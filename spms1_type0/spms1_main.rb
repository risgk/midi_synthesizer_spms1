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
# MODULE_NONE, which is what an unset NRPN entry reads as.
MODULES_SIZE = 16

MODULE_NONE    = 0
MODULE_ENV_GEN = 1
MODULE_LFO     = 2
MODULE_OSC     = 3
MODULE_FILTER  = 4
MODULE_AMP     = 5

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
SIGNAL_NONE              = 0
SIGNAL_ONE               = 1
SIGNAL_HALF              = 2
SIGNAL_MINUS_HALF        = 3
SIGNAL_MINUS_ONE         = 4
SIGNAL_ENV_GEN_OUTPUT    = 5
SIGNAL_LFO_OUTPUT        = 6
SIGNAL_OSC_OUTPUT        = 7
SIGNAL_FILTER_OUTPUT     = 8
SIGNAL_AMP_OUTPUT        = 9
SIGNAL_OSC_WAVEFORM      = 10
SIGNAL_OSC_MOD_AMOUNT    = 11
SIGNAL_OSC_COARSE_TUNE   = 12
SIGNAL_OSC_FINE_TUNE     = 13
SIGNAL_FILTER_CUTOFF     = 14
SIGNAL_FILTER_RESONANCE  = 15
SIGNAL_FILTER_MOD_AMOUNT = 16
SIGNAL_FILTER_GAIN       = 17
SIGNAL_AMP_GAIN          = 18
SIGNAL_ENV_GEN_ATTACK    = 19
SIGNAL_ENV_GEN_DECAY     = 20
SIGNAL_ENV_GEN_SUSTAIN   = 21
SIGNAL_LFO_RATE          = 22
SIGNAL_PITCH             = 23
SIGNAL_GATE              = 24

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

NRPN_SOURCE_ENV_GEN_GATE = 128
NRPN_SOURCE_OSC_PITCH    = 129
NRPN_SOURCE_OSC_MOD      = 130
NRPN_SOURCE_FILTER_AUDIO = 131
NRPN_SOURCE_FILTER_MOD   = 132
NRPN_SOURCE_AMP_AUDIO    = 133
NRPN_SOURCE_AMP_MOD      = 134
NRPN_SOURCE_OUTPUT       = 135

NRPN_SOURCE_OSC_WAVEFORM      = 256
NRPN_SOURCE_OSC_MOD_AMOUNT    = 257
NRPN_SOURCE_OSC_COARSE_TUNE   = 258
NRPN_SOURCE_OSC_FINE_TUNE     = 259
NRPN_SOURCE_FILTER_CUTOFF     = 260
NRPN_SOURCE_FILTER_RESONANCE  = 261
NRPN_SOURCE_FILTER_MOD_AMOUNT = 262
NRPN_SOURCE_FILTER_GAIN       = 263
NRPN_SOURCE_AMP_GAIN          = 264
NRPN_SOURCE_ENV_GEN_ATTACK    = 265
NRPN_SOURCE_ENV_GEN_DECAY     = 266
NRPN_SOURCE_ENV_GEN_SUSTAIN   = 267
NRPN_SOURCE_LFO_RATE          = 268

# A CC number of 0 means the parameter has no CC: its control slot keeps whatever it holds, so the
# parameter can be driven by routing alone. A parameter shipped that way wants its slot seeded
# below, unless 0.0 is the value it should rest at.
NRPN_CC_OSC_WAVEFORM      = 384
NRPN_CC_OSC_MOD_AMOUNT    = 385
NRPN_CC_OSC_COARSE_TUNE   = 386
NRPN_CC_OSC_FINE_TUNE     = 387
NRPN_CC_FILTER_CUTOFF     = 388
NRPN_CC_FILTER_RESONANCE  = 389
NRPN_CC_FILTER_MOD_AMOUNT = 390
NRPN_CC_FILTER_GAIN       = 391
NRPN_CC_AMP_GAIN          = 392
NRPN_CC_ENV_GEN_ATTACK    = 393
NRPN_CC_ENV_GEN_DECAY     = 394
NRPN_CC_ENV_GEN_SUSTAIN   = 395
NRPN_CC_LFO_RATE          = 396

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

osc     = Osc.new(SAMPLE_RATE)
filter  = Filter.new(SAMPLE_RATE)
amp     = Amp.new(SAMPLE_RATE)
env_gen = EnvGen.new(SAMPLE_RATE)
lfo     = LFO.new(SAMPLE_RATE)

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

# Control slots start at 0.0, which is where each parameter rests, except the two tune controls
# whose resting value is the middle of their range. This only shows for a parameter with no CC
# assigned, since every other slot is overwritten from MIDI on the first buffer.
signals[SIGNAL_OSC_COARSE_TUNE] = 0.5
signals[SIGNAL_OSC_FINE_TUNE]   = 0.5

# The default patch, written into the NRPN table the loop reads it back from. Slots left at 0
# read as MODULE_NONE, so active_modules needs only the five it uses.
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_ENV_GEN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_LFO)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_OSC)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_FILTER)
C.set_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_AMP)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_GATE, SIGNAL_GATE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_PITCH   , SIGNAL_PITCH)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_MOD     , SIGNAL_LFO_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_AUDIO, SIGNAL_OSC_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_MOD  , SIGNAL_ENV_GEN_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_AUDIO   , SIGNAL_FILTER_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_MOD     , SIGNAL_ENV_GEN_OUTPUT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT      , SIGNAL_AMP_OUTPUT)

C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_WAVEFORM     , SIGNAL_OSC_WAVEFORM)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_MOD_AMOUNT   , SIGNAL_OSC_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_COARSE_TUNE  , SIGNAL_OSC_COARSE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_FINE_TUNE    , SIGNAL_OSC_FINE_TUNE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_CUTOFF    , SIGNAL_FILTER_CUTOFF)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_RESONANCE , SIGNAL_FILTER_RESONANCE)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_MOD_AMOUNT, SIGNAL_FILTER_MOD_AMOUNT)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_GAIN      , SIGNAL_FILTER_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_GAIN         , SIGNAL_AMP_GAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_ATTACK   , SIGNAL_ENV_GEN_ATTACK)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_DECAY    , SIGNAL_ENV_GEN_DECAY)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_SUSTAIN  , SIGNAL_ENV_GEN_SUSTAIN)
C.set_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_RATE         , SIGNAL_LFO_RATE)

C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_WAVEFORM     , 20)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_MOD_AMOUNT   , 13)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_COARSE_TUNE  , 86)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_FINE_TUNE    , 70)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_CUTOFF    , 74)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_RESONANCE , 71)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_MOD_AMOUNT, 24)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_GAIN      , 112)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_GAIN         , 15)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_ATTACK   , 73)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_DECAY    , 75)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_SUSTAIN  , 30)
C.set_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_RATE         , 3)

C.set_midi_cc_value(MIDI_CH, 20 , 4  ) # Osc Wave
C.set_midi_cc_value(MIDI_CH, 13 , 4  ) # Osc Mod Amt
C.set_midi_cc_value(MIDI_CH, 86 , 64 ) # Osc Coarse Tune
C.set_midi_cc_value(MIDI_CH, 70 , 64 ) # Osc Fine Tune
C.set_midi_cc_value(MIDI_CH, 74 , 124) # Filter Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter Mod Amt
C.set_midi_cc_value(MIDI_CH, 112, 64 ) # Filter Gain
C.set_midi_cc_value(MIDI_CH, 15 , 64 ) # Amp Gain
C.set_midi_cc_value(MIDI_CH, 73 , 4  ) # EG Attack
C.set_midi_cc_value(MIDI_CH, 75 , 94 ) # EG Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 4  ) # EG Sustain
C.set_midi_cc_value(MIDI_CH, 3  , 64 ) # LFO Rate

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

  source_env_gen_gate = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_GATE)
  source_osc_pitch    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_PITCH)
  source_osc_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_MOD)
  source_filter_audio = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_AUDIO)
  source_filter_mod   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_MOD)
  source_amp_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_AUDIO)
  source_amp_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_MOD)
  source_output       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT)

  # Parameter sources. Once per buffer is enough: the destination's 2.67 ms smoothing swallows the
  # difference between being fed at 48 kHz and at the 750 Hz buffer rate.
  source_osc_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_WAVEFORM)
  source_osc_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_MOD_AMOUNT)
  source_osc_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_COARSE_TUNE)
  source_osc_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_FINE_TUNE)
  source_filter_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_CUTOFF)
  source_filter_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_RESONANCE)
  source_filter_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_MOD_AMOUNT)
  source_filter_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_GAIN)
  source_amp_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_GAIN)
  source_env_gen_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_ATTACK)
  source_env_gen_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_DECAY)
  source_env_gen_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_ENV_GEN_SUSTAIN)
  source_lfo_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_RATE)

  # Which CC fills each control slot. The bus is the only thing downstream reads, so this is
  # where MIDI enters and the only place a CC number appears.
  cc_osc_waveform      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_WAVEFORM)
  cc_osc_mod_amount    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_MOD_AMOUNT)
  cc_osc_coarse_tune   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_COARSE_TUNE)
  cc_osc_fine_tune     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_FINE_TUNE)
  cc_filter_cutoff     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_CUTOFF)
  cc_filter_resonance  = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_RESONANCE)
  cc_filter_mod_amount = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_MOD_AMOUNT)
  cc_filter_gain       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_GAIN)
  cc_amp_gain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_GAIN)
  cc_env_gen_attack    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_ATTACK)
  cc_env_gen_decay     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_DECAY)
  cc_env_gen_sustain   = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_ENV_GEN_SUSTAIN)
  cc_lfo_rate          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_RATE)

  signals[cc_slot(cc_osc_waveform, SIGNAL_OSC_WAVEFORM)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_waveform))
  signals[cc_slot(cc_osc_mod_amount, SIGNAL_OSC_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_mod_amount))
  signals[cc_slot(cc_osc_coarse_tune, SIGNAL_OSC_COARSE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_coarse_tune))
  signals[cc_slot(cc_osc_fine_tune, SIGNAL_OSC_FINE_TUNE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_osc_fine_tune))
  signals[cc_slot(cc_filter_cutoff, SIGNAL_FILTER_CUTOFF)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_cutoff))
  signals[cc_slot(cc_filter_resonance, SIGNAL_FILTER_RESONANCE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_resonance))
  signals[cc_slot(cc_filter_mod_amount, SIGNAL_FILTER_MOD_AMOUNT)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_mod_amount))
  signals[cc_slot(cc_filter_gain, SIGNAL_FILTER_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_filter_gain))
  signals[cc_slot(cc_amp_gain, SIGNAL_AMP_GAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_amp_gain))
  signals[cc_slot(cc_env_gen_attack, SIGNAL_ENV_GEN_ATTACK)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_attack))
  signals[cc_slot(cc_env_gen_decay, SIGNAL_ENV_GEN_DECAY)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_decay))
  signals[cc_slot(cc_env_gen_sustain, SIGNAL_ENV_GEN_SUSTAIN)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_env_gen_sustain))
  signals[cc_slot(cc_lfo_rate, SIGNAL_LFO_RATE)] = cc_to_ratio(C.get_midi_cc_value(MIDI_CH, cc_lfo_rate))

  osc.set_waveform(signals[source_osc_waveform])
  osc.set_modulation_amount(signals[source_osc_mod_amount])
  osc.set_coarse_tune(signals[source_osc_coarse_tune])
  osc.set_fine_tune(signals[source_osc_fine_tune])
  filter.set_cutoff(signals[source_filter_cutoff])
  filter.set_resonance(signals[source_filter_resonance])
  filter.set_modulation_amount(signals[source_filter_mod_amount])
  filter.set_gain(signals[source_filter_gain])
  amp.set_gain(signals[source_amp_gain])
  env_gen.set_attack(signals[source_env_gen_attack])
  env_gen.set_decay(signals[source_env_gen_decay])
  env_gen.set_sustain(signals[source_env_gen_sustain])
  lfo.set_rate(signals[source_lfo_rate])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    # A plain while loop, not .each: breaking out of a block needs setjmp, while a plain break
    # compiles to a C break.
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      case module_id
      when MODULE_ENV_GEN
        signals[SIGNAL_ENV_GEN_OUTPUT] = env_gen.process(signals[source_env_gen_gate])
      when MODULE_LFO
        signals[SIGNAL_LFO_OUTPUT] = lfo.process
      when MODULE_OSC
        signals[SIGNAL_OSC_OUTPUT] = osc.process(signals[source_osc_pitch], signals[source_osc_mod])
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
