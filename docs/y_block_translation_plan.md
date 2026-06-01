<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Yブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「y」「*y」で始まる単語キー（Yブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **引用の形式**: 原文が書籍等から引用されているものは、そのオリジナルの改行形式とリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭の検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 作業計画と進捗管理
Yブロックは項目数が5件（実質5ブロック）と比較的コンパクトであるため、1つのグループとして一括で安全に適用・検証を行います。

### 進捗状況
- [x] **Yブロック一括適用と検証** (5/5 完了)
  - [x] `ya` の日本語翻訳を適用
  - [x] `yeenoghu` の日本語翻訳を適用
  - [x] `yeti` の日本語翻訳を適用
  - [x] `*yugake` の日本語翻訳を適用
  - [x] `yumi` の日本語翻訳を適用
  - [x] 適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 詳細翻訳設計案（新訳案）

### ① `ya` (5801-5803行付近) - 新規翻訳
*   **原文**:
    ```text
    ya
    	The arrow of choice of the samurai, ya are made of very
    	straight bamboo, and are tipped with hardened steel.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    ya
    	侍が好んで用いる矢（や）は、非常にまっすぐな竹で
    	作られており、その先端には焼き入れされた鋼が
    	取り付けられている。
    ```

### ② `yeenoghu` (5804-5809行付近) - 新規翻訳
*   **原文**:
    ```text
    yeenoghu
    	Yeenoghu, the demon lord of gnolls, still exists although
    	all his followers have been wiped off the face of the earth.
    	He casts magic projectiles at those close to him, and a mere
    	gaze into his piercing eyes may hopelessly confuse the
    	battle-weary adventurer.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    yeenoghu
    	クノルの魔王であるイェノグは、彼の信奉者たちが
    	ことごとく地上から一掃された今もなお存在している。
    	彼は身近な者に対して魔法の投射物を放ち、その鋭い
    	眼光で見つめられるだけで、戦いに疲れた冒険者は
    	絶望的な混乱に陥るかもしれない。
    ```

### ③ `yeti` (5810-5825行付近) - 新規翻訳
*   **原文**:
    ```text
    yeti
    	The Abominable Snowman, or yeti, is one of the truly great
    	unknown animals of the twentieth century.  It is a large hairy
    	biped that lives in the Himalayan region of Asia ... The story
    	of the Abominable Snowman is filled with mysteries great and
    	small, and one of the most difficult of all is how it got that
    	awful name.  The creature is neither particularly abominable,
    	nor does it necessarily live in the snows.  _Yeti_ is a Tibetan
    	word which may apply either to a real, but unknown animal of
    	the Himalayas, or to a mountain spirit or demon -- no one is
    	quite sure which.  And after nearly half a century in which
    	Westerners have trampled around looking for the yeti, and
    	asking all sorts of questions, the original native traditions
    	concerning the creature have become even more muddled and
    	confused.
    		[ The Encyclopedia of Monsters, by Daniel Cohen ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    yeti
    	雪男、あるいはイエティは、２０世紀における真に
    	偉大な未確認動物の一つである。それはアジアのヒマラヤ
    	地方に生息する、毛むくじゃらで大型の二足歩行生物で
    	ある……雪男の物語は大小さまざまな謎に満ちており、
    	中でも最も不可解なのは、なぜそのような恐ろしい名前が
    	ついたのかということだ。この生物は特に忌まわしいわけ
    	でもなければ、必ずしも雪の中に住んでいるわけでもない。
    	「イエティ」はチベット語であり、ヒマラヤに実在する
    	未確認の動物を指すこともあれば、山の精霊や悪魔を指す
    	こともあるが、どちらなのかははっきりしていない。
    	そして、西洋人がイエティを探し回って踏み荒らし、
    	ありとあらゆる質問を投げかけてから半世紀近くが経ち、
    	この生物に関する本来の先住民の伝承は、さらに混乱して
    	曖昧なものになってしまった。
    		［『モンスター百科事典』、ダニエル・コーエン著 ］
    ```

### ④ `*yugake` (5826-5829行付近) - 新規翻訳
*   **原文**:
    ```text
    *yugake
    	Japanese leather archery gloves.  Gloves made for use while
    	practicing had thumbs reinforced with horn.  Those worn into
    	battle had thumbs reinforced with a double layer of leather.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *yugake
    	日本の革製の弓術用手袋（ゆがけ）。練習用に作られた
    	手袋は、親指が角で補強されていた。合戦で着用された
    	ものは、親指が二重 of 革で補強されていた。
    ```
    ※注：ここは `of` 誤字が発生しやすいので、新訳案ではもちろん `二重の革` にしています：
    ```text
    *yugake
    	日本の革製の弓術用手袋（ゆがけ）。練習用に作られた
    	手袋は、親指が角で補強されていた。合戦で着用された
    	ものは、親指が二重の革で補強されていた。
    ```

### ⑤ `yumi` (5830-5834行付近) - 新規翻訳
*   **原文**:
    ```text
    yumi
    	The samurai is highly trained with a special type of bow,
    	the yumi.  Like the ya, the yumi is made of bamboo.  With
    	the yumi-ya, the bow and arrow, the samurai is an extremely
    	accurate and deadly warrior.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    yumi
    	侍は「弓（ゆみ）」と呼ばれる特殊な弓の訓練を高度に
    	積んでいる。矢と同様に、弓も竹で作られている。
    	弓と矢を合わせた「弓矢」を手にすることで、侍は
    	極めて正確で恐るべき戦士となる。
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を1項目ずつ手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
