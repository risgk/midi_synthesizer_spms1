module Spms1
  # Amplifier that smooths the gain parameter to avoid zipper noise.
  # Modulation input is applied directly without smoothing.
  class Amp
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    CONTROL_RATE_DIVISOR = 4

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @gain = 1.0
      @current_gain = 1.0
      @sample_counter = 0
    end

    # Gain is normalized to [0.0, 1.0].
    # Range: -∞ dB (0.0), -12 dB (0.5), 0 dB (1.0).
    # Squared here rather than by the caller: the taper is part of what gain means, while the
    # caller's job is only to get a control value into [0.0, 1.0]. @gain therefore holds amplitude,
    # so the smoothing below works in the amplitude domain.
    def set_gain(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      @gain = clamped_gain * clamped_gain
    end

    def process(audio_input = 0.0, modulation_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if @sample_counter == 0
        @current_gain += (@gain - @current_gain) * @smoothing_target_blend
      end

      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
      total_gain = @current_gain * mod

      audio_input * total_gain
    end
  end
end
