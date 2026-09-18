<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-19. -->
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

6. **リッチな音響システム (BGM / 効果音 / 環境音 / 音声)**:
   - 全ダンジョン分岐・特殊階層（城、メデューサ、聖所、精霊界など計31種）および特別部屋（店、寺院、動物園など計35種）のBGM再生に対応。
   - 2プレイヤー構成によるフロアBGMとルームBGMのシームレスなクロスフェード再生、音源ファイル欠落時の自動フォールバック（無音化・中断防止）。
   - 出入りチャタリング防止（世代カウンタによる音量競合排除）、アプリバックグラウンド移行時の自動一時停止・復帰、セーブデータ再開時の部屋BGM即時復元。

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
│   ├── services/                # バックエンドサービス (sound_manager.dart 等)
│   │   └── sound_manager.dart   # 音響再生・2プレイヤー制御・ライフサイクル管理
│   ├── widgets/                 # 再利用可能な UI ウィジェット (overlays, TopTenWidget 等)
│   └── utils/                   # ユーティリティ関数
│
├── doc/                         # 各種設計・仕様書
│   ├── ambience_specs.md        # BGM・環境音・特別部屋BGM仕様書
│   ├── combat_sound_specification.md # 戦闘アクション効果音仕様書
│   ├── sound_macros_list.md     # 全313音のサウンドマスター仕様書
│   ├── sound_system_design.md   # 音響システム設計・確定実装仕様書
│   └── voice_speech_specs.md    # 音声合成・セリフ演出仕様書
│
├── tools/                       # 開発支援・アセット作成ツール
│   └── sound_curator/           # 効果音収集・作成支援ローカルWebツール
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
│   ├── sounds/                  # 効果音・BGM・環境音 (OGG ファイル配置場所)
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

## 🎵 音響システム (BGM / 効果音 / 環境音 / 音声)

DartHack では、NetHack 5.0 のサウンドトリガー仕様に準拠した本格的な音響システム（`lib/services/sound_manager.dart`）を搭載しています。C コアから FFI 経由で発行されるイベントを Worker Isolate が受信し、Flutter 側でリアルタイムかつ低遅延に再生します。

### 1. サウンドカテゴリと階層構造

| カテゴリ | C コア定数 | 再生方式 | 主な役割・用途 |
| :--- | :--- | :--- | :--- |
| **フロアBGM** | `SOUND_CAT_BGM` | ループ再生（`_floorBgmPlayer`） | 運命の大迷宮、城、メデューサの島、ノームの鉱山、ゲヘナ、精霊界など階層全体の探索曲（全31曲）。 |
| **ルームBGM** | `SOUND_CAT_AMBIENCE` | ループ再生（`_roomBgmPlayer`） | 店、寺院、宝物庫、動物園、兵舎、王座などの特別部屋に入った際にフロアBGMとクロスフェードする専用曲（全35種）。 |
| **地形・天候環境音** | `SOUND_CAT_AMBIENCE` | ループ再生（`_ambiencePlayer`） | 水流、溶岩、暴風、雨、沼地などフロアBGMと同時に鳴る環境音（距離減衰あり）。 |
| **効果音 (SE)** | `SOUND_CAT_SE` | ワンショット（最大12重和音プール） | 攻撃、呪文詠唱、罠作動、アイテム使用、ドア開閉などのゲームプレイSE。最大同時12音プール、60msデバウンス、同一音最大3インスタンス制限、重要音プリエンプション制御。 |
| **楽器演奏** | `SOUND_CAT_HEROMUSIC` | シーケンス再生 | 魔法の笛、角笛、ハープ、ドラムなどの音階シーケンス演奏。 |
| **実績・ファンファーレ** | `SOUND_CAT_ACHIEVEMENT` | ワンショット | レベルアップ、実績達成、ゲーム開始/再開ファンファーレ。 |
| **音声・セリフ (Voice)** | `SOUND_CAT_VOICE` | ワンショット / TTS | デルフィの神託、神の声、喋るアーティファクト、死因アナウンス等のセリフ演出。 |

### 2. 2プレイヤー構成とフォールバック・クロスフェード
フロアBGMとルームBGMには独立した `AudioPlayer` インスタンスを割り当てており、高いUX品質を実現しています：
- **シームレスな一時停止と再開**: 特別部屋に入るとフロアBGMを約300msでフェードアウトして一時停止（`pause`）し、ルームBGMをフェードイン再生します。部屋を出るとルームBGMをフェードアウト停止し、フロアBGMが中断位置からシームレスに再開（`resume`）します。
- **ファイル欠落時のフォールバック**: 特別部屋のBGM音源（`.ogg`）がまだ配置されていない場合、**フロアBGMを止めずにそのまま途切れず継続再生**します（無音化や不要なフェードを防止）。
- **出入りチャタリング防止**: ドアの境界を素早く行き来した際、世代カウンタ（Generation Token）により古い非同期フェードループを即座に破棄し、音量競合（Volume Fighting）を完全に防ぎます。
- **テレポート・ワープ対応**: テレポートや落とし穴（穴落ち・レベルテレポート）で突然部屋から通路へワープした場合も、C コアの `check_special_room()` が旧部屋の退出を検知して即座にフロアBGMへ復帰します。
- **ライフサイクル連動**: アプリがバックグラウンドに回った際（画面ロックや着信含む）は自動で全音声を一時停止し、フォアグラウンド復帰時に元々鳴っていた音楽のみを安全に再開します。
- **セーブデータ互換性**: 音響情報はセーブファイルへ直接保存せず、すべて実行時イベントとして動作するため、過去バージョンのセーブデータとの100%完全な後方互換性を保持しています。

### 3. 効果音 (SE) プレイヤープールと最適化
効果音の多重再生と快適な演出のため、以下の制御機構を搭載しています：
- **最大12音同時再生プレイヤープール**: 同時に最大12個の独立した `AudioPlayer` インスタンスを循環管理し、激しい乱戦時でも音が途切れないリッチな音響体験を提供します。
- **同一音多重制限（最大3インスタンス）**: 連続ヒットや同時発生時でも、同一のサウンドファイルが4つ以上重なって爆音化・歪みが発生するのを防ぎます。
- **短時間デバウンス（60ms）**: 60ms 以内の極短時間に同一SEが多重発行された場合は自動で間引き、クリアな音質を維持します。
- **重要音のプリエンプション（割り込み再生）**: プールが満杯の際に実績音や重要アラーム、魔法発動音などの優先度が高いSEが要求された場合、再生中の通常戦闘SEを安全にフェード停止して割り込み再生します。

### 4. 音源ファイルの配置方法と仕様書
- 音源ファイル（`.ogg` 形式）は `sys/flutter/assets/sounds/` 配下に配置します。
- 全313音（一般効果音203種、戦闘アクション効果音33種、実績・システム音23種、楽器演奏音47種、声音7種）のイベントID、対応ファイル名、Cコア呼び出し行対照表は [`doc/sound_macros_list.md`](doc/sound_macros_list.md) を参照してください。
- 戦闘アクション効果音の詳細仕様・判定ロジックについては [`doc/combat_sound_specification.md`](doc/combat_sound_specification.md) を参照してください。
- 詳細なBGM・環境音のイベントID、対応ファイル名、部屋一覧、判定ロジックについては [`doc/ambience_specs.md`](doc/ambience_specs.md) を参照してください。
- 音声合成・セリフイベントの仕様については [`doc/voice_speech_specs.md`](doc/voice_speech_specs.md) を参照してください。
- 音響システム全体の詳細アーキテクチャ・FFI連携仕様については [`doc/sound_system_design.md`](doc/sound_system_design.md) を参照してください。

---

## 🛠️ サウンドキュレーター（効果音収集・作成支援ツール）

Cコアの全効果音・戦闘音・楽器音・音声イベント仕様（[`doc/sound_macros_list.md`](doc/sound_macros_list.md)）に定義されている **全 313 種のサウンドアセット** を、効率よく・高品質かつ狙い通りに収集・作成・管理するためのローカルWebワークスペース（`sys/flutter/tools/sound_curator/`）です。

### 1. 主な機能と特徴
- **全313音の進捗ダッシュボード**:
  - リアルタイム進捗率（パーセンテージ）表示、未設定/確定済フィルタ、カテゴリ別フィルタ（効果音/戦闘/実績/楽器/声音）、インクリメンタル検索。
- **ワンクリック外部検索支援（全 13 サイト対応）**:
  - 各カード内に色分けされたコンパクトバッジが常時表示され、ワンクリックで最適な日本語/英語キーワードがセットされた検索ページを開きます。
  - **🇯🇵 国内サイト (8件)**: 効果音ラボ、On-Jin ～音人～、OtoLogic、効果音辞典、Springin' Sound Stock、魔王魂、ポケットサウンド、甘茶の音楽工房
  - **🌐 海外・オープン素材 (5件)**: Pixabay、SoundDino、Freesound.org、ZapSplat、OpenGameArt.org
- **ドラッグ＆ドロップ登録 & 自動正規化 (`ffmpeg`)**:
  - ダウンロードした音声ファイル（WAV/MP3/OGG等）をカードにドロップするだけで即時取り込み。
  - ファイル名から出典サイト・ライセンス規約を自動判別し、`ffmpeg` により **先頭無音ミリ秒カット**、**EBU R128 (-14 LUFS / True Peak -1.0dBFS) 正規化**、**Ogg Opus (48kHz) エンコード** を一括実行して `assets/sounds/` に配置。
- **楽器音 47 種の完全自動生成**:
  - オープンSoundFont（`FluidR3 GM`）と `FluidSynth` を用いた自動サンプリング（`generate_instruments.py`）により、フルート・角笛・ラッパ・ハープ等の A〜G 各音階（42種）および固定楽器音（5種）をミリ秒単位の正確なピッチで自動生成済み。
- **ライセンス一覧（`attributions.txt`）の自動生成**:
  - 採否と同時に、作者・出典URL・ライセンス規約が `sys/flutter/assets/sounds/attributions.txt` に本家フォーマット準拠で自動記録。

### 2. ツールの起動方法

#### PowerShell スクリプト（推奨）
```powershell
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/run_curator.ps1
```
ローカルWebサーバーが立ち上がり、既定のWebブラウザで `http://localhost:8765` が自動的に開きます。

#### 手動起動
```powershell
python sys/flutter/tools/sound_curator/server.py
```
ブラウザで `http://localhost:8765` にアクセスしてください（終了時は `Ctrl + C`）。
※外部 pip パッケージのインストールは不要（Python 標準ライブラリで動作）です。

### 3. 使用方法・キュレーションワークフロー
1. ブラウザで画面を開き、上部の **「⏳ 未設定のみ」** フィルタを選択します。
2. 収集したい効果音カードの検索バッジ（例: **［効果音ラボ］**、**［Pixabay］**、**［Freesound］** 等）をクリックして目的の音源をダウンロードします。
3. ダウンロードした音声ファイルをカードの「📥 ドロップゾーン」にドラッグ＆ドロップします。
4. モーダルで出典サイトやライセンス（自動推定されます）を確認し、**「正規化 & 確定 (Opus変換)」** ボタンをクリックします。
5. 自動的に Opus 変換され、確定済みカードに切り替わり、試聴プレイヤーで仕上がりを確認できます。

### 4. 音量バランス検査・自動適正化ツール (check_volumes)
全音源の音量・音圧バランスが適正かを常時チェックし、過小音量や頭打ち（音割れ）を一括修復できます。

```powershell
# PowerShell スクリプト（問題のある音源のみ表示）
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -WarnOnly

# 問題のある音源を一括自動修復（ピーク -1.5 dBFS に適正化）
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -Fix
```
※Web UI（サウンドキュレーター）の画面上部にある **［🔊 音量診断］** ボタンからも、全音源の測定およびワンクリック修復が可能です。

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
