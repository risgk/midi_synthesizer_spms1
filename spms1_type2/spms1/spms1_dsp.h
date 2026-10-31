/* Arithmetic for Dsp (spms1_dsp.rb) that Ruby has no single operation for: the larger and the
   smaller of two Floats, each one instruction on the device (vmaxnm.f32 and vminnm.f32, FPv5), for
   the clamps that otherwise take a subtraction, an abs and an addition a side. Neither is NaN in
   the synth; for any other pair they are what a comparison would pick. Included, as spms1_bus.h is,
   ahead of spms1_main.c's extern declarations of them. */
#ifndef SPMS1_DSP_H
#define SPMS1_DSP_H

static inline float float_max(float a, float b) {
  return __builtin_fmaxf(a, b);
}

static inline float float_min(float a, float b) {
  return __builtin_fminf(a, b);
}

#endif /* SPMS1_DSP_H */
