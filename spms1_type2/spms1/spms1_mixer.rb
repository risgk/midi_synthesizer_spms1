module Spms1
  # Sums four inputs, each at its own level, and scales the sum by Out Level. Out, which process
  # returns, is the sum, and Out Inv the sum negated, so with one input routed it is a buffer, an
  # attenuator or an inverter; a negative constant on another input shifts a unipolar signal, such
  # as the envelope, into a bipolar one.
  # Mixer 1 serves the modulation, Mixer 2 the audio ahead of the filter.
  class Mixer
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
      # Every level powers up silent, so an input fades in from nothing when its level is first set
      # rather than sounding at full level before the patch says otherwise.
      @level_1 = 0.0
      @level_2 = 0.0
      @level_3 = 0.0
      @level_4 = 0.0
      @stage_1_1 = 0.0
      @stage_1_2 = 0.0
      @stage_1_3 = 0.0
      @stage_1_4 = 0.0
      @current_1 = 0.0
      @current_2 = 0.0
      @current_3 = 0.0
      @current_4 = 0.0
      # Out Level scales the sum, smoothed as the input levels are.
      @out_level = 0.5
      @stage_1_out_level = 0.0
      @current_out_level = 0.0
      @output = 0.0
    end

    # Each level is unipolar, [0.0, 1.0], and used as a plain multiplier on its own input.
    def set_level_1(level)
      @level_1 = Dsp.clamp(level, 0.0, 1.0)
    end

    def set_level_2(level)
      @level_2 = Dsp.clamp(level, 0.0, 1.0)
    end

    def set_level_3(level)
      @level_3 = Dsp.clamp(level, 0.0, 1.0)
    end

    def set_level_4(level)
      @level_4 = Dsp.clamp(level, 0.0, 1.0)
    end

    # Out Level is unipolar, [0.0, 1.0], a plain multiplier on the sum, so one control can take a
    # blend of two sources up and down together. It is applied before the sum is held to its range,
    # so it can also bring a sum that would have been clipped back inside it.
    def set_out_level(level)
      @out_level = Dsp.clamp(level, 0.0, 1.0)
    end

    # The inputs are taken as they are; only the sum is held to a range. A mixer is one
    # of the places on the bus where a value can come out bigger than what went in, and like the
    # others (Amp Gain, Pitch 1 Stretch) it clamps what it puts out -- so this is what keeps every
    # slot finite. That matters beyond tidiness: a NaN would pass through the modules that read it,
    # and the only way to make one here is to overflow to infinity first, which this makes
    # impossible.
    #
    # One unit is the sum of two full-scale bipolar signals, as much as any destination can use; an
    # audio destination takes up to a unit too, so two oscillators at full level want Out Level at
    # 0.5 to stay inside it.
    # Written as a literal rather than a constant on purpose: Spinel emits a named Float as a mutable
    # global, and a mixer loading one twice a sample is about 1.8us a buffer.
    def process(control_tick, input_1 = 0.0, input_2 = 0.0, input_3 = 0.0, input_4 = 0.0)
      if control_tick
        @stage_1_1 = Dsp.smooth(@level_1, @stage_1_1, @smoothing_target_blend)
        @current_1 = Dsp.smooth(@stage_1_1, @current_1, @smoothing_target_blend)
        @stage_1_2 = Dsp.smooth(@level_2, @stage_1_2, @smoothing_target_blend)
        @current_2 = Dsp.smooth(@stage_1_2, @current_2, @smoothing_target_blend)
        @stage_1_3 = Dsp.smooth(@level_3, @stage_1_3, @smoothing_target_blend)
        @current_3 = Dsp.smooth(@stage_1_3, @current_3, @smoothing_target_blend)
        @stage_1_4 = Dsp.smooth(@level_4, @stage_1_4, @smoothing_target_blend)
        @current_4 = Dsp.smooth(@stage_1_4, @current_4, @smoothing_target_blend)
        @stage_1_out_level = Dsp.smooth(@out_level, @stage_1_out_level, @smoothing_target_blend)
        @current_out_level = Dsp.smooth(@stage_1_out_level, @current_out_level, @smoothing_target_blend)
      end

      sum = (((input_1 * @current_1 + input_2 * @current_2) + input_3 * @current_3) + input_4 * @current_4) * @current_out_level
      output = Dsp.clamp(sum, -1.0, 1.0)
      @output = output
      output
    end

    # Out Inv: Out of the last process, negated.
    def output_inverted
      -@output
    end
  end
end
