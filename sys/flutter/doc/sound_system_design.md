# NetHackサウンド機構の解説とDartHackにおける効果音実装検討書

NetHack 5.0のCコアに導入されたサウンドサブシステム（`soundlib`）の仕組みを整理し、それに基づいて **DartHack（Flutter/FFIポート）** で効果音・音楽を再生するためのアーキテクチャ設計および実装方針を検討・整理します。

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
| `SOUND_TRIGGER_SOUNDEFFECTS` (0x0008) | ゲーム内現象の効果音（ドア開閉、爆発、モンスターの鳴き声等） | `Soundeffect(seid, vol)` |
| `SOUND_TRIGGER_HEROMUSIC` (0x0002) | プレイヤー/NPCの楽器演奏（木製フルート、角笛、ラッパ等） | `Hero_playnotes(instrument, str, vol)` |
| `SOUND_TRIGGER_ACHIEVEMENTS` (0x0004) | ゲーム実績・システムイベント（レベルアップ/ダウン、復元、スプラッシュ等） | `SoundAchievement(arg1, arg2, avals)` |
| `SOUND_TRIGGER_USERSOUNDS` (0x0001) | 設定ファイル（`defaults.nh`）の正規表現一致による効果音再生 | `Play_usersound(filename, vol, idx)` |
| `SOUND_TRIGGER_AMBIENCE` (0x0010) | ダンジョン環境音・BGM（雰囲気音の開始/停止/更新） | `soundprocs.sound_ambience(...)` |
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
`include/seffects.h` には 190 種類以上の効果音ID（`enum sound_effect_entries`）が定義されています。
- 例: `se_door_open` (ドアが開く), `se_explosion` (爆発), `se_low_buzzing` (羽音), `se_squeak_A`〜`se_squeak_G_sharp` (革袋のチューニング音)

### 3.2 楽器ID (`sndprocs.h`)
`enum instruments` には、GM (General MIDI) に準拠した楽器IDが割り当てられています。
- 例: `ins_flute` (74), `ins_french_horn` (61), `ins_baritone_sax` (68), `ins_trumpet` (57), `ins_taiko_drum` (117)
- 演奏される音符列は文字列（例: `"A"`, `"C#"`, `"G"`）として渡されます。

### 3.3 デフォルトアセット構成 (`sound/wav/`)
`c_core/nethack_jp/sound/wav/` には標準の `.wav` サウンドアセット群が収録されており、`src/sounds.c` の `get_sound_effect_filename()` によって `se_door_open.wav` のようにファイル名へ自動マッピングされます。

---

## 4. DartHack (Flutter / Dart FFI) における実装検討

現在 DartHack の `winflutter.c` においては、`androidsound_procs` が全関数 `(void*)0` のダミーとして定義されており、効果音が出力されない状態になっています。

DartHack で効果音・音楽をスムーズに再生するため、**Cコアと Flutter (Dart) 間の FFI 通信層** および **Flutter 側のオーディオエンジン** の構成を検討します。

### 4.1 全体アーキテクチャ案

```
+-------------------------------------------------------------+
|                     NetHack C Core                          |
|  Soundeffect() / Hero_playnotes() / SoundAchievement()      |
+------------------------------+------------------------------+
                               | (C function call)
                               v
+-------------------------------------------------------------+
|              winflutter.c (fluttersound_procs)              |
|  1. イベント構造体を生成                                      |
|  2. スレッドセーフなリングバッファ/キューに格納               |
+------------------------------+------------------------------+
                               | (Dart FFI Callback / Poll)
                               v
+-------------------------------------------------------------+
|                Dart (Flutter Engine / SoundManager)         |
|  1. イベントをデコード (seid, volume, instrument, etc.)     |
|  2. アセットパス解決 (assets/sounds/se_door_open.mp3 等)     |
|  3. AudioPlayer / Soundpool で再生                          |
+-------------------------------------------------------------+
```

---

### 4.2 Cコア ↔ Dart 間の FFI 設計（メモリ安全と非同期配慮）

ユーザー定義ルール（**FFI コールバックにおける非同期 Use-After-Free 回避と文字列の安全変換**）に従い、以下の点に注意した設計とします。

1. **Cコア側 (`winflutter.c`) の実装**:
   - `fluttersound_procs` を定義し、`SOUND_TRIGGER_SOUNDEFFECTS | SOUND_TRIGGER_HEROMUSIC | SOUND_TRIGGER_ACHIEVEMENTS` を有効化。
   - コールバック呼び出し時、引数の文字列やIDを固定長構造体（イベントパケット）へコピーし、Cコアスレッドをブロックしないようにリングバッファ（または FFI `NativeCallable`）経由で Dart 側へ送信。

2. **Dart イベント構造体（ポインタ引き渡しなしの安全設計）**:
   ```dart
   enum SoundEventType { soundEffect, heroMusic, achievement, userSound }

   class SoundEvent {
     final SoundEventType type;
     final int id;         // seid または instrument または ach2
     final int volume;     // 1 ~ 100
     final String? noteStr; // 演奏音符 (文字列が必要な場合のみ)
     SoundEvent({...});
   }
   ```

---

### 4.3 Flutter オーディオエンジンの選定

Flutter での効果音・音楽再生において、以下のパッケージまたはネイティブ連携を比較・検討します。

| パッケージ / 方式 | 特徴・長所 | 短所 / 注意点 | DartHackでの推奨度 |
| :--- | :--- | :--- | :--- |
| **`soundpool`** (pub.dev) | iOS/Android の Native SoundPool API を使用。**超低遅延**で効果音の同時・連打再生に強い。メモリ消費が少ない。 | 長時間のBGM再生や複雑なストリーミングには不向き（数秒までの短音向け）。 | **効果音 (SE) 向けに最推奨** ⭐⭐⭐ |
| **`audioplayers`** (pub.dev) | BGM再生、効果音再生の両方に対応。機能が豊富でクロスプラットフォーム（Windows, Android, iOS, Web）に対応。 | 短音の連打時に若干のレイテンシが発生する場合がある（AudioCache/SoundPoolモードの指定で改善可能）。 | **BGM / 汎用SE 向けに推奨** ⭐⭐ |
| **`soloud`** (pub.dev) | SoLoud C++ エンジンベース。低遅延、ピッチ・ボリューム・エフェクト制御が強力。 | Nativeビルドのセットアップが必要。 | **将来の高度な効果音処理向け** ⭐ |

**推奨構成**:
- **効果音 (SE)**: `soundpool`（Android / iOS の低遅延再生）または `audioplayers` の低遅延インスタンス。
- **BGM / 環境音 / 演奏**: `audioplayers`（ストリーミング再生対応）。

---

### 4.4 サウンドアセットの配置とロード方針

NetHackJP のデータファイル配置ルールに従い、アセット管理を整理します。

1. **アセット配置ディレクトリ**:
   `sys/flutter/assets/sounds/`
   - 効果音: `se_door_open.ogg` (または `.mp3` / `.wav`)
   - 楽器音: `ins_flute_A.ogg` 等
   - 実績・システム音: `sa2_xplevelup.ogg` 等

2. **`pubspec.yaml` への登録**:
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```

3. **アセットマッピングテーブル (Dart側)**:
   `seid` (整数値) から Flutter アセットパスへのマッピングを Dart 内の `Map<int, String>` または enum で一括管理。

---

## 5. 実装ステップ案

1. **ステップ 1: サウンドアセットの準備**:
   - `c_core/nethack_jp/sound/wav/` の `.wav` ファイルを `.mp3` や `.ogg` 等に最適化し（または `.wav` のまま）、`sys/flutter/assets/sounds/` に配置。
2. **ステップ 2: `winflutter.c` の Cコア連携拡張**:
   - `fluttersound_procs` を作成し、Cコアのサウンドイベントを捉えて FFI コールバック（`send_sound_event`）を呼び出す処理を実装。
3. **ステップ 3: Dart 側 `SoundManager` の作成**:
   - Dart 側で `SoundManager` クラスを作成し、`soundpool` や `audioplayers` の初期化とアセットの事前ロード（プリロード）を行う。
   - FFI イベントを受信した際に `SoundManager.playSound(event)` を呼び出す。
4. **ステップ 4: 設定UIとの連動**:
   - ドロワーや設定画面から効果音（SE）およびBGMのON/OFF、音量調整（0〜100%）を行えるように `iflags.sounds` と Dart 側プレイヤーの音量を同期。

---

## 6. まとめ

NetHack 5.0 の Cコアには、極めて整理された `soundlib` インターフェースが既に存在しており、コアコード側で `Soundeffect()` 等のマクロが適切なタイミングで呼び出されています。

DartHack では、Cコアの修正を最小限に抑えつつ、`winflutter.c` 内で `fluttersound_procs` を実装して Dart (Flutter) へイベントをブリッジし、Flutter 側の低遅延オーディオエンジンで再生する構成が**最も拡張性が高く、保守性に優れている**と考えられます。
