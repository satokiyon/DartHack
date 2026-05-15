# NetHackJP 翻訳作業 指示ファイル

この文書は、NetHackJP の日本語化作業で共通運用するための実務指示をまとめたもの。

## 1. 目的

- ユーザー向けメッセージの日本語化を、安全に、継続的に進める。
- 原作の挙動を変えずに、表示文言のみを改善する。
- 用語と文体のぶれを抑え、プレイ体験を一貫させる。

## 2. ビルド手順 (Windows / VS)

### 推奨: VS Developer Shell 経由

PowerShell で以下を実行する。

```powershell
# VS DevShell を初期化してから msbuild を呼ぶ (通常 PowerShell では msbuild が PATH にない)
Import-Module 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
Enter-VsDevShell -VsInstallPath 'C:\Program Files\Microsoft Visual Studio\18\Community' -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'

Set-Location 'C:\Users\satok\NetHackJP'
# PowerShell では ; がコマンド区切りになるため /t: の値を必ず引用する
msbuild sys\windows\vs\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Debug /p:Platform=x64 /m /nologo /verbosity:minimal
```

> **注意**: PowerShell では `/t:NetHack;NetHackW` の `;` がコマンド区切りに解釈されることがあるため、
> `'/t:NetHack;NetHackW'` のようにシングルクォートで必ず引用する。

### 代替: フルパス MSBuild 直接呼び出し (VS DevShell 不要)

```powershell
Set-Location 'C:\Users\satok\NetHackJP'
& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe' `
	sys\windows\vs\NetHack.sln '/t:NetHack;NetHackW' /p:Configuration=Release /p:Platform=x64
```

### 最低確認

- Exit Code が `0` であること
- `binary\Debug\x64\NetHack.exe` と `NetHackW.exe` の両方が生成されること（Debug ビルドの場合）
- `binary\Release\x64\NetHack.exe` と `NetHackW.exe`（Release ビルドの場合）

### 注意事項

- `NetHackW.exe` が起動中の状態でビルドすると `LNK1168` でリンク失敗する。翻訳確認のみなら `/t:NetHack` だけでもコンパイル検証できる。
- `/t:Build` を使うと末尾の `package.vcxproj` で `nmake` 未検出 (MSB3073) になる場合がある。翻訳確認では `/t:NetHack;NetHackW` を使うこと。

## 3. 翻訳の基本方針

### 変更範囲

- 変更対象は原則として文字列リテラルの変更を優先する。
- ただし自然な日本語にするため、語順の入れ替え、補助語の付け足し、文脈を保つための最小限のロジック調整は許可する。
- 上記の調整はゲーム挙動を変えない範囲に限定し、条件分岐や制御フローの意味を変えない。

### 文体

- 常体を基本にする。
- 叙述は過去形を優先する(例: 〜した、〜だった)。
- 原文のニュアンスを保ち、意味を足し過ぎない。

### 記号・表記

- 互換性のため、文末記号は半角 `.`, `!`, `?` を基本維持する。
- 既存 UI 訳語と整合する表記を優先する。

## 4. フォーマット指定子の厳守

以下は絶対に変更しない。

- 個数: `%s`, `%d`, `%ld`, `%c` など
- 順序
- 型
- 対応する引数式

禁止例:

- `%s` を削除する
- `%d` を `%ld` に変更する
- 引数を減らす、順番を入れ替える

## 5. 用語ルール (重要)

本プロジェクトで確定した区別:

- boulder: 巨大な岩
- rock (壁・地形文脈): 岩
- iron bars: 鉄格子
- tree: 木
- door: 扉
- wall: 壁

特に boulder と rock は同じ訳にしない。

## 6. 既知の注意点

- 手動編集時は、書式指定子と引数の整合を必ず確認する。
- `still_chewing()` では boulder 判定と地形判定が混在するため、訳語の取り違えに注意する。
- `Tobjnam()` など複雑な文字列生成は、ロジックに触れず文脈のみ調整する。

## 7. 推奨ワークフロー

1. 対象ファイルで未翻訳メッセージを抽出する。
2. 小さな単位で翻訳を適用する。
3. 差分でフォーマット指定子の不変を確認する。
4. ビルドを実行し、エラー/警告の増加を確認する。
5. 必要ならプレイ中メッセージを目視確認する。

## 10. sys/windows/consoletty.c の Unicode 対応注意点

Win32 コンソール版の入力処理は Unicode ビルド (UNICODE マクロ定義) と密接に関係する。以下の点に注意する。

### 修正済みの問題パターン（参考）

| パターン | 問題 | 修正方針 |
|---|---|---|
| `CHAR ch2; ReadConsole(&ch2, 1, ...)` | Unicodeビルドでは `ReadConsole` → `ReadConsoleW` にマップされ 2バイトを 1バイトバッファに書き込む→スタック破壊 | `WCHAR wch2 = 0; ReadConsoleW(&wch2, 1, ...)` に変更 |
| `unsigned char ch = uChar.AsciiChar` (processkeystroke系) | 日本語文字の低バイトが `< 32` になると制御コードと誤判定される | `int ch = (int)(unsigned short)uChar.UnicodeChar` に変更 |
| `unsigned char ch = uChar.AsciiChar` (kbhit系) | 日本語文字が "Strange Key event" として誤 purge される恐れ | `WCHAR ch = uChar.UnicodeChar` に変更 |
| `uChar.AsciiChar` で bogus_key 初期化 | Unicode ビルドでの明示性不足 | `uChar.UnicodeChar = (WCHAR) 0x0080` に変更 |

### 新規修正時のルール

- `ReadConsole` を使う箇所は **常に `ReadConsoleW` を明示的に呼び、バッファを `WCHAR` にする**。
- `INPUT_RECORD.Event.KeyEvent.uChar` を参照する場合、**Unicodeビルドでは `UnicodeChar`** を使う。`AsciiChar` は低バイトの切り捨てになり、日本語文字で誤動作する。
- `ReadConsoleInput` / `PeekConsoleInput` は Unicodeビルドで W 版が使われるため、`uChar.UnicodeChar` が正しく設定される。

## 8. 変更後チェック

- コンパイルエラーが増えていない
- フォーマット警告が増えていない
- 代表的な戦闘/移動/罠/視認メッセージが自然
- メッセージ履歴や表示位置制御(`pline_dir`, `pline_xy`)に異常がない

## 9. 参照ドキュメント

- docs/message-translation-safety-checklist.md
- docs/translation-glossary-quest.md
- sys/windows/vs/.github/copilot-instructions.md
