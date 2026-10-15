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

My patch takes this shape already, as far as it can from outside: it carries all of `lib`, and
`SPINEL_BARE_METAL` in `lib/sp_types.h` leaves out whole the eight files that need POSIX
throughout (`sp_cold.c`, `sp_fiber.c`, `sp_io.c`, `sp_net.c`, `sp_process.c`,
`sp_process_status.c`, `sp_sched.c`, `sp_system.c`), two lines each; `sp_crypto.c`, `sp_pack.c`
and `sp_time.c` build as they are. What is still done with `#if 0` is the POSIX inside the files
that are built (`spinel_rt.h` above all).

`sp_cold.c` is the hard one. It holds what the generated code needs (`sp_raise_nil_int_op`, the
GC scan functions of Dir and Enumerator, Float and Integer leaf ops, ...) side by side with
files, directories, processes and sockets: built for bare metal, about 100 of its functions have
to be left out one by one, about 1,160 of its 4,200 lines, and the line between them runs
through the whole file. I build a copy of it with those left out, kept apart as
`sp_cold_bare_metal.c`. A split of `sp_cold.c` into what needs an OS and what does not would make
it two files, one of them left out whole, as the others are.

`sp_float_to_i_checked` (`Float#to_i`) moved into `sp_cold.c` from the header where it was static.
Out of line in another file, it is a call for every `to_i`, which in a synth is every sample; on
a microcontroller, a call into flash. I keep it `static inline` in `sp_alloc.h`, where it is
declared, for the bare-metal build. Back in the header for every build would do as well.

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

The runtime side is the larger part, and stays opt-in, for those who accept results that differ
from CRuby's (`0.1 + 0.2` is 0.3 as a float, integers above 2^24 lose precision, `1.0e39` is
Infinity). I have done it in my patch, in the shape it would take in Spinel:

- `SPINEL_FLOAT32` in `lib/sp_types.h` decides `sp_float` (and `mrb_float` in `lib/mruby_shim.h`)
- the runtime written in `sp_float` where it said `double` for a Float: about 140 places in 11
  files, `double` kept where it means double (`sp_dtoa`, the GC's clocks, `Time`)
- the float versions of the math functions, and `FLT_EPSILON`, `FLT_MAX` and the like for the
  Float constants
- `Float#to_s` giving the shortest digits that read back as the same float (`0.1`, `0.33333334`);
  `String#to_f` reads a double and converts it

With `SPINEL_FLOAT32` set to 0, a test program prints exactly what CRuby does; with 1, the synth core
of my program compiles to the same machine code as before. A round trip of 52,200 floats through `to_s` and `to_f`
gave them all back. What the patch cannot do is the generated C: it still needs `#define double
float` and the `DBL_*` constants redefined at the end of `spinel_rt.h`, which the change in the
table above would make unnecessary.

Doing it from outside with `#define double float` around the runtime, as I did before, is
fragile: in my patch, `sp_float_shortest` and `sp_read_float` were declared with float in some translation units
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

- **`--int-overflow=wrap` with `-c`.** The mode reaches the C only as `-DSP_INT_OVERFLOW_MODE_WRAP`
  on the command line of the C compiler that `spinel` runs itself (`src/main.c:852`). With `-c`,
  where the C is compiled elsewhere (here by the Arduino build), nothing in the file says which
  mode it was generated for, and it compiles in the default raise mode. Writing the define at the
  top of the C, ahead of `#include "spinel_rt.h"`, would make the file carry its mode. I define it
  in a header of my own instead (`spinel_rt_mcu_head.h`). The checks it removes were 8% of the
  instructions of my program's per-sample code on a Cortex-M33.

- **The in-range path of an Array access first.** `sp_FloatArray_get`/`set` and `sp_IntArray_get`
  test null, frozen, a negative index and the length in turn, all inline. Testing
  `a && (uintptr_t)i < (uintptr_t)a->len` (and `!a->frozen` for set) first, inline, and leaving
  the rest out of line with the body as it is, keeps what every access does and took 12% of the
  instructions out of the same code:

  ```c
  static inline sp_float sp_FloatArray_get(sp_FloatArray*a,sp_int i){
    if(__builtin_expect(a&&(uintptr_t)i<(uintptr_t)a->len,1))return a->data[i];
    return sp_FloatArray_get_slow(a,i);  /* the released body, noinline */
  }
  ```

- **`loop do` makes every local in it volatile.** `loop` emits a setjmp to rescue StopIteration,
  and the volatile analysis (`begin_volatile_names`, `is_stopiter_loop`) then treats its block as
  a `begin`: every local written inside it is volatile, loaded and stored at every use. A program's
  main loop is often `loop do`, so this reaches its whole hot path, though nothing in it can raise
  StopIteration. Writing it as `while true` took 6% of the instructions out of my program. Leaving
  the setjmp (and the volatile) out when the block calls nothing that can raise StopIteration
  would make the two the same.

I would be glad to send pull requests for any of these, one at a time, and the CI job, and to
keep them working.

For reference, the program: https://github.com/risgk/midi_synthesizer_spms1 (`spms1_type2/`).
