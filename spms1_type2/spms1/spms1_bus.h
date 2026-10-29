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

#define SPMS1_BUS_SIZE 512

static float spms1_bus_signals[SPMS1_BUS_SIZE];

static inline float get_bus_signal(int32_t slot) {
  return spms1_bus_signals[slot & (SPMS1_BUS_SIZE - 1)];
}

static inline void set_bus_signal(int32_t slot, float value) {
  spms1_bus_signals[slot & (SPMS1_BUS_SIZE - 1)] = value;
}

/* The run order of the modules, by slot, as a plain C array for the same reason: the per-sample
   dispatch reads a slot for every module it runs. The slot is masked to the array, which
   MODULES_SIZE in spms1_main.rb matches. */
#define SPMS1_ACTIVE_MODULES_SIZE 32

static int32_t spms1_active_modules[SPMS1_ACTIVE_MODULES_SIZE];

static inline int32_t get_active_module(int32_t slot) {
  return spms1_active_modules[slot & (SPMS1_ACTIVE_MODULES_SIZE - 1)];
}

static inline void set_active_module(int32_t slot, int32_t module_id) {
  spms1_active_modules[slot & (SPMS1_ACTIVE_MODULES_SIZE - 1)] = module_id;
}

#endif /* SPMS1_BUS_H */
