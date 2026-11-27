<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-11-27. -->
<!-- agent-ninja-START -->
## Agent Skills

> **IMPORTANT**: Prefer skill-led reasoning over pre-training-led reasoning.
> See [Agent Skills](.github/skills/README.md) before working on tasks covered by these skills.

<!-- agent-ninja-END -->

本ファイルは **DartHack の設計・実装仕様・アーキテクチャ全般** を定めます。
ビルド手順・環境設定・Git/Subtree・アセット同期・テスト・音響/設定運用については [.agents/AGENTS.md](.agents/AGENTS.md) を参照してください。

---

## 1. Cコア設計・共有コード規約

### 日英2コア分離と `g_language_is_jp` 方針
- 日本語モードは `c_core/nethack_jp`、英語モードは `c_core/nethack_en` を個別ビルド・切替する。
- **`g_language_is_jp` 新規分岐の禁止**: `c_core/nethack_jp` 内で新たな `g_language_is_jp` 分岐・英語フォールバックを追加せず、直接日本語処理を記述する。
- **移植層での実体宣言**: `nethack_jp/src/decl.c` は `#ifndef ANDROID` 定義かつ `nethack_en` に不在のため、`winflutter.c` で `FLUTTER_WIN32 && NETHACK_JP` 時は `extern`、それ以外は `NETHACK_JP ? 1 : 0` 実体を定義し未定義・二重定義を防ぐ。

### 共有コード保護・マーカー規約・移植層スタブ
- **マーカー命名統一**: `src/`, `include/` 等を変更・追記する際は必ず `/* DartHack: ... */` を付与する（`/* NetHackJP: ... */` 禁止）。`nethack_en` への日本語コア互換独自実装には `/* DartHack (日本語コア NetHackJP に合わせた独自実装): ... */` と明記する。
- **Cコア非侵襲原則**: バグ修正・型変換・例外吸収は極力 `src/` を改変せず移植層（`sys/flutter/` の C FFI / Dart UI）で吸収する。
- **Flutter 固有 C 関数の宣言とスタブ**: `set_flutter_plain_text_dialog`, `flutter_putmixed_with_tile` 等を共有コアから呼ぶ際は両コアの `include/extern.h` に宣言、`src/windows.c` に空スタブ、`winflutter.c` に実体を置き、`#ifdef AND_GUI` でガードする。
- **Android 補完シンボル**: `#ifdef ANDROID` が参照する `and_procs`, `and_get_dumplog_dir`, `and_you_die`, `load_usersound`, `androidsound_procs`, `quit_possible`, `lock_mouse_cursor`, `set_username`, `debuglog`（`#define error debuglog` のため `void debuglog(const char *fmt, ...)`）等は `extern.h` と厳密一致させる。

### セーブデータ互換性・オートセーブ・UID管理
- **`critical_sizes` と 4段階マイグレーション**: `version.c` の `critical_sizes` 登録構造体やバッファサイズ（例: `PL_FSIZ = 64`、日英両コア同一値必須）を変更する際は、`nh_file` 旧サイズ保持 → `compare_critical_bytes` 検知 → `restore.c` 旧サイズ消費 → 次回セーブ時自動昇格の4段階を実装する（`struct mapseen.custom` 等の Pascal 文字列可変長フィールドは対象外）。
- **オートセーブ (`do_autosave`) の状態保護**: メモリ解放しないため完了時に `vision_recalc(0); see_monsters(); newsym(u.ux, u.uy);` で視界を復元し、`u.uz` / `u.usteed` / `u.ustuck` を破壊しない。`savegamestate()` では `FREEING` / `in_checkpoint` に限定せず `u.usteed_mid` / `u.ustuck_mid` / `svc.context.polearm.m_id` を常に書き出す。
- **UID 管理とセーブ一覧**:
  - `#define getuid() 1` 等の固定値マクロは禁止（OS の実 UID を使用し日英間の `uid mismatch` を防ぐ）。旧 UID=1 救済の `_migrateLegacySaveFiles`（`nethack_assets.dart`）は維持する。
  - `restore_saved_game()` 前に非圧縮パスで `file_exists()` 判定せず（`.gz` セーブ見落とし防止）、`restore_saved_game()` の戻り値で判定する。
  - `get_saved_games()` (`src/files.c`) では `.bak` ファイルを必ず除外する。

### 同一プロセス安全性（`abort()` / `umask`）と NetHack 5.0 仕様追従
- **`abort()` / コアダンプ抑止**: C コアと Flutter が同一プロセスで動作するため、`end.c` 等の `abort()` / `NH_abort()` / コアダンプ問合せは `!defined(ANDROID) && !defined(WINFLUTTER)` で抑止し、安全な終了処理へ遷移させる。
- **`umask` 汚染防止**: POSIX では `umask` がプロセス全スレッドに適用されるため、移植層（`fluttermain.c` 等）で `umask(0777 & ~FCMASK)`（= `0117`、ディレクトリの `x` 権限剥奪により `audioplayers` 等が `errno = 13` でクラッシュ）を絶対に呼ばず、`umask(0022)` を維持する。また非同期I/O等での `catch (_)` 握りつぶしを禁止し `catch (e, st)` でログ出力する。
- **NetHack 5.0 仕様追従**:
  - `#ifdef WIZARD` は廃止済みのため記述禁止。移植層からのウィザード設定は `wizard = TRUE; discover = FALSE;` → `svp.plname` に `"wizard"` → `set_playmode();` の順で行う。
  - コンソール制御は `console.active.*`（または `console.orig.*`）を参照する。
  - `xlogfile` / `logfile` は `wizard` / `discover` 除外後の `if (flg)` 確定時に `record` と 1対1 同期し、`USE_FCNTL` 用に書き込み対象がある場合のみ `ensure_score_logfile_exists()` で作成する（Flutter 起動時 `_syncLogsWithRecord` でも空ファイルを新規作成しない）。
  - `PERSMAX` 等のスコア定数は `#define SYSCF` 有効時は `sys/flutter/config/sysconf` および `winflutter.c` の動的生成値（実効値 `PERSMAX=10` 等）が優先されるため必ず確認する。
  - `xlogfile` の `flags` bit 2 (`0x4`) は「骨ファイル未遭遇 (`!u.uroleplay.numbones`)」であり、オプションの `'bonesless'` と区別する（`xlog_entry.dart`）。`'genocideless'` の日本語表示名は `'虐殺なし'` とする。

---

## 2. 日本語化・翻訳・テキスト処理仕様

### 死因・固有名詞・動的メッセージ
- **死因の英語キー保持と動的翻訳**: `svk.killer.name` 等は英語キーのまま保持し、表示時に `src/topten.c` の `jp_translate_killer_text_for_display()` 等で動的に日本語化する（詳細は [death_reasons_architecture.md](docs/death_reasons_architecture.md)）。
  - 墓石は生成時（`src/end.c`）に `jp_formatkiller_for_display` で日本語刻印し、読取（`engrave.c`）・遠見（`pager.c`）時にも `jp_headstone_text_for_display` で二重保護する。
- **英語文法関数の排除と動的名前解決**: 日本語メッセージ構築で `makeplural()`, `an()`, `the()`, `s_suffix()`, `uhis()`, `uhim()`, `noit_mhe()` 等を使用しない。モンスター・神名・職業・肩書・種族は `jp_pmname`, `jp_pmname_from_idx`, `jp_align_gname_for_display`, `jp_gname_for_display`, `jp_role_name_for_display`, `jp_rank_of_for_display`, `jp_race_noun_for_display` 等を経由する。
- **訳語・表現統一**:
  - `Sokoban` → `倉庫番`、`genocide` → `虐殺`、`polymorph` → `へんげ`。
  - `You()` は先頭に「あなたは」を自動付加するため、客観通知には `pline()` を使う。
  - 行動中断テキスト（`set_occupation`）は「あなたは%sをやめた.」に繋がる体言または「〜するの」形とし、助詞「を」の重複を防ぐ。
  - `GEM_CLASS`（石・宝石）の助数詞は `本` ではなく `個` とする。
  - 状態表示は `src/botl.c` の `conditions[i].text[1]` を参照し、上限 `CONDITION_COUNT` (30) と `unsigned long` を使用する。
  - 可変引数マクロ（`pline` 等）の指定子（特に `%c` と `%s`）と引数の型・順序を厳密一致させる。
- **データファイル翻訳と優先ロード**:
  - 機械翻訳由来の誤訳（指示代名詞の「色」等）を排除し、1行の表示幅上限（全角2・半角1で **75以内**）を守る。
  - `dlb.h` で `dlb_fopen` が `fopen_datafile` に展開されるため、自動言語切替（`_jp` 付きファイル優先オープンと `make_jp_datafile_name` による拡張子前への `_jp` 挿入）は `src/files.c: fopen_datafile` 内に実装する。

### 入力正規化・UTF-8・テキスト整形
- **対話プロンプト正規化**: IME 有効時の全角英数字・記号は C コアの `normalize_fullwidth_to_ascii()` で半角正規化し、「はい」「いいえ」「ヘルプ」「ランダム」等の日本語キーワードを受理する（Dart 側で二重変換しない）。
- **UTF-8 文字境界とゴミ文字防止**:
  - `options.c` (`nmcpy`) や `do_name.c` では日英両コアとも `utf8_truncate()` を適用し、英語モードでも UTF-8 入力・表示が壊れないようにする。
  - `convert_cp437_to_utf8` で不完全な UTF-8 断片バイトを検出した場合は安全にスキップ・除去する。
- **墓石 (`rip.c`) テキストモード整形**: 漢字幅=2・ASCII=1（`utf8_strwidth`）で 16表示幅枠に折り返し（`…` 2幅 / `...` 3幅）、Column 37 の右枠 `|` 位置と中央揃えを維持する。
- **CRLF トリミングとデデント**:
  - `winflutter.c`（`flutter_display_file` 等）では行末の `\r` と `\n` を両方トリミングする。
  - `MenuOverlay` / `TextOverlay` では各行を単純 `.trim()` せず、非カテゴリ・非ディバイダー行から最小共通先頭空白数（`minLeadingSpaces`）を算出して除去（デデント）し、相対インデントを保持する。

---

## 3. Cコア ↔ Flutter FFI・ウィンドウ連携仕様

- **ウィンドウ初期化と終了検知**: `init_nhwindows` で `iflags.window_inited = TRUE;` をセットし（`really_done` での `done_stopprint = 1` による墓石/スコア抑止を防止）、`exit_nhwindows` で `FALSE` に戻す。C スレッド終了時は `ExitCallback` を呼んで Dart 側の `_isGameRunning` 等をリセットする。
- **ステータス更新ハイジャック**: `HijackWindowProcs()` で `and_procs.win_status_update` を `genl_status_update` に差し替え、Dart 側では `curs(WIN_STATUS, x, y)` の `y` 座標を追跡して行を上書き更新する。
- **非同期 FFI コールバックのメモリ安全**: `NativeCallable.listener` の Use-After-Free を防ぐため、C 側文字列は即時 `free` せず **256面以上**（各 4096 バイト程度）の静的リングバッファ＋ `convert_cp437_to_utf8` を経由し、Dart 側でも `allowMalformed: true` の損失ありデコード（`_utf8DecodeLossy`）を行う。
- **`union any` 符号拡張と `ident` フィルタリング**: 64bit 環境で負の 32bit `a_int`（`-2` = `ALL_TYPES_SELECTED` 等）が `4294967294` に化けるのを防ぐため、上位32bitが0かつ下位32bitが負のときのみ `(long)(int)ident->a_int` へ符号拡張し、C 側受信も `strtoll` で復元する。UI 側でも `ident > 0` かつメタ項目（`ident >= 65`）を除外して扱う。
- **`query_category` の純粋カテゴリ連動**: 純粋アイテムカテゴリ（`0 < ident < 65`）とメタ項目（`'A'`=65 等）を分離し、「全種類 (`-2`)」のトグル・双方向連動は純粋カテゴリのみを対象とする。
- **行属性・プレーン種別伝達**: `putstr` の `ATR_BOLD` 等の行属性を並行追跡（`_textAttrs` 等）する。また C→Dart の `isPlain` 整数値と `plainType` の同調をフォールバック付きで維持する。
- **マップタップ (`PosCmd`)・隣接移動・Farlook**:
  - タップ時に `#herecmdmenu` 等の文字列送信は禁止。`SendPosCmdToFlutter(x, y, mod)` → `g_poscmd_queue` → `flutter_nhgetch` / `flutter_nh_poskey` の `PosCmd` キュー方式を使用する。
  - 隣接8マスの移動可能地形では「ここに移動する (`MCMD_MOVE`)」メニューを提供する。
  - Farlook（`do_look()` 等）開始時は冒頭で `docrt()` を呼び、`gg.gbuf` を最新状態に同期させる。
- **自動セーブプレフィックス切除**: `winflutter.c` で `[自動セーブ] ` / `[Autosave] ` を剥がす際は `strlen(prefix)` で動的算出し、`PL_NSIZ_PLUS - 1` タグ検査やクレンジングは `files.c` 側で行って冪等性を保つ。
- **メッセージ履歴とデッドロック防止**:
  - `clearWindow(WIN_MESSAGE)` は表示用 `_messages` のみクリアし、`_messageHistory` は保持（`attr & 0x8000 != 0` は除外、履歴ダイアログは `reverse: true`）。
  - `g_in_display_blocking` 中は Space / ESC / Enter 以外を破棄するが、`WIN_MAP` / `WIN_STATUS` では有効化しない。C 側でキーを破棄した際は必ず `g_dart_notify_input_cb`（`request_input`）を再通知して Dart 側の送信ガード（`_waitingForInput`）のデッドロックを防ぐ。

---

## 4. タイル・画像・マップ描画仕様

- **透過タイルセット2層描画**: 背景地形の算出には `back_to_glyph(x, y)` を使用する（詳細は [transparent_tiles_architecture.md](docs/transparent_tiles_architecture.md)）。未探索マス（`MG_UNEXPL`）および視界外探知モンスター（`(special & MG_DETECT) && !cansee(x, y) && levl[x][y].seenv == 0`）は `bktile = -1` として暗闇を維持する。
- **マップアニメーション・VFX**: 非ブロッキング2層描画・独立フローティングテキスト・持続状態マイクロ演出の仕様は [map_animation_vfx_architecture.md](docs/map_animation_vfx_architecture.md) に準拠する。`MaskFilter.blur` は使用禁止とし、短期アニメ完了時（持続状態のみ表示中を含む）は必ず `Ticker` を完全停止させる（`pumpAndSettle()` 保護）。
- **スプライトシート仕様と非正方形タイル**:
  - 標準スプライトシートは **横40列 (`width % 40 == 0`)**・20〜85行で検証する。
  - `Geoduck (15x25)` 等の非正方形タイルに対応するため、`tileWidth` と `tileHeight` を独立管理し、マップセルサイズは固定 `32.0x32.0` ではなく `TilesetManager` / `FontManager` の `getMapCellSize` でアスペクト比連動させる。
  - カスタムタイルは `getApplicationDocumentsDirectory()/custom_tiles/` に永続化し、削除時は `pixelhack_32x32` へ安全フォールバックする。タイルセット名等の固有名詞は英語表記のまま維持する。
- **画像メモリ最適化**: 単体大判画像（`assets/images/`）は最大幅 1920px・非可逆 WebP 化し `Image.asset` に `cacheWidth` / `cacheHeight` を指定する。タイルセット画像（`assets/tiles/`）はピクセルズレ防止のためダウンサンプリングせず**原寸デコード**＋ロスレス WebP とする。
- **閲覧専用画面のタイル表示とダンプログ保護**: `look_here` や `container_contents` のアイテム行は `flutter_putmixed_with_tile` でタイル描画するが、必ず `if (dumping)`（`iflags.in_dumplog`）を検査し、ダンプログ出力中は通常の `putstr` を使って記載脱落を防ぐ。

---

## 5. Flutter UI / UX・レイアウト・入力制御仕様

### 構造・ライフサイクル・画面モード
- **モジュール分割と `mounted` チェック**: `main.dart` を肥大化させず `models/`, `widgets/`, `widgets/overlays/`, `screens/` に分割する。非同期処理後の `BuildContext` 操作前には必ず `if (!context.mounted) return;` を入れる。
- **本編開始前ガードと Android プロセスキル**: `NHW_MAP`（`winType == 3`）の初回 `displayWindow` を本編開始トリガーとし、開始前はドロワー・メニューボタンを無効化、Back 操作時は確認なしで `exit(0)` する。Android `MainActivity.onDestroy()` ではゾンビプロセスによる次回起動 SIGSEGV 防止のため `Process.killProcess(Process.myPid())` を維持する。
- **画面表示モード**: `MainActivity.kt` の `applyScreenMode(Int)` で通常/全画面（ステータスバー・ナビゲーションバー制御）を切り替える。

### オーバーレイ・Material・ダイアログ・ジェスチャー
- **最前面配置**: 全ダイアログ・プロンプトオーバーレイは操作パッドの内部に置かず、メイン `build()` の `Stack` 最前面に配置する。
- **Material / ListTile / カラー安全性**: `Material` に `shape` と `borderRadius` を同時指定しない。背景・枠線付き `ListTile` は `Material(color: ..., shape: ..., child: ListTile(...))`、透明時は `Material(color: Colors.transparent)` で包む。`Colors.grey[950]` 等のスウォッチアクセスに `!` を使わず `??` でフォールバックする。
- **AlertDialog オーバーフロー防止**: 入力欄やリストを含む `AlertDialog` は `scrollable: true`、`insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8)`、固定高さではなく画面比率高さを指定する。
- **透過・タップ競合防止**:
  - オーバーレイ空白部のタッチ透過のため `Container(color: Colors.transparent)` を避け `Padding` や色なし `Container` を使う。テキスト領域も文字行ごとに個別に `GestureDetector` を配置する。
  - `onLongPress` を持つボタンは `onTapDown` ではなく `onTap` を使う。
  - `InteractiveViewer` 上のタップは `onTapUp` ではなく `onTapDown` で座標保存＋ `onTap` で確定実行する。
- **マップビューポートとカメラ**: `InteractiveViewer` の子は巨大キャンバス（例: `4000x3000`）とし、`_currentScale` を状態保持してズームリセットを防ぎ、下部コントローラ回避のため Y 軸目標を画面上 35% に補正する。`camera_follow_mode: 'fixed'` では X/Y 軸別に実効ビューポート判定と `scroll_margin`/`scroll_amount` 端スクロールを行い、固定モード時のみ `minScale` 下限を拡張する。2D マップ（`InteractiveViewer`）の `Matrix4` 操作では `getMaxScaleOnAxis()` を直接呼ばず（Z 軸 `1.0` により縮小倍率が `1.0` に化けて左上へ大幅ズレするため）、必ず `MapCamera.extractScale()` と 3 軸等方スケールの `MapCamera.buildTransform()` を使用する。
- **独立スケール・干渉防止**: D-Pad / ShortcutPad / CmdPanel は端点起点 `Transform.scale` ＋ `sys/flutter/lib/utils/scale_clamp.dart` の `calculatePadClamp()` で衝突回避クランプする（設定画面で乖離時に警告表示）。半透明ボタンはコントローラ表示状態に応じて `bottom` を動的シフトし、ステータス長文は Fit / Wrap モードおよびリアルタイム計測オフセットで干渉を防ぐ。
- **ExpansionTile・テーマ配色・スライダー**: `ExpansionTile` には `PageStorageKey` を使わず `ValueKey<String>`＋`Column` を使う（`ScrollPosition` の型キャスト灰色クラッシュ防止）。音声クレジットはサービス単位に集約する。UI テーマ `primary`（例: `#CE93D8`）とアクションボタン背景（`0xFF004D40` 等）はコントラスト比 4.5:1 以上を保ち、全決定ボタンで横断統一する。個数選択スライダーは `MenuOverlay.didUpdateWidget` で同期し、持ち物一覧からの後続アクションは `set_itemactions_count` 経由で `cmdq_add_int` へ引き継ぐ。

### スコアボード・入力・コマンドパネル・ガイド
- **TopTen 二重同期・パース**: 死因・ダンジョン名・エンドゲーム階層名は `topten.c` と `sys/flutter/lib/models/topten_entry.dart` の両方を同時更新する。英語ヘッダー判定（`text_overlay.dart`）は単語境界（`\bno\b` 等）必須かつ `TopTenEntry.parse()` 非空時のみ適用する。ミュータブル `List` 参照キャッシュ無効化バグを防ぐため `List.unmodifiable`＋`windowRevision`＋スナップショット比較を用い、`rank <= 0` は `"-"` 表示、`entries.lastIndexWhere((e) => e.isCurrent)` へ初回のみ自動スクロールする。
- **文字列入力ダイアログ**: IME 破壊防止のため自動切り詰めを禁止し、`utf8.encode` バイト数表示＋超過時保存ボタン無効化とする。バッファ上限（末尾 `\0` 除く）は `PL_NSIZ`=32（31B）、`PL_PSIZ`=63（62B）、`PL_FSIZ`=64（63B）。
- **コマンドパネル・アクセラレータ**: `CmdItem.parseCmds` で `\e`, `\n`, `\s`, `\b` の `\` を誤消費しない。直接キーと `#` コマンドの日英ラベルを一致・簡潔に保つ。アクセラレータ自動採番（`a..z, A..Z`）は `selectMenu` 時の `how > 0` かつ非拡張コマンドに限定し、`#enhance` の 3状態（`can_advance`, `"  * "`, `"  # "`）を保持する。
- **スポイラーガイド (`companion.md`)**: パラグラフ単位改行（ハードラップ禁止）、コードブロック・テーブル行保護、生 HTML/JS/ツールバー残骸除去と `validate_markdown()` 検証、テーブル内 `<br>` の `\n` 変換を行う。

---

## 6. 物理キーボード・フォーカス管理仕様

- **最優先ルーティングと修飾キー**: `HardwareKeyRouter` ではテキスト入力中を除き、全画面共通キー（`F1` / `Alt-h` / `Esc` 等）を個別コンテキスト分岐より前に配置する。修飾キー判定には `HardwareKeyboard.instance` を使用する（`KeyEvent` に `isAltPressed` は無い）。ルートは `Focus(onKeyEvent: _onHardwareKey)` で消費キーに `KeyEventResult.handled` を返す。
- **NetHack 操作仕様準拠**:
  - メタキー（`0x80 | charCode`）は `logicalKey` から解決し、Alt 単体は `SwallowKey`、`Alt+F4`/`Alt+Tab` 等は `IgnoreKey` とする。
  - `yn_function()` は `choices` 有効文字以外を `SwallowKey` し、`choices` 側のケースへ正規化して返す。
  - メニュー表示中のプレフィクスキーは `MenuItems` をスキャンして `PICK_ONE` 即決 / `PICK_ANY` トグル、Space は下スクロール、Enter で確定とする。`KeyRepeatEvent` はスクロール操作のみ許可。
  - `TextOverlay` は `--More--` 準拠（Space でページ送り・最下部で閉じる、Enter/ESC で即閉じる）。
  - `#` 拡張コマンド検索では「完全一致」または「候補1件」のときのみ Enter 即実行する。
- **フォーカス隔離・復帰**: 画面外ウィジェット（ドロワー等）は `autofocus: false` ＋非展開時 `ExcludeFocus`。モーダル表示中は背景を `ExcludeFocus` で覆う（`Stack` 内の `Positioned` は外側ではなく `child` 直下に適用）。ダイアログ内部の不要な `FocusScope` を排しフラットな仮想フォーカスとし、`TextField` 遷移時のみ本物フォーカス＋Tab捕捉 `unfocus()` を行う。`showDialog` 閉鎖後は `.then((_) => _ensureGameFocus())` で復帰させる（ゲーム開始前ガードは設けない）。
- **実機 IME 対策・モード分離・ヘルプ**:
  - Android 実機での IME 経由対策として `FocusManager.instance.addEarlyKeyEventHandler` で物理キー押下を検知し、`GestureBinding.instance.pointerRouter.addGlobalRoute` で `Overlay` 含む全画面タップ時にタッチモードへ即復帰させる。
  - `ExpansionTile` は 3段階ハイライト＋内部無名ヘッダーをスキップするフォーカス補正を行う。
  - ヘルプ `Table` は代表キーのみ厳選記載し、列0 に `MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(maxWidth * 0.45))` を適用する。数量指定（`0〜9`）の案内は `menuHow >= 1` のみ表示する。
