module Spms1
  # Indices into signals, the shared bus of audio-rate and control-rate signal values that main
  # wires modules together through. SIGNAL_NONE (0) is reserved as the sentinel for "no signal",
  # so per-module wiring tables (see main) can reference it without relying on nil.
  module SignalIndex
    SIGNALS_SIZE = 128

    SIGNAL_NONE = 0

    # Updated once per audio buffer.
    PITCH = 1
    GATE  = 2

    # Module parameters: main writes the raw MIDI-derived value once per audio buffer; each module
    # smooths it internally, at its own control rate. Starts at 32 to leave room in the block above.
    OSCILLATOR_WAVEFORM       = 32
    FILTER_CUTOFF             = 33
    FILTER_RESONANCE          = 34
    FILTER_ENV_GEN_MOD_AMOUNT = 35
    AMP_GAIN                  = 36
    ENV_GEN_ATTACK            = 37
    ENV_GEN_DECAY             = 38
    ENV_GEN_SUSTAIN           = 39

    # Module outputs: updated once per sample.
    ENV_GEN_OUTPUT            = 40
    OSCILLATOR_OUTPUT         = 41
    FILTER_OUTPUT             = 42
    AMP_OUTPUT                = 43
  end
end
