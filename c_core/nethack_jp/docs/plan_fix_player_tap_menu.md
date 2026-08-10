<!-- Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-10. -->
# 計画: Flutter 版における主人公タップ時の「ここで使えるコマンド」メニュー表示対応

## 1. 背景・目的

### 1.1 問題の概要
Flutter 版（`sys/nethack_flutter/`）の実機デバッグにおいて、主人公キャラクター（`@`）をタップしても何も表示されない。
Java 版（`sys/android/ForkFront-Android/`）では、タップによりその場で実行可能なアクション一覧（日本語メニュー）がダイアログで表示される。

### 1.2 ログから読み取れること
ユーザーが提示したログ：

```
D/NetHackFlutter(18409): flutter_nhgetch called. Waiting for key...
D/NetHackFlutter(18409): C core received key: 35     ← '#'
D/NetHackFlutter(18409): C core received key: 104    ← 'h'
D/NetHackFlutter(18409): C core received key: 101    ← 'e'
D/NetHackFlutter(18409): C core received key: 114    ← 'r'
D/NetHackFlutter(18409): C core received key: 101    ← 'e'
D/NetHackFlutter(18409): C core received key: 99     ← 'c'
D/NetHackFlutter(18409): C core received key: 109    ← 'm'
D/NetHackFlutter(18409): C core received key: 100    ← 'd'
D/NetHackFlutter(18409): C core received key: 109    ← 'm'
D/NetHackFlutter(18409): C core received key: 101    ← 'e'
D/NetHackFlutter(18409): C core received key: 110    ← 'n'
D/NetHackFlutter(18409): C core received key: 117    ← 'u'  (拡張コマンド補完の最後の1文字)
D/NetHackFlutter(18409): flutter_nhgetch returning key: 117
D/NetHackFlutter(18409): flutter_clear_nhwindow win=10
D/NetHackFlutter(18409): flutter_display_nhwindow win=12, block=0
D/NetHackFlutter(18409): flutter_display_nhwindow win=12, block=0
D/NetHackFlutter(18409): flutter_nhgetch called. Waiting for key...
```

- ASCII コードを綴ると `#herecmdmenu`（正しい拡張コマンド名）。
- `'\n'` (10) は観測されていないが、これは前のターンで送信済みか、またはフィルターされている可能性がある。
- 直後の `flutter_clear_nhwindow win=10` と `flutter_display_nhwindow win=12, block=0` は、マップ再描画を意味する。
- **メニューオーバーレイ生成の痕跡（`flutter_select_menu` → Dart 側 `_buildMenuOverlay`）がログにない**。`debuglog` の出力選定による取りこぼしか、または実際にダイアログが立ち上がっていない可能性の両方がある。

### 1.3 目的
Java 版と同等、もしくはそれに近い「主人公タイルタップ時に現在地で実行可能なアクション一覧ダイアログを表示する」機能を Flutter 版で実現する。`#herecmdmenu` 拡張コマンドを起点とした C コア主導のメニュー生成フローをそのまま活用する。

## 2. 現状の整理

### 2.1 既に実装されている要素（Flutter 版）
| 要素 | 場所 | 状態 |
|---|---|---|
| 主人公タイルタップ検出 | `sys/nethack_flutter/lib/main.dart:1304-1320` `_handleMapTap` | 実装済 |
| 拡張コマンド送信（1文字 + LF） | `main.dart:1261-1278` `_sendExtendedCommand` | 実装済 |
| 拡張コマンド受信ループ | `sys/nethack_flutter/android/app/src/main/cpp/winflutter.c:833-849` `flutter_nhgetch` | 実装済 |
| `cliparound` 経由の主人公位置通知 | `winflutter.c:748-758` `flutter_cliparound` → `nethack_ffi.dart:35` `CliparoundCallback` | 実装済 |
| Dart 側での主人公位置保持 | `sys/nethack_flutter/lib/nethack_screen.dart:92-97, 171-181` `setPlayerPos` | 実装済 |
| メニューコールバック受信 | `nethack_worker.dart:42-45, 136-182` `startMenuCallable` 等 | 実装済 |
| メニュー項目蓄積 | `nethack_screen.dart:251-292` `startMenu`/`addMenu`/`endMenu`/`selectMenu` | 実装済 |
| メニューオーバーレイ表示 | `main.dart:1405-1644` `_buildMenuOverlay`、`main.dart:2231-2232` 呼び出し | 実装済 |
| メニュー選択→C コア送信 | `main.dart:1322-1336` `_sendMenuSelection` | 実装済 |
| C コア `herecmdmenu` 定義 | `src/cmd.c:1741-1742` 拡張コマンドテーブル | 実装済 |
| C コア `doherecmdmenu` 実装 | `src/cmd.c:4341-4348` → `here_cmd_menu` → `there_cmd_menu` | 実装済 |
| C コア `there_cmd_menu_self` メニュー項目生成 | `src/cmd.c:4447-4543` | 実装済（メニュー項目は日本語で既に定義済） |

### 2.2 Flutter 版で欠落している／不完全な要素（Java 版との比較）
| 要素 | Java 版での実装 | Flutter 版での状況 | 影響 |
|---|---|---|---|
| 隣接タイルタップで `therecmdmenu` | `NHW_Map.java:1291-1321` で `SEND_POS` 分岐 | `_handleMapTap` が `dx==0 && dy==0` のみ対応し、それ以外を完全無視 | 扉・宝箱などへの「開ける/蹴る/検索」メニューが立ち上がらない |
| 長押し検出 | `NHW_Map.java:1042` `CountDownTimer` | `GestureDetector.onTapUp` のみ | 自動移動 (`g` + 方向) 等の長押し系機能がない |
| 主人公周辺の半径判定 (`mSelfRadius`) | `NHW_Map.java:30, 1328, 1383` 25dp 半径 | タイル座標の完全一致のみ | 指ズレで自キャラタップ判定に失敗しやすい |
| C コアへの `PosCmd(x, y)` 送信 | `NetHackIO.java:272-277` `sendPosCmd` | FFI 関数 `SendPosCmd` 系が**未実装** | 隣接タイルクリックがそもそも C コアに届かない |
| 方向入力要求中のマップタップ→方向決定 | `NHW_Map.java:1305-1320, 1380-1381` | 未対応 | 「What direction?」プロンプト時にマップタップが使えない |
| トラベル自動移動 | `NHW_Map.java:1386-1410` | 未対応 | 遠方タップで travel しない |
| `setExtMenuOption(false)` 相当の制御 | `Cmd.java:179-233` `#` 送信中だけ拡張メニュー無効化 | なし。`_waitingForInput` フラグで代替しているが挙動の差異がある可能性 | 拡張コマンド送信中に候補メニューが二重表示する等の競合 |

### 2.3 Java 版タップ→メニュー表示の正常フロー（参考）
1. ユーザー：`@` タップ
2. `NHW_Map.UI.onTouched` (`NHW_Map.java:1267`) → 座標変換
3. `getTouchResult` (`NHW_Map.java:1375`) → `SEND_MY_POS` 判定
4. `NH_State.sendPosCmd(x, y)` → `NetHackIO.sendPosCmd` → `PosCmd` を C コアに送信
5. C コア `and_nh_poskey` (`winandroid.c:1657-1683`) → `click_to_cmd` (`src/cmd.c:4942-4950`) → `therecmdmenu` コマンドキュー
6. C コア `dotherecmdmenu` → `here_cmd_menu` → `there_cmd_menu(u.ux, u.uy, CLICK_1)`
7. C コア `there_cmd_menu_self` (`src/cmd.c:4447-4543`) でメニュー項目を生成
8. C コア `select_menu` → Java 側 `NHW_Menu.selectMenu` → ダイアログ表示
9. ユーザーが項目タップ → `NetHackIO.sendSelectCmd` → C コア `act_on_act` でコマンド実行

## 3. 仮説（バグの原因候補）

### 仮説 A: `_waitingForInput=false` の瞬間に `_sendExtendedCommand` がスキップされている
- `main.dart:1261-1262` のガード `if (!_waitingForInput) return;`
- マップタップ発生時点で C コアが `nhgetch` 待ちでない瞬間があると、コマンドが捨てられる
- 検証：ログに `C core received key: 35` 以降が出ている時点で、C コアは受信しているので、別の経路で破棄されている可能性

### 仮説 B: 主人公位置が `setPlayerPos` で更新されていない／座標系の不一致
- `playerX, playerY` が `-1` のまま、もしくは 1-based/0-based 不一致で `_handleMapTap` の `dx==0 && dy==0` が成立しない
- 検証：`setPlayerPos` の呼び出しログ／`_screen.playerX` の値をログ出力

### 仮説 C: メニュー受信後の Dart 側 `_buildMenuOverlay` が描画されない
- `selectMenu` 通知は来ているが、何らかの理由で再描画が走らない／`_isMenuWindowVisible=true` にならない
- 検証：`selectMenu` 受信箇所のデバッグログ

### 仮説 D: メニューは描画されているが `Stack` の順序で見えない／サイズが 0
- `main.dart:2231-2232` の位置、Overlay の z-order、`Container` の `color: Colors.black.withValues(alpha: 0.92)` の背景だけ見えて内容が見えない等
- 検証：固定カラーで `Container.color` を `red` にするなど

### 仮説 E: メニュー項目がすべて `ident=0` で、表示はされるがタップしても何も起こらない
- `there_cmd_menu_self` が出力するメニュー項目の `a_int` (ident) が 0 の可能性
- 検証：`_screen.menuItems` の中身をログ

### 仮説 F: C コア側で `select_menu` 呼び出しが即座にタイムアウト／キャンセルされている
- `flutter_select_menu` (`winflutter.c` 該当箇所) の Dart 側応答待ちが失敗
- 検証：`flutter_select_menu` の入口・出口ログ

### 仮説 G: 拡張コマンド補完が失敗し `#herecmdmenu` ではなく別コマンド（`#herecdmenu` 等のタイポ）が補完されている
- ログから送信文字列は `#herecmdmenu` に見えるので可能性は低いが、念のため確認
- 検証：送信ログの完全文字列出力

## 4. 作業分割

> フェーズ 1（調査）で原因を特定し、フェーズ 2（実装）で修正する。フェーズ 3（検証）で実機確認する。

### フェーズ 1: 詳細調査・再現（まずログで挙動を確定）

#### 1-A: ログ追加
タップからメニュー表示までの各ステップにデバッグログを差し込む。

- `main.dart:1304-1320` `_handleMapTap` 入口／出口に `_addLog` を追加
  - `tileX, tileY, playerX, playerY, dx, dy, isMainTile`
- `main.dart:1261-1278` `_sendExtendedCommand` 入口に送信文字列を `_addLog`
- `main.dart:1322-1336` `_sendMenuSelection` 入口に ident を `_addLog`
- `nethack_screen.dart:251-292` `startMenu`/`addMenu`/`endMenu`/`selectMenu` それぞれに `MenuItemData` 件数・プロンプト・winId をログ出力
- `nethack_screen.dart:171-181` `setPlayerPos` に受け取った x, y をログ出力
- `winflutter.c:678-700` `flutter_clear_nhwindow` / `flutter_display_nhwindow` 入口に winId, type ログ
- `winflutter.c` `flutter_select_menu` 入口に wid, how, 出口に npick ログ

#### 1-B: 想定される仮説の検証
- **仮説 B**: `_handleMapTap` ログで `playerX, playerY` が `-1` や巨大値になっていないか確認
- **仮説 C/E**: `selectMenu` ログで `_screen.menuItems` の件数、`addMenu` ログで ident 値を確認
- **仮説 D**: 開発モードで `Container.color` を `red` に一時変更し、可視化確認
- **仮説 F**: `flutter_select_menu` の入口・出口ログで C コアが `select_menu` に入ったか確認

#### 1-C: 実機での再現ログ取得
- 上記ログを入れた状態で、主人公タイルをタップ
- ログ全文を取得
- 仮説のうちどれが該当するか分析

#### 1-D: 該当箇所の特定
- ログから問題箇所を 1 ヶ所に絞り込む
- 仮説が複数該当する場合は優先度の高いものから対応

### フェーズ 2: 修正実装

#### 2-A: メイン修正（仮説ごとに分岐）

##### ケース A/B: 主人公タップ検出が失敗している場合
- `main.dart:1282-1300` `_mapLocalToTile` の座標変換を再確認
- 主人公位置の更新フロー（`cliparound` 受信 → `setPlayerPos` → `_screen.playerX/Y`）をトレース
- 座標系の 0-based/1-based 混同がないか確認（C 側は `(int)u.ux - 1, (int)u.uy` で 0-based 送信）

##### ケース C/E: `_buildMenuOverlay` が表示されない／ident=0
- `main.dart:960-971` `selectMenu` 受信の `setState` を確認
- `nethack_screen.dart:287-292` `selectMenu` メソッドで `_isMenuWindowVisible = true` が確実に代入されるか確認
- `main.dart:2231-2232` の `if (_screen.isMenuWindowVisible) _buildMenuOverlay()` の `Stack` 内位置を確認
- `main.dart:1405-1644` `_buildMenuOverlay` の `_screen.menuItems` が空でないか確認
- `main.dart:1504, 1594` の `isSelectable` 判定でヘッダー以外がタップ可能か確認

##### ケース D: レイアウト／可視性
- `Stack` の `Positioned.fill` が見えているか
- `Container.color: Colors.black.withValues(alpha: 0.92)` が全面を覆っているか
- `Scaffold` の `body` 内か `floatingActionButton` かなど、Z-order を確認

##### ケース F: C コア側 `select_menu` の即時終了
- `winflutter.c` の `flutter_select_menu` で Dart 側応答待ちが正常か
- `g_input_request_id` / `g_dart_notify_input_cb` の発火を確認
- 必要なら `flutter_select_menu` のデバッグログ追加

#### 2-B: 追加改善（メイン修正のついでに可能なら）
- 半径判定の導入（`mSelfRadius` 相当）: `main.dart:1317` の `dx==0 && dy==0` を `dx*dx + dy*dy <= radius*radius` 形式に
- 隣接タイルタップで `therecmdmenu` を送る（SEND_POS 相当）
- 拡張コマンド送信中の競合防止: `setExtMenuOption(false)` 相当のフラグ管理
- `LongPress` 検出の追加

#### 2-C: ログのクリーンアップ
- 1-A で追加したデバッグログは、解決後に必ず削除（AGENTS.md 方針 6 に従う）
- 残すログは `flutter_nhgetch called/returning`、`flutter_clear_nhwindow`、`flutter_display_nhwindow` の既存ログのみ

### フェーズ 3: 検証

#### 3-A: ビルド確認
- コマンド: `.\sys\windows\vs\build_one.bat` (Windows 環境) または `& .\sys\android\build_android.ps1` (Android WSL 環境)
- 既存ログ以外のデバッグログが残っていないか `git diff` で確認

#### 3-B: 実機テスト
- 新規ゲーム開始 → ダンジョンに降りる → 主人公をタップ
- 期待結果：「何をしますか?」タイトル＋メニュー項目リストが画面に表示される
- メニュー項目タップ → 期待される動作（拾う、祈る、休息、etc.）
- 扉や宝箱がある隣接タイルタップ → 「ここでは〜」のメニューが立ち上がる（追加改善した場合）

#### 3-C: 既存機能への影響確認
- 拡張コマンドメニュー（`#` → 検索 → 実行）が従来通り動作するか
- 他の特殊ウィンドウ（テキスト表示、インベントリ等）が従来通り動作するか
- 方向入力 D-Pad／キーボード操作が従来通り動作するか

## 5. 関連ファイル一覧

### Flutter 版
- `sys/nethack_flutter/lib/main.dart`
  - `1261-1278` `_sendExtendedCommand`
  - `1282-1300` `_mapLocalToTile`
  - `1304-1320` `_handleMapTap`
  - `1322-1336` `_sendMenuSelection`
  - `1338-1352` `_sendMenuSelections`
  - `938-971` メニュー関連メッセージ受信
  - `1405-1644` `_buildMenuOverlay`
  - `2231-2232` メニューオーバーレイ呼び出し
- `sys/nethack_flutter/lib/nethack_screen.dart`
  - `19-37` `MenuItemData`
  - `41-45` ウィンドウタイプ定数
  - `74-83` メニュー状態フィールド
  - `92-97, 171-181` `setPlayerPos` / 主人公位置
  - `251-292` `startMenu`/`addMenu`/`endMenu`/`selectMenu`
- `sys/nethack_flutter/lib/nethack_worker.dart`
  - `42-45, 136-182` メニュー関連 callback listener
  - `243-263` `ffi.registerCallbacks`
  - `273-282` メニュー選択の Dart→C 送信
- `sys/nethack_flutter/lib/nethack_ffi.dart`
  - `15-27` メニュー関連 typedef
  - `35` `CliparoundCallback`
  - `88-92, 146-152` メニュー送信 FFI

### C コア (Flutter Port)
- `sys/nethack_flutter/android/app/src/main/cpp/winflutter.c`
  - `55-73` コールバック関数ポインタ型
  - `75-92` コールバックグローバル変数
  - `196-235` `RegisterFlutterCallbacks`
  - `362-366` `SendKeyToFlutter`
  - `369-378` `SendMenuSelection` 実装
  - `667-676` `flutter_create_nhwindow` (`g_next_win_id = 10` 開始)
  - `678-700` `flutter_clear_nhwindow` / `flutter_display_nhwindow`
  - `748-758` `flutter_cliparound` (0-based 変換)
  - `833-849` `flutter_nhgetch`
  - `1039-1100` `flutter_do_ext_cmd_menu`
  - `1102-1105` `flutter_get_ext_cmd`
  - `1108-1157` `HijackWindowProcs`
  - `1160-1287` `flutter_status_update`

### C コア (共通)
- `src/cmd.c`
  - `1741-1742` `herecmdmenu` 拡張コマンド定義
  - `1903-1905` `therecmdmenu` 拡張コマンド定義
  - `2065-2066` `clicklook` / `mouseaction` INTERNALCMD
  - `2620-2654` `bind_mousebtn`
  - `2764-2765` `commands_init` 内 `bind_mousebtn(1, "therecmdmenu")`
  - `4341-4348` `doherecmdmenu`
  - `4350-4384` `dotherecmdmenu`
  - `4447-4543` `there_cmd_menu_self` (メニュー項目生成)
  - `4879-4933` `there_cmd_menu`
  - `4936-4940` `here_cmd_menu`
  - `4942-4950` `click_to_cmd`
  - `5298-5302` `nh_poskey` 戻り値 0 → `click_to_cmd`
- `include/wintype.h`
  - `121-127` NHW_* ウィンドウタイプ定数

### Java 版（参考）
- `sys/android/ForkFront-Android/lib/src/com/tbd/forkfront/NHW_Map.java`
  - `30` `SELF_RADIUS_FACTOR = 25`
  - `85-90` `TouchResult` enum
  - `99-100, 165-166` `mSelfRadius` / `mSelfRadiusSquared`
  - `230-237` `cliparound`
  - `289-299` `onCursorPosClicked`
  - `1020-1124` `onTouchEvent`
  - `1042-1051` 長押し検出
  - `1267-1323` `onTouched`
  - `1375-1411` `getTouchResult`
  - `1414-1467` `handleKeyDown` / `handleKeyUp`
- `sys/android/ForkFront-Android/lib/src/com/tbd/forkfront/NH_State.java`
  - `415-419` `sendPosCmd`
  - `421-425` `clickCursorPos`
- `sys/android/ForkFront-Android/lib/src/com/tbd/forkfront/NetHackIO.java`
  - `71-91` `PosCmd` / `KeyCmd`
  - `259-263` `sendKeyCmd`
  - `266-270` `sendDirKeyCmd`
  - `272-277` `sendPosCmd`
  - `286-307` `sendSelectCmd`
  - `407-438` `receivePosKeyCmd`
  - `733-750` `selectMenu` (JNI)
- `sys/android/winandroid.c`
  - `1657-1683` `and_nh_poskey`
  - `1811-1830` 「What direction?」処理

## 6. 重要コード抜粋

### 6.1 主人公タップ→拡張コマンド送信 (Flutter 既存実装)
`sys/nethack_flutter/lib/main.dart:1304-1320`
```dart
void _handleMapTap(TapUpDetails details) {
  if (!_isMainGameStarted) return;
  final px = _screen.playerX;
  final py = _screen.playerY;
  if (px < 0 || py < 0) return;

  final tile = _mapLocalToTile(details.localPosition);
  if (tile == null) return;

  final dx = tile.tileX - px;
  final dy = tile.tileY - py;
  if (dx == 0 && dy == 0) {
    _sendExtendedCommand('#herecmdmenu');
  }
}
```

`sys/nethack_flutter/lib/main.dart:1261-1278`
```dart
void _sendExtendedCommand(String cmd) {
  if (!_waitingForInput) return;
  if (_screen.isMenuWindowVisible) return;
  if (_screen.isTextWindowVisible) return;
  if (_isYnVisible) return;
  if (_isGetLineVisible) return;
  if (_isAskNameVisible) return;

  _addLog("> Send Extended Command: '$cmd'");
  for (int i = 0; i < cmd.length; i++) {
    final isLast = (i == cmd.length - 1);
    _sendFfiKey(cmd.codeUnitAt(i), cmd[i], keepWaiting: !isLast);
  }
  _sendFfiKey(10, '${cmd}\n', keepWaiting: true);
}
```

### 6.2 メニュー項目生成 (C コア、メニュー内容の正体)
`src/cmd.c:4447-4543` `there_cmd_menu_self` 内で `mcmd_addmenu` により以下を動的追加（既に日本語化済）:

| メニュー項目 | enum | 発動条件 |
|---|---|---|
| 「%sから飲む」 | `MCMD_QUAFF` | 足元が泉/シンク |
| 「何かを泉に浸す」 | `MCMD_DIP` | 足元が泉 |
| 「玉座に座る」 | `MCMD_SIT` | 足元が玉座 |
| 「何かを祭壇に捧げる」 | `MCMD_OFFER` | 足元が祭壇 |
| 「階段を上る/下りる」「はしごを上る/下りる」 | `MCMD_UP`/`MCMD_DOWN` | 足元が階段/はしご |
| 「%sから降りる」 | `MCMD_DISMOUNT` | 騎乗中 |
| 「%sを拾う/あさる/傾ける/食べる」 | `MCMD_PICKUP`/`MCMD_LOOT`/`MCMD_TIP`/`MCMD_EAT` | 足元にアイテム |
| 「持ち物を見る」「物品を落とす」 | `MCMD_INVENTORY`/`MCMD_DROP` | 常に表示 |
| 「1ターン休む」「周囲を探す」「ここにあるものを見る」「ここで祈る」「ここに文字を彫る」「能力値を見る」「最近のメッセージを見る」 | `MCMD_REST`/`MCMD_SEARCH`/`MCMD_LOOK_HERE`/`MCMD_PRAY`/`MCMD_ENGRAVE`/`MCMD_ATTRIBUTES`/`MCMD_PREVIOUS_MESSAGES` | 常に表示 |
| 「呪文を唱える」 | `MCMD_CAST_SPELL` | 呪文を知っている |
| 「罠を解除しようとする」 | `MCMD_UNTRAP_HERE` | 足元に罠 |
| 「跳ぶ」 | `MCMD_JUMP` | Jumping モード時 |

## 7. 想定スケジュール
- フェーズ 1（調査）: 1〜2 セッション
- フェーズ 2（修正）: 1〜2 セッション
- フェーズ 3（検証）: 0.5〜1 セッション

## 8. リスク・留意事項
1. **デバッグログの残存**: AGENTS.md 方針 6 により、解決後は必ずデバッグ用ログを削除
2. **セーブデータ互換性**: `#herecmdmenu` 拡張コマンド自体は既存定義をそのまま使うので互換性影響なし
3. **既存操作への影響**: 主人公タップ以外の操作（拡張コマンドメニュー、テキストウィンドウ、YN プロンプト等）に副作用が出ないか必ず検証
4. **メニュー項目のフォント／はみ出し**: メニューオーバーレイで長い項目名（"%sから飲む" 等）が画面幅を超える場合、FittedBox による縮小が必要（AGENTS.md 方針「はみ出し防止」に従う）
5. **権限・設定変更**: 拡張コマンド送信中の `setExtMenuOption(false)` 相当処理を入れる場合、ユーザー設定（extmenu）に影響する

## 9. 完了基準 (DoD)
- [ ] 主人公タイルタップで「何をしますか?」メニューが画面に表示される
- [ ] メニュー項目をタップすると対応するアクション（拾う、祈る、休息、etc.）が実行される
- [ ] 扉/宝箱など隣接タイルタップで「ここでは〜」のメニューが立ち上がる（追加改善した場合）
- [ ] 既存機能（拡張コマンドメニュー、YN、テキストウィンドウ、方向入力等）が正常動作
- [ ] デバッグログが残っていない
- [ ] ビルドが `.\sys\windows\vs\build_one.bat`（または `& .\sys\android\build_android.ps1`）で成功
- [ ] 修正がコミットされ、PR が作成されている
