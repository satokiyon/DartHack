<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-16. -->
# DartHack (Flutter 移植版)

NetHackJP 5.0.0 を **Flutter / Dart** 上で動作させるための移植プロジェクトです。

- ゲーム本体（C コア）はリポジトリ直下の NetHack C ソース (`src/`) を使用します。
- 画面表示・キー入力・メニュー等は **Flutter UI（Dart）** で行い、C コアとは **Dart FFI** で双方向通信します。
- モバイル（Android / iOS）およびデスクトップ（Windows 等）で同じ FFI 経路を用いて動作するよう設計されています。

---

## 📁 フォルダ構成

```text
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
│   ├── nethack_keyboard.dart    # 仮想キーボード
│   ├── nethack_assets.dart      # アセット・フォント・タイルセット管理
│   ├── nethack_core_loader.dart # C コアライブラリの動的ロード
│   ├── amount_selector_dialog.dart # 個数選択ダイアログ
│   ├── defaults_editor.dart     # NetHack 起動オプション編集
│   ├── settings_page.dart       # 設定画面
│   ├── config/                  # 各種設定・定数
│   ├── l10n/                    # 多言語化リソース (ARB ファイル & 生成コード)
│   │   ├── app_ja.arb           # 日本語リソース
│   │   ├── app_en.arb           # 英語リソース
│   │   └── app_localizations*.dart
│   ├── models/                  # データモデル
│   ├── screens/                 # 各種画面コンポーネント
│   ├── widgets/                 # 再利用可能な UI ウィジェット
│   └── utils/                   # ユーティリティ関数
│
├── android/                     # Android ビルド設定 (Gradle / CMake)
│   ├── build.gradle.kts         # プロジェクト共通設定
│   ├── settings.gradle.kts      # Flutter Plugin Loader / AGP / Kotlin 宣言
│   ├── gradle.properties
│   ├── local.properties         # flutter.sdk / sdk.dir など環境依存設定
│   └── app/
│       ├── build.gradle.kts     # アプリモジュール設定
│       └── src/main/cpp/        # C コアと Flutter を橋渡しするソース (winflutter.c)
│
├── ios/                         # iOS Runner (Xcode プロジェクト)
├── windows/                     # Windows ランナー
├── dummy/                       # FFI 検証用スタブ実装
│   └── libnethack_dummy.c
│
├── assets/                      # アプリに同梱する静的アセット
│   ├── ver                      # アセットバージョン番号（更新時に要インクリメント）
│   ├── nethackdir/              # NetHack データファイル一式 (日本語/英語同梱)
│   ├── tiles/                   # タイルセット (16x16, Geoduck, Nevanda, PixelHack 等)
│   └── fonts/                   # フォントファイル
│
├── pubspec.yaml                 # Flutter パッケージ設定
├── pubspec.lock
├── l10n.yaml                    # 多言語化 (l10n) 設定
├── analysis_options.yaml        # Lint 設定
└── README.md                    # 本ドキュメント
```

### 主要ファイルの説明

| ファイル / フォルダ | 役割 |
|---|---|
| `lib/main.dart` | アプリ全体の状態管理・画面遷移・設定画面。NetHack 起動から C コア起動までを行う。 |
| `lib/nethack_ffi.dart` | C コアが公開する関数（`StartNetHackFlutter`, `RegisterFlutterCallbacks`, `SendKeyToFlutter` 等）の FFI バインディング定義。 |
| `lib/nethack_worker.dart` | Dart Isolate 上で FFI コールバック（ウィンドウ操作・メニュー・YN 等）を受け取り、UI 側 (`SendPort`) に転送する。 |
| `lib/l10n/` | Flutter の i18n 多言語対応リソース。`app_ja.arb`（日本語）および `app_en.arb`（英語）を管理。 |
| `android/app/src/main/cpp/winflutter.c` | NetHack の `window_procs` をハイジャックして、ウィンドウ描画・キー入力等を Dart 側へコールバック通知する C ソース。 |
| `android/app/src/main/cpp/CMakeLists.txt` | NetHack C コアと `winflutter.c` を `libnethack.so` として構成。 |
| `dummy/libnethack_dummy.c` | C コアをビルドせずに FFI 接続を検証するためのスタブ実装。 |

---

## 🏗️ アーキテクチャ概要

```text
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
│  libnethack.so / dll / dylib (C コア + winflutter.c)         │
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

- C コア側は `HijackWindowProcs()` で `and_procs`（Android/POSIX 共通移植テーブル）を Flutter 用テーブルに差し替えています。
- Dart ↔ C 間の双方向通信は「C → Dart コールバック + Dart → C エクスポート関数」の二系統で実現しています。
- ステータス更新は `genl_status_update` をハイジャックして `WIN_STATUS` への `putstr` 2 行送信に統一されています。
- マップタップは `SendPosCmdToFlutter(x, y, mod)` でクリックコマンドをキューに積み、`readchar_core` 経由で入力として処理されます。

---

## 🔄 c_core 配下（Cコアソース）の最新化方法

`c_core/nethack_jp` および `c_core/nethack_en` は DartHack 独自の拡張・修正（UTF-8化、FFI互換処理、自動バイリンガル切替など）を含むため、`git submodule` ではなく **Git Subtree** 方式で管理されています。

### 1. NetHackJP 本家更新の取り込み (`c_core/nethack_jp`)

NetHackJP 本家リポジトリ (`https://github.com/satokiyon/NetHackJP.git`) の最新変更を取り込む場合：

#### PowerShell スクリプトを使用する場合 (推奨)
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_jp.ps1
```
※ 特定のブランチを指定する場合:
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_jp.ps1 -Branch main
```

#### 手動コマンドで同期する場合
```powershell
# 1. リモートの追加 (初回のみ)
git remote add nethack-jp https://github.com/satokiyon/NetHackJP.git

# 2. 最新情報の取得
git fetch nethack-jp

# 3. c_core/nethack_jp にSubtreeマージ
git subtree pull --prefix=c_core/nethack_jp nethack-jp main
```

---

### 2. NetHack 本家更新の取り込み (`c_core/nethack_en`)

NetHack 本家リポジトリ (`https://github.com/NetHack/NetHack.git`) の最新変更を取り込む場合：

#### PowerShell スクリプトを使用する場合 (推奨)
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_en.ps1
```
※ 特定のブランチを指定する場合:
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_en.ps1 -Branch NetHack-5.0
```

#### 手動コマンドで同期する場合
```powershell
# 1. リモートの追加 (初回のみ)
git remote add nethack-en https://github.com/NetHack/NetHack.git

# 2. 最新情報の取得
git fetch nethack-en

# 3. c_core/nethack_en にSubtreeマージ
git subtree pull --prefix=c_core/nethack_en nethack-en NetHack-5.0
```

---

### 3. C コア同期後の注意事項・作業手順

1. **コンフリクトの解消**:
   - `git subtree pull` 実行時にコンフリクトが発生した場合は、手動でマージ解消を行いコミットしてください。
2. **データアセットの再生成とバージョンインクリメント**:
   - 本家のデータファイル（`data`, `rumors`, `oracles`, `quest.lua` 等）に変更が入った場合は、データファイルを再構築し `sys/flutter/assets/nethackdir/` に同期してください。
   - アセットファイルを変更・更新した際は、上書きインストール時にアプリ側でアセット再コピーが実行されるよう、必ず **`sys/flutter/assets/ver` の整数値をインクリメント (+1)** してください。
3. **動作確認**:
   - 変更後はビルド（Windows `sys\windows\vs\build_one.bat` や Android/iOS ビルド）を行い、C コアの動作および FFI 通信に問題がないことを検証してください。

---

## 🌐 多言語化（l10n / i18n）対応

Flutter UI 側の文字列多言語対応および C コア側のバイリンガル対応は以下の仕組みで実装されています。

### UI 側 (Flutter/Dart)
- `flutter_localizations` と ARB (Application Resource Bundle) ファイルを使用しています。
- リソース定義: `lib/l10n/app_ja.arb` (日本語) および `lib/l10n/app_en.arb` (英語)。
- 新しい UI 文字列を追加した場合は `flutter gen-l10n` を実行するか、ビルド時に自動生成される `AppLocalizations` を参照します。

### ゲームコア側 (C / FFI)
- `assets/nethackdir/` 内に英語版 (`data`, `oracles` 等) と日本語版 (`data_jp`, `oracles_jp` 等) の両方を同梱しています。
- C コアの `src/files.c` (`fopen_datafile`) にて、日本語モード設定時に `_jp` 付きファイルを自動優先ロードする処理が実装されています。

---

## 📝 開発メモ & 規約

### ログ・クラッシュ解析

- **C 側のデバッグログ**: `winflutter.c` 内の `debuglog()` で Logcat (`NetHackFlutter` タグ) や標準エラーに出力。
- **ログのクリーンアップ規則**: 調査・デバッグ用に埋め込んだ一時的なログ出力コードは、原因特定および修正完了後に**必ず削除してからコミット**してください。

### 新しい C ↔ Dart コールバックを追加する手順

1. **C 側 (`winflutter.c`)**: `DartXxxCallback` typedef とハンドラ関数を宣言し、`RegisterFlutterCallbacks()` および `flutter_procs` に追加。
2. **Dart FFI 側 (`lib/nethack_ffi.dart`)**: コールバック型定義と Lookup を追加。
3. **Worker Isolate 側 (`lib/nethack_worker.dart`)**: `NativeCallable<XxxCallback>` を作成し UI スレッドへ中継。

---

## 🔗 関連ドキュメント

- [ルート README.md](../../README.md) — プロジェクト概要
- [DEVELOPMENT.md](../../DEVELOPMENT.md) — 開発ガイドライン
- [AGENTS.md](../../AGENTS.md) — AI エージェント / 開発者共通のコーディング・設計規約

---

## ⚖️ ライセンス

本ディレクトリ配下の Dart / Flutter コードおよび C 移植コードは NetHack General Public License に準じます。同梱アセットの権利は各著作者に帰属します。

