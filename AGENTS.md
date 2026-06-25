<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-25. -->
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

## 神の名前の日本語表示方針

神の名前（`align_gname()` や `u_gname()` が返す文字列）をプレイヤーへの表示メッセージやログ（`livelog`など）に含める際は、英語のまま表示されてしまうのを防ぐため、必ず日本語の表示用変換関数を経由させてください。

1. **アライメントに対応する神の名の取得**:
   - アライメント値（`aligntyp`）から日本語の神の名前を取得して表示する場合は、`jp_align_gname_for_display(alignment)` を使用してください。

2. **英語の神の名の文字列からの翻訳**:
   - 既に英語の神の名前の文字列（`gnam`）がある場合は、`jp_gname_for_display(gnam)` を通して日本語名（カタカナ）に変換してから表示してください。

3. **例外（内部ロジックでの英語の維持）**:
   - 死因 (`svk.killer.name`) など、セーブデータ互換性やスコア判定で内部的に使われる識別キーとして設定する場合は、表示時以外は英語のままとします。

## イベント履歴（livelog）および画面メッセージの日本語表示方針

ゲーム内イベント履歴（livelog / chronicle）や画面に表示されるメッセージを日本語化・翻訳する際は、以下のルールを徹底してください。

1. **固有名詞の翻訳統一**:
   - `Sokoban` の翻訳は必ず「倉庫番」を使用してください。「ソコバン」などのカタカナ表記は避けてください。

2. **英語特有の表現・関数の排除**:
   - 日本語化に伴い不要となる英語の不定冠詞付与関数 `an()` や、代名詞取得関数 `uhis()`, `uhim()` は削除し、日本語の助詞や「あなた」などに適宜置き換えてください。
   - 店主などのモンスターの代名詞を返す関数 `noit_mhe()`, `noit_mhim()`, `noit_mhis()` なども同様にメッセージ内で使用せず、日本語の「自分」「相手」などに置き換えるか、プレースホルダー自体を削除して文章を整理してください。

3. **日本語の語順への再構築**:
   - 英語の語順（例: `entered <Level>`）をそのまま直訳せず、日本語として自然な語順（例: `<Level>に入った`）にフォーマット文字列と引数の順序を再構築してください。

4. **動的な日本語名の解決**:
   - 職業名、肩書、種族名などのプレイヤー情報は、イベント履歴（livelog）や画面に表示される通常メッセージ（`pline` 等での出力）において、英語の文字列（`gu.urole.name.m` など）をそのまま出力して英語交じりになるのを防ぐため、必ず以下の表示用日本語化関数を経由させてください。
     - 職業名: `jp_role_name_for_display(flags.initrole, gender)`
     - 肩書: `jp_rank_of_for_display(u.ulevel, Role_switch, gender)`
     - 種族名: `jp_race_noun_for_display(Race_switch)`


## Windows (MSVC) 開発における C コード記述とビルドの制約

1. **strcasecmp の使用禁止と strcmpi / strncmpi の徹底**:
   - Windows (MSVC) ビルド環境では `strcasecmp` や `strncasecmp` は利用できず、リンクエラー（外部シンボル未解決）になります。
   - 大文字小文字を無視した文字列比較を行う場合は、NetHackで定義されているマクロである `strcmpi` / `strncmpi` を必ず使用してください。

2. **AIエージェント用ビルドスクリプトの利用**:
   - Windows環境でコードのビルド確認を行う際は、ルートのCMakeではなく、用意されているエージェント用バッチファイル `sys\windows\vs\build_one.bat` を優先して実行してください。これにより、環境の自動セットアップと `Release|x64` 構成でのビルドが一貫して行われます。

