<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Xブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「x」「*x」「* x」で始まる単語キー（Xブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **引用の形式**: 原文がマヤ神話等の聖典から引用されているものは、そのオリジナルの改行形式とリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭の検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 作業計画と進捗管理
Xブロックは項目数が2件（実質2ブロック）と非常にコンパクトであるため、1つのグループとして一括で安全に適用・検証を行います。

### 進捗状況
- [ ] **Xブロック一括適用と検証** (0/2 完了)
  - [ ] `xan` の日本語翻訳を適用
  - [ ] `xorn` の日本語翻訳を適用
  - [ ] 適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [ ] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 詳細翻訳設計案（新訳案）

### ① `xan` (5783-5795行付近) - 新規翻訳
*   **原文**:
    ```text
    xan
    	They sent their friend the mosquito [xan] ahead of them to
    	find out what lay ahead.  "Since you are the one who sucks
    	the blood of men walking along paths," they told the mosquito,
    	"go and sting the men of Xibalba."  The mosquito flew
    	down the dark road to the Underworld.  Entering the house of
    	the Lords of Death, he stung the first person that he saw...

    	The mosquito stung this man as well, and when he yelled, the
    	man next to him asked, "Gathered Blood, what's wrong?"  So
    	he flew along the row stinging all the seated men until he
    	knew the names of all twelve.
    			[ Popul Vuh, as translated by Ralph Nelson ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    xan
    	彼らは先方に何があるかを探るため、友人の蚊［クサン］を
    	先に行かせた。「お前は道を歩く人間の血を吸う者なのだから」
    	と彼らは蚊に言った。「行ってシバルバーの人々を刺すがよい。」
    	蚊は冥界へと続く暗い道を飛び下りた。死の君主たちの館に入り、
    	彼は最初に見かけた人物を刺した……

    	蚊はその男も刺した。男が叫ぶと、隣の男が「集まる血よ、
    	どうしたのだ？」と尋ねた。こうして彼は、座っている男たちを
    	列に沿って刺しながら飛び回り、ついに１２人全員の名前を
    	知るに至った。
    			［『ポポル・ヴフ』、ラルフ・ネルソン訳 ］
    ```

### ② `xorn` (5796-5801行付近) - 新規翻訳
*   **原文**:
    ```text
    xorn
    	A distant cousin of the earth elemental, the xorn has the
    	ability to shift the cells of its body around in such a way
    	that it becomes porous to inert material.  This gives it the
    	ability to pass through any obstacle that might be between it
    	and its next meal.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    xorn
    	土のエレメンタルの遠い親戚であるゾーンは、不活性な物質に
    	対して多孔質（浸透可能）になるような方法で、自らの体の細胞を
    	移動させる能力を持っている。これにより、ゾーンは次の食事と
    	自らの間に立ちふさがる、いかなる障害物をも通り抜ける能力を
    	得ている。
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を1項目ずつ手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
