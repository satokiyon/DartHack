# Copilot Instructions for NetHackJP (Technical & Operational)

このファイルは、NetHackJP プロジェクトにおける技術的な運用、ビルド手順、および開発フローに関する指示をまとめたものです。翻訳に関する具体的なガイドラインは `docs/translation-instructions-ja.md` を参照してください。

## 1. プロジェクト構成と環境

- **OS**: Windows (win32)
- **シェル**: PowerShell / VS Developer Shell 推奨
- **ツール**:
  - 文字列検索: `ag` コマンドを使用（`grep` は避ける）
  - スクリプト: `PowerShell` または `Python` を使用（`bash` は避ける）

## 2. ビルド手順 (Windows / VS)

### 推奨: VS Developer Shell 経由
```powershell
Import-Module 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
Enter-VsDevShell -VsInstallPath 'C:\Program Files\Microsoft Visual Studio\18\Community' -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
Set-Location 'C:\Users\satok\NetHackJP'
msbuild sys\windows\vs\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Debug /p:Platform=x64 /m /nologo /verbosity:minimal
```

### 最低確認事項
- Exit Code が `0` であること。
- `binary\Debug\x64\NetHack.exe` と `NetHackW.exe` が生成されること。
- `NetHackW.exe` 起動中はリンク失敗（LNK1168）するため、ビルド前に終了させること。

## 3. アップストリーム同期 (Git)

本家（https://github.com/NetHack/NetHack）の更新は `upstream-base` ブランチを経由して取り込む。

### 同期の手順
```powershell
git switch upstream-base
git pull upstream NetHack-5.0
git switch main
git merge upstream-base
# コンフリクト解決後
git add <解決したファイル>
git commit -m "Merge branch 'upstream-base' into main"
```

## 4. プロジェクト管理とコミット

- **進捗管理**: 計画と進捗を `/memories/repo/translation-notes.md` に記録する。
- **コミットルール**:
  - ユーザーの明示的な依頼がある時のみ行う。
  - `git status --short` で関係ない変更が含まれていないか確認する。
  - コミットメッセージは日本語で簡潔に記述する。
- **デバッグ実装**: 調査用のトレース出力やデバッグフラグは、完了後に必ず削除し、本番コードに残さない。

## 5. 技術的注意点 (Unicode / Console)

- **sys/windows/consoletty.c**:
  - `ReadConsole` は常に `ReadConsoleW` を使い、バッファは `WCHAR` とする。
  - `INPUT_RECORD` の参照には `UnicodeChar` を使う。`AsciiChar` は日本語文字で誤動作の原因となる。

## 6. 参照先

- **翻訳ガイドライン**: `docs/translation-instructions-ja.md`
- **安全チェックリスト**: `docs/message-translation-safety-checklist.md`
- **用語集**: `docs/translation-glossary-quest.md`
