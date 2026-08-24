/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-24. */
/* NetHack 5.0	rip.c	$NHDT-Date: 1781973064 2026/06/20 16:31:04 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.49 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2017. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"

/* Defining TEXT_TOMBSTONE causes genl_outrip() to exist, but it doesn't
   necessarily have to be used by a binary with multiple window-ports */

#if defined(TTY_GRAPHICS) || defined(X11_GRAPHICS) || defined(GEM_GRAPHICS) \
    || defined(DUMPLOG) || defined(CURSES_GRAPHICS) || defined(SHIM_GRAPHICS) \
    || defined(AMII_GRAPHICS) || defined(ANDROID_GRAPHICS)
#define TEXT_TOMBSTONE
#endif
#if defined(mac) || defined(__BEOS__)
#ifndef TEXT_TOMBSTONE
#define TEXT_TOMBSTONE
#endif
#endif

#ifdef TEXT_TOMBSTONE
staticfn void center(int, char *);

#ifndef NH320_DEDICATION
/* A normal tombstone for end of game display. */
static const char *const rip_txt[] = {
    "                       ----------",
    "                      /          \\",
    "                     /    REST    \\",
    "                    /      IN      \\",
    "                   /     PEACE      \\",
    "                  /                  \\",
    "                  |                  |", /* Name of player */
    "                  |                  |", /* Amount of $ */
    "                  |                  |", /* Type of death */
    "                  |                  |", /* . */
    "                  |                  |", /* . */
    "                  |                  |", /* . */
    "                  |       1001       |", /* Real year of death */
    "                 *|     *  *  *      | *",
    "        _________)/\\\\_//(\\/(/\\)/\\//\\/|_)_______", 0
};
#define STONE_LINE_CENT 28 /* char[] element of center of stone face */
#else                      /* NH320_DEDICATION */
/* NetHack 3.2.x displayed a dual tombstone as a tribute to Izchak. */
static const char *const rip_txt[] = {
    "              ----------                      ----------",
    "             /          \\                    /          \\",
    "            /    REST    \\                  /    This    \\",
    "           /      IN      \\                /  release of  \\",
    "          /     PEACE      \\              /   NetHack is   \\",
    "         /                  \\            /   dedicated to   \\",
    "         |                  |            |  the memory of   |",
    "         |                  |            |                  |",
    "         |                  |            |  Izchak Miller   |",
    "         |                  |            |   1935 - 1994    |",
    "         |                  |            |                  |",
    "         |                  |            |     Ascended     |",
    "         |       1001       |            |                  |",
    "      *  |     *  *  *      | *        * |      *  *  *     | *",
    (" _____)/\\|\\__//(\\/(/\\)/\\//\\/|_)___"
     "_____)/|\\\\_/_/(\\/(/\\)/\\/\\/|_)____"),
    0
};
#define STONE_LINE_CENT 19 /* char[] element of center of stone face */
#endif                     /* NH320_DEDICATION */
#define STONE_LINE_LEN  16 /* # chars that fit on one line
                            * (note 1 ' ' border)           */
#define NAME_LINE  6 /* *char[] line # for player name */
#define GOLD_LINE  7 /* *char[] line # for amount of gold */
#define DEATH_LINE 8 /* *char[] line # for death description */
#define YEAR_LINE 12 /* *char[] line # for year */

/* UTF-8 デコードおよび表示幅計算ヘルパー関数 */

/* 指定された Unicode コードポイントの表示幅（半角=1, 全角=2）を返す */
staticfn int
rip_utf8_char_width(unsigned cp)
{
    if (cp < 0x80)
        return 1;
    /* 半角カタカナ */
    if (cp >= 0xFF61 && cp <= 0xFF9F)
        return 1;
    /* 一般句読点・記号(0x2000〜0x206F)や CJK/東アジア文字(0x1100〜)は幅2とする */
    if ((cp >= 0x2000 && cp <= 0x206F) || cp >= 0x1100) {
        return 2;
    }
    return 1;
}

/* UTF-8 のバイト列からコードポイントをデコードして返す。文字バイト数も返す */
staticfn unsigned
rip_utf8_decode(const char *s, int *len)
{
    unsigned char b0 = (unsigned char)s[0];
    if (b0 < 0x80) {
        *len = 1;
        return b0;
    }
    if (b0 >= 0xC2 && b0 <= 0xDF) {
        if (s[1] == '\0') { *len = 1; return b0; }
        *len = 2;
        return ((b0 & 0x1F) << 6) | ((unsigned char)s[1] & 0x3F);
    }
    if (b0 >= 0xE0 && b0 <= 0xEF) {
        if (s[1] == '\0' || s[2] == '\0') { *len = 1; return b0; }
        *len = 3;
        return ((b0 & 0x0F) << 12) | (((unsigned char)s[1] & 0x3F) << 6) | ((unsigned char)s[2] & 0x3F);
    }
    if (b0 >= 0xF0 && b0 <= 0xF4) {
        if (s[1] == '\0' || s[2] == '\0' || s[3] == '\0') { *len = 1; return b0; }
        *len = 4;
        return ((b0 & 0x07) << 18) | (((unsigned char)s[1] & 0x3F) << 12) | (((unsigned char)s[2] & 0x3F) << 6) | ((unsigned char)s[3] & 0x3F);
    }
    *len = 1;
    return b0;
}

/* UTF-8 文字列全体の表示幅（カラム数）を計算する */
staticfn int
rip_utf8_str_width(const char *str)
{
    int w = 0;
    const char *p = str;
    int seqlen;
    unsigned cp;

    while (*p != '\0') {
        cp = rip_utf8_decode(p, &seqlen);
        w += rip_utf8_char_width(cp);
        p += seqlen;
    }
    return w;
}

/* UTF-8 文字列を指定表示幅 max_width に収まるよう文字境界で切り詰める */
staticfn void
rip_truncate_utf8_width(char *dst, const char *src, int max_width)
{
    int current_width = 0;
    const char *p = src;
    char *d = dst;
    int seqlen = 0;

    while (*p != '\0') {
        unsigned cp = rip_utf8_decode(p, &seqlen);
        int w = rip_utf8_char_width(cp);
        if (current_width + w > max_width)
            break;
        for (int i = 0; i < seqlen; i++) {
            *d++ = *p++;
        }
        current_width += w;
    }
    *d = '\0';
}

staticfn void
center(int line, char *text)
{
    char *op;
    int w = rip_utf8_str_width(text);
    op = &gr.rip[line][STONE_LINE_CENT - ((w + 1) >> 1)];

    /* op 以降の元の文字列のうち、上書きされない残りの部分（op + w 以降）を退避する */
    char temp[BUFSZ];
    Strcpy(temp, op + w);

    /* 新しいテキストをコピーする */
    while (*text) {
        *op++ = *text++;
    }

    /* 退避しておいた残りの部分（| や \0 など）を直後に連結する */
    Strcpy(op, temp);
}

void
genl_outrip(winid tmpwin, int how, time_t when)
{
    char **dp;
    char *dpx;
    char buf[BUFSZ];
    int x;
    int line, year;
    long cash;

    gr.rip = dp = (char **) alloc(sizeof(rip_txt));
    for (x = 0; rip_txt[x]; ++x) {
        /* 日本語（UTF-8）の埋め込みでバイト数が増加するため、余分なバッファを確保する */
        size_t len = strlen(rip_txt[x]);
        dp[x] = (char *) alloc(len + 128);
        Strcpy(dp[x], rip_txt[x]);
    }
    dp[x] = (char *) 0;

    /* Put name on stone (UTF-8 表示幅 16 カラム内で安全切断) */
    rip_truncate_utf8_width(buf, svp.plname, STONE_LINE_LEN);
    center(NAME_LINE, buf);

    /* Put $ on stone */
    cash = max(gd.done_money, 0L);
    /* arbitrary upper limit; practical upper limit is quite a bit less */
    if (cash > 999999999L)
        cash = 999999999L;
    Sprintf(buf, "%ld Au", cash);
    center(GOLD_LINE, buf);

    /* Put together death description */
    jp_formatkiller_for_display(buf, sizeof buf, how, FALSE);

    /* Put death type on stone */
    for (line = DEATH_LINE, dpx = buf; line < YEAR_LINE; line++) {
        char tmpchar;
        int i0 = 0;
        int count_width = 0;
        int last_space_byte = 0;
        int last_space_width = 0;
        boolean is_last_line = (line == YEAR_LINE - 1);

        /* 先頭の余分なスペースをスキップ */
        while (*dpx == ' ')
            dpx++;

        if (*dpx == '\0') {
            break;
        }

        /* 文字境界と表示幅を考慮しながら、STONE_LINE_LEN に収まる位置を探す */
        int byte_idx = 0;
        int seqlen = 0;
        while (dpx[byte_idx] != '\0') {
            unsigned cp = rip_utf8_decode(&dpx[byte_idx], &seqlen);
            int char_w = rip_utf8_char_width(cp);

            if (count_width + char_w > STONE_LINE_LEN) {
                break;
            }

            if (cp == ' ') {
                last_space_byte = byte_idx + seqlen;
                last_space_width = count_width + char_w;
            }

            count_width += char_w;
            byte_idx += seqlen;
        }

        /* 収まる部分の末尾のバイトインデックスを設定 */
        if (dpx[byte_idx] == '\0') {
            /* 文字列全体が収まる場合 */
            i0 = byte_idx;
        } else if (is_last_line) {
            /* 4行目（最終行）で、まだテキストが残っている場合：
               省略記号（日本語 "…" 2幅、英語 "..." 3幅）を付与して切り詰める */
            const char *ellipsis = g_language_is_jp ? "…" : "...";
            int ellipsis_w = rip_utf8_str_width(ellipsis);
            int target_w = STONE_LINE_LEN - ellipsis_w;

            int e_byte = 0;
            int e_width = 0;
            int e_last_space = 0;
            while (dpx[e_byte] != '\0') {
                unsigned cp = rip_utf8_decode(&dpx[e_byte], &seqlen);
                int char_w = rip_utf8_char_width(cp);
                if (e_width + char_w > target_w)
                    break;
                if (cp == ' ')
                    e_last_space = e_byte + seqlen;
                e_width += char_w;
                e_byte += seqlen;
            }

            if (!g_language_is_jp && e_last_space > 0) {
                i0 = e_last_space;
            } else {
                i0 = e_byte;
            }

            char linebuf[BUFSZ];
            int copylen = (i0 < (int)sizeof(linebuf) - 8) ? i0 : (int)sizeof(linebuf) - 8;
            (void) memcpy(linebuf, dpx, copylen);
            linebuf[copylen] = '\0';
            int rlen = (int) strlen(linebuf);
            while (rlen > 0 && linebuf[rlen - 1] == ' ') {
                linebuf[--rlen] = '\0';
            }
            Strcat(linebuf, ellipsis);
            center(line, linebuf);
            dpx += strlen(dpx);
            continue;
        } else {
            /* 途中で切れる場合 */
            if (last_space_byte > 0) {
                if (g_language_is_jp && last_space_width < 10 && count_width >= 12) {
                    i0 = byte_idx;
                } else {
                    i0 = last_space_byte;
                }
            } else {
                i0 = byte_idx;
            }
        }

        /* 万が一、1文字も入らなかった場合の無限ループ防止 */
        if (i0 == 0 && dpx[0] != '\0') {
            (void)rip_utf8_decode(dpx, &seqlen);
            i0 = seqlen;
        }

        tmpchar = dpx[i0];
        dpx[i0] = 0;

        /* center() に渡す前に行末の余分なスペースを除去（RTrim） */
        char linebuf[BUFSZ];
        Strcpy(linebuf, dpx);
        int rlen = (int) strlen(linebuf);
        while (rlen > 0 && linebuf[rlen - 1] == ' ') {
            linebuf[--rlen] = '\0';
        }
        center(line, linebuf);

        if (tmpchar != ' ') {
            dpx[i0] = tmpchar;
            dpx = &dpx[i0];
        } else {
            dpx[i0] = tmpchar;
            dpx = &dpx[i0 + 1];
        }
    }

    /* Put year on stone */
    year = (int) ((yyyymmdd(when) / 10000L) % 10000L);
    Sprintf(buf, "%4d", year);
    center(YEAR_LINE, buf);

#ifdef DUMPLOG
    if (tmpwin == 0)
        dump_forward_putstr(0, 0, "Game over:", TRUE);
    else
#endif
        putstr(tmpwin, 0, "");

    for (; *dp; dp++)
        putstr(tmpwin, 0, *dp);

    putstr(tmpwin, 0, "");
#ifdef DUMPLOG
    if (tmpwin != 0)
#endif
        putstr(tmpwin, 0, "");

    for (x = 0; rip_txt[x]; x++) {
        free((genericptr_t) gr.rip[x]);
    }
    free((genericptr_t) gr.rip);
    gr.rip = 0;
}

#endif /* TEXT_TOMBSTONE */

/*rip.c*/

