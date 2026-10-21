/* flutter_compat.h
 * Cross-platform Compatibility Layer for NetHack Flutter Port (Android & Windows)
 */

#ifndef FLUTTER_COMPAT_H
#define FLUTTER_COMPAT_H

#if defined(FLUTTER_PORT)
# if defined(_WIN32) && !defined(FLUTTER_WIN32)
#  define FLUTTER_WIN32
# endif
# if defined(__ANDROID__) && !defined(FLUTTER_ANDROID)
#  define FLUTTER_ANDROID
# endif
#endif

#ifdef FLUTTER_WIN32

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <io.h>
#include <direct.h>
#include <process.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <BaseTsd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#ifdef WIN32
#undef WIN32
#endif

#ifndef F_OK
#define F_OK 0
#endif
#ifndef R_OK
#define R_OK 4
#endif
#ifndef W_OK
#define W_OK 2
#endif
#ifndef X_OK
#define X_OK 0
#endif
#define access _access

#define NH_EXPORT __declspec(dllexport)

#include <sys/types.h>
typedef SSIZE_T ssize_t;
#ifndef _OFF_T_DEFINED
typedef long off_t;
#define _OFF_T_DEFINED
#endif

#define usleep(us) Sleep(((us) + 999) / 1000)
#define sleep(s) Sleep((s) * 1000)

#ifndef PATH_MAX
#define PATH_MAX MAX_PATH
#endif

#ifndef S_ISDIR
#define S_ISDIR(mode) (((mode) & _S_IFMT) == _S_IFDIR)
#endif
#ifndef S_ISREG
#define S_ISREG(mode) (((mode) & _S_IFMT) == _S_IFREG)
#endif

#define strncasecmp _strnicmp
#define strcasecmp _stricmp

#define getuid() 10470
#define getlogin() "Player"

#define __sync_fetch_and_add(ptr, val) ((int)InterlockedExchangeAdd((volatile LONG *)(ptr), (LONG)(val)))
#define __sync_synchronize() MemoryBarrier()

/* 軽量 dirent / scandir 互換実装 (files.c: get_saved_games 用) */
struct dirent {
    char d_name[MAX_PATH];
};

static inline int win32_scandir(const char *dirp, struct dirent ***namelist,
                                int (*filter)(const struct dirent *),
                                int (*compar)(const struct dirent **, const struct dirent **)) {
    char search_path[MAX_PATH];
    snprintf(search_path, sizeof(search_path), "%s\\*", dirp);
    WIN32_FIND_DATAA fd;
    HANDLE hFind = FindFirstFileA(search_path, &fd);
    if (hFind == INVALID_HANDLE_VALUE) {
        *namelist = NULL;
        return -1;
    }
    int count = 0;
    int capacity = 16;
    struct dirent **list = (struct dirent **)malloc(capacity * sizeof(struct dirent *));
    if (!list) {
        FindClose(hFind);
        *namelist = NULL;
        return -1;
    }
    do {
        if (strcmp(fd.cFileName, ".") == 0 || strcmp(fd.cFileName, "..") == 0) continue;
        struct dirent ent;
        strncpy(ent.d_name, fd.cFileName, sizeof(ent.d_name) - 1);
        ent.d_name[sizeof(ent.d_name) - 1] = '\0';
        if (filter && !filter(&ent)) continue;
        if (count >= capacity) {
            capacity *= 2;
            struct dirent **new_list = (struct dirent **)realloc(list, capacity * sizeof(struct dirent *));
            if (!new_list) {
                break;
            }
            list = new_list;
        }
        struct dirent *d = (struct dirent *)malloc(sizeof(struct dirent));
        if (d) {
            *d = ent;
            list[count++] = d;
        }
    } while (FindNextFileA(hFind, &fd));
    FindClose(hFind);
    if (compar && count > 1) {
        qsort(list, count, sizeof(struct dirent *), (int (*)(const void *, const void *))compar);
    }
    *namelist = list;
    return count;
}
#define scandir win32_scandir

/* Windows UCRT (open.cpp:164) における pmode デバッグアサーションクラッシュの防止
 * (pmode & (~(_S_IREAD | _S_IWRITE))) == 0 の要件を満たすため、
 * Unix 権限（0666, 0660 等）から Windows で有効な _S_IREAD | _S_IWRITE (0600) のみにサニタイズする。
 * また UTF-8 パスを _wopen / _wcreat に変換して日本語 Windows パスにも対応。
 */
static inline wchar_t* flutter_win32_utf8_to_w(const char* s) {
    if (!s) return NULL;
    int wlen = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
    if (wlen <= 0) return NULL;
    wchar_t* wbuf = (wchar_t*)malloc(wlen * sizeof(wchar_t));
    if (wbuf) MultiByteToWideChar(CP_UTF8, 0, s, -1, wbuf, wlen);
    return wbuf;
}

static inline int flutter_win32_open(const char* path, int oflag, ...) {
    int pmode = 0;
    if (oflag & (_O_CREAT | O_CREAT)) {
        va_list ap;
        va_start(ap, oflag);
        pmode = va_arg(ap, int);
        va_end(ap);

        /* UCRT アサーション対策: _S_IREAD | _S_IWRITE 以外をマスク */
        int safe_pmode = 0;
        if (pmode & (0400 | 0040 | 0004 | _S_IREAD)) safe_pmode |= _S_IREAD;
        if (pmode & (0200 | 0020 | 0002 | _S_IWRITE)) safe_pmode |= _S_IWRITE;
        if (!safe_pmode) safe_pmode = _S_IREAD | _S_IWRITE;
        pmode = safe_pmode;
    }
    wchar_t* wpath = flutter_win32_utf8_to_w(path);
    int fd;
    if (wpath) {
        fd = _wopen(wpath, oflag, pmode);
        free(wpath);
    } else {
        fd = _open(path, oflag, pmode);
    }
    return fd;
}

static inline int flutter_win32_creat(const char* path, int pmode) {
    int safe_pmode = 0;
    if (pmode & (0400 | 0040 | 0004 | _S_IREAD)) safe_pmode |= _S_IREAD;
    if (pmode & (0200 | 0020 | 0002 | _S_IWRITE)) safe_pmode |= _S_IWRITE;
    if (!safe_pmode) safe_pmode = _S_IREAD | _S_IWRITE;

    wchar_t* wpath = flutter_win32_utf8_to_w(path);
    int fd;
    if (wpath) {
        fd = _wcreat(wpath, safe_pmode);
        free(wpath);
    } else {
        fd = _creat(path, safe_pmode);
    }
    return fd;
}
#define open flutter_win32_open
#define creat flutter_win32_creat

#else /* FLUTTER_ANDROID or POSIX */

#include <unistd.h>
#include <pthread.h>
#include <android/log.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <pwd.h>
#include <dirent.h>

#define NH_EXPORT __attribute__((visibility("default")))

#endif /* FLUTTER_WIN32 */

#endif /* FLUTTER_COMPAT_H */

