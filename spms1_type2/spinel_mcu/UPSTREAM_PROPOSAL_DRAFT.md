# DRAFT: issue for matz/spinel (not filed)

> [!WARNING]
> **DRAFT -- NOT FILED.** This is a draft of an issue for matz/spinel, kept here as a memo.
> It has not been posted, and nothing in it has been agreed with the Spinel project.
> Check it against the Spinel release in use before posting: the numbers and line numbers are
> those of SPMS-1 (type-2) v0.0.2 and Spinel 2026.09.12.

**Title:** Spinel on bare metal: a 48 kHz synthesizer written in Ruby, running on a Raspberry Pi Pico 2

## A Ruby program on a microcontroller, in real time

SPMS-1 (type-2) (https://github.com/risgk/midi_synthesizer_spms1, `spms1_type2/`) is a
monophonic semi-modular MIDI synthesizer written in Ruby, about 2,100 lines in nine files. Spinel
compiles it to C, and the C runs on a Raspberry Pi Pico 2: an RP2350, a Cortex-M33 at 153.6 MHz with
520 KB of SRAM, and no OS. One core runs the synth; the other takes MIDI.

- **Every sample in Ruby.** At 48 kHz, stereo, the oscillator, a zero-delay feedback state variable
  filter, the envelope, the LFO, the amp, a mixer, a chorus and a delay each run once per sample,
  as Ruby methods. The patch -- which modules run in what order, and what feeds what -- is data,
  rewired over MIDI while it plays
- **Small enough for the chip.** The whole synth core compiles to one function of 41,004 bytes,
  placed in RAM so that it does not wait on flash. The firmware takes 199 KB of flash and 137 KB of
  static RAM. About 4 ms from a MIDI message to the sound
- **Nothing allocated while it plays.** With RBS type seeds (`--rbs`) where inference needs a hint,
  every per-sample value stays unboxed. A check in CI renders the synth on a PC and fails if
  anything is allocated while it plays
- **One source, everywhere.** The same Ruby runs on CRuby as the reference, and the C Spinel makes
  of it runs on the device, in PC simulators, and in a web browser as WebAssembly. Renders of the
  two are compared in CI: the difference of their spectra stays below -35 dB (-39 dB measured),
  where float against double puts it

## Why it is worth having

- **Ruby that keeps time.** Per-sample DSP is out of reach of an interpreter: CRuby does not keep
  up with SPMS-1 in real time even on a PC. Spinel's design -- whole-program type inference, no VM,
  unused runtime dropped by the linker -- is what lets the same Ruby do it on a microcontroller
- **Write in Ruby, test on CRuby, ship as C.** The DSP is read and changed as Ruby, checked against
  CRuby on a PC, and becomes firmware without being translated by hand
- **A board that costs a few dollars.** Instruments, education and hobby electronics, with Ruby
- **Little stands in the way.** What the runtime needs on such a target beyond what it does today
  is small: the C library is there (newlib); what is missing is POSIX and the OS behind it

## What it takes today

I carry a patch of the runtime from release to release: 13 files, 55 hunks, applied with a script
and checked in CI. Most of it leaves out the parts that assume POSIX, which a bare-metal target
does not have:

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

## The proposal: an opt-in bare-metal build

A macro, say `SPINEL_BARE_METAL`, defined only by those who build for such a target, under which
the runtime leaves out the parts above, with the IO and thread features simply absent. A program
that uses none of them, as SPMS-1 does not, does not miss them. Without the macro nothing changes:
the default build stays POSIX, as the README describes it.

"Bare metal" here means no OS under the program, with the C library still there (`malloc`,
`stdio`, `math.h`, `setjmp`). It is not "freestanding" in the C standard's sense, which guarantees
only a few headers; the runtime and the generated code are built hosted and call the C library.
An RTOS target without POSIX, such as FreeRTOS, is in the same place.

To keep it from breaking unnoticed, I would add a compile-only CI job: the runtime compiled with
`arm-none-eabi-gcc` and newlib, with `SPINEL_BARE_METAL` defined. No hardware is needed for that.
It can also come in steps, starting with the parts that are harmless on POSIX as well (for example
`__has_include` checks for `<execinfo.h>` and `<ucontext.h>`).

I would be glad to send the pull requests, and the CI job, and to keep them working.

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
  overridden. These cannot, and as static tables they take more SRAM than the chip has:

  | Macro | Where | Default | Bytes on 32-bit |
  |---|---|---|---|
  | `SP_GC_REMEMBERED_MAX` | `sp_gc.h:126` | 65536 | 256 KB |
  | `SP_GC_PINNED_MAX` | `sp_gc.h:175` | 16384 | 64 KB |
  | `SP_STR_SHAPE_MAX` | `sp_alloc.c:114` | 8192 | 32 KB |
  | `SP_ALLOC_NAMES` | `sp_alloc.c:1037` | 512 | 4 KB |

Not asked: SPMS-1 also makes `sp_float` a `float`, since the Cortex-M33 has a single-precision FPU
only. That changes results against CRuby, so it stays on my side.
