/* NetHack 5.0	questpgr.c	$NHDT-Date: 1704043695 2023/12/31 17:28:15 $  $NHDT-Branch: keni-luabits2 $:$NHDT-Revision: 1.87 $ */
/*      Copyright 1991, M. Stephenson                             */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"
#include "dlb.h"

/*  quest-specific pager routines. */

#define QTEXT_FILE "quest.lua"

#ifdef TTY_GRAPHICS
#include "wintty.h"
#endif

staticfn const char *intermed(void);
/* sometimes find_qarti(gi.invent), and gi.invent can be null */
staticfn struct obj *find_qarti(struct obj *) NO_NNARGS;
staticfn const char *neminame(void);
staticfn const char *guardname(void);
staticfn const char *homebase(void);
staticfn const char *jp_quest_place_name(boolean);
staticfn const char *jp_quest_artiname_for_display(int, boolean);
staticfn void qtext_pronoun(char, char);
staticfn const char *jp_quest_pronoun(int, char, boolean);
staticfn void convert_arg(char);
staticfn void convert_line(char *,char *);
staticfn const char *jp_quest_alignname(aligntyp);
staticfn boolean quest_text_uses_multibyte(const char *);
staticfn void deliver_by_pline(const char *);
staticfn void deliver_by_window(const char *, int);
staticfn boolean skip_pager(boolean);
staticfn boolean com_pager_core(const char *, const char *, boolean, char **);

short
quest_info(int typ)
{
    switch (typ) {
    case 0:
        return gu.urole.questarti;
    case MS_LEADER:
        return gu.urole.ldrnum;
    case MS_NEMESIS:
        return gu.urole.neminum;
    case MS_GUARDIAN:
        return gu.urole.guardnum;
    default:
        impossible("quest_info(%d)", typ);
    }
    return 0;
}

/* return your role leader's name */
const char *
ldrname(void)
{
    int i = gu.urole.ldrnum;

    return jp_pmname_from_idx(i, NEUTRAL);
}

/* return your intermediate target string */
staticfn const char *
intermed(void)
{
    return jp_quest_place_name(FALSE);
}

boolean
is_quest_artifact(struct obj *otmp)
{
    return (boolean) (otmp->oartifact == gu.urole.questarti);
}

staticfn struct obj *
find_qarti(struct obj *ochain)
{
    struct obj *otmp, *qarti;

    for (otmp = ochain; otmp; otmp = otmp->nobj) {
        if (is_quest_artifact(otmp))
            return otmp;
        if (Has_contents(otmp) && (qarti = find_qarti(otmp->cobj)) != 0)
            return qarti;
    }
    return (struct obj *) 0;
}

/* check several object chains for the quest artifact to determine
   whether it is present on the current level */
struct obj *
find_quest_artifact(unsigned whichchains)
{
    struct monst *mtmp;
    struct obj *qarti = 0;

    if ((whichchains & (1 << OBJ_INVENT)) != 0)
        qarti = find_qarti(gi.invent);
    if (!qarti && (whichchains & (1 << OBJ_FLOOR)) != 0)
        qarti = find_qarti(fobj);
    if (!qarti && (whichchains & (1 << OBJ_MINVENT)) != 0)
        for (mtmp = fmon; mtmp; mtmp = mtmp->nmon) {
            if (DEADMONSTER(mtmp))
                continue;
            if ((qarti = find_qarti(mtmp->minvent)) != 0)
                break;
        }
    if (!qarti && (whichchains & (1 << OBJ_MIGRATING)) != 0) {
        /* check migrating objects and minvent of migrating monsters */
        for (mtmp = gm.migrating_mons; mtmp; mtmp = mtmp->nmon) {
            if (DEADMONSTER(mtmp))
                continue;
            if ((qarti = find_qarti(mtmp->minvent)) != 0)
                break;
        }
        if (!qarti)
            qarti = find_qarti(gm.migrating_objs);
    }
    if (!qarti && (whichchains & (1 << OBJ_BURIED)) != 0)
        qarti = find_qarti(svl.level.buriedobjlist);

    return qarti;
}

/* return your role nemesis' name */
staticfn const char *
neminame(void)
{
    int i = gu.urole.neminum;

    return jp_pmname_from_idx(i, NEUTRAL);
}

staticfn const char *
guardname(void) /* return your role leader's guard monster name */
{
    int i = gu.urole.guardnum;

    return jp_pmname_from_idx(i, NEUTRAL);
}

staticfn const char *
homebase(void) /* return your role leader's location */
{
    return jp_quest_place_name(TRUE);
}

staticfn const char *
jp_quest_place_name(boolean homebase)
{
    const char *fc = gu.urole.filecode;

    if (!strcmpi(fc, "Arc"))
        return homebase ? "考古学学院" : "トルテック王の墓";
    if (!strcmpi(fc, "Bar"))
        return homebase ? "デュアリ族の野営地" : "デュアリのオアシス";
    if (!strcmpi(fc, "Cav"))
        return homebase ? "祖先の洞窟" : "ドラゴンのねぐら";
    if (!strcmpi(fc, "Hea"))
        return homebase ? "エピダウロス神殿" : "コイオス神殿";
    if (!strcmpi(fc, "Kni"))
        return homebase ? "キャメロット城" : "ガラスの島";
    if (!strcmpi(fc, "Mon"))
        return homebase ? "チャン=スネ僧院" : "地主の僧院";
    if (!strcmpi(fc, "Pri"))
        return homebase ? "大神殿" : "ナルゾックの神殿";
    if (!strcmpi(fc, "Rog"))
        return homebase ? "盗賊ギルド会館" : "暗殺者ギルド会館";
    if (!strcmpi(fc, "Ran"))
        return homebase ? "オリオンの野営地" : "ワンプスの洞窟";
    if (!strcmpi(fc, "Sam"))
        return homebase ? "太郎一族の城" : "将軍の城";
    if (!strcmpi(fc, "Tou"))
        return homebase ? "アンク・モルポーク" : "盗賊ギルド会館";
    if (!strcmpi(fc, "Val"))
        return homebase ? "運命の聖堂" : "スルトの洞窟";
    if (!strcmpi(fc, "Wiz"))
        return homebase ? "孤独の塔" : "闇の塔";

    return homebase ? gu.urole.homebase : gu.urole.intermed;
}

staticfn const char *
jp_quest_artiname_for_display(int artinum, boolean short_name)
{
    nhUse(short_name);

    switch (artinum) {
    case ART_ORB_OF_DETECTION:
        return "探知のオーブ";
    case ART_HEART_OF_AHRIMAN:
        return "アーリマンの心臓";
    case ART_SCEPTRE_OF_MIGHT:
        return "力の王笏";
    case ART_STAFF_OF_AESCULAPIUS:
        return "アスクレピオスの杖";
    case ART_MAGIC_MIRROR_OF_MERLIN:
        return "マーリンの魔法の鏡";
    case ART_EYES_OF_THE_OVERWORLD:
        return "オーバーワールドの目";
    case ART_MITRE_OF_HOLINESS:
        return "神聖の僧帽";
    case ART_LONGBOW_OF_DIANA:
        return "ディアナの長弓";
    case ART_MASTER_KEY_OF_THIEVERY:
        return "盗賊術のマスターキー";
    case ART_TSURUGI_OF_MURAMASA:
        return "村正の剣";
    case ART_YENDORIAN_EXPRESS_CARD:
        return "プラチナ・イェンドリアン・エキスプレスカード";
    case ART_ORB_OF_FATE:
        return "運命のオーブ";
    case ART_EYE_OF_THE_AETHIOPICA:
        return "エチオピカの目";
    default:
        return (const char *) 0;
    }
}

/* returns 1 if nemesis death message mentions noxious fumes, otherwise 0;
   does not display the message */
int
stinky_nemesis(struct monst *mon)
{
    char *mesg = 0;
    int res = 0;

#if 0
    /* get the quest text for dying nemesis; don't assume that mon is
       hero's own role's nemesis (overkill since m_detach() and nemdead()
       both make that assumption--valid for normal play but not necessarily
       valid for wizard mode) */
    int r, mndx = monsndx(mon->data);
    for (r = 0; roles[r].name.m || roles[r].name.f; ++r)
        if (roles[r].neminum == mndx) {
            (void) com_pager_core(roles[r].filecode, "killed_nemesis",
                                  FALSE, &mesg);
            break;
        }
#else
    nhUse(mon);
    /* since nemdead() just gave the message for hero's nemesis even if 'mon'
       is some other role's nemesis (feasible in wizard mode), base any gas
       cloud on the text that was shown even if not appropriate for 'mon' */
    (void) com_pager_core(gu.urole.filecode, "killed_nemesis", FALSE, &mesg);
#endif

     /* this is somewhat fragile; it assumes that when both poison-ish
         qualifier and gas/fumes token are present, the latter refers to
         the former rather than to something unrelated. */
    if (mesg) {
        char *p;

        /* change newlines into spaces to cope with "...noxious\nfumes..." */
        (void) strNsubst(mesg, "\n", " ", 0);

        if (((p = strstri(mesg, "noxious")) != 0
             || (p = strstri(mesg, "poisonous")) != 0
             || (p = strstri(mesg, "toxic")) != 0
             || (p = strstri(mesg, "有毒")) != 0
             || (p = strstri(mesg, "毒")) != 0)
            && (strstri(p, " gas") || strstri(p, " fumes")
            || strstri(p, "ガス") || strstri(p, "煙")))
            res = 1;

        free((genericptr_t) mesg);
    }
    return res;
}

/* replace deity, leader, nemesis, or artifact name with pronoun;
   overwrites cvt_buf[] */
staticfn const char *
jp_quest_pronoun(
    int godgend,
    char lwhich,
    boolean plural)
{
    if (plural)
        return (lwhich == 'h') ? "それら"
               : (lwhich == 'i') ? "それらを"
               : (lwhich == 'j') ? "それらの" : "?";

    if (godgend == 0) {
        return (lwhich == 'h') ? "彼"
               : (lwhich == 'i') ? "彼を"
               : (lwhich == 'j') ? "彼の" : "?";
    } else if (godgend == 1) {
        return (lwhich == 'h') ? "彼女"
               : (lwhich == 'i') ? "彼女を"
               : (lwhich == 'j') ? "彼女の" : "?";
    }

    return (lwhich == 'h') ? "それ"
           : (lwhich == 'i') ? "それを"
           : (lwhich == 'j') ? "その" : "?";
}

staticfn void
qtext_pronoun(
    char who,   /* 'd' => deity, 'l' => leader, 'n' => nemesis, 'o' => arti */
    char which) /* 'h'|'H'|'i'|'I'|'j'|'J' */
{
    const char *pnoun;
    int godgend;
    char lwhich = lowc(which); /* H,I,J -> h,i,j */
    boolean plural_artifact;
    boolean multibyte;

    /*
     * Invalid subject (not d,l,n,o) yields neuter, singular result.
     *
     * For %o, treat all artifacts as neuter; some have plural names,
     * which genders[] doesn't handle; cvt_buf[] already contains name.
     */
    plural_artifact = (boolean) (who == 'o'
                                 && (strstri(gc.cvt_buf, "Eyes ")
                                     || strcmpi(gc.cvt_buf,
                                                makesingular(gc.cvt_buf))));
    multibyte = quest_text_uses_multibyte(gc.cvt_buf);

    if (multibyte) {
        if (plural_artifact) {
            pnoun = jp_quest_pronoun(2, lwhich, TRUE);
        } else {
            godgend = (who == 'd') ? svq.quest_status.godgend
                : (who == 'l') ? svq.quest_status.ldrgend
                : (who == 'n') ? svq.quest_status.nemgend
                : 2; /* default to neuter */
            pnoun = jp_quest_pronoun(godgend, lwhich, FALSE);
        }
    } else if (plural_artifact) {
        pnoun = (lwhich == 'h') ? "they"
                : (lwhich == 'i') ? "them"
                : (lwhich == 'j') ? "their" : "?";
    } else {
        godgend = (who == 'd') ? svq.quest_status.godgend
            : (who == 'l') ? svq.quest_status.ldrgend
            : (who == 'n') ? svq.quest_status.nemgend
            : 2; /* default to neuter */
        pnoun = (lwhich == 'h') ? genders[godgend].he
                : (lwhich == 'i') ? genders[godgend].him
                : (lwhich == 'j') ? genders[godgend].his : "?";
    }
    Strcpy(gc.cvt_buf, pnoun);
    /* capitalize for H,I,J */
    if (lwhich != which && !quest_text_uses_multibyte(gc.cvt_buf))
        gc.cvt_buf[0] = highc(gc.cvt_buf[0]);
    return;
}

staticfn void
convert_arg(char c)
{
    const char *str;

    switch (c) {
    case 'p':
        str = svp.plname;
        break;
    case 'c':
        str = jp_role_name_for_display(Role_switch, flags.female ? 1 : 0);
        break;
    case 'r':
        str = jp_rank_of_for_display(u.ulevel, Role_switch, flags.female);
        break;
    case 'R':
        str = jp_rank_of_for_display(MIN_QUEST_LEVEL, Role_switch,
                                     flags.female);
        break;
    case 's':
        str = (flags.female) ? "姉妹" : "兄弟";
        break;
    case 'S':
        str = (flags.female) ? "娘" : "息子";
        break;
    case 'l':
        str = ldrname();
        break;
    case 'i':
        str = intermed();
        break;
    case 'O':
    case 'o':
        str = jp_quest_artiname_for_display(gu.urole.questarti, c == 'O');
        if (!str) {
            str = the(artiname(gu.urole.questarti));
            if (c == 'O') {
                /* shorten "the Foo of Bar" to "the Foo"
                   (buffer returned by the() is modifiable) */
                char *p = strstri(str, " of ");

                if (p)
                    *p = '\0';
            }
        }
        break;
    case 'n':
        str = neminame();
        break;
    case 'g':
        str = guardname();
        break;
    case 'G':
        str = jp_align_gtitle_for_display(u.ualignbase[A_ORIGINAL]);
        break;
    case 'H':
        str = homebase();
        break;
    case 'a':
        str = jp_quest_alignname(u.ualignbase[A_ORIGINAL]);
        break;
    case 'A':
        str = jp_quest_alignname(u.ualign.type);
        break;
    case 'd':
        str = jp_align_gname_for_display(u.ualignbase[A_ORIGINAL]);
        break;
    case 'D':
        str = jp_align_gname_for_display(A_LAWFUL);
        break;
    case 'C':
        str = jp_quest_alignname(A_CHAOTIC);
        break;
    case 'N':
        str = jp_quest_alignname(A_NEUTRAL);
        break;
    case 'L':
        str = jp_quest_alignname(A_LAWFUL);
        break;
    case 'x':
        str = Blind ? "感じる" : "見る";
        break;
    case 'Z':
        str = jp_dungeon_name_by_dnum(0);
        break;
    case '%':
        str = "%";
        break;
    default:
        str = "";
        break;
    }
    Strcpy(gc.cvt_buf, str);
}

staticfn const char *
jp_quest_alignname(aligntyp alignment)
{
    switch (alignment) {
    case A_LAWFUL:
        return "秩序";
    case A_NEUTRAL:
        return "中立";
    case A_CHAOTIC:
        return "混沌";
    default:
        return "<属性>";
    }
}

staticfn boolean
quest_text_uses_multibyte(const char *str)
{
    const unsigned char *cursor = (const unsigned char *) str;

    while (*cursor) {
        if (*cursor & 0x80)
            return TRUE;
        ++cursor;
    }
    return FALSE;
}

staticfn void
convert_line(char *in_line, char *out_line)
{
    char *c, *cc;
    boolean multibyte;

    cc = out_line;
    for (c = in_line; *c; c++) {
        *cc = 0;
        switch (*c) {
        case '\r':
        case '\n':
            *(++cc) = 0;
            return;

        case '%':
            if (*(c + 1)) {
                convert_arg(*(++c));
                multibyte = quest_text_uses_multibyte(gc.cvt_buf);
                switch (*(++c)) {
                /* insert "a"/"an" prefix */
                case 'A':
                    if (multibyte) {
                        Strcat(cc, gc.cvt_buf);
                        cc += strlen(gc.cvt_buf);
                        continue; /* for */
                    }
                    Strcat(cc, An(gc.cvt_buf));
                    cc += strlen(cc);
                    continue; /* for */
                case 'a':
                    if (multibyte) {
                        Strcat(cc, gc.cvt_buf);
                        cc += strlen(gc.cvt_buf);
                        continue; /* for */
                    }
                    Strcat(cc, an(gc.cvt_buf));
                    cc += strlen(cc);
                    continue; /* for */

                /* capitalize */
                case 'C':
                    if (!multibyte)
                        gc.cvt_buf[0] = highc(gc.cvt_buf[0]);
                    break;

                /* replace name with pronoun;
                   valid for %d, %l, %n, and %o */
                case 'h': /* he/she */
                case 'H': /* He/She */
                case 'i': /* him/her */
                case 'I':
                case 'j': /* his/her */
                case 'J':
                    if (strchr("dlno", lowc(*(c - 1))))
                        qtext_pronoun(*(c - 1), *c);
                    else
                        --c; /* default action */
                    break;

                /* pluralize */
                case 'P':
                    if (!multibyte)
                        gc.cvt_buf[0] = highc(gc.cvt_buf[0]);
                    FALLTHROUGH;
                    /*FALLTHRU*/
                case 'p':
                    if (!multibyte)
                        Strcpy(gc.cvt_buf, makeplural(gc.cvt_buf));
                    break;

                /* append possessive suffix */
                case 'S':
                    if (!multibyte)
                        gc.cvt_buf[0] = highc(gc.cvt_buf[0]);
                    FALLTHROUGH;
                    /*FALLTHRU*/
                case 's':
                    if (!multibyte)
                        Strcpy(gc.cvt_buf, s_suffix(gc.cvt_buf));
                    break;

                /* strip any "the" prefix */
                case 't':
                    if (!multibyte && !strncmpi(gc.cvt_buf, "the ", 4)) {
                        Strcat(cc, &gc.cvt_buf[4]);
                        cc += strlen(cc);
                        continue; /* for */
                    }
                    break;

                default:
                    --c; /* undo switch increment */
                    break;
                }
                Strcat(cc, gc.cvt_buf);
                cc += strlen(gc.cvt_buf);
                break;
            }
            FALLTHROUGH;
            /* FALLTHRU */
        default:
            *cc++ = *c;
            break;
        }
        if (cc > &out_line[BUFSZ - 1])
            panic("convert_line: overflow");
    }
    *cc = 0;
    return;
}

staticfn void
deliver_by_pline(const char *str)
{
    char in_line[BUFSZ], out_line[BUFSZ];
    const char *msgp = str, *msgend = eos((char *) str);

    while (msgp < msgend) {
        /* copynchars() will stop at newline if it finds one */
        copynchars(in_line, msgp, (int) sizeof in_line - 1);
        msgp += strlen(in_line) + 1;

        convert_line(in_line, out_line);
        pline("%s", out_line);
    }
}

staticfn void
deliver_by_window(const char *msg, int how)
{
    char in_line[BUFSZ], out_line[BUFSZ];
    const char *msgp = msg, *msgend = eos((char *) msg);
    winid datawin = create_nhwindow(how);

    while (msgp < msgend) {
        /* copynchars() will stop at newline if it finds one */
        copynchars(in_line, msgp, (int) sizeof in_line - 1);
        msgp += strlen(in_line) + 1;

        convert_line(in_line, out_line);
        putstr(datawin, 0, out_line);
    }

    display_nhwindow(datawin, TRUE);
    destroy_nhwindow(datawin);
}

staticfn boolean
skip_pager(boolean common UNUSED)
{
    /* WIZKIT: suppress plot feedback if starting with quest artifact */
    if (program_state.wizkit_wishing)
        return TRUE;
    return FALSE;
}

staticfn boolean
com_pager_core(
    const char *section,
    const char *msgid,
    boolean showerror,
    char **rawtext)
{
    static const char *const howtoput[] = {
        "pline", "window", "text", "menu", "default", NULL
    };
    static const int howtoput2i[] = { 1, 2, 2, 3, 0, 0 };
    int output;
    lua_State *L;
    char *text = NULL, *synopsis = NULL, *fallback_msgid = NULL;
    boolean res = FALSE;
    nhl_sandbox_info sbi = {NHL_SB_SAFE, 1*1024*1024, 0, 1*1024*1024};

    if (skip_pager(TRUE))
        return FALSE;

    L = nhl_init(&sbi);
    if (!L) {
        if (showerror)
            impossible("com_pager: nhl_init() failed");
        goto compagerdone;
    }

    if (!nhl_loadlua(L, QTEXT_FILE)) {
        if (showerror)
            impossible("com_pager: %s not found.", QTEXT_FILE);
        goto compagerdone;
    }

    lua_settop(L, 0);
    lua_getglobal(L, "questtext");
    if (!lua_istable(L, -1)) {
        if (showerror)
            impossible("com_pager: questtext in %s is not a lua table",
                       QTEXT_FILE);
        goto compagerdone;
    }

    lua_getfield(L, -1, section);
    if (!lua_istable(L, -1)) {
        if (showerror)
            impossible("com_pager: questtext[%s] in %s is not a lua table",
                       section, QTEXT_FILE);
        goto compagerdone;
    }

 tryagain:
    lua_getfield(L, -1, fallback_msgid ? fallback_msgid : msgid);
    if (!lua_istable(L, -1)) {
        if (!fallback_msgid) {
            /* Do we have questtxt[msg_fallbacks][<msgid>]? */
            lua_getfield(L, -3, "msg_fallbacks");
            if (lua_istable(L, -1)) {
                fallback_msgid = get_table_str_opt(L, msgid, NULL);
                lua_pop(L, 2);
                if (fallback_msgid)
                    goto tryagain;
            }
        }
        if (showerror) {
            if (!fallback_msgid)
                impossible(
                      "com_pager: questtext[%s][%s] in %s is not a lua table",
                           section, msgid, QTEXT_FILE);
            else
                impossible(
           "com_pager: questtext[%s][%s] and [][%s] in %s are not lua tables",
                           section, msgid, fallback_msgid, QTEXT_FILE);
        }
        goto compagerdone;
    }

    text = get_table_str_opt(L, "text", NULL);
    if (rawtext) {
        *rawtext = dupstr(text);
        res = TRUE;
        goto compagerdone;
    }
    synopsis = get_table_str_opt(L, "synopsis", NULL);
    output = howtoput2i[get_table_option(L, "output", "default", howtoput)];

    if (!text) {
        int nelems;

        lua_len(L, -1);
        nelems = (int) lua_tointeger(L, -1);
        lua_pop(L, 1);
        if (nelems < 2) {
            if (showerror)
                impossible(
              "com_pager: questtext[%s][%s] in %s is not an array of strings",
                           section, fallback_msgid ? fallback_msgid : msgid,
                           QTEXT_FILE);
            goto compagerdone;
        }
        nelems = rn2(nelems) + 1;
        lua_pushinteger(L, nelems);
        lua_gettable(L, -2);
        text = dupstr(luaL_checkstring(L, -1));
    }

    /* switch from by_pline to by_window if line has multiple segments or
       is unreasonably long (the latter ought to checked after formatting
       conversions rather than before...) */
    if (output == 0 && (strchr(text, '\n') || strlen(text) >= BUFSZ - 1)) {
        output = 2;

        /*
         * FIXME:  should update quest.lua to include proper synopsis line
         * for any item subject to having its delivery converted to by_window.
         */
        if (!synopsis) {
            char tmpbuf[BUFSZ];

            Sprintf(tmpbuf, "[%.*s]", BUFSZ - 1 - 2, text);
            /* change every newline character to a space */
            (void) strNsubst(tmpbuf, "\n", " ", 0);
            synopsis = dupstr(tmpbuf);
        }
    }

    if (output == 0 || output == 1)
        deliver_by_pline(text);
    else
        deliver_by_window(text, (output == 3) ? NHW_MENU : NHW_TEXT);

    if (synopsis) {
        char in_line[BUFSZ], out_line[BUFSZ];

#if 0   /* not yet -- brackets need to be removed from quest.lua */
        Sprintf(in_line, "[%.*s]",
                (int) (sizeof in_line - sizeof "[]"), synopsis);
#else
        Strcpy(in_line, synopsis);
#endif
        convert_line(in_line, out_line);
        /* bypass message delivery but be available for ^P recall */
        putmsghistory(out_line, FALSE);
    }
    res = TRUE;

 compagerdone:
    if (text)
        free((genericptr_t) text);
    if (synopsis)
        free((genericptr_t) synopsis);
    if (fallback_msgid)
        free((genericptr_t) fallback_msgid);
    nhl_done(L);
    return res;
}

void
com_pager(const char *msgid)
{
    (void) com_pager_core("common", msgid, TRUE, (char **) 0);
}

void
qt_pager(const char *msgid)
{
    if (!com_pager_core(gu.urole.filecode, msgid, FALSE, (char **) 0))
        (void) com_pager_core("common", msgid, TRUE, (char **) 0);
}

struct permonst *
qt_montype(void)
{
    int qpm;

    if (rn2(5)) {
        qpm = gu.urole.enemy1num;
        if (qpm != NON_PM && rn2(5) && !(svm.mvitals[qpm].mvflags & G_GENOD))
            return &mons[qpm];
        return mkclass(gu.urole.enemy1sym, 0);
    }
    qpm = gu.urole.enemy2num;
    if (qpm != NON_PM && rn2(5) && !(svm.mvitals[qpm].mvflags & G_GENOD))
        return &mons[qpm];
    return mkclass(gu.urole.enemy2sym, 0);
}

/* special levels can include a custom arrival message; display it */
void
deliver_splev_message(void)
{
    /* there's no provision for delivering via window instead of pline */
    if (gl.lev_message) {
        deliver_by_pline(gl.lev_message);

        free((genericptr_t) gl.lev_message);
        gl.lev_message = NULL;
    }
}

#undef QTEXT_FILE

/*questpgr.c*/
