require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'

# PROTOTYPE / PERFORMANCE EXPERIMENT: three ideas, tested separately, combined here.
#
# 1) Which modules run, and in what order, is data (active_modules): a fixed-length, all-Integer
#    array (MODULE_NONE = no assignment) packed from the front, walked by a while loop that breaks
#    at the first MODULE_NONE. A plain loop, so break compiles to a plain C break -- unlike
#    breaking out of an .each block, which needs setjmp. sp_IntArray_get is inlined and cheap.
#
# 2) Which signal feeds each module's input is data too (SRC_* locals), but resolved by
#    pick_source -- a case/when over plain locals -- rather than an array-based signal bus, which
#    measured as the expensive part: array writes go through sp_FloatArray_set whether the index
#    is constant or data-driven. Every module output stays a plain local, and every other
#    parameter (cutoff, resonance, gain, attack, decay, sustain, waveform, gate, pitch) is its own
#    dedicated knob, read directly, exactly as in the original patch.
#
# 3) The per-sample loop lives in render_audio_buffer, a plain method, rather than directly inside
#    the top-level `loop do` block. `loop do` compiles to a setjmp region, so Spinel must mark
#    every local assigned inside it `volatile` (a local modified between setjmp and longjmp is
#    otherwise undefined) and the hot signal locals never reach a register. A `def` body has no
#    setjmp in it, which is why the module process methods never had the problem.
#
#    `signals` carries the four module outputs across buffer boundaries: a routing with feedback
#    reads last sample's value, and at a buffer edge that is the previous call's. Read into locals
#    on entry, written back on exit, so four array accesses per buffer rather than per sample.
#
#    This depends on Spms1_main being in RAM. Freed from volatile, GCC inlines all four process
#    bodies into the loop and duplicates it across the dispatch paths, and the result no longer
#    fits the XIP cache that core0 shares. From flash this change is a large net loss; it only
#    pays off with the `.time_critical` attribute in sp_runtime.h in place, so do not revert that.
#
# Restore the previous (reverted) main.rb with `git checkout 6746b36 -- spms1_main.rb`.

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

MIDI_CH            = 0
SAMPLE_RATE        = 96000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

MODULES_SIZE = 128

MODULE_NONE       = 0
MODULE_ENV_GEN    = 1
MODULE_OSCILLATOR = 2
MODULE_FILTER     = 3
MODULE_AMP        = 4

# Module-output source IDs. Not array indices: only ever compared against in pick_source, so
# picking a source costs a compare-chain, never an array access.
SRC_ENV_GEN_OUTPUT    = 0
SRC_OSCILLATOR_OUTPUT = 1
SRC_FILTER_OUTPUT     = 2
SRC_AMP_OUTPUT        = 3

SIGNALS_SIZE = 4

# Picks one of the four module outputs by source id. The case/when is a statement, with each
# branch assigning `result` -- not an expression capturing the case's own value. As an expression
# Spinel infers a boxed sp_RbVal even with float-only branches, and that boxing lands on every
# sample. As a statement each branch stays a plain mrb_float, as the module dispatch case does.
def pick_source(source, env_gen_out, osc_out, filter_out, amp_out)
  result = 0.0
  case source
  when SRC_ENV_GEN_OUTPUT    then result = env_gen_out
  when SRC_OSCILLATOR_OUTPUT then result = osc_out
  when SRC_FILTER_OUTPUT     then result = filter_out
  when SRC_AMP_OUTPUT        then result = amp_out
  end
  result
end

# Renders one audio buffer. Everything the loop touches arrives as an argument -- once per buffer,
# so the wide parameter list costs nothing per sample. See note 3 for why this is a method.
def render_audio_buffer(env_gen, oscillator, filter, amp,
                        active_modules, audio_buffer, signals,
                        pitch, gate,
                        filter_audio_source, filter_mod_source,
                        amp_audio_source, amp_mod_source, output_source)
  env_gen_output    = signals[0]
  oscillator_output = signals[1]
  filter_output     = signals[2]
  amp_output        = signals[3]

  i = 0
  while i < AUDIO_BUFFER_WORDS
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      case module_id
      when MODULE_ENV_GEN
        env_gen_output = env_gen.process(gate)
      when MODULE_OSCILLATOR
        oscillator_output = oscillator.process(pitch)
      when MODULE_FILTER
        filter_audio_input = pick_source(filter_audio_source, env_gen_output, oscillator_output, filter_output, amp_output)
        filter_mod_input   = pick_source(filter_mod_source, env_gen_output, oscillator_output, filter_output, amp_output)
        filter_output = filter.process(filter_audio_input, filter_mod_input)
      when MODULE_AMP
        amp_audio_input = pick_source(amp_audio_source, env_gen_output, oscillator_output, filter_output, amp_output)
        amp_mod_input   = pick_source(amp_mod_source, env_gen_output, oscillator_output, filter_output, amp_output)
        amp_output = amp.process(amp_audio_input, amp_mod_input)
      end

      slot += 1
    end

    audio_buffer[i] = pick_source(output_source, env_gen_output, oscillator_output, filter_output, amp_output)
    i += 1
  end

  # Ends on an assignment, not an explicit `nil`, so the inferred return type stays a plain float.
  signals[0] = env_gen_output
  signals[1] = oscillator_output
  signals[2] = filter_output
  signals[3] = amp_output
end

oscillator = Oscillator.new(SAMPLE_RATE)
filter = Filter.new(SAMPLE_RATE)
amp = Amp.new(SAMPLE_RATE)
env_gen = EnvGen.new(SAMPLE_RATE)

# Which modules run each sample, in order. Packed from the front with no gaps -- see note 1.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)
active_modules[0] = MODULE_ENV_GEN
active_modules[1] = MODULE_OSCILLATOR
active_modules[2] = MODULE_FILTER
active_modules[3] = MODULE_AMP

# Signal routing, and which module output is the final (mono, for now) audio output. Fixed here to
# reproduce the original patch, but these are plain Integer locals: reassignable later, e.g. from
# MIDI once per buffer, without touching the per-sample dispatch.
filter_audio_source = SRC_OSCILLATOR_OUTPUT
filter_mod_source   = SRC_ENV_GEN_OUTPUT
amp_audio_source    = SRC_FILTER_OUTPUT
amp_mod_source      = SRC_ENV_GEN_OUTPUT
output_source       = SRC_AMP_OUTPUT

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# Module outputs carried across buffer boundaries. Touched twice per buffer, never per sample.
signals = Array.new(SIGNALS_SIZE, 0.0)

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

  pitch = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  gate = C.get_midi_note_on_state(MIDI_CH).to_f

  oscillator.set_waveform((((value = C::get_midi_cc_value(MIDI_CH, 20)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  filter.set_cutoff((C::get_midi_cc_value(MIDI_CH, 74).to_f - 4.0) * (1.0 / 120.0))
  filter.set_resonance((((value = C::get_midi_cc_value(MIDI_CH, 71)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  filter.set_modulation_amount((((value = C::get_midi_cc_value(MIDI_CH, 24)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  amp.set_gain(((value = C.get_midi_cc_value(MIDI_CH, 15)).to_f * value.to_f) * (1.0 / (127.0 * 127.0)))
  env_gen.set_attack((((value = C::get_midi_cc_value(MIDI_CH, 73)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  env_gen.set_decay((((value = C::get_midi_cc_value(MIDI_CH, 75)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  env_gen.set_sustain((((value = C::get_midi_cc_value(MIDI_CH, 30)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))

  render_audio_buffer(env_gen, oscillator, filter, amp,
                      active_modules, audio_buffer, signals,
                      pitch, gate,
                      filter_audio_source, filter_mod_source,
                      amp_audio_source, amp_mod_source, output_source)

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
