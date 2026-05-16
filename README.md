# NetHack 5.0 日本語版プロジェクト

このリポジトリは、ダンジョン探索ゲーム **NetHack 5.0** を日本語で遊べるようにすることを目的としたプロジェクトです。

## プロジェクトの目標

1.  **NetHack 5.0 の日本語化**
    *   メッセージ、アイテム名、モンスター名などの日本語翻訳および表示対応を行います。
2.  **Windows版 GUI (Qt/Win32) への対応（当面の目標）**
    *   まずは Windows 環境の GUI で日本語が正しく表示され、プレイできる状態を目指します。

## 現在の作業方針

*   Windows のコンソール表示では、日本語の欠落や崩れを防ぐための表示修正を進めています。
*   原因調査のために追加したトレースやログは、確認が終わったら削除し、本番コードには残しません。
*   調査用の一時生成物（`*trace*.tsv`, `build*.log`, `output.txt` など）はコミット対象外です。

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
本家の更新を `master` ブランチに取り込む手順です。
1. **本家の最新を取得**:
   ```bash
   git checkout upstream-base
   git pull upstream NetHack-5.0
   ```
2. **メインブランチに統合**:
   ```bash
   git checkout master
   git merge upstream-base
   ```
3. **競合の解決とビルド確認**:
   コンフリクトが発生した場合は慎重に解消し、必ずビルドと動作確認を行ってください。

## 構成

*   `README`: オリジナルの英語版 README
*   `README.JP`: 英語版 README の日本語訳
*   `README.md`: このファイル（プロジェクトの概要）

## ライセンス

オリジナルの NetHack 同様、[NetHack General Public License](dat/license) に準じます。

---
NetHack 5.0 の詳細については、[README](README) または [README.JP](README.JP) を参照してください。
