MIDI Synthesizer SPMS-1
=======================

- MIDI Synthesizer made with Spinel (Ruby AOT Compiler)
- Developed by ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [日本語版 README](./README.ja.md)


SPMS-1 (type-2)
---------------

- Monophonic semi-modular MIDI Synthesizer for Raspberry Pi Pico 2
- Filter: ZDF/TPT State Variable Filter (with delayed soft clipping)
- Chorus (mono to stereo) and Delay (stereo), with stereo output
- Required Hardware: Raspberry Pi Pico 2 and Pimoroni Pico Audio Pack (or alternative I2S DAC hardware), or Raspberry Pi Pico 2 alone (PWM Audio output, with no DAC)
    - The photo: PWM Audio from Raspberry Pi Pico 2 on a breadboard, through an RC low pass filter on each output, to a 3.5 mm stereo jack with screw terminals
- SPMS-1 Web: the synth itself runs in the Web browser, built into the Web Editor ("spms1_editor.html")
- [README](./spms1_type2/README.md) / [日本語版](./spms1_type2/README.ja.md)

![SPMS-1 (type-2), PWM Audio](./midi_synthesizer_spms1_type2_pwm_audio.jpg)


SPMS-1 (type-1) (Frozen)
------------------------

- Monophonic semi-modular MIDI Synthesizer for M5Stack AtomS3 Lite and Raspberry Pi Pico 2
- Filter: ZDF/TPT State Variable Filter (with delayed soft clipping)
- Required Hardware: M5Stack AtomS3 Lite and Atomic Audio-3.5 Base (recommended), or Raspberry Pi Pico 2 and Pimoroni Pico Audio Pack (or alternative I2S DAC hardware)
- [README](./spms1_type1/README.md) / [日本語版](./spms1_type1/README.ja.md)

![SPMS-1 (type-1), AtomS3 Lite](./midi_synthesizer_spms1_type1_atoms3_lite.jpg)


SPMS-1 (type-0)
---------------

- See [Spinel x Raspberry Pi Pico 2でシンセサイザーを作ってみた #nagoyark05 - Speaker Deck](https://speakerdeck.com/risgk/spinel-x-raspberry-pi-pico-2-de-shinsesaiza-o-tsuku-te-mita-nagoyark05)
- Monophonic semi-modular MIDI Synthesizer for Raspberry Pi Pico 2
- Filter: Nonlinear biquad
- Required Hardware: Raspberry Pi Pico 2, Pimoroni Pico Audio Pack (or alternative I2S DAC hardware)
- [README](./spms1_type0/README.md) / [日本語版](./spms1_type0/README.ja.md)

![SPMS-1 (type-0), Pico Audio Pack](./midi_synthesizer_spms1_type0_pico_audio_pack.jpg)
