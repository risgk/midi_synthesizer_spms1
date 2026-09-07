require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_signal_index'
require_relative 'spms1_module_index'

module Spms1
  module C
    ffi_func :set_midi_note_on_pitch, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_pitch, [:uint8],                 :uint8
    ffi_func :set_midi_note_on_state, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_state, [:uint8],                 :uint8
    ffi_func :set_midi_cc_value,      [:uint8, :uint8, :uint8], :void
    ffi_func :get_midi_cc_value,      [:uint8, :uint8],         :uint8
    ffi_func :set_sample_rate,        [:int32],                 :void
    ffi_func :get_sample_rate,        [],                       :int32
    ffi_func :set_audio_buffers,      [:int32],                 :void
    ffi_func :get_audio_buffers,      [],                       :int32
    ffi_func :set_audio_buffer_words, [:int32],                 :void
    ffi_func :get_audio_buffer_words, [],                       :int32
    ffi_func :start_audio,            [],                       :void
    ffi_func :stop_audio,             [],                       :void
    ffi_func :write_to_audio_buffer,  [:float, :float],         :void
    ffi_func :start_debug_measure,    [],                       :void
    ffi_func :stop_debug_measure,     [],                       :void
  end
end

include Spms1
include SignalIndex
include ModuleIndex

MIDI_CH            = 0
SAMPLE_RATE        = 96000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

# The instantiated modules, kept as their own typed locals so the dispatch loop below can call
# each one directly instead of going through a dynamically-typed lookup.
env_gen = EnvGen.new(SAMPLE_RATE)
oscillator = Oscillator.new(SAMPLE_RATE)
filter = Filter.new(SAMPLE_RATE)
amp = Amp.new(SAMPLE_RATE)

# ModuleIndex values that actually run each sample, in order; a subset of what's in modules.
# Fixed-length, all-Integer array (MODULE_NONE = no assignment) rather than a dynamically-sized one.
# Packed from the front with no gaps: the loop below stops at the first MODULE_NONE it hits.
active_module_indices = Array.new(MODULES_SIZE, MODULE_NONE)
active_module_indices[0] = ENV_GEN
active_module_indices[1] = OSCILLATOR
active_module_indices[2] = FILTER
active_module_indices[3] = AMP

# Which signal feeds each positional argument of a module's process(), and which signal its
# result is written to. Data, indexed by ModuleIndex, so this wiring may become MIDI-assignable
# later without changing the dispatch loop below (SignalIndex::SIGNAL_NONE = unused argument slot).
# Flat (not nested) so it stays one static, all-Integer array rather than an array of arrays --
# module_index's row starts at module_index * MODULE_MAX_ARGS.
module_input_signal_indices = Array.new(MODULES_SIZE * MODULE_MAX_ARGS, SignalIndex::SIGNAL_NONE)
module_output_signal_indices = Array.new(MODULES_SIZE, SignalIndex::SIGNAL_NONE)

module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 0] = GATE
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 1] = ENV_GEN_ATTACK
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 2] = ENV_GEN_DECAY
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 3] = ENV_GEN_SUSTAIN
module_output_signal_indices[ENV_GEN]                      = ENV_GEN_OUTPUT

module_input_signal_indices[OSCILLATOR * MODULE_MAX_ARGS + 0] = PITCH
module_input_signal_indices[OSCILLATOR * MODULE_MAX_ARGS + 1] = OSCILLATOR_WAVEFORM
module_output_signal_indices[OSCILLATOR]                      = OSCILLATOR_OUTPUT

module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 0] = OSCILLATOR_OUTPUT
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 1] = ENV_GEN_OUTPUT
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 2] = FILTER_CUTOFF
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 3] = FILTER_RESONANCE
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 4] = FILTER_ENV_GEN_MOD_AMOUNT
module_output_signal_indices[FILTER]                      = FILTER_OUTPUT

module_input_signal_indices[AMP * MODULE_MAX_ARGS + 0] = FILTER_OUTPUT
module_input_signal_indices[AMP * MODULE_MAX_ARGS + 1] = ENV_GEN_OUTPUT
module_input_signal_indices[AMP * MODULE_MAX_ARGS + 2] = AMP_GAIN
module_output_signal_indices[AMP]                      = AMP_OUTPUT

# Shared bus that modules are wired through; see SignalIndex for what each slot holds. Each
# module smooths its own parameter internally (at its own control rate), so main just writes the
# raw MIDI-derived target straight into the signal a module reads from.
signals = Array.new(SIGNALS_SIZE, 0.0)

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

C.set_midi_cc_value(MIDI_CH, 20 , 0  ) # Oscillator Waveform
C.set_midi_cc_value(MIDI_CH, 74 , 127) # Filter Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter EG Amt
C.set_midi_cc_value(MIDI_CH, 15 , 100) # Amp Gain
C.set_midi_cc_value(MIDI_CH, 73 , 0  ) # EG Attack
C.set_midi_cc_value(MIDI_CH, 75 , 96 ) # EG Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 0  ) # EG Sustain

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  signals[PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[GATE] = C.get_midi_note_on_state(MIDI_CH).to_f

  signals[OSCILLATOR_WAVEFORM] = (((value = C::get_midi_cc_value(MIDI_CH, 20)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[FILTER_CUTOFF] = (C::get_midi_cc_value(MIDI_CH, 74).to_f - 4.0) * (1.0 / 120.0)
  signals[FILTER_RESONANCE] = (((value = C::get_midi_cc_value(MIDI_CH, 71)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[FILTER_ENV_GEN_MOD_AMOUNT] = (((value = C::get_midi_cc_value(MIDI_CH, 24)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[AMP_GAIN] = ((value = C.get_midi_cc_value(MIDI_CH, 15)).to_f * value.to_f) * (1.0 / (127.0 * 127.0))
  signals[ENV_GEN_ATTACK] = (((value = C::get_midi_cc_value(MIDI_CH, 73)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[ENV_GEN_DECAY] = (((value = C::get_midi_cc_value(MIDI_CH, 75)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[ENV_GEN_SUSTAIN] = (((value = C::get_midi_cc_value(MIDI_CH, 30)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)

  AUDIO_BUFFER_WORDS.times do |i|
    # Run the active modules front to back, stopping at the first MODULE_NONE (see active_module_indices
    # above). Which signal feeds each argument, and where the result lands, comes from
    # module_input_signal_indices / module_output_signal_indices; only which typed local gets
    # called, and its argument count/order (plus the Filter audio input's fixed -6dB pad), stay
    # hard-coded per module here. Each branch reads only the inputs it actually needs.
    # A while loop (not active_module_indices.each) so break stays a plain loop exit instead of
    # a non-local jump out of a block.
    module_slot = 0
    while module_slot < MODULES_SIZE
      module_index = active_module_indices[module_slot]
      break if module_index == MODULE_NONE

      input_base = module_index * MODULE_MAX_ARGS
      output = module_output_signal_indices[module_index]

      case module_index
      when ENV_GEN
        signals[output] = env_gen.process(signals[module_input_signal_indices[input_base]],
          signals[module_input_signal_indices[input_base + 1]], signals[module_input_signal_indices[input_base + 2]],
          signals[module_input_signal_indices[input_base + 3]])
      when OSCILLATOR
        signals[output] = oscillator.process(signals[module_input_signal_indices[input_base]],
          signals[module_input_signal_indices[input_base + 1]])
      when FILTER
        signals[output] = filter.process(signals[module_input_signal_indices[input_base]] * 0.5,
          signals[module_input_signal_indices[input_base + 1]], signals[module_input_signal_indices[input_base + 2]],
          signals[module_input_signal_indices[input_base + 3]], signals[module_input_signal_indices[input_base + 4]])
      when AMP
        signals[output] = amp.process(signals[module_input_signal_indices[input_base]],
          signals[module_input_signal_indices[input_base + 1]], signals[module_input_signal_indices[input_base + 2]])
      end

      module_slot += 1
    end

    audio_buffer[i] = signals[AMP_OUTPUT]
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
