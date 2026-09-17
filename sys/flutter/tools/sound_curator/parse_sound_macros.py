#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sound_macros_list.md を解析し、全274音の構造化メタデータを sound_definitions.json に出力するスクリプト。
"""

import json
from pathlib import Path

COMBAT_METADATA = {
    "se_combat_hit_slash.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（斬撃）",
        "keywords_ja": "斬撃 剣 刀 斧 攻撃",
        "keywords_en": "sword slash blade cut hit attack",
    },
    "se_combat_hit_blunt.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（打撃）",
        "keywords_ja": "打撃 鈍器 メイス 棍棒 殴る",
        "keywords_en": "blunt hit mace club strike punch smack",
    },
    "se_combat_hit_pierce.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（刺突）",
        "keywords_ja": "刺突 槍 突き 短剣 刺す",
        "keywords_en": "pierce spear stab thrust dagger jab",
    },
    "se_combat_hit_unarmed.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（素手/格闘）",
        "keywords_ja": "素手 格闘 パンチ キック 殴打",
        "keywords_en": "punch fist kick unarmed melee hit combat",
    },
    "se_combat_miss.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（空振り）",
        "keywords_ja": "風切り音 空振り 武器 振る ヒュッ",
        "keywords_en": "whoosh swing miss weapon swoosh air",
    },
    "se_combat_shoot_bow.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（弓発射）",
        "keywords_ja": "弓 矢 発射 射撃 弦 ビュン",
        "keywords_en": "bow arrow shoot release arrow shot",
    },
    "se_combat_shoot_crossbow.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（クロスボウ）",
        "keywords_ja": "クロスボウ ボウガン 発射 カシュッ 機械",
        "keywords_en": "crossbow bolt shoot mechanical trigger launch",
    },
    "se_combat_shoot_sling.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（スリング）",
        "keywords_ja": "スリング 投石器 投石 ヒュルッ 旋回",
        "keywords_en": "sling stone sling throw shot whirl bullet",
    },
    "se_combat_throw.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（一般投擲）",
        "keywords_ja": "投擲 投げる 物 手投げ ビュッ",
        "keywords_en": "throw toss weapon throw object whoosh",
    },
    "se_combat_throw_boomerang.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（ブーメラン）",
        "keywords_ja": "ブーメラン 投擲 回転 風切り ヒュンヒュン",
        "keywords_en": "boomerang throw spinning whirr swoosh",
    },
    "se_combat_throw_mjollnir.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（ミョルニル）",
        "keywords_ja": "ハンマー 投擲 雷 電撃 豪快 神聖",
        "keywords_en": "hammer throw lightning thunder heavy strike",
    },
    "se_combat_miss_thud.ogg": {
        "sub_category": "ranged",
        "sub_category_ja": "遠隔（外れ衝突）",
        "keywords_ja": "衝突 矢 壁 床 落ちる バシッ コツッ",
        "keywords_en": "thud arrow hit wall impact ground miss bounce",
    },
    "se_combat_spell_cast.ogg": {
        "sub_category": "magic",
        "sub_category_ja": "魔法（呪文詠唱）",
        "keywords_ja": "呪文 魔法 詠唱 発動 魔力 キィン",
        "keywords_en": "magic spell cast aura arcane energy",
    },
    "se_combat_wand_zap.ogg": {
        "sub_category": "magic",
        "sub_category_ja": "魔法（杖発動）",
        "keywords_ja": "杖 ワンド 発射 光線 ビビッ ピシュッ",
        "keywords_en": "magic wand zap beam ray laser spark",
    },
    "se_mon_claw.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（爪）",
        "keywords_ja": "モンスター 爪 ひっかき 引き裂き シャッ 獣",
        "keywords_en": "monster claw slash scratch beast beastly",
    },
    "se_mon_bite.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（噛みつき）",
        "keywords_ja": "噛む 噛みつき 牙 ガブッ モンスター 肉",
        "keywords_en": "monster bite chomp beast teeth jaws crunch",
    },
    "se_mon_sting.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（毒針）",
        "keywords_ja": "毒針 刺す チクッ サソリ 蜂 針",
        "keywords_en": "sting stinger insect scorpion wasp prick pierce",
    },
    "se_mon_butt.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（角/頭突き）",
        "keywords_ja": "頭突き 角 突進 ゴスッ 雄牛 衝突",
        "keywords_en": "headbutt horn ram blunt bash charge bull",
    },
    "se_mon_touch.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（接触/麻痺）",
        "keywords_ja": "霊体 触れる 接触 麻痺 不気味 ゾクッ ゴースト",
        "keywords_en": "ghostly touch paralyze eerie chill phantom undead",
    },
    "se_mon_tentacle.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（触手）",
        "keywords_ja": "触手 ヌチャッ 絡みつき クラーケン 吸血",
        "keywords_en": "tentacle squish slimy whip suction monster",
    },
    "se_mon_kick.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（蹴り/蹄）",
        "keywords_ja": "蹴り 蹄 ドカッ 馬 キック 踏みつけ",
        "keywords_en": "hoof kick horse beast stomp donkey heavy",
    },
    "se_mon_hug.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（締めつけ）",
        "keywords_ja": "締め付け 抱き締め 怪力 圧迫 メキッ ギシッ クマ",
        "keywords_en": "bear hug crush squeeze constrict squeeze bone",
    },
    "se_mon_gaze.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（視線/凝視）",
        "keywords_ja": "視線 凝視 魔眼 石化 キィーーン 催眠",
        "keywords_en": "evil gaze stare petrify eye psychic hypnosis",
    },
    "se_mon_engulf.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（丸呑み）",
        "keywords_ja": "丸呑み 呑み込み ゴクッ スライム 捕食",
        "keywords_en": "engulf swallow gulp digest slime stomach absorb",
    },
    "se_mon_breath.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（ブレス）",
        "keywords_ja": "ドラゴン ブレス 息吹 ゴォォッ 火炎 咆哮 炎",
        "keywords_en": "dragon breath roar fire blast exhale flame",
    },
    "se_mon_spit.ogg": {
        "sub_category": "monster",
        "sub_category_ja": "モンスター（吐出/毒液）",
        "keywords_ja": "毒液 酸 吐く 唾 飛沫 ピュッ ジュッ コブラ",
        "keywords_en": "spit acid venom liquid squirt snake hiss",
    },
}

def parse_sound_macros(md_path: Path) -> list:
    content = md_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    current_category = "effect"
    sub_category = ""
    items = []

    for line in lines:
        line_str = line.strip()
        if not line_str:
            continue

        if line_str.startswith("### 1-A."):
            current_category = "effect"
            sub_category = "Soundeffect"
            continue
        elif line_str.startswith("### 1-B."):
            current_category = "achievement"
            sub_category = "Achievement"
            continue
        elif line_str.startswith("#### 1-B-i."):
            current_category = "achievement"
            sub_category = "SystemEvent"
            continue
        elif line_str.startswith("#### 1-B-ii."):
            current_category = "achievement"
            sub_category = "GameAchievement"
            continue
        elif line_str.startswith("#### 1-C.") or line_str.startswith("### 1-C."):
            current_category = "instrument"
            sub_category = "HeroPlaynotes"
            continue
        elif line_str.startswith("#### 音階バリエーションあり楽器"):
            current_category = "instrument"
            sub_category = "VariablePitch"
            continue
        elif line_str.startswith("#### 固定演奏楽器"):
            current_category = "instrument"
            sub_category = "FixedPitch"
            continue
        elif line_str.startswith("### 1-D."):
            current_category = "voice"
            sub_category = "SetVoice"
            continue
        elif line_str.startswith("## 第2部"):
            break

        if line_str.startswith("|") and not line_str.startswith("| No.") and not line_str.startswith("| :---"):
            cols = [c.strip() for c in line_str.split("|")[1:-1]]
            if len(cols) >= 5:
                no_str = cols[0]
                filename = cols[1].strip("` ")
                sound_id = cols[2].strip("` ")
                desc = cols[3]
                caller = cols[4]

                if not filename.endswith(".ogg"):
                    continue

                cat = current_category
                sub_cat = sub_category
                sub_cat_ja = ""
                kw_ja = ""
                kw_en = ""

                # 戦闘効果音の特別判定
                if filename in COMBAT_METADATA:
                    cat = "combat"
                    meta = COMBAT_METADATA[filename]
                    sub_cat = meta["sub_category"]
                    sub_cat_ja = meta["sub_category_ja"]
                    kw_ja = meta["keywords_ja"]
                    kw_en = meta["keywords_en"]

                items.append({
                    "no": int(no_str) if no_str.isdigit() else len(items) + 1,
                    "filename": filename,
                    "id": sound_id,
                    "description": desc,
                    "caller": caller,
                    "category": cat,
                    "sub_category": sub_cat,
                    "sub_category_ja": sub_cat_ja,
                    "keywords_ja": kw_ja,
                    "keywords_en": kw_en
                })

    return items

def main():
    root = Path(__file__).resolve().parent
    md_path = root.parent.parent / "doc" / "sound_macros_list.md"
    if not md_path.exists():
        md_path = Path("sys/flutter/doc/sound_macros_list.md")
    
    items = parse_sound_macros(md_path)
    output_path = root / "sound_definitions.json"
    output_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"成功: {len(items)} 件のサウンド定義を {output_path} に書き出しました。")

    from collections import Counter
    counts = Counter(item["category"] for item in items)
    for cat, count in counts.items():
        print(f" - {cat}: {count} 件")

if __name__ == "__main__":
    main()
