/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-25. */
/* NetHack 5.0	do_name.c	$NHDT-Date: 1781973046 2026/06/20 16:30:46 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.339 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Pasi Kallinen, 2018. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"

staticfn char *nextmbuf(void);
staticfn char *name_from_player(char *, const char *, const char *);
staticfn void do_mgivenname(void);
staticfn boolean alreadynamed(struct monst *, char *, char *) NONNULLPTRS;
staticfn void do_oname(struct obj *) NONNULLARG1;
staticfn const char *docall_target_name(struct obj *, char *, size_t) NONNULLPTRS;
staticfn void build_docall_prompt(char *, size_t, struct obj *) NONNULLPTRS;
staticfn void namefloorobj(void);
staticfn const char *jp_default_dog_name_for_display(struct monst *, const char *);
staticfn const char *jp_bogusmon_for_display(const char *);

#define NUMMBUF 5

/* manage a pool of BUFSZ buffers, so callers don't have to */
staticfn char *
nextmbuf(void)
{
    static char NEARDATA bufs[NUMMBUF][BUFSZ];
    static int bufidx = 0;

    bufidx = (bufidx + 1) % NUMMBUF;
    return bufs[bufidx];
}

/* allocate space for a monster's name; removes old name if there is one */
void
new_mgivenname(
    struct monst *mon,
    int lth) /* desired length (caller handles adding 1 for terminator) */
{
    if (lth) {
        /* allocate mextra if necessary; otherwise get rid of old name */
        if (!mon->mextra)
            mon->mextra = newmextra();
        else
            free_mgivenname(mon); /* has mextra, might also have name */
        MGIVENNAME(mon) = (char *) alloc((unsigned) lth);
    } else {
        /* zero length: the new name is empty; get rid of the old name */
        if (has_mgivenname(mon))
            free_mgivenname(mon);
    }
}

/* release a monster's name; retains mextra even if all fields are now null */
void
free_mgivenname(struct monst *mon)
{
    if (has_mgivenname(mon)) {
        free((genericptr_t) MGIVENNAME(mon));
        MGIVENNAME(mon) = (char *) 0;
    }
}

/* allocate space for an object's name; removes old name if there is one */
void
new_oname(
    struct obj *obj,
    int lth) /* desired length (caller handles adding 1 for terminator) */
{
    if (lth) {
        /* allocate oextra if necessary; otherwise get rid of old name */
        if (!obj->oextra)
            obj->oextra = newoextra();
        else
            free_oname(obj); /* already has oextra, might also have name */
        ONAME(obj) = (char *) alloc((unsigned) lth);
    } else {
        /* zero length: the new name is empty; get rid of the old name */
        if (has_oname(obj))
            free_oname(obj);
    }
}

/* release an object's name; retains oextra even if all fields are now null */
void
free_oname(struct obj *obj)
{
    if (has_oname(obj)) {
        free((genericptr_t) ONAME(obj));
        ONAME(obj) = (char *) 0;
    }
}

/*  safe_oname() always returns a valid pointer to
 *  a string, either the pointer to an object's name
 *  if it has one, or a pointer to an empty string
 *  if it doesn't.
 */
const char *
safe_oname(struct obj *obj)
{
    if (has_oname(obj))
        return ONAME(obj);
    return "";
}

/* get a name for a monster or an object from player;
   truncate if longer than PL_PSIZ, then return it */
staticfn char *
name_from_player(
    char *outbuf,       /* output buffer, assumed to be at least BUFSZ long;
                         * anything longer than PL_PSIZ will be truncated */
    const char *prompt,
    const char *defres) /* only used if EDIT_GETLIN is enabled; only useful
                         * if windowport xxx's xxx_getlin() supports that */
{
    outbuf[0] = '\0';
#ifdef EDIT_GETLIN
    if (defres && *defres)
        Strcpy(outbuf, defres); /* default response from getlin() */
#else
    nhUse(defres);
#endif
    getlin(prompt, outbuf);
    if (!*outbuf || *outbuf == '\033')
        return NULL;

    /* strip leading and trailing spaces, condense internal sequences */
    (void) mungspaces(outbuf);
    utf8_truncate(outbuf, PL_PSIZ - 1);
    return outbuf;
}

/* historical note: this returns a monster pointer because it used to
   allocate a new bigger block of memory to hold the monster and its name */
struct monst *
christen_monst(struct monst *mtmp, const char *name)
{
    int lth;
    char buf[PL_PSIZ];

    /* dogname & catname are PL_PSIZ arrays; object names have same limit */
    lth = 0;
    if (name && *name) {
        copynchars(buf, name, PL_PSIZ - 1);
        buf[PL_PSIZ - 1] = '\0';
        utf8_truncate(buf, PL_PSIZ - 1);
        name = buf;
        lth = (int) strlen(name) + 1;
    }
    new_mgivenname(mtmp, lth); /* removes old name if one is present */
    if (lth)
        Strcpy(MGIVENNAME(mtmp), name);
    /* if 'mtmp' is leashed, persistent inventory window needs updating */
    if (mtmp->mleashed)
        update_inventory(); /* x - leash (attached to Fido) */
    return mtmp;
}

/* check whether user-supplied name matches or nearly matches an unnameable
   monster's name, or is an attempt to delete the monster's name; if so, give
   alternate reject message for do_mgivenname() */
staticfn boolean
alreadynamed(struct monst *mtmp, char *monnambuf, char *usrbuf)
{
    char *p;

    if (!*usrbuf) { /* attempt to erase existing name */
        boolean name_not_title = (has_mgivenname(mtmp)
                                  || type_is_pname(mtmp->data)
                                  || mtmp->isshk);
        pline("%sは今の%sを変えたがらない.", upstart(monnambuf),
              name_not_title ? "名前" : "称号");
        return TRUE;
    } else if (fuzzymatch(usrbuf, monnambuf, " -_", TRUE)
               /* catch trying to name "the Oracle" as "Oracle" */
               || (!strncmpi(monnambuf, "the ", 4)
                   && fuzzymatch(usrbuf, monnambuf + 4, " -_", TRUE))
               /* catch trying to name "invisible Orcus" as "Orcus" */
               || ((p = strstri(monnambuf, "invisible ")) != 0
                   && fuzzymatch(usrbuf, p + 10, " -_", TRUE))
               /* catch trying to name "the priest of Crom" as "Crom" */
               || ((p = strstri(monnambuf, " of ")) != 0
                   && fuzzymatch(usrbuf, p + 4, " -_", TRUE))) {
        if (is_rider(mtmp->data)) {
            /* avoid gendered pronoun for riders */
            pline("%sはすでにそう呼ばれている.", upstart(monnambuf));
        } else {
            pline("%sはすでにその名前が付いている.", upstart(monnambuf));
        }
        return TRUE;
    } else if (mtmp->data == &mons[PM_JUIBLEX]
               && strstri(monnambuf, "Juiblex")
               && !strcmpi(usrbuf, "Jubilex")) {
        pline("%sは%sと呼ばれることを嫌がった.", upstart(monnambuf), usrbuf);
        return TRUE;
    }
    return FALSE;
}

/* allow player to assign a name to some chosen monster */
staticfn void
do_mgivenname(void)
{
    char buf[BUFSZ], monnambuf[BUFSZ], qbuf[QBUFSZ];
    coord cc;
    int cx, cy;
    struct monst *mtmp = 0;
    boolean do_swallow = FALSE;

    if (Hallucination) {
        You("どうせ見分けられないだろう.");
        return;
    }
    cc.x = u.ux;
    cc.y = u.uy;
    if (getpos(&cc, FALSE, "名前をつけたいモンスター") < 0
        || !isok(cc.x, cc.y))
        return;
    cx = cc.x, cy = cc.y;

    if (u_at(cx, cy)) {
        if (u.usteed && canspotmon(u.usteed)) {
            mtmp = u.usteed;
        } else {
            pline("この%s怪物の名は%sで、変えられない。",
                  beautiful(), svp.plname);
            return;
        }
    } else
        mtmp = m_at(cx, cy);

    /* Allow you to name the monster that has swallowed you */
    if (!mtmp && u.uswallow) {
        int glyph = glyph_at(cx, cy);

        if (glyph_is_swallow(glyph)) {
            mtmp = u.ustuck;
            do_swallow = TRUE;
        }
    }

    if (!do_swallow && (!mtmp
        || (!sensemon(mtmp)
            && (!(cansee(cx, cy) || see_with_infrared(mtmp))
                || mtmp->mundetected || M_AP_TYPE(mtmp) == M_AP_FURNITURE
                || M_AP_TYPE(mtmp) == M_AP_OBJECT
                || (mtmp->minvis && !See_invisible))))) {

        pline("そこにはモンスターがいない。");
        return;
    }
    /* special case similar to the one in lookat() */
    Sprintf(qbuf, "%sを何と呼びますか?",
            distant_monnam(mtmp, ARTICLE_THE, monnambuf));
    /* use getlin() to get a name string from the player */
    if (!name_from_player(buf, qbuf,
                          has_mgivenname(mtmp) ? MGIVENNAME(mtmp) : NULL))
        return;

    /* Unique monsters have their own specific names or titles.
     * Shopkeepers, temple priests and other minions use alternate
     * name formatting routines which ignore any user-supplied name.
     *
     * Don't say a new name is being rejected if it happens to match
     * the existing name, or if the player is trying to remove the
     * monster's existing name without assigning a new one.
     */
    if ((mtmp->data->geno & G_UNIQ) && !mtmp->ispriest) {
        if (!alreadynamed(mtmp, monnambuf, buf))
            pline("%sは名前を付けられるのを嫌がった!", upstart(monnambuf));
    } else if (mtmp->isshk
               && !(Deaf || helpless(mtmp)
                    || mtmp->data->msound <= MS_ANIMAL)) {
        if (!alreadynamed(mtmp, monnambuf, buf)) {
            SetVoice(mtmp, 0, 80, 0);
            verbalize("私は%s、%sではない。", jp_shkname_for_display(mtmp), buf);
        }
    } else if (mtmp->ispriest || mtmp->isminion || mtmp->isshk
               || mtmp->data == &mons[PM_GHOST] || has_ebones(mtmp)) {
        if (!alreadynamed(mtmp, monnambuf, buf))
            pline("%sは「%s」という名を受け入れなかった.", upstart(monnambuf), buf);
    } else {
        (void) christen_monst(mtmp, buf);
    }
}

/*
 * This routine used to change the address of 'obj' so be unsafe if not
 * used with extreme care.  Applying a name to an object no longer
 * allocates a replacement object, so that old risk is gone.
 */
staticfn void
do_oname(struct obj *obj)
{
    char *bufp, buf[BUFSZ], bufcpy[BUFSZ], qbuf[QBUFSZ];
    const char *aname;
    short objtyp = STRANGE_OBJECT;

    /* Do this now because there's no point in even asking for a name */
    if (obj->otyp == SPE_NOVEL) {
        pline("%sにはすでに正式な名前が付いている.", xname(obj));
        return;
    }

    Snprintf(qbuf, sizeof qbuf, "%s%sを何と名付けますか?",
             is_plural(obj) ? "これらの" : "この",
             simpleonames(obj));
    /* use getlin() to get a name string from the player */
    if (!name_from_player(buf, qbuf, safe_oname(obj)))
        return;

    /*
     * We don't violate illiteracy conduct here, although it is
     * arguable that we should for anything other than "X".  Doing so
     * would make attaching player's notes to hero's inventory have an
     * in-game effect, which may or may not be the correct thing to do.
     *
     * We do violate illiteracy in oname() if player creates Sting or
     * Orcrist, clearly being literate (no pun intended...).
     */

    if (obj->oartifact) {
        /* this used to give "The artifact seems to resist the attempt."
           but resisting is definite, no "seems to" about it */
          pline("%sは名付けを拒んだ.",
              /* any artifact should always pass the has_oname() test
                 but be careful just in case */
                  has_oname(obj) ? ONAME(obj) : "アーティファクト");
        return;
    }

    /* relax restrictions over proper capitalization for artifacts */
    if ((aname = artifact_name(buf, &objtyp, TRUE)) != 0
        && (restrict_name(obj, aname) || exist_artifact(obj->otyp, aname))) {
        /* substitute canonical spelling before slippage */
        Strcpy(buf, aname);
        /* this used to change one letter, substituting a value
           of 'a' through 'y' (due to an off by one error, 'z'
           would never be selected) and then force that to
           upper case if such was the case of the input;
           now, the hand slip scuffs one or two letters as if
           the text had been trodden upon, sometimes picking
           punctuation instead of an arbitrary letter;
           unfortunately, we have to cover the possibility of
           it targeting spaces so failing to make any change
           (we know that it must eventually target a nonspace
           because buf[] matches a valid artifact name) */
        Strcpy(bufcpy, buf);
        /* for "the Foo of Bar", only scuff "Foo of Bar" part */
        bufp = !strncmpi(buf, "the ", 4) ? (buf + 4) : buf;
        do {
            wipeout_text(bufp, rnd_on_display_rng(2), (unsigned) 0);
        } while (!strcmp(buf, bufcpy));
        pline("刻みつけている最中に%sが滑った。", jp_body_part(HAND));
        display_nhwindow(WIN_MESSAGE, FALSE);
        You("「%s」と刻みつけた。", buf);
        /* violate illiteracy conduct since hero attempted to write
           a valid artifact name */
        u.uconduct.literate++;
    } else if (obj->otyp == objtyp) {
        /* artifact_name() always returns non-Null when it sets objtyp */
        assert(aname != 0);

        /* artifact_name() found a match and restrict_name() didn't reject
           it; since 'obj' is the right type, naming will change it into an
           artifact so use canonical capitalization (Sting or Orcrist) */
        Strcpy(buf, aname);
    }

    obj = oname(obj, buf, ONAME_VIA_NAMING | ONAME_KNOW_ARTI);
    nhUse(obj);
}

struct obj *
oname(
    struct obj *obj,  /* item to assign name to */
    const char *name, /* name to assign */
    unsigned oflgs)   /* flags, mostly for artifact creation */
{
    int lth;
    char buf[PL_PSIZ];
    boolean via_naming = (oflgs & ONAME_VIA_NAMING) != 0,
            skip_inv_update = (oflgs & ONAME_SKIP_INVUPD) != 0;

    lth = 0;
    if (*name) {
        copynchars(buf, name, PL_PSIZ - 1);
        buf[PL_PSIZ - 1] = '\0';
        utf8_truncate(buf, PL_PSIZ - 1);
        name = buf;
        lth = (int) strlen(name) + 1;
    }
    /* If named artifact exists in the game, do not create another.
       Also trying to create an artifact shouldn't de-artifact
       it (e.g. Excalibur from prayer). In this case the object
       will retain its current name. */
    if (obj->oartifact || (lth && exist_artifact(obj->otyp, name)))
        return obj;

    new_oname(obj, lth); /* removes old name if one is present */
    if (lth)
        Strcpy(ONAME(obj), name);

    if (lth)
        artifact_exists(obj, name, TRUE, oflgs);
    if (obj->oartifact) {
        /* can't dual-wield with artifact as secondary weapon */
        if (obj == uswapwep)
            untwoweapon();
        /* activate warning if you've just named your weapon "Sting" */
        if (obj == uwep)
            set_artifact_intrinsic(obj, TRUE, W_WEP);
        /* if obj is owned by a shop, increase your bill */
        if (obj->unpaid)
            alter_cost(obj, 0L);
        if (via_naming) {
            /* violate illiteracy conduct since successfully wrote arti-name */
            if (!u.uconduct.literate++)
                livelog_printf(LL_CONDUCT | LL_ARTIFACT,
                               "%sと命名することで読み書きができるようになった",
                               bare_artifactname(obj));
            else
                livelog_printf(LL_ARTIFACT,
                               "%sの名前を\"%s\"に指定した",
                               ansimpleoname(obj), bare_artifactname(obj));
        }
    }
    if (carried(obj) && !skip_inv_update)
        update_inventory();
    return obj;
}

boolean
objtyp_is_callable(int i)
{
    if (objects[i].oc_uname)
        return TRUE;

    switch(objects[i].oc_class) {
    case AMULET_CLASS:
        /* 5.0: calling these used to be allowed but that enabled the
           player to tell whether two unID'd amulets of yendor were both
           fake or one was real by calling them distinct names and then
           checking discoveries to see whether first name was replaced
           by second or both names stuck; with more than two available
           to work with, if they weren't all fake it was possible to
           determine which one was the real one */
        if (i == AMULET_OF_YENDOR || i == FAKE_AMULET_OF_YENDOR)
            break; /* return FALSE */
        FALLTHROUGH;
        /*FALLTHRU*/
    case SCROLL_CLASS:
    case POTION_CLASS:
    case WAND_CLASS:
    case RING_CLASS:
    case GEM_CLASS:
    case SPBOOK_CLASS:
    case ARMOR_CLASS:
    case TOOL_CLASS:
    case VENOM_CLASS:
        if (OBJ_DESCR(objects[i]))
            return TRUE;
        break;
    default:
        break;
    }
    return FALSE;
}

/* getobj callback for object to name (specific item) - anything but gold */
int
name_ok(struct obj *obj)
{
    if (!obj || obj->oclass == COIN_CLASS)
        return GETOBJ_EXCLUDE;

    if (!obj->dknown || obj->oartifact || obj->otyp == SPE_NOVEL)
        return GETOBJ_DOWNPLAY;

    return GETOBJ_SUGGEST;
}

/* getobj callback for object to call (name its type) */
int
call_ok(struct obj *obj)
{
    if (!obj || !objtyp_is_callable(obj->otyp))
        return GETOBJ_EXCLUDE;

    /* not a likely candidate if not seen yet since naming will fail,
       or if it has been discovered and doesn't already have a name;
       when something has been named and then becomes discovered, it
       remains a likely candidate until player renames it to <space>
       to remove that no longer needed name */
    if (!obj->dknown || (objects[obj->otyp].oc_name_known
                         && !objects[obj->otyp].oc_uname))
        return GETOBJ_DOWNPLAY;

    return GETOBJ_SUGGEST;
}

/* #call / #name command - player can name monster or object or type of obj */
int
docallcmd(void)
{
    struct obj *obj;
    winid win;
    anything any;
    menu_item *pick_list = 0;
    struct _cmd_queue cq, *cmdq;
    char ch = 0;
    /* if player wants a,b,c instead of i,o when looting, do that here too */
    boolean abc = flags.lootabc;
    int clr = NO_COLOR;

    if ((cmdq = cmdq_pop()) != 0) {
        cq = *cmdq;
        free((genericptr_t) cmdq);
        if (cq.typ == CMDQ_KEY)
            ch = cq.key;
        else
            cmdq_clear(CQ_CANNED);
        goto docallcmd;
    }
    win = create_nhwindow(NHW_MENU);
    start_menu(win, MENU_BEHAVE_STANDARD);
    any = cg.zeroany;
    any.a_char = 'm'; /* group accelerator 'C' */
    add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, 'C',
             ATR_NONE, clr, "モンスター", MENU_ITEMFLAGS_NONE);
    if (gi.invent) {
        /* we use y and n as accelerators so that we can accept user's
           response keyed to old "name an individual object?" prompt */
        any.a_char = 'i'; /* group accelerator 'y' */
        add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, 'y',
                 ATR_NONE, clr, "持ち物の個別のアイテム",
                 MENU_ITEMFLAGS_NONE);
        any.a_char = 'o'; /* group accelerator 'n' */
        add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, 'n',
                 ATR_NONE, clr, "持ち物のアイテムの種類",
                 MENU_ITEMFLAGS_NONE);
    }
    any.a_char = 'f'; /* group accelerator ',' (or ':' instead?) */
    add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, ',',
             ATR_NONE, clr, "床にあるアイテムの種類",
             MENU_ITEMFLAGS_NONE);
    any.a_char = 'd'; /* group accelerator '\' */
    add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, '\\',
             ATR_NONE, clr, "発見済み一覧のアイテムの種類",
             MENU_ITEMFLAGS_NONE);
    any.a_char = 'a'; /* group accelerator 'l' */
    add_menu(win, &nul_glyphinfo, &any, abc ? 0 : any.a_char, 'l',
             ATR_NONE, clr, "現在の階層に注釈を記録",
             MENU_ITEMFLAGS_NONE);
    end_menu(win, "何に名前を付けますか?");
    if (select_menu(win, PICK_ONE, &pick_list) > 0) {
        ch = pick_list[0].item.a_char;
        free((genericptr_t) pick_list);
    } else
        ch = 'q';
    destroy_nhwindow(win);

 docallcmd:
    switch (ch) {
    default:
    case 'q':
        break;
    case 'm': /* name a visible monster */
        do_mgivenname();
        break;
    case 'i': /* name an individual object in inventory */
        obj = getobj("name", name_ok, GETOBJ_PROMPT);
        if (obj)
            do_oname(obj);
        break;
    case 'o': /* name a type of object in inventory */
        obj = getobj("call", call_ok, GETOBJ_NOFLAGS);
        if (obj) {
            /* behave as if examining it in inventory;
               this might set dknown if it was picked up
               while blind and the hero can now see */
            (void) xname(obj);

            if (!obj->dknown) {
                You("それを別の種類の物として認識し直すことはできなかった.");
#if 0
            } else if (call_ok(obj) == GETOBJ_EXCLUDE) {
                You("それについてはすでに十分知っている.");
#endif
            } else {
                docall(obj);
            }
        }
        break;
    case 'f': /* name a type of object visible on the floor */
        namefloorobj();
        break;
    case 'd': /* name a type of object on the discoveries list */
        rename_disco();
        break;
    case 'a': /* annotate level */
        donamelevel();
        break;
    }
    return ECMD_OK;
}

/* type-calling prompt用: 英語冠詞経路を使わない安全な対象名 */
staticfn const char *
docall_target_name(struct obj *obj, char *outbuf, size_t outbufsz)
{
    struct obj otemp;

    otemp = *obj;
    otemp.oextra = (struct oextra *) 0;
    otemp.quan = 1L;
    /* in case water is already known, convert "[un]holy water" to "water" */
    otemp.blessed = otemp.cursed = 0;
    /* remove attributes that are doname() caliber but get formatted
       by xname(); most of these fixups aren't really needed because the
       relevant type of object isn't callable so won't reach this far */
    if (otemp.oclass == WEAPON_CLASS)
        otemp.opoisoned = 0; /* not poisoned */
    else if (otemp.oclass == POTION_CLASS)
        otemp.odiluted = 0; /* not diluted */
    else if (otemp.otyp == TOWEL || otemp.otyp == STATUE)
        otemp.spe = 0; /* not wet or historic */
    else if (otemp.otyp == TIN)
        otemp.known = 0; /* suppress tin type (homemade, &c) and mon type */
    else if (otemp.otyp == FIGURINE)
        otemp.corpsenm = NON_PM; /* suppress mon type */
    else if (otemp.otyp == HEAVY_IRON_BALL)
        otemp.owt = objects[HEAVY_IRON_BALL].oc_weight; /* not "very heavy" */
    else if (otemp.oclass == FOOD_CLASS && otemp.globby)
        otemp.owt = 120; /* 6*20, neither a small glob nor a large one */

    Snprintf(outbuf, outbufsz, "%s", simpleonames(&otemp));
    return outbuf;
}

staticfn void
build_docall_prompt(char *qbuf, size_t qbufsz, struct obj *obj)
{
    char target[BUFSZ];

    if (obj->oclass == POTION_CLASS && obj->fromsink) {
        Snprintf(qbuf, qbufsz, "この液体を何と呼びますか?");
        return;
    }
    Snprintf(qbuf, qbufsz, "%sを何と呼びますか?",
             docall_target_name(obj, target, sizeof target));
}

staticfn void
normalize_scroll_callname(struct obj *obj, char *buf, size_t bufsz)
{
    const char *en_descr;
    const char *jp_descr;

    if (!obj || obj->oclass != SCROLL_CLASS || !buf || !*buf)
        return;

    en_descr = OBJ_DESCR(objects[obj->otyp]);
    jp_descr = jp_item_descr(obj->otyp);
    if (en_descr && jp_descr && !strcmpi(buf, en_descr))
        Snprintf(buf, bufsz, "%s", jp_descr);
}

void
docall(struct obj *obj)
{
    char buf[BUFSZ], qbuf[QBUFSZ];
    char **uname_p;
    boolean had_name = FALSE;

    if (!obj->dknown)
        return; /* probably blind; Blind || Hallucination for 'fromsink' */
    flush_screen(1); /* buffered updates might matter to player's response */

    build_docall_prompt(qbuf, sizeof qbuf, obj);
    /* pointer to old name */
    uname_p = &(objects[obj->otyp].oc_uname);
    /* use getlin() to get a name string from the player */
    if (!name_from_player(buf, qbuf, *uname_p))
        return;

    /* clear old name */
    if (*uname_p) {
        had_name = TRUE;
        free((genericptr_t) *uname_p), *uname_p = NULL; /* clear oc_uname */
    }

    /* strip leading and trailing spaces; uncalls item if all spaces */
    (void) mungspaces(buf);
    normalize_scroll_callname(obj, buf, sizeof buf);
    if (!*buf) {
        if (had_name) /* possibly remove from disco[]; old *uname_p is gone */
            undiscover_object(obj->otyp);
    } else {
        *uname_p = dupstr(buf);
        discover_object(obj->otyp, FALSE, TRUE, TRUE); /* possibly add to disco[] */
    }
    if (obj->where == OBJ_INVENT || carrying(obj->otyp))
        update_inventory();
}

staticfn void
namefloorobj(void)
{
    coord cc;
    int glyph;
    char buf[BUFSZ];
    struct obj *obj = 0;
    boolean fakeobj = FALSE, use_plural;

    cc.x = u.ux, cc.y = u.uy;
    /* "dot for under/over you" only makes sense when the cursor hasn't
       been moved off the hero's '@' yet, but there's no way to adjust
       the help text once getpos() has started */
         Sprintf(buf, "地図上の物体（'.'で%s物体を指定）",
            (u.uundetected && hides_under(gy.youmonst.data))
                  ? "あなたの上の" : "足元の");
    if (getpos(&cc, FALSE, buf) < 0 || cc.x <= 0)
        return;
    if (u_at(cc.x, cc.y)) {
        obj = vobj_at(u.ux, u.uy);
    } else {
        glyph = glyph_at(cc.x, cc.y);
        if (glyph_is_object(glyph))
            fakeobj = object_from_map(glyph, cc.x, cc.y, &obj);
        /* else 'obj' stays null */
    }
    if (!obj) {
        /* "under you" is safe here since there's no object to hide under */
        There("にはそのような物体が%sないようだ.",
              u_at(cc.x, cc.y) ? "足元に" : "");
        return;
    }
    /* note well: 'obj' might be an instance of STRANGE_OBJECT if target
       is a mimic; passing that to xname (directly or via simpleonames)
       would yield "glorkum" so we need to handle it explicitly; it will
       always fail the Hallucination test and pass the !callable test,
       resulting in the "can't be assigned a type name" message */
    Strcpy(buf, (obj->otyp != STRANGE_OBJECT)
                 ? simpleonames(obj)
                 : obj_descr[STRANGE_OBJECT].oc_name);
    use_plural = (obj->quan > 1L);
    if (Hallucination) {
        const char *unames[6];
        char tmpbuf[BUFSZ];

        /* straight role name */
        unames[0] = jp_role_name_for_display(
                flags.initrole,
                ((Upolyd ? u.mfemale : flags.female) ? 1 : 0));
        /* random rank title for hero's role

           note: the 30 is hardcoded in xlev_to_rank, so should be
           hardcoded here too */
        unames[1] = jp_rank_of_for_display(rn2_on_display_rng(30) + 1,
                           Role_switch, flags.female);
        /* random fake monster */
        unames[2] = bogusmon(tmpbuf, (char *) 0);
        /* increased chance for fake monster */
        unames[3] = unames[2];
        /* traditional */
        unames[4] = roguename();
        /* silly */
        unames[5] = "ウィブリー・ウォブリー";
          pline("%sはあなたを\"%s\"と呼ぶことにした.",
              The(buf),
              unames[rn2_on_display_rng(SIZE(unames))]);
    } else if (call_ok(obj) == GETOBJ_EXCLUDE) {
          pline("%sに種類名は付けられない.",
              use_plural ? "それら" : "それ");
    } else if (!obj->dknown) {
        You("%sの正体をまだ十分に知らないため、%sとは名付けられない。",
            use_plural ? "それら" : "それ", buf);
    } else {
        docall(obj);
    }
    if (fakeobj) {
        obj->where = OBJ_FREE; /* object_from_map() sets it to OBJ_FLOOR */
        dealloc_obj(obj); /* has no contents */
    }
}

static const char *const ghostnames[] = {
    /* these names should have length < PL_NSIZ */
    "アドリ",      "アンドリース", "アンドレアス", "バート",        "デビッド",    "ディルク",
    "エミール",    "フランツ",     "フレッド",     "グレッグ",      "ヘザー",      "ジェイ",
    "ジョン",      "ヨン",         "カルノフ",     "ケイ",          "ケニー",      "ケビン",
    "モード",      "ミヒール",     "マイク",       "ピーター",      "ロバート",    "ロン",
    "トム",        "ウィルマー",   "ニック・デンジャー", "フェニックス", "ジロー",      "ミズエ",
    "ステファン",  "ランス・ブラッカス", "シャドウホーク",  "マーフィー"
};

/* ghost names formerly set by x_monnam(), now by makemon() instead */
const char *
rndghostname(void)
{
    return rn2(7) ? ROLL_FROM(ghostnames)
                  : (const char *) svp.plname;
}

/*
 * Monster naming functions:
 * x_monnam is the generic monster-naming function.
 *                seen        unseen       detected               named
 * mon_nam:     the newt        it      the invisible orc       Fido
 * noit_mon_nam:your newt (as if detected) your invisible orc   Fido
 * some_mon_nam:the newt    someone     the invisible orc       Fido
 *          or              something
 * l_monnam:    newt            it      invisible orc           dog called Fido
 * Monnam:      The newt        It      The invisible orc       Fido
 * noit_Monnam: Your newt (as if detected) Your invisible orc   Fido
 * Some_Monnam: The newt    Someone     The invisible orc       Fido
 *          or              Something
 * Adjmonnam:   The poor newt   It      The poor invisible orc  The poor Fido
 * Amonnam:     A newt          It      An invisible orc        Fido
 * a_monnam:    a newt          it      an invisible orc        Fido
 * m_monnam:    newt            xan     orc                     Fido
 * y_monnam:    your newt     your xan  your invisible orc      Fido
 * YMonnam:     Your newt     Your xan  Your invisible orc      Fido
 * noname_monnam(mon,article):
 *              article newt    art xan art invisible orc       art dog
 */

/*
 * article
 *
 * ARTICLE_NONE, ARTICLE_THE, ARTICLE_A: obvious
 * ARTICLE_YOUR: "your" on pets, "the" on everything else
 *
 * If the monster would be referred to as "it" or if the monster has a name
 * _and_ there is no adjective, "invisible", "saddled", etc., override this
 * and always use no article.
 *
 * suppress
 *
 * SUPPRESS_IT, SUPPRESS_INVISIBLE, SUPPRESS_HALLUCINATION, SUPPRESS_SADDLE.
 * SUPPRESS_MAPPEARANCE: if monster is mimicking another monster (cloned
 *              Wizard or quickmimic pet), describe the real monster rather
 *              than its current form;
 * EXACT_NAME: combination of all the above
 * SUPPRESS_NAME: omit monster's assigned name (unless uniq w/ pname).
 * AUGMENT_IT: not suppression but shares suppression bitmask; if result
 *              would have been "it", return "someone" if humanoid or
 *              "something" otherwise.
 *
 * Bug: if the monster is a priest or shopkeeper, not every one of these
 * options works, since those are special cases.
 */
char *
x_monnam(
    struct monst *mtmp,
    int article,
    const char *adjective,
    int suppress,
    boolean called)
{
    char *buf = nextmbuf();
    struct permonst *mdat = mtmp->data;
    const char *pm_name;
    boolean do_hallu, do_invis, do_it, do_saddle, do_mappear,
            do_exact, do_name, augment_it;
    boolean name_at_start, has_adjectives, insertbuf2,
            mappear_as_mon = (M_AP_TYPE(mtmp) == M_AP_MONSTER);
    char *bp, buf2[BUFSZ];

    if (mtmp == &gy.youmonst)
        return strcpy(buf, "you"); /* ignore article, "invisible", &c */

    if (program_state.gameover)
        suppress |= SUPPRESS_HALLUCINATION;
    if (article == ARTICLE_YOUR && !mtmp->mtame)
        article = ARTICLE_THE;

    if (u.uswallow && mtmp == u.ustuck) {
        /*
         * This monster has become important, for the moment anyway.
         * As the hero's consumer, it is worthy of ARTICLE_THE.
         * Also, suppress invisible as that particular characteristic
         * is unimportant now and you can see its interior anyway.
         */
        article = ARTICLE_THE;
        suppress |= SUPPRESS_INVISIBLE;
    }
    do_hallu = Hallucination && !(suppress & SUPPRESS_HALLUCINATION);
    do_invis = mtmp->minvis && !(suppress & SUPPRESS_INVISIBLE);
    do_it = !canspotmon(mtmp) && article != ARTICLE_YOUR
            && !program_state.gameover && mtmp != u.usteed
            && !engulfing_u(mtmp) && !(suppress & SUPPRESS_IT);
    do_saddle = !(suppress & SUPPRESS_SADDLE);
    do_mappear = mappear_as_mon && !(suppress & SUPPRESS_MAPPEARANCE);
    do_exact = (suppress & EXACT_NAME) == EXACT_NAME;
    do_name = !(suppress & SUPPRESS_NAME) || type_is_pname(mdat);
    augment_it = (suppress & AUGMENT_IT) != 0;

    buf[0] = '\0';

    /* unseen monsters, etc.; usually "it" but sometimes more specific;
       when hallucinating, the more specific values might be inverted */
    if (do_it) {
        /* !is_animal excludes all Y; !mindless excludes Z, M, \' */
        boolean s_one = humanoid(mdat) && !is_animal(mdat) && !mindless(mdat);

        Strcpy(buf, !augment_it ? "それ"
                    : (!do_hallu ? s_one : !rn2(2)) ? "誰か"
                      : "何か");
        return buf;
    }

    /* priests and minions: don't even use this function */
    if ((mtmp->ispriest || mtmp->isminion) && !do_mappear) {
        char *name;
        long save_prop = EHalluc_resistance;
        unsigned save_invis = mtmp->minvis;

        /* when true name is wanted, explicitly block Hallucination */
        if (!do_hallu)
            EHalluc_resistance = 1L;
        if (!do_invis)
            mtmp->minvis = 0;
        /* EXACT_NAME will force "of <deity>" on the Astral Plane */
        name = priestname(mtmp, article, do_exact, buf2);
        EHalluc_resistance = save_prop;
        mtmp->minvis = save_invis;
        if (article == ARTICLE_NONE && !strncmp(name, "the ", 4))
            name += 4;
        return strcpy(buf, name);
    }

    /* 'pm_name' is the base part of most names */
    if (do_mappear) {
        /*assert(ismnum(mtmp->mappearance));*/
        pm_name = jp_pmname(&mons[mtmp->mappearance], Mgender(mtmp));
    } else {
        pm_name = mon_pmname(mtmp);
    }

    /* Shopkeepers: use shopkeeper name.  For normal shopkeepers, just
     * "Asidonhopo"; for unusual ones, "Asidonhopo the invisible
     * shopkeeper" or "Asidonhopo the blue dragon".  If hallucinating,
     * none of this applies.
     */
    if (mtmp->isshk && !do_hallu && !do_mappear) {
        if (adjective && article == ARTICLE_THE) {
            /* 形容詞+役職+固有名: "怒っているよろず屋Asidonhopo" */
            Strcat(buf, adjective);
            Strcat(buf, pm_name);
            Strcat(buf, jp_shkname_for_display(mtmp));
        } else {
            if (mdat != &mons[PM_SHOPKEEPER] || do_invis) {
                if (do_invis)
                    Strcat(buf, "見えない");
                Strcat(buf, pm_name);
            }
            Strcat(buf, jp_shkname_for_display(mtmp));
        }
        return buf;
    }

    /* Put the adjectives in the buffer */
    if (adjective) {
        if (!strcmp(adjective, "poor"))
            Strcat(buf, "かわいそうな");
        else if (!strcmp(adjective, "poor, unseen"))
            Strcat(buf, "見えない、かわいそうな");
        else
            Strcat(buf, adjective);
    }
    if (do_invis)
        Strcat(buf, "見えない");
    if (do_saddle && (mtmp->misc_worn_check & W_SADDLE) && !Blind
        && !Hallucination)
        Strcat(buf, "鞍をつけた");
    has_adjectives = (buf[0] != '\0');

    /* Put the actual monster name or type into the buffer now.
       Remember whether the buffer starts with a personal name. */
    if (do_hallu) {
        char rnamecode;
        char *rname = rndmonnam(&rnamecode);

        Strcat(buf, rname);
        name_at_start = bogon_is_pname(rnamecode);
    } else if (do_name && has_mgivenname(mtmp)) {
        char *name = MGIVENNAME(mtmp);
        const char *disp_name = jp_default_dog_name_for_display(mtmp, name);

#if 0
      /* hardfought */
      if (has_ebones(mtmp)) {
#endif
        if (mdat == &mons[PM_GHOST]) {
            Sprintf(eos(buf), "%sのゴースト", disp_name);
            name_at_start = TRUE;
        } else if (called) {
            char adj_save[BUFSZ];
            Strcpy(adj_save, buf); /* save adjectives already in buf (may be "") */
            Sprintf(buf, "%sという%s%s", disp_name, adj_save, pm_name);
            name_at_start = (boolean) type_is_pname(mdat);
        } else if (is_mplayer(mdat) && (bp = strstri(name, " the ")) != 0) {
            /* <name> the <adjective> <invisible> <saddled> <rank> */
            char pbuf[BUFSZ];

            Strcpy(pbuf, name);
            pbuf[bp - name + 5] = '\0'; /* adjectives right after " the " */
            if (has_adjectives)
                Strcat(pbuf, buf);
            Strcat(pbuf, bp + 5); /* append the rest of the name */
            Strcpy(buf, pbuf);
            article = ARTICLE_NONE;
            name_at_start = TRUE;
        } else {
            Strcat(buf, disp_name);
            name_at_start = TRUE;
        }
#if 0 /* hardfought */
      }
#endif
    } else if (is_mplayer(mdat) && !In_endgame(&u.uz)) {
        char pbuf[BUFSZ];

        Strcpy(pbuf, jp_rank_of_for_display((int) mtmp->m_lev,
                            monsndx(mdat),
                            (boolean) mtmp->female));
        Strcat(buf, lcase(pbuf));
        name_at_start = FALSE;
    } else {
        Strcat(buf, pm_name);
        name_at_start = (boolean) type_is_pname(mdat);
    }

    if (name_at_start && (article == ARTICLE_YOUR || !has_adjectives)) {
        if (mdat == &mons[PM_WIZARD_OF_YENDOR])
            article = ARTICLE_THE;
        else
            article = ARTICLE_NONE;
    } else if ((mdat->geno & G_UNIQ) != 0 && article == ARTICLE_A) {
        article = ARTICLE_THE;
    }

    insertbuf2 = TRUE;
    buf2[0] = '\0'; /* lint suppression */
    switch (article) {
    case ARTICLE_YOUR:
        Strcpy(buf2, "あなたの");
        break;
    case ARTICLE_THE:
        insertbuf2 = FALSE;
        break;
    case ARTICLE_A:
        insertbuf2 = FALSE;
        break;
    case ARTICLE_NONE:
    default:
        insertbuf2 = FALSE;
        break;
    }
    if (insertbuf2) {
        Strcat(buf2, buf); /* buf2[] isn't viable to return,  */
        Strcpy(buf, buf2); /* so transfer the result to buf[] */
    }
    return buf;
}

char *
l_monnam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_NONE, (char *) 0,
                    (has_mgivenname(mtmp)) ? SUPPRESS_SADDLE : 0, TRUE);
}

char *
mon_nam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_THE, (char *) 0,
                    (has_mgivenname(mtmp)) ? SUPPRESS_SADDLE : 0, FALSE);
}

/* print the name as if mon_nam() (y_monnam() if tame) was called, but
   assume that the player can always see the monster--used for probing and
   for monsters aggravating the player with a cursed potion of invisibility;
   also used for pet moving "reluctantly" onto cursed object when that pet
   can be seen either before or after it moves */
char *
noit_mon_nam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_YOUR, (char *) 0,
                    (has_mgivenname(mtmp) ? (SUPPRESS_SADDLE | SUPPRESS_IT)
                                          : SUPPRESS_IT),
                    FALSE);
}

/* in between noit_mon_nam() and mon_nam(); if the latter would pick "it",
   use "someone" (for humanoids) or "something" (for others) instead */
char *
some_mon_nam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_THE, (char *) 0,
                    (has_mgivenname(mtmp) ? (SUPPRESS_SADDLE | AUGMENT_IT)
                                          : AUGMENT_IT),
                    FALSE);
}

char *
Monnam(struct monst *mtmp)
{
    char *bp = mon_nam(mtmp);

    *bp = highc(*bp);
    return bp;
}

char *
noit_Monnam(struct monst *mtmp)
{
    char *bp = noit_mon_nam(mtmp);

    *bp = highc(*bp);
    return bp;
}

char *
Some_Monnam(struct monst *mtmp)
{
    char *bp = some_mon_nam(mtmp);

    *bp = highc(*bp);
    return bp;
}

/* return "a dog" rather than "Fido", honoring hallucination and visibility */
char *
noname_monnam(struct monst *mtmp, int article)
{
    return x_monnam(mtmp, article, (char *) 0, SUPPRESS_NAME, FALSE);
}

/* monster's own name -- overrides hallucination and [in]visibility
   so shouldn't be used in ordinary messages (mainly for disclosure) */
char *
m_monnam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_NONE, (char *) 0, EXACT_NAME, FALSE);
}

/* pet name: "your little dog" */
char *
y_monnam(struct monst *mtmp)
{
    int prefix, suppression_flag;

    prefix = mtmp->mtame ? ARTICLE_YOUR : ARTICLE_THE;
    suppression_flag = (has_mgivenname(mtmp)
                        /* "saddled" is redundant when mounted */
                        || mtmp == u.usteed)
                           ? SUPPRESS_SADDLE
                           : 0;

    return x_monnam(mtmp, prefix, (char *) 0, suppression_flag, FALSE);
}

/* y_monnam() for start of sentence */
char *
YMonnam(struct monst *mtmp)
{
    char *bp = y_monnam(mtmp);

    *bp = highc(*bp);
    return bp;
}

char *
Adjmonnam(struct monst *mtmp, const char *adj)
{
    char *bp = x_monnam(mtmp, ARTICLE_THE, adj,
                        has_mgivenname(mtmp) ? SUPPRESS_SADDLE : 0, FALSE);

    *bp = highc(*bp);
    return bp;
}

char *
a_monnam(struct monst *mtmp)
{
    return x_monnam(mtmp, ARTICLE_A, (char *) 0,
                    has_mgivenname(mtmp) ? SUPPRESS_SADDLE : 0, FALSE);
}

char *
Amonnam(struct monst *mtmp)
{
    char *bp = a_monnam(mtmp);

    *bp = highc(*bp);
    return bp;
}

/* used for monster ID by the '/', ';', and 'C' commands to block remote
   identification of the endgame altars via their attending priests */
char *
distant_monnam(
    struct monst *mon,
    int article, /* only ARTICLE_NONE and ARTICLE_THE are handled here */
    char *outbuf)
{
    /* high priest(ess)'s identity is concealed on the Astral Plane,
       unless you're adjacent (overridden for hallucination which does
       its own obfuscation) */
    if (mon->data == &mons[PM_HIGH_CLERIC] && !Hallucination
        && Is_astralevel(&u.uz) && !m_next2u(mon)) {
        Strcpy(outbuf, article == ARTICLE_THE ? "the " : "");
        Strcat(outbuf, mon->female ? "high priestess" : "high priest");
    } else {
        Strcpy(outbuf, x_monnam(mon, article, (char *) 0, 0, TRUE));
    }
    return outbuf;
}

/* returns mon_nam(mon) relative to other_mon; normal name unless they're
   the same, in which case the reference is to {him|her|it} self */
char *
mon_nam_too(struct monst *mon, struct monst *other_mon)
{
    char *outbuf;

    if (mon != other_mon) {
        outbuf = mon_nam(mon);
    } else {
        outbuf = nextmbuf();
        switch (pronoun_gender(mon, PRONOUN_HALLU)) {
        case 0:
            Strcpy(outbuf, "彼自身");
            break;
        case 1:
            Strcpy(outbuf, "彼女自身");
            break;
        default:
        case 2:
            Strcpy(outbuf, "自分自身");
            break;
        case 3: /* could happen when hallucinating */
            Strcpy(outbuf, "お互い");
            break;
        }
    }
    return outbuf;
}

/* construct "<monnamtext> <verb> <othertext> {him|her|it}self" which might
   be distorted by Hallu; if that's plural, adjust monnamtext and verb */
char *
monverbself(
    struct monst *mon,
    char *monnamtext, /* modifiable 'mbuf' with adequate room at end */
    const char *verb,
    const char *othertext)
{
    char *verbs, selfbuf[40]; /* sizeof "themselves" suffices */

    /* "himself"/"herself"/"itself", maybe "themselves" if hallucinating */
    Strcpy(selfbuf, mon_nam_too(mon, mon));
    /* verb starts plural; this will yield singular except for "themselves" */
    verbs = vtense(selfbuf, verb);
    if (!strcmp(verb, verbs)) { /* a match indicates that it stayed plural */
        monnamtext = makeplural(monnamtext);
        /* for "it", makeplural() produces "them" but we want "they" */
        if (!strcmpi(monnamtext, genders[3].he)) {
            boolean capitaliz = (monnamtext[0] == highc(monnamtext[0]));

            Strcpy(monnamtext, genders[3].him);
            if (capitaliz)
                monnamtext[0] = highc(monnamtext[0]);
        }
    }
    Strcat(strcat(monnamtext, " "), verbs);
    if (othertext && *othertext)
        Strcat(strcat(monnamtext, " "), othertext);
    Strcat(strcat(monnamtext, " "), selfbuf);
    return monnamtext;
}

/* for debugging messages, where data might be suspect and we aren't
   taking what the hero does or doesn't know into consideration */
char *
minimal_monnam(struct monst *mon, boolean ckloc)
{
    struct permonst *ptr;
    char *outbuf = nextmbuf();

    if (!mon) {
        Strcpy(outbuf, "[Null monster]");
    } else if ((ptr = mon->data) == 0) {
        Strcpy(outbuf, "[Null mon->data]");
    } else if (ptr < &mons[0]) {
        Sprintf(outbuf, "[Invalid mon->data %s < %s]",
                fmt_ptr((genericptr_t) mon->data),
                fmt_ptr((genericptr_t) &mons[0]));
    } else if (ptr >= &mons[NUMMONS]) {
        Sprintf(outbuf, "[Invalid mon->data %s >= %s]",
                fmt_ptr((genericptr_t) mon->data),
                fmt_ptr((genericptr_t) &mons[NUMMONS]));
    } else if (ckloc && ptr == &mons[PM_LONG_WORM] && mon->mx
               && svl.level.monsters[mon->mx][mon->my] != mon) {
        Sprintf(outbuf, "%s <%d,%d>",
            jp_pmname(&mons[PM_LONG_WORM_TAIL], Mgender(mon)),
                mon->mx, mon->my);
    } else {
        Sprintf(outbuf, "%s%s <%d,%d>",
                mon->mtame ? "tame " : mon->mpeaceful ? "peaceful " : "",
                mon_pmname(mon), mon->mx, mon->my);
        if (mon->cham != NON_PM)
            Sprintf(eos(outbuf), "{%s}",
                jp_pmname(&mons[mon->cham], Mgender(mon)));
    }
    return outbuf;
}

#ifndef PMNAME_MACROS
int
Mgender(struct monst *mtmp)
{
    int mgender = MALE;

    if (mtmp == &gy.youmonst) {
        if (Upolyd ? u.mfemale : flags.female)
            mgender = FEMALE;
    } else if (mtmp->female) {
        mgender = FEMALE;
    }
    return mgender;
}

const char *
pmname(struct permonst *pm, int mgender)
{
    if (mgender < MALE || mgender >= NUM_MGENDERS || !pm->pmnames[mgender])
        mgender = NEUTRAL;
    return pm->pmnames[mgender];
}
#endif /* PMNAME_MACROS */

/* mons[]->pmname for a monster */
const char *
mon_pmname(struct monst *mon)
{
    /* for neuter, mon->data->pmnames[MALE] will be Null and use [NEUTRAL] */
    return jp_pmname(mon->data, Mgender(mon));
}

/* mons[]->pmname for a corpse or statue or figurine */
const char *
obj_pmname(struct obj *obj)
{
#if 0   /* ignore saved montraits even when they're available; they determine
         * what a corpse would revive as if resurrected (human corpse from
         * slain vampire revives as vampire rather than as human, for example)
         * and don't necessarily reflect the state of the corpse itself */
    if (has_omonst(obj)) {
        struct monst *m = OMONST(obj);

        /* obj->oextra->omonst->data is Null but ...->mnum is set */
        if (ismnum(m->mnum))
            return jp_pmname(&mons[m->mnum], Mgender(m));
    }
#endif
    if ((obj->otyp == CORPSE || obj->otyp == STATUE || obj->otyp == FIGURINE)
        && ismnum(obj->corpsenm)) {
        int cgend = (obj->spe & CORPSTAT_GENDER),
            mgend = ((cgend == CORPSTAT_MALE) ? MALE
                     : (cgend == CORPSTAT_FEMALE) ? FEMALE
                       : NEUTRAL),
            mndx = obj->corpsenm;

        /* mons[].pmnames[] for monster cleric uses "priest" or "priestess"
           or "aligned cleric"; we want to avoid "aligned cleric [corpse]"
           unless it has been explicitly flagged as neuter rather than
           defaulting to random (which fails male or female check above);
           role monster cleric uses "priest" or "priestess" or "cleric"
           without "aligned" prefix so we switch to that; [can't force
           random gender to be chosen here because splitting a stack of
           corpses could cause the split-off portion to change gender, so
           settle for avoiding "aligned"] */
        if (mndx == PM_ALIGNED_CLERIC && cgend == CORPSTAT_RANDOM)
            mndx = PM_CLERIC;

        return jp_pmname(&mons[mndx], mgend);
    }
    impossible("obj_pmname otyp:%i,corpsenm:%i", obj->otyp, obj->corpsenm);
    return "two-legged glorkum-seeker";
}

/* used by bogusmon(next) and also by init_CapMons(rumors.c);
   bogon_is_pname(below) checks a hard-coded subset of these rather than
   use this list.
   Also used in rumors.c */
const char bogon_codes[] = "-_+|="; /* see dat/bonusmon.txt */

/* fake monsters used to be in a hard-coded array, now in a data file */
char *
bogusmon(char *buf, char *code)
{
    char *mnam = buf;

    if (code)
        *code = '\0';
    /* might fail (return empty buf[]) if the file isn't available */
    get_rnd_text(BOGUSMONFILE, buf, rn2_on_display_rng, MD_PAD_BOGONS);
    if (!*mnam) {
        Strcpy(buf, "bogon");
    } else if (strchr(bogon_codes, *mnam)) { /* strip prefix if present */
        if (code)
            *code = *mnam;
        ++mnam;
    }
    return mnam;
}

staticfn const char *
jp_default_dog_name_for_display(struct monst *mtmp, const char *name)
{
    if (!name || !*name || !mtmp || !mtmp->data || mtmp->data->mlet != S_DOG)
        return name;

    if (!strcmpi(name, "Idefix"))
        return "イデフィックス";
    if (!strcmpi(name, "Slasher"))
        return "スラッシャー";
    if (!strcmpi(name, "Hachi"))
        return "ハチ";
    if (!strcmpi(name, "Sirius"))
        return "シリウス";
    return name;
}

const char *
jp_mgivenname_for_display(struct monst *mtmp)
{
    const char *name;

    if (!mtmp || !has_mgivenname(mtmp))
        return "";
    name = MGIVENNAME(mtmp);
    return jp_default_dog_name_for_display(mtmp, name);
}

staticfn const char *
jp_bogusmon_for_display(const char *name)
{
    static const struct {
        const char *en;
        const char *ja;
    } bogons[] = {
        { "jumbo shrimp", "巨大な小エビ" },
        { "giant pigmy", "巨大なピグミー" },
        { "gnu", "ヌー" },
        { "killer penguin", "殺人ペンギン" },
        { "giant cockroach", "巨大ゴキブリ" },
        { "giant slug", "巨大ナメクジ" },
        { "maggot", "ウジ虫" },
        { "pterodactyl", "プテロダクティルス" },
        { "tyrannosaurus rex", "ティラノサウルス・レックス" },
        { "basilisk", "バシリスク" },
        { "beholder", "ビホルダー" },
        { "nightmare", "ナイトメア" },
        { "efreeti", "イフリート" },
        { "marid", "マリド" },
        { "rot grub", "腐肉ウジ" },
        { "bookworm", "本の虫" },
        { "master lichen", "親玉地衣類" },
        { "shadow", "影" },
        { "hologram", "ホログラム" },
        { "jester", "道化師" },
        { "attorney", "弁護士" },
        { "sleazoid", "ろくでなし" },
        { "killer tomato", "殺人トマト" },
        { "amazon", "アマゾネス" },
        { "robot", "ロボット" },
        { "battlemech", "バトルメック" },
        { "rhinovirus", "ライノウイルス" },
        { "harpy", "ハーピー" },
        { "lion-dog", "獅子犬" },
        { "rat-ant", "ネズミアリ" },
        { "Y2K bug", "Y2Kバグ" },
        { "angry mariachi", "怒れるマリアッチ" },
        { "arch-pedant", "大衒学者" },
        { "bluebird of happiness", "幸せの青い鳥" },
        { "cardboard golem", "段ボールのゴーレム" },
        { "duct tape golem", "ダクトテープのゴーレム" },
        { "diagonally moving grid bug", "斜めに動くグリッドバグ" },
        { "evil overlord", "邪悪な大君主" },
        { "newsgroup troll", "ニュースグループの荒らし" },
        { "ninja pirate zombie robot", "忍者海賊ゾンビロボット" },
        { "octarine dragon", "オクタリンのドラゴン" },
        { "plaid unicorn", "チェック柄のユニコーン" },
        { "gonzo journalist", "ゴンゾー・ジャーナリスト" },
        { "lag monster", "ラグ怪物" },
        { "loan shark", "高利貸しザメ" },
        { "possessed waffle iron", "取りつかれたワッフル焼き器" },
        { "poultrygeist", "ポウルトリーガイスト" },
        { "stuffed raccoon puppet", "アライグマのぬいぐるみ人形" },
        { "viking", "ヴァイキング" },
        { "wee green blobbie", "小さな緑のブロブ" },
        { "wereplatypus", "ワープラティパス" },
        { "hag of bolding", "太字化の魔女" },
        { "blancmange", "ブランマンジェ" },
        { "raging nerd", "激怒したオタク" },
        { "spelling bee", "スペリング蜂" },
        { "land octopus", "陸ダコ" },
        { "frog prince", "カエルの王子" },
        { "pigasus", "ピガサス" },
        { "Semigorgon", "セミゴルゴン" },
        { "conventioneer", "大会参加者" },
        { "large microbat", "大きなマイクロバット" },
        { "small megabat", "小さなメガバット" },
        { "uberhulk", "ユーバーハルク" },
        { "tofurkey", "トーファーキー" },
        { "Dudley", "ダドリー" },
        { "shrinking violet", "引っ込み思案のスミレ" },
        { "shallow one", "浅きもの" },
        { "spherical cow", "球形の牛" },
        { "electric giraffe", "電気キリン" },
        { "steam dragon", "蒸気ドラゴン" },
        { "omnibus", "オムニバス" },
        { "slinky", "スリンキー" },
        { "maxotaur", "マクソタウロス" },
        { "millitaur", "ミリタウロス" },
        { "octahedron", "八面体" },
        { "dungeon core", "ダンジョンコア" },
        { "quale", "クェール" },
        { "holloway", "ホロウェイ" },
        { "chiasmus", "キアズマス" },
        { "giant tetrapod", "巨大四脚獣" },
        { "voussoir", "ヴソワール" },
        { "barking spider", "ほえるクモ" },
        { "frog cloud", "カエル雲" },
        { "toothsayer", "トゥースセイヤー" },
        { "third eye", "第三の目" },
        { "owlpug", "フクロウパグ" },
        { "pugasus", "パガサス" },
        { "acorn", "どんぐり" },
        { "red dot", "赤い点" },
        { "robot chicken", "ロボットチキン" },
        { "doozer", "ドーザー" },
        { "poison cackler", "毒のけたたまし屋" },
        { "lhurgoyf", "ラーゴイフ" },
        { "phelddagrif", "フェルダグリフ" },
        { "tiktaalik", "ティクターリク" },
        { "weremoustache", "ワーマスタッシュ" },
        { "rapier tapir", "レイピアバク" },
        { "choplet", "チョプレット" },
        { "pommelbug", "ポメルバグ" },
        { "quest sprout", "クエストもやし" },
        { "grue", "グルー" },
        { "Christmas-tree monster", "クリスマスツリー怪物" },
        { "luck sucker", "幸運吸い" },
        { "paskald", "パスカルド" },
        { "brogmoid", "ブログモイド" },
        { "dornbeast", "ドルンビースト" },
        { "Ancient Multi-Hued Dragon", "古代の極彩色ドラゴン" },
        { "Evil Iggy", "邪悪なイギー" },
        { "rattlesnake", "ガラガラヘビ" },
        { "ice monster", "氷の怪物" },
        { "phantom", "ファントム" },
        { "quagga", "クアッガ" },
        { "aquator", "アクエイター" },
        { "griffin", "グリフィン" },
        { "emu", "エミュー" },
        { "kestrel", "チョウゲンボウ" },
        { "xeroc", "ゼロック" },
        { "venus flytrap", "ハエトリグサ" },
        { "creeping coins", "うごめく硬貨" },
        { "hydra", "ヒュドラ" },
        { "siren", "セイレーン" },
        { "killer bunny", "殺人ウサギ" },
        { "rodent of unusual size", "異常に大きいげっ歯類" },
        { "were-rabbit", "ワーラビット" },
        { "Smokey Bear", "スモーキー・ベア" },
        { "Luggage", "ラゲッジ" },
        { "vampiric watermelon", "吸血スイカ" },
        { "Ent", "エント" },
        { "tangle tree", "もつれ木" },
        { "nickelpede", "ニッケルムカデ" },
        { "wiggle", "うねうね" },
        { "white rabbit", "白ウサギ" },
        { "snark", "スナーク" },
        { "pushmi-pullyu", "プシュミプルユ" },
        { "smurf", "スマーフ" },
        { "tribble", "トリブル" },
        { "Klingon", "クリンゴン" },
        { "Borg", "ボーグ" },
        { "Ewok", "イウォーク" },
        { "Totoro", "トトロ" },
        { "ohmu", "王蟲" },
        { "youma", "妖魔" },
        { "nyaasu", "ニャース" },
        { "Godzilla", "ゴジラ" },
        { "King Kong", "キングコング" },
        { "earthquake beast", "地震獣" },
        { "Invid", "インビッド" },
        { "Terminator", "ターミネーター" },
        { "boomer", "ブーマー" },
        { "Dalek", "ダーレク" },
        { "microscopic space fleet", "微細な宇宙艦隊" },
        { "Ravenous Bugblatter Beast of Traal", "トラール星の貪欲なバグブラッター獣" },
        { "leathery-winged avian", "革のような翼を持つ鳥" },
        { "teenage mutant ninja turtle", "ティーンエイジ・ミュータント・ニンジャ・タートル" },
        { "samurai rabbit", "侍ウサギ" },
        { "aardvark", "ツチブタ" },
        { "Audrey II", "オードリーII世" },
        { "witch doctor", "魔医" },
        { "one-eyed one-horned flying purple people eater", "片目一本角の空飛ぶ紫の人間食い" },
        { "Barney the dinosaur", "恐竜バーニー" },
        { "Morgoth", "モルゴス" },
        { "Vorlon", "ヴォーロン" },
        { "questing beast", "唸る獣" },
        { "Predator", "プレデター" },
        { "dementor", "吸魂鬼（ディメンター）" },
        { "mother-in-law", "姑" },
        { "praying mantis", "カマキリ" },
        { "beluga whale", "シロイルカ" },
        { "chicken", "ニワトリ" },
        { "coelacanth", "シーラカンス" },
        { "star-nosed mole", "ホシバナモグラ" },
        { "lungfish", "肺魚" },
        { "slow loris", "スローロリス" },
        { "sea cucumber", "ナマコ" },
        { "tapeworm", "サナダムシ" },
        { "liger", "ライガー" },
        { "velociraptor", "ヴェロキラプトル" },
        { "corpulent porpoise", "肥満したネズミイルカ" },
        { "quokka", "クオッカ" },
        { "potoo", "タチヨタカ" },
        { "lemming", "レミング" },
        { "dhole", "ドール" },
        { "wolpertinger", "ヴォルパーティンガー" },
        { "elwedritsche", "エルヴェドリッチェ" },
        { "skvader", "スクヴェイダー" },
        { "Nessie", "ネッシー" },
        { "tatzelwurm", "タッツェルヴルム" },
        { "dahu", "ダユ" },
        { "dropbear", "ドロップベア" },
        { "wild haggis", "野生のハギス" },
        { "jackalope", "ジャッカロープ" },
        { "flying monkey", "空飛ぶ猿" },
        { "flying pig", "空飛ぶ豚" },
        { "hippocampus", "ヒッポカンポス" },
        { "hippogriff", "ヒッポグリフ" },
        { "kelpie", "ケルピー" },
        { "catoblepas", "カトブレパス" },
        { "phoenix", "フェニックス" },
        { "amphisbaena", "アンフィスバエナ" },
        { "bouncing eye", "跳ねる目玉" },
        { "floating nose", "浮遊する鼻" },
        { "wandering eye", "彷徨う目玉" },
        { "buffer overflow", "バッファオーバーフロー" },
        { "dangling pointer", "迷子のポインタ" },
        { "walking disk drive", "歩くディスクドライブ" },
        { "floating point", "浮動小数点" },
        { "regex engine", "正規表現エンジン" },
        { "netsplit", "ネットスプリット" },
        { "wiki", "ウィキ" },
        { "peer", "ピア" },
        { "COBOL", "COBOL" },
        { "wire shark", "ワイヤーシャーク" },
        { "stray tab", "迷いタブ" },
        { "bohrbug", "ボーアバグ" },
        { "mandelbug", "マンデルバグ" },
        { "schroedinbug", "シュレディンバグ" },
        { "heisenbug", "ハイゼンバグ" },
        { "cacodemon", "カコデモン" },
        { "scrag", "スクラーグ" },
        { "Crow T. Robot", "クロウTロボット" },
        { "chess pawn", "チェスの歩兵" },
        { "chocolate pudding", "チョコプリン" },
        { "ooblecks", "ウーブレック" },
        { "terracotta warrior", "兵馬俑" },
        { "hearse", "霊柩車" },
        { "roomba", "ルンバ" },
        { "miniature blimp", "ミニチュア飛行船" },
        { "dust speck", "塵の粒" },
        { "gazebo", "ガゼボ" },
        { "gray goo", "グレイグー" },
        { "magnetic monopole", "磁気単極子" },
        { "first category perpetual motion device", "第一種永久機関" },
        { "big dumb object", "巨大な沈黙の物体（BDO）" },
        { "Lord British", "ロード・ブリティッシュ" },
        { "particle man", "パーティクル・マン" },
        { "kitten prospecting robot", "子猫探査ロボット" },
        { "guillemet", "ギュメ" },
        { "solidus", "ソリダス" },
        { "obelus", "オベルス" },
        { "dingbat", "ディングバット" },
        { "bold face", "太字" },
        { "boustrophedon", "牛耕式（バウストロフェドン）" },
        { "ligature", "合字" },
        { "rebus", "判じ絵" },
        { "dinkus", "ディンカス" },
        { "apostrophe golem", "アポストロフィのゴーレム" },
        { "voluptuous ampersand", "妖艶なアンパサンド" },
        { "Bob the angry flower", "怒れる花ボブ" },
        { "Strong Bad", "ストロング・バッド" },
        { "Magical Trevor", "魔法使いトレバー" },
        { "smakken", "スマッケン" },
        { "mimmoth", "ミンモス" },
        { "one-winged dewinged stab-bat", "片翼をもぎ取られた刺しコウモリ" },
        { "Invisible Pink Unicorn", "見えないピンクのユニコーン" },
        { "Flying Spaghetti Monster", "空飛ぶスパゲッティ・モンスター" },
        { "three-headed monkey", "三つ首の猿" },
        { "El Pollo Diablo", "エル・ポヨ・ディアブロ（悪魔の鶏）" },
        { "little green man", "リトル・グリーン・マン" },
        { "weighted Companion Cube", "重み付き同行キューブ" },
        { "manbearpig", "マンベアピッグ" },
        { "bonsai-kitten", "盆栽子猫" },
        { "tie-thulu", "タイトゥルフ" },
        { "Domo-kun", "どーもくん" },
        { "looooooooooooong cat", "のびーるたん（ロングキャット）" },
        { "nyan cat", "ニャンキャット" },
        { "ceiling cat", "天井猫" },
        { "basement cat", "地下室猫" },
        { "monorail cat", "モノレール猫" },
        { "tridude", "トライデュード" },
        { "orcus cosmicus", "オルクス・コスミクス" },
        { "yeek", "イーク" },
        { "quylthulg", "クイルスルグ" },
        { "Greater Hell Beast", "偉大なる地獄の獣" },
        { "Vendor of Yizard", "イザードの行商人" },
        { "Sigmund", "ジークムント" },
        { "lernaean hydra", "レルネーのヒュドラ" },
        { "Ijyb", "イジィブ" },
        { "Gloorx Vloq", "グルークス・ヴロック" },
        { "Blork the orc", "オークのブローク" },
        { "unicorn pegasus kitten", "ユニコーン・ペガサス・子猫" },
        { "enderman", "エンダーマン" },
        { "wight supremacist", "ワイト至上主義者" },
        { "zergling", "ザーグリン" },
        { "existential angst", "実存的不安" },
        { "figment of your imagination", "想像の産物" },
        { "flash of insight", "閃き" },
        { "ghoti", "フィッシュ" },
        { "vermicious knid", "ヴァミシャス・クニッド" },
        { "meeple", "ミープル" },
        { "womble", "ウォンブル" },
        { "fraggle", "フラグル" },
        { "stainless steel rat", "ステンレス・スチール・ラット" },
        { "antagonistic undecagonstring", "敵対的な十一角形の弦" },
        { "mock role", "模擬ロール" },
        { "clown", "ピエロ" },
        { "mime", "パントマイム" },
        { "peddler", "行商人" },
        { "haggler", "値切る人" },
        { "gloating eye", "ほくそ笑むアイ" },
        { "flush golem", "水洗のゴーレム" },
        { "martyr orc", "殉教者のオーク" },
        { "mortar orc", "臼のオーク" },
        { "acid blog", "酸性ブログ" },
        { "acute blob", "鋭角のブロブ" },
        { "aria elemental", "アリアの精霊" },
        { "aliasing priest", "エイリアシング司祭" },
        { "aligned parasite", "整列した寄生虫" },
        { "aligned parquet", "整列した寄木細工" },
        { "aligned proctor", "整列した試験監督官" },
        { "baby balky dragon", "赤ちゃん駄々こねドラゴン" },
        { "baby blues dragon", "赤ちゃんブルース・ドラゴン" },
        { "baby caricature", "赤ちゃんカリカチュア" },
        { "baby crochet", "赤ちゃんクロシェ編み" },
        { "baby grainy dragon", "赤ちゃんつぶつぶドラゴン" },
        { "baby bong worm", "赤ちゃんボング虫" },
        { "baby long word", "赤ちゃん長い単語" },
        { "baby parable worm", "赤ちゃん寓話虫" },
        { "barfed devil", "吐き気を催した悪魔" },
        { "beer wight", "ビール・ワイト" },
        { "boor wight", "無作法なワイト" },
        { "brawny mold", "筋骨逞しいカビ" },
        { "rave spider", "レイブ・スパイダー" },
        { "clue golem", "手がかりのゴーレム" },
        { "bust vortex", "胸像の渦" },
        { "errata elemental", "誤植の精霊" },
        { "elastic eel", "弾力性のあるウナギ" },
        { "electrocardiogram eel", "心電図ウナギ" },
        { "fir elemental", "モミの精霊" },
        { "tire elemental", "タイヤの精霊" },
        { "flamingo sphere", "フラミンゴの球体" },
        { "fallacy golem", "謬論のゴーレム" },
        { "frizzed centaur", "ちりちり頭のケンタウロス" },
        { "forest centerfold", "森の折込ページ" },
        { "fierceness sphere", "猛烈な球体" },
        { "frosted giant", "霜を被った巨人" },
        { "geriatric snake", "老人ヘビ" },
        { "gnat ant", "ブユアリ" },
        { "giant bath", "巨大風呂" },
        { "grant beetle", "助成金カブトムシ" },
        { "greater snake", "より偉大なヘビ" },
        { "grind bug", "研磨バグ" },
        { "giant mango", "巨大マンゴー" },
        { "glossy golem", "光沢のあるゴーレム" },
        { "gnome laureate", "ノームの受賞者" },
        { "gnome dummy", "ノームのダミー" },
        { "gooier ooze", "よりベタつくウーズ" },
        { "green slide", "緑のスライド" },
        { "guardian nacho", "守護者ナチョ" },
        { "hell hound pun", "地獄の猟犬の駄洒落" },
        { "high purist", "高潔な純粋主義者" },
        { "hairnet devil", "ヘアネットの悪魔" },
        { "ice trowel", "氷の移植ごて" },
        { "killer beet", "殺人ビーツ" },
        { "feather golem", "羽毛のゴーレム" },
        { "lounge worm", "ラウンジ虫" },
        { "mountain lymph", "山のリンパ" },
        { "pager golem", "ポケベルのゴーレム" },
        { "pie fiend", "パイの悪鬼" },
        { "prophylactic worm", "避妊虫" },
        { "sock mole", "靴下モグラ" },
        { "rogue piercer", "ローグの穿孔器" },
        { "seesawing sphere", "シーソーする球体" },
        { "simile mimic", "直喩のミミック" },
        { "moldier ant", "よりカビの生えたアリ" },
        { "stain vortex", "汚れの渦" },
        { "scone giant", "スコーン巨人" },
        { "umbrella hulk", "傘ハルク" },
        { "vampire mace", "吸血鬼のメイス" },
        { "verbal jabberwock", "言葉のジャバウォック" },
        { "water lemon", "ウォーターレモン" },
        { "water melon", "スイカ" },
        { "winged grizzly", "翼のあるグリズリー" },
        { "yellow wight", "黄色のワイト" },
    };
    int i;

    for (i = 0; i < SIZE(bogons); ++i)
        if (!strcmp(name, bogons[i].en))
            return bogons[i].ja;

    return name;
}

/* return a random monster name, for hallucination */
char *
rndmonnam(char *code)
{
    static char buf[BUFSZ];
    char *mnam;
    int name;
#define BOGUSMONSIZE 100 /* arbitrary */

    if (code)
        *code = '\0';

    do {
        name = rn2_on_display_rng(SPECIAL_PM + BOGUSMONSIZE - LOW_PM) + LOW_PM;
    } while (name < SPECIAL_PM
             && (type_is_pname(&mons[name]) || (mons[name].geno & G_NOGEN)));

    if (name >= SPECIAL_PM) {
        mnam = strcpy(buf, jp_bogusmon_for_display(bogusmon(buf, code)));
    } else {
        mnam = strcpy(buf, jp_pmname(&mons[name], rn2_on_display_rng(2)));
    }
    return mnam;
#undef BOGUSMONSIZE
}

/* check bogusmon prefix to decide whether it's a personal name */
boolean
bogon_is_pname(char code)
{
    if (!code)
        return FALSE;
    return strchr("-+=", code) ? TRUE : FALSE;
}

/* name of a Rogue player */
const char *
roguename(void)
{
    char *i, *opts;

    if ((opts = nh_getenv("ROGUEOPTS")) != 0) {
        for (i = opts; *i; i++)
            if (!strncmp("name=", i, 5)) {
                char *j;
                if ((j = strchr(i + 5, ',')) != 0)
                    *j = (char) 0;
                return i + 5;
            }
    }
    return rn2(3) ? (rn2(2) ? "Michael Toy" : "Kenneth Arnold")
                  : "Glenn Wichman";
}

static NEARDATA const char *const hcolors[] = {
    "ultraviolet", "infrared", "bluish-orange", "reddish-green", "dark white",
    "light black", "sky blue-pink", "pinkish-cyan", "indigo-chartreuse",
    "salty", "sweet", "sour", "bitter", "umami", /* basic tastes */
    "striped", "spiral", "swirly", "plaid", "checkered", "argyle", "paisley",
    "blotchy", "guernsey-spotted", "polka-dotted", "square", "round",
    "triangular", "cabernet", "sangria", "fuchsia", "wisteria", "lemon-lime",
    "strawberry-banana", "peppermint", "romantic", "incandescent",
    "octarine", /* Discworld: the Colour of Magic */
    "excitingly dull", "mauve", "electric",
    "neon", "fluorescent", "phosphorescent", "translucent", "opaque",
    "psychedelic", "iridescent", "rainbow-colored", "polychromatic",
    "colorless", "colorless green",
    "dancing", "singing", "loving", "loudy", "noisy", "clattery", "silent",
    "apocyan", "infra-pink", "opalescent", "violant", "tuneless",
    "viridian", "aureolin", "cinnabar", "purpurin", "gamboge", "madder",
    "bistre", "ecru", "fulvous", "tekhelet", "selective yellow",
};

/* Display-only localized labels for hallucination color text. */
static NEARDATA const char *const jp_hcolors[] = {
    "紫外線色", "赤外線色", "青みがかったオレンジ", "赤みがかった緑",
    "暗い白", "明るい黒", "空色ピンク", "ピンクがかったシアン", "藍と黄緑の混色",
    "塩辛い色", "甘い色", "酸っぱい色", "苦い色", "うま味色", /* basic tastes */
    "縞模様", "螺旋模様", "渦巻き", "格子縞", "チェック模様", "アーガイル", "ペイズリー",
    "まだら模様", "ガーンジー牛柄", "水玉模様", "四角い色", "丸い色",
    "三角の色", "カベルネ色", "サングリア色", "フクシア", "藤色", "レモンライム色",
    "イチゴバナナ色", "ペパーミント色", "ロマンチックな色", "白熱光色",
    "オクタリン（魔法の色）", /* Discworld: the Colour of Magic */
    "刺激的なほど地味な色", "モーヴ", "電気色",
    "ネオン色", "蛍光色", "燐光色", "半透明", "不透明",
    "サイケデリック", "虹色", "レインボー色", "多色",
    "無色", "無色の緑",
    "踊る色", "歌う色", "愛情深い色", "うるさい色", "騒がしい色", "ガタガタ鳴る色", "無音の色",
    "アポシアン", "赤外ピンク", "オパール色", "バイオラント", "音程外れの色",
    "ヴィリジアン", "オレオリン", "辰砂（朱色）", "プルプリン", "藤黄（黄橙）", "茜色",
    "ビストル", "エクリュ", "黄褐色", "テヘレット", "選択黄",
};

static const struct {
    const char *en;
    const char *ja;
} color_translation[] = {
    { "black", "黒" },
    { "amber", "琥珀" },
    { "golden", "金" },
    { "light blue", "淡い青" },
    { "red", "赤" },
    { "green", "緑" },
    { "silver", "銀" },
    { "blue", "青" },
    { "purple", "紫" },
    { "white", "白" },
    { "orange", "橙" },
    { "brown", "茶" },
    { "magenta", "赤紫" },
    { "cyan", "青緑" },
    { "gray", "灰" },
    { "transparent", "透明" },
    { "bright green", "明るい緑" },
    { "yellow", "黄" },
    { "bright blue", "明るい青" },
    { "bright magenta", "明るい赤紫" },
    { "bright cyan", "明るい青緑" }
};

const char *
hcolor(const char *colorpref)
{
    if (Hallucination || !colorpref)
        return jp_hcolors[rn2_on_display_rng(SIZE(jp_hcolors))];

    for (int i = 0; i < SIZE(color_translation); ++i) {
        if (!strcmp(colorpref, color_translation[i].en)) {
            return color_translation[i].ja;
        }
    }
    return colorpref;
}

/* return a random real color unless hallucinating */
const char *
rndcolor(void)
{
    int k = rn2(CLR_MAX);

    return Hallucination ? hcolor((char *) 0)
                         : (k == NO_COLOR) ? "無色"
                                           : jp_obj_color_for_display(k);
}

static NEARDATA const char *const hliquids[] = {
    "yoghurt", "oobleck", "clotted blood", "diluted water", "purified water",
    "instant coffee", "tea", "herbal infusion", "liquid rainbow",
    "creamy foam", "mulled wine", "bouillon", "nectar", "grog", "flubber",
    "ketchup", "slow light", "oil", "vinaigrette", "liquid crystal", "honey",
    "caramel sauce", "ink", "aqueous humour", "milk substitute",
    "fruit juice", "glowing lava", "gastric acid", "mineral water",
    "cough syrup", "quicksilver", "sweet vitriol", "grey goo", "pink slime",
    "cosmic latte", "bone oil", "custard", "lard", "vinegar", "creosote",
    /* "new coke (tm)", --better not */
};

/* Display-only localized labels for hallucination liquid text. */
static NEARDATA const char *const jp_hliquids[] = {
    "ヨーグルト", "ウーブレック", "凝固した血", "薄めた水", "浄化水",
    "インスタントコーヒー", "紅茶", "薬草茶", "虹色の液体",
    "濃厚な泡", "ホットワイン", "ブイヨン", "ネクター", "グロッグ", "フラバー",
    "ケチャップ", "ゆっくりした光", "油", "ビネグレット", "液晶", "蜂蜜",
    "キャラメルソース", "インク", "房水", "代用ミルク",
    "果汁", "光る溶岩", "胃酸", "ミネラルウォーター",
    "咳止めシロップ", "水銀", "甘い礬油", "グレイグー", "ピンクスライム",
    "コズミックラテ", "骨油", "カスタード", "ラード", "酢", "クレオソート",
};

staticfn const char *
jp_liquidname_for_display(const char *liquidpref)
{
    if (!liquidpref || !*liquidpref)
        return liquidpref;

    /* Keep upstream-style liquid keys at call sites and normalize here. */
    if (!strcmp(liquidpref, "water"))
        return "水";
    if (!strcmp(liquidpref, "lava"))
        return "溶岩";
    if (!strcmp(liquidpref, "acid"))
        return "酸";

    return liquidpref;
}

/* if hallucinating, return a random liquid instead of 'liquidpref' */
const char *
hliquid(
    const char *liquidpref) /* use as-is when not hallucintg (unless empty) */
{
    boolean hallucinate = Hallucination && !program_state.gameover;

    if (hallucinate || !liquidpref || !*liquidpref) {
        int indx, count = SIZE(jp_hliquids);

        /* if we have a non-hallucinatory default value, include it
           among the choices */
        if (liquidpref && *liquidpref)
            ++count;
        indx = rn2_on_display_rng(count);
        if (IndexOk(indx, jp_hliquids))
            return jp_hliquids[indx];
        if (IndexOk(indx, hliquids))
            return hliquids[indx];
    }
    return jp_liquidname_for_display(liquidpref);
}

/* Aliases for road-runner nemesis
 */
static const char *const coynames[] = {
    "Carnivorous Vulgaris", "Road-Runnerus Digestus", "Eatibus Anythingus",
    "Famishus-Famishus", "Eatibus Almost Anythingus", "Eatius Birdius",
    "Famishius Fantasticus", "Eternalii Famishiis", "Famishus Vulgarus",
    "Famishius Vulgaris Ingeniusi", "Eatius-Slobbius", "Hardheadipus Oedipus",
    "Carnivorous Slobbius", "Hard-Headipus Ravenus", "Evereadii Eatibus",
    "Apetitius Giganticus", "Hungrii Flea-Bagius", "Overconfidentii Vulgaris",
    "Caninus Nervous Rex", "Grotesques Appetitus", "Nemesis Ridiculii",
    "Canis latrans"
};

static const char *const jp_coynames[] = {
    "肉食属 普通種", "鳥追走属 消化良好種", "何食属 万物摂取種",
    "空腹属 空腹種", "何食属 ほぼ万物種", "鳥食属 鳥追種",
    "空腹属 幻想種", "永遠空腹属 永久飢餓種", "空腹属 一般種",
    "空腹属 一般巧妙種", "食いしん坊属 よだれ種", "硬頭属 難題種",
    "肉食属 よだれ種", "硬頭属 猛食種", "常食属 常食種",
    "巨大食欲属 大食種", "飢餓属 ノミ袋種", "過信属 一般種",
    "犬神経属 王種", "奇怪属 食欲種", "天罰属 愚行種",
    "コヨーテ（Canis latrans）"
};

char *
coyotename(struct monst *mtmp, char *buf)
{
    if (mtmp && buf) {
        Sprintf(buf, "%s - %s",
                x_monnam(mtmp, ARTICLE_NONE, (char *) 0, 0, TRUE),
                mtmp->mcan ? jp_coynames[SIZE(jp_coynames) - 1]
                           : jp_coynames[mtmp->m_id % (SIZE(jp_coynames) - 1)]);
    }
    return buf;
}

char *
rndorcname(char *s)
{
    static const char *const v[] = { "ア", "イ", "ウ", "エ", "オ" };
    static const char *const snd[] = { "ゴ", "ク", "ザ", "ナ", "リ",
                                 "ブ","ガ", "ズ", "ロ","ダ","バ" };
    int i, iend = rn1(2, 3), vstart = rn2(2);

    if (s) {
        *s = '\0';
        for (i = 0; i < iend; ++i) {
            vstart = 1 - vstart;                /* 0 -> 1, 1 -> 0 */
            Sprintf(eos(s), "%s%s", (i > 0 && !rn2(30)) ? "-" : "",
                    vstart ? ROLL_FROM(v) : ROLL_FROM(snd));
        }
    }
    return s;
}

struct monst *
christen_orc(struct monst *mtmp, const char *gang, const char *other)
{
    int sz = 0;
    char buf[BUFSZ], buf2[BUFSZ], *orcname;

    orcname = rndorcname(buf2);
    /* rndorcname() won't return NULL */
    sz = (int) strlen(orcname);
    if (gang)
        sz += (int) (strlen(gang) + strlen("の"));
    else if (other)
        sz += (int) strlen(other);

    if (sz < BUFSZ) {
        char gbuf[BUFSZ];
        boolean nameit = FALSE;

        if (gang) {
            Sprintf(buf, "%sの%s", upstart(strcpy(gbuf, gang)),
                    upstart(orcname));
            nameit = TRUE;
        } else if (other) {
            Sprintf(buf, "%s%s", upstart(orcname), other);
            nameit = TRUE;
        }
        if (nameit)
            mtmp = christen_monst(mtmp, buf);
    }
    return mtmp;
}

/* Discworld novel titles, in the order that they were published; a subset
   of them have index macros used for variant spellings; if the titles are
   reordered for some reason, make sure that those get renumbered to match */
static const char *const sir_Terry_novels[] = {
    "The Colour of Magic", "The Light Fantastic", "Equal Rites", "Mort",
    "Sourcery", "Wyrd Sisters", "Pyramids", "Guards! Guards!", "Eric",
    "Moving Pictures", "Reaper Man", "Witches Abroad", "Small Gods",
    "Lords and Ladies", "Men at Arms", "Soul Music", "Interesting Times",
    "Maskerade", "Feet of Clay", "Hogfather", "Jingo", "The Last Continent",
    "Carpe Jugulum", "The Fifth Elephant", "The Truth", "Thief of Time",
    "The Last Hero", "The Amazing Maurice and His Educated Rodents",
    "Night Watch", "The Wee Free Men", "Monstrous Regiment",
    "A Hat Full of Sky", "Going Postal", "Thud!", "Wintersmith",
    "Making Money", "Unseen Academicals", "I Shall Wear Midnight", "Snuff",
    "Raising Steam", "The Shepherd's Crown"
};
#define NVL_COLOUR_OF_MAGIC 0
#define NVL_SOURCERY 4
#define NVL_MASKERADE 17
#define NVL_AMAZING_MAURICE 27
#define NVL_THUD 33

/* Display-only Japanese titles (same order as sir_Terry_novels[]). */
static const char *const jp_sir_Terry_novels[] = {
    "魔法の色", "光のファンタスティック", "平等の儀式", "モート",
    "ソーサリー", "ウィアード・シスターズ", "ピラミッド", "衛兵！衛兵！", "エリック",
    "動く映像", "死神マン", "海外の魔女たち", "小さな神々",
    "貴族と淑女", "武装した男たち", "ソウル・ミュージック", "面白き時代",
    "仮面劇", "粘土の足", "ホッグファーザー", "ジンゴ", "最後の大陸",
    "喉笛を掴め", "第五の象", "真実", "時間泥棒",
    "最後の英雄", "驚くべきモーリスと教養ある齧歯類たち",
    "夜警", "小さな自由の男たち", "怪物の連隊",
    "空いっぱいの帽子", "郵便局へ行こう", "ドカン！", "冬の精",
    "お金を作ろう", "見えない学者たち", "真夜中の装い", "スナッフ",
    "蒸気を起こせ", "羊飼いの王冠"
};

const char *
noveltitle(int *novidx)
{
    int j, k = SIZE(sir_Terry_novels);

    j = rn2(k);
    if (novidx) {
        if (*novidx == -1)
            *novidx = j;
        else if (*novidx >= 0 && *novidx < k)
            j = *novidx;
    }
    return jp_sir_Terry_novels[j];
}

/* figure out canonical novel title from player-specified one */
const char *
lookup_novel(const char *lookname, int *idx)
{
    int k;

    /*
     * Accept variant spellings:
     * _The_Colour_of_Magic_ uses British spelling, and American
     * editions keep that, but we also recognize American spelling;
     * _Sourcery_ is a joke rather than British spelling of "sorcery".
     */
    if (!strcmpi(The(lookname), "The Color of Magic"))
        lookname = sir_Terry_novels[NVL_COLOUR_OF_MAGIC];
    else if (!strcmpi(lookname, "Sorcery"))
        lookname = sir_Terry_novels[NVL_SOURCERY];
    else if (!strcmpi(lookname, "Masquerade"))
        lookname = sir_Terry_novels[NVL_MASKERADE];
    else if (!strcmpi(The(lookname), "The Amazing Maurice"))
        lookname = sir_Terry_novels[NVL_AMAZING_MAURICE];
    else if (!strcmpi(lookname, "Thud"))
        lookname = sir_Terry_novels[NVL_THUD];

    for (k = 0; k < SIZE(sir_Terry_novels); ++k) {
        if (!strcmpi(lookname, sir_Terry_novels[k])
            || !strcmpi(The(lookname), sir_Terry_novels[k])) {
            if (idx)
                *idx = k;
            return sir_Terry_novels[k];
        }
    }
    /* name not found; if novelidx is already set, override the name */
    if (idx && IndexOk(*idx, sir_Terry_novels))
        return sir_Terry_novels[*idx];

    return (const char *) 0;
}

/*do_name.c*/


