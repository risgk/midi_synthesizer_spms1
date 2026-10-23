# MIDI Synthesizer SPMS-1 (type-2): the framework the synth is built on
#
# What any synth on this base shares, whatever its modules: the functions the host provides
# (Spms1::C, implemented by spms1.ino and by every simulator), and the conversions from MIDI to the
# values the modules take. spms1_main.rb is the loop that runs the patch, and the modules
# (spms1_osc.rb and the rest) are the sound; spms1_development.md's "Adding a Module" says how a
# new one is added, which is a class and its entries in spms1_patch.yaml, with nothing written in
# the loop by hand.
#
# The patch is data: which modules run and in what order, what feeds each module input, where each
# parameter takes its value, and which CC fills each control slot all live in the NRPN table, read
# back every buffer so that MIDI can rewire the synth while it runs. spms1_patching.md lists the
# numbers a controller sends. Two invariants the code leans on:
#
# - Every entry is 7-bit and every 7-bit value is legal, so nothing read back is validated. An
#   unknown module id falls through the dispatch, and any slot number is a real slot because the
#   bus is wider than 127: a parameter source of 127 is read as the parameter's own control slot,
#   which sits above that.
# - Module inputs are read per sample and reach their module unsmoothed; parameters are read once
#   per buffer and are smoothed by the module receiving them. Which of the two a signal arrives
#   through is what decides how fast it is allowed to move.
#
# One rule the code keeps: the worst case of a buffer is guaranteed, not hoped for. No patch, CC or
# note makes a buffer take more work than every module running, which is what is measured, so the
# time measured is the worst time. Every module in the run order runs every sample and every
# parameter is worked out every buffer, whether or not it has moved, never only when it changes;
# branches on values are avoided where they can be (clamps as nested ternaries that compile to
# selects, curves from lookup tables with interpolation rather than library calls such as a square
# root), so that no input takes a slower path than the one measured. A module keeps to it as well:
# spms1_development.md's "Writing a Module" says how.
#
# Claims about the generated C, here and in the rest of the synth, hold for the Spinel version
# vendored in spinel_rt.h. Re-check them on updating it.

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
    ffi_func :get_bus_signal,             [:int32],                  :float
    ffi_func :set_bus_signal,             [:int32, :float],          :void
  end

  # The signal bus, indexed as an Array would be. Its slots are a C array of the host's
  # (spms1_bus.h for the C builds), so that a read or a write is one load or store, where an Array
  # of Spinel's checks the index against its length and its frozen flag at every access, which
  # in the per-sample code was about a fifth of all the instructions.
  class SignalBus
    def [](slot)
      C.get_bus_signal(slot)
    end

    def []=(slot, value)
      C.set_bus_signal(slot, value)
    end
  end
end

# CC value normalization. Each control slot is unipolar or bipolar, matching the range its
# parameter clamps to, and takes the converter of its kind: unipolar is 0.0..1.0, the span of an
# envelope, and bipolar is -0.5..0.5, the span of an LFO, with 0.0 at CC 64 where a MIDI
# controller puts its detent. Pitch Coarse and Pitch Fine are
# bipolar, being offsets about that detent. Both map CC 4..124 to the full range and
# clamp anything outside. Every lookup table in the synth is spaced to match --
# FREQ_TABLE is semitone-spaced across 120, and EXP_TABLE and K_TABLE are 121 entries over their
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

# What a controller's slot, the mod wheel's or a general control's, is filled with. CC number 0 means no CC is assigned, and the slot
# gets 0.0. Selecting the value rather than skipping the write keeps the cost the same whatever the
# patch says.
def cc_or_zero(cc_number, value)
  (cc_number == 0) ? 0.0 : value
end

# sin(u * pi / 2) for each CC step of u, 0.0 at index 0 to 1.0 at index 120, which a controller's
# Sin form reads as it is and its Cos form from the other end; their squares sum to one at every
# step, so two levels taking them crossfade at equal power.
QUARTER_SINE_TABLE = Array.new(122, 0.0)
for i in 0...121
  QUARTER_SINE_TABLE[i] = Math.sin(i.to_f * (Math::PI / 240.0))
end
QUARTER_SINE_TABLE[120] = 1.0
# A guard past the end, for quarter_sine at u = 1.0.
QUARTER_SINE_TABLE[121] = 1.0

# sin(u * pi / 2) for any u in [0.0, 1.0], between the steps of the table in a straight line,
# for the smoothed copies of a controller's Sin and Cos, whose u falls between the CC steps. The
# squares of the pair then sum to one within 0.00002.
def quarter_sine(u)
  x = u * 120.0
  index = x.to_i
  index = (index < 0) ? 0 : ((index > 120) ? 120 : index)
  QUARTER_SINE_TABLE[index] + (QUARTER_SINE_TABLE[index + 1] - QUARTER_SINE_TABLE[index]) * (x - index.to_f)
end

# A controller's CC value as an index of QUARTER_SINE_TABLE, 0 at CC 4 to 120 at CC 124, and 0, as
# u is 0.0, while no CC is assigned.
def cc_table_index(cc_number, value)
  index = value - 4
  index = (index < 0) ? 0 : ((index > 120) ? 120 : index)
  (cc_number == 0) ? 0 : index
end

# The 7-bit value a parameter's control slot is filled from: its CC's while one is assigned, and
# the value NRPN category 4 holds for it while none is. Selected the same way, before the one
# conversion.
def cc_or_nrpn(cc_number, cc_value, nrpn_value)
  (cc_number == 0) ? nrpn_value : cc_value
end

# Where a parameter reads: the bus slot its source names, or, for SIGNAL_OWN, its own control slot.
# 127 is SIGNAL_OWN written out, as Spinel emits a named Integer constant as a runtime global.
def source_or_own(source, own_slot)
  (source == 127) ? own_slot : source
end
