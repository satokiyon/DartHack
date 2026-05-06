/* NetHack 5.0	timeout.h	$NHDT-Date: 1705087443 2024/01/12 19:24:03 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.23 $ */
/* Copyright 1994, Dean Luick                                     */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef TIMEOUT_H
#define TIMEOUT_H

/* 汎用タイムアウト関数 */
typedef void (*timeout_proc)(ANY_P *, long);

/* タイマーの種類 */
enum timer_type {
    TIMER_NONE = 0,
    TIMER_LEVEL = 1,   /* 階層固有イベント [氷が溶ける] */
    TIMER_GLOBAL = 2,  /* 現在のプレイに追随するイベント [未使用] */
    TIMER_OBJECT = 3,  /* オブジェクトに追随するイベント [各種] */
    TIMER_MONSTER = 4, /* モンスターに追随するイベント [未使用] */
    NUM_TIMER_KINDS    /* 5 */
};

/* セーブ/復元用タイマー範囲 */
#define RANGE_LEVEL 0  /* その階層に留まるタイマーをセーブ/復元 */
#define RANGE_GLOBAL 1 /* プレイ全体に追随するタイマーをセーブ/復元 */

/*
 * タイムアウト関数。
 * ここへ enum を追加し、timeout.c のテーブルへも追加すること。
 * "もう1段階の間接参照で全て解決する。"
 * また nhl_get_timertype(nhlua.c) の timerstr[] にも追加すること。
 * そちらの項目はこれらと対応するが綴りは異なる。
 *
 * 注意: 追加・削除・順序変更を行う場合、EDITLEVEL を増やす必要がある。
 * タイマーが存在する状態で保存すると、timeout の添字が save と
 * bones ファイルへ書き込まれるためである。（末尾への追加のみは、
 * 新しい添字が古いデータに存在しないためこの制約を受けない。）
 */
enum timeout_types {
    ROT_ORGANIC = 0, /* 埋まっている有機物用 */
    ROT_CORPSE,
    REVIVE_MON,
    ZOMBIFY_MON,
    BURN_OBJECT,
    HATCH_EGG,
    FIG_TRANSFORM,
    SHRINK_GLOB,
    MELT_ICE_AWAY,

    NUM_TIME_FUNCS
};

#define timer_is_pos(ttype) ((ttype) == MELT_ICE_AWAY)
#define timer_is_obj(ttype) ((ttype) == ROT_ORGANIC      \
                             || (ttype) == ROT_CORPSE    \
                             || (ttype) == REVIVE_MON    \
                             || (ttype) == ZOMBIFY_MON   \
                             || (ttype) == BURN_OBJECT   \
                             || (ttype) == HATCH_EGG     \
                             || (ttype) == FIG_TRANSFORM \
                             || (ttype) == SHRINK_GLOB)

/* timeout.c で使用 */
typedef struct fe {
    struct fe *next;          /* チェーン内の次要素 */
    long timeout;             /* タイムアウト時刻 */
    unsigned long tid;        /* タイマー ID */
    short kind;               /* 用途の種類 */
    short func_index;         /* タイムアウト時に呼び出す先 */
    anything arg;             /* タイムアウト引数へのポインタ */
    Bitfield(needs_fixup, 1); /* arg のパッチ適用が必要か */
} timer_element;

#endif /* TIMEOUT_H */
