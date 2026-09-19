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
    "se_combat_hit_whip.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（鞭/しなり）",
        "keywords_ja": "鞭 ムチ ピシッ 打撃 しなり",
        "keywords_en": "whip hit lash crack strike leather whip",
    },
    "se_combat_hit_ironball.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（鉄球/鎖）",
        "keywords_ja": "鉄球 鎖 ガシャン 重金属 衝撃",
        "keywords_en": "iron ball chain heavy metal impact bash",
    },
    "se_combat_hit_shield.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（盾バッシュ）",
        "keywords_ja": "シールド 盾 防具 バッシュ ガゴン 打撃",
        "keywords_en": "shield bash metal shield heavy block hit",
    },
    "se_combat_hit_corpse.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（死体/肉塊）",
        "keywords_ja": "肉片 死体 ボコッ グチャ 生体 肉塊",
        "keywords_en": "corpse flesh meat smack squish blunt hit",
    },
    "se_combat_hit_pick.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（採掘具）",
        "keywords_ja": "つるはし マトック 採掘 ピッケル 岩石 キーン",
        "keywords_en": "pickaxe mattock mining pick stone hit clink",
    },
    "se_combat_hit_wand.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接（杖/ロッド）",
        "keywords_ja": "杖 ロッド 細い棒 コツッ カチッ 物理",
        "keywords_en": "wand staff light tap click stick hit",
    },
    "se_combat_hit_other.ogg": {
        "sub_category": "melee",
        "sub_category_ja": "近接/汎用（その他）",
        "keywords_ja": "物 打撃 ポンッ バシッ 雑多 アイテム",
        "keywords_en": "item hit generic smack object blunt light",
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
    "se_kick.ogg": {
        "sub_category": "action",
        "sub_category_ja": "アクション（キック）",
        "keywords_ja": "キック 蹴り 蹴る ドア 宝箱 モンスター ドカッ ボコッ",
        "keywords_en": "kick hit bash impact blunt attack door chest",
    },
    "se_stairs_up.ogg": {
        "sub_category": "movement",
        "sub_category_ja": "移動（階段上り）",
        "keywords_ja": "階段 はしご 上る 登る 足音 ステップ トントン",
        "keywords_en": "stairs climb up ladder footsteps ascent steps",
    },
    "se_stairs_down.ogg": {
        "sub_category": "movement",
        "sub_category_ja": "移動（階段下り）",
        "keywords_ja": "階段 はしご 降りる 下りる 足音 ステップ ドスン",
        "keywords_en": "stairs climb down ladder footsteps descent steps",
    },
}

BGM_DEFINITIONS = [
    # 2.1 ダンジョン分岐・特殊階層（フロア全体BGM: 32種）
    # 2.1.1 主要ダンジョン分岐
    {
        "filename": "amb_dungeon.ogg",
        "id": "amb_dungeon",
        "description": "運命の大迷宮（通常フロア）の環境BGM。暗く湿った地下迷宮の反響音。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ダンジョン 地下迷宮 アンビエント ダンジョンシンセ 暗闇",
        "keywords_en": "dungeon synth dark underground cavern dungeon ambient",
    },
    {
        "filename": "amb_mines.ogg",
        "id": "amb_mines",
        "description": "ノームの鉱山の環境BGM。ツルハシの遠い打撃音や岩盤の軋み。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "鉱山 洞窟 地下 ドワーフ つるはし 岩盤",
        "keywords_en": "dwarven mines cavern underground rock mining ambient",
    },
    {
        "filename": "amb_sokoban.ogg",
        "id": "amb_sokoban",
        "description": "倉庫番の環境BGM。パズルに集中できる静かで整然とした旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "倉庫番 パズル 思考 穏やか 静寂 神秘",
        "keywords_en": "puzzle peaceful calm ambient fantasy thinking mystery",
    },
    {
        "filename": "amb_quest.ogg",
        "id": "amb_quest",
        "description": "クエスト階層の環境BGM。各職業の試練にふさわしい緊張感ある音楽。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "クエスト 試練 冒険 ファンタジー 緊張 英雄",
        "keywords_en": "quest adventure epic tension fantasy trial synth",
    },
    {
        "filename": "amb_gehennom.ogg",
        "id": "amb_gehennom",
        "description": "ゲヘナ（地獄）の環境BGM。低く重苦しい唸り音、業火の気配。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "地獄 ゲヘナ 冥界 業火 邪悪 ダークアンビエント",
        "keywords_en": "hell gehenna dark ambient inferno underworld abyss evil",
    },
    {
        "filename": "amb_vlad.ogg",
        "id": "amb_vlad",
        "description": "ヴラドの塔の環境BGM。ゴシック調の冷徹で不気味な旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ヴラド 吸血鬼 ゴシック 城 パイプオルガン 不気味",
        "keywords_en": "vampire gothic horror castle organ dark synth vlad",
    },
    {
        "filename": "amb_ludios.ogg",
        "id": "amb_ludios",
        "description": "ルーディオス砦（Fort Ludios）のBGM。金塊と富に満ちた豪華な要塞の音楽。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "要塞 砦 財宝 金塊 豪華 行進曲",
        "keywords_en": "fortress fortress treasury gold castle royal march",
    },
    {
        "filename": "amb_tutorial.ogg",
        "id": "amb_tutorial",
        "description": "チュートリアル階層のBGM。初心者向けの穏やかで教導的な旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "チュートリアル 初心者 穏やか 旅立ち 平穏 アコースティック",
        "keywords_en": "tutorial beginner calm gentle acoustic adventure pleasant",
    },
    # 2.1.2 運命の大迷宮の特殊階層
    {
        "filename": "amb_oracle.ogg",
        "id": "amb_oracle",
        "description": "デルフィの神託所フロア（oracle）。全域に漂う神託の静寂と神秘的な気配。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "神託 預言 神秘 静寂 瞑想 デルフィ",
        "keywords_en": "oracle prophecy mystic ethereal ambient spiritual temple",
    },
    {
        "filename": "amb_rogue.ogg",
        "id": "amb_rogue",
        "description": "ローグ階層（rogue）。初代Rogueを彷彿とさせるレトロな8bitチップチューン調の旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ローグ レトロ 8bit チップチューン ピコピコ ダンジョン",
        "keywords_en": "8bit chiptune retro rogue classic rpg synth",
    },
    {
        "filename": "amb_bigroom.ogg",
        "id": "amb_bigroom",
        "description": "大部屋階層（bigrm）。見渡す限りの広大な空間に反響する不穏な風音。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "大部屋 広大 反響 虚無 不穏 風音",
        "keywords_en": "vast open chamber ominous echo dark ambient drone",
    },
    {
        "filename": "amb_medusa.ogg",
        "id": "amb_medusa",
        "description": "メデューサの島（medusa）。水に閉ざされた孤島、石化の恐怖を煽る緊迫した旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "メデューサ 孤島 石化 緊迫 毒蛇 恐怖",
        "keywords_en": "medusa snake island dread tension suspense dark",
    },
    {
        "filename": "amb_castle.ogg",
        "id": "amb_castle",
        "description": "城・要塞（castle / Stronghold）。跳ね橋、堀、ドラゴンの護衛が待ち受ける壮大かつ重厚な城塞BGM。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "城 要塞 城塞 壮大 重厚 跳ね橋 ドラゴン",
        "keywords_en": "castle stronghold epic heavy fortress dungeon synth",
    },
    # 2.1.3 各分岐ダンジョンの特殊階層
    {
        "filename": "amb_town.ogg",
        "id": "amb_town",
        "description": "ミナタウン（鉱山町 / minetn）。活気のある市場、寺院、居住区の喧騒。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "町 市場 酒場 活気 賑やか 中世 街",
        "keywords_en": "town village tavern market medieval folk lively",
    },
    {
        "filename": "amb_minend.ogg",
        "id": "amb_minend",
        "description": "鉱山最下層（minend）。鉱脈の最深部、眩い宝石の輝きと危険なモンスターの気配。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "鉱山最深部 宝石 輝き 危険 深層 洞窟",
        "keywords_en": "deep mines crystal gem dangerous cavern synth ambient",
    },
    {
        "filename": "amb_sokoend.ogg",
        "id": "amb_sokoend",
        "description": "倉庫番最上階（soko4）。難関パズルを突破した達成感と賞品部屋の清々しい旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "達成 清々しい 勝利 宝 報酬 安らぎ",
        "keywords_en": "triumph victory relief peaceful reward serene fantasy",
    },
    {
        "filename": "amb_quest_nemesis.ogg",
        "id": "amb_quest_nemesis",
        "description": "クエスト宿敵の階層（x-goal）。アーティファクトを奪還するためのボス決戦BGM。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ボス決戦 宿敵 最終決戦 激闘 オーケストラ 壮絶",
        "keywords_en": "boss battle nemesis epic combat dark orchestral showdown",
    },
    # 2.1.4 ゲヘナ・悪魔階層
    {
        "filename": "amb_valley.ogg",
        "id": "amb_valley",
        "description": "死の谷（valley）。ゲヘナの入口に広がるアンデッドの墓場。荒涼とした絶望の旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "死の谷 荒涼 絶望 墓場 アンデッド 悲哀",
        "keywords_en": "valley of the dead bleak desolate graveyard undead doom",
    },
    {
        "filename": "amb_juiblex.ogg",
        "id": "amb_juiblex",
        "description": "ジュピレクスの沼地（juiblex）。毒泥とスライムに覆われた腐敗と溶解の不気味な旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ジュピレクス スライム 沼 腐敗 溶解 悪魔",
        "keywords_en": "juiblex slime swamp ooze rot toxic acid demon dark",
    },
    {
        "filename": "amb_baalzebub.ogg",
        "id": "amb_baalzebub",
        "description": "ベルゼブブの住居（baalz）。蝿の王が支配する沼と不快な羽音の混じる悪魔的音楽。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ベルゼブブ 蝿の王 悪魔 羽音 沼 不快 邪悪",
        "keywords_en": "baalzebub lord of flies demon lord swamp insect evil dark",
    },
    {
        "filename": "amb_asmodeus.ogg",
        "id": "amb_asmodeus",
        "description": "アスモデウスの宮殿（asmodeus）。地獄の高位貴族にふさわしい威厳と邪悪に満ちた旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "アスモデウス 地獄 宮殿 悪魔 威厳 邪悪 貴族",
        "keywords_en": "asmodeus archdevil palace majestic infernal dark royal evil",
    },
    {
        "filename": "amb_orcus.ogg",
        "id": "amb_orcus",
        "description": "オルクスの町（orcus）。死霊の王オルクスが支配する廃墟の町。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "オルクス 死霊の王 廃墟 アンデッド 死霊 亡霊",
        "keywords_en": "orcus undead ruined city necromancy ghost wraith ambient",
    },
    {
        "filename": "amb_wizard_tower.ogg",
        "id": "amb_wizard_tower",
        "description": "イェンダーの魔法使いの塔（wizard1〜wizard3）。神秘的かつ狂気じみた実験棟の旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "イェンダー 魔法使いの塔 魔術 狂気 実験 迷宮",
        "keywords_en": "wizard tower yendor arcane madness laboratory sorcery synth",
    },
    {
        "filename": "amb_fakewiz.ogg",
        "id": "amb_fakewiz",
        "description": "偽の魔法使いの塔（fakewiz1, fakewiz2）。本物と酷似しつつも何かが欠落した不穏な音楽。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "偽魔法使い 塔 偽物 幻影 歪み 不気味 欺瞞",
        "keywords_en": "fake wizard illusion distorted mockery eerie dark synth",
    },
    {
        "filename": "amb_sanctum.ogg",
        "id": "amb_sanctum",
        "description": "モロクの聖所（sanctum）。モロクの高司祭が魔除けを守る最深聖域。冒涜的かつ荘厳な大聖堂の旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "モロク 聖所 聖域 大聖堂 冒涜 祭壇 終末",
        "keywords_en": "sanctum moloch cathedral dark chant profane high priest doom",
    },
    # 2.1.5 精霊界・エンドゲーム
    {
        "filename": "amb_plane_earth.ogg",
        "id": "amb_plane_earth",
        "description": "土の精霊界（earth）。迷路のような固い岩盤を掘り進む重低音の響き。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "土の精霊界 大地 岩盤 重低音 ドローン 振動",
        "keywords_en": "plane of earth stone cavern rumble deep bass drone elemental",
    },
    {
        "filename": "amb_plane_air.ogg",
        "id": "amb_plane_air",
        "description": "風の精霊界（air）。吹きすさぶ暴風と雷雲が渦巻く疾風の音楽。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "風の精霊界 暴風 疾風 雷雲 嵐 浮遊 空",
        "keywords_en": "plane of air storm whirlwind tempest thunder sky elemental",
    },
    {
        "filename": "amb_plane_fire.ogg",
        "id": "amb_plane_fire",
        "description": "火の精霊界（fire）。煮えたぎる灼熱の業火と紅蓮の旋律。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "火の精霊界 灼熱 業火 紅蓮 炎 溶岩 激動",
        "keywords_en": "plane of fire inferno blazing flame volcanic heat elemental",
    },
    {
        "filename": "amb_plane_water.ogg",
        "id": "amb_plane_water",
        "description": "水の精霊界（water）。漂う気泡と水中を彷徨う深海のような幻想的BGM。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "水の精霊界 水中 深海 気泡 幻想的 漂流",
        "keywords_en": "plane of water underwater deep ocean bubbles ambient floating",
    },
    {
        "filename": "amb_astral.ogg",
        "id": "amb_astral",
        "description": "アストラル界（astral）。3つの祭壇と黙示録の騎士たちが待ち受ける神聖かつ超越的な最終決戦BGM。",
        "caller": "get_dungeon_ambience (src/dungeon.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "アストラル界 昇天 最終決戦 神聖 黙示録 祭壇 壮大",
        "keywords_en": "astral plane celestial final battle epic sacred transcendence choir",
    },
    # 2.1.6 システム・ゲーム進行
    {
        "filename": "amb_title.ogg",
        "id": "amb_title",
        "description": "タイトル画面BGM。冒険の旅立ちを予感させるオープニングテーマ。",
        "caller": "TitleScreen / main.dart",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "タイトル オープニング 冒険 旅立ち ファンタジー メインテーマ",
        "keywords_en": "title theme opening adventure fantasy prologue heroic synth",
    },
    {
        "filename": "amb_gameover.ogg",
        "id": "amb_gameover",
        "description": "ゲームオーバー・昇天BGM。戦いを終えた冒険者に捧げる鎮魂曲（または勝利の讃歌）。",
        "caller": "outrip / topten (src/end.c)",
        "category": "bgm",
        "sub_category": "floor",
        "sub_category_ja": "フロアBGM",
        "keywords_ja": "ゲームオーバー 墓標 鎮魂曲 レクイエム 哀愁 昇天",
        "keywords_en": "game over requiem death sad tombstone memorial mournful",
    },

    # 2.2 自然・地形・天候環境音（5種）
    {
        "filename": "amb_water.ogg",
        "id": "amb_water",
        "description": "水辺・噴水の環境音。水が湧き出る音、せせらぎ。",
        "caller": "sound_ambience (src/sounds.c)",
        "category": "bgm",
        "sub_category": "ambience",
        "sub_category_ja": "環境音",
        "keywords_ja": "水音 せせらぎ 噴水 水流 滴り 川 環境音",
        "keywords_en": "water stream fountain trickle flowing splash water ambient",
    },
    {
        "filename": "amb_lava.ogg",
        "id": "amb_lava",
        "description": "溶岩地帯・火の精霊界の環境音。マグマの煮えたぎるボコボコという音。",
        "caller": "sound_ambience (src/sounds.c)",
        "category": "bgm",
        "sub_category": "ambience",
        "sub_category_ja": "環境音",
        "keywords_ja": "溶岩 マグマ 煮えたぎる 泡 火口 地熱 環境音",
        "keywords_en": "lava magma bubbling molten boiling volcano heat ambient",
    },
    {
        "filename": "amb_wind.ogg",
        "id": "amb_wind",
        "description": "風の精霊界・吹き抜け通路の環境音。吹きすさぶ突風の轟音。",
        "caller": "sound_ambience (src/sounds.c)",
        "category": "bgm",
        "sub_category": "ambience",
        "sub_category_ja": "環境音",
        "keywords_ja": "風 突風 隙間風 吹きすさぶ 通路 轟音 環境音",
        "keywords_en": "wind howling draft breeze gust blowing storm ambient",
    },
    {
        "filename": "amb_rain.ogg",
        "id": "amb_rain",
        "description": "雨天・天井からの水滴の環境音。絶え間ない滴りと湿気。",
        "caller": "sound_ambience (src/sounds.c)",
        "category": "bgm",
        "sub_category": "ambience",
        "sub_category_ja": "環境音",
        "keywords_ja": "雨 水滴 滴り 湿気 洞窟 雨音 環境音",
        "keywords_en": "rain dripping water drops damp cave moisture ambient",
    },
    {
        "filename": "amb_swamp.ogg",
        "id": "amb_swamp",
        "description": "沼地・ジュピレクス階層の環境音。腐敗した泥の気泡音、毒気の泡立ち。",
        "caller": "sound_ambience (src/sounds.c)",
        "category": "bgm",
        "sub_category": "ambience",
        "sub_category_ja": "環境音",
        "keywords_ja": "沼地 泥 気泡 湿地 湿原 毒気 泡 環境音",
        "keywords_en": "swamp marsh mud bubbles bog mire slimy ambient",
    },

    # 2.3 特別な部屋・施設（ルームBGM: 35種）
    # 2.3.1 伝統的な特別室・施設
    {
        "filename": "amb_in_a_shop.ogg",
        "id": "amb_in_a_shop",
        "description": "店内の音楽。店主の気配、小銭の触れ合う音、陳列棚のざわめき。",
        "caller": "check_room (src/shk.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "商店 店 買い物 商人 酒場 リュート アコースティック",
        "keywords_en": "shop merchant store medieval tavern market acoustic lute",
    },
    {
        "filename": "amb_inside_temple.ogg",
        "id": "amb_inside_temple",
        "description": "寺院内の音楽。荘厳なチャント（聖歌）、パイプオルガンの残響、鈴の音。",
        "caller": "check_room (src/priest.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "寺院 聖歌 チャント パイプオルガン 祈り 祭壇 荘厳",
        "keywords_en": "temple chant choir organ church sacred holy altar",
    },
    {
        "filename": "amb_inside_vault.ogg",
        "id": "amb_inside_vault",
        "description": "金庫室の音楽・環境音。密閉された石壁の完全な静寂と金貨の山。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "金庫室 宝物庫 金貨 静寂 財宝 密室",
        "keywords_en": "vault treasure chamber gold coins secure silence mysterious",
    },
    {
        "filename": "amb_approaching_oracle.ogg",
        "id": "amb_approaching_oracle",
        "description": "デルフィの神託所。瞑想を誘う神秘的な波動、澄んだチャイム音。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "神託所 預言者 瞑想 チャイム 神秘 澄んだ音",
        "keywords_en": "oracle mystic meditation bells chime sacred ethereal",
    },
    {
        "filename": "amb_in_a_court.ogg",
        "id": "amb_in_a_court",
        "description": "王座の間（宮廷）。優雅な宮廷音楽、トランペットのファンファーレ、貴族のざわめき。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "王座 玉座 宮廷 貴族 優雅 チェンバロ ファンファーレ",
        "keywords_en": "throne room royal court palace majestic regal harpsichord",
    },
    {
        "filename": "amb_in_a_barracks.ogg",
        "id": "amb_in_a_barracks",
        "description": "兵舎の音楽。兵士たちの軍靴の行進音、武器や鎧の擦れる音。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "兵舎 兵士 軍隊 行進 太鼓 鎧 武具",
        "keywords_en": "barracks soldiers military march drums garrison armed",
    },
    {
        "filename": "amb_in_a_zoo.ogg",
        "id": "amb_in_a_zoo",
        "description": "動物園（モンスター部屋）。様々な野獣の唸り声、咆哮、檻の軋み。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "動物園 モンスター部屋 野獣 咆哮 檻 不穏",
        "keywords_en": "monster zoo beasts growl cage dungeon creatures chaotic",
    },
    {
        "filename": "amb_in_a_beehive.ogg",
        "id": "amb_in_a_beehive",
        "description": "蜂の巣の部屋。無数の巨大蜂が飛び交うブーンという不穏な羽音の調べ。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "蜂の巣 蜂 ハチ 羽音 昆虫 ブーン 不気味",
        "keywords_en": "beehive buzzing wasps bees insect swarm hive drone",
    },
    {
        "filename": "amb_inside_anthole.ogg",
        "id": "amb_inside_anthole",
        "description": "蟻塚の部屋。無数の巨大蟻が壁を這い回るカサカサという足音の調べ。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "蟻塚 アリ 巨大蟻 這う カサカサ 巣穴 昆虫",
        "keywords_en": "anthole ant colony crawling insect nest chitin swarm",
    },
    {
        "filename": "amb_inside_leprehall.ogg",
        "id": "amb_inside_leprehall",
        "description": "レプラコーンの広間。陽気で小気味よいアイリッシュジグ、硬貨を数える音、いたずらっぽい忍び笑い。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "レプラコーン 妖精 アイリッシュ ジグ 陽気 硬貨 軽快",
        "keywords_en": "leprechaun irish jig celtic lively folk whistle playful",
    },
    {
        "filename": "amb_in_a_morgue.ogg",
        "id": "amb_in_a_morgue",
        "description": "死体置き場。冷え切った空気、腐臭、死霊の囁き、石棺のきしみ。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "死体置き場 遺体 冷気 石棺 死霊 囁き ホラー",
        "keywords_en": "morgue mortuary cold dead sarcophagus horror dark ambient",
    },
    {
        "filename": "amb_in_cemetery.ogg",
        "id": "amb_in_cemetery",
        "description": "墓地（死者の部屋）。夜風のうめき声、墓石の陰から聞こえる微かな怨嗟。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "墓地 墓場 墓石 怨嗟 夜風 亡霊 ゴースト",
        "keywords_en": "cemetery graveyard tomb ghostly eerie wind haunted",
    },
    {
        "filename": "amb_in_a_cockatrice_nest.ogg",
        "id": "amb_in_a_cockatrice_nest",
        "description": "コカトリスの巣。石化の気配、乾燥した鱗の擦れる不気味な旋律。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "コカトリス 石化 鱗 蛇 巣 不気味 緊張",
        "keywords_en": "cockatrice petrification scales serpent nest dread eerie",
    },
    {
        "filename": "amb_in_a_lemure_pit.ogg",
        "id": "amb_in_a_lemure_pit",
        "description": "レムレースの穴。地獄の亡者たちの絶え間ない苦痛の呻きと叫びの旋律。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "レムレース 亡者 苦痛 呻き 叫び 地獄 穴",
        "keywords_en": "lemure pit agony torment wailing souls infernal suffering",
    },
    {
        "filename": "amb_in_a_migot_nest.ogg",
        "id": "amb_in_a_migot_nest",
        "description": "ミ＝ゴの巣。異形の羽音、理解不能な宇宙的テレパシーノイズ。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "ミゴ クトゥルフ 異形 宇宙的 狂気 羽音 ノイズ",
        "keywords_en": "mi-go lovecraftian cosmic horror alien hive weird drone",
    },
    {
        "filename": "amb_in_a_black_market.ogg",
        "id": "amb_in_a_black_market",
        "description": "闇市の音楽。怪しげな密売人たちの囁き、違法取引の喧騒。",
        "caller": "check_room (src/shk.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "闇市 密売 違法 怪しい 酒場 アングラ 地下市場",
        "keywords_en": "black market smuggler shady underground bazaar stealth",
    },
    {
        "filename": "amb_in_swamp_room.ogg",
        "id": "amb_in_swamp_room",
        "description": "沼地部屋の音楽。淀んだ泥水のぬかるみ、不穏な泡立ちと湿地帯の気配。",
        "caller": "check_room (src/sounds.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "沼地 泥 淀み 湿原 湿地 ぬかるみ 不穏",
        "keywords_en": "swamp room marsh murky bog stagnant water damp",
    },
    # 2.3.2 NetHack 5.0 テーマ部屋
    {
        "filename": "amb_theme_nymph_garden.ogg",
        "id": "amb_theme_nymph_garden",
        "description": "ニンフの園（Garden）。魅惑的で穏やかな竪琴の調べ、妖精の寝息やささやき、噴水のせせらぎ。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "ニンフ 妖精 庭園 竪琴 ハープ 魅惑 穏やか",
        "keywords_en": "nymph garden fairy enchanting harp serene fountain magical",
    },
    {
        "filename": "amb_theme_spider_nest.ogg",
        "id": "amb_theme_spider_nest",
        "description": "蜘蛛の巣窟（Spider nest）。無数の蜘蛛が糸を張り巡らせる音、壁を這い回る不気味なカサカサ音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "蜘蛛 蜘蛛の巣 巣窟 糸 不気味 這い回る 虫",
        "keywords_en": "spider nest web arachnid crawling creep dark ambient",
    },
    {
        "filename": "amb_theme_ice_room.ogg",
        "id": "amb_theme_ice_room",
        "description": "氷の部屋（Ice room）。凍てつく寒風の吹きすさぶ音、氷が軋んで割れる音、冷気の残響。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "氷 凍結 冷気 寒風 吹雪 氷窟 クリスタル",
        "keywords_en": "ice room frozen frost cold wind crystal chill ambient",
    },
    {
        "filename": "amb_theme_cloud_room.ogg",
        "id": "amb_theme_cloud_room",
        "description": "雲・霧の部屋（Cloud room）。濃霧が立ち込める深い静寂、シューと噴き出す蒸気やガス雲の音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "雲 霧 濃霧 蒸気 静寂 幻想的 浮遊",
        "keywords_en": "cloud room fog mist vapor steam eerie floating ambient",
    },
    {
        "filename": "amb_theme_boulder_room.ogg",
        "id": "amb_theme_boulder_room",
        "description": "巨石の部屋（Boulder room）。ゴロゴロと重く転がる巨大岩の地響き、落石の軋み。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "巨石 岩 地響き 落石 重低音 採石",
        "keywords_en": "boulder stone rocks heavy rumbling cave quarry",
    },
    {
        "filename": "amb_theme_trap_room.ogg",
        "id": "amb_theme_trap_room",
        "description": "トラップ部屋（Trap room）。カチリと作動する微かな機械歯車の回転音、張り詰めた緊張感。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "トラップ 罠 歯車 機械 緊迫 仕掛け 時計",
        "keywords_en": "trap room mechanical gears clockwork tension suspense stealth",
    },
    {
        "filename": "amb_theme_buried_treasure.ogg",
        "id": "amb_theme_buried_treasure",
        "description": "埋没財宝の部屋（Buried treasure）。地下深くから漂う金属的な金貨の共鳴、宝箱の鍵が軋む微かな音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "埋没財宝 隠し宝 宝箱 金貨 鍵 神秘 輝き",
        "keywords_en": "buried treasure hidden gold chest glittering mystery loot",
    },
    {
        "filename": "amb_theme_buried_zombies.ogg",
        "id": "amb_theme_buried_zombies",
        "description": "蠢く土葬室（Buried zombies）。土中から聞こえる爪で土を掻き分ける音、蘇生しつつある死者の呻き。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "ゾンビ 土葬 死者 蠢く 蘇生 呻き ホラー",
        "keywords_en": "buried zombies undead awakening dirt crawling grave horror",
    },
    {
        "filename": "amb_theme_massacre.ogg",
        "id": "amb_theme_massacre",
        "description": "大虐殺跡（Massacre）。血生臭い風音、死霊たちの無念の怨嗟、飛び交うハエの羽音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "虐殺 惨劇 怨嗟 血風 死屍累々 絶望 悲壮",
        "keywords_en": "massacre slaughter battlefield bloodshed sorrow grim dark",
    },
    {
        "filename": "amb_theme_statuary.ogg",
        "id": "amb_theme_statuary",
        "description": "彫像展示室（Statuary）。冷徹な石像が並ぶ静けさ、時折石像が視線を向けたかのような石の擦れる音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "彫像 石像 像 ギャラリー 静寂 冷徹 視線",
        "keywords_en": "statues statuary museum gallery silent cold stone watchful",
    },
    {
        "filename": "amb_theme_light_source.ogg",
        "id": "amb_theme_light_source",
        "description": "暗闇の灯火（Light source）。パチパチと静かに爆ぜる油灯の炎の音、温かな光の気配。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "灯火 ランプ 篝火 温かい 光 炎 安らぎ キャンドル",
        "keywords_en": "light campfire lamp flame candle warmth peaceful cozy",
    },
    {
        "filename": "amb_theme_temple_of_the_gods.ogg",
        "id": "amb_theme_temple_of_the_gods",
        "description": "三神の合祀殿（Temple of the gods）。秩序・中立・混沌の相反する聖歌や詠唱が重なり合う神聖かつ不穏な響き。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "合祀殿 三神 神々 聖歌 詠唱 秩序 混沌 荘厳",
        "keywords_en": "pantheon gods temple sacred chant chaos order divine choir",
    },
    {
        "filename": "amb_theme_ghost_adventurer.ogg",
        "id": "amb_theme_ghost_adventurer",
        "description": "冒険者の亡霊（Ghost of an Adventurer）。かつての冒険者の悲哀に満ちたため息、金属鎧の揺れる音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "冒険者の亡霊 亡霊 幽霊 悲哀 ため息 鎧 追憶",
        "keywords_en": "ghost adventurer phantom spirit sorrowful armor regret haunt",
    },
    {
        "filename": "amb_theme_storeroom.ogg",
        "id": "amb_theme_storeroom",
        "description": "物置部屋・ミミックの罠（Storeroom）。無数の木箱の匂い、ミミックが蠢くわずかなネバネバした擬態音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "物置 木箱 倉庫 ミミック 擬態 罠 潜伏",
        "keywords_en": "storeroom warehouse crates mimic lurk creeping trap",
    },
    {
        "filename": "amb_theme_teleport_hub.ogg",
        "id": "amb_theme_teleport_hub",
        "description": "テレポート中枢室（Teleportation hub）。空間の歪みが生み出す電子音のようなハム音、次元のさざ波。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "テレポート 転移 次元 空間の歪み パルス 電子音 ポータル",
        "keywords_en": "teleport portal dimension warp cosmic pulse sci-fi fantasy",
    },
    {
        "filename": "amb_theme_mausoleum.ogg",
        "id": "amb_theme_mausoleum",
        "description": "霊廟（Mausoleum）。重い石棺の隙間から漏れる冷たい隙間風、アンデッドの不穏な気配。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "霊廟 石棺 墓 隙間風 アンデッド 不穏 厳粛",
        "keywords_en": "mausoleum tomb crypt crypts undead chilly stone draft",
    },
    {
        "filename": "amb_theme_pillars.ogg",
        "id": "amb_theme_pillars",
        "description": "列柱の間（Pillars）。整然と立ち並ぶ巨大な柱の陰から反響する足音、厳粛な回廊の響き。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "列柱 柱 回廊 大広間 反響 厳粛 神殿",
        "keywords_en": "pillars colonnade ancient hall stone columns solemn echo",
    },
    {
        "filename": "amb_theme_fake_delphi.ogg",
        "id": "amb_theme_fake_delphi",
        "description": "偽神託所（Fake Delphi）。不自然に静まり返った室内、神託所のものとは微かに異なる歪んだチャイム音。",
        "caller": "check_special_room (src/hack.c)",
        "category": "bgm",
        "sub_category": "room",
        "sub_category_ja": "ルームBGM",
        "keywords_ja": "偽神託所 偽物 歪み 偽チャイム 偽預言 違和感 不穏",
        "keywords_en": "fake delphi false oracle distorted eerie discordant mystery",
    },
]

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

    # BGM定義を末尾に連番で追加（No.317〜388）
    start_no = len(items) + 1
    for idx, bgm_item in enumerate(BGM_DEFINITIONS):
        item_copy = dict(bgm_item)
        item_copy["no"] = start_no + idx
        items.append(item_copy)

    output_path = root / "sound_definitions.json"
    output_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"成功: {len(items)} 件のサウンド定義を {output_path} に書き出しました。")

    from collections import Counter
    counts = Counter(item["category"] for item in items)
    for cat, count in counts.items():
        print(f" - {cat}: {count} 件")
    sub_counts = Counter(item.get("sub_category") for item in items if item["category"] == "bgm")
    print(" [BGM 内訳]")
    for sub, count in sub_counts.items():
        print(f"   * {sub}: {count} 件")

if __name__ == "__main__":
    main()

