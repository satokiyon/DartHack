# マップタップにおけるターゲット選択中判定（`endsWith("?")`）の課題と設計改善案

## 1. 現状の実装と課題

### 1.1 現状の実装 (`sys/flutter/lib/main.dart`)
```dart
// farlookモード (/) や ; コマンド、ターゲット選択（getpos等）入力待ち中の判定
// toplineプロンプト、またはメッセージ末尾が?で終わる場合はターゲット選択中とみなす
final bool isGetposOrTargetingMode = _screen.topline != null ||
    (_screen.messages.isNotEmpty && _screen.messages.last.trim().endsWith("?"));

if (isGetposOrTargetingMode) {
  sendPosCmd(tile.tileX, tile.tileY, 1 /* CLICK_1 */);
  return;
}
```

### 1.2 脆弱性と潜在的バグ
1. **通常メッセージ末尾の「?」による誤爆**:
   - 会話やログ、状態メッセージなどの末尾が「?」で終わる通常のメッセージ（例: `「本当にドアを蹴りますか?」`、`「〜ですか?」`、モンスターとの会話テキスト等）が表示された直後、プレイヤーが通常のダンジョン探索としてマップをタップした場合、まだ質問プロンプトや getpos 中でないにもかかわらず `isGetposOrTargetingMode = true` と誤判定される。
   - その結果、即時移動モードを設定していてもタップがターゲット指定（`CLICK_1`）として処理され、意図した移動が発動しない、または予期せぬメニューが開く。
2. **メッセージ履歴の末尾参照依存**:
   - `_screen.messages.last` はメッセージログの最後の1行を参照しているため、ゲームの入力待ち状態（`program_state.input_state`）と画面に表示されているメッセージのライフサイクルが完全には同期していない。

---

## 2. 根本解決案

### 案A: Cコアの `program_state.input_state` 連動通知（推奨）
NetHack C コアは内部で入力状態を厳密に管理している：
- `program_state.input_state`:
  - `commandInp`: 通常コマンド入力待ち
  - `getposInp`: ターゲット位置選択中（`/`、`;`、遠隔呪文・投擲の getpos 等）
  - `ynInp`: y/n プロンプト中
  - `getlineInp`: 文字列入力中
- **対策**:
  1. `inputCallable`（または状態変更コールバック）で、C 側から現在の `input_state`（特に `is_getpos = (program_state.input_state == getposInp)`）を Dart 側にブール値または整数フラグとして通知する。
  2. Dart 側はメッセージ文字列の末尾「?」パースを全廃し、`_screen.isGetposActive` フラグのみを参照して判定する。

### 案B: C移植層での PosCmd 配送分岐
- Dart 側では常に単なるマップタップ座標 `PosCmd(x, y, mod)` を C コアへ送信する。
- C コア側の `flutter_nh_poskey` は既に C スレッドで動作しているため、`program_state.input_state == getposInp` のときは `mod` を強制的に `CLICK_1`（ターゲット座標）として渡し、通常探索時はユーザー設定の `mod`（スマート隣接や即時移動）として処理する。
- Dart 側からターゲット選択かどうかの判定処理自体を排除できるため、最も疎結合で堅牢なアーキテクチャとなる。
