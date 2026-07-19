<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-17. -->
<!-- agent-ninja-START -->
## Agent Skills

> **IMPORTANT**: Prefer skill-led reasoning over pre-training-led reasoning.
> See [Agent Skills](.github/skills/README.md) before working on tasks covered by these skills.

<!-- agent-ninja-END -->

## 死因（killer.name）の日本語化と英語交じり回避方針

ハイスコア（`record`）との互換性を維持するため、死因を表す `svk.killer.name` や `multi_reason` は、原則として元の英語キーのままコード内で設定し、表示時に動的に翻訳するアプローチを徹底してください。

1. **共通翻訳関数の利用**:
   - すべての死因表示（墓石、ダンジョン概要、ゲームオーバー、トップテン一覧）は、共通して `src/topten.c` の `jp_translate_killer_text_for_display` を経由します。翻訳のルールはすべてこの関数内に集約してください。

2. **動的日本語翻訳の適用**:
   - 死因テキストにモンスター名やアイテム名が含まれる場合、文字列の静的なハードコードでの置換ではなく、以下の検索関数を組み合わせて動的に日本語名を解決してください。
     - モンスター名: `name_to_mon(eng_name, &gend)` でIDを取得し、`jp_pmname_from_idx(mndx, 0)` で日本語名に翻訳。
     - オブジェクト名: `name_to_otyp(eng_name)`（`topten.c` 内のヘルパー）でIDを取得し、`jp_item_name(otyp)` で日本語名に翻訳。

3. **定型パターンへの対応**:
   - `tripping over a [Monster] corpse`（死体につまずく）や `kicking a [Monster] barefoot`（裸足で蹴る）などの定型的な死因表現も、モンスター名部分を動的に切り出して日本語文（例：「〜の死体につまずいたことで石化した」）に再構築してください。

## 神の名前の日本語表示方針

神の名前（`align_gname()` や `u_gname()` が返す文字列）をプレイヤーへの表示メッセージやログ（`livelog`など）に含める際は、英語のまま表示されてしまうのを防ぐため、必ず日本語の表示用変換関数を経由させてください。

1. **アライメントに対応する神の名の取得**:
   - アライメント値（`aligntyp`）から日本語の神の名前を取得して表示する場合は、`jp_align_gname_for_display(alignment)` を使用してください。

2. **英語の神の名の文字列からの翻訳**:
   - 既に英語の神の名前の文字列（`gnam`）がある場合は、`jp_gname_for_display(gnam)` を通して日本語名（カタカナ）に変換してから表示してください。

3. **例外（内部ロジックでの英語の維持）**:
   - 死因 (`svk.killer.name`) など、セーブデータ互換性やスコア判定で内部的に使われる識別キーとして設定する場合は、表示時以外は英語のままとします。

## イベント履歴（livelog）および画面メッセージの日本語表示方針

ゲーム内イベント履歴（livelog / chronicle）や画面に表示されるメッセージを日本語化・翻訳する際は、以下のルールを徹底してください。

1. **固有名詞の翻訳統一**:
   - `Sokoban` の翻訳は必ず「倉庫番」を使用してください。「ソコバン」などのカタカナ表記は避けてください。

2. **英語特有の表現・関数の排除**:
   - 日本語化に伴い不要となる英語の不定冠詞付与関数 `an()` や、代名詞取得関数 `uhis()`, `uhim()` は削除し、日本語の助詞や「あなた」などに適宜置き換えてください。
   - 店主などのモンスターの代名詞を返す関数 `noit_mhe()`, `noit_mhim()`, `noit_mhis()` なども同様にメッセージ内で使用せず、日本語の「自分」「相手」などに置き換えるか、プレースホルダー自体を削除して文章を整理してください。

3. **日本語の語順への再構築**:
   - 英語の語順（例: `entered <Level>`）をそのまま直訳せず、日本語として自然な語順（例: `<Level>に入った`）にフォーマット文字列と引数の順序を再構築してください。

4. **動的な日本語名の解決**:
   - 職業名、肩書、種族名などのプレイヤー情報は、イベント履歴（livelog）や画面に表示される通常メッセージ（`pline` 等での出力）において、英語の文字列（`gu.urole.name.m` など）をそのまま出力して英語交じりになるのを防ぐため、必ず以下の表示用日本語化関数を経由させてください。
     - 職業名: `jp_role_name_for_display(flags.initrole, gender)`
     - 肩書: `jp_rank_of_for_display(u.ulevel, Role_switch, gender)`
     - 種族名: `jp_race_noun_for_display(Race_switch)`

5. **可変引数マクロのフォーマットと引数の完全一致確認**:
   - `pline()`, `You()`, `pline_The()`, `impossible()` などの可変引数マクロを日本語化・修正する際は、フォーマット文字列内の指定子（`%s`, `%c`, `%d`等）と、渡す実引数の個数および型が完全に一致していることを必ず確認してください。
   - 特に英語メッセージの `%c`（文字型、`.` や `!` など）をそのまま残すか `%s`（文字列型）に誤って変更してしまうと、メモリアクセス違反（`strnlen` でのクラッシュ）を引き起こします。
   - フォーマット文字列の順序を入れ替える場合は、渡す引数の順序もそれに合わせて並び替えてください。

6. **genocide の翻訳統一**:
   - ゲーム内メッセージ、イベント履歴、コマンド説明文（`cmd.c`の`#genocided`など）において、`genocide`（根絶、虐殺等）の訳語は必ず「**虐殺**」に統一してください。
   - プレイモード（通常プレイかデバッグモードか）によってコマンド一覧等の説明文を動的に切り替える処理を行う場合も、「虐殺」の文字列を対象として置換するように実装してください。

7. **行動中断メッセージ（occupation text）の日本語化と助詞重複防止**:
   - 複数ターンにわたる自動行動（`set_occupation`で処理されるもの）のテキストを定義する際は、中断時のメッセージ「あなたは%sをやめた.」と自然に繋がる名詞（体言）または「〜するの」の形で設定してください（例: 「探索」「待機」「缶を開けるの」など）。
   - 「脱衣」「武装解除」などのように、完了・継続メッセージで「を」を用いる行動については、中断時に「〜ををやめた」という助詞の重複が発生するのを防ぐため、活動テキスト自体から「を」を排除し（例: 「脱衣」）、完了・継続メッセージの出力側（例: `You("%sを終えた.", ...)`）で「を」を補う設計を徹底してください。


## アイテムの日本語助数詞（単位）表示方針

1. **GEM_CLASS オブジェクトの助数詞**:
   - 石（`rock`）や宝石（`gem`）など、スリングなどで投射可能な武器属性（`is_ammo` や `is_missile`）を持つ `GEM_CLASS` のアイテムについても、日本語の助数詞（単位）は「本」ではなく「個」と表示されるようにしてください（例: 「10個の石」、「2個の紫の石」）。

## Windows (MSVC) 開発における C コード記述とビルドの制約

1. **strcasecmp の使用禁止と strcmpi / strncmpi の徹底**:
   - Windows (MSVC) ビルド環境では `strcasecmp` や `strncasecmp` は利用できず、リンクエラー（外部シンボル未解決）になります。
   - 大文字小文字を無視した文字列比較を行う場合は、NetHackで定義されているマクロである `strcmpi` / `strncmpi` を必ず使用してください。

2. **AIエージェント用ビルドスクリプトの利用**:
   - Windows環境でコードのビルド確認を行う際は、ルートのCMakeではなく、用意されているエージェント用バッチファイル `sys\windows\vs\build_one.bat` を優先して実行してください。これにより、環境の自動セットアップと `Release|x64` 構成でのビルドが一貫して行われます。

3. **Windows (PowerShell) 環境での Git コミット・コマンド実行の制約**:
   - `run_command` 等でコマンドを連結する際、PowerShell では `&&` を使用すると構文エラーになるため、1行ずつ実行するかセミコロン `;` 等で区切ってください。
   - 日本語のコミットメッセージを指定する場合、PowerShell 上で文字化けが発生するのを防ぐため、メッセージを一時ファイル（UTF-8）を artifacts の scratch ディレクトリ（例：`<appDataDir>\brain\<conversation-id>\scratch\commit_msg.txt`）に書き込み、`git commit -F <ファイルパス>` でコミットを行ってください。コミット完了後、一時ファイルは削除してください。

4. **Android (WSL + Gradle) 環境での自動ビルドスクリプトの利用**:
   - Android環境向けに `libnethack.so` のコンパイルおよびAPKビルドを行う際は、用意されているPowerShellスクリプト `sys/android/build_android.ps1` を実行してください。
   - このスクリプトを実行する際は、PowerShell上で `& .\sys\android\build_android.ps1` の形式で呼び出します。これにより、自動的に WSL (Ubuntu-26.04) 上での C ライブラリのビルドと、Windows 側での `ANDROID_HOME` の設定を伴う `gradlew.bat` による APK パッケージングが一貫して行われます。

5. **Android版における日本語データファイル（データベース・ヘルプ）の配置方針**:
   - Androidポートでは、データファイル群（`data`, `rumors`, `oracles` 等）およびヘルプ・メニューなどのデータファイル群を個別のファイルとして `assets/nethackdir/` にパッケージングし、アプリ起動時に Java 側の `UpdateAssets.java` を経由して端末のストレージ（データディレクトリ）にコピーして読み込みます。
   - `data_jp` や `help_jp` といった `_jp` 接尾辞を持つ日本語ファイルをそのまま別ファイル名としてアセットに配置すると、Java側のアセット取得バグやC側のファイルオープン制限によって、正常にコピーまたはロードされず、英語版データにフォールバックして表示されてしまう問題が発生します。
   - 解決策として、Androidポートでは英語版データファイル自体を完全に排除し、**日本語版データを英語版と同じ標準ファイル名（例：`data`, `help`, `rumors` 等）としてアセット化**します。
   - 具体的には、`sys/android/Makefile.top` 内の `dofiles-nodlb` ターゲット等のアセットコピー処理直後に、日本語ファイル（`data_jp` 等）を元の英語名（`data` 等）へ上書きリネーム（`mv -f`）して格納します。
   - データファイルアセットを変更・追加した際は、上書きインストール時に強制的にアセットコピーがトリガーされるよう、必ず `sys/android/app/assets/ver` 内のバージョン値（整数値）をインクリメントしてください。

6. **デバッグ用一時コード・ログ出力のクリーンアップ**:
   - デバッグや診断の目的で一時的に埋め込んだログ出力処理（例：Cコード内の `__android_log_print` や print文など）や、ログ出力のためだけに一時的に追加したリンクライブラリ指定（例：`-llog` 等）は、**原因の特定および問題の解決が完了した段階で、必ずすべて削除し、元のクリーンな状態に復元した上でコミット**してください。

7. **独自のバーチャルキーボード（SoftKeyboard）の非表示漏れとプレビュー残存バグ対策**:
   - 独自のバーチャルキーボード（`SoftKeyboard` / `KeyboardView`）が非表示になる際、拡大キープレビュー（`PopupWindow`）が消えずに画面上に残り、システムキーボード（IME）へのタッチ入力を阻害するバグ。また、初期化されていない状態で `hide()` を呼んだ際に `kbd_frame` の非表示（`GONE`）化がスキップされ、システムキーボードの直上のタッチを阻害するバグ。
   - 対策：
     - `mainwindow.xml` の `kbd_frame` の初期可視性を `gone` にする。
     - `SoftKeyboard.java` のコンストラクタで `mKeyboardFrame.setVisibility(View.GONE)` を呼び出す。
     - `SoftKeyboard.show()` 時に `setPreviewEnabled(true)` でプレビューを有効化。
     - `SoftKeyboard.hide()` 時に `setPreviewEnabled(false)` でプレビューを無効化し、かつ `closing()` を明示的に呼び出してプレビューウィンドウを破棄・クローズした上で、`mKeyboardFrame.setVisibility(View.GONE)` でフレームを非表示にする。

8. **外部モジュール ForkFront-Android のローカルモジュール化と修正の適用**:
   - 背景：以前はビルド時に `sourceControl` で GitHub から直接取得されていたため、ローカルの Java ソースコード修正をビルドに反映できませんでした。
   - 構成：
     - `settings.gradle` で `sourceControl` を削除し、`include(':lib')` と `project(':lib').projectDir = file('ForkFront-Android/lib')` を設定。
     - `app/build.gradle` の `dependencies` に `implementation project(':lib')` を指定。
     - `ForkFront-Android` は `.git` を削除したうえで、NetHackJPの通常のローカルディレクトリとして Git 追跡対象とします。

9. **固有名詞の英語表記の維持方針**:
   - タイルセット名（Geoduck, Nevanda, PixelHack など）のような固有名詞は、日本語化リソース（xmlなど）を作成する際にもカタカナなどに翻訳せず、元の英語表記のまま維持してください。

10. **プレイヤー状態（Condition）表示の日本語化と表示制限の回避**:
    - ステータスライン等で盲目や混乱、石化などの状態表示を日本語化する際は、英語の文字列を個別にハードコードして翻訳するのではなく、ゲームコア側（`src/botl.c`）の `conditions[i].text[1]` の日本語定義を直接参照してください。
    - 表示ループの上限には古いハードコード値（13など）を使用せず、必ず `CONDITION_COUNT` (30) を使用し、すべての状態異常が正しく表示されるようにしてください。
    - ビットマスク処理の安全性のために、状態判定用の変数や関数の引数型は、マスク幅に合わせた `unsigned long` 等を使用してください。

11. **Android 独自設定（Preference）におけるデフォルト値の永続化徹底**:
    - 現象と制約：
      `SliderPreference` などのカスタム Preference を実装する場合、単に XML で `android:defaultValue` を設定しただけでは、インストール直後の初回起動時（`PreferenceManager.setDefaultValues` 実行時）に初期値が SharedPreferences に保存されず、設定値が反映されなくなる（キーが存在しない状態になる）問題が発生します。
    - 対策：
      カスタム Preference クラスを定義・修正する際は、必ず以下の2つのメソッドをオーバーライドしてください。
      1. `onGetDefaultValue(TypedArray a, int index)`: XML からデフォルト値を正しく取得して返す。
      2. `onSetInitialValue(boolean restore, Object defaultValue)`: `restore` が `false`（デフォルト値設定時）の際、引数から受け取った `defaultValue` を設定した上で、 `persistInt` / `persistString` / `persistBoolean` を明示的に呼び出して SharedPreferences に値を保存する。

   **関連**: C コア ↔ Flutter FFI におけるウィンドウ API とタイル描画の設計方針（後述）も合わせて参照してください。`#ifndef ANDROID` ガードの配置や、`flutter_putmixed_with_tile` のような Android 専用 C シンボルを共通ファイルに置く際の二重定義回避パターンを記載しています。


## Flutter移植版におけるCスレッド連携・UI同期設計方針

NetHack Cコア（バックグラウンドスレッド）と Flutter/Dart UI（メインスレッド）間で FFI を用いて画面同期や連携処理を実装する際は、以下の設計方針を遵守してください。

1. **ステータス表示（win_status_update）のジェネリック化**:
   - Android/Javaポートで実装されている JNI 経由での構造化されたステータス更新処理（JNICallOを用いるもの）は、JNI 環境が NULL になる Flutter版では利用できず、そのまま呼ぶと JNI ヌルポインタによる SIGSEGV クラッシュを引き起こします。
   - 対策として、 `HijackWindowProcs()` 内で `and_procs.win_status_update` を NetHack 汎用の `genl_status_update` に差し替えて（ハイジャックして）ください。これにより、ステータス更新時に `putstr` / `putmixed` を介して `WIN_STATUS` (ID: 2) 宛てに自動的にフォーマット済みのテキスト（通常2行）が送信されるようになります。
   - `genl_status_update` を使用する際は、ヘッダーまたはファイル冒頭で `extern void genl_status_update(...)` の前方宣言を行ってください。

2. **ステータス行（WIN_STATUS）のカーソル追跡と上書き処理**:
   - `genl_status_update` はステータス各行を出力する際、 `curs(WIN_STATUS, 1, 0)`（1行目）または `curs(WIN_STATUS, 1, 1)`（2行目）を呼んでから `putstr` を実行します。
   - Dart側の画面バッファ管理クラス（`NetHackScreen` 等）では、 `curs(WIN_STATUS)` が呼び出された際の `y` 座標を状態（インデックス）として保持してください。その後に来る `putString(WIN_STATUS)` では、保持したインデックス行を直接上書き更新するように実装することで、ステータス行の順序反転や表示崩れを完全に防ぐことができます。

3. **Cスレッド終了（セーブ・ゲームオーバー）のUI中継とフリーズ防止**:
   - "S"キーによるセーブ終了や通常のゲーム終了時、C側のスレッド（NetHackMain）がリターンまたは `exit_nhwindows` を経由して終了した事実を UI 側に通知しないと、画面が「セーブ中...」などのゲーム中状態のまま停止してフリーズしてしまいます。
   - 対策として、 FFI に `ExitCallback` (シグネチャ: `Void Function()`) を追加し、 `flutter_exit_nhwindows` および `NetHackThreadFunc` の終了時にこれを呼び出して Dart 側に通知を中継してください。
   - Dart 側では終了イベントを受け取った際、 `_isGameRunning` や各種入力フラグを直ちにリセットし、開始画面に安全かつスムーズに戻るようにステート更新を行ってください。

4. **はみ出し（RenderFlex overflow）の防止と自動縮小フィット**:
   - モバイル端末の多様な画面幅に対応するため、YN質問などのボタン配置は `Row` を避け、自動折り返しが発生する `Wrap` を使用してください。
   - ステータス表示部など、はみ出しが深刻な長文領域については、以下の2つのモードを選択・設定できるように構成してください：
     - **自動縮小フィット（Fit / デフォルト）**: `FittedBox` (`fit: BoxFit.scaleDown`) を用い、固定された高さの中でテキストを画面幅に合わせて自動的に縮小・圧縮する。
     - **領域の可変高さ（Wrap）**: テキストの長さに応じて自動的に折り返し、表示領域の高さ自体を動的に拡張する。

5. **マップタップ時の C コア送信 (PosCmd キュー方式)**:
   - 主人公タイルやマップタイルをタップした時に `#herecmdmenu` などの拡張コマンド**文字列**を 1 文字ずつ送信するのは **禁止**です。Flutter版 `get_ext_cmd` は `flutter_do_ext_cmd_menu`（拡張コマンド一覧を即座にメニュー起動）にハイジャックされており、文字列補完を行う `extcmd_via_menu` とは挙動が異なります。残り文字が `doread`/`doeat`/`doclose` 等の個別コマンドとして連続実行され、UX を破壊します。
   - **正しい実装**: Java版互換の `PosCmd(x, y, mod)` 送信方式を採用してください。
     - C側 `winflutter.c`:
       - `PosCmdEntry` 構造体と `g_poscmd_queue` リングバッファ（`FLUTTER_MAX_POSCMD = 32` 程度）を用意。
       - `SendPosCmdToFlutter(int x, int y, int mod)` 関数を追加し、FFI 経由で Dart 側から呼び出せるようにする。
       - `flutter_nhgetch` 内で PosCmd キューもチェックし、エントリがあれば消費して `g_pending_poscmd_x/y/mod` グローバル変数に座標を退避、戻り値 0（クリックイベント）として返す。
       - `flutter_nh_poskey` 内で PosCmd キューを先にチェックし、なければ `g_pending_poscmd` フラグを確認して復元、戻り値 0 で `x, y, mod` を `readchar_core` に渡す（`readchar_core` は `sym == 0` を `click_to_cmd` 経由でクリック系コマンドとして処理）。
     - Dart側 `main.dart`:
       - `sendPosCmd(int x, int y, int mod)` 関数を追加し、worker 経由で C コアの `SendPosCmdToFlutter` を呼び出す。
       - `_handleMapTap` で `_sendExtendedCommand('#herecmdmenu')` ではなく `sendPosCmd(tile.tileX, tile.tileY, 1 /* CLICK_1 */)` を呼ぶ。
     - 主人公の座標判定は C側 `flutter_cliparound` から Dart側 `setPlayerPos` へ通知される `(u.ux - 1, u.uy)`（0-based マップグリッド座標）を使用し、`dx == 0 && dy == 0` で同一タイルを判定します。
   - `flutter_nh_poskey` から `readchar_core` への座標引き渡し: `nhgetch` 戻り値 0 はクリックイベントとして処理されますが、座標ポインタを返せないため、`g_pending_poscmd_*` グローバル変数経由で `nh_poskey` 側（次の readchar サイクル）に復元します。これにより PosCmd 1 個に対し `readchar` が 2 回呼ばれますが、機能上問題ありません（1 回目は `nhgetch` で PosCmd 消費、2 回目で `nh_poskey` が pending 復元して `click_to_cmd` 実行）。

6. **`request_input` 受信時の自動 `Space(auto)` 送信とメニュー表示中のスキップ**:
   - `request_input` 受信時のセーブ自動アドバンス処理で、一定条件を満たす場合に `WidgetsBinding.instance.addPostFrameCallback` 経由で `_sendFfiKey(32, 'Space(auto)')` を自動送信するロジックがあります（セーブ進行中のテキストを自動で進める用途）。
   - この `Space(auto)` は `_sendFfiKey` 内のメニューガード（`if (_screen.isMenuWindowVisible)`）を通過し、Space/Enter/ESC として `_sendMenuSelection(-1)`（キャンセル）を発動するため、**メニューやテキストウィンドウが表示されている最中に `request_input` が届くと、即座にメニューが閉じてしまう**重大な UX 破壊を引き起こします。
   - **対策**: `addPostFrameCallback` の中で Space を送信する直前に、**メニュー/テキストウィンドウが表示されていないことを再度チェック**してください（`canAutoAdvance` の判定時点と `addPostFrameCallback` 実行時点で状態が変わり得るため、二重チェックが必須）。
     ```dart
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted && _waitingForInput
           && !_screen.isMenuWindowVisible
           && !_screen.isTextWindowVisible
           && _screen.textLines.isEmpty
           && !_isYnVisible
           && !_isGetLineVisible
           && !_isAskNameVisible) {
         _sendFfiKey(32, 'Space(auto)');
       }
     });
     ```

7. **Dart 側デバッグログの出力先**:
   - 既存の `_addLog(String msg)` は Flutter UI 内のログ表示エリア専用で、`adb logcat` や `flutter run` のコンソールには**出力されません**。
   - デバッグ目的で `flutter run` のコンソールや logcat に出力したい場合は **`debugPrint`（`package:flutter/foundation.dart` 標準）** を使用してください。`print` も使用可能ですが、`debugPrint` の方が長い文字列を自動的に分割してくれるため推奨されます。
   - デバッグログは **原因特定後、必ず削除してからコミット** してください（方針 6 参照）。

8. **sys/flutter における sys/android 完全分離と C 補完シンボルの定義原則**:
   - `sys/flutter`（Flutter ポート）は `sys/android` の C コード（`androidmain.c`, `androidunix.c`, `winandroid.c`）へ一切依存せず、独自の `fluttermain.c`, `flutterunix.c`, `winflutter.c` を `CMakeLists.txt` に指定して完全独立・自己完結させてください。
   - NetHack C コア (`src/`) 内部の `#ifdef ANDROID` 領域が参照する Android 固有のグローバル変数・関数（`and_procs`, `and_get_dumplog_dir`, `and_you_die`, `load_usersound`, `androidsound_procs`, `quit_possible`, `lock_mouse_cursor`, `set_username`, `debuglog` 等）は、`sys/android` なしでリンクエラーを出さないよう、`sys/flutter` 側（`winflutter.c` / `fluttermain.c` / `flutterunix.c`）で適切な型・シグネチャを伴う補完シンボルとして定義・実装してください。
   - 特に `debuglog` は `androidconf.h` にて `#define error debuglog` とマクロ展開され C コアから可変長引数関数として参照されるため、単なるマクロではなく `winflutter.c` で `<stdarg.h>` / `<android/log.h>` を用いた実態関数 `void debuglog(const char *fmt, ...)` として定義してください。
   - `and_get_dumplog_dir(char *buf)` 等の補完関数は、`include/extern.h` 等にある宣言の戻り値型・引数型と完全に一致させてください。

9. **Flutter における MaterialColor スウォッチアクセスの安全性（Null クラッシュ防止）**:
   - `Colors.grey[950]` のように、Flutter 標準の `MaterialColor` スウォッチ（50, 100〜900）に定義されていないキーへのアクセスや、その他のスウォッチから取得したカラーに対して `!` 演算子を用いた強制アンラップ（例：`Colors.grey[900]!`）を行うのは禁止です。`null` が返された場合に `Null check operator used on a null value` 例外を引き起こし、画面がクラッシュする原因になります。
   - スウォッチから色を取得して不透明度などを調整する際は、必ず `(Colors.grey[950] ?? const Color(0xFF0D0D0D))` のように `??` を用いて安全なフォールバック用 `Color` を設定した上で、`withValues` や `withOpacity` などのメソッドを呼び出すように徹底してください。

9. **操作ボタンにおけるタップと長押し（onLongPress）の競合防止**:
   - 設定ダイアログの表示など長押しアクション（`onLongPress`）を持つボタンを設計・修正する際は、タップ時の処理に `onTapDown` を使用してはなりません。
   - `onTapDown` は押し下げの瞬間に即座に反応するため、長押し時にも通常タップの処理が先行して走ってしまいます。
   - 必ず `onTap`（または `InkWell` の `onTap`）を使用してください。Flutterの `GestureDetector` は長押しが検知された場合、指を離しても `onTap` は発火しないため、競合を避けることができます。

10. **ドラッグ/ズーム領域（マップ等）における誤タップ防止**:
    - マップのように `InteractiveViewer` 等でドラッグ（パン）やピンチズームを行うキャンバス上のタップ検出には、`onTapUp` を直接使用してはなりません。
    - ドラッグやピンチ操作を終えて指を離した瞬間に `onTapUp` が誤発火して意図しないタップ（キャラクター移動等）が発生するのを防ぐため、以下の設計パターンを採用してください：
      - `onTapDown` でタップされたローカル座標を一時変数（ステート）に保存する.
      - `onTap`（引数なし、ジェスチャー競合でタップとして確定した瞬間に発火）を契機とし、一時保存した座標を取り出してタップ処理を実行する.

11. **Gradle / Kotlin 関連警告に対する gradle.properties 設定の維持**:
    - **現象と制約**:
      Android Gradle Plugin (AGP) 9.0 以降への移行に伴い、`org.jetbrains.kotlin.android` プラグイン非推奨の警告が出力される場合がありますが、これを解消するために `gradle.properties` から `android.newDsl=false` や `android.builtInKotlin=false` を削除してはなりません。
    - **影響**:
      - `android.newDsl=false` を削除すると、Flutter Gradle Plugin 側が DSL 非互換により `ClassCastException` でクラッシュします。
      - `android.builtInKotlin=false` を削除すると、外部依存モジュール（例：`:jni` プラグイン）が古い Kotlin プラグインの適用チェックにより `IllegalStateException` をスローしてビルドが失敗します。
    - **対策**:
      ビルド成功を維持するため、これらの警告は一時的に許容し、両方のフラグを `gradle.properties` に残したまま維持してください。

12. **メッセージ表示・履歴バッファとキー誤爆防止の設計**:
    - **一時バッファと永続履歴バッファの分離**: Cコア側の `clearWindow(WIN_MESSAGE)` はターン毎に呼ばれて表示内容をクリアするため、UIで現在表示するバッファ（`_messages`）のみをクリアし、過去ログを保持するバッファ（`_messageHistory`）はクリアしない設計にしてください。`_messageHistory` はゲーム開始時や再開時の `createWindow(WIN_MESSAGE)` のタイミングでのみリセットします。
    - **履歴対象外メッセージの除外**: `putString` 時、属性（`attr`）の特定フラグ（`attr & 0x8000 != 0`）が立っているものは入力補完などの内部的な出力であるため、`_messageHistory` に追加しないように制御してください。
    - **履歴ダイアログのスクロール初期位置最適化**: 過去のメッセージログを縦スクロールで表示するダイアログは、最新メッセージが最初から表示されるように ListView に `reverse: true` を設定し、インデックスを逆順（`length - 1 - index`）で参照する設計にしてください。
    - **メッセージブロック待機中の入力制限**: Cコアがメッセージ表示ブロック中（`g_in_display_blocking`）は、スペース・ESC・Enter以外のゲーム用ショートカット等のキー入力を破棄して、画面が切り替わる際の意図しない誤爆入力を防止してください。

13. **キー制限（破棄）時における入力可能状態の同期（デッドロック防止）**:
    - **現象と制約**:
      Dart側のキー送信処理は、連続キー入力の衝突を防ぐため、送信の瞬間にガードフラグ `_waitingForInput` を `false` に設定して次の入力要求（`request_input`）を待ちます。
    - **デッドロックの回避**:
      Cコア側で `g_in_display_blocking` 等の制限により受信したキーを破棄（`dropped key`）する場合、Cコアはそのままウェイトループで待ち続けます。この際、Dart側に入力可能状態を戻すよう再通知しなければ、その後にユーザーが押す Space や ESC も Dart 側で送信ガードされて届かなくなり、永久にデッドロックフリーズが発生します。
    - **対策**:
      Cコア側でキーを破棄した際は、必ず `g_dart_notify_input_cb` を経由して `request_input` を Dart 側に再通知し、Dart側の送信ガードフラグ（`_waitingForInput`）を `true` にリセットさせてください。
    - **対象外ウィンドウの制御**:
      マップウィンドウ（`WIN_MAP`）やステータスウィンドウ（`WIN_STATUS`）の表示更新（`blocking`）時には、画面にダイアログが表示されないため、キー制限（`g_in_display_blocking`）を有効にしないでください。ユーザーの任意のキー入力（方向キーなど）で即座にブロッキングを解除できるように制御します。

14. **半透明オーバーレイコントロールにおけるタッチイベントの透過設計**:
    - D-PadやShortcutPadなど、ゲーム画面（マップ等）の上に `Stack` を使って重ね合わせる（半透明オーバーレイする）UIを設計する際は、ボタンがない透明な隙間（中央スペースなど）で奥のマップのピンチズームやドラッグ操作ができるよう、必ずタッチイベントの透過を保証してください。
    - 具体的には、レイアウトの調整（位置決めやパディング）に `Container(color: Colors.transparent)` を使用するのは避けてください（透明色であっても `color` が指定されているとタッチが遮断されます）。代わりに、`Padding` ウィジェットを使用するか、`color` プロパティを指定しない `Container` を用いることで、ヒットテストが子ウィジェット（個別のボタン）がある位置のみに絞られ、無駄な領域でタッチイベントが遮断されるのを完全に防ぐことができます。
    - スケーリング（`Transform.scale` 等）によって描画領域が境界を越えて拡張される場合もこの原則が適用されます。

15. **オーバーレイUIにおけるタップ透過と個別行フィット設計**:
    - メッセージ表示領域やステータス領域など、ゲームマップやメイン画面の上に半透明で重ねて表示するテキストオーバーレイUIを設計・修正する際は、文字が表示されていない余白領域のタップを下層（マップ操作等）に透過させる設計を徹底してください。
    - 具体的には、領域全体を覆うような `GestureDetector` や `Container` の使用を避け、`Column` や `Wrap` などのレイアウトウィジェットを用いて、実際に文字が描画されている各行（または各要素）ごとに個別に `GestureDetector` と半透明背景（`BoxDecoration` 等）を配置してください。
    - これにより、ユーザーが文字のない空白部分に触れた際は、下層のマップ等のタップイベントとして通常通り判定されるようになり、直感的な操作性とマップ視認性を両立できます。

16. **複数 UI 要素の独立 scale 化と衝突回避クランプ**:
    - 画面下端に配置する D-Pad・ShortcutPad・CmdPanel のような「複数の独立 UI 要素に個別の scale 設定を持たせる」場合、各 Widget を画面端点（`Alignment.bottomLeft` / `Alignment.bottomRight`）を起点に拡大する設計が有効です。
    - **基本パターン**:
      ```dart
      Positioned(
        left: 8,                              // 端点からのマージン
        bottom: cmdPanelHeight + 6,           // 縦位置 (CmdPanel の上 6px)
        child: Padding(
          padding: const EdgeInsets.only(top: 6),  // 上方向の余白（元レイアウト互換）
          child: Transform.scale(
            scale: _dpadEffectiveScale,       // 独立 scale
            alignment: Alignment.bottomLeft,  // 端点と一致
            child: NetHackDPad(...),
          ),
        ),
      )
      ```
    - **衝突回避クランプ**: 両端起点のパッド群が中央で衝突する可能性がある場合、`combinedScaledWidth > availableWidth` を判定し、両者を等倍で `equalScale = availableWidth / totalBaseSize` にクランプします。共通関数 `sys/flutter/lib/utils/scale_clamp.dart` の `calculatePadClamp()` を必ず使用してください。
    - **minGap**: 両端からの最小間隔（minGap = 8px 程度 = `Positioned` の `left` / `right`）を確保し、視覚的な窮屈さと誤タップを防ぎます。
    - **クランプ通知**: 設定値と実効値が乖離する場合、設定画面の Slider 下に「⚠ 画面幅により自動調整」を薄いオレンジ色（`Colors.amber[300]`）で表示します。
    - **してはいけないこと**:
      - 全 UI 要素を単一の `Transform.scale` でまとめて拡大する（位置計算が破綻しやすい）
      - スケール拡大時のクランプを行わず、`RenderFlex overflow` 例外を許容する
      - 拡大後の Widget が画面外にはみ出すことを許容する
    - **現状の制限**: Y 軸方向の CmdPanel 拡張時にマップ下端が見切れる可能性があります。完全な縦方向保護は未実装です（将来の改善課題）。

17. **レイアウト refactor 時の数値等価性検証**:
    - `Positioned` / `Padding` / `Transform.scale` の組み合わせでレイアウトを再構築する際は、**予約高さや描画位置の数式が scale=1.0 において旧実装と完全に一致すること**を必ず確認してください。
    - **確認手順**:
      1. 旧レイアウトの予約高さ式と新レイアウトの予約高さ式を、数式レベルで書き下す。
      2. scale=1.0（クランプ未発動時のデフォルト値）を代入し、両式の計算結果が一致することを手計算または単体テストで確認する。
      3. scale=1.5 や 2.0 のような非デフォルト値でも、`max()` や端点起点の `Transform.scale` が視覚的な破綻を起こさないか確認する。
    - **具体例（コントローラ UI の予約高さ再構築）**:
      - 旧: `(padAndShortcutHeight + cmdPanelHeight) * padScale` = `(162.0 + 58) * 1.0` = `220`
      - 新: `cmdPanelHeight * cmdPanelEffective + 12 + max(150 * dpadEffective, 150 * shortcutPadEffective)` = `58 * 1.0 + 12 + max(150 * 1.0, 150 * 1.0)` = `220` ✓
    - **Padding 構造を分解して表現する**: 旧レイアウトで `Padding(EdgeInsets.all(6))` 等を使っていた場合、新レイアウトでは `Padding(EdgeInsets.only(top: 6))` のように最小限の部分に分解し、合わせて予約高さ計算式の `+ 6` 等の定数項も同じ結果になるよう再構築してください。
    - **境界ケースの単体テスト**: 上記の計算式を用いた予約高さや等倍クランプ計算（`calculatePadClamp`）は、Flutter widget test ではなく **純関数の Dart unit test**（`test/utils/` 配下）に切り出し、scale=1.0 の等価性確認 + 境界値（クランプ発動・非発動の閾値）+ 極値（極小画面・極大画面）を網羅してください。

18. **純関数化された共通ヘルパーの境界値テストパターン**:
    - 両端から拡大する複数 UI 要素のクランプ計算のような「**設定値 → 実効値の写像**」は、副作用のない純関数として `lib/utils/` 配下に切り出し、以下を網羅するユニットテストを書いてください。
      1. **クランプなし（標準）**: 一般的な端末幅（例: 360px）+ デフォルト scale（1.0 + 1.0）。
      2. **クランプ発動（典型）**: 一般的な端末幅 + 大きな scale（例: 1.5 + 1.5）で `isClamped == true` を確認。
      3. **クランプなし（非対称）**: D-Pad と ShortcutPad で異なる scale（例: 1.5 + 0.6）でも衝突しない場合。
      4. **クランプなし（タブレット）**: 大きい端末幅（例: 600px, 800px）+ 大きな scale。
      5. **クランプなし（極小）**: 一般的な端末幅 + 小さい scale（例: 0.6 + 0.6）。
      6. **境界値**: `combinedScaledWidth == availableWidth` の閾値ぴったり。
      7. **カスタムパラメータ**: デフォルト以外の `minGap`（例: 16px）等。
      8. **極小画面**: 極小端末幅（例: 300px）+ デフォルト scale でクランプ発動。
    - **書式**: `test/utils/<モジュール名>_test.dart` に `group('calculatePadClamp', ...)` 形式で配置し、テスト名は日本語で「クランプなし: 360px 端末 + ...」「クランプ発動: ...」のように意図が即座に分かる表現にしてください。
    - **浮動小数比較**: `closeTo(期待値, 許容誤差)` を使って浮動小数点演算の誤差を吸収してください（例: `closeTo(1.1733, 0.001)`）。

19. **計画策定段階で前提条件（ファイル構造・既存テスト）を必ず確認する**:
    - 設計やコミット粒度の計画を立てる前に、以下を必ず実コードで確認してください。
      - `ls lib/` や `find . -name "*.dart" -not -path "*/test/*"` で **対象ディレクトリのファイル構造**（フラットか、`lib/screens/`, `lib/widgets/`, `lib/utils/` 等のサブディレクトリがあるか）を把握する。
      - `find . -name "*_test.dart" -not -path "*/.dart_tool/*"` で **既存テストの一覧**を取得し、新規実装が既存テストに与える影響範囲を評価する。
      - `grep -r "<対象シンボル>" lib/` で **影響範囲のシンボル出現箇所**をリストアップし、コミット粒度の判断材料とする。
    - **誤った前提の典型例**:
      - 計画書では `lib/utils/scale_clamp.dart` としていたが、実装時に初めて「`lib/` 直下に全ファイルがフラット配置されている」と判明する。
      - 既存テスト（pre-existing failures）が残存しており、新規実装と無関係な失敗を本変更に起因する失敗と誤認する。
    - **対策**: 計画書の冒頭に「**前提確認**」セクションを設け、確認した内容を記載してください。コミット粒度の決定は、この確認結果を基に行います。

    **関連**: C コア ↔ Flutter FFI におけるウィンドウ API とタイル描画の設計方針（次セクション）も合わせて参照してください。タイル表示や putmixed 拡張など、ウィンドウ API への機能追加パターンを記載しています。


## NetHack C コア ↔ Flutter FFI におけるウィンドウ API とタイル描画の設計方針

NetHack C コア（バックグラウンドスレッド）と Flutter/Dart UI 間で、ウィンドウ API を拡張してタイル表示などの付加情報をやり取りする際の方針です。前述の「Flutter移植版におけるCスレッド連携・UI同期設計方針」の姉妹ドキュメントとして位置付け、ウィンドウ API レベルでの設計判断・実装パターン・典型的なハマりポイントを整理します。

1. **NetHack ウィンドウ API の使い分け（NHW_MENU vs NHW_TEXT）**:
   - **`NHW_MENU` + `add_menu(glyphinfo, ...)`**: タイル ID を `glyphinfo->gm.tileidx` で **直接取得可能**。インベントリ系メニュー（i, d, e, w, #loot 等）の各行にタイルを表示する場合はこちらを使う。
   - **`NHW_TEXT` + `putmixed(win, attr, str)`**: 標準 API にはタイル引数が **存在しない**。テキストに `\GXXXXNNNN` 形式のエンコード済みグリフを埋込み、`genl_putmixed` が showsym 1 文字にデコードする仕組み。
   - → `NHW_TEXT` 経由でタイル表示を追加するには、 `win_putmixed` の **シグネチャ拡張** か **新 API 追加** が必要。
   - → 関連: タイル ID 計算パターン（本セクション内 4.）、グリフエンコード形式（本セクション内 5.）。

2. **FFI 拡張の追加ルール**:
   - 新ウィンドウプロックを追加する場合、既存 FFI typedef に新パラメータを追加すると **FFI breaking change** になります（既存コードがすべて再ビルド必要になる）。
   - → 既存 typedef はそのまま、 **新 typedef を別経路で追加** することで既存 FFI シグネチャを破壊しません。
   - → 例: 既存の `DartAddMenuCallback` を変更せず、新しく `DartPutMixedWithTileCallback` を定義して登録する。
   - → 新 typedef は既存と類似の引数並び（`winId, attr, tile, msg` など）にして、同じ実装パターン（`flutter_save_message` + `g_*_cb` 経由）で書けます。
   - → 関連: 前述の「Flutter移植版におけるCスレッド連携・UI同期設計方針」セクション全体。

3. **Flutter ポート特有のハマりポイント**:
   - **`static` キーワード**: `winflutter.c` 内の関数を `static` 定義すると、他ファイル（例: `src/pager.c`）から **直接呼び出せません**。pager.c 等の他ファイルから直接呼び出される関数は、必ず **`static` を外して外部リンケージ化** してください。
   - **`and_procs.win_putmixed` の型**: upstream `include/winprocs.h` で `void (*)(winid, int, const char *)`（3 引数）のため、4 引数関数は **代入不可**（型不一致エラーになる）。シグネチャ拡張は upstream 変更を伴うため、 **クロスプロジェクトでは避ける**。
   - **`#ifndef ANDROID` ガード**: `src/windows.c` 等の共通ファイルに置いた Android 専用シンボルの非 Android 用デフォルト実装を、Android ビルド時に **コンパイル対象外** にするために必要です。ガードなしだと `flutter_putmixed_with_tile` 等のシンボルが **二重定義** になり、リンクエラーになります。
   - → 関連: 前述の「Windows (MSVC) 開発における C コード記述とビルドの制約」セクション全体（`#ifndef ANDROID` ガードのビルド検証手順など）。

4. **タイル ID 計算パターン**:
   - 各種エンティティから対応する NetHack グリフを生成し、`map_glyphinfo` でタイル ID を取得するパターンです。
   - **怪物**: `mon_to_glyph(mtmp, rn2_on_display_rng)` + `map_glyphinfo`。
   - **物体**: `vobj_at(x, y)` → `obj_to_glyph(otmp, rn2_on_display_rng)` + `map_glyphinfo`。
   - **罠**: `trap_to_glyph(t)` または元の trap シンボル + `map_glyphinfo`。
   - **刻印**: `engraving_to_glyph(e)` または `cmap_to_glyph(S_grave)` + `map_glyphinfo`。
   - **自分自身**: `hero_glyph` + `map_glyphinfo`。
   - **不可視/警告マーカー**: 元の `glyph` をそのまま使用。
   - → 関連: NHW_TEXT 経由の場合、グリフを `\GXXXXNNNN` にエンコードしてから `putmixed` する（本セクション内 5.）。

5. **グリフエンコード形式**:
   - `encglyph(glyph, buf)` は `\G` + 4 桁 hex（ランダムエンコード）+ 4 桁 hex（glyph 値）= `\GXXXXNNNN` を出力します。
   - `genl_putmixed` は `decode_mixed` でこれを showsym 1 文字にデコードします。
   - Flutter 側で `\GXXXXNNNN` をパースするには `RegExp(r'\\G[0-9A-Fa-f]{8}')` で検出する（8 文字分）のが確実です。

6. **putmixed 経由のタイル ID 引き渡し実装ガイド**:
   - インベントリ系メニュー以外のテキスト系ウィンドウ（`/` コマンドの結果リスト等）の各行頭にタイルを表示する場合の手順:
     1. **新 FFI typedef 追加**（本セクション 2. のパターンに従う）: 例 `DartPutMixedWithTileCallback`。
     2. **C 側実装**: `winflutter.c` に新 API 関数（例 `flutter_putmixed_with_tile`）を追加し、`static` を **付けない**。Dart 側 FFI 関数テーブル（`FlutterFfiTable` 等）に新コールバックを登録。
     3. **呼び出し元の修正**（例 `src/pager.c` の `look_all`, `look_traps`, `look_engrs`）: 各エンティティのポインタから `*_to_glyph` + `map_glyphinfo` でタイル ID を計算し、 `putmixed(win, attr, str)` の代わりに新 API（例 `flutter_putmixed_with_tile(win, attr, tile, str)`）を **直接呼び出す**。`and_procs.win_putmixed` の Hijack は **行わない**（本セクション 3. の型不一致問題回避）。
     4. **非 Android 環境向けデフォルト実装**: 共通ファイル（`src/windows.c` 等）に新 API のスタブ実装を `#ifndef ANDROID` ガード付きで配置し、Android ビルドで二重定義にならないようにする（本セクション 3. の二重定義問題回避）。
   - **コミット粒度の参考**: 枠組み確立（FFI 拡張）→ 機能有効化（呼び出し元修正）の **2 段階** に分割すると、ロールバック容易でレビューしやすくなります。
   - **upstream との競合**: NetHackJP-Android 固有のシンボル（例 `flutter_putmixed_with_tile`）を `src/`, `include/` 配下に追加する場合は、NetHackJP の `DEVELOPMENT.md` §4 のポリシーに従い、 `/* NetHackJP: ... */` マーカーで独自実装マーキングしてください。

## Android版におけるセーブデータ一覧（get_saved_games）のフィルタリング方針

1. **バックアップファイル（.bak）の除外**:
   - Android/Flutterポートでは、ゲームロード直後にクラッシュ救済用のバックアップファイルとして `save/[UID][PlayerName].bak` が自動生成されます。
   - `get_saved_games()` (in `src/files.c`) でセーブデータ一覧を走査・スキャンする際は、重複表示や死亡後の無効データ残存を防ぐため、必ずファイル名末尾が `".bak"` であるものをスキップ・除外してください。
   - アップストリーム（本家）の更新をマージする際、このフィルタリングロジックが上書きされて消失（先祖返り）しないよう厳重に注意してください。

## 将来の検討事項
- レイアウト関連: CmdPanel の Y 軸方向クランプ（マップ下端保護）の実装。方針 16 の「現状の制限」を解消する。
- ウィンドウ API 拡張: `flutter_putmixed_with_tile` のような NetHackJP-Android 独自シンボル（`src/`, `include/` 配下に追加）の upstream 還元可否の検討。

## 画面表示モード設計方針（Flutter 版）

Flutter 版には、ゲーム画面のステータスバーの表示を制御する 2 つの画面モードを実装しています。

### 1. 2 つのモード定義

| モード | ステータスバー | ゲーム画面レイアウト | ナビゲーションバー |
|---|---|---|---|
| **通常 (0)** | 表示 | 通常 | 表示 |
| **イマーシブ (1)** | **非表示**（黒帯） | 通常 | 表示 |

- **適用スコープ**: ユーザ設定に従い全画面で適用（タイトル画面・設定ダイアログ・墓石・エンディングも、イマーシブ設定時はイマーシブモードで表示される）
- **デフォルト値**: 0 (通常)
- **3ボタンモード・ジェスチャーモード共通**: `SystemUiOverlay.bottom` を全モードで維持し、操作不能を防止

### 2. 設計上の重要な決定

- **フルスクリーンモード（描画領域をステータスバー領域まで拡張）は採用しない**: Android 12 (Pixel 5) での `setDecorFitsSystemWindows(false)` の互換性问题和、および Android 14+ (Pixel 9a) での `Transform.scale` を介した内部レイアウトずれの解决困難のため。见送り。
- **ジェスチャーモードでも OS ジェスチャー（予測型「戻る」を含む）は OS 側で消費される**: `enableOnBackInvokedCallback="false"` の既存設定と相まって、`WindowInsetsControllerCompat.hide(navigationBars)` を呼ばない方針でジェスチャーと本実装の競合を完全に回避
- **Android 16+ (targetSdk = 36) で `SystemChrome.setEnabledSystemUIMode` はほぼ無視される**: Flutter 内部の旧 `View.setSystemUiVisibility()` が API 36+ で NoOp になるため、**MethodChannel + `WindowInsetsControllerCompat`（AndroidX 経由）** を必ず使用
- **minSdk = 24 を維持**: `WindowInsetsControllerCompat` 内部で API 30+ は新 API、API 24-29 は旧 `setSystemUiVisibility` に自動フォールバック。Kotlin 側で API レベル分岐を書く必要なし

### 3. MethodChannel パターン

- **チャンネル名**: `jp.satokiyo.darthack/screen_mode`
- **メソッド**: `setScreenMode(mode: Int)` — mode は 0/1
- **Kotlin 側実装**: `MainActivity.kt` の `applyScreenMode(mode: Int)` で `WindowCompat.setDecorFitsSystemWindows` + `WindowInsetsControllerCompat.hide(statusBars)` を呼ぶ
- **iOS フォールバック**: Dart 側で `Platform.isAndroid` 判定、`else` 分岐で `SystemChrome.setEnabledSystemUIMode(manual, overlays: [...])` を使用

### 4. 反映タイミング

- **設定画面 pop 後に反映**: `Navigator.push(...).then((_) => _loadPreferences().then((_) { if (_isGameRunning) _applyScreenMode(_screenMode); }))` 経由で適用
- **ゲーム開始時に反映**: `_startGame()` 内で `setState` 直後に `_applyScreenMode(_screenMode)` を呼ぶ
- **アプリ起動時**: `initState` の `_loadPreferences` 完了後に `_applyScreenMode(_screenMode)` を呼ぶ（ユーザ設定に従い、タイトル画面から一貫して適用）

### 5. 設定キー

- **SharedPreferences キー**: `screen_mode`（int, 0/1）
- **デフォルト値**: 0 (normal)
- **保存形式**: int（既存 `status_display_mode`, `tombstone_display_mode` と同じパターン）
- **値検証**: `_loadScreenMode(int?)` で 0/1 以外を `ScreenMode.normal` にフォールバック
- **マイグレーション**: 過去に `screen_mode = 2`（フルスクリーン）が保存されている端末では、ロード時に範囲外として自動的に `normal` にフォールバックされる

### 6. 関連ファイル

- `sys/flutter/lib/main.dart`: enum `ScreenMode`, state, `_loadScreenMode`, `_applyScreenMode`
- `sys/flutter/lib/settings_page.dart`: 新セクション「画面表示モード」追加（タイルセット設定の後、2 番目）
- `sys/flutter/android/app/src/main/kotlin/jp/satokiyo/darthack/MainActivity.kt`: `applyScreenMode(Int)` 実装

