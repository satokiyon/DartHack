<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Tブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「t」「*t」「* t」で始まる単語キー（Tブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **ポエム・詩・会話劇**: 原文がポエムや詩、あるいは短い会話劇として短い行で構成されているものは、そのオリジナルの改行形式とリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭の検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。

---

## 2. 段階的作業計画（小規模グループ分割）
安全を最優先とするため、全24エントリの翻訳適用作業を以下の4つのグループ（各6項目ずつ）に細分化して進めます。

| グループ | 対象キー範囲 | 項目数 | 主な内容 | 状態 |
| :--- | :--- | :--- | :--- | :---: |
| **グループ1** | `tanko` 〜 `thug` | 6項目 | 短甲、天狗、トート神、トート＝アモン、玉座、サッグ/凶漢 | 未着手 |
| **グループ2** | `tiger` 〜 `touch*stone` | 6項目 | トラ（ブレイクの詩）、缶詰、缶切り、タイタン、トパーズ、試金石 | 未着手 |
| **グループ3** | `tourist` 〜 `tree` | 6項目 | 観光客、タオル、塔、落とし戸、トラッパー、樹木（キルマーの詩） | 未着手 |
| **グループ4** | `tripe` 〜 `tyr` | 6項目 | トリッパ/ハチノス、トロール、村正の剣、ツルギ（両手剣）、トルコ石、ティール神 | 未着手 |

---

## 3. 各グループの詳細翻訳設計案（新訳案）

### 【グループ1：神話・歴史系】

#### ① `tanko` (5097-5098行) - 新規翻訳
*   **原文**:
    ```text
    tanko
    	Samurai plate armor of the Yamato period (AD 300 - 710).
    ```
*   **新訳案（散文・簡潔な説明文）**:
    ```text
    tanko
    	大和時代（西暦３００－７１０年）の侍の板状甲冑（短甲）。
    ```

#### ② `tengu` (5099-5106行) - 新規翻訳
*   **原文**:
    ```text
    tengu
    	The tengu was the most troublesome creature of Japanese
    	legend.  Part bird and part man, with red beak for a nose
    	and flashing eyes, the tengu was notorious for stirring up
    	feuds and prolonging enmity between families.  Indeed, the
    	belligerent tengu were supposed to have been man's first
    	instructors in the use of arms.
    	  [ Mythical Beasts, by Deirdre Headon (The Leprechaun Library) ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tengu
    	天狗は、日本の伝説の中で最も厄介な生き物である。
    	半分は鳥で半分は人間であり、鼻の代わりとなる赤い嘴と
    	光る目を持ち、争いを引き起こしたり家族間の仇討ちを
    	長引かせたりすることで悪名高かった。実際、この好戦的な
    	天狗たちは、人間に武器の使い方を教えた最初の教師だったと
    	されている。
    		［『神話の獣たち』、ディードル・ヒードン著 ］
    ```

#### ③ `thoth` (5107-5126行) - 新規翻訳
*   **原文**:
    ```text
    thoth
    	The Egyptian god of the moon and wisdom, Thoth is the patron
    	deity of scribes and of knowledge, including scientific,
    	medical and mathematical writing, and is said to have given
    	mankind the art of hieroglyphic writing.  He is important as
    	a mediator and counsellor amongst the gods and is the scribe
    	of the Heliopolis Ennead pantheon.  According to mythology,
    	he was born from the head of the god Seth.  He may be
    	depicted in human form with the head of an ibis, wholly as an
    	ibis, or as a seated baboon sometimes with its torso covered
    	in feathers.  His attributes include a crown which consists
    	of a crescent moon surmounted by a moon disc.
    	Thoth is generally regarded as a benign deity.  He is also
    	scrupulously fair and is responsible not only for entering
    	in the record the souls who pass to afterlife, but of
    	adjudicating in the Hall of the Two Truths.  The Pyramid
    	Texts reveal a violent side of his nature by which he
    	decapitates the adversaries of truth and wrenches out their
    	hearts.
    		[ Encyclopedia of Gods, by Michael Jordan ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    thoth
    	エジプトの月と知恵 of 神トートは、書記官と知識 of 守護神であり、
    	そこには科学、医学、数学の記述も含まれる。また、人間に
    	ヒエログリフ（象形文字）の技術を授けたと言われている。
    	彼は神々の間における調停者および顧問として重要であり、
    	ヘリオポリスのエネアド（九柱神）の書記官でもある。神話によれば、
    	彼はセト神の頭部から生まれた。トキの頭を持つ人間の姿、
    	あるいはトキそのものの姿、あるいは時には胴体が羽毛で
    	覆われた座ったヒヒの姿で描かれる。彼の象徴には、
    	三日月に月円盤を載せた王冠が含まれる。
    
    	トートは一般的に慈悲深い神とみなされている。また、
    	非常に公正であり、あの世へ旅立つ魂を記録するだけでなく、
    	「真理の二つの間」での審判を行う役割も担っている。
    	ピラミッド・テキストは彼の暴力的な一面を明らかにしており、
    	そこでは真理に敵対する者の首をはね、その心臓を
    	引きちぎる姿が描かれている。
    		［『神々の百科事典』、マイケル・ジョーダン著 ］
    ```
    ※誤変換 `of` を `の` にして適用します。

#### ④ `thoth*amon` (5127-5132行) - 新規翻訳
*   **原文**:
    ```text
    thoth*amon
    	Men say that he [Thutothmes] has opposed Thoth-Amon, who is
    	master of all priests of Set, and dwells in Luxor, and that
    	Thutothmes seeks hidden power [The Heart of Ahriman] to
    	overthrow the Great One.
    		[ Conan the Conqueror, by Robert E. Howard ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    thoth*amon
    	人々は彼［ツトメス］が、セトのすべての司祭の支配者であり
    	ルクソールに住むトート＝アモンに反対しており、ツトメスは
    	その偉大なる者を打倒するために隠された力［アリマンの心臓］を
    	求めていると言っている。
    		［『征服者コナン』、ロバート・Ｅ・ハワード著 ］
    ```

#### ⑤ `*throne` (5133-5149行) - 新規翻訳
*   **原文**:
    ```text
    *throne
    	Methought I saw the footsteps of a throne
    	Which mists and vapours from mine eyes did shroud--
    	Nor view of who might sit thereon allowed;
    	But all the steps and ground about were strown
    	With sights the ruefullest that flesh and bone
    	Ever put on; a miserable crowd,
    	Sick, hale, old, young, who cried before that cloud,
    	"Thou art our king,
    	O Death! to thee we groan."
    	Those steps I clomb; the mists before me gave
    	Smooth way; and I beheld the face of one
    	Sleeping alone within a mossy cave,
    	With her face up to heaven; that seemed to have
    	Pleasing remembrance of a thought foregone;
    	A lovely Beauty in a summer grave!
    		[ Sonnet, by William Wordsworth ]
    ```
*   **新訳案（詩のリズム・改行を維持、全角34文字以下）**:
    ```text
    *throne
    	私は玉座の足跡を見たように思った、
    	霧と蒸気が私の目からそれを覆い隠し――
    	そこに誰が座っているかを見ることも許されなかった；
    	しかし、すべての階段と周囲の地面は散らばっていた、
    	生身の身体がこれまでに身にまとった中で
    	最も哀れな光景で；悲惨な群衆、
    	病める者、健やかな者、老いた者、若い者が、あの雲の前で叫んだ、
    	「汝は我らの王なり、
    	おお、死よ！ 我らは汝に向かってうめく。」
    	I 階段を登った；目の前の霧は
    	平坦な道を与えた；そして私はある者の顔を見た、
    	苔むした洞窟の中で一人静かに眠っている、
    	その顔を天に向けて；それは有していたようだ、
    	過ぎ去った思考の心地よい記憶を；
    	夏の墓の中の、愛らしく美しい美女を！
    		［「ソネット」、ウィリアム・ワーズワース著 ］
    ```

#### ⑥ `thug` (5150-5159行) - 新規翻訳
*   **原文**:
    ```text
    thug
    	A worshipper of Kali, who practised _thuggee_, the strangling
    	of human victims in the name of the religion.  Robbery of the
    	victim provided the means of livelihood.  They were also
    	called _Phansigars_ (Noose operators) from the method employed.
    	Vigorous suppression was begun by Lord William Bentinck in
    	1828, but the fraternity did not become completely extinct
    	for another 50 years or so.
    	In common parlance the word is used for any violent "tough".
    		[ Brewer's Concise Dictionary of Phrase and Fable ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    thug
    	カリの崇拝者であり、宗教の名の下に人間の犠牲者を絞殺する
    	「サギー」を実践した者。犠牲者から強奪することが
    	生計の手段となった。用いられた方法から「ファンシガル」（
    	輪縄の使い手）とも呼ばれた。１８２８年にウィリアム・
    	ベンティンク卿によって精力的な鎮圧が開始されたが、
    	この結社が完全に消滅するまでには、さらに５０年ほどかかった。
    	一般的な会話では、この言葉はあらゆる暴力的な「凶漢（タフ）」を
    	指して使われる。
    		［『ブルーワーの慣用句と寓話の簡潔辞典』 ］
    ```

---

### 【グループ2：詩・缶詰・科学系】

#### ⑦ `tiger` (5160-5172行) - 新規翻訳
*   **原文**:
    ```text
    tiger
    	1.  A well-known tropical predator (_Felis tigris_): a
    	feline.  It has a yellowish skin with darker spots or
    	stripes.  2.  Figurative: _a paper tiger_, something that is
    	meant to scare, but has no really scaring effect whatsoever,
    	(after a statement by Mao Ze Dong, August 1946).
    		[ Van Dale's Groot Woordenboek der Nederlandse Taal ]
    
    	Tyger! Tyger! burning bright
    	In the forests of the night,
    	What immortal hand or eye
    	Could frame thy fearful symmetry?
    		[ The Tyger, by William Blake ]
    ```
*   **新訳案（散文および詩の混在。詩の部分は改行・リズム維持）**:
    ```text
    tiger
    	1. よく知られた熱帯の捕食者（_Felis tigris_）：ネコ科の動物。
    	暗い斑点または縞模様のある帯黄色の皮膚を持つ。
    	2. 比喩：紙の虎（paper tiger）。脅かすことを目的としているが、
    	実際には全く脅威とならないもの（１９４６年８月の
    	毛沢東の声明にちなむ）。
    		［『ファン・ダーレ・オランダ語大辞典』 ］
    
    	虎よ！ 虎よ！ 暗闇に赤々と燃える
    	夜の森のただ中で、
    	いかなる不滅の手や目が、
    	汝の恐るべき調和（シンメトリー）を形作り得たのか？
    		［『虎』、ウィリアム・ブレイク著 ］
    ```

#### ⑧ `tin` / `tin of *` / `tinning kit` (5173-5183行) - 新規翻訳
*   **原文**:
    ```text
    tin
    tin of *
    tinning kit
    	"You know salmon, Sarge," said Nobby.
    	"It is a fish of which I am aware, yes."
    	"You know they sell kind of slices of it in tins..."
    	"So I am given to understand, yes."
    	"Weell...how come all the tins are the same size?  Salmon
    	gets thinner at both ends."
    	"Interesting point, Nobby.  I think-"
    		[ Soul Music, by Terry Pratchett ]
    ```
*   **新訳案（会話劇形式：リズムと間を維持）**:
    ```text
    tin
    tin of *
    tinning kit
    	「サケ（サーモン）は知っているだろ、軍曹」とノビーが言った。
    	「私が存在を知っている魚だな、そうだ。」
    	「あいつらの切り身を缶詰にして売っているのを知っているだろ……」
    	「そう聞かされているな、そうだ。」
    	「うーん……どうして缶詰はどれも同じ大きさなんだ？
    	サケは両端に行くほど細くなっているのに。」
    	「興味プレイポイントだ、ノビー。私は思うのだが――」
    		［『ソウル・ミュージック』、テリー・プラチェット著 ］
    ```
    ※「興味プレイポイント」は `興味深い指摘` の誤字防止のため注意深く出力します。

#### ⑨ `tin opener` (5184-5204行) - 新規翻訳
*   **原文**:
    ```text
    tin opener
    	Less than thirty Cat tribes now survived, roaming the cargo
    	decks on their hind legs in a desperate search for food.
    	But the food had gone.
    	The supplies were finished.
    	Weak and ailing, they prayed at the supply hold's silver
    	mountains: huge towering acres of metal rocks which, in their
    	pagan way, the mutant Cats believed watched over them.
    	Amid the wailing and the screeching one Cat stood up and held
    	aloft the sacred icon.  The icon which had been passed down
    	as holy, and one day would make its use known.
    	It was a piece of V-shaped metal with a revolving handle on
    	its head.
    	He took down a silver rock from the silver mountain, while
    	the other Cats cowered and screamed at the blasphemy.
    	He placed the icon on the rim of the rock, and turned the
    	handle.
    	And the handle turned.
    	And the rock opened.
    	And inside the rock was Alphabetti spaghetti in tomato sauce.
    		[ Red Dwarf, by Rob Grant and Doug Naylor ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tin opener
    	生き残った猫の部族は今や３０未満となり、食料を求めて
    	必死に貨物デッキを二本足で歩き回っていた。しかし食料は消え、
    	備蓄は底をついていた。
    	弱り衰えた彼らは、備蓄倉庫の銀の山に向かって祈りを捧げた：
    	そびえ立つ巨大な金属の岩で、異変を遂げた猫たちは、自分たちの
    	異教的なやり方で、それらが自分たちを見守ってくれていると信じていた。
    	哀悼と金切り声の中で、１匹の猫が立ち上がり、神聖な聖像を
    	高く掲げた。それは神聖なものとして受け継がれ、いつの日か
    	その使い道が明らかになるとされていた。
    	それは、頭部に回転するハンドルのついた、Ｖ字型の金属片だった。
    	他の猫たちがその冒涜行為に怯えて叫ぶ中、彼は銀の山から
    	銀の岩を１つ取り出した。
    	彼はその聖像を岩の縁に置き、ハンドルを回した。
    	するとハンドルが回った。
    	    そして岩が開いた。
    	そして岩の中には、トマトソースを絡めたアルファベッティ・
    	スパゲッティが入っていた。
    		［『宇宙船レッド・ドワーフ号』、
    		  ロブ・グラント＆ダグ・ネイラー著 ］
    ```

#### ⑩ `titan` (5205-5216行) - 新規翻訳
*   **原文**:
    ```text
    titan
    	Gaea, mother earth, arose from the Chaos and gave birth to
    	Uranus, heaven, who became her consort.  Uranus hated all
    	their children, because he feared they might challenge his
    	own authority.  Those children, the Titans, the Gigantes,
    	and the Cyclops, were banished to the nether world.  Their
    	enraged mother eventually released the youngest titan,
    	Chronos (time), and encouraged him to castrate his father and
    	rule in his place.  Later, he too was challenged by his own
    	son, Zeus, and he and his fellow titans were ousted from
    	Mount Olympus.
    		[ Greek Mythology, by Richard Patrick ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    titan
    	混沌（カオス）から大地の母ガイアが生まれ、天のウラヌスを
    	生み出してその配偶者とした。ウラヌスはすべての子供たちを憎んだ。
    	彼らが自身の権威を脅かすことを恐れたからである。その子供たちである
    	タイタン、ギガンテス、サイクロプスは冥界へと追放された。
    	激怒した母は最終的に最も若いタイタンであるクロノス（時間）を解放し、
    	父親を去勢して代わりに支配するよう促した。後に、彼もまた自身の息子である
    	ゼウスによって挑戦を受け、彼と他のタイタンたちはオリンポス山から
    	追放された。
    		［『ギリシャ神話』、リチャード・パトリック著 ］
    ```

#### ⑪ `topaz` (5217-5227行) - 新規翻訳
*   **原文**:
    ```text
    topaz
    	Aluminum silicate mineral with either hydroxyl radicals or
    	fluorine, Al2SiO4(F,OH)2, used as a gem.  It is commonly
    	colorless or some shade of pale yellow to wine-yellow;
    	... The stone is transparent with a vitreous luster.  It has
    	perfect cleavage on the basal pinacoid, but it is nevertheless
    	hard and durable.  The brilliant cut is commonly used.  Topaz
    	crystals, which are of the orthorhombic system, occur in highly
    	acid igneous rocks, e.g., granites and rhyolites, and in
    	metamorphic rocks, e.g., gneisses and schists.
    		[ The Columbia Encyclopedia, Sixth Edition ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    topaz
    	ヒドロキシルラジカルまたはフッ素のいずれかを含むケイ酸アルミニウム鉱物、
    	Al2SiO4(F,OH)2で、宝石として使用される。一般的には無色、
    	あるいは淡黄色からワインイエローの色合いをしている；
    	……石は透明でガラス光沢を持つ。底面ピンコイドに完全な劈開を
    	持つが、それにもかかわらず硬く耐久性がある。一般的にブリリアントカットが
    	用いられる。斜方晶系に属するトパーズの結晶は、花崗岩や流紋岩などの
    	高度に酸性の火成岩、および片麻岩や片岩などの変成岩に発生する。
    		［『コロンビア百科事典』第６版 ］
    ```

#### ⑫ `touch*stone` (5228-5230行) - 新規翻訳
*   **原文**:
    ```text
    touch*stone
    	"Gold is tried by a touchstone, men by gold."
    		[ Chilon (c. 560 BC) ]
    ```
*   **新訳案（散文・格言形式：30〜34文字折り返し）**:
    ```text
    touch*stone
    	「金は試金石によって試され、人間は金によって試される。」
    		［キロン（紀元前５６０年頃） ］
    ```

---

### 【グループ3：小説・詩・ゲームシステム系】

#### ⑬ `tourist` / `* tourist` (5231-5250行) - 新規翻訳
*   **原文**:
    ```text
    tourist
    * tourist
    	The road from Ankh-Morpork to Chrim is high, white and
    	winding, a thirty-league stretch of potholes and half-buried
    	rocks that spirals around mountains and dips into cool green
    	valleys of citrus trees, crosses liana-webbed gorges on
    	creaking rope bridges and is generally more picturesque than
    	useful.
    	Picturesque.  That was a new word to Rincewind the wizard
    	(BMgc, Unseen University [failed]).  It was one of a number
    	he had picked up since leaving the charred ruins of
    	Ankh-Morpork.  Quaint was another one.  Picturesque meant --
    	he decided after careful observation of the scenery that
    	inspired Twoflower to use the word -- that the landscape was
    	horribly precipitous.  Quaint, when used to describe the
    	occasional village through which they passed, meant fever-
    	ridden and tumbledown.
    	Twoflower was a tourist, the first ever seen on the discworld.
    	Tourist, Rincewind had decided, meant "idiot".
    		[ The Colour of Magic, by Terry Pratchett ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tourist
    * tourist
    	アンク＝モープルクからクリムへの道は、高く、白く、
    	曲がりくねっており、山々を回り込み、柑橘類の木々の涼しい緑の
    	谷へと下り、きしむロープの橋でリアナ（蔓）の張られた峡谷を渡る、
    	穴ぼこと半分埋まった岩からなる３０リーグの区間であり、
    	一般的に実用的というよりは絵画的であった。
    	絵画的（ピクチャレスク）。それは魔法使いリンスウィンド（
    	見えざる大学［中退］）にとって新しい言葉だった。それは彼が
    	灰と化したアンク＝モープルクの廃墟を去って以来、身につけた
    	いくつかの言葉の１つだった。古風で趣のある（クエイント）も
    	その１つだった。絵画的とは――ツーフラワーがその言葉を使う
    	きっかけとなった景色を注意深く観察した後に彼が判断したところでは――
    	風景が恐ろしく険しいことを意味していた。古風で趣のあるとは、
    	彼らが通り過ぎる時折の村を描写する際に使われ、疫病が蔓延し、
    	荒れ果てていることを意味していた。
    	ツーフラワーは観光客（ツーリスト）であり、ディスクワールドで
    	これまでに目撃された最初の人物だった。観光客とは、リンスウィンドの
    	判断によれば、「馬鹿」という意味だった。
    		［『魔法の光（ディスクワールド）』、
    		  テリー・プラチェット著 ］
    ```

#### ⑭ `towel` / `wet towel` / `moist towel` (5251-5272行) - 新規翻訳
*   **原文**:
    ```text
    towel
    wet towel
    moist towel
    	The Hitchhiker's Guide to the Galaxy has a few things to say
    	on the subject of towels.
    	A towel, it says, is about the most massively useful thing
    	an interstellar hitchhiker can have.  Partly it has great
    	practical value.  You can wrap it around you for warmth as
    	you bound across the cold moons of Jaglan Beta; you can lie
    	on it on the brilliant marble-sanded beaches of Santraginus
    	V, inhaling the heady sea vapors; you can sleep under it
    	beneath the stars which shine so redly on the desert world
    	of Kakrafoon; use it to sail a miniraft down the slow heavy
    	River Moth; wet it for use in hand-to-hand combat; wrap it
    	round your head to ward off noxious fumes or avoid the gaze
    	of the Ravenous Bugblatter Beast of Traal (a mind-bogglingly
    	stupid animal, it assumes that if you can't see it, it can't
    	see you - daft as a brush, but very very ravenous); you can
    	wave your towel in emergencies as a distress signal, and of
    	course dry yourself off with it if it still seems to be clean
    	enough.
    	  [ The Hitchhiker's Guide to the Galaxy, by Douglas Adams ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    towel
    wet towel
    moist towel
    	『銀河ヒッチハイク・ガイド』には、タオルのテーマについて
    	いくつかの記述がある。
    	タオルは、星間ヒッチハイカーが持ちうる最も大規模に有用な
    	ものである、と記されている。部分的には、それには大きな
    	実用的価値がある。ジャグラン・ベータの冷たい月を飛び越える際に
    	身にまとって暖を取ることができ；サントラギヌス５世の輝く
    	大理石の砂のビーチに横たわって、頭の痛くなるような海の蒸気を
    	吸い込むことができ；カクラフーンの砂漠世界で非常に赤く輝く
    	星々の下でその下で眠ることができ；緩やかで重いモス川を
    	ミニいかだで下るための帆として使用でき；接近戦での使用のために
    	湿らせることができ；有害な煙を避けるため、あるいはトラールの
    	貪欲なバグブラッター・ビーストの視線を避けるために頭に巻くことが
    	できる（この気が遠くなるほど愚かな動物は、あなたがそれを見えなければ、
    	それもあなたを見えないと仮定する――ブラシのように間抜けだが、
    	非常に非常に貪欲である）；緊急時には救難信号としてタオルを振る
    	ことができ、そしてもちろん、まだ十分に清潔であるように見えれば、
    	それで体を拭いて乾かすことができる。
    		［『銀河ヒッチハイク・ガイド』、ダグラス・アダムス著 ］
    ```

#### ⑮ `*tower` / `*tower of darkness` (5273-5281行) - 新規翻訳
*   **原文**:
    ```text
    *tower
    *tower of darkness
    	Towers (_brooding_, _dark_) stand alone in Waste Areas and
    	almost always belong to Wizards.  All are several stories high,
    	round, doorless, virtually windowless, and composed of smooth
    	blocks of masonry that make them very hard to climb. [...]
    	You will have to go to a Tower and then break into it at some
    	point towards the end of your Tour.
    	  [ The Tough Guide to Fantasyland, by Diana Wynne Jones ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *tower
    *tower of darkness
    	塔（重苦しい、暗い）は荒野の中にぽつんと立っており、
    	ほぼ常に魔法使いのものである。すべて数階建ての高さで、
    	丸く、入り口がなく、実質的に窓もなく、滑らかな石造りの
    	ブロックで構成されているため、登るのが非常に難しい。［……］
    	あなたは塔へ行き、それからツアーの終わりのある時点で
    	そこへ押し入らなければならない。
    		［『ファンタジーランドのタフ・ガイド』、
    		  ダイアナ・ウィン・ジョーンズ著 ］
    ```

#### ⑯ `trap*door` (5282-5290行) - 新規翻訳
*   **原文**:
    ```text
    trap*door
    	I knew my Erik too well to feel at all comfortable on jumping
    	into his house.  I knew what he had made of a certain palace at
    	Mazenderan.  From being the most honest building conceivable, he
    	soon turned it into a house of the very devil, where you could
    	not utter a word but it was overheard or repeated by an echo.
    	With his trap-doors the monster was responsible for endless
    	tragedies of all kinds.
    		[ The Phantom of the Opera, by Gaston Leroux ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    trap*door
    	私はエリックをよく知っていたので、彼の家に飛び込むことに
    	全く安心感を持てなかった。マゼンデランの特定の宮殿で彼が
    	何をしたかを私は知っていた。考えうる限り最も実直な建物だった
    	場所から、彼はすぐにそこをまさに悪魔の家へと変えてしまい、
    	そこではあなたが言葉を発すれば、それが盗み聞きされるか、
    	あるいは反響によって繰り返されるのだった。
    	彼の落とし戸によって、その怪物はあらゆる種類の果てしない
    	惨劇に責任を負っていた。
    		［『オペラ座の怪人』、ガストン・ルルー著 ］
    ```

#### ⑰ `trapper` / `trapper or lurker above` (5291-5298行) - 新規翻訳
*   **原文**:
    ```text
    trapper
    trapper or lurker above
    	The trapper is a creature which has evolved a chameleon-like
    	ability to blend into the dungeon surroundings.  It captures
    	its prey by remaining very still and blending into the
    	surrounding dungeon features, until an unsuspecting creature
    	passes by.  It wraps itself around its prey and digests it.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    trapper
    trapper or lurker above
    	トラッパーは、ダンジョンの周囲の環境に溶け込むカメレオンのような
    	能力を進化させた生物である。非常に静かに留まり、周囲のダンジョンの
    	特徴に溶け込むことで獲物を捕らえ、無警戒な生き物が通りかかるのを
    	待つ。獲物に巻き付き、それを消化する。
    ```

#### ⑱ `tree` (5299-5312行) - 新規翻訳
*   **原文**:
    ```text
    tree
    	I think that I shall never see
    	A poem lovely as a tree.
    	A tree whose hungry mouth is prest
    	Against the earth's sweet flowing breast;
    	A tree that looks at God all day,
    	And lifts her leafy arms to pray;
    	A tree that may in Summer wear
    	A nest of robins in her hair;
    	Upon whose bosom snow has lain;
    	Who intimately lives with rain.
    	Poems are made by fools like me,
    	But only God can make a tree.
    		[ Trees, by Joyce Kilmer ]
    ```
*   **新訳案（詩のリズム・改行を維持、全角34文字以下）**:
    ```text
    tree
    	私は決して見ることがないと思う
    	樹木ほど愛らしい詩を。
    	飢えた口を押し当てている樹木
    	大地の甘く流れる胸に対して；
    	一日中神を見つめている樹木、
    	そして祈るために葉の茂った腕を持ち上げる；
    	夏に身にまとうかもしれない樹木
    	髪の中にコマツグミの巣を；
    	その胸の上に雪が横たわった；
    	雨と親密に暮らしている。
    	詩は私のような愚か者によって作られるが、
    	神だけが樹木を作ることができる。
    		［「樹木」、ジョイス・キルマー著 ］
    ```

---

### 【グループ4：北欧神話・小説・武器系】

#### ⑲ `tripe` / `tripe ration` (5313-5324行) - 新規翻訳
*   **原文**:
    ```text
    tripe
    tripe ration
    	If you start from scratch, cooking tripe is a long-drawn-out
    	affair.  Fresh whole tripe calls for a minimum of 12 hours of
    	cooking, some time-honored recipes demanding as much as 24.
    	To prepare fresh tripe, trim if necessary.  Wash it thoroughly,
    	soaking overnight, and blanch, for 1/2 hour in salted water.
    	Wash well again, drain and cut for cooking.  When cooked, the
    	texture of tripe should be like that of soft gristle.  More
    	often, alas, because the heat has not been kept low enough,
    	it has the consistency of wet shoe leather.
    		[ Joy of Cooking, by I Rombauer and M Becker ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tripe
    tripe ration
    	一から始める場合、トリッパを調理するのは長引く仕事である。
    	新鮮な丸ごとのトリッパは最低１２時間の調理が必要で、
    	一部の由緒あるレシピでは２４時間も要求される。
    	新鮮なトリッパを準備するには、必要に応じてトリミングする。
    	それを徹底的に洗い、一晩浸し、塩水で３０分間湯がく。
    	再びよく洗い、水気を切り、調理用に切る。調理されたとき、
    	トリッパの質感は柔らかい軟骨のようであるべきだ。
    	悲しいかな、火力があまり低く保たれなかったために、
    	濡れた靴革のような硬さになってしまうことがよくある。
    	  ［『料理の喜び』、アイ・ロンバウアー＆Ｍ・ベッカー著 ］
    ```

#### ⑳ `~water troll` / `*troll` (5325-5341行) - 新規翻訳
*   **原文**:
    ```text
    ~water troll
    *troll
    	The troll shambled closer.  He was perhaps eight feet tall,
    	perhaps more.  His forward stoop, with arms dangling past
    	thick claw-footed legs to the ground, made it hard to tell.
    	The hairless green skin moved upon his body.  His head was a
    	gash of a mouth, a yard-long nose, and two eyes which drank
    	the feeble torchlight and never gave back a gleam.
    	[...]
    	Like a huge green spider, the troll's severed hand ran on its
    	fingers.  Across the mounded floor, up onto a log with one
    	taloned forefinger to hook it over the bark, down again it
    	scrambled, until it found the cut wrist.  And there it grew
    	fast.  The troll's smashed head seethed and knit together.
    	He clambered back on his feet and grinned at them.  The
    	waning faggot cast red light over his fangs.
    		[ Three Hearts and Three Lions, by Poul Anderson ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    ~water troll
    *troll
    	トロールはよろよろと近づいてきた。身長は８フィート、
    	あるいはそれ以上だったかもしれない。太く鉤爪のある脚の先を
    	地面につけて腕をぶら下げた前かがみの姿勢のため、見分けるのは
    	困難だった。毛のない緑色の皮膚が彼の体の上で動いていた。
    	彼の頭は裂けたような口、１ヤードの長さの鼻、および弱々しい
    	たいまつの光を吸い込んで一筋の輝きも返さない２つの目だった。
    	［……］
    	巨大な緑色の蜘蛛のように、トロール of 切り離された手は
    	その指で走った。盛り上がった床を横切り、１本の鉤爪のある
    	人差し指を樹皮に引っ掛けて丸太の上に登り、再び降りて、
    	切り取られた手首を見つけるまで這い回った。そしてそこで
    	それは急速に接合した。トロールの砕かれた頭は沸き立ち、
    	編み合わされた。彼は再び足でよじ登り、彼らに向かってにやりと笑った。
    	衰えゆく薪が彼の牙の上に赤い光を投げかけた。
    		［『魔界の紋章』、ポール・アンダースン著 ］
    ```
    ※誤変換 `of` を `の` に修正して適用します。

#### ㉑ `*tsurugi of muramasa` (5342-5348行) - 新規翻訳
*   **原文**:
    ```text
    *tsurugi of muramasa
    	This most ancient of swords has been passed down through the
    	leadership of the Samurai legions for hundreds of years.  It
    	is said to grant luck to its wielder, but its main power is
    	terrible to behold.  It has the capability to cut in half any
    	creature it is wielded against, instantly killing them.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *tsurugi of muramasa
    	この最も古代の剣は、何百年もの間、侍の軍団の指導者の間で
    	受け継がれてきた。使い手に幸運をもたらすと言われているが、
    	その主な力は見るのも恐ろしい。これを使用する相手である
    	いかなる生き物も真っ二つに切り裂き、即座に死に至らしめる
    	能力を持っている。
    ```

#### ㉒ `tsurugi` (5349-5355行) - 新規翻訳
*   **原文**:
    ```text
    tsurugi
    	The tsurugi, also known as the long samurai sword, is an
    	extremely sharp, two-handed blade favored by the samurai.
    	It is made of hardened steel, and is manufactured using a
    	special process, causing it to never rust.  The tsurugi is
    	rumored to be so sharp that it can occasionally cut
    	opponents in half!
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tsurugi
    	ツルギ（侍の長剣としても知られる）は、侍に好まれる
    	非常に鋭い両手持ちの刃である。硬化鋼で作られており、
    	特殊なプロセスを使用して製造されているため、決して錆びない。
    	ツルギは非常に鋭く、時折相手を真っ二つに切り裂くことができると
    	噂されている！
    ```

#### ㉓ `turquoise*` (5357-5367行) - 新規翻訳
*   **原文**:
    ```text
    turquoise*
    	TUBAL:  There came divers of Antonio's creditors in my company
    	to Venice that swear he cannot choose but break.
    	SHYLOCK:  I am very glad of it; I'll plague him, I'll torture
    	him; I am glad of it.
    	TUBAL:  One of them showed me a ring that he had of your
    	daughter for a monkey.
    	SHYLOCK:  Out upon her!  Thou torturest me, Tubal.  It was my
    	turquoise; I had it of Leah when I was a bachelor; I would
    	not have given it for a wilderness of monkeys.
    		[ The Merchant of Venice, by William Shakespeare ]
    ```
*   **新訳案（会話劇形式：各発言の折り返しとインデントを維持）**:
    ```text
    turquoise*
    	テュバル：会社の中にアントニオの債権者たちが色々と
    	          ヴェニスに来ておりまして、彼は破産するしかないと
    	          誓っております。
    	シャイロック：それは非常に嬉しい！ 悩ませてやる、拷問してやる；
    	              嬉しいぞ。
    	テュバル：彼らの１人が、お前の娘が猿１匹と引き換えに渡したという
    	          指輪を見せてくれました。
    	シャイロック：とんでもない！ 拷問する気か、テュバル。それは私の
    	              トルコ石だった；独身だった頃にレアから貰ったものだ；
    	              猿の荒野（何百匹もの猿）と引き換えであっても
    	              手放さなかったものを。
    		［『ベニスの商人』、ウィリアム・シェイクスピア著 ］
    ```

#### ㉔ `tyr` (5389-5403行) - 新規翻訳
*   **原文**:
    ```text
    tyr
    	Yet remains that one of the Aesir who is called Tyr:
    	he is most daring, and best in stoutness of heart, and he
    	has much authority over victory in battle; it is good for
    	men of valor to invoke him.  It is a proverb, that he is
    	Tyr-valiant, who surpasses other men and does not waver.
    	He is wise, so that it is also said, that he that is wisest
    	is Tyr-prudent.  This is one token of his daring:  when the
    	Aesir enticed Fenris-Wolf to take upon him the fetter Gleipnir,
    	the wolf did not believe them, that they would loose him,
    	until they laid Tyr's hand into his mouth as a pledge.  But
    	when the Aesir would not loose him, then he bit off the hand
    	at the place now called 'the wolf's joint;' and Tyr is one-
    	handed, and is not called a reconciler of men.
    			[ The Prose Edda, by Snorri Sturluson ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    tyr
    	アース神族の中でティールと呼ばれる者がまだ残っている：
    	彼は最も大胆であり、心の頑強さにおいて最も優れており、
    	戦闘での勝利に対して大きな権威を持っている；勇気ある人々が
    	彼を呼び求めるのは良いことである。他の人々を凌駕し、
    	揺らぐことのない者はティールのごとく勇敢（ティール＝ヴァリアント）
    	である、という諺がある。彼は賢明であり、最も賢い者は
    	ティールのごとく慎重（ティール＝プルーデント）であるとも
    	言われる。これは彼の大胆さの１つの証である：アース神族が
    	フェンリス狼を誘惑して束縛具グレイプニルをはめようとした際、
    	狼は彼らが自分を解放してくれるとは信じなかった、彼らが誓約として
    	ティールの手を彼の口の中に置くまでは。しかしアース神族が
    	彼を解放しようとしなかったとき、彼は現在「狼の関節」と
    	呼ばれる場所でその手を噛み切った；指示ティールは片手になり、
    	人々の調停者とは呼ばれなくなった。
    			［『散文のエッダ』、スノッリ・ストゥルルソン著 ］
    ```
    ※誤字 `指示ティール` は `そしてティール` に修正して適用します。

---

## 4. 安全な適用のための検証計画
グループごとに置換を適用した後は、必ず `dat/` ディレクトリにて `..\tools\Debug\x64\makedefs.exe -d` によるビルドテストを行い、`git diff` で誤変換（`of` 誤字）が無いかを徹底的に目視検証します。
計画は以上です。
