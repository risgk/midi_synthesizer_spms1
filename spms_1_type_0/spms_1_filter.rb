module Spms1
  # A 2nd-order Biquad Low-Pass Filter featuring interleaved coefficient updates,
  # dynamic cutoff modulation routing, and integrated soft-clipping distortion.
  class Filter
    # Configurable soft-clipping headroom ceiling
    SOFT_CLIP_CEILING = 8.0

    # Smoothing coefficient optimized for the 8-sample gated control rate grid
    # to maintain a steady ~5.3ms parameter tracking lag time (95% settled)
    SMOOTHING_TARGET_BLEND = 0.0625

    def initialize
      @sample_rate = 48000.0
      @cutoff = 1.0
      @resonance = 0.0

      # Modulation amount to scale the incoming modulation signal (-1.0 to 1.0)
      @modulation_amount = 0.0

      # Target values for parameter smoothing (One-pole low-pass filter)
      @current_cutoff = 1.0
      @current_resonance = 0.0

      # Filter coefficients and internal state variables (Transposed Direct Form II)
      @b0 = 1.0; @b1 = 0.0; @b2 = 0.0
      @a1 = 0.0; @a2 = 0.0
      @z1 = 0.0; @z2 = 0.0 # Uses exactly two delay registers (state variables)

      # Interleaving state and double buffers for coefficients
      @interleave_state = 0
      @next_b0 = 1.0
      @next_b1 = 0.0
      @next_a1 = 0.0
      @next_a2 = 0.0

      # Internal counter to automatically handle the 8-sample control block updates
      @sample_counter = 0

      update_coefficients_interleaved
    end

    # Sets the system sample rate and forces a coefficient recalculation.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 48000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
      update_coefficients_interleaved
    end

    # Sets the target base cutoff frequency.
    # @param cutoff [Float] Normalized cutoff value between 0.0 and 1.0
    def set_cutoff(cutoff)
      @cutoff = (cutoff < 0.0) ? 0.0 : ((cutoff > 1.0) ? 1.0 : cutoff)
    end

    # Sets the cutoff modulation depth amount.
    # @param amount [Float] Normalized modulation depth from -1.0 to 1.0
    def set_modulation_amount(amount)
      @modulation_amount = (amount < -1.0) ? -1.0 : ((amount > 1.0) ? 1.0 : amount)
    end

    # Sets the target resonance.
    # @param resonance [Float] Normalized resonance value between 0.0 and 1.0
    def set_resonance(resonance)
      @resonance = (resonance < 0.0) ? 0.0 : ((resonance > 1.0) ? 1.0 : resonance)
    end

    # Processes a single audio sample (1 frame).
    # @param audio_input [Float] Input sample value
    # @param modulation_input [Float] Control signal from an EG or LFO (typically 0.0 to 1.0)
    # @return [Float] Filtered and soft-clipped output sample
    def process(audio_input = 0.0, modulation_input = 0.0)
      # Synchronize parameter smoothing routines onto the internal 8-sample step boundary
      if @sample_counter == 0
        # Calculate the dynamic combined cutoff value using base cutoff and scaled modulation input
        mod = (modulation_input < 0.0) ? 0.0 : ((modulation_input > 1.0) ? 1.0 : modulation_input)
        total_cutoff = @cutoff + (mod * @modulation_amount)
        clamped_cutoff = (total_cutoff < 0.0) ? 0.0 : ((total_cutoff > 1.0) ? 1.0 : total_cutoff)

        # Smooth parameters over time to prevent audible zipper noise
        @current_cutoff += (clamped_cutoff - @current_cutoff) * SMOOTHING_TARGET_BLEND
        @current_resonance += (@resonance - @current_resonance) * SMOOTHING_TARGET_BLEND

        # Execute one step of the interleaved coefficient calculation
        update_coefficients_interleaved
      end

      # Increment and mask the sample tracking counter (0 to 7 wrap around)
      @sample_counter = (@sample_counter + 1) & 7

      # Difference equation calculation (Transposed Direct Form II implementation)
      audio_output = @z1 + @b0 * audio_input
      @z1 = soft_clip(@z2 + @b1 * audio_input - @a1 * audio_output)
      @z2 = soft_clip(@b2 * audio_input - @a2 * audio_output)
      
      audio_output
    end

    private

    # Distributes the heavy math of coefficient calculation over 8 sample frames.
    # This process is internally gated to run once every 8 frames to prevent CPU spikes 
    # caused by calling Math.sin, Math.cos, or 2.0 ** x on every consecutive frame.
    def update_coefficients_interleaved
      case @interleave_state
      when 0
        # Map normalized cutoff (0.00 - 1.00) to 10-octave pitch range scaled to absolute note numbers (15 - 135)
        @internal_cutoff = @current_cutoff * 120.0 + 15.0
      when 1
        # Convert internal log scale value to frequency in Hz using a standard 12-steps-per-octave reference
        # (where internal note number 69 maps exactly to 440 Hz). Tuning profile:
        # - Min (0.00) : ~19.5 Hz  (equiv. to note number 15)
        # - Mid (0.50) : ~622 Hz   (equiv. to note number 75)
        # - Max (1.00) : ~19.9 kHz (equiv. to note number 135)
        cutoff_freq = 440.0 * (2.0 ** ((@internal_cutoff - 69.0) * (1.0 / 12.0)))
        
        # Calculate angular frequency (omega)
        @step_omega = 2.0 * Math::PI * cutoff_freq / @sample_rate
      when 2
        # Map resonance to Q factor scale (base Q is 1 / sqrt(2) approx 0.707)
        # Scale adjusted to 128.0 to maintain original maximum peak at CC 127 input (127/128 * 128 = 127.0)
        @internal_resonance = @current_resonance * 128.0
        
        # Convert internal log scale value to Q factor.
        # 32 steps per octave ideal scaling profile:
        # - Min (0.00) : ~0.707 (Butterworth filter alignment)
        # - Q1  (0.25) : ~1.414 (+6dB resonance peak)
        # - Mid (0.50) : ~2.828 (+12dB resonance peak)
        # - Q3  (0.75) : ~5.657 (+18dB resonance peak)
        # - Max (1.00) : ~11.311 (approx +24dB resonance peak)
        base_q = 0.7071067811865476
        @step_q = base_q * (2.0 ** (@internal_resonance * (1.0 / 32.0)))
      when 3
        # Precompute trigonometric components
        @step_sin_w = Math.sin(@step_omega)
        @step_cos_w = Math.cos(@step_omega)
      when 4
        # Calculate reciprocal of the denominator for division optimization
        @step_inv_denom = 1.0 / ((2.0 * @step_q) + @step_sin_w)
      when 5
        # Calculate b0 coefficient into the double-buffer
        @step_two_q = 2.0 * @step_q
        raw_b0 = (1.0 - @step_cos_w) * 0.5 * @step_two_q
        @next_b0 = raw_b0 * @step_inv_denom
      when 6
        # Calculate b1, a1, and a2 coefficients into the double-buffer
        @next_b1 = (1.0 - @step_cos_w) * @step_two_q * @step_inv_denom
        @next_a1 = -4.0 * @step_cos_w * @step_q * @step_inv_denom
        @next_a2 = (@step_two_q - @step_sin_w) * @step_inv_denom
      else
        # State 7: Atomically swap active coefficients with the newly calculated ones
        @b0 = @next_b0
        @b1 = @next_b1
        @b2 = @next_b0 # Low-pass Biquad assumes b2 equals b0
        @a1 = @next_a1
        @a2 = @next_a2
      end

      # Increment state and wrap around using bitwise AND (0 to 7)
      @interleave_state = (@interleave_state + 1) & 7
    end

    # Applies a cubic non-linear soft-clipping function tailored for a configurable range.
    # Adds warm analog-like saturation and prevents internal state blow-ups.
    # Note: No oversampling is performed here; however, as long as the inputs are well-behaved,
    # aliasing noise remains minimal within the dynamic range of the synthesis core.
    # @param sample [Float] Internal state or feedback signal
    # @return [Float] Saturated signal
    def soft_clip(sample)
      if sample > SOFT_CLIP_CEILING
        (2.0 / 3.0) * SOFT_CLIP_CEILING
      elsif sample < -SOFT_CLIP_CEILING
        -(2.0 / 3.0) * SOFT_CLIP_CEILING
      else
        # Cubic curve implementation: x - (x^3 / 3) normalized for the active headroom ceiling
        sample - 
          ((sample * (1.0 / SOFT_CLIP_CEILING)) * 
           (sample * (1.0 / SOFT_CLIP_CEILING)) * 
           (sample * (1.0 / SOFT_CLIP_CEILING))) * (1.0 / 3.0) * SOFT_CLIP_CEILING
      end
    end
  end
end
