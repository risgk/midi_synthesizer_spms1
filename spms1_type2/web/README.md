SPMS-1 (type-2) Web
===================

SPMS-1 Web: a software synthesizer version of SPMS-1 (type-2) that runs in a Web browser, built into
SPMS-1 (type-2) Editor ("spms1_editor.html")

- The signal processing is the same as SPMS-1 (type-2): "spms1_main.c", the Spinel output the sketch runs,
  and the Spinel runtime of the sketch are compiled to WebAssembly as they are
    - The output matches the PC build of the same "spms1_main.c" within the rounding of the math library
- Version: the same as SPMS-1 (type-2) (the title of "../README.md"), shown in the console of the Web browser
- "spms1_web_synth.js" (in the parent folder, next to "spms1_editor.html"): the built file
    - The WebAssembly binary (about 230 KB) and the AudioWorkletProcessor are embedded, so that it works
      both on a Web server (e.g. GitHub Pages) and with a local file ("file://")
    - Without this file, the editor works as before (MIDI Out to the devices only)


How to Use
----------

- Open "spms1_editor.html" (a local file, or on a Web server) with Google Chrome or Microsoft Edge (recommended)
- Select "SPMS-1 Web (Built-in)" in the list "MIDI Out"
    - The editor sends its whole patch (NRPN and CC values) to SPMS-1 Web, Live patch or not
- Play the soft keyboard of the editor, or a MIDI keyboard selected in "MIDI In"
    - Web browsers start the audio only after a user operation in the page (e.g. a click, a tap, or a key press),
      so click the page once before playing a MIDI keyboard (clicking the soft keyboard also starts the audio)
    - While the audio is not started, "SPMS-1 Web: Click (or tap) to start the audio" is shown at the bottom of the page
- MIDI Channel: 1, as SPMS-1 (type-2) (the other channels are kept but not played)
- Web browsers
    - Google Chrome, Microsoft Edge (Windows, Mac, Linux, Android): recommended
      (Web MIDI API, i.e. "MIDI In" and "MIDI Out" to the devices, needs a permission)
    - Firefox: Web MIDI API needs a permission (a site permission add-on)
    - Safari (Mac, iPhone, iPad) and all the Web browsers on iPhone and iPad: Web MIDI API is not supported,
      so only the soft keyboard of the editor can be used to play SPMS-1 Web (MIDI devices cannot be used)
- Each window (tab) has its own SPMS-1 Web, which starts with the default patch of the sketch


Specifications
--------------

- The same as SPMS-1 (type-2) (MIDI, the patch in NRPN, and the 48 kHz sampling rate), except:
    - Sampling rate: 48 kHz is requested to the Web browser (no resampling);
      at other sampling rates, the output is resampled (cubic Hermite interpolation)
    - The MIDI messages are handled at the beginning of the next audio block (128 samples, about 2.7 ms at 48 kHz),
      and the synth reads them once per its own buffer (64 samples), as on the device
- How it runs: `Spms1_main` never returns, and its `while true` loop writes each sample out through
  `write_to_audio_buffer`, which waits for room in the output on the device. Here the build runs
  Binaryen's Asyncify on the WebAssembly, so that `write_to_audio_buffer` can unwind `Spms1_main`
  out to the AudioWorkletProcessor once a block is filled, and the next block rewinds it back to the
  same place. No SharedArrayBuffer (and no special HTTP headers) is needed
- `setjmp` takes the path of no exception, and `longjmp` (reached only by a raised exception) stops
  SPMS-1 Web with a message in the console: the synth raises nothing while it runs


How to Build
------------

- Requirements: [Emscripten](https://emscripten.org) (emcc, Binaryen, and Node.js; installed with emsdk) and Git
    - Built with Emscripten 6.0.12
- Install Emscripten (emsdk), once (in any folder, outside this repository):

```
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install 6.0.12
./emsdk activate 6.0.12
```

- On Windows (Command Prompt): `emsdk install 6.0.12` and `emsdk activate 6.0.12` (without "./")
- Set up the environment variables (PATH, etc.) in each new terminal:
    - Linux and macOS: `source <emsdk folder>/emsdk_env.sh`
    - Windows (Command Prompt): `<emsdk folder>\emsdk_env.bat`
- Regenerate "spms1_main.c" with Spinel first, if the .rb files are changed (see "../README.md")
- Build in this folder ("web"), and test (optional):

```
node spms1_web_build.js
node spms1_web_test.js
```

- The output: "../spms1_web_synth.js"
- GitHub Actions: "SPMS-1 (type-2) Build (UF2 and Web)" in "../../.github/workflows/spms1-type2.yml"
  builds and tests "spms1_web_synth.js" (and commits it with "commit_package")
- The source files
    - "spms1_web_main.c": the C API for the AudioWorkletProcessor, standing in for "spms1.ino"
      (the MIDI tables and handlers are the sketch's own "../spms1/spms1_midi_state.h")
    - "spms1_web_compat.h": force-included ahead of the Spinel files, as "../sim_spinel/host_compat.h" is in the PC build
    - "spms1_web_synth_processor.js": the AudioWorkletProcessor (runs the WebAssembly)
    - "spms1_web_synth_main.js": the main thread part (the virtual MIDI output for the editor)
    - "spms1_web_build.js": the build script
    - "spms1_web_test.js": the test of the built file with Node.js (plays a note at 48 kHz, 44.1 kHz, and 96 kHz,
      and checks the release, that the output does not depend on the block size, and that a patch sent as NRPN is taken)
- The Arduino IDE does not see this folder: it is outside the sketch folder, "spms1"


Credits
-------

- Modeled after PRA32-U2 Web of [Digital Synth PRA32-U2](https://github.com/risgk/digital-synth-pra32-u2)
