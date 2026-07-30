<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-30. -->
# DartHack (Flutter 移植版)

NetHackJP 5.0.0 を **Flutter / Dart** 上で動作させるための移植プロジェクトです。

- ゲーム本体（C コア）はリポジトリ直下の NetHack C ソース (`src/`) を使用します。
- 画面表示・キー入力・メニュー等は **Flutter UI（Dart）** で行い、C コアとは **Dart FFI** で双方向通信します。
- モバイル（Android）およびデスクトップ（Windows 等）で同じ FFI 経路を用いて動作するよう設計されています。

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
│   ├── amount_selector_dialog.dart # 個数選択ダイアログ
│   ├── defaults_editor.dart     # NetHack 起動オプション編集
│   └── settings_page.dart       # 設定画面
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
│   ├── ver                      # アセットバージョン番号
│   ├── nethackdir/              # NetHack データファイル一式
│   ├── tiles/                   # タイルセット (16x16, Geoduck, Nevanda, PixelHack 等)
│   └── fonts/                   # フォントファイル
│
├── pubspec.yaml                 # Flutter パッケージ設定
├── pubspec.lock
├── analysis_options.yaml        # Lint 設定
└── README.md                    # 本ドキュメント
```

### 主要ファイルの説明

| ファイル | 役割 |
|---|---|
| `lib/main.dart` | アプリ全体の状態管理・画面遷移・設定画面。NetHack 起動から C コア起動までを行う。 |
| `lib/nethack_ffi.dart` | C コアが公開する関数（`StartNetHackFlutter`, `RegisterFlutterCallbacks`, `SendKeyToFlutter`, `SendPosCmdToFlutter` 等）の FFI バインディングを定義。 |
| `lib/nethack_worker.dart` | Dart Isolate 上で FFI コールバック（ウィンドウ操作・メニュー・YN 等）を受け取り、UI 側 (`SendPort`) に転送する。 |
| `android/app/src/main/cpp/winflutter.c` | NetHack の `window_procs` をハイジャックして、ウィンドウ描画・キー入力等を Dart 側へコールバックで通知する実体。`HijackWindowProcs()` で `and_procs` を上書き。 |
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
│  libnethack.so / dll  (C コア + winflutter.c)                │
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
- ステータス更新は `genl_status_update` をハイジャックして `WIN_STATUS` への `putstr` 2 行送信に統一されています（`AGENTS.md` の方針参照）。
- マップタップは `SendPosCmdToFlutter(x, y, mod)` でクリックコマンドをキューに積み、`readchar_core` 経由で入力として処理されます。

---

## 📝 開発メモ

### ログ・クラッシュ解析

- **C 側のデバッグログ**: `winflutter.c` 冒頭に `debuglog()` マクロを定義し、Android Logcat へ `NetHackFlutter` タグで出力しています。`adb logcat -s NetHackFlutter:V` で確認できます。
- **Dart 側のデバッグログ**: `lib/nethack_assets.dart` 等で `debugPrint()` を使用。
  - 問題特定の目的以外で残したデバッグログは、**原因特定後に必ず削除してからコミット** してください（リポジトリ方針）。
- **クラッシュ時の確認ポイント**:
  - 画面が「セーブ中...」のまま止まる → C コアの `ExitCallback` が Dart 側に届いたか確認。
  - メニューが勝手に閉じる → `request_input` 受信時の自動 `Space(auto)` 送信による誤発動の可能性。

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
3. タイル名（固有名詞）は日本語化せず英語表記を維持してください。

---

## 🔗 関連ドキュメント

- ルート [README.md](../../README.md) — プロジェクト全体の概要・プレイヤー向け手順
- [DEVELOPMENT.md](../../DEVELOPMENT.md) — 開発者向け方針の詳細
- [AGENTS.md](../../AGENTS.md) — AI エージェント / 開発者共通のコーディング・翻訳・命名規約

---

## ⚖️ ライセンス

本ディレクトリ配下の Dart / Flutter コードおよび Windows 用ダミー C ソースは、NetHackJP リポジトリのライセンス（NetHack General Public License）に準じます。タイル画像・フォント等の同梱アセットの権利はそれぞれの著作者に帰属します（詳細はリポジトリ直下の `THIRD_PARTY_NOTICES` を参照）。
