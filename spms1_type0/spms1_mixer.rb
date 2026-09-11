module Spms1
  # Sums two inputs, each at its own level and its own polarity. With one input left unrouted it
  # is a buffer, an attenuator or an inverter; inverting just one input subtracts it from the
  # other; and a constant on the second input shifts a unipolar signal into a bipolar one, which
  # is the only way to build a bipolar control out of a CC.
  class Mixer
    # Blend at the reference rate on the line below. The two move together: their product is what
    # fixes the time constant, so changing one without the other changes how fast smoothing is.
    SMOOTHING_TARGET_BLEND_BASE = 0.03125
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    CONTROL_RATE_DIVISOR = 4

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @level_1 = 1.0
      @level_2 = 1.0
      @polarity_1 = 1.0
      @polarity_2 = 1.0
      # Each polarity is folded into its own level at the control rate rather than applied per
      # sample, so the per-sample path is two multiplies and an add and only two states smooth.
      @target_1 = 1.0
      @target_2 = 1.0
      @current_1 = 1.0
      @current_2 = 1.0
      @sample_counter = 0
    end

    # Each level is normalized to [0.0, 1.0] and used as a plain multiplier on its own input.
    def set_level_1(level)
      @level_1 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_1 = @level_1 * @polarity_1
    end

    def set_level_2(level)
      @level_2 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_2 = @level_2 * @polarity_2
    end

    # Each invert is normalized to [0.0, 1.0] and read as a polarity on its own input: 0.0 passes
    # it through, 1.0 negates it, and the way between scales it, crossing silence at 0.5. Continuous
    # rather than a switch so that smoothing carries it across zero without a step. Inverting one
    # input is what makes a difference rather than a sum; inverting both negates the output.
    def set_invert_1(invert)
      clamped_invert = (invert < 0.0) ? 0.0 : ((invert > 1.0) ? 1.0 : invert)
      @polarity_1 = 1.0 - (clamped_invert + clamped_invert)
      @target_1 = @level_1 * @polarity_1
    end

    def set_invert_2(invert)
      clamped_invert = (invert < 0.0) ? 0.0 : ((invert > 1.0) ? 1.0 : invert)
      @polarity_2 = 1.0 - (clamped_invert + clamped_invert)
      @target_2 = @level_2 * @polarity_2
    end

    # Both inputs are taken as they are. Nothing is clamped here: a mixer carries audio as often as
    # it carries control, and the destination is what decides the range it wants.
    def process(input_1 = 0.0, input_2 = 0.0)
      if @sample_counter == 0
        @current_1 += (@target_1 - @current_1) * @smoothing_target_blend
        @current_2 += (@target_2 - @current_2) * @smoothing_target_blend
      end

      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      input_1 * @current_1 + input_2 * @current_2
    end
  end
end
