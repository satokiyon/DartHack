/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-31. */
/* NetHack 5.0	polyself.c	$NHDT-Date: 1781973061 2026/06/20 16:31:01 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.233 $ */
/*      Copyright (C) 1987, 1988, 1989 by Ken Arromdee */
/* NetHack may be freely redistributed.  See license for details. */

/*
 * Polymorph self routine.
 *
 * Note:  the light source handling code assumes that gy.youmonst.m_id
 * always remains 1 and gy.youmonst.mx will always remain 0 when it handles
 * the case of the player polymorphed into a light-emitting monster.
 *
 * Transformation sequences:
 *              /-> polymon                 poly into monster form
 *    polyself =
 *              \-> newman -> polyman       fail to poly, get human form
 *
 *    rehumanize -> polyman                 return to original form
 *
 *    polymon (called directly)             usually golem petrification
 */

#include "hack.h"

staticfn void check_strangling(boolean);
staticfn void polyman(const char *, const char *);
staticfn void dropp(struct obj *);
staticfn void break_armor(void);
staticfn void drop_weapon(int);
staticfn int armor_to_dragon(int);
staticfn void newman(void);
staticfn void polysense(void);

static const char no_longer_petrify_resistant[] =
    "No longer petrify-resistant, you";

/* update the gy.youmonst.data structure pointer and intrinsics */
void
set_uasmon(void)
{
    struct permonst *mdat = &mons[u.umonnum];
    boolean was_vampshifter = valid_vampshiftform(gy.youmonst.cham, u.umonnum);

    set_mon_data(&gy.youmonst, mdat);
    gy.youmonst.m_id = 1;

    if (Protection_from_shape_changers)
        gy.youmonst.cham = NON_PM;
    else if (is_vampire(gy.youmonst.data))
        gy.youmonst.cham = gy.youmonst.mnum;
    /* assume hero-as-chameleon/doppelganger/sandestin doesn't change shape */
    else if (!was_vampshifter)
        gy.youmonst.cham = NON_PM;
    u.mcham = gy.youmonst.cham; /* for save/restore since youmonst isn't */

#define PROPSET(PropIndx, ON)                          \
    do {                                               \
        if (ON)                                        \
            u.uprops[PropIndx].intrinsic |= FROMFORM;  \
        else                                           \
            u.uprops[PropIndx].intrinsic &= ~FROMFORM; \
    } while (0)
#define resist_from_form(MRtyp) ((gy.youmonst.data->mresists & (MRtyp)) != 0)

    PROPSET(FIRE_RES, resist_from_form(MR_FIRE));
    PROPSET(COLD_RES, resist_from_form( MR_COLD));
    PROPSET(SLEEP_RES, resist_from_form(MR_SLEEP));
    PROPSET(DISINT_RES, resist_from_form(MR_DISINT));
    PROPSET(SHOCK_RES, resist_from_form(MR_ELEC));
    PROPSET(POISON_RES, resist_from_form(MR_POISON));
    PROPSET(ACID_RES, resist_from_form(MR_ACID));
    PROPSET(STONE_RES, resist_from_form(MR_STONE));
    {
        /* resists_drli() takes wielded weapon into account; suppress it */
        struct obj *save_uwep = uwep;

        uwep = 0;
        PROPSET(DRAIN_RES, resists_drli(&gy.youmonst));
        uwep = save_uwep;
    }
    /* resists_magm() takes wielded, worn, and carried equipment into
       into account; cheat and duplicate its monster-specific part */
    PROPSET(ANTIMAGIC, (dmgtype(mdat, AD_MAGM)
                        || mdat == &mons[PM_BABY_GRAY_DRAGON]
                        || dmgtype(mdat, AD_RBRE)));
    PROPSET(SICK_RES, (mdat->mlet == S_FUNGUS || mdat == &mons[PM_GHOUL]));

    PROPSET(STUNNED, (mdat == &mons[PM_STALKER] || is_bat(mdat)));
    PROPSET(HALLUC_RES, dmgtype(mdat, AD_HALU));
    PROPSET(SEE_INVIS, perceives(mdat));
    PROPSET(TELEPAT, telepathic(mdat));
    /* note that Infravision uses mons[race] rather than usual mons[role] */
    PROPSET(INFRAVISION, infravision(Upolyd ? mdat : &mons[gu.urace.mnum]));
    PROPSET(INVIS, pm_invisible(mdat));
    PROPSET(TELEPORT, can_teleport(mdat));
    PROPSET(TELEPORT_CONTROL, control_teleport(mdat));
    PROPSET(LEVITATION, is_floater(mdat));
    /* floating eye is the only 'floater'; it is also flagged as a 'flyer';
       suppress flying for it so that enlightenment doesn't confusingly
       show latent flight capability always blocked by levitation */
    PROPSET(FLYING, (is_flyer(mdat) && !is_floater(mdat)));
    PROPSET(SWIMMING, is_swimmer(mdat));
    /* [don't touch MAGICAL_BREATHING here; both Amphibious and Breathless
       key off of it but include different monster forms...] */
    PROPSET(PASSES_WALLS, passes_walls(mdat));
    PROPSET(REGENERATION, regenerates(mdat));
    PROPSET(REFLECTING, (mdat == &mons[PM_SILVER_DRAGON]));
    PROPSET(BLINDED, !haseyes(mdat));
    PROPSET(BLND_RES, (dmgtype_fromattack(mdat, AD_BLND, AT_EXPL)
                       || dmgtype_fromattack(mdat, AD_BLND, AT_GAZE)));
#undef PROPSET
#undef resist_from_form

    /* whether the player is flying/floating depends on their steed,
       which won't be known during the restore process: but BFlying
       and BStealth should be set correctly already in that case, so
       there's nothing to do */
    if (!program_state.restoring)
        float_vs_flight(); /* maybe toggle (BFlying & I_SPECIAL) */
    polysense();

#ifdef STATUS_HILITES
    if (VIA_WINDOWPORT())
        status_initialize(REASSESS_ONLY);
#endif
    /* we can reset this now, having just done what it is meant to trigger */
    gw.were_changes = 0L;
}

/* Levitation overrides Flying; set or clear BFlying|I_SPECIAL */
void
float_vs_flight(void)
{
    boolean stuck_in_floor = (u.utrap && u.utraptype != TT_PIT);

    /* floating overrides flight; so does being trapped in the floor */
    if ((HLevitation || ELevitation)
        || ((HFlying || EFlying) && stuck_in_floor))
        BFlying |= I_SPECIAL;
    else
        BFlying &= ~I_SPECIAL;
    /* being trapped on the ground (bear trap, web, molten lava survived
       with fire resistance, former lava solidified via cold, tethered
       to a buried iron ball) overrides floating--the floor is reachable */
    if ((HLevitation || ELevitation) && stuck_in_floor)
        BLevitation |= I_SPECIAL;
    else
        BLevitation &= ~I_SPECIAL;

    /* riding blocks stealth unless hero+steed fly, so a change in flying
       might cause a change in stealth */
    steed_vs_stealth();

    disp.botl = TRUE;
}

/* riding blocks stealth unless hero+steed fly */
void
steed_vs_stealth(void)
{
    if (u.usteed && !Flying && !Levitation)
        BStealth |= FROMOUTSIDE;
    else
        BStealth &= ~FROMOUTSIDE;
}

/* for changing into form that's immune to strangulation */
staticfn void
check_strangling(boolean on)
{
    /* on -- maybe resume strangling */
    if (on) {
        boolean was_strangled = (Strangled != 0L);

        /* when Strangled is already set, polymorphing from one
           vulnerable form into another causes the counter to be reset */
        if (uamul && uamul->otyp == AMULET_OF_STRANGULATION
            && can_be_strangled(&gy.youmonst)) {
            Strangled = 6L;
            disp.botl = TRUE;
              Your("%sが%sを%s!", simpleonames(uamul), jp_body_part(NECK),
                  was_strangled ? "まだ締めつけている" : "締めつけ始めた"); /* "throat" */
            makeknown(AMULET_OF_STRANGULATION);
        }

    /* off -- maybe block strangling */
    } else {
        if (Strangled && !can_be_strangled(&gy.youmonst)) {
            Strangled = 0L;
            disp.botl = TRUE;
            You("もう綒澠騙けた。");
        }
    }
}

DISABLE_WARNING_FORMAT_NONLITERAL

/* make a (new) human out of the player */
staticfn void
polyman(const char *fmt, const char *arg)
{
    boolean sticking = (sticks(gy.youmonst.data) && u.ustuck && !u.uswallow),
            was_mimicking = (U_AP_TYPE != M_AP_NOTHING);
    boolean was_blind = !!Blind,
            had_see_invis = !!See_invisible;

    if (Upolyd) {
        u.acurr = u.macurr; /* restore old attribs */
        u.amax = u.mamax;
        u.umonnum = u.umonster;
        flags.female = u.mfemale;
    }
    set_uasmon();

    u.mh = u.mhmax = 0;
    u.mtimedone = 0;
    skinback(FALSE);
    u.uundetected = 0;

    if (sticking)
        uunstick();
    find_ac();
    if (was_mimicking) {
        if (gm.multi < 0)
            unmul("");
        gy.youmonst.m_ap_type = M_AP_NOTHING;
        gy.youmonst.mappearance = 0;
    }

    newsym(u.ux, u.uy);

    urgent_pline(fmt, arg);
    /* check whether player foolishly genocided self while poly'd */
    if (ugenocided()) {
        /* intervening activity might have clobbered genocide info */
        struct kinfo *kptr = find_delayed_killer(POLYMORPH);

        if (kptr != (struct kinfo *) 0 && kptr->name[0]) {
            svk.killer.format = kptr->format;
            Strcpy(svk.killer.name, kptr->name);
        } else {
            svk.killer.format = KILLED_BY;
            Strcpy(svk.killer.name, "self-genocide");
        }
        dealloc_killer(kptr);
        done(GENOCIDED);
    }

    if (!!See_invisible ^ had_see_invis)
        set_mimic_blocking(); /* See_invisible just toggled */

    if (u.twoweap && !could_twoweap(gy.youmonst.data))
        untwoweapon();

    if (u.utrap && u.utraptype == TT_PIT) {
        set_utrap(rn1(6, 2), TT_PIT); /* time to escape resets */
    }
    if (was_blind && !Blind) { /* reverting from eyeless */
        set_itimeout(&HBlinded, 1L);
        make_blinded(0L, TRUE); /* remove blindness */
    }
    check_strangling(TRUE);

    if (!Levitation && !u.ustuck && is_pool_or_lava(u.ux, u.uy))
        spoteffects(TRUE);

    see_monsters();
}

RESTORE_WARNING_FORMAT_NONLITERAL

void
change_sex(void)
{
    /* Some monsters are always of one sex and their sex can't be changed;
     * Succubi/incubi can change, but are handled below.
     *
     * !Upolyd check necessary because is_male() and is_female()
     * may be true for certain roles
     */
    if (!Upolyd
        || (!is_male(gy.youmonst.data) && !is_female(gy.youmonst.data)
            && !is_neuter(gy.youmonst.data)))
        flags.female = !flags.female;
    if (Upolyd) /* poly'd: also change saved sex */
        u.mfemale = !u.mfemale;
    max_rank_sz(); /* [this appears to be superfluous] */
    if ((Upolyd ? u.mfemale : flags.female) && gu.urole.name.f)
        Strcpy(svp.pl_character, gu.urole.name.f);
    else
        Strcpy(svp.pl_character, gu.urole.name.m);
    if (!Upolyd) {
        u.umonnum = u.umonster;
    } else if (u.umonnum == PM_AMOROUS_DEMON) {
        flags.female = !flags.female;
#if 0
        /* change monster type to match new sex; disabled with
           PM_AMOROUS_DEMON */
        u.umonnum = (u.umonnum == PM_SUCCUBUS) ? PM_INCUBUS : PM_SUCCUBUS;
#endif
        set_uasmon();
    }
}

/* log a message if non-poly'd hero's gender has changed */
void
livelog_newform(boolean viapoly, int oldgend, int newgend)
{
    char buf[BUFSZ];
    const char *oldrole, *oldrank, *newrole, *newrank;

    /*
     * TODO?
     *  Give other logging feedback here instead of in newman().
     */

    if (!Upolyd) {
        if (newgend != oldgend) {
            oldrole = (oldgend && gu.urole.name.f) ? gu.urole.name.f
                                                  : gu.urole.name.m;
            newrole = (newgend && gu.urole.name.f) ? gu.urole.name.f
                                                  : gu.urole.name.m;
            oldrank = rank_of(u.ulevel, Role_switch, oldgend);
            newrank = rank_of(u.ulevel, Role_switch, newgend);
            const char *jp_oldrole = jp_role_name_for_display(flags.initrole, oldgend);
            const char *jp_newrole = jp_role_name_for_display(flags.initrole, newgend);
            const char *jp_oldrank = jp_rank_of_for_display(u.ulevel, Role_switch, oldgend);
            const char *jp_newrank = jp_rank_of_for_display(u.ulevel, Role_switch, newgend);

            Sprintf(buf, "%sの%s", newgend ? "女性" : "男性", jp_newrank);
            livelog_printf(LL_MINORAC, "%sに%s",
                           strcmp(jp_newrole, jp_oldrole) ? jp_newrole
                           : strcmp(jp_newrank, jp_oldrank) ? jp_newrank
                             : buf,
                           viapoly ? "ポリモーフした" : "変化した");
        }
    }
}

staticfn void
newman(void)
{
    const char *newform;
    int i, oldlvl, newlvl, oldgend, newgend, hpmax, enmax;

    oldlvl = u.ulevel;
    newlvl = oldlvl + rn1(5, -2);     /* new = old + {-2,-1,0,+1,+2} */
    if (newlvl > 127 || newlvl < 1) { /* level went below 0? */
        goto dead; /* old level is still intact (in case of lifesaving) */
    }
    if (newlvl > MAXULEV)
        newlvl = MAXULEV;
    /* If your level goes down, your peak level goes down by
       the same amount so that you can't simply use blessed
       full healing to undo the decrease.  But if your level
       goes up, your peak level does *not* undergo the same
       adjustment; you might end up losing out on the chance
       to regain some levels previously lost to other causes. */
    if (newlvl < oldlvl)
        u.ulevelmax -= (oldlvl - newlvl);
    if (u.ulevelmax < newlvl)
        u.ulevelmax = newlvl;
    u.ulevel = newlvl;

    oldgend = poly_gender();
    if (gs.sex_change_ok && !rn2(10))
        change_sex();

    adjabil(oldlvl, (int) u.ulevel);

    /* random experience points for the new experience level */
    u.uexp = rndexp(FALSE);

    /* set up new attribute points (particularly Con) */
    redist_attr();

    /*
     * New hit points:
     *  remove "level gain"-based HP from any extra HP accumulated
     *  (the "extra" might actually be negative);
     *  modify the extra, retaining {80%, 90%, 100%, or 110%};
     *  add in newly generated set of level-gain HP.
     *
     * (This used to calculate new HP in direct proportion to old HP,
     * but that was subject to abuse:  accumulate a large amount of
     * extra HP, drain level down to 1, then polyself to level 2 or 3
     * [lifesaving capability needed to handle level 0 and -1 cases]
     * and the extra got multiplied by 2 or 3.  Repeat the level
     * drain and polyself steps until out of lifesaving capability.)
     */
    hpmax = u.uhpmax;
    for (i = 0; i < oldlvl; i++)
        hpmax -= (int) u.uhpinc[i];
    /* hpmax * rn1(4,8) / 10; 0.95*hpmax on average */
    hpmax = rounddiv((long) hpmax * (long) rn1(4, 8), 10);
    for (i = 0; (u.ulevel = i) < newlvl; i++)
        hpmax += newhp();
    if (hpmax < u.ulevel)
        hpmax = u.ulevel; /* min of 1 HP per level */
    /* retain same proportion for current HP; u.uhp * hpmax / u.uhpmax */
    u.uhp = rounddiv((long) u.uhp * (long) hpmax, u.uhpmax);
    setuhpmax(hpmax, TRUE); /* might reduce u.uhp */
    /*
     * Do the same for spell power.
     */
    enmax = u.uenmax;
    for (i = 0; i < oldlvl; i++)
        enmax -= (int) u.ueninc[i];
    enmax = rounddiv((long) enmax * (long) rn1(4, 8), 10);
    for (i = 0; (u.ulevel = i) < newlvl; i++)
        enmax += newpw();
    if (enmax < u.ulevel)
        enmax = u.ulevel;
    u.uen = rounddiv((long) u.uen * (long) enmax,
                     ((u.uenmax < 1) ? 1 : u.uenmax));
    u.uenmax = enmax;
    /* [should alignment record be tweaked too?] */

    u.uhunger = rn1(500, 500);
    if (Sick)
        make_sick(0L, (char *) 0, FALSE, SICK_ALL);
    if (Stoned)
        make_stoned(0L, (char *) 0, 0, (char *) 0);
    if (u.uhp <= 0) {
        if (Polymorph_control) { /* even when Stunned || Unaware */
            if (u.uhp <= 0)
                u.uhp = 1;
        } else {
 dead:      /* we come directly here if experience level went to 0 or less */
            urgent_pline(
                     "Your new form doesn't seem healthy enough to survive.");
            svk.killer.format = KILLED_BY_AN;
            Strcpy(svk.killer.name, "unsuccessful polymorph");
            done(DIED);
            /* must have been life-saved to get here */
            newuhs(FALSE);
            encumber_msg(); /* used to be done by redist_attr() */
            return; /* lifesaved */
        }
    }
    newuhs(FALSE);
    /* use saved gender we're about to revert to, not current */
    newform = ((Upolyd ? u.mfemale : flags.female) && gu.urace.individual.f)
                ? gu.urace.individual.f
                : (gu.urace.individual.m)
                   ? gu.urace.individual.m
                   : gu.urace.noun;
    polyman("You feel like a new %s!", newform);

    newgend = poly_gender();
    /* note: newman() bypasses achievements for new ranks attained and
       doesn't log "new <form>" when that isn't accompanied by level change */
    if (newlvl != oldlvl)
        livelog_printf(LL_MINORAC, "新たな%sとして経験値レベル %d になった",
                       jp_race_noun_for_display(Race_switch), newlvl);
    else
        livelog_newform(TRUE, oldgend, newgend);

    if (Slimed) {
        Your("体は変化したが、粘液はまだ残っている.");
        make_slimed(10L, (const char *) 0);
    }

    disp.botl = TRUE;
    see_monsters();
    encumber_msg();

    retouch_equipment(2);
    if (!uarmg)
        selftouch(no_longer_petrify_resistant);
}

void
polyself(int psflags)
{
    char buf[BUFSZ];
    int old_light, new_light, mntmp, class, tryct, gvariant = NEUTRAL;
    boolean forcecontrol = ((psflags & POLY_CONTROLLED) != 0),
            low_control = ((psflags & POLY_LOW_CTRL) != 0),
            monsterpoly = ((psflags & POLY_MONSTER) != 0),
            formrevert = ((psflags & POLY_REVERT) != 0),
            draconian = (uarm && Is_dragon_armor(uarm)),
            iswere = (ismnum(u.ulycn)),
            isvamp = (is_vampire(gy.youmonst.data)
                      || is_vampshifter(&gy.youmonst)),
            controllable_poly = Polymorph_control && !(Stunned || Unaware);

    if (Unchanging) {
        You("変身に失敗した!");
        return;
    }
    /* being Stunned|Unaware doesn't negate this aspect of Poly_control */
    if (!Polymorph_control && !forcecontrol && !draconian && !iswere
        && !isvamp) {
        if (rn2(20) > ACURR(A_CON)) {
            You1(shudder_for_moment);
            losehp(rnd(30), "システムショック", KILLED_BY_AN);
            exercise(A_CON, FALSE);
            return;
        }
    }
    old_light = emits_light(gy.youmonst.data);
    mntmp = NON_PM;

    if (formrevert) {
        mntmp = gy.youmonst.cham;
        monsterpoly = TRUE;
        controllable_poly = FALSE;
    }

    if (forcecontrol && low_control
        && (draconian || monsterpoly || isvamp || iswere))
        forcecontrol = FALSE;

    if (monsterpoly && isvamp)
        goto do_vampyr;

    if (controllable_poly || forcecontrol) {
        buf[0] = '\0';
        tryct = 5;

        do {
            mntmp = NON_PM;
            getlin("どの種類のモンスターになりますか? [名前を入力してください]", buf);
            (void) mungspaces(buf);
            if (*buf == '\033') {
                /* user is cancelling controlled poly */
                if (forcecontrol) { /* wizard mode #polyself */
                    pline1(Never_mind);
                    return;
                }
                Strcpy(buf, "*"); /* resort to random */
            }
            if (!strcmp(buf, "*") || !strcmp(buf, "random")) {
                /* explicitly requesting random result */
                tryct = 0; /* will skip thats_enough_tries */
                continue;  /* end do-while(--tryct > 0) loop */
            }
            class = 0;
            mntmp = name_to_mon(buf, &gvariant);
            if (mntmp < LOW_PM) {
 by_class:
                class = name_to_monclass(buf, &mntmp);
                if (class && mntmp == NON_PM)
                    mntmp = (draconian && class == S_DRAGON)
                            ? armor_to_dragon(uarm->otyp)
                            : mkclass_poly(class);

            /* placeholder monsters are for corpses and all flagged
               M2_NOPOLY but they are reasonable polymorph targets;
               pick a suitable substitute (which might be geno'd) */
            } else if (is_placeholder(&mons[mntmp])
                       /* when your own race, fall to !polyok() case */
                       && !your_race(&mons[mntmp])
                       /* same for generic human, even if hero isn't human */
                       && mntmp != PM_HUMAN) {
                /* far less general than mkclass() */
                if (mntmp == PM_ORC)
                    mntmp = rn2(3) ? PM_HILL_ORC : PM_MORDOR_ORC;
                else if (mntmp == PM_ELF)
                    mntmp = rn2(3) ? PM_GREEN_ELF : PM_GREY_ELF;
                else if (mntmp == PM_GIANT)
                    mntmp = rn2(3) ? PM_STONE_GIANT : PM_HILL_GIANT;
                /* note: PM_DWARF and PM_GNOME are ordinary monsters and
                   no longer flagged no-poly so have no need for placeholder
                   handling; PM_HUMAN is a placeholder without a suitable
                   substitute so gets handled differently below */
            }

            if (mntmp < LOW_PM) {
                if (!class)
                    pline("そんなモンスターは聞いたことがない.");
                else
                    You_cant("そのいずれにもポリモーフすることはできなかった。");
            } else if (wizard && Upolyd
                       && (mntmp == u.umonster
                           /* "priest" and "priestess" match the monster
                              rather than the role; override that unless
                              the text explicitly contains "aligned" */
                           || (u.umonster == PM_CLERIC
                               && mntmp == PM_ALIGNED_CLERIC
                               && !strstri(buf, "aligned")))) {
                /* in wizard mode, picking own role while poly'd reverts to
                   normal without newman()'s chance of level or sex change */
                rehumanize();
                old_light = 0; /* rehumanize() extinguishes u-as-mon light */
                goto made_change;
            } else if (iswere && (were_beastie(mntmp) == u.ulycn
                                  || mntmp == counter_were(u.ulycn)
                                  || (Upolyd && mntmp == PM_HUMAN))) {
                goto do_shift;
            } else if (!polyok(&mons[mntmp])
                       /* Note:  humans are illegal as monsters, but an
                          illegal monster forces newman(), which is what
                          we want if they specified a human.... (unless
                          they specified a unique monster) */
                       && !(mntmp == PM_HUMAN
                            || (your_race(&mons[mntmp])
                                && (mons[mntmp].geno & G_UNIQ) == 0)
                            || mntmp == gu.urole.mnum)) {
                const char *pm_name;

                /* mkclass_poly() can pick a !polyok()
                   candidate; if so, usually try again */
                if (class) {
                    if (rn2(3) || --tryct > 0)
                        goto by_class;
                    /* no retries left; put one back on counter
                       so that end of loop decrement will yield
                       0 and trigger thats_enough_tries message */
                    ++tryct;
                }
                pm_name = jp_pmname(&mons[mntmp], flags.female ? FEMALE : MALE);
                if (the_unique_pm(&mons[mntmp]))
                    pm_name = the(pm_name);
                else if (!type_is_pname(&mons[mntmp]))
                    pm_name = an(pm_name);
                You_cant("%sにポリモーフすることはできなかった。", pm_name);
            } else
                break;
        } while (--tryct > 0);

        if (!tryct)
            pline1(thats_enough_tries);
        /* allow skin merging, even when polymorph is controlled */
        if (draconian && (tryct <= 0 || mntmp == armor_to_dragon(uarm->otyp)))
            goto do_merge;
        if (isvamp && (tryct <= 0 || mntmp == PM_WOLF || mntmp == PM_FOG_CLOUD
                       || is_bat(&mons[mntmp])))
            goto do_vampyr;
    } else if (draconian || iswere || isvamp) {
        /* special changes that don't require polyok() */
        if (draconian) {
 do_merge:
            mntmp = armor_to_dragon(uarm->otyp);
            if (!(svm.mvitals[mntmp].mvflags & G_GENOD)) {
                unsigned was_lit = uarm->lamplit;
                int arm_light = artifact_light(uarm) ? arti_light_radius(uarm)
                                                     : 0;

                /* allow G_EXTINCT */
                if (Is_dragon_scales(uarm)) {
                    /* dragon scales remain intact as uskin */
                    You("鱗の鎧と融合した.");
                } else { /* dragon scale mail reverts to scales */
                    /* similar to noarmor(invent.c),
                       shorten to "<color> scale mail" */
                    Strcpy(buf, simpleonames(uarm));
                    strsubst(buf, " dragon ", " ");
                    /* tricky phrasing; dragon scale mail is singular, dragon
                       scales are plural (note: we don't use "set of scales",
                       which usually overrides the distinction, here) */
                    Your("%sは融合に伴って鱗へ戻った.", buf);
                    /* uarm->spe enchantment remains unchanged;
                       re-converting scales to mail poses risk
                       of evaporation due to over enchanting */
                    uarm->otyp += GRAY_DRAGON_SCALES - GRAY_DRAGON_SCALE_MAIL;
                    observe_object(uarm);
                    disp.botl = TRUE; /* AC is changing */
                }
                uskin = uarm;
                uarm = (struct obj *) 0;
                /* save/restore hack */
                uskin->owornmask |= I_SPECIAL;
                if (was_lit)
                    maybe_adjust_light(uskin, arm_light);
                update_inventory();
            }
        } else if (iswere) {
 do_shift:
            if (Upolyd && were_beastie(mntmp) != u.ulycn)
                mntmp = PM_HUMAN; /* Illegal; force newman() */
            else
                mntmp = u.ulycn;
        } else if (isvamp) {
 do_vampyr:
            if (mntmp < LOW_PM || (mons[mntmp].geno & G_UNIQ)) {
                mntmp = (gy.youmonst.data == &mons[PM_VAMPIRE_LEADER]
                         && !rn2(10)) ? PM_WOLF
                                      : !rn2(4) ? PM_FOG_CLOUD
                                                : PM_VAMPIRE_BAT;
                if (ismnum(gy.youmonst.cham)
                    && !is_vampire(gy.youmonst.data) && !rn2(2))
                    mntmp = gy.youmonst.cham;
            }
            if (controllable_poly) {
                Sprintf(buf, "%sになりますか?",
                        jp_pmname(&mons[mntmp], gvariant));
                if (y_n(buf) != 'y')
                    return;
            }
        }
        /* if polymon fails, "you feel" message has been given
           so don't follow up with another polymon or newman;
           sex_change_ok left disabled here */
        if (mntmp == PM_HUMAN)
            newman(); /* werecritter */
        else
            (void) polymon(mntmp);
        goto made_change; /* maybe not, but this is right anyway */
    }

    if (mntmp < LOW_PM) {
        tryct = 200;
        do {
            /* randomly pick an "ordinary" monster */
            mntmp = rn1(SPECIAL_PM - LOW_PM, LOW_PM);
            if (polyok(&mons[mntmp]) && !is_placeholder(&mons[mntmp]))
                break;
        } while (--tryct > 0);
    }

    /* The below polyok() fails either if everything is genocided, or if
     * we deliberately chose something illegal to force newman().
     */
    gs.sex_change_ok++;
    if (!polyok(&mons[mntmp]) || (!forcecontrol && !rn2(5))
        || your_race(&mons[mntmp])) {
        newman();
    } else {
        (void) polymon(mntmp);
    }
    gs.sex_change_ok--; /* reset */

 made_change:
    new_light = emits_light(gy.youmonst.data);
    if (old_light != new_light) {
        if (old_light)
            del_light_source(LS_MONSTER, monst_to_any(&gy.youmonst));
        if (new_light == 1)
            ++new_light; /* otherwise it's undetectable */
        if (new_light)
            new_light_source(u.ux, u.uy, new_light, LS_MONSTER,
                             monst_to_any(&gy.youmonst));
    }
}

/* (try to) make a mntmp monster out of the player; return 1 if successful */
int
polymon(int mntmp)
{
    char buf[BUFSZ], ustuckNam[BUFSZ];
    boolean sticking = sticks(gy.youmonst.data) && u.ustuck && !u.uswallow,
            was_blind = !!Blind, dochange = FALSE, was_expelled = FALSE,
            was_hiding_under = u.uundetected && hides_under(gy.youmonst.data);
    int mlvl, newMaxStr;

    if (svm.mvitals[mntmp].mvflags & G_GENOD) { /* allow G_EXTINCT */
        You_feel("少し%sっぽい気がした.",
                 jp_pmname(&mons[mntmp], flags.female ? FEMALE : MALE));
        exercise(A_WIS, TRUE);
        return 0;
    }

    /* KMH, conduct */
    if (!u.uconduct.polyselfs++)
        livelog_printf(LL_CONDUCT,
                       "初めて姿を変え、%sになった",
                       jp_pmname(&mons[mntmp], flags.female ? FEMALE : MALE));

    /* exercise used to be at the very end but only Wis was affected
       there since the polymorph was always in effect by then */
    exercise(A_CON, FALSE);
    exercise(A_WIS, TRUE);

    if (!Upolyd) {
        /* Human to monster; save human stats */
        u.macurr = u.acurr;
        u.mamax = u.amax;
        u.mfemale = flags.female;
    } else {
        /* Monster to monster; restore human stats, to be
         * immediately changed to provide stats for the new monster
         */
        u.acurr = u.macurr;
        u.amax = u.mamax;
        flags.female = u.mfemale;
    }

    /* if stuck mimicking gold, stop immediately */
    if (gm.multi < 0 && U_AP_TYPE == M_AP_OBJECT
        && gy.youmonst.data->mlet != S_MIMIC)
        unmul("");
    /* if becoming a non-mimic, stop mimicking anything */
    if (mons[mntmp].mlet != S_MIMIC) {
        /* as in polyman() */
        gy.youmonst.m_ap_type = M_AP_NOTHING;
        gy.youmonst.mappearance = 0;
    }
    if (is_male(&mons[mntmp])) {
        if (flags.female)
            dochange = TRUE;
    } else if (is_female(&mons[mntmp])) {
        if (!flags.female)
            dochange = TRUE;
    } else if (!is_neuter(&mons[mntmp]) && mntmp != u.ulycn) {
        if (gs.sex_change_ok && !rn2(10))
            dochange = TRUE;
    }

    Strcpy(ustuckNam, u.ustuck ? Some_Monnam(u.ustuck) : "");

    Strcpy(buf, (u.umonnum != mntmp) ? "" : "new ");
    if (dochange) {
        flags.female = !flags.female;
        Strcat(buf, (is_male(&mons[mntmp]) || is_female(&mons[mntmp]))
                       ? "" : flags.female ? "メスの" : "オスの");
    }
    Strcat(buf, jp_pmname(&mons[mntmp], flags.female ? FEMALE : MALE));
    pline("あなたは%sに%s!", buf, (u.umonnum != mntmp) ? "変身した" : "変身する気がした");

    if (Stoned && poly_when_stoned(&mons[mntmp])) {
        /* poly_when_stoned already checked stone golem genocide */
        mntmp = PM_STONE_GOLEM;
        make_stoned(0L, "You turn to stone!", 0, (char *) 0);
    }

    u.mtimedone = rn1(500, 500);
    u.umonnum = mntmp;
    set_uasmon();

    /* New stats for monster, to last only as long as polymorphed.
     * Currently only strength gets changed.
     */
    newMaxStr = uasmon_maxStr();
    if (strongmonst(&mons[mntmp])) {
        ABASE(A_STR) = AMAX(A_STR) = (schar) newMaxStr;
    } else {
        /* not a strongmonst(); if hero has exceptional strength, remove it
           (note: removal is temporary until returning to original form);
           we don't attempt to enforce lower maximum for wimpy forms;
           unlike for strongmonst, current strength does not get set to max */
        AMAX(A_STR) = (schar) newMaxStr;
        /* make sure current is not higher than max (strip exceptional Str) */
        if (ABASE(A_STR) > AMAX(A_STR))
            ABASE(A_STR) = AMAX(A_STR);
    }

    if (Stone_resistance && Stoned) { /* parnes@eniac.seas.upenn.edu */
        make_stoned(0L, "石化が止まったようだ.", 0,
                    (char *) 0);
    }
    if (Sick_resistance && Sick) {
        make_sick(0L, (char *) 0, FALSE, SICK_ALL);
        You("もう気分は悪くなかった.");
    }
    if (Slimed) {
        if (flaming(gy.youmonst.data)) {
            make_slimed(0L, "体を覆うスライムは焼き払われた!");
        } else if (mntmp == PM_GREEN_SLIME) {
            /* do it silently */
            make_slimed(0L, (char *) 0);
        }
    }
    check_strangling(FALSE); /* maybe stop strangling */
    if (nohands(gy.youmonst.data))
        make_glib(0);

    /*
    mlvl = adj_lev(&mons[mntmp]);
     * We can't do the above, since there's no such thing as an
     * "experience level of you as a monster" for a polymorphed character.
     */
    mlvl = (int) mons[mntmp].mlevel;
    if (gy.youmonst.data->mlet == S_DRAGON && mntmp >= PM_GRAY_DRAGON) {
        u.mhmax = In_endgame(&u.uz) ? (8 * mlvl) : (4 * mlvl + d(mlvl, 4));
    } else if (is_golem(gy.youmonst.data)) {
        u.mhmax = golemhp(mntmp);
    } else {
        if (!mlvl)
            u.mhmax = rnd(4);
        else
            u.mhmax = d(mlvl, 8);
        if (is_home_elemental(&mons[mntmp]))
            u.mhmax *= 3;
    }
    u.mh = u.mhmax;

    if (u.ulevel < mlvl) {
        /* Low level characters can't become high level monsters for long */
#ifdef DUMB
        /* DRS/NS 2.2.6 messes up -- Peter Kendell */
        int mtd = u.mtimedone, ulv = u.ulevel;

        u.mtimedone = mtd * ulv / mlvl;
#else
        u.mtimedone = u.mtimedone * u.ulevel / mlvl;
#endif
    }

    if (uskin && mntmp != armor_to_dragon(uskin->otyp))
        skinback(FALSE);
    break_armor();
    drop_weapon(1);
    find_ac(); /* (repeated below) */
    /* if hiding under something and can't hide anymore, unhide now;
       but don't auto-hide when not already hiding-under */
    if (was_hiding_under)
        (void) hideunder(&gy.youmonst);

    if (u.utrap && u.utraptype == TT_PIT) {
        set_utrap(rn1(6, 2), TT_PIT); /* time to escape resets */
    }
    if (was_blind && !Blind) { /* previous form was eyeless */
        set_itimeout(&HBlinded, 1L);
        make_blinded(0L, TRUE); /* remove blindness */
    }
    newsym(u.ux, u.uy); /* Change symbol */

    /* you now know what an egg of your type looks like; [moved from
       below in case expels() -> spoteffects() drops hero onto any eggs] */
    if (lays_eggs(gy.youmonst.data)) {
        learn_egg_type(u.umonnum);
        /* make queen bees recognize killer bee eggs */
        learn_egg_type(egg_type_from_parent(u.umonnum, TRUE));
    }

    if (u.uswallow) {
        uchar usiz;

        /* if new form can't be swallowed, make engulfer expel hero */
        if (unsolid(gy.youmonst.data)
            /* subset of engulf_target() */
            || (usiz = gy.youmonst.data->msize) >= MZ_HUGE
            || (u.ustuck->data->msize < usiz && !is_whirly(u.ustuck->data))) {
            boolean expels_mesg = TRUE;

            if (unsolid(gy.youmonst.data)) {
                if (canspotmon(u.ustuck)) /* [see below for explanation] */
                    Strcpy(ustuckNam, Monnam(u.ustuck));
                pline("%sはもうあなたを飲み込んでおけない.", ustuckNam);
                expels_mesg = FALSE;
            }
            expels(u.ustuck, u.ustuck->data, expels_mesg);
            was_expelled = TRUE;
            /* FIXME? if expels() triggered rehumanize then we should
               return early */
        }

    /* [note:  this 'sticking' handling is only sufficient for changing from
       grabber to engulfer or vice versa because engulfing by poly'd hero
       always ends immediately so won't be in effect during a polymorph] */
    } else if (u.ustuck && !sticking /* && !u.uswallow */
               /* being held; if now capable of holding, make holder
                  release so that hero doesn't automagically start holding
                  it; or, release if no longer capable of being held */
               && (sticks(gy.youmonst.data) || unsolid(gy.youmonst.data))) {
        /* u.ustuck name was saved above in case we're changing from can-see
           to can't-see; but might have changed from can't-see to can-see so
           override here if hero knows who u.ustuck is */
        if (canspotmon(u.ustuck))
            Strcpy(ustuckNam, Monnam(u.ustuck));
        set_ustuck((struct monst *) 0);
        pline("%sはあなたを放した.", ustuckNam);
    } else if (sticking && !sticks(gy.youmonst.data)) {
        /* was holding onto u.ustuck but no longer capable of that */
        uunstick();
    }

    if (u.usteed) {
        if (touch_petrifies(u.usteed->data) && !Stone_resistance && rnl(3)) {
            pline("%sが%sに触れた.", no_longer_petrify_resistant,
                  mon_nam(u.usteed));
            Sprintf(buf, "riding %s",
                    an(pmname(u.usteed->data, Mgender(u.usteed))));
            instapetrify(buf);
        }
        if (!can_ride(u.usteed))
            dismount_steed(DISMOUNT_POLY);
    }

    find_ac();
    if (((!Levitation && !u.ustuck && !Flying && is_pool_or_lava(u.ux, u.uy))
         || (Underwater && !Swimming))
        /* if expelled above, expels() already called spoteffects() */
        && !was_expelled) {
        spoteffects(TRUE);
        /* FIXME? if spoteffects() triggered rehumanize then we should
           return early */
    }
    if (Passes_walls && u.utrap
        && (u.utraptype == TT_INFLOOR || u.utraptype == TT_BURIEDBALL)) {
        if (u.utraptype == TT_INFLOOR) {
            pline_The("岩はもはやあなたを閉じ込めていないようだ.");
        } else {
            pline_The("埋まった鉄球はもはやあなたにつながれていない.");
            buried_ball_to_freedom();
        }
        reset_utrap(TRUE);
    } else if (likes_lava(gy.youmonst.data) && u.utrap
               && u.utraptype == TT_LAVA) {
        pline_The("%sは心地よく感じられる.", hliquid("lava"));
        reset_utrap(TRUE);
    }
    if (amorphous(gy.youmonst.data) || is_whirly(gy.youmonst.data)
        || unsolid(gy.youmonst.data)) {
        if (Punished) {
            You("鉄の鎖からすり抜けた.");
            unpunish();
        } else if (u.utrap && u.utraptype == TT_BURIEDBALL) {
            You("埋まった鉄球と鎖からすり抜けた.");
            buried_ball_to_freedom();
        }
    }
    if (u.utrap && (u.utraptype == TT_WEB || u.utraptype == TT_BEARTRAP)
        && (amorphous(gy.youmonst.data) || is_whirly(gy.youmonst.data)
            || unsolid(gy.youmonst.data)
            || (gy.youmonst.data->msize <= MZ_SMALL
                && u.utraptype == TT_BEARTRAP))) {
        You("もう%sにはまっていなかった.",
            u.utraptype == TT_WEB ? "web" : "bear trap");
        /* probably should burn webs too if PM_FIRE_ELEMENTAL */
        reset_utrap(TRUE);
    }
    if (webmaker(gy.youmonst.data) && u.utrap && u.utraptype == TT_WEB) {
        You("蜘蛛の巣の上で体勢を立て直した.");
        reset_utrap(TRUE);
    }
    check_strangling(TRUE); /* maybe start strangling */

    disp.botl = TRUE;
    gv.vision_full_recalc = 1;
    see_monsters();
    encumber_msg();

    retouch_equipment(2);
    /* this might trigger a recursive call to polymon() [stone golem
       wielding cockatrice corpse and hit by stone-to-flesh, becomes
       flesh golem above, now gets transformed back into stone golem;
       fortunately neither form uses #monster] */
    if (!uarmg)
        selftouch(no_longer_petrify_resistant);

    /* the explanation of '#monster' used to be shown sooner, but there are
       possible fatalities above and it isn't useful unless hero survives */
    if (flags.verbose) {
        static const char use_thec[] = "コマンド#%sで%sことができる.";
        static const char monsterc[] = "monster";
        struct permonst *uptr = gy.youmonst.data;
        boolean might_hide = (is_hider(uptr) || hides_under(uptr));

        if (can_breathe(uptr))
            pline(use_thec, monsterc, "ブレスを吐く");
        if (attacktype(uptr, AT_SPIT))
            pline(use_thec, monsterc, "毒を吐く");
        if (uptr->mlet == S_NYMPH)
            pline(use_thec, monsterc, "鉄球を外す");
        if (attacktype(uptr, AT_GAZE))
            pline(use_thec, monsterc, "モンスターを睨みつける");
        if (might_hide && webmaker(uptr))
            pline(use_thec, monsterc, "隠れたり巣を張ったりする");
        else if (might_hide)
            pline(use_thec, monsterc, "隠れる");
        else if (webmaker(uptr))
            pline(use_thec, monsterc, "巣を張る");
        if (is_were(uptr))
            pline(use_thec, monsterc, "仲間を呼ぶ");
        if (u.umonnum == PM_GREMLIN)
            pline(use_thec, monsterc, "噴水で増殖する");
        if (is_unicorn(uptr))
            pline(use_thec, monsterc, "角を使う");
        if (is_mind_flayer(uptr))
            pline(use_thec, monsterc, "精神波を放つ");
        if (uptr->msound == MS_SHRIEK) /* worthless, actually */
            pline(use_thec, monsterc, "悲鳴を上げる");
        if (is_vampire(uptr) || is_vampshifter(&gy.youmonst))
            pline(use_thec, monsterc, "姿を変える");

        if (lays_eggs(uptr) && flags.female
            && !(uptr == &mons[PM_GIANT_EEL]
                 || uptr == &mons[PM_ELECTRIC_EEL]))
            pline(use_thec, "sit",
                  eggs_in_water(uptr) ? "水中で産卵する" : "卵を産む");
    }
    return 1;
}

/* determine hero's temporary strength value used while polymorphed;
   hero poly'd into M2_STRONG monster usually gets 18/100 strength but
   there are exceptions; non-M2_STRONG get maximum strength set to 18 */
schar
uasmon_maxStr(void)
{
    const struct Race *R;
    int newMaxStr;
    int mndx = u.umonnum;
    struct permonst *ptr = &mons[mndx];

    if (is_orc(ptr)) {
        if (mndx != PM_URUK_HAI && mndx != PM_ORC_CAPTAIN)
            mndx = PM_ORC;
    } else if (is_elf(ptr)) {
        mndx = PM_ELF;
    } else if (is_dwarf(ptr)) {
        mndx = PM_DWARF;
    } else if (is_gnome(ptr)) {
        mndx = PM_GNOME;
#if 0   /* use the mons[] value for humans */
    } else if (is_human(ptr)) {
        mndx = PM_HUMAN;
#endif
    }
    R = character_race(mndx);

    if (strongmonst(ptr)) {
        /* ettins, titans and minotaurs don't pass the is_giant() test;
           giant mummies and giant zombies do but we throttle those */
        boolean live_H = is_giant(ptr) && !is_undead(ptr);

        /* hero orcs are limited to 18/50 for maximum strength, so treat
           hero poly'd into an orc the same; goblins, orc shamans, and orc
           zombies don't have strongmonst() attribute so won't get here;
           hobgoblins and orc mummies do get here and are limited to 18/50
           like normal orcs; however, orc captains and Uruk-hai retain 18/100
           strength; hero gnomes are also limited to 18/50; hero elves are
           limited to 18/00 regardless of whether they're strongmonst, but
           the two strongmonst types (monarchs and nobles) have current
           strength set to 18 [by polymon()], the others don't */
        newMaxStr = R ? R->attrmax[A_STR] : live_H ? STR19(19) : STR18(100);
    } else {
        newMaxStr = R ? R->attrmax[A_STR] : 18; /* 18 is same as STR18(0) */
    }
    return (schar) newMaxStr;
}

/* dropx() jacket for break_armor() */
staticfn void
dropp(struct obj *obj)
{
    struct obj *otmp;

    /*
     * Dropping worn armor while polymorphing might put hero into water
     * (loss of levitation boots or water walking boots that the new
     * form can't wear), where emergency_disrobe() could remove it from
     * inventory.  Without this, dropx() could trigger an 'object lost'
     * panic.  Right now, boots are the only armor which might encounter
     * this situation, but handle it for all armor.
     *
     * Hypothetically, 'obj' could have merged with something (not
     * applicable for armor) and no longer be a valid pointer, so scan
     * inventory for it instead of trusting obj->where.
     */
    for (otmp = gi.invent; otmp; otmp = otmp->nobj) {
        if (otmp == obj) {
            dropx(obj);
            /* Note that otmp->nobj is pointing at fobj now,
             * as a result of:
             * dropx() -> dropy() -> dropz() -> place_object(),
             * and no longer pointing at the next obj in inventory.
             * That would be an issue if this loop were allowed
             * to continue, but the break statement that
             * follows prevents the loop from continuing on with
             * objects on the floor.
             */
            break;
        }
    }
}

staticfn void
break_armor(void)
{
    struct obj *otmp;
    struct permonst *uptr = gy.youmonst.data;

    if (breakarm(uptr)) {
        if ((otmp = uarm) != 0) {
            if (donning(otmp))
                cancel_don();
            /* for gold DSM, we don't want Armor_gone() to report that it
               stops shining _after_ we've been told that it is destroyed */
            if (otmp->lamplit)
                end_burn(otmp, FALSE);

            You("鎧を突き破った!");
            exercise(A_STR, FALSE);
            (void) Armor_gone();
            useup(otmp);
        }
        if ((otmp = uarmc) != 0
            /* mummy wrapping adapts to small and very big sizes */
            && (otmp->otyp != MUMMY_WRAPPING || !WrappingAllowed(uptr))) {
            if (otmp->otyp == MUMMY_WRAPPING) {
                /* doesn't have a clasp to break open */
                Your("%sは引き裂けた!", cloak_simple_name(otmp));
                (void) Cloak_off();
                useup(otmp);
            } else if (otmp->otyp == ALCHEMY_SMOCK) {
                pline_The("あなたの%sの結び目はほどけた!", cloak_simple_name(otmp));
                (void) Cloak_off();
                dropp(otmp);
            } else {
                pline_The("あなたの%sの留め金が外れた!", cloak_simple_name(otmp));
                (void) Cloak_off();
                dropp(otmp);
            }
        }
        if (uarmu) {
            Your("シャツはずたずたに裂けた!");
            useup(uarmu);
        }
    } else if (sliparm(uptr)) {
        if ((otmp = uarm) != 0 && racial_exception(&gy.youmonst, otmp) < 1) {
            if (donning(otmp))
                cancel_don();
            Your("鎧は体から外れて落ちた!");
            /* [note: _gone() instead of _off() dates to when life-saving
               could force fire resisting armor back on if hero burned in
               hell (3.0, predating Gehennom); the armor isn't actually
               gone here but also isn't available to be put back on] */
            (void) Armor_gone();
            dropp(otmp);
        }
        if ((otmp = uarmc) != 0
            /* mummy wrapping adapts to small and very big sizes */
            && (otmp->otyp != MUMMY_WRAPPING || !WrappingAllowed(uptr))) {
            if (is_whirly(uptr))
                Your("%sは支えを失って落ちた!", cloak_simple_name(otmp));
            else
                You("%sがぶかぶかになって抜け落ちた!", cloak_simple_name(otmp));
            (void) Cloak_off();
            dropp(otmp);
        }
        if ((otmp = uarmu) != 0) {
            if (is_whirly(uptr))
                You("シャツをすり抜けた!");
            else
                You("シャツには大きさが合わなくなった!");
            setworn((struct obj *) 0, otmp->owornmask & W_ARMU);
            dropp(otmp);
        }
    }
    if (has_horns(uptr)) {
        if ((otmp = uarmh) != 0) {
            if (is_flimsy(otmp) && !donning(otmp)) {
                char hornbuf[BUFSZ];

                /* Future possibilities: This could damage/destroy helmet */
                /* NetHackJP: Sprintf hornbuf to "角" instead of "horn(s)" to make it Japanese */
                Sprintf(hornbuf, "角");
                                Your("%sが%sを%s.", hornbuf, xname(otmp), "突き破った");
            } else {
                if (donning(otmp))
                    cancel_don();
                 Your("%sは%sへ落ちた!", helm_simple_name(otmp),
                     surface(u.ux, u.uy));
                (void) Helmet_off();
                dropp(otmp);
            }
        }
    }
    if (nohands(uptr) || verysmall(uptr)) {
        if ((otmp = uarmg) != 0) {
            if (donning(otmp))
                cancel_don();
            /* Drop weapon along with gloves */
            You("手袋%sを落とした!", uwep ? "と武器" : "");
            drop_weapon(0);
            (void) Gloves_off();
            /* Glib manipulation (ends immediately) handled by Gloves_off */
            dropp(otmp);
        }
        if ((otmp = uarms) != 0) {
            You("盾を持てなくなった!");
            (void) Shield_off();
            dropp(otmp);
        }
        if ((otmp = uarmh) != 0) {
            if (donning(otmp))
                cancel_don();
              Your("%sは%sへ落ちた!", helm_simple_name(otmp),
                 surface(u.ux, u.uy));
            (void) Helmet_off();
            dropp(otmp);
        }
    }
    if (nohands(uptr) || verysmall(uptr)
        || slithy(uptr) || uptr->mlet == S_CENTAUR) {
        if ((otmp = uarmf) != 0) {
            if (donning(otmp))
                cancel_don();
            if (is_whirly(uptr))
                Your("ブーツは外れて落ちた!");
            else
                 Your("ブーツは足から%s!",
                     verysmall(uptr) ? "滑り落ちた" : "押し出された");
            (void) Boots_off();
            dropp(otmp);
        }
    }
    /* not armor, but eyewear shouldn't stay worn without a head to wear
       it/them on (should also come off if head is too tiny or too huge,
       but putting accessories on doesn't reject those cases [yet?]);
       amulet stays worn */
    if ((otmp = ublindf) != 0 && !has_head(uptr)) {
        int l;
        const char *eyewear = simpleonames(otmp); /* blindfold|towel|lenses */

        if (!strncmp(eyewear, "pair of ", l = 8)) /* lenses */
            eyewear += l;
        Your("%sは外れ落ちた!", eyewear);
        (void) Blindf_off((struct obj *) 0); /* Null: skip usual off mesg */
        dropp(otmp);
    }
    /* rings stay worn even when no hands */
}

staticfn void
drop_weapon(int alone)
{
    struct obj *otmp;
    const char *what, *which, *whichtoo;
    boolean candropwep, candropswapwep, updateinv = TRUE;

    if (uwep) {
        /* !alone check below is currently superfluous but in the
         * future it might not be so if there are monsters which cannot
         * wear gloves but can wield weapons
         */
        if (!alone || cantwield(gy.youmonst.data)) {
            candropwep = canletgo(uwep, "");
            candropswapwep = !u.twoweap || canletgo(uswapwep, "");
            if (alone) {
                what = (candropwep && candropswapwep) ? "落とす" : "手放す";
                which = is_sword(uwep) ? "sword" : weapon_descr(uwep);
                if (u.twoweap) {
                    whichtoo =
                        is_sword(uswapwep) ? "sword" : weapon_descr(uswapwep);
                    if (strcmp(which, whichtoo))
                        which = "weapon";
                }
                if (uwep->quan != 1L || u.twoweap)
                    which = makeplural(which);

                You("%s%sを%s必要があることに気づいた!",
                    the_your[!!strncmp(which, "corpse", 6)], which, what);
            }
            /* if either uwep or wielded uswapwep is flagged as 'in_use'
               then don't drop it or explicitly update inventory; leave
               those actions to caller (or caller's caller, &c) */
            if (u.twoweap) {
                otmp = uswapwep;
                uswapwepgone();
                if (otmp->in_use)
                    updateinv = FALSE;
                else if (candropswapwep)
                    dropx(otmp);
            }
            otmp = uwep;
            uwepgone();
            if (otmp->in_use)
                updateinv = FALSE;
            else if (candropwep)
                dropx(otmp);
            /* [note: dropp vs dropx -- if heart of ahriman is wielded, we
               might be losing levitation by dropping it; but that won't
               happen until the drop, unlike Boots_off() dumping hero into
               water and triggering emergency_disrobe() before dropx()] */

            if (updateinv)
                update_inventory();
        } else if (!could_twoweap(gy.youmonst.data)) {
            untwoweapon();
        }
    }
}

/* return to original form, usually either due to polymorph timing out
   or dying from loss of hit points while being polymorphed */
void
rehumanize(void)
{
    boolean was_flying = (Flying != 0);

    /* You can't revert back while unchanging */
    if (Unchanging) {
        if (u.mh < 1) {
            svk.killer.format = NO_KILLER_PREFIX;
            Strcpy(svk.killer.name, "killed while stuck in creature form");
            done(DIED);
            /* can get to here if declining to die in explore or wizard
               mode; since we're wearing an amulet of unchanging we can't
               be wearing an amulet of life-saving */
            return; /* don't rehumanize after all */
        } else if (uamul && uamul->otyp == AMULET_OF_UNCHANGING) {
            Your("%sは効かなかった!", simpleonames(uamul));
            observe_object(uamul);
            makeknown(AMULET_OF_UNCHANGING);
        }
    }

    /*
     * Right now, dying while being a shifted vampire (bat, cloud, wolf)
     * reverts to human rather than to vampire.
     */

    if (emits_light(gy.youmonst.data))
        del_light_source(LS_MONSTER, monst_to_any(&gy.youmonst));
    polyman("You return to %s form!", gu.urace.adj);

    if (u.uhp < 1) {
        /* can only happen if some bit of code reduces u.uhp
           instead of u.mh while poly'd */
        Your("元の姿は生き延びるには健全ではなかった.");
        Sprintf(svk.killer.name, "reverting to unhealthy %s form",
                gu.urace.adj);
        svk.killer.format = KILLED_BY;
        done(DIED);
    }
    nomul(0);

    disp.botl = TRUE;
    gv.vision_full_recalc = 1;
    encumber_msg();
    update_inventory();
    if (was_flying && !Flying && u.usteed)
        You("そして%sと一緒にそっと%sへ戻った.",
            l_monnam(u.usteed), surface(u.ux, u.uy));
    retouch_equipment(2);
    if (!uarmg)
        selftouch(no_longer_petrify_resistant);
}

int
dobreathe(void)
{
    struct attack *mattk;

    if (Strangled) {
        You_cant("呼吸することはできなかった。申し訳ない。");
        return ECMD_OK;
    }
    if (u.uen < 15) {
        You("呼吸するだけのエネルギーがなかった!");
        return ECMD_OK;
    }
    u.uen -= 15;
    disp.botl = TRUE;

    if (!getdir((char *) 0))
        return ECMD_CANCEL;

    mattk = attacktype_fordmg(gy.youmonst.data, AT_BREA, AD_ANY);
    if (!mattk)
        impossible("bad breath attack?"); /* mouthwash needed... */
    else if (!u.dx && !u.dy && !u.dz)
        ubreatheu(mattk);
    else
        ubuzz(BZ_U_BREATH(BZ_OFS_AD(mattk->adtyp)), (int) mattk->damn);
    return ECMD_TIME;
}

int
dospit(void)
{
    struct obj *otmp;
    struct attack *mattk;

    if (!getdir((char *) 0))
        return ECMD_CANCEL;
    mattk = attacktype_fordmg(gy.youmonst.data, AT_SPIT, AD_ANY);
    if (!mattk) {
        impossible("bad spit attack?");
    } else {
        switch (mattk->adtyp) {
        case AD_BLND:
        case AD_DRST:
            otmp = mksobj(BLINDING_VENOM, TRUE, FALSE);
            break;
        default:
            impossible("bad attack type in dospit");
            FALLTHROUGH;
            /*FALLTHRU*/
        case AD_ACID:
            otmp = mksobj(ACID_VENOM, TRUE, FALSE);
            break;
        }
        otmp->spe = 1; /* to indicate it's yours */
        throwit(otmp, 0L, FALSE, (struct obj *) 0);
    }
    return ECMD_TIME;
}

int
doremove(void)
{
    if (!Punished) {
        if (u.utrap && u.utraptype == TT_BURIEDBALL) {
            pline_The("鉄球と鎖は%sに深く埋まっている.",
                      surface(u.ux, u.uy));
            return ECMD_OK;
        }
        You("何にも鎖でつながれていなかった!");
        return ECMD_OK;
    }
    unpunish();
    return ECMD_TIME;
}

int
dospinweb(void)
{
    coordxy x = u.ux, y = u.uy;
    struct trap *ttmp = t_at(x, y);
    /* disallow webs on water, lava, air & cloud */
    boolean reject_terrain = is_pool_or_lava(x, y) || IS_AIR(levl[x][y].typ);

    /* [at the time this was written, it was not possible to be both a
       webmaker and a flyer, but with the advent of amulet of flying that
       became a possibility; at present hero can spin a web while flying] */
    if (Levitation || reject_terrain) {
        You("蜘蛛の巣を張るには%s地面にいる必要があった.",
            reject_terrain ? "しっかりした" : "その");
        return ECMD_OK;
    }
    if (u.uswallow) {
        You("%sの中で蜘蛛の糸を吐き出した.", l_monnam(u.ustuck));
        if (is_animal(u.ustuck->data)) {
            expels(u.ustuck, u.ustuck->data, TRUE);
            return ECMD_OK;
        }
        if (is_whirly(u.ustuck->data)) {
            int i;

            for (i = 0; i < NATTK; i++)
                if (u.ustuck->data->mattk[i].aatyp == AT_ENGL)
                    break;
            if (i == NATTK)
                impossible("Swallower has no engulfing attack?");
            else {
                char sweep[64]; /* NetHackJP: expanded for localized text */

                sweep[0] = '\0';
                switch (u.ustuck->data->mattk[i].adtyp) {
                case AD_FIRE:
                    Strcpy(sweep, "ignites and ");
                    break;
                case AD_ELEC:
                    Strcpy(sweep, "fries and ");
                    break;
                case AD_COLD:
                    Strcpy(sweep, "freezes, shatters and ");
                    break;
                }
                pline_The("蜘蛛の巣は%s流された!", sweep);
            }
            return ECMD_OK;
        } /* default: a nasty jelly-like creature */
        pline_The("蜘蛛の巣は%sの中に溶けた.", l_monnam(u.ustuck));
        return ECMD_OK;
    }
    if (u.utrap) {
        You("罠にはまっている間は蜘蛛の巣を張れなかった.");
        return ECMD_OK;
    }
    exercise(A_DEX, TRUE);
    if (ttmp) {
        switch (ttmp->ttyp) {
        case PIT:
        case SPIKED_PIT:
            You("蜘蛛の巣を張って落とし穴を塞いだ.");
            deltrap(ttmp);
            bury_objs(x, y);
            newsym(x, y);
            return ECMD_TIME;
        case SQKY_BOARD:
            pline_The("きしむ板の音は抑えられた.");
            deltrap(ttmp);
            newsym(x, y);
            return ECMD_TIME;
        case TELEP_TRAP:
        case LEVEL_TELEP:
        case MAGIC_PORTAL:
        case VIBRATING_SQUARE:
            Your("蜘蛛の巣は消え去った!");
            return ECMD_OK;
        case WEB:
            You("蜘蛛の巣を厚くした.");
            return ECMD_TIME;
        case HOLE:
        case TRAPDOOR:
            You("%sを蜘蛛の巣で塞いだ.",
                (ttmp->ttyp == TRAPDOOR) ? "trap door" : "hole");
            deltrap(ttmp);
            newsym(x, y);
            return ECMD_TIME;
        case ROLLING_BOULDER_TRAP:
            You("蜘蛛の巣を張って仕掛けを詰まらせた.");
            deltrap(ttmp);
            newsym(x, y);
            return ECMD_TIME;
        case ARROW_TRAP:
        case DART_TRAP:
        case BEAR_TRAP:
        case ROCKTRAP:
        case FIRE_TRAP:
        case LANDMINE:
        case SLP_GAS_TRAP:
        case RUST_TRAP:
        case MAGIC_TRAP:
        case ANTI_MAGIC:
        case POLY_TRAP:
            You("罠を作動させた!");
            dotrap(ttmp, NO_TRAP_FLAGS);
            return ECMD_TIME;
        default:
            impossible("Webbing over trap type %d?", ttmp->ttyp);
            return ECMD_OK;
        }
    } else if (On_stairs(x, y)) {
        /* cop out: don't let them hide the stairs */
           Your("蜘蛛の巣では%sへの通行を妨げられなかった.",
               (levl[x][y].typ == STAIRS) ? "階段" : "梯子");
        return ECMD_TIME;
    }
    ttmp = maketrap(x, y, WEB);
    if (ttmp) {
        You("蜘蛛の巣を張った.");
        ttmp->madeby_u = 1;
        feeltrap(ttmp);
        if (*in_rooms(x, y, SHOPBASE))
            add_damage(x, y, SHOP_WEB_COST);
    }
    return ECMD_TIME;
}

int
dosummon(void)
{
    int placeholder;
    if (u.uen < 10) {
        You("助けを呼ぶ力が足りない!");
        return ECMD_OK;
    }
    u.uen -= 10;
    disp.botl = TRUE;

    You("仲間に助けを求めた!");
    exercise(A_WIS, TRUE);
    if (!were_summon(gy.youmonst.data, TRUE, &placeholder, (char *) 0))
        pline("だが、誰も来なかった.");
    return ECMD_TIME;
}

int
dogaze(void)
{
    struct monst *mtmp;
    int looked = 0;
    char qbuf[QBUFSZ];
    int i;
    uchar adtyp = 0;

    for (i = 0; i < NATTK; i++) {
        if (gy.youmonst.data->mattk[i].aatyp == AT_GAZE) {
            adtyp = gy.youmonst.data->mattk[i].adtyp;
            break;
        }
    }
    if (adtyp != AD_CONF && adtyp != AD_FIRE) {
        impossible("gaze attack %d?", adtyp);
        return ECMD_OK;
    }

    if (Blind) {
        You_cant("見つめるものが見えなかった。");
        return ECMD_OK;
    } else if (Hallucination) {
        You_cant("見えるものに見つめることはできなかった。");
        return ECMD_OK;
    }
    if (u.uen < 15) {
        You("特殊な視線を使う力が足りない!");
        return ECMD_OK;
    }
    u.uen -= 15;
    disp.botl = TRUE;

    for (mtmp = fmon; mtmp; mtmp = mtmp->nmon) {
        if (DEADMONSTER(mtmp))
            continue;
        if (canseemon(mtmp) && couldsee(mtmp->mx, mtmp->my)) {
            looked++;
            if (Invis && !perceives(mtmp->data)) {
                pline("%sはあなたの視線に気づかないようだ.", l_monnam(mtmp));
            } else if (mtmp->minvis && !See_invisible) {
                You_cant("%sをどこで見つめるのか見えなかった。", l_monnam(mtmp));
            } else if (M_AP_TYPE(mtmp) == M_AP_FURNITURE
                       || M_AP_TYPE(mtmp) == M_AP_OBJECT) {
                looked--;
                continue;
            } else if (flags.safe_dog && mtmp->mtame && !Confusion) {
                You("%sを見つめるのを避けた.", y_monnam(mtmp));
            } else {
                if (flags.confirm && mtmp->mpeaceful && !Confusion) {
                    Sprintf(qbuf, "本当に%sを%sする?",
                            l_monnam(mtmp),
                            (adtyp == AD_CONF) ? "混乱" : "攻撃");
                    if (y_n(qbuf) != 'y')
                        continue;
                }
                setmangry(mtmp, TRUE);
                if (helpless(mtmp) || mtmp->mstun
                    || !mtmp->mcansee || !haseyes(mtmp->data)) {
                    looked--;
                    continue;
                }
                /* No reflection check for consistency with when a monster
                 * gazes at *you*--only medusa gaze gets reflected then.
                 */
                if (adtyp == AD_CONF) {
                    if (!mtmp->mconf)
                        Your("視線で%sを混乱させた!", l_monnam(mtmp));
                    else
                        pline("%sはますます混乱した.",
                              l_monnam(mtmp));
                    mtmp->mconf = 1;
                } else if (adtyp == AD_FIRE) {
                    int dmg = d(2, 6), orig_dmg = dmg, lev = (int) u.ulevel;

                    You("炎の視線で%sを攻撃した!", l_monnam(mtmp));
                    if (resists_fire(mtmp)) {
                        pline_The("炎は%sを燃やせなかった!", l_monnam(mtmp));
                        dmg = 0;
                    }
                    if (lev > rn2(20)) {
                        dmg += destroy_items(mtmp, AD_FIRE, orig_dmg);
                        ignite_items(mtmp->minvent);
                    }
                    if (dmg)
                        mtmp->mhp -= dmg;
                    if (DEADMONSTER(mtmp))
                        killed(mtmp);
                }
                /* For consistency with passive() in uhitm.c, this only
                 * affects you if the monster is still alive.
                 */
                if (DEADMONSTER(mtmp))
                    continue;

                if (mtmp->data == &mons[PM_FLOATING_EYE] && !mtmp->mcan) {
                    if (!Free_action) {
                        You("%sの視線で凍りついた!",
                            s_suffix(mon_nam(mtmp)));
                        nomul((u.ulevel > 6 || rn2(4))
                                  ? -d((int) mtmp->m_lev + 1,
                                       (int) mtmp->data->mattk[0].damd)
                                  : -200);
                        gm.multi_reason = "frozen by a monster's gaze";
                        gn.nomovemsg = 0;
                        return ECMD_TIME;
                    } else
                        You("%sの視線で一瞬体がこわばった.",
                            s_suffix(mon_nam(mtmp)));
                }
                /* Technically this one shouldn't affect you at all because
                 * the Medusa gaze is an active monster attack that only
                 * works on the monster's turn, but for it to *not* have an
                 * effect would be too weird.
                 */
                if (mtmp->data == &mons[PM_MEDUSA] && !mtmp->mcan) {
                    pline("目覚めた%sを見つめるのは得策ではなかった.",
                          l_monnam(mtmp));
                    /* as if gazing at a sleeping anything is fruitful... */
                      urgent_pline("あなたは石になっていく...");
                    svk.killer.format = KILLED_BY;
                    Strcpy(svk.killer.name,
                           "deliberately meeting Medusa's gaze");
                    done(STONING);
                }
            }
        }
    }
    if (!looked)
        You("特に何もない場所を見つめた.");
    return ECMD_TIME;
}

/* called by domonability() for #monster */
int
dohide(void)
{
    boolean ismimic = gy.youmonst.data->mlet == S_MIMIC,
            on_ceiling = is_clinger(gy.youmonst.data) || Flying;

    /* can't hide while being held (or holding) or while trapped
       (except for floor hiders [trapper or mimic] in pits) */
    if (u.ustuck || (u.utrap && (u.utraptype != TT_PIT || on_ceiling))) {
        You_cant("隠れることはできなかった。%sているから。",
                 !u.ustuck ? "引っ掛かっ"
                                     : u.uswallow ? (digests(u.ustuck->data) ? "消化され"
                                                                                                                     : "飲み込まれ")
                                         : !sticks(gy.youmonst.data) ? "つかまれ"
                                             : (humanoid(u.ustuck->data) ? "誰かをつかまえ"
                                                                                                     : "その生き物をつかまえ"));
        if (u.uundetected || (ismimic && U_AP_TYPE != M_AP_NOTHING)) {
            u.uundetected = 0;
            gy.youmonst.m_ap_type = M_AP_NOTHING;
            newsym(u.ux, u.uy);
        }
        return ECMD_OK;
    }
    /* note: hero-as-eel handling is incomplete but unnecessary;
       such critters aren't offered the option of hiding via #monster */
    if (gy.youmonst.data->mlet == S_EEL && !is_pool(u.ux, u.uy)) {
        if (IS_FOUNTAIN(levl[u.ux][u.uy].typ))
            pline_The("噴水は身を隠すには浅すぎた.");
        else
            There("には身を隠せる%sがない.", hliquid("water"));
        u.uundetected = 0;
        return ECMD_OK;
    }
    if (hides_under(gy.youmonst.data)) {
        long ct = 0L;
        struct obj *otmp, *otop = svl.level.objects[u.ux][u.uy];

        if (!otop) {
            There("には下に隠れるものがない.");
            u.uundetected = 0;
            return ECMD_OK;
        }
        for (otmp = otop;
             otmp && otmp->otyp == CORPSE
                  && touch_petrifies(&mons[otmp->corpsenm]);
             otmp = otmp->nexthere)
            ct += otmp->quan;
        /* otmp will be Null iff the entire pile consists of 'trice corpses */
        if (!otmp && !Stone_resistance) {
            char kbuf[BUFSZ];
            const char *corpse_name = cxname(otop);

            /* for the plural case, we'll say "cockatrice corpses" or
               "chickatrice corpses" depending on the top of the pile
               even if both types are present */
            if (ct == 1)
                corpse_name = an(corpse_name);
            /* no need to check poly_when_stoned(); no hide-underers can
               turn into stone golems instead of becoming petrified */
                /* NetHackJP: Remove plur(ct) from pline to avoid trailing 's' in Japanese */
                pline("%sの下に隠れるのは致命的な失敗だ...",
                  corpse_name);
            Sprintf(kbuf, "hiding under %s%s", corpse_name, plur(ct));
            instapetrify(kbuf);
            /* only reach here if life-saved */
            u.uundetected = 0;
            return ECMD_TIME;
        }
    }
    /* Planes of Air and Water */
    if (on_ceiling && !has_ceiling(&u.uz)) {
        There("にはあなたの上に隠れる場所がない.");
        u.uundetected = 0;
        return ECMD_OK;
    }
    if ((is_hider(gy.youmonst.data) && !Flying) /* floor hider */
        && (Is_airlevel(&u.uz) || Is_waterlevel(&u.uz))) {
        There("にはあなたの下に隠れる場所がない.");
        u.uundetected = 0;
        return ECMD_OK;
    }
    /* TODO? inhibit floor hiding at furniture locations, or
     * else make youhiding() give smarter messages at such spots.
     */

    if (u.uundetected || (ismimic && U_AP_TYPE != M_AP_NOTHING)) {
        youhiding(FALSE, 1); /* "you are already hiding" */
        return ECMD_OK;
    }

    if (ismimic) {
        /* should bring up a dialog "what would you like to imitate?" */
        gy.youmonst.m_ap_type = M_AP_OBJECT;
        gy.youmonst.mappearance = STRANGE_OBJECT;
    } else
        u.uundetected = 1;
    newsym(u.ux, u.uy);
    youhiding(FALSE, 0); /* "you are now hiding" */
    return ECMD_TIME;
}

int
dopoly(void)
{
    struct permonst *savedat = gy.youmonst.data;

    if (is_vampire(gy.youmonst.data) || is_vampshifter(&gy.youmonst)) {
        polyself(POLY_MONSTER);
        if (savedat != gy.youmonst.data) {
            You("%sへ変身した.",
                an(jp_pmname(gy.youmonst.data, Ugender)));
            newsym(u.ux, u.uy);
        }
    }
    return ECMD_TIME;
}

/* #monster for hero-as-mind_flayer giving psychic blast */
int
domindblast(void)
{
    struct monst *mtmp, *nmon;
    int dmg;

    if (u.uen < 10) {
        You("集中しようとしたが、維持する力が足りない.");
        return ECMD_OK;
    }
    u.uen -= 10;
    disp.botl = TRUE;

    You("集中した.");
    pline("精神エネルギーの波があふれ出した.");
    for (mtmp = fmon; mtmp; mtmp = nmon) {
        int u_sen;

        nmon = mtmp->nmon;
        if (DEADMONSTER(mtmp))
            continue;
        if (mdistu(mtmp) > BOLT_LIM * BOLT_LIM)
            continue;
        if (mtmp->mpeaceful)
            continue;
        if (mindless(mtmp->data))
            continue;
        u_sen = telepathic(mtmp->data) && !mtmp->mcansee;
        if (u_sen || (telepathic(mtmp->data) && rn2(2)) || !rn2(10)) {
            dmg = rnd(15);
            /* wake it up first, to bring hidden monster out of hiding;
               but in case it is currently peaceful, don't make it hostile
               unless it will survive the psychic blast, otherwise hero
               would avoid the penalty for killing it while peaceful */
            wakeup(mtmp, (dmg > mtmp->mhp) ? TRUE : FALSE);
            You("%sの%sを捉えた.", mon_nam(mtmp),
                u_sen ? "テレパシー"
                : telepathic(mtmp->data) ? "潜在テレパシー"
                    : "精神");
            mtmp->mhp -= dmg;
            if (DEADMONSTER(mtmp))
                killed(mtmp);
        }
    }
    return ECMD_TIME;
}

void
uunstick(void)
{
    struct monst *mtmp = u.ustuck;

    if (!mtmp) {
        impossible("uunstick: no ustuck?");
        return;
    }
    set_ustuck((struct monst *) 0); /* before pline() */
    pline("%sはもうあなたの手中にはいない.", Monnam(mtmp));
}

void
skinback(boolean silently)
{
    if (uskin) {
        int old_light = arti_light_radius(uskin);

        if (!silently)
            Your("皮膚は元の姿に戻った.");
        uarm = uskin;
        uskin = (struct obj *) 0;
        /* undo save/restore hack */
        uarm->owornmask &= ~I_SPECIAL;

        if (artifact_light(uarm))
            maybe_adjust_light(uarm, old_light);
    }
}

const char *
mbodypart(struct monst *mon, int part)
{
    static NEARDATA const char
        *humanoid_parts[] = { "arm",       "eye",  "face",         "finger",
                              "fingertip", "foot", "hand",         "handed",
                              "head",      "leg",  "light headed", "neck",
                              "spine",     "toe",  "hair",         "blood",
                              "lung",      "nose", "stomach" },
        *jelly_parts[] = { "pseudopod", "dark spot", "front",
                           "pseudopod extension", "pseudopod extremity",
                           "pseudopod root", "grasp", "grasped",
                           "cerebral area", "lower pseudopod", "viscous",
                           "middle", "surface", "pseudopod extremity",
                           "ripples", "juices", "surface", "sensor",
                           "stomach" },
        *animal_parts[] = { "forelimb",  "eye",           "face",
                            "foreclaw",  "claw tip",      "rear claw",
                            "foreclaw",  "clawed",        "head",
                            "rear limb", "light headed",  "neck",
                            "spine",     "rear claw tip", "fur",
                            "blood",     "lung",          "nose",
                            "stomach" },
        *bird_parts[] = { "wing",     "eye",  "face",         "wing",
                          "wing tip", "foot", "wing",         "winged",
                          "head",     "leg",  "light headed", "neck",
                          "spine",    "toe",  "feathers",     "blood",
                          "lung",     "bill", "stomach" },
        *horse_parts[] = { "foreleg",  "eye",           "face",
                           "forehoof", "hoof tip",      "rear hoof",
                           "forehoof", "hooved",        "head",
                           "rear leg", "light headed",  "neck",
                           "backbone", "rear hoof tip", "mane",
                           "blood",    "lung",          "nose",
                           "stomach" },
        *sphere_parts[] = { "appendage", "optic nerve", "body", "tentacle",
                            "tentacle tip", "lower appendage", "tentacle",
                            "tentacled", "body", "lower tentacle",
                            "rotational", "equator", "body",
                            "lower tentacle tip", "cilia", "life force",
                            "retina", "olfactory nerve", "interior" },
        *fungus_parts[] = { "mycelium", "visual area", "front",
                            "hypha",    "hypha",       "root",
                            "strand",   "stranded",    "cap area",
                            "rhizome",  "sporulated",  "stalk",
                            "root",     "rhizome tip", "spores",
                            "juices",   "gill",        "gill",
                            "interior" },
        *vortex_parts[] = { "region",        "eye",           "front",
                            "minor current", "minor current", "lower current",
                            "swirl",         "swirled",       "central core",
                            "lower current", "addled",        "center",
                            "currents",      "edge",          "currents",
                            "life force",    "center",        "leading edge",
                            "interior" },
        *snake_parts[] = { "vestigial limb", "eye", "face", "large scale",
                           "large scale tip", "rear region", "scale gap",
                           "scale gapped", "head", "rear region",
                           "light headed", "neck", "length", "rear scale",
                           "scales", "blood", "lung", "forked tongue",
                           "stomach" },
        *worm_parts[] = { "anterior segment", "light sensitive cell",
                          "clitellum", "setae", "setae", "posterior segment",
                          "segment", "segmented", "anterior segment",
                          "posterior", "over stretched", "clitellum",
                          "length", "posterior setae", "setae", "blood",
                          "skin", "prostomium", "stomach" },
        *spider_parts[] = { "pedipalp", "eye", "face", "pedipalp", "tarsus",
                            "claw", "pedipalp", "palped", "cephalothorax",
                            "leg", "spun out", "cephalothorax", "abdomen",
                            "claw", "hair", "hemolymph", "book lung",
                            "labrum", "digestive tract" },
        *fish_parts[] = { "fin", "eye", "premaxillary", "pelvic axillary",
                          "pelvic fin", "anal fin", "pectoral fin", "finned",
                          "head", "peduncle", "played out", "gills",
                          "dorsal fin", "caudal fin", "scales", "blood",
                          "gill", "nostril", "stomach" };
    /* claw attacks are overloaded in mons[]; most humanoids with
       such attacks should still reference hands rather than claws */
    static const char not_claws[] = {
        S_HUMAN,     S_MUMMY,   S_ZOMBIE, S_ANGEL, S_NYMPH, S_LEPRECHAUN,
        S_QUANTMECH, S_VAMPIRE, S_ORC,    S_GIANT, /* quest nemeses */
        '\0' /* string terminator; assert( S_xxx != 0 ); */
    };
    struct permonst *mptr = mon->data;

    if (part <= NO_PART) {
        impossible("mbodypart: bad part %d", part);
        return "mystery part";
    }

    /* some special cases */
    if (mptr->mlet == S_DOG || mptr->mlet == S_FELINE
        || mptr->mlet == S_RODENT || mptr == &mons[PM_OWLBEAR]) {
        switch (part) {
        case HAND:
            return "paw";
        case HANDED:
            return "pawed";
        case FOOT:
            return "rear paw";
        case ARM:
        case LEG:
            return horse_parts[part]; /* "foreleg", "rear leg" */
        default:
            break; /* for other parts, use animal_parts[] below */
        }
    } else if (mptr->mlet == S_YETI) { /* excl. owlbear due to 'if' above */
        /* opposable thumbs, hence "hands", "arms", "legs", &c */
        return humanoid_parts[part]; /* yeti/sasquatch, monkey/ape */
    }
    if ((part == HAND || part == HANDED)
        && (humanoid(mptr) && attacktype(mptr, AT_CLAW)
            && !strchr(not_claws, mptr->mlet) && mptr != &mons[PM_STONE_GOLEM]
            && mptr != &mons[PM_AMOROUS_DEMON]))
        return (part == HAND) ? "claw" : "clawed";
    if ((mptr == &mons[PM_MUMAK] || mptr == &mons[PM_MASTODON])
        && part == NOSE)
        return "trunk";
    if (mptr == &mons[PM_SHARK] && part == HAIR)
        return "skin"; /* sharks don't have scales */
    if ((mptr == &mons[PM_JELLYFISH] || mptr == &mons[PM_KRAKEN])
        && (part == ARM || part == FINGER || part == HAND || part == FOOT
            || part == TOE))
        return "tentacle";
    if (mptr == &mons[PM_FLOATING_EYE] && part == EYE)
        return "cornea";
    if (humanoid(mptr) && (part == ARM || part == FINGER || part == FINGERTIP
                           || part == HAND || part == HANDED))
        return humanoid_parts[part];
    if (mptr->mlet == S_COCKATRICE)
        return (part == HAIR) ? snake_parts[part] : bird_parts[part];
    if (mptr == &mons[PM_RAVEN])
        return bird_parts[part];
    if (mptr->mlet == S_CENTAUR || mptr->mlet == S_UNICORN
        || mptr == &mons[PM_KI_RIN]
        || (mptr == &mons[PM_ROTHE] && part != HAIR))
        return horse_parts[part];
    if (mptr->mlet == S_LIGHT) {
        if (part == HANDED)
            return "rayed";
        else if (part == ARM || part == FINGER || part == FINGERTIP
                 || part == HAND)
            return "ray";
        else
            return "beam";
    }
    if (mptr == &mons[PM_STALKER] && part == HEAD)
        return "head";
    if (mptr->mlet == S_EEL && mptr != &mons[PM_JELLYFISH])
        return fish_parts[part];
    if (mptr->mlet == S_WORM)
        return worm_parts[part];
    if (mptr->mlet == S_SPIDER)
        return spider_parts[part];
    if (slithy(mptr) || (mptr->mlet == S_DRAGON && part == HAIR))
        return snake_parts[part];
    if (mptr->mlet == S_EYE)
        return sphere_parts[part];
    if (mptr->mlet == S_JELLY || mptr->mlet == S_PUDDING
        || mptr->mlet == S_BLOB || mptr == &mons[PM_JELLYFISH])
        return jelly_parts[part];
    if (mptr->mlet == S_VORTEX || mptr->mlet == S_ELEMENTAL)
        return vortex_parts[part];
    if (mptr->mlet == S_FUNGUS)
        return fungus_parts[part];
    if (humanoid(mptr))
        return humanoid_parts[part];
    return animal_parts[part];
}

const char *
body_part(int part)
{
    return mbodypart(&gy.youmonst, part);
}

static const char *
jp_bodypart_default(int part)
{
    switch (part) {
    case ARM:
        return "腕";
    case EYE:
        return "目";
    case FACE:
        return "顔";
    case FINGER:
        return "指";
    case FINGERTIP:
        return "指先";
    case FOOT:
        return "足";
    case HAND:
        return "手";
    case HANDED:
        return "手";
    case HEAD:
        return "頭";
    case LEG:
        return "脚";
    case LIGHT_HEADED:
        return "めまいがする";
    case NECK:
        return "首";
    case SPINE:
        return "背筋";
    case TOE:
        return "つま先";
    case HAIR:
        return "体毛";
    case BLOOD:
        return "血";
    case LUNG:
        return "肺";
    case NOSE:
        return "鼻";
    case STOMACH:
        return "胃";
    default:
        return "部位";
    }
}

static boolean
jp_has_nonascii(const char *str)
{
    const uchar *p = (const uchar *) str;

    if (!str)
        return FALSE;
    while (*p) {
        if (*p & 0x80)
            return TRUE;
        ++p;
    }
    return FALSE;
}

static const char *
jp_translate_bodypart_name(const char *part, int part_id)
{
    static const struct {
        const char *en;
        const char *ja;
    } jp_bodypart_map[] = {
        { "abdomen", "腹部" },
        { "addled", "めまいがする" },
        { "anal fin", "尻びれ" },
        { "anterior segment", "前体節" },
        { "appendage", "付属肢" },
        { "arm", "腕" },
        { "backbone", "背骨" },
        { "beam", "光条" },
        { "bill", "くちばし" },
        { "blood", "血" },
        { "body", "胴体" },
        { "book lung", "書肺" },
        { "cap area", "傘部" },
        { "caudal fin", "尾びれ" },
        { "center", "中心" },
        { "central core", "中核" },
        { "cephalothorax", "頭胸部" },
        { "cerebral area", "中枢部" },
        { "cilia", "繊毛" },
        { "claw", "爪" },
        { "claw tip", "爪先" },
        { "clawed", "鉤爪" },
        { "clitellum", "環帯" },
        { "cornea", "角膜" },
        { "currents", "流れ" },
        { "dark spot", "暗斑" },
        { "digestive tract", "消化管" },
        { "dorsal fin", "背びれ" },
        { "edge", "縁" },
        { "equator", "赤道部" },
        { "eye", "目" },
        { "face", "顔" },
        { "feathers", "羽毛" },
        { "fin", "ヒレ" },
        { "finger", "指" },
        { "fingertip", "指先" },
        { "finned", "ヒレ" },
        { "foot", "足" },
        { "foreclaw", "前爪" },
        { "forehoof", "前ひづめ" },
        { "foreleg", "前脚" },
        { "forelimb", "前肢" },
        { "forked tongue", "二股舌" },
        { "front", "前面" },
        { "fur", "体毛" },
        { "gill", "えら" },
        { "gills", "えら" },
        { "grasp", "把持器" },
        { "grasped", "把持肢" },
        { "hair", "体毛" },
        { "hand", "手" },
        { "handed", "手" },
        { "head", "頭" },
        { "hemolymph", "血リンパ" },
        { "hoof tip", "ひづめ先" },
        { "hooved", "ひづめ" },
        { "hypha", "菌糸" },
        { "interior", "内部" },
        { "juices", "体液" },
        { "labrum", "上唇" },
        { "large scale", "大鱗" },
        { "large scale tip", "鱗先" },
        { "leading edge", "前縁" },
        { "leg", "脚" },
        { "length", "胴体" },
        { "life force", "生命力" },
        { "light headed", "頭がくらくら" },
        { "light sensitive cell", "光感受細胞" },
        { "lower appendage", "下部付属肢" },
        { "lower current", "下部流" },
        { "lower pseudopod", "下部仮足" },
        { "lower tentacle", "下部触手" },
        { "lower tentacle tip", "下部触手先" },
        { "lung", "肺" },
        { "mane", "たてがみ" },
        { "middle", "中央部" },
        { "minor current", "小渦流" },
        { "mycelium", "菌糸体" },
        { "neck", "首" },
        { "nose", "鼻" },
        { "nostril", "鼻孔" },
        { "olfactory nerve", "嗅神経" },
        { "optic nerve", "視神経" },
        { "over stretched", "めまいがする" },
        { "palped", "触肢" },
        { "paw", "前足" },
        { "pawed", "前足" },
        { "pectoral fin", "胸びれ" },
        { "pedipalp", "触肢" },
        { "peduncle", "尾柄" },
        { "pelvic axillary", "腹びれ基部" },
        { "pelvic fin", "腹びれ" },
        { "played out", "めまいがする" },
        { "posterior", "後部" },
        { "posterior segment", "後体節" },
        { "posterior setae", "後部剛毛" },
        { "premaxillary", "前上顎" },
        { "prostomium", "口前葉" },
        { "pseudopod", "仮足" },
        { "pseudopod extension", "仮足突起" },
        { "pseudopod extremity", "仮足先" },
        { "pseudopod root", "仮足根" },
        { "ray", "光線" },
        { "rayed", "光線" },
        { "rear claw", "後ろ爪" },
        { "rear claw tip", "後ろ爪先" },
        { "rear hoof", "後ろひづめ" },
        { "rear hoof tip", "後ろひづめ先" },
        { "rear leg", "後脚" },
        { "rear limb", "後肢" },
        { "rear paw", "後ろ足" },
        { "rear region", "後部" },
        { "rear scale", "後部鱗" },
        { "region", "渦部" },
        { "retina", "網膜" },
        { "rhizome", "根茎" },
        { "rhizome tip", "根茎先" },
        { "ripples", "波紋" },
        { "root", "根" },
        { "rotational", "めまいがする" },
        { "scale gap", "鱗間" },
        { "scale gapped", "鱗の隙間" },
        { "scales", "鱗" },
        { "segment", "体節" },
        { "segmented", "体節" },
        { "sensor", "感覚器" },
        { "setae", "剛毛" },
        { "skin", "皮膚" },
        { "spine", "背筋" },
        { "spores", "胞子" },
        { "sporulated", "めまいがする" },
        { "spun out", "めまいがする" },
        { "stalk", "柄" },
        { "stomach", "胃" },
        { "strand", "菌糸束" },
        { "stranded", "菌糸" },
        { "surface", "表面" },
        { "swirl", "渦流" },
        { "swirled", "渦" },
        { "tarsus", "跗節" },
        { "tentacle", "触手" },
        { "tentacle tip", "触手先" },
        { "tentacled", "触手" },
        { "toe", "つま先" },
        { "trunk", "鼻" },
        { "vestigial limb", "痕跡肢" },
        { "viscous", "粘質部" },
        { "visual area", "視覚域" },
        { "wing", "翼" },
        { "wing tip", "翼端" },
        { "winged", "翼" },
    };
    int i;

    if (!part || !*part)
        return jp_bodypart_default(part_id);
    if (jp_has_nonascii(part))
        return part;

    for (i = 0; i < (int) SIZE(jp_bodypart_map); ++i)
        if (!strcmp(part, jp_bodypart_map[i].en))
            return jp_bodypart_map[i].ja;

    return jp_bodypart_default(part_id);
}

static const char *
jp_bodypart_pluralized(const char *jpname, int part)
{
    static char bufs[8][BUFSZ];
    static int idx = 0;
    char *buf;
    boolean paired = FALSE;

    if (!jpname || !*jpname)
        jpname = jp_bodypart_default(part);

    switch (part) {
    case ARM:
    case EYE:
    case FINGER:
    case FINGERTIP:
    case FOOT:
    case HAND:
    case LEG:
    case LUNG:
    case TOE:
        paired = TRUE;
        break;
    default:
        paired = FALSE;
        break;
    }
    if (!paired)
        return jpname;

    buf = bufs[idx++ % SIZE(bufs)];
    Snprintf(buf, BUFSZ, "両%s", jpname);
    return buf;
}

const char *
jp_mbodypart(struct monst *mon, int part)
{
    return jp_translate_bodypart_name(mbodypart(mon, part), part);
}

const char *
jp_body_part(int part)
{
    return jp_translate_bodypart_name(body_part(part), part);
}

const char *
jp_mbodypart_plural(struct monst *mon, int part)
{
    return jp_bodypart_pluralized(jp_mbodypart(mon, part), part);
}

const char *
jp_body_part_plural(int part)
{
    return jp_bodypart_pluralized(jp_body_part(part), part);
}

int
poly_gender(void)
{
    /* Returns gender of polymorphed player;
     * 0/1=same meaning as flags.female, 2=none.
     */
    if (is_neuter(gy.youmonst.data) || !humanoid(gy.youmonst.data))
        return 2;
    return flags.female;
}

void
ugolemeffects(int damtype, int dam)
{
    int heal = 0;

    /* We won't bother with "slow"/"haste" since players do not
     * have a monster-specific slow/haste so there is no way to
     * restore the old velocity once they are back to human.
     */
    if (u.umonnum != PM_FLESH_GOLEM && u.umonnum != PM_IRON_GOLEM)
        return;
    switch (damtype) {
    case AD_ELEC:
        if (u.umonnum == PM_FLESH_GOLEM)
            heal = (dam + 5) / 6; /* Approx 1 per die */
        break;
    case AD_FIRE:
        if (u.umonnum == PM_IRON_GOLEM)
            heal = dam;
        break;
    }
    if (heal && (u.mh < u.mhmax)) {
        u.mh += heal;
        if (u.mh > u.mhmax)
            u.mh = u.mhmax;
        disp.botl = TRUE;
        pline("奇妙なことに、前より体調がよくなった.");
        exercise(A_STR, TRUE);
    }
}

staticfn int
armor_to_dragon(int atyp)
{
    switch (atyp) {
    case GRAY_DRAGON_SCALE_MAIL:
    case GRAY_DRAGON_SCALES:
        return PM_GRAY_DRAGON;
    case SILVER_DRAGON_SCALE_MAIL:
    case SILVER_DRAGON_SCALES:
        return PM_SILVER_DRAGON;
    case GOLD_DRAGON_SCALE_MAIL:
    case GOLD_DRAGON_SCALES:
        return PM_GOLD_DRAGON;
#if 0 /* DEFERRED */
    case SHIMMERING_DRAGON_SCALE_MAIL:
    case SHIMMERING_DRAGON_SCALES:
        return PM_SHIMMERING_DRAGON;
#endif
    case RED_DRAGON_SCALE_MAIL:
    case RED_DRAGON_SCALES:
        return PM_RED_DRAGON;
    case ORANGE_DRAGON_SCALE_MAIL:
    case ORANGE_DRAGON_SCALES:
        return PM_ORANGE_DRAGON;
    case WHITE_DRAGON_SCALE_MAIL:
    case WHITE_DRAGON_SCALES:
        return PM_WHITE_DRAGON;
    case BLACK_DRAGON_SCALE_MAIL:
    case BLACK_DRAGON_SCALES:
        return PM_BLACK_DRAGON;
    case BLUE_DRAGON_SCALE_MAIL:
    case BLUE_DRAGON_SCALES:
        return PM_BLUE_DRAGON;
    case GREEN_DRAGON_SCALE_MAIL:
    case GREEN_DRAGON_SCALES:
        return PM_GREEN_DRAGON;
    case YELLOW_DRAGON_SCALE_MAIL:
    case YELLOW_DRAGON_SCALES:
        return PM_YELLOW_DRAGON;
    default:
        return NON_PM;
    }
}

/* some species have awareness of other species */
staticfn void
polysense(void)
{
    short warnidx = NON_PM;

    svc.context.warntype.speciesidx = NON_PM;
    svc.context.warntype.species = 0;
    svc.context.warntype.polyd = 0;
    HWarn_of_mon &= ~FROMRACE;

    switch (u.umonnum) {
    case PM_PURPLE_WORM:
    case PM_BABY_PURPLE_WORM:
        warnidx = PM_SHRIEKER;
        break;
    case PM_VAMPIRE:
    case PM_VAMPIRE_LEADER:
        svc.context.warntype.polyd = M2_HUMAN | M2_ELF;
        HWarn_of_mon |= FROMRACE;
        return;
    }
    if (ismnum(warnidx)) {
        svc.context.warntype.speciesidx = warnidx;
        svc.context.warntype.species = &mons[warnidx];
        HWarn_of_mon |= FROMRACE;
    }
}

/* True iff hero's role or race has been genocided */
boolean
ugenocided(void)
{
    return ((svm.mvitals[gu.urole.mnum].mvflags & G_GENOD)
            || (svm.mvitals[gu.urace.mnum].mvflags & G_GENOD));
}

/* how hero feels "inside" after self-genocide of role or race */
const char *
udeadinside(void)
{
    /* self-genocide used to always say "you feel dead inside" but that
       seems silly when you're polymorphed into something undead;
       monkilled() distinguishes between living (killed) and non (destroyed)
       for monster death message; we refine the nonliving aspect a bit */
    return !nonliving(gy.youmonst.data)
             ? "死んだ"          /* living, including demons */
             : !weirdnonliving(gy.youmonst.data)
                 ? "断罪された" /* undead plus manes */
                 : "空っぽな";  /* golems plus vortices */
}

/*polyself.c*/

