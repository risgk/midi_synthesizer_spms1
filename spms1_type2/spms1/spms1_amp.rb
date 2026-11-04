module Spms1
  # Amplifier of two audio inputs, each with a gain of its own, which it smooths to avoid zipper
  # noise, and sums before the modulation and the limiter. Its two modulation inputs are
  # crossfaded by Mod 1/2 Mix and applied directly without smoothing. A look-ahead limiter after
  # the gain holds what leaves under the one-unit clamp, so that the gain can bring a sound well up
  # without the clamp's corners: the output comes LIMITER_LOOKAHEAD_TIME late, and the limiter
  # takes the gain down over that time before a peak arrives, rather than at it, and lets it back
  # up slowly, from the highest peak of a window long enough to span a cycle of a low note.
  class Amp
    # Where the limiter holds the peaks, 0.9 (-0.9 dB), under the clamp at one unit, which stays as
    # the last guard. The gain it needs is taken from the highest level of the block in progress
    # and the one before it, blocks of LIMITER_HOLD_TIME, so from the last 25 to 50 ms: that spans
    # a cycle of a note down to 20 Hz, so the peak does not fall between the crests of a held note
    # and the gain does not ripple at its pitch, as it did from a peak envelope falling over the
    # release, by some 7% at C3 with a resonant filter. The gain follows what it needs with a
    # one-pole smoother, fast enough on the way down to be within 1% of it a look-ahead later,
    # which is what the margin under the clamp is for, and over LIMITER_RELEASE_TIME on the way
    # back up, rounding off the step as a block with a lower peak takes over.
    LIMITER_THRESHOLD      = 0.9
    LIMITER_LOOKAHEAD_TIME = 0.001
    LIMITER_HOLD_TIME      = 0.025
    LIMITER_RELEASE_TIME   = 0.1
    # The delay line, a power of two above the look-ahead at up to 192 kHz.
    LIMITER_LINE_SIZE = 256
    LIMITER_LINE_MASK = LIMITER_LINE_SIZE - 1
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

    # Distortion: what the gain puts out, driven by D = 2^(5 * distortion), x1 to x32 (6 dB every
    # fifth of the dial), through a curve that is a straight line up to DISTORTION_KNEE and a
    # quadratic shoulder from there that lands on DISTORTION_LIMIT with zero slope at
    # DISTORTION_CEILING, and taken back down by D^(-15/16): 15/16 of the drive in dB, so that the
    # level stays within about 1.5 dB as the drive goes up (a little up halfway, and a little down
    # where it saturates hard), and the limiter after it holds the rest. The knee is
    # the bus's one unit, which no input reaches at x1 with the gains at unity, so the default patch
    # passes as it did. The curve's part beyond the straight line, f(u) - u, goes through first-order
    # antiderivative anti-aliasing (ADAA): the difference of its antiderivative over the step from the
    # last sample, divided by the step. On the straight line that part is zero, so a sample that
    # reaches no shoulder, now or a sample ago, passes exactly, neither late nor rounded off in the
    # highs, as ADAA on the whole curve would leave it; past the knee it is half a sample late against
    # the straight part. Below DISTORTION_ADAA_MIN_STEP of a step, where the difference loses its
    # precision in single precision, the part is taken at the sample itself instead. Against the
    # curve without ADAA, a sine at C5 to C8 driven x16 aliases -61 to -16 dB in total and -71 to
    # -25 dB under 5 kHz; with it, the tone and the make-up, -83 to -62 dB under 5 kHz at x16, and
    # -77 to -57 dB at x32.
    DISTORTION_KNEE     = 1.0
    DISTORTION_LIMIT    = 2.0
    DISTORTION_CEILING  = DISTORTION_LIMIT + DISTORTION_LIMIT - DISTORTION_KNEE
    DISTORTION_SPAN     = DISTORTION_CEILING - DISTORTION_KNEE
    # 1 / (4 * (limit - knee)), and its third for the antiderivative.
    DISTORTION_SHOULDER = 1.0 / (4.0 * (DISTORTION_LIMIT - DISTORTION_KNEE))
    DISTORTION_SHOULDER_THIRD = DISTORTION_SHOULDER / 3.0
    DISTORTION_FLAT     = DISTORTION_LIMIT - DISTORTION_KNEE
    DISTORTION_ADAA_MIN_STEP = 0.001
    # Below zero, the shoulder is half as long, to -1.5 at -2.0, so that the curve is not symmetric
    # and adds even harmonics too (about 10 to 25 dB under the odd ones); its DC is taken off at
    # DISTORTION_DC_FREQUENCY. After the curve, the tone, a 1-pole low pass, takes the edge off the
    # harmonics, more with more drive: none at x1, about 10 kHz halfway, DISTORTION_TONE_FREQUENCY at the top.
    DISTORTION_SPAN_BELOW     = 1.0
    DISTORTION_DC_FREQUENCY   = 3.73  # 48000 / (2 * pi * 2048), a rate of 2^-11 at 48 kHz
    DISTORTION_TONE_FREQUENCY = 5000.0
    # D = 2^(i * 5 / 32) and D^(-15/16) = 2^(-i * 75 / 512), one entry for each 1/32 of the dial, the
    # last repeated for the interpolation's upper neighbour. The make-up is held at x16 (0.8 of the dial,
    # i = 25.6), where most of a sound is past the shoulder already, which holds the level of what
    # comes out from there on.
    DISTORTION_GAIN_TABLE = Array.new(34, 0.0)
    DISTORTION_COMP_TABLE = Array.new(34, 0.0)
    for i in 0...33
      DISTORTION_GAIN_TABLE[i] = 2.0 ** (i.to_f * (5.0 / 32.0))
      DISTORTION_COMP_TABLE[i] = 2.0 ** (((i.to_f < 25.6) ? i.to_f : 25.6) * (-75.0 / 512.0))
    end
    DISTORTION_GAIN_TABLE[33] = DISTORTION_GAIN_TABLE[32]
    DISTORTION_COMP_TABLE[33] = DISTORTION_COMP_TABLE[32]

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @gain = 1.0
      @stage_1_gain = 0.0
      @current_gain = 0.0
      @gain_2 = 1.0
      @stage_1_gain_2 = 0.0
      @current_gain_2 = 0.0
      @modulation_mix = 0.0
      @stage_1_modulation_mix = 0.0
      @current_modulation_mix = 0.0

      lookahead = (LIMITER_LOOKAHEAD_TIME * @sample_rate).round
      @limiter_lookahead = (lookahead < LIMITER_LINE_MASK) ? lookahead : LIMITER_LINE_MASK
      @limiter_threshold = LIMITER_THRESHOLD
      @limiter_hold = (LIMITER_HOLD_TIME * @sample_rate).round
      @limiter_hold_left = @limiter_hold
      @limiter_release = 1.0 - Math.exp(-1.0 / (LIMITER_RELEASE_TIME * @sample_rate))
      # 1% left of a step after the look-ahead.
      @limiter_attack = 1.0 - (0.01 ** (1.0 / @limiter_lookahead.to_f))
      @limiter_line = Array.new(LIMITER_LINE_SIZE, 0.0)
      @limiter_write_index = 0
      @limiter_block_peak = 0.0
      @limiter_last_block_peak = 0.0
      @limiter_gain = 1.0
      @limiter_switch = 1.0
      @distortion = 0.0
      @stage_1_distortion = 0.0
      @current_distortion = 0.0
      @distortion_gain = 1.0
      @distortion_comp = 1.0
      @distortion_last_input = 0.0
      @distortion_last_antiderivative = 0.0
      # The tone after the curve, a 1-pole low pass: the weight of its last output is
      # @distortion_tone_rest, from 0.0 at x1 (none) up to that of DISTORTION_TONE_FREQUENCY at the top.
      @distortion_tone_max_rest = Math.exp(-2.0 * Math::PI * DISTORTION_TONE_FREQUENCY / @sample_rate)
      @distortion_tone = 1.0
      @distortion_tone_rest = 0.0
      @distortion_tone_out = 0.0
      # The DC of the curve's part (its shoulders are not symmetric), followed by a 1-pole low pass
      # at DISTORTION_DC_FREQUENCY and taken off.
      @distortion_dc_rate = 1.0 - Math.exp(-2.0 * Math::PI * DISTORTION_DC_FREQUENCY / @sample_rate)
      @distortion_dc = 0.0
    end

    # Distortion is unipolar, [0.0, 1.0], the drive into the curve, x1 at 0.0 to x32 at 1.0 (see
    # DISTORTION_KNEE). Smoothed as the gains are.
    def set_distortion(distortion)
      @distortion = Dsp.clamp(distortion, 0.0, 1.0)
    end

    # Gain 1, of Audio In 1, is unipolar, [0.0, 1.0], and squared and taken four times into a multiplier, so that the
    # middle of the dial is unity, the top can bring a quiet sound up by 12 dB as well as the bottom
    # take it down, and the dial moves in steps nearer equal in dB than a straight line's.
    # Range: -∞ dB (0.0), -6 dB (0.354), 0 dB (0.5), +6 dB (0.707), +12 dB (1.0).
    # @gain is an amplitude, so the smoothing below works in the amplitude domain.
    def set_gain_1(gain)
      clamped_gain = Dsp.clamp(gain, 0.0, 1.0)
      @gain = 4.0 * clamped_gain * clamped_gain
    end

    # Gain 2, of Audio In 2, as Gain 1 is of Audio In 1.
    def set_gain_2(gain)
      clamped_gain = Dsp.clamp(gain, 0.0, 1.0)
      @gain_2 = 4.0 * clamped_gain * clamped_gain
    end

    # Limiter Sw: the limiter on at 0.5 and above, off below, where the peaks reach the clamp. Off,
    # the output is as late as on, so that switching moves nothing in time.
    def set_limiter_switch(switch)
      @limiter_switch = (switch >= 0.5) ? 1.0 : 0.0
    end

    # Mod 1/2 Mix is unipolar, [0.0, 1.0], and crossfades the gain's modulation in a straight line
    # from Mod 1 In alone at 0.0 to Mod 2 In alone at 1.0. Smoothed as the gain is, so that a sparse
    # CC does not step it.
    def set_modulation_mix(mix)
      @modulation_mix = Dsp.clamp(mix, 0.0, 1.0)
    end

    def process(control_tick, audio_input = 0.0, audio_input_2 = 0.0, modulation_1_input = 1.0, modulation_2_input = 1.0)
      # The gain parameters are smoothed at control rate to avoid zipper noise.
      if control_tick
        @stage_1_gain = Dsp.smooth(@gain, @stage_1_gain, @smoothing_target_blend)
        @current_gain = Dsp.smooth(@stage_1_gain, @current_gain, @smoothing_target_blend)
        @stage_1_gain_2 = Dsp.smooth(@gain_2, @stage_1_gain_2, @smoothing_target_blend)
        @current_gain_2 = Dsp.smooth(@stage_1_gain_2, @current_gain_2, @smoothing_target_blend)
        @stage_1_modulation_mix = Dsp.smooth(@modulation_mix, @stage_1_modulation_mix, @smoothing_target_blend)
        @current_modulation_mix = Dsp.smooth(@stage_1_modulation_mix, @current_modulation_mix, @smoothing_target_blend)
        @stage_1_distortion = Dsp.smooth(@distortion, @stage_1_distortion, @smoothing_target_blend)
        @current_distortion = Dsp.smooth(@stage_1_distortion, @current_distortion, @smoothing_target_blend)
        # The drive and its make-up from the tables, every tick whatever the value.
        position = @current_distortion * 32.0
        index = position.to_i
        fraction = position - index.to_f
        @distortion_gain = DISTORTION_GAIN_TABLE[index] + fraction * (DISTORTION_GAIN_TABLE[index + 1] - DISTORTION_GAIN_TABLE[index])
        @distortion_comp = DISTORTION_COMP_TABLE[index] + fraction * (DISTORTION_COMP_TABLE[index + 1] - DISTORTION_COMP_TABLE[index])
        @distortion_tone_rest = @distortion_tone_max_rest * @current_distortion
        @distortion_tone = 1.0 - @distortion_tone_rest
      end

      # Each side weighted on its own, so that at either end of Mod 1/2 Mix the one input
      # passes exactly as it is. The amp's modulation is the one in the synth that is clamped on the way
      # in: a modulation scales the gain down, and must not be able to scale it up however loud it
      # arrives. Negative still inverts.
      modulation = modulation_1_input * (1.0 - @current_modulation_mix) + modulation_2_input * @current_modulation_mix
      mod = Dsp.clamp(modulation, -1.0, 1.0)
      gained = (audio_input * @current_gain + audio_input_2 * @current_gain_2) * mod

      # The distortion (see DISTORTION_KNEE): u is the driven sample, r the curve's part beyond the
      # straight line by ADAA, and both are taken back down by the make-up. The antiderivative is
      # worked out once a sample and kept for the next; the part itself, for a short step, from the
      # same terms, at this sample rather than the middle of the step, which a step that short makes
      # no measurable difference to. Branchless: each term is clamped into its own range, and the short step is
      # a weight of 1.0 or 0.0, a select between two literals, which GCC keeps a select.
      # Written with literals, DISTORTION_* above, as Spinel emits a named Float constant as a
      # runtime global: the knee 1.0, the ceiling 3.0, the shoulder 0.25 (its third 0.25 / 3.0), and
      # the flat part's limit - knee 1.0.
      # Below zero the shoulder is half as long (DISTORTION_SPAN_BELOW), selected by the sign as a
      # weight of 1.0 or 0.0: its end (the ceiling) 3.0 or 2.0, the shoulder 1 / (2 * span) 0.25 or
      # 0.5, and the flat part's limit - knee (span / 2) 1.0 or 0.5. The part has the sign of -u,
      # from the same weight.
      u = gained * @distortion_gain
      a = u.abs
      negative = (u < 0.0) ? 1.0 : 0.0
      ceiling = 3.0 - negative
      shoulder = 0.25 + 0.25 * negative
      flat = 1.0 - 0.5 * negative
      e = Dsp.clamp(a, 1.0, ceiling) - 1.0
      d = C.float_max(a - ceiling, 0.0)
      curved = e * e * shoulder
      part = (curved + d) * (2.0 * negative - 1.0)
      antiderivative = 0.0 - curved * e * (1.0 / 3.0) - flat * d - d * d * 0.5
      step = u - @distortion_last_input
      short = (step.abs < 0.001) ? 1.0 : 0.0
      r = part * short + (antiderivative - @distortion_last_antiderivative) / (step + short) * (1.0 - short)
      @distortion_last_input = u
      @distortion_last_antiderivative = antiderivative
      # The DC of the part taken off, and the tone, as the sum of two weights (not a difference):
      # with nothing past the knee, the part and its DC are zero, and at x1 the weight of the input
      # is 1.0 and that of the last output 0.0, so that the amp is exactly as it was.
      dc = @distortion_dc + (r - @distortion_dc) * @distortion_dc_rate
      @distortion_dc = dc
      toned = (u + (r - dc)) * @distortion_tone + @distortion_tone_out * @distortion_tone_rest
      @distortion_tone_out = toned
      amplified = toned * @distortion_comp

      # The limiter. The gain it wants is the threshold over the peak of the two blocks where that
      # is above it, and 1.0 where not, or always while it is switched off; the one division is
      # taken every sample, whatever the level, so that a loud passage costs what a quiet one does.
      # A block ends once every LIMITER_HOLD_TIME, the one branch that takes more work.
      level = amplified.abs
      @limiter_block_peak = (level > @limiter_block_peak) ? level : @limiter_block_peak
      @limiter_hold_left -= 1
      if @limiter_hold_left == 0
        @limiter_last_block_peak = @limiter_block_peak
        @limiter_block_peak = 0.0
        @limiter_hold_left = @limiter_hold
      end
      peak = (@limiter_block_peak > @limiter_last_block_peak) ? @limiter_block_peak : @limiter_last_block_peak
      over = (peak > @limiter_threshold) ? peak : @limiter_threshold
      wanted = 1.0 + (@limiter_threshold / over - 1.0) * @limiter_switch
      # The rate, attack on the way down and release on the way up, picked by a 1.0 or 0.0 rather
      # than as one of the two: GCC made a choice between two instance variables a branch, to load
      # only the one, but one between two literals a select.
      falling = (wanted < @limiter_gain) ? 1.0 : 0.0
      rate = @limiter_release + (@limiter_attack - @limiter_release) * falling
      @limiter_gain += (wanted - @limiter_gain) * rate
      @limiter_write_index = (@limiter_write_index + 1) & LIMITER_LINE_MASK
      @limiter_line[@limiter_write_index] = amplified
      output = @limiter_line[(@limiter_write_index - @limiter_lookahead) & LIMITER_LINE_MASK] * @limiter_gain

      # A gain reaches 4.0, so the output is held to -1.0 and +1.0, as a mixer's is: the limiter keeps
      # it under that, and it is reached with the limiter off.
      Dsp.clamp(output, -1.0, 1.0)
    end
  end
end
