/* Force-included (-include) ahead of every Spinel translation unit in the PC build, so that the
   vendored runtime, trimmed for the microcontrollers, compiles unmodified on Windows and macOS. */
#ifndef SPMS1_HOST_COMPAT_H
#define SPMS1_HOST_COMPAT_H

#include <math.h>
#include <stdlib.h>
#include <signal.h>
/* stddef.h spells out long double in max_align_t, so it has to be in before sp_array.c defines
   double as float. */
#include <stddef.h>
#include <stdint.h>

/* The same define turns the long double inside the host libc's type-generic math macros into
   long float wherever they are used. */
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

#if defined(__APPLE__)
/* Mach-O wants "segment,section", so the .time_critical of sp_runtime.h's #define main is not a
   valid section name there. Nothing else in the runtime spells section(. */
#define section(x) used
#endif

#if defined(_WIN32)
static inline int setenv(const char *k, const char *v, int overwrite) {
  (void)overwrite;
  return _putenv_s(k, v);
}
static inline int unsetenv(const char *k) { return _putenv_s(k, ""); }
#define malloc_trim(x) ((void)0)

/* Only the runtime's Signal.list table names these; Windows defines six signals. */
#ifndef SIGHUP
#define SIGHUP    1
#define SIGQUIT   3
#define SIGTRAP   5
#define SIGBUS    7
#define SIGKILL   9
#define SIGUSR1   10
#define SIGUSR2   12
#define SIGPIPE   13
#define SIGALRM   14
#define SIGCHLD   17
#define SIGCONT   18
#define SIGSTOP   19
#define SIGTSTP   20
#define SIGTTIN   21
#define SIGTTOU   22
#define SIGURG    23
#define SIGXCPU   24
#define SIGXFSZ   25
#define SIGVTALRM 26
#define SIGPROF   27
#define SIGWINCH  28
#define SIGIO     29
#define SIGSYS    31
#endif
#endif

#endif
