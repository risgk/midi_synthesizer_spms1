module Spms1
  # Stereo delay with feedback, after PRA32-U2's Delay FX in its Stereo Delay mode: two audio
  # inputs, left and right, each with a delay line and a loop of its own, and two outputs, each a
  # crossfade of its dry input with its delayed signal. Time, Feedback and Mix are shared, so the
  # two sides repeat together and the stereo image going in is the one the repeats keep.
  # Reference: https://github.com/risgk/digital-synth-pra32-u2 (pra32-u2-delay-fx.h)
  #
  # It keeps the bus's one unit without a limiter or a clip. What enters each loop is half its
  # input, plus its delayed signal at a feedback of at most a half, so as long as the delayed
  # signal is within one unit, so is what is written back -- and it starts at silence. The low
  # pass filter in the loop and the reading between two samples are weighted averages, which
  # cannot reach past what they average, and the output is a crossfade, which cannot either. The
  # price of the half is that the first repeat is 6 dB under the dry signal.
  #
  # The outputs are read after process, from output_l and output_r: returning both would build an
  # Array every sample. output_mono, a sub output, is the two averaged, for a mono destination.
  class Delay
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

    # The delay line, a power of two so that its index wraps with a mask: Ruby's % is a
    # floor-modulo, and sp_imod carries a sign correction the index can never need. It holds the longest delay at 48 kHz, 16320 samples, plus the older of
    # the two samples the interpolation reads; a higher sample rate would need it longer.
    # Reading reaches back 16384 samples at most, to the slot about to be written, which still
    # holds its oldest sample; a delay of 16384 or more would read back the newest one.
    # Array.new(16384, 0.0) grows by pushes to a capacity of 17407, 68 KB of floats, and on the
    # way there briefly holds the 34 KB it grew from as well. There is one for each side, 136 KB
    # in all, allocated one after the other, so the 34 KB is held only once at a time.
    DELAY_LINE_SIZE = 16384
    DELAY_LINE_MASK = DELAY_LINE_SIZE - 1

    # The Time dial, in samples at 48 kHz: a straight line from 0 at 0.0 to 16320 (340 ms) at 1.0,
    # 136 samples a CC step, clipped to 136 (2.83 ms) at the bottom. The bottom keeps the read clear
    # of the sample about to be written. The top is PRA32-U2's 340 ms, which fits the line above
    # with room left for the slew to overshoot by rounding; its clip only guards the line.
    FULL_SCALE_TIME_AT_48K = 16320.0
    MIN_TIME_AT_48K        = 136.0
    MAX_TIME_AT_48K        = 16320.0
    # How far the read position may move per sample while Time is turned, in samples: a quarter,
    # as PRA32-U2 allows. Moving it faster would read the line at many times its speed, which is
    # heard as noise; held to this, the repeats bend in pitch by at most 25%, as a tape delay's do,
    # and arrive at the new time a moment later.
    TIME_SLEW = 0.25

    attr_reader :output_l, :output_r

    # The average of the two sides, worked out when read, which the loop does every sample.
    def output_mono
      (@output_l + @output_r) * 0.5
    end

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
      @delay_line_l = Array.new(DELAY_LINE_SIZE, 0.0)
      @delay_line_r = Array.new(DELAY_LINE_SIZE, 0.0)
      # One write index for both lines, which are read at the same delay.
      @write_index = 0
      # The states of the low pass filters in the loops.
      @filtered_l = 0.0
      @filtered_r = 0.0

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

      @output_l = 0.0
      @output_r = 0.0
    end

    # Time is unipolar, [0.0, 1.0], read as 0 to 340 ms in a straight line and clipped to 2.83 ms
    # at the bottom.
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

    # Mix is unipolar, [0.0, 1.0], the delayed signal's share of each crossfade: the dry input at
    # 0.0, only the repeats at 1.0.
    def set_mix(mix)
      @mix = (mix < 0.0) ? 0.0 : ((mix > 1.0) ? 1.0 : mix)
    end

    def process(control_tick, audio_input_l = 0.0, audio_input_r = 0.0)
      if control_tick
        @stage_1_time = Dsp.smooth(@time, @stage_1_time, @smoothing_target_blend)
        @current_time = Dsp.smooth(@stage_1_time, @current_time, @smoothing_target_blend)
        @stage_1_feedback = Dsp.smooth(@feedback, @stage_1_feedback, @smoothing_target_blend)
        @current_feedback = Dsp.smooth(@stage_1_feedback, @current_feedback, @smoothing_target_blend)
        @stage_1_mix = Dsp.smooth(@mix, @stage_1_mix, @smoothing_target_blend)
        @current_mix = Dsp.smooth(@stage_1_mix, @current_mix, @smoothing_target_blend)

        # Where the read position should be by the next update, at most the slew away, and a
        # quarter of the way there each sample.
        target = @full_scale_time * @current_time
        target = (target < @min_time) ? @min_time : ((target > @max_time) ? @max_time : target)
        distance = target - @delay
        distance = (distance < @time_slew_down) ? @time_slew_down : ((distance > @time_slew_up) ? @time_slew_up : distance)
        @delay_step = distance * 0.25
      end

      # Held to the bus's one unit on the way in, as the amp holds its modulation input: the
      # bound each loop keeps is only as good as what enters it.
      input_l = (audio_input_l < -1.0) ? -1.0 : ((audio_input_l > 1.0) ? 1.0 : audio_input_l)
      input_r = (audio_input_r < -1.0) ? -1.0 : ((audio_input_r > 1.0) ? 1.0 : audio_input_r)

      @delay += @delay_step
      @write_index = (@write_index + 1) & DELAY_LINE_MASK
      # Read before this sample's write, from at least 136 samples back, so truncating the delay
      # is flooring it and neither sample read is the one about to be written. Both sides read at
      # the same places.
      whole = @delay.to_i
      fraction = @delay - whole.to_f
      newer_index = (@write_index - whole) & DELAY_LINE_MASK
      older_index = (@write_index - whole - 1) & DELAY_LINE_MASK
      newer_l = @delay_line_l[newer_index]
      older_l = @delay_line_l[older_index]
      delayed_l = newer_l + fraction * (older_l - newer_l)
      newer_r = @delay_line_r[newer_index]
      older_r = @delay_line_r[older_index]
      delayed_r = newer_r + fraction * (older_r - newer_r)

      # A gentle low pass in each loop, as PRA32-U2 has: 0.75 of what goes in and 0.25 of the last
      # value, so each repeat comes back a little darker than the one before.
      loop_input_l = input_l * 0.5 + delayed_l * @current_feedback
      @filtered_l = loop_input_l + (@filtered_l - loop_input_l) * 0.25
      @delay_line_l[@write_index] = @filtered_l
      loop_input_r = input_r * 0.5 + delayed_r * @current_feedback
      @filtered_r = loop_input_r + (@filtered_r - loop_input_r) * 0.25
      @delay_line_r[@write_index] = @filtered_r

      @output_l = input_l + (delayed_l - input_l) * @current_mix
      @output_r = input_r + (delayed_r - input_r) * @current_mix
    end
  end
end
