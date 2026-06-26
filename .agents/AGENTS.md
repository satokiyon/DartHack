<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-26. -->
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
    $env:ANDROID_HOME="C:\Users\satok\AppData\Local\Android\Sdk"; .\gradlew.bat assembleDebug
    ```
