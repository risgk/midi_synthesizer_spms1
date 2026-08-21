module Spms1
  # An Amplifier module that controls audio volume using a modulation input 
  # (typically driven by an Envelope Generator output) with parameter smoothing.
  class Amp
    # A 4-sample grid implementation to maintain the original time constant
    SMOOTHING_TARGET_BLEND_BASE = 0.015625

    def initialize
      @sample_rate = 96000.0
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE
      # Configurable base gain coefficient (1.0 = unity gain)
      @gain = 1.0
      # Current smoothed gain state to prevent zipper noise
      @current_gain = 1.0
      # Internal counter to automatically handle the 4-sample control block updates
      @sample_counter = 0
    end

    # Sets the system sample rate.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 96000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate)
    end

    # Sets the target base gain of the amplifier.
    # @param gain [Float] Volume level from 0.0 to 1.0
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    # Processes a single audio sample scaled by the modulation input.
    # @param audio_input [Float] Input audio sample
    # @param modulation_input [Float] Control signal from an EG or LFO (typically -1.0 to 1.0)
    # @return [Float] Amplified output sample
    def process(audio_input = 0.0, modulation_input = 1.0)
      # Synchronize parameter smoothing routines onto the internal 8-sample step boundary
      if @sample_counter == 0
        @current_gain += (@gain - @current_gain) * @smoothing_target_blend
      end

      # Increment and mask the sample tracking counter (0 to 3 wrap around for 4-sample grid)
      @sample_counter = (@sample_counter + 1) & 3

      # Clamp modulation input to safe normalized bounds (-1.0 to 1.0)
      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)

      # Calculate the total gain by combining smoothed base gain and modulation
      total_gain = @current_gain * mod

      # Apply gain to the audio input
      audio_input * total_gain
    end
  end
end
