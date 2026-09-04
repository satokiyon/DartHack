/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-04. */
/* NetHackJP: XIM commit capture, persistent IC/focus rebinding and
 * minimum input-field width.  (1) the key handler runs the XIM lookup
 * BEFORE the Return/Escape early-returns so committed text arriving on
 * Enter/Space is captured instead of lost; (2) the MapNotify focus
 * handler is persistent and re-binds the XIM IC to the popup's freshly
 * created windows on every opening; (3) the response field keeps a
 * minimum width of 10 half-width characters.  See DEVELOPMENT.md
 * §4.12. */
/* NetHackJP: chain hints on CreateXimDialog children to fix narrow form
 * collapse and invisible button borders.  See CreateXimDialog() and
 * DEVELOPMENT.md §4.12 for the rationale. */
/* NetHackJP: XIM-aware getlin / askname dialog.
 *
 * Phase 3+ of the XIM implementation plan: Xaw's AsciiText widget
 * with `XtNinternational=True` is unreliable on XIM clients (the
 * fcitx5 server does not engage on this widget in the WSL/XWayland
 * setup).  This file implements a small custom dialog that drives the
 * XIM protocol directly via the winxim.c API.
 *
 * The visual structure mirrors CreateDialog() in dialogs.c:
 *
 *     +---------------------------------+
 *     | <prompt>                        |
 *     | <response>                      |   <-- label, not editable
 *     |       [ OK ]   [ Cancel ]       |
 *     +---------------------------------+
 *
 * NetHackJP: every child carries XtNtop=XtChainTop, XtNbottom=XtChainTop,
 * XtNleft=XtChainLeft, XtNright=XtChainLeft and XtNresizable=True.
 * Without these constraints, an empty response label collapses to its
 * 10px preferred width and the form inherits a ~170px column (the
 * 1-character input strip visible in earlier builds).  See
 * DEVELOPMENT.md §4.12.
 *
 * Keys are routed to xim_getlin_key_handler() which appends UTF-8
 * bytes from XIM to an internal buffer and updates the <response>
 * label after every event.
 *
 * The public API matches dialogs.c's signature so X11_askname() and
 * X11_getlin() in winX.c can switch over with a single-line change
 * (CreateDialog -> CreateXimDialog, GetDialogResponse ->
 * XimDialogGetResponse).
 */

#ifndef SYSV
#define PRESERVE_NO_SYSV /* X11 include files may define SYSV */
#endif

/* X11 headers must come BEFORE winX.h because winX.h uses Widget,
 * Dimension, Pixel, Boolean, XEvent, String, XtAppContext, etc. */
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/keysym.h> /* XK_Return, XK_Escape, XK_BackSpace, ... */
#include <X11/Xaw/Cardinals.h> /* ZERO / ONE macros for Xt{Set,Get}Values */
#include <X11/Xaw/Form.h>
#include <X11/Xaw/Label.h>
#include <X11/Xaw/Command.h>
#include <X11/Xlib.h> /* XK_*, XK_Return, etc. */

/* X11_BUILD must be defined before including hack.h so that GCC 12+'s
 * attribute-nonstring warning is suppressed for the IM-related
 * variadic-format calls we make.  See tradstdc.h for the exact check. */
#define X11_BUILD
#include "hack.h"
#undef X11_BUILD

#include "winX.h"

#include <string.h>

#ifdef PRESERVE_NO_SYSV
#ifdef SYSV
#undef SYSV
#endif
#undef PRESERVE_NO_SYSV
#endif

/* Maximum UTF-8 input length.  We use BUFSZ-1 to match the rest of
 * NetHackJP's input buffer size assumptions in winX.c. */
#define XIM_GETLIN_MAX 1023

/* NetHackJP: visible geometry of the response (input) field.  The field
 * is always at least XIM_GETLIN_MIN_CHARS half-width characters wide so
 * that it reads as an input area even when empty (see
 * xim_getlin_refresh_label).  The padding values must match the
 * XtNinternalWidth / XtNborderWidth given to the response widget in
 * CreateXimDialog(). */
#define XIM_GETLIN_MIN_CHARS 10
#define XIM_RESPONSE_INTERNAL_WIDTH 4
#define XIM_RESPONSE_BORDER_WIDTH 1

/* ---- module state ---------------------------------------------------- */

/* Single global state since only one getlin dialog is active at a
 * time.  The form widget reference is needed so the OK / Cancel
 * callbacks can popdown the popup shell. */
typedef struct {
    char buf[XIM_GETLIN_MAX + 1];
    int len;
    Widget form;
    Widget prompt_label;
    Widget response_label;
    Widget ok_widget;        /* OK button, used by MapNotify focus handler */
    void *ic;                /* XIC for the form, created lazily */
    XtCallbackProc ok_cb;    /* user-provided OK callback (e.g. done_button) */
    XtCallbackProc cancel_cb; /* user-provided cancel callback (e.g. abort_button) */
    /* NetHackJP: the X input focus in effect before the dialog grabbed
     * it, restored by XimDialogReleaseInputFocus() when the dialog is
     * popped down (see xim_map_notify_focus_handler). */
    boolean focus_saved;
    Window saved_focus_win;
    int saved_focus_revert;
} XimGetlinState;

static XimGetlinState g_xim_getlin_state;

/* NetHackJP: forward declaration; the persistent MapNotify focus
 * handler is defined below the public API but installed from
 * CreateXimDialog() (which runs before the popup is realized). */
static void xim_map_notify_focus_handler(Widget, XtPointer, XEvent *,
                                         Boolean *);

/* ---- UTF-8 helpers --------------------------------------------------- */

/* Append up to n bytes from src to buf at *len, capped at max.
 * The cap is checked strictly so that *len + 1 <= max (the trailing
 * NUL is always present).  Bell on overflow. */
static void
utf8_append(char *buf, int *len, int max, const char *src, int n)
{
    int available = max - *len;

    if (n > available) {
        n = available;
        X11_nhbell();
    }
    if (n <= 0) {
        X11_nhbell();
        return;
    }
    (void) memcpy(buf + *len, src, (size_t) n);
    *len += n;
    buf[*len] = '\0';
}

/* Delete the last UTF-8 character from buf and update *len.  Walks
 * back past any UTF-8 continuation bytes (10xxxxxx). */
static void
utf8_backspace(char *buf, int *len)
{
    int i;

    if (*len <= 0)
        return;
    i = *len - 1;
    while (i > 0 && ((unsigned char) buf[i] & 0xC0U) == 0x80U)
        i--;
    *len = i;
    buf[i] = '\0';
}

/* ---- label update ---------------------------------------------------- */

/* Push the current buffer back into the response label so the user
 * sees what they have typed.  Because the label was wrapped with
 * X11_wrap_widget_if_Xft(), it does NOT respond to ordinary
 * XtSetValues on XtNlabel alone; we have to:
 *   1. Set XtNlabel via XtSetValues.
 *   2. Call X11_update_label_if_Xft() which reads the new XtNlabel,
 *      renders the Xft Pixmap and assigns XtNbitmap.
 *   3. Force an X exposure on the widget's window with XClearArea
 *      so the X server actually repaints the new bitmap.
 *
 * NetHackJP: enforce a minimum visible width of XIM_GETLIN_MIN_CHARS
 * half-width characters, growing with the text and shrinking back to
 * that minimum when the text is deleted.
 *
 * ORDERING MATTERS here.  The Xaw Label widget auto-resizes itself
 * whenever XtNlabel changes (to the new label's preferred width, 10px
 * when empty), and X11_update_label_if_Xft() then resizes it again to
 * the rendered bitmap's dimensions (winlabel.c assigns XtNbitmap).  An
 * XtNwidth passed in the SAME XtSetValues call as the label is silently
 * overridden by both of those internal resize requests - which is why
 * the earlier single-call attempt still collapsed the field to one
 * character.  The explicit width is therefore applied LAST, in its own
 * XtSetValues, after the label and bitmap updates: a child width
 * request granted by the Form (XtNresizable=True) wins because no
 * further auto-resize occurs until the next label change. */
static void
xim_getlin_refresh_label(XimGetlinState *state)
{
    Arg args[1];
    Widget w = state->response_label;
    int pad;
    Dimension min_width, text_width, new_width;

    if (w == (Widget) 0)
        return;

    pad = 2 * XIM_RESPONSE_INTERNAL_WIDTH + 2 * XIM_RESPONSE_BORDER_WIDTH;
    min_width = (Dimension) (X11_label_string_width(w, "0123456789")
                             + pad);
    if (min_width < (Dimension) (XIM_GETLIN_MIN_CHARS * 8 + pad)) {
        /* Fallback for a font the helper could not measure: assume a
         * conservative 8px per half-width character. */
        min_width = (Dimension) (XIM_GETLIN_MIN_CHARS * 8 + pad);
    }
    text_width = (Dimension) (X11_label_string_width(w, state->buf) + pad);
    new_width = (min_width > text_width) ? min_width : text_width;

    XtSetArg(args[0], XtNlabel, state->buf);
    XtSetValues(w, args, ONE);
    X11_update_label_if_Xft(w);

    /* NetHackJP: applied last so it cannot be overridden by the
     * Label's own resize-on-label/bitmap-change (see the comment
     * above). */
    XtSetArg(args[0], XtNwidth, new_width);
    XtSetValues(w, args, ONE);

    if (XtIsRealized(w) && XtWindow(w) != None) {
        XClearArea(XtDisplay(w), XtWindow(w), 0, 0, 0, 0, True);
    }
}

/* ---- button callbacks ------------------------------------------------ */

/* Forward to the user-supplied OK callback (e.g. done_button or
 * askname_done) which is responsible for copying the final text into
 * the caller's buffer, popping the dialog down, and setting
 * exit_x_event.  We only need to forward the call. */
static void
xim_getlin_ok_button(Widget w, XtPointer client_data, XtPointer call_data)
{
    XimGetlinState *state = &g_xim_getlin_state;
    Widget form = (Widget) client_data;

    nhUse(form);
    nhUse(call_data);

    if (state->ok_cb != (XtCallbackProc) 0)
        (*state->ok_cb)(w, client_data, call_data);
}

/* Forward to the user-supplied cancel callback (abort_button).  We
 * also pre-populate the buffer with a single ESC so callers that read
 * the buffer directly (instead of trusting the cancel callback) see
 * the standard cancellation signal. */
static void
xim_getlin_cancel_button(Widget w, XtPointer client_data, XtPointer call_data)
{
    XimGetlinState *state = &g_xim_getlin_state;
    Widget form = (Widget) client_data;

    nhUse(form);
    nhUse(call_data);

    state->buf[0] = '\033';
    state->buf[1] = '\0';
    state->len = 1;
    xim_getlin_refresh_label(state);

    if (state->cancel_cb != (XtCallbackProc) 0)
        (*state->cancel_cb)(w, client_data, call_data);
}

/* ---- key event handler ---------------------------------------------- */

/*ARGSUSED*/
static void
xim_getlin_key_handler(Widget w, XtPointer client_data, XEvent *event,
                       Boolean *continue_to_dispatch)
{
    XimGetlinState *state = (XimGetlinState *) client_data;
    XKeyEvent *key = (XKeyEvent *) event;
    char buf[MAX_KEY_STRING];
    char utf8buf[MAX_KEY_STRING];
    KeySym keysym = NoSymbol;
    boolean xim_engaged = FALSE;
    int n, xim_n;

    nhUse(w);
    nhUse(continue_to_dispatch);

    /* XLookupString runs first because we need the raw keysym to
     * detect non-printable keys (Return, Escape, BackSpace).  Note it
     * does NOT consult the input method; that is what the XIM lookup
     * below is for. */
    n = XLookupString(key, buf, (int) sizeof buf - 1, &keysym,
                      (XComposeStatus *) 0);
    if (n >= 0 && n < (int) sizeof buf)
        buf[n] = '\0';

    /* Try XIM (fcitx5 / ibus).  We attach the IC to the OK button (the
     * focused widget) rather than the form, so fcitx5's XSelectInput
     * registration on the IC's XNFocusWindow actually receives the
     * keyboard events that the X server delivers to OK.  Attaching to
     * the form ancestor does NOT work because the X server routes
     * events to the focused widget, not its parent. */
    if (state->ic == (void *) 0 && xim_is_active()) {
        state->ic = xim_create_ic((void *) state->ok_widget);
        if (state->ic != (void *) 0)
            xim_focus_in(state->ic);
    }

    /*
     * NetHackJP: run the XIM lookup BEFORE the keysym checks below.
     * A committed string can be delivered as the return value of
     * Xutf8LookupString() on the very key event that triggered the
     * commit (typically Enter or Space).  The previous order returned
     * early on XK_Return / XK_KP_Enter, which (a) discarded the commit
     * text and (b) let the OK button's <Key>Return translation close
     * the dialog - the user saw "typed Japanese vanished and the
     * dialog closed".
     *
     * The XIM lookup result is CLASSIFIED by the Status output, because
     * Xutf8LookupString() returns ordinary key translations as well as
     * IM commits.  A blind "append whenever bytes come back" inserted
     * those plain translations as text: with fcitx5 passing keys
     * through, Enter delivers "\r", BackSpace "\b" and Delete 0x7F,
     * which all ended up as characters in the field.
     *
     *   XLookupChars  - string with NO keysym: this is genuine IM
     *                   commit text (or a locale compose result) ->
     *                   append.
     *   XLookupBoth   - string AND keysym: an ordinary key translation;
     *                   if the keysym is one of the editing keys
     *                   (Return / KP_Enter / Escape / BackSpace /
     *                   Delete) it must be handled as that key, not
     *                   appended; otherwise append the (printable)
     *                   translation.
     *   XLookupKeySym - keysym with no text: fall through to the keysym
     *                   handling (e.g. Delete on most layouts).
     *   XLookupNone   - the IM consumed the key (mode toggle, ...) ->
     *                   swallow it.
     */
    if (state->ic != (void *) 0 && xim_is_active()) {
        unsigned long im_keysym = NoSymbol;
        int status = 0;
        boolean special_key;

        xim_engaged = TRUE;
        xim_n = xim_lookup_utf8(state->ic, key, utf8buf,
                                (int) sizeof utf8buf - 1,
                                &im_keysym, &status);
        if (status == XLookupNone)
            return; /* IM consumed the key; nothing to add */

        special_key = (im_keysym == XK_Return || im_keysym == XK_KP_Enter
                       || im_keysym == XK_Escape
                       || im_keysym == XK_BackSpace
                       || im_keysym == XK_Delete);

        if (xim_n > 0 && !special_key
            && (status == XLookupChars
                || (status == XLookupBoth
                    && utf8buf[0] >= ' '
                    && (unsigned char) utf8buf[0] < 0x7fU))) {
            utf8_append(state->buf, &state->len, XIM_GETLIN_MAX,
                        utf8buf, xim_n);
            xim_getlin_refresh_label(state);
            return;
        }
        /* Special key (Return/Escape/BackSpace/Delete), a keysym with
         * no text, or a non-printable translation: fall through to the
         * keysym handling below, using the keysym reported by the IM
         * lookup when it has one.  Key events consumed by the IM
         * (preedit romaji, the Ctrl+Space mode toggle, ...) are
         * filtered by XFilterEvent() inside Xt's event loop and never
         * reach this handler at all. */
        if (im_keysym != NoSymbol)
            keysym = (KeySym) im_keysym;
    }

    /* Return / KP_Enter: handled by the OK button's own translation
     * (<Key>Return: set() notify() unset()).  We must NOT call
     * xim_getlin_ok_button() here, otherwise the user's OK callback
     * fires twice.  Just let Xt's translation dispatch take over. */
    if (keysym == XK_Return || keysym == XK_KP_Enter) {
        return;
    }
    /* Escape: cancel via our own handler.  The Cancel button's own
     * translation has been stripped so Escape does not activate it.
     *
     * NetHackJP: pass state->form (not client_data) as the second
     * argument.  xim_getlin_cancel_button() forwards its second
     * argument straight through to state->cancel_cb (abort_button /
     * askname_done), which casts it to Widget dialog and calls
     * XtParent(dialog) to reach the popup shell for nh_XtPopdown.
     *
     * The Xt callback chain (Cancel-button click) is registered with
     * form as client_data, so the cancel path there is correct.
     * But here the key event handler is installed on the OK button
     * with client_data = state; the second argument of this handler
     * is therefore &g_xim_getlin_state, NOT a Widget.  Passing it
     * straight through would make abort_button do XtParent(state)
     * -> XtPopdown(garbage) -> SIGABRT. */
    if (keysym == XK_Escape) {
        xim_getlin_cancel_button(w, (XtPointer) state->form,
                                 (XtPointer) 0);
        return;
    }
    if (keysym == XK_BackSpace || keysym == XK_Delete) {
        utf8_backspace(state->buf, &state->len);
        xim_getlin_refresh_label(state);
        return;
    }

    /* ASCII fallback for when XIM is not active at all.  This keeps the
     * dialog usable when fcitx5 / ibus is not running. */
    if (!xim_engaged
        && n >= 1 && buf[0] >= ' ' && (unsigned char) buf[0] < 0x7fU) {
        utf8_append(state->buf, &state->len, XIM_GETLIN_MAX, buf, 1);
        xim_getlin_refresh_label(state);
    }
}

/* ---- public API ------------------------------------------------------ */

/*
 * Create an XIM-aware dialog widget and return the form widget handle
 * (matching the convention of CreateDialog() in dialogs.c).
 *
 * The OK and Cancel buttons are managed by this module.  When the user
 * clicks them, the corresponding user-supplied callback is invoked
 * with the form widget as client_data; that callback is expected to
 * copy the current text (via XimDialogGetResponse()) into the
 * caller's buffer and set exit_x_event = TRUE.
 */
Widget
CreateXimDialog(Widget parent, String name,
                XtCallbackProc okay_callback,
                XtCallbackProc cancel_callback)
{
    Widget form, prompt, response, ok, cancel;
    Arg args[20];
    Cardinal num_args;

    /* Reset state */
    (void) memset(&g_xim_getlin_state, 0, sizeof g_xim_getlin_state);
    g_xim_getlin_state.ok_cb = okay_callback;
    g_xim_getlin_state.cancel_cb = cancel_callback;

    num_args = 0;
    XtSetArg(args[num_args], nhStr(XtNborderWidth), 0); num_args++;
    /* XtNdefaultDistance adds vertical/horizontal spacing between
     * children, so the prompt/response/OK buttons don't overlap.
     * 8 pixels gives a comfortable, readable spacing. */
    XtSetArg(args[num_args], nhStr(XtNdefaultDistance), 8); num_args++;
    /* NetHackJP: also set the form's preferred width so it does not
     * collapse to a narrow column when every child is chain-pinned
     * to XtChainLeft.  Without this, Xaw's Form widget sometimes
     * squeezes the response to a 1-character-wide vertical strip. */
    XtSetArg(args[num_args], nhStr(XtNwidth), 380); num_args++;
    form = XtCreateManagedWidget(name, formWidgetClass, parent,
                                 args, num_args);
    g_xim_getlin_state.form = form;

    /* NetHackJP: chain hints and XtNresizable=True are required so that
     * Xaw's Form widget uses the child's XtWidth (360) instead of the
     * child's preferred width when computing the form's preferred_width.
     * Without these constraints, an empty label/button collapses the
     * form to ~170 pixels and the response field appears as a 1-character
     * vertical strip.  Both top/bottom pinned to top (and left/right to
     * left) preserve the explicit XtNwidth as the child's fixed size. */
    /* prompt: top of the form. */
    num_args = 0;
    XtSetArg(args[num_args], nhStr(XtNtop), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNbottom), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNleft), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNright), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNresizable), True); num_args++;
    XtSetArg(args[num_args], nhStr(XtNborderWidth), 0); num_args++;
    XtSetArg(args[num_args], nhStr(XtNinternalWidth), 4); num_args++;
    XtSetArg(args[num_args], nhStr(XtNinternalHeight), 4); num_args++;
    XtSetArg(args[num_args], nhStr(XtNwidth), 360); num_args++;
    XtSetArg(args[num_args], nhStr(XtNheight), 28); num_args++;
    prompt = XtCreateManagedWidget("prompt", labelWidgetClass, form,
                                   args, num_args);
    g_xim_getlin_state.prompt_label = prompt;
    X11_wrap_widget_if_Xft(prompt, NHW_MENU);

    /* response: directly below the prompt.  We force an explicit
     * width AND height so the form does NOT allocate a 0-height
     * widget for the empty input.  XtNborderWidth is set to 1 so the
     * response area looks like an input field with a visible frame.
     *
     * NetHackJP: chain hints and XtNresizable=True are REQUIRED here.
     * The response label has XtNlabel="" which makes its preferred
     * width = 2*internalWidth + 2*borderWidth = 10px.  Without chain
     * hints, Xaw's Form layout uses this preferred width and the
     * form collapses to a narrow column (~170px), making the field
     * show only a 1-character-wide vertical strip. */
    num_args = 0;
    XtSetArg(args[num_args], nhStr(XtNfromVert), prompt); num_args++;
    XtSetArg(args[num_args], nhStr(XtNtop), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNbottom), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNleft), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNright), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNresizable), True); num_args++;
    XtSetArg(args[num_args], nhStr(XtNborderWidth),
             XIM_RESPONSE_BORDER_WIDTH); num_args++;
    XtSetArg(args[num_args], nhStr(XtNinternalWidth),
             XIM_RESPONSE_INTERNAL_WIDTH); num_args++;
    XtSetArg(args[num_args], nhStr(XtNinternalHeight), 4); num_args++;
    XtSetArg(args[num_args], nhStr(XtNwidth), 360); num_args++;
    XtSetArg(args[num_args], nhStr(XtNheight), 36); num_args++;
    XtSetArg(args[num_args], nhStr(XtNlabel), ""); num_args++;
    response = XtCreateManagedWidget("response", labelWidgetClass, form,
                                     args, num_args);
    g_xim_getlin_state.response_label = response;
    X11_wrap_widget_if_Xft(response, NHW_MENU);

    /* OK: below the response, on the left.  Chain hints are added so
     * the form respects the explicit XtNwidth (and the OK button does
     * NOT collapse to its narrow preferred size).  The widget name
     * "OK" (capitalized) matches NetHack.ad resource patterns
     * (NetHack*OK.foreground: green, NetHack*OK.shapeStyle:
     * roundedRectangle).
     *
     * NetHackJP: XtNborderWidth is left at the Xaw default (1) so the
     * rounded rectangle shapeStyle from NetHack.ad is actually visible
     * as a button frame.  Setting it to 0 made the button appear as
     * plain "OK" text with no visible boundary. */
    num_args = 0;
    XtSetArg(args[num_args], nhStr(XtNfromVert), response); num_args++;
    XtSetArg(args[num_args], nhStr(XtNtop), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNbottom), XtChainTop); num_args++;
    XtSetArg(args[num_args], nhStr(XtNleft), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNright), XtChainLeft); num_args++;
    XtSetArg(args[num_args], nhStr(XtNresizable), True); num_args++;
    /* Force a usable button size so the shapeStyle resource is visible.
     * The NetHack.ad shapeStyle resources render a rounded rectangle
     * border; without these dimensions the button is just text-sized. */
    XtSetArg(args[num_args], nhStr(XtNwidth), 100); num_args++;
    XtSetArg(args[num_args], nhStr(XtNheight), 32); num_args++;
    ok = XtCreateManagedWidget("OK", commandWidgetClass, form,
                               args, num_args);
    XtAddCallback(ok, XtNcallback, xim_getlin_ok_button,
                  (XtPointer) form);
    /* NetHackJP: record the OK widget right away so the persistent
     * MapNotify focus handler below can bind the XIM IC and move the
     * X input focus even on the very first dialog opening, where the
     * MapNotify fires before XimDialogFocusInput() is ever called. */
    g_xim_getlin_state.ok_widget = ok;

    /*
     * Override the OK button's default translations so that the
     * Command widget does NOT activate itself on <Key>space.  Space
     * is reserved for fcitx5's commit, and we route it through our
     * XIM-aware key handler instead.  <Key>Return stays bound so
     * pressing Enter commits via the existing ok callback.
     *
     * #override replaces the widget's translations completely.
     * The <Btn1Down>...<Btn1Up> sequence is preserved so that mouse
     * clicks still activate the button.
     */
    XtOverrideTranslations(ok, XtParseTranslationTable(
        "#override\n\
         <Key>Return: set() notify() unset()\n\
         <Btn1Down>,<Btn1Up>: set() notify() unset()"));

    if (cancel_callback != (XtCallbackProc) 0) {
        /* NetHackJP: chain hints added and XtNborderWidth left at the
         * Xaw default (1) so the rounded rectangle shapeStyle from
         * NetHack.ad is visible as a button frame.  See the OK
         * comment above for rationale. */
        num_args = 0;
        XtSetArg(args[num_args], nhStr(XtNfromVert), response); num_args++;
        XtSetArg(args[num_args], nhStr(XtNfromHoriz), ok); num_args++;
        XtSetArg(args[num_args], nhStr(XtNtop), XtChainTop); num_args++;
        XtSetArg(args[num_args], nhStr(XtNbottom), XtChainTop); num_args++;
        XtSetArg(args[num_args], nhStr(XtNleft), XtChainLeft); num_args++;
        XtSetArg(args[num_args], nhStr(XtNright), XtChainLeft); num_args++;
        XtSetArg(args[num_args], nhStr(XtNresizable), True); num_args++;
        XtSetArg(args[num_args], nhStr(XtNwidth), 100); num_args++;
        XtSetArg(args[num_args], nhStr(XtNheight), 32); num_args++;
        cancel = XtCreateManagedWidget("cancel", commandWidgetClass, form,
                                       args, num_args);
        XtAddCallback(cancel, XtNcallback, xim_getlin_cancel_button,
                      (XtPointer) form);

        /* Cancel: remove all key bindings so Enter and Space do
         * not activate Cancel accidentally.  Only mouse clicks and
         * explicit focus traversal reach it. */
        XtOverrideTranslations(cancel, XtParseTranslationTable(
            "#override\n\
             <Btn1Down>,<Btn1Up>: set() notify() unset()"));
    }

    /*
     * Install the key event handler on the OK button.  The OK button
     * is focusable and will be the keyboard focus target below, so
     * it reliably receives KeyPress events.  Installing on the form
     * itself would not work because Xt dispatches key events to the
     * focused widget, not to its parent.
     *
     * nonmaskable = True forces the handler to be invoked for
     * KeyPress events even if the OK button's X event mask does not
     * include KeyPressMask (Command widgets select KeyPressMask by
     * default because of their default translations, but we have
     * overridden those and want to be sure the handler still fires).
     */
    XtAddEventHandler(ok, KeyPressMask, True,
                      (XtEventHandler) xim_getlin_key_handler,
                      (XtPointer) &g_xim_getlin_state);

    /*
     * Make the OK button the keyboard focus.  XtSetKeyboardFocus
     * takes a shell widget (or composite) as the first argument; the
     * popup shell we were passed qualifies.  We do this explicitly
     * (rather than relying on appResources.autofocus) because the
     * dialog is unusable without keyboard focus on a focusable child.
     */
    XtSetKeyboardFocus(parent, ok);

    /*
     * NetHackJP: install the persistent MapNotify focus handler on the
     * popup shell BEFORE it is ever realized.  positionpopup()
     * unrealizes and re-realizes the popup on every dialog open, so
     * each opening delivers exactly one MapNotify here - the moment
     * the new windows exist and are viewable.  The handler moves the
     * X server input focus to the OK button and (re)binds the XIM IC
     * to the freshly created window; see xim_map_notify_focus_handler()
     * and winxim.c's window-aware IC cache for why the re-bind is
     * required on every opening.
     *
     * The old one-shot variant was installed from XimDialogFocusInput()
     * AFTER positionpopup()/nh_XtPopup() had already mapped the shell,
     * so it never fired on the first opening and fired one opening
     * late afterwards (accumulating one stale handler per opening).
     */
    XtAddEventHandler(parent, StructureNotifyMask, False,
                      (XtEventHandler) xim_map_notify_focus_handler,
                      (XtPointer) NULL);

    return form;
}

/*
 * NetHackJP: persistent StructureNotify handler on the popup shell.
 * It is installed once by CreateXimDialog() (before realization) and
 * stays for the popup's lifetime.  Every dialog opening runs through
 * positionpopup(), which unrealizes and re-realizes the shell, so each
 * opening produces exactly one MapNotify here - the right moment to:
 *
 *   1. Move the X server input focus to the OK button.  Calling
 *      XSetInputFocus() earlier (right after XtPopup()) is unsafe
 *      because the shell's children may not be viewable yet and X
 *      rejects focus on unviewable windows with BadMatch.  Waiting for
 *      the MapNotify event guarantees the OK window is viewable.
 *   2. Bind the XIM IC to the OK button's CURRENT window.  Because the
 *      windows are destroyed and re-created on every opening, the IC
 *      must be re-bound each time; winxim.c's window-aware cache makes
 *      xim_create_ic() destroy any IC that was bound to the previous
 *      (now dead) window and create a fresh one.  Skipping this made
 *      fcitx5 disengage and swallowed every keystroke from the second
 *      dialog opening onward.
 */
static void
xim_map_notify_focus_handler(Widget w, XtPointer client_data,
                             XEvent *event, Boolean *cont)
{
    Widget ok;
    XimGetlinState *state = &g_xim_getlin_state;

    nhUse(client_data);
    nhUse(cont);

    if (event->type != MapNotify || w == (Widget) 0)
        return;

    ok = state->ok_widget;
    if (ok == (Widget) 0 || !XtIsRealized(ok) || XtWindow(ok) == None)
        return;

    /*
     * NetHackJP: take the X input focus for the OK button so fcitx5's
     * per-window focus tracking (FocusIn on the IC's XNFocusWindow)
     * engages the dialog's IC, but remember what was focused before so
     * XimDialogReleaseInputFocus() can put it back when the dialog
     * pops down.  Without the restore, the X server reverts the focus
     * to the toplevel shell when the dialog's windows are unmapped,
     * which abandons the application's implicit PointerRoot
     * (pointer-following) focus model - with the focus pinned on the
     * toplevel, the IM server sees FocusIn/FocusOut churn on windows
     * it tracks and the Japanese input UI can end up engaging in the
     * main game window after the dialog is gone.
     */
    if (!state->focus_saved) {
        XGetInputFocus(XtDisplay(ok), &state->saved_focus_win,
                       &state->saved_focus_revert);
        state->focus_saved = TRUE;
    }
    XSetInputFocus(XtDisplay(ok), XtWindow(ok),
                   RevertToParent, CurrentTime);

    if (xim_is_active()) {
        state->ic = xim_create_ic((void *) ok);
        if (state->ic != (void *) 0)
            xim_focus_in(state->ic);
    }
}

/*
 * NetHackJP: restore the X input focus that was in effect before the
 * getlin / askname dialog grabbed it.  Called from nh_XtPopdown() so
 * every way of closing the dialog (OK, Cancel, Escape, the window
 * manager's delete protocol) funnels through a single restore point.
 * A no-op when no dialog has grabbed the focus.
 */
void
XimDialogReleaseInputFocus(void)
{
    XimGetlinState *state = &g_xim_getlin_state;

    if (!state->focus_saved)
        return;
    state->focus_saved = FALSE;
    if (state->ok_widget != (Widget) 0) {
        /* XtDisplay() works on unrealized widgets too; restoring the
         * saved window (which may be PointerRoot or None) returns the
         * server to the focus model the application was using. */
        XSetInputFocus(XtDisplay(state->ok_widget),
                       state->saved_focus_win,
                       state->saved_focus_revert, CurrentTime);
    }
    state->saved_focus_win = 0;
}

void
XimDialogFocusInput(Widget form)
{
    Widget ok, popup;

    if (form == (Widget) 0)
        return;
    /* NetHackJP: the OK button is named "OK" (capitalized) to match
     * the NetHack.ad resource patterns ("NetHack*OK.foreground: green",
     * "NetHack*OK.shapeStyle: roundedRectangle", etc.).  Looking it up
     * with the WRONG case ("ok") would silently fail and leave the
     * dialog with no keyboard focus and no event handler handlers,
     * making the dialog look completely unresponsive. */
    ok = XtNameToWidget(form, "OK");
    if (ok == (Widget) 0)
        return;

    popup = XtParent(form);
    g_xim_getlin_state.ok_widget = ok;

    /* XtSetKeyboardFocus is safe at any time: if the widget is not
     * yet realized, Xt just records the focus intent and applies
     * it when XtSetKeyboardFocus is called again after realization. */
    XtSetKeyboardFocus(popup, ok);

    /* NetHackJP: the X server input focus and the XIM IC binding are
     * owned by the persistent MapNotify handler installed by
     * CreateXimDialog(); it fires on every dialog opening because
     * positionpopup() unrealizes/re-realizes the shell.  This function
     * deliberately does not touch XSetInputFocus or the IC anymore -
     * the previous one-shot handler installed here fired one opening
     * late (it was added after the map had already happened), leaving
     * the first opening without focus setup and making IM engagement
     * nondeterministic. */
}

/*
 * Set the prompt label text.
 */
void
XimDialogSetPrompt(Widget w, String prompt)
{
    Arg args[1];

    nhUse(w);
    /* Cast away const for the XtSetArg macro; we are not modifying
     * the string, just passing it to Xt for storage. */
    if (prompt == (String) 0)
        prompt = (String) "";
    XtSetArg(args[0], XtNlabel, prompt);
    XtSetValues(g_xim_getlin_state.prompt_label, args, ONE);
    X11_update_label_if_Xft(g_xim_getlin_state.prompt_label);
}

/*
 * Pre-populate the input buffer with the given text.  Used to set the
 * default answer (e.g. current player name for #name).  Truncated to
 * XIM_GETLIN_MAX bytes.
 */
void
XimDialogSetResponse(Widget w, String text)
{
    int n;

    nhUse(w);
    /* Cast away const for memcpy; we are not modifying the source. */
    if (text == (String) 0)
        text = (String) "";
    n = (int) strlen(text);
    if (n > XIM_GETLIN_MAX)
        n = XIM_GETLIN_MAX;
    (void) memcpy(g_xim_getlin_state.buf, text, (size_t) n);
    g_xim_getlin_state.len = n;
    g_xim_getlin_state.buf[n] = '\0';
    xim_getlin_refresh_label(&g_xim_getlin_state);
}

/*
 * Return a freshly-allocated copy of the current buffer.  Caller is
 * responsible for XtFree()-ing the returned string.  Matches the
 * semantics of GetDialogResponse() in dialogs.c.
 */
String
XimDialogGetResponse(Widget w)
{
    nhUse(w);
    return XtNewString(g_xim_getlin_state.buf);
}

/* End wingetlin.c */