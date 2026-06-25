/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-25. */
/* NetHack 5.0	eat.c	$NHDT-Date: 1781973048 2026/06/20 16:30:48 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.354 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2012. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"

staticfn int eatmdone(void);
staticfn int eatfood(void);
staticfn struct obj *costly_tin(int);
staticfn int opentin(void);
staticfn int unfaint(void);

staticfn const char *food_xname(struct obj *, boolean);
staticfn void choke(struct obj *);
staticfn void recalc_wt(void);
staticfn int adj_victual_nutrition(void);
staticfn struct obj *touchfood(struct obj *);
staticfn void do_reset_eat(void);
staticfn void done_eating(boolean);
staticfn void cprefx(int);
staticfn boolean temp_givit(int, struct permonst *);
staticfn void givit(int, struct permonst *);
staticfn void eye_of_newt_buzz(void);
staticfn void cpostfx(int);
staticfn void use_up_tin(struct obj *) NONNULLARG1;
staticfn void consume_tin(const char *);
staticfn void start_tin(struct obj *);
staticfn int eatcorpse(struct obj *);
staticfn void start_eating(struct obj *, boolean);
staticfn void garlic_breath(struct monst *);
staticfn boolean fprefx(struct obj *);
staticfn void fpostfx(struct obj *);
staticfn int bite(void);
staticfn int edibility_prompts(struct obj *);
staticfn int doeat_nonfood(struct obj *);
staticfn int tinopen_ok(struct obj *);
staticfn int rottenfood(struct obj *);
staticfn void eatspecial(void);
staticfn int bounded_increase(int, int, int);
staticfn void accessory_has_effect(struct obj *);
staticfn void eataccessory(struct obj *);
staticfn const char *foodword(struct obj *);
staticfn const char *jp_foodword_for_display(struct obj *);
staticfn int tin_variety(struct obj *, boolean);
staticfn boolean maybe_cannibal(int, boolean);
staticfn int eat_ok(struct obj *);
staticfn int offer_ok(struct obj *);
staticfn int tin_ok(struct obj *);

/* also used to see if you're allowed to eat cats and dogs */
#define CANNIBAL_ALLOWED() (Role_if(PM_CAVE_DWELLER) || Race_if(PM_ORC))

/* Rider corpses are treated as non-rotting so that attempting to eat one
   will be sure to reach the stage of eating where that meal is fatal;
   acid blob corpses eventually rot away to nothing but before that happens
   they can be sacrificed regardless of age which implies that they never
   become rotten */
#define nonrotting_corpse(mnum) \
    ((mnum) == PM_LIZARD || (mnum) == PM_LICHEN \
     || is_rider(&mons[mnum])                   \
     || (mnum) == PM_ACID_BLOB)

/* non-rotting non-corpses; unlike lizard corpses, these items will behave
   as if rotten if they are cursed (fortune cookies handled elsewhere) */
#define nonrotting_food(otyp) \
    ((otyp) == LEMBAS_WAFER || (otyp) == CRAM_RATION)

/* see hunger states in hack.h - texts used on bottom line
   Also used in botl.c and insight.c  */
const char *const hu_stat[] = {
    "Satiated", "        ", "Hungry  ", "Weak    ",
    "Fainting", "Fainted ", "Starved "
};

/* display-only hunger text for localized UI paths */
const char *
jp_hunger_status_for_display(int uhs, boolean include_not_hungry)
{
    switch (uhs) {
    case SATIATED:
        return "満腹";
    case NOT_HUNGRY:
        return include_not_hungry ? "空腹ではない" : "";
    case HUNGRY:
        return "空腹";
    case WEAK:
        return "衰弱";
    case FAINTING:
        return "失神寸前";
    case FAINTED:
        return "失神";
    case STARVED:
        return "飢餓";
    default:
        return include_not_hungry ? "空腹ではない" : "";
    }
}

static const struct victual_info zero_victual = { 0 };

/* used by getobj() callback routines eat_ok()/offer_ok()/tin_ok() to
   indicate whether player was given an opportunity to eat or offer or
   tin an item on the floor and declined, in order to insert "else"
   into the "you don't have anything [else] to {eat | offer | tin}"
   feedback if hero lacks any suitable items in inventory
   [reinitialized every time it's used so does not need to be placed
   in struct instance_globals g for potential bulk reinitialization] */
static int getobj_else = 0;

/*
 * Decide whether a particular object can be eaten by the possibly
 * polymorphed character.  Not used for monster checks.
 */
boolean
is_edible(struct obj *obj)
{
    /* protect invocation tools but not Rider corpses (handled elsewhere)*/
    /* if (obj->oclass != FOOD_CLASS && obj_resists(obj, 0, 0)) */
    if (objects[obj->otyp].oc_unique)
        return FALSE;
    /* above also prevents the Amulet from being eaten, so we must never
       allow fake amulets to be eaten either [which is already the case] */

    if (gy.youmonst.data == &mons[PM_FIRE_ELEMENTAL]
        && is_flammable(obj))
        return TRUE;

    if (metallivorous(gy.youmonst.data) && is_metallic(obj)
        && (gy.youmonst.data != &mons[PM_RUST_MONSTER] || is_rustprone(obj)))
        return TRUE;

    /* Ghouls only eat non-veggy corpses or eggs (see dogfood()) */
    if (u.umonnum == PM_GHOUL)
        return (boolean)((obj->otyp == CORPSE
                          && !vegan(&mons[obj->corpsenm]))
                         || (obj->otyp == EGG));

    if (u.umonnum == PM_GELATINOUS_CUBE && is_organic(obj)
        /* [g-cubes can eat containers and retain all contents
            as engulfed items, but poly'd player can't do that] */
        && !Has_contents(obj))
        return TRUE;

    return (boolean) (obj->oclass == FOOD_CLASS);
}

/* used for hero init, life saving (if choking), and prayer results of fix
   starving, fix weak from hunger, or golden glow boon (if u.uhunger < 900) */
void
init_uhunger(void)
{
    disp.botl = (u.uhs != NOT_HUNGRY || ATEMP(A_STR) < 0);
    u.uhunger = 900;
    u.uhs = NOT_HUNGRY;
    if (ATEMP(A_STR) < 0) {
        ATEMP(A_STR) = 0;
        encumber_msg();
    }
}

/* tin types [SPINACH_TIN = -1, overrides corpsenm, nut==600] */
static const struct {
    const char *txt;                      /* description */
    int nut;                              /* nutrition */
    Bitfield(fodder, 1);                  /* stocked by health food shops */
    Bitfield(greasy, 1);                  /* causes slippery fingers */
} tintxts[] = { { "rotten", -50, 0, 0 },  /* ROTTEN_TIN = 0 */
                { "homemade", 50, 1, 0 }, /* HOMEMADE_TIN = 1 */
                { "soup made from", 20, 1, 0 },
                { "french fried", 40, 0, 1 },
                { "pickled", 40, 1, 0 },
                { "boiled", 50, 1, 0 },
                { "smoked", 50, 1, 0 },
                { "dried", 55, 1, 0 },
                { "deep fried", 60, 0, 1 },
                { "szechuan", 70, 1, 0 },
                { "broiled", 80, 0, 0 },
                { "stir fried", 80, 0, 1 },
                { "sauteed", 95, 0, 0 },
                { "candied", 100, 1, 0 },
                { "pureed", 500, 1, 0 },
                { "", 0, 0, 0 } };
#define TTSZ SIZE(tintxts)

static const char *const tintxts_jp[] = {
    "腐った",
    "手製の",
    "スープにした",
    "フライにした",
    "酢漬けにした",
    "ゆでた",
    "燻製にした",
    "干した",
    "揚げた",
    "四川風の",
    "あぶり焼きにした",
    "炒めた",
    "ソテーにした",
    "砂糖漬けにした",
    "すり潰した",
    ""
};

enum {
    TIN_SOUP_MADE_FROM = 2,
    TIN_FRENCH_FRIED = 3,
    TIN_PICKLED = 4,
    TIN_BOILED = 5,
    TIN_SMOKED = 6,
    TIN_DRIED = 7,
    TIN_DEEP_FRIED = 8,
    TIN_SZECHUAN = 9,
    TIN_BROILED = 10,
    TIN_STIR_FRIED = 11,
    TIN_SAUTEED = 12,
    TIN_CANDIED = 13,
    TIN_PUREED = 14
};

static const struct {
    const char *txt;
    int variety;
} tintxts_jp_aliases[] = {
    { "腐敗した", ROTTEN_TIN },
    { "腐っている", ROTTEN_TIN },
    { "手製", HOMEMADE_TIN },
    { "自家製", HOMEMADE_TIN },
    { "スープ", TIN_SOUP_MADE_FROM },
    { "フライ", TIN_FRENCH_FRIED },
    { "フライド", TIN_FRENCH_FRIED },
    { "酢漬け", TIN_PICKLED },
    { "ゆで", TIN_BOILED },
    { "茹で", TIN_BOILED },
    { "燻製", TIN_SMOKED },
    { "干し", TIN_DRIED },
    { "乾燥", TIN_DRIED },
    { "揚げ", TIN_DEEP_FRIED },
    { "四川風", TIN_SZECHUAN },
    { "あぶり焼き", TIN_BROILED },
    { "炙り焼き", TIN_BROILED },
    { "炒め", TIN_STIR_FRIED },
    { "ソテー", TIN_SAUTEED },
    { "砂糖漬け", TIN_CANDIED },
    { "すり潰し", TIN_PUREED },
    { "ピューレ", TIN_PUREED },
    { 0, -1 }
};

staticfn void jp_tin_content_name(int, int, char *, size_t);
staticfn void jp_tin_display_name(int, int, char *, size_t);

staticfn void
jp_tin_content_name(int tvariety, int mnum, char *buf, size_t bufsz)
{
    char foodbuf[BUFSZ];
    const char *qualifier = "";

    if (!buf || bufsz == 0)
        return;

    if (tvariety == SPINACH_TIN) {
        Snprintf(buf, bufsz, "ほうれん草");
        return;
    }
    if (mnum == NON_PM) {
        Snprintf(buf, bufsz, "空");
        return;
    }

    if (tvariety >= 0 && tvariety < (int) TTSZ)
        qualifier = tintxts_jp[tvariety];

    if (vegetarian(&mons[mnum]))
        Snprintf(foodbuf, sizeof foodbuf, "%s", jp_pmname(&mons[mnum], NEUTRAL));
    else
        Snprintf(foodbuf, sizeof foodbuf, "%s肉", jp_pmname(&mons[mnum], NEUTRAL));

    if (qualifier && *qualifier)
        Snprintf(buf, bufsz, "%s%s", qualifier, foodbuf);
    else
        Snprintf(buf, bufsz, "%s", foodbuf);
}

staticfn void
jp_tin_display_name(int tvariety, int mnum, char *buf, size_t bufsz)
{
    char contentbuf[BUFSZ];

    if (!buf || bufsz == 0)
        return;

    if (tvariety == SPINACH_TIN) {
        Snprintf(buf, bufsz, "ほうれん草の缶詰");
        return;
    }
    if (mnum == NON_PM) {
        Snprintf(buf, bufsz, "空の缶");
        return;
    }

    jp_tin_content_name(tvariety, mnum, contentbuf, sizeof contentbuf);
    Snprintf(buf, bufsz, "%sの缶詰", contentbuf);
}

/* called after mimicking is over */
staticfn int
eatmdone(void)
{
    /* release `eatmbuf' */
    if (ge.eatmbuf) {
        if (gn.nomovemsg == ge.eatmbuf)
            gn.nomovemsg = 0;
        free((genericptr_t) ge.eatmbuf), ge.eatmbuf = 0;
    }
    /* update display */
    if (U_AP_TYPE) {
        gy.youmonst.m_ap_type = M_AP_NOTHING;
        newsym(u.ux, u.uy);
    }
    return 0;
}

/* called when hallucination is toggled */
void
eatmupdate(void)
{
    const char *altmsg = 0;
    int altapp = 0; /* lint suppression */

    if (!ge.eatmbuf || gn.nomovemsg != ge.eatmbuf)
        return;

    if (is_obj_mappear(&gy.youmonst,ORANGE) && !Hallucination) {
        /* revert from hallucinatory to "normal" mimicking */
        altmsg = "今は自分自身のふりをするのがお好みのようだ.";
        altapp = GOLD_PIECE;
    } else if (is_obj_mappear(&gy.youmonst,GOLD_PIECE) && Hallucination) {
        /* won't happen; anything which might make immobilized
           hero begin hallucinating (black light attack, theft
           of Grayswandir) will terminate the mimicry first */
        altmsg = "あなたの外皮は無傷で残った.";
        altapp = ORANGE;
    }

    if (altmsg) {
        /* replace end-of-mimicking message */
        unsigned amlen = Strlen(altmsg);
        if (amlen > Strlen(ge.eatmbuf)) {
            free((genericptr_t) ge.eatmbuf);
            ge.eatmbuf = (char *) alloc(amlen + 1);
        }
        gn.nomovemsg = strcpy(ge.eatmbuf, altmsg);
        /* update current image */
        gy.youmonst.mappearance = altapp;
        newsym(u.ux, u.uy);
    }
}

/* ``[the(] singular(food, xname) [)]'' */
staticfn const char *
food_xname(struct obj *food, boolean the_pfx)
{
    const char *result;

    if (food->otyp == CORPSE) {
        result = jp_corpse_xname(food, (const char *) 0,
                                 CXN_SINGULAR | (the_pfx ? CXN_PFX_THE : 0));
    } else {
        /* the ordinary case */
        result = singular(food, xname);
    }
    if (the_pfx)
        result = the(result);
    return result;
}

/* Created by GAN 01/28/87
 * Amended by AKP 09/22/87: if not hard, don't choke, just vomit.
 * Amended by 3.  06/12/89: if not hard, sometimes choke anyway, to keep risk.
 *                11/10/89: if hard, rarely vomit anyway, for slim chance.
 *
 * To a full belly all food is bad. (It.)
 */
staticfn void
choke(struct obj *food)
{
    /* only happens if you were satiated */
    if (u.uhs != SATIATED) {
        if (!food || food->otyp != AMULET_OF_STRANGULATION)
            return;
    } else if (Role_if(PM_KNIGHT) && u.ualign.type == A_LAWFUL) {
        adjalign(-1); /* gluttony is unchivalrous */
        You_feel("大食漢になったような気がした!");
    }

    exercise(A_CON, FALSE);

    if (Breathless || Hunger || (!Strangled && !rn2(20))) {
        /* choking by eating AoS doesn't involve stuffing yourself */
        if (food && food->otyp == AMULET_OF_STRANGULATION) {
            You("喉に詰まらせたが、どうにか落ち着きを取り戻した.");
            return;
        }
        You("腹いっぱい詰め込んだあと、盛大に吐いた.");
        morehungry(Hunger ? (u.uhunger - 60) : 1000); /* just got very sick! */
        vomit();
    } else {
        svk.killer.format = KILLED_BY_AN;
        /*
         * Note all "killer"s below read "Choked on %s" on the
         * high score list & tombstone.  So plan accordingly.
         */
        if (food) {
            You("%sで喉を詰まらせた.", jp_foodword_for_display(food));
            if (food->oclass == COIN_CLASS) {
                Strcpy(svk.killer.name, "very rich meal");
            } else {
                svk.killer.format = KILLED_BY;
                Strcpy(svk.killer.name, killer_xname(food));
            }
        } else {
            You("それで喉を詰まらせた.");
            Strcpy(svk.killer.name, "quick snack");
        }
        You("死んだ...");
        done(CHOKING);
    }
}

/* modify victual.piece->owt depending on time spent consuming it */
staticfn void
recalc_wt(void)
{
    struct obj *piece = svc.context.victual.piece;

    if (!piece) {
        impossible("recalc_wt without piece");
        return;
    }
    debugpline1("Old weight = %d", piece->owt);
    debugpline2("Used time = %d, Req'd time = %d",
                svc.context.victual.usedtime, svc.context.victual.reqtime);
    piece->owt = weight(piece);
    debugpline1("New weight = %d", piece->owt);
}

/* called when eating interrupted by an event */
void
reset_eat(void)
{
    /* we only set a flag here - the actual reset process is done after
     * the round is spent eating.
     */
    if (svc.context.victual.eating && !svc.context.victual.doreset) {
        debugpline0("reset_eat...");
        svc.context.victual.doreset = 1;
    }
    return;
}

/* base nutrition of a food-class object; this used to include a variation
   of the code that is now in adj_victual_nutrition() and was moved due to
   its affect on weight() */
unsigned
obj_nutrition(struct obj *otmp)
{
    unsigned nut = (otmp->otyp == CORPSE) ? mons[otmp->corpsenm].cnutrit
                      : otmp->globby ? otmp->owt
                         : (unsigned) objects[otmp->otyp].oc_nutrition;

    return nut;
}

/* nutrition increment for next byte; this used to be factored into
   victual.piece->oeaten but that produced weight change if hero
   polymorphed to or from one of the races which has nutrition adjusted */
staticfn int
adj_victual_nutrition(void)
{
    int otyp = svc.context.victual.piece->otyp;
    /* note: adj_victual_nutrition() is only called when 'nmod' is negative */
    int nut = -svc.context.victual.nmod; /* convert 'nmod' to positive */

    assert(nut > 0);
    if (otyp == LEMBAS_WAFER) {
        if (maybe_polyd(is_elf(gy.youmonst.data), Race_if(PM_ELF)))
            nut += (nut + 2) / 4; /* 800 -> 1000 */
        else if (maybe_polyd(is_orc(gy.youmonst.data), Race_if(PM_ORC)))
            nut -= (nut + 2) / 4; /* 800 -> 600 */
    } else if (otyp == CRAM_RATION) {
        if (maybe_polyd(is_dwarf(gy.youmonst.data), Race_if(PM_DWARF)))
            nut += (nut + 3) / 6; /* 600 -> 700 */
    }
    nut = max(nut, 1);
    return nut;
}

/* might destroy otmp if hero drops it */
staticfn struct obj *
touchfood(struct obj *otmp)
{
    if (otmp->quan > 1L) {
        if (!carried(otmp))
            (void) splitobj(otmp, otmp->quan - 1L);
        else
            otmp = splitobj(otmp, 1L);
        debugpline0("split food,");
    }

    if (!otmp->oeaten) {
        costly_alteration(otmp, COST_BITE);
        otmp->oeaten = obj_nutrition(otmp);
    }

    if (carried(otmp)) {
        freeinv(otmp);
        if (inv_cnt(FALSE) >= invlet_basic) {
            sellobj_state(SELL_DONTSELL);
            dropy(otmp);
            sellobj_state(SELL_NORMAL);
            if (otmp->where == OBJ_DELETED)
                otmp = (struct obj *) NULL;
        } else {
            otmp = addinv_nomerge(otmp);
        }
    }
    return otmp;
}

/* When food decays, in the middle of your meal, we don't want to dereference
 * any dangling pointers, so set it to null (which should still trigger
 * do_reset_eat() at the beginning of eatfood()) and check for null pointers
 * in do_reset_eat().
 */
void
food_disappears(struct obj *obj)
{
    if (obj == svc.context.victual.piece)
        svc.context.victual = zero_victual; /* victual.piece = 0, .o_id = 0 */

    if (obj->timed)
        obj_stop_timers(obj);
}

/* renaming an object used to result in it having a different address,
   so the sequence start eating/opening, get interrupted, name the food,
   resume eating/opening would restart from scratch */
void
food_substitution(struct obj *old_obj, struct obj *new_obj)
{
    if (old_obj == svc.context.victual.piece) {
        svc.context.victual.piece = new_obj;
        svc.context.victual.o_id = new_obj->o_id;
    }
    if (old_obj == svc.context.tin.tin) {
        svc.context.tin.tin = new_obj;
        svc.context.tin.o_id = new_obj->o_id;
    }
}

staticfn void
do_reset_eat(void)
{
    debugpline0("do_reset_eat...");
    if (svc.context.victual.piece) {
        struct obj *otmp;

        svc.context.victual.o_id = 0;
        otmp = touchfood(svc.context.victual.piece);
        svc.context.victual.piece = otmp;
        if (otmp) {
            svc.context.victual.o_id = otmp->o_id;
            recalc_wt();
        }
    }
    svc.context.victual.fullwarn
        = svc.context.victual.eating
        = svc.context.victual.doreset
        = 0;
    /* Do not set canchoke to FALSE; if we continue eating the same object
     * we need to know if canchoke was set when they started eating it the
     * previous time.  And if we don't continue eating the same object
     * canchoke always gets recalculated anyway.
     */
    stop_occupation();
    newuhs(FALSE);
}

/* if 'prop' is only set because of a timed value (so not an intrinsic
   attribute or because of polymorph shape or worn or carried gear), return
   its timeout, otherwise return 0; used by enlightenment */
long
temp_resist(int prop)
{
    struct prop *p = &u.uprops[prop];
    long timeout = p->intrinsic & TIMEOUT;

    if (timeout
        /* and if not also protected by polymorph form */
        && (p->intrinsic & ~TIMEOUT) == 0L
        /* and not by worn gear (dragon armor) */
        && !p->extrinsic
        /* and property is not blocked; we don't expect this, but if it
           is then the timeout doesn't matter so we won't extend that */
        && !p->blocked) {
        return timeout;
    }
    return 0L;
}

/* if temporary acid or stoning resistance is timing out while eating
   something which that resistance is protecting against, caller will
   extend resistance's duration so that it times out after meal finishes */
boolean
eating_dangerous_corpse(int res)
{
    struct obj *food;
    int mnum;

    if (go.occupation == eatfood
        && (food = svc.context.victual.piece) != 0
        && food->otyp == CORPSE
        && (mnum = food->corpsenm) >= LOW_PM
        && (carried(food) || obj_here(food, u.ux, u.uy))) {

        if (res == ACID_RES && acidic(&mons[mnum]))
            return TRUE;
        /* flesh_petrifies() includes Medusa as well as touch_petrifies() */
        if (res == STONE_RES && flesh_petrifies(&mons[mnum]))
            return TRUE;
    }
    return FALSE;
}

#if 0   /* no longer used */
staticfn void maybe_extend_timed_resist(int);

/* if temp resist against 'prop' is about to timeout, extend it slightly */
staticfn void
maybe_extend_timed_resist(int prop)
{
    long timeout = temp_resist(prop);

    /* if hero is being protected from nasty effects of current meal by
       temporary resistance (timed acid resist or timed stoning resist),
       prevent expiration from occurring while the meal is in progress
       so that player doesn't get feedback about becoming more vulnerable
       and then have the hero stay unharmed; has a minor side-effect of
       also extending the protection against other attacks of the sort
       being resisted */
    if (timeout == 1L) {
        set_itimeout(&u.uprops[prop].intrinsic, 2L);
    }
}
#endif

/* called each move during eating process */
staticfn int
eatfood(void)
{
    struct obj *food = svc.context.victual.piece;

    if (food && !carried(food) && !obj_here(food, u.ux, u.uy))
        food = 0;
    if (!food) {
        /* maybe it was stolen? */
        do_reset_eat();
        return 0;
    }
    if (!svc.context.victual.eating)
        return 0;

    if (++svc.context.victual.usedtime <= svc.context.victual.reqtime) {
        if (bite())
            return 0;
        return 1; /* still busy */
    } else {        /* done */
        done_eating(TRUE);
        return 0;
    }
}

staticfn void
done_eating(boolean message)
{
    struct obj *piece = svc.context.victual.piece;

    piece->in_use = TRUE;
    go.occupation = 0; /* do this early, so newuhs() knows we're done */
    newuhs(FALSE);
    if (gn.nomovemsg) {
        if (message)
            pline1(gn.nomovemsg);
        gn.nomovemsg = 0;
    } else if (message) {
        You("%sを%s.", food_xname(piece, FALSE),
            (gy.youmonst.data == &mons[PM_FIRE_ELEMENTAL])
                ? "消費し尽くした"
                : "食べ終えた");
    }

    if (piece->otyp == CORPSE || piece->globby)
        cpostfx(piece->corpsenm);
    else
        fpostfx(piece);

    if (carried(piece))
        useup(piece);
    else
        useupf(piece, 1L);

    svc.context.victual = zero_victual; /* victual.piece = 0, .o_id = 0 */
}

void
eating_conducts(struct permonst *pd)
{
    int ll_conduct = 0;

    if (!u.uconduct.food++) {
        livelog_printf(LL_CONDUCT, "初めて食事をした - %s",
                       pd->pmnames[NEUTRAL]);
        ll_conduct++;
    }
    if (!vegan(pd)) {
        if (!u.uconduct.unvegan++ && !ll_conduct) {
            livelog_printf(LL_CONDUCT,
                           "初めて動物性食品（%s）を口にした",
                           pd->pmnames[NEUTRAL]);
            ll_conduct++;
        }
    }
    if (!vegetarian(pd)) {
        if (!u.uconduct.unvegetarian && !ll_conduct)
            livelog_printf(LL_CONDUCT, "初めて肉（%s）を口にした",
                           pd->pmnames[NEUTRAL]);
        violated_vegetarian();
    }
}

/* handle side-effects of mind flayer's tentacle attack */
int
eat_brains(
    struct monst *magr,
    struct monst *mdef,
    boolean visflag,
    int *dmg_p) /* for dishing out extra damage in lieu of Int loss */
{
    struct permonst *pd = mdef->data;
    boolean give_nutrit = FALSE;
    int result = M_ATTK_HIT, xtra_dmg = rnd(10);

    /* previous tentacle attack might have triggered fatal passive
       counterattack [callers ought to be updated to avoid this situation] */
    if (magr != &gy.youmonst && DEADMONSTER(magr)) {
        return M_ATTK_AGR_DIED;
    }

    if (noncorporeal(pd)) {
        if (visflag)
            pline("%sの脳は無傷だった.",
                  (mdef == &gy.youmonst) ? "あなた" : l_monnam(mdef));
        return M_ATTK_MISS; /* side-effects can't occur */
    } else if (magr == &gy.youmonst) {
        You("%sの脳を食べた!", l_monnam(mdef));
    } else if (mdef == &gy.youmonst) {
        Your("脳を食べられた!");
    } else { /* monster against monster */
        if (visflag && canspotmon(mdef))
            pline("%sの脳が食べられた!", l_monnam(mdef));
    }

    if (flesh_petrifies(pd)) {
        /* mind flayer has attempted to eat the brains of a petrification
           inducing critter (most likely Medusa; attacking a cockatrice via
           tentacle-touch should have been caught before reaching this far) */
        if (magr == &gy.youmonst) {
            if (!Stone_resistance && !Stoned)
                make_stoned(5L, (char *) 0, KILLED_BY_AN,
                            jp_pmname(pd, Mgender(mdef)));
        } else {
            /* no need to check for poly_when_stoned or Stone_resistance;
               mind flayers don't have those capabilities */
            if (visflag && canseemon(magr))
                pline("%sは石になった!", l_monnam(magr));
            monstone(magr);
            if (!DEADMONSTER(magr)) {
                /* life-saved; don't continue eating the brains */
                return M_ATTK_MISS;
            } else {
                if (magr->mtame && !visflag)
                    /* parallels mhitm.c's brief_feeling */
                    You("一瞬悲しい考えが頭をよぎったが、すぐに消えた.");
                return M_ATTK_AGR_DIED;
            }
        }
    }

    if (magr == &gy.youmonst) {
        /*
         * player mind flayer is eating something's brain
         */
        eating_conducts(pd);
        if (mindless(pd)) { /* (cannibalism not possible here) */
            pline("%sは気づかなかった.", l_monnam(mdef));
            /* all done; no extra harm inflicted upon target */
            return M_ATTK_MISS;
        } else if (is_rider(pd)) {
            pline("それを摂取すると致命的だった.");
            Sprintf(svk.killer.name, "unwisely ate the brain of %s",
                    jp_pmname(pd, Mgender(mdef)));
            svk.killer.format = NO_KILLER_PREFIX;
            done(DIED);
            /* life-saving needed to reach here */
            exercise(A_WIS, FALSE);
            *dmg_p += xtra_dmg; /* Rider takes extra damage */
        } else {
            morehungry(-rnd(30)); /* cannot choke */
            if (ABASE(A_INT) < AMAX(A_INT)) {
                /* recover lost Int; won't increase current max */
                ABASE(A_INT) += rnd(4);
                if (ABASE(A_INT) > AMAX(A_INT))
                    ABASE(A_INT) = AMAX(A_INT);
                disp.botl = TRUE;
            }
            exercise(A_WIS, TRUE);
            *dmg_p += xtra_dmg;
        }
        /* targeting another mind flayer or your own underlying species
           is cannibalism */
        (void) maybe_cannibal(monsndx(pd), TRUE);

    } else if (mdef == &gy.youmonst) {
        /*
         * monster mind flayer is eating hero's brain
         */
        /* no such thing as mindless players */
        if (ABASE(A_INT) <= ATTRMIN(A_INT)) {
            static NEARDATA const char brainlessness[] = "brainlessness";

            if (Lifesaved) {
                Strcpy(svk.killer.name, brainlessness);
                svk.killer.format = KILLED_BY;
                done(DIED);
                /* amulet of life saving has now been used up */
                pline("残念ながら、脳はまだなかった.");
                /* sanity check against adding other forms of life-saving */
                u.uprops[LIFESAVED].extrinsic =
                    u.uprops[LIFESAVED].intrinsic = 0L;
            } else {
                Your("最後の記憶が消えていった.");
            }
            Strcpy(svk.killer.name, brainlessness);
            svk.killer.format = KILLED_BY;
            done(DIED);
            /* can only get here when in wizard or explore mode and user has
               explicitly chosen not to die; arbitrarily boost intelligence */
            ABASE(A_INT) = ATTRMIN(A_INT) + 2;
            You_feel("案山子になったような気分だ.");
        }
        give_nutrit = TRUE; /* in case a conflicted pet is doing this */
        exercise(A_WIS, FALSE);
        /* caller handles Int and memory loss */

    } else { /* mhitm */
        /*
         * monster mind flayer is eating another monster's brain
         */
        if (mindless(pd)) {
            if (visflag && canspotmon(mdef))
                pline("%sは気づかなかった.", l_monnam(mdef));
            return M_ATTK_MISS;
        } else if (is_rider(pd)) {
            mondied(magr);
            if (DEADMONSTER(magr))
                result = M_ATTK_AGR_DIED;
            /* Rider takes extra damage regardless of whether attacker dies */
            *dmg_p += xtra_dmg;
        } else {
            *dmg_p += xtra_dmg;
            give_nutrit = TRUE;
            if (*dmg_p >= mdef->mhp && visflag && canspotmon(mdef))
                pline("%sの最後の記憶が消えていった...",
                      l_monnam(mdef));
        }
    }

    if (give_nutrit && magr->mtame && !magr->isminion) {
        EDOG(magr)->hungrytime += rnd(60);
        magr->mconf = 0;
    }

    return result;
}

/* eating a corpse or egg of one's own species is usually naughty */
staticfn boolean
maybe_cannibal(int pm, boolean allowmsg)
{
    static NEARDATA long ate_brains = 0L;
    struct permonst *fptr = &mons[pm]; /* food type */

    /* when poly'd into a mind flayer, multiple tentacle hits in one
       turn cause multiple digestion checks to occur; avoid giving
       multiple luck penalties for the same attack */
    if (svm.moves == ate_brains)
        return FALSE;
    ate_brains = svm.moves; /* ate_anything, not just brains... */

    if (!CANNIBAL_ALLOWED()
        /* non-cannibalistic heroes shouldn't eat own species ever
           and also shouldn't eat current species when polymorphed
           (even if having the form of something which doesn't care
           about cannibalism--hero's innate traits aren't altered) */
        && (your_race(fptr)
            || (Upolyd && same_race(gy.youmonst.data, fptr))
            || (ismnum(u.ulycn) && were_beastie(pm) == u.ulycn))) {
        if (allowmsg) {
            if (Upolyd && your_race(fptr))
                You("胸の奥に嫌な予感がした.");
            You("共食いだ! きっと後悔した.");
        }
        HAggravate_monster |= FROMOUTSIDE;
        change_luck(-rn1(4, 2)); /* -5..-2 */
        return TRUE;
    }
    return FALSE;
}

staticfn void
cprefx(int pm)
{
    (void) maybe_cannibal(pm, TRUE);
    if (flesh_petrifies(&mons[pm])) {
        if (!Stone_resistance
            && !(poly_when_stoned(gy.youmonst.data)
                 && polymon(PM_STONE_GOLEM))) {
            /* if food was a tin, use it up early to keep it out of bones */
            if (svc.context.tin.tin)
                use_up_tin(svc.context.tin.tin);

            Sprintf(svk.killer.name, "tasting %s meat",
                    mons[pm].pmnames[NEUTRAL]);
            svk.killer.format = KILLED_BY;
                You("石になった.");
            done(STONING);
            if (svc.context.victual.piece)
                svc.context.victual.eating = 0;
            return; /* lifesaved */
        }
    }

    switch (pm) {
    case PM_LITTLE_DOG:
    case PM_DOG:
    case PM_LARGE_DOG:
    case PM_KITTEN:
    case PM_HOUSECAT:
    case PM_LARGE_CAT:
        /* cannibals are allowed to eat domestic animals without penalty */
        if (!CANNIBAL_ALLOWED()) {
            You_feel("%sを食べたのはまずかったと感じた.",
                     mons[pm].pmnames[NEUTRAL]);
            HAggravate_monster |= FROMOUTSIDE;
        }
        break;
    case PM_LIZARD:
        if (Stoned)
            fix_petrification();
        break;
    case PM_DEATH:
    case PM_PESTILENCE:
    case PM_FAMINE: {
        pline("それを食べると即座に致命的だった.");
        Sprintf(svk.killer.name, "unwisely ate the body of %s",
                mons[pm].pmnames[NEUTRAL]);
        svk.killer.format = NO_KILLER_PREFIX;
        done(DIED);
        /* life-saving needed to reach here */
        exercise(A_WIS, FALSE);
        /* revive an actual corpse; can't do that if it was a tin;
           5.0: this used to assume that such tins were impossible but
           they can be wished for in wizard mode; they can't make it
           to normal play though because bones creation empties them */
        if (svc.context.victual.piece /* Null for tins */
            && svc.context.victual.piece->otyp == CORPSE /* paranoia */
            && revive_corpse(svc.context.victual.piece))
            svc.context.victual = zero_victual; /* victual.piece=0, .o_id=0 */
        return;
    }
    case PM_GREEN_SLIME:
        if (!Slimed && !Unchanging && !slimeproof(gy.youmonst.data)) {
            You("ひどく気分が悪くなった.");
            make_slimed(10L, (char *) 0);
            delayed_killer(SLIMED, KILLED_BY_AN, "");
        }
        FALLTHROUGH;
    /* Fall through */
    default:
        if (acidic(&mons[pm]) && Stoned)
            fix_petrification();
        break;
    }
}

void
fix_petrification(void)
{
    char buf[BUFSZ];

    if (Hallucination)
        Sprintf(buf, "ああ、なんということだ。あなたは将来の%s芸術作品を台無しにしてしまった!",
                ACURR(A_CHA) > 15 ? "素晴らしい" : "");
    else
        Strcpy(buf, "体がしなやかになった気がした!");
    make_stoned(0L, buf, 0, (char *) 0);
}

/*
 * If you add an intrinsic that can be gotten by eating a monster, add it
 * to intrinsic_possible() and givit().  (It must already be in prop.h to
 * be an intrinsic property.)
 * It would be very easy to make the intrinsics not try to give you one
 * that you already had by checking to see if you have it in
 * intrinsic_possible() instead of givit(), but we're not that nice.
 */

/* intrinsic_possible() returns TRUE iff a monster can give an intrinsic. */
int
intrinsic_possible(int type, struct permonst *ptr)
{
    int res = 0;

#ifdef DEBUG
#define ifdebugresist(Msg)      \
    do {                        \
        if (res)                \
            debugpline0(Msg);   \
    } while (0)
#else
#define ifdebugresist(Msg) /*empty*/
#endif
    switch (type) {
    case FIRE_RES:
        res = (ptr->mconveys & MR_FIRE) != 0;
        ifdebugresist("can get fire resistance");
        break;
    case SLEEP_RES:
        res = (ptr->mconveys & MR_SLEEP) != 0;
        ifdebugresist("can get sleep resistance");
        break;
    case COLD_RES:
        res = (ptr->mconveys & MR_COLD) != 0;
        ifdebugresist("can get cold resistance");
        break;
    case DISINT_RES:
        res = (ptr->mconveys & MR_DISINT) != 0;
        ifdebugresist("can get disintegration resistance");
        break;
    case SHOCK_RES: /* shock (electricity) resistance */
        res = (ptr->mconveys & MR_ELEC) != 0;
        ifdebugresist("can get shock resistance");
        break;
    case POISON_RES:
        res = (ptr->mconveys & MR_POISON) != 0;
        ifdebugresist("can get poison resistance");
        break;
    case ACID_RES:
        res = (ptr->mconveys & MR_ACID) != 0;
        ifdebugresist("can get acid resistance temporarily");
        break;
    case STONE_RES:
        res = (ptr->mconveys & MR_STONE) != 0;
        ifdebugresist("can get stoning resistance temporarily");
        break;
    case TELEPORT:
        res = can_teleport(ptr);
        ifdebugresist("can get teleport");
        break;
    case TELEPORT_CONTROL:
        res = control_teleport(ptr);
        ifdebugresist("can get teleport control");
        break;
    case TELEPAT:
        res = telepathic(ptr);
        ifdebugresist("can get telepathy");
        break;
    default:
        /* res stays 0 */
        break;
    }
#undef ifdebugresist
    return res;
}

/* The "do we or do we not give the intrinsic" logic from givit(), extracted
 * into its own function. Depends on the monster's level and the type of
 * intrinsic it is trying to give you.
 */
boolean
should_givit(int type, struct permonst *ptr)
{
    int chance;

    /* some intrinsics are easier to get than others */
    switch (type) {
    case POISON_RES:
        if ((ptr == &mons[PM_KILLER_BEE] || ptr == &mons[PM_SCORPION])
            && !rn2(4))
            chance = 1;
        else
            chance = 15;
        break;
    case TELEPORT:
        chance = 10;
        break;
    case TELEPORT_CONTROL:
        chance = 12;
        break;
    case TELEPAT:
        chance = 1;
        break;
    default:
        chance = 15;
        break;
    }

    return (ptr->mlevel > rn2(chance));
}

staticfn boolean
temp_givit(int type, struct permonst *ptr)
{
    int chance = (type == STONE_RES) ? 6 : (type == ACID_RES) ? 3 : 0;

    return chance ? (ptr->mlevel > rn2(chance)) : FALSE;
}

/* givit() tries to give you an intrinsic based on the monster's level
 * and what type of intrinsic it is trying to give you.
 */
staticfn void
givit(int type, struct permonst *ptr)
{
    debugpline1("Attempting to give intrinsic %d", type);

    if (!should_givit(type, ptr) && !temp_givit(type, ptr))
        return;

    switch (type) {
    case FIRE_RES:
        debugpline0("Trying to give fire resistance");
        if (!(HFire_resistance & FROMOUTSIDE)) {
            You(Hallucination ? "寒気がするね、ベイビー." : "一瞬、寒気がした.");
            HFire_resistance |= FROMOUTSIDE;
        }
        break;
    case SLEEP_RES:
        debugpline0("Trying to give sleep resistance");
        if (!(HSleep_resistance & FROMOUTSIDE)) {
            You_feel("目が完全に冴えた.");
            HSleep_resistance |= FROMOUTSIDE;
        }
        break;
    case COLD_RES:
        debugpline0("Trying to give cold resistance");
        if (!(HCold_resistance & FROMOUTSIDE)) {
            You_feel("体が熱くなった.");
            HCold_resistance |= FROMOUTSIDE;
        }
        break;
    case DISINT_RES:
        debugpline0("Trying to give disintegration resistance");
        if (!(HDisint_resistance & FROMOUTSIDE)) {
            You_feel(Hallucination ? "体がバラバラにならない気がするぜ、ブラザー." : "体がとても頑丈になった気がした.");
            HDisint_resistance |= FROMOUTSIDE;
        }
        break;
    case SHOCK_RES: /* shock (electricity) resistance */
        debugpline0("Trying to give shock resistance");
        if (!(HShock_resistance & FROMOUTSIDE)) {
            if (Hallucination)
                You_feel("現実感がわいてきた.");
            else
                Your("体中に力がみなぎってきた!");
            HShock_resistance |= FROMOUTSIDE;
        }
        break;
    case POISON_RES:
        debugpline0("Trying to give poison resistance");
        if (!(HPoison_resistance & FROMOUTSIDE)) {
            You_feel(Poison_resistance ? "体がとても健康になった気がした." : "体が健康になった気がした.");
            HPoison_resistance |= FROMOUTSIDE;
        }
        break;
    case TELEPORT:
        debugpline0("Trying to give teleport");
        if (!(HTeleportation & FROMOUTSIDE)) {
            You_feel(Hallucination ? "自分が拡散していく気がする." : "そわそわしてきた.");
            HTeleportation |= FROMOUTSIDE;
        }
        break;
    case TELEPORT_CONTROL:
        debugpline0("Trying to give teleport control");
        if (!(HTeleport_control & FROMOUTSIDE)) {
            You_feel(Hallucination ? "パーソナルスペースの中心にいる気がする."
                                   : "自分を制御できている気がした.");
            HTeleport_control |= FROMOUTSIDE;
        }
        break;
    case TELEPAT:
        debugpline0("Trying to give telepathy");
        if (!(HTelepat & FROMOUTSIDE)) {
            You_feel(Hallucination ? "宇宙と一体になった気がした."
                                   : "精神が研ぎ澄まされたような気がした.");
            HTelepat |= FROMOUTSIDE;
            /* If blind, make sure monsters show up. */
            if (Blind)
                see_monsters();
        }
        break;
    case ACID_RES:
        debugpline0("Giving timed acid resistance");
        if (!Acid_resistance)
            You_feel("%s.", Hallucination ? "フラッシュバックから解放された気がした"
                            : "酸によるダメージをあまり気にしなくなった");
        incr_itimeout(&HAcid_resistance, d(3, 6));
        break;
    case STONE_RES:
        debugpline0("Giving timed stoning resistance");
        if (!Stone_resistance)
            You_feel("%s.", Hallucination ? "体が異常に柔軟になった気がした"
                            : "石化することをあまり気にしなくなった");
        incr_itimeout(&HStone_resistance, d(3, 6));
        break;
    default:
        debugpline0("Tried to give an impossible intrinsic");
        break;
    }
}

staticfn void
eye_of_newt_buzz(void)
{
    /* MRKR: "eye of newt" may give small magical energy boost */
    if (rn2(3) || 3 * u.uen <= 2 * u.uenmax) {
        int old_uen = u.uen;

        u.uen += rnd(3);
        if (u.uen > u.uenmax) {
            if (!rn2(3)) {
                u.uenmax++;
                if (u.uenmax > u.uenpeak)
                    u.uenpeak = u.uenmax;
            }
            u.uen = u.uenmax;
        }
        if (old_uen != u.uen) {
            You_feel("軽い高揚感を覚えた.");
            disp.botl = TRUE;
        }
    }
}

DISABLE_WARNING_FORMAT_NONLITERAL

/* called after completely consuming a corpse */
staticfn void
cpostfx(int pm)
{
    int tmp = 0;
    int catch_lycanthropy = NON_PM;
    boolean check_intrinsics = FALSE;

    /* in case `afternmv' didn't get called for previously mimicking
       gold, clean up now to avoid `eatmbuf' memory leak */
    if (ge.eatmbuf)
        (void) eatmdone();

    switch (pm) {
    case PM_WRAITH:
        pluslvl(FALSE);
        break;
    case PM_HUMAN_WERERAT:
        catch_lycanthropy = PM_WERERAT;
        break;
    case PM_HUMAN_WEREJACKAL:
        catch_lycanthropy = PM_WEREJACKAL;
        break;
    case PM_HUMAN_WEREWOLF:
        catch_lycanthropy = PM_WEREWOLF;
        break;
    case PM_NURSE:
        if (Upolyd)
            u.mh = u.mhmax;
        else
            u.uhp = u.uhpmax;
        make_blinded(0L, !u.ucreamed);
        disp.botl = TRUE;
        check_intrinsics = TRUE; /* might also convey poison resistance */
        break;
    case PM_STALKER:
        if (!Invis) {
            set_itimeout(&HInvis, (long) rn1(100, 50));
            if (!Blind && !BInvis)
                self_invis_message();
        } else {
            if (!(HInvis & INTRINSIC))
                You_feel("姿が隠れた気がした!");
            HInvis |= FROMOUTSIDE;
            HSee_invisible |= FROMOUTSIDE;
        }
        newsym(u.ux, u.uy);
        FALLTHROUGH;
        /*FALLTHRU*/
    case PM_YELLOW_LIGHT:
    case PM_GIANT_BAT:
        make_stunned((HStun & TIMEOUT) + 30L, FALSE);
        FALLTHROUGH;
        /*FALLTHRU*/
    case PM_BAT:
        make_stunned((HStun & TIMEOUT) + 30L, FALSE);
        break;
    case PM_GIANT_MIMIC:
        tmp += 10;
        FALLTHROUGH;
        /*FALLTHRU*/
    case PM_LARGE_MIMIC:
        tmp += 20;
        FALLTHROUGH;
        /*FALLTHRU*/
    case PM_SMALL_MIMIC:
        tmp += 20;
        if (gy.youmonst.data->mlet != S_MIMIC && !Unchanging) {
            char buf[BUFSZ];
            const char *tempshape = !Hallucination ? "金貨の山"
                                                   : "オレンジ";

            if (!u.uconduct.polyselfs++) /* you're changing form */
                livelog_printf(LL_CONDUCT,
                            "初めて姿を変えた（%sに擬態）",
                               tempshape);
            You("%sに化けたいという誘惑に勝てなかった.", tempshape);
            /* A pile of gold can't ride. */
            if (u.usteed)
                dismount_steed(DISMOUNT_FELL);
            nomul(-tmp);
            gm.multi_reason = "金貨の山のふりをしている";
            Sprintf(buf,
                    Hallucination
                       ? "皮をむかれるのが急に怖くなり、再び%sに化けた!"
                       : "再び%sに化けるのがお似合いだと思った.",
                    Upolyd ? jp_pmname(gy.youmonst.data, Ugender)
                              : gu.urace.noun);
            ge.eatmbuf = dupstr(buf);
            gn.nomovemsg = ge.eatmbuf;
            ga.afternmv = eatmdone;
            /* ??? what if this was set before? */
            gy.youmonst.m_ap_type = M_AP_OBJECT;
            gy.youmonst.mappearance = Hallucination ? ORANGE : GOLD_PIECE;
            newsym(u.ux, u.uy);
            curs_on_u();
            /* make gold symbol show up now */
            display_nhwindow(WIN_MAP, TRUE);
        }
        break;
    case PM_QUANTUM_MECHANIC:
        Your("速度が突然不安定になった気がした!");
        if (HFast & INTRINSIC) {
            HFast &= ~INTRINSIC;
            You("遅くなったようだ.");
        } else {
            HFast |= FROMOUTSIDE;
            You("速くなったようだ.");
        }
        break;
    case PM_LIZARD:
        if ((HStun & TIMEOUT) > 2)
            make_stunned(2L, FALSE);
        if ((HConfusion & TIMEOUT) > 2)
            make_confused(2L, FALSE);
        check_intrinsics = TRUE; /* might convey temporary stoning resist */
        break;
    case PM_CHAMELEON:
    case PM_DOPPELGANGER:
    case PM_SANDESTIN: /* moot--they don't leave corpses */
    case PM_GENETIC_ENGINEER:
        if (Unchanging) {
            You_feel("一瞬、自分が変わったような気がした."); /* same as poly trap */
        } else {
            /* polyself() is potentially fatal; if food is a tin, use it up
               early to keep it out of bones */
            if (svc.context.tin.tin) {
                use_up_tin(svc.context.tin.tin);
                /* most tin effects end up being skipped */
                lesshungry(200 + (metallivorous(gy.youmonst.data) ? 5 : 0));
            }

            You("%s.", (pm == PM_GENETIC_ENGINEER)
                          ? "奇妙な変態を遂げた"
                          : "自分自身が変わっていくのを感じた");
            polyself(POLY_NOFLAGS);
        }
        break;
    case PM_DISPLACER_BEAST:
        if (!Displaced) /* give a message (before setting the timeout) */
            toggle_displacement((struct obj *) 0, 0L, TRUE);
        incr_itimeout(&HDisplaced, d(6, 6));
        break;
    case PM_DISENCHANTER:
        /* picks an intrinsic at random and removes it; there's
           no feedback if hero already lacks the chosen ability */
        debugpline0("using attrcurse to strip an intrinsic");
        (void) attrcurse();
        break;
    case PM_DEATH:
    case PM_PESTILENCE:
    case PM_FAMINE:
        /* life-saved; don't attempt to confer any intrinsics */
        break;
    case PM_MIND_FLAYER:
    case PM_MASTER_MIND_FLAYER:
        if (ABASE(A_INT) < ATTRMAX(A_INT)) {
            if (!rn2(2)) {
                pline("うまい! とても頭に良い食べ物だった!");
                (void) adjattrib(A_INT, 1, FALSE);
                break; /* don't give them telepathy, too */
            }
        } else {
            pline("なぜかあまり味がしなかった.");
        }
        FALLTHROUGH;
    /*FALLTHRU*/
    default:
        check_intrinsics = TRUE;
        break;
    }

    /* possibly convey an intrinsic */
    if (check_intrinsics) {
        struct permonst *ptr = &mons[pm];

        if (dmgtype(ptr, AD_STUN) || dmgtype(ptr, AD_HALU)
            || pm == PM_VIOLET_FUNGUS) {
            pline("うーん! 最高だった!");
            (void) make_hallucinated((HHallucination & TIMEOUT) + 200L, FALSE,
                                     0L);
        }

        /* Eating magical monsters can give you some magical energy. */
        if (attacktype(ptr, AT_MAGC) || pm == PM_NEWT)
            eye_of_newt_buzz();

        tmp = corpse_intrinsic(ptr);

        /* if something was chosen, give it now (givit() might fail) */
        if (tmp == -1)
            gainstr((struct obj *) 0, 0, TRUE);
        else if (tmp > 0)
            givit(tmp, ptr);
    } /* check_intrinsics */

    if (ismnum(catch_lycanthropy)) {
        set_ulycn(catch_lycanthropy);
        retouch_equipment(2);
    }
    return;
}

RESTORE_WARNING_FORMAT_NONLITERAL

/* Choose (one of) the intrinsics granted by a corpse, and return it.
 * If this corpse gives no intrinsics, return 0.
 * For the special not-real-prop cases of strength gain from giants
 * return fake prop value of -1.
 * Non-deterministic; should only be called once per corpse.
 */
int
corpse_intrinsic(struct permonst *ptr)
{
    /* Check the monster for all of the intrinsics.  If this
     * monster can give more than one, pick one to try to give
     * from among all it can give.
     */
    boolean conveys_STR = is_giant(ptr);
    int i;
    int count = 0; /* number of possible intrinsics */
    int prop = 0;   /* which one we will try to give */

    if (conveys_STR) {
        count = 1;
        prop = -1; /* use -1 as fake prop index for STR */
        debugpline1("\"Intrinsic\" strength, %d", prop);
    }
    for (i = 1; i <= LAST_PROP; i++) {
        if (!intrinsic_possible(i, ptr))
            continue;
        ++count;
        /* a 1 in count chance of replacing the old choice
           with this one, and a count-1 in count chance
           of keeping the old choice (note that 1 in 1 and
           0 in 1 are what we want for the first candidate) */
        if (!rn2(count)) {
            debugpline2("Intrinsic %d replacing %d", i, prop);
            prop = i;
        }
    }
    /* if strength is the only candidate, give it 50% chance */
    if (conveys_STR && count == 1 && !rn2(2))
        prop = 0;

    return prop;
}

void
violated_vegetarian(void)
{
    u.uconduct.unvegetarian++;
    if (Role_if(PM_MONK)) {
        You_feel("罪悪感を感じた.");
        adjalign(-1);
    }
    return;
}

/* common code to check and possibly charge for 1 svc.context.tin.tin,
 * will split() svc.context.tin.tin if necessary */
staticfn struct obj *
costly_tin(int alter_type) /* COST_xxx */
{
    struct obj *tin = svc.context.tin.tin;

    if (carried(tin) ? tin->unpaid
                     : (costly_spot(tin->ox, tin->oy) && !tin->no_charge)) {
        if (tin->quan > 1L) {
            tin = svc.context.tin.tin = splitobj(tin, 1L);
            svc.context.tin.o_id = tin->o_id;
        }
        costly_alteration(tin, alter_type);
    }
    return tin;
}

int
tin_variety_txt(char *s, int *tinvariety)
{
    int k, l;

    if (s && tinvariety) {
        *tinvariety = -1;
        for (k = 0; k < TTSZ - 1; ++k) {
            l = (int) strlen(tintxts[k].txt);
            if (!strncmpi(s, tintxts[k].txt, l) && ((int) strlen(s) > l)
                && s[l] == ' ') {
                *tinvariety = k;
                return (l + 1);
            }
        }
        for (k = 0; k < TTSZ - 1; ++k) {
            int ofs;

            l = (int) strlen(tintxts_jp[k]);
            if (!l || strncmpi(s, tintxts_jp[k], l))
                continue;

            ofs = l;
            while (s[ofs] == ' ')
                ++ofs;

            *tinvariety = k;
            return ofs;
        }
        for (k = 0; tintxts_jp_aliases[k].txt; ++k) {
            int ofs;

            l = (int) strlen(tintxts_jp_aliases[k].txt);
            if (!l || strncmpi(s, tintxts_jp_aliases[k].txt, l))
                continue;

            ofs = l;
            while (s[ofs] == ' ')
                ++ofs;
            if (!strncmpi(&s[ofs], "の", (int) strlen("の")))
                ofs += (int) strlen("の");
            while (s[ofs] == ' ')
                ++ofs;

            *tinvariety = tintxts_jp_aliases[k].variety;
            return ofs;
        }
    }
    return 0;
}

/*
 * This assumes that buf already contains the word "tin",
 * as is the case with caller xname().
 */
void
tin_details(struct obj *obj, int mnum, char *buf)
{
    if (!obj || !buf)
        return;

    jp_tin_display_name(tin_variety(obj, TRUE), mnum, buf, BUFSZ);
}

void
set_tin_variety(struct obj *obj, int forcetype)
{
    int r, mnum = obj->corpsenm;

    if (forcetype == SPINACH_TIN
        || (forcetype == HEALTHY_TIN
            && (mnum == NON_PM /* empty or already spinach */
                || !vegetarian(&mons[mnum])))) { /* replace meat */
        obj->corpsenm = NON_PM; /* not based on any monster */
        obj->spe = 1;           /* spinach */
        return;
    } else if (forcetype == HEALTHY_TIN) {
        r = tin_variety(obj, FALSE);
        if (r < 0 || r >= TTSZ)
            r = ROTTEN_TIN; /* shouldn't happen */
        while ((r == ROTTEN_TIN && !obj->cursed) || !tintxts[r].fodder)
            r = rn2(TTSZ - 1);
    } else if (forcetype >= 0 && forcetype < TTSZ - 1) {
        r = forcetype;
    } else {               /* RANDOM_TIN */
        r = rn2(TTSZ - 1); /* take your pick */
        if (r == ROTTEN_TIN && (ismnum(mnum) && nonrotting_corpse(mnum)))
            r = HOMEMADE_TIN; /* lizards don't rot */
    }
    obj->spe = -(r + 1); /* offset by 1 to allow index 0 */
}

staticfn int
tin_variety(
    struct obj *obj,
    boolean displ) /* we're just displaying so leave things alone */
{
    int r, mnum = obj->corpsenm;

    if (obj->spe == 1) {
        r = SPINACH_TIN;
    } else if (obj->cursed) {
        r = ROTTEN_TIN; /* always rotten if cursed */
    } else if (obj->spe < 0) {
        r = -(obj->spe);
        --r; /* get rid of the offset */
    } else {
        r = rn2(TTSZ - 1);
    }

    if (!displ && r == HOMEMADE_TIN && !obj->blessed && !rn2(7))
        r = ROTTEN_TIN; /* some homemade tins go bad */

    if (r == ROTTEN_TIN && (ismnum(mnum) && nonrotting_corpse(mnum)))
        r = HOMEMADE_TIN; /* lizards don't rot */
    return r;
}

/* finish consume_tin(); also potentially used by cprefx() and cpostfx() */
staticfn void
use_up_tin(struct obj *tin)
{
    if (carried(tin))
        useup(tin);
    else
        useupf(tin, 1L);
    /* reset tin context */
    svc.context.tin.tin = (struct obj *) NULL;
    svc.context.tin.o_id = 0;
}

staticfn void
consume_tin(const char *mesg)
{
    const char *what;
    int which, mnum, r, nutamt;
    /* if you've eaten tin itself, chance to not eat contents gets bypassed */
    boolean always_eat = metallivorous(gy.youmonst.data);
    struct obj *tin = svc.context.tin.tin;

    r = tin_variety(tin, FALSE);
    if (tin->otrapped || (tin->cursed && r != HOMEMADE_TIN && !rn2(8))) {
        b_trapped("tin", NO_PART);
        tin = costly_tin(COST_DSTROY);
        use_up_tin(tin);
        return;
    }

    pline1(mesg); /* "You succeed in opening the tin." */

    if (r != SPINACH_TIN) {
        mnum = tin->corpsenm;
        if (mnum == NON_PM) {
            if (Hallucination)
                pline("中身は%sだった.",
                      rn2(2) ? "風のエレメンタルのスフレ"
                             : "脱水された水");
            else
                pline("中身は空だった.");
            observe_object(tin);
            tin->known = 1;
            tin = costly_tin(COST_OPEN);
            use_up_tin(tin);
            if (always_eat)
                lesshungry(5); /* metallivorous hero ate the tin itself */
            return;
        }

        which = 0; /* 0=>plural, 1=>as-is, 2=>"the" prefix */
        if ((mnum == PM_COCKATRICE || mnum == PM_CHICKATRICE)
            && (Stone_resistance || Hallucination)) {
            what = "chicken";
            which = 1; /* suppress pluralization */
        } else if (Hallucination) {
            what = rndmonnam(NULL);
        } else {
            what = mons[mnum].pmnames[NEUTRAL];
            if (the_unique_pm(&mons[mnum]))
                which = 2;
            else if (type_is_pname(&mons[mnum]))
                which = 1;
        }
        if (which == 0)
            what = makeplural(what);
        else if (which == 2)
            what = the(what);

        if (!always_eat) {
            pline("%sのような匂いがした.", what);
            if (y_n("食べますか?") == 'n') {
                if (flags.verbose)
                    You("開けた缶を捨てた.");
                if (!Hallucination) {
                    observe_object(tin);
                    tin->known = 1;
                }
                tin = costly_tin(COST_OPEN);
                use_up_tin(tin);
                return;
            }
        }

        /* in case stop_occupation() was called on previous meal */
        svc.context.victual = zero_victual; /* victual.piece = 0, .o_id = 0 */

        {
            char tinbuf[BUFSZ];

            jp_tin_content_name(r, mnum, tinbuf, sizeof tinbuf);
            You("%sを完食した.", tinbuf);
        }

        eating_conducts(&mons[mnum]);

        observe_object(tin);
        tin->known = 1;
        /* charge for one at pre-eating cost */
        tin = svc.context.tin.tin = costly_tin(COST_OPEN);

        /* cprefx() or cpostfx() might use up tin to keep it out of bones */
        cprefx(mnum);
        if (svc.context.tin.tin)
            cpostfx(mnum);
        if (!svc.context.tin.tin)
            return;

        if (tintxts[r].nut < 0) { /* rotten */
            make_vomiting((long) rn1(15, 10), FALSE);
        } else {
            nutamt = tintxts[r].nut;
            /* nutrition from a homemade tin (made from a single corpse)
               shouldn't be more than nutrition from the corresponding
               corpse; other tinning modes might use more than one corpse
               or add extra ingredients so aren't similarly restricted */
            if (r == HOMEMADE_TIN && nutamt > mons[mnum].cnutrit)
                nutamt = mons[mnum].cnutrit;
            if (always_eat)
                nutamt += 5; /* metallivorous hero ate the tin itself */
            /* use up tin now; lesshungry() could be fatal and produce bones */
            use_up_tin(tin), tin = NULL;
            lesshungry(nutamt);
        }

        if (tintxts[r].greasy) {
            /* normal hero is !Glib, because you can't open tins when Glib,
               but one poly'd into metallivorous form might already be Glib;
               it's debatable whether a rock mole should have its paws made
               slippery when eating a greasy tin, but we'll go with that... */
            int alreadyglib = (int) (Glib & TIMEOUT);
            char tinbuf[BUFSZ];

            jp_tin_content_name(r, mnum, tinbuf, sizeof tinbuf);
            make_glib(alreadyglib + rn1(11, 5)); /* 5..15 */
            pline("%sを食べたので、%sが%s滑りやすくなった.",
                tinbuf, fingers_or_gloves(TRUE),
                  alreadyglib ? "さらに" : "非常に");
        }

    } else { /* spinach... */
        if (tin->cursed) {
            pline("中には腐りかけの%s%s物質が入っていた.",
                  Blind ? "" : " ", Blind ? "" : hcolor(NH_GREEN));
        } else {
            pline("ほうれん草が入っていた.");
            observe_object(tin);
            tin->known = 1;
        }

        if (!always_eat && y_n("食べますか?") == 'n') {
            if (flags.verbose)
                You("開けた缶を捨てた.");
            tin = costly_tin(COST_OPEN);
            use_up_tin(tin);
            return;
        }

        /*
         * Same order as with non-spinach above:
         * conduct update, side-effects, shop handling, and nutrition.
         */
        /* don't need vegetarian checks for spinach */
        if (!u.uconduct.food++)
            livelog_printf(LL_CONDUCT, "初めて食事をした（ホウレンソウ）");
        if (!tin->cursed)
            pline("これで%sになった気分だ!",
                  /* "Swee'pea" is a character from the Popeye cartoons */
                  Hallucination ? "スウィーピー"
                  /* "feel like Popeye" unless sustain ability suppresses
                     any attribute change; this slightly oversimplifies
                     things:  we want "Popeye" if no strength increase
                     occurs due to already being at maximum, but we won't
                     get it if at-maximum and fixed-abil both apply */
                  : !Fixed_abil ? "ポパイ"
                  /* no gain, feel like another character from Popeye */
                  : (flags.female ? "オリーブ" : "ブルート"));
        gainstr(tin, 0, FALSE);

        tin = svc.context.tin.tin = costly_tin(COST_OPEN);
        nutamt = (tin->blessed ? 600                   /* blessed */
                  : !tin->cursed ? (400 + rnd(200))    /* uncursed */
                    : (200 + rnd(400)));               /* cursed */
        if (always_eat)
            nutamt += 5; /* metallivorous hero also eats the tin itself */
        /* use up tin first; lesshungry() could be fatal and produce bones */
        use_up_tin(tin), tin = NULL;
        lesshungry(nutamt);
    }
    if (tin)
        use_up_tin(tin);
    return;
    }

    /* called during each move whilst opening a tin */
    staticfn int
    opentin(void)
    {
    /* perhaps it was stolen (although that should cause interruption) */
    if (!carried(svc.context.tin.tin)
        && (!obj_here(svc.context.tin.tin, u.ux, u.uy)
            || !can_reach_floor(TRUE)))
        return 0; /* %% probably we should use tinoid */
    if (svc.context.tin.usedtime++ >= 50) {
        You("缶を開けるのをあきらめた.");
        return 0;
    }
    if (svc.context.tin.usedtime < svc.context.tin.reqtime)
        return 1; /* still busy */

    consume_tin("缶を開けることに成功した.");
    return 0;
    }

    /* called when starting to open a tin */
    staticfn void
    start_tin(struct obj *otmp)
    {
    const char *mesg = 0;
    int tmp;

    if (metallivorous(gy.youmonst.data)) {
        mesg = "金属の缶にそのままかじりついた...";
        tmp = 0;
    } else if (cantwield(gy.youmonst.data)) { /* nohands || verysmall */
        You("缶をうまく扱えず、開けることができない.");
        return;
    } else if (otmp->blessed) {
        /* 50/50 chance for immediate access vs 1 turn delay (unless
           wielding blessed tin opener which always yields immediate
           access); 1 turn delay case is non-deterministic:  getting
           interrupted and retrying might yield another 1 turn delay
           or might open immediately on 2nd (or 3rd, 4th, ...) try */
        tmp = (uwep && uwep->blessed && uwep->otyp == TIN_OPENER) ? 0
                                                                  : rn2(2);
        if (!tmp)
            mesg = "魔法のように缶が開いた!";
        else
            pline_The("この缶は簡単に開けられそうだ.");
    } else if (uwep) {
        switch (uwep->otyp) {
        case TIN_OPENER:
            mesg = "簡単に缶を開けた."; /* iff tmp==0 */
            tmp = rn2(uwep->cursed ? 3 : !uwep->blessed ? 2 : 1);
            break;
        case DAGGER:
        case SILVER_DAGGER:
        case ELVEN_DAGGER:
        case ORCISH_DAGGER:
        case ATHAME:
        case KNIFE:
        case STILETTO:
        case CRYSKNIFE:
            tmp = 3;
            break;
        case PICK_AXE:
        case AXE:
            tmp = 6;
            break;
        default:
            goto no_opener;
        }
        pline("%sを使って缶を開けようとした.", yobjnam(uwep, (char *) 0));
    } else {
    no_opener:
        pline("この缶を開けるのはそれほど簡単ではなかった.");
        if (Glib) {
            pline_The("缶が%sから滑り落ちた.", fingers_or_gloves(FALSE));
            if (otmp->quan > 1L) {
                otmp = splitobj(otmp, 1L);
            }
            if (carried(otmp))
                dropx(otmp);
            else
                stackobj(otmp);
            return;
        }
        tmp = rn1(1 + 500 / ((int) (ACURR(A_DEX) + ACURRSTR)), 10);
    }

    svc.context.tin.tin = otmp;
    svc.context.tin.o_id = otmp->o_id;
    if (!tmp) {
        consume_tin(mesg); /* begin immediately */
    } else {
        svc.context.tin.reqtime = tmp;
        svc.context.tin.usedtime = 0;
        set_occupation(opentin, "opening the tin", 0);
    }
    return;
    }

    /* called when waking up after fainting */
    int
    Hear_again(void)
    {
    /* Chance of deafness going away while fainted/sleeping/etc. */
    if (!rn2(2)) {
        make_deaf(0L, FALSE);
        disp.botl = TRUE;
    }
    return 0;
    }

    /* called on the "first bite" of rotten food */
    staticfn int
    rottenfood(struct obj *obj)
    {
    pline("おえっ!  %s%sだ!",
            is_rottable(obj) ? "腐った" : "ひどい味の",
            jp_foodword_for_display(obj));
    if (!rn2(4)) {
        if (Hallucination)
            You_feel("ちょっとトリップした気がした.");
        else
            You_feel("ちょっと%s気がした.", jp_body_part(LIGHT_HEADED));
        make_confused(HConfusion + d(2, 4), FALSE);
    } else if (!rn2(4) && !Blind) {
            pline("突然、すべてが暗くなった.");
        /* hero is not Blind, but Blinded timer might be nonzero if
           blindness is being overridden by the Eyes of the Overworld */
        make_blinded(BlindedTimeout + (long) d(2, 10), FALSE);
        if (!Blind)
            Your1(vision_clears);
    } else if (!rn2(3)) {
        const char *what, *where;
        int duration = rnd(10);

        if (!Blind)
            what = "あたりが", where = "暗くなった";
        else if (Levitation || Is_airlevel(&u.uz) || Is_waterlevel(&u.uz))
            what = "自分を", where = "制御できなくなった";
        else
            what = "地面に",
            where = (u.usteed) ? "叩きつけられた (鞍から)" : "叩きつけられた";
        pline_The("世界が回り、%s%s.", what, where);
        incr_itimeout(&HDeaf, duration);
        disp.botl = TRUE;
        nomul(-duration);
        gm.multi_reason = "腐った食べ物で意識を失っている";
        gn.nomovemsg = "意識を取り戻した.";
        ga.afternmv = Hear_again;
        return 1;
    }
    return 0;
    }

    /* called when a corpse is selected as food */
    staticfn int
    eatcorpse(struct obj *otmp)
    {
    int retcode = 0, tp = 0, mnum = otmp->corpsenm;
    long rotted = 0L;
    int ll_conduct = 0;
    boolean stoneable,
            slimeable = (mnum == PM_GREEN_SLIME && !Slimed && !Unchanging
                         && !slimeproof(gy.youmonst.data)),
            glob = otmp->globby ? TRUE : FALSE;

    assert(ismnum(mnum));
    stoneable = (flesh_petrifies(&mons[mnum]) && !Stone_resistance
                 && !poly_when_stoned(gy.youmonst.data));

    /* KMH, conduct */
    if (!vegan(&mons[mnum]))
        if (!u.uconduct.unvegan++) {
            livelog_printf(LL_CONDUCT,
                  "初めて動物性食品を口にした（%sを食べることで）",
                           food_xname(otmp, FALSE));
            ll_conduct++;
        }
    if (!vegetarian(&mons[mnum])) {
        if (!u.uconduct.unvegetarian && !ll_conduct)
            livelog_printf(LL_CONDUCT,
                           "初めて肉を口にした（%sを食べることで）",
                           food_xname(otmp, FALSE));
        violated_vegetarian();
    }
    if (!nonrotting_corpse(mnum)) {
        long age = peek_at_iced_corpse_age(otmp);

        rotted = (svm.moves - age) / (10L + rn2(20));
        if (otmp->cursed)
            rotted += 2L;
        else if (otmp->blessed)
            rotted -= 2L;
    }

    /* 5.0: globs don't become tainted, they shrink away */
    if (!glob && !stoneable && !slimeable && rotted > 5L) {
        boolean cannibal = maybe_cannibal(mnum, FALSE);

        /* tp++; -- early return makes this unnecessary */
        pline("うわっ、この%sは汚染されていた%s!",
              (mons[mnum].mlet == S_FUNGUS) ? "キノコの肉"
              : vegetarian(&mons[mnum]) ? "プロトプラズム"
                : "肉",
              cannibal ? "、この共食い野郎" : "");
        if (Sick_resistance) {
            pline("しかし、全く気分が悪くならなかった...");
        } else {
            long sick_time;

            sick_time = (long) rn1(10, 10);
            /* make sure new ill doesn't result in improvement */
            if (Sick && (sick_time > Sick))
                sick_time = (Sick > 1L) ? Sick - 1L : 1L;
            make_sick(sick_time, corpse_xname(otmp, "rotted", CXN_NORMAL),
                      TRUE, SICK_VOMITABLE);

            pline("(死んでから時間が経ちすぎていて、安全に食べられないようだ.)");
        }
        if (carried(otmp))
            useup(otmp);
        else
            useupf(otmp, 1L);
        return 2;
    } else if (acidic(&mons[mnum]) && !Acid_resistance) {
        tp++;
        You("ひどい胃酸過多に襲われた.");   /* not jp_body_part() */
        losehp(rnd(15), !glob ? "acidic corpse" : "acidic glob",
               KILLED_BY_AN); /* acid damage */
    } else if (poisonous(&mons[mnum]) && rn2(5)) {
        tp++;
        pline("うげっ - 毒があった!");
        if (!Poison_resistance) {
            poison_strdmg(rnd(4), rnd(15),
                          !glob ? "poisonous corpse" : "poisonous glob",
                          KILLED_BY_AN);
        } else
            You("毒の影響を受けていないようだ.");

    /* now any corpse left too long will make you mildly ill */
    } else if ((rotted > 5L || (rotted > 3L && rn2(5))) && !Sick_resistance) {
        tp++;
        You_feel("%s気分が悪くなった.", (Sick) ? "ひどく" : "");
        losehp(rnd(8), !glob ? "cadaver" : "rotted glob", KILLED_BY_AN);
    }

    /* delay is weight dependent */
    svc.context.victual.reqtime
        = 3 + ((!glob ? mons[mnum].cwt : otmp->owt) >> 6);

    if (!tp && !nonrotting_corpse(mnum) && (otmp->orotten || !rn2(7))) {
        if (rottenfood(otmp)) {
            otmp->orotten = TRUE;
            otmp = touchfood(otmp);
            if (!otmp)
                return 1;
            retcode = 1;
        }

        if (!mons[otmp->corpsenm].cnutrit) {
            /* no nutrition: rots away, no message if you passed out */
            if (!retcode)
                pline_The("死体は完全に腐り果てた.");
            if (carried(otmp))
                useup(otmp);
            else
                useupf(otmp, 1L);
            retcode = 2;
        }

        if (!retcode)
            consume_oeaten(otmp, 2); /* oeaten >>= 2 */
    } else if ((mnum == PM_COCKATRICE || mnum == PM_CHICKATRICE)
               && (Stone_resistance || Hallucination)) {
        pline("チキンのような味だった!");
    } else if (mnum == PM_FLOATING_EYE && u.umonnum == PM_RAVEN) {
        You("喜んで目玉をつついた.");
    } else if (tp) {
        ; /* we've already delivered a message; don't add "it tastes okay" */
    } else {
        /* yummy is always False for omnivores, palatable always True */
        boolean yummy = (vegan(&mons[mnum])
                            ? (!carnivorous(gy.youmonst.data)
                               && herbivorous(gy.youmonst.data))
                            : (carnivorous(gy.youmonst.data)
                               && !herbivorous(gy.youmonst.data))),
                palatable = ((vegetarian(&mons[mnum])
                              ? herbivorous(gy.youmonst.data)
                              : carnivorous(gy.youmonst.data))
                             && rn2(10)
                             && (rotted < 1 || !rn2((int) rotted + 1)));
          const char *pmxnam = food_xname(otmp, FALSE);
          static const char *const palatable_msgs[] = {
                "まあまあだ", "筋っぽい", "獣くさい", "脂っこい", "硬い"
          };
          int idx = vegetarian(&mons[mnum]) ? 0 : rn2(SIZE(palatable_msgs));
          const char *taste_desc = Hallucination
                                                 ? (yummy ? "最高だ"
                                                     : palatable ? "悪くない"
                                                                    : "最悪だ")
                                                 : (yummy ? "とてもおいしい"
                                                     : palatable ? palatable_msgs[idx]
                                                                    : "ひどい味だ");

          pline("%sは%s%c", pmxnam, taste_desc,
                  (yummy || !palatable) ? '!' : '.');
    }

    return retcode;
    }
/* called as you start to eat */
staticfn void
start_eating(struct obj *otmp, boolean already_partly_eaten)
{
    const char *old_nomovemsg, *save_nomovemsg;
    static char msgbuf[BUFSZ];

    debugpline2("start_eating: %s (victual = %s)",
                /* note: fmt_ptr() returns a static buffer but supports
                   several such so we don't need to copy the first result
                   before calling it a second time */
                fmt_ptr((genericptr_t) otmp),
                fmt_ptr((genericptr_t) svc.context.victual.piece));
    debugpline1("reqtime = %d", svc.context.victual.reqtime);
    debugpline1("(original reqtime = %d)", objects[otmp->otyp].oc_delay);
    debugpline1("nmod = %d", svc.context.victual.nmod);
    debugpline1("oeaten = %d", otmp->oeaten);
    svc.context.victual.fullwarn = svc.context.victual.doreset = 0;
    svc.context.victual.eating = 1;

    if (otmp->otyp == CORPSE || otmp->globby) {
        cprefx(svc.context.victual.piece->corpsenm);
        if (!svc.context.victual.piece || !svc.context.victual.eating) {
            /* rider revived, or hero died and was lifesaved */
            return;
        }
    }

    old_nomovemsg = gn.nomovemsg;
    if (bite()) {
        /* survived choking, finish off food that's nearly done;
           need this to handle cockatrice eggs, fortune cookies, etc */
        if (++svc.context.victual.usedtime >= svc.context.victual.reqtime) {
            /* don't want done_eating() to issue gn.nomovemsg if it
               is due to vomit() called by bite() */
            save_nomovemsg = gn.nomovemsg;
            if (!old_nomovemsg)
                gn.nomovemsg = 0;
            done_eating(FALSE);
            if (!old_nomovemsg)
                gn.nomovemsg = save_nomovemsg;
        }
        return;
    }

    if (++svc.context.victual.usedtime >= svc.context.victual.reqtime) {
        /* print "finish eating" message if they just resumed -dlc */
        done_eating((svc.context.victual.reqtime > 1
                     || already_partly_eaten) ? TRUE : FALSE);
        return;
    }

    Sprintf(msgbuf, "%sを食べるの", food_xname(otmp, TRUE));
    set_occupation(eatfood, msgbuf, 0);
}

/* used by shrink_glob() timer routine */
boolean
eating_glob(struct obj *glob)
{
    return (go.occupation == eatfood && glob == svc.context.victual.piece);
}

/* scare nearby monster when hero eats garlic */
staticfn void
garlic_breath(struct monst *mtmp)
{
    if (olfaction(mtmp->data) && distu(mtmp->mx, mtmp->my) < 7)
        monflee(mtmp, 0, FALSE, FALSE);
}

/*
 * Called on "first bite" of (non-corpse) food, after touchfood() has
 * marked it 'partly eaten'.  Used for non-rotten non-tin non-corpse food.
 * Messages should use present tense since multi-turn food won't be
 * finishing at the time they're issued.
 * Returns FALSE if eating should not succeed for whatever reason.
 */
staticfn boolean
fprefx(struct obj *otmp)
{
    switch (otmp->otyp) {
    case EGG:
        if (otmp->corpsenm == PM_PYROLISK) {
            if (carried(otmp))
                useup(otmp);
            else
                useupf(otmp, 1L);
            explode(u.ux, u.uy, -11, d(3, 6), 0, EXPL_FIERY);
            return FALSE;
        } else if (stale_egg(otmp)) {
            pline("うげっ. 腐った卵だった.");
            /* increasing existing nausea means that it will take longer
               before eventual vomit, but also means that constitution
               will be abused more times before illness completes */
            make_vomiting((Vomiting & TIMEOUT) + (long) d(10, 4), TRUE);
        } else
            goto give_feedback;
        break;
    case FOOD_RATION: /* nutrition 800 */
        /* 200+800 remains below 1000+1, the satiation threshold */
        if (u.uhunger <= 200)
            pline("%s!", Hallucination ? "おお、これは... 素晴らしいぜ、ブラザー"
                                       : "この食べ物はまさに今の気分にぴったりだ");

        /* 700-1+800 remains below 1500, the choking threshold which
           triggers "you're having a hard time getting it down" feedback */
        else if (u.uhunger < 700)
            pline("これであなたの%sは満たされた!", jp_body_part(STOMACH));
        /* [satiation message may be inaccurate if eating gets interrupted] */
        break;
    case TRIPE_RATION:
        if (carnivorous(gy.youmonst.data) && !humanoid(gy.youmonst.data)) {
            pline("このモツ肉は意外とうまかった!");
        } else if (maybe_polyd(is_orc(gy.youmonst.data), Race_if(PM_ORC))) {
            pline(Hallucination ? "最高だぜ!  お腹も膨れるしな!"
                                : "ふむ、モツ肉か... 悪くないな!");
        } else {
            pline("げっ - ドッグフードだった!");
            more_experienced(1, 0);
            newexplevel();
            /* not cannibalism, but we use similar criteria
               for deciding whether to be sickened by this meal */
            if (rn2(2) && !CANNIBAL_ALLOWED())
                make_vomiting((long) rn1(svc.context.victual.reqtime, 14),
                              FALSE);
        }
        break;
    case LEMBAS_WAFER:
        if (maybe_polyd(is_orc(gy.youmonst.data), Race_if(PM_ORC))) {
            pline("%s", "!#?&* エルフの餌だ!");
            break;
        } else if (maybe_polyd(is_elf(gy.youmonst.data), Race_if(PM_ELF))) {
            pline("少量で十分だった.");
            break;
        }
        goto give_feedback;
    case MEATBALL:
    case MEAT_STICK:
    case ENORMOUS_MEATBALL:
    case MEAT_RING:
        goto give_feedback;
    case CLOVE_OF_GARLIC:
        if (is_undead(gy.youmonst.data)) {
            make_vomiting((long) rn1(svc.context.victual.reqtime, 5), FALSE);
            break;
        }
        iter_mons(garlic_breath);
        FALLTHROUGH;
        /*FALLTHRU*/
    default:
        if (otmp->otyp == SLIME_MOLD && !otmp->cursed
            && otmp->spe == svc.context.current_fruit) {
            pline("おや、これは%s %sだ!",
                  Hallucination ? "最高の" : "うまい",
                  singular(otmp, xname));
        } else if (otmp->otyp == APPLE && otmp->cursed && !Sleep_resistance) {
            ; /* skip core joke; feedback deferred til fpostfx() */

#if defined(MAC68K) || defined(MACOS)
        /* KMH -- Why should Unix have all the fun?
           We check MACOS before UNIX to get the Apple-specific apple
           message; the '#if UNIX' code will still kick in for pear. */
        } else if (otmp->otyp == APPLE) {
            pline("うまい! マッキントッシュに違いなかった!");
#endif

#ifdef UNIX
        } else if (otmp->otyp == APPLE || otmp->otyp == PEAR) {
            if (!Hallucination) {
                pline("コアダンプ.");
            } else {
                /* based on an old Usenet joke, a fake a.out manual page */
                int x = rnd(100);

                pline("%s -- コアダンプ.",
                      (x <= 75)
                         ? "セグメンテーション違反"
                         : (x <= 99)
                            ? "バスエラー"
                            : "お前の母ちゃん");
            }
#endif
        } else {
 give_feedback:
            pline("この%sは%s", singular(otmp, xname),
                  otmp->cursed
                     ? (Hallucination ? "おぞましい味だ!" : "ひどい味だ!")
                     : (otmp->otyp == CRAM_RATION
                        || otmp->otyp == K_RATION
                        || otmp->otyp == C_RATION)
                        ? "味気ない."
                        : Hallucination ? "イケてるぜ!" : "うまい!");
        }
        break; /* default */
    } /* switch */
    return TRUE;
}

/* increment a combat intrinsic with limits on its growth */
staticfn int
bounded_increase(int old, int inc, int typ)
{
    int absold, absinc, sgnold, sgninc;

    /* don't include any amount coming from worn rings (caller handles
       'protection' differently) */
    if (uright && uright->otyp == typ && typ != RIN_PROTECTION)
        old -= uright->spe;
    if (uleft && uleft->otyp == typ && typ != RIN_PROTECTION)
        old -= uleft->spe;
    absold = abs(old), absinc = abs(inc);
    sgnold = sgn(old), sgninc = sgn(inc);

    if (absinc == 0 || sgnold != sgninc || absold + absinc < 10) {
        ; /* use inc as-is */
    } else if (absold + absinc < 20) {
        absinc = rnd(absinc); /* 1..n */
        if (absold + absinc < 10)
            absinc = 10 - absold;
        inc = sgninc * absinc;
    } else if (absold + absinc < 40) {
        absinc = rn2(absinc) ? 1 : 0;
        if (absold + absinc < 20)
            absinc = rnd(20 - absold);
        inc = sgninc * absinc;
    } else {
        inc = 0; /* no further increase allowed via this method */
    }
    /* put amount from worn rings back */
    if (uright && uright->otyp == typ && typ != RIN_PROTECTION)
        old += uright->spe;
    if (uleft && uleft->otyp == typ && typ != RIN_PROTECTION)
        old += uleft->spe;
    return old + inc;
}

staticfn void
accessory_has_effect(struct obj *otmp)
{
    pline("%sを消化するにつれ、魔法が体中に広がっていった.",
          (otmp->oclass == RING_CLASS) ? "指輪" : "魔除け");
}

staticfn void
eataccessory(struct obj *otmp)
{
    int typ = otmp->otyp;
    long oldprop;

    /* Note: rings are not so common that this is unbalancing. */
    /* (How often do you even _find_ 3 rings of polymorph in a game?) */
    oldprop = u.uprops[objects[typ].oc_oprop].intrinsic;
    if (otmp == uleft || otmp == uright) {
        Ring_gone(otmp);
        if (u.uhp <= 0)
            return; /* died from sink fall */
    }
    observe_object(otmp);
    otmp->known = 1; /* by taste */
    if (!rn2(otmp->oclass == RING_CLASS ? 3 : 5)) {
        switch (otmp->otyp) {
        default:
            if (!objects[typ].oc_oprop)
                break; /* should never happen */

            if (!(u.uprops[objects[typ].oc_oprop].intrinsic & FROMOUTSIDE))
                accessory_has_effect(otmp);

            u.uprops[objects[typ].oc_oprop].intrinsic |= FROMOUTSIDE;

            switch (typ) {
            case RIN_SEE_INVISIBLE:
                set_mimic_blocking();
                see_monsters();
                if (Invis && !oldprop && !ESee_invisible
                    && !perceives(gy.youmonst.data) && !Blind) {
                    newsym(u.ux, u.uy);
                    pline("突然、自分の姿が見えるようになった.");
                    makeknown(typ);
                }
                break;
            case RIN_INVISIBILITY:
                if (!oldprop && !EInvis && !BInvis && !See_invisible
                    && !Blind) {
                    newsym(u.ux, u.uy);
                    Your("体は%s透明感を帯びてきた...",
                         Hallucination ? "普通の" : "不思議な");
                    makeknown(typ);
                }
                break;
            case RIN_PROTECTION_FROM_SHAPE_CHAN:
                rescham();
                break;
            case RIN_LEVITATION:
                /* undo the `.intrinsic |= FROMOUTSIDE' done above */
                u.uprops[LEVITATION].intrinsic = oldprop;
                if (!Levitation) {
                    float_up();
                    incr_itimeout(&HLevitation, d(10, 20));
                    makeknown(typ);
                }
                break;
            } /* inner switch */
            break; /* default case of outer switch */

        case RIN_ADORNMENT:
            accessory_has_effect(otmp);
            if (adjattrib(A_CHA, otmp->spe, -1))
                makeknown(typ);
            break;
        case RIN_GAIN_STRENGTH:
            accessory_has_effect(otmp);
            if (adjattrib(A_STR, otmp->spe, -1))
                makeknown(typ);
            break;
        case RIN_GAIN_CONSTITUTION:
            accessory_has_effect(otmp);
            if (adjattrib(A_CON, otmp->spe, -1))
                makeknown(typ);
            break;
        case RIN_INCREASE_ACCURACY:
            accessory_has_effect(otmp);
            u.uhitinc = (schar) bounded_increase((int) u.uhitinc, otmp->spe,
                                                 RIN_INCREASE_ACCURACY);
            break;
        case RIN_INCREASE_DAMAGE:
            accessory_has_effect(otmp);
            u.udaminc = (schar) bounded_increase((int) u.udaminc, otmp->spe,
                                                 RIN_INCREASE_DAMAGE);
            break;
        case RIN_PROTECTION:
        case AMULET_OF_GUARDING:
            accessory_has_effect(otmp);
            HProtection |= FROMOUTSIDE;
            u.ublessed = bounded_increase(u.ublessed,
                                          (typ == RIN_PROTECTION) ? otmp->spe
                                           : 2, /* fixed amount for amulet */
                                          typ);
            disp.botl = TRUE;
            break;
        case RIN_FREE_ACTION:
            /* Give sleep resistance instead */
            if (!(HSleep_resistance & FROMOUTSIDE))
                accessory_has_effect(otmp);
            if (!Sleep_resistance)
                You_feel("目が完全に冴えた.");
            HSleep_resistance |= FROMOUTSIDE;
            break;
        case AMULET_OF_CHANGE:
            accessory_has_effect(otmp);
            makeknown(typ);
            change_sex();
            You("突然、とても%sなった!",
                flags.female ? "女性らしく" : "雄々しく");
            disp.botl = TRUE;
            break;
        case AMULET_OF_UNCHANGING:
            /* un-change: it's a pun */
            if (!Unchanging && Upolyd) {
                accessory_has_effect(otmp);
                makeknown(typ);
                rehumanize();
            }
            break;
        case AMULET_OF_STRANGULATION: /* bad idea! */
            /* no message--this gives no permanent effect */
            choke(otmp);
            break;
        case AMULET_OF_RESTFUL_SLEEP: { /* another bad idea! */
            long newnap = (long) rnd(100), oldnap = (HSleepy & TIMEOUT);

            if (!(HSleepy & FROMOUTSIDE))
                accessory_has_effect(otmp);
            HSleepy |= FROMOUTSIDE;
            /* might also be wearing one; use shorter of two timeouts */
            if (newnap < oldnap || oldnap == 0L)
                HSleepy = (HSleepy & ~TIMEOUT) | newnap;
            break;
        }
        case RIN_SUSTAIN_ABILITY:
        case AMULET_OF_LIFE_SAVING:
        case AMULET_OF_FLYING:
        case AMULET_OF_REFLECTION: /* nice try */
            /* can't eat Amulet of Yendor or fakes,
             * and no oc_prop even if you could -3.
             */
            break;
        }
    }
}

/* called after eating non-food */
staticfn void
eatspecial(void)
{
    struct obj *otmp = svc.context.victual.piece;

    /* lesshungry wants an occupation to handle choke messages correctly */
    set_occupation(eatfood, "eating non-food", 0);
    lesshungry(svc.context.victual.nmod);
    go.occupation = 0;
    svc.context.victual = zero_victual; /* victual.piece = 0, .o_id = 0 */

    if (otmp->oclass == COIN_CLASS) {
        if (carried(otmp))
            useupall(otmp);
        else
            useupf(otmp, otmp->quan);
        vault_gd_watching(GD_EATGOLD);
        return;
    }
    if (objects[otmp->otyp].oc_material == PAPER) {
#ifdef MAIL_STRUCTURES
        if (otmp->otyp == SCR_MAIL)
            /* no nutrition */
            pline("このジャンクメールはあまり満足できなかった.");
        else
#endif
        if (otmp->otyp == SCR_SCARE_MONSTER)
            /* to eat scroll, hero is currently polymorphed into a monster */
            pline("おえっ%c", otmp->blessed ? '!' : '.');
        else if (otmp->oclass == SCROLL_CLASS
                 /* check description after checking for specific scrolls */
                 && objdescr_is(otmp, "YUM YUM"))
            pline("うまい%c", otmp->blessed ? '!' : '.');
        else
            pline("塩が足りなかった...");
    }
    if (otmp->oclass == POTION_CLASS) {
        otmp->quan++; /* dopotion() does a useup() */
        (void) dopotion(otmp);
    } else if (otmp->oclass == RING_CLASS || otmp->oclass == AMULET_CLASS) {
        eataccessory(otmp);
    } else if (otmp->otyp == LEASH && otmp->leashmon) {
        o_unleash(otmp);
    }

    /* KMH -- idea by "Tommy the Terrorist" */
    if (otmp->otyp == TRIDENT && !otmp->cursed) {
        /* sugarless chewing gum which used to be heavily advertised on TV */
        pline(Hallucination ? "歯医者の5人中4人が太鼓判を押している."
                    : "噛みごたえは文句なしだった!");
        exercise(A_WIS, TRUE);
    }
    if (otmp->otyp == FLINT && !otmp->cursed) {
        /* chewable vitamin for kids based on "The Flintstones" TV cartoon */
        pline("ヤバーダバー、うまーい!");
        exercise(A_CON, TRUE);
    }

    if (otmp == uwep && otmp->quan == 1L)
        uwepgone();
    if (otmp == uquiver && otmp->quan == 1L)
        uqwepgone();
    if (otmp == uswapwep && otmp->quan == 1L)
        uswapwepgone();

    if (otmp == uball)
        unpunish();
    if (otmp == uchain)
        unpunish(); /* but no useup() */
    else if (carried(otmp))
        useup(otmp);
    else
        useupf(otmp, 1L);
}

/* NOTE: the order of these words exactly corresponds to the
   order of oc_material values #define'd in objclass.h. */
static const char *const foodwords[] = {
    "meal",    "liquid",  "wax",       "food", "meat",     "paper",
    "cloth",   "leather", "wood",      "bone", "scale",    "metal",
    "metal",   "metal",   "silver",    "gold", "platinum", "mithril",
    "plastic", "glass",   "rich food", "stone"
};

/* Display-only localized labels keyed by oc_material order. */
static const char *const jp_foodwords[] = {
    "食事", "液体", "蝋", "食べ物", "肉", "紙", "布", "革", "木", "骨",
    "鱗", "金属", "金属", "金属", "銀", "金", "プラチナ", "ミスリル",
    "プラスチック", "ガラス", "ごちそう", "石"
};

staticfn const char *
foodword(struct obj *otmp)
{
    if (otmp->oclass == FOOD_CLASS)
        return "food";
    if (otmp->oclass == GEM_CLASS && objects[otmp->otyp].oc_material == GLASS
        && otmp->dknown)
        makeknown(otmp->otyp);
    return foodwords[objects[otmp->otyp].oc_material];
}

staticfn const char *
jp_foodword_for_display(struct obj *otmp)
{
    if (otmp->oclass == FOOD_CLASS)
        return "食べ物";
    if (otmp->oclass == GEM_CLASS && objects[otmp->otyp].oc_material == GLASS
        && otmp->dknown)
        makeknown(otmp->otyp);
    return jp_foodwords[objects[otmp->otyp].oc_material];
}

/* called after consuming (non-corpse) food */
staticfn void
fpostfx(struct obj *otmp)
{
    switch (otmp->otyp) {
    case SPRIG_OF_WOLFSBANE:
        if (ismnum(u.ulycn) || is_were(gy.youmonst.data))
            you_unwere(TRUE);
        break;
    case CARROT:
        if (!u.uswallow
            || !attacktype_fordmg(u.ustuck->data, AT_ENGL, AD_BLND))
            make_blinded((long) u.ucreamed, TRUE);
        break;
    case FORTUNE_COOKIE:
        outrumor(bcsign(otmp), BY_COOKIE);
        if (!Blind)
            if (!u.uconduct.literate++)
                livelog_printf(LL_CONDUCT,
                    "クッキーの中のメッセージを読むことで読み書きができるようになった");
        break;
    case LUMP_OF_ROYAL_JELLY:
        if (gy.youmonst.data == &mons[PM_KILLER_BEE] && !Unchanging
            && polymon(PM_QUEEN_BEE))
            break;

        /* This stuff seems to be VERY healthy! */
        gainstr(otmp, 1, TRUE);
        if (Upolyd) {
            u.mh += otmp->cursed ? -rnd(20) : rnd(20), disp.botl = TRUE;
            if (u.mh > u.mhmax) {
                if (!rn2(17))
                    setuhpmax(u.mhmax + 1, FALSE);
                u.mh = u.mhmax;
            } else if (u.mh <= 0) {
                rehumanize();
            }
        } else {
            u.uhp += otmp->cursed ? -rnd(20) : rnd(20), disp.botl = TRUE;
            if (u.uhp > u.uhpmax) {
                if (!rn2(17))
                    setuhpmax(u.uhpmax + 1, FALSE);
                u.uhp = u.uhpmax;
            } else if (u.uhp <= 0) {
                svk.killer.format = KILLED_BY_AN;
                Strcpy(svk.killer.name, "rotten lump of royal jelly");
                done(POISONING);
            }
        }
        if (!otmp->cursed)
            heal_legs(0);
        break;
    case EGG:
        if (ismnum(otmp->corpsenm)
            && flesh_petrifies(&mons[otmp->corpsenm])) {
            if (!Stone_resistance
                && !(poly_when_stoned(gy.youmonst.data)
                     && polymon(PM_STONE_GOLEM))) {
                if (!Stoned) {
                    Sprintf(svk.killer.name, "%s egg",
                            mons[otmp->corpsenm].pmnames[NEUTRAL]);
                    make_stoned(5L, (char *) 0, KILLED_BY_AN,
                                svk.killer.name);
                }
            }
            /* note: no "tastes like chicken" message for eggs */
        }
        break;
    case EUCALYPTUS_LEAF:
        if (Sick && !otmp->cursed)
            make_sick(0L, (char *) 0, TRUE, SICK_ALL);
        if (Vomiting && !otmp->cursed)
            make_vomiting(0L, TRUE);
        break;
    case APPLE:
        if (otmp->cursed && !Sleep_resistance) {
            /* Snow White; 'poisoned' applies to [a subset of] weapons,
               not food, so we substitute cursed; fortunately our hero
               won't have to wait for a prince to be rescued/revived */
            if (Race_if(PM_DWARF) && Hallucination) {
                verbalize("ハイ・ホー、フムフム、今日は仕事休みだな.");
            } else if (Deaf || !flags.acoustics) {
                You("眠りに落ちた.");
            } else {
                Soundeffect(se_sinister_laughter, 100);
                You_hear("眠りに落ちる時、不気味な笑い声が聞こえる...");
            }
            fall_asleep(-rn1(11, 20), TRUE);
        }
        break;
    }
    return;
}

#if 0
/* intended for eating a spellbook while polymorphed, but not used;
   "leather" applied to appearance, not composition, and has been
   changed to "leathery" to reflect that */
staticfn boolean leather_cover(struct obj *);

staticfn boolean
leather_cover(struct obj *otmp)
{
    const char *odesc = OBJ_DESCR(objects[otmp->otyp]);

    if (odesc && (otmp->oclass == SPBOOK_CLASS)) {
        if (!strcmp(odesc, "leather"))
            return TRUE;
    }
    return FALSE;
}
#endif

/*
 * return 0 if the food was not dangerous.
 * return 1 if the food was dangerous and you chose to stop.
 * return 2 if the food was dangerous and you chose to eat it anyway.
 */
staticfn int
edibility_prompts(struct obj *otmp)
{
    /* Blessed food detection grants hero a one-use
     * ability to detect food that is unfit for consumption
     * or dangerous and avoid it.
     */
    char buf[BUFSZ], foodsmell[BUFSZ];
    /* 5.0: decaying globs don't become tainted anymore; in 3.6, they did */
    boolean cadaver = (otmp->otyp == CORPSE), stoneorslime = FALSE;
    int material = objects[otmp->otyp].oc_material, mnum = otmp->corpsenm;
    long rotted = 0L;

    Strcpy(foodsmell, Tobjnam(otmp, "smell"));

    if (cadaver || otmp->otyp == EGG || otmp->otyp == TIN
        || otmp->otyp == GLOB_OF_GREEN_SLIME) {
        /* These checks must match those in eatcorpse() */
        stoneorslime = (ismnum(mnum)
                        && flesh_petrifies(&mons[mnum])
                        && !Stone_resistance
                        && !poly_when_stoned(gy.youmonst.data));

        if (mnum == PM_GREEN_SLIME || otmp->otyp == GLOB_OF_GREEN_SLIME)
            stoneorslime = (!Unchanging && !slimeproof(gy.youmonst.data));

        if (cadaver && !nonrotting_corpse(mnum)) {
            long age = peek_at_iced_corpse_age(otmp);

            /* worst case rather than random
               in this calculation to force prompt */
            rotted = (svm.moves - age) / (10L + 0 /* was rn2(20) */);
            if (otmp->cursed)
                rotted += 2L;
            else if (otmp->blessed)
                rotted -= 2L;
        }
    }

    /*
     * These problems with food should be checked in
     * order from most detrimental to least detrimental.
     */
    buf[0] = '\0';
    if (cadaver && rotted > 5L && !Sick_resistance) {
        /* Tainted meat */
        Snprintf(buf, sizeof buf, "%s。ひどく汚染されているかもしれない!",
             foodsmell);
    } else if (stoneorslime) {
        Snprintf(buf, sizeof buf,
             "%s。とても危険なものかもしれない!",
             foodsmell);
    } else if (cadaver && rotted > 5L && Sick_resistance) {
        /* Tainted meat with Sick_resistance (testing for that is
           redundant; we don't get this far for !Sick_resistance)
           needs to be done now even though there is no danger because
           it can't match after the rotten (cadaver && rotted > 3) test */
        Snprintf(buf, sizeof buf, "%s。汚染されているかもしれない.",
             foodsmell);
    } else if (otmp->orotten || (cadaver && rotted > 3L)) {
        /* Rotten */
        Snprintf(buf, sizeof buf, "%s。腐っているかもしれない!",
             foodsmell);
    } else if (cadaver && poisonous(&mons[mnum]) && !Poison_resistance) {
        /* poisonous */
        Snprintf(buf, sizeof buf, "%s。毒があるかもしれない!",
             foodsmell);
    } else if (otmp->otyp == APPLE && otmp->cursed && !Sleep_resistance) {
        /* causes sleep, for long enough to be dangerous */
        Snprintf(buf, sizeof buf, "%s。毒入りかもしれない.",
             foodsmell);
    } else if (cadaver && !vegetarian(&mons[mnum])
               && !u.uconduct.unvegetarian && Role_if(PM_MONK)) {
        Snprintf(buf, sizeof buf, "%s体に良くなさそうだ.", foodsmell);
    } else if (cadaver && acidic(&mons[mnum]) && !Acid_resistance) {
        Snprintf(buf, sizeof buf, "%sかなり酸っぱいようだ.", foodsmell);
    } else if (Upolyd && u.umonnum == PM_RUST_MONSTER && is_metallic(otmp)
               && otmp->oerodeproof) {
        Snprintf(buf, sizeof buf, "%s今のあなたには受け付けない.",
             foodsmell);

    /*
     * Breaks conduct, but otherwise safe.
     */
    } else if (!u.uconduct.unvegan
               && ((material == LEATHER || material == BONE
                    || material == DRAGON_HIDE || material == WAX)
                   || (cadaver && !vegan(&mons[mnum])))) {
        Snprintf(buf, sizeof buf, "%sあなたには不快でなじみがない.",
             foodsmell);
    } else if (!u.uconduct.unvegetarian
               && ((material == LEATHER || material == BONE
                    || material == DRAGON_HIDE)
                   || (cadaver && !vegetarian(&mons[mnum])))) {
        Snprintf(buf, sizeof buf, "%sあなたにはなじみがない.", foodsmell);
    }

    if (*buf) {
        Snprintf(eos(buf), sizeof buf - strlen(buf),
             "  それでも%s食べますか?",
             (otmp->quan == 1L) ? "" : "1つ");
        return (yn_function(buf, ynchars, 'n', TRUE) == 'n') ? 1 : 2;
    }
    return 0;
}

staticfn int
doeat_nonfood(struct obj *otmp)
{
    int basenutrit; /* nutrition of full item */
    int ll_conduct = 0;
    boolean nodelicious = FALSE;
    int material;

    svc.context.victual.reqtime = 1;
    svc.context.victual.piece = otmp;
    svc.context.victual.o_id = otmp->o_id;
    /* Don't split it, we don't need to if it's 1 move */
    svc.context.victual.usedtime = 0;
    svc.context.victual.canchoke = (u.uhs == SATIATED);
    /* Note: gold weighs 1 pt. for each 1000 pieces (see
       pickup.c) so gold and non-gold is consistent. */
    if (otmp->oclass == COIN_CLASS)
        basenutrit = ((otmp->quan > 200000L) ? 2000
                      : (int) (otmp->quan / 100L));
    else if (otmp->oclass == BALL_CLASS || otmp->oclass == CHAIN_CLASS)
        basenutrit = weight(otmp);
    /* oc_nutrition is usually weight anyway */
    else
        basenutrit = objects[otmp->otyp].oc_nutrition;
#ifdef MAIL_STRUCTURES
    if (otmp->otyp == SCR_MAIL) {
        basenutrit = 0;
        nodelicious = TRUE;
    }
#endif
    svc.context.victual.nmod = basenutrit;
    svc.context.victual.eating = 1; /* needed for lesshungry() */

    if (!u.uconduct.food++) {
        ll_conduct++;
        livelog_printf(LL_CONDUCT, "初めて食事をした（%s）",
                       food_xname(otmp, FALSE));
    }
    material = objects[otmp->otyp].oc_material;
    if (material == LEATHER || material == BONE
        || material == DRAGON_HIDE || material == WAX) {
        if (!u.uconduct.unvegan++ && !ll_conduct) {
            livelog_printf(LL_CONDUCT,
                  "初めて動物性食品を口にした（%sを食べることで）",
                           food_xname(otmp, FALSE));
            ll_conduct++;
        }
        if (material != WAX) {
            if (!u.uconduct.unvegetarian && !ll_conduct)
                livelog_printf(LL_CONDUCT,
                   "初めて肉製品を口にした（%sを食べることで）",
                               food_xname(otmp, FALSE));
            violated_vegetarian();
        }
    }

    if (otmp->cursed) {
        (void) rottenfood(otmp);
        nodelicious = TRUE;
    } else if (objects[otmp->otyp].oc_material == PAPER)
        nodelicious = TRUE;

    if (otmp->oclass == WEAPON_CLASS && otmp->opoisoned) {
        pline("うげっ - 毒があった!");
        if (!Poison_resistance) {
            poison_strdmg(rnd(4), rnd(15), xname(otmp), KILLED_BY_AN);
        } else
            You("毒の影響を受けていないようだ.");
    } else if (!nodelicious) {
          pline("%sはおいしい!",
              (otmp->oclass == COIN_CLASS)
                                ? jp_foodword_for_display(otmp)
                : singular(otmp, xname));
    }
    eatspecial();
    return ECMD_TIME;
}

/* the #eat command */
int
doeat(void)
{
    struct obj *otmp;
    int basenutrit; /* nutrition of full item */
    boolean dont_start = FALSE,
            already_partly_eaten;
    int ll_conduct = 0;

    if (Strangled) {
        pline("空気を吸えないのに、どうやって固形物を食べられるのか?");
        return ECMD_OK;
    }
    if (!(otmp = floorfood("eat", 0)))
        return ECMD_OK;
    if (check_capacity((char *) 0))
        return ECMD_OK;

    if (u.uedibility) {
        int res = edibility_prompts(otmp);

        if (res) {
            Your(
                             "%sのむずむずはおさまり、嗅覚は元に戻った.",
                 jp_body_part(NOSE));
            u.uedibility = 0;
            if (res == 1)
                return ECMD_OK;
        }
    }

    /* from floorfood(), &hands_obj means iron bars at current spot */
    if (otmp == &hands_obj) {
        /* hero in metallivore form is eating [diggable] iron bars
           at current location so skip the other assorted checks;
           operates as if digging rather than via the eat occupation */
        if (still_chewing(u.ux, u.uy) && levl[u.ux][u.uy].typ == IRONBARS) {
            /* this is verbose, but player will see the hero rather than the
               bars so wouldn't know that more turns of eating are required */
            You("飲み込むために一休みした.");
        }
        return ECMD_TIME;
    }
    /* We have to make non-foods take 1 move to eat, unless we want to
     * do ridiculous amounts of coding to deal with partly eaten plate
     * mails, players who polymorph back to human in the middle of their
     * metallic meal, etc....
     */
    if (!is_edible(otmp)) {
        You("それは食べられない!");
        return ECMD_OK;
    } else if ((otmp->owornmask & (W_ARMOR | W_TOOL | W_AMUL | W_SADDLE))
               != 0) {
        /* let them eat rings */
        You_cant("身につけている%sを食べることはできない.", something);
        return ECMD_OK;
    } else if (!(carried(otmp) ? retouch_object(&otmp, FALSE)
                               : touch_artifact(otmp, &gy.youmonst))) {
        return ECMD_TIME; /* got blasted so use a turn */
    }
    if (is_metallic(otmp) && u.umonnum == PM_RUST_MONSTER
        && otmp->oerodeproof) {
        otmp->rknown = TRUE;
        if (otmp->quan > 1L) {
            if (!carried(otmp))
                (void) splitobj(otmp, otmp->quan - 1L);
            else
                otmp = splitobj(otmp, 1L);
        }
        pline("うげっ - その%sは防錆加工されていた!", xname(otmp));
        /* The regurgitated object's rustproofing is gone now */
        otmp->oerodeproof = 0;
        make_stunned((HStun & TIMEOUT) + (long) rn2(10), TRUE);
        /*
         * We don't expect rust monsters to be wielding welded weapons
         * or wearing cursed rings which were rustproofed, but guard
         * against the possibility just in case.
         */
        if (welded(otmp) || (otmp->cursed && (otmp->owornmask & W_RING))) {
            set_bknown(otmp, 1); /* for ring; welded() does this for weapon */
            You("%sを吐き出した.", xname(otmp));
        } else {
            You("%sを%sの上に吐き出した.", xname(otmp),
                surface(u.ux, u.uy));
            if (carried(otmp)) {
                /* no need to check for leash in use; it's not metallic */
                if (otmp->owornmask)
                    remove_worn_item(otmp, FALSE);
                freeinv(otmp);
                dropy(otmp);
            }
            stackobj(otmp);
        }
        return ECMD_TIME;
    }
    /* KMH -- Slow digestion is... indigestible */
    if (otmp->otyp == RIN_SLOW_DIGESTION) {
        pline("この指輪は消化できなかった!");
        (void) rottenfood(otmp);
        if (otmp->dknown)
            trycall(otmp);
        return ECMD_TIME;
    }
    if (otmp->oclass != FOOD_CLASS)
        return doeat_nonfood(otmp);


    if (otmp == svc.context.victual.piece) {
        boolean one_bite_left = (svc.context.victual.usedtime + 1
                                 >= svc.context.victual.reqtime);

        /* If they weren't able to choke, they don't suddenly become able to
         * choke just because they were interrupted.  On the other hand, if
         * they were able to choke before, if they lost food it's possible
         * they shouldn't be able to choke now.
         */
        if (u.uhs != SATIATED)
            svc.context.victual.canchoke = 0;
        svc.context.victual.o_id = 0;
        otmp = touchfood(otmp);
        if (otmp) {
            svc.context.victual.piece = otmp;
            svc.context.victual.o_id = otmp->o_id;
        } else {
            do_reset_eat();
        }
        /* if there's only one bite left, there sometimes won't be any
           "you finish eating" message when done; use different wording
           for resuming with one bite remaining instead of trying to
           determine whether or not "you finish" is going to be given */
        You("食事を%s.",
            !one_bite_left ? "再開した" : "最後の一口まで食べ切った");
        if (otmp)
            start_eating(otmp, FALSE);
        return ECMD_TIME;
    }

    /* nothing in progress - so try to find something. */
    /* tins are a special case */
    /* tins must also check conduct separately in case they're discarded */
    if (otmp->otyp == TIN) {
        start_tin(otmp);
        return ECMD_TIME;
    }

    /* KMH, conduct */
    if (!u.uconduct.food++) {
        livelog_printf(LL_CONDUCT, "初めて食事をした - %s",
                       food_xname(otmp, FALSE));
        ll_conduct++;
    }

    already_partly_eaten = otmp->oeaten ? TRUE : FALSE;
    otmp = touchfood(otmp);
    if (otmp) {
        svc.context.victual.piece = otmp;
        svc.context.victual.o_id = otmp->o_id;
        svc.context.victual.usedtime = 0;
    } else {
        do_reset_eat();
        return ECMD_TIME;
    }

    /* Now we need to calculate delay and nutritional info.
     * The base nutrition calculated here and in eatcorpse() accounts
     * for normal vs. rotten food.  The reqtime and nutrit values are
     * then adjusted in accordance with the amount of food left.
     */
    if (otmp->otyp == CORPSE || otmp->globby) {
        int tmp = eatcorpse(otmp);

        if (tmp == 2) {
            /* used up */
            svc.context.victual = zero_victual; /* victual.piece=0, .o_id=0 */
            return ECMD_TIME;
        } else if (tmp)
            dont_start = TRUE;
        /* if not used up, eatcorpse sets up reqtime and may modify oeaten */
    } else {
        /* No checks for WAX, LEATHER, BONE, DRAGON_HIDE.  These are
         * all handled in the != FOOD_CLASS case, above.
         */
        switch (objects[otmp->otyp].oc_material) {
        case FLESH:
            if (!u.uconduct.unvegan++ && !ll_conduct) {
                livelog_printf(LL_CONDUCT,
                  "初めて動物性食品を口にした（%sを食べることで）",
                               food_xname(otmp, FALSE));
                ll_conduct++;
            }
            if (otmp->otyp != EGG) {
                if (!u.uconduct.unvegetarian && !ll_conduct)
                    livelog_printf(LL_CONDUCT,
                               "初めて肉を口にした（%sを食べることで）",
                                   food_xname(otmp, FALSE));

                violated_vegetarian();
            }
            break;
        default:
            if (otmp->otyp == PANCAKE || otmp->otyp == FORTUNE_COOKIE /*eggs*/
                || otmp->otyp == CREAM_PIE || otmp->otyp == CANDY_BAR /*milk*/
                || otmp->otyp == LUMP_OF_ROYAL_JELLY)
                if (!u.uconduct.unvegan++ && !ll_conduct)
                    livelog_printf(LL_CONDUCT,
                           "初めて動物性食品（%s）を口にした",
                                   food_xname(otmp, FALSE));
            break;
        }

        svc.context.victual.reqtime = objects[otmp->otyp].oc_delay;
        if (otmp->otyp != FORTUNE_COOKIE
            && (otmp->cursed || (!nonrotting_food(otmp->otyp)
                                 && (svm.moves - otmp->age)
                                        > (otmp->blessed ? 50L : 30L)
                                 && (otmp->orotten || !rn2(7))))) {
            if (rottenfood(otmp)) {
                otmp->orotten = TRUE;
                dont_start = TRUE;
            }
            consume_oeaten(otmp, 1); /* oeaten >>= 1 */
        } else if (!already_partly_eaten) {
            if (!fprefx(otmp)) {
                do_reset_eat();
                return ECMD_TIME;
            }
        } else {
            You("%sを%s.", doname(otmp),
                (svc.context.victual.reqtime == 1) ? "食べた" : "食べ始めた");
        }
    }

    /* re-calc the nutrition */
    basenutrit = (int) obj_nutrition(otmp);

    debugpline3(
     "before rounddiv: victual.reqtime == %d, oeaten == %d, basenutrit == %d",
                svc.context.victual.reqtime, otmp->oeaten, basenutrit);

    svc.context.victual.reqtime
        = (basenutrit == 0) ? 0
          : rounddiv(svc.context.victual.reqtime * (long) otmp->oeaten,
                     basenutrit);

    debugpline1("after rounddiv: victual.reqtime == %d",
                svc.context.victual.reqtime);
    /*
     * calculate the modulo value (nutrit. units per round eating)
     * note: this isn't exact - you actually lose a little nutrition due
     *       to this method.
     * TODO: add in a "remainder" value to be given at the end of the meal.
     */
    if (svc.context.victual.reqtime == 0 || otmp->oeaten == 0)
        /* possible if most has been eaten before */
        svc.context.victual.nmod = 0;
    else if ((int) otmp->oeaten >= svc.context.victual.reqtime)
        svc.context.victual.nmod = -((int) otmp->oeaten
                                    / svc.context.victual.reqtime);
    else
        svc.context.victual.nmod = svc.context.victual.reqtime % otmp->oeaten;
    svc.context.victual.canchoke = (u.uhs == SATIATED);

    if (!dont_start)
        start_eating(otmp, already_partly_eaten);
    else
        otmp->owt = weight(otmp);
    return ECMD_TIME;
}

/* getobj callback for object to be opened with a tin opener */
staticfn int
tinopen_ok(struct obj *obj)
{
    if (obj && obj->otyp == TIN)
        return GETOBJ_SUGGEST;

    return GETOBJ_EXCLUDE;
}


int
use_tin_opener(struct obj *obj)
{
    struct obj *otmp;
    int res = ECMD_OK;

    if (!carrying(TIN)) {
        You("開けるための缶を持っていない.");
        return ECMD_OK;
    }

    if (obj != uwep) {
        if (obj->cursed && obj->bknown) {
            char qbuf[QBUFSZ];

            if (ynq(safe_qbuf(qbuf, "Really wield ", "?",
                              obj, doname, thesimpleoname, "that")) != 'y')
                return ECMD_OK;
        }
        if (!wield_tool(obj, "use"))
            return ECMD_OK;
        res = ECMD_TIME;
    }

    otmp = getobj("open", tinopen_ok, GETOBJ_NOFLAGS);
    if (!otmp)
        return (res|ECMD_CANCEL);

    start_tin(otmp);
    return ECMD_TIME;
}

/* Take a single bite from a piece of food, checking for choking and
 * modifying usedtime.  Returns 1 if they choked and survived, 0 otherwise.
 */
staticfn int
bite(void)
{
    /* hack to pacify static analyzer incorporated into gcc 12.2 */
    sa_victual(&svc.context.victual);

    if (svc.context.victual.canchoke && u.uhunger >= 2000) {
        choke(svc.context.victual.piece);
        return 1;
    }
    if (svc.context.victual.doreset) {
        do_reset_eat();
        return 0;
    }
    gf.force_save_hs = TRUE;
    if (svc.context.victual.nmod < 0) {
        lesshungry(adj_victual_nutrition(/*-svc.context.victual.nmod*/));
        consume_oeaten(svc.context.victual.piece,
                       svc.context.victual.nmod); /* -= -nmod */
    } else if (svc.context.victual.nmod > 0
               && (svc.context.victual.usedtime % svc.context.victual.nmod)) {
        lesshungry(1);
        consume_oeaten(svc.context.victual.piece, -1); /* -= 1 */
    }
    gf.force_save_hs = FALSE;
    recalc_wt();
    return 0;
}

/* as time goes by - called by moveloop(every move) & domove(melee attack) */
void
gethungry(void)
{
    int accessorytime;

    if (u.uinvulnerable || iflags.debug_hunger)
        return; /* you don't feel hungrier */

    /* being polymorphed into a creature which doesn't eat prevents
       this first uhunger decrement, but to stay in such form the hero
       will need to wear an Amulet of Unchanging so still burn a small
       amount of nutrition in the 'moves % 20' ring/amulet check below */
    if ((!Unaware || !rn2(10)) /* slow metabolic rate while asleep */
        && (carnivorous(gy.youmonst.data)
            || herbivorous(gy.youmonst.data)
            || metallivorous(gy.youmonst.data))
        && !Slow_digestion)
        u.uhunger--; /* ordinary food consumption */

    /*
     * 5.0:  trigger is randomized instead of (moves % N).  Makes
     * ring juggling (using the 'time' option to see the turn counter
     * in order to time swapping of a pair of rings of slow digestion,
     * wearing one on one hand, then putting on the other and taking
     * off the first, then vice versa, over and over and over and ...
     * to avoid any hunger from wearing a ring) become ineffective.
     * Also causes melee-induced hunger to vary from turn-based hunger
     * instead of just replicating that.
     */
    accessorytime = rn2(20); /* rn2(20) replaces (int) (svm.moves % 20L) */
    if (accessorytime % 2) { /* odd */
        /* Regeneration uses up food, unless due to an artifact */
        if ((HRegeneration & ~FROMFORM)
            || (ERegeneration & ~(W_ARTI | W_WEP)))
            u.uhunger--;
        if (near_capacity() > SLT_ENCUMBER)
            u.uhunger--;
    } else { /* even */
        if (Hunger)
            u.uhunger--;
        /* Conflict uses up food too */
        if (HConflict || (EConflict & (~W_ARTI)))
            u.uhunger--;
        /*
         * +0 charged rings don't do anything, so don't affect hunger.
         * Slow digestion cancels movement and melee hunger but still
         * causes ring hunger.
         * Possessing the real Amulet imposes a separate hunger penalty
         * from wearing an amulet (so gets a double penalty when worn).
         *
         * 5.0.0:  Worn meat rings don't affect hunger.
         * Same with worn cheap plastic imitation of the Amulet.
         * +0 ring of protection might do something (enhanced "magical
         * cancellation") if hero doesn't have protection from some
         * other source (cloak or second ring).
         *
         * [If wearing duplicate rings whose effects don't stack,
         * should they both consume nutrition, or just one of them?
         * Two +0 rings of protection are treated as if only one,
         * but this could apply to most rings.]
         */
        switch (accessorytime) { /* note: use even cases among 0..19 only */
        case 0:
            /* 5.0: if not wearing a ring of slow digestion, obtaining
               that property from worn armor (white dragon scales/mail)
               causes the armor to burn nutrition; since it's not
               actually a ring, we don't check for it on the ring
               turns; because of that, wearing two (non-slow digestion)
               rings plus the armor consumes more nutrition that one
               non-slow digestion ring plus ring of slow digestion */
            if (Slow_digestion
                && (!uright || uright->otyp != RIN_SLOW_DIGESTION)
                && (!uleft || uleft->otyp != RIN_SLOW_DIGESTION))
                u.uhunger--;
            break;
        case 4:
            if (uleft && uleft->otyp != MEAT_RING
                /* more hungry if +/- is nonzero or +/- doesn't apply or
                   +0 ring of protection is only source of protection;
                   need to check whether both rings are +0 protection or
                   they'd both slip by the "is there another source?" test,
                   but don't do that for both rings or they will both be
                   treated as supplying "MC" when only one matters;
                   note: amulet of guarding overrides both +0 rings and
                   is caught by the (EProtection & ~W_RINGx) == 0L tests */
                && (uleft->spe
                    || !objects[uleft->otyp].oc_charged
                    || (uleft->otyp == RIN_PROTECTION
                        && ((EProtection & ~W_RINGL) == 0L
                            || ((EProtection & ~W_RINGL) == W_RINGR
                                && uright && uright->otyp == RIN_PROTECTION
                                && !uright->spe)))))
                u.uhunger--;
            break;
        case 8:
            if (uamul && uamul->otyp != FAKE_AMULET_OF_YENDOR)
                u.uhunger--;
            break;
        case 12:
            if (uright && uright->otyp != MEAT_RING
                && (uright->spe
                    || !objects[uright->otyp].oc_charged
                    || (uright->otyp == RIN_PROTECTION
                        && (EProtection & ~W_RINGR) == 0L)))
                u.uhunger--;
            break;
        case 16:
            if (u.uhave.amulet)
                u.uhunger--;
            break;
        default:
            break;
        }
    }
    newuhs(TRUE);
}

/* called after vomiting and after performing feats of magic */
void
morehungry(int num)
{
    u.uhunger -= num;
    newuhs(TRUE);
}

/* called after eating (and after drinking fruit juice) */
void
lesshungry(int num)
{
    /* See comments in newuhs() for discussion on force_save_hs */
    boolean iseating = (go.occupation == eatfood) || gf.force_save_hs;

    debugpline1("lesshungry(%d)", num);
    u.uhunger += num;
    if (u.uhunger >= 2000) {
        if (!iseating || svc.context.victual.canchoke) {
            if (iseating) {
                choke(svc.context.victual.piece);
                reset_eat();
            } else {
                choke((go.occupation == opentin) ? svc.context.tin.tin : 0);
                /* no reset_eat() */
            }
        }
    } else {
        /* Have lesshungry() report when you're nearly full so all eating
         * warns when you're about to choke.
         */
        if (u.uhunger >= 1500 && !Hunger
            && (!svc.context.victual.eating
                || (svc.context.victual.eating
                    && !svc.context.victual.fullwarn))) {
            pline("それをすべて飲み込むのに苦労している.");
            gn.nomovemsg = "ようやく食べ終わった.";
            if (!svc.context.victual.eating) {
                gm.multi = -2;
            } else {
                svc.context.victual.fullwarn = 1;
                if (svc.context.victual.canchoke
                    && (svc.context.victual.reqtime
                        - svc.context.victual.usedtime) > 1) {
                    /* food with one bite left will not survive a stop */
                    if (!paranoid_query(ParanoidEating, "食事を続けますか?")) {
                        reset_eat();
                        gn.nomovemsg = (char *) 0;
                    }
                }
            }
        }
    }
    newuhs(FALSE);
}

staticfn int
unfaint(void)
{
    (void) Hear_again();
    if (u.uhs > FAINTING)
        u.uhs = FAINTING;
    stop_occupation();
    disp.botl = TRUE;
    return 0;
}

boolean
is_fainted(void)
{
    return (boolean) (u.uhs == FAINTED);
}

/* call when a faint must be prematurely terminated */
void
reset_faint(void)
{
    if (ga.afternmv == unfaint)
        unmul("意識を取り戻した.");
}

/* compute and comment on your (new?) hunger status */
void
newuhs(boolean incr)
{
    unsigned newhs;
    static unsigned save_hs;
    static boolean saved_hs = FALSE;
    int h = u.uhunger;

    newhs = (h > 1000)
                ? SATIATED
                : (h > 150) ? NOT_HUNGRY
                            : (h > 50) ? HUNGRY : (h > 0) ? WEAK : FAINTING;

    /* While you're eating, you may pass from WEAK to HUNGRY to NOT_HUNGRY.
     * This should not produce the message "you only feel hungry now";
     * that message should only appear if HUNGRY is an endpoint.  Therefore
     * we check to see if we're in the middle of eating.  If so, we save
     * the first hunger status, and at the end of eating we decide what
     * message to print based on the _entire_ meal, not on each little bit.
     */
    /* It is normally possible to check if you are in the middle of a meal
     * by checking occupation == eatfood, but there is one special case:
     * start_eating() can call bite() for your first bite before it
     * sets the occupation.
     * Anyone who wants to get that case to work _without_ an ugly static
     * force_save_hs variable, feel free.
     */
    /* Note: If you become a certain hunger status in the middle of the
     * meal, and still have that same status at the end of the meal,
     * this will incorrectly print the associated message at the end of
     * the meal instead of the middle.  Such a case is currently
     * impossible, but could become possible if a message for SATIATED
     * were added or if HUNGRY and WEAK were separated by a big enough
     * gap to fit two bites.
     */
    if (go.occupation == eatfood || gf.force_save_hs) {
        if (!saved_hs) {
            save_hs = u.uhs;
            saved_hs = TRUE;
        }
        u.uhs = newhs;
        return;
    } else {
        if (saved_hs) {
            u.uhs = save_hs;
            saved_hs = FALSE;
        }
    }

    if (newhs == FAINTING) {
        /* u,uhunger is likely to be negative at this point */
        int uhunger_div_by_10 = sgn(u.uhunger) * ((abs(u.uhunger) + 5) / 10);

        if (is_fainted())
            newhs = FAINTED;
        if (u.uhs <= WEAK || rn2(20 - uhunger_div_by_10) >= 19) {
            if (!is_fainted() && gm.multi >= 0 /* %% */) {
                int duration = 10 - uhunger_div_by_10;

                /* stop what you're doing, then faint */
                stop_occupation();
                You("空腹のあまり意識を失った.");
                incr_itimeout(&HDeaf, duration);
                disp.botl = TRUE;
                nomul(-duration);
                gm.multi_reason = "空腹のあまり失神している";
                gn.nomovemsg = "意識を取り戻した.";
                ga.afternmv = unfaint;
                newhs = FAINTED;
                if (!Levitation)
                    selftouch("倒れ込みながら、あなたは");
            }

        /* this used to be -(200 + 20 * Con) but that was when being asleep
           suppressed per-turn uhunger decrement but being fainted didn't;
           now uhunger becomes more negative at a slower rate */
        } else if (u.uhunger < -(100 + 10 * (int) ACURR(A_CON))) {
            u.uhs = STARVED;
            disp.botl = TRUE;
            bot();
            You("餓死した.");
            svk.killer.format = KILLED_BY;
            Strcpy(svk.killer.name, "starvation");
            done(STARVING);
            /* if we return, we lifesaved, and that calls newuhs */
            return;
        }
    }

    if (newhs != u.uhs) {
        if (newhs >= WEAK && u.uhs < WEAK) {
            /* this used to be losestr(1) which had the potential to
               be fatal (still handled below) by reducing HP if it
               tried to take base strength below minimum of 3 */
            ATEMP(A_STR) = -1; /* temporary loss overrides Fixed_abil */
            /* defer context.botl status update until after hunger message */
        } else if (newhs < WEAK && u.uhs >= WEAK) {
            /* this used to be losestr(-1) which could be abused by
               becoming weak while wearing ring of sustain ability,
               removing ring, eating to 'restore' strength which boosted
               strength by a point each time the cycle was performed;
               substituting "while polymorphed" for sustain ability and
               "rehumanize" for ring removal might have done that too */
            ATEMP(A_STR) = 0; /* repair of loss also overrides Fixed_abil */
            /* defer context.botl status update until after hunger message */
        }

        switch (newhs) {
        case HUNGRY:
            if (Hallucination) {
                You(!incr ? "小腹が空いてきた."
                    : "お腹が空いてきた.");
            } else
                You("%s.", !incr ? "今は空腹を感じるだけだ"
                           : (u.uhunger < 145) ? "お腹が空いた"
                             : "お腹が空き始めてきた");
            if (incr && go.occupation
                && (go.occupation != eatfood && go.occupation != opentin))
                stop_occupation();
            end_running(TRUE);
            break;
        case WEAK:
            if (Hallucination)
                pline(!incr ? "まだ小腹が空いている."
              : "空腹のせいで体がうまく動かない.");
            else if (incr && (Role_if(PM_WIZARD) || Race_if(PM_ELF)
                              || Role_if(PM_VALKYRIE)))
                pline("%sはひどく食べ物を欲している!",
                      (Role_if(PM_WIZARD) || Role_if(PM_VALKYRIE))
                          ? jp_role_name_for_display(flags.initrole, flags.female ? 1 : 0)
                          : "エルフ");
            else
                You("%s.", !incr ? "相変わらず体が衰弱している"
                          : (u.uhunger < 45)
                              ? "空腹を感じており、体が衰弱している"
                              : "空腹を感じ始めており、体が衰弱している");
            if (incr && go.occupation
                && (go.occupation != eatfood && go.occupation != opentin))
                stop_occupation();
            end_running(TRUE);
            break;
        }
        u.uhs = newhs;
        disp.botl = TRUE;
        bot();
        if ((Upolyd ? u.mh : u.uhp) < 1) {
            You("空腹と疲労で死んでしまった.");
            svk.killer.format = KILLED_BY;
            Strcpy(svk.killer.name, "exhaustion");
            done(STARVING);
            return;
        }
    }
}

/* getobj callback for object to eat - effectively just wraps is_edible() */
staticfn int
eat_ok(struct obj *obj)
{
    /* 'getobj_else' will be non-zero if floor food is present and
       player declined to eat that; used to insert "else" into
       "you don't have anything [else] to eat" if not carrying any food */
    if (!obj)
        return getobj_else ? GETOBJ_EXCLUDE_NONINVENT : GETOBJ_EXCLUDE;

    if (is_edible(obj))
        return GETOBJ_SUGGEST;

    /* make sure to exclude, not downplay, gold (if not is_edible) in order to
     * produce the "You cannot eat gold" message in getobj */
    if (obj->oclass == COIN_CLASS)
        return GETOBJ_EXCLUDE;

    return GETOBJ_EXCLUDE_SELECTABLE;
}

/* getobj callback for object to be offered (corpses and things that look like
 * the Amulet only */
staticfn int
offer_ok(struct obj *obj)
{
    if (!obj)
        return getobj_else ? GETOBJ_EXCLUDE_NONINVENT : GETOBJ_EXCLUDE;

    if (obj->oclass != FOOD_CLASS && obj->oclass != AMULET_CLASS)
        return GETOBJ_EXCLUDE;

    if (obj->otyp != CORPSE && obj->otyp != AMULET_OF_YENDOR
        && obj->otyp != FAKE_AMULET_OF_YENDOR)
        return GETOBJ_EXCLUDE_SELECTABLE;

    /* suppress corpses on astral, amulets elsewhere
     * (!astral && amulet) || (astral && !amulet) */
    if (Is_astralevel(&u.uz) ^ (obj->oclass == AMULET_CLASS))
        return GETOBJ_DOWNPLAY;

    return GETOBJ_SUGGEST;
}

/* getobj callback for object to be tinned */
staticfn int
tin_ok(struct obj *obj)
{
    if (!obj)
        return getobj_else ? GETOBJ_EXCLUDE_NONINVENT : GETOBJ_EXCLUDE;

    if (obj->oclass != FOOD_CLASS)
        return GETOBJ_EXCLUDE;

    if (obj->otyp != CORPSE || !tinnable(obj))
        return GETOBJ_EXCLUDE_SELECTABLE;

    return GETOBJ_SUGGEST;
}

/* Returns an object representing food.
 * Object may be either on floor or in inventory.
 */
struct obj *
floorfood(
    const char *verb,
    int corpsecheck) /* 0, no check, 1, corpses, 2, tinnable corpses */
{
    struct obj *otmp;
    char qbuf[QBUFSZ];
    char c;
    struct permonst *uptr = gy.youmonst.data;
    boolean feeding = !strcmp(verb, "eat"),        /* corpsecheck==0 */
            offering = !strcmp(verb, "sacrifice"); /* corpsecheck==1 */

    getobj_else = 0; /* haven't asked about floor food; is used to vary
                      * "you don't have anything [else] to eat" when
                      * floor food has been declined and inventory lacks
                      * any suitable items */
    /* if we can't touch floor objects then use invent food only;
       same when 'm' prefix is used--for #eat, it means "skip floor food" */
    if (iflags.menu_requested
        || !can_reach_floor(TRUE) || (feeding && u.usteed)
        || (is_pool_or_lava(u.ux, u.uy)
            && (Wwalking || is_clinger(uptr) || (Flying && !Breathless))))
        goto skipfloor;

    if (feeding && metallivorous(uptr)) {
        struct obj *gold;
        struct trap *ttmp = t_at(u.ux, u.uy);

        if (ttmp && ttmp->tseen && ttmp->ttyp == BEAR_TRAP) {
            boolean u_in_beartrap = (u.utrap && u.utraptype == TT_BEARTRAP);

            /* If not already stuck in the trap, perhaps there should
               be a chance to becoming trapped?  Probably not, because
               then the trap would just get eaten on the _next_ turn... */
            Sprintf(qbuf, "ここに熊罠がある (%s); 食べますか?",
                    u_in_beartrap ? "これに捕まっている" : "セットされている");
            if ((c = yn_function(qbuf, ynqchars, 'n', TRUE)) == 'y') {
                struct obj *beartrap;

                deltrap(ttmp);
                if (u_in_beartrap)
                    reset_utrap(TRUE);
                beartrap = mksobj(BEARTRAP, TRUE, FALSE);
                Sprintf(qbuf,"なんとか熊罠を%sしただけだった.",
                        u_in_beartrap ? "外して脱出" : "解除");
                if (check_capacity(qbuf) && beartrap) {
                    obj_extract_self(beartrap);
                    dropy(beartrap);           /* put it on the floor */
                    return (struct obj *) 0;
                }
                return beartrap;
            } else if (c == 'q') {
                return (struct obj *) 0;
            }
            ++getobj_else;
        }
        if (levl[u.ux][u.uy].typ == IRONBARS) {
            /* already verified that hero is metallivorous above */
            boolean nodig = (levl[u.ux][u.uy].wall_info & W_NONDIGGABLE) != 0;

            c = 'n';
            Strcpy(qbuf, "ここに鉄格子がある");
            if (nodig || u.uhunger > 1500) {
                pline("%sが、%s食べることはできない.", qbuf,
                      nodig ? "掘り出すことができず" : "お腹がいっぱいで");
            } else {
                Strcat(qbuf, (!svc.context.digging.chew
                              || !u_at(svc.context.digging.pos.x,
                                       svc.context.digging.pos.y)
                              || !on_level(&svc.context.digging.level, &u.uz))
                              ? "; 食べますか?"
                              : "; 食事を再開しますか?");
                c = yn_function(qbuf, ynqchars, 'n', TRUE);
            }
            if (c == 'y')
                return &hands_obj;
            else if (c == 'q')
                return (struct obj *) 0;
            ++getobj_else;
        }
        if (uptr != &mons[PM_RUST_MONSTER]
            && (gold = g_at(u.ux, u.uy)) != 0) {
            if (gold->quan == 1L)
                Sprintf(qbuf, "ここに金貨が1枚ある; 食べますか?");
            else
                Sprintf(qbuf, "ここに金貨が%ld枚ある; 食べますか?",
                        gold->quan);
            if ((c = yn_function(qbuf, ynqchars, 'n', TRUE)) == 'y') {
                return gold;
            } else if (c == 'q') {
                return (struct obj *) 0;
            }
            ++getobj_else;
        }
    }

    /* Is there some food (probably a heavy corpse) here on the ground? */
    for (otmp = svl.level.objects[u.ux][u.uy]; otmp; otmp = otmp->nexthere) {
        if (corpsecheck
                ? (otmp->otyp == CORPSE
                   && (corpsecheck == 1 || tinnable(otmp)))
                : feeding ? (otmp->oclass != COIN_CLASS && is_edible(otmp))
                          : otmp->oclass == FOOD_CLASS) {
            char qsfx[QBUFSZ];
            boolean one = (otmp->quan == 1L);

            /* if blind and without gloves, attempting to eat (or tin or
               offer) a cockatrice corpse is fatal before asking whether
               or not to use it; otherwise, 'm<dir>' followed by 'e' could
               be used to locate cockatrice corpses without touching them */
            if (otmp->otyp == CORPSE && will_feel_cockatrice(otmp, FALSE)) {
                feel_cockatrice(otmp, FALSE);
                /* if life-saved (or poly'd into stone golem), terminate
                   attempt to eat off floor */
                return (struct obj *) 0;
            }
            if (otmp->otyp == CORPSE) {
                Sprintf(qbuf, "そこに%sがある; それを%sか?",
                        jp_corpse_xname(otmp, (const char *) 0,
                                        CXN_SINGULAR | CXN_ARTICLE),
                        offering ? "捧げます" : "食べます");
            } else {
                /* "There is <an object> here; <verb> it?" or
                   "There are <N objects> here; <verb> one?" */
                Sprintf(qbuf, "そこに");
                Sprintf(qsfx, "がある; %sか?",
                        one ? (offering ? "それを捧げます" : "それを食べます")
                            : (offering ? "1つ捧げます" : "1つ食べます"));
                (void) safe_qbuf(qbuf, qbuf, qsfx, otmp, doname, ansimpleoname,
                                 one ? something : (const char *) "things");
            }
            if ((c = yn_function(qbuf, ynqchars, 'n', TRUE)) == 'y')
                return  otmp;
            else if (c == 'q')
                return (struct obj *) 0;
            ++getobj_else;
        }
    }

 skipfloor:
    /* We cannot use GETOBJ_PROMPT since we don't want a prompt in the case
       where nothing edible is being carried. */
    if (feeding) {
        otmp = getobj("eat", eat_ok, GETOBJ_NOFLAGS);
    } else if (offering) {
        otmp = getobj("sacrifice", offer_ok, GETOBJ_NOFLAGS);
    } else if (corpsecheck == 2) {
        otmp = getobj(verb, tin_ok, GETOBJ_NOFLAGS);
    } else {
        impossible("floorfood: unknown request (%s)", verb);
        otmp = (struct obj *) 0;
    }
    if (otmp && corpsecheck && !(offering && otmp->oclass == AMULET_CLASS)) {
        if (otmp->otyp != CORPSE || (corpsecheck == 2 && !tinnable(otmp))) {
            You_cant("%sことはできない!", verb);
            otmp = (struct obj *) 0;
        }
    }
    /* resetting 'getobj_else' here isn't essential; it will be cleared the
       next time it needs to be used */
    getobj_else = 0;
    return otmp;
}

/* Side effects of vomiting */
/* added nomul (MRS) - it makes sense, you're too busy being sick! */
void
vomit(void) /* A good idea from David Neves */
{
    boolean spewed = FALSE;

    if (cantvomit(gy.youmonst.data)) {
        /* doesn't cure food poisoning; message assumes that we aren't
           dealing with some esoteric jp_body_part() */
        Your("あごが痙攣して開いた.");
    } else {
        if (Sick && (u.usick_type & SICK_VOMITABLE) != 0)
            make_sick(0L, (char *) 0, TRUE, SICK_VOMITABLE);
        /* if not enough in stomach to actually vomit then dry heave;
           vomiting_dialog() gives a vomit message when its countdown
           reaches 0, but only if u.uhs < FAINTING (and !cantvomit()) */
        if (u.uhs >= FAINTING)
            Your("%sが激しく痙攣した!", jp_body_part(STOMACH));
        else
            spewed = TRUE;
    }

    /* nomul()/You_can_move_again used to be unconditional, which was
       viable while eating but not for Vomiting countdown where hero might
       be immobilized for some other reason at the time vomit() is called */
    if (gm.multi >= -2) {
        nomul(-2);
        gm.multi_reason = "吐いている";
        gn.nomovemsg = You_can_move_again;
    }

    if (spewed) {
        struct attack
            *mattk = attacktype_fordmg(gy.youmonst.data, AT_BREA, AD_ACID);

        /* currently, only yellow dragons can breathe acid */
        if (mattk) {
            You("自分に向かって酸を吐いた..."); /* [why?] */
            ubreatheu(mattk);
        }
        /* vomiting on an altar is, all things considered, rather impolite */
        if (IS_ALTAR(levl[u.ux][u.uy].typ))
            altar_wrath(u.ux, u.uy);
        /* if poly'd into acidic form, stomach acid is stronger than normal */
        if (acidic(gy.youmonst.data)) {
            /* TODO: if there's a web here, destroy that too (before ice) */
            if (is_ice(u.ux, u.uy))
                melt_ice(u.ux, u.uy,
                         "胃酸が氷を真っ直ぐに溶かした!");
        }
    }
}

int
eaten_stat(int base, struct obj *obj)
{
    long uneaten_amt, full_amount;

    /* get full_amount first; obj_nutrition() might modify obj->oeaten */
    full_amount = (long) obj_nutrition(obj);
    uneaten_amt = (long) obj->oeaten;
    if (uneaten_amt > full_amount) {
        impossible(
          "partly eaten food (%ld) more nutritious than untouched food (%ld)",
                   uneaten_amt, full_amount);
        uneaten_amt = full_amount;
    }

    base = (int) (full_amount ? (long) base * uneaten_amt / full_amount : 0L);
    return (base < 1) ? 1 : base;
}

/* reduce obj's oeaten field, making sure it never hits or passes 0 */
void
consume_oeaten(struct obj *obj, int amt)
{
    if (!obj_nutrition(obj)) {
        char itembuf[40];
        int otyp = obj->otyp;

        if (otyp == CORPSE || otyp == EGG || otyp == TIN) {
            Strcpy(itembuf, (otyp == CORPSE) ? "corpse"
                            : (otyp == EGG) ? "egg"
                              : (otyp == TIN) ? "tin" : "other?");
            Sprintf(eos(itembuf), " [%d]", obj->corpsenm);
        } else {
            Sprintf(itembuf, "%d", otyp);
        }
        impossible(
            "oeaten: attempting to set 0 nutrition food (%s) partially eaten",
                   itembuf);
        return;
    }

    /*
     * This is a hack to try to squelch several long standing mystery
     * food bugs.  A better solution would be to rewrite the entire
     * victual handling mechanism from scratch using a less complex
     * model.  Alternatively, this routine could call done_eating()
     * or food_disappears() but its callers would need revisions to
     * cope with svc.context.victual.piece unexpectedly going away.
     *
     * Multi-turn eating operates by setting the food's oeaten field
     * to its full nutritional value and then running a counter which
     * independently keeps track of whether there is any food left.
     * The oeaten field can reach exactly zero on the last turn, and
     * the object isn't removed from inventory until the next turn
     * when the "you finish eating" message gets delivered, so the
     * food would be restored to the status of untouched during that
     * interval.  This resulted in unexpected encumbrance messages
     * at the end of a meal (if near enough to a threshold) and would
     * yield full food if there was an interruption on the critical
     * turn.  Also, there have been reports over the years of food
     * becoming massively heavy or producing unlimited satiation;
     * this would occur if reducing oeaten via subtraction attempted
     * to drop it below 0 since its unsigned type would produce a
     * huge positive value instead.  So far, no one has figured out
     * _why_ that inappropriate subtraction might sometimes happen.
     */

    if (amt > 0) {
        /* bit shift to divide the remaining amount of food */
        obj->oeaten >>= amt;
    } else {
        /* simple decrement; value is negative so we actually add it */
        if ((int) obj->oeaten > -amt)
            obj->oeaten += amt;
        else
            obj->oeaten = 0;
    }

    /* mustn't let partly-eaten drop all the way to 0 or the item would
       become restored to untouched; set to no bites left */
    if (obj->oeaten == 0) {
        if (obj == svc.context.victual.piece) /* always true unless wishing */
            svc.context.victual.reqtime = svc.context.victual.usedtime;
        obj->oeaten = 1; /* smallest possible positive value */
    }
}

/* called when eatfood occupation has been interrupted,
   or in the case of theft, is about to be interrupted */
boolean
maybe_finished_meal(boolean stopping)
{
    /* in case consume_oeaten() has decided that the food is all gone */
    if (go.occupation == eatfood
        && svc.context.victual.usedtime >= svc.context.victual.reqtime) {
        if (stopping)
            go.occupation = 0; /* for do_reset_eat */
        /* eatfood() calls done_eating() to use up svc.context.victual.piece */
        (void) eatfood();
        return TRUE;
    }
    return FALSE;
}

/* called by revive(); sort of the opposite of maybe_finished_meal() */
void
cant_finish_meal(struct obj *corpse)
{
    /*
     * When a corpse gets resurrected, the makemon() for that might
     * call stop_occupation().  If that happens, prevent it from using
     * up the corpse via maybe_finished_meal() when there's not enough
     * left for another bite.  revive() needs continued access to the
     * corpse and will delete it when done.
     */
    if (go.occupation == eatfood && svc.context.victual.piece == corpse) {
        /* normally performed by done_eating() */
        svc.context.victual = zero_victual; /* victual.piece = 0, .o_id = 0 */

        if (!corpse->oeaten)
            corpse->oeaten = 1; /* [see consume_oeaten()] */
        go.occupation = donull; /* any non-Null other than eatfood() */
        stop_occupation();
        newuhs(FALSE);
    }
}

/* Tin of <something> to the rescue?  Decide whether current occupation
   is an attempt to eat a tin of something capable of saving hero's life.
   We don't care about consumption of non-tinned food here because special
   effects there take place on first bite rather than at end of occupation.
   [Popeye the Sailor gets out of trouble by eating tins of spinach. :-] */
boolean
Popeye(int threat)
{
    struct obj *otin;
    int mndx;

    if (go.occupation != opentin)
        return FALSE;
    otin = svc.context.tin.tin;
    /* make sure hero still has access to tin */
    if (!carried(otin)
        && (!obj_here(otin, u.ux, u.uy) || !can_reach_floor(TRUE)))
        return FALSE;
    /* unknown tin is assumed to be helpful */
    if (!otin->known)
        return TRUE;
    /* known tin is helpful if it will stop life-threatening problem */
    mndx = otin->corpsenm;
    switch (threat) {
    /* note: not used; hunger code bypasses stop_occupation() when eating */
    case HUNGER:
        return (boolean) (mndx != NON_PM || otin->spe == 1);
    /* flesh from lizards and acidic critters stops petrification */
    case STONED:
        return (boolean) (ismnum(mndx)
                          && (mndx == PM_LIZARD || acidic(&mons[mndx])));
    /* polymorph into a fiery monster */
    case SLIMED:
        return (boolean) polyfood(otin);
    /* no tins can cure these (yet?) */
    case SICK:
    case VOMITING:
        break;
    default:
        break;
    }
    return FALSE;
}

/* the hero has swallowed a monster whole as a purple worm or similar, and has
   finished digesting its corpse (called via ga.afternmv) */
int
Finish_digestion(void)
{
    if (gc.corpsenm_digested != NON_PM) {
        cpostfx(gc.corpsenm_digested);
        gc.corpsenm_digested = NON_PM;
    }
    return 0;
}

/*eat.c*/


