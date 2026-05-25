---
name: nethackjp-message-translation
description: NetHackJP のメッセージ翻訳作業で、内部キー互換を壊さず自然な日本語へ改善し、最小変更で検証まで行うための実務手順。
---

# NetHackJP Message Translation

NetHackJP の表示メッセージ翻訳を安全に進めるためのプロジェクト専用スキル。

## When to Use

以下の依頼で使う:

- 表示文の英語残存を日本語化したい
- 日本語として不自然な文を自然化したい
- `You(...)`, `You_feel(...)`, `You_hear(...)`, `You_see(...)`, `pline(...)`, `pline_The(...)`, `There(...)`, `verbalize(...)` の文言調整
- 翻訳後にビルドやメッセージ回帰を安全に確認したい

## Core Rules

- 変更対象は原則として表示文言（文字列リテラル）を優先し、不要なロジック変更を避ける。
- フォーマット指定子（`%s`, `%d`, `%ld` など）の個数・順序・型を維持する。
- 質問文（入力/確認）は敬体（です・ます調）を優先し、文末は半角 `?` を使う。
- `You_*` 系は接頭辞自動付与を前提に、主語重複を避ける。
- 英語活用ヘルパー（`vtense`, `makeplural`, `an`）を日本語文に直接流用しない。
- 内部キー（wish/Lua/照合用の英語文字列）を直接日本語化しない。表示は専用ヘルパー経由で分離する。

## Workflow

1. 対象と文脈を確認する
- 対象行だけでなく前後分岐を読む。
- 連結後の最終表示文で自然さを判断する。

2. 影響範囲を洗い出す
- まず `ag` で同様パターンや呼び出し元を確認する（未導入なら `rg` で代替）。
- 比較キーとして使われる文字列かどうかを確認する。

3. 最小差分で修正する
- 語順や文型は日本語として自然な形へ調整する。
- ただし制御フロー、引数式、メッセージ制御（`set_msg_dir` など）は原則不変。

4. 検証する
- 変更ファイルに対して `get_errors` で構文/型エラーを確認する。
- 必要に応じて Windows 環境でビルド確認する。

## Build Check (Windows)

`MSBuild.exe` を使う場合の代表例:

```powershell
MSBuild.exe sys\windows\vs\NetHack.sln /t:"NetHack;NetHackW" /p:Configuration=Debug /p:Platform=x64
```

確認事項:

- Exit Code が 0
- `binary\Debug\x64\NetHack.exe` と `NetHackW.exe` が生成される

## Translation Quality Checklist

- 完成文で読んで自然か
- `%` 指定子と可変引数が一致しているか
- 助詞連結（`%sは`, `%sを`, `%sに`, `%sの`）が破綻していないか
- 引数側の語句（テンプレート外）に英語残存がないか
- 接頭辞関数（`You_*`, `There`, `pline_The`）と呼び出し側の重複がないか

## Notes Specific to This Repo

- 進捗と再発防止の知見は `/memories/repo/translation-notes.md` を優先参照する。
- 技術運用は `.github/copilot-instructions.md`、翻訳方針は `docs/translation-instructions-ja.md` を基準にする。
- 安全確認は `docs/message-translation-safety-checklist.md` を使う。
