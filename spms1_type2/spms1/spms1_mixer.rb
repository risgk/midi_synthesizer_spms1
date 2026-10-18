module Spms1
  # Sums four inputs, each at its own level and its own polarity, with a balance across each pair,
  # 1 and 2, 3 and 4. With one input routed it is a buffer, an attenuator or an inverter; inverting
  # just one input subtracts it from another; a constant on another input shifts a unipolar
  # signal, such as the envelope, into a bipolar one; and a balance turned to one end selects one
  # input of its pair. Mixer 1 serves the modulation, Mixer 2 the audio ahead of the filter.
  class Mixer
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

    # Lookup for the balances, one run of 130 entries for each of the five laws Balance Law picks,
    # each a factor f(u) for u = i / 64, 0.0 to 2.0, interpolated in a straight line between
    # entries:
    #   0 linear      f(u) = u               the two factors add to 2.0
    #   1 reserved    f(u) = sqrt(u)         as equal power, until a law is put here
    #   2 equal power f(u) = sqrt(u)         their squares add to 2.0
    #   3 filter Mode f(u) = min(u, 1.0)     each at 1.0 over its own half, as Filter 1 Mode's
    #   4 split       f(u) = max(u - 1.0, 0) one input on each side, at the balance's distance from
    #                                        the centre: both silent there, each at 1.0 at its end
    # A balance is worked out every buffer whether it has moved or not, never only when it changes,
    # and always by the same few operations with no branch on its value or on the law: the time a
    # buffer takes must not hang on what the patch or the CCs are doing, so that its worst case is
    # the case measured, and can be guaranteed. A square root would be a library call in double
    # precision on the Pico 2, with a branch for its domain inside, and a choice between formulas a
    # branch; the law only moves where in the table the factor is read. Every law but split has
    # f(1.0) = 1.0, so the centre leaves its pair as it is, and the entries at u = 1.0 and 2.0 are
    # exact. The linear, the filter Mode and the split laws are straight between entries, their
    # corners at u = 1.0 on an entry, so they are exact everywhere; the square root's line runs
    # under its curve, by up to 0.03 in the first entry, near silence, and under 0.001 from
    # u = 0.25 on. The last entry of each run repeats the one before it so that interpolating at
    # u = 2.0 reads a real entry of the same run rather than the next run's first.
    BALANCE_TABLE_RUN = 130
    BALANCE_TABLE = Array.new(650, 0.0)
    for i in 0...129
      u = i.to_f * (1.0 / 64.0)
      BALANCE_TABLE[i] = u
      BALANCE_TABLE[130 + i] = Math.sqrt(u)
      BALANCE_TABLE[260 + i] = Math.sqrt(u)
      BALANCE_TABLE[390 + i] = (u < 1.0) ? u : 1.0
      BALANCE_TABLE[520 + i] = (u > 1.0) ? u - 1.0 : 0.0
    end
    BALANCE_TABLE[129] = BALANCE_TABLE[128]
    BALANCE_TABLE[259] = BALANCE_TABLE[258]
    BALANCE_TABLE[389] = BALANCE_TABLE[388]
    BALANCE_TABLE[519] = BALANCE_TABLE[518]
    BALANCE_TABLE[649] = BALANCE_TABLE[648]

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # Where the law Balance Law picks starts in BALANCE_TABLE; equal power at power-up.
      @balance_law_offset = 260
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
      # The balance of each pair as a multiplier on each of its two inputs, 1.0 at the centre.
      @balance_factor_1 = 1.0
      @balance_factor_2 = 1.0
      @balance_factor_3 = 1.0
      @balance_factor_4 = 1.0
      # Each polarity and balance is folded into its own level when it is set rather than applied
      # per sample, so the per-sample path is four multiplies and three adds and only four states
      # smooth.
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
    end

    # Each level is unipolar, [0.0, 1.0], and used as a plain multiplier on its own input.
    def set_level_1(level)
      @level_1 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_1 = @level_1 * @polarity_1 * @balance_factor_1
    end

    def set_level_2(level)
      @level_2 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_2 = @level_2 * @polarity_2 * @balance_factor_2
    end

    def set_level_3(level)
      @level_3 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_3 = @level_3 * @polarity_3 * @balance_factor_3
    end

    def set_level_4(level)
      @level_4 = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @target_4 = @level_4 * @polarity_4 * @balance_factor_4
    end

    # Each polarity is bipolar, [-0.5, 0.5], and doubled into a multiplier on its own input: +0.5
    # passes it through, -0.5 negates it, and the way between scales it, crossing silence at 0.0.
    # Continuous rather than a switch so that smoothing carries it across zero without a step.
    # Inverting one input is what makes a difference rather than a sum; inverting both negates the
    # output.
    def set_polarity_1(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_1 = clamped_polarity + clamped_polarity
      @target_1 = @level_1 * @polarity_1 * @balance_factor_1
    end

    def set_polarity_2(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_2 = clamped_polarity + clamped_polarity
      @target_2 = @level_2 * @polarity_2 * @balance_factor_2
    end

    def set_polarity_3(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_3 = clamped_polarity + clamped_polarity
      @target_3 = @level_3 * @polarity_3 * @balance_factor_3
    end

    def set_polarity_4(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity_4 = clamped_polarity + clamped_polarity
      @target_4 = @level_4 * @polarity_4 * @balance_factor_4
    end

    # Balance Law is bipolar, [-0.5, 0.5], and picks how both balances crossfade, in five zones, the
    # two at the ends 0.125 wide and the three between 0.25: linear (CC 0-18), reserved (CC 19-48,
    # as equal power for now), equal power (CC 49-78, as PRA32-U2's Osc Mix), as Filter 1 Mode
    # (CC 79-108) and split (CC 109-127), so the constants -0.5, -0.2, 0.0, +0.2 and +0.5 pick each.
    # It is bipolar only so that equal power, the default, is the centre, where it rests with no
    # CC. The zone is the integer part of law * 4 + 2.51, 0.51 to 4.51: the 0.01, a third of a CC
    # step, keeps every CC value off an edge, where float rounding could put it either side. No
    # branch either way. It is read once a buffer like any other
    # parameter, ahead of the balances, which are worked out again in the same buffer; their
    # factors are smoothed on the way to the inputs, so switching laws does not click.
    def set_balance_law(law)
      clamped_law = (law < -0.5) ? -0.5 : ((law > 0.5) ? 0.5 : law)
      @balance_law_offset = (clamped_law * 4.0 + 2.51).to_i * BALANCE_TABLE_RUN
    end

    # Each balance is bipolar, [-0.5, 0.5], and crossfades its pair by the law Balance Law picks,
    # the factors f(1 - 2b) and f(1 + 2b) of BALANCE_TABLE. 0.0 at the centre leaves both inputs as
    # they are, so the centre is the mixer without a balance, whatever the law but split, which
    # silences both there; -0.5 silences the second input and takes the first to 2.0 (linear), √2
    # (equal power) or 1.0 (filter Mode, split), and +0.5 the other way round. Split passes only
    # the first input below the centre and only the second above, each at twice the distance, so a
    # bipolar source on the balance plays one input with its negative half and the other with its
    # positive half. A crossfader, each input as it is at its own end, wants both levels
    # of the pair at 0.5, 1/√2 or 1.0 by the law: a pair at the same level keeps its total (linear),
    # its loudness when uncorrelated, as detuned oscillators are (equal power), or each input whole
    # over its own half (filter Mode). The clamp, written as nested ternaries so that it compiles
    # to selects rather than branches, keeps what the table is read at in 0.0 to 2.0.
    def set_balance_1_2(balance)
      clamped_balance = (balance < -0.5) ? -0.5 : ((balance > 0.5) ? 0.5 : balance)
      @balance_factor_1 = balance_factor_fast(1.0 - (clamped_balance + clamped_balance))
      @balance_factor_2 = balance_factor_fast(1.0 + (clamped_balance + clamped_balance))
      @target_1 = @level_1 * @polarity_1 * @balance_factor_1
      @target_2 = @level_2 * @polarity_2 * @balance_factor_2
    end

    def set_balance_3_4(balance)
      clamped_balance = (balance < -0.5) ? -0.5 : ((balance > 0.5) ? 0.5 : balance)
      @balance_factor_3 = balance_factor_fast(1.0 - (clamped_balance + clamped_balance))
      @balance_factor_4 = balance_factor_fast(1.0 + (clamped_balance + clamped_balance))
      @target_3 = @level_3 * @polarity_3 * @balance_factor_3
      @target_4 = @level_4 * @polarity_4 * @balance_factor_4
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
    # audio destination takes up to a unit too, so two oscillators at full level want Out Level at
    # 0.5 to stay inside it.
    # Written as a literal rather than a constant on purpose: Spinel emits a named Float as a mutable
    # global, and a mixer loading one twice a sample is about 1.8us a buffer.
    def process(control_tick, input_1 = 0.0, input_2 = 0.0, input_3 = 0.0, input_4 = 0.0)
      if control_tick
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

      sum = ((input_1 * @current_1 + input_2 * @current_2) + (input_3 * @current_3 + input_4 * @current_4)) * @current_out_level
      # One nested ternary, not two statements. Split in two, each comparison compiles to a vsel
      # when the method stands alone, which is not how it is built: inside the flattened
      # Spms1_main the branch count does not move and the extra instructions cost 870/875us a
      # buffer against 854/856. The same holds for the clamps in Amp#process and Osc#process.
      # Measured on a Pico 2 at 48 kHz, 2026-09-18.
      (sum < -1.0) ? -1.0 : ((sum > 1.0) ? 1.0 : sum)
    end

    private

    # The factor for u, 0.0 to 2.0, by the law picked, from BALANCE_TABLE: one multiply, one
    # conversion, an add, two loads and a multiply-add, with no branch of its own (Spinel's checks
    # on the conversion and the loads, which never fail here, aside), so it takes the same time
    # whatever u and the law are.
    def balance_factor_fast(u)
      position = u * 64.0
      whole = position.to_i
      fraction = position - whole.to_f
      index = whole + @balance_law_offset

      s0 = BALANCE_TABLE[index]
      s1 = BALANCE_TABLE[index + 1]

      s0 + fraction * (s1 - s0)
    end
  end
end
