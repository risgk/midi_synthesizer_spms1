require_relative 'spms1_osc'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_lfo'
require_relative 'spms1_mixer'

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
# Claims below about the generated C hold for the Spinel version vendored in spinel_rt.h.
# Re-check them on updating it.

module Spms1
  module C
    ffi_func :set_midi_note_on_pitch, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_pitch, [:uint8],                 :uint8
    ffi_func :set_midi_note_on_state, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_state, [:uint8],                 :uint8
    ffi_func :set_midi_pitch_bend,    [:uint8, :int32],         :void
    ffi_func :get_midi_pitch_bend,    [:uint8],                 :int32
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

# One of every module type that makes a sound, and one mixer. Instances carry their number in
# the id rather than being indexed by one, so a second oscillator would be MODULE_OSC_2 sitting
# next to MODULE_OSC_1 here, and the numbering after it would shift.
MODULE_NONE      = 0
MODULE_LFO_1     = 1
MODULE_ENV_GEN_1 = 2
MODULE_OSC_1     = 3
MODULE_FILTER_1  = 4
MODULE_AMP_1     = 5
MODULE_MIXER_1   = 6

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
SIGNAL_POINT_TWO           = 3
SIGNAL_POINT_ONE           = 4
SIGNAL_MINUS_POINT_ONE     = 5
SIGNAL_MINUS_POINT_TWO     = 6
SIGNAL_MINUS_HALF          = 7
SIGNAL_MINUS_ONE           = 8

SIGNAL_LFO_1_OUTPUT        = 9
SIGNAL_ENV_GEN_1_OUTPUT    = 10
SIGNAL_OSC_1_OUTPUT        = 11
SIGNAL_FILTER_1_OUTPUT     = 12
SIGNAL_AMP_1_OUTPUT        = 13
SIGNAL_MIXER_1_OUTPUT      = 14

SIGNAL_LFO_1_RATE            = 15
SIGNAL_LFO_1_LEVEL           = 16
SIGNAL_LFO_1_POLARITY        = 17
SIGNAL_ENV_GEN_1_ATTACK      = 18
SIGNAL_ENV_GEN_1_DECAY       = 19
SIGNAL_ENV_GEN_1_SUSTAIN     = 20
SIGNAL_ENV_GEN_1_LEVEL       = 21
SIGNAL_ENV_GEN_1_POLARITY    = 22
SIGNAL_OSC_1_WAVEFORM        = 23
SIGNAL_OSC_1_COARSE_TUNE     = 24
SIGNAL_OSC_1_FINE_TUNE       = 25
SIGNAL_OSC_1_MOD_AMOUNT      = 26
SIGNAL_OSC_1_MOD_POLARITY    = 27
SIGNAL_FILTER_1_CUTOFF       = 28
SIGNAL_FILTER_1_RESONANCE    = 29
SIGNAL_FILTER_1_GAIN         = 30
SIGNAL_FILTER_1_MOD_AMOUNT   = 31
SIGNAL_FILTER_1_MOD_POLARITY = 32
SIGNAL_AMP_1_GAIN            = 33
SIGNAL_MIXER_1_LEVEL_1       = 34
SIGNAL_MIXER_1_POLARITY_1    = 35
SIGNAL_MIXER_1_LEVEL_2       = 36
SIGNAL_MIXER_1_POLARITY_2    = 37

SIGNAL_PITCH               = 38
SIGNAL_GATE                = 39
SIGNAL_BEND                = 40

# Control slots no parameter owns: each is a CC put on the bus for any input or parameter to read.
# The mod wheel first, unipolar and on CC 1, then four of each kind. The two kinds share General
# CCs 1-4, one CC filling a slot of each, so a knob can be taken either way without a mixer to
# shift it.
SIGNAL_GENERAL_MOD_WHEEL   = 41
SIGNAL_GENERAL_UNIPOLAR_1  = 42
SIGNAL_GENERAL_UNIPOLAR_2  = 43
SIGNAL_GENERAL_UNIPOLAR_3  = 44
SIGNAL_GENERAL_UNIPOLAR_4  = 45
SIGNAL_GENERAL_BIPOLAR_1   = 46
SIGNAL_GENERAL_BIPOLAR_2   = 47
SIGNAL_GENERAL_BIPOLAR_3   = 48
SIGNAL_GENERAL_BIPOLAR_4   = 49

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

NRPN_SOURCE_ENV_GEN_1_GATE = 128
NRPN_SOURCE_OSC_1_PITCH    = 129
NRPN_SOURCE_OSC_1_MOD      = 130
NRPN_SOURCE_FILTER_1_AUDIO = 131
NRPN_SOURCE_FILTER_1_MOD   = 132
NRPN_SOURCE_AMP_1_AUDIO    = 133
NRPN_SOURCE_AMP_1_MOD      = 134
NRPN_SOURCE_MIXER_1_IN_1   = 135
NRPN_SOURCE_MIXER_1_IN_2   = 136
NRPN_SOURCE_OUTPUT         = 137

NRPN_SOURCE_LFO_1_RATE            = 256
NRPN_SOURCE_LFO_1_LEVEL           = 257
NRPN_SOURCE_LFO_1_POLARITY        = 258
NRPN_SOURCE_ENV_GEN_1_ATTACK      = 259
NRPN_SOURCE_ENV_GEN_1_DECAY       = 260
NRPN_SOURCE_ENV_GEN_1_SUSTAIN     = 261
NRPN_SOURCE_ENV_GEN_1_LEVEL       = 262
NRPN_SOURCE_ENV_GEN_1_POLARITY    = 263
NRPN_SOURCE_OSC_1_WAVEFORM        = 264
NRPN_SOURCE_OSC_1_COARSE_TUNE     = 265
NRPN_SOURCE_OSC_1_FINE_TUNE       = 266
NRPN_SOURCE_OSC_1_MOD_AMOUNT      = 267
NRPN_SOURCE_OSC_1_MOD_POLARITY    = 268
NRPN_SOURCE_FILTER_1_CUTOFF       = 269
NRPN_SOURCE_FILTER_1_RESONANCE    = 270
NRPN_SOURCE_FILTER_1_GAIN         = 271
NRPN_SOURCE_FILTER_1_MOD_AMOUNT   = 272
NRPN_SOURCE_FILTER_1_MOD_POLARITY = 273
NRPN_SOURCE_AMP_1_GAIN            = 274
NRPN_SOURCE_MIXER_1_LEVEL_1       = 275
NRPN_SOURCE_MIXER_1_POLARITY_1    = 276
NRPN_SOURCE_MIXER_1_LEVEL_2       = 277
NRPN_SOURCE_MIXER_1_POLARITY_2    = 278

# A CC number of 0 means the parameter has no CC: its control slot keeps whatever it holds, so the
# parameter can be driven by routing alone. Nothing seeds a control slot, so one with no CC holds
# 0.0 -- the bottom of a unipolar dial, the middle of a bipolar one -- until a CC is assigned.
NRPN_CC_LFO_1_RATE            = 384
NRPN_CC_LFO_1_LEVEL           = 385
NRPN_CC_LFO_1_POLARITY        = 386
NRPN_CC_ENV_GEN_1_ATTACK      = 387
NRPN_CC_ENV_GEN_1_DECAY       = 388
NRPN_CC_ENV_GEN_1_SUSTAIN     = 389
NRPN_CC_ENV_GEN_1_LEVEL       = 390
NRPN_CC_ENV_GEN_1_POLARITY    = 391
NRPN_CC_OSC_1_WAVEFORM        = 392
NRPN_CC_OSC_1_COARSE_TUNE     = 393
NRPN_CC_OSC_1_FINE_TUNE       = 394
NRPN_CC_OSC_1_MOD_AMOUNT      = 395
NRPN_CC_OSC_1_MOD_POLARITY    = 396
NRPN_CC_FILTER_1_CUTOFF       = 397
NRPN_CC_FILTER_1_RESONANCE    = 398
NRPN_CC_FILTER_1_GAIN         = 399
NRPN_CC_FILTER_1_MOD_AMOUNT   = 400
NRPN_CC_FILTER_1_MOD_POLARITY = 401
NRPN_CC_AMP_1_GAIN            = 402
NRPN_CC_MIXER_1_LEVEL_1       = 403
NRPN_CC_MIXER_1_POLARITY_1    = 404
NRPN_CC_MIXER_1_LEVEL_2       = 405
NRPN_CC_MIXER_1_POLARITY_2    = 406
NRPN_CC_GENERAL_MOD_WHEEL     = 407
NRPN_CC_GENERAL_1             = 408
NRPN_CC_GENERAL_2             = 409
NRPN_CC_GENERAL_3             = 410
NRPN_CC_GENERAL_4             = 411

# CC value normalization. Each control slot is unipolar or bipolar, matching the range its
# parameter clamps to, and takes the converter of its kind: unipolar is 0.0..1.0, the span of an
# envelope, and bipolar is -0.5..0.5, the span of an LFO, with 0.0 at CC 64 where a MIDI
# controller puts its detent. The tune controls are bipolar, being offsets about that detent,
# and so are the polarities, whose sign is what they set. Both map CC 4..124 to the full range and
# clamp anything outside. Every lookup table in the synth is spaced to match --
# FREQ_TABLE is semitone-spaced across 120, and EXP_TABLE and Q_TABLE are 121 entries over their
# ranges -- so a CC value lands on an integer table index, and CC 64 is the exact mid-value of
# each.
# What a value means -- dimensionless, semitones, seconds -- stays a property of the destination,
# so reassigning which CC a parameter reads cannot change what the value means.
def cc_to_unipolar(value)
  scaled = (value.to_f - 4.0) * (1.0 / 120.0)
  (scaled < 0.0) ? 0.0 : ((scaled > 1.0) ? 1.0 : scaled)
end

def cc_to_bipolar(value)
  scaled = (value.to_f - 64.0) * (1.0 / 120.0)
  (scaled < -0.5) ? -0.5 : ((scaled > 0.5) ? 0.5 : scaled)
end

# Which slot a control value is written to. CC number 0 means no CC is assigned, and the value is
# sent to SIGNAL_SINK so the parameter's own slot keeps what it already holds. Selecting the
# destination rather than skipping the write keeps the cost the same whatever the patch says.
def cc_slot(cc_number, slot)
  (cc_number == 0) ? SIGNAL_SINK : slot
end

lfo_1     = LFO.new(SAMPLE_RATE)
env_gen_1 = EnvGen.new(SAMPLE_RATE)
osc_1     = Osc.new(SAMPLE_RATE)
filter_1  = Filter.new(SAMPLE_RATE)
amp_1     = Amp.new(SAMPLE_RATE)
mixer_1   = Mixer.new(SAMPLE_RATE)

# Allocated once; which slots are filled is decided per buffer, inside the loop.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# The signal bus: each module's latest output, in its SIGNAL_* slot. Declared out here so it
# carries across buffers, since a routing with feedback reads last sample's value and at a buffer
# edge that is the previous iteration's.
signals = Array.new(SIGNALS_SIZE, 0.0)
signals[SIGNAL_ONE]             =  1.0
signals[SIGNAL_HALF]            =  0.5
signals[SIGNAL_POINT_TWO]       =  0.2
signals[SIGNAL_POINT_ONE]       =  0.1
signals[SIGNAL_MINUS_POINT_ONE] = -0.1
signals[SIGNAL_MINUS_POINT_TWO] = -0.2
signals[SIGNAL_MINUS_HALF]      = -0.5
signals[SIGNAL_MINUS_ONE]       = -1.0

# The default patch, written into the NRPN table the loop reads it back from. Every module is in
# the run order, so a patch only ever has to route, never to switch something on first. The mixer
# runs after both modulation sources and ahead of the oscillator, so it sees this sample's LFO and
# envelope and can feed the oscillator, the filter and the amp without a sample's delay. The
# default patch leaves it unused: the LFO goes straight to the
# oscillator, and its own polarity reads the constant 0.1, which brings it down to a vibrato depth
# so that Osc Mod Amt can span the whole pitch range the way every other modulation depth does.
# A mixer's parameters have no CC, so the default patch points them at constants instead: full
# level and a polarity of +0.5, which makes a mixer pass its input through rather than mute it.
# Each modulation polarity has no CC either and reads +0.5, which leaves the amount in charge.
# LFO 1 Level has no CC either and reads 1.0. EG 1 Level and Polarity read 1.0 and +0.5, passing
# the envelope as it is.
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_LFO_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_ENV_GEN_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_MIXER_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_OSC_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_FILTER_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_AMP_1)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE , SIGNAL_GATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD      , SIGNAL_LFO_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_OSC_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD   , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT         , SIGNAL_AMP_1_OUTPUT)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE            , SIGNAL_LFO_1_RATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL           , SIGNAL_ONE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_POLARITY        , SIGNAL_POINT_ONE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_ATTACK      , SIGNAL_ENV_GEN_1_ATTACK)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_DECAY       , SIGNAL_ENV_GEN_1_DECAY)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_SUSTAIN     , SIGNAL_ENV_GEN_1_SUSTAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_LEVEL       , SIGNAL_ONE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_POLARITY    , SIGNAL_HALF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_WAVEFORM        , SIGNAL_OSC_1_WAVEFORM)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_COARSE_TUNE     , SIGNAL_OSC_1_COARSE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_FINE_TUNE       , SIGNAL_OSC_1_FINE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_AMOUNT      , SIGNAL_OSC_1_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_POLARITY    , SIGNAL_HALF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_CUTOFF       , SIGNAL_FILTER_1_CUTOFF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_RESONANCE    , SIGNAL_FILTER_1_RESONANCE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_GAIN         , SIGNAL_FILTER_1_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_AMOUNT   , SIGNAL_FILTER_1_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_POLARITY , SIGNAL_HALF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_GAIN            , SIGNAL_AMP_1_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_1       , SIGNAL_ONE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POLARITY_1    , SIGNAL_HALF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_2       , SIGNAL_ONE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POLARITY_2    , SIGNAL_HALF)

C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE          , 3)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_ATTACK    , 73)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_DECAY     , 75)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_SUSTAIN   , 30)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_WAVEFORM      , 20)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_COARSE_TUNE   , 86)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_FINE_TUNE     , 70)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_AMOUNT    , 13)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_CUTOFF     , 74)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_RESONANCE  , 71)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_GAIN       , 112)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_AMOUNT , 24)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_1_GAIN          , 15)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_MOD_WHEEL   , 1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_1           , 16)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_2           , 17)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_3           , 18)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_4           , 19)

C.set_midi_cc_value(MIDI_CH, 3  , 64 ) # LFO 1 Rate
C.set_midi_cc_value(MIDI_CH, 73 , 4  ) # EG 1 Attack
C.set_midi_cc_value(MIDI_CH, 75 , 100) # EG 1 Decay
C.set_midi_cc_value(MIDI_CH, 30 , 4  ) # EG 1 Sustain
C.set_midi_cc_value(MIDI_CH, 20 , 4  ) # Osc 1 Wave
C.set_midi_cc_value(MIDI_CH, 86 , 64 ) # Osc 1 Coarse Tune
C.set_midi_cc_value(MIDI_CH, 70 , 64 ) # Osc 1 Fine Tune
C.set_midi_cc_value(MIDI_CH, 13 , 4  ) # Osc 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 74 , 64 ) # Filter 1 Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 94 ) # Filter 1 Resonance
C.set_midi_cc_value(MIDI_CH, 112, 64 ) # Filter 1 Gain
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 15 , 64 ) # Amp 1 Gain
C.set_midi_cc_value(MIDI_CH, 1  , 4  ) # General Mod Wheel
# Each of these fills a unipolar and a bipolar slot at once, and CC 64 is the one value that puts
# neither at an end: the unipolar slot at 0.5, the bipolar at 0.0.
C.set_midi_cc_value(MIDI_CH, 16 , 64 ) # General 1
C.set_midi_cc_value(MIDI_CH, 17 , 64 ) # General 2
C.set_midi_cc_value(MIDI_CH, 18 , 64 ) # General 3
C.set_midi_cc_value(MIDI_CH, 19 , 64 ) # General 4

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  signals[SIGNAL_PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_GATE]  = C.get_midi_note_on_state(MIDI_CH).to_f
  # Pitch bend arrives 14-bit and signed, -8192 to 8191, so a whole turn of the wheel is one unit
  # and half of it lands where the pitch domain's own half does. The count of steps is even, so
  # the middle of the range falls between -1 and 0 rather than on a value. Pairing the steps off
  # in the integers first puts -1 and 0 on the same one, which costs half the resolution -- 8193
  # steps, still far under a cent at any usable bend range -- and buys a centre that is exactly
  # zero with both ends exactly on -0.5 and +0.5. The division must floor for the bottom end to
  # land: Integer#/ does, and Spinel's sp_idiv implements it.
  signals[SIGNAL_BEND]  = ((C.get_midi_pitch_bend(MIDI_CH) + 1) / 2).to_f * (1.0 / 8192.0)

  # The patch, read back from the NRPN table. active_modules is packed from the front with no
  # gaps; every source_* holds a SIGNAL_* bus slot.
  slot = 0
  while slot < MODULES_SIZE
    active_modules[slot] = C.get_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + slot)
    slot += 1
  end

  source_env_gen_1_gate = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE)
  source_osc_1_pitch    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH)
  source_osc_1_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD)
  source_filter_1_audio = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO)
  source_filter_1_mod   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD)
  source_amp_1_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO)
  source_amp_1_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD)
  source_mixer_1_in_1   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_1)
  source_mixer_1_in_2   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_2)
  source_output         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT)

  # Parameter sources. Read once per buffer rather than per sample: each destination smooths at
  # the control rate with a 2.67 ms time constant, which swallows the difference between feeding
  # it at 48 kHz and at the 750 Hz buffer rate. Faster modulation goes through the module inputs
  # above, which are read per sample and not smoothed.
  source_lfo_1_rate            = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE)
  source_lfo_1_level           = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL)
  source_lfo_1_polarity        = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_POLARITY)
  source_env_gen_1_attack      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_ATTACK)
  source_env_gen_1_decay       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_DECAY)
  source_env_gen_1_sustain     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_SUSTAIN)
  source_env_gen_1_level       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_LEVEL)
  source_env_gen_1_polarity    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_POLARITY)
  source_osc_1_waveform        = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_WAVEFORM)
  source_osc_1_coarse_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_COARSE_TUNE)
  source_osc_1_fine_tune       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_FINE_TUNE)
  source_osc_1_mod_amount      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_AMOUNT)
  source_osc_1_mod_polarity    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_POLARITY)
  source_filter_1_cutoff       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_CUTOFF)
  source_filter_1_resonance    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_RESONANCE)
  source_filter_1_gain         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_GAIN)
  source_filter_1_mod_amount   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_AMOUNT)
  source_filter_1_mod_polarity = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_POLARITY)
  source_amp_1_gain            = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_GAIN)
  source_mixer_1_level_1       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_1)
  source_mixer_1_polarity_1    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POLARITY_1)
  source_mixer_1_level_2       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_2)
  source_mixer_1_polarity_2    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POLARITY_2)

  # Which CC fills each control slot. The bus is the only thing downstream reads, so this is
  # where MIDI enters and the only place a CC number appears.
  cc_lfo_1_rate            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE)
  cc_lfo_1_level           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_LEVEL)
  cc_lfo_1_polarity        = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_POLARITY)
  cc_env_gen_1_attack      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_ATTACK)
  cc_env_gen_1_decay       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_DECAY)
  cc_env_gen_1_sustain     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_SUSTAIN)
  cc_env_gen_1_level       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_LEVEL)
  cc_env_gen_1_polarity    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_1_POLARITY)
  cc_osc_1_waveform        = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_WAVEFORM)
  cc_osc_1_coarse_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_COARSE_TUNE)
  cc_osc_1_fine_tune       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_FINE_TUNE)
  cc_osc_1_mod_amount      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_AMOUNT)
  cc_osc_1_mod_polarity    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_POLARITY)
  cc_filter_1_cutoff       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_CUTOFF)
  cc_filter_1_resonance    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_RESONANCE)
  cc_filter_1_gain         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_GAIN)
  cc_filter_1_mod_amount   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_AMOUNT)
  cc_filter_1_mod_polarity = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_POLARITY)
  cc_amp_1_gain            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_1_GAIN)
  cc_mixer_1_level_1       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_1)
  cc_mixer_1_polarity_1    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POLARITY_1)
  cc_mixer_1_level_2       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_2)
  cc_mixer_1_polarity_2    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POLARITY_2)
  cc_general_mod_wheel     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_MOD_WHEEL)
  cc_general_1             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_1)
  cc_general_2             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_2)
  cc_general_3             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_3)
  cc_general_4             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_4)

  signals[cc_slot(cc_lfo_1_rate, SIGNAL_LFO_1_RATE)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate))
  signals[cc_slot(cc_lfo_1_level, SIGNAL_LFO_1_LEVEL)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level))
  signals[cc_slot(cc_lfo_1_polarity, SIGNAL_LFO_1_POLARITY)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_polarity))
  signals[cc_slot(cc_env_gen_1_attack, SIGNAL_ENV_GEN_1_ATTACK)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_attack))
  signals[cc_slot(cc_env_gen_1_decay, SIGNAL_ENV_GEN_1_DECAY)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_decay))
  signals[cc_slot(cc_env_gen_1_sustain, SIGNAL_ENV_GEN_1_SUSTAIN)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_sustain))
  signals[cc_slot(cc_env_gen_1_level, SIGNAL_ENV_GEN_1_LEVEL)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_level))
  signals[cc_slot(cc_env_gen_1_polarity, SIGNAL_ENV_GEN_1_POLARITY)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_polarity))
  signals[cc_slot(cc_osc_1_waveform, SIGNAL_OSC_1_WAVEFORM)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_waveform))
  signals[cc_slot(cc_osc_1_coarse_tune, SIGNAL_OSC_1_COARSE_TUNE)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_coarse_tune))
  signals[cc_slot(cc_osc_1_fine_tune, SIGNAL_OSC_1_FINE_TUNE)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_fine_tune))
  signals[cc_slot(cc_osc_1_mod_amount, SIGNAL_OSC_1_MOD_AMOUNT)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_amount))
  signals[cc_slot(cc_osc_1_mod_polarity, SIGNAL_OSC_1_MOD_POLARITY)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_polarity))
  signals[cc_slot(cc_filter_1_cutoff, SIGNAL_FILTER_1_CUTOFF)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_cutoff))
  signals[cc_slot(cc_filter_1_resonance, SIGNAL_FILTER_1_RESONANCE)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_resonance))
  signals[cc_slot(cc_filter_1_gain, SIGNAL_FILTER_1_GAIN)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_gain))
  signals[cc_slot(cc_filter_1_mod_amount, SIGNAL_FILTER_1_MOD_AMOUNT)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_amount))
  signals[cc_slot(cc_filter_1_mod_polarity, SIGNAL_FILTER_1_MOD_POLARITY)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_polarity))
  signals[cc_slot(cc_amp_1_gain, SIGNAL_AMP_1_GAIN)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_amp_1_gain))
  signals[cc_slot(cc_mixer_1_level_1, SIGNAL_MIXER_1_LEVEL_1)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_1))
  signals[cc_slot(cc_mixer_1_polarity_1, SIGNAL_MIXER_1_POLARITY_1)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_1))
  signals[cc_slot(cc_mixer_1_level_2, SIGNAL_MIXER_1_LEVEL_2)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_2))
  signals[cc_slot(cc_mixer_1_polarity_2, SIGNAL_MIXER_1_POLARITY_2)] = cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_2))
  signals[cc_slot(cc_general_mod_wheel, SIGNAL_GENERAL_MOD_WHEEL)] = cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_general_mod_wheel))
  # Each General CC fills two slots, the same value taken both ways.
  general_1 = C.get_midi_cc_value(MIDI_CH, cc_general_1)
  general_2 = C.get_midi_cc_value(MIDI_CH, cc_general_2)
  general_3 = C.get_midi_cc_value(MIDI_CH, cc_general_3)
  general_4 = C.get_midi_cc_value(MIDI_CH, cc_general_4)
  signals[cc_slot(cc_general_1, SIGNAL_GENERAL_UNIPOLAR_1)] = cc_to_unipolar(general_1)
  signals[cc_slot(cc_general_2, SIGNAL_GENERAL_UNIPOLAR_2)] = cc_to_unipolar(general_2)
  signals[cc_slot(cc_general_3, SIGNAL_GENERAL_UNIPOLAR_3)] = cc_to_unipolar(general_3)
  signals[cc_slot(cc_general_4, SIGNAL_GENERAL_UNIPOLAR_4)] = cc_to_unipolar(general_4)
  signals[cc_slot(cc_general_1, SIGNAL_GENERAL_BIPOLAR_1)] = cc_to_bipolar(general_1)
  signals[cc_slot(cc_general_2, SIGNAL_GENERAL_BIPOLAR_2)] = cc_to_bipolar(general_2)
  signals[cc_slot(cc_general_3, SIGNAL_GENERAL_BIPOLAR_3)] = cc_to_bipolar(general_3)
  signals[cc_slot(cc_general_4, SIGNAL_GENERAL_BIPOLAR_4)] = cc_to_bipolar(general_4)

  lfo_1.set_rate(signals[source_lfo_1_rate])
  lfo_1.set_level(signals[source_lfo_1_level])
  lfo_1.set_polarity(signals[source_lfo_1_polarity])
  env_gen_1.set_attack(signals[source_env_gen_1_attack])
  env_gen_1.set_decay(signals[source_env_gen_1_decay])
  env_gen_1.set_sustain(signals[source_env_gen_1_sustain])
  env_gen_1.set_level(signals[source_env_gen_1_level])
  env_gen_1.set_polarity(signals[source_env_gen_1_polarity])
  osc_1.set_waveform(signals[source_osc_1_waveform])
  osc_1.set_coarse_tune(signals[source_osc_1_coarse_tune])
  osc_1.set_fine_tune(signals[source_osc_1_fine_tune])
  osc_1.set_modulation_amount(signals[source_osc_1_mod_amount])
  osc_1.set_modulation_polarity(signals[source_osc_1_mod_polarity])
  filter_1.set_cutoff(signals[source_filter_1_cutoff])
  filter_1.set_resonance(signals[source_filter_1_resonance])
  filter_1.set_gain(signals[source_filter_1_gain])
  filter_1.set_modulation_amount(signals[source_filter_1_mod_amount])
  filter_1.set_modulation_polarity(signals[source_filter_1_mod_polarity])
  amp_1.set_gain(signals[source_amp_1_gain])
  mixer_1.set_level_1(signals[source_mixer_1_level_1])
  mixer_1.set_polarity_1(signals[source_mixer_1_polarity_1])
  mixer_1.set_level_2(signals[source_mixer_1_level_2])
  mixer_1.set_polarity_2(signals[source_mixer_1_polarity_2])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      # Spinel never emits a jump table however the Ruby is written, so a case costs one compare
      # per id up to the one that matches: 21 a sample at six modules. Splitting the chain on a
      # kind of module pays only once that kind has several instances.
      case module_id
      when MODULE_LFO_1
        signals[SIGNAL_LFO_1_OUTPUT] = lfo_1.process
      when MODULE_ENV_GEN_1
        signals[SIGNAL_ENV_GEN_1_OUTPUT] = env_gen_1.process(signals[source_env_gen_1_gate])
      when MODULE_OSC_1
        signals[SIGNAL_OSC_1_OUTPUT] = osc_1.process(signals[source_osc_1_pitch], signals[source_osc_1_mod])
      when MODULE_FILTER_1
        signals[SIGNAL_FILTER_1_OUTPUT] = filter_1.process(signals[source_filter_1_audio], signals[source_filter_1_mod])
      when MODULE_AMP_1
        signals[SIGNAL_AMP_1_OUTPUT] = amp_1.process(signals[source_amp_1_audio], signals[source_amp_1_mod])
      when MODULE_MIXER_1
        signals[SIGNAL_MIXER_1_OUTPUT] = mixer_1.process(signals[source_mixer_1_in_1], signals[source_mixer_1_in_2])
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
