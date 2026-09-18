module Spms1
  # Amplifier that smooths the gain parameter to avoid zipper noise.
  # Modulation input is applied directly without smoothing.
  class Amp
    # Blend at the reference rate on the line below. The two move together: their product is what
    # fixes the time constant, so changing one without the other changes how fast smoothing is.
    SMOOTHING_TARGET_BLEND_BASE = 0.03125
    # Number of samples between control-rate updates; smoothing speed is kept approximately
    # constant if this is changed. It has to stay a power of two: the counter below wraps with a
    # mask, because Ruby's % is a floor-modulo and sp_imod carries a sign correction the counter
    # can never need -- one branch a sample in each module, ten across the six of them.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction survives into the per-sample path carrying an overflow check of its own, which
    # measured far worse than the modulo it replaces. What the mask buys is size -- ten branches
    # and 66 instructions across the six modules -- and not determinism: every branch it removes
    # is one that could never be taken. The buffer time did not move (853/857us against 854/856).
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @gain = 1.0
      @current_gain = 1.0
      @sample_counter = 0
    end

    # Gain is normalized to [0.0, 1.0].
    # Range: -∞ dB (0.0), -6 dB (0.5), 0 dB (1.0).
    # Used as a plain multiplier, so @gain is an amplitude and the smoothing below works in the
    # amplitude domain.
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    def process(audio_input = 0.0, modulation_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if @sample_counter == 0
        @current_gain += (@gain - @current_gain) * @smoothing_target_blend
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # The one modulation input in the synth that is clamped on the way in, because an amp is an
      # attenuator: a modulation scales the gain down, and must not be able to scale it up however
      # loud it arrives. Negative still inverts. @gain is already [0.0, 1.0], so the product needs
      # no clamp of its own.
      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
      total_gain = @current_gain * mod

      audio_input * total_gain
    end
  end
end
