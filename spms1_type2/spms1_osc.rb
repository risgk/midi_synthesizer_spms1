module Spms1
  # PolyBLEP-based saw/square morph oscillator for anti-aliased waveform transitions.
  class Osc
    # Blend at the reference rate on the line below, for each of two cascaded stages. The two move
    # together: their product is what fixes the time constant, so changing one without the other
    # changes how fast smoothing is. Two stages at 1/64 (5.3 ms each at 48 kHz) delay a step by
    # 10.7 ms on average, as one stage at 1/128 would, but start from zero slope, so that the steps
    # of a controller sending sparse CCs (e.g. every 20 ms) are rounded off rather than heard,
    # and settle sooner, 99% in 35 ms.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately
    # constant if this is changed. It has to stay a power of two: the counter below wraps with a
    # mask, because Ruby's % is a floor-modulo and sp_imod carries a sign correction the counter
    # can never need -- one branch a sample in each module, six across the six of them.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction survives into the per-sample path carrying an overflow check of its own, which
    # measured far worse than the modulo it replaces. What the mask buys is size, not
    # determinism: the six branches it removes, one per site, are ones that could never be taken.
    # Together with the LFO's fold it took 11 branches and 60 instructions out of Spms1_main as
    # linked, and the buffer time did not move (853/857us against 854/856).
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1
    # What a modulation depth of 1.0 is worth: 120 semitones per unit of modulation input, which is
    # the whole pitch range. A bipolar source reaches half a unit either way, so at full depth it
    # swings the pitch five octaves up and five down. Bringing a source down to a musical depth is
    # a mixer's job, not this one's.
    MODULATION_RANGE = 120.0 / 120.0
    # How far each tune control reaches at either end of its dial. Both are spaced so that one step
    # of a 7-bit control is one whole unit: a semitone for coarse, a cent for fine.
    COARSE_TUNE_RANGE = 60.0 / 120.0
    FINE_TUNE_RANGE   = 0.6 / 120.0

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
      # Amount and polarity are multiplied before smoothing, so only one smoothing state has to be
      # carried.
      @pitch_modulation_amount = 0.0
      @pitch_modulation_polarity = 1.0
      @pitch_modulation_depth = 0.0
      @stage_1_pitch_modulation_depth = 0.0
      @current_pitch_modulation_depth = 0.0
      # The pulse width modulation has a depth of its own, carried the same way.
      @pw_modulation_amount = 0.0
      @pw_modulation_polarity = 1.0
      @pw_modulation_depth = 0.0
      @stage_1_pw_modulation_depth = 0.0
      @current_pw_modulation_depth = 0.0
      @coarse_tune = 0.0
      @fine_tune = 0.0
      # The two tune controls are summed when set, so the per-sample path adds one offset rather
      # than two.
      @tune = 0.0
      @sample_counter = 0
    end

    # Waveform morph is unipolar, [0.0, 1.0].
    # 0.0 = sawtooth, 0.5 = 50% morph, 1.0 = square.
    def set_waveform(waveform)
      @waveform = (waveform < 0.0) ? 0.0 : ((waveform > 1.0) ? 1.0 : waveform)
    end

    # Pulse width is unipolar, [0.0, 1.0]: how far the second sawtooth is shifted from half a cycle
    # toward a whole one. At the square end of the morph, 0.0 is a pulse of 50%, 0.5 one of 25% and
    # 1.0 one of 0%, which is silence, as the two sawtooths then cancel. Between the two ends of the
    # morph it moves the second sawtooth of the blend in the same way.
    def set_pulse_width(pulse_width)
      @pulse_width = (pulse_width < 0.0) ? 0.0 : ((pulse_width > 1.0) ? 1.0 : pulse_width)
    end

    # Modulation depth is amount times polarity. Amount is unipolar, [0.0, 1.0]. Polarity is
    # bipolar, [-0.5, 0.5], and doubled, so +0.5 leaves the amount as it is, -0.5 negates it and
    # the way between scales it, crossing zero; it sets depth as well as direction. Scaled here
    # rather than per sample so the smoothed value is already in pitch units.
    def set_pitch_modulation_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_depth = @pitch_modulation_amount * @pitch_modulation_polarity
    end

    def set_pitch_modulation_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pitch_modulation_polarity = clamped_polarity + clamped_polarity
      @pitch_modulation_depth = @pitch_modulation_amount * @pitch_modulation_polarity
    end

    # The pulse width modulation depth is amount times polarity, as the pitch's is. A unit of
    # pulse width modulation input times depth is the whole pulse width range, so at full depth a
    # bipolar source swings it half the range either way.
    def set_pw_modulation_amount(amount)
      @pw_modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pw_modulation_depth = @pw_modulation_amount * @pw_modulation_polarity
    end

    def set_pw_modulation_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pw_modulation_polarity = clamped_polarity + clamped_polarity
      @pw_modulation_depth = @pw_modulation_amount * @pw_modulation_polarity
    end

    # Both tune controls are bipolar, [-0.5, 0.5], with 0.0 meaning no offset, so a controller's
    # centre detent lands there. Linear about that centre, which is what puts every step on a whole
    # semitone or a whole cent; a curve here would make exact intervals unreachable.
    # Not smoothed: a semitone step is part of the sound, a cent step is too small to hear as one,
    # and a step in pitch does not click, as the phase runs on unbroken.
    def set_coarse_tune(coarse_tune)
      clamped = (coarse_tune < -0.5) ? -0.5 : ((coarse_tune > 0.5) ? 0.5 : coarse_tune)
      @coarse_tune = (clamped + clamped) * COARSE_TUNE_RANGE
      @tune = @coarse_tune + @fine_tune
    end

    def set_fine_tune(fine_tune)
      clamped = (fine_tune < -0.5) ? -0.5 : ((fine_tune > 0.5) ? 0.5 : fine_tune)
      @fine_tune = (clamped + clamped) * FINE_TUNE_RANGE
      @tune = @coarse_tune + @fine_tune
    end

    # Both inputs are taken as they arrive; what is held to a range is the pitch they add up to.
    # [-0.5, 0.5] is that range, covering MIDI notes 0 to 120, and it is what keeps the table
    # lookup in bounds. The pulse width its modulation adds up to is held to its own, [0.0, 1.0].
    # The modulation inputs are deliberately not smoothed, so a fast source reaches the pitch and
    # the pulse width unslewed.
    def process(pitch_input = 0.0, pitch_modulation_input = 0.0, pw_modulation_input = 0.0)
      if @sample_counter == 0
        # Morph, pulse width and depth are smoothed at the control rate to avoid sudden jumps.
        @stage_1_waveform = Dsp.smooth(@waveform, @stage_1_waveform, @smoothing_target_blend)
        @current_waveform = Dsp.smooth(@stage_1_waveform, @current_waveform, @smoothing_target_blend)
        @stage_1_pulse_width = Dsp.smooth(@pulse_width, @stage_1_pulse_width, @smoothing_target_blend)
        @current_pulse_width = Dsp.smooth(@stage_1_pulse_width, @current_pulse_width, @smoothing_target_blend)
        @stage_1_pitch_modulation_depth = Dsp.smooth(@pitch_modulation_depth, @stage_1_pitch_modulation_depth, @smoothing_target_blend)
        @current_pitch_modulation_depth = Dsp.smooth(@stage_1_pitch_modulation_depth, @current_pitch_modulation_depth, @smoothing_target_blend)
        @stage_1_pw_modulation_depth = Dsp.smooth(@pw_modulation_depth, @stage_1_pw_modulation_depth, @smoothing_target_blend)
        @current_pw_modulation_depth = Dsp.smooth(@stage_1_pw_modulation_depth, @current_pw_modulation_depth, @smoothing_target_blend)
      end

      total_pitch = pitch_input + @tune + (pitch_modulation_input * @current_pitch_modulation_depth)
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
      total_pulse_width = @current_pulse_width + (pw_modulation_input * @current_pw_modulation_depth)
      pulse_width = (total_pulse_width < 0.0) ? 0.0 : ((total_pulse_width > 1.0) ? 1.0 : total_pulse_width)
      phase2 = @phase + (0.5 + pulse_width * 0.5)
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt, current_dt_inv)
      saw2 = naive_saw2 + blep2

      output = saw1 - (saw2 * @current_waveform)
      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0
      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # Halved so that both ends of the morph come out at one unit peak to peak, the same span
      # as every other bipolar signal on the bus. How loudly it drives what comes next is the
      # receiving module's business, not this one's.
      output * 0.5
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
    # Both corrections are written as selects rather than conditionals, and this is the one place
    # in the per-sample path where that does not survive the C compiler. Each correction is five
    # or six operations, so GCC would rather branch around one than compute it and throw it away,
    # and it does: in the sketch each call comes out as two branches with the arithmetic moved
    # inside them. The cost here therefore does vary with the phase -- a sample next to a wrap
    # pays for a correction, one away from both wraps skips them -- and no way of writing this in
    # Ruby changes that, because the decision is the compiler's cost model, not the shape of the
    # source. Only the two comparisons are unconditional.
    def poly_blep(t, dt, dt_inv)
      num_start = t * dt_inv
      blep_start = num_start + num_start - num_start * num_start - 1.0
      num_end = (t - 1.0) * dt_inv
      blep_end = num_end * num_end + num_end + num_end + 1.0
      val = (t < dt) ? blep_start : 0.0
      (t > 1.0 - dt) ? blep_end : val
    end
  end
end
