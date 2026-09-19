# NetHack 5.0 / DartHack サウンドキュレーター (Sound Curator)

本ツールは、『[sound_macros_list.md](../../doc/sound_macros_list.md)』、『[combat_sound_specification.md](../../doc/combat_sound_specification.md)』、および『[ambience_specs.md](../../doc/ambience_specs.md)』に定義されている **全 388 種類の効果音・戦闘アクション音・BGM/環境音・実績音・楽器演奏音・声音** を、効率よく・高品質かつ狙い通りに収集・選定・正規化・管理するためのローカルWebワークスペースです。

---

## 主な機能と特徴

1. **進捗ダッシュボード & カテゴリフィルタ**:
   - 全388音の収集進捗率（パーセンテージ）をリアルタイム表示。
   - 「未設定のみ」「確定済のみ」「🎵 BGM(72)」「⚔️ 戦闘(33)」「効果音(203)」「実績(23)」「楽器(47)」「声音(7)」による瞬時絞り込み。
   - サウンドIDや日本語説明文、推奨検索キーワードによるインクリメンタル検索。
2. **🎵 BGM・環境音（72種）特化キュレーション & ダンジョンシンセ/TRPG音源連携**:
   - **3つのサブカテゴリ絞り込み**: 「🏛️ フロアBGM (32)」「🚪 ルームBGM (35)」「🌊 環境音 (5)」に瞬時に切り替え可能。
   - **ダンジョンシンセ・ファンタジーTRPG特化の日英検索キーワード**: 各階層（大迷宮、ノーム鉱山、ゲヘナ、精霊界、アストラル界）や部屋（王座、寺院、闇市、ニンフの園、氷の部屋）の雰囲気に合わせた特化キーワードを全72曲に定義。
   - **BGM特化の国内外9サイト ワンクリック外部検索**:
     - 🌐 **itch.io**: ダンジョンシンセ・インディーゲーム向け音楽アセット（CC0 / CC-BY）
     - 🌐 **OpenGameArt.org**: オープンソースRPG・ファンタジーBGM（CC0 / CC-BY）
     - 🌐 **Free Music Archive (FMA)**: 世界的CC音楽アーカイブ（Dungeon Synth / Dark Ambient）
     - 🌐 **Incompetech**: Kevin MacLeod氏によるTRPG/D&D定番BGM（CC BY）
     - 🌐 **Pixabay Music**: 高品質ファンタジー・アンビエント（商用フリー・クレジット不要）
     - 🌐 **Freesound.org**: ダンジョン環境音・アンビエントループ（CC0 / CC-BY）
     - 🇯🇵 **甘茶の音楽工房**: 中世・ファンタジー・ダンジョン向けフリーBGM
     - 🇯🇵 **魔王魂**: RPGダンジョン・戦闘・イベント向けフリーBGM
     - 🇯🇵 **PeriTune**: ファンタジー・民族・アンビエント特化フリーBGM
   - **BGM専用の自動オーディオプロファイル**:
     - **ステレオ 2ch**（空間の広がりと音像定位を保持）
     - **96kbps Opus (48kHz)**（高音質かつ軽量）
     - **-18.0 LUFS**（SEの -14.0 LUFS より控えめで長時間の探索でも疲れないバランス、True Peak -1.5 dBFS）
     - **ソフト先頭無音処理**（-60dB閾値でイントロの微弱なフェードインやパッド音を切り落とさず保持）
3. **⚔️ 戦闘アクション効果音（33種）特化キュレーション & 自動音響処理**:
   - **4つのサブカテゴリ絞り込み**: 「🗡️ 近接攻撃 (12)」「🏹 遠隔・投擲 (7)」「✨ 魔法攻撃 (2)」「🐾 モンスター固有 (12)」に瞬時に切り替え可能。
   - **特化検索キーワード**: 全33音それぞれに割り当てられた日英特化キーワード（「斬撃 剣」「打撃 鈍器」「鞭 ムチ」「鉄球 鎖」「盾 バッシュ」「死体 肉塊」「つるはし 採掘」「杖 ロッド」「汎用 打撃」「弓 矢」「モンスター 爪」等）により、13の音源サイトで的確な検索結果を即座に表示。
   - **『combat_sound_specification.md』第7章準拠の自動オーディオプロファイル**:
     - **-16.0 LUFS**（高頻度で連打される戦闘SE向けに、通常SEの-14 LUFSよりわずかに控えめにして耳の疲労を防止）
     - **80Hz ハイパスフィルター**（小型スマートフォンやタブレットのスピーカーで低音による音割れ・クリッピングを完全防止）
     - **先頭無音ゼロトリム**（攻撃アニメーション・ログと完全に同期する即時発音）
4. **ワンクリック外部検索支援（効果音13サイト / BGM 9サイト動的切り替え）**:
   - カードのカテゴリに応じて最適な外部音源サイトの検索バッジが自動展開されます。
5. **ドラッグ＆ドロップによる即時登録 & 自動正規化 (ffmpeg)**:
   - ダウンロードした音声ファイル（WAV, MP3, OGG, FLAC等）を該当カードにドラッグ＆ドロップするだけで即時取り込み。
   - モーダルで出典（サイト名、作者、URL、ライセンス）を入力して「確定」を押すと、バックグラウンドで `ffmpeg` が自動実行されます。
   - 出力先: `DartHack_private/sys/flutter/assets/sounds/<filename>.ogg`（存在時。非存在時は `sys/flutter/assets/sounds/`）
6. **楽器音 47 種の完全自動サンプリング**:
   - オープンSoundFont（FluidR3 GM）と FluidSynth を用いて、木製フルート・角笛・ラッパ・ハープ等のA〜G音階（計47ファイル）を正確なピッチと音色で一括自動生成済み。
7. **ライセンス一覧（`attributions.txt`）の自動生成**:
   - 採否と同時に `DartHack_private/sys/flutter/assets/sounds/attributions.txt` に作者、出典URL、ライセンス条件が本家フォーマット準拠で自動記録・更新されます。

---

## 起動方法

### 方法 A: 🎵 BGM・環境音キュレーター（BGM 72音に特化）
```powershell
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/run_bgm_curator.ps1
```
サーバーが立ち上がり、既定のブラウザでBGMカテゴリに絞り込んだ画面（`http://localhost:8765/?category=bgm`）が自動的に開きます。

### 方法 B: ⚔️ 戦闘アクション効果音キュレーター（戦闘33音に特化）
```powershell
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/run_combat_curator.ps1
```
サーバーが立ち上がり、既定のブラウザで戦闘カテゴリに絞り込んだ画面（`http://localhost:8765/?category=combat`）が自動的に開きます。

### 方法 C: 🎮 総合サウンドキュレーター（全388音）
```powershell
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/run_curator.ps1
```
サーバーが立ち上がり、既定のブラウザで `http://localhost:8765` が自動的に開きます。

### 方法 D: 手動起動
```powershell
python sys/flutter/tools/sound_curator/server.py
```
ブラウザで `http://localhost:8765` にアクセスしてください。

---

## 推奨キュレーションワークフロー

1. `run_bgm_curator.ps1`（または `run_combat_curator.ps1`, `run_curator.ps1`）を実行してブラウザで画面を開く。
2. 上部の **「⏳ 未設定のみ」** フィルタをクリック。
3. （BGMの場合）「🏛️ フロアBGM」「🚪 ルームBGM」「🌊 環境音」サブカテゴリを選択。
4. 収集したい曲カードのボタン（例: **［itch.io］**、**［FMA］**、**［甘茶の音楽工房］**、**［PeriTune］** 等）をクリック（推奨キーワードで即座に検索されます）。
5. ブラウザで目的の音源（WAVやMP3）をダウンロード。
6. ダウンロードしたファイルをカードの「📥 ドロップゾーン」にドラッグ＆ドロップ。
7. モーダルで「出典サイト」「作者」「URL」「ライセンス」を確認し、**「正規化 & 確定 (Opus変換)」** ボタンをクリック。
8. 自動的にBGMオーディオプロファイル（ステレオ 2ch / 96kbps / -18.0 LUFS / ソフト先頭無音処理）が適用されて Opus 変換され、試聴プレイヤーで仕上がりを確認できます。

---

## 🔊 音量バランス検査 & 自動適正化ツール (check_volumes)

全音源の音量・音圧が均一で揃っているかを瞬時に診断し、過小音量や頭打ち（0dBクリッピング）を自動適正化できます。

### 1. Web UI（サウンドキュレーター）からのワンクリック操作
1. キュレーター画面上部のヘッダーにある **［🔊 音量診断］** ボタンをクリック。
2. 全音源のピーク音量（`max_volume`）、実効音量（`mean_volume`）、再生時間が一括スキャンされ、各カード内に測定バッジ（`[OK]`, `[WARN]`, `[ERROR]`, `[CLIP]`）が表示されます。
3. 問題のある音源は **［🔧 適正化 (Fix)］** ボタンで個別修復できるほか、ヘッダーに現れる **［⚠️ 要修正音源を一括適正化］** ボタンで全自動修復（無音トリム＋コンプレッション＋ピーク -1.5 dBFS 正規化）が可能です。

### 2. コマンドライン（CLI）からの実行

#### PowerShell ラッパー経由:
```powershell
# 全音源の音量レポートを表示
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1

# 問題（WARN/ERROR/CLIP）のある音源のみ表示
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -WarnOnly

# 問題のある音源を一括自動修復（ピーク -1.5 dBFS にリノーマライズ）
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -Fix

# 特定のファイルのみ検査・修復
powershell -ExecutionPolicy Bypass -File sys/flutter/tools/sound_curator/check_volumes.ps1 -Target se_combat_hit_pick.ogg -Fix
```

#### Python 直接実行:
```powershell
python sys/flutter/tools/sound_curator/check_volumes.py --warn-only
python sys/flutter/tools/sound_curator/check_volumes.py --fix
python sys/flutter/tools/sound_curator/check_volumes.py --target se_combat_hit_corpse.ogg --fix
```

### 3. 判定基準と適正化ルール (ルール38準拠)
- **OK**: ピーク `-0.5 〜 -4.0 dBFS`、平均 `-14.0 〜 -24.0 dBFS`（最適バランス）
- **CLIP**: ピーク `0.0 dBFS`（0dB頭打ち、音割れリスク）
- **WARN**: ピーク `< -5.0 dBFS` または 平均 `< -25.0 dBFS`（過小音量）
- **ERROR**: ピーク `< -12.0 dBFS` または 平均 `< -35.0 dBFS`（ほぼ無音・不良音源）
- **自動適正化内容**: `silenceremove`（不要無音カット）＋ `acompressor`（軽度のアタック・リリース補正）＋ `volume`（ピーク -1.5 dBFS リノーマライズ）。短音に対する `loudnorm` 単独適用の誤作動を恒久防止。
