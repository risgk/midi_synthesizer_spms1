MIDI Synthesizer SPMS-1 (type-0) v0.0.23
========================================

- Monophonic MIDI Synthesizer for Raspberry Pi Pico 2, made with Spinel (Ruby AOT Compiler)
- Controlled by MIDI as a sound module
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>


Required Hardware
-----------------

- [Raspberry Pi Pico 2](https://www.raspberrypi.com/products/raspberry-pi-pico-2/)
- Pimoroni [Pico Audio Pack](https://shop.pimoroni.com/products/pico-audio-pack) (PIM544)
    - The following I2S DAC hardware (96 kHz/24 bit) can also be used:
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
| 0 | 0-15 | Run order, slot by slot | Module ID |
| 1 | 0-7 | What feeds a module input | Signal ID |
| 2 | 0-8 | Where a parameter takes its value | Signal ID |
| 3 | 0-8 | Which CC fills a control slot | CC number (0-127) |

The run order is read from slot 0 upwards and stops at the first Module ID 0, so a patch shorter
than 16 modules ends itself.

#### Entries (CC 98)

| CC 98 | Category 1: module input | Categories 2 and 3: parameter |
| ----- | ------------------------ | ----------------------------- |
| 0 | EG Gate | Osc Waveform |
| 1 | Osc Pitch | Filter Cutoff |
| 2 | Filter Audio In | Filter Resonance |
| 3 | Filter Modulation In | Filter Mod Amount |
| 4 | Amp Audio In | Amp Gain |
| 5 | Amp Modulation In | EG Attack |
| 6 | Final Output | EG Decay/Release |
| 7 | Osc Modulation In | EG Sustain |
| 8 | -- | Osc Mod Amount |

#### Module IDs

| ID | Module |
| -- | ------ |
| 0 | None (ends the run order) |
| 1 | EG |
| 2 | Osc |
| 3 | Filter |
| 4 | Amp |

#### Signal IDs

| ID | Signal | | ID | Signal |
| -- | ------ | - | -- | ------ |
| 0 | None (constant 0.0) | | 8 | Filter Resonance |
| 1 | Constant 1.0 | | 9 | Filter Mod Amount |
| 2 | EG Output | | 10 | Amp Gain |
| 3 | Osc Output | | 11 | EG Attack |
| 4 | Filter Output | | 12 | EG Decay/Release |
| 5 | Amp Output | | 13 | EG Sustain |
| 6 | Osc Waveform | | 14 | Note Pitch |
| 7 | Filter Cutoff | | 15 | Note Gate |
| | | | 16 | Osc Mod Amount |

Slots 6-13 and 16 hold the values arriving from CC, so a parameter reads its own CC by default.
Pointing it at another slot is what makes a modulation.

Slots 0 and 1 are constants that nothing writes. Signal 0 is also what an entry nobody has set
reads as, so an unrouted input is silent rather than wired to whatever sits in the first slot.
Signal 1 is the value an unmodulated input wants: routing an amp's modulation input to it leaves
the amp at full level.

#### Examples

- Filter cutoff follows note pitch (keyboard tracking): CC 99 = 2, CC 98 = 1, CC 6 = 14
- Filter cutoff driven by the envelope instead of its CC: CC 99 = 2, CC 98 = 1, CC 6 = 2
- Amp gain and filter cutoff share one CC: CC 99 = 3, CC 98 = 4, CC 6 = 74
- Amp at full level with no envelope: CC 99 = 1, CC 98 = 5, CC 6 = 1
- Disconnect the filter's modulation input: CC 99 = 1, CC 98 = 3, CC 6 = 0
- Pitch swept by the envelope: CC 99 = 1, CC 98 = 7, CC 6 = 2, then set the depth on CC 13 --
  about a semitone at 15, an octave at 42, the whole range at 124
- Take the filter out of the chain: CC 99 = 0, CC 98 = 2, CC 6 = 4, then CC 99 = 0, CC 98 = 3,
  CC 6 = 0 -- and point the amp's audio input at the oscillator: CC 99 = 1, CC 98 = 4, CC 6 = 3

#### Notes

- Module inputs (category 1) are read every sample and are not smoothed; parameters (category 2)
  are read once per buffer and are smoothed by their destination. Route a fast source through a
  module input, a stepped one through a parameter
- A parameter source may point at any of the 128 slots. Slots above 16 read 0 until something
  writes them
- The NRPN CCs are stored as ordinary controls too, so a parameter may be mapped to CC 6 -- which
  then moves it every time a patch edit is sent


### [MIDI Implementation Chart](./spms1_midi_chart.md)


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
