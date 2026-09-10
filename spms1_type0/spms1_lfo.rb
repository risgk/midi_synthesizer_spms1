module Spms1
  # Triangle LFO. Deliberately not band-limited: a triangle's harmonics fall off as 1/n^2, so even
  # at the top of the rate range what folds back stays far below the fundamental.
  class LFO
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
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
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @phase = 0.0
      # Middle of the range, so the LFO starts where its control does rather than sliding up to it.
      @rate = 0.5
      @current_rate = 0.5
      # Not derived here: process assigns it on its first call, before anything reads it.
      @dt = 0.0
      @sample_counter = 0
    end

    # Rate is normalized to [0.0, 1.0] and read as a note number, so the dial is linear in pitch:
    # 0.215 Hz at 0.0, 6.875 Hz at 0.5, 220 Hz at 1.0.
    def set_rate(rate)
      @rate = (rate < 0.0) ? 0.0 : ((rate > 1.0) ? 1.0 : rate)
    end

    # Output is bipolar and spans one unit peak to peak, [-0.5, 0.5], the same span as the pitch
    # domain. Every bipolar signal on the bus is scaled that way, so a destination's amount control
    # means the same thing whichever one is routed to it.
    def process
      if @sample_counter == 0
        # Rate is smoothed at the control rate to avoid sudden jumps, and the phase increment is
        # derived here rather than per sample: nothing feeds this module, so it cannot change
        # between control-rate updates.
        @current_rate += (@rate - @current_rate) * @smoothing_target_blend
        @dt = rate_to_freq_fast(@current_rate) * @inv_sample_rate
      end

      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      # Triangle folded out of the phase ramp. The quarter-turn shift puts 0.0 at the start of the
      # cycle, so a destination sees the LFO leave its unmodulated value rather than jump off it.
      shifted = @phase + 0.25
      shifted -= (shifted < 1.0) ? 0.0 : 1.0
      distance = shifted - 0.5
      folded = (distance < 0.0) ? -distance : distance
      output = 0.5 - (2.0 * folded)

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
