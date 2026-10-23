MIDI Synthesizer SPMS-1 (type-2): Development
=============================================

- [README](./README.md) / [日本語版](./spms1_development.ja.md)


## Debug Print

- USB CDC (the serial port next to USB MIDI on the same cable)
- UART can be used instead: comment out `SPMS1_DEBUG_PRINT_USE_USB_SERIAL`
    - Speed: 115200 bps
    - GP0 and GP1 pins are used by UART0 TX and UART0 RX


## PC Simulators

The C hosts ("sim_spinel", "sim_render", and SPMS-1 Web in "web") keep the MIDI with the sketch's own
"spms1_midi_state.h", the tables "spms1_main.rb" reads and the handlers that fill them, so a change
there reaches the device and all of them at once. They take the signal bus from the sketch's "spms1_bus.h"
as well. "sim_cruby" keeps a Ruby copy of both in "sim_cruby/spms1_c_midi.rb".

The simulators are developed and tested on Windows. macOS and Linux are supported on a best-effort
basis, written to their APIs but without the machines to try them on. The GitHub Actions workflow
("SPMS-1 (type-2) Build (UF2 and Web)") builds sim_spinel and sim_render on Windows, macOS and Linux and runs
the offline renders there, and compares them with CRuby on Linux; neither is tried with audio or MIDI hardware
(on Linux, sim_spinel was run once with a FIFO standing in for the MIDI device and ALSA's file
plugin for the audio).

- Spinel output (experimental): "sim_spinel" -- builds "spms1_main.c" and the runtime in "spms1", unmodified,
  for Windows, macOS or Linux and runs it in real time, with audio out through PortAudio and MIDI in
  through WinMM, CoreMIDI, or the ALSA raw MIDI devices ("/dev/snd/midiC*D*"). Build with
  `sh sim_spinel/build.sh` (MinGW gcc in Git Bash on Windows, clang on macOS, cc on Linux), then run
  `build/sim_spinel/spms1_sim --midi-in NAME`; `--list` shows the MIDI inputs
    - The build first regenerates "spms1_main.c" with Spinel, found on the PATH or, on Windows,
      inside WSL, passing it the type seeds in "spms1/sig". `--no-spinel`, or no Spinel to be found,
      builds the one already here
    - PortAudio is loaded at run time. The PortAudio project releases source only; on Windows,
      install it into RubyInstaller's MSYS2 with
      `ridk exec pacman -S mingw-w64-ucrt-x86_64-portaudio` (the simulators look there), and on
      macOS with `brew install portaudio`, and on Linux with the package of the distribution
      (`sudo apt install libportaudio2` on Debian and Ubuntu). `SPMS1_PORTAUDIO_DLL` gives a path of your own
    - Linux: `--host alsa` or `--host jack` picks the PortAudio host API (PortAudio's default otherwise).
      A MIDI keyboard or interface on USB shows up as a raw MIDI device; a software port of the ALSA
      sequencer (a virtual keyboard) has none, so it cannot be used
- CRuby (experimental): "sim_cruby" -- runs "spms1_main.rb" itself on CRuby, with PortAudio
  through the ffi gem, installed as above, and MIDI in through WinMM on Windows and the unimidi
  gem on macOS: `ruby sim_cruby/spms1_sim.rb --midi-in NAME`. The interpreter does not keep up
  with the default patch in real time
    - Offline, with no gems: `ruby sim_cruby/spms1_render.rb` takes the same options as "sim_render" below
      and writes "spms1_render_cruby.wav". `ruby sim_cruby/spms1_compare.rb A.wav B.wav` compares two renders
- Offline render of the Spinel output: "sim_render" -- builds "spms1_main.c" and the runtime, unmodified,
  as "sim_spinel" does, and runs the whole synth faster than real time into a WAV file (48 kHz, 24 bit,
  stereo). The signals bus, the run order and the NRPN table are all there, so a routing is heard as
  the device plays it. Needs only a C compiler, on Linux, macOS, or Windows (MinGW gcc in Git Bash):
  `sh sim_render/build.sh`, then `build/sim_render/spms1_render`
    - `--patch FILE`: a patch copied from the editor with Format "MIDI bytes (hex)" (';' starts a comment),
      taken after the synth has written its default patch, as a patch sent after power-up is
    - `--score FILE`: the MIDI to play, a line each, the time in seconds and then the bytes in hex,
      e.g. `1.5 80 3C 40`. Without it, note 60 is held from 0 s to 1 s
    - `--seconds N` (default 4) and `--out FILE` (default "spms1_render.wav")
    - It prints the peaks and a hash of the samples, so two renders can be told apart at a glance:
      the editor's "Init" patch renders to the same hash as no patch at all. Compare hashes from the
      same compiler only: clang ignores the `single-precision-constant` of "spinel_rt_mcu_head.h", which GCC (as
      on the device) honors, so the last bits differ between them
    - It also checks the GC, and exits with 1 (failing "compare_with_cruby.sh" and the GitHub Actions
      workflow) unless both hold: that nothing is allocated while the synth plays,
      as a collection would interrupt the audio on the device, and that no GC root is dropped for want
      of room in `sp_gc_roots`, which "sp_gc.h" sizes for the MCU (`SP_GC_STACK_MAX`). A Spinel
      release that boxes a value the previous one kept unboxed fails the first; the second is checked
      only here, with `SP_GC_ROOT_OVERFLOW_CHECK`, so as to cost the device nothing
    - The build regenerates "spms1_main.c" with Spinel first, as "sim_spinel" does (`--no-spinel` to skip)
    - `sh sim_render/compare_with_cruby.sh [--patch FILE] [--score FILE] [--seconds N]` renders the same
      patch and score with this and with CRuby running "spms1_main.rb" itself, and compares them, so it
      tells whether the C that Spinel made does what the Ruby says. The comparison is of short-time
      spectra, relative to the signal: float (Spinel's output) and double (CRuby) let the oscillators'
      phase drift apart, which differs sample by sample but not in the spectra. Precision stays below
      about -35 dB, and a different routing, or a CC value 4 steps away, lands above -10 dB; the limit
      is -25 dB (`ruby sim_cruby/spms1_compare.rb --limit DB` for another). The chorus is the
      exception: it turns the drift of its LFO's phase into one of the delay it swings, and a high note
      played some seconds into a render can pass -25 dB from precision alone (C7 at 6 s, about -21 dB).
      Keep a render that has to pass to about 4 s, or take the chorus out of it with its Mix or Depth


## Adding a Module

The synth is built as a framework, and its sound is the modules on it:

- "spms1/spms1_framework.rb": what any synth on this base shares -- the functions the host provides
  (`Spms1::C`, implemented by "spms1.ino" and every simulator), the conversions from MIDI to the
  values a module takes, and the rules below
- "spms1/spms1_main.rb": the loop that runs a patch -- the run order, the routing, the CCs and the
  dispatch -- most of it written by patch_gen
- "spms1_patch.yaml" and "patch_gen": every number of the patch, and the wiring of each module
- The modules ("spms1_osc.rb" and the rest): a class each, knowing nothing of MIDI or of the patch

A module is added without writing anything in the loop:

1. Write its class in "spms1", in a file named after it: "spms1_" and the class name in snake
   case, as `EnvGen` is in "spms1_env_gen.rb". "spms1_amp.rb" is the smallest to start from. The
   class has:
    - `initialize(sample_rate)`
    - a setter for each parameter, called once a buffer with the value its source holds: unipolar
      0.0..1.0 or bipolar -0.5..0.5, as the parameter is marked in the YAML. It clamps the value
      and keeps it as a target
    - `process(control_tick, input, ...)`, called once a sample with its inputs, in the order the
      YAML lists them, returning its main output. `control_tick` is true every 4th sample, the
      same samples for every module: the parameters are smoothed toward their targets there, with
      `Dsp.smooth`
    - a method for each further output, read just after `process`
2. Add it to "spms1_patch.yaml", each item where it belongs in its list. Every list is numbered
   in its order, from 0 (from 1 for the modules) with no gaps, as patch_gen checks;
   `ruby patch_gen/spms1_patch_gen.rb --renumber` numbers them again after an addition:
    - under `modules`: its id, its `class`, and `process`, the keys of its inputs in the order
      `process` takes them
    - under `signals`: a slot for each output, with `module` and `output`, and `get`, the method
      that reads it, for each output but the one `process` returns
    - under `inputs`: an entry for each input
    - under `controls`: an entry for each parameter, with `set`, its setter
    - each key is its label in capitals, with `_` between the words ("Pitch Mod 1 Pol" is
      `PITCH_MOD_1_POL`), as patch_gen checks too
    - in `default_order`, where the default patch is to run it; the modules are numbered in this
      order
3. Run `ruby patch_gen/spms1_patch_gen.rb` (with `--renumber`) and regenerate "spms1/spms1_main.c"
   (`sh sim_render/build.sh`), then listen (a render with a patch file that routes it) and
   measure (`sh sim_load/estimate.sh`)

patch_gen writes the `require_relative` of the module's file, its instance, the reads of its routing and its CCs, the calls to its
setters and its `when` in the dispatch into "spms1/spms1_main.rb", as plain straight-line Ruby, the
same as it would be written by hand, so Spinel compiles it to the same: a module costs what its
own code costs and no more. The editor and the NRPN tables of "spms1_patching.md" and "spms1_patching.ja.md" take it up as well.

### Writing a Module

The worst case of a buffer is guaranteed, not hoped for: what "sim_load" measures, every module
running, is the longest a buffer can take, whatever patch, CC or note comes. A module keeps to
that:

- The same work every sample and every buffer, whatever the values: work out each parameter's
  coefficients every buffer or every control tick, never only when it changes
- No branches on values: clamp with nested ternaries, `(x < 0.0) ? 0.0 : ((x > 1.0) ? 1.0 : x)`,
  which compile to selects. A branch on `control_tick` is fine, every module taking it on the
  same samples, all of which the measure includes
- Curves from lookup tables with linear interpolation, worked out once in the class, not library
  calls (`Math.sqrt`, `Math.exp` and the like), whose time depends on the input
- Nothing allocated while playing: make every array in `initialize`
- Literals rather than named constants in the per-sample code: Spinel emits a named Integer or
  Float constant as a runtime global, loaded each time it is read
- A state that decays toward zero through `Dsp.flush_tiny`, so that it lands on zero rather than
  sinking into the denormals
- If Spinel leaves something untyped and boxes the arithmetic, a type seed in "spms1/sig" fixes it
  ("spms1/sig/spms1_dsp.rbs" says how)


## Load Estimate

"sim_load" estimates how much of each audio buffer the synth takes on the Raspberry Pi Pico 2, without
the board: `sh sim_load/estimate.sh [--profile]` builds the sketch with arduino-cli, as the GitHub
Actions workflow does, and runs its `Spms1_main` in an emulator of the Cortex-M33 (Unicorn), counting
the instructions between `start_debug_measure` and `stop_debug_measure` -- the span Debug Print
measures on the device -- with the default patch and a note held.

- It prints the instructions per buffer, which are exact for the code as built, and the cycles and
  the time at 153.6 MHz against the 1333 us a buffer of 64 samples lasts at 48 kHz, which come from a
  first-order cost model and are an estimate (see `cost` in "sim_load/spms1_load_estimate.py")
- `--profile` lists the functions the cycles go to; `--elf FILE` estimates an ELF built elsewhere, from
  another commit say, so two versions can be compared; `--help` shows the rest
- Needs Python 3 and `pip install unicorn capstone pyelftools numpy`, installed by you and not shipped
  here: Unicorn's Python binding is under the BSD license and its emulator under the GPLv2, Capstone
  and NumPy under the BSD license, and pyelftools is in the public domain


## GitHub Actions

"SPMS-1 (type-2) Build (UF2 and Web)" in "../.github/workflows/spms1-type2.yml", run by hand
("Run workflow" in the Actions tab, e.g. at a release); every run does all of the following:

- UF2: compiles "spms1/spms1.ino" for PWM Audio and I2S with Arduino-Pico 6.3.0, and keeps the
  UF2 files as an artifact
- SPMS-1 Web: builds and tests "spms1_web_synth.js", and keeps it as an artifact
- Simulators: builds "sim_spinel" and "sim_render" on Linux, macOS and Windows, renders, and compares
  the renders with CRuby on Linux. On Linux it first checks that the files generated from
  "spms1_patch.yaml" are up to date ("patch_gen/spms1_patch_gen.rb --check"). On Linux it also checks that every function and variable of the
  runtime has the same type wherever it is declared ("spinel_mcu/lto_type_check.sh"): a function
  declared with float on one side and double on the other goes unnoticed otherwise, which the
  runtime is prone to, made float for the MCU with `#define double float`
- Spinel: builds the release the README names ("Release:" under Spinel) and checks that "spms1_main.c" is what it makes of the .rb files,
  and that the runtime files are the release with "spinel_mcu/spinel_mcu.patch" applied (see below)
- With "commit_package" checked, and when all of the above pass, the UF2 files ("bin") and
  "spms1_web_synth.js" are committed on the selected branch (not if the sources were changed after
  the build, nor if nothing changed)


## Where It Departs from Ruby

The synth runs as Ruby says, CRuby included (see "sim_cruby"), but for what the MCU cannot afford.
Each of these is made in one place and named there, and no other change to Spinel or its runtime
alters what a program does:

- Float is a 32-bit float, not a double, the RP2350 having a single-precision FPU only:
  `SPINEL_FLOAT32` in "sp_types.h" (through "spinel_mcu/spinel_mcu.patch"), with the Float
  literals of the generated code taken as float ("spinel_rt_mcu_head.h") and its `double` spelled
  `float` ("spinel_rt_mcu_cold.h"). Results differ from CRuby's by the precision; sim_cruby's
  comparison allows for that. Without it, every Float operation would be done in software
- Integer `+ - *` wrap at the width of a pointer, 32 bits on the RP2350, rather than growing into a
  Bignum, as `spinel --int-overflow=wrap` builds them (`SP_INT_OVERFLOW_MODE_WRAP` in
  "spinel_rt_mcu_head.h"). The synth's integers are indices and counters far inside 32 bits.
  Without it, the checks are about 8% of the instructions of the per-sample code
- What needs an OS is not there (files, processes, sockets, fibers, threads; see `SPINEL_BARE_METAL`
  below), and the GC's buffers are sized for SRAM, so a program that nests more than 1024 GC roots
  loses the rest, which sim_render reports (see "sp_gc.h")


## Updating Spinel

The runtime files in "spms1" are all of Spinel's `lib` (and `lib/regexp`) of the release the
README names, with the changes for the MCU kept in two places:

- "spinel_rt_mcu_head.h", "spinel_rt_mcu_libm.h" and "spinel_rt_mcu_cold.h": what the MCU adds -- the
  section and the pragmas of the synth core, Integer arithmetic without the overflow check
  (`SP_INT_OVERFLOW_MODE_WRAP`, as `spinel --int-overflow=wrap` builds it), the float versions of
  the math functions, and, at
  the end of "spinel_rt.h", what binds the generated code to a float runtime (below) and the
  sketch's "spms1_bus.h".
  "spinel_rt.h" carries only an `#include` line for each
- "spinel_mcu/spinel_mcu.patch": what is changed in Spinel's own files -- the runtime written in
  `sp_float` where it said `double` for a Float, the POSIX parts left out with `#if 0` (a release
  changing what is inside them seldom stops the patch from applying), the files that need POSIX
  throughout left out whole with `SPINEL_BARE_METAL` (below), the GC's buffers made to fit
  SRAM, and the in-range path of an Array read or write (`sp_FloatArray_get`/`set`,
  `sp_IntArray_get`) put ahead of the other checks, which go out of line unchanged, so that what
  an access does is the same and only its cost moves. Each file it
  changes sits next to its released copy, "NAME.orig"
- "sp_cold_bare_metal.c" and "spinel_mcu/sp_cold_bare_metal.patch": "sp_cold.c" for a bare-metal
  build (below), kept apart from the released one, which stays as it is but for its being left
  out whole

Float is float, the RP2350 having a single-precision FPU only. `SPINEL_FLOAT32` in "sp_types.h"
decides it for the whole runtime: 1 here, and 0 gives double, as Spinel has it, with the same
results as CRuby. The generated code still spells `double` in casts and temporaries and uses
`DBL_EPSILON` and the like for the Float constants, so "spinel_rt_mcu_cold.h" ends with
`#define double float` and `FLT_*` for `DBL_*`, which reach the generated code only. `Float#to_s`
prints the shortest digits that read back as the same float (`0.1`, `0.33333334`).

There is no OS under the synth. `SPINEL_BARE_METAL` in "sp_types.h", 1 here, leaves out what in the
runtime needs more than the C library: whole, the files that need POSIX throughout ("sp_cold.c",
"sp_fiber.c", "sp_io.c", "sp_net.c", "sp_process.c", "sp_process_status.c", "sp_sched.c" and
"sp_system.c"). "sp_cold.c" is built instead as "sp_cold_bare_metal.c", which is "sp_cold.c" with
the functions that need more than the C library left out (files, directories, processes,
sockets, and what uses the files left out), made from it by "spinel_mcu/sp_cold_bare_metal.patch"
when a release is taken. `Float#to_i`, which a synth calls every sample, is inline in
"sp_alloc.h" there, so that it is inlined into the synth core rather than called from flash. The
rest is built as it is; the linker drops what the synth does not use. The simulators and SPMS-1
Web build the runtime the same way.

A new release is taken on GitHub Actions, so it needs no particular OS:

1. Run "SPMS-1 (type-2) Try a Spinel Release" ("../.github/workflows/spms1-type2-spinel-try.yml")
   by hand on the branch, with the release's tag. It takes the release with
   `sh spinel_mcu/update.sh update TAG`, which copies its files in, applies the patch and names the
   release in README.md and README.ja.md; regenerates "spms1_main.c"; checks that types agree
   across the runtime ("spinel_mcu/lto_type_check.sh", see "GitHub Actions"); compares the renders with
   CRuby, which fails if the release makes the synth allocate while it plays or need more GC roots
   than there is room for; and builds the UF2 before and after, which stops if `sp_float` is no
   longer `float`. Nothing is committed: what it changed is kept as an artifact
2. Look at the summary of the run. "spinel_mcu/size_report.sh" compares the two builds: how much
   the synth core in RAM (`Spms1_main`), the RAM and the flash grew, with a warning above 2%. A
   larger core runs more instructions a sample, which neither the sound nor the simulators show.
   Files the release adds to its `lib` are listed there too, copied in like the rest: one that
   needs POSIX does not build, and is to be left out with `SPINEL_BARE_METAL` as the others are
   (copy it to "NAME.orig", put its text between `#include "sp_types.h"` `#if !SPINEL_BARE_METAL`
   and `#endif`, and `sh spinel_mcu/update.sh save`)
3. Apply "spinel-TAG.diff" from the artifact at the top of the repository (`git apply
   spinel-TAG.diff`), commit it, and run the build workflow, whose Spinel job checks the result
   (`sh spinel_mcu/update.sh check`)
4. A hunk that no longer applies is in the artifact as "NAME.rej", and the run fails; the diff holds
   everything else. Make the change by hand after applying the diff, and write the patch again with
   `sh spinel_mcu/update.sh save`, which needs only diff (Git Bash has it on Windows). Then run
   step 1 again on the branch

The workflow can be run only once it is on the default branch, as GitHub runs a manual workflow
from there; it then runs on whichever branch is chosen.

To change a runtime file further, copy it to "NAME.orig" first if it has none, edit it, and
`sh spinel_mcu/update.sh save`.

The scripts can also be run locally, from this folder: `sh spinel_mcu/update.sh update TAG`,
`sh spinel_mcu/update.sh check` (both with `--spinel DIR` to take Spinel from a checkout instead of
cloning it), and `sh spinel_mcu/size_report.sh BEFORE.elf AFTER.elf` (the .elf that
`arduino-cli compile --output-dir DIR` leaves in DIR). They need git, diff and GNU patch, and
size_report.sh the tools of the Arduino-Pico core. They are tested on Linux only; on Windows,
Git Bash has all of them, and on macOS, `brew install gpatch` adds GNU patch.

Most of the patch would go away with a few build options in Spinel itself.
"spinel_mcu/UPSTREAM_PROPOSAL_DRAFT.md" is a **draft** of an issue proposing them, **not filed**.


## Checking the Generated Code

What the compiler makes of a change to the per-sample path is worth looking at before flashing it,
and "branchless in Ruby" does not mean branchless in the binary -- the decision is GCC's, and it
depends on the whole function. Compile the
Spinel output on its own, from the sketch folder, "spms1":

```
arm-none-eabi-gcc -c -g -mcpu=cortex-m33 -mthumb -march=armv8-m.main+fp+dsp -mfloat-abi=softfp -mcmse -std=gnu23 -Os -I. -o out.o spms1_main.c
```

The compiler ships with the Arduino-Pico core, under `packages/rp2040/tools/pqt-gcc`. It takes
about a minute. Then `arm-none-eabi-objdump -d out.o` and count the conditional branches inside
`Spms1_main`, and `arm-none-eabi-objdump --dwarf=decodedline out.o` to map an address back to the
line of Ruby it came from -- the generated C carries `#line` directives that point at the `.rb`
files, so the mapping survives all the way down.

Four things to know before reading the output:

- The `-Os` above is not what the synth is built with. "spinel_rt_mcu_head.h" carries
  `#pragma GCC optimize ("O3")`, which overrides whatever is on the command line for that
  translation unit. Passing `-O3` instead changes nothing, and neither does passing `-Os`
- The synth core is not in `.text`. The `#define main` in "spinel_rt_mcu_head.h" puts it in
  `.time_critical`. To prove two builds are the same code,
  `arm-none-eabi-objcopy -O binary --only-section=.time_critical` on each and compare the bytes.
  A comment-only edit moves every `#line` in "spms1_main.c" and nothing else, and this is how to
  confirm it
- A standalone compile runs about 2000 instructions lighter than the linked firmware, because
  `flatten` pulls the sketch's own functions into `Spms1_main` when it is built for real.
  Differences between two standalone builds are reliable; absolute totals are not. Take those
  from the `.elf` the Arduino build leaves in its sketch cache
- A shape that compiles well in a test function may not survive inlining into `Spms1_main`, which
  is about 12000 instructions. Measure the change in the real file, not in a small one
