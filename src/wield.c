/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-31. */
/* NetHack 5.0	wield.c	$NHDT-Date: 1707525193 2024/02/10 00:33:13 $  $NHDT-Branch: NetHack-3.7 $:$NHDT-Revision: 1.110 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2009. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"

/* KMH -- Differences between the three weapon slots.
 *
 * The main weapon (uwep):
 * 1.  Is filled by the (w)ield command.
 * 2.  Can be filled with any type of item.
 * 3.  May be carried in one or both hands.
 * 4.  Is used as the melee weapon and as the launcher for
 *     ammunition.
 * 5.  Only conveys intrinsics when it is a weapon, weapon-tool,
 *     or artifact.
 * 6.  Certain cursed items will weld to the hand and cannot be
 *     unwielded or dropped.  See erodeable_wep() and will_weld()
 *     below for the list of which items apply.
 *
 * The secondary weapon (uswapwep):
 * 1.  Is filled by the e(x)change command, which swaps this slot
 *     with the main weapon.  If the "pushweapon" option is set,
 *     the (w)ield command will also store the old weapon in the
 *     secondary slot.
 * 2.  Can be filled with anything that will fit in the main weapon
 *     slot; that is, any type of item.
 * 3.  Is usually NOT considered to be carried in the hands.
 *     That would force too many checks among the main weapon,
 *     second weapon, shield, gloves, and rings; and it would
 *     further be complicated by bimanual weapons.  A special
 *     exception is made for two-weapon combat.
 * 4.  Is used as the second weapon for two-weapon combat, and as
 *     a convenience to swap with the main weapon.
 * 5.  Never conveys intrinsics.
 * 6.  Cursed items never weld (see #3 for reasons), but they also
 *     prevent two-weapon combat.
 *
 * The quiver (uquiver):
 * 1.  Is filled by the (Q)uiver command.
 * 2.  Can be filled with any type of item.
 * 3.  Is considered to be carried in a special part of the pack.
 * 4.  Is used as the item to throw with the (f)ire command.
 *     This is a convenience over the normal (t)hrow command.
 * 5.  Never conveys intrinsics.
 * 6.  Cursed items never weld; their effect is handled by the normal
 *     throwing code.
 * 7.  The autoquiver option will fill it with something deemed
 *     suitable if (f)ire is used when it's empty.
 *
 * No item may be in more than one of these slots.
 */

staticfn boolean cant_wield_corpse(struct obj *) NONNULLARG1;
staticfn int ready_weapon(struct obj *) NO_NNARGS;
staticfn int ready_ok(struct obj *) NO_NNARGS;
staticfn int wield_ok(struct obj *) NO_NNARGS;
staticfn void finish_splitting(struct obj *);
staticfn const char *jp_wield_verb(const char *);

/* used by will_weld() */
/* probably should be renamed */
#define erodeable_wep(optr)                             \
    ((optr)->oclass == WEAPON_CLASS || is_weptool(optr) \
     || (optr)->otyp == HEAVY_IRON_BALL || (optr)->otyp == IRON_CHAIN)

/* used by welded(), and also while wielding */
#define will_weld(optr) \
    ((optr)->cursed && (erodeable_wep(optr) || (optr)->otyp == TIN_OPENER))

/* to dual-wield, 'obj' must be a weapon or a weapon-tool, and not a bow
   or arrow or missile (dart, shuriken, boomerang), so not matching the
   one-handed weapons which yield "you begin bashing" if used for melee;
   empty hands and two-handed weapons have to be handled separately */
#define TWOWEAPOK(obj) \
    (((obj)->oclass == WEAPON_CLASS)                            \
     ? !(is_launcher(obj) || is_ammo(obj) || is_missile(obj))   \
     : is_weptool(obj))

static const char
    are_no_longer_twoweap[] = "二刀流ではなくなった",
    can_no_longer_twoweap[] = "二刀流を続けられない";

staticfn const char *
jp_wield_verb(const char *verb)
{
    if (!verb)
        return "使う";
    if (!strcmp(verb, "wield"))
        return "装備する";
    if (!strcmp(verb, "ready"))
        return "準備する";
    if (!strcmp(verb, "fire"))
        return "発射する";
    if (!strcmp(verb, "rub"))
        return "こする";
    /* Keep message generation robust even if a new verb is added later.
       Unknown verbs intentionally fall back to a generic Japanese action. */
    return "使う";
}

/*** Functions that place a given item in a slot ***/
/* Proper usage includes:
 * 1.  Initializing the slot during character generation or a
 *     restore.
 * 2.  Setting the slot due to a player's actions.
 * 3.  If one of the objects in the slot is split off, these
 *     functions can be used to put the remainder back in the slot.
 * 4.  Putting an item that was thrown and returned back into the slot.
 * 5.  Emptying the slot, by passing a null object.  NEVER pass
 *     cg.zeroobj!
 *
 * If the item is being moved from another slot, it is the caller's
 * responsibility to handle that.  It's also the caller's responsibility
 * to print the appropriate messages.
 */
void
setuwep(struct obj *obj)
{
    struct obj *olduwep = uwep;

    if (obj == uwep)
        return; /* necessary to not set gu.unweapon */
    setworn(obj, W_WEP);
    /* handle Ogresmasher before Sunsword; even though they can't be happening
       at the same time, botl flag update should come before pline message */
    if (uwep == obj
        && ((uwep && uwep->oartifact == ART_OGRESMASHER)
            || (olduwep && olduwep->oartifact == ART_OGRESMASHER)))
        disp.botl = TRUE; /* gaining or losing Con bonus */
    /* This message isn't printed in the caller because it happens
     * *whenever* Sunsword is unwielded, from whatever cause. */
    if (uwep == obj && artifact_light(olduwep) && olduwep->lamplit) {
        end_burn(olduwep, FALSE);
        if (!Blind)
            pline("%sは輝かなくなった.", xname(olduwep));
    }
    if (uwep == obj
        && (u_wield_art(ART_OGRESMASHER)
            || is_art(olduwep, ART_OGRESMASHER)))
        disp.botl = TRUE;
    /* Note: Explicitly wielding a pick-axe will not give a "bashing"
     * message.  Wielding one via 'a'pplying it will.
     * 3.2.2:  Wielding arbitrary objects will give bashing message too.
     */
    if (obj) {
        gu.unweapon = (obj->oclass == WEAPON_CLASS)
                       ? is_launcher(obj) || is_ammo(obj) || is_missile(obj)
            || (is_pole(obj) && !u.usteed && !is_art(obj, ART_SNICKERSNEE))
                       : !is_weptool(obj) && !is_wet_towel(obj);
    } else
        gu.unweapon = TRUE; /* for "bare hands" message */
}

staticfn boolean
cant_wield_corpse(struct obj *obj)
{
    char kbuf[BUFSZ];

    if (uarmg || obj->otyp != CORPSE || !touch_petrifies(&mons[obj->corpsenm])
        || Stone_resistance)
        return FALSE;

    /* Prevent wielding cockatrice when not wearing gloves --KAA */
    You("素手の%sで%sを装備した.",
        jp_body_part_plural(HAND),
        jp_corpse_xname(obj, (const char *) 0, CXN_PFX_THE));
    Sprintf(kbuf, "素手で%sを装備した", killer_xname(obj));
    instapetrify(kbuf);
    return TRUE;
}

/* description of hands when not wielding anything; also used
   by #seeweapon (')'), #attributes (^X), and #takeoffall ('A') */
const char *
empty_handed(void)
{
        return uarmg ? "手に何も持っていない" /* gloves imply hands */
           : humanoid(gy.youmonst.data)
             /* hands but no weapon and no gloves */
                         ? "素手だ"
               /* alternate phrasing for paws or lack of hands */
                             : "何も装備していない";
}

staticfn int
ready_weapon(struct obj *wep)
{
    /* Separated function so swapping works easily */
    int res = ECMD_OK;
    boolean was_twoweap = u.twoweap, had_wep = (uwep != 0);

    if (!wep) {
        /* No weapon */
        if (uwep) {
            You("%s.", empty_handed());
            setuwep((struct obj *) 0);
            res = ECMD_TIME;
        } else
            You("すでに%s.", empty_handed());
    } else if (wep->otyp == CORPSE && cant_wield_corpse(wep)) {
        /* hero must have been life-saved to get here; use a turn */
        res = ECMD_TIME; /* corpse won't be wielded */
    } else if (uarms && bimanual(wep)) {
        You("盾を装備したままでは両手用の%sを装備できなかった.",
            is_sword(wep) ? "剣" : wep->otyp == BATTLE_AXE ? "斧"
                                                              : "武器");
        res = ECMD_FAIL;
    } else if (!retouch_object(&wep, FALSE)) {
        res = ECMD_TIME; /* takes a turn even though it doesn't get wielded */
    } else {
        /* Weapon WILL be wielded after this point */
        res = ECMD_TIME;
        if (will_weld(wep)) {
            pline("%sはあなたの%s%sに貼りついて離れなくなった!",
                  xname(wep),
                  bimanual(wep) ? "" :
                      (URIGHTY ? "利き手の右" : "利き手の左"),
                  bimanual(wep) ? (const char *) jp_body_part_plural(HAND)
                                : jp_body_part(HAND));
            set_bknown(wep, 1);
        } else {
            /* The message must be printed before setuwep (since
             * you might die and be revived from changing weapons),
             * and the message must be before the death message and
             * Lifesaved rewielding.  Yet we want the message to
             * say "weapon in hand", thus this kludge.
             * [That comment is obsolete.  It dates from the days (3.0)
             * when unwielding Firebrand could cause hero to be burned
             * to death in Hell due to loss of fire resistance.
             * "Lifesaved re-wielding or re-wearing" is ancient history.]
             */
            long dummy = wep->owornmask;

            wep->owornmask |= W_WEP;
            if (wep->otyp == AKLYS && (wep->owornmask & W_WEP) != 0)
                You("ひもをしっかり固定した.");
            prinv((char *) 0, wep, 0L);
            wep->owornmask = dummy;
        }

        setuwep(wep);
        if (was_twoweap && !u.twoweap && flags.verbose) {
            /* skip this message if we already got "empty handed" one above;
               also, Null is not safe for neither TWOWEAPOK() or bimanual() */
            if (uwep)
                You("%s.", ((TWOWEAPOK(uwep) && !bimanual(uwep))
                            ? are_no_longer_twoweap
                            : can_no_longer_twoweap));
        }

        /* KMH -- Talking artifacts are finally implemented */
        if (wep->oartifact) {
            res |= arti_speak(wep); /* sets ECMD_TIME bit if artifact speaks */
        }

        if (artifact_light(wep) && !wep->lamplit) {
            begin_burn(wep, FALSE);
            if (!Blind)
                pline("%sが%sように輝き始めた!",
                      xname(wep), arti_light_description(wep));
        }
#if 0
        /* we'll get back to this someday, but it's not balanced yet */
        if (Race_if(PM_ELF) && !wep->oartifact
            && objects[wep->otyp].oc_material == IRON) {
            /* Elves are averse to wielding cold iron */
            You("冷たい鉄を装備すると不安を覚えた.");
            change_luck(-1);
        }
#endif
        if (wep->unpaid) {
            struct monst *this_shkp;

            if ((this_shkp = shop_keeper(inside_shop(u.ux, u.uy)))
                != (struct monst *) 0) {
                pline("%sが警告した: \"うちの%sは丁寧に扱ってくれ!\"",
                      jp_shkname_for_display(this_shkp), xname(wep));
            }
        }
    }
    if ((had_wep != (uwep != 0)) && condtests[bl_bareh].enabled)
        disp.botl = TRUE;
    return res;
}

void
setuqwep(struct obj *obj)
{
    setworn(obj, W_QUIVER);
    /* no extra handling needed; this used to include a call to
       update_inventory() but that's already performed by setworn() */
    return;
}

void
setuswapwep(struct obj *obj)
{
    setworn(obj, W_SWAPWEP);
    return;
}

/* getobj callback for object to ready for throwing/shooting;
   this filter lets worn items through so that caller can reject them */
staticfn int
ready_ok(struct obj *obj)
{
    if (!obj) /* '-', will empty quiver slot if chosen */
        return uquiver ? GETOBJ_SUGGEST : GETOBJ_DOWNPLAY;

    /* downplay when wielded, unless more than one */
    if (obj == uwep || (obj == uswapwep && u.twoweap))
        return (obj->quan == 1) ? GETOBJ_DOWNPLAY : GETOBJ_SUGGEST;

    if (is_ammo(obj)) {
        return ((uwep && ammo_and_launcher(obj, uwep))
                || (uswapwep && ammo_and_launcher(obj, uswapwep)))
                ? GETOBJ_SUGGEST
                : GETOBJ_DOWNPLAY;
    } else if (is_launcher(obj)) { /* part of 'possible extension' below */
        return GETOBJ_DOWNPLAY;
    } else {
        if (obj->oclass == WEAPON_CLASS || obj->oclass == COIN_CLASS)
            return GETOBJ_SUGGEST;
        /* Possible extension: exclude weapons that make no sense to throw,
           such as whips, bows, slings, rubber hoses. */
    }

#if 0   /* superseded by ammo_and_launcher handling above */
    /* Include gems/stones as likely candidates if either primary
       or secondary weapon is a sling. */
    if (obj->oclass == GEM_CLASS
        && (uslinging()
            || (uswapwep && objects[uswapwep->otyp].oc_skill == P_SLING)))
        return GETOBJ_SUGGEST;
#endif

    return GETOBJ_DOWNPLAY;
}

/* getobj callback for object to wield */
staticfn int
wield_ok(struct obj *obj)
{
    if (!obj)
        return GETOBJ_SUGGEST;

    if (obj->oclass == COIN_CLASS)
        return GETOBJ_EXCLUDE;

    if (obj->oclass == WEAPON_CLASS || is_weptool(obj))
        return GETOBJ_SUGGEST;

    return GETOBJ_DOWNPLAY;
}

staticfn void
finish_splitting(struct obj *obj)
{
    /* obj was split off from something; give it its own invlet */
    freeinv(obj);
    addinv_nomerge(obj);
}

/* the #wield command - wield a weapon */
int
dowield(void)
{
    char qbuf[QBUFSZ];
    struct obj *wep, *oldwep;
    int result;

    /* May we attempt this? */
    gm.multi = 0;
    if (cantwield(gy.youmonst.data)) {
        pline("ばかげている!");
        return ECMD_FAIL;
    }
    /* Keep going even if inventory is completely empty, since wielding '-'
       to wield nothing can be construed as a positive act even when done
       so redundantly. */

    /* Prompt for a new weapon */
    clear_splitobjs();
    if (!(wep = getobj("wield", wield_ok, GETOBJ_PROMPT | GETOBJ_ALLOWCNT))) {
        /* Cancelled */
        return ECMD_CANCEL;
    } else if (wep == uwep) {
 already_wielded:
        You("それは既に装備していた!");
        if (is_weptool(wep) || is_wet_towel(wep))
            gu.unweapon = FALSE; /* [see setuwep()] */
        return ECMD_FAIL;
    } else if (welded(uwep)) {
        weldmsg(uwep);
        /* previously interrupted armor removal mustn't be resumed */
        reset_remarm();
        /* if player chose a partial stack but can't wield it, undo split */
        if (wep->o_id && wep->o_id == svc.context.objsplit.child_oid)
            unsplitobj(wep);
        return ECMD_FAIL;
    } else if (wep->o_id && wep->o_id == svc.context.objsplit.child_oid) {
        /* if wep is the result of supplying a count to getobj()
           we don't want to split something already wielded; for
           any other item, we need to give it its own inventory slot */
        if (uwep && uwep->o_id == svc.context.objsplit.parent_oid) {
            unsplitobj(wep);
            /* wep was merged back to uwep, already_wielded uses wep */
            wep = uwep;
            goto already_wielded;
        }
        finish_splitting(wep);
        goto wielding;
    }

    /* Handle no object, or object in other slot */
    if (wep == &hands_obj) {
        wep = (struct obj *) 0;
    } else if (wep == uswapwep) {
        return doswapweapon();
    } else if (wep == uquiver) {
        /* offer to split stack if multiple are quivered */
        if (uquiver->quan > 1L && inv_cnt(FALSE) < invlet_basic
                                    && splittable(uquiver)) {
            Sprintf(qbuf, "%ld本の%sを構えている。1本だけ装備するか?",
                    uquiver->quan, simpleonames(uquiver));
            switch (ynq(qbuf)) {
            case 'q':
                return ECMD_OK;
            case 'y':
                /* leave N-1 quivered, split off 1 to wield */
                wep = splitobj(uquiver, 1L);
                finish_splitting(wep);
                goto wielding;
            default:
                break;
            }
            Strcpy(qbuf, "代わりに全部装備するか?");
        } else {
            boolean use_plural = (is_plural(uquiver) || pair_of(uquiver));

            Sprintf(qbuf, "%sを構えている。代わりに%sを装備するか?",
                    !use_plural ? "それ" : "それら",
                    !use_plural ? "それ" : "それら");
        }
        /* require confirmation to wield the quivered weapon */
        if (ynq(qbuf) != 'y') {
            (void) Shk_Your(qbuf, uquiver); /* replace qbuf[] contents */
            pline("%s%sはそのまま構えられている.", qbuf,
                  simpleonames(uquiver));
            return ECMD_OK;
        }
        /* wielding whole readied stack, so no longer quivered */
        setuqwep((struct obj *) 0);
    } else if (wep->owornmask & (W_ARMOR | W_ACCESSORY | W_SADDLE)) {
        You("それを装備することはできない!");
        return ECMD_FAIL;
    }

 wielding:
    /* Set your new primary weapon */
    oldwep = uwep;
    result = ready_weapon(wep);
    if (flags.pushweapon && oldwep && uwep != oldwep)
        setuswapwep(oldwep);
    untwoweapon();

    return result;
}

/* the #swap command - swap wielded and secondary weapons */
int
doswapweapon(void)
{
    struct obj *oldwep, *oldswap;
    int result = 0;

    /* May we attempt this? */
    gm.multi = 0;
    if (cantwield(gy.youmonst.data)) {
        pline("ばかげている!");
        return ECMD_FAIL;
    }
    if (welded(uwep)) {
        weldmsg(uwep);
        return ECMD_FAIL;
    }

    /* Unwield your current secondary weapon */
    oldwep = uwep;
    oldswap = uswapwep;
    setuswapwep((struct obj *) 0);

    /* Set your new primary weapon */
    result = ready_weapon(oldswap);

    /* Set your new secondary weapon */
    if (uwep == oldwep) {
        /* Wield failed for some reason */
        setuswapwep(oldswap);
    } else {
        setuswapwep(oldwep);
        if (uswapwep)
            prinv((char *) 0, uswapwep, 0L);
        else
            You("副武器は装備していなかった.");
    }

    if (u.twoweap && !can_twoweapon())
        untwoweapon();

    return result;
}

/* the #quiver command */
int
dowieldquiver(void)
{
    return doquiver_core("ready");
}

/* guts of #quiver command; also used by #fire when refilling empty quiver */
int
doquiver_core(const char *verb) /* "ready" or "fire" */
{
    char qbuf[QBUFSZ];
    struct obj *newquiver;
    int res;
    const char *jpverb = jp_wield_verb(verb);
    boolean was_uwep = FALSE, was_twoweap = u.twoweap;

    /* Since the quiver isn't in your hands, don't check cantwield(),
       will_weld(), touch_petrifies(), etc. */
    gm.multi = 0;
    if (!gi.invent) {
        /* could accept '-' to empty quiver, but there's no point since
           inventory is empty so uquiver is already Null */
        You("矢筒に用意できるものを持っていない.");
        return ECMD_OK;
    }

    /* forget last splitobj() before calling getobj() with GETOBJ_ALLOWCNT */
    clear_splitobjs();
    /* Prompt for a new quiver: "What do you want to {ready|fire}?" */
    newquiver = getobj(verb, ready_ok, GETOBJ_PROMPT | GETOBJ_ALLOWCNT);

    if (!newquiver) {
        /* Cancelled */
        return ECMD_CANCEL;
    } else if (newquiver == &hands_obj) { /* no object */
        /* Explicitly nothing */
        if (uquiver) {
            You("矢筒には何も用意されていない.");
            /* skip 'quivering: prinv()' */
            setuqwep((struct obj *) 0);
        } else {
            You("最初から矢筒は空だった!");
        }
        return ECMD_OK;
    } else if (newquiver->o_id == svc.context.objsplit.child_oid) {
        /* if newquiver is the result of supplying a count to getobj()
           we don't want to split something already in the quiver;
           for any other item, we need to give it its own inventory slot */
        if (uquiver && uquiver->o_id == svc.context.objsplit.parent_oid) {
            unsplitobj(newquiver);
            goto already_quivered;
        } else if (newquiver->oclass == COIN_CLASS) {
            /* don't allow splitting a stack of coins into quiver */
            You("金貨の一部だけを矢筒に準備することはできない.");
            unsplitobj(newquiver);
            return ECMD_OK;
        }
        finish_splitting(newquiver);
    } else if (newquiver == uquiver) {
 already_quivered:
        pline("それは既に矢筒に準備されている!");
        return ECMD_OK;
    } else if (newquiver->owornmask & (W_ARMOR | W_ACCESSORY | W_SADDLE)) {
        You("それを%sことはできない!", jpverb);
        return ECMD_OK;
    } else if (newquiver == uwep) {
        int weld_res = !uwep->bknown;

        if (welded(uwep)) {
            weldmsg(uwep);
            reset_remarm(); /* same as dowield() */
            return weld_res ? ECMD_TIME : ECMD_OK;
        }
        /* offer to split stack if wielding more than 1 */
        if (uwep->quan > 1L && inv_cnt(FALSE) < invlet_basic
                                    && splittable(uwep)) {
            Sprintf(qbuf, "%ld個の%sを装備している。%ld個を矢筒に準備するか?",
                uwep->quan, simpleonames(uwep), uwep->quan - 1L);
            switch (ynq(qbuf)) {
            case 'q':
                return ECMD_OK;
            case 'y':
                /* leave 1 wielded, split rest off and put into quiver */
                newquiver = splitobj(uwep, uwep->quan - 1L);
                finish_splitting(newquiver);
                goto quivering;
            default:
                break;
            }
            Strcpy(qbuf, "代わりにすべてを矢筒に準備するか?");
        } else {
            Sprintf(qbuf, "%sを装備している。代わりに矢筒に準備するか?",
                    simpleonames(uwep));
        }
        /* require confirmation to ready the main weapon */
        if (ynq(qbuf) != 'y') {
            /* Shk_Your() writes only ownership prefix into qbuf
               (for example, "あなたの" / "店主の"). */
            (void) Shk_Your(qbuf, uwep); /* replace qbuf[] contents */
            pline("%s%sはそのまま装備されている.",
                  qbuf, simpleonames(uwep));
            return ECMD_OK;
        }
        /* quivering main weapon, so no longer wielding it */
        setuwep((struct obj *) 0);
        untwoweapon();
        was_uwep = TRUE;
    } else if (newquiver == uswapwep) {
        if (uswapwep->quan > 1L && inv_cnt(FALSE) < invlet_basic
            && splittable(uswapwep)) {
            Sprintf(qbuf, "%s%ld個の%sを装備している。%ld個を矢筒に準備するか?",
                u.twoweap ? "二刀流で" : "副武器として",
                    uswapwep->quan, simpleonames(uswapwep),
                    uswapwep->quan - 1L);
            switch (ynq(qbuf)) {
            case 'q':
                return ECMD_OK;
            case 'y':
                /* leave 1 alt-wielded, split rest off and put into quiver */
                newquiver = splitobj(uswapwep, uswapwep->quan - 1L);
                finish_splitting(newquiver);
                goto quivering;
            default:
                break;
            }
            Strcpy(qbuf, "代わりにすべてを矢筒に準備するか?");
        } else {
            Sprintf(qbuf, "%sを%s装備している。代わりに矢筒に準備するか?",
                    simpleonames(uswapwep),
                    u.twoweap ? "二刀流で" : "副武器として");
        }
        /* require confirmation to ready the alternate weapon */
        if (ynq(qbuf) != 'y') {
            /* qbuf receives ownership prefix from Shk_Your(); the noun
               phrase itself is appended by this pline() call. */
            (void) Shk_Your(qbuf, uswapwep); /* replace qbuf[] contents */
            pline("%s%sはそのまま%s.", qbuf,
                  simpleonames(uswapwep),
                  u.twoweap ? "二刀流で構えられている"
                            : "副武器として装備されている");
            return ECMD_OK;
        }
        /* quivering alternate weapon, so no more uswapwep */
        setuswapwep((struct obj *) 0);
        untwoweapon();
    }

 quivering:
    if (!strcmp(verb, "ready")) {
        /* place item in quiver before printing so that inventory feedback
           includes "(at the ready)" */
        setuqwep(newquiver);
        prinv((char *) 0, newquiver, 0L);
    } else { /* verb=="fire", manually refilling quiver during 'f'ire */
        /* prefix item with description of action, so don't want that to
           include "(at the ready)" */
        prinv("準備した:", newquiver, 0L);
        setuqwep(newquiver);
    }

    /* quiver is a convenience slot and manipulating it ordinarily
       consumes no time, but unwielding primary or secondary weapon
       should take time (perhaps we're adjacent to a rust monster
       or disenchanter and want to hit it immediately, but not with
       something we're wielding that's vulnerable to its damage) */
    res = 0;
    if (was_uwep) {
        You("今は%s.", empty_handed());
        res = 1;
    } else if (was_twoweap && !u.twoweap) {
        You("%s.", are_no_longer_twoweap);
        res = 1;
    }
    return res ? ECMD_TIME : ECMD_OK;
}

/* used for #rub and for applying pick-axe, whip, grappling hook or polearm */
boolean
wield_tool(struct obj *obj,
           const char *verb) /* "rub",&c */
{
    const char *what;
    const char *jpverb;
    boolean more_than_1;

    if (uwep && obj == uwep)
        return TRUE; /* nothing to do if already wielding it */

    if (!verb)
        verb = "wield";
    jpverb = jp_wield_verb(verb);
    what = xname(obj);
    more_than_1 = (obj->quan > 1L || strstri(what, "pair of ") != 0
                   || strstri(what, "s of ") != 0);

    if (obj->owornmask & (W_ARMOR | W_ACCESSORY)) {
        You_cant("%sを着用している間は使えない。", xname(obj));
        return FALSE;
    }
    if (uwep && welded(uwep)) {
        if (flags.verbose) {
            const char *hand = jp_body_part(HAND);

            if (bimanual(uwep))
                hand = makeplural(hand);
            if (strstri(what, "pair of ") != 0)
                more_than_1 = FALSE;
            pline("武器があなたの%sに貼り付いているため、%sを%sことはできない.",
                  hand, xname(obj), jpverb);
        } else {
            You_cant("それはできない.");
        }
        return FALSE;
    }
    if (cantwield(gy.youmonst.data)) {
        You_cant("%sをしっかりと握ることはできない。", more_than_1 ? "それらは" : "それは");
        return FALSE;
    }
    /* check shield */
    if (uarms && bimanual(obj)) {
        You("盾を装備したままでは両手用の%sを%sことはできない.",
            (obj->oclass == WEAPON_CLASS) ? "武器" : "道具", jpverb);
        return FALSE;
    }

    if (uquiver == obj)
        setuqwep((struct obj *) 0);
    if (uswapwep == obj) {
        (void) doswapweapon();
        /* doswapweapon might fail */
        if (uswapwep == obj)
            return FALSE;
    } else {
        struct obj *oldwep = uwep;

        if (will_weld(obj)) {
            /* hope none of ready_weapon()'s early returns apply here... */
            (void) ready_weapon(obj);
        } else {
            You("今は%sを装備した.", doname(obj));
            setuwep(obj);
        }
        if (flags.pushweapon && oldwep && uwep != oldwep)
            setuswapwep(oldwep);
    }
    if (uwep && uwep != obj)
        return FALSE; /* rewielded old object after dying */
    /* applying weapon or tool that gets wielded ends two-weapon combat */
    if (u.twoweap)
        untwoweapon();
    if (obj->oclass != WEAPON_CLASS)
        gu.unweapon = TRUE;
    return TRUE;
}

int
can_twoweapon(void)
{
    struct obj *otmp;

    if (!could_twoweap(gy.youmonst.data)) {
        if (Upolyd)
            You_cant("現在の姿では二つの武器を使うことはできない。");
        else
            pline("その職業では二つの武器を同時に使うことはできない.");
    } else if (!uwep || !uswapwep) {
        const char *hand_s = jp_body_part(HAND);

        if (!uwep && !uswapwep)
            hand_s = makeplural(hand_s);
        /* "your hands are empty" or "your {left|right} hand is empty" */
        Your("%s%sが空だった.", uwep ? "左" : uswapwep ? "右" : "", hand_s);
    } else if (!TWOWEAPOK(uwep) || !TWOWEAPOK(uswapwep)) {
        otmp = !TWOWEAPOK(uwep) ? uwep : uswapwep;
        pline("%sは%s武器として適していない.", xname(otmp),
              (otmp == uwep) ? "主" : "副");
    } else if (bimanual(uwep) || bimanual(uswapwep)) {
        otmp = bimanual(uwep) ? uwep : uswapwep;
        pline("%sは片手用ではない.", xname(otmp));
    } else if (uarms) {
        You_cant("盾を着用している間、二つの武器を使うことはできなかった。");
    } else if (uswapwep->oartifact) {
        pline("%sはもう一方の武器として構えられることを拒んだ!",
              xname(uswapwep));
    } else if (uswapwep->otyp == CORPSE && cant_wield_corpse(uswapwep)) {
        /* [Note: !TWOWEAPOK() check prevents ever getting here...] */
        ; /* must be life-saved to reach here; return FALSE */
    } else if (Glib || uswapwep->cursed) {
        if (!Glib)
            set_bknown(uswapwep, 1);
        drop_uswapwep();
    } else
        return TRUE;
    return FALSE;
}

/* uswapwep has become cursed while in two-weapon combat mode or hero is
   attempting to dual-wield when it is already cursed or hands are slippery */
void
drop_uswapwep(void)
{
    char left_hand[QBUFSZ];
    struct obj *obj = uswapwep;

    /* this used to use jp_body_part_plural(HAND) but in order to be
       dual-wielded, or to get this far attempting to achieve that,
       uswapwep must be one-handed; since it's secondary, the hand must
       be the left one */
    Sprintf(left_hand, "左%s", jp_body_part(HAND));
    if (!obj->cursed)
        /* attempting to two-weapon while Glib */
        pline("%sが%sから滑り落ちた!", xname(obj), left_hand);
    else if (!u.twoweap)
        /* attempting to two-weapon when uswapwep is cursed */
        pline("%sは手をすり抜け、%sから落ちた!",
              xname(obj), left_hand);
    else
        /* already two-weaponing but can't anymore because uswapwep has
           become cursed */
          Your("%sがけいれんし、%sを落とした!", left_hand,
                 xname(obj));
    dropx(obj);
}

void
set_twoweap(boolean on_off)
{
    if (on_off != u.twoweap) {
        u.twoweap = on_off;
        if (flags.weaponstatus)
            disp.botl = TRUE;
    }
}

/* the #twoweapon command */
int
dotwoweapon(void)
{
    /* You can always toggle it off */
    if (u.twoweap) {
        You("主武器に持ち替えた.");
        set_twoweap(FALSE); /* u.twoweap = FALSE */
        update_inventory();
        return ECMD_OK;
    }

    /* May we use two weapons? */
    if (can_twoweapon()) {
        /* Success! */
        You("二刀流で戦い始めた.");
        set_twoweap(TRUE); /* u.twoweap = TRUE */
        update_inventory();
        return (rnd(20) > ACURR(A_DEX)) ? ECMD_TIME : ECMD_OK;
    }
    return ECMD_OK;
}

/*** Functions to empty a given slot ***/
/* These should be used only when the item can't be put back in
 * the slot by life saving.  Proper usage includes:
 * 1.  The item has been eaten, stolen, burned away, or rotted away.
 * 2.  Making an item disappear for a bones pile.
 */
void
uwepgone(void)
{
    if (uwep) {
        if (artifact_light(uwep) && uwep->lamplit) {
            end_burn(uwep, FALSE);
            if (!Blind)
                pline("%sは輝かなくなった.", xname(uwep));
        }
        setworn((struct obj *) 0, W_WEP);
        gu.unweapon = TRUE;
        update_inventory();
    }
}

void
uswapwepgone(void)
{
    if (uswapwep) {
        setworn((struct obj *) 0, W_SWAPWEP);
        update_inventory();
    }
}

void
uqwepgone(void)
{
    if (uquiver) {
        setworn((struct obj *) 0, W_QUIVER);
        update_inventory();
    }
}

void
untwoweapon(void)
{
    if (u.twoweap) {
        You("%s.", can_no_longer_twoweap);
        set_twoweap(FALSE); /* u.twoweap = FALSE */
        update_inventory();
    }
    return;
}

/* enchant wielded weapon */
int
chwepon(struct obj *otmp, int amount)
{
    const char *color = hcolor((amount < 0) ? NH_BLACK : NH_BLUE);
    const char *xtime, *wepname = "";
    boolean multiple;
    int otyp = STRANGE_OBJECT;

    if (!uwep || (uwep->oclass != WEAPON_CLASS && !is_weptool(uwep))) {
        char buf[BUFSZ];

        if (amount >= 0 && uwep && will_weld(uwep)) { /* cursed tin opener */
            if (!Blind) {
                Sprintf(buf, "%sが%sオーラで輝いた.",
                        xname(uwep), hcolor(NH_AMBER));
                uwep->bknown = !Hallucination; /* ok to bypass set_bknown() */
            } else {
                /* cursed tin opener is wielded in right hand */
                Sprintf(buf, "右%sがうずいた.", jp_body_part(HAND));
            }
            uncurse(uwep);
            update_inventory();
        } else {
            Sprintf(buf, "%sが%s.", jp_body_part_plural(HAND),
                    (amount >= 0) ? "ぴくりと震えた" : "むずむずする");
        }
        strange_feeling(otmp, buf); /* pline()+docall()+useup() */
        exercise(A_DEX, (boolean) (amount >= 0));
        return 0;
    }

    if (otmp && otmp->oclass == SCROLL_CLASS)
        otyp = otmp->otyp;

    if (uwep->otyp == WORM_TOOTH && amount >= 0) {
        multiple = (uwep->quan > 1L);
        /* order: message, transformation, shop handling */
           Your("%sが%sさらに鋭くなった.", simpleonames(uwep),
               multiple ? "融合して" : "");
        uwep->otyp = CRYSKNIFE;
        uwep->oerodeproof = 0;
        if (multiple) {
            uwep->quan = 1L;
            uwep->owt = weight(uwep);
        }
        if (uwep->cursed)
            uncurse(uwep);
        /* update shop bill to reflect new higher value */
        if (uwep->unpaid)
            alter_cost(uwep, 0L);
        if (otyp != STRANGE_OBJECT)
            makeknown(otyp);
        if (multiple)
            encumber_msg();
        return 1;
    } else if (uwep->otyp == CRYSKNIFE && amount < 0) {
        multiple = (uwep->quan > 1L);
        /* order matters: message, shop handling, transformation */
           Your("%sが%sずっと鈍くなった.", simpleonames(uwep),
               multiple ? "融合して" : "");
        costly_alteration(uwep, COST_DEGRD); /* DECHNT? other? */
        uwep->otyp = WORM_TOOTH;
        uwep->oerodeproof = 0;
        if (multiple) {
            uwep->quan = 1L;
            uwep->owt = weight(uwep);
        }
        if (otyp != STRANGE_OBJECT && otmp->bknown)
            makeknown(otyp);
        if (multiple)
            encumber_msg();
        return 1;
    }

    if (has_oname(uwep))
        wepname = ONAME(uwep);
    if (amount < 0 && uwep->oartifact && restrict_name(uwep, wepname)) {
        if (!Blind)
            pline("%sが%s色にかすかに輝いた.", xname(uwep), color);
        return 1;
    }
    /* there is a (soft) upper and lower limit to uwep->spe */
    if (((uwep->spe > 5 && amount >= 0) || (uwep->spe < -5 && amount < 0))
        && rn2(3)) {
        if (!Blind)
            pline("%sが%s色に激しく輝いたあと、消えてしまった.",
                  xname(uwep), color);
        else
            pline("%sは消えてしまった.", xname(uwep));

        useupall(uwep); /* let all of them disappear */
        return 1;
    }
    if (!Blind) {
          xtime = (amount * amount == 1) ? "一瞬" : "しばらく";
          pline("%sが%s色に%s輝いた.",
              xname(uwep), color, xtime);
        if (otyp != STRANGE_OBJECT && uwep->known
            && (amount > 0 || (amount < 0 && otmp->bknown)))
            makeknown(otyp);
    }
    if (amount < 0)
        costly_alteration(uwep, COST_DECHNT);
    uwep->spe += amount;
    if (amount > 0) {
        if (uwep->cursed)
            uncurse(uwep);
        /* update shop bill to reflect new higher price */
        if (uwep->unpaid)
            alter_cost(uwep, 0L);
    }

    /*
     * Enchantment, which normally improves a weapon, has an
     * additional adverse reaction on Magicbane whose effects are
     * spe dependent.  Give an obscure clue here.
     */
    if (u_wield_art(ART_MAGICBANE) && uwep->spe >= 0) {
           Your("右%sが%s.", jp_body_part(HAND),
               (((amount > 1) && (uwep->spe > 1)) ? "ひきつった" : "かゆくなった"));
    }

    /* an elven magic clue, cookie@keebler */
    /* elven weapons vibrate warningly when enchanted beyond a limit */
    if ((uwep->spe > 5)
        && (is_elven_weapon(uwep) || uwep->oartifact || !rn2(7)))
        pline("%sが突然震えた.", xname(uwep));

    return 1;
}

int
welded(struct obj *obj)
{
    if (obj && obj == uwep && will_weld(obj)) {
        set_bknown(obj, 1);
        return 1;
    }
    return 0;
}

void
weldmsg(struct obj *obj)
{
    long savewornmask;
    const char *hand = jp_body_part(HAND);

    if (bimanual(obj))
        hand = makeplural(hand);
    savewornmask = obj->owornmask;
    obj->owornmask = 0L; /* suppress doname()'s "(weapon in hand)";
                          * Yobjnam2() doesn't actually need this because
                          * it is based on xname() rather than doname() */
    pline("%sはあなたの%sに貼りついた!", xname(obj), hand);
    obj->owornmask = savewornmask;
}

/* test whether monster's wielded weapon is stuck to hand/paw/whatever */
boolean
mwelded(struct obj *obj)
{
    /* caller is responsible for making sure this is a monster's item */
    if (obj && (obj->owornmask & W_WEP) && will_weld(obj))
        return TRUE;
    return FALSE;
}

/*wield.c*/


