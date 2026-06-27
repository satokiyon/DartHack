<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-28. -->
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


## アイテムの日本語助数詞（単位）表示方針

1. **GEM_CLASS オブジェクトの助数詞**:
   - 石（`rock`）や宝石（`gem`）など、スリングなどで投射可能な武器属性（`is_ammo` や `is_missile`）を持つ `GEM_CLASS` のアイテムについても、日本語の助数詞（単位）は「本」ではなく「個」と表示されるようにしてください（例: 「10個の石」、「2個の紫の石」）。

## Windows (MSVC) 開発における C コード記述とビルドの制約

1. **strcasecmp の使用禁止と strcmpi / strncmpi の徹底**:
   - Windows (MSVC) ビルド環境では `strcasecmp` や `strncasecmp` は利用できず、リンクエラー（外部シンボル未解決）になります。
   - 大文字小文字を無視した文字列比較を行う場合は、NetHackで定義されているマクロである `strcmpi` / `strncmpi` を必ず使用してください。

2. **AIエージェント用ビルドスクリプトの利用**:
   - Windows環境でコードのビルド確認を行う際は、ルートのCMakeではなく、用意されているエージェント用バッチファイル `sys\windows\vs\build_one.bat` を優先して実行してください。これにより、環境の自動セットアップと `Release|x64` 構成でのビルドが一貫して行われます。

3. **Windows (PowerShell) 環境での Git コミット・コマンド実行の制約**:
   - `run_command` 等でコマンドを連結する際、PowerShell では `&&` を使用すると構文エラーになるため、1行ずつ実行するかセミコロン `;` 等で区切ってください。
   - 日本語のコミットメッセージを指定する場合、PowerShell 上で文字化けが発生するのを防ぐため、メッセージを一時ファイル（UTF-8）を artifacts の scratch ディレクトリ（例：`<appDataDir>\brain\<conversation-id>\scratch\commit_msg.txt`）に書き込み、`git commit -F <ファイルパス>` でコミットを行ってください。コミット完了後、一時ファイルは削除してください。

4. **Android (WSL + Gradle) 環境での自動ビルドスクリプトの利用**:
   - Android環境向けに `libnethack.so` のコンパイルおよびAPKビルドを行う際は、用意されているPowerShellスクリプト `sys/android/build_android.ps1` を実行してください。
   - このスクリプトを実行する際は、PowerShell上で `& .\sys\android\build_android.ps1` の形式で呼び出します。これにより、自動的に WSL (Ubuntu-26.04) 上での C ライブラリのビルドと、Windows 側での `ANDROID_HOME` の設定を伴う `gradlew.bat` による APK パッケージングが一貫して行われます。

5. **Android版における日本語データファイル（データベース・ヘルプ）の配置方針**:
   - Androidポートでは、データファイル群（`data`, `rumors`, `oracles` 等）およびヘルプ・メニューなどのデータファイル群を個別のファイルとして `assets/nethackdir/` にパッケージングし、アプリ起動時に Java 側の `UpdateAssets.java` を経由して端末のストレージ（データディレクトリ）にコピーして読み込みます。
   - `data_jp` や `help_jp` といった `_jp` 接尾辞を持つ日本語ファイルをそのまま別ファイル名としてアセットに配置すると、Java側のアセット取得バグやC側のファイルオープン制限によって、正常にコピーまたはロードされず、英語版データにフォールバックして表示されてしまう問題が発生します。
   - 解決策として、Androidポートでは英語版データファイル自体を完全に排除し、**日本語版データを英語版と同じ標準ファイル名（例：`data`, `help`, `rumors` 等）としてアセット化**します。
   - 具体的には、`sys/android/Makefile.top` 内の `dofiles-nodlb` ターゲット等のアセットコピー処理直後に、日本語ファイル（`data_jp` 等）を元の英語名（`data` 等）へ上書きリネーム（`mv -f`）して格納します。
   - データファイルアセットを変更・追加した際は、上書きインストール時に強制的にアセットコピーがトリガーされるよう、必ず `sys/android/app/assets/ver` 内のバージョン値（整数値）をインクリメントしてください。

6. **デバッグ用一時コード・ログ出力のクリーンアップ**:
   - デバッグや診断の目的で一時的に埋め込んだログ出力処理（例：Cコード内の `__android_log_print` や print文など）や、ログ出力のためだけに一時的に追加したリンクライブラリ指定（例：`-llog` 等）は、**原因の特定および問題の解決が完了した段階で、必ずすべて削除し、元のクリーンな状態に復元した上でコミット**してください。

