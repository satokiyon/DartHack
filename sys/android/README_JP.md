<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-06-27. -->
# NetHackJP Android 版ビルド手順 (Windows PC)

Windows PC 上で NetHackJP の Android 版 APK をビルドするための手順書です。
ビルドには **WSL (Windows Subsystem for Linux)** 上での C ネイティブライブラリのコンパイルと、**Windows 上での Gradle によるAPKパッケージング**の2段階を経ます。

> [!NOTE]
> この手順は `main-android` ブランチを対象としています。

---

## 📋 前提条件

| 項目 | 説明 |
|------|------|
| OS | Windows 10/11（64-bit） |
| WSL | Ubuntu 24.04 以降がインストール済み |
| Git | Windows 側で NetHackJP リポジトリをクローン済み |
| ブランチ | `main-android` にチェックアウト済み |

---

## 🔧 Step 1: WSL (Ubuntu) のセットアップ

### 1.1 WSL のインストール（未インストールの場合）

PowerShell（管理者権限）で実行します：

```powershell
wsl --install -d Ubuntu
```

インストール後、Ubuntu を起動してユーザー名とパスワードを設定してください。

### 1.2 ビルドツールのインストール

WSL (Ubuntu) 内で以下を実行します：

```bash
sudo apt update
sudo apt install -y build-essential bison flex curl unzip
```

---

## 🤖 Step 2: Android NDK のインストール（WSL内）

### 2.1 NDK のダウンロードと展開

WSL (Ubuntu) 内で以下を実行し、Android NDK をインストールします。
NDK のバージョンは `21.4.7075529` を使用します（Makefile.src に合わせてください）。

```bash
# ディレクトリの作成
mkdir -p ~/android_sdk/ndk

# NDK r21e のダウンロード
cd /tmp
curl -O https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip

# 展開
unzip android-ndk-r21e-linux-x86_64.zip

# 所定のディレクトリに配置
mv android-ndk-r21e ~/android_sdk/ndk/21.4.7075529
```

### 2.2 NDK パスの確認

Makefile 内の `NDK` 変数と一致していることを確認します：

```bash
ls ~/android_sdk/ndk/21.4.7075529/toolchains/llvm/prebuilt/linux-x86_64/bin/
# aarch64-linux-android30-clang 等が存在すればOK
```

> [!IMPORTANT]
> `Makefile.src` と `Makefile.top` 内の `NDK` 変数のパスが、実際のインストールパスと一致していることを確認してください。異なる場合はパスを修正するか、`make` 実行時に `NDK=<パス>` で上書き指定してください。

---

## 📱 Step 3: Android SDK のインストール（Windows側）

### 3.1 Android Studio のインストール

[Android Studio](https://developer.android.com/studio) をダウンロードしてインストールします。

### 3.2 SDK コンポーネントのインストール

Android Studio の **SDK Manager** (File → Settings → Android SDK) から以下をインストールします：

| タブ | インストール対象 |
|------|-----------------|
| SDK Platforms | Android 14 (API 34) 以降 |
| SDK Tools | Android SDK Build-Tools 36.0.0 |
| SDK Tools | Android SDK Platform-Tools |

> [!TIP]
> Android Studio を使わず SDK Command-line Tools だけで構築することも可能です。
> その場合は `sdkmanager` を使って上記コンポーネントをインストールしてください。

### 3.3 SDK パスの確認

デフォルトのインストール先は以下です：

```
C:\Users\<ユーザー名>\AppData\Local\Android\Sdk
```

---

## 🏗️ Step 4: Lua ソースの取得

初回ビルドの前に、Lua のソースコードを取得する必要があります。
WSL 内で、リポジトリのルートディレクトリに移動して以下を実行します：

```bash
# NetHackJP リポジトリのルートへ移動
# 例: Windows の C:\Users\satok\NetHackJP は WSL では /mnt/c/Users/satok/NetHackJP
cd /mnt/c/Users/<ユーザー名>/NetHackJP

# Makefile の配置
cd sys/android
sh ./setup.sh
cd ../..

# Lua のソース取得
make fetch-lua
```

---

## 🔨 Step 5: C ネイティブライブラリのビルド（WSL内）

各 CPU アーキテクチャごとに `libnethack.so` をビルドし、APK に同梱するための `libs/` ディレクトリに配置します。

### 5.1 対象アーキテクチャ

| ABI | 対象デバイス |
|-----|------------|
| `arm64-v8a` | 現行の Android スマートフォン・タブレット（Pixel、Galaxy 等） |
| `armeabi-v7a` | 旧世代 ARM 32-bit デバイス |
| `armeabi` | さらに古い ARM デバイス（ほぼ不要） |
| `x86_64` | x86_64 エミュレータ、一部の Chromebook |
| `x86` | x86 エミュレータ（32-bit） |

### 5.2 全アーキテクチャの一括ビルド

WSL 内でリポジトリルートに移動し、各 ABI を順番にビルドします：

```bash
cd /mnt/c/Users/<ユーザー名>/NetHackJP

# クリーンビルドする場合（初回やソース変更後に推奨）
make clean

# 各ABIを順番にビルド＆インストール
for abi in arm64-v8a armeabi-v7a armeabi x86_64 x86; do
    echo "=== Building for $abi ==="
    make clean
    make ABI=$abi install
done
```

> [!NOTE]
> `make install` を実行すると、ビルドされた `libnethack.so` が `sys/android/app/libs/<ABI>/` に配置され、ゲームデータが `sys/android/app/assets/nethackdir/` にコピーされます。

### 5.3 個別のアーキテクチャだけビルドする場合

特定のアーキテクチャだけビルドしたい場合は、`ABI` を指定して実行します：

```bash
# arm64-v8a のみ
make ABI=arm64-v8a install

# x86_64（エミュレータ用）のみ
make ABI=x86_64 install
```

### 5.4 NDK パスを上書き指定する場合

Makefile を編集せずに NDK パスを変更する場合は、コマンドラインで直接指定できます：

```bash
make NDK=/path/to/your/ndk ABI=arm64-v8a install
```

### 5.5 ビルド結果の確認

各 ABI の `.so` ファイルが正しく配置されていることを確認します：

```bash
ls -la sys/android/app/libs/*/
```

以下のような構造になっていれば成功です：

```
sys/android/app/libs/
├── arm64-v8a/
│   └── libnethack.so
├── armeabi/
│   └── libnethack.so
├── armeabi-v7a/
│   └── libnethack.so
├── x86/
│   └── libnethack.so
└── x86_64/
    └── libnethack.so
```

---

## 📦 Step 6: APK のビルド（Windows側・Gradle）

### 6.1 ビルドコマンド

Windows の PowerShell で `sys/android` ディレクトリに移動し、Gradle ビルドを実行します：

```powershell
cd C:\Users\<ユーザー名>\NetHackJP\sys\android

# デバッグ版＋リリース版の両方をビルド
$env:ANDROID_HOME="C:\Users\<ユーザー名>\AppData\Local\Android\Sdk"; .\gradlew.bat assemble

# リリース版のみをビルドする場合
$env:ANDROID_HOME="C:\Users\<ユーザー名>\AppData\Local\Android\Sdk"; .\gradlew.bat assembleRelease
```

> [!IMPORTANT]
> 環境変数 `ANDROID_HOME` を必ず設定してください。
> `settings.gradle` で外部モジュール（ForkFront-Android）を Gradle Source Control 経由でビルドする際、`local.properties` の `sdk.dir` はそのモジュールには引き継がれません。`ANDROID_HOME` 環境変数のみが正しく伝播します。

### 6.2 ビルド成果物の場所

ビルドが成功すると、各 ABI 用の APK が以下のディレクトリに生成されます：

**デバッグ版:**
```
sys/android/app/build/outputs/apk/debug/
├── app-arm64-v8a-debug.apk
├── app-armeabi-debug.apk
├── app-armeabi-v7a-debug.apk
├── app-x86-debug.apk
└── app-x86_64-debug.apk
```

**リリース版:**
```
sys/android/app/build/outputs/apk/release/
├── app-arm64-v8a-release.apk
├── app-armeabi-release.apk
├── app-armeabi-v7a-release.apk
├── app-x86-release.apk
└── app-x86_64-release.apk
```

> [!NOTE]
> リリース版は `build.gradle` の `buildTypes.release` で `signingConfig signingConfigs.debug` が設定されているため、デバッグ署名が使用されます。Google Play ストア等への公開を行う場合は、独自の署名鍵を設定してください。

---

## 📲 Step 7: 実機へのインストール

### 7.1 adb によるインストール

デバイスを USB 接続し、開発者オプションで USB デバッグを有効にした上で、対象デバイスの ABI に合った APK をインストールします：

```powershell
# 例: Pixel 9a (arm64-v8a) にデバッグ版をインストール
adb install sys/android/app/build/outputs/apk/debug/app-arm64-v8a-debug.apk

# リリース版をインストール
adb install sys/android/app/build/outputs/apk/release/app-arm64-v8a-release.apk
```

### 7.2 デバイスの ABI を確認する方法

接続中のデバイスの CPU アーキテクチャは以下で確認できます：

```powershell
adb shell getprop ro.product.cpu.abi
# 例: arm64-v8a
```

---

## ⚠️ トラブルシューティング

### 日本語が文字化けする

`sys/android/app/res/values/config.xml` の `useCP437Decoder` が `true` になっていないか確認してください。NetHackJP では UTF-8 エンコーディングを使用するため、この値を **`false`** に設定する必要があります。

```xml
<bool name="useCP437Decoder">false</bool>
```

### WSL で `unknown identifier` や `non-printable '015'` エラーが出る

Windows 側のファイルの改行コードが CRLF のため、WSL 上のパーサーが `\r` を正しく処理できていない可能性があります。`util/makedefs.c` の `\r` トリミング処理が正しく機能しているか確認してください。

### Gradle ビルドで `SDK location not found` エラーが出る

`ANDROID_HOME` 環境変数が設定されていることを確認してください（Step 6.1 参照）。

### NDK ビルドで `character too large` エラーが出る

全角文字をシングルクォーテーションで囲んで文字定数（`char`）として定義しようとしていないか確認してください。全角文字は文字列リテラル（`""`）を使用する必要があります。

### NDK ビルドで `expected expression` エラーが出る（FALLTHROUGH 関連）

`include/tradstdc.h` の clang 向け `FALLTHROUGH` マクロ定義がセミコロン付きになっているか確認してください：

```c
#define FALLTHROUGH ; __attribute__((fallthrough))
```

### 起動時に `Unknown status field` 警告が出る

`sys/android/defaults.nh` で使用しているステータスフィールド名が、`src/botl.c` 内のフィールド名テーブルに登録されていることを確認してください。

---

## 📝 補足: ビルド構成の概要

```
NetHackJP/
├── sys/android/
│   ├── Makefile.top          # トップレベル Makefile（NDK/ABI 設定を含む）
│   ├── Makefile.src          # ソース Makefile（NDK/ABI 設定を含む）
│   ├── Makefile.dat          # データファイル Makefile
│   ├── Makefile.doc          # ドキュメント Makefile
│   ├── Makefile.utl          # ユーティリティ Makefile
│   ├── setup.sh              # Makefile をリポジトリルートに配置するスクリプト
│   ├── build.gradle          # Gradle ルートビルドファイル
│   ├── settings.gradle       # Gradle 設定（ForkFront-Android 依存を含む）
│   ├── gradlew.bat           # Gradle ラッパー (Windows)
│   ├── gradlew               # Gradle ラッパー (Linux/macOS)
│   ├── defaults.nh           # Android 版のデフォルト設定
│   └── app/
│       ├── build.gradle      # アプリ Gradle ビルドファイル（ABI splits 設定）
│       ├── AndroidManifest.xml
│       ├── res/values/config.xml  # useCP437Decoder 等の設定
│       ├── libs/             # ← make install で .so が配置される
│       └── assets/nethackdir/# ← make install でゲームデータが配置される
└── ...（C ソースファイル群）
```

---

Happy hacking! 🎮
