module Spms1
  # The note's pitch on its way to the oscillator and the filter. Portamento is a slew limiter of
  # the exponential kind, a lag: the output follows the input along a one-pole
  # curve, as a voltage across an RC network does. Fed with Note Pitch, it is portamento, and the
  # pitch domain being linear in semitones makes the glide an exponential one in pitch, which is
  # what an analog synth's portamento is. It takes any signal, though, so it rounds off the steps of
  # a stepped one as well. Direct In is added to the output past the lag, for what should move the
  # pitch at once rather than glide, as a pitch bend should, and Offset Coarse and Fine shift the
  # output in the same place: a transposition that takes effect at once, ahead of everything the
  # module feeds, so two oscillators on it move together and keep their own Pitch Coarse and Fine as
  # the interval between them.
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

    # Direct Amt and Pol are smoothed as every other module's depths are: two stages at this blend,
    # updated every CONTROL_RATE_DIVISOR samples. See Amp for both.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    CONTROL_RATE_DIVISOR = 4
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    # The offsets' ranges, the oscillator's Pitch Coarse and Fine's: 60 semitones and 60 cents
    # either way, in the pitch domain's units, where 120 semitones are one.
    OFFSET_COARSE_RANGE = 60.0 / 120.0
    OFFSET_FINE_RANGE   = 0.6 / 120.0

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @time = 0.0
      # The share of the distance left that is covered each sample. 1.0 is no slew at all.
      @blend = 1.0
      # The state is the distance from the output to the input, not the output itself; see process.
      @distance = 0.0
      @last_input = 0.0
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @direct_amount = 0.0
      @direct_polarity = 1.0
      @direct_depth = 0.0
      @stage_1_direct_depth = 0.0
      @current_direct_depth = 0.0
      @sample_counter = 0
      @offset_coarse = 0.0
      @offset_fine = 0.0
      @offset = 0.0
    end

    # Portamento Time is unipolar, [0.0, 1.0]; see TIME_BASE for scaling details. 0.0 turns the portamento off.
    # Not smoothed: a new time changes only how fast the output moves from where it is, so a step
    # in it cannot step the output. Converted here rather than in process, as this is called once
    # per buffer, and with nothing to smooth there is no control-rate update to put it in.
    # The share is 1/(time constant in samples), the first-order form of the exact
    # 1 - exp(-1/(time constant in samples)); at the shortest time, 69 samples, it runs 0.7% fast.
    def set_portamento_time(time)
      @time = (time < 0.0) ? 0.0 : ((time > 1.0) ? 1.0 : time)
      blend = 1.0 / (TIME_BASE * calculate_exp_fast(@time) * @sample_rate)
      @blend = (@time > 0.0) ? blend : 1.0
    end

    # The depth of Direct In is amount times polarity, as a modulation depth is. Amount is unipolar,
    # [0.0, 1.0], and at 1.0 Direct In is added as it arrives; polarity is bipolar, [-0.5, 0.5], and
    # doubled, so +0.5 leaves the amount as it is and -0.5 negates it. Pitch Bend is one unit across
    # the wheel, the pitch range's whole width, so the bend range is the amount times 60 semitones
    # either way: half a semitone a CC step, and 2 semitones at CC 8.
    def set_direct_amount(amount)
      @direct_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @direct_depth = @direct_amount * @direct_polarity
    end

    def set_direct_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @direct_polarity = clamped_polarity + clamped_polarity
      @direct_depth = @direct_amount * @direct_polarity
    end

    # Offset Coarse and Offset Fine are bipolar, [-0.5, 0.5], 0.0 at a controller's centre detent,
    # and linear about it, so every step lands on a whole semitone or a whole cent, as the
    # oscillator's Pitch Coarse and Fine do. Not smoothed, for the reasons the oscillator gives.
    def set_offset_coarse(offset_coarse)
      clamped = (offset_coarse < -0.5) ? -0.5 : ((offset_coarse > 0.5) ? 0.5 : offset_coarse)
      @offset_coarse = (clamped + clamped) * OFFSET_COARSE_RANGE
      @offset = @offset_coarse + @offset_fine
    end

    def set_offset_fine(offset_fine)
      clamped = (offset_fine < -0.5) ? -0.5 : ((offset_fine > 0.5) ? 0.5 : offset_fine)
      @offset_fine = (clamped + clamped) * OFFSET_FINE_RANGE
      @offset = @offset_coarse + @offset_fine
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
    # Direct In and the offset are added last, so that the lag never holds them, and so that at
    # zero they leave the output as it was, bit for bit.
    def process(input = 0.0, direct_input = 0.0)
      if @sample_counter == 0
        @stage_1_direct_depth = Dsp.smooth(@direct_depth, @stage_1_direct_depth, @smoothing_target_blend)
        @current_direct_depth = Dsp.smooth(@stage_1_direct_depth, @current_direct_depth, @smoothing_target_blend)
      end
      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      distance = @distance + (@last_input - input)
      @last_input = input
      flushed = Dsp.flush_tiny(distance)
      @distance = flushed - flushed * @blend
      ((input + @distance) + (direct_input * @current_direct_depth)) + @offset
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
