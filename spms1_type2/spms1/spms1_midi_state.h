/*
 * MIDI Synthesizer SPMS-1 (type-2): the MIDI state the synth reads through ffi_func, and the
 * handlers that fill it
 *
 * Included once per program, by spms1.ino (inside its extern "C") and by the hosts that stand
 * in for it: sim_spinel, sim_render and web. They all keep the MIDI the same way, so a change here
 * reaches the device and every simulator at once. sim_cruby keeps its own copy, in Ruby.
 *
 * Plain C, so that it compiles as C++ in the sketch as well.
 */
#ifndef SPMS1_MIDI_STATE_H
#define SPMS1_MIDI_STATE_H

#include <stdint.h>

// Where the accessors the synth calls go. The sketch defines it to put them in RAM, next to the
// synth's own code: in flash they would be fetched through the XIP cache, which core 0's MIDI and
// USB code shares and evicts. The simulators leave it empty.
#ifndef SPMS1_RAM_FUNC
#define SPMS1_RAM_FUNC
#endif

uint8_t  g_midi_note_on_pitch[16]  = {60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60};
uint8_t  g_midi_note_on_state[16]  = {0};
// The note held before the one sounding, which comes back when that one is let go, or
// SPMS1_NO_NOTE. One note is remembered, no more: enough for a trill.
#define SPMS1_NO_NOTE (0xFF)
uint8_t  g_midi_note_prev_pitch[16] = {SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE,
                                       SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE,
                                       SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE,
                                       SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE, SPMS1_NO_NOTE};
uint8_t  g_midi_cc_values[16][128] = {{0}};
// Pitch bend arrives 14-bit and centered, and the MIDI library hands it over already signed,
// so it is kept that way rather than folded into the 7-bit tables above.
int16_t  g_midi_pitch_bend[16]     = {0};

// NRPN parameter numbers are (category << 7) | LSB, where the MSB is 112 (0x70) + category: MSB
// 112-116 for categories 0-4, clear of the NRPNs of GS and XG (MSB 1 and 20-31) and of the low MSBs
// other synths tend to use, so 640 entries cover it. Values are 7-bit, filled from CC 6. MSB 117,
// category 5, has the system entries, which are not kept in the table (see below).
#define SPMS1_NRPN_MSB_BASE (112)
#define SPMS1_NRPN_SIZE (640)
uint8_t  g_midi_nrpn_values[16][SPMS1_NRPN_SIZE] = {{0}};
uint8_t  g_midi_nrpn_msb[16]            = {0};
uint8_t  g_midi_nrpn_lsb[16]            = {0};
uint8_t  g_midi_nrpn_selected[16]       = {0};  // 0 until CC 99 or 98 arrives, and again after an RPN
// When each slot of the run order (NRPN category 0) was last written, as a count of such writes on
// its channel, so the synth can tell which of two slots naming one module was written later: the
// last write wins, wherever its slot is. 0 is a slot never written. The count passes the int32 the
// synth reads it as after 2 billion writes, which no patch editing reaches.
#define SPMS1_RUN_ORDER_SIZE (32)
uint32_t g_midi_run_order_writes[16]                       = {0};
uint32_t g_midi_run_order_written[16][SPMS1_RUN_ORDER_SIZE] = {{0}};

// NRPN category 5 (MSB 117), the system entries, which act rather than hold a part of the patch,
// so they are not kept in the NRPN table and a patch does not include them. Entry 0, Mute, mutes
// the output at 64-127 and unmutes it at 0-63, for while a patch is sent; entry 1, Reset, puts the
// patch back to the default at 64-127, as at power-up (spms1_reset_patch).
#define SPMS1_NRPN_SYSTEM_MSB   (SPMS1_NRPN_MSB_BASE + 5)
#define SPMS1_NRPN_SYSTEM_MUTE  (0)
#define SPMS1_NRPN_SYSTEM_RESET (1)
uint8_t  g_midi_mute[16]            = {0};
// How many All Sound Offs (CC 120) have arrived, which the synth tells apart by the count changing:
// it fades the output out, silences the envelopes and the filter, clears the delay and the
// chorus, and fades it in again.
uint32_t g_midi_sound_off_count[16] = {0};

SPMS1_RAM_FUNC void set_midi_note_on_pitch(uint8_t midi_ch, uint8_t midi_note_on_pitch) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_pitch[midi_ch] = midi_note_on_pitch;
}

SPMS1_RAM_FUNC uint8_t get_midi_note_on_pitch(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_pitch[midi_ch];
}

SPMS1_RAM_FUNC void set_midi_note_on_state(uint8_t midi_ch, uint8_t midi_note_on_state) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_state[midi_ch] = midi_note_on_state;
}

SPMS1_RAM_FUNC uint8_t get_midi_note_on_state(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_state[midi_ch];
}

SPMS1_RAM_FUNC void set_midi_pitch_bend(uint8_t midi_ch, int32_t midi_pitch_bend) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_pitch_bend[midi_ch] = (int16_t)midi_pitch_bend;
}

SPMS1_RAM_FUNC int32_t get_midi_pitch_bend(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_pitch_bend[midi_ch];
}

SPMS1_RAM_FUNC void set_midi_cc_value(uint8_t midi_ch, uint8_t cc_number, uint8_t cc_value) {
  if (midi_ch >= 16) {
    return;
  }

  if (cc_number >= 128) {
    return;
  }

  g_midi_cc_values[midi_ch][cc_number] = cc_value;
}

SPMS1_RAM_FUNC uint8_t get_midi_cc_value(uint8_t midi_ch, uint8_t cc_number) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (cc_number >= 128) {
    return 0;
  }

  return g_midi_cc_values[midi_ch][cc_number];
}

SPMS1_RAM_FUNC void set_midi_nrpn_value(uint8_t midi_ch, int32_t index, uint8_t value) {
  if (midi_ch >= 16) {
    return;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return;
  }

  g_midi_nrpn_values[midi_ch][index] = value;
  if (index < SPMS1_RUN_ORDER_SIZE) {
    g_midi_run_order_written[midi_ch][index] = ++g_midi_run_order_writes[midi_ch];
  }
}

SPMS1_RAM_FUNC uint8_t get_midi_nrpn_value(uint8_t midi_ch, int32_t index) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return 0;
  }

  return g_midi_nrpn_values[midi_ch][index];
}

SPMS1_RAM_FUNC int32_t get_midi_run_order_written(uint8_t midi_ch, int32_t slot) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (slot < 0 || slot >= SPMS1_RUN_ORDER_SIZE) {
    return 0;
  }

  return (int32_t)g_midi_run_order_written[midi_ch][slot];
}

SPMS1_RAM_FUNC uint8_t get_midi_mute(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_mute[midi_ch];
}

SPMS1_RAM_FUNC int32_t get_midi_sound_off_count(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return (int32_t)g_midi_sound_off_count[midi_ch];
}

// The default patch, from spms1_patch.yaml, as spms1_write_default_patch in spms1_patch.rb writes
// it at power-up.
#include "spms1_default_patch.h"

// Puts the NRPN table, the times the run order was written and the CC values back as they are at
// power-up: every entry and CC to 0, and then the default patch and the values its CCs power up at.
// The notes, Pitch Bend, the NRPN selection and Mute are kept. The synth may read the tables while
// they are rewritten, so a reset is sent between Mute and unmute to be heard as silence.
void spms1_reset_patch(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return;
  }

  for (int32_t i = 0; i < SPMS1_NRPN_SIZE; ++i) {
    g_midi_nrpn_values[midi_ch][i] = 0;
  }
  g_midi_run_order_writes[midi_ch] = 0;
  for (int32_t i = 0; i < SPMS1_RUN_ORDER_SIZE; ++i) {
    g_midi_run_order_written[midi_ch][i] = 0;
  }
  for (int32_t i = 0; i < 128; ++i) {
    g_midi_cc_values[midi_ch][i] = 0;
  }

  for (uint32_t i = 0; i < sizeof(g_spms1_default_nrpn) / sizeof(g_spms1_default_nrpn[0]); ++i) {
    set_midi_nrpn_value(midi_ch, g_spms1_default_nrpn[i][0], (uint8_t)g_spms1_default_nrpn[i][1]);
  }
  for (uint32_t i = 0; i < sizeof(g_spms1_default_cc) / sizeof(g_spms1_default_cc[0]); ++i) {
    set_midi_cc_value(midi_ch, g_spms1_default_cc[i][0], g_spms1_default_cc[i][1]);
  }
}

// The system entries of NRPN category 5.
void handle_midi_nrpn_system(uint8_t midi_ch, uint8_t lsb, uint8_t value) {
  if (lsb == SPMS1_NRPN_SYSTEM_MUTE) {
    g_midi_mute[midi_ch] = (value >= 64) ? 1 : 0;
  } else if (lsb == SPMS1_NRPN_SYSTEM_RESET && value >= 64) {
    spms1_reset_patch(midi_ch);
  }
}

// CC 99 and 98 select a parameter, in either order, and CC 6 commits a value to it. CC 38 is
// ignored because every value here is 7-bit, and CC 96/97 are not implemented. CC 101 and 100
// select an RPN instead, which must not leave a following CC 6 looking like NRPN data. The CCs
// are still stored by set_midi_cc_value as well, so a patch may read them as ordinary controls.
void handle_midi_nrpn_cc(uint8_t midi_ch, uint8_t number, uint8_t value) {
  if (midi_ch >= 16) {
    return;
  }

  if (number == 99) {
    g_midi_nrpn_msb[midi_ch] = value;
    g_midi_nrpn_selected[midi_ch] = 1;
  } else if (number == 98) {
    g_midi_nrpn_lsb[midi_ch] = value;
    g_midi_nrpn_selected[midi_ch] = 1;
  } else if (number == 101 || number == 100) {
    g_midi_nrpn_selected[midi_ch] = 0;
  } else if (number == 6 && g_midi_nrpn_selected[midi_ch]) {
    // An MSB below the base, as another device's NRPN, is ignored (set_midi_nrpn_value ignores one
    // past the last category)
    if (g_midi_nrpn_msb[midi_ch] == SPMS1_NRPN_SYSTEM_MSB) {
      handle_midi_nrpn_system(midi_ch, g_midi_nrpn_lsb[midi_ch], value);
    } else if (g_midi_nrpn_msb[midi_ch] >= SPMS1_NRPN_MSB_BASE) {
      set_midi_nrpn_value(midi_ch, (((int32_t)g_midi_nrpn_msb[midi_ch] - SPMS1_NRPN_MSB_BASE) << 7) | g_midi_nrpn_lsb[midi_ch], value);
    }
  }
}

// The handlers, by 0-based channel. A note on remembers the note it takes over from, if that one
// is still held, and a note off of the note sounding brings the remembered one back with the gate
// left open (legato), or closes the gate if there is none. A note off of the remembered note only
// forgets it, and one for any other pitch is ignored. A note on at velocity 0 is a note off, as the
// MIDI library the sketch uses treats it.
void spms1_handle_note_off(uint8_t midi_ch, uint8_t pitch) {
  if (midi_ch >= 16) {
    return;
  }

  if (pitch == g_midi_note_on_pitch[midi_ch]) {
    if (g_midi_note_prev_pitch[midi_ch] != SPMS1_NO_NOTE) {
      set_midi_note_on_pitch(midi_ch, g_midi_note_prev_pitch[midi_ch]);
      g_midi_note_prev_pitch[midi_ch] = SPMS1_NO_NOTE;
    } else {
      set_midi_note_on_state(midi_ch, 0);
    }
  } else if (pitch == g_midi_note_prev_pitch[midi_ch]) {
    g_midi_note_prev_pitch[midi_ch] = SPMS1_NO_NOTE;
  }
}

void spms1_handle_note_on(uint8_t midi_ch, uint8_t pitch, uint8_t velocity) {
  if (velocity == 0) {
    spms1_handle_note_off(midi_ch, pitch);
    return;
  }

  if (midi_ch >= 16) {
    return;
  }

  // The same note again keeps what is remembered.
  if (!g_midi_note_on_state[midi_ch]) {
    g_midi_note_prev_pitch[midi_ch] = SPMS1_NO_NOTE;
  } else if (pitch != g_midi_note_on_pitch[midi_ch]) {
    g_midi_note_prev_pitch[midi_ch] = g_midi_note_on_pitch[midi_ch];
  }

  set_midi_note_on_pitch(midi_ch, pitch);
  set_midi_note_on_state(midi_ch, 1);
}

// The Channel Mode messages, CC 120 to 127, which are not controls and are not stored as CC values.
// All Sound Off (120), All Notes Off (123) and Omni Off, Omni On, Mono On and Poly On (124 to 127),
// which end every note as All Notes Off does, close the gate and forget the remembered note, as a
// note off of every note would: the envelopes release as they do at a note off. All Sound Off
// also has the synth fade the output out, silence the envelopes and the filter and clear the delay
// and the chorus, so that the release is cut short (see g_midi_sound_off_count). Reset All
// Controllers (121) centers Pitch Bend, sets the Modulation Wheel (CC 1) to 0 and leaves no NRPN
// selected, and leaves every other CC as it is, the parameters among them. Local Control (122) has
// no keyboard here to act on.
void spms1_handle_channel_mode(uint8_t midi_ch, uint8_t number) {
  if (midi_ch >= 16) {
    return;
  }

  if (number == 121) {
    set_midi_pitch_bend(midi_ch, 0);
    set_midi_cc_value(midi_ch, 1, 0);
    g_midi_nrpn_selected[midi_ch] = 0;
  } else if (number != 122) {
    g_midi_note_prev_pitch[midi_ch] = SPMS1_NO_NOTE;
    set_midi_note_on_state(midi_ch, 0);
    if (number == 120) {
      ++g_midi_sound_off_count[midi_ch];
    }
  }
}

void spms1_handle_control_change(uint8_t midi_ch, uint8_t number, uint8_t value) {
  if (number >= 120) {
    spms1_handle_channel_mode(midi_ch, number);
    return;
  }
  set_midi_cc_value(midi_ch, number, value);
  handle_midi_nrpn_cc(midi_ch, number, value);
}

// bend: signed, -8192 to 8191
void spms1_handle_pitch_bend(uint8_t midi_ch, int32_t bend) {
  set_midi_pitch_bend(midi_ch, bend);
}

// One whole channel message, for the hosts that have no MIDI library to parse it.
static inline void spms1_handle_midi_message(uint8_t status, uint8_t data_1, uint8_t data_2) {
  uint8_t midi_ch = status & 0x0F;
  switch (status & 0xF0) {
  case 0x80:
    spms1_handle_note_off(midi_ch, data_1);
    break;
  case 0x90:
    spms1_handle_note_on(midi_ch, data_1, data_2);
    break;
  case 0xB0:
    spms1_handle_control_change(midi_ch, data_1, data_2);
    break;
  case 0xE0:
    spms1_handle_pitch_bend(midi_ch, ((((int32_t)data_2) << 7) | data_1) - 8192);
    break;
  }
}

// A byte stream, for the hosts that get raw bytes: running status is resolved here, several
// messages may come in a row, and real-time bytes may arrive anywhere and are skipped, and so is
// SysEx.
static inline void spms1_midi_parse_byte(uint8_t b) {
  static uint8_t s_status = 0;
  static uint8_t s_data[2] = {0, 0};
  static int     s_count = 0;
  static int     s_in_sysex = 0;

  if (b >= 0xF8) {
    return;
  } else if (b == 0xF0) {
    s_in_sysex = 1;
  } else if (b >= 0x80) {
    s_in_sysex = 0;
    s_status = (b < 0xF0) ? b : 0;
    s_count = 0;
  } else if (!s_in_sysex && s_status) {
    int length = ((s_status & 0xE0) == 0xC0) ? 1 : 2;
    s_data[s_count++] = b;
    if (s_count == length) {
      spms1_handle_midi_message(s_status, s_data[0], (length == 2) ? s_data[1] : 0);
      s_count = 0;
    }
  }
}

#endif  // SPMS1_MIDI_STATE_H
