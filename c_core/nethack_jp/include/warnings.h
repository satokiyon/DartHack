/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-21. */
/* NetHack 5.0	warnings.h	$NHDT-Date: 1781973090 2026/06/20 16:31:30 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.11 $ */
/* Copyright (c) Michael Allison, 2021. */

#ifndef WARNINGS_H
#define WARNINGS_H

/*
 * ENABLE_WARNING_PRAGMAS が定義されている場合、各種コンパイラ向けの
 * 判定が有効になる。
 *
 * 適切なコンパイラが見つかった場合、STDC_Pragma_AVAILABLE が定義される。
 * STDC_Pragma_AVAILABLE が未定義の場合、以下は何もしない定義になる:
 *     DISABLE_WARNING_UNREACHABLE_CODE
 *     DISABLE_WARNING_CONDEXPR_IS_CONSTANT
 *     DISABLE_WARNING_FORMAT_NONLITERAL
 *       ...
 *     RESTORE_WARNINGS
 *     RESTORE_WARNING_CONDEXPR_IS_CONSTANT
 *     RESTORE_WARNING_FORMAT_NONLITERAL
 *
 */

#if !defined(DISABLE_WARNING_PRAGMAS)
#if defined(__STDC_VERSION__)
#if __STDC_VERSION__ >= 199901L
#define ACTIVATE_WARNING_PRAGMAS
#endif /* __STDC_VERSION >= 199901L */
#endif /* __STDC_VERSION */
#if defined(_MSC_VER)
#ifndef ACTIVATE_WARNING_PRAGMAS
#define ACTIVATE_WARNING_PRAGMAS
#endif
#endif
#if defined(__GNUC__) || defined(__clang__)
#if defined(__cplusplus)
#ifndef ACTIVATE_WARNING_PRAGMAS
#define ACTIVATE_WARNING_PRAGMAS
#endif
#endif /* __cplusplus */
#endif /* __GNUC__ || __clang__ */

#ifdef ACTIVATE_WARNING_PRAGMAS
#if defined(__clang__)
#define DISABLE_WARNING_UNREACHABLE_CODE \
    _Pragma("clang diagnostic push")                                    \
    _Pragma("clang diagnostic ignored \"-Wunreachable-code\"")
#define DISABLE_WARNING_FORMAT_NONLITERAL \
    _Pragma("clang diagnostic push")                                    \
    _Pragma("clang diagnostic ignored \"-Wformat-nonliteral\"")
#define DISABLE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_FORMAT_NONLITERAL _Pragma("clang diagnostic pop")
#define RESTORE_WARNING_UNREACHABLE_CODE _Pragma("clang diagnostic pop")
#define RESTORE_WARNINGS _Pragma("clang diagnostic pop")
#define STDC_Pragma_AVAILABLE

#elif defined(__GNUC__)
/* clang とは異なり、gcc では後期バージョンで -Wunreachable-code が
   機能しない（-O1 以上が必要な問題かもしれない） */
#define DISABLE_WARNING_UNREACHABLE_CODE \
    _Pragma("GCC diagnostic push")                                      \
    _Pragma("GCC diagnostic ignored \"-Wunreachable-code\"")
#define DISABLE_WARNING_FORMAT_NONLITERAL \
    _Pragma("GCC diagnostic push")                                      \
    _Pragma("GCC diagnostic ignored \"-Wformat-nonliteral\"")
#define DISABLE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_FORMAT_NONLITERAL _Pragma("GCC diagnostic pop")
#define RESTORE_WARNING_UNREACHABLE_CODE _Pragma("GCC diagnostic pop")
#define RESTORE_WARNINGS _Pragma("GCC diagnostic pop")
#define STDC_Pragma_AVAILABLE

#elif defined(_MSC_VER)
#if _MSC_VER > 1916
#define DISABLE_WARNING_UNREACHABLE_CODE \
    _Pragma("warning( push )")                                  \
    _Pragma("warning( disable : 4702 )")
#define DISABLE_WARNING_FORMAT_NONLITERAL \
    _Pragma("warning( push )")                                  \
    _Pragma("warning( disable : 4774 )")
#define DISABLE_WARNING_CONDEXPR_IS_CONSTANT \
    _Pragma("warning( push )")                                  \
    _Pragma("warning( disable : 4127 )")
#define RESTORE_WARNING_CONDEXPR_IS_CONSTANT _Pragma("warning( pop )")
#define RESTORE_WARNING_FORMAT_NONLITERAL _Pragma("warning( pop )")
#define RESTORE_WARNING_UNREACHABLE_CODE _Pragma("warning( pop )")
#define RESTORE_WARNINGS _Pragma("warning( pop )")
#define STDC_Pragma_AVAILABLE
#else  /* 2019 より前の Visual Studio */
#define DISABLE_WARNING_UNREACHABLE_CODE \
    __pragma(warning(push))                                     \
    __pragma(warning(disable:4702))
#define DISABLE_WARNING_FORMAT_NONLITERAL \
    __pragma(warning(push))                                     \
    __pragma(warning(disable:4774))
#define DISABLE_WARNING_CONDEXPR_IS_CONSTANT \
    __pragma(warning(push))                                     \
    __pragma(warning(disable:4127))
#define RESTORE_WARNING_CONDEXPR_IS_CONSTANT __pragma(warning(pop))
#define RESTORE_WARNING_FORMAT_NONLITERAL __pragma(warning(pop))
#define RESTORE_WARNING_UNREACHABLE_CODE __pragma(warning(pop))
#define RESTORE_WARNINGS  __pragma(warning(pop))
#define STDC_Pragma_AVAILABLE
#endif /* 2019 または 2017 */

#endif /* 各種コンパイラ判定 */
#endif /* ACTIVATE_WARNING_PRAGMAS */
#else  /* DISABLE_WARNING_PRAGMAS */
#if defined(STDC_Pragma_AVAILABLE)
#undef STDC_Pragma_AVAILABLE
#endif
#endif /* DISABLE_WARNING_PRAGMAS */

#if !defined(STDC_Pragma_AVAILABLE)
#define DISABLE_WARNING_UNREACHABLE_CODE
#define DISABLE_WARNING_FORMAT_NONLITERAL
#define DISABLE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_CONDEXPR_IS_CONSTANT
#define RESTORE_WARNING_FORMAT_NONLITERAL
#define RESTORE_WARNING_UNREACHABLE_CODE
#define RESTORE_WARNINGS
#endif

#endif /* WARNINGS_H */

