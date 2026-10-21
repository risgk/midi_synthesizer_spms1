module Spms1
  # Amplifier that smooths the gain parameter to avoid zipper noise. Its two modulation inputs are
  # crossfaded by Mod 1/2 Mix and applied directly without smoothing.
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
      @modulation_mix = 0.0
      @stage_1_modulation_mix = 0.0
      @current_modulation_mix = 0.0
    end

    # Gain is unipolar, [0.0, 1.0], and doubled into a multiplier, so that the middle of the dial
    # is unity and the top can bring a quiet sound up as well as the bottom take it down.
    # Range: -∞ dB (0.0), 0 dB (0.5), +6 dB (1.0).
    # @gain is an amplitude, so the smoothing below works in the amplitude domain.
    def set_gain(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      @gain = clamped_gain + clamped_gain
    end

    # Mod 1/2 Mix is unipolar, [0.0, 1.0], and crossfades the gain's modulation in a straight line
    # from Mod 1 In alone at 0.0 to Mod 2 In alone at 1.0. Smoothed as the gain is, so that a sparse
    # CC does not step it.
    def set_modulation_mix(mix)
      @modulation_mix = (mix < 0.0) ? 0.0 : ((mix > 1.0) ? 1.0 : mix)
    end

    def process(control_tick, audio_input = 0.0, modulation_1_input = 1.0, modulation_2_input = 1.0)
      # Gain parameter is smoothed at control rate to avoid zipper noise.
      if control_tick
        @stage_1_gain = Dsp.smooth(@gain, @stage_1_gain, @smoothing_target_blend)
        @current_gain = Dsp.smooth(@stage_1_gain, @current_gain, @smoothing_target_blend)
        @stage_1_modulation_mix = Dsp.smooth(@modulation_mix, @stage_1_modulation_mix, @smoothing_target_blend)
        @current_modulation_mix = Dsp.smooth(@stage_1_modulation_mix, @current_modulation_mix, @smoothing_target_blend)
      end

      # Each side weighted on its own, so that at either end of Mod 1/2 Mix the one input
      # passes exactly as it is. The amp's modulation is the one in the synth that is clamped on the way
      # in: a modulation scales the gain down, and must not be able to scale it up however loud it
      # arrives. Negative still inverts. Gain reaches 2.0, so the output is held to -1.0 and +1.0, as a mixer's is, which
      # the default patch, at a gain of 1.0, never reaches. One nested ternary, for the reason
      # Mixer#process gives.
      modulation = modulation_1_input * (1.0 - @current_modulation_mix) + modulation_2_input * @current_modulation_mix
      mod = (modulation < -1.0) ? -1.0 : ((modulation > 1.0) ? 1.0 : modulation)
      total_gain = @current_gain * mod

      output = audio_input * total_gain
      (output < -1.0) ? -1.0 : ((output > 1.0) ? 1.0 : output)
    end
  end
end
