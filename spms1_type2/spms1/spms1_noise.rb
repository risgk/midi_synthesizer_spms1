module Spms1
  # White noise source, at a smoothed level. The default patch feeds it to Filter 1 Audio 3 In.
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

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # Powers up silent, so that the noise fades in from nothing when Level is first turned up.
      @level = 0.0
      @stage_1_level = 0.0
      @current_level = 0.0
      # The generator's state: a 32-bit linear congruential generator, always in [0, 2^32). Seeded
      # with a fixed value, so that a render is the same every time.
      @state = 1
      @sample_counter = 0
    end

    # Level is unipolar, [0.0, 1.0], and used as a plain multiplier, so 1.0 puts out noise filling
    # -1.0 to +1.0, the oscillator's range.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    def process
      if @sample_counter == 0
        @stage_1_level = Dsp.smooth(@level, @stage_1_level, @smoothing_target_blend)
        @current_level = Dsp.smooth(@stage_1_level, @current_level, @smoothing_target_blend)
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # Numerical Recipes' constants. The product stays under 2^53, so it is exact in 64 bits and
      # needs no wrap of its own; the mask keeps the state in 32. The low bits of an LCG repeat
      # with short periods, so only the top 24 are used: 0 to 2^24 - 1, scaled to [-1.0, 1.0).
      # The literals are written out rather than named, as a named Integer constant is a runtime
      # global to Spinel.
      @state = (@state * 1664525 + 1013904223) & 0xffffffff
      white = (@state >> 8).to_f * (1.0 / 8388608.0) - 1.0

      white * @current_level
    end
  end
end
