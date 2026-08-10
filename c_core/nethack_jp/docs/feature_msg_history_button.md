<!--
  Feature Guide: 突然表示されるダイアログへのメッセージ履歴ボタン追加
  コミット: 3f56d3480 [Flutter] 突然表示されるダイアログにメッセージ履歴ボタンを追加
  関連 AGENTS.md セクション: 「Flutter 版におけるダイアログへのメッセージ履歴ボタン追加（実装ガイド）」
  最終更新: 2026-07-21
-->

# Flutter 版: 突然表示されるダイアログへのメッセージ履歴ボタン追加

## 1. 概要

Flutter 版 NetHackJP-Android（実体: `C:\Users\satok\DartHack\sys\flutter\`）のゲーム中に突然表示される 3 種類のオーバーレイダイアログに、**メッセージ履歴ボタン**を追加しました。押下すると既存のメッセージ履歴ボトムシート（`_showMsgHistoryPanel`）が開き、過去の最大 100 件のメッセージを遡って確認できます。

### 1.1 対応した要望

- 死亡時ダイアログにメッセージ履歴ダイアログを表示する機能が欲しい
- 「この○○に何と名前を付けますか?」の名前付けダイアログにメッセージ履歴ダイアログを表示する機能が欲しい

### 1.2 対応したオーバーレイ

| # | オーバーレイ種別 | ボタン表示条件 | コード位置 |
|---|---|---|---|
| 1 | **YN 確認オーバーレイ** (`_buildYnOverlay`) | 常時 | `sys/flutter/lib/main.dart:2252`、ボタン追加: `main.dart:2330`, `main.dart:2355` |
| 2 | **テキストウィンドウ・オーバーレイ**（墓石・結果表示・通常テキスト） | 常時 | ボタン追加: `main.dart:3395-3423` |
| 3 | **getline オーバーレイ** (`_buildGetLineOverlay`) | call/name 系のプロンプト時のみ | `sys/flutter/lib/main.dart:2368`、ボタン追加: `main.dart:2492-2517` |

### 1.3 デザイン判断（経緯）

設計段階で検討した 2 つの方式のうち、「**オーバーレイ側を直接編集**」する方式を採用しました。

| 方式 | 評価 | 採用 |
|---|---|---|
| **A+内部C**: 共通ラッパ関数を作って `showDialog` 13 箇所を包む | ラッパ自体の認知負荷・間接化・間接化によるデバッグ困難性が大きい | ✗ |
| **直接編集**: 既存オーバーレイ 3 箇所に直接ボタンを追加 | 変更点が見通しやすく、後からラッパ抽出も可能 | ✓ |

採用理由: 実際のダイアログ呼び出しは 12 個が `AlertDialog`、1 個が生 `Dialog` で散在しているが、その 95% は `Positioned.fill` ベースの「オーバーレイ」（`showDialog` 経由ではない）であり、死亡時のフローは 2 つのオーバーレイ（`_buildYnOverlay` + テキストウィンドウ・オーバーレイ）に集約されているため。

---

## 2. 実装内容

### 2.1 共通ヘルパー: `_buildMsgHistoryButton`（行 2944-2961）

```dart
// 履歴ボタン。YN/getline/テキストウィンドウ オーバーレイに共通で載せる。
// 押下で既存の _showMsgHistoryPanel() (ボトムシート) を開く。
// 視覚的に応答ボタンと区別するため、Amber 系のアウトラインで「補助操作」感を出す。
Widget _buildMsgHistoryButton({String label = '履歴'}) {
  return OutlinedButton.icon(
    onPressed: _showMsgHistoryPanel,
    icon: const Icon(Icons.history, size: 18, color: Colors.amber),
    label: Text(label, style: const TextStyle(color: Colors.amber)),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.amber,
      side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
```

**ポイント**:
- 引数 `label`（デフォルト `'履歴'`）でラベル変更可能。
- Amber のアウトラインで「応答ボタン」と視覚的に区別する。
- 押下時は既存の `_showMsgHistoryPanel()` を呼び出すだけ（既存資産を活用）。

### 2.2 プロンプト判別ヘルパー: `_isCallOrNamePrompt`（行 2972-2979）

```dart
// getline のプロンプトが「アイテム/階層に名前を付ける」系か判定する。
// 該当する場合のみ getline オーバーレイに履歴ボタンを表示する。
// 対応パターン (C 側 src/do_name.c, src/nhlua.c 由来):
//   "%sを何と呼びますか?" (docall / do_oname 経由の call)
//   "%s%sを何と名付けますか?" (do_oname 経由の name)
//   "この液体を何と呼びますか?" (流し台の药水)
//   "このダンジョン階層にどのような名前を付けますか?" (nhlua.c:693)
//   英語版: "What do you want to call/name this ___?" も念のため拾う。
// 銘刻/ウィッシュ/虐殺/拡張コマンドは除外。
bool _isCallOrNamePrompt(String prompt) {
  if (prompt.isEmpty) return false;
  return prompt.contains('何と呼びますか')
      || prompt.contains('何と名付けますか')
      || prompt.contains('名前を付け')
      || prompt.toLowerCase().contains('call this')
      || prompt.toLowerCase().contains('name this');
}
```

#### サポートするパターン

| C 側ソース | 日本語プロンプト例 | 用途 |
|---|---|---|
| `src/do_name.c:253` `docall` | `"%sを何と呼びますか?"` | アイテム命名 (call) |
| `src/do_name.c:305` `do_oname` | `"%s%sを何と名付けますか?"` | アイテム命名 (name) |
| `src/do_name.c:647` | `"この液体を何と呼びますか?"` | 流し台の药水 |
| `src/do_name.c:650` `build_docall_prompt` | `"%sを何と呼びますか?"` | docall プロンプト生成 |
| `src/nhlua.c:693` | `"このダンジョン階層にどのような名前を付けますか?"` | 階層命名 |

#### 意図的に除外しているプロンプト

| 用途 | 除外理由 |
|---|---|
| 銘刻（`engraving`） | 短い自由入力で、履歴参照の動機が薄い |
| ウィッシュ | 短文 |
| 虐殺（genocide） | 短文 |
| 拡張コマンド補完 | 補完候補を選ぶ用途で、履歴ボタンの UX ノイズになる |
| askname（"お名前は?"） | ゲーム開始時のみ出現するため |
| その他自由入力 | 同上 |

#### 英語版対応

- `"call this"`, `"name this"` の両方を `.toLowerCase()` 比較でフォールバック検出。
- 将来英語版に切替わった場合もそのまま動作する。

### 2.3 オーバーレイへの組み込み

#### (1) YN オーバーレイ: メイン行・キャンセル Wrap の末尾（行 2330, 2355）

```dart
// メイン Wrap
children: [
  // ... Yes, No, Quit ElevatedButton ...
  _buildMsgHistoryButton(),  // ← 追加（行 2330）
],

// キャンセル Wrap
children: [
  ...choices.map((ch) => ...),
  ElevatedButton(/* ESC */),
  _buildMsgHistoryButton(),  // ← 追加（行 2355）
],
```

#### (2) テキストウィンドウ・オーバーレイ: OK ボタンの左（行 3395-3423）

```dart
// 旧: Center(child: ElevatedButton(... OK ...))
// 新: Center(child: Row(children: [_buildMsgHistoryButton(), SizedBox(12), ElevatedButton(... OK ...)]))
Center(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _buildMsgHistoryButton(),         // ← 追加
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () => _sendFfiKey(32, "Space"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[500],
          // ...
        ),
        child: const Text("OK", /* ... */),
      ),
    ],
  ),
),
```

**常時表示する理由**: UX 一貫性のため。死亡時の墓石・結果表示だけでなく、`#overview` 等の通常テキストページでも「いままでのメッセージ何があったっけ?」が起きたときに同じボタンで確認できる。

#### (3) getline オーバーレイ: キャンセル/決定 Row の左（行 2492-2517）

```dart
// 旧: Row(children: [TextButton(キャンセル), ElevatedButton(決定)])
// 新: Row(spaceBetween, children: [if call/name: 履歴ボタン, Row(キャンセル, 決定)])
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 道具/階層への命名入力時のみ履歴ボタンを表示。
    // 銘刻/拡張コマンド/ウィッシュ/その他自由入力では出さない (UX ノイズ回避)。
    if (_isCallOrNamePrompt(_getlinePrompt))
      _buildMsgHistoryButton()
    else
      const SizedBox.shrink(),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: () => _sendGetLineResult(null), child: const Text('キャンセル')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => _sendGetLineResult(_getlineController.text), /* ... */),
      ],
    ),
  ],
),
```

**フィルタ必須の理由**: getline は多くの用途（銘刻、ウィッシュ、拡張コマンド、askname、その他自由入力）で使われるため、全部に履歴ボタンを出すと UX ノイズになる。

---

## 3. 既存資産（再実装不要）

### 3.1 `_showMsgHistoryPanel()`（行 2821-）

```dart
/// メッセージ履歴パネルを表示する。
/// 画面下半部（約60%）をスライドアップして _screen.messageHistory の全履歴を表示。
/// ゲームに入力を送らずに閉じることができる。
void _showMsgHistoryPanel() {
  if (!mounted) return;
  final messages = List<String>.from(_screen.messageHistory);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,         // 領域外タップで閉じる
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        // ... 履歴リスト ...
      );
    },
  );
}
```

**ポイント**:
- `showModalBottomSheet` + `DraggableScrollableSheet` で「画面下半部 ~60%」をスライドアップ。
- `isDismissible: true` で領域外タップ・ESC で閉じる（**ゲームに入力を送らない**）。
- 既存の `ListView(reverse: true)` で最新メッセージが上から表示される（AGENTS.md 方針 12 参照）。

### 3.2 `_messageHistory`（`sys/flutter/lib/nethack_screen.dart:57`）

```dart
// メッセージ履歴 (clearWindow で消去されない永続バッファ)
final List<String> _messageHistory = [];
List<String> get messageHistory => _messageHistory;
```

**ポイント**:
- 最大 100 件保持（超過分は先頭から `removeAt(0)`）。
- `ChangeNotifier`（`extends ChangeNotifier`）配下なので、UI 更新は `notifyListeners()` で自動。
- `clearWindow(WIN_MESSAGE)`（ターン毎）ではクリアされない。
- リセットは `createWindow(WIN_MESSAGE)` 時（ゲーム開始/再開時）のみ（AGENTS.md 方針 12）。
- 履歴対象外: `attr & 0x8000 != 0`（入力補完などの内部的な出力）は追加しない（AGENTS.md 方針 12）。

---

## 4. 拡張ガイド

### 4.1 新しいダイアログに履歴ボタンを足したい場合

1. **そのダイアログが「応答ボタン群を持つ」か確認**:
   - 応答ボタン群の末尾に `_buildMsgHistoryButton()` を追加。
   - 例: `_buildYnOverlay` パターン（行 2330, 2355）。

2. **そのダイアログが「単一 OK ボタン」の場合**:
   - OK ボタンの左に `_buildMsgHistoryButton()` を配置。
   - 例: テキストウィンドウ・オーバーレイ（行 3395-3423）。

3. **そのダイアログが「自由入力（テキストフィールド）」の場合**:
   - 必ずフィルタを噛ませる。`if (_isCallOrNamePrompt(...)) _buildMsgHistoryButton()` のように条件付きで表示。
   - 既存のフィルタ条件に該当しない用途なら、新規プロンプトパターンを `_isCallOrNamePrompt` に追加するか、新しいヘルパーを作る。
   - 例: getline オーバーレイ（行 2492-2517）。

4. **そのダイアログが「メニュー選択」の場合**:
   - 履歴ボタンは不要（メニューは選択で完結し、過去のメッセージ文脈を遡る動機が薄い）。
   - 必要なら別途検討。

### 4.2 新しいプロンプトパターンを追加したい場合

`_isCallOrNamePrompt` の判定ロジックを拡張します（行 2972-2979）。

```dart
// 例えば "○○と名付けてください" のような別パターンも拾いたい場合:
bool _isCallOrNamePrompt(String prompt) {
  if (prompt.isEmpty) return false;
  return prompt.contains('何と呼びますか')
      || prompt.contains('何と名付けますか')
      || prompt.contains('名前を付け')
      || prompt.contains('と名付けてください')   // ← 追加
      || prompt.toLowerCase().contains('call this')
      || prompt.toLowerCase().contains('name this');
}
```

**C 側プロンプトの追加手順**:
1. C 側の該当ファイル（例: `src/do_name.c`）で該当プロンプト文字列を確認。
2. 日本語版と英語版の両方をサポートするか決定。
3. `_isCallOrNamePrompt` に条件追加。
4. `dart analyze` で 0 issues 確認。
5. 実機で該当プロンプトを発生させ、ボタンが出ることを確認。

### 4.3 履歴ボタンのデザインを変えたい場合

`_buildMsgHistoryButton` の 1 箇所を修正すれば全体に反映されます（行 2944-2961）。

```dart
// 例: アイコンを Icons.history から Icons.list_alt に変える
icon: const Icon(Icons.list_alt, size: 18, color: Colors.amber),
```

---

## 5. 検証手順

### 5.1 静的解析

```bash
cd C:\Users\satok\DartHack\sys\flutter
dart analyze
# → "No issues found!" を確認
```

### 5.2 実機確認

| 確認項目 | 手順 | 期待結果 |
|---|---|---|
| YN 確認に履歴ボタン | 死亡 → YN「持ち物を識別しますか?」等で確認 | ボタンが Amber アウトラインで表示される |
| 墓石に履歴ボタン | 死亡 → 結果表示で墓石が出る | OK の左に履歴ボタン |
| 通常テキストページに履歴ボタン | `#overview` コマンド | OK の左に履歴ボタン |
| getline call/name に履歴ボタン | `\call` で任意アイテムを呼び名し | 履歴ボタンが左、キャンセル/決定が右 |
| getline 銘刻に履歴ボタン **なし** | `\e -lorem` | 履歴ボタンが左に出ない（空） |
| getline 拡張コマンドに履歴ボタン **なし** | `#something` | 履歴ボタンが左に出ない（空） |
| 押下で履歴ボトムシート | 履歴ボタンタップ | 画面下半 ~60% に履歴ボトムシート、領域外タップで閉じる |

### 5.3 自動テスト

今回は UI 統合的変更のため、自動テストは追加していません（既存パターンに倣い、`docs/feature_msg_history_button.md` レベルの手動確認 + `dart analyze` のみ）。

---

## 6. 影響範囲

### 6.1 変更ファイル

| ファイル | 変更内容 | 行数 |
|---|---|---|
| `sys/flutter/lib/main.dart` | 共通ヘルパー 2 つ追加、3 オーバーレイにボタン追加 | +84, -26 |

### 6.2 コミット

```
3f56d3480 [Flutter] 突然表示されるダイアログにメッセージ履歴ボタンを追加
```

---

## 7. 関連ドキュメント

- `AGENTS.md`: 「Flutter 版におけるダイアログへのメッセージ履歴ボタン追加（実装ガイド）」セクション（方針の要点）
- `AGENTS.md`: 方針 12「メッセージ表示・履歴バッファとキー誤爆防止の設計」(`_messageHistory` のリセット条件・履歴対象外除外など)
- `AGENTS.md`: 方針 13「キー制限（破棄）時における入力可能状態の同期」(`_showMsgHistoryPanel` がゲームに入力を送らない設計)
- `AGENTS.md`: 方針 14「半透明オーバーレイコントロールにおけるタッチイベントの透過設計」(`Positioned.fill` + `Container` ベースのオーバーレイ構造)
- `sys/flutter/lib/nethack_screen.dart:57`: `_messageHistory` の定義
- `src/do_name.c:253, :305, :647, :650`: C 側アイテム命名プロンプト
- `src/nhlua.c:693`: C 側階層命名プロンプト
