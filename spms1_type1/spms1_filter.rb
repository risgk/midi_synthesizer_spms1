module Spms1
  # ZDF (zero-delay feedback) / TPT (topology-preserving transform) state variable filter, low
  # pass, with delayed soft clipping on both integrator states.
  # This implementation is not oversampled; the nonlinear behavior is kept intentionally simple.
  # Reference: https://www.discodsp.net/VAFilterDesign_2.1.2.pdf (The Art of VA Filter Design)
  # Reference: https://jatinchowdhury18.medium.com/complex-nonlinearities-episode-4-nonlinear-biquad-filters-ae6b3f23cb0e
  # Coefficients are recomputed every 4 samples rather than every sample: the computation needs two
  # table lookups and a division, and the parameters feeding it are smoothed in the same place.
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

    # Twice OUTPUT_CEILING, so a state rails at twice what leaves the module. The cubic is
    # self-similar: scaling the ceiling scales the flat value, two thirds of it, with it. What
    # this value sets in play is how hard the curve bends below the rail, and that is what holds
    # the resonant peak down.
    SOFT_CLIP_CEILING = 3.0
    # Everything soft_clip needs derived from the ceiling once, at startup. The vendored Spinel
    # emits Float constants as runtime globals rather than compile-time literals, so writing these
    # expressions inline in soft_clip would leave a real division and extra multiplies in a
    # method that runs twice per sample.
    SOFT_CLIP_FLOOR      = -SOFT_CLIP_CEILING
    SOFT_CLIP_GAIN_SCALE = 1.0 / (3.0 * SOFT_CLIP_CEILING * SOFT_CLIP_CEILING)
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

    # Damping lookup, k = 1 / Q, one entry per step of the resonance dial: Q runs from ~0.7 to
    # ~11.3 across 121 entries. The last entry repeats the one before it so that interpolating
    # at the top of the dial reads a real entry rather than past the end.
    K_TABLE = Array.new(122, 0.0)
    BASE_Q = 0.7071067811865476
    for i in 0...121
      K_TABLE[i] = 1.0 / (BASE_Q * (2.0 ** (i.to_f * (1.0 / 30.0))))
    end
    K_TABLE[121] = K_TABLE[120]

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)

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
      @s1 = 0.0
      @s2 = 0.0

      @current_modulation_input = 0.0
      @sample_counter = 0

      update_coefficients
    end

    # Every parameter is normalized to [-0.5, 0.5] and held in [0.0, 1.0], which is what the
    # smoothing, the modulation sum and the table lookups below are written against.
    # Cutoff range: MIDI note 15 (19 Hz) at -0.5, MIDI note 75 (622 Hz) at 0.0, MIDI note 135 (20 kHz) at 0.5.
    def set_cutoff(cutoff)
      clamped = (cutoff < -0.5) ? -0.5 : ((cutoff > 0.5) ? 0.5 : cutoff)
      @cutoff = clamped + 0.5
    end

    # Modulation depth, none at -0.5.
    def set_modulation_amount(amount)
      clamped = (amount < -0.5) ? -0.5 : ((amount > 0.5) ? 0.5 : amount)
      @modulation_amount = clamped + 0.5
    end

    # How hard the audio input drives the filter, used as a plain multiplier: 0.0 at -0.5, 1.0 at
    # 0.5. It sits on the input rather than the output because that is what decides how far the
    # states run into soft_clip: past the middle of the dial the filter starts to saturate.
    def set_gain(gain)
      clamped = (gain < -0.5) ? -0.5 : ((gain > 0.5) ? 0.5 : gain)
      @gain = clamped + 0.5
    end

    # Q range: ~0.7 (-0.5), ~2.83 (0.0), ~11.3 (0.5).
    def set_resonance(resonance)
      clamped = (resonance < -0.5) ? -0.5 : ((resonance > 0.5) ? 0.5 : resonance)
      @resonance = clamped + 0.5
    end

    def process(audio_input = 0.0, modulation_input = 0.0)
      @current_modulation_input = modulation_input

      if @sample_counter == 0
        update_coefficients
      end

      driven_input = audio_input * @current_gain

      # Gain prediction: each integrator's soft clip is evaluated on its state from the previous
      # sample, so its gain is fixed for this one. The zero-delay feedback equation then stays
      # linear within the sample and keeps its closed-form solution, with no iteration and no
      # division here -- 1 / a0 comes from the control-rate update.
      s1 = soft_clip(@s1)
      s2 = soft_clip(@s2)

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

    # The three coefficients are replaced together, so the filter never runs on a g from one
    # setting and a damping from another.
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
      k = resonance_to_k_fast(@current_resonance)
      g_plus_k = g + k
      one_over_a0 = 1.0 / (1.0 + g * g_plus_k)

      @g = g
      @one_over_a0 = one_over_a0
      @g_plus_k_over_a0 = g_plus_k * one_over_a0
    end

    # Bounds what the module hands to the bus. Separate from soft_clip, which bounds the states
    # inside the loop at a much higher ceiling and has to stay where it is.
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

    # Cubic soft clip written as a gain: the clamped value times 1 - c^2 / (3 * ceiling^2). Same
    # curve as c - c^3 / (3 * ceiling^2), slope exactly 1 at zero and flat at the ceiling, so a
    # state within the ceiling is only ever scaled down and a state past it is held at two thirds
    # of it. Clamped the way clip_output clamps, without a comparison; this one runs twice per
    # sample, on the states inside the feedback path.
    def soft_clip(sample)
      over    = sample - SOFT_CLIP_CEILING
      under   = SOFT_CLIP_FLOOR - sample
      clamped = sample - ((over + over.abs) - (under + under.abs)) * 0.5
      clamped * (1.0 - clamped * clamped * SOFT_CLIP_GAIN_SCALE)
    end
  end
end
