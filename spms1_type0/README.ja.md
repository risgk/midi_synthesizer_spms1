MIDI Synthesizer SPMS-1 (type-0) v0.0.26
========================================

- Spinel (Ruby AOT コンパイラ) で作った、Raspberry Pi Pico 2 用のモノフォニック・セミモジュラー MIDI シンセサイザー
- 音源モジュールとして MIDI で制御します
- 48 kHz/24 bit オーディオ出力
- 開発: ISGK Instruments (Ryo Ishigaki)
- <https://github.com/risgk/midi_synthesizer_spms1>
- [English README](./README.md) (英語版が正です)


必要なハードウェア
------------------

- [Raspberry Pi Pico 2](https://www.raspberrypi.com/products/raspberry-pi-pico-2/)
- Pimoroni [Pico Audio Pack](https://shop.pimoroni.com/products/pico-audio-pack) (PIM544)
    - 以下の I2S DAC ハードウェア (48 kHz/24 bit) も使えます:
        - [Adafruit PCM5102 I2S DAC](https://www.adafruit.com/product/6250) (Product ID: 6250)
        - GY-PCM5102 (PCM5102A I2S DAC モジュール)


改造に必要なソフトウェア
------------------------

- [Arduino IDE](https://www.arduino.cc/en/software)
- Arduino-Pico = Raspberry Pi Pico/RP2040/RP2350 (by Earle F. Philhower, III) コア
    - 追加のボードマネージャ URL: <https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json>
    - このスケッチはバージョン 6.0.0 で動作確認しています: <https://github.com/earlephilhower/arduino-pico/releases/tag/6.0.0>
    - 情報: <https://github.com/earlephilhower/arduino-pico>
- Arduino MIDI Library (by Francois Best, lathoub)
    - このスケッチはバージョン 5.0.2 で動作確認しています: <https://github.com/FortySevenEffects/arduino_midi_library/releases/tag/5.0.2>
    - 情報: <https://github.com/FortySevenEffects/arduino_midi_library>
- Spinel
    - コミット: <https://github.com/matz/spinel/tree/5af61ae7d53e36ca59a8de5870f532360d88fd7c>
    - Spinel の出力ファイル "spms1_main.c" の `int main(int argc,char**argv){` を `int Spms1_main(int argc,char**argv){` に書き換えてください


使い方
------

### ビルド済みバイナリ

- "bin" フォルダの "spms1_type0.ino.uf2" は Raspberry Pi Pico 2 と Pimoroni Pico Audio Pack 用です


### Web エディタ

- Web MIDI API を使う、プラットフォームを問わないパラメータ・コントローラ: "spms1_editor.html"
- 音を出して試すためのソフトウェア鍵盤を内蔵しています


### MIDI の設定

- MIDI チャンネル: チャンネル 1
- USB MIDI 入力
    - 製造者ディスクリプタ: "ISGK Instruments"
    - デバイス名: "SPMS-1 (type-0)"
- UART MIDI 入力
    - 速度: 31250 bps
    - GP4 ピンと GP5 ピンを UART1 TX と UART1 RX に使います
    - 以下のように書き換えれば `SoftwareSerial` も使えます:

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

    - DIN/TRS MIDI は、たとえば Adafruit MIDI FeatherWing Kit などを使う (そして手を入れる) ことで利用できます
        - Adafruit [MIDI FeatherWing Kit](https://www.adafruit.com/product/4740) (Product ID: 4740)
        - M5Stack [Midi Unit with DIN Connector (SAM2695)](https://shop.m5stack.com/products/midi-unit-with-din-connector-sam2695) (SKU: U187) のセパレートモード
        - Kinoshita Laboratory [MIDI-UART interface-san Kit](https://www.tindie.com/products/kinoshitalab/midi-uart-interface-san-kit/)
        - 木下研究所 [MIDI-UARTインターフェースさん キット](https://www.switch-science.com/products/8117) (日本国内発送のみ)
        - necobit電子 [MIDI Unit for GROVE](https://necobit.com/denshi/grove-midi-unit/) (日本国内発送のみ)
        - necobit電子 [MIDI Unit Mini for GROVE](https://necobit.com/denshi/midi-unit-mini-for-grove/) (日本国内発送のみ)


### [MIDI インプリメンテーション・チャート](./spms1_midi_chart.md)


### ブロック図

デフォルトのパッチです。実線の矢印がオーディオ信号を、破線の矢印がコントロール信号を運びます。

```mermaid
flowchart LR
  NOTE([MIDI Note])
  EG1[EG 1]
  LFO1[LFO 1]
  MIX1[Mixer 1]
  OSC1[Osc 1]
  FILTER1[Filter 1]
  AMP1[Amp 1]
  OUT([Audio Out])

  OSC1 --> FILTER1
  FILTER1 --> AMP1
  AMP1 --> OUT

  NOTE -. Gate .-> EG1
  NOTE -. Pitch .-> OSC1
  LFO1 -.-> MIX1
  MIX1 -. Mod .-> OSC1
  EG1 -. Mod .-> FILTER1
  EG1 -. Mod .-> AMP1
```

モジュールは EG 1、LFO 1、Mixer 1、Osc 1、Filter 1、Amp 1 の順に、1 サンプルずつ処理されます。波形や
カットオフ、ゲインといったパラメータは CC から届くもので、この図では省いています。

Mixer 1 がビブラートの経路に入っているのは、LFO を 0.2 倍に落とすためです。Osc Mod Amt はここにある
どのモジュレーション深度とも同じくピッチの全域に届くので、ソースを音楽的な深さまで絞る仕事はオシレータに
作り込まず、ミキサーに任せています。

以上はどれも固定ではありません。実行順も、上の図のすべての矢印も、どの CC がどのパラメータに入るかも、
NRPN が書き換えます。

#### 積んであるモジュールすべて

残りのモジュールも電源投入時から存在していて、パッチが届くのを待っています。何も結線されておらず、CC も
触れないので、実行順に名前が挙がるまで音を出しません。

```mermaid
flowchart TB
  subgraph patched [デフォルトのパッチの中]
    direction LR
    NOTE([MIDI Note])
    OSC1[Osc 1] --> FILTER1[Filter 1] --> AMP1[Amp 1] --> OUT([Audio Out])
    NOTE -. Gate .-> EG1[EG 1]
    NOTE -. Pitch .-> OSC1
    LFO1[LFO 1] -.-> MIX1[Mixer 1] -. Mod .-> OSC1
    EG1 -. Mod .-> FILTER1
    EG1 -. Mod .-> AMP1
  end
  subgraph spare [パッチが指名するまで待機]
    direction LR
    EG2[EG 2] ~~~ LFO2[LFO 2] ~~~ OSC2[Osc 2] ~~~ FILTER2[Filter 2] ~~~ AMP2[Amp 2]
    MIX2[Mixer 2] ~~~ MIX3[Mixer 3] ~~~ MIX4[Mixer 4] ~~~ MIX5[Mixer 5]
  end
  patched ~~~ spare
```

ミキサーは 2 つの信号を合流させるための道具であり、Pitch Bend を除けば、正負どちらにも振れる信号を
モジュール入力へ渡す唯一の手段でもあります。下の例を参照してください。

### パッチの編集 (NRPN)

パッチはデータであり、NRPN は動いているシンセのそれを書き換えます。どのモジュールがどの順で走るか、各
モジュール入力に何が入るか、各パラメータがどこから値を取るか、どの CC がどのコントロールスロットを埋める
か。すべてのモジュールは番号の付いたシグナルスロットから読み、番号の付いたスロットへ書くので、配線し直す
こととはスロット番号を変えることです。

#### 送り方

- CC 99 でカテゴリを、CC 98 でその中のエントリを選びます。順序はどちらが先でも構いません
- CC 6 (Data Entry MSB) で値が確定し、次のオーディオバッファから効きます
- CC 38 (Data Entry LSB) は無視されます。ここで扱う値はすべて 7 ビットです
- CC 101 と CC 100 (RPN セレクト) はデータ入力を中断させるので、RPN がパッチ編集と取り違えられることは
  ありません。再開するには CC 99 か CC 98 をもう一度送ります
- 編集内容は保存されません。電源投入時にデフォルトのパッチへ戻ります

#### カテゴリ (CC 99)

| CC 99 | CC 98 | 設定する対象 | CC 6 の値 |
| ----- | ----- | ---- | ---------- |
| 0 | 0-31 | 実行順、スロットごとに | モジュール ID |
| 1 | 0-24 | モジュール入力に何を入れるか | シグナル ID |
| 2 | 0-45 | パラメータがどこから値を取るか | シグナル ID |
| 3 | 0-45 | どの CC がコントロールスロットを埋めるか | CC 番号、0 なら割り当てなし |

実行順はスロット 0 から上へ読まれ、最初に現れたモジュール ID 0 で止まります。32 個に満たないパッチは
そこで自ら終わるわけです。実行順はモジュールの番号付けとは別物です。あるモジュールが今サンプルの値を
見られるのは自分より前に並んでいるものからだけで、後ろにあるものからは前サンプルの値を受け取ります。

カテゴリ 3 で CC 番号 0 を指定すると、そのパラメータには CC がない状態になります。コントロールスロットは
そのとき持っている値をそのまま保つので、パラメータをルーティングだけで動かせます。

音を作るモジュールはそれぞれ 2 つずつ、ミキサーは 5 つあります。**デフォルトの実行順に入っているのは各
ペアの 1 番目だけ**で、これに Mixer 1 が加わります。残り 4 つのミキサーは入っていません。外れているものに
は何も結線されておらず、どのパラメータにも CC が付いていないので、パッチが実行順に加えるまで音を出さず、
サンプルあたりのコストもかかりません。ただしパラメータはどちらにせよ 1 バッファに 1 回読まれます。それらの
コントロールスロットには結線済みのモジュールのデフォルト値を入れてあるので、パッチに組み込まれたモジュール
は無音から始まるのではなく、相方と同じように振る舞います。

#### エントリ (CC 98)、カテゴリ 1

| CC 98 | モジュール入力 | | CC 98 | モジュール入力 |
| ----- | ------ | - | ----- | ------ |
| 0 | EG 1 Gate | | 13 | Amp 2 Mod In |
| 1 | EG 2 Gate | | 14 | Mixer 1 In 1 |
| 2 | Osc 1 Pitch | | 15 | Mixer 1 In 2 |
| 3 | Osc 1 Mod In | | 16 | Mixer 2 In 1 |
| 4 | Osc 2 Pitch | | 17 | Mixer 2 In 2 |
| 5 | Osc 2 Mod In | | 18 | Mixer 3 In 1 |
| 6 | Filter 1 Audio In | | 19 | Mixer 3 In 2 |
| 7 | Filter 1 Mod In | | 20 | Mixer 4 In 1 |
| 8 | Filter 2 Audio In | | 21 | Mixer 4 In 2 |
| 9 | Filter 2 Mod In | | 22 | Mixer 5 In 1 |
| 10 | Amp 1 Audio In | | 23 | Mixer 5 In 2 |
| 11 | Amp 1 Mod In | | 24 | 最終出力 |
| 12 | Amp 2 Audio In | |  |  |

#### エントリ (CC 98)、カテゴリ 2 と 3

| CC 98 | パラメータ | | CC 98 | パラメータ | | CC 98 | パラメータ |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | Osc 1 Wave | | 16 | Amp 1 Gain | | 32 | Mixer 2 Level 2 |
| 1 | Osc 1 Mod Amt | | 17 | Amp 2 Gain | | 33 | Mixer 2 Invert 2 |
| 2 | Osc 1 Coarse Tune | | 18 | EG 1 Attack | | 34 | Mixer 3 Level 1 |
| 3 | Osc 1 Fine Tune | | 19 | EG 1 Decay | | 35 | Mixer 3 Invert 1 |
| 4 | Osc 2 Wave | | 20 | EG 1 Sustain | | 36 | Mixer 3 Level 2 |
| 5 | Osc 2 Mod Amt | | 21 | EG 2 Attack | | 37 | Mixer 3 Invert 2 |
| 6 | Osc 2 Coarse Tune | | 22 | EG 2 Decay | | 38 | Mixer 4 Level 1 |
| 7 | Osc 2 Fine Tune | | 23 | EG 2 Sustain | | 39 | Mixer 4 Invert 1 |
| 8 | Filter 1 Cutoff | | 24 | LFO 1 Rate | | 40 | Mixer 4 Level 2 |
| 9 | Filter 1 Resonance | | 25 | LFO 2 Rate | | 41 | Mixer 4 Invert 2 |
| 10 | Filter 1 Mod Amt | | 26 | Mixer 1 Level 1 | | 42 | Mixer 5 Level 1 |
| 11 | Filter 1 Gain | | 27 | Mixer 1 Invert 1 | | 43 | Mixer 5 Invert 1 |
| 12 | Filter 2 Cutoff | | 28 | Mixer 1 Level 2 | | 44 | Mixer 5 Level 2 |
| 13 | Filter 2 Resonance | | 29 | Mixer 1 Invert 2 | | 45 | Mixer 5 Invert 2 |
| 14 | Filter 2 Mod Amt | | 30 | Mixer 2 Level 1 | |  |  |
| 15 | Filter 2 Gain | | 31 | Mixer 2 Invert 1 | |  |  |

#### モジュール ID

| ID | モジュール |
| ----- | ------ |
| 0 | なし（実行順の終端） |
| 1 | EG 1 |
| 2 | EG 2 |
| 3 | LFO 1 |
| 4 | LFO 2 |
| 5 | Osc 1 |
| 6 | Osc 2 |
| 7 | Filter 1 |
| 8 | Filter 2 |
| 9 | Amp 1 |
| 10 | Amp 2 |
| 11 | Mixer 1 |
| 12 | Mixer 2 |
| 13 | Mixer 3 |
| 14 | Mixer 4 |
| 15 | Mixer 5 |

#### シグナル ID

| ID | シグナル | | ID | シグナル | | ID | シグナル |
| ----- | ------ | - | ----- | ------ | - | ----- | ------ |
| 0 | なし（定数 0.0） | | 23 | Osc 1 Fine Tune | | 46 | Mixer 1 Level 1 |
| 1 | 定数 1.0 | | 24 | Osc 2 Wave | | 47 | Mixer 1 Invert 1 |
| 2 | 定数 0.5 | | 25 | Osc 2 Mod Amt | | 48 | Mixer 1 Level 2 |
| 3 | 定数 -0.5 | | 26 | Osc 2 Coarse Tune | | 49 | Mixer 1 Invert 2 |
| 4 | 定数 -1.0 | | 27 | Osc 2 Fine Tune | | 50 | Mixer 2 Level 1 |
| 5 | EG 1 Output | | 28 | Filter 1 Cutoff | | 51 | Mixer 2 Invert 1 |
| 6 | EG 2 Output | | 29 | Filter 1 Resonance | | 52 | Mixer 2 Level 2 |
| 7 | LFO 1 Output | | 30 | Filter 1 Mod Amt | | 53 | Mixer 2 Invert 2 |
| 8 | LFO 2 Output | | 31 | Filter 1 Gain | | 54 | Mixer 3 Level 1 |
| 9 | Osc 1 Output | | 32 | Filter 2 Cutoff | | 55 | Mixer 3 Invert 1 |
| 10 | Osc 2 Output | | 33 | Filter 2 Resonance | | 56 | Mixer 3 Level 2 |
| 11 | Filter 1 Output | | 34 | Filter 2 Mod Amt | | 57 | Mixer 3 Invert 2 |
| 12 | Filter 2 Output | | 35 | Filter 2 Gain | | 58 | Mixer 4 Level 1 |
| 13 | Amp 1 Output | | 36 | Amp 1 Gain | | 59 | Mixer 4 Invert 1 |
| 14 | Amp 2 Output | | 37 | Amp 2 Gain | | 60 | Mixer 4 Level 2 |
| 15 | Mixer 1 Output | | 38 | EG 1 Attack | | 61 | Mixer 4 Invert 2 |
| 16 | Mixer 2 Output | | 39 | EG 1 Decay | | 62 | Mixer 5 Level 1 |
| 17 | Mixer 3 Output | | 40 | EG 1 Sustain | | 63 | Mixer 5 Invert 1 |
| 18 | Mixer 4 Output | | 41 | EG 2 Attack | | 64 | Mixer 5 Level 2 |
| 19 | Mixer 5 Output | | 42 | EG 2 Decay | | 65 | Mixer 5 Invert 2 |
| 20 | Osc 1 Wave | | 43 | EG 2 Sustain | | 66 | Note Pitch |
| 21 | Osc 1 Mod Amt | | 44 | LFO 1 Rate | | 67 | Note Gate |
| 22 | Osc 1 Coarse Tune | | 45 | LFO 2 Rate | | 68 | Pitch Bend |

スロット 20〜65 には CC から届いた値が入ります。パラメータはデフォルトでは自分の CC を読んでいるわけです。
別のスロットを指させることがモジュレーションになります。CC のないものは、割り当てられるまで初期値のまま
です。

Note Pitch、Note Gate、Pitch Bend の 3 つは鍵盤がバスに載せるものです。Pitch Bend は最初からバイポーラで、
ホイールの端から端までがちょうど 1 単位、中央が 0 なので、ミキサーで下駄を履かせなくてもモジュール入力へ
入れられます。デフォルトではどこにも結線されていません。

スロット 0〜4 は何も書き込まない定数で、ソースではなく固定値を入れたい入力のためにあります。シグナル 0 は
誰も設定していないエントリが読む値でもあるので、未結線の入力は最初のスロットに入っているものに繋がるので
はなく、無音になります。シグナル 1 はモジュレーションのかかっていない入力が欲しがる値で、アンプの
モジュレーション入力をここへ向ければアンプはフルレベルのままです。負の定数はミキサーで信号を下へずらす
ためのもので、パラメータは自分の値を 0.0〜1.0 に丸めるので直接は取れません。

スロット 127 は、CC のないパラメータが使われない値を捨てる先です。ここを読ませてはいけません。

ID 番号はファームウェアのバージョンをまたいで安定ではありません。パッチは保存されないので、モジュールの
種類が増えたり、あるモジュールのインスタンスが増えたり、シグナルが増えたりすると、それ以降がすべて振り
直されることがあります。アップデート後はこれらの表を読み直してください。

#### 知っておきたいレンジ

2 つのチューンはどちらも CC 64 を中心とし、CC 1 ステップでちょうど 1 単位動きます。Coarse Tune は半音で
上下 5 オクターブまで、Fine Tune は 1 セントで上下 60 セントまでです。両者は加算されるので、どのピッチにも
届きます。

Osc Mod Amt はオフセットではなく深さで、ピッチの全域に届きます。最大にすると、バイポーラのソースがピッチ
を 5 オクターブ上下に振ります。ビブラートのつまみとしては CC 1 ステップが 50 セントと粗いので、デフォルト
のパッチでは LFO をまず Mixer 1 で 0.2 倍にしています。この経路なら半音のビブラートが CC 14、つまみの上端で
1 オクターブです。

Filter Gain はオーディオ入力がフィルタをどれだけ強く駆動するかを決め、それがそのままフィルタ自身の
サチュレーションの深さにもなります。デフォルトの CC 64 は、かつてオシレータ側で掛けていたレベルにあたり
ます。それより上げると、フィルタが音の大きい部分を圧縮しはじめます。

ミキサーは各入力をそれぞれのレベルとそれぞれの極性で受け取り、足し合わせます。Invert は 0.0 でそのまま、
0.5 で無音、1.0 で反転します。レベルの初期値は最大、Invert は 0 なので、入力を 1 つだけ結線したミキサーは
バッファになります。その入力を反転させればインバータに、2 番目だけを反転させれば減算器になります。
Mixer 1 だけは例外で、結線されているビブラート経路に合わせて両方のレベルが 0.2 になっています。

#### 例

- ビブラートはデフォルトで結線済みです。LFO 1 が Mixer 1 を経てオシレータのモジュレーション入力に届くので、
  CC 13 で深さ、CC 3 でレートを決められます
- フィルタのカットオフをノートのピッチに追従させる（キーボードトラッキング）: CC 99 = 2, CC 98 = 8,
  CC 6 = 66
- フィルタのカットオフを、自分の CC ではなくエンベロープで動かす: CC 99 = 2, CC 98 = 8, CC 6 = 5
- フィルタのカットオフを LFO で揺らす: CC 99 = 2, CC 98 = 8, CC 6 = 7 -- パラメータなのでレートは低めに
- アンプのゲインとフィルタのカットオフで 1 つの CC を共有する: CC 99 = 3, CC 98 = 16, CC 6 = 74
- エンベロープなしでアンプをフルレベルにする: CC 99 = 1, CC 98 = 11, CC 6 = 1
- フィルタのモジュレーション入力を切り離す: CC 99 = 1, CC 98 = 7, CC 6 = 0
- 深さ 60 セントのピッチエンベロープ: CC 99 = 2, CC 98 = 3, CC 6 = 5 で Osc 1 Fine Tune をエンベロープに
  向けると、チューニングが 60 セント低いところから 60 セント高いところまで動きます
- ノートの出だしでエンベロープがフィルタをより強く駆動する: CC 99 = 2, CC 98 = 11, CC 6 = 5
- ピッチを LFO ではなくエンベロープで動かす: CC 99 = 1, CC 98 = 14, CC 6 = 5 で LFO の代わりに EG 1 を
  Mixer 1 の 1 番目の入力に置き、あとは CC 13 で深さを決めます -- 14 で半音、124 で 1 オクターブです
- 2 本目のエンベロープを足して、フィルタとアンプでの共有をやめる: CC 99 = 0, CC 98 = 5, CC 6 = 2 で EG 2 を
  実行順に入れ、CC 99 = 1, CC 98 = 1, CC 6 = 67 で鍵盤からゲートをかけ、CC 99 = 1, CC 98 = 7, CC 6 = 6 で
  フィルタを EG 2 に渡します
- 2 つのオシレータをフィルタへ。Mixer 1 は塞がっているので、別のミキサーを使います。まず実行順から。
  各モジュールがこのサンプルで作られた値を読めるようにするためです: CC 99 = 0 で CC 98 = 4, 5, 6, 7 に
  CC 6 = 6, 12, 7, 9 を送ると EG 1, LFO 1, Mixer 1, Osc 1, Osc 2, Mixer 2, Filter 1, Amp 1 になります。
  次に CC 99 = 1, CC 98 = 4, CC 6 = 66 で Osc 2 にノートを与え、CC 99 = 1 で CC 98 = 16 と 17 に
  CC 6 = 9 と 10 を送って両方を Mixer 2 に入れ、CC 99 = 1, CC 98 = 6, CC 6 = 16 でミックスをフィルタへ
  送ります。デチューンは Osc 2 の Coarse Tune か Fine Tune で
- ピッチを両方向に曲げる CC。パラメータ単独ではできないことです。Mixer 1 はすでに Osc 1 のモジュレーション
  入力に繋がっているので、あとは混ぜるものを与えるだけです: CC 99 = 1, CC 98 = 14, CC 6 = 28 で LFO の
  代わりにフィルタのカットオフのコントロールスロットを 1 番目の入力に置き、CC 99 = 1, CC 98 = 15, CC 6 = 3
  で -0.5 の定数を 2 番目に置きます。レベルはどちらも 0.2 なので、ミキサーは CC から 0.5 を引いたものを
  ビブラートの深さで出力し、CC 74 がノートの上下にピッチを曲げるようになります
- 逆向きに効く CC。ミキサーに足し算ではなく引き算をさせます。CC 99 = 0, CC 98 = 6, CC 6 = 12 で Mixer 2 を
  実行順に入れ、CC 99 = 1, CC 98 = 16, CC 6 = 1 で定数 1.0 を 1 番目の入力に、CC 99 = 1, CC 98 = 17,
  CC 6 = 28 でカットオフのコントロールスロットを 2 番目に置き、CC 99 = 2, CC 98 = 33, CC 6 = 1 でその
  2 番目だけを反転させると、ミキサーは 1 から CC を引いたものを出力します。CC 99 = 2, CC 98 = 8, CC 6 = 16
  でカットオフ自身のソースをそのミキサーに向ければ、CC 74 は上げるほどフィルタを閉じるようになります
- フィルタを経路から外す: CC 99 = 0, CC 98 = 3, CC 6 = 9 のあと CC 99 = 0, CC 98 = 4, CC 6 = 0 -- そして
  アンプのオーディオ入力をオシレータに向けます: CC 99 = 1, CC 98 = 10, CC 6 = 9

#### 注意点

- モジュール入力（カテゴリ 1）は毎サンプル読まれ、スムージングされません。パラメータ（カテゴリ 2）は
  1 バッファに 1 回読まれ、受け取る側でスムージングされます。速いソースはモジュール入力へ、段階的なものは
  パラメータへ通してください
- パラメータのソースは 128 のスロットのどれでも指せます。68 より上のスロットは、何かが書き込むまで 0 を
  返します
- パラメータは自分の値を 0.0〜1.0 に丸めるので、Pitch Bend を除けば、正負どちらにも振れる信号をモジュール
  入力に渡す手段はミキサーだけです
- NRPN 用の CC も通常のコントロールとして保存されるので、パラメータを CC 6 に割り当てることもできます。
  その場合、パッチ編集を送るたびにそのパラメータが動きます

### デバッグ UART

- 速度: 115200 bps
- GP0 ピンと GP1 ピンを UART0 TX と UART0 RX に使います


### テストスクリプト

- WAV ファイルの出力: "spms1_output_wav.rb"


SPMS-1 (type-0) のライセンス
----------------------------

```
MIDI Synthesizer SPMS-1 (type-0) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
```

- 対象ファイル: `spms1_*.*`


Spinel のライセンス
-------------------

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

- ベースコミット: <https://github.com/matz/spinel/tree/5af61ae7d53e36ca59a8de5870f532360d88fd7c>
- 対象ファイル: `sp_*.*`
    - 注: ランタイムの一部のファイルは、MCU 向けに ISGK Instruments (Ryo Ishigaki) が変更しています
