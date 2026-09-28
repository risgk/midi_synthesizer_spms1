module Spms1
  # ZDF (zero-delay feedback) / TPT (topology-preserving transform) state variable filter, low
  # pass, with delayed soft clipping on the band pass integrator's state.
  # This implementation is not oversampled; the nonlinear behavior is kept intentionally simple.
  # Reference: https://www.discodsp.net/VAFilterDesign_2.1.2.pdf (The Art of VA Filter Design)
  # Reference: https://www.kvraudio.com/forum/viewtopic.php?t=349859 (Cheap non-linear zero-delay filters)
  # Reference: https://jatinchowdhury18.medium.com/complex-nonlinearities-episode-4-nonlinear-biquad-filters-ae6b3f23cb0e
  # Coefficients are recomputed every 4 samples rather than every sample, and ramped between: the
  # computation needs two table lookups and a division, and the parameters feeding it are smoothed
  # in the same place.
  class Filter
    # What leaves the filter, as opposed to what circulates inside it: exactly linear up to
    # OUTPUT_KNEE, then a quadratic shoulder that reaches OUTPUT_LIMIT with zero slope at
    # OUTPUT_CEILING. The limit is one unit, the widest thing the bus carries. A cubic here had no
    # linear region and bent everything it passed -- 0.3 dB and a 1% third harmonic at half a unit
    # -- which put the output clip ahead of the loop as the filter's main source of distortion. The
    # default patch peaks near 0.3, under the knee, so it leaves untouched. The shoulder's curvature
    # steps at the knee, so what crosses it gains odd harmonics of every order rather than just the
    # third, falling as 1/n^3; a hard clamp, stepping in slope, falls as 1/n^2.
    OUTPUT_LIMIT       = 1.0
    OUTPUT_KNEE        = 0.5
    OUTPUT_CEILING     = OUTPUT_LIMIT + OUTPUT_LIMIT - OUTPUT_KNEE
    OUTPUT_FLOOR       = -OUTPUT_CEILING
    OUTPUT_KNEE_FLOOR  = -OUTPUT_KNEE
    # 1 / (4 * (limit - knee)) for the shoulder, and a further quarter because clip_output's
    # excess is doubled.
    OUTPUT_KNEE_SCALE  = 1.0 / (16.0 * (OUTPUT_LIMIT - OUTPUT_KNEE))

    # The cubic is self-similar: scaling the ceiling scales the flat value, two thirds of it, with
    # it. What this value sets in play is how hard the curve bends below the rail;
    # applied every sample inside the loop, that bend is what holds the resonant peak down.
    SOFT_CLIP_CEILING = 4.0
    # Everything soft_clip needs derived from the ceiling once, at startup. The vendored Spinel
    # emits Float constants as runtime globals rather than compile-time literals, so writing these
    # expressions inline in soft_clip would leave a real division and extra multiplies in a
    # method that runs every sample.
    SOFT_CLIP_FLOOR      = -SOFT_CLIP_CEILING
    SOFT_CLIP_GAIN_SCALE = 1.0 / (3.0 * SOFT_CLIP_CEILING * SOFT_CLIP_CEILING)
    # The guard on the low pass state that process describes, well above anything ordinary use
    # reaches.
    LOW_PASS_STATE_CEILING = 16.0
    LOW_PASS_STATE_FLOOR   = -LOW_PASS_STATE_CEILING
    # Blend at the reference rate on the line below. The two move together: their product is what
    # fixes the time constant, so changing one without the other changes how fast smoothing is.
    SMOOTHING_TARGET_BLEND_BASE = 0.03125
    # Number of samples between control-rate updates; smoothing speed is kept approximately
    # constant if this is changed. It has to stay a power of two: the counter below wraps with a
    # mask, because Ruby's % is a floor-modulo and sp_imod carries a sign correction the counter
    # can never need -- one branch a sample in each module, ten across the six of them.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction survives into the per-sample path carrying an overflow check of its own, which
    # measured far worse than the modulo it replaces. What the mask buys is size, not
    # determinism: the ten branches it removes, one per site, are ones that could never be taken.
    # Together with the LFO's fold it took 11 branches and 60 instructions out of Spms1_main as
    # linked, and the buffer time did not move (853/857us against 854/856).
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    # Damping lookup, k = 1 / Q, one entry per step of the resonance dial, written against the
    # dial position r = i / 120: Q = 0.707 * 2^(4r) up to Q 5.66 at r = 0.75. Past that the curve
    # is laid out on v = 128r, where a quadratic term in (v - 96) is added to log2(Q), so that the
    # slope grows smoothly rather than stepping up, reaching Q 256 at v = 122; above that k is
    # zero, and the self-oscillation that update_coefficients adds takes over. The last entry
    # repeats the one before it so that interpolating at the top of the dial reads a real entry
    # rather than past the end.
    K_TABLE = Array.new(122, 0.0)
    BASE_Q = 0.7071067811865476
    Q_CURVE_C = (8.0 - (122.0 - 16.0) / 32.0) / ((122.0 - 96.0) * (122.0 - 96.0))
    for i in 0...121
      if i <= 90
        K_TABLE[i] = 1.0 / (BASE_Q * (2.0 ** (i.to_f * (1.0 / 30.0))))
      else
        v = i.to_f * (128.0 / 120.0)
        if v <= 122.0
          K_TABLE[i] = 1.0 / (2.0 ** ((v - 16.0) * (1.0 / 32.0) + Q_CURVE_C * (v - 96.0) * (v - 96.0)))
        end
      end
    end
    K_TABLE[121] = K_TABLE[120]

    # Negative damping at the top of the resonance dial, as k = -t * kappa * (1 + g^2)^2 / g with t
    # the amount dialled in. The soft clip on the band pass state settles the oscillation at about
    # 11.4 * sqrt(|k| * g / (1 + g^2)^2), so this holds it near SELF_OSC_LEVEL whatever the cutoff;
    # the (1 + g^2)^2 matters only in the top octaves, where g is no longer small.
    # Set at the output clip's knee, the most that leaves the filter as a clean sine; the
    # oscillation settles just below it. The value is for 48 kHz; initialize scales it with the
    # sample rate, as it does the clip.
    SELF_OSC_LEVEL = 0.5
    SELF_OSC_KAPPA = (SELF_OSC_LEVEL / 11.4) * (SELF_OSC_LEVEL / 11.4)
    # How negative k may go. Below about 150 Hz, -kappa / g grows large enough to pull the
    # oscillation's pitch down; held here, the amplitude falls off there instead.
    SELF_OSC_K_FLOOR = -0.2
    # The loop cannot start oscillating from states of exactly zero. This is added to the band
    # pass state at every control-rate step with its sign flipped each time, so the states never
    # rest at zero and never rest on a point that a change of k leaves in place; a constant would
    # do the latter, as k does not move the loop's DC balance. Well above flush_tiny's dead zone,
    # and far below anything audible.
    SELF_OSC_SEED = 1e-6

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)

      # The state passes through soft_clip once a sample, so what it takes out of it adds up with
      # the sample rate: left alone, the distortion grows as the rate rises and does not settle
      # toward any continuous-time filter. Blending the clip by alpha = 48000 / f_s,
      # s - alpha * (s - soft_clip(s)), keeps the sound at 48 kHz on other rates. alpha is folded
      # into the two values soft_clip reads; at 48 kHz the leak is exactly zero and the scale
      # exactly SOFT_CLIP_GAIN_SCALE, so the output there is the plain clip's, bit for bit.
      soft_clip_alpha = 48000.0 / @sample_rate
      @soft_clip_gain_scale = SOFT_CLIP_GAIN_SCALE * soft_clip_alpha
      @soft_clip_leak = (1.0 - soft_clip_alpha) * 0.5
      @self_osc_kappa = SELF_OSC_KAPPA * soft_clip_alpha
      @self_osc_seed = SELF_OSC_SEED

      # Integrator gain lookup, g = tan(pi * f_0 / f_s), one entry per semitone of MIDI note 15
      # (19 Hz) to 135 (20 kHz), the cutoff dial's range. It depends on the sample rate, so it is
      # built here rather than as a constant. The prewarp puts the cutoff exactly where the note
      # says, all the way up; the guard entry at the end serves as K_TABLE's does.
      @g_table = Array.new(122, 0.0)
      i = 0
      while i < 121
        freq = 440.0 * (2.0 ** ((i.to_f - 54.0) * (1.0 / 12.0)))
        @g_table[i] = Math.tan(Math::PI * freq * (1.0 / sample_rate))
        i += 1
      end
      @g_table[121] = @g_table[120]

      @cutoff = 1.0
      @resonance = 0.0
      @modulation_amount = 0.0
      @gain = 0.5

      @current_cutoff = 1.0
      @current_resonance = 0.0
      @current_modulation_amount = 0.0
      @current_gain = 0.5

      @g = 0.0
      @one_over_a0 = 1.0
      @g_plus_k_over_a0 = 0.0
      @last_g = 0.0
      @last_one_over_a0 = 1.0
      @last_g_plus_k_over_a0 = 0.0
      @g_slope = 0.0
      @one_over_a0_slope = 0.0
      @g_plus_k_over_a0_slope = 0.0
      @s1 = 0.0
      @s2 = 0.0

      @current_modulation_input = 0.0
      @sample_counter = 0

      update_coefficients
    end

    # Every parameter is unipolar, [0.0, 1.0], which is what the smoothing, the modulation sum and
    # the table lookups below are written against.
    # Cutoff range: MIDI note 15 (19 Hz) at 0.0, MIDI note 75 (622 Hz) at 0.5, MIDI note 135 (20 kHz) at 1.0.
    def set_cutoff(cutoff)
      @cutoff = (cutoff < 0.0) ? 0.0 : ((cutoff > 1.0) ? 1.0 : cutoff)
    end

    # Modulation depth, none at 0.0.
    def set_modulation_amount(amount)
      @modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # How hard the audio input drives the filter, used as a plain multiplier. It sits on the input
    # rather than the output because that is what decides how far the band pass state runs into
    # soft_clip, which the resonant peak reaches first: the pass band itself stays nearly clean.
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    # Q range: ~0.7 (0.0), ~2.83 (0.5), ~5.66 (0.75), ~27 (0.875), 256 (~0.953); self-oscillation from there,
    # growing to its full level at ~0.992 and staying there to 1.0.
    def set_resonance(resonance)
      @resonance = (resonance < 0.0) ? 0.0 : ((resonance > 1.0) ? 1.0 : resonance)
    end

    def process(audio_input = 0.0, modulation_input = 0.0)
      @current_modulation_input = modulation_input

      if @sample_counter == 0
        update_coefficients
        @s1 = flush_tiny(@s1) + @self_osc_seed
        @s2 = flush_tiny(@s2)
        @self_osc_seed = 0.0 - @self_osc_seed
      end

      @g += @g_slope
      @one_over_a0 += @one_over_a0_slope
      @g_plus_k_over_a0 += @g_plus_k_over_a0_slope

      driven_input = audio_input * @current_gain

      # Gain prediction: the soft clip is evaluated on the state from the previous sample, so its
      # gain is fixed for this one. The zero-delay feedback equation then stays linear within the
      # sample and keeps its closed-form solution, with no iteration and no division here -- 1 / a0
      # comes from the control-rate update.
      # Only the band pass state is soft-clipped: the low pass passes clean and the resonance stays
      # in tune, still held down by the clip inside the loop; clip_output trims what peaks remain.
      # To clip both states, use the line in the comment instead of the clamp:
      #   s2 = soft_clip(@s2)
      # The clamp is a guard that ordinary use never reaches. Between control-rate steps the
      # coefficients only approximately satisfy a0 = 1 + g * (g + k), and a cutoff thrown across
      # its range every step, as audio on the modulation input at full depth does, can then give
      # the loop gain; nothing else bounds the low pass state. Clamped the way clip_output clamps.
      s1 = soft_clip(@s1)
      s2_over  = @s2 - LOW_PASS_STATE_CEILING
      s2_under = LOW_PASS_STATE_FLOOR - @s2
      s2 = @s2 - ((s2_over + s2_over.abs) - (s2_under + s2_under.abs)) * 0.5

      # high_pass = (x - (g + k) * s1 - s2) / (1 + g * (g + k))
      high_pass = (driven_input - s2) * @one_over_a0 - s1 * @g_plus_k_over_a0

      # Two trapezoidal integrators in series.
      v1 = @g * high_pass
      band_pass = v1 + s1
      v2 = @g * band_pass
      low_pass = v2 + s2
      @s1 = band_pass + v1
      @s2 = low_pass + v2

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      clip_output(low_pass)
    end

    private

    def cutoff_to_g_fast(clamped_cutoff)
      internal_cutoff = clamped_cutoff * 120.0
      index = internal_cutoff.to_i
      fraction = internal_cutoff - index.to_f

      g0 = @g_table[index]
      g1 = @g_table[index + 1]

      g0 + fraction * (g1 - g0)
    end

    def resonance_to_k_fast(resonance)
      internal_resonance = resonance * 120.0
      index = internal_resonance.to_i
      fraction = internal_resonance - index.to_f

      k0 = K_TABLE[index]
      k1 = K_TABLE[index + 1]

      k0 + fraction * (k1 - k0)
    end

    # The three coefficients ramp together from the last step's set to this one's over the next
    # four samples, as the EG's output does, so a fast cutoff sweep is a line rather than a
    # staircase at a quarter of the sample rate. Each is ramped on its own, so between the ends
    # of a ramp they only approximately satisfy a0 = 1 + g * (g + k); the ends are exact, and the
    # states stay bounded either way, through soft_clip and the guard on the low pass state. Each ramp starts from the stored set rather
    # than from where the additions got to, so rounding does not build up. 0.25 is
    # 1 / CONTROL_RATE_DIVISOR, written out for the reason Mixer#process gives.
    def update_coefficients
      @current_cutoff += (@cutoff - @current_cutoff) * @smoothing_target_blend
      @current_resonance += (@resonance - @current_resonance) * @smoothing_target_blend
      @current_modulation_amount += (@modulation_amount - @current_modulation_amount) * @smoothing_target_blend
      @current_gain += (@gain - @current_gain) * @smoothing_target_blend

      # The modulation input arrives as it is; clamping total_cutoff below is what holds the
      # table lookup in range, and a source that swings both ways moves the cutoff both ways.
      # Clamped without a comparison, as clip_output does it.
      total_cutoff = @current_cutoff + (@current_modulation_input * @current_modulation_amount)
      over  = total_cutoff - 1.0
      under = 0.0 - total_cutoff
      clamped_cutoff = total_cutoff - ((over + over.abs) - (under + under.abs)) * 0.5

      g = cutoff_to_g_fast(clamped_cutoff)

      # The self-oscillation amount: zero up to r = 122/128, rising to one at 127/128 and held
      # there. Worked out here rather than in K_TABLE, whose interpolation would round off the
      # corner at 127/128. Each clamp is built as clip_output builds its own.
      t = @current_resonance * 25.6 - 24.4
      over  = t - 1.0
      under = 0.0 - t
      t = t - ((over + over.abs) - (under + under.abs)) * 0.5
      one_plus_g_squared = 1.0 + g * g
      k = resonance_to_k_fast(@current_resonance) - t * @self_osc_kappa * one_plus_g_squared * one_plus_g_squared / g
      below_floor = SELF_OSC_K_FLOOR - k
      k = k + (below_floor + below_floor.abs) * 0.5
      g_plus_k = g + k
      one_over_a0 = 1.0 / (1.0 + g * g_plus_k)

      g_plus_k_over_a0 = g_plus_k * one_over_a0

      @g = @last_g
      @one_over_a0 = @last_one_over_a0
      @g_plus_k_over_a0 = @last_g_plus_k_over_a0
      @g_slope = (g - @last_g) * 0.25
      @one_over_a0_slope = (one_over_a0 - @last_one_over_a0) * 0.25
      @g_plus_k_over_a0_slope = (g_plus_k_over_a0 - @last_g_plus_k_over_a0) * 0.25
      @last_g = g
      @last_one_over_a0 = one_over_a0
      @last_g_plus_k_over_a0 = g_plus_k_over_a0
    end

    # Bounds what the module hands to the bus. Separate from soft_clip, which bounds the band pass
    # state inside the loop at a much higher ceiling and has to stay where it is. With only that
    # state clipped, a high Q on a loud input reaches the shoulder here.
    # No comparisons, so nothing for the compiler to turn into a branch: Spinel emits abs as fabs,
    # one vabs.f32, and a + |a| is twice a where a is positive and exactly zero where it is not.
    # Each clamp and the knee are built from two of those, one per side, which is also what keeps
    # the linear region bit-exact -- a sample inside it has nothing added to it or taken away.
    # excess is twice the signed distance past the knee; excess * |excess| keeps the shoulder odd
    # without a sign test. Every subtraction here is exact in single precision below 2^23, far
    # past anything the filter can produce, so fed past the ceiling the curve lands on exactly
    # OUTPUT_LIMIT. An infinity would come out as NaN where a comparison would have clamped it;
    # the filter's input is a bus slot and its states are bounded, so none arrives. Both floors
    # are stored constants rather than negated ones, for the reason the constants above give.
    def clip_output(sample)
      over    = sample - OUTPUT_CEILING
      under   = OUTPUT_FLOOR - sample
      clamped = sample - ((over + over.abs) - (under + under.abs)) * 0.5
      above   = clamped - OUTPUT_KNEE
      below   = OUTPUT_KNEE_FLOOR - clamped
      excess  = (above + above.abs) - (below + below.abs)
      clamped - (excess * excess.abs) * OUTPUT_KNEE_SCALE
    end

    # A dead zone of 1e-20 about zero, so that a state decaying on a silent input lands on exactly
    # zero instead of sinking into denormals, which x86 computes slowly. It shifts every other
    # value toward zero by 1e-20, which rounds away at any audible level. Built from a + |a| as
    # clip_output is, rather than as (s + c) - c: -ffast-math may fold that one to s, while this
    # is a dead zone in exact arithmetic, so any rewrite it allows still is one. What comes out is
    # zero or at least 8e-28, the spacing of floats near 1e-20: never a denormal. Rewritten under
    # -ffast-math it rounds at that spacing and may leave a remnant of that size instead of zero,
    # still far above the denormals. A literal, for the reason given above.
    def flush_tiny(state)
      above = state - 1e-20
      below = (0.0 - state) - 1e-20
      ((above + above.abs) - (below + below.abs)) * 0.5
    end

    # Cubic soft clip written as a gain: the clamped value times 1 - c^2 / (3 * ceiling^2). Same
    # curve as c - c^3 / (3 * ceiling^2), slope exactly 1 at zero and flat at the ceiling, so a
    # state within the ceiling is only ever scaled down and a state past it is held at two thirds
    # of it. Clamped the way clip_output clamps, without a comparison; this one runs every sample,
    # on the band pass state inside the feedback path.
    # Blended by alpha as initialize describes: with the state split into its clamped part c and
    # the part past the ceiling d, s - alpha * (s - soft_clip(s)) is c - alpha * c^3 / (3 *
    # ceiling^2) + (1 - alpha) * d. excess is twice d, which is why the leak carries a half.
    def soft_clip(sample)
      over    = sample - SOFT_CLIP_CEILING
      under   = SOFT_CLIP_FLOOR - sample
      excess  = (over + over.abs) - (under + under.abs)
      clamped = sample - excess * 0.5
      clamped * (1.0 - clamped * clamped * @soft_clip_gain_scale) + excess * @soft_clip_leak
    end
  end
end
