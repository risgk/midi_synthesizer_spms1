module Spms1
  # Amplifier that smooths the gain parameter to avoid zipper noise.
  # Modulation input is applied directly without smoothing.
  class Amp
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
      @gain = 1.0
      @stage_1_gain = 1.0
      @current_gain = 1.0
    end

    # Gain is unipolar, [0.0, 1.0].
    # Range: -∞ dB (0.0), -6 dB (0.5), 0 dB (1.0).
    # Used as a plain multiplier, so @gain is an amplitude and the smoothing below works in the
    # amplitude domain.
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    def process(control_tick, audio_input = 0.0, modulation_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if control_tick
        @stage_1_gain = Dsp.smooth(@gain, @stage_1_gain, @smoothing_target_blend)
        @current_gain = Dsp.smooth(@stage_1_gain, @current_gain, @smoothing_target_blend)
      end

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
