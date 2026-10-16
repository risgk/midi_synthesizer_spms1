module Spms1
  # Amplifier that smooths the gain parameter and the modulation depth to avoid zipper noise.
  # Modulation input is applied directly without smoothing.
  class Amp
    # Blend at the reference rate on the line below, for each of two cascaded stages. The two move
    # together: their product is what fixes the time constant, so changing one without the other
    # changes how fast smoothing is. Two stages at 1/64 (5.3 ms each at 48 kHz) delay a step by
    # 10.7 ms on average, as one stage at 1/128 would, but start from zero slope, so that the steps
    # of a controller sending sparse CCs (e.g. every 20 ms) are rounded off rather than heard,
    # and settle sooner, 99% in 35 ms.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately
    # constant if this is changed. It has to stay a power of two: the counter below wraps with a
    # mask, because Ruby's % is a floor-modulo and sp_imod carries a sign correction the counter
    # can never need -- one branch a sample in each module, six across the six of them.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction survives into the per-sample path carrying an overflow check of its own, which
    # measured far worse than the modulo it replaces. What the mask buys is size, not
    # determinism: the six branches it removes, one per site, are ones that could never be taken.
    # Together with the LFO's fold it took 11 branches and 60 instructions out of Spms1_main as
    # linked, and the buffer time did not move (853/857us against 854/856).
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @gain = 1.0
      @stage_1_gain = 1.0
      @current_gain = 1.0
      # Modulation depth is amount times polarity, as the other modules' is, multiplied before
      # smoothing so that only one smoothing state has to be carried.
      @modulation_amount = 1.0
      @modulation_polarity = 1.0
      @modulation_depth = 1.0
      @stage_1_modulation_depth = 1.0
      @current_modulation_depth = 1.0
      @sample_counter = 0
    end

    # Gain is unipolar, [0.0, 1.0].
    # Range: -∞ dB (0.0), -6 dB (0.5), 0 dB (1.0).
    # Used as a plain multiplier, so @gain is an amplitude and the smoothing below works in the
    # amplitude domain.
    def set_gain(gain)
      @gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
    end

    # Modulation depth is amount times polarity. Amount is unipolar, [0.0, 1.0]. Polarity is
    # bipolar, [-0.5, 0.5], and doubled, so +0.5 leaves the amount as it is, -0.5 negates it and
    # the way between scales it, crossing zero. The depth scales the modulation input before it
    # scales the gain, so at 1.0 the input passes as it arrives and at 0.0 the amp is shut, as a
    # mixer's Level shuts its input.
    def set_modulation_amount(amount)
      @modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @modulation_depth = @modulation_amount * @modulation_polarity
    end

    def set_modulation_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @modulation_polarity = clamped_polarity + clamped_polarity
      @modulation_depth = @modulation_amount * @modulation_polarity
    end

    def process(audio_input = 0.0, modulation_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if @sample_counter == 0
        @stage_1_gain = Dsp.smooth(@gain, @stage_1_gain, @smoothing_target_blend)
        @current_gain = Dsp.smooth(@stage_1_gain, @current_gain, @smoothing_target_blend)
        @stage_1_modulation_depth = Dsp.smooth(@modulation_depth, @stage_1_modulation_depth, @smoothing_target_blend)
        @current_modulation_depth = Dsp.smooth(@stage_1_modulation_depth, @current_modulation_depth, @smoothing_target_blend)
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # The one modulation input in the synth that is clamped on the way in, because an amp is an
      # attenuator: a modulation scales the gain down, and must not be able to scale it up however
      # loud it arrives. Negative still inverts. @gain is already [0.0, 1.0] and the depth
      # [-1.0, 1.0], so the product needs no clamp of its own.
      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
      total_gain = @current_gain * (mod * @current_modulation_depth)

      audio_input * total_gain
    end
  end
end
