/* NetHack 5.0 monflag.h $NHDT-Date: 1596498549 2020/08/03 23:49:09 $ $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.21 $ */
/* Copyright (c) 1989 Mike Threepoint */
/* NetHack may be freely redistributed. See license for details. */

#ifndef MONFLAG_H
#define MONFLAG_H
/* clang-format off */
/* *INDENT-OFF* */

enum ms_sounds {
    MS_SILENT   =  0,   /* 音を出さない */
    MS_BARK     =  1,   /* 満月時には遠吠えすることがある */
    MS_MEW      =  2,   /* 鳴く、または威嚇する */
    MS_ROAR     =  3,   /* ほえる */
    MS_BELLOW   =  4,   /* 成体の雄ワニ; 幼体は「chirp」 */
    MS_GROWL    =  5,   /* うなる */
    MS_SQEEK    =  6,   /* げっ歯類のように鳴く */
    MS_SQAWK    =  7,   /* 鳥のようにけたたましく鳴く */
    MS_CHIRP    =  8,   /* 子ワニ */
    MS_HISS     =  9,   /* シューと鳴く */
    MS_BUZZ     = 10,   /* ブンブン鳴る（キラービー） */
    MS_GRUNT    = 11,   /* うなる（または固有言語で話す） */
    MS_NEIGH    = 12,   /* 馬類のようにいななく */
    MS_MOO      = 13,   /* ミノタウロス、ロース */
    MS_WAIL     = 14,   /* 苦しむ魂のように嘆く */
    MS_GURGLE   = 15,   /* 液体や唾液越しのようにごぼごぼ鳴る */
    MS_BURBLE   = 16,   /* ぶつぶつ鳴く（ジャバウォック） */
    MS_TRUMPET  = 17,   /* ラッパのように鳴く（象） */
    MS_ANIMAL   = 17,   /* ここまでは動物音 */
    /* FIXME? 上記の grunt の「固有言語で話す」ケースは
       動物として分類すべきではない */
    MS_SHRIEK   = 18,   /* 他を目覚めさせる */
    MS_BONES    = 19,   /* 骨をカタカタ鳴らす（スケルトン） */
    MS_LAUGH    = 20,   /* にやにや、ほほえみ、くすくす、笑う */
    MS_MUMBLE   = 21,   /* 何かをぶつぶつ言う */
    MS_IMITATE  = 22,   /* 他者を真似る（レオクロッタ） */
    MS_WERE     = 23,   /* 人間形態のライカンスロープ */
    MS_ORC      = 24,   /* 知能のある粗暴種 */
    /* ここから先は発話内容を理解可能 */
    MS_HUMANOID = 25,   /* 一般的な同行者の台詞 */
    MS_ARREST   = 26,   /* 「法の名のもとに止まれ!」（警官） */
    MS_SOLDIER  = 27,   /* 軍人・見張りの台詞 */
    MS_GUARD    = 28,   /* 「その金を置いてついて来い。」 */
    MS_DJINNI   = 29,   /* 「解放してくれてありがとう!」 */
    MS_NURSE    = 30,   /* 「シャツを脱いでください。」 */
    MS_SEDUCE   = 31,   /* 「こんにちは、水兵さん。」（ニンフ） */
    MS_VAMPIRE  = 32,   /* 吸血鬼の誘惑、ヴラドの叫びなど */
    MS_BRIBE    = 33,   /* 金を要求、または罵る */
    MS_CUSS     = 34,   /* 罵倒（悪魔）または威圧（Wiz） */
    MS_RIDER    = 35,   /* アストラル階層の特殊モンスター */
    MS_LEADER   = 36,   /* あなたの職業リーダー */
    MS_NEMESIS  = 37,   /* あなたの宿敵 */
    MS_GUARDIAN = 38,   /* あなたのリーダーの護衛 */
    MS_SELL     = 39,   /* 支払い要求、万引きへの苦情 */
    MS_ORACLE   = 40,   /* 神託を行う */
    MS_PRIEST   = 41,   /* 寄進を求める; 清めを行う */
    MS_SPELL    = 42,   /* 上記に当てはまらない呪文使い */
    MS_BOAST    = 43,   /* 巨人 */
    MS_GROAN    = 44,   /* ゾンビのうめき */
};

#define MR_FIRE         0x01 /* 火耐性 */
#define MR_COLD         0x02 /* 冷気耐性 */
#define MR_SLEEP        0x04 /* 睡眠耐性 */
#define MR_DISINT       0x08 /* 分解耐性 */
#define MR_ELEC         0x10 /* 電撃耐性 */
#define MR_POISON       0x20 /* 毒耐性 */
#define MR_ACID         0x40 /* 酸耐性 */
#define MR_STONE        0x80 /* 石化耐性 */
/* 注: 上記耐性は prop_types の先頭8つのヒーロー特性
   （FIRE_RES から STONE_RES）に対応し、prop.h で定義された
   res_to_mr() マクロで MR_foo 相当へ変換できる */
/* その他の耐性: 魔法、病気 */
/* その他の付与: テレポート、テレポート制御、テレパシー */

/* 個別耐性 */
#define MR2_SEE_INVIS   0x0100 /* 透明視認 */
#define MR2_LEVITATE    0x0200 /* 浮遊 */
#define MR2_WATERWALK   0x0400 /* 水上歩行 */
#define MR2_MAGBREATH   0x0800 /* 魔法呼吸 */
#define MR2_DISPLACED   0x1000 /* 位置ずれ */
#define MR2_STRENGTH    0x2000 /* 力の篭手 */
#define MR2_FUMBLING    0x4000 /* 不器用 */

#define M1_FLY          0x00000001L /* 飛行または浮遊できる */
#define M1_SWIM         0x00000002L /* 水域を移動できる */
#define M1_AMORPHOUS    0x00000004L /* 扉の下を流れ込める */
#define M1_WALLWALK     0x00000008L /* 岩をすり抜けられる */
#define M1_CLING        0x00000010L /* 天井に張り付ける */
#define M1_TUNNEL       0x00000020L /* 岩を掘り進める */
#define M1_NEEDPICK     0x00000040L /* 掘るにはつるはしが必要 */
#define M1_CONCEAL      0x00000080L /* 物体の下に隠れる */
#define M1_HIDE         0x00000100L /* 擬態、天井に溶け込む */
#define M1_AMPHIBIOUS   0x00000200L /* 水中で生存できる */
#define M1_BREATHLESS   0x00000400L /* 呼吸不要 */
#define M1_NOTAKE       0x00000800L /* 物を拾えない */
#define M1_NOEYES       0x00001000L /* 目がなく、凝視や盲目化対象外 */
#define M1_NOHANDS      0x00002000L /* 物を扱う手がない */
#define M1_NOLIMBS      0x00006000L /* 蹴る/装備する腕脚がない */
#define M1_NOHEAD       0x00008000L /* 首がなく斬首されない */
#define M1_MINDLESS     0x00010000L /* 精神なし（ゴーレム、ゾンビ、カビ） */
#define M1_HUMANOID     0x00020000L /* 人型の頭/腕/胴体を持つ */
#define M1_ANIMAL       0x00040000L /* 動物体型 */
#define M1_SLITHY       0x00080000L /* 蛇体型 */
#define M1_UNSOLID      0x00100000L /* 固体/液体の体を持たない */
#define M1_THICK_HIDE   0x00200000L /* 厚い皮膚または鱗を持つ */
#define M1_OVIPAROUS    0x00400000L /* 産卵できる */
#define M1_REGEN        0x00800000L /* HP が自然回復する */
#define M1_SEE_INVIS    0x01000000L /* 透明な生物を見える */
#define M1_TPORT        0x02000000L /* テレポートできる */
#define M1_TPORT_CNTRL  0x04000000L /* テレポート先を制御できる */
#define M1_ACID         0x08000000L /* 食べると酸性 */
#define M1_POIS         0x10000000L /* 食べると有毒 */
#define M1_CARNIVORE    0x20000000L /* 死体を食べる */
#define M1_HERBIVORE    0x40000000L /* 果物を食べる */
#define M1_OMNIVORE     0x60000000L /* 両方食べる */
#ifdef NHSTDC
#define M1_METALLIVORE  0x80000000UL /* 金属を食べる */
#else
#define M1_METALLIVORE  0x80000000L /* 金属を食べる */
#endif

#define M2_NOPOLY       0x00000001L /* プレイヤーは変身不可 */
#define M2_UNDEAD       0x00000002L /* アンデッド */
#define M2_WERE         0x00000004L /* ライカンスロープ */
#define M2_HUMAN        0x00000008L /* 人間 */
#define M2_ELF          0x00000010L /* エルフ */
#define M2_DWARF        0x00000020L /* ドワーフ */
#define M2_GNOME        0x00000040L /* ノーム */
#define M2_ORC          0x00000080L /* オーク */
#define M2_DEMON        0x00000100L /* 悪魔 */
#define M2_MERC         0x00000200L /* 衛兵または兵士 */
#define M2_LORD         0x00000400L /* 同族内の領主 */
#define M2_PRINCE       0x00000800L /* 同族内の君主 */
#define M2_MINION       0x00001000L /* 神の眷属 */
#define M2_GIANT        0x00002000L /* 巨人 */
#define M2_SHAPESHIFTER 0x00004000L /* 変身種 */
#define M2_MALE         0x00010000L /* 常に男性 */
#define M2_FEMALE       0x00020000L /* 常に女性 */
#define M2_NEUTER       0x00040000L /* 男性でも女性でもない */
#define M2_PNAME        0x00080000L /* モンスター名が固有名詞 */
#define M2_HOSTILE      0x00100000L /* 常に敵対で開始 */
#define M2_PEACEFUL     0x00200000L /* 常に平和で開始 */
#define M2_DOMESTIC     0x00400000L /* 餌付けで手懐け可能 */
#define M2_WANDER       0x00800000L /* ランダムに徘徊 */
#define M2_STALK        0x01000000L /* 他階層まで追跡する */
#define M2_NASTY        0x02000000L /* 特に危険（経験値増） */
#define M2_STRONG       0x04000000L /* 強い（または大型） */
#define M2_ROCKTHROW    0x08000000L /* 岩を投げる */
#define M2_GREEDY       0x10000000L /* 金を好む */
#define M2_JEWELS       0x20000000L /* 宝石を好む */
#define M2_COLLECT      0x40000000L /* 武器と食料を拾う */
#ifdef NHSTDC
#define M2_MAGIC        0x80000000UL /* 魔法アイテムを拾う */
#else
#define M2_MAGIC        0x80000000L /* 魔法アイテムを拾う */
#endif

#define M3_WANTSAMUL    0x0001 /* アミュレットを盗みたがる */
#define M3_WANTSBELL    0x0002 /* ベルを欲しがる */
#define M3_WANTSBOOK    0x0004 /* 本を欲しがる */
#define M3_WANTSCAND    0x0008 /* 燭台を欲しがる */
#define M3_WANTSARTI    0x0010 /* クエストアーティファクトを欲しがる */
#define M3_WANTSALL     0x001f /* 主要アーティファクトなら何でも欲しがる */
#define M3_WAITFORU     0x0040 /* あなたを見るか攻撃されるまで待つ */
#define M3_CLOSE        0x0080 /* 攻撃されない限り接近を許す */

#define M3_COVETOUS     0x001f /* 何かを欲しがる */
#define M3_WAITMASK     0x00c0 /* 待機中... */

/* 赤外線視認は現在プレイヤーのみ実装 */
#define M3_INFRAVISION  0x0100 /* 赤外線視認を持つ */
#define M3_INFRAVISIBLE 0x0200 /* 赤外線視認の対象になる */

#define M3_DISPLACES    0x0400 /* 他モンスターを押しのけて進む */

#define MZ_TINY         0 /* 2フィート未満 */
#define MZ_SMALL        1 /* 2-4フィート */
#define MZ_MEDIUM       2 /* 4-7フィート */
#define MZ_HUMAN        MZ_MEDIUM /* 人間サイズ */
#define MZ_LARGE        3 /* 7-12フィート */
#define MZ_HUGE         4 /* 12-25フィート */
#define MZ_GIGANTIC     7 /* 規格外 */

/* モンスター種族 -- ROLE_RACEMASK 内に収めること */
/* 将来的に独立フィールド化される可能性あり */
#define MH_HUMAN        M2_HUMAN
#define MH_ELF          M2_ELF
#define MH_DWARF        M2_DWARF
#define MH_GNOME        M2_GNOME
#define MH_ORC          M2_ORC

/* mons[].geno 用（ゲーム中は定数） */
#define G_UNIQ          0x1000 /* 一度だけ生成 */
#define G_NOHELL        0x0800 /* 「地獄」では生成されない */
#define G_HELL          0x0400 /* 「地獄」でのみ生成 */
#define G_NOGEN         0x0200 /* 特別にのみ生成 */
#define G_SGROUP        0x0080 /* 通常は小集団で出現 */
#define G_LGROUP        0x0040 /* 通常は大集団で出現 */
#define G_GENO          0x0020 /* 絶滅指定可能 */
#define G_NOCORPSE      0x0010 /* 死体を一切残さない */
#define G_FREQ          0x0007 /* 生成頻度マスク */
/* 注: G_IGNORE は mvitals[].mvflags の扱いを制御するが、
   mkclass() へは mons[].geno を扱うかのように渡される */
#define G_IGNORE        0x8000 /* mkclass() 用。G_GENOD|G_EXTINCT を無視 */

/* svm.mvitals[].mvflags 用（ゲーム中に変化）。G_NOCORPSE と併用 */
#define G_KNOWN         0x04 /* 遭遇済み */
#define G_GENOD         0x02 /* 絶滅済み */
#define G_EXTINCT       0x01 /* 個体数制御; これ以上生成しない */
#define G_GONE          (G_GENOD | G_EXTINCT)
#define MV_KNOWS_EGG    0x08 /* この種の卵をプレイヤーが識別している */

enum mgender { MALE, FEMALE, NEUTRAL,
               NUM_MGENDERS };

/* *INDENT-ON* */
/* clang-format on */
#endif /* MONFLAG_H */
