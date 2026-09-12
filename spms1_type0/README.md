MIDI Synthesizer SPMS-1 (type-0) v0.0.28
========================================

- Monophonic semi-modular MIDI Synthesizer for Raspberry Pi Pico 2, made with Spinel (Ruby AOT Compiler)
- Controlled by MIDI as a sound module
- 48 kHz/24 bit audio output
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [日本語版 README](./README.ja.md)


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
  LFO[LFO 1]
  MIX1[Mixer 1]
  EG[EG 1]
  OSC[Osc 1]
  FILTER[Filter 1]
  AMP[Amp 1]
  OUT([Audio Out])

  OSC --> FILTER
  FILTER --> AMP
  AMP --> OUT

  NOTE -. Gate .-> EG
  NOTE -. Pitch .-> OSC
  LFO -.-> MIX1
  MIX1 -. Mod .-> OSC
  EG -. Mod .-> FILTER
  EG -. Mod .-> AMP
```

Each module is processed once per sample, in the run order below. Their parameters -- waveform,
cutoff, gain and the rest -- arrive from CC and are left out of the diagram.

Mixer 1 is in the vibrato path to scale the LFO down to 0.2. Osc 1 Mod Amt spans the whole pitch
range, as every modulation depth here does, so bringing a source down to a musical depth is left
to a mixer rather than built into the oscillator.

None of this is fixed. NRPN rewrites the run order, every arrow above, and which CC feeds each
parameter.

#### The run order

Every module is in it, one of each kind that makes a sound and a mixer behind each of them:

```mermaid
flowchart LR
  LFO[LFO 1] ~~~ MIX1[Mixer 1] ~~~ EG[EG 1] ~~~ MIX2[Mixer 2] ~~~ OSC[Osc 1]
  MIX3[Mixer 3] ~~~ FILTER[Filter 1] ~~~ MIX4[Mixer 4] ~~~ AMP[Amp 1] ~~~ MIX5[Mixer 5]
```

Mixers 2 to 5 have nothing routed to them, so they cost their slot every sample and change
nothing until a patch gives them something. Where each one sits is what it buys: a module sees
the current sample's value only from something ahead of it in this line, and last sample's from
anything behind. Mixer 1 can reach the LFO, Mixer 3 can reach the oscillator, and so on.

A mixer is what lets two of anything meet, and apart from Pitch Bend it is the only way to hand a
module input a signal that swings both ways. See the examples below.

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
| 1 | 0-17 | What feeds a module input | Signal ID |
| 2 | 0-32 | Where a parameter takes its value | Signal ID |
| 3 | 0-32 | Which CC fills a control slot | CC number, or 0 for none |

The run order is read from slot 0 upwards and stops at the first Module ID 0, so a patch shorter
than 32 modules ends itself. It is separate from the module numbering: a module only sees the
current sample's value from something listed before it, and last sample's from something after.

In category 3, CC number 0 means the parameter has no CC. Its control slot then keeps whatever it
already holds, so the parameter can be driven by routing alone.

There is one of every module that makes a sound and there are five mixers, and **all ten are in
the default run order**, so a patch only ever has to route, never to switch something on first.
A mixer is the only kind with no CC on any of its parameters: their control slots are seeded
instead, at full level and no inversion, so a mixer with one input routed passes it through
rather than muting it. Mixer 1 is seeded to 0.2 instead, because the default patch runs the
LFO through it.

#### Entries (CC 98), category 1

| CC 98 | Module input | | CC 98 | Module input |
| ----- | ------ | - | ----- | ------ |
| 0 | EG 1 Gate | | 9 | Mixer 2 In 1 |
| 1 | Osc 1 Pitch | | 10 | Mixer 2 In 2 |
| 2 | Osc 1 Mod In | | 11 | Mixer 3 In 1 |
| 3 | Filter 1 Audio In | | 12 | Mixer 3 In 2 |
| 4 | Filter 1 Mod In | | 13 | Mixer 4 In 1 |
| 5 | Amp 1 Audio In | | 14 | Mixer 4 In 2 |
| 6 | Amp 1 Mod In | | 15 | Mixer 5 In 1 |
| 7 | Mixer 1 In 1 | | 16 | Mixer 5 In 2 |
| 8 | Mixer 1 In 2 | | 17 | Final Output |

Most of these take what their name suggests, but three do not say it on their face. A Gate is a
threshold rather than a level: an envelope triggers as the signal crosses 0.5 and releases as it
falls back. A Pitch is -0.5 to +0.5 across MIDI notes 0 to 120, so 0.0 is note 60 and a tenth of
a unit is an octave. And a Mod In is taken as it arrives: nothing is held to a range on the way
in, and what gets clamped is the value the module ends up with -- cutoff to 0.0 and 1.0, pitch
to -0.5 and +0.5. A mixer adds without a ceiling, so a loud modulation pins its destination at
one end rather than being trimmed on the way in. The amp is the exception, and holds its
modulation input to -1.0 and +1.0: it is an attenuator, so a modulation may scale its gain down
but never up.

#### Entries (CC 98), categories 2 and 3

| CC 98 | Parameter | | CC 98 | Parameter | | CC 98 | Parameter |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | Osc 1 Wave | | 11 | EG 1 Sustain | | 22 | Mixer 3 Invert 1 |
| 1 | Osc 1 Mod Amt | | 12 | LFO 1 Rate | | 23 | Mixer 3 Level 2 |
| 2 | Osc 1 Coarse Tune | | 13 | Mixer 1 Level 1 | | 24 | Mixer 3 Invert 2 |
| 3 | Osc 1 Fine Tune | | 14 | Mixer 1 Invert 1 | | 25 | Mixer 4 Level 1 |
| 4 | Filter 1 Cutoff | | 15 | Mixer 1 Level 2 | | 26 | Mixer 4 Invert 1 |
| 5 | Filter 1 Resonance | | 16 | Mixer 1 Invert 2 | | 27 | Mixer 4 Level 2 |
| 6 | Filter 1 Mod Amt | | 17 | Mixer 2 Level 1 | | 28 | Mixer 4 Invert 2 |
| 7 | Filter 1 Gain | | 18 | Mixer 2 Invert 1 | | 29 | Mixer 5 Level 1 |
| 8 | Amp 1 Gain | | 19 | Mixer 2 Level 2 | | 30 | Mixer 5 Invert 1 |
| 9 | EG 1 Attack | | 20 | Mixer 2 Invert 2 | | 31 | Mixer 5 Level 2 |
| 10 | EG 1 Decay | | 21 | Mixer 3 Level 1 | | 32 | Mixer 5 Invert 2 |

#### Module IDs

| ID | Module |
| ----- | ------ |
| 0 | None (ends the run order) |
| 1 | LFO 1 |
| 2 | EG 1 |
| 3 | Osc 1 |
| 4 | Filter 1 |
| 5 | Amp 1 |
| 6 | Mixer 1 |
| 7 | Mixer 2 |
| 8 | Mixer 3 |
| 9 | Mixer 4 |
| 10 | Mixer 5 |

#### Signal IDs

| ID | Signal | | ID | Signal | | ID | Signal |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | None (constant 0.0) | | 17 | Osc 1 Coarse Tune | | 34 | Mixer 2 Level 2 |
| 1 | Constant 1.0 | | 18 | Osc 1 Fine Tune | | 35 | Mixer 2 Invert 2 |
| 2 | Constant 0.5 | | 19 | Filter 1 Cutoff | | 36 | Mixer 3 Level 1 |
| 3 | Constant -0.5 | | 20 | Filter 1 Resonance | | 37 | Mixer 3 Invert 1 |
| 4 | Constant -1.0 | | 21 | Filter 1 Mod Amt | | 38 | Mixer 3 Level 2 |
| 5 | LFO 1 Output ± | | 22 | Filter 1 Gain | | 39 | Mixer 3 Invert 2 |
| 6 | EG 1 Output | | 23 | Amp 1 Gain | | 40 | Mixer 4 Level 1 |
| 7 | Osc 1 Output ± | | 24 | EG 1 Attack | | 41 | Mixer 4 Invert 1 |
| 8 | Filter 1 Output ± | | 25 | EG 1 Decay | | 42 | Mixer 4 Level 2 |
| 9 | Amp 1 Output ± | | 26 | EG 1 Sustain | | 43 | Mixer 4 Invert 2 |
| 10 | Mixer 1 Output ± | | 27 | LFO 1 Rate | | 44 | Mixer 5 Level 1 |
| 11 | Mixer 2 Output ± | | 28 | Mixer 1 Level 1 | | 45 | Mixer 5 Invert 1 |
| 12 | Mixer 3 Output ± | | 29 | Mixer 1 Invert 1 | | 46 | Mixer 5 Level 2 |
| 13 | Mixer 4 Output ± | | 30 | Mixer 1 Level 2 | | 47 | Mixer 5 Invert 2 |
| 14 | Mixer 5 Output ± | | 31 | Mixer 1 Invert 2 | | 48 | Note Pitch ± |
| 15 | Osc 1 Wave | | 32 | Mixer 2 Level 1 | | 49 | Note Gate |
| 16 | Osc 1 Mod Amt | | 33 | Mixer 2 Invert 1 | | 50 | Pitch Bend ± |

A **±** marks a signal that swings both ways: a module output reaches -0.5 and +0.5 at full
scale, and a mixer sums two of them and stops at one. Everything unmarked runs
0.0 to 1.0 -- an envelope's output, Note Gate, and every control slot. The bus carries both
kinds under one numbering, so the range belongs to the slot rather than to the sort of thing
that wrote it.

Slots 15-47 hold the values arriving from CC, each a ratio in 0.0 to 1.0, so a parameter reads
its own CC by default. Pointing it at another slot is what makes a modulation. Anything with no
CC sits at what it was seeded with until one is assigned.

Note Pitch, Note Gate and Pitch Bend are what the keyboard puts on the bus. Note Pitch carries
MIDI notes 0 to 120 as -0.5 to +0.5, the same span the oscillator reads as its whole pitch
range, and Pitch Bend is bipolar too, one unit across the whole wheel: exactly -0.5 and +0.5 at
the ends of its travel and exactly zero at the centre detent, so it can feed a module input
without a mixer to shift it. Note Gate is 0.0 or 1.0, and an envelope triggers at 0.5. Nothing
is routed to Pitch Bend by default.

Slots 0-4 are constants that nothing writes, for inputs that want a fixed value rather than a
source. Signal 0 is also what an entry nobody has set reads as, so an unrouted input is silent
rather than wired to whatever sits in the first slot. Signal 1 is the value an unmodulated input
wants: routing an amp's modulation input to it leaves the amp at full level. The negative
constants are for shifting a signal in a mixer, since a parameter clamps its own value to
0.0-1.0 and cannot take one directly.

Slot 127 is where a parameter with no CC sends its unused value. Nothing should read it.

The ID numbers are not stable across firmware versions. A patch is never saved, so a new module
type, another instance of one, or another signal may renumber everything after it. Read these
tables again after an update.

#### Ranges worth knowing

Both tune controls are centred on CC 64 and move one whole unit per CC step: Coarse Tune a
semitone, reaching 5 octaves either way, and Fine Tune a cent, reaching 60 either way. They are
summed, so any pitch is reachable.

Osc 1 Mod Amt is a depth, not an offset, and it reaches the whole pitch range: at its top a bipolar
source swings the pitch five octaves up and five down. That is a coarse dial for vibrato, half a
semitone per CC step, which is why the default patch runs the LFO through Mixer 1 at 0.2 first. On
that path a semitone of vibrato sits at CC 14 and an octave at the top of the dial.

Filter 1 Gain sets how hard the audio input drives the filter, which is also what decides how far
the filter runs into its own saturation. Its default of CC 64 is the level the oscillator used to
be scaled to on its own; above that the filter starts to compress the loud part of a note.

A mixer takes each input at its own level and its own polarity, then adds them. Invert runs from
unchanged at 0.0, through silence at 0.5, to negated at 1.0. Levels default to full and inverts
to zero, so a mixer with one input routed is a buffer; inverting that one input makes it an
inverter; and inverting only the second makes the mixer a subtractor. Mixer 1 is the exception,
seeded to 0.2 on both levels for the vibrato path it is wired into.

The sum is held to -1.0 and +1.0. Two full-scale signals reach exactly that, so nothing ordinary
is cut; what it stops is a mixer wired back to its own input, which would otherwise double every
sample until the number stopped being a number and took the oscillator or the filter with it.
The filter is held to the same one unit, by a curve rather than a corner: its resonant peak can
climb past one unit on a sweep, and rounding that off makes a third harmonic where a hard edge
would fold high ones back down into the note.

#### Examples

- Vibrato is wired by default -- the LFO reaches the oscillator's modulation input through
  Mixer 1 -- so CC 13 sets the depth and CC 3 the rate
- Filter cutoff follows note pitch (keyboard tracking): CC 99 = 2, CC 98 = 4, CC 6 = 48
- Filter cutoff driven by the envelope instead of its CC: CC 99 = 2, CC 98 = 4, CC 6 = 6
- Filter cutoff swept by the LFO: CC 99 = 2, CC 98 = 4, CC 6 = 5 -- a parameter, so keep the rate
  low
- Amp gain and filter cutoff share one CC: CC 99 = 3, CC 98 = 8, CC 6 = 74
- Amp at full level with no envelope: CC 99 = 1, CC 98 = 6, CC 6 = 1
- Disconnect the filter's modulation input: CC 99 = 1, CC 98 = 4, CC 6 = 0
- A pitch envelope 60 cents deep: CC 99 = 2, CC 98 = 3, CC 6 = 6 points Osc 1 Fine Tune at the
  envelope, which then sweeps the tuning from 60 cents flat up to 60 cents sharp
- The envelope drives the filter harder as a note starts: CC 99 = 2, CC 98 = 7, CC 6 = 6
- Pitch swept by the envelope instead of the LFO: CC 99 = 1, CC 98 = 7, CC 6 = 6 puts the
  envelope on Mixer 1's first input in the LFO's place, then set the depth on CC 13 -- a semitone
  at 14, an octave at 124
- Pitch bend, which nothing is routed to by default. CC 99 = 1 with CC 98 = 9 and 10, CC 6 = 48
  and 50 puts Note Pitch and Pitch Bend on Mixer 2's two inputs, and CC 99 = 1, CC 98 = 1,
  CC 6 = 11 makes that sum the oscillator's pitch. Mixer 2 runs ahead of the oscillator, so the
  wheel moves the note in the same sample. Both levels are full, so the wheel reaches five
  octaves either way; CC 99 = 3, CC 98 = 19, CC 6 = 16 puts Mixer 2's second level on CC 16 to
  trim that down to a bend range worth playing
- A CC that bends pitch both ways, which no parameter can do on its own. Mixer 1 already feeds
  the oscillator's modulation input, so it only has to be given something else to mix:
  CC 99 = 1, CC 98 = 7, CC 6 = 19 puts the filter cutoff's control slot on its first input in
  the LFO's place, and CC 99 = 1, CC 98 = 8, CC 6 = 3 puts the -0.5 constant on its second. Both
  levels are 0.2, so the mixer outputs the CC less a half at vibrato depth, and CC 74 now bends
  the pitch down and up around the note
- A CC that works backwards, which needs a mixer to subtract rather than add. Mixer 2 is already
  running, so it only needs wiring: CC 99 = 1, CC 98 = 9, CC 6 = 1 puts the constant 1.0 on its
  first input, CC 99 = 1, CC 98 = 10, CC 6 = 19 puts the cutoff's control slot on the second,
  and CC 99 = 2, CC 98 = 20, CC 6 = 1 inverts that second input alone, so the mixer outputs one
  minus the CC. Point the cutoff's own source at the mixer with CC 99 = 2, CC 98 = 4, CC 6 = 11
  and CC 74 now closes the filter as it rises
- Take the filter out of the chain: CC 99 = 1, CC 98 = 5, CC 6 = 7 points the amp's audio input
  at the oscillator. The filter keeps running and keeps its slot; nothing reads it

#### Notes

- Module inputs (category 1) are read every sample and are not smoothed; parameters (category 2)
  are read once per buffer and are smoothed by their destination. Route a fast source through a
  module input, a stepped one through a parameter
- A parameter source may point at any of the 128 slots. Slots above 50 read 0 until something
  writes them
- A parameter clamps its value to 0.0-1.0, so apart from Pitch Bend a mixer is the only way to
  give a module input a signal that swings both ways
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
