MIDI Synthesizer SPMS-1 (type-2): 開発
======================================

- [README](./README.ja.md) / [English](./spms1_development.md)


## デバッグプリント

- USB CDC (同じケーブルで USB MIDI と並ぶシリアルポート)
- 代わりに UART も使えます: `SPMS1_DEBUG_PRINT_USE_USB_SERIAL` をコメントアウトしてください
    - 速度: 115200 bps
    - GP0 ピンと GP1 ピンを UART0 TX と UART0 RX に使います
- 常に有効です (`SPMS1_USE_DEBUG_PRINT`)。出力は core 0 が行うので、シンセへの影響はわずかです
- core 0 のループ 256 回 (約 0.3 秒) ごとに表示します:
    - `min` と `max`: 64 サンプルのバッファ 1 つの処理時間 (us)。前回の表示からの値で、持ち時間は 1333 us です。
      `min` はシンセだけの時間で、`max` との差は core 0 や割り込みからの干渉です
    - `gc roots` と `peak`: 使っている GC ルートの数 (サンプリング)。`sp_gc_roots` の大きさを決める目安です
    - `underruns`: 起動から出力の DMA がシンセを追い越した回数。音が鳴っていればそのたびにクリックが
      聞こえます。0 のままであるべきです。出力への書き込みは `min` と `max` が測る範囲の後にあり (PWM Audio で
      1 バッファ約 40 us、I2S ではそれより少ない)、バッファが持ち時間を超えたことはまずここに現れます


## 実行時の構成

- core 1 がシンセ (`Spms1_main`、RAM 上) を動かします。64 サンプル (48 kHz で 1.33 ms) のバッファごとに処理し、
  出力には 2 バッファを積みます。64 のままにしているのは、小さくするとサンプルあたりの負荷が増え、core 0 からの
  干渉に対する余裕も減るためです
- バッファ 1 つの処理は、平均で 1333 us 未満であれば足ります。それを超えるのはときどきだけにします。遅いバッファの
  遅れは出力に積んだバッファが吸収しますが、長くは続きません。出力に書き込むコードもシンセと同じく RAM に置く必要が
  あります。サンプルの丸めにフラッシュ上のライブラリ関数 `lroundf` を呼んでいたときは、PWM Audio で 1 バッファ 1255 us
  でも出力の DMA が 1 秒に数回シンセを追い越していました。`max` には現れませんでしたが、core 0 がフラッシュを使うときに
  この呼び出しが待たされていたためです。1 命令の切り捨てに替えて `underruns` は 0 になりました。どんな入力でも処理時間が
  ほぼ同じになるよう作っているので (「モジュールの書き方」を参照)、見るべきは最大値で、超えたことがあるかは
  `underruns` で分かります
- core 0 は MIDI を読み、1 ms 休みます (`delay(1)`)。1 回に USB MIDI を 4 バイト、UART MIDI を 8 バイト読み、
  31250 bps で届く約 3.2 バイトを上回ります。メッセージは次のバッファで反映されます
- Mute (NRPN 117/0) は出力を 4 ms でフェードアウト・インし、少なくとも 9 バッファ無音を保ちます。コーラスと
  リミッターの先読みはこの間に流れ切ります。モジュールは動き続けます
- Save (NRPN 117/2) は出力が無音になってから core 1 が書き込みます。リングバッファ全体を無音で埋め、EEPROM に
  書き、違いがあればコミットします。コミットの間 (約 50-100 ms) は core 0 も止まります。保存イメージと
  そのチェックは "spms1_midi_state.h" に説明があります


## PC シミュレーター

C のホスト ("sim_spinel"、"sim_render"、"web" の SPMS-1 Web) は、スケッチ自身の "spms1_midi_state.h"
("spms1_main.rb" が読むテーブルと、それを埋めるハンドラ) で MIDI を扱うので、そこを変えれば実機とすべての
ホストに一度に反映されます。シグナルバスと実行順もスケッチの "spms1_bus.h" のものを、CC の値と NRPN のテーブルの読み出しも
"spms1_midi_state.h" が読み込む "spms1_midi_read.h" のものを使います。"sim_cruby" は
両方を Ruby で書いた写しを "sim_cruby/spms1_c_midi.rb" に持っています。

シミュレーターは Windows で開発・テストしています。macOS と Linux は、各 API に沿って書いてはいますが、
試せる環境が手元にないため、ベストエフォートでの対応です。GitHub Actions のワークフロー
("SPMS-1 (type-2) Build (UF2 and Web)") で、Windows、macOS、Linux での sim_spinel と sim_render のビルドとオフライン・
レンダリング、Linux での CRuby との比較を確認しています。どちらもオーディオや MIDI のハードウェアでは
試していません (Linux では、sim_spinel を MIDI デバイスの代わりの FIFO と、音声用の ALSA の file
プラグインで一度動かしました)。

- Spinel 出力 (実験的): "sim_spinel" -- "spms1" の "spms1_main.c" とランタイムを、変更せずに Windows、macOS、
  Linux 向けにビルドし、リアルタイムで動かします。音声は PortAudio で出力し、MIDI は WinMM、CoreMIDI、
  または ALSA の raw MIDI デバイス ("/dev/snd/midiC*D*") で受けます。`sh sim_spinel/build.sh` でビルドし
  (Windows は Git Bash 上の MinGW gcc、macOS は clang、Linux は cc)、
  `build/sim_spinel/spms1_sim --midi-in NAME` で起動します。`--list` で MIDI 入力の一覧を表示します
    - ビルドの最初に、PATH 上、Windows では WSL の中にある Spinel で "spms1_main.c" を生成し直します。
      その際 "spms1/sig" の型シードを渡します。`--no-spinel` を付けるか、Spinel が見つからなければ、
      今ある "spms1_main.c" をビルドします
    - PortAudio は実行時に読み込みます。PortAudio プロジェクトの配布はソースのみなので、Windows では
      RubyInstaller の MSYS2 に `ridk exec pacman -S mingw-w64-ucrt-x86_64-portaudio` で入れ
      (シミュレーターはそこを探します)、macOS では `brew install portaudio`、Linux ではディストリビューションの
      パッケージ (Debian と Ubuntu では `sudo apt install libportaudio2`) で入れます。
      `SPMS1_PORTAUDIO_DLL` で任意のパスを指定することもできます
    - Linux: `--host alsa` か `--host jack` で PortAudio のホスト API を選びます (省略時は PortAudio の既定)。
      USB の MIDI キーボードやインターフェースは raw MIDI デバイスとして見えます。ALSA シーケンサーの
      ソフトウェアのポート (仮想キーボードなど) には raw MIDI デバイスがないので、使えません
- CRuby (実験的): "sim_cruby" -- "spms1_main.rb" そのものを CRuby で動かします。PortAudio は上と同じく
  入れたものを ffi gem 経由で使い、MIDI 入力は Windows では WinMM、macOS では unimidi gem で受けます:
  `ruby sim_cruby/spms1_sim.rb --midi-in NAME`。デフォルトのパッチはインタプリタではリアルタイムに
  間に合いません
    - オフライン (gem 不要): `ruby sim_cruby/spms1_render.rb` は下の "sim_render" と同じオプションを取り、
      "spms1_render_cruby.wav" に書き出します。`ruby sim_cruby/spms1_compare.rb A.wav B.wav` で 2 つの
      レンダリングを比べます
- Spinel 出力のオフライン・レンダリング: "sim_render" -- "sim_spinel" と同じく "spms1_main.c" と
  ランタイムを改変せずにビルドし、シンセ全体を実時間より速く動かして WAV ファイル (48 kHz、24 bit、
  ステレオ) に書き出します。シグナルバス、実行順、NRPN テーブルがすべて動くので、結線も実機と同じに
  鳴ります。必要なのは C コンパイラだけで、Linux、macOS、Windows (Git Bash 上の MinGW gcc) で動きます:
  `sh sim_render/build.sh` の後に `build/sim_render/spms1_render`
    - `--patch FILE`: エディタから Format "MIDI bytes (hex)" でコピーしたパッチ (';' 以降はコメント)。
      シンセがデフォルトのパッチを書いた後に、電源投入後に送ったパッチと同じく取り込まれます
    - `--score FILE`: 演奏する MIDI。1 行に 1 つずつ、秒単位の時刻と 16 進のバイト列を書きます
      (例: `1.5 80 3C 40`)。省略すると、ノート 60 を 0 秒から 1 秒まで鳴らします
    - `--seconds N` (デフォルト 4) と `--out FILE` (デフォルト "spms1_render.wav")
    - ピークとサンプルのハッシュを表示するので、2 つのレンダリングの違いがすぐ分かります。
      エディタの "Init" パッチは、パッチなしと同じハッシュになります。ハッシュは同じコンパイラ同士で
      比べてください: "spinel_rt_mcu_head.h" の `single-precision-constant` を GCC は (実機と同じく) 守り、
      clang は無視するので、両者では下位のビットが変わります
    - GC も確認し、次のどちらかに反すると終了コード 1 で終わります ("compare_with_cruby.sh" と
      GitHub Actions のワークフローも失敗します): シンセが鳴っている間に何も確保しないこと
      (実機では GC が音を途切れさせます)、"sp_gc.h" が MCU 向けに決めた `sp_gc_roots` の大きさ
      (`SP_GC_STACK_MAX`) が足りずに GC ルートが落とされないこと。前のリリースがボックス化しなかった値を
      ボックス化するリリースは前者で分かります。後者は実機に負担をかけないよう、ここでだけ
      `SP_GC_ROOT_OVERFLOW_CHECK` 付きで確認します
    - ビルドは "sim_spinel" と同じく、先に Spinel で "spms1_main.c" を再生成します (`--no-spinel` で省略)
    - `sh sim_render/compare_with_cruby.sh [--patch FILE] [--score FILE] [--seconds N]` は、同じパッチと
      スコアをこれと、"spms1_main.rb" そのものを動かす CRuby とでレンダリングして比べるので、Spinel が
      作った C が Ruby の書いたとおりに動くかが分かります。比較は短時間スペクトルで、信号に対する相対値です:
      float (Spinel の出力) と double (CRuby) ではオシレータの位相が少しずつずれ、サンプル単位では
      差が出ますが、スペクトルには出ません。精度による差は約 -35 dB 以下、結線の違いや CC 値の 4 段階の
      違いは -10 dB 以上になります。判定の上限は -25 dB です (`ruby sim_cruby/spms1_compare.rb --limit DB` で変更)。
      例外はコーラスです。LFO の位相のずれが、揺らしている遅延時間のずれになるので、レンダリングの数秒後に
      弾いた高い音は、精度の差だけで -25 dB を超えることがあります (6 秒後の C7 で約 -21 dB)。通す必要のある
      レンダリングは 4 秒程度にするか、コーラスの Mix か Depth を 0 にして外してください


## モジュールの追加

このシンセはフレームワークとして作られていて、音はその上に載るモジュールが作ります。

- "spms1/spms1_framework.rb": どのシンセでも共通の部分。ホストが提供する関数 (`Spms1::C`。
  "spms1.ino" と各シミュレーターが実装します)、MIDI からモジュールが受け取る値への変換、下の決まり事
- "spms1/spms1_main.rb": パッチを動かすループ。実行順、ルーティング、CC、ディスパッチ。
  大部分は patch_gen が書きます
- "spms1_patch.yaml" と "patch_gen": パッチのすべての番号と、各モジュールの配線
- モジュール ("spms1_osc.rb" など): それぞれ 1 つのクラス。MIDI のこともパッチのことも知りません

モジュールは、ループに何も手で書かずに追加できます。

1. クラスを "spms1" の中に、クラス名にちなんだファイル名で書きます。"spms1_" にクラス名を
   スネークケースにしたものを続けた名前で、`EnvGen` なら "spms1_env_gen.rb" です。いちばん小さい
   "spms1_amp.rb" から始めるとよいでしょう。クラスに必要なもの:
    - `initialize(sample_rate)`
    - パラメータごとの setter。バッファごとに 1 回、ソースの値で呼ばれます。値は YAML での指定に
      従ってユニポーラ 0.0..1.0 かバイポーラ -0.5..0.5 です。クランプして目標値として持ちます
    - `process(control_tick, input, ...)`。サンプルごとに 1 回、YAML に並べた順の入力で呼ばれ、
      メインの出力を返します。`control_tick` は 4 サンプルに 1 回 true で、全モジュールで同じ
      サンプルです。パラメータはここで `Dsp.smooth` により目標値へ平滑化します
    - それ以外の出力ごとのメソッド。`process` の直後に読まれます
2. "spms1_patch.yaml" の各一覧の、それぞれふさわしい位置に追加します。どの一覧も 0 から (モジュールは
   1 から) 欠番なしに順に番号を振り、patch_gen がこれを確認します。追加したあとは
   `ruby patch_gen/spms1_patch_gen.rb --renumber` で振り直せます:
    - `modules`: ID、`class`、`process` (`process` が受け取る順の入力のキー)
    - `signals`: 出力ごとのスロット。`module` と `output`、さらに `process` が返すもの以外の
      出力には、それを読むメソッドの `get`
    - `inputs`: 入力ごとのエントリ
    - `controls`: パラメータごとのエントリと、その setter の `set`
    - キーはラベルを大文字にし、語の間を `_` にしたものにします ("Pitch Mod 1 Pol" なら
      `PITCH_MOD_1_POL`)。これも patch_gen が確認します
    - 初期パッチで動かすなら `default_order` の動かしたい位置。モジュールはこの順に番号が振られます
3. `ruby patch_gen/spms1_patch_gen.rb` を (`--renumber` を付けて) 実行し、"spms1/spms1_main.c" を生成し直します
   (`sh sim_render/build.sh`)。そのあと音を確かめ (ルーティングするパッチファイルでレンダリング)、
   負荷を測ります (`sh sim_load/estimate.sh`)

patch_gen は、モジュールのファイルの `require_relative`、インスタンス、ルーティングと CC の読み出し、setter の呼び出し、
ディスパッチの `when` を "spms1/spms1_main.rb" に書きます。手で書いた場合と同じ
素直な直線的な Ruby なので、Spinel も同じものにコンパイルします。モジュールにかかるのは、
そのモジュール自身のコードの分だけです。そのうちパラメータの部分 (ソース、CC、setter。バッファごとに 1 回) は
独立した関数 `spms1_apply_parameters` に入り、同じく patch_gen が書く "spms1/spms1_parameters.h" が、
これを `Spms1_main` の外に置き (`noinline`)、RAM に置き、それ自体を flatten します。`Spms1_main` に
その flatten でインライン展開されると、これがレジスタに抱える値がサンプルごとのループを圧迫し、
パラメータを足すたびにループが長くなっていました。エディタと "spms1_patching.ja.md"、"spms1_patching.md" の NRPN の表にも反映されます。

### モジュールの書き方

バッファの実行時間は、何が来てもほぼ同じになるようにします。"sim_load" が全モジュールを動かして
測る時間が、どんなパッチ、CC、ノートが来てもバッファにかかる最長の時間になることを目指して、
モジュールはできるだけ次を守ります。

- 値によらず、毎サンプル、毎バッファ同じ処理をする。各パラメータの係数は毎バッファか毎コントロール
  ティック計算し、変わったときだけ計算することはしない
- 値で分岐しない。クランプは三項演算子の入れ子 `(x < 0.0) ? 0.0 : ((x > 1.0) ? 1.0 : x)` で書く
  (select にコンパイルされます)。`control_tick` での分岐はかまいません。全モジュールが同じ
  サンプルで通り、測定にはそのすべてが含まれます。ただし、三項演算子が select になるかは GCC が
  決めます (「生成コードの確認」を参照)。インスタンス変数 2 つのように、読み込みが要る値の間で選ぶと
  分岐になることがあり、リテラル 2 つの間で選んでその結果を掛ける形なら分岐になりません
  (Amp のリミッターが速さを選ぶやり方)。ただし、それも確実ではありません。今のビルドでは、オシレータの
  位相の折り返し `x -= (x < 1.0) ? 0.0 : 1.0` が引き算を飛び越す短い分岐になっていて、位相が周期のどこに
  あるかによって、バッファごとに最大約 540 サイクル (3.5 us、0.3%) ばらつきます。周期がバッファより長い低い音で
  最も大きく (バッファ全体が折り返しの片側に収まることがあるため)、1 バッファに多くの周期が入る高い音で最も
  小さくなります。最大値は見積もりの max に表れます (`--note` で音を変え、`--buffers 40` で十分な数を測ります)。別の書き方 (`x -= x.to_i.to_f`、または GCC の分岐の推定を止める) にすると
  毎バッファ同じになりますが、46 us 以上重くなるので、そのままにしています
- カーブはクラスで一度作るルックアップテーブルと線形補間で求め、入力によって時間が変わる
  ライブラリ関数 (`Math.sqrt`、`Math.exp` など) は使わない
- 演奏中に何も確保しない。配列はすべて `initialize` で作る
- サンプルごと、バッファごとのコードでは名前付き定数よりリテラルを使う。Spinel は名前付きの Integer
  や Float の定数を実行時のグローバル変数として出力し、読むたびにロードし、それとの比較も畳まれません
- ゼロへ減衰する状態は `Dsp.flush_tiny` を通し、デノーマルに沈まずゼロに落ちるようにする
- Spinel が型を決めきれず演算をボックス化する場合は、"spms1/sig" の型シードで直す
  (やり方は "spms1/sig/spms1_dsp.rbs" にあります)

ブランチレスは目指すものであって、最後の 1 命令まで徹底する決まりではありません。結果はコンパイラ
などに依存し、まれな分岐や軽い分岐はそのままにしています (リミッターのホールドのブロックの終わり、
25 ms に 1 回など)。そのため、バッファの実行時間は値によって多少ぶれ、最悪実行時間も "sim_load" の
測定値を多少上回ることがあります。バッファの時間に残している余裕は、そのためのものです。


## 処理負荷の見積もり

"sim_load" は、Raspberry Pi Pico 2 の実機なしで、シンセが各オーディオバッファの時間をどれだけ使うかを見積もります。
`sh sim_load/estimate.sh [--profile]` で、GitHub Actions のワークフローと同じく arduino-cli でスケッチをビルドし、
その `Spms1_main` を Cortex-M33 のエミュレータ (Unicorn) で動かして、`start_debug_measure` から
`stop_debug_measure` まで (実機の Debug Print が測る区間) の命令数を数えます。デフォルトのパッチで、ノートを
押したままの状態です。

- バッファあたりの命令数 (ビルドしたコードについて正確な値) と、153.6 MHz でのサイクル数と時間を表示し、
  48 kHz で 64 サンプルのバッファ 1 つぶんの 1333 us と比べます。サイクル数と時間は 1 次の近似モデルによる
  見積もりです ("sim_load/spms1_load_estimate.py" の `cost` を参照)
- `--profile` でサイクルの行き先の関数を、`--modules` でモジュールごとの負荷 (下記。ELF のデバッグ情報と
  実行から求めます) を表示します。`--elf FILE` で別にビルドした ELF (別のコミットのものなど) を見積もれるので、
  2 つの版を比べられます。そのほかは `--help` を参照してください
- `--patch FILE` と `--score FILE` は sim_render と同じものを再生します。パッチ (16 進の MIDI バイト) は最初の
  バッファの前に、スコア (秒単位の時刻と MIDI) はその時刻を含むバッファの前に、スケッチの MIDI ハンドラが書く
  テーブルへ書き込みます。`--per-buffer` でバッファごとの値を表示します。バッファ数を増やす (`--buffers 60`) と、
  値によってバッファの処理時間がどれだけ動くかが分かります。"sim_load/scenarios" のファイルは、Mixer 2 を上限に
  張り付かせる、リミッタを切る、変調を最大にする、フィルタを自己発振させる、ディレイを最短にする、10 ms ごとに
  ノートを弾いてグライドとベンドを掛ける (`--gate 0`) 状況です。追加したコミットでの測定では、最後のものが最も
  大きく動き、約 700 サイクル (207599〜208300。v0.4.1 では 208145〜208676) で、エンベロープとグライドの状態の
  切り替わりによるものです。ほかはデフォルトのパッチと同じ 207366〜207969 の範囲に収まります
- Python 3 と `pip install unicorn capstone pyelftools numpy` が必要です。各自でインストールするもので、ここには
  含めていません。Unicorn は Python バインディングが BSD ライセンス、エミュレータ本体が GPLv2、Capstone と
  NumPy は BSD ライセンス、pyelftools はパブリックドメインです

最新の版の見積もりです。リリースのたびに置き換えます (前の版のものはこのファイルの履歴にあります。デフォルトの
パッチ、153.6 MHz、1333 us に対して)。モジュールの設計どおり、ノートを押していてもいなくても、バッファの処理時間は
ほぼ同じです:

| 版 | ノートあり (平均 / 最大) | ノートなし (平均 / 最大) |
| :-- | --: | --: |
| v0.4.1 | 208204 / 208204 サイクル、1355 us (102%) | 208556 / 208556 サイクル、1358 us (102%) |

見積もりは、実機の Debug Print (v0.4.0: min 1253 us、max 1256 us、約 94%) より 8% ほど大きめなので、102% でも
バッファが持ち時間を超えているわけではありません。超えているかは実機の `underruns` で分かります。

`--modules` による各モジュールの負荷です (同じ版、ノートあり)。「単体」は
そのモジュールのメソッド (process、出力、smooth_parameters) のサイクル、「共通込み」はそれに共通部分の分担
(入力の信号バスからの読み出し、出力の書き込み、実行順の振り分けの均等割り) を足したものです。残りの共通部分は、
サンプルのループ、出力、MIDI、CC です:

| モジュール | 単体 | 共通込み |
| :-- | --: | --: |
| Filter 2 | 11.9% (159 us) | 13.7% (182 us) |
| Filter 1 | 11.9% (158 us) | 13.6% (181 us) |
| Osc 2 (Sync あり) | 9.5% (126 us) | 11.3% (151 us) |
| Osc 1 | 6.3% (84 us) | 7.8% (105 us) |
| Delay 1 | 6.5% (86 us) | 7.7% (103 us) |
| Chorus 1 | 6.4% (85 us) | 7.4% (99 us) |
| Amp 1 | 4.7% (63 us) | 6.0% (80 us) |
| LFO 1 | 3.1% (41 us) | 4.0% (53 us) |
| Pitch 1 | 2.7% (37 us) | 3.9% (53 us) |
| Mixer 1 | 1.6% (22 us) | 2.9% (39 us) |
| Mixer 2 | 1.6% (22 us) | 2.9% (39 us) |
| EG 1 | 2.2% (29 us) | 2.9% (39 us) |
| EG 2 | 2.2% (29 us) | 2.9% (39 us) |
| Noise 1 | 1.9% (26 us) | 2.9% (38 us) |
| 残りの共通部分 | | 11.7% (156 us) |


## GitHub Actions

"../.github/workflows/spms1-type2.yml" の "SPMS-1 (type-2) Build (UF2 and Web)" を手動で実行します
(リリース時など、Actions タブの "Run workflow" で)。毎回、以下をすべて行います:

- UF2: "spms1/spms1.ino" を Arduino-Pico 6.3.0 で PWM Audio 版と I2S 版にコンパイルし、UF2 ファイルを
  成果物 (artifact) として残します
- SPMS-1 Web: "spms1_web_synth.js" をビルド・テストし、成果物として残します
- シミュレーター: "sim_spinel" と "sim_render" を Linux、macOS、Windows でビルドしてレンダリングし、
  Linux では CRuby とのレンダリングの比較もします。Linux では最初に、"spms1_patch.yaml" から生成される
  ファイルが最新かを確認します ("patch_gen/spms1_patch_gen.rb --check")。また、ランタイムの関数と変数がどこで宣言されても
  同じ型かも確認します ("spinel_mcu/lto_type_check.sh")。片側で float、もう片側で double と宣言された関数は、
  ほかでは気づけません (MCU 向けに `#define double float` でランタイムを float にしているため、起こりやすい誤りです)
- Spinel: README が指定するリリース (Spinel の "Release:") をビルドし、"spms1_main.c" が .rb ファイルから作られるものと一致するかを確認します。
  また、ランタイムのファイルがそのリリースに "spinel_mcu/spinel_mcu.patch" を当てたものかを確認します (下記参照)
- "commit_package" を選び、上記がすべて通ると、UF2 ファイル ("bin") と "spms1_web_synth.js" を選んだブランチに
  コミットします (ビルドの後でソースが変わっていた場合と、何も変わっていない場合はコミットしません)


## リリース

基本的に、次の順で行います (日付は JST):

1. 実機で確認します (PWM Audio 版と I2S 版)
2. その版の主な変更を "spms1_change_history.md" にまとめます (新しい順)
3. バージョンを変えます: "README.md" と "README.ja.md" の 1 行目、エディタの `<span class="version">`、
   "spms1_midi_chart.md" の Version と Date (MIDI の仕様が変わらなくても毎回)
4. 負荷を見積もり (`sh sim_load/estimate.sh`、ノートありと `--gate 0`、`--modules`)、「処理負荷の見積もり」の表を置き換えます
5. "type-2: Version X.Y.Z" としてコミットします
6. develop でワークフロー (上記) を "commit_package" 付きで実行し、UF2 ファイルと SPMS-1 Web を更新します
7. プルリクエスト "type-2 vX.Y.Z" で develop を main にマージします


## Ruby と違うところ

シンセは CRuby も含め Ruby のとおりに動きます ("sim_cruby" 参照)。ただし MCU では賄えない次の点は別です。
どれも 1 か所で行い、そこに理由を書いてあります。これ以外の Spinel やそのランタイムへの変更は、
プログラムの動きを変えません:

- Float は double でなく 32 ビットの float です。RP2350 の FPU は単精度だけなので。"sp_types.h" の
  `SPINEL_FLOAT32` ("spinel_mcu/spinel_mcu.patch" による) が決め、生成コードの Float リテラルを float に
  し ("spinel_rt_mcu_head.h")、生成コードの `double` を `float` と読み替えます ("spinel_rt_mcu_cold.h")。
  結果は CRuby とは精度のぶん違い、sim_cruby の比較はそれを見込んでいます。これがないと、Float の
  演算はすべてソフトウェアになります
- Integer の `+ - *` は Bignum に広がらず、ポインタ幅 (RP2350 では 32 ビット) で桁あふれのまま回ります。
  `spinel --int-overflow=wrap` と同じです ("spinel_rt_mcu_head.h" の `SP_INT_OVERFLOW_MODE_WRAP`)。シンセの
  整数は 32 ビットに遠く届かない添字やカウンタです。これがないと、検査が毎サンプルのコードの命令の
  約 8% になります
- OS が要るもの (ファイル、プロセス、ソケット、Fiber、スレッド。下記の `SPINEL_BARE_METAL` 参照) は
  ありません。GC のバッファは SRAM に合わせてあり、GC ルートを 1024 より深く重ねるプログラムは
  残りを失います。sim_render はそれを報告します ("sp_gc.h" 参照)


## Spinel の更新

"spms1" のランタイムのファイルは、README が指定するリリースの Spinel の `lib` (と `lib/regexp`) のすべてです。
MCU 向けの変更は 2 か所にまとめてあります:

- "spinel_rt_mcu_head.h"、"spinel_rt_mcu_libm.h"、"spinel_rt_mcu_cold.h": MCU 向けに足すもの --
  シンセ本体のセクションと pragma、オーバーフロー検査なしの Integer 演算 (`SP_INT_OVERFLOW_MODE_WRAP`。
  `spinel --int-overflow=wrap` と同じ)、数学関数の float 版、そして "spinel_rt.h" の最後で生成コードを
  float のランタイムにつなぐもの (下記) とスケッチの "spms1_bus.h"、"spms1_midi_read.h"、"spms1_parameters.h"。"spinel_rt.h" にはそれぞれの `#include` 行だけがあります
- "spinel_mcu/spinel_mcu.patch": Spinel 自身のファイルへの変更 -- Float を表す `double` を `sp_float`
  で書いたランタイム、POSIX 部分の `#if 0` による除外 (中身がリリースで変わってもパッチが
  当たりやすいように)、全体が POSIX 前提のファイルの `SPINEL_BARE_METAL` による除外 (下記)、
  SRAM に収まる GC のバッファ、配列の読み書き (`sp_FloatArray_get`/`set`、`sp_IntArray_get`) で範囲内の
  場合を他の検査より先に置くこと (残りの検査はそのまま関数の外へ。アクセスの動きは同じで、コストだけが
  変わります)、Float#to_i ("sp_alloc.h" の `sp_float_to_i_checked`) をインラインにし、整数演算のオーバー
  フロー検査と同じく検査を外すこと (NaN、無限大、Integer の範囲を超える Float でも例外を出さず、プロセッサの
  変換結果になります。マイコンでは例外でも音が止まるだけなので同じことで、検査が使っていたバッファあたり
  31 us がなくなります)。変更するファイルの隣には、
  リリースのままのコピー "NAME.orig" があります
- "sp_cold_bare_metal.c" と "spinel_mcu/sp_cold_bare_metal.patch": ベアメタル向けの "sp_cold.c" (下記)。
  リリースの "sp_cold.c" とは分けてあり、そちらは丸ごと外すこと以外は元のままです

RP2350 の FPU は単精度だけなので、Float は float です。ランタイム全体を "sp_types.h" の
`SPINEL_FLOAT32` が決めます: ここでは 1 で、0 にすると Spinel のとおり double になり、結果は CRuby と
同じです。生成コードはキャストや一時変数でまだ `double` と書き、Float の定数に `DBL_EPSILON` などを
使うので、"spinel_rt_mcu_cold.h" の最後に `#define double float` と `DBL_*` の代わりの `FLT_*` があり、
これは生成コードにだけ効きます。`Float#to_s` は、同じ float に読み戻せる最短の桁を出します
(`0.1`、`0.33333334`)。

シンセの下に OS はありません。"sp_types.h" の `SPINEL_BARE_METAL` (ここでは 1) が、ランタイムのうち
C ライブラリより多くを必要とするものを外します: POSIX が全体の前提のファイル ("sp_cold.c"、"sp_fiber.c"、
"sp_io.c"、"sp_net.c"、"sp_process.c"、"sp_process_status.c"、"sp_sched.c"、"sp_system.c") を丸ごと。
"sp_cold.c" の代わりには "sp_cold_bare_metal.c" をビルドします。これは "sp_cold.c" から、C ライブラリより
多くを必要とする関数 (ファイル、ディレクトリ、プロセス、ソケット、外したファイルを使うもの) を外したもので、
リリースを取り込むときに "spinel_mcu/sp_cold_bare_metal.patch" で作られます。シンセが毎サンプル呼ぶ
`Float#to_i` は、そこで "sp_alloc.h" のインライン関数にしてあり、flash から呼ばれずにシンセ本体へ
展開されます。残りはそのままビルドし、シンセが使わないものはリンカが捨てます。シミュレーターと
SPMS-1 Web も同じようにランタイムをビルドします。

新しいリリースは GitHub Actions で取り込むので、特定の OS は要りません:

1. "SPMS-1 (type-2) Try a Spinel Release" ("../.github/workflows/spms1-type2-spinel-try.yml") を、
   ブランチを選び、リリースのタグを指定して手動で実行します。`sh spinel_mcu/update.sh update TAG` で
   リリースを取り込み (ファイルをコピーし、パッチを当て、README.ja.md と README.md のリリース名を
   書き換えます)、"spms1_main.c" を再生成し、ランタイムの型が食い違っていないかを確かめ
   ("spinel_mcu/lto_type_check.sh"、"GitHub Actions" 参照)、CRuby とレンダリングを比べ (リリースのせいでシンセが
   鳴っている間に確保したり、GC ルートが収まらなくなったりすると失敗します)、取り込む前と後の
   UF2 をビルドします (`sp_float` が `float` でなくなるとビルドが止まります)。何もコミットせず、
   変わったものを成果物 (artifact) として残します
2. 実行結果のまとめを見ます。"spinel_mcu/size_report.sh" が 2 つのビルドを比べ、RAM 上のシンセ本体
   (`Spms1_main`)、RAM、flash がどれだけ増えたかを表示し、2% を超えると警告します。本体が大きく
   なると 1 サンプルあたりの命令が増えますが、音にもシミュレーターにも表れません。リリースが
   `lib` に足したファイルもここに出ます (ほかと同じくコピーされます): POSIX を必要とするものは
   ビルドできないので、ほかと同じく `SPINEL_BARE_METAL` で外します ("NAME.orig" にコピーし、中身を
   `#include "sp_types.h"` `#if !SPINEL_BARE_METAL` と `#endif` で囲み、`sh spinel_mcu/update.sh save`)
3. 成果物の "spinel-TAG.diff" をリポジトリの最上位で当て (`git apply spinel-TAG.diff`)、
   コミットして、ビルド用のワークフローを実行します。その Spinel ジョブが結果を確認します
   (`sh spinel_mcu/update.sh check`)
4. 当たらなかった hunk は成果物の "NAME.rej" に入り、実行は失敗します。それ以外はすべて diff に
   入っています。diff を当てた後で手で変更し、`sh spinel_mcu/update.sh save` でパッチを書き直します
   (diff だけで動きます。Windows では Git Bash にあります)。そのうえで、ブランチで手順 1 を
   もう一度実行します

手動実行のワークフローは GitHub がデフォルトブランチのものを使うので、デフォルトブランチに
入ってから実行できます。実行するブランチはそのとき選べます。

ランタイムのファイルをさらに変更するときは、"NAME.orig" がなければ先にコピーしてから編集し、
`sh spinel_mcu/update.sh save` を実行します。

スクリプトはこのフォルダからローカルでも実行できます: `sh spinel_mcu/update.sh update TAG`、
`sh spinel_mcu/update.sh check` (どちらも `--spinel DIR` で、clone せずにチェックアウト済みの
Spinel を使います)、`sh spinel_mcu/size_report.sh BEFORE.elf AFTER.elf` (`arduino-cli compile
--output-dir DIR` が DIR に残す .elf)。git、diff、GNU patch が必要で、size_report.sh には
Arduino-Pico コアのツールが必要です。動作を確認しているのは Linux だけです。Windows では Git Bash に
すべてあり、macOS では `brew install gpatch` で GNU patch が入ります。

パッチの大半は、Spinel 自体にいくつかのビルドオプションがあれば不要になります。それを提案する Issue の
**下書き** が "spinel_mcu/UPSTREAM_PROPOSAL_DRAFT.md" にあります (**未投稿**)。


## 生成コードの確認

サンプル単位の処理に手を入れたら、書き込む前にコンパイラが何を生成したか見る価値があります。
Ruby でブランチレスに書いても、バイナリがブランチレスになるとは限りません。決めるのは GCC で、
その判断は関数全体に依存します。スケッチのフォルダ "spms1" で、
Spinel の出力を単体でコンパイルします。

```
arm-none-eabi-gcc -c -g -mcpu=cortex-m33 -mthumb -march=armv8-m.main+fp+dsp -mfloat-abi=softfp -mcmse -std=gnu23 -Os -I. -o out.o spms1_main.c
```

コンパイラは Arduino-Pico コアに同梱されており、`packages/rp2040/tools/pqt-gcc` の下にあります。
1 分ほどかかります。あとは `arm-none-eabi-objdump -d out.o` で `Spms1_main` の中の条件分岐を数え、
`arm-none-eabi-objdump --dwarf=decodedline out.o` でアドレスを元の Ruby の行に戻せます。生成された
C が `.rb` を指す `#line` を持っているので、対応は最後まで残ります。

読む前に知っておくべきことが 4 つあります。

- 上の `-Os` は実際の設定ではありません。"spinel_rt_mcu_head.h" が `#pragma GCC optimize ("O3")` を
  持っており、この翻訳単位ではコマンドラインの指定を上書きします。`-O3` を渡しても `-Os` を
  渡しても結果は変わりません
- シンセ本体は `.text` にありません。"spinel_rt_mcu_head.h" の `#define main` が `.time_critical` に
  置きます。2 つのビルドが同じコードだと示すには、それぞれに
  `arm-none-eabi-objcopy -O binary --only-section=.time_critical` をかけてバイト比較します。
  コメントだけの変更は "spms1_main.c" の `#line` を全部動かして他は何も変えませんが、その確認も
  この方法です
- 単体コンパイルは実際のファームウェア より 2000 命令ほど軽く出ます。本番のビルドでは `flatten` が
  スケッチ側の関数まで `Spms1_main` に取り込むからです。単体ビルド同士の差分は信用できますが、
  絶対値は信用できません。絶対値は Arduino のビルドキャッシュに残る `.elf` から取ります
- テスト用の小さな関数でうまくコンパイルされる書き方が、1 万 2000 命令の `Spms1_main` に
  インライン展開されたあとも同じとは限りません。小さなファイルではなく、実物で測ります
