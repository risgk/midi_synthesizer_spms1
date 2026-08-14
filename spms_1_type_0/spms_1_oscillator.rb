module Spms1
  # A band-limited oscillator supporting Sawtooth-to-Square waveform morphing
  # by summing/subtracting two phase-shifted Sawtooth waves with PolyBLEP anti-aliasing.
  class Oscillator
    # Promoted lookup table to a Class Constant to unlock compiler optimizations.
    # This allows the Spinel AOT compiler to pre-allocate memory and generate high-speed static arrays.
    FREQ_TABLE = Array.new(129, 0.0)
    for i in 0...129
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 69.0) * (1.0 / 12.0)))
    end

    def initialize
      @sample_rate = 48000.0
      @phase = 0.0 # Normalized phase accumulator (0.0 to 1.0)
      
      # Continuous morph control: 0.0 = pure Sawtooth, 1.0 = pure Square
      @waveform = 0.0
    end

    # Sets the system sample rate.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 48000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
    end

    # Sets the oscillator waveform morph amount.
    # @param value [Float] Normalized input value from 0.0 to 1.0
    def set_waveform(value)
      @waveform = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    # Processes a single audio sample (1 frame) based on pitch input.
    # @param pitch_input [Float] Normalized pitch value (typically around -0.5 to 0.5)
    # @return [Float] Anti-aliased morphing output sample scaled to approx +/-0.5 range
    def process(pitch_input = 0.0)
      # Clamp input pitch to designated bounds (-0.5 to 0.5)
      pitch = (pitch_input < -0.5) ? -0.5 : ((pitch_input > 0.5) ? 0.5 : pitch_input)
      
      # Convert pitch to frequency via fast lookup table interpolation
      freq = pitch_to_freq_fast(pitch)
      
      # Calculate phase increment per sample
      current_dt = freq / @sample_rate

      # --- First Sawtooth Wave (Base Phase) ---
      naive_saw1 = -2.0 * @phase + 1.0
      blep1 = poly_blep(@phase, current_dt)
      saw1 = naive_saw1 + blep1

      # --- Second Sawtooth Wave (Shifted by 180 degrees / 0.5 Phase) ---
      phase2 = @phase + 0.5
      phase2 -= 1.0 if phase2 >= 1.0
      
      naive_saw2 = -2.0 * phase2 + 1.0
      blep2 = poly_blep(phase2, current_dt)
      saw2 = naive_saw2 + blep2

      # --- Waveform Morphing ---
      # Subtracting the second shifted saw from the first saw yields a square wave.
      # Morphing from Saw to Square by interpolating the gain of the second saw.
      output = saw1 - (saw2 * @waveform)

      # Increment and wrap the phase accumulator
      @phase += current_dt
      @phase -= 1.0 if @phase >= 1.0

      # Scale down amplitude to prevent clipping in downstream modules
      # Adjusting gain scaling slightly based on morph state to maintain steady perceived volume
      output * 0.5
    end

    private

    # Performs high-speed conversion from normalized pitch to frequency
    # using linear interpolation between precomputed table indices.
    def pitch_to_freq_fast(pitch)
      # Map [-0.5, 0.5] range to MIDI note range [0.0, 120.0]
      midi_pitch = (pitch + 0.5) * 120.0
      index = midi_pitch.to_i
      fraction = midi_pitch - index.to_f
      
      f0 = FREQ_TABLE[index]
      f1 = FREQ_TABLE[index + 1]
      
      # Linear interpolation: f0 + fraction * (f1 - f0)
      f0 + fraction * (f1 - f0)
    end

    # Computes the 1st-order PolyBLEP residual to smooth out sharp discontinuities.
    # @param t [Float] Current phase
    # @param dt [Float] Phase increment
    # @return [Float] Correction value (0.0 if not near a transition)
    def poly_blep(t, dt)
      if t < dt
        # Discontinuity is just ahead / occurring at the boundary
        num = t / dt
        num + num - num * num - 1.0
      elsif t > 1.0 - dt
        # Discontinuity has just passed the boundary
        num = (t - 1.0) / dt
        num * num + num + num + 1.0
      else
        # No sharp transition within this sample frame
        0.0
      end
    end
  end
end
