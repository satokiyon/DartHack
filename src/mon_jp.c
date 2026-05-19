#include "config.h"
#include "permonst.h"

/*
 * モンスター表示名の日本語テーブル。
 * 内部ID解決は英語 pmnames[] を使い続けるため、表示専用で参照する。
 */
static const char *const mon_jp_names[NUMMONS][NUM_MGENDERS] = {
    [PM_GIANT_ANT] = { 0, 0, "巨大アリ" },
    [PM_KILLER_BEE] = { 0, 0, "キラービー" },
    [PM_SOLDIER_ANT] = { 0, 0, "兵隊アリ" },
    [PM_FIRE_ANT] = { 0, 0, "火アリ" },
    [PM_GIANT_BEETLE] = { 0, 0, "巨大カブトムシ" },
    [PM_QUEEN_BEE] = { 0, 0, "女王バチ" },
    [PM_ACID_BLOB] = { 0, 0, "酸の塊" },
    [PM_QUIVERING_BLOB] = { 0, 0, "震える塊" },
    [PM_GELATINOUS_CUBE] = { 0, 0, "ゼラチン質キューブ" },
    [PM_CHICKATRICE] = { 0, 0, "ひよこカトリス" },
    [PM_COCKATRICE] = { 0, 0, "コカトリス" },
    [PM_PYROLISK] = { 0, 0, "パイロリスク" },
    [PM_JACKAL] = { 0, 0, "ジャッカル" },
    [PM_FOX] = { 0, 0, "キツネ" },
    [PM_COYOTE] = { 0, 0, "コヨーテ" },
    [PM_LITTLE_DOG] = { 0, 0, "小さな犬" },
    [PM_DOG] = { 0, 0, "犬" },
    [PM_LARGE_DOG] = { 0, 0, "大型犬" },
    [PM_WOLF] = { 0, 0, "オオカミ" },
    [PM_WINTER_WOLF] = { 0, 0, "冬のオオカミ" },
};

static int
pmname_gender_slot(struct permonst *pm, int mgender)
{
    if ((mgender == MALE || mgender == FEMALE) && pm->pmnames[mgender])
        return mgender;
    return NEUTRAL;
}

const char *
jp_pmname(struct permonst *pm, int mgender)
{
    int pmidx, gslot;
    const char *jp;

    if (!pm)
        return "";

    gslot = pmname_gender_slot(pm, mgender);
    pmidx = (int) pm->pmidx;

    if (pmidx >= LOW_PM && pmidx < NUMMONS) {
        jp = mon_jp_names[pmidx][gslot];
        if (!jp && gslot != NEUTRAL)
            jp = mon_jp_names[pmidx][NEUTRAL];
        if (jp)
            return jp;
    }
    return pm->pmnames[gslot];
}

const char *
jp_pmname_from_idx(int pmidx, int mgender)
{
    if (pmidx >= LOW_PM && pmidx < NUMMONS)
        return jp_pmname(&mons[pmidx], mgender);
    return "";
}
