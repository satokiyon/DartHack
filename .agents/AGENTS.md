<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-11-27. -->
# DartHack ビルド・環境設定・開発ツール運用ルール

本ファイルは **ビルド手順、環境設定、Git/Subtree・アセット同期、開発ツール・テスト運用、および音響・設定・課金連携** に関するルールを定めます。
アーキテクチャや設計仕様・実装原則についてはルートの [AGENTS.md](../AGENTS.md) を参照してください。

---

## 1. Git / Git Subtree・リポジトリ分離運用

### `c_core/nethack_jp` および `c_core/nethack_en` の Git Subtree 管理
- `c_core/nethack_jp`（リモート: `nethack-jp` / `https://github.com/satokiyon/NetHackJP.git`）および `c_core/nethack_en`（リモート: `nethack-en` / `https://github.com/NetHack/NetHack.git`）は DartHack 独自拡張を含むため、submodule 化せず **Git Subtree** で管理する。
- **同期方法**:
  - 日本語コア: `powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_jp.ps1`
  - 英語コア: `powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_en.ps1`（手動時は `git subtree pull --prefix=c_core/nethack_en --squash nethack-en NetHack-5.0`）
- **`--squash` 必須化**: 両サブツリーは同一リポジトリ・コミットオブジェクトを共有するため、`--squash` なしで pull すると共通祖先（Merge-Base）が誤認され変更が脱落する。必ず `--squash` を使用する。
- **`extern.h` 整合性チェック**: 同期スクリプト終了後に宣言欠落の警告が出た場合は、`git diff nethack-jp/main:include/extern.h c_core/nethack_jp/include/extern.h` 等で差分を確認し、消去された本家宣言・定義を手動復元する。

### プライベートリポジトリ (`DartHack_private`) とバイナリアセット分離
- 公開リポジトリ `DartHack` には効果音（`.ogg` / `.mp3`）や画像（`.png` / `.webp`）などのバイナリアセット実体を直接コミットしない。
  - `DartHack`: `sys/flutter/assets/` 配下のバイナリは `.gitignore` で除外し、`.gitkeep` のみ追跡する。
  - `DartHack_private`: バイナリアセット実体およびビルド・同期スクリプト（`build_files/sys/flutter/scripts/sync_dat_assets.ps1`, `android_build.ps1`, `windows_build.ps1`）を管理する。
- 音声編集・追加は `DartHack_private/sys/flutter/assets/sounds/` に直接行い、`DartHack` 側へ手動コピーしない（ビルドスクリプトで自動同期される）。
- `sys/flutter/tools/sound_curator/` 等のツールは `DartHack_private` の存在を最優先検知し、不在時は公開リポジトリ側へフォールバックする動的パス解決を維持する。

### Git 履歴書き換え・ロールバックの原則
- **`git filter-repo` / `git filter-branch` 時の退避**: 実行後に履歴除去対象ファイルが作業ツリーからも削除されるため、実行前に必ず管理外の一時ディレクトリ（例: `<appDataDir>\brain\<conversation-id>\scratch\`）へ退避し、完了後に復元する。
- **コミット切り戻し時の部分適用**: ビルドインフラ構成変更と論理コード変更が混在するコミットを一括 `git revert` せず、ビルド設定を維持したまま不要な論理コードのみを手動で切り戻す。

### 公開リポジトリのパス表記・ドキュメント追跡・非配布ツール隔離
- **ローカル PC パス記載禁止**: Git 管理下の全ファイル（`docs/*.md`, `README.md`, `AGENTS.md`, ソースコメント、テスト等）にローカル PC の絶対パスや OS ユーザー名（`C:\Users\...`, `file:///c:/Users/...` 等）を記載してはならない。リポジトリ内のファイル参照には必ず相対パス（例: `../sys/flutter/...`）を使用する（`file:///` スキームはチャット返信および `<appDataDir>\brain\` 内アーティファクト専用）。
- **`docs/` のホワイトリスト管理**: ルート `.gitignore` は `/docs/**` をデフォルト除外しているため、`docs/` に新規ドキュメントを追加して追跡させる際は `!/docs/<filename>.md` を `.gitignore` に明示追加する。
- **開発者専用（非配布）ツールの隔離**: エンドユーザーに配布しない開発・調整用 Flutter ツール（例: `vfx_studio`）は本番パッケージ `sys/flutter/lib/` に入れず、`sys/flutter/tools/<tool_name>/` に隔離配置する（`flutter run -t tools/<tool_name>/main.dart` で起動）。`pubspec.yaml` の `assets:` にも開発専用 JSON 等を同梱せず、開発時ホットリロード処理は `kDebugMode` でガードし、本番 Release ビルドには自動生成した `const` 定数コード等で組み込む。

---

## 2. プラットフォーム別ビルド・コンパイラ制約

### Android / NDK (clang)
- **全角文字リテラル（`char`）禁止**: `'。'` 等のマルチバイト文字をシングルクォートで囲むと `character too large` エラーになるため、必ず文字列リテラル（`"。"`）＋ `%s` を使用する。
- **`FALLTHROUGH` マクロ互換**: `include/tradstdc.h` の clang 向け `FALLTHROUGH` には `; __attribute__((fallthrough))` のように先頭セミコロンを維持する（ラベル直後の構文エラー防止）。上流同期時に巻き戻らないよう注意する。
- **Lua 5.4.8**: `CMakeLists.txt` 等で `-DLUA_USE_POSIX` を必ず指定し、`tmpnam` 非推奨警告を防止する。
- **圧縮セーブ有効化**: `CMakeLists.txt` で `-DZLIB_COMP` を必ず定義する。

### Gradle / AGP 9 / JDK
- `sys/flutter/android/gradle.properties` に以下を維持する：
  - `android.newDsl=false`（Flutter Gradle Plugin 互換性維持、`ClassCastException` 防止）
  - `android.builtInKotlin=true`（`shared_preferences_android` 2.5.x の Built-in Kotlin コンパイルに必須）
  - `org.gradle.java.home` を Android Studio 同梱の安定 JBR（例: `C:/Program Files/Android/Android Studio/jbr`）に固定（最新 JDK での `jlink` 失敗防止）

### Windows / MSVC・CMake
- **文字列比較**: `strcasecmp` / `strncasecmp` は使用禁止（リンクエラー）。必ず `strcmpi` / `strncmpi` を使用する。
- **Debug UCRT `pmode` サニタイズ**: Debug ビルド時の `open.cpp:164` アサーション失敗を防ぐため、`#ifdef FLUTTER_WIN32` ガード下で `flutter_compat.h` の `flutter_win32_open` / `flutter_win32_creat` による `_S_IREAD | _S_IWRITE`（0600）マスクと `unixconf.h` の `FCMASK` 再定義を維持する（`files.c` のハードコード `0666` も `FCMASK` を使用）。
- **POSIX / 外部プロセス機能抑止**: `config.h` の `COMPRESS` および `global.h` の `PANICTRACE_GDB` に `&& !defined(FLUTTER_PORT)` を維持し、`fork()` / `popen()` 等の未定義エラーを防ぐ。`#pragma GCC` は `#if defined(__GNUC__) || defined(__clang__)` で囲む。
- **CMake 絶対パス**: `CMakeLists.txt` から `nethack_core.cmake` を読み込む際は `${NHSROOT}` を使った絶対パス（`include("${NHSROOT}/sys/flutter/cmake/nethack_core.cmake")`）を使用する。

### ビルドスクリプトと自動更新
- **Windows C コア単体確認**: 作業ディレクトリを `c_core\nethack_jp\sys\windows\vs` にして `build_one.bat`（`Release|x64`）を実行する。
- **Flutter Android / Windows ビルド**: `DartHack_private` 内の `android_build.ps1` / `windows_build.ps1` を使用する。
  - C コア変更時は `assets/ver` の自動インクリメントと `flutter_get_build_id()` の二重チェックにより、実機端末のアセット・`.so` 更新を確実に行う。
  - **音源フォーマットの単一化とビルド検証**: Android は `.ogg` のみ（`mp3Count == 0`）、Windows は `.mp3` のみ（`oggCount == 0`）を同梱する。`android_build.ps1` はビルド前に Gradle の `merged_assets` / `assets` キャッシュをクリアし、両スクリプトで成果物内の音源数・不要形式 0 件を検証する。
- **アプリアイコン**: `pubspec.yaml` の `flutter_launcher_icons`（`adaptive_icon_background: "#000000"`, `adaptive_icon_foreground: "assets/icon/darthack_icon_1024x1024.png"`）を維持し、`dart run flutter_launcher_icons` で生成する。

### WSL・データ構築・CRLF 対策
- `sys/flutter` は外部ポートに依存しない完全自己完結構成（`setup.sh`, `Makefile.*`, `fluttermain.c`, `flutterunix.c`, `winflutter.c`）として維持する。
- WSL ビルドで `util/makedefs` が CRLF で失敗しないよう、`util/makedefs.c`（`grep0` / `fgetline`）の `\r` トリミング処理を維持する。

---

## 3. データファイル・アセット同期運用

- **`pubspec.yaml` アセット指定**: `nhlib.lua` / `nhcore.lua` 等のルート直下 Lua スクリプト欠落を防ぐため、必ず `- assets/nethackdir/`（末尾スラッシュ付き）を指定する。
- **日英 Lua / データファイルマッピング**:
  - `c_core/nethack_jp/dat/` 内では Git Subtree 互換のため原本名（`_jp` なし、例: `quest.lua`）のまま日本語コンテンツを保持する。
  - 同期スクリプト（`DartHack_private/build_files/sys/flutter/scripts/sync_dat_assets.ps1`）で `c_core/nethack_jp/dat/<name>.lua` → `sys/flutter/assets/nethackdir/<name>_jp.lua`、`c_core/nethack_en/dat/<name>.lua` → `<name>.lua` へマッピングする。
  - 新規データ・Lua 追加時は `$syncItems` に登録し、MD5 差分検知で同期・`sys/flutter/assets/ver` をインクリメントする。
  - オーディオ同期（`Sync-AudioAssets`）は `-AudioFormat <All | OggOnly | Mp3Only>` で不要形式を削除し、差分時のみ `assets/ver` を更新する。
- **スポイラー原本同期**: `sys/flutter/books/`（`companion.md`, `companion.jp.md` 等）を更新したら、`sys/flutter/assets/nethackdir/` にも同期し `assets/ver` をインクリメントする。
- **音声クレジット同期**: 音声追加・複製時は `sys/flutter/tools/sound_curator/sound_database.json` を `ready` に更新し、`database.py` の `generate_attributions()` で `DartHack_private` と `DartHack` 両方の `attributions.txt` を同期する。
- **`defaults.nh` と両コアの整合性**:
  - `c_core/nethack_en` / `c_core/nethack_jp` 両方の `src/cfgfiles.c` で `defined(ANDROID)` 時に `CONFIG_FILE`（`defaults.nh`）を読む定義を維持する。
  - `defaults.nh` のオプション・ステータスフィールドは両コアの `include/optlist.h`、`include/flag.h`、`src/botl.c`（`status_hilite_menu_fld()`）に定義・同期する。

---

## 4. PowerShell・AIエージェント作業・テスト検証ルール

### PowerShell スクリプトおよびコマンド実行制約
- **コマンド連結**: PowerShell では `&&` が構文エラーになるため、1行ずつ実行するか `;` で区切る。
- **日本語コミットメッセージ**: 文字化け防止のため、一時ファイル（UTF-8）を `<appDataDir>\brain\<conversation-id>\scratch\commit_msg.txt` 等へ書き出して `git commit -F <パス>` で実行し、完了後に一時ファイルを削除する。
- **`*.ps1` 保存形式**: Windows PowerShell 5.1 での誤パース（`Missing closing '}'` 等）を防ぐため、日本語を含む `.ps1` ファイルは必ず **UTF-8 with BOM (`utf-8-sig`) かつ CRLF (`\r\n`)** で保存する。
- **StrictMode 安全性**: `Set-StrictMode -Version Latest` 下では `Get-ChildItem` 0件時に `$null` が返るため `@(Get-ChildItem ...).Count` で配列キャストする。文字列展開で変数直後に `:` 等が続く場合は `${Var}:` のように波括弧で囲む。

### コード編集・クリーンアップ・計画前提確認
- **安全なコード置換**: インデントや改行コード（CRLF）を確認し、編集対象を最小範囲に絞る。置換用の一時スクリプト（Node.js / Python 等）を作成・実行する場合は、必ず事前に内容と目的をユーザーへ説明し許可を得てから実行する。
- **デバッグ用一時コードの削除**: 診断用ログ（`__android_log_print` 等）や一時的なリンク指定（`-llog` 等）は、問題解決後に必ずすべて削除してクリーンな状態に戻す。
- **計画策定前の実コード・テスト確認**: ファイル構造（`lib/` 配下の階層）、既存テスト一覧（`*_test.dart`）、対象シンボルの出現箇所を事前確認してから計画・変更を行う。

### テスト作成・検証ルール
- **純関数の境界値テスト**: UI スケール計算（`calculatePadClamp` 等）のような純関数は `sys/flutter/test/utils/` に切り出し、標準・クランプ発動・非対称・タブレット・境界値・極小画面・`scale=1.0` 等価性をテストする（浮動小数は `closeTo` を使用）。
- **`WidgetTest` の必須作法**:
  - 日本語文言を検証する場合は `MaterialApp(locale: const Locale('ja'), ...)` を明示する。
  - `ExpansionTile` やスクロール領域内の要素をタップする前に `await tester.ensureVisible(finder); await tester.pumpAndSettle();` を実行する。
  - メニューテストのモック `MenuItemData.ident` には `include/objclass.h` 準拠のアイテムクラス番号（`1..18`）とメタ項目 ASCII コード（`'A'`=65 等）を正確に割り当てる。
  - 物理キーボード操作テストでは `tap` 後に `touch` モードが残るのを防ぐため、`await tester.sendKeyEvent(LogicalKeyboardKey.select);` 等で明示的にキーボード入力を発生させて検証する。

---

## 5. 音響（BGM・効果音）・設定・課金連携仕様

- **特別部屋 BGM・環境音**:
  - `sp_lev` のサブルームは `u.urooms` で無視されるため、特別部屋判定は親部屋に設定し、初回クリアされない `orig_rtype` を参照する。
  - 部屋タイプ→環境音ID変換は `sounds.c: room_type_to_ambience(int rtype)` に集約する。`In_V_tower` 等の独立分岐は `In_hell` にネストせず独立 `else if` とする。
  - 特別部屋退出は `check_special_room` の `u.urooms0` / `u.urooms` 差分で検知し、`ambience_end` を発行する（ロード時 `welcome()` でも復元し、BGM 状態はセーブにシリアライズしない）。
- **プレイヤー制御・`audioplayers` 制約**:
  - フロア BGM 用・ルーム BGM 用の 2プレイヤー構成とし、ルーム音源欠落時はフロア BGM を止めない。フェード競合は世代カウンタで破棄制御し、本編開始前のフロア BGM は `_pendingFloorBgm` に保留する。
  - 全プレイヤーで `AndroidAudioFocus.none` を二重適用（global＋個別）し、SE による BGM 停止を防ぐ。iOS `AVAudioSessionCategory.ambient` 時は `options: const {}`（`mixWithOthers` 禁止）。
  - `audioplayers` v6 では `resume()` を完全排除し、`play(AssetSource(...))` で再開する。
  - プレビュー試聴中（`_currentPreviewBgm != null`）のバックグラウンド復帰は本編 BGM を再開せずプレビューのみ再開し、ダイアログ内停止は `stopPreviewBgm(restorePrevious: false)`、本編復帰は `dispose()` 時の `restorePrevious: true` に一元化する。設定再ON/ミュート解除時は `_lastFloorBgm` / `_lastAmbience` を自動復元し、バックグラウンド復帰時は `!_muted && _bgmEnabled` 等を再検証する。
- **効果音・BGM 加工**:
  - 短音効果音に `loudnorm` を単独適用せず、無音除去（`silenceremove`）＋ピーク正規化（`-1.0 〜 -1.5 dBFS`）を行う。音階・不良音源は同セット近隣音から `asetrate`/`aresample` ピッチシフトで補完する。
  - BGM・環境音ループは末尾 3.0秒をイコールパワーカーブで頭へ重ねるシームレス・クロスフェードループとする。
  - トラップ等の新規効果音追加時は日英コアの `seffects.h` / `trap.c`、`sys/flutter/doc/sound_macros_list.md`、`sound_curator`（`sound_definitions.json`, `sound_database.json`, `attributions.txt`）を全同期する。
- **設定 (`AppPrefs` / `SettingsPage`)・リワード広告**:
  - `AppPrefs`（`sys/flutter/lib/utils/app_prefs.dart`、詳細 [datastore_migration_architecture.md](../docs/datastore_migration_architecture.md)）の `proguard-rules.pro` 保護（`shared_preferences_android` / `package:jni` Kotlin コルーチンメンバー）と `__datastore_migration_v1_completed__` システムキー保護（`AppPrefs.isSystemKey`）を維持する。
  - Release AOT（`gen_snapshot.exe`）クラッシュ防止のため、本番 `getInstance()` に `InMemorySharedPreferencesAsync` 等のテスト用フォールバックを混入させない。
  - JSON インポート時は `doubleKeys` に一致する `num` 値を `.toDouble()` で型昇格する。スライダーは `onChanged`（メモリ/音量更新）と `onChangeEnd`（永続化）を分離し、空コレクションでの `reduce` をガードする。
  - `RewardedAdManager.showRewardedAd` は 1回の表示要求につき報酬通知または `onAdClosed(false)` が**合計ちょうど1回**のみ発火する契約（重複要求は無視、ロード監視タイムアウト必須）を厳守する。
