# NetHackJP-Android マージ・運用ガイド

本リポジトリ（`NetHackJP-Android`）は、日本語化共通リソースや Windows 版の更新を行う `NetHackJP` リポジトリと、Android 移植元である `JodiJodington/NetHack-Android` リポジトリの変更を統合して開発を進めるためのリポジトリです。

安全かつコンフリクトを最小限に抑えるためのマージ手順を以下に示します。

---

## 1. リモート設定の確認
本リポジトリには、以下の3つのリモートが設定されていることを前提とします。

- **`origin`**: `https://github.com/satokiyon/NetHackJP-Android.git` (本リポジトリ)
- **`nethack-jp`**: `https://github.com/satokiyon/NetHackJP.git` (日本語化・Windows版)
- **`jodi-android`**: `https://github.com/JodiJodington/NetHack-Android.git` (Android移植元)

設定されていない場合は、以下のコマンドで追加してください。
```bash
git remote add nethack-jp https://github.com/satokiyon/NetHackJP.git
git remote add jodi-android https://github.com/JodiJodington/NetHack-Android.git
```

---

## 2. マージ手順

競合が発生した場合の切り分けを容易にするため、**`nethack-jp` からのマージと `jodi-android` からのマージは必ず別々のタイミング（コミット）で行ってください**。

### A. 日本語化（NetHackJP）の更新を取り込む場合
`NetHackJP` 側で NetHack 本家の更新や、日本語翻訳データの修正が行われた場合、それを取り込みます。

1. 最新情報をフェッチします。
   ```bash
   git fetch nethack-jp
   ```
2. `main` ブランチにいることを確認し、マージします。
   ```bash
   git checkout main
   git merge nethack-jp/main -m "Merge updates from NetHackJP (main)"
   ```
3. 競合（コンフリクト）が発生した場合は解決し、コミットします。

### B. Android移植元（JodiJodington/NetHack-Android）の更新を取り込む場合
Android 移植元のバグ修正や機能追加を取り込みます。

1. 最新情報をフェッチします。
   ```bash
   git fetch jodi-android
   ```
2. `main` ブランチにいることを確認し、マージします。
   ```bash
   git checkout main
   git merge jodi-android/master -m "Merge updates from JodiJodington/NetHack-Android (master)"
   ```
3. 競合（コンフリクト）が発生した場合は解決し、コミットします。

---

## 3. ビルドと動作確認
変更を取り込んだ後は、必ず以下の手順でビルド確認を行ってください。

1. **Android ビルドスクリプトの実行**
   PowerShell から自動ビルドスクリプトを実行します（WSL経由でCライブラリをコンパイルし、GradleでAPKを生成します）。
   ```powershell
   & .\sys\android\build_android.ps1
   ```
   > [!IMPORTANT]
   > Android SDKパスのエラーが出る場合は、以下のように `ANDROID_HOME` 環境変数を明示的に渡して実行してください。
   > ```powershell
   > $env:ANDROID_HOME="C:\Users\satok\AppData\Local\Android\Sdk"; .\sys\android\build_android.ps1
   > ```

2. **データファイルアセットの変更・追加時の注意**
   データファイル（`data`, `help` など）を変更した場合は、端末へのアセット上書きコピーを強制するため、必ず `sys/android/app/assets/ver` 内のバージョン値（整数値）をインクリメントしてください。

3. **デバッグログ of クリーンアップ**
   マージやデバッグの目的で一時的に埋め込んだログ出力コード（`__android_log_print` など）は、検証完了後にすべて削除してクリーンな状態に復元した上でコミットしてください。
