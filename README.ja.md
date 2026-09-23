MIDI Synthesizer SPMS-1
=======================

- Spinel (Ruby AOT コンパイラ) で作った MIDI シンセサイザー
- 開発: ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [English README](./README.md) (英語版が正です)


SPMS-1 (type-0)
---------------

- 参照: [Spinel x Raspberry Pi Pico 2でシンセサイザーを作ってみた #nagoyark05 - Speaker Deck](https://speakerdeck.com/risgk/spinel-x-raspberry-pi-pico-2-de-shinsesaiza-o-tsuku-te-mita-nagoyark05)
- Raspberry Pi Pico 2 用のモノフォニック・セミモジュラー MIDI シンセサイザー
- フィルタ: 非線形バイカッド
- 必要なハードウェア: Raspberry Pi Pico 2、Pimoroni Pico Audio Pack (または代わりとなる I2S DAC ハードウェア)
- [README](./spms1_type0/README.ja.md)

![SPMS-1 (type-0)](./midi_synthesizer_spms1_type0.jpg)


SPMS-1 (type-1)
---------------

- Raspberry Pi Pico 2 用のモノフォニック・セミモジュラー MIDI シンセサイザー
- フィルタ: ZDF/TPT SVF (ゼロ遅延フィードバック、トポロジー保存変換によるステート・バリアブル・フィルタ)
- 必要なハードウェア: Raspberry Pi Pico 2、Pimoroni Pico Audio Pack (または代わりとなる I2S DAC ハードウェア)
- [README](./spms1_type1/README.ja.md)
