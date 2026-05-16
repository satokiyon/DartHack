# NetHack 5.0 日本語版プロジェクト

このリポジトリは、ダンジョン探索ゲーム **NetHack 5.0** を日本語で遊べるようにすることを目的としたプロジェクトです。

## プロジェクトの目標

1.  **NetHack 5.0 の日本語化**
    *   メッセージ、アイテム名、モンスター名などの日本語翻訳および表示対応を行います。
2.  **Windows版が日本語でプレイできる状態にする（当面の目標）**
    *   まずは Windows版にて日本語が表示され、プレイできる状態を目指します。

## 現在の作業方針

*   AIを使用して画面表示される英文を日本語に翻訳します。
*   日本語はUTF-8でエンコードします。
*   コンソール版もUTF-8を処理して画面表示するように修正します。
*   原因調査のためにデバッグ用コードやトレースやログを追加することがありますが、確認が終わったら削除し本番コードには残しません。コミットの履歴に残るのは構いません。
*   調査用の一時生成物(ログやデバッグ用データ)はコミット対象外です。

## リポジトリ構成と運用

NetHack 本家（アップストリーム）の修正を継続的に反映するため、以下の構成で運用します。

### ブランチ構成
- **`master`**: 日本語化プロジェクトのメインブランチ。
- **`upstream-base`**: 本家 (`NetHack/NetHack`) のコードをそのまま保持する同期用ブランチ。日本語版独自の変更は加えません。

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
git pull upstream NetHack-5.0

# 2. main に統合する
git switch main
git merge upstream-base

# 3. コンフリクトが発生した場合の処理（VS Code等で解決後）
# 競合箇所を手動修正し、全解決後に以下を実行
# git add は個別に実行する（例: git add dat/history）
git add <解決したファイル名>
git commit -m "Merge branch 'upstream-base' into main"

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

オリジナルの NetHack 同様、[NetHack General Public License](dat/license) に準じます。

---
NetHack 5.0 の詳細については、[README](README) または [README.JP](README.JP) を参照してください。
