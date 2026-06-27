<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-27. -->
# NetHackJP Android 開発・ビルドに関する追加ルール

NetHackJPをAndroid向けにWSLおよびGradleでビルドする際は、以下の制約とトラブルシューティング知識を遵守してください。

## 1. NDKコンパイルにおける全角文字リテラルの禁止
- **制約**: Android NDK (clang) コンパイラでは、全角文字（例: `'。'`) などのマルチバイト文字をシングルクォーテーションで囲んだ文字定数（`char`）として記述すると `character too large` エラーになります。
- **対策**: 全角の記号や文字を条件付きで出力する場合は、必ず文字列リテラル（例: `"。"`）を使用し、フォーマット指定子を `%c` から `%s` に置き換えてください。

## 2. WSLでのビルド時における改行コード（CRLF）対策
- **現象**: Windows側のリポジトリ（CRLF改行）をそのままWSL (Linux) でビルドする際、データベース構築ユーティリティ `util/makedefs` で行末の `\r` をパースできず `unknown identifier 'MAIL'` や `non-printable '015'` などのエラー・警告が発生します。
- **対策**: `util/makedefs.c` のパース処理（`grep0` および `fgetline` 内）では、改行 `\n` の直前にある `\r` を安全にトリミングする実装（`*tmp == '\r'` の除去）がなされている必要があります。新しくデータファイルやパーサを追加・変更する際は、この `\r` 除去が正しく機能していることを確認してください。

## 3. Gradle Source Control と Android SDK パス (ANDROID_HOME) の伝播
- **現象**: `settings.gradle` 内で Gradle Source Control を用いて外部依存モジュール（例: `ForkFront-Android`）をビルドする場合、メインプロジェクト内の `local.properties` に記述された `sdk.dir` は外部モジュールのビルドコンテキストに引き継がれず、`SDK location not found` エラーが発生します。
- **対策**: Gradleビルド（`gradlew`）を呼び出す際は、必ずビルドプロセス全体の環境変数として `ANDROID_HOME` を直接提供してください。
  - **PowerShellでの実行例**:
    ```powershell
    $env:ANDROID_HOME="C:\Users\satok\AppData\Local\Android\Sdk"; .\gradlew.bat assemble
    ```

## 4. CP437デコーダの無効化とアスキーマップ文字化け対策（日本語文字化け対策）
- **現象**: Android版 NetHack のテキスト出力系は `useCP437Decoder`（`sys/android/app/res/values/config.xml`）が `true` の場合, CP437（単バイト・IBMコードページ）でデコードするため, UTF-8 でエンコードされた日本語テキストがすべて文字化けします。
- **対策**: NetHackJP では `useCP437Decoder` を **必ず `false`** に設定してください。この設定により Java 側のデコーダが UTF-8 モードで動作し, 日本語テキストが正常に表示されます。
- **アスキーマップの対応**: `useCP437Decoder = false` にすると Java 側での CP437 デコーダが無効化され, マップ描画の `ttychar`（CP437コード値）がそのまま `(char)` キャストされて罫線文字などが文字化けします。そのため, C側（`sys/android/winandroid.c`）の `and_print_glyph` 関数で, Java 側に文字データを渡す直前に CP437 から Unicode への変換テーブルを適用して渡してください。これにより, Java 側のコードを改変せずにアスキーマップと日本語表示を両立させることができます。
- **注意**: 上流の NetHack-Android リポジトリではこの値が `true` がデフォルトであるため, `android-base` ブランチの同期時にこの設定が巻き戻らないよう注意してください。

## 5. FALLTHROUGH マクロの clang（NDK）互換性
- **現象**: `include/tradstdc.h` の clang 向け `FALLTHROUGH` マクロが `__attribute__((fallthrough))` のみで定義されていると、特定の文脈（ラベル直後など）で C 言語のパーサーが「expected expression」エラーを出します。Android NDK の clang で発生します。
- **対策**: clang 向けの `FALLTHROUGH` マクロ定義には、先頭にセミコロンを付与して `; __attribute__((fallthrough))` とする必要があります。これにより空文（empty statement）が挿入され、ラベル直後でも有効な式として解析されます。
- **注意**: 上流の NetHack 本家リポジトリからの更新で `tradstdc.h` が変更された際に、この修正が維持されていることを確認してください。

## 6. defaults.nh のオプション名エイリアス整合性
- **現象**: `sys/android/defaults.nh` で日本語版独自のステータス表示オプション（例: `statuslines`）を使用している場合、`src/botl.c` の `status_hilite_menu_fld()` 内のフィールド名テーブルに対応するエイリアスが未登録だと、起動時に `Unknown status field` 警告が出力されます。
- **対策**: `defaults.nh` に新しいステータスフィールド名やエイリアスを追加する場合は、対応する C コード側（`src/botl.c` 等）のフィールド名テーブルにもエイリアスを登録し、パーサーが認識できるようにしてください。

## 7. Android版における日本語データファイル（データベース・ヘルプ）の配置方針
- **現象と制約**:
  Androidポートでは、データファイル群（`data`, `rumors`, `oracles` 等）およびヘルプ・メニューなどのデータファイル群を個別のファイルとして `assets/nethackdir/` にパッケージングし、アプリ起動時に Java 側の `UpdateAssets.java` を経由して端末のストレージ（データディレクトリ）にコピーして読み込みます。
  `data_jp` や `help_jp` といった `_jp` 接尾辞を持つ日本語ファイルをそのまま別ファイル名としてアセットに配置すると、Java側のアセット取得バグやC側のファイルオープン制限によって、正常にコピーまたはロードされず、英語版データにフォールバックして表示されてしまう問題が発生します。
- **リネーム上書きによる解決方針**:
  Androidポートでは英語版データファイル自体を完全に排除し、**日本語版データを英語版と同じ標準ファイル名（例：`data`, `help`, `rumors` 等）としてアセット化**します。
  具体的には、`sys/android/Makefile.top` 内の `dofiles-nodlb` ターゲット等のアセットコピー処理直後に、日本語ファイル（`data_jp` 等）を元の英語名（`data` 等）へ上書きリネーム（`mv -f`）して格納します。
- **アセットバージョン（ver）のインクリメント**:
  データファイルアセットを変更・追加した際は、上書きインストール時に強制的にアセットコピーがトリガーされるよう、必ず `sys/android/app/assets/ver` 内のバージョン値（整数値）をインクリメントしてください。
