module Spms1
  # A 2nd-order Biquad Low-Pass Filter featuring interleaved coefficient updates,
  # dynamic cutoff modulation routing, and integrated soft-clipping distortion.
  class Filter
    # Configurable soft-clipping headroom ceiling
    SOFT_CLIP_CEILING = 8.0

    # A 4-sample grid implementation to maintain the original time constant
    SMOOTHING_TARGET_BLEND = 0.125

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

      # Internal counter to automatically handle the control block updates
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
      # Execute one step of the reconstructed 4-step interleaved coefficient calculation
      if @sample_counter == 0
        # Pass variables required for State 0 computation internally
        @current_modulation_input = modulation_input
        update_coefficients_interleaved
      end

      # Increment and mask the sample tracking counter (0 to 3 wrap around for 4-sample grid)
      @sample_counter = (@sample_counter + 1) & 3

      # Difference equation calculation (Transposed Direct Form II implementation)
      audio_output = @z1 + @b0 * audio_input
      @z1 = soft_clip(@z2 + @b1 * audio_input - @a1 * audio_output)
      @z2 = soft_clip(@b2 * audio_input - @a2 * audio_output)
      
      audio_output
    end

    private

    # Distributes the math of coefficient calculation over 4 sample frames to align perfectly 
    # with the 4-sample control grid and maintain steady processing scaling.
    def update_coefficients_interleaved
      case @interleave_state
      when 0
        # Calculate the dynamic combined cutoff value using base cutoff and scaled modulation input
        mod = (@current_modulation_input < 0.0) ? 0.0 : ((@current_modulation_input > 1.0) ? 1.0 : @current_modulation_input)
        total_cutoff = @cutoff + (mod * @modulation_amount)
        clamped_cutoff = (total_cutoff < 0.0) ? 0.0 : ((total_cutoff > 1.0) ? 1.0 : total_cutoff)

        # Smooth parameters over time to prevent audible zipper noise
        @current_cutoff += (clamped_cutoff - @current_cutoff) * SMOOTHING_TARGET_BLEND
        @current_resonance += (@resonance - @current_resonance) * SMOOTHING_TARGET_BLEND

        # Map normalized cutoff (0.00 - 1.00) to 10-octave pitch range scaled to absolute note numbers (15 - 135)
        internal_cutoff = @current_cutoff * 120.0 + 15.0

        # Convert internal log scale value to frequency in Hz using a standard 12-steps-per-octave reference
        cutoff_freq = 440.0 * (2.0 ** ((internal_cutoff - 69.0) * (1.0 / 12.0)))
        
        # Calculate angular frequency (omega)
        @step_omega = 2.0 * Math::PI * cutoff_freq / @sample_rate
      when 1
        # Map resonance to Q factor scale (base Q is 1 / sqrt(2) approx 0.707)
        internal_resonance = @current_resonance * 128.0
        
        # Convert internal log scale value to Q factor.
        base_q = 0.7071067811865476
        @step_q = base_q * (2.0 ** (internal_resonance * (1.0 / 32.0)))

        # Precompute trigonometric components simultaneously to prevent instruction drifting
        @step_sin_w = Math.sin(@step_omega)
        @step_cos_w = Math.cos(@step_omega)
      when 2
        # Calculate reciprocal of the denominator for division optimization
        step_inv_denom = 1.0 / ((2.0 * @step_q) + @step_sin_w)

        # Calculate b0 coefficient into the double-buffer
        @step_two_q = 2.0 * @step_q
        raw_b0 = (1.0 - @step_cos_w) * 0.5 * @step_two_q
        @next_b0 = raw_b0 * step_inv_denom
        @next_b1 = (1.0 - @step_cos_w) * @step_two_q * step_inv_denom
        @next_a1 = -4.0 * @step_cos_w * @step_q * step_inv_denom
        @next_a2 = (@step_two_q - @step_sin_w) * step_inv_denom
      else
        # State 3: Atomically swap active coefficients with the newly calculated ones
        @b0 = @next_b0
        @b1 = @next_b1
        @b2 = @next_b0 # Low-pass Biquad assumes b2 equals b0
        @a1 = @next_a1
        @a2 = @next_a2
      end

      # Increment state and wrap around using bitwise AND (0 to 3 for 4-step sequence)
      @interleave_state = (@interleave_state + 1) & 3
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
