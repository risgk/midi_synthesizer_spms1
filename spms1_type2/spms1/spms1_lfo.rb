module Spms1
  # Triangle and square LFO. The triangle is band-limited with PolyBLAMP (polynomial band-limited
  # ramp): the slope change at each corner is rounded off over the two samples around it, as
  # PolyBLEP rounds off a step. A triangle's harmonics fall off as 1/n^2, so what folds back stays
  # low even without it, but at the top of the rate range, where the LFO is an audible tone, it
  # takes the aliases at 220 Hz from -69 dB to -81 dB, in total against the signal. The square is
  # the triangle's side, with each step rounded off by PolyBLEP, and unipolar: 1.0 while the
  # triangle is above zero and 0.0 while it is below, so it gates, or trills up from the note,
  # rather than swinging about zero as the triangle does. It puts out both at once, each on an
  # output of its own, with Out, which process returns, crossfading from one to the other by Wave.
  # Each of the three has an inverted output beside it, the same negated.
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
      # The blend of the parameters smoothed once every 16 samples, four control ticks (see
      # smooth_parameters): the one above taken four times over, for the same time.
      @smoothing_16_blend = 1.0 - (1.0 - @smoothing_target_blend) ** 4.0
      @phase = 0.0
      @reset_high = 0.0
      @reset_switch = 0.0
      # Middle of the range, its power-on value; its smoothing starts at 0.0, as every module's does.
      @rate = 0.5
      @stage_1_rate = 0.0
      @current_rate = 0.0
      # The level powers up at 0.0, so that the LFO is silent at startup and fades in to the level
      # the patch sets, 1.0 by default.
      @level = 0.0
      # The level, smoothed; the per-sample path takes one multiply by it.
      @amount = 0.0
      @stage_1_amount = 0.0
      @current_amount = 0.0
      # Each modulation depth is its amount, smoothed as the other modules' are.
      @rate_modulation_depth = 1.0
      @stage_1_rate_modulation_depth = 0.0
      @current_rate_modulation_depth = 0.0
      # The level's modulation depth likewise. The level and what Level Mod In adds to it are
      # summed and held to [0.0, 1.0] at each control-rate step.
      @level_modulation_depth = 1.0
      @stage_1_level_modulation_depth = 0.0
      @current_level_modulation_depth = 0.0
      @total_amount = 0.0
      # Powers up at the triangle.
      @wave = 0.0
      @stage_1_wave = 0.0
      @current_wave = 0.0
      @output_triangle = 0.0
      @output_square = 0.0
      @output = 0.0
      # Not derived here: process assigns them on its first call, before anything reads them.
      @dt = 0.0
      @blamp_scale = 0.0
      @blep_scale = 0.0
      @blamp_side = 0.0
    end

    # Rate is unipolar, [0.0, 1.0], and read as a note number, so the dial is linear in pitch:
    # 0.215 Hz at 0.0, 6.875 Hz at 0.5, 220 Hz at 1.0.
    def set_rate(rate)
      @rate = (rate < 0.0) ? 0.0 : ((rate > 1.0) ? 1.0 : rate)
    end

    # Rate Mod Amt is unipolar, [0.0, 1.0], the depth of Rate Mod In. A unit of modulation input
    # times depth is the whole rate range, ten octaves, so at full depth a bipolar source swings the
    # rate five octaves either way. A modulation the other way up takes an inverted source.
    def set_rate_modulation_amount(amount)
      @rate_modulation_depth = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # Level Mod Amt is unipolar, [0.0, 1.0], the depth of Level Mod In, in the same way. A unit of
    # Level Mod In times depth is the whole level, so the mod wheel at its top adds a full level at
    # full depth.
    def set_level_modulation_amount(amount)
      @level_modulation_depth = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # Reset Sw: Reset In is taken at 0.5 and above, and ignored below.
    def set_reset_switch(switch)
      @reset_switch = (switch >= 0.5) ? 1.0 : 0.0
    end

    # The output is scaled by level, unipolar, [0.0, 1.0], a plain multiplier, so a destination
    # can take the LFO at less than full scale without a mixer in between. Turning it the other
    # way up is for Out Inv, or a mixer's Out Inv.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @amount = @level
    end

    # Wave is unipolar, [0.0, 1.0], and crossfades Out in a straight line, from the triangle alone
    # at 0.0 to the square alone at 1.0.
    def set_wave(wave)
      @wave = (wave < 0.0) ? 0.0 : ((wave > 1.0) ? 1.0 : wave)
    end

    # The parameters that scale no audio themselves -- rates, depths, times -- smoothed in two
    # stages once every 16 samples, four control ticks, by the main loop for every module whatever
    # runs, so that they cost a quarter as much and the same for any patch. What multiplies the
    # audio is smoothed at every control tick, where a coarser step would be heard.
    def smooth_parameters
      @stage_1_rate = Dsp.smooth(@rate, @stage_1_rate, @smoothing_16_blend)
      @current_rate = Dsp.smooth(@stage_1_rate, @current_rate, @smoothing_16_blend)
      @stage_1_amount = Dsp.smooth(@amount, @stage_1_amount, @smoothing_16_blend)
      @current_amount = Dsp.smooth(@stage_1_amount, @current_amount, @smoothing_16_blend)
      @stage_1_rate_modulation_depth = Dsp.smooth(@rate_modulation_depth, @stage_1_rate_modulation_depth, @smoothing_16_blend)
      @current_rate_modulation_depth = Dsp.smooth(@stage_1_rate_modulation_depth, @current_rate_modulation_depth, @smoothing_16_blend)
      @stage_1_level_modulation_depth = Dsp.smooth(@level_modulation_depth, @stage_1_level_modulation_depth, @smoothing_16_blend)
      @current_level_modulation_depth = Dsp.smooth(@stage_1_level_modulation_depth, @current_level_modulation_depth, @smoothing_16_blend)
      @stage_1_wave = Dsp.smooth(@wave, @stage_1_wave, @smoothing_16_blend)
      @current_wave = Dsp.smooth(@stage_1_wave, @current_wave, @smoothing_16_blend)
    end

    # The triangle is bipolar and spans one unit peak to peak at full level, [-0.5, 0.5], the same
    # span as the pitch domain; the square is unipolar, [0.0, 1.0], and Out crossfades between them. Every bipolar signal on the bus is scaled that way, so a destination's
    # amount control means the same thing whichever one is routed to it.
    # Both modulation inputs are read at the control-rate step, as the filter reads its own, and
    # not smoothed: the phase increment and the PolyBLAMP scale below take a table lookup and a
    # division, which every fourth sample can afford and every sample would be paying for. Rate Mod
    # In is held to the rate range after it is added, which also keeps the lookup in bounds, and
    # Level Mod In to the level's, so the wheel adds to the level up to its top and no further.
    # Reset In restarts the cycle where it rises above zero, as a gate does at a note on, with Reset
    # Sw on: read at the control-rate step, as a gate only changes between buffers, which are a
    # whole number of steps.
    def process(control_tick, rate_modulation_input = 0.0, level_modulation_input = 0.0, reset_input = 0.0)
      if control_tick
        reset_high = (reset_input > 0.0) ? @reset_switch : 0.0
        @phase -= (reset_high - reset_high * @reset_high) * @phase
        @reset_high = reset_high
        # Rate, amount and the two modulation depths are smoothed at the control rate to avoid sudden
        # jumps, and the phase increment is derived here rather than per sample.
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
        # The PolyBLEP residual is (1 - |x|)^2 of half the step for a step x samples away, and the
        # square steps by a whole unit, so with d as above it is (dt - d)^2 / dt^2 of the square's
        # own value: 1 / dt^2, which the scale above already holds two thirds of.
        @blep_scale = @blamp_scale * 1.5
        @blamp_side = @blamp_scale * -2.0
      end

      # Triangle folded out of the phase ramp. The quarter-turn shift puts 0.0 at the start of the
      # cycle, so a destination sees the LFO leave its unmodulated value rather than jump off it.
      shifted = @phase + 0.25
      shifted -= (shifted < 1.0) ? 0.0 : 1.0
      distance = shifted - 0.5
      # abs rather than a ternary: Spinel emits fabs, which is one vabs.f32 instruction, where a
      # branch would alternate, taken for half of every LFO cycle.
      folded = distance.abs
      triangle = 0.5 - (2.0 * folded)
      # PolyBLAMP: folded is the distance in phase to the top corner, and 0.5 - folded to the
      # bottom one, so the nearer of the two is 0.25 - |folded - 0.25| away. A sample within dt of
      # it is pulled toward the inside of the corner, down at the top and up at the bottom.
      # Branchless, as the oscillator's PolyBLEP is: each select here only picks a value, with nothing on either side for GCC to move
      # inside a branch, so the correction is computed every sample and comes out as 0.0 away from
      # a corner. The cost is the same at every phase. The square below is +0.5 while the triangle
      # is above zero, the side of the top corner, so the side is taken from it, by a multiply
      # rather than a select of its own: two selects on one condition, GCC turns into a branch.
      # Halving and doubling are exact, so the side is the same either way.
      square = (folded < 0.25) ? 0.5 : -0.5
      corner_gap = @dt - (0.25 - (folded - 0.25).abs)
      gap = (corner_gap > 0.0) ? corner_gap : 0.0
      side = square * @blamp_side
      triangle += gap * gap * gap * side
      # The square steps where the triangle crosses zero, at folded 0.25, so a step is
      # |folded - 0.25| away in phase. PolyBLEP: a sample within dt of a step is pulled toward the
      # middle of it, by the same branchless select as above.
      step_gap = @dt - (folded - 0.25).abs
      edge = (step_gap > 0.0) ? step_gap : 0.0
      square -= square * (edge * edge * @blep_scale)
      @output_triangle = triangle * @total_amount
      # +0.5 and -0.5 shifted up to 1.0 and 0.0, the step rounded off as it was.
      @output_square = (square + 0.5) * @total_amount
      output = @output_triangle + (@output_square - @output_triangle) * @current_wave
      @output = output

      @phase += @dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0

      output
    end

    # Out Inv: Out of the last process, negated.
    def output_inverted
      -@output
    end

    # The triangle and the square of the last process.
    def output_triangle
      @output_triangle
    end

    def output_square
      @output_square
    end

    # Out Triangle Inv and Out Square Inv: the triangle and the square, negated.
    def output_triangle_inverted
      -@output_triangle
    end

    def output_square_inverted
      -@output_square
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
