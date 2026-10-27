module Spms1
  # ADS envelope updated on a 4-sample control-rate grid, its release either the decay's or the
  # shortest decay's (the release switch). Out Inv puts out the envelope negated as well.
  class EnvGen
    STATE_ATTACK = 0
    STATE_SUSTAIN = 1
    STATE_IDLE = 2
    # Blend at the reference rate on the line below, for each of two cascaded stages. The two move
    # together: their product is what fixes the time constant, so changing one without the other
    # changes how fast smoothing is. Two stages at 1/64 (5.3 ms each at 48 kHz) delay a step by
    # 10.7 ms on average, as one stage at 1/128 would, but start from zero slope, so that the steps
    # of a controller sending sparse CCs (e.g. every 20 ms) are rounded off rather than heard,
    # and settle sooner, 99% in 35 ms.
    SMOOTHING_TARGET_BLEND_BASE = 0.015625
    # Samples between control-rate updates. The main loop sets the cadence, handing every module
    # the same control tick once every CONTROL_RATE_DIVISOR samples (see spms1_main.rb), and the
    # rates derived here assume this, so the two have to match; envelope timing is kept approximately
    # constant if both are changed.
    CONTROL_RATE_DIVISOR = 4

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
      # 1.0 when the release follows the decay, 0.0 when it takes the shortest decay; see
      # set_release_switch.
      @release_follows_decay = 1.0
      @sustain = 1.0
      @level = 0.0
      # The level, smoothed; the control-rate path takes one multiply by it. It starts at 0.0, as
      # the other levels and the gains do, and comes up through the smoothing to what the patch sets.
      @amount = 0.0
      @stage_1_amount = 0.0
      @current_amount = 0.0

      @was_gate_on = false
      @attack_coef = 1.0
      @decay_coef = 1.0
      @release_coef = 1.0
      # The shortest decay's coefficient, the release's with the switch off. Fixed once the
      # sample rate is, as EXP_TABLE's first entry is the bottom of the decay dial.
      @shortest_decay_coef = 1.0 / (DECAY_BASE * EXP_TABLE[0] * @effective_rate)

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

    # Release Sw is unipolar, [0.0, 1.0], and taken as a switch, on from 0.5 (CC 64) up, as a
    # MIDI switch is on from 64: on, the release, after the gate falls, runs at the decay's rate;
    # off, it runs at the shortest decay's, 10 ms, whatever the decay is. Not smoothed: there is
    # nothing between its two settings to pass through.
    def set_release_switch(switch)
      @release_follows_decay = (switch >= 0.5) ? 1.0 : 0.0
    end

    # Sustain level: silent at 0.0, full at 1.0.
    def set_sustain(sustain)
      @sustain = (sustain < 0.0) ? 0.0 : ((sustain > 1.0) ? 1.0 : sustain)
    end

    # The output is scaled by level, as the LFO's is: unipolar, [0.0, 1.0], a plain multiplier.
    # Turning it the other way up is for Out Inv, or a mixer's Out Inv.
    def set_level(level)
      @level = (level < 0.0) ? 0.0 : ((level > 1.0) ? 1.0 : level)
      @amount = @level
    end

    def process(control_tick, gate_input = 0.0)
      # Gate transitions drive the ADS state machine; level changes are stepped at the control rate.
      if control_tick
        is_gate_on = gate_input >= 0.25
        gate_rose = is_gate_on && !@was_gate_on
        gate_fell = !is_gate_on && @was_gate_on

        @state = gate_rose ? STATE_ATTACK : (gate_fell ? STATE_SUSTAIN : @state)
        @was_gate_on = is_gate_on

        update_coefficients_full

        target = (@state == STATE_ATTACK) ? ATTACK_TARGET : (((@state == STATE_SUSTAIN) && is_gate_on) ? @sustain : 0.0)
        # With the gate off, the sustain state is the release, and takes the release's rate.
        coef = (@state == STATE_ATTACK) ? @attack_coef : ((@state == STATE_SUSTAIN) ? (is_gate_on ? @decay_coef : @release_coef) : 0.0)

        # With the gate on, the level follows the sustain both ways at the decay rate, so raising
        # the sustain while a note is held raises the level too.
        @current_level += (target - @current_level) * coef

        is_attack_done = (@state == STATE_ATTACK) && (@current_level >= 1.0 || !@was_gate_on)
        # The floor holds with the gate on too: decaying toward a sustain of 0.0, the level would
        # otherwise sink into denormals and stick at the smallest one, which x86 computes slowly.
        # Only where the target is below it as well, so that a sustain raised from 0.0 is not held
        # at the floor by a long decay, whose first step can fall short of it.
        is_floor_reached = (@state == STATE_SUSTAIN) && (@current_level < 1e-5) && (target < 1e-5)
        is_idle_reached = is_floor_reached && !@was_gate_on
        is_forced_attack = (@state == STATE_IDLE) && @was_gate_on

        @state = is_attack_done ? STATE_SUSTAIN : (is_idle_reached ? STATE_IDLE : (is_forced_attack ? STATE_ATTACK : @state))

        @current_level = 1.0 if is_attack_done
        @current_level = 0.0 if is_floor_reached || (@state == STATE_IDLE && !@was_gate_on)

        # The amount is smoothed here, on the step, so a change in it rides the same ramp as the
        # level does rather than stepping the output.
        @stage_1_amount = Dsp.smooth(@amount, @stage_1_amount, @smoothing_target_blend)
        @current_amount = Dsp.smooth(@stage_1_amount, @current_amount, @smoothing_target_blend)
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
      @output += @slope
      @output
    end

    # Out Inv: the output of the last process, negated, from 0.0 down to -1.0.
    def output_inverted
      -@output
    end

    private

    def update_coefficients_full
      @attack_coef = 1.0 / (ATTACK_BASE * calculate_exp_fast(@attack) * @effective_rate)
      @decay_coef  = 1.0 / (DECAY_BASE  * calculate_exp_fast(@decay)  * @effective_rate)
      # A blend of the two by a weight of 1.0 or 0.0, so the pick is a multiply, not a branch.
      # Each term is weighted on its own, rather than as shortest + (decay - shortest) * weight,
      # so that the release lands on the decay's coefficient exactly, not within a rounding of it.
      @release_coef = @decay_coef * @release_follows_decay + @shortest_decay_coef * (1.0 - @release_follows_decay)
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
