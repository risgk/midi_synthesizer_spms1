MIDI Synthesizer SPMS-1 (type-2) Changelog
==========================================

The main changes of each version, newest first, gathered before each release. The format may be
revised.

- v0.8.0 (2026-??-??):
    - **Programs #0-7**: Save keeps the patch as the program that NRPN 117/4 (Program) selects, each in a 4 KB sector of
      the flash of its own, with its name (SysEx command 02, 32 bytes of ASCII); **Program Change #0-7** puts a program
      back, fading the output out and in (about 20 ms of silence); program #0 is loaded at power-on
        - Wait about 30 ms after a Program Change before CCs or NRPN, which the program replaces until it is put back
        - The patch saved before (one) is read as program #0 until #0 is saved; Save and Load act on the program that
          NRPN 117/4 gives before each (#0 without it, as before); there is no program the synth is "on"
        - Debug Print: the name of the patch, and those of the programs #0-7, one a report in turn
        - **Clear** (NRPN 117/5): the program that NRPN 117/4 gives not kept
        - The EEPROM's 4 KB in RAM no longer taken (the programs read where they are in the flash)
    - Editor: Save to Device with the program #0-7 to save as, and the name; Program Change sends it to the synth; the
      name of the patch sent (as SysEx) with the whole patch and whenever it changes; Clear, on the synth and of the
      user presets
    - Editor: **User presets #0-7** in the browser (Presets panel), as PRA32-U2 Editor: Store (to Browser) and Recall (from
      Browser); Save to Device writes the user preset of the same number too, and a Program Change (sent, or at
      MIDI In) shows it as the synth has it, to edit on from there (otherwise Send Patch is marked); Undo Store, Import
      All and Export All of them
    - Editor: **Reset Values** (Initialize Values before) puts the values back to the patch's as it was loaded or saved
      last, or with Shift to those of Init (the default patch)
    - "patches/Init-spms1_type2.json": the default patch, Init, as the editor's Save JSON saves it
    - sim_load: `--program-load` counts putting a program back (about 115 us, once, while silent); the tests of the
      programs in CI (sim_render compared with CRuby, and SPMS-1 Web)
- v0.7.3 (2026-11-23):
    - Built with Arduino-Pico 6.4.0 (6.3.0 before); the same load and RAM in the estimate
    - Filter: The output clip in fewer steps, the same curve (the renders the same), a little lighter
      (estimated: 1253 us to 1245 us a buffer of 1333 us, the default patch with a note held)
    - sim_load: "loud.txt" and "loud_nolim.txt" set Mixer 2 Level 1 on CC 42 (on CC 19 before, which it left since v0.7.2)
    - Editor: No dark line between two keys of the soft keyboard (where the edges of the keys fell between the pixels,
      e.g. at 125% and 150% of the display scale)
    - Editor: Lighter with a stream of CCs or NRPN received (e.g. a knob turned): the display, the export and the patch
      kept in the browser brought up to date once a frame, not at each of them
- v0.7.2 (2026-11-20):
    - The default patch: **Osc 1 PW** on CC 47 (114 before) and **LFO 1 Level** on CC 45 (116 before), as Osc 1 Shape
      and LFO Depth of PRA32-U2 v3.22.0 (CC 16 and 17, General 1 and 2, as its General Purpose Controller 1 and 2),
      and **Mixer 2 Level 1** on CC 42 (19 before, which PRA32-U2 v3.22.0 makes General Purpose Controller 4)
        - Not compatible: a MIDI controller set to CC 114, 116 or 19 for them is to be set to CC 47, 45 or 42; a patch
          kept (saved to the device, or exported) keeps its own CCs
        - The load as v0.7.1 (the synth core the same)
    - SPMS-1 Web: "Click (or tap) to start the audio" is shown as soon as SPMS-1 Web is chosen in MIDI Out (e.g. as the
      editor opens with it chosen), before anything is sent to it, whatever the editor sends then
- v0.7.1 (2026-11-16):
    - Filters: **Filter Drive** back to v0.6.1: the leak's ceiling down by the gain, x1 to x32, for a saturated
      resonance, with no input clip (as SPMS-1 type-2 drives a filter harder by its input, Gain 1 and Gain 2 and
      Mixer 2, and soft-clips the input by Amp 1 Distortion). The input clip of v0.7.0, not oversampled, folded
      back in the band below 5 kHz (about -46 dB of a saw at C4 at the top, against about -77 dB without it), most of
      it at Filter 1, the first of the two in series, and more as the input went up
        - Not compatible with v0.7.0: a patch with Filter Drive above x1 sounds as in v0.6.1 again
        - The load and the RAM as v0.6.1 (the synth core the same as v0.6.1)
- v0.7.0 (2026-11-16):
    - Filters: **Filter Drive** shared between the input and the loop, as PRA32-U2's: the input
      soft-clipped (the leak's curve, biased, the even harmonics too), and the leak's ceiling down by
      the square root of the gain, so that the Drive puts in harmonics at any resonance while the
      resonance, and the squelch of an envelope on the cutoff, is kept more (with the default patch, a
      pluck at Resonance CC 100 keeps its peak about 5 dB up at the top, from about 0.6 dB before),
      with a make-up gain (the level within about 1 dB); x1 to x8 (x1 to x32 before), short of a
      square wave: a strong distortion is for Amp 1 Distortion
        - Not compatible: a patch with Filter Drive above x1 sounds otherwise (more harmonics, the
          resonance less held down); x1 (the default patch) is as before
        - About 37 us more a buffer (estimated: 1253 us to 1290 us of 1333 us, 94% to 97%, with the
          default patch)
- v0.6.1 (2026-11-11):
    - Filters: The self-oscillation comes out at 0.3 at most (0.25 before): 0.15 at Resonance CC 119
      (as before), 0.21 at CC 120, 0.25 at CC 121, 0.28 at CC 122 and 0.3 at CC 123, as PRA32-U2 v3.21.0,
      with the outputs lowered less at a high resonance (-4.4 dB at CC 123, from -6.0 dB) and more at
      each step up
    - Filters: The self-oscillation starts from silence at any Resonance of it (at CC 119 too, where it did
      not): the tiny value added to the band pass to start it has a random sign (a 16-bit LFSR), not one
      flipped each time, and is 1e-7 (1e-6 before); about 3 us more in the load estimate
- v0.6.0 (2026-11-07):
    - Filters: **Mode** (CC#39) goes LP, BR (band reject, a notch), HP, BP and back to LP (at values 4,
      34, 64, 94 and 124), changing smoothly all the way: the high pass to the band pass and the band
      pass to the low pass with no notch in between. Not compatible: the high pass, at value 124
      before, is now at 64
    - Filters: Add **Out BR**, the band reject (the low pass and the high pass summed), between Out LP
      and Out HP; the signals from Filter 1 Out HP on are numbered one up (two from Filter 2 Out HP on)
- v0.5.1 (2026-11-06):
    - Delay 1 Mix: **No dip in the middle**: the dry input stays at full up to value 64, while the
      repeats come up to full, and then goes down to none at value 124 (it was a crossfade, about 5
      to 7 dB down at value 64)
    - Default patch: Amp 1 Gain 2 (CC#15) powers up at **half** (value 46) instead of unity (value
      64), about 6 dB down, for room to bring a sound up
        - With the Delay 1 Mix above, about 3.5 dB lower in all (the peaks at about -13 dBFS)
    - SPMS-1 Web: Add **"SPMS-1 Web (Built-in, +6 dB)"** to MIDI Out: 6 dB louder, closer to other
      sounds (the peaks above -2 dBFS rounded off)
    - Editor: While Hold is on, a key pressed again while its note is held turns the note off
- v0.5.0 (2026-11-05):
    - Add **Filter Drive**, of Filter 1 and Filter 2 (CC#31, among the favorites): drives the
      filters harder, x1 to x32, for a saturated resonance, with the level kept. A patch saved by
      v0.4.1 loads the default patch, as the entries have changed: the Drives, the Distortion and
      Limiter Sw now sit in their modules (entries 68, 80, 91 and 93), and the entries after them
      are numbered on
    - Add **Amp 1 Distortion** (CC#95, among the favorites): a soft clip with less aliasing (ADAA)
      and a tone after it, ahead of the limiter, x1 to x32, with the level kept for a sound below
      the knee; x1 at power-up
    - Filters: A high resonance is about as loud as a moderate one, and the self-oscillation is
      quieter (0.25 at most, from 0.5), while it holds against the input as before
    - Default patch: Mixer 2 Level 1 at 0.5 instead of 1.0, so that the self-oscillation holds
      while a note plays, and the level is about 6 dB lower, about as loud as a lead sound of a
      typical synth; and Chorus 1 Mix at value 34 (0.25) instead of 64, a lighter chorus
    - Chorus 1 and Delay 1: Out Wet L and Out Wet R, the tap and the repeats alone, whatever Mix
      is, to mix with the dry signal elsewhere, as a send would (the signals from Delay 1 Out L on
      are numbered two up)
    - Filters: Cutoff three semitones down, a C every 12 values, C5 at value 64; the default patch
      powers up at value 88 (C7)
    - LFO 1 Rate: a C every 12 values, C-2 (4.09 Hz) at value 64; it powers up at 6.49 Hz, a
      slightly slower vibrato
    - Lighter: about 150 us less of a buffer in all, with the Drive and the Distortion (about 83%
      on the device)
- v0.4.1 (2026-10-30):
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
