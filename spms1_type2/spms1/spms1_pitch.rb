module Spms1
  # The note's pitch on its way to the oscillators and the filter. Portamento is a slew limiter of
  # the exponential kind, a lag: the output follows the input along a one-pole
  # curve, as a voltage across an RC network does. Fed with Note Pitch, it is portamento, and the
  # pitch domain being linear in semitones makes the glide an exponential one in pitch, which is
  # what an analog synth's portamento is. It takes any signal, though, so it rounds off the steps of
  # a stepped one as well. Bend In is added to the output past the lag, for what should move the
  # pitch at once rather than glide, as a pitch bend should. Stretch then widens the sum about note
  # 60, so that the keys, the glide and the bend spread out alike.
  #
  # The glide moves only while Gate In is on, from 0.25 up, as an envelope's gate is: with the gate
  # off, it holds where it is, and the next note goes on from there.
  #
  # There are two outputs, Out 1 and Out 2, each with a lag of its own, at the one time, and the
  # one bend: each has a glide switch and a bend switch of its own, so the glide or the bend can
  # reach one oscillator only.
  class Pitch
    # Lookup table for exponential time mapping, the envelope's: a twelfth of an octave per index,
    # so one CC step of the 120-step control range moves the time by a semitone and the whole dial
    # spans ten octaves.
    EXP_TABLE = Array.new(122, 0.0)
    for i in 0...121
      EXP_TABLE[i] = 2.0 ** ((i.to_f - 60.0) * (1.0 / 12.0))
    end
    EXP_TABLE[121] = EXP_TABLE[120]

    # Time range: 10 ms at 0.0 (next to it, since 0.0 itself is no slew at all), 320 ms at 0.5,
    # 10.24 s at 1.0 -- EG 1 Decay's range. As the decay is, it is measured to 1/1024 of the way
    # left, where a glide of an octave is within a hundredth of a semitone of its note; nine tenths
    # of the way is covered in a third of the time. The constant is the time constant at 0.0 over
    # the table's lowest entry: value at 0.0 / (EXP_TABLE min * 10 * ln(2)).
    TIME_BASE = 0.010 / ((1.0 / 32.0) * 10 * Math::log(2))

    # Bend Amt is smoothed as every other module's depths are: two stages at this blend,
    # updated every CONTROL_RATE_DIVISOR samples. See Amp for both.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    CONTROL_RATE_DIVISOR = 4

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @time = 0.0
      # The share of the distance left that is covered each sample, Glide's, and each output's
      # with the gate on and off. 1.0 is no slew at all. With the gate off, the share is 0.0,
      # holding the glide, unless the slew is off; with its glide switch off, an output's is 1.0.
      @blend = 1.0
      @gate_off_blend = 1.0
      @blend_1 = 1.0
      @gate_off_blend_1 = 1.0
      @blend_2 = 1.0
      @gate_off_blend_2 = 1.0
      # Whether each output takes the glide and the bend: 1.0 on, 0.0 off.
      @glide_1_on = 1.0
      @glide_2_on = 1.0
      @bend_1_on = 1.0
      @bend_2_on = 1.0
      @output_2 = 0.0
      # Each output's state is the distance from it to the input, not the output itself; see
      # process.
      @distance_1 = 0.0
      @distance_2 = 0.0
      @last_input = 0.0
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # The blend of the parameters smoothed once every 16 samples, four control ticks (see
      # smooth_parameters): the one above taken four times over, for the same time.
      @smoothing_16_blend = 1.0 - (1.0 - @smoothing_target_blend) ** 4.0
      @bend_amount = 0.0
      @bend_polarity = 1.0
      @bend_depth = 0.0
      @stage_1_bend_depth = 0.0
      @current_bend_depth = 0.0
      @stretch = 0.0
      @stretch_factor = 1.0
      # The smoothing starts where Stretch 0.0 puts it, a factor of 1.0, as every module's starts
      # where its parameters at 0.0 put it.
      @stage_1_stretch_factor = 1.0
      @current_stretch_factor = 1.0
    end

    # Glide, the portamento time, is unipolar, [0.0, 1.0]; see TIME_BASE for scaling details. 0.0 turns the portamento off.
    # Not smoothed: a new time changes only how fast the output moves from where it is, so a step
    # in it cannot step the output. Converted here rather than in process, as this is called once
    # per buffer, and with nothing to smooth there is no control-rate update to put it in.
    # The share is 1/(time constant in samples), the first-order form of the exact
    # 1 - exp(-1/(time constant in samples)); at the shortest time, 69 samples, it runs 0.7% fast.
    def set_glide(time)
      @time = Dsp.clamp(time, 0.0, 1.0)
      blend = 1.0 / (TIME_BASE * calculate_exp_fast(@time) * @sample_rate)
      @blend = (@time > 0.0) ? blend : 1.0
      @gate_off_blend = (@time > 0.0) ? 0.0 : 1.0
      update_blends
    end

    # Out 1 Glide Sw and Out 2 Glide Sw are unipolar, [0.0, 1.0], and each turns the
    # portamento on for its output from 0.5 (CC 64) up, as a MIDI switch is on from 64. Off, the
    # output's lag runs at no slew, so the output follows the input at once, as at Glide 0.0,
    # mid-glide too, and switched on again it glides from where it is to the next note, with no
    # step.
    def set_glide_1_switch(switch)
      @glide_1_on = (switch >= 0.5) ? 1.0 : 0.0
      update_blends
    end

    def set_glide_2_switch(switch)
      @glide_2_on = (switch >= 0.5) ? 1.0 : 0.0
      update_blends
    end

    # Out 1 Bend Sw and Out 2 Bend Sw are unipolar, [0.0, 1.0], and each adds Bend In to
    # its output from 0.5 (CC 64) up. Off, the output is not bent, and the bend steps out at once.
    def set_bend_1_switch(switch)
      @bend_1_on = (switch >= 0.5) ? 1.0 : 0.0
    end

    def set_bend_2_switch(switch)
      @bend_2_on = (switch >= 0.5) ? 1.0 : 0.0
    end

    # Bend Amt is unipolar, [0.0, 1.0], the depth of Bend In: at 1.0 Bend In is added as it
    # arrives. Pitch Bend is one unit across the wheel, the pitch range's whole width, so the bend
    # range is the amount times 60 semitones either way: half a semitone a step of the 7-bit value,
    # 2 semitones at 8 and an octave at 28. Bend Pol multiplies it, as a filter's Mod Pol does its
    # Mod Amt: bipolar, [-0.5, 0.5], doubled, so at +0.5 the bend runs as the wheel does, at -0.5
    # the other way, and at 0.0 not at all. Only their product, the depth, is smoothed.
    def set_bend_amount(amount)
      @bend_amount = Dsp.clamp(amount, 0.0, 1.0)
      @bend_depth = @bend_amount * @bend_polarity
    end

    def set_bend_polarity(polarity)
      clamped = Dsp.clamp(polarity, -0.5, 0.5)
      @bend_polarity = clamped + clamped
      @bend_depth = @bend_amount * @bend_polarity
    end

    # Stretch is unipolar, [0.0, 1.0], and multiplies the pitch, glided and bent, whose 0.0 is note
    # 60, by 1 plus a stretch that grows a semitone's ratio each step of the 7-bit value from the
    # second, as Glide's time does: 0.0 (4) leaves the pitch as it is, 5 widens an octave by 1.2
    # cents, 64 by 38 and 124 by a whole octave, which doubles every interval. So a piano's few cents an octave and a
    # keyboard spread to whole tones are both on the one dial. The factor is smoothed, as a depth
    # is, so that turning it glides the pitch rather than stepping it.
    def set_stretch(stretch)
      @stretch = Dsp.clamp(stretch, 0.0, 1.0)
      # calculate_exp_fast spans 1/32 to 32 over the dial, so the stretch reaches 1.0 at its top.
      stretch_factor = 1.0 + calculate_exp_fast(@stretch) * (1.0 / 32.0)
      @stretch_factor = (@stretch > 0.0) ? stretch_factor : 1.0
    end

    # The parameters that scale no audio themselves -- rates, depths, times -- smoothed in two
    # stages once every 16 samples, four control ticks, by the main loop for every module whatever
    # runs, so that they cost a quarter as much and the same for any patch. What multiplies the
    # audio is smoothed at every control tick, where a coarser step would be heard.
    def smooth_parameters
      @stage_1_bend_depth = Dsp.smooth(@bend_depth, @stage_1_bend_depth, @smoothing_16_blend)
      @current_bend_depth = Dsp.smooth(@stage_1_bend_depth, @current_bend_depth, @smoothing_16_blend)
      @stage_1_stretch_factor = Dsp.smooth(@stretch_factor, @stage_1_stretch_factor, @smoothing_16_blend)
      @current_stretch_factor = Dsp.smooth(@stage_1_stretch_factor, @current_stretch_factor, @smoothing_16_blend)
    end

    # The distance left is what is carried from sample to sample, and the output is the input plus
    # it. Carrying the output instead, as a one-pole filter usually does, rounds every step to the
    # spacing of floats at the output, and at the longest time a step of an octave's glide is only
    # some 190 of those: the glide runs up to 0.3% off its time, and stops for good once a step
    # rounds to nothing, 3 cents short of the note. The distance shrinks by its own share instead,
    # at a precision of its own, and goes all the way. It also leaves the output exactly the input,
    # bit for bit, with the slew off, so a patch through it sounds as one without it. The distance
    # is moved by d - d * blend rather than d * (1 - blend), which as a float rounds a blend of
    # 1/70000 to within 0.2% and the time with it.
    #
    # It goes through Dsp.flush_tiny's dead zone first, as the filter's states do: shrinking by a
    # share each sample, it would otherwise sink into denormals and stick at the smallest one,
    # which x86 computes slowly.
    #
    # Gate In picks each output's share each sample: Glide's while it is on, and while it is off
    # 0.0, which leaves the distance as it is, or 1.0 at Glide 0.0 or with the output's glide
    # switch off, so that no slew stays no slew whatever the gate does.
    #
    # Bend In is added past the lag, so that the lag never holds it, and so that at zero it leaves
    # the output as it was, bit for bit. Stretch multiplies the sum last, so a bend is widened with
    # the keys; at a factor of 1.0 the product is the sum, bit for bit. Each output takes the bend
    # through its switch, and on, the product by 1.0 leaves it as it is, bit for bit.
    #
    # The outputs are held to -1.0 to +1.0, as a mixer's is: twice the pitch range, so whatever
    # the oscillator and the filter clamp to their own range is still reached at either end.
    # Out 1 is returned, and Out 2 is read with output_2.
    def process(control_tick, input = 0.0, gate_input = 0.0, bend_input = 0.0)

      step = @last_input - input
      @last_input = input
      gate_on = gate_input >= 0.25
      flushed_1 = Dsp.flush_tiny(@distance_1 + step)
      blend_1 = gate_on ? @blend_1 : @gate_off_blend_1
      @distance_1 = flushed_1 - flushed_1 * blend_1
      flushed_2 = Dsp.flush_tiny(@distance_2 + step)
      blend_2 = gate_on ? @blend_2 : @gate_off_blend_2
      @distance_2 = flushed_2 - flushed_2 * blend_2
      bend = bend_input * @current_bend_depth
      output_2 = ((input + @distance_2) + (bend * @bend_2_on)) * @current_stretch_factor
      @output_2 = Dsp.clamp(output_2, -1.0, 1.0)
      output = ((input + @distance_1) + (bend * @bend_1_on)) * @current_stretch_factor
      Dsp.clamp(output, -1.0, 1.0)
    end

    def output_2
      @output_2
    end

    private

    # Each output's shares, Glide's through its glide switch.
    def update_blends
      @blend_1 = (@glide_1_on > 0.0) ? @blend : 1.0
      @gate_off_blend_1 = (@glide_1_on > 0.0) ? @gate_off_blend : 1.0
      @blend_2 = (@glide_2_on > 0.0) ? @blend : 1.0
      @gate_off_blend_2 = (@glide_2_on > 0.0) ? @gate_off_blend : 1.0
    end

    def calculate_exp_fast(value)
      v_scale = value * 120.0
      index = v_scale.to_i
      fraction = v_scale - index.to_f

      e0 = EXP_TABLE[index]
      e1 = EXP_TABLE[index + 1]

      e0 + fraction * (e1 - e0)
    end
  end
end
