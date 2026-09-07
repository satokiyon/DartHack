/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-06. */
/* NetHackJP: recreate stale ICs when the owning widget's X window is
 * re-created.  positionpopup() unrealizes/re-realizes the getlin popup
 * on every dialog open, so Window IDs change; an IC bound to the old
 * window made fcitx5 disengage and swallowed every keystroke.  See
 * xim_create_ic() and DEVELOPMENT.md §4.12. */
/* NetHackJP: XIM (X Input Method) infrastructure for the X11 window port.
 *
 * This module provides a thin wrapper around XOpenIM / XCreateIC /
 * Xutf8LookupString so that the rest of the X11 port can talk to an
 * external input method server such as fcitx5 / ibus / IIIMF.
 *
 * Design choices (see XIM-IMPLEMENTATION-PLAN.md for the full plan):
 *   - Use XIMPreeditNothing | XIMStatusNothing so that preedit / status
 *     windows are delegated to the IM server (fcitx5).  We do NOT install
 *     any PreeditCallbacks or StatusCallbacks; doing so would require
 *     complex reentrancy handling between the Xt event loop and our
 *     pline / putsyms callbacks.
 *   - On XOpenIM failure (e.g. fcitx5 not running, XMODIFIERS unset), log
 *     a single warning and stay in fallback mode where every caller
 *     behaves as if no IC exists and falls back to XLookupString.
 *   - Per-widget IC caching: a small linear list maps Widget -> XIC so
 *     that we can reuse an IC across popup/destroy cycles.
 *
 * This file is gated entirely by the HAVE_XIM compile-time macro so that
 * the binary keeps building on platforms without XIM support.
 */

#ifdef HAVE_XIM

/* X11 headers must come BEFORE winX.h because winX.h uses Widget,
 * Dimension, Pixel, Boolean, XEvent, String, XtAppContext, etc.  We
 * mirror the include order used by winX.c itself (intrinsic.h first,
 * then stringdefs.h, then xlib.h for XIM / XIC types). */
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/Xlib.h> /* XIM, XIC, XEvent, KeySym, Status, etc. */

/* X11_BUILD must be defined before including hack.h so that GCC 12+'s
 * attribute-nonstring warning is suppressed for the IM-related
 * variadic-format calls we make.  See tradstdc.h for the exact check. */
#define X11_BUILD
#include "hack.h"
#undef X11_BUILD

#include "winX.h"

#include <locale.h>
#include <stdlib.h>
#include <string.h>

/* ---- module state ----------------------------------------------------- */

/* The single global input method handle.  We open at most one IM per
 * process; per-window ICs are created on demand via xim_create_ic().
 * Held as a (Display *)-compatible opaque handle. */
static XIM xim_im_obj = (XIM) NULL;

/* True iff xim_init() succeeded.  Callers can use xim_is_active() as a
 * fast guard before any XIM work.  When FALSE, every XIC handle returned
 * by xim_create_ic() is NULL and lookups fall back to XLookupString. */
static boolean xim_active_flag = FALSE;

/* NetHackJP: the IC that currently holds XIM focus (see the focus
 * tracking section below).  Declared here so xim_create_ic() can clear
 * it when it destroys a stale IC whose widget's X window was
 * re-created. */
static XIC xim_current_focused_ic = (XIC) 0;

/* ---- per-widget IC cache --------------------------------------------- */

/* We keep a small fixed-size table of (Widget, XIC) pairs so that
 * repeated xim_create_ic() calls for the same Widget return the same IC.
 * A Widget is reused for the lifetime of the X11 application, so this
 * list never shrinks; entries are appended once and freed in
 * xim_cleanup().
 *
 * NetHackJP: each entry also records the X Window the IC was created
 * for.  positionpopup() calls XtUnrealizeWidget/XtRealizeWidget on
 * every dialog open, which hands the widget brand-new Window IDs; an
 * IC bound to the old window keeps XNClientWindow/XNFocusWindow
 * pointing at a dead window, so the IM server disengages and
 * Xutf8LookupString() stops returning anything.  xim_create_ic()
 * compares the recorded window against the widget's current window and
 * destroys + recreates the IC when they differ. */
typedef struct xim_ic_entry {
    Widget w;
    XIC ic;
    Window win;
} xim_ic_entry;

#define XIM_IC_CACHE_MAX 64
static xim_ic_entry xim_ic_cache[XIM_IC_CACHE_MAX];
static int xim_ic_cache_count = 0;

static int
xim_ic_cache_find(Widget w)
{
    int i;

    for (i = 0; i < xim_ic_cache_count; ++i) {
        if (xim_ic_cache[i].w == w)
            return i;
    }
    return -1;
}

static void
xim_ic_cache_store(Widget w, XIC ic, Window win)
{
    if (xim_ic_cache_count >= XIM_IC_CACHE_MAX) {
        /* Should not happen in practice; if it does, drop the new IC
         * to avoid unbounded growth. */
        if (ic != (XIC) 0)
            XDestroyIC(ic);
        return;
    }
    xim_ic_cache[xim_ic_cache_count].w = w;
    xim_ic_cache[xim_ic_cache_count].ic = ic;
    xim_ic_cache[xim_ic_cache_count].win = win;
    ++xim_ic_cache_count;
}

/* ---- public API ------------------------------------------------------- */

/*
 * Returns 1 if xim_init() successfully opened an input method,
 * 0 otherwise.  Cheap predicate safe to call on every key event.
 */
int
xim_is_active(void)
{
    return xim_active_flag ? 1 : 0;
}

/*
 * Initialize the XIM subsystem.  Called once from X11_init_nhwindows()
 * after XtSetLanguageProc() so that the LC_CTYPE locale is already set
 * up; we still call XSetLocaleModifiers("") ourselves to honour the
 * user's XMODIFIERS environment variable.
 *
 * On failure (no IM server running, XMODIFIERS unset, no locale support)
 * we leave xim_active_flag = FALSE and let callers fall back to
 * XLookupString.
 */
void
xim_init(void *dpy_arg)
{
    Display *dpy = (Display *) dpy_arg;
    char *mods;
    char *locale;

    /* NetHackJP: Phase 7 - honour the OPTIONS=use_xim runtime toggle.
     * When iflags.wc_use_xim == 0 the user has explicitly disabled XIM
     * via .nethackrc; we skip XOpenIM entirely and rely on plain
     * XLookupString input.  Other platforms leave wc_use_xim at 0
     * (default) but call into this routine only on X11 builds, so the
     * flag is read unconditionally here. */
    if (iflags.wc_use_xim == 0) {
        X11_raw_print("XIM: disabled by OPTIONS=use_xim:off");
        xim_active_flag = FALSE;
        return;
    }

    if (dpy == (Display *) 0) {
        X11_raw_print("XIM: cannot initialize (Display is NULL)");
        xim_active_flag = FALSE;
        return;
    }

    /* Make sure the C library locale is set; XOpenIM inspects this. */
    locale = setlocale(LC_ALL, "");
    if (locale == (char *) 0 || !strcmp(locale, "C") || !strcmp(locale, "POSIX")) {
        /* "C"/"POSIX" locales cannot drive XIM.  Try a UTF-8 fallback. */
        if (setlocale(LC_ALL, "C.UTF-8") != (char *) 0) {
            locale = setlocale(LC_ALL, (const char *) 0);
        }
    }
    (void) locale; /* silence unused-but-set-variable */

    /* XSetLocaleModifiers("") triggers XMODIFIERS lookup.  We do not
     * bail out on NULL: that just means no modifier is registered,
     * which is a normal case (no IM configured). */
    mods = XSetLocaleModifiers("");
    if (mods == (char *) 0) {
        X11_raw_print("XIM: no input method registered (XMODIFIERS unset or @im=none)");
        xim_active_flag = FALSE;
        return;
    }

    xim_im_obj = XOpenIM(dpy, NULL, NULL, NULL);
    if (xim_im_obj == (XIM) 0) {
        /* fcitx5 not running, or IM server refused connection.  This is
         * not fatal: the X11 port keeps working in ASCII-only mode.
         * Emit diagnostics so the user can tell *why* the IM is
         * unreachable: locale, XMODIFIERS, and whether fcitx5 is in the
         * process table. */
        char lbuf[64];
        const char *curloc = setlocale(LC_ALL, (const char *) 0);

        if (curloc == (const char *) 0)
            curloc = "(null)";
        Snprintf(lbuf, sizeof lbuf,
                 "XIM: XOpenIM failed; locale=%s XMODIFIERS=%s",
                 curloc, mods ? mods : "(null)");
        X11_raw_print(lbuf);
        X11_raw_print("XIM:   -> falling back to XLookupString (ASCII only)");
        X11_raw_print("XIM:   -> check 'pgrep -a fcitx5' and 'fcitx5-diagnose'");
        xim_active_flag = FALSE;
        return;
    }

    xim_active_flag = TRUE;
    X11_raw_print("XIM: connected to input method (XPreeditNothing / XStatusNothing)");
    (void) mods;
}

/*
 * Tear down the XIM subsystem.  Called from X11_exit_nhwindows().
 * Destroys every cached IC before closing the IM.
 */
void
xim_cleanup(void)
{
    int i;

    for (i = 0; i < xim_ic_cache_count; ++i) {
        if (xim_ic_cache[i].ic != (XIC) 0)
            XDestroyIC(xim_ic_cache[i].ic);
        xim_ic_cache[i].w = (Widget) 0;
        xim_ic_cache[i].ic = (XIC) 0;
        xim_ic_cache[i].win = None;
    }
    xim_ic_cache_count = 0;

    if (xim_im_obj != (XIM) 0) {
        XCloseIM(xim_im_obj);
        xim_im_obj = (XIM) 0;
    }
    xim_active_flag = FALSE;
}

/*
 * Return an XIC for the given widget, creating one if needed.
 * Returns NULL when XIM is not active or the widget has no window yet.
 *
 * The IC style is XIMPreeditNothing | XIMStatusNothing: we delegate the
 * preedit / status windows to the IM server (fcitx5) and never install
 * XIM callbacks.  This keeps the Xt event loop reentrancy story simple.
 *
 * NetHackJP: if the widget's X window changed since the cached IC was
 * created (positionpopup() unrealizes and re-realizes the popup on
 * every dialog open, which reassigns Window IDs), the stale IC is
 * destroyed and a fresh one is created for the new window.  Without
 * this, the IM server keeps an IC whose focus window no longer exists
 * and silently stops delivering preedit/commit for it.
 */
void *
xim_create_ic(void *w_arg)
{
    Widget w = (Widget) w_arg;
    XIC ic;
    Window xwin;
    int idx;

    if (!xim_active_flag || w == (Widget) 0)
        return (void *) 0;

    /* XCreateIC needs a Window that already exists.  If the widget is
     * not yet realized, we cannot create an IC; the caller should retry
     * later. */
    if (!XtIsRealized(w))
        return (void *) 0;

    xwin = XtWindow(w);
    if (xwin == None)
        return (void *) 0;

    idx = xim_ic_cache_find(w);
    if (idx >= 0 && xim_ic_cache[idx].win == xwin)
        return (void *) xim_ic_cache[idx].ic;

    if (idx >= 0 && xim_ic_cache[idx].ic != (XIC) 0) {
        /* Drop the stale IC.  Clear the focus tracker first so we
         * never call XUnsetICFocus on a destroyed handle. */
        if (xim_current_focused_ic == xim_ic_cache[idx].ic)
            xim_current_focused_ic = (XIC) 0;
        XDestroyIC(xim_ic_cache[idx].ic);
        xim_ic_cache[idx].ic = (XIC) 0;
    }

    ic = XCreateIC(xim_im_obj,
                   XNInputStyle,
                       XIMPreeditNothing | XIMStatusNothing,
                   XNClientWindow, xwin,
                   XNFocusWindow, xwin,
                   NULL);
    if (ic == (XIC) 0) {
        /* Remember the window even on failure so the next call retries
         * with a fresh XCreateIC instead of returning a stale IC. */
        if (idx < 0)
            xim_ic_cache_store(w, (XIC) 0, xwin);
        else
            xim_ic_cache[idx].win = xwin;
        return (void *) 0;
    }

    if (idx < 0)
        xim_ic_cache_store(w, ic, xwin);
    else {
        xim_ic_cache[idx].ic = ic;
        xim_ic_cache[idx].win = xwin;
    }
    return (void *) ic;
}

/*
 * Destroy a previously-created IC.  Currently a no-op because we keep
 * ICs alive for the lifetime of their widget (and ultimately the
 * lifetime of the X11 application, since widgets are not destroyed
 * until X11_exit_nhwindows).  Provided for API completeness and to
 * make future refactoring (per-popup IC scoping) easier.
 */
void
xim_destroy_ic(void *ic_arg)
{
    /* ICs are managed by the cache; xim_cleanup() destroys them all. */
    nhUse(ic_arg);
}

/* ---- focus tracking (Phase 5) ----------------------------------------- */

/* NetHackJP: track which IC currently has XIM focus so we can
 * automatically unfocus the previous one when a different widget
 * gains focus.  Without this, fcitx5 may keep delivering keystrokes
 * to an IC whose window is no longer mapped (e.g. after a popup is
 * dismissed) until the user clicks somewhere to reset focus.
 * The xim_current_focused_ic variable itself is declared in the
 * module state section at the top of this file because
 * xim_create_ic() also clears it when destroying a stale IC. */

/*
 * Set XIM focus to `ic`.  If a different IC previously had focus,
 * it is automatically unfocused.  Passing NULL is a no-op (the
 * previous IC, if any, is left alone).  Safe to call multiple
 * times with the same IC.
 */
void
xim_focus_in(void *ic_arg)
{
    XIC ic = (XIC) ic_arg;

    if (ic == (XIC) 0)
        return;
    if (xim_current_focused_ic == ic) {
        /* Already focused: re-assert to cover the case where the
         * window was unmapped and remapped. */
        XSetICFocus(ic);
        return;
    }
    if (xim_current_focused_ic != (XIC) 0)
        XUnsetICFocus(xim_current_focused_ic);
    xim_current_focused_ic = ic;
    XSetICFocus(ic);
}

/*
 * Clear XIM focus from whatever IC currently has it.  Safe to call
 * even if no IC has focus.
 */
void
xim_focus_out(void *ic_arg)
{
    nhUse(ic_arg);
    if (xim_current_focused_ic != (XIC) 0) {
        XUnsetICFocus(xim_current_focused_ic);
        xim_current_focused_ic = (XIC) 0;
    }
}

/*
 * Reset focus tracking without calling XUnsetICFocus.  Used when an
 * IC is being destroyed (e.g. via xim_destroy_ic) so we don't call
 * XUnsetICFocus on a stale handle.
 */
void
xim_focus_clear(void)
{
    xim_current_focused_ic = (XIC) 0;
}

/*
 * Look up a key event as a UTF-8 string via the given IC.
 *
 *   ic_arg       - input context (may be NULL for fallback)
 *   ev           - the key event to translate
 *   buf          - output buffer for the resulting UTF-8 string
 *   bufsz        - size of buf in bytes
 *   keysym_ret   - output: keysym associated with the key
 *                  (caller passes a KeySym* cast to unsigned long*)
 *   status_ret   - output: XLookupChars / XLookupKeySym / XLookupBoth /
 *                  XLookupNone (mirrors Xutf8LookupString contract)
 *
 * Returns the number of bytes written to buf (>= 0), or -1 on error.
 * When ic_arg is NULL or XIM is not active, the function returns -1
 * and leaves buf / keysym_ret / status_ret untouched; callers must
 * fall back to XLookupString in that case.
 *
 * The output is always NUL-terminated when bufsz > 0.
 */
int
xim_lookup_utf8(void *ic_arg, XKeyEvent *ev,
                char *buf, int bufsz,
                unsigned long *keysym_ret, int *status_ret)
{
    XIC ic = (XIC) ic_arg;
    int nbytes;
    Status status;

    if (!xim_active_flag || ic == (XIC) 0 || ev == (XKeyEvent *) 0
        || buf == (char *) 0 || bufsz <= 0)
        return -1;

    /* Keep gcc -Wunused-result happy: we always read status below. */
    status = XLookupNone;
    nbytes = Xutf8LookupString(ic, ev, buf, bufsz - 1,
                               keysym_ret ? (KeySym *) keysym_ret : NULL,
                               &status);

    /* Defensive: ensure NUL-termination even if the IM returned a
     * partial sequence. */
    if (nbytes >= 0 && nbytes < bufsz)
        buf[nbytes] = '\0';
    else if (bufsz > 0)
        buf[bufsz - 1] = '\0';

    if (status_ret != (int *) 0)
        *status_ret = (int) status;

    /* XLookupNone means no useful data; signal failure to the caller
     * so it can fall back to XLookupString. */
    if (status == XLookupNone)
        return -1;

    return nbytes;
}

#endif /* HAVE_XIM */