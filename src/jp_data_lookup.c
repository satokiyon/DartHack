/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-01. */
/* NetHack 5.0	jp_data_lookup.c */
/* Japanese aliases for data.base lookup.
 * Keep data.base keys in English and only map player input for lookup.
 */

#include "hack.h"

struct jp_data_lookup_alias {
    const char *jp_key;
    const char *en_key;
};

/* Minimal seed dictionary: keep small and grow based on real misses. */
static const struct jp_data_lookup_alias jp_data_lookup_aliases[] = {
    { "カイダン", "stair" },
    { "かいだん", "stair" },
    { "カイダンノボリ", "stair" },
    { "かいだんのぼり", "stair" },
    { "カイダンクダリ", "stair" },
    { "かいだんくだり", "stair" },
    { "ノボリカイダン", "stair" },
    { "のぼりかいだん", "stair" },
    { "クダリカイダン", "stair" },
    { "くだりかいだん", "stair" },
    { "ハシゴ", "stair" },
    { "はしご", "stair" },
    { "ノボリハシゴ", "stair" },
    { "のぼりはしご", "stair" },
    { "クダリハシゴ", "stair" },
    { "くだりはしご", "stair" },
    { "梯子", "stair" },
    { "上りはしご", "stair" },
    { "下りはしご", "stair" },
    { "ドア", "door" },
    { "どあ", "door" },
    { "トビラ", "door" },
    { "とびら", "door" },
    { "モン", "door" },
    { "もん", "door" },
    { "イリグチ", "doorway" },
    { "いりぐち", "doorway" },
    { "入口", "doorway" },
    { "入り口", "doorway" },
    { "出入口", "doorway" },
    { "出入り口", "doorway" },
    { "でいりぐち", "doorway" },
    { "トグチ", "doorway" },
    { "とぐち", "doorway" },
    { "カイタトビラ", "door" },
    { "あいたとびら", "door" },
    { "トジタトビラ", "door" },
    { "とじたとびら", "door" },
    { "開いた扉", "door" },
    { "閉じた扉", "door" },
    { "キ", "tree" },
    { "き", "tree" },
    { "イズミ", "fountain" },
    { "いずみ", "fountain" },
    { "センスイ", "fountain" },
    { "せんすい", "fountain" },
    { "フンスイ", "fountain" },
    { "ふんすい", "fountain" },
    { "噴水", "fountain" },
    { "サイダン", "altar" },
    { "さいだん", "altar" },
    { "ギョクザ", "throne" },
    { "ぎょくざ", "throne" },
    { "ハカ", "grave" },
    { "はか", "grave" },
    { "ヒョウ", "ice" },
    { "ひょう", "ice" },
    { "ヨウガン", "lava" },
    { "ようがん", "lava" },
    { "ラバ", "lava" },
    { "らば", "lava" },
    { "クモ", "cloud" },
    { "くも", "cloud" },
    { "クラウド", "cloud" },
    { "くらうど", "cloud" },
    { "ウン", "cloud" },
    { "うん", "cloud" },
    { "テッコウシ", "iron bars" },
    { "てっこうし", "iron bars" },
    { "テッゴウシ", "iron bars" },
    { "てっごうし", "iron bars" },
    { "てつごうし", "iron bars" },
    { "テツコウシ", "iron bars" },
    { "テツゴウシ", "iron bars" },
    { "鉄こうし", "iron bars" },
    { "鉄ごうし", "iron bars" },
    { "ミズ", "water" },
    { "みず", "water" },
    { "ウォーター", "water" },
    { "うぉーたー", "water" },
    { "階段", "stair" },
    { "上階段", "stair" },
    { "下階段", "stair" },
    { "階段上り", "stair" },
    { "階段下り", "stair" },
    { "上り階段", "stair" },
    { "下り階段", "stair" },
    { "扉", "door" },
    { "戸口", "doorway" },
    { "木", "tree" },
    { "墓石", "grave" },
    { "ぼせき", "grave" },
    { "泉", "fountain" },
    { "祭壇", "altar" },
    { "玉座", "throne" },
    { "墓", "grave" },
    { "氷", "ice" },
    { "溶岩", "lava" },
    { "雲", "cloud" },
    { "水", "water" },
    { "鉄格子", "iron bars" },
};

staticfn boolean
jp_data_lookup_has_nonascii(const char *s)
{
    while (*s) {
        if (((uchar) *s) & 0x80U)
            return TRUE;
        ++s;
    }
    return FALSE;
}

staticfn void
jp_data_lookup_normalize(char *s)
{
    utf8_hiragana_to_katakana(s);
    (void) mungspaces(s);
}

boolean
jp_data_lookup_key_from_japanese(const char *input, char *out, size_t outsz)
{
    char normalized[BUFSZ];
    const char *key;
    int i;

    if (!input || !*input || !out || outsz == 0)
        return FALSE;
    if (!jp_data_lookup_has_nonascii(input))
        return FALSE;

    strncpy(normalized, input, sizeof normalized - 1);
    normalized[sizeof normalized - 1] = '\0';
    jp_data_lookup_normalize(normalized);
    key = trimspaces(normalized);
    if (!*key)
        return FALSE;

    for (i = 0; i < SIZE(jp_data_lookup_aliases); ++i) {
        if (!strcmp(key, jp_data_lookup_aliases[i].jp_key)) {
            strncpy(out, jp_data_lookup_aliases[i].en_key, outsz - 1);
            out[outsz - 1] = '\0';
            return TRUE;
        }
    }
    return FALSE;
}
