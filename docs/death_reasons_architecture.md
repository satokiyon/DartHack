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

## 3. 同期済みの共通レイヤー (`topten.c` / `explode.c` / 英語キー完全移行)

2026年11月現在、NetHackJP 本家側も上記 §2 の未移行箇所を含めて**全死因・キラー・無防備理由 (`gm.multi_reason`)・モンスタートークンの英語キー正規化と表示時動的翻訳アーキテクチャへ完全移行・同期**されました。

1. **英語キー生成・正規化層 (`src/*.c`)**:
   - `src/do_name.c` / `src/objnam.c` / `src/priest.c`: プレイヤー向け画面表示 (`pline` 等) は日本語のまま維持しつつ、記録・死因専用の英語生成ヘルパー (`en_x_monnam`, `en_m_monnam`, `en_obj_pmname`, `en_xname`, `en_ansimpleoname`, `en_bare_artifactname`, `en_priestname`) および `en_tin_details` (`src/eat.c`) を導入し、`svk.killer.name` や `gm.multi_reason` への日本語文字列混入を根絶。
   - `src/zap.c`: `en_flash_types[]` を導入し、光線・魔法・ブレス由来の自爆および敵攻撃死因の内部キーを英語化（`potion.c`, `read.c`, `spell.c`, `trap.c`, `fountain.c`, `music.c`, `pickup.c`, `steed.c`, `pray.c`, `region.c`, `muse.c`, `detect.c`, `monmove.c`, `mhitu.c`, `mon.c`, `uhitm.c`, `mthrowu.c`, `end.c` も同様に統一）。
   - `src/mon_jp.c`: `NAMS()` による性別対応モンスター（`dwarf lord`/`dwarf lady`, `gnome lord`/`gnome lady`, `priest`/`priestess`, `high priest`/`high priestess` 等 全15組）の `{ male, female, neutral }` 全スロットを定義。
2. **`src/topten.c` / `src/explode.c` / `src/rip.c` (Cコア表示時翻訳層)**:
   - `name_to_mon(..., &gend)` で判別した性別インデックスを `jp_pmname_from_idx(mndx, (gend >= 0) ? gend : 0)` へ伝播し、英語キーから日本語の性別別名称へ正確に復元。
   - `jp_killer_reason_table`: 罠・水場・薬・巻物・乗馬滑落・鉄球等を含む全英語キーを網羅。
   - `jp_flash_text_to_jp` / `jp_translate_self_inflicted`: `zap`/`cast`/`exhale`/`play`/`imagine`/`inflict` 各構文を自爆・他者攻撃の双方で動的翻訳。
   - `jp_translate_killer_name_or_monster`: `high priestess of <神>` / `priestess of <神>` / `exploding <X>` / `handling <X>` / `touching <X>` を正確に処理。
3. **Flutter UI 層 (`topten_entry.dart` / `xlog_entry.dart`)**:
   - `TopTenEntry` / `translateDeathReason` / `translateMultiReasonText` の辞書・パターンを C コアと二重同期（全モンスター・性別 `NAMS()` ペア・全アイテム・アーティファクト・罠・光線系死因・大文字小文字フォールバック）。
   - `XLogEntry.translateWhileReason` は独自辞書を廃止し、`translateMultiReasonText` へ一元委譲。

---

## 4. 今後の運用・Git Subtree 同期ガイドライン

1. **内部キー英語原則の維持**:
   - 新しい死因・罠・イベントを追加する際は、画面表示用メッセージ (`pline`, `You`, `poisoned()` 第1引数 等) のみを日本語にし、`losehp()`, `poisoned()` 第3引数, `poison_strdmg()`, `instapetrify()`, `svk.killer.name`, `gm.multi_reason` に渡す内部識別キーは必ず上流 `NetHack` 同一の英語文字列を維持してください。
2. **Flutter UI 側との二重同期ルールの徹底**:
   - Cコア側で死因キーや翻訳文言を変更・追加した際は、必ず Flutter UI 側（`sys/flutter/lib/models/topten_entry.dart`）の辞書およびテストコード（`sys/flutter/test/models/topten_entry_test.dart`, `sys/flutter/test/xlog_sync_and_detail_test.dart`）も同時に同期・更新してください（RULE[AGENTS.md] 参照）。
