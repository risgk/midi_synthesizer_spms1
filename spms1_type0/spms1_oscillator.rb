module Spms1
  # PolyBLEP-based saw/square morph oscillator for anti-aliased waveform transitions.
  class Oscillator
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Number of samples between control-rate updates; smoothing speed is kept approximately constant if this is changed.
    CONTROL_RATE_DIVISOR = 4
    # Level this oscillator's output is mixed in at. Kept here so the level stays tied to this
    # oscillator specifically, not to whichever module happens to read its output. May move to a
    # dedicated oscillator mixer later.
    OUTPUT_LEVEL = 0.5
    # What a modulation depth of 1.0 is worth: all 120 semitones the pitch domain spans, so a
    # full-scale signal can drive the pitch from either end of the range to the other, whatever note
    # it started from.
    MODULATION_RANGE = 120.0 / 120.0

    # Pitch lookup table for note-to-frequency conversion.
    FREQ_TABLE = Array.new(129, 0.0)
    for i in 0...129
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 69.0) * (1.0 / 12.0)))
    end

    def initialize(sample_rate)
      @sample_rate = sample_rate
      # Reciprocal kept alongside the rate so process multiplies rather than divides. @sample_rate
      # is an Integer, so dividing by it in the per-sample path also costs an int-to-float
      # conversion on top of the division.
      @inv_sample_rate = 1.0 / sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @phase = 0.0
      @waveform = 0.0
      @current_waveform = 0.0
      @modulation_amount = 0.0
      @current_modulation_amount = 0.0
      @sample_counter = 0
    end

    # Waveform morph is normalized to [0.0, 1.0].
    # 0.0 = sawtooth, 0.5 = 50% morph, 1.0 = square.
    def set_waveform(waveform)
      @waveform = (waveform < 0.0) ? 0.0 : ((waveform > 1.0) ? 1.0 : waveform)
    end

    # Modulation depth is normalized to [0.0, 1.0]. Squared and scaled here rather than per sample,
    # so the smoothed value is already in pitch units. Squared because the useful depths are the
    # small ones: linear across the range would make a 7-bit step a whole semitone, far too coarse
    # for vibrato, where squared keeps the bottom of the dial under a fifth of one.
    def set_modulation_amount(amount)
      clamped_amount = (amount < 0.0) ? 0.0 : ((amount > 1.0) ? 1.0 : amount)
      @modulation_amount = clamped_amount * clamped_amount * MODULATION_RANGE
    end

    # Pitch input is a signal in [-1.0, 1.0], of which [-0.5, 0.5] is the usable span: it covers
    # MIDI notes 0 to 120, and anything beyond clamps to the ends. modulation_input is added to it
    # per sample and is deliberately not smoothed, so a fast source reaches the pitch unslewed.
    def process(pitch_input = 0.0, modulation_input = 0.0)
      if @sample_counter == 0
        # Morph and depth are smoothed at the control rate to avoid sudden jumps.
        @current_waveform += (@waveform - @current_waveform) * @smoothing_target_blend
        @current_modulation_amount += (@modulation_amount - @current_modulation_amount) * @smoothing_target_blend
      end

      mod = (modulation_input < -1.0) ? -1.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
      total_pitch = pitch_input + (mod * @current_modulation_amount)
      pitch = (total_pitch < -0.5) ? -0.5 : ((total_pitch > 0.5) ? 0.5 : total_pitch)
      freq = pitch_to_freq_fast(pitch)
      current_dt = freq * @inv_sample_rate
      # Both poly_blep calls below work against this same dt, so its reciprocal is taken once here
      # and passed in, rather than dividing twice inside each call.
      current_dt_inv = 1.0 / current_dt

      naive_saw1 = -2.0 * @phase + 1.0
      blep1 = poly_blep(@phase, current_dt, current_dt_inv)
      saw1 = naive_saw1 + blep1

      phase2 = @phase + 0.5
      phase2 -= (phase2 < 1.0) ? 0.0 : 1.0

      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt, current_dt_inv)
      saw2 = naive_saw2 + blep2

      output = saw1 - (saw2 * @current_waveform)
      @phase += current_dt
      @phase -= (@phase < 1.0) ? 0.0 : 1.0
      @sample_counter = (@sample_counter + 1) % CONTROL_RATE_DIVISOR

      output * 0.5 * OUTPUT_LEVEL
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
    # dt_inv (1.0 / dt) comes from the caller so this multiplies instead of dividing; see process.
    # Both corrections are evaluated unconditionally -- the comparisons only select between them
    # -- so the cost per sample is the same whether or not the phase is near a wrap.
    def poly_blep(t, dt, dt_inv)
      num_start = t * dt_inv
      blep_start = num_start + num_start - num_start * num_start - 1.0
      num_end = (t - 1.0) * dt_inv
      blep_end = num_end * num_end + num_end + num_end + 1.0
      val = (t < dt) ? blep_start : 0.0
      (t > 1.0 - dt) ? blep_end : val
    end
  end
end
