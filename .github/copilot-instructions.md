# Copilot Instructions for NetHackJP

このリポジトリでは、以下を最優先で守ること。

## 1. 作業対象

- 主に日本語翻訳作業を行う。
- 画面表示されるプレイヤー向けメッセージ（`You(...)`, `You_feel(...)`, `pline(...)` など）を優先して翻訳する。
- `impossible(...)` や `paniclog(...)` などの診断・デバッグ向け文言は原則として翻訳対象外とする。
- 原則として文字列リテラルの変更を優先する。
- ただし自然な日本語にするため、語順の入れ替え、補助語の付け足し、文脈を保つための最小限のロジック調整は許可する。
- 上記の調整はゲーム挙動を変えない範囲に限定し、条件分岐や制御フローの意味を変えない。

## 2. 翻訳スタイル

- 常体を基本とする。
- 叙述は過去形を優先する。
- 原文の意味を変えない。
- 文末記号は互換性のため半角 `.`, `!`, `?` を維持する。

## 3. 書式指定子の厳守

- `%s`, `%d`, `%ld`, `%c` などの個数・順序・型を変更しない。
- 対応する引数式を変更しない。

## 4. 用語ルール

- boulder: 巨大な岩
- rock (地形/壁文脈): 岩
- iron bars: 鉄格子
- tree: 木
- door: 扉
- wall: 壁

boulder と rock を同じ訳語にしない。

## 5. 翻訳対象外ファイル

以下のファイルは翻訳対象外とし、英語のまま維持すること。

- `include/defsym.h`: タイルモードでのタイル名照合に使われる文字列（`tilenm` 引数）が含まれるため、日本語化するとタイルファイルとの照合が失敗する。全エントリを英語のまま維持する。

## 6. 変更後の確認

- ビルド確認を行う。
- Windows では Developer PowerShell（VS DevShell）を使用して msbuild を実行する。
- `NetHack.exe` と `NetHackW.exe` の生成を確認する。

## 7. 参照先

詳細手順は以下を参照:

- docs/translation-instructions-ja.md
- docs/message-translation-safety-checklist.md
- docs/translation-glossary-quest.md

翻訳時の参考プロジェクト:

- https://github.com/jnethack/jnethack-release
