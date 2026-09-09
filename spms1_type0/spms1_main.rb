require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'

# Two structural choices, referred to below as notes 1-2. What they say about the generated C
# holds for the Spinel version vendored in sp_runtime.h; re-check on updating it.
#
# 1) active_modules is walked by a plain while loop, not .each: breaking out of a block needs
#    setjmp, while a plain break compiles to a C break.
#
# 2) Module outputs live in the `signals` array and routing is an index into it, so a routed
#    input costs one array read whatever the module count. Passing the candidates in as
#    arguments instead costs picks x candidates per sample, which grows quadratically.

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

# Slots of the `signals` bus: module outputs, control values and the note inputs, in one
# namespace, so a routing is just a slot number -- see note 2 -- and one source can feed as many
# destinations as read its slot. A slot is a plain float; its range is whatever the destination
# expects. Append new slots at the end: the numbers are arbitrary and nothing depends on order.
SIGNAL_ENV_GEN_OUTPUT      = 0
SIGNAL_OSCILLATOR_OUTPUT   = 1
SIGNAL_FILTER_OUTPUT       = 2
SIGNAL_AMP_OUTPUT          = 3
SIGNAL_OSCILLATOR_WAVEFORM = 4
SIGNAL_FILTER_CUTOFF       = 5
SIGNAL_FILTER_RESONANCE    = 6
SIGNAL_FILTER_MOD_AMOUNT   = 7
SIGNAL_AMP_GAIN            = 8
SIGNAL_ENV_GEN_ATTACK      = 9
SIGNAL_ENV_GEN_DECAY       = 10
SIGNAL_ENV_GEN_SUSTAIN     = 11
SIGNAL_PITCH               = 12
SIGNAL_GATE                = 13

SIGNALS_SIZE = 14

# CC value normalization. Every parameter is a ratio in 0.0..1.0, so this is the only converter:
# CC 4..124 maps to the full range, centred on CC 64 where a MIDI controller puts its detent, and
# anything outside is clamped here. Every lookup table in the synth is spaced to match --
# FREQ_TABLE is semitone-spaced across 120, and EXP_TABLE and Q_TABLE are 121 entries over their
# ranges -- so a CC value lands on an integer table index with no interpolation error, and CC 64
# is the exact mid-value of each.
# What a ratio means -- dimensionless, semitones, seconds -- stays a property of the destination,
# so reassigning which CC a parameter reads cannot change what the value means.
def cc_to_ratio(value)
  scaled = (value.to_f - 4.0) * (1.0 / 120.0)
  (scaled < 0.0) ? 0.0 : ((scaled > 1.0) ? 1.0 : scaled)
end

oscillator = Oscillator.new(SAMPLE_RATE)
filter = Filter.new(SAMPLE_RATE)
amp = Amp.new(SAMPLE_RATE)
env_gen = EnvGen.new(SAMPLE_RATE)

# Allocated once; which slots are filled is decided per buffer, inside the loop.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)

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

# The signal bus: each module's latest output, in its SIGNAL_* slot. Declared out here so it
# carries across buffers, since a routing with feedback reads last sample's value and at a buffer
# edge that is the previous iteration's.
signals = Array.new(SIGNALS_SIZE, 0.0)

C.set_midi_cc_value(MIDI_CH, 20 , 4  ) # Oscillator Waveform
C.set_midi_cc_value(MIDI_CH, 74 , 124) # Filter Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter EG Amt
C.set_midi_cc_value(MIDI_CH, 15 , 94 ) # Amp Gain
C.set_midi_cc_value(MIDI_CH, 73 , 4  ) # EG Attack
C.set_midi_cc_value(MIDI_CH, 75 , 94 ) # EG Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 4  ) # EG Sustain

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  signals[SIGNAL_PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_GATE]  = C.get_midi_note_on_state(MIDI_CH).to_f

  # The patch -- which modules run and in what order, and what feeds each routed input -- is
  # rebuilt every buffer so it can come from MIDI later. Constant for now. active_modules is
  # packed from the front with no gaps, see note 1; source_* hold SIGNAL_* bus slots, see note 2.
  active_modules[0] = MODULE_ENV_GEN
  active_modules[1] = MODULE_OSCILLATOR
  active_modules[2] = MODULE_FILTER
  active_modules[3] = MODULE_AMP

  source_env_gen_gate     = SIGNAL_GATE
  source_oscillator_pitch = SIGNAL_PITCH
  source_filter_audio     = SIGNAL_OSCILLATOR_OUTPUT
  source_filter_mod       = SIGNAL_ENV_GEN_OUTPUT
  source_amp_audio        = SIGNAL_FILTER_OUTPUT
  source_amp_mod          = SIGNAL_ENV_GEN_OUTPUT
  source_output           = SIGNAL_AMP_OUTPUT

  signals[SIGNAL_OSCILLATOR_WAVEFORM] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_oscillator_waveform))
  signals[SIGNAL_FILTER_CUTOFF]       = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_cutoff))
  signals[SIGNAL_FILTER_RESONANCE]    = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_resonance))
  signals[SIGNAL_FILTER_MOD_AMOUNT]   = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_mod_amount))
  signals[SIGNAL_AMP_GAIN]            = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_amp_gain))
  signals[SIGNAL_ENV_GEN_ATTACK]      = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_attack))
  signals[SIGNAL_ENV_GEN_DECAY]       = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_decay))
  signals[SIGNAL_ENV_GEN_SUSTAIN]     = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_sustain))

  oscillator.set_waveform(signals[SIGNAL_OSCILLATOR_WAVEFORM])
  filter.set_cutoff(signals[SIGNAL_FILTER_CUTOFF])
  filter.set_resonance(signals[SIGNAL_FILTER_RESONANCE])
  filter.set_modulation_amount(signals[SIGNAL_FILTER_MOD_AMOUNT])
  amp.set_gain(signals[SIGNAL_AMP_GAIN])
  env_gen.set_attack(signals[SIGNAL_ENV_GEN_ATTACK])
  env_gen.set_decay(signals[SIGNAL_ENV_GEN_DECAY])
  env_gen.set_sustain(signals[SIGNAL_ENV_GEN_SUSTAIN])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      case module_id
      when MODULE_ENV_GEN
        signals[SIGNAL_ENV_GEN_OUTPUT] = env_gen.process(signals[source_env_gen_gate])
      when MODULE_OSCILLATOR
        signals[SIGNAL_OSCILLATOR_OUTPUT] = oscillator.process(signals[source_oscillator_pitch])
      when MODULE_FILTER
        signals[SIGNAL_FILTER_OUTPUT] = filter.process(signals[source_filter_audio], signals[source_filter_mod])
      when MODULE_AMP
        signals[SIGNAL_AMP_OUTPUT] = amp.process(signals[source_amp_audio], signals[source_amp_mod])
      end

      slot += 1
    end

    audio_buffer[i] = signals[source_output]
    i += 1
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
