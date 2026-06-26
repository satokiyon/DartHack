/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-26. */
/* NetHack 5.0	tradstdc.h	$NHDT-Date: 1781973090 2026/06/20 16:31:30 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.71 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2006. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef TRADSTDC_H
#define TRADSTDC_H

#if defined(DUMB) && !defined(NOVOID)
#define NOVOID
#endif

#ifdef NOVOID
#define void int
#endif

/*
 * Borland C は Borland C++ モードで十分な ANSI C 互換性を提供するので
 * これを有効にする価値がある。ただし ANSI keywords only モードで
 * コンパイルしない限り __STDC__ を設定しないため、そのモードでは
 * <dos.h> や far pointer が使えなくなる。
 */
#if (defined(__STDC__) || defined(__TURBOC__)) && !defined(NOTSTDC)
#define NHSTDC
#endif

#if defined(ultrix) && defined(__STDC__) && !defined(__LANGUAGE_C)
/* Ultrix は常に流動的な状態にあるようだ。この判定は、
 * コンパイラが正しく設定しなかった場合に ANSI 互換性を
 * 整えることを試みる。
 */
#ifdef mips
#define __mips mips
#endif
#ifdef LANGUAGE_C
#define __LANGUAGE_C LANGUAGE_C
#endif
#endif

/*
 * ANSI X3J11 の検出。
 * 古い C 規格との互換性のための代替を用意する。
 */

/* 可変引数リストの扱いを決める:
 * USE_STDARG は ANSI の <stdarg.h> 機能を使うことを意味する
 * （ANSI コンパイラのみ、かつライブラリが対応する場合のみ）。
 * USE_VARARGS は <varargs.h> 機能を使うことを意味する。
 * これもライブラリ対応時のみ使うべきで、ANSI は不要。
 * それ以外では、古い不格好な方法を使う。
 */

/* #define USE_VARARGS */ /* <stdarg.h> の代わりに <varargs.h> を使う */
/* #define USE_OLDARGS */ /* 可変引数機能を一切使わない */

#if defined(apollo) /* Apollo には stdarg(3) はあるが stdarg.h はない */
#define USE_VARARGS
#endif

#if !defined(USE_STDARG) && !defined(USE_VARARGS) && !defined(USE_OLDARGS)
/* 古い VARARGS と OLDARGS の仕組みはまだ残っているが、
   今では C99 必須のため有用である可能性は低い */
#define USE_STDARG
#endif

#ifdef NEED_VARARGS /* 必要な場合のみ定義する */
/*
 * これらは 3.6.0 で変更された。VA_END() は VA_DECL() が隠しで
 * 開く波括弧に対応する閉じ波括弧を提供するため、VA_DECL() で
 * 始めたコードには、明示的な最後の閉じ波括弧に対応する追加の
 * 開き波括弧が必要になる。これは、VA_DECL() が開き波括弧のない
 * 関数を導入したように見えて不自然だったためで、現在は先頭と末尾に
 * 見える/見えない波括弧がある。使用例:
 void foo VA_DECL(int, arg)  --マクロ展開で隠し開き波括弧が入る
 {  --明示的な開き波括弧（実際には入れ子ブロックを導入）
 VA_START(bar);
 ...foo のコード...
 VA_END();  --展開で入れ子ブロック用の閉じ波括弧が入る
 }  --この閉じ波括弧は VA_DECL() 内の隠し波括弧に対応
 * コードを読む場合や波括弧対応を追うツールを使う場合でも、
 * 対応した波括弧の組が見える。VA_END() の使用はやや厄介になりうるが、
 * nethack では単純な形で使っている。
 */

#ifdef USE_STDARG
#include <stdarg.h>
#define VA_DECL(typ1, var1) \
    (typ1 var1, ...)        \
    {                       \
        va_list the_args;
#define VA_DECL2(typ1, var1, typ2, var2) \
    (typ1 var1, typ2 var2, ...)          \
    {                                    \
        va_list the_args;
#define VA_INIT(var1, typ1)
#define VA_NEXT(var1, typ1) (var1 = va_arg(the_args, typ1))
#define VA_ARGS the_args
#define VA_START(x) va_start(the_args, x)
#define VA_END()      \
    va_end(the_args); \
    }
#define VA_PASS1(a1) a1
#if defined(ULTRIX_PROTO) && !defined(_VA_LIST_)
#define _VA_LIST_ /* stdio.h での多重定義を防ぐ */
#endif
#else

#ifdef USE_VARARGS
#include <varargs.h>
#define VA_DECL(typ1, var1) \
    (va_alist) va_dcl       \
    {                       \
        va_list the_args;   \
        typ1 var1;
#define VA_DECL2(typ1, var1, typ2, var2) \
    (va_alist) va_dcl                    \
    {                                    \
        va_list the_args;                \
        typ1 var1;                       \
        typ2 var2;
#define VA_ARGS the_args
#define VA_START(x) va_start(the_args)
#define VA_INIT(var1, typ1) var1 = va_arg(the_args, typ1)
#define VA_NEXT(var1, typ1) (var1 = va_arg(the_args, typ1))
#define VA_END()      \
    va_end(the_args); \
    }
#define VA_PASS1(a1) a1
#else

/*USE_OLDARGS*/
/*
 * 注意: double（float が昇格した double を含む）を渡すと
 * ほぼ確実に壊れる。また sizeof(char *) より大きい整数型でも
 * 同様である。
 * NetHack は浮動小数点を避けており、'long long int' や
 * I64P32 などを使える構成であれば USE_STDARG を使うべきである。
 */
#ifndef VA_TYPE
typedef const char *vA;
#define VA_TYPE
#endif
#define VA_ARGS arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
#define VA_DECL(typ1, var1)                                             \
    (var1, VA_ARGS) typ1 var1; vA VA_ARGS;                              \
    {
#define VA_DECL2(typ1, var1, typ2, var2)                                \
    (var1, var2, VA_ARGS) typ1 var1; typ2 var2; vA VA_ARGS;             \
    {
#define VA_START(x)
#define VA_INIT(var1, typ1)
/* これは本質的に危険であり、本当に最後の手段としてのみ
   試みるべきである。実際には渡されていない引数を操作することは、
   使用中の関数呼び出し/引数受け渡し機構によっては重大な問題を
   起こすことも起こさないこともある。

   [nethack 本体は VA_NEXT() を使わないので VA_SHIFT() も使わない。
   この定義は完全性のために残してあるだけ。
   lev_comp は VA_NEXT() を使うが、すべての 'argX' 引数を渡す。
   注: 5.0.0 時点で lev_comp はもう存在しない。]
 */
#define VA_SHIFT()                                                    \
    (arg1 = arg2, arg2 = arg3, arg3 = arg4, arg4 = arg5, arg5 = arg6, \
     arg6 = arg7, arg7 = arg8, arg8 = arg9, arg9 = 0)
#define VA_NEXT(var1, typ1) ((var1 = (typ1) arg1), VA_SHIFT(), var1)
#define VA_END() }
/* pline.c で必要。そこでは引数の総数が既知で期待通り */
#define VA_PASS1(a1)                                                  \
    (vA) a1, (vA) 0, (vA) 0, (vA) 0, (vA) 0, (vA) 0, (vA) 0, (vA) 0, (vA) 0
#endif
#endif

#endif /* NEED_VARARGS */

/* 汎用ポインタ。常にマクロ; genericptr_t は通常 typedef */
#define genericptr void *
#ifndef genericptr_t
typedef genericptr genericptr_t; /* (void *) または (char *) */
#endif

#ifndef NO_PTR_FMT
/* 実際には、どのシステムが ANSI 実行時ライブラリを持つかを知りたい。
 * そうすればポインタ表示の %p 書式をサポートするか分かる。
 * いまは C99 以降が必須なので、ライブラリは対応しているとみなす。 */
#define HAS_PTR_FMT
#endif

/*
 * ANSI C によれば、旧式関数定義のプロトタイプ
 *   int func(arg) short arg; { ... }
 * では、引数は拡張後の型（char と short は int、float は double）を
 * 指定しなければならない:
 *   int func(int);
 * これはプロトタイプ情報が無いときに狭い型がどのように渡されるかと同じ。
 * しかし多くのコンパイラは、プロトタイプで char や short などの
 * 狭い型を受け入れ、それで型検査を行う。そこで、型検査を改善しつつ
 * ANSI コンパイラ向けの一部プロトタイプも許し、標準に合わせて
 * プロトタイプを「修正」して型検査を失うことがないよう、この面倒な
 * 仕組みがある。
 */
#if defined(MSDOS) && !defined(__GO32__)
#define UNWIDENED_PROTOTYPES
#endif
#if defined(AMIGA) && !defined(AZTEC_50)
#define UNWIDENED_PROTOTYPES
#endif
#if defined(macintosh) && (defined(__SC__) || defined(__MRC__))
#define WIDENED_PROTOTYPES
#endif
#if defined(__MWERKS__) && defined(__BEOS__)
#define UNWIDENED_PROTOTYPES
#endif
#if defined(WIN32)
#define UNWIDENED_PROTOTYPES
#endif

#if defined(ULTRIX_PROTO) && defined(ULTRIX_CC20)
#define UNWIDENED_PROTOTYPES
#endif
#if defined(apollo)
#define UNWIDENED_PROTOTYPES
#endif

#ifndef UNWIDENED_PROTOTYPES
#if defined(NHSTDC) || defined(ULTRIX_PROTO) || defined(THINK_C)
#ifndef WIDENED_PROTOTYPES
#define WIDENED_PROTOTYPES
#endif
#endif
#endif

/* this applies to both VMS and Digital Unix/HP Tru64 */
#ifdef WIDENED_PROTOTYPES
/* ANSI C uses "value preserving rules", where 'unsigned char' and
   'unsigned short' promote to 'int' if signed int is big enough to hold
   all possible values, rather than traditional "sign preserving rules"
   where 'unsigned char' and 'unsigned short' promote to 'unsigned int'.
   However, the ANSI C rules aren't binding on non-ANSI compilers.
   When DEC C (aka Compaq C, then HP C) is in non-standard 'common' mode
   it supports prototypes that expect widened types, but it uses the old
   sign preserving rules for how to widen narrow unsigned types.  (In its
   default 'relaxed' mode, __STDC__ is 1 and uchar widens to 'int'.) */
#if defined(__DECC) && (!defined(__STDC__) || !__STDC__)
#define UCHAR_P unsigned int
#endif
#endif

/* これらは VDECL プロトタイプ宣言内の引数に使う。 */
#ifdef UNWIDENED_PROTOTYPES
#define CHAR_P char
#define SCHAR_P schar
#define UCHAR_P uchar
#define XCHAR_P coordxy
#define SHORT_P short
#ifndef SKIP_BOOLEAN
#define BOOLEAN_P boolean
#endif
#define ALIGNTYP_P aligntyp
#else
#ifdef WIDENED_PROTOTYPES
#define CHAR_P int
#define SCHAR_P int
#ifndef UCHAR_P
#define UCHAR_P int
#endif
#define XCHAR_P int
#define SHORT_P int
#define BOOLEAN_P int
#define ALIGNTYP_P int
#else
/* Neither widened nor unwidened prototypes.  Argument list expansion
 * by VDECL always empty; all xxx_P vanish so defs aren't needed. */
#endif
#endif

/* OBJ_P と MONST_P は、関数ポインタ宣言にのみ使うこと。 */
#if defined(ULTRIX_PROTO) && !defined(__STDC__)
/* Ultrix 2.0 と 2.1 のコンパイラ（それぞれ Ultrix 4.0 と 4.2）では、
 * プロトタイプ中の "struct obj *" 構文を扱えない。バグの内容は違うが、
 * プロトタイプで "void*" を使うと両方とも動くようだ。
 * これにより最小限のプロトタイプ検査は維持しつつ、コンパイラバグを回避する。 */
#define OBJ_P void *
#define MONST_P void *
#else
#define OBJ_P struct obj *
#define MONST_P struct monst *
#endif

#if 0
/* The problem below is still the case through 4.0.5F, but the suggested
 * compiler flags in the Makefiles suppress the nasty messages, so we don't
 * need to be quite so drastic.
 */
#if defined(__sgi) && !defined(__GNUC__)
/*
 * As of IRIX 4.0.1, /bin/cc claims to be an ANSI compiler, but it thinks
 * it's impossible for a prototype to match an old-style definition with
 * unwidened argument types.  Thus, we have to turn off all NetHack
 * prototypes, and avoid declaring several system functions, since the system
 * include files have prototypes and the compiler also complains that
 * prototyped and unprototyped declarations don't match.
 */
#undef VDECL
#define VDECL(f, p) f()
#endif
#endif

/* MetaWare High-C の既定は unsigned char */
/* AIX 3.2 でもこれが必要 */
#if defined(__HC__) || defined(_AIX32)
#undef signed
#endif

/*
 * 言語
 * 標準
 *
 *          NetHack 5.0 の対象範囲
 *         /
 *        /
 *   C2y X      NetHack 3.6 and earlier range
 *   C23 X     /
 *   C17 X    X
 *   C11 X    X
 *   C99 X    X
 *   C89      X
 *
 *
 * NetHack 5.0 のソースコードは現在、次の
 * C99（およびそれ以降）の言語機能を使用している:
 *
 *     列挙子リスト末尾のカンマ
 *     for ループ初期化部での変数宣言
 *     宣言とコードの混在
 *     可変長マクロ
 *     'long long'
 *
 * NetHack 5.0 のソースコードは、C99 を超える次の
 * 言語制約に従っている:
 *
 *     K&R 形式関数定義の廃止
 *     暗黙の int の廃止
 */

/*
 * NetHack ヘッダファイル内で特定の C 規格を簡潔に判定できるよう、
 * NH_C を常に次の3値のいずれか（2025年1月時点）に設定する:
 *
 * NH_C >= 202300L     C23 以上でコンパイル中
 * NH_C >= 199900L     C99 以上でコンパイル中
 * NH_C >= 198900L     C89 以上、または C 規格を判定できなかった
 */
#if defined(__STDC_VERSION__)
#if (__STDC_VERSION__ >= 202000L)
#define NH_C 202300L
#else
#define NH_C 199900L
#endif  /* C23 or C99 */
#else   /* __STDC_VERSION not defined */
#define NH_C 198900L
#endif  /* __STDC_VERSION not defined */
#ifndef NH_C
#define NH_C 198900L
#endif

/* NH_C は 198900L または 199900L または 202300L に定義済み */

#if NH_C >= 202300L
/* まず標準を最優先する */
#ifndef __has_c_attribute
#define __has_c_attribute(x) 0
#endif
/*
 * noreturn
 */
#ifndef ATTRNORETURN
#define ATTRNORETURN [[noreturn]]
/* #warning [[noreturn]] from C23 */
#endif  /* ATTRNORETURN not defined */
/*
 * fallthrough
 */
#if __has_c_attribute(fallthrough)
/* 標準属性が利用可能なのでそれを使う。 */
#define FALLTHROUGH [[fallthrough]]
/* #warning [[fallthrough]] from C23 */
#endif  /* __has_c_attribute(fallthrough) */
/*
 * maybe_unused
 */
#if __has_c_attribute(maybe_unused)
#ifndef ATTRUNUSED
#define ATTRUNUSED [[maybe_unused]]
#endif
#endif  /* __has_c_attribute(maybe_unused) */
#endif  /* NH_C >= 202300L */

/*
 * コンパイラ固有
 */

#ifdef __clang__
/* clang の gcc エミュレーションは nethack の用途には十分 */
#ifndef __GNUC__
#define __GNUC__ 5 /* high enough for returns_nonnull */
#endif
#endif

/*
 * gcc（および #define 上で __GNUC__==5 を名乗る clang も含む）
 *
 * -Wformat によって printf 風呼び出しの引数を検査できるようにする;
 * これをプロトタイプ宣言へ付与する（extern.h の pline() を参照）。
 */
#ifdef __GNUC__
#ifdef ANDROID
#define PRINTF_F(f,v) __attribute__ ((format (__printf__, f, v)))
#elif (__GNUC__ >= 2) && !defined(USE_OLDARGS)
#define PRINTF_F(f, v) __attribute__((format(printf, f, v)))
#if (__GNUC__ > 3) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1)
#define PRINTF_F_PTR(f, v) PRINTF_F(f, v)
#endif
#if __GNUC__ >= 3
#ifndef ATTRUNUSED
#define UNUSED __attribute__((unused))
#endif
#ifndef ATTRNORETURN
#ifndef NORETURN
#define NORETURN __attribute__((noreturn))
/* #warning NORETURN __attribute__((noreturn)) from __GNUC__ >= 3 */
#endif  /* NORETURN */
#endif  /* ATTRNORETURN */
#endif  /* __GNUC__ >= 3 */
#if __GNUC__ >= 5
#ifndef NONNULLS_DEFINED
#define DO_DEFINE_NONNULLS
#endif  /* !NONNULLS_DEFINED */
/* #pragma message is available */
#define NH_PRAGMA_MESSAGE 1
#endif  /* __GNUC__ greater than or equal to 5 */
#if (!defined(__linux__) && !defined(MACOS)) || defined(GCC_URWARN)
 /* disable gcc's __attribute__((__warn_unused_result__)) since explicitly
   discarding the result by casting to (void) is not accepted as a 'use' */
#define __warn_unused_result__ /*empty*/
#define warn_unused_result /*empty*/
#endif  /* GCC_URWARN || !__linux || !MACOS */
#endif  /* __GNUC__ || clang masquerading as __GNUC__==5 */

/*
 * clang 固有
 *
 */
#if defined(__clang__)
#ifndef FALLTHROUGH
#if defined(__clang_major__)
#if __clang_major__ >= 9
#define FALLTHROUGH __attribute__((fallthrough))
/* #warning FALLTHROUGH __attribute__((fallthrough)) from clang */
#endif  /* __clang_major__ greater than or equal to 9 */
#endif  /* __clang_major__ is defined */
#endif  /* FALLTHROUGH */
#if !defined(DO_DEFINE_NONNULLS)
#define DO_DEFINE_NONNULLS
#endif
#endif  /* __clang__ */

/*
 * NONNULL 引数
 */
#if defined(DO_DEFINE_NONNULLS) && !defined(NONNULLS_DEFINED)
#define NONNULL __attribute__((returns_nonnull))
#define NONNULLPTRS __attribute__((nonnull))
#define NONNULLARG1 __attribute__((nonnull (1)))
#define NONNULLARG2 __attribute__((nonnull (2)))
#define NONNULLARG3 __attribute__((nonnull (3)))
#define NONNULLARG4 __attribute__((nonnull (4)))
#define NONNULLARG5 __attribute__((nonnull (5)))
#define NONNULLARG6 __attribute__((nonnull (6)))
#define NONNULLARG7 __attribute__((nonnull (7))) /* for bhit() */
#define NONNULLARG12 __attribute__((nonnull (1, 2)))
#define NONNULLARG23 __attribute__((nonnull (2, 3)))
#define NONNULLARG123 __attribute__((nonnull (1, 2, 3)))
#define NONNULLARG13 __attribute__((nonnull (1, 3)))
#define NONNULLARG14 __attribute__((nonnull (1, 4))) /* for query_category */
#define NONNULLARG134 __attribute__((nonnull (1, 3, 4))) /* for do_stone_mon */
#define NONNULLARG145 __attribute__((nonnull (1, 4, 5))) /* find_roll_to_hit */
#define NONNULLARG17 __attribute__((nonnull (1, 7))) /* for askchain() */
#define NONNULLARG24 __attribute__((nonnull (2, 4))) /* query_objlist() */
#define NONNULLARG45 __attribute__((nonnull (4, 5))) /* do_screen_descri... */
#define NONNULLS_DEFINED
#undef DO_DEFINE_NONNULLS
#endif  /* DO_DEFINE_NONNULLS && !NONNULLS_DEFINED */

/*
 * Microsoft コンパイラ
 */
#ifdef _MSC_VER
#ifndef ATTRNORETURN
#define ATTRNORETURN __declspec(noreturn)
/* #warning ATTRNORETURN __declspec(noreturn) from _MSC_VER */
#endif
/* #pragma message が利用可能 */
#define NH_PRAGMA_MESSAGE 1
#endif  /* _MSC_VER */

#if !defined(UNUSED) && defined(ATTRUNUSED)
#define UNUSED ATTRUNUSED
#endif
#endif

/* フォールバック実装 */
#ifndef PRINTF_F
#define PRINTF_F(f, v)
#endif
#ifndef PRINTF_F_PTR
#define PRINTF_F_PTR(f, v)
#endif
#ifndef UNUSED
#define UNUSED
#endif
#ifndef ATTRUNUSED
#define ATTRUNUSED
#endif
#ifndef FALLTHROUGH
#define FALLTHROUGH
#endif
#ifndef ATTRNORETURN
#define ATTRNORETURN
#endif
#ifndef NORETURN
#define NORETURN
#endif
#ifndef NONNULLS_DEFINED
#define NONNULL
#define NONNULLPTRS
#define NONNULLARG1
#define NONNULLARG2
#define NONNULLARG3
#define NONNULLARG4
#define NONNULLARG5
#define NONNULLARG6
#define NONNULLARG7
#define NONNULLARG12
#define NONNULLARG23
#define NONNULLARG123
#define NONNULLARG13
#define NONNULLARG14
#define NONNULLARG134
#define NONNULLARG145
#define NONNULLARG17
#define NONNULLARG24
#define NONNULLARG45
#define NONNULLS_DEFINED
#endif  /* NONNULLS_DEFINED */
#ifndef NO_NNARGS
#define NO_NNARGS /*empty*/
#endif  /* NO_NNARGS */

/*
 * Allow gcc and clang to catch the use of non-C99 functions that
 * NetHack has replaced with a C99 standard function. The old non-C99
 * function will cause a link failure on non-Unix platforms,
 * so it is preferrable to catch it early, during compile.
 */
#if !defined(X11_BUILD) && !defined(__cplusplus)
#if defined(__GNUC__) && !defined(__clang__)
#if __GNUC__ >= 12
extern char *index(const char *s, int c) __attribute__ ((unavailable));
extern char *rindex(const char *s, int c) __attribute__ ((unavailable));
#endif
#endif
#if defined(__clang__)
#if __clang_major__ >= 7
extern char *index(const char *s, int c) __attribute__ ((unavailable));
extern char *rindex(const char *s, int c) __attribute__ ((unavailable));
#endif
#endif
#endif


#endif /* TRADSTDC_H */

