/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-27. */
/* NetHack 5.0	topten.c	$NHDT-Date: 1781973070 2026/06/20 16:31:10 $  $NHDT-Branch: NetHack-5.0 $:$NHDT-Revision: 1.111 $ */
/* Copyright (c) Stichting Mathematisch Centrum, Amsterdam, 1985. */
/*-Copyright (c) Robert Patrick Rankin, 2012. */
/* NetHack may be freely redistributed.  See license for details. */

#include "hack.h"
#include "dlb.h"

#if defined(VMS) && !defined(UPDATE_RECORD_IN_PLACE)
/* We don't want to rewrite the whole file, because that entails
   creating a new version which requires that the old one be deletable.
   [Write and Delete are separate permissions on VMS.  'record' should
   be writable but not deletable there.]  */
#define UPDATE_RECORD_IN_PLACE
#endif

/*
 * Updating in place can leave junk at the end of the file in some
 * circumstances (if it shrinks and the OS doesn't have a straightforward
 * way to truncate it).  The trailing junk is harmless and the code
 * which reads the scores will ignore it.
 */
#ifdef UPDATE_RECORD_IN_PLACE
static long final_fpos; /* [note: do not move this to the 'g' struct] */
#endif

#define done_stopprint program_state.stopprint

#define newttentry() (struct toptenentry *) alloc(sizeof (struct toptenentry))
#define dealloc_ttentry(ttent) free((genericptr_t) (ttent))
#ifndef NAMSZ
/* NAMSZ はハイスコアレコード (record ファイル) におけるプレイヤー名
   フィールドのバッファサイズ (バイト単位) である。NAMSZ_CHARS で指定
   された最大文字数 (UTF-8 文字) を格納できるだけのバイト数が必要で、
   最もバイト幅が大きい UTF-8 文字 (4 バイト絵文字等) でも
   NAMSZ_CHARS 文字分保持できるよう 4 * NAMSZ_CHARS としている。 */
#define NAMSZ 40
#endif
/* NAMSZ_CHARS はレコードに保存するプレイヤー名の最大 UTF-8 文字数。
   全角・半角・絵文字のいずれも 1 文字として数える。 */
#define NAMSZ_CHARS 10
#define DTHSZ 100
#define ROLESZ 3

struct toptenentry {
    struct toptenentry *tt_next;
#ifdef UPDATE_RECORD_IN_PLACE
    long fpos;
#endif
    long points;
    int deathdnum, deathlev;
    int maxlvl, hp, maxhp, deaths;
    int ver_major, ver_minor, patchlevel;
    long deathdate, birthdate;
    int uid;
    char plrole[ROLESZ + 1];
    char plrace[ROLESZ + 1];
    char plgend[ROLESZ + 1];
    char plalign[ROLESZ + 1];
    char name[NAMSZ + 1];
    char death[DTHSZ + 1];
};
static struct toptenentry *tt_head;
/* record ファイル 1 行分のヘッダー (バージョン番号、点数、ダンジョン番号、
   階層、HP、最大HP、死亡回数、日付、UID 等) の最大長を十分カバーする
   バッファ。1 行は "%d.%d.%d %ld %d %d %d %d %d %d %ld %ld %d " 形式の
   ヘッダー + 4 つの役割フィールド + 名前 + 死因 + 改行で構成され、値
   によっては理論上 130 バイト超となり得るため、80 バイト程度を確保して
   おくと典型ケースで fgets による行末欠落を避けられる。 */
#define TT_HDR_MAX 80
/* size big enough to read in all the string fields at once; includes
   room for separating space or trailing newline plus string terminator
   and the leading header fields (version/points/dungeon/level/...) */
#define SCANBUFSZ (TT_HDR_MAX + 4 * (ROLESZ + 1) + (NAMSZ + 1) + (DTHSZ + 1) + 1)

static struct toptenentry zerott;

staticfn void topten_print(const char *);
staticfn void topten_print_bold(const char *);
staticfn void outheader(void);
staticfn void outentry(int, struct toptenentry *, boolean);
staticfn void discardexcess(FILE *);
staticfn void readentry(FILE *, struct toptenentry *);
staticfn void writeentry(FILE *, struct toptenentry *);
#ifdef XLOGFILE
staticfn void writexlentry(FILE *, struct toptenentry *, int);
staticfn long encodexlogflags(void);
staticfn long encodeconduct(void);
staticfn long encodeachieve(boolean);
staticfn void add_achieveX(char *, const char *, boolean);
staticfn char *encode_extended_achievements(char *);
staticfn char *encode_extended_conducts(char *);
#endif
staticfn void free_ttlist(struct toptenentry *);
staticfn int classmon(char *);
staticfn int score_wanted(boolean, int, struct toptenentry *, int,
                        const char **, int);
staticfn int tt_gend_from_filecode(const char *);
staticfn const char *tt_role_name_from_filecode(const char *, const char *);
staticfn const char *tt_race_name_from_filecode(const char *);
staticfn const char *tt_gender_name_from_filecode(const char *);
staticfn const char *tt_align_name_from_filecode(const char *, const char *);
staticfn int topten_utf8_charlen(const char *);
staticfn int topten_dispwidth(const char *);
staticfn char *topten_wrapsplit(char *, int);
#ifdef NO_SCAN_BRACK
staticfn void nsb_mung_line(char *);
staticfn void nsb_unmung_line(char *);
#endif
staticfn const char *skip_english_article(const char *);
staticfn const char *jp_translate_multi_reason_exact(const char *, char *,
                                                     unsigned);
staticfn const char *jp_translate_multi_reason_for_display(const char *,
                                                           char *, unsigned);

/* "killed by",&c ["an"] 'svk.killer.name' */
void
formatkiller(
    char *buf,
    unsigned siz,
    int how,
    boolean incl_helpless)
{
    static NEARDATA const char *const killed_by_prefix[] = {
        /* DIED, CHOKING, POISONING, STARVING, */
        "killed by ", "choked on ", "poisoned by ", "died of ",
        /* DROWNING, BURNING, DISSOLVED, CRUSHING, */
        "drowned in ", "burned by ", "dissolved in ", "crushed to death by ",
        /* STONING, TURNED_SLIME, GENOCIDED, */
        "petrified by ", "turned to slime by ", "killed by ",
        /* PANICKED, TRICKED, QUIT, ESCAPED, ASCENDED */
        "", "", "", "", ""
    };
    unsigned l;
    char c, *kname = svk.killer.name;

    buf[0] = '\0'; /* lint suppression */
    switch (svk.killer.format) {
    default:
        impossible("bad killer format? (%d)", svk.killer.format);
        FALLTHROUGH;
        /*FALLTHRU*/
    case NO_KILLER_PREFIX:
        break;
    case KILLED_BY_AN:
        kname = an(kname);
        FALLTHROUGH;
        /*FALLTHRU*/
    case KILLED_BY:
        (void) strncat(buf, killed_by_prefix[how], siz - 1);
        l = Strlen(buf);
        buf += l, siz -= l;
        break;
    }
    /* Copy kname into buf[].
     * Object names and named fruit have already been sanitized, but
     * monsters can have "called 'arbitrary text'" attached to them,
     * so make sure that that text can't confuse field splitting when
     * record, logfile, or xlogfile is re-read at some later point.
     */
    while (--siz > 0) {
        c = *kname++;
        if (!c)
            break;
        else if (c == ',')
            c = ';';
        /* 'xlogfile' doesn't really need protection for '=', but
           fixrecord.awk for corrupted 3.6.0 'record' does (only
           if using xlogfile rather than logfile to repair record) */
        else if (c == '=')
            c = '_';
        /* tab is not possible due to use of mungspaces() when naming;
           it would disrupt xlogfile parsing if it were present */
        else if (c == '\t')
            c = ' ';
        *buf++ = c;
    }
    *buf = '\0';

    if (incl_helpless && gm.multi < 0) {
        /* X <= siz: 'sizeof "string"' includes 1 for '\0' terminator */
        if (gm.multi_reason
            && strlen(gm.multi_reason) + sizeof ", while " <= siz)
            Sprintf(buf, ", while %s", gm.multi_reason);
        /* either gm.multi_reason wasn't specified or wouldn't fit */
        else if (sizeof ", while helpless" <= siz)
            Strcpy(buf, ", while helpless");
        /* else extra death info won't fit, so leave it out */
    }
}

int
name_to_otyp(const char *name)
{
    int i;
    for (i = 0; i < NUM_OBJECTS; i++) {
        const char *objname = OBJ_NAME(objects[i]);
        if (objname && !strcmpi(name, objname)) {
            return i;
        }
    }
    return -1;
}
staticfn void
jp_translate_food_or_corpse(char *out, unsigned outsz, const char *in)
{
    char tmp[BUFSZ];
    char adj[BUFSZ];
    char noun[BUFSZ];
    const char *p;
    const char *q;

    out[0] = '\0';
    adj[0] = '\0';
    noun[0] = '\0';

    if (!in || !*in)
        return;

    Snprintf(tmp, sizeof tmp, "%s", in);
    p = skip_english_article(tmp);

    /* 形容詞の抽出 */
    if (!strncmpi(p, "rotted ", 7)) {
        Snprintf(adj, sizeof adj, "腐った");
        p += 7;
    } else if (!strncmpi(p, "rotten ", 7)) {
        Snprintf(adj, sizeof adj, "腐った");
        p += 7;
    } else if (!strncmpi(p, "stolen ", 7)) {
        Snprintf(adj, sizeof adj, "奪った");
        p += 7;
    } else if (!strncmpi(p, "acidic ", 7)) {
        Snprintf(adj, sizeof adj, "酸性の");
        p += 7;
    } else if (!strncmpi(p, "very rich ", 10)) {
        Snprintf(adj, sizeof adj, "豪華すぎる");
        p += 10;
    } else if (!strncmpi(p, "quick ", 6)) {
        Snprintf(adj, sizeof adj, "軽い");
        p += 6;
    }

    p = skip_english_article(p);

    /* 名詞の判定 */
    if ((q = strstr(p, " corpse")) != 0) {
        char mbuf[BUFSZ];
        size_t len = q - p;
        if (len < sizeof mbuf) {
            (void) memcpy(mbuf, p, len);
            mbuf[len] = '\0';
            const char *mname = skip_english_article(mbuf);
            int mndx, gend;
            mndx = name_to_mon(mname, &gend);
            if (mndx >= 0) {
                Snprintf(noun, sizeof noun, "%sの死体", jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(noun, sizeof noun, "%sの死体", mname);
            }
        }
    } else if ((q = strstr(p, " egg")) != 0) {
        char mbuf[BUFSZ];
        size_t len = q - p;
        if (len < sizeof mbuf) {
            (void) memcpy(mbuf, p, len);
            mbuf[len] = '\0';
            const char *mname = skip_english_article(mbuf);
            int mndx, gend;
            mndx = name_to_mon(mname, &gend);
            if (mndx >= 0) {
                Snprintf(noun, sizeof noun, "%sの卵", jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(noun, sizeof noun, "%sの卵", mname);
            }
        }
    } else if (!strncmpi(p, "statue of ", 10)) {
        const char *mname = skip_english_article(p + 10);
        int mndx, gend;
        mndx = name_to_mon(mname, &gend);
        if (mndx >= 0) {
            Snprintf(noun, sizeof noun, "%sの石像", jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(noun, sizeof noun, "%sの石像", mname);
        }
    } else if (!strncmpi(p, "body of ", 8)) {
        const char *mname = skip_english_article(p + 8);
        int mndx, gend;
        mndx = name_to_mon(mname, &gend);
        if (mndx >= 0) {
            Snprintf(noun, sizeof noun, "%sの体", jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(noun, sizeof noun, "%sの体", mname);
        }
    } else if (!strncmpi(p, "brain of ", 9)) {
        const char *mname = skip_english_article(p + 9);
        int mndx, gend;
        mndx = name_to_mon(mname, &gend);
        if (mndx >= 0) {
            Snprintf(noun, sizeof noun, "%sの脳", jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(noun, sizeof noun, "%sの脳", mname);
        }
    } else if (!strcmpi(p, "glob")) {
        Snprintf(noun, sizeof noun, "塊");
    } else if (!strcmpi(p, "lump of royal jelly")) {
        Snprintf(noun, sizeof noun, "ローヤルゼリー");
    } else if (!strcmpi(p, "meal")) {
        Snprintf(noun, sizeof noun, "食事");
    } else if (!strcmpi(p, "snack")) {
        Snprintf(noun, sizeof noun, "スナック");
    } else {
        int mndx, gend, otyp;
        mndx = name_to_mon(p, &gend);
        if (mndx >= 0) {
            Snprintf(noun, sizeof noun, "%s", jp_pmname_from_idx(mndx, 0));
        } else {
            otyp = name_to_otyp(p);
            if (otyp >= 0 && otyp < NUM_OBJECTS) {
                Snprintf(noun, sizeof noun, "%s", jp_item_name(otyp));
            } else {
                Snprintf(noun, sizeof noun, "%s", p);
            }
        }
    }

    if (*adj) {
        Snprintf(out, outsz, "%s%s", adj, noun);
    } else {
        Snprintf(out, outsz, "%s", noun);
    }
}

staticfn const char *
skip_english_article(const char *s)
{
    if (!s)
        return "";
    if (!strncmpi(s, "an ", 3))
        return s + 3;
    if (!strncmpi(s, "a ", 2))
        return s + 2;
    if (!strncmpi(s, "the ", 4))
        return s + 4;
    return s;
}

staticfn const char *
jp_translate_multi_reason_exact(
    const char *reason,
    char *out,
    unsigned outsz)
{
    static const struct {
        const char *reason;
        const char *jp;
    } reason_map[] = {
        { "dragging an iron ball", "鉄球を引きずっていた" },
        { "digesting something", "何かを消化していた" },
        { "gazing into a mirror", "鏡をのぞき込んでいた" },
        { "jumping around", "跳び回っていた" },
        { "stuck in a spider web", "蜘蛛の巣に絡まっていた" },
        { "disrobing", "服を脱いでいた" },
        { "dressing up", "着替えていた" },
        { "moving through the air", "空中を移動していた" },
        { "pretending to be a pile of gold", "金貨の山のふりをしていた" },
        { "feigning a pile of gold coins", "金貨の山のふりをしていた" },
        { "unconscious from rotten food", "腐った食べ物で意識を失っていた" },
        { "fainted from lack of food", "食料不足で気絶していた" },
        { "fainting from hunger", "飢えで気絶していた" },
        { "vomiting", "吐いていた" },
        { "opening a container", "容器を開けていた" },
        { "tipping a container", "容器を傾けていた" },
        { "looking into a magic 8-ball", "マジック8ボールを覗き込んでいた" },
        { "looking into a crystal ball", "水晶玉を覗き込んでいた" },
        { "toyed with by fate", "運命に翻弄されていた" },
        { "paralyzed by fear", "恐怖で身動きできなかった" },
        { "being scared stiff", "恐怖で身動きできなかった" },
        { "being frightened to death", "恐怖で死にかけていた" },
        { "sleeping off a magical draught", "魔法の薬で眠っていた" },
        { "reading a book", "本を読んでいた" },
        { "taking off clothes", "服を脱いでいた" },
        { "praying", "祈っていた" },
        { "trying to turn the monsters", "モンスターを退散させようとしていた" },
        { "being terrified of a demon", "悪魔におびえていた" },
        { "being terrified of a ghost", "幽霊におびえていた" },
        { "scared by rattling", "ガタガタいう音に驚いていた" },
        { "frozen by a potion", "ポーションで凍りついていた" },
        { "getting stoned", "石化していた" },
        { "fumbling", "もたついていた" },
        { "sleeping", "眠っていた" },
        { "hiding from thunderstorm", "雷雨を避けて隠れていた" },
        { "paralyzed by a monster", "モンスターに麻痺させられていた" },
        { "frozen by a monster's gaze", "モンスターの視線で凍りついていた" },
        { "frozen by a monster", "モンスターに凍りつかされていた" },
        { "exhaustion", "疲労困憊していた" },
        { "elementary physics", "物理法則に翻弄されていた" },
        { "brainlessness", "脳を失っていた" },
        { "starvation", "飢えに苦しんでいた" },
        { "system shock", "システムショック状態だった" },
        { "alchemic blast", "錬金術の爆発に巻き込まれていた" },
        { 0, 0 }
    };
    int i;

    for (i = 0; reason_map[i].reason; ++i) {
        if (!strcmpi(reason, reason_map[i].reason)) {
            Snprintf(out, outsz, "%s", reason_map[i].jp);
            return out;
        }
    }
    return NULL;
}

staticfn const char *
jp_translate_multi_reason_for_display(
    const char *reason,
    char *out,
    unsigned outsz)
{
    const char *who;

    if (!out || outsz == 0)
        return "";
    out[0] = '\0';
    if (!reason || !*reason)
        return out;

    if (jp_translate_multi_reason_exact(reason, out, outsz))
        return out;

    if (!strncmp(reason, "paralyzed by ", 13)) {
        int mndx, gend;
        who = skip_english_article(reason + 13);
        mndx = name_to_mon(who, &gend);
        if (mndx >= 0)
            Snprintf(out, outsz, "%sに麻痺させられていた", jp_pmname_from_idx(mndx, 0));
        else
            Snprintf(out, outsz, "%sに麻痺させられていた", who);
        return out;
    }
    if (!strncmp(reason, "frozen by ", 10)) {
        char who_buf[BUFSZ];
        size_t wholen;

        who = skip_english_article(reason + 10);
        wholen = strlen(who);
        if (wholen > 5 && !strcmp(who + wholen - 5, " gaze")) {
            size_t baselen = wholen - 5;

            if (baselen >= sizeof who_buf)
                baselen = sizeof who_buf - 1;
            (void) memcpy(who_buf, who, baselen);
            who_buf[baselen] = '\0';
            baselen = strlen(who_buf);
            if (baselen >= 2 && who_buf[baselen - 2] == '\''
                && who_buf[baselen - 1] == 's')
                who_buf[baselen - 2] = '\0';
            else if (baselen >= 1 && who_buf[baselen - 1] == '\'')
                who_buf[baselen - 1] = '\0';
            who = skip_english_article(who_buf);

            int mndx, gend;
            mndx = name_to_mon(who, &gend);
            if (mndx >= 0)
                Snprintf(out, outsz, "%sの視線で凍りついていた", jp_pmname_from_idx(mndx, 0));
            else
                Snprintf(out, outsz, "%sの視線で凍りついていた", who);
        } else {
            int mndx, gend;
            mndx = name_to_mon(who, &gend);
            if (mndx >= 0)
                Snprintf(out, outsz, "%sに凍りつかされていた", jp_pmname_from_idx(mndx, 0));
            else
                Snprintf(out, outsz, "%sに凍りつかされていた", who);
        }
        return out;
    }

    Snprintf(out, outsz, "%s", reason);
    return out;
}

staticfn const char *
jp_translate_killer_name_or_monster(const char *in, char *out, unsigned outsz)
{
    char tmp[BUFSZ];
    const char *p;
    int mndx, gend, otyp, artinum;

    if (!out || outsz == 0)
        return "";
    out[0] = '\0';
    if (!in || !*in)
        return out;

    p = skip_english_article(in);
    Snprintf(tmp, sizeof tmp, "%s", p);

    artinum = jp_artiname_to_num(tmp);
    if (artinum > 0) {
        Snprintf(out, outsz, "%s", jp_artiname(artinum));
        return out;
    }

    mndx = name_to_mon(tmp, &gend);
    if (mndx >= LOW_PM && mndx < NUMMONS) {
        Snprintf(out, outsz, "%s", jp_pmname_from_idx(mndx, 0));
        return out;
    }

    otyp = name_to_otyp(tmp);
    if (otyp >= 0 && otyp < NUM_OBJECTS) {
        Snprintf(out, outsz, "%s", jp_item_name(otyp));
        return out;
    }

    /* 修飾語・名詞句の動的パース */
    if (!strncmpi(tmp, "ghost of ", 9)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 9, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "%sの幽霊", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "shade of ", 9)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 9, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "%sの影", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "zombie of ", 10)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 10, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "%sのゾンビ", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "mummy of ", 9)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 9, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "%sのマミー", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "skeleton of ", 12)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 12, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "%sのスケルトン", nbuf);
        return out;
    }

    if (strstr(tmp, "'s ghost") || strstr(tmp, "'s shade")) {
        char gbuf[BUFSZ];
        const char *gp = strstr(tmp, "'s ");
        size_t glen = gp - tmp;
        if (glen < sizeof gbuf) {
            memcpy(gbuf, tmp, glen);
            gbuf[glen] = '\0';
            char nbuf[BUFSZ];
            jp_translate_killer_name_or_monster(gbuf, nbuf, sizeof nbuf);
            if (strstr(tmp, "ghost"))
                Snprintf(out, outsz, "%sの幽霊", nbuf);
            else
                Snprintf(out, outsz, "%sの影", nbuf);
            return out;
        }
    }

    if (!strncmpi(tmp, "hallucinatory ", 14)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 14, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "幻覚の%s", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "invisible ", 10)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 10, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "不可視の%s", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "displaced ", 10)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 10, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "位置のずれた%s", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "tame ", 5)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 5, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "ペットの%s", nbuf);
        return out;
    }
    if (!strncmpi(tmp, "peaceful ", 9)) {
        char nbuf[BUFSZ];
        jp_translate_killer_name_or_monster(tmp + 9, nbuf, sizeof nbuf);
        Snprintf(out, outsz, "大人しい%s", nbuf);
        return out;
    }

    /* 末尾サフィックスパターン */
    size_t tlen = strlen(tmp);
    if (tlen > 7 && !strcmpi(tmp + tlen - 7, " zombie")) {
        char base[BUFSZ];
        size_t blen = tlen - 7;
        if (blen < sizeof base) {
            memcpy(base, tmp, blen);
            base[blen] = '\0';
            char nbuf[BUFSZ];
            jp_translate_killer_name_or_monster(base, nbuf, sizeof nbuf);
            Snprintf(out, outsz, "%sのゾンビ", nbuf);
            return out;
        }
    }
    if (tlen > 6 && !strcmpi(tmp + tlen - 6, " mummy")) {
        char base[BUFSZ];
        size_t blen = tlen - 6;
        if (blen < sizeof base) {
            memcpy(base, tmp, blen);
            base[blen] = '\0';
            char nbuf[BUFSZ];
            jp_translate_killer_name_or_monster(base, nbuf, sizeof nbuf);
            Snprintf(out, outsz, "%sのマミー", nbuf);
            return out;
        }
    }
    if (tlen > 9 && !strcmpi(tmp + tlen - 9, " skeleton")) {
        char base[BUFSZ];
        size_t blen = tlen - 9;
        if (blen < sizeof base) {
            memcpy(base, tmp, blen);
            base[blen] = '\0';
            char nbuf[BUFSZ];
            jp_translate_killer_name_or_monster(base, nbuf, sizeof nbuf);
            Snprintf(out, outsz, "%sのスケルトン", nbuf);
            return out;
        }
    }

    /* 死体・卵・石像などの名詞句 */
    if (strstr(tmp, " corpse") || strstr(tmp, " egg") || !strncmpi(tmp, "statue of ", 10) || !strncmpi(tmp, "body of ", 8)) {
        jp_translate_food_or_corpse(out, outsz, tmp);
        if (*out)
            return out;
    }

    Snprintf(out, outsz, "%s", tmp);
    return out;
}

void
jp_translate_killer_text_for_display(
    char *out,
    unsigned outsz,
    const char *in)
{
    char tmp[BUFSZ], outmain[BUFSZ], whilebuf[BUFSZ];
    char wieldingbuf[BUFSZ];
    char *whilep;
    char *wieldingp;
    const char *core;

    if (!out || outsz == 0)
        return;

    if (!g_language_is_jp) {
        Snprintf(out, outsz, "%s", in ? in : "");
        return;
    }

    out[0] = '\0';
    Snprintf(tmp, sizeof tmp, "%s", in ? in : "");
    whilebuf[0] = '\0';
    wieldingbuf[0] = '\0';

    wieldingp = strstr(tmp, " while wielding ");
    if (wieldingp) {
        Snprintf(wieldingbuf, sizeof wieldingbuf, "%s", wieldingp + 16);
        *wieldingp = '\0';
    }

    whilep = strstr(tmp, ", while ");
    if (whilep) {
        Snprintf(whilebuf, sizeof whilebuf, "%s", whilep + 8);
        *whilep = '\0';
    }

    core = tmp;
    outmain[0] = '\0';
    if (!strncmpi(core, "caught in a ", 12)) {
        char expbuf[BUFSZ];
        const char *jpexp = jp_explosion_text_for_display(core + 12, expbuf, sizeof expbuf);
        Snprintf(outmain, sizeof outmain, "%sに巻き込まれた", jpexp);
    } else if (!strncmpi(core, "caught in own ", 14)) {
        char expbuf[BUFSZ];
        const char *jpexp = jp_explosion_text_for_display(core + 14, expbuf, sizeof expbuf);
        Snprintf(outmain, sizeof outmain, "自分の%sに巻き込まれた", jpexp);
    } else if (!strncmpi(core, "caught in ", 10)) {
        char expbuf[BUFSZ];
        const char *jpexp = jp_explosion_text_for_display(core + 10, expbuf, sizeof expbuf);
        Snprintf(outmain, sizeof outmain, "%sに巻き込まれた", jpexp);
    } else if (!strcmpi(core, "crushed to death underneath a drawbridge")) {
        Snprintf(outmain, sizeof outmain, "跳ね橋の下敷きになった");
    } else if (!strcmpi(core, "fell from a drawbridge")) {
        Snprintf(outmain, sizeof outmain, "跳ね橋から落ちた");
    } else if (!strncmpi(core, "killed by ", 10)) {
        const char *killer = skip_english_article(core + 10);

        if (!strcmpi(killer, "falling drawbridge")) {
            Snprintf(outmain, sizeof outmain, "落下した跳ね橋に倒された");
        } else if (!strcmpi(killer, "closing drawbridge")) {
            Snprintf(outmain, sizeof outmain, "閉じる跳ね橋に倒された");
        } else if (!strcmpi(killer, "exploding drawbridge")) {
            Snprintf(outmain, sizeof outmain, "爆発する跳ね橋に倒された");
        } else if (!strcmpi(killer, "collapsing drawbridge")) {
            Snprintf(outmain, sizeof outmain, "崩れ落ちる跳ね橋に倒された");
        } else if (!strcmpi(killer, "life drainage")) {
            Snprintf(outmain, sizeof outmain, "生命力吸収で倒された");
        } else if (!strcmpi(killer, "gas cloud")) {
            Snprintf(outmain, sizeof outmain, "毒ガスの雲に倒された");
        } else if (!strcmpi(killer, "wand")) {
            Snprintf(outmain, sizeof outmain, "魔法の杖に倒された");
        } else if (!strcmpi(killer, "scroll of fire")) {
            Snprintf(outmain, sizeof outmain, "火炎の巻物に倒された");
        } else if (!strcmpi(killer, "potion of acid")) {
            Snprintf(outmain, sizeof outmain, "酸の薬に倒された");
        } else if (!strcmpi(killer, "potion of holy water")) {
            Snprintf(outmain, sizeof outmain, "聖水に倒された");
        } else if (!strcmpi(killer, "potion of unholy water")) {
            Snprintf(outmain, sizeof outmain, "不浄な水に倒された");
        } else if (!strcmpi(killer, "potion of poison")) {
            Snprintf(outmain, sizeof outmain, "毒薬に倒された");
        } else if (!strcmpi(killer, "potion of polymorph")) {
            Snprintf(outmain, sizeof outmain, "へんげの薬に倒された");
        } else if (!strcmpi(killer, "scroll of genocide")) {
            Snprintf(outmain, sizeof outmain, "虐殺の巻物に倒された");
        } else if (!strcmpi(killer, "elementary physics")) {
            Snprintf(outmain, sizeof outmain, "物理法則に倒された");
        } else if (!strcmpi(killer, "colliding with the ceiling")) {
            Snprintf(outmain, sizeof outmain, "天井への激突で倒された");
        } else if (!strcmpi(killer, "splash of acid")) {
            Snprintf(outmain, sizeof outmain, "酸の飛沫に倒された");
        } else if (!strcmpi(killer, "death field")) {
            Snprintf(outmain, sizeof outmain, "死の領域に倒された");
        } else if (!strcmpi(killer, "disintegration field")) {
            Snprintf(outmain, sizeof outmain, "分解領域に倒された");
        } else if (!strcmpi(killer, "falling rock")) {
            Snprintf(outmain, sizeof outmain, "落石に倒された");
        } else if (!strcmpi(killer, "falling object")) {
            Snprintf(outmain, sizeof outmain, "落下物に倒された");
        } else if (!strcmpi(killer, "grappling hook")) {
            Snprintf(outmain, sizeof outmain, "グラップリングフックに倒された");
        } else if (!strcmpi(killer, "exploding wand")) {
            Snprintf(outmain, sizeof outmain, "杖の爆発で倒された");
        } else if (!strcmpi(killer, "exploding ring")) {
            Snprintf(outmain, sizeof outmain, "指輪の爆発で倒された");
        } else if (!strcmpi(killer, "exploding rune")) {
            Snprintf(outmain, sizeof outmain, "ルーンの爆発で倒された");
        } else if (!strcmpi(killer, "residual undead turning effect")) {
            Snprintf(outmain, sizeof outmain, "アンデッド退散の残留効果に倒された");
        } else if (!strcmpi(killer, "system shock")) {
            Snprintf(outmain, sizeof outmain, "システムショックで倒された");
        } else if (!strcmpi(killer, "psychic blast")) {
            Snprintf(outmain, sizeof outmain, "精神波の爆発に倒された");
        } else if (!strcmpi(killer, "exhaustion")) {
            Snprintf(outmain, sizeof outmain, "過労で倒された");
        } else if (!strcmpi(killer, "cloud of poison gas")) {
            Snprintf(outmain, sizeof outmain, "毒ガスの雲に倒された");
        } else if (!strcmpi(killer, "jumping out of a bear trap")) {
            Snprintf(outmain, sizeof outmain, "熊罠からの脱出で倒された");
        } else if (!strcmpi(killer, "crunched in the head by an iron ball")) {
            Snprintf(outmain, sizeof outmain, "鉄球に頭を打ち砕かれた");
        } else if (!strcmpi(killer, "iron ball collision")) {
            Snprintf(outmain, sizeof outmain, "鉄球との衝突で倒された");
        } else if (!strcmpi(killer, "exploding crystal ball")) {
            Snprintf(outmain, sizeof outmain, "水晶玉の爆発で倒された");
        } else if (!strcmpi(killer, "axing a hard object")) {
            Snprintf(outmain, sizeof outmain, "硬いものを斧で叩いたこと");
        } else if (!strcmpi(killer, "falling down a mine shaft")) {
            Snprintf(outmain, sizeof outmain, "坑道への落下で倒された");
        } else if (!strcmpi(killer, "unrefrigerated sip of juice")) {
            Snprintf(outmain, sizeof outmain, "冷やされていない果汁をすすったこと");
        } else if (!strcmpi(killer, "sipping boiling water")) {
            Snprintf(outmain, sizeof outmain, "煮えたぎる湯をすすったこと");
        } else if (!strcmpi(killer, "carnivorous bag")) {
            Snprintf(outmain, sizeof outmain, "肉食の袋に倒された");
        } else if (!strcmpi(killer, "magical explosion")) {
            Snprintf(outmain, sizeof outmain, "魔法の爆発に倒された");
        } else if (!strcmpi(killer, "arrow")) {
            Snprintf(outmain, sizeof outmain, "矢に倒された");
        } else if (!strcmpi(killer, "little dart") || !strcmpi(killer, "dart")) {
            Snprintf(outmain, sizeof outmain, "吹き矢に倒された");
        } else if (!strcmpi(killer, "poisoned needle") || !strcmpi(killer, "needle")) {
            Snprintf(outmain, sizeof outmain, "毒針に刺されて倒された");
        } else if (!strcmpi(killer, "land mine")) {
            Snprintf(outmain, sizeof outmain, "地雷の爆発で倒された");
        } else if (!strcmpi(killer, "electric shock")) {
            Snprintf(outmain, sizeof outmain, "電撃で倒された");
        } else if (!strcmpi(killer, "bear trap")) {
            Snprintf(outmain, sizeof outmain, "熊罠で倒された");
        } else if (!strcmpi(killer, "rolling boulder trap")) {
            Snprintf(outmain, sizeof outmain, "転がる大岩の罠に倒された");
        } else if (!strcmpi(killer, "statue trap")) {
            Snprintf(outmain, sizeof outmain, "石像の罠に倒された");
        } else if (!strcmpi(killer, "spiked pit")) {
            Snprintf(outmain, sizeof outmain, "杭のある落とし穴に落ちて倒された");
        } else if (!strcmpi(killer, "pit")) {
            Snprintf(outmain, sizeof outmain, "落とし穴に落ちて倒された");
        } else if (!strcmpi(killer, "fire trap")) {
            Snprintf(outmain, sizeof outmain, "火の罠で焼死した");
        } else if (!strcmpi(killer, "magic trap")) {
            Snprintf(outmain, sizeof outmain, "魔法の罠に倒された");
        } else if (!strcmpi(killer, "anti-magic trap")) {
            Snprintf(outmain, sizeof outmain, "反魔法の罠に倒された");
        } else if (!strcmpi(killer, "polymorph trap")) {
            Snprintf(outmain, sizeof outmain, "へんげの罠に倒された");
        } else if (!strcmpi(killer, "rusting away")) {
            Snprintf(outmain, sizeof outmain, "錆び崩れて倒された");
        } else if (!strcmpi(killer, "dangerous winds")) {
            Snprintf(outmain, sizeof outmain, "危険な突風で倒された");
        } else if (!strcmpi(killer, "strangulation")) {
            Snprintf(outmain, sizeof outmain, "首を絞められて倒された");
        } else if (!strcmpi(killer, "suffocation")) {
            Snprintf(outmain, sizeof outmain, "窒息して倒された");
        } else if (!strcmpi(killer, "slimicide")) {
            Snprintf(outmain, sizeof outmain, "スライム化による死");
        } else if (!strncmpi(killer, "riding ", 7)) {
            const char *mname = skip_english_article(killer + 7);
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", mname);
            int mndx, gend;
            mndx = name_to_mon(mbuf, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "%sに騎乗中に石化した",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "%sに騎乗中に石化した", mbuf);
            }
        } else if (!strncmpi(killer, "falling off ", 12)) {
            const char *mname = skip_english_article(killer + 12);
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", mname);
            int mndx, gend;
            mndx = name_to_mon(mbuf, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "%sから落馬したことで石化した",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "%sから落馬したことで石化した", mbuf);
            }
        } else if (!strncmpi(killer, "trying to saddle ", 17)) {
            const char *mname = skip_english_article(killer + 17);
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", mname);
            int mndx, gend;
            mndx = name_to_mon(mbuf, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "%sに鞍を付けようとして石化した",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "%sに鞍を付けようとして石化した", mbuf);
            }
        } else if (!strncmpi(killer, "trying to mount ", 16)) {
            const char *mname = skip_english_article(killer + 16);
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", mname);
            int mndx, gend;
            mndx = name_to_mon(mbuf, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "%sに乗ろうとして石化した",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "%sに乗ろうとして石化した", mbuf);
            }
        } else if (!strncmpi(killer, "trying to tin ", 14) && strstr(killer, " without gloves")) {
            const char *mname = skip_english_article(killer + 14);
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", mname);
            char *p = strstr(mbuf, " corpse");
            if (p) *p = '\0';
            int mndx, gend;
            mndx = name_to_mon(mbuf, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "手袋なしで%sを缶詰にしようとして石化した",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "手袋なしで%sを缶詰にしようとして石化した", mbuf);
            }
        } else if (!strncmpi(killer, "snatching ", 10)) {
            const char *what = skip_english_article(killer + 10);
            char buf[BUFSZ];
            Snprintf(buf, sizeof buf, "%s", what);
            if (strstr(buf, " corpse")) {
                char *p = strstr(buf, " corpse");
                if (p) *p = '\0';
                const char *mname = skip_english_article(buf);
                int mndx, gend;
                mndx = name_to_mon(mname, &gend);
                if (mndx >= 0) {
                    Snprintf(outmain, sizeof outmain, "%sの死体をひったくろうとして石化した",
                             jp_pmname_from_idx(mndx, 0));
                } else {
                    Snprintf(outmain, sizeof outmain, "%sの死体をひったくろうとして石化した", mname);
                }
            } else {
                int otyp = name_to_otyp(buf);
                if (otyp >= 0 && otyp < NUM_OBJECTS) {
                    Snprintf(outmain, sizeof outmain, "%sをひったくろうとして石化した", jp_item_name(otyp));
                } else {
                    Snprintf(outmain, sizeof outmain, "%sをひったくろうとして石化した", buf);
                }
            }
        } else if (!strncmpi(killer, "inflicted by ", 13)) {
            const char *p = killer + 13;
            char what[BUFSZ];
            char mon[BUFSZ];
            what[0] = '\0';
            mon[0] = '\0';
            const char *ofp = strstr(p, " of ");
            if (ofp) {
                size_t wlen = ofp - p;
                if (wlen < sizeof what) {
                    memcpy(what, p, wlen);
                    what[wlen] = '\0';
                }
                const char *mname = skip_english_article(ofp + 4);
                int mndx, gend;
                mndx = name_to_mon(mname, &gend);
                if (mndx >= 0) {
                    Snprintf(mon, sizeof mon, "%s", jp_pmname_from_idx(mndx, 0));
                } else {
                    Snprintf(mon, sizeof mon, "%s", mname);
                }
            } else {
                Snprintf(what, sizeof what, "%s", p);
            }
            char whatjp[BUFSZ];
            if (!strcmpi(what, "the touch of death")) {
                Snprintf(whatjp, sizeof whatjp, "死の手");
            } else if (!strcmpi(what, "strength loss")) {
                Snprintf(whatjp, sizeof whatjp, "力不足");
            } else {
                Snprintf(whatjp, sizeof whatjp, "%s", what);
            }
            if (*mon) {
                Snprintf(outmain, sizeof outmain, "%sの%sによって倒された", mon, whatjp);
            } else {
                Snprintf(outmain, sizeof outmain, "%sによって倒された", whatjp);
            }
        } else {
            char kbuf[BUFSZ];
            jp_translate_killer_name_or_monster(killer, kbuf, sizeof kbuf);

            char *p;
            if ((p = strstr(kbuf, "に触れたこと")) != 0 && p[12] == '\0') {
                /* 「～に触れたことに倒された」を「～に触れたことで倒された」に改善 */
                Snprintf(outmain, sizeof outmain, "%sで倒された", kbuf);
            } else if (strstr(kbuf, "倒された") || strstr(kbuf, "石化した") || strstr(kbuf, "死んだ") || strstr(kbuf, "失敗")) {
                Snprintf(outmain, sizeof outmain, "%s", kbuf);
            } else {
                Snprintf(outmain, sizeof outmain, "%sに倒された", kbuf);
            }
        }
    } else if (!strncmpi(core, "whipping ", 9)) {
        Snprintf(outmain, sizeof outmain, "むちで自分を打って死んだ");
    } else if (!strncmpi(core, "choked on ", 10)) {
        const char *what = skip_english_article(core + 10);
        char buf[BUFSZ];
        jp_translate_food_or_corpse(buf, sizeof buf, what);
        Snprintf(outmain, sizeof outmain, "%sで窒息した", buf);
    } else if (!strncmpi(core, "poisoned by ", 12)) {
        const char *what = skip_english_article(core + 12);
        char buf[BUFSZ];
        jp_translate_food_or_corpse(buf, sizeof buf, what);
        Snprintf(outmain, sizeof outmain, "%sで毒に侵された", buf);
    } else if (!strncmpi(core, "died of ", 8)) {
        Snprintf(outmain, sizeof outmain, "%sで死亡した",
                 skip_english_article(core + 8));
    } else if (!strncmpi(core, "unwisely drank from ", 20)) {
        const char *what = skip_english_article(core + 20);
        const char *place_jp = "水場";
        if (!strcmpi(what, "fountain")) place_jp = "泉";
        else if (!strcmpi(what, "pool of water") || !strcmpi(what, "pool")) place_jp = "水たまり";
        else if (!strcmpi(what, "moat")) place_jp = "堀";
        else if (!strcmpi(what, "swamp")) place_jp = "沼";
        else if (!strcmpi(what, "river")) place_jp = "川";
        else if (!strcmpi(what, "lake")) place_jp = "湖";
        else if (!strcmpi(what, "water")) place_jp = "水";
        Snprintf(outmain, sizeof outmain, "%sから飲んだ不心得", place_jp);
    } else if (!strncmpi(core, "drowned in ", 11)) {
        const char *what = skip_english_article(core + 11);
        const char *by_ptr = strstr(what, " by ");
        if (by_ptr) {
            char place[BUFSZ];
            char monster_eng[BUFSZ];
            char monster_jp[BUFSZ];
            size_t place_len = by_ptr - what;
            if (place_len < sizeof place) {
                (void) memcpy(place, what, place_len);
                place[place_len] = '\0';
            } else {
                Strcpy(place, "");
            }
            Strcpy(monster_eng, by_ptr + 4);
            jp_translate_food_or_corpse(monster_jp, sizeof monster_jp, monster_eng);

            const char *place_jp = "水";
            if (!strcmpi(place, "moat")) place_jp = "堀";
            else if (!strcmpi(place, "pool of water") || !strcmpi(place, "pool")) place_jp = "水たまり";
            else if (!strcmpi(place, "deep water")) place_jp = "深い水";
            else if (!strcmpi(place, "limitless water")) place_jp = "果てしない水";
            else if (!strcmpi(place, "swamp")) place_jp = "沼";
            else if (!strcmpi(place, "bog")) place_jp = "湿地";
            else if (!strcmpi(place, "river")) place_jp = "川";
            else if (!strcmpi(place, "lake")) place_jp = "湖";
            else if (!strcmpi(place, "sea") || !strcmpi(place, "ocean")) place_jp = "海";
            else if (!strcmpi(place, "fountain")) place_jp = "泉";
            else if (!strcmpi(place, "water")) place_jp = "水";

            Snprintf(outmain, sizeof outmain, "%sで%sに溺れさせられた", place_jp, monster_jp);
        } else {
            const char *place_jp = NULL;
            if (!strcmpi(what, "moat")) place_jp = "堀";
            else if (!strcmpi(what, "pool of water") || !strcmpi(what, "pool")) place_jp = "水たまり";
            else if (!strcmpi(what, "deep water")) place_jp = "深い水";
            else if (!strcmpi(what, "limitless water")) place_jp = "果てしない水";
            else if (!strcmpi(what, "swamp")) place_jp = "沼";
            else if (!strcmpi(what, "bog")) place_jp = "湿地";
            else if (!strcmpi(what, "river")) place_jp = "川";
            else if (!strcmpi(what, "lake")) place_jp = "湖";
            else if (!strcmpi(what, "sea") || !strcmpi(what, "ocean")) place_jp = "海";
            else if (!strcmpi(what, "fountain")) place_jp = "泉";
            else if (!strcmpi(what, "water")) place_jp = "水";

            if (place_jp) {
                Snprintf(outmain, sizeof outmain, "%sで溺死した", place_jp);
            } else {
                char fbuf[BUFSZ];
                jp_translate_food_or_corpse(fbuf, sizeof fbuf, what);
                Snprintf(outmain, sizeof outmain, "%sで溺死した", fbuf);
            }
        }
    } else if (!strncmpi(core, "burned by ", 10)) {
        const char *what = skip_english_article(core + 10);
        char buf[BUFSZ];
        Snprintf(buf, sizeof buf, "%s", what);
        int mndx, gend, otyp;
        if (!strcmpi(buf, "lava") || !strcmpi(buf, "molten lava")) {
            Snprintf(outmain, sizeof outmain, "溶岩で焼死した");
        } else if ((mndx = name_to_mon(buf, &gend)) >= 0) {
            Snprintf(outmain, sizeof outmain, "%sで焼死した",
                     jp_pmname_from_idx(mndx, 0));
        } else {
            otyp = name_to_otyp(buf);
            if (otyp >= 0 && otyp < NUM_OBJECTS) {
                Snprintf(outmain, sizeof outmain, "%sで焼死した", jp_item_name(otyp));
            } else {
                Snprintf(outmain, sizeof outmain, "%sで焼死した", buf);
            }
        }
    } else if (!strncmpi(core, "dissolved in ", 13)) {
        const char *what = skip_english_article(core + 13);
        if (!strcmpi(what, "lava") || !strcmpi(what, "molten lava")) {
            Snprintf(outmain, sizeof outmain, "溶岩で溶けた");
        } else {
            Snprintf(outmain, sizeof outmain, "%sで溶けた", what);
        }
    } else if (!strncmpi(core, "crushed to death by ", 20)) {
        const char *what = skip_english_article(core + 20);
        char buf[BUFSZ];
        Snprintf(buf, sizeof buf, "%s", what);
        int mndx, gend, otyp;
        mndx = name_to_mon(buf, &gend);
        if (mndx >= 0) {
            Snprintf(outmain, sizeof outmain, "%sに押しつぶされた",
                     jp_pmname_from_idx(mndx, 0));
        } else {
            otyp = name_to_otyp(buf);
            if (otyp >= 0 && otyp < NUM_OBJECTS) {
                Snprintf(outmain, sizeof outmain, "%sに押しつぶされた", jp_item_name(otyp));
            } else {
                Snprintf(outmain, sizeof outmain, "%sに押しつぶされた", buf);
            }
        }
    } else if (!strncmpi(core, "petrified by ", 13)) {
        const char *what = skip_english_article(core + 13);
        char buf[BUFSZ];
        Snprintf(buf, sizeof buf, "%s", what);
        if (!strncmp(what, "tripping over ", 14)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 14);
            Snprintf(outmain, sizeof outmain, "%sにつまずいたことで石化した", fbuf);
        } else if (!strncmp(what, "kicking ", 8) && strstr(what, " barefoot")) {
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", what + 8);
            char *p = strstr(mbuf, " barefoot");
            if (p) *p = '\0';
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, mbuf);
            Snprintf(outmain, sizeof outmain, "%sを素手で蹴ったことで石化した", fbuf);
        } else if (!strncmp(what, "throwing ", 9) && strstr(what, " bare-handed")) {
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", what + 9);
            char *p = strstr(mbuf, " bare-handed");
            if (p) *p = '\0';
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, mbuf);
            Snprintf(outmain, sizeof outmain, "%sを素手で投げたことで石化した", fbuf);
        } else if (!strncmp(what, "wielding ", 9) && strstr(what, " bare-handed")) {
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", what + 9);
            char *p = strstr(mbuf, " bare-handed");
            if (p) *p = '\0';
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, mbuf);
            Snprintf(outmain, sizeof outmain, "素手で%sを装備したことで石化した", fbuf);
        } else if (!strncmp(what, "bumping into ", 13)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 13);
            Snprintf(outmain, sizeof outmain, "%sにぶつかったことで石化した", fbuf);
        } else if (!strncmp(what, "being hit by ", 13)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 13);
            Snprintf(outmain, sizeof outmain, "%sに当たったことで石化した", fbuf);
        } else if (!strncmp(what, "attempting to saddle ", 21)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 21);
            Snprintf(outmain, sizeof outmain, "%sに鞍を付けようとして石化した", fbuf);
        } else if (!strncmp(what, "attempting to ride ", 19)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 19);
            Snprintf(outmain, sizeof outmain, "%sに乗ろうとして石化した", fbuf);
        } else if (!strncmp(what, "swallowing ", 11) && strstr(what, " whole")) {
            char mbuf[BUFSZ];
            Snprintf(mbuf, sizeof mbuf, "%s", what + 11);
            char *p = strstr(mbuf, " whole");
            if (p) *p = '\0';
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, mbuf);
            Snprintf(outmain, sizeof outmain, "%sを丸のみして石化した", fbuf);
        } else if (!strncmp(what, "engulfing ", 10)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 10);
            Snprintf(outmain, sizeof outmain, "%sを包み込んで石化した", fbuf);
        } else if (!strncmp(what, "enclosing ", 10)) {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what + 10);
            Snprintf(outmain, sizeof outmain, "%sを閉じ込めて石化した", fbuf);
        } else {
            char fbuf[BUFSZ];
            jp_translate_food_or_corpse(fbuf, sizeof fbuf, what);
            Snprintf(outmain, sizeof outmain, "%sで石化した", fbuf);
        }
    } else if (!strncmpi(core, "turned to slime by ", 19)) {
        const char *what = skip_english_article(core + 19);
        char buf[BUFSZ];
        Snprintf(buf, sizeof buf, "%s", what);
        int mndx, gend;
        mndx = name_to_mon(buf, &gend);
        if (mndx >= 0) {
            Snprintf(outmain, sizeof outmain, "%sでスライム化した",
                     jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(outmain, sizeof outmain, "%sでスライム化した", buf);
        }
    } else if (!strncmpi(core, "reverting to unhealthy ", 23)
               && strstr(core, " form")) {
        char rbuf[BUFSZ];
        const char *p = strstr(core, " form");
        size_t rlen = p - (core + 23);
        if (rlen < sizeof rbuf) {
            memcpy(rbuf, core + 23, rlen);
            rbuf[rlen] = '\0';
            const char *rname = skip_english_article(rbuf);
            int mndx, gend;
            mndx = name_to_mon(rname, &gend);
            if (mndx >= LOW_PM && mndx < NUMMONS) {
                Snprintf(outmain, sizeof outmain, "不健康な%sの姿に戻って倒れた",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "不健康な姿に戻って倒れた");
            }
        } else {
            Snprintf(outmain, sizeof outmain, "不健康な姿に戻って倒れた");
        }
    } else if (!strcmpi(core, "reverting to unhealthy human form")
               || !strcmpi(core, "reverting to unhealthy elf form")
               || !strcmpi(core, "reverting to unhealthy dwarf form")
               || !strcmpi(core, "reverting to unhealthy gnome form")
               || !strcmpi(core, "reverting to unhealthy orc form")) {
        Snprintf(outmain, sizeof outmain, "不健康な姿に戻って倒れた");
    } else if (!strcmpi(core, "killed while stuck in creature form")) {
        Snprintf(outmain, sizeof outmain, "怪物の姿から戻れずに倒れた");
    } else if (!strcmpi(core, "unsuccessful polymorph")) {
        Snprintf(outmain, sizeof outmain, "へんげの失敗で倒された");
    } else if (!strcmpi(core, "self-genocide")) {
        Snprintf(outmain, sizeof outmain, "自分自身の虐殺");
    } else if (!strcmpi(core, "system shock")) {
        Snprintf(outmain, sizeof outmain, "システムショック");
    } else if (!strcmpi(core, "alchemic blast")) {
        Snprintf(outmain, sizeof outmain, "錬金術の爆発");
    } else if (!strcmpi(core, "exhaustion")) {
        Snprintf(outmain, sizeof outmain, "過労死");
    } else if (!strcmpi(core, "starvation")) {
        Snprintf(outmain, sizeof outmain, "餓死");
    } else if (!strcmpi(core, "brainlessness")) {
        Snprintf(outmain, sizeof outmain, "脳を失ったこと");
    } else if (!strcmpi(core, "elementary physics")) {
        Snprintf(outmain, sizeof outmain, "物理法則");
    } else if (!strcmpi(core, "psychic blast")) {
        Snprintf(outmain, sizeof outmain, "精神波の爆発");
    } else if (!strcmpi(core, "gas cloud")) {
        Snprintf(outmain, sizeof outmain, "毒ガスの雲");
    } else if (!strcmpi(core, "falling rock")) {
        Snprintf(outmain, sizeof outmain, "落石");
    } else if (!strcmpi(core, "falling object")) {
        Snprintf(outmain, sizeof outmain, "落下物");
    } else if (!strcmpi(core, "colliding with the ceiling")) {
        Snprintf(outmain, sizeof outmain, "天井への激突");
    } else if (!strcmpi(core, "a grappling hook")) {
        Snprintf(outmain, sizeof outmain, "グラップリングフック");
    } else if (!strcmpi(core, "jumping out of a bear trap")) {
        Snprintf(outmain, sizeof outmain, "熊罠からの脱出失敗");
    } else if (!strcmpi(core, "sitting in lava")) {
        Snprintf(outmain, sizeof outmain, "溶岩に座ったこと");
    } else if (!strcmpi(core, "cursed throne")) {
        Snprintf(outmain, sizeof outmain, "呪われた玉座");
    } else if (!strcmpi(core, "electric chair")) {
        Snprintf(outmain, sizeof outmain, "電気椅子");
    } else if (!strcmpi(core, "acidic chair")) {
        Snprintf(outmain, sizeof outmain, "酸の椅子");
    } else if (!strcmpi(core, "acidic corpse")) {
        Snprintf(outmain, sizeof outmain, "酸性の死体");
    } else if (!strcmpi(core, "acidic glob")) {
        Snprintf(outmain, sizeof outmain, "酸性の塊");
    } else if (!strcmpi(core, "cadaver")) {
        Snprintf(outmain, sizeof outmain, "腐った死体");
    } else if (!strcmpi(core, "rotted glob")) {
        Snprintf(outmain, sizeof outmain, "腐った塊");
    } else if (!strcmpi(core, "rotten lump of royal jelly")) {
        Snprintf(outmain, sizeof outmain, "腐ったローヤルゼリー");
    } else if (!strcmpi(core, "very rich meal")) {
        Snprintf(outmain, sizeof outmain, "豪華すぎる食事");
    } else if (!strcmpi(core, "quick snack")) {
        Snprintf(outmain, sizeof outmain, "軽いスナック");
    } else if (!strcmpi(core, "axing a hard object")) {
        Snprintf(outmain, sizeof outmain, "硬いものを斧で叩いたこと");
    } else if (!strcmpi(core, "exploding ring")) {
        Snprintf(outmain, sizeof outmain, "指輪の爆発");
    } else if (!strcmpi(core, "exploding wand")) {
        Snprintf(outmain, sizeof outmain, "杖の爆発");
    } else if (!strcmpi(core, "exploding rune")) {
        Snprintf(outmain, sizeof outmain, "ルーンの爆発");
    } else if (!strcmpi(core, "residual undead turning effect")) {
        Snprintf(outmain, sizeof outmain, "アンデッド退散の残留効果");
    } else if (!strcmpi(core, "genocidal confusion")) {
        Snprintf(outmain, sizeof outmain, "虐殺による混乱");
    } else if (!strcmpi(core, "imperious order")) {
        Snprintf(outmain, sizeof outmain, "傲慢な命令");
    } else if (!strcmpi(core, "removing gloves")) {
        Snprintf(outmain, sizeof outmain, "手袋を脱いだこと");
    } else if (!strcmpi(core, "losing gloves")) {
        Snprintf(outmain, sizeof outmain, "手袋を失ったこと");
    } else if (!strcmpi(core, "removing boots")) {
        Snprintf(outmain, sizeof outmain, "靴を脱いだこと");
    } else if (!strcmpi(core, "losing boots")) {
        Snprintf(outmain, sizeof outmain, "靴を失ったこと");
    } else if (!strcmpi(core, "resistance timing out")) {
        Snprintf(outmain, sizeof outmain, "石化耐性が切れたこと");
    } else if (!strcmpi(core, "elementary physics")) {
        Snprintf(outmain, sizeof outmain, "物理法則");
    } else if (!strncmpi(core, "unwisely tried to eat ", 22)) {
        char fbuf[BUFSZ];
        jp_translate_food_or_corpse(fbuf, sizeof fbuf, core + 22);
        Snprintf(outmain, sizeof outmain, "無謀にも%sを食べようとした", fbuf);
    } else if (!strncmpi(core, "shot ", 5) && strstr(core, "self with a death ray")) {
        Snprintf(outmain, sizeof outmain, "死の光線を自分自身に撃った");
    } else if (strstr(core, " by himself") || strstr(core, " by herself") || strstr(core, " by itself")) {
        char verb[BUFSZ];
        char fltxt[BUFSZ];
        fltxt[0] = '\0';
        verb[0] = '\0';
        if (strstr(core, "zapped")) {
            Snprintf(verb, sizeof verb, "放った");
        } else if (strstr(core, "breathed")) {
            Snprintf(verb, sizeof verb, "吐いた");
        } else {
            Snprintf(verb, sizeof verb, "引き起こした");
        }
        if (strstr(core, "magic missile")) {
            Snprintf(fltxt, sizeof fltxt, "魔法の矢");
        } else if (strstr(core, "fire")) {
            Snprintf(fltxt, sizeof fltxt, "火炎");
        } else if (strstr(core, "frost")) {
            Snprintf(fltxt, sizeof fltxt, "冷気");
        } else if (strstr(core, "sleep")) {
            Snprintf(fltxt, sizeof fltxt, "睡眠ガス");
        } else if (strstr(core, "death")) {
            Snprintf(fltxt, sizeof fltxt, "死の光線");
        } else if (strstr(core, "lightning")) {
            Snprintf(fltxt, sizeof fltxt, "稲妻");
        } else if (strstr(core, "poison gas")) {
            Snprintf(fltxt, sizeof fltxt, "毒ガス");
        } else if (strstr(core, "acid")) {
            Snprintf(fltxt, sizeof fltxt, "酸");
        } else {
            Snprintf(fltxt, sizeof fltxt, "光線");
        }
        Snprintf(outmain, sizeof outmain, "自分自身で%s%s", verb, fltxt);
    } else if (!strcmpi(core, "committed suicide")) {
        Snprintf(outmain, sizeof outmain, "自殺");
    } else if (!strcmpi(core, "went to heaven prematurely")) {
        Snprintf(outmain, sizeof outmain, "早すぎる天国への旅");
    } else if (!strcmpi(core, "turned into green slime")) {
        Snprintf(outmain, sizeof outmain, "緑のスライムになったこと");
    } else if (!strcmpi(core, "slimicide")) {
        Snprintf(outmain, sizeof outmain, "スライム化による死");
    } else if (!strcmpi(core, "killed by petrification")) {
        Snprintf(outmain, sizeof outmain, "石化による死");
    } else if (!strcmpi(core, "strangulation")) {
        Snprintf(outmain, sizeof outmain, "首を絞められたこと");
    } else if (!strcmpi(core, "suffocation")) {
        Snprintf(outmain, sizeof outmain, "窒息");
    } else if (!strcmpi(core, "quit while already on Charon's boat")) {
        Snprintf(outmain, sizeof outmain, "カロンの舟の上で人生を諦めた");
    } else if (!strncmp(core, "unwisely ate the body of ", 25)) {
        const char *mname = skip_english_article(core + 25);
        int mndx, gend;
        mndx = name_to_mon(mname, &gend);
        if (mndx >= 0) {
            Snprintf(outmain, sizeof outmain, "%sの死体を食べた不心得",
                     jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(outmain, sizeof outmain, "%sの死体を食べた不心得", mname);
        }
    } else if (!strncmp(core, "unwisely ate the brain of ", 26)) {
        const char *mname = skip_english_article(core + 26);
        int mndx, gend;
        mndx = name_to_mon(mname, &gend);
        if (mndx >= 0) {
            Snprintf(outmain, sizeof outmain, "%sの脳を食べた不心得",
                     jp_pmname_from_idx(mndx, 0));
        } else {
            Snprintf(outmain, sizeof outmain, "%sの脳を食べた不心得", mname);
        }
    } else if (!strncmp(core, "tasting ", 8) && strstr(core, " meat")) {
        char mbuf[BUFSZ];
        const char *p = strstr(core, " meat");
        size_t mlen = p - (core + 8);
        if (mlen < sizeof mbuf) {
            (void) memcpy(mbuf, core + 8, mlen);
            mbuf[mlen] = '\0';
            const char *mname = skip_english_article(mbuf);
            int mndx, gend;
            mndx = name_to_mon(mname, &gend);
            if (mndx >= 0) {
                Snprintf(outmain, sizeof outmain, "%sの肉の試食",
                         jp_pmname_from_idx(mndx, 0));
            } else {
                Snprintf(outmain, sizeof outmain, "%sの肉の試食", mname);
            }
        } else {
            Snprintf(outmain, sizeof outmain, "肉の試食");
        }
    } else if (!strncmp(core, "the wrath of ", 13)) {
        Snprintf(outmain, sizeof outmain, "%sの怒り",
                 jp_gname_for_display(skip_english_article(core + 13)));
    } else if (!strncmp(core, "the anger of ", 13)) {
        Snprintf(outmain, sizeof outmain, "%sの怒り",
                 jp_gname_for_display(skip_english_article(core + 13)));
    } else if (strstr(core, "'s anger")) {
        char gbuf[BUFSZ];
        const char *p = strstr(core, "'s anger");
        size_t glen = p - core;
        if (glen < sizeof gbuf) {
            memcpy(gbuf, core, glen);
            gbuf[glen] = '\0';
            Snprintf(outmain, sizeof outmain, "%sの怒り",
                     jp_gname_for_display(skip_english_article(gbuf)));
        } else {
            Snprintf(outmain, sizeof outmain, "神の怒り");
        }
    } else if (strstr(core, "'s wrath")) {
        char gbuf[BUFSZ];
        const char *p = strstr(core, "'s wrath");
        size_t glen = p - core;
        if (glen < sizeof gbuf) {
            memcpy(gbuf, core, glen);
            gbuf[glen] = '\0';
            Snprintf(outmain, sizeof outmain, "%sの怒り",
                     jp_gname_for_display(skip_english_article(gbuf)));
        } else {
            Snprintf(outmain, sizeof outmain, "神の怒り");
        }
    } else if (strstr(core, " indifference")) {
        char gbuf[BUFSZ];
        const char *p = strstr(core, " indifference");
        size_t glen = p - core;
        if (glen < sizeof gbuf) {
            (void) memcpy(gbuf, core, glen);
            gbuf[glen] = '\0';
            /* s_suffix を除去 */
            if (glen >= 2 && !strcmp(gbuf + glen - 2, "'s"))
                gbuf[glen - 2] = '\0';
            else if (glen >= 1 && gbuf[glen - 1] == '\'')
                gbuf[glen - 1] = '\0';
            Snprintf(outmain, sizeof outmain, "%sの無関心",
                     jp_gname_for_display(gbuf));
        } else {
            Snprintf(outmain, sizeof outmain, "神の無関心");
        }
    } else if (!strncmp(core, "quit", 5)) {
        Snprintf(outmain, sizeof outmain, "中断した");
    } else if (!strncmp(core, "ascended", 8)) {
        Snprintf(outmain, sizeof outmain, "昇天した");
    } else if (!strncmp(core, "escaped", 7)) {
        const char *etail = core + 7;

        while (*etail == ' ')
            etail++;
        if (!*etail) {
            Snprintf(outmain, sizeof outmain, "脱出した");
        } else if (!strcmp(etail, "(with the Amulet)")) {
            Snprintf(outmain, sizeof outmain,
                     "アミュレットを持ったまま脱出した");
        } else if (!strcmp(etail, "(in celestial disgrace)")) {
            Snprintf(outmain, sizeof outmain,
                     "天上界の不名誉を背負って脱出した");
        } else if (!strcmp(etail, "(with a fake Amulet)")) {
            Snprintf(outmain, sizeof outmain,
                     "偽物のアミュレットを持って脱出した");
        } else {
            Snprintf(outmain, sizeof outmain, "脱出した %s", etail);
        }
    } else if (!strncmp(core, "quit ", 5)) {
        Snprintf(outmain, sizeof outmain, "中断した（%s）", core + 5);
    } else if (!strncmp(core, "died", 4)) {
        Snprintf(outmain, sizeof outmain, "死亡した");
    } else if (!strcmpi(core, "trickery")) {
        Snprintf(outmain, sizeof outmain, "不正行為");
    } else if (!strcmpi(core, "panic")) {
        Snprintf(outmain, sizeof outmain, "パニック");
    } else if (strstr(core, " own player")) {
        Snprintf(outmain, sizeof outmain, "自分自身のプレイヤー");
    } else if (!strcmpi(core, "committed suicide")) {
        Snprintf(outmain, sizeof outmain, "自殺");
    } else if (!strcmpi(core, "went to heaven prematurely")) {
        Snprintf(outmain, sizeof outmain, "早すぎる天国への旅");
    } else {
        const char *mname = skip_english_article(core);
        char kbuf[BUFSZ];
        jp_translate_killer_name_or_monster(mname, kbuf, sizeof kbuf);
        if (strstr(kbuf, "倒された") || strstr(kbuf, "石化した") || strstr(kbuf, "死んだ") || strstr(kbuf, "失敗")) {
            Snprintf(outmain, sizeof outmain, "%s", kbuf);
        } else {
            Snprintf(outmain, sizeof outmain, "%sに倒された", kbuf);
        }
    }

    if (*wieldingbuf) {
        char wieldingjp[BUFSZ];
        jp_translate_food_or_corpse(wieldingjp, sizeof wieldingjp, wieldingbuf);
        char outtmp[BUFSZ];
        Snprintf(outtmp, sizeof outtmp, "%s", outmain);
        Snprintf(outmain, sizeof outmain, "%s（%sを装備中）で石化した", outtmp, wieldingjp);
    }

    Snprintf(out, outsz, "%s", outmain);
    if (*whilebuf) {
        char whilejp[BUFSZ];

        if (!strcmp(whilebuf, "helpless")) {
            Snprintf(out, outsz, "%s（無力状態）", outmain);
        } else {
            const char *whiletxt =
                jp_translate_multi_reason_for_display(whilebuf,
                                                      whilejp,
                                                      sizeof whilejp);
            Snprintf(out, outsz, "%s（%s）", outmain, whiletxt);
        }
    }
}

void
jp_formatkiller_for_display(
    char *buf,
    unsigned siz,
    int how,
    boolean incl_helpless)
{
    char tmp[BUFSZ];

    formatkiller(tmp, sizeof tmp, how, incl_helpless);
    jp_translate_killer_text_for_display(buf, siz, tmp);
}

staticfn int
tt_gend_from_filecode(const char *fc)
{
    if (!fc || !*fc)
        return 0;
    if (!strncmp(fc, "Fem", 3) || !strncmp(fc, "F", 1))
        return 1;
    if (!strncmp(fc, "Mal", 3) || !strncmp(fc, "M", 1))
        return 0;
    return 0;
}

staticfn const char *
tt_role_name_from_filecode(const char *rolefc, const char *gendfc)
{
    int roleidx = str2role(rolefc);
    int gidx = tt_gend_from_filecode(gendfc);

    if (!g_language_is_jp)
        return (roleidx >= 0)
                ? ((gidx == 1 && roles[roleidx].name.f) ? roles[roleidx].name.f : roles[roleidx].name.m)
                : rolefc;

    return (roleidx >= 0)
            ? jp_role_name_for_display(roleidx, gidx)
            : rolefc;
}

staticfn const char *
tt_race_name_from_filecode(const char *racefc)
{
    int raceidx = str2race(racefc);

    if (!g_language_is_jp)
        return (raceidx >= 0 && races[raceidx].noun) ? races[raceidx].noun : racefc;

    return (raceidx >= 0) ? jp_race_adj_for_display(raceidx) : racefc;
}

staticfn const char *
tt_gender_name_from_filecode(const char *gendfc)
{
    if (!g_language_is_jp)
        return gendfc;
    return jp_gender_for_display(tt_gend_from_filecode(gendfc));
}

staticfn const char *
tt_align_name_from_filecode(const char *alignfc, const char *rolefc)
{
    int aidx = str2align(alignfc), ridx = str2role(rolefc);
    const char *gnam = 0;

    /* str2align() returns an index into aligns[], not an aligntyp.
     * Use aligns[aidx].value to get the A_LAWFUL/A_NEUTRAL/A_CHAOTIC
     * constant.  For topten display, deity must be resolved from each
     * record's role (rolefc), not from current gu.urole. */
    if (aidx < 0 || aidx >= ROLE_ALIGNS)
        return alignfc;

    if (ridx >= 0) {
        switch (aligns[aidx].value) {
        case A_LAWFUL:
            gnam = roles[ridx].lgod;
            break;
        case A_NEUTRAL:
            gnam = roles[ridx].ngod;
            break;
        case A_CHAOTIC:
            gnam = roles[ridx].cgod;
            break;
        default:
            break;
        }
    }

    if (gnam && *gnam) {
        if (*gnam == '_')
            ++gnam;
        return g_language_is_jp ? jp_gname_for_display(gnam) : gnam;
    }

    /* Fallback when role has no fixed pantheon (for example, some Priest
       configurations) or role code is unavailable: show alignment label. */
    return g_language_is_jp ? jp_align_for_display(aidx) : alignfc;
}

staticfn void
topten_print(const char *x)
{
    if (gt.toptenwin == WIN_ERR)
        raw_print(x);
    else
        putstr(gt.toptenwin, ATR_NONE, x);
}

staticfn void
topten_print_bold(const char *x)
{
    if (gt.toptenwin == WIN_ERR)
        raw_print_bold(x);
    else
        putstr(gt.toptenwin, ATR_BOLD, x);
}

staticfn int
topten_utf8_charlen(const char *s)
{
    uchar c0;

    if (!s || !*s)
        return 0;
    c0 = (uchar) *s;
    if (c0 < 0x80)
        return 1;
    if (c0 >= 0xC2 && c0 <= 0xDF)
        return (uchar) s[1] >= 0x80 && (uchar) s[1] <= 0xBF ? 2 : 1;
    if (c0 >= 0xE0 && c0 <= 0xEF)
        return ((uchar) s[1] >= 0x80 && (uchar) s[1] <= 0xBF
                && (uchar) s[2] >= 0x80 && (uchar) s[2] <= 0xBF) ? 3 : 1;
    if (c0 >= 0xF0 && c0 <= 0xF4)
        return ((uchar) s[1] >= 0x80 && (uchar) s[1] <= 0xBF
                && (uchar) s[2] >= 0x80 && (uchar) s[2] <= 0xBF
                && (uchar) s[3] >= 0x80 && (uchar) s[3] <= 0xBF) ? 4 : 1;
    return 1;
}

staticfn int
topten_dispwidth(const char *s)
{
    int w = 0, len;

    while (s && *s) {
        len = topten_utf8_charlen(s);
        w += ((uchar) *s < 0x80) ? 1 : 2;
        s += len;
    }
    return w;
}

/* return split position; caller will terminate line at this pointer */
staticfn char *
topten_wrapsplit(char *s, int maxw)
{
    char *p = s, *last_space = (char *) 0, *first_over = (char *) 0;
    char *indent_end = s;
    int w = 0, len, cw;

    /* 先頭のインデント用スペースをスキップする */
    while (*indent_end == ' ')
        indent_end++;

    while (*p) {
        len = topten_utf8_charlen(p);
        cw = ((uchar) *p < 0x80) ? 1 : 2;
        /* インデントより後ろにあるスペースのみを記録する */
        if (*p == ' ' && p >= indent_end)
            last_space = p;
        if (w + cw >= maxw) {
            first_over = p;
            break;
        }
        w += cw;
        p += len;
    }

    if (first_over)
        return (last_space && last_space >= indent_end) ? last_space : first_over;
    return eos(s);
}

int
observable_depth(d_level *lev)
{
#if 0
    /* if we ever randomize the order of the elemental planes, we
       must use a constant external representation in the record file */
    if (In_endgame(lev)) {
        if (Is_astralevel(lev))
            return -5;
        else if (Is_waterlevel(lev))
            return -4;
        else if (Is_firelevel(lev))
            return -3;
        else if (Is_airlevel(lev))
            return -2;
        else if (Is_earthlevel(lev))
            return -1;
        else
            return 0; /* ? */
    } else
#endif
    return depth(lev);
}

/* throw away characters until current record has been entirely consumed */
staticfn void
discardexcess(FILE *rfile)
{
    int c;

    do {
        c = fgetc(rfile);
    } while (c != '\n' && c != EOF);
}

DISABLE_WARNING_FORMAT_NONLITERAL

staticfn void
readentry(FILE *rfile, struct toptenentry *tt)
{
    char inbuf[SCANBUFSZ], s1[SCANBUFSZ], s2[SCANBUFSZ], s3[SCANBUFSZ],
         s4[SCANBUFSZ], s5[SCANBUFSZ], s6[SCANBUFSZ];

#ifdef NO_SCAN_BRACK /* Version_ Pts DgnLevs_ Hp___ Died__Born id */
    static const char fmt[] = "%d %d %d %ld %d %d %d %d %d %d %ld %ld %d%*c";
    static const char fmt32[] = "%c%c %s %s%*c";
    static const char fmt33[] = "%s %s %s %s %s %s%*c";
#else
    static const char fmt[] = "%d.%d.%d %ld %d %d %d %d %d %d %ld %ld %d ";
    static const char fmt32[] = "%c%c %[^,],%[^\n]%*c";
    static const char fmt33[] = "%s %s %s %s %[^,],%[^\n]%*c";
#endif

#ifdef UPDATE_RECORD_IN_PLACE
    /* note: input below must read the record's terminating newline */
    final_fpos = tt->fpos = ftell(rfile);
#endif
#define TTFIELDS 13
    if (fscanf(rfile, fmt, &tt->ver_major, &tt->ver_minor, &tt->patchlevel,
               &tt->points, &tt->deathdnum, &tt->deathlev, &tt->maxlvl,
               &tt->hp, &tt->maxhp, &tt->deaths, &tt->deathdate,
               &tt->birthdate, &tt->uid) != TTFIELDS) {
#undef TTFIELDS
        tt->points = 0;
        discardexcess(rfile);
    } else {
        /* load remainder of record into a local buffer;
           this imposes an implicit length limit of SCANBUFSZ
           on every string field extracted from the buffer */
        if (!fgets(inbuf, sizeof inbuf, rfile)) {
            /* sscanf will fail and tt->points will be set to 0 */
            *inbuf = '\0';
        } else if (!strchr(inbuf, '\n')) {
            Strcpy(&inbuf[sizeof inbuf - 2], "\n");
            discardexcess(rfile);
        }
        /* Check for backwards compatibility */
        if (tt->ver_major < 3 || (tt->ver_major == 3 && tt->ver_minor < 3)) {
            int i;

            if (sscanf(inbuf, fmt32, tt->plrole, tt->plgend, s1, s2) == 4) {
                tt->plrole[1] = tt->plgend[1] = '\0'; /* read via %c */
                copynchars(tt->name, s1, (int) (sizeof tt->name) - 1);
                copynchars(tt->death, s2, (int) (sizeof tt->death) - 1);
                /* 旧バージョン record の場合も同様に UTF-8 文字数の上限を
                   強制する (破損データ対策) */
                utf8_char_truncate(tt->name, NAMSZ_CHARS);
            } else
                tt->points = 0;
            tt->plrole[1] = '\0';
            if ((i = str2role(tt->plrole)) >= 0)
                Strcpy(tt->plrole, roles[i].filecode);
            Strcpy(tt->plrace, "?");
            Strcpy(tt->plgend, (tt->plgend[0] == 'M') ? "Mal" : "Fem");
            Strcpy(tt->plalign, "?");
        } else if (sscanf(inbuf, fmt33, s1, s2, s3, s4, s5, s6) == 6) {
            copynchars(tt->plrole, s1, (int) (sizeof tt->plrole) - 1);
            copynchars(tt->plrace, s2, (int) (sizeof tt->plrace) - 1);
            copynchars(tt->plgend, s3, (int) (sizeof tt->plgend) - 1);
            copynchars(tt->plalign, s4, (int) (sizeof tt->plalign) - 1);
            copynchars(tt->name, s5, (int) (sizeof tt->name) - 1);
            copynchars(tt->death, s6, (int) (sizeof tt->death) - 1);
            /* 読み込んだ名前が破損 (例: 別バージョンで保存された長い名前や
               編集された record ファイル) していても、ここで UTF-8 文字
               数の上限 (NAMSZ_CHARS) を強制することで、後段の strncmp や
               表示処理への不整合伝播を防ぐ。 */
            utf8_char_truncate(tt->name, NAMSZ_CHARS);
        } else
            tt->points = 0;
#ifdef NO_SCAN_BRACK
        if (tt->points > 0) {
            nsb_unmung_line(tt->name);
            nsb_unmung_line(tt->death);
        }
#endif
    }

    /* check old score entries for Y2K problem and fix whenever found */
    if (tt->points > 0) {
        if (tt->birthdate < 19000000L)
            tt->birthdate += 19000000L;
        if (tt->deathdate < 19000000L)
            tt->deathdate += 19000000L;
    }
}

staticfn void
writeentry(FILE *rfile, struct toptenentry *tt)
{
    static const char fmt32[] = "%c%c ";        /* role,gender */
    static const char fmt33[] = "%s %s %s %s "; /* role,race,gndr,algn */
#ifndef NO_SCAN_BRACK
    static const char fmt0[] = "%d.%d.%d %ld %d %d %d %d %d %d %ld %ld %d ";
    static const char fmtX[] = "%s,%s\n";
#else /* NO_SCAN_BRACK */
    static const char fmt0[] = "%d %d %d %ld %d %d %d %d %d %d %ld %ld %d ";
    static const char fmtX[] = "%s %s\n";

    nsb_mung_line(tt->name);
    nsb_mung_line(tt->death);
#endif

    (void) fprintf(rfile, fmt0, tt->ver_major, tt->ver_minor, tt->patchlevel,
                   tt->points, tt->deathdnum, tt->deathlev, tt->maxlvl,
                   tt->hp, tt->maxhp, tt->deaths, tt->deathdate,
                   tt->birthdate, tt->uid);
    if (tt->ver_major < 3 || (tt->ver_major == 3 && tt->ver_minor < 3))
        (void) fprintf(rfile, fmt32, tt->plrole[0], tt->plgend[0]);
    else
        (void) fprintf(rfile, fmt33, tt->plrole, tt->plrace, tt->plgend,
                       tt->plalign);
    (void) fprintf(rfile, fmtX, onlyspace(tt->name) ? "_" : tt->name,
                   tt->death);

#ifdef NO_SCAN_BRACK
    nsb_unmung_line(tt->name);
    nsb_unmung_line(tt->death);
#endif
}

RESTORE_WARNING_FORMAT_NONLITERAL

#ifdef XLOGFILE

/* as tab is never used in eg. svp.plname or death, no need to mangle those. */
staticfn void
writexlentry(FILE *rfile, struct toptenentry *tt, int how)
{
#define Fprintf (void) fprintf
#define XLOG_SEP '\t' /* xlogfile field separator. */
    char buf[BUFSZ], tmpbuf[DTHSZ + 1];
    char achbuf[N_ACH * 40];

    Sprintf(buf, "version=%d.%d.%d", tt->ver_major, tt->ver_minor,
            tt->patchlevel);
    Sprintf(eos(buf), "%cpoints=%ld%cdeathdnum=%d%cdeathlev=%d", XLOG_SEP,
            tt->points, XLOG_SEP, tt->deathdnum, XLOG_SEP, tt->deathlev);
    Sprintf(eos(buf), "%cmaxlvl=%d%chp=%d%cmaxhp=%d", XLOG_SEP, tt->maxlvl,
            XLOG_SEP, tt->hp, XLOG_SEP, tt->maxhp);
    Sprintf(eos(buf), "%cdeaths=%d%cdeathdate=%ld%cbirthdate=%ld%cuid=%d",
            XLOG_SEP, tt->deaths, XLOG_SEP, tt->deathdate, XLOG_SEP,
            tt->birthdate, XLOG_SEP, tt->uid);
    Fprintf(rfile, "%s", buf);
    Sprintf(buf, "%crole=%s%crace=%s%cgender=%s%calign=%s", XLOG_SEP,
            tt->plrole, XLOG_SEP, tt->plrace, XLOG_SEP, tt->plgend, XLOG_SEP,
            tt->plalign);
    /* make a copy of death reason that doesn't include ", while helpless" */
    formatkiller(tmpbuf, sizeof tmpbuf, how, FALSE);
    Fprintf(rfile, "%s%cname=%s%cdeath=%s",
            buf, /* (already includes separator) */
            XLOG_SEP, svp.plname, XLOG_SEP, tmpbuf);
    if (gm.multi < 0)
        Fprintf(rfile, "%cwhile=%s", XLOG_SEP,
                gm.multi_reason ? gm.multi_reason : "helpless");
    Fprintf(rfile, "%cconduct=0x%lx%cturns=%ld%cachieve=0x%lx", XLOG_SEP,
            encodeconduct(), XLOG_SEP, svm.moves, XLOG_SEP,
            encodeachieve(FALSE));
    Fprintf(rfile, "%cachieveX=%s", XLOG_SEP,
            encode_extended_achievements(achbuf));
    Fprintf(rfile, "%cconductX=%s", XLOG_SEP,
            encode_extended_conducts(buf)); /* reuse 'buf[]' */
    Fprintf(rfile, "%crealtime=%ld%cstarttime=%ld%cendtime=%ld", XLOG_SEP,
            urealtime.realtime, XLOG_SEP,
            timet_to_seconds(ubirthday), XLOG_SEP,
            timet_to_seconds(urealtime.finish_time));
    Fprintf(rfile, "%cgender0=%s%calign0=%s", XLOG_SEP,
            genders[flags.initgend].filecode, XLOG_SEP,
            aligns[1 - u.ualignbase[A_ORIGINAL]].filecode);
    Fprintf(rfile, "%cflags=0x%lx", XLOG_SEP, encodexlogflags());
    Fprintf(rfile, "%cgold=%ld", XLOG_SEP,
            money_cnt(gi.invent) + hidden_gold(TRUE));
    Fprintf(rfile, "%cwish_cnt=%ld", XLOG_SEP, u.uconduct.wishes);
    Fprintf(rfile, "%carti_wish_cnt=%ld", XLOG_SEP, u.uconduct.wisharti);
    Fprintf(rfile, "%cbones=%ld", XLOG_SEP, u.uroleplay.numbones);
    Fprintf(rfile, "%crerolls=%ld", XLOG_SEP, u.uroleplay.numrerolls);
    Fprintf(rfile, "\n");
#undef XLOG_SEP
}

staticfn long
encodexlogflags(void)
{
    long e = 0L;

    if (wizard)
        e |= 1L << 0;
    if (discover)
        e |= 1L << 1;
    if (!u.uroleplay.numbones)
        e |= 1L << 2;
    if (u.uroleplay.reroll)
        e |= 1L << 3;

    return e;
}

staticfn long
encodeconduct(void)
{
    long e = 0L;

    if (!u.uconduct.food)
        e |= 1L << 0;
    if (!u.uconduct.unvegan)
        e |= 1L << 1;
    if (!u.uconduct.unvegetarian)
        e |= 1L << 2;
    if (!u.uconduct.gnostic)
        e |= 1L << 3;
    if (!u.uconduct.weaphit)
        e |= 1L << 4;
    if (!u.uconduct.killer)
        e |= 1L << 5;
    if (!u.uconduct.literate)
        e |= 1L << 6;
    if (!u.uconduct.polypiles)
        e |= 1L << 7;
    if (!u.uconduct.polyselfs)
        e |= 1L << 8;
    if (!u.uconduct.wishes)
        e |= 1L << 9;
    if (!u.uconduct.wisharti)
        e |= 1L << 10;
    if (!num_genocides())
        e |= 1L << 11;
    /* one bit isn't really adequate for sokoban conduct:
       reporting "obeyed sokoban rules" is misleading if sokoban wasn't
       completed or at least attempted; however, suppressing that when
       sokoban was never entered, as we do here, risks reporting
       "violated sokoban rules" when no such thing occurred; this can
       be disambiguated in xlogfile post-processors by testing the
       entered-sokoban bit in the 'achieve' field */
    if (!u.uconduct.sokocheat && sokoban_in_play())
        e |= 1L << 12;
    if (!u.uconduct.pets)
        e |= 1L << 13;

    return e;
}

staticfn long
encodeachieve(
    boolean secondlong) /* False: handle achievements 1..31, True: 32..62 */
{
    int i, achidx, offset;
    long r = 0L;

    /*
     * 32: portable limit for 'long'.
     * Force 32 even on configurations that are using 64 bit longs.
     *
     * We use signed long and limit ourselves to 31 bits since tools
     * that post-process xlogfile might not be able to cope with
     * 'unsigned long'.
     */
    offset = secondlong ? (32 - 1) : 0;
    for (i = 0; u.uachieved[i]; ++i) {
        achidx = u.uachieved[i] - offset;
        if (achidx > 0 && achidx < 32) /* value 1..31 sets bit 0..30 */
            r |= 1L << (achidx - 1);
    }
    return r;
}

/* add the achievement or conduct comma-separated to string */
staticfn void
add_achieveX(char *buf, const char *achievement, boolean condition)
{
    if (condition) {
        if (buf[0] != '\0') {
            Strcat(buf, ",");
        }
        Strcat(buf, achievement);
    }
}

staticfn char *
encode_extended_achievements(char *buf)
{
    char rnkbuf[40];
    const char *achievement = NULL;
    int i, achidx, absidx;

    buf[0] = '\0';
    for (i = 0; u.uachieved[i]; i++) {
        achidx = u.uachieved[i];
        absidx = abs(achidx);
        switch (absidx) {
        case ACH_UWIN:
            achievement = "ascended";
            break;
        case ACH_ASTR:
            achievement = "entered_astral_plane";
            break;
        case ACH_ENDG:
            achievement = "entered_elemental_planes";
            break;
        case ACH_AMUL:
            achievement = "obtained_the_amulet_of_yendor";
            break;
        case ACH_INVK:
            achievement = "performed_the_invocation_ritual";
            break;
        case ACH_BOOK:
            achievement = "obtained_the_book_of_the_dead";
            break;
        case ACH_BELL:
            achievement = "obtained_the_bell_of_opening";
            break;
        case ACH_CNDL:
            achievement = "obtained_the_candelabrum_of_invocation";
            break;
        case ACH_HELL:
            achievement = "entered_gehennom";
            break;
        case ACH_MEDU:
            achievement = "defeated_medusa";
            break;
        case ACH_MINE_PRIZE:
            achievement = "obtained_the_luckstone_from_the_mines";
            break;
        case ACH_SOKO_PRIZE:
            achievement = "obtained_the_sokoban_prize";
            break;
        case ACH_ORCL:
            achievement = "consulted_the_oracle";
            break;
        case ACH_NOVL:
            achievement = "read_a_discworld_novel";
            break;
        case ACH_MINE:
            achievement = "entered_the_gnomish_mines";
            break;
        case ACH_TOWN:
            achievement = "entered_mine_town";
            break;
        case ACH_SHOP:
            achievement = "entered_a_shop";
            break;
        case ACH_TMPL:
            achievement = "entered_a_temple";
            break;
        case ACH_SOKO:
            achievement = "entered_sokoban";
            break;
        case ACH_BGRM:
            achievement = "entered_bigroom";
            break;
        case ACH_TUNE:
            achievement = "learned_castle_drawbridge_tune";
            break;
        /* rank 0 is the starting condition, not an achievement; 8 is Xp 30 */
        case ACH_RNK1: case ACH_RNK2: case ACH_RNK3: case ACH_RNK4:
        case ACH_RNK5: case ACH_RNK6: case ACH_RNK7: case ACH_RNK8:
            Sprintf(rnkbuf, "attained_the_rank_of_%s",
                    rank_of(rank_to_xlev(absidx - (ACH_RNK1 - 1)),
                            Role_switch, (achidx < 0) ? TRUE : FALSE));
            strNsubst(rnkbuf, " ", "_", 0); /* replace every ' ' with '_' */
            achievement = lcase(rnkbuf);
            break;
        default:
            continue;
        }
        add_achieveX(buf, achievement, TRUE);
    }

    return buf;
}

staticfn char *
encode_extended_conducts(char *buf)
{
    buf[0] = '\0';
    add_achieveX(buf, "foodless",     !u.uconduct.food);
    add_achieveX(buf, "vegan",        !u.uconduct.unvegan);
    add_achieveX(buf, "vegetarian",   !u.uconduct.unvegetarian);
    add_achieveX(buf, "atheist",      !u.uconduct.gnostic);
    add_achieveX(buf, "weaponless",   !u.uconduct.weaphit);
    add_achieveX(buf, "pacifist",     !u.uconduct.killer);
    add_achieveX(buf, "illiterate",   !u.uconduct.literate);
    add_achieveX(buf, "polyless",     !u.uconduct.polypiles);
    add_achieveX(buf, "polyselfless", !u.uconduct.polyselfs);
    add_achieveX(buf, "wishless",     !u.uconduct.wishes);
    add_achieveX(buf, "artiwishless", !u.uconduct.wisharti);
    add_achieveX(buf, "genocideless", !num_genocides());
    if (sokoban_in_play())
        add_achieveX(buf, "sokoban",  !u.uconduct.sokocheat);
    add_achieveX(buf, "blind",        u.uroleplay.blind);
    add_achieveX(buf, "deaf",         u.uroleplay.deaf);
    add_achieveX(buf, "nudist",       u.uroleplay.nudist);
    add_achieveX(buf, "pauper",       u.uroleplay.pauper);
    add_achieveX(buf, "bonesless",    !flags.bones);
    add_achieveX(buf, "petless",      !u.uconduct.pets);
    add_achieveX(buf, "unrerolled",   !u.uroleplay.reroll);

    return buf;
}

#endif /* XLOGFILE */

staticfn void
free_ttlist(struct toptenentry *tt)
{
    struct toptenentry *ttnext;

    while (tt->points > 0) {
        ttnext = tt->tt_next;
        dealloc_ttentry(tt);
        tt = ttnext;
    }
    dealloc_ttentry(tt);
}

void
topten(int how, time_t when)
{
    struct toptenentry *t0, *tprev;
    struct toptenentry *t1;
    FILE *rfile;
#ifdef LOGFILE
    FILE *lfile;
#endif
#ifdef XLOGFILE
    FILE *xlfile;
#endif
    int uid = getuid();
    int rank, rank0 = -1, rank1 = 0;
    int occ_cnt = sysopt.persmax;
    int flg = 0;
    boolean t0_used, skip_scores;

#ifdef UPDATE_RECORD_IN_PLACE
    final_fpos = 0L;
#endif
    /* If we are in the midst of a panic, cut out topten entirely.
     * topten uses alloc() several times, which will lead to
     * problems if the panic was the result of an alloc() failure.
     */
    if (program_state.panicking)
        return;

    if (iflags.toptenwin) {
        gt.toptenwin = create_nhwindow(NHW_TEXT);
    }

#if defined(HANGUPHANDLING)
#define HUP if (!program_state.done_hup)
#else
#define HUP
#endif

#ifdef TOS
    restore_colors(); /* make sure the screen is black on white */
#endif
    /* create a new 'topten' entry */
    t0_used = FALSE;
    t0 = newttentry();
    *t0 = zerott;
    t0->ver_major = VERSION_MAJOR;
    t0->ver_minor = VERSION_MINOR;
    t0->patchlevel = PATCHLEVEL;
    t0->points = u.urexp;
    t0->deathdnum = u.uz.dnum;
    /* deepest_lev_reached() is in terms of depth(), and reporting the
     * deepest level reached in the dungeon death occurred in doesn't
     * seem right, so we have to report the death level in depth() terms
     * as well (which also seems reasonable since that's all the player
     * sees on the screen anyway)
     */
    t0->deathlev = observable_depth(&u.uz);
    t0->maxlvl = deepest_lev_reached(TRUE);
    t0->hp = u.uhp;
    t0->maxhp = u.uhpmax;
    t0->deaths = u.umortality;
    t0->uid = uid;
    copynchars(t0->plrole, gu.urole.filecode, ROLESZ);
    copynchars(t0->plrace, gu.urace.filecode, ROLESZ);
    copynchars(t0->plgend, genders[flags.female].filecode, ROLESZ);
    copynchars(t0->plalign, aligns[1 - u.ualign.type].filecode, ROLESZ);
    /* プレイヤー名は UTF-8 文字数の上限 (NAMSZ_CHARS) まで保持する。
       まずバイト単位 (NAMSZ) でバッファオーバーフローを防いだ後、
       UTF-8 文字単位で切り詰めることで、全角文字・半角文字・絵文字の
       いずれが含まれていても 10 文字を超える分は文字境界で切り詰める。 */
    copynchars(t0->name, svp.plname, NAMSZ);
    utf8_char_truncate(t0->name, NAMSZ_CHARS);
    formatkiller(t0->death, sizeof t0->death, how, TRUE);
    t0->birthdate = yyyymmdd(ubirthday);
    t0->deathdate = yyyymmdd(when);
    t0->tt_next = 0;
#ifdef UPDATE_RECORD_IN_PLACE
    t0->fpos = -1L;
#endif

#ifdef LOGFILE /* used for debugging (who dies of what, where) */
    if (lock_file(LOGFILE, SCOREPREFIX, 10)) {
        if (!(lfile = fopen_datafile(LOGFILE, "a", SCOREPREFIX))) {
            HUP raw_print("ログファイルを開けない。");
        } else {
            writeentry(lfile, t0);
            (void) fclose(lfile);
        }
        unlock_file(LOGFILE);
    }
#endif /* LOGFILE */
#ifdef XLOGFILE
    if (lock_file(XLOGFILE, SCOREPREFIX, 10)) {
        if (!(xlfile = fopen_datafile(XLOGFILE, "a", SCOREPREFIX))) {
            HUP raw_print("拡張ログファイルを開けない。");
        } else {
            writexlentry(xlfile, t0, how);
            (void) fclose(xlfile);
        }
        unlock_file(XLOGFILE);
    }
#endif /* XLOGFILE */

    if (wizard || discover) {
        if (how != PANICKED)
            HUP {
                char pbuf[BUFSZ];

                topten_print("");
                Sprintf(pbuf,
                        "%sモード中のため、スコア一覧は更新されない。",
                    wizard ? "ウィザード(wizard)" : "探索(discover)");
                topten_print(pbuf);
            }
        goto showwin;
    }

    if (!lock_file(RECORD, SCOREPREFIX, 60))
        goto destroywin;

#ifdef UPDATE_RECORD_IN_PLACE
    rfile = fopen_datafile(RECORD, "r+", SCOREPREFIX);
#else
    rfile = fopen_datafile(RECORD, "r", SCOREPREFIX);
#endif

    if (!rfile) {
        HUP raw_print("スコア記録ファイルを開けない。");
        unlock_file(RECORD);
        goto destroywin;
    }

    HUP topten_print("");

    /* assure minimum number of points */
    if (t0->points < sysopt.pointsmin)
        t0->points = 0;

    t1 = tt_head = newttentry();
    *t1 = zerott; /* t0 と同様、NUL 終端以降の未初期化バイトが残らないように
                     構造体全体をゼロ初期化しておく (strncmp の精度拡大に
                     伴う比較バグの防止) */
    tprev = 0;
    /* rank0: -1 undefined, 0 not_on_list, n n_th on list */
    for (rank = 1; ; ) {
        readentry(rfile, t1);
        if (t1->points < sysopt.pointsmin)
            t1->points = 0;
        if (rank0 < 0 && t1->points < t0->points) {
            rank0 = rank++;
            if (tprev == 0)
                tt_head = t0;
            else
                tprev->tt_next = t0;
            t0->tt_next = t1;
#ifdef UPDATE_RECORD_IN_PLACE
            t0->fpos = t1->fpos; /* insert here */
#endif
            t0_used = TRUE;
            occ_cnt--;
            flg++; /* ask for a rewrite */
        } else
            tprev = t1;

        if (t1->points == 0)
            break;
        if ((sysopt.pers_is_uid ? t1->uid == t0->uid
                                : strncmp(t1->name, t0->name, NAMSZ) == 0)
            && !strncmp(t1->plrole, t0->plrole, ROLESZ) && --occ_cnt <= 0) {
            if (rank0 < 0) {
                rank0 = 0;
                rank1 = rank;
                HUP {
                    char pbuf[BUFSZ];

                    Sprintf(pbuf,
                        "前回の自己記録 %ld 点を更新できなかった。",
                            t1->points);
                    topten_print(pbuf);
                    topten_print("");
                }
            }
            if (occ_cnt < 0) {
                flg++;
                continue;
            }
        }
        if (rank <= sysopt.entrymax) {
            t1->tt_next = newttentry();
            *t1->tt_next = zerott; /* 新規ノードも同様にゼロ初期化 */
            t1 = t1->tt_next;
            rank++;
        }
        if (rank > sysopt.entrymax) {
            t1->points = 0;
            break;
        }
    }
    if (flg) { /* rewrite record file */
#ifdef UPDATE_RECORD_IN_PLACE
        (void) fseek(rfile, (t0->fpos >= 0) ? t0->fpos : final_fpos, SEEK_SET);
#else
        (void) fclose(rfile);
        if (!(rfile = fopen_datafile(RECORD, "w", SCOREPREFIX))) {
            HUP raw_print("スコア記録ファイルを書き込めない。");
            unlock_file(RECORD);
            free_ttlist(tt_head);
            goto destroywin;
        }
#endif /* UPDATE_RECORD_IN_PLACE */
        if (!done_stopprint)
            if (rank0 > 0) {
                if (rank0 <= 10) {
                    topten_print("トップ10入りした。");
                } else {
                    char pbuf[BUFSZ];

                    Sprintf(pbuf,
                            "トップ%dのうち %d 位に入った。",
                            sysopt.entrymax, rank0);
                    topten_print(pbuf);
                }
                topten_print("");
            }
    }
    skip_scores = !flags.end_top && !flags.end_around && !flags.end_own;
    if (rank0 == 0)
        rank0 = rank1;
    if (rank0 <= 0)
        rank0 = rank;
    if (!skip_scores && !done_stopprint)
        outheader();
    for (t1 = tt_head, rank = 1; t1->points != 0; t1 = t1->tt_next, ++rank) {
        if (flg
#ifdef UPDATE_RECORD_IN_PLACE
            && rank >= rank0
#endif
            )
            writeentry(rfile, t1);
        if (skip_scores || done_stopprint)
            continue;
        if (rank <= flags.end_top
            || (rank >= rank0 - flags.end_around
                && rank <= rank0 + flags.end_around)
            || (flags.end_own && (sysopt.pers_is_uid
                                  ? t1->uid == t0->uid
                                  : !strncmp(t1->name, t0->name, NAMSZ)))) {
            if (rank == rank0 - flags.end_around
                && rank0 > flags.end_top + flags.end_around + 1
                && !flags.end_own)
                topten_print("");

            if (rank != rank0) {
                outentry(rank, t1, FALSE);
            } else if (!rank1) {
                outentry(rank, t1, TRUE);
            } else {
                outentry(rank, t1, TRUE);
                outentry(0, t0, TRUE);
            }
        }
    }
    if (rank0 >= rank)
        if (!skip_scores && !done_stopprint)
            outentry(0, t0, TRUE);
#ifdef UPDATE_RECORD_IN_PLACE
    if (flg) {
#ifdef TRUNCATE_FILE
        /* if a reasonable way to truncate a file exists, use it */
        truncate_file(rfile);
#else
        /* use sentinel record rather than relying on truncation */
        *t1 = zerott;
        t1->points = 0L; /* [redundant] terminates file when read back in */
        t1->plrole[0] = t1->plrace[0] = t1->plgend[0] = t1->plalign[0] = '-';
        t1->birthdate = t1->deathdate = yyyymmdd((time_t) 0L);
        Strcpy(t1->name, "@");
        Strcpy(t1->death, "<eod>\n"); /* end of data */
        writeentry(rfile, t1);
        /* note: there might be junk (if file has shrunk due to shorter
           entries supplanting longer ones) after this dummy entry, but
           reading and/or updating will ignore it */
        (void) fflush(rfile);
#endif /* TRUNCATE_FILE */
    }
#endif /* UPDATE_RECORD_IN_PLACE */
    (void) fclose(rfile);
    unlock_file(RECORD);
    free_ttlist(tt_head);

 showwin:
    if (!done_stopprint) {
        if (iflags.toptenwin) {
            display_nhwindow(gt.toptenwin, TRUE);
        } else {
            /* when not a window, we need something comparable to more()
               but can't use it directly because we aren't dealing with
               the message window */
            ;
        }
    }
 destroywin:
    if (!t0_used)
        dealloc_ttentry(t0);
    if (iflags.toptenwin) {
        destroy_nhwindow(gt.toptenwin);
        gt.toptenwin = WIN_ERR;
    }
}

staticfn void
outheader(void)
{
    char linebuf[BUFSZ];
    int w;

    Strcpy(linebuf, "順位      点数  名前");
    w = topten_dispwidth(linebuf);
    while (w < COLNO - 9) {
        Strcat(linebuf, " ");
        ++w;
    }
    Strcat(linebuf, "HP[最大]");
    topten_print(linebuf);
}

DISABLE_WARNING_FORMAT_NONLITERAL

/* so>0: standout line; so=0: ordinary line */
staticfn void
outentry(int rank, struct toptenentry *t1, boolean so)
{
    char linebuf[BUFSZ];
    char *bp, hpbuf[24], linebuf3[BUFSZ], deathbuf[BUFSZ], profilebuf[BUFSZ];
    const char *arg;
    int hppos, lngr;

    linebuf[0] = '\0';
    if (rank)
        Sprintf(eos(linebuf), "%3d", rank);
    else
        Strcat(linebuf, "   ");

    /* 名前は最大 NAMSZ_CHARS (10) 文字保持され、バイト長は最大
       4 * NAMSZ_CHARS (40) バイトとなり得るため、表示用のバイト長
       上限を NAMSZ (40) に合わせて拡張する。行が長くなる場合は
       topten_wrapsplit() が折り返し処理を行う。 */
    Sprintf(eos(linebuf), " %10ld  %.*s", t1->points ? t1->points : u.urexp,
            (int) NAMSZ, t1->name);
    Snprintf(profilebuf, sizeof profilebuf, "%s",
             tt_role_name_from_filecode(t1->plrole, t1->plgend));
    if (t1->plrace[0] != '?')
        Sprintf(eos(profilebuf), "/%s", tt_race_name_from_filecode(t1->plrace));
    Sprintf(eos(profilebuf), "/%s", tt_gender_name_from_filecode(t1->plgend));
    if (t1->plalign[0] != '?')
        Sprintf(eos(profilebuf), "/%s",
            tt_align_name_from_filecode(t1->plalign, t1->plrole));
    Sprintf(eos(linebuf), " %s ", profilebuf);

    jp_translate_killer_text_for_display(deathbuf, sizeof deathbuf, t1->death);
    if (!g_language_is_jp) {
        if (!strncmp("escaped", t1->death, 7)) {
            Sprintf(eos(linebuf), "%s [max level %d]", deathbuf, t1->maxlvl);
        } else if (!strncmp("ascended", t1->death, 8)) {
            Strcat(linebuf, deathbuf);
        } else {
            Sprintf(eos(linebuf), "%s", deathbuf);

            if (t1->deathdnum == astral_level.dnum) {
                const char *arg, *fmt = " on the Plane of %s";

                switch (t1->deathlev) {
                case -5:
                    fmt = " on the %s Plane";
                    arg = "Astral";
                    break;
                case -4:
                    arg = "Water";
                    break;
                case -3:
                    arg = "Fire";
                    break;
                case -2:
                    arg = "Air";
                    break;
                case -1:
                    arg = "Earth";
                    break;
                default:
                    arg = "Void";
                    break;
                }
                Sprintf(eos(linebuf), fmt, arg);
            } else {
                Sprintf(eos(linebuf), " in %s",
                        svd.dungeons[t1->deathdnum].dname);
                if (t1->deathdnum != knox_level.dnum)
                    Sprintf(eos(linebuf), " on level %d", t1->deathlev);
                if (t1->deathlev != t1->maxlvl)
                    Sprintf(eos(linebuf), " [max level %d]", t1->maxlvl);
            }
        }
    } else {
        if (!strncmp("escaped", t1->death, 7)) {
            Sprintf(eos(linebuf), "%s（最大到達 %d階）", deathbuf, t1->maxlvl);
        } else if (!strncmp("ascended", t1->death, 8)) {
            Strcat(linebuf, deathbuf);
        } else {
            Sprintf(eos(linebuf), "%s", deathbuf);

            if (t1->deathdnum == astral_level.dnum) {
                const char *fmt = "（%s）";

                switch (t1->deathlev) {
                case -5:
                    arg = "アストラル界";
                    break;
                case -4:
                    arg = "水の精霊界";
                    break;
                case -3:
                    arg = "火の精霊界";
                    break;
                case -2:
                    arg = "風の精霊界";
                    break;
                case -1:
                    arg = "地の精霊界";
                    break;
                default:
                    arg = "虚無";
                    break;
                }
                Sprintf(eos(linebuf), fmt, arg);
            } else {
                Sprintf(eos(linebuf), "（%s",
                        jp_dungeon_name_by_dnum(t1->deathdnum));
                if (t1->deathdnum != knox_level.dnum)
                    Sprintf(eos(linebuf), " %d階", t1->deathlev);
                if (t1->deathlev != t1->maxlvl)
                    Sprintf(eos(linebuf), ", 最大到達 %d階", t1->maxlvl);
                Strcat(linebuf, "）");
            }
        }
    }
    Strcat(linebuf, ".");

    lngr = topten_dispwidth(linebuf);
    if (t1->hp <= 0)
        hpbuf[0] = '-', hpbuf[1] = '\0';
    else
        Sprintf(hpbuf, "%d", t1->hp);
    /* beginning of hp column after padding (not actually padded yet) */
    hppos = COLNO - (int) (sizeof "  Hp [max]" - sizeof "");
    while (lngr >= hppos) {
        bp = topten_wrapsplit(linebuf, hppos);
        /* special case: if about to wrap in the middle of maximum
           dungeon depth reached, wrap in front of it instead */
        if (bp > linebuf + 5 && !strncmp(bp - 5, " [max", 5))
            bp -= 5;
        if (*bp != ' ')
            Strcpy(linebuf3, bp);
        else
            Strcpy(linebuf3, bp + 1);
        *bp = '\0';
        if (so) {
            while (bp < linebuf + (COLNO - 1))
                *bp++ = ' ';
            *bp = '\0';
            topten_print_bold(linebuf);
        } else
            topten_print(linebuf);
        Snprintf(linebuf, sizeof(linebuf), "%15s %s", "", linebuf3);
        lngr = topten_dispwidth(linebuf);
    }
    /* beginning of hp column not including padding */
    hppos = COLNO - 7 - (int) strlen(hpbuf);
    bp = eos(linebuf);

    if (topten_dispwidth(linebuf) <= hppos) {
        /* pad any necessary blanks to the hit point entry */
        while (topten_dispwidth(linebuf) < hppos)
            Strcat(linebuf, " ");
        bp = eos(linebuf);
        Strcpy(bp, hpbuf);
        Sprintf(eos(bp), " %s[%d]",
                (t1->maxhp < 10) ? "  " : (t1->maxhp < 100) ? " " : "",
                t1->maxhp);
    }

    if (so) {
        while (topten_dispwidth(linebuf) < (COLNO - 1))
            Strcat(linebuf, " ");
        topten_print_bold(linebuf);
    } else
        topten_print(linebuf);
}

RESTORE_WARNING_FORMAT_NONLITERAL

staticfn int
score_wanted(
    boolean current_ver,
    int rank,
    struct toptenentry *t1,
    int playerct,
    const char **players,
    int uid)
{
    const char *arg, *nxt;
    int i;

    if (current_ver && (t1->ver_major != VERSION_MAJOR
                        || t1->ver_minor != VERSION_MINOR
                        || t1->patchlevel != PATCHLEVEL))
        return 0;

    if (sysopt.pers_is_uid && !playerct && t1->uid == uid)
        return 1;

    /*
     * FIXME:
     *  This selection produces a union (OR) of criteria rather than
     *  an intersection (AND).  So
     *    nethack -s -u igor -p Cav -r Hum
     *  will list all entries for name igor regardless of role or race
     *  plus all entries for cave dwellers regardless of name or race
     *  plus all entries for humans regardless of name or role.
     *
     *  It would be more useful if it only chose human cave dwellers
     *  named igor.  That would be pretty straightforward if only one
     *  instance of each of the criteria were possible, but
     *    nethack -s -u igor -u ayn -p Cav -p Pri -r Hum -r Dwa
     *  should list human cave dwellers named igor and human cave
     *  dwellers named ayn plus dwarven cave dwellers named igor and
     *  dwarven cave dwellers named ayn plus human priest[esse]s named
     *  igor and human priest[esse]s named ayn (the combination of
     *  dwarven priest[esse]s doesn't occur but the selection can test
     *  entries without being aware of such; it just won't find any
     *  matches for that).  An extra initial pass of the command line
     *  to collect all criteria before testing any entry is needed to
     *  accomplish this.  And we might need to drop support for
     *  pre-3.3.0 entries (old elf role) depending on how the criteria
     *  matching is performed.
     *
     *  It also ought to extended to handle
     *    nethack -s -u igor-Cav-Hum
     *  Alignment and gender could be useful too but no one has ever
     *  clamored for them.  Presumably if they care they postprocess
     *  with some custom tool.
     */

    for (i = 0; i < playerct; i++) {
        arg = players[i];
        if (arg[0] == '-' && arg[1] == 'u' && arg[2] != '\0')
            arg += 2; /* handle '-uname' */

        if (arg[0] == '-' && strchr("pru", arg[1]) && !arg[2]
            && i + 1 < playerct) {
            nxt = players[i + 1];
            if ((arg[1] == 'p' && str2role(nxt) == str2role(t1->plrole))
                || (arg[1] == 'r' && str2race(nxt) == str2race(t1->plrace))
                /* handle '-u name' */
                || (arg[1] == 'u' && (!strcmp(nxt, "all")
                                      || !strncmp(t1->name, nxt, NAMSZ))))
                return 1;
            i++;
        } else if (!strcmp(arg, "all")
                   || !strncmp(t1->name, arg, NAMSZ)
                   || (arg[0] == '-' && arg[1] == t1->plrole[0] && !arg[2])
                   || (digit(arg[0]) && rank <= atoi(arg)))
            return 1;
    }
    return 0;
}

/*
 * print selected parts of score list.
 * argc >= 2, with argv[0] untrustworthy (directory names, et al.),
 * and argv[1] starting with "-s".
 * caveat: some shells might allow argv elements to be arbitrarily long.
 */
void
prscore(int argc, char **argv)
{
    const char **players, *player0;
    int i, playerct, rank;
    struct toptenentry *t1;
    FILE *rfile;
    char pbuf[BUFSZ], *p;
    unsigned ln;
    int uid = -1;
    boolean current_ver = TRUE, init_done = FALSE, match_found = FALSE;

    /* expect "-s" or "--scores"; "-s<anything> is accepted */
    ln = (argc < 2) ? 0U
         : ((p = strchr(argv[1], ' ')) != 0) ? (unsigned) (p - argv[1])
           : Strlen(argv[1]);
    if (ln < 2 || (strncmp(argv[1], "-s", 2)
                   && strcmp(argv[1], "--scores"))) {
        raw_printf("prscore: 引数が不正 (%d)", argc);
        return;
    }

    rfile = fopen_datafile(RECORD, "r", SCOREPREFIX);
    if (!rfile) {
        raw_print("スコア記録ファイルを開けない。");
        return;
    }

#ifdef AMIGA
    {
        extern winid amii_rawprwin;

        init_nhwindows(&argc, argv);
        amii_rawprwin = create_nhwindow(NHW_TEXT);
    }
#endif

    /* If the score list isn't after a game, we never went through
     * initialization. */
    if (wiz1_level.dlevel == 0) {
        dlb_init();
        init_dungeons();
        init_done = TRUE;
    }

    /* to get here, argv[1] either starts with "-s" or is "--scores" without
       trailing stuff; for "-s<anything>" treat <anything> as separate arg */
    if (argv[1][1] == '-' || !argv[1][2]) {
        argc--;
        argv++;
    } else { /* concatenated arg string; use up "-s" but keep argc,argv */
        argv[1] += 2;
    }
    /* -v doesn't take a version number arg; it means 'all versions present
       in the file' instead of the default of only the current version;
       unlike -s, we don't accept "-v<anything>" for non-empty <anything> */
    if (argc > 1 && !strcmp(argv[1], "-v")) {
        current_ver = FALSE;
        argc--;
        argv++;
    }

    if (argc <= 1) {
        if (sysopt.pers_is_uid) {
            uid = getuid();
            playerct = 0;
            players = (const char **) 0;
        } else {
            player0 = svp.plname;
            if (!*player0)
                player0 = "all"; /* if no plname[], show all scores
                                  * (possibly filtered by '-v') */
            playerct = 1;
            players = &player0;
        }
    } else {
        playerct = --argc;
        players = (const char **) ++argv;
    }
    raw_print("");

    t1 = tt_head = newttentry();
    *t1 = zerott; /* t0 と同様、構造体全体をゼロ初期化 */
    for (rank = 1; ; rank++) {
        readentry(rfile, t1);
        if (t1->points == 0)
            break;
        if (!match_found
            && score_wanted(current_ver, rank, t1, playerct, players, uid))
            match_found = TRUE;
        t1->tt_next = newttentry();
        *t1->tt_next = zerott; /* 新規ノードも同様にゼロ初期化 */
        t1 = t1->tt_next;
    }

    (void) fclose(rfile);
    if (init_done) {
        free_dungeons();
        dlb_cleanup();
    }

    if (match_found) {
        outheader();
        t1 = tt_head;
        for (rank = 1; t1->points != 0; rank++, t1 = t1->tt_next) {
            if (score_wanted(current_ver, rank, t1, playerct, players, uid))
                (void) outentry(rank, t1, FALSE);
        }
    } else {
        Sprintf(pbuf, "%s該当エントリが見つからない（条件: ",
                current_ver ? "現バージョンの" : "");
        if (playerct < 1) {
            Strcat(pbuf, "あなた");
        } else {
            /* minor bug: 'nethack -s -u ziggy' will say "any of"
               even though the '-u' doesn't indicate multiple names */
            if (playerct > 1)
                Strcat(pbuf, "いずれか ");
            for (i = 0; i < playerct; i++) {
                /* accept '-u name' and '-uname' as well as just 'name'
                   so skip '-u' for the none-found feedback */
                if (!strncmp(players[i], "-u", 2)) {
                    if (!players[i][2])
                        continue;
                    players[i] += 2;
                }
                /* stop printing players if there are too many to fit */
                if (strlen(pbuf) + strlen(players[i]) + 2 >= BUFSZ) {
                    if (strlen(pbuf) < BUFSZ - 4)
                        Strcat(pbuf, "...");
                    else
                        Strcpy(pbuf + strlen(pbuf) - 4, "...");
                    break;
                }
                Strcat(pbuf, players[i]);
                if (i < playerct - 1) {
                    if (players[i][0] == '-' && strchr("pr", players[i][1])
                        && players[i][2] == 0)
                        Strcat(pbuf, " ");
                    else
                        Strcat(pbuf, "、");
                }
            }
        }
        if (strlen(pbuf) < BUFSZ - 1)
            Strcat(pbuf, "）");
        /* append end-of-sentence punctuation if there is room */
        if (strlen(pbuf) < BUFSZ - 1)
            Strcat(pbuf, ".");
        raw_print(pbuf);
        raw_printf("使い方: %s -s [-v] <playertypes> [maxrank] [playernames]",
                   gh.hname);
        raw_printf("プレイヤー種別指定: [-p role] [-r race]");
    }
    free_ttlist(tt_head);
#ifdef AMIGA
    {
        extern winid amii_rawprwin;

        display_nhwindow(amii_rawprwin, 1);
        destroy_nhwindow(amii_rawprwin);
        amii_rawprwin = WIN_ERR;
    }
#endif
}

staticfn int
classmon(char *plch)
{
    int i;

    /* Look for this role in the role table */
    for (i = 0; roles[i].name.m; i++) {
        if (!strncmp(plch, roles[i].filecode, ROLESZ)) {
            if (roles[i].mnum != NON_PM)
                return roles[i].mnum;
            else
                return PM_HUMAN;
        }
    }
    /* this might be from a 3.2.x score for former Elf class */
    if (!strcmp(plch, "E"))
        return PM_RANGER;

    impossible("What weird role is this? (%s)", plch);
    return  PM_HUMAN_MUMMY;
}

/*
 * Get a random player name and class from the high score list,
 */
struct toptenentry *
get_rnd_toptenentry(void)
{
    int rank, i;
    FILE *rfile;
    struct toptenentry *tt;
    static struct toptenentry tt_buf;

    rfile = fopen_datafile(RECORD, "r", SCOREPREFIX);
    if (!rfile) {
        impossible("Cannot open record file!");
        return NULL;
    }

    tt = &tt_buf;
    rank = rnd(sysopt.tt_oname_maxrank);
 pickentry:
    for (i = rank; i; i--) {
        readentry(rfile, tt);
        if (tt->points == 0)
            break;
    }

    if (tt->points == 0) {
        if (rank > 1) {
            rank = 1;
            rewind(rfile);
            goto pickentry;
        }
        tt = NULL;
    }

    (void) fclose(rfile);
    return tt;
}


/*
 * Attach random player name and class from high score list
 * to an object (for statues or morgue corpses).
 */
struct obj *
tt_oname(struct obj *otmp)
{
    struct toptenentry *tt;
    if (!otmp)
        return (struct obj *) 0;

    tt = get_rnd_toptenentry();

    if (!tt)
        return (struct obj *) 0;

    set_corpsenm(otmp, classmon(tt->plrole));
    if (tt->plgend[0] == 'F')
        otmp->spe = CORPSTAT_FEMALE;
    else if (tt->plgend[0] == 'M')
        otmp->spe = CORPSTAT_MALE;
    otmp = oname(otmp, tt->name, ONAME_NO_FLAGS);

    return otmp;
}

/* Randomly select a topten entry to mimic */
int
tt_doppel(struct monst *mon) {
    struct toptenentry *tt = rn2(13) ? get_rnd_toptenentry() : NULL;
    int ret;

    if (!tt)
        ret = rn1(PM_WIZARD - PM_ARCHEOLOGIST + 1, PM_ARCHEOLOGIST);
    else {
        if (tt->plgend[0] == 'F')
            mon->female = 1;
        else if (tt->plgend[0] == 'M')
            mon->female = 0;
        ret = classmon(tt->plrole);
        /* Only take on a name if the player can see
           the doppelganger, otherwise we end up with
           named monsters spoiling the fun - Kes */
        if (canseemon(mon))
            christen_monst(mon, tt->name);
    }
    return ret;
}

#ifdef NO_SCAN_BRACK
/* Lattice scanf isn't up to reading the scorefile.  What */
/* follows deals with that; I admit it's ugly. (KL) */
/* Now generally available (KL) */
staticfn void
nsb_mung_line(p)
char *p;
{
    while ((p = strchr(p, ' ')) != 0)
        *p = '|';
}

staticfn void
nsb_unmung_line(p)
char *p;
{
    while ((p = strchr(p, '|')) != 0)
        *p = ' ';
}
#endif /* NO_SCAN_BRACK */

/*topten.c*/

