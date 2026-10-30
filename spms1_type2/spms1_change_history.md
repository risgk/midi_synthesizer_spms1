MIDI Synthesizer SPMS-1 (type-2) Change History
===============================================

The main changes of each version, newest first, gathered before each release. The format may be
revised.

- v0.4.1 (2026-??-??):
    - Default patch: Mixer 2 Out Level powers up at 1.0 (value 124) instead of 0.5, and Amp 1 Gain 2
      (CC#15) at unity (value 64) instead of 1.96 times (value 88), so the level is as it was, but the
      filters are driven 6 dB harder, 0.5 at Filter 1 with Osc 1 alone: the leak's saturation at the
      resonance comes in sooner, and Osc 2 or a mixer level brought up to full now reaches Filter 1's
      output clip (its knee at 0.75), so the sound rounds off where it stayed clean before; Mixer 2's
      sum is held to one unit, which two sources at full level just reach. A patch saved by v0.4.0
      keeps its own values

- v0.4.0 (2026-10-29):
    - Filters: Filter 2 runs after Filter 1 by default, Mixer 2 into Filter 1 into Filter 2 into the
      amp, one low pass of the fourth order (24 dB/oct), steeper and darker above the cutoff; the two
      are on the same CCs and power up alike, but for the Resonance: Filter 2's, on CC#71, at Q 4.0,
      and Filter 1's, with no CC, at Q 0.71. Each filter and the amp take two audio inputs, at Gain 1
      and Gain 2 (the filters' with no CC; the amp's Gain 2 on CC#15, its Gain 1 with no CC), wired
      so that the gains alone set the filters in parallel. Mode heads each filter's parameters, and
      the gains follow the resonance
    - Keyboard tracking: each filter's Pitch Amt (CC#9) powers up at 0.0, with a Pitch Pol beside
      it, with no CC, which runs the tracking the other way below value 64
    - Oscillators: the pitch and the pulse width take two modulation inputs each, Pitch Mod 1 In and
      Pitch Mod 2 In, and PW Mod 1 In and PW Mod 2 In, EG 1 on each Mod 1 In and LFO 1 on each Mod 2
      In by default, with a Pitch Mod 1 Sw and Pitch Mod 2 Sw (Osc 1's Mod 1 Sw on CC#118); Pitch is
      gone; Pitch Coarse reaches 60 semitones either way, a semitone a step (Osc 2's on CC#85), and
      Pitch Fine 50 cents either way (Osc 2's on CC#76, 10 cents sharp at power-up); Osc 2's PW and
      PW Mod Amts have no CC; Wave reads Saw to Pulse
    - Pitch 1: Bend Pol, with no CC, runs the bend the other way below value 64; Out 1 Bend Sw is on
      CC#119, so the wheel can bend Osc 2 alone, for a sync sound swept against Osc 1 (README has
      the example)
    - Default patch: Osc 1 alone at full level, Mixer 2 Level 1 at 1.0 (CC#19 = 124) and Level 2 at
      0.0 (CC#20 = 4), so Osc 2 is silent until it is turned up, 10 cents sharp
    - Controllers: Breath (CC#2), as the Mod Wheel, with a wheel beside the mod wheel by the soft
      keyboard; the Mod Wheel and Breath each on the bus in four forms (the value, Rev, Inv and Rev
      Inv); General 1 and 2 on CC#16 and 17, and holding a value of the patch while they have no CC,
      as a parameter does; the editor shows them as a General node and panel of their own
    - NRPN: the patch can go as SysEx too, a value a byte, about a quarter of the bytes of NRPN;
      the editor sends it so where the browser allows it (and always to SPMS-1 Web), and Export has
      the format "MIDI bytes, SysEx (hex)"
    - Every module's smoothing starts at 0.0 at power-on, and the levels and gains come up through
      it; the rates, depths, times and the cutoff start where their controls are
    - PWM Audio: a sample is written in about 90 instructions, from about 130 and two calls to
      lroundf, which ran from the flash and now and then held the writes up long enough for the
      output's DMA to pass the synth, a click each; Debug Print shows `underruns`, the count of those,
      0 now
    - Editor: the favorites are 47 (README lists them); the Controls tab's panels in four columns,
      the modulation first and the effects last, moved by dragging and put back by Reset Layout,
      both undone by Undo; every module's panel shown, its title alone when none of its parameters
      is; a long name wraps onto a second line in four columns; the Patch tab's columns keep an even
      gap; Save JSON names the file after the patch and the synth
    - The module ids, Signal IDs and NRPN entries are renumbered (Filter 2, the oscillators'
      inputs, Breath, Bend Pol, Pitch Pol, Pitch), so a patch saved by v0.3.4 is not loaded, and a
      patch sent as NRPN bytes for it is not taken as it was
    - Documents: the Patching examples say what to do in the editor first, and then the MIDI; "Patch
      Editing (NRPN)" opens with a worked example; README walks through the default patch by the
      block diagram; Development on the runtime, the underruns and the load
    - Load: Debug Print on the device 1253 to 1256 us (about 94%), from 1046 to 1047, with the second
      filter, the oscillators' inputs and the controllers; the estimate 1355 us
- v0.3.4 (2026-10-26):
    - The run order of the modules as a C array of the sketch's, as the signal bus, and the reads
      of the CC values and the NRPN table inline ("spms1_midi_read.h"), with the same output, so
      that the common part takes less: about 7% less a buffer on the device (Debug Print: 1046 to
      1047 us, from 1124 to 1129), as in the estimate (1119 us, from 1207)
    - sim_load: Add `--modules`, the load of each module, also with its share of the common part
    - README: Add Getting Started, the steps from the favorites to the patch; Patching: the wiring
      on the editor's Patch tab beside some of the examples
    - Development: Keep the load estimate of the latest version only, with the table of the modules
- v0.3.3 (2026-10-25):
    - USB MIDI: Read 4 bytes a loop (from 8), still more than UART MIDI brings (about 3.2 bytes)
    - Editor: Init and Load (and their Undo and Redo) send what they change between Mute on and off,
      as Send Patch
    - Editor: Keep the Mute button as wide when on, so that the buttons by it do not move
    - Documents: Development (Runtime, Release, and the load estimates), and notes on the editor,
      the time a patch takes to send, and the patch saved
- v0.3.2 (2026-10-25):
    - Save (NRPN 117/2): save the General controls' CCs as they are again, as v0.3.0 did, since a
      General control may set a parameter, Rev or Inv; only a CC that only the Mod Wheel has is
      saved at 0
    - Editor: Save JSON and Export keep the General controls' CCs as they are again
- v0.3.1 (2026-10-25):
    - Save (NRPN 117/2): save a CC that only the controllers (Mod Wheel, General) have at 0, as
      the Mod Wheel's was; a CC that a parameter has too is saved as it is
    - Editor: Save JSON and Export keep such a CC at what it powers up at
- v0.3.0 (2026-10-25):
    - NRPN: Add the system entries (MSB 117), which are not a part of the patch
        - Mute (117/0): fades the output out over 4 ms and holds it silent, and fades it back in;
          a Mute on is never missed, however soon Mute off follows it
        - Reset (117/1): puts the default patch back
        - Save (117/2): keeps the patch in the flash, taken only while Mute is on
        - Load (117/3): puts the patch saved back, taken only while Mute is on
    - Load the patch saved at power-on, if it was saved by a version with the same numbering
      (module ids, Signal IDs and NRPN entries); the Mod Wheel's CC is saved at 0
    - All Sound Off (CC#120): as All Notes Off; the envelopes release
    - Editor: Send Patch between Mute on and off, a Mute button, and Save to Device
    - Editor: Export: add "Mute while loading" (on by default)
    - Editor: Save JSON and Export keep the Mod Wheel's CC at what it powers up at
- v0.2.2 (2026-10-24):
    - Fix the NRPN MSBs of the routing example of sim_render
- v0.2.1 (2026-10-24):
    - Editor: Keep the soft keyboard at the bottom of the window on both tabs, and with Wide too
    - Editor: Keep the page from widening on the Patch tab, where a scrollbar comes and goes
- v0.2.0 (2026-10-24):
    - NRPN: Move the categories to MSB 112-116 (from 0-4), clear of the NRPNs of GS and XG;
      a patch sent as NRPN bytes for v0.1.x is not taken
    - Change the default patch: EG 1 Sustain 1.0 (CC#30 = 124), and Amp 1 Gain 0.7 (CC#15 = 88),
      under the limiter
    - Editor: Light up a held key of the soft keyboard whole
- v0.1.3 (2026-10-24):
    - Editor: Keep the soft keyboard at the bottom of the window on the Controls tab at any height,
      with 100px keys in a window up to 640px high
- v0.1.2 (2026-10-24):
    - Change the default patch: EG 1 Decay 88 (from 94), a pluck that dies away in about 1.3 s
    - Editor: Show two octaves of keys on a touch screen other than a phone, and an octave on a phone
    - Editor: Move a panel of the Controls tab by arrows in one column, as on a phone
- v0.1.1 (2026-10-24):
    - Editor: For iPhone: keep the page from scrolling under the soft keyboard, and keep the soft
      keyboard at the bottom of a window from 480px high
- v0.1.0 (2026-10-24):
    - First release
