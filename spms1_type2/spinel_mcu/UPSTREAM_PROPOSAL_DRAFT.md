# DRAFT: issue for matz/spinel (not filed)

> [!WARNING]
> **DRAFT -- NOT FILED.** This is a draft of an issue for matz/spinel, kept here as a memo.
> It has not been posted, and nothing in it has been agreed with the Spinel project.
> Check it against the Spinel release in use before posting: the numbers and line numbers are
> those of Spinel 2026.09.12. Check also the name of mruby's option (`MRB_USE_FLOAT32`).

**Title:** Spinel on bare-metal microcontrollers: an opt-in build without POSIX, and Float as float chosen by the runtime

## Background

I use Spinel to run a real-time audio program written in Ruby on a microcontroller, an RP2350
(Raspberry Pi Pico 2) with no OS. The work done for every audio sample is Ruby, compiled by
Spinel; the same source also runs on CRuby, which serves as the reference.

This works well, and it seems worth having more widely: Ruby for real-time work on small, cheap
hardware, written and tested as Ruby and shipped as C. Spinel's design -- whole-program type
inference, no VM, unused runtime dropped by the linker -- is what makes it fit, where an
interpreter would not keep up.

To get there I carry a patch of the runtime from release to release. Two changes would take most
of it away. Neither would change the default build, nor add an option to the compiler.

## 1. An opt-in bare-metal build

On a microcontroller with no OS, the C library is there (newlib: `malloc`, `stdio`, `math.h`,
`setjmp`), but POSIX and the OS behind it are not. ("Bare metal", not "freestanding": a
freestanding implementation in the C standard's sense guarantees only a few headers, while the
runtime and the generated code are built hosted and call the C library.) An RTOS target without
POSIX, such as FreeRTOS, is in the same place. What the runtime needs there and does not find:

- `spinel_rt.h`: `<sys/stat.h>`, `<dirent.h>`, `<pwd.h>`, `<sys/times.h>`, `<unistd.h>`, `<signal.h>`,
  `<sys/resource.h>`, `<fcntl.h>`, `<fnmatch.h>`, `<sys/file.h>`, `<sys/mman.h>`, `<sys/wait.h>`,
  `<execinfo.h>`; `getppid`, `pread`, `times`/`sysconf`
- `sp_io.h`: `<dirent.h>` (only for `DIR *` in `sp_Dir`)
- `sp_gc.c`: `signal(SIGSEGV/SIGBUS, ...)` for `SPINEL_GC_VERIFY`
- `sp_alloc.c`: `sigaction` for the allocation report, `clock_gettime` for the GC stats
- `sp_fiber_ctx.h`: `<ucontext.h>` as the fallback for non-x86_64/aarch64
- The inline arms in `spinel_rt.h` that call into `sp_cold.c`/`sp_io.c`/`sp_sched.c` (IO, Dir,
  Thread, Queue, Mutex, BigRational, FloatRange inspect) and need those objects to link
- `__int128` in `sp_time.h` (absent on 32-bit targets)

The proposal: a macro, say `SPINEL_BARE_METAL`, defined only by those who build for such a target,
under which the runtime leaves these out, with the IO and thread features simply absent. A
program that uses none of them does not miss them. Without the macro nothing changes.

It can come in steps, starting with what is harmless on POSIX as well (for example
`__has_include` checks for `<execinfo.h>` and `<ucontext.h>`). To keep it from breaking unnoticed,
I would add a compile-only CI job: the runtime compiled with `arm-none-eabi-gcc` and newlib, with
the macro defined. No hardware is needed for that.

## 2. Float as float, chosen where the runtime is linked in, not in the compiler

Many microcontrollers have a single-precision FPU only: the Cortex-M4F and the Cortex-M33 (as in
the RP2350), for example. There, double arithmetic is done in software. Compiled with Float as
double, the hot function of my program had about 1,900 calls to the soft-float routines
(`__aeabi_dmul`, `__aeabi_dadd`, ...), each in place of one FPU instruction, and was 24% larger.

mruby lets Float be float (`MRB_USE_FLOAT32`), and Spinel already shares some of mruby's ground
(`lib/mruby_shim.h`, and `sp_dtoa` from mruby's `fp_uscale.c`). For Spinel, though, I would not
ask for an option in the compiler. The generated C is already written almost entirely in terms of
`sp_float`; what it spells as double itself is small, and could be spelled so that the runtime
decides:

| In the generated C today | Instead | Defined by the runtime as, with double |
|---|---|---|
| `double` in casts and temporaries (`(double)(n)`, `double _t40 = x;` for `Float#floor`) | `sp_float` | `double` |
| float literals (`0.5`) | `SP_FLT(0.5)` | `((sp_float)(0.5))` |
| `DBL_EPSILON`, `DBL_MAX` and the other Float constants | `SP_FLOAT_EPSILON`, `SP_FLOAT_MAX`, ... | `DBL_EPSILON`, `DBL_MAX`, ... |

The math functions need nothing: the generated C calls `sin()`, `floor()` and the rest of
`<math.h>` with `sp_float` arguments already, and a runtime for float that includes `<tgmath.h>`
sends each of them to its float version (`sinf`, `floorf`). With 20 of them called from Ruby
(`Math.sin` to `Math.hypot`, `Float#floor`, `%`, `**`), compiled for a Cortex-M33 that way, every
call was to the float version.

The compiler then has no option and emits the same C whatever Float is to be; the runtime's
headers decide, when the C is compiled. With double, nothing changes: I rewrote the Spinel output
of my program this way (32 `double`, 898 literals) and compiled it for a Cortex-M33 against the
runtime as released, and the machine code is the same as before, byte for byte.

With float, the runtime defines `sp_float` as float and `SP_FLT(x)` as a float constant, includes
`<tgmath.h>`, and has its own helpers in `sp_float` (`sp_fmod` takes double today). The same
rewritten C, compiled that way, needs no `#define double float` and no
`-fsingle-precision-constant` (which clang ignores): the hot function has no soft-float arithmetic
left (only the conversions that the error messages pass to `sp_sprintf`), and comes out the same,
byte for byte, as what my patch produces today, and renders the same audio.

The runtime side is then the larger part, and stays opt-in, for those who accept results that
differ from CRuby's (`0.1 + 0.2` is 0.30000001192092896, integers above 2^24 lose precision,
`1.0e39` is Infinity):

- `sp_float` declared in one place (today `lib/sp_types.h`, `lib/sp_core.c`, and `mrb_float` in
  `lib/mruby_shim.h`), with the prototypes in terms of `sp_float`
- `<tgmath.h>`, its own inline helpers in terms of `sp_float`, and `SP_FLOAT_EPSILON`,
  `SP_FLOAT_MAX` and the like defined from `FLT_EPSILON`, `FLT_MAX`, ...
- the shortest round trip for a float in `Float#to_s`, and `strtof` (or the float counterpart of
  `sp_read_float`) in `String#to_f`

Doing it from outside, as I do now (`#define double float` around the runtime), is fragile: in my
patch, `sp_float_shortest` and `sp_read_float` were declared with float in some translation units
and defined with double in `sp_dtoa.c`, so `Float#to_s` printed garbage and `String#to_f` wrote
past a variable, unnoticed until an LTO type check (`-flto -Wlto-type-mismatch`). And `<tgmath.h>`
cannot be used under that `#define` (its macros spell `long double`), so each math function has to
be sent to its float version by hand, and one left out falls back to double silently.

The generated-C part can come first: with double it changes nothing. The CRuby comparison does not
apply to the float runtime, so that would need its own tests: a small set with a tolerance, and
the compile-only CI job above with float.

## Smaller, separate

- **A bug on 32-bit targets.** `sp_float_to_i_checked` (`lib/sp_cold.c:3099`) raises RangeError
  outside +-2^63, the range of a 64-bit `sp_int`. `sp_int` is pointer-width, so on a 32-bit target
  a Float from 2^31 up passes the check and is converted out of range, which C leaves undefined.
  Checking against the range of `sp_int` fixes it at the same cost:

  ```c
  #if INTPTR_MAX == INT32_MAX
    if (f >= 2147483648.0 || f < -2147483648.0)
  #else
    if (f >= 9223372036854775808.0 || f < -9223372036854775808.0)
  #endif
  ```

- **`#ifndef` on the remaining table sizes.** `SP_GC_STACK_MAX` and `SP_ALLOC_STATS` can already be
  overridden. These cannot, and as static tables they take more SRAM than a microcontroller has:

  | Macro | Where | Default | Bytes on 32-bit |
  |---|---|---|---|
  | `SP_GC_REMEMBERED_MAX` | `sp_gc.h:126` | 65536 | 256 KB |
  | `SP_GC_PINNED_MAX` | `sp_gc.h:175` | 16384 | 64 KB |
  | `SP_STR_SHAPE_MAX` | `sp_alloc.c:114` | 8192 | 32 KB |
  | `SP_ALLOC_NAMES` | `sp_alloc.c:1037` | 512 | 4 KB |

I would be glad to send pull requests for any of these, one at a time, and the CI job, and to
keep them working.

For reference, the program: https://github.com/risgk/midi_synthesizer_spms1 (`spms1_type2/`).
