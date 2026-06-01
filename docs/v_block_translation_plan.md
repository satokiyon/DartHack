<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Vブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「v」「*v」「* v」で始まる単語キー（Vブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **引用の形式**: 原文が小説等から引用されているものは、そのオリジナルの改行形式とリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭 of 検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 作業計画と進捗管理
Vブロックは項目数が6件（実質6ブロック）と非常にコンパクトであるため、1つのグループとして一括で安全に適用・検証を行います。

### 進捗状況
- [x] **Vブロック一括適用と検証** (6/6 完了)
  - [x] `valkyrie` / `* valkyrie` の日本語翻訳を適用
  - [x] `vampire` / `~vampire bat` / `vampire l*` の日本語翻訳を適用
  - [x] `venus` の日本語翻訳を適用
  - [x] `vlad*` の日本語翻訳を適用
  - [x] `*vortex` / `vortices` の日本語翻訳を適用
  - [x] `vrock` の日本語翻訳を適用
  - [x] 適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 詳細翻訳設計案（新訳案）

### ① `valkyrie` / `* valkyrie` (5445-5458行) - 新規翻訳
*   **原文**:
    ```text
    valkyrie
    * valkyrie
    	The Valkyries were the thirteen choosers of the slain, the
    	beautiful warrior-maids of Odin who rode through the air and
    	over the sea.  They watched the progress of the battle and
    	selected the heroes who were to fall fighting.  After they
    	were dead, the maidens rewarded the heroes by kissing them
    	and then led their souls to Valhalla, where the warriors
    	lived happily in an ideal existence, drinking and eating
    	without restraint and fighting over again the battles in
    	which they died and in which they had won their deathless
    	fame.
    	    [ The Encyclopaedia of Myths and Legends of All Nations,
    		by Herbert Spencer Robinson and Knox Wilson ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    valkyrie
    * valkyrie
    	ワルキューレは、空中を駆け海を越えて旅する、オーディンの
    	美しい戦乙女であり、死を遂げる者を選ぶ１３人の存在だった。
    	彼女たちは戦況を見守り、戦いの中で倒れるべき英雄たちを
    	選別した。彼らが死んだ後、乙女たちは英雄たちに口づけをして
    	報い、彼らの魂をヴァルハラへと導いた。そこでは戦士たちが
    	理想的な生活の中で幸福に暮らし、制限なく飲んだり食べたりし、
    	自らが死に、不滅の誉れを得た戦闘を再び戦い抜くのだった。
    		［『万国の神話と伝説の百科事典』、
    		  ハーバート・スペンサー・ロビンソン＆
    		  ノックス・ウィルソン著 ］
    ```

### ② `vampire` / `~vampire bat` / `vampire l*` (5459-5481行) - 新規翻訳
*   **原文**:
    ```text
    vampire
    ~vampire bat
    vampire l*
    	He can transform himself to wolf, as we gather from the ship
    	arrival in Whitby, when he tear open the dog; he can be as
    	bat, as Madam Mina saw him on the window at Whitby, and as
    	friend John saw him fly from this so near house, and as my
    	friend Quincey saw him at the window of Miss Lucy. He can come
    	in mist which he create--that noble ship's captain proved him
    	of this; but, from what we know, the distance he can make this
    	mist is limited, and it can only be round himself. He come on
    	moonlight rays as elemental dust--as again Jonathan saw those
    	sisters in the castle of Dracula. He become so small--we
    	ourselves saw Miss Lucy, ere she was at peace, slip through a
    	hairbreadth space at the tomb door.
    		[ Dracula, by Bram Stoker ]

    	The Oxford English Dictionary is quite unequivocal:
    	_vampire_ - "a preternatural being of a malignant nature (in
    	the original and usual form of the belief, a reanimated
    	corpse), supposed to seek nourishment, or do harm, by sucking
    	the blood of sleeping persons. ..."
    		[]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    vampire
    ~vampire bat
    vampire l*
    	彼は狼に変身することができる。ホイットビーに船が到着した
    	際、彼が犬を引き裂いたことから我々はそれを知る；彼はコウモリ
    	になることもできる。ミナ夫人がホイットビーの窓で彼を目撃し、
    	友人のジョンがこのすぐ近くの家から彼が飛び去るのを見、
    	私の友人のクインシーがルーシー嬢の窓で彼を見たように。
    	彼は自ら作り出した霧となって現れることができる――あの高潔な
    	船長が身をもってそれを証明した；しかし我々の知る限り、
    	彼がこの霧を発生させられる距離は限られており、彼自身の
    	周囲に限られる。彼は元素のチリとして月光の光線に乗って
    	やってくる――ジョナサンがドラキュラ城でそれらの姉妹を
    	再び目撃したように。彼は非常に小さくなることができる――
    	我々自身、安らかに眠る前のルーシー嬢が、墓の扉の髪の毛ほどの
    	隙間をすり抜けるのを見たのだ。
    		［『ドラキュラ』、ブラム・ストーカー著 ］

    	オックスフォード英語辞典の記述は極めて明確である：
    	吸血鬼（ヴァンパイア）――「悪意ある性質を持つ超自然的な存在
    	（信仰の本来かつ通常の形態においては、蘇った死体）であり、
    	眠っている人々の血を吸うことによって栄養を求め、あるいは
    	害を及ぼすと想定されている。……」
    		［］
    ```

### ③ `venus` (5482-5493行) - 新規翻訳
*   **原文**:
    ```text
    venus
    	Venus, the goddess of love and beauty, was the daughter of
    	Jupiter and Dione.  Others say that Venus sprang from the
    	foam of the sea.  The zephyr wafted her along the waves to
    	the Isle of Cyprus, where she was received and attired by
    	the Seasons, and then led to the assembly of the gods.  All
    	were charmed with her beauty, and each one demanded her
    	for his wife.  Jupiter gave her to Vulcan, in gratitude for
    	the service he had rendered in forging thunderbolts.  So
    	the most beautiful of the goddesses became the wife of the
    	most ill-favoured of gods.
    		[ Bulfinch's Mythology, by Thomas Bulfinch ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    venus
    	愛と美の女神ヴィーナスは、ジュピターとディオーネの娘であった。
    	あるいは、ヴィーナスは海の泡から生まれたとも言われる。
    	西風（ゼピュロス）が波を越えて彼女をキプロス島へと運び、
    	そこで彼女は季節の女神たち（ホーラ）に迎えられて服を着せられ、
    	それから神々の集いへと導かれた。すべての者が彼女の美しさに
    	魅了され、各々が彼女を妻にと望んだ。ジュピターは、
    	雷撃を鍛造した功績に対する感謝の印として、彼女をバルカンに
    	与えた。こうして、女神の中で最も美しい者が、神々の中で
    	最も醜い者の妻となったのである。
    		［『ブルフィンチ神話』、トマス・ブルフィンチ著 ］
    ```

### ④ `vlad*` (5494-5503行) - 新規翻訳
*   **原文**:
    ```text
    vlad*
    	Vlad Dracula the Impaler was a 15th-Century monarch of the
    	Birgau region of the Carpathian Mountains, in what is now
    	Romania.  In Romanian history he is best known for two things.
    	One was his skilled handling of the Ottoman Turks, which kept
    	them from making further inroads into Christian Europe.  The
    	other was the ruthless manner in which he ran his fiefdom.
    	He dealt with perceived challengers to his rule by impaling
    	them upright on wooden stakes.  Visiting dignitaries who
    	failed to doff their hats had them nailed to their head.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    vlad*
    	串刺し公ヴラド・ドラキュラは、現在のルーマニアにあたる
    	カルパティア山脈ビルガウ地方の１５世紀の君主であった。
    	ルーマニアの歴史において、彼は主に２つのことで知られている。
    	１つはオスマン・トルコを巧みに扱い、キリスト教ヨーロッパへの
    	さらなる侵入を防いだことである。もう１つは、その領地を
    	支配した無慈悲な方法であった。彼は自身の支配を脅かすと
    	みなした者たちを、木の杭の上に直立させて串刺しにすることで
    	対処した。帽子を脱がなかった訪問中の高官たちは、帽子を
    	頭に釘付けにされた。
    ```

### ⑤ `*vortex` / `vortices` (5504-5510行) - 新規翻訳
*   **原文**:
    ```text
    *vortex
    vortices
    	Swirling clouds of pure elemental energies, the vortices are
    	thought to be related to the larger elementals.  They are
    	noted for being able to envelop unwary travellers.  The
    	hapless fool thus swallowed by a vortex will soon perish from
    	exposure to the element the vortex is composed of.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *vortex
    vortices
    	純粋な元素エネルギーの渦巻く雲であるボルテックス（渦）は、
    	より巨大なエレメンタルに関連していると考えられている。
    	それらは無警戒な旅人を包み込むことができることで知られている。
    	このようにボルテックスに呑み込まれた不幸な愚か者は、渦を構成する
    	元素にさらされることで、すぐに滅びることになる。
    ```

### ⑥ `vrock` (5511-5515行) - 新規翻訳
*   **原文**:
    ```text
    vrock
    	The vrock is one of the weaker forms of demon.  It resembles
    	a cross between a human being and a vulture and does physical
    	damage by biting and by using the claws on both its arms and
    	feet.  It can also release a cloud of noxious gas to hide in.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    vrock
    	ヴロックは比較的弱い形態の悪魔の１つである。人間とハゲタカの
    	中間のような姿をしており、噛みつきや両手両足の爪を用いて
    	物理的なダメージを与える。また、身を隠すために有毒ガスの雲を
    	放出することもできる。
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を1項目ずつ手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
