/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-24. */
/* NetHack 3.6	amiconf.h	$NHDT-Date: 1432512775 2015/05/25 00:12:55 $  $NHDT-Branch: master $:$NHDT-Revision: 1.12 $ */
/* Copyright (c) Kenneth Lorber, Bethesda, Maryland, 1990, 1991, 1992, 1993.
 */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef AMICONF_H
#define AMICONF_H

#undef abs /* avoid using macro form of abs */
#undef min /* this gets redefined */
#undef max /* this gets redefined */

#include <time.h> /* 使用前に time_t を定義させる! */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dos/dos.h>
#include <clib/dos_protos.h>
#include <proto/dos.h>

#define MICRO /* 一部インクルードを許可するため定義必須 */

#define NOCWD_ASSUMPTIONS /* HACKDIR, LEVELDIR, SAVEDIR, BONESDIR, DATADIR, \
                             SCOREDIR, LOCKDIR, CONFIGDIR, TROUBLEDIR に \
                             パスを指定できるようにする */

#define PATHLEN 130

/* データライブラリアン定義 */
#define DLBFILE "nhdat"   /* メインライブラリ */
/* nhsdat サウンドライブラリは 5.0 では未使用 */
#undef DLBFILE2

#define FILENAME_CMP strcmpi /* case insensitive */
#define O_BINARY 0

#define MFLOPPY /* 通常は有効推奨。典型的な個人PC構成向けの
                 * 補助機能を提供する
                 */

/* ### amidos.c ### */

extern void nethack_exit(int);

/* ### winreq.c ### */

extern void amii_setpens(int);

extern void getlind(const char *, char *, const char *);
extern void CleanUp(void);
extern void Abort(long) NORETURN;
extern int getpid(void);
extern int kbhit(void);
extern int WindowGetchar(void);
extern void ami_wininit_data(int);

#ifndef MICRO_H
#include "micro.h"
#endif

#ifndef PCCONF_H
#include "pcconf.h" /* remainder of stuff is almost same as the PC */
#endif

#define remove(x) unlink(x)
#define rewind(f) fseek(f, 0, 0)

/*
 * （場合により）設定可能な Amiga オプション:
 */

#define HACKFONT  /* Use special hack.font */
#define MAIL      /* Get mail at unexpected occasions */
#define AMIFLUSH /* toss typeahead (select flush in .cnf) */
#define SFSTRUCT_BUFFERING /* buffered stdio writes for structlevel files */

/* 新しいウィンドウシステムオプション */
/* 誤り - AMIGA_INTUITION は将来的に削除されるべき */
#ifdef AMII_GRAPHICS
#define AMIGA_INTUITION /* 高機能グラフィックスインターフェース (amii) */
#endif

#define CHANGE_COLOR 1
#define DEPTH 6 /* Maximum depth of the screen allowed */
#define AMII_MAXCOLORS (1L << DEPTH)
/* Number of palette entries actually populated in amii_init_map[] (AMII text
 * mode) and amiv_init_map[] (AMIV tile mode).  Indices beyond these read 0. */
#define AMII_PALETTE_SIZE 8
#define AMIV_PALETTE_SIZE 32
typedef unsigned short AMII_COLOR_TYPE;

#define PORT_HELP "amii.hlp"

#undef TERMLIB

#ifdef AMII_GRAPHICS
extern int amii_numcolors;
void amii_setpens(int);
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
#ifdef MFLOPPY
    boolean asksavedisk;
#endif
};
extern struct ami_sysflags sysflags;

#undef SYSCF
#undef SYSCF_FILE

#endif /* AMICONF_H */

