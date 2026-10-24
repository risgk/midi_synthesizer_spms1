MIDI Synthesizer SPMS-1 (type-2) Change History
===============================================

The main changes of each version, newest first, gathered before each release. The format may be
revised.

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
