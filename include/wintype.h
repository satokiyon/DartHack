/* NetHack 5.0  wintype.h       $NHDT-Date: 1717880364 2024/06/08 20:59:24 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.52 $ */
/* Copyright (c) David Cohrs, 1991                                */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef WINTYPE_H
#define WINTYPE_H

typedef int winid; /* ウィンドウ識別子 */

/* 汎用パラメータ - ポインタより大きくしてはならない */
typedef union any {
    genericptr_t a_void;
    struct obj *a_obj;
    struct monst *a_monst;
    int a_int;
    int a_xint16;
    int a_xint8;
    char a_char;
    schar a_schar;
    uchar a_uchar;
    unsigned int a_uint;
    long a_long;
    unsigned long a_ulong;
    coordxy a_coordxy;
    int *a_iptr;
    xint16 *a_xint16ptr;
    xint8 *a_xint8ptr;
    long *a_lptr;
    coordxy *a_coordxyptr;
    unsigned long *a_ulptr;
    unsigned *a_uptr;
    const char *a_string;
    int (*a_nfunc)(void);
    unsigned long a_mask32; /* ステータス強調表示で使用 */
    int64 a_int64;
    uint64 a_uint64;
    /* 必要に応じて型を追加 */
} anything;
#define ANY_P union any /* プロトタイプ内で typedef を避ける
                         * （古い Ultrix コンパイラの不具合対策） */

/* anything に格納されるデータ型のシンボリック名 */
enum any_types {
    ANY_VOID = 1,
    ANY_OBJ,         /* struct obj */
    ANY_MONST,       /* struct monst（未使用） */
    ANY_INT,         /* int */
    ANY_CHAR,        /* char */
    ANY_UCHAR,       /* unsigned char */
    ANY_SCHAR,       /* signed char */
    ANY_UINT,        /* unsigned int */
    ANY_LONG,        /* long */
    ANY_ULONG,       /* unsigned long */
    ANY_IPTR,        /* int へのポインタ */
    ANY_UPTR,        /* unsigned int へのポインタ */
    ANY_LPTR,        /* long へのポインタ */
    ANY_ULPTR,       /* unsigned long へのポインタ */
    ANY_STR,         /* ヌル終端 char 文字列へのポインタ */
    ANY_NFUNC,       /* 引数なし int 戻り値関数へのポインタ */
    ANY_MASK32,      /* 32ビットマスク（unsigned long に格納） */

    ANY_INVALID      /* これを最後に置く */
};

/* メニュー戻り値リスト */
typedef struct mi {
    anything item;     /* 識別子 */
    long count;        /* 個数 */
    unsigned itemflags; /* アイテムフラグ */
} menu_item;
#define MENU_ITEM_P struct mi

/* これらは sym.h と display.h にあるべきだが、X11 の
   windowproc インターフェース定義に必要で、X11 側は
   NetHack の主要ヘッダの多くを含まないためここに置く */

struct classic_representation {
    int color;
    int symidx;
};

struct unicode_representation {
    uint32 utf32ch;
    uint8 *utf8str;
};

typedef struct glyph_map_entry {
    unsigned glyphflags;
    struct classic_representation sym;
    uint32 customcolor;
    uint16 color256idx;
    short int tileidx;
#ifdef ENHANCED_SYMBOLS
    struct unicode_representation *u;
#endif
} glyph_map;

/* glyph と追加情報
   フィールド追加や順序変更をする場合は以下を修正:
        display.c の g_info 初期化
        display.c の nul_glyphinfo 初期化
 */
typedef struct glyphinfo {
    int glyph;            /* 表示エンティティ */
    int ttychar;
    uint32 framecolor;
    glyph_map gm;
} glyph_info;
/*#define GLYPH_INFO_P struct glyphinfo //not used*/

/* select_menu() の "how" 引数タイプ */
/* [monst.h の MINV_PICKMASK はこれらが 0, 1, 2 である前提] */
#define PICK_NONE 0 /* ユーザーは選ばない（表示のみ） */
#define PICK_ONE 1  /* 1つだけ選択 */
#define PICK_ANY 2  /* 任意数選択可能 */

/* ウィンドウタイプ */
/* 追加のポート固有タイプは win*.h で定義すること */
#define NHW_MESSAGE 1
#define NHW_STATUS 2
#define NHW_MAP 3
#define NHW_MENU 4
#define NHW_TEXT 5
#define NHW_PERMINVENT 6
#define NHW_LAST_TYPE NHW_PERMINVENT

/* putstr 用属性タイプ; 利便性のため ANSI 値と同じ */
#define ATR_NONE       0
#define ATR_BOLD       1
#define ATR_DIM        2
#define ATR_ITALIC     3
#define ATR_ULINE      4
#define ATR_BLINK      5
#define ATR_INVERSE    7
/* 表示属性ではないが putstr() へ属性として渡す;
   通常表示属性1つとマスク可能 */
#define ATR_URGENT    16
#define ATR_NOHISTORY 32

/* nh_poskey() の修飾子タイプ */
#define CLICK_1 1
#define CLICK_2 2
#define NUM_MOUSE_BUTTONS 2

/* 無効な winid */
#define WIN_ERR ((winid) -1)

/* メニューウィンドウのキーボードコマンド（マップ可能）;
   menu_shift_right/menu_shift_left は永続インベントリ用 */
/* clang-format off */
#define MENU_FIRST_PAGE         '^'
#define MENU_LAST_PAGE          '|'
#define MENU_NEXT_PAGE          '>'
#define MENU_PREVIOUS_PAGE      '<'
#define MENU_SHIFT_RIGHT        '}'
#define MENU_SHIFT_LEFT         '{'
#define MENU_SELECT_ALL         '.'
#define MENU_UNSELECT_ALL       '-'
#define MENU_INVERT_ALL         '@'
#define MENU_SELECT_PAGE        ','
#define MENU_UNSELECT_PAGE      '\\'
#define MENU_INVERT_PAGE        '~'
#define MENU_SEARCH             ':'

#define MENU_ITEMFLAGS_NONE           0x0000000U
#define MENU_ITEMFLAGS_SELECTED       0x0000001U
#define MENU_ITEMFLAGS_SKIPINVERT     0x0000002U
#define MENU_ITEMFLAGS_SKIPMENUCOLORS 0x0000004U

/* 5.0+ の拡張メニューフラグ。すべての window port が
 * 初期段階で対応するとは限らない。
 *
 * 挙動・外観の変更フラグが追加されると、各 window port 側で
 * 適切に反応する更新が必要になる可能性が高い。
 */

#define MENU_BEHAVE_STANDARD      0x0000000U
#define MENU_BEHAVE_PERMINV       0x0000001U

enum perm_invent_toggles {
    toggling_off = -1,
    toggling_not =  0,
    toggling_on  =  1
};

/* perm_invent モード */
enum inv_mode_bits {
    InvNormal   = 1,
    InvShowGold = 2,
    InvSparse   = 4, /* must be ORed with Normal or ShowGold to be valid */
    InvInUse    = 8
};
enum inv_modes { /* 'perminv_mode' option settings */
    InvOptNone       = 0,           /* no perm_invent */
    InvOptOn         = InvNormal,   /* 1 */
    InvOptFull       = InvShowGold, /* 2 */
#if 1 /*#ifdef TTY_PERM_INVENT*/
    /* 名前は紛らわしいが "sparse mode" は、スロットが空でも
       すべてのインベントリ文字を表示する。tty の perm_invent のみ有意 */
    InvOptOn_grid    = InvNormal | InvSparse,   /* 5 */
    InvOptFull_grid  = InvShowGold | InvSparse, /* 6 */
#endif
    InvOptInUse      = InvInUse,    /* 8 */
};

enum to_core_flags {
    active           = 0x001,
    too_small        = 0x002,
    prohibited       = 0x004,
    no_init_done     = 0x008,
    too_early        = 0x010,
};

enum from_core_requests {
    invalid_core_request = 0,
    set_mode             = 1,
    request_settings     = 2,
    set_menu_promptstyle = 3,
};

struct to_core {
    long tocore_flags;
    boolean active;
    boolean use_update_inventory;    /* disable the newer slot interface */
    int maxslot;
    int needrows, needcols;
    int haverows, havecols;
};

struct from_core {
    enum from_core_requests core_request;
    enum inv_modes invmode;
    color_attr menu_promptstyle;
};

struct win_request_info_t {
    struct to_core tocore;
    struct from_core fromcore;
};

typedef struct win_request_info_t win_request_info;
extern win_request_info zerowri;    /* windows.c */

/* #define CORE_INVENT */

/* 複数のウィンドウインターフェースをリンクしたバイナリでは、
 * コンパイル時に静的確定できないインターフェース能力を追跡する
 * 構造体として使用する。いくつかは切替可能で、コアはその時点で
 * 有効かどうかを把握する必要がある。
 */

enum win_display_modes {
    wdmode_traditional = 0,
    wdmode_tiled
};

struct win_settings {
    enum win_display_modes wdmode;
    uint32 map_frame_color;
};

/* clang-format on */

#endif /* WINTYPE_H */
