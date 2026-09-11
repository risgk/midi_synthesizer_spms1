require_relative 'spms1_osc'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_lfo'

# The patch is data: which modules run and in what order, what feeds each module input, where each
# parameter takes its value, and which CC fills each control slot all live in the NRPN table, read
# back every buffer so that MIDI can rewire the synth while it runs. README lists the numbers a
# controller sends. Two invariants the code leans on:
#
# - Every entry is 7-bit and every 7-bit value is legal, so nothing read back is validated. An
#   unknown module id falls through the dispatch, and any slot number is a real slot because the
#   bus is 128 wide.
# - Module inputs are read per sample and reach their module unsmoothed; parameters are read once
#   per buffer and are smoothed by the module receiving them. Which of the two a signal arrives
#   through is what decides how fast it is allowed to move.
#
# Claims below about the generated C hold for the Spinel version vendored in sp_runtime.h.
# Re-check them on updating it.

module Spms1
  module C
    ffi_func :set_midi_note_on_pitch, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_pitch, [:uint8],                 :uint8
    ffi_func :set_midi_note_on_state, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_state, [:uint8],                 :uint8
    ffi_func :set_midi_cc_value,      [:uint8, :uint8, :uint8], :void
    ffi_func :get_midi_cc_value,      [:uint8, :uint8],         :uint8
    ffi_func :set_midi_nrpn_value,    [:uint8, :int32, :uint8], :void
    ffi_func :get_midi_nrpn_value,    [:uint8, :int32],         :uint8
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
SAMPLE_RATE        = 48000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

# How many modules a patch can chain, and so the range of NRPN category 0. Every slot is rewritten
# from NRPN each buffer, so nothing needs a terminator: a shorter patch stops at the first
# MODULE_NONE, which is what an unset NRPN entry reads as. Only the rewriting is paid for the full
# length; the per-sample walk stops at that first MODULE_NONE.
MODULES_SIZE = 32

# Two instances of every type. They are separate module ids rather than one id and an instance
# number, so the dispatch stays a flat compare chain with nothing to index. Instance 2 of each ships
# with no CC assigned and nothing routed to it -- see the default patch below.
MODULE_NONE      = 0
MODULE_ENV_GEN_1 = 1
MODULE_ENV_GEN_2 = 2
MODULE_LFO_1     = 3
MODULE_LFO_2     = 4
MODULE_OSC_1     = 5
MODULE_OSC_2     = 6
MODULE_FILTER_1  = 7
MODULE_FILTER_2  = 8
MODULE_AMP_1     = 9
MODULE_AMP_2     = 10

# Slots of the `signals` bus: module outputs, control values and the note inputs in one namespace,
# so a routing is just a slot number and one source can feed as many destinations as read its
# slot. A slot is a plain float; its range is whatever the destination expects. Indexing an array
# is what holds a routed input to one read whatever the module count: passing the candidates in as
# arguments instead costs picks x candidates per sample, which grows quadratically.
# Nothing in the code depends on the numbering and a patch is never saved, so the order is for the
# reader alone and regrouping it costs only a documentation update.
# The constants come first so that SIGNAL_NONE is 0: an NRPN entry nobody has set reads 0, and an
# unrouted input should be silent rather than wired to whatever happens to sit in slot 0. Nothing
# ever writes them, so they hold what the bus was filled with at startup. They are what a routing
# reaches for when an input wants a fixed value rather than a source.
SIGNAL_NONE                = 0
SIGNAL_ONE                 = 1
SIGNAL_HALF                = 2
SIGNAL_MINUS_HALF          = 3
SIGNAL_MINUS_ONE           = 4

SIGNAL_ENV_GEN_1_OUTPUT    = 5
SIGNAL_ENV_GEN_2_OUTPUT    = 6
SIGNAL_LFO_1_OUTPUT        = 7
SIGNAL_LFO_2_OUTPUT        = 8
SIGNAL_OSC_1_OUTPUT        = 9
SIGNAL_OSC_2_OUTPUT        = 10
SIGNAL_FILTER_1_OUTPUT     = 11
SIGNAL_FILTER_2_OUTPUT     = 12
SIGNAL_AMP_1_OUTPUT        = 13
SIGNAL_AMP_2_OUTPUT        = 14

SIGNAL_OSC_1_WAVEFORM      = 15
SIGNAL_OSC_1_MOD_AMOUNT    = 16
SIGNAL_OSC_1_COARSE_TUNE   = 17
SIGNAL_OSC_1_FINE_TUNE     = 18
SIGNAL_OSC_2_WAVEFORM      = 19
SIGNAL_OSC_2_MOD_AMOUNT    = 20
SIGNAL_OSC_2_COARSE_TUNE   = 21
SIGNAL_OSC_2_FINE_TUNE     = 22
SIGNAL_FILTER_1_CUTOFF     = 23
SIGNAL_FILTER_1_RESONANCE  = 24
SIGNAL_FILTER_1_MOD_AMOUNT = 25
SIGNAL_FILTER_1_GAIN       = 26
SIGNAL_FILTER_2_CUTOFF     = 27
SIGNAL_FILTER_2_RESONANCE  = 28
SIGNAL_FILTER_2_MOD_AMOUNT = 29
SIGNAL_FILTER_2_GAIN       = 30
SIGNAL_AMP_1_GAIN          = 31
SIGNAL_AMP_2_GAIN          = 32
SIGNAL_ENV_GEN_1_ATTACK    = 33
SIGNAL_ENV_GEN_1_DECAY     = 34
SIGNAL_ENV_GEN_1_SUSTAIN   = 35
SIGNAL_ENV_GEN_2_ATTACK    = 36
SIGNAL_ENV_GEN_2_DECAY     = 37
SIGNAL_ENV_GEN_2_SUSTAIN   = 38
SIGNAL_LFO_1_RATE          = 39
SIGNAL_LFO_2_RATE          = 40

SIGNAL_PITCH               = 41
SIGNAL_GATE                = 42

SIGNALS_SIZE = 128

# Where a control slot's value goes when its parameter has no CC assigned. Nothing reads this slot.
# It exists so that filling the control slots is one array write either way: see cc_slot.
SIGNAL_SINK = SIGNALS_SIZE - 1

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_ENV_GEN_1_GATE  = 128
NRPN_SOURCE_ENV_GEN_2_GATE  = 129
NRPN_SOURCE_OSC_1_PITCH     = 130
NRPN_SOURCE_OSC_1_MOD       = 131
NRPN_SOURCE_OSC_2_PITCH     = 132
NRPN_SOURCE_OSC_2_MOD       = 133
NRPN_SOURCE_FILTER_1_AUDIO  = 134
NRPN_SOURCE_FILTER_1_MOD    = 135
NRPN_SOURCE_FILTER_2_AUDIO  = 136
NRPN_SOURCE_FILTER_2_MOD    = 137
NRPN_SOURCE_AMP_1_AUDIO     = 138
NRPN_SOURCE_AMP_1_MOD       = 139
NRPN_SOURCE_AMP_2_AUDIO     = 140
NRPN_SOURCE_AMP_2_MOD       = 141
NRPN_SOURCE_OUTPUT          = 142

NRPN_SOURCE_OSC_1_WAVEFORM      = 256
NRPN_SOURCE_OSC_1_MOD_AMOUNT    = 257
NRPN_SOURCE_OSC_1_COARSE_TUNE   = 258
NRPN_SOURCE_OSC_1_FINE_TUNE     = 259
NRPN_SOURCE_OSC_2_WAVEFORM      = 260
NRPN_SOURCE_OSC_2_MOD_AMOUNT    = 261
NRPN_SOURCE_OSC_2_COARSE_TUNE   = 262
NRPN_SOURCE_OSC_2_FINE_TUNE     = 263
NRPN_SOURCE_FILTER_1_CUTOFF     = 264
NRPN_SOURCE_FILTER_1_RESONANCE  = 265
NRPN_SOURCE_FILTER_1_MOD_AMOUNT = 266
NRPN_SOURCE_FILTER_1_GAIN       = 267
NRPN_SOURCE_FILTER_2_CUTOFF     = 268
NRPN_SOURCE_FILTER_2_RESONANCE  = 269
NRPN_SOURCE_FILTER_2_MOD_AMOUNT = 270
NRPN_SOURCE_FILTER_2_GAIN       = 271
NRPN_SOURCE_AMP_1_GAIN          = 272
NRPN_SOURCE_AMP_2_GAIN          = 273
NRPN_SOURCE_ENV_GEN_1_ATTACK    = 274
NRPN_SOURCE_ENV_GEN_1_DECAY     = 275
NRPN_SOURCE_ENV_GEN_1_SUSTAIN   = 276
NRPN_SOURCE_ENV_GEN_2_ATTACK    = 277
NRPN_SOURCE_ENV_GEN_2_DECAY     = 278
NRPN_SOURCE_ENV_GEN_2_SUSTAIN   = 279
NRPN_SOURCE_LFO_1_RATE          = 280
NRPN_SOURCE_LFO_2_RATE          = 281

# A CC number of 0 means the parameter has no CC: its control slot keeps whatever it holds, so the
# parameter can be driven by routing alone. A parameter shipped that way wants its slot seeded
# below, unless 0.0 is the value it should rest at. Every instance-2 parameter ships that way.
NRPN_CC_OSC_1_WAVEFORM      = 384
NRPN_CC_OSC_1_MOD_AMOUNT    = 385
NRPN_CC_OSC_1_COARSE_TUNE   = 386
NRPN_CC_OSC_1_FINE_TUNE     = 387
NRPN_CC_OSC_2_WAVEFORM      = 388
NRPN_CC_OSC_2_MOD_AMOUNT    = 389
NRPN_CC_OSC_2_COARSE_TUNE   = 390
NRPN_CC_OSC_2_FINE_TUNE     = 391
NRPN_CC_FILTER_1_CUTOFF     = 392
NRPN_CC_FILTER_1_RESONANCE  = 393
NRPN_CC_FILTER_1_MOD_AMOUNT = 394
NRPN_CC_FILTER_1_GAIN       = 395
NRPN_CC_FILTER_2_CUTOFF     = 396
NRPN_CC_FILTER_2_RESONANCE  = 397
NRPN_CC_FILTER_2_MOD_AMOUNT = 398
NRPN_CC_FILTER_2_GAIN       = 399
NRPN_CC_AMP_1_GAIN          = 400
NRPN_CC_AMP_2_GAIN          = 401
NRPN_CC_ENV_GEN_1_ATTACK    = 402
NRPN_CC_ENV_GEN_1_DECAY     = 403
NRPN_CC_ENV_GEN_1_SUSTAIN   = 404
NRPN_CC_ENV_GEN_2_ATTACK    = 405
NRPN_CC_ENV_GEN_2_DECAY     = 406
NRPN_CC_ENV_GEN_2_SUSTAIN   = 407
NRPN_CC_LFO_1_RATE          = 408
NRPN_CC_LFO_2_RATE          = 409

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

# Which slot a control value is written to. CC number 0 means no CC is assigned, and the value is
# sent to SIGNAL_SINK so the parameter's own slot keeps what it already holds. Selecting the
# destination rather than skipping the write keeps the cost the same whatever the patch says.
def cc_slot(cc_number, slot)
  (cc_number == 0) ? SIGNAL_SINK : slot
end

osc_1     = Osc.new(SAMPLE_RATE)
osc_2     = Osc.new(SAMPLE_RATE)
filter_1  = Filter.new(SAMPLE_RATE)
filter_2  = Filter.new(SAMPLE_RATE)
amp_1     = Amp.new(SAMPLE_RATE)
amp_2     = Amp.new(SAMPLE_RATE)
env_gen_1 = EnvGen.new(SAMPLE_RATE)
env_gen_2 = EnvGen.new(SAMPLE_RATE)
lfo_1     = LFO.new(SAMPLE_RATE)
lfo_2     = LFO.new(SAMPLE_RATE)

# Allocated once; which slots are filled is decided per buffer, inside the loop.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# The signal bus: each module's latest output, in its SIGNAL_* slot. Declared out here so it
# carries across buffers, since a routing with feedback reads last sample's value and at a buffer
# edge that is the previous iteration's.
signals = Array.new(SIGNALS_SIZE, 0.0)
signals[SIGNAL_ONE]        =  1.0
signals[SIGNAL_HALF]       =  0.5
signals[SIGNAL_MINUS_HALF] = -0.5
signals[SIGNAL_MINUS_ONE]  = -1.0

# Instance 2 has no CC on any parameter, so nothing ever writes these slots and they keep what is
# put here. They are seeded with the values instance 1's CCs default to, so a second module wired
# into a patch behaves like the first one rather than starting silent or five octaves flat.
# Instance 1 needs none of this: its slots are overwritten from MIDI on the first buffer.
signals[SIGNAL_OSC_2_WAVEFORM]      = cc_to_ratio(4)
signals[SIGNAL_OSC_2_MOD_AMOUNT]    = cc_to_ratio(4)
signals[SIGNAL_OSC_2_COARSE_TUNE]   = cc_to_ratio(64)
signals[SIGNAL_OSC_2_FINE_TUNE]     = cc_to_ratio(64)
signals[SIGNAL_FILTER_2_CUTOFF]     = cc_to_ratio(124)
signals[SIGNAL_FILTER_2_RESONANCE]  = cc_to_ratio(64)
signals[SIGNAL_FILTER_2_MOD_AMOUNT] = cc_to_ratio(64)
signals[SIGNAL_FILTER_2_GAIN]       = cc_to_ratio(64)
signals[SIGNAL_AMP_2_GAIN]          = cc_to_ratio(64)
signals[SIGNAL_ENV_GEN_2_ATTACK]    = cc_to_ratio(4)
signals[SIGNAL_ENV_GEN_2_DECAY]     = cc_to_ratio(94)
signals[SIGNAL_ENV_GEN_2_SUSTAIN]   = cc_to_ratio(4)
signals[SIGNAL_LFO_2_RATE]          = cc_to_ratio(64)

# The default patch, written into the NRPN table the loop reads it back from. Slots left at 0
# read as MODULE_NONE, so active_modules needs only the five it uses. Instance 2 of every type is
# left out of the run order, with nothing routed to it and no CC on its parameters.
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_ENV_GEN_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_LFO_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_OSC_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_FILTER_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_AMP_1)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE , SIGNAL_GATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD      , SIGNAL_LFO_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_OSC_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD   , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT         , SIGNAL_AMP_1_OUTPUT)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_WAVEFORM     , SIGNAL_OSC_1_WAVEFORM)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_AMOUNT   , SIGNAL_OSC_1_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_COARSE_TUNE  , SIGNAL_OSC_1_COARSE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_FINE_TUNE    , SIGNAL_OSC_1_FINE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_WAVEFORM     , SIGNAL_OSC_2_WAVEFORM)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_AMOUNT   , SIGNAL_OSC_2_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_COARSE_TUNE  , SIGNAL_OSC_2_COARSE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_FINE_TUNE    , SIGNAL_OSC_2_FINE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_CUTOFF    , SIGNAL_FILTER_1_CUTOFF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_RESONANCE , SIGNAL_FILTER_1_RESONANCE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_AMOUNT, SIGNAL_FILTER_1_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_GAIN      , SIGNAL_FILTER_1_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_CUTOFF    , SIGNAL_FILTER_2_CUTOFF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_RESONANCE , SIGNAL_FILTER_2_RESONANCE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_MOD_AMOUNT, SIGNAL_FILTER_2_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_GAIN      , SIGNAL_FILTER_2_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_GAIN         , SIGNAL_AMP_1_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_2_GAIN         , SIGNAL_AMP_2_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_ATTACK   , SIGNAL_ENV_GEN_1_ATTACK)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_DECAY    , SIGNAL_ENV_GEN_1_DECAY)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_SUSTAIN  , SIGNAL_ENV_GEN_1_SUSTAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_ATTACK   , SIGNAL_ENV_GEN_2_ATTACK)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_DECAY    , SIGNAL_ENV_GEN_2_DECAY)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_SUSTAIN  , SIGNAL_ENV_GEN_2_SUSTAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE         , SIGNAL_LFO_1_RATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_2_RATE         , SIGNAL_LFO_2_RATE)

C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_WAVEFORM     , 20)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_AMOUNT   , 13)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_COARSE_TUNE  , 86)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_FINE_TUNE    , 70)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_CUTOFF    , 74)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_RESONANCE , 71)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_AMOUNT, 24)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_GAIN      , 112)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_1_GAIN         , 15)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_ATTACK   , 73)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_DECAY    , 75)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_SUSTAIN  , 30)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE         , 3)

C.set_midi_cc_value(MIDI_CH, 20 , 4  ) # Osc 1 Wave
C.set_midi_cc_value(MIDI_CH, 13 , 4  ) # Osc 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 86 , 64 ) # Osc 1 Coarse Tune
C.set_midi_cc_value(MIDI_CH, 70 , 64 ) # Osc 1 Fine Tune
C.set_midi_cc_value(MIDI_CH, 74 , 124) # Filter 1 Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter 1 Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 112, 64 ) # Filter 1 Gain
C.set_midi_cc_value(MIDI_CH, 15 , 64 ) # Amp 1 Gain
C.set_midi_cc_value(MIDI_CH, 73 , 4  ) # EG 1 Attack
C.set_midi_cc_value(MIDI_CH, 75 , 94 ) # EG 1 Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 4  ) # EG 1 Sustain
C.set_midi_cc_value(MIDI_CH, 3  , 64 ) # LFO 1 Rate

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  signals[SIGNAL_PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_GATE]  = C.get_midi_note_on_state(MIDI_CH).to_f

  # The patch, read back from the NRPN table. active_modules is packed from the front with no
  # gaps; every source_* holds a SIGNAL_* bus slot.
  slot = 0
  while slot < MODULES_SIZE
    active_modules[slot] = C.get_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + slot)
    slot += 1
  end

  source_env_gen_1_gate = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE)
  source_env_gen_2_gate = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_GATE)
  source_osc_1_pitch    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH)
  source_osc_1_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD)
  source_osc_2_pitch    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PITCH)
  source_osc_2_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD)
  source_filter_1_audio = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO)
  source_filter_1_mod   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD)
  source_filter_2_audio = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_AUDIO)
  source_filter_2_mod   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_MOD)
  source_amp_1_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO)
  source_amp_1_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD)
  source_amp_2_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_2_AUDIO)
  source_amp_2_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_2_MOD)
  source_output         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT)

  # Parameter sources. Read once per buffer rather than per sample: each destination smooths at
  # the control rate with a 2.67 ms time constant, which swallows the difference between feeding
  # it at 48 kHz and at the 750 Hz buffer rate. Faster modulation goes through the module inputs
  # above, which are read per sample and not smoothed.
  source_osc_1_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_WAVEFORM)
  source_osc_1_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_AMOUNT)
  source_osc_1_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_COARSE_TUNE)
  source_osc_1_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_FINE_TUNE)
  source_osc_2_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_WAVEFORM)
  source_osc_2_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_AMOUNT)
  source_osc_2_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_COARSE_TUNE)
  source_osc_2_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_FINE_TUNE)
  source_filter_1_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_CUTOFF)
  source_filter_1_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_RESONANCE)
  source_filter_1_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_AMOUNT)
  source_filter_1_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_GAIN)
  source_filter_2_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_CUTOFF)
  source_filter_2_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_RESONANCE)
  source_filter_2_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_MOD_AMOUNT)
  source_filter_2_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_2_GAIN)
  source_amp_1_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_GAIN)
  source_amp_2_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_2_GAIN)
  source_env_gen_1_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_ATTACK)
  source_env_gen_1_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_DECAY)
  source_env_gen_1_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_SUSTAIN)
  source_env_gen_2_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_ATTACK)
  source_env_gen_2_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_DECAY)
  source_env_gen_2_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_2_SUSTAIN)
  source_lfo_1_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE)
  source_lfo_2_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_2_RATE)

  # Which CC fills each control slot. The bus is the only thing downstream reads, so this is
  # where MIDI enters and the only place a CC number appears.
  cc_osc_1_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_WAVEFORM)
  cc_osc_1_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_AMOUNT)
  cc_osc_1_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_COARSE_TUNE)
  cc_osc_1_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_FINE_TUNE)
  cc_osc_2_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_WAVEFORM)
  cc_osc_2_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_MOD_AMOUNT)
  cc_osc_2_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_COARSE_TUNE)
  cc_osc_2_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_FINE_TUNE)
  cc_filter_1_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_CUTOFF)
  cc_filter_1_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_RESONANCE)
  cc_filter_1_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_AMOUNT)
  cc_filter_1_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_GAIN)
  cc_filter_2_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_2_CUTOFF)
  cc_filter_2_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_2_RESONANCE)
  cc_filter_2_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_2_MOD_AMOUNT)
  cc_filter_2_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_2_GAIN)
  cc_amp_1_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_1_GAIN)
  cc_amp_2_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_2_GAIN)
  cc_env_gen_1_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_ATTACK)
  cc_env_gen_1_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_DECAY)
  cc_env_gen_1_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_SUSTAIN)
  cc_env_gen_2_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_2_ATTACK)
  cc_env_gen_2_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_2_DECAY)
  cc_env_gen_2_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_2_SUSTAIN)
  cc_lfo_1_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE)
  cc_lfo_2_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_2_RATE)

  signals[cc_slot(cc_osc_1_waveform, SIGNAL_OSC_1_WAVEFORM)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_1_waveform))
  signals[cc_slot(cc_osc_1_mod_amount, SIGNAL_OSC_1_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_amount))
  signals[cc_slot(cc_osc_1_coarse_tune, SIGNAL_OSC_1_COARSE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_1_coarse_tune))
  signals[cc_slot(cc_osc_1_fine_tune, SIGNAL_OSC_1_FINE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_1_fine_tune))
  signals[cc_slot(cc_osc_2_waveform, SIGNAL_OSC_2_WAVEFORM)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_2_waveform))
  signals[cc_slot(cc_osc_2_mod_amount, SIGNAL_OSC_2_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_2_mod_amount))
  signals[cc_slot(cc_osc_2_coarse_tune, SIGNAL_OSC_2_COARSE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_2_coarse_tune))
  signals[cc_slot(cc_osc_2_fine_tune, SIGNAL_OSC_2_FINE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_2_fine_tune))
  signals[cc_slot(cc_filter_1_cutoff, SIGNAL_FILTER_1_CUTOFF)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_1_cutoff))
  signals[cc_slot(cc_filter_1_resonance, SIGNAL_FILTER_1_RESONANCE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_1_resonance))
  signals[cc_slot(cc_filter_1_mod_amount, SIGNAL_FILTER_1_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_amount))
  signals[cc_slot(cc_filter_1_gain, SIGNAL_FILTER_1_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_1_gain))
  signals[cc_slot(cc_filter_2_cutoff, SIGNAL_FILTER_2_CUTOFF)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_2_cutoff))
  signals[cc_slot(cc_filter_2_resonance, SIGNAL_FILTER_2_RESONANCE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_2_resonance))
  signals[cc_slot(cc_filter_2_mod_amount, SIGNAL_FILTER_2_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_2_mod_amount))
  signals[cc_slot(cc_filter_2_gain, SIGNAL_FILTER_2_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_2_gain))
  signals[cc_slot(cc_amp_1_gain, SIGNAL_AMP_1_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_amp_1_gain))
  signals[cc_slot(cc_amp_2_gain, SIGNAL_AMP_2_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_amp_2_gain))
  signals[cc_slot(cc_env_gen_1_attack, SIGNAL_ENV_GEN_1_ATTACK)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_attack))
  signals[cc_slot(cc_env_gen_1_decay, SIGNAL_ENV_GEN_1_DECAY)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_decay))
  signals[cc_slot(cc_env_gen_1_sustain, SIGNAL_ENV_GEN_1_SUSTAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_sustain))
  signals[cc_slot(cc_env_gen_2_attack, SIGNAL_ENV_GEN_2_ATTACK)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_2_attack))
  signals[cc_slot(cc_env_gen_2_decay, SIGNAL_ENV_GEN_2_DECAY)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_2_decay))
  signals[cc_slot(cc_env_gen_2_sustain, SIGNAL_ENV_GEN_2_SUSTAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_2_sustain))
  signals[cc_slot(cc_lfo_1_rate, SIGNAL_LFO_1_RATE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate))
  signals[cc_slot(cc_lfo_2_rate, SIGNAL_LFO_2_RATE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_lfo_2_rate))

  osc_1.set_waveform(signals[source_osc_1_waveform])
  osc_1.set_modulation_amount(signals[source_osc_1_mod_amount])
  osc_1.set_coarse_tune(signals[source_osc_1_coarse_tune])
  osc_1.set_fine_tune(signals[source_osc_1_fine_tune])
  osc_2.set_waveform(signals[source_osc_2_waveform])
  osc_2.set_modulation_amount(signals[source_osc_2_mod_amount])
  osc_2.set_coarse_tune(signals[source_osc_2_coarse_tune])
  osc_2.set_fine_tune(signals[source_osc_2_fine_tune])
  filter_1.set_cutoff(signals[source_filter_1_cutoff])
  filter_1.set_resonance(signals[source_filter_1_resonance])
  filter_1.set_modulation_amount(signals[source_filter_1_mod_amount])
  filter_1.set_gain(signals[source_filter_1_gain])
  filter_2.set_cutoff(signals[source_filter_2_cutoff])
  filter_2.set_resonance(signals[source_filter_2_resonance])
  filter_2.set_modulation_amount(signals[source_filter_2_mod_amount])
  filter_2.set_gain(signals[source_filter_2_gain])
  amp_1.set_gain(signals[source_amp_1_gain])
  amp_2.set_gain(signals[source_amp_2_gain])
  env_gen_1.set_attack(signals[source_env_gen_1_attack])
  env_gen_1.set_decay(signals[source_env_gen_1_decay])
  env_gen_1.set_sustain(signals[source_env_gen_1_sustain])
  env_gen_2.set_attack(signals[source_env_gen_2_attack])
  env_gen_2.set_decay(signals[source_env_gen_2_decay])
  env_gen_2.set_sustain(signals[source_env_gen_2_sustain])
  lfo_1.set_rate(signals[source_lfo_1_rate])
  lfo_2.set_rate(signals[source_lfo_2_rate])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      case module_id
      when MODULE_ENV_GEN_1
        signals[SIGNAL_ENV_GEN_1_OUTPUT] = env_gen_1.process(signals[source_env_gen_1_gate])
      when MODULE_ENV_GEN_2
        signals[SIGNAL_ENV_GEN_2_OUTPUT] = env_gen_2.process(signals[source_env_gen_2_gate])
      when MODULE_LFO_1
        signals[SIGNAL_LFO_1_OUTPUT] = lfo_1.process
      when MODULE_LFO_2
        signals[SIGNAL_LFO_2_OUTPUT] = lfo_2.process
      when MODULE_OSC_1
        signals[SIGNAL_OSC_1_OUTPUT] = osc_1.process(signals[source_osc_1_pitch], signals[source_osc_1_mod])
      when MODULE_OSC_2
        signals[SIGNAL_OSC_2_OUTPUT] = osc_2.process(signals[source_osc_2_pitch], signals[source_osc_2_mod])
      when MODULE_FILTER_1
        signals[SIGNAL_FILTER_1_OUTPUT] = filter_1.process(signals[source_filter_1_audio], signals[source_filter_1_mod])
      when MODULE_FILTER_2
        signals[SIGNAL_FILTER_2_OUTPUT] = filter_2.process(signals[source_filter_2_audio], signals[source_filter_2_mod])
      when MODULE_AMP_1
        signals[SIGNAL_AMP_1_OUTPUT] = amp_1.process(signals[source_amp_1_audio], signals[source_amp_1_mod])
      when MODULE_AMP_2
        signals[SIGNAL_AMP_2_OUTPUT] = amp_2.process(signals[source_amp_2_audio], signals[source_amp_2_mod])
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
