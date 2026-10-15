require_relative 'spms1_dsp'
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

# The numbers of the patch -- module ids, bus slots, NRPN entries -- and the default patch,
# generated from spms1_patch.yaml.
require_relative 'spms1_patch'

MIDI_CH            = 0
SAMPLE_RATE        = 48000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

# How many modules a patch can chain, and so the range of NRPN category 0. Every slot is rewritten
# from NRPN each buffer, so nothing needs a terminator: a shorter patch stops at the first
# MODULE_NONE, which is what an unset NRPN entry reads as. Only the rewriting is paid for the full
# length; the per-sample walk stops at that first MODULE_NONE.
MODULES_SIZE = 32

# The module ids (MODULE_*), in spms1_patch.rb: one of every module type that makes a sound, one
# mixer, one chorus and one delay. Instances carry their number in the id rather than being
# indexed by one, so a second oscillator would be MODULE_OSC_2, the next id after MODULE_DELAY_1:
# numbers only ever get added, at the end of their range (see spms1_patch.yaml).

# The slots of the `signals` bus (SIGNAL_*), in spms1_patch.rb: module outputs, control values
# and the note inputs in one namespace, so a routing is just a slot number and one source can feed
# as many destinations as read its slot. A slot is a plain float; its range is whatever the destination expects. Indexing an array
# is what holds a routed input to one read whatever the module count: passing the candidates in as
# arguments instead costs picks x candidates per sample, which grows quadratically.
# The constants come first so that SIGNAL_NONE is 0: an NRPN entry nobody has set reads 0, and an
# unrouted input should be silent rather than wired to whatever happens to sit in slot 0. Nothing
# ever writes them, so they hold what the bus was filled with at startup. They are what a routing
# reaches for when an input wants a fixed value rather than a source.
SIGNALS_SIZE = 128

# The NRPN parameter numbers (NRPN_*), in spms1_patch.rb: (MSB << 7) | LSB, where the MSB picks
# a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.

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

# The signal bus: each module's latest output, in its SIGNAL_* slot. Declared out here so it
# carries across buffers, since a routing with feedback reads last sample's value and at a buffer
# edge that is the previous iteration's.
signals = Array.new(SIGNALS_SIZE, 0.0)
spms1_fill_constant_signals(signals)

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
spms1_write_default_patch(MIDI_CH)

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

# while rather than loop: Spinel builds a loop block with a setjmp, for the StopIteration that ends
# one, which makes every local written inside it volatile, so that the per-sample code loaded and
# stored each of them, slot and i included, at every use: 6% of all instructions.
while true
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

  signals[SIGNAL_LFO_1_RATE] = cc_or_zero(cc_lfo_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate)))
  signals[SIGNAL_LFO_1_LEVEL] = cc_or_zero(cc_lfo_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level)))
  signals[SIGNAL_LFO_1_POLARITY] = cc_or_zero(cc_lfo_1_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_polarity)))
  signals[SIGNAL_ENV_GEN_1_ATTACK] = cc_or_zero(cc_env_gen_1_attack, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_attack)))
  signals[SIGNAL_ENV_GEN_1_DECAY] = cc_or_zero(cc_env_gen_1_decay, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_decay)))
  signals[SIGNAL_ENV_GEN_1_SUSTAIN] = cc_or_zero(cc_env_gen_1_sustain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_sustain)))
  signals[SIGNAL_ENV_GEN_1_LEVEL] = cc_or_zero(cc_env_gen_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_level)))
  signals[SIGNAL_ENV_GEN_1_POLARITY] = cc_or_zero(cc_env_gen_1_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_env_gen_1_polarity)))
  signals[SIGNAL_OSC_1_WAVEFORM] = cc_or_zero(cc_osc_1_waveform, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_waveform)))
  signals[SIGNAL_OSC_1_COARSE_TUNE] = cc_or_zero(cc_osc_1_coarse_tune, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_coarse_tune)))
  signals[SIGNAL_OSC_1_FINE_TUNE] = cc_or_zero(cc_osc_1_fine_tune, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_fine_tune)))
  signals[SIGNAL_OSC_1_MOD_AMOUNT] = cc_or_zero(cc_osc_1_mod_amount, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_amount)))
  signals[SIGNAL_OSC_1_MOD_POLARITY] = cc_or_zero(cc_osc_1_mod_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_polarity)))
  signals[SIGNAL_FILTER_1_CUTOFF] = cc_or_zero(cc_filter_1_cutoff, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_cutoff)))
  signals[SIGNAL_FILTER_1_RESONANCE] = cc_or_zero(cc_filter_1_resonance, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_resonance)))
  signals[SIGNAL_FILTER_1_GAIN] = cc_or_zero(cc_filter_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_gain)))
  signals[SIGNAL_FILTER_1_MOD_AMOUNT] = cc_or_zero(cc_filter_1_mod_amount, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_amount)))
  signals[SIGNAL_FILTER_1_MOD_POLARITY] = cc_or_zero(cc_filter_1_mod_polarity, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_polarity)))
  signals[SIGNAL_AMP_1_GAIN] = cc_or_zero(cc_amp_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_amp_1_gain)))
  signals[SIGNAL_MIXER_1_LEVEL_1] = cc_or_zero(cc_mixer_1_level_1, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_1)))
  signals[SIGNAL_MIXER_1_POLARITY_1] = cc_or_zero(cc_mixer_1_polarity_1, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_1)))
  signals[SIGNAL_MIXER_1_LEVEL_2] = cc_or_zero(cc_mixer_1_level_2, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_2)))
  signals[SIGNAL_MIXER_1_POLARITY_2] = cc_or_zero(cc_mixer_1_polarity_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_polarity_2)))
  signals[SIGNAL_CHORUS_1_RATE] = cc_or_zero(cc_chorus_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_rate)))
  signals[SIGNAL_CHORUS_1_DEPTH] = cc_or_zero(cc_chorus_1_depth, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_depth)))
  signals[SIGNAL_CHORUS_1_MIX] = cc_or_zero(cc_chorus_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_mix)))
  signals[SIGNAL_DELAY_1_TIME] = cc_or_zero(cc_delay_1_time, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_time)))
  signals[SIGNAL_DELAY_1_FEEDBACK] = cc_or_zero(cc_delay_1_feedback, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_feedback)))
  signals[SIGNAL_DELAY_1_MIX] = cc_or_zero(cc_delay_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_mix)))
  signals[SIGNAL_GENERAL_MOD_WHEEL] = cc_or_zero(cc_general_mod_wheel, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_general_mod_wheel)))
  # Each General CC fills two slots, the same value taken both ways.
  general_1 = C.get_midi_cc_value(MIDI_CH, cc_general_1)
  general_2 = C.get_midi_cc_value(MIDI_CH, cc_general_2)
  general_3 = C.get_midi_cc_value(MIDI_CH, cc_general_3)
  general_4 = C.get_midi_cc_value(MIDI_CH, cc_general_4)
  signals[SIGNAL_GENERAL_UNIPOLAR_1] = cc_or_zero(cc_general_1, cc_to_unipolar(general_1))
  signals[SIGNAL_GENERAL_UNIPOLAR_2] = cc_or_zero(cc_general_2, cc_to_unipolar(general_2))
  signals[SIGNAL_GENERAL_UNIPOLAR_3] = cc_or_zero(cc_general_3, cc_to_unipolar(general_3))
  signals[SIGNAL_GENERAL_UNIPOLAR_4] = cc_or_zero(cc_general_4, cc_to_unipolar(general_4))
  signals[SIGNAL_GENERAL_BIPOLAR_1] = cc_or_zero(cc_general_1, cc_to_bipolar(general_1))
  signals[SIGNAL_GENERAL_BIPOLAR_2] = cc_or_zero(cc_general_2, cc_to_bipolar(general_2))
  signals[SIGNAL_GENERAL_BIPOLAR_3] = cc_or_zero(cc_general_3, cc_to_bipolar(general_3))
  signals[SIGNAL_GENERAL_BIPOLAR_4] = cc_or_zero(cc_general_4, cc_to_bipolar(general_4))

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
  chorus_1.set_rate(signals[source_chorus_1_rate])
  chorus_1.set_depth(signals[source_chorus_1_depth])
  chorus_1.set_mix(signals[source_chorus_1_mix])
  delay_1.set_time(signals[source_delay_1_time])
  delay_1.set_feedback(signals[source_delay_1_feedback])
  delay_1.set_mix(signals[source_delay_1_mix])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    slot = 0
    while slot < MODULES_SIZE
      module_id = active_modules[slot]
      break if module_id == MODULE_NONE

      # Spinel never emits a jump table however the Ruby is written, so a case costs one compare
      # per id up to the one that matches: 36 a sample at eight modules. Splitting the chain on a
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
      when MODULE_CHORUS_1
        chorus_1.process(signals[source_chorus_1_audio])
        signals[SIGNAL_CHORUS_1_OUTPUT_L] = chorus_1.output_l
        signals[SIGNAL_CHORUS_1_OUTPUT_R] = chorus_1.output_r
      when MODULE_DELAY_1
        delay_1.process(signals[source_delay_1_audio_l], signals[source_delay_1_audio_r])
        signals[SIGNAL_DELAY_1_OUTPUT_L] = delay_1.output_l
        signals[SIGNAL_DELAY_1_OUTPUT_R] = delay_1.output_r
      end

      slot += 1
    end

    audio_buffer_l[i] = signals[source_output_l]
    audio_buffer_r[i] = signals[source_output_r]
    i += 1
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer_l[i], audio_buffer_r[i])
  end
end
