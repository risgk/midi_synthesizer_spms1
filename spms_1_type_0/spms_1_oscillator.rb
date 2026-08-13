module Spms1
  # A band-limited oscillator supporting Sawtooth and Square waveforms
  # using PolyBLEP (Polynomial Band-Limited Step) to mitigate aliasing.
  class Oscillator
    SAW = 0
    SQUARE = 1

    # Promoted lookup table to a Class Constant to unlock compiler optimizations.
    # This allows the Spinel AOT compiler to pre-allocate memory and generate high-speed static arrays.
    FREQ_TABLE = Array.new(129, 0.0)
    for i in 0...129
      FREQ_TABLE[i] = 440.0 * (2.0 ** ((i.to_f - 69.0) * (1.0 / 12.0)))
    end

    def initialize
      @sample_rate = 48000.0
      @phase = 0.0 # Normalized phase accumulator (0.0 to 1.0)
      @waveform = SAW
    end

    # Sets the system sample rate.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 48000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
    end

    # Sets the oscillator waveform type using a normalized threshold profile.
    # @param value [Float] Normalized input value from 0.0 to 1.0 (>= 0.5 triggers SQUARE)
    def set_waveform(value)
      @waveform = (value >= 0.5) ? SQUARE : SAW
    end

    # Processes a single audio sample (1 frame) based on pitch input.
    # @param pitch_input [Float] Normalized pitch value (typically around -0.5 to 0.5)
    # @return [Float] Anti-aliased output sample scaled to approx +/-0.5 range
    def process(pitch_input = 0.0)
      # Clamp input pitch to designated bounds (-0.5 to 0.5)
      pitch = (pitch_input < -0.5) ? -0.5 : ((pitch_input > 0.5) ? 0.5 : pitch_input)
      
      # Convert pitch to frequency via fast lookup table interpolation
      freq = pitch_to_freq_fast(pitch)
      
      # Calculate phase increment per sample
      current_dt = freq / @sample_rate
      output = 0.0

      # Refactored to case statement for cleaner Spinel AOT compiler mapping
      case @waveform
      when SAW
        # Generate raw/naive sawtooth waveform
        naive_saw = -2.0 * @phase + 1.0
        # Apply PolyBLEP residual at the phase wrap-around point to reduce aliasing
        output = naive_saw + poly_blep(@phase, current_dt)

      when SQUARE
        # Generate raw/naive square waveform
        naive_square = (@phase < 0.5) ? 1.0 : -1.0
        
        # Apply PolyBLEP residual at the start of the period (phase = 0.0)
        blep_0 = poly_blep(@phase, current_dt)
        
        # Calculate phase offset for the middle of the period (phase = 0.5)
        phase_05 = @phase + 0.5
        if phase_05 >= 1.0
          phase_05 -= 1.0
        end
        
        # Apply PolyBLEP residual at the half-period transition (phase = 0.5)
        blep_05 = poly_blep(phase_05, current_dt)
        output = naive_square + blep_0 - blep_05
      end

      # Increment and wrap the phase accumulator
      @phase += current_dt
      if @phase >= 1.0
        @phase -= 1.0
      end

      # Scale down amplitude to prevent clipping in downstream modules
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
