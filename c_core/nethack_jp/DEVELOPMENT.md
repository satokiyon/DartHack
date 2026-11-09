<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-11-09. -->
<!--
  IMPORTANT POLICY FOR NetHackJP-ONLY MODIFICATIONS
  =================================================
  When adding changes to src/ or include/ that are *not* present in
  upstream NetHack (NetHack/NetHack @ NetHack-5.0), follow these rules:

  1. Mark all such custom code regions with a /* NetHackJP: ... */ comment
     in the source file itself, so future readers can quickly identify
     NetHackJP-specific code vs. upstream code.

  2. Add a dedicated subsection below that documents:
     - the marker tag used in the source,
     - which file(s) and roughly which lines contain the custom code,
     - how to "remove" the customization (so we can drop the change
       cleanly if upstream eventually adds an equivalent feature), and
     - how to follow upstream if upstream adds the same or a similar
       change later.

  3. Priority rule: when upstream introduces a change that overlaps with
     a NetHackJP-only customization, the upstream version takes
     precedence — we drop the NetHackJP code and follow upstream.
     Upstream compatibility is the primary goal; NetHackJP-specific
     behavior is secondary.

  This policy is enforced for every commit that touches shared
  upstream files (src/, include/). Local changes that live entirely
  under sys/ (e.g. win/flutter, sys/android) are exempt because they
  are not part of upstream NetHack.
-->
# DartHack 開発ドキュメント (Cコア & NetHackJP 連携)

本ドキュメントは、`DartHack` における C コア（`c_core/nethack_jp` および `c_core/nethack_en`）の開発環境、ビルド、Git Subtree によるマージ運用、アーキテクチャ設計原則、およびリリース手順についてまとめたものです。

---

## 1. リポジトリ構成と C コア管理方針

本リポジトリ (`DartHack`) は、日本語版 NetHack 本家追従リポジトリ `NetHackJP` と、NetHack 本家（英語版）の更新を取り込みつつ、Flutter (Dart) 移植版として開発を進めています。

```mermaid
graph TD
    NetHackJP["NetHackJP (nethack-jp/main)"] -->|Git Subtree (--squash)| SubtreeJP["c_core/nethack_jp (日本語コア)"]
    NetHackEN["NetHack (nethack-en/NetHack-5.0)"] -->|Git Subtree (--squash)| SubtreeEN["c_core/nethack_en (英語コア)"]
    SubtreeJP --> DartHack["DartHack (origin/main)"]
    SubtreeEN --> DartHack
    DartHack --> FlutterUI["Flutter UI (sys/flutter/)"]
```

### Git Subtree による管理原則
`c_core/nethack_jp` および `c_core/nethack_en` は DartHack 独自の拡張や修正（UTF-8化、Android/FFI互換処理、オートセーブフックなど）が含まれるため、git submodule 化を行わず **Git Subtree** 方式で管理します。

1. **基本方針**:
   - ソースコードは親リポジトリ（DartHack）内で直接コミット・維持します。
   - 本家リポジトリの更新を取り込む際は Git Subtree を用いてマージします。
2. **Git Subtree 同期における `--squash` 必須化原則**:
   - `c_core/nethack_jp`（NetHackJP）と `c_core/nethack_en`（NetHack本家）は同一リポジトリ・コミットオブジェクトを共有しています。
   - `--squash` を付けずに `git subtree pull` を実行すると、外部リモートのコミットグラフが DartHack のブランチに直接接続され、Git の 3-way merge において本家の共通コミットが Merge-Base（共通祖先）として誤認識されます。その結果、本家から NetHackJP にマージされた修正が「すでに共有済み（新規変更なし）」と誤認されて `c_core/nethack_jp` への反映から脱落する重大なバグが発生します。
   - したがって、両サブツリーの同期では**必ず `--squash` オプションを指定して同期**してください。

---

## 2. 開発環境とビルド手順

### 開発環境の要件
- **Flutter SDK**: 3.24 以上
- **Android SDK & NDK**: Android Studio 等でセットアップ（NDK r25 以上推奨）
- **CMake**: 3.22 以上
- **Windows C++ ビルド環境**: Visual Studio 2022 (MSVC / C++ ワークロード)

### 日常の開発・ビルド
Flutter 移植版の開発では、`sys/flutter` ディレクトリ配下で Flutter コマンドを実行するだけで、Dart UI と CMake 経由の C 側コア（`c_core`）の両方が自動的にビルドされます。
```powershell
cd sys/flutter
flutter pub get
flutter run
```
※ ビルドキャッシュの不整合や FFI 変更が反映されない場合は、`flutter clean && flutter pub get && flutter run` を実行してください。

### APK / AAB パッケージビルド
```powershell
cd sys/flutter
flutter build apk --release
```
App Bundle (AAB) の署名付きビルドを行う場合は、プライベートリポジトリ `DartHack_private` 内のビルドスクリプトと `sys/flutter/android/key.properties` の署名情報を使用します。

---

## 3. C コア・Flutter 移植層のアーキテクチャ設計原則

### 1. NetHackJP Cコアにおける言語判定分岐の全廃原則
- **Cコア内多言語分岐の禁止**:
  - `NetHackJP`（`c_core/nethack_jp`）は日本語版専用コアです。
  - `DartHack` においても、日本語モード時は `c_core/nethack_jp`、英語モード時は `c_core/nethack_en` と C コアライブラリ自体が別々にビルド・切り替えられます。
  - したがって、NetHackJP の C ソースコード内で `g_language_is_jp` などの言語判定分岐やマクロ、英語フォールバックロジックを追加してはなりません。メッセージ生成やフォーマット処理は、多言語分岐を挟まずに直接自然な日本語処理を記述してください。

### 2. 日本語メッセージ生成における英語文法関数（makeplural / an / the）の排除
- **英語文法関数の適用禁止**:
  - 日本語モンスター名（`jp_pmname`）や日本語名詞（「大岩」「果物名」など）に対して、英語文法用の `makeplural()`, `an()`, `the()`, `s_suffix()` などを呼び出してはなりません。
  - 日本語名詞に対して `makeplural()` を呼び出すと末尾に "s" や "es" が付着して「オークsへの警告」「大岩s」のような壊れた表示になります。
- **動的メッセージにおける名詞の日本語化徹底**:
  - 缶詰を開けたときの匂いや味（`src/eat.c`）、死体投げ・死体殴打（`src/uhitm.c`, `src/mthrowu.c`）、警告メッセージ（`src/timeout.c`）、気配察知（`src/insight.c`）、遠見・墓石（`src/engrave.c`, `src/pager.c`）など、名詞が動的に埋め込まれるメッセージでは、アップストリームの `m_monnam`, `pmname`, `mons` から直接英語名を取得せず、必ず `jp_pmname` / `jp_pmname_from_idx` などの日本語化関数を経由させて取得してください。

### 3. オブジェクト名・死因キーの英語正規化と表示時動的翻訳原則
- **内部ID・キーの英語維持**:
  - アイテム名（`include/objects.h`）だけでなく、死因キー（`"falling rock"`, `"potion of acid"` など）も、C コード内部（`losehp()` や `svk.killer.name`）では upstream 本来の英語キーのまま保持・正規化します。
  - 墓石（`rip.c`）やスコアボード（`topten.c`）の表示時に、`src/obj_jp.c` や `jp_killer_reason_table` 等で動的に日本語へ変換して表示します。
  - 詳細な仕様やマッピングテーブルについては、[`docs/death_reasons_architecture.md`](../../docs/death_reasons_architecture.md) を参照してください。
- **墓石表示の二重保護原則**:
  1. **生成時刻印**: 墓石生成時（`src/end.c`）は `jp_formatkiller_for_display` を直接使用して最初から完全な日本語テキストを刻印する。
  2. **読取・遠見時動的翻訳**: 過去セーブデータや英語 bones からロードされた墓石テキストに対しては、読取時（`src/engrave.c: read_engr_at`）および遠見時（`src/pager.c: add_quoted_engraving`）に `jp_headstone_text_for_display` を経由させて動的に日本語化する。

### 4. スコアボード (TopTen) の C コア・Flutter UI 二重同期原則
- スコアボード表示には以下の 2 系統の表示経路が存在します：
  1. **Cコア表示パス (`c_core/nethack_jp/src/topten.c`)**: ゲームオーバー画面、ダンプログ（`dumplog`）。
  2. **Flutter UI 表示パス (`sys/flutter/lib/models/topten_entry.dart`)**: ディスク上の `record` ファイルをパースしてハイスコアカードUIを描画。
- 死因テキスト、ダンジョン名（`dnum 0` → 運命の大迷宮、`dnum 1` → ゲヘナ等）、エンドゲーム階層名（`dlev -5` → アストラル界等）の翻訳や表示ロジックを修正・追加する際は、**必ず C コア側と Flutter UI 側の両方を同時に修正・同期**させてください。

### 5. フロアBGM・特別部屋BGM判定とサブルーム（子部屋）の仕様原則
- **サブルーム（子部屋）の不可視性**:
  - Lua スクリプト（`sp_lev`）の親部屋内部で入れ子定義された小部屋（例: `oracle.lua` の賢者の祠）は、Cコア内部でサブルーム（`gs.subrooms`）として生成されますが、部屋出入り判定（`in_rooms` や `u.urooms`）はメイン部屋配列しか参照せず、子部屋の `rtype` は無視されます。特別な部屋イベントやBGMを発火させたい場合は、親部屋自身に `rtype` を設定するか、独立した部屋として定義してください。
- **`orig_rtype` の参照義務**:
  - 特別な部屋に入ると初回メッセージ後に `svr.rooms[roomno].rtype = OROOM;` とクリアされるため、BGM判定等ではクリア済みの `rtype` ではなく、必ず `orig_rt = (svr.rooms[roomno].orig_rtype ? svr.rooms[roomno].orig_rtype : svr.rooms[roomno].rtype);` を参照してください。
- **共通関数 `room_type_to_ambience` への集約**:
  - 部屋タイプから環境音IDへの変換は `sounds.c` の `room_type_to_ambience(int rtype)` に集約してください。
- **独立ダンジョン分岐（ヴラドの塔等）における `In_hell` ネスト禁止**:
  - `Vlad's Tower`（`tower_dnum`）は独立ダンジョン分岐であり `In_hell(&u.uz)` は常に `FALSE` となるため、判定を `In_hell` ブロックの内側にネストせず、独立した `else if` 分岐として記述してください。

### 6. 透過タイルセット背景2層描画 (`back_to_glyph`) と暗闇維持原則
- **正確な背景地形算出 (`back_to_glyph(x, y)`)**:
  - 透過 WebP/PNG タイルセットでキャラクターやアイテムの背景に地形を重ねて描画する際は、部屋の床を除外してしまう `get_bkglyph_and_framecolor()` ではなく、必ず `src/display.c: back_to_glyph(x, y)` を使用してください。
- **暗闇維持（ネタバレ防止）**:
  - 未探索マス（`special & MG_UNEXPL`）や、探知された視界外モンスター（`(special & MG_DETECT) && !cansee(x, y) && levl[x][y].seenv == 0`）では背景タイル ID を無効値（`bktile = -1`）として扱い、暗闇を維持してください。詳細は [`docs/transparent_tiles_architecture.md`](../../docs/transparent_tiles_architecture.md) を参照してください。

### 7. タイルセット仕様（横40列）バリデーションと非正方形アスペクト比連動原則
- **横40列バリデーション**:
  - NetHack 標準タイルスプライトシートは解像度に関わらず **1行あたり40枚（`width % 40 == 0`）** を仕様としています。カスタムタイルセットのインポート時にもこの検証を徹底します。
- **アスペクト比連動**:
  - `Geoduck (15x25)` などの非正方形タイルセットでは、セルサイズを正方形で固定せず、`TilesetManager.instance.getMapCellSize` を経由して基準高さ（32.0）にタイルのアスペクト比を乗じた `cellW = baseHeight * (tileWidth / tileHeight)`, `cellH = baseHeight` を動的に適用してください。

### 8. オートセーブ（`do_autosave`）のインメモリ・視界保護および状態記録原則
- **視界マップの全復元**:
  - オートセーブ完了時には必ず `vision_recalc(0);`, `see_monsters();`, `newsym(u.ux, u.uy);` を呼び出し、プレイ継続中の画面と視界を完全に復元させてください。
- **モンスターID (`m_id`) の完全記録**:
  - 乗馬 ID (`u.usteed_mid`)、巻きつき ID (`u.ustuck_mid`)、長柄攻撃対象 ID (`svc.context.polearm.m_id`) は、オートセーブ中であっても確実にセーブファイルに書き出してください。
- **プロセス強制終了（`abort()`）の抑止**:
  - モバイル/FFI環境では C コアが Flutter と同プロセスで動作するため、デバッグ用 `abort()` やコアダンプ出力問合せはマクロガード（`!defined(ANDROID) && !defined(WINFLUTTER)`）でスキップし、安全な終了処理に遷移させてください。
- **`umask` 汚染防止**:
  - C コア初期化時に `umask(0117)` が設定されると Flutter / Dart 側のディレクトリ作成等に権限不整合が生じるため、プロセス全体の `umask` 汚染を防止してください。

### 9. Flutter (Dart FFI) コールバックにおける非同期 Use-After-Free 回避
- **静的リングバッファの維持**:
  - Dart の `NativeCallable.listener` による FFI コールバックは非同期で処理されるため、C 側で即座にメモリを `free` してはなりません。能力値表示や大量テキスト出力に対応できるよう、**最低 256 面以上（各 4096 バイト程度）** のスレッドセーフな静的リングバッファを経由させてください。
- **文字コードの安全変換**:
  - 文字列を FFI に渡す前に C 側（`convert_cp437_to_utf8`）で UTF-8 に変換し、Dart 側でも `allowMalformed: true` を指定してデコードしてください。

---

## 4. C コア独自拡張マーカー一覧

アップストリーム（NetHack 5.0 / NetHackJP）の共有ファイル（`src/`, `include/`）に DartHack 独自の変更を加える場合は、以下のマーカータグを付与して保守性を高めています。

### 1. `flutter_putmixed_with_tile` によるタイル ID 引き渡し
- **マーカータグ**: `/* NetHackJP: putmixed with tile for look result list */`
- **対象ファイル**: `src/pager.c`, `src/windows.c`
- **内容**: `look_all` / `look_traps` / `look_engrs` の結果リスト（`NHW_TEXT`）の各行に対応するエンティティの代表タイル ID を渡し、Flutter UI 側でリスト項目にタイルを添えて表示する。

### 2. 日本語メッセージ内の複数形 "s" (plur) の排除と日本語化
- **マーカータグ**:
  - `/* NetHackJP: Pass currency(amt) instead of plur(amt) to display proper currency unit */`
  - `/* NetHackJP: Remove plur(...) to avoid trailing 's' in Japanese */`
  - `/* NetHackJP: Sprintf hornbuf to "角" instead of "horn(s)" to make it Japanese */`
  - `/* NetHackJP: Distinguish singular/plural for Kop in Japanese */`
  - `/* NetHackJP: expand suffix buffer size to prevent overflow in Japanese */`
- **対象ファイル**: `src/shk.c`, `src/objnam.c`, `src/polyself.c`, `src/region.c`

### 3. Flutter版専用のテキスト表示制御（プレーンテキストフラグ設定）
- **マーカータグ**:
  - `/* DartHack: set plain text dialog flag for flutter lookup result */`
  - `/* DartHack: set plain text dialog flag for flutter tribute reading */`
- **対象ファイル**: `src/pager.c`, `src/files.c`
- **内容**: データベース検索結果（`checkfile()`）や小説（`read_tribute()`）を表示する際、末尾が `:` の行が太字見出しとして装飾されるのを防ぐため、`#ifdef AND_GUI` ガード付きでプレーンテキストダイアログフラグを設定する。

---

## 5. Git Subtree 同期手順とマージ運用

### 1. NetHackJP（日本語コア）の同期
- **リモート確認**: `git remote` に `nethack-jp` (`https://github.com/satokiyon/NetHackJP.git`) が登録されていることを確認。
- **同期実行**:
  専用スクリプト `c_core/sync_nethack_jp.ps1` を実行します。
  ```powershell
  powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_jp.ps1
  ```
  内部で以下のコマンドが `--squash` 付きで実行されます：
  ```bash
  git subtree pull --prefix=c_core/nethack_jp --squash nethack-jp main
  ```

### 2. NetHack 本家（英語コア）の同期
- **同期実行**:
  専用スクリプト `c_core/sync_nethack_en.ps1` を実行します。
  ```powershell
  powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_en.ps1
  ```
  内部で以下のコマンドが `--squash` 付きで実行されます：
  ```bash
  git subtree pull --prefix=c_core/nethack_en --squash nethack-en NetHack-5.0
  ```

### 3. マージ後の整合性検証と手動復元手順
- `sync_nethack_jp.ps1` および `sync_nethack_en.ps1` は、同期完了後に本家の `include/extern.h` に存在する `extern` 関数宣言がローカル側に欠落していないかを自動検証します。
- 警告が出力された場合は、マージ競合解消時に本家側の新関数宣言がドロップされた可能性があるため、`git diff nethack-jp/main:include/extern.h c_core/nethack_jp/include/extern.h` 等で差分を確認し、消去された宣言を手動で復元してください。

### 4. データファイル・アセットの同期手順
- データファイルや Lua スクリプトを変更・同期した際は、`DartHack_private/build_files/sys/flutter/scripts/sync_dat_assets.ps1` を実行して `sys/flutter/assets/nethackdir/` へ同期させ、`assets/ver` をインクリメントしてください。
- ※ スクリプトを編集する際は、PowerShell 5.1 の文字化けを防ぐため **BOM付き UTF-8 (`utf-8-sig`) かつ CRLF** で保存してください。

---

## 6. リリース・タグ手順

1. リリース用キーストア情報を `sys/flutter/android/key.properties` に配置。
2. リリースビルドを実行：
   ```powershell
   cd sys/flutter
   flutter build apk --release
   ```
3. リリース用タグを作成してプッシュ：
   - タグ命名規則: `NetHackJP-Flutter-[Version]-[Date]` (例: `NetHackJP-Flutter-5.0.0-20261109`)
   ```bash
   git tag NetHackJP-Flutter-5.0.0-20261109
   git push origin NetHackJP-Flutter-5.0.0-20261109
   ```
4. GitHub Releases に AAB および APK ファイルを添付して公開。

---

## 7. トラブルシューティングと過去の設計改善知見

### Flutter版ショートカット多文字入力修正 (2026-07-11)
ショートカットボタンに登録された拡張コマンド (`#herecmdmenu` 等) や複数文字マクロ (`100g` 等) を送信した際、最初の 1 文字しか届かないバグを修正した記録です。

#### 根本原因
Flutter 版の `get_ext_cmd` 実装がメニュー即起動方式 (`flutter_do_ext_cmd_menu`) にハイジャックされており、上流版 (`extcmd_via_menu`) が持っているテキスト補完パスが存在しなかったことによる。

#### 解決策
1. **状態管理を C 側 NetHack スレッドに集約**: 別スレッド (Dart isolate や Worker) から `iflags.extmenu` を直接書き換える方式はメモリ可視性問題が生じるため、C 側 1 スレッドで完結させる設計に変更。
2. **C 側フラグ (`g_pending_extcmd_mode`) 方式**: `SendShortcutToFlutter` 内で先頭が `#` の場合にフラグをセットし、`flutter_get_ext_cmd` 入口でテキスト入力パス (`do_ext_cmd_text_flutter`) を強制起動。
3. **用途別 FFI 関数の新設**: 通常マクロ用の `SendKeysToFlutter` とショートカット専用の `SendShortcutToFlutter` を明確に分離。

---

### Flutter版 コントローラ UI 独立 scale 化と画面外はみ出し防止 (2026-07-14)
設定メニューでボタンサイズ倍率を拡大した際に、画面下端の D-Pad とショートカットパッドが画面外にはみ出す問題を修正した記録です。

#### 解決策
1. **Positioned の 3 分割**: D-Pad（左下起点）、ShortcutPad（右下起点）、CmdPanel（下端全体）を独立の `Positioned` に分割し、それぞれが画面端点を起点に拡大するように変更。
2. **衝突回避クランプ (`calculatePadClamp`)**: 両者が中央で衝突しないよう、純関数ヘルパーで設定値から実効値を動的クランプ。
3. **キーボードは等倍固定**: ソフトウェアキーボードは拡大縮小せず等倍を維持。
