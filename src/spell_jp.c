/* Modified by NetHackJP contributor @satokiyon; latest change date: 2026-05-22. */
/* NetHack 5.0	spell_jp.c */
/* Display-only Japanese labels for spells.
 * Keep internal spell IDs and English object keys unchanged.
 */

#include "hack.h"

static const char *const spell_jp_names[NUM_OBJECTS + 1] = {
    [SPE_DIG] = "穴掘り",
    [SPE_MAGIC_MISSILE] = "マジックミサイル",
    [SPE_FIREBALL] = "火の玉",
    [SPE_CONE_OF_COLD] = "冷気",
    [SPE_SLEEP] = "眠り",
    [SPE_FINGER_OF_DEATH] = "死の指",
    [SPE_LIGHT] = "灯り",
    [SPE_DETECT_MONSTERS] = "怪物探知",
    [SPE_HEALING] = "回復",
    [SPE_KNOCK] = "開錠",
    [SPE_FORCE_BOLT] = "衝撃",
    [SPE_CONFUSE_MONSTER] = "混乱",
    [SPE_CURE_BLINDNESS] = "盲目治療",
    [SPE_DRAIN_LIFE] = "生命吸収",
    [SPE_SLOW_MONSTER] = "減速",
    [SPE_WIZARD_LOCK] = "施錠",
    [SPE_CREATE_MONSTER] = "怪物創造",
    [SPE_DETECT_FOOD] = "食料探知",
    [SPE_CAUSE_FEAR] = "恐怖",
    [SPE_CLAIRVOYANCE] = "千里眼",
    [SPE_CURE_SICKNESS] = "病気治療",
    [SPE_CHARM_MONSTER] = "魅了",
    [SPE_HASTE_SELF] = "加速",
    [SPE_DETECT_UNSEEN] = "不可視探知",
    [SPE_LEVITATION] = "浮遊",
    [SPE_EXTRA_HEALING] = "超回復",
    [SPE_RESTORE_ABILITY] = "能力回復",
    [SPE_INVISIBILITY] = "透明化",
    [SPE_DETECT_TREASURE] = "宝探知",
    [SPE_REMOVE_CURSE] = "解呪",
    [SPE_MAGIC_MAPPING] = "地図化",
    [SPE_IDENTIFY] = "識別",
    [SPE_TURN_UNDEAD] = "アンデッド退散",
    [SPE_POLYMORPH] = "変化",
    [SPE_TELEPORT_AWAY] = "テレポート",
    [SPE_CREATE_FAMILIAR] = "使い魔創造",
    [SPE_CANCELLATION] = "無力化",
    [SPE_PROTECTION] = "防護",
    [SPE_JUMPING] = "跳躍",
    [SPE_STONE_TO_FLESH] = "石化解除",
    [SPE_CHAIN_LIGHTNING] = "連鎖雷撃",
    [SPE_BLANK_PAPER] = "白紙",
};

const char *
jp_spellname_for_display(int spell_otyp)
{
    if (spell_otyp >= 0 && spell_otyp < NUM_OBJECTS
        && spell_jp_names[spell_otyp])
        return spell_jp_names[spell_otyp];

    if (spell_otyp >= 0 && spell_otyp < NUM_OBJECTS
        && OBJ_NAME(objects[spell_otyp]))
        return OBJ_NAME(objects[spell_otyp]);

    return "";
}

