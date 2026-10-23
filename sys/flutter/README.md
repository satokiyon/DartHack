<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-10-22. -->
# DartHack : 開発者向けドキュメント

NetHack 5.0 (日本語版 / 英語版) に **Flutter / Dart** でUIを実装するためのプロジェクトです。

- ゲーム本体（C コア）は `c_core/nethack_jp`（日本語版）および `c_core/nethack_en`（英語版）を **Git Subtree** として配置・管理しており、アプリ内で動的に言語を切り替えてプレイ可能です。
- 画面表示・キー入力・メニュー・ダイアログ等は **Flutter UI（Dart）** で行い、C コアとは **Dart FFI** で双方向通信します。
- モバイル（Android）およびデスクトップ（Windows）で一貫した FFI 経路を用いて動作するよう設計されています。

---

## ✨ 主な取り込み機能・特徴

1. **日本語版 / 英語版の二言語切り替え**:
   - `c_core` 配下の 2 系統の C コアソース (`nethack_jp` / `nethack_en`) およびアセットデータ (`assets/nethackdir/` 配下の `jp/`, `en/`, `common/`) により、設定画面から日本語・英語をシームレスに切り替えてプレイ可能です。

2. **マルチプラットフォーム対応 (Android / Windows)**:
   - スマートフォン（Android）でのタッチ・ジェスチャー操作に加え、PC（Windows デスクトップ）環境にもネイティブ対応。UCRT 互換・堅牢なセーブ終了処理を備え、環境を問わず安定動作します。

3. **多彩なタイルセット選択 & 透過2層描画**:
   - 伝統的な 16x16 タイルに加え、Nevanda (32x32)、PixelHack (32x32)、Geoduck (15x25) など複数のタイルセットを動的に切り替え可能。
   - 透過タイルセット使用時は C コアの `back_to_glyph` と連動し、背景地形とキャラクター/アイテムを重ね合わせた自然な2層描画を実現しています。

4. **ゲーム内スポイラー & ガイド機能**:
   - ゲームプレイ中にいつでもモンスターやアイテム、ルール等の詳細な知識を閲覧できるスポイラーダイアログ (`SpoilerDialog`) およびガイドブックビューアを搭載。閲覧専用画面でのタイル表示やキー操作にも対応しています。原本（`companion.md` / `companion.jp.md`）の更新・同期手順については [`doc/spoiler_update_guide.md`](doc/spoiler_update_guide.md) を参照してください。

5. **ハードウェアキーボード & 物理操作最適化**:
   - `HardwareKeyRouter` により、テンキーや矢印キーによる8方向移動、各種アクションショートカット、拡張コマンドの直接入力など、PC や外部キーボード接続時の快適な打鍵操作をフルサポート。

6. **モバイル最適化 UI & スムーズなマップ操作**:
   - **マップ移動**: 巨大キャンバス `InteractiveViewer` 設計により、極端なズーム時やマップ端でも主人公の位置を画面中央やや上方 (35% 位置) に確実センタリングし、ズーム倍率を保持。
   - **操作補助**: 仮想方向パッド (D-Pad)、境界バーのタップ/クリックで開閉可能な拡張コマンドパネル、ショートカットキーパッド、仮想キーボードを搭載。
   - **各種ダイアログ**: 個数選択ダイアログ (`AmountSelectorDialog`)、メッセージ履歴 (`MsgHistoryDialog`)、直近メッセージボックス、`defaults.nh` (起動オプション) エディタ。

7. **カード型 UI & 日英バイリンガル対応 (墓石・ハイスコア)**:
   - ゲームオーバー・クリア時のハイスコア (`TopTenWidget`) や墓石 (`TombstoneWidget`) をカード形式でレイアウト。
   - 英語プロフィール (`Name-Role-Race-Gend-Align`) の自動分解・整形、日本語/英語双方のヘッダー検知、マルチ行エントリーの安全なパースに対応。

8. **FFI メモリ安全 & 高速マルチスレッド通信**:
   - Dart Worker Isolate との通信において 256 面以上の静的リングバッファを使用し、UTF-8 文字列の非同期 Use-After-Free (領域外参照) や文字化けを防止。
   - C 側での CP437 から UTF-8 へのリアルタイム変換および Dart 側の安全なデコード層。

9. **オートセーブ & 状態・視界保護**:
   - オートセーブ (`do_autosave`) 実行時の視界マップ (`viz_array`) 自動全復元 (`vision_recalc(0)`) および画面同期。
   - セーブデータへの乗馬・巻きつき ID (`m_id`) の確実な保持、セーブプレフィックスの自動クレンジング。

10. **リッチな音響システム (BGM / 効果音 / 環境音 / 音声)**:
    - 全フロア・特別部屋（計60種以上）のBGM再生、デュアルプレイヤーによるA/Bクロスフェード。
    - 完全ミキシング `AudioContext`（Android: `audioFocus: none` / iOS: `ambient`）により、SE再生時のBGM停止を根絶し、Spotify 等の外部音楽アプリと完全共存。

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
│   ├── nethack_cmd_panel.dart   # 拡張コマンドパネル（開閉バー対応）
│   ├── nethack_shortcut_pad.dart# ショートカットキーパッド
│   ├── nethack_keyboard.dart    # 仮想キーボード
│   ├── nethack_assets.dart      # アセット・フォント・タイルセット管理
│   ├── nethack_core_loader.dart # C コアライブラリの動的ロード
│   ├── amount_selector_dialog.dart # 個数選択ダイアログ
│   ├── defaults_editor.dart     # NetHack 起動オプション編集
│   ├── settings_page.dart       # 設定画面
│   ├── tileset_selection_page.dart # タイルセット選択・プレビュー画面
│   ├── input/                   # 入力ルーティング
│   │   └── hardware_key_router.dart # 物理キーボード・テンキー入力制御
│   ├── config/                  # 各種設定・定数
│   ├── l10n/                    # 多言語化リソース (ARB ファイル & 生成コード)
│   ├── models/                  # データモデル (TilesetInfo, TopTenEntry, TombstoneData 等)
│   ├── screens/                 # 各種画面コンポーネント (start_screen, end_screen 等)
│   ├── services/                # バックエンドサービス (sound_manager.dart 等)
│   ├── widgets/                 # 再利用可能な UI ウィジェット
│   │   ├── overlays/            # Cコア対話用オーバーレイ (メニュー, Y/N, 一行入力等)
│   │   ├── spoiler_dialog.dart  # ゲーム内スポイラー・解説ダイアログ
│   │   ├── sound_credits_dialog.dart # 音響クレジット表示ダイアログ
│   │   ├── topten_widget.dart   # ハイスコアカード表示
│   │   └── tombstone_widget.dart# 墓石カード表示
│   └── utils/                   # ユーティリティ関数
│
├── doc/                         # 各種設計・音響仕様書
│   ├── ambience_specs.md        # BGM・環境音・特別部屋BGM仕様書
│   ├── combat_sound_specification.md # 戦闘アクション効果音仕様書
│   ├── sound_macros_list.md     # 全316音のサウンドマスター仕様書
│   ├── sound_system_design.md   # 音響システム設計・確定実装仕様書
│   ├── spoiler_update_guide.md  # スポイラー更新手順書・仕様
│   └── voice_speech_specs.md    # 音声合成・セリフ演出仕様書
│
├── books/                       # スポイラー(攻略情報)原本 (Markdown)
│   ├── en/                      # 英語版 (companion.md)
│   └── jp/                      # 日本語版 (companion.jp.md)
│
├── scripts/                     # 開発・アセット保守スクリプト
│   ├── convert_images_to_webp.py# 画像アセット WebP 変換
│   ├── update_companion_jp.py   # 日本語版スポイラー更新・整形・アセット同期
│   └── update_companion_en.py   # 英語版スポイラー更新・整形・アセット同期
│
├── config/                      # NetHack 設定ファイル原本
│   ├── defaults.nh              # 起動オプション定義 (defaults.nh)
│   └── sysconf                  # システム設定 (sysconf)
│
├── tools/                       # 開発支援・アセット作成ツール
│   └── sound_curator/           # 効果音収集・作成支援ローカルWebツール
│
├── android/                     # Android プロジェクト設定 (Gradle / CMake)
├── windows/                     # Windows ランナー (C++ / CMake)
├── ios/                         # iOS Runner (Xcode プロジェクト)
├── dummy/                       # FFI 検証用スタブ実装
│
├── assets/                      # アプリに同梱する静的アセット
│   ├── ver                      # アセットバージョン番号（更新時に要インクリメント）
│   ├── nethackdir/              # NetHack データファイル一式
│   │   ├── common/              # 日英共通データ (ダンジョン定義 Lua 等)
│   │   ├── en/                  # 英語版データ (data, oracles, rumors 等)
│   │   └── jp/                  # 日本語版データ (data_jp, oracles_jp 等)
│   ├── sounds/                  # 効果音・BGM・環境音 (OGG/Opus ファイル配置場所)
│   ├── tiles/                   # タイルセット (16x16, Nevanda, PixelHack, Geoduck 等)
│   ├── images/                  # 背景・演出用画像
│   └── icon/                    # アプリアイコン
│
├── pubspec.yaml                 # Flutter パッケージ設定
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
│              ├─→ NetHackMapPainter (タイル描画 / 2層描画)       │
│              ├─→ HardwareKeyRouter (物理キーボード入力)        │
│              ├─→ DPad / CmdPanel / SoftKeyboard              │
│              ├─→ SoundManager (音響・BGMクロスフェード制御)    │
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

## 🎵 音響システム (BGM / 効果音 / 環境音 / 音声)

DartHack では、NetHack 5.0 のサウンドトリガー仕様に準拠した本格的な音響システム（`lib/services/sound_manager.dart`）を搭載しています。C コアから FFI 経由で発行されるイベントを Worker Isolate が受信し、Flutter 側でリアルタイムかつ低遅延に再生します。

### サウンドカテゴリ概要

| カテゴリ | C コア定数 | 再生方式 | 主な役割・用途 |
| :--- | :--- | :--- | :--- |
| **フロアBGM** | `SOUND_CAT_BGM` | ループ再生（デュアル交互） | ダンジョン各階層の探索曲（全31曲）。A/Bプレイヤー交互の1.0秒クロスフェード。 |
| **ルームBGM** | `SOUND_CAT_AMBIENCE` | ループ再生 | 店、寺院、動物園などの特別部屋（全35種）。フロアBGMと相互クロスフェード。 |
| **地形・環境音** | `SOUND_CAT_AMBIENCE` | ループ再生 | 水流、溶岩、暴風などフロアBGMと同時に鳴る環境音。 |
| **効果音 (SE)** | `SOUND_CAT_SE` | ワンショット（最大12音プール） | 攻撃、呪文、罠、アイテム等のゲームプレイSE。デバウンス・プリエンプション制御。 |
| **楽器演奏** | `SOUND_CAT_HEROMUSIC` | シーケンス再生 | 魔法の笛、角笛、ハープ、ドラムなどの音階シーケンス演奏。 |
| **ファンファーレ** | `SOUND_CAT_ACHIEVEMENT` | ワンショット | レベルアップ、実績達成、ゲーム開始/再開ファンファーレ。 |
| **音声・セリフ** | `SOUND_CAT_VOICE` | ワンショット / TTS | 神託、神の声、喋るアーティファクト等のセリフ演出。 |

### 音響アーキテクチャの主要な特徴
- **デュアルフロアBGMとクロスフェード**: 階層移動時の A/B 交互クロスフェード、特別部屋への進入/退出時のスムーズな音量減衰・復帰。
- **完全ミキシング (AudioFocus)**: Android（`audioFocus: none`）、iOS（`ambient`）、Windows で最適化し、SE 再生時の BGM 途切れを根絶。Spotify や YouTube Music などの外部アプリとの完全共存を実現。
- **多重再生最適化**: 最大12音同時再生プール、60ms デバウンス、同一音多重制限（最大3音）、二連撃マイクロディレイ（35ms）。
- **ライフサイクル連携**: バックグラウンド移行時の自動一時停止と安全な音源復帰。

※詳細なイベントID一覧、対照表、アーキテクチャ設計、更新手順については [`doc/`](doc/) 配下の仕様書を参照してください：
- サウンドマスター対照表: [`doc/sound_macros_list.md`](doc/sound_macros_list.md)
- BGM・環境音仕様: [`doc/ambience_specs.md`](doc/ambience_specs.md)
- 戦闘効果音仕様: [`doc/combat_sound_specification.md`](doc/combat_sound_specification.md)
- 音響システム詳細設計: [`doc/sound_system_design.md`](doc/sound_system_design.md)
- スポイラー更新手順書: [`doc/spoiler_update_guide.md`](doc/spoiler_update_guide.md)

---

## 🛠️ サウンドキュレーター（効果音収集・作成支援ツール）

C コアに定義された全サウンドアセットを効率よく収集・作成・管理するためのローカル Web ワークスペース（`sys/flutter/tools/sound_curator/`）です。

- **進捗ダッシュボード**: 全音源の収集進捗率、未設定/確定済フィルタ、インクリメンタル検索。
- **外部検索支援**: 国内外 13 のフリー音源サイトへのワンクリック検索バッジ。
- **ドラッグ＆ドロップ自動正規化**: 音声ファイルをドロップするだけで、`ffmpeg` により無音カット、EBU R128 (-14 LUFS) 正規化、Opus (48kHz) エンコードを一括実行。
- **楽器音の自動生成**: SoundFont (`FluidR3 GM`) と `FluidSynth` による音階サンプルの自動生成。
- **ライセンス自動記録**: 採否と同時に `attributions.txt` へ出典・規約を自動記録。

#### 起動方法
```powershell
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/run_curator.ps1
```
※ブラウザで `http://localhost:8765` が自動的に開きます。音量バランス検査には `check_volumes.ps1` を利用可能です。

---

## 🔄 c_core 配下（Cコアソース）の管理と取り込み方法

`c_core/nethack_jp` および `c_core/nethack_en` は DartHack 独自の拡張・修正（UTF-8化、FFI互換処理、自動バイリンガル切替など）を含むため、`git submodule` ではなく **Git Subtree** 方式で管理されています。

### 1. NetHackJP 本家更新の同期 (`c_core/nethack_jp`)
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_jp.ps1
```

### 2. NetHack 本家更新の同期 (`c_core/nethack_en`)
```powershell
powershell -ExecutionPolicy Bypass -File c_core/sync_nethack_en.ps1
```

> [!IMPORTANT]
> **`--squash` 必須化原則**:
> `c_core/nethack_jp` と `c_core/nethack_en` は同一リポジトリ・コミットオブジェクトを共有しています。Git の 3-way merge における Merge-Base 混信や変更脱落を防止するため、同期スクリプトでは必ず `--squash` を指定して同期しています。
> データファイルに変更が入った場合は、`sys/flutter/assets/ver` のバージョン番号をインクリメント (+1) してください。

---

## 🧪 Flutter / Dart コードの検証手順

開発・コード変更時の Dart および Flutter UI 側の構文チェック・静的解析・テスト検証には以下の標準コマンドを使用します。

### 1. 静的解析 (Lint チェック)

```bash
cd sys/flutter
flutter analyze
```
エラーや警告が出力されないことを確認してください。

### 2. 単体テスト・ウィジェットテスト

```bash
cd sys/flutter
flutter test
```
すべてのテストケースがパスすることを確認してください。


---

## ⚖️ ライセンス

本ディレクトリ配下の Dart / Flutter コードおよび C 移植コードは NetHack General Public License に準じます。同梱アセットの権利は各著作者に帰属します。
