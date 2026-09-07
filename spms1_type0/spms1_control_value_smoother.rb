module Spms1
  # Synthesizer-knob-like parameter: holds a target value and smooths the current value toward it
  # at the control rate, to avoid sudden jumps and zipper noise. Owned and stepped by the caller
  # (e.g. main.rb), independently of the module that ends up consuming the smoothed value.
  class ControlValueSmoother
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    CONTROL_RATE_DIVISOR = 4

    def initialize(sample_rate, initial_value = 0.0)
      @target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @current = initial_value
      @sample_counter = 0
    end

    # Target is the knob's raw value; already-valid-range values are expected (callers clamp).
    def process(target = 0.0)
      if @sample_counter == 0
        @current += (target - @current) * @target_blend
      end
      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      @current
    end
  end
end
