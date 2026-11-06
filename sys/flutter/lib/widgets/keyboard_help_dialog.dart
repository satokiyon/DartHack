import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 操作ヘルプを表示するコンテキスト種別
enum KeyboardHelpContext {
  game,
  menu,
  yn,
  guidebook,
}

/// キーボード操作ヘルプダイアログ
class KeyboardHelpDialog extends StatelessWidget {
  final KeyboardHelpContext helpContext;
  final int menuHow; // menu 時: 0 = PICK_NONE (閲覧), 1 = PICK_ONE (単一選択), 2 = PICK_ANY (複数選択)
  final bool isJapanese;

  const KeyboardHelpDialog({
    super.key,
    required this.helpContext,
    this.menuHow = 0,
    required this.isJapanese,
  });

  /// ヘルプダイアログを表示する静的メソッド
  static Future<void> show(
    BuildContext context, {
    required KeyboardHelpContext helpContext,
    int menuHow = 0,
    required bool isJapanese,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => KeyboardHelpDialog(
        helpContext: helpContext,
        menuHow: menuHow,
        isJapanese: isJapanese,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isJapanese ? 'キーボード操作ガイド' : 'Keyboard Controls Guide';
    final items = _buildHelpItems();

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        // 任意の主要キー（Esc, F1, Enter, Space等）で安全に閉じる
        if (event.logicalKey == LogicalKeyboardKey.escape ||
            event.logicalKey == LogicalKeyboardKey.f1 ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFA161B24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.8), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 16, spreadRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ヘッダー
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.keyboard_rounded, color: Colors.amberAccent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: isJapanese ? '閉じる (Esc)' : 'Close (Esc)',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 操作一覧リスト
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FlexColumnWidth(),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: items.map((item) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF242C3D),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white24, width: 0.8),
                                  ),
                                  child: Text(
                                    item.key,
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                child: Text(
                                  item.desc,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // フッター
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white12, width: 1)),
                    ),
                    alignment: Alignment.centerRight,
                    child: Text(
                      isJapanese ? 'F1 / Esc / Space で閉じる' : 'Press F1 / Esc / Space to close',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_HelpItem> _buildHelpItems() {
    switch (helpContext) {
      case KeyboardHelpContext.menu:
        final list = <_HelpItem>[];
        // 選択・ドロップメニュー (menuHow >= 1) の時のみ数量指定を案内
        if (menuHow >= 1) {
          list.addAll([
            _HelpItem(
              '0 〜 9',
              isJapanese
                  ? '数量指定（数字入力後にアイテム文字を押すと個数を指定して選択）'
                  : 'Specify quantity (type numbers then press item key)',
            ),
            _HelpItem(
              'BackSpace',
              isJapanese ? '入力中の数量の末尾1桁を削除' : 'Delete last digit of quantity',
            ),
            _HelpItem(
              'Escape',
              isJapanese
                  ? '数量入力をクリア（数量なし時はメニューを閉じる）'
                  : 'Clear quantity (or close menu if no quantity)',
            ),
            _HelpItem(
              'a〜z / A〜Z',
              isJapanese ? 'アイテムの選択・トグル（未指定時は全量）' : 'Select item (all if no count specified)',
            ),
          ]);
        }

        // 共通メニュー操作
        list.addAll([
          _HelpItem('Tab', isJapanese ? '下部ボタン（全選択、解除、閉じる等）を巡回' : 'Cycle bottom action buttons'),
          _HelpItem('Space / PgDn', isJapanese ? '1ページ下へスクロール（閲覧時は最下部で閉じる）' : 'Page down (closes at bottom on view-only)'),
          _HelpItem('↑ / ↓ (k / j)', isJapanese ? '項目を1行スクロール' : 'Scroll 1 line up/down'),
          _HelpItem('← / →', isJapanese ? 'オプション一覧・呪文一覧等の横スクロール' : 'Horizontal scroll (e.g. options, spells)'),
          _HelpItem('Shift + ← / →', isJapanese ? 'メニューを最左端 / 最右端へジャンプ' : 'Jump to left / right edge'),
        ]);

        if (menuHow == 2) {
          list.addAll([
            _HelpItem('.', isJapanese ? '全選択 (menu_select_all)' : 'Select all'),
            _HelpItem('-', isJapanese ? '全選択解除 (menu_deselect_all)' : 'Deselect all'),
            _HelpItem('@', isJapanese ? '選択反転 (menu_invert_all)' : 'Invert selection'),
          ]);
        }

        list.addAll([
          _HelpItem('Enter', isJapanese ? '選択決定（閲覧画面では安全に閉じる）' : 'Confirm selection (or close on view-only)'),
          _HelpItem('Esc', isJapanese ? 'メニューを閉じる / キャンセル' : 'Close menu / Cancel'),
        ]);
        return list;

      case KeyboardHelpContext.yn:
        return [
          _HelpItem('y / n', isJapanese ? '「はい」 / 「いいえ」を実行' : 'Yes / No'),
          _HelpItem('a', isJapanese ? '「すべて」 / 「おまかせ」を実行' : 'All / Pick all'),
          _HelpItem('q', isJapanese ? '「中断」を実行' : 'Quit'),
          _HelpItem('Tab / Shift+Tab', isJapanese ? '選択肢ボタン ↔ 履歴ボタンのフォーカス循環' : 'Cycle choice buttons and History'),
          _HelpItem('Enter', isJapanese ? 'フォーカス中の選択肢を実行（フォーカスなし時は既定値）' : 'Execute focused button (or default)'),
          _HelpItem('Esc', isJapanese ? 'キャンセル / 既定値で終了' : 'Cancel / Dismiss'),
        ];

      case KeyboardHelpContext.guidebook:
        return [
          _HelpItem('t', isJapanese ? '目次モーダルを開く（目次内で文字入力するとリアルタイム絞り込み）' : 'Open Table of Contents (type to filter)'),
          _HelpItem('Tab / Shift+Tab', isJapanese ? '検索欄 ↔ 透過 ↔ 目次 ↔ 閉じるボタンのフォーカス巡回' : 'Cycle Search, Peek, TOC, Close buttons'),
          _HelpItem('↑ / ↓ (k / j)', isJapanese ? '本文を行単位で上下スクロール' : 'Scroll text lines up/down'),
          _HelpItem('← / →', isJapanese ? '表示中の表（テーブル）やコードブロックを横スクロール' : 'Horizontal scroll visible table/code block'),
          _HelpItem('Shift + ← / →', isJapanese ? '表を最左端 / 最右端へ瞬時ジャンプ' : 'Jump table to left / right edge'),
          _HelpItem('Space / PgDn', isJapanese ? '1画面分下へスクロール' : 'Page down'),
          _HelpItem('Home / End', isJapanese ? 'ドキュメント最先頭 / 最末尾へジャンプ' : 'Jump to top / bottom'),
          _HelpItem('Esc / q', isJapanese ? 'ガイドブック / スポイラーを閉じる' : 'Close Guidebook / Spoilers'),
        ];

      case KeyboardHelpContext.game:
        return [
          _HelpItem('矢印 / テンキー / hjkl', isJapanese ? '8方向移動' : '8-direction movement'),
          _HelpItem('Shift + 移動', isJapanese ? '障害物に当たるまでダッシュ移動' : 'Run until obstacle'),
          _HelpItem('Ctrl + 移動', isJapanese ? 'その方向の扉・罠の探査や移動' : 'Move / search towards direction'),
          _HelpItem('Esc', isJapanese ? '現在のアクションを中断 / キャンセル' : 'Cancel current action'),
          _HelpItem('Tab', isJapanese ? 'コマンド履歴や拡張メニューの呼び出し' : 'History / extended menu'),
          _HelpItem('F1', isJapanese ? '操作ヘルプの表示' : 'Show controls help'),
        ];
    }
  }
}

class _HelpItem {
  final String key;
  final String desc;
  const _HelpItem(this.key, this.desc);
}

