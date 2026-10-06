# NetHackJP と DartHack における死因処理の設計差分とアーキテクチャ

本ドキュメントは、NetHackJP 本家リポジトリ（`NetHackJP`）と DartHack（`c_core/nethack_jp`）における死因（Death Reasons / Killer Names）の生成・保持・表示アーキテクチャの設計差分を整理・記録したものです。

---

## 1. 背景と基本設計思想の違い

NetHack における死因（`svk.killer.name` や `losehp()` に渡されるキラー名）の扱いには、歴史的経緯と近代化アプローチにより 2 つの異なる設計方針が存在します。

| 観点 | NetHackJP（従来の実装） | DartHack（現代的・アップストリーム整合） |
| :--- | :--- | :--- |
| **死因内部キーの保持** | 発生箇所の各 C ソース内で直接**日本語文字列**（「落石」「トラバサミ」「酸の薬」「火の巻物」等）をハードコードして記録・保持。 | セーブデータや記録ファイル（`record`）に書き込む内部データは、アップストリーム本来の**英語キー**（`"falling rock"`, `"bear trap"`, `"potion of acid"`, `"scroll of fire"` 等）のまま正規化して保持。 |
| **日本語化のタイミング** | 各イベント発生時点で即時日本語化。 | 墓石（`rip.c`）、スコアボード（`topten.c`）、ゲームオーバー画面（`end.c`）、ダンジョン注釈（`dungeon.c`）等の**表示時に一元的に動的翻訳**。 |
| **アップストリーム追従性** | 内部データが日本語化されているため、アップストリームの新設死因やパッチを取り込む際にコンフリクトや整合性の乖離が発生しやすい。 | 内部キーが英語のまま維持されるため、本家 NetHack との互換性が高く、`topten.c` の辞書テーブルを更新するだけで多言語対応・表示改善が可能。 |
| **バイリンガル対応** | 日本語モード専任（内部データも日本語）。 | 英語モード（`!g_language_is_jp`）と日本語モード（`g_language_is_jp`）の双方向完全切り替えに対応。 |

---

## 2. ファイル別・発生箇所ごとの設計差分一覧

DartHack では、アップストリーム本来の英語キーを出力するように修正されており、NetHackJP では直接日本語が書き込まれている主な箇所は以下の通りです。

### (1) モンスター・攻撃者死因およびゲームオーバー処理

| ファイル | 関数 / 箇所 | NetHackJP の実装（日本語直書き） | DartHack の実装（英語キー正規化） | 表示時翻訳ロジック (`topten.c`) |
| :--- | :--- | :--- | :--- | :--- |
| `src/end.c` | `done_in_by()` | `Strcat(buf, "透明な")`<br>`Strcat(buf, "幻覚でゆがんだ")`<br>`Sprintf(eos(buf), "...（店主）")`<br>`Sprintf(eos(buf), "...（...の姿）")` | `Strcat(buf, "invisible ")`<br>`Strcat(buf, "hallucinogen-distorted ")`<br>`Sprintf(eos(buf), "... the shopkeeper")`<br>`Sprintf(eos(buf), "... in ... form")` | `jp_translate_killer_name_or_monster()` 等でモンスター名や接頭辞・接尾辞を動的パース・日本語化 |
| `src/end.c` | `savelife()` | `gm.multi_reason = "運命にもてあそばれていた"` | `gm.multi_reason = "toyed with by fate"` | `reason_map[]` で「運命に翻弄されていた」に動的翻訳 |
| `src/end.c` | `really_done()` | `Strcat(svk.killer.name, "（魔除けを所持）")`<br>`Strcat(svk.killer.name, "（神の不興を買って）")` | `Strcat(svk.killer.name, " (with the Amulet)")`<br>`Strcat(svk.killer.name, " (in celestial disgrace)")` | `topten.c` のサフィックス処理で「（魔除けを所持）」等に動的翻訳 |
| `src/mon.c` | `corpse_chance()` | `Sprintf(svk.killer.name, "%sの爆発", s_suffix(jp_pmname(...)))` | `Sprintf(svk.killer.name, "%s explosion", s_suffix(pmname(...)))` | `jp_explosion_text_for_display()` で「～の爆発」に動的翻訳 |
| `src/mhitu.c` | `mhitm_ad_drst()` 等 | `Strcpy(svk.killer.name, jp_pmname(...))` | `Strcpy(svk.killer.name, pmname(...))` | 表示時に `name_to_mon()` 経由で日本語モンスター名に解決 |
| `src/uhitm.c` | `mhitm_ad_drst()` 等 | `poisoned(buf, ptmp, jp_pmname(...), ...)` | `poisoned(buf, ptmp, pmname(...), ...)` | 同上 |

### (2) 罠・環境死因 (`src/trap.c` 他)

| ファイル | 状況 | NetHackJP (`losehp`) | DartHack (`losehp`) | 日本語表示名 |
| :--- | :--- | :--- | :--- | :--- |
| `src/trap.c` | 落石トラップ | `"落石"` | `"falling rock"` | 落石 |
| `src/trap.c` | トラバサミ | `"トラバサミ"` | `"bear trap"` | トラバサミ |
| `src/trap.c` | 鉄ゴーレムの錆び崩れ | `"錆び崩れ"` | `"rusting away"` | 錆び崩れて倒された / 錆び崩れたこと |
| `src/trap.c` | 魔法の爆発 | `"魔法の爆発"` | `"magical explosion"` | 魔法の爆発 |
| `src/trap.c` | 反魔法の爆縮 | `"魔法の収縮"` | `"anti-magic implosion"` | 反魔法の爆縮 |
| `src/trap.c` | 地雷 | `"地雷"` | `"land mine"` | 地雷 |
| `src/trap.c` | 危険な突風 | `"危険な突風"` | `"dangerous winds"` | 危険な突風 |
| `src/trap.c` | 熱湯 | `"熱湯"` | `"boiling water"` | 熱湯 |
| `src/trap.c` | 感電 | `"感電"` | `"electric shock"` | 感電 |
| `src/fountain.c` | 毒水飲用 | `"冷やされていないジュースの一口"` | `"unrefrigerated sip of juice"` | 冷やされていないジュースの一口 |
| `src/region.c` | 毒ガス雲 | `"毒ガスの雲"` | `"gas cloud"` | 毒ガス雲 |

### (3) アイテム・魔法死因 (`potion.c`, `read.c`, `spell.c` 他)

| ファイル | 状況 | NetHackJP (`losehp`) | DartHack (`losehp`) | 日本語表示名 |
| :--- | :--- | :--- | :--- | :--- |
| `src/potion.c` | 酸の薬 | `"酸の薬"` | `"potion of acid"` | 酸の薬 |
| `src/potion.c` | 汚染ポーション | `"汚れた薬"` | `"mildly contaminated potion"` | 汚染ポーション |
| `src/potion.c` | 天井衝突 | `"天井への衝突"` | `"colliding with the ceiling"` | 天井への衝突 |
| `src/read.c` | 火の巻物 | `"火炎の巻物"` | `"scroll of fire"` | 火の巻物 |
| `src/read.c` | 土の巻物 | `"大地の巻物"` | `"scroll of earth"` | 大地の巻物 |
| `src/read.c` | 指輪爆発 | `"指輪の爆発"` | `"exploding ring"` | 指輪の爆発 |
| `src/read.c` | 杖爆発 | `"杖の爆発"` | `"exploding wand"` | 杖の爆発 |
| `src/spell.c` | ルーン爆発 | `"ルーンの爆発"` | `"exploding rune"` | ルーンの爆発 |
| `src/ball.c` | 鉄球直撃 | `"鉄球に頭を粉砕された"` | `"crunched in the head by an iron ball"` | 鉄球直撃 |
| `src/apply.c` | 罠脱出事故 | `"トラバサミからの脱出"` | `"jumping out of a bear trap"` | トラバサミからの脱出 |

---

## 3. 同期済みの共通レイヤー (`topten.c` / `explode.c`)

2026年9月現在、以下のコンポーネントは両リポジトリ間で完全同期（または互換実装）されています。

1. **`src/topten.c`**:
   - `jp_killer_reason_table`: 上記の全英語キー（落石、トラバサミ、酸の薬、火の巻物、昇天、不正行為等）を網羅した動的翻訳テーブル。
   - `jp_translate_multi_reason_exact` / `reason_map[]`: 複合死因（気絶、金貨の山、恐怖、運命の翻弄等）の動的翻訳テーブル。
   - `jp_translate_food_or_corpse`: 毒・酸・死体・卵・石像・部位の詳細名詞解決。
   - `jp_translate_killer_text_for_display`: 誤射、水場、石化事故等の多層構文解析。
2. **`src/explode.c`**:
   - `jp_translate_explosion_noun`: モンスター名（`name_to_mon`）、オブジェクト名（`name_to_otyp`）、爆発名の詳細解決。
   - `jp_explosion_text_for_display`: 外部公開関数として `topten.c` から安全に参照可能。
   - `explode()` および `mon_explodes()`: `svk.killer.name` を英語キー（`"caught in a %s"`, `"%s explosion"`）で保持。

---

## 4. 今後の移行・Git Subtree 同期ガイドライン

1. **NetHackJP 側の段階的移行方針**:
   - NetHackJP 本家でも近年 `invent.c`（素手触診石化）などで英語キーへの正常化が進められています。
   - 将来的に NetHackJP 側で罠やアイテム死因の英語キー化を進める際は、上記の一覧表を参照して DartHack の実装（アップストリーム同一のキー名）に合わせることで、DartHack との差分を解消し、Git Subtree 同期時のコンフリクトを最小限に抑えることができます。
2. **Flutter UI 側との二重同期ルールの徹底**:
   - Cコア側で死因キーや翻訳文言を変更・追加した際は、必ず Flutter UI 側（`sys/flutter/lib/models/topten_entry.dart`）の辞書およびテストコード（`sys/flutter/test/models/topten_entry_test.dart`）も同時に同期・更新してください（RULE[AGENTS.md] 参照）。
