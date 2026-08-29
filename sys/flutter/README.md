<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-29. -->
# DartHack (Flutter 移植版)

NetHack 5.0 (日本語版 / 英語版) を **Flutter / Dart** 上で動作させるための移植プロジェクトです。

- ゲーム本体（C コア）は `c_core/nethack_jp`（日本語版）および `c_core/nethack_en`（英語版）を **Git Subtree** として配置・管理しており、アプリ内で動的に言語を切り替えてプレイ可能です。
- 画面表示・キー入力・メニュー・ダイアログ等は **Flutter UI（Dart）** で行い、C コアとは **Dart FFI** で双方向通信します。
- モバイル（Android / iOS）およびデスクトップ等で一貫した FFI 経路を用いて動作するよう設計されています。

---

## ✨ 主な取り込み機能・特徴

1. **日本語版 / 英語版の二言語切り替え**:
   - `c_core` 配下に配置された 2 系統の C コアソース (`nethack_jp` / `nethack_en`) およびアセットデータ (`assets/nethackdir/` 配下の `_jp` 優先ロード) により、設定画面から日本語・英語を切り替えてプレイ可能です。

2. **カード型 UI & 日英バイリンガル対応 (墓石・ハイスコア)**:
   - ゲームオーバー・クリア時のハイスコア (`TopTenWidget`) や墓石 (`TombstoneWidget`) をカード形式でレイアウト。
   - 英語プロフィール (`Name-Role-Race-Gend-Align`) の自動分解・整形、日本語/英語双方のヘッダー検知、マルチ行エントリーの安全なパースに対応。

3. **FFI メモリ安全 & 高速マルチスレッド通信**:
   - Dart Worker Isolate との通信において 256 面以上の静的リングバッファを使用し、UTF-8 文字列の非同期 Use-After-Free (領域外参照) や文字化けを防止。
   - C 側での CP437 から UTF-8 へのリアルタイム変換および Dart 側の安全なデコード層。

4. **オートセーブ & 状態・視界保護**:
   - オートセーブ (`do_autosave`) 実行時の視界マップ (`viz_array`) 自動全復元および画面同期。
   - セーブデータへの乗馬・巻きつき ID (`m_id`) の確実な保持、セーブプレフィックスの自動クレンジング。

5. **モバイル最適化 UI & スムーズなマップ操作**:
   - **マップ移動**: 巨大キャンバス `InteractiveViewer` 設計により、極端なズーム時やマップ端でも主人公の位置を画面中心よりやや上方 (35% 位置) に確実センタリング。ズーム倍率を保持。
   - **各種ダイアログ**: 個数選択ダイアログ (`AmountSelectorDialog`)、`defaults.nh` (起動オプション) エディタ、全体マップダイアログ、メッセージ履歴ダイアログ、ガイドブックダイアログ。
   - **操作補助**: 仮想方向パッド (D-Pad)、拡張コマンドパネル、ショートカットキーパッド、仮想キーボード。

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
│   ├── models/                  # データモデル (TopTenEntry, TombstoneData 等)
│   ├── screens/                 # 各種画面コンポーネント (start_screen, end_screen 等)
│   ├── widgets/                 # 再利用可能な UI ウィジェット (overlays, TopTenWidget 等)
│   └── utils/                   # ユーティリティ関数
│
├── android/                     # Android プロジェクト設定 (Gradle / CMake)
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

---

## 🔄 c_core 配下（Cコアソース）の管理と取り込み方法

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

### 3. C コア同期後の注意事項

1. **整合性チェックと宣言失効の復元**:
   - スクリプト内にて本家 `extern.h` などの関数宣言ドロップがないか自動検証されます。警告が表示された場合は `git diff` 等で解消してください。
2. **データアセットの同期とバージョンインクリメント**:
   - データファイル（`data`, `rumors`, `oracles`, `quest.lua` 等）に変更が入った場合は、`sys/flutter/assets/nethackdir/` にアセットを同期し、**`sys/flutter/assets/ver` の整数値をインクリメント (+1)** してください。

---

## 🧪 Flutter / Dart コードの検証手順

開発・コード変更時の Dart および Flutter UI 側の構文チェック・静的解析・テスト検証には以下の標準コマンドを使用します（※検証にあたって `build_one.bat` は使用しません）。

### 1. 静的解析 (Lint チェック)

```bash
cd sys/flutter
flutter analyze
```
エラーや警告が出力されないことを確認してください。

### 2. 単体テスト・統合テスト

```bash
cd sys/flutter
flutter test
```
すべてのテストケースがパスすることを確認してください。

※野良ビルド（不正なパッケージ配布）を防止する観点から、アプリパッケージ（`apk`, `aab` 等）のビルドコマンド・ビルド手順については本ドキュメントには記載していません。

---

## ⚖️ ライセンス

本ディレクトリ配下の Dart / Flutter コードおよび C 移植コードは NetHack General Public License に準じます。同梱アセットの権利は各著作者に帰属します。
