MIDI Synthesizer SPMS-1 (type-1) v0.0.11
========================================

- Monophonic semi-modular MIDI Synthesizer for M5Stack AtomS3 Lite and Raspberry Pi Pico 2, made with Spinel (Ruby AOT Compiler)
- Controlled by MIDI as a sound module
- 48 kHz/24 bit audio output
- Filter: ZDF/TPT State Variable Filter (with delayed soft clipping)
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [日本語版 README](./README.ja.md)


Required Hardware
-----------------

- M5Stack AtomS3 Lite (ESP32-S3), recommended
    - M5Stack [AtomS3 Lite](https://shop.m5stack.com/products/atoms3-lite-esp32s3-dev-kit) (SKU: C124)
    - M5Stack [Atomic Audio-3.5 Base](https://shop.m5stack.com/products/atomic-audio-3-5-base) (SKU: A166)
- Raspberry Pi Pico 2 (RP2350)
    - [Raspberry Pi Pico 2](https://www.raspberrypi.com/products/raspberry-pi-pico-2/)
    - Pimoroni [Pico Audio Pack](https://shop.pimoroni.com/products/pico-audio-pack) (PIM544)
        - The following I2S DAC hardware (48 kHz/24 bit) can also be used:
            - [Adafruit PCM5102 I2S DAC](https://www.adafruit.com/product/6250) (Product ID: 6250)
            - GY-PCM5102 (PCM5102A I2S DAC Module)
    - NOTE: The RP2350 system clock (sysclk) changes to overclocked 153.6 MHz by I2S Audio Library setSysClk()


Required Software for Modification
----------------------------------

- [Arduino IDE](https://www.arduino.cc/en/software)
- For M5Stack AtomS3 Lite: Arduino core for the ESP32 (by Espressif Systems)
    - This sketch is tested with version 3.3.11: <https://github.com/espressif/arduino-esp32/releases/tag/3.3.11>
    - Info: <https://github.com/espressif/arduino-esp32>
    - Board: "M5AtomS3", with USB Mode: "USB-OTG (TinyUSB)" in the "Tools" menu. USB MIDI, I2S
      and I2C all come from the core, so no library beyond the Arduino MIDI Library is needed
- For Raspberry Pi Pico 2: Arduino-Pico = Raspberry Pi Pico/RP2040/RP2350 (by Earle F. Philhower, III) core
    - Additional Board Manager URL: <https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json>
    - This sketch is tested with version 6.1.1: <https://github.com/earlephilhower/arduino-pico/releases/tag/6.1.1>
    - Info: <https://github.com/earlephilhower/arduino-pico>
    - Board: "Raspberry Pi Pico 2", with USB Stack: "Adafruit TinyUSB" in the "Tools" menu
- Arduino MIDI Library (by Francois Best, lathoub)
    - This sketch is tested with version 5.0.2: <https://github.com/FortySevenEffects/arduino_midi_library/releases/tag/5.0.2>
    - Info: <https://github.com/FortySevenEffects/arduino_midi_library>
- Spinel
    - Commit: <https://github.com/matz/spinel/tree/5af61ae7d53e36ca59a8de5870f532360d88fd7c>
    - The Spinel output file "spms1_main.c" needs no editing. "sp_runtime.h" in this sketch
      carries `#define main IRAM_ATTR __attribute__((flatten)) Spms1_main` for the ESP32-S3 and
      `#define main __attribute__((section(".time_critical"), flatten)) Spms1_main` for the
      RP2350, which renames it and puts the synth core in RAM (IRAM on the ESP32-S3) at the same
      time. Renaming it by hand instead leaves the macro with nothing to match, and the core runs
      from flash


Usage
-----

### Prebuilt Binary

- "spms1_type1.ino.merged.bin" (in the "bin" folder) is for M5Stack AtomS3 Lite and Atomic Audio-3.5 Base
    - Hold the AtomS3 Lite's reset button for about 2 seconds, until the green LED inside lights,
      to put it into download mode. Then write the file at address 0x0, with esptool (it ships
      with the Arduino core for the ESP32), for example:

        ```
        esptool --chip esp32s3 --port COM7 write-flash 0x0 spms1_type1.ino.merged.bin
        ```

    - Or, with nothing to install, open [esptool-js](https://espressif.github.io/esptool-js/) in
      Chrome or Edge, "Connect" to the AtomS3 Lite, and "Program" the file at Flash Address 0x0
    - Then unplug and replug the USB cable to start it; the reset at the end of writing leaves it
      in download mode


### Web Editor

- Cross-platform web-based parameter controller via Web MIDI API: "spms1_editor.html"
- Built-in software keyboard for note input and testing
- Graphical patch editor (experimental) on its Patch tab
    - Wires module outputs to inputs and parameters, and sets the run order and CC assignments
    - Saves and loads patches as JSON
    - Copies the patch as MIDI bytes or as an NRPN list, or sends it through Web MIDI


### MIDI Settings

- MIDI Channel: Channel 1
- USB MIDI Input
    - Manufacturer Descriptor: "ISGK Instruments" (Raspberry Pi Pico 2 only; the AtomS3 Lite
      keeps the core's own, because USB CDC On Boot starts USB before the sketch can set it)
    - Device Name: "SPMS-1 (type-1)"
    - On Windows, the AtomS3 Lite's MIDI interface can come up bound to the "USB JTAG debug unit"
      driver (WinUSB), which some ESP32 tools install for the same VID/PID in the Hardware CDC
      mode. It then does not show up as a MIDI device. Change its driver in the Device Manager
      to "USB Audio Device"
- UART MIDI Input
    - Speed: 31250 bps
    - M5Stack AtomS3 Lite: G2 and G1 pins (Grove port) are used by UART2 TX and UART2 RX
        - M5Stack [Unit MIDI](https://shop.m5stack.com/products/midi-unit-with-din-connector-sam2695)
          (SKU: U187) plugs straight into the Grove port as the DIN MIDI interface, in Separate mode
        - To use the AtomS3 Lite itself as a Grove unit, driven over the Grove port by another
          M5Stack controller, swap the two pins:

            ```cpp
            #define SPMS1_UART_MIDI_TX_PIN              (1)     // Grove
            #define SPMS1_UART_MIDI_RX_PIN              (2)     // Grove
            ```

    - Raspberry Pi Pico 2: GP4 and GP5 pins are used by UART1 TX and UART1 RX
    - On the Raspberry Pi Pico 2, you can also use `SoftwareSerial` by making the following changes:

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


### Latency

About 4 ms from a MIDI message to the sound that answers it:

- Two output buffers of 64 samples each: 2.7 ms
- MIDI is read once per buffer, so a message waits up to one more: 1.3 ms

That is the synth's own; what the MIDI link and the DAC add sits on top of it.


### [MIDI Implementation Chart](./spms1_midi_chart.md)


### Block Diagram

The default patch. Solid arrows carry audio, dashed arrows carry control.

```mermaid
flowchart LR
  NOTE([MIDI Note])
  LFO[LFO 1]
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
  LFO -. Mod .-> OSC
  EG -. Mod .-> FILTER
  EG -. Mod .-> AMP
```

Each module is processed once per sample, in the run order below. Their parameters -- waveform,
cutoff, gain and the rest -- arrive from CC and are left out of the diagram.

The LFO goes straight to the oscillator, and LFO 1 Polarity reads the constant 0.1, which brings
it down to a vibrato depth. Osc 1 Mod Amt spans the whole pitch range, as every modulation
depth here does, so bringing a source down to a musical depth is left to the source rather than
built into the oscillator.

None of this is fixed. NRPN rewrites the run order, every arrow above, and which CC feeds each
parameter.

#### The run order

Every module is in it, one of each kind that makes a sound and a mixer between the modulation
sources and the oscillator:

```mermaid
flowchart LR
  LFO[LFO 1] ~~~ EG[EG 1] ~~~ MIX1[Mixer 1] ~~~ OSC[Osc 1] ~~~ FILTER[Filter 1] ~~~ AMP[Amp 1]
```

The mixer has nothing routed to it, so it costs its slot every sample and changes nothing until
a patch gives it something. Where it sits is what it buys: a module sees the current sample's
value only from something ahead of it in this line, and last sample's from anything behind.
Mixer 1 can reach the LFO and the envelope, and the oscillator, the filter and the amp can reach
Mixer 1.

A mixer is what lets two of anything meet, and what makes a signal that runs one way, such as the
envelope, swing both ways. See the examples below.

#### Filter 1

A zero-delay feedback state variable filter: at the sum, the loop equation is solved in closed
form, so the high pass is found in one step. The soft clip acts only where the band pass state is
read back, and it is what holds the resonance down; the low pass state stays linear, with a
clamp at 16 as a guard that ordinary use never reaches. The output clip comes last. At the top of
the resonance dial k turns negative and the loop oscillates.

```mermaid
flowchart LR
  IN([Input]) --> SUM((Σ))
  SUM -->|HP| I1["Integrator 1<br/>BP, state s1"]
  I1 -->|BP| I2["Integrator 2<br/>LP, state s2"]
  I2 -->|LP| OC["Output clip<br/>linear up to 0.75"]
  OC --> OUT([Output])
  SC["State clip<br/>ceiling 4.0, α comp."] -.- I1
  L2["s2 is linear<br/>guard clamp at 16"] -.- I2
  I1 -->|"−k·BP"| SUM
  I2 -->|"−LP"| SUM
  classDef nl fill:#FAECE7,stroke:#D85A30,color:#712B13
  class SC,OC nl
```

The same structure redrawn as an op-amp integrator filter. The diode pair stands for the state
clip and the output limiter for the output clip. It is an interpretation, not a reproduction of
an actual circuit.

```mermaid
flowchart LR
  IN([Input]) --> A1["Summing amp Σ"]
  A1 -->|HP| A2["Integrator ∫<br/>C1"]
  D["Diode pair"] -.-|across C1| A2
  A2 -->|BP| A3["Integrator ∫<br/>C2, linear"]
  A3 -->|LP| LIM["Output limiter"]
  LIM --> OUT([Output])
  A2 -->|"R/k (resonance)"| A1
  A3 -->|R| A1
  classDef nl fill:#FAECE7,stroke:#D85A30,color:#712B13
  class D,LIM nl
```

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
| 1 | 0-9 | What feeds a module input | Signal ID |
| 2 | 0-22 | Where a parameter takes its value | Signal ID |
| 3 | 0-27 | Which CC fills a control slot | CC number, or 0 for none |

The run order is read from slot 0 upwards and stops at the first Module ID 0, so a patch shorter
than 32 modules ends itself. It is separate from the module numbering: a module only sees the
current sample's value from something listed before it, and last sample's from something after.

In category 3, CC number 0 means the parameter has no CC. Its control slot then keeps whatever it
already holds, so the parameter can be driven by routing alone.

There is one of every module that makes a sound and one mixer, and **all six are in the default
run order**, so a patch only ever has to route, never to switch something on first.
A mixer is the only kind with no CC on any of its parameters: the default patch points them at
constants instead, each level at 1.0 and each polarity at +0.5, so a mixer with one input routed
passes it through rather than muting it.

#### Entries (CC 98), category 1

| CC 98 | Module input | | CC 98 | Module input |
| ----- | ------ | - | ----- | ------ |
| 0 | EG 1 Gate | | 5 | Amp 1 Audio In |
| 1 | Osc 1 Pitch | | 6 | Amp 1 Mod In |
| 2 | Osc 1 Mod In | | 7 | Mixer 1 In 1 |
| 3 | Filter 1 Audio In | | 8 | Mixer 1 In 2 |
| 4 | Filter 1 Mod In | | 9 | Final Output |

Most of these take what their name suggests, but three do not say it on their face. A Gate is a
threshold rather than a level: an envelope triggers as the signal reaches 0.25 and releases as it
falls back. A Pitch is -0.5 to +0.5 across MIDI notes 0 to 120, so 0.0 is note 60 and a tenth of
a unit is an octave. And a Mod In is taken as it arrives: nothing is held to a range on the way
in, and what gets clamped is the value the module ends up with -- cutoff to the ends of its dial,
pitch to -0.5 and +0.5. A mixer adds without a ceiling, so a loud modulation pins its
destination at one end rather than being trimmed on the way in. The amp is the exception, and
holds its modulation input to -1.0 and +1.0: it is an attenuator, so a modulation may scale its
gain down but never up.

#### Entries (CC 98), categories 2 and 3

| CC 98 | Parameter | | CC 98 | Parameter | | CC 98 | Parameter |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | LFO 1 Rate | | 8 | Osc 1 Wave | | 16 | Filter 1 Mod Amt |
| 1 | LFO 1 Level | | 9 | Osc 1 Coarse Tune | | 17 | Filter 1 Mod Polarity |
| 2 | LFO 1 Polarity | | 10 | Osc 1 Fine Tune | | 18 | Amp 1 Gain |
| 3 | EG 1 Attack | | 11 | Osc 1 Mod Amt | | 19 | Mixer 1 Level 1 |
| 4 | EG 1 Decay | | 12 | Osc 1 Mod Polarity | | 20 | Mixer 1 Polarity 1 |
| 5 | EG 1 Sustain | | 13 | Filter 1 Cutoff | | 21 | Mixer 1 Level 2 |
| 6 | EG 1 Level | | 14 | Filter 1 Resonance | | 22 | Mixer 1 Polarity 2 |
| 7 | EG 1 Polarity | | 15 | Filter 1 Gain | |  |  |

#### Entries (CC 98), category 3 only

These CCs belong to no parameter, so category 2 has no entry for them. Each of General 1-4 fills
two slots, a unipolar and a bipolar one. See the General slots below.

| CC 98 | CC for | Fills |
| ----- | ------ | ----- |
| 23 | General Mod Wheel | General Mod Wheel |
| 24 | General 1 | General Unipolar 1, General Bipolar 1 |
| 25 | General 2 | General Unipolar 2, General Bipolar 2 |
| 26 | General 3 | General Unipolar 3, General Bipolar 3 |
| 27 | General 4 | General Unipolar 4, General Bipolar 4 |

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

#### Signal IDs

| ID | Signal | | ID | Signal | | ID | Signal |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | None (constant 0.0) | | 17 | LFO 1 Polarity ± | | 34 | Mixer 1 Level 1 |
| 1 | Constant 1.0 | | 18 | EG 1 Attack | | 35 | Mixer 1 Polarity 1 ± |
| 2 | Constant 0.5 | | 19 | EG 1 Decay | | 36 | Mixer 1 Level 2 |
| 3 | Constant 0.2 | | 20 | EG 1 Sustain | | 37 | Mixer 1 Polarity 2 ± |
| 4 | Constant 0.1 | | 21 | EG 1 Level | | 38 | Note Pitch ± |
| 5 | Constant -0.1 | | 22 | EG 1 Polarity ± | | 39 | Note Gate |
| 6 | Constant -0.2 | | 23 | Osc 1 Wave | | 40 | Pitch Bend ± |
| 7 | Constant -0.5 | | 24 | Osc 1 Coarse Tune ± | | 41 | General Mod Wheel |
| 8 | Constant -1.0 | | 25 | Osc 1 Fine Tune ± | | 42 | General Unipolar 1 |
| 9 | LFO 1 Output ± | | 26 | Osc 1 Mod Amt | | 43 | General Unipolar 2 |
| 10 | EG 1 Output ± | | 27 | Osc 1 Mod Polarity ± | | 44 | General Unipolar 3 |
| 11 | Osc 1 Output ± | | 28 | Filter 1 Cutoff | | 45 | General Unipolar 4 |
| 12 | Filter 1 Output ± | | 29 | Filter 1 Resonance | | 46 | General Bipolar 1 ± |
| 13 | Amp 1 Output ± | | 30 | Filter 1 Gain | | 47 | General Bipolar 2 ± |
| 14 | Mixer 1 Output ± | | 31 | Filter 1 Mod Amt | | 48 | General Bipolar 3 ± |
| 15 | LFO 1 Rate | | 32 | Filter 1 Mod Polarity ± | | 49 | General Bipolar 4 ± |
| 16 | LFO 1 Level | | 33 | Amp 1 Gain | |  |  |

A **±** marks a signal that swings both ways: a module output reaches -0.5 and +0.5 at full
scale, a bipolar control slot runs -0.5 to +0.5, and a mixer sums two of them and stops at one.
The envelope is the exception: 0.0 to 1.0 at the default Polarity of +0.5, and down to -1.0 once
its Polarity is turned negative. Everything unmarked runs 0.0 to 1.0 -- Note Gate and every
unipolar control slot. The bus carries both kinds under one numbering, so the range belongs to the slot
rather than to the sort of thing that wrote it.

Slots 15-37 hold the values arriving from CC, so a parameter reads its own CC by default. Each
parameter is unipolar or bipolar, and its slot takes the same range. A unipolar one runs 0.0 to
1.0 from CC 4 to CC 124, the span of an envelope, so an envelope pointed at one sweeps the whole
of its dial. A bipolar one runs -0.5 to +0.5 with CC 64 at 0.0, the span of an LFO, so a bipolar
source pointed at one swings it about the middle. The two tune controls are bipolar, since their
middle is no change at all, and so is every Polarity -- the LFO's, the EG's, the mixer's and the two
Mod Polarity controls -- since its sign is what it sets. Pointing a parameter at another slot is what
makes a modulation. A slot with no CC holds 0.0 until one is assigned.

Slots 41-49, the General slots, are control slots that no parameter owns: a CC put on the bus for
any module input or parameter to read. General Mod Wheel reads CC 1, runs 0.0 to 1.0 and powers
up at CC 4, so it is at 0.0 until the wheel moves; nothing is routed to it by default. General 1-4
read CC 16-19 by default, and each puts its CC on the bus both ways at once: General Unipolar 1-4
run 0.0 to 1.0 and General Bipolar 1-4 run -0.5 to +0.5. All four power up at CC 64, so the
unipolar slots start at 0.5 and the bipolar ones at 0.0.

Note Pitch, Note Gate and Pitch Bend are what the keyboard puts on the bus. Note Pitch carries
MIDI notes 0 to 120 as -0.5 to +0.5, the same span the oscillator reads as its whole pitch
range, and Pitch Bend is bipolar too, one unit across the whole wheel: exactly -0.5 and +0.5 at
the ends of its travel and exactly zero at the centre detent, so it can feed a module input
without a mixer to shift it. Note Gate is 0.0 or 1.0, and an envelope triggers at 0.25. Nothing
is routed to Pitch Bend by default.

Slots 0-8 are constants that nothing writes, for inputs that want a fixed value rather than a
source. Signal 0 is also what an entry nobody has set reads as, so an unrouted input is silent
rather than wired to whatever sits in the first slot. Signal 1 is the value an unmodulated input
wants: routing an amp's modulation input to it leaves the amp at full level. Signals 0 and 1 are
the two ends of a unipolar parameter's range and Signals 7 and 2 of a bipolar one, for pinning
one there; Signal 2 is also the middle of a unipolar dial. Signal 3 is a fifth of full scale and
Signal 6 its negative. Signal 4 is the LFO 1 Polarity the default patch uses, which brings the
LFO down to a vibrato depth, and Signal 5 its negative. A constant on a mixer's second input
shifts a signal between the two kinds: -0.5 turns one that runs one way into one that swings
both, and +0.5 the other way round.

Slot 127 is where a parameter with no CC sends its unused value. Nothing should read it.

The ID numbers are not stable across firmware versions. A patch is never saved, so a new module
type, another instance of one, or another signal may renumber everything after it. Read these
tables again after an update.

#### Ranges worth knowing

Both tune controls are centred on CC 64 and move one whole unit per CC step: Coarse Tune a
semitone, reaching 5 octaves either way, and Fine Tune a cent, reaching 60 either way. They are
summed, so any pitch is reachable.

LFO 1 Level and LFO 1 Polarity scale the LFO's output together, as a mixer's Level and Polarity
scale its input: Level from silent at 0.0 (CC 4) to full at 1.0 (CC 124), and Polarity from
negated at -0.5 (CC 4), through silence at 0.0 (CC 64), to unchanged at +0.5 (CC 124). Neither has a
CC: the default patch points Level at the constant 1.0 and Polarity at the constant 0.1, a fifth
of the way to its top.

EG 1 Level and EG 1 Polarity scale the envelope's output the same way, over the same ranges.
Neither has a CC, and the default patch points them at the constants 1.0 and +0.5, which pass
the envelope through as it is.

Each modulation depth is Mod Amt times Mod Polarity, the second doubled: Mod Polarity passes
Mod Amt through at +0.5 (CC 124), silences it at 0.0 (CC 64) and negates it at -0.5 (CC 4), and
the way between scales it, so it sets depth as well as direction. Mod Polarity has no CC and the
default patch points it at the constant 0.5, so either can be the one that is turned: Mod Amt for
a depth in one direction, Mod Polarity for one that crosses zero.

Osc 1 Mod Amt is a depth, not an offset, and it reaches the whole pitch range: at its top a
bipolar source swings the pitch five octaves up and five down. That is a coarse dial for vibrato,
half a semitone per CC step, which is why the default patch brings the LFO down to a fifth with
LFO 1 Polarity. There a semitone of vibrato sits at CC 14 and an octave at the top of the dial.

Filter 1 Gain sets how hard the audio input drives the filter, which is also what decides how far
the filter runs into its own saturation. Its default of CC 64 is the level the oscillator used to
be scaled to on its own. The saturation sits on the resonance rather than the pass band: a low
cutoff passes a loud note nearly clean, while turning the gain up rounds off the resonant peak.

Filter 1 Resonance doubles Q every 30 CC steps up to Q 5.66 at CC 94, and from there rises faster
and faster, without a sudden step, through Q 27 at CC 109 to Q 256 just past CC 118. Above that
the filter oscillates on its own: a sine at the cutoff frequency, growing to its full level of
about 0.5 by CC 123 and holding it to the top of the dial. Low in that range the oscillation
builds slowly and shares the filter with the input; at the top it takes the input over. Its
level holds across the cutoff range down to about 150 Hz and falls below that. Near the top of the
cutoff range it fades out, before its 3rd harmonic folds back as an inharmonic tone: at 48 kHz,
from 8 kHz (CC 108) to 10 kHz (CC 112), modulation included. Above that the resonance acts as at
Q 256. With the cutoff following the keyboard, as in the examples below, it plays as a sine voice.

A mixer takes each input at its own level and its own polarity, then adds them. Level runs from
silent at 0.0 (CC 4) to full at 1.0 (CC 124), and Polarity from negated at -0.5 (CC 4), through
silence at 0.0 (CC 64), to unchanged at +0.5 (CC 124). Levels default to full and polarities to
unchanged, so a mixer with one input routed is a buffer; inverting that one input makes it an
inverter; and inverting only the second makes the mixer a subtractor.

The sum is held to -1.0 and +1.0. Two full-scale signals reach exactly that, so nothing ordinary
is cut; what it stops is a mixer wired back to its own input, which would otherwise double every
sample until the number stopped being a number and took the oscillator or the filter with it.
The filter is held to the same one unit, by a curve rather than a corner: its output passes
untouched up to three quarters of a unit, well above anything the default patch reaches, and
above that bends smoothly onto the limit. Its resonant peak can climb past one unit on a sweep,
and rounding that off makes far weaker high harmonics than a hard edge would fold back down into
the note.

#### Examples

- Vibrato is wired by default -- the LFO goes straight to the oscillator's modulation input --
  so CC 13 sets the depth and CC 3 the rate. CC 99 = 2, CC 98 = 1, CC 6 = 41 takes LFO 1 Level
  from General Mod Wheel, so the wheel brings the vibrato in up to the depth CC 13 sets
- Filter cutoff follows note pitch (keyboard tracking): CC 99 = 1, CC 98 = 4, CC 6 = 38 puts
  Note Pitch on the filter's modulation input in the envelope's place. With the cutoff at CC 64
  and Mod Amt at CC 124, note 60 leaves the cutoff at the middle of its dial and each note moves
  it a semitone
- Filter cutoff swept by the LFO about the middle of its dial: CC 99 = 1, CC 98 = 4, CC 6 = 9.
  A module input is read every sample, so the LFO can run at any rate
- Filter cutoff driven by the envelope instead of its CC: CC 99 = 2, CC 98 = 13, CC 6 = 10. The
  envelope and the cutoff are both unipolar, so it opens the cutoff from the bottom of its dial
  to the top
- Amp gain and filter cutoff share one CC: CC 99 = 3, CC 98 = 18, CC 6 = 74
- Amp at full level with no envelope: CC 99 = 1, CC 98 = 6, CC 6 = 1
- Disconnect the filter's modulation input: CC 99 = 1, CC 98 = 4, CC 6 = 0
- A pitch envelope 60 cents deep: CC 99 = 2, CC 98 = 10, CC 6 = 10 points Osc 1 Fine Tune at the
  envelope, which then sweeps the tuning from in tune up to 60 cents sharp, reached at half the
  envelope's peak
- The envelope drives the filter harder as a note starts: CC 99 = 2, CC 98 = 15, CC 6 = 10 takes
  the filter's input level from silence up to the top of its dial and back
- Pitch swept by the envelope instead of the LFO: CC 99 = 1, CC 98 = 2, CC 6 = 10 puts the
  envelope on the oscillator's modulation input in the LFO's place, then set the depth on CC 13.
  Nothing scales the envelope down on this path, so a semitone is at CC 5 and an octave at CC 16
- Pitch bend, which nothing is routed to by default. CC 99 = 1 with CC 98 = 7 and 8, CC 6 = 38
  and 40 puts Note Pitch and Pitch Bend on Mixer 1's two inputs, and CC 99 = 1, CC 98 = 1,
  CC 6 = 14 makes that sum the oscillator's pitch. Mixer 1 runs ahead of the oscillator, so the
  wheel moves the note in the same sample. Both levels are full, so the wheel reaches five
  octaves either way; CC 99 = 2, CC 98 = 21, CC 6 = 42 takes Mixer 1's second level from General
  Unipolar 1, so CC 16 trims that down to a bend range worth playing
- A CC that bends pitch both ways through the modulation input. Mixer 1 runs ahead of the
  oscillator and is free: CC 99 = 1, CC 98 = 7, CC 6 = 28 puts the filter cutoff's control slot on
  its first input, CC 98 = 8, CC 6 = 7 the constant -0.5 on its second, and CC 98 = 2, CC 6 = 14
  points the oscillator's modulation input at Mixer 1 in the LFO's place. The slot is unipolar, so
  that constant is what centres it on CC 64 as the LFO is on zero. CC 74 now bends the pitch down
  and up around the note, as far as CC 13 allows: a semitone either way at CC 6, an octave at
  CC 28
- A CC that works backwards, which needs a mixer to invert it. Mixer 1 is already running, so it
  only needs wiring: CC 99 = 1, CC 98 = 7, CC 6 = 28 puts the cutoff's control slot on its first
  input and CC 98 = 8, CC 6 = 1 the constant 1.0 on its second, and CC 99 = 2, CC 98 = 20,
  CC 6 = 7 pins the first input's polarity to -0.5, the negating end of its dial, so the mixer
  outputs 1.0 less the CC: the CC mirrored about CC 64. Point the cutoff's own source at the
  mixer with CC 99 = 2, CC 98 = 13, CC 6 = 14 and CC 74 now closes the filter as it rises
- Take the filter out of the chain: CC 99 = 1, CC 98 = 5, CC 6 = 11 points the amp's audio input
  at the oscillator. The filter keeps running and keeps its slot; nothing reads it

#### Notes

- Module inputs (category 1) are read every sample and are not smoothed; parameters (category 2)
  are read once per buffer and are smoothed by their destination. Route a fast source through a
  module input, a stepped one through a parameter
- The smoothing takes two stages (10.7 ms average delay, 99% in 35 ms at 48 kHz), which round off
  the steps of a controller sending sparse CCs (e.g. every 20 ms). Osc 1 Coarse Tune and Fine Tune
  are not smoothed, so that the pitch follows right away
- A parameter source may point at any of the 128 slots. Slots above 49 read 0 until something
  writes them, which leaves a parameter pointed at one at the bottom of a unipolar dial or the
  middle of a bipolar one
- A parameter clamps its value to its own range, 0.0 to 1.0 or -0.5 to +0.5, and its control slot
  carries that same range onto the bus. A unipolar slot routed to a module input runs one way,
  as an envelope does; it takes a mixer and the constant -0.5 to swing both ways about CC 64
- The NRPN CCs are stored as ordinary controls too, so a parameter may be mapped to CC 6 -- which
  then moves it every time a patch edit is sent
- A feedback loop through the bus -- a mixer wired back to its own input at a level below full,
  directly or through other modules -- decays toward zero and can settle on a denormal, which
  x86 computes slowly, so the PC simulator there may slow down. Nothing in the loop flushes it

### Debug UART

- M5Stack AtomS3 Lite: USB CDC (the serial port next to USB MIDI on the same cable)
- Raspberry Pi Pico 2
    - Speed: 115200 bps
    - GP0 and GP1 pins are used by UART0 TX and UART0 RX


### PC Simulators

- Spinel output (experimental): "sim_spinel" -- builds "spms1_main.c" and the runtime in this folder, unmodified,
  for Windows or macOS and runs it in real time, with audio out through PortAudio and MIDI in
  through WinMM or CoreMIDI. Build with `sh sim_spinel/build.sh` (MinGW gcc in Git Bash on
  Windows, clang on macOS), then run `build/sim_spinel/spms1_sim --midi-in NAME`; `--list` shows
  the MIDI inputs
    - The build first regenerates "spms1_main.c" with Spinel, found on the PATH or, on Windows,
      inside WSL. `--no-spinel`, or no Spinel to be found, builds the one already here
    - PortAudio is loaded at run time. The PortAudio project releases source only; on Windows,
      install it into RubyInstaller's MSYS2 with
      `ridk exec pacman -S mingw-w64-ucrt-x86_64-portaudio` (the simulators look there), and on
      macOS with `brew install portaudio`. `SPMS1_PORTAUDIO_DLL` gives a path of your own
    - Not tested on macOS
- CRuby (experimental): "sim_cruby" -- runs "spms1_main.rb" itself on CRuby, with PortAudio
  through the ffi gem, installed as above, and MIDI in through WinMM on Windows and the unimidi
  gem on macOS: `ruby sim_cruby/spms1_sim.rb --midi-in NAME`. The interpreter does not keep up
  with the default patch in real time
    - Not tested on macOS
- Offline WAV output: "sim_offline/spms1_output_wav.rb" -- renders the default patch offline, the
  same modules in the same order with the CC values the synth powers up with, save for two: Decay
  is at the top of its dial so the note carries as far into the render as it can, and Cutoff a
  quarter of the way up so the envelope opening it is what you hear. It does not reproduce the
  signals bus or the run order, so it catches a change in a module, not in a routing


### Checking the Generated Code

What the compiler makes of a change to the per-sample path is worth looking at before flashing it,
and "branchless in Ruby" does not mean branchless in the binary -- the decision is GCC's, and it
depends on the whole function. The steps below are for the Raspberry Pi Pico 2 build. Compile the
Spinel output on its own, from the sketch folder:

```
arm-none-eabi-gcc -c -g -mcpu=cortex-m33 -mthumb -march=armv8-m.main+fp+dsp -mfloat-abi=softfp -mcmse -std=gnu23 -Os -I. -o out.o spms1_main.c
```

The compiler ships with the Arduino-Pico core, under `packages/rp2040/tools/pqt-gcc`. It takes
about a minute. Then `arm-none-eabi-objdump -d out.o` and count the conditional branches inside
`Spms1_main`, and `arm-none-eabi-objdump --dwarf=decodedline out.o` to map an address back to the
line of Ruby it came from -- the generated C carries `#line` directives that point at the `.rb`
files, so the mapping survives all the way down.

Four things to know before reading the output:

- The `-Os` above is not what the synth is built with. "sp_runtime.h" carries
  `#pragma GCC optimize ("O3")`, which overrides whatever is on the command line for that
  translation unit. Passing `-O3` instead changes nothing, and neither does passing `-Os`
- The synth core is not in `.text`. The `#define main` in "sp_runtime.h" puts it in
  `.time_critical`. To prove two builds are the same code,
  `arm-none-eabi-objcopy -O binary --only-section=.time_critical` on each and compare the bytes.
  A comment-only edit moves every `#line` in "spms1_main.c" and nothing else, and this is how to
  confirm it
- A standalone compile runs about 2000 instructions lighter than the linked firmware, because
  `flatten` pulls the sketch's own functions into `Spms1_main` when it is built for real.
  Differences between two standalone builds are reliable; absolute totals are not. Take those
  from the `.elf` the Arduino build leaves in its sketch cache
- A shape that compiles well in a test function may not survive inlining into `Spms1_main`, which
  is about 30000 instructions. Measure the change in the real file, not in a small one


SPMS-1 (type-1) Licence
-----------------------

```
MIDI Synthesizer SPMS-1 (type-1) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
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
- Target files: `sp_*.*`, `re_*.*`
    - Note: Some files for runtime are modified for MCU by ISGK Instruments (Ryo Ishigaki)
