module Spms1
  # Mono-in, stereo-out chorus, after PRA32-U2's Chorus FX: one audio input, two outputs, each a
  # crossfade of the dry input with a tap of one short delay line. It is an insert, as Delay 1 is:
  # Mix sets the balance of the two, rather than a send level. A triangle LFO swings the two taps
  # in opposite directions about a fixed delay, so the left and right outputs bend in pitch against
  # each other, and a mono source comes out spread across the stereo field.
  # Reference: https://github.com/risgk/digital-synth-pra32-u2 (pra32-u2-chorus-fx.h)
  #
  # It keeps the bus's one unit without a limiter or a clip: the input is held to one unit on the
  # way in, and the low pass filter in front of the line, the reading between two samples and the
  # crossfade are all weighted averages, which cannot reach past what they average.
  #
  # The outputs are read after process, from output_l and output_r: returning both would build an
  # Array every sample.
  class Chorus
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
    # the counter above. It holds the longest delay at 48 kHz, 508 samples, plus the older of the
    # two samples the interpolation reads; a higher sample rate would need it longer. One line
    # serves both taps, since the input is mono.
    DELAY_LINE_SIZE = 512
    DELAY_LINE_MASK = DELAY_LINE_SIZE - 1

    # The delay the taps swing about, in samples at 48 kHz: 5.33 ms, PRA32-U2's Chorus Delay Time
    # at its default, which PRA32-U2 keeps internal as well.
    BASE_TIME_AT_48K = 256.0
    # How far each tap swings at the top of Depth, in samples at 48 kHz: 5.25 ms, PRA32-U2's at
    # Chorus Depth 126. It stays 4 samples short of the base, so the nearer tap never reaches the
    # sample about to be written.
    FULL_SCALE_DEPTH_AT_48K = 252.0

    # Rate lookup table, one entry per semitone, so the dial is linear in pitch as LFO 1 Rate's is:
    # 0.015 Hz at 0.0, 0.48 Hz at 0.5 (PRA32-U2's Chorus Rate at its default), 15.4 Hz at 1.0:
    # the default divided by 32 at the bottom and multiplied by 32 at the top.
    # 122 entries so that a rate of 1.0 still has an entry above it to interpolate against.
    FREQ_TABLE = Array.new(122, 0.0)
    for i in 0...122
      FREQ_TABLE[i] = 0.48 * (2.0 ** ((i.to_f - 60.0) * (1.0 / 12.0)))
    end

    attr_reader :output_l, :output_r

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      # The LFO advances once per control-rate update, so its increment is per update, not per
      # sample.
      @inv_control_rate = CONTROL_RATE_DIVISOR.to_f / sample_rate
      @base_time = BASE_TIME_AT_48K * (@sample_rate / 48000.0)
      @full_scale_depth = FULL_SCALE_DEPTH_AT_48K * (@sample_rate / 48000.0)
      @delay_line = Array.new(DELAY_LINE_SIZE, 0.0)
      @write_index = 0
      # The state of the low pass filter in front of the line.
      @filtered = 0.0

      # Each parameter starts where its control does at power-on, so nothing slides up to it.
      @rate = 0.5
      @stage_1_rate = 0.5
      @current_rate = 0.5
      @depth = 0.5
      @stage_1_depth = 0.5
      @current_depth = 0.5
      @mix = 0.5
      @stage_1_mix = 0.5
      @current_mix = 0.5

      @phase = 0.0
      # The delay each tap is read at, in samples, moved a step every sample so that it arrives at
      # each control-rate update's value on time. Both start at the base, where the LFO starts.
      @delay_l = @base_time
      @delay_r = @base_time
      @delay_step_l = 0.0
      @delay_step_r = 0.0
      @sample_counter = 0

      @output_l = 0.0
      @output_r = 0.0
    end

    # Rate is unipolar, [0.0, 1.0], and read as a note number: 0.015 Hz at 0.0, 0.48 Hz at 0.5,
    # 15.4 Hz at 1.0.
    def set_rate(rate)
      @rate = (rate < 0.0) ? 0.0 : ((rate > 1.0) ? 1.0 : rate)
    end

    # Depth is unipolar, [0.0, 1.0], how far each tap swings either side of 5.33 ms: not at all at
    # 0.0, 2.63 ms at 0.5, 5.25 ms at 1.0.
    def set_depth(depth)
      @depth = (depth < 0.0) ? 0.0 : ((depth > 1.0) ? 1.0 : depth)
    end

    # Mix is unipolar, [0.0, 1.0], the delayed signal's share of each crossfade: the dry input at
    # 0.0, half and half at 0.5, which is the chorus PRA32-U2 makes at full Chorus Level, and only
    # the delayed signal at 1.0, a vibrato apart on the two sides.
    def set_mix(mix)
      @mix = (mix < 0.0) ? 0.0 : ((mix > 1.0) ? 1.0 : mix)
    end

    def process(audio_input = 0.0)
      if @sample_counter == 0
        @stage_1_rate = Dsp.smooth(@rate, @stage_1_rate, @smoothing_target_blend)
        @current_rate = Dsp.smooth(@stage_1_rate, @current_rate, @smoothing_target_blend)
        @stage_1_depth = Dsp.smooth(@depth, @stage_1_depth, @smoothing_target_blend)
        @current_depth = Dsp.smooth(@stage_1_depth, @current_depth, @smoothing_target_blend)
        @stage_1_mix = Dsp.smooth(@mix, @stage_1_mix, @smoothing_target_blend)
        @current_mix = Dsp.smooth(@stage_1_mix, @current_mix, @smoothing_target_blend)

        # A triangle, -1.0 to 1.0, folded out of the phase ramp as LFO 1's is, with the same
        # quarter-turn shift so that it starts from 0.0, where both taps already are.
        shifted = @phase + 0.25
        shifted -= (shifted < 1.0) ? 0.0 : 1.0
        distance = shifted - 0.5
        triangle = 1.0 - 4.0 * distance.abs
        @phase += rate_to_freq_fast(@current_rate) * @inv_control_rate
        @phase -= (@phase < 1.0) ? 0.0 : 1.0

        # Where each tap should be by the next update, the two on opposite sides of the base, and
        # a quarter of the way there each sample. Interpolated rather than stepped, since a read
        # position held for the interval and then moved would modulate the delayed signal's phase
        # at the control rate.
        swing = triangle * @current_depth * @full_scale_depth
        @delay_step_l = (@base_time - swing - @delay_l) * 0.25
        @delay_step_r = (@base_time + swing - @delay_r) * 0.25
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK

      # Held to the bus's one unit on the way in, as the delay holds its inputs.
      input = (audio_input < -1.0) ? -1.0 : ((audio_input > 1.0) ? 1.0 : audio_input)

      @delay_l += @delay_step_l
      @delay_r += @delay_step_r
      @write_index = (@write_index + 1) & DELAY_LINE_MASK
      # Read before this sample's write, from at least 4 samples back, so truncating a delay is
      # flooring it and neither sample read is the one about to be written.
      whole_l = @delay_l.to_i
      fraction_l = @delay_l - whole_l.to_f
      newer_l = @delay_line[(@write_index - whole_l) & DELAY_LINE_MASK]
      older_l = @delay_line[(@write_index - whole_l - 1) & DELAY_LINE_MASK]
      delayed_l = newer_l + fraction_l * (older_l - newer_l)
      whole_r = @delay_r.to_i
      fraction_r = @delay_r - whole_r.to_f
      newer_r = @delay_line[(@write_index - whole_r) & DELAY_LINE_MASK]
      older_r = @delay_line[(@write_index - whole_r - 1) & DELAY_LINE_MASK]
      delayed_r = newer_r + fraction_r * (older_r - newer_r)

      # A gentle low pass in front of the line, as PRA32-U2 has: 0.75 of what goes in and 0.25 of
      # the last value, which takes the edge off the delayed signal alone.
      @filtered = input + (@filtered - input) * 0.25
      @delay_line[@write_index] = @filtered

      @output_l = input + (delayed_l - input) * @current_mix
      @output_r = input + (delayed_r - input) * @current_mix
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
