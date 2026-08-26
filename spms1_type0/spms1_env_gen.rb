module Spms1
  # An ADS (Attack, Decay, Sustain) Envelope Generator where Release matches Decay.
  # Optimized down to a 4-sample control rate grid to match downstream filters perfectly.
  # FSM state changes, levels, and coefficient calculations are internally gated 
  # to run once every 4 frames to completely eliminate redundant loop overhead.
  class EnvGen
    # Streamlined 3-state machine definitions
    STATE_ATTACK = 0
    STATE_SUSTAIN = 1
    STATE_IDLE = 2

    # Expanded lookup table size to 130 to completely eliminate branching overhead 
    # in the inner calculation loop. Indicies 128 and 129 hold the exact same maximum 
    # value to provide a safe flat-line interpolation buffer when input value clears 1.0.
    EXP_TABLE = Array.new(130, 0.0)
    for i in 0...129
      EXP_TABLE[i] = 10.0 ** ((i.to_f - 64.0) * (1.0 / 32.0))
    end
    EXP_TABLE[129] = EXP_TABLE[128] # Safe boundary padding for index + 1 lookups

    def initialize
      @sample_rate = 96000.0
      @state = STATE_IDLE
      @current_level = 0.0

      # Normalized ADS parameters ranging from 0.0 to 1.0 (Release equals Decay)
      @attack = 0.0
      @decay = 0.0
      @sustain = 1.0

      # Virtual target level for exponential attack to increase slope punchiness
      @attack_target = 2.0

      # Track the gate state from the previous control frame to detect edge transitions
      @was_gate_on = false

      # Coefficients updated via time-slicing within the control rate frame window
      @attack_coef = 1.0
      @decay_coef = 1.0

      # Internal counter to automatically handle the 4-sample control block updates
      @sample_counter = 0

      # Force initial immediate full calculations
      update_coefficients_full
    end

    # Sets the system sample rate.
    # @param sample_rate [Float] The sample rate in Hz (e.g., 96000.0)
    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
      update_coefficients_full
    end

    # Sets the attack time parameter.
    # @param value [Float] Normalized value from 0.0 to 1.0
    def set_attack(value)
      @attack = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    # Sets the decay time parameter.
    # @param value [Float] Normalized value from 0.0 to 1.0
    def set_decay(value)
      @decay = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    # Sets the sustain level parameter.
    # @param value [Float] Normalized level from 0.0 to 1.0
    def set_sustain(value)
      @sustain = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    # Processes a single audio sample (1 frame).
    # @param gate_input [Float] Value >= 0.5 sets Gate On, < 0.5 triggers Release
    # @return [Float] Current envelope value (0.0 to 1.0)
    def process(gate_input = 0.0)
      # Synchronize all FSM logic and level tracking onto the 4-sample grid to match Filter sync perfectly
      if @sample_counter == 0
        is_gate_on = gate_input >= 0.5

        # Handle Gate Input Edge Transitions (Note On / Note Off tracking)
        if is_gate_on && !@was_gate_on
          @state = STATE_ATTACK
        elsif !is_gate_on && @was_gate_on
          @state = STATE_SUSTAIN
        end

        @was_gate_on = is_gate_on

        # Periodically refresh the target coefficients inside the control window bounds
        update_coefficients_full

        # Execute Finite State Machine progression logic step at the 4-sample control rate
        case @state
        when STATE_ATTACK
          @current_level += (@attack_target - @current_level) * @attack_coef
          if @current_level >= 1.0
            @state = STATE_SUSTAIN
            @current_level = 1.0
          end

          # Handle premature note-off during the attack phase
          unless @was_gate_on
            @state = STATE_SUSTAIN
          end

        when STATE_SUSTAIN
          if @was_gate_on
            # Note On: Only allowed to chase downwards. Preventing volume swells when sustain is increased.
            if @sustain < @current_level
              @current_level += (@sustain - @current_level) * @decay_coef
            end
          else
            # Note Off: Smoothly chases absolute zero using the identical decay coefficient
            @current_level += (0.0 - @current_level) * @decay_coef
            
            # [Denormal Protection] Flush to hard 0.0 and enter IDLE when threshold is cleared
            if @current_level < 1e-5
              @state = STATE_IDLE
              @current_level = 0.0
            end
          end

        else # STATE_IDLE
          # Safety check to ensure re-trigger if gate is held active
          if @was_gate_on
            @state = STATE_ATTACK
          else
            @current_level = 0.0
          end
        end
      end

      # Increment and mask the sample tracking counter (0 to 3 wrap around for 4-sample grid)
      @sample_counter = (@sample_counter + 1) & 3

      # Always return the evaluated level (holds perfectly stable across intermediate frames)
      @current_level
    end

    private

    # Unifies the mathematical recalculations safely inside the 4-sample step boundary.
    def update_coefficients_full
      # 4-sample rate grid matches the update interval perfectly, restoring original time metrics
      effective_rate = @sample_rate * (1.0 / 4.0)

      # Attack Coefficient Evaluation Profile (1.00 ms to 10.0 s)
      attack_time = 0.1443 * calculate_exp_fast(@attack)
      @attack_coef = 1.0 / (attack_time * effective_rate)
      @attack_coef = 1.0 if @attack_coef > 1.0

      # Unified Decay/Release Coefficient Evaluation Profile (3.00 ms to 30.0 s)
      decay_time = 0.043281 * calculate_exp_fast(@decay)
      @decay_coef = 1.0 / (decay_time * effective_rate)
      @decay_coef = 1.0 if @decay_coef > 1.0
    end

    # High-speed conversion from normalized input to exponential multiplier
    def calculate_exp_fast(value)
      v_scale = value * 128.0
      index = v_scale.to_i
      fraction = v_scale - index.to_f
      
      e0 = EXP_TABLE[index]
      e1 = EXP_TABLE[index + 1] # Guaranteed safe up to index 129
      
      e0 + fraction * (e1 - e0)
    end
  end
end
