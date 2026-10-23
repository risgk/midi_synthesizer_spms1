/* The signal bus of SPMS-1 (type-2): the slots SignalBus (spms1_framework.rb) reads and writes,
   as a plain C array. spms1_main.c declares get_bus_signal and set_bus_signal extern, as it does
   every Spms1::C function, after spinel_rt.h, which includes this through
   spinel_rt_mcu_cold.h; a static definition ahead of an extern declaration keeps its internal
   linkage, so the two inline into the per-sample code as a load and a store. The slot is masked
   to the array, which SIGNALS_SIZE in spms1_main.rb matches, so no slot can reach past it,
   whatever is routed. */
#ifndef SPMS1_BUS_H
#define SPMS1_BUS_H

#include <stdint.h>

#define SPMS1_BUS_SIZE 256

static float spms1_bus_signals[SPMS1_BUS_SIZE];

static inline float get_bus_signal(int32_t slot) {
  return spms1_bus_signals[slot & (SPMS1_BUS_SIZE - 1)];
}

static inline void set_bus_signal(int32_t slot, float value) {
  spms1_bus_signals[slot & (SPMS1_BUS_SIZE - 1)] = value;
}

#endif /* SPMS1_BUS_H */
