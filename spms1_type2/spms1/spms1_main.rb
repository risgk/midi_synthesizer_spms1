require_relative 'spms1_dsp'
require_relative 'spms1_osc'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_lfo'
require_relative 'spms1_mixer'
require_relative 'spms1_chorus'
require_relative 'spms1_delay'
require_relative 'spms1_pitch'
require_relative 'spms1_noise'

# The patch is data: which modules run and in what order, what feeds each module input, where each
# parameter takes its value, and which CC fills each control slot all live in the NRPN table, read
# back every buffer so that MIDI can rewire the synth while it runs. README lists the numbers a
# controller sends. Two invariants the code leans on:
#
# - Every entry is 7-bit and every 7-bit value is legal, so nothing read back is validated. An
#   unknown module id falls through the dispatch, and any slot number is a real slot because the
#   bus is wider than 127: a parameter source of 127 is read as the parameter's own control slot,
#   which sits above that.
# - Module inputs are read per sample and reach their module unsmoothed; parameters are read once
#   per buffer and are smoothed by the module receiving them. Which of the two a signal arrives
#   through is what decides how fast it is allowed to move.
#
# Claims below about the generated C hold for the Spinel version vendored in spinel_rt.h.
# Re-check them on updating it.

module Spms1
  module C
    ffi_func :set_midi_note_on_pitch,     [:uint8, :uint8],          :void
    ffi_func :get_midi_note_on_pitch,     [:uint8],                  :uint8
    ffi_func :set_midi_note_on_state,     [:uint8, :uint8],          :void
    ffi_func :get_midi_note_on_state,     [:uint8],                  :uint8
    ffi_func :set_midi_pitch_bend,        [:uint8, :int32],          :void
    ffi_func :get_midi_pitch_bend,        [:uint8],                  :int32
    ffi_func :set_midi_cc_value,          [:uint8, :uint8, :uint8],  :void
    ffi_func :get_midi_cc_value,          [:uint8, :uint8],          :uint8
    ffi_func :set_midi_nrpn_value,        [:uint8, :int32, :uint8],  :void
    ffi_func :get_midi_nrpn_value,        [:uint8, :int32],          :uint8
    ffi_func :get_midi_run_order_written, [:uint8, :int32],          :int32
    ffi_func :set_sample_rate,            [:int32],                  :void
    ffi_func :get_sample_rate,            [],                        :int32
    ffi_func :set_audio_buffers,          [:int32],                  :void
    ffi_func :get_audio_buffers,          [],                        :int32
    ffi_func :set_audio_buffer_words,     [:int32],                  :void
    ffi_func :get_audio_buffer_words,     [],                        :int32
    ffi_func :start_audio,                [],                        :void
    ffi_func :stop_audio,                 [],                        :void
    ffi_func :write_to_audio_buffer,      [:float, :float],          :void
    ffi_func :start_debug_measure,        [],                        :void
    ffi_func :stop_debug_measure,         [],                        :void
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
# length; the per-sample walk runs to active_count, counted once a buffer up to that first
# MODULE_NONE. A module listed more than once runs once, at the slot written last.
MODULES_SIZE = 32

# The module ids (MODULE_*), in spms1_patch.rb: one of every module type that makes a sound, two
# mixers, one chorus, one delay, one pitch module, one noise source and two oscillators. Instances
# carry their number in the id rather than
# being indexed by one, so the second oscillator is MODULE_OSC_2, the next id after
# MODULE_NOISE_1 when it came: numbers only ever get added, at the end of their range (see spms1_patch.yaml),
# which is also why MODULE_PITCH_1 comes after MODULE_DELAY_1 though it runs before the oscillator.

# The slots of the `signals` bus (SIGNAL_*), in spms1_patch.rb: module outputs, the General
# control values, the constants and the note inputs in one namespace, 0-126, so a routing is just a
# slot number and one source can feed as many destinations as read its slot. Each parameter's own
# control slot (SLOT_*) is in the same array but above it, at 128 + the parameter's entry, where no
# routing can name it: a parameter reaches its own through a source of 127, SIGNAL_OWN, and
# nothing else reaches it at all. A CC that should feed a module input or another parameter goes
# through a General slot. So the parameters, however many, take nothing from the numbers a
# routing names. A slot is a plain float; its range is whatever the destination expects. Indexing an array
# is what holds a routed input to one read whatever the module count: passing the candidates in as
# arguments instead costs picks x candidates per sample, which grows quadratically.
# The constants come first so that SIGNAL_NONE is 0: an NRPN entry nobody has set reads 0, and an
# unrouted input should be silent rather than wired to whatever happens to sit in slot 0. Nothing
# ever writes them, so they hold what the bus was filled with at startup. They are what a routing
# reaches for when an input wants a fixed value rather than a source.
SIGNALS_SIZE = 256

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
# controller puts its detent. Pitch Coarse, Pitch Fine and Pitch 1 Coarse and Fine are
# bipolar, being offsets about that detent, and so are the polarities, whose sign is what they set. Both map CC 4..124 to the full range and
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

# Where a parameter reads: the bus slot its source names, or, for SIGNAL_OWN, its own control slot.
# 127 is SIGNAL_OWN written out, as Spinel emits a named Integer constant as a runtime global.
def source_or_own(source, own_slot)
  (source == 127) ? own_slot : source
end

lfo_1     = LFO.new(SAMPLE_RATE)
eg_1 = EnvGen.new(SAMPLE_RATE)
osc_1     = Osc.new(SAMPLE_RATE)
filter_1  = Filter.new(SAMPLE_RATE)
amp_1     = Amp.new(SAMPLE_RATE)
mixer_1   = Mixer.new(SAMPLE_RATE)
mixer_2   = Mixer.new(SAMPLE_RATE)
chorus_1  = Chorus.new(SAMPLE_RATE)
delay_1   = Delay.new(SAMPLE_RATE)
pitch_1    = Pitch.new(SAMPLE_RATE)
noise_1    = Noise.new(SAMPLE_RATE)
osc_2     = Osc.new(SAMPLE_RATE)

# Allocated once; which slots are filled is decided per buffer, inside the loop.
active_modules = Array.new(MODULES_SIZE, MODULE_NONE)
# The slot of the run order each module id runs at, by id: 128 entries, as an id read from NRPN
# is 7-bit. Only the entries of the ids listed in the same buffer are read, and those are reset
# first, so it is never cleared.
winning_slot = Array.new(128, 0)
# When each slot was last written, from spms1_midi_state.h, for the slots in the order.
order_written = Array.new(MODULES_SIZE, 0)

audio_buffer_l = Array.new(AUDIO_BUFFER_WORDS, 0.0)
audio_buffer_r = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# The signal bus: each module's latest output, in its SIGNAL_* slot. Declared out here so it
# carries across buffers, since a routing with feedback reads last sample's value and at a buffer
# edge that is the previous iteration's.
signals = Array.new(SIGNALS_SIZE, 0.0)
spms1_fill_constant_signals(signals)

# The default patch, written into the NRPN table the loop reads it back from. Every module is in
# the run order, so a patch only ever has to route, never to switch something on first. Pitch 1
# runs just ahead of the oscillator, taking Note Pitch and handing it to the oscillator: its Glide powers up at 0.0, where
# it passes its input through as it is, so the patch plays as one without it until CC 5 turns the
# portamento up. Pitch Bend goes to its Bend In, added past the glide, 2 semitones either way at
# Bend Amt's power-up value of CC 8, so the bend reaches the oscillator and the filter's keyboard
# tracking at once. Running after the LFO, the envelope, the noise and Mixer 1
# lets it take any of them in the same sample, and the oscillators and the filter read it so too. Mixer 1
# runs after the modulation sources and ahead of the oscillators, so it sees this sample's LFO,
# envelope and noise and can feed the oscillators, the filter and the amp without a sample's delay. The
# default patch leaves it unused: the LFO goes straight to the oscillator's pitch and pulse
# width at its full level, and Osc 1 Mod 2 Pol reads the constant 0.1, which brings it
# down to a vibrato depth on the pitch, so that Osc 1 Mod 2 Amt can span the whole pitch range
# the way every other modulation depth does. Osc 1 Pitch In takes the note from Pitch 1 whole,
# in tune. Osc 1 Mod 1 In takes the envelope, for a pitch envelope, but Mod 1 Amt powers up at
# 0.0 and leaves it off until CC 89; Mod 1 Pol reads +0.5. The LFO also reaches Filter 1 Mod 2 In, but Filter 1
# Mod 2 Amt powers up at 0.0, so the cutoff follows the envelope alone until CC 25 turns it up,
# and Filter 1 Mod 2 Pol reads 0.1, as Osc 1 Mod 2 Pol does. Filter 1 Mod 3 In takes Pitch 1's
# pitch too, for keyboard tracking, but Mod 3 Amt powers up at 0.0 and leaves it off until CC 9.
# Noise 1 runs ahead of the other modulation sources, at full level: its Level has no CC and reads
# 1.0. Mixer 2 runs after the oscillators, just ahead of the filter, which it feeds: Osc 1 on its
# In 1, Osc 2 on In 2 and the noise on In 3. Its Level 1, on CC 116, powers up at 1.0, and Level 2
# and Level 3, on CC 21 and 23, at 0.0, so Osc 2 is silent until CC 21 and the noise until CC 23.
# Osc 2 plays the note from Pitch 1,
# as Osc 1 does, tuned by its own Pitch Coarse and Fine (CC 85 and 76), 12 cents sharp at
# power-up, and has a Wave of its own on CC 104 (Osc 1's on CC 102); it follows Osc 1 in everything
# else: each of its amounts and its pulse width is on Osc 1's CC, so one CC moves both.
# Mixer 1 Level 1 and 2 are on CC 118 and 119 and power up at 0.0, and Level 3 and 4, with no CC,
# read their own slots, 0.0, so all four of its inputs start closed. Mixer 1's polarities and Out
# Level have no CC, and neither have Mixer 2's, so the default patch points them at constants
# instead: full level and a polarity of +0.5, which makes a mixer pass its input through rather
# than mute it.
# Each modulation polarity has no CC either and reads +0.5, which leaves the amount in charge,
# but for Osc 1 Mod 2's. LFO 1 Level is on CC 113 and powers up at 1.0, and the mod wheel on its Level
# Mod In adds to it up to that top; EG 1 Level has no CC and reads 1.0, passing the envelope as it
# is. The chorus and the delay run last, after the amp: the chorus
# takes the mono amp and spreads it into a left and a right, the delay takes the two sides, and
# its two outputs are what the final output's left and right read.
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

  signals[SIGNAL_NOTE_PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_NOTE_GATE]  = C.get_midi_note_on_state(MIDI_CH).to_f
  # Pitch bend arrives 14-bit and signed, -8192 to 8191, so a whole turn of the wheel is one unit
  # and half of it lands where the pitch domain's own half does. The count of steps is even, so
  # the middle of the range falls between -1 and 0 rather than on a value. Pairing the steps off
  # in the integers first puts -1 and 0 on the same one, which costs half the resolution -- 8193
  # steps, still far under a cent at any usable bend range -- and buys a centre that is exactly
  # zero with both ends exactly on -0.5 and +0.5. The division must floor for the bottom end to
  # land: Integer#/ does, and Spinel's sp_idiv implements it.
  signals[SIGNAL_PITCH_BEND]  = ((C.get_midi_pitch_bend(MIDI_CH) + 1) / 2).to_f * (1.0 / 8192.0)

  # The patch, read back from the NRPN table. active_modules is packed from the front with no
  # gaps; every source_* holds a SIGNAL_* bus slot, or a parameter's own SLOT_*.
  slot = 0
  while slot < MODULES_SIZE
    active_modules[slot] = C.get_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + slot)
    slot += 1
  end
  # The order up to the first MODULE_NONE, with when each of its slots was written.
  listed_count = 0
  while listed_count < MODULES_SIZE && active_modules[listed_count] != MODULE_NONE
    order_written[listed_count] = C.get_midi_run_order_written(MIDI_CH, listed_count)
    winning_slot[active_modules[listed_count]] = -1
    listed_count += 1
  end
  # A module listed twice would run twice a sample -- an LFO at twice its rate, a filter taking
  # two steps -- so it runs once, at the slot written last, and its other slots are dropped. Last
  # in time rather than in place, so that a module written to a slot ahead of where it was moves
  # there, as one written to a slot after it does. On a tie, never written alike, the later slot.
  slot = 0
  while slot < listed_count
    module_id = active_modules[slot]
    winner = winning_slot[module_id]
    if winner < 0 || order_written[slot] >= order_written[winner]
      winning_slot[module_id] = slot
    end
    slot += 1
  end
  # Packed in place: a slot is only ever written once it has been read. Counted here, once a
  # buffer, so the per-sample walk neither reads the MODULE_NONE that ends the order nor compares
  # every id against it.
  active_count = 0
  slot = 0
  while slot < listed_count
    module_id = active_modules[slot]
    if winning_slot[module_id] == slot
      active_modules[active_count] = module_id
      active_count += 1
    end
    slot += 1
  end

  source_eg_1_gate         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_EG_1_GATE)
  source_osc_1_pitch = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH)
  source_osc_1_mod_1 = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_1)
  source_osc_1_mod_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_2)
  source_filter_1_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_AUDIO)
  source_filter_1_mod_1    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_1)
  source_filter_1_mod_2    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_2)
  source_filter_1_mod_3    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_3)
  source_amp_1_audio       = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_AUDIO)
  source_amp_1_mod         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_MOD)
  source_mixer_1_in_1      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_1)
  source_mixer_1_in_2      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_2)
  source_mixer_1_in_3      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_3)
  source_mixer_1_in_4      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_IN_4)
  source_mixer_2_in_1      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_IN_1)
  source_mixer_2_in_2      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_IN_2)
  source_mixer_2_in_3      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_IN_3)
  source_mixer_2_in_4      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_IN_4)
  source_chorus_1_audio    = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_AUDIO)
  source_delay_1_audio_l   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_L)
  source_delay_1_audio_r   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_AUDIO_R)
  source_output_l          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_L)
  source_output_r          = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OUTPUT_R)
  source_pitch_1_pitch         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_PITCH)
  source_pitch_1_bend     = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_BEND)
  source_osc_1_pw_mod      = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PW_MOD)
  source_osc_2_pitch = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PITCH)
  source_osc_2_mod_1 = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_1)
  source_osc_2_mod_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_2)
  source_osc_2_pw_mod = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PW_MOD)
  source_lfo_1_rate_mod         = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE_MOD)
  source_lfo_1_level_mod   = C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL_MOD)

  # Parameter sources. Read once per buffer rather than per sample: each destination smooths at
  # the control rate with a 2.67 ms time constant, which swallows the difference between feeding
  # it at 48 kHz and at the 750 Hz buffer rate. Faster modulation goes through the module inputs
  # above, which are read per sample and not smoothed.
  source_lfo_1_rate            = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE), SLOT_LFO_1_RATE)
  source_lfo_1_level           = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL), SLOT_LFO_1_LEVEL)
  source_eg_1_attack           = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_EG_1_ATTACK), SLOT_EG_1_ATTACK)
  source_eg_1_decay            = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_EG_1_DECAY), SLOT_EG_1_DECAY)
  source_eg_1_sustain          = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_EG_1_SUSTAIN), SLOT_EG_1_SUSTAIN)
  source_eg_1_level            = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_EG_1_LEVEL), SLOT_EG_1_LEVEL)
  source_osc_1_wave            = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_WAVE), SLOT_OSC_1_WAVE)
  source_osc_1_pitch_coarse    = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH_COARSE), SLOT_OSC_1_PITCH_COARSE)
  source_osc_1_pitch_fine      = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PITCH_FINE), SLOT_OSC_1_PITCH_FINE)
  source_osc_1_mod_2_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_2_AMT), SLOT_OSC_1_MOD_2_AMT)
  source_osc_1_mod_2_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_2_POL), SLOT_OSC_1_MOD_2_POL)
  source_filter_1_cutoff       = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_CUTOFF), SLOT_FILTER_1_CUTOFF)
  source_filter_1_resonance    = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_RESONANCE), SLOT_FILTER_1_RESONANCE)
  source_filter_1_gain         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_GAIN), SLOT_FILTER_1_GAIN)
  source_filter_1_mod_1_amt    = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_1_AMT), SLOT_FILTER_1_MOD_1_AMT)
  source_filter_1_mod_1_pol    = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_1_POL), SLOT_FILTER_1_MOD_1_POL)
  source_amp_1_gain            = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_AMP_1_GAIN), SLOT_AMP_1_GAIN)
  source_mixer_1_level_1       = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_1), SLOT_MIXER_1_LEVEL_1)
  source_mixer_1_pol_1         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POL_1), SLOT_MIXER_1_POL_1)
  source_mixer_1_level_2       = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_2), SLOT_MIXER_1_LEVEL_2)
  source_mixer_1_pol_2         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POL_2), SLOT_MIXER_1_POL_2)
  source_chorus_1_rate         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_RATE), SLOT_CHORUS_1_RATE)
  source_chorus_1_depth        = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_DEPTH), SLOT_CHORUS_1_DEPTH)
  source_chorus_1_mix          = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_CHORUS_1_MIX), SLOT_CHORUS_1_MIX)
  source_delay_1_time          = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_TIME), SLOT_DELAY_1_TIME)
  source_delay_1_feedback      = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_FEEDBACK), SLOT_DELAY_1_FEEDBACK)
  source_delay_1_mix           = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_DELAY_1_MIX), SLOT_DELAY_1_MIX)
  source_pitch_1_glide           = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_GLIDE), SLOT_PITCH_1_GLIDE)
  source_osc_1_pulse_width     = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PULSE_WIDTH), SLOT_OSC_1_PULSE_WIDTH)
  source_osc_1_pw_mod_amt      = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PW_MOD_AMT), SLOT_OSC_1_PW_MOD_AMT)
  source_osc_1_pw_mod_pol      = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_PW_MOD_POL), SLOT_OSC_1_PW_MOD_POL)
  source_lfo_1_rate_mod_amt         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE_MOD_AMT), SLOT_LFO_1_RATE_MOD_AMT)
  source_lfo_1_rate_mod_pol         = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_RATE_MOD_POL), SLOT_LFO_1_RATE_MOD_POL)
  source_filter_1_mod_2_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_2_AMT), SLOT_FILTER_1_MOD_2_AMT)
  source_filter_1_mod_2_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_2_POL), SLOT_FILTER_1_MOD_2_POL)
  source_filter_1_mod_3_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_3_AMT), SLOT_FILTER_1_MOD_3_AMT)
  source_filter_1_mod_3_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_FILTER_1_MOD_3_POL), SLOT_FILTER_1_MOD_3_POL)
  source_pitch_1_bend_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_BEND_AMT), SLOT_PITCH_1_BEND_AMT)
  source_pitch_1_bend_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_BEND_POL), SLOT_PITCH_1_BEND_POL)
  source_lfo_1_level_mod_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT), SLOT_LFO_1_LEVEL_MOD_AMT)
  source_lfo_1_level_mod_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL), SLOT_LFO_1_LEVEL_MOD_POL)
  source_pitch_1_coarse = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_COARSE), SLOT_PITCH_1_COARSE)
  source_pitch_1_fine = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_FINE), SLOT_PITCH_1_FINE)
  source_mixer_1_out_level = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_OUT_LEVEL), SLOT_MIXER_1_OUT_LEVEL)
  source_osc_1_mod_1_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_1_AMT), SLOT_OSC_1_MOD_1_AMT)
  source_osc_1_mod_1_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_1_MOD_1_POL), SLOT_OSC_1_MOD_1_POL)
  source_noise_1_level = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_NOISE_1_LEVEL), SLOT_NOISE_1_LEVEL)
  source_osc_2_wave = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_WAVE), SLOT_OSC_2_WAVE)
  source_osc_2_pitch_coarse = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PITCH_COARSE), SLOT_OSC_2_PITCH_COARSE)
  source_osc_2_pitch_fine = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PITCH_FINE), SLOT_OSC_2_PITCH_FINE)
  source_osc_2_mod_1_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_1_AMT), SLOT_OSC_2_MOD_1_AMT)
  source_osc_2_mod_1_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_1_POL), SLOT_OSC_2_MOD_1_POL)
  source_osc_2_mod_2_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_2_AMT), SLOT_OSC_2_MOD_2_AMT)
  source_osc_2_mod_2_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_MOD_2_POL), SLOT_OSC_2_MOD_2_POL)
  source_osc_2_pulse_width = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PULSE_WIDTH), SLOT_OSC_2_PULSE_WIDTH)
  source_osc_2_pw_mod_amt = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PW_MOD_AMT), SLOT_OSC_2_PW_MOD_AMT)
  source_osc_2_pw_mod_pol = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_OSC_2_PW_MOD_POL), SLOT_OSC_2_PW_MOD_POL)
  source_mixer_1_level_3 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_3), SLOT_MIXER_1_LEVEL_3)
  source_mixer_1_pol_3 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POL_3), SLOT_MIXER_1_POL_3)
  source_mixer_1_level_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_LEVEL_4), SLOT_MIXER_1_LEVEL_4)
  source_mixer_1_pol_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_POL_4), SLOT_MIXER_1_POL_4)
  source_mixer_2_level_1 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_LEVEL_1), SLOT_MIXER_2_LEVEL_1)
  source_mixer_2_pol_1 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_POL_1), SLOT_MIXER_2_POL_1)
  source_mixer_2_level_2 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_LEVEL_2), SLOT_MIXER_2_LEVEL_2)
  source_mixer_2_pol_2 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_POL_2), SLOT_MIXER_2_POL_2)
  source_mixer_2_level_3 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_LEVEL_3), SLOT_MIXER_2_LEVEL_3)
  source_mixer_2_pol_3 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_POL_3), SLOT_MIXER_2_POL_3)
  source_mixer_2_level_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_LEVEL_4), SLOT_MIXER_2_LEVEL_4)
  source_mixer_2_pol_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_POL_4), SLOT_MIXER_2_POL_4)
  source_mixer_2_out_level = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_OUT_LEVEL), SLOT_MIXER_2_OUT_LEVEL)
  source_mixer_1_balance_1_2 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_BALANCE_1_2), SLOT_MIXER_1_BALANCE_1_2)
  source_mixer_1_balance_3_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_1_BALANCE_3_4), SLOT_MIXER_1_BALANCE_3_4)
  source_mixer_2_balance_1_2 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_BALANCE_1_2), SLOT_MIXER_2_BALANCE_1_2)
  source_mixer_2_balance_3_4 = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_MIXER_2_BALANCE_3_4), SLOT_MIXER_2_BALANCE_3_4)
  source_pitch_1_stretch = source_or_own(C.get_midi_nrpn_value(MIDI_CH, NRPN_SOURCE_PITCH_1_STRETCH), SLOT_PITCH_1_STRETCH)

  # Which CC fills each control slot. The signals array -- the bus and the parameters' own slots
  # above it -- is the only thing downstream reads, so this is where MIDI enters and the only
  # place a CC number appears.
  cc_lfo_1_rate            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE)
  cc_lfo_1_level           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_LEVEL)
  cc_eg_1_attack           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_EG_1_ATTACK)
  cc_eg_1_decay            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_EG_1_DECAY)
  cc_eg_1_sustain          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_EG_1_SUSTAIN)
  cc_eg_1_level            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_EG_1_LEVEL)
  cc_osc_1_wave            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_WAVE)
  cc_osc_1_pitch_coarse    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_PITCH_COARSE)
  cc_osc_1_pitch_fine      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_PITCH_FINE)
  cc_osc_1_mod_2_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_2_AMT)
  cc_osc_1_mod_2_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_2_POL)
  cc_filter_1_cutoff       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_CUTOFF)
  cc_filter_1_resonance    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_RESONANCE)
  cc_filter_1_gain         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_GAIN)
  cc_filter_1_mod_1_amt    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_1_AMT)
  cc_filter_1_mod_1_pol    = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_1_POL)
  cc_amp_1_gain            = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_AMP_1_GAIN)
  cc_mixer_1_level_1       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_1)
  cc_mixer_1_pol_1         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POL_1)
  cc_mixer_1_level_2       = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_2)
  cc_mixer_1_pol_2         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POL_2)
  cc_chorus_1_rate         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_RATE)
  cc_chorus_1_depth        = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_DEPTH)
  cc_chorus_1_mix          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_CHORUS_1_MIX)
  cc_delay_1_time          = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_TIME)
  cc_delay_1_feedback      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_FEEDBACK)
  cc_delay_1_mix           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_DELAY_1_MIX)
  cc_pitch_1_glide           = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_GLIDE)
  cc_osc_1_pulse_width     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_PULSE_WIDTH)
  cc_osc_1_pw_mod_amt      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_PW_MOD_AMT)
  cc_osc_1_pw_mod_pol      = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_PW_MOD_POL)
  cc_lfo_1_rate_mod_amt         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE_MOD_AMT)
  cc_lfo_1_rate_mod_pol         = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_RATE_MOD_POL)
  cc_filter_1_mod_2_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_2_AMT)
  cc_filter_1_mod_2_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_2_POL)
  cc_filter_1_mod_3_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_3_AMT)
  cc_filter_1_mod_3_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_FILTER_1_MOD_3_POL)
  cc_pitch_1_bend_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_BEND_AMT)
  cc_pitch_1_bend_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_BEND_POL)
  cc_lfo_1_level_mod_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_LEVEL_MOD_AMT)
  cc_lfo_1_level_mod_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_LFO_1_LEVEL_MOD_POL)
  cc_pitch_1_coarse = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_COARSE)
  cc_pitch_1_fine = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_FINE)
  cc_mixer_1_out_level = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_OUT_LEVEL)
  cc_osc_1_mod_1_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_1_AMT)
  cc_osc_1_mod_1_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_1_MOD_1_POL)
  cc_noise_1_level = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_NOISE_1_LEVEL)
  cc_osc_2_wave = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_WAVE)
  cc_osc_2_pitch_coarse = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_PITCH_COARSE)
  cc_osc_2_pitch_fine = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_PITCH_FINE)
  cc_osc_2_mod_1_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_MOD_1_AMT)
  cc_osc_2_mod_1_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_MOD_1_POL)
  cc_osc_2_mod_2_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_MOD_2_AMT)
  cc_osc_2_mod_2_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_MOD_2_POL)
  cc_osc_2_pulse_width = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_PULSE_WIDTH)
  cc_osc_2_pw_mod_amt = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_PW_MOD_AMT)
  cc_osc_2_pw_mod_pol = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_OSC_2_PW_MOD_POL)
  cc_mixer_1_level_3 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_3)
  cc_mixer_1_pol_3 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POL_3)
  cc_mixer_1_level_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_LEVEL_4)
  cc_mixer_1_pol_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_POL_4)
  cc_mixer_2_level_1 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_LEVEL_1)
  cc_mixer_2_pol_1 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_POL_1)
  cc_mixer_2_level_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_LEVEL_2)
  cc_mixer_2_pol_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_POL_2)
  cc_mixer_2_level_3 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_LEVEL_3)
  cc_mixer_2_pol_3 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_POL_3)
  cc_mixer_2_level_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_LEVEL_4)
  cc_mixer_2_pol_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_POL_4)
  cc_mixer_2_out_level = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_OUT_LEVEL)
  cc_mixer_1_balance_1_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_BALANCE_1_2)
  cc_mixer_1_balance_3_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_1_BALANCE_3_4)
  cc_mixer_2_balance_1_2 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_BALANCE_1_2)
  cc_mixer_2_balance_3_4 = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_MIXER_2_BALANCE_3_4)
  cc_pitch_1_stretch = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_PITCH_1_STRETCH)
  cc_general_mod_wheel     = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_MOD_WHEEL)
  cc_general_1             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_1)
  cc_general_2             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_2)
  cc_general_3             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_3)
  cc_general_4             = C.get_midi_nrpn_value(MIDI_CH, NRPN_CC_GENERAL_4)

  signals[SLOT_LFO_1_RATE] = cc_or_zero(cc_lfo_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate)))
  signals[SLOT_LFO_1_LEVEL] = cc_or_zero(cc_lfo_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level)))
  signals[SLOT_EG_1_ATTACK] = cc_or_zero(cc_eg_1_attack, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_eg_1_attack)))
  signals[SLOT_EG_1_DECAY] = cc_or_zero(cc_eg_1_decay, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_eg_1_decay)))
  signals[SLOT_EG_1_SUSTAIN] = cc_or_zero(cc_eg_1_sustain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_eg_1_sustain)))
  signals[SLOT_EG_1_LEVEL] = cc_or_zero(cc_eg_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_eg_1_level)))
  signals[SLOT_OSC_1_WAVE] = cc_or_zero(cc_osc_1_wave, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_wave)))
  signals[SLOT_OSC_1_PITCH_COARSE] = cc_or_zero(cc_osc_1_pitch_coarse, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_pitch_coarse)))
  signals[SLOT_OSC_1_PITCH_FINE] = cc_or_zero(cc_osc_1_pitch_fine, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_pitch_fine)))
  signals[SLOT_OSC_1_MOD_2_AMT] = cc_or_zero(cc_osc_1_mod_2_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_2_amt)))
  signals[SLOT_OSC_1_MOD_2_POL] = cc_or_zero(cc_osc_1_mod_2_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_2_pol)))
  signals[SLOT_FILTER_1_CUTOFF] = cc_or_zero(cc_filter_1_cutoff, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_cutoff)))
  signals[SLOT_FILTER_1_RESONANCE] = cc_or_zero(cc_filter_1_resonance, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_resonance)))
  signals[SLOT_FILTER_1_GAIN] = cc_or_zero(cc_filter_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_gain)))
  signals[SLOT_FILTER_1_MOD_1_AMT] = cc_or_zero(cc_filter_1_mod_1_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_1_amt)))
  signals[SLOT_FILTER_1_MOD_1_POL] = cc_or_zero(cc_filter_1_mod_1_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_1_pol)))
  signals[SLOT_AMP_1_GAIN] = cc_or_zero(cc_amp_1_gain, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_amp_1_gain)))
  signals[SLOT_MIXER_1_LEVEL_1] = cc_or_zero(cc_mixer_1_level_1, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_1)))
  signals[SLOT_MIXER_1_POL_1] = cc_or_zero(cc_mixer_1_pol_1, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_pol_1)))
  signals[SLOT_MIXER_1_LEVEL_2] = cc_or_zero(cc_mixer_1_level_2, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_2)))
  signals[SLOT_MIXER_1_POL_2] = cc_or_zero(cc_mixer_1_pol_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_pol_2)))
  signals[SLOT_CHORUS_1_RATE] = cc_or_zero(cc_chorus_1_rate, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_rate)))
  signals[SLOT_CHORUS_1_DEPTH] = cc_or_zero(cc_chorus_1_depth, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_depth)))
  signals[SLOT_CHORUS_1_MIX] = cc_or_zero(cc_chorus_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_chorus_1_mix)))
  signals[SLOT_DELAY_1_TIME] = cc_or_zero(cc_delay_1_time, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_time)))
  signals[SLOT_DELAY_1_FEEDBACK] = cc_or_zero(cc_delay_1_feedback, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_feedback)))
  signals[SLOT_DELAY_1_MIX] = cc_or_zero(cc_delay_1_mix, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_delay_1_mix)))
  signals[SLOT_PITCH_1_GLIDE] = cc_or_zero(cc_pitch_1_glide, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_glide)))
  signals[SLOT_OSC_1_PULSE_WIDTH] = cc_or_zero(cc_osc_1_pulse_width, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_pulse_width)))
  signals[SLOT_OSC_1_PW_MOD_AMT] = cc_or_zero(cc_osc_1_pw_mod_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_pw_mod_amt)))
  signals[SLOT_OSC_1_PW_MOD_POL] = cc_or_zero(cc_osc_1_pw_mod_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_pw_mod_pol)))
  signals[SLOT_LFO_1_RATE_MOD_AMT] = cc_or_zero(cc_lfo_1_rate_mod_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate_mod_amt)))
  signals[SLOT_LFO_1_RATE_MOD_POL] = cc_or_zero(cc_lfo_1_rate_mod_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_rate_mod_pol)))
  signals[SLOT_FILTER_1_MOD_2_AMT] = cc_or_zero(cc_filter_1_mod_2_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_2_amt)))
  signals[SLOT_FILTER_1_MOD_2_POL] = cc_or_zero(cc_filter_1_mod_2_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_2_pol)))
  signals[SLOT_FILTER_1_MOD_3_AMT] = cc_or_zero(cc_filter_1_mod_3_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_3_amt)))
  signals[SLOT_FILTER_1_MOD_3_POL] = cc_or_zero(cc_filter_1_mod_3_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_filter_1_mod_3_pol)))
  signals[SLOT_PITCH_1_BEND_AMT] = cc_or_zero(cc_pitch_1_bend_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_bend_amt)))
  signals[SLOT_PITCH_1_BEND_POL] = cc_or_zero(cc_pitch_1_bend_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_bend_pol)))
  signals[SLOT_LFO_1_LEVEL_MOD_AMT] = cc_or_zero(cc_lfo_1_level_mod_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level_mod_amt)))
  signals[SLOT_LFO_1_LEVEL_MOD_POL] = cc_or_zero(cc_lfo_1_level_mod_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_lfo_1_level_mod_pol)))
  signals[SLOT_PITCH_1_COARSE] = cc_or_zero(cc_pitch_1_coarse, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_coarse)))
  signals[SLOT_PITCH_1_FINE] = cc_or_zero(cc_pitch_1_fine, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_fine)))
  signals[SLOT_MIXER_1_OUT_LEVEL] = cc_or_zero(cc_mixer_1_out_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_out_level)))
  signals[SLOT_OSC_1_MOD_1_AMT] = cc_or_zero(cc_osc_1_mod_1_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_1_amt)))
  signals[SLOT_OSC_1_MOD_1_POL] = cc_or_zero(cc_osc_1_mod_1_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_1_mod_1_pol)))
  signals[SLOT_NOISE_1_LEVEL] = cc_or_zero(cc_noise_1_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_noise_1_level)))
  signals[SLOT_OSC_2_WAVE] = cc_or_zero(cc_osc_2_wave, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_wave)))
  signals[SLOT_OSC_2_PITCH_COARSE] = cc_or_zero(cc_osc_2_pitch_coarse, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_pitch_coarse)))
  signals[SLOT_OSC_2_PITCH_FINE] = cc_or_zero(cc_osc_2_pitch_fine, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_pitch_fine)))
  signals[SLOT_OSC_2_MOD_1_AMT] = cc_or_zero(cc_osc_2_mod_1_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_mod_1_amt)))
  signals[SLOT_OSC_2_MOD_1_POL] = cc_or_zero(cc_osc_2_mod_1_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_mod_1_pol)))
  signals[SLOT_OSC_2_MOD_2_AMT] = cc_or_zero(cc_osc_2_mod_2_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_mod_2_amt)))
  signals[SLOT_OSC_2_MOD_2_POL] = cc_or_zero(cc_osc_2_mod_2_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_mod_2_pol)))
  signals[SLOT_OSC_2_PULSE_WIDTH] = cc_or_zero(cc_osc_2_pulse_width, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_pulse_width)))
  signals[SLOT_OSC_2_PW_MOD_AMT] = cc_or_zero(cc_osc_2_pw_mod_amt, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_pw_mod_amt)))
  signals[SLOT_OSC_2_PW_MOD_POL] = cc_or_zero(cc_osc_2_pw_mod_pol, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_osc_2_pw_mod_pol)))
  signals[SLOT_MIXER_1_LEVEL_3] = cc_or_zero(cc_mixer_1_level_3, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_3)))
  signals[SLOT_MIXER_1_POL_3] = cc_or_zero(cc_mixer_1_pol_3, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_pol_3)))
  signals[SLOT_MIXER_1_LEVEL_4] = cc_or_zero(cc_mixer_1_level_4, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_level_4)))
  signals[SLOT_MIXER_1_POL_4] = cc_or_zero(cc_mixer_1_pol_4, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_pol_4)))
  signals[SLOT_MIXER_2_LEVEL_1] = cc_or_zero(cc_mixer_2_level_1, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_level_1)))
  signals[SLOT_MIXER_2_POL_1] = cc_or_zero(cc_mixer_2_pol_1, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_pol_1)))
  signals[SLOT_MIXER_2_LEVEL_2] = cc_or_zero(cc_mixer_2_level_2, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_level_2)))
  signals[SLOT_MIXER_2_POL_2] = cc_or_zero(cc_mixer_2_pol_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_pol_2)))
  signals[SLOT_MIXER_2_LEVEL_3] = cc_or_zero(cc_mixer_2_level_3, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_level_3)))
  signals[SLOT_MIXER_2_POL_3] = cc_or_zero(cc_mixer_2_pol_3, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_pol_3)))
  signals[SLOT_MIXER_2_LEVEL_4] = cc_or_zero(cc_mixer_2_level_4, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_level_4)))
  signals[SLOT_MIXER_2_POL_4] = cc_or_zero(cc_mixer_2_pol_4, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_pol_4)))
  signals[SLOT_MIXER_2_OUT_LEVEL] = cc_or_zero(cc_mixer_2_out_level, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_out_level)))
  signals[SLOT_MIXER_1_BALANCE_1_2] = cc_or_zero(cc_mixer_1_balance_1_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_balance_1_2)))
  signals[SLOT_MIXER_1_BALANCE_3_4] = cc_or_zero(cc_mixer_1_balance_3_4, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_1_balance_3_4)))
  signals[SLOT_MIXER_2_BALANCE_1_2] = cc_or_zero(cc_mixer_2_balance_1_2, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_balance_1_2)))
  signals[SLOT_MIXER_2_BALANCE_3_4] = cc_or_zero(cc_mixer_2_balance_3_4, cc_to_bipolar(C.get_midi_cc_value(MIDI_CH, cc_mixer_2_balance_3_4)))
  signals[SLOT_PITCH_1_STRETCH] = cc_or_zero(cc_pitch_1_stretch, cc_to_unipolar(C.get_midi_cc_value(MIDI_CH, cc_pitch_1_stretch)))
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
  eg_1.set_attack(signals[source_eg_1_attack])
  eg_1.set_decay(signals[source_eg_1_decay])
  eg_1.set_sustain(signals[source_eg_1_sustain])
  eg_1.set_level(signals[source_eg_1_level])
  osc_1.set_waveform(signals[source_osc_1_wave])
  osc_1.set_pitch_coarse(signals[source_osc_1_pitch_coarse])
  osc_1.set_pitch_fine(signals[source_osc_1_pitch_fine])
  osc_1.set_modulation_2_amount(signals[source_osc_1_mod_2_amt])
  osc_1.set_modulation_2_polarity(signals[source_osc_1_mod_2_pol])
  filter_1.set_cutoff(signals[source_filter_1_cutoff])
  filter_1.set_resonance(signals[source_filter_1_resonance])
  filter_1.set_gain(signals[source_filter_1_gain])
  filter_1.set_modulation_1_amount(signals[source_filter_1_mod_1_amt])
  filter_1.set_modulation_1_polarity(signals[source_filter_1_mod_1_pol])
  filter_1.set_modulation_2_amount(signals[source_filter_1_mod_2_amt])
  filter_1.set_modulation_2_polarity(signals[source_filter_1_mod_2_pol])
  filter_1.set_modulation_3_amount(signals[source_filter_1_mod_3_amt])
  filter_1.set_modulation_3_polarity(signals[source_filter_1_mod_3_pol])
  amp_1.set_gain(signals[source_amp_1_gain])
  mixer_1.set_level_1(signals[source_mixer_1_level_1])
  mixer_1.set_polarity_1(signals[source_mixer_1_pol_1])
  mixer_1.set_level_2(signals[source_mixer_1_level_2])
  mixer_1.set_polarity_2(signals[source_mixer_1_pol_2])
  mixer_1.set_out_level(signals[source_mixer_1_out_level])
  osc_1.set_modulation_1_amount(signals[source_osc_1_mod_1_amt])
  osc_1.set_modulation_1_polarity(signals[source_osc_1_mod_1_pol])
  noise_1.set_level(signals[source_noise_1_level])
  osc_2.set_waveform(signals[source_osc_2_wave])
  osc_2.set_pitch_coarse(signals[source_osc_2_pitch_coarse])
  osc_2.set_pitch_fine(signals[source_osc_2_pitch_fine])
  osc_2.set_modulation_1_amount(signals[source_osc_2_mod_1_amt])
  osc_2.set_modulation_1_polarity(signals[source_osc_2_mod_1_pol])
  osc_2.set_modulation_2_amount(signals[source_osc_2_mod_2_amt])
  osc_2.set_modulation_2_polarity(signals[source_osc_2_mod_2_pol])
  osc_2.set_pulse_width(signals[source_osc_2_pulse_width])
  osc_2.set_pw_modulation_amount(signals[source_osc_2_pw_mod_amt])
  osc_2.set_pw_modulation_polarity(signals[source_osc_2_pw_mod_pol])
  mixer_1.set_level_3(signals[source_mixer_1_level_3])
  mixer_1.set_polarity_3(signals[source_mixer_1_pol_3])
  mixer_1.set_level_4(signals[source_mixer_1_level_4])
  mixer_1.set_polarity_4(signals[source_mixer_1_pol_4])
  mixer_2.set_level_1(signals[source_mixer_2_level_1])
  mixer_2.set_polarity_1(signals[source_mixer_2_pol_1])
  mixer_2.set_level_2(signals[source_mixer_2_level_2])
  mixer_2.set_polarity_2(signals[source_mixer_2_pol_2])
  mixer_2.set_level_3(signals[source_mixer_2_level_3])
  mixer_2.set_polarity_3(signals[source_mixer_2_pol_3])
  mixer_2.set_level_4(signals[source_mixer_2_level_4])
  mixer_2.set_polarity_4(signals[source_mixer_2_pol_4])
  mixer_2.set_out_level(signals[source_mixer_2_out_level])
  mixer_1.set_balance_1_2(signals[source_mixer_1_balance_1_2])
  mixer_1.set_balance_3_4(signals[source_mixer_1_balance_3_4])
  mixer_2.set_balance_1_2(signals[source_mixer_2_balance_1_2])
  mixer_2.set_balance_3_4(signals[source_mixer_2_balance_3_4])
  pitch_1.set_stretch(signals[source_pitch_1_stretch])
  chorus_1.set_rate(signals[source_chorus_1_rate])
  chorus_1.set_depth(signals[source_chorus_1_depth])
  chorus_1.set_mix(signals[source_chorus_1_mix])
  delay_1.set_time(signals[source_delay_1_time])
  delay_1.set_feedback(signals[source_delay_1_feedback])
  delay_1.set_mix(signals[source_delay_1_mix])
  pitch_1.set_glide(signals[source_pitch_1_glide])
  pitch_1.set_bend_amount(signals[source_pitch_1_bend_amt])
  pitch_1.set_bend_polarity(signals[source_pitch_1_bend_pol])
  pitch_1.set_coarse(signals[source_pitch_1_coarse])
  pitch_1.set_fine(signals[source_pitch_1_fine])
  osc_1.set_pulse_width(signals[source_osc_1_pulse_width])
  osc_1.set_pw_modulation_amount(signals[source_osc_1_pw_mod_amt])
  osc_1.set_pw_modulation_polarity(signals[source_osc_1_pw_mod_pol])
  lfo_1.set_rate_modulation_amount(signals[source_lfo_1_rate_mod_amt])
  lfo_1.set_rate_modulation_polarity(signals[source_lfo_1_rate_mod_pol])
  lfo_1.set_level_modulation_amount(signals[source_lfo_1_level_mod_amt])
  lfo_1.set_level_modulation_polarity(signals[source_lfo_1_level_mod_pol])

  i = 0
  while i < AUDIO_BUFFER_WORDS
    # The control tick, every module's cue for its control-rate update, once every 4 samples
    # (CONTROL_RATE_DIVISOR in each module). Taken here once a sample rather than counted by each
    # module: a counter of each module's own cost an add, a mask and a load and store of a 64-bit
    # instance variable a sample, about 6% of the buffer at twelve modules (1247us to 1174us,
    # emulated). The buffer is a multiple of 4 samples, so the tick keeps its phase across buffers,
    # and every module ticks on the same samples, whenever it joined the run order.
    control_tick = (i & 3) == 0
    slot = 0
    while slot < active_count
      module_id = active_modules[slot]

      # Spinel never emits a jump table however the Ruby is written, so a case costs one compare
      # per id up to the one that matches: 78 a sample at twelve modules. Splitting the chain on a
      # kind of module pays only once that kind has several instances. Where a module sits in the
      # chain moves the cost between modules but not the total, so one added later goes at the
      # end whatever its place in the run order, and leaves what the others cost as it was.
      #
      # The ids are literals, each with its constant's name after it, and so are the bus slots the
      # outputs go to; patch_gen writes the numbers from spms1_patch.yaml (--check catches one out
      # of step). Spinel emits an Integer constant as a runtime global, so `when MODULE_LFO_1`
      # loaded its address and then its value before every compare, and `signals[SIGNAL_...]`
      # before every write; a literal is an immediate. The ids took 10.6% of the instructions out
      # of a buffer of the default patch (100.5k to 89.8k, emulated Cortex-M33), and the slots
      # with active_count above another 4.4% (to 85.8k).
      case module_id
      when 1 # MODULE_LFO_1
        signals[9] = lfo_1.process(control_tick, signals[source_lfo_1_rate_mod], signals[source_lfo_1_level_mod]) # SIGNAL_LFO_1_OUTPUT
      when 2 # MODULE_EG_1
        signals[10] = eg_1.process(control_tick, signals[source_eg_1_gate]) # SIGNAL_EG_1_OUTPUT
      when 3 # MODULE_OSC_1
        signals[11] = osc_1.process(control_tick, signals[source_osc_1_pitch], signals[source_osc_1_mod_1], signals[source_osc_1_mod_2], signals[source_osc_1_pw_mod]) # SIGNAL_OSC_1_OUTPUT
      when 4 # MODULE_FILTER_1
        signals[12] = filter_1.process(control_tick, signals[source_filter_1_audio], signals[source_filter_1_mod_1], signals[source_filter_1_mod_2], signals[source_filter_1_mod_3]) # SIGNAL_FILTER_1_OUTPUT_LP
        signals[65] = filter_1.output_bp # SIGNAL_FILTER_1_OUTPUT_BP
        signals[66] = filter_1.output_hp # SIGNAL_FILTER_1_OUTPUT_HP
      when 5 # MODULE_AMP_1
        signals[13] = amp_1.process(control_tick, signals[source_amp_1_audio], signals[source_amp_1_mod]) # SIGNAL_AMP_1_OUTPUT
      when 6 # MODULE_MIXER_1
        signals[14] = mixer_1.process(control_tick, signals[source_mixer_1_in_1], signals[source_mixer_1_in_2], signals[source_mixer_1_in_3], signals[source_mixer_1_in_4]) # SIGNAL_MIXER_1_OUTPUT
      when 7 # MODULE_CHORUS_1
        chorus_1.process(control_tick, signals[source_chorus_1_audio])
        signals[15] = chorus_1.output_l # SIGNAL_CHORUS_1_OUTPUT_L
        signals[16] = chorus_1.output_r # SIGNAL_CHORUS_1_OUTPUT_R
      when 8 # MODULE_DELAY_1
        delay_1.process(control_tick, signals[source_delay_1_audio_l], signals[source_delay_1_audio_r])
        signals[17] = delay_1.output_l # SIGNAL_DELAY_1_OUTPUT_L
        signals[18] = delay_1.output_r # SIGNAL_DELAY_1_OUTPUT_R
      when 9 # MODULE_PITCH_1
        signals[60] = pitch_1.process(control_tick, signals[source_pitch_1_pitch], signals[source_pitch_1_bend]) # SIGNAL_PITCH_1_OUTPUT
      when 10 # MODULE_NOISE_1
        signals[86] = noise_1.process(control_tick) # SIGNAL_NOISE_1_OUTPUT_WHITE
        signals[116] = noise_1.output_red # SIGNAL_NOISE_1_OUTPUT_RED
        signals[118] = noise_1.output_lf_1 # SIGNAL_NOISE_1_OUTPUT_LF_1
        signals[119] = noise_1.output_lf_2 # SIGNAL_NOISE_1_OUTPUT_LF_2
      when 11 # MODULE_OSC_2
        signals[88] = osc_2.process(control_tick, signals[source_osc_2_pitch], signals[source_osc_2_mod_1], signals[source_osc_2_mod_2], signals[source_osc_2_pw_mod]) # SIGNAL_OSC_2_OUTPUT
      when 12 # MODULE_MIXER_2
        signals[106] = mixer_2.process(control_tick, signals[source_mixer_2_in_1], signals[source_mixer_2_in_2], signals[source_mixer_2_in_3], signals[source_mixer_2_in_4]) # SIGNAL_MIXER_2_OUTPUT
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
