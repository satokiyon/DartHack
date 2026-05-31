/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-06. */
/* NetHack 5.0	permonst.h	$NHDT-Date: 1725653014 2024/09/06 20:03:34 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.26 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Kenneth Lorber, Kensington, Maryland, 2015. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef PERMONST_H
#define PERMONST_H

enum monnums {
#define MONS_ENUM
#include "monsters.h"
#undef MONS_ENUM
        NUMMONS,
        NON_PM = -1,              /* 「モンスターではない」 */
        LOW_PM = NON_PM + 1,      /* mons 配列内の最初のモンスター */
        LEAVESTATUE = NON_PM - 1, /* 死体の代わりに石像を残す;
                                   * end.c ではさらに低い値が2つ使われ、
                                   * bones.c で (x == LEAVESTATUE) が
                                   * FALSE になるようにしている:
                                   *  (NON_PM - 2) は死体なし
                                   *  (NON_PM - 3) は死体なし・墓なし */
        HIGH_PM = NUMMONS - 1,
        SPECIAL_PM = PM_LONG_WORM_TAIL  /* [通常] < ~ < [特殊] */
                /* mons[SPECIAL_PM] から mons[NUMMONS-1] までは
                   ランダム生成されず、変身先にもならない */
};

/*     この構造体はすべての攻撃形態を扱う。
 *     aatyp は大まかな攻撃種別（例: 爪、噛みつき、ブレス、...）
 *     adtyp はダメージ種別（例: 物理、火、冷気、呪文、...）
 *     damn は攻撃ダメージのダイス個数。
 *     damd は各ダイスの面数。
 *
 *     一部の攻撃はダメージ点を持たない。
 *     また、特殊効果を持ちつつ同時にダメージを与えるものもある。
 *     damn と damd が設定される場合、特別な意味を持つことがある。
 *     例えば盲目化攻撃では、盲目時間の長さを決定する。
 */

struct attack {
    uchar aatyp;
    uchar adtyp, damn, damd;
};

/*     任意モンスターが持ちうる攻撃数の上限。
 */

#define NATTK 6

#ifndef ALIGN_H
#include "align.h"
#endif
#include "monattk.h"
#include "monflag.h"

struct permonst {
    const char *pmnames[NUM_MGENDERS];
    const enum monnums pmidx;   /* mons 配列インデックス（PM_識別子） */
    char mlet;                  /* シンボル */
    schar mlevel,               /* 基本モンスターレベル */
        mmove,                  /* 移動速度 */
        ac,                     /* （基本）防御クラス */
        mr;                     /* （基本）魔法抵抗 */
    aligntyp maligntyp;         /* 基本属性 */
    unsigned short geno;        /* 生成/絶滅マスク値 */
    struct attack mattk[NATTK]; /* 攻撃行列 */
    unsigned cwt;               /* 死体の重量 */
    unsigned short cnutrit;     /* 栄養価 */
    uchar msound;               /* 発する音（6ビット） */
    uchar msize;                /* 物理サイズ（3ビット） */
    uchar mresists;             /* 耐性 */
    uchar mconveys;             /* 食べると得る耐性 */
    unsigned long mflags1,      /* 真偽ビットフラグ */
        mflags2;                /* 追加の真偽ビットフラグ */
    unsigned short mflags3;     /* さらに追加の真偽ビットフラグ */
    uchar difficulty;           /* 強さ（旧 makedefs -m 由来） */
    uchar mcolor;               /* 使用する色 */
};

#define NORMAL_SPEED 12

extern NEARDATA struct permonst mons[NUMMONS + 1]; /* モンスター種の
                                                    * マスター一覧 */

#endif /* PERMONST_H */

