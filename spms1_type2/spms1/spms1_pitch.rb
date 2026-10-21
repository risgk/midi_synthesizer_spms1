module Spms1
  # The note's pitch on its way to the oscillators and the filter. Portamento is a slew limiter of
  # the exponential kind, a lag: the output follows the input along a one-pole
  # curve, as a voltage across an RC network does. Fed with Note Pitch, it is portamento, and the
  # pitch domain being linear in semitones makes the glide an exponential one in pitch, which is
  # what an analog synth's portamento is. It takes any signal, though, so it rounds off the steps of
  # a stepped one as well. Bend In is added to the output past the lag, for what should move the
  # pitch at once rather than glide, as a pitch bend should. Stretch then widens the sum about note
  # 60, as PRA32-U2's Stretch Tune does, so that the keys, the glide and the bend spread out alike.
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
      # The share Glide sets, and whether Glide Switch lets it through: 1.0 on, 0.0 off.
      @glide_blend = 1.0
      @glide_on = 1.0
      # The share of the distance left that is covered each sample. 1.0 is no slew at all.
      @blend = 1.0
      # The state is the distance from the output to the input, not the output itself; see process.
      @distance = 0.0
      @last_input = 0.0
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @bend_depth = 0.0
      @stage_1_bend_depth = 0.0
      @current_bend_depth = 0.0
      @stretch = 0.0
      @stretch_factor = 1.0
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
      @time = (time < 0.0) ? 0.0 : ((time > 1.0) ? 1.0 : time)
      blend = 1.0 / (TIME_BASE * calculate_exp_fast(@time) * @sample_rate)
      @glide_blend = (@time > 0.0) ? blend : 1.0
      @blend = (@glide_on > 0.0) ? @glide_blend : 1.0
    end

    # Glide Switch is unipolar, [0.0, 1.0], and turns the portamento on from 0.5 (CC 64) up, as a
    # MIDI switch is on from 64. Off, the output follows the input at once, as at Glide 0.0, mid-glide
    # too, and Glide keeps its time for when it is on again.
    def set_glide_switch(switch)
      @glide_on = (switch >= 0.5) ? 1.0 : 0.0
      @blend = (@glide_on > 0.0) ? @glide_blend : 1.0
    end

    # Bend Amt is unipolar, [0.0, 1.0], the depth of Bend In: at 1.0 Bend In is added as it
    # arrives. Pitch Bend is one unit across the wheel, the pitch range's whole width, so the bend
    # range is the amount times 60 semitones either way: half a semitone a step of the 7-bit value,
    # 2 semitones at 8 and an octave at 28.
    def set_bend_amount(amount)
      @bend_depth = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # Stretch is unipolar, [0.0, 1.0], and multiplies the pitch, glided and bent, whose 0.0 is note
    # 60, by 1 plus a stretch that grows a semitone's ratio each step of the 7-bit value from the
    # second, as Glide's time does: 0.0 (4) leaves the pitch as it is, 5 widens an octave by 1.2
    # cents, 64 by 38 and 124 by a whole octave, which doubles every interval. So a piano's few cents an octave and a
    # keyboard spread to whole tones are both on the one dial. The factor is smoothed, as a depth
    # is, so that turning it glides the pitch rather than stepping it.
    def set_stretch(stretch)
      @stretch = (stretch < 0.0) ? 0.0 : ((stretch > 1.0) ? 1.0 : stretch)
      # calculate_exp_fast spans 1/32 to 32 over the dial, so the stretch reaches 1.0 at its top.
      stretch_factor = 1.0 + calculate_exp_fast(@stretch) * (1.0 / 32.0)
      @stretch_factor = (@stretch > 0.0) ? stretch_factor : 1.0
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
    # Bend In is added past the lag, so that the lag never holds it, and so that at zero it leaves
    # the output as it was, bit for bit. Stretch multiplies the sum last, so a bend is widened with
    # the keys; at a factor of 1.0 the product is the sum, bit for bit.
    #
    # The output is held to -1.0 to +1.0, as a mixer's is: twice the pitch range, so whatever
    # the oscillator and the filter clamp to their own range is still reached at either end.
    def process(control_tick, input = 0.0, bend_input = 0.0)
      if control_tick
        @stage_1_bend_depth = Dsp.smooth(@bend_depth, @stage_1_bend_depth, @smoothing_target_blend)
        @current_bend_depth = Dsp.smooth(@stage_1_bend_depth, @current_bend_depth, @smoothing_target_blend)
        @stage_1_stretch_factor = Dsp.smooth(@stretch_factor, @stage_1_stretch_factor, @smoothing_target_blend)
        @current_stretch_factor = Dsp.smooth(@stage_1_stretch_factor, @current_stretch_factor, @smoothing_target_blend)
      end

      distance = @distance + (@last_input - input)
      @last_input = input
      flushed = Dsp.flush_tiny(distance)
      @distance = flushed - flushed * @blend
      output = ((input + @distance) + (bend_input * @current_bend_depth)) * @current_stretch_factor
      (output < -1.0) ? -1.0 : ((output > 1.0) ? 1.0 : output)
    end

    private

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
