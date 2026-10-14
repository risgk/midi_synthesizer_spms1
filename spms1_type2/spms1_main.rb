require_relative 'spms1_osc'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_lfo'
require_relative 'spms1_mixer'
require_relative 'spms1_chorus'
require_relative 'spms1_delay'

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
# The length of a bus slot: a slot holds a buffer of samples, the first of them at slot * W.
W = AUDIO_BUFFER_WORDS

# How many modules a patch can chain, and so the range of NRPN category 0. Every slot is rewritten
# from NRPN each buffer, so nothing needs a terminator: a shorter patch stops at the first
# MODULE_NONE, which is what an unset NRPN entry reads as. Only the rewriting is paid for the full
# length; the walk down it stops at that first MODULE_NONE.
MODULES_SIZE = 32

# Numbers only ever get added, at the end of their range: a module id after the last, a bus slot
# after the last, an NRPN entry after the last of its category. A patch sent as NRPN bytes names
# everything by number, so one made before keeps meaning the same thing after, and the tables in
# the README only grow. The cost is that a second oscillator does not sit next to the first.

# One of every module type that makes a sound, one mixer, one chorus and one delay. Instances carry
# their number in the id rather than being indexed by one, so a second oscillator would be
# MODULE_OSC_2, the next id after MODULE_DELAY_1.
MODULE_NONE      = 0
MODULE_LFO_1     = 1
MODULE_ENV_GEN_1 = 2
MODULE_OSC_1     = 3
MODULE_FILTER_1  = 4
MODULE_AMP_1     = 5
MODULE_MIXER_1   = 6
MODULE_CHORUS_1  = 7
MODULE_DELAY_1   = 8

# Slots of the `signals` bus: module outputs, control values and the note inputs in one namespace,
# so a routing is just a slot number and one source can feed as many destinations as read its
# slot. A slot is a plain float; its range is whatever the destination expects. Indexing an array
# is what holds a routed input to one read whatever the module count: passing the candidates in as
# arguments instead costs picks x candidates per sample, which grows quadratically.
# Nothing in the code depends on the numbering beyond signal_stride, which marks the module outputs.
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
SIGNAL_CHORUS_1_OUTPUT_L   = 15
SIGNAL_CHORUS_1_OUTPUT_R   = 16
SIGNAL_DELAY_1_OUTPUT_L    = 17
SIGNAL_DELAY_1_OUTPUT_R    = 18

SIGNAL_LFO_1_RATE            = 19
SIGNAL_LFO_1_LEVEL           = 20
SIGNAL_LFO_1_POLARITY        = 21
SIGNAL_ENV_GEN_1_ATTACK      = 22
SIGNAL_ENV_GEN_1_DECAY       = 23
SIGNAL_ENV_GEN_1_SUSTAIN     = 24
SIGNAL_ENV_GEN_1_LEVEL       = 25
SIGNAL_ENV_GEN_1_POLARITY    = 26
SIGNAL_OSC_1_WAVEFORM        = 27
SIGNAL_OSC_1_COARSE_TUNE     = 28
SIGNAL_OSC_1_FINE_TUNE       = 29
SIGNAL_OSC_1_MOD_AMOUNT      = 30
SIGNAL_OSC_1_MOD_POLARITY    = 31
SIGNAL_FILTER_1_CUTOFF       = 32
SIGNAL_FILTER_1_RESONANCE    = 33
SIGNAL_FILTER_1_GAIN         = 34
SIGNAL_FILTER_1_MOD_AMOUNT   = 35
SIGNAL_FILTER_1_MOD_POLARITY = 36
SIGNAL_AMP_1_GAIN            = 37
SIGNAL_MIXER_1_LEVEL_1       = 38
SIGNAL_MIXER_1_POLARITY_1    = 39
SIGNAL_MIXER_1_LEVEL_2       = 40
SIGNAL_MIXER_1_POLARITY_2    = 41
SIGNAL_CHORUS_1_RATE         = 42
SIGNAL_CHORUS_1_DEPTH        = 43
SIGNAL_CHORUS_1_MIX          = 44
SIGNAL_DELAY_1_TIME          = 45
SIGNAL_DELAY_1_FEEDBACK      = 46
SIGNAL_DELAY_1_MIX           = 47

SIGNAL_PITCH               = 48
SIGNAL_GATE                = 49
SIGNAL_BEND                = 50

# Control slots no parameter owns: each is a CC put on the bus for any input or parameter to read.
# The mod wheel first, unipolar and on CC 1, then four of each kind. The two kinds share General
# CCs 1-4, one CC filling a slot of each, so a knob can be taken either way without a mixer to
# shift it.
SIGNAL_GENERAL_MOD_WHEEL   = 51
SIGNAL_GENERAL_UNIPOLAR_1  = 52
SIGNAL_GENERAL_UNIPOLAR_2  = 53
SIGNAL_GENERAL_UNIPOLAR_3  = 54
SIGNAL_GENERAL_UNIPOLAR_4  = 55
SIGNAL_GENERAL_BIPOLAR_1   = 56
SIGNAL_GENERAL_BIPOLAR_2   = 57
SIGNAL_GENERAL_BIPOLAR_3   = 58
SIGNAL_GENERAL_BIPOLAR_4   = 59

SIGNALS_SIZE = 128

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_ENV_GEN_1_GATE  = 128
NRPN_SOURCE_OSC_1_PITCH     = 129
NRPN_SOURCE_OSC_1_MOD       = 130
NRPN_SOURCE_FILTER_1_AUDIO  = 131
NRPN_SOURCE_FILTER_1_MOD    = 132
NRPN_SOURCE_AMP_1_AUDIO     = 133
NRPN_SOURCE_AMP_1_MOD       = 134
NRPN_SOURCE_MIXER_1_IN_1    = 135
NRPN_SOURCE_MIXER_1_IN_2    = 136
NRPN_SOURCE_CHORUS_1_AUDIO  = 137
NRPN_SOURCE_DELAY_1_AUDIO_L = 138
NRPN_SOURCE_DELAY_1_AUDIO_R = 139
NRPN_SOURCE_OUTPUT_L        = 140
NRPN_SOURCE_OUTPUT_R        = 141

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
NRPN_SOURCE_CHORUS_1_RATE         = 279
NRPN_SOURCE_CHORUS_1_DEPTH        = 280
NRPN_SOURCE_CHORUS_1_MIX          = 281
NRPN_SOURCE_DELAY_1_TIME          = 282
NRPN_SOURCE_DELAY_1_FEEDBACK      = 283
NRPN_SOURCE_DELAY_1_MIX           = 284

# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.
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
NRPN_CC_CHORUS_1_RATE         = 407
NRPN_CC_CHORUS_1_DEPTH        = 408
NRPN_CC_CHORUS_1_MIX          = 409
NRPN_CC_DELAY_1_TIME          = 410
NRPN_CC_DELAY_1_FEEDBACK      = 411
NRPN_CC_DELAY_1_MIX           = 412
NRPN_CC_GENERAL_MOD_WHEEL     = 413
NRPN_CC_GENERAL_1             = 414
NRPN_CC_GENERAL_2             = 415
NRPN_CC_GENERAL_3             = 416
NRPN_CC_GENERAL_4             = 417

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

# What a control slot is filled with. CC number 0 means no CC is assigned, and the slot gets 0.0.
# Selecting the value rather than skipping the write keeps the cost the same whatever the patch says.
def cc_or_zero(cc_number, value)
  (cc_number == 0) ? 0.0 : value
end

lfo_1     = LFO.new(SAMPLE_RATE)
env_gen_1 = EnvGen.new(SAMPLE_RATE)
osc_1     = Osc.new(SAMPLE_RATE)
filter_1  = Filter.new(SAMPLE_RATE)
amp_1     = Amp.new(SAMPLE_RATE)
mixer_1   = Mixer.new(SAMPLE_RATE)
chorus_1  = Chorus.new(SAMPLE_RATE)
delay_1   = Delay.new(SAMPLE_RATE)

# Allocated once; which slots are filled is decided per buffer, inside the loop.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)

audio_buffer_l = Array.new(AUDIO_BUFFER_WORDS, 0.0)
audio_buffer_r = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# The signal bus: each module's output for this buffer, a sample per position of its SIGNAL_*
# slot, and every other slot's one value at the first position of its own. Declared out here so
# it carries across buffers, since a routing with feedback reads a module that has not run yet
# this buffer, and so gets the previous buffer's sample at the same position: a loop through the
# bus is W samples long, 1.3 ms at 48 kHz.
signals = Array.new(SIGNALS_SIZE * W, 0.0)
signals[SIGNAL_ONE * W]             =  1.0
signals[SIGNAL_HALF * W]            =  0.5
signals[SIGNAL_POINT_TWO * W]       =  0.2
signals[SIGNAL_POINT_ONE * W]       =  0.1
signals[SIGNAL_MINUS_POINT_ONE * W] = -0.1
signals[SIGNAL_MINUS_POINT_TWO * W] = -0.2
signals[SIGNAL_MINUS_HALF * W]      = -0.5
signals[SIGNAL_MINUS_ONE * W]       = -1.0

# How far apart a reader of each slot finds its samples: 1 for a module output, which changes
# every sample, and 0 for the rest, which hold one value a buffer. Reading at stride 0 is what lets
# those be written once a buffer rather than W times.
signal_stride = Array.new(SIGNALS_SIZE, 0)
signal_stride[SIGNAL_LFO_1_OUTPUT]      = 1
signal_stride[SIGNAL_ENV_GEN_1_OUTPUT]  = 1
signal_stride[SIGNAL_OSC_1_OUTPUT]      = 1
signal_stride[SIGNAL_FILTER_1_OUTPUT]   = 1
signal_stride[SIGNAL_AMP_1_OUTPUT]      = 1
signal_stride[SIGNAL_MIXER_1_OUTPUT]    = 1
signal_stride[SIGNAL_CHORUS_1_OUTPUT_L] = 1
signal_stride[SIGNAL_CHORUS_1_OUTPUT_R] = 1
signal_stride[SIGNAL_DELAY_1_OUTPUT_L]  = 1
signal_stride[SIGNAL_DELAY_1_OUTPUT_R]  = 1

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
# the envelope as it is. The chorus and the delay run last, after the amp: the chorus takes the mono
# amp and spreads it into a left and a right, the delay takes the two sides, and its two outputs
# are what the final output's left and right read.
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_LFO_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_ENV_GEN_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_MIXER_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_OSC_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_FILTER_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_AMP_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 6, MODULE_CHORUS_1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 7, MODULE_DELAY_1)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE , SIGNAL_GATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD      , SIGNAL_LFO_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_OSC_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD   , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_ENV_GEN_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)

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
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_RATE         , SIGNAL_CHORUS_1_RATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_DEPTH        , SIGNAL_CHORUS_1_DEPTH)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_MIX          , SIGNAL_CHORUS_1_MIX)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_TIME          , SIGNAL_DELAY_1_TIME)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_FEEDBACK      , SIGNAL_DELAY_1_FEEDBACK)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_MIX           , SIGNAL_DELAY_1_MIX)

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
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_RATE       , 58)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_DEPTH      , 59)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_MIX        , 93)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_TIME        , 55)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_FEEDBACK    , 56)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_MIX         , 94)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_MOD_WHEEL   , 1)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_1           , 16)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_2           , 17)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_3           , 18)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_4           , 19)

C.set_midi_cc_value(MIDI_CH, 3  , 64 ) # LFO 1 Rate
C.set_midi_cc_value(MIDI_CH, 73 , 4  ) # EG 1 Attack
C.set_midi_cc_value(MIDI_CH, 75 , 96 ) # EG 1 Decay
C.set_midi_cc_value(MIDI_CH, 30 , 124) # EG 1 Sustain
C.set_midi_cc_value(MIDI_CH, 20 , 4  ) # Osc 1 Wave
C.set_midi_cc_value(MIDI_CH, 86 , 64 ) # Osc 1 Coarse Tune
C.set_midi_cc_value(MIDI_CH, 70 , 64 ) # Osc 1 Fine Tune
C.set_midi_cc_value(MIDI_CH, 13 , 4  ) # Osc 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 74 , 100) # Filter 1 Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 94 ) # Filter 1 Resonance
C.set_midi_cc_value(MIDI_CH, 112, 64 ) # Filter 1 Gain
C.set_midi_cc_value(MIDI_CH, 24 , 28 ) # Filter 1 Mod Amt
C.set_midi_cc_value(MIDI_CH, 15 , 124) # Amp 1 Gain
C.set_midi_cc_value(MIDI_CH, 58 , 64 ) # Chorus 1 Rate
C.set_midi_cc_value(MIDI_CH, 59 , 64 ) # Chorus 1 Depth
C.set_midi_cc_value(MIDI_CH, 93 , 64 ) # Chorus 1 Mix
C.set_midi_cc_value(MIDI_CH, 55 , 64 ) # Delay 1 Time
C.set_midi_cc_value(MIDI_CH, 56 , 64 ) # Delay 1 Feedback
C.set_midi_cc_value(MIDI_CH, 94 , 34 ) # Delay 1 Mix
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

  signals[SIGNAL_PITCH * W] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_GATE * W]  = C.get_midi_note_on_state(MIDI_CH).to_f
  # Pitch bend arrives 14-bit and signed, -8192 to 8191, so a whole turn of the wheel is one unit
  # and half of it lands where the pitch domain's own half does. The count of steps is even, so
  # the middle of the range falls between -1 and 0 rather than on a value. Pairing the steps off
  # in the integers first puts -1 and 0 on the same one, which costs half the resolution -- 8193
  # steps, still far under a cent at any usable bend range -- and buys a centre that is exactly
  # zero with both ends exactly on -0.5 and +0.5. The division must floor for the bottom end to
  # land: Integer#/ does, and Spinel's sp_idiv implements it.
  signals[SIGNAL_BEND * W]  = ((C.get_midi_pitch_bend(MIDI_CH) + 1) / 2).to_f * (1.0 / 8192.0)

  # The patch, read back from the NRPN table. active_modules is packed from the front with no
  # gaps; every source_* holds a SIGNAL_* bus slot.
  slot = 0
  while slot < MODULES_SIZE
    active_modules[slot] = C.get_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + slot)
    slot += 1
  end

  source_env_gen_1_gate  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_1_GATE)
  source_osc_1_pitch     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH)
  source_osc_1_mod       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD)
  source_filter_1_audio  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO)
  source_filter_1_mod    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD)
  source_amp_1_audio     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO)
  source_amp_1_mod       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD)
  source_mixer_1_in_1    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_1)
  source_mixer_1_in_2    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_2)
  source_chorus_1_audio  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_AUDIO)
  source_delay_1_audio_l = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_L)
  source_delay_1_audio_r = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_R)
  source_output_l        = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_L)
  source_output_r        = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_R)

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
  source_chorus_1_rate         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_RATE)
  source_chorus_1_depth        = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_DEPTH)
  source_chorus_1_mix          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_MIX)
  source_delay_1_time          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_TIME)
  source_delay_1_feedback      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_FEEDBACK)
  source_delay_1_mix           = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_MIX)

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
  cc_chorus_1_rate         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_RATE)
  cc_chorus_1_depth        = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_DEPTH)
  cc_chorus_1_mix          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_MIX)
  cc_delay_1_time          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_TIME)
  cc_delay_1_feedback      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_FEEDBACK)
  cc_delay_1_mix           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_MIX)
  cc_general_mod_wheel     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_MOD_WHEEL)
  cc_general_1             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_1)
  cc_general_2             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_2)
  cc_general_3             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_3)
  cc_general_4             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_4)

  signals[SIGNAL_LFO_1_RATE * W] = cc_or_zero(cc_lfo_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate)))
  signals[SIGNAL_LFO_1_LEVEL * W] = cc_or_zero(cc_lfo_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level)))
  signals[SIGNAL_LFO_1_POLARITY * W] = cc_or_zero(cc_lfo_1_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_polarity)))
  signals[SIGNAL_ENV_GEN_1_ATTACK * W] = cc_or_zero(cc_env_gen_1_attack, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_attack)))
  signals[SIGNAL_ENV_GEN_1_DECAY * W] = cc_or_zero(cc_env_gen_1_decay, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_decay)))
  signals[SIGNAL_ENV_GEN_1_SUSTAIN * W] = cc_or_zero(cc_env_gen_1_sustain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_sustain)))
  signals[SIGNAL_ENV_GEN_1_LEVEL * W] = cc_or_zero(cc_env_gen_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_level)))
  signals[SIGNAL_ENV_GEN_1_POLARITY * W] = cc_or_zero(cc_env_gen_1_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_polarity)))
  signals[SIGNAL_OSC_1_WAVEFORM * W] = cc_or_zero(cc_osc_1_waveform, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_waveform)))
  signals[SIGNAL_OSC_1_COARSE_TUNE * W] = cc_or_zero(cc_osc_1_coarse_tune, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_coarse_tune)))
  signals[SIGNAL_OSC_1_FINE_TUNE * W] = cc_or_zero(cc_osc_1_fine_tune, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_fine_tune)))
  signals[SIGNAL_OSC_1_MOD_AMOUNT * W] = cc_or_zero(cc_osc_1_mod_amount, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_amount)))
  signals[SIGNAL_OSC_1_MOD_POLARITY * W] = cc_or_zero(cc_osc_1_mod_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_polarity)))
  signals[SIGNAL_FILTER_1_CUTOFF * W] = cc_or_zero(cc_filter_1_cutoff, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_cutoff)))
  signals[SIGNAL_FILTER_1_RESONANCE * W] = cc_or_zero(cc_filter_1_resonance, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_resonance)))
  signals[SIGNAL_FILTER_1_GAIN * W] = cc_or_zero(cc_filter_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_gain)))
  signals[SIGNAL_FILTER_1_MOD_AMOUNT * W] = cc_or_zero(cc_filter_1_mod_amount, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_amount)))
  signals[SIGNAL_FILTER_1_MOD_POLARITY * W] = cc_or_zero(cc_filter_1_mod_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_polarity)))
  signals[SIGNAL_AMP_1_GAIN * W] = cc_or_zero(cc_amp_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_amp_1_gain)))
  signals[SIGNAL_MIXER_1_LEVEL_1 * W] = cc_or_zero(cc_mixer_1_level_1, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_1)))
  signals[SIGNAL_MIXER_1_POLARITY_1 * W] = cc_or_zero(cc_mixer_1_polarity_1, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_1)))
  signals[SIGNAL_MIXER_1_LEVEL_2 * W] = cc_or_zero(cc_mixer_1_level_2, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_2)))
  signals[SIGNAL_MIXER_1_POLARITY_2 * W] = cc_or_zero(cc_mixer_1_polarity_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_2)))
  signals[SIGNAL_CHORUS_1_RATE * W] = cc_or_zero(cc_chorus_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_rate)))
  signals[SIGNAL_CHORUS_1_DEPTH * W] = cc_or_zero(cc_chorus_1_depth, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_depth)))
  signals[SIGNAL_CHORUS_1_MIX * W] = cc_or_zero(cc_chorus_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_mix)))
  signals[SIGNAL_DELAY_1_TIME * W] = cc_or_zero(cc_delay_1_time, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_time)))
  signals[SIGNAL_DELAY_1_FEEDBACK * W] = cc_or_zero(cc_delay_1_feedback, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_feedback)))
  signals[SIGNAL_DELAY_1_MIX * W] = cc_or_zero(cc_delay_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_mix)))
  signals[SIGNAL_GENERAL_MOD_WHEEL * W] = cc_or_zero(cc_general_mod_wheel, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_general_mod_wheel)))
  # Each General CC fills two slots, the same value taken both ways.
  general_1 = C.get_midi_cc_value(MIDI_CH, cc_general_1)
  general_2 = C.get_midi_cc_value(MIDI_CH, cc_general_2)
  general_3 = C.get_midi_cc_value(MIDI_CH, cc_general_3)
  general_4 = C.get_midi_cc_value(MIDI_CH, cc_general_4)
  signals[SIGNAL_GENERAL_UNIPOLAR_1 * W] = cc_or_zero(cc_general_1, cc_to_unipolar(general_1))
  signals[SIGNAL_GENERAL_UNIPOLAR_2 * W] = cc_or_zero(cc_general_2, cc_to_unipolar(general_2))
  signals[SIGNAL_GENERAL_UNIPOLAR_3 * W] = cc_or_zero(cc_general_3, cc_to_unipolar(general_3))
  signals[SIGNAL_GENERAL_UNIPOLAR_4 * W] = cc_or_zero(cc_general_4, cc_to_unipolar(general_4))
  signals[SIGNAL_GENERAL_BIPOLAR_1 * W] = cc_or_zero(cc_general_1, cc_to_bipolar(general_1))
  signals[SIGNAL_GENERAL_BIPOLAR_2 * W] = cc_or_zero(cc_general_2, cc_to_bipolar(general_2))
  signals[SIGNAL_GENERAL_BIPOLAR_3 * W] = cc_or_zero(cc_general_3, cc_to_bipolar(general_3))
  signals[SIGNAL_GENERAL_BIPOLAR_4 * W] = cc_or_zero(cc_general_4, cc_to_bipolar(general_4))

  lfo_1.set_rate(signals[source_lfo_1_rate * W])
  lfo_1.set_level(signals[source_lfo_1_level * W])
  lfo_1.set_polarity(signals[source_lfo_1_polarity * W])
  env_gen_1.set_attack(signals[source_env_gen_1_attack * W])
  env_gen_1.set_decay(signals[source_env_gen_1_decay * W])
  env_gen_1.set_sustain(signals[source_env_gen_1_sustain * W])
  env_gen_1.set_level(signals[source_env_gen_1_level * W])
  env_gen_1.set_polarity(signals[source_env_gen_1_polarity * W])
  osc_1.set_waveform(signals[source_osc_1_waveform * W])
  osc_1.set_coarse_tune(signals[source_osc_1_coarse_tune * W])
  osc_1.set_fine_tune(signals[source_osc_1_fine_tune * W])
  osc_1.set_modulation_amount(signals[source_osc_1_mod_amount * W])
  osc_1.set_modulation_polarity(signals[source_osc_1_mod_polarity * W])
  filter_1.set_cutoff(signals[source_filter_1_cutoff * W])
  filter_1.set_resonance(signals[source_filter_1_resonance * W])
  filter_1.set_gain(signals[source_filter_1_gain * W])
  filter_1.set_modulation_amount(signals[source_filter_1_mod_amount * W])
  filter_1.set_modulation_polarity(signals[source_filter_1_mod_polarity * W])
  amp_1.set_gain(signals[source_amp_1_gain * W])
  mixer_1.set_level_1(signals[source_mixer_1_level_1 * W])
  mixer_1.set_polarity_1(signals[source_mixer_1_polarity_1 * W])
  mixer_1.set_level_2(signals[source_mixer_1_level_2 * W])
  mixer_1.set_polarity_2(signals[source_mixer_1_polarity_2 * W])
  chorus_1.set_rate(signals[source_chorus_1_rate * W])
  chorus_1.set_depth(signals[source_chorus_1_depth * W])
  chorus_1.set_mix(signals[source_chorus_1_mix * W])
  delay_1.set_time(signals[source_delay_1_time * W])
  delay_1.set_feedback(signals[source_delay_1_feedback * W])
  delay_1.set_mix(signals[source_delay_1_mix * W])

  # Each module runs the whole buffer before the next one starts, so the walk down the run order
  # and the case below are paid once a buffer rather than once a sample. Spinel never emits a jump
  # table however the Ruby is written, so the case costs one compare per id up to the one that
  # matches. An input reads its source at stride 1 when that is a module output, which holds a
  # sample per position, and at stride 0 otherwise, which reads the one value the buffer has.
  # ob, lb and rb are where an output starts on the bus; ab and as the first input's start and
  # stride, bb and bs the second's.
  slot = 0
  while slot < MODULES_SIZE
    module_id = active_modules[slot]
    break if module_id == MODULE_NONE

    case module_id
    when MODULE_LFO_1
      ob = SIGNAL_LFO_1_OUTPUT * W
      i = 0
      while i < W
        signals[ob + i] = lfo_1.process
        i += 1
      end
    when MODULE_ENV_GEN_1
      ob = SIGNAL_ENV_GEN_1_OUTPUT * W
      ab = source_env_gen_1_gate * W
      as = signal_stride[source_env_gen_1_gate]
      i = 0
      while i < W
        signals[ob + i] = env_gen_1.process(signals[ab + i * as])
        i += 1
      end
    when MODULE_OSC_1
      ob = SIGNAL_OSC_1_OUTPUT * W
      ab = source_osc_1_pitch * W
      as = signal_stride[source_osc_1_pitch]
      bb = source_osc_1_mod * W
      bs = signal_stride[source_osc_1_mod]
      i = 0
      while i < W
        signals[ob + i] = osc_1.process(signals[ab + i * as], signals[bb + i * bs])
        i += 1
      end
    when MODULE_FILTER_1
      ob = SIGNAL_FILTER_1_OUTPUT * W
      ab = source_filter_1_audio * W
      as = signal_stride[source_filter_1_audio]
      bb = source_filter_1_mod * W
      bs = signal_stride[source_filter_1_mod]
      i = 0
      while i < W
        signals[ob + i] = filter_1.process(signals[ab + i * as], signals[bb + i * bs])
        i += 1
      end
    when MODULE_AMP_1
      ob = SIGNAL_AMP_1_OUTPUT * W
      ab = source_amp_1_audio * W
      as = signal_stride[source_amp_1_audio]
      bb = source_amp_1_mod * W
      bs = signal_stride[source_amp_1_mod]
      i = 0
      while i < W
        signals[ob + i] = amp_1.process(signals[ab + i * as], signals[bb + i * bs])
        i += 1
      end
    when MODULE_MIXER_1
      ob = SIGNAL_MIXER_1_OUTPUT * W
      ab = source_mixer_1_in_1 * W
      as = signal_stride[source_mixer_1_in_1]
      bb = source_mixer_1_in_2 * W
      bs = signal_stride[source_mixer_1_in_2]
      i = 0
      while i < W
        signals[ob + i] = mixer_1.process(signals[ab + i * as], signals[bb + i * bs])
        i += 1
      end
    when MODULE_CHORUS_1
      lb = SIGNAL_CHORUS_1_OUTPUT_L * W
      rb = SIGNAL_CHORUS_1_OUTPUT_R * W
      ab = source_chorus_1_audio * W
      as = signal_stride[source_chorus_1_audio]
      i = 0
      while i < W
        chorus_1.process(signals[ab + i * as])
        signals[lb + i] = chorus_1.output_l
        signals[rb + i] = chorus_1.output_r
        i += 1
      end
    when MODULE_DELAY_1
      lb = SIGNAL_DELAY_1_OUTPUT_L * W
      rb = SIGNAL_DELAY_1_OUTPUT_R * W
      ab = source_delay_1_audio_l * W
      as = signal_stride[source_delay_1_audio_l]
      bb = source_delay_1_audio_r * W
      bs = signal_stride[source_delay_1_audio_r]
      i = 0
      while i < W
        delay_1.process(signals[ab + i * as], signals[bb + i * bs])
        signals[lb + i] = delay_1.output_l
        signals[rb + i] = delay_1.output_r
        i += 1
      end
    end

    slot += 1
  end

  lb = source_output_l * W
  ls = signal_stride[source_output_l]
  rb = source_output_r * W
  rs = signal_stride[source_output_r]
  i = 0
  while i < W
    audio_buffer_l[i] = signals[lb + i * ls]
    audio_buffer_r[i] = signals[rb + i * rs]
    i += 1
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer_l[i], audio_buffer_r[i])
  end
end
