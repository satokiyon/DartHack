<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-05. -->
# NetHackJP 開発者向け情報

本ドキュメントは、NetHackJP プロジェクトのビルド、翻訳方針、およびリポジトリの運用に関する開発者向けの情報をまとめたものです。

---

## 🛠️ ビルドと開発環境

### 1. ビルド方法
Windows でのビルド方法の詳細は、以下のドキュメントを参照してください。
* [ビルドガイド (sys/windows/vs/build-vs.txt)](sys/windows/vs/build-vs.txt)

### 2. デバッグとLuaスクリプト検証
デバッグモード中に `#wizloadlua` を使用してLuaスクリプトからゲーム状態の取得やデバッグ操作を行う方法については、以下のドキュメントを参照してください。
* [Luaデバッグ・検証ガイド (docs/wizloadlua_guide.md)](docs/wizloadlua_guide.md)

### 3. オブジェクト名ローカライズ方針（重要）
表示用テキスト以外にゲームロジック上でキー値として使用されている英単語は、直接日本語に置換せず、日本語の表示用リストを別途用意してヘルパー関数を利用して英単語から日本語へ変換して表示する仕組みをとっています。これによって、もともとのキー値を参照するゲームロジックが破壊されるのを防ぎます。

例えば `include/objects.h` を直接日本語化すると、Lua special floor の `des.object({ id = "leather armor" })` のような英語 ID ルックアップが壊れるため、内部IDは英語のまま維持し、表示層だけを日本語化します。

* **内部IDは英語維持**: `include/objects.h` は upstream 英語のまま保持し、Lua・wish・検索系の互換性を確保する。
* **表示だけ日本語化**: `src/obj_jp.c` に日本語名テーブル (`obj_jp_names[]`) と未識別外観テーブル (`obj_jp_descrs[]`) を持たせる。
* **表示層で切り替え**: `src/objnam.c` の表示処理は `jp_item_name()` / `jp_item_descr()` を使う。
* **シャッフル対応**: 未識別外観は `oc_descr_idx` が実行時に変わるため、`jp_item_descr()` は `objects[otyp].oc_descr_idx` を経由する。
* **Windows ビルドへの組み込み**: `sys/windows/vs/NetHack/NetHack.vcxproj` と `sys/windows/vs/NetHackW/NetHackW.vcxproj` の両方に `src/obj_jp.c` を含める。
* **アーティファクトの日本語化と願い・検索対応**: 
  - `src/obj_jp.c` に表示用の標準日本語名テーブル (`artilist_jp_names[]`) と、入力受付用のJNetHack表記の別名テーブル (`artilist_jnethack_names[]`) を用意。
  - `src/objnam.c` の `xname()` や `bare_artifactname()` では、表示時に標準日本語名に置き換える。
  - `src/artifact.c` の `artifact_name()` で入力された日本語名（表記揺れや別名を含む）を英語キー名にマッピングして「願い」に対応する。
  - `src/jp_data_lookup.c` において、データ検索用にアーティファクトの日本語名（およびひらがな表記）を英語キーに紐づける alias 設定を追加。

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
* `README.md`: プロジェクトの概要 (プレイヤー向け情報)

---

## ⚖️ ライセンスと NetHack License 2(a) への対応方針

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

## 🔄 リポジトリ運用メモ

### 1. ブランチ構成と運用
NetHack 本家（アップストリーム）の修正を継続的に反映するため、以下の2つのブランチで運用しています。
* **`main`**: 日本語化プロジェクトのメイン開発ブランチ。
* **`upstream-base`**: 本家 (`NetHack/NetHack-5.0`) のコードをそのまま保持する同期用ブランチ（日本語版独自の変更は加えません）。

### 2. 初期設定（初回のみ）
本家のリポジトリを `upstream` リモートとして登録し、同期用ブランチを作成します。
```powershell
# 1. 本家リポジトリを upstream として登録
git remote add upstream https://github.com/NetHack/NetHack.git

# 2. 最新情報を取得
git fetch upstream

# 3. 本家の NetHack-5.0 ブランチをベースにしたブランチを作成
git checkout -b upstream-base upstream/NetHack-5.0
```

### 3. 定期的な同期（2回目以降）
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
