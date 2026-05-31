<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-23. -->
# quest.lua 翻訳用語集・実務知見

この文書は `quest.lua` および関連するテキストの翻訳に使用する用語集と、特有の実務知見をまとめたものです。基本方針については [docs/translation-instructions-ja.md](translation-instructions-ja.md) を参照してください。

## 1. 固有名詞
- Amulet of Yendor: イェンダーの魔除け
- Wizard of Yendor: イェンダーの魔術師
- Moloch: モーロック
- Marduk: マルドゥク
- Gehennom: ゲヘナ
- Astral Plane: アストラル界
- Bell of Opening: 開門のベル

## 2. 役職・職業（既存UI訳語準拠）
- Archeologist: 考古学者
- Barbarian: 野蛮人
- Caveman / Cavewoman: 洞窟人
- Healer: 薬師
- Knight: 騎士
- Monk: 武闘家
- Priest / Priestess: 司祭
- Ranger: レンジャー
- Rogue: 盗賊
- Samurai: 侍
- Tourist: 観光客
- Valkyrie: ワルキューレ
- Wizard: 魔法使い

## 3. Quest 翻訳の実務知見

- **Lua 構造の維持**: キー名、テーブル構造、配列順は変更しない。
- **プレースホルダ**: `%p`, `%d`, `%l`, `%n`, `%o` などのプレースホルダは、`quest.lua` 独自の展開ルールがあるため、順序や個数を変えない。
- **口調の使い分け**:
  - 地の文は叙事調（常体）を基本とする。
  - 役職メッセージや神託などの命令調は、原文の威厳やニュアンスを維持する。
- **反映ルール**: 反映はブロック単位（common → 各職業）で行い、都度ビルド確認することを推奨。
- **非破壊編集**: 原文の英文を削除せず、文字列リテラル部分のみを置換すること。

