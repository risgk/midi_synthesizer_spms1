module Spms1
  # Amplifier that smooths the gain parameter to avoid zipper noise.
  # Modulation input is applied directly without smoothing.
  class Amp
    SMOOTHING_TARGET_BLEND_BASE = 0.015625

    def initialize
      @sample_rate = 96000.0
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE
      @gain = 1.0
      @current_gain = 1.0
      @sample_counter = 0
    end

    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate)
    end

    # Gain is normalized to [0.0, 1.0].
    # Range: -∞ dB (0.0), -6 dB (0.5), 0 dB (1.0).
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    def process(audio_input = 0.0, modulation_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if @sample_counter == 0
        @current_gain += (@gain - @current_gain) * @smoothing_target_blend
      end

      @sample_counter = (@sample_counter + 1) & 3

      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
      total_gain = @current_gain * mod

      audio_input * total_gain
    end
  end
end
