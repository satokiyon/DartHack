<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Uブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「u」「*u」「* u」で始まる単語キー（Uブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **会話劇・引用の形式**: 原文が対話形式などで短い行で構成されているものは、そのオリジナルの改行形式とリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭の検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 作業計画と進捗管理
Uブロックは項目数が3件（実質3ブロック）と非常にコンパクトであるため、1つのグループとして一括で安全に適用・検証を行います。

### 進捗状況
- [x] **Uブロック一括適用と検証** (3/3 完了)
  - [x] `*unicorn` / `unicorn horn` の日本語翻訳を適用
  - [x] `unreconnoitered` の日本語翻訳を適用
  - [x] `uruk*hai shield` / `white-handed shield` の日本語翻訳を適用
  - [x] 適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 詳細翻訳設計案（新訳案）

### ① `*unicorn` / `unicorn horn` (5405-5432行) - 新規翻訳
*   **原文**:
    ```text
    *unicorn
    unicorn horn
    	Men have always sought the elusive unicorn, for the single
    	twisted horn which projected from its forehead was thought to
    	be a powerful talisman.  It was said that the unicorn had
    	simply to dip the tip of its horn in a muddy pool for the water
    	to become pure.  Men also believed that to drink from this horn
    	was a protection against all sickness, and that if the horn was
    	ground to a powder it would act as an antidote to all poisons.
    	Less than 200 years ago in France, the horn of a unicorn was
    	used in a ceremony to test the royal food for poison.

    	Although only the size of a small horse, the unicorn is a very
    	fierce beast, capable of killing an elephant with a single
    	thrust from its horn.  Its fleetness of foot also makes this
    	solitary creature difficult to capture.  However, it can be
    	tamed and captured by a maiden.  Made gentle by the sight of a
    	virgin, the unicorn can be lured to lay its head in her lap, and
    	in this docile mood, the maiden may secure it with a golden rope.
    	  [ Mythical Beasts, by Deirdre Headon (The Leprechaun Library) ]

    	Martin took a small sip of beer.  "Almost ready," he said.
    	"You hold your beer awfully well."
    	Tlingel laughed.  "A unicorn's horn is a detoxicant.  Its
    	possession is a universal remedy.  I wait until I reach the
    	warm glow stage, then I use my horn to burn off any excess and
    	keep me right there."
    		[ Unicorn Variations, by Roger Zelazny ]
    ```
*   **新訳案（散文：30〜34文字折り返し、会話劇：リズム・改行維持）**:
    ```text
    *unicorn
    unicorn horn
    	人間は常に捕らえがたいユニコーンを追い求めてきた。
    	その額から突き出た一本の螺旋状の角は、強力な護符であると
    	考えられていたからである。ユニコーンが泥水に角の先端を
    	浸すだけで、その水は清められると言われていた。また、人間は
    	この角から飲むことはすべての病気に対する予防になると信じており、
    	角を粉末にすればすべての毒に対する解毒剤として作用すると
    	信じていた。フランスでは２００年も経たない昔まで、王室の
    	食事の毒見をする儀式にユニコーンの角が使われていた。

    	体は小さな馬ほどの大きさしかないが、ユニコーンは非常に
    	獰猛な獣であり、角のひと突きで象を殺すことができる。
    	また、その足の速さも相まって、この孤独な生き物を捕らえる
    	ことは困難である。しかし、乙女によって手懐けられ、捕らえられる
    	ことがある。処女の姿を見て優しくなったユニコーンは、
    	彼女の膝の上に頭を横たえるよう誘い込まれ、この従順な状態で、
    	乙女は金のロープでそれを縛り上げることができる。
    		［『神話の獣たち』、ディードル・ヒードン著 ］

    	マーティンはビールを一口小さくすすった。「ほぼ準備完了だ」
    	と彼は言った。「君は実によくビールを保つね。」
    	Tlingelは笑った。「ユニコーンの角は解毒剤なのさ。それを
    	所有することは万能薬だ。私は心地よく酔う段階に達するまで待ち、
    	それから角を使って余分なアルコールを燃やし、その状態を
    	ちょうど維持するんだ。」
    		［『ユニコーン・バリエーションズ』、
    		  ロジャー・ゼラズニイ著 ］
    ```
    ※ `Tlingel` などの名前や、会話劇の表現が美しく処理されるよう注意します。

### ② `unreconnoitered` (5433-5435行) - 新規翻訳
*   **原文**:
    ```text
    unreconnoitered
    	Area of map which is beyond limited perception range when
    	underwater or engulfed by a monster.
    ```
*   **新訳案（簡潔な説明文：30〜34文字折り返し）**:
    ```text
    unreconnoitered
    	水中、あるいはモンスターに呑み込まれた際、
    	制限された知覚範囲の外にあるマップ領域。
    ```

### ③ `uruk*hai shield` / `white-handed shield` (5436-5444行) - 新規翻訳
*   **原文**:
    ```text
    uruk*hai shield
    white-handed shield
    	They were armed with short broad-bladed swords, not with the
    	curved scimitars usual with Orcs: and they had bows of yew,
    	in length and shape like the bows of Men. Upon their shields
    	they bore a strange device: a small white hand in the centre
    	of a black field; on the front of their iron helms was set an
    	S-rune, wrought of some white metal.
    		[ The Two Towers, by J.R.R. Tolkien ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    uruk*hai shield
    white-handed shield
    	彼らはオークに一般的な曲がったシミターではなく、刃の広い
    	短い剣で武装していた：そして彼らは、長さや形状が人間の
    	弓に似たイチイの木の弓を持っていた。彼らの盾には奇妙な紋章、
    	すなわち黒地の中心に描かれた小さな白い手があしらわれていた；
    	彼らの鉄の兜の前面には、何らかの白い金属で作られた
    	Ｓのルーンが据えられていた。
    		［『二つの塔』、Ｊ・Ｒ・Ｒ・トールキン著 ］
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を1項目ずつ手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
