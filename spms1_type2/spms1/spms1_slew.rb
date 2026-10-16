module Spms1
  # Slew limiter of the exponential kind, a lag: the output follows the input along a one-pole
  # curve, as a voltage across an RC network does. Fed with Note Pitch, it is portamento, and the
  # pitch domain being linear in semitones makes the glide an exponential one in pitch, which is
  # what an analog synth's portamento is. It takes any signal, though, so it rounds off the steps of
  # a stepped one as well.
  class Slew
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

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @time = 0.0
      # The share of the distance left that is covered each sample. 1.0 is no slew at all.
      @blend = 1.0
      # The state is the distance from the output to the input, not the output itself; see process.
      @distance = 0.0
      @last_input = 0.0
    end

    # Time is unipolar, [0.0, 1.0]; see TIME_BASE for scaling details. 0.0 turns the slew off.
    # Not smoothed: a new time changes only how fast the output moves from where it is, so a step
    # in it cannot step the output. Converted here rather than in process, as this is called once
    # per buffer, and with nothing to smooth there is no control-rate update to put it in.
    # The share is 1/(time constant in samples), the first-order form of the exact
    # 1 - exp(-1/(time constant in samples)); at the shortest time, 69 samples, it runs 0.7% fast.
    def set_time(time)
      @time = (time < 0.0) ? 0.0 : ((time > 1.0) ? 1.0 : time)
      blend = 1.0 / (TIME_BASE * calculate_exp_fast(@time) * @sample_rate)
      @blend = (@time > 0.0) ? blend : 1.0
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
    def process(input = 0.0)
      distance = @distance + (@last_input - input)
      @last_input = input
      flushed = Dsp.flush_tiny(distance)
      @distance = flushed - flushed * @blend
      input + @distance
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
