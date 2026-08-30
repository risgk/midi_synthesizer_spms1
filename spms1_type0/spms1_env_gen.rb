module Spms1
  # ADS envelope updated at 4-sample control-rate grid.
  class EnvGen
    STATE_ATTACK = 0
    STATE_SUSTAIN = 1
    STATE_IDLE = 2

    # Lookup table for exponential time mapping.
    EXP_TABLE = Array.new(130, 0.0)
    for i in 0...129
      EXP_TABLE[i] = 10.0 ** ((i.to_f - 64.0) * (1.0 / 32.0))
    end
    EXP_TABLE[129] = EXP_TABLE[128]

    # Time scaling constants for attack and decay.
    ATTACK_BASE = 0.1
    DECAY_BASE = 0.3

    def initialize
      @sample_rate = 96000.0
      @state = STATE_IDLE
      @current_level = 0.0

      @attack = 0.0
      @decay = 0.0
      @sustain = 1.0

      @attack_target = 2.0
      @was_gate_on = false

      @attack_coef = 1.0
      @decay_coef = 1.0

      @sample_counter = 0

      # Precomputed coefficient tables for fast lookup with linear interpolation.
      @attack_coef_table = Array.new(130, 0.0)
      @decay_coef_table = Array.new(130, 0.0)

      set_sample_rate(@sample_rate)
    end

    def set_sample_rate(sample_rate)
      @sample_rate = sample_rate
      effective_rate = @sample_rate * (1.0 / 4.0)

      # Precompute coefficient tables based on sample rate.
      for i in 0...130
        exp_val = EXP_TABLE[i]
        attack_time = ATTACK_BASE * exp_val
        @attack_coef_table[i] = 2.0 ** (-1.0 / (attack_time * effective_rate))
        @attack_coef_table[i] = 1.0 if @attack_coef_table[i] > 1.0

        decay_time = DECAY_BASE * exp_val
        @decay_coef_table[i] = 2.0 ** (-10.0 / (decay_time * effective_rate))
        @decay_coef_table[i] = 1.0 if @decay_coef_table[i] > 1.0
      end

      update_coefficients_full
    end

    # Attack time is normalized to [0.0, 1.0].
    # Range: 1 ms (0.0), 100 ms (0.5), 10 s (1.0).
    def set_attack(value)
      @attack = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    def set_decay(value)
      # Decay time is normalized to [0.0, 1.0].
      # Range: 3 ms (0.0), 300 ms (0.5), 30 s (1.0).
      @decay = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    def set_sustain(value)
      # Sustain level is normalized to [0.0, 1.0].
      @sustain = (value < 0.0) ? 0.0 : ((value > 1.0) ? 1.0 : value)
    end

    def process(gate_input = 0.0)
      # Gate transitions drive the ADS state machine; level changes are stepped at the control rate.
      if @sample_counter == 0
        is_gate_on = gate_input >= 0.5

        if is_gate_on && !@was_gate_on
          @state = STATE_ATTACK
        elsif !is_gate_on && @was_gate_on
          @state = STATE_SUSTAIN
        end

        @was_gate_on = is_gate_on
        update_coefficients_full

        case @state
        when STATE_ATTACK
          @current_level += (@attack_target - @current_level) * @attack_coef
          if @current_level >= 1.0
            @state = STATE_SUSTAIN
            @current_level = 1.0
          end

          unless @was_gate_on
            @state = STATE_SUSTAIN
          end

        when STATE_SUSTAIN
          if @was_gate_on
            if @sustain < @current_level
              @current_level += (@sustain - @current_level) * @decay_coef
            end
          else
            @current_level += (0.0 - @current_level) * @decay_coef

            if @current_level < 1e-5
              @state = STATE_IDLE
              @current_level = 0.0
            end
          end

        else
          if @was_gate_on
            @state = STATE_ATTACK
          else
            @current_level = 0.0
          end
        end
      end

      @sample_counter = (@sample_counter + 1) & 3
      @current_level
    end

    private

    def update_coefficients_full
      # Interpolate coefficient from precomputed table for fast lookup.
      attack_v = @attack * 128.0
      attack_index = attack_v.to_i
      attack_fraction = attack_v - attack_index.to_f
      c0 = @attack_coef_table[attack_index]
      c1 = @attack_coef_table[attack_index + 1]
      @attack_coef = c0 + attack_fraction * (c1 - c0)

      decay_v = @decay * 128.0
      decay_index = decay_v.to_i
      decay_fraction = decay_v - decay_index.to_f
      c0 = @decay_coef_table[decay_index]
      c1 = @decay_coef_table[decay_index + 1]
      @decay_coef = c0 + decay_fraction * (c1 - c0)
    end
  end
end
