# NetHack 5.0 / DartHack サウンドマスター管理仕様書 & 呼び出し一覧

本書は、NetHack 5.0 Cコア（`c_core/nethack_jp`）から呼び出される効果音・音楽・音声の全イベント仕様書です。
DartHack（Flutter/FFI環境）で再生する **全 `.ogg` (Opus) 音声ファイルのマスターチェックリスト（全 321 種）**、および **Cコアソースコード内の全 394 箇所呼び出し対照表** で構成されています。

> **戦闘アクション効果音の詳細仕様書**:
> 戦闘系効果音（No.204〜236：近接、遠隔、呪文、杖、モンスター固有攻撃12種、特徴的アイテム・フォールバック音など計33種）の音量制御、不可視40%気配察知、生データ属性自動判定、Multishot集約、60msデバウンス制御、および音響素材制作ガイドラインの詳細は、専用仕様書 [combat_sound_specification.md](combat_sound_specification.md) を参照してください。

> **改訂履歴**: 2026-09-16 初版作成。初版レビューに基づき修正。2026-09-17 戦闘アクション効果音 33種（No.204〜236）対応。2026-09-18 魔法の笛（se_magic_whistle）新設・通常笛と分離。2026-09-18 ドアを閉める音（se_door_close）新設・開扉音と連動。2026-09-19 全313種体系へ完全統一、Cコア呼び出し箇所（全369箇所）同期、Android umask(0022)健全性維持およびプレイヤープール制御を反映。2026-09-19 階段昇降音（se_stairs_up / se_stairs_down）、キック打撃音（se_kick）新設、ガラス破壊音（se_glass_shattering）音響配備により全316種体系・全376箇所呼び出しへ拡張。2026-09-20 ドア蹴り開け音（se_kick_door_it_crashes_open / se_kick_door_it_shatters）、宝箱鍵破壊音（se_crashing_sound）、宝箱ふた開閉音（se_lid_slams_open_falls_shut）、隠し扉開扉音（se_crash_door）、玉座破壊音（se_crash_throne_destroyed）の音源配備およびCコア呼び出し同期。2026-09-20 状態異常デバフ音（se_debuff）および空腹音（se_hunger）新設、Cコア呼び出し（全390箇所）および全320種体系へ拡張。2026-09-20 玉座破壊音（se_crash_throne_destroyed）を重厚な木製家具破壊音へ再合成・更新、旧破砕音をガラス激割れ音（se_glass_crashing）へ正式配備。2026-09-20 大箱・宝箱等の解錠・施錠音（se_klick）音源配備およびこじ開け音（se_force_lock）新設、Cコア呼び出し（全394箇所）および全321種体系へ拡張。

---

## 第1部: 音声ファイル マスター管理表（全音源チェックリスト）

### 1-A. 効果音 (`Soundeffect`) — se_*.ogg 一覧
Cコアの `include/seffects.h` に定義されている 244 種の効果音 ID の全一覧です（一般効果音 211種 + 戦闘アクション効果音 33種）。

| No. | 音声ファイル名 (.ogg) | サウンドID | 日本語イベント説明 | 呼び出し元Cファイル |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `se_air_crackles.ogg` | `se_air_crackles` | 空気がパチパチと鳴る音（エレメンタルや魔法の気配） | mcastu.c |
| 2 | `se_alarm.ogg` | `se_alarm` | 警報・アラーム音（金庫室アラームやトラップ作動時） | do.c, shk.c |
| 3 | `se_angry_drone.ogg` | `se_angry_drone` | 怒った蜂・昆虫の羽音（蜂の巣部屋） | sounds.c |
| 4 | `se_angry_snakes.ogg` | `se_angry_snakes` | 威嚇するヘビ群のシューシュー音（ヘビ複数の攻撃） | mthrowu.c |
| 5 | `se_angry_voice.ogg` | `se_angry_voice` | 怒れる声（神や店主の立腹・叫び） | shk.c |
| 6 | `se_applause.ogg` | `se_applause` | 拍手喝采（闘技場や成功イベント） | mon.c |
| 7 | `se_avian_screak.ogg` | `se_avian_screak` | 鳥類・怪鳥の甲高い叫び声 | 予備（直接呼び出しなし） |
| 8 | `se_bang_weapon_side.ogg` | `se_bang_weapon_side` | 武器の柄で壁を叩く音（壁の素材調査時） | dig.c |
| 9 | `se_bars_clink.ogg` | `se_bars_clink` | 鉄格子がカチャリと軽く鳴る音 | 予備（直接呼び出しなし） |
| 10 | `se_bars_clonk.ogg` | `se_bars_clonk` | 鉄格子への重い金属衝突音 | 予備（直接呼び出しなし） |
| 11 | `se_bars_flapp.ogg` | `se_bars_flapp` | 鉄格子のバタバタという揺れ音 | 予備（直接呼び出しなし） |
| 12 | `se_bars_whang.ogg` | `se_bars_whang` | 鉄格子への激しい衝撃音 | 予備（直接呼び出しなし） |
| 13 | `se_bars_whap.ogg` | `se_bars_whap` | 鉄格子への打撃・ビシッという音 | 予備（直接呼び出しなし） |
| 14 | `se_bear_trap.ogg` | `se_bear_trap` | 熊の罠・トラバサミがガシャンと挟み込む金属音 | trap.c |
| 15 | `se_bees.ogg` | `se_bees` | 蜂の群体がブンブン群がる羽音 | sounds.c |
| 16 | `se_blast.ogg` | `se_blast` | 爆発・爆風音（魔法爆発・罠爆発） | explode.c |
| 17 | `se_board_squeak.ogg` | `se_board_squeak` | 床板がギシッときしむ音（きしみ床トラップ） | 予備（直接呼び出しなし） |
| 18 | `se_board_squeaks_loudly.ogg` | `se_board_squeaks_loudly` | 床板がギシギシと大きくきしむ音 | 予備（直接呼び出しなし） |
| 19 | `se_boing.ogg` | `se_boing` | ビヨーンと跳ねる音（ゴムや跳躍） | muse.c |
| 20 | `se_bolt_of_lightning.ogg` | `se_bolt_of_lightning` | ビリビリと落雷・雷撃が走る音 | mcastu.c |
| 21 | `se_bone_rattle.ogg` | `se_bone_rattle` | 骨がカタカタと鳴る音（スケルトンやアンデッド） | sounds.c |
| 22 | `se_boomerang_klonk.ogg` | `se_boomerang_klonk` | ブーメランが何かに当たって跳ね返る音 | zap.c |
| 23 | `se_boulder_drop.ogg` | `se_boulder_drop` | 巨石がドスンと落ちる音（階段や穴への落下） | do.c |
| 24 | `se_bovine_bellow.ogg` | `se_bovine_bellow` | 牛・ウシの低い唸り声 | 予備（直接呼び出しなし） |
| 25 | `se_bovine_moo.ogg` | `se_bovine_moo` | 牛のモーという鳴き声 | sounds.c |
| 26 | `se_bubble_rising.ogg` | `se_bubble_rising` | 水中からポコポコと泡が湧き立つ音 | fountain.c |
| 27 | `se_bugle_playing_reveille.ogg` | `se_bugle_playing_reveille` | ラッパで起床ラッパを演奏する音 | muse.c |
| 28 | `se_buzz.ogg` | `se_buzz` | ブーンという低周波の羽音・電気音 | sounds.c |
| 29 | `se_canine_bark.ogg` | `se_canine_bark` | 犬・狼のワンワンという吠え声 | 予備（直接呼び出しなし） |
| 30 | `se_canine_growl.ogg` | `se_canine_growl` | 犬・狼のウーンという唸り声 | 予備（直接呼び出しなし） |
| 31 | `se_canine_howl.ogg` | `se_canine_howl` | 犬・狼の遠吠え（アオーンという声） | were.c |
| 32 | `se_canine_whine.ogg` | `se_canine_whine` | 犬のクーン・キュンという甘え声 | 予備（直接呼び出しなし） |
| 33 | `se_canine_yelp.ogg` | `se_canine_yelp` | 犬のキャンという痛みの悲鳴 | 予備（直接呼び出しなし） |
| 34 | `se_canine_yip.ogg` | `se_canine_yip` | 犬の甲高いキュッという鳴き声 | 予備（直接呼び出しなし） |
| 35 | `se_canine_yowl.ogg` | `se_canine_yowl` | 犬の長く引き伸ばした吠え声 | 予備（直接呼び出しなし） |
| 36 | `se_chain_shatters.ogg` | `se_chain_shatters` | 鎖がバキッと砕け散る音（魔法爆発等で） | explode.c |
| 37 | `se_chains_rattling_gears_turning.ogg` | `se_chains_rattling_gears_turning` | 鎖がジャラジャラ鳴りながらギアが回る音（跳ね橋の可動） | dbridge.c |
| 38 | `se_chant.ogg` | `se_chant` | 呪文の詠唱・宗教的な賛歌の声 | 予備（直接呼び出しなし） |
| 39 | `se_chirp.ogg` | `se_chirp` | 小鳥・小動物のちゅんちゅんという鳴き声 | sounds.c |
| 40 | `se_clanging_sound.ogg` | `se_clanging_sound` | 金属がカンカンと大きく鳴り響く音 | 予備（直接呼び出しなし） |
| 41 | `se_clank.ogg` | `se_clank` | カンという短い金属衝突音 | worn.c |
| 42 | `se_clanking_pipe.ogg` | `se_clanking_pipe` | 配管がカンカンと響く音（噴水の配管操作） | fountain.c |
| 43 | `se_clash.ogg` | `se_clash` | 武器同士が激しくぶつかり合う金属音 | dig.c |
| 44 | `se_cockatrice_hiss.ogg` | `se_cockatrice_hiss` | コカトリスの石化の威嚇音 | uhitm.c |
| 45 | `se_cough.ogg` | `se_cough` | ゲホゲホと咳き込む声（毒・粉塵吸入） | mthrowu.c |
| 46 | `se_courtly_conversation.ogg` | `se_courtly_conversation` | 宮廷部屋のにぎやかな会話音（謁見室） | sounds.c |
| 47 | `se_cracking_sound.ogg` | `se_cracking_sound` | パキッとひびが入る音（防具・呪いの解除等） | worn.c |
| 48 | `se_crackling.ogg` | `se_crackling` | パチパチとはじける音（炎・電気） | 予備（直接呼び出しなし） |
| 49 | `se_crackling_of_hellfire.ogg` | `se_crackling_of_hellfire` | 地獄の業火がメラメラと燃えさかる音（呪われた道具） | apply.c |
| 50 | `se_crash.ogg` | `se_crash` | ドカンと激しく崩壊・衝突する音 | 予備（直接呼び出しなし） |
| 51 | `se_crash_door.ogg` | `se_crash_door` | ドアがドカンと破壊される音（強制突破） | dokick.c |
| 52 | `se_crash_something_broke.ogg` | `se_crash_something_broke` | 何かがガシャンと割れて壊れる音 | 予備（直接呼び出しなし） |
| 53 | `se_crash_throne_destroyed.ogg` | `se_crash_throne_destroyed` | 玉座が蹴り倒されて粉々に砕ける大音響 | dokick.c |
| 54 | `se_crash_through_floor.ogg` | `se_crash_through_floor` | 床を突き破って落とし穴に落ちる音 | muse.c |
| 55 | `se_crashed_ceiling.ogg` | `se_crashed_ceiling` | 天井が崩落してガラガラ落ちる音 | 予備（直接呼び出しなし） |
| 56 | `se_crashing_boulder.ogg` | `se_crashing_boulder` | 巨石がドカドカと激しく転がり激突する音 | do.c |
| 57 | `se_crashing_rock.ogg` | `se_crashing_rock` | 岩石がガラガラと崩れ落ちる音（掘削・崩壊） | dig.c |
| 58 | `se_crashing_sound.ogg` | `se_crashing_sound` | 激しい衝突・破壊音（ドアや施錠装置の破壊） | dokick.c, lock.c |
| 59 | `se_croc_bellow.ogg` | `se_croc_bellow` | ワニの低く響く咆哮 | 予備（直接呼び出しなし） |
| 60 | `se_crumbling_sound.ogg` | `se_crumbling_sound` | 砂岩や壁がボロボロと崩れる音（魔法・掘削） | zap.c |
| 61 | `se_crunching_sound.ogg` | `se_crunching_sound` | バリバリと硬いものを噛み砕く音（捕食・踏み砕き） | mon.c |
| 62 | `se_crushing_sound.ogg` | `se_crushing_sound` | メキメキと挟まれて押し潰される音（跳ね橋） | dbridge.c |
| 63 | `se_deafening_roar_atmospheric.ogg` | `se_deafening_roar_atmospheric` | 耳をつんざく轟音（強力な罠・爆発の雰囲気） | trap.c |
| 64 | `se_destroy_web.ogg` | `se_destroy_web` | クモの巣をビリっと破り払う音 | ball.c |
| 65 | `se_distant_thunder.ogg` | `se_distant_thunder` | 遠くに聞こえる雷鳴（嵐・スクロール効果） | mon.c |
| 66 | `se_divine_music.ogg` | `se_divine_music` | 神聖な天上の音楽（神への祈り成功時） | pray.c |
| 67 | `se_door_crash_open.ogg` | `se_door_crash_open` | ドアがドカンと蹴り開けられる音（モンスターの侵入） | monmove.c |
| 68 | `se_door_open.ogg` | `se_door_open` | ドアがギィッと開く音（通常の開扉） | monmove.c, lock.c |
| 69 | `se_door_close.ogg` | `se_door_close` | ドアがバタンと閉まる音（通常の閉扉） | lock.c |
| 70 | `se_door_unlock_and_open.ogg` | `se_door_unlock_and_open` | 鍵がカチャリと解錠されてドアが開く音 | monmove.c |
| 71 | `se_drain_noises.ogg` | `se_drain_noises` | 排水口がゴボゴボと鳴る音（排水溝近く） | do.c |
| 72 | `se_dry_throat_rattle.ogg` | `se_dry_throat_rattle` | 乾燥した喉がガラガラ鳴る音（モンスターの息） | mthrowu.c |
| 73 | `se_egg_cracking.ogg` | `se_egg_cracking` | 卵の殻がパキッと割れる音（蹴った時） | dokick.c |
| 74 | `se_egg_splatting.ogg` | `se_egg_splatting` | 卵がグシャッと踏み潰れる音 | dokick.c |
| 75 | `se_elephant_trumpet.ogg` | `se_elephant_trumpet` | 象のパオーンという高らかな鳴き声 | sounds.c |
| 76 | `se_equine_neigh.ogg` | `se_equine_neigh` | 馬のヒヒーンという高いいななき | sounds.c |
| 77 | `se_equine_whicker.ogg` | `se_equine_whicker` | 馬の低く柔らかいいななき | sounds.c |
| 78 | `se_equine_whinny.ogg` | `se_equine_whinny` | 馬の短いいななき声 | sounds.c |
| 79 | `se_explosion.ogg` | `se_explosion` | 大爆発音（錠前爆発・爆破罠） | lock.c |
| 80 | `se_faint_chime.ogg` | `se_faint_chime` | かすかなチリンというチャイムの音（魔法感知） | spell.c |
| 81 | `se_faint_sloshing.ogg` | `se_faint_sloshing` | かすかな水が揺れる音（アイテム生成時） | mkobj.c |
| 82 | `se_faint_splashing.ogg` | `se_faint_splashing` | かすかな水しぶき音（ホイールへの接触） | apply.c |
| 83 | `se_feline_meow.ogg` | `se_feline_meow` | 猫のニャーという鳴き声 | sounds.c |
| 84 | `se_feline_mew.ogg` | `se_feline_mew` | 子猫のミューという細い鳴き声 | sounds.c |
| 85 | `se_feline_purr.ogg` | `se_feline_purr` | 猫のゴロゴロと喉を鳴らす音 | sounds.c |
| 86 | `se_feline_yelp.ogg` | `se_feline_yelp` | 猫のギャッという悲鳴 | 予備（直接呼び出しなし） |
| 87 | `se_feline_yip.ogg` | `se_feline_yip` | 猫の甲高いキーという鳴き声 | 予備（直接呼び出しなし） |
| 88 | `se_feline_yowl.ogg` | `se_feline_yowl` | 猫のウウウという低い唸り声 | sounds.c |
| 89 | `se_furious_bubbling.ogg` | `se_furious_bubbling` | 液体が激しくボコボコと泡立つ音（噴水の呪い） | fountain.c |
| 90 | `se_gear_turn.ogg` | `se_gear_turn` | 歯車がカチリと一段回る音（機構の動作） | music.c |
| 91 | `se_gears_turning_chains_rattling.ogg` | `se_gears_turning_chains_rattling` | 歯車が回り鎖が引き上げられる音（跳ね橋の引き上げ） | dbridge.c |
| 92 | `se_glass_crashing.ogg` | `se_glass_crashing` | ガラスが激しくバリーンと割れる音 | dokick.c |
| 93 | `se_glass_shattering.ogg` | `se_glass_shattering` | ガラス瓶が粉々にパリーンと砕け散る音 | dokick.c |
| 94 | `se_groan.ogg` | `se_groan` | ウゥーといううめき声（モンスターや地形） | sounds.c |
| 95 | `se_groans_and_moans.ogg` | `se_groans_and_moans` | 呻きとうめき声（アンデッドの気配・死体部屋） | do.c |
| 96 | `se_growl.ogg` | `se_growl` | ウーンという低い唸り声 | 予備（直接呼び出しなし） |
| 97 | `se_grunt.ogg` | `se_grunt` | フンと鼻を鳴らす短い声 | sounds.c |
| 98 | `se_guards_footsteps.ogg` | `se_guards_footsteps` | 警備員の重い足音が近づく音（金庫室侵入） | sounds.c |
| 99 | `se_gurgle.ogg` | `se_gurgle` | ゴボゴボと湧き立つ液体の音（モンスターの声） | sounds.c |
| 100 | `se_gushing_sound.ogg` | `se_gushing_sound` | ドバーッと液体や水が噴き出す音（配管破壊） | dokick.c |
| 101 | `se_heart_beat.ogg` | `se_heart_beat` | トックン、トックンという心臓の鼓動音（聴診器使用） | apply.c |
| 102 | `se_hiss.ogg` | `se_hiss` | シュッというヘビや蒸気の威嚇音 | sounds.c |
| 103 | `se_hollow_sound.ogg` | `se_hollow_sound` | コンコンと中が空洞に響く音（壁や箱の確認） | apply.c |
| 104 | `se_horn_being_played.ogg` | `se_horn_being_played` | 角笛がブォーンと響き渡る音（演奏効果） | muse.c |
| 105 | `se_iron_ball_dragging_you.ogg` | `se_iron_ball_dragging_you` | 重い鉄球をズルズルと引きずられる音 | 予備（直接呼び出しなし） |
| 106 | `se_iron_ball_hits_you.ogg` | `se_iron_ball_hits_you` | 鉄球がドスンと身体に激突する音 | ball.c |
| 107 | `se_item_tumble_downwards.ogg` | `se_item_tumble_downwards` | アイテムが下層にカラカラ落ちていく音 | do.c |
| 108 | `se_jabberwock_burble.ogg` | `se_jabberwock_burble` | ジャバウォックのブツブツという不気味な声 | sounds.c |
| 109 | `se_kaablamm_of_mine.ogg` | `se_kaablamm_of_mine` | 地雷がカーブラムと大爆発する音 | trap.c |
| 110 | `se_kaboom.ogg` | `se_kaboom` | ドカーンという爆発音 | trap.c |
| 111 | `se_kaboom_boom_boom.ogg` | `se_kaboom_boom_boom` | ドカン、ドドーンという連続大爆発音 | timeout.c |
| 112 | `se_kaboom_door_explodes.ogg` | `se_kaboom_door_explodes` | ドアの罠がドカンと爆発する音 | lock.c |
| 113 | `se_kadoom_boulder_falls_in.ogg` | `se_kadoom_boulder_falls_in` | 巨石がカドームと穴に落ちる轟音 | dig.c |
| 114 | `se_kerplunk_boulder_gone.ogg` | `se_kerplunk_boulder_gone` | 巨石が水中や穴をカポーンと塞ぐ音 | hack.c |
| 115 | `se_kick_door_it_crashes_open.ogg` | `se_kick_door_it_crashes_open` | 蹴りによりドアがドカンと開く音 | dokick.c |
| 116 | `se_kick_door_it_shatters.ogg` | `se_kick_door_it_shatters` | 蹴りによりドアが粉々にバリーンと砕ける音 | dokick.c |
| 117 | `se_klick.ogg` | `se_klick` | カチッという小さな金属の作動音（解錠・機構） | lock.c |
| 118 | `se_klunk.ogg` | `se_klunk` | ゴトンという重い鈍い衝突音 | lock.c |
| 119 | `se_klunk_pipe.ogg` | `se_klunk_pipe` | 配管をゴトンと叩く衝撃音 | dokick.c |
| 120 | `se_laughter.ogg` | `se_laughter` | ハハハという笑い声（モンスターや魔法使用時） | sounds.c, uhitm.c |
| 121 | `se_lid_slams_open_falls_shut.ogg` | `se_lid_slams_open_falls_shut` | 箱の蓋がガタンと開き、ズンと閉まる音 | dokick.c |
| 122 | `se_loud_click.ogg` | `se_loud_click` | カチャンという大きな機構の作動音（罠発動） | trap.c |
| 123 | `se_loud_crash.ogg` | `se_loud_crash` | 大音響の衝突・崩壊音 | dbridge.c, trap.c |
| 124 | `se_loud_pop.ogg` | `se_loud_pop` | ポーンと弾けて破裂する音（泡・爆発） | fountain.c |
| 125 | `se_loud_splash.ogg` | `se_loud_splash` | ドバシャーンという大きな水しぶき音 | dbridge.c |
| 126 | `se_low_buzzing.ogg` | `se_low_buzzing` | ブーンという低く響く羽音（蜂の巣・虫） | sounds.c |
| 127 | `se_low_hum.ogg` | `se_low_hum` | ブーンというハム・機械音（罠の予兆） | trap.c |
| 128 | `se_magic_whistle.ogg` | `se_magic_whistle` | 魔法の笛の澄んだ神秘的な音（ペットを呼び寄せる） | apply.c |
| 129 | `se_mana_drain.ogg` | `se_mana_drain` | 反魔法の罠や魔力吸収によるマナ枯渇音 | trap.c |
| 130 | `se_maniacal_laughter.ogg` | `se_maniacal_laughter` | ケタケタという狂気的な高笑い（巻物読後等） | read.c |
| 131 | `se_masticating_sound.ogg` | `se_masticating_sound` | クチャクチャと何かを噛む咀嚼音 | mon.c |
| 132 | `se_monster_behind_boulder.ogg` | `se_monster_behind_boulder` | 岩陰に隠れるモンスターの気配・物音 | hack.c |
| 133 | `se_mutter_imprecations.ogg` | `se_mutter_imprecations` | 呪いの言葉をブツブツと呟く声（店主の怒り） | shk.c |
| 134 | `se_mutter_incantation.ogg` | `se_mutter_incantation` | 呪文をブツブツと唱える声 | shk.c |
| 135 | `se_orc_grunt.ogg` | `se_orc_grunt` | オークのグアッという低い唸り声 | sounds.c |
| 136 | `se_paranoid_confirmation.ogg` | `se_paranoid_confirmation` | ソワソワした確認の囁き声 | 予備（直接呼び出しなし） |
| 137 | `se_polymorph.ogg` | `se_polymorph` | ポリモーフの罠による肉体変化・変身音 | trap.c |
| 138 | `se_potion_crash_and_break.ogg` | `se_potion_crash_and_break` | ポーション瓶がガシャンと割れ液体が散る音 | potion.c |
| 139 | `se_ring_in_drain.ogg` | `se_ring_in_drain` | 指輪が排水口にコロコロと転がり落ちる音 | do.c |
| 140 | `se_ripping_sound.ogg` | `se_ripping_sound` | ビリビリと布・紙が破れる音（装備破壊等） | worn.c |
| 141 | `se_roar.ogg` | `se_roar` | ガオーッという猛獣の咆哮 | trap.c |
| 142 | `se_rumbling.ogg` | `se_rumbling` | ゴゴゴという地鳴り音（罠・地震） | trap.c |
| 143 | `se_rumbling_of_earth.ogg` | `se_rumbling_of_earth` | ズズズという大地が轟く地鳴り | 予備（直接呼び出しなし） |
| 144 | `se_rushing_wind_noise.ogg` | `se_rushing_wind_noise` | ヒューという突風が吹き荒れる音 | mhitu.c |
| 145 | `se_rustling_paper.ogg` | `se_rustling_paper` | カサカサと紙・巻物が擦れ合う音 | apply.c |
| 146 | `se_sad_wailing.ogg` | `se_sad_wailing` | ウワーンという悲しげなすすり泣き・哀しみの声 | read.c, sounds.c |
| 147 | `se_sceptor_pounding.ogg` | `se_sceptor_pounding` | 笏（しゃく）で床をドンドンと叩く音（宮廷） | sounds.c |
| 148 | `se_scratching.ogg` | `se_scratching` | カリカリと爪で引っ掻く音（秘密の扉の探索） | do.c |
| 149 | `se_scream.ogg` | `se_scream` | ギャーッという悲鳴・絶叫（演奏効果等） | music.c |
| 150 | `se_screech.ogg` | `se_screech` | キーキーという甲高い叫び声 | 予備（直接呼び出しなし） |
| 151 | `se_sewer_song.ogg` | `se_sewer_song` | 下水道から聞こえる不気味な歌声（下水道の噴水） | fountain.c |
| 152 | `se_sharp_crack.ogg` | `se_sharp_crack` | バシッと鋭くひびが走る音 | 予備（直接呼び出しなし） |
| 153 | `se_shriek.ogg` | `se_shriek` | ギャーッという鋭い悲鳴（モンスターの声） | sounds.c |
| 154 | `se_shrill_whistle.ogg` | `se_shrill_whistle` | ピーッと甲高く突き刺さる笛の音（ホイッスル使用） | apply.c, mon.c |
| 155 | `se_sinister_laughter.ogg` | `se_sinister_laughter` | クックッという不敵・邪悪な笑い声（悪の存在） | eat.c |
| 156 | `se_sizzling.ogg` | `se_sizzling` | ジュージューと焼ける・溶ける音（酸・炎接触） | do.c |
| 157 | `se_slurping_sound.ogg` | `se_slurping_sound` | ズルズルとすする音（捕食・液体摂取） | mon.c |
| 158 | `se_smashing_and_crushing.ogg` | `se_smashing_and_crushing` | ガシャンと叩き潰す音（跳ね橋の可動） | dbridge.c |
| 159 | `se_snake_rattle.ogg` | `se_snake_rattle` | ガラガラヘビの尾のガラガラと鳴る警告音 | 予備（直接呼び出しなし） |
| 160 | `se_snakes_hissing.ogg` | `se_snakes_hissing` | ヘビのシャーという群体の威嚇音 | fountain.c |
| 161 | `se_snarl.ogg` | `se_snarl` | ウーッと牙をむいて低く唸る声 | sounds.c |
| 162 | `se_soft_click.ogg` | `se_soft_click` | カチッとかすかに鳴るいかにも怪しい音（罠感知） | trap.c |
| 163 | `se_soft_crackling.ogg` | `se_soft_crackling` | パチパチとかすかに燃える音（炎の魔法） | zap.c |
| 164 | `se_someone_bowling.ogg` | `se_someone_bowling` | ボウリングの球が転がるような音（転がる物体） | trap.c |
| 165 | `se_someone_searching.ogg` | `se_someone_searching` | ガサゴソと何かを捜索する音（探索中のモンスター） | sounds.c |
| 166 | `se_someone_summoning.ogg` | `se_someone_summoning` | ウォーという召喚の呪文を唱える声 | mcastu.c |
| 167 | `se_someone_yells.ogg` | `se_someone_yells` | 誰かが叫ぶ声（警衛の呼び声・緊急事態） | monmove.c |
| 168 | `se_splash.ogg` | `se_splash` | バシャッと水が跳ねる音（水中落下・投擲） | dbridge.c, do.c, dothrow.c, mthrowu.c |
| 169 | `se_splat_egg.ogg` | `se_splat_egg` | 卵がぐしゃっと潰れる音（投擲命中） | mthrowu.c |
| 170 | `se_splat_from_engulf.ogg` | `se_splat_from_engulf` | 丸呑みモンスターに消化されグシャッとなる音 | 予備（直接呼び出しなし） |
| 171 | `se_squawk.ogg` | `se_squawk` | ギャーギャーという鳥の鳴き声 | sounds.c |
| 172 | `se_squeak.ogg` | `se_squeak` | チューという動物の高い鳴き声・きしみ音 | sounds.c |
| 173 | `se_squeak_A.ogg` | `se_squeak_A` | きしみ床板の罠を踏んだときのきしみ音 — ラ音（A） | trap.c |
| 174 | `se_squeak_B.ogg` | `se_squeak_B` | きしみ床板の罠を踏んだときのきしみ音 — シ音（B） | trap.c |
| 175 | `se_squeak_B_flat.ogg` | `se_squeak_B_flat` | きしみ床板の罠を踏んだときのきしみ音 — シ♭音（B♭） | trap.c |
| 176 | `se_squeak_C.ogg` | `se_squeak_C` | きしみ床板の罠を踏んだときのきしみ音 — ド音（C） | trap.c |
| 177 | `se_squeak_D.ogg` | `se_squeak_D` | きしみ床板の罠を踏んだときのきしみ音 — レ音（D） | trap.c |
| 178 | `se_squeak_D_flat.ogg` | `se_squeak_D_flat` | きしみ床板の罠を踏んだときのきしみ音 — レ♭音（D♭） | trap.c |
| 179 | `se_squeak_E.ogg` | `se_squeak_E` | きしみ床板の罠を踏んだときのきしみ音 — ミ音（E） | trap.c |
| 180 | `se_squeak_E_flat.ogg` | `se_squeak_E_flat` | きしみ床板の罠を踏んだときのきしみ音 — ミ♭音（E♭） | trap.c |
| 181 | `se_squeak_F.ogg` | `se_squeak_F` | きしみ床板の罠を踏んだときのきしみ音 — ファ音（F） | trap.c |
| 182 | `se_squeak_F_sharp.ogg` | `se_squeak_F_sharp` | きしみ床板の罠を踏んだときのきしみ音 — ファ♯音（F♯） | trap.c |
| 183 | `se_squeak_G.ogg` | `se_squeak_G` | きしみ床板の罠を踏んだときのきしみ音 — ソ音（G） | trap.c |
| 184 | `se_squeak_G_sharp.ogg` | `se_squeak_G_sharp` | きしみ床板の罠を踏んだときのきしみ音 — ソ♯音（G♯） | trap.c |
| 185 | `se_squeal.ogg` | `se_squeal` | キーッという甲高い叫び声・きしみ | 予備（直接呼び出しなし） |
| 186 | `se_squelch.ogg` | `se_squelch` | グチャッという湿った踏みつけ音 | sit.c |
| 187 | `se_stone_breaking.ogg` | `se_stone_breaking` | バキッと石が割れる音（岩石魔法・爆発） | explode.c |
| 188 | `se_stone_crumbling.ogg` | `se_stone_crumbling` | ガラガラと石が崩れ落ちる音 | explode.c |
| 189 | `se_swoosh.ogg` | `se_swoosh` | ヒュッと素早く風を切る音（飛道具・魔法） | lock.c |
| 190 | `se_sword_blade_rings.ogg` | `se_sword_blade_rings` | 剣の刃がシャリーンと鳴る音（法具の認識） | apply.c |
| 191 | `se_teleport.ogg` | `se_teleport` | テレポートの罠による空間転移・瞬間移動音 | trap.c |
| 192 | `se_thud.ogg` | `se_thud` | ドスンという重い着地・衝突音 | worn.c |
| 193 | `se_thump.ogg` | `se_thump` | ドンという鈍い衝突音 | music.c |
| 194 | `se_thunderclap.ogg` | `se_thunderclap` | ドカーンと轟く雷鳴（祈り・神罰） | pray.c |
| 195 | `se_tumbler_click.ogg` | `se_tumbler_click` | 鍵穴のタンブラーがハマってカチッと鳴る音 | music.c |
| 196 | `se_typing_noise.ogg` | `se_typing_noise` | カタカタとタイプライターを打つような音（占術使用） | apply.c |
| 197 | `se_wail.ogg` | `se_wail` | ウオーッと泣き叫ぶ声（アンデッドや呪い） | 予備（直接呼び出しなし） |
| 198 | `se_wailing_of_the_banshee.ogg` | `se_wailing_of_the_banshee` | バンシーの死を予告する絶叫（バンシーの遭遇） | hack.c |
| 199 | `se_wall_of_force.ogg` | `se_wall_of_force` | ズズーンと重く響く力場・バリア音（魔法壁） | apply.c |
| 200 | `se_yelp.ogg` | `se_yelp` | キャンという短い悲鳴 | 予備（直接呼び出しなし） |
| 201 | `se_zap.ogg` | `se_zap` | ビビッという魔法・電撃の発射音 | muse.c |
| 202 | `se_zap_then_explosion.ogg` | `se_zap_then_explosion` | ビビッからドカンという魔法爆発音 | muse.c |
| 203 | `se_mon_chugging_potion.ogg` | `se_mon_chugging_potion` | モンスターがポーションをゴクゴクと飲む音 | muse.c |
| 204 | `se_combat_hit_slash.ogg` | `se_combat_hit_slash` | 刃物・刀剣・斧による斬撃ヒット音 | uhitm.c, mhitu.c, mhitm.c, dothrow.c |
| 205 | `se_combat_hit_blunt.ogg` | `se_combat_hit_blunt` | 鈍器・棍棒・石・打撃武器によるヒット音 | uhitm.c, mhitu.c, mhitm.c, dothrow.c |
| 206 | `se_combat_hit_pierce.ogg` | `se_combat_hit_pierce` | 槍・刺突武器・矢弾による貫通ヒット音 | uhitm.c, mhitu.c, mhitm.c, dothrow.c |
| 207 | `se_combat_hit_unarmed.ogg` | `se_combat_hit_unarmed` | 素手格闘・パンチ・キックによる打撃ヒット音 | uhitm.c, mhitu.c, mhitm.c |
| 208 | `se_combat_hit_whip.ogg` | `se_combat_hit_whip` | 鞭・濡れたタオルによる攻撃命中音 | uhitm.c, mhitu.c, mhitm.c |
| 209 | `se_combat_hit_ironball.ogg` | `se_combat_hit_ironball` | 鉄球・鉄鎖による重金属・鎖衝突音 | uhitm.c, mhitu.c, mhitm.c |
| 210 | `se_combat_hit_shield.ogg` | `se_combat_hit_shield` | 盾による重い防具シールドバッシュ音（近接限定） | uhitm.c, mhitu.c, mhitm.c |
| 211 | `se_combat_hit_corpse.ogg` | `se_combat_hit_corpse` | 死体・肉塊武器による生体打撃音 | uhitm.c, mhitu.c, mhitm.c |
| 212 | `se_combat_hit_pick.ogg` | `se_combat_hit_pick` | つるはし・マトックによる硬質な採掘具打撃音 | uhitm.c, mhitu.c, mhitm.c |
| 213 | `se_combat_hit_wand.ogg` | `se_combat_hit_wand` | 杖・ロッドによる硬く乾いた小打撃音 | uhitm.c, mhitu.c, mhitm.c |
| 214 | `se_combat_hit_other.ogg` | `se_combat_hit_other` | 未分類アイテム（本・巻物・薬・食料・宝石等）全般の汎用フォールバック打撃音 | uhitm.c, mhitu.c, mhitm.c, dothrow.c, mthrowu.c |
| 215 | `se_combat_miss.ogg` | `se_combat_miss` | 攻撃の空振り音（風切り音） | uhitm.c, mhitu.c, mhitm.c |
| 216 | `se_combat_shoot_bow.ogg` | `se_combat_shoot_bow` | 弓矢の発射音（弦を弾く音） | dothrow.c, mthrowu.c |
| 217 | `se_combat_shoot_crossbow.ogg` | `se_combat_shoot_crossbow` | クロスボウの発射音（バネ解放音） | dothrow.c, mthrowu.c |
| 218 | `se_combat_shoot_sling.ogg` | `se_combat_shoot_sling` | スリング（投石器）の旋回・射出音 | dothrow.c, mthrowu.c |
| 219 | `se_combat_throw.ogg` | `se_combat_throw` | 手投げによる投擲音 | dothrow.c, mthrowu.c |
| 220 | `se_combat_throw_boomerang.ogg` | `se_combat_throw_boomerang` | ブーメランの旋回投擲音 | dothrow.c |
| 221 | `se_combat_throw_mjollnir.ogg` | `se_combat_throw_mjollnir` | ミョルニルの電撃を帯びた豪快な投擲音 | dothrow.c |
| 222 | `se_combat_miss_thud.ogg` | `se_combat_miss_thud` | 飛翔体が外れて壁や床に激突する音 | dothrow.c, mthrowu.c |
| 223 | `se_combat_spell_cast.ogg` | `se_combat_spell_cast` | 呪文の詠唱・魔法発動音 | spell.c, mcastu.c |
| 224 | `se_combat_wand_zap.ogg` | `se_combat_wand_zap` | 杖を振った際の発動音 | zap.c, muse.c |
| 225 | `se_mon_claw.ogg` | `se_mon_claw` | モンスターの爪による引き裂き音 | mhitu.c, mhitm.c |
| 226 | `se_mon_bite.ogg` | `se_mon_bite` | モンスターの噛みつき音 | mhitu.c, mhitm.c |
| 227 | `se_mon_sting.ogg` | `se_mon_sting` | モンスターの毒針・刺突音 | mhitu.c, mhitm.c |
| 228 | `se_mon_butt.ogg` | `se_mon_butt` | モンスターの角・頭突き衝突音 | mhitu.c, mhitm.c |
| 229 | `se_mon_touch.ogg` | `se_mon_touch` | モンスターの接触・麻痺音 | mhitu.c, mhitm.c |
| 230 | `se_mon_tentacle.ogg` | `se_mon_tentacle` | 触手による攻撃・絡みつき音 | mhitu.c, mhitm.c |
| 231 | `se_mon_kick.ogg` | `se_mon_kick` | モンスターの蹴り・踏みつけ音 | mhitu.c, mhitm.c |
| 232 | `se_mon_hug.ogg` | `se_mon_hug` | 締めつけ・怪力による抱き締め音 | mhitu.c, mhitm.c |
| 233 | `se_mon_gaze.ogg` | `se_mon_gaze` | 凝視・魔眼による視線攻撃音 | mhitu.c, mhitm.c |
| 234 | `se_mon_engulf.ogg` | `se_mon_engulf` | 丸呑み・呑み込み音 | mhitu.c, mhitm.c |
| 235 | `se_mon_breath.ogg` | `se_mon_breath` | ドラゴン等のブレス放出音 | mhitu.c, mhitm.c |
| 236 | `se_mon_spit.ogg` | `se_mon_spit` | 毒液・酸の吐出音 | mhitu.c, mhitm.c |
| 237 | `se_kick.ogg` | `se_kick` | ドア・宝箱・モンスター・壁などを蹴った時の打撃音 | dokick.c |
| 238 | `se_stairs_up.ogg` | `se_stairs_up` | 階段やはしごを登るときの効果音 | do.c |
| 239 | `se_stairs_down.ogg` | `se_stairs_down` | 階段やはしごを降りるときの効果音 | do.c |
| 240 | `se_kick_door_it_crashes_open.ogg` | `se_kick_door_it_crashes_open` | ドアを蹴って勢いよく開けた時の音 | dokick.c |
| 241 | `se_kick_door_it_shatters.ogg` | `se_kick_door_it_shatters` | ドアを蹴って完全に粉砕した時の音 | dokick.c |
| 242 | `se_debuff.ogg` | `se_debuff` | 状態異常（デバフ）を受けた時のトーンダウン下降音 | potion.c, do.c |
| 243 | `se_hunger.ogg` | `se_hunger` | 空腹状態（Hungry, Weak, Fainting）悪化時のお腹の音 | eat.c |
| 244 | `se_force_lock.ogg` | `se_force_lock` | 箱の鍵を無理やりこじ開けた時の力強い破断音 | lock.c |

> **詳細仕様**: 各戦闘アクション効果音の詳細な判定ロジック、音量制御（不可視40%気配察知）、および素材制作指針は [combat_sound_specification.md](combat_sound_specification.md) を参照してください。

---

### 1-B. 実績・システム音 (`SoundAchievement`) — sa2_*.ogg / ach_*.ogg 一覧

#### 1-B-i. sa2 システムイベント音（`sa2_*`）
| No. | 音声ファイル名 (.ogg) | サウンドID | 日本語説明 | 呼び出し元 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `sa2_splashscreen.ogg` | `sa2_splashscreen` | タイトル・スプラッシュ画面が表示される時の音 | allmain.c |
| 2 | `sa2_newgame_nosplash.ogg` | `sa2_newgame_nosplash` | スプラッシュなしで新規ゲームを開始する時の音 | allmain.c |
| 3 | `sa2_xplevelup.ogg` | `sa2_xplevelup` | 経験値レベルがアップした時のファンファーレ音 | exper.c |
| 4 | `sa2_xpleveldown.ogg` | `sa2_xpleveldown` | 経験値レベルがダウンした時の音（ドレイン等） | exper.c |

#### 1-B-ii. ゲーム内実績達成音（`ach_*`）— `insight.c` から `SoundAchievement(achidx, 0, ...)` で呼ばれる
| No. | 音声ファイル名 (.ogg) | 実績ID | 日本語説明 | 呼び出し元 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `ach_bell.ogg` | `ACH_BELL (achidx=1)` | 「開封の鐘」を入手した時の実績音 | insight.c |
| 2 | `ach_hell.ogg` | `ACH_HELL (achidx=2)` | ゲヘナ（地獄）に入った時の実績音 | insight.c |
| 3 | `ach_cndl.ogg` | `ACH_CNDL (achidx=3)` | 「召喚の燭台」を入手した時の実績音 | insight.c |
| 4 | `ach_book.ogg` | `ACH_BOOK (achidx=4)` | 「死者の書」を入手した時の実績音 | insight.c |
| 5 | `ach_invk.ogg` | `ACH_INVK (achidx=5)` | 聖域へのアクセスのため召喚を行った時の実績音 | insight.c |
| 6 | `ach_amul.ogg` | `ACH_AMUL (achidx=6)` | 「ヨェンダーのアミュレット」を入手した時の実績音 | insight.c |
| 7 | `ach_endg.ogg` | `ACH_ENDG (achidx=7)` | エンドゲームに突入した時の実績音 | insight.c |
| 8 | `ach_astr.ogg` | `ACH_ASTR (achidx=8)` | アストラル界に足を踏み入れた時の実績音 | insight.c |
| 9 | `ach_uwin.ogg` | `ACH_UWIN (achidx=9)` | ゲームを昇天クリアした時のクリア音 | insight.c |
| 10 | `ach_mine_prize.ogg` | `ACH_MINE_PRIZE (achidx=10)` | 坑道の終点のラッキーストーンを入手した時の実績音 | insight.c |
| 11 | `ach_soko_prize.ogg` | `ACH_SOKO_PRIZE (achidx=11)` | 倉庫番のバッグまたはアミュレットを入手した時の実績音 | insight.c |
| 12 | `ach_medu.ogg` | `ACH_MEDU (achidx=12)` | メデューサを倒した時の実績音 | insight.c |
| 13 | `ach_mine.ogg` | `ACH_MINE (achidx=15)` | ノーム坑道に入った時の実績音 | insight.c |
| 14 | `ach_town.ogg` | `ACH_TOWN (achidx=16)` | 坑道の町（マインタウン）に到達した時の実績音 | insight.c |
| 15 | `ach_shop.ogg` | `ACH_SHOP (achidx=17)` | 店に入った時の実績音 | insight.c |
| 16 | `ach_tmpl.ogg` | `ACH_TMPL (achidx=18)` | 寺院に入った時の実績音 | insight.c |
| 17 | `ach_orcl.ogg` | `ACH_ORCL (achidx=19)` | 神託の神官（オラクル）に相談した時の実績音 | insight.c |
| 18 | `ach_soko.ogg` | `ACH_SOKO (achidx=21)` | 倉庫番（ソコバン）に入った時の実績音 | insight.c |
| 19 | `ach_tune.ogg` | `ACH_TUNE (achidx=31)` | 城の跳ね橋の演奏チューンを発見した時の実績音 | insight.c |

---

#### 1-C. 楽器演奏音 (`Hero_playnotes`) — sound_*.ogg 一覧

Cコアは `Hero_playnotes(instrument, notes, volume)` を呼び出し、楽器 enum ID とアルファベット（A〜G）の音符文字列を渡します。
**音階バリエーションあり**の楽器は音符ごとに個別ファイルが必要です（6種 × 7音 = 42ファイル）。
**固定演奏**の楽器は Cコアから常に固定音符が渡されるため、音階違いファイルは不要です（5種 × 1ファイル = 5ファイル）。計 **47 ファイル**。

> **参考情報 — ウィンドウ版 (`windsound.c`) との対応関係について**
>
> DartHack では `windsound.c` の wav ファイルは使用せず、新規に `.ogg` ファイルを用意します。
> ただし、上記ファイル名は `windsound.c` の `windsound_hero_playnotes()` 実装
> （[windsound.c L179〜L219](../../../c_core/nethack_jp/sound/windsound/windsound.c)）で
> 使われているリソース名をそのまま踏襲しています。これにより DartHack 側の再生コード実装時に同じ命名規則で `.ogg` を解決できます。
>
> | 楽器 enum ID | NetHack アイテム名 | windsound.c の基本リソース名 | 音階バリエーション |
> | :--- | :--- | :--- | :--- |
> | `ins_flute` | 木製フルート (wooden flute) | `sound_Wooden_Flute` | ✅ A〜G |
> | `ins_pan_flute` | 魔法のフルート (magic flute) | `sound_Magic_Flute` | ✅ A〜G |
> | `ins_english_horn` | 彫刻された角笛 (tooled horn) | `sound_Tooled_Horn` | ✅ A〜G |
> | `ins_french_horn` | 凍結の角笛 (frost horn) | `sound_Frost_Horn` | ❌ 固定1ファイル |
> | `ins_baritone_sax` | 火炎の角笛 (fire horn) | `sound_Fire_Horn` | ❌ 固定1ファイル |
> | `ins_trumpet` | ラッパ (bugle) | `sound_Bugle` | ✅ A〜G |
> | `ins_orchestral_harp` | 木製ハープ (wooden harp) | `sound_Wooden_Harp` | ✅ A〜G |
> | `ins_cello` | 魔法のハープ (magic harp) | `sound_Magic_Harp` | ✅ A〜G |
> | `ins_tinkle_bell` | ベル (Bell of Opening 等) | `sound_Bell` | ❌ 固定1ファイル |
> | `ins_taiko_drum` | 地震の太鼓 (drum of earthquake) | `sound_Drum_Of_Earthquake` | ❌ 固定1ファイル |
> | `ins_melodic_tom` | 革製太鼓 (leather drum) | `sound_Leather_Drum` | ❌ 固定1ファイル |

#### 音階バリエーションあり楽器（各 A〜G 7ファイル）

| No. | 音声ファイル名 (.ogg) | 楽器ID / 音階 | 日本語説明 | 呼び出し元 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `sound_Wooden_Flute_A.ogg` | `ins_flute` / A音 | 木製フルートの演奏音（蛇を魅了する効果）（A音） | apply.c, music.c |
| 2 | `sound_Wooden_Flute_B.ogg` | `ins_flute` / B音 | 木製フルートの演奏音（蛇を魅了する効果）（B音） | apply.c, music.c |
| 3 | `sound_Wooden_Flute_C.ogg` | `ins_flute` / C音 | 木製フルートの演奏音（蛇を魅了する効果）（C音） | apply.c, music.c |
| 4 | `sound_Wooden_Flute_D.ogg` | `ins_flute` / D音 | 木製フルートの演奏音（蛇を魅了する効果）（D音） | apply.c, music.c |
| 5 | `sound_Wooden_Flute_E.ogg` | `ins_flute` / E音 | 木製フルートの演奏音（蛇を魅了する効果）（E音） | apply.c, music.c |
| 6 | `sound_Wooden_Flute_F.ogg` | `ins_flute` / F音 | 木製フルートの演奏音（蛇を魅了する効果）（F音） | apply.c, music.c |
| 7 | `sound_Wooden_Flute_G.ogg` | `ins_flute` / G音 | 木製フルートの演奏音（蛇を魅了する効果）（G音） | apply.c, music.c |
| 8 | `sound_Magic_Flute_A.ogg` | `ins_pan_flute` / A音 | 魔法のフルートの演奏音（モンスターを眠らせる）（A音） | apply.c, music.c |
| 9 | `sound_Magic_Flute_B.ogg` | `ins_pan_flute` / B音 | 魔法のフルートの演奏音（モンスターを眠らせる）（B音） | apply.c, music.c |
| 10 | `sound_Magic_Flute_C.ogg` | `ins_pan_flute` / C音 | 魔法のフルートの演奏音（モンスターを眠らせる）（C音） | apply.c, music.c |
| 11 | `sound_Magic_Flute_D.ogg` | `ins_pan_flute` / D音 | 魔法のフルートの演奏音（モンスターを眠らせる）（D音） | apply.c, music.c |
| 12 | `sound_Magic_Flute_E.ogg` | `ins_pan_flute` / E音 | 魔法のフルートの演奏音（モンスターを眠らせる）（E音） | apply.c, music.c |
| 13 | `sound_Magic_Flute_F.ogg` | `ins_pan_flute` / F音 | 魔法のフルートの演奏音（モンスターを眠らせる）（F音） | apply.c, music.c |
| 14 | `sound_Magic_Flute_G.ogg` | `ins_pan_flute` / G音 | 魔法のフルートの演奏音（モンスターを眠らせる）（G音） | apply.c, music.c |
| 15 | `sound_Tooled_Horn_A.ogg` | `ins_english_horn` / A音 | 彫刻された角笛の演奏音（モンスターを起こす）（A音） | apply.c, music.c |
| 16 | `sound_Tooled_Horn_B.ogg` | `ins_english_horn` / B音 | 彫刻された角笛の演奏音（モンスターを起こす）（B音） | apply.c, music.c |
| 17 | `sound_Tooled_Horn_C.ogg` | `ins_english_horn` / C音 | 彫刻された角笛の演奏音（モンスターを起こす）（C音） | apply.c, music.c |
| 18 | `sound_Tooled_Horn_D.ogg` | `ins_english_horn` / D音 | 彫刻された角笛の演奏音（モンスターを起こす）（D音） | apply.c, music.c |
| 19 | `sound_Tooled_Horn_E.ogg` | `ins_english_horn` / E音 | 彫刻された角笛の演奏音（モンスターを起こす）（E音） | apply.c, music.c |
| 20 | `sound_Tooled_Horn_F.ogg` | `ins_english_horn` / F音 | 彫刻された角笛の演奏音（モンスターを起こす）（F音） | apply.c, music.c |
| 21 | `sound_Tooled_Horn_G.ogg` | `ins_english_horn` / G音 | 彫刻された角笛の演奏音（モンスターを起こす）（G音） | apply.c, music.c |
| 22 | `sound_Bugle_A.ogg` | `ins_trumpet` / A音 | ラッパの演奏音（兵士を起こす）（A音） | apply.c, music.c |
| 23 | `sound_Bugle_B.ogg` | `ins_trumpet` / B音 | ラッパの演奏音（兵士を起こす）（B音） | apply.c, music.c |
| 24 | `sound_Bugle_C.ogg` | `ins_trumpet` / C音 | ラッパの演奏音（兵士を起こす）（C音） | apply.c, music.c |
| 25 | `sound_Bugle_D.ogg` | `ins_trumpet` / D音 | ラッパの演奏音（兵士を起こす）（D音） | apply.c, music.c |
| 26 | `sound_Bugle_E.ogg` | `ins_trumpet` / E音 | ラッパの演奏音（兵士を起こす）（E音） | apply.c, music.c |
| 27 | `sound_Bugle_F.ogg` | `ins_trumpet` / F音 | ラッパの演奏音（兵士を起こす）（F音） | apply.c, music.c |
| 28 | `sound_Bugle_G.ogg` | `ins_trumpet` / G音 | ラッパの演奏音（兵士を起こす）（G音） | apply.c, music.c |
| 29 | `sound_Wooden_Harp_A.ogg` | `ins_orchestral_harp` / A音 | 木製ハープの演奏音（ニンフを魅了する）（A音） | apply.c, music.c |
| 30 | `sound_Wooden_Harp_B.ogg` | `ins_orchestral_harp` / B音 | 木製ハープの演奏音（ニンフを魅了する）（B音） | apply.c, music.c |
| 31 | `sound_Wooden_Harp_C.ogg` | `ins_orchestral_harp` / C音 | 木製ハープの演奏音（ニンフを魅了する）（C音） | apply.c, music.c |
| 32 | `sound_Wooden_Harp_D.ogg` | `ins_orchestral_harp` / D音 | 木製ハープの演奏音（ニンフを魅了する）（D音） | apply.c, music.c |
| 33 | `sound_Wooden_Harp_E.ogg` | `ins_orchestral_harp` / E音 | 木製ハープの演奏音（ニンフを魅了する）（E音） | apply.c, music.c |
| 34 | `sound_Wooden_Harp_F.ogg` | `ins_orchestral_harp` / F音 | 木製ハープの演奏音（ニンフを魅了する）（F音） | apply.c, music.c |
| 35 | `sound_Wooden_Harp_G.ogg` | `ins_orchestral_harp` / G音 | 木製ハープの演奏音（ニンフを魅了する）（G音） | apply.c, music.c |
| 36 | `sound_Magic_Harp_A.ogg` | `ins_cello` / A音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（A音） | apply.c, music.c |
| 37 | `sound_Magic_Harp_B.ogg` | `ins_cello` / B音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（B音） | apply.c, music.c |
| 38 | `sound_Magic_Harp_C.ogg` | `ins_cello` / C音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（C音） | apply.c, music.c |
| 39 | `sound_Magic_Harp_D.ogg` | `ins_cello` / D音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（D音） | apply.c, music.c |
| 40 | `sound_Magic_Harp_E.ogg` | `ins_cello` / E音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（E音） | apply.c, music.c |
| 41 | `sound_Magic_Harp_F.ogg` | `ins_cello` / F音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（F音） | apply.c, music.c |
| 42 | `sound_Magic_Harp_G.ogg` | `ins_cello` / G音 | 魔法のハープの演奏音（視界内モンスターを魅了する）（G音） | apply.c, music.c |

#### 固定演奏楽器（音階バリエーションなし・各1ファイル）

Cコアから常に固定音符（`"C"` 等）が渡されるため、音階別ファイルは不要です。

| No. | 音声ファイル名 (.ogg) | 楽器ID | 日本語説明 | 呼び出し元 |
| :--- | :--- | :--- | :--- | :--- |
| 43 | `sound_Frost_Horn.ogg` | `ins_french_horn` | 凍結の角笛の演奏音（冷気の魔法効果） | apply.c, music.c |
| 44 | `sound_Fire_Horn.ogg` | `ins_baritone_sax` | 火炎の角笛の演奏音（炎の魔法効果） | apply.c, music.c |
| 45 | `sound_Bell.ogg` | `ins_tinkle_bell` | ベル・鈴の演奏音（鐘の識別） | apply.c, music.c |
| 46 | `sound_Drum_Of_Earthquake.ogg` | `ins_taiko_drum` | 地震の太鼓の演奏音（ランダムな落とし穴を生成） | apply.c, music.c |
| 47 | `sound_Leather_Drum.ogg` | `ins_melodic_tom` | 革製太鼓の演奏音（周囲のモンスターを起こす） | apply.c, music.c |

---

### 1-D. 声音 (`SetVoice` / `SoundSpeak`) — voice_*.ogg 一覧
`SetVoice` の第4引数（`moreinfo`）の値によって、どの声音ファイルを使用するかを分類します。

| No. | 音声ファイル名 (.ogg) | moreinfo / 種別 | 日本語説明 | 主な呼び出し元 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `voice_deity.ogg` | `voice_deity` | 神（アライメント神）の声・天からの啓示（祈り応答・神罰・神恩寵） | pray.c, minion.c, read.c, teleport.c |
| 2 | `voice_oracle.ogg` | `voice_oracle` | 神託の神官（オラクル）の神秘的な囁き声 | rumors.c |
| 3 | `voice_talking_artifact.ogg` | `voice_talking_artifact` | 意志を持つアーティファクトの発話音 | artifact.c |
| 4 | `voice_throne.ogg` | `voice_throne` | 玉座に座った時に聞こえる声（魔法の玉座からの啓示） | sit.c |
| 5 | `voice_death.ogg` | `voice_death` | 死神・死の声（死の女神への降伏場面） | sounds.c |
| 6 | `voice_shopkeeper.ogg` | `voice_shopkeeper` | 店主の挨拶・売買交渉・怒りの掛け声 | apply.c, shk.c |
| 7 | `voice_mon_generic.ogg` | `voice (moreinfo=0)` | モンスターおよびNPCの一般的な会話・鳴き声 | sounds.c, vault.c, priest.c, その他多数 |

---

## 第2部: Cコアソースコード内 呼び出し箇所一覧（全 369 箇所）

Cコアのソースファイルごとに、どの行でどのサウンドマクロがどのような引数で呼ばれ、どの `.ogg` ファイルに対応するかを示します。

### `allmain.c` （計 2 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L711 | `SoundAchievement` | `0, sa2_splashscreen, 0` | `sa2_splashscreen.ogg` | `SoundAchievement(0, sa2_splashscreen, 0);` |
| L714 | `SoundAchievement` | `0, sa2_newgame_nosplash, 0` | `sa2_newgame_nosplash.ogg` | `SoundAchievement(0, sa2_newgame_nosplash, 0);` |

---

### `apply.c` （計 17 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L364 | `Soundeffect` | `se_faint_splashing, 35` | `se_faint_splashing.ogg` | `Soundeffect(se_faint_splashing, 35);` |
| L371 | `Soundeffect` | `se_crackling_of_hellfire, 35` | `se_crackling_of_hellfire.ogg` | `Soundeffect(se_crackling_of_hellfire, 35);` |
| L378 | `Soundeffect` | `se_heart_beat, 100` | `se_heart_beat.ogg` | `Soundeffect(se_heart_beat, 100);` |
| L390 | `Soundeffect` | `se_typing_noise, 100` | `se_typing_noise.ogg` | `Soundeffect(se_typing_noise, 100);` |
| L460 | `Soundeffect` | `se_hollow_sound, 100` | `se_hollow_sound.ogg` | `Soundeffect(se_hollow_sound, 100);` |
| L494 | `Soundeffect` | `se_shrill_whistle, 50` | `se_shrill_whistle.ogg` | `Soundeffect(se_shrill_whistle, 50);` |
| L518 | `Soundeffect` | `se_magic_whistle, 80` | `se_magic_whistle.ogg` | `Soundeffect(se_magic_whistle, 80);` |
| L1207 | `Hero_playnotes` | `obj_to_instr(obj` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(obj), "C", 100);` |
| L1441 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L1599 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L1674 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L1730 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L2220 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L2229 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3516 | `Soundeffect` | `se_sword_blade_rings, 100` | `se_sword_blade_rings.ogg` | `Soundeffect(se_sword_blade_rings, 100);` |
| L4010 | `Soundeffect` | `se_wall_of_force, 65` | `se_wall_of_force.ogg` | `Soundeffect(se_wall_of_force, 65);` |
| L4485 | `Soundeffect` | `se_rustling_paper, 50` | `se_rustling_paper.ogg` | `Soundeffect(se_rustling_paper, 50);` |

---

### `artifact.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L2324 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_talking_artifact);` |

---

### `ball.c` （計 2 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L909 | `Soundeffect` | `se_destroy_web, 30` | `se_destroy_web.ogg` | `Soundeffect(se_destroy_web, 30);` |
| L1022 | `Soundeffect` | `se_iron_ball_hits_you, 25` | `se_iron_ball_hits_you.ogg` | `Soundeffect(se_iron_ball_hits_you, 25);` |

---

### `dbridge.c` （計 8 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L627 | `Soundeffect` | `se_crushing_sound, 100` | `se_crushing_sound.ogg` | `Soundeffect(se_crushing_sound, 100);` |
| L733 | `Soundeffect` | `se_splash, 100` | `se_splash.ogg` | `Soundeffect(se_splash, 100);` |
| L805 | `Soundeffect` | `se_chains_rattling_gears_turning, 75` | `se_chains_rattling_gears_turning.ogg` | `Soundeffect(se_chains_rattling_gears_turning, 75);` |
| L828 | `Soundeffect` | `se_smashing_and_crushing, 75` | `se_smashing_and_crushing.ogg` | `Soundeffect(se_smashing_and_crushing, 75);` |
| L868 | `Soundeffect` | `se_gears_turning_chains_rattling, 100` | `se_gears_turning_chains_rattling.ogg` | `Soundeffect(se_gears_turning_chains_rattling, 100);` |
| L922 | `Soundeffect` | `se_loud_splash, 100` | `se_loud_splash.ogg` | `Soundeffect(se_loud_splash, 100);  /* Deaf-aware */` |
| L944 | `Soundeffect` | `se_loud_crash, 100` | `se_loud_crash.ogg` | `Soundeffect(se_loud_crash, 100);  /* Deaf-aware */` |
| L1018 | `Soundeffect` | `se_crushing_sound, 75` | `se_crushing_sound.ogg` | `Soundeffect(se_crushing_sound, 75);` |

---

### `dig.c` （計 6 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L98 | `Soundeffect` | `se_crashing_rock, 100` | `se_crashing_rock.ogg` | `Soundeffect(se_crashing_rock, 100);` |
| L354 | `Soundeffect` | `se_bang_weapon_side, 100` | `se_bang_weapon_side.ogg` | `Soundeffect(se_bang_weapon_side, 100);` |
| L953 | `Soundeffect` | `se_kadoom_boulder_falls_in, 60` | `se_kadoom_boulder_falls_in.ogg` | `Soundeffect(se_kadoom_boulder_falls_in, 60);` |
| L1196 | `Soundeffect` | `se_clash, 40` | `se_clash.ogg` | `Soundeffect(se_clash, 40);` |
| L1387 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L1468 | `Soundeffect` | `se_crashing_rock, 75` | `se_crashing_rock.ogg` | `Soundeffect(se_crashing_rock, 75);` |

---

### `do.c` （計 13 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L118 | `Soundeffect` | `se_sizzling, 100` | `se_sizzling.ogg` | `Soundeffect(se_sizzling, 100);` |
| L120 | `Soundeffect` | `se_splash, 100` | `se_splash.ogg` | `Soundeffect(se_splash, 100);` |
| L239 | `Soundeffect` | `se_crashing_boulder, 100` | `se_crashing_boulder.ogg` | `Soundeffect(se_crashing_boulder, 100);` |
| L251 | `Soundeffect` | `se_boulder_drop, 100` | `se_boulder_drop.ogg` | `Soundeffect(se_boulder_drop, 100);` |
| L293 | `Soundeffect` | `se_item_tumble_downwards, 50` | `se_item_tumble_downwards.ogg` | `Soundeffect(se_item_tumble_downwards, 50);` |
| L530 | `Soundeffect` | `se_drain_noises, 50` | `se_drain_noises.ogg` | `Soundeffect(se_drain_noises, 50);` |
| L643 | `Soundeffect` | `se_ring_in_drain, 50` | `se_ring_in_drain.ogg` | `Soundeffect(se_ring_in_drain, 50);` |
| L1297 | `Soundeffect` | `se_stairs_down, 60` | `se_stairs_down.ogg` | `Soundeffect(se_stairs_down, 60);` |
| L1349 | `Soundeffect` | `se_stairs_up, 60` | `se_stairs_up.ogg` | `Soundeffect(se_stairs_up, 60);` |
| L1876 | `Soundeffect` | `se_groans_and_moans, 25` | `se_groans_and_moans.ogg` | `Soundeffect(se_groans_and_moans, 25);` |
| L1905 | `Soundeffect` | `se_alarm, 100` | `se_alarm.ogg` | `Soundeffect(se_alarm, 100);` |
| L2241 | `Soundeffect` | `se_scratching, 50` | `se_scratching.ogg` | `Soundeffect(se_scratching, 50);` |
| L2450 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |

---

### `do_name.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L278 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `dokick.c` （計 25 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L212 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L257 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L339 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L348 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L360 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L388 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L394 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L397 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L453 | `Soundeffect` | `se_egg_cracking, 25` | `se_egg_cracking.ogg` | `Soundeffect(se_egg_cracking, 25);` |
| L455 | `Soundeffect` | `se_glass_shattering, 50` | `se_glass_shattering.ogg` | `Soundeffect(se_glass_shattering, 50);` |
| L658 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L665 | `Soundeffect` | `se_crashing_sound, 60` | `se_crashing_sound.ogg` | `Soundeffect(se_crashing_sound, 60);` |
| L673 | `Soundeffect` | `se_lid_slams_open_falls_shut, 50` | `se_lid_slams_open_falls_shut.ogg` | `Soundeffect(se_lid_slams_open_falls_shut, 50);` |
| L693 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L892 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L945 | `Soundeffect` | `se_kick_door_it_shatters, 50` | `se_kick_door_it_shatters.ogg` | `Soundeffect(se_kick_door_it_shatters, 50);` |
| L950 | `Soundeffect` | `se_kick_door_it_crashes_open, 50` | `se_kick_door_it_crashes_open.ogg` | `Soundeffect(se_kick_door_it_crashes_open, 50);` |
| L970 | `Soundeffect` | `se_kick, 50` | `se_kick.ogg` | `Soundeffect(se_kick, 50);` |
| L983 | `Soundeffect` | `se_crash_door, 40` | `se_crash_door.ogg` | `Soundeffect(se_crash_door, 40);` |
| L1008 | `Soundeffect` | `se_crash_door, 40` | `se_crash_door.ogg` | `Soundeffect(se_crash_door, 40);` |
| L1030 | `Soundeffect` | `se_crash_throne_destroyed, 60` | `se_crash_throne_destroyed.ogg` | `Soundeffect(se_crash_throne_destroyed, 60);` |
| L1208 | `Soundeffect` | `se_klunk_pipe, 60` | `se_klunk_pipe.ogg` | `Soundeffect(se_klunk_pipe, 60);` |
| L1217 | `Soundeffect` | `se_gushing_sound, 100` | `se_gushing_sound.ogg` | `Soundeffect(se_gushing_sound, 100);` |
| L1738 | `Soundeffect` | `se_egg_splatting, 25` | `se_egg_splatting.ogg` | `Soundeffect(se_egg_splatting, 25);` |
| L1740 | `Soundeffect` | `se_glass_crashing, 25` | `se_glass_crashing.ogg` | `Soundeffect(se_glass_crashing, 25);` |

---

### `dothrow.c` （計 2 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1867 | `Soundeffect` | `se_splash, 50` | `se_splash.ogg` | `Soundeffect(se_splash, 50);` |
| L2702 | `Soundeffect` | `se_potion_crash_and_break, in_view ? 80 : 60` | `se_potion_crash_and_break.ogg` | `Soundeffect(se_potion_crash_and_break, in_view ? 80 : 60);` |

---

### `eat.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L2762 | `Soundeffect` | `se_sinister_laughter, 100` | `se_sinister_laughter.ogg` | `Soundeffect(se_sinister_laughter, 100);` |
| L3586 | `Soundeffect` | `se_hunger, 80` | `se_hunger.ogg` | `Soundeffect(se_hunger, 80);` |
| L3635 | `Soundeffect` | `se_hunger, 60` | `se_hunger.ogg` | `Soundeffect(se_hunger, 60);` |
| L3650 | `Soundeffect` | `se_hunger, 70` | `se_hunger.ogg` | `Soundeffect(se_hunger, 70);` |

---

### `exper.c` （計 2 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L232 | `SoundAchievement` | `0, sa2_xpleveldown, 0` | `sa2_xpleveldown.ogg` | `SoundAchievement(0, sa2_xpleveldown, 0);` |
| L357 | `SoundAchievement` | `0, sa2_xplevelup, 0` | `sa2_xplevelup.ogg` | `SoundAchievement(0, sa2_xplevelup, 0);` |

---

### `explode.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L612 | `Soundeffect` | `se_blast, 75` | `se_blast.ogg` | `Soundeffect(se_blast, 75);` |
| L933 | `Soundeffect` | `se_chain_shatters, 25` | `se_chain_shatters.ogg` | `Soundeffect(se_chain_shatters, 25);` |
| L959 | `Soundeffect` | `se_stone_breaking, 100` | `se_stone_breaking.ogg` | `Soundeffect(se_stone_breaking, 100);` |
| L977 | `Soundeffect` | `se_stone_crumbling, 100` | `se_stone_crumbling.ogg` | `Soundeffect(se_stone_crumbling, 100);` |

---

### `fountain.c` （計 8 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L49 | `Soundeffect` | `se_snakes_hissing, 75` | `se_snakes_hissing.ogg` | `Soundeffect(se_snakes_hissing, 75);` |
| L58 | `Soundeffect` | `se_furious_bubbling, 20` | `se_furious_bubbling.ogg` | `Soundeffect(se_furious_bubbling, 20);` |
| L88 | `Soundeffect` | `se_furious_bubbling, 20` | `se_furious_bubbling.ogg` | `Soundeffect(se_furious_bubbling, 20);` |
| L110 | `Soundeffect` | `se_bubble_rising, 50` | `se_bubble_rising.ogg` | `Soundeffect(se_bubble_rising, 50);` |
| L111 | `Soundeffect` | `se_loud_pop, 50` | `se_loud_pop.ogg` | `Soundeffect(se_loud_pop, 50);` |
| L114 | `Soundeffect` | `se_loud_pop, 50` | `se_loud_pop.ogg` | `Soundeffect(se_loud_pop, 50);` |
| L688 | `Soundeffect` | `se_clanking_pipe, 50` | `se_clanking_pipe.ogg` | `Soundeffect(se_clanking_pipe, 50);` |
| L692 | `Soundeffect` | `se_sewer_song, 100` | `se_sewer_song.ogg` | `Soundeffect(se_sewer_song, 100);` |

---

### `hack.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L465 | `Soundeffect` | `se_monster_behind_boulder, 50` | `se_monster_behind_boulder.ogg` | `Soundeffect(se_monster_behind_boulder, 50);` |
| L537 | `Soundeffect` | `se_kerplunk_boulder_gone, 40` | `se_kerplunk_boulder_gone.ogg` | `Soundeffect(se_kerplunk_boulder_gone, 40);` |
| L3716 | `SetVoice` | `oracle, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(oracle, 0, 80, 0);` |
| L4241 | `Soundeffect` | `se_wailing_of_the_banshee, 75` | `se_wailing_of_the_banshee.ogg` | `Soundeffect(se_wailing_of_the_banshee, 75);` |

---

### `insight.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L2407 | `SoundAchievement` | `achidx, 0, repeat_achievement` | `ach_*.ogg (achidxに応じたACH実績音)` | `SoundAchievement(achidx, 0, repeat_achievement);` |

---

### `lock.c` （計 13 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L136 | `Soundeffect` | `se_klick, 50` | `se_klick.ogg` | `Soundeffect(se_klick, 50);` |
| L144 | `Soundeffect` | `se_klick, 50` | `se_klick.ogg` | `Soundeffect(se_klick, 50);` |
| L154 | `Soundeffect` | `se_force_lock, 60` | `se_force_lock.ogg` | `Soundeffect(se_force_lock, 60);` |
| L168 | `Soundeffect` | `se_crashing_sound, 70` | `se_crashing_sound.ogg` | `Soundeffect(se_crashing_sound, 70);` |
| L552 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L893 | `Soundeffect` | `se_door_open, 80` | `se_door_open.ogg` | `Soundeffect(se_door_open, 80);` |
| L1030 | `Soundeffect` | `se_door_close, 80` | `se_door_close.ogg` | `Soundeffect(se_door_close, 80);` |
| L1055 | `Soundeffect` | `se_klunk, 50` | `se_klunk.ogg` | `Soundeffect(se_klunk, 50);` |
| L1069 | `Soundeffect` | `se_klick, 50` | `se_klick.ogg` | `Soundeffect(se_klick, 50);` |
| L1136 | `Soundeffect` | `se_swoosh, 25` | `se_swoosh.ogg` | `Soundeffect(se_swoosh, 25);` |
| L1211 | `Soundeffect` | `se_kaboom_door_explodes, 75` | `se_kaboom_door_explodes.ogg` | `Soundeffect(se_kaboom_door_explodes, 75);` |
| L1215 | `Soundeffect` | `se_explosion, 75` | `se_explosion.ogg` | `Soundeffect(se_explosion, 75);` |
| L1233 | `Soundeffect` | `se_crashing_sound, 100` | `se_crashing_sound.ogg` | `Soundeffect(se_crashing_sound, 100);` |

---

### `mail.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L339 | `SetVoice` | `md, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(md, 0, 80, 0);` |
| L373 | `SetVoice` | `md, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(md, 0, 80, 0);` |
| L418 | `SetVoice` | `md, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(md, 0, 80, 0);` |
| L434 | `SetVoice` | `md, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(md, 0, 80, 0);` |

---

### `mcastu.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L210 | `Soundeffect` | `se_air_crackles, 60` | `se_air_crackles.ogg` | `Soundeffect(se_air_crackles, 60);` |
| L434 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L576 | `Soundeffect` | `se_bolt_of_lightning, 80` | `se_bolt_of_lightning.ogg` | `Soundeffect(se_bolt_of_lightning, 80);` |
| L692 | `Soundeffect` | `se_someone_summoning, 100` | `se_someone_summoning.ogg` | `Soundeffect(se_someone_summoning, 100);` |

---

### `mhitu.c` （計 7 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L921 | `Soundeffect` | `se_rushing_wind_noise, 60` | `se_rushing_wind_noise.ogg` | `Soundeffect(se_rushing_wind_noise, 60);` |
| L2089 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L2120 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L2194 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L2339 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L2377 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0); /* y_n aka yn_function is set up for this */` |
| L2387 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |

---

### `minion.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L303 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L533 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L566 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L575 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |

---

### `mkobj.c` （計 3 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L799 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L810 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3839 | `Soundeffect` | `se_faint_sloshing, 25` | `se_faint_sloshing.ogg` | `Soundeffect(se_faint_sloshing, 25);` |

---

### `mon.c` （計 7 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1518 | `Soundeffect` | `se_crunching_sound, 50` | `se_crunching_sound.ogg` | `Soundeffect(se_crunching_sound, 50);` |
| L1631 | `Soundeffect` | `se_slurping_sound, 30` | `se_slurping_sound.ogg` | `Soundeffect(se_slurping_sound, 30);` |
| L1710 | `Soundeffect` | `se_masticating_sound, 50` | `se_masticating_sound.ogg` | `Soundeffect(se_masticating_sound, 50);` |
| L3725 | `Soundeffect` | `se_distant_thunder, 40` | `se_distant_thunder.ogg` | `Soundeffect(se_distant_thunder, 40);` |
| L3728 | `Soundeffect` | `se_applause, 40` | `se_applause.ogg` | `Soundeffect(se_applause, 40);` |
| L4197 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L5764 | `Soundeffect` | `se_shrill_whistle, 100` | `se_shrill_whistle.ogg` | `Soundeffect(se_shrill_whistle, 100);` |

---

### `monmove.c` （計 7 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L121 | `Soundeffect` | `se_someone_yells, 75` | `se_someone_yells.ogg` | `/* Soundeffect(se_someone_yells, 75); */` |
| L124 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L511 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L1562 | `Soundeffect` | `se_door_unlock_and_open, 50` | `se_door_unlock_and_open.ogg` | `Soundeffect(se_door_unlock_and_open, 50);` |
| L1580 | `Soundeffect` | `se_door_open, 100` | `se_door_open.ogg` | `Soundeffect(se_door_open, 100);` |
| L1604 | `Soundeffect` | `se_door_crash_open, 50` | `se_door_crash_open.ogg` | `Soundeffect(se_door_crash_open, 50);` |
| L1834 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `mplayer.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L375 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `mthrowu.c` （計 6 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L407 | `Soundeffect` | `se_splat_egg, 35` | `se_splat_egg.ogg` | `Soundeffect(se_splat_egg, 35);` |
| L980 | `Soundeffect` | `se_splash, 50` | `se_splash.ogg` | `Soundeffect(se_splash, 50);` |
| L1051 | `Soundeffect` | `se_dry_throat_rattle, 50` | `se_dry_throat_rattle.ogg` | `Soundeffect(se_dry_throat_rattle, 50);` |
| L1129 | `Soundeffect` | `se_cough, 100` | `se_cough.ogg` | `Soundeffect(se_cough, 100);` |
| L1462 | `Soundeffect` | `se_angry_snakes, 100` | `se_angry_snakes.ogg` | `Soundeffect(se_angry_snakes, 100);` |
| L1489 | `Soundeffect` | `se[bsindx], 100` | `se_unknown.ogg` | `Soundeffect(se[bsindx], 100);` |

---

### `muse.c` （計 10 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L118 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L148 | `Soundeffect` | `se_zap_then_explosion, 100` | `se_zap_then_explosion.ogg` | `Soundeffect(se_zap_then_explosion, 100);` |
| L181 | `Soundeffect` | `se_zap, 100` | `se_zap.ogg` | `Soundeffect(se_zap, 100);` |
| L208 | `Soundeffect` | `se_horn_being_played, 50` | `se_horn_being_played.ogg` | `Soundeffect(se_horn_being_played, 50);` |
| L297 | `Soundeffect` | `se_mon_chugging_potion, 25` | `se_mon_chugging_potion.ogg` | `Soundeffect(se_mon_chugging_potion, 25);` |
| L842 | `Soundeffect` | `se_bugle_playing_reveille, 100` | `se_bugle_playing_reveille.ogg` | `Soundeffect(se_bugle_playing_reveille, 100);` |
| L961 | `Soundeffect` | `se_crash_through_floor, 100` | `se_crash_through_floor.ogg` | `Soundeffect(se_crash_through_floor, 100);` |
| L1610 | `Soundeffect` | `se_boing, 40` | `se_boing.ogg` | `Soundeffect(se_boing, 40);` |
| L1629 | `Soundeffect` | `se_boing, 40` | `se_boing.ogg` | `Soundeffect(se_boing, 40);` |
| L1936 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `music.c` （計 17 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L268 | `Soundeffect` | `se_scream, 50` | `se_scream.ogg` | `Soundeffect(se_scream, 50);` |
| L377 | `Soundeffect` | `se_thump, 50` | `se_thump.ogg` | `Soundeffect(se_thump, 50);` |
| L594 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L607 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L624 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L633 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L646 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 80);` |
| L656 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 80);` |
| L669 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L684 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L697 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), "C", 100);` |
| L709 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), "CCC", 100);` |
| L719 | `Hero_playnotes` | `obj_to_instr(&itmp` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(&itmp), improvisation, 50);` |
| L808 | `Hero_playnotes` | `obj_to_instr(instr` | `sound_[楽器名]_[音符].ogg` | `Hero_playnotes(obj_to_instr(instr), buf, 50);` |
| L871 | `Soundeffect` | `se_tumbler_click, 50` | `se_tumbler_click.ogg` | `Soundeffect(se_tumbler_click, 50);` |
| L872 | `Soundeffect` | `se_gear_turn, 50` | `se_gear_turn.ogg` | `Soundeffect(se_gear_turn, 50);` |
| L876 | `Soundeffect` | `se_tumbler_click, 50` | `se_tumbler_click.ogg` | `Soundeffect(se_tumbler_click, 50);` |

---

### `pickup.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L2447 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, 0);` |

---

### `pline.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L80 | `SoundSpeak` | `line` | `voice_*.ogg` | `SoundSpeak(line);` |

---

### `potion.c` （計 11 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L101 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L123 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L158 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L210 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L239 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L259 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L311 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L421 | `Soundeffect` | `se_debuff, 60` | `se_debuff.ogg` | `Soundeffect(se_debuff, 60);` |
| L1655 | `Soundeffect` | `se_potion_crash_and_break, 60` | `se_potion_crash_and_break.ogg` | `Soundeffect(se_potion_crash_and_break, 60);` |
| L1672 | `Soundeffect` | `se_potion_crash_and_break, 60` | `se_potion_crash_and_break.ogg` | `Soundeffect(se_potion_crash_and_break, 60);` |
| L2831 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `pray.c` （計 14 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L687 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L692 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L744 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L768 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L843 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L854 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L867 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L1231 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L1235 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L1241 | `Soundeffect` | `se_divine_music, 50` | `se_divine_music.ogg` | `Soundeffect(se_divine_music, 50);` |
| L1341 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L1585 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |
| L1616 | `Soundeffect` | `se_thunderclap, 100` | `se_thunderclap.ogg` | `Soundeffect(se_thunderclap, 100);` |
| L2786 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |

---

### `priest.c` （計 9 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L459 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L593 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L601 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L649 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L656 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L660 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L666 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L694 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |
| L701 | `SetVoice` | `priest, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(priest, 0, 80, 0);` |

---

### `quest.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L459 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `read.c` （計 3 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1694 | `Soundeffect` | `se_sad_wailing, 50` | `se_sad_wailing.ogg` | `Soundeffect(se_sad_wailing, 50);` |
| L1696 | `Soundeffect` | `se_maniacal_laughter, 50` | `se_maniacal_laughter.ogg` | `Soundeffect(se_maniacal_laughter, 50);` |
| L3132 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |

---

### `rumors.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L587 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_oracle);` |

---

### `shk.c` （計 34 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L520 | `Soundeffect` | `se_alarm, 80` | `se_alarm.ogg` | `Soundeffect(se_alarm, 80);` |
| L611 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L805 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L818 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L830 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L840 | `Soundeffect` | `se_mutter_imprecations, 50` | `se_mutter_imprecations.ogg` | `Soundeffect(se_mutter_imprecations, 50);` |
| L898 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L913 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L950 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L2040 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L2471 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3145 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3148 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3158 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L3995 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L4032 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L4404 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L4592 | `Soundeffect` | `se_mutter_incantation, 100` | `se_mutter_incantation.ogg` | `Soundeffect(se_mutter_incantation, 100);` |
| L4670 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L4931 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L4940 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5067 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5169 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5178 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5291 | `Soundeffect` | `se_angry_voice, 75` | `se_angry_voice.ogg` | `/* Soundeffect(se_angry_voice, 75); */` |
| L5293 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5352 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5468 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5475 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5565 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5572 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L5743 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L6120 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |
| L6144 | `SetVoice` | `shkp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(shkp, 0, 80, 0);` |

---

### `sit.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L119 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_throne);` |
| L129 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_throne);` |
| L137 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_throne);` |
| L459 | `Soundeffect` | `se_squelch, 30` | `se_squelch.ogg` | `Soundeffect(se_squelch, 30);` |

---

### `sounds.c` （計 53 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L46 | `Soundeffect` | `se_courtly_conversation, 30` | `se_courtly_conversation.ogg` | `Soundeffect(se_courtly_conversation, 30);` |
| L48 | `Soundeffect` | `se_sceptor_pounding, 100` | `se_sceptor_pounding.ogg` | `Soundeffect(se_sceptor_pounding, 100);` |
| L71 | `Soundeffect` | `se_low_buzzing, 30` | `se_low_buzzing.ogg` | `Soundeffect(se_low_buzzing, 30);` |
| L75 | `Soundeffect` | `se_angry_drone, 100` | `se_angry_drone.ogg` | `Soundeffect(se_angry_drone, 100);` |
| L79 | `Soundeffect` | `se_bees, 100` | `se_bees.ogg` | `Soundeffect(se_bees, 100);` |
| L262 | `Soundeffect` | `se_someone_searching, 30` | `se_someone_searching.ogg` | `Soundeffect(se_someone_searching, 30);` |
| L271 | `Soundeffect` | `se_guards_footsteps, 30` | `se_guards_footsteps.ogg` | `Soundeffect(se_guards_footsteps, 30);` |
| L550 | `Soundeffect` | `se, 70` | `se_unknown.ogg` | `Soundeffect(se, 70);  /* Soundeffect() handles Deaf or not Deaf */` |
| L589 | `Soundeffect` | `se, 50` | `se_unknown.ogg` | `Soundeffect(se, 50);` |
| L618 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L955 | `Soundeffect` | `(ptr == &mons[PM_HUMAN_WERERAT]` | `se_unknown.ogg` | `Soundeffect((ptr == &mons[PM_HUMAN_WERERAT]) ? se_scream` |
| L986 | `Soundeffect` | `se_feline_yowl, 80` | `se_feline_yowl.ogg` | `Soundeffect(se_feline_yowl, 80);` |
| L989 | `Soundeffect` | `se_feline_meow, 80` | `se_feline_meow.ogg` | `Soundeffect(se_feline_meow, 80);` |
| L992 | `Soundeffect` | `se_feline_purr, 40` | `se_feline_purr.ogg` | `Soundeffect(se_feline_purr, 40);` |
| L995 | `Soundeffect` | `se_feline_mew, 60` | `se_feline_mew.ogg` | `Soundeffect(se_feline_mew, 60);` |
| L1003 | `Soundeffect` | `(mtmp->mpeaceful ? se_snarl : se_growl` | `se_snarl.ogg` | `Soundeffect((mtmp->mpeaceful ? se_snarl : se_growl), 80);` |
| L1007 | `Soundeffect` | `(mtmp->mpeaceful ? se_snarl : se_roar` | `se_snarl.ogg` | `Soundeffect((mtmp->mpeaceful ? se_snarl : se_roar), 80);` |
| L1011 | `Soundeffect` | `se_squeak, 80` | `se_squeak.ogg` | `Soundeffect(se_squeak, 80);` |
| L1018 | `Soundeffect` | `se_squawk, 80` | `se_squawk.ogg` | `Soundeffect(se_squawk, 80);` |
| L1024 | `Soundeffect` | `se_hiss, 80` | `se_hiss.ogg` | `Soundeffect(se_hiss, 80);` |
| L1031 | `Soundeffect` | `(mtmp->mpeaceful ? se_buzz : se_angry_drone` | `se_buzz.ogg` | `Soundeffect((mtmp->mpeaceful ? se_buzz : se_angry_drone), 80);` |
| L1035 | `Soundeffect` | `se_grunt, 60` | `se_grunt.ogg` | `Soundeffect(se_grunt, 60);` |
| L1040 | `Soundeffect` | `se_equine_neigh, 60` | `se_equine_neigh.ogg` | `Soundeffect(se_equine_neigh, 60);` |
| L1043 | `Soundeffect` | `se_equine_whinny, 60` | `se_equine_whinny.ogg` | `Soundeffect(se_equine_whinny, 60);` |
| L1046 | `Soundeffect` | `se_equine_whicker, 60` | `se_equine_whicker.ogg` | `Soundeffect(se_equine_whicker, 60);` |
| L1051 | `Soundeffect` | `se_bovine_moo, 80` | `se_bovine_moo.ogg` | `Soundeffect(se_bovine_moo, 80);` |
| L1055 | `Soundeffect` | `(ptr->mlet == S_QUADRUPED` | `se_unknown.ogg` | `Soundeffect((ptr->mlet == S_QUADRUPED) ? se_bovine_bellow` |
| L1061 | `Soundeffect` | `se_chirp, 60` | `se_chirp.ogg` | `Soundeffect(se_chirp, 60);` |
| L1065 | `Soundeffect` | `se_sad_wailing, 60` | `se_sad_wailing.ogg` | `Soundeffect(se_sad_wailing, 60);` |
| L1070 | `Soundeffect` | `se_groan, 60` | `se_groan.ogg` | `Soundeffect(se_groan, 60);` |
| L1075 | `Soundeffect` | `se_gurgle, 60` | `se_gurgle.ogg` | `Soundeffect(se_gurgle, 60);` |
| L1079 | `Soundeffect` | `se_jabberwock_burble, 60` | `se_jabberwock_burble.ogg` | `Soundeffect(se_jabberwock_burble, 60);` |
| L1083 | `Soundeffect` | `se_elephant_trumpet, 60` | `se_elephant_trumpet.ogg` | `Soundeffect(se_elephant_trumpet, 60);` |
| L1088 | `Soundeffect` | `se_shriek, 60` | `se_shriek.ogg` | `Soundeffect(se_shriek, 60);` |
| L1096 | `Soundeffect` | `se_bone_rattle, 60` | `se_bone_rattle.ogg` | `Soundeffect(se_bone_rattle, 60);` |
| L1107 | `Soundeffect` | `se_laughter, 60` | `se_laughter.ogg` | `Soundeffect(se_laughter, 60);` |
| L1115 | `Soundeffect` | `se_orc_grunt, 60` | `se_orc_grunt.ogg` | `Soundeffect(se_orc_grunt, 60);` |
| L1257 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L1353 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L1362 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_death);` |
| L1365 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L1789 | `Play_usersound` | `snd->filename, snd->volume, snd->idx` | `usersound_custom.ogg` | `Play_usersound(snd->filename, snd->volume, snd->idx);` |
| L1806 | `Play_usersound` | `snd->filename, snd->volume, snd->idx` | `usersound_custom.ogg` | `Play_usersound(snd->filename, snd->volume, snd->idx);` |
| L2549 | `Soundeffect` | `seid, vol` | `se_combat_hit_*.ogg` | `Soundeffect(seid, vol); /* nh_sound_melee_hit */` |
| L2560 | `Soundeffect` | `se_combat_miss, vol` | `se_combat_miss.ogg` | `Soundeffect(se_combat_miss, vol); /* nh_sound_melee_miss */` |
| L2590 | `Soundeffect` | `seid, vol` | `se_combat_shoot_*.ogg` | `Soundeffect(seid, vol); /* nh_sound_shoot */` |
| L2610 | `Soundeffect` | `seid, vol` | `se_combat_throw*.ogg` | `Soundeffect(seid, vol); /* nh_sound_throw */` |
| L2640 | `Soundeffect` | `seid, vol` | `se_combat_hit_other.ogg 等` | `Soundeffect(seid, vol); /* nh_sound_missile_hit */` |
| L2654 | `Soundeffect` | `se_combat_miss, vol` | `se_combat_miss.ogg` | `Soundeffect(se_combat_miss, vol); /* nh_sound_mon_attack */` |
| L2659 | `Soundeffect` | `se_mon_claw, vol` | `se_mon_claw.ogg` | `Soundeffect(se_mon_claw, vol); /* nh_sound_mon_attack */` |
| L2705 | `Soundeffect` | `seid, vol` | `se_mon_*.ogg` | `Soundeffect(seid, vol); /* nh_sound_mon_attack */` |
| L2716 | `Soundeffect` | `se_combat_spell_cast, vol` | `se_combat_spell_cast.ogg` | `Soundeffect(se_combat_spell_cast, vol); /* nh_sound_spell_cast */` |
| L2727 | `Soundeffect` | `se_combat_wand_zap, vol` | `se_combat_wand_zap.ogg` | `Soundeffect(se_combat_wand_zap, vol); /* nh_sound_wand_zap */` |

---

### `spell.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L256 | `Soundeffect` | `se_faint_chime, 30` | `se_faint_chime.ogg` | `Soundeffect(se_faint_chime, 30);` |

---

### `teleport.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1340 | `SetVoice` | `(struct monst *` | `voice_mon_generic.ogg` | `SetVoice((struct monst *) 0, 0, 80, voice_deity);` |

---

### `timeout.c` （計 2 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1122 | `SetVoice` | `mon, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mon, 0, 80, 0);` |
| L1872 | `Soundeffect` | `se_kaboom_boom_boom, 80` | `se_kaboom_boom_boom.ogg` | `Soundeffect(se_kaboom_boom_boom, 80);` |

---

### `trap.c` （計 40 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1228 | `Soundeffect` | `se_loud_click, 100` | `se_loud_click.ogg` | `Soundeffect(se_loud_click, 100);` |
| L1236 | `Soundeffect` | `se_combat_shoot_bow, 70` | `se_combat_shoot_bow.ogg` | `Soundeffect(se_combat_shoot_bow, 70);` |
| L1269 | `Soundeffect` | `se_combat_shoot_bow, 50` | `se_combat_shoot_bow.ogg` | `Soundeffect(se_combat_shoot_bow, 50);` |
| L1294 | `Soundeffect` | `se_soft_click, 30` | `se_soft_click.ogg` | `Soundeffect(se_soft_click, 30);` |
| L1302 | `Soundeffect` | `se_swoosh, 60` | `se_swoosh.ogg` | `Soundeffect(se_swoosh, 60);` |
| L1345 | `Soundeffect` | `se_swoosh, 40` | `se_swoosh.ogg` | `Soundeffect(se_swoosh, 40);` |
| L1377 | `Soundeffect` | `se_crashing_rock, 80` | `se_crashing_rock.ogg` | `Soundeffect(se_crashing_rock, 80);` |
| L1427 | `Soundeffect` | `se_crashing_rock, 60` | `se_crashing_rock.ogg` | `Soundeffect(se_crashing_rock, 60);` |
| L1467 | `Soundeffect` | `tsnds[trap->tnote], 50` | `se_squeak_*.ogg` (12音階) | `Soundeffect(tsnds[trap->tnote], 50);` |
| L1484 | `Soundeffect` | `tsnds[trap->tnote], 50` | `se_squeak_*.ogg` (12音階) | `Soundeffect(tsnds[trap->tnote], 50);` |
| L1501 | `Soundeffect` | `tsnds[trap->tnote], ...` | `se_squeak_*.ogg` (12音階) | `Soundeffect(tsnds[trap->tnote], ...);` |
| L1542 | `Soundeffect` | `se_bear_trap, 80` | `se_bear_trap.ogg` | `Soundeffect(se_bear_trap, 80);` |
| L1570 | `Soundeffect` | `se_bear_trap, 60` | `se_bear_trap.ogg` | `Soundeffect(se_bear_trap, 60);` |
| L1578 | `Soundeffect` | `se_roar, 100` | `se_roar.ogg` | `Soundeffect(se_roar, 100);` |
| L1607 | `Soundeffect` | `se_hiss, 70` | `se_hiss.ogg` | `Soundeffect(se_hiss, 70);` |
| L1623 | `Soundeffect` | `se_hiss, 50` | `se_hiss.ogg` | `Soundeffect(se_hiss, 50);` |
| L1643 | `Soundeffect` | `se_gushing_sound, 80` | `se_gushing_sound.ogg` | `Soundeffect(se_gushing_sound, 80);` |
| L1702 | `Soundeffect` | `se_gushing_sound, 60` | `se_gushing_sound.ogg` | `Soundeffect(se_gushing_sound, 60);` |
| L1779 | `Soundeffect` | `se_blast, 80` | `se_blast.ogg` | `Soundeffect(se_blast, 80);` |
| L1790 | `Soundeffect` | `se_blast, 60` | `se_blast.ogg` | `Soundeffect(se_blast, 60);` |
| L1966 | `Soundeffect` | `se_thud, 75` | `se_thud.ogg` | `Soundeffect(se_thud, 75);` |
| L2039 | `Soundeffect` | `se_thud, 55` | `se_thud.ogg` | `Soundeffect(se_thud, 55);` |
| L2073 | `Soundeffect` | `se_thud, 75` | `se_thud.ogg` | `Soundeffect(se_thud, 75);` |
| L2126 | `Soundeffect` | `se_teleport, 80` | `se_teleport.ogg` | `Soundeffect(se_teleport, 80);` |
| L2132 | `Soundeffect` | `se_teleport, 60` | `se_teleport.ogg` | `Soundeffect(se_teleport, 60);` |
| L2147 | `Soundeffect` | `se_teleport, 80` | `se_teleport.ogg` | `Soundeffect(se_teleport, 80);` |
| L2154 | `Soundeffect` | `se_teleport, 60` | `se_teleport.ogg` | `Soundeffect(se_teleport, 60);` |
| L2274 | `Soundeffect` | `se_roar, 60` | `se_roar.ogg` | `Soundeffect(se_roar, 60);` |
| L2339 | `Soundeffect` | `se_stone_crumbling, 75` | `se_stone_crumbling.ogg` | `Soundeffect(se_stone_crumbling, 75);` |
| L2392 | `Soundeffect` | `se_mana_drain, 80` | `se_mana_drain.ogg` | `Soundeffect(se_mana_drain, 80);` |
| L2407 | `Soundeffect` | `se_mana_drain, 80` | `se_mana_drain.ogg` | `Soundeffect(se_mana_drain, 80);` |
| L2526 | `Soundeffect` | `se_polymorph, 80` | `se_polymorph.ogg` | `Soundeffect(se_polymorph, 80);` |
| L2578 | `Soundeffect` | `se_polymorph, 60` | `se_polymorph.ogg` | `Soundeffect(se_polymorph, 60);` |
| L2621 | `Soundeffect` | `se_kaablamm_of_mine, 80` | `se_kaablamm_of_mine.ogg` | `Soundeffect(se_kaablamm_of_mine, 80);` |
| L3381 | `Soundeffect` | `se_someone_bowling, 60` | `se_someone_bowling.ogg` | `Soundeffect(se_someone_bowling, 60);` |
| L3384 | `Soundeffect` | `se_rumbling, 60` | `se_rumbling.ogg` | `Soundeffect(se_rumbling, 60);` |
| L3578 | `Soundeffect` | `se_loud_crash, 80` | `se_loud_crash.ogg` | `Soundeffect(se_loud_crash, 80);` |
| L4409 | `Soundeffect` | `se_deafening_roar_atmospheric, 100` | `se_deafening_roar_atmospheric.ogg` | `Soundeffect(se_deafening_roar_atmospheric, 100);` |
| L4430 | `Soundeffect` | `se_low_hum, 100` | `se_low_hum.ogg` | `Soundeffect(se_low_hum, 100);` |
| L6771 | `Soundeffect` | `se_kaboom, 80` | `se_kaboom.ogg` | `Soundeffect(se_kaboom, 80);` |
---

### `uhitm.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L3050 | `Soundeffect` | `se_laughter, 40` | `se_laughter.ogg` | `Soundeffect(se_laughter, 40);` |
| L4223 | `Soundeffect` | `se_cockatrice_hiss, 50` | `se_cockatrice_hiss.ogg` | `Soundeffect(se_cockatrice_hiss, 50);` |
| L4375 | `SetVoice` | `magr, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(magr, 0, 80, 0);` |
| L4534 | `SetVoice` | `magr, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(magr, 0, 80, 0);` |

---

### `vault.c` （計 18 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L466 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L478 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L495 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L529 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L541 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L557 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L566 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L576 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L586 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L589 | `SetVoice` | `guard, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(guard, 0, 80, 0);` |
| L748 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L943 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L963 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L975 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L1008 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L1039 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L1049 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |
| L1077 | `SetVoice` | `grd, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(grd, 0, 80, 0);` |

---

### `were.c` （計 1 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L36 | `Soundeffect` | `se_canine_howl, 50` | `se_canine_howl.ogg` | `Soundeffect(se_canine_howl, 50);` |

---

### `wizard.c` （計 5 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L776 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L854 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L858 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L863 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |
| L866 | `SetVoice` | `mtmp, 0, 80, 0` | `voice_shopkeeper.ogg または voice_mon_generic.ogg` | `SetVoice(mtmp, 0, 80, 0);` |

---

### `worn.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L1191 | `Soundeffect` | `se_cracking_sound, 100` | `se_cracking_sound.ogg` | `Soundeffect(se_cracking_sound, 100);` |
| L1209 | `Soundeffect` | `se_ripping_sound, 100` | `se_ripping_sound.ogg` | `Soundeffect(se_ripping_sound, 100);` |
| L1231 | `Soundeffect` | `se_thud, 50` | `se_thud.ogg` | `Soundeffect(se_thud, 50);` |
| L1275 | `Soundeffect` | `se_clank, 50` | `se_clank.ogg` | `Soundeffect(se_clank, 50);` |

---

### `zap.c` （計 4 箇所）

| 行番号 | マクロ | 引数 / サウンドID | 対応 .ogg ファイル | コードスニペット |
| :--- | :--- | :--- | :--- | :--- |
| L2296 | `Soundeffect` | `se_crumbling_sound, 75` | `se_crumbling_sound.ogg` | `Soundeffect(se_crumbling_sound, 75);` |
| L4234 | `Soundeffect` | `se_boomerang_klonk, 75` | `se_boomerang_klonk.ogg` | `Soundeffect(se_boomerang_klonk, 75);` |
| L5263 | `Soundeffect` | `se_soft_crackling, 100` | `se_soft_crackling.ogg` | `Soundeffect(se_soft_crackling, 100);` |
| L5296 | `Soundeffect` | `se_soft_crackling, 30` | `se_soft_crackling.ogg` | `Soundeffect(se_soft_crackling, 30);` |

---

