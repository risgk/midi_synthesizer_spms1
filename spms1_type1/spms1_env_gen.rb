module Spms1
  # ADS envelope updated at 4-sample control-rate grid.
  class EnvGen
    STATE_ATTACK = 0
    STATE_SUSTAIN = 1
    STATE_IDLE = 2
    # Blend at the reference rate on the line below. The two move together: their product is what
    # fixes the time constant, so changing one without the other changes how fast smoothing is.
    SMOOTHING_TARGET_BLEND_BASE = 0.03125
    # Number of samples between control-rate updates; envelope timing is kept approximately constant if this is changed.
    # It has to stay a power of two: the counter below wraps with a mask, because Ruby's % is a
    # floor-modulo and sp_imod carries a sign correction the counter can never need -- one branch
    # a sample in each module, ten across the six of them.
    CONTROL_RATE_DIVISOR = 4
    # Its own constant, not CONTROL_RATE_DIVISOR - 1 where it is used: Spinel emits an Integer
    # constant as a runtime global and does not fold arithmetic on one, so written that way the
    # subtraction survives into the per-sample path carrying an overflow check of its own, which
    # measured far worse than the modulo it replaces. What the mask buys is size, not
    # determinism: the ten branches it removes, one per site, are ones that could never be taken.
    # Together with the LFO's fold it took 11 branches and 60 instructions out of Spms1_main as
    # linked, and the buffer time did not move (853/857us against 854/856).
    CONTROL_RATE_MASK = CONTROL_RATE_DIVISOR - 1

    # Lookup table for exponential time mapping. A twelfth of an octave per index, so one CC step
    # of the 120-step control range moves a time by a semitone and the whole dial spans ten octaves.
    EXP_TABLE = Array.new(122, 0.0)
    for i in 0...121
      EXP_TABLE[i] = 2.0 ** ((i.to_f - 60.0) * (1.0 / 12.0))
    end
    EXP_TABLE[121] = EXP_TABLE[120]

    # Time scaling constants (value at 0.0 / (EXP_TABLE min * ln(2))).
    # Attack range: 2.5 ms at 0.0, 80 ms at 0.5, 2.56 s at 1.0.
    ATTACK_BASE = 0.0025 / ((1.0 / 32.0) * Math::log(2))
    # Decay range: 10 ms at 0.0, 320 ms at 0.5, 10.24 s at 1.0 -- the attack times four throughout.
    # Decay is measured to 1/1024 = 2^-10, which keeps the attack's base of 2 rather than landing
    # on a round -60 dB. 1/1024 is -60.2 dB; the shared base is worth more than closing the 0.2.
    DECAY_BASE  = 0.010 / ((1.0 / 32.0) * 10 * Math::log(2))

    # Overshoot target so the attack ramp reaches 1.0 in finite time.
    ATTACK_TARGET = 2.0

    def initialize(sample_rate)
      @sample_rate = sample_rate
      # Rate the envelope actually steps at. Fixed once sample_rate is, so it is computed here
      # rather than on every control-rate update.
      @effective_rate = sample_rate * (1.0 / CONTROL_RATE_DIVISOR)
      @smoothing_target_blend = SMOOTHING_TARGET_BLEND_BASE * (48000.0 / @sample_rate) * (CONTROL_RATE_DIVISOR / 4.0)
      @state = STATE_IDLE
      @current_level = 0.0
      @last_output_level = 0.0
      @output = 0.0
      @slope = 0.0

      @attack = 0.0
      @decay = 0.0
      @sustain = 1.0
      @level = 1.0
      @polarity = 1.0
      # Level and polarity are multiplied before smoothing, so the control-rate path takes one
      # multiply and only one smoothing state has to be carried.
      @amount = 1.0
      @current_amount = 1.0

      @was_gate_on = false
      @attack_coef = 1.0
      @decay_coef = 1.0
      @sample_counter = 0

      update_coefficients_full
    end

    # Every parameter is unipolar, [0.0, 1.0], which is what the table lookup and the level
    # comparisons below are written against.
    # Attack time: see ATTACK_BASE for scaling details.
    def set_attack(attack)
      @attack = (attack < 0.0) ? 0.0 : ((attack > 1.0) ? 1.0 : attack)
    end

    # Decay time: see DECAY_BASE for scaling details.
    def set_decay(decay)
      @decay = (decay < 0.0) ? 0.0 : ((decay > 1.0) ? 1.0 : decay)
    end

    # Sustain level: silent at 0.0, full at 1.0.
    def set_sustain(sustain)
      @sustain = (sustain < 0.0) ? 0.0 : ((sustain > 1.0) ? 1.0 : sustain)
    end

    # The output is scaled by level and polarity together, as the LFO's is. Level is unipolar,
    # [0.0, 1.0], a plain multiplier. Polarity is bipolar, [-0.5, 0.5], and doubled: +0.5 passes
    # the output through, -0.5 negates it, and the way between scales it, crossing silence at 0.0.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @amount = @level * @polarity
    end

    def set_polarity(polarity)
      clamped_polarity = (polarity < -0.5) ? -0.5 : ((polarity > 0.5) ? 0.5 : polarity)
      @polarity = clamped_polarity + clamped_polarity
      @amount = @level * @polarity
    end

    def process(gate_input = 0.0)
      # Gate transitions drive the ADS state machine; level changes are stepped at the control rate.
      if @sample_counter == 0
        is_gate_on = gate_input >= 0.25
        gate_rose = is_gate_on && !@was_gate_on
        gate_fell = !is_gate_on && @was_gate_on

        @state = gate_rose ? STATE_ATTACK : (gate_fell ? STATE_SUSTAIN : @state)
        @was_gate_on = is_gate_on

        update_coefficients_full

        target = (@state == STATE_ATTACK) ? ATTACK_TARGET : (((@state == STATE_SUSTAIN) && is_gate_on) ? @sustain : 0.0)
        coef = (@state == STATE_ATTACK) ? @attack_coef : ((@state == STATE_SUSTAIN) ? @decay_coef : 0.0)

        apply_step = (@state != STATE_SUSTAIN) || !is_gate_on || (@sustain < @current_level)
        coef_masked = apply_step ? coef : 0.0

        @current_level += (target - @current_level) * coef_masked

        is_attack_done = (@state == STATE_ATTACK) && (@current_level >= 1.0 || !@was_gate_on)
        # The floor holds with the gate on too: decaying toward a sustain of 0.0, the level would
        # otherwise sink into denormals and stick at the smallest one, which x86 computes slowly.
        is_floor_reached = (@state == STATE_SUSTAIN) && (@current_level < 1e-5)
        is_idle_reached = is_floor_reached && !@was_gate_on
        is_forced_attack = (@state == STATE_IDLE) && @was_gate_on

        @state = is_attack_done ? STATE_SUSTAIN : (is_idle_reached ? STATE_IDLE : (is_forced_attack ? STATE_ATTACK : @state))

        @current_level = 1.0 if is_attack_done
        @current_level = 0.0 if is_floor_reached || (@state == STATE_IDLE && !@was_gate_on)

        # The amount is smoothed here, on the step, so a change in it rides the same ramp as the
        # level does rather than stepping the output.
        @current_amount += (@amount - @current_amount) * @smoothing_target_blend
        output_level = @current_level * @current_amount

        # The output ramps from the last step's level to this one's over the next four samples,
        # so what reaches the amp is a line rather than a staircase at a quarter of the sample
        # rate. Starting each ramp from the stored level rather than from where the additions
        # got to keeps rounding from building up, and lands a ramp to 0.0 on exactly zero.
        # 0.25 is 1 / CONTROL_RATE_DIVISOR, written out for the reason Mixer#process gives.
        @output = @last_output_level
        @slope = (output_level - @last_output_level) * 0.25
        @last_output_level = output_level
      end

      @sample_counter = (@sample_counter + 1) & CONTROL_RATE_MASK
      @output += @slope
      @output
    end

    private

    def update_coefficients_full
      @attack_coef = 1.0 / (ATTACK_BASE * calculate_exp_fast(@attack) * @effective_rate)
      @decay_coef  = 1.0 / (DECAY_BASE  * calculate_exp_fast(@decay)  * @effective_rate)
    end

    def calculate_exp_fast(value)
      v_scale = value * 120.0
      index = v_scale.to_i
      fraction = v_scale - index.to_f

      e0 = EXP_TABLE[index]
      e1 = EXP_TABLE[index + 1]

      e0 + fraction * (e1 - e0)
    end
  end
end
