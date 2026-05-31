/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-06. */
/* NetHack 5.0	pcconf.h	$NHDT-Date: 1596498554 2020/08/03 23:49:14 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.28 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Michael Allison, 2006. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef PCCONF_H
#define PCCONF_H

#define MICRO /* 常にこれを定義! */

#ifdef MSDOS /* このセクションの一部は MS-DOS 固有 */

/*
 *  自動定義:
 *
 *     __GO32__ は gcc の djgpp 版で自動定義される。
 *     __DJGPP__ は djgpp version 2 以降で自動定義される。
 *     _MSC_VER は Microsoft C で自動定義される。
 *     __BORLANDC__ は Borland C で自動定義される。
 *     __SC__ は Symantec C で自動定義される。
 *     注: 3.6.x は Symantec C では未検証。
 */

#define CONFIG_FILE "defaults.nh"
#define GUIDEBOOK_FILE "Guidebook.txt"

/*
 *  次のオプションは、使用コンパイラに応じて
 *  ある程度設定可能。
 */

/*
 *  V7.0 より前の Microsoft コンパイラ向けにのみ、
 *  OVERLAY をここで手動定義する。
 */

/*#define OVERLAY */ /* 手動オーバーレイ定義（MSC 6.0ax のみ） */

#ifndef CROSS_TO_AMIGA
#define SHELL /* via exec of COMMAND.COM */
#endif

/*
 * 画面制御オプション
 *
 * 次のいずれかを有効化できる:
 *    ANSI_DEFAULT
 *    または TERMLIB
 *    または ANSI_DEFAULT と TERMLIB
 *    または NO_TERMS
 */

/* # define TERMLIB */ /* termcap ファイル /etc/termcap を使用 */
                       /* または MSDOS(SAC) では ./termcap */
                       /* これを使うには Fred Fish の termcap ライブラリ */
                       /* （TERMCAP.ARC 同梱）をコンパイル・リンク */

/* # define ANSI_DEFAULT */ /* ./termcap がなくても NetHack を実行可能にする */

#define NO_TERMS /* ansi.sys なしで NetHack を実行できるよう、 */
                 /* 画面ルーチンを .exe にリンクする          */

#ifdef NO_TERMS     /* NO_TERMS の場合、下から画面パッケージを1つ選択 */
#define SCREEN_BIOS /* すべての画面制御に BIOS 呼び出しを使用 */
/* #define SCREEN_DJGPPFAST */ /* djgpp 高速画面ルーチンを使用 */
#endif

/* # define PC9800 */ /* NEC PC-9800 で NetHack を実行可能にする */
/* Yamamoto Keizo */

/*
 * PC ビデオハードウェア対応オプション（グラフィカルタイル用）
 *
 * 下記オプションは任意で有効化できる。
 *
 */
#ifndef SUPPRESS_GRAPHICS
#if (defined(SCREEN_BIOS) || defined(SCREEN_DJGPPFAST)) && !defined(PC9800)
#ifdef TILES_IN_GLYPHMAP
#define SCREEN_VGA /* ビルドに VGA グラフィックスルーチンを含める */
#define SCREEN_VESA
#endif
#endif
#else
#undef NO_TERMS
#undef SCREEN_BIOS
#undef SCREEN_DJGPPFAST
#undef SCREEN_VGA
#undef SCREEN_VESA
#undef TERMLIB
#define ANSI_DEFAULT
#endif

#ifndef CROSS_TO_AMIGA
#define RANDOM /* Berkeley random(3) を使用 */
#endif

#define MAIL /* 疑似メールデーモンによる配達を有効化 */
             /* （MSDOS 版）。(AMIGA の MAIL は */
             /* amiconf.h を参照)。将来はここが */
             /* メールリーダ実装のフックになる。 */

/* 以下は特定関数のプロトタイプに必要 */

#if defined(_MSC_VER) || defined(__BORLANDC__) || defined(__SC__)
#include <process.h> /* Provides prototypes of exit(), spawn()      */
#endif

#ifdef CROSS_TO_AMIGA
#include <spawn.h>
#endif

#if defined(_MSC_VER) && (_MSC_VER >= 7)
#include <sys/types.h>
#ifdef strcmpi
#undef strcmpi
#endif
#include <conio.h>
#include <io.h>
#include <direct.h>
#define SIG_RET_TYPE void(__cdecl *)(int)
#define vprintf printf
#define vfprintf fprintf
#define vsprintf sprintf
#endif

#ifndef M
#define M(c) ((char) (0x80 | (c)))
#endif

/*
 * On the VMS and unix, this option controls whether a delay is done by
 * the clock, or whether it is done by excess output.  On the PC, however,
 * there is always a clock to use for the delay.  The TIMED_DELAY option
 * on MSDOS (without the termcap routines) is used to determine whether to
 * include the delay routines in the code (and thus, provides a compile time
 * method to turn off napping for visual effect).  However, it is also used
 * in the music code to wait between different notes.  So it is needed in that
 * case as well.

 * Whereas on the VMS and unix, flags.nap is a run-time option controlling
 * whether there is a delay by clock or by excess output, on MSDOS it is
 * simply a flag to turn on or off napping for visual effects at run-time.
 */

#define TIMED_DELAY /* `timed_delay` 実行時オプションを有効化 */

#define NOCWD_ASSUMPTIONS /* HACKDIR, LEVELDIR, SAVEDIR, BONESDIR, DATADIR, \
                             SCOREDIR, LOCKDIR, CONFIGDIR, TROUBLEDIR に \
                             パス指定を許可する。 \
                             */

#endif /* MSDOS 設定部分 */

#ifndef PATHLEN
#define PATHLEN 64  /* 最大パス長 */
#endif
#define FILENAME 80 /* 最大ファイル名長（保守的） */
#ifndef MICRO_H
#include "micro.h" /* [os_name].c に必要な extern を含む */
#endif

/* ===================================================
 *  以降のコードは通常変更不要。
 */

#ifndef SYSTEM_H
#if !defined(_MSC_VER)
/* #include "system.h" */
#endif
#endif

#ifdef __DJGPP__
#include <unistd.h> /* close() など */
/* io.h の lock() が decl.h の lock[] と衝突する */
#define lock djlock
#include <io.h>
#undef lock
#include <pc.h> /* kbhit() */
#define PC_LOCKING
#define SELF_RECOVER /* NetHack 自身がゲームをリカバリ可能 */
#endif

#ifdef MSDOS
#ifndef EXEPATH
#define EXEPATH /* 明示定義がない場合、HACKDIR は .exe の場所 */
#endif
#endif

#if defined(_MSC_VER) && defined(MSDOS)
#if (_MSC_VER >= 700) && !defined(FUNCTION_LEVEL_LINKING)
#ifndef MOVERLAY
#define MOVERLAY /* Microsoft's MOVE overlay system (MSC >= 7.0) */
#endif
#endif
#define PC_LOCKING
#endif

/* Borland 関連 */
#if defined(__BORLANDC__)
#if defined(__OVERLAY__) && !defined(VROOMM)
/* __OVERLAY__ は Borland C でオーバーレイ有効時に自動定義 */
#define VROOMM /* Borland の VROOMM オーバーレイシステム */
#endif
#if !defined(STKSIZ)
#define STKSIZ 5 * 1024 /* Borland C の既定スタック 5K を使用 */
                        /* このマクロは main() を含むファイルで使用 */
#endif
#define PC_LOCKING
#endif

#ifdef PC_LOCKING
#define HLOCK "NHPERM"
#endif

/* 高品質乱数ルーチン */
#ifndef USE_ISAAC64
# ifdef RANDOM
#  define Rand() random()
# else
#  define Rand() rand()
# endif
#endif

#ifndef TOS
#define FCMASK 0660 /* ファイル作成マスク */
#endif

#include <fcntl.h>

#ifdef MSDOS
#define PORT_HELP "msdoshlp.txt" /* msdos ポート固有ヘルプファイル */
#endif

/* 整合性チェック。以下ブロックは変更しないこと。 */

#if defined(MSDOS) && defined(NO_TERMS)
#ifdef TERMLIB
#if defined(_MSC_VER) || defined(__SC__)
#pragma message("Warning -- TERMLIB defined with NO_TERMS in pcconf.h")
#pragma message("           Forcing undef of TERMLIB")
#endif
#undef TERMLIB
#endif
#ifdef ANSI_DEFAULT
#if defined(_MSC_VER) || defined(__SC__)
#pragma message("Warning -- ANSI_DEFAULT defined with NO_TERMS in pcconf.h")
#pragma message("           Forcing undef of ANSI_DEFAULT")
#endif
#undef ANSI_DEFAULT
#endif
/* only one screen package is allowed */
#if defined(SCREEN_BIOS) && defined(SCREEN_DJGPPFAST)
#if defined(_MSC_VER) || defined(__SC__)
#pragma message("Warning -- More than one screen package defined in pcconf.h")
#endif
#if defined(_MSC_VER) || defined(__BORLANDC__) || defined(__SC__)
#if defined(SCREEN_DJGPPFAST)
#if defined(_MSC_VER) || defined(__SC__)
#pragma message("           Forcing undef of SCREEN_DJGPPFAST")
#endif
#undef SCREEN_DJGPPFAST /* Can't use djgpp fast with other compilers anyway \
                           */
#endif
#else
/* djgpp C compiler */
#if defined(SCREEN_BIOS)
#undef SCREEN_BIOS
#endif
#endif
#endif
#define ASCIIGRAPH
#define VIDEOSHADES
/* SCREEN_8514, SCREEN_VESA は現状プレースホルダのみ - VGA に置換 */
#if defined(SCREEN_8514)
#undef SCREEN_8514
#define SCREEN_VGA
#endif
/* グラフィカルタイル整合性チェック */
#ifdef SCREEN_VGA
#define SIMULATE_CURSOR
#define POSITIONBAR
/* 適切なタイルファイル形式とマップサイズを選択 */
#define PLANAR_FILE
#define SMALL_MAP
#endif
#endif /* End of sanity check block */

#if defined(MSDOS) && defined(DLB)
#define FILENAME_CMP stricmp /* 大文字小文字を区別しない */
#endif

#if defined(_MSC_VER) && (_MSC_VER >= 7)
#pragma warning(disable : 4131)
#pragma warning(disable : 4135)
#pragma warning(disable : 4309)
#pragma warning(disable : 4746)
#pragma warning(disable : 4761)
#endif

#ifdef TIMED_DELAY
#ifdef __DJGPP__
#define msleep(k) (void) usleep((k) *1000)
#endif
#ifdef __BORLANDC__
#define msleep(k) delay(k)
#endif
#ifdef __SC__
#define msleep(k) (void) usleep((long)((k) *1000))
#endif
#endif

#endif /* PCCONF_H */

