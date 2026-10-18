MIDI Synthesizer SPMS-1 (type-2) v0.0.3
=======================================

- Monophonic semi-modular MIDI Synthesizer for Raspberry Pi Pico 2, made with Spinel (Ruby AOT Compiler)
- Controlled by MIDI as a sound module
- Last-note priority with one note of memory: releasing the newest note while the one before it is still held goes back to that one, legato (for trills)
- 48 kHz audio output: 24 bit through an I2S DAC, or PWM Audio (no DAC needed)
- Oscillator: a sawtooth-to-square morph with pulse width (CC 114), and two modulation inputs of its own for the pulse width (PWM): the envelope on CC 8 and the LFO on CC 103, wired by default; and the sawtooth and the pulse on outputs of their own too
- LFO: triangle (PolyBLAMP) and square (PolyBLEP), each on an output of its own, and a main output crossfading from one to the other (Wave, CC 33)
- Filter: ZDF/TPT State Variable Filter (with a nonlinear leak on the band pass integrator, solved by the one-step Newton method), with low pass and high pass outputs and a main output crossfading from one to the other through a notch (Mode, CC 39)
- Chorus: mono in, stereo out, as a module in the run order
- Delay: stereo, with feedback, as a module in the run order (up to 340 ms)
- Pitch: the note's pitch as a module in the run order, with portamento as an exponential lag (CC 5), pitch bend past it (range on CC 57), a transposition (CC 86 and 70) and a stretch of the keys (CC 22)
- Stereo output: the chorus spreads the mono voice into a left and a right, and the delay keeps them apart
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [日本語版 README](./README.ja.md)


Required Hardware
-----------------

- Raspberry Pi Pico 2 (RP2350)
    - [Raspberry Pi Pico 2](https://www.raspberrypi.com/products/raspberry-pi-pico-2/)
    - I2S DAC hardware (48 kHz/24 bit): uncomment `SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO`
        - Pimoroni [Pico Audio Pack](https://shop.pimoroni.com/products/pico-audio-pack) (PIM544)
        - [Adafruit PCM5102 I2S DAC](https://www.adafruit.com/product/6250) (Product ID: 6250)
        - GY-PCM5102 (PCM5102A I2S DAC Module)
    - Or PWM Audio output, without a DAC (the default of the sketch)
        - L on GP28 and R on GP27, as on the Pimoroni [Pico VGA Demo Base](https://shop.pimoroni.com/products/pimoroni-pico-vga-demo-base) (PIM553)
        - An RC low pass filter on each output is recommended, to take out the PWM ripple
            - It also reduces the radio noise (EMI) radiated from the cables carrying the square waves:
              put it close to the pins, not after the cable
        - Without the RC filter, reduce the level with resistors or the input gain (volume) of the connected device:
          the PWM ripple (3.3 V square waves) may saturate the input (e.g. of an audio interface) and cause beeps or noises,
          even when its level meter looks fine
        - The PWM level (3200 steps) is quantized with 1st-order noise shaping and TPDF dither
        - Each sample is split into 4 PWM periods (PWM carrier: 192 kHz instead of 48 kHz), so the carrier is easier to filter out
          and less likely to cause beeps or whines in active speakers (`SPMS1_PWM_AUDIO_SUBPERIODS`: 1, 2, 4, or 8)
    - NOTE: The RP2350 system clock (sysclk) changes to overclocked 153.6 MHz, set by the sketch's own I2S or PWM Audio output
      ("spms1_pico2_i2s.h" or "spms1_pico2_pwm_audio.h", the same as PRA32-U2's), not by the Arduino-Pico I2S library


Required Software for Modification
----------------------------------

- [Arduino IDE](https://www.arduino.cc/en/software)
    - The sketch is the "spms1" folder: open "spms1/spms1.ino". The editor, the READMEs and the
      tools stay in this folder, outside it
- Arduino-Pico = Raspberry Pi Pico/RP2040/RP2350 (by Earle F. Philhower, III) core
    - Additional Board Manager URL: <https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json>
    - This sketch is tested with version 6.2.0: <https://github.com/earlephilhower/arduino-pico/releases/tag/6.2.0>
    - Info: <https://github.com/earlephilhower/arduino-pico>
    - Board: "Raspberry Pi Pico 2", with USB Stack: "Adafruit TinyUSB" in the "Tools" menu
- Arduino MIDI Library (by Francois Best, lathoub)
    - This sketch is tested with version 5.0.2: <https://github.com/FortySevenEffects/arduino_midi_library/releases/tag/5.0.2>
    - Info: <https://github.com/FortySevenEffects/arduino_midi_library>
- Spinel
    - Release: 2026.09.12 <https://github.com/matz/spinel/tree/2026.09.12>
    - The Spinel output file "spms1_main.c" needs no editing. "spinel_rt_mcu_head.h" in this sketch,
      included at the top of "spinel_rt.h", carries `#define main __attribute__((section(".time_critical"), flatten)) Spms1_main`,
      which renames it and puts the synth core in RAM at the same time. Renaming it by hand
      instead leaves the macro with nothing to match, and the core runs from flash
    - What the core calls while it plays, the MIDI accessors in "spms1_midi_state.h" and the audio
      output in "spms1.ino", is put in RAM as well, with `SPMS1_RAM_FUNC`. From flash it would be
      fetched through the XIP cache, which core 0's MIDI and USB code shares, and a burst of MIDI
      would slow the synth's buffer by evicting it
    - "spms1_main.c" is generated in "spms1" with `spinel spms1_main.rb -c --rbs sig`. The type seeds
      in "spms1/sig" keep the filter states and the parameter smoothing unboxed;
      "spms1/sig/spms1_filter.rbs" and "spms1/sig/spms1_dsp.rbs" say why they are needed
- Ruby (CRuby), to change the patch's numbers or the default patch: they are kept in "spms1_patch.yaml",
  and `ruby patch_gen/spms1_patch_gen.rb` writes them out to "spms1/spms1_patch.rb" (read by
  "spms1/spms1_main.rb"), the tables of "spms1_editor.html", the NRPN tables of this README and
  "README.ja.md", and the module ids and output slots of the dispatch in "spms1/spms1_main.rb"
  (literals, each marked with its constant's name). Run it, then regenerate "spms1/spms1_main.c";
  `--check` only says whether the files are up to date


Usage
-----

### Prebuilt Binary

- "spms1_i2s.ino.uf2" (in the "bin" folder) is for Raspberry Pi Pico 2 and Pimoroni Pico Audio Pack,
  Adafruit PCM5102 I2S DAC, or GY-PCM5102
- "spms1_pwm_audio.ino.uf2" (in the "bin" folder) is for Raspberry Pi Pico 2 with PWM Audio output, built with L on GP28 and R on GP27


### Web Editor

- Cross-platform web-based parameter controller via Web MIDI API: "spms1_editor.html"
    - Its Controls tab shows a slider for each parameter with a CC; those with none are hidden until
      "Show parameters with no CC" is ticked or a CC is given to one, and the choice is remembered
    - Its Patch tab folds the same parameters away in each node, unless something reads their slots;
      the row at the bottom of a node opens it, and Show All and Hide All open or fold every node;
      Init leaves every node open
- Built-in software keyboard for note input and testing
    - Click its heading to hide it, so the patch editor or the controls take its height; the editor remembers
      which, and the keys of the PC keyboard do not play while it is hidden
- Graphical patch editor on its Patch tab
    - Wires module outputs to inputs and parameters, and sets the run order and CC assignments
    - Folds away each module's parameters that have no CC and read their own slot or a constant, under a
      row that opens and closes them; opening one moves the nodes under it down, and closing it moves
      them back. A wire to a folded one ends on that row, and each module's choice is remembered
    - Saves and loads patches as JSON
    - Copies the patch as MIDI bytes or as an NRPN list, or sends it through Web MIDI
    - The side panels (Patch, Run Order, Export) fold to their headings with a click, each remembered;
      with all three folded, the canvas takes the width they leave
- SPMS-1 Web: the synth itself, built into the editor ("spms1_web_synth.js")
    - Select "SPMS-1 Web (Built-in)" in "MIDI Out", and play the soft keyboard (or a MIDI keyboard in "MIDI In")
    - "spms1_main.c" runs in the Web browser as WebAssembly, so it sounds the same as the device
    - See [web/README.md](./web/README.md)


### MIDI Settings

- MIDI Channel: Channel 1
- USB MIDI Input
    - Manufacturer Descriptor: "ISGK Instruments"
    - Device Name: "SPMS-1 (type-2)"
- UART MIDI Input
    - Speed: 31250 bps
    - GP4 and GP5 pins are used by TX and RX, through `SerialPIO`
    - Any pins can be used, TX and RX swapped included, by changing `SPMS1_UART_MIDI_TX_PIN` and
      `SPMS1_UART_MIDI_RX_PIN`
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
  KBD([Keyboard])
  PITCH[Pitch 1]
  LFO[LFO 1]
  EG[EG 1]
  OSC[Osc 1]
  OSC2[Osc 2]
  NOISE[Noise 1]
  MIX2[Mixer 2]
  FILTER[Filter 1]
  AMP[Amp 1]
  CHORUS[Chorus 1]
  DELAY[Delay 1]
  OUT([Audio Out])

  OSC -->|In 1| MIX2
  OSC2 -->|In 2| MIX2
  NOISE -->|In 3| MIX2
  MIX2 --> FILTER
  FILTER --> AMP
  AMP --> CHORUS
  CHORUS -->|L| DELAY
  CHORUS -->|R| DELAY
  DELAY -->|L| OUT
  DELAY -->|R| OUT

  KBD -. Note Gate .-> EG
  KBD -. Note Pitch .-> PITCH
  KBD -. Pitch Bend .-> PITCH
  PITCH -. Pitch .-> OSC
  EG -. Mod 1 .-> OSC
  LFO -. Mod 2 .-> OSC
  EG -. PW Mod 1 .-> OSC
  LFO -. PW Mod 2 .-> OSC
  PITCH -. Pitch .-> OSC2
  EG -. Mod 1 .-> OSC2
  LFO -. Mod 2 .-> OSC2
  EG -. PW Mod 1 .-> OSC2
  LFO -. PW Mod 2 .-> OSC2
  EG -. Mod 1 .-> FILTER
  LFO -. Mod 2 .-> FILTER
  PITCH -. Mod 3 .-> FILTER
  EG -. Mod .-> AMP
```

Each module is processed once per sample, in the run order below. Their parameters -- waveform,
cutoff, gain and the rest -- arrive from CC and are left out of the diagram. Parameter names
shorten Amount to Amt and Polarity to Pol.

The note's pitch reaches the oscillator through Pitch 1, which glides from one note to the next:
portamento. Pitch 1 Glide is on CC 5, Portamento Time in the MIDI spec, and powers up at 0.0, where
the portamento is off and passes the pitch through exactly as it arrives. Pitch Bend comes in on Pitch 1
Bend In, which is added to the output past the glide, so the bend acts at once and reaches the
oscillator and the filter's keyboard tracking alike. Pitch 1 Bend Amt (CC 57) is the bend range,
half a semitone a step: 2 semitones either way at CC 8, where it powers up, an octave at CC 28 and
5 octaves at the top.

The LFO goes straight to the oscillator, both to its pitch and to its pulse width, at its full
level, and to the filter, where Filter 1 Mod 2 Amt (CC 25) powers up at 0.0 and leaves the cutoff
to the envelope until it is turned up. Osc 1 Mod 2 Pol and Filter 1 Mod 2 Pol read the constant
0.1, which brings it down to a vibrato depth on the pitch and a like depth on the cutoff, while Osc 1 PW Mod 2 Pol reads 0.5 and
takes the LFO whole. The pitch from Pitch 1 reaches the filter too, on Filter 1 Mod 3 In, for keyboard tracking: Mod 3
Pol reads +0.5, so CC 9 (Mod 3 Amt) at its top has the cutoff follow the note a semitone for a
semitone, unmoved at note 60. Mod 3 Amt powers up at 0.0, with the tracking off.
The envelope reaches the oscillator's pitch too, on Osc 1 Mod 1 In, for a pitch envelope: Mod 1 Pol
reads +0.5, and Mod 1 Amt (CC 89) powers up at 0.0, with it off. Each modulation depth spans the
whole range of what it moves, so bringing a source down to a musical depth is left to the patch
rather than built into the modules.

Mixer 2 sums the audio ahead of the filter: Osc 1 on In 1, Osc 2 on In 2 and Noise 1's Out on In 3, each
at its own level; In 4 is free. Level 1 and 2 read 0.5, with no CC, so that Balance 1/2 (CC 21)
crossfades Osc 1 and Osc 2: Osc 1 alone at CC 4, half each at CC 64 and Osc 2 alone at CC 124.
It powers up at CC 4, and Level 3 (CC 23) at 0.0, so the default patch plays Osc 1 alone until
they are turned up. Osc 2 plays the note from Pitch 1 as Osc
1 does, tuned against it by its own Pitch Coarse (CC 85) and Pitch Fine (CC 76), 12 cents sharp at
power-up for a slow beat. Its Wave is its own as well, on CC 104 beside Osc 1's on CC 102. It
follows Osc 1 in everything else: its amounts and its pulse width are on Osc 1's CCs, so one CC
moves both.

The voice is mono up to the amp. The chorus takes it and puts out a left and a right, the delay
takes the two sides and keeps them apart, and its two outputs are the two sides of the final
output.

None of this is fixed. NRPN rewrites the run order, every arrow above, and which CC feeds each
parameter.

#### The run order

Every module is in it: one of each kind that makes a sound, the modulation sources first -- the
envelope ahead of the LFO, so that the LFO's Mod Ins can read it in the same sample, as a vibrato
fading in with the envelope does -- Mixer 1 between them and Pitch 1, Pitch 1 just ahead of the
oscillators, Noise 1 after the oscillators, as it is mostly a sound of its own (a modulation
taking it is a sample late, which it does not hear), Mixer 2 between them and the filter, and the
chorus and the delay last:

```mermaid
flowchart LR
  EG[EG 1] ~~~ LFO[LFO 1] ~~~ MIX1[Mixer 1] ~~~ PITCH[Pitch 1] ~~~ OSC[Osc 1] ~~~ OSC2[Osc 2] ~~~ NOISE[Noise 1] ~~~ MIX2[Mixer 2] ~~~ FILTER[Filter 1] ~~~ AMP[Amp 1] ~~~ CHORUS[Chorus 1] ~~~ DELAY[Delay 1]
```

The mixer has nothing routed to it, so it costs its slot every sample and changes nothing until
a patch gives it something. Where it sits is what it buys: a module sees the current sample's
value only from something ahead of it in this line, and last sample's from anything behind.
Mixer 1 can reach the LFO and the envelope, and the oscillators, the filter and the amp can reach
Mixer 1. Pitch 1 comes after all three, so that a modulation of its own -- a bend from the LFO
through Bend In, say -- is this sample's, and before the oscillators and the filter, which read
it in the same sample. Mixer 2 sits between the oscillators and the filter, where it gathers the
audio.

A mixer is what lets two of anything meet, and what makes a signal that runs one way, such as the
envelope, swing both ways. See the examples below.

#### Filter 1

A zero-delay feedback state variable filter. The band pass integrator leaks, more and more as the
band pass bends into a soft clip curve, and that is what holds the resonance down; at small levels
the leak is next to nothing, so the pass band passes nearly clean. The loop equation, leak
included, is solved every sample by the one-step Newton method from the linear solution, which
lands almost on the root. The leak's rate is fixed in time, so the sound does not change with the
sample rate. The low pass state stays linear, with a
clamp at 16 as a guard that ordinary use never reaches. The output clip comes last. At the top of
the resonance dial k turns negative and the loop oscillates.

The filter puts out its low pass and high pass at once, as Out LP and Out HP, each through a DC
blocker and an output clip of its own, and Out, the two crossfaded by Filter 1 Mode (CC 39, Filter
Mode's in PRA32-U2). Each side stays at full over its own half and falls to nothing over the other,
which a mixer's Balance, a straight line, cannot do alone: its ends would be at twice the level, or
its centre at half. At 0.0 (CC 4), where it powers up, Out is the low
pass alone; at 1.0 (CC 124) the high pass alone; and at 0.5 (CC 64) both at full, whose sum, the
input less k·BP, is a notch at the cutoff with both sides of it passed whole. In between the notch
moves off the cutoff, above it toward the low pass and below it toward the high pass, with the
other side at up to 6 dB down. Out is the one the default patch uses, feeding Amp 1, in the slot
the single output had, so a patch that reads that slot hears the low pass until Mode is turned
up. Out is not clipped again: in the pass band one side is all there is, and around the cutoff,
where both are, the notch takes them down. The two factors are smoothed as the other levels
are.

```mermaid
flowchart LR
  IN([Input]) --> SUM((Σ))
  SUM -->|HP| I1["Integrator 1<br/>BP, state s1"]
  I1 -->|BP| I2["Integrator 2<br/>LP, state s2"]
  I2 -->|LP| OC["Output clips<br/>linear up to 0.75"]
  SUM -->|HP| OC
  OC -->|LP| OUT_LP([Out LP])
  OC -->|HP| OUT_HP([Out HP])
  OC -->|LP| XF["Mode<br/>LP / notch / HP"]
  OC -->|HP| XF
  XF --> OUT([Out])
  SC["Nonlinear leak<br/>ceiling 4.0, one-step Newton"] -.- I1
  L2["s2 is linear<br/>guard clamp at 16"] -.- I2
  I1 -->|"−k·BP"| SUM
  I2 -->|"−LP"| SUM
  classDef nl fill:#FAECE7,stroke:#D85A30,color:#712B13
  class SC,OC nl
```

The same structure redrawn as an op-amp integrator filter. The diode pair stands for the
nonlinear leak and the output limiter for the output clip. It is an interpretation, not a reproduction of
an actual circuit.

```mermaid
flowchart LR
  IN([Input]) --> A1["Summing amp Σ"]
  A1 -->|HP| A2["Integrator ∫<br/>C1"]
  D["Diode pair"] -.-|across C1| A2
  A2 -->|BP| A3["Integrator ∫<br/>C2, linear"]
  A3 -->|LP| LIM["Output limiters"]
  A1 -->|HP| LIM
  LIM -->|LP| OUT_LP([Out LP])
  LIM -->|HP| OUT_HP([Out HP])
  LIM -->|LP| XF["Crossfader<br/>Mode"]
  LIM -->|HP| XF
  XF --> OUT([Out])
  A2 -->|"R/k (resonance)"| A1
  A3 -->|R| A1
  classDef nl fill:#FAECE7,stroke:#D85A30,color:#712B13
  class D,LIM nl
```

#### Chorus 1

A mono-in, stereo-out chorus, after PRA32-U2's Chorus FX, put in the chain as an insert, as the
delay is: Mix sets the balance of dry and chorused, rather than a send level. The input goes through a gentle low pass
filter into one short delay line, which is read at two taps. A triangle LFO swings the two taps in
opposite directions about 5.33 ms, so the left and right delayed signals bend in pitch against
each other. Each output is a crossfade of the input with its own tap, so a mono source comes out
spread across the stereo field.

```mermaid
flowchart LR
  IN([Audio In]) --> LPF["Low pass<br/>1-pole"]
  LPF --> DL["Delay line<br/>5.33 ms ± Depth"]
  LFO["Triangle LFO<br/>Rate"] -.->|"−"| DL
  LFO -.->|"+"| DL
  DL -->|"Tap L"| XL["Crossfade<br/>Mix"]
  DL -->|"Tap R"| XR["Crossfade<br/>Mix"]
  IN --> XL
  IN --> XR
  XL --> OUTL([Output L])
  XR --> OUTR([Output R])
```

It needs no limiter and no clip after it: the input is held to one unit on the way in, and the
filter, the reading between two samples and the crossfades are all weighted averages, which cannot
reach past what they average. The delay the taps swing about is fixed.

#### Delay 1

A stereo delay with feedback, after PRA32-U2's Delay FX in its Stereo Delay mode. Each side has a
delay line and a loop of its own: half its input and its delayed signal at the Feedback gain go
through a gentle low pass filter into its line, and its output is a crossfade of its input with
its delayed signal. Time, Feedback and Mix are shared, so the two sides repeat together and keep
the stereo image they came in with.

```mermaid
flowchart LR
  IN([Audio In L / R]) --> H["× 0.5"]
  H --> SUM((Σ))
  SUM --> LPF["Low pass<br/>1-pole"]
  LPF --> DL["Delay line<br/>up to 340 ms"]
  DL --> FB["× Feedback<br/>0 to 0.5"]
  FB --> SUM
  DL --> X["Crossfade<br/>Mix"]
  IN --> X
  X --> OUT([Output L / R])
```

The diagram is one side; the other is the same. It needs no limiter and no clip after it. With
half the input coming in and at most half the delayed signal going round again, what is written
back stays within one unit as long as the delayed signal does, and it starts from silence; the
filter, the reading between two samples and the crossfade are all weighted averages, which cannot
reach past what they average. The price is that the first repeat comes 6 dB under the dry signal.
Each input is held to one unit on the way in, as the amp holds its modulation input, so whatever
is routed to it the bound holds.

### Patch Editing (NRPN)

The patch is data, and NRPN rewrites it while the synth is running: which modules run and in what
order, what feeds each module input, where each parameter takes its value from, and which CC fills
each control slot. Every module reads from a numbered signal slot and writes to one, so rewiring is
a matter of changing slot numbers. Each parameter also has a control slot of its own, which its CC
fills and which only it can read: a parameter source of 127 names it, and no slot number reaches
it from anywhere else.

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
| 1 | 0-35 | What feeds a module input | Signal ID |
| 2 | 0-28, 34-96 | Where a parameter takes its value | Signal ID, or 127 for its own control slot |
| 3 | 0-96 | Which CC fills a control slot | CC number, or 0 for none |

The run order is read from slot 0 upwards and stops at the first Module ID 0, so a patch shorter
than 32 modules ends itself. It is separate from the module numbering: a module only sees the
current sample's value from something listed before it, and last sample's from something after.
A module listed more than once runs once, at the slot written last, as if its other slots were
not there: the last write wins, whether its slot is ahead of the others or after them. A module
written to a new slot moves there, and the module that slot held leaves the order.

In category 3, CC number 0 means the parameter has no CC. Its control slot then holds 0.0, whatever
CC it had before, so the patch alone sets what the parameter reads.

There are two oscillators, one of every other module that makes a sound, two mixers, one chorus,
one delay, one pitch module and one noise source, and **all twelve are in the default run order**, so a patch only ever has to route, never to switch something
on first. The synth is built to keep time with every module running, so taking one out of the
order is never what makes a patch fit; to leave one out of the sound, route around it and let it
run unread (see the examples below).
On each mixer, Balance 1/2 has the CC, CC 119 on Mixer 1 and CC 21 on Mixer 2, where Level 2 had
it, and Level 1 and 2 have none and read 0.5, so that the balance crossfades the pair. Mixer 1's
balance powers up at the centre, CC 64, passing each at half, and Mixer 2's at CC 4, Osc 1
alone. Mixer 2 Level 3 has a CC too (CC 23); the default patch points the other levels and Out
Level at 1.0 and each polarity at +0.5, so an input on one of them passes through rather than
being muted -- but for Mixer 1 Level 3 and 4, which read their own slots, 0.0, so those two
inputs start closed.

#### Entries (CC 98), category 1

<!-- patch_gen inputs -->

| CC 98 | Module input | | CC 98 | Module input |
| ----- | ------ | - | ----- | ------ |
| 0 | EG 1 Gate In | | 17 | Filter 1 Mod 2 In |
| 1 | Osc 1 Pitch In | | 18 | Filter 1 Mod 3 In |
| 2 | Osc 1 Mod 2 In | | 19 | Pitch 1 Bend In |
| 3 | Filter 1 Audio In | | 20 | LFO 1 Level Mod In |
| 4 | Filter 1 Mod 1 In | | 21 | Osc 1 Mod 1 In |
| 5 | Amp 1 Audio In | | 24 | Osc 2 Pitch In |
| 6 | Amp 1 Mod In | | 25 | Osc 2 Mod 1 In |
| 7 | Mixer 1 In 1 | | 26 | Osc 2 Mod 2 In |
| 8 | Mixer 1 In 2 | | 27 | Osc 2 PW Mod 2 In |
| 9 | Chorus 1 Audio In | | 28 | Mixer 1 In 3 |
| 10 | Delay 1 Audio In L | | 29 | Mixer 1 In 4 |
| 11 | Delay 1 Audio In R | | 30 | Mixer 2 In 1 |
| 12 | Final Output L | | 31 | Mixer 2 In 2 |
| 13 | Final Output R | | 32 | Mixer 2 In 3 |
| 14 | Pitch 1 Pitch In | | 33 | Mixer 2 In 4 |
| 15 | Osc 1 PW Mod 2 In | | 34 | Osc 1 PW Mod 1 In |
| 16 | LFO 1 Rate Mod In | | 35 | Osc 2 PW Mod 1 In |

<!-- patch_gen end -->

Most of these take what their name suggests, but three do not say it on their face. A Gate is a
threshold rather than a level: an envelope triggers as the signal reaches 0.25 and releases as it
falls back. A pitch, as Note Pitch carries one to Pitch In, is -0.5 to +0.5 across MIDI notes
0 to 120, so 0.0 is note 60 and a tenth of a unit is an octave. And a Mod In is taken as it arrives:
nothing is held to a range on the way in, and what gets clamped is the value the module ends up with
-- cutoff to the ends of its dial, pitch to -0.5 and +0.5, pulse width to 0.0 and 1.0. The
oscillator's Pitch In, Mod 1 In, Mod 2 In, PW Mod 1 In and PW Mod 2 In are Mod Ins too. A mixer adds without a
ceiling, so a loud modulation pins its destination at one
end rather than being trimmed on the way in. The amp is the exception, and holds its modulation
input to -1.0 and +1.0: it is an attenuator, so a modulation may scale its gain down but never up.
The chorus and the delay hold their audio inputs to the same one unit. Pitch 1 Pitch In takes anything,
as a Mod In does, and puts out what it takes, glided, bent and transposed.

The two sides of the final output are read separately, so either can be pointed anywhere; point
both at the same signal for a mono output.

#### Entries (CC 98), categories 2 and 3

<!-- patch_gen params -->

| CC 98 | Parameter | | CC 98 | Parameter | | CC 98 | Parameter |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | LFO 1 Rate | | 35 | Osc 1 Pulse Width | | 67 | Osc 2 PW Mod 2 Pol |
| 1 | LFO 1 Level | | 36 | Osc 1 PW Mod 2 Amt | | 71 | Mixer 1 Level 3 |
| 3 | EG 1 Attack | | 37 | Osc 1 PW Mod 2 Pol | | 72 | Mixer 1 Pol 3 |
| 4 | EG 1 Decay | | 40 | LFO 1 Rate Mod Amt | | 73 | Mixer 1 Level 4 |
| 5 | EG 1 Sustain | | 41 | LFO 1 Rate Mod Pol | | 74 | Mixer 1 Pol 4 |
| 6 | EG 1 Level | | 44 | Filter 1 Mod 2 Amt | | 75 | Mixer 2 Level 1 |
| 8 | Osc 1 Wave | | 45 | Filter 1 Mod 2 Pol | | 76 | Mixer 2 Pol 1 |
| 9 | Osc 1 Pitch Coarse | | 46 | Filter 1 Mod 3 Amt | | 77 | Mixer 2 Level 2 |
| 10 | Osc 1 Pitch Fine | | 47 | Filter 1 Mod 3 Pol | | 78 | Mixer 2 Pol 2 |
| 11 | Osc 1 Mod 2 Amt | | 48 | Pitch 1 Bend Amt | | 79 | Mixer 2 Level 3 |
| 12 | Osc 1 Mod 2 Pol | | 49 | Pitch 1 Bend Pol | | 80 | Mixer 2 Pol 3 |
| 13 | Filter 1 Cutoff | | 50 | LFO 1 Level Mod Amt | | 81 | Mixer 2 Level 4 |
| 14 | Filter 1 Resonance | | 51 | LFO 1 Level Mod Pol | | 82 | Mixer 2 Pol 4 |
| 15 | Filter 1 Gain | | 52 | Pitch 1 Coarse | | 83 | Mixer 2 Out Level |
| 16 | Filter 1 Mod 1 Amt | | 53 | Pitch 1 Fine | | 85 | Mixer 1 Balance 1/2 |
| 17 | Filter 1 Mod 1 Pol | | 54 | Mixer 1 Out Level | | 86 | Mixer 1 Balance 3/4 |
| 18 | Amp 1 Gain | | 55 | Osc 1 Mod 1 Amt | | 87 | Mixer 2 Balance 1/2 |
| 19 | Mixer 1 Level 1 | | 56 | Osc 1 Mod 1 Pol | | 88 | Mixer 2 Balance 3/4 |
| 20 | Mixer 1 Pol 1 | | 57 | Noise 1 Level | | 89 | Pitch 1 Stretch |
| 21 | Mixer 1 Level 2 | | 58 | Osc 2 Wave | | 90 | Filter 1 Mode |
| 22 | Mixer 1 Pol 2 | | 59 | Osc 2 Pitch Coarse | | 91 | Osc 1 PW Mod 1 Amt |
| 23 | Chorus 1 Rate | | 60 | Osc 2 Pitch Fine | | 92 | Osc 1 PW Mod 1 Pol |
| 24 | Chorus 1 Depth | | 61 | Osc 2 Mod 1 Amt | | 93 | Osc 2 PW Mod 1 Amt |
| 25 | Chorus 1 Mix | | 62 | Osc 2 Mod 1 Pol | | 94 | Osc 2 PW Mod 1 Pol |
| 26 | Delay 1 Time | | 63 | Osc 2 Mod 2 Amt | | 95 | Noise 1 Color |
| 27 | Delay 1 Feedback | | 64 | Osc 2 Mod 2 Pol | | 96 | LFO 1 Wave |
| 28 | Delay 1 Mix | | 65 | Osc 2 Pulse Width | |  |  |
| 34 | Pitch 1 Glide | | 66 | Osc 2 PW Mod 2 Amt | |  |  |

<!-- patch_gen end -->

#### Entries (CC 98), category 3 only

These CCs belong to no parameter, so category 2 has no entry for them. Each of General 1-4 fills
two slots, a unipolar and a bipolar one. See the General slots below.

<!-- patch_gen generals -->

| CC 98 | CC for | Fills |
| ----- | ------ | ----- |
| 29 | General Mod Wheel | General Mod Wheel |
| 30 | General 1 | General Unipolar 1, General Bipolar 1 |
| 31 | General 2 | General Unipolar 2, General Bipolar 2 |
| 32 | General 3 | General Unipolar 3, General Bipolar 3 |
| 33 | General 4 | General Unipolar 4, General Bipolar 4 |

<!-- patch_gen end -->

#### Module IDs

<!-- patch_gen modules -->

| ID | Module |
| ----- | ------ |
| 0 | None (ends the run order) |
| 1 | LFO 1 |
| 2 | EG 1 |
| 3 | Osc 1 |
| 4 | Filter 1 |
| 5 | Amp 1 |
| 6 | Mixer 1 |
| 7 | Chorus 1 |
| 8 | Delay 1 |
| 9 | Pitch 1 |
| 10 | Noise 1 |
| 11 | Osc 2 |
| 12 | Mixer 2 |

<!-- patch_gen end -->

#### Signal IDs

<!-- patch_gen signals -->

| ID | Signal | | ID | Signal | | ID | Signal |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | None (constant 0.0) | | 15 | Chorus 1 Output L ± | | 59 | General Bipolar 4 ± |
| 1 | Constant 1.0 | | 16 | Chorus 1 Output R ± | | 60 | Pitch 1 Output ± |
| 2 | Constant 0.5 | | 17 | Delay 1 Output L ± | | 66 | Filter 1 Output HP ± |
| 3 | Constant 0.2 | | 18 | Delay 1 Output R ± | | 86 | Noise 1 Output ± |
| 4 | Constant 0.1 | | 48 | Note Pitch ± | | 88 | Osc 2 Output ± |
| 5 | Constant -0.1 | | 49 | Note Gate | | 106 | Mixer 2 Output ± |
| 6 | Constant -0.2 | | 50 | Pitch Bend ± | | 116 | Noise 1 Output Red ± |
| 7 | Constant -0.5 | | 51 | General Mod Wheel | | 117 | Filter 1 Output LP ± |
| 8 | Constant -1.0 | | 52 | General Unipolar 1 | | 118 | Osc 1 Output Saw ± |
| 9 | LFO 1 Output ± | | 53 | General Unipolar 2 | | 119 | Osc 1 Output Pulse ± |
| 10 | EG 1 Output | | 54 | General Unipolar 3 | | 120 | Osc 2 Output Saw ± |
| 11 | Osc 1 Output ± | | 55 | General Unipolar 4 | | 121 | Osc 2 Output Pulse ± |
| 12 | Filter 1 Output ± | | 56 | General Bipolar 1 ± | | 122 | Noise 1 Output White ± |
| 13 | Amp 1 Output ± | | 57 | General Bipolar 2 ± | | 123 | LFO 1 Output Triangle ± |
| 14 | Mixer 1 Output ± | | 58 | General Bipolar 3 ± | | 124 | LFO 1 Output Square ± |

<!-- patch_gen end -->

A **±** marks a signal that swings both ways: a module output reaches -0.5 and +0.5 at full
scale, a bipolar General slot runs -0.5 to +0.5, and a mixer sums two of them and stops at one.
Everything unmarked runs 0.0 to 1.0 -- the envelope, Note Gate and the unipolar General slots. The
bus carries both kinds under one numbering, so the range belongs to the slot rather than to the
sort of thing that wrote it. The numbers missing from the table are free; 127 is not a slot but a
parameter's own control slot.

A parameter's own control slot holds the value arriving from its CC, off the bus, and a parameter
reads it by default: Signal ID 127 in category 2. Each parameter is unipolar or bipolar, and its
slot takes the same range. A unipolar one
runs 0.0 to 1.0 from CC 4 to CC 124, the span of an envelope, so an envelope pointed at one sweeps
the whole of its dial. A bipolar one runs -0.5 to +0.5 with CC 64 at 0.0, the span of an LFO, so a
bipolar source pointed at one swings it about the middle. Osc 1 Pitch Coarse and Fine and Pitch 1 Coarse and
Fine are bipolar, since their middle is no change at all, and so is every Pol -- the mixer's two and
the eight Mod Pol controls and Pitch 1 Bend Pol -- since its sign is what it sets. Pointing a parameter at a
slot on the bus is what makes a modulation. A control slot with no CC holds 0.0. No input or other
parameter can read a parameter's control slot: a CC meant for more than one parameter, or for a
module input, goes on a General slot, or is given to each parameter in category 3, as Osc 1 and
Osc 2 share theirs.

Slots 51-59, the General slots, are control slots that no parameter owns: a CC put on the bus for
any module input or parameter to read. General Mod Wheel reads CC 1, runs 0.0 to 1.0 and powers
up at CC 4, so it is at 0.0 until the wheel moves; nothing is routed to it by default. General 1-4
read CC 16, 17, 18 and 19 by default, and each puts its CC on the bus both ways at once: General Unipolar 1-4
run 0.0 to 1.0 and General Bipolar 1-4 run -0.5 to +0.5. All four power up at CC 64, so the
unipolar slots start at 0.5 and the bipolar ones at 0.0.

Note Pitch, Note Gate and Pitch Bend are what the keyboard puts on the bus. Note Pitch carries
MIDI notes 0 to 120 as -0.5 to +0.5, the same span the oscillator reads as its whole pitch
range, and Pitch Bend is bipolar too, one unit across the whole wheel: exactly -0.5 and +0.5 at
the ends of its travel and exactly zero at the centre detent, so it can feed a module input
without a mixer to shift it. Note Gate is 0.0 or 1.0, and an envelope triggers at 0.25. Pitch Bend
is routed to Pitch 1 Bend In by default.

The newest note sounds, and the note it took over from is remembered while it is still held: one
note, no more. When the newest note is released, the remembered one comes back with Note Gate
left at 1.0, so the envelopes go on without a new attack, and holding one key while tapping
another plays a trill. Releasing the remembered note only forgets it, and with three keys held,
releasing the newest goes back to the second, and releasing that closes the gate, even with the
first still held.

Slots 0-8 are constants that nothing writes, for inputs that want a fixed value rather than a
source. Signal 0 is also what an entry nobody has set reads as, so an unrouted input is silent
rather than wired to whatever sits in the first slot. Signal 1 is the value an unmodulated input
wants: routing an amp's modulation input to it leaves the amp at full level. Signals 0 and 1 are the
two ends of a unipolar parameter's range and Signals 7 and 2 of a bipolar one, for pinning one
there; Signal 2 is also the middle of a unipolar dial. Signal 3 is a fifth of full scale and Signal
6 its negative. Signal 4 is the Osc 1 and Filter 1 Mod 2 Pol the default patch uses, which brings the
LFO down to a vibrato depth, and Signal 5 its negative. A constant on a mixer's second input shifts
a signal between the two kinds: -0.5 turns one that runs one way into one that swings both, and +0.5
the other way round.

The ID numbers are not stable across firmware versions. A patch is never saved, so a new module
type, another instance of one, or another signal may renumber everything after it. Read these
tables again after an update.

#### Ranges worth knowing

Pitch 1 Coarse (CC 86) and Fine (CC 70) transpose the pitch Pitch 1 hands on, after
the glide, so a change acts at once and reaches the oscillator and the filter's keyboard tracking
alike. Both are centred on CC 64 and move one whole unit per CC step: Coarse a semitone,
reaching 5 octaves either way, and Fine a cent, reaching 60 either way. They are summed, so
any pitch is reachable. Osc 1 Pitch Coarse and Pitch Fine have the same ranges and add to the
oscillator alone; they have no CC and stay at 0.0 by default, for an interval or a detune between
oscillators.

Pitch 1 Stretch (CC 22) widens the keys about note 60, ahead of the glide, by multiplying Pitch
In: every interval from note 60 grows by the same share, so the stretch is often given as how
much an octave widens. At 0.0 (CC 4), where it powers up, the keys are as they are; from CC 5 the
widening grows by a semitone's ratio a step, as the envelope's times do: 1.2 cents an octave at
CC 5, 38 at CC 64, and a whole octave at CC 124, which doubles every interval and turns the
keyboard into whole tones. The low end is a piano's stretch tuning, a few cents an octave. The
bend and the transposition come after it and stay as they are, and turning it glides the pitch
rather than stepping it. At its top, notes more than 30 semitones from note 60 run past the
oscillator's range.

LFO 1 puts out a triangle and a square at once, each on an output of its own, Out Triangle and
Out Square, and the two crossfaded on Out. The triangle has its corners rounded off by PolyBLAMP
and the square its steps by PolyBLEP, so at the top of the rate range, 220 Hz, where the LFO is an
audible tone, the square's aliases are 41 dB down on it, rather than 24 dB without. The square is
the triangle's sign: +0.5 while the triangle is above zero, stepping where it crosses. LFO 1 Wave
(CC 33, LFO Wave's in PRA32-U2) crossfades Out in a straight line from the triangle at 0.0 (CC 4),
where it powers up, to the square at 1.0 (CC 124), and is smoothed as the level is. Out keeps the
slot the LFO's one output had, and is what the default patch routes, so the LFO is a triangle
until Wave is turned up.

LFO 1 Level scales the LFO's outputs, as a mixer's Level scales its input: from silent at 0.0
(CC 4) to full at 1.0 (CC 124). It is on CC 113 and powers up at 1.0, passing the LFO through as
it is. LFO 1 Level Mod In adds to it, held to the same range, by Level Mod Amt times Level Mod
Pol, and it takes General Mod Wheel by default at a depth of 1.0 (neither has a CC; they read 1.0
and +0.5). With Level turned down, the wheel brings the LFO in, up to full at its top. Turning the LFO the other way up is for the destination's
Mod Pol, or a mixer's Pol.

LFO 1 Rate Mod In moves the rate by LFO 1 Rate Mod Amt times Rate Mod Pol, as Osc 1 Mod 2 In moves the
oscillator's pitch: a unit of input times depth is the whole rate range, ten octaves, so 0.1 is an
octave. Neither has a CC, and the default patch points them at 1.0 and +0.5, a depth of 1.0, and
leaves Rate Mod In unrouted, so routing a source to it is all it takes. Both of the LFO's Mod Ins
are read every fourth sample,
where the LFO works out its rate, rather than every sample as most module inputs are.

EG 1 Level scales the envelope's output the same way, over the same range. It has no CC, and the
default patch points it at the constant 1.0, which passes the envelope through as it is. The
envelope runs one way, 0.0 to 1.0; turning it the other way up is for the destination's Mod Pol,
or a mixer's Pol.

Each modulation depth is Mod Amt times Mod Pol, the second doubled: Mod Pol passes
Mod Amt through at +0.5 (CC 124), silences it at 0.0 (CC 64) and negates it at -0.5 (CC 4), and
the way between scales it, so it sets depth as well as direction. Mod Pol has no CC and the
default patch points it at a constant, so either can be the one that is turned: Mod Amt for
a depth in one direction, Mod Pol for one that crosses zero.

Osc 1 Mod 2 Amt is a depth, not an offset, and it reaches the whole pitch range: at its top a
bipolar source swings the pitch five octaves up and five down. That is a coarse dial for vibrato,
half a semitone per CC step, which is why the default patch brings the LFO down to a fifth of its depth
with Osc 1 Mod 2 Pol (0.1). There a semitone of vibrato sits at CC 14 and an octave at the top of the
dial.

Osc 1 Pitch In is where the note comes in, from Pitch 1 in the default patch. It has no depth:
the pitch it takes is added whole, so the note plays in tune, a key a semitone.

Osc 1 Mod 1 In moves the pitch as Mod 2 In does, by Mod 1 Amt times Mod 1 Pol, and takes the
envelope in the default patch, for a pitch envelope. Mod 1 Amt is on CC 89 and powers up at 0.0,
so the envelope leaves the pitch alone until it is turned up; Mod 1 Pol reads +0.5, not 0.1 as
Mod 2 Pol does, as the envelope is unipolar and an envelope's sweep is wider than a vibrato's.

Osc 1 Pulse Width shifts the second of the two sawtooths that the morph is made of, from half a
cycle at 0.0 (CC 4) toward a whole one at 1.0 (CC 124). At the square end of Osc 1 Wave that is a
pulse of 50% at CC 4, 25% at CC 64 and 0%, silence, at CC 124; it is on CC 114.
Two modulations move it as Mod 1 In and Mod 2 In move the pitch, each by its Amt times its Pol:
Osc 1 PW Mod 1 In, which the default patch feeds the envelope, by PW Mod 1 Amt (CC 8), and PW Mod
2 In, which it feeds the LFO, by PW Mod 2 Amt (CC 103). The two CCs are EG Mod Dst's and LFO Mod
Dst's in PRA32-U2, whose EG Mod Amt and LFO Mod Amt are on CC 89 and 13 as Mod 1 Amt and Mod 2 Amt
are here: rather than switch one amount between the pitch and the pulse width, each destination
has an amount of its own, so the envelope and the LFO can each move both at once with no rewiring.
Both power up at 0.0. A unit of modulation is the whole pulse width range, so at the top of PW
Mod 2 Amt the LFO swings the pulse width half the range either way: with Pulse Width at CC 64,
from 50% to nearly 0%; and at the top of PW Mod 1 Amt the envelope sweeps it across the whole
range, from Pulse Width up. The pulse width the modulations add up to is held to 0.0 to 1.0.

Each oscillator puts out the two ends of its morph on their own as well, whatever Wave is: Out
Saw, the sawtooth, and Out Pulse, the pulse at the pulse width, as Out is at the square end of
Wave. Both run at the same level as Out, -0.5 to +0.5, and the default patch uses neither, so a
mixer can take the two from one oscillator at levels of their own, or one oscillator can feed a
saw to one place and a pulse to another.

Noise 1 puts out two noises from one generator, at Noise 1 Level, each on an output of its own
and the two crossfaded on Out. Out White is white noise,
flat across the spectrum: from silence at 0.0 to noise filling -0.5 to +0.5 at 1.0, the
oscillator's range. Out Red is the same noise through a one-pole low pass, falling 6 dB an octave
above a fixed cutoff on the A of a MIDI note number, note 21 (A0, 27.5 Hz), so across the whole
audible band. A gain holds it at the white's RMS over the square root of 2, and it is held to -0.5
to +0.5, which cuts the rarest peaks, 1.5% of the samples. Noise 1 Color (CC 115) crossfades Out
in a straight line from the white at 0.0 (CC 4), where it powers up, to the red at 1.0 (CC 124),
each end as its own output is, so the red end is 3 dB down. Out keeps the slot the white had, and
is what the default patch puts on Mixer 2, so the noise there is white until Color is turned up,
and darkens as it is. Color is smoothed as the level is. The level has no CC and reads 1.0, so
the noise runs at full level and Mixer 2 Level 3 (CC 23), or the depth of whatever it modulates,
sets how much of it is heard. The level is smoothed as the other levels are. The noise repeats only after 2^32 samples,
over a day at 48 kHz, and starts the same every time, so a render comes out the same.

Filter 1 Gain sets how hard the audio input drives the filter, which is also what decides how far
the filter runs into its own saturation. Two oscillators at full level on Mixer 2 drive the filter
twice as hard as one: turn Gain down to keep the level, or leave it up to drive the saturation.
The saturation sits on the resonance rather than the pass band: a low
cutoff passes a loud note nearly clean, while turning the gain up rounds off the resonant peak.

Filter 1 Resonance raises the resonant peak 6 dB every 30 CC steps, Q doubling each time, up to
Q 5.66 at CC 94, and from there Q rises faster and faster, without a sudden step, through Q 29
at CC 109 to Q 256 at CC 118. Above that the filter oscillates on its own: a sine at the cutoff
frequency, growing to its full level of about 0.5 by CC 123 and holding it to the top of the
dial. Low in that range the oscillation builds slowly and shares the filter with the input; at
the top it takes the input over. Its level holds across the cutoff range down to about 150 Hz
and falls below that. Near the top of the cutoff range it fades out, before its 3rd harmonic
folds back as an inharmonic tone: at 48 kHz, from 8 kHz (CC 108) to 10 kHz (CC 112), modulation
included. Above that the resonance acts as at Q 256. With the cutoff following the keyboard, as
in the examples below, it plays as a sine voice.

A mixer takes each of its four inputs at its own level and its own polarity, then adds them. Level runs from
silent at 0.0 (CC 4) to full at 1.0 (CC 124), and Pol from negated at -0.5 (CC 4), through
silence at 0.0 (CC 64), to unchanged at +0.5 (CC 124). Levels default to full and polarities to
unchanged, so a mixer with one input routed is a buffer; inverting that one input makes it an
inverter; and inverting only another makes the mixer a subtractor. Out Level then scales the
sum, over the same range as Level and also at 1.0 by default, so one control can take a blend of
two sources up and down together; it is applied before the sum is held to its range, so turning
it down also brings a sum that would have been cut back inside it.

Balance 1/2 and Balance 3/4 crossfade each pair of inputs in a straight line, from -0.5 (CC 4)
through 0.0 (CC 64) to +0.5 (CC 124). The two inputs' levels are multiplied by 2.0 and 0.0 at
-0.5, by 1.0 each at 0.0, and by 0.0 and 2.0 at +0.5, always adding up to 2.0. At the centre the
mixer is as it was without them, and a pair
at the same level keeps the same total whichever way its balance is turned. For a crossfader, or a
selector at either end, set both levels of the pair to 0.5 (CC 64): each input then passes at
half at the centre and as it is at its own end -- a mix control for two oscillators, or a switch
between two modulation sources. Balance 1/2 of each mixer is set up so by default, on CC 119 and
CC 21; Balance 3/4 reads its own slot, the centre, with no CC. Like every parameter, a balance is
read once a buffer and smoothed, so a selector driven by a gate crossfades in about 35 ms
rather than switching on the sample.

The sum is held to -1.0 and +1.0. Two full-scale signals reach exactly that, and an oscillator
or the noise at full level is half of one, so nothing ordinary is cut -- on Mixer 2, two
oscillators and the noise all at full level would be, which Out Level is there to prevent. A narrow
pulse is the exception: its peak-to-peak stays one unit, but held round zero it spends most of
its time just below zero and spikes up to 0.95, so one on top of another source, or two together,
have their spikes cut off -- turn the levels down when layering them. What the limit stops is a mixer wired back to its own input, which would otherwise double every
sample until the number stopped being a number and took the oscillator or the filter with it.
The filter is held to the same one unit, by a curve rather than a corner: its output passes
untouched up to three quarters of a unit, well above anything the default patch reaches, and
above that bends smoothly onto the limit. Its resonant peak can climb past one unit on a sweep,
and rounding that off makes far weaker high harmonics than a hard edge would fold back down into
the note.

The three Chorus 1 parameters are unipolar and move in steps of 1/120. Rate is read as a note
number, a semitone a step, as LFO 1 Rate is: 0.015 Hz at CC 4, 0.48 Hz at CC 64 and 15.4 Hz at
CC 124, the default divided and multiplied by 32. Depth is how far each tap swings either side of 5.33 ms, in a straight line from not at
all at CC 4, through 2.63 ms at CC 64, to 5.25 ms at CC 124. Mix is each tap's share of its side's
crossfade: the dry input alone at CC 4, half and half at CC 64, and only the taps at CC 124, a vibrato on each side, the two moving opposite ways.
All three power up at CC 64. The halves of the crossfade are what hold the chorus to one unit, so
at the default the dry signal is 6 dB down, and the sum with the tap makes up some of it.

The three Delay 1 parameters are unipolar and move in steps of 1/120, as every unipolar dial
does. Time runs in a straight line, 2.83 ms a step, from 0 at CC 4 to 340 ms at CC 124, and is
clipped to 2.83 ms at the bottom, so it holds 2.83 ms up to CC 5; it is 170 ms at CC 64. Turning
it bends the pitch of the repeats, by at most 25%, as a tape delay's would, and they reach the new
time a moment later. Feedback is the gain from the repeats back into the line, from 0 at CC 4, a
single repeat, to 0.5 at CC 124, where each repeat comes back 6 dB down and a little darker; it is
0.25 at CC 64. Mix is the repeats' share of the crossfade, from the dry input alone at CC 4 to the
repeats alone at CC 124, half and half at CC 64. Time and Feedback power up at CC 64 and Mix at
CC 34, 0.25: the dry signal is 2.5 dB down and the first repeat about 16 dB under it.

Pitch 1 Glide is unipolar and moves in steps of 1/120, a semitone of time a step, as EG 1 Decay
does and over the same range: from about 10 ms at CC 5 through 320 ms at CC 64 to 10.24 s at CC 124,
each the time to come within 1/1024 of the way, where a glide of an octave is a hundredth of a
semitone short; nine tenths of the way take a third of it. At CC 4 and below, 0.0, the portamento
is off, and its output is its input exactly. The glide is exponential, quick at first and slowing
as it lands, as an analog synth's portamento is, and it starts from wherever the output is, so a
note played during a glide takes it over from there. The time is not smoothed: a change in it
changes only how fast the output moves, so it cannot step it.

#### Examples

- Vibrato is wired by default -- the LFO goes straight to the oscillator's Mod 2 input --
  so CC 13 sets the depth and CC 3 the rate. The mod wheel adds to LFO 1 Level (CC 113), so with
  CC 113 turned down to CC 4 the wheel brings the vibrato in, up to the depth CC 13 sets
- The LFO reaches the filter's Mod 2 input by default too, so CC 25 sweeps the cutoff with it, on
  top of the envelope on Mod 1
- A second oscillator is wired by default too, on Mixer 2's second input, so CC 21 crossfades to
  it, half each at CC 64, beating slowly against Osc 1 from the 12 cents of CC 76's power-up
  value. CC 85 and 76 tune it: CC 85 = 76 an octave up, CC 85 = 71 a fifth, CC 76 = 64 in unison
- Noise is wired by default too, its Out on Mixer 2's third input beside the oscillators, so CC 23
  brings it in under the note, at a tenth of the oscillator's level at CC 16. CC 99 = 2,
  CC 98 = 75, CC 6 = 0 points Mixer 2 Level 1 at 0.0, taking Osc 1 out and leaving the noise alone,
  through the filter. CC 115 (Color) turns it from
  white to red
- Keyboard tracking is wired by default as well, the pitch from Pitch 1 on the filter's Mod 3 input,
  so CC 9 sets how far the cutoff follows the keys: all the way at CC 124, not at all at CC 4,
  where it powers up
- A pitch envelope is wired by default too -- the envelope on the oscillator's Mod 1 input --
  so CC 89 sets its depth. Nothing scales the envelope down on this path, so the note starts a
  semitone sharp at CC 5 and an octave at CC 16, and falls back with the decay
- Noise as a modulation source, a random jitter of the cutoff: CC 99 = 1, CC 98 = 17,
  CC 6 = 116 puts Noise 1's red output on the filter's Mod 2 input in the LFO's place, and CC 25
  sets how much. CC 6 = 122 takes the white instead, finer still. The red is on no mixer, and the
  white is heard only once CC 23 brings it up, so neither is heard as well
- Filter cutoff driven by the envelope instead of its CC: CC 99 = 2, CC 98 = 13, CC 6 = 10. The
  envelope and the cutoff are both unipolar, so it opens the cutoff from the bottom of its dial
  to the top
- Amp gain and filter cutoff share one CC: CC 99 = 3, CC 98 = 18, CC 6 = 74
- Amp at full level with no envelope: CC 99 = 1, CC 98 = 6, CC 6 = 1
- Disconnect the filter's Mod 1 input, and with it the envelope: CC 99 = 1, CC 98 = 4, CC 6 = 0
- A finer pitch envelope, 60 cents deep: CC 99 = 2, CC 98 = 10, CC 6 = 10 points Osc 1 Pitch Fine at the
  envelope, which then sweeps the tuning from in tune up to 60 cents sharp, reached at half the
  envelope's peak
- The envelope drives the filter harder as a note starts: CC 99 = 2, CC 98 = 15, CC 6 = 10 takes
  the filter's input level from silence up to the top of its dial and back
- Portamento is wired by default -- Note Pitch reaches the oscillator through Pitch 1 -- so CC 5
  sets the time; at CC 64 a glide covers nine tenths of the way in about a tenth of a second. Every note glides, played legato
  or not. CC 99 = 2, CC 98 = 34, CC 6 = 51 takes the time from General Mod Wheel instead, so the
  wheel brings the portamento in
- A CC that bends pitch both ways through the modulation input: CC 99 = 1, CC 98 = 2, CC 6 = 56
  points the oscillator's Mod 2 input at General Bipolar 1 in the LFO's place, and CC 99 = 2,
  CC 98 = 12, CC 6 = 2 sets Osc 1 Mod 2 Pol back to +0.5. The slot is bipolar, centred on CC 64 as
  the LFO is on zero, so CC 16 now bends the pitch down and up around the note, as far as CC 13
  allows: a semitone either way at CC 6, an octave at CC 28
- A CC that works backwards, which needs a mixer to invert it. Mixer 1 is already running, so it
  only needs wiring and its levels up: CC 99 = 1, CC 98 = 7, CC 6 = 52 puts General Unipolar 1
  (CC 16) on its first input and CC 98 = 8, CC 6 = 1 the constant 1.0 on its second, and CC 99 =
  2, CC 98 = 20, CC 6 = 7 pins the first input's polarity to -0.5, the negating end of its dial;
  with CC 98 = 19, CC 6 = 1 and CC 98 = 21, CC 6 = 1 pointing Level 1 and 2 at 1.0, and CC 119,
  Balance 1/2, at the centre it powers up at, the mixer outputs 1.0 less the CC: the CC mirrored
  about CC 64. Point the cutoff's source at the mixer with CC 99 = 2, CC 98 = 13, CC 6 = 14 and CC 16 now
  closes the filter as it rises
- Take the filter out of the chain: CC 99 = 1, CC 98 = 5, CC 6 = 106 points the amp's audio input
  at Mixer 2. The filter keeps running and keeps its slot; nothing reads it
- A band pass, and one control sweeping from the dry input through it to the notch, from Filter 1
  Mode at the notch less the filter's input: LP + HP is the input less k·BP, so what is taken
  away is the band pass, k = 1/Q times. CC 39 = 64 sets Mode to the notch. Mixer 1 has to run
  after the filter, so that it reads the filter's output of the same sample: CC 99 = 0, then
  CC 98 = 2 to 8 with CC 6 = 9, 3, 11, 10, 12, 4 and 6 rewrites slots 2-8 of the run order to Pitch 1,
  Osc 1, Osc 2, Noise 1, Mixer 2, Filter 1 and Mixer 1. CC 99 = 1, CC 98 = 7, CC 6 = 106 and CC 98 = 8,
  CC 6 = 12 put Mixer 2, the filter's input, and Filter 1's Out on the mixer's inputs, and
  CC 98 = 5, CC 6 = 14 the mixer on the amp. CC 99 = 2, CC 98 = 22, CC 6 = 7 turns the second
  input over, CC 98 = 85, CC 6 = 56 hands Balance 1/2 to General Bipolar 1 (CC 16), and CC 98 = 19,
  CC 6 = 127 has Level 1 read its own slot, which CC 99 = 3, CC 98 = 19, CC 6 = 118 gives CC 118.
  With CC 118 = 34 (0.25, half of Filter 1 Gain's 0.5 at CC 64, as the filter takes its input at
  that gain) and Level 2 at the 0.5 it reads, CC 16 sweeps from the dry input at CC 4, through the band pass at
  CC 64, to the notch, turned over, at CC 124. The band pass peaks at the cutoff at half the level
  whatever the resonance, narrowing as it rises: rendered with white noise, at Resonance's
  power-up value, it is 6 dB down at the cutoff and the notch 34 dB down. Below about 100 Hz the
  filter's DC blockers leave some of the input in it, 23 dB down at 50 Hz, and a level that drives
  the filter's leak or its output clip leaves more. Narrow as it is, it is far quieter than the
  dry note, more so with the cutoff high above the harmonics: CC 74 = 64 brings it among them
- Echoes that only come in with the mod wheel: CC 99 = 2, CC 98 = 28, CC 6 = 51 takes Delay 1 Mix
  from General Mod Wheel, which powers up at 0.0, so the output is dry until the wheel moves
- Chorus that only comes in with the mod wheel: CC 99 = 2, CC 98 = 25, CC 6 = 51 takes Chorus 1
  Mix from General Mod Wheel, so the output stays mono until the wheel moves
- Leave the chorus out of the sound, keeping the delay: CC 99 = 1, CC 98 = 10 and 11, CC 6 = 13
  feeds both sides of Delay 1 from the amp. The chorus keeps running and nothing reads it, and the
  output is then mono
- Echoes ahead of the filter: CC 99 = 1, CC 98 = 10, CC 6 = 11 feeds Delay 1's left side from the
  oscillator, CC 98 = 3, CC 6 = 17 feeds the filter from it, and CC 98 = 12 and 13, CC 6 = 15 and
  16 points the final output at the chorus, which still takes the amp. The repeats then go
  through the filter and the amp's envelope as the note does, so they die away with it. Delay 1
  still runs after the filter, which reads it a sample late; for an echo that does not matter

#### Notes

- Module inputs (category 1) are read every sample (EG 1 Gate In, LFO 1's two Mod Ins and Filter 1's three every fourth) and are not
  smoothed; parameters (category 2) are read once per buffer and are smoothed by their
  destination. Route a fast source through a module input, a stepped one through a parameter
- The smoothing takes two stages (10.7 ms average delay, 99% in 35 ms at 48 kHz), which round off
  the steps of a controller sending sparse CCs (e.g. every 20 ms). Osc 1 Pitch Coarse and Pitch Fine
  and Pitch 1 Coarse and Fine are not smoothed, so that the pitch follows right away, and neither is Pitch 1 Glide, which
  cannot step what it sets, nor EG 1 Attack, Decay and Sustain, which the envelope's own curve
  already moves between
- A source may point at any slot number. A free one reads 0 until something writes it, which
  leaves a parameter pointed at one at the bottom of a unipolar dial or the middle of a bipolar
  one; 127, a parameter's own control slot, reads 0 as a module input's source
- A parameter clamps its value to its own range, 0.0 to 1.0 or -0.5 to +0.5, and its control slot
  holds that same range. A unipolar General slot routed to a module input runs one way, as an
  envelope does; its bipolar twin swings both ways about CC 64
- The NRPN CCs are stored as ordinary controls too, so a parameter may be mapped to CC 6 -- which
  then moves it every time a patch edit is sent
- A feedback loop through the bus -- a mixer wired back to its own input at a level below full,
  directly or through other modules -- decays toward zero and lands on it: the synth runs with
  flush-to-zero, on the device and in the C simulators alike, so a denormal comes out as 0.0. The
  CRuby simulator has no such mode, and there it can settle on a denormal, which x86 computes
  slowly

### Debug Print

- USB CDC (the serial port next to USB MIDI on the same cable)
- UART can be used instead: comment out `SPMS1_DEBUG_PRINT_USE_USB_SERIAL`
    - Speed: 115200 bps
    - GP0 and GP1 pins are used by UART0 TX and UART0 RX


### PC Simulators

The C hosts ("sim_spinel", "sim_render", and SPMS-1 Web in "web") keep the MIDI with the sketch's own
"spms1_midi_state.h", the tables "spms1_main.rb" reads and the handlers that fill them, so a change
there reaches the device and all of them at once. "sim_cruby" keeps a Ruby copy in "sim_cruby/spms1_c_midi.rb".

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
      is -25 dB (`ruby sim_cruby/spms1_compare.rb --limit DB` for another)


### Load Estimate

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
  here: Unicorn's Python binding is under the BSD licence and its emulator under the GPLv2, Capstone
  and NumPy under the BSD licence, and pyelftools is in the public domain


### GitHub Actions

"SPMS-1 (type-2) Build (UF2 and Web)" in "../.github/workflows/spms1-type2.yml", run by hand
("Run workflow" in the Actions tab, e.g. at a release); every run does all of the following:

- UF2: compiles "spms1/spms1.ino" for PWM Audio and I2S with Arduino-Pico 6.2.0, and keeps the
  UF2 files as an artifact
- SPMS-1 Web: builds and tests "spms1_web_synth.js", and keeps it as an artifact
- Simulators: builds "sim_spinel" and "sim_render" on Linux, macOS and Windows, renders, and compares
  the renders with CRuby on Linux. On Linux it first checks that the files generated from
  "spms1_patch.yaml" are up to date ("patch_gen/spms1_patch_gen.rb --check"). On Linux it also checks that every function and variable of the
  runtime has the same type wherever it is declared ("spinel_mcu/lto_type_check.sh"): a function
  declared with float on one side and double on the other goes unnoticed otherwise, as two did
  when the MCU changes made the runtime float with `#define double float`
- Spinel: builds the release named above and checks that "spms1_main.c" is what it makes of the .rb files,
  and that the runtime files are the release with "spinel_mcu/spinel_mcu.patch" applied (see below)
- With "commit_package" checked, and when all of the above pass, the UF2 files ("bin") and
  "spms1_web_synth.js" are committed on the selected branch (not if the sources were changed after
  the build, nor if nothing changed)


### Updating Spinel

The runtime files in "spms1" are all of Spinel's `lib` (and `lib/regexp`) of the release named
above, with the changes for the MCU kept in two places:

- "spinel_rt_mcu_head.h", "spinel_rt_mcu_libm.h" and "spinel_rt_mcu_cold.h": what the MCU adds -- the
  section and the pragmas of the synth core, Integer arithmetic without the overflow check
  (`SP_INT_OVERFLOW_MODE_WRAP`, as `spinel --int-overflow=wrap` builds it), the float versions of
  the math functions, and, at
  the end of "spinel_rt.h", what binds the generated code to a float runtime (below).
  "spinel_rt.h" carries only an `#include` line for each
- "spinel_mcu/spinel_mcu.patch": what is changed in Spinel's own files -- the runtime written in
  `sp_float` where it said `double` for a Float, the POSIX parts left out with `#if 0` (a release
  changing what is inside them seldom stops the patch from applying), the files that need POSIX
  throughout left out whole with `SPINEL_BARE_METAL` (below), the GC's buffers made to fit
  SRAM, and the in-range path of an Array read or write (`sp_FloatArray_get`/`set`,
  `sp_IntArray_get`) put ahead of the other checks, which go out of line unchanged. Each file it
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
   release in this README and README.ja.md; regenerates "spms1_main.c"; checks that types agree
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


### Checking the Generated Code

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


SPMS-1 (type-2) Licence
-----------------------

```
MIDI Synthesizer SPMS-1 (type-2) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
```

- Target files: `spms1_*.*`, `spms1/spms1.ino`, `spms1/spms1_*.*`


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

- Base Release: 2026.09.12 <https://github.com/matz/spinel/tree/2026.09.12>
- Target files: `spms1/spinel_rt*.h*`, `spms1/mruby_shim.h*`, `spms1/sp_*.*`, `spms1/re_*.*`, `spinel_mcu/*`
    - Note: Some files for runtime are modified for MCU by ISGK Instruments (Ryo Ishigaki)
