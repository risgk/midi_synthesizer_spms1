module Spms1
  # PolyBLEP-based saw/pulse morph oscillator for anti-aliased waveform transitions. Besides the
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
    # would swing the pitch five octaves up and five down; the default patch's Pitch Mod Pols
    # bring the depth down to 0.2 at the top of each Pitch Mod Amt, an octave either way, and two
    # octaves up for the envelope.
    MODULATION_RANGE = 120.0 / 120.0
    # How far Pitch Coarse and Pitch Fine reach at either end of their dials: 60 semitones, so that one step
    # of a 7-bit control is a whole semitone, and 50 cents, so that the dial's quarters are quarter tones.
    PITCH_COARSE_RANGE = 60.0 / 120.0
    PITCH_FINE_RANGE   = 0.5 / 120.0

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
      # The blend of the parameters smoothed once every 16 samples, four control ticks (see
      # smooth_parameters): the one above taken four times over, for the same time.
      @smoothing_16_blend = 1.0 - (1.0 - @smoothing_target_blend) ** 4.0
      @phase = 0.0
      @sub_toggle = 0.0
      @output_sub = 0.0
      @waveform = 0.0
      @stage_1_waveform = 0.0
      @current_waveform = 0.0
      @pulse_width = 0.0
      @stage_1_pulse_width = 0.0
      @current_pulse_width = 0.0
      # Pitch Mod 1 In and Pitch Mod 2 In each move the pitch by a Pitch Mod Amt of their own, and
      # PW Mod 1 In and PW Mod 2 In the pulse width by a PW Mod Amt of their own. Pitch In has no depth: the note it carries is added
      # whole, a key a semitone, and plays in tune from the first sample.
      # Each Mod Amt, its Mod Pol and, for the pitch, its Pitch Mod Sw are multiplied before
      # smoothing, so only their product, the depth, carries a smoothing state.
      @pitch_modulation_1_polarity = 1.0
      @pitch_modulation_2_polarity = 1.0
      @pw_modulation_1_polarity = 1.0
      @pw_modulation_2_polarity = 1.0
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
      @pw_modulation_1_depth = 0.0
      @stage_1_pw_modulation_1_depth = 0.0
      @current_pw_modulation_1_depth = 0.0
      @pw_modulation_2_amount = 0.0
      @pw_modulation_2_depth = 0.0
      @stage_1_pw_modulation_2_depth = 0.0
      @current_pw_modulation_2_depth = 0.0
      @pitch_coarse = 0.0
      @pitch_fine = 0.0
      # Pitch Coarse and Pitch Fine are summed when set, so the per-sample path adds one
      # offset rather than two.
      @tune = 0.0
      @output_saw = 0.0
      @output_pulse = 0.0
      # Sync In of the last sample: a restart is taken where it rises from there through zero.
      @sync_last = 0.0
      @sync_switch = 0.0
      # process_synced puts out each sample one sample late, so that the step a restart makes can be
      # rounded off on the sample before it too: these are that sample's two sawtooths, waiting to
      # go out.
      @held_saw1 = 0.0
      @held_saw2 = 0.0
    end

    # Sync Sw: Sync In is taken at 0.5 and above, and ignored below.
    def set_sync_switch(switch)
      @sync_switch = (switch >= 0.5) ? 1.0 : 0.0
    end

    # Waveform morph is unipolar, [0.0, 1.0].
    # 0.0 = sawtooth, 0.5 = 50% morph, 1.0 = pulse (square at PW 0.0).
    def set_waveform(waveform)
      @waveform = (waveform < 0.0) ? 0.0 : ((waveform > 1.0) ? 1.0 : waveform)
    end

    # Pulse width is bipolar, [-0.5, 0.5]: how far the second sawtooth is shifted back from half a
    # cycle. At the pulse end of the morph, 0.0 is a pulse of 50%, +0.25 one of 75% and +0.5 one of
    # 100%, -0.25 one of 25% and -0.5 one of 0%; both ends are silence, as the two sawtooths then
    # cancel. Between the two ends of the morph it moves the second sawtooth of the blend in the
    # same way.
    def set_pulse_width(pulse_width)
      @pulse_width = (pulse_width < -0.5) ? -0.5 : ((pulse_width > 0.5) ? 0.5 : pulse_width)
    end

    # Every Mod Amt is unipolar, [0.0, 1.0], a plain multiplier on its input, and its Mod Pol,
    # bipolar, [-0.5, 0.5], doubled into a multiplier from -1.0 to +1.0, sets the sign and what the
    # top of the Mod Amt is worth: at +1.0 the modulation runs the way its source does, at -1.0
    # the other way up, and at 0.0 not at all. The depths are scaled here rather than per sample,
    # so the smoothed values are already in pitch units. A unit of input times a PW Mod Amt is the
    # whole pulse width range, so at full depth a bipolar source swings it half the range either
    # way, and a unipolar one across all of it.
    def set_pitch_modulation_1_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_1_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_1_polarity * @pitch_modulation_1_on
    end

    def set_pitch_modulation_2_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pitch_modulation_2_amount = clamped_amount * MODULATION_RANGE
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_2_polarity * @pitch_modulation_2_on
    end

    # Pitch Mod 1 Sw and Pitch Mod 2 Sw are unipolar, [0.0, 1.0], and each lets its input
    # move the pitch from 0.5 (CC 64) up. Off, the depth goes to 0.0, smoothed as a depth is, and the
    # Pitch Mod Amt is kept for when it is on again. The pulse width's modulation is not switched.
    def set_pitch_modulation_1_switch(switch)
      @pitch_modulation_1_on = (switch >= 0.5) ? 1.0 : 0.0
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_1_polarity * @pitch_modulation_1_on
    end

    def set_pitch_modulation_2_switch(switch)
      @pitch_modulation_2_on = (switch >= 0.5) ? 1.0 : 0.0
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_2_polarity * @pitch_modulation_2_on
    end

    def set_pitch_modulation_1_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pitch_modulation_1_polarity = clamped + clamped
      @pitch_modulation_1_depth = @pitch_modulation_1_amount * @pitch_modulation_1_polarity * @pitch_modulation_1_on
    end

    def set_pitch_modulation_2_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pitch_modulation_2_polarity = clamped + clamped
      @pitch_modulation_2_depth = @pitch_modulation_2_amount * @pitch_modulation_2_polarity * @pitch_modulation_2_on
    end

    def set_pw_modulation_1_amount(amount)
      @pw_modulation_1_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pw_modulation_1_depth = @pw_modulation_1_amount * @pw_modulation_1_polarity
    end

    def set_pw_modulation_2_amount(amount)
      @pw_modulation_2_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @pw_modulation_2_depth = @pw_modulation_2_amount * @pw_modulation_2_polarity
    end

    def set_pw_modulation_1_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pw_modulation_1_polarity = clamped + clamped
      @pw_modulation_1_depth = @pw_modulation_1_amount * @pw_modulation_1_polarity
    end

    def set_pw_modulation_2_polarity(polarity)
      clamped = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @pw_modulation_2_polarity = clamped + clamped
      @pw_modulation_2_depth = @pw_modulation_2_amount * @pw_modulation_2_polarity
    end

    # Pitch Coarse and Pitch Fine are bipolar, [-0.5, 0.5], with 0.0 meaning no offset, so a controller's
    # center detent lands there. Linear about that center, which is what puts every Coarse step on a
    # whole semitone; a curve here would make exact intervals unreachable. Swept by hand,
    # Coarse also serves a sync sweep, a semitone a step.
    # Not smoothed: a semitone step is part of the sound, a Fine step is too small to hear as one,
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

    # The parameters that scale no audio themselves -- rates, depths, times -- smoothed in two
    # stages once every 16 samples, four control ticks, by the main loop for every module whatever
    # runs, so that they cost a quarter as much and the same for any patch. What multiplies the
    # audio is smoothed at every control tick, where a coarser step would be heard.
    def smooth_parameters
      @stage_1_pulse_width = Dsp.smooth(@pulse_width, @stage_1_pulse_width, @smoothing_16_blend)
      @current_pulse_width = Dsp.smooth(@stage_1_pulse_width, @current_pulse_width, @smoothing_16_blend)
      @stage_1_pitch_modulation_1_depth = Dsp.smooth(@pitch_modulation_1_depth, @stage_1_pitch_modulation_1_depth, @smoothing_16_blend)
      @current_pitch_modulation_1_depth = Dsp.smooth(@stage_1_pitch_modulation_1_depth, @current_pitch_modulation_1_depth, @smoothing_16_blend)
      @stage_1_pitch_modulation_2_depth = Dsp.smooth(@pitch_modulation_2_depth, @stage_1_pitch_modulation_2_depth, @smoothing_16_blend)
      @current_pitch_modulation_2_depth = Dsp.smooth(@stage_1_pitch_modulation_2_depth, @current_pitch_modulation_2_depth, @smoothing_16_blend)
      @stage_1_pw_modulation_1_depth = Dsp.smooth(@pw_modulation_1_depth, @stage_1_pw_modulation_1_depth, @smoothing_16_blend)
      @current_pw_modulation_1_depth = Dsp.smooth(@stage_1_pw_modulation_1_depth, @current_pw_modulation_1_depth, @smoothing_16_blend)
      @stage_1_pw_modulation_2_depth = Dsp.smooth(@pw_modulation_2_depth, @stage_1_pw_modulation_2_depth, @smoothing_16_blend)
      @current_pw_modulation_2_depth = Dsp.smooth(@stage_1_pw_modulation_2_depth, @current_pw_modulation_2_depth, @smoothing_16_blend)
    end

    # The inputs are taken as they arrive; what is held to a range is the pitch they add up to.
    # [-0.5, 0.5] is that range, covering MIDI notes 0 to 120, and it is what keeps the table
    # lookup in bounds. The pulse width its modulations add up to is held to its own, [-0.5, 0.5].
    # The modulation inputs are deliberately not smoothed, so a fast source reaches the pitch and
    # the pulse width unslewed.
    def process(control_tick, pitch_input = 0.0, pitch_modulation_1_input = 0.0, pitch_modulation_2_input = 0.0,
                pw_modulation_1_input = 0.0, pw_modulation_2_input = 0.0)
      update_controls if control_tick

      pitch_modulation = (pitch_modulation_1_input * @current_pitch_modulation_1_depth) + (pitch_modulation_2_input * @current_pitch_modulation_2_depth)
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
      pw_modulation = (pw_modulation_1_input * @current_pw_modulation_1_depth) + (pw_modulation_2_input * @current_pw_modulation_2_depth)
      total_pulse_width = @current_pulse_width + pw_modulation
      pulse_width = (total_pulse_width < -0.5) ? -0.5 : ((total_pulse_width > 0.5) ? 0.5 : total_pulse_width)
      phase2 = @phase + (0.5 - pulse_width)
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
    # does: another oscillator's sawtooth, at its wrap, or a gate, at a note on. The phase starts
    # this sample as far past 0.0 as the time since the crossing takes it, so the synced wave
    # repeats with the period of what it is synced to, where a restart rounded to a sample would
    # make the period jitter by a sample. Where between the two samples it crossed is found as the
    # place of a step rounded off by PolyBLEP, from one level to the same level the other side of
    # zero, would be: that is what an oscillator's sawtooth is at its wrap, and a line drawn
    # between the two samples would miss it by up to a twelfth of a sample, which takes back most
    # of what the rounding off below gains. A gate, a step between two samples, comes out at the
    # last sample, as a line would put it. Sync In is taken only with Sync Sw on. The sub is left
    # out: only an oscillator run by process, Osc 1 in the patch, has Out Sub.
    #
    # Every step the two sawtooths make, at a wrap or at a restart, is rounded off by PolyBLEP, on
    # the sample after it and the one before it. Nothing tells the one before that a restart is
    # coming, so every sample goes out one sample late, held until the next has been worked out,
    # and the wraps are rounded off the same way rather than seen coming as process does: a wrap a
    # restart cuts off is then never rounded off, and one just after a restart is. Left as it was,
    # a restart's step folds back as much as a sawtooth taken with no correction does, some 30 dB
    # more than the rest of the oscillator. Without a restart the output is process's, one sample
    # late, but where the pitch jumps: a phase a wrap left behind can be within the new dt of 0.0,
    # which both take for a wrap just past, and this one rounds off on the sample before as well.
    def process_synced(control_tick, pitch_input = 0.0, pitch_modulation_1_input = 0.0, pitch_modulation_2_input = 0.0,
                       pw_modulation_1_input = 0.0, pw_modulation_2_input = 0.0, sync_input = 0.0)
      update_controls if control_tick

      pitch_modulation = (pitch_modulation_1_input * @current_pitch_modulation_1_depth) + (pitch_modulation_2_input * @current_pitch_modulation_2_depth)
      total_pitch = pitch_input + @tune + pitch_modulation
      pitch = (total_pitch < -0.5) ? -0.5 : ((total_pitch > 0.5) ? 0.5 : total_pitch)
      freq = pitch_to_freq_fast(pitch)
      current_dt = freq * @inv_sample_rate
      current_dt_inv = 1.0 / current_dt

      pw_modulation = (pw_modulation_1_input * @current_pw_modulation_1_depth) + (pw_modulation_2_input * @current_pw_modulation_2_depth)
      total_pulse_width = @current_pulse_width + pw_modulation
      pulse_width = (total_pulse_width < -0.5) ? -0.5 : ((total_pulse_width > 0.5) ? 0.5 : total_pulse_width)
      shift = 0.5 - pulse_width

      # The crossing, a fraction f past the last sample, since = 1 - f before this one. A step of
      # height h rounded off by PolyBLEP there leaves the last sample at -h/2 + h(1 - f)^2/2 and
      # this one at h/2 - hf^2/2: their sum over their difference, r, is
      # (1/2 - f) / (1/2 + f - f^2), whatever h is. f, the root of that in [0, 1], is
      # (1 - r) / (1 + r + sqrt(1 + 3r^2)), which is 1/2 less an odd function of r: that function
      # is taken as a polynomial of the 7th degree, fitted by least squares over [-1, 1], within a
      # thousandth of a sample, so that no square root and no second division is needed, and since
      # is 1/2 plus it. r is within [-1, 1] wherever the last sample is at or below zero and this
      # one above it, the sum being no larger than the rise there; elsewhere the rise is taken as
      # at least the sum, which holds r there too, and above zero, so that the division is finite.
      # A rise is never smaller than that floor but by a step of a millionth. Held so, rather than
      # by clamping r, the compiler finds no end of the clamp to jump past.
      from_below = (@sync_last > 0.0) ? 0.0 : 1.0
      restart = ((sync_input > 0.0) ? from_below : 0.0) * @sync_switch
      sum = sync_input + @sync_last
      reach = sum.abs
      rise = sync_input - @sync_last
      rise = (rise > reach) ? rise : reach
      rise = (rise > 0.000001) ? rise : 0.000001
      ratio = sum / rise
      ratio_2 = ratio * ratio
      since = 0.5 + ratio * (0.74532 + ratio_2 * (-0.477774 + ratio_2 * (0.361841 + ratio_2 * -0.130411)))
      @sync_last = sync_input

      # Each step is placed by how long before this sample it was, in samples: since for the
      # restart at the crossing, and a wrap where the phase, wrapped, is less than dt. A wrap that
      # would have come after the crossing is one the restart cut off. Each step counts only where
      # it is made, so the steps are worked out whatever happens and multiplied by whether it did.
      travel = since * current_dt
      phase2_on = @phase + shift
      phase2_on -= (phase2_on < 1.0) ? 0.0 : 1.0
      wrap1_since = @phase * current_dt_inv
      wrap1 = ((wrap1_since < 1.0) ? 1.0 : 0.0) * (1.0 - ((wrap1_since > since) ? 0.0 : 1.0) * restart)
      wrap2_since = phase2_on * current_dt_inv
      wrap2 = ((wrap2_since < 1.0) ? 1.0 : 0.0) * (1.0 - ((wrap2_since > since) ? 0.0 : 1.0) * restart)
      # The phases the restart cut off, at the crossing, give the steps it makes: each sawtooth
      # jumps up to where it starts, by twice the phase it had reached.
      cut_phase = @phase - travel
      cut_phase += (cut_phase < 0.0) ? 1.0 : 0.0
      cut_phase2 = cut_phase + shift
      cut_phase2 -= (cut_phase2 < 1.0) ? 0.0 : 1.0
      step1 = restart * (cut_phase + cut_phase)
      step2 = restart * ((cut_phase2 - shift) + (cut_phase2 - shift))

      @phase += restart * (travel - @phase)
      # After a restart the second sawtooth starts at the shift, and wraps again within this sample
      # where the shift is within travel of 1.0.
      phase2 = @phase + shift
      wraps = (phase2 < 1.0) ? 0.0 : 1.0
      phase2 -= wraps
      wraps_after = wraps * restart
      wrap3_since = phase2 * current_dt_inv

      # PolyBLEP of a step of h, a time s past it: -h(1 - s)^2 / 2 on this sample, and hs^2 / 2 on
      # the one before. A wrap is a step of two.
      after_w1 = 1.0 - wrap1_since
      after_w2 = 1.0 - wrap2_since
      after_w3 = 1.0 - wrap3_since
      after_r = 1.0 - since
      step1 *= 0.5
      step2 *= 0.5
      saw1 = -2.0 * @phase + 1.0 - wrap1 * (after_w1 * after_w1) - step1 * (after_r * after_r)
      saw2 = -2.0 * phase2 + 1.0 - wrap2 * (after_w2 * after_w2) - wraps_after * (after_w3 * after_w3) - step2 * (after_r * after_r)
      since_2 = since * since
      before1 = wrap1 * (wrap1_since * wrap1_since) + step1 * since_2
      before2 = wrap2 * (wrap2_since * wrap2_since) + wraps_after * (wrap3_since * wrap3_since) + step2 * since_2

      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0

      # The sample before goes out now, with its share of this sample's steps, and this one is
      # held. The halving brings the outputs to one unit peak to peak, as process's. Wave, smoothed,
      # is taken as it is now: it moves too slowly for a sample to tell.
      held_saw1 = @held_saw1 + before1
      held_saw2 = @held_saw2 + before2
      @output_saw = held_saw1 * 0.5
      @output_pulse = (held_saw1 - held_saw2) * 0.5
      output = (held_saw1 - held_saw2 * @current_waveform) * 0.5
      @held_saw1 = saw1
      @held_saw2 = saw2
      output
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
      # The morph, which crossfades the audio, is smoothed at the control rate (see smooth_parameters).
      @stage_1_waveform = Dsp.smooth(@waveform, @stage_1_waveform, @smoothing_target_blend)
      @current_waveform = Dsp.smooth(@stage_1_waveform, @current_waveform, @smoothing_target_blend)
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
