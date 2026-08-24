<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-13. -->
# NetHackJP Android 開発・ビルドに関する追加ルール

NetHackJPをAndroid向けにWSLおよびGradleでビルドする際は、以下の制約とトラブルシューティング知識を遵守してください。

## 1. NDKコンパイルにおける全角文字リテラルの禁止
- **制約**: Android NDK (clang) コンパイラでは、全角文字（例: `'。'`) などのマルチバイト文字をシングルクォーテーションで囲んだ文字定数（`char`）として記述すると `character too large` エラーになります。
- **対策**: 全角の記号や文字を条件付きで出力する場合は、必ず文字列リテラル（例: `"。"`）を使用し、フォーマット指定子を `%c` から `%s` に置き換えてください。

## 2. WSLでのビルド時における改行コード（CRLF）対策
- **現象**: Windows側のリポジトリ（CRLF改行）をそのままWSL (Linux) でビルドする際、データベース構築ユーティリティ `util/makedefs` で行末の `\r` をパースできず `unknown identifier 'MAIL'` や `non-printable '015'` などのエラー・警告が発生します。
- **対策**: `util/makedefs.c` のパース処理（`grep0` および `fgetline` 内）では、改行 `\n` の直前にある `\r` を安全にトリミングする実装（`*tmp == '\r'` の除去）がなされている必要があります。新しくデータファイルやパーサを追加・変更する際は、この `\r` 除去が正しく機能していることを確認してください。

## 3. Gradle Source Control と Android SDK パス (ANDROID_HOME) の伝播
- **現象**: `settings.gradle` 内で Gradle Source Control を用いて外部依存モジュール（例: `ForkFront-Android`）をビルドする場合、メインプロジェクト内の `local.properties` に記述された `sdk.dir` は外部モジュールのビルドコンテキストに引き継がれず、`SDK location not found` エラーが発生します。
- **対策**: Gradleビルド（`gradlew`）を呼び出す際は、必ずビルドプロセス全体の環境変数として `ANDROID_HOME` を直接提供してください。
  - **PowerShellでの実行例**:
    ```powershell
    $env:ANDROID_HOME="C:\Users\satok\AppData\Local\Android\Sdk"; .\gradlew.bat assemble
    ```

## 4. CP437デコーダの無効化とアスキーマップ文字化け対策（日本語文字化け対策）
- **現象**: Android版 NetHack のテキスト出力系は `useCP437Decoder`（`sys/android/app/res/values/config.xml`）が `true` の場合, CP437（単バイト・IBMコードページ）でデコードするため, UTF-8 でエンコードされた日本語テキストがすべて文字化けします。
- **対策**: NetHackJP では `useCP437Decoder` を **必ず `false`** に設定してください。この設定により Java 側のデコーダが UTF-8 モードで動作し, 日本語テキストが正常に表示されます。
- **アスキーマップ의 対応**: `useCP437Decoder = false` にすると Java 側での CP437 デコーダが無効化され, マップ描画の `ttychar`（CP437コード値）がそのまま `(char)` キャストされて罫線文字などが文字化けします。そのため, C側（`sys/android/winandroid.c`）の `and_print_glyph` 関数で, Java 側に文字データを渡す直前に CP437 から Unicode への変換テーブルを適用して渡してください。これにより, Java 側のコードを改変せずにアスキーマップと日本語表示を両立させることができます。
- **注意**: 上流の NetHack-Android リポジトリではこの値が `true` がデフォルトであるため, `android-base` ブランチの同期時にこの設定が巻き戻らないよう注意してください。

## 5. FALLTHROUGH マクロの clang（NDK）互換性
- **現象**: `include/tradstdc.h` の clang 向け `FALLTHROUGH` マクロが `__attribute__((fallthrough))` のみで定義されていると、特定の文脈（ラベル直後など）で C 言語のパーサーが「expected expression」エラーを出します。Android NDK の clang で発生します。
- **対策**: clang 向けの `FALLTHROUGH` マクロ定義には、先頭にセミコロンを付与して `; __attribute__((fallthrough))` とする必要があります。これにより空文（empty statement）が挿入され、ラベル直後でも有効な式として解析されます。
- **注意**: 上流の NetHack 本家リポジトリからの更新で `tradstdc.h` が変更された際に、この修正が維持されていることを確認してください。

## 6. defaults.nh のオプション名エイリアス整合性
- **現象**: `defaults.nh`（`sys/flutter/assets/nethackdir/defaults.nh` 等）で日本語版独自のステータス表示オプション（例: `statuslines`）を使用している場合、`src/botl.c` の `status_hilite_menu_fld()` 内のフィールド名テーブルに対応するエイリアスが未登録だと、起動時に `Unknown status field` 警告が出力されます。
- **対策**: `defaults.nh` に新しいステータスフィールド名やエイリアスを追加する場合は、対応する C コード側（`src/botl.c` 等）のフィールド名テーブルにもエイリアスを登録し、パーサーが認識できるようにしてください。

## 7. Android / Flutter版における日本語・英語版データファイルの配置と優先ロード方針
- **構成とロード方針**:
  AndroidおよびFlutterポートでは、データファイル群（`data`, `rumors`, `oracles` 等）およびヘルプ・メニューなどのデータファイル群を個別のファイルとして `assets/nethackdir/` にパッケージングし、アプリ起動時に端末のストレージ（データディレクトリ）にコピーして読み込みます。
  Windows版と同様に、英語版（`data`, `oracles`, `rumors`, `tribute` 等）と日本語版（`data_jp`, `oracles_jp`, `rumors_jp`, `tribute_jp` 等）の両方のファイルを `assets/nethackdir/` に同梱します。
  Cコア側（`dlb.c` / `files.c`）でデータファイルをロードする際、日本語版（`_jp`）が存在すれば自動的に優先して読み込み、無ければ英語版にフォールバックして読み込みます。
- **データファイルおよび Lua スクリプトの `_jp` ペア分離とバイリンガル原則**:
  `c_core/nethack_jp/dat/` 配下のデータファイルおよび Lua スクリプト（`tut-1.lua`, `air.lua`, `Arc-loca.lua` 等）に日本語メッセージが含まれる場合は、原本ファイル（例: `tut-1.lua`）に直接日本語を埋め込まず、英語版メッセージの原本 `.lua` と、日本語メッセージの `*_jp.lua`（例: `tut-1_jp.lua`）のペア構成に分離してください。
  分離した `*_jp.lua` および原本 `.lua` の双方は、必ず Flutter アセット (`sys/flutter/assets/nethackdir/`) に同期・同梱してください。
- **アセット同期スクリプト (`sync_dat_assets.ps1`) のパスと運用原則**:
  アセット同期スクリプトの実体は `DartHack_private` リポジトリ配下の `build_files/sys/flutter/scripts/sync_dat_assets.ps1` です。
  新しい `_jp` データファイルや Lua スクリプトを追加・改修した際は、必ず本スクリプト内の `$syncItems` 配列に同期定義を追加し、実行して `sys/flutter/assets/ver` をインクリメントさせてください。
  なお、Windows PowerShell 上で本スクリプトを編集する際は、改行コードを CRLF (`\r\n`) に保つことで構文エラーを防いでください。
- **アセットバージョン（ver）のインクリメント**:
  データファイルアセットを変更・追加した際は、上書きインストール時に強制的にアセットコピーがトリガーされるよう、必ず `assets/ver` 内のバージョン値（整数値）をインクリメントしてください。
- **デフォルト設定ファイル名（`defaults.nh`）と `cfgfiles.c` の Android 整合性**:
  Cコアの `src/cfgfiles.c` において、`default_configfile` のマクロ定義分岐に `defined(ANDROID)` が含まれていない場合、Linux/Unixデフォルトの `".nethackrc"` を開こうとして失敗し、パッケージングされた `defaults.nh` が一切読み込まれなくなります（ステータスカラーやメニューカラーが無効化される原因となります）。英語コア (`c_core/nethack_en`) および日本語コア (`c_core/nethack_jp`) の両方の `cfgfiles.c` において、`defined(ANDROID)` 時に `CONFIG_FILE` (または `"defaults.nh"`) が割り当てられる定義を維持してください。
- **`defaults.nh` に記述されるオプション（`dumplog` 等）の二重コア間同期**:
  `defaults.nh` で指定されるオプション（例: `dumplog` 等）が、日本語コア (`nethack_jp`) のみに定義されていて英語コア (`nethack_en`) に定義されていない場合、英語モード起動時に `Unknown option` エラーが発生します。`defaults.nh` で利用するオプションやフラグは、英語コア・日本語コア両方の `include/optlist.h` および `include/flag.h` に正しく定義・同期されていることを徹底してください。

## 8. デバッグ用一時コード・ログ出力のクリーンアップ
- **原則**: デバッグや診断 of 目的で一時的に埋め込んだログ出力処理（例：Cコード内の `__android_log_print` や print文など）や、ログ出力のためだけに一時的に追加したリンクライブラリ指定（例：`-llog` 等）は、**原因の特定および問題の解決が完了した段階で、必ずすべて削除し、元のクリーンな状態に復元した上でコミット**してください。
- **理由**: 本番コードやリリースパッケージ内に不要な処理やリンク依存を残さず、ログの肥大化やパフォーマンスの余計なオーバーヘッドを避けるためです。

## 9. Android版におけるダイアログ（メニュー）のレイアウトと多言語化方針
- **キャンセルボタンの配置と自動フック**:
  - `ForkFront-Android` では、メニューダイアログのレイアウト（`dialog_menu1` や `dialog_menu3` など）に `android:id="@+id/btn_cancel"` のボタンを配置するだけで、Java側（`NHW_Menu.java`）で自動的にキャンセルイベント（戻るキー押下と同等の処理）がフックされます。
  - 新たにキャンセル可能なダイアログを修正または定義する際は、Cコード側のメニュー項目を汚さず、XMLレイアウトに `btn_cancel` を配置することでUI側から直接キャンセルさせる設計を優先してください。
- **ダイアログボタンの多言語化（リソース化）**:
  - ダイアログ上のボタンテキスト（Ok, Cancelなど）をXMLやJavaコードに直接ハードコードせず、`values.xml` および `values-ja/values.xml` で `@string/ok` や `@string/cancel` 等のリソース文字列として定義し、それらを参照させてください。これにより、日本語設定時の適切なローカライズ（「決定」「キャンセル」など）が自動的に適用されます。
  - **注意**: Javaコード側でボタンテキストの文字列を直接比較して動作を分岐させている箇所（例: 以前の `NHW_Menu.java` の `"Clear all"` 判定など）は、ボタン表記を安易にリソース化して変更すると機能が破損します。このような場合は、テキストの文字列比較による分岐を廃止し、Javaコード側に状態保持用のフラグ（例: `mIsClearAllState`）を導入してロジックと表示テキストを分離したうえで、リソースIDからテキスト（例: `R.string.select_all` / `R.string.clear_all`）を設定するように修正してください。
- **日本語長文説明文の表示切れ対策（Spinnerの回避）**:
  - カスタマイズ画面や設定ダイアログにおいて、長文化しやすい日本語の説明文（例：拡張コマンドの動作説明など）を含む項目を選択させる場合、 `Spinner` (ドロップダウン形式) では横幅の制約によりテキストが途中で切れてしまいます。
  - そのため、自動的にテキストが折り返されて全行が表示される `AlertDialog` のリスト選択（`setItems` など）や `ListView` を用いたダイアログ形式のUIを採用してください。
- **拡張コマンド一覧におけるメタコマンドの除外**:
  - ショートカットの割り当て等の目的で C側の `extcmdlist` から拡張コマンド一覧を動的に取得する際、リストの先頭に含まれる `"#"` (拡張コマンドの入力) や `"?"` (一覧ヘルプの表示) は、プレイヤーが直接ショートカットに登録して実行する対象のコマンドではないため、あらかじめフィルタリング（除外）してください。

## 10. コミット切り戻し（ロールバック）における部分適用の原則
- **構成維持の判断**: 過去の不要な変更やバグ調査時の暫定対応コミットを元に戻す（ロールバックする）際、対象コミット内に「外部モジュールのローカルモジュール化」などのビルドインフラ的な構成変更が混在している場合は、コミット全体の単純な `git revert` や一括ロールバックを行ってはなりません。
- **論理コードのみの抽出**: ビルドや他のバグ修正の反映に必須なインフラ構成（`settings.gradle` や `build.gradle` など）は維持したまま、不要となった Java/C コードなどの論理ロジックのみを特定してピンポイントで手動ロールバックしてください。

## 11. Flutter (Dart FFI) コールバックにおける非同期 Use-After-Free の回避と文字列の安全変換
- **現象と制約**:
  Dart 側の `NativeCallable.listener` による FFI コールバックは非同期で処理されるため、Cスレッド側がコールバックを呼び出した直後に文字列メモリを即座に `free` すると、Dart 側が実際にメモリを参照してデコードするタイミングで解放済みメモリを読みに行ってしまい、文字化けやデータ破損、重複表示、最悪の場合クラッシュを引き起こします（典型的な Use After Free バグ）。
- **対策**:
  1. C側から FFI 経由で文字列を渡す場合、即時解放は行わず、スレッドセーフな静的リングバッファを経由させることで、Dart 側が安全にメモリをコピーし終えるまで生存期間を保持させてください。
     - **バッファの面数について**: 能力値表示（`enlightenment`）やヘルプ、ダンプ表示など、一瞬で大量（数千〜数万バイト）の連続出力が発生する箇所ではバッファが高速に周回して上書きされるため、**最低でも 256面以上**（各4096バイト程度）の十分な面数を確保するように徹底してください。
  2. 文字コードの混在（CP437、UTF-8、EUC-JP等）による文字化けを防ぐため、文字列を FFI に渡す前に C 側（`convert_cp437_to_utf8`）で自動的に正しい UTF-8 文字列へリアルタイムに変換して渡す設計を徹底してください。
  3. Dart 側でも、フォーマットの不整合によるクラッシュを防ぐため、`allowMalformed: true` を指定した損失あり UTF-8 デコード（`_utf8DecodeLossy`）を防御層として実装してください。

## 12. Flutter ListTile と ColoredBox のアサーション例外の回避
- **現象**:
  Flutter の `ListTile` はスプラッシュやインク効果を描画するために `Material` の祖先ウィジェットを必要とするため、`ColoredBox` や背景色を持った `Container` などの直下でそのまま使用すると「ListTile background color or ink splashes may be invisible」アサーション例外で落ちます。
- **対策**:
  メニュー選択オーバーレイ等で `ListTile` を使用する場合は、必ず `ListTile` を `Material(color: Colors.transparent)` でラップする設計を徹底してください。

## 13. Flutter InteractiveViewer によるスクロールロック回避とズーム率維持の原則
- **巨大キャンバス化によるスクロールロック無効化**:
  - `InteractiveViewer` は、子がビューポート（画面）よりも小さくなると、境界マージン（`boundaryMargin`）に関わらず自動的にスクロールをクランプ・ロックしてセンタリングする特性があります。
  - これを防ぐため、マップを描画する子の `SizedBox` を十分巨大な固定サイズ（例: 4000x3000）に指定し、描画側（`CustomPainter`等）でそのキャンバスの中央にマップをオフセット配置で描画する「巨大キャンバス設計」を適用してください。これにより、極端なズームアウト時やマップの端・四隅であっても主人公を任意の絶対座標に完全センタリングできます。
- **状態変数によるズーム倍率の維持（リセットバグの防止）**:
  - `_transformationController.value = matrix` を直接代入してカメラのスクロール位置を変更すると、リビルド時等にズーム倍率が `1.0`（等倍）に勝手にリセットされるバグが発生します。
  - 回避策として、現在のスケール（ズーム倍率）を `_transformationController` から直接読み出すのではなく、Widget の状態（プライベート変数 `_currentScale` 等）として保持し、`InteractiveViewer.onInteractionUpdate` からリアルタイムに同期保存してください。カメラ平行移動（移動・追従）の際には、この `_currentScale` を用いて `Matrix4` を直接構築して代入してください。
- **下部コントローラを避けるカメラセンタリングの補正**:
  - スマホ下部にコントローラや仮想キーボードが配置される場合、マップビューポートの物理的な中心（50%）に主人公を表示すると手元に被って見づらくなります。
  - カメラ追従の計算時、目標の垂直座標（Y軸オフセット）を画面中央ではなく、少し上側の **上から 35% の位置 (`viewportHeight * 0.35` 等)** に主人公が描画されるようにオフセットを計算する設計を適用してください。

## 14. Android ライフサイクルとプロセスクリーンアップ（ゾンビクラッシュ防止）
- **現象と制約**:
  Android では Activity が終了（`finish()`）してもプロセスはメモリ上に残るため、Cコアのグローバル変数やバックグラウンドスレッドがゾンビ化して残ります。次回起動時に新旧Cコアスレッドが競合して起動直後に SIGSEGV クラッシュを起こすのを防ぐため、必ず `MainActivity.onDestroy()` 等の完全な破棄時点でプロセス自体をキル (`android.os.Process.killProcess(android.os.Process.myPid())`) する設計を徹底してください。

## 15. ゲーム本編開始までのUI・機能制限（誤セーブ防止）
- **仕様と設計**:
  名前入力、キャラクターメイク、チュートリアル有無選択等の「ゲーム開始前フェーズ」では、セーブデータが存在しないためドロワー（スワイプ含む）や半透明メニューボタンは非表示かつ動作不能に制御してください。
- **本編開始の検知**:
  Cコアからマップウィンドウ（`winType == 3` / `NHW_MAP`）の作成要求を受け取り、そのIDに対する表示・更新要求（`displayWindow`）が最初に届いたタイミングを「ゲーム本編開始」の正確なトリガーとして検知してください。
- **開始前の戻る操作**:
  セーブすべきデータがないため、開始前に戻る操作（Backジェスチャー等）がなされた場合は、確認ダイアログを表示せず即座にアプリを終了（`exit(0)`）させてください。

## 16. 半透明メニューボタン等の下部動的シフト（コントローラ重複防止）
- **レイアウト設計**:
  半透明メニューボタンなどを「左下」「右下」等の画面下部に配置する際は、仮想キーボードやパッド操作盤が表示されているか否かを動的に判定し、コントローラ表示時はその上部（例: `bottom: 270`）、非表示時は画面最下端（例: `bottom: 16`）に bottom オフセットを自動シフトさせ、操作盤との重複を完全に回避してください。

## 17. ゲーム終了時ウィンドウ（墓石・ハイスコア）の表示抑止回避方針
- **現象と制約**:
  Cコア内部のゲーム終了処理 `really_done` (in `src/end.c`) において、ウィンドウ初期化完了フラグ `iflags.window_inited` が `TRUE` でない場合、ウィンドウ環境が無いと見なされて画面出力抑止フラグ `done_stopprint = 1` が強制的に有効化されます。これにより、墓石表示 (`outrip`) やトップテン一覧 (`topten`) の出力がすべてスキップされてしまいます。
- **対策**:
  移植版のウィンドウシステム初期化関数（`init_nhwindows`）の中で確実に `iflags.window_inited = TRUE;` をセットし、終了時（`exit_nhwindows`）に `FALSE` にリセットする設計を徹底してください。

## 18. FFI 経由でのテキスト行アトリビュート（太字等）の同期管理
- **現象と制約**:
  NetHack の C コアは、ハイスコアの一覧表示（トップテン）などで「今回のプレイヤーのスコア」などの強調したい行を出力する際、`putstr` メソッドに `ATR_BOLD` などの属性（attr）を付与して呼び出します。
- **対策**:
  FFI 経由でテキストウィンドウに行情報を渡す際は、単なる文字列のリストだけでなく、その行に紐づく属性値も並行して追跡・管理する仕組み（`_textAttrs` 等）を実装してください。これにより、UI 側で特定の行（太字行など）を検知し、ハイライト表示（カードの枠線や背景色の変更）などのカスタマイズが正確に行えます。

## 19. 切り詰められた日本語文字列（UTF-8）の断片による文字化け防止
- **現象と制約**:
  プレイヤー名などを制限文字数（`NAMSZ` など）に適合させるために C コア側で単純にバイト数で切り詰められた文字列は、末尾に不完全な UTF-8 マルチバイトシーケンス（断片バイト）が残り、画面出力用の CP437→UTF-8 変換等を通る際にゴミ文字として文字化けする原因となります。
- **対策**:
  変換処理（`convert_cp437_to_utf8`）において、「マルチバイト開始バイトの後に、正当な後続バイトが伴わない不完全なシーケンス」を検知した場合は、デコードを行わずに安全にスキップ・除去するロジックを実装し、ゴミ文字の出力を防止してください。

## 20. エディタツールを用いた安全なコード置換と外部スクリプトの利用ルール
- **インデントと改行コードの厳密な一致**:
  - Windows環境（CRLF）やネストの深いコード（Flutter/Dart等）において、`replace_file_content` などの置換ツールを使用する際、スペース数（インデント数）や改行のミスマッチにより置換が正しく適用されない（または曖昧マッチによってコードが破損する）ことがあります。
  - 対策として、置換を適用する際は `view_file` でターゲット箇所のスペース数を正確にカウントし、かつ変更したい最小限の行数に範囲を絞って適用してください。

- **外部スクリプト（Node.js等）を用いた置換の制限と合意形成の義務**:
  - 置換ツールのミスマッチによるバグを避けるために Node.js や Python などの置換スクリプトを一時生成して実行する手法は有効ですが、セキュリティと透明性を維持するため、ユーザーにスクリプトの内容と実行目的を事前に説明し、明示的な許可を得てから実行してください。
  - 事前合意のないまま、裏で作成したスクリプトの実行コマンドを唐突に提案してはなりません。

## 21. sys/flutter における完全自己完結とデータ構築・C補完シンボルの定義原則
- **構成方針**: `sys/flutter`（Flutter ポート）は旧 `sys/android` への依存を持たず、専用の `setup.sh` / `Makefile.*` および C コード（`fluttermain.c`, `flutterunix.c`, `winflutter.c`）を備えた完全独立・自己完結構成として運用してください。
- **データファイル構築・アセット同期**: WSL でのデータファイル生成（`data`, `rumors`, `oracles` 等）は `sys/flutter/setup.sh` からルートへ Makefile 群を配置し、`HACKDIR` 生成物（`sys/flutter/assets/nethackdir`）に書き出します。データファイルの同期やアセットバージョンのインクリメントには、必ず `sys/flutter/scripts/sync_dat_assets.ps1` を使用してください。
- **補完シンボルの要件**: NetHack C コア (`src/`) 内部の `#ifdef ANDROID` 領域が参照する Android 固有のグローバル変数・関数（`and_procs`, `and_get_dumplog_dir`, `and_you_die`, `load_usersound`, `androidsound_procs`, `quit_possible`, `lock_mouse_cursor`, `set_username`, `debuglog` 等）は、`sys/flutter` 側（`winflutter.c` / `fluttermain.c` / `flutterunix.c`）で適切な型・シグネチャを伴う補完シンボルとして定義・実装してください。
- **debuglog 実態関数化**: 特に `debuglog` は `androidconf.h` にて `#define error debuglog` とマクロ展開され C コアから可変長引数関数として参照されるため、単なるマクロではなく `winflutter.c` で `<stdarg.h>` / `<android/log.h>` を用いた実態関数 `void debuglog(const char *fmt, ...)` として定義してください。
- **シグネチャ厳密一致**: `and_get_dumplog_dir(char *buf)` 等の補完関数は、`include/extern.h` 等にある宣言の戻り値型・引数型と完全に一致させてください。

## 22. Flutter 版におけるアプリアイコン設定・構成方針
- **`flutter_launcher_icons` パッケージの利用**:
  `pubspec.yaml` の `dev_dependencies` に `flutter_launcher_icons` を追加し、`dart run flutter_launcher_icons` コマンドで全プラットフォーム（Android, iOS, Windows, Web）用のアセットを生成してください。
- **Android アダプティブアイコン（Adaptive Icons）の背景色指定**:
  デフォルトのまま構成すると Android アダプティブアイコンの背景色が白になり、デザイン意図と異なる表示（白い枠枠や白背景）になる場合があります。`pubspec.yaml` の `flutter_launcher_icons` 設定において、必ず明示的に `adaptive_icon_background: "#000000"` (黒) および `adaptive_icon_foreground: "assets/icon/darthack_icon_1024x1024.png"` を設定してください。

10. **データファイル翻訳における機械翻訳誤訳（指示代名詞の「色」等）の排除と表示幅制約**:
    - **指示代名詞誤訳（「色」など）の解明と修復**: 過去の機械翻訳ツール等により、英語の指示代名詞 `this`, `it`, `he` などが「色」と誤直訳されているケースがあります。翻訳文の再点検時には原文の英語構造を確認し、無関係な「色」を排除して本来の文脈（「これ」「それ」「彼」等）に再構築してください。
    - **表示幅上限（75文字以内）の厳守**: `dat/tribute_jp` などのデータファイルを修正・更新する際は、各行の表示幅（全角2, 半角1）が 75 表示幅を超過しないよう、助詞の整理や文節の分割・調整を徹底してください。

## 23. 共有コード変更時のマーカータグ命名規則 (`DartHack`)
- Upstream (NetHackJP や NetHack 本家) からの変更と区別するため、`src/`, `include/` 等の共有ディレクトリ内のコードを変更・追記する際は、必ず `/* DartHack: ... */` というコメントマーカーを明記してください (`/* NetHackJP: ... */` ではなく `DartHack` を使用)。

## 24. sys/flutter における Flutter 固有 C 関数の共通宣言とスタブ提供原則
- `set_flutter_plain_text_dialog` などの共有コアから参照される Flutter/GUI 関連 C 関数は、`include/extern.h` にプロトタイプ宣言を配置し、`src/windows.c` に非Flutter/非Android環境用の空スタブ（例: `void set_flutter_plain_text_dialog(int enable) { (void) enable; }`）、および `sys/flutter` (`winflutter.c`) 内に Flutter 用の実体を実装してください。
- 共有コア (`src/pager.c`, `src/files.c` 等) から呼び出す際は、`include/extern.h` を経由し、Flutter/GUI ビルド時のみ実行されるよう `#ifdef AND_GUI` ガードを付与して呼び出します。これにより、非GUIビルドでのリンクエラーや不要な局所宣言の散在を防ぎつつ、安全で標準的な NetHack C 関数共有構造を維持できます。

## 25. Lua 5.4.8 コンパイルにおける LUA_USE_POSIX の指定徹底
- **現象**: Android NDK (clang) 等で Lua 5.4.8 をビルドする際、`LUA_USE_POSIX` フラグが未定義だと ISO C の `tmpnam()` にフォールバックし、`tmpnam is deprecated` 警告が出力されます。
- **対策**: `CMakeLists.txt` やビルド定義の `add_definitions` に必ず `-DLUA_USE_POSIX` を指定してください。これにより Lua 内部で安全な `mkstemp()` が使用され、警告が防止されます。

## 26. Flutter版 Cコア・アセットの自動確実更新（二重チェック）設計原則
- **構成と自動同期**:
  `sys/flutter` において C コアソース (`src/`, `include/`) が変更された場合も、`DartHack_private` 内の `android_build.ps1` によるビルド時に自動検知して `assets/ver` をインクリメントし、`build.gradle.kts` がそれを読み取って Android の `versionCode` を動的増分させる構成を維持してください。
- **FFI ビルド ID 判定**:
  C コア側（`winflutter.c`）で `flutter_get_build_id()` を提供し、Dart 側で `assets/ver` と C コアビルド ID の両重チェックを行うことで、実機端末上でのアセット最新展開と `.so` ファイルの確実な置換・反映を達成します。

## 27. Git 履歴抹消 (`git filter-repo` / `git filter-branch`) 実行時のローカルファイル保護原則
- **現象とリスク**:
  `git filter-repo` などの履歴書き換えコマンドは、実行完了後に書き換え後のコミットツリーを作業ツリーへ自動チェックアウト（上書き）するため、履歴から除去されたファイルがローカルのディスク上からも削除されます。
- **対策**:
  履歴抹消を行う際は、実行前に必ず対象のフォルダ・ファイルを Git 管理外の安全な一時ディレクトリ（例：`<appDataDir>\brain\<conversation-id>\scratch\`）へ手動でバックアップ（コピー）し、`git filter-repo` の完了後に元のローカル位置へ復元する手順を徹底してください。

## 28. ダイアログ・全フェーズ用オーバーレイの最前面配置原則（暗転・フリーズ防止）
- **現象と制約**:
  メッセージ、YN質問、1行入力、メニュー、名前入力プロンプト（`flutter_askname`）、テキスト/墓石/トップテン表示などのダイアログ系オーバーレイを、操作パッド領域（`_buildControllerOverlay` 等）の内部に埋め込んで配置してはなりません。
- **影響**:
  `_buildControllerOverlay` は操作パッドの非表示条件（`_shouldShowController`）を満たさない場合に `const SizedBox.shrink()` を返します。
  「冒険を開始する」を押した直後の名前入力フェーズ（`_isMainGameStarted == false`）で `flutter_askname` が発生した際、操作パッド非表示に伴ってダイアログ全体が `SizedBox.shrink()` に隠されて画面に何も描画されず、画面暗転・操作不能のフリーズ状態を引き起こします。
- **対策**:
  すべてのダイアログ・メニュー系オーバーレイは、操作パッドや各種ボタンの表示状態に関わらず、メイン `build()` の `Stack` の最前面（直下）に配置し、ゲームのすべてのフェーズで独立して描画可能にしてください。

## 30. Dart/Flutter メインファイル (`main.dart`) のモジュール分割・構造化設計および非同期コンテキスト安全性原則
- **モジュール分割の構成標準**:
  `main.dart` が肥大化した場合は、以下の標準ディレクトリ構造に沿ってコンポーネントを分割・整理し、1ファイルあたりの規模を抑制してください：
  - `models/`: 列挙型・データモデル・パース関数
  - `widgets/`: 独立表示コンポーネント・ダイアログ関数
  - `widgets/overlays/`: ゲーム応答・ダイアログオーバーレイ
  - `screens/`: タイトル・終了等の画面フェーズ
- **非同期コンテキスト (`BuildContext`) の安全性チェック**:
  非同期処理（`Future` / `SharedPreferences` / FFI 呼び出し等）を跨いで `showDialog` や `context` を参照・操作する際は、必ず事前に `if (!context.mounted) return;` （または `if (!mounted) return;`）を挿入し、アンマウント済みのコンテキスト参照によるクラッシュや型解析警告を徹底して回避してください。

## 31. Cコアコードの非侵襲原則と Flutter UI層におけるメニュー識別子（ident）の安全管理
- **Cコア非侵襲原則**: バグや機能改善の原因が Flutter 移植層（`sys/flutter` 配下の Dart / C 連携部）に存在する場合、本家 NetHack の C コアコード（`src/` 配下）に過剰な修正を施さず、修正は `sys/flutter` 側で完結させてください。
- **メニュー識別子 (`ident`) の型・文脈検証**: NetHack C コアのメニューには、カテゴリ選択（`query_category`：`int` 識別子）とアイテム選択（`query_objlist`：`struct obj *` ポインタアドレス）の2種類が存在します。アイテム選択メニューにおいて `ident = -2`（`ALL_TYPES_SELECTED`）などのメタ識別子が送信されると SEGV クラッシュを引き起こすため、Flutter UI 側（`menu_overlay.dart` / `main.dart`）で全選択時や送信時に `ident > 0` の純粋なアイテム識別子のみを抽出・送信し、メニュー切替時には選択状態を確実にクリアしてください。



## 32. Flutter ポートにおける画像メモリ最適化とタイルセット解像度維持方針
1. **Google Play Console `BitmapFactory` ダウンサンプリング警告対策**:
   - `Image.asset` を用いて単体の大判画像（タイトル背景、ロゴ、墓石画面など）を表示する際は、必ず端末の物理画面幅に応じた `cacheWidth` / `cacheHeight` （例: `cacheWidth: (screenWidth * MediaQuery.of(context).devicePixelRatio).round()`）を指定してください。これにより、Flutter 内部のデコーダ（BitmapFactory）側で表示枠に合ったダウンサンプリングが行われ、メモリ（RAM）過大消費や OOM クラッシュを防止できます。

2. **単体画像の WebP 最適化**:
   - `assets/images/` 配下の単体画像は、最大幅 1920px 程度に事前リサイズし、WebP 形式（Quality 85〜90%）に変換してファイル容量を削減してください。

3. **タイルセット（スプライトシート）画像の解像度維持とロスレス WebP**:
   - タイルセット画像（`assets/tiles/`）は、切り出しロジック（`srcRect`）が固定ピクセルサイズ（32x32 等）に依存しているため、デコード時のダウンサンプリングや解像度のリサイズ（ピクセル数の削減）を行うと座標がズレて表示が崩れます。
   - タイルセット画像については、**ピクセル解像度を完全に維持したまま**、ロスレス（無劣化）WebP 形式へ変換してアセット容量のみを削減してください。

## 33. Flutter AlertDialog におけるソフトキーボード・横画面オーバーフロー防止原則
1. **現象と原因**:
   `AlertDialog` 内に `TextField` や入力チップ群が含まれる場合、ソフトキーボード（IME）の自動立ち上がり（`autofocus: true` 等）や横画面（Landscape）表示によって画面の縦サイズが激減した際、`AlertDialog` のデフォルト枠固定計算（`scrollable: false`）および上下の外枠マージン (`insetPadding`) により `BOTTOM OVERFLOWED BY X PIXELS` エラーが発生します。
2. **標準設計ルール**:
   - **`scrollable: true` の指定**:
     入力項目やリスト要素を持つダイアログでは、原則として `AlertDialog(scrollable: true, ...)` を指定し、ダイアログ全域（タイトル・コンテンツ・下部ボタン）を可視領域内でダイナミックにスクロール可能にします。
   - **`insetPadding` の最適化**:
     横画面時のマージン圧迫を防ぐため、`insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)` を指定して上下余白を約 32px 節約・最適化してください。
   - **ダイアログ内固定高さの回避**:
     `content` 内に高さ制限付きリストを配置する場合は、`SizedBox(height: 350)` などの固定ピクセル指定を避け、`SizedBox(height: MediaQuery.of(context).size.height * 0.45)` などの画面サイズ相対高に設定してください。

## 34. C 移植層 (`winflutter.c` 等) における CRLF 改行コード (`\r\n`) の完全トリミング原則
- **現象と影響**:
  データファイル (`history_jp`, `license` 等) を C 側の `dlb_fgets` で読み込んで Dart 側に FFI 送信する場合、`strchr(buf, '\n')` で `\n` のみ `\0` に置換し末尾の `\r` を残してしまうと、Dart 側で 1 行ごとにゴーストの空行 (`""`) が混入する結果となり、`TextFormatter` などの段落結合ロジックが誤作動を起こします。
- **対策方針**:
  C 移植層のファイル読み込み処理（`flutter_display_file` 等）では、取得した文字列末尾の `\r` および `\n` を以下のように末尾から確実にトリミングして除去する実装を徹底してください：
  ```c
  int len = (int) strlen(buf);
  while (len > 0 && (buf[len - 1] == '\r' || buf[len - 1] == '\n')) {
      buf[--len] = '\0';
  }
  ```

## 35. Cコア ↔ Flutter FFI におけるプレーンテキスト種別フラグ (`isPlain` / `plainType`) の伝達同調
- **現象と影響**:
  C コアで `set_flutter_plain_text_dialog(2)` (クエスト文章等) をセットして FFI コールバック (`isPlain` 整数値) で渡す際、Dart 側の受取部 (`main.dart`) で `message['plainType']` という未存在キーを参照していたため、`plainType` が `0` に落とされてクエストの自動改行整形が動作しませんでした。
- **対策方針**:
  FFI メッセージからダイアログの表示属性を受信・伝達する際は、送信キー名（`isPlain` 整数値）と受信側プロパティ（`plainType`）の同調を保つため、以下のようにフォールバック付きで値を取得して画面管理モデル (`NetHackScreen`) へ伝達してください：
  ```dart
  final plainVal = message['isPlain'] as int? ?? 0;
  final isPlain = plainVal != 0;
  final plainType = (message['plainType'] as int?) ?? plainVal;

## 36. Android / Flutter版におけるセーブデータ・UID管理とアセット・復元処理の原則
1. **`#define getuid() 1` などの固定値マクロの禁止**:
   - `androidconf.h` や `hack.h` 等で `#define getuid() 1` などの固定値ダミーマクロを定義してはなりません。
   - Android OS の本物の Linux プロセス UID (Bionic libc `getuid()`) をそのまま使用してください。マクロで固定化すると、言語モード間（日本語/英語）で `myuid` の不一致 (`uid mismatch`) が発生し、セーブデータが表示されなくなります。

2. **圧縮セーブ (`.gz`) と `restore_saved_game` 直接判定の徹底**:
   - `CMakeLists.txt` には必ず `-DZLIB_COMP` を定義して `nh_compress` / `nh_uncompress` を有効化してください。
   - Cコア起動層 (`fluttermain.c` 等) で `restore_saved_game()` を呼ぶ直前に、非圧縮のセーブファイル名に対して `file_exists(fq_save)` で存在チェックを行わないでください。圧縮セーブ (`.gz`) が存在しても `FALSE` と判定され、セーブデータが存在しないと誤認して新規キャラメイクに進むバグを引き起こします。必ず本家 NetHack の設計通り `restore_saved_game()` の戻り値成否を直接判定してください。

3. **`pubspec.yaml` における `assets/nethackdir/` 直下アセットの指定徹底**:
   - NetHack 5.0 (Cコア) の起動・新規ゲーム開始には `nhlib.lua` や `nhcore.lua` などのルート直下 Lua スクリプト群が必須です。
   - `pubspec.yaml` の `assets:` にサブフォルダ（`common/`, `en/`, `jp/`）だけを指定するとルート直下の Lua ファイルが APK に含まれず `nhl_loadlua` パニッククラッシュを起こします。必ず `- assets/nethackdir/` (末尾スラッシュ付き) を指定してください。

4. **旧セーブデータ (UID=1) の起動時自動マイグレーション維持**:
   - 旧バージョン等で UID=`1`（`1Player.gz`, `1Player.bak`）として保存されたセーブファイルを救済するため、`nethack_assets.dart` で起動時に `_migrateLegacySaveFiles` を呼び出し、現行プロセスの UID へ自動一括リネーム移行させるロジックを維持してください。

5. **Android / Flutter版における日本語・英語版データファイルの配置と優先ロード方針**:
   - AndroidおよびFlutterポートでは、データファイル群（`data`, `rumors`, `oracles`, `quest.lua`, `bogusmon`, `engrave`, `epitaph`, `tut-1.lua` 等）を個別のファイルとして `assets/nethackdir/` にパッケージングし、アプリ起動時に端末のストレージ（データディレクトリ）にコピーして読み込みます。
   - 英語版（`data`, `oracles`, `rumors`, `quest.lua`, `bogusmon` 等）と日本語版（`data_jp`, `oracles_jp`, `rumors_jp`, `quest_jp.lua`, `bogusmon_jp` 等）の両方のファイルを `assets/nethackdir/` に同梱します。
   - **Cコア側における自動優先ロードの実装原則 (`files.c` / `fopen_datafile`)**:
     - DLB (Data Librarian Archive) が未定義の環境では、`include/dlb.h` において `dlb_fopen` が `fopen_datafile(name, mode, DATAPREFIX)` へ展開されます。
     - そのため、データファイルの自動言語切り替え（`g_language_is_jp == 1` 時に `_jp` 付きファイルを優先オープンする処理）は `dlb.c` ではなく、全プラットフォーム共通のディスクオープン関数である **`src/files.c` の `fopen_datafile`** 内に実装してください。これにより、メモリ構造体への副作用を一切生じさせずに `quest_jp.lua` 等を含む全データファイルの自動バイリンガル切り替えが保証されます。
     - **パス・拡張子判定の注意**: `_jp` ファイル名の生成（`make_jp_datafile_name`）時は、`./quest.lua` や `dat/quest.lua` などのパス区切り文字 (`/`, `\`) を考慮し、ファイル名部分末尾の拡張子ドットのみを判別して手前に `_jp` を挿入する設計を徹底してください。
   - データファイルアセットを変更・追加した際は、上書きインストール時に強制的にアセットコピーがトリガーされるよう、必ず `assets/ver` 内のバージョン値（整数値）をインクリメントしてください。




