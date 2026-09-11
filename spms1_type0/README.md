MIDI Synthesizer SPMS-1 (type-0) v0.0.25
========================================

- Monophonic semi-modular MIDI Synthesizer for Raspberry Pi Pico 2, made with Spinel (Ruby AOT Compiler)
- Controlled by MIDI as a sound module
- 48 kHz/24 bit audio output
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>


Required Hardware
-----------------

- [Raspberry Pi Pico 2](https://www.raspberrypi.com/products/raspberry-pi-pico-2/)
- Pimoroni [Pico Audio Pack](https://shop.pimoroni.com/products/pico-audio-pack) (PIM544)
    - The following I2S DAC hardware (48 kHz/24 bit) can also be used:
        - [Adafruit PCM5102 I2S DAC](https://www.adafruit.com/product/6250) (Product ID: 6250)
        - GY-PCM5102 (PCM5102A I2S DAC Module)


Required Software for Modification
----------------------------------

- [Arduino IDE](https://www.arduino.cc/en/software)
- Arduino-Pico = Raspberry Pi Pico/RP2040/RP2350 (by Earle F. Philhower, III) core
    - Additional Board Manager URL: <https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json>
    - This sketch is tested with version 6.0.0: <https://github.com/earlephilhower/arduino-pico/releases/tag/6.0.0>
    - Info: <https://github.com/earlephilhower/arduino-pico>
- Arduino MIDI Library (by Francois Best, lathoub)
    - This sketch is tested with version 5.0.2: <https://github.com/FortySevenEffects/arduino_midi_library/releases/tag/5.0.2>
    - Info: <https://github.com/FortySevenEffects/arduino_midi_library>
- Spinel
    - Commit: <https://github.com/matz/spinel/tree/5af61ae7d53e36ca59a8de5870f532360d88fd7c>
    - Please modify `int main(int argc,char**argv){` to `int Spms1_main(int argc,char**argv){` in the Spinel output file "spms1_main.c"


Usage
-----

### Prebuilt Binary

- "spms1_type0.ino.uf2" (in the "bin" folder) is for Raspberry Pi Pico 2 and Pimoroni Pico Audio Pack


### Web Editor

- Cross-platform web-based parameter controller via Web MIDI API: "spms1_editor.html"
- Built-in software keyboard for note input and testing


### MIDI Settings

- MIDI Channel: Channel 1
- USB MIDI Input
    - Manufacturer Descriptor: "ISGK Instruments"
    - Device Name: "SPMS-1 (type-0)"
- UART MIDI Input
    - Speed: 31250 bps
    - GP4 and GP5 pins are used by UART1 TX and UART1 RX
    - You can also use `SoftwareSerial` by making the following changes:

        ```cpp
        #include <SoftwareSerial.h>
        #define SPMS1_UART_MIDI_TX_PIN              (4)
        #define SPMS1_UART_MIDI_RX_PIN              (5)
        SoftwareSerial mySerial(SPMS1_UART_MIDI_RX_PIN, SPMS1_UART_MIDI_TX_PIN);
        #define SPMS1_UART_MIDI_SERIAL              mySerial
        ```

        ```cpp
        //  SPMS1_UART_MIDI_SERIAL.setTX(SPMS1_UART_MIDI_TX_PIN);
        //  SPMS1_UART_MIDI_SERIAL.setRX(SPMS1_UART_MIDI_RX_PIN);
        ```

    - DIN/TRS MIDI is available by using (and modifying) Adafruit MIDI FeatherWing Kit, for example
        - Adafruit [MIDI FeatherWing Kit](https://www.adafruit.com/product/4740) (Product ID: 4740)
        - M5Stack [Midi Unit with DIN Connector (SAM2695)](https://shop.m5stack.com/products/midi-unit-with-din-connector-sam2695) (SKU: U187) in Separate mode
        - Kinoshita Laboratory [MIDI-UART interface-san Kit](https://www.tindie.com/products/kinoshitalab/midi-uart-interface-san-kit/)
        - 木下研究所 [MIDI-UARTインターフェースさん キット](https://www.switch-science.com/products/8117) (Shipping to Japan only)
        - necobit電子 [MIDI Unit for GROVE](https://necobit.com/denshi/grove-midi-unit/) (Shipping to Japan only)
        - necobit電子 [MIDI Unit Mini for GROVE](https://necobit.com/denshi/midi-unit-mini-for-grove/) (Shipping to Japan only)


### [MIDI Implementation Chart](./spms1_midi_chart.md)


### Block Diagram

The default patch. Solid arrows carry audio, dashed arrows carry control.

```mermaid
flowchart LR
  NOTE([MIDI Note])
  EG[EG]
  LFO[LFO]
  OSC[Osc]
  FILTER[Filter]
  AMP[Amp]
  OUT([Audio Out])

  OSC --> FILTER
  FILTER --> AMP
  AMP --> OUT

  NOTE -. Gate .-> EG
  NOTE -. Pitch .-> OSC
  LFO -. Mod .-> OSC
  EG -. Mod .-> FILTER
  EG -. Mod .-> AMP
```

The modules run in the order EG, LFO, Osc, Filter, Amp, one sample at a time. Their parameters --
waveform, cutoff, gain and the rest -- arrive from CC and are left out here.

None of this is fixed. NRPN rewrites the run order, every arrow above, and which CC feeds each
parameter.


### Patch Editing (NRPN)

The patch is data, and NRPN rewrites it while the synth is running: which modules run and in what
order, what feeds each module input, where each parameter takes its value from, and which CC fills
each control slot. Every module reads from a numbered signal slot and writes to one, so rewiring is
a matter of changing slot numbers.

#### Sending

- CC 99 selects the category, CC 98 the entry within it, in either order
- CC 6 (Data Entry MSB) commits the value, and takes effect on the next audio buffer
- CC 38 (Data Entry LSB) is ignored: every value here is 7-bit
- CC 101 and CC 100 (RPN select) suspend data entry, so an RPN is never taken as a patch edit.
  Send CC 99 or CC 98 again to resume
- Edits are not saved. The default patch is restored at power-on

#### Categories (CC 99)

| CC 99 | CC 98 | Sets | CC 6 value |
| ----- | ----- | ---- | ---------- |
| 0 | 0-31 | Run order, slot by slot | Module ID |
| 1 | 0-14 | What feeds a module input | Signal ID |
| 2 | 0-25 | Where a parameter takes its value | Signal ID |
| 3 | 0-25 | Which CC fills a control slot | CC number, or 0 for none |

The run order is read from slot 0 upwards and stops at the first Module ID 0, so a patch shorter
than 32 modules ends itself.

In category 3, CC number 0 means the parameter has no CC. Its control slot then keeps whatever it
already holds, so the parameter can be driven by routing alone.

There are two of every module. **The second of each is not in the default run order**, has
nothing routed to it, and carries no CC on any of its parameters, so it makes no sound and costs
nothing per sample until a patch puts it in the run order. Its parameters are still read once a
buffer either way. Its control slots are seeded with the values the first one's CCs default to,
so wiring it in gives a module that behaves like the first rather than a silent one.

#### Entries (CC 98)

| CC 98 | Category 1: module input | Categories 2 and 3: parameter |
| ----- | ------------------------ | ----------------------------- |
| 0 | EG 1 Gate | Osc 1 Wave |
| 1 | EG 2 Gate | Osc 1 Mod Amt (Modulation Amount) |
| 2 | Osc 1 Pitch | Osc 1 Coarse Tune |
| 3 | Osc 1 Mod In | Osc 1 Fine Tune |
| 4 | Osc 2 Pitch | Osc 2 Wave |
| 5 | Osc 2 Mod In | Osc 2 Mod Amt (Modulation Amount) |
| 6 | Filter 1 Audio In | Osc 2 Coarse Tune |
| 7 | Filter 1 Mod In | Osc 2 Fine Tune |
| 8 | Filter 2 Audio In | Filter 1 Cutoff |
| 9 | Filter 2 Mod In | Filter 1 Resonance |
| 10 | Amp 1 Audio In | Filter 1 Mod Amt (Modulation Amount) |
| 11 | Amp 1 Mod In | Filter 1 Gain |
| 12 | Amp 2 Audio In | Filter 2 Cutoff |
| 13 | Amp 2 Mod In | Filter 2 Resonance |
| 14 | Final Output | Filter 2 Mod Amt (Modulation Amount) |
| 15 | -- | Filter 2 Gain |
| 16 | -- | Amp 1 Gain |
| 17 | -- | Amp 2 Gain |
| 18 | -- | EG 1 Attack |
| 19 | -- | EG 1 Decay |
| 20 | -- | EG 1 Sustain |
| 21 | -- | EG 2 Attack |
| 22 | -- | EG 2 Decay |
| 23 | -- | EG 2 Sustain |
| 24 | -- | LFO 1 Rate |
| 25 | -- | LFO 2 Rate |

#### Module IDs

| ID | Module | | ID | Module |
| -- | ------ | - | -- | ------ |
| 0 | None (ends the run order) | | 6 | Osc 2 |
| 1 | EG 1 (Envelope Generator) | | 7 | Filter 1 |
| 2 | EG 2 | | 8 | Filter 2 |
| 3 | LFO 1 (Low Frequency Oscillator) | | 9 | Amp 1 (Amplifier) |
| 4 | LFO 2 | | 10 | Amp 2 |
| 5 | Osc 1 (Oscillator) | | | |

#### Signal IDs

| ID | Signal | | ID | Signal |
| -- | ------ | - | -- | ------ |
| 0 | None (constant 0.0) | | 22 | Osc 2 Fine Tune |
| 1 | Constant 1.0 | | 23 | Filter 1 Cutoff |
| 2 | Constant 0.5 | | 24 | Filter 1 Resonance |
| 3 | Constant -0.5 | | 25 | Filter 1 Mod Amt |
| 4 | Constant -1.0 | | 26 | Filter 1 Gain |
| 5 | EG 1 Output | | 27 | Filter 2 Cutoff |
| 6 | EG 2 Output | | 28 | Filter 2 Resonance |
| 7 | LFO 1 Output | | 29 | Filter 2 Mod Amt |
| 8 | LFO 2 Output | | 30 | Filter 2 Gain |
| 9 | Osc 1 Output | | 31 | Amp 1 Gain |
| 10 | Osc 2 Output | | 32 | Amp 2 Gain |
| 11 | Filter 1 Output | | 33 | EG 1 Attack |
| 12 | Filter 2 Output | | 34 | EG 1 Decay |
| 13 | Amp 1 Output | | 35 | EG 1 Sustain |
| 14 | Amp 2 Output | | 36 | EG 2 Attack |
| 15 | Osc 1 Wave | | 37 | EG 2 Decay |
| 16 | Osc 1 Mod Amt | | 38 | EG 2 Sustain |
| 17 | Osc 1 Coarse Tune | | 39 | LFO 1 Rate |
| 18 | Osc 1 Fine Tune | | 40 | LFO 2 Rate |
| 19 | Osc 2 Wave | | 41 | Note Pitch |
| 20 | Osc 2 Mod Amt | | 42 | Note Gate |
| 21 | Osc 2 Coarse Tune | | | |

Slots 15-40 hold the values arriving from CC, so a parameter reads its own CC by default.
Pointing it at another slot is what makes a modulation. The second instance of each module has no
CC, so its slots sit at what they were seeded with until one is assigned.

Slots 0-4 are constants that nothing writes, for inputs that want a fixed value rather than a
source. Signal 0 is also what an entry nobody has set reads as, so an unrouted input is silent
rather than wired to whatever sits in the first slot. Signal 1 is the value an unmodulated input
wants: routing an amp's modulation input to it leaves the amp at full level. The negative
constants only do something on a module input, since a parameter clamps its value to 0.0-1.0.

Slot 127 is where a parameter with no CC sends its unused value. Nothing should read it.

The ID numbers are not stable across firmware versions. A patch is never saved, so adding a
module is allowed to regroup them.

#### Ranges worth knowing

Both tune controls are centred on CC 64 and move one whole unit per CC step: Coarse Tune a
semitone, reaching 5 octaves either way, and Fine Tune a cent, reaching 60 either way. They are
summed, so any pitch is reachable.

Osc Mod Amt is a depth, not an offset: at its top a bipolar source swings the pitch an octave up
and an octave down, and a semitone of vibrato sits at CC 14.

Filter Gain sets how hard the audio input drives the filter, which is also what decides how far
the filter runs into its own saturation. Its default of CC 64 is the level the oscillator used to
be scaled to on its own; above that the filter starts to compress the loud part of a note.

#### Examples

- Vibrato is wired by default -- LFO 1 feeds the oscillator's modulation input -- so CC 13 sets
  the depth and CC 3 the rate
- Filter cutoff follows note pitch (keyboard tracking): CC 99 = 2, CC 98 = 8, CC 6 = 41
- Filter cutoff driven by the envelope instead of its CC: CC 99 = 2, CC 98 = 8, CC 6 = 5
- Filter cutoff swept by the LFO: CC 99 = 2, CC 98 = 8, CC 6 = 7 -- a parameter, so keep the rate
  low
- Amp gain and filter cutoff share one CC: CC 99 = 3, CC 98 = 16, CC 6 = 74
- Amp at full level with no envelope: CC 99 = 1, CC 98 = 11, CC 6 = 1
- Disconnect the filter's modulation input: CC 99 = 1, CC 98 = 7, CC 6 = 0
- A pitch envelope 60 cents deep: CC 99 = 2, CC 98 = 3, CC 6 = 5 points Osc 1 Fine Tune at the
  envelope, which then sweeps the tuning from 60 cents flat up to 60 cents sharp
- The envelope drives the filter harder as a note starts: CC 99 = 2, CC 98 = 11, CC 6 = 5
- Pitch swept by the envelope instead of the LFO: CC 99 = 1, CC 98 = 3, CC 6 = 5, then set the
  depth on CC 13 -- a semitone at 14, an octave at 124
- A second envelope, so the filter and the amp stop sharing one: CC 99 = 0, CC 98 = 5, CC 6 = 2
  puts EG 2 in the run order, CC 99 = 1, CC 98 = 1, CC 6 = 42 gates it from the keyboard, and
  CC 99 = 1, CC 98 = 7, CC 6 = 6 hands the filter over to it
- Take the filter out of the chain: CC 99 = 0, CC 98 = 3, CC 6 = 9, then CC 99 = 0, CC 98 = 4,
  CC 6 = 0 -- and point the amp's audio input at the oscillator: CC 99 = 1, CC 98 = 10, CC 6 = 9

#### Notes

- Module inputs (category 1) are read every sample and are not smoothed; parameters (category 2)
  are read once per buffer and are smoothed by their destination. Route a fast source through a
  module input, a stepped one through a parameter
- A parameter source may point at any of the 128 slots. Slots above 42 read 0 until something
  writes them
- There is no mixer yet, so two modules of the same kind cannot be summed into one input. A
  second oscillator is reachable as a modulator, not as a second voice
- The NRPN CCs are stored as ordinary controls too, so a parameter may be mapped to CC 6 -- which
  then moves it every time a patch edit is sent

### Debug UART

- Speed: 115200 bps
- GP0 and GP1 pins are used by UART0 TX and UART0 RX


### Test Script

- Output WAV File: "spms1_output_wav.rb"


SPMS-1 (type-0) Licence
-----------------------

```
MIDI Synthesizer SPMS-1 (type-0) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
```

- Target files: `spms1_*.*`


Spinel Licence
--------------

```
Copyright (c) 2024- Yukihiro Matsumoto (matz@ruby.or.jp)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```

- Base Commit: <https://github.com/matz/spinel/tree/5af61ae7d53e36ca59a8de5870f532360d88fd7c>
- Target files: `sp_*.*`
    - Note: Some files for runtime are modified for MCU by ISGK Instruments (Ryo Ishigaki)
