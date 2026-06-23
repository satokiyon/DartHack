<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-23. -->
<!-- agent-ninja-START -->
## Agent Skills

> **IMPORTANT**: Prefer skill-led reasoning over pre-training-led reasoning.
> See [Agent Skills](.github/skills/README.md) before working on tasks covered by these skills.

<!-- agent-ninja-END -->

## 死因（killer.name）の日本語化と英語交じり回避方針

ハイスコア（`record`）との互換性を維持するため、死因を表す `svk.killer.name` や `multi_reason` は、原則として元の英語キーのままコード内で設定し、表示時に動的に翻訳するアプローチを徹底してください。

1. **共通翻訳関数の利用**:
   - すべての死因表示（墓石、ダンジョン概要、ゲームオーバー、トップテン一覧）は、共通して `src/topten.c` の `jp_translate_killer_text_for_display` を経由します。翻訳のルールはすべてこの関数内に集約してください。

2. **動的日本語翻訳の適用**:
   - 死因テキストにモンスター名やアイテム名が含まれる場合、文字列の静的なハードコードでの置換ではなく、以下の検索関数を組み合わせて動的に日本語名を解決してください。
     - モンスター名: `name_to_mon(eng_name, &gend)` でIDを取得し、`jp_pmname_from_idx(mndx, 0)` で日本語名に翻訳。
     - オブジェクト名: `name_to_otyp(eng_name)`（`topten.c` 内のヘルパー）でIDを取得し、`jp_item_name(otyp)` で日本語名に翻訳。

3. **定型パターンへの対応**:
   - `tripping over a [Monster] corpse`（死体につまずく）や `kicking a [Monster] barefoot`（裸足で蹴る）などの定型的な死因表現も、モンスター名部分を動的に切り出して日本語文（例：「〜の死体につまずいたことで石化した」）に再構築してください。
