module Spms1
  # Noise source, at a smoothed level: audio, or a modulation source. Two outputs: white, flat
  # across the spectrum, and red, the white through a one-pole low pass at Red Cutoff, falling 6 dB
  # an octave above it. The default patch feeds the white to Mixer 2 In 3, and runs the module
  # ahead of the LFO and the envelope.
  class Noise
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
    # can never need.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one.
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    # Red Cutoff 0.0 to 1.0 spans 10 octaves, an octave every 0.1, on MIDI note numbers as Filter 1
    # Cutoff does: note -39 (0.86 Hz) at 0.0, a slow random wander as a modulation source, note 21
    # (A0, 27.5 Hz) at 0.5, where the red falls 6 dB an octave across the audible band, and note 81
    # (A5, 880 Hz) at 1.0. The table holds a point for each note, as PRA32-U2's LFO Red Noise
    # does a coefficient and a gain for each step of its rate.

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # Powers up silent, so that the noise fades in from nothing when Level is first turned up.
      @level = 0.0
      @stage_1_level = 0.0
      @current_level = 0.0
      # The low pass is red += (white - red) * coef, with coef = 1 - e^(-2 pi fc / fs). It scales
      # the white's power by coef / (2 - coef), so the gain puts it back to half the white's, the
      # RMS 1/sqrt(2) of it, as PRA32-U2 does: the red then stays within -0.5 to +0.5 but for its
      # rarest swings, which the clamp in process holds there.
      @red_coef_table = Array.new(122, 0.0)
      @red_gain_table = Array.new(122, 0.0)
      for i in 0...121
        cutoff_hz = 440.0 * (2.0 ** ((i.to_f - 108.0) * (1.0 / 12.0)))
        coef = 1.0 - Math.exp(-2.0 * Math::PI * cutoff_hz / @sample_rate)
        @red_coef_table[i] = coef
        @red_gain_table[i] = Math.sqrt((2.0 - coef) / (2.0 * coef))
      end
      @red_coef_table[121] = @red_coef_table[120]
      @red_gain_table[121] = @red_gain_table[120]
      @red_cutoff = 0.0
      @stage_1_red_cutoff = 0.0
      @current_red_cutoff = 0.0
      @red_coef = @red_coef_table[0]
      @red_gain = @red_gain_table[0]
      @red = 0.0
      @output_red = 0.0
      # The generator's state: a 32-bit linear congruential generator, always in [0, 2^32). Seeded
      # with a fixed value, so that a render is the same every time.
      @state = 1
      @sample_counter = 0
    end

    # Level is unipolar, [0.0, 1.0], and used as a plain multiplier, so 1.0 puts out noise filling
    # -0.5 to +0.5, the oscillator's range, as every audio source in the synth is.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    # Red Cutoff is unipolar, [0.0, 1.0]: see the table in initialize.
    def set_red_cutoff(red_cutoff)
      @red_cutoff = (red_cutoff < 0.0) ? 0.0 : ((red_cutoff > 1.0) ? 1.0 : red_cutoff)
    end

    def process
      if @sample_counter == 0
        @stage_1_level = Dsp.smooth(@level, @stage_1_level, @smoothing_target_blend)
        @current_level = Dsp.smooth(@stage_1_level, @current_level, @smoothing_target_blend)
        @stage_1_red_cutoff = Dsp.smooth(@red_cutoff, @stage_1_red_cutoff, @smoothing_target_blend)
        @current_red_cutoff = Dsp.smooth(@stage_1_red_cutoff, @current_red_cutoff, @smoothing_target_blend)
        # Looked up at every update, the cutoff moving or not, so that the load does not change
        # with it.
        position = @current_red_cutoff * 120.0
        index = position.to_i
        fraction = position - index.to_f
        c0 = @red_coef_table[index]
        g0 = @red_gain_table[index]
        @red_coef = c0 + fraction * (@red_coef_table[index + 1] - c0)
        @red_gain = g0 + fraction * (@red_gain_table[index + 1] - g0)
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # Numerical Recipes' constants. The product stays under 2^53, so it is exact in 64 bits and
      # needs no wrap of its own; the mask keeps the state in 32. The low bits of an LCG repeat
      # with short periods, so only the top 24 are used: 0 to 2^24 - 1, scaled to [-0.5, 0.5).
      # The literals are written out rather than named, as a named Integer constant is a runtime
      # global to Spinel.
      @state = (@state * 1664525 + 1013904223) & 0xffffffff
      white = (@state >> 8).to_f * (1.0 / 16777216.0) - 0.5

      # Driven by the noise every sample, the state never settles toward zero, so it needs no
      # flush_tiny.
      @red += (white - @red) * @red_coef
      red = @red * @red_gain
      red = (red < -0.5) ? -0.5 : ((red > 0.5) ? 0.5 : red)
      @output_red = red * @current_level

      white * @current_level
    end

    # The red output of the last process.
    def output_red
      @output_red
    end
  end
end
