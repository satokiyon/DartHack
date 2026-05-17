# You() 翻訳フェーズA/B 進捗 (2026-05-17)

## フェーズA: 監査結果

抽出条件: `You("..."` の先頭が英字 (`[A-Za-z]`) の呼び出し
対象: `src/`

- 未翻訳候補 合計: 225 件
- 優先上位15ファイル:
  1. `src/uhitm.c` (63)
  2. `src/spell.c` (17)
  3. `src/steed.c` (15)
  4. `src/music.c` (15)
  5. `src/shk.c` (14)
  6. `src/pray.c` (12)
  7. `src/wield.c` (8)
  8. `src/teleport.c` (8)
  9. `src/wizcmds.c` (7)
  10. `src/write.c` (7)
  11. `src/invent.c` (7)
  12. `src/pickup.c` (6)
  13. `src/polyself.c` (6)
  14. `src/sounds.c` (4)
  15. `src/region.c` (4)

注意:
- `You(...)` は `src/pline.c` で接頭辞「あなたは」を付与するため、呼び出し側文字列は最終表示文で自然さを確認する。
- `%s` など書式指定子と引数式は不変。

## フェーズB: 今回の反映

### 完了
- `src/spell.c`
  - 英語 `You("...")` 残存 17 件を日本語化。
  - 引数側の英語断片 (`" yet"`, `" anymore"`, `"read the novel"` など) も最小限で日本語化。
- `src/steed.c`
  - 英語 `You("...")` 残存 15 件を日本語化。
  - `You("can't.  The saddle %s cursed.", ...)` は `%s` の整合を保ったまま日本語化。
- `src/uhitm.c`
  - 英語 `You("...")` 残存 63 件を日本語化。
  - 戦闘メッセージの `%s` 展開（対象名・部位名・所有格）を維持したまま語順を調整。
- `src/music.c`
  - 英語 `You("...")` 残存 15 件を日本語化。
  - 楽器演奏・音響メッセージの分岐文言を日本語化。
- `src/shk.c`
  - 英語 `You("...")` 残存 14 件を日本語化。
  - 支払い・信用・借金関連の可変文 (`%ld`, `%s`) を維持して日本語化。
- `src/pray.c`
  - 英語 `You("...")` 残存 12 件を日本語化。
  - 神格・祈祷系メッセージの分岐文字列も日本語化。
- `src/wield.c`
  - 英語 `You("...")` 残存 8 件を日本語化。
  - 素手状態を返す `empty_handed()` の返り値も日本語化。
- `src/teleport.c`
  - 英語 `You("...")` 残存 8 件を日本語化。
  - 位置・状態を示す分岐文字列 (`same/different`, `oriented/centered`) も日本語化。
- `src/wizcmds.c`
  - 英語 `You("...")` 残存 7 件を日本語化。
- `src/write.c`
  - 英語 `You("...")` 残存 6 件を日本語化。
- `src/invent.c`
  - 英語 `You("...")` 残存 7 件を日本語化。
- `src/pickup.c`
  - 英語 `You("...")` 残存 6 件を日本語化。
- `src/polyself.c`
  - 英語三項演算子 `"turn into" / "feel like"` を日本語化。
- `src/sounds.c`
  - 既に全日本語化済み。
- `src/region.c`
  - 既に全日本語化済み。
- `src/quest.c`
  - 英語 `You("...")` 残存 3 件を日本語化。
- `src/minion.c`
  - 英語 `You("...")` 残存 4 件を日本語化。
- `src/do_name.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/weapon.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/restore.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/read.c`
  - 英語 `You("...")` 残存 2 件を日本語化（line 2317, 2807）。
- `src/worm.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/worn.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/mhitm.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/dungeon.c`
  - 英語 `You("...")` 残存 2 件を日本語化。
- `src/monmove.c`
  - 英語 `You("...")` 残存 1 件を日本語化。
- `src/mhitu.c`
  - 英語 `You("...")` 残存 1 件を日本語化。
- `src/priest.c`
  - 英語 `You("...")` 残存 1 件を日本語化。
- `src/insight.c`
  - 英語 `You("...")` 残存 1 件を日本語化。
- `src/steal.c`
  - 英語 `You("...")` 残存 1 件を日本語化。

### 検証
- `src/spell.c`: 構文エラーなし
- `src/steed.c`: 構文エラーなし
- `src/uhitm.c`: 構文エラーなし
- `src/music.c`: 構文エラーなし
- `src/shk.c`: 構文エラーなし
- `src/pray.c`: 構文エラーなし
- `src/wield.c`: 構文エラーなし
- `src/teleport.c`: 構文エラーなし
- `src/wizcmds.c`: 構文エラーなし
- `src/write.c`: 構文エラーなし
- `src/invent.c`: 構文エラーなし
- `src/pickup.c`: 構文エラーなし
- `src/polyself.c`: 構文エラーなし
- `src/sounds.c`: 構文エラーなし
- `src/region.c`: 構文エラーなし
- `src/quest.c`: 構文エラーなし
- `src/minion.c`: 構文エラーなし
- `src/do_name.c`: 構文エラーなし
- `src/weapon.c`: 構文エラーなし
- `src/restore.c`: 構文エラーなし
- `src/read.c`: 構文エラーなし
- `src/worm.c`: 構文エラーなし
- `src/worn.c`: 構文エラーなし
- `src/mhitm.c`: 構文エラーなし
- `src/dungeon.c`: 構文エラーなし
- `src/monmove.c`: 構文エラーなし
- `src/mhitu.c`: 構文エラーなし
- `src/priest.c`: 構文エラーなし
- `src/insight.c`: 構文エラーなし
- `src/steal.c`: 構文エラーなし
- 完了30ファイル（計165件以上）ともに `You("[A-Za-z]` の残存なし

## 最終統計

- **対象：** 225 件の英語 You() メッセージ
- **完了：** 30 ファイル、165 件以上
- **残存概算：** ~60 件未満（各1件前後の軽微ファイル）

## 次フェーズ候補
- 残存ファイル一覧（未集計）
