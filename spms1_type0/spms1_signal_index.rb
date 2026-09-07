module Spms1
  # Indices into signals, the shared bus of audio-rate and control-rate signal values that main
  # wires modules together through. Assignment is static for now (each signal always lives at the
  # same index), but the indirection leaves room to make the wiring MIDI-assignable later without
  # changing how modules themselves are called.
  module SignalIndex
    SIGNALS_SIZE = 128

    # Updated once per audio buffer.
    PITCH = 0
    GATE  = 1

    # Audio-rate signals: updated once per sample. Starts at 32 to leave room in the block above.
    OSCILLATOR_WAVEFORM       = 32
    FILTER_CUTOFF             = 33
    FILTER_RESONANCE          = 34
    FILTER_ENV_GEN_MOD_AMOUNT = 35
    AMP_GAIN                  = 36
    ENV_GEN_ATTACK            = 37
    ENV_GEN_DECAY             = 38
    ENV_GEN_SUSTAIN           = 39
    ENV_GEN_OUTPUT            = 40
    OSCILLATOR_OUTPUT         = 41
    FILTER_OUTPUT             = 42
    AMP_OUTPUT                = 43

    # Control-rate signals: updated once per audio buffer. Starts at 64 to leave room in the block
    # above for more audio-rate signals.
    OSCILLATOR_WAVEFORM_TARGET       = 64
    FILTER_CUTOFF_TARGET             = 65
    FILTER_RESONANCE_TARGET          = 66
    FILTER_ENV_GEN_MOD_AMOUNT_TARGET = 67
    AMP_GAIN_TARGET                  = 68
    ENV_GEN_ATTACK_TARGET            = 69
    ENV_GEN_DECAY_TARGET             = 70
    ENV_GEN_SUSTAIN_TARGET           = 71
  end
end
