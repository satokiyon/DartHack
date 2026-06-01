<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. -->
# NetHackJP `dat/data_jp.base` Wブロック日本語翻訳計画

## 1. 目的と方針
`dat/data_jp.base` に含まれる、「w」「*w」「* w」で始まる単語キー（Wブロック）のゲーム内百科事典解説文について、NetHack の世界観と引用元の雰囲気を尊重しつつ、自然な日本語に翻訳します。

### 翻訳基本ルール:
*   **折り返し**: 通常の散文は、既存のルールに従い **1行あたり全角30〜34文字（最大34文字）** の範囲内で美しく折り返します。
*   **会話劇・ポエム・引用の形式**: 原文が対話形式や詩、あるいは短い発言行で構成されているものは、そのオリジナルの改行形式とインデント、およびリズムを維持して自然な日本語で翻訳します。
*   **引用元の日本語化**: 引用元のタイトルや著者名も自然な日本語に翻訳して `［『書名』、著者名著 ］` の形式を厳守します。
*   **構文厳守**: 行頭の検索キー（インデントなし）と説明文（TAB開始）の構造を絶対に維持します。またプレースホルダや `#` コメント行は変更・削除禁止です。
*   **誤変換の防止**: 助詞の「の」が `of` に誤変換されるバグ等が入らないよう、適用時に細心の注意を払い、`git diff` で徹底的に検証します。

---

## 2. 段階的作業計画（グループ分割）
Wブロックは全21項目あるため、安全と正確性を考慮し、2つのグループに分けて段階的に適用・検証を行います。

| グループ | 対象キー範囲 | 項目数 | 主な内容 | 状態 |
| :--- | :--- | :--- | :--- | :---: |
| **グループ1** | `wakizashi` 〜 `win` | 12項目 | 脇差、魔法の杖（トールキン）、ワーグ（トールキン）、戦鎚（氷と炎の歌）、海（コールリッジ）、水魔、水トロール、兵器、蜘蛛の巣、口笛（怪談）、塚人、勝利のルール | 未着手 |
| ****グループ2** | `wizard` 〜 `*wumpus` | 9項目 | 魔法使い、イェンダーの魔法使い、オオカミ、トリカブト、木ゴーレム（ゲーテの詩）、ウッドチャック、砂虫/クリスナイフ（デューン）、ナズグル（トールキン）、ワンプス | 未着手 |

### 進捗状況
- [x] **グループ1の適用と検証** (12/12 完了)
  - [x] `wakizashi` の日本語翻訳を適用
  - [x] `wand *` / `*wand` の日本語翻訳を適用
  - [x] `warg` の日本語翻訳を適用
  - [x] `war*hammer` の日本語翻訳を適用
  - [x] `water` の日本語翻訳を適用
  - [x] `water demon` の日本語翻訳を適用
  - [x] `water troll` の日本語翻訳を適用
  - [x] `weapon` / `club` / `flail` / `~*broadsword` / `~sunsword` / `*sword` の日本語翻訳を適用
  - [x] `web` の日本語翻訳を適用
  - [x] `*whistle` の日本語翻訳を適用
  - [x] `*wight` の日本語翻訳を適用
  - [x] `win` / `winner` / `winning` の日本語翻訳を適用
  - [x] グループ1適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)
- [x] **グループ2の適用と検証** (9/9 完了)
  - [x] `wizard` / `* wizard` / `apprentice` の日本語翻訳を適用
  - [x] `wizard of yendor` の日本語翻訳を適用
  - [x] `wolf` / `*wolf` / `*wolf cub` の日本語翻訳を適用
  - [x] `*wolfsbane` の日本語翻訳を適用
  - [x] `wood golem` の日本語翻訳を適用
  - [x] `woodchuck` の日本語翻訳を適用
  - [x] `*worm` / `long worm tail` / `worm tooth` / `crysknife` の日本語翻訳を適用
  - [x] `wraith` / `nazgul` の日本語翻訳を適用
  - [x] `*wumpus` の日本語翻訳を適用
  - [x] グループ2適用後の `git diff` による差分確認（`of` 誤字チェック）
  - [x] `makedefs -d` によるビルド検証とステージング (`git add`)

---

## 3. 各グループの詳細翻訳設計案（新訳案）

### 【グループ1：`wakizashi` 〜 `win`】

#### ① `wakizashi` (5516-5526行) - 新規翻訳
*   **原文**:
    ```text
    wakizashi
    	A wakizashi was used as a samurai's weapon when the katana
    	was unavailable.  When entering a building, a samurai would
    	leave his katana on a rack near the entrance.  However, the
    	wakizashi would be worn at all times, and therefore, it made
    	a sidearm for the samurai (similar to a soldier's use of a
    	pistol).  The samurai would have worn it from the time they
    	awoke to the time they went to sleep.  In earlier periods,
    	and especially during times of civil wars, a tanto was worn
    	in place of a wakizashi.
    		[ Wikipedia, the free encyclopedia ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    wakizashi
    	脇差は、カタナ（刀）が手元にないときのサムライの武器として
    	使用された。建物に入る際、サムライはカタナを入り口近くの
    	棚（刀掛け）に残した。しかし、脇差は常に身につけられており、
    	それゆえにサムライの補助兵器（兵士がピストルを使用するのと
    	同様）となった。サムライは目覚めてから眠るまでそれを
    	身につけていた。初期の時代、特に戦国時代には、脇差の代わりに
    	短刀が身につけられた。
    		［ Wikipedia フリー百科事典 ］
    ```

#### ② `wand *` / `*wand` (5529-5540行) - 新規翻訳
*   **原文**:
    ```text
    wand *
    *wand
    	'Saruman!' he cried, and his voice grew in power and authority.
    	'Behold, I am not Gandalf the Grey, whom you betrayed.  I am
    	Gandalf the White, who has returned from death.  You have no
    	colour now, and I cast you from the order and from the Council.'
    	He raised his hand, and spoke slowly in a clear cold voice.
    	'Saruman, your staff is broken.'  There was a crack, and the
    	staff split asunder in Saruman's hand, and the head of it
    	fell down at Gandalf's feet.  'Go!' said Gandalf.  With a cry
    	Saruman fell back and crawled away.
    		[ The Two Towers, by J.R.R. Tolkien ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    wand *
    *wand
    	「サルマン！」と彼は叫び、その声は力と威厳を増した。
    	「見よ、私はお前が裏切った灰色 の ガンダルフではない。私は
    	死から帰還した白きガンダルフだ。お前にはもう色はない。
    	お前を賢者 の 結社からも、会議からも追放する。」
    	彼は手を上げ、澄んだ冷たい声でゆっくりと話した。
    	「サルマン、お前 の 杖は折れた。」鋭い音がして、杖はサルマンの
    	手の中で真っ二つに裂け、その頭部がガンダルフの足元に
    	落ちた。「去れ！」とガンダルフは言った。叫び声を上げて
    	サルマンは後退し、這うようにして去っていった。
    		［『二つの塔』、Ｊ・Ｒ・Ｒ・トールキン著 ］
    ```

#### ③ `warg` (5541-5558行) - 新規翻訳
*   **原文**:
    ```text
    warg
    	Suddenly Aragorn leapt to his feet.  "How the wind howls!"
    	he cried.  "It is howling with wolf-voices.  The Wargs have
    	come west of the Mountains!"
    	"Need we wait until morning then?" said Gandalf.  "It is as I
    	said.  The hunt is up!  Even if we live to see the dawn, who
    	now will wish to journey south by night with the wild wolves
    	on his trail?"
    	"How far is Moria?" asked Boromir.
    	"There was a door south-west of Caradhras, some fifteen miles
    	as the crow flies, and maybe twenty as the wolf runs,"
    	answered Gandalf grimly.
    	"Then let us start as soon as it is light tomorrow, if we can,"
    	said Boromir.  "The wolf that one hears is worse than the orc
    	that one fears."
    	"True!" said Aragorn, loosening his sword in its sheath.  "But
    	where the warg howls, there also the orc prowls."
    		[ The Fellowship of the Ring, by J.R.R. Tolkien ]
    ```
*   **新訳案（対話劇形式：改行・インデント・リズムを維持）**:
    ```text
    warg
    	突然アラゴルンが立ち上がった。「なんと風がうなることか！」
    	と彼は叫んだ。「狼の声でうなっている。ワーグ（魔狼）どもが
    	霧降り山脈の西側に来たのだ！」
    	「では朝まで待つ必要があるかね？」とガンダルフが言った。
    	「私が言った通りだ。狩りが始まった！ たとえ生きて夜明けを
    	迎えたとしても、野性の狼どもに追われながら夜間に南へ
    	旅をしたいと望む者がいるだろうか？」
    	「モリアまではどれくらいだ？」とボロミアが尋ねた。
    	「カラドラスの南西に扉があった。直線距離で１５マイルほど、
    	狼が走る道のりなら２０マイルほどだろう」とガンダルフは
    	険しい表情で答えた。
    	「では、できれば明日明るくなったらすぐに出発しよう」と
    	ボロミアが言った。「耳にする狼は、恐れるオークよりも悪い。」
    	「その通りだ！」とアラゴルンは言い、鞘の中で剣を緩めた。
    	「しかし、ワーグがうなるところ、オークもまたうろつくものだ。」
    		［『旅の仲間』、Ｊ・Ｒ・Ｒ・トールキン著 ］
    ```

#### ④ `war*hammer` (5560-5573行) - 新規翻訳
*   **原文**:
    ```text
    war*hammer
    	They had come together at the ford of the Trident while the
    	battle crashed around them, Robert with his warhammer and his
    	great antlered helm, the Targaryen prince armored all in
    	black.  On his breastplate was the three-headed dragon of his
    	House, wrought all in rubies that flashed like fire in the
    	sunlight.  The waters of the Trident ran red around the
    	hooves of their destriers as they circled and clashed, again
    	and again, until at last a crushing blow from Robert's hammer
    	stove in the dragon and the chest behind it.  When Ned had
    	finally come on the scene, Rhaegar lay dead in the stream,
    	while men of both armies scrambled in the swirling waters for
    	rubies knocked free of his armor.
    		[ A Game of Thrones, by George R.R. Martin ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    war*hammer
    	彼らは周囲で戦闘が激化する中、トライデントの渡しで対峙した。
    	ロバートは戦鎚と巨大な角付きの兜を身につけ、ターガリエンの
    	王子は全身黒の甲冑をまとっていた。彼の胸当てには家紋である
    	三頭の竜が、日光の中で炎のように輝くルビーで精巧に描かれていた。
    	彼らが旋回し、何度も衝突する中、トライデントの川水は彼らの
    	軍馬の蹄の周りで赤く染まった。そしてついに、ロバートの鎚による
    	強烈な一撃が竜とその背後の胸を打ち砕いた。ネッドがようやく
    	その場に到着したとき、レイガーは川の中に死んで横たわっており、
    	両軍の兵士たちが、彼の鎧から叩き落とされたルビーを求めて
    	渦巻く水の中を探し回っていた。
    		［『ゲーム・オブ・スローンズ（氷と炎の歌）』、
    		  ジョージ・Ｒ・Ｒ・マーティン著 ］
    ```

#### ⑤ `water` (5574-5584行) - 新規翻訳
*   **原文**:
    ```text
    water
    	Day after day, day after day,
    	We stuck, nor breath nor motion;
    	As idle as a painted ship
    	Upon a painted ocean.
    
    	Water, water, everywhere,
    	And all the boards did shrink;
    	Water, water, everywhere
    	Nor any drop to drink.
    	  [ The Rime of the Ancient Mariner, by Samuel Taylor Coleridge ]
    ```
*   **新訳案（詩のリズム・改行を維持、全角34文字以下）**:
    ```text
    water
    	来る日も来る日も、来る日も来る日も、
    	我らは立ち往生した、息も動きもなく；
    	描かれた海の上に浮かぶ
    	描かれた船のように物憂げに。
    
    	水、水、至るところに水、
    	そしてすべての甲板の板は縮んだ；
    	水、水、至るところに水、
    	しかし飲むべき水は一滴もない。
    		［『老水夫の歌』、
    		  サミュエル・テイラー・コールリッジ著 ］
    ```

#### ⑥ `water demon` (5585-5607行) - 新規翻訳
*   **原文**:
    ```text
    water demon
    	[ The monkey king ] walked along the bank, around the pond.
    	He examined the footprints of the animals that had gone into
    	the water, and saw that none came out again!  So he realized
    	this pond must be possessed by a water demon.  He said to the
    	80,000 monkeys, "This pond is possessed by a water demon.  Do
    	not let anybody go into it."
    
    	After a little while, the water demon saw that none of the
    	monkeys went into the water to drink.  So he rose out of the
    	middle of the pond, taking the shape of a frightening monster.
    	He had a big blue belly, a white face with bulging green eyes,
    	and red claws and feet.  He said, "Why are you just sitting
    	around?  Come into the pond and drink at once!"
    
    	The monkey king said to the horrible monster, "Are you the
    	water demon who owns this pond?"  "Yes, I am," said he.  "Do
    	you eat whoever goes into the water?" asked the king.  "Yes,
    	I do," he answered, "including even birds.  I eat them all.
    	And when you are forced by your thirst to come into the pond
    	and drink, I will enjoy eating you, the biggest monkey, most
    	of all!"  He grinned, and saliva dripped down his hairy chin.
    		[ Buddhist Tales for Young and Old, Vol. 1 ]
    ```
*   **新訳案（散文・会話劇：30〜34文字折り返し）**:
    ```text
    water demon
    	［アサルの王］は池の周囲の土手を歩いた。彼は水に入った動物の
    	足跡を調査し、戻ってきた足跡が１つもないことに気づいた！
    	そこで彼は、この池が水魔に憑依されているに違いないと悟った。
    	彼は８万匹の猿たちに言った。「この池には水魔が住んでいる。
    	誰も中に入ってはならない。」
    
    	しばらくすると、水魔は猿たちが誰も水を飲みに池に入らない
    	ことに気づいた。そこで彼は恐ろしい怪物の姿をして池の中央から
    	浮き上がってきた。彼は大きな青い腹、突き出た緑の目を持つ
    	白い顔、および赤い爪と足を持っていた。彼は言った。「なぜ
    	ただ座り込んでいる？ すぐに池に入って飲むのだ！」
    
    	猿の王はその恐ろしい怪物に言った。「お前がこの池を所有する
    	水魔か？」「そうだ、私がそうだ」と彼は言った。「水に
    	入る者は誰でも食べるのか？」と王が尋ねた。「そうだ」と
    	彼は答えた。「鳥でさえもな。全員食べる。端くれお前たちが
    	渇きに耐えかねて池に水を飲みに来るとき、私は最も大きな猿である
    	お前を食べるのを何よりも楽しむだろう！」彼はにやりと笑い、
    	毛深いあごから唾液が垂れ落ちた。
    		［『若者と大人のための仏教説話』第１巻 ］
    ```

#### ⑦ `water troll` (5608-5622行) - 新規翻訳
*   **原文**:
    ```text
    water troll
    	It wasn't that the troll was _horrifying_. Instead of the
    	rotting, betentacled monstrosity he had been expecting
    	Rincewind found himself looking at a rather squat but not
    	particularly ugly old man who would quite easily have passed
    	for normal on any city street, always provided that other
    	people on the street were used to seeing old men who were
    	apparently composed of water and very little else. It was as
    	if the ocean had decided to create life without going through
    	all that tedious business of evolution, and had simply formed
    	a part of itself into a biped and sent it walking squishily up
    	the beach. The troll was a pleasant translucent blue color.
    	As Rincewind stared a small shoal of silver fish flashed
    	across its chest.
    	    [ The Colour of Magic, by Terry Pratchett ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    water troll
    	トロールが「恐ろしい」というわけではなかった。腐敗し、
    	触手を持つ怪物を期待していた代わりに、リンスウィンドは
    	都市の通りで通常なら普通に通ったであろう、ずんぐりした、しかし
    	特に醜くはない老人を見つめていることに気づいた。もちろんそれは、
    	通りにいる他の人々が、明らかに水で構成され、他にはほとんど
    	何もない老人を見ることに慣れている場合に限られた。まるで海が、
    	あの退屈な進化のプロセスを経ることなく生命を創造することを決定し、
    	自らの一部を二本足の姿に形成して、ビーチをぐしょぐしょと
    	歩かせたかのようだった。トロールは心地よい半透明の青色を
    	していた。リンスウィンドが凝視していると、銀色の魚の小さな
    	群れが彼の胸をよぎって閃いた。
    		［『魔法の光（ディスクワールド）』、
    		  テリー・プラチェット著 ］
    ```

#### ⑧ `weapon` / `club` / `flail` / `~*broadsword` / `~sunsword` / `*sword` (5626-5633行) - 新規翻訳
*   **原文**:
    ```text
    weapon
    club
    flail
    ~*broadsword
    ~sunsword
    *sword
    	A weapon is a device for making your enemy change his mind.
    		[ The Vor Game, by Lois McMaster Bujold ]
    ```
*   **新訳案（散文・格言形式：30〜34文字折り返し）**:
    ```text
    weapon
    club
    flail
    ~*broadsword
    ~sunsword
    *sword
    	兵器とは、敵に考えを変えさせるための道具である。
    		［『戦士志願（ヴォル・ゲーム）』、
    		  ロイス・マクマスター・ビジョルド著 ］
    ```

#### ⑨ `web` (5634-5637行) - 新規翻訳
*   **原文**:
    ```text
    web
    	Oh what a tangled web we weave,
    	When first we practise to deceive!
    		[ Marmion, by Sir Walter Scott ]
    ```
*   **新訳案（詩のリズム・改行を維持、全角34文字以下）**:
    ```text
    web
    	おお、なんと複雑な蜘蛛の巣を我々は織りなすことか、
    	最初に人を欺くことを試みるときに！
    		［『マーミオン』、サー・ウォルター・スコット著 ］
    ```

#### ⑩ `*whistle` (5639-5653行) - 新規翻訳
*   **原文**:
    ```text
    *whistle
    	There were legends both on the front and on the back of the
    	whistle. The one read thus:

    	FLA FUR BIS FLE The other: QUIS EST ISTE QUI VENIT
    	'I ought to be able to make it out,' he thought;
    	'but I suppose I am a little rusty in my Latin.
    	When I come to think of it, I don't believe I even
    	know the word for a whistle. The long one does seem
    	simple enough. It ought to mean, "Who is this who is coming?"

    	Well, the best way to find out is evidently to whistle
    	for him.'
    		[Ghost Stories of an Antiquary, by Montague Rhodes James
    		 'Oh, Whistle, and I'll Come to You My Lad']
    ```
*   **新訳案（散文・思考の形式：30〜34文字折り返し）**:
    ```text
    *whistle
    	ホイッスル（呼子笛）の前面と背面の両方に文字が刻まれていた。
    	一方は次のように読めた：
    
    	FLA FUR BIS FLE  もう一方は：QUIS EST ISTE QUI VENIT
    	「私にはこれを理解できるはずだ」と彼は考えた；
    	「しかし私のラテン語は少し錆びついているようだ。考えてみれば、
    	ホイッスルを表す言葉さえ知っているとは思えない。長い方は
    	十分に単純なようだ。それは『来つつあるこの者は誰か？』という
    	意味に違いない。
    
    	まあ、それを確かめる最善の方法は、明らかに彼を呼ぶために
    	口笛を吹くことだ。」
    		［『好古家の怪談集』、Ｍ・Ｒ・ジェイムズ著 
    		  「おお、口笛を吹けば、私は行くよ、我が子よ」 ］
    ```

#### ⑪ `*wight` (5655-5664行) - 新規翻訳
*   **原文**:
    ```text
    *wight
    	When he came to himself again, for a moment he could recall
    	nothing except a sense of dread.  Then suddenly he knew that
    	he was imprisoned, caught hopelessly; he was in a barrow.  A
    	Barrow-wight had taken him, and he was probably already under
    	the dreadful spells of the Barrow-wights about which whispered
    	tales spoke.  He dared not move, but lay as he found himself:
    	flat on his back upon a cold stone with his hands on his
    	breast.
    		[ The Fellowship of the Ring, by J.R.R. Tolkien ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *wight
    	再び意識を取り戻したとき、彼は一瞬、恐怖感以外には何も
    	思い出すことができなかった。それから突然、自分が捕らえられ、
    	絶望的に閉じ込められていることを知った；彼は塚（バロウ）の中に
    	いた。塚人（バロウ＝ワイト）が彼を連れ去ったのだ。彼は十中八九、
    	噂話で語られる塚人の恐ろしい呪文の下にすでに置かれていた。
    	彼は動く勇気が出ず、自分が置かれたままの姿勢で横たわっていた：
    	冷たい石の上に仰向けになり、胸の上に両手を置いて。
    		［『旅の仲間』、Ｊ・Ｒ・Ｒ・トールキン著 ］
    ```

#### ⑫ `win` / `winner` / `winning` (5665-5673行) - 新規翻訳
*   **原文**:
    ```text
    win
    winner
    winning
    	... the rules of Brockian Ultra Cricket, as played in the higher
    	dimensions.  A full set of rules is so massively complicated ...
    	A brief summary, however, follows:
    	...
    	/Rule Six/:  The winning team shall be the first team that wins.
    	    [ Life, the Universe and Everything, by Douglas Adams ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    win
    winner
    winning
    	……高次元でプレイされるブロッキャン・ウルトラ・クリケットの
    	ルール。完全なルールセットは非常に大規模に複雑である……
    	しかし、簡単な要約は以下の通り：
    	……
    	／第６ルール／：勝利チームとは、最初に勝利したチームとする。
    		［『宇宙の果てのレストラン』、ダグラス・アダムス著 ］
    ```

---

### 【グループ2：`wizard` 〜 `*wumpus`】

#### ⑬ `wizard` / `* wizard` / `apprentice` (5675-5685行) - 新規翻訳
*   **原文**:
    ```text
    ~gnomish wizard
    wizard
    * wizard
    apprentice
    	Ebenezum walked before me along the closest thing we could
    	find to a path in these overgrown woods.  Every few paces he
    	would pause, so that I, burdened with a pack stuffed with
    	arcane and heavy paraphernalia, could catch up with his
    	wizardly strides.  He, as usual, carried nothing, preferring,
    	as he often said, to keep his hands free for quick conjuring
    	and his mind free for the thoughts of a mage.
    		[ A Dealing with Demons, by Craig Shaw Gardner ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    ~gnomish wizard
    wizard
    * wizard
    apprentice
    	エベネザムは、この草の生い茂った森の中で我々が見つけられた
    	小道に最も近い場所を通って、私の前を歩いた。数歩歩くごとに
    	彼は立ち止まり、難解で重い道具が詰め込まれたパックを背負った
    	私が、彼の魔法使いらしい大股の歩みに追いつけるようにした。
    	彼はいつものように何も持たず、よく言っていたように、素早い
    	召喚のために両手を空けておき、魔術師の思考のために心を
    	自由にしておくことを好んだ。
    		［『悪魔との取引』、クレイグ・ショー・ガードナー著 ］
    ```

#### ⑭ `wizard of yendor` (5686-5696行) - 新規翻訳
*   **原文**:
    ```text
    wizard of yendor
    	No one knows how old this mighty wizard is, or from whence he
    	came.  It is known that, having lived a span far greater than
    	any normal man's, he grew weary of lesser mortals; and so,
    	spurning all human company, he forsook the dwellings of men
    	and went to live in the depths of the Earth.  He took with
    	him a dreadful artifact, the Book of the Dead, which is said
    	to hold great power indeed.  Many have sought to find the
    	wizard and his treasure, but none have found him and lived to
    	tell the tale.  Woe be to the incautious adventurer who
    	disturbs this mighty sorcerer!
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    wizard of yendor
    	この強力な魔法使いが何歳なのか、あるいはどこから来たのかは
    	誰も知らない。普通の人間よりはるかに長い寿命を生きた彼は、
    	低俗な凡人たちに飽き飽きしたことが知られている；こうして、
    	あらゆる人間の付き合いを拒絶し、彼は人間の住処を捨てて
    	地底の深淵へと移り住んだ。彼は実に強大な力を秘めているとされる
    	恐ろしいアーティファクト「死者の書」を携えていった。
    	多くの者がその魔法使いと財宝を見つけようと試みたが、誰一人として
    	彼を見つけ出し、生きてその話を語ることはできなかった。
    	この強力な魔術師の眠りを妨げる、不注意な冒険者には災いあれ！
    ```

#### ⑮ `wolf` / `*wolf` / `*wolf cub` (5697-5704行) - 新規翻訳
*   **原文**:
    ```text
    wolf
    *wolf
    *wolf cub
    	The ancestors of the modern day domestic dog, wolves are
    	powerful muscular animals with bushy tails.  Intelligent,
    	social animals, wolves live in family groups or packs made
    	up of multiple family units.  These packs cooperate in hunting
    	down prey.
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    wolf
    *wolf
    *wolf cub
    	現代の飼い犬の祖先であるオオカミは、ふさふさした尾を持つ、
    	強力で筋肉質の動物である。知的で社会的な動物であり、
    	オオカミは複数の家族単位で構成される家族グループまたは群れ（
    	パック）を作って暮らす。これらの群れは協力して獲物を
    	狩り立てる。
    ```

#### ⑯ `*wolfsbane` (5705-5714行) - 新規翻訳
*   **原文**:
    ```text
    *wolfsbane
    	1.  Any of various, usually poisonous perennial herbs of the
    	genus Aconitum, having tuberous roots, palmately lobed leaves,
    	blue or white flowers with large hoodlike upper sepals, and an
    	aggregate of follicles.  2.  The dried leaves and roots of
    	some of these plants, which yield a poisonous alkaloid that
    	was formerly used medicinally.  In both senses also called
    	monkshood.
    		[ The American Heritage Dictionary of
    		    the English Language, Fourth Edition. ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *wolfsbane
    	1. トリカブト属の様々な、通常は有毒な多年草の総称。塊根、
    	掌状に裂けた葉、大きな頭巾状の上部萼片を持つ青または白の花、
    	および袋果の集合体を持つ。2. これらの一部の植物の乾燥した
    	葉と根で、かつては薬用として使用されていた有毒アルカロイドを
    	産出するもの。両方の意味においてモンクスフード（僧侶の頭巾）
    	とも呼ばれる。
    		［『アメリカン・ヘリテージ英語辞典』第４版 ］
    ```

#### ⑰ `wood golem` (5715-5734行) - 新規翻訳
*   **原文**:
    ```text
    wood golem
    	Come, old broomstick, you are needed,
    	Take these rags and wrap them round you!
    	Long my orders you have heeded,
    	By my wishes now I've bound you.
    	Have two legs and stand,
    	And a head for you.
    	Run, and in your hand
    	Hold a bucket too.
    	...
    	See him, toward the shore he's racing
    	There, he's at the stream already,
    	Back like lightning he is chasing,
    	Pouring water fast and steady.
    	Once again he hastens!
    	How the water spills,
    	How the water basins
    	Brimming full he fills!
    	  [ The Sorcerer's Apprentice, by Johann Wolfgang von Goethe,
    	      translation by Edwin Zeydel ]
    ```
*   **新訳案（詩のリズム・改行を維持、全角34文字以下）**:
    ```text
    wood golem
    	来い、古いほうきよ、お前が必要だ、
    	これらのボロ布を取って、お前に巻きつけろ！
    	長らくお前は私の命令に耳を傾けてきた、
    	今や私の望みによって、お前を縛りつけた。
    	二本足を持って立ち上がれ、
    	お前のための頭もあるぞ。
    	走れ、そしてお前の手に
    	バケツも持つんだ。
    	……
    	見よ、彼は岸に向かって疾走している
    	ほら、彼はもう小川に達している、
    	稲妻のように彼は引き返して追跡し、
    	素早く着実に水を注いでいる。
    	もう一度彼は急ぐ！
    	なんと水がこぼれることか、
    	なんと水桶が
    	縁までいっぱいに満たされることか！
    		［『魔法使いの弟子』、
    		  ヨハン・ヴォルフガング・フォン・ゲーテ著、
    		  エドウィン・ザイデル訳 ］
    ```

#### ⑱ `woodchuck` (5735-5748行) - 新規翻訳
*   **原文**:
    ```text
    woodchuck
    	The Usenet Oracle requires an answer to this question!
    
    	> How much wood could a woodchuck chuck if a woodchuck could
    	> chuck wood?
    
    	"Oh, heck!  I'll handle *this* one!"  The Oracle spun the terminal
    	back toward himself, unlocked the ZOT-guard lock, and slid the
    	glass guard away from the ZOT key.  "Ummmm....could you turn around
    	for a minute?  ZOTs are too graphic for the uninitiated.  Even *I*
    	get a little squeamish sometimes..."  The neophyte turned around,
    	and heard the Oracle slam his finger on a computer key, followed
    	by a loud ZZZZOTTTTT and the smell of ozone.
    		[ Excerpted from Internet Oracularity 576.6 ]
    ```
*   **新訳案（散文・対話形式：30〜34文字折り返し）**:
    ```text
    woodchuck
    	ユーズネットの神託（オラクル）はこの質問への回答を求めている！
    
    	＞ ウッドチャックが木を投げられるとしたら、
    	＞ ウッドチャックはどれほどの木を投げるだろうか？
    
    	「ああ、もう！ これの処理は私が引き受けよう！」オラクルは
    	端末を自分の方に回転させ、ZOTガードのロックを解除し、ZOTキーから
    	ガラスの保護カバーをスライドさせて外した。「うーん……ちょっと
    	後ろを向いていてくれないか？ ZOTは未経験者にはグラフィックが
    	強烈すぎるんだ。私でさえ時々少しゾッとするほどだからね……」
    	初心者は後ろを向き、オラクルがコンピュータのキーに指を叩きつける
    	のを聞いた。それに続いて大きな『ZZZZOTTTTT』という音がし、
    	オゾンの臭いが漂ってきた。
    		［ Internet Oracularity 576.6 より抜粋 ］
    ```

#### ⑲ `*worm` / `long worm tail` / `worm tooth` / `crysknife` (5749-5758行) - 新規翻訳
*   **原文**:
    ```text
    *worm
    long worm tail
    worm tooth
    crysknife
    	[The crysknife] is manufactured in two forms from teeth taken
    	from dead sandworms.  The two forms are "fixed" and "unfixed".
    	An unfixed knife requires proximity to a human body's
    	electrical field to prevent disintegration.  Fixed knives
    	are treated for storage.  All are about 20 centimeters long.
    		[ Dune, by Frank Herbert ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *worm
    long worm tail
    worm tooth
    crysknife
    	［クリスナイフ］は、死んだサンドワームから採取された歯から
    	２つの形態で製造される。その２つの形態とは「固定（固定化）」と
    	「未固定」である。未固定のナイフは、崩壊を防ぐために人間の
    	体の電界の近くに置く必要がある。固定されたナイフは、保管用に
    	処理されている。すべて長さは約２０センチメートルである。
    		［『デューン 砂の惑星』、フランク・ハーバート著 ］
    ```

#### ⑳ `wraith` / `nazgul` (5759-5777行) - 新規翻訳
*   **原文**:
    ```text
    wraith
    nazgul
    	Immediately, though everything else remained as before, dim
    	and dark, the shapes became terribly clear.  He was able to
    	see beneath their black wrappings.  There were five tall
    	figures:  two standing on the lip of the dell, three advancing.
    	In their white faces burned keen and merciless eyes; under
    	their mantles were long grey robes; upon their grey hairs
    	were helms of silver; in their haggard hands were swords of
    	steel.  Their eyes fell on him and pierced him, as they
    	rushed towards him.  Desperate, he drew his own sword, and
    	it seemed to him that it flickered red, as if it was a
    	firebrand.  Two of the figures halted.  The third was taller
    	than the others:  his hair was long and gleaming and on his
    	helm was a crown.  In one hand he held a long sword, and in
    	the other a knife; both the knife and the hand that held it
    	glowed with a pale light.  He sprang forward and bore down
    	on Frodo.
    		[ The Fellowship of the Ring, by J.R.R. Tolkien ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    wraith
    nazgul
    	他のすべては以前のまま、薄暗く暗いままであったが、突如として
    	彼らの姿が恐ろしいほど明確になった。彼は黒い包み布の下を
    	見ることができた。５人の背の高い人影があった：２人が窪地の
    	縁に立ち、３人が進んできていた。彼らの白い顔には鋭く無慈悲な
    	目が燃えていた；マントの下には長い灰色のローブをまとっていた；
    	灰色の髪の上には銀の兜を戴いていた；やつれた手には鋼の剣を
    	握っていた。彼らが自分に向かって突進してくるとき、彼らの目が
    	彼の上に落ち、彼を刺し貫いた。自暴自棄になり、彼は自分の剣を
    	抜いた。その剣は松明であるかのように赤くまたたいているように
    	彼には思えた。人影のうちの２人が立ち止まった。３人目は
    	他の者たちよりも背が高く、その髪は長く輝き、兜の上には
    	王冠があった。一方の手には長い剣を持ち、もう一方の手には
    	ナイフを持っていた；ナイフとそれを持つ手の両方が、青白い光を
    	放っていた。彼は前方に跳び、フロドに向かって襲いかかった。
    		［『旅の仲間』、Ｊ・Ｒ・Ｒ・トールキン著 ］
    ```

#### ㉑ `*wumpus` (5778-5789行) - 新規翻訳
*   **原文**:
    ```text
    *wumpus
    	The Wumpus, by the way, is not bothered by the hazards since
    	he has sucker feet and is too big for a bat to lift.  If you
    	try to shoot him and miss, there's also a chance that he'll
    	up and move himself into another cave, though by nature the
    	Wumpus is a sedentary creature.
    		[ wump (6) -- "Hunt the Wumpus" ]

    	_Wumpus yobgregorii_, in the flesh...
    	Later, all you will be able to remember are its eyes.  They
    	are rich mud-brown, and they hold your own without effort.
    		[ Hunter, In Darkness, by Andrew Plotkin ]
    ```
*   **新訳案（散文：30〜34文字折り返し）**:
    ```text
    *wumpus
    	ちなみに、ワンプスは吸盤付きの足を持ち、コウモリが持ち上げる
    	には大きすぎるため、ハザード（危険）を気にする必要はない。
    	彼を撃とうとして外した場合、彼は立ち上がって別の洞窟に
    	移動する可能性もあるが、本質的にワンプスは座りがちな（動かない）
    	生き物である。
    		［ wump (6) ―― 「ハント・ザ・ワンプス」 ］
    
    	生身の _Wumpus yobgregorii_ ……。
    	後になって、お前が思い出すことができるのはその目だけだろう。
    	それらは豊かな泥褐色をしており、難なくお前の目を惹きつけて
    	離さない。
    		［『ハンター・イン・ダークネス』、
    		  アンドリュー・プロットキン著 ］
    ```

---

## 4. 検証プロセス
1. **ピンポイント置換**: 翻訳箇所を1項目ずつ手動で丁寧に置換。
2. **差分目視確認**: `git diff` により差分を徹底確認。助詞「の」が `of` になっていないこと、インデント崩れがないことを1文字単位でチェック。
3. **ビルドテスト**: `dat/` ディレクトリで `..\tools\Debug\x64\makedefs.exe -d` を実行し、Exit Code 0 で正常終了し、`dat/data_jp` が正しく再構築されることを確認。
4. **ステージング**: 検証完了後、`git add dat/data_jp.base` を実行し保護。
