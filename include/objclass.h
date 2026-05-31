/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-20. */
/* NetHack 5.0	objclass.h	$NHDT-Date: 1596498553 2020/08/03 23:49:13 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.22 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Pasi Kallinen, 2018. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef OBJCLASS_H
#define OBJCLASS_H

/* [命名は不正確] オブジェクト型の定義。多くのオブジェクトは複合体
   （ガラス瓶入り液体薬、木軸に金属の鏃など）であり、
   ここでの定義は最も近い単一素材を指定する */
enum obj_material_types {
    NO_MATERIAL =  0,
    LIQUID      =  1, /* 現在は毒液のみ */
    WAX         =  2,
    VEGGY       =  3, /* 食品類 */
    FLESH       =  4, /* 同上 */
    PAPER       =  5,
    CLOTH       =  6,
    LEATHER     =  7,
    WOOD        =  8,
    BONE        =  9,
    DRAGON_HIDE = 10, /* 革ではない! */
    IRON        = 11, /* Fe - 鋼を含む */
    METAL       = 12, /* Sn など */
    COPPER      = 13, /* Cu - 真鍮を含む */
    SILVER      = 14, /* Ag */
    GOLD        = 15, /* Au */
    PLATINUM    = 16, /* Pt */
    MITHRIL     = 17,
    PLASTIC     = 18,
    GLASS       = 19,
    GEMSTONE    = 20,
    MINERAL     = 21
};

enum obj_armor_types {
    ARM_SUIT   = 0,
    ARM_SHIELD = 1,        /* 特殊装着関数で必要 */
    ARM_HELM   = 2,
    ARM_GLOVES = 3,
    ARM_BOOTS  = 4,
    ARM_CLOAK  = 5,
    ARM_SHIRT  = 6
};

struct objclass {
    short oc_name_idx;              /* 実名へのインデックス */
    short oc_descr_idx;             /* 名前不明時の説明 */
    char *oc_uname;                 /* ユーザー呼称 */
    Bitfield(oc_name_known, 1);     /* 発見済み */
    Bitfield(oc_merge, 1);          /* 同一条件オブジェクトを結合 */
    Bitfield(oc_uses_known, 1);     /* obj->known が完全説明に影響;
                                     * それ以外では obj->dknown と obj->bknown
                                     * で情報が揃い、適切な結合挙動のため
                                     * obj->known は常に設定されるべき。 */
    Bitfield(oc_encountered, 1);    /* ヒーローがこの種のアイテムを
                                       少なくとも一度は観測した
                                       （名称未判明でも可） */
    Bitfield(oc_magic, 1);          /* 本質的に魔法の品 */
    Bitfield(oc_charged, 1);        /* +n や (n) チャージを持ちうる */
    Bitfield(oc_unique, 1);         /* 一点物の特別アイテム */
    Bitfield(oc_nowish, 1);         /* 願いでは取得不可 */

    Bitfield(oc_big, 1);
#define oc_bimanual oc_big /* 武器および武器扱いの道具で両手持ち */
#define oc_bulky oc_big    /* 防具でかさばる */
    Bitfield(oc_tough, 1); /* 硬い宝石/指輪 */

    Bitfield(oc_spare1, 6);         /* oc_dir と oc_material の整列用パディング;
                                     * 他用途へ流用可能;
                                     * すなわち未使用6ビット */

    Bitfield(oc_dir, 3);
    /* oc_dir: 杖と呪文の発射スタイル */
#define NODIR     1 /* 無方向 */
#define IMMEDIATE 2 /* 反射しない指向性ビーム */
#define RAY       3 /* 壁で反射するビーム */
    /* オーバーロードされた oc_dir: 武器/武器道具の打撃種別ビットマスク */
#define PIERCE    1 /* 先端武器が目標を貫通する */
#define SLASH     2 /* 刃物が目標を切り裂く */
#define WHACK     4 /* 鈍器が目標を打ち据える */
    Bitfield(oc_material, 5); /* obj_material_types のいずれか */

    schar oc_subtyp;
#define oc_skill oc_subtyp  /* 武器・呪文書・道具・宝石のスキル */
#define oc_armcat oc_subtyp /* 防具用（enum obj_armor_types） */

    uchar oc_oprop; /* 付与される特性（不可視など） */
    char  oc_class; /* オブジェクトクラス（enum obj_class_types） */
    schar oc_delay; /* このオブジェクト使用時の遅延 */
    uchar oc_color; /* オブジェクトの色 */

    short oc_prob;            /* 出現確率（mkobj() で使用） */
    unsigned oc_weight;       /* 重さ（1 cn = 0.1 lb.） */
    short oc_cost;            /* 店での基本価格 */
    /* AD&D ルール参照! 先頭は小型モンスターへのダメージ。 */
    /* 武器、および武器として有用な道具・岩・宝石用 */
    schar oc_wsdam, oc_wldam; /* 小型/大型モンスターへの最大ダメージ */
    schar oc_oc1, oc_oc2;
#define oc_hitbon oc_oc1 /* 武器: 命中ボーナス */

#define a_ac oc_oc1     /* 防具クラス（do.c の ARM_BONUS で使用） */
#define a_can oc_oc2    /* 防具: mhitu.c で使用 */
#define oc_level oc_oc2 /* 書物: 呪文レベル */

    unsigned short oc_nutrition; /* 食料価値 */

    unsigned long oc_sell_minseen;
    unsigned long oc_sell_maxseen;
    unsigned long oc_buy_minseen;
    unsigned long oc_buy_maxseen;
};

struct class_sym {
    char sym;
    const char *name;
    const char *explain;
};

struct objdescr {
    const char *oc_name;  /* 実際の名称 */
    const char *oc_descr; /* 名前不明時の説明 */
};

/*
 * すべてのオブジェクトはクラスを持つ。
 * すべてのクラスに対応するシンボルが下にあることを確認すること。
 */

enum objclass_defchars {
#define OBJCLASS_DEFCHAR_ENUM
#include "defsym.h"
#undef OBJCLASS_DEFCHAR_ENUM
};

enum objclass_classes {
    RANDOM_CLASS =  0, /* used for generating random objects */
#define OBJCLASS_CLASS_ENUM
#include "defsym.h"
#undef OBJCLASS_CLASS_ENUM
    MAXOCLASSES
};

/* Default characters for object classes */
enum objclass_syms {
#define OBJCLASS_S_ENUM
#include "defsym.h"
#undef OBJCLASS_S_ENUM
};

/* for mkobj() use ONLY! odd '-SPBOOK_CLASS' is in case of unsigned enums */
#define SPBOOK_no_NOVEL (0 - (int) SPBOOK_CLASS)

#define BURNING_OIL (MAXOCLASSES + 1) /* explode への入力として使用可能 */
#define MON_EXPLODE (MAXOCLASSES + 2) /* 爆発するモンスター（例: ガス胞子） */
#define TRAP_EXPLODE (MAXOCLASSES + 3)

#if 0 /* moved to decl.h so that makedefs.c won't see them */
extern const struct class_sym
        def_oc_syms[MAXOCLASSES];       /* default class symbols */
extern uchar oc_syms[MAXOCLASSES];      /* current class symbols */
#endif

struct fruit {
    char fname[PL_FSIZ];
    int fid;
    struct fruit *nextf;
};
#define newfruit() (struct fruit *) alloc(sizeof(struct fruit))
#define dealloc_fruit(rind) free((genericptr_t)(rind))

enum objects_nums {
#define OBJECTS_ENUM
#include "objects.h"
#undef OBJECTS_ENUM
    NUM_OBJECTS
};

enum misc_object_nums {
    NUM_REAL_GEMS  = (LAST_REAL_GEM - FIRST_REAL_GEM + 1),
    NUM_GLASS_GEMS = (LAST_GLASS_GEM - FIRST_GLASS_GEM + 1),
    /* LAST_SPELL は SPE_BLANK_PAPER であり、spl_book[] の末尾に
       終端子として使える未使用スロットが最低1つ確保される */
    MAXSPELL       = (LAST_SPELL - FIRST_SPELL + 1),
};

extern NEARDATA struct objclass objects[NUM_OBJECTS + 1];
extern NEARDATA struct objdescr obj_descr[NUM_OBJECTS + 1];

/* JP localization: Japanese item names and descriptions */
extern const char *const obj_jp_names[NUM_OBJECTS + 1];
extern const char *const obj_jp_descrs[NUM_OBJECTS + 1];
extern const char *jp_item_name(int otyp);
extern const char *jp_item_descr(int otyp);

#define OBJ_NAME(obj) (obj_descr[(obj).oc_name_idx].oc_name)
#define OBJ_DESCR(obj) (obj_descr[(obj).oc_descr_idx].oc_descr)

#define is_organic(otmp) (objects[otmp->otyp].oc_material <= WOOD)
#define is_metallic(otmp) \
    (objects[otmp->otyp].oc_material >= IRON            \
     && objects[otmp->otyp].oc_material <= MITHRIL)

/* 一次ダメージ: 火/錆/--- */
/* is_flammable(otmp), is_rottable(otmp) は mkobj.c */
#define is_rustprone(otmp) (objects[otmp->otyp].oc_material == IRON)
#define is_crackable(otmp) \
    (objects[(otmp)->otyp].oc_material == GLASS         \
     && (otmp)->oclass == ARMOR_CLASS) /* erosion_matters() */
/* 二次ダメージ: 腐食/酸/酸 */
#define is_corrodeable(otmp) \
    (objects[otmp->otyp].oc_material == COPPER          \
     || objects[otmp->otyp].oc_material == IRON)
/* 何らかのダメージ対象になる */
#define is_damageable(otmp) \
    (is_rustprone(otmp) || is_flammable(otmp)           \
     || is_rottable(otmp) || is_corrodeable(otmp)       \
     || is_crackable(otmp))

#endif /* OBJCLASS_H */

