module Spms1
  # An Amplifier module that controls audio volume using a modulation input 
  # (typically driven by an Envelope Generator output).
  class Amp
    def initialize
      @sample_rate = 48000.0
      # Configurable base gain coefficient (1.0 = unity gain)
      @gain = 1.0
    end

    # Sets the system sample rate.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 48000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
    end

    # Sets the base gain of the amplifier.
    # @param gain [Float] Volume level from 0.0 to 1.0
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    # Processes a single audio sample scaled by the modulation input.
    # @param audio_input [Float] Input audio sample
    # @param modulation_input [Float] Control signal from an EG or LFO (typically -1.0 to 1.0)
    # @return [Float] Amplified output sample
    def process(audio_input = 0.0, modulation_input = 1.0)
      # Clamp modulation input to safe normalized bounds (-1.0 to 1.0)
      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)

      # Calculate the total gain by combining base gain and modulation
      total_gain = @gain * mod

      # Apply gain to the audio input
      audio_input * total_gain
    end
  end
end
