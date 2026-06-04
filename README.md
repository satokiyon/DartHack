<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-03. -->
# NetHack 5.0 日本語化非公式プロジェクト

NetHackJPは、ローグライクゲームの金字塔 **NetHack 5.0** を日本語で快適にプレイできるようにすることを目的とした非公式プロジェクトです。(対象OSはWindowsのみ)

<img width="1318" height="826" alt="2026-06-02_05h29_10" src="https://github.com/user-attachments/assets/69fc8182-c260-4dbc-9127-7103506f8aad" />

<img width="1265" height="607" alt="2026-06-04_16h36_13" src="https://github.com/user-attachments/assets/a26364a0-a940-4c1d-b586-d841562e5533" />

<img width="1058" height="607" alt="2026-06-02_05h25_26" src="https://github.com/user-attachments/assets/ab664586-d185-4a1c-b23e-6807ec676d9a" />

---

## 🎮 プレイヤー向け情報（ゲームの始め方）

まずは日本語版 NetHack をダウンロードして遊んでみましょう！

### 1. 導入手順

ゲームをプレイするには、[GitHubのReleasesページ](https://github.com/satokiyon/NetHackJP/releases) からビルド済みのWindows用実行ファイル（`NetHack.exe` / `NetHackW.exe`）を含むZIPファイルをダウンロードしてください。

※本プロジェクトは開発中のため、最新の開発版をプレイしたい場合はご自身でビルドする必要があります（ビルド方法は後述の「開発者向け情報」を参照してください）。

#### NetHackJP起動手順

※参考 : [NetHack 5.0.0 Windows Port](https://nethack.org/v500/ports/download-win.html)

1. ダウンロードしたZIPファイルをすべて展開してください。
   （※ZIPファイルの中にファイルがある状態で実行ファイルを起動しないでください）

2. 必要であれば、ご自身の環境に合わせてNetHackの設定ファイルを編集してください。
   NetHackに関連するフォルダの場所と名前は、次のコマンドで確認できます。
   ```cmd
   nethack.exe --showpath
   ```
   設定は `.nethackrc` を編集してください。一度NetHackを起動すると、`nethackrc.template` からコピーされて自動作成されます。
   その後、作成された `%USERPROFILE%\NetHackJP\.nethackrc` を編集してください。

3. 次のどちらかのファイルを起動してください。
   * **`NetHack.exe`** （コンソール版）
   * **`NetHackW.exe`** （GUI版）


- `.nethackrc` に設定できる各種オプションやゲーム内容に関する説明は、`Guidebook_JP.txt` を参照してください。

---

### 2. 日本語入力と対応機能
Windows版では、ゲーム内での日本語入力・表示に対応しています。以下の項目で日本語と英語のどちらも使用可能です。
* 主人公キャラの名前
* アイテムやモンスターへの命名（名前付け）
* 「願い（wishing）」の指定
* 「虐殺（extinction）」の指定
* データベースの検索

---

### 3. タイルセット（画像）で遊ぶ
NetHack はテキスト（ASCII文字）だけでなく、美しいグラフィック（タイル）でプレイすることも可能です。

#### 設定手順
1. 好みのタイルセットをダウンロードし、BMP形式に変換します。
   * 参考リンク: [NetHackWiki Tileset 一覧](https://nethackwiki.com/wiki/Tileset)
2. `.nethackrc` を開き、以下の設定を追記または修正します。
   ```ini
   OPTIONS=map_mode:tiles
   OPTIONS=tile_file:nevanda_nethack_32x32.bmp
   OPTIONS=tile_width:32
   OPTIONS=tile_height:32
   ```
   * `tile_file`: 使用する BMP ファイル名（または絶対パス）を指定します。
   * `tile_width` / `tile_height`: タイルのピクセルサイズ（例: 32x32 なら `32`）を指定します。

#### タイル画像の配置場所
* 相対パスで指定する場合、実行ファイル（`NetHack.exe` / `NetHackW.exe`）と同じフォルダに置くのが確実です。
* サブフォルダに置く場合は `OPTIONS=tile_file:tiles/your_tiles.bmp` のように相対パスで指定できます。

---

## 💖 プロジェクトへの支援（寄付）について

本プロジェクトは非公式のボランティアによって開発・運営されています。もしこの日本語化プロジェクトを気に入っていただき、今後の継続的な開発やメンテナンスを応援していただける場合は、温かいご支援（寄付）をいただけますと幸いです。

[![Sponsor satokiyon](https://img.shields.io/badge/Sponsor-satokiyon-EA4AAA?style=flat-square&logo=github-sponsors&logoColor=white)](https://github.com/sponsors/satokiyon)

（※具体的な寄付方法やリンクなどは、上記のボタンや、本リポジトリの「Sponsor」ボタン等をご確認ください）

---

## 🛠️ 開発者向け情報

プロジェクトへの貢献や、自分でビルドを行いたい方向けの情報です。

### 1. ビルド方法
Windows でのビルド方法の詳細は、以下のドキュメントを参照してください。
* [ビルドガイド (sys/windows/vs/build-vs.txt)](sys/windows/vs/build-vs.txt)


### 2. オブジェクト名ローカライズ方針（重要）
表示用テキスト以外にゲームロジック上でキー値として使用されている英単語は、直接日本語に置換せず、日本語の表示用リストを別途用意してヘルパー関数を利用して英単語から日本語へ変換して表示する仕組みをとっています。これによって、もともとのキー値を参照するゲームロジックが破壊されるのを防ぎます。

例えば `include/objects.h` を直接日本語化すると、Lua special floor の `des.object({ id = "leather armor" })` のような英語 ID ルックアップが壊れるため、内部IDは英語のまま維持し、表示層だけを日本語化します。

* **内部IDは英語維持**: `include/objects.h` は upstream 英語のまま保持し、Lua・wish・検索系の互換性を確保する。
* **表示だけ日本語化**: `src/obj_jp.c` に日本語名テーブル (`obj_jp_names[]`) と未識別外観テーブル (`obj_jp_descrs[]`) を持たせる。
* **表示層で切り替え**: `src/objnam.c` の表示処理は `jp_item_name()` / `jp_item_descr()` を使う。
* **シャッフル対応**: 未識別外観は `oc_descr_idx` が実行時に変わるため、`jp_item_descr()` は `objects[otyp].oc_descr_idx` を経由する。
* **Windows ビルドへの組み込み**: `sys/windows/vs/NetHack/NetHack.vcxproj` と `sys/windows/vs/NetHackW/NetHackW.vcxproj` の両方に `src/obj_jp.c` を含める。

この設計により、英語ID依存の内部処理を壊さずに日本語表示を実現できます。チュートリアルの Lua `Unknown object id` 問題もこの方式で解消しました。

---

## 📝 翻訳方針と補足情報

### 1. プロジェクトの目標と作業方針
1. **NetHack 5.0 の画面に表示されるメッセージやテキストを日本語に翻訳する**
   * メッセージ、アイテム名、モンスター名などの日本語翻訳および表示対応を行います。
2. **Windows版が日本語でプレイできる状態にする**
3. **現在の作業方針**
   * 画面表示テキストの日本語化を優先し、内部仕様やID互換性を壊さない方針で進めます。
   * 日本語の文字コードは UTF-8 を前提とし、Windows 版の表示品質を重視します。
   * 変更は原則として最小差分で行い、表示文・訳文に関係ないロジック変更は避けます。
   * `dat/` にあるデータファイルは、日本語用に別ファイルを用意してそちらを使用します。

### 2. 翻訳時のポイント
* `src/pline.c` のメッセージ表示関数 (`You`, `Your`, `You_feel`, `You_hear`, `You_see`, `You_cant`, `There`, `pline_The`, `verbalize`, `custompline`) は、関数単体ではなく呼び出し側文字列と結合した最終表示文で自然さを確認します。
* `You_feel` / `You_hear` / `You_see` は接頭辞を自動付与するため、呼び出し側リテラルで主語重複や助詞衝突を起こさないようにします。
* `%s` の直後に助詞（`は/を/に/へ/が/の/と/から`）が来る文では、`mon_nam()/Monnam()` より `l_monnam()` の利用を優先します。
* `%s%sから` のような複合テンプレートは機械置換せず、文脈ごとに語順を手動で整えます。
* 英語冠詞を返す補助（`just_an()` など）の結果は、日本語文へ直接連結しません。
* `%s`, `%d`, `%ld`, `%c` などのフォーマット指定子は、個数・順序・型を変更しません。
* 原則として文字列リテラルのみを変更し、ゲームロジックや条件分岐の意味は変えません。
* `隠し%s` のようなテンプレートは、展開後の最終語形 (`隠し扉`, `隠し通路`) が自然か確認します。

### 3. リポジトリの構成ファイル
* `README`: オリジナルの英語版 README
* `README.JP`: 英語版 README の日本語訳
* `README.md`: このファイル（プロジェクトの概要）


---

## ⚖️ ライセンス

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
NetHack 5.0 の詳細については、[README](README) または [README.JP](README.JP) を参照してください。

---

# リポジトリ運用メモ

## 1. リポジトリ構成と運用
NetHack 本家（アップストリーム）の修正を継続的に反映するため、以下の2つのブランチで運用しています。
* **`main`**: 日本語化プロジェクトのメイン開発ブランチ。
* **`upstream-base`**: 本家 (`NetHack/NetHack-5.0`) のコードをそのまま保持する同期用ブランチ（日本語版独自の変更は加えません）。

### 初期設定（初回のみ）
本家のリポジトリを `upstream` リモートとして登録し、同期用ブランチを作成します。
```powershell
# 1. 本家リポジトリを upstream として登録
git remote add upstream https://github.com/NetHack/NetHack.git

# 2. 最新情報を取得
git fetch upstream

# 3. 本家の NetHack-5.0 ブランチをベースにしたブランチを作成
git checkout -b upstream-base upstream/NetHack-5.0
```

### 定期的な同期（2回目以降）
本家の更新を `main` ブランチに取り込む手順です。
```powershell
# 1. upstream-base を最新にする
git switch upstream-base
git pull

# 2. main に統合する
git switch main
git merge --no-commit --no-ff upstream-base

# 3. コンフリクトが発生した場合の処理（競合解決後）
# 競合箇所を手動修正し、全解決後に以下を実行
# git add は個別に実行する（例: git add dat/history）
git add <解決したファイル名>
git commit -m "アップストリームの変更をマージ"

# 4. 確認とプッシュ
# ビルドを行い、動作確認後に実行
git push origin main

# （補足）マージを中断して作業前の状態に戻す場合
git merge --abort
```
