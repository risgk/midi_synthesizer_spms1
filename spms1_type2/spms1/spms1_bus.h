/* The signal bus of SPMS-1 (type-2): the slots SignalBus (spms1_framework.rb) reads and writes,
   as a plain C array. spms1_main.c declares get_bus_signal and set_bus_signal extern, as it does
   every Spms1::C function, after spinel_rt.h, which includes this through
   spinel_rt_mcu_cold.h; a static definition ahead of an extern declaration keeps its internal
   linkage, so the two inline into the per-sample code as a load and a store. The array is
   SIGNALS_SIZE in spms1_main.rb. A write is masked to it, so no write can reach past it, which
   costs nothing as every slot written is a literal. A read is not: the per-sample code makes about
   60 a sample, each an instruction more with the mask (about 16 us a buffer), and every slot read
   is in the array as it is: a literal, or a source the per-buffer code makes from an NRPN value,
   a byte (0 to 255), with SMOOTHED_SLOT_OFFSET added only to a controller slot (up to 41 + 466 =
   507), or a parameter's own slot (128 + its entry, up to 255). A read made otherwise has to keep
   to the array itself. */
#ifndef SPMS1_BUS_H
#define SPMS1_BUS_H

#include <stdint.h>

#define SPMS1_BUS_SIZE 512

static float spms1_bus_signals[SPMS1_BUS_SIZE];

static inline float get_bus_signal(int32_t slot) {
  return spms1_bus_signals[slot];
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
