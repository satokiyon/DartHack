/* NetHack 5.0	options.c	$NHDT-Date: 1737556914 2025/01/22 06:41:54 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.753 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Michael Allison, 2008. */
/* NetHack may be freely redistributed.  See license for details. */

#ifndef OPTION_LISTS_ONLY
#include "hack.h"
#include "tcap.h"
#else /* OPTION_LISTS_ONLY: (AMIGA) external program for opt lists */
#include "config.h"
#include "objclass.h"
#include "flag.h"
NEARDATA struct flag flags; /* provide linkage */
NEARDATA struct instance_flags iflags; /* provide linkage */
NEARDATA struct accessibility_data a11y;
#define static
#endif

#define BACKWARD_COMPAT
#define COMPLAIN_ABOUT_PRAYCONFIRM

/* whether the 'msg_window' option is used to control ^P behavior */
#if defined(TTY_GRAPHICS) || defined(CURSES_GRAPHICS)
#define PREV_MSGS 1
#else
#define PREV_MSGS 0
#endif

/*
 *  NOTE:  If you add (or delete) an option, please review the following:
 *             doc/options.txt
 *
 *         It contains how-to info and outlines some required/suggested
 *         updates that should accompany your change.
 */

/*
 * include/optlist.h is utilized 3 successive times, for 3 different
 * objectives.
 *
 * The first time is with NHOPT_PROTO defined, to produce and include
 * the prototypes for the individual option processing functions.
 *
 * The second time is with NHOPT_ENUM defined, to produce the enum values
 * for the individual options that are used throughout options processing.
 * They are generally opt_optname, where optname is the name of the option.
 *
 * The third time is with NHOPT_PARSE defined, to produce the initializers
 * to fill out the allopt[] array of options (both boolean and compound).
 *
 */

#define OPTIONS_C

#define NHOPT_PROTO
#include "optlist.h"
#undef NHOPT_PROTO

#define NHOPT_PARSE
static struct allopt_t allopt_init[] = {
#include "optlist.h"
    {(const char *) 0, OptS_Advanced, 0, 0, 0, set_in_sysconf, BoolOpt,
     No, No, No, No, Term_False, 0, (boolean *) 0,
     (int (*)(int, int, boolean, char *, char *)) 0,
     (char *) 0, (const char *) 0, (const char *) 0, 0, 0, 0, TRUE }
};
#undef NHOPT_PARSE

#undef OPTIONS_C

#define PILE_LIMIT_DFLT 5
#define rolestring(val, array, field) \
    ((val >= 0) ? array[val].field : (val == ROLE_RANDOM) ? randomrole : none)

enum window_option_types {
    MESSAGE_OPTION = 1,
    STATUS_OPTION,
    MAP_OPTION,
    MENU_OPTION,
    TEXT_OPTION
};

enum optn_result {
    optn_silenterr = -1, optn_err = 0, optn_ok
};
enum requests {
    do_nothing, do_init, do_set, do_handler, get_val, get_cnf_val
};

static struct allopt_t allopt[SIZE(allopt_init)];

#ifndef OPTION_LISTS_ONLY

/* use rest of file */

/* extern char configfile[]; */ /* for messages; files.c */
extern const struct symparse loadsyms[];
#if defined(TOS)
extern boolean colors_changed;  /* in tos.c */
#endif
#ifdef VIDEOSHADES
extern char *shade[3];          /* in sys/msdos/video.c */
extern char ttycolors[CLR_MAX]; /* in sys/msdos/video.c */
#endif

static char empty_optstr[] = { '\0' };
static boolean duplicate, using_alias;
static boolean give_opt_msg = TRUE;

enum { MAX_ROLEOPT = 4 };  /* 4: role,race,gend,algn */
static boolean opt_set_in_config[OPTCOUNT];
static char *roleoptvals[MAX_ROLEOPT][num_opt_phases];

static NEARDATA const char *OptS_type[OptS_Advanced+1] = {
    "General", "Behavior", "Map", "Status", "Advanced"
};

static const char def_inv_order[MAXOCLASSES] = {
    COIN_CLASS, AMULET_CLASS, WEAPON_CLASS, ARMOR_CLASS, FOOD_CLASS,
    SCROLL_CLASS, SPBOOK_CLASS, POTION_CLASS, RING_CLASS, WAND_CLASS,
    TOOL_CLASS, GEM_CLASS, ROCK_CLASS, BALL_CLASS, CHAIN_CLASS, 0,
};

static const char none[] = "(none)", randomrole[] = "random",
                  to_be_done[] = "(to be done)",
                  defopt[] = "default", defbrief[] = "def";

/* paranoia[] - used by parseoptions() and handler_paranoid_confirmation() */
static const struct paranoia_opts {
    int flagmask;        /* which paranoid option */
    const char *argname; /* primary name */
    int argMinLen;       /* minimum number of letters to match */
    const char *synonym; /* alternate name (optional) */
    int synMinLen;
    const char *explain; /* for interactive menu */
} paranoia[] = {
    /* there are some initial-letter conflicts: "a"ttack vs "A"utoall vs
       "a"ll, "attack" takes precedence and "all" isn't present in the
       interactive menu with "Autoall" capitalized there,
       and "d"ie vs "d"eath, synonyms for each other so doesn't matter;
       (also "p"ray vs "P"aranoia, "pray" takes precedence since "Paranoia"
       is just a synonym for "Confirm"); "b"ones vs "br"eak-wand, the
       latter requires at least two letters; "e"at vs "ex"plore,
       "cont"inue eating vs "C"onfirm; "wand"-break vs "Were"-change,
       both require at least two letters during config processing but use
       one letter with case-sensitivity for 'm O's interactive menu;
       if any entry or alias beginning with 'n' gets added, aside from "none",
       the parsing to accept "nofoo" to mean "!foo" will need fixing */
    { PARANOID_CONFIRM, "Confirm", 1, "Paranoia", 2,
      "for \"yes\" confirmations, require \"no\" to reject" },
    { PARANOID_QUIT, "quit", 1, "explore", 2,
      "yes vs y to quit or to enter explore mode" },
    { PARANOID_DIE, "die", 1, "death", 2,
      "yes vs y to die (explore mode or debug mode)" },
    { PARANOID_BONES, "bones", 1, 0, 0,
      "yes vs y to save bones data when dying in debug mode" },
    { PARANOID_HIT, "attack", 1, "hit", 1,
      "yes vs y to attack a peaceful monster" },
    { PARANOID_BREAKWAND, "wand-break", 2, "break-wand", 2,
      "yes vs y to break a wand via (a)pply" },
    { PARANOID_EATING, "eat", 1, "continue", 4,
      "yes vs y to continue eating after first bite when satiated" },
    { PARANOID_WERECHANGE, "Were-change", 2, (const char *) 0, 0,
      "yes vs y to change form when lycanthropy is controllable" },
    /* extra y/n questions rather than changing y/n to yes/n[o];
       they switch to yes/no if paranoid:confirm is also set */
    { PARANOID_PRAY, "pray", 1, 0, 0,
      "y required to pray (supersedes old \"prayconfirm\" option)" },
    { PARANOID_TRAP, "trap", 1, "move-trap", 1,
      "y required to enter known trap unless considered harmless" },
    { PARANOID_AUTOALL, "Autoall", 2, "autoselect-all", 2,
      "y required to pick filter choice 'A' for menustyle:Full" },
    /* not a yes/n[o] vs y/n change nor a y/n addition */
    { PARANOID_SWIM, "swim", 1, 0, 0,
      "'m' prefix necessary to deliberately walk into lava or water" },
    { PARANOID_REMOVE, "Remove", 1, "Takeoff", 1,
      /* normally when there is only 1 candidate it's chosen automatically */
      "always pick from inventory for Remove and Takeoff" },
    /* for config file parsing; interactive menu skips these */
    { 0, "none", 4, 0, 0, 0 }, /* require full word match */
    { ~0, "all", 3, 0, 0, 0 }, /* ditto */
};

static NEARDATA const char *menutype[][3] = { /* 'menustyle' settings */
    { "traditional",  "[prompt for object class(es), then",
                      " ask y/n for each item in those classes]" },
    { "combination",  "[prompt for object class(es), then",
                      " use menu for items in those classes]" },
    { "full",         "[use menu to choose class(es), then",
                      " use another menu for items in those]" },
    { "partial",      "[skip class filtering; always",
                      " use menu of all available items]" }
};
#if PREV_MSGS /* tty supports all four settings, curses just final two */
static NEARDATA const char *msgwind[][3] = { /* 'msg_window' settings */
    { "single",       "[show one old message at a time,",
                      " most recent first]" },
    { "combination",  "[for consecutive ^P requests, use",
                      " 'single' for first two, then 'full']" },
    { "full",         "[show all available messages,",
                      " oldest first and most recent last]" },
    { "reversed",     "[show all available messages,",
                      " most recent first]" }
};
#endif
/* autounlock settings */
static NEARDATA const char *unlocktypes[][2] = {
    { "untrap",    "(might fail)" },
    { "apply-key", "" },
    { "kick",      "(doors only)" },
    { "force",     "(chests/boxes only)" },
};
static NEARDATA const char *burdentype[] = {
    "unencumbered", "burdened",     "stressed",
    "strained",     "overtaxed",    "overloaded"
};
static NEARDATA const char *runmodes[] = {
    "teleport",     "run",          "walk",     "crawl"
};
static NEARDATA const char *sortltype[] = {
    "none",         "loot",         "full"
};
/* second column is an alias for the first; third is brief explanation;
   entries 5 and 6 are 1|4 and 2|4 (tty only) */
static NEARDATA const char *perminv_modes[][3] = {
  /*0*/ { "none",      "off",        "no permanent inventory window" },
  /*1*/ { "all" ,      "on",         "all inventory except for gold" },
  /*2*/ { "full",      "gold",       "full inventory including gold" },
  /*3*/ { NULL,        NULL,         NULL },
  /*4*/ { NULL,        NULL,         NULL },
#ifdef TTY_PERM_INVENT
  /*5*/ { "on+grid",   "all+grid",   "all except gold, plus unused letters" },
  /*6*/ { "gold+grid", "full+grid",  "full inventory, plus unused letters" },
#else
  /*5*/ { NULL,        NULL,         NULL },
  /*6*/ { NULL,        NULL,         NULL },
#endif
  /*7*/ { NULL,        NULL,         NULL },
  /*8*/ { "in-use",    "inuse-only", "subset: items currently in use" },
};

struct objsymopt {
    int num;
    const char *nam;
    const char *descr;
};

/*
 * menuobjsyms:
 *   Inventory display for the various values of menuobjsyms.
 *   4' and 5' represent !sortpack which lacks headers; they
 *   produce the same result.
 *
 *   0:                         1:
 *        Weapons                    Weapons  (')')
 *        a - 15 darts               a - 15 darts
 *        Armor                      Armor    ('[')
 *        b - Hawaiian shirt         b - Hawaiian shirt
 *   2:                         3:
 *        Weapons                    Weapons  (')')
 *        a ) 15 darts               a ) 15 darts
 *        Armor                      Armor    ('[')
 *        b [ Hawaiian shirt         b [ Hawaiian shirt
 *   4:                         5:
 *        Weapons                    Weapons  (')')
 *        a - 15 darts               a - 15 darts
 *        Armor                      Armor    ('[')
 *        b - Hawaiian shirt         b - Hawaiian shirt
 *   4':                        5':
 *        a ) 15 darts               a ) 15 darts
 *        b [ Hawaiian shirt         b [ Hawaiian shirt
 */
static const struct objsymopt objsymvals[] = {
    { 0, "none",         "don't show object symbols in menus" },
    { 1, "headers",      "show object symbols in menu header lines" },
    { 2, "entries",      "show object symbols in individual menu entries" },
    { 3, "both",         "show object symbols in headers and menu entries" },
    { 4, "conditional",  "show objsyms in entries if no headers are shown" },
    { 5, "one-or-other", "show objsyms in header, in entries if no header" },
};

/*
 * Default menu manipulation command accelerators.  These may _not_ be:
 *
 *      + a number or '#' - reserved for counts
 *      + an upper or lower case US ASCII letter - used for accelerators
 *      + ESC - reserved for escaping the menu
 *      + NULL, CR or LF - reserved for committing the selection(s).  NULL
 *        is kind of odd, but the tty's xwaitforspace() will return it if
 *        someone hits a <ret>.
 *      + a default object class symbol - used for object class accelerators
 *
 * Standard letters (for now) are:
 *
 *              <  back 1 page
 *              >  forward 1 page
 *              ^  first page
 *              |  last page
 *              :  search
 *
 *              page            all
 *               ,    select     .
 *               \    deselect   -
 *               ~    invert     @
 *
 * The command name list is duplicated in the compopt array.
 */
typedef struct {
    const char *name;
    char cmd;
    const char *desc;
} menu_cmd_t;

static const menu_cmd_t default_menu_cmd_info[] = {
    { "menu_next_page",     MENU_NEXT_PAGE,     "Go to next page" },
    { "menu_previous_page", MENU_PREVIOUS_PAGE, "Go to previous page" },
    { "menu_first_page",    MENU_FIRST_PAGE,    "Go to first page" },
    { "menu_last_page",     MENU_LAST_PAGE,     "Go to last page" },
    { "menu_select_all",    MENU_SELECT_ALL,
                            "Select all items in entire menu" },
    { "menu_invert_all",    MENU_INVERT_ALL,
                            "Invert selection for all items" },
    { "menu_deselect_all",  MENU_UNSELECT_ALL,
                            "Unselect all items in entire menu" },
    { "menu_select_page",   MENU_SELECT_PAGE,
                            "Select all items on current page" },
    { "menu_invert_page",   MENU_INVERT_PAGE,
                            "Invert current page's selections" },
    { "menu_deselect_page", MENU_UNSELECT_PAGE,
                            "Unselect all items on current page" },
    { "menu_search",        MENU_SEARCH,
                            "Search and invert matching items" },
    { "menu_shift_right",   MENU_SHIFT_RIGHT,
                            "Pan current page to right (perm_invent only)" },
    { "menu_shift_left",    MENU_SHIFT_LEFT,
                            "Pan current page to left (perm_invent only)" },
    { (char *) 0, '\0', (char *) 0 }
};

static const char n_currently_set[] = "(%d currently set)";

staticfn void nmcpy(char *, const char *, int);
staticfn void escapes(const char *, char *);
staticfn void rejectoption(const char *);
staticfn char *string_for_opt(char *, boolean);
staticfn char *string_for_env_opt(const char *, char *, boolean);
staticfn void bad_negation(const char *, boolean);
staticfn void set_menuobjsyms_flags(int);
staticfn int change_inv_order(char *);
staticfn boolean warning_opts(char *, const char *);
staticfn int feature_alert_opts(char *, const char *);
staticfn boolean duplicate_opt_detection(int);
staticfn void complain_about_duplicate(int);
staticfn int length_without_val(const char *, int len);
staticfn void determine_ambiguities(void);
staticfn int check_misc_menu_command(char *, char *);
staticfn int opt2roleopt(int);
staticfn char *getoptstr(int, int);
staticfn void saveoptstr(int, const char *);
staticfn void unsaveoptstr(int, int);
staticfn int petname_optfn(int, int, boolean, char *, char *);
staticfn int shared_menu_optfn(int, int, boolean, char *, char *);
staticfn int spcfn_misc_menu_cmd(int, int, boolean, char *, char *);

staticfn const char * msgtype2name(int);
staticfn int query_msgtype(void);
staticfn boolean msgtype_add(int, char *);
staticfn void free_one_msgtype(int);
staticfn int msgtype_count(void);
staticfn boolean test_regex_pattern(const char *, const char *);
staticfn boolean parse_role_opt(int, boolean, const char *, char *, char **);
staticfn char *get_cnf_role_opt(int);
staticfn unsigned int longest_option_name(int, int);
staticfn int doset_simple_menu(void);
staticfn void reset_needed_visuals(void);
staticfn void doset_add_menu(winid, const char *, const char *, int, int);
staticfn int handle_add_list_remove(const char *, int);
staticfn void all_options_conds(strbuf_t *);
staticfn void all_options_menucolors(strbuf_t *);
staticfn void all_options_msgtypes(strbuf_t *);
staticfn void all_options_apes(strbuf_t *);
#ifdef CHANGE_COLOR
staticfn void all_options_palette(strbuf_t *);
#endif
staticfn void remove_autopickup_exception(struct autopickup_exception *);
staticfn int count_apes(void);
staticfn int count_cond(void);
staticfn void enhance_menu_text(char *, size_t, int, boolean *,
                                struct allopt_t *);
staticfn boolean can_set_perm_invent(void);
staticfn int handler_align_misc(int);
staticfn int handler_autounlock(int);
staticfn int handler_disclose(void);
staticfn int handler_menu_headings(void);
staticfn int handler_menu_objsyms(void);
staticfn int handler_menustyle(void);
staticfn int handler_msg_window(void);
staticfn int handler_number_pad(void);
staticfn int handler_paranoid_confirmation(void);
staticfn int handler_perminv_mode(void);
staticfn int handler_pickup_burden(void);
staticfn int handler_pickup_types(void);
staticfn int handler_runmode(void);
staticfn int handler_petattr(void);
staticfn int handler_sortloot(void);
staticfn int handler_symset(int);
staticfn int handler_versinfo(void);
staticfn int handler_whatis_coord(void);
staticfn int handler_whatis_filter(void);
/* next few are not allopt[] entries, so will only be called
   directly from doset, not from individual optfn's */
staticfn int handler_autopickup_exception(void);
staticfn int handler_menu_colors(void);
staticfn int handler_msgtype(void);
staticfn int handler_windowborders(void);

staticfn boolean is_wc_option(const char *);
staticfn boolean wc_supported(const char *);
staticfn boolean is_wc2_option(const char *);
staticfn boolean wc2_supported(const char *);
staticfn void wc_set_font_name(int, char *);
staticfn int wc_set_window_colors(char *);
staticfn boolean illegal_menu_cmd_key(uchar);
staticfn const char *term_for_boolean(int, boolean *);

/* ask user if they want a tutorial, except if tutorial boolean option has
   been set in config - either on or off - in which case just obey that
   setting without asking */
boolean
ask_do_tutorial(void)
{
    boolean dotut = flags.tutorial;

    if (!opt_set_in_config[opt_tutorial]) {
        winid win;
        menu_item *sel;
        anything any;
        char buf[BUFSZ];
        const char *rc;
        boolean norc;
        int n, pass = 0;

        rc = nh_basename(get_configfile(), TRUE);
        norc = !strcmp(get_configfile(), "/dev/null");
        Snprintf(buf, sizeof buf,
                 "この確認を表示しないには、%s に \"OPTIONS=!tutorial\" を設定してください。",
                 (rc && *rc && !norc) ? rc : "設定ファイル");
        do {
            win = create_nhwindow(NHW_MENU);
            start_menu(win, MENU_BEHAVE_STANDARD);
            any = cg.zeroany;
            any.a_char = 'y';
            add_menu(win, &nul_glyphinfo, &any, any.a_char, 0,
                     ATR_NONE, NO_COLOR,
                     "はい、チュートリアルを行う", MENU_ITEMFLAGS_NONE);
            any.a_char = 'n';
            add_menu(win, &nul_glyphinfo, &any, any.a_char, 0,
                     ATR_NONE, NO_COLOR,
                     "いいえ、通常プレイを開始する", MENU_ITEMFLAGS_NONE);

            add_menu_str(win, "");
            add_menu_str(win, buf);
            if (pass++) /* we'll get here after <space> or <return> */
                add_menu_str(win, "(yかnで選択してください。)");

            end_menu(win, "チュートリアルを実行しますか？");

            n = select_menu(win, PICK_ONE, &sel);
            destroy_nhwindow(win);
        } while (!n);
        if (n > 0) {
            dotut = (sel[0].item.a_char == 'y');
            free((genericptr_t) sel);
        } else { /* ESC */
            dotut = FALSE;
        }
    }
    return dotut;
}

/*
 **********************************
 *
 *   parseoptions
 *
 **********************************
 */
boolean
parseoptions(
    char *opts,
    boolean tinitial,
    boolean tfrom_file)
{
    char *op;
    boolean negated, got_match = FALSE, pfx_match = FALSE;
#if 0
    boolean has_val = FALSE;
#endif
    int i, matchidx = -1, optresult = optn_err, optlen, optlen_wo_val;
    boolean retval = TRUE;

    duplicate = FALSE;
    using_alias = FALSE;
    go.opt_initial = tinitial;
    go.opt_from_file = tfrom_file;
    /*
     * Process elements of comma-separated list in right to left order.
     * When some options are set interactively--notably various compound
     * options that issue a prompt for a value--they use parseoptions()
     * to handle setting the new value.  For those, 'tinitial' is False
     * and if user tries to supply a comma-separated list, it will be
     * treated as part of the current option, probably failing to parse.
     */
    if (tinitial && (op = strchr(opts, ',')) != 0) {
        *op++ = 0;
        /* current element remains pending while the rest of the line gets
           handled recursively; if the rest of line contains any commas,
           then the process will recurse deeper as it is processed */
        if (!parseoptions(op, go.opt_initial, go.opt_from_file))
            retval = FALSE;
    }
    if (strlen(opts) > BUFSZ / 2) {
        config_error_add("Option too long, max length is %i characters",
                         (BUFSZ / 2));
        return FALSE;
    }

    /* strip leading and trailing white space */
    while (isspace((uchar) *opts))
        opts++;
    op = eos(opts);
    while (--op >= opts && isspace((uchar) *op))
        *op = '\0';

    if (!*opts) {
        config_error_add("Empty statement");
        return FALSE;
    }
    negated = FALSE;
    while ((*opts == '!') || !strncmpi(opts, "no", 2)) {
        opts += (*opts == '!') ? 1 : (opts[2] != '-') ? 2 : 3;
        negated = !negated;
    }
    optlen = (int) strlen(opts);
    optlen_wo_val = length_without_val(opts, optlen);
    if (optlen_wo_val < optlen) {
#if 0
        has_val = TRUE;
#endif
        optlen = optlen_wo_val;
#if 0
    } else {
        has_val = FALSE;
#endif
    }

    for (i = 0; i < OPTCOUNT; ++i) {
        got_match = FALSE;

        if (allopt[i].pfx) {
            if (str_start_is(opts, allopt[i].name, TRUE)) {
                matchidx = i;
                got_match = pfx_match = TRUE;
            }
        }
#if 0   /* this prevents "boolopt:True" &c */
        if (!got_match) {
            if (has_val && !allopt[i].valok)
                continue;
        }
#endif
        /*
         * During option initialization, the function
         *     determine_ambiguities()
         * figured out exactly how many characters are required to
         * unambiguously differentiate one option from all others, and it
         * placed that number into each option's allopt[n].minmatch.
         *
         */
        if (!got_match && allopt[i].name)
            got_match = match_optname(opts, allopt[i].name,
                                      allopt[i].minmatch, TRUE);
        if (got_match) {
            if (!allopt[i].pfx && optlen < allopt[i].minmatch) {
                config_error_add(
             "Ambiguous option %s, %d characters are needed to differentiate",
                                 opts, allopt[i].minmatch);
                break;
            }
            matchidx = i;
            break;
        }
    }

    if (!got_match) {
        /* spin through the aliases to see if there's a match in those.
           Note that if multiple delimited aliases for the same option
           becomes desirable in the future, this is where you'll need
           to split a delimited allopt[i].alias field into each
           individual alias */

        for (i = 0; i < OPTCOUNT; ++i) {
            if (!allopt[i].alias)
                continue;
            got_match = match_optname(opts, allopt[i].alias,
                                      (int) strlen(allopt[i].alias),
                                      TRUE);
            if (got_match) {
                matchidx = i;
                using_alias = TRUE;
                break;
            }
        }
    }

    /* allow optfn's to test whether they were called from parseoptions() */
    program_state.in_parseoptions++;

    if (got_match && (matchidx >= 0 && matchidx < OPTCOUNT)
                      && !allopt[matchidx].disregarded) {
        duplicate = duplicate_opt_detection(matchidx);
        if (duplicate && !allopt[matchidx].dupeok)
            complain_about_duplicate(matchidx);

        /* check for bad negation, so option functions don't have to */
        if (negated && !allopt[matchidx].negateok) {
            bad_negation(allopt[matchidx].name, TRUE);
            return optn_err;
        }

        /*
         * Now call the option's associated function via the function
         * pointer for it in the allopt[] array, specifying a 'do_set' req.
         */
        if (allopt[matchidx].optfn) {
            op = string_for_opt(opts, TRUE);
            optresult = (*allopt[matchidx].optfn)(allopt[matchidx].idx,
                                                  do_set, negated, opts, op);
            if (optresult == optn_ok)
                opt_set_in_config[matchidx] = TRUE;
        }
    }

    if (program_state.in_parseoptions > 0)
        program_state.in_parseoptions--;

#if 0
    /* This specialization shouldn't be needed any longer because each of
       the individual options is part of the allopts[] list, thus already
       taken care of in the for-loop above */
    if (!got_match) {
        int res = check_misc_menu_command(opts, op);

        if (res >= 0)
            optresult = spcfn_misc_menu_cmd(res, do_set, negated, opts, op);
        if (optresult == optn_ok)
            got_match = TRUE;
    }
#endif

    if (!got_match) {
        /* Is it a symbol? */
        if (strstr(opts, "S_") == opts && parsesymbols(opts, PRIMARYSET)) {
            switch_symbols(TRUE);
            check_gold_symbol();
            optresult = optn_ok;
        }
    }

    if (optresult == optn_silenterr
        || (got_match && allopt[matchidx].disregarded)
            || (!got_match && config_unmatched_ignored()))
        return FALSE;
    if (pfx_match && optresult == optn_err) {
        char pfxbuf[BUFSZ], *pfxp;

        Snprintf(pfxbuf, sizeof pfxbuf, "%s", opts);
        if ((pfxp = strchr(pfxbuf, ':')) != 0)
            *pfxp = '\0';
        config_error_add("bad option suffix variation '%s'", pfxbuf);
        return FALSE;
    }
    if (got_match && optresult == optn_err)
        return FALSE;
    if (optresult == optn_ok)
        return retval;

    /* out of valid options */
    config_error_add("Unknown option '%s'", opts);
    return FALSE;
}

staticfn int
check_misc_menu_command(char *opts, char *op UNUSED)
{
    int i;
    const char *name_to_check;

    /* check for menu command mapping */
    for (i = 0; default_menu_cmd_info[i].name; i++) {
        name_to_check = default_menu_cmd_info[i].name;
        if (match_optname(opts, name_to_check,
                          (int) strlen(name_to_check), TRUE))
            return i;
    }
    return -1;
}

static int roleopt2opt[4] = {
    opt_role, opt_race, opt_gender, opt_alignment
};

/* role => 0, race => 1, gender => 2, alignment =>3 */
staticfn int
opt2roleopt(int roleopt)
{
    switch (roleopt) {
    case opt_role:
        return 0;
    case opt_race:
        return 1;
    case opt_gender:
        return 2;
    case opt_alignment:
        return 3;
    default:
        break;
    }
    return 0;
}

/* fetch saved option string for a particular option phase */
staticfn char *
getoptstr(int optidx, int ophase)
{
    int roleoptindx = opt2roleopt(optidx);

    if (ophase == num_opt_phases) { /* any source */
        int phase;

        /* find non-Null, in order optvals[][play_opt], [cmdline_opt],
           [environ_opt], [rc_file_opt], [syscf_opt], [builtin_opt] */
        for (phase = num_opt_phases - 1; phase >= 0; --phase)
            if (roleoptvals[roleoptindx][phase]) {
                ophase = phase;
                break;
            }
    }
    if ((roleoptindx >= 0 && roleoptindx < MAX_ROLEOPT
          && ophase >= 0 && ophase < num_opt_phases))
        return roleoptvals[roleoptindx][ophase];
    panic("bad index roleoptvals[%d][%d]", roleoptindx, ophase);
    /*NOTREACHED*/
}

/* to track some unparsed option settings in case #saveoptions needs them */
staticfn void
saveoptstr(int optidx, const char *optstr)
{
    int phase = go.opt_phase, roleoptindx = opt2roleopt(optidx);
    const char *p = strchr(optstr, ':'), *q = strchr(optstr, '=');

    /* strip away "optname:" from optname:optstr */
    if (!p || (q && q < p))
        p = q;
    if (p)
        optstr = p + 1;

    if (roleoptvals[roleoptindx][phase])
        free((genericptr_t) roleoptvals[roleoptindx][phase]);
    roleoptvals[roleoptindx][phase] = dupstr(optstr);
}

/* discard specific saved option string */
staticfn void
unsaveoptstr(int optidx, int ophase)
{
    int roleoptindx = opt2roleopt(optidx);

    if (roleoptvals[roleoptindx][ophase])
        free((genericptr_t) roleoptvals[roleoptindx][ophase]),

        roleoptvals[roleoptindx][ophase] = 0;
}

/* discard all saved option strings */
void
freeroleoptvals(void)
{
    int i, j;

    for (i = 0; i < 4; ++i)
        for (j = 0; j < num_opt_phases; ++j)
            unsaveoptstr(roleopt2opt[i], j);
}

#if 0   /* not needed */

/* put roleoptvals[][] into save file; will be needed if #saveoptions
   takes place after restore */
void
saveoptvals(NHFILE *nhfp)
{
    if (update_file(nhfp)) {
        char *val;
        unsigned len;
        int i, j;

        for (i = 0; i < 4; ++i)
            for (j = 0; j < num_opt_phases; ++j) {
                val = roleoptvals[i][j];
                len = val ? Strlen(val) + 1 : 0;
                Sfo_unsigned(nhfp, &len, "optvals-len");
                if (val)
                    Sfo_char(nhfp, val, "optvals-val", len);
            }
    }
    if (release_data(nhfp))
        freeroleoptvals();
}

/* get roleoptvals[][] from save file */
void
restoptvals(NHFILE *nhfp)
{
    char *val;
    unsigned len;
    int i, j;

    if (nhfp->structlevel) {
        for (i = 0; i < 4; ++i)
            for (j = 0; j < num_opt_phases; ++j) {
                /* len includes terminating '\0' for non-Null values */
                Sfi_unsigned(nhfp, &len, "optvals-len");
                if (len) {
                    val = roleoptvals[i][j] = (char *) alloc(len);
                    Sfi_char(nhfp, val, "opvals-val", (int) len);
                } else {
                    roleoptvals[i][j] = NULL;
                }
            }
    }
}

#endif /* 0 */

/* common to optfn_catname(), optfn_dogname(), optfn_horsename() */
staticfn int
petname_optfn(
    int optidx, int req,
    boolean negated,
    char *opts, char *op)
{
    char failsafe[PL_PSIZ + 1];
    char *petname = (optidx == opt_catname) ? gc.catname
                    : (optidx == opt_dogname) ? gd.dogname
                      : (optidx == opt_horsename) ? gh.horsename
                        : failsafe;

    if (req == do_init) {
        ;
    } else if (req == do_set) {
        if (op == empty_optstr && !negated)
            return optn_err;
        if (negated || !strcmp(op, "none") || !strcmp(op, none))
            op = empty_optstr;
        nmcpy(petname, op, PL_PSIZ);
        sanitize_name(petname);
    } else if (req == get_val || req == get_cnf_val) {
        failsafe[0] = '\0';
        Sprintf(opts, "%s", *petname ? petname
                            : (req == get_cnf_val) ? "none" : none);
    }
    return optn_ok;
}

/*
 **********************************
 *
 *   Per-option Functions
 *
 **********************************
 */

staticfn int
optfn_alignment(
    int optidx,
    int req,
    boolean negated,
    char *opts,
    char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* alignment:string */
        if (!parse_role_opt(optidx, negated, allopt[optidx].name, opts, &op))
            return optn_silenterr;

        if (*op != '!') {
            if ((flags.initalign = str2align(op)) == ROLE_NONE) {
                config_error_add("Unknown %s '%s'", allopt[optidx].name, op);
                return optn_err;
            }
            saveoptstr(optidx, rolestring(flags.initalign, aligns, adj));
        }
        return optn_ok;
    }
    if (req == get_val) {
        Sprintf(opts, "%s", rolestring(flags.initalign, aligns, adj));
        return optn_ok;
    }
    if (req == get_cnf_val) {
        op = get_cnf_role_opt(optidx);
        Strcpy(opts, op ? op : "none");
        return optn_ok;
    }
    return optn_ok;
}


staticfn int
optfn_align_message(
    int optidx, int req, boolean negated,
    char *opts, char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* WINCAP align_message:[left|top|right|bottom] */

        op = string_for_opt(opts, negated);
        if ((op != empty_optstr) && !negated) {
            if (!strncmpi(op, "left", sizeof "left" - 1))
                iflags.wc_align_message = ALIGN_LEFT;
            else if (!strncmpi(op, "top", sizeof "top" - 1))
                iflags.wc_align_message = ALIGN_TOP;
            else if (!strncmpi(op, "right", sizeof "right" - 1))
                iflags.wc_align_message = ALIGN_RIGHT;
            else if (!strncmpi(op, "bottom", sizeof "bottom" - 1))
                iflags.wc_align_message = ALIGN_BOTTOM;
            else {
                config_error_add("Unknown %s parameter '%s'",
                                 allopt[optidx].name, op);
                return optn_err;
            }
        } else if (negated) {
            bad_negation(allopt[optidx].name, TRUE);
            return optn_err;
        }
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        int which;

        which = iflags.wc_align_message;
        Sprintf(opts, "%s",
                (which == ALIGN_TOP) ? "top"
                : (which == ALIGN_LEFT) ? "left"
                  : (which == ALIGN_BOTTOM) ? "bottom"
                    : (which == ALIGN_RIGHT) ? "right"
                      : defopt);
        return optn_ok;
    }
    if (req == do_handler) {
        return handler_align_misc(optidx);
    }
    return optn_ok;
}

staticfn int
optfn_align_status(
    int optidx, int req, boolean negated,
    char *opts, char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* WINCAP align_status:[left|top|right|bottom] */
        op = string_for_opt(opts, negated);
        if ((op != empty_optstr) && !negated) {
            if (!strncmpi(op, "left", sizeof "left" - 1))
                iflags.wc_align_status = ALIGN_LEFT;
            else if (!strncmpi(op, "top", sizeof "top" - 1))
                iflags.wc_align_status = ALIGN_TOP;
            else if (!strncmpi(op, "right", sizeof "right" - 1))
                iflags.wc_align_status = ALIGN_RIGHT;
                iflags.wc_align_status = ALIGN_BOTTOM;
                iflags.wc_align_status = ALIGN_BOTTOM;
            else {
                config_error_add("Unknown %s parameter '%s'",
                                 allopt[optidx].name, op);
                return optn_err;
            }
        } else if (negated) {
            bad_negation(allopt[optidx].name, TRUE);
            return optn_err;
        }
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {

        which = iflags.wc_align_status;
        Sprintf(opts, "%s",
                (which == ALIGN_TOP) ? "top"
                : (which == ALIGN_LEFT) ? "left"
                  : (which == ALIGN_BOTTOM) ? "bottom"
                    : (which == ALIGN_RIGHT) ? "right"
                      : defopt);
        return optn_ok;
    }
    if (req == do_handler) {
        return handler_align_misc(optidx);
    }
    return optn_ok;
}

staticfn int
optfn_altkeyhandling(
    int optidx UNUSED,
    int req,
    boolean negated,
    char *opts,
    char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* altkeyhandling:string */

#if defined(WIN32CON) && defined(TTY_GRAPHICS)
        if (op == empty_optstr || negated)
            return optn_err;
        set_altkeyhandling(op);
#else
        nhUse(negated);
        nhUse(op);
#endif
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        opts[0] = '\0';
#ifdef WIN32
        Sprintf(opts, "%s",
                (iflags.key_handling == nh340_keyhandling)
                    ? "340"
                    : (iflags.key_handling == ray_keyhandling)
                        ? "ray"
                        : "default");
#endif
        return optn_ok;
    }
#ifdef WIN32CON
    if (req == do_handler) {
        return set_keyhandling_via_option();
    }
#endif
    return optn_ok;
}

staticfn int
optfn_autounlock(
    int optidx,
    int req,
    boolean negated,
    char *opts,
    char *op)
{
    if (req == do_init) {
        flags.autounlock = AUTOUNLOCK_APPLY_KEY;
        return optn_ok;
    }
    if (req == do_set) {
        /* autounlock:none or autounlock:untrap+apply-key+kick+force;
           autounlock without a value is same as autounlock:apply-key and
           !autounlock is same as autounlock:none; multiple values can be
           space separated or plus-sign separated but the same separation
           must be used for each element, not mix&match */
        char sep, *nxt;
        unsigned newflags;
        int i;

        if ((op = string_for_opt(opts, TRUE)) == empty_optstr) {
            flags.autounlock = negated ? 0 : AUTOUNLOCK_APPLY_KEY;
            return optn_ok;
        }
        newflags = 0;
        sep = strchr(op, '+') ? '+' : ' ';
        while (op) {
            boolean matched = FALSE;
            op = trimspaces(op); /* might have leading space */
            if ((nxt = strchr(op, sep)) != 0) {
                *nxt++ = '\0';
                op = trimspaces(op); /* might have trailing space after
                                      * plus sign removal */
            }
            if (str_start_is("none", op, TRUE))
                negated = TRUE, matched = TRUE;
            for (i = 0; i < SIZE(unlocktypes) && !matched; ++i) {
                if (str_start_is(unlocktypes[i][0], op, TRUE)
                    /* fuzzymatch() doesn't match leading substrings but
                       this allows "apply_key" and "applykey" to match
                       "apply-key"; "apply key" too if part of foo+bar */
                    || fuzzymatch(op, unlocktypes[i][0], " -_", TRUE)) {
                    matched = TRUE;
                    switch (*op) {
                    case 'u':
                        newflags |= AUTOUNLOCK_UNTRAP;
                        break;
                    case 'a':
                        newflags |= AUTOUNLOCK_APPLY_KEY;
                        break;
                    case 'k':
                        newflags |= AUTOUNLOCK_KICK;
                        break;
                    case 'f':
                        newflags |= AUTOUNLOCK_FORCE;
                        break;
                    default:
                        matched = FALSE;
                        break;
                    }
                }
            }
            if (!matched) {
                config_error_add("Invalid value for \"%s\": \"%s\"",
                                 allopt[optidx].name, op);
                return optn_silenterr;
            }
            op = nxt;
        }
        if (negated && newflags != 0) {
            config_error_add(
                     "Invalid value combination for \"%s\": 'none' with some",
                             allopt[optidx].name);
            return optn_silenterr;
        }
        flags.autounlock = newflags;
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        if (!flags.autounlock) {
            Strcpy(opts, "none");
        } else {
            static const char plus[] = " + ";
            const char *p = "";

            *opts = '\0';
            if (flags.autounlock & AUTOUNLOCK_UNTRAP)
                Sprintf(eos(opts), "%s%s", p, unlocktypes[0][0]), p = plus;
            if (flags.autounlock & AUTOUNLOCK_APPLY_KEY)
                Sprintf(eos(opts), "%s%s", p, unlocktypes[1][0]), p = plus;
            if (flags.autounlock & AUTOUNLOCK_KICK)
                Sprintf(eos(opts), "%s%s", p, unlocktypes[2][0]), p = plus;
            if (flags.autounlock & AUTOUNLOCK_FORCE)
                Sprintf(eos(opts), "%s%s", p, unlocktypes[3][0]); /*no more p*/
        }
        return optn_ok;
    }
    if (req == do_handler) {
        return handler_autounlock(optidx);
    }
    return optn_ok;
}

staticfn int
optfn_boulder(
    int optidx UNUSED, int req, boolean negated UNUSED,
    char *opts, char *op UNUSED)
{
#ifdef BACKWARD_COMPAT
    int clash = 0;
#endif

    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* boulder:symbol */

#ifdef BACKWARD_COMPAT

        /* if ((opts = string_for_env_opt(allopt[optidx].name, opts, FALSE))
               == empty_optstr)
         */
        if ((opts = string_for_opt(opts, FALSE)) == empty_optstr)
            return FALSE;
        escapes(opts, opts);
        /* note: dummy monclass #0 has symbol value '\0'; we allow that--
           attempting to set bouldersym to '^@'/'\0' will reset to default */
        if (def_char_to_monclass(opts[0]) != MAXMCLASSES)
            clash = opts[0] ? 1 : 0;
        else if (opts[0] >= '1' && opts[0] < WARNCOUNT + '0')
            clash = 2;
        if (opts[0] < ' ') {
            config_error_add("boulder symbol cannot be a control character");
            return optn_ok;
        } else if (clash) {
            /* symbol chosen matches a used monster or warning
               symbol which is not good - reject it */
            config_error_add("Badoption - boulder symbol '%s' would conflict "
                             "with a %s symbol",
                             visctrl(opts[0]),
                             (clash == 1) ? "monster" : "warning");
        } else {
            /*
             * Override the default boulder symbol.
             */
            go.ov_primary_syms[SYM_BOULDER + SYM_OFF_X] = (nhsym) opts[0];
            go.ov_rogue_syms[SYM_BOULDER + SYM_OFF_X] = (nhsym) opts[0];
            /* for 'initial', update of BOULDER symbol is done in
               initoptions_finish(), after all symset options
               have been processed */
            if (!go.opt_initial) {
                nhsym sym = get_othersym(SYM_BOULDER,
                                         Is_rogue_level(&u.uz) ? ROGUESET
                                                               : PRIMARYSET);

                if (sym)
                    gs.showsyms[SYM_BOULDER + SYM_OFF_X] = sym;
                go.opt_need_redraw = TRUE;
            }
        }
        return optn_ok;
#else
        config_error_add("'%s' no longer supported; use S_boulder:c instead",
                         allopt[optidx].name);
        return optn_err;
#endif
    }
    if (req == get_val || req == get_cnf_val) {
        opts[0] = '\0';
#ifdef BACKWARD_COMPAT
        Sprintf(opts, "%c",
                go.ov_primary_syms[SYM_BOULDER + SYM_OFF_X]
                  ? go.ov_primary_syms[SYM_BOULDER + SYM_OFF_X]
                  : gs.showsyms[(int) objects[BOULDER].oc_class + SYM_OFF_O]);
#endif
        return optn_ok;
    }
    return optn_ok;
}

staticfn int
optfn_catname(
    int optidx, int req,
    boolean negated,
    char *opts, char *op)
{
    return petname_optfn(optidx, req, negated, opts, op);
}

#ifdef CRASHREPORT
staticfn int
optfn_crash_email(
    int optidx UNUSED, int req, boolean negated UNUSED,
    char *opts, char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        if ((op = string_for_opt(opts, FALSE)) == empty_optstr)
            return optn_err;
        if (gc.crash_email)
            free((genericptr_t) gc.crash_email);
        gc.crash_email = dupstr(op);
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        if (!opts)
            return optn_err;
        if (gc.crash_email)
            Sprintf(opts, "%s", gc.crash_email);
        return optn_ok;
    }
    return optn_ok;
}

staticfn int
optfn_crash_name(
    int optidx UNUSED, int req, boolean negated UNUSED,
    char *opts, char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        if ((op = string_for_opt(opts, FALSE)) == empty_optstr)
            return optn_err;
        if (gc.crash_name)
            free((genericptr_t) gc.crash_name);
        gc.crash_name = dupstr(op);
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        if (!opts)
            return optn_err;
        if (gc.crash_name)
            Sprintf(opts, "%s", gc.crash_name);
        return optn_ok;
    }
    return optn_ok;
}

staticfn int
optfn_crash_urlmax(
    int optidx UNUSED, int req, boolean negated UNUSED,
    char *opts, char *op)
{
    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        if ((op = string_for_opt(opts, FALSE)) != empty_optstr) {
            int temp = atoi(op);

            if (temp < 75){
                config_error_add("Invalid value %d for crash_urlmax. "
                                 " Minimum value is 75.", temp);
                return optn_err;
            }
            gc.crash_urlmax = temp;
        } else
            return optn_err;
        return optn_ok;
    }
    if (req == get_val || req == get_cnf_val) {
        if (!opts)
            return optn_err;
        Sprintf(opts, "%d", gc.crash_urlmax);
        return optn_ok;
    }
    return optn_ok;
}

#endif /* CRASHREPORT */

#ifdef CURSES_GRAPHICS
staticfn int
optfn_cursesgraphics(
    int optidx, int req, boolean negated,
    char *opts, char *op UNUSED)
{
#ifdef BACKWARD_COMPAT
    boolean badflag = FALSE;
#endif

    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* "cursesgraphics" */

#ifdef BACKWARD_COMPAT
        if (!negated) {
            /* There is no rogue level cursesgraphics-specific set */
            if (gs.symset[PRIMARYSET].name) {
                badflag = TRUE;
            } else {
                gs.symset[PRIMARYSET].name = dupstr(allopt[optidx].name);
                if (!read_sym_file(PRIMARYSET)) {
                    badflag = TRUE;
                    clear_symsetentry(PRIMARYSET, TRUE);
                } else
                    switch_symbols(TRUE);
            }
            if (badflag) {
                config_error_add("Failure to load symbol set %s.",
                                 allopt[optidx].name);
                return optn_err;
            }
        }
        return optn_ok;
#else
        config_error_add("'%s' no longer supported; use 'symset:%s' instead",
                         allopt[optidx].name, allopt[optidx].name);
        return optn_err;
#endif
    }
    if (req == get_val || req == get_cnf_val) {
        opts[0] = '\0';
        return optn_ok;
    }
    return optn_ok;
}
#endif

staticfn int
optfn_DECgraphics(
    int optidx, int req, boolean negated,
    char *opts, char *op UNUSED)
{
#ifdef BACKWARD_COMPAT
    boolean badflag = FALSE;
#endif

    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* "DECgraphics" */

#ifdef BACKWARD_COMPAT
        if (!negated) {
            /* There is no rogue level DECgraphics-specific set */
            if (gs.symset[PRIMARYSET].name) {
                badflag = TRUE;
            } else {
                gs.symset[PRIMARYSET].name = dupstr(allopt[optidx].name);
                if (!read_sym_file(PRIMARYSET)) {
                    badflag = TRUE;
                    clear_symsetentry(PRIMARYSET, TRUE);
                } else
                    switch_symbols(TRUE);
            }
            if (badflag) {
                config_error_add("Failure to load symbol set %s.",
                                 allopt[optidx].name);
                return optn_err;
            }
        }
        return optn_ok;
#else
        config_error_add("'%s' no longer supported; use 'symset:%s' instead",
                         allopt[optidx].name, allopt[optidx].name);
        return optn_err;
#endif
    }
    if (req == get_val || req == get_cnf_val) {
        opts[0] = '\0';
        return optn_ok;
    }
    return optn_ok;
}

staticfn int
optfn_disclose(
    int optidx, int req, boolean negated,
    char *opts, char *op)
{
    int i, idx, prefix_val;
    unsigned num;

    if (req == do_init) {
        return optn_ok;
    }
    if (req == do_set) {
        /* things to disclose at end of game */

        /*
         * The order that the end_disclose options are stored:
         *      inventory, attribs, vanquished, genocided,
         *      conduct, overview.
         * There is an array in flags:
         *      end_disclose[NUM_DISCLOSURE_OPT];
         * with option settings for the each of the following:
         * iagvc [see disclosure_options in decl.c]:
         * Allowed setting values in that array are:
         *      DISCLOSE_PROMPT_DEFAULT_YES  ask with default answer yes
         *      DISCLOSE_PROMPT_DEFAULT_NO   ask with default answer no
         *      DISCLOSE_YES_WITHOUT_PROMPT  always disclose and don't ask
         *      DISCLOSE_NO_WITHOUT_PROMPT   never disclose and don't ask
         *      DISCLOSE_PROMPT_DEFAULT_SPECIAL  for 'vanq'/'genod' only...
         *      DISCLOSE_SPECIAL_WITHOUT_PROMPT  ...to set up sort order.
         *
         * Those setting values can be used in the option
         * string as a prefix to get the desired behavior.
         *
         * For backward compatibility, no prefix is required,
         * and the presence of a i,a,g,v, or c without a prefix
         * sets the corresponding value to DISCLOSE_YES_WITHOUT_PROMPT.
         * This code was last updated for 3.6.0; further changes
         * to genod or vanquished settings will need update here.
         */
        op = string_for_opt(opts, TRUE);
        if (op != empty_optstr && negated) {
            bad_negation(allopt[optidx].name, TRUE);
            return optn_err;
        }
        /* "disclose" without a value means "all with prompting"
           and negated means "none without prompting" */
        if (op == empty_optstr || !strcmpi(op, "all")
            || !strcmpi(op, "none")) {
            if (op != empty_optstr && !strcmpi(op, "none"))
                negated = TRUE;
            for (num = 0; num < NUM_DISCLOSURE_OPTIONS; num++)
                flags.end_disclose[num] = negated
                                              ? DISCLOSE_NO_WITHOUT_PROMPT
                                              : DISCLOSE_PROMPT_DEFAULT_YES;
            return optn_ok;
        }

        num = 0;
        prefix_val = -1;
        while (*op && num < sizeof flags.end_disclose - 1) {
            static char valid_settings[] = { DISCLOSE_PROMPT_DEFAULT_YES,
                                             DISCLOSE_PROMPT_DEFAULT_NO,
                                             DISCLOSE_PROMPT_DEFAULT_SPECIAL,
                                             DISCLOSE_YES_WITHOUT_PROMPT,
                                             DISCLOSE_NO_WITHOUT_PROMPT,
                                             DISCLOSE_SPECIAL_WITHOUT_PROMPT,
                                             '\0' };
            char c;
            const char *dop;

            c = lowc(*op);
            if (c == 'k')
                c = 'v'; /* killed -> vanquished */
            if (c == 'd')
                c = 'o'; /* dungeon -> overview */
            dop = strchr(disclosure_options, c);
            if (dop) {
                idx = (int) (dop - disclosure_options);
                if (idx < 0 || idx > NUM_DISCLOSURE_OPTIONS - 1) {
                    impossible("bad disclosure index %d %c", idx, c);
                    continue;
                }
                if (prefix_val != -1) {
                    if (*dop != 'v' && *dop != 'g') {
                        if (prefix_val == DISCLOSE_PROMPT_DEFAULT_SPECIAL)
                            prefix_val = DISCLOSE_PROMPT_DEFAULT_YES;
                        if (prefix_val == DISCLOSE_SPECIAL_WITHOUT_PROMPT)
                            prefix_val = DISCLOSE_YES_WITHOUT_PROMPT;
                    }
                    flags.end_disclose[idx] = prefix_val;
                    prefix_val = -1;
                } else
                    flags.end_disclose[idx] = DISCLOSE_YES_WITHOUT_PROMPT;
            } else if (strchr(valid_settings, c)) {
                prefix_val = c;
            } else if (c == ' ') {
                ; /* do nothing */
            } else {
                config_error_add("Unknown %s parameter '%c'",
                                 allopt[optidx].name, *op);
                return optn_err;
            }
            op++;
        }
        /* finish off final line; value might be empty if one or more cond_xyz
           options were changed in such a manner that they're all back to their
           default values--which will produce "OPTIONS=" with nothing after the
           equals sign; only add to the output when there is more present */
        if (strcmp(buf, "OPTIONS=")) {
            Strcat(buf, "\n");
            strbuf_append(sbuf, buf);
        }
    }
}

/* append menucolor lines to strbuf */
staticfn void
all_options_menucolors(strbuf_t *sbuf)
{
    int i = 0, ncolors = count_menucolors();
    struct menucoloring *tmp = gm.menu_colorings;
    char buf[BUFSZ*2]; /* see also: add_menu_coloring() */
    struct menucoloring **arr;

    if (!ncolors)
        return;

    /* reverse the order */
    arr = (struct menucoloring **) alloc(ncolors * sizeof *arr);
    while (tmp) {
        arr[i++] = tmp;
        tmp = tmp->next;
    }

    for (i = ncolors; i > 0; i--) {
        tmp = arr[i-1];
        const char *sattr = attr2attrname(tmp->attr);
        const char *sclr = clr2colorname(tmp->color);
        Sprintf(buf, "MENUCOLOR=\"%s\"=%s%s%s\n",
                tmp->origstr,
                sclr,
                (tmp->attr != ATR_NONE) ? "&" : "",
                (tmp->attr != ATR_NONE) ? sattr : "");
        strbuf_append(sbuf, buf);
    }

    free(arr);
}

staticfn void
all_options_msgtypes(strbuf_t *sbuf)
{
    struct plinemsg_type *tmp = gp.plinemsg_types;
    char buf[BUFSZ];

    while (tmp) {
        const char *mtype = msgtype2name(tmp->msgtype);
        Sprintf(buf, "MSGTYPE=%s \"%s\"\n",
                mtype, tmp->pattern);
        strbuf_append(sbuf, buf);
        tmp = tmp->next;
    }
}

staticfn void
all_options_apes(strbuf_t *sbuf)
{
    struct autopickup_exception *tmp = ga.apelist;
    char buf[BUFSZ];

    while (tmp) {
        Sprintf(buf, "autopickup_exception=\"%c%s\"\n",
                tmp->grab ? '<' : '>', tmp->pattern);
        strbuf_append(sbuf, buf);
        tmp = tmp->next;
    }
}

#ifdef CHANGE_COLOR
staticfn void
all_options_palette(strbuf_t *sbuf)
{
    int clr, n = count_alt_palette();
    char buf[BUFSZ];

    if (!n)
        return;

    for (clr = 0; clr < CLR_MAX; ++clr) {
        if (ga.altpalette[clr] != 0U) {
            Sprintf(buf, "OPTIONS=palette:%s/#%06x\n",
                    clr2colorname(clr), COLORVAL(ga.altpalette[clr]));
            strbuf_append(sbuf, buf);
        }
    }
}
#endif /* CHANGE_COLOR */

/* return strbuf of all options, to write to file */
void
all_options_strbuf(strbuf_t *sbuf)
{
    const char *name;
    char tmp[BUFSZ];
    char *buf2;
    boolean *bool_p;
    int i;

    strbuf_init(sbuf);
    Sprintf(tmp, "# NetHack config, saved %s\n#\n",
            yyyymmddhhmmss((time_t) 0));
    strbuf_append(sbuf, tmp);

    for (i = 0; (name = allopt[i].name) != 0; i++) {
        if (!opt_set_in_config[i])
            continue;
        switch (allopt[i].opttyp) {
        case BoolOpt:
            bool_p = allopt[i].addr;
            if (!bool_p || bool_p == &flags.female)
                break; /* obsolete */
            if (*bool_p != allopt[i].initval) {
                Sprintf(tmp, "OPTIONS=%s%s\n", *bool_p ? "" : "!", name);
                strbuf_append(sbuf, tmp);
            }
            break;
        case CompOpt:
            if (!(allopt[i].setwhere == set_in_config
                  || allopt[i].setwhere == set_gameview
                  || allopt[i].setwhere == set_in_game))
                break;
            /* FIXME: get_option_value for:
               - menu_deselect_all &c menu control keys,
               - term_cols, term_rows */
            buf2 = get_option_value(name, TRUE);
            if (buf2) {
                Snprintf(tmp, sizeof tmp - 1, "OPTIONS=%s:%s", name, buf2);
                Strcat(tmp, "\n"); /* guaranteed to fit */
                strbuf_append(sbuf, tmp);
            }
            break;
        case OthrOpt:
            break;
        }
    }

    /* cond_xyz are closer to regular options than the other 'other opts'
       so put them next; [pfx_cond_] will be set if any cond_Foo were
       present when RC file was read in or if player made any changes via
       status conditions menu; ignore opt_set_in_config[opt_o_status_cond] */
    if (opt_set_in_config[pfx_cond_])
        all_options_conds(sbuf);

#ifdef CHANGE_COLOR
    all_options_palette(sbuf);
#endif
    get_changed_key_binds(sbuf);
    savedsym_strbuf(sbuf);
    all_options_menucolors(sbuf);
    all_options_msgtypes(sbuf);
    all_options_apes(sbuf);
    all_options_autocomplete(sbuf);
#ifdef STATUS_HILITES
    all_options_statushilites(sbuf);
#endif

    if (gw.wizkit[0]) {
        Sprintf(tmp, "WIZKIT=%s\n", gw.wizkit);
        strbuf_append(sbuf, tmp);
    }
}

/*
 * prints the next boolean option, on the same line if possible, on a new
 * line if not. End with next_opt("").
 */
void
next_opt(winid datawin, const char *str)
{
    static char *buf = 0;
    int i;
    char *s;

    if (!buf)
        *(buf = (char *) alloc(COLBUFSZ)) = '\0';

    if (!*str) {
        s = eos(buf);
        if (s > &buf[1] && s[-2] == ',')
            s[-2] = '.', s[-1] = '\0'; /* replace ending ", " with "." */
        i = COLNO;              /* (greater than COLNO - 2) */
    } else {
        i = Strlen(buf) + Strlen(str) + 2;
    }

    if (i > COLNO - 2) { /* rule of thumb */
        putstr(datawin, 0, buf);
        buf[0] = 0;
    }
    if (*str) {
        Strcat(buf, str);
        Strcat(buf, ", ");
    } else {
        putstr(datawin, 0, str);
        free((genericptr_t) buf), buf = 0;
    }
    return;
}

static struct wc_Opt wc_options[] = {
    { "ascii_map", WC_ASCII_MAP },
    { "color", WC_COLOR },
    { "eight_bit_tty", WC_EIGHT_BIT_IN },
    { "hilite_pet", WC_HILITE_PET },
    { "perm_invent", WC_PERM_INVENT },
    { "perminv_mode", WC_PERM_INVENT }, /* shares WC_PERM_INVENT */
    { "popup_dialog", WC_POPUP_DIALOG },
    { "player_selection", WC_PLAYER_SELECTION },
    { "preload_tiles", WC_PRELOAD_TILES },
    { "tiled_map", WC_TILED_MAP },
    { "tile_file", WC_TILE_FILE },
    { "tile_width", WC_TILE_WIDTH },
    { "tile_height", WC_TILE_HEIGHT },
    { "align_message", WC_ALIGN_MESSAGE },
    { "align_status", WC_ALIGN_STATUS },
    { "font_map", WC_FONT_MAP },
    { "font_menu", WC_FONT_MENU },
    { "font_message", WC_FONT_MESSAGE },
    { "font_size_map", WC_FONTSIZ_MAP },
    { "font_size_menu", WC_FONTSIZ_MENU },
    { "font_size_message", WC_FONTSIZ_MESSAGE },
    { "font_size_status", WC_FONTSIZ_STATUS },
    { "font_size_text", WC_FONTSIZ_TEXT },
    { "font_status", WC_FONT_STATUS },
    { "font_text", WC_FONT_TEXT },
    { "map_mode", WC_MAP_MODE },
    { "scroll_amount", WC_SCROLL_AMOUNT },
    { "scroll_margin", WC_SCROLL_MARGIN },
    { "splash_screen", WC_SPLASH_SCREEN },
    { "use_inverse", WC_INVERSE },
    { "vary_msgcount", WC_VARY_MSGCOUNT },
    { "windowcolors", WC_WINDOWCOLORS },
    { "mouse_support", WC_MOUSE_SUPPORT },
    { (char *) 0, 0L }
};
static struct wc_Opt wc2_options[] = {
    { "armorstatus", WC2_EXTRASTATUS },
    { "fullscreen", WC2_FULLSCREEN },
    { "guicolor", WC2_GUICOLOR },
    { "hilite_status", WC2_HILITE_STATUS },
    { "hitpointbar", WC2_HITPOINTBAR },
    { "menu_shift", WC2_MENU_SHIFT },
    { "petattr", WC2_PETATTR },
    { "softkeyboard", WC2_SOFTKEYBOARD },
    /* name shown in 'O' menu is different */
    { "status hilite rules", WC2_HILITE_STATUS },
    /* statushilites doesn't have its own bit */
    { "statushilites", WC2_HILITE_STATUS },
    { "statuslines", WC2_STATUSLINES },
    { "term_cols", WC2_TERM_SIZE },
    { "term_rows", WC2_TERM_SIZE },
    { "terrainstatus", WC2_EXTRASTATUS },
    { "use_darkgray", WC2_DARKGRAY },
    { "weaponstatus", WC2_EXTRASTATUS },
    { "windowborders", WC2_WINDOWBORDERS },
    { "wraptext", WC2_WRAPTEXT },
    { (char *) 0, 0L }
};

/*
 * If a port wants to change or ensure that the set_in_sysconf,
 * set_in_config, set_gameview, or set_in_game status of an option is
 * correct (for controlling its display in the option menu) call
 * set_option_mod_status()
 * with the appropriate second argument.
 */
void
set_option_mod_status(const char *optnam, int status)
{
    int k;

    if (SET__IS_VALUE_VALID(status)) {
        impossible("set_option_mod_status: status out of range %d.", status);
        return;
    }
    for (k = 0; allopt[k].name; k++) {
        if (str_start_is(allopt[k].name, optnam, TRUE)) {
            allopt[k].setwhere = status;
            return;
        }
    }
}

void
set_wc_option_mod_status(unsigned long optmask, int status)
{
    int k = 0;

    if (SET__IS_VALUE_VALID(status)) {
        impossible("set_wc_option_mod_status: status out of range %d.",
                   status);
        return;
    }
    while (wc_options[k].wc_name) {
        if (optmask & wc_options[k].wc_bit) {
            set_option_mod_status(wc_options[k].wc_name, status);
        }
        k++;
    }
}

staticfn boolean
is_wc_option(const char *optnam)
{
    int k = 0;

    while (wc_options[k].wc_name) {
        if (strcmp(wc_options[k].wc_name, optnam) == 0)
            return TRUE;
        k++;
    }
    return FALSE;
}

staticfn boolean
wc_supported(const char *optnam)
{
    int k;

    for (k = 0; wc_options[k].wc_name; ++k) {
        if (!strcmp(wc_options[k].wc_name, optnam))
            return (windowprocs.wincap & wc_options[k].wc_bit) ? TRUE : FALSE;
    }
    return FALSE;
}

staticfn boolean
is_wc2_option(const char *optnam)
{
    int k = 0;

    while (wc2_options[k].wc_name) {
        if (strcmp(wc2_options[k].wc_name, optnam) == 0)
            return TRUE;
        k++;
    }
    return FALSE;
}

staticfn boolean
wc2_supported(const char *optnam)
{
    int k;

    for (k = 0; wc2_options[k].wc_name; ++k) {
        if (!strcmp(wc2_options[k].wc_name, optnam))
            return (windowprocs.wincap2 & wc2_options[k].wc_bit) ? TRUE
                                                                 : FALSE;
    }
    return FALSE;
}

staticfn void
wc_set_font_name(int opttype, char *fontname)
{
    char **fn = (char **) 0;

    if (!fontname)
        return;
    switch (opttype) {
    case MAP_OPTION:
        fn = &iflags.wc_font_map;
        break;
    case MESSAGE_OPTION:
        fn = &iflags.wc_font_message;
        break;
    case TEXT_OPTION:
        fn = &iflags.wc_font_text;
        break;
    case MENU_OPTION:
        fn = &iflags.wc_font_menu;
        break;
    case STATUS_OPTION:
        fn = &iflags.wc_font_status;
        break;
    default:
        return;
    }
    if (fn) {
        if (*fn)
            free((genericptr_t) *fn);
        *fn = dupstr(fontname);
    }
    return;
}

static char **fgp[] = { &iflags.wcolors[wcolor_menu].fg,
                        &iflags.wcolors[wcolor_message].fg,
                        &iflags.wcolors[wcolor_status].fg,
                        &iflags.wcolors[wcolor_text].fg };
static char **bgp[] = { &iflags.wcolors[wcolor_menu].bg,
                        &iflags.wcolors[wcolor_message].bg,
                        &iflags.wcolors[wcolor_status].bg,
                        &iflags.wcolors[wcolor_text].bg };
int options_set_window_colors_flag = 0;

staticfn int
wc_set_window_colors(char *op)
{
    /* syntax:
     *  menu white/black message green/yellow status white/blue text
     * white/black
     */

    int j;
    int32 clr;
    char buf[BUFSZ];
    char *wn, *tfg, *tbg, *newop;

    Strcpy(buf, op);
    newop = mungspaces(buf);
    while (*newop) {
        wn = tfg = tbg = (char *) 0;

        /* until first non-space in case there's leading spaces - before
           colorname*/
        if (*newop == ' ')
            newop++;
        if (!*newop)
            return 0;
        wn = newop;

        /* until first space - colorname*/
        while (*newop && *newop != ' ')
            newop++;
        if (!*newop)
            return 0;
        *newop++ = '\0';

        /* until first non-space - before foreground*/
        if (*newop == ' ')
            newop++;
        if (!*newop)
            return 0;
        tfg = newop;

        /* until slash - foreground */
        while (*newop && *newop != '/')
            newop++;
        if (!*newop)
            return 0;
        *newop++ = '\0';

        /* until first non-space (in case there's leading space after slash) -
         * before background */
        if (*newop == ' ')
            newop++;
        if (!*newop)
            return 0;
        tbg = newop;

        /* until first space - background */
        while (*newop && *newop != ' ')
            newop++;
        if (*newop)
            *newop++ = '\0';

        for (j = 0; j < WC_COUNT; ++j) {
            if (!strcmpi(wn, wcnames[j]) || !strcmpi(wn, wcshortnames[j])) {
                if (!strstri(tfg, " ")) {
                    if (*fgp[j])
                        free((genericptr_t) *fgp[j]);
                    clr = check_enhanced_colors(tfg);
                    *fgp[j] = dupstr((clr >= 0) ? wc_color_name(clr) : tfg);
                }
                if (!strstri(tbg, " ")) {
                    if (*bgp[j])
                        free((genericptr_t) *bgp[j]);
                    clr = check_enhanced_colors(tbg);
                    *bgp[j] = dupstr((clr >= 0) ? wc_color_name(clr) : tbg);
                }
                if (wcolors_opt[j] != 0) {
                    config_error_add(
                       "windowcolors for %s windows specified multiple times",
                                     wcnames[j]);
                }
                wcolors_opt[j]++;
                break;
            }
        }
        if (j == WC_COUNT) {
            config_error_add("windowcolors for unrecognized window type: %s",
                             wn);
        }
    }
    options_set_window_colors_flag = 1;
    return 1;
}

void
options_free_window_colors(void)
{
    int j;

    for (j = 0; j < WC_COUNT; ++j) {
        if (*fgp[j])
            free((genericptr_t) *fgp[j]), *fgp[j] = 0;
        if (*bgp[j])
            free((genericptr_t) *bgp[j]), *bgp[j] = 0;
    }
    options_set_window_colors_flag = 0;
}

/* set up for wizard mode if player or save file has requested it;
   called from port-specific startup code to handle `nethack -D' or
   OPTIONS=playmode:debug, or from dorecover()'s restgamestate() if
   restoring a game which was saved in wizard mode */
void
set_playmode(void)
{
    if (wizard) {
        if (authorize_wizard_mode())
            gp.plnamelen = (int) strlen(strcpy(svp.plname, "wizard"));
        else
            wizard = FALSE; /* not allowed or not available */
        /* try explore mode if we didn't make it into wizard mode */
        /* if requesting wizard mode when restoring a normal game, this will
           set iflags.deferred_X and prompt to activate explore mode after the
           save file has already been deleted */
        discover = !wizard;
        iflags.deferred_X = FALSE;
    }
    if (discover && !authorize_explore_mode()) {
        discover = iflags.deferred_X = FALSE;
    }
    /* don't need to do anything special for normal play */
}

staticfn void
enhance_menu_text(
    char *buf,
    size_t sz,
    int whichpass UNUSED,
    boolean *bool_p,
    struct allopt_t *thisopt)
{
    size_t nowsz, availsz;

    if (!buf)
        return;
    nowsz = strlen(buf) + 1;
    availsz = sz - nowsz;

#if 0 /*#ifdef TTY_PERM_INVENT*/
    if (bool_p == &iflags.perm_invent && WINDOWPORT(tty)) {
        if (thisopt->setwhere == set_gameview)
            Snprintf(eos(buf), availsz, " *terminal size is too small");
    }
#else
    nhUse(availsz);
    nhUse(bool_p);
    nhUse(thisopt);
#endif
    return;
}

void
heed_all_options(void)
{
    int i;

    for (i = 0; i < OPTCOUNT; i++)
        allopt[i].disregarded = FALSE;
}

void
disregard_all_options(void)
{
    int i;

    for (i = 0; i < OPTCOUNT ; i++)
        allopt[i].disregarded = TRUE;
}

void
heed_this_option(enum opt optidx)
{
    if (optidx >= 0 && optidx < (enum opt) OPTCOUNT)
         allopt[optidx].disregarded = FALSE;
}
void
disregard_this_option(enum opt optidx)
{
    if (optidx >= 0 && optidx < (enum opt) OPTCOUNT)
        allopt[optidx].disregarded = TRUE;
}



#undef OPTIONS_HEADING
#undef CONFIG_SLOT

#endif /* OPTION_LISTS_ONLY */

#undef BACKWARD_COMPAT
#undef COMPLAIN_ABOUT_PRAYCONFIRM
#undef PREV_MSGS
#undef PILE_LIMIT_DFLT

/*options.c*/
