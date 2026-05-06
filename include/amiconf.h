/* NetHack 3.6	amiconf.h	$NHDT-Date: 1432512775 2015/05/25 00:12:55 $  $NHDT-Branch: master $:$NHDT-Revision: 1.12 $ */
/* Copyright (c) Kenneth Lorber, Bethesda, Maryland, 1990, 1991, 1992, 1993.
 */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef AMICONF_H
#define AMICONF_H

#undef abs /* abs のマクロ形式を使わない */
#ifndef __SASC_60
#undef min /* これは再定義される */
#undef max /* これは再定義される */
#endif

#include <time.h> /* 使用前に time_t を定義させる! */

#ifdef CROSS_TO_AMIGA
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dos/dos.h>
#include <clib/dos_protos.h>
#include <proto/dos.h>
#endif

#ifdef __SASC_60    /* SAS は再インクルード防止を行うため */
#include <stdlib.h> /* ビルトインを含む一般的なもの */
#include <string.h>
#endif

#ifdef AZTEC_50
#include <stdlib.h>
#define AZTEC_C_WORKAROUND /* sounds.c で発生するバグへの回避策。 */
#define NO_SIGNAL          /* 5.0 のシグナル処理は SIGINT と相性が悪い... */
#endif

#ifdef _DCC
#include <stdlib.h>
#define _SIZE_T
#endif

#ifndef __GNUC__
typedef long off_t;
#endif

#define MICRO /* 一部インクルードを許可するため定義必須 */

#define NOCWD_ASSUMPTIONS /* HACKDIR, LEVELDIR, SAVEDIR, BONESDIR, DATADIR, \
                             SCOREDIR, LOCKDIR, CONFIGDIR, TROUBLEDIR に \
                             パスを指定できるようにする */

#define PATHLEN 130

/* データライブラリアン定義 */
#define DLBFILE "nhdat"   /* メインライブラリ */
/* nhsdat サウンドライブラリは 5.0 では未使用 */
#undef DLBFILE2

#ifndef CROSS_TO_AMIGA
#define FILENAME_CMP stricmp /* 大文字小文字を区別しない */
#else
#define FILENAME_CMP strcmpi /* 大文字小文字を区別しない */
#endif

#ifndef __SASC_60
#define O_BINARY 0
#endif

/* Compile in New Intuition look for 2.0 */
#ifdef IDCMP_CLOSEWINDOW
#ifndef INTUI_NEW_LOOK
#define INTUI_NEW_LOOK 1
#endif
#endif

#define MFLOPPY /* 通常は有効推奨。典型的な個人PC構成向けの
                 * 補助機能を提供する
                 */
#ifndef CROSS_TO_AMIGA
#define RANDOM
#endif

/* ### amidos.c ### */

extern void nethack_exit(int);

/* ### amiwbench.c ### */

extern void ami_wbench_init(void);
extern void ami_wbench_args(void);
extern int ami_wbench_getsave(int);
extern void ami_wbench_unlink(char *);
extern int ami_wbench_iconsize(char *);
extern void ami_wbench_iconwrite(char *);
extern int ami_wbench_badopt(const char *);
extern void ami_wbench_cleanup(void);
extern void getlind(const char *, char *, const char *);

/* ### winreq.c ### */

extern void amii_setpens(int);

extern void exit(int);
extern void CleanUp(void);
extern void Abort(long);
extern int getpid(void);
extern char *CopyFile(const char *, const char *);
extern int kbhit(void);
extern int WindowGetchar(void);
extern void ami_argset(int *, char *[]);
extern void ami_mkargline(int *, char **[]);
extern void ami_wininit_data(int);

#define FromWBench 0 /* コンパイラ向けヒント ... */
/* extern boolean FromWBench;  起動元情報 */
extern int ami_argc;
extern char **ami_argv;

#ifndef MICRO_H
#include "micro.h"
#endif

#ifndef PCCONF_H
#include "pcconf.h" /* remainder of stuff is almost same as the PC */
#endif

#define remove(x) unlink(x)

/* DICE では rewind() の戻り値が void になる。	こちらは int にしたい。 */
#if defined(_DCC) || defined(__GNUC__)
#define rewind(f) fseek(f, 0, 0)
#endif

#ifdef AZTEC_C
extern FILE *freopen(const char *, const char *, FILE *);
extern char *gets(char *);
#endif

/*
 * IF AZTEC_C  we can't use the long cpath in vision.c....
 */
#ifdef AZTEC_C
#undef MACRO_CPATH
#endif

/*
 * （場合により）設定可能な Amiga オプション:
 */

#define HACKFONT  /* 特殊な hack.font を使用 */
#ifndef CROSS_TO_AMIGA   /* プロトタイプと spawnl の問題回避 */
#define SHELL  /* シェルエスケープコマンド (!) を有効化 */
#endif
#define MAIL      /* 予期しないタイミングでメールを受け取る */
#define DEFAULT_ICON "NetHack:default.icon" /* 専用アイコン */
#define AMIFLUSH /* 先行入力を破棄（.cnf の select flush） */
/* #define OPT_DISPMAP */ /* fast_map オプションを有効化 */

/* 新しいウィンドウシステムオプション */
/* 誤り - AMIGA_INTUITION は将来的に削除されるべき */
#ifdef AMII_GRAPHICS
#define AMIGA_INTUITION /* 高機能グラフィックスインターフェース (amii) */
#endif

#define CHANGE_COLOR 1
#define DEPTH 6 /* Maximum depth of the screen allowed */
#define AMII_MAXCOLORS (1L << DEPTH)
typedef unsigned short AMII_COLOR_TYPE;

#define PORT_HELP "nethack:amii.hlp"

#undef TERMLIB

#define AMII_MUFFLED_VOLUME 40
#define AMII_SOFT_VOLUME 50
#define AMII_OKAY_VOLUME 60
#define AMII_LOUDER_VOLUME 80

#ifdef TTY_GRAPHICS
#define ANSI_DEFAULT
#endif

extern int amibbs; /* BBS モード? */

#ifdef AMII_GRAPHICS
extern int amii_numcolors;
void amii_setpens(int);
#endif

/* for cmd.c: override version in micro.h */
#ifdef __SASC_60
#undef M
#define M(c) ((c) -128)
#endif
struct ami_sysflags {
    char sysflagsid[10];
#ifdef AMIFLUSH
    boolean altmeta;  /* ALT キーを META として使用 */
    boolean amiflush; /* 先行入力を破棄 */
#endif
#ifdef AMII_GRAPHICS 
    int numcols;
    unsigned short amii_dripens[20]; /* DrawInfo Pens（現状 v39 では 13） */
    AMII_COLOR_TYPE amii_curmap[AMII_MAXCOLORS]; /* カラーマップ */
#endif
#ifdef OPT_DISPMAP
    boolean fast_map; /* 最適化された（柔軟性は低い）マップ表示を使用 */
#endif
#ifdef MFLOPPY
    boolean asksavedisk;
#endif
};
extern struct ami_sysflags sysflags;

#undef SYSCF
#undef SYSCF_FILE

#endif /* AMICONF_H */
