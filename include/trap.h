/* NetHack 5.0	trap.h	$NHDT-Date: 1670316586 2022/12/06 08:49:46 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.31 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Pasi Kallinen, 2016. */
/* NetHack may be freely redistributed.  See license for details. */

/* 3.1.0 以降の注記: もはや 'makedefs' では操作しない */

#ifndef TRAP_H
#define TRAP_H

union vlaunchinfo {
    short v_launch_otyp; /* 発動対象オブジェクト型 */
    coord v_launch2;     /* 第二発射地点（岩用） */
    uchar v_conjoined;   /* 連結落とし穴位置 */
    short v_tnote;       /* 板: 12 音階        */
};

struct trap {
    struct trap *ntrap;
    coordxy tx, ty;
    d_level dst; /* ポータル/穴/落とし戸の遷移先 */
    coord launch;
#define teledest launch /* テレポート罠の x,y 遷移先（> 0 の場合） */
    Bitfield(ttyp, 5);
    Bitfield(tseen, 1);
    Bitfield(once, 1);
    Bitfield(madeby_u, 1); /* あなたが仕掛けた罠でモンスターが怒るため
                            * 誰が作った罠かを判別できるのは
                            * 不自然ではない（癖がある）。このフラグは
                            * モンスターを解除したときにも必要。
                            * 仕掛けてから解除するだけで平和化できると
                            * 簡単すぎるため。 */
    union vlaunchinfo vl;
#define launch_otyp vl.v_launch_otyp
#define launch2 vl.v_launch2
#define conjoined vl.v_conjoined
#define tnote vl.v_tnote
};

#define newtrap() (struct trap *) alloc(sizeof(struct trap))
#define dealloc_trap(trap) free((genericptr_t)(trap))

/* 石像アニメーションの理由 */
#define ANIMATE_NORMAL 0
#define ANIMATE_SHATTER 1
#define ANIMATE_SPELL 2

/* animate_statue の失敗理由 */
#define AS_OK 0            /* 失敗していない */
#define AS_NO_MON 1        /* makemon 失敗 */
#define AS_MON_IS_UNIQUE 2 /* 石像モンスターが固有 */

/* 注: 罠を追加/削除する場合は mklev.c の trap_engravings[] も調整 */

/* 無条件トラップ */
enum trap_types {
    ALL_TRAPS    = -1, /* mon_knows_traps(), mon_learns_traps() */
    NO_TRAP      =  0,
    ARROW_TRAP   =  1,
    DART_TRAP    =  2,
    ROCKTRAP     =  3,
    SQKY_BOARD   =  4,
    BEAR_TRAP    =  5,
    LANDMINE     =  6,
    ROLLING_BOULDER_TRAP = 7,
    SLP_GAS_TRAP =  8,
    RUST_TRAP    =  9,
    FIRE_TRAP    = 10,
    PIT          = 11,
    SPIKED_PIT   = 12,
    HOLE         = 13,
    TRAPDOOR     = 14,
    TELEP_TRAP   = 15,
    LEVEL_TELEP  = 16,
    MAGIC_PORTAL = 17,
    WEB          = 18,
    STATUE_TRAP  = 19,
    MAGIC_TRAP   = 20,
    ANTI_MAGIC   = 21,
    POLY_TRAP    = 22,
    VIBRATING_SQUARE = 23, /* 罠ではないが、発見後は罠同様に
                            * 表示/記憶される */

    /* 仕掛け扉と仕掛け箱はマップ上の罠ではないが、罠検知後に
       ヒーローが視認して機能/物体を確認するまで、罠として
       表示/記憶されることがある。
       鍵使用または破壊で生き残ったモンスターは同種扉を避ける
       （未実装） */
    TRAPPED_DOOR = 24, /* 扉の一部; マップ上に罠としては存在しない */
    TRAPPED_CHEST = 25, /* オブジェクトの一部; マップ上にない */

    TRAPNUM = 26
};

/* いくつかの罠関連関数の戻り値 */
enum trap_result {
    Trap_Effect_Finished = 0,
    Trap_Is_Gone = 0,
    Trap_Caught_Mon = 1,
    Trap_Killed_Mon = 2,
    Trap_Moved_Mon = 3, /* 新しい場所、または新しいレベル */
};

/* immune_to_trap() の戻り値 */
enum trap_immunities {
    TRAP_NOT_IMMUNE = 0,
    TRAP_CLEARLY_IMMUNE = 1,
    TRAP_HIDDEN_IMMUNE = 2,
};


#define is_pit(ttyp) ((ttyp) == PIT || (ttyp) == SPIKED_PIT)
#define is_hole(ttyp)  ((ttyp) == HOLE || (ttyp) == TRAPDOOR)
#define unhideable_trap(ttyp) ((ttyp) == HOLE) /* 常に可視の罠 */
#define undestroyable_trap(ttyp) ((ttyp) == MAGIC_PORTAL         \
                                  || (ttyp) == VIBRATING_SQUARE)
#define is_magical_trap(ttyp) ((ttyp) == TELEP_TRAP     \
                               || (ttyp) == LEVEL_TELEP \
                               || (ttyp) == MAGIC_TRAP  \
                               || (ttyp) == ANTI_MAGIC  \
                               || (ttyp) == POLY_TRAP)
/* 「移送」系トラップ */
#define is_xport(ttyp) ((ttyp) >= TELEP_TRAP && (ttyp) <= MAGIC_PORTAL)
#define fixed_tele_trap(t) ((t)->ttyp == TELEP_TRAP \
                            && isok((t)->teledest.x,(t)->teledest.y))

#endif /* TRAP_H */
