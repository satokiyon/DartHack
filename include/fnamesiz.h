/* NetHack 5.0	fnamesiz.h	$NHDT-Date: 1580310580 2020/01/29 15:09:40 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.1 $ */
/*-Copyright (c) Michael Allison, 2020. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef FNAMESIZ_H
#define FNAMESIZ_H

/*
 *  ファイル名サイズ宣言（NetHack と recover で共有が必要なものを含む）。
 *  ここへ集約することで、両者間で不一致が生じる可能性を減らす。
 */

#if !defined(MICRO) && !defined(VMS) && !defined(WIN32)
#define LOCKNAMESIZE (PL_NSIZ + 14) /* uid+name+.99 に十分な長さ */
#define LOCKNAMEINIT "1lock"
#define BONESINIT "bonesnn.xxx.le"
#define BONESSIZE sizeof(BONESINIT)
#else
#if defined(MICRO)
#define LOCKNAMESIZE FILENAME
#define LOCKNAMEINIT ""
#define BONESINIT ""
#define BONESSIZE FILENAME
#endif
#if defined(VMS)
#define LOCKNAMESIZE (PL_NSIZ + 17) /* _uid+name+.99;1 に十分な長さ */
#define LOCKNAMEINIT "1lock"
#define BONESINIT "bonesnn.xxx_le;1"
#define BONESSIZE sizeof(BONESINIT)
#endif
#if defined(WIN32)
#define LOCKNAMESIZE (PL_NSIZ + 25) /* username+-+name+.99 に十分な長さ */
#define LOCKNAMEINIT ""
#define BONESINIT "bonesnn.xxx.le"
#define BONESSIZE sizeof(BONESINIT)
#endif
#endif

#define INDEXT ".xxxxxx"           /* 最大の識別子サフィックス */
#define INDSIZE sizeof(INDEXT)

#if defined(UNIX) || defined(__BEOS__)
#define SAVEX "save/99999.e"
#ifndef SAVE_EXTENSION
#define SAVE_EXTENSION ""
#endif
#else /* UNIX || __BEOS__ */
#ifdef VMS
#define SAVEX "[.save]nnnnn.e;1"
#ifndef SAVE_EXTENSION
#define SAVE_EXTENSION ""
#endif
#else /* VMS */
#if defined(WIN32) || defined(MICRO)
#define SAVEX ""
#if !defined(SAVE_EXTENSION)
#ifdef MICRO
#define SAVE_EXTENSION ".svh"
#endif
#ifdef WIN32
#define SAVE_EXTENSION ".NetHack-saved-game"
#endif
#endif /* !SAVE_EXTENSION */
#endif /* WIN32 || MICRO */
#endif /* else !VMS */
#endif /* else !(UNIX || __BEOS__) */

#ifndef SAVE_EXTENSION
#define SAVE_EXTENSION ""
#endif

#ifndef MICRO
#define SAVESIZE (PL_NSIZ + sizeof(SAVEX) + sizeof(SAVE_EXTENSION) + INDSIZE)
#else
#define SAVESIZE FILENAME
#endif

#endif /* FNAMESIZ_H */
