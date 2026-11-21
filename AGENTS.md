<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-11-20. -->
<!-- agent-ninja-START -->
## Agent Skills

> **IMPORTANT**: Prefer skill-led reasoning over pre-training-led reasoning.
> See [Agent Skills](.github/skills/README.md) before working on tasks covered by these skills.

<!-- agent-ninja-END -->

## 関連ドキュメント（詳細リファレンス）

- 設計・独自拡張一覧: `DEVELOPMENT.md`（特に §4）
- 翻訳ガイドライン: `docs/translation-instructions-ja.md`
- 翻訳作業スキル: `.github/skills/nethackjp-message-translation/SKILL.md`
- X11 XIM 詳細: `XIM-IMPLEMENTATION-PLAN.md`

## 1. 基本原則（日本語専用コア・内部キー分離）

- **多言語分岐の禁止**: `NetHackJP` は日本語版専用リポジトリである（移植先でも英語/日本語は C コア自体を切り替える）。`g_language_is_jp` のような言語判定分岐や英語フォールバックを追加せず、直接自然な日本語処理を記述すること。
- **内部識別キーの英語維持**: ハイスコア（`record`）やセーブ互換性・Lua ID 解決を保つため、`svk.killer.name`、`losehp()`、`multi_reason` 等の内部キーに日本語を直書きしてはならない。本家本来の英語キーを維持し、表示時に動的に翻訳すること。
- **死因と墓石の翻訳集約・二重保護**:
  - すべての死因表示は `src/topten.c` の `jp_translate_killer_text_for_display` に集約し、モンスター名は `name_to_mon()` + `jp_pmname_from_idx()`、アイテム名は `name_to_otyp()` + `jp_item_name()` で動的解決すること。
  - 墓石は生成時（`src/end.c`）に `jp_formatkiller_for_display` で日本語刻印し、読取・遠見時（`src/engrave.c`, `src/pager.c`）にも `jp_headstone_text_for_display` を経由させて二重保護すること。

## 2. 日本語表示・翻訳のコア制約

詳細な文体・用語規則は `docs/translation-instructions-ja.md` および `.github/skills/nethackjp-message-translation/SKILL.md` を参照すること。以下はコード編集時に常時守るべき制約である。

- **動的日本語表示関数の利用**: 英語の内部文字列を直接表示せず、必ず表示用関数を経由させること。
  - 神名: `jp_align_gname_for_display()`, `jp_gname_for_display()`, `jp_u_gname_for_display()`, `jp_a_gname_for_display()`, `jp_a_gname_at_for_display()`
  - 職業・肩書・種族: `jp_role_name_for_display()`, `jp_rank_of_for_display()`, `jp_current_race_noun()`, `jp_race_noun_for_display()`
  - モンスター・アイテム: `jp_pmname()` / `jp_pmname_from_idx()`, `jp_item_name()` / `jp_item_descr()`
- **設定オプション名・設定値キーワードの保護**: `"O"` コマンド等で表示されるオプション名および `.nethackrc`・ガイドブックに対応する設定値キーワード（例: `autopickup`, `hilite_status`, `symset`, `none`, `full`, `brief` 等）は翻訳せず英語のまま保持すること（エラー本文や説明文の周辺テキストのみ日本語化する）。
- **英語ヘルパーの排除**: `an()`, `the()`, `makeplural()`, `s_suffix()`, `plur()`, `uhis()`, `uhim()`, `noit_mhe()` / `noit_mhim()` / `noit_mhis()` を日本語メッセージ内で使わないこと（通貨単位は `currency(amt)` を使用）。
- **マクロ接続とフォーマット整合**:
  - `You()` は先頭に「あなたは」を、`There()` は先頭に「そこに」を自動付与するため、呼び出し側のリテラル先頭に「そこに」「ここに」「には」等を重複させないこと（主語や場所指定を伴わない通知には `pline()` を使う）。`Your()` は自動「あなたの」付与を行わない。`You_hear()` / `You_see()` / `You_feel()` は体言止めを避け、述語まで含めた完全な文にすること。
  - `pline()` 等の可変引数マクロでは、`%` 指定子（特に `%c` と `%s`）の個数・型・順序を実引数と完全一致させること。
  - 日本語化で固定長バッファ（`char buf[N]`）を扱う際は UTF-8（全角 3 バイト/文字）を考慮し、十分なサイズ（64〜128 バイト以上または `BUFSZ`）を確保すること。
- **主要訳語・代名詞マクロの統一**:
  - `Sokoban` →「倉庫番」、`genocide` →「虐殺」に統一すること。
  - `dat/quest.lua` の代名詞マクロは `%nh`（主格）、`%ni`（目的格「〜を」内包）、`%nj`（所有格「〜の」内包）の仕様を守り、`%njを` / `%niを` 等の助詞重複や `%niself` 等の英文マクロ残存を避けること。
- **プレイヤー日本語入力（`getlin()` 系）**:
  - 本家オリジナルの仕様・制約（ブランチ移動制限等）を厳守し、独自ショートカットや過剰な構文解析を追加しないこと。
  - 固有名詞は既存の公式対訳テーブル（`src/mon_jp.c`, `src/obj_jp.c` 等）と完全一致させること。
  - 入力受領直後に `jp_normalize_zenkaku(buf)` で全角スペースを半角化し、`mungspaces(buf)` と連動させること。UTF-8 マルチバイト走査時は後続バイトの終端（`\0`）チェックを徹底すること。
  - アイテム名・モンスター名の日本語表記を変更する際は、`src/obj_jp.c` の `jnh_wish_aliases[]` に旧表記 → 新表記のエイリアスを追加し、願いの後方互換を維持すること。

## 3. C コード・クロスプラットフォーム規約

- **MSVC 互換**: `strcasecmp` / `strncasecmp` は使用禁止。NetHack の `strcmpi` / `strncmpi` を使うこと。
- **Clang / Emscripten / C23 互換**:
  - マルチバイト文字定数（`'。'`, `'あ'` 等）は禁止。文字列リテラル（`"あ"`）と `%s` を使うこと。
  - ヘッダーの `extern` 宣言と `.c` の `staticfn` 定義でリンケージを一致させること。
  - 旧式 K&R の空括弧 `()` 宣言は禁止。`(void)` や `(const char *, ...)` を明記すること。
- **Lua / Submodule 構成**: Lua 5.4 は `nhlua/lua/src/` に内包されている（外部取得不要）。submodule は `submodules/pdcursesmod` のみ。

## 4. UI ポート別制約（TTY / Curses / X11 / Qt / タイル）

- **Curses / TTY**:
  - `sys/unix/hints/` では `WANT_WIN_CURSES=1` を `#-INCLUDE multiw-2.500` より前に記述し、UTF-8 表示のため `HAVE_NCURSESW = 1` を設定すること。
  - `getcchar()` の第 2 引数 `wch` に `NULL` を渡さないこと（PDCursesMod で `color_pair` が未初期化になる）。非 NULL バッファと初期化した `color_pair` を渡すこと。
  - `win/tty/` で生の `putchar()` / `fputs(..., stdout)` を使わず、`g_putch()` / `g_pututf8()` に統一すること（`WIN32CON` での CP437 文字化け防止）。
  - 文字幅計算は `tty_utf8_char_width()`（ロケール非依存の East Asian Width 判定）に一本化し、`wcwidth` / `mbrtowc` を使わないこと。POSIX TTY の `tgetch()` 入力は二重エンコードを避け、UTF-8 1 文字分が揃ってからエコーすること。
- **X11 (XIM)**: `#ifdef HAVE_XIM` で囲むこと。`XOpenIM` 失敗時や `OPTIONS=use_xim:off` 時は ASCII（`XLookupString`）へフォールバックし、`XIMPreeditNothing | XIMStatusNothing` を使うこと。マップ画面・yn プロンプトは ASCII のみ（詳細は `DEVELOPMENT.md §4.15〜4.16` / `XIM-IMPLEMENTATION-PLAN.md`）。
- **Qt6**: `win/Qt/` で新規に `QString::fromLatin1` / `toLatin1` を書かず UTF-8 を使うこと。マップ画面・yn プロンプトは ASCII のみを維持し、日本語化済み静的ラベルおよびコア日本語表示関数を維持すること（詳細は `DEVELOPMENT.md §4.21〜4.24`）。
- **タイル定義（`win/share/*.txt`）**: ヘッダー注釈・コメント行は必ず行頭 `#` で始めること（`#` がないとカラーパレットと誤判定され全タイルがスキップされる）。

## 5. Lua ファイルの構文保護と検証

- **Shebang 保護**: 実行可能 Lua スクリプト（`sys/msdos/fonts/makefont.lua` 等）では 1 行目の `#!` を維持し、更新ヘッダーコメントは 2 行目に配置すること（Lua 5.4 は 1 行目以外の `#` を構文エラーとする）。
- **構文検証**: NetHack コアは Lua 読み込み失敗時に迷路等へ静かにフォールバックするため、`dat/*.lua` 等を編集・マージした際は必ず全 `.lua` のパース検証（エラー 0 件）を行うこと。
  ```bash
  wsl -d Ubuntu-26.04 -- python3 -c "
  import ctypes, os, sys
  lua = ctypes.CDLL('liblua5.4.so')
  lua.luaL_newstate.restype = ctypes.c_void_p
  lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
  L = lua.luaL_newstate()
  errs = [os.path.join(r, f) for r, _, fs in os.walk('.') if '.git' not in r for f in fs if f.endswith('.lua') and lua.luaL_loadfilex(L, os.path.join(r, f).encode(), None) != 0]
  if errs: print('Lua syntax errors:', errs); sys.exit(1)
  print('All lua files valid.')
  "
  ```

## 6. ビルド・動作検証

- **Windows (MSVC)**: `sys\windows\vs\build_one.bat` を実行する（`Release|x64`）。
- **WSL (Linux / Qt6)**: `Ubuntu-26.04` で `sys/unix/build_wsl.sh --qt` を実行する。
- **WSL 実行検証**:
  - インストール済みの `./playground/nethack` を実行すること（未インストールの `./src/nethack` は不可）。
  - Qt6 起動: `QT_IM_MODULE=fcitx QT_QPA_PLATFORM=xcb ./playground/nethack -wQt`（Wayland 対象外）。
  - TTY モードの非対話テストはパイプ直結ではなく PTY（`pty.openpty()` 等）経由で実行すること。

## 7. Git・アップストリーム運用

- **ステージング厳格限定**: `git add .` / `git add -A` / `git commit -a` は禁止。タスク対象ファイルのみ `git add <path>` で個別指定し、作業用一時ファイル・スクリプトはコミット前に削除すること。
- **PowerShell 制約**: コマンド連結に `&&` は使わず `;` または 1 行ずつ実行すること。日本語コミットメッセージは文字化け防止のため UTF-8 一時ファイル経由（`git commit -F <ファイルパス>`）でコミットし、完了後に一時ファイルを削除すること。
- **独自拡張の管理**: 翻訳以外のロジック変更には `/* NetHackJP: ... */` マーカータグを付与し、`DEVELOPMENT.md §4` に記録すること（単純な翻訳追加・更新は不要）。上流（`upstream/NetHack-5.0` 等）に同等修正が入った場合は独自拡張を取り消して追従すること。
- **本家への Pull Request**: `satokiyon/NetHackJP` は独立リポジトリのため、本家（`NetHack/NetHack`）へ PR を送る際は公式 Fork（`satokiyon/NetHack`）経由とし、`upstream/NetHack-5.0` 基点のクリーンブランチにマーカーや日本語記述を含めない純粋な C 差分のみをコミットすること（50/72 ルールと `.github/pull_request_template.md` 準拠）。
