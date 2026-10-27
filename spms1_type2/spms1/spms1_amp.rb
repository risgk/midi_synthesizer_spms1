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

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # The gains start at 0.0, so that the sound comes in through the smoothing at power-up.
      @gain = 0.0
      @stage_1_gain = 0.0
      @current_gain = 0.0
      @gain_2 = 0.0
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
    end

    # Gain 1, of Audio In 1, is unipolar, [0.0, 1.0], and squared and taken four times into a multiplier, so that the
    # middle of the dial is unity, the top can bring a quiet sound up by 12 dB as well as the bottom
    # take it down, and the dial moves in steps nearer equal in dB than a straight line's.
    # Range: -∞ dB (0.0), -6 dB (0.354), 0 dB (0.5), +6 dB (0.707), +12 dB (1.0).
    # @gain is an amplitude, so the smoothing below works in the amplitude domain.
    def set_gain_1(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
      @gain = 4.0 * clamped_gain * clamped_gain
    end

    # Gain 2, of Audio In 2, as Gain 1 is of Audio In 1.
    def set_gain_2(gain)
      clamped_gain = (gain < 0.0) ? 0.0 : ((gain > 1.0) ? 1.0 : gain)
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
      @modulation_mix = (mix < 0.0) ? 0.0 : ((mix > 1.0) ? 1.0 : mix)
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
      end

      # Each side weighted on its own, so that at either end of Mod 1/2 Mix the one input
      # passes exactly as it is. The amp's modulation is the one in the synth that is clamped on the way
      # in: a modulation scales the gain down, and must not be able to scale it up however loud it
      # arrives. Negative still inverts.
      modulation = modulation_1_input * (1.0 - @current_modulation_mix) + modulation_2_input * @current_modulation_mix
      mod = (modulation < -1.0) ? -1.0 : ((modulation > 1.0) ? 1.0 : modulation)
      amplified = (audio_input * @current_gain + audio_input_2 * @current_gain_2) * mod

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
      # it under that, and it is reached with the limiter off. One nested ternary, for the reason
      # Mixer#process gives.
      (output < -1.0) ? -1.0 : ((output > 1.0) ? 1.0 : output)
    end
  end
end
