/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-09. */
#include "hack.h"
#include "artifact.h"

/* アイテム名の日本語表示テーブル
 * otyp をインデックスとする。NULL エントリは英語 OBJ_NAME にフォールバック。
 */
const char *const obj_jp_names[NUM_OBJECTS + 1] = {
    [AGATE] = "めのう",
    [AKLYS] = "アキリス",
    [ALCHEMY_SMOCK] = "錬金術の仕事着",
    [AMBER] = "琥珀",
    [AMETHYST] = "アメジスト",
    [AMULET_OF_CHANGE] = "性転換の魔除け",
    [AMULET_OF_ESP] = "遠視の魔除け",
    [AMULET_OF_FLYING] = "飛行の魔除け",
    [AMULET_OF_GUARDING] = "守りの魔除け",
    [AMULET_OF_LIFE_SAVING] = "命の魔除け",
    [AMULET_OF_MAGICAL_BREATHING] = "呼吸の魔除け",
    [AMULET_OF_REFLECTION] = "反射の魔除け",
    [AMULET_OF_RESTFUL_SLEEP] = "安眠の魔除け",
    [AMULET_OF_STRANGULATION] = "絞殺の魔除け",
    [AMULET_OF_UNCHANGING] = "耐へんげの魔除け",
    [AMULET_VERSUS_POISON] = "耐毒の魔除け",
    [AQUAMARINE] = "アクアマリン",
    [ARROW] = "矢",
    [ATHAME] = "アサメ",
    [AXE] = "斧",
    [BAG_OF_HOLDING] = "軽量化の鞄",
    [BAG_OF_TRICKS] = "トリックの鞄",
    [BANDED_MAIL] = "帯金の鎧",
    [BARDICHE] = "バーディック",
    [BATTLE_AXE] = "戦斧",
    [BEARTRAP] = "熊の罠",
    [BEC_DE_CORBIN] = "ベック・ド・コルバン",
    [BELL] = "ベル",
    [BILL_GUISARME] = "ビル・ギザルム",
    [BLACK_OPAL] = "黒オパール",
    [BLINDFOLD] = "目隠し",
    [BOULDER] = "巨大な岩",
    [BOOMERANG] = "ブーメラン",
    [BOW] = "弓",
    [BRASS_LANTERN] = "真鍮のランタン",
    [BROADSWORD] = "幅広の剣",
    [BRONZE_PLATE_MAIL] = "青銅の鎧",
    [BUGLE] = "ラッパ",
    [BULLWHIP] = "鞭",
    [CAN_OF_GREASE] = "脂の缶",
    [CHAIN_MAIL] = "鎖かたびら",
    [CHEST] = "宝箱",
    [CHRYSOBERYL] = "金緑石",
    [CITRINE] = "黄水晶",
    [CLOAK_OF_DISPLACEMENT] = "幻影のクローク",
    [CLOAK_OF_INVISIBILITY] = "透明のクローク",
    [CLOAK_OF_MAGIC_RESISTANCE] = "魔法を防ぐクローク",
    [CLOAK_OF_PROTECTION] = "守りのクローク",
    [CLUB] = "こん棒",
    [CREDIT_CARD] = "クレジットカード",
    [CROSSBOW] = "クロスボゥ",
    [CROSSBOW_BOLT] = "クロスボゥボルト",
    [CRYSKNIFE] = "クリスナイフ",
    [CRYSTAL_BALL] = "水晶玉",
    [CRYSTAL_PLATE_MAIL] = "水晶の鎧",
    [DAGGER] = "短剣",
    [DART] = "投げ矢",
    [DENTED_POT] = "くぼんだ鍋",
    [DIAMOND] = "ダイヤモンド",
    [DILITHIUM_CRYSTAL] = "ディリジウムの結晶",
    [DRUM_OF_EARTHQUAKE] = "地震の太鼓",
    [DWARVISH_CLOAK] = "ドワーフのクローク",
    [DWARVISH_IRON_HELM] = "ドワーフの鉄兜",
    [DWARVISH_MATTOCK] = "ドワーフのつるはし",
    [DWARVISH_MITHRIL_COAT] = "ドワーフのミスリル服",
    [DWARVISH_ROUNDSHIELD] = "ドワーフの丸盾",
    [DWARVISH_SHORT_SWORD] = "ドワーフの小剣",
    [DWARVISH_SPEAR] = "ドワーフの槍",
    [ELVEN_ARROW] = "エルフの矢",
    [ELVEN_BOOTS] = "エルフの靴",
    [ELVEN_BOW] = "エルフの弓",
    [ELVEN_BROADSWORD] = "エルフの幅広の剣",
    [ELVEN_CLOAK] = "エルフのクローク",
    [ELVEN_DAGGER] = "エルフの短剣",
    [ELVEN_LEATHER_HELM] = "エルフの革帽子",
    [ELVEN_MITHRIL_COAT] = "エルフのミスリル服",
    [ELVEN_SHIELD] = "エルフの盾",
    [ELVEN_SHORT_SWORD] = "エルフの小剣",
    [ELVEN_SPEAR] = "エルフの槍",
    [EMERALD] = "エメラルド",
    [EXPENSIVE_CAMERA] = "高価なカメラ",
    [FAUCHARD] = "フォシャール",
    [FEDORA] = "フィドーラ",
    [FIGURINE] = "人形",
    [FIRE_HORN] = "炎のホルン",
    [FLAIL] = "フレイル",
    [FLINT] = "火打ち石",
    [FLUORITE] = "フルオライト",
    [FROST_HORN] = "吹雪のホルン",
    [FUMBLE_BOOTS] = "つまずきの靴",
    [GARNET] = "ガーネット",
    [GAUNTLETS_OF_DEXTERITY] = "器用さの小手",
    [GAUNTLETS_OF_FUMBLING] = "お手玉の小手",
    [GAUNTLETS_OF_POWER] = "力の小手",
    [GLAIVE] = "グレイブ",
    [GOLD_PIECE] = "金貨",
    [GRAPPLING_HOOK] = "ひっかけ棒",
    [GUISARME] = "ギザルム",
    [HALBERD] = "ハルバード",
    [HAWAIIAN_SHIRT] = "アロハシャツ",
    [HELMET] = "兜",
    [HELM_OF_CAUTION] = "知性の兜",
    [HELM_OF_OPPOSITE_ALIGNMENT] = "逆属性の兜",
    [HELM_OF_TELEPATHY] = "テレパシーの兜",
    [HIGH_BOOTS] = "かかとの高い靴",
    [HORN_OF_PLENTY] = "恵みのホルン",
    [ICE_BOX] = "アイスボックス",
    [IRON_SHOES] = "鉄の靴",
    [JACINTH] = "橙水晶",
    [JADE] = "ひすい",
    [JASPER] = "ジャスパー",
    [JAVELIN] = "ジャベリン",
    [JET] = "黒玉",
    [JUMPING_BOOTS] = "飛び跳ねる靴",
    [KATANA] = "刀",
    [KICKING_BOOTS] = "蹴り挙げ靴",
    [KNIFE] = "ナイフ",
    [LANCE] = "ランス",
    [LAND_MINE] = "地雷",
    [LARGE_BOX] = "大箱",
    [LARGE_SHIELD] = "大きな盾",
    [LEASH] = "紐",
    [LEATHER_ARMOR] = "革鎧",
    [LEATHER_CLOAK] = "革のクローク",
    [LEATHER_DRUM] = "革の太鼓",
    [LEATHER_GLOVES] = "革の手袋",
    [LEATHER_JACKET] = "革の服",
    [LENSES] = "レンズ",
    [LEVITATION_BOOTS] = "浮遊の靴",
    [LOADSTONE] = "重し",
    [LOCK_PICK] = "鍵開け器具",
    [LONG_SWORD] = "長剣",
    [LOW_BOOTS] = "かかとの低い靴",
    [LUCERN_HAMMER] = "ルッツェルンハンマー",
    [LUCKSTONE] = "幸せの石",
    [MACE] = "メイス",
    [MAGIC_FLUTE] = "魔法のフルート",
    [MAGIC_HARP] = "魔法の竪琴",
    [MAGIC_LAMP] = "魔法のランプ",
    [MAGIC_MARKER] = "魔法のマーカ",
    [MAGIC_WHISTLE] = "魔法の笛",
    [MIRROR] = "鏡",
    [MORNING_STAR] = "モーニングスター",
    [MUMMY_WRAPPING] = "ミイラの包帯",
    [OBSIDIAN] = "黒燿石",
    [OILSKIN_CLOAK] = "防水クローク",
    [OILSKIN_SACK] = "防水袋",
    [OIL_LAMP] = "オイルランプ",
    [OPAL] = "オパール",
    [ORCISH_ARROW] = "オークの矢",
    [ORCISH_BOW] = "オークの弓",
    [ORCISH_CHAIN_MAIL] = "オークの鎖かたびら",
    [ORCISH_CLOAK] = "オークのクローク",
    [ORCISH_DAGGER] = "オークの短剣",
    [ORCISH_HELM] = "オークの兜",
    [ORCISH_RING_MAIL] = "オークの鉄環の鎧",
    [ORCISH_SHIELD] = "オークの盾",
    [ORCISH_SHORT_SWORD] = "オークの小剣",
    [ORCISH_SPEAR] = "オークの槍",
    [PARTISAN] = "パルチザン",
    [PICK_AXE] = "つるはし",
    [PLATE_MAIL] = "鋼鉄の鎧",
    [POT_ACID] = "酸の薬",
    [POT_BLINDNESS] = "盲目の薬",
    [POT_BOOZE] = "酔っぱらいの薬",
    [POT_CONFUSION] = "混乱の薬",
    [POT_ENLIGHTENMENT] = "啓蒙の薬",
    [POT_EXTRA_HEALING] = "超回復の薬",
    [POT_FRUIT_JUICE] = "フルーツジュース",
    [POT_FULL_HEALING] = "完全回復の薬",
    [POT_GAIN_ABILITY] = "能力獲得の薬",
    [POT_GAIN_ENERGY] = "魔力の薬",
    [POT_GAIN_LEVEL] = "レベルアップの薬",
    [POT_HALLUCINATION] = "幻覚の薬",
    [POT_HEALING] = "回復の薬",
    [POT_INVISIBILITY] = "透明の薬",
    [POT_LEVITATION] = "浮遊の薬",
    [POT_MONSTER_DETECTION] = "怪物を探す薬",
    [POT_OBJECT_DETECTION] = "物体を探す薬",
    [POT_OIL] = "油",
    [POT_PARALYSIS] = "麻痺の薬",
    [POT_POLYMORPH] = "へんげの薬",
    [POT_RESTORE_ABILITY] = "能力回復の薬",
    [POT_SEE_INVISIBLE] = "可視の薬",
    [POT_SICKNESS] = "病気の薬",
    [POT_SLEEPING] = "睡眠の薬",
    [POT_SPEED] = "加速の薬",
    [POT_WATER] = "水",
    [QUARTERSTAFF] = "六尺棒",
    [RANSEUR] = "ランサー",
    [RING_MAIL] = "鉄環の鎧",
    [RIN_ADORNMENT] = "飾りの指輪",
    [RIN_AGGRAVATE_MONSTER] = "反感の指輪",
    [RIN_COLD_RESISTANCE] = "耐冷の指輪",
    [RIN_CONFLICT] = "争いの指輪",
    [RIN_FIRE_RESISTANCE] = "耐炎の指輪",
    [RIN_FREE_ACTION] = "自由行動の指輪",
    [RIN_GAIN_CONSTITUTION] = "体力の指輪",
    [RIN_GAIN_STRENGTH] = "強さの指輪",
    [RIN_HUNGER] = "飢餓の指輪",
    [RIN_INCREASE_ACCURACY] = "命中の指輪",
    [RIN_INCREASE_DAMAGE] = "攻撃の指輪",
    [RIN_INVISIBILITY] = "透明の指輪",
    [RIN_LEVITATION] = "浮遊の指輪",
    [RIN_POISON_RESISTANCE] = "耐毒の指輪",
    [RIN_POLYMORPH] = "へんげの指輪",
    [RIN_POLYMORPH_CONTROL] = "へんげ制御の指輪",
    [RIN_PROTECTION] = "守りの指輪",
    [RIN_PROTECTION_FROM_SHAPE_CHAN] = "耐へんげの指輪",
    [RIN_REGENERATION] = "回復の指輪",
    [RIN_SEARCHING] = "探索の指輪",
    [RIN_SEE_INVISIBLE] = "可視の指輪",
    [RIN_SHOCK_RESISTANCE] = "耐電の指輪",
    [RIN_SLOW_DIGESTION] = "消化不良の指輪",
    [RIN_STEALTH] = "忍びの指輪",
    [RIN_SUSTAIN_ABILITY] = "能力維持の指輪",
    [RIN_TELEPORTATION] = "瞬間移動の指輪",
    [RIN_TELEPORT_CONTROL] = "瞬間移動制御の指輪",
    [RIN_WARNING] = "警告の指輪",
    [ROBE] = "ローブ",
    [ROCK] = "石",
    [RUBBER_HOSE] = "ゴムホース",
    [RUBY] = "ルビー",
    [RUNESWORD] = "ルーンの剣",
    [SACK] = "袋",
    [SADDLE] = "鞍",
    [SAPPHIRE] = "サファイア",
    [SCALE_MAIL] = "鱗の鎧",
    [SCALPEL] = "メス",
    [SCIMITAR] = "シミター",
    [SCR_AMNESIA] = "記憶喪失の巻物",
    [SCR_BLANK_PAPER] = "白紙の巻物",
    [SCR_CHARGING] = "充填の巻物",
    [SCR_CONFUSE_MONSTER] = "怪物を混乱させる巻物",
    [SCR_CREATE_MONSTER] = "怪物を作る巻物",
    [SCR_DESTROY_ARMOR] = "鎧を破壊する巻物",
    [SCR_EARTH] = "大地の巻物",
    [SCR_ENCHANT_ARMOR] = "鎧に魔法をかける巻物",
    [SCR_ENCHANT_WEAPON] = "武器に魔法をかける巻物",
    [SCR_FIRE] = "炎の巻物",
    [SCR_FOOD_DETECTION] = "食料を探す巻物",
    [SCR_GENOCIDE] = "虐殺の巻物",
    [SCR_GOLD_DETECTION] = "金貨を探す巻物",
    [SCR_IDENTIFY] = "識別の巻物",
    [SCR_LIGHT] = "光の巻物",
    [SCR_MAGIC_MAPPING] = "地図の巻物",
    [SCR_MAIL] = "手紙の巻物",
    [SCR_PUNISHMENT] = "罰の巻物",
    [SCR_REMOVE_CURSE] = "解呪の巻物",
    [SCR_SCARE_MONSTER] = "怪物を怯えさせる巻物",
    [SCR_STINKING_CLOUD] = "悪臭雲の巻物",
    [SCR_TAMING] = "怪物を飼いならす巻物",
    [SCR_TELEPORTATION] = "瞬間移動の巻物",
    [SHIELD_OF_DRAIN_RESISTANCE] = "吸命耐性の盾",
    [SHIELD_OF_REFLECTION] = "反射の盾",
    [SHIELD_OF_SHOCK_RESISTANCE] = "電撃耐性の盾",
    [SHORT_SWORD] = "小剣",
    [SHURIKEN] = "手裏剣",
    [SILVER_ARROW] = "銀の矢",
    [SILVER_DAGGER] = "銀の短剣",
    [SILVER_MACE] = "銀のメイス",
    [SILVER_SABER] = "銀のサーベル",
    [SILVER_SPEAR] = "銀の槍",
    [SKELETON_KEY] = "万能鍵",
    [SLING] = "スリング",
    [SMALL_SHIELD] = "小さな盾",
    [SPEAR] = "槍",
    [SPEED_BOOTS] = "韋駄天の靴",
    [SPETUM] = "スペタム",
    [SPE_BLANK_PAPER] = "白紙の魔法書",
    [SPE_CANCELLATION] = "無力化の魔法書",
    [SPE_CAUSE_FEAR] = "恐怖の魔法書",
    [SPE_CHAIN_LIGHTNING] = "連鎖雷撃の魔法書",
    [SPE_CHARM_MONSTER] = "魅了の魔法書",
    [SPE_CLAIRVOYANCE] = "千里眼の魔法書",
    [SPE_CONE_OF_COLD] = "冷気の魔法書",
    [SPE_CONFUSE_MONSTER] = "混乱の魔法書",
    [SPE_CREATE_FAMILIAR] = "造魔の魔法書",
    [SPE_CREATE_MONSTER] = "怪物を造る魔法書",
    [SPE_CURE_BLINDNESS] = "盲目を癒す魔法書",
    [SPE_CURE_SICKNESS] = "病気を癒す魔法書",
    [SPE_DETECT_FOOD] = "食料を探す魔法書",
    [SPE_DETECT_MONSTERS] = "怪物を探す魔法書",
    [SPE_DETECT_TREASURE] = "宝を探す魔法書",
    [SPE_DETECT_UNSEEN] = "霊感の魔法書",
    [SPE_DIG] = "穴掘りの魔法書",
    [SPE_DRAIN_LIFE] = "脱力の魔法書",
    [SPE_EXTRA_HEALING] = "超回復の魔法書",
    [SPE_FINGER_OF_DEATH] = "死の指の魔法書",
    [SPE_FIREBALL] = "火の玉の魔法書",
    [SPE_FORCE_BOLT] = "衝撃の魔法書",
    [SPE_HASTE_SELF] = "速攻の魔法書",
    [SPE_HEALING] = "回復の魔法書",
    [SPE_IDENTIFY] = "識別の魔法書",
    [SPE_INVISIBILITY] = "透明の魔法書",
    [SPE_JUMPING] = "跳躍の魔法書",
    [SPE_KNOCK] = "開錠の魔法書",
    [SPE_LEVITATION] = "浮遊の魔法書",
    [SPE_LIGHT] = "灯りの魔法書",
    [SPE_MAGIC_MAPPING] = "地図の魔法書",
    [SPE_MAGIC_MISSILE] = "矢の魔法書",
    [SPE_POLYMORPH] = "へんげの魔法書",
    [SPE_PROTECTION] = "守りの魔法書",
    [SPE_REMOVE_CURSE] = "解呪の魔法書",
    [SPE_RESTORE_ABILITY] = "能力回復の魔法書",
    [SPE_SLEEP] = "眠りの魔法書",
    [SPE_SLOW_MONSTER] = "牛歩の魔法書",
    [SPE_STONE_TO_FLESH] = "軟化の魔法書",
    [SPE_TELEPORT_AWAY] = "瞬間移動の魔法書",
    [SPE_TURN_UNDEAD] = "蘇生の魔法書",
    [SPE_WIZARD_LOCK] = "施錠の魔法書",
    [SPLINT_MAIL] = "鉄片の鎧",
    [STETHOSCOPE] = "聴診器",
    [STILETTO] = "スティレット",
    [STUDDED_LEATHER_ARMOR] = "鋲付き革鎧",
    [TALLOW_CANDLE] = "獣脂のろうそく",
    [TINNING_KIT] = "缶詰作成道具",
    [TIN_OPENER] = "缶切り",
    [TIN_WHISTLE] = "ブリキの笛",
    [TOOLED_HORN] = "細工のほどこされたホルン",
    [TOPAZ] = "トパーズ",
    [TOUCHSTONE] = "試金石",
    [TOWEL] = "タオル",
    [TRIDENT] = "トライデント",
    [TSURUGI] = "大刀",
    [TURQUOISE] = "トルコ石",
    [TWO_HANDED_SWORD] = "両手剣",
    [T_SHIRT] = "Ｔシャツ",
    [TRIPE_RATION] = "トライプの配給食",
    [CORPSE] = "死体",
    [EGG] = "卵",
    [MEATBALL] = "肉団子",
    [MEAT_STICK] = "肉の串",
    [ENORMOUS_MEATBALL] = "巨大な肉団子",
    [MEAT_RING] = "肉の輪",
    [GLOB_OF_GRAY_OOZE] = "灰色ウーズの塊",
    [GLOB_OF_BROWN_PUDDING] = "茶色プリンの塊",
    [GLOB_OF_GREEN_SLIME] = "緑スライムの塊",
    [GLOB_OF_BLACK_PUDDING] = "黒プリンの塊",
    [KELP_FROND] = "昆布",
    [EUCALYPTUS_LEAF] = "ユーカリの葉",
    [APPLE] = "りんご",
    [ORANGE] = "オレンジ",
    [PEAR] = "梨",
    [MELON] = "メロン",
    [BANANA] = "バナナ",
    [CARROT] = "にんじん",
    [SPRIG_OF_WOLFSBANE] = "トリカブト",
    [CLOVE_OF_GARLIC] = "にんにく片",
    [SLIME_MOLD] = "果物",
    [LUMP_OF_ROYAL_JELLY] = "ロイヤルゼリー",
    [CREAM_PIE] = "クリームパイ",
    [CANDY_BAR] = "キャンディバー",
    [FORTUNE_COOKIE] = "フォーチュンクッキー",
    [PANCAKE] = "パンケーキ",
    [LEMBAS_WAFER] = "レンバス",
    [CRAM_RATION] = "携帯糧食",
    [FOOD_RATION] = "食料",
    [K_RATION] = "Ｋレーション",
    [C_RATION] = "Ｃレーション",
    [TIN] = "缶詰",
    [UNICORN_HORN] = "ユニコーンの角",
    [URUK_HAI_SHIELD] = "ウルク・ハイの盾",
    [VOULGE] = "ヴォウジェ",
    [WAN_CANCELLATION] = "無力化の杖",
    [WAN_COLD] = "吹雪の杖",
    [WAN_CREATE_MONSTER] = "怪物を造る杖",
    [WAN_DEATH] = "死の杖",
    [WAN_DIGGING] = "穴掘りの杖",
    [WAN_ENLIGHTENMENT] = "啓蒙の杖",
    [WAN_FIRE] = "炎の杖",
    [WAN_LIGHT] = "灯りの杖",
    [WAN_LIGHTNING] = "雷の杖",
    [WAN_LOCKING] = "施錠の杖",
    [WAN_MAGIC_MISSILE] = "矢の杖",
    [WAN_MAKE_INVISIBLE] = "透明化の杖",
    [WAN_NOTHING] = "単なる杖",
    [WAN_OPENING] = "開錠の杖",
    [WAN_POLYMORPH] = "へんげの杖",
    [WAN_PROBING] = "探査する杖",
    [WAN_SECRET_DOOR_DETECTION] = "扉探索の杖",
    [WAN_SLEEP] = "眠りの杖",
    [WAN_SLOW_MONSTER] = "減速の杖",
    [WAN_SPEED_MONSTER] = "加速の杖",
    [WAN_STASIS] = "静止の杖",
    [WAN_STRIKING] = "衝撃の杖",
    [WAN_TELEPORTATION] = "瞬間移動の杖",
    [WAN_UNDEAD_TURNING] = "蘇生の杖",
    [WAN_WISHING] = "願いの杖",
    [WAR_HAMMER] = "ウォーハンマー",
    [WATER_WALKING_BOOTS] = "水上歩行の靴",
    [WAX_CANDLE] = "蜜蝋のろうそく",
    [WOODEN_FLUTE] = "木のフルート",
    [WOODEN_HARP] = "木の竪琴",
    [WORM_TOOTH] = "ワームの歯",
    [WORTHLESS_BLACK_GLASS] = "黒色のガラス",
    [WORTHLESS_BLUE_GLASS] = "青いガラス",
    [WORTHLESS_GREEN_GLASS] = "緑のガラス",
    [WORTHLESS_ORANGE_GLASS] = "橙色のガラス",
    [WORTHLESS_RED_GLASS] = "赤いガラス",
    [WORTHLESS_VIOLET_GLASS] = "紫のガラス",
    [WORTHLESS_WHITE_GLASS] = "白いガラス",
    [WORTHLESS_YELLOWBROWN_GLASS] = "茶褐色のガラス",
    [WORTHLESS_YELLOW_GLASS] = "黄色のガラス",
    [YA] = "竹矢",
    [YUMI] = "和弓",
    [GRAY_DRAGON_SCALE_MAIL] = "灰色ドラゴン鱗鎧",
    [GOLD_DRAGON_SCALE_MAIL] = "金色ドラゴン鱗鎧",
    [SILVER_DRAGON_SCALE_MAIL] = "銀色ドラゴン鱗鎧",
    [RED_DRAGON_SCALE_MAIL] = "赤色ドラゴン鱗鎧",
    [WHITE_DRAGON_SCALE_MAIL] = "白色ドラゴン鱗鎧",
    [ORANGE_DRAGON_SCALE_MAIL] = "橙色ドラゴン鱗鎧",
    [BLACK_DRAGON_SCALE_MAIL] = "黒色ドラゴン鱗鎧",
    [BLUE_DRAGON_SCALE_MAIL] = "青色ドラゴン鱗鎧",
    [GREEN_DRAGON_SCALE_MAIL] = "緑色ドラゴン鱗鎧",
    [YELLOW_DRAGON_SCALE_MAIL] = "黄色ドラゴン鱗鎧",
    [GRAY_DRAGON_SCALES] = "灰色ドラゴン鱗",
    [GOLD_DRAGON_SCALES] = "金色ドラゴン鱗",
    [SILVER_DRAGON_SCALES] = "銀色ドラゴン鱗",
    [RED_DRAGON_SCALES] = "赤色ドラゴン鱗",
    [WHITE_DRAGON_SCALES] = "白色ドラゴン鱗",
    [ORANGE_DRAGON_SCALES] = "橙色ドラゴン鱗",
    [BLACK_DRAGON_SCALES] = "黒色ドラゴン鱗",
    [BLUE_DRAGON_SCALES] = "青色ドラゴン鱗",
    [GREEN_DRAGON_SCALES] = "緑色ドラゴン鱗",
    [YELLOW_DRAGON_SCALES] = "黄色ドラゴン鱗",
};

/* 未識別時の外観説明（日本語）
 * descr があるアイテムのみ登録。シャッフル後の参照は obj_jp.c の
 * jp_item_descr() 関数内で oc_descr_idx を経由する。
 */
const char *const obj_jp_descrs[NUM_OBJECTS + 1] = {
    [AGATE] = "橙色の石",
    [AKLYS] = "紐付のこん棒",
    [ALCHEMY_SMOCK] = "エプロン",
    [AMBER] = "茶褐色の石",
    [AMETHYST] = "紫の石",
    [AMULET_OF_CHANGE] = "四角の魔除け",
    [AMULET_OF_ESP] = "円形の魔除け",
    [AMULET_OF_FLYING] = "立方体の魔除け",
    [AMULET_OF_GUARDING] = "穴あきの魔除け",
    [AMULET_OF_LIFE_SAVING] = "球形の魔除け",
    [AMULET_OF_MAGICAL_BREATHING] = "八角形の魔除け",
    [AMULET_OF_REFLECTION] = "六角形の魔除け",
    [AMULET_OF_RESTFUL_SLEEP] = "三角形の魔除け",
    [AMULET_OF_STRANGULATION] = "卵型の魔除け",
    [AMULET_OF_UNCHANGING] = "凹面の魔除け",
    [AMULET_VERSUS_POISON] = "四角錐の魔除け",
    [AQUAMARINE] = "緑の石",
    [BAG_OF_HOLDING] = "鞄",
    [BAG_OF_TRICKS] = "鞄",
    [BARDICHE] = "長いまさかり",
    [BATTLE_AXE] = "両刃の斧",
    [BEC_DE_CORBIN] = "くちばし付き長斧",
    [BILL_GUISARME] = "鈎付き長斧",
    [BLACK_OPAL] = "黒い石",
    [CHRYSOBERYL] = "黄色い石",
    [CITRINE] = "黄色い石",
    [CLOAK_OF_DISPLACEMENT] = "布切れ",
    [CLOAK_OF_INVISIBILITY] = "オペラクローク",
    [CLOAK_OF_MAGIC_RESISTANCE] = "装飾用の外套",
    [CLOAK_OF_PROTECTION] = "ぼろぼろのケープ",
    [CRYSTAL_BALL] = "ガラスの球",
    [DIAMOND] = "白い石",
    [DILITHIUM_CRYSTAL] = "白い石",
    [DRUM_OF_EARTHQUAKE] = "太鼓",
    [DWARVISH_CLOAK] = "フードつきのクローク",
    [DWARVISH_IRON_HELM] = "固い帽子",
    [DWARVISH_MATTOCK] = "幅広のつるはし",
    [DWARVISH_ROUNDSHIELD] = "大きな丸盾",
    [DWARVISH_SHORT_SWORD] = "幅広の小剣",
    [DWARVISH_SPEAR] = "丈夫な槍",
    [ELVEN_ARROW] = "神秘的な矢",
    [ELVEN_BOOTS] = "長靴",
    [ELVEN_BOW] = "神秘的な弓",
    [ELVEN_BROADSWORD] = "神秘的な幅広の剣",
    [ELVEN_CLOAK] = "陰気な外套",
    [ELVEN_DAGGER] = "神秘的な短剣",
    [ELVEN_LEATHER_HELM] = "革帽子",
    [ELVEN_SHIELD] = "青と緑の盾",
    [ELVEN_SHORT_SWORD] = "神秘的な小剣",
    [ELVEN_SPEAR] = "神秘的な槍",
    [EMERALD] = "緑の石",
    [FAUCHARD] = "鎌付き竿",
    [FIRE_HORN] = "ホルン",
    [FLINT] = "灰色の宝石",
    [FLUORITE] = "紫の石",
    [FROST_HORN] = "ホルン",
    [FUMBLE_BOOTS] = "乗馬用の靴",
    [GARNET] = "赤い石",
    [GAUNTLETS_OF_DEXTERITY] = "フェンシングの小手",
    [GAUNTLETS_OF_FUMBLING] = "詰めもののある手袋",
    [GAUNTLETS_OF_POWER] = "乗馬用の手袋",
    [GLAIVE] = "片刃長斧",
    [GRAPPLING_HOOK] = "鉄のフック",
    [GUISARME] = "刈り込みがま",
    [HALBERD] = "曲ったまさかり",
    [HELMET] = "羽兜",
    [HELM_OF_CAUTION] = "模様入り兜",
    [HELM_OF_OPPOSITE_ALIGNMENT] = "とさかの兜",
    [HELM_OF_TELEPATHY] = "面頬付きの兜",
    [HIGH_BOOTS] = "軍隊靴",
    [HORN_OF_PLENTY] = "ホルン",
    [IRON_SHOES] = "固い靴",
    [JACINTH] = "橙色の石",
    [JADE] = "緑の石",
    [JASPER] = "赤い石",
    [JAVELIN] = "投げ槍",
    [JET] = "黒い石",
    [JUMPING_BOOTS] = "ハイキングの靴",
    [KATANA] = "侍の剣",
    [KICKING_BOOTS] = "留め金のある靴",
    [LEATHER_DRUM] = "太鼓",
    [LEATHER_GLOVES] = "古い手袋",
    [LEVITATION_BOOTS] = "雪靴",
    [LOADSTONE] = "灰色の宝石",
    [LOW_BOOTS] = "散歩用の靴",
    [LUCERN_HAMMER] = "二股の長斧",
    [LUCKSTONE] = "灰色の宝石",
    [MAGIC_FLUTE] = "フルート",
    [MAGIC_HARP] = "竪琴",
    [MAGIC_LAMP] = "ランプ",
    [MAGIC_WHISTLE] = "笛",
    [MIRROR] = "ガラス",
    [OBSIDIAN] = "黒い石",
    [OILSKIN_CLOAK] = "つるつるしたクローク",
    [OILSKIN_SACK] = "鞄",
    [OIL_LAMP] = "ランプ",
    [OPAL] = "白い石",
    [ORCISH_ARROW] = "粗末な矢",
    [ORCISH_BOW] = "粗末な弓",
    [ORCISH_CHAIN_MAIL] = "粗末な鎖かたびら",
    [ORCISH_CLOAK] = "粗末なマント",
    [ORCISH_DAGGER] = "粗末な短剣",
    [ORCISH_HELM] = "鉄の帽子",
    [ORCISH_RING_MAIL] = "粗末な鉄環の鎧",
    [ORCISH_SHIELD] = "赤い目の盾",
    [ORCISH_SHORT_SWORD] = "粗末な小剣",
    [ORCISH_SPEAR] = "粗末な槍",
    [PARTISAN] = "粗雑な長斧",
    [POT_ACID] = "白い薬",
    [POT_BLINDNESS] = "黄色の薬",
    [POT_BOOZE] = "茶色の薬",
    [POT_CONFUSION] = "オレンジ色の薬",
    [POT_ENLIGHTENMENT] = "渦を巻いている薬",
    [POT_EXTRA_HEALING] = "暗褐色の薬",
    [POT_FRUIT_JUICE] = "陰気な色の薬",
    [POT_FULL_HEALING] = "黒い薬",
    [POT_GAIN_ABILITY] = "ルビー色の薬",
    [POT_GAIN_ENERGY] = "曇っている薬",
    [POT_GAIN_LEVEL] = "ミルク色の薬",
    [POT_HALLUCINATION] = "水色の薬",
    [POT_HEALING] = "赤紫色の薬",
    [POT_INVISIBILITY] = "明るい青色の薬",
    [POT_LEVITATION] = "シアン色の薬",
    [POT_MONSTER_DETECTION] = "泡だっている薬",
    [POT_OBJECT_DETECTION] = "煙がでている薬",
    [POT_OIL] = "濃黒の薬",
    [POT_PARALYSIS] = "エメラルド色の薬",
    [POT_POLYMORPH] = "金色の薬",
    [POT_RESTORE_ABILITY] = "ピンク色の薬",
    [POT_SEE_INVISIBLE] = "マゼンダ色の薬",
    [POT_SICKNESS] = "発泡している薬",
    [POT_SLEEPING] = "沸騰している薬",
    [POT_SPEED] = "暗緑色の薬",
    [POT_WATER] = "無色の薬",
    [QUARTERSTAFF] = "棒",
    [RANSEUR] = "柄付の長斧",
    [RIN_ADORNMENT] = "木の指輪",
    [RIN_AGGRAVATE_MONSTER] = "サファイアの指輪",
    [RIN_COLD_RESISTANCE] = "真鍮の指輪",
    [RIN_CONFLICT] = "ルビーの指輪",
    [RIN_FIRE_RESISTANCE] = "鉄の指輪",
    [RIN_FREE_ACTION] = "ねじれた指輪",
    [RIN_GAIN_CONSTITUTION] = "オパールの指輪",
    [RIN_GAIN_STRENGTH] = "花崗岩の指輪",
    [RIN_HUNGER] = "トパーズの指輪",
    [RIN_INCREASE_ACCURACY] = "土の指輪",
    [RIN_INCREASE_DAMAGE] = "珊瑚の指輪",
    [RIN_INVISIBILITY] = "針金の指輪",
    [RIN_LEVITATION] = "めのうの指輪",
    [RIN_POISON_RESISTANCE] = "真珠の指輪",
    [RIN_POLYMORPH] = "象牙の指輪",
    [RIN_POLYMORPH_CONTROL] = "エメラルドの指輪",
    [RIN_PROTECTION] = "黒めのうの指輪",
    [RIN_PROTECTION_FROM_SHAPE_CHAN] = "光る指輪",
    [RIN_REGENERATION] = "月長石の指輪",
    [RIN_SEARCHING] = "虎目石の指輪",
    [RIN_SEE_INVISIBLE] = "婚約指輪",
    [RIN_SHOCK_RESISTANCE] = "銅の指輪",
    [RIN_SLOW_DIGESTION] = "鋼鉄の指輪",
    [RIN_STEALTH] = "ひすいの指輪",
    [RIN_SUSTAIN_ABILITY] = "青銅の指輪",
    [RIN_TELEPORTATION] = "銀の指輪",
    [RIN_TELEPORT_CONTROL] = "金の指輪",
    [RIN_WARNING] = "ダイヤモンドの指輪",
    [RUBY] = "赤い石",
    [RUNESWORD] = "神秘的な幅広の剣",
    [SACK] = "鞄",
    [SAPPHIRE] = "青い石",
    [SCIMITAR] = "曲った剣",
    [SCR_AMNESIA] = "「コケツ・マロビツ」と書かれた巻物",
    [SCR_BLANK_PAPER] = "ラベルのない巻物",
    [SCR_CHARGING] = "「ジゴク・バッケイ」と書かれた巻物",
    [SCR_CONFUSE_MONSTER] = "「ムスビ・タマユラ」と書かれた巻物",
    [SCR_CREATE_MONSTER] = "「アラタマ・ニギミタマ」と書かれた巻物",
    [SCR_DESTROY_ARMOR] = "「ヨモツ・ウツシヨ」と書かれた巻物",
    [SCR_EARTH] = "「コムソー」と書かれた巻物",
    [SCR_ENCHANT_ARMOR] = "「モージャノ・タワムレ」と書かれた巻物",
    [SCR_ENCHANT_WEAPON] = "「スタブ・ドライバ」と書かれた巻物",
    [SCR_FIRE] = "「デバガ・デバギ・デバグ」と書かれた巻物",
    [SCR_FOOD_DETECTION] = "「ジャイスト」と書かれた巻物",
    [SCR_GENOCIDE] = "「アプセト・ネデブ」と書かれた巻物",
    [SCR_GOLD_DETECTION] = "「エピステーメー」と書かれた巻物",
    [SCR_IDENTIFY] = "「コンテキスト・スイッチ」と書かれた巻物",
    [SCR_LIGHT] = "「テナガ・アシナガ」と書かれた巻物",
    [SCR_MAGIC_MAPPING] = "「サルタヒコ」と書かれた巻物",
    [SCR_MAIL] = "消印の押された巻物",
    [SCR_PUNISHMENT] = "「アイガカリ・ボーギン」と書かれた巻物",
    [SCR_REMOVE_CURSE] = "「ニガシムジャウム」と書かれた巻物",
    [SCR_SCARE_MONSTER] = "「クシクサ・クスクサ」と書かれた巻物",
    [SCR_STINKING_CLOUD] = "「ドスコイ・ワッショイ」と書かれた巻物",
    [SCR_TAMING] = "「ドッコイセ」と書かれた巻物",
    [SCR_TELEPORTATION] = "「ランタナ・シチヘンゲ」と書かれた巻物",
    /* Extra shuffled scroll labels (SC01..SC20) */
    [SC01] = "「リコリス・アカヒカリ」と書かれた巻物",
    [SC02] = "「サイエンティア」と書かれた巻物",
    [SC03] = "「カアラマン」と書かれた巻物",
    [SC04] = "「ルナリア・ツキノタネ」と書かれた巻物",
    [SC05] = "「オオナムチ」と書かれた巻物",
    [SC06] = "「ミシャグチ」と書かれた巻物",
    [SC07] = "「アーマン・チュウメイ」と書かれた巻物",
    [SC08] = "「スグニ・ヨンデ」と書かれた巻物",
    [SC09] = "「アブラ・カ・ダブラ」と書かれた巻物",
    [SC10] = "「セマフォ」と書かれた巻物",
    [SC11] = "「ヨンデハ・ナラヌ」と書かれた巻物",
    [SC12] = "「テヅル・モヅル」と書かれた巻物",
    [SC13] = "「サンケン・シケン」と書かれた巻物",
    [SC14] = "「チリ・トテ・チン」と書かれた巻物",
    [SC15] = "「ポンポコピー・ポンポコナー」と書かれた巻物",
    [SC16] = "「スピンロック」と書かれた巻物",
    [SC17] = "「オンカカカ・ミサンマエイ・ソワカ」と書かれた巻物",
    [SC18] = "「ノウマク・サマンダ」と書かれた巻物",
    [SC19] = "「テケレッツノ・パア」と書かれた巻物",
    [SC20] = "「アジャラカ・モクレン」と書かれた巻物",
    [SHIELD_OF_DRAIN_RESISTANCE] = "木盾",
    [SHIELD_OF_REFLECTION] = "銀色の磨かれた盾",
    [SHIELD_OF_SHOCK_RESISTANCE] = "木盾",
    [SHURIKEN] = "星型の投げるもの",
    [SKELETON_KEY] = "鍵",
    [SPEED_BOOTS] = "戦闘靴",
    [SPETUM] = "フォーク付き長斧",
    [SPE_BLANK_PAPER] = "真っ白な魔法書",
    [SPE_CANCELLATION] = "輝く魔法書",
    [SPE_CAUSE_FEAR] = "淡青の魔法書",
    [SPE_CHAIN_LIGHTNING] = "市松模様の魔法書",
    [SPE_CHARM_MONSTER] = "マゼンダ色の魔法書",
    [SPE_CLAIRVOYANCE] = "濃青の魔法書",
    [SPE_CONE_OF_COLD] = "ページの折られた魔法書",
    [SPE_CONFUSE_MONSTER] = "オレンジ色の魔法書",
    [SPE_CREATE_FAMILIAR] = "きらびやかな魔法書",
    [SPE_CREATE_MONSTER] = "青緑色の魔法書",
    [SPE_CURE_BLINDNESS] = "黄色い魔法書",
    [SPE_CURE_SICKNESS] = "藍色の魔法書",
    [SPE_DETECT_FOOD] = "シアン色の魔法書",
    [SPE_DETECT_MONSTERS] = "革張りの魔法書",
    [SPE_DETECT_TREASURE] = "灰色の魔法書",
    [SPE_DETECT_UNSEEN] = "スミレ色の魔法書",
    [SPE_DIG] = "羊皮紙の魔法書",
    [SPE_DRAIN_LIFE] = "ビロードの魔法書",
    [SPE_EXTRA_HEALING] = "ラシャの魔法書",
    [SPE_FINGER_OF_DEATH] = "よごれた魔法書",
    [SPE_FIREBALL] = "ぼろぼろの魔法書",
    [SPE_FORCE_BOLT] = "赤い魔法書",
    [SPE_HASTE_SELF] = "紫色の魔法書",
    [SPE_HEALING] = "白い魔法書",
    [SPE_IDENTIFY] = "青銅の魔法書",
    [SPE_INVISIBILITY] = "濃茶色の魔法書",
    [SPE_JUMPING] = "薄い色の魔法書",
    [SPE_KNOCK] = "ピンク色の魔法書",
    [SPE_LEVITATION] = "黄褐色の魔法書",
    [SPE_LIGHT] = "布地の魔法書",
    [SPE_MAGIC_MAPPING] = "ほこりっぽい魔法書",
    [SPE_MAGIC_MISSILE] = "子牛皮の魔法書",
    [SPE_POLYMORPH] = "銀の魔法書",
    [SPE_PROTECTION] = "鉛色の魔法書",
    [SPE_REMOVE_CURSE] = "くしゃくしゃの魔法書",
    [SPE_RESTORE_ABILITY] = "淡茶色の魔法書",
    [SPE_SLEEP] = "まだらの魔法書",
    [SPE_SLOW_MONSTER] = "淡緑色の魔法書",
    [SPE_STONE_TO_FLESH] = "濃い色の魔法書",
    [SPE_TELEPORT_AWAY] = "金の魔法書",
    [SPE_TURN_UNDEAD] = "銅の魔法書",
    [SPE_WIZARD_LOCK] = "濃緑色の魔法書",
    [TALLOW_CANDLE] = "ろうそく",
    [TIN_WHISTLE] = "笛",
    [TOOLED_HORN] = "ホルン",
    [TOPAZ] = "茶褐色の石",
    [TOUCHSTONE] = "灰色の宝石",
    [TSURUGI] = "侍の長剣",
    [TURQUOISE] = "緑の石",
    [URUK_HAI_SHIELD] = "白の手の盾",
    [VOULGE] = "包丁付き竿",
    [WAN_CANCELLATION] = "プラチナの杖",
    [WAN_COLD] = "短い杖",
    [WAN_CREATE_MONSTER] = "楓の杖",
    [WAN_DEATH] = "長い杖",
    [WAN_DIGGING] = "鉄の杖",
    [WAN_ENLIGHTENMENT] = "水晶の杖",
    [WAN_FIRE] = "六角形の杖",
    [WAN_LIGHT] = "ガラスの杖",
    [WAN_LIGHTNING] = "曲った杖",
    [WAN_LOCKING] = "アルミニウムの杖",
    [WAN_MAGIC_MISSILE] = "鋼鉄の杖",
    [WAN_MAKE_INVISIBLE] = "大理石の杖",
    [WAN_NOTHING] = "樫の杖",
    [WAN_OPENING] = "亜鉛の杖",
    [WAN_POLYMORPH] = "銀の杖",
    [WAN_PROBING] = "ウラニウムの杖",
    [WAN_SECRET_DOOR_DETECTION] = "バルサの杖",
    [WAN_SLEEP] = "ルーン文字の書かれた杖",
    [WAN_SLOW_MONSTER] = "ブリキの杖",
    [WAN_SPEED_MONSTER] = "真鍮の杖",
    [WAN_STASIS] = "レッドウッドの杖",
    [WAN_STRIKING] = "黒檀の杖",
    [WAN_TELEPORTATION] = "イリジウムの杖",
    [WAN_UNDEAD_TURNING] = "銅の杖",
    [WAN_WISHING] = "松の杖",
    [WAN1] = "二股の杖",
    [WAN2] = "トゲ付きの杖",
    [WAN3] = "宝石付きの杖",
    [WATER_WALKING_BOOTS] = "ジャングルの靴",
    [WAX_CANDLE] = "ろうそく",
    [WOODEN_FLUTE] = "フルート",
    [WOODEN_HARP] = "竪琴",
    [WORTHLESS_BLACK_GLASS] = "黒い石",
    [WORTHLESS_BLUE_GLASS] = "青い石",
    [WORTHLESS_GREEN_GLASS] = "緑の石",
    [WORTHLESS_ORANGE_GLASS] = "橙色の石",
    [WORTHLESS_RED_GLASS] = "赤い石",
    [WORTHLESS_VIOLET_GLASS] = "紫の石",
    [WORTHLESS_WHITE_GLASS] = "白い石",
    [WORTHLESS_YELLOWBROWN_GLASS] = "茶褐色の石",
    [WORTHLESS_YELLOW_GLASS] = "黄色い石",
    [YA] = "竹の矢",
    [YUMI] = "長弓",
};

/* アイテムの日本語表示名を取得（フォールバック付き）*/
const char *
jp_item_name(int otyp)
{
    if (otyp >= 0 && otyp < NUM_OBJECTS && obj_jp_names[otyp])
        return obj_jp_names[otyp];
    return OBJ_NAME(objects[otyp]);
}

/* アイテムの未識別外観を日本語で取得（シャッフル対応）
 * oc_descr_idx は shuffle() により書き換えられるため、
 * OBJ_DESCR() と同じ参照チェーン（oc_descr_idx 経由）を使う。
 */
const char *
jp_item_descr(int otyp)
{
    int idx = objects[otyp].oc_descr_idx;
    if (idx >= 0 && idx < NUM_OBJECTS && obj_jp_descrs[idx])
        return obj_jp_descrs[idx];
    return OBJ_DESCR(objects[otyp]);
}

const char *
jp_oclass_name(int oclass)
{
    static const char *const names[] = {
        "不明", "不正規", "武器", "防具", "指輪", "魔除け", "道具",
        "食べ物", "薬", "巻物", "魔法書", "杖", "金貨",
        "宝石", "岩石", "鉄球", "鎖", "毒液"
    };
    if (oclass >= 0 && oclass < MAXOCLASSES)
        return names[oclass];
    return names[0];
}

/* アーティファクトの日本語表示名テーブル（NROFARTIFACTS + 1 エントリ） */
const char *const artilist_jp_names[1 + NROFARTIFACTS] = {
    [ART_EXCALIBUR] = "エクスカリバー",
    [ART_STORMBRINGER] = "ストームブリンガー",
    [ART_MJOLLNIR] = "ミョルニル",
    [ART_CLEAVER] = "クリーバー",
    [ART_GRIMTOOTH] = "グリムトゥース",
    [ART_ORCRIST] = "オークリスト",
    [ART_STING] = "スティング",
    [ART_MAGICBANE] = "マジックベイン",
    [ART_FROST_BRAND] = "フロストブランド",
    [ART_FIRE_BRAND] = "ファイアブランド",
    [ART_DRAGONBANE] = "ドラゴンベイン",
    [ART_DEMONBANE] = "デーモンベイン",
    [ART_WEREBANE] = "ウェアベイン",
    [ART_GRAYSWANDIR] = "グレイスワンダー",
    [ART_GIANTSLAYER] = "ジャイアントスレイヤー",
    [ART_OGRESMASHER] = "オウガスマッシャー",
    [ART_TROLLSBANE] = "トロルズベイン",
    [ART_VORPAL_BLADE] = "ヴォーパルブレード",
    [ART_SNICKERSNEE] = "スニッカーズニー",
    [ART_SUNSWORD] = "サンソード",

    /* クエストアーティファクト */
    [ART_ORB_OF_DETECTION] = "探知のオーブ",
    [ART_HEART_OF_AHRIMAN] = "アーリマンの心臓",
    [ART_SCEPTRE_OF_MIGHT] = "力の王笏",
    [ART_STAFF_OF_AESCULAPIUS] = "アスクレピオスの杖",
    [ART_MAGIC_MIRROR_OF_MERLIN] = "マーリンの魔法の鏡",
    [ART_EYES_OF_THE_OVERWORLD] = "オーバーワールドの目",
    [ART_MITRE_OF_HOLINESS] = "神聖の僧帽",
    [ART_LONGBOW_OF_DIANA] = "ディアナの長弓",
    [ART_MASTER_KEY_OF_THIEVERY] = "盗賊術のマスターキー",
    [ART_TSURUGI_OF_MURAMASA] = "村正の剣",
    [ART_YENDORIAN_EXPRESS_CARD] = "プラチナイェンダー印エクスプレスカード",
    [ART_ORB_OF_FATE] = "運命のオーブ",
    [ART_EYE_OF_THE_AETHIOPICA] = "エチオピカの目",
};

/* JNetHackでのアーティファクトの日本語名テーブル（願い入力用別名） */
const char *const artilist_jnethack_names[1 + NROFARTIFACTS] = {
    [ART_MJOLLNIR] = "ミュルニール",
    [ART_GRAYSWANDIR] = "グレイスワンダー",
    [ART_OGRESMASHER] = "オーガスマッシャー",
    [ART_TROLLSBANE] = "トロルスベーン",
    [ART_VORPAL_BLADE] = "ボーパルブレード",
    [ART_ORB_OF_DETECTION] = "探索のオーブ",
    [ART_SCEPTRE_OF_MIGHT] = "権力の笏",
    [ART_EYES_OF_THE_OVERWORLD] = "超世界の目",
    [ART_MITRE_OF_HOLINESS] = "聖なる冠",
    [ART_MASTER_KEY_OF_THIEVERY] = "盗賊のマスターキー",
    [ART_TSURUGI_OF_MURAMASA] = "村正の刀",
    [ART_EYE_OF_THE_AETHIOPICA] = "エチオピアの目",
};

/* アーティファクトの日本語名を取得 */
const char *
jp_artiname(int artinum)
{
    if (artinum > 0 && artinum <= NROFARTIFACTS && artilist_jp_names[artinum])
        return artilist_jp_names[artinum];
    return "";
}

/* 日本語名（表記揺れ対応）からアーティファクト番号を取得 */
int
jp_artiname_to_num(const char *name)
{
    int i;
    char normalized_name[256] = {0};
    char u_buf[256] = {0}, jp_buf[256] = {0};
    char *p;
    int guard;

    if (!name || !*name)
        return 0;

    /* JNetHackの通常アイテム名などをNetHackJP表記に正規化 */
    jnh_normalize_wish(name, normalized_name, sizeof(normalized_name));

    /* 入力文字列のクリーンアップ（「の」やスペースの除去） */
    strncpy(u_buf, normalized_name, sizeof(u_buf) - 1);
    u_buf[sizeof(u_buf) - 1] = '\0';

    /* 先頭の "the " などをスキップ（英語と日本語の混在対策） */
    char *u_ptr = u_buf;
    if (!strncmpi(u_ptr, "the ", 4))
        u_ptr += 4;

    /* 「の」の除去 */
    guard = 0;
    while (guard++ < 256 && (p = strstr(u_ptr, "の")) != 0) {
        memmove(p, p + 3, strlen(p + 3) + 1);
    }
    /* 半角スペースの除去 */
    guard = 0;
    while (guard++ < 256 && (p = strchr(u_ptr, ' ')) != 0) {
        memmove(p, p + 1, strlen(p + 1) + 1);
    }
    /* 全角スペースの除去 */
    guard = 0;
    while (guard++ < 256 && (p = strstr(u_ptr, "　")) != 0) {
        memmove(p, p + 3, strlen(p + 3) + 1);
    }

    /* 1. 標準日本語表示名テーブルで検索 */
    for (i = 1; i <= NROFARTIFACTS; i++) {
        if (!artilist_jp_names[i])
            continue;

        /* 完全に一致するか？ */
        if (!strcmpi(u_ptr, artilist_jp_names[i]))
            return i;

        /* 表記揺れ除去後の比較 */
        strncpy(jp_buf, artilist_jp_names[i], sizeof(jp_buf) - 1);
        jp_buf[sizeof(jp_buf) - 1] = '\0';

        /* 辞書名から「の」を除去 */
        guard = 0;
        while (guard++ < 256 && (p = strstr(jp_buf, "の")) != 0) {
            memmove(p, p + 3, strlen(p + 3) + 1);
        }
        /* 辞書名から半角スペースを除去 */
        guard = 0;
        while (guard++ < 256 && (p = strchr(jp_buf, ' ')) != 0) {
            memmove(p, p + 1, strlen(p + 1) + 1);
        }
        /* 辞書名から全角スペースを除去 */
        guard = 0;
        while (guard++ < 256 && (p = strstr(jp_buf, "　")) != 0) {
            memmove(p, p + 3, strlen(p + 3) + 1);
        }

        if (!strcmpi(u_ptr, jp_buf))
            return i;
    }

    /* 2. JNetHack別名テーブルで検索 */
    for (i = 1; i <= NROFARTIFACTS; i++) {
        if (!artilist_jnethack_names[i])
            continue;

        /* 完全に一致するか？ */
        if (!strcmpi(u_ptr, artilist_jnethack_names[i]))
            return i;

        /* 表記揺れ除去後の比較 */
        strncpy(jp_buf, artilist_jnethack_names[i], sizeof(jp_buf) - 1);
        jp_buf[sizeof(jp_buf) - 1] = '\0';

        /* 辞書名から「の」を除去 */
        guard = 0;
        while (guard++ < 256 && (p = strstr(jp_buf, "の")) != 0) {
            memmove(p, p + 3, strlen(p + 3) + 1);
        }
        /* 辞書名から半角スペースを除去 */
        guard = 0;
        while (guard++ < 256 && (p = strchr(jp_buf, ' ')) != 0) {
            memmove(p, p + 1, strlen(p + 1) + 1);
        }
        /* 辞書名から全角スペースを除去 */
        guard = 0;
        while (guard++ < 256 && (p = strstr(jp_buf, "　")) != 0) {
            memmove(p, p + 3, strlen(p + 3) + 1);
        }

        if (!strcmpi(u_ptr, jp_buf))
            return i;
    }

    return 0;
}

/* 文字列置換ヘルパー */
static void
str_replace(char *buf, int buf_size, const char *from, const char *to)
{
    char tmp[256] = {0};
    char *p;
    if (buf_size > 256 || buf_size <= 0) return;
    if ((p = strstr(buf, from)) != 0) {
        int prefix_len = (int)(p - buf);
        int from_len = (int)strlen(from);
        int suffix_len = (int)strlen(p + from_len);
        int to_len = (int)strlen(to);
        if (prefix_len + to_len + suffix_len < buf_size) {
            /* 安全な文字列構築 */
            memcpy(tmp, buf, prefix_len);
            memcpy(tmp + prefix_len, to, to_len);
            memcpy(tmp + prefix_len + to_len, p + from_len, suffix_len);
            tmp[prefix_len + to_len + suffix_len] = '\0';
            
            memcpy(buf, tmp, prefix_len + to_len + suffix_len + 1);
        }
    }
}

struct jnh_wish_alias {
    const char *jnh_name;
    const char *nhjp_name;
};

static const struct jnh_wish_alias jnh_wish_aliases[] = {
    /* ワンド / 杖 */
    { "願いのワンド", "願いの杖" },
    { "死のワンド", "死の杖" },
    { "テレポートのワンド", "瞬間移動の杖" },
    { "瞬間移動のワンド", "瞬間移動の杖" },
    { "穴掘りのワンド", "穴掘りの杖" },
    { "へんげのワンド", "へんげの杖" },
    { "無力化のワンド", "無力化の杖" },
    { "スピードのワンド", "加速の杖" },
    { "スピードモンスターのワンド", "加速の杖" },
    { "スローモンスターのワンド", "減速の杖" },
    { "加速のワンド", "加速の杖" },
    { "減速のワンド", "減速の杖" },
    { "雷のワンド", "雷の杖" },
    { "炎のワンド", "炎の杖" },
    { "冷気のワンド", "吹雪の杖" },
    { "吹雪のワンド", "吹雪の杖" },
    { "睡眠のワンド", "眠りの杖" },
    { "眠りのワンド", "眠りの杖" },
    { "光のワンド", "灯りの杖" },
    { "灯りのワンド", "灯りの杖" },
    { "探査のワンド", "探査する杖" },
    { "開錠のワンド", "開錠の杖" },
    { "施錠のワンド", "施錠の杖" },
    { "造魔のワンド", "怪物を造る杖" },
    { "蘇生のワンド", "蘇生の杖" },
    { "単なるワンド", "単なる杖" },

    /* ポーション / 薬 */
    { "回復のポーション", "回復の薬" },
    { "超回復のポーション", "超回復の薬" },
    { "完全回復のポーション", "完全回復の薬" },
    { "能力獲得のポーション", "能力獲得の薬" },
    { "能力回復のポーション", "能力回復の薬" },
    { "レベルアップのポーション", "レベルアップの薬" },
    { "魔力のポーション", "魔力の薬" },
    { "へんげのポーション", "へんげの薬" },
    { "盲目のポーション", "盲目の薬" },
    { "混乱のポーション", "混乱の薬" },
    { "麻痺のポーション", "麻痺の薬" },
    { "睡眠のポーション", "睡眠の薬" },
    { "スピードのポーション", "加速の薬" },
    { "加速のポーション", "加速の薬" },
    { "啓蒙のポーション", "啓蒙の薬" },
    { "幻覚のポーション", "幻覚の薬" },
    { "可視のポーション", "可視の薬" },
    { "透明のポーション", "透明の薬" },
    { "病気のポーション", "病気の薬" },
    { "酸のポーション", "酸の薬" },
    { "オイルのポーション", "油" },

    /* 巻物 (接尾辞「巻物」を除いた実体名のみでマッピング) */
    { "鑑定", "識別" },
    { "呪いをとく", "解呪" },
    { "呪いを解く", "解呪" },
    { "鎧強化", "鎧に魔法をかける" },
    { "武器強化", "武器に魔法をかける" },
    { "テレポート", "瞬間移動" },
    { "怪物創造", "怪物を作る" },
    { "飼いならし", "怪物を飼いならす" },

    /* 指輪 (接尾辞「指輪」を除いた実体名のみでマッピング) */
    { "変化制御", "へんげ制御" },
    { "変化", "へんげ" },
    { "耐変化", "耐へんげ" },
    { "耐変化怪物", "耐へんげ" },
    { "スロー消化", "消化不良" },

    /* 防具 */
    { "スピードブーツ", "韋駄天の靴" },
    { "スピードの靴", "韋駄天の靴" },
    { "魔除けのクローク", "魔法を防ぐクローク" },
    { "知性の兜", "知性の兜" },
    { "知恵の兜", "知性の兜" },

    /* 道具 */
    { "軽量化のバッグ", "軽量化の鞄" },
    { "軽量化バッグ", "軽量化の鞄" },
    { "トリックのバッグ", "トリックの鞄" },
    { "トリックバッグ", "トリックの鞄" },
    { "防水バッグ", "防水袋" },
    { "万能鍵", "万能鍵" },
    { "鍵開け器具", "鍵開け器具" },
    { "クレジットカード", "クレジットカード" },
    { "魔法のマーカー", "魔法のマーカ" },
    { "缶詰作成キット", "缶詰作成道具" },

    /* アーティファクト */
    { "ミョルニール", "ミョルニル" },
    { "ミュルニール", "ミョルニル" },
    { "マジックベーン", "マジックベイン" },
    { "グレイスワンディル", "グレイスワンダー" },
    { "グレイズワンディル", "グレイスワンダー" },

    /* その他のエイリアス */
    { "つらぬき丸", "スティング" },
    { "つらぬきまる", "スティング" },
    { "かみつき丸", "オークリスト" },
    { "かみつきまる", "オークリスト" },
    { "オルクリスと", "オークリスト" },

    { (const char *)0, (const char *)0 }
};

/* JNetHackの通常アイテム名表記（エイリアス・表記揺れ）をNetHackJP名に正規化する */
void
jnh_normalize_wish(const char *u_str, char *out_buf, size_t outsz)
{
    char u_buf[256] = {0};
    char jp_buf[256] = {0};
    char *p;
    int i;
    int guard;

    if (!u_str || !*u_str || !out_buf || outsz == 0)
        return;

    /* 元の文字列をデフォルトとして出力にコピー */
    strncpy(out_buf, u_str, outsz - 1);
    out_buf[outsz - 1] = '\0';

    /* エイリアステーブルで置換
       完全一致ではなく部分置換にすることで「祝福されたつらぬき丸」等を認識可能にする */
    for (i = 0; jnh_wish_aliases[i].jnh_name; i++) {
        str_replace(out_buf, outsz, jnh_wish_aliases[i].jnh_name, jnh_wish_aliases[i].nhjp_name);
    }

    /* ドラゴン名の正規化だけでマッチする可能性があるため、
       エイリアス適用後の out_buf に対してドラゴン名の正規化を行う。
       例えば「白ドラゴンのつらぬき丸」 -> 「白色ドラゴンのスティング」
    */
    {
        char dragon_buf[256] = {0};
        strncpy(dragon_buf, out_buf, sizeof(dragon_buf) - 1);
        dragon_buf[sizeof(dragon_buf) - 1] = '\0';
        str_replace(dragon_buf, sizeof(dragon_buf), "ドラゴンの", "ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "白ドラゴン", "白色ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "オレンジドラゴン", "橙色ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "黒ドラゴン", "黒色ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "青ドラゴン", "青色ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "緑ドラゴン", "緑色ドラゴン");
        str_replace(dragon_buf, sizeof(dragon_buf), "黄ドラゴン", "黄色ドラゴン");

        if (strcmp(dragon_buf, out_buf) != 0) {
            strncpy(out_buf, dragon_buf, outsz - 1);
            out_buf[outsz - 1] = '\0';
        }
    }
}



