module Spms1
  # Sums four inputs, each at its own level and its own polarity. With one input routed it is a
  # buffer, an attenuator or an inverter; inverting just one input subtracts it from another; and
  # a constant on another input shifts a unipolar signal, such as the envelope, into a bipolar
  # one. Mixer 1 serves the modulation, Mixer 2 the audio ahead of the filter.
  class Mixer
    # Blend at the reference rate on the line below, for each of two cascaded stages. The two move
    # together: their product is what fixes the time constant, so changing one without the other
    # changes how fast smoothing is. Two stages at 1/64 (5.3 ms each at 48 kHz) delay a step by
    # 10.7 ms on average, as one stage at 1/128 would, but start from zero slope, so that the steps
    # of a controller sending sparse CCs (e.g. every 20 ms) are rounded off rather than heard,
    # and settle sooner, 99% in 35 ms.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    # It has to stay a power of two: the counter below wraps with a mask, because Ruby's % is a
    # floor-modulo and sp_imod carries a sign correction the counter can never need -- one branch
    # a sample in each module, six across the six of them.
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
      # Every level powers up silent, so an input fades in from nothing when its level is first set
      # rather than sounding at full level before the patch says otherwise.
      @level_1 = 0.0
      @level_2 = 0.0
      @level_3 = 0.0
      @level_4 = 0.0
      @polarity_1 = 1.0
      @polarity_2 = 1.0
      @polarity_3 = 1.0
      @polarity_4 = 1.0
      # Each polarity is folded into its own level at the control rate rather than applied per
      # sample, so the per-sample path is four multiplies and three adds and only four states smooth.
      @target_1 = 0.0
      @target_2 = 0.0
      @target_3 = 0.0
      @target_4 = 0.0
      @stage_1_1 = 0.0
      @stage_1_2 = 0.0
      @stage_1_3 = 0.0
      @stage_1_4 = 0.0
      @current_1 = 0.0
      @current_2 = 0.0
      @current_3 = 0.0
      @current_4 = 0.0
      # Out Level scales the sum, smoothed as the input levels are.
      @out_level = 1.0
      @stage_1_out_level = 1.0
      @current_out_level = 1.0
      @sample_counter = 0
    end

    # Each level is unipolar, [0.0, 1.0], and used as a plain multiplier on its own input.
    def set_level_1(level)
      @level_1 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_1 = @level_1 * @polarity_1
    end

    def set_level_2(level)
      @level_2 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_2 = @level_2 * @polarity_2
    end

    def set_level_3(level)
      @level_3 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_3 = @level_3 * @polarity_3
    end

    def set_level_4(level)
      @level_4 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_4 = @level_4 * @polarity_4
    end

    # Each polarity is bipolar, [-0.5, 0.5], and doubled into a multiplier on its own input: +0.5
    # passes it through, -0.5 negates it, and the way between scales it, crossing silence at 0.0.
    # Continuous rather than a switch so that smoothing carries it across zero without a step.
    # Inverting one input is what makes a difference rather than a sum; inverting both negates the
    # output.
    def set_polarity_1(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_1 = clamped_polarity + clamped_polarity
      @target_1 = @level_1 * @polarity_1
    end

    def set_polarity_2(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_2 = clamped_polarity + clamped_polarity
      @target_2 = @level_2 * @polarity_2
    end

    def set_polarity_3(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_3 = clamped_polarity + clamped_polarity
      @target_3 = @level_3 * @polarity_3
    end

    def set_polarity_4(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_4 = clamped_polarity + clamped_polarity
      @target_4 = @level_4 * @polarity_4
    end

    # Out Level is unipolar, [0.0, 1.0], a plain multiplier on the sum, so one control can take a
    # blend of two sources up and down together. It is applied before the sum is held to its range,
    # so it can also bring a sum that would have been clipped back inside it.
    def set_out_level(level)
      @out_level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
    end

    # The inputs are taken as they are; only the sum is held to a range. A mixer is the one place on
    # the bus where a value can come out bigger than what went in -- every other module is fixed at
    # half a unit, or saturates, or only attenuates -- so this is what keeps every slot finite. That
    # matters beyond tidiness: a comparison lets a NaN through any clamp, and the only way to make
    # one here is to overflow to infinity first, which this makes impossible.
    #
    # One unit is the sum of two full-scale bipolar signals, as much as any destination can use; an
    # audio destination takes up to a unit too. The sum is held to it the way the filter's output
    # is, as an analog mixer runs out of headroom gradually: exactly linear up to 0.75, then a
    # quadratic shoulder that reaches 1.0 with zero slope at 1.25. Two oscillators at full level
    # reach into the shoulder, and the noise on top of them goes past it; a hard clamp there folded
    # every harmonic of its corner back into the note, where the shoulder's fall much faster. The
    # default patch peaks at half a unit and passes untouched.
    # Written as literals rather than constants on purpose: Spinel emits a named Float as a mutable
    # global, and a mixer loading one twice a sample is about 1.8us a buffer.
    def process(input_1 = 0.0, input_2 = 0.0, input_3 = 0.0, input_4 = 0.0)
      if @sample_counter == 0
        @stage_1_1 = Dsp.smooth(@target_1, @stage_1_1, @smoothing_target_blend)
        @current_1 = Dsp.smooth(@stage_1_1, @current_1, @smoothing_target_blend)
        @stage_1_2 = Dsp.smooth(@target_2, @stage_1_2, @smoothing_target_blend)
        @current_2 = Dsp.smooth(@stage_1_2, @current_2, @smoothing_target_blend)
        @stage_1_3 = Dsp.smooth(@target_3, @stage_1_3, @smoothing_target_blend)
        @current_3 = Dsp.smooth(@stage_1_3, @current_3, @smoothing_target_blend)
        @stage_1_4 = Dsp.smooth(@target_4, @stage_1_4, @smoothing_target_blend)
        @current_4 = Dsp.smooth(@stage_1_4, @current_4, @smoothing_target_blend)
        @stage_1_out_level = Dsp.smooth(@out_level, @stage_1_out_level, @smoothing_target_blend)
        @current_out_level = Dsp.smooth(@stage_1_out_level, @current_out_level, @smoothing_target_blend)
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      sum = ((input_1 * @current_1 + input_2 * @current_2) + (input_3 * @current_3 + input_4 * @current_4)) * @current_out_level
      # Built from abs, as Filter#clip_output is, so that it has no branch. It cost 33us a buffer
      # across both mixers, 1243 against 1210, estimated for a Pico 2 at 48 kHz, 2026-10-17.
      # The excess is doubled, so the shoulder's 1 / (4 * (1.0 - 0.75)) takes a further quarter.
      over    = sum - 1.25
      under   = -1.25 - sum
      clamped = sum - ((over + over.abs) - (under + under.abs)) * 0.5
      above   = clamped - 0.75
      below   = -0.75 - clamped
      excess  = (above + above.abs) - (below + below.abs)
      clamped - (excess * excess.abs) * 0.25
    end
  end
end
