require_relative 'spms1_framework'
require_relative 'spms1_dsp'
# The file of each module class in spms1_patch.yaml, spms1_ and the class in snake case. Written by
# patch_gen.
# patch_gen requires
require_relative 'spms1_pitch'
require_relative 'spms1_env_gen'
require_relative 'spms1_lfo'
require_relative 'spms1_mixer'
require_relative 'spms1_osc'
require_relative 'spms1_noise'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_chorus'
require_relative 'spms1_delay'
# patch_gen end

# The loop that runs the patch. The framework rules -- the invariants of the patch and the worst
# case of a buffer -- are in spms1_framework.rb, with the functions the host provides.

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

# The module ids (MODULE_*), in spms1_patch.rb: fourteen in all, two envelopes, two mixers, two
# oscillators and two filters, and one each of the pitch module, the LFO, the noise source, the amp,
# the chorus and the delay, numbered in the default run order (see spms1_patch.yaml). Instances carry their number in the id rather
# than being indexed by one, so the second oscillator is MODULE_OSC_2.

# The slots of the `signals` bus (SIGNAL_*), in spms1_patch.rb: the constants, the note inputs,
# the mod wheel, the general controls and the module outputs in one namespace, 0-126, so a routing is just a
# slot number and one source can feed as many destinations as read its slot. Each parameter's own
# control slot (SLOT_*) is in the same array but above it, at 128 + the parameter's entry, where no
# routing can name it: a parameter reaches its own through a source of 127, SIGNAL_OWN, and
# nothing else reaches it at all. A CC that should feed a module input or another parameter goes
# through the mod wheel's slot or a general control's. So the parameters, however many, take nothing from the numbers a
# routing names. A slot is a plain float; its range is whatever the destination expects. Indexing an array
# is what holds a routed input to one read whatever the module count: passing the candidates in as
# arguments instead costs picks x candidates per sample, which grows quadratically.
# The constants come first so that SIGNAL_NONE is 0: an NRPN entry nobody has set reads 0, and an
# unrouted input should be silent rather than wired to whatever happens to sit in slot 0. Nothing
# ever writes them, so they hold what the bus was filled with at startup. They are what a routing
# reaches for when an input wants a fixed value rather than a source.
# SPMS1_BUS_SIZE in spms1_bus.h, the host's array that holds the slots, is the same.
SIGNALS_SIZE = 512

# The controller slots -- the mod wheel's and the general controls' -- are filled once a buffer
# from their CCs and not smoothed, as a parameter that takes one smooths it itself. A module input
# reads them per sample with no smoothing of its own, and would step with every CC step, so it
# reads a copy instead, smoothed as a parameter would smooth it, two stages of 10.7 ms on average,
# written once a buffer with the rest at the top of `signals`, off the bus (SMOOTHED_SLOT_OFFSET,
# in spms1_patch.rb). A buffer is AUDIO_BUFFER_WORDS / 4 control-rate steps, 16 at 64 samples, so
# each stage takes the blend the modules take at each step that many times over, and keeps the
# same time for any buffer size that is a whole number of steps. The copies of every controller
# are made every buffer whatever reads them, so that they cost the same for any patch. A gate
# input -- Gate In, Reset In, Sync In -- acts at a threshold or an edge and takes the slot as it is.
CONTROLLER_SMOOTHING_BLEND = 1.0 - (1.0 - 0.015625 * (48000.0 / SAMPLE_RATE.to_f)) ** (AUDIO_BUFFER_WORDS.to_f / 4.0)

# The output fader: a linear fade of the output out and in, of at least 3 ms, in
# whole buffers, 4 ms at 64 samples. It fades out at Mute on (NRPN 117/0, see spms1_midi_state.h),
# as a patch is sent, and holds the output silent until Mute is off. Every Mute on is taken,
# however soon Mute off follows it, so a patch sent between them is never heard at full level;
# what changes during a fade, 4 ms, is let be. A fade that has begun runs to its end before the
# next one. Where it is is counted in samples, an Integer, and the gain worked out from it at the
# start of each buffer, so that it lands on exactly 0.0 or 1.0 at the end of a fade; within a
# buffer the gain takes a step a sample. The gain multiplies the output as it is written, every
# sample whether or not it fades, which costs a multiply a side, and a buffer that fades costs the
# same as one that does not. The modules run on while the output is silent, and it stays silent
# for OUTPUT_HOLD_BUFFERS (11 ms) at least, so that the lines of the chorus and the amp's limiter,
# 11 ms and less, hold nothing of the patch from before Mute on. The delay's line, 340 ms, is left
# as it is, and its repeats come back with the output, as they would from a delay after the
# synth. A Save (NRPN 117/2), which comes while Mute is on, is written to the flash once the output
# is silent: writing it stops both cores for up to 100 ms, while the audio plays the silence the
# host fills its buffer with (see store_patch_image in spms1_midi_state.h). It is written after
# the buffer is, outside the span that Debug Print measures.
OUTPUT_FADE_SAMPLES = (SAMPLE_RATE * 3 / 1000 + AUDIO_BUFFER_WORDS - 1) / AUDIO_BUFFER_WORDS * AUDIO_BUFFER_WORDS
OUTPUT_FADE_STEP    = 1.0 / OUTPUT_FADE_SAMPLES.to_f
OUTPUT_HOLD_BUFFERS = (SAMPLE_RATE * 11 / 1000 + AUDIO_BUFFER_WORDS - 1) / AUDIO_BUFFER_WORDS

# The NRPN parameter numbers (NRPN_*), in spms1_patch.rb: (category << 7) | LSB, where the MSB,
# 112 + category, picks a category and the LSB an entry.
#   0..127   the run order, the module of each slot
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
# 512..639   the value of each parameter's control slot while it has no CC
# A CC number of 0 means the control has no CC: a parameter's control slot then holds its value
# from 512.., whatever CC it had before, so a patch sets it alone, and a controller's slot holds 0.0.

# One instance of each module, by its class in spms1_patch.yaml. Written by patch_gen.
# patch_gen instances
pitch_1 = Pitch.new(SAMPLE_RATE)
eg_1 = EnvGen.new(SAMPLE_RATE)
eg_2 = EnvGen.new(SAMPLE_RATE)
lfo_1 = LFO.new(SAMPLE_RATE)
mixer_1 = Mixer.new(SAMPLE_RATE)
osc_1 = Osc.new(SAMPLE_RATE)
osc_2 = Osc.new(SAMPLE_RATE)
noise_1 = Noise.new(SAMPLE_RATE)
mixer_2 = Mixer.new(SAMPLE_RATE)
filter_1 = Filter.new(SAMPLE_RATE)
filter_2 = Filter.new(SAMPLE_RATE)
amp_1 = Amp.new(SAMPLE_RATE)
chorus_1 = Chorus.new(SAMPLE_RATE)
delay_1 = Delay.new(SAMPLE_RATE)
# patch_gen end

# The run order, the module of each slot, is C.get_active_module and C.set_active_module, a C array
# of the host's as the signal bus is (spms1_bus.h), as the per-sample dispatch reads it for every
# module it runs; which slots are filled is decided per buffer, inside the loop.
# The slot of the run order each module id runs at, by id: 128 entries, as an id read from NRPN
# is 7-bit. Only the entries of the ids listed in the same buffer are read, and those are reset
# first, so it is never cleared.
winning_slot = Array.new(128, 0)
# When each slot was last written, from spms1_midi_state.h, for the slots in the order.
order_written = Array.new(MODULES_SIZE, 0)

# The output fader: where the fade is, in samples, from 0 (silent) to OUTPUT_FADE_SAMPLES (the
# output as it is), and which way it goes, 1 in, -1 out or 0; the count of Mute ons it has taken,
# with one waiting while the output fades out, and so for Save; and the buffers left to
# hold the output silent before it may fade in.
output_fade_position = OUTPUT_FADE_SAMPLES
output_fade_direction = 0
mute_count = 0
mute_waiting = false
save_count = 0
save_waiting = false
output_hold_buffers = 0

audio_buffer_l = Array.new(AUDIO_BUFFER_WORDS, 0.0)
audio_buffer_r = Array.new(AUDIO_BUFFER_WORDS, 0.0)

# The signal bus: each module's latest output, in its SIGNAL_* slot. Its slots live with the host
# (SignalBus, in spms1_framework.rb), so they carry across buffers, since a routing with feedback
# reads last sample's value and at a buffer edge that is the previous iteration's.
signals = SignalBus.new
spms1_fill_constant_signals(signals)

# The default patch, written into the NRPN table the loop reads it back from. Why it is what it is,
# spms1_patch.yaml says, above default_order.
spms1_write_default_patch(MIDI_CH)
# And over it the patch kept in the flash, if one is.
C.load_saved_patch(MIDI_CH)

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

# The parameters, once per buffer, written by patch_gen from the controls of spms1_patch.yaml:
# - Where each takes its value: a bus slot, or its own control slot. Read once per buffer rather than
#   per sample: each destination smooths at the control rate in two stages of 5.3 ms each (10.7 ms on
#   average), which swallows the difference between feeding it at 48 kHz and at the 750 Hz buffer
#   rate. Faster modulation goes through the module inputs.
# - Which CC fills each control slot, or, for a parameter with none, its value from NRPN category 4.
#   `signals` -- the bus and the parameters' own slots above it -- is the only thing downstream
#   reads, so this is where MIDI enters and the only place a CC number appears. Each parameter's CC
#   fills its own slot, and each controller's CC its slots on the bus, with their smoothed copies.
# - Each parameter takes its value, every buffer, whether or not it moved, by its `set`.
# A function of its own, which spms1_parameters.h (written by patch_gen too) keeps out of
# Spms1_main, in RAM and flattened itself: inlined into Spms1_main, as its flatten would have it,
# what this holds in registers crowds the per-sample loop, which then runs longer as parameters are
# added, wherever they come in the list.
# The NRPN entries, the slots and the MIDI channel in it are literals, as in the dispatch, each line
# with the names of its constants at its end: named, each would be a load from a global, and the
# range checks of get_midi_nrpn_value and get_midi_cc_value would be kept for each read rather than
# folded away, about 40 us a buffer more (emulated Cortex-M33).
# patch_gen parameters
def spms1_apply_parameters(signals, pitch_1, eg_1, eg_2, lfo_1, mixer_1, osc_1, osc_2, noise_1, mixer_2, filter_1, filter_2, amp_1, chorus_1, delay_1)
  source_pitch_1_glide = source_or_own(C.get_midi_nrpn_value(0, 256), 128) # NRPN_SOURCE_PITCH_1_GLIDE, SLOT_PITCH_1_GLIDE
  source_pitch_1_out_1_glide_sw = source_or_own(C.get_midi_nrpn_value(0, 257), 129) # NRPN_SOURCE_PITCH_1_OUT_1_GLIDE_SW, SLOT_PITCH_1_OUT_1_GLIDE_SW
  source_pitch_1_out_2_glide_sw = source_or_own(C.get_midi_nrpn_value(0, 258), 130) # NRPN_SOURCE_PITCH_1_OUT_2_GLIDE_SW, SLOT_PITCH_1_OUT_2_GLIDE_SW
  source_pitch_1_bend_amt = source_or_own(C.get_midi_nrpn_value(0, 259), 131) # NRPN_SOURCE_PITCH_1_BEND_AMT, SLOT_PITCH_1_BEND_AMT
  source_pitch_1_bend_pol = source_or_own(C.get_midi_nrpn_value(0, 260), 132) # NRPN_SOURCE_PITCH_1_BEND_POL, SLOT_PITCH_1_BEND_POL
  source_pitch_1_out_1_bend_sw = source_or_own(C.get_midi_nrpn_value(0, 261), 133) # NRPN_SOURCE_PITCH_1_OUT_1_BEND_SW, SLOT_PITCH_1_OUT_1_BEND_SW
  source_pitch_1_out_2_bend_sw = source_or_own(C.get_midi_nrpn_value(0, 262), 134) # NRPN_SOURCE_PITCH_1_OUT_2_BEND_SW, SLOT_PITCH_1_OUT_2_BEND_SW
  source_pitch_1_stretch = source_or_own(C.get_midi_nrpn_value(0, 263), 135) # NRPN_SOURCE_PITCH_1_STRETCH, SLOT_PITCH_1_STRETCH
  source_eg_1_attack = source_or_own(C.get_midi_nrpn_value(0, 264), 136) # NRPN_SOURCE_EG_1_ATTACK, SLOT_EG_1_ATTACK
  source_eg_1_decay = source_or_own(C.get_midi_nrpn_value(0, 265), 137) # NRPN_SOURCE_EG_1_DECAY, SLOT_EG_1_DECAY
  source_eg_1_sustain = source_or_own(C.get_midi_nrpn_value(0, 266), 138) # NRPN_SOURCE_EG_1_SUSTAIN, SLOT_EG_1_SUSTAIN
  source_eg_1_release_sw = source_or_own(C.get_midi_nrpn_value(0, 267), 139) # NRPN_SOURCE_EG_1_RELEASE_SW, SLOT_EG_1_RELEASE_SW
  source_eg_1_level = source_or_own(C.get_midi_nrpn_value(0, 268), 140) # NRPN_SOURCE_EG_1_LEVEL, SLOT_EG_1_LEVEL
  source_eg_2_attack = source_or_own(C.get_midi_nrpn_value(0, 269), 141) # NRPN_SOURCE_EG_2_ATTACK, SLOT_EG_2_ATTACK
  source_eg_2_decay = source_or_own(C.get_midi_nrpn_value(0, 270), 142) # NRPN_SOURCE_EG_2_DECAY, SLOT_EG_2_DECAY
  source_eg_2_sustain = source_or_own(C.get_midi_nrpn_value(0, 271), 143) # NRPN_SOURCE_EG_2_SUSTAIN, SLOT_EG_2_SUSTAIN
  source_eg_2_release_sw = source_or_own(C.get_midi_nrpn_value(0, 272), 144) # NRPN_SOURCE_EG_2_RELEASE_SW, SLOT_EG_2_RELEASE_SW
  source_eg_2_level = source_or_own(C.get_midi_nrpn_value(0, 273), 145) # NRPN_SOURCE_EG_2_LEVEL, SLOT_EG_2_LEVEL
  source_lfo_1_wave = source_or_own(C.get_midi_nrpn_value(0, 274), 146) # NRPN_SOURCE_LFO_1_WAVE, SLOT_LFO_1_WAVE
  source_lfo_1_rate = source_or_own(C.get_midi_nrpn_value(0, 275), 147) # NRPN_SOURCE_LFO_1_RATE, SLOT_LFO_1_RATE
  source_lfo_1_level = source_or_own(C.get_midi_nrpn_value(0, 276), 148) # NRPN_SOURCE_LFO_1_LEVEL, SLOT_LFO_1_LEVEL
  source_lfo_1_rate_mod_amt = source_or_own(C.get_midi_nrpn_value(0, 277), 149) # NRPN_SOURCE_LFO_1_RATE_MOD_AMT, SLOT_LFO_1_RATE_MOD_AMT
  source_lfo_1_level_mod_amt = source_or_own(C.get_midi_nrpn_value(0, 278), 150) # NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT, SLOT_LFO_1_LEVEL_MOD_AMT
  source_lfo_1_reset_sw = source_or_own(C.get_midi_nrpn_value(0, 279), 151) # NRPN_SOURCE_LFO_1_RESET_SW, SLOT_LFO_1_RESET_SW
  source_mixer_1_level_1 = source_or_own(C.get_midi_nrpn_value(0, 280), 152) # NRPN_SOURCE_MIXER_1_LEVEL_1, SLOT_MIXER_1_LEVEL_1
  source_mixer_1_level_2 = source_or_own(C.get_midi_nrpn_value(0, 281), 153) # NRPN_SOURCE_MIXER_1_LEVEL_2, SLOT_MIXER_1_LEVEL_2
  source_mixer_1_level_3 = source_or_own(C.get_midi_nrpn_value(0, 282), 154) # NRPN_SOURCE_MIXER_1_LEVEL_3, SLOT_MIXER_1_LEVEL_3
  source_mixer_1_level_4 = source_or_own(C.get_midi_nrpn_value(0, 283), 155) # NRPN_SOURCE_MIXER_1_LEVEL_4, SLOT_MIXER_1_LEVEL_4
  source_mixer_1_out_level = source_or_own(C.get_midi_nrpn_value(0, 284), 156) # NRPN_SOURCE_MIXER_1_OUT_LEVEL, SLOT_MIXER_1_OUT_LEVEL
  source_osc_1_wave = source_or_own(C.get_midi_nrpn_value(0, 285), 157) # NRPN_SOURCE_OSC_1_WAVE, SLOT_OSC_1_WAVE
  source_osc_1_pw = source_or_own(C.get_midi_nrpn_value(0, 286), 158) # NRPN_SOURCE_OSC_1_PW, SLOT_OSC_1_PW
  source_osc_1_pitch_coarse = source_or_own(C.get_midi_nrpn_value(0, 287), 159) # NRPN_SOURCE_OSC_1_PITCH_COARSE, SLOT_OSC_1_PITCH_COARSE
  source_osc_1_pitch_fine = source_or_own(C.get_midi_nrpn_value(0, 288), 160) # NRPN_SOURCE_OSC_1_PITCH_FINE, SLOT_OSC_1_PITCH_FINE
  source_osc_1_pitch_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 289), 161) # NRPN_SOURCE_OSC_1_PITCH_MOD_1_AMT, SLOT_OSC_1_PITCH_MOD_1_AMT
  source_osc_1_pitch_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 290), 162) # NRPN_SOURCE_OSC_1_PITCH_MOD_1_POL, SLOT_OSC_1_PITCH_MOD_1_POL
  source_osc_1_pitch_mod_1_sw = source_or_own(C.get_midi_nrpn_value(0, 291), 163) # NRPN_SOURCE_OSC_1_PITCH_MOD_1_SW, SLOT_OSC_1_PITCH_MOD_1_SW
  source_osc_1_pitch_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 292), 164) # NRPN_SOURCE_OSC_1_PITCH_MOD_2_AMT, SLOT_OSC_1_PITCH_MOD_2_AMT
  source_osc_1_pitch_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 293), 165) # NRPN_SOURCE_OSC_1_PITCH_MOD_2_POL, SLOT_OSC_1_PITCH_MOD_2_POL
  source_osc_1_pitch_mod_2_sw = source_or_own(C.get_midi_nrpn_value(0, 294), 166) # NRPN_SOURCE_OSC_1_PITCH_MOD_2_SW, SLOT_OSC_1_PITCH_MOD_2_SW
  source_osc_1_pw_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 295), 167) # NRPN_SOURCE_OSC_1_PW_MOD_1_AMT, SLOT_OSC_1_PW_MOD_1_AMT
  source_osc_1_pw_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 296), 168) # NRPN_SOURCE_OSC_1_PW_MOD_1_POL, SLOT_OSC_1_PW_MOD_1_POL
  source_osc_1_pw_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 297), 169) # NRPN_SOURCE_OSC_1_PW_MOD_2_AMT, SLOT_OSC_1_PW_MOD_2_AMT
  source_osc_1_pw_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 298), 170) # NRPN_SOURCE_OSC_1_PW_MOD_2_POL, SLOT_OSC_1_PW_MOD_2_POL
  source_osc_2_wave = source_or_own(C.get_midi_nrpn_value(0, 299), 171) # NRPN_SOURCE_OSC_2_WAVE, SLOT_OSC_2_WAVE
  source_osc_2_pw = source_or_own(C.get_midi_nrpn_value(0, 300), 172) # NRPN_SOURCE_OSC_2_PW, SLOT_OSC_2_PW
  source_osc_2_pitch_coarse = source_or_own(C.get_midi_nrpn_value(0, 301), 173) # NRPN_SOURCE_OSC_2_PITCH_COARSE, SLOT_OSC_2_PITCH_COARSE
  source_osc_2_pitch_fine = source_or_own(C.get_midi_nrpn_value(0, 302), 174) # NRPN_SOURCE_OSC_2_PITCH_FINE, SLOT_OSC_2_PITCH_FINE
  source_osc_2_pitch_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 303), 175) # NRPN_SOURCE_OSC_2_PITCH_MOD_1_AMT, SLOT_OSC_2_PITCH_MOD_1_AMT
  source_osc_2_pitch_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 304), 176) # NRPN_SOURCE_OSC_2_PITCH_MOD_1_POL, SLOT_OSC_2_PITCH_MOD_1_POL
  source_osc_2_pitch_mod_1_sw = source_or_own(C.get_midi_nrpn_value(0, 305), 177) # NRPN_SOURCE_OSC_2_PITCH_MOD_1_SW, SLOT_OSC_2_PITCH_MOD_1_SW
  source_osc_2_pitch_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 306), 178) # NRPN_SOURCE_OSC_2_PITCH_MOD_2_AMT, SLOT_OSC_2_PITCH_MOD_2_AMT
  source_osc_2_pitch_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 307), 179) # NRPN_SOURCE_OSC_2_PITCH_MOD_2_POL, SLOT_OSC_2_PITCH_MOD_2_POL
  source_osc_2_pitch_mod_2_sw = source_or_own(C.get_midi_nrpn_value(0, 308), 180) # NRPN_SOURCE_OSC_2_PITCH_MOD_2_SW, SLOT_OSC_2_PITCH_MOD_2_SW
  source_osc_2_pw_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 309), 181) # NRPN_SOURCE_OSC_2_PW_MOD_1_AMT, SLOT_OSC_2_PW_MOD_1_AMT
  source_osc_2_pw_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 310), 182) # NRPN_SOURCE_OSC_2_PW_MOD_1_POL, SLOT_OSC_2_PW_MOD_1_POL
  source_osc_2_pw_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 311), 183) # NRPN_SOURCE_OSC_2_PW_MOD_2_AMT, SLOT_OSC_2_PW_MOD_2_AMT
  source_osc_2_pw_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 312), 184) # NRPN_SOURCE_OSC_2_PW_MOD_2_POL, SLOT_OSC_2_PW_MOD_2_POL
  source_osc_2_sync_sw = source_or_own(C.get_midi_nrpn_value(0, 313), 185) # NRPN_SOURCE_OSC_2_SYNC_SW, SLOT_OSC_2_SYNC_SW
  source_noise_1_color = source_or_own(C.get_midi_nrpn_value(0, 314), 186) # NRPN_SOURCE_NOISE_1_COLOR, SLOT_NOISE_1_COLOR
  source_noise_1_level = source_or_own(C.get_midi_nrpn_value(0, 315), 187) # NRPN_SOURCE_NOISE_1_LEVEL, SLOT_NOISE_1_LEVEL
  source_mixer_2_level_1 = source_or_own(C.get_midi_nrpn_value(0, 316), 188) # NRPN_SOURCE_MIXER_2_LEVEL_1, SLOT_MIXER_2_LEVEL_1
  source_mixer_2_level_2 = source_or_own(C.get_midi_nrpn_value(0, 317), 189) # NRPN_SOURCE_MIXER_2_LEVEL_2, SLOT_MIXER_2_LEVEL_2
  source_mixer_2_level_3 = source_or_own(C.get_midi_nrpn_value(0, 318), 190) # NRPN_SOURCE_MIXER_2_LEVEL_3, SLOT_MIXER_2_LEVEL_3
  source_mixer_2_level_4 = source_or_own(C.get_midi_nrpn_value(0, 319), 191) # NRPN_SOURCE_MIXER_2_LEVEL_4, SLOT_MIXER_2_LEVEL_4
  source_mixer_2_out_level = source_or_own(C.get_midi_nrpn_value(0, 320), 192) # NRPN_SOURCE_MIXER_2_OUT_LEVEL, SLOT_MIXER_2_OUT_LEVEL
  source_filter_1_mode = source_or_own(C.get_midi_nrpn_value(0, 321), 193) # NRPN_SOURCE_FILTER_1_MODE, SLOT_FILTER_1_MODE
  source_filter_1_cutoff = source_or_own(C.get_midi_nrpn_value(0, 322), 194) # NRPN_SOURCE_FILTER_1_CUTOFF, SLOT_FILTER_1_CUTOFF
  source_filter_1_resonance = source_or_own(C.get_midi_nrpn_value(0, 323), 195) # NRPN_SOURCE_FILTER_1_RESONANCE, SLOT_FILTER_1_RESONANCE
  source_filter_1_gain_1 = source_or_own(C.get_midi_nrpn_value(0, 324), 196) # NRPN_SOURCE_FILTER_1_GAIN_1, SLOT_FILTER_1_GAIN_1
  source_filter_1_gain_2 = source_or_own(C.get_midi_nrpn_value(0, 325), 197) # NRPN_SOURCE_FILTER_1_GAIN_2, SLOT_FILTER_1_GAIN_2
  source_filter_1_pitch_amt = source_or_own(C.get_midi_nrpn_value(0, 326), 198) # NRPN_SOURCE_FILTER_1_PITCH_AMT, SLOT_FILTER_1_PITCH_AMT
  source_filter_1_pitch_pol = source_or_own(C.get_midi_nrpn_value(0, 327), 199) # NRPN_SOURCE_FILTER_1_PITCH_POL, SLOT_FILTER_1_PITCH_POL
  source_filter_1_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 328), 200) # NRPN_SOURCE_FILTER_1_MOD_1_AMT, SLOT_FILTER_1_MOD_1_AMT
  source_filter_1_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 329), 201) # NRPN_SOURCE_FILTER_1_MOD_1_POL, SLOT_FILTER_1_MOD_1_POL
  source_filter_1_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 330), 202) # NRPN_SOURCE_FILTER_1_MOD_2_AMT, SLOT_FILTER_1_MOD_2_AMT
  source_filter_1_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 331), 203) # NRPN_SOURCE_FILTER_1_MOD_2_POL, SLOT_FILTER_1_MOD_2_POL
  source_filter_2_mode = source_or_own(C.get_midi_nrpn_value(0, 332), 204) # NRPN_SOURCE_FILTER_2_MODE, SLOT_FILTER_2_MODE
  source_filter_2_cutoff = source_or_own(C.get_midi_nrpn_value(0, 333), 205) # NRPN_SOURCE_FILTER_2_CUTOFF, SLOT_FILTER_2_CUTOFF
  source_filter_2_resonance = source_or_own(C.get_midi_nrpn_value(0, 334), 206) # NRPN_SOURCE_FILTER_2_RESONANCE, SLOT_FILTER_2_RESONANCE
  source_filter_2_gain_1 = source_or_own(C.get_midi_nrpn_value(0, 335), 207) # NRPN_SOURCE_FILTER_2_GAIN_1, SLOT_FILTER_2_GAIN_1
  source_filter_2_gain_2 = source_or_own(C.get_midi_nrpn_value(0, 336), 208) # NRPN_SOURCE_FILTER_2_GAIN_2, SLOT_FILTER_2_GAIN_2
  source_filter_2_pitch_amt = source_or_own(C.get_midi_nrpn_value(0, 337), 209) # NRPN_SOURCE_FILTER_2_PITCH_AMT, SLOT_FILTER_2_PITCH_AMT
  source_filter_2_pitch_pol = source_or_own(C.get_midi_nrpn_value(0, 338), 210) # NRPN_SOURCE_FILTER_2_PITCH_POL, SLOT_FILTER_2_PITCH_POL
  source_filter_2_mod_1_amt = source_or_own(C.get_midi_nrpn_value(0, 339), 211) # NRPN_SOURCE_FILTER_2_MOD_1_AMT, SLOT_FILTER_2_MOD_1_AMT
  source_filter_2_mod_1_pol = source_or_own(C.get_midi_nrpn_value(0, 340), 212) # NRPN_SOURCE_FILTER_2_MOD_1_POL, SLOT_FILTER_2_MOD_1_POL
  source_filter_2_mod_2_amt = source_or_own(C.get_midi_nrpn_value(0, 341), 213) # NRPN_SOURCE_FILTER_2_MOD_2_AMT, SLOT_FILTER_2_MOD_2_AMT
  source_filter_2_mod_2_pol = source_or_own(C.get_midi_nrpn_value(0, 342), 214) # NRPN_SOURCE_FILTER_2_MOD_2_POL, SLOT_FILTER_2_MOD_2_POL
  source_amp_1_gain_1 = source_or_own(C.get_midi_nrpn_value(0, 343), 215) # NRPN_SOURCE_AMP_1_GAIN_1, SLOT_AMP_1_GAIN_1
  source_amp_1_gain_2 = source_or_own(C.get_midi_nrpn_value(0, 344), 216) # NRPN_SOURCE_AMP_1_GAIN_2, SLOT_AMP_1_GAIN_2
  source_amp_1_mod_1_2_mix = source_or_own(C.get_midi_nrpn_value(0, 345), 217) # NRPN_SOURCE_AMP_1_MOD_1_2_MIX, SLOT_AMP_1_MOD_1_2_MIX
  source_chorus_1_mix = source_or_own(C.get_midi_nrpn_value(0, 346), 218) # NRPN_SOURCE_CHORUS_1_MIX, SLOT_CHORUS_1_MIX
  source_chorus_1_rate = source_or_own(C.get_midi_nrpn_value(0, 347), 219) # NRPN_SOURCE_CHORUS_1_RATE, SLOT_CHORUS_1_RATE
  source_chorus_1_depth = source_or_own(C.get_midi_nrpn_value(0, 348), 220) # NRPN_SOURCE_CHORUS_1_DEPTH, SLOT_CHORUS_1_DEPTH
  source_delay_1_mix = source_or_own(C.get_midi_nrpn_value(0, 349), 221) # NRPN_SOURCE_DELAY_1_MIX, SLOT_DELAY_1_MIX
  source_delay_1_time = source_or_own(C.get_midi_nrpn_value(0, 350), 222) # NRPN_SOURCE_DELAY_1_TIME, SLOT_DELAY_1_TIME
  source_delay_1_feedback = source_or_own(C.get_midi_nrpn_value(0, 351), 223) # NRPN_SOURCE_DELAY_1_FEEDBACK, SLOT_DELAY_1_FEEDBACK
  source_amp_1_limiter_sw = source_or_own(C.get_midi_nrpn_value(0, 356), 228) # NRPN_SOURCE_AMP_1_LIMITER_SW, SLOT_AMP_1_LIMITER_SW
  source_filter_1_drive = source_or_own(C.get_midi_nrpn_value(0, 357), 229) # NRPN_SOURCE_FILTER_1_DRIVE, SLOT_FILTER_1_DRIVE
  source_filter_2_drive = source_or_own(C.get_midi_nrpn_value(0, 358), 230) # NRPN_SOURCE_FILTER_2_DRIVE, SLOT_FILTER_2_DRIVE
  cc_pitch_1_glide = C.get_midi_nrpn_value(0, 384) # NRPN_CC_PITCH_1_GLIDE
  signals[128] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_glide, C.get_midi_cc_value(0, cc_pitch_1_glide), C.get_midi_nrpn_value(0, 512))) # SLOT_PITCH_1_GLIDE, NRPN_VALUE_PITCH_1_GLIDE
  cc_pitch_1_out_1_glide_sw = C.get_midi_nrpn_value(0, 385) # NRPN_CC_PITCH_1_OUT_1_GLIDE_SW
  signals[129] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_out_1_glide_sw, C.get_midi_cc_value(0, cc_pitch_1_out_1_glide_sw), C.get_midi_nrpn_value(0, 513))) # SLOT_PITCH_1_OUT_1_GLIDE_SW, NRPN_VALUE_PITCH_1_OUT_1_GLIDE_SW
  cc_pitch_1_out_2_glide_sw = C.get_midi_nrpn_value(0, 386) # NRPN_CC_PITCH_1_OUT_2_GLIDE_SW
  signals[130] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_out_2_glide_sw, C.get_midi_cc_value(0, cc_pitch_1_out_2_glide_sw), C.get_midi_nrpn_value(0, 514))) # SLOT_PITCH_1_OUT_2_GLIDE_SW, NRPN_VALUE_PITCH_1_OUT_2_GLIDE_SW
  cc_pitch_1_bend_amt = C.get_midi_nrpn_value(0, 387) # NRPN_CC_PITCH_1_BEND_AMT
  signals[131] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_bend_amt, C.get_midi_cc_value(0, cc_pitch_1_bend_amt), C.get_midi_nrpn_value(0, 515))) # SLOT_PITCH_1_BEND_AMT, NRPN_VALUE_PITCH_1_BEND_AMT
  cc_pitch_1_bend_pol = C.get_midi_nrpn_value(0, 388) # NRPN_CC_PITCH_1_BEND_POL
  signals[132] = cc_to_bipolar(cc_or_nrpn(cc_pitch_1_bend_pol, C.get_midi_cc_value(0, cc_pitch_1_bend_pol), C.get_midi_nrpn_value(0, 516))) # SLOT_PITCH_1_BEND_POL, NRPN_VALUE_PITCH_1_BEND_POL
  cc_pitch_1_out_1_bend_sw = C.get_midi_nrpn_value(0, 389) # NRPN_CC_PITCH_1_OUT_1_BEND_SW
  signals[133] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_out_1_bend_sw, C.get_midi_cc_value(0, cc_pitch_1_out_1_bend_sw), C.get_midi_nrpn_value(0, 517))) # SLOT_PITCH_1_OUT_1_BEND_SW, NRPN_VALUE_PITCH_1_OUT_1_BEND_SW
  cc_pitch_1_out_2_bend_sw = C.get_midi_nrpn_value(0, 390) # NRPN_CC_PITCH_1_OUT_2_BEND_SW
  signals[134] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_out_2_bend_sw, C.get_midi_cc_value(0, cc_pitch_1_out_2_bend_sw), C.get_midi_nrpn_value(0, 518))) # SLOT_PITCH_1_OUT_2_BEND_SW, NRPN_VALUE_PITCH_1_OUT_2_BEND_SW
  cc_pitch_1_stretch = C.get_midi_nrpn_value(0, 391) # NRPN_CC_PITCH_1_STRETCH
  signals[135] = cc_to_unipolar(cc_or_nrpn(cc_pitch_1_stretch, C.get_midi_cc_value(0, cc_pitch_1_stretch), C.get_midi_nrpn_value(0, 519))) # SLOT_PITCH_1_STRETCH, NRPN_VALUE_PITCH_1_STRETCH
  cc_eg_1_attack = C.get_midi_nrpn_value(0, 392) # NRPN_CC_EG_1_ATTACK
  signals[136] = cc_to_unipolar(cc_or_nrpn(cc_eg_1_attack, C.get_midi_cc_value(0, cc_eg_1_attack), C.get_midi_nrpn_value(0, 520))) # SLOT_EG_1_ATTACK, NRPN_VALUE_EG_1_ATTACK
  cc_eg_1_decay = C.get_midi_nrpn_value(0, 393) # NRPN_CC_EG_1_DECAY
  signals[137] = cc_to_unipolar(cc_or_nrpn(cc_eg_1_decay, C.get_midi_cc_value(0, cc_eg_1_decay), C.get_midi_nrpn_value(0, 521))) # SLOT_EG_1_DECAY, NRPN_VALUE_EG_1_DECAY
  cc_eg_1_sustain = C.get_midi_nrpn_value(0, 394) # NRPN_CC_EG_1_SUSTAIN
  signals[138] = cc_to_unipolar(cc_or_nrpn(cc_eg_1_sustain, C.get_midi_cc_value(0, cc_eg_1_sustain), C.get_midi_nrpn_value(0, 522))) # SLOT_EG_1_SUSTAIN, NRPN_VALUE_EG_1_SUSTAIN
  cc_eg_1_release_sw = C.get_midi_nrpn_value(0, 395) # NRPN_CC_EG_1_RELEASE_SW
  signals[139] = cc_to_unipolar(cc_or_nrpn(cc_eg_1_release_sw, C.get_midi_cc_value(0, cc_eg_1_release_sw), C.get_midi_nrpn_value(0, 523))) # SLOT_EG_1_RELEASE_SW, NRPN_VALUE_EG_1_RELEASE_SW
  cc_eg_1_level = C.get_midi_nrpn_value(0, 396) # NRPN_CC_EG_1_LEVEL
  signals[140] = cc_to_unipolar(cc_or_nrpn(cc_eg_1_level, C.get_midi_cc_value(0, cc_eg_1_level), C.get_midi_nrpn_value(0, 524))) # SLOT_EG_1_LEVEL, NRPN_VALUE_EG_1_LEVEL
  cc_eg_2_attack = C.get_midi_nrpn_value(0, 397) # NRPN_CC_EG_2_ATTACK
  signals[141] = cc_to_unipolar(cc_or_nrpn(cc_eg_2_attack, C.get_midi_cc_value(0, cc_eg_2_attack), C.get_midi_nrpn_value(0, 525))) # SLOT_EG_2_ATTACK, NRPN_VALUE_EG_2_ATTACK
  cc_eg_2_decay = C.get_midi_nrpn_value(0, 398) # NRPN_CC_EG_2_DECAY
  signals[142] = cc_to_unipolar(cc_or_nrpn(cc_eg_2_decay, C.get_midi_cc_value(0, cc_eg_2_decay), C.get_midi_nrpn_value(0, 526))) # SLOT_EG_2_DECAY, NRPN_VALUE_EG_2_DECAY
  cc_eg_2_sustain = C.get_midi_nrpn_value(0, 399) # NRPN_CC_EG_2_SUSTAIN
  signals[143] = cc_to_unipolar(cc_or_nrpn(cc_eg_2_sustain, C.get_midi_cc_value(0, cc_eg_2_sustain), C.get_midi_nrpn_value(0, 527))) # SLOT_EG_2_SUSTAIN, NRPN_VALUE_EG_2_SUSTAIN
  cc_eg_2_release_sw = C.get_midi_nrpn_value(0, 400) # NRPN_CC_EG_2_RELEASE_SW
  signals[144] = cc_to_unipolar(cc_or_nrpn(cc_eg_2_release_sw, C.get_midi_cc_value(0, cc_eg_2_release_sw), C.get_midi_nrpn_value(0, 528))) # SLOT_EG_2_RELEASE_SW, NRPN_VALUE_EG_2_RELEASE_SW
  cc_eg_2_level = C.get_midi_nrpn_value(0, 401) # NRPN_CC_EG_2_LEVEL
  signals[145] = cc_to_unipolar(cc_or_nrpn(cc_eg_2_level, C.get_midi_cc_value(0, cc_eg_2_level), C.get_midi_nrpn_value(0, 529))) # SLOT_EG_2_LEVEL, NRPN_VALUE_EG_2_LEVEL
  cc_lfo_1_wave = C.get_midi_nrpn_value(0, 402) # NRPN_CC_LFO_1_WAVE
  signals[146] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_wave, C.get_midi_cc_value(0, cc_lfo_1_wave), C.get_midi_nrpn_value(0, 530))) # SLOT_LFO_1_WAVE, NRPN_VALUE_LFO_1_WAVE
  cc_lfo_1_rate = C.get_midi_nrpn_value(0, 403) # NRPN_CC_LFO_1_RATE
  signals[147] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_rate, C.get_midi_cc_value(0, cc_lfo_1_rate), C.get_midi_nrpn_value(0, 531))) # SLOT_LFO_1_RATE, NRPN_VALUE_LFO_1_RATE
  cc_lfo_1_level = C.get_midi_nrpn_value(0, 404) # NRPN_CC_LFO_1_LEVEL
  signals[148] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_level, C.get_midi_cc_value(0, cc_lfo_1_level), C.get_midi_nrpn_value(0, 532))) # SLOT_LFO_1_LEVEL, NRPN_VALUE_LFO_1_LEVEL
  cc_lfo_1_rate_mod_amt = C.get_midi_nrpn_value(0, 405) # NRPN_CC_LFO_1_RATE_MOD_AMT
  signals[149] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_rate_mod_amt, C.get_midi_cc_value(0, cc_lfo_1_rate_mod_amt), C.get_midi_nrpn_value(0, 533))) # SLOT_LFO_1_RATE_MOD_AMT, NRPN_VALUE_LFO_1_RATE_MOD_AMT
  cc_lfo_1_level_mod_amt = C.get_midi_nrpn_value(0, 406) # NRPN_CC_LFO_1_LEVEL_MOD_AMT
  signals[150] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_level_mod_amt, C.get_midi_cc_value(0, cc_lfo_1_level_mod_amt), C.get_midi_nrpn_value(0, 534))) # SLOT_LFO_1_LEVEL_MOD_AMT, NRPN_VALUE_LFO_1_LEVEL_MOD_AMT
  cc_lfo_1_reset_sw = C.get_midi_nrpn_value(0, 407) # NRPN_CC_LFO_1_RESET_SW
  signals[151] = cc_to_unipolar(cc_or_nrpn(cc_lfo_1_reset_sw, C.get_midi_cc_value(0, cc_lfo_1_reset_sw), C.get_midi_nrpn_value(0, 535))) # SLOT_LFO_1_RESET_SW, NRPN_VALUE_LFO_1_RESET_SW
  cc_mixer_1_level_1 = C.get_midi_nrpn_value(0, 408) # NRPN_CC_MIXER_1_LEVEL_1
  signals[152] = cc_to_unipolar(cc_or_nrpn(cc_mixer_1_level_1, C.get_midi_cc_value(0, cc_mixer_1_level_1), C.get_midi_nrpn_value(0, 536))) # SLOT_MIXER_1_LEVEL_1, NRPN_VALUE_MIXER_1_LEVEL_1
  cc_mixer_1_level_2 = C.get_midi_nrpn_value(0, 409) # NRPN_CC_MIXER_1_LEVEL_2
  signals[153] = cc_to_unipolar(cc_or_nrpn(cc_mixer_1_level_2, C.get_midi_cc_value(0, cc_mixer_1_level_2), C.get_midi_nrpn_value(0, 537))) # SLOT_MIXER_1_LEVEL_2, NRPN_VALUE_MIXER_1_LEVEL_2
  cc_mixer_1_level_3 = C.get_midi_nrpn_value(0, 410) # NRPN_CC_MIXER_1_LEVEL_3
  signals[154] = cc_to_unipolar(cc_or_nrpn(cc_mixer_1_level_3, C.get_midi_cc_value(0, cc_mixer_1_level_3), C.get_midi_nrpn_value(0, 538))) # SLOT_MIXER_1_LEVEL_3, NRPN_VALUE_MIXER_1_LEVEL_3
  cc_mixer_1_level_4 = C.get_midi_nrpn_value(0, 411) # NRPN_CC_MIXER_1_LEVEL_4
  signals[155] = cc_to_unipolar(cc_or_nrpn(cc_mixer_1_level_4, C.get_midi_cc_value(0, cc_mixer_1_level_4), C.get_midi_nrpn_value(0, 539))) # SLOT_MIXER_1_LEVEL_4, NRPN_VALUE_MIXER_1_LEVEL_4
  cc_mixer_1_out_level = C.get_midi_nrpn_value(0, 412) # NRPN_CC_MIXER_1_OUT_LEVEL
  signals[156] = cc_to_unipolar(cc_or_nrpn(cc_mixer_1_out_level, C.get_midi_cc_value(0, cc_mixer_1_out_level), C.get_midi_nrpn_value(0, 540))) # SLOT_MIXER_1_OUT_LEVEL, NRPN_VALUE_MIXER_1_OUT_LEVEL
  cc_osc_1_wave = C.get_midi_nrpn_value(0, 413) # NRPN_CC_OSC_1_WAVE
  signals[157] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_wave, C.get_midi_cc_value(0, cc_osc_1_wave), C.get_midi_nrpn_value(0, 541))) # SLOT_OSC_1_WAVE, NRPN_VALUE_OSC_1_WAVE
  cc_osc_1_pw = C.get_midi_nrpn_value(0, 414) # NRPN_CC_OSC_1_PW
  signals[158] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pw, C.get_midi_cc_value(0, cc_osc_1_pw), C.get_midi_nrpn_value(0, 542))) # SLOT_OSC_1_PW, NRPN_VALUE_OSC_1_PW
  cc_osc_1_pitch_coarse = C.get_midi_nrpn_value(0, 415) # NRPN_CC_OSC_1_PITCH_COARSE
  signals[159] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pitch_coarse, C.get_midi_cc_value(0, cc_osc_1_pitch_coarse), C.get_midi_nrpn_value(0, 543))) # SLOT_OSC_1_PITCH_COARSE, NRPN_VALUE_OSC_1_PITCH_COARSE
  cc_osc_1_pitch_fine = C.get_midi_nrpn_value(0, 416) # NRPN_CC_OSC_1_PITCH_FINE
  signals[160] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pitch_fine, C.get_midi_cc_value(0, cc_osc_1_pitch_fine), C.get_midi_nrpn_value(0, 544))) # SLOT_OSC_1_PITCH_FINE, NRPN_VALUE_OSC_1_PITCH_FINE
  cc_osc_1_pitch_mod_1_amt = C.get_midi_nrpn_value(0, 417) # NRPN_CC_OSC_1_PITCH_MOD_1_AMT
  signals[161] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pitch_mod_1_amt, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_1_amt), C.get_midi_nrpn_value(0, 545))) # SLOT_OSC_1_PITCH_MOD_1_AMT, NRPN_VALUE_OSC_1_PITCH_MOD_1_AMT
  cc_osc_1_pitch_mod_1_pol = C.get_midi_nrpn_value(0, 418) # NRPN_CC_OSC_1_PITCH_MOD_1_POL
  signals[162] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pitch_mod_1_pol, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_1_pol), C.get_midi_nrpn_value(0, 546))) # SLOT_OSC_1_PITCH_MOD_1_POL, NRPN_VALUE_OSC_1_PITCH_MOD_1_POL
  cc_osc_1_pitch_mod_1_sw = C.get_midi_nrpn_value(0, 419) # NRPN_CC_OSC_1_PITCH_MOD_1_SW
  signals[163] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pitch_mod_1_sw, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_1_sw), C.get_midi_nrpn_value(0, 547))) # SLOT_OSC_1_PITCH_MOD_1_SW, NRPN_VALUE_OSC_1_PITCH_MOD_1_SW
  cc_osc_1_pitch_mod_2_amt = C.get_midi_nrpn_value(0, 420) # NRPN_CC_OSC_1_PITCH_MOD_2_AMT
  signals[164] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pitch_mod_2_amt, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_2_amt), C.get_midi_nrpn_value(0, 548))) # SLOT_OSC_1_PITCH_MOD_2_AMT, NRPN_VALUE_OSC_1_PITCH_MOD_2_AMT
  cc_osc_1_pitch_mod_2_pol = C.get_midi_nrpn_value(0, 421) # NRPN_CC_OSC_1_PITCH_MOD_2_POL
  signals[165] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pitch_mod_2_pol, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_2_pol), C.get_midi_nrpn_value(0, 549))) # SLOT_OSC_1_PITCH_MOD_2_POL, NRPN_VALUE_OSC_1_PITCH_MOD_2_POL
  cc_osc_1_pitch_mod_2_sw = C.get_midi_nrpn_value(0, 422) # NRPN_CC_OSC_1_PITCH_MOD_2_SW
  signals[166] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pitch_mod_2_sw, C.get_midi_cc_value(0, cc_osc_1_pitch_mod_2_sw), C.get_midi_nrpn_value(0, 550))) # SLOT_OSC_1_PITCH_MOD_2_SW, NRPN_VALUE_OSC_1_PITCH_MOD_2_SW
  cc_osc_1_pw_mod_1_amt = C.get_midi_nrpn_value(0, 423) # NRPN_CC_OSC_1_PW_MOD_1_AMT
  signals[167] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pw_mod_1_amt, C.get_midi_cc_value(0, cc_osc_1_pw_mod_1_amt), C.get_midi_nrpn_value(0, 551))) # SLOT_OSC_1_PW_MOD_1_AMT, NRPN_VALUE_OSC_1_PW_MOD_1_AMT
  cc_osc_1_pw_mod_1_pol = C.get_midi_nrpn_value(0, 424) # NRPN_CC_OSC_1_PW_MOD_1_POL
  signals[168] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pw_mod_1_pol, C.get_midi_cc_value(0, cc_osc_1_pw_mod_1_pol), C.get_midi_nrpn_value(0, 552))) # SLOT_OSC_1_PW_MOD_1_POL, NRPN_VALUE_OSC_1_PW_MOD_1_POL
  cc_osc_1_pw_mod_2_amt = C.get_midi_nrpn_value(0, 425) # NRPN_CC_OSC_1_PW_MOD_2_AMT
  signals[169] = cc_to_unipolar(cc_or_nrpn(cc_osc_1_pw_mod_2_amt, C.get_midi_cc_value(0, cc_osc_1_pw_mod_2_amt), C.get_midi_nrpn_value(0, 553))) # SLOT_OSC_1_PW_MOD_2_AMT, NRPN_VALUE_OSC_1_PW_MOD_2_AMT
  cc_osc_1_pw_mod_2_pol = C.get_midi_nrpn_value(0, 426) # NRPN_CC_OSC_1_PW_MOD_2_POL
  signals[170] = cc_to_bipolar(cc_or_nrpn(cc_osc_1_pw_mod_2_pol, C.get_midi_cc_value(0, cc_osc_1_pw_mod_2_pol), C.get_midi_nrpn_value(0, 554))) # SLOT_OSC_1_PW_MOD_2_POL, NRPN_VALUE_OSC_1_PW_MOD_2_POL
  cc_osc_2_wave = C.get_midi_nrpn_value(0, 427) # NRPN_CC_OSC_2_WAVE
  signals[171] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_wave, C.get_midi_cc_value(0, cc_osc_2_wave), C.get_midi_nrpn_value(0, 555))) # SLOT_OSC_2_WAVE, NRPN_VALUE_OSC_2_WAVE
  cc_osc_2_pw = C.get_midi_nrpn_value(0, 428) # NRPN_CC_OSC_2_PW
  signals[172] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pw, C.get_midi_cc_value(0, cc_osc_2_pw), C.get_midi_nrpn_value(0, 556))) # SLOT_OSC_2_PW, NRPN_VALUE_OSC_2_PW
  cc_osc_2_pitch_coarse = C.get_midi_nrpn_value(0, 429) # NRPN_CC_OSC_2_PITCH_COARSE
  signals[173] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pitch_coarse, C.get_midi_cc_value(0, cc_osc_2_pitch_coarse), C.get_midi_nrpn_value(0, 557))) # SLOT_OSC_2_PITCH_COARSE, NRPN_VALUE_OSC_2_PITCH_COARSE
  cc_osc_2_pitch_fine = C.get_midi_nrpn_value(0, 430) # NRPN_CC_OSC_2_PITCH_FINE
  signals[174] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pitch_fine, C.get_midi_cc_value(0, cc_osc_2_pitch_fine), C.get_midi_nrpn_value(0, 558))) # SLOT_OSC_2_PITCH_FINE, NRPN_VALUE_OSC_2_PITCH_FINE
  cc_osc_2_pitch_mod_1_amt = C.get_midi_nrpn_value(0, 431) # NRPN_CC_OSC_2_PITCH_MOD_1_AMT
  signals[175] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pitch_mod_1_amt, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_1_amt), C.get_midi_nrpn_value(0, 559))) # SLOT_OSC_2_PITCH_MOD_1_AMT, NRPN_VALUE_OSC_2_PITCH_MOD_1_AMT
  cc_osc_2_pitch_mod_1_pol = C.get_midi_nrpn_value(0, 432) # NRPN_CC_OSC_2_PITCH_MOD_1_POL
  signals[176] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pitch_mod_1_pol, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_1_pol), C.get_midi_nrpn_value(0, 560))) # SLOT_OSC_2_PITCH_MOD_1_POL, NRPN_VALUE_OSC_2_PITCH_MOD_1_POL
  cc_osc_2_pitch_mod_1_sw = C.get_midi_nrpn_value(0, 433) # NRPN_CC_OSC_2_PITCH_MOD_1_SW
  signals[177] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pitch_mod_1_sw, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_1_sw), C.get_midi_nrpn_value(0, 561))) # SLOT_OSC_2_PITCH_MOD_1_SW, NRPN_VALUE_OSC_2_PITCH_MOD_1_SW
  cc_osc_2_pitch_mod_2_amt = C.get_midi_nrpn_value(0, 434) # NRPN_CC_OSC_2_PITCH_MOD_2_AMT
  signals[178] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pitch_mod_2_amt, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_2_amt), C.get_midi_nrpn_value(0, 562))) # SLOT_OSC_2_PITCH_MOD_2_AMT, NRPN_VALUE_OSC_2_PITCH_MOD_2_AMT
  cc_osc_2_pitch_mod_2_pol = C.get_midi_nrpn_value(0, 435) # NRPN_CC_OSC_2_PITCH_MOD_2_POL
  signals[179] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pitch_mod_2_pol, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_2_pol), C.get_midi_nrpn_value(0, 563))) # SLOT_OSC_2_PITCH_MOD_2_POL, NRPN_VALUE_OSC_2_PITCH_MOD_2_POL
  cc_osc_2_pitch_mod_2_sw = C.get_midi_nrpn_value(0, 436) # NRPN_CC_OSC_2_PITCH_MOD_2_SW
  signals[180] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pitch_mod_2_sw, C.get_midi_cc_value(0, cc_osc_2_pitch_mod_2_sw), C.get_midi_nrpn_value(0, 564))) # SLOT_OSC_2_PITCH_MOD_2_SW, NRPN_VALUE_OSC_2_PITCH_MOD_2_SW
  cc_osc_2_pw_mod_1_amt = C.get_midi_nrpn_value(0, 437) # NRPN_CC_OSC_2_PW_MOD_1_AMT
  signals[181] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pw_mod_1_amt, C.get_midi_cc_value(0, cc_osc_2_pw_mod_1_amt), C.get_midi_nrpn_value(0, 565))) # SLOT_OSC_2_PW_MOD_1_AMT, NRPN_VALUE_OSC_2_PW_MOD_1_AMT
  cc_osc_2_pw_mod_1_pol = C.get_midi_nrpn_value(0, 438) # NRPN_CC_OSC_2_PW_MOD_1_POL
  signals[182] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pw_mod_1_pol, C.get_midi_cc_value(0, cc_osc_2_pw_mod_1_pol), C.get_midi_nrpn_value(0, 566))) # SLOT_OSC_2_PW_MOD_1_POL, NRPN_VALUE_OSC_2_PW_MOD_1_POL
  cc_osc_2_pw_mod_2_amt = C.get_midi_nrpn_value(0, 439) # NRPN_CC_OSC_2_PW_MOD_2_AMT
  signals[183] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_pw_mod_2_amt, C.get_midi_cc_value(0, cc_osc_2_pw_mod_2_amt), C.get_midi_nrpn_value(0, 567))) # SLOT_OSC_2_PW_MOD_2_AMT, NRPN_VALUE_OSC_2_PW_MOD_2_AMT
  cc_osc_2_pw_mod_2_pol = C.get_midi_nrpn_value(0, 440) # NRPN_CC_OSC_2_PW_MOD_2_POL
  signals[184] = cc_to_bipolar(cc_or_nrpn(cc_osc_2_pw_mod_2_pol, C.get_midi_cc_value(0, cc_osc_2_pw_mod_2_pol), C.get_midi_nrpn_value(0, 568))) # SLOT_OSC_2_PW_MOD_2_POL, NRPN_VALUE_OSC_2_PW_MOD_2_POL
  cc_osc_2_sync_sw = C.get_midi_nrpn_value(0, 441) # NRPN_CC_OSC_2_SYNC_SW
  signals[185] = cc_to_unipolar(cc_or_nrpn(cc_osc_2_sync_sw, C.get_midi_cc_value(0, cc_osc_2_sync_sw), C.get_midi_nrpn_value(0, 569))) # SLOT_OSC_2_SYNC_SW, NRPN_VALUE_OSC_2_SYNC_SW
  cc_noise_1_color = C.get_midi_nrpn_value(0, 442) # NRPN_CC_NOISE_1_COLOR
  signals[186] = cc_to_unipolar(cc_or_nrpn(cc_noise_1_color, C.get_midi_cc_value(0, cc_noise_1_color), C.get_midi_nrpn_value(0, 570))) # SLOT_NOISE_1_COLOR, NRPN_VALUE_NOISE_1_COLOR
  cc_noise_1_level = C.get_midi_nrpn_value(0, 443) # NRPN_CC_NOISE_1_LEVEL
  signals[187] = cc_to_unipolar(cc_or_nrpn(cc_noise_1_level, C.get_midi_cc_value(0, cc_noise_1_level), C.get_midi_nrpn_value(0, 571))) # SLOT_NOISE_1_LEVEL, NRPN_VALUE_NOISE_1_LEVEL
  cc_mixer_2_level_1 = C.get_midi_nrpn_value(0, 444) # NRPN_CC_MIXER_2_LEVEL_1
  signals[188] = cc_to_unipolar(cc_or_nrpn(cc_mixer_2_level_1, C.get_midi_cc_value(0, cc_mixer_2_level_1), C.get_midi_nrpn_value(0, 572))) # SLOT_MIXER_2_LEVEL_1, NRPN_VALUE_MIXER_2_LEVEL_1
  cc_mixer_2_level_2 = C.get_midi_nrpn_value(0, 445) # NRPN_CC_MIXER_2_LEVEL_2
  signals[189] = cc_to_unipolar(cc_or_nrpn(cc_mixer_2_level_2, C.get_midi_cc_value(0, cc_mixer_2_level_2), C.get_midi_nrpn_value(0, 573))) # SLOT_MIXER_2_LEVEL_2, NRPN_VALUE_MIXER_2_LEVEL_2
  cc_mixer_2_level_3 = C.get_midi_nrpn_value(0, 446) # NRPN_CC_MIXER_2_LEVEL_3
  signals[190] = cc_to_unipolar(cc_or_nrpn(cc_mixer_2_level_3, C.get_midi_cc_value(0, cc_mixer_2_level_3), C.get_midi_nrpn_value(0, 574))) # SLOT_MIXER_2_LEVEL_3, NRPN_VALUE_MIXER_2_LEVEL_3
  cc_mixer_2_level_4 = C.get_midi_nrpn_value(0, 447) # NRPN_CC_MIXER_2_LEVEL_4
  signals[191] = cc_to_unipolar(cc_or_nrpn(cc_mixer_2_level_4, C.get_midi_cc_value(0, cc_mixer_2_level_4), C.get_midi_nrpn_value(0, 575))) # SLOT_MIXER_2_LEVEL_4, NRPN_VALUE_MIXER_2_LEVEL_4
  cc_mixer_2_out_level = C.get_midi_nrpn_value(0, 448) # NRPN_CC_MIXER_2_OUT_LEVEL
  signals[192] = cc_to_unipolar(cc_or_nrpn(cc_mixer_2_out_level, C.get_midi_cc_value(0, cc_mixer_2_out_level), C.get_midi_nrpn_value(0, 576))) # SLOT_MIXER_2_OUT_LEVEL, NRPN_VALUE_MIXER_2_OUT_LEVEL
  cc_filter_1_mode = C.get_midi_nrpn_value(0, 449) # NRPN_CC_FILTER_1_MODE
  signals[193] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_mode, C.get_midi_cc_value(0, cc_filter_1_mode), C.get_midi_nrpn_value(0, 577))) # SLOT_FILTER_1_MODE, NRPN_VALUE_FILTER_1_MODE
  cc_filter_1_cutoff = C.get_midi_nrpn_value(0, 450) # NRPN_CC_FILTER_1_CUTOFF
  signals[194] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_cutoff, C.get_midi_cc_value(0, cc_filter_1_cutoff), C.get_midi_nrpn_value(0, 578))) # SLOT_FILTER_1_CUTOFF, NRPN_VALUE_FILTER_1_CUTOFF
  cc_filter_1_resonance = C.get_midi_nrpn_value(0, 451) # NRPN_CC_FILTER_1_RESONANCE
  signals[195] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_resonance, C.get_midi_cc_value(0, cc_filter_1_resonance), C.get_midi_nrpn_value(0, 579))) # SLOT_FILTER_1_RESONANCE, NRPN_VALUE_FILTER_1_RESONANCE
  cc_filter_1_gain_1 = C.get_midi_nrpn_value(0, 452) # NRPN_CC_FILTER_1_GAIN_1
  signals[196] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_gain_1, C.get_midi_cc_value(0, cc_filter_1_gain_1), C.get_midi_nrpn_value(0, 580))) # SLOT_FILTER_1_GAIN_1, NRPN_VALUE_FILTER_1_GAIN_1
  cc_filter_1_gain_2 = C.get_midi_nrpn_value(0, 453) # NRPN_CC_FILTER_1_GAIN_2
  signals[197] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_gain_2, C.get_midi_cc_value(0, cc_filter_1_gain_2), C.get_midi_nrpn_value(0, 581))) # SLOT_FILTER_1_GAIN_2, NRPN_VALUE_FILTER_1_GAIN_2
  cc_filter_1_pitch_amt = C.get_midi_nrpn_value(0, 454) # NRPN_CC_FILTER_1_PITCH_AMT
  signals[198] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_pitch_amt, C.get_midi_cc_value(0, cc_filter_1_pitch_amt), C.get_midi_nrpn_value(0, 582))) # SLOT_FILTER_1_PITCH_AMT, NRPN_VALUE_FILTER_1_PITCH_AMT
  cc_filter_1_pitch_pol = C.get_midi_nrpn_value(0, 455) # NRPN_CC_FILTER_1_PITCH_POL
  signals[199] = cc_to_bipolar(cc_or_nrpn(cc_filter_1_pitch_pol, C.get_midi_cc_value(0, cc_filter_1_pitch_pol), C.get_midi_nrpn_value(0, 583))) # SLOT_FILTER_1_PITCH_POL, NRPN_VALUE_FILTER_1_PITCH_POL
  cc_filter_1_mod_1_amt = C.get_midi_nrpn_value(0, 456) # NRPN_CC_FILTER_1_MOD_1_AMT
  signals[200] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_mod_1_amt, C.get_midi_cc_value(0, cc_filter_1_mod_1_amt), C.get_midi_nrpn_value(0, 584))) # SLOT_FILTER_1_MOD_1_AMT, NRPN_VALUE_FILTER_1_MOD_1_AMT
  cc_filter_1_mod_1_pol = C.get_midi_nrpn_value(0, 457) # NRPN_CC_FILTER_1_MOD_1_POL
  signals[201] = cc_to_bipolar(cc_or_nrpn(cc_filter_1_mod_1_pol, C.get_midi_cc_value(0, cc_filter_1_mod_1_pol), C.get_midi_nrpn_value(0, 585))) # SLOT_FILTER_1_MOD_1_POL, NRPN_VALUE_FILTER_1_MOD_1_POL
  cc_filter_1_mod_2_amt = C.get_midi_nrpn_value(0, 458) # NRPN_CC_FILTER_1_MOD_2_AMT
  signals[202] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_mod_2_amt, C.get_midi_cc_value(0, cc_filter_1_mod_2_amt), C.get_midi_nrpn_value(0, 586))) # SLOT_FILTER_1_MOD_2_AMT, NRPN_VALUE_FILTER_1_MOD_2_AMT
  cc_filter_1_mod_2_pol = C.get_midi_nrpn_value(0, 459) # NRPN_CC_FILTER_1_MOD_2_POL
  signals[203] = cc_to_bipolar(cc_or_nrpn(cc_filter_1_mod_2_pol, C.get_midi_cc_value(0, cc_filter_1_mod_2_pol), C.get_midi_nrpn_value(0, 587))) # SLOT_FILTER_1_MOD_2_POL, NRPN_VALUE_FILTER_1_MOD_2_POL
  cc_filter_2_mode = C.get_midi_nrpn_value(0, 460) # NRPN_CC_FILTER_2_MODE
  signals[204] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_mode, C.get_midi_cc_value(0, cc_filter_2_mode), C.get_midi_nrpn_value(0, 588))) # SLOT_FILTER_2_MODE, NRPN_VALUE_FILTER_2_MODE
  cc_filter_2_cutoff = C.get_midi_nrpn_value(0, 461) # NRPN_CC_FILTER_2_CUTOFF
  signals[205] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_cutoff, C.get_midi_cc_value(0, cc_filter_2_cutoff), C.get_midi_nrpn_value(0, 589))) # SLOT_FILTER_2_CUTOFF, NRPN_VALUE_FILTER_2_CUTOFF
  cc_filter_2_resonance = C.get_midi_nrpn_value(0, 462) # NRPN_CC_FILTER_2_RESONANCE
  signals[206] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_resonance, C.get_midi_cc_value(0, cc_filter_2_resonance), C.get_midi_nrpn_value(0, 590))) # SLOT_FILTER_2_RESONANCE, NRPN_VALUE_FILTER_2_RESONANCE
  cc_filter_2_gain_1 = C.get_midi_nrpn_value(0, 463) # NRPN_CC_FILTER_2_GAIN_1
  signals[207] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_gain_1, C.get_midi_cc_value(0, cc_filter_2_gain_1), C.get_midi_nrpn_value(0, 591))) # SLOT_FILTER_2_GAIN_1, NRPN_VALUE_FILTER_2_GAIN_1
  cc_filter_2_gain_2 = C.get_midi_nrpn_value(0, 464) # NRPN_CC_FILTER_2_GAIN_2
  signals[208] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_gain_2, C.get_midi_cc_value(0, cc_filter_2_gain_2), C.get_midi_nrpn_value(0, 592))) # SLOT_FILTER_2_GAIN_2, NRPN_VALUE_FILTER_2_GAIN_2
  cc_filter_2_pitch_amt = C.get_midi_nrpn_value(0, 465) # NRPN_CC_FILTER_2_PITCH_AMT
  signals[209] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_pitch_amt, C.get_midi_cc_value(0, cc_filter_2_pitch_amt), C.get_midi_nrpn_value(0, 593))) # SLOT_FILTER_2_PITCH_AMT, NRPN_VALUE_FILTER_2_PITCH_AMT
  cc_filter_2_pitch_pol = C.get_midi_nrpn_value(0, 466) # NRPN_CC_FILTER_2_PITCH_POL
  signals[210] = cc_to_bipolar(cc_or_nrpn(cc_filter_2_pitch_pol, C.get_midi_cc_value(0, cc_filter_2_pitch_pol), C.get_midi_nrpn_value(0, 594))) # SLOT_FILTER_2_PITCH_POL, NRPN_VALUE_FILTER_2_PITCH_POL
  cc_filter_2_mod_1_amt = C.get_midi_nrpn_value(0, 467) # NRPN_CC_FILTER_2_MOD_1_AMT
  signals[211] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_mod_1_amt, C.get_midi_cc_value(0, cc_filter_2_mod_1_amt), C.get_midi_nrpn_value(0, 595))) # SLOT_FILTER_2_MOD_1_AMT, NRPN_VALUE_FILTER_2_MOD_1_AMT
  cc_filter_2_mod_1_pol = C.get_midi_nrpn_value(0, 468) # NRPN_CC_FILTER_2_MOD_1_POL
  signals[212] = cc_to_bipolar(cc_or_nrpn(cc_filter_2_mod_1_pol, C.get_midi_cc_value(0, cc_filter_2_mod_1_pol), C.get_midi_nrpn_value(0, 596))) # SLOT_FILTER_2_MOD_1_POL, NRPN_VALUE_FILTER_2_MOD_1_POL
  cc_filter_2_mod_2_amt = C.get_midi_nrpn_value(0, 469) # NRPN_CC_FILTER_2_MOD_2_AMT
  signals[213] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_mod_2_amt, C.get_midi_cc_value(0, cc_filter_2_mod_2_amt), C.get_midi_nrpn_value(0, 597))) # SLOT_FILTER_2_MOD_2_AMT, NRPN_VALUE_FILTER_2_MOD_2_AMT
  cc_filter_2_mod_2_pol = C.get_midi_nrpn_value(0, 470) # NRPN_CC_FILTER_2_MOD_2_POL
  signals[214] = cc_to_bipolar(cc_or_nrpn(cc_filter_2_mod_2_pol, C.get_midi_cc_value(0, cc_filter_2_mod_2_pol), C.get_midi_nrpn_value(0, 598))) # SLOT_FILTER_2_MOD_2_POL, NRPN_VALUE_FILTER_2_MOD_2_POL
  cc_amp_1_gain_1 = C.get_midi_nrpn_value(0, 471) # NRPN_CC_AMP_1_GAIN_1
  signals[215] = cc_to_unipolar(cc_or_nrpn(cc_amp_1_gain_1, C.get_midi_cc_value(0, cc_amp_1_gain_1), C.get_midi_nrpn_value(0, 599))) # SLOT_AMP_1_GAIN_1, NRPN_VALUE_AMP_1_GAIN_1
  cc_amp_1_gain_2 = C.get_midi_nrpn_value(0, 472) # NRPN_CC_AMP_1_GAIN_2
  signals[216] = cc_to_unipolar(cc_or_nrpn(cc_amp_1_gain_2, C.get_midi_cc_value(0, cc_amp_1_gain_2), C.get_midi_nrpn_value(0, 600))) # SLOT_AMP_1_GAIN_2, NRPN_VALUE_AMP_1_GAIN_2
  cc_amp_1_mod_1_2_mix = C.get_midi_nrpn_value(0, 473) # NRPN_CC_AMP_1_MOD_1_2_MIX
  signals[217] = cc_to_unipolar(cc_or_nrpn(cc_amp_1_mod_1_2_mix, C.get_midi_cc_value(0, cc_amp_1_mod_1_2_mix), C.get_midi_nrpn_value(0, 601))) # SLOT_AMP_1_MOD_1_2_MIX, NRPN_VALUE_AMP_1_MOD_1_2_MIX
  cc_chorus_1_mix = C.get_midi_nrpn_value(0, 474) # NRPN_CC_CHORUS_1_MIX
  signals[218] = cc_to_unipolar(cc_or_nrpn(cc_chorus_1_mix, C.get_midi_cc_value(0, cc_chorus_1_mix), C.get_midi_nrpn_value(0, 602))) # SLOT_CHORUS_1_MIX, NRPN_VALUE_CHORUS_1_MIX
  cc_chorus_1_rate = C.get_midi_nrpn_value(0, 475) # NRPN_CC_CHORUS_1_RATE
  signals[219] = cc_to_unipolar(cc_or_nrpn(cc_chorus_1_rate, C.get_midi_cc_value(0, cc_chorus_1_rate), C.get_midi_nrpn_value(0, 603))) # SLOT_CHORUS_1_RATE, NRPN_VALUE_CHORUS_1_RATE
  cc_chorus_1_depth = C.get_midi_nrpn_value(0, 476) # NRPN_CC_CHORUS_1_DEPTH
  signals[220] = cc_to_unipolar(cc_or_nrpn(cc_chorus_1_depth, C.get_midi_cc_value(0, cc_chorus_1_depth), C.get_midi_nrpn_value(0, 604))) # SLOT_CHORUS_1_DEPTH, NRPN_VALUE_CHORUS_1_DEPTH
  cc_delay_1_mix = C.get_midi_nrpn_value(0, 477) # NRPN_CC_DELAY_1_MIX
  signals[221] = cc_to_unipolar(cc_or_nrpn(cc_delay_1_mix, C.get_midi_cc_value(0, cc_delay_1_mix), C.get_midi_nrpn_value(0, 605))) # SLOT_DELAY_1_MIX, NRPN_VALUE_DELAY_1_MIX
  cc_delay_1_time = C.get_midi_nrpn_value(0, 478) # NRPN_CC_DELAY_1_TIME
  signals[222] = cc_to_unipolar(cc_or_nrpn(cc_delay_1_time, C.get_midi_cc_value(0, cc_delay_1_time), C.get_midi_nrpn_value(0, 606))) # SLOT_DELAY_1_TIME, NRPN_VALUE_DELAY_1_TIME
  cc_delay_1_feedback = C.get_midi_nrpn_value(0, 479) # NRPN_CC_DELAY_1_FEEDBACK
  signals[223] = cc_to_unipolar(cc_or_nrpn(cc_delay_1_feedback, C.get_midi_cc_value(0, cc_delay_1_feedback), C.get_midi_nrpn_value(0, 607))) # SLOT_DELAY_1_FEEDBACK, NRPN_VALUE_DELAY_1_FEEDBACK
  cc_amp_1_limiter_sw = C.get_midi_nrpn_value(0, 484) # NRPN_CC_AMP_1_LIMITER_SW
  signals[228] = cc_to_unipolar(cc_or_nrpn(cc_amp_1_limiter_sw, C.get_midi_cc_value(0, cc_amp_1_limiter_sw), C.get_midi_nrpn_value(0, 612))) # SLOT_AMP_1_LIMITER_SW, NRPN_VALUE_AMP_1_LIMITER_SW
  cc_filter_1_drive = C.get_midi_nrpn_value(0, 485) # NRPN_CC_FILTER_1_DRIVE
  signals[229] = cc_to_unipolar(cc_or_nrpn(cc_filter_1_drive, C.get_midi_cc_value(0, cc_filter_1_drive), C.get_midi_nrpn_value(0, 613))) # SLOT_FILTER_1_DRIVE, NRPN_VALUE_FILTER_1_DRIVE
  cc_filter_2_drive = C.get_midi_nrpn_value(0, 486) # NRPN_CC_FILTER_2_DRIVE
  signals[230] = cc_to_unipolar(cc_or_nrpn(cc_filter_2_drive, C.get_midi_cc_value(0, cc_filter_2_drive), C.get_midi_nrpn_value(0, 614))) # SLOT_FILTER_2_DRIVE, NRPN_VALUE_FILTER_2_DRIVE
  cc_mod_wheel = C.get_midi_nrpn_value(0, 480) # NRPN_CC_MOD_WHEEL
  mod_wheel = C.get_midi_cc_value(0, cc_mod_wheel)
  signals[8] = cc_or_zero(cc_mod_wheel, cc_to_unipolar(mod_wheel)) # SIGNAL_MOD_WHEEL
  signals[9] = 1.0 - signals[8] # SIGNAL_MOD_WHEEL_REV, SIGNAL_MOD_WHEEL
  signals[10] = 0.0 - signals[8] # SIGNAL_MOD_WHEEL_INV, SIGNAL_MOD_WHEEL
  signals[11] = signals[8] - 1.0 # SIGNAL_MOD_WHEEL_REV_INV, SIGNAL_MOD_WHEEL
  cc_breath = C.get_midi_nrpn_value(0, 481) # NRPN_CC_BREATH
  breath = C.get_midi_cc_value(0, cc_breath)
  signals[12] = cc_or_zero(cc_breath, cc_to_unipolar(breath)) # SIGNAL_BREATH
  signals[13] = 1.0 - signals[12] # SIGNAL_BREATH_REV, SIGNAL_BREATH
  signals[14] = 0.0 - signals[12] # SIGNAL_BREATH_INV, SIGNAL_BREATH
  signals[15] = signals[12] - 1.0 # SIGNAL_BREATH_REV_INV, SIGNAL_BREATH
  cc_general_1 = C.get_midi_nrpn_value(0, 482) # NRPN_CC_GENERAL_1
  general_1 = cc_or_nrpn(cc_general_1, C.get_midi_cc_value(0, cc_general_1), C.get_midi_nrpn_value(0, 610)) # NRPN_VALUE_GENERAL_1
  signals[16] = cc_to_unipolar(general_1) # SIGNAL_GENERAL_1
  signals[17] = 1.0 - signals[16] # SIGNAL_GENERAL_1_REV, SIGNAL_GENERAL_1
  signals[18] = 0.0 - signals[16] # SIGNAL_GENERAL_1_INV, SIGNAL_GENERAL_1
  signals[19] = signals[16] - 1.0 # SIGNAL_GENERAL_1_REV_INV, SIGNAL_GENERAL_1
  signals[20] = signals[16] - 0.5 # SIGNAL_GENERAL_1_BIPOLAR, SIGNAL_GENERAL_1
  signals[21] = 0.5 - signals[16] # SIGNAL_GENERAL_1_BIPOLAR_INV, SIGNAL_GENERAL_1
  signals[22] = QUARTER_SINE_TABLE[120 - value_table_index(general_1)] # SIGNAL_GENERAL_1_COS
  signals[23] = QUARTER_SINE_TABLE[value_table_index(general_1)] # SIGNAL_GENERAL_1_SIN
  signals[24] = (signals[16] < 0.5) ? 1.0 : (2.0 - (signals[16] + signals[16])) # SIGNAL_GENERAL_1_LO, SIGNAL_GENERAL_1
  signals[25] = (signals[16] > 0.5) ? 1.0 : (signals[16] + signals[16]) # SIGNAL_GENERAL_1_HI, SIGNAL_GENERAL_1
  signals[26] = (signals[16] > 0.5) ? 0.0 : (1.0 - (signals[16] + signals[16])) # SIGNAL_GENERAL_1_NEG, SIGNAL_GENERAL_1
  signals[27] = (signals[16] < 0.5) ? (signals[16] + signals[16]) : (2.0 - (signals[16] + signals[16])) # SIGNAL_GENERAL_1_MID, SIGNAL_GENERAL_1
  signals[28] = (signals[16] < 0.5) ? 0.0 : ((signals[16] + signals[16]) - 1.0) # SIGNAL_GENERAL_1_POS, SIGNAL_GENERAL_1
  cc_general_2 = C.get_midi_nrpn_value(0, 483) # NRPN_CC_GENERAL_2
  general_2 = cc_or_nrpn(cc_general_2, C.get_midi_cc_value(0, cc_general_2), C.get_midi_nrpn_value(0, 611)) # NRPN_VALUE_GENERAL_2
  signals[29] = cc_to_unipolar(general_2) # SIGNAL_GENERAL_2
  signals[30] = 1.0 - signals[29] # SIGNAL_GENERAL_2_REV, SIGNAL_GENERAL_2
  signals[31] = 0.0 - signals[29] # SIGNAL_GENERAL_2_INV, SIGNAL_GENERAL_2
  signals[32] = signals[29] - 1.0 # SIGNAL_GENERAL_2_REV_INV, SIGNAL_GENERAL_2
  signals[33] = signals[29] - 0.5 # SIGNAL_GENERAL_2_BIPOLAR, SIGNAL_GENERAL_2
  signals[34] = 0.5 - signals[29] # SIGNAL_GENERAL_2_BIPOLAR_INV, SIGNAL_GENERAL_2
  signals[35] = QUARTER_SINE_TABLE[120 - value_table_index(general_2)] # SIGNAL_GENERAL_2_COS
  signals[36] = QUARTER_SINE_TABLE[value_table_index(general_2)] # SIGNAL_GENERAL_2_SIN
  signals[37] = (signals[29] < 0.5) ? 1.0 : (2.0 - (signals[29] + signals[29])) # SIGNAL_GENERAL_2_LO, SIGNAL_GENERAL_2
  signals[38] = (signals[29] > 0.5) ? 1.0 : (signals[29] + signals[29]) # SIGNAL_GENERAL_2_HI, SIGNAL_GENERAL_2
  signals[39] = (signals[29] > 0.5) ? 0.0 : (1.0 - (signals[29] + signals[29])) # SIGNAL_GENERAL_2_NEG, SIGNAL_GENERAL_2
  signals[40] = (signals[29] < 0.5) ? (signals[29] + signals[29]) : (2.0 - (signals[29] + signals[29])) # SIGNAL_GENERAL_2_MID, SIGNAL_GENERAL_2
  signals[41] = (signals[29] < 0.5) ? 0.0 : ((signals[29] + signals[29]) - 1.0) # SIGNAL_GENERAL_2_POS, SIGNAL_GENERAL_2
  signals[508] = Dsp.smooth(signals[8], signals[508], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_MOD_WHEEL, SIGNAL_MOD_WHEEL
  smoothed_mod_wheel = Dsp.smooth(signals[508], signals[474], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_MOD_WHEEL, SIGNAL_MOD_WHEEL + SMOOTHED_SLOT_OFFSET
  signals[474] = smoothed_mod_wheel # SIGNAL_MOD_WHEEL + SMOOTHED_SLOT_OFFSET
  signals[475] = 1.0 - smoothed_mod_wheel # SIGNAL_MOD_WHEEL_REV + SMOOTHED_SLOT_OFFSET
  signals[476] = 0.0 - smoothed_mod_wheel # SIGNAL_MOD_WHEEL_INV + SMOOTHED_SLOT_OFFSET
  signals[477] = smoothed_mod_wheel - 1.0 # SIGNAL_MOD_WHEEL_REV_INV + SMOOTHED_SLOT_OFFSET
  signals[509] = Dsp.smooth(signals[12], signals[509], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_BREATH, SIGNAL_BREATH
  smoothed_breath = Dsp.smooth(signals[509], signals[478], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_BREATH, SIGNAL_BREATH + SMOOTHED_SLOT_OFFSET
  signals[478] = smoothed_breath # SIGNAL_BREATH + SMOOTHED_SLOT_OFFSET
  signals[479] = 1.0 - smoothed_breath # SIGNAL_BREATH_REV + SMOOTHED_SLOT_OFFSET
  signals[480] = 0.0 - smoothed_breath # SIGNAL_BREATH_INV + SMOOTHED_SLOT_OFFSET
  signals[481] = smoothed_breath - 1.0 # SIGNAL_BREATH_REV_INV + SMOOTHED_SLOT_OFFSET
  signals[510] = Dsp.smooth(signals[16], signals[510], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_GENERAL_1, SIGNAL_GENERAL_1
  smoothed_general_1 = Dsp.smooth(signals[510], signals[482], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_GENERAL_1, SIGNAL_GENERAL_1 + SMOOTHED_SLOT_OFFSET
  signals[482] = smoothed_general_1 # SIGNAL_GENERAL_1 + SMOOTHED_SLOT_OFFSET
  signals[483] = 1.0 - smoothed_general_1 # SIGNAL_GENERAL_1_REV + SMOOTHED_SLOT_OFFSET
  signals[484] = 0.0 - smoothed_general_1 # SIGNAL_GENERAL_1_INV + SMOOTHED_SLOT_OFFSET
  signals[485] = smoothed_general_1 - 1.0 # SIGNAL_GENERAL_1_REV_INV + SMOOTHED_SLOT_OFFSET
  signals[486] = smoothed_general_1 - 0.5 # SIGNAL_GENERAL_1_BIPOLAR + SMOOTHED_SLOT_OFFSET
  signals[487] = 0.5 - smoothed_general_1 # SIGNAL_GENERAL_1_BIPOLAR_INV + SMOOTHED_SLOT_OFFSET
  signals[488] = quarter_sine(1.0 - smoothed_general_1) # SIGNAL_GENERAL_1_COS + SMOOTHED_SLOT_OFFSET
  signals[489] = quarter_sine(smoothed_general_1) # SIGNAL_GENERAL_1_SIN + SMOOTHED_SLOT_OFFSET
  signals[490] = (smoothed_general_1 < 0.5) ? 1.0 : (2.0 - (smoothed_general_1 + smoothed_general_1)) # SIGNAL_GENERAL_1_LO + SMOOTHED_SLOT_OFFSET
  signals[491] = (smoothed_general_1 > 0.5) ? 1.0 : (smoothed_general_1 + smoothed_general_1) # SIGNAL_GENERAL_1_HI + SMOOTHED_SLOT_OFFSET
  signals[492] = (smoothed_general_1 > 0.5) ? 0.0 : (1.0 - (smoothed_general_1 + smoothed_general_1)) # SIGNAL_GENERAL_1_NEG + SMOOTHED_SLOT_OFFSET
  signals[493] = (smoothed_general_1 < 0.5) ? (smoothed_general_1 + smoothed_general_1) : (2.0 - (smoothed_general_1 + smoothed_general_1)) # SIGNAL_GENERAL_1_MID + SMOOTHED_SLOT_OFFSET
  signals[494] = (smoothed_general_1 < 0.5) ? 0.0 : ((smoothed_general_1 + smoothed_general_1) - 1.0) # SIGNAL_GENERAL_1_POS + SMOOTHED_SLOT_OFFSET
  signals[511] = Dsp.smooth(signals[29], signals[511], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_GENERAL_2, SIGNAL_GENERAL_2
  smoothed_general_2 = Dsp.smooth(signals[511], signals[495], CONTROLLER_SMOOTHING_BLEND) # SMOOTHED_STAGE_1_GENERAL_2, SIGNAL_GENERAL_2 + SMOOTHED_SLOT_OFFSET
  signals[495] = smoothed_general_2 # SIGNAL_GENERAL_2 + SMOOTHED_SLOT_OFFSET
  signals[496] = 1.0 - smoothed_general_2 # SIGNAL_GENERAL_2_REV + SMOOTHED_SLOT_OFFSET
  signals[497] = 0.0 - smoothed_general_2 # SIGNAL_GENERAL_2_INV + SMOOTHED_SLOT_OFFSET
  signals[498] = smoothed_general_2 - 1.0 # SIGNAL_GENERAL_2_REV_INV + SMOOTHED_SLOT_OFFSET
  signals[499] = smoothed_general_2 - 0.5 # SIGNAL_GENERAL_2_BIPOLAR + SMOOTHED_SLOT_OFFSET
  signals[500] = 0.5 - smoothed_general_2 # SIGNAL_GENERAL_2_BIPOLAR_INV + SMOOTHED_SLOT_OFFSET
  signals[501] = quarter_sine(1.0 - smoothed_general_2) # SIGNAL_GENERAL_2_COS + SMOOTHED_SLOT_OFFSET
  signals[502] = quarter_sine(smoothed_general_2) # SIGNAL_GENERAL_2_SIN + SMOOTHED_SLOT_OFFSET
  signals[503] = (smoothed_general_2 < 0.5) ? 1.0 : (2.0 - (smoothed_general_2 + smoothed_general_2)) # SIGNAL_GENERAL_2_LO + SMOOTHED_SLOT_OFFSET
  signals[504] = (smoothed_general_2 > 0.5) ? 1.0 : (smoothed_general_2 + smoothed_general_2) # SIGNAL_GENERAL_2_HI + SMOOTHED_SLOT_OFFSET
  signals[505] = (smoothed_general_2 > 0.5) ? 0.0 : (1.0 - (smoothed_general_2 + smoothed_general_2)) # SIGNAL_GENERAL_2_NEG + SMOOTHED_SLOT_OFFSET
  signals[506] = (smoothed_general_2 < 0.5) ? (smoothed_general_2 + smoothed_general_2) : (2.0 - (smoothed_general_2 + smoothed_general_2)) # SIGNAL_GENERAL_2_MID + SMOOTHED_SLOT_OFFSET
  signals[507] = (smoothed_general_2 < 0.5) ? 0.0 : ((smoothed_general_2 + smoothed_general_2) - 1.0) # SIGNAL_GENERAL_2_POS + SMOOTHED_SLOT_OFFSET
  pitch_1.set_glide(signals[source_pitch_1_glide])
  pitch_1.set_glide_1_switch(signals[source_pitch_1_out_1_glide_sw])
  pitch_1.set_glide_2_switch(signals[source_pitch_1_out_2_glide_sw])
  pitch_1.set_bend_amount(signals[source_pitch_1_bend_amt])
  pitch_1.set_bend_polarity(signals[source_pitch_1_bend_pol])
  pitch_1.set_bend_1_switch(signals[source_pitch_1_out_1_bend_sw])
  pitch_1.set_bend_2_switch(signals[source_pitch_1_out_2_bend_sw])
  pitch_1.set_stretch(signals[source_pitch_1_stretch])
  eg_1.set_attack(signals[source_eg_1_attack])
  eg_1.set_decay(signals[source_eg_1_decay])
  eg_1.set_sustain(signals[source_eg_1_sustain])
  eg_1.set_release_switch(signals[source_eg_1_release_sw])
  eg_1.set_level(signals[source_eg_1_level])
  eg_2.set_attack(signals[source_eg_2_attack])
  eg_2.set_decay(signals[source_eg_2_decay])
  eg_2.set_sustain(signals[source_eg_2_sustain])
  eg_2.set_release_switch(signals[source_eg_2_release_sw])
  eg_2.set_level(signals[source_eg_2_level])
  lfo_1.set_wave(signals[source_lfo_1_wave])
  lfo_1.set_rate(signals[source_lfo_1_rate])
  lfo_1.set_level(signals[source_lfo_1_level])
  lfo_1.set_rate_modulation_amount(signals[source_lfo_1_rate_mod_amt])
  lfo_1.set_level_modulation_amount(signals[source_lfo_1_level_mod_amt])
  lfo_1.set_reset_switch(signals[source_lfo_1_reset_sw])
  mixer_1.set_level_1(signals[source_mixer_1_level_1])
  mixer_1.set_level_2(signals[source_mixer_1_level_2])
  mixer_1.set_level_3(signals[source_mixer_1_level_3])
  mixer_1.set_level_4(signals[source_mixer_1_level_4])
  mixer_1.set_out_level(signals[source_mixer_1_out_level])
  osc_1.set_waveform(signals[source_osc_1_wave])
  osc_1.set_pulse_width(signals[source_osc_1_pw])
  osc_1.set_pitch_coarse(signals[source_osc_1_pitch_coarse])
  osc_1.set_pitch_fine(signals[source_osc_1_pitch_fine])
  osc_1.set_pitch_modulation_1_amount(signals[source_osc_1_pitch_mod_1_amt])
  osc_1.set_pitch_modulation_1_polarity(signals[source_osc_1_pitch_mod_1_pol])
  osc_1.set_pitch_modulation_1_switch(signals[source_osc_1_pitch_mod_1_sw])
  osc_1.set_pitch_modulation_2_amount(signals[source_osc_1_pitch_mod_2_amt])
  osc_1.set_pitch_modulation_2_polarity(signals[source_osc_1_pitch_mod_2_pol])
  osc_1.set_pitch_modulation_2_switch(signals[source_osc_1_pitch_mod_2_sw])
  osc_1.set_pw_modulation_1_amount(signals[source_osc_1_pw_mod_1_amt])
  osc_1.set_pw_modulation_1_polarity(signals[source_osc_1_pw_mod_1_pol])
  osc_1.set_pw_modulation_2_amount(signals[source_osc_1_pw_mod_2_amt])
  osc_1.set_pw_modulation_2_polarity(signals[source_osc_1_pw_mod_2_pol])
  osc_2.set_waveform(signals[source_osc_2_wave])
  osc_2.set_pulse_width(signals[source_osc_2_pw])
  osc_2.set_pitch_coarse(signals[source_osc_2_pitch_coarse])
  osc_2.set_pitch_fine(signals[source_osc_2_pitch_fine])
  osc_2.set_pitch_modulation_1_amount(signals[source_osc_2_pitch_mod_1_amt])
  osc_2.set_pitch_modulation_1_polarity(signals[source_osc_2_pitch_mod_1_pol])
  osc_2.set_pitch_modulation_1_switch(signals[source_osc_2_pitch_mod_1_sw])
  osc_2.set_pitch_modulation_2_amount(signals[source_osc_2_pitch_mod_2_amt])
  osc_2.set_pitch_modulation_2_polarity(signals[source_osc_2_pitch_mod_2_pol])
  osc_2.set_pitch_modulation_2_switch(signals[source_osc_2_pitch_mod_2_sw])
  osc_2.set_pw_modulation_1_amount(signals[source_osc_2_pw_mod_1_amt])
  osc_2.set_pw_modulation_1_polarity(signals[source_osc_2_pw_mod_1_pol])
  osc_2.set_pw_modulation_2_amount(signals[source_osc_2_pw_mod_2_amt])
  osc_2.set_pw_modulation_2_polarity(signals[source_osc_2_pw_mod_2_pol])
  osc_2.set_sync_switch(signals[source_osc_2_sync_sw])
  noise_1.set_color(signals[source_noise_1_color])
  noise_1.set_level(signals[source_noise_1_level])
  mixer_2.set_level_1(signals[source_mixer_2_level_1])
  mixer_2.set_level_2(signals[source_mixer_2_level_2])
  mixer_2.set_level_3(signals[source_mixer_2_level_3])
  mixer_2.set_level_4(signals[source_mixer_2_level_4])
  mixer_2.set_out_level(signals[source_mixer_2_out_level])
  filter_1.set_mode(signals[source_filter_1_mode])
  filter_1.set_cutoff(signals[source_filter_1_cutoff])
  filter_1.set_resonance(signals[source_filter_1_resonance])
  filter_1.set_gain_1(signals[source_filter_1_gain_1])
  filter_1.set_gain_2(signals[source_filter_1_gain_2])
  filter_1.set_pitch_amount(signals[source_filter_1_pitch_amt])
  filter_1.set_pitch_polarity(signals[source_filter_1_pitch_pol])
  filter_1.set_modulation_1_amount(signals[source_filter_1_mod_1_amt])
  filter_1.set_modulation_1_polarity(signals[source_filter_1_mod_1_pol])
  filter_1.set_modulation_2_amount(signals[source_filter_1_mod_2_amt])
  filter_1.set_modulation_2_polarity(signals[source_filter_1_mod_2_pol])
  filter_2.set_mode(signals[source_filter_2_mode])
  filter_2.set_cutoff(signals[source_filter_2_cutoff])
  filter_2.set_resonance(signals[source_filter_2_resonance])
  filter_2.set_gain_1(signals[source_filter_2_gain_1])
  filter_2.set_gain_2(signals[source_filter_2_gain_2])
  filter_2.set_pitch_amount(signals[source_filter_2_pitch_amt])
  filter_2.set_pitch_polarity(signals[source_filter_2_pitch_pol])
  filter_2.set_modulation_1_amount(signals[source_filter_2_mod_1_amt])
  filter_2.set_modulation_1_polarity(signals[source_filter_2_mod_1_pol])
  filter_2.set_modulation_2_amount(signals[source_filter_2_mod_2_amt])
  filter_2.set_modulation_2_polarity(signals[source_filter_2_mod_2_pol])
  amp_1.set_gain_1(signals[source_amp_1_gain_1])
  amp_1.set_gain_2(signals[source_amp_1_gain_2])
  amp_1.set_modulation_mix(signals[source_amp_1_mod_1_2_mix])
  chorus_1.set_mix(signals[source_chorus_1_mix])
  chorus_1.set_rate(signals[source_chorus_1_rate])
  chorus_1.set_depth(signals[source_chorus_1_depth])
  delay_1.set_mix(signals[source_delay_1_mix])
  delay_1.set_time(signals[source_delay_1_time])
  delay_1.set_feedback(signals[source_delay_1_feedback])
  amp_1.set_limiter_switch(signals[source_amp_1_limiter_sw])
  filter_1.set_drive(signals[source_filter_1_drive])
  filter_2.set_drive(signals[source_filter_2_drive])
  0.0
end
# patch_gen end

# while rather than loop: Spinel builds a loop block with a setjmp, for the StopIteration that ends
# one, which makes every local written inside it volatile, so that the per-sample code would load
# and store each of them, slot and i included, at every use: about 6% of all instructions.
while true
  C.start_debug_measure

  signals[SIGNAL_NOTE_PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[SIGNAL_NOTE_GATE]  = C.get_midi_note_on_state(MIDI_CH).to_f
  # Pitch bend arrives 14-bit and signed, -8192 to 8191, so a whole turn of the wheel is one unit
  # and half of it lands where the pitch domain's own half does. The count of steps is even, so
  # the middle of the range falls between -1 and 0 rather than on a value. Pairing the steps off
  # in the integers first puts -1 and 0 on the same one, which costs half the resolution -- 8193
  # steps, still far under a cent at any usable bend range -- and buys a center that is exactly
  # zero with both ends exactly on -0.5 and +0.5. The division must floor for the bottom end to
  # land: Integer#/ does, and Spinel's sp_idiv implements it.
  signals[SIGNAL_PITCH_BEND]  = ((C.get_midi_pitch_bend(MIDI_CH) + 1) / 2).to_f * (1.0 / 8192.0)

  # The output fader: where a fade ends, the next one is picked. The output silent, a Save that
  # waited for it is done (below), and the fade in starts once the hold is over, unless Mute holds
  # the output silent.
  if C.get_midi_mute_count(MIDI_CH) != mute_count
    mute_count = C.get_midi_mute_count(MIDI_CH)
    mute_waiting = true
  end
  if C.get_midi_save_count(MIDI_CH) != save_count
    save_count = C.get_midi_save_count(MIDI_CH)
    save_waiting = true
  end
  muted = C.get_midi_mute(MIDI_CH) != 0
  saving = false
  if output_fade_position == 0
    mute_waiting = false
    saving = save_waiting
    save_waiting = false
    output_hold_buffers -= (output_hold_buffers > 0) ? 1 : 0
    output_fade_direction = (!muted && !saving && output_hold_buffers == 0) ? 1 : 0
  elsif output_fade_position == OUTPUT_FADE_SAMPLES && (muted || mute_waiting || save_waiting)
    output_fade_direction = -1
    output_hold_buffers = OUTPUT_HOLD_BUFFERS
  elsif output_fade_position == OUTPUT_FADE_SAMPLES
    output_fade_direction = 0
  end
  output_gain = output_fade_position.to_f / OUTPUT_FADE_SAMPLES.to_f
  output_gain_step = output_fade_direction.to_f * OUTPUT_FADE_STEP

  # The patch, read back from the NRPN table. The run order is packed from the front with no
  # gaps; every source_* holds a SIGNAL_* bus slot, or a parameter's own SLOT_*.
  slot = 0
  while slot < MODULES_SIZE
    C.set_active_module(slot, C.get_midi_nrpn_value(MIDI_CH, NRPN_ACTIVE_MODULE_BASE + slot))
    slot += 1
  end
  # The order up to the first MODULE_NONE, with when each of its slots was written.
  listed_count = 0
  while listed_count < MODULES_SIZE && C.get_active_module(listed_count) != MODULE_NONE
    order_written[listed_count] = C.get_midi_run_order_written(MIDI_CH, listed_count)
    winning_slot[C.get_active_module(listed_count)] = -1
    listed_count += 1
  end
  # A module listed twice would run twice a sample -- an LFO at twice its rate, a filter taking
  # two steps -- so it runs once, at the slot written last, and its other slots are dropped. Last
  # in time rather than in place, so that a module written to a slot ahead of where it was moves
  # there, as one written to a slot after it does. On a tie, never written alike, the later slot.
  slot = 0
  while slot < listed_count
    module_id = C.get_active_module(slot)
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
    module_id = C.get_active_module(slot)
    if winning_slot[module_id] == slot
      C.set_active_module(active_count, module_id)
      active_count += 1
    end
    slot += 1
  end

  # What feeds each module input, a bus slot. Written by patch_gen from the inputs of
  # spms1_patch.yaml. The inputs are read per sample and not smoothed: one that takes a controller
  # slot reads its smoothed copy instead (see SIGNALS_SIZE), but for a gate input.
  # patch_gen sources
  source_pitch_1_pitch_in = C.get_midi_nrpn_value(0, 128) # NRPN_SOURCE_PITCH_1_PITCH_IN
  source_pitch_1_pitch_in += ((source_pitch_1_pitch_in - 8) | (41 - source_pitch_1_pitch_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_pitch_1_gate_in = C.get_midi_nrpn_value(0, 129) # NRPN_SOURCE_PITCH_1_GATE_IN
  source_pitch_1_bend_in = C.get_midi_nrpn_value(0, 130) # NRPN_SOURCE_PITCH_1_BEND_IN
  source_pitch_1_bend_in += ((source_pitch_1_bend_in - 8) | (41 - source_pitch_1_bend_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_eg_1_gate_in = C.get_midi_nrpn_value(0, 131) # NRPN_SOURCE_EG_1_GATE_IN
  source_eg_2_gate_in = C.get_midi_nrpn_value(0, 132) # NRPN_SOURCE_EG_2_GATE_IN
  source_lfo_1_rate_mod_in = C.get_midi_nrpn_value(0, 133) # NRPN_SOURCE_LFO_1_RATE_MOD_IN
  source_lfo_1_rate_mod_in += ((source_lfo_1_rate_mod_in - 8) | (41 - source_lfo_1_rate_mod_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_lfo_1_level_mod_in = C.get_midi_nrpn_value(0, 134) # NRPN_SOURCE_LFO_1_LEVEL_MOD_IN
  source_lfo_1_level_mod_in += ((source_lfo_1_level_mod_in - 8) | (41 - source_lfo_1_level_mod_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_lfo_1_reset_in = C.get_midi_nrpn_value(0, 135) # NRPN_SOURCE_LFO_1_RESET_IN
  source_mixer_1_in_1 = C.get_midi_nrpn_value(0, 136) # NRPN_SOURCE_MIXER_1_IN_1
  source_mixer_1_in_1 += ((source_mixer_1_in_1 - 8) | (41 - source_mixer_1_in_1)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_1_in_2 = C.get_midi_nrpn_value(0, 137) # NRPN_SOURCE_MIXER_1_IN_2
  source_mixer_1_in_2 += ((source_mixer_1_in_2 - 8) | (41 - source_mixer_1_in_2)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_1_in_3 = C.get_midi_nrpn_value(0, 138) # NRPN_SOURCE_MIXER_1_IN_3
  source_mixer_1_in_3 += ((source_mixer_1_in_3 - 8) | (41 - source_mixer_1_in_3)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_1_in_4 = C.get_midi_nrpn_value(0, 139) # NRPN_SOURCE_MIXER_1_IN_4
  source_mixer_1_in_4 += ((source_mixer_1_in_4 - 8) | (41 - source_mixer_1_in_4)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_1_pitch_in = C.get_midi_nrpn_value(0, 140) # NRPN_SOURCE_OSC_1_PITCH_IN
  source_osc_1_pitch_in += ((source_osc_1_pitch_in - 8) | (41 - source_osc_1_pitch_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_1_pitch_mod_1_in = C.get_midi_nrpn_value(0, 141) # NRPN_SOURCE_OSC_1_PITCH_MOD_1_IN
  source_osc_1_pitch_mod_1_in += ((source_osc_1_pitch_mod_1_in - 8) | (41 - source_osc_1_pitch_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_1_pitch_mod_2_in = C.get_midi_nrpn_value(0, 142) # NRPN_SOURCE_OSC_1_PITCH_MOD_2_IN
  source_osc_1_pitch_mod_2_in += ((source_osc_1_pitch_mod_2_in - 8) | (41 - source_osc_1_pitch_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_1_pw_mod_1_in = C.get_midi_nrpn_value(0, 143) # NRPN_SOURCE_OSC_1_PW_MOD_1_IN
  source_osc_1_pw_mod_1_in += ((source_osc_1_pw_mod_1_in - 8) | (41 - source_osc_1_pw_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_1_pw_mod_2_in = C.get_midi_nrpn_value(0, 144) # NRPN_SOURCE_OSC_1_PW_MOD_2_IN
  source_osc_1_pw_mod_2_in += ((source_osc_1_pw_mod_2_in - 8) | (41 - source_osc_1_pw_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_pitch_in = C.get_midi_nrpn_value(0, 145) # NRPN_SOURCE_OSC_2_PITCH_IN
  source_osc_2_pitch_in += ((source_osc_2_pitch_in - 8) | (41 - source_osc_2_pitch_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_pitch_mod_1_in = C.get_midi_nrpn_value(0, 146) # NRPN_SOURCE_OSC_2_PITCH_MOD_1_IN
  source_osc_2_pitch_mod_1_in += ((source_osc_2_pitch_mod_1_in - 8) | (41 - source_osc_2_pitch_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_pitch_mod_2_in = C.get_midi_nrpn_value(0, 147) # NRPN_SOURCE_OSC_2_PITCH_MOD_2_IN
  source_osc_2_pitch_mod_2_in += ((source_osc_2_pitch_mod_2_in - 8) | (41 - source_osc_2_pitch_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_pw_mod_1_in = C.get_midi_nrpn_value(0, 148) # NRPN_SOURCE_OSC_2_PW_MOD_1_IN
  source_osc_2_pw_mod_1_in += ((source_osc_2_pw_mod_1_in - 8) | (41 - source_osc_2_pw_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_pw_mod_2_in = C.get_midi_nrpn_value(0, 149) # NRPN_SOURCE_OSC_2_PW_MOD_2_IN
  source_osc_2_pw_mod_2_in += ((source_osc_2_pw_mod_2_in - 8) | (41 - source_osc_2_pw_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_osc_2_sync_in = C.get_midi_nrpn_value(0, 150) # NRPN_SOURCE_OSC_2_SYNC_IN
  source_mixer_2_in_1 = C.get_midi_nrpn_value(0, 151) # NRPN_SOURCE_MIXER_2_IN_1
  source_mixer_2_in_1 += ((source_mixer_2_in_1 - 8) | (41 - source_mixer_2_in_1)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_2_in_2 = C.get_midi_nrpn_value(0, 152) # NRPN_SOURCE_MIXER_2_IN_2
  source_mixer_2_in_2 += ((source_mixer_2_in_2 - 8) | (41 - source_mixer_2_in_2)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_2_in_3 = C.get_midi_nrpn_value(0, 153) # NRPN_SOURCE_MIXER_2_IN_3
  source_mixer_2_in_3 += ((source_mixer_2_in_3 - 8) | (41 - source_mixer_2_in_3)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_mixer_2_in_4 = C.get_midi_nrpn_value(0, 154) # NRPN_SOURCE_MIXER_2_IN_4
  source_mixer_2_in_4 += ((source_mixer_2_in_4 - 8) | (41 - source_mixer_2_in_4)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_1_audio_in_1 = C.get_midi_nrpn_value(0, 155) # NRPN_SOURCE_FILTER_1_AUDIO_IN_1
  source_filter_1_audio_in_1 += ((source_filter_1_audio_in_1 - 8) | (41 - source_filter_1_audio_in_1)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_1_audio_in_2 = C.get_midi_nrpn_value(0, 156) # NRPN_SOURCE_FILTER_1_AUDIO_IN_2
  source_filter_1_audio_in_2 += ((source_filter_1_audio_in_2 - 8) | (41 - source_filter_1_audio_in_2)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_1_pitch_in = C.get_midi_nrpn_value(0, 157) # NRPN_SOURCE_FILTER_1_PITCH_IN
  source_filter_1_pitch_in += ((source_filter_1_pitch_in - 8) | (41 - source_filter_1_pitch_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_1_mod_1_in = C.get_midi_nrpn_value(0, 158) # NRPN_SOURCE_FILTER_1_MOD_1_IN
  source_filter_1_mod_1_in += ((source_filter_1_mod_1_in - 8) | (41 - source_filter_1_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_1_mod_2_in = C.get_midi_nrpn_value(0, 159) # NRPN_SOURCE_FILTER_1_MOD_2_IN
  source_filter_1_mod_2_in += ((source_filter_1_mod_2_in - 8) | (41 - source_filter_1_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_2_audio_in_1 = C.get_midi_nrpn_value(0, 160) # NRPN_SOURCE_FILTER_2_AUDIO_IN_1
  source_filter_2_audio_in_1 += ((source_filter_2_audio_in_1 - 8) | (41 - source_filter_2_audio_in_1)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_2_audio_in_2 = C.get_midi_nrpn_value(0, 161) # NRPN_SOURCE_FILTER_2_AUDIO_IN_2
  source_filter_2_audio_in_2 += ((source_filter_2_audio_in_2 - 8) | (41 - source_filter_2_audio_in_2)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_2_pitch_in = C.get_midi_nrpn_value(0, 162) # NRPN_SOURCE_FILTER_2_PITCH_IN
  source_filter_2_pitch_in += ((source_filter_2_pitch_in - 8) | (41 - source_filter_2_pitch_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_2_mod_1_in = C.get_midi_nrpn_value(0, 163) # NRPN_SOURCE_FILTER_2_MOD_1_IN
  source_filter_2_mod_1_in += ((source_filter_2_mod_1_in - 8) | (41 - source_filter_2_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_filter_2_mod_2_in = C.get_midi_nrpn_value(0, 164) # NRPN_SOURCE_FILTER_2_MOD_2_IN
  source_filter_2_mod_2_in += ((source_filter_2_mod_2_in - 8) | (41 - source_filter_2_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_amp_1_audio_in_1 = C.get_midi_nrpn_value(0, 165) # NRPN_SOURCE_AMP_1_AUDIO_IN_1
  source_amp_1_audio_in_1 += ((source_amp_1_audio_in_1 - 8) | (41 - source_amp_1_audio_in_1)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_amp_1_audio_in_2 = C.get_midi_nrpn_value(0, 166) # NRPN_SOURCE_AMP_1_AUDIO_IN_2
  source_amp_1_audio_in_2 += ((source_amp_1_audio_in_2 - 8) | (41 - source_amp_1_audio_in_2)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_amp_1_mod_1_in = C.get_midi_nrpn_value(0, 167) # NRPN_SOURCE_AMP_1_MOD_1_IN
  source_amp_1_mod_1_in += ((source_amp_1_mod_1_in - 8) | (41 - source_amp_1_mod_1_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_amp_1_mod_2_in = C.get_midi_nrpn_value(0, 168) # NRPN_SOURCE_AMP_1_MOD_2_IN
  source_amp_1_mod_2_in += ((source_amp_1_mod_2_in - 8) | (41 - source_amp_1_mod_2_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_chorus_1_audio_in = C.get_midi_nrpn_value(0, 169) # NRPN_SOURCE_CHORUS_1_AUDIO_IN
  source_chorus_1_audio_in += ((source_chorus_1_audio_in - 8) | (41 - source_chorus_1_audio_in)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_delay_1_audio_in_l = C.get_midi_nrpn_value(0, 170) # NRPN_SOURCE_DELAY_1_AUDIO_IN_L
  source_delay_1_audio_in_l += ((source_delay_1_audio_in_l - 8) | (41 - source_delay_1_audio_in_l)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_delay_1_audio_in_r = C.get_midi_nrpn_value(0, 171) # NRPN_SOURCE_DELAY_1_AUDIO_IN_R
  source_delay_1_audio_in_r += ((source_delay_1_audio_in_r - 8) | (41 - source_delay_1_audio_in_r)) >= 0 ? 466 : 0 # CONTROLLER_SLOT_FIRST, CONTROLLER_SLOT_LAST, SMOOTHED_SLOT_OFFSET
  source_output_l = C.get_midi_nrpn_value(0, 172) # NRPN_SOURCE_OUTPUT_L
  source_output_r = C.get_midi_nrpn_value(0, 173) # NRPN_SOURCE_OUTPUT_R
  # patch_gen end

  # The parameters and the controller slots, once per buffer (see spms1_apply_parameters).
  # patch_gen apply
  spms1_apply_parameters(signals, pitch_1, eg_1, eg_2, lfo_1, mixer_1, osc_1, osc_2, noise_1, mixer_2, filter_1, filter_2, amp_1, chorus_1, delay_1)
  # patch_gen end
  i = 0
  while i < AUDIO_BUFFER_WORDS
    # The control tick, every module's cue for its control-rate update, once every 4 samples
    # (CONTROL_RATE_DIVISOR in each module). Taken here once a sample rather than counted by each
    # module: a counter in each module would cost an add, a mask and a load and store of an
    # instance variable a sample, about 6% of the buffer by the emulated estimate. The buffer is a multiple of 4 samples, so the tick keeps its phase across buffers,
    # and every module ticks on the same samples, whenever it joined the run order.
    control_tick = (i & 3) == 0
    # The smoothing of the parameters that scale no audio, every module's that has them, once every
    # 16 samples whatever runs, so that it costs the same for any patch (see smooth_parameters).
    if (i & 15) == 0
      # patch_gen smoothing
      pitch_1.smooth_parameters
      lfo_1.smooth_parameters
      osc_1.smooth_parameters
      osc_2.smooth_parameters
      filter_1.smooth_parameters
      filter_2.smooth_parameters
      chorus_1.smooth_parameters
      delay_1.smooth_parameters
      # patch_gen end
    end
    slot = 0
    while slot < active_count
      module_id = C.get_active_module(slot)

      # Spinel emits the case as a C switch over the literal ids, which GCC compiles to a jump
      # table, so the dispatch costs the same whichever module it lands on and wherever that sits
      # in the run order.
      #
      # The ids are literals, each with its constant's name after it, and so are the bus slots the
      # outputs go to; patch_gen writes the whole dispatch from spms1_patch.yaml, a `when` for each
      # module calling its `process`, or the `method` the YAML names in its place, with the inputs
      # the YAML names. Spinel emits an Integer constant as a runtime global, so `when MODULE_LFO_1`
      # would load its address and then its value, and `signals[SIGNAL_...]` would too before every
      # write; a literal is an immediate. Literal ids save about a tenth of the instructions of a
      # buffer of the default patch, and literal slots with active_count above about another 4%
      # (emulated Cortex-M33).
      case module_id
      # patch_gen dispatch
      when 1 # MODULE_PITCH_1
        signals[42] = pitch_1.process(control_tick, signals[source_pitch_1_pitch_in], signals[source_pitch_1_gate_in], signals[source_pitch_1_bend_in]) # SIGNAL_PITCH_1_OUTPUT_1
        signals[43] = pitch_1.output_2 # SIGNAL_PITCH_1_OUTPUT_2
      when 2 # MODULE_EG_1
        signals[44] = eg_1.process(control_tick, signals[source_eg_1_gate_in]) # SIGNAL_EG_1_OUTPUT
        signals[45] = eg_1.output_inverted # SIGNAL_EG_1_OUTPUT_INV
      when 3 # MODULE_EG_2
        signals[46] = eg_2.process(control_tick, signals[source_eg_2_gate_in]) # SIGNAL_EG_2_OUTPUT
        signals[47] = eg_2.output_inverted # SIGNAL_EG_2_OUTPUT_INV
      when 4 # MODULE_LFO_1
        signals[48] = lfo_1.process(control_tick, signals[source_lfo_1_rate_mod_in], signals[source_lfo_1_level_mod_in], signals[source_lfo_1_reset_in]) # SIGNAL_LFO_1_OUTPUT
        signals[49] = lfo_1.output_inverted # SIGNAL_LFO_1_OUTPUT_INV
        signals[50] = lfo_1.output_triangle # SIGNAL_LFO_1_OUTPUT_TRIANGLE
        signals[51] = lfo_1.output_triangle_inverted # SIGNAL_LFO_1_OUTPUT_TRIANGLE_INV
        signals[52] = lfo_1.output_square # SIGNAL_LFO_1_OUTPUT_SQUARE
        signals[53] = lfo_1.output_square_inverted # SIGNAL_LFO_1_OUTPUT_SQUARE_INV
      when 5 # MODULE_MIXER_1
        signals[54] = mixer_1.process(control_tick, signals[source_mixer_1_in_1], signals[source_mixer_1_in_2], signals[source_mixer_1_in_3], signals[source_mixer_1_in_4]) # SIGNAL_MIXER_1_OUTPUT
        signals[55] = mixer_1.output_inverted # SIGNAL_MIXER_1_OUTPUT_INV
      when 6 # MODULE_OSC_1
        signals[56] = osc_1.process(control_tick, signals[source_osc_1_pitch_in], signals[source_osc_1_pitch_mod_1_in], signals[source_osc_1_pitch_mod_2_in], signals[source_osc_1_pw_mod_1_in], signals[source_osc_1_pw_mod_2_in]) # SIGNAL_OSC_1_OUTPUT
        signals[57] = osc_1.output_saw # SIGNAL_OSC_1_OUTPUT_SAW
        signals[58] = osc_1.output_pulse # SIGNAL_OSC_1_OUTPUT_PULSE
        signals[59] = osc_1.output_sub # SIGNAL_OSC_1_OUTPUT_SUB
      when 7 # MODULE_OSC_2
        signals[60] = osc_2.process_synced(control_tick, signals[source_osc_2_pitch_in], signals[source_osc_2_pitch_mod_1_in], signals[source_osc_2_pitch_mod_2_in], signals[source_osc_2_pw_mod_1_in], signals[source_osc_2_pw_mod_2_in], signals[source_osc_2_sync_in]) # SIGNAL_OSC_2_OUTPUT
        signals[61] = osc_2.output_saw # SIGNAL_OSC_2_OUTPUT_SAW
        signals[62] = osc_2.output_pulse # SIGNAL_OSC_2_OUTPUT_PULSE
      when 8 # MODULE_NOISE_1
        signals[63] = noise_1.process(control_tick) # SIGNAL_NOISE_1_OUTPUT
        signals[64] = noise_1.output_white # SIGNAL_NOISE_1_OUTPUT_WHITE
        signals[65] = noise_1.output_red # SIGNAL_NOISE_1_OUTPUT_RED
      when 9 # MODULE_MIXER_2
        signals[66] = mixer_2.process(control_tick, signals[source_mixer_2_in_1], signals[source_mixer_2_in_2], signals[source_mixer_2_in_3], signals[source_mixer_2_in_4]) # SIGNAL_MIXER_2_OUTPUT
        signals[67] = mixer_2.output_inverted # SIGNAL_MIXER_2_OUTPUT_INV
      when 10 # MODULE_FILTER_1
        signals[68] = filter_1.process(control_tick, signals[source_filter_1_audio_in_1], signals[source_filter_1_audio_in_2], signals[source_filter_1_pitch_in], signals[source_filter_1_mod_1_in], signals[source_filter_1_mod_2_in]) # SIGNAL_FILTER_1_OUTPUT
        signals[69] = filter_1.output_lp # SIGNAL_FILTER_1_OUTPUT_LP
        signals[70] = filter_1.output_hp # SIGNAL_FILTER_1_OUTPUT_HP
        signals[71] = filter_1.output_bp # SIGNAL_FILTER_1_OUTPUT_BP
      when 11 # MODULE_FILTER_2
        signals[72] = filter_2.process(control_tick, signals[source_filter_2_audio_in_1], signals[source_filter_2_audio_in_2], signals[source_filter_2_pitch_in], signals[source_filter_2_mod_1_in], signals[source_filter_2_mod_2_in]) # SIGNAL_FILTER_2_OUTPUT
        signals[73] = filter_2.output_lp # SIGNAL_FILTER_2_OUTPUT_LP
        signals[74] = filter_2.output_hp # SIGNAL_FILTER_2_OUTPUT_HP
        signals[75] = filter_2.output_bp # SIGNAL_FILTER_2_OUTPUT_BP
      when 12 # MODULE_AMP_1
        signals[76] = amp_1.process(control_tick, signals[source_amp_1_audio_in_1], signals[source_amp_1_audio_in_2], signals[source_amp_1_mod_1_in], signals[source_amp_1_mod_2_in]) # SIGNAL_AMP_1_OUTPUT
      when 13 # MODULE_CHORUS_1
        chorus_1.process(control_tick, signals[source_chorus_1_audio_in])
        signals[77] = chorus_1.output_l # SIGNAL_CHORUS_1_OUTPUT_L
        signals[78] = chorus_1.output_r # SIGNAL_CHORUS_1_OUTPUT_R
        signals[79] = chorus_1.output_mono # SIGNAL_CHORUS_1_OUTPUT_MONO
      when 14 # MODULE_DELAY_1
        delay_1.process(control_tick, signals[source_delay_1_audio_in_l], signals[source_delay_1_audio_in_r])
        signals[80] = delay_1.output_l # SIGNAL_DELAY_1_OUTPUT_L
        signals[81] = delay_1.output_r # SIGNAL_DELAY_1_OUTPUT_R
        signals[82] = delay_1.output_mono # SIGNAL_DELAY_1_OUTPUT_MONO
      # patch_gen end
      end

      slot += 1
    end

    audio_buffer_l[i] = signals[source_output_l] * output_gain
    audio_buffer_r[i] = signals[source_output_r] * output_gain
    output_gain += output_gain_step
    i += 1
  end

  output_fade_position += output_fade_direction * AUDIO_BUFFER_WORDS

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer_l[i], audio_buffer_r[i])
  end

  # A Save, with the output silent; the output is held silent as long again after it.
  if saving
    C.store_patch_image(MIDI_CH)
    output_hold_buffers = OUTPUT_HOLD_BUFFERS
  end
end
