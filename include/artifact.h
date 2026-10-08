/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-21. */
/* NetHack 5.0	artifact.h	$NHDT-Date: 1781973076 2026/06/20 16:31:16 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.23 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2011. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef ARTIFACT_H
#define ARTIFACT_H

#include "permonst.h"
#include "prop.h"

/* clang-format off */

#define SPFX_NONE   0x00000000L /* 特殊効果なし、単なるボーナス */
#define SPFX_NOGEN  0x00000001L /* 特別な品。神から授けられる */
#define SPFX_RESTR  0x00000002L /* 制限付き。命名できない */
#define SPFX_INTEL  0x00000004L /* 自我を持つ（知性がある） */
#define SPFX_SPEAK  0x00000008L /* 話せる（未実装） */
#define SPFX_SEEK   0x00000010L /* 物探しを助ける */
#define SPFX_WARN   0x00000020L /* 危険を警告する */
#define SPFX_ATTK   0x00000040L /* 特殊攻撃（attk）を持つ */
#define SPFX_DEFN   0x00000080L /* 特殊防御（defn）を持つ */
#define SPFX_DRLI   0x00000100L /* モンスターのレベルを吸収する */
#define SPFX_SEARCH 0x00000200L /* 探索を補助する */
#define SPFX_BEHEAD 0x00000400L /* モンスターを斬首する */
#define SPFX_HALRES 0x00000800L /* 幻覚を防ぐ */
#define SPFX_ESP    0x00001000L /* ESP（ESP の護符と同様） */
#define SPFX_STLTH  0x00002000L /* 隠密 */
#define SPFX_REGEN  0x00004000L /* 自然回復 */
#define SPFX_EREGEN 0x00008000L /* エネルギー回復 */
#define SPFX_HSPDAM 0x00010000L /* 戦闘中の呪文ダメージを1/2（プレイヤー側） */
#define SPFX_HPHDAM 0x00020000L /* 戦闘中の物理ダメージを1/2（プレイヤー側） */
#define SPFX_TCTRL  0x00040000L /* テレポート制御 */
#define SPFX_LUCK   0x00080000L /* 運を増加（幸運石と同様） */
#define SPFX_DMONS  0x00100000L /* 特定モンスター種への攻撃ボーナス */
#define SPFX_DCLAS  0x00200000L /* シンボル mtype を持つ敵への攻撃ボーナス */
#define SPFX_DFLAG1 0x00400000L /* mflags1 を持つ敵への攻撃ボーナス */
#define SPFX_DFLAG2 0x00800000L /* mflags2 を持つ敵への攻撃ボーナス */
#define SPFX_DALIGN 0x01000000L /* 非同属性モンスターへの攻撃ボーナス  */
#define SPFX_DBONUS 0x01F00000L /* 攻撃ボーナスマスク */
#define SPFX_XRAY   0x02000000L /* プレイヤーにX線視覚を与える */
#define SPFX_REFLECT 0x04000000L /* 反射 */
#define SPFX_PROTECT 0x08000000L /* 保護 */

struct artifact {
    short otyp;
    const char *name;
    unsigned long spfx;  /* 装備（武器/防具）中の特殊効果 */
    unsigned long cspfx; /* 所持しているだけで有効な特殊効果 */
    unsigned long mtype; /* モンスター種、シンボル、またはフラグ */
    struct attack attk, defn, cary;
    uchar inv_prop;     /* アーティファクト起動で得る特性 */
    aligntyp alignment; /* 授与した神の属性 */
    short role;         /* 対応するキャラクター役割 */
    short race;         /* 対応するキャラクター種族 */
    schar gen_spe;      /* 贈与/ランダム生成時の spe への補正 */
    uchar gift_value;   /* これが贈与されるための最小生け贄価値 */
    long cost;          /* ヒーローへの売値（既定: 基本価格×100） */
    char acolor;        /* アーティファクトが「発光」する際の色 */
};

/* 特殊能力を持つ起動特性 */
enum invoke_prop_types {
    TAMING = (LAST_PROP + 1),
    HEALING,
    ENERGY_BOOST,
    UNTRAP,
    CHARGE_OBJ,
    LEV_TELE,
    CREATE_PORTAL,
    ENLIGHTENING,
    CREATE_AMMO,
    BANISH,
    FLING_POISON,
    FIRESTORM,
    SNOWSTORM,
    BLINDING_RAY
};

/* アーティファクト追跡; gift と wish は found を含意する。
   床上、容器内、モンスターの装備/ドロップで見えた場合にも設定される */
struct arti_info {
    Bitfield(exists, 1); /* 1: 対応アーティファクトが生成済み */
    Bitfield(found, 1);  /* 1: ヒーローが存在を把握している */
    Bitfield(gift, 1);   /* 1: 祈り報酬として生成された */
    Bitfield(wish, 1);   /* 1: 願いで生成された */
    Bitfield(named, 1);  /* 1: アイテム命名で作成された */
    Bitfield(viadip, 1); /* 1: 長剣を浸して Excalibur 化した */
    Bitfield(lvldef, 1); /* 1: 特殊階層定義で生成された */
    Bitfield(bones, 1);  /* 1: bones ファイル由来 */
    Bitfield(rndm, 1);   /* 1: ランダム生成 */
};

#endif /* ARTIFACT_H */

