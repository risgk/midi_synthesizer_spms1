module Spms1
  # ZDF (zero-delay feedback) / TPT (topology-preserving transform) state variable filter, with a
  # nonlinear leak on the band pass integrator, solved within the sample by one step of Newton's
  # method. It puts out its low pass, high pass and band pass at once, each through a DC blocker
  # and the output clip of its own, and the first two crossfaded by Mode: process returns the
  # crossfade, and output_lp, output_hp and output_bp hold the low pass, the high pass and the
  # band pass. The audio input drives it as it
  # arrives, so how hard is set ahead of it: by Mixer 2 Out Level in the default patch. That is
  # what decides how far the band pass runs into the leak, which the resonant peak reaches first:
  # the pass band itself stays nearly clean.
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
    # OUTPUT_CEILING. The limit is one unit, the widest thing the bus carries. A cubic here would have
    # no linear region and bend everything it passed -- 0.3 dB and a 1% third harmonic at half a
    # unit -- making the output clip, not the loop, the filter's main source of distortion. The
    # default patch peaks near 0.68, under the knee, so it leaves untouched. The shoulder's curvature
    # steps at the knee, so what crosses it gains odd harmonics of every order rather than just the
    # third, falling as 1/n^3; a hard clamp, stepping in slope, falls as 1/n^2.
    OUTPUT_LIMIT       = 1.0
    OUTPUT_KNEE        = 0.75
    OUTPUT_CEILING     = OUTPUT_LIMIT + OUTPUT_LIMIT - OUTPUT_KNEE
    OUTPUT_FLOOR       = -OUTPUT_CEILING
    OUTPUT_KNEE_FLOOR  = -OUTPUT_KNEE
    # 1 / (4 * (limit - knee)) for the shoulder, and a further quarter because clip_output's
    # excess is doubled.
    OUTPUT_KNEE_SCALE  = 1.0 / (16.0 * (OUTPUT_LIMIT - OUTPUT_KNEE))

    # The band pass integrator leaks at LEAK_RATE * (y - soft_clip_biased(y)) on top of what it
    # integrates, y being the band pass: nothing at small levels, more and more as y bends into the
    # cubic below. In continuous time,
    #   dy/dt = w_c * high_pass - LEAK_RATE * (y - soft_clip_biased(y))
    # which is an integrator with a soft limiter across its capacitor. The rate is that of
    # soft-clipping the state once a sample at 48 kHz, fixed in time rather than per sample, so
    # the distortion does not grow with the sample rate and needs no blend to hold it. That leak is what holds
    # the resonant peak down; the pass band, where y stays small, passes nearly clean.
    LEAK_RATE = 48000.0
    # The cubic is self-similar: scaling the ceiling scales the flat value, two thirds of it, with
    # it. What this value sets in play is how hard the curve bends below the rail, and so how fast
    # the leak grows with the level.
    SOFT_CLIP_CEILING = 4.0
    # Everything the leak needs derived from the ceiling once, at startup. The vendored Spinel
    # emits Float constants as runtime globals rather than compile-time literals, so writing these
    # expressions inline in process would leave a real division and extra multiplies in a method
    # that runs every sample.
    SOFT_CLIP_FLOOR      = -SOFT_CLIP_CEILING
    SOFT_CLIP_GAIN_SCALE = 1.0 / (3.0 * SOFT_CLIP_CEILING * SOFT_CLIP_CEILING)
    # The clip is shifted by B, its output at zero, soft_clip(B), taken back off so that zero
    # still maps to zero, and its slope there, 1 - B^2 / ceiling^2, made up again:
    #   soft_clip_biased(x) = (soft_clip(x + B) - soft_clip(B)) / (1 - B^2 / ceiling^2)
    # so that the leak and its slope are both zero at zero. Without the make-up the leak would be
    # negative there, a gain in the loop at small signals. The bias gives the state even harmonics
    # and a DC that follows its level; the DC blocker on the output takes the DC back out.
    SOFT_CLIP_BIAS        = 0.125
    SOFT_CLIP_BIAS_OUTPUT = SOFT_CLIP_BIAS * (1.0 - SOFT_CLIP_BIAS * SOFT_CLIP_BIAS * SOFT_CLIP_GAIN_SCALE)
    SOFT_CLIP_BIAS_GAIN   = 1.0 / (1.0 - 3.0 * SOFT_CLIP_BIAS * SOFT_CLIP_BIAS * SOFT_CLIP_GAIN_SCALE)
    # With c the clamped x + B and G the make-up gain, soft_clip_biased(x) is
    # c * (G - c^2 * G / (3 * ceiling^2)) - G * soft_clip(B), and its slope G - c^2 * G / ceiling^2,
    # zero past the ceiling, where c is held at it. The leak's slope is one minus that.
    LEAK_CLIP_GAIN_SCALE = SOFT_CLIP_GAIN_SCALE * SOFT_CLIP_BIAS_GAIN
    LEAK_CLIP_OFFSET     = SOFT_CLIP_BIAS_GAIN * SOFT_CLIP_BIAS_OUTPUT
    LEAK_SLOPE_OFFSET    = 1.0 - SOFT_CLIP_BIAS_GAIN
    LEAK_SLOPE_SCALE     = 3.0 * LEAK_CLIP_GAIN_SCALE
    # One-pole high pass on the output at f_s * coefficient / (2 * pi), 7.5 Hz at 48 kHz; initialize
    # scales the coefficient with the sample rate to hold that frequency.
    DC_BLOCKER_COEFFICIENT_BASE = 1.0 / 1024.0
    # The guard on the low pass state that process describes, well above anything ordinary use
    # reaches.
    LOW_PASS_STATE_CEILING = 16.0
    LOW_PASS_STATE_FLOOR   = -LOW_PASS_STATE_CEILING
    # Blend at the reference rate on the line below, for each of two cascaded stages. The two move
    # together: their product is what fixes the time constant, so changing one without the other
    # changes how fast smoothing is. Two stages at 1/64 (5.3 ms each at 48 kHz) delay a step by
    # 10.7 ms on average, as one stage at 1/128 would, but start from zero slope, so that the steps
    # of a controller sending sparse CCs (e.g. every 20 ms) are rounded off rather than heard,
    # and settle sooner, 99% in 35 ms.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Samples between control-rate updates. The main loop sets the cadence, handing every module
    # the same control tick once every CONTROL_RATE_DIVISOR samples (see spms1_main.rb), and the
    # rates derived here assume this, so the two have to match; smoothing speed is kept approximately
    # constant if both are changed.
    CONTROL_RATE_DIVISOR = 4

    # Damping lookup, k = 1 / Q, one entry per step of the resonance dial, written against the
    # dial position r = i / 120, i = CC - 4: Q = 0.707 * 2^(5r), doubling every 24 steps, up to
    # Q 9.51 at i = 90 (CC 94).
    # Past that a quadratic term in (i - 90) is added to log2(Q), so that the slope grows smoothly
    # rather than stepping up, reaching Q 256 at i = 114 (CC 118); above that k is zero, and the
    # self-oscillation that update_coefficients adds takes over. The last entry repeats the one
    # before it so that interpolating at the top of the dial reads a real entry rather than past
    # the end.
    K_TABLE = Array.new(122, 0.0)
    BASE_Q = 0.7071067811865476
    Q_CURVE_C = (8.0 - (114.0 / 24.0 - 0.5)) / ((114.0 - 90.0) * (114.0 - 90.0))
    for i in 0...121
      if i <= 90
        K_TABLE[i] = 1.0 / (BASE_Q * (2.0 ** (i.to_f * (1.0 / 24.0))))
      elsif i <= 114
        d = (i - 90).to_f
        K_TABLE[i] = 1.0 / (2.0 ** (i.to_f * (1.0 / 24.0) - 0.5 + Q_CURVE_C * d * d))
      end
    end
    K_TABLE[121] = K_TABLE[120]

    # Negative damping at the top of the resonance dial, as k = -t * kappa / g with t the amount
    # dialed in. The leak settles the oscillation where it takes out what the negative damping
    # puts in: g * |k| against h * A^2 / (4 * ceiling^2) for a band pass of amplitude A, with h the
    # leak's step that initialize sets, so at about 2 * ceiling * sqrt(|k| * g / h), 11.3 *
    # sqrt(|k| * g) at 48 kHz (11.4 as measured). Both sit in the same implicit equation, so the
    # balance holds whatever the cutoff, the top octaves included, and this holds the oscillation
    # near SELF_OSC_LEVEL. Set below the output clip's knee, so that the oscillation leaves the filter as
    # a clean sine. The value is for 48 kHz; initialize scales it with h.
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
    # Where the self-oscillation starts on the resonance dial, r = 114/120 (CC 118), where K_TABLE
    # reaches Q 256.
    SELF_OSC_START = 114.0 / 120.0
    # The leak on the band pass gives the oscillation a 3rd harmonic, which folds back
    # to |f_s - 3 * f_0| once 3 * f_0 is above f_s / 2 (an inharmonic 11.8 kHz tone for f_0 = 19.9
    # kHz at 48 kHz). The oscillation therefore fades out as the cutoff, modulation included, rises
    # from f_s / 6 to f_s / 4.8, linearly on the cutoff dial, where the folded tone is still above
    # 0.375 * f_s; above that the resonance past SELF_OSC_START acts as SELF_OSC_START. At 48 kHz
    # that is 8 kHz to 10 kHz, CC 108 to 112. The fade's width on the dial does not depend on the
    # sample rate: log2(6 / 4.8) octaves, at 10 octaves to the dial.
    SELF_OSC_FADE_WIDTH = Math.log(6.0 / 4.8) / (10.0 * Math.log(2.0))

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # The blend of the parameters smoothed once every 16 samples, four control ticks (see
      # smooth_parameters): the one above taken four times over, for the same time.
      @smoothing_16_blend = 1.0 - (1.0 - @smoothing_target_blend) ** 4.0

      # The leak's rate over the trapezoidal rule's step, LEAK_RATE * T / 2, as g is w_c * T / 2
      # (prewarped); a half at 48 kHz.
      @leak_step = 0.5 * LEAK_RATE / @sample_rate
      @self_osc_kappa = SELF_OSC_KAPPA * (48000.0 / @sample_rate)
      @dc_blocker_coefficient = DC_BLOCKER_COEFFICIENT_BASE * (48000.0 / @sample_rate)
      @self_osc_seed = SELF_OSC_SEED
      # The fade's weight is offset - cutoff * scale, clamped to [0, 1]: one at f_s / 6 and below,
      # zero at f_s / 4.8 and above. The dial puts MIDI note 15 at 0.0 and 135 at 1.0, 440 Hz at
      # 0.45. At a sample rate of 96 kHz or more, f_s / 4.8 lies past the top of the dial and the
      # oscillation never fades out entirely.
      self_osc_fade_end = 0.45 + Math.log(sample_rate * (1.0 / (4.8 * 440.0))) / (10.0 * Math.log(2.0))
      @self_osc_fade_scale = 1.0 / SELF_OSC_FADE_WIDTH
      @self_osc_fade_offset = self_osc_fade_end * @self_osc_fade_scale

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
      # Each Mod Amt and its Mod Pol are multiplied before smoothing, so only their product,
      # the depth, carries a smoothing state.
      @modulation_1_amount = 0.0
      @modulation_2_amount = 0.0
      @modulation_1_polarity = 1.0
      @modulation_2_polarity = 1.0
      @modulation_1_depth = 0.0
      @modulation_2_depth = 0.0
      @pitch_amount = 0.0
      @pitch_polarity = 1.0
      @pitch_depth = 0.0
      @mode_lp = 1.0
      @mode_hp = 0.0

      # The smoothing starts where the parameters at 0.0 put it, as every module's does: Mode 0.0 is
      # the low pass alone.
      @stage_1_cutoff = 0.0
      @stage_1_resonance = 0.0
      @stage_1_modulation_1_depth = 0.0
      @stage_1_modulation_2_depth = 0.0
      @stage_1_pitch_depth = 0.0
      @stage_1_mode_lp = 1.0
      @stage_1_mode_hp = 0.0
      @current_cutoff = 0.0
      @current_resonance = 0.0
      @current_modulation_1_depth = 0.0
      @current_modulation_2_depth = 0.0
      @current_pitch_depth = 0.0
      @current_mode_lp = 1.0
      @current_mode_hp = 0.0

      @g = 0.0
      @g_plus_k = 0.0
      @one_over_a0 = 1.0
      @last_g = 0.0
      @last_g_plus_k = 0.0
      @last_one_over_a0 = 1.0
      @g_slope = 0.0
      @g_plus_k_slope = 0.0
      @one_over_a0_slope = 0.0
      @s1 = 0.0
      @s2 = 0.0
      @dc_blocker = 0.0
      @dc_blocker_hp = 0.0
      @dc_blocker_bp = 0.0
      @output_lp = 0.0
      @output_hp = 0.0
      @output_bp = 0.0

      @current_pitch_input = 0.0
      @current_modulation_1_input = 0.0
      @current_modulation_2_input = 0.0
      @gain_1 = 1.0
      @stage_1_gain_1 = 0.0
      @current_gain_1 = 0.0
      @gain_2 = 1.0
      @stage_1_gain_2 = 0.0
      @current_gain_2 = 0.0

      update_coefficients
    end

    # Gain 1 and Gain 2, of Audio In 1 and Audio In 2, which are summed into the filter: each
    # unipolar, [0.0, 1.0], squared and taken four times, as Amp's Gain 1 is, so that the middle of
    # the dial is unity and the top drives the filter 12 dB harder. Smoothed at the control rate,
    # as Mode is, being gains on the audio.
    def set_gain_1(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      @gain_1 = 4.0 * clamped_gain * clamped_gain
    end

    def set_gain_2(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      @gain_2 = 4.0 * clamped_gain * clamped_gain
    end

    # Every parameter but the two Mod Pols is unipolar, [0.0, 1.0], which is what the smoothing, the
    # modulation sum and the table lookups below are written against.
    # Cutoff range: MIDI note 15 (19 Hz) at 0.0, MIDI note 75 (622 Hz) at 0.5, MIDI note 135 (20 kHz) at 1.0.
    def set_cutoff(cutoff)
      @cutoff = (cutoff < 0.0) ? 0.0 : ((cutoff > 1.0) ? 1.0 : cutoff)
    end

    # Each modulation amount is unipolar, [0.0, 1.0], a plain multiplier on its input: at 1.0 a
    # unit of input is the whole cutoff range, and at 0.0 the input leaves the cutoff alone. Each
    # modulation's polarity multiplies its amount.
    def set_modulation_1_amount(amount)
      @modulation_1_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @modulation_1_depth = @modulation_1_amount * @modulation_1_polarity
    end

    def set_modulation_2_amount(amount)
      @modulation_2_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @modulation_2_depth = @modulation_2_amount * @modulation_2_polarity
    end

    # Mod 1 Pol and Mod 2 Pol are bipolar, [-0.5, 0.5], each doubled into a multiplier on
    # its modulation: at +0.5 it moves the cutoff as its amount says, at -0.5 the other way, so the
    # envelope closes the filter, and at 0.0 not at all.
    def set_modulation_1_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @modulation_1_polarity = clamped + clamped
      @modulation_1_depth = @modulation_1_amount * @modulation_1_polarity
    end

    def set_modulation_2_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @modulation_2_polarity = clamped + clamped
      @modulation_2_depth = @modulation_2_amount * @modulation_2_polarity
    end

    # Pitch Amt is unipolar, [0.0, 1.0], how far the cutoff follows Pitch In, the keyboard
    # tracking: the cutoff dial and the pitch both span 120 semitones a unit, so at 1.0 the cutoff
    # follows the note a semitone for a semitone, unmoved at note 60, and at 0.0 not at all. It is
    # added on its own, as an oscillator's Pitch In is outside its Pitch Mod Amts. Pitch Pol
    # multiplies it as Mod 1 Pol does Mod 1 Amt: bipolar, [-0.5, 0.5], doubled, so at +0.5 the
    # cutoff follows the note as Pitch Amt says, at -0.5 the other way, and at 0.0 not at all.
    # Only their product, the depth, is smoothed.
    def set_pitch_amount(amount)
      @pitch_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_depth = @pitch_amount * @pitch_polarity
    end

    def set_pitch_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pitch_polarity = clamped + clamped
      @pitch_depth = @pitch_amount * @pitch_polarity
    end

    # Q range: ~0.7 (0.0), 4.0 (0.5), ~9.5 (0.75), ~40 (0.875), 256 (0.95); self-oscillation from there,
    # growing to its full level at ~0.992 and staying there to 1.0, fading out at a high cutoff.
    def set_resonance(resonance)
      @resonance = (resonance < 0.0) ? 0.0 : ((resonance > 1.0) ? 1.0 : resonance)
    end

    # Mode is unipolar, [0.0, 1.0], and crossfades Out from the low pass to the high pass: each side
    # at 1.0 over its own half and falling to 0.0 over the other, so 0.0 is the low pass alone, 1.0
    # the high pass alone, and 0.5 both at 1.0, whose sum is the input less k times the band pass: a
    # notch at the cutoff, the pass band whole. Only the two factors are smoothed.
    def set_mode(mode)
      clamped = (mode < 0.0) ? 0.0 : ((mode > 1.0) ? 1.0 : mode)
      lp = 2.0 - (clamped + clamped)
      hp = clamped + clamped
      @mode_lp = (lp > 1.0) ? 1.0 : lp
      @mode_hp = (hp > 1.0) ? 1.0 : hp
    end

    # The parameters that scale no audio themselves -- rates, depths, times -- smoothed in two
    # stages once every 16 samples, four control ticks, by the main loop for every module whatever
    # runs, so that they cost a quarter as much and the same for any patch. What multiplies the
    # audio is smoothed at every control tick, where a coarser step would be heard.
    def smooth_parameters
      @stage_1_cutoff = Dsp.smooth(@cutoff, @stage_1_cutoff, @smoothing_16_blend)
      @current_cutoff = Dsp.smooth(@stage_1_cutoff, @current_cutoff, @smoothing_16_blend)
      @stage_1_resonance = Dsp.smooth(@resonance, @stage_1_resonance, @smoothing_16_blend)
      @current_resonance = Dsp.smooth(@stage_1_resonance, @current_resonance, @smoothing_16_blend)
      @stage_1_modulation_1_depth = Dsp.smooth(@modulation_1_depth, @stage_1_modulation_1_depth, @smoothing_16_blend)
      @current_modulation_1_depth = Dsp.smooth(@stage_1_modulation_1_depth, @current_modulation_1_depth, @smoothing_16_blend)
      @stage_1_modulation_2_depth = Dsp.smooth(@modulation_2_depth, @stage_1_modulation_2_depth, @smoothing_16_blend)
      @current_modulation_2_depth = Dsp.smooth(@stage_1_modulation_2_depth, @current_modulation_2_depth, @smoothing_16_blend)
      @stage_1_pitch_depth = Dsp.smooth(@pitch_depth, @stage_1_pitch_depth, @smoothing_16_blend)
      @current_pitch_depth = Dsp.smooth(@stage_1_pitch_depth, @current_pitch_depth, @smoothing_16_blend)
    end

    def process(control_tick, audio_input_1 = 0.0, audio_input_2 = 0.0, pitch_input = 0.0, modulation_1_input = 0.0, modulation_2_input = 0.0)
      @current_pitch_input = pitch_input
      @current_modulation_1_input = modulation_1_input
      @current_modulation_2_input = modulation_2_input

      if control_tick
        update_coefficients
        @s1 = Dsp.flush_tiny(@s1) + @self_osc_seed
        @s2 = Dsp.flush_tiny(@s2)
        @dc_blocker = Dsp.flush_tiny(@dc_blocker)
        @dc_blocker_hp = Dsp.flush_tiny(@dc_blocker_hp)
        @dc_blocker_bp = Dsp.flush_tiny(@dc_blocker_bp)
        @self_osc_seed = 0.0 - @self_osc_seed
      end

      audio_input = audio_input_1 * @current_gain_1 + audio_input_2 * @current_gain_2

      @g += @g_slope
      @g_plus_k += @g_plus_k_slope
      @one_over_a0 += @one_over_a0_slope

      # The clamp is a guard that ordinary use never reaches: nothing else bounds the low pass
      # state, and a cutoff thrown across its range every step, as audio on the modulation input
      # at full depth does, with k negative at the top of the resonance dial, is where to expect
      # it if anywhere. Clamped the way clip_output clamps.
      s2_over  = @s2 - LOW_PASS_STATE_CEILING
      s2_under = LOW_PASS_STATE_FLOOR - @s2
      s2 = @s2 - ((s2_over + s2_over.abs) - (s2_under + s2_under.abs)) * 0.5

      # With the high pass x - s2 - (g + k) * y, the band pass y = s1 + g * high_pass - h * leak(y)
      # (the trapezoidal rule on the equation LEAK_RATE describes, h being @leak_step) is
      #   a0 * y + h * leak(y) = b,  a0 = 1 + g * (g + k),  b = s1 + g * (x - s2)
      # Without the leak, y = b / a0: that is the guess, from the control-rate 1 / a0, so no
      # division for it. The leak is small next to a0 * y wherever the curve is nearly straight,
      # so one Newton step from there lands within 1e-5 of the root on a loud input and much
      # closer on an ordinary one; starting from the last sample's y instead, the step falls short
      # at a high cutoff, where y moves far between samples, and lifts the self-oscillation there.
      # The denominator, a0 + h * leak'(y), is at least a0 - 0.001 * h, since the clip's slope
      # never exceeds its make-up gain, 1.001: well clear of zero, as a0 stays above 0.99 with k
      # held at SELF_OSC_K_FLOOR. No branch: the clamp is built as clip_output's is.
      # This is neither the delayed soft clipping it replaces, which clipped the band pass state of
      # the previous sample before the linear solve, nor the "gain prediction" of the KVR thread,
      # which puts a gain predicted from the previous sample into the linear solve: the leak is
      # evaluated at this sample's linear solution, and Newton's step takes it off.
      b =@s1 + @g * (audio_input - s2)
      a0 = 1.0 + @g * @g_plus_k
      guess = b * @one_over_a0
      shifted = guess + SOFT_CLIP_BIAS
      over    = shifted - SOFT_CLIP_CEILING
      under   = SOFT_CLIP_FLOOR - shifted
      clamped = shifted - ((over + over.abs) - (under + under.abs)) * 0.5
      clamped_squared = clamped * clamped
      leak = guess - clamped * (SOFT_CLIP_BIAS_GAIN - clamped_squared * LEAK_CLIP_GAIN_SCALE) + LEAK_CLIP_OFFSET
      leak_slope = LEAK_SLOPE_OFFSET + clamped_squared * LEAK_SLOPE_SCALE
      band_pass = guess - (a0 * guess + @leak_step * leak - b) / (a0 + @leak_step * leak_slope)

      # Two trapezoidal integrators in series. Each new state is twice the output less the old
      # state, s1 + 2 * (g * high_pass - h * leak) and s2 + 2 * g * y, the leak taken as Newton's
      # step took it, which is what makes y satisfy its equation to the last bit.
      low_pass = s2 + @g * band_pass
      # The high pass as the loop has it, x - s2 - (g + k) * y, taken from the solved band pass,
      # so that with the band pass the three add up as a state variable filter's do:
      # x = lp + k * bp + hp.
      high_pass = audio_input - s2 - @g_plus_k * band_pass
      @s1 = band_pass + band_pass - @s1
      @s2 = low_pass + low_pass - s2

      # Ahead of clip_output, so that the output limit holds on what actually leaves. The leak's
      # bias gives the state a DC that reaches every output, so each has a blocker of its own. The
      # band pass is the state itself, unnormalized: its peak at the cutoff is Q times the input.
      @dc_blocker_hp += (high_pass - @dc_blocker_hp) * @dc_blocker_coefficient
      @output_hp = clip_output(high_pass - @dc_blocker_hp)
      @dc_blocker += (low_pass - @dc_blocker) * @dc_blocker_coefficient
      @output_lp = clip_output(low_pass - @dc_blocker)
      @dc_blocker_bp += (band_pass - @dc_blocker_bp) * @dc_blocker_coefficient
      @output_bp = clip_output(band_pass - @dc_blocker_bp)
      # Taken from the two outputs as they leave, so not clipped again: in the pass band one side
      # is all there is, and around the cutoff, where both are, the notch takes them down.
      @output_lp * @current_mode_lp + @output_hp * @current_mode_hp
    end

    # The low pass, the high pass and the band pass of the last sample process took, read after it
    # as Chorus's outputs are.
    def output_lp
      @output_lp
    end

    def output_hp
      @output_hp
    end

    def output_bp
      @output_bp
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
    # staircase at a quarter of the sample rate. process forms a0 from g and g + k itself, so the
    # equation it solves is exact all along the ramp; 1 / a0, ramped on its own, only feeds the
    # guess, and Newton's step takes up the difference. Each ramp starts from the stored set
    # rather than from where the additions got to, so rounding does not build up. 0.25 is
    # 1 / CONTROL_RATE_DIVISOR, written out for the reason Mixer#process gives.
    def update_coefficients
      @stage_1_mode_lp = Dsp.smooth(@mode_lp, @stage_1_mode_lp, @smoothing_target_blend)
      @current_mode_lp = Dsp.smooth(@stage_1_mode_lp, @current_mode_lp, @smoothing_target_blend)
      @stage_1_mode_hp = Dsp.smooth(@mode_hp, @stage_1_mode_hp, @smoothing_target_blend)
      @current_mode_hp = Dsp.smooth(@stage_1_mode_hp, @current_mode_hp, @smoothing_target_blend)
      @stage_1_gain_1 = Dsp.smooth(@gain_1, @stage_1_gain_1, @smoothing_target_blend)
      @current_gain_1 = Dsp.smooth(@stage_1_gain_1, @current_gain_1, @smoothing_target_blend)
      @stage_1_gain_2 = Dsp.smooth(@gain_2, @stage_1_gain_2, @smoothing_target_blend)
      @current_gain_2 = Dsp.smooth(@stage_1_gain_2, @current_gain_2, @smoothing_target_blend)

      # The pitch and modulation inputs arrive as they are; clamping total_cutoff below is what holds
      # the table lookup in range, and a source that swings both ways moves the cutoff both ways.
      # Clamped without a comparison, as clip_output does it.
      modulation = (@current_modulation_1_input * @current_modulation_1_depth) + (@current_modulation_2_input * @current_modulation_2_depth)
      total_cutoff = @current_cutoff + @current_pitch_input * @current_pitch_depth + modulation
      over  = total_cutoff - 1.0
      under = 0.0 - total_cutoff
      clamped_cutoff = total_cutoff - ((over + over.abs) - (under + under.abs)) * 0.5

      g = cutoff_to_g_fast(clamped_cutoff)

      # The resonance past SELF_OSC_START, scaled down toward it by the fade's weight, so that a
      # high cutoff fades out the self-oscillation as SELF_OSC_FADE_WIDTH describes. Each clamp
      # is built as clip_output builds its own.
      weight = @self_osc_fade_offset - clamped_cutoff * @self_osc_fade_scale
      over  = weight - 1.0
      under = 0.0 - weight
      weight = weight - ((over + over.abs) - (under + under.abs)) * 0.5
      self_osc_over = @current_resonance - SELF_OSC_START
      self_osc_over = (self_osc_over + self_osc_over.abs) * 0.5
      resonance = @current_resonance - self_osc_over * (1.0 - weight)

      # The self-oscillation amount: zero up to r = 114/120 (CC 118), rising to one at 119/120
      # (CC 123) and held there.
      t = resonance * 24.0 - 22.8
      over  = t - 1.0
      under = 0.0 - t
      t = t - ((over + over.abs) - (under + under.abs)) * 0.5
      k = resonance_to_k_fast(resonance) - t * @self_osc_kappa / g
      below_floor = SELF_OSC_K_FLOOR - k
      k = k + (below_floor + below_floor.abs) * 0.5
      g_plus_k = g + k
      one_over_a0 = 1.0 / (1.0 + g * g_plus_k)

      @g = @last_g
      @g_plus_k = @last_g_plus_k
      @one_over_a0 = @last_one_over_a0
      @g_slope = (g - @last_g) * 0.25
      @g_plus_k_slope = (g_plus_k - @last_g_plus_k) * 0.25
      @one_over_a0_slope = (one_over_a0 - @last_one_over_a0) * 0.25
      @last_g = g
      @last_g_plus_k = g_plus_k
      @last_one_over_a0 = one_over_a0
    end

    # Bounds what the module hands to the bus. Separate from the leak, which holds the band pass
    # down inside the loop at a much higher level and has to stay where it is. With only the band
    # pass held, a high Q on a loud input reaches the shoulder here.
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
  end
end
