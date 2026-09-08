require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'

# PROTOTYPE / PERFORMANCE EXPERIMENT: combines two ideas tested separately so far.
#
# 1) Which modules run, and in what order, is data (active_modules), like the earlier
#    ModuleIndex-driven dispatch: a fixed-length, all-Integer array (MODULE_NONE = no
#    assignment), packed from the front, walked by a while loop that breaks at the first
#    MODULE_NONE (a plain loop, so break compiles to a plain C break -- no setjmp, unlike
#    breaking out of an .each block). Array reads (sp_IntArray_get) are inlined and cheap, and
#    there are only ever a handful of entries to scan before the break either way.
#
# 2) Which signal feeds each module's audio/modulation input is data too (SRC_* locals), but
#    resolved via pick_source (a case/when over plain local variables) instead of an array-based
#    signal bus -- that measured as the expensive part (array writes go through a non-inlined
#    sp_FloatArray_set regardless of whether the index is constant or data-driven). Every
#    module's output stays a plain local. Every other parameter (cutoff, resonance, gain, attack,
#    decay, sustain, waveform, gate, pitch) is its own dedicated knob, read directly, exactly as
#    in the original patch.
#
#    pick_source's result is forced back to a plain float with a trailing .to_f: without it, the
#    on-device measurement showed a huge regression (~3084us), consistent with Spinel inferring a
#    generic boxed value (sp_RbVal) for the case/when's result -- and, transitively, for
#    filter_output/amp_output themselves, since they're read back as source candidates elsewhere
#    -- which meant heavy GC activity from boxing every sample instead of plain float arithmetic.
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

# Module-output source IDs. Not array indices: only ever compared against in a case/when at a
# read site, so picking a source costs a compare-chain, never an array access.
SRC_ENV_GEN_OUTPUT    = 0
SRC_OSCILLATOR_OUTPUT = 1
SRC_FILTER_OUTPUT     = 2
SRC_AMP_OUTPUT        = 3

# NOTE: an earlier flash of this exact code crashed on-device almost immediately; a rebuild/
# reflash of the identical source ran fine (~350us, no crash). Didn't reproduce on retry, so
# most likely a one-off build/flash issue rather than a real bug in this rewrite -- but if a
# similar crash shows up again, this is the first place to suspect and bisect against the boxed
# expression form (case/when as an expression + .to_f) that measured ~360us and never crashed.
#
# Picks one of the four module outputs by source id. Uses case/when as a statement (assigning
# result inside each branch) rather than as an expression (capturing the case's own value) --
# a case/when used as an expression got inferred as a generic boxed value (sp_RbVal) by Spinel
# even with float-only branches, which showed up on-device as major overhead (heavy GC activity
# from boxing); as a statement, each branch's plain-float assignment stays a plain mrb_float,
# matching how the module dispatch case (case module_id ... end) above stays unboxed too.
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

oscillator = Oscillator.new(SAMPLE_RATE)
filter = Filter.new(SAMPLE_RATE)
amp = Amp.new(SAMPLE_RATE)
env_gen = EnvGen.new(SAMPLE_RATE)

# Which modules run each sample, in order. Fixed-length, all-Integer array (MODULE_NONE = no
# assignment) rather than a dynamically-sized one. Packed from the front with no gaps: the loop
# below stops at the first MODULE_NONE it hits.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)
active_modules[0] = MODULE_ENV_GEN
active_modules[1] = MODULE_OSCILLATOR
active_modules[2] = MODULE_FILTER
active_modules[3] = MODULE_AMP

# Which module output feeds Filter's and Amp's audio/modulation inputs, and which module output
# is the final (mono, for now) audio output. Fixed here to reproduce the original patch exactly,
# but these are plain Integer locals -- reassignable later (e.g. from MIDI, once per audio buffer)
# without touching the per-sample dispatch below.
filter_audio_source = SRC_OSCILLATOR_OUTPUT
filter_mod_source   = SRC_ENV_GEN_OUTPUT
amp_audio_source    = SRC_FILTER_OUTPUT
amp_mod_source      = SRC_ENV_GEN_OUTPUT
output_source       = SRC_AMP_OUTPUT

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

env_gen_output = 0.0
oscillator_output = 0.0
filter_output = 0.0
amp_output = 0.0

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

  AUDIO_BUFFER_WORDS.times do |i|
    # A while loop (not active_modules.each) so break stays a plain loop exit instead of a
    # non-local jump out of a block.
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
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
