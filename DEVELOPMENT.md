<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-23. -->
<!--
  IMPORTANT POLICY FOR NetHackJP-ONLY MODIFICATIONS
  =================================================
  When adding changes to src/ or include/ that are *not* present in
  upstream NetHack (NetHack/NetHack @ NetHack-5.0), follow these rules:

  1. Mark all such custom code regions with a /* NetHackJP: ... */ comment
     in the source file itself, so future readers can quickly identify
     NetHackJP-specific code vs. upstream code.

  2. Add a dedicated subsection below (§4.x) that documents:
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
  upstream files (src/, include/).  Local changes that live entirely
  under sys/ (e.g. win/flutter, sys/android) are exempt because they
  are not part of upstream NetHack.
-->
# NetHackJP 開発メモ

本ドキュメントは、Windows ポート（CUI/GUI）の日本語化リポジトリである `NetHackJP` の開発環境の構築、ビルド、マージ運用およびリリース手順についてまとめたものです。

---

## 1. 開発環境の要件（事前準備）

ビルドを実行する前に、以下のソフトウェアを Windows 環境にインストールし、セットアップを完了させてください。

- **Visual Studio** (MSVC)
  - インストール時に「C++ によるデスクトップ開発」ワークロードを選択してください。
- **CMake**
  - ビルド設定の生成に必要です。インストール時にシステム PATH へ追加するオプションを選択するか、手動で PATH を通してください。
- **Git for Windows**

### Linux / WSL (Windows Subsystem for Linux) 環境の事前準備
Linux (Ubuntu / Debian 等) 上でビルドを行う場合は、事前に以下のパッケージをインストールしてください。
```bash
sudo apt update
sudo apt install build-essential libncursesw5-dev liblua5.4-dev pkg-config gdb \
                 libx11-dev libxft-dev libxpm-dev libxaw7-dev libxt-dev fonts-noto-cjk
# X11 GUI 版で日本語入力（getlin / askname ダイアログ等）に fcitx5 を使用する場合（§2.2.2 の「fcitx5 の設定と起動」を参照）
sudo apt install fcitx5 fcitx5-frontend-gtk3 fcitx5-modules fcitx5-mozc
```

| パッケージ | 用途 |
|---|---|
| `build-essential` | gcc / make 等のビルドツール一式 |
| `libncursesw5-dev` | curses (UTF-8 対応) ターミナル UI ライブラリ |
| `liblua5.4-dev` | Lua 5.4 組み込みスクリプトエンジン |
| `pkg-config` | ライブラリのコンパイルフラグ解決 |
| `gdb` | パニックトレース (`PANICTRACE_GDB`) によるクラッシュ解析。実行時に必要 |
| `libx11-dev` / `libxft-dev` / `libxaw7-dev` 等 | X11 GUI ポート (UTF-8 Xft / Athena Widgets) のビルド・描画ライブラリ |
| `fonts-noto-cjk` (`Noto Sans CJK JP`) | X11 GUI ポートで日本語・墓石死因の文字化けを防ぐ日本語 CJK フォントパッケージ |
| `fcitx5` / `fcitx5-mozc` 等 | X11 GUI ポートで getlin / askname ダイアログへの日本語入力（XIM）を行う IM サーバと変換エンジン（§2.2.2 参照） |
| `qt6-base-dev` / `qt6-multimedia-dev` / `qt6-base-dev-tools` | Qt6 GUI ポートのビルドライブラリ / サウンド機能 / `moc` 等のツール（Ubuntu 26.04 では Qt 6.10.2 系） |
| `fcitx5-frontend-qt6` | Qt6 GUI ポートの getlin / askname / メニュー Search 等への日本語入力（§2.2 に記載の `QT_IM_MODULE=fcitx` と併用） |

> [!NOTE]
> `gdb` は **実行時**にも参照されます。`sysconf` の `PANICTRACE_GDB=1` が有効な状態で `gdb` が存在しない場合、クラッシュ時に追加のバックトレース情報が取れないだけでなく、起動に失敗するケースもあります。インストールしておくことを強く推奨します。

*GUI ポート（X11 や Qt）のコンパイルを行う場合は、上記パッケージを事前導入してください。*

---

## 2. ビルドの実行

### 2.1. Windows ポートの開発・ビルド (MSVC)
リポジトリに用意されている開発者用のバッチファイルを実行することで、ビルドとテストを安全に行うことができます。
- **実行スクリプト**: `sys/windows/vs/build_one.bat`
- このスクリプトは、MSVCのビルド環境（`Release|x64`）を自動セットアップした上で一貫したビルドを行います。

### 2.2. Linux / WSL ポートの開発・ビルド (GNU Make / GCC)
WSL または Linux 環境上で、ワンステップ用ビルドスクリプトを実行して Makefile の生成とビルドを一括で行うことができます。
- **実行スクリプト**: `sh sys/unix/build_wsl.sh`
- **Qt6 ポートを追加でビルドする場合**: 同一スクリプトに `--qt` を渡すこと（`WANT_WIN_QT=1 WANT_WIN_QT6=1 WANT_DEFAULT=Qt` が付与される）。Qt6 開発パッケージ (`qt6-base-dev` / `qt6-multimedia-dev` / `qt6-base-dev-tools`) が必要で、事前に pkg-config と `moc` の存在が確認される。ヒントファイル `sys/unix/hints/linux-jp` の既存 Qt 分岐を流用するため、ヒント自体の編集は不要。
- *Qt ビルドの実行例*:
  ```bash
  sh sys/unix/build_wsl.sh --qt
  make WANT_WIN_CURSES=1 WANT_WIN_TTY=1 WANT_WIN_X11=1 WANT_WIN_QT=1 WANT_WIN_QT6=1 WANT_DEFAULT=Qt install
  QT_IM_MODULE=fcitx QT_QPA_PLATFORM=xcb ./playground/nethack -wQt
  ```
  - `make install` もビルドと同じ `WANT_WIN_QT=1 WANT_WIN_QT6=1` フラグで実行する必要がある（Qt 用データ `nhtiles.bmp` / `nhsplash.xpm` は `VARDATND0` が make 実行時の `ifdef` 評価で `DATNODLB` に追加されるため、フラグ無し install では `playground/` にコピーされない）。
  - `QT_IM_MODULE=fcitx` は getlin / askname / plsel / メニューSearch への Mozc による日本語入力（`fcitx5-frontend-qt6`）に必須。
  - `QT_QPA_PLATFORM=xcb` は WSLg での Qt プラットフォームを X11/xcb に固定する指定（Wayland は対象外）。
- スクリプト実行により、日本語対応ヒントファイル `sys/unix/hints/linux-jp` が使用され、`src/nethack` に `tty` / `curses`（`ncursesw` による UTF-8 日本語表示対応）/ `X11`（Xft UTF-8 描画 + XIM 日本語入力対応）の **3 インターフェースに対応した実行ファイル**が生成されます（`--qt` 指定時は `Qt`（Qt6 / UTF-8 入出力対応）を含む **4 インターフェース**）。
- *手動でステップを実行する場合*:
  ```bash
  sh sys/unix/setup.sh sys/unix/hints/linux-jp
  make WANT_WIN_CURSES=1 WANT_WIN_TTY=1 WANT_WIN_X11=1 WANT_DEFAULT=tty all x11tiles
  ```

#### 2.2.1. インストール（`make install`）— 必須

ビルド完了後、**必ず `make install` を実行してください**。
`src/nethack` を直接実行しても、起動直後に下記のようなエラーが発生して終了します。

```
/mnt/c/Users/satok/NetHackJP/playground: No such file or directory
Cannot chdir to /mnt/c/Users/satok/NetHackJP/playground.
```

これは `nethack` 実行ファイルが起動時に `HACKDIR`（= `playground/`）へ `chdir()` しようとするためです。
`playground/` ディレクトリとその中身は `make install` によって初めて作成されます。

```bash
make install
```

`make install` が行う主な処理：

| 処理 | 内容 |
|---|---|
| `mkdir -p playground/` | HACKDIR（ゲーム実行ディレクトリ）を作成 |
| `mkdir -p playground/save` | セーブファイル格納ディレクトリを作成 |
| `cp src/nethack playground/` | 実行ファイルをコピー |
| `cp dat/nhdat playground/` | 日本語データリソース（DLB）をコピー |
| `cp sys/unix/sysconf playground/` | システム設定ファイルをコピー |
| X11 関連ファイルの配置 | `playground/x11tiles`（タイルセット）、`playground/NetHack.ad`（X リソース）、`nh10.pcf` / `fonts.dir`（フォント）、`rip.xpm` 等をコピー |
| `touch playground/record` 等 | ハイスコア・ログ・ライブログファイルを新規作成 |

#### 2.2.2. 実行とウィンドウポート（tty / curses / X11）

`make install` が完了したら、`playground/nethack` を起動します。

```bash
playground/nethack
```

PATH に追加して短縮することも可能です。

```bash
export PATH="$PATH:$(pwd)/playground"
nethack
```

生成バイナリは 3 ポートに対応しており、`-w` コマンドラインオプションまたは `~/.nethackrc`（ホームディレクトリ）／カレントディレクトリの `.nethackrc` の `windowtype` で切り替えます（コマンドライン指定が設定ファイルより優先されます）。

##### (a) tty インターフェース（デフォルト）
UTF-8 対応ターミナル（Windows Terminal 等）で起動します。

```bash
playground/nethack        # ビルド時のデフォルト（WANT_DEFAULT=tty）
playground/nethack -wtty  # 明示指定
```

```text
# ~/.nethackrc
OPTIONS=windowtype:tty
```

##### (b) curses インターフェース（CUI では推奨）
`ncursesw` による UTF-8 日本語表示対応です。

```bash
playground/nethack -wcurses
```

```text
# ~/.nethackrc
OPTIONS=windowtype:curses,align_message:top,align_status:right
```

##### (c) X11 GUI インターフェース
X リソース（`NetHack.ad`）とタイルセット（`x11tiles`）は `make install` で `playground/` に配置済みです。`XAPPLRESDIR` を `playground/` に向けて起動します（WSLg 内蔵の X サーバ、または外部 X サーバ上で実行）。

```bash
XAPPLRESDIR=./playground ./playground/nethack -wX11
```

```text
# ~/.nethackrc（リポジトリ直下のサンプル `.nethackrc.X11` を `~/.nethackrc` としてコピーしてもよい）
OPTIONS=windowtype:X11
```

※ リリースパッケージでは同封の `./nethackW` スクリプトで起動できます。X11 版のタイルセットはデフォルトで `x11tiles` が読み込まれますが、`.nethackrc` の `OPTIONS=tile_file:ファイル名,tile_width:32,tile_height:32` や `NetHack.ad` リソースで任意のファイル名およびタイルサイズ（幅・高さ）を指定できます（未指定時は画像サイズから自動判定）。
※ 日本語入力（`#名前` `#願い` 等の getlin ダイアログ）を使用する場合は、事前に fcitx5 を起動してください（下記「fcitx5 の設定と起動」）。

##### (d) fcitx5 の設定と起動（X11 版で日本語入力する場合）
X11 版では getlin / askname ダイアログ（`#名前`、`#願い`、`#虐殺`、起動時のキャラクター名入力等）で XIM 経由の日本語入力が可能です。fcitx5 は **nethack を起動する前に**準備します。

1. インストール（1 回のみ）:
   ```bash
   sudo apt install -y fcitx5 fcitx5-frontend-gtk3 fcitx5-modules fcitx5-mozc
   ```
   （変換エンジンは `fcitx5-mozc` のほか `fcitx5-anthy` 等でも可）
2. 環境変数の設定（`~/.bashrc` と `~/.profile` に追記）:
   ```bash
   export LANG=ja_JP.UTF-8
   export XMODIFIERS=@im=fcitx   # fcitx5 は XIM サーバ名として "fcitx" を登録する
   export GTK_IM_MODULE=fcitx
   export QT_IM_MODULE=fcitx
   export SDL_IM_MODULE=fcitx
   ```
   （`xim_init()` は `C`/`POSIX` ロケール時に `C.UTF-8` へのフォールバックを試みるため、`ja_JP.UTF-8` が未生成でも `C.UTF-8` が利用可能であれば動作します）
3. fcitx5 の起動（nethack を起動する **同じシェル／セッション** で実行）:
   ```bash
   # WSL (WSLg) の場合は Wayland との競合を防ぐため以下で起動:
   fcitx5 --disable=wayland,waylandim -d
   # 通常の Linux X11 の場合:
   # fcitx5 -d

   pgrep -a fcitx5   # 起動確認
   ```
4. X11 版の起動と確認:
   ```bash
   XAPPLRESDIR=./playground ./playground/nethack -wX11
   ```
   - stderr に `XIM: connected to input method` と出力されれば fcitx5 との接続成功。
   - `XIM: XOpenIM failed` と出た場合は `pgrep -a fcitx5` と `echo $XMODIFIERS` を確認し、`fcitx5-diagnose` で問題箇所を切り分けてください。また、**新しいターミナルで nethack を起動してください**（既存ターミナルには環境変数の変更が反映されません）。fcitx5 未起動時でも ASCII 入力は動作します。
5. 入力の切替: ダイアログ内で **Ctrl+Space** で日本語入力モードをトグルします。確定は Enter / Space で、確定文字列が入力欄に挿入されダイアログは閉じないため、もう一度 Enter で OK します（詳細は §4.12）。
6. IM を無効化したい場合は `~/.nethackrc` に `OPTIONS=use_xim:off` を指定します（デフォルトは on）。

> [!NOTE]
> `hints/linux-jp` 内で `WANT_WIN_X11 = 1` および `HAVE_NCURSESW = 1` が定義されているため、生成されるバイナリは `tty`, `curses`, `X11` の 3 ポートマルチウィンドウに対応します。`X11` 使用時には Xft による日本語 TrueType/OpenType フォント描画が有効です（日本語 CJK フォントが未導入の場合は文字が白四角＝豆腐で表示されます）。マップ画面等の通常操作は 1 バイト＝1 コマンドのため IM を経由せず、日本語入力が有効なのは getlin / askname ダイアログのみです（§4.11 / §4.12）。

#### 2.2.3. まとめ（WSL での初回セットアップ全体フロー）

```bash
# (1) 依存パッケージのインストール（初回のみ）
sudo apt update
sudo apt install -y build-essential libncursesw5-dev liblua5.4-dev pkg-config gdb \
                    libx11-dev libxft-dev libxpm-dev libxaw7-dev libxt-dev fonts-noto-cjk
# X11 版で日本語入力する場合（詳細は §2.2.2「fcitx5 の設定と起動」）
sudo apt install -y fcitx5 fcitx5-frontend-gtk3 fcitx5-modules fcitx5-mozc

# (2) リポジトリのクローン（初回のみ）
# git clone https://github.com/satokiyon/NetHackJP.git
# cd NetHackJP

# (3) ビルド（tty / curses / X11 3ポート対応バイナリの生成）
sh sys/unix/build_wsl.sh

# (4) インストール（playground/ を構築。NetHack.ad と x11tiles も配置される）
make install

# (5) 日本語入力の準備（X11 版で日本語入力する場合のみ）
export LANG=ja_JP.UTF-8
export XMODIFIERS=@im=fcitx
fcitx5 --disable=wayland,waylandim -d

# (6) 起動
playground/nethack                                   # tty インターフェース
playground/nethack -wcurses                          # curses インターフェース
XAPPLRESDIR=./playground ./playground/nethack -wX11  # X11 GUI インターフェース
```

> [!TIP]
> 再ビルド後も毎回 `make install` の実行が必要です。
> `make all && make install` とまとめると便利です。



---

## 3. 翻訳方針と補足情報

### 日本語助詞とモノ名の連結問題
* `You_feel` / `You_hear` / `You_see` は接頭辞を自動付与するため、呼び出し側リテラルで主語重複や助詞衝突を起こさないようにします。
* `%s` の直後に助詞（`は/を/に/へ/が/の/と/から`）が来る文では、`mon_nam()` / `Monnam()` より `l_monnam()` の利用を優先します。
* `%s%sから` のような複合テンプレートは機械置換せず、文脈ごとに語順を手動で整えます。
* 英語冠詞を返す補助（`just_an()` など）の結果は、日本語文へ直接連結しません。
* `%s`, `%d`, `%ld`, `%c` などのフォーマット指定子は、個数・順序・型を変更しません。
* 原則として文字列リテラルのみを変更し、ゲームロジックや条件分岐の意味は変えません。
* `隠し%s` のようなテンプレートは、展開後の最終語形 (`隠し扉`, `隠し通路`) が自然か確認します。

### コーディング規約とビルド対応
* **MSVC警告対応**: MSVC (Visual Studio) でのビルド時に `warning C4210` (関数内のextern宣言) などの警告が出ないよう、宣言は原則としてファイルスコープで行います。
* **日本語対応関数の命名**: 日本語化に関連する独自の補助関数には `jp_` 接頭辞（例: `jp_insight_has_nonascii`）を付与し、既存コードとの区別を明確にします。

### 再発防止と品質管理
翻訳やコード修正を行う際は、以下の点に注意して問題の発生を未然に防ぎます。

* **コミット前のビルド確認**: 変更を加えた後は、必ず `sys\windows\vs\build_one.bat` を実行してビルドが通ることを確認してください。構文エラーや未使用変数の警告などはこの段階で排除します。
* **構文と括弧の整合性**: 大規模な翻訳やリファクタリングを行った後は、中括弧 `{}` や括弧 `()` の対応が崩れていないか細心の注意を払ってください。
* **内部ロジックの再確認**: 死因 (`killer`) や中断理由 (`multi_reason`) などの内部キーとしても機能する文字列を翻訳した場合は、それらを参照している他の箇所（`topten.c` や `end.c` など）のロジックが壊れていないか、広範囲に調査して整合性を保ってください。
* **文字コードと文字化けの防止**: ソースファイルは UTF-8 で保存し、マルチバイト文字が不自然に分割されたり、特殊な制御文字が混入したりしないように注意してください。
* **未使用コードの整理**: 翻訳によって不要になった変数（英語メッセージ用の `message` や `verb` など）は、放置せずに削除してコンパイラの警告を最小限に抑えてください。

### 実施済みの翻訳改善・検証実績
* **`dat/tribute_jp` 内の冗長な「だった」表現および不自然な日本語訳の全面刷新（2026年8月完了）**:
  - `dat/tribute_jp` に存在していた、過去の機械翻訳に起因する「〜のだった」「〜だったのだった」といった冗長な文末表現を徹底して排除し、自然な日本語の過去形表現（例: 「判断した」「確信を持っていた」等）に修正しました。
  - 英語の指示代名詞（`it`, `this`, `he` など）が機械翻訳によって「色」「色彩」と直訳されていた箇所の誤訳を元の文脈（「これ」「彼」など）に修復しました。
  - カタカナ表記の「アンド」を「そして」「また」「〜と」などの自然な日本語表現に置き換えました。
  - マッピングズレ（アライメントの崩れ）を完全に同期・修復し、英語原本 `dat/tribute` の各パッセージと1対1で対応する状態（Offset 0）を最終パッセージ（ID 561）まで完全に維持しました。

  #### 品質維持・検証プロセス:
  1. **表示幅（75文字以内）と制御行の自動検証 (`validate_tribute.js`)**:
     - 編集時、およびコミット前には必ず自動検証スクリプトを実行し、以下の項目を検証して整合性を確保します：
       - **表示幅の厳守**: 各行の表示幅（全角2, 半角1）が 75 表示幅を超過していないこと。
       - **制御行の完全一致**: 全 561 パッセージおよび 2,249 行の制御行（`%section`, `%title`, `%passage`, `%e` 等）のシーケンスが原本と完全一致していること。
  2. **データビルドツールによる最終実地検証**:
     - `cmd /c "cd dat && ..\tools\Release\x64\makedefs.exe --make d"` を実行し、データ変換エラーが 0 件で正常コンパイルされることを確認します。



---

## 4. 独自拡張機能とアップストリーム同期

NetHackJP では、本家（アップストリーム）で未実装ながら利便性の高い機能を独自に実装している場合があります。これらは将来的にアップストリームで同様の修正が入った際、混乱を避けるために一括削除または差し替えが容易な構成にしています。

### 1. セーブデータ選択時の属性自動復元機能
ゲーム開始時のセーブデータ一覧からキャラクターを選択した際、職業・種族・性別・属性およびプレイモードを自動的に復元する機能です。
* **マーカータグ**: `/* NetHackJP: save data restoration */`
* **対象ファイルと削除手順**:
  1. **`include/extern.h`**: `select_saved_game` のプロトタイプ宣言を削除。
  2. **`src/role.c`**: `select_saved_game` 関数の実装全体を削除。
  3. **`src/restore.c`**: `restore_menu()` 関数内の `select_saved_game` の呼び出し箇所を削除。

### 2. セーブデータ一覧の重複表示バグの修正（Windows）
Windows版において、複数のセーブファイルが存在する際に一覧画面で同じキャラクターが重複して表示されてしまうバグの修正です。
* **マーカータグ**: `/* NetHackJP: update buffer for each file */`
* **対象ファイルと削除手順**:
  1. **`src/files.c`**: `get_saved_games()` 関数内の `foundfile_buffer()` の呼び出し箇所をアップストリームに合わせて差し戻し。

### 3. ハイスコアレコードの UTF-8 文字数ベースの切り詰め対応
プレイヤー名に日本語 (UTF-8) を含む場合に、ハイスコアレコード (record ファイル) 内で 10 バイトで丸ごと切られてしまう問題を修正し、UTF-8 文字数ベースで 10 文字まで保持できるようにした独自拡張です。
* **マーカータグ**: `/* NetHackJP: UTF-8 char truncation for topten name */`
* **背景**:
  - 従来は `src/topten.c` の `NAMSZ = 10` (バイト単位) で `copynchars(t0->name, svp.plname, NAMSZ)` により切り詰めていたため、日本語名は 3〜4 文字程度で切られていた。
  - これを `NAMSZ = 40` バイト + `NAMSZ_CHARS = 10` 文字の二段構えにし、`utf8_char_truncate()` で文字境界を保護しながら切り詰めるようにした。
  - ついでに、レビューで指摘された `readentry` での `t1` バッファの未初期化バイトが `strncmp` 比較に悪影響を及ぼす問題、および `SCANBUFSZ` にはヘッダー領域が算入されておらず行末が `fgets` で欠落し得る問題も併せて修正している。
* **対象ファイル**:
  - **`src/hacklib.c`**: `utf8_char_truncation_point()` / `utf8_char_truncate()` を新規追加。
  - **`include/hacklib.h`**: 上記 2 関数の `extern` 宣言を追加。
  - **`src/topten.c`**:
    - `NAMSZ` を `10` → `40` に拡大し、`NAMSZ_CHARS = 10` を新設。
    - 名前保存を `copynchars(NAMSZ)` + `utf8_char_truncate(NAMSZ_CHARS)` に変更。
    - `readentry()` の両分岐 (旧 `fmt32` / 現行 `fmt33`) で読み込み後に `utf8_char_truncate()` を適用。
    - `topten()` / `prscore()` で `newttentry()` 直後に `*t1 = zerott;` を追加 (4 箇所)。
    - `outentry()` の表示用フォーマットを `%.10s` → `%.*s` (NAMSZ) に変更。
    - `SCANBUFSZ` の算出式に `TT_HDR_MAX = 80` を加算。
* **アップストリーム追従手順**:
  1. アップストリーム (`upstream/NetHack-5.0`) で本件と同等の修正が入ったか確認する (例: `NAMSZ` 拡大、`SCANBUFSZ` のヘッダー領域算入、`strncmp` 対象のバッファゼロ化、UTF-8 文字数での切り詰めなど)。
  2. アップストリームに修正がある場合は、本独自拡張 (上記マーカータグで囲まれた変更) を取り消してアップストリームの実装に追従する。
  3. アップストリームに部分的な修正しかない場合は、重複する変更 (例: 既にアップストリームが `NAMSZ` を変更済みなら本件の `NAMSZ = 40` 化は重複) のみを取り消し、残りは維持する。
  4. `utf8_char_truncate` 等の独自 API が他で利用されている場合は、アップストリーム API との整合性を確認の上でリネームまたはラッパー化を検討する。

### 4. `look` コマンド結果リストへのタイル ID 引き渡し (Android/Flutter 向け)

Android/Flutter ポート (`NetHackJP-Android`) で `look_all` / `look_traps`
/ `look_engrs` が生成する結果リスト (NHW_TEXT ウィンドウ) の各行に
対応するエンティティ (怪物 / 物体 / 罠 / 刻印) の代表タイルを表示する
ための独自拡張です。 アップストリーム NetHack には `putmixed(win, attr,
str)` という API しかなく、 タイル ID を直接渡せないため、 タイル ID
を引数に取る `flutter_putmixed_with_tile(win, attr, tile, str)` を
新規追加しています。

* **マーカータグ**: `/* NetHackJP: putmixed with tile for look result list */`
* **対象ファイル**:
  1. **`src/pager.c`**:
     - ファイル先頭付近に `flutter_putmixed_with_tile` の `extern` 宣言を追加。
     - `look_all()` (怪物 / 物体 結果リスト) の `putmixed` 呼び出しを
       `flutter_putmixed_with_tile` に置換、 タイル ID を `mon_to_glyph`
       / `hero_glyph` / `obj_to_glyph` / 元 glyph から `map_glyphinfo`
       経由で計算。
     - `look_traps()` (罠 結果リスト) で同様に置換と計算。
     - `look_engrs()` (刻印 結果リスト) で同様に置換と計算。
  2. **`src/windows.c`**:
     - 非 Android 環境向けデフォルト実装 `flutter_putmixed_with_tile`
       を `#ifndef ANDROID` ガード付きで追加 (単に `putmixed` を呼ぶだけ、
       tile 引数は無視)。
* **背景**:
  - 既存の `putmixed(win, attr, str)` にはタイル ID 引き渡し口がない。
  - 新 API `flutter_putmixed_with_tile` は Android/Flutter ポート
    (`win/winflutter.c`) でのみ FFI 経由で Dart 側にタイル ID を渡し、
    それ以外のポート (tty, curses, win32, Qt, X11 等) では src/windows.c
    のデフォルト実装が使われる。
  - Android 判定は CMake の `add_definitions(-DANDROID)` に従う。
    そのため、 `src/windows.c` 側の実装は Android ビルドでは
    コンパイルされず、 `win/winflutter.c` 側の同名関数がリンクされる。
* **アップストリーム追従手順**:
  1. アップストリームが `putmixed` の拡張 (例: `glyph_info` 引き渡しや
     新ウィンドウプロック `win_putmixed_with_tile` 追加) を入れたかを
     確認する。
  2. アップストリーム版と本独自実装が衝突する場合は、 本独自実装を
     取り消してアップストリーム版に追従する (新ウィンドウプロックが
     追加されたなら `winprocs.win_putmixed_with_tile` を使う形に
     置換するのが望ましい)。
  3. `flutter_putmixed_with_tile` シンボル自体が他で使われていないかを
     `git grep` で確認し、 残骸が残らないようにする。
  4. 一方で、 「`look_all` / `look_traps` / `look_engrs` の結果リストに
     タイル ID を渡す」 というコンセプト自体は有用なため、
     アップストリーム側の新設計に合わせつつ結果リストにタイル ID を
     含める修正を継続検討する。

### 5. Linux/WSL・Android における CRLF サニタイズおよび UTF-8 端末表示の崩れ防止
Linux/WSL や Android (Bionic libc) 環境において、Windows 側でチェックアウトされた CRLF (`\r\n`) ファイルの読込時、および TTY 画面出力時に `\r` (0x0D) や `g_putch` への誤送信によって画面先頭文字が化ける (`␊`, `␌`, `␍`, `°` などのグラフィック制御記号表示やリードバイト破壊) 現象を防止するための独自修復です。

* **マーカータグ**: `/* NetHackJP: CRLF and UTF-8 TTY display fixes for Linux/WSL/Android */`
* **対象ファイル**:
  1. **`src/nhlua.c`**: `nhl_loadlua()` で CRLF ファイルをバッファ読み込みする際の `\r` スキップ順序を修復（`\n` の前にある `\r` をスキップ）。
  2. **`src/dlb.c`**: `lib_dlb_fgets()` および `dlb_fgets()` の `\r` 除去処理を `WIN32` 限定から全プラットフォーム対応に変更。
  3. **`util/makedefs.c`**: `do_data_for()` および `do_oracles()` でのファイル生成モードを `WRBMODE` (バイナリ) に変更し、`ftell()` オフセット計算のズレを防止。
  4. **`src/questpgr.c`**: `convert_line()` で `\r` に遭遇した際に早期 return せずスキップするよう修正。
  5. **`win/tty/wintty.c`**:
     - `tty_putstr()` の入口で `\r` を除去するサニタイズ処理を追加。
     - `utf8_text_wrap_index()` を全プラットフォームで利用可能にし、非 WIN32CON (Linux/Android) 環境でもマルチバイト安全なテキスト折り返しを行えるよう修正。
     - `tty_put_utf8_sequence(&cp)` ヘルパー関数を新設し、`tty_display_nhwindow()` 内のプラットフォーム非依存統一描画ループにて全環境（Windows/WSL/Linux/Android）で UTF-8 マルチバイト文字を安全にセル幅加算出力するようリファクタリング。
* **アップストリーム追従手順**:
  - アップストリーム側で CRLF の取扱い向上や `utf8_text_wrap_index` の全 tty ポート対応、あるいは tty ディスプレイライブラリの UTF-8 行頭文字処理が入った場合は、本変更箇所のマーカータグを確認し追従または整理を行う。

### 6. curses メッセージウィンドウの UTF-8 ワイド文字カラーペア取得修復
ncursesw (Linux/WSL ワイド文字 curses) 環境において、`windowtype:curses` でターン経過時に過去メッセージがアンハイライト（ボールド解除）される際、古いメッセージの文字色が緑・紫・黄色・オレンジ等にランダム化けする現象を防止するための独自修復です。

* **マーカータグ**: `/* NetHackJP: Wide-character (UTF-8) color pair extraction fix */`
* **背景**:
  - `win/curses/cursmesg.c` の `curses_clear_unhighlight_message_window()` 内で、1バイト ASCII 用関数 `mvwinch` と `PAIR_NUMBER` マクロを使って画面セルの既存カラーペアを取得していた。
  - ncursesw 環境で全角漢字・ひらがな等（3バイト UTF-8）のセルに対して `mvwinch` を使うと、文字コードビットが `PAIR_NUMBER` が抽出するカラーペア番号領域に混入し、不正なカラーペア番号（緑、紫、黄色等）として計算され文字色が化けていた。
  - ワイド文字用 API (`mvwin_wch` および `getcchar`) を利用してワイド文字セルから正確にカラーペア番号を取得するように修復した。
* **対象ファイル**:
  - **`win/curses/cursmesg.c`**: `curses_clear_unhighlight_message_window()` 内で `NCURSES_WIDECHAR` / `CURSES_UNICODE` 条件分岐を追加し、`mvwin_wch` / `getcchar` を用いてカラーペアを取得・再設定するよう修正。
* **アップストリーム追従手順**:
  - アップストリームで ncursesw のワイド文字セルに対する `mvwin_wch` / `getcchar` を用いたアンハイライト修復、あるいは `curses_clear_unhighlight_message_window` のリファクタリングが入った場合は本変更を取り消して追従する。
     タイルを添える」 という仕様自体は Android/Flutter ポートの
     ユーザ体験に直結するため、 アップストリームが同等の機能を
     入れても問題なければ本独自実装は削除して良い (動作は同等のため)。

### 5. 日本語メッセージ内の複数形 "s" (plur) の排除と日本語化
日本語メッセージが表示される箇所において、英語の複数形接尾辞 `"s"`（`plur()` マクロ）がそのまま表示されてしまう翻訳バグや、英語の単語がそのまま出力されてしまっていた箇所を修正しました。
* **マーカータグ**: 
  - `/* NetHackJP: Pass currency(amt) instead of plur(amt) to display proper currency unit */` (通貨表示の修正)
  - `/* NetHackJP: Remove plur(...) to avoid trailing 's' in Japanese */` (複数形 "s" の排除)
  - `/* NetHackJP: Sprintf hornbuf to "角" instead of "horn(s)" to make it Japanese */` (角のヘルメット突き破りメッセージの日本語化)
  - `/* NetHackJP: Distinguish singular/plural for Kop in Japanese */` (コップ消滅メッセージの単複切り分け)
  - `/* NetHackJP: expand suffix buffer size to prevent overflow in Japanese */` (呼び出しの燭台の日本語表示用バッファサイズ拡張)
* **対象ファイル**:
  1. **`src/shk.c`**:
     - `shk_names_obj()` 内で `plur(amt)` の代わりに `currency(amt)` を渡すように変更。
     - 店主の道具持ち込み拒否時のセリフおよびメッセージから `plur(cnt)` 排除。
     - コップ消滅時のメッセージで `cnt` に応じて「コップ」と「コップ達」を切り分けるよう修正。
  2. **`src/objnam.c`**:
     - `killer_xname()` 内で危険なスライムモールドの名称フォーマットから `plur(obj->quan)` を排除。
     - `xname()` 内で呼び出しの燭台（`CANDELABRUM_OF_INVOCATION`）の `suffix` バッファサイズを `24` から `32` に拡張。
  3. **`src/polyself.c`**:
     - 角がヘルメット等を突き破った時のメッセージを「角」として日本語化。
     - コカトリス等の死体の下に隠れて石化した際の pline メッセージから `plur(ct)` を排除。
  4. **`src/region.c`**:
     - ガス雲消散時のメッセージから `plur(gg.gas_cloud_diss_seen)` を排除。
* **アップストリーム追従手順**:
  1. 本件は日本語メッセージのフォーマットに合わせた修正（日本語化特有の対応）であるため、アップストリームマージ時に競合した場合は、日本語側の文脈に合わせて `plur` や英語表記を排除する変更を維持するように競合解決を行ってください。

### 6. CodeQL指摘によるバグ・誤検知の安全な修正
GitHub CodeQL によるコードスキャン警告（Critical）を修正するための NetHackJP 独自の変更です。

1. **makedefs.c のバッファオーバーフロー修正**
   - **マーカータグ**: `/* NetHackJP: expand str buffer to prevent overflow */`
   - **対象**: `util/makedefs.c`
   - **背景**: control 文字の 16進出力バッファ `str[10]` に、負の値の char が渡された場合に `sprintf` で 11 バイト書き込もうとしてオーバーフローする問題を、バッファ拡張とキャストで回避しました。
   - **アップストリーム追従手順**:
     1. アップストリーム（本家）で同等のバッファサイズ変更やキャスト修正が入った場合は、本修正を削除して追従します。

### 7. ステータスハイライトメニューにおけるキャンセル時の無限ループ修正
ステータスハイライトルール追加時 (`status_hilite_menu_add()`) に、文字列型フィールドや値入力のない動作で色選択をキャンセル（`-1`）した際、`goto choose_value` からそのまま `choose_color` に直線落下して即座に色選択が再表示される無限ループバグの修正です。

* **マーカータグ**: `/* NetHackJP: Fix infinite loop on cancel in status_hilite_menu_add */`
* **対象ファイル**:
  - **`src/botl.c`**: `status_hilite_menu_add()` 内の色選択キャンセル判定を修正し、数値入力を行わない動作または文字列型フィールドの場合は `goto choose_behavior` へジャンプして動作選択メニューへ復帰するよう変更。
* **アップストリーム追従手順**:
### 8. C23 規格 / GCC 14+ / Clang 18+ 基準でのビルド警告・型厳格化対応
現代の C コンパイラ（GCC 14+ / Clang 18+）および C23 規格でのビルド厳格化に伴うコンパイルエラー・警告の解体と、マルチプラットフォーム（Linux / WSL, Android NDK, Windows MSVC）互換性を維持するための修正です。アップストリーム（本家 NetHack）のマージ時にコンフリクトが発生した場合は、以下の指針に従って競合解決を行ってください。

* **主な修正内容**:
  1. **`win/tty/termcap.c` の `tparm` プロトタイプ修復**:
     - C23 規格では `extern char *tparm();` の空括弧 `()` が `(void)`（引数0個）と解釈されコンパイルエラーとなるため、可変長引数プロトタイプ `extern char *tparm(const char *, ...);` に修正。
  2. **バッファオーバーフロー防止 (`-Wformat-overflow=`)**:
     - `src/insight.c`, `src/shk.c`, `src/dungeon.c`, `src/wizcmds.c` において、日本語 (UTF-8 全角3バイト) 出力時のオーバーフローを防ぐため `Sprintf` 用ローカルバッファを `BUFSZ` / `BUFSZ * 2` に拡大。
  3. **プロトタイプ欠落の解消 (`-Wmissing-prototypes`)**:
     - `src/mon_jp.c`, `src/objnam.c`, `src/nhlua.c`, `src/options.c`, `src/jp_data_lookup.c`, `src/pager.c`, `src/polyself.c`, `src/rip.c`, `src/shknam.c`, `src/topten.c`, `src/mondata.c` 内のモジュール内限定独自ヘルパー関数（`jp_*` 等）に `static` 宣言を明示。`include/extern.h` に `flutter_putmixed_with_tile` のプロトタイプを追加。
  4. **型属性修復とシャドウイング防止 (`-Wdiscarded-qualifiers`, `-Wshadow`)**:
     - `src/botl.c` の `const char *beh_disp` 導入、および `src/mondata.c`, `src/objnam.c`, `src/pager.c` のローカル変数リネーム（`g_idx`, `g_glyph`, `local_genders`）。

* **アップストリーム追従・マージ判定手順**:
  1. **`tparm()` プロトタイプ**: アップストリーム側で可変長引数プロトタイプへの変更や `ncurses` ヘッダー利用への切り替えが入った場合は、本修正を取り消してアップストリームの実装に追従してください。
  2. **日本語固有関数 (`jp_*`) の `static` 宣言**: 日本語化固有のヘルパー関数に関する変更であるため、アップストリームマージ時もモジュール内閉塞（`static` 宣言）を維持してください。
  3. **固定バッファ拡大 (`BUFSZ` / `BUFSZ * 2`)**: 日本語 UTF-8 表示に必要なバッファ長確保（全角文字のバイト数膨張対応）であるため、アップストリームのコードと競合した場合は、バッファサイズ拡大を維持する形で競合を解決してください。
  4. **型修復・シャドウイング対策**: アップストリームで同等の型修正や変数名変更が入っている場合はアップストリームの表記に追従し、入っていない場合は型安全性維持のため本修正を保持してください。

### 7. TTY 環境における `DEF_PAGER` の `_jp` ヘルプファイル優先検索と DLB フォールバック
Linux/UNIX 環境の TTY モード（`wintty.c`）において、`DEF_PAGER`（外部ページャー `more`/`less` 等）使用時に日本語ファイル（`help_jp` 等）が優先オープンされるようにし、実ファイルがない場合は `dlb_fopen`（内部画面表示）に自動フォールバックする機能を追加しました。
* **マーカータグ**: `/* NetHackJP: try _jp file first for DEF_PAGER, and fallback to dlb_fopen if open fails */`
* **対象ファイル**: `win/tty/wintty.c`
* **背景**:
  - 従来 `wintty.c` の `tty_display_file()` は `#ifdef DEF_PAGER` で `open(fname, O_RDONLY)` を直接呼び出していたため、`_jp` ファイルの試行検索が行われず、また DLB (`nhdat`) コンテナ内のファイルを開けなかった。
  - この変更により、指定 `fname` に対してまず `_jp` 付き実ファイルの `open()` を試み、失敗した場合は内部ページャー（`dlb_fopen`）へフォールバックして DLB 内の日本語ヘルプファイルを画面表示できるようにした。
* **アップストリーム追従手順**:
  - アップストリームで外部ページャーの `open()` 処理や `display_file` の仕様が変更された場合、本マーカータグのブロックを確認し、`_jp` 付きファイル検索と `dlb_fopen` フォールバックのロジックを保持した状態で競合解決を行ってください。

### 8. Linux/WSL X11 GUI ポートにおける UTF-8 日本語描画対応
Linux/UNIX 環境の X11 ウィンドウポート（`win/X11`）において、Xft (FreeType/Fontconfig) 描画を UTF-8 化し、日本語 TrueType/OpenType フォントを正しくレンダリングできるようにしました。

> [!IMPORTANT]
> §4.8 は **描画のみ** を扱います。**XIM（インプットメソッド）による日本語入力は §4.10 で扱います**。`XtSetLanguageProc(NULL, NULL, NULL)` は `LC_CTYPE` / `LC_MESSAGES` のロケールを初期化するのみで、fcitx5 / ibus 等の IM サーバとの通信経路は提供しません。XIM による実際の日本語入力は §4.10 を参照してください。

* **マーカータグ**: `/* NetHackJP: X11 UTF-8 text rendering and input support */`
* **対象ファイル**:
  1. **`sys/unix/hints/linux-jp` & `sys/unix/build_wsl.sh` & `sys/unix/Makefile.dat`**: `WANT_WIN_X11=1` を有効化し、`tty`, `curses`, `X11` の 3 ポートマルチバイナリ生成に対応。また、`Makefile.dat` における `tile2x11` のテキストファイル引数順序を `tile.c` のレイアウト（`monsters`, `objects`, `-grayscale monsters`, `other`）と完全一致させるよう修正し、NetHack 5.0 純正タイルセット `x11tiles` の自動生成・配置に対応。
  2. **`win/X11/winlabel.c`**: `XftDrawString8` / `XftTextExtents8` を `XftDrawStringUtf8` / `XftTextExtentsUtf8` に更新。
  3. **`win/X11/wintext.c`**: 墓石（RIP）画面等での描画・テキスト幅算出を `XftTextExtentsUtf8` / `XftDrawStringUtf8` に更新。また、`appResources.font_rip`（`sans-9`）単体指定時に日本語死因が文字化け（白四角化）しないよう、`font_text` や `Noto Sans CJK JP` をフォールバックフォントとして結合オープンする処理を追加。
  4. **`win/X11/winmesg.c`**: メッセージウィンドウの Xft 描画部を UTF-8 ワイド文字表示に更新。
  5. **`win/X11/winmap.c`**: マップ描画部の `XftDrawString8` を `XftDrawStringUtf8` に更新。また、`XpmReadFileToImage` 呼び出し前に Windows CRLF 改行に起因する `\r` (0x0D) 文字のトリム処理および `fopen_datafile` で `HACKDIR`（`playground/` 等）配下の `tile_file` パスを正常解決する処理を追加。
  6. **`win/X11/winstat.c`**: ステータス表示の `XftTextExtents8` / `XftDrawString8` を `XftTextExtentsUtf8` / `XftDrawStringUtf8` に更新。
  7. **`win/X11/NetHack.ad`**: Xft デフォルトフォント注釈に CJK 日本語フォント（`Noto Sans CJK JP` 等）のフォールバックガイドを追加。
* **`XtSetLanguageProc(NULL, NULL, NULL)`** は `X11_init_nhwindows` の先頭で呼んでロケールを初期化（`LC_CTYPE=ja_JP.UTF-8` 等）。**これは XIM 接続ではない**。
* **ダイアログ入力の XIM 化は当初 `AsciiText` Widget の `XtNinternational=True` で試行したが、WSLg/XWayland 環境で fcitx5 が engage しなかった**。`win/X11/dialogs.c` 側の `XtNinternational` 指定は無効で、§4.10 の `wingetlin.c` 自前ダイアログに置き換えた。
* **アップストリーム追従手順**:
  - アップストリームで X11 ポートの Xft UTF-8 化や Pango/Cairo への置き換えが入った場合は、本変更箇所を取り消してアップストリームに追従してください。


### 9. X11 ポートにおける未初期化 XFontStruct ポインタ参照保護
WSL環境などの X11 ポート (`-wX11`) において、`XtNinternational = True` 指定により `XtGetValues` で `XtNfont` が返されなかった場合に未初期化の `XFontStruct *` ポインタをデリファレンスして Signal 11 (Segmentation Fault) によりクラッシュする問題を修正するための安全ガードです。
* **マーカータグ**: 
  - `/* NetHackJP: uninitialized XFontStruct pointer guard under XtNinternational */`
  - `/* NetHackJP: uninitialized XFontStruct pointer guard */`
* **対象ファイル**:
  1. **`win/X11/dialogs.c`**: `SetDialogResponse()` 内の `XFontStruct *font` を NULL 初期化し、フォールバック幅計算を追加。
  2. **`win/X11/winstat.c`**: `create_status_window_fancy()` および `display_status_line()` 内の `fs` / `font` を NULL 初期化し、ガードを追加。
  3. **`win/X11/winX.c`**: `set_bold_font()`、`nhFontHeight()` 内の `fs` を NULL 初期化し、`yn_font` の `XTextWidth` 呼び出しに NULL ガードを追加。
### 10. UNIX/Linux 環境における起動時キャラクター名入力のデフォルト化 (`GENERICUSERS=*`) と二重入力防止
WSL や Linux 環境において、NetHack 起動時に Linux のログインユーザー名（`$USER`）が自動でキャラクター名として確定されてしまうのを防ぎ、ゲーム開始時に常にキャラクター名入力プロンプト（「お名前は？」）を表示できるようにするための設定、およびそれに伴う二重入力防止ガードです。
* **マーカータグ**: 
  - `# NetHackJP: prompt for character name on startup instead of using Linux username`
  - `/* NetHackJP: do not clear explicitly given, user-entered, or restored hero name under genericusers */`
  - `/* NetHackJP: track if svp.plname came from OS login name */`
* **対象ファイル**:
  1. **`sys/unix/sysconf`**: `GENERICUSERS` のデフォルト値を `*` に変更。
  2. **`sys/libnh/sysconf`**: `GENERICUSERS` のデフォルト値を `*` に変更。
  3. **`playground/sysconf`**: `GENERICUSERS` のデフォルト値を `*` に変更。
  4. **`include/flag.h`**: `struct instance_flags` に `plname_from_os` フラグを追加。
  5. **`src/role.c`**: `plnamesuffix()` 内で `sysopt.genericusers && iflags.plname_from_os` の場合のみ名前クリアを実行し、クリア後はフラグを解除。`select_saved_game()` でセーブ復元時にもフラグを解除。
  6. **`src/options.c`**: `optfn_name()` で `OPTIONS=name:` 指定時にフラグを解除。
  7. **`sys/unix/unixmain.c` / `sys/libnh/libnhmain.c`**: `whoami()` で OS ログイン名を取得・設定した時のみ `iflags.plname_from_os = TRUE` を設定。`-u` コマンドライン引数指定時は解除。
* **動作仕様**:
  - `GENERICUSERS=*` が指定されている場合、`whoami()` で OS ログイン名から自動設定された初期状態（`iflags.plname_from_os == TRUE`）においてのみ `src/role.c` の `plnamesuffix()` にて `svp.plname` がクリアされ、ゲーム開始時に必ず `askname()`（名前入力プロンプト/ダイアログ）が実行されます。
  - コマンドライン引数 `-u <名前>` や `OPTIONS=name:<名前>` が指定された場合、ユーザーが `askname()` で名前を入力した場合、およびセーブデータから復元された場合は `iflags.plname_from_os` が FALSE となるため、キャラクター選択後（`newgame()` -> `role_init()`）やセーブ復元後（`dorecover()` -> `role_init()`）に再度名前が消去されて二重に入力を求められる不具合を完全に防止します。
* **アップストリーム追従手順**:
  - アップストリームで `plnamesuffix()` や `sysconf` のマージ競合が生じた場合は、本設定および `iflags.plname_from_os` によるガードを維持してください。

### 11. Linux/WSL X11 GUI ポートにおける XIM インプットメソッド対応
本リポジトリの X11 ポートは上流 NetHack 5.0 には XIM（X Input Method）対応が含まれていません。fcitx5 / ibus / IIIMF 等の IM サーバと通信して日本語入力を行うための独自拡張です。詳細はルートの `XIM-IMPLEMENTATION-PLAN.md` を参照。

* **マーカータグ**: `/* NetHackJP: XIM integration */` および各ファイル内の補助タグ
* **ビルドフラグ**: `HAVE_XIM`（`sys/unix/hints/linux-jp` で `CFLAGS += -DHAVE_XIM`）
* **対応ファイル**:
  1. **`win/X11/winxim.c` (新規)**: XIM インフラ層。`XOpenIM` / `XSetLocaleModifiers` / `XCreateIC` / `XSetICFocus` / `XUnsetICFocus` / `Xutf8LookupString` のラッパーを提供。Widget ごとの IC キャッシュ、現在の focused IC の追跡、`xim_focus_in`/`xim_focus_out` ヘルパー。**`#ifdef HAVE_XIM` ガード** で、XIM 非対応環境では空マクロに展開されバイナリ影響なし。
  2. **`include/winX.h`**: `xim_init` / `xim_cleanup` / `xim_create_ic` / `xim_destroy_ic` / `xim_focus_in` / `xim_focus_out` / `xim_lookup_utf8` / `xim_is_active` の extern 宣言、および `key_event_to_utf8`（Phase 4 で追加）。
  3. **`sys/unix/Makefile.src`**: `win/X11/winxim.c` と `win/X11/wingetlin.c` を `WINX11SRC` / `WINX11OBJ` に追加し、対応する `$(TARGETPFX)winxim.o` / `$(TARGETPFX)wingetlin.o` ビルドルールを追加。
  4. **`sys/unix/hints/linux-jp`**: `HAVE_XIM=1` 設定と `CFLAGS += -DHAVE_XIM` を追加。`winxim.o` を `WINX11OBJ` に追加。
  5. **`win/X11/winX.c`**: `X11_init_nhwindows` で `xim_init(XtDisplay(toplevel))`、`X11_exit_nhwindows` で `xim_cleanup()` を呼ぶ。`nh_XtPopdown` で `xim_focus_out(NULL)` を呼んで popup 終了時に IM focus を解放。`key_event_to_utf8` を新設（Phase 4）。
  6. **`win/X11/winmap.c`**: かつては `map_input` で XIM 経路（map IC の lazy 生成と `xim_focus_in`）を使用したが、メインウィンドウで IM が勝手に engage する問題のため撤去済み（§4.12）。現在は `XLookupString` のみを使用し、メインウィンドウは IC を一切 focus しない。
  7. **`win/X11/wingetlin.c` (新規)**: `XtNinternational=True` を使った Xaw AsciiText は WSLg/XWayland + fcitx5 で engage しなかったため、`asciiTextWidgetClass` を自前の `labelWidgetClass` ベースに置換。`CreateXimDialog` / `XimDialogSetPrompt` / `XimDialogSetResponse` / `XimDialogGetResponse` / `XimDialogFocusInput` の API を提供。レイアウト・キー分類・フォーカス保存/復元を含む最終仕様は §4.12 を参照。
  8. **`win/X11/winmisc.c`**: `ec_key`（`#versuswizard` 等の extended command）をマルチバイト UTF-8 対応に。`key_event_to_utf8` で全バイトを `ec_chars[]` に append して `strncmp` で `command_list[]` と比較。
  9. **`include/winX.h`**: Phase 4 で `key_event_to_utf8` の extern 宣言追加。
* **既知の制限**:
  - yn prompts / role / race / gender / alignment 選択は単一文字入力のため、ASCII のみ対応（`や` を打鍵しても先頭バイト 0xE3 が `y`/`n` にマッチしないため無視）。これは仕様。将来の拡張で YN プロンプトも XIM 経由にできるが、yn の本質的意味（y/n/?/q の即応）からは離れる。
  - メインウィンドウ（`map_input`）は XIM 経路を持たない（§4.12）。IM は getlin / askname ダイアログでのみ engage し、プレイ中に日本語入力 UI が起動することはない。
  - XtNinternational (Athena Widgets 内部 XIM) は WSLg/XWayland + fcitx5 構成で機能しなかったため、`wingetlin.c` の自前実装に全面置換した。
* **実行時トグル (Phase 7)**:
  - `OPTIONS=use_xim:on`（デフォルト）／ `OPTIONS=use_xim:off` で XIM の有効・無効を切り替え可能。
  - 仕組み: `include/optlist.h` に `use_xim` オプション追加（`WC2_USE_XIM` ビット）、`src/options.c::optfn_use_xim` が `iflags.wc_use_xim` を 0/1 に設定。`initoptions_init()` で `iflags.wc_use_xim = 1` のデフォルトを設定（`.nethackrc` パース前）。
  - 関連ファイル:
    - `include/winprocs.h`: `WC2_USE_XIM` ビット定義
    - `include/flag.h`: `wc_use_xim` フィールド追加
    - `include/optlist.h`: `use_xim` エントリ追加
    - `src/options.c`: `optfn_use_xim` ハンドラ + `wc2_options[]` 登録 + `initoptions_init` でデフォルト値
    - `win/X11/winxim.c`: `xim_init` で `iflags.wc_use_xim == 0` の場合は `XOpenIM` をスキップ
* **アップストリーム追従手順**:
  - アップストリーム NetHack 5.0 に XIM 対応がマージされた場合は、本セクションの全独自拡張を取り消してアップストリーム版に追従する。
  - 追従時は `winxim.c` / `wingetlin.c` を削除し、`Makefile.src` から関連エントリを削除し、`linux-jp` から `HAVE_XIM=1` を削除し、`flag.h` / `optlist.h` / `options.c` / `winprocs.h` の XIM 関連エントリを取り消す。

### 12. X11 getlin / askname ダイアログ（`wingetlin.c`）の最終仕様

Xaw AsciiText の `XtNinternational=True` は WSLg/XWayland + fcitx5 構成で IM が engage しなかったため（§4.11 Phase 3）、`labelWidgetClass` ベースの自前ダイアログ `win/X11/wingetlin.c` を新設し、XIM を直接駆動している。実装過程で判明した一連の問題（フォーム縮潤・ボタン枠線不可視・ESC 経路のクラッシュ・確定文字取りこぼし・stale IC・入力欄最低幅・メインウィンドウでの IM 誤起動）はすべて解決済みで、現在は次の最終仕様で動作する。

#### 最終動作仕様
- **表示**: 入力欄は空欄時でも半角10文字分以上の幅を保ち、11文字以上でテキスト幅に追従し、全削除で最低幅へ戻る。OK / Cancel ボタンは角丸枠線（`NetHack.ad` の `shapeStyle: roundedRectangle`）が表示される。
- **キー操作**: Enter → OK（日本語確定文字列が Enter イベントに乗って届く場合は先に追記され、ダイアログは閉じない。もう一度 Enter で OK）、Space による確定も同様、Escape → キャンセル、BackSpace / Delete → 1文字削除。これらのキーが文字として挿入されることはない。
- **IM の engage 範囲**: getlin / askname ダイアログ内のみ。メインウィンドウ（マップ等）は一切 IC を focus しないため、プレイ中に日本語入力 UI が勝手に起動することはない。
- **再利用**: ダイアログを開くたびに `positionpopup()` が Window を再作成するが、IC が自動再生成・再結合されるため何回開き直っても正常に動作する。
- **フォーカス**: ダイアログを閉じると X 入力フォーカスは取得前の状態（通常 PointerRoot のポインタ追従モデル）へ復元される。

#### 実装構成（最終形）

| ファイル | 内容 |
|---|---|
| `win/X11/wingetlin.c` | 自前ダイアログ本体。全子にチェーン制約（`XtChainTop` / `XtChainLeft`）と `XtNresizable=True` を付与し Form の縮潤を防止。入力欄の最低幅は `XIM_GETLIN_MIN_CHARS`（10半角文字、実測フォント幅と 8px/文字のフォールバックの大きい方）で、`XtNlabel` 設定 → bitmap 更新 → **明示 `XtNwidth` を最後に別 `XtSetValues` で適用**（Xaw Label は label / bitmap 変更時に自前のリサイズ要求を発行し、同一呼び出し内の幅指定を上書きするため）。キーハンドラは `xim_lookup_utf8()` を keysym 判定より先に実行し、戻りの status / keysym で分類する（`XLookupChars`＝keysym を持たない IM 確定のみ追記、`XLookupBoth` かつ編集キー＝keysym 処理へフォールスルー、`XLookupBoth` かつ非編集キーで表示可能 ASCII＝追記、`XLookupKeySym`＝keysym 処理、`XLookupNone`＝IM 消費として握り潰し）。Escape 経路は `state->form` を明示渡し（イベントハンドラの `client_data` は state ポインタであり Widget ではないため）。MapNotify ハンドラは `CreateXimDialog()` 内（realize 前）に**常設**で登録され、発火のたびに `XGetInputFocus()` で直前の X フォーカスを保存 → `XSetInputFocus(OK)` → `xim_create_ic()`（Window 変更時は自動再生成）→ `xim_focus_in()` を行う。`XimDialogReleaseInputFocus()` が `nh_XtPopdown()` から呼ばれ、保存したフォーカスを復元する（OK / Cancel / Escape / WM 削除の全終了経路を 1 箇所で回収）。 |
| `win/X11/winxim.c` | IC キャッシュを Window ID 連動に拡張。エントリに生成時の `Window` を保持し、`XtWindow(w)` が変化していたら旧 IC を `XDestroyIC()` して再生成する（`positionpopup()` が開くたび Window を再作成するため必須）。破棄前には `xim_current_focused_ic` をクリアする。 |
| `win/X11/winlabel.c` / `include/winX.h` | `X11_label_string_width(Widget, const char *)` を新設（Xft 実測、非 XFT は `XtNfont` リソースへフォールバック）。winX.h に `XimDialogReleaseInputFocus` / `xim_focus_clear` の宣言を追加。 |
| `win/X11/winX.c` | `nh_XtPopdown()` から `XimDialogReleaseInputFocus()` を呼ぶ。 |
| `win/X11/winmap.c` | `map_input()` から XIM 経路を削除し、純粋な `XLookupString` に戻した（Phase 2 実装の取り止め）。メインウィンドウは IC を focus しないため、IM が engage する経路が構造的に存在しない。日本語入力は getlin / askname ダイアログ専用。 |

* **マーカータグ**:
  - `/* NetHackJP: XIM-aware getlin / askname dialog. */`（wingetlin.c 冒頭）
  - `/* NetHackJP: XIM commit capture, persistent IC/focus rebinding and minimum input-field width */`（wingetlin.c 冒頭）
  - `/* NetHackJP: recreate stale ICs when the owning widget's X window is re-created */`（winxim.c 冒頭）
  - `/* NetHackJP: map input deliberately does NOT route through the input method */`（winmap.c / `map_input`）
  - `X11_label_string_width` / `XimDialogReleaseInputFocus` の関数コメント（winlabel.c / wingetlin.c / winX.c / winX.h）
* **対応ファイル**: `win/X11/wingetlin.c`、`win/X11/winxim.c`、`win/X11/winlabel.c`、`win/X11/winX.c`、`win/X11/winmap.c`、`include/winX.h`
* **削除手順**: `wingetlin.c` / `winxim.c` 自体が独自実装であるため、アップストリームへ戻す場合はファイルごと削除し、`Makefile.src` / `linux-jp` のエントリ、`nh_XtPopdown` の `XimDialogReleaseInputFocus()` 呼び出し、winmap.c の注釈コメント、winX.h の追加宣言を取り消す。`X11_label_string_width` のみ winlabel.c 内の独立追加のため単独で取り消し可能。
* **アップストリーム追従手順**: 上流 NetHack-5.0 に XIM 対応（XFilterEvent を含む IM 統合、または `XtNinternational` ベースの実装）が導入された場合、`wingetlin.c` / `winxim.c` を削除して上流設計に全面的に追従する。`X11_label_string_width` は上流に同等の測定 API が追加された場合はそちらへ移行する。

### 13. Windows コンソール（WIN32CON）における絵文字（4バイトUTF-8）のサロゲートペア対応

* **背景**:
  Windows コンソール（WIN32CON）の `utf8_char_chartype()` / `utf8_char_display_width()`（`win/tty/wintty.c`）および `getlin_utf8_char_chartype()` / `getlin_utf8_char_display_width()`（`win/tty/getline.c`）において、`MultiByteToWideChar()` に渡す出力バッファ長が `1` に固定されていたため、サロゲートペア（UTF-16 で 2 つの `wchar_t` を要する 4 バイト絵文字や SMP 補助漢字）の変換時にバッファ不足エラー（戻り値 0）となり、文字種別判定が失敗して表示幅が 1（半角）と誤認される問題があった。これにより、画面上の絵文字のバックスペース消去幅計算（`delcols`）が狂い、消去残骸が発生していた。
* **修正内容**:
  1. `win/tty/getline.c` および `win/tty/wintty.c` の各関数において、`MultiByteToWideChar()` の出力バッファ長を `2` に拡張。
  2. 戻り値が `2`（サロゲートペア）の場合、`GetStringTypeW()` で分類フラグを取得しつつ、絵文字・追加漢字として全角幅（2 セル幅、`NH_C3_FULLWIDTH`）を付与して幅 2 を返すように実装。
  3. `win/tty/wintty.c` の `tty_askname()` において、WIN32CON 以外の POSIX 環境で `tgetch()` から受領した生バイト列が `unicodeval_to_utf8str()` に二重エンコードされるのを防ぐため、`#ifdef WIN32CON` の条件分岐を整備。
  4. `src/role.c` において、名前が 31 バイトを超過した際の警告メッセージに、4 バイト絵文字の場合の目安文字数（約 7 文字）を併記。
* **マーカータグ**:
  - `/* NetHackJP: MultiByteToWideChar buffer expanded to 2 for surrogate pair support */`
  - `/* NetHackJP: Surrogate pairs (emoji and SMP supplementary ideographs) treated as fullwidth */`
  - `/* NetHackJP: POSIX / Linux: tgetch() returns raw bytes of incoming UTF-8 */`
* **アップストリーム追従手順**:
  上流 NetHack-5.0 で Windows コンソールの UTF-8/サロゲートペア入力および文字幅判定が改善された場合、本独自修正と競合箇所の差分を確認し、上流の実装へ追従する。

### 14. フルーツ名バッファ（`PL_FSIZ`）の 64 バイト拡張と重複時プレフィックスの日本語化

* **背景**:
  プレイヤーが設定したフルーツ名（`svp.pl_fruit`）が他の既存食料名や特定接頭辞と重複した際、NetHack は区別のために `"candied "`（8 バイト）を自動付加する。しかし日本語環境において以下の問題があった。
  1. 既存食料名「フォーチュンクッキー」（30 バイト）等に日本語プレフィックス「砂糖漬けの」（15 バイト）を付加すると合計 45 バイトとなり、従来の `PL_FSIZ`（32 バイト、有効 31 バイト）では 14 バイト不足して途中で切断されてしまう（全 33 種中 12 種の食料名で 31 バイトを超過）。
  2. `nmcpy()` による単純バイトコピーのため、日本語や絵文字が境界にあるとマルチバイトの途中バイトで切断され文字化けが発生する。
  3. 付加されるプレフィックスが英語（`"candied "`）のままハードコードされており、ゲーム内画面で「candied りんご」のように英語交じりで表示される。
* **修正内容**:
  1. `include/global.h` の `PL_FSIZ` を 32 から 64（有効長 63 バイト）に拡張。これにより「砂糖漬けのフォーチュンクッキー」（45 バイト）でも 18 バイトの余裕を持って完全に格納可能となった。
  2. `src/options.c` の `fruitadd()` において、`jp_item_name(i)` を比較対象に追加し、日本語食料名（「りんご」「卵」等）との重複も正しく検知できるように拡張。
  3. 重複時に付加するプレフィックスを、マルチバイト文字を含む場合は自然な日本語である `"砂糖漬けの"`、半角英数字のみの場合は `"candied "` に切り分けるよう実装。
  4. プレフィックス付加後に `utf8_truncate(svp.pl_fruit, PL_FSIZ - 1)` を適用し、バッファ上限を超えた場合でも必ず安全な UTF-8 文字境界で切り詰められるように保護。
* **マーカータグ**:
  - `/* NetHackJP: expand PL_FSIZ from 32 to 64 for Japanese fruit names with "砂糖漬けの" prefix */`
  - `/* NetHackJP: Also check Japanese food item names to detect collisions */`
  - `/* NetHackJP: Use natural Japanese prefix "砂糖漬けの" for multibyte fruit names */`
  - `/* NetHackJP: copy remaining text safely and truncate at UTF-8 boundary */`
* **対応ファイル**: `include/global.h`、`src/options.c`
* **アップストリーム追従手順**:
  上流 NetHack-5.0 で `PL_FSIZ` の拡張やフルーツ名重複判定の変更が入った場合、本独自拡張の差分（64 拡張と日本語プレフィックス処理）を維持しつつ追従する。

### 15. 主人公・ペット・フルーツ等の名前設定におけるバイト数上限と文字数制限の仕様

本リポジトリ（NetHackJP）における主人公名・ペット名・フルーツ名の各バッファ上限、文字種別の最大文字数、および設定経路別の仕様は以下の通りである。

#### バイト数および文字数上限一覧

| 対象 | バッファ定数 | バッファ長 | 有効バイト上限<br>(末尾 `\0` 除く) | 半角英数<br>(1B) | 全角日本語<br>(3B) | 絵文字<br>(4B) | 備考 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **主人公の名前**<br>(`svp.plname`) | `PL_NSIZ` | **32 バイト** | **31 バイト** | 最大 31 文字 | 最大 10 文字<br>(30B) | 最大 7 文字<br>(28B) | ゲーム内 "C" / `#name` コマンドでの変更不可。起動時 `askname()` プロンプトまたは `.nethackrc` で指定。超過時は警告表示。 |
| **ペットの名前**<br>(犬・猫・馬) | `PL_PSIZ` | **63 バイト** | **62 バイト** | 最大 62 文字 | 最大 20 文字<br>(60B) | 最大 15 文字<br>(60B) | "C" / `#name` コマンドでペットに命名可能。`.nethackrc`（`dogname`, `catname`, `horsename`）でも設定可能。`utf8_truncate` で保護。 |
| **フルーツの名前**<br>(通常時) | `PL_FSIZ` | **64 バイト**<br>*(32➔64拡張)* | **63 バイト** | 最大 63 文字 | 最大 21 文字<br>(63B) | 最大 15 文字<br>(60B) | `.nethackrc`（`fruit`）または `#options` で変更可能。 |
| **フルーツの名前**<br>(食料重複時・日本語) | `PL_FSIZ` | **64 バイト** | **48 バイト**<br>*(「砂糖漬けの」15Bを除く)* | 最大 48 文字 | 最大 16 文字<br>(48B) | 最大 12 文字<br>(48B) | 既存食料名（「りんご」「卵」等）と重複時に `"砂糖漬けの"` を自動付加。「フォーチュンクッキー」(30B) も途切れず完全格納。 |
| **フルーツの名前**<br>(食料重複時・英語) | `PL_FSIZ` | **64 バイト** | **55 バイト**<br>*(「candied 」8Bを除く)* | 最大 55 文字 | - | - | 英語食料名（"apple" 等）と重複時に `"candied "` を自動付加。 |

#### 設定経路別の挙動

1. **"C" コマンドおよび `#name` コマンド（`docallcmd`）**:
   - **主人公**: 自分自身（`@`）を指定しても「この怪物の名は〜で、変えられない。」と表示され、ゲーム中の名前変更は不可。
   - **ペット**: メニューから `m`（モンスター）を選びペットを指定して命名。`utf8_truncate(buf, PL_PSIZ - 1)` により最大 62 バイトの文字境界で安全に切り詰められる。WIN32CON ではサロゲートペア対応により絵文字も 2 セル幅として正しく消去・表示される。
   - **フルーツ**: "C" や `#name` コマンドには果物の種類（fruit設定）自体を変更する機能はない（個別アイテムへの銘やアイテム通称の命名は可能で、ペット同様最大 62 バイト）。果物設定自体のゲーム中変更は `#options` から行い、最大 63 バイトまで設定可能。
2. **起動時プロンプト（`askname()`）**:
   - 31 バイトを超える入力は打ち切られ、超過時は「半角英数字なら 31 文字、日本語なら約 10 文字（絵文字は約 7 文字）以内で入力してください。」と警告が表示され再入力を促される。
3. **設定ファイル（`.nethackrc`）**:
   - `OPTIONS=name:xxx` は最大 31 バイト。
   - `OPTIONS=dogname:xxx` / `catname:xxx` / `horsename:xxx` は最大 62 バイト。
   - `OPTIONS=fruit:xxx` は最大 63 バイト（重複時はプレフィックスが付加され文字境界でトリミング）。

### 16. 埃・混乱時の刻印ブレ処理（`doengrave`）における UTF-8 マルチバイト文字境界保護
* **マーカータグ**: `/* NetHackJP: UTF-8 safe engraving mix-up */`
* **対象ファイル**: `src/engrave.c`（約 1350〜1420 行目）
* **概要**:
  埃（`DUST`）への刻字時や、盲目・混乱・朦朧・幻覚状態において、一定確率（1/25等）で刻印文字を乱す処理がオリジナルのバイト走査ループ（`for (sp = de->ebuf; *sp; sp++)`）で行われていたため、UTF-8 マルチバイト文字（3バイト）の途中のバイトがランダムな ASCII 記号（`' ' + rnd(96 - 2)`）で上書きされ、バイトシーケンスが破壊されて「âP」等の文字化けを引き起こしていた。これを `utf8_charlen` に基づくマルチバイト文字単位の判定・置換に改修し、ASCII 文字は ASCII 記号へ、全角文字は全角ルビアウト候補（`jp_rubouts` からの選出、または全角「？」）に置換することで UTF-8 の文字境界と整合性を完全保護した。
* **削除手順（取り消し方法）**:
  アップストリーム側で UTF-8 マルチバイト文字に対応した刻字ブレ処理が導入された場合は、マーカータグで囲まれたブロックをアップストリームの実装に置き換える。
* **アップストリーム追従方針**:
  アップストリームのマルチバイト対応方針（Unicode コードポイント単位処理など）に沿って追従する。


### 17. WSL ビルドスクリプト（`build_wsl.sh`）への Qt6 ウィンドウポート有効化オプションの追加
* **背景**:
  WSL (Ubuntu) 環境の `build_wsl.sh` は tty / curses / X11 の3ポートをビルドしていたが、Qt6 ポート (`win/Qt/`) を UTF-8 日本語対応させるため、まず Qt6 でビルドを通す経路が必要となった。Qt ポート向けのヒント分岐 (`WANT_WIN_QT` / `WANT_WIN_QT6`) は `sys/unix/hints/linux-jp` に既存しており、スクリプト側で明示的に有効化するだけで Qt6 ポートをビルド可能。
* **修正内容**:
  1. `build_wsl.sh` に `--qt` オプションを追加。指定時のみ `WANT_WIN_QT=1 WANT_WIN_QT6=1 WANT_DEFAULT=Qt` を make に追加して Qt6 ポートをビルドする（未指定時は従来どおり tty/curses/X11 のみで既存ビルド挙動は不変）。
  2. `--qt` 指定時は事前に `pkg-config --exists Qt6Core Qt6Gui Qt6Widgets Qt6Multimedia` で Qt6 開発パッケージの存在を確認し、未導入なら `apt install` 指示とともに終了する。さらに `pkg-config --variable=libexecdir Qt6Core` で解決される `moc` の実行権も確認する。
  3. Qt6 用データアセット (`nhtiles.bmp` / `nhsplash.xpm` / `rip.xpm`) をビルド後に明示生成する（`make nhtiles.bmp nhsplash.xpm rip.xpm`）。
  4. `make install` 時も `WANT_WIN_QT=1` 系フラグを付与する必要がある（`VARDATND0` の追加は make 実行時の `ifdef` 評価で行われるため、別途 `make install` を実行すると Qt 用アセットが `playground/` にコピーされない）。この注意点をスクリプトの完了メッセージに出力する。
* **マーカータグ**:
  - `# NetHackJP: --qt option to opt-in the Qt6 window port`（Usage コメント）をはじめ、build_wsl.sh 内の NetHackJP マーカーコメント一式
* **対応ファイル**: `sys/unix/build_wsl.sh`
* **ビルド検証** (2026-09-23): Ubuntu 26.04 + Qt 6.10.2 + g++ 15.2.0 で `sh sys/unix/build_wsl.sh --qt` および同フラグ付き `make install` が成功。Qt6Widgets/Qt6Multimedia/Qt6Gui/Qt6Core のリンクを確認、`QT_QPA_PLATFORM=xcb ./playground/nethack -wQt` で起動確認済み。
* **アップストリーム追従手順**:
  上流 NetHack-5.0 に Qt ビルドを CLI から有効化する仕組みが入った場合、本オプションを取り消して追従する。linux-jp ヒント側の `WANT_WIN_QT` 分岐が上流 `linux.500` 由来であるため、ヒントファイル側の追従競合も併せて確認する。


### 18. Qt ポートの文字コード変換の UTF-8 化（`fromLatin1`/`toLatin1` の排除）
* **背景**:
  Qt ポート (`win/Qt/`) はコアとの `char *` テキスト受け渡しを Latin-1 前提（`QString::fromLatin1` / `QString::toLatin1`）で実装していたため、日本語化されたコアが渡す UTF-8 文字列が文字化けしていた。逆に入力ダイアログ (`QLineEdit`) からコアへ戻す際も `toLatin1()` で日本語が破壊され、getlin / askname / plsel / メニューSearch への日本語入力が不可能だった。
* **修正内容**:
  1. `win/Qt/` 内の `QString::fromLatin1` をすべて `QString::fromUtf8` に、`QString::toLatin1` をすべて `QString::toUtf8` に置換した（Qt 5/6 の `QString(const char *)` 暗黙変換はもともと UTF-8 であり、修正対象は明示的 Latin-1 変換箇所のみ）。
  2. 対象は `qt_bind.cpp`（`qt_putstr` / `qt_add_menu` / `qt_yn_function` / `qt_putmsghistory` + dumplog / `qt_getlin` の入力エコー）、`qt_msg.cpp`（メッセージ履歴 `GetStr`）、`qt_main.cpp`（ツールバー `doKeys`）、`qt_plsel.cpp`（キャラクター名入力）、`qt_stat.cpp`（ステータス肩書ラベル）、`qt_streq.cpp`（getlin プロンプトと入力の往復）、`qt_yndlg.cpp`（yn ダイアログの choices 解析）。
  3. `qt_getlin` のメッセージウィンドウへの入力エコーは `visctrl()` をバイト単位で適用する実装だったため、UTF-8 マルチバイト文字は ASCII のみ `visctrl()` で描画し、マルチバイト文字列は生バイトのまま通す方式に改修（playground 上の入力確定エコーが「ãã...」等に化ける問題の予防）。
* **マーカータグ**（各変更箇所に付与）:
  - `/* NetHackJP: UTF-8 (Japanese) ... text, not Latin-1 */`（QString 変換箇所）
  - `// NetHackJP: UTF-8 Japanese input - copy multibyte characters through unchanged`（qt_getlin エコー）
  - `/* NetHackJP: dumplog stores UTF-8, not Latin-1 */`（dumplogmsg 呼び出し）
* **対応ファイル**: `win/Qt/qt_bind.cpp`、`win/Qt/qt_msg.cpp`、`win/Qt/qt_main.cpp`、`win/Qt/qt_plsel.cpp`、`win/Qt/qt_stat.cpp`、`win/Qt/qt_streq.cpp`、`win/Qt/qt_yndlg.cpp`
* **アップストリーム追従手順**:
  上流 NetHack-5.0 の Qt ポート変更で `fromLatin1`/`toLatin1` 箇所に差分が入った場合、Latin-1 から UTF-8 への変換選択（fromUtf8 / toUtf8）を保持したまま移植する。日本語データ入力（`hack.h` 由来の UTF-8 テキスト）を扱う箇所では絶対に Latin-1 を復活させない。

### 19. Qt ポートのステータス「名前+称号」行およびダンジョン階層表示の日本語化
* **背景**:
  Qt6 ステータスウィンドウの名前行が `rank_of()` による英文称号（例: `テスト the Plunder`）を表示しており、ダンジョン階層表示も `describe_level()` の戻り値を誤解した常時フォールバック（`The Dungeons of Doom, level N`）になっていた。
* **修正内容** (`win/Qt/qt_stat.cpp`):
  1. 名前行はコンソール (tty) と同じ「<名前> <称号>」の並列形式（例: テスト 乱暴者）にする（初版は「<称号>の<名前>」だったがユーザー確認のフィードバックにより形式変更）。変身中は「<名前> <モンスター名>」。`pmname()` は `const char *` を返すため QString 変換を経由せず C 文字列で結合する。
  2. ダンジョン階層は `jp_dungeon_name_by_dnum(u.uz.dnum)` による「<ダンジョン名>: 階層<深さ>」（例: 運命の大迷宮: 階層1）。初版の「<ダンジョン名>:3」から、深さの意味を明示する形式へ変更。クエスト / エンドゲーム / ノックス / チュートリアルはコア `describe_level()` の日本語出力がそのまま使われる。
  3. `describe_level()` はメイン地層では常に 0 を返す仕様（botl.c のコメントどおり「ports with more room may expand this」）のため、Qt 独自の日本語フォールバックを用意した。
* **マーカータグ**: `// NetHackJP: <rank>の<name>` / `// NetHackJP: main dungeon needs JP "dungeon name:depth"`
* **対応ファイル**: `win/Qt/qt_stat.cpp`
* **アップストリーム追従手順**: X11 ポート (`win/X11/winstat.c`) にも同種の英文フォールバック（`the ...`, `, level N`）が残るが Qt スコープ外として残置。上流で称号/階層表示が変わった場合はコアの日本語表示関数を維持したまま追従する。
---

## 5. ライセンスと NetHack License 2(a) への対応方針

本リポジトリは、オリジナルの NetHack 同様、NetHack General Public License に準じます。

### NetHack License 2(a) への対応方針
* 改変したファイルには、ファイル形式に適合する方法で改変通知を記載します。
* コメント記載できないファイル（`dat/` 配下のデータファイル等）は原本を直接改変せず、日本語用の別ファイル（`*_jp`）へ分離して運用します。
* `dat/` 配下の `.lua` ファイルはコメント可能なため、改変時は変更通知コメントの対象に含めます。
* 実行時は日本語用ファイルを優先し、存在しない場合は原本へフォールバックする方針を採ります。
* 原本データは保持し、変更履歴と対応関係を追跡可能な形で管理します。

* ライセンス本文: [dat/license](dat/license)
* サブモジュール等の第三者コンポーネント: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES)

---

## 6. リポジトリ構成とマージ運用

本リポジトリは Windows ポート用の日本語化リポジトリであり、本家 NetHack（アップストリーム）の変更を取り込みながら開発を進めます。

```mermaid
graph TD
    UpstreamBase[NetHack/NetHack<br>upstream/NetHack-5.0] -->|同期| UpstreamBaseBranch[upstream-base]
    UpstreamBaseBranch -->|マージ| Main[main]
```

### リモート設定
マージ作業を行う前に、以下のリモート設定を確認してください。
- **`origin`**: `https://github.com/satokiyon/NetHackJP.git` (自身のWindows日本語化リポジトリ)
- **`upstream`**: `https://github.com/NetHack/NetHack.git` (本家NetHackオリジナルリポジトリ)

設定されていない場合は、以下のコマンドで追加します。
```bash
git remote add upstream https://github.com/NetHack/NetHack.git
git fetch --all
```

### マージの手順（定期実行）

本家 NetHack 側の更新を日本語版メイン (`main`) に取り込み、Windows版でのビルド・動作を確認します。

1. **同期用クリーンブランチ（`upstream-base`）を最新にする**
   ```bash
   git switch upstream-base
   git pull upstream NetHack-5.0
   ```
2. **`main` ブランチにマージする**
   ```bash
   git switch main
   git merge --no-commit --no-ff upstream-base
   ```
3. **競合（コンフリクト）が発生した場合**
   - 競合を手動で解決します。
   - `sys/windows/vs/build_one.bat` を実行し、コンパイルエラーやリンクエラーがないことを確認します。
   - 解消後、変更をインデックスに追加してコミットします。
     ```bash
     git add .
     git commit -m "Merge upstream changes into main"
     ```
4. **プッシュ**
   ```bash
   git push origin main
   ```

---

## 7. リリース手順

### リリース用バイナリのビルド
`sys/windows/vs/build_one.bat` を用いて、`Release|x64` または `Release|Win32` で最終パッケージ用バイナリをビルドします。

### タグの作成とプッシュ
リリース用コミットが `main` ブランチにプッシュされた後、リリース用タグを作成してプッシュします。
- タグ命名規則: `NetHackJP-[Version]-[Date]` (例: `NetHackJP-5.0.0-20260629`)
```bash
git tag NetHackJP-5.0.0-20260629
git push origin NetHackJP-5.0.0-20260629
```

### GitHub Release の作成
GitHub上の Releases ページから新規リリースを作成し、ビルドされた Windows 用バイナリをアタッチして公開します。

---

## 8. X11 GUI ポートにおける XPM タイル描画および生成ツールの修復（2026年9月完了）

WSL (Linux) 環境上の NetHack X11 ポート (`windowtype:X11`) において、タイル画像が未探索マスや一部グラフィックで崩れる問題、および生成される `x11tiles` 画像が途中で読み込み中断を起こす問題についての技術注釈です。

* **タイルファイル指定および解像度の設定ファイル対応と自動判定フォールバック (`win/X11/winmap.c`, `win/X11/winX.c`, `include/winX.h`, `win/X11/NetHack.ad`)**:
  - 従来はファイル名が `x11tiles` 固定で解像度は画像からの自動計算のみだったが、Windows版と同様に `.nethackrc` の `OPTIONS=tile_file:...,tile_width:W,tile_height:H` および X11 リソース（`NetHack.tile_file`, `NetHack.tile_width` / `NetHack.tile_height`）での柔軟なファイル指定および 1 タイルのピクセルサイズ明示指定に対応。
  - 要求サイズが指定されている場合は、画像の幅・高さの割り切れチェックおよび総タイル数チェック（`total_tiles_used`）を行い、不一致時は警告を出してテキストモードにフォールバック。
  - 省略（未指定）時は、既定のファイル名（`x11tiles`）および従来の画像幅からの自動判定（`tile_width = image_width / TILES_PER_ROW`, `tile_height = tile_width`）をフォールバックとして継続サポート。
* **`tile2x11` における XPM 色記号文字コード破壊の修正 (`win/X11/tile2x11.c`)**:
  - 単純な `(char)(i + '0')` による文字コード加算では、色数増加時に `"` (ダブルクォーテーション) 等の制御文字が混入して libXpm で構文エラーを起こし、画像ロードが途中で打ち切られていた。安全な ASCII キャラクターマップ (`xpm_chars[]`) を導入してエスケープ破綻を保護した。
* **`convert_tiles` ポインタ移動計算の「絶対座標計算方式」への変更 (`win/X11/tile2x11.c`)**:
  - 相対ポインタ加算のバグにより1行（40個）終わるごとに画像が対角線状に横滑りしていた計算式を、`total`（タイル番号）からの絶対座標計算 (`tb = tile_bytes + (total / header.per_row)...`) へ修正し、ポインタズレを物理的に排除した。
* **`objects.txt` 1行目のコメント記号補正 (`win/share/objects.txt`)**:
  - `win/share/tiletext.c` のパーサーが `#` で始まらないヘッダー行 `NOTICE:` をカラー定義行と誤認して `objects.txt` のパースに失敗 (`0 tiles`) していた問題を、行頭を `# NOTICE:` にコメントアウトすることで修復した。
