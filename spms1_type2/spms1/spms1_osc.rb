module Spms1
  # PolyBLEP-based saw/square morph oscillator for anti-aliased waveform transitions. Besides the
  # morph, which process returns, it puts out its two ends on their own: output_saw, the sawtooth,
  # and output_pulse, the pulse at its pulse width, as the morph is at 1.0, whatever Wave is.
  class Osc
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
    # What a pitch modulation depth of 1.0 is worth: 120 semitones per unit of the modulation sum,
    # which is the whole pitch range. A bipolar source at full depth reaches half a unit either way,
    # so at 1.0 it would swing the pitch five octaves up and five down; the default patch's Pitch
    # Mod Scale brings the depth down to 0.2 at the top of Pitch Mod Amt, an octave either way, and
    # two octaves up for the envelope.
    MODULATION_RANGE = 120.0 / 120.0
    # How far Pitch Coarse and Pitch Fine reach at either end of their dials. Both are spaced so that one step
    # of a 7-bit control is one whole unit: a semitone for coarse, a cent for fine.
    PITCH_COARSE_RANGE = 60.0 / 120.0
    PITCH_FINE_RANGE   = 0.6 / 120.0

    # Pitch lookup table for note-to-frequency conversion.
    FREQ_TABLE = Array.new(129, 0.0)
    for i in 0...129
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 69.0) * (1.0 / 12.0)))
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      # Reciprocal kept alongside the rate so process multiplies rather than divides. @sample_rate
      # is an Integer, so dividing by it in the per-sample path also costs an int-to-float
      # conversion on top of the division.
      @inv_sample_rate = 1.0 / sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @phase = 0.0
      @waveform = 0.0
      @stage_1_waveform = 0.0
      @current_waveform = 0.0
      @pulse_width = 0.0
      @stage_1_pulse_width = 0.0
      @current_pulse_width = 0.0
      # Mod 1 In and Mod 2 In are summed, each at its share of Mod 1/2 Mix, and the sum moves the
      # pitch by Pitch Mod Amt and the pulse width by PW Mod Amt. Pitch In has no depth: the note it carries is
      # added whole, a key a semitone, and plays in tune from the first sample.
      @modulation_1_amount = 0.0
      @stage_1_modulation_1_amount = 0.0
      @current_modulation_1_amount = 0.0
      @modulation_2_amount = 1.0
      @stage_1_modulation_2_amount = 1.0
      @current_modulation_2_amount = 1.0
      # Pitch Mod Amt and Pitch Mod Range are multiplied before smoothing, so only their product,
      # the depth, carries a smoothing state.
      @pitch_modulation_amount = 0.0
      @pitch_modulation_range = 1.0
      @pitch_modulation_depth = 0.0
      @stage_1_pitch_modulation_depth = 0.0
      @current_pitch_modulation_depth = 0.0
      @pw_modulation_amount = 0.0
      @stage_1_pw_modulation_amount = 0.0
      @current_pw_modulation_amount = 0.0
      @pitch_coarse = 0.0
      @pitch_fine = 0.0
      # Pitch Coarse and Pitch Fine are summed when set, so the per-sample path adds one offset rather
      # than two.
      @tune = 0.0
      @output_saw = 0.0
      @output_pulse = 0.0
    end

    # Waveform morph is unipolar, [0.0, 1.0].
    # 0.0 = sawtooth, 0.5 = 50% morph, 1.0 = square.
    def set_waveform(waveform)
      @waveform = (waveform < 0.0) ? 0.0 : ((waveform > 1.0) ? 1.0 : waveform)
    end

    # Pulse width is bipolar, [-0.5, 0.5]: how far the second sawtooth is shifted from half a cycle.
    # At the square end of the morph, 0.0 is a pulse of 50%, +0.25 one of 25% and +0.5 one of 0%,
    # -0.25 one of 75% and -0.5 one of 100%; both ends are silence, as the two sawtooths then
    # cancel. Between the two ends of the morph it moves the second sawtooth of the blend in the
    # same way.
    def set_pulse_width(pulse_width)
      @pulse_width = (pulse_width < -0.5) ? -0.5 : ((pulse_width > 0.5) ? 0.5 : pulse_width)
    end

    # Mod 1/2 Mix is bipolar, [-0.5, 0.5], a linear crossfade between the two modulation inputs:
    # Mod 1 In is taken at 0.5 - mix and Mod 2 In at 0.5 + mix, so -0.5 is Mod 1 alone, +0.5 Mod 2
    # alone and 0.0 half of each. A modulation runs the way its source does; one the other way up
    # takes an inverted source, such as a mixer's at Pol -0.5.
    def set_modulation_mix(mix)
      clamped_mix = (mix < -0.5) ? -0.5 : ((mix > 0.5) ? 0.5 : mix)
      @modulation_1_amount = 0.5 - clamped_mix
      @modulation_2_amount = 0.5 + clamped_mix
    end

    # Pitch Mod Amt and PW Mod Amt are unipolar, [0.0, 1.0], how far the modulation sum moves
    # each. The pitch's depth is Pitch Mod Amt times Pitch Mod Range, also unipolar, [0.0, 1.0], a
    # plain multiplier that sets what the top of Pitch Mod Amt is worth; it is scaled here rather
    # than per sample, so the smoothed value is already in pitch units. A unit of sum times
    # PW Mod Amt is the whole pulse width range, so at full depth a bipolar source swings it half
    # the range either way, and a unipolar one across all of it.
    def set_pitch_modulation_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_depth = @pitch_modulation_amount * @pitch_modulation_range
    end

    def set_pitch_modulation_range(range)
      @pitch_modulation_range = (range < 0.0) ? 0.0 : ((range > 1.0) ? 1.0 : range)
      @pitch_modulation_depth = @pitch_modulation_amount * @pitch_modulation_range
    end

    def set_pw_modulation_amount(amount)
      @pw_modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # Pitch Coarse and Pitch Fine are both bipolar, [-0.5, 0.5], with 0.0 meaning no offset, so a controller's
    # centre detent lands there. Linear about that centre, which is what puts every step on a whole
    # semitone or a whole cent; a curve here would make exact intervals unreachable.
    # Not smoothed: a semitone step is part of the sound, a cent step is too small to hear as one,
    # and a step in pitch does not click, as the phase runs on unbroken.
    def set_pitch_coarse(pitch_coarse)
      clamped = (pitch_coarse < -0.5) ? -0.5 : ((pitch_coarse > 0.5) ? 0.5 : pitch_coarse)
      @pitch_coarse = (clamped + clamped) * PITCH_COARSE_RANGE
      @tune = @pitch_coarse + @pitch_fine
    end

    def set_pitch_fine(pitch_fine)
      clamped = (pitch_fine < -0.5) ? -0.5 : ((pitch_fine > 0.5) ? 0.5 : pitch_fine)
      @pitch_fine = (clamped + clamped) * PITCH_FINE_RANGE
      @tune = @pitch_coarse + @pitch_fine
    end

    # The inputs are taken as they arrive; what is held to a range is the pitch they add up to.
    # [-0.5, 0.5] is that range, covering MIDI notes 0 to 120, and it is what keeps the table
    # lookup in bounds. The pulse width its modulations add up to is held to its own, [-0.5, 0.5].
    # The modulation inputs are deliberately not smoothed, so a fast source reaches the pitch and
    # the pulse width unslewed.
    def process(control_tick, pitch_input = 0.0, modulation_1_input = 0.0, modulation_2_input = 0.0)
      if control_tick
        # Morph, pulse width and depth are smoothed at the control rate to avoid sudden jumps.
        @stage_1_waveform = Dsp.smooth(@waveform, @stage_1_waveform, @smoothing_target_blend)
        @current_waveform = Dsp.smooth(@stage_1_waveform, @current_waveform, @smoothing_target_blend)
        @stage_1_pulse_width = Dsp.smooth(@pulse_width, @stage_1_pulse_width, @smoothing_target_blend)
        @current_pulse_width = Dsp.smooth(@stage_1_pulse_width, @current_pulse_width, @smoothing_target_blend)
        @stage_1_modulation_1_amount = Dsp.smooth(@modulation_1_amount, @stage_1_modulation_1_amount, @smoothing_target_blend)
        @current_modulation_1_amount = Dsp.smooth(@stage_1_modulation_1_amount, @current_modulation_1_amount, @smoothing_target_blend)
        @stage_1_modulation_2_amount = Dsp.smooth(@modulation_2_amount, @stage_1_modulation_2_amount, @smoothing_target_blend)
        @current_modulation_2_amount = Dsp.smooth(@stage_1_modulation_2_amount, @current_modulation_2_amount, @smoothing_target_blend)
        @stage_1_pitch_modulation_depth = Dsp.smooth(@pitch_modulation_depth, @stage_1_pitch_modulation_depth, @smoothing_target_blend)
        @current_pitch_modulation_depth = Dsp.smooth(@stage_1_pitch_modulation_depth, @current_pitch_modulation_depth, @smoothing_target_blend)
        @stage_1_pw_modulation_amount = Dsp.smooth(@pw_modulation_amount, @stage_1_pw_modulation_amount, @smoothing_target_blend)
        @current_pw_modulation_amount = Dsp.smooth(@stage_1_pw_modulation_amount, @current_pw_modulation_amount, @smoothing_target_blend)
      end

      modulation = (modulation_1_input * @current_modulation_1_amount) + (modulation_2_input * @current_modulation_2_amount)
      total_pitch = pitch_input + @tune + modulation * @current_pitch_modulation_depth
      pitch = (total_pitch < -0.5) ? -0.5 : ((total_pitch > 0.5) ? 0.5 : total_pitch)
      freq = pitch_to_freq_fast(pitch)
      current_dt = freq * @inv_sample_rate
      # Both poly_blep calls below work against this same dt, so its reciprocal is taken once here
      # and passed in, rather than dividing twice inside each call.
      current_dt_inv = 1.0 / current_dt

      naive_saw1 = -2.0 * @phase + 1.0
      blep1 = poly_blep(@phase, current_dt, current_dt_inv)
      saw1 = naive_saw1 + blep1

      # The pulse width is held to its range after the modulation is added, which also keeps the
      # shift within one cycle, so that a single wrap below brings phase2 back under 1.0.
      total_pulse_width = @current_pulse_width + modulation * @current_pw_modulation_amount
      pulse_width = (total_pulse_width < -0.5) ? -0.5 : ((total_pulse_width > 0.5) ? 0.5 : total_pulse_width)
      phase2 = @phase + (0.5 + pulse_width)
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt, current_dt_inv)
      saw2 = naive_saw2 + blep2

      output = saw1 - (saw2 * @current_waveform)
      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0

      # Halved so that both ends of the morph come out at one unit peak to peak, the same span
      # as every other bipolar signal on the bus. How loudly it drives what comes next is the
      # receiving module's business, not this one's. The two ends on their own are halved alike.
      @output_saw = saw1 * 0.5
      @output_pulse = (saw1 - saw2) * 0.5
      output * 0.5
    end

    # The sawtooth and the pulse of the last sample process took, read after it as Chorus's
    # outputs are.
    def output_saw
      @output_saw
    end

    def output_pulse
      @output_pulse
    end

    private

    def pitch_to_freq_fast(pitch)
      internal_pitch = (pitch + 0.5) * 120.0
      index = internal_pitch.to_i
      fraction = internal_pitch - index.to_f
      f0 = FREQ_TABLE[index]
      f1 = FREQ_TABLE[index + 1]
      f0 + fraction * (f1 - f0)
    end

    # PolyBLEP correction for discontinuity smoothing at the waveform wrap point.
    # dt_inv (1.0 / dt) comes from the caller so this multiplies instead of dividing; see process.
    # Written as the LFO's PolyBLAMP is, so that the C compiler keeps it branchless: each select
    # only clamps a distance at zero, with nothing on either side for GCC to move inside a branch,
    # and the correction is computed every sample whatever the phase, so the cost is the same at
    # every sample and the worst case is the usual one. The residual is -(1 - t/dt)^2 just past a
    # wrap and (1 - (1 - t)/dt)^2 just before one, that is, the square of how far within dt of the
    # wrap the sample is, in units of dt: zero away from both wraps. The pitch range keeps dt
    # under 0.5, so the two never overlap.
    def poly_blep(t, dt, dt_inv)
      start_gap = dt - t
      start = (start_gap > 0.0) ? start_gap : 0.0
      end_gap = t - (1.0 - dt)
      ending = (end_gap > 0.0) ? end_gap : 0.0
      num_start = start * dt_inv
      num_end = ending * dt_inv
      num_end * num_end - num_start * num_start
    end
  end
end
