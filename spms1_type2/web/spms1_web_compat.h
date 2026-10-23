/* Force-included (-include) ahead of every Spinel translation unit in the WebAssembly build
   (SPMS-1 Web), so that the vendored runtime, trimmed for the microcontrollers, compiles unmodified
   with Emscripten. */
#ifndef SPMS1_WEB_COMPAT_H
#define SPMS1_WEB_COMPAT_H

#include <math.h>
#include <stdlib.h>
#include <signal.h>
/* stddef.h spells out long double in max_align_t, so it has to be in before sp_array.c defines
   double as float. */
#include <stddef.h>
#include <stdint.h>
/* So do these, which sp_core.c includes after it. */
#include <locale.h>
#include <xlocale.h>

/* The same define turns the long double inside the libc's type-generic math macros into long
   float wherever they are used. */
#undef isnan
#undef isinf
#undef isfinite
#undef signbit
#undef fpclassify
#define isnan(x)      __builtin_isnan(x)
#define isinf(x)      __builtin_isinf(x)
#define isfinite(x)   __builtin_isfinite(x)
#define signbit(x)    __builtin_signbit(x)
#define fpclassify(x) __builtin_fpclassify(FP_NAN, FP_INFINITE, FP_NORMAL, FP_SUBNORMAL, FP_ZERO, x)

/* WebAssembly has no sections to put a function in, so the .time_critical of the #define main
   in spinel_rt_mcu_head.h is dropped there. Nothing else in the runtime spells section(. */
#define section(x) used

/* setjmp and longjmp of Emscripten go through JavaScript (or through Wasm exceptions, which
   Asyncify cannot unwind), so the runtime's setjmp always takes the path of no exception, and a
   longjmp, which only a raised exception reaches, stops the synth with a trap. The synth raises
   nothing while it runs, and its own code reaches no setjmp: it loops with `while true`. */
#include <setjmp.h>
#undef setjmp
#undef longjmp
#define setjmp(env)       (((void)(env)), 0)
#define longjmp(env, val) (((void)(env)), ((void)(val)), __builtin_trap())

#endif
