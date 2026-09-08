require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'

# Three structural choices, referred to below as notes 1-3. What they say about the generated C
# holds for the Spinel version vendored in sp_runtime.h; re-check on updating it.
#
# 1) active_modules is walked by a plain while loop, not .each: breaking out of a block needs
#    setjmp, while a plain break compiles to a C break.
#
# 2) pick_source resolves routing over plain locals rather than an array signal bus, because
#    sp_FloatArray_set costs the same whether the index is constant or data-driven.
#
# 3) The per-sample loop is a method, not the body of `loop do`: `loop do` compiles to a setjmp
#    region, forcing every local assigned inside it to `volatile`, and `signals` carries the four
#    module outputs across the call boundary. Freed from volatile GCC inlines the process bodies
#    and the loop outgrows the XIP cache core0 shares, so this pays off only with the
#    `.time_critical` attribute in sp_runtime.h -- do not remove it.

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

# CC value normalization. One window for every parameter: CC 0..120 maps to 0.0..1.0, and
# CC 121..127 clamp at the destination. Every lookup table in the synth is spaced to match --
# FREQ_TABLE is semitone-spaced across 120, and EXP_TABLE and Q_TABLE are re-spaced to 121 entries
# over their unchanged ranges -- so a CC value lands on an integer table index with no
# interpolation error, and CC 60 is the exact mid-value of each.
# The bipolar form is `(v - 64) / 120`: -0.5..+0.5 over CC 4..124, centred on the detent a MIDI
# controller puts at 64. Nothing needs it yet, so it is not written.
# What a value means -- dimensionless or semitones -- stays a property of the destination, so
# reassigning which CC a parameter reads cannot change what the value means.
def cc_to_unipolar(value)
  value.to_f * (1.0 / 120.0)
end

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

# Signal routing, and which module output is the final (mono, for now) audio output. Plain Integer
# locals, so they can be reassigned once per buffer without touching the per-sample dispatch.
filter_audio_source = SRC_OSCILLATOR_OUTPUT
filter_mod_source   = SRC_ENV_GEN_OUTPUT
amp_audio_source    = SRC_FILTER_OUTPUT
amp_mod_source      = SRC_ENV_GEN_OUTPUT
output_source       = SRC_AMP_OUTPUT

# Which CC each parameter reads. Plain Integer locals like the routing above, so they can be
# reassigned once per buffer without touching the per-sample path.
cc_oscillator_waveform = 20
cc_filter_cutoff       = 74
cc_filter_resonance    = 71
cc_filter_mod_amount   = 24
cc_amp_gain            = 15
cc_env_gen_attack      = 73
cc_env_gen_decay       = 75
cc_env_gen_sustain     = 30

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# Module outputs carried across buffer boundaries. Touched twice per buffer, never per sample.
signals = Array.new(SIGNALS_SIZE, 0.0)

C.set_midi_cc_value(MIDI_CH, 20 , 0  ) # Oscillator Waveform
C.set_midi_cc_value(MIDI_CH, 74 , 120) # Filter Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 60 ) # Filter Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 60 ) # Filter EG Amt
C.set_midi_cc_value(MIDI_CH, 15 , 90 ) # Amp Gain
C.set_midi_cc_value(MIDI_CH, 73 , 0  ) # EG Attack
C.set_midi_cc_value(MIDI_CH, 75 , 90 ) # EG Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 0  ) # EG Sustain

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  pitch = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  gate = C.get_midi_note_on_state(MIDI_CH).to_f

  oscillator.set_waveform(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_oscillator_waveform)))
  filter.set_cutoff(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_cutoff)))
  filter.set_resonance(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_resonance)))
  filter.set_modulation_amount(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_mod_amount)))
  amp.set_gain(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_amp_gain)))
  env_gen.set_attack(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_attack)))
  env_gen.set_decay(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_decay)))
  env_gen.set_sustain(cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_sustain)))

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
