# DRAFT: issue for matz/spinel (not filed)

> [!WARNING]
> **DRAFT -- NOT FILED.** This is a draft of an issue for matz/spinel, kept here as a memo.
> It has not been posted, and nothing in it has been agreed with the Spinel project.
> Check it against the Spinel release in use before posting: the line numbers are those of 2026.09.12.

**Title:** Build knobs for running the runtime on a microcontroller (float as sp_float, no POSIX, smaller GC tables)

I run Spinel's output on a Raspberry Pi Pico 2 (RP2350, Cortex-M33, 520 KB SRAM, single-precision FPU)
as the core of a MIDI synthesizer (https://github.com/risgk/midi_synthesizer_spms1, type-2).
It works well with release 2026.09.12, but the runtime needs a patch for the MCU, which I carry
from release to release (13 files, about 50 hunks). Most of it would go away with three knobs,
each a no-op for existing builds:

## 1. The float type as one macro

`sp_float` is declared as `double` in three places: `lib/sp_types.h:91`, `lib/sp_core.c:24` and
`lib/mruby_shim.h:25` (`mrb_float`). On an FPU without double precision, double arithmetic is
software-emulated and many times slower. A single knob would do:

```c
#ifndef SP_FLOAT_TYPE
#define SP_FLOAT_TYPE double
#endif
typedef SP_FLOAT_TYPE sp_float;
```

used in all three, with `sp_core.h`'s prototypes in terms of `sp_float` rather than `double`.
(Today I also `#define double float` in the runtime and map `sin`/`sqrt`/... to their `f` forms.
I can do that part on my side, but the typedefs have to agree across translation units.)

## 2. A switch for a build without POSIX

On newlib without an OS, these are missing and are the rest of my patch:

- `spinel_rt.h`: `<sys/stat.h>`, `<dirent.h>`, `<pwd.h>`, `<sys/times.h>`, `<unistd.h>`, `<signal.h>`,
  `<sys/resource.h>`, `<fcntl.h>`, `<fnmatch.h>`, `<sys/file.h>`, `<sys/mman.h>`, `<sys/wait.h>`,
  `<execinfo.h>`; `getppid`, `pread`, `times`/`sysconf`
- `sp_io.h`: `<dirent.h>` (only for `DIR *` in `sp_Dir`)
- `sp_gc.c`: `signal(SIGSEGV/SIGBUS, ...)` for `SPINEL_GC_VERIFY`
- `sp_alloc.c`: `sigaction` for the allocation report, `clock_gettime` for the GC stats
- `sp_fiber_ctx.h`: `<ucontext.h>` as the fallback for non-x86_64/aarch64
- The inline arms in `spinel_rt.h` that call into `sp_cold.c`/`sp_io.c`/`sp_sched.c`
  (IO, Dir, Thread, Queue, Mutex, BigRational, FloatRange inspect) and need those objects to link
- `__int128` in `sp_time.h` (absent on 32-bit targets)

Something like `#ifdef SPINEL_NO_POSIX` around those (or `__has_include` checks) would let the
runtime build for a bare-metal target, with the IO/thread features simply absent. The generated
code of a program that uses none of them does not need them.

## 3. `#ifndef` on the remaining table sizes

`SP_GC_STACK_MAX` (`sp_gc.h:68`) can already be overridden. These cannot, and as static tables they
take more SRAM than the MCU has:

| Macro | Where | Default | Bytes on 32-bit |
|---|---|---|---|
| `SP_GC_REMEMBERED_MAX` | `sp_gc.h:126` | 65536 | 256 KB |
| `SP_GC_PINNED_MAX` | `sp_gc.h:175` | 16384 | 64 KB |
| `SP_STR_SHAPE_MAX` | `sp_alloc.c:114` | 8192 | 32 KB |
| `SP_ALLOC_STATS` | `sp_alloc.c` (has `#ifndef`) | 8192 | 192 KB |
| `SP_ALLOC_NAMES` | `sp_alloc.c:1037` | 512 | 4 KB |

`#ifndef` around each, as `SP_GC_STACK_MAX` has, is all it takes.

I would be happy to send pull requests for any of these, one at a time, if the direction is welcome.
