/* The reads of the MIDI state that the per-buffer code of SPMS-1 (type-2) makes for every
   parameter (a CC value, and an NRPN entry: which CC, and the value without one), as inline
   functions, so that each is a load rather than a call; spinel_rt_mcu_cold.h includes this for
   spms1_main.c, ahead of its extern declarations of them (as spms1_bus.h), and spms1_midi_state.h,
   which defines the arrays, for the sketch and the hosts. */
#ifndef SPMS1_MIDI_READ_H
#define SPMS1_MIDI_READ_H

#include <stdint.h>

#define SPMS1_NRPN_SIZE (640)

extern uint8_t g_midi_cc_values[16][128];
extern uint8_t g_midi_nrpn_values[16][SPMS1_NRPN_SIZE];

static inline uint8_t get_midi_cc_value(uint8_t midi_ch, uint8_t cc_number) {
  if ((midi_ch >= 16) || (cc_number >= 128)) {
    return 0;
  }
  return g_midi_cc_values[midi_ch][cc_number];
}

static inline uint8_t get_midi_nrpn_value(uint8_t midi_ch, int32_t index) {
  if ((midi_ch >= 16) || (index < 0) || (index >= SPMS1_NRPN_SIZE)) {
    return 0;
  }
  return g_midi_nrpn_values[midi_ch][index];
}

#endif /* SPMS1_MIDI_READ_H */
