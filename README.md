<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-31. -->
# NetHack 5.0 を勝手に日本語に翻訳する非公式プロジェクト

NetHackJPは、ダンジョン探索ゲーム **NetHack 5.0** を日本語で遊べるようにすることを目的とした**非公式**プロジェクトです。

## プロジェクトの目標

1.  **NetHack 5.0 の画面に表示されるメッセージやテキストを日本語に翻訳する**
    *   メッセージ、アイテム名、モンスター名などの日本語翻訳および表示対応を行います。
2.  **Windows版が日本語でプレイできる状態にする**
    *   Windows版にて日本語が表示され、プレイできる状態を目指します。

## 現在の作業方針

*   画面表示テキストの日本語化を優先し、内部仕様やID互換性を壊さない方針で進めます。
*   日本語の文字コードは UTF-8 を前提とし、Windows 版の表示品質を重視します。
*   変更は原則として最小差分で行い、表示文・訳文に関係ないロジック変更は避けます。
*   調査のために一時的なトレースやデバッグコードを入れる場合は、原因確認後に必ず削除します。
*   調査用の一時生成物（ログや検証データ）はコミット対象外にします。
*   公開リポジトリ運用を前提に、ライセンス・第三者通知・セキュリティ運用情報を維持します。
*   変更通知コメント（`Modified by ...` など）は、各ファイル形式で有効なコメント構文のみを使います。
*   特に XML は `<?xml ...?>` を先頭に置き、通知コメントは `<!-- ... -->` を XML 宣言の直後に置きます。
*   JSON のようにコメント非対応の形式には通知コメントを入れず、README やコミット履歴で記録します。
*   NetHack License 2(a) 対応として、改変ファイルには原則として変更通知を記載します。
*   ただしコメント記載できないファイル（`dat/` 配下のデータファイル等）は直接改変せず、日本語用の別ファイル（`*_jp` など）を作成して参照します。

## 翻訳時のポイント

*   `src/pline.c` のメッセージ表示関数 (`You`, `Your`, `You_feel`, `You_hear`, `You_see`, `You_cant`, `There`, `pline_The`, `verbalize`, `custompline`) は、関数単体ではなく呼び出し側文字列と結合した最終表示文で自然さを確認します。
*   `You_feel` / `You_hear` / `You_see` は接頭辞を自動付与するため、呼び出し側リテラルで主語重複や助詞衝突を起こさないようにします。
*   `%s` の直後に助詞（`は/を/に/へ/が/の/と/から`）が来る文では、`mon_nam()/Monnam()` より `l_monnam()` の利用を優先します。
*   `%s%sから` のような複合テンプレートは機械置換せず、文脈ごとに語順を手動で整えます。
*   英語冠詞を返す補助（`just_an()` など）の結果は、日本語文へ直接連結しません。
*   `%s`, `%d`, `%ld`, `%c` などのフォーマット指定子は、個数・順序・型を変更しません。
*   原則として文字列リテラルのみを変更し、ゲームロジックや条件分岐の意味は変えません。
*   `隠し%s` のようなテンプレートは、展開後の最終語形 (`隠し扉`, `隠し通路`) が自然か確認します。
*   置換後は最低限 `hack.c`, `apply.c`, `trap.c`, `uhitm.c`, `mhitu.c`, `steed.c` を重点確認します。

### オブジェクト名ローカライズ方針

`include/objects.h` を直接日本語化すると、Lua special floor の `des.object({ id = "leather armor" })` のような英語 ID ルックアップが壊れるため、内部IDは英語のまま維持し、表示層だけを日本語化します。

- **内部IDは英語維持**: `include/objects.h` は upstream 英語のまま保持し、Lua・wish・検索系の互換性を確保する。
- **表示だけ日本語化**: `src/obj_jp.c` に日本語名テーブル (`obj_jp_names[]`) と未識別外観テーブル (`obj_jp_descrs[]`) を持たせる。
- **表示層で切り替え**: `src/objnam.c` の表示処理は `jp_item_name()` / `jp_item_descr()` を使う。
- **シャッフル対応**: 未識別外観は `oc_descr_idx` が実行時に変わるため、`jp_item_descr()` は `objects[otyp].oc_descr_idx` を経由する。
- **Windows ビルドへの組み込み**: `sys/windows/vs/NetHack/NetHack.vcxproj` と `sys/windows/vs/NetHackW/NetHackW.vcxproj` の両方に `src/obj_jp.c` を含める。

この設計により、英語ID依存の内部処理を壊さずに日本語表示を実現できます。チュートリアルの Lua `Unknown object id` 問題もこの方式で解消しました。

## リポジトリ構成と運用

NetHack 本家（アップストリーム）の修正を継続的に反映するため、以下の構成で運用します。

### ブランチ構成
- **`main`**: 日本語化プロジェクトのメインブランチ。
- **`upstream-base`**: 本家 (`NetHack/NetHack-5.0`) のコードをそのまま保持する同期用ブランチ。日本語版独自の変更は加えません。

### 初期設定（初回のみ）
本家のリポジトリを `upstream` リモートとして登録し、同期用ブランチを作成します。
```bash
git remote add upstream https://github.com/NetHack/NetHack.git
git fetch upstream
git checkout -b upstream-base upstream/NetHack-5.0
```

### 同期手順

#### 1. 初期設定（初回のみ）
本家のリポジトリを登録し、同期用のベースブランチを作成します。
```powershell
# 1. 本家リポジトリを upstream として登録
git remote add upstream https://github.com/NetHack/NetHack.git

# 2. 最新情報を取得
git fetch upstream

# 3. 本家の NetHack-5.0 ブランチをベースにしたブランチを作成
git checkout -b upstream-base upstream/NetHack-5.0
```

#### 2. 定期的な同期（2回目以降）
本家の更新を `main` ブランチに取り込むコマンド手順です。
```powershell
# 1. upstream-base を最新にする
git switch upstream-base
git pull

# 2. main に統合する
git switch main
git merge --no-commit --no-ff upstream-base

# 3. コンフリクトが発生した場合の処理（VS Code等で解決後）
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

## 構成

*   `README`: オリジナルの英語版 README
*   `README.JP`: 英語版 README の日本語訳
*   `README.md`: このファイル（プロジェクトの概要）

## ライセンス

本リポジトリは、オリジナルの NetHack 同様、NetHack General Public License に準じます。

### NetHack License 2(a) への対応方針

- 改変したファイルには、ファイル形式に適合する方法で改変通知を記載します。
- コメント記載できないファイル（`dat/` 配下のデータファイル等）は原本を直接改変せず、日本語用の別ファイル（`*_jp`）へ分離して運用します。
- 実行時は日本語用ファイルを優先し、存在しない場合は原本へフォールバックする方針を採ります。
- 原本データは保持し、変更履歴と対応関係を追跡可能な形で管理します。

- ライセンス本文: [dat/license](dat/license)
- サブモジュール等の第三者コンポーネント: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES)

---
NetHack 5.0 の詳細については、[README](README) または [README.JP](README.JP) を参照してください。


# タイルセット
次のサイトのリンク先から好みのタイルセットをダウンロードし、BMPファイルに変換して使用可能
- https://nethackwiki.com/wiki/Tileset

タイルセットを使うときは、`.nethackrc` に以下を設定します。

```ini
OPTIONS=map_mode:tiles
OPTIONS=tile_file:nevanda_nethack_32x32.bmp
OPTIONS=tile_width:32
OPTIONS=tile_height:32
```

- `tile_file` には BMP ファイル名（または絶対パス）を指定します。
- `tile_width` / `tile_height` は、1タイルのピクセルサイズに合わせてください（例: 32x32 なら `32`）。

## .nethackrc の配置場所

- このプロジェクトでは、リポジトリ直下の `.nethackrc` を使用します。
- 配置場所: `NetHackJP/.nethackrc`
- 必要に応じてこのファイルを編集して、`tile_file` などの設定を変更してください。

起動方法によって、実際に読み込まれる設定ファイルが異なる場合があります。

- このリポジトリの想定手順で起動する場合は、`NetHackJP/.nethackrc` を編集対象として使用します。
- `--nethackrc=<パス>` で起動した場合は、指定したファイルが優先されます（例: `--nethackrc=.nethackrc`）。
- 明示指定なしで通常起動した場合は、環境によって `%USERPROFILE%\nethack\.nethackrc` 側が使われることがあります。

期待した設定が反映されない場合は、起動引数で `--nethackrc` を明示指定してください。

## タイル画像の配置場所

- 相対パスで指定する場合は、実行ファイル (`NetHack.exe` / `NetHackW.exe`) と同じフォルダに置くのが確実です。
- このリポジトリの Debug ビルドでは、通常 `binary/Debug/x64/` に配置します。
- 別の場所に置く場合は、`OPTIONS=tile_file:tiles/your_tiles.bmp` のように相対パスで指定できます。
- 絶対パスが必要な環境では、実行環境に合わせたパス表記で指定してください。


