module Spms1
  # Amplifier. Modulation input is applied directly without smoothing.
  class Amp
    # Gain is normalized to [0.0, 1.0] (already-smoothed values from a Smoother are expected).
    # Range: -∞ dB (0.0), -6 dB (0.5), 0 dB (1.0).
    def process(audio_input = 0.0, modulation_input = 1.0, gain = 1.0)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)

      audio_input * clamped_gain * mod
    end
  end
end
