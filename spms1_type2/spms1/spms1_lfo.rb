module Spms1
  # Triangle LFO, band-limited with PolyBLAMP (polynomial band-limited ramp): the slope change at
  # each corner is rounded off over the two samples around it, as PolyBLEP rounds off a step. A
  # triangle's harmonics fall off as 1/n^2, so what folds back stays low even without it, but at the
  # top of the rate range, where the LFO is an audible tone, it takes the aliases at 220 Hz from
  # -69 dB to -81 dB, in total against the signal.
  class LFO
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

    # Rate lookup table, one entry per semitone of MIDI note -63 to 57, so 0.215 Hz to 220 Hz.
    # Its own table rather than the oscillator's, which starts at note 0 and cannot reach this low.
    # 122 entries so that a rate of 1.0 still has an entry above it to interpolate against.
    FREQ_TABLE = Array.new(122, 0.0)
    for i in 0...122
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 132.0) * (1.0 / 12.0)))
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      # Reciprocal kept alongside the rate so process multiplies rather than divides. @sample_rate
      # is an Integer, so dividing by it in the per-sample path also costs an int-to-float
      # conversion on top of the division.
      @inv_sample_rate = 1.0 / sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @phase = 0.0
      # Middle of the range, so the LFO starts where its control does rather than sliding up to it.
      @rate = 0.5
      @stage_1_rate = 0.5
      @current_rate = 0.5
      @level = 1.0
      # The level, smoothed; the per-sample path takes one multiply by it.
      @amount = 1.0
      @stage_1_amount = 1.0
      @current_amount = 1.0
      # Modulation depth is amount times polarity, as the other modules' are, multiplied before
      # smoothing so that only one smoothing state has to be carried.
      @rate_modulation_amount = 1.0
      @rate_modulation_polarity = 1.0
      @rate_modulation_depth = 1.0
      @stage_1_rate_modulation_depth = 1.0
      @current_rate_modulation_depth = 1.0
      # The level's modulation depth likewise. The level and what Level Mod In adds to it are
      # summed and held to [0.0, 1.0] at each control-rate step.
      @level_modulation_amount = 1.0
      @level_modulation_polarity = 1.0
      @level_modulation_depth = 1.0
      @stage_1_level_modulation_depth = 1.0
      @current_level_modulation_depth = 1.0
      @total_amount = 1.0
      # Not derived here: process assigns them on its first call, before anything reads them.
      @dt = 0.0
      @blamp_scale = 0.0
    end

    # Rate is unipolar, [0.0, 1.0], and read as a note number, so the dial is linear in pitch:
    # 0.215 Hz at 0.0, 6.875 Hz at 0.5, 220 Hz at 1.0.
    def set_rate(rate)
      @rate = (rate < 0.0) ? 0.0 : ((rate > 1.0) ? 1.0 : rate)
    end

    # Rate Mod depth is amount times polarity. Amount is unipolar, [0.0, 1.0]. Polarity is
    # bipolar, [-0.5, 0.5], and doubled, so +0.5 leaves the amount as it is, -0.5 negates it and
    # the way between scales it, crossing zero. A unit of modulation input times depth is the
    # whole rate range, ten octaves, so at full depth a bipolar source swings the rate five octaves
    # either way.
    def set_rate_modulation_amount(amount)
      @rate_modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @rate_modulation_depth = @rate_modulation_amount * @rate_modulation_polarity
    end

    def set_rate_modulation_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @rate_modulation_polarity = clamped_polarity + clamped_polarity
      @rate_modulation_depth = @rate_modulation_amount * @rate_modulation_polarity
    end

    # Level Mod depth is amount times polarity in the same way. A unit of Level Mod In times depth
    # is the whole level, so the mod wheel at its top adds a full level at full depth.
    def set_level_modulation_amount(amount)
      @level_modulation_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @level_modulation_depth = @level_modulation_amount * @level_modulation_polarity
    end

    def set_level_modulation_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @level_modulation_polarity = clamped_polarity + clamped_polarity
      @level_modulation_depth = @level_modulation_amount * @level_modulation_polarity
    end

    # The output is scaled by level, unipolar, [0.0, 1.0], a plain multiplier, so a destination
    # can take the LFO at less than full scale without a mixer in between. Turning it the other
    # way up is for the destination's own Mod Pol, or a mixer's Pol.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @amount = @level
    end

    # Output is bipolar and spans one unit peak to peak at full level, [-0.5, 0.5],
    # the same span as the pitch domain. Every bipolar signal on the bus is scaled that way, so a destination's
    # amount control means the same thing whichever one is routed to it.
    # Both modulation inputs are read at the control-rate step, as the filter reads its own, and
    # not smoothed: the phase increment and the PolyBLAMP scale below take a table lookup and a
    # division, which every fourth sample can afford and every sample would be paying for. Rate Mod
    # In is held to the rate range after it is added, which also keeps the lookup in bounds, and
    # Level Mod In to the level's, so the wheel adds to the level up to its top and no further.
    def process(control_tick, rate_modulation_input = 0.0, level_modulation_input = 0.0)
      if control_tick
        # Rate, amount and the two modulation depths are smoothed at the control rate to avoid sudden
        # jumps, and the phase increment is derived here rather than per sample.
        @stage_1_rate = Dsp.smooth(@rate, @stage_1_rate, @smoothing_target_blend)
        @current_rate = Dsp.smooth(@stage_1_rate, @current_rate, @smoothing_target_blend)
        @stage_1_amount = Dsp.smooth(@amount, @stage_1_amount, @smoothing_target_blend)
        @current_amount = Dsp.smooth(@stage_1_amount, @current_amount, @smoothing_target_blend)
        @stage_1_rate_modulation_depth = Dsp.smooth(@rate_modulation_depth, @stage_1_rate_modulation_depth, @smoothing_target_blend)
        @current_rate_modulation_depth = Dsp.smooth(@stage_1_rate_modulation_depth, @current_rate_modulation_depth, @smoothing_target_blend)
        @stage_1_level_modulation_depth = Dsp.smooth(@level_modulation_depth, @stage_1_level_modulation_depth, @smoothing_target_blend)
        @current_level_modulation_depth = Dsp.smooth(@stage_1_level_modulation_depth, @current_level_modulation_depth, @smoothing_target_blend)
        total_amount = @current_amount + (level_modulation_input * @current_level_modulation_depth)
        @total_amount = (total_amount < 0.0) ? 0.0 : ((total_amount > 1.0) ? 1.0 : total_amount)
        total_rate = @current_rate + (rate_modulation_input * @current_rate_modulation_depth)
        rate = (total_rate < 0.0) ? 0.0 : ((total_rate > 1.0) ? 1.0 : total_rate)
        @dt = rate_to_freq_fast(rate) * @inv_sample_rate
        # The PolyBLAMP residual is (1 - |x|)^3 / 6 of the slope change for a corner x samples
        # away. The slope changes by 4 * dt at each corner, and with the distance d = |x| * dt in
        # phase that is (dt - d)^3 * (2/3) / dt^2: the division is taken here, once per update,
        # and process only multiplies. dt is never 0, the lowest rate being 0.215 Hz.
        @blamp_scale = 0.6666667 / (@dt * @dt)
      end

      # Triangle folded out of the phase ramp. The quarter-turn shift puts 0.0 at the start of the
      # cycle, so a destination sees the LFO leave its unmodulated value rather than jump off it.
      shifted = @phase + 0.25
      shifted -= (shifted < 1.0) ? 0.0 : 1.0
      distance = shifted - 0.5
      # abs rather than a ternary: Spinel emits fabs, which is one vabs.f32 instruction, and the
      # branch it replaces was the only one in the per-sample path that actually alternated --
      # taken for half of every LFO cycle.
      folded = distance.abs
      triangle = 0.5 - (2.0 * folded)
      # PolyBLAMP: folded is the distance in phase to the top corner, and 0.5 - folded to the
      # bottom one, so the nearer of the two is 0.25 - |folded - 0.25| away. A sample within dt of
      # it is pulled toward the inside of the corner, down at the top and up at the bottom.
      # Branchless, as the oscillator's selects are meant to be, and unlike them it survives the C
      # compiler: each select here only picks a value, with nothing on either side for GCC to move
      # inside a branch, so the correction is computed every sample and comes out as 0.0 away from
      # a corner. The cost is the same at every phase.
      corner_gap = @dt - (0.25 - (folded - 0.25).abs)
      gap = (corner_gap > 0.0) ? corner_gap : 0.0
      side = (folded < 0.25) ? -@blamp_scale : @blamp_scale
      triangle += gap * gap * gap * side
      output = triangle * @total_amount

      @phase += @dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0

      output
    end

    private

    def rate_to_freq_fast(rate)
      internal_rate = rate * 120.0
      index = internal_rate.to_i
      fraction = internal_rate - index.to_f
      f0 = FREQ_TABLE[index]
      f1 = FREQ_TABLE[index + 1]
      f0 + fraction * (f1 - f0)
    end
  end
end
