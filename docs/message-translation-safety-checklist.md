<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-26. -->
# Message Translation Safety Checklist (pline family)

このチェックリストは `pline`, `pline_dir`, `pline_xy`, `pline_mon`, `vpline` を経由するメッセージ翻訳の安全確認用。

## 1. フォーマット指定子の不変

- `%s`, `%d`, `%ld`, `%c` の個数を変えない
- 指定子の順序を変えない
- 指定子の型を変えない
- 引数式を変えない（例: `Monnam(mtmp)`, `body_part(...)`, `s_suffix(...)`）

## 2. ロジック不変

- `if` / `switch` 条件を変えない
- 分岐先の実行順を変えない
- `set_msg_dir`, `set_msg_xy` などメッセージ位置制御を変えない
- `Norep`, `custompline`, `urgent_pline` の使用方法を変えない

## 3. 文字列変更の範囲

- 変更対象は文字列リテラルのみ
- 文字列連結やバッファ長計算に影響する処理は変更しない
- 原作互換優先のため句読点は半角 `.`, `!`, `?` を基本維持

## 4. レビュー観点

- 日本語として意味が自然か
- 英語原文の意味が変わっていないか
- 主語がモンスターの場合 `%s` に対して不自然な助詞になっていないか
- 所有格（`s_suffix(...)`）を含む文で語順が破綻していないか
- `src/pline.c` のメッセージ表示関数（`You`, `Your`, `You_feel`, `You_hear`, `You_see`, `You_cant`, `There`, `pline_The`, `verbalize`, `custompline` など）を扱う場合、呼び出し側文字列との最終結合結果まで確認したか
- `You_see(...)` / `You_feel(...)` / `You_hear(...)` は接頭辞を自動付与するため、呼び出し側リテラルで主語重複や助詞衝突が起きていないか、最終表示文で確認したか
- 接頭辞側だけで不自然になる場合は、呼び出し側リテラルまたは最小限の文組み立て調整で自然な日本語にしたか

## 5. 変更後検証

- 変更ファイルでフォーマット警告が増えていない
- 戦闘・罠・移動・視認・聴覚の代表メッセージが正しく表示される
- メッセージ履歴や `--More--` の挙動に変化がない

## 6. Oracle 追加検証

- `dat/oracles.txt` の本文行と `util/makedefs.c` の `special_oracle[]` 各行は UTF-8 バイト長で **80 未満**になっているか（`src/rumors.c` の `line[COLNO]` 読み出し前提）。
- `dat/oracles.txt` の区切り行 `-----` が欠損・増減していないか。
- `The Dungeons of Doom` を表示文で使う場合、`src/dungeon.c` の表示語彙に合わせて **運命の大迷宮** を使っているか。

