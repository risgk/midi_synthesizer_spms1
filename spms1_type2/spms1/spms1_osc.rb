module Spms1
  # PolyBLEP-based saw/square morph oscillator for anti-aliased waveform transitions. Besides the
  # morph, which process returns, it puts out its two ends on their own: output_saw, the sawtooth,
  # and output_pulse, the pulse at its pulse width, as the morph is at 1.0, whatever Wave is. And
  # output_sub, a sine an octave down, locked to the sawtooth's phase: it starts each of its cycles
  # where every other cycle of the sawtooth starts.
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
    # What a pitch modulation depth of 1.0 is worth: 120 semitones per unit of input, which is the
    # whole pitch range. A bipolar source at full depth reaches half a unit either way, so at 1.0 it
    # would swing the pitch five octaves up and five down; the default patch's Pitch Mod Range
    # brings the depth down to 0.2 at the top of each Pitch Mod Amt, an octave either way, and two
    # octaves up for the envelope.
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
      @sub_toggle = 0.0
      @output_sub = 0.0
      @waveform = 0.0
      @stage_1_waveform = 0.0
      @current_waveform = 0.0
      @pulse_width = 0.0
      @stage_1_pulse_width = 0.0
      @current_pulse_width = 0.0
      # Mod 1 In and Mod 2 In each move the pitch by a Pitch Mod Amt of their own and the pulse
      # width by a PW Mod Amt of their own. Pitch In has no depth: the note it carries is added
      # whole, a key a semitone, and plays in tune from the first sample.
      # Each Pitch Mod Amt, Pitch Mod Range and the Pitch Mod Sw of the input are multiplied
      # before smoothing, so only their product, the depth, carries a smoothing state.
      @pitch_modulation_range = 1.0
      @pitch_modulation_1_on = 1.0
      @pitch_modulation_2_on = 1.0
      @pitch_modulation_1_amount = 0.0
      @pitch_modulation_1_depth = 0.0
      @stage_1_pitch_modulation_1_depth = 0.0
      @current_pitch_modulation_1_depth = 0.0
      @pitch_modulation_2_amount = 0.0
      @pitch_modulation_2_depth = 0.0
      @stage_1_pitch_modulation_2_depth = 0.0
      @current_pitch_modulation_2_depth = 0.0
      @pw_modulation_1_amount = 0.0
      @stage_1_pw_modulation_1_amount = 0.0
      @current_pw_modulation_1_amount = 0.0
      @pw_modulation_2_amount = 0.0
      @stage_1_pw_modulation_2_amount = 0.0
      @current_pw_modulation_2_amount = 0.0
      @pitch_coarse = 0.0
      @pitch_fine = 0.0
      # Pitch Coarse and Pitch Fine are summed when set, so the per-sample path adds one offset rather
      # than two.
      @tune = 0.0
      @output_saw = 0.0
      @output_pulse = 0.0
      # Sync In of the last sample: a restart is taken where it rises from there through zero.
      @sync_last = 0.0
      @sync_switch = 0.0
    end

    # Sync Sw: Sync In is taken at 0.5 and above, and ignored below.
    def set_sync_switch(switch)
      @sync_switch = (switch >= 0.5) ? 1.0 : 0.0
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

    # Every modulation depth is unipolar, [0.0, 1.0], a plain multiplier on its input, so a
    # modulation runs the way its source does; one the other way up takes an inverted source, such
    # as EG 1 Out Inv. The pitch's depths are each Pitch Mod Amt times Pitch Mod Range, also
    # unipolar, a plain multiplier that sets what the top of a Pitch Mod Amt is worth; they are
    # scaled here rather than per sample, so the smoothed values are already in pitch units. A unit
    # of input times a PW Mod Amt is the whole pulse width range, so at full depth a bipolar source
    # swings it half the range either way, and a unipolar one across all of it.
    def set_pitch_modulation_1_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_1_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_range * @pitch_modulation_1_on
    end

    def set_pitch_modulation_2_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_2_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_range * @pitch_modulation_2_on
    end

    # Pitch Mod 1 Sw and Pitch Mod 2 Sw are unipolar, [0.0, 1.0], and each lets its input
    # move the pitch from 0.5 (CC 64) up. Off, the depth goes to 0.0, smoothed as a depth is, and the
    # Pitch Mod Amt is kept for when it is on again. The pulse width's modulation is not switched.
    def set_pitch_modulation_1_switch(switch)
      @pitch_modulation_1_on = (switch >= 0.5) ? 1.0 : 0.0
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_range * @pitch_modulation_1_on
    end

    def set_pitch_modulation_2_switch(switch)
      @pitch_modulation_2_on = (switch >= 0.5) ? 1.0 : 0.0
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_range * @pitch_modulation_2_on
    end

    def set_pitch_modulation_range(range)
      @pitch_modulation_range = (range < 0.0) ? 0.0 : ((range > 1.0) ? 1.0 : range)
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_range * @pitch_modulation_1_on
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_range * @pitch_modulation_2_on
    end

    def set_pw_modulation_1_amount(amount)
      @pw_modulation_1_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    def set_pw_modulation_2_amount(amount)
      @pw_modulation_2_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
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
      update_controls if control_tick

      pitch_modulation = (modulation_1_input * @current_pitch_modulation_1_depth) + (modulation_2_input * @current_pitch_modulation_2_depth)
      total_pitch = pitch_input + @tune + pitch_modulation
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
      pw_modulation = (modulation_1_input * @current_pw_modulation_1_amount) + (modulation_2_input * @current_pw_modulation_2_amount)
      total_pulse_width = @current_pulse_width + pw_modulation
      pulse_width = (total_pulse_width < -0.5) ? -0.5 : ((total_pulse_width > 0.5) ? 0.5 : total_pulse_width)
      phase2 = @phase + (0.5 + pulse_width)
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt, current_dt_inv)
      saw2 = naive_saw2 + blep2

      output = saw1 - (saw2 * @current_waveform)

      # The sub's phase is the sawtooth's, counted over two of its cycles: @sub_toggle is 1.0 over
      # every other one, flipped at each wrap. A sine has nothing to alias, so it takes no
      # correction. It is a parabola, 4x(1 - |x|) over x in [-1, 1], bent toward the sine by the
      # usual 0.225 refinement, within 0.1% of it; no table, and no branch.
      x = @phase + @sub_toggle - 1.0
      parabola = 4.0 * x * (1.0 - x.abs)
      sub = 0.225 * (parabola * parabola.abs - parabola) + parabola

      @phase += current_dt
      wrapped = (@phase < 1.0) ? 0.0 : 1.0
      @phase -= wrapped
      toggle = @sub_toggle + wrapped
      @sub_toggle = (toggle < 2.0) ? toggle : 0.0

      # Halved so that both ends of the morph come out at one unit peak to peak, the same span
      # as every other bipolar signal on the bus. How loudly it drives what comes next is the
      # receiving module's business, not this one's. The two ends on their own are halved alike.
      @output_saw = saw1 * 0.5
      @output_pulse = (saw1 - saw2) * 0.5
      @output_sub = sub * -0.5
      output * 0.5
    end

    # process with Sync In, which restarts the phase where it rises through zero, from zero or below
    # on the last sample to above it on this one, as a comparator on an analog oscillator's sync input
    # does: another oscillator's sawtooth, at its wrap, or a gate, at a note on. Where between the
    # two samples it crossed is found by drawing a line between them, and the phase starts this
    # sample as far past 0.0 as the time since then takes it, so the synced wave repeats with the
    # period of what it is synced to, where a restart rounded to a sample would make the period
    # jitter by a sample. A sawtooth's PolyBLEP rounds its step off evenly about where it falls, so
    # the line crosses close to it. The step the restart makes in the wave is left as it is, not
    # smoothed. Sync In is taken only with Sync Sw on. The sub is left out: only an oscillator run by process, Osc 1 in the patch, has Out Sub.
    # Without a restart the output is the same as process's to the bit.
    def process_synced(control_tick, pitch_input = 0.0, modulation_1_input = 0.0, modulation_2_input = 0.0, sync_input = 0.0)
      update_controls if control_tick

      pitch_modulation = (modulation_1_input * @current_pitch_modulation_1_depth) + (modulation_2_input * @current_pitch_modulation_2_depth)
      total_pitch = pitch_input + @tune + pitch_modulation
      pitch = (total_pitch < -0.5) ? -0.5 : ((total_pitch > 0.5) ? 0.5 : total_pitch)
      freq = pitch_to_freq_fast(pitch)
      current_dt = freq * @inv_sample_rate
      current_dt_inv = 1.0 / current_dt

      # The crossing, at crossed_at from the last sample, 0.0, to this one, 1.0. The span is held
      # below zero, so that the division is finite where Sync In has not risen; it is used only
      # where it has, and a rise is never smaller than the floor but by a step of a millionth.
      from_below = (@sync_last > 0.0) ? 0.0 : 1.0
      restart = (sync_input > 0.0) ? from_below * @sync_switch : 0.0
      span = @sync_last - sync_input
      span = (span < -0.000001) ? span : -0.000001
      crossed_at = @sync_last / span
      @sync_last = sync_input
      @phase += restart * ((1.0 - crossed_at) * current_dt - @phase)

      naive_saw1 = -2.0 * @phase + 1.0
      blep1 = poly_blep(@phase, current_dt, current_dt_inv)
      saw1 = naive_saw1 + blep1

      pw_modulation = (modulation_1_input * @current_pw_modulation_1_amount) + (modulation_2_input * @current_pw_modulation_2_amount)
      total_pulse_width = @current_pulse_width + pw_modulation
      pulse_width = (total_pulse_width < -0.5) ? -0.5 : ((total_pulse_width > 0.5) ? 0.5 : total_pulse_width)
      phase2 = @phase + (0.5 + pulse_width)
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt, current_dt_inv)
      saw2 = naive_saw2 + blep2

      output = saw1 - (saw2 * @current_waveform)

      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0

      @output_saw = saw1 * 0.5
      @output_pulse = (saw1 - saw2) * 0.5
      output * 0.5
    end

    # The sawtooth, the pulse and the sub of the last sample process or process_synced took (the sub
    # from process alone), read after it as Chorus's outputs are.
    def output_saw
      @output_saw
    end

    def output_pulse
      @output_pulse
    end

    def output_sub
      @output_sub
    end


    private

    def update_controls
      # Morph, pulse width and depth are smoothed at the control rate to avoid sudden jumps.
      @stage_1_waveform = Dsp.smooth(@waveform, @stage_1_waveform, @smoothing_target_blend)
      @current_waveform = Dsp.smooth(@stage_1_waveform, @current_waveform, @smoothing_target_blend)
      @stage_1_pulse_width = Dsp.smooth(@pulse_width, @stage_1_pulse_width, @smoothing_target_blend)
      @current_pulse_width = Dsp.smooth(@stage_1_pulse_width, @current_pulse_width, @smoothing_target_blend)
      @stage_1_pitch_modulation_1_depth = Dsp.smooth(@pitch_modulation_1_depth, @stage_1_pitch_modulation_1_depth, @smoothing_target_blend)
      @current_pitch_modulation_1_depth = Dsp.smooth(@stage_1_pitch_modulation_1_depth, @current_pitch_modulation_1_depth, @smoothing_target_blend)
      @stage_1_pitch_modulation_2_depth = Dsp.smooth(@pitch_modulation_2_depth, @stage_1_pitch_modulation_2_depth, @smoothing_target_blend)
      @current_pitch_modulation_2_depth = Dsp.smooth(@stage_1_pitch_modulation_2_depth, @current_pitch_modulation_2_depth, @smoothing_target_blend)
      @stage_1_pw_modulation_1_amount = Dsp.smooth(@pw_modulation_1_amount, @stage_1_pw_modulation_1_amount, @smoothing_target_blend)
      @current_pw_modulation_1_amount = Dsp.smooth(@stage_1_pw_modulation_1_amount, @current_pw_modulation_1_amount, @smoothing_target_blend)
      @stage_1_pw_modulation_2_amount = Dsp.smooth(@pw_modulation_2_amount, @stage_1_pw_modulation_2_amount, @smoothing_target_blend)
      @current_pw_modulation_2_amount = Dsp.smooth(@stage_1_pw_modulation_2_amount, @current_pw_modulation_2_amount, @smoothing_target_blend)
    end

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
