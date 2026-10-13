/*
 * MIDI Synthesizer SPMS-1 (type-2): the MIDI state the synth reads through ffi_func, and the
 * handlers that fill it
 *
 * Included once per program, by spms1_type2.ino (inside its extern "C") and by the hosts that stand
 * in for it: sim_spinel, sim_render and web. They all keep the MIDI the same way, so a change here
 * reaches the device and every simulator at once. sim_cruby keeps its own copy, in Ruby.
 *
 * Plain C, so that it compiles as C++ in the sketch as well.
 */
#ifndef SPMS1_MIDI_STATE_H
#define SPMS1_MIDI_STATE_H

#include <stdint.h>

uint8_t  g_midi_note_on_pitch[16]  = {60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60};
uint8_t  g_midi_note_on_state[16]  = {0};
uint8_t  g_midi_cc_values[16][128] = {{0}};
// Pitch bend arrives 14-bit and centred, and the MIDI library hands it over already signed,
// so it is kept that way rather than folded into the 7-bit tables above.
int16_t  g_midi_pitch_bend[16]     = {0};

// NRPN parameter numbers are (MSB << 7) | LSB; the synth uses MSB 0-3 as categories, so 512
// entries cover it. Values are 7-bit, filled from CC 6.
#define SPMS1_NRPN_SIZE (512)
uint8_t  g_midi_nrpn_values[16][SPMS1_NRPN_SIZE] = {{0}};
uint8_t  g_midi_nrpn_msb[16]            = {0};
uint8_t  g_midi_nrpn_lsb[16]            = {0};
uint8_t  g_midi_nrpn_selected[16]       = {0};  // 0 until CC 99 or 98 arrives, and again after an RPN

void set_midi_note_on_pitch(uint8_t midi_ch, uint8_t midi_note_on_pitch) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_pitch[midi_ch] = midi_note_on_pitch;
}

uint8_t get_midi_note_on_pitch(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_pitch[midi_ch];
}

void set_midi_note_on_state(uint8_t midi_ch, uint8_t midi_note_on_state) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_state[midi_ch] = midi_note_on_state;
}

uint8_t get_midi_note_on_state(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_state[midi_ch];
}

void set_midi_pitch_bend(uint8_t midi_ch, int32_t midi_pitch_bend) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_pitch_bend[midi_ch] = (int16_t)midi_pitch_bend;
}

int32_t get_midi_pitch_bend(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_pitch_bend[midi_ch];
}

void set_midi_cc_value(uint8_t midi_ch, uint8_t cc_number, uint8_t cc_value) {
  if (midi_ch >= 16) {
    return;
  }

  if (cc_number >= 128) {
    return;
  }

  g_midi_cc_values[midi_ch][cc_number] = cc_value;
}

uint8_t get_midi_cc_value(uint8_t midi_ch, uint8_t cc_number) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (cc_number >= 128) {
    return 0;
  }

  return g_midi_cc_values[midi_ch][cc_number];
}

void set_midi_nrpn_value(uint8_t midi_ch, int32_t index, uint8_t value) {
  if (midi_ch >= 16) {
    return;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return;
  }

  g_midi_nrpn_values[midi_ch][index] = value;
}

uint8_t get_midi_nrpn_value(uint8_t midi_ch, int32_t index) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return 0;
  }

  return g_midi_nrpn_values[midi_ch][index];
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
    set_midi_nrpn_value(midi_ch, (((int32_t)g_midi_nrpn_msb[midi_ch]) << 7) | g_midi_nrpn_lsb[midi_ch], value);
  }
}

// The handlers, by 0-based channel. A note off closes the gate only for the pitch that last came
// on, and a note on at velocity 0 is a note off, as the MIDI library the sketch uses treats it.
void spms1_handle_note_off(uint8_t midi_ch, uint8_t pitch) {
  if (midi_ch >= 16) {
    return;
  }

  if (pitch == g_midi_note_on_pitch[midi_ch]) {
    set_midi_note_on_state(midi_ch, 0);
  }
}

void spms1_handle_note_on(uint8_t midi_ch, uint8_t pitch, uint8_t velocity) {
  if (velocity == 0) {
    spms1_handle_note_off(midi_ch, pitch);
    return;
  }

  set_midi_note_on_pitch(midi_ch, pitch);
  set_midi_note_on_state(midi_ch, 1);
}

void spms1_handle_control_change(uint8_t midi_ch, uint8_t number, uint8_t value) {
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
