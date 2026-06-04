/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-04. */
/* NetHack 5.0	windconf.h	$NHDT-Date: 1596498552 2020/08/03 23:49:12 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.89 $ */
/* Copyright (c) NetHack PC Development Team 1993, 1994.  */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef WINDCONF_H
#define WINDCONF_H

/* #define SHELL */    /* nt で pcsys ルーチンを使うとハングした */

#define EXEPATH              /* .exe の場所を HACKDIR として使えるようにする */
#define TRADITIONAL_GLYPHMAP /* glyph マッピングを階層変更時に保存する */

#define LAN_FEATURES /* LAN 対応機能のコードを含める。3.4.0 では未検証 */

#define PC_LOCKING /* 中断済みまたは進行中ゲームの上書きを防ぐ */
/* まず確認を取る。 */

#define SELF_RECOVER /* ゲーム自身が中断ゲームから復旧できるようにする */

#define SYSCF                /* グローバル設定を使用 */
#define SYSCF_FILE "sysconf" /* SYSCF 設定を保持するファイルを使用 */

#ifdef DUMPLOG
#define DUMPLOG_FILE "%TEMP%/nethack-%n-%d.log"
#endif

/*#define CHANGE_COLOR*/ /* パレット変更を許可 */

#define QWERTZ_SUPPORT  /* swap_yz が True のとき、numpad 7 は 'y' でなく 'z' */

#define OPTIONS_AT_RUNTIME  /* ビルド情報はテキストファイルでなく実行時生成 */

#define EARLY_CONFIGFILE_PASS
#define TTY_PERM_INVENT

#ifdef WIN32CON
#define IDLECHECKPOINT
#endif

#define TIMED_DELAY

/*
 * -----------------------------------------------------------------
 *  以降のコードは通常変更不要。
 * -----------------------------------------------------------------
 */
/* #define SHORT_FILENAMES */ /* すべての NT ファイルシステムは現在長い名前をサポート */

#ifdef DLB
#define VERSION_IN_DLB_FILENAME     /* nhdat にバージョン番号を付加 */
#endif

#ifdef MICRO
#undef MICRO /* これは決して定義しない! */
#endif

#define NOCWD_ASSUMPTIONS /* 常にこれを定義する。WIN32 では定義済み前提の \
                             仮定が存在する。さらに HACKDIR, \
                             LEVELDIR, SAVEDIR, BONESDIR, DATADIR, \
                             SCOREDIR, LOCKDIR, CONFIGDIR, TROUBLEDIR へ \
                             パス指定を許可する */
#define NO_TERMS
#define ASCIIGRAPH

#ifdef OPTIONS_USED
#undef OPTIONS_USED
#endif
#define OPTIONS_USED "options"
#define OPTIONS_FILE OPTIONS_USED

#define PORT_HELP "porthelp"

#define PORT_DEBUG /* 国際キーボード問題をデバッグする機能を含める */

#define RUNTIME_PORT_ID /* 実行時ポート識別を有効化し、\
                         * exe の CPU アーキテクチャ識別に使う */
#define RUNTIME_PASTEBUF_SUPPORT


#define SAFERHANGUP /* SAFERHANGUP を定義するとハングアップ処理を \
                     * メインコマンドループまで遅延する。これは \
                     * いくつかの不正を防ぎ、ハングアップ時に \
                     * 投げていた物品を失わないため、より安全。 */

#define CONFIG_FILE ".nethackrc"
#define CONFIG_TEMPLATE "nethackrc.template"
#define SYSCF_TEMPLATE "sysconf.template"
#define SYMBOLS_TEMPLATE "symbols.template"
#define GUIDEBOOK_FILE "Guidebook.txt"

/* よくあるが重大なユーザーエラーに対処するための補助 */
#define INTERJECT_PANIC 0
#define INTERJECTION_TYPES (INTERJECT_PANIC + 1)
extern void interject_assistance(int, int, genericptr_t, genericptr_t);
extern void interject(int);
extern char *windows_exepath(void);

/*
 *===============================================
 * コンパイラ固有の調整
 *===============================================
 */

#ifdef __GNUC__
#define MD_USE_TMPFILE_S
#
#ifdef strncasecmp
#undef strncasecmp
#endif
#ifdef strcasecmp
#undef strcasecmp
/* https://sourceforge.net/p/mingw-w64/wiki2/gnu%20printf/ */
#endif
/* extern int getlock(void); */
#endif   /* __GNUC__ */

#ifdef _MSC_VER
#define MD_USE_TMPFILE_S
#define HAS_STDINT
#if (_MSC_VER > 1000)
/* Visual C 8 警告の抑制 */
#ifndef _CRT_SECURE_NO_DEPRECATE
#define _CRT_SECURE_NO_DEPRECATE
#endif
#ifndef _SCL_SECURE_NO_DEPRECATE
#define _SCL_SECURE_NO_DEPRECATE
#endif
#ifndef _CRT_NONSTDC_NO_DEPRECATE
#define _CRT_NONSTDC_NO_DEPRECATE
#endif
#pragma warning(disable : 4996) /* VC8 deprecation warnings */
#pragma warning(disable : 4142) /* benign redefinition */
#pragma warning(disable : 4267) /* 'size_t' から XX への変換 */
#if (_MSC_VER > 1600)
#pragma warning(disable : 4459) /* グローバル宣言を隠す */
#endif                          /* _MSC_VER > 1600 */
#endif                          /* _MSC_VER > 1000 */
#pragma warning(disable : 4761) /* 引数で整数サイズ不一致; 変換抑制 */
#ifdef YYPREFIX
#pragma warning(disable : 4102) /* unreferenced label */
#endif
#ifdef __cplusplus
/* cppregex.cpp の警告を抑制 */
#pragma warning(disable : 4101) /* unreferenced local variable */
#endif
#ifndef HAS_STDINT_H
#define HAS_STDINT_H    /* force include of stdint.h in integer.h */
#endif
/* 追加の警告をいくつか有効化 */
#pragma warning(3:4389)

/* ssize_t を提供 */
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;

#endif /* _MSC_VER */

/* 以下は特定関数のプロトタイプに必要 */
#if defined(_MSC_VER)
#include <process.h> /* exit(), spawn() のプロトタイプを提供 */
#endif

#include <string.h> /* strncmpi() などのプロトタイプを提供 */
#ifdef STRNCMPI
#define strncmpi(a, b, c) strnicmp(a, b, c)
#endif


#include <sys/types.h>
#ifdef __BORLANDC__
#undef randomize
#undef random
#endif

#define PATHLEN BUFSZ  /* 最大パス長 */
#define FILENAME BUFSZ /* 最大ファイル名長（保守的） */

#if defined(_MAX_PATH) && defined(_MAX_FNAME)
#if (_MAX_PATH < BUFSZ) && (_MAX_FNAME < BUFSZ)
#undef PATHLEN
#undef FILENAME
#define PATHLEN _MAX_PATH
#define FILENAME _MAX_FNAME
#endif
#endif

#define NO_SIGNAL
#define USE_STDARG

/* 高品質乱数ルーチンを使用する。 */
#ifdef USE_ISAAC64
#undef RANDOM
#else
#define RANDOM
#define Rand() random()
#endif

/* 他に何もなければ C 標準へフォールバックするが、本来これは望ましくない */
#if !defined(USE_ISAAC64) && !defined(RANDOM)
#define Rand() rand()
#endif

#include <sys/stat.h>
#define FCMASK (_S_IREAD | _S_IWRITE) /* ファイル作成マスク */
#define regularize nt_regularize
#define HLOCK "NHPERM"

#ifndef M
#define M(c) ((char) (0x80 | (c)))
/* #define M(c) ((c) - 128) */
#endif

#ifndef C
#define C(c) (0x1f & (c))
#endif

#if defined(DLB) || defined(_MSC_VER)
#define FILENAME_CMP stricmp /* 大文字小文字を区別しない */
#endif

/* これは以前は MICRO 関連の一部だった */
extern const char *alllevels, *allbones;
#define ABORT C('a')
#define getuid() 1
#define getlogin() ((char *) 0)
extern void win32_abort(void);
extern void consoletty_preference_update(const char *);
extern void toggle_mouse_support(void);
extern void map_subkeyvalue(char *);
extern void set_altkeyhandling(const char *);
extern void raw_clear_screen(void);

#include <fcntl.h>
#ifndef __BORLANDC__
#include <io.h>
#include <direct.h>
#else
int _RTLENTRY _EXPFUNC access(const char _FAR *__path, int __amode);
int _RTLENTRY _EXPFUNC _chdrive(int __drive);
int _RTLENTRYF _EXPFUNC32 chdir(const char _FAR *__path);
char _FAR *_RTLENTRY _EXPFUNC getcwd(char _FAR *__buf, int __buflen);
int _RTLENTRY _EXPFUNC
write(int __handle, const void _FAR *__buf, unsigned __len);
int _RTLENTRY _EXPFUNC creat(const char _FAR *__path, int __amode);
int _RTLENTRY _EXPFUNC close(int __handle);
int _RTLENTRY _EXPFUNC _close(int __handle);
int _RTLENTRY _EXPFUNC
open(const char _FAR *__path, int __access, ... /*unsigned mode*/);
long _RTLENTRY _EXPFUNC lseek(int __handle, long __offset, int __fromwhere);
int _RTLENTRY _EXPFUNC read(int __handle, void _FAR *__buf, unsigned __len);
#endif
#undef kbhit /* NT 用の特別な kbhit を使う */
#define kbhit (*nt_kbhit)

#ifdef LAN_FEATURES
#define MAX_LAN_USERNAME 20
#endif

#ifndef alloca
#define ALLOCA_HACK /* util/panic.c で使用 */
#endif

extern int set_win32_option(const char *, const char *);
#define LEFTBUTTON FROM_LEFT_1ST_BUTTON_PRESSED
#define RIGHTBUTTON RIGHTMOST_BUTTON_PRESSED
#define MIDBUTTON FROM_LEFT_2ND_BUTTON_PRESSED
#define MOUSEMASK (LEFTBUTTON | RIGHTBUTTON | MIDBUTTON)
#ifdef CHANGE_COLOR
extern int alternative_palette(char *);
#endif

#define nethack_enter(argc, argv) nethack_enter_windows()
extern boolean file_exists(const char *);
extern boolean file_newer(const char *, const char *);
#ifndef SYSTEM_H
/* #include "system.h" */
#endif

#if defined(WIN_CE)
#define QSORTCALLBACK __cdecl
#endif

/* Override the default version of nhassert.  The default version is unable
 * to generate a string form of the expression due to the need to be
 * compatible with compilers which do not support macro stringization (i.e.
 * #x to turn x into its string form).
 */
extern void nt_assert_failed(const char *, const char *, int);
#define nhassert(expression) (void)((!!(expression)) || \
        (nt_assert_failed(#expression, __FILE__, __LINE__), 0))

#endif /* WINDCONF_H */

