module Spms1
  # Noise source, at a smoothed level: audio, or a modulation source. Two noises from one
  # generator: white, flat across the spectrum, and red, filtered from it through a one-pole low
  # pass at a fixed cutoff, falling 6 dB an octave above it. Each has an output of its own, and
  # Out, which process returns, crossfades from one to the other by Color. The default patch feeds the white to Mixer 2 In 3, and runs the
  # module ahead of the envelope and the LFO.
  class Noise
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

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # Powers up silent, so that the noise fades in from nothing when Level is first turned up.
      @level = 0.0
      @stage_1_level = 0.0
      @current_level = 0.0
      # Powers up at the white.
      @color = 0.0
      @stage_1_color = 0.0
      @current_color = 0.0
      @output_white = 0.0
      # The red's cutoff is fixed, on the A of a MIDI note number, as Filter 1 Cutoff's dial is on
      # note numbers: note 21 (A0, 27.5 Hz), so that it falls 6 dB an octave across the audible
      # band. The low pass is state += (white - state) * coef, with coef = 1 - e^(-2 pi fc / fs).
      # That scales the white's power by coef / (2 - coef), so the gain puts it back to half the
      # white's, the RMS 1/sqrt(2) of it, as PRA32-U2's LFO Red Noise does: it then stays within
      # -0.5 to +0.5 but for its rarest swings, which the clamp in process holds there.
      @red_coef = low_pass_coef(21.0)
      @red_gain = Math.sqrt((2.0 - @red_coef) / (2.0 * @red_coef))
      @red = 0.0
      @output_red = 0.0
      # The generator's state: a 32-bit linear congruential generator, always in [0, 2^32). Seeded
      # with a fixed value, so that a render is the same every time.
      @state = 1
    end

    # Level is unipolar, [0.0, 1.0], and used as a plain multiplier, so 1.0 puts out noise filling
    # -0.5 to +0.5, the oscillator's range, as every audio source in the synth is.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    # Color is unipolar, [0.0, 1.0], and crossfades Out in a straight line, from the white alone at
    # 0.0 to the red alone at 1.0. Each end is as its own output is, so the red end is 3 dB down
    # on the white, at the RMS the red's gain gives it.
    def set_color(color)
      @color = (color < 0.0) ? 0.0 : ((color > 1.0) ? 1.0 : color)
    end

    def process(control_tick)
      if control_tick
        @stage_1_level = Dsp.smooth(@level, @stage_1_level, @smoothing_target_blend)
        @current_level = Dsp.smooth(@stage_1_level, @current_level, @smoothing_target_blend)
        @stage_1_color = Dsp.smooth(@color, @stage_1_color, @smoothing_target_blend)
        @current_color = Dsp.smooth(@stage_1_color, @current_color, @smoothing_target_blend)
      end

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
      @output_white = white * @current_level

      @output_white + (@output_red - @output_white) * @current_color
    end

    # The white output of the last process.
    def output_white
      @output_white
    end

    # The red output of the last process.
    def output_red
      @output_red
    end

    private

    # The coefficient of a one-pole low pass at the frequency of a MIDI note number.
    def low_pass_coef(note)
      cutoff_hz = 440.0 * (2.0 ** ((note - 69.0) * (1.0 / 12.0)))
      1.0 - Math.exp(-2.0 * Math::PI * cutoff_hz / @sample_rate)
    end
  end
end
