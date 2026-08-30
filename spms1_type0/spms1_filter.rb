module Spms1
  # Nonlinear biquad low-pass filter with modulation and soft clipping.
  # This implementation is not oversampled; the nonlinear behavior is kept intentionally simple.
  # Reference: https://jatinchowdhury18.medium.com/complex-nonlinearities-episode-4-nonlinear-biquad-filters-ae6b3f23cb0e
  # Coefficient updates are distributed across a 4-sample grid to preserve stability without a full oversampling path.
  class Filter
    SOFT_CLIP_CEILING = 1.5
    SMOOTHING_TARGET_BLEND_BASE = 0.015625

    # Resonance-to-Q lookup for fast filter coefficient updates.
    Q_TABLE = Array.new(130, 0.0)
    BASE_Q = 0.7071067811865476
    for i in 0...129
      Q_TABLE[i] = BASE_Q * (2.0 ** (i.to_f * (1.0 / 32.0)))
    end
    Q_TABLE[129] = Q_TABLE[128]

    def initialize(sample_rate)
      @sample_rate = sample_rate
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (96000.0 / @sample_rate)
      @cutoff = 1.0
      @resonance = 0.0
      @modulation_amount = 0.0

      @current_cutoff = 1.0
      @current_resonance = 0.0
      @current_modulation_amount = 0.0

      @b0 = 1.0; @b1 = 0.0; @b2 = 0.0
      @a1 = 0.0; @a2 = 0.0
      @z1 = 0.0; @z2 = 0.0

      @interleave_state = 0
      @next_b0 = 1.0
      @next_b1 = 0.0
      @next_a1 = 0.0
      @next_a2 = 0.0

      @current_modulation_input = 0.0
      @sample_counter = 0

      @interleave_state = 0
      4.times do
        update_coefficients_interleaved
      end
    end

    # Cutoff and resonance use normalized values in [0.0, 1.0].
    # Cutoff range: MIDI note 15 (19 Hz) at 0.0, MIDI note 75 (622 Hz) at 0.5, MIDI note 135 (20 kHz) at 1.0.
    def set_cutoff(cutoff)
      @cutoff = (cutoff < 0.0) ? 0.0 : ((cutoff > 1.0) ? 1.0 : cutoff)
    end

    # Modulation depth is normalized to [-1.0, 1.0].
    def set_modulation_amount(amount)
      @modulation_amount = (amount < -1.0) ? -1.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    def set_resonance(resonance)
      # Q range: ~0.7 (0.0), ~2.83 (0.5), ~11.3 (1.0).
      @resonance = (resonance < 0.0) ? 0.0 : ((resonance > 1.0) ? 1.0 : resonance)
    end

    def process(audio_input = 0.0, modulation_input = 0.0)
      @current_modulation_input = modulation_input
      update_coefficients_interleaved

      @sample_counter = (@sample_counter + 1) & 3

      audio_output = @z1 + @b0 * audio_input
      @z1 = soft_clip(@z2 + @b1 * audio_input - @a1 * audio_output)
      @z2 = soft_clip(@b2 * audio_input - @a2 * audio_output)

      audio_output
    end

    private

    # Split coefficient updates across four samples to keep the control-rate grid stable.
    def update_coefficients_interleaved
      case @interleave_state
      when 0
        @current_cutoff += (@cutoff - @current_cutoff) * @smoothing_target_blend
        @current_resonance += (@resonance - @current_resonance) * @smoothing_target_blend
        @current_modulation_amount += (@modulation_amount - @current_modulation_amount) * @smoothing_target_blend

        mod = (@current_modulation_input < 0.0) ? 0.0 : ((@current_modulation_input > 1.0) ? 1.0 : @current_modulation_input)
        total_cutoff = @current_cutoff + (mod * @current_modulation_amount)
        clamped_cutoff = (total_cutoff < 0.0) ? 0.0 : ((total_cutoff > 1.0) ? 1.0 : total_cutoff)

        internal_cutoff = clamped_cutoff * 120.0 + 15.0
        cutoff_freq = 440.0 * (2.0 ** ((internal_cutoff - 69.0) * (1.0 / 12.0)))
        @step_omega = 2.0 * Math::PI * cutoff_freq / @sample_rate
      when 1
        internal_resonance = @current_resonance * 128.0

        index = internal_resonance.to_i
        fraction = internal_resonance - index.to_f

        q0 = Q_TABLE[index]
        q1 = Q_TABLE[index + 1]

        @step_q = q0 + fraction * (q1 - q0)
        @step_sin_w = Math.sin(@step_omega)
        @step_cos_w = Math.cos(@step_omega)
      when 2
        step_inv_denom = 1.0 / ((2.0 * @step_q) + @step_sin_w)

        @step_two_q = 2.0 * @step_q
        raw_b0 = (1.0 - @step_cos_w) * 0.5 * @step_two_q
        @next_b0 = raw_b0 * step_inv_denom
        @next_b1 = (1.0 - @step_cos_w) * @step_two_q * step_inv_denom
        @next_a1 = -4.0 * @step_cos_w * @step_q * step_inv_denom
        @next_a2 = (@step_two_q - @step_sin_w) * step_inv_denom
      else
        @b0 = @next_b0
        @b1 = @next_b1
        @b2 = @next_b0
        @a1 = @next_a1
        @a2 = @next_a2
      end

      @interleave_state = (@interleave_state + 1) & 3
    end

    # Applies a cubic non-linear soft-clipping function tailored for a configurable range.
    # Adds warm analog-like saturation and prevents internal state blow-ups.
    def soft_clip(sample)
      if sample > SOFT_CLIP_CEILING
        (2.0 / 3.0) * SOFT_CLIP_CEILING
      elsif sample < -SOFT_CLIP_CEILING
        -(2.0 / 3.0) * SOFT_CLIP_CEILING
      else
        sample -
          ((sample * (1.0 / SOFT_CLIP_CEILING)) *
           (sample * (1.0 / SOFT_CLIP_CEILING)) *
           (sample * (1.0 / SOFT_CLIP_CEILING))) * (1.0 / 3.0) * SOFT_CLIP_CEILING
      end
    end
  end
end
