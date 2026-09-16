# NetHack 声音・発話（TTS/ボイス）仕様書 (Voice & Speech Specifications)

本ドキュメントは、NetHack のサウンドサブシステムにおける **声音・発話機能（`SetVoice` および `SoundSpeak`）** の仕様、アーキテクチャ、Cコア内の全呼び出し箇所（132箇所）、推奨音声ファイル名（`.ogg`）、およびテキスト音声合成（TTS）連携設計を整理した仕様書である。

---

## 1. 概要とアーキテクチャ

### 1.1 `SetVoice` と `SoundSpeak` の対構造
NetHack 5.0 の発話サブシステムは、**話者設定（`SetVoice`）** と **発話実行（`SoundSpeak`）** の2段階で構成されている。

1. **話者情報の事前設定 (`SetVoice`)**:
   発話直前に `SetVoice(mon, tone, vol, moreinfo)` を呼び出し、内部の静的構造体 `voice` に話者のモンスター情報、声のトーン、音量、特殊フラグを設定する。
2. **発話の実行 (`SoundSpeak`)**:
   `verbalize(...)` や `pline(..., PLINE_VERBALIZE)` が呼ばれると、内部で `SoundSpeak(text)` → `(*soundprocs.sound_verbal)(text, gender, tone, vol, moreinfo)` が実行され、移植層へ音声テキストと話者パラメータが渡される。

```c
/* Cコア内部の発話フロー */
SetVoice(shkp, 0, 80, 0);
verbalize("いらっしゃいませ、%s!", svp.plname);
  └─> SoundSpeak(text)
        └─> (*soundprocs.sound_verbal)(text, gender, tone, vol, moreinfo);
```

### 1.2 パラメータ仕様

#### (1) `voice_moreinfo` ビットマスク (`sndprocs.h`)
| 定数名 | 値 | 説明 |
| :--- | :--- | :--- |
| `voice_nothing_special` | `0x0000` | 通常の会話・発話 |
| `voice_audioassistant` | `0x0001` | アクセシビリティ・ナレーション用 |
| `voice_talking_artifact` | `0x0002` | 知性を持つアーティファクト（話す武器） |
| `voice_deity` | `0x0004` | 神の声・天啓 |
| `voice_oracle` | `0x0008` | デルフィのオラクル（神託） |
| `voice_throne` | `0x0010` | 玉座の声 |
| `voice_death` | `0x0020` | 死神（死の宣告・沈黙） |

#### (2) トーン（`tone`）定義
| 定数名 | 説明 | TTS推奨ピッチ・音質 |
| :--- | :--- | :--- |
| `0` / `tone_ordinary` | 通常の声 | ピッチ 1.0, 速度 1.0 |
| `tone_blustering` | 威張り散らした怒声（店主・警備兵） | ピッチ 0.8, 速度 1.1, 強調 |
| `tone_raspy` | しゃがれた声（アンデッド・老僧） | ピッチ 0.7, 速度 0.9 |
| `tone_deep` | 重低音・荘厳な声（神・上位悪魔） | ピッチ 0.5, 速度 0.85, リバーブ |
| `tone_whisper` | 囁き声（幽霊・オラクル） | ピッチ 1.1, 速度 0.9, 低音量 |
| `tone_high_pitched` | 甲高い声（小動物・妖精） | ピッチ 1.4, 速度 1.15 |

---

## 2. 音声再生のハイブリッド設計方針

NetHack のセリフには「プレイヤー名」「金額」「アイテム名」などの動的パラメータが多く含まれるため、**定型セリフ用の固定音声ファイル（`.ogg`）** と **動的セリフ用のテキスト音声合成（TTS）** を組み合わせたハイブリッド設計とする。

1. **固定音声ファイル優先 (`voice_<category>_<detail>.ogg`)**:
   - 神の雷罰、店主の代表的セリフ、警備兵の警告など、象徴的なシーンでは対応する `.ogg` ファイルが存在すれば最優先で再生する。
2. **TTS 音声合成へのフォールバック**:
   - 音声ファイルが存在しない場合や、プレイヤー名・金額を含む動的メッセージは、`flutter_tts` 等の TTS エンジンにテキストと話者パラメータ（性別、トーン、音量）を渡してリアルタイムに読み上げる。
3. **設定による切り替え**:
   - プレイヤーは設定画面で「ボイス再生: OFF / 効果音のみ / TTS読み上げ / 両方」を選択可能とする。

---

## 3. Cコア全呼び出し対照表 (132箇所)

| No | ファイル:行 | 話者・シチュエーション | セリフ内容 (抜粋) | moreinfo | 推奨音声ファイル | TTSパラメータ |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | `apply.c:1441` | 店主: 請求・未払い催促 | それを%sなら、代金は払ってもらうぞ!',                     otmp-... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 002 | `apply.c:1599` | 店主: 請求・未払い催促 | もちろん、それとは別に%sの代金も払ってもらう.',                     ... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 003 | `apply.c:1674` | 店主: 請求・未払い催促 | 燃やした以上、その代金は払ってもらう! | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 004 | `apply.c:1730` | 店主: 請求・未払い催促 | もちろん、ポーション代は別だ. | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 005 | `apply.c:2220` | 店主: 請求・未払い催促 | 缶詰にするなら、代金は払ってもらうぞ! | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 006 | `apply.c:2229` | 店主: 請求・未払い催促 | 缶詰にするなら、代金は払ってもらうぞ! | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 007 | `artifact.c:2324` | アーティファクト（話す武器）の警告 | (セリフなし/状態設定) | `voice_talking_artifact` | `voice_artifact_speak.ogg` | 金属的な反響声 (ピッチ 1.05) |
| 008 | `dig.c:1387` | 金庫警備兵: 威嚇・攻撃宣言 | 待て、破壊者め!  貴様を逮捕する! | `0` | `voice_guard_attack.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 009 | `do_name.c:278` | 店主: 店頭対話 | 私は%s、%sではない。', jp_shkname_for_display(mtmp), buf | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 010 | `dokick.c:339` | 店主: 怒り・罵倒・警告 | 礼は言っておくぞ、このクズ! | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 011 | `dokick.c:348` | 寺院僧侶: 寄付受諾・祝福 | 寄進に感謝する. | `0` | `voice_priest_bless.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 012 | `dokick.c:360` | 金庫警備兵: 誘導命令 | umoney ? '残りも置いて、ついて来い.'                       ... | `0` | `voice_guard_follow.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 013 | `dokick.c:388` | 店主: 店頭対話 | それでは足りんぞ、腰抜け! | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 014 | `dokick.c:394` | 店主: 店頭対話 | それで十分だ.  さっさと失せろ! | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 015 | `dokick.c:397` | 店主: 感謝・購入完了 | 心付け感謝する, %s.',                           flags.... | `0` | `voice_shk_thanks.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 016 | `hack.c:3716` | オラクル: 神託・真理の託宣 | ここはデルファイだ, %s.', svp.plname | `0` | `voice_oracle_prophecy.ogg` | 神秘的な巫女 (ピッチ 1.1, 速度 0.9, 囁き) |
| 017 | `lock.c:552` | 施錠/解錠時の独り言・商人 | 小切手もクレジットも不要だ. 問題ない. | `0` | `voice_lock_speech.ogg` | 一般 (ピッチ 1.0) |
| 018 | `mail.c:339` | 郵便配達員: 配達セリフ | 失礼します。 | `0` | `voice_mail_daemon.ogg` | 早口な配達員 (ピッチ 1.1, 速度 1.25) |
| 019 | `mail.c:373` | 郵便配達員: 配達セリフ | ここは人が多すぎます。出ていきます。 | `0` | `voice_mail_daemon.ogg` | 早口な配達員 (ピッチ 1.1, 速度 1.25) |
| 020 | `mail.c:418` | 郵便配達員: 配達セリフ | %s、%s! %s.', Hello(md), svp.plname, info->displ... | `0` | `voice_mail_daemon.ogg` | 早口な配達員 (ピッチ 1.1, 速度 1.25) |
| 021 | `mail.c:434` | 郵便配達員: 配達セリフ | キャッチ！ | `0` | `voice_mail_daemon.ogg` | 早口な配達員 (ピッチ 1.1, 速度 1.25) |
| 022 | `mcastu.c:434` | クローサス王: 警備兵号令 | 泥棒を滅ぼせ、わが従僕たちよ! | `0` | `voice_croesus_command.ogg` | 富豪の王 (ピッチ 0.75, 傲慢) |
| 023 | `mhitu.c:2089` | モンスター戦闘発言 | %sは%sを気に入り、奪っていった.',                       Who,... | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 024 | `mhitu.c:2120` | モンスター戦闘発言 | %sは%sをあなたに付ければもっと映えると思った.',                    ... | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 025 | `mhitu.c:2194` | モンスター戦闘発言 | あなたは本当に%sですね。ああ…',                           fl... | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 026 | `mhitu.c:2339` | モンスター戦闘発言 | ただです！ | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 027 | `mhitu.c:2377` | モンスター戦闘発言 | (セリフなし/状態設定) | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 028 | `mhitu.c:2387` | モンスター戦闘発言 | あなたの%sを脱いで。%s', str,                         (o... | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 029 | `minion.c:303` | 悪魔の要求・使徒召喚 | 汝の不謹慎な行動に代価を払わせるぞ！ | `0` | `voice_demon_demand.ogg` | 上位悪魔 (ピッチ 0.6, 威圧的) |
| 030 | `minion.c:533` | 悪魔の要求・使徒召喚 | 争いを望むなら、もっとくれてやる！ | `0` | `voice_demon_demand.ogg` | 上位悪魔 (ピッチ 0.6, 威圧的) |
| 031 | `minion.c:566` | 悪魔の要求・使徒召喚 | 汝の争いへの欲望は叶えられん！ | `voice_deity` | `voice_demon_demand.ogg` | 上位悪魔 (ピッチ 0.6, 威圧的) |
| 032 | `minion.c:575` | 悪魔の要求・使徒召喚 | 汝は我に値する者だった！ | `voice_deity` | `voice_demon_demand.ogg` | 上位悪魔 (ピッチ 0.6, 威圧的) |
| 033 | `mkobj.c:799` | 店主: 請求・未払い催促 | お前が%sしたこの%s、払え!',               alteration_verb... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 034 | `mkobj.c:810` | 店主: 請求・未払い催促 | お前が%sしたそれ、払え!',                       alteratio... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 035 | `mon.c:4197` | NPC/対戦相手の移動・発言 | 動くな！お前を逮捕する！ | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 036 | `monmove.c:124` | NPC/対戦相手の移動・発言 | (セリフなし/状態設定) | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 037 | `monmove.c:511` | NPC/対戦相手の移動・発言 | 眩しい光だ！ | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 038 | `monmove.c:1834` | NPC/対戦相手の移動・発言 | 遅刻だ！ | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 039 | `mplayer.c:375` | NPC/対戦相手の移動・発言 | 話す？--　%s', mtmp->data == &mons[gu.urole.mnum]  ... | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 040 | `muse.c:118` | NPC/対戦相手の移動・発言 | おれを助けたな！ | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 041 | `muse.c:1936` | NPC/対戦相手の移動・発言 | はいチーズ！ | `0` | `voice_npc_speech.ogg` | NPC (ピッチ 1.0) |
| 042 | `pickup.c:2447` | 店主: 感謝・購入完了 | 神殿への借りをお返しいただき、ありがとうございます。 | `0` | `voice_shk_thanks.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 043 | `potion.c:2831` | 店主: 店頭対話 | %sは消え去った.', Monnam(mtmp) | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 044 | `pray.c:687` | 神: 激怒・天罰 | 我が怒りからは逃れられぬ、定命の者よ！ | `voice_deity` | `voice_deity_anger.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 045 | `pray.c:692` | 神: 激怒・天罰 | 奴を滅ぼせ、我がしもべたちよ！ | `voice_deity` | `voice_deity_anger.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 046 | `pray.c:744` | 神: 承認・託宣 | 汝、教えを学び直せ！ | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 047 | `pray.c:768` | 神: 承認・託宣 | 汝よ、我を%s！',                   (on_altar() && (a_... | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 048 | `pray.c:843` | 神: 承認・託宣 | 汝に冠を授けよう……エルベレスの御手よ！ | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 049 | `pray.c:854` | 神: 承認・託宣 | 汝は我がバランスの使者となれ！ | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 050 | `pray.c:867` | 神: 承認・託宣 | 汝は我が栄光のために%sよう選ばれた！',                   (((alre... | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 051 | `pray.c:1231` | 神: 祝福・受諾 | 聞け、%s！', is_human(gy.youmonst.data)            ... | `voice_deity` | `voice_deity_bless.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 052 | `pray.c:1235` | 神: 祝福・受諾 |                                '城へ入るには、正しい旋律を奏でよ！ | `voice_deity` | `voice_deity_bless.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 053 | `pray.c:1341` | 神: 祝福・受諾 | 我が名のもとに賢明に使うがよい！ | `voice_deity` | `voice_deity_bless.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 054 | `pray.c:1585` | 神: 祝福・受諾 |                      'その働きへの報いとして、不死の賜物を授けよう！ | `voice_deity` | `voice_deity_bless.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 055 | `pray.c:2786` | 神: 祝福・受諾 | 報いを受けるがよい、異教徒め！ | `voice_deity` | `voice_deity_bless.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 056 | `priest.c:459` | 寺院僧侶: 説教・対話 | (セリフなし/状態設定) | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 057 | `priest.c:593` | 寺院僧侶: 説教・対話 | 立ち去れ! 汝の存在がこの聖地を穢している。 | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 058 | `priest.c:601` | 寺院僧侶: 説教・対話 | 立ち去れ! 汝の存在がこの聖地を穢している。 | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 059 | `priest.c:649` | 寺院僧侶: 説教・対話 | 汝、その行いを悔いることになろうぞ！ | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 060 | `priest.c:656` | 寺院僧侶: 寄付不足・拒絶 | けちんぼめ。 | `0` | `voice_priest_reject.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 061 | `priest.c:660` | 寺院僧侶: 寄付受諾・祝福 | 汝の奉納に感謝いたします。 | `0` | `voice_priest_bless.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 062 | `priest.c:666` | 寺院僧侶: 説教・対話 | 汝は実に信心深い方だ。 | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 063 | `priest.c:694` | 寺院僧侶: 説教・対話 | 汝の献身への報いが授けられた。 | `0` | `voice_priest_talk.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 064 | `priest.c:701` | 寺院僧侶: 寄付受諾・祝福 | 汝の寛大な寄進、深く感謝いたします。 | `0` | `voice_priest_bless.ogg` | 老僧 (ピッチ 0.75, 速度 0.9) |
| 065 | `quest.c:459` | クエストリーダー: 使命の訓示 | ようやく自由だ！ | `0` | `voice_quest_leader.ogg` | 威厳ある導師 (ピッチ 0.8, 速度 0.95) |
| 066 | `read.c:3132` | 巻物読解時の発声 | いいえ、定命の者よ！それは行われない。 | `voice_deity` | `voice_scroll_read.ogg` | 詠唱 (ピッチ 0.95) |
| 067 | `rumors.c:587` | オラクル: 神託・真理の託宣 | fortune_msg | `voice_oracle` | `voice_oracle_prophecy.ogg` | 神秘的な巫女 (ピッチ 1.1, 速度 0.9, 囁き) |
| 068 | `shk.c:611` | 店主: 請求・未払い催促 | not_upset ? '%sさん、出る前に支払いをお願いします。'             ... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 069 | `shk.c:805` | 店主: 店頭対話 | 姿を隠した客は歓迎できねえな! | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 070 | `shk.c:818` | 店主: 怒り・罵倒・警告 | なあ、%sよ。よくも%s%sに戻ってきやがったな！？', svp.plname,       ... | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 071 | `shk.c:830` | 店主: 再訪・監視声掛け | また来たのか、%s？俺の%sでしっかり見張っとくぞ。',                   ... | `0` | `voice_shk_greet.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 072 | `shk.c:898` | 店主: 店頭対話 | not_upset                               ? '%sは外... | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 073 | `shk.c:913` | 店主: ペット/つるはし入店規制 | not_upset ? '%sは外に繋いでから入ってくれますか?'              ... | `0` | `voice_shk_warning.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 074 | `shk.c:950` | 店主: 怒り・罵倒・警告 | この卑怯な%s！そのつるはしを持ったまま出ていけ！',                    ... | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 075 | `shk.c:2040` | 店主: 感謝・購入完了 | %s%sでのお買い上げ、ありがとう%s',                       s_s... | `0` | `voice_shk_thanks.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 076 | `shk.c:2471` | 店主: 請求・未払い催促 | %s、まず%sの分を支払ってから%sを買ってくれ.',                   A... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 077 | `shk.c:3145` | 店主: 店頭対話 | いや、俱だったらそれは手放さないね。 | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 078 | `shk.c:3148` | 店主: 店頭対話 |                                        'それにはあと%... | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 079 | `shk.c:3158` | 店主: 怒り・罵倒・警告 | そんなもの仕入れはしない。ここから出ていけ！ | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 080 | `shk.c:3995` | 店主: 感謝・購入完了 | ありがとうね、クズ野郎。 | `0` | `voice_shk_thanks.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 081 | `shk.c:4032` | 店主: 店頭対話 |        '略奪で減った在庫の補充に協力してくれて助かるよ. | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 082 | `shk.c:4404` | 店主: 怒り・罵倒・警告 | 邪魔だ邪魔！このクズ！ | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 083 | `shk.c:4670` | 店主: 店頭対話 | そのガラクタを壁から出せ！ | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 084 | `shk.c:4931` | 店主: 再訪・監視声掛け | %s、%s! %sを探していましたよ。', Hello(shkp),             ... | `0` | `voice_shk_greet.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 085 | `shk.c:4940` | 店主: 請求・未払い催促 | %s、%s! お支払いをお忘れではないですか?',                      ... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 086 | `shk.c:5067` | 店主: 店頭対話 |                         '足元に気をつけな、%s。床を踏み抜くかもしれ... | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 087 | `shk.c:5169` | 店主: 怒り・罵倒・警告 | よくも俺の%sを%sしやがった！', dugwall ? '店' : '戸',        ... | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 088 | `shk.c:5178` | 店主: 怒り・罵倒・警告 | 誰だ！俺の%sを%sしたのは！', dugwall ? '店' : '戸',         ... | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 089 | `shk.c:5293` | 店主: 怒り・罵倒・警告 | 邪魔だ邪魔！このクズ！ | `0` | `voice_shk_angry.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 090 | `shk.c:5352` | 店主: 請求・未払い催促 | ああ、そうとも！払ってもらうぞ！ | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 091 | `shk.c:5468` | 店主: 店頭対話 | %s!', upstart(buf) | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 092 | `shk.c:5475` | 店主: 請求・未払い催促 | %s、%s値段は%ld %s%s', upstart(buf),               ... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 093 | `shk.c:5565` | 店主: 再訪・監視声掛け | %s、%s! %sを探していましたよ。',                       Hel... | `0` | `voice_shk_greet.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 094 | `shk.c:5572` | 店主: 請求・未払い催促 | %s、%s! お支払いをお忘れではないですか?',                      ... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 095 | `shk.c:5743` | 店主: 店頭対話 | fmt, arg1, arg2, tmp, currency(tmp) | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 096 | `shk.c:6120` | 店主: 請求・未払い催促 | 俺の%sを%s分の代金、%ld%sを払え%s',                   obj_... | `0` | `voice_shk_payment.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 097 | `shk.c:6144` | 店主: 店頭対話 | それを仕掛けたなら、買え！ | `0` | `voice_shk_talk.ogg` | 中年商人 (ピッチ 0.85, 速度 1.05) |
| 098 | `sit.c:119` | 王座: 謁見者召喚 | 汝の謁見者が召喚されたぞ、%s！',                           fl... | `voice_throne` | `voice_throne_summon.ogg` | 王威の反響 (ピッチ 0.6, 速度 0.9) |
| 099 | `sit.c:129` | 王座: 謁見者召喚 | 汝の崇高なる命により、%s...',                       flags.... | `voice_throne` | `voice_throne_summon.ogg` | 王威の反響 (ピッチ 0.6, 速度 0.9) |
| 100 | `sit.c:137` | 王座: 冒涜の呪い |                   'A curse upon thee for sittin... | `voice_throne` | `voice_throne_curse.ogg` | 王威の反響 (ピッチ 0.6, 速度 0.9) |
| 101 | `sounds.c:618` | 幻聴・怪異モンスター会話 | オイラは腹が減った。 | `0` | `voice_monster_talk.ogg` | 怪異・モンスター (ピッチ可変) |
| 102 | `sounds.c:1257` | 幻聴・怪異モンスター会話 | 事実だけを言い給え、%s。', flags.female ? 'お嬢さん' : '旦那 | `0` | `voice_monster_talk.ogg` | 怪異・モンスター (ピッチ可変) |
| 103 | `sounds.c:1353` | 幻聴・怪異モンスター会話 | (セリフなし/状態設定) | `0` | `voice_monster_talk.ogg` | 怪異・モンスター (ピッチ可変) |
| 104 | `sounds.c:1362` | 死神/死の宣告: 沈黙 | あなたは%sなので、話すことができない.',               jp_pmname(... | `voice_death` | `voice_death_silence.ogg` | 無音・低音 |
| 105 | `sounds.c:1365` | 幻聴・怪異モンスター会話 | あなたは%sなので、話すことができない.',               jp_pmname(... | `0` | `voice_monster_talk.ogg` | 怪異・モンスター (ピッチ可変) |
| 106 | `teleport.c:1340` | 神: 承認・託宣 | 汝は早く来たが、我ら汝を認めよう。 | `voice_deity` | `voice_deity_oracle.ogg` | 重低音・神性 (ピッチ 0.5, リバーブ) |
| 107 | `timeout.c:1122` | 状態異常時のモンスター叫び | ギーッ！ | `0` | `voice_monster_shriek.ogg` | 奇声 (ピッチ 1.3) |
| 108 | `uhitm.c:4375` | 看護婦: 治療会話 | 先生、協力してくださらないと先生を治療できません。 | `0` | `voice_nurse_heal.ogg` | 女性 (ピッチ 1.2, 速度 1.0) |
| 109 | `uhitm.c:4534` | モンスター戦闘発言 | ゲップ！ | `0` | `voice_combat_speech.ogg` | 各種モンスター (ピッチ可変) |
| 110 | `vault.c:466` | 金庫警備兵: 詰問・誰何 | ここで何が起きている? | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 111 | `vault.c:478` | 金庫警備兵: 詰問・誰何 | おい! ここにその%sを置いたのは誰だ?',                         ... | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 112 | `vault.c:495` | 金庫警備兵: 詰問・誰何 | 話せるようになったらまた来る! | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 113 | `vault.c:529` | 金庫警備兵: 退去許可・見送り |                           'ああ、もちろんです. お邪魔して申し訳ない. | `0` | `voice_guard_leave.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 114 | `vault.c:541` | 金庫警備兵: 詰問・誰何 |                             '死から戻ってきたのか? ならば片を付... | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 115 | `vault.c:557` | 金庫警備兵: 詰問・誰何 | お前を知らない. | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 116 | `vault.c:566` | 金庫警備兵: 誘導命令 | ついて来い. | `0` | `voice_guard_follow.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 117 | `vault.c:576` | 金庫警備兵: 金貨尋問・没収 | 隠し持った金があるな. | `0` | `voice_guard_gold.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 118 | `vault.c:586` | 金庫警備兵: 金貨尋問・没収 |                      'おそらく、その金はすべてこの宝物庫から盗んだものだ. | `0` | `voice_guard_gold.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 119 | `vault.c:589` | 金庫警備兵: 誘導命令 | その金を置いて、ついて来い. | `0` | `voice_guard_follow.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 120 | `vault.c:748` | 金庫警備兵: 威嚇・攻撃宣言 | どけ、下衆め! | `0` | `voice_guard_attack.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 121 | `vault.c:943` | 金庫警備兵: 金貨尋問・没収 | よくもその金を%sしたな、この悪党め!',                       (eg... | `0` | `voice_guard_gold.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 122 | `vault.c:963` | 金庫警備兵: 詰問・誰何 | 繰り返すが、%s', buf | `0` | `voice_guard_question.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 123 | `vault.c:975` | 金庫警備兵: 威嚇・攻撃宣言 | 警告したはずだ、この下郎! | `0` | `voice_guard_attack.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 124 | `vault.c:1008` | 金庫警備兵: 退去許可・見送り | では、立ち去れ. | `0` | `voice_guard_leave.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 125 | `vault.c:1039` | 金庫警備兵: 金貨尋問・没収 | 金を全部落とせ、この悪党め! | `0` | `voice_guard_gold.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 126 | `vault.c:1049` | 金庫警備兵: 威嚇・攻撃宣言 | ならばよい、無頼漢め! | `0` | `voice_guard_attack.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 127 | `vault.c:1077` | 金庫警備兵: 退去許可・見送り | 先へ進め! | `0` | `voice_guard_leave.ogg` | 厳格な衛兵 (ピッチ 0.8, 速度 1.0) |
| 128 | `wizard.c:776` | イェンダー: 罵倒・嘲笑 | 汝がおれに%sできると思ったのか、愚か者よ。', verb | `0` | `voice_wizard_taunt.ogg` | 邪悪な魔術師 (ピッチ 0.7, 速度 1.1) |
| 129 | `wizard.c:854` | イェンダー: 魔除け要求 | アミュレットを譲れ、%s!',                       ROLL_FROM... | `0` | `voice_wizard_amulet.ogg` | 邪悪な魔術師 (ピッチ 0.7, 速度 1.1) |
| 130 | `wizard.c:858` | イェンダー: 死の呪言・復活予告 | rn2(2) ? 'いま、汝の生命力が失われていくぞ、%s!'                ... | `0` | `voice_wizard_curse.ogg` | 邪悪な魔術師 (ピッチ 0.7, 速度 1.1) |
| 131 | `wizard.c:863` | イェンダー: 死の呪言・復活予告 | rn2(2) ? 'また戻ってくるぞ.' : 'また会おう. | `0` | `voice_wizard_curse.ogg` | 邪悪な魔術師 (ピッチ 0.7, 速度 1.1) |
| 132 | `wizard.c:866` | イェンダー: 罵倒・嘲笑 | %s%s!',                       ROLL_FROM(random_... | `0` | `voice_wizard_taunt.ogg` | 邪悪な魔術師 (ピッチ 0.7, 速度 1.1) |

---

## 4. 代表的な固定音声ファイル名 (`.ogg`) 一覧

132箇所のセリフ群のうち、主要な定型セリフに対応する代表的な固定音声ファイルの一覧は以下の通りである。

| ファイル名 | 種別 | 対象キャラクター / シーン |
| :--- | :--- | :--- |
| `voice_shk_greet.ogg` | 店主 | 店主の挨拶・再訪時（「また来たのか」など） |
| `voice_shk_payment.ogg` | 店主 | 代金請求・未払い警告（「代金は払ってもらうぞ」など） |
| `voice_shk_thanks.ogg` | 店主 | 購入感謝（「お買い上げありがとう」など） |
| `voice_shk_angry.ogg` | 店主 | 店主の激怒・泥棒への罵倒（「このクズ野郎！」など） |
| `voice_guard_question.ogg` | 警備兵 | 金庫番の誰何・詰問（「ここで何が起きている？」など） |
| `voice_guard_follow.ogg` | 警備兵 | 誘導・連行命令（「ついて来い」など） |
| `voice_guard_gold.ogg` | 警備兵 | 金貨没収・詰問（「その金を置いていけ」など） |
| `voice_guard_attack.ogg` | 警備兵 | 威嚇・攻撃宣言（「警告したはずだ！」など） |
| `voice_guard_leave.ogg` | 警備兵 | 退去許可（「では立ち去れ」など） |
| `voice_deity_bless.ogg` | 神 | 祈りの受諾・祝福・恩寵 |
| `voice_deity_anger.ogg` | 神 | 神の激怒・雷罰 |
| `voice_priest_bless.ogg` | 僧侶 | 寺院への寄付受諾・祝福 |
| `voice_priest_reject.ogg` | 僧侶 | 寄付不足・拒絶 |
| `voice_priest_anger.ogg` | 僧侶 | 寺院冒涜への破門・激怒 |
| `voice_wizard_taunt.ogg` | イェンダー | イェンダーの魔法使いの嘲笑・罵倒 |
| `voice_wizard_amulet.ogg` | イェンダー | イェンダーのアミュレット強奪要求 |
| `voice_wizard_curse.ogg` | イェンダー | イェンダーの死の呪言・復活予告 |
| `voice_oracle_prophecy.ogg` | オラクル | デルフィのオラクルの神託・予言 |
| `voice_throne_summon.ogg` | 玉座 | 王座の謁見者召喚 |
| `voice_throne_curse.ogg` | 玉座 | 王座冒涜の呪い |
| `voice_mail_daemon.ogg` | 配達員 | 郵便配達デーモンの配達ボイス |
| `voice_nurse_heal.ogg` | 看護婦 | 看護婦の治療セリフ |
| `voice_demon_demand.ogg` | 悪魔 | 悪魔の貢物要求・嘲笑 |
| `voice_croesus_command.ogg` | クローサス | クローサス王の警備兵召集命令 |
| `voice_quest_leader.ogg` | クエスト | クエストリーダーの使命訓示 |
| `voice_artifact_speak.ogg` | 武器 | 知性を持つアーティファクトの警告 |

---

## 5. Flutter (DartHack) での実装連携仕様

### 5.1 FFI コールバック定義 (`winflutter.c`)

```c
void flutter_sound_verbal(const char *text, int32_t gender, int32_t tone, int32_t vol, int32_t moreinfo) {
    if (g_flutter_cbs.sound_verbal_cb) {
        g_flutter_cbs.sound_verbal_cb(text, gender, tone, vol, moreinfo);
    }
}
```

### 5.2 Dart側 (`SoundManager`) での振り分けフロー

1. `sound_verbal_cb` 受信時:
   - `moreinfo` やテキスト内容から対応する `assets/sound/voice_*.ogg` の存在をチェック。
   - 音声ファイルが存在する場合は `AudioPlayer` で即時再生。
   - 音声ファイルが存在しない場合、かつ設定で TTS が有効な場合は、`flutter_tts` にてテキストを読み上げ。
2. **TTS パラメータ動的マッピング**:
   - `tone` および `moreinfo` に応じて TTS のピッチ（`setPitch`）、速度（`setSpeechRate`）、声色（言語・性別）を動的に設定。
   - 例: `voice_deity`（神）ならピッチ 0.5、`voice_oracle`（オラクル）ならピッチ 1.1、店主の怒りなら速度 1.15。
3. **安全対策**:
   - プレイヤー操作をブロックしない非同期音声合成・再生。
   - テキストウィンドウの更新タイミングとセリフ音声の自然な同期。
