module Spms1
  # Mono delay with feedback, after PRA32-U2's Delay FX: one audio input, one output, a crossfade
  # of the dry input with the delayed signal.
  # Reference: https://github.com/risgk/digital-synth-pra32-u2 (pra32-u2-delay-fx.h)
  #
  # It keeps the bus's one unit without a limiter or a clip. What enters the loop is half the
  # input, plus the delayed signal at a feedback of at most a half, so as long as the delayed
  # signal is within one unit, so is what is written back -- and it starts at silence. The low
  # pass filter in the loop and the reading between two samples are weighted averages, which
  # cannot reach past what they average, and the output is a crossfade, which cannot either. The
  # price of the half is that the first repeat is 6 dB under the dry signal.
  class Delay
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
    # can never need.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction would survive into the per-sample path carrying an overflow check of its own.
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    # The delay line, a power of two so that its index wraps with a mask, for the same reason as
    # the counter above. It holds the longest delay at 48 kHz, 16272 samples, plus the older of
    # the two samples the interpolation reads; a higher sample rate would need it longer.
    # Reading reaches back 16384 samples at most, to the slot about to be written, which still
    # holds its oldest sample; a delay of 16384 or more would read back the newest one.
    # Array.new(16384, 0.0) grows by pushes to a capacity of 17407, 68 KB of floats, and on the
    # way there briefly holds the 34 KB it grew from as well.
    DELAY_LINE_SIZE = 16384
    DELAY_LINE_MASK = DELAY_LINE_SIZE - 1

    # The Time dial, in samples at 48 kHz: a straight line from 0 at 0.0 to 17280 (360 ms) at 1.0,
    # 3 ms a CC step, clipped to 144 (3 ms) at the bottom and 16272 (339 ms) at the top. The bottom
    # keeps the read clear of the sample about to be written; the top is the last CC step that fits
    # the line above, with room left for the slew to overshoot by rounding.
    FULL_SCALE_TIME_AT_48K = 17280.0
    MIN_TIME_AT_48K        = 144.0
    MAX_TIME_AT_48K        = 16272.0
    # How far the read position may move per sample while Time is turned, in samples: a quarter,
    # as PRA32-U2 allows. Moving it faster would read the line at many times its speed, which is
    # heard as noise; held to this, the repeats bend in pitch by at most 25%, as a tape delay's do,
    # and arrive at the new time a moment later.
    TIME_SLEW = 0.25

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @full_scale_time = FULL_SCALE_TIME_AT_48K * (@sample_rate / 48000.0)
      @min_time = MIN_TIME_AT_48K * (@sample_rate / 48000.0)
      @max_time = MAX_TIME_AT_48K * (@sample_rate / 48000.0)
      # The slew per control-rate update, and its negative, so that the update clamps without
      # arithmetic on a constant.
      @time_slew_up = TIME_SLEW * CONTROL_RATE_DIVISOR
      @time_slew_down = -@time_slew_up
      @delay_line = Array.new(DELAY_LINE_SIZE, 0.0)
      @write_index = 0
      # The state of the low pass filter in the loop.
      @filtered = 0.0

      # Each parameter starts where its control does at power-on, so nothing slides up to it.
      @time = 0.5
      @stage_1_time = 0.5
      @current_time = 0.5
      @feedback = 0.25
      @stage_1_feedback = 0.25
      @current_feedback = 0.25
      @mix = 0.25
      @stage_1_mix = 0.25
      @current_mix = 0.25

      # The delay the line is read at, in samples, which follows Time no faster than TIME_SLEW,
      # moved a step every sample so that it arrives at each control-rate update's value on time.
      @delay = @full_scale_time * @current_time
      @delay_step = 0.0
      @sample_counter = 0
    end

    # Time is unipolar, [0.0, 1.0], read as 0 to 360 ms in a straight line and clipped to 3 ms at
    # the bottom and 339 ms at the top.
    def set_time(time)
      @time = (time < 0.0) ? 0.0 : ((time > 1.0) ? 1.0 : time)
    end

    # Feedback is unipolar, [0.0, 1.0], and halved into the gain from the delayed signal back
    # into the line: a single repeat at 0.0, and at 1.0 repeats that fall 6 dB each. The half is
    # the ceiling that keeps the loop within one unit; see the class comment.
    def set_feedback(feedback)
      clamped_feedback = (feedback < 0.0) ? 0.0 : ((feedback > 1.0) ? 1.0 : feedback)
      @feedback = clamped_feedback * 0.5
    end

    # Mix is unipolar, [0.0, 1.0], the delayed signal's share of the crossfade: the dry input at
    # 0.0, only the repeats at 1.0.
    def set_mix(mix)
      @mix = (mix < 0.0) ? 0.0 : ((mix > 1.0) ? 1.0 : mix)
    end

    def process(audio_input = 0.0)
      if @sample_counter == 0
        @stage_1_time += (@time - @stage_1_time) * @smoothing_target_blend
        @current_time += (@stage_1_time - @current_time) * @smoothing_target_blend
        @stage_1_feedback += (@feedback - @stage_1_feedback) * @smoothing_target_blend
        @current_feedback += (@stage_1_feedback - @current_feedback) * @smoothing_target_blend
        @stage_1_mix += (@mix - @stage_1_mix) * @smoothing_target_blend
        @current_mix += (@stage_1_mix - @current_mix) * @smoothing_target_blend

        # Where the read position should be by the next update, at most the slew away, and a
        # quarter of the way there each sample.
        target = @full_scale_time * @current_time
        target = (target < @min_time) ? @min_time : ((target > @max_time) ? @max_time : target)
        distance = target - @delay
        distance = (distance < @time_slew_down) ? @time_slew_down : ((distance > @time_slew_up) ? @time_slew_up : distance)
        @delay_step = distance * 0.25
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # Held to the bus's one unit on the way in, as the amp holds its modulation input: the
      # bound the loop keeps is only as good as what enters it.
      input = (audio_input < -1.0) ? -1.0 : ((audio_input > 1.0) ? 1.0 : audio_input)

      @delay += @delay_step
      @write_index = (@write_index + 1) & DELAY_LINE_MASK
      # Read before this sample's write, from at least 144 samples back, so truncating the delay
      # is flooring it and neither sample read is the one about to be written.
      whole = @delay.to_i
      fraction = @delay - whole.to_f
      newer = @delay_line[(@write_index - whole) & DELAY_LINE_MASK]
      older = @delay_line[(@write_index - whole - 1) & DELAY_LINE_MASK]
      delayed = newer + fraction * (older - newer)

      # A gentle low pass in the loop, as PRA32-U2 has: 0.75 of what goes in and 0.25 of the last
      # value, so each repeat comes back a little darker than the one before.
      loop_input = input * 0.5 + delayed * @current_feedback
      @filtered = loop_input + (@filtered - loop_input) * 0.25
      @delay_line[@write_index] = @filtered

      input + (delayed - input) * @current_mix
    end
  end
end
