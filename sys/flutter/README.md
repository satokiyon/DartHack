<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-11. -->
# DartHack (Flutter 移植版)

NetHackJP 5.0.0 を **Flutter / Dart** 上で動作させるための移植プロジェクトです。

- ゲーム本体（C コア）はリポジトリ直下の NetHack C ソース (`src/`、`win/android/`) をそのまま使用します。
- 画面表示・キー入力・メニュー等は **Flutter UI（Dart）** で行い、C コアとは **Dart FFI** で双方向通信します。
- モバイル（Android）を第一ターゲットとしつつ、Windows ローカルでの UI デバッグも同じ FFI 経路で行えるよう設計されています。

このドキュメントでは、本フォルダ配下の構成と、ビルド手順を説明します。

---

## 📁 フォルダ構成

```
sys/flutter/
├── lib/                         # Dart / Flutter ソース（UI・FFI ブリッジ）
│   ├── main.dart                # アプリ起動・メイン画面・状態管理
│   ├── nethack_ffi.dart         # C コア ↔ Dart の FFI 型定義・シンボル解決
│   ├── nethack_worker.dart      # FFI コールバックを受け取る Worker Isolate
│   ├── nethack_screen.dart      # 画面バッファ（テキスト / マップ / ステータス / メニュー）
│   ├── nethack_map_painter.dart # タイルマップ描画 (CustomPainter)
│   ├── nethack_dpad.dart        # 仮想方向パッド
│   ├── nethack_cmd_panel.dart   # 拡張コマンドパネル
│   ├── nethack_shortcut_pad.dart# ショートカットキーパッド
│   ├── nethack_keyboard.dart    # 仮想キーボード (SoftKeyboard 相当)
│   ├── amount_selector_dialog.dart # 個数選択ダイアログ
│   ├── defaults_editor.dart     # NetHack 起動オプション編集
│   └── settings_page.dart       # 設定画面
│
├── android/                     # Android ビルド設定 (Gradle / CMake)
│   ├── build.gradle.kts         # プロジェクト共通設定
│   ├── settings.gradle.kts      # Flutter Plugin Loader / AGP / Kotlin 宣言
│   ├── gradle.properties
│   ├── local.properties         # flutter.sdk / sdk.dir など環境依存設定
│   ├── gradle/                  # Gradle Wrapper
│   └── app/
│       ├── build.gradle.kts     # アプリモジュール設定
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml
│           │   ├── kotlin/      # MainActivity 等の Kotlin コード
│           │   ├── res/         # アイコン・テーマ等の Android リソース
│           │   └── cpp/         # ★ C コアと Flutter を橋渡しするソース
│           │       ├── CMakeLists.txt   # ネイティブビルド定義
│           │       ├── winflutter.c     # Flutter 用 window port（実体）
│           │       └── libnethack_dummy.c # ダミーコア（Windows 開発用）
│           ├── debug/ / profile/        # ビルドバリアント別 Manifest
│
├── ios/                         # iOS Runner (Xcode プロジェクト、自動生成)
│   ├── Flutter/                 # Flutter フレームワーク組み込み
│   └── Runner/                  # AppDelegate / Info.plist
│
├── windows/                     # Windows ローカル FFI デバッグ用
│   ├── CMakeLists.txt           # ※ libnethack_dummy.c を流用して DLL を生成
│   ├── runner/                  # Win32 エントリポイント (Flutter Windows)
│   └── flutter/                 # Flutter Windows ツール用設定
│
├── web/                         # Web 版（アイコン・index.html のみ。動作未対応）
├── dummy/                       # Windows 用 FFI 検証用スタブの原本
│   └── libnethack_dummy.c       # android/app/src/main/cpp/ と同期
│
├── assets/                      # Flutter 経由でアプリに同梱する静的アセット
│   ├── ver                      # アセットバージョン番号（更新時にインクリメント）
│   ├── nethackdir/              # NetHack データ一式 (152 ファイル)
│   │                            #   data, rumors, oracles, help, opthelp, cmdhelp,
│   │                            #   keyhelp, engrive, epitaph, history, license,
│   │                            #   wizhelp, tribute, symbols, bogusmon, hh,
│   │                            #   opthelp, optmenu, defaults.nh, options 等
│   │                            #   ※日本語版データを標準ファイル名で配置
│   │                            #   ※タウンの *.lua (medusa, kox, soko1-1 等) も同梱
│   ├── tiles/                   # タイルセット
│   │   ├── default_16x16.png    #   16x16 ASCII
│   │   ├── geoduck_15x25.png    #   15x25 Geoduck
│   │   ├── nevanda_32x32.png    #   32x32 Nevanda
│   │   ├── pixelhack_32x32.png  #   32x32 PixelHack
│   │   └── overlays.png         #   ステータスアイコン等のオーバーレイ
│   └── fonts/
│       └── monobold.ttf         # ステータス行用等幅フォント
│
├── test/                        # Flutter 自動テスト (デフォルト)
│
├── pubspec.yaml                 # Flutter パッケージ設定（依存・assets 宣言）
├── pubspec.lock
├── analysis_options.yaml        # Lint 設定 (flutter_lints)
├── .gitignore / .metadata /
├── darthack.iml /
├── README.md                    # 本ドキュメント
```

### 主要ファイルの説明

| ファイル | 役割 |
|---|---|
| `lib/main.dart` | アプリ全体の状態管理・画面遷移・設定画面。NetHack 起動から C コア起動までを行う。 |
| `lib/nethack_ffi.dart` | C コアが公開する関数（`StartNetHackFlutter`, `RegisterFlutterCallbacks`, `SendKeyToFlutter`, `SendPosCmdToFlutter` 等）の FFI バインディングを定義。 |
| `lib/nethack_worker.dart` | Dart Isolate 上で FFI コールバック（ウィンドウ操作・メニュー・YN 等）を受け取り、UI 側 (`SendPort`) に転送する。 |
| `android/app/src/main/cpp/winflutter.c` | NetHack の `window_procs` をハイジャックして、ウィンドウ描画・キー入力等を Dart 側へコールバックで通知する実体。`HijackWindowProcs()` で `and_procs` を上書き。 |
| `android/app/src/main/cpp/CMakeLists.txt` | NetHack C コア（`src/*.c`, `win/android/*.c`, `lib/lua-5.4.8/src/*.c`）と `winflutter.c` を `libnethack.so` としてビルド。 |
| `dummy/libnethack_dummy.c` | C コアをビルドせずに FFI 接続を検証するためのスタブ実装。Windows ローカル開発時に `nethack_dummy.dll` として読み込まれる。 |
| `assets/ver` | Flutter 側 (`lib/nethack_assets.dart`) が参照するアセットバージョン番号。`assets/nethackdir/` 配下を更新したら必ずインクリメントする。 |

---

## 🏗️ アーキテクチャ概要

```
┌──────────────────────────────────────────────────────────────┐
│  Dart / Flutter (UI スレッド)                                │
│                                                              │
│  MyHomePage ─┐                                               │
│              ├─→ NetHackScreen (画面バッファ)                  │
│              ├─→ NetHackMapPainter (タイル描画)                │
│              ├─→ DPad / CmdPanel / SoftKeyboard              │
│              └─→ NetHackFfi  (Dart FFI)                      │
│                       │                                      │
└───────────────────────┼──────────────────────────────────────┘
                        │  FFI call
┌───────────────────────▼──────────────────────────────────────┐
│  libnethack.so  (C コア + winflutter.c)                      │
│                                                              │
│  NetHackMain() ─→ 既存の NetHack C ロジック                  │
│       │                                                      │
│       └─→ window_procs (ハイジャック済み)                    │
│              ├─ flutter_create_nhwindow()                    │
│              ├─ flutter_putstr()      ─┐                     │
│              ├─ flutter_print_glyph()  │ Dart 側へ           │
│              ├─ flutter_start_menu()   │ コールバック        │
│              ├─ flutter_yn_function()  │ 通知               │
│              ├─ flutter_getline()      │                     │
│              ├─ flutter_cliparound()   ─┘                    │
│              └─ flutter_exit_nhwindows()                     │
│                                                              │
│  ↑ Dart から呼ばれるエクスポート関数                          │
│    StartNetHackFlutter(path, username)                       │
│    RegisterFlutterCallbacks(...)                              │
│    SendKeyToFlutter / SendKeysToFlutter                      │
│    SendPosCmdToFlutter(x, y, mod)                           │
│    SendMenuSelection / SendMenuSelectionsToC                 │
│    SendYnResultToC / SendGetLineResultToC / SendAskName...   │
│    GetFlutterInputRequestId / GetExtCmdsFlutter              │
└──────────────────────────────────────────────────────────────┘
        ↓ 別スレッドで動作 (pthread)
┌──────────────────────────────────────────────────────────────┐
│  Worker Isolate (nethack_worker.dart)                        │
│                                                              │
│  C からのコールバックを SendPort で UI スレッドに転送         │
└──────────────────────────────────────────────────────────────┘
```

- C コア側は `HijackWindowProcs()` で `and_procs`（Android ネイティブ実装）を丸ごと Flutter 用テーブルに差し替えています。
- Dart ↔ C 間の双方向通信は「C → Dart コールバック + Dart → C エクスポート関数」の二系統で実現しています。
- ステータス更新は `genl_status_update` をハイジャックして `WIN_STATUS` への `putstr` 2 行送信に統一されています（`AGENTS.md` の方針 1 を参照）。
- マップタップは `SendPosCmdToFlutter(x, y, mod)` でクリックコマンドをキューに積み、`readchar_core` 経由で `#herecmdmenu` 相当のクリック系コマンドに変換します（`AGENTS.md` の方針 5）。

---

## 🛠️ ビルド方法

### 前提条件

| 種別 | 必須環境 |
|---|---|
| OS | Windows 10/11 (推奨) |
| Flutter SDK | 3.12 以降（`dart:ffi`, `flutter: 3.x`） |
| Android SDK | API 21 以上（Flutter デフォルトで OK） |
| Android NDK | Flutter が指定するバージョン（`flutter.ndkVersion`） |
| WSL | Ubuntu-26.04（C コアを Linux 用にクロスコンパイルするため） |
| JDK | 17（`JavaVersion.VERSION_17`） |
| Kotlin | 2.3.20（`android/settings.gradle.kts`） |
| Android Gradle Plugin | 9.0.1 |

`android/local.properties` に `flutter.sdk` と `sdk.dir` のパスが記載されていることを確認してください（環境に合わせて書き換えてください）。

```properties
sdk.dir=C\:\\Users\\<user>\\AppData\\Local\\Android\\Sdk
flutter.sdk=C\:\\Users\\<user>\\flutter
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
```

### A. Android 向け APK のビルド

リポジトリ直下に用意されている **統合ビルドスクリプト** を使うと、C コアの WSL クロスコンパイルから Gradle APK パッケージングまでを 1 コマンドで実行できます。

```powershell
# リポジトリ直下 (Windows PowerShell)
& .\sys\android\build_android.ps1
```

このスクリプトは内部で次のことを行います。

1. **WSL (Ubuntu-26.04) で C コアをクロスコンパイル**
   - `sys/android/setup.sh` の実行
   - `make fetch-lua` で Lua 5.4.8 ソースを取得
   - `make clean && make ABI=<abi> install` で `libnethack.so` を生成
   - 既定では `arm64-v8a` のみ（必要に応じて `$abilist` を編集）
2. **Windows 側で Gradle パッケージング**
   - `ANDROID_HOME` を設定
   - `sys/android/gradlew.bat assembleDebug` を実行
3. 生成物: `sys/android/app/build/outputs/apk/debug/app-debug.apk`

> **NOTE:** Android ポートでは英語版データファイル (`data`, `help`, ... 等) は **完全に除去** され、日本語版データが `data` / `help` 等の標準ファイル名でアセット化されています。データ更新時は `sys/android/Makefile.top` の `dofiles-nodlb` ターゲット配下のアセットコピー処理で `_jp` ファイルを英語名へリネーム（`mv -f`）していることを確認してください。
>
> データファイルを変更した際は **必ず `sys/android/app/assets/ver` のバージョン番号をインクリメント** してください（Flutter 側 `lib/nethack_assets.dart` のアセット展開判定基準となる）。

#### 個別にビルドする場合

**Step 1: C コアのクロスコンパイル（WSL）**

```bash
# WSL 上で
cd /path/to/NetHackJP-Android
cd sys/android
sh ./setup.sh
cd ../..
make fetch-lua
make clean
make ABI=arm64-v8a install
```

成果物:
- `sys/android/app/src/main/jniLibs/arm64-v8a/libnethack.so`

**Step 2: Flutter アプリ（APK）のパッケージング**

```powershell
# Windows PowerShell
$env:ANDROID_HOME = "C:\Users\<user>\AppData\Local\Android\Sdk"
cd sys\android
.\gradlew.bat assembleDebug
```

成果物:
- `sys/android/app/build/outputs/apk/debug/app-debug.apk`

### B. Windows ローカルでの UI デバッグ（ダミーコア）

フル C コアをビルドせず、**Flutter UI のみをローカルで高速にデバッグ** したい場合は、Flutter の Windows ターゲットを使います。

```powershell
cd sys\flutter
flutter pub get
flutter run -d windows
```

このとき `lib/nethack_ffi.dart` は以下の順でネイティブライブラリを探索します。

1. `libnethack.so` (Android 実機 / Linux)
2. 見つからなければ `nethack_dummy.dll` (Windows デバッグ用)

`nethack_dummy.dll` は `windows/CMakeLists.txt` が `dummy/libnethack_dummy.c` をビルドして生成し、Flutter 実行ファイルと同じフォルダへ自動コピーされます。

- 起動すると「You see a dark room. What do you want to do?」等の仮想シナリオが流れます。
- メニュー・YN 等の UI フローの動作確認ができます。
- 実際の NetHack の挙動を確認したい場合は A. の手順で `libnethack.so` を用意し、Android 端末 / エミュレータで `flutter run -d android` を使ってください。

### C. iOS / Web / macOS

`ios/` `web/` フォルダは Flutter ツールが自動生成した雛形です。現時点では本プロジェクトは **Android および Windows (デバッグ用) を主ターゲット** としており、iOS / Web / macOS の動作は未検証です（Issue 等で要相談）。

---

## 🧪 テスト

```powershell
cd sys\flutter
flutter test
```

`test/widget_test.dart` のみが含まれているデフォルトの Flutter ウィジェットテストが実行されます。

---

## 📝 開発メモ

### ログ・クラッシュ解析

- **C 側のデバッグログ**: `winflutter.c` 冒頭に `debuglog()` マクロを定義し、Android Logcat へ `NetHackFlutter` タグで出力しています。`adb logcat -s NetHackFlutter:V` で確認できます。
- **Dart 側のデバッグログ**: `lib/nethack_assets.dart` 等で `debugPrint()` を使用（`flutter run` コンソール / logcat に出力）。
  - 問題特定の目的以外で残したデバッグログは、**原因特定後に必ず削除してからコミット** してください（リポジトリ方針）。
- **クラッシュ時の確認ポイント**:
  - 画面が「セーブ中...」のまま止まる → C コアの `ExitCallback` が Dart 側に届いたか確認。
  - メニューが勝手に閉じる → `request_input` 受信時の自動 `Space(auto)` 送信による誤発動の可能性（`AGENTS.md` の方針 6）。

### 新しい C ↔ Dart コールバックを追加する手順

1. **C 側** (`winflutter.c`)
   - `DartXxxCallback` 型の typedef を宣言し、グローバル変数を追加。
   - 実際の処理関数を実装（例: `flutter_xxx()`）。
   - `HijackWindowProcs()` の `flutter_procs` テーブルにエントリを追加。
   - 登録用 `RegisterFlutterCallbacks()` の引数を追加。

2. **Dart 側** (`lib/nethack_ffi.dart`)
   - コールバック typedef と `RegisterCallbacksFunc` の引数を追加。
   - `NetHackFfi` クラスで `lookup<...>('Xxx')` 経由で関数シンボルを取得。

3. **Worker Isolate** (`lib/nethack_worker.dart`)
   - `NativeCallable<XxxCallback>` を作成。
   - `registerCallbacks` 呼び出しに新しい callable を追加。

### タイルセットを増やす

1. PNG ファイルを `assets/tiles/<name>_<w>x<h>.png` として配置。
2. `lib/main.dart` のタイルセット一覧と `lib/nethack_screen.dart` の読み込みロジックを追加。
3. タイル名（固有名詞）は日本語化せず英語表記を維持してください（`AGENTS.md` の方針 9）。

### データファイル更新時の注意

`assets/nethackdir/` 配下のファイルを更新した場合:

1. **必ず** `assets/ver` の整数値をインクリメントする。
2. APK に同梱されるアセットは Flutter の `pubspec.yaml` 経由で参照されるため、APK 再ビルド時は `flutter clean && flutter pub get` を推奨。
3. 既存端末ではインストール時に `assets/ver` の差分を検出して自動で再展開されます（`lib/nethack_assets.dart` の `initialize()` を参照）。

---

## 🔗 関連ドキュメント

- ルート [README.md](../../../README.md) — プロジェクト全体の概要・プレイヤー向け手順
- [DEVELOPMENT.md](../../../DEVELOPMENT.md) — 開発者向けビルド・翻訳方針の詳細
- [AGENTS.md](../../../AGENTS.md) — AI エージェント / 開発者共通のコーディング・翻訳・命名規約
- 既存の Android 移植: [`sys/android/`](../../android/) — `libnethack.so` ビルド手順

---

## ⚖️ ライセンス

本ディレクトリ配下の Dart / Flutter コードおよび Windows 用ダミー C ソースは、NetHackJP リポジトリのライセンス（NetHack General Public License）に準じます。タイル画像・フォント等の同梱アセットの権利はそれぞれの著作者に帰属します（詳細はリポジトリ直下の `THIRD_PARTY_NOTICES` を参照）。
