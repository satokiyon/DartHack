/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. */
/* NetHack 5.0	getline.c	$NHDT-Date: 1701285885 2023/11/29 19:24:45 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.59 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Michael Allison, 2006. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"

#ifdef TTY_GRAPHICS

#if !defined(MACOS9)
#define NEWAUTOCOMP
#endif

#include "wintty.h"
#include "func_tab.h"

char morc = 0; /* tell the outside world what char you chose */
static boolean suppress_history;
static boolean ext_cmd_getlin_hook(char *);

typedef boolean (*getlin_hook_proc)(char *);

static void hooked_tty_getlin(const char *, char *, getlin_hook_proc);
static int getlin_utf8_sequence_len(const unsigned char *);
static int getlin_utf8_cells(const char *);
static int getlin_utf8_char_display_width(const unsigned char *);
static void getlin_put_backspaces(int);
static void getlin_put_spaces(int);
extern int extcmd_via_menu(void); /* cmd.c */

extern char erase_char, kill_char; /* from appropriate tty.c file */

#ifdef WIN32CON
#define NH_C3_NONSPACING 0x0001U
#define NH_C3_KATAKANA   0x0010U
#define NH_C3_HIRAGANA   0x0020U
#define NH_C3_HALFWIDTH  0x0040U
#define NH_C3_FULLWIDTH  0x0080U
#define NH_C3_IDEOGRAPH  0x0100U

static unsigned short getlin_utf8_char_chartype(const unsigned char *);
extern int __stdcall MultiByteToWideChar(unsigned int, unsigned long,
                                         const char *, int, wchar_t *, int);
extern int __stdcall GetStringTypeW(unsigned long, const wchar_t *, int,
                                    unsigned short *);
#endif

static int
getlin_utf8_sequence_len(const unsigned char *utf8str)
{
    unsigned char c = *utf8str;

    if ((c & 0x80U) == 0)
        return 1;
    if ((c & 0xE0U) == 0xC0U && (utf8str[1] & 0xC0U) == 0x80U)
        return 2;
    if ((c & 0xF0U) == 0xE0U && (utf8str[1] & 0xC0U) == 0x80U
        && (utf8str[2] & 0xC0U) == 0x80U)
        return 3;
    if ((c & 0xF8U) == 0xF0U && (utf8str[1] & 0xC0U) == 0x80U
        && (utf8str[2] & 0xC0U) == 0x80U
        && (utf8str[3] & 0xC0U) == 0x80U)
        return 4;
    return 1;
}

static int
getlin_utf8_cells(const char *str)
{
    const unsigned char *cp = (const unsigned char *) str;
    int total = 0;

    if (!cp)
        return 0;

    while (*cp) {
        if (*cp < 0x80U) {
            ++total;
            ++cp;
        } else {
            int ulen = getlin_utf8_sequence_len(cp);

            if (ulen > 1) {
                int width = getlin_utf8_char_display_width(cp);

                total += (width > 0) ? width : 1;
                cp += ulen;
            } else {
                ++total;
                ++cp;
            }
        }
    }

    return total;
}

static int
getlin_utf8_char_display_width(const unsigned char *utf8str)
{
#ifdef WIN32CON
    unsigned short chartype = getlin_utf8_char_chartype(utf8str);

    if (chartype & NH_C3_NONSPACING)
        return 0;
    if (chartype & (NH_C3_FULLWIDTH | NH_C3_KATAKANA
                    | NH_C3_HIRAGANA | NH_C3_IDEOGRAPH))
        return 2;
    if (chartype & NH_C3_HALFWIDTH)
        return 1;
#endif
    return (*utf8str < 0x80U) ? 1 : 1;
}

#ifdef WIN32CON
static unsigned short
getlin_utf8_char_chartype(const unsigned char *utf8str)
{
    wchar_t wch[2] = { 0, 0 };
    unsigned short chartype = 0;
    int ulen = getlin_utf8_sequence_len(utf8str);

    if (ulen <= 1)
        return 0;
    if (MultiByteToWideChar(65001U, 0x00000008UL,
                            (const char *) utf8str, ulen, wch, 1)
        != 1)
        return 0;
    if (!GetStringTypeW(0x0004UL, wch, 1, &chartype))
        return 0;
    return chartype;
}
#endif

static void
getlin_put_backspaces(int cells)
{
    while (cells-- > 0)
        putsyms("\b");
}

static void
getlin_put_spaces(int cells)
{
    while (cells-- > 0)
        putsyms(" ");
}

/*
 * Read a line closed with '\n' into the array char bufp[BUFSZ].
 * (The '\n' is not stored. The string is closed with a '\0'.)
 * Reading can be interrupted by an escape ('\033').  If there is already
 * some text, it is removed and prompting continues as if from the start.
 * However, if there is no text yet (or anymore) then "\033" is returned.
 */
void
tty_getlin(const char *query, char *bufp)
{
    suppress_history = FALSE;
    hooked_tty_getlin(query, bufp, (getlin_hook_proc) 0);
}

static void
hooked_tty_getlin(
    const char *query,
    char *bufp,
    getlin_hook_proc hook)
{
    char *obufp = bufp;
    int c;
    uint8 utf8buf[8];
    struct WinDesc *cw = wins[WIN_MESSAGE];
    boolean doprev = FALSE;

    if (ttyDisplay->toplin == TOPLINE_NEED_MORE && !(cw->flags & WIN_STOP))
        more();
    cw->flags &= ~WIN_STOP;
    ttyDisplay->toplin = TOPLINE_SPECIAL_PROMPT;
    ttyDisplay->inread++;

    /*
     * Issue the prompt.
     *
     * custompline() will call vpline() which calls flush_screen() which
     * calls bot(). The core now disables bot() processing while inside
     * getlin, so the screen won't be modified during whatever this prompt
     * is for.
     */
    custompline(OVERRIDE_MSGTYPE | SUPPRESS_HISTORY, "%s ", query);

#ifdef EDIT_GETLIN
    /* bufp is input/output; treat current contents (presumed to be from
       previous getlin()) as default input */
    addtopl(obufp);
    bufp = eos(obufp);
#else
    /* !EDIT_GETLIN: bufp is output only; init it to empty */
    *bufp = '\0';
#endif

    for (;;) {
        (void) fflush(stdout);
        Strcat(strcat(strcpy(gt.toplines, query), " "), obufp);
        term_curs_set(1);
        /* tty getlin needs full-width input values; pgetchar() returns
         * char and can truncate IME-committed Unicode characters. */
        c = tty_nhgetch();
        term_curs_set(0);
        if (c == '\033' || c == EOF) {
            if (c == EOF)
                iflags.term_gone = 1;
            if (c == '\033' && obufp[0] != '\0') {
                obufp[0] = '\0';
                bufp = obufp;
                tty_clear_nhwindow(WIN_MESSAGE);
                cw->maxcol = cw->maxrow;
                addtopl(query);
                addtopl(" ");
                addtopl(obufp);
            } else {
                obufp[0] = '\033';
                obufp[1] = '\0';
                break;
            }
        }
        if (ttyDisplay->intr) {
            ttyDisplay->intr--;
            *bufp = 0;
        }
        if (c == C('p')) { /* ctrl-P, doesn't honor rebinding #prevmsg cmd */
            int sav = ttyDisplay->inread;

            ttyDisplay->inread = 0;
            if (iflags.prevmsg_window == 's'
                || (iflags.prevmsg_window == 'c' && !doprev)) {
                /* msg_window:single, or msg_window:combination while it's
                   behaving like msg_window:single */
                if (!doprev)
                    (void) tty_doprev_message(); /* need two initially */
                (void) tty_doprev_message();
                ttyDisplay->inread = sav;
                doprev = TRUE;
                continue;
            } else {
                /* msg_window:full or reverse, or msg_window:combination while
                   it's behaving like msg_window:full */
                (void) tty_doprev_message();
                ttyDisplay->inread = sav;
                doprev = FALSE;
                tty_clear_nhwindow(WIN_MESSAGE);
                cw->maxcol = cw->maxrow;
                addtopl(query);
                addtopl(" ");
                *bufp = 0;
                addtopl(obufp);
            }
        } else if (doprev) {
            tty_clear_nhwindow(WIN_MESSAGE);
            cw->maxcol = cw->maxrow;
            doprev = FALSE;
            addtopl(query);
            addtopl(" ");
            *bufp = 0;
            addtopl(obufp);
        }
        if (c == erase_char || c == '\b') {
            if (bufp != obufp) {
                char *newp = (char *) utf8_prev_char_start(obufp, bufp);
#ifdef NEWAUTOCOMP
                int delcols = getlin_utf8_char_display_width(
                                  (const unsigned char *) newp);
                int tailcols;

#endif /* NEWAUTOCOMP */
                bufp = newp;
#ifndef NEWAUTOCOMP
                putsyms("\b \b"); /* putsym converts \b */
#else                             /* NEWAUTOCOMP */
                if (delcols < 1)
                    delcols = 1;
                tailcols = getlin_utf8_cells(bufp);
                getlin_put_backspaces(delcols);
                getlin_put_spaces(tailcols);
                getlin_put_backspaces(tailcols);
                *bufp = 0;
#endif                            /* NEWAUTOCOMP */
            } else
                tty_nhbell();
        } else if (c == '\n' || c == '\r') {
#ifndef NEWAUTOCOMP
            *bufp = 0;
#endif /* not NEWAUTOCOMP */
            break;
        } else if (c >= ' ' && c != '\177') {
            const char *inbytes = (const char *) 0;
            int inlen = 0;

            if (c < 0x80) {
                utf8buf[0] = (uint8) c;
                utf8buf[1] = '\0';
                inbytes = (const char *) utf8buf;
                inlen = 1;
            } else if (unicodeval_to_utf8str(c, utf8buf, sizeof utf8buf)) {
                inbytes = (const char *) utf8buf;
                inlen = (int) strlen(inbytes);
            }

            if (!inbytes
                || (bufp - obufp + inlen > BUFSZ - 1)
                || (bufp - obufp + inlen > COLNO)) {
                tty_nhbell();
                continue;
            }
#ifdef NEWAUTOCOMP
            char *i = eos(bufp);
            int oldtailcols = getlin_utf8_cells(bufp);

#endif /* NEWAUTOCOMP */
            memcpy((genericptr_t) bufp, (genericptr_t) inbytes,
                   (size_t) inlen);
            bufp += inlen;
            *bufp = 0;
            putsyms(inbytes);
            if (hook && (*hook)(obufp)) {
                putsyms(bufp);
#ifndef NEWAUTOCOMP
                bufp = eos(bufp);
#else  /* NEWAUTOCOMP */
                /* pointer and cursor left where they were */
                getlin_put_backspaces(getlin_utf8_cells(bufp));
            } else if (i > bufp) {
                /* erase rest of prior guess */
                getlin_put_spaces(oldtailcols);
                getlin_put_backspaces(oldtailcols);
#endif /* NEWAUTOCOMP */
            }
        } else if (c == kill_char || c == '\177') { /* Robert Viduya */
            /* this test last - @ might be the kill_char */
#ifndef NEWAUTOCOMP
            while (bufp != obufp) {
                bufp--;
                putsyms("\b \b");
            }
#else  /* NEWAUTOCOMP */
            int tailcols = getlin_utf8_cells(bufp);

            getlin_put_spaces(tailcols);
            getlin_put_backspaces(tailcols);
            while (bufp != obufp) {
                char *newp = (char *) utf8_prev_char_start(obufp, bufp);
                int delcols = getlin_utf8_char_display_width(
                                  (const unsigned char *) newp);

                if (delcols < 1)
                    delcols = 1;
                getlin_put_backspaces(delcols);
                getlin_put_spaces(delcols);
                getlin_put_backspaces(delcols);
                bufp = newp;
            }
            *bufp = 0;
#endif /* NEWAUTOCOMP */
        } else
            tty_nhbell();
    }
    ttyDisplay->toplin = TOPLINE_NON_EMPTY;
    ttyDisplay->inread--;
    clear_nhwindow(WIN_MESSAGE); /* clean up after ourselves */

    if (suppress_history) {
        /* prevent next message from pushing current query+answer into
           tty message history */
        *gt.toplines = '\0';
#ifdef DUMPLOG_CORE
    } else {
        /* needed because we've bypassed pline() */
        dumplogmsg(gt.toplines);
#endif
    }
}

void
xwaitforspace(const char *s) /* chars allowed besides return */
{
    int c, x = ttyDisplay ? (int) ttyDisplay->dismiss_more : '\n';

    morc = 0;
    while (
#ifdef HANGUPHANDLING
        !program_state.done_hup &&
#endif
        (c = tty_nhgetch()) != EOF) {
        if (c == '\n' || c == '\r')
            break;

        if (iflags.cbreak) {
            if (c == '\033') {
                if (ttyDisplay)
                    ttyDisplay->dismiss_more = 1;
                morc = '\033';
                break;
            }
            if ((s && strchr(s, c)) || c == x || (x == '\n' && c == '\r')) {
                morc = (char) c;
                break;
            }
            tty_nhbell();
        }
    }
}

/*
 * Implement extended command completion by using this hook into
 * tty_getlin.  Check the characters already typed, if they uniquely
 * identify an extended command, expand the string to the whole
 * command.
 *
 * Return TRUE if we've extended the string at base.  Otherwise return FALSE.
 * Assumptions:
 *
 *      + we don't change the characters that are already in base
 *      + base has enough room to hold our string
 */
static boolean
ext_cmd_getlin_hook(char *base)
{
    int *ecmatches;
    int nmatches = extcmds_match(base, ECM_NOFLAGS, &ecmatches);

    if (nmatches == 1) {
        struct ext_func_tab *ec = extcmds_getentry(ecmatches[0]);

        Strcpy(base, ec->ef_txt);
        return TRUE;
    }

    return FALSE; /* didn't match anything */
}

/*
 * Read in an extended command, doing command line completion.  We
 * stop when we have found enough characters to make a unique command.
 */
int
tty_get_ext_cmd(void)
{
    char buf[BUFSZ];
    int nmatches;
    int *ecmatches = 0;
    boolean (*no_hook)(char *base) = (boolean (*)(char *)) 0;
    char extcmd_char[2];

    if (iflags.extmenu)
        return extcmd_via_menu();

    suppress_history = TRUE;
    /* maybe a runtime option?
     * hooked_tty_getlin("#", buf,
     *                   (flags.cmd_comp && !gi.in_doagain)
     *                      ? ext_cmd_getlin_hook
     *                      : (getlin_hook_proc) 0);
     */
    extcmd_char[0] = extcmd_initiator(), extcmd_char[1] = '\0';
    buf[0] = '\0';
    hooked_tty_getlin(extcmd_char, buf,
                      !gi.in_doagain ? ext_cmd_getlin_hook : no_hook);
    (void) mungspaces(buf);

    nmatches = (buf[0] == '\0' || buf[0] == '\033') ? -1
              : extcmds_match(buf, ECM_IGNOREAC | ECM_EXACTMATCH, &ecmatches);
    if (nmatches != 1) {
        if (nmatches != -1)
            pline("%s%.60s: unknown extended command.",
                  visctrl(extcmd_char[0]), buf);
        return -1;
    }

    return ecmatches[0];
}

#endif /* TTY_GRAPHICS */

/*getline.c*/
