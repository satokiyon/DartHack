<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-09-19. -->
# NetHackサウンド機構とDartHack音響システム設計・確定実装仕様書

本書は、NetHack 5.0のCコアに導入されたサウンドサブシステム（`soundlib`）の仕組みを解説し、それに基づいて **DartHack（Flutter/FFIポート）** で稼働している効果音・音楽・環境音・音声の確定アーキテクチャ、実装仕様、および運用知見を包括的にまとめた技術仕様書です。

---

## 1. NetHack 5.0 (Cコア) サウンドサブシステムの概要

NetHack 5.0では、画面描画の `window_procs` と同様に、サウンド再生機能をプラットフォーム独立な抽象化レイヤー `soundlib` (`struct sound_procs`) として統一管理しています。

### 1.1 基本構造 (`struct sound_procs`)
`include/sndprocs.h` に定義されている `struct sound_procs` は、サウンドエンジンの各種イベントハンドラを指す関数ポインタ構造体です。

```c
struct sound_procs {
    const char *soundname;            /* サウンドライブラリ名 (例: "windsound", "fluttersound") */
    enum soundlib_ids soundlib_id;    /* サウンドライブラリID */
    unsigned long sound_triggers;     /* このライブラリがサポートする機能ビットマスク */
    
    void (*sound_init_nhsound)(void);
    void (*sound_exit_nhsound)(const char *reason);
    void (*sound_achievement)(schar arg1, schar arg2, int32_t avals);
    void (*sound_soundeffect)(char *desc, int32_t seid, int32_t volume);
    void (*sound_hero_playnotes)(int32_t instrument, const char *notestr, int32_t volume);
    void (*sound_play_usersound)(char *filename, int32_t volume, int32_t idx);
    void (*sound_ambience)(int32_t ambience_action, int32_t ambienceid, int32_t proximity);
    void (*sound_verbal)(char *text, int32_t gender, int32_t tone, int32_t vol, int32_t moreinfo);
};
```

---

## 2. Cコアの 6大サウンドトリガー (`SOUND_TRIGGER_*`)

Cコアから出力されるサウンドイベントは、以下の6つのトリガー種別に分類されます。

| トリガー種別 (ビットマスク) | 説明 | Cコアの呼び出しマクロ / 関数の例 |
| :--- | :--- | :--- |
| `SOUND_TRIGGER_SOUNDEFFECTS` (0x0008) | ゲーム内現象の効果音（ドア開閉、爆発、戦闘、罠、モンスター鳴き声等） | `Soundeffect(seid, vol)` |
| `SOUND_TRIGGER_HEROMUSIC` (0x0002) | プレイヤー/NPCの楽器演奏（木製フルート、角笛、ラッパ、ハープ等） | `Hero_playnotes(instrument, str, vol)` |
| `SOUND_TRIGGER_ACHIEVEMENTS` (0x0004) | ゲーム実績・システムイベント（レベルアップ/ダウン、スプラッシュ等） | `SoundAchievement(arg1, arg2, avals)` |
| `SOUND_TRIGGER_USERSOUNDS` (0x0001) | 設定ファイル（`defaults.nh`）の正規表現一致による効果音再生 | `Play_usersound(filename, vol, idx)` |
| `SOUND_TRIGGER_AMBIENCE` (0x0010) | ダンジョン環境音・フロアBGM・ルームBGM（開始/停止/更新） | `soundprocs.sound_ambience(...)` |
| `SOUND_TRIGGER_VERBAL` (0x0020) | 台詞・音声出力（神の呼びかけ、アーティファクトの喋り声、TTS等） | `SoundSpeak(text)` |

### 2.1 主要なマクロと安全装置
`include/sndprocs.h` に定義されている呼び出し用マクロは、オプション設定（`iflags.sounds`）や盲目/難聴状態（`Deaf`）などを自動判定した上で、`soundprocs` の関数ポインタを呼び出します。

```c
#define Soundeffect(seid, vol) \
    do { \
        if (iflags.sounds && !Deaf && soundprocs.sound_soundeffect \
          && ((soundprocs.sound_triggers & SOUND_TRIGGER_SOUNDEFFECTS) != 0)) \
            (*soundprocs.sound_soundeffect)(emptystr, (seid), (vol)); \
    } while(0)
```

---

## 3. サウンドIDとアセットの対応関係

### 3.1 効果音ID (`seffects.h`)
`include/seffects.h` には **239 種類** の効果音ID（`enum sound_effect_entries`）が定義されています（一般効果音 206種 + 戦闘アクション効果音 33種）。
- 例: `se_door_open` (開扉), `se_door_close` (閉扉), `se_magic_whistle` (魔法の笛), `se_explosion` (爆発), `se_kick` (キック打撃), `se_stairs_up` / `se_stairs_down` (階段昇降), `se_glass_shattering` (ガラス破砕), `se_combat_hit_slash` (斬撃)

### 3.2 楽器ID (`sndprocs.h`)
`enum instruments` には、GM (General MIDI) に準拠した楽器IDが割り当てられています。
- 音階バリエーションあり（フルート、角笛、ラッパ、ハープ等 6種 × A〜G 7音 = 42ファイル）
- 固定演奏（火炎の角笛、凍結の角笛、ベル、地震の太鼓、革製太鼓 = 5ファイル）
- 計 **47 ファイル** の `.ogg` が対応。

### 3.3 実績・システム音 (`sa2_*` / `ach_*`)
- システムイベント音: 4種（スプラッシュ画面、新規ゲーム、レベルアップ、レベルダウン）
- 実績達成音: 19種（ベル、燭台、書物、アミュレット、アストラル界、クリア等）
- 計 **23 ファイル** の `.ogg` が対応。

### 3.4 声音 (`voice_*`)
- 神の声、オラクル、喋るアーティファクト、玉座、死神、店主、汎用NPCの計 **7 ファイル** の `.ogg` が対応。

**全サウンドアセット総数**: 239 + 47 + 23 + 7 = **全 316 種**。

---

## 4. DartHack (Flutter / Dart FFI) 確定アーキテクチャと実装仕様

DartHack では、Cコアの `fluttersound` 移植層から Dart FFI、Worker Isolate、そして UI スレッドの `SoundManager` に至るマルチスレッド安全な音響パイプラインを完全構築・稼働させています。

### 4.1 全体パイプライン

```
┌──────────────────────────────────────────────────────────────┐
│  NetHack C Core (Pthread スレッド)                           │
│  Soundeffect() / Hero_playnotes() / SoundAchievement() 等   │
└──────────────────────────────┬───────────────────────────────┘
                               │ C function call
┌──────────────────────────────▼───────────────────────────────┐
│  winflutter.c / fluttersound_procs                           │
│  1. サウンドID・引数をイベントパケット化                       │
│  2. FFI NativeCallable コールバック経由で非同期発行          │
└──────────────────────────────┬───────────────────────────────┘
                               │ FFI async callback
┌──────────────────────────────▼───────────────────────────────┐
│  Worker Isolate (nethack_worker.dart)                        │
│  1. FFI メモリの安全デコード（Use-After-Free 防止）           │
│  2. SendPort 経由で UI Isolate へメッセージ転送              │
└──────────────────────────────┬───────────────────────────────┘
                               │ SendPort.send()
┌──────────────────────────────▼───────────────────────────────┐
│  UI Isolate: SoundManager (sound_manager.dart)               │
│  1. カテゴリ判別（BGM / SE / 環境音 / 音声）                 │
│  2. プレイヤープール（最大12音同時再生・60msデバウンス）       │
│  3. audioplayers 経由でネイティブ再生                         │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 Cコア移植層 (`fluttersound_procs`) の実装
`c_core/nethack_jp` および `c_core/nethack_en` の移植層において、`struct sound_procs` に `fluttersound_procs` を登録し、全6大トリガーを有効化（`SOUND_TRIGGER_ALL`）しています。

```c
struct sound_procs fluttersound_procs = {
    "fluttersound",
    soundlib_fluttersound,
    SOUND_TRIGGER_SOUNDEFFECTS | SOUND_TRIGGER_HEROMUSIC
        | SOUND_TRIGGER_ACHIEVEMENTS | SOUND_TRIGGER_AMBIENCE
        | SOUND_TRIGGER_VERBAL,
    fluttersound_init_nhsound,
    fluttersound_exit_nhsound,
    fluttersound_achievement,
    fluttersound_soundeffect,
    fluttersound_hero_playnotes,
    fluttersound_play_usersound,
    fluttersound_ambience,
    fluttersound_verbal,
};
```

### 4.3 4系統独立オーディオ制御 (`SoundManager`)
Flutter 側（`lib/services/sound_manager.dart`）では、音の役割と演出意図に合わせて独立したプレイヤー群を管理しています：

1. **フロアBGM (`_floorBgmPlayer`)**:
   - 運命の大迷宮、城、メデューサ、ゲヘナ、精霊界など階層全体の探索BGM（ループ再生）。
2. **ルームBGM (`_roomBgmPlayer`)**:
   - 店、寺院、宝物庫、動物園、玉座など特別な部屋の専用曲（ループ再生）。
   - **クロスフェード & フォールバック**: 進入時にフロアBGMを300msでフェードアウト一時停止（`pause`）し、ルームBGMを再生。音源が存在しない場合はフロアBGMをそのまま無音化させずに継続。出入りチャタリングは世代トークン（Generation Token）で音量競合を完全に排除。
3. **環境音 (`_ambiencePlayer`)**:
   - 水流、溶岩、暴風、雨などフロアBGMと同時に鳴る環境ループ音（距離減衰対応）。
4. **効果音プレイヤープール (`_sePool`)**:
   - ゲームプレイSE・戦闘SE・ファンファーレのワンショット再生。

### 4.4 効果音 (SE) プレイヤープールの高度制御仕様
- **最大12音同時再生プレイヤープール**:
  12個の独立した `AudioPlayer` インスタンスを循環管理し、激しい乱戦や召喚ラッシュ時でも音が途切れないリッチな多重和音を実現。
- **同一音多重制限（最大3インスタンス）**:
  同一のサウンドファイルが短時間に連続して再生される際、最大3インスタンスまでに制限し、音割れや爆音化を防止。
- **短時間デバウンス（60ms）**:
  同一フレーム・極短時間の多重発火を自動で間引き、クリアな音響を維持。
- **二連撃マイクロディレイキュー（35ms）**:
  二刀流攻撃やモンスターの2連撃（爪×2等）で同一SEが 0〜25ms 以内に連続要求された際、2撃目を約35ms遅延させて再生（「タ・タン！」というリアルな連撃感を演出）。
- **重要音のプリエンプション（割り込み再生）**:
  プール満杯時に重要アラーム（`se_alarm`）、呪文詠唱、バンシーの絶叫、実績達成音などの優先音響が要求された場合、再生中の通常戦闘打撃音を安全にフェード停止して割り込み再生を保証。

---

## 5. OS・パーミッション健全性維持とトラブルシューティング知見

Android / Flutter (FFI) 環境特有のマルチスレッド・同一プロセス制約により得られた極めて重大なアーキテクチャ知見です（`AGENTS.md` 恒久ルール準拠）。

### 5.1 Cコアのプロセスグローバルな `umask` 汚染防止
- **メカニズム**:
  UNIX版 NetHack はファイル作成マスクとして `FCMASK = 0660` を定義しており、初期化時に `umask(0777 & ~FCMASK)` を呼び出します。しかし `~FCMASK` と `0777` の AND は **`0117`** となり、以後のディレクトリ作成から実行権限（`x`）をすべて剥奪するマスクとなります。
- **同一プロセスの罠**:
  Android / Flutter (FFI) では Cコアと Dart VM / Flutter エンジンが**同一プロセス内の別スレッド**として同居しています。POSIX 仕様上 `umask` はスレッドローカルではなく**プロセス全体共通**に適用されるため、Cコアが `umask(0117)` を設定すると、Dart 側（`audioplayers` キャッシュ、I/O 等）が作成する全ディレクトリから `x` 権限が剥奪され、以後の探索・存在確認が OS から `Permission denied (errno = 13)` で拒絶されてクラッシュします。
- **対策**:
  Android / Flutter 移植層（`fluttermain.c` 等）においてディレクトリ実行権限を剥奪するマスクを絶対に渡してはならず、標準の安全な **`umask(0022)`**（ディレクトリ: `0755`、ファイル: `0644`）を設定・維持します。

### 5.2 破損ディレクトリの残存と端末アンインストール対処
- ディレクトリから `x` 権限が剥奪された破損ディレクトリが端末上に一度作成されると、Linux VFS では子ディレクトリの走査（`opendir`/`readdir`）ができないため、Dart の `Directory.delete(recursive: true)` も権限不足で失敗します。
- PC側の「クリーン＆ビルド」は端末内の内部ストレージ（`/data/user/0/...`）を削除しないため、パーミッション破損の解消には **端末側でのアプリの完全アンインストール（`adb uninstall`）または「ストレージ消去」** が必須となります。

### 5.3 エラーハンドリングにおける `catch (_)` の禁止と構造化ログの徹底
- サウンドマネージャーや非同期 I/O において、`catch (_)` による例外の握りつぶしは真の根本原因（`PathAccessException: Exists failed (errno = 13)` 等）を隠蔽して調査を著しく困難にします。
- 必ず `catch (e, st)` で捕捉し、`debugPrint` で例外名とスタックトレースを明示的に出力する設計を徹底します。

---

## 6. サウンド制作・キュレーションツール連携

全 316 種のサウンドアセットを高品質に収集・管理するため、専用のローカルWebツールを整備しています。

### 6.1 サウンドキュレーター (`tools/sound_curator/`)
- **Webダッシュボード**: `http://localhost:8765` で動作し、全316音の進捗管理、未設定/確定済フィルタ、インクリメンタル検索を提供。
- **外部音源検索支援**: 国内外13サイト（効果音ラボ、Pixabay、Freesound等）への最適キーワードワンクリック検索。
- **ドラッグ＆ドロップ自動正規化**: ドロップされた音声ファイルを `ffmpeg` により先頭無音カット、**EBU R128 (-14 LUFS / True Peak -1.0dBFS)** 正規化、Ogg Opus (48kHz) エンコード。
- **楽器音 47種自動生成**: `FluidR3 GM` SoundFont と `FluidSynth` によるピッチ正確な全音階自動サンプリング。
- **ライセンス一覧自動生成**: `attributions.txt` に出典・ライセンス規約を自動記録。

### 6.2 音量診断・一括修復スクリプト (`check_volumes.ps1`)
```powershell
# 規定値から外れた音源の診断
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -WarnOnly

# 一括自動適正化（True Peak -1.5 dBFS 修復）
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -Fix
```

---

## 7. 戦闘アクション効果音システム (Combat Sound System)

戦闘アクション効果音（近接攻撃、空振り、射撃、投擲、着弾、呪文、杖、モンスター生体攻撃12種など計33種）は、共通ヘルパー集約方式により Cコアから低遅延に発行されます。

詳細な判定ロジック、音量スケーリング、武器属性マッピング、および音響素材制作ガイドラインは、専用仕様書 [`combat_sound_specification.md`](combat_sound_specification.md) を参照してください。

---

## 8. 仕様書一覧・相互参照

- [sound_macros_list.md](sound_macros_list.md): 全316音マスター管理表 & Cコア内全376箇所呼び出し対照表
- [combat_sound_specification.md](combat_sound_specification.md): 戦闘アクション効果音（33種）詳細仕様書
- [ambience_specs.md](ambience_specs.md): フロアBGM・特別部屋BGM・環境音詳細仕様書
- [voice_speech_specs.md](voice_speech_specs.md): 声音・神託・TTS発話詳細仕様書
