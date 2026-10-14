/* MCU settings for the Spinel runtime: what spinel_rt.h needs before anything else.
   spinel_rt.h includes this at its top, ahead of every system header. It is kept out of
   spinel_rt.h so that what a new Spinel release has to take again stays small: spinel_rt.h
   carries only the #include line for it (see spinel_mcu/spinel_mcu.patch). */
#ifndef SPINEL_RT_MCU_HEAD_H
#define SPINEL_RT_MCU_HEAD_H

/* Puts the synth core in RAM. */
/* flatten pulls the module process methods into Spms1_main. Without it GCC stops inlining them
   once a module type has two instances and so two call sites, and anything not inlined into main
   runs from XIP flash, main being the only function that carries .time_critical. */
#define main __attribute__((section(".time_critical"), flatten)) Spms1_main
/* Float literals of the generated code as float where Float is float (SPINEL_FLOAT32 in sp_types.h,
   1 unless defined otherwise), as a Spinel that spelled them SP_FLT(0.5) would not need. */
#if !defined(SPINEL_FLOAT32) || SPINEL_FLOAT32
#pragma GCC optimize("single-precision-constant")
#endif
#pragma GCC optimize ("O3")
#if defined(__arm__)
#pragma GCC target ("thumb")
#endif
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"

#endif /* SPINEL_RT_MCU_HEAD_H */
