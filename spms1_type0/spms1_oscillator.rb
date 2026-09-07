module Spms1
  # PolyBLEP-based saw/square morph oscillator for anti-aliased waveform transitions.
  class Oscillator
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    CONTROL_RATE_DIVISOR = 4

    # Pitch lookup table for note-to-frequency conversion.
    FREQ_TABLE = Array.new(129, 0.0)
    for i in 0...129
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 69.0) * (1.0 / 12.0)))
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @phase = 0.0
      @waveform = 0.0
      @current_waveform = 0.0
      @sample_counter = 0
    end

    # Waveform morph is normalized to [0.0, 1.0].
    # 0.0 = sawtooth, 0.5 = 50% morph, 1.0 = square.
    def set_waveform(waveform)
      @waveform = (waveform < 0.0) ? 0.0 : ((waveform > 1.0) ? 1.0 : waveform)
    end

    # Pitch input is normalized to [-0.5, 0.5], corresponding to MIDI notes 0 to 120.
    def process(pitch_input = 0.0)
      pitch = (pitch_input < -0.5) ? -0.5 : ((pitch_input > 0.5) ? 0.5 : pitch_input)
      freq = pitch_to_freq_fast(pitch)
      current_dt = freq / @sample_rate

      naive_saw1 = -2.0 * @phase + 1.0
      blep1 = poly_blep(@phase, current_dt)
      saw1 = naive_saw1 + blep1

      phase2 = @phase + 0.5
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt)
      saw2 = naive_saw2 + blep2

      if @sample_counter == 0
        # Morph is smoothed at the control rate to avoid sudden waveform jumps.
        @current_waveform += (@waveform - @current_waveform) * @smoothing_target_blend
      end

      output = saw1 - (saw2 * @current_waveform)
      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0
      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      output * 0.5
    end

    private

    def pitch_to_freq_fast(pitch)
      internal_pitch = (pitch + 0.5) * 120.0
      index = internal_pitch.to_i
      fraction = internal_pitch - index.to_f
      f0 = FREQ_TABLE[index]
      f1 = FREQ_TABLE[index + 1]
      f0 + fraction * (f1 - f0)
    end

    # PolyBLEP correction for discontinuity smoothing at the waveform wrap point.
    def poly_blep(t, dt)
      num_start = t / dt
      blep_start = num_start + num_start - num_start * num_start - 1.0
      num_end = (t - 1.0) / dt
      blep_end = num_end * num_end + num_end + num_end + 1.0
      val = (t < dt) ? blep_start : 0.0
      (t > 1.0 - dt) ? blep_end : val
    end
  end
end
