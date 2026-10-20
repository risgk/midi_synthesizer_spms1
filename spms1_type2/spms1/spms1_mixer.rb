module Spms1
  # Sums three inputs, each at its own level, and scales the sum by Out Level. Out, which process
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
      @stage_1_1 = 0.0
      @stage_1_2 = 0.0
      @stage_1_3 = 0.0
      @current_1 = 0.0
      @current_2 = 0.0
      @current_3 = 0.0
      # Out Level scales the sum, smoothed as the input levels are.
      @out_level = 1.0
      @stage_1_out_level = 1.0
      @current_out_level = 1.0
      @output = 0.0
    end

    # Each level is unipolar, [0.0, 1.0], and used as a plain multiplier on its own input.
    def set_level_1(level)
      @level_1 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    def set_level_2(level)
      @level_2 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    def set_level_3(level)
      @level_3 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    # Out Level is unipolar, [0.0, 1.0], a plain multiplier on the sum, so one control can take a
    # blend of two sources up and down together. It is applied before the sum is held to its range,
    # so it can also bring a sum that would have been clipped back inside it.
    def set_out_level(level)
      @out_level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    # The inputs are taken as they are; only the sum is held to a range. A mixer is the one place on
    # the bus where a value can come out bigger than what went in -- every other module is fixed at
    # half a unit, or saturates, or only attenuates -- so this is what keeps every slot finite. That
    # matters beyond tidiness: a comparison lets a NaN through any clamp, and the only way to make
    # one here is to overflow to infinity first, which this makes impossible.
    #
    # One unit is the sum of two full-scale bipolar signals, as much as any destination can use; an
    # audio destination takes up to a unit too, so two oscillators at full level want Out Level at
    # 0.5 to stay inside it.
    # Written as a literal rather than a constant on purpose: Spinel emits a named Float as a mutable
    # global, and a mixer loading one twice a sample is about 1.8us a buffer.
    def process(control_tick, input_1 = 0.0, input_2 = 0.0, input_3 = 0.0)
      if control_tick
        @stage_1_1 = Dsp.smooth(@level_1, @stage_1_1, @smoothing_target_blend)
        @current_1 = Dsp.smooth(@stage_1_1, @current_1, @smoothing_target_blend)
        @stage_1_2 = Dsp.smooth(@level_2, @stage_1_2, @smoothing_target_blend)
        @current_2 = Dsp.smooth(@stage_1_2, @current_2, @smoothing_target_blend)
        @stage_1_3 = Dsp.smooth(@level_3, @stage_1_3, @smoothing_target_blend)
        @current_3 = Dsp.smooth(@stage_1_3, @current_3, @smoothing_target_blend)
        @stage_1_out_level = Dsp.smooth(@out_level, @stage_1_out_level, @smoothing_target_blend)
        @current_out_level = Dsp.smooth(@stage_1_out_level, @current_out_level, @smoothing_target_blend)
      end

      sum = ((input_1 * @current_1 + input_2 * @current_2) + input_3 * @current_3) * @current_out_level
      # One nested ternary, not two statements. Split in two, each comparison compiles to a vsel
      # when the method stands alone, which is not how it is built: inside the flattened
      # Spms1_main the branch count does not move and the extra instructions cost 870/875us a
      # buffer against 854/856. The same holds for the clamps in Amp#process and Osc#process.
      # Measured on a Pico 2 at 48 kHz, 2026-09-18.
      output = (sum < -1.0) ? -1.0 : ((sum > 1.0) ? 1.0 : sum)
      @output = output
      output
    end

    # Out Inv: Out of the last process, negated.
    def output_inverted
      -@output
    end
  end
end
