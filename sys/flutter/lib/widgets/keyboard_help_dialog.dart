import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 操作ヘルプを表示するコンテキスト種別
enum KeyboardHelpContext {
  game,
  menu,
  yn,
  guidebook,
  titleScreen,
  settings,
  textInput,  // 一行テキスト入力 (願い・名前・フロアメモ等)
  extCmd,     // 拡張コマンド一覧 (# コマンド)
  askName,    // キャラ作成・お名前入力画面
  textWindow, // 長文テキスト (概要、怪物・所持品一覧、墓石、スコア等)
  anyKey,     // 1文字コマンド説明 (「&」コマンド / AnyKeyOverlay)
  fullMap,    // 階層の全体地図 (FullMapDialog)
}

/// キーボード操作ヘルプダイアログ
class KeyboardHelpDialog extends StatefulWidget {
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
  State<KeyboardHelpDialog> createState() => _KeyboardHelpDialogState();
}

class _KeyboardHelpDialogState extends State<KeyboardHelpDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(double delta) {
    if (!_scrollController.hasClients) return;
    final next = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _pageScroll(int direction) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final step = viewport > 0 ? viewport * 0.85 : 320.0;
    final next = (_scrollController.offset + direction * step)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _jumpToEdge(bool toTop) {
    if (!_scrollController.hasClients) return;
    final target = toTop ? 0.0 : _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  void _handleSpace() {
    // スクロール不要（全体が1画面に収まる）か、最下部に到達している場合は閉じる
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 10.0 &&
        _scrollController.offset < _scrollController.position.maxScrollExtent - 5.0) {
      _pageScroll(1);
    } else {
      Navigator.of(context).pop();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isDown = event is KeyDownEvent;
    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    final isHelpCloseKey = key == LogicalKeyboardKey.f1 ||
        (isAlt && key == LogicalKeyboardKey.keyH);

    // Escape / Enter / F1 / Alt-h: 任意の位置から即座に閉じる
    if (key == LogicalKeyboardKey.escape ||
        isHelpCloseKey ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Space: Shift+Space でページ戻り、通常 Space でページ送り（最下部到達時またはスクロール不要時は閉じる）
    if (key == LogicalKeyboardKey.space) {
      if (isDown) {
        if (isShift) {
          _pageScroll(-1);
        } else {
          _handleSpace();
        }
      }
      return KeyEventResult.handled;
    }

    // PageDown / > (Shift + Period / NumpadDecimal)
    final isGreater = isShift &&
        (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal);
    if (key == LogicalKeyboardKey.pageDown || isGreater) {
      if (isDown) _pageScroll(1);
      return KeyEventResult.handled;
    }

    // PageUp / < (Shift + Comma / Less)
    final isLess = (isShift && key == LogicalKeyboardKey.comma) ||
        key == LogicalKeyboardKey.less;
    if (key == LogicalKeyboardKey.pageUp || isLess) {
      if (isDown) _pageScroll(-1);
      return KeyEventResult.handled;
    }

    // ArrowDown / j: 1行下スクロール
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      _scroll(40.0);
      return KeyEventResult.handled;
    }

    // ArrowUp / k: 1行上スクロール
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      _scroll(-40.0);
      return KeyEventResult.handled;
    }

    // Home / End
    if (key == LogicalKeyboardKey.home) {
      if (isDown) _jumpToEdge(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      if (isDown) _jumpToEdge(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isJapanese ? 'キーボード操作ガイド' : 'Keyboard Controls Guide';
    final items = _buildHelpItems();

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
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
                          tooltip: widget.isJapanese ? '閉じる (Esc)' : 'Close (Esc)',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 操作一覧リスト
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Table(
                            columnWidths: {
                              0: MinColumnWidth(
                                const IntrinsicColumnWidth(),
                                FixedColumnWidth(constraints.maxWidth * 0.45),
                              ),
                              1: const FlexColumnWidth(),
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
                          );
                        },
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
                      widget.isJapanese
                          ? 'Spaceでスクロール（最下部で閉じる） / Esc・Enterで終了'
                          : 'Space: Scroll (closes at bottom) / Esc, Enter: Close',
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
    final isJp = widget.isJapanese;
    switch (widget.helpContext) {
      case KeyboardHelpContext.menu:
        final list = <_HelpItem>[];
        // 選択・ドロップメニュー (menuHow >= 1) の時のみ数量指定を案内
        if (widget.menuHow >= 1) {
          list.addAll([
            _HelpItem(
              '0 〜 9',
              isJp
                  ? '数量指定（数字入力後にアイテム文字を押して選択）'
                  : 'Specify quantity (type numbers then press item key)',
            ),
            _HelpItem(
              'BackSpace',
              isJp ? '数量の末尾1桁を削除' : 'Delete last digit of quantity',
            ),
            _HelpItem(
              'Escape',
              isJp
                  ? '数量入力をクリア（数量未入力時はメニュー終了）'
                  : 'Clear quantity (or close menu if no quantity)',
            ),
          ]);
        }

        list.addAll([
          _HelpItem(
            'a〜z / A〜Z',
            isJp
                ? 'アイテムの選択・トグル（数量未指定時は全量）'
                : 'Select item (all if no count specified)',
          ),
        ]);

        if (widget.menuHow == 2) {
          list.addAll([
            _HelpItem('.', isJp ? '全選択 (menu_select_all)' : 'Select all'),
            _HelpItem('-', isJp ? '全選択解除 (menu_deselect_all)' : 'Deselect all'),
            _HelpItem('@', isJp ? '選択反転 (menu_invert_all)' : 'Invert selection'),
          ]);
        }

        list.addAll([
          _HelpItem(
            'Space / PgDn / >',
            isJp
                ? 'ページ送り（閲覧メニュー時は最下部で閉じる）'
                : 'Page down (closes at bottom on view-only)',
          ),
          _HelpItem('Shift+Space / PgUp / <', isJp ? 'ページ戻り' : 'Page up'),
          _HelpItem('^ / | (Home / End)', isJp ? '最先頭 / 最末尾へジャンプ' : 'Jump to top / bottom'),
          _HelpItem('← / →', isJp ? '呪文一覧・オプション等の横スクロール' : 'Horizontal scroll'),
          _HelpItem('Shift + ← / →', isJp ? '最左端 / 最右端へジャンプ' : 'Jump to left / right edge'),
          _HelpItem('↑ / ↓ (k / j)', isJp ? '1行スクロール' : 'Scroll 1 line up/down'),
          _HelpItem('Tab / Shift+Tab', isJp ? '下部アクションボタンのフォーカス循環' : 'Cycle bottom action buttons'),
          _HelpItem('Enter', isJp ? '選択決定（閲覧画面では閉じる）' : 'Confirm selection (or close on view-only)'),
          _HelpItem('Esc', isJp ? 'メニューを閉じる / キャンセル' : 'Close menu / Cancel'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ]);
        return list;

      case KeyboardHelpContext.game:
        return [
          _HelpItem('Ctrl+M / F10', isJp ? 'ドロワーメニューを一発起動' : 'Open drawer menu directly'),
          _HelpItem('F9 / Alt-z', isJp ? '階層の全体地図を表示' : 'Show full level map'),
          _HelpItem('Tab / Shift+Tab', isJp ? '半透明ボタン（メニュー／全体マップ）のフォーカス選択' : 'Focus floating buttons'),
          _HelpItem('Enter / Space', isJp ? '選択中の半透明ボタンを実行' : 'Execute focused floating button'),
          _HelpItem('?', isJp ? 'NetHack標準のヘルプ・コマンド一覧を表示' : 'Show standard NetHack help and command list'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.yn:
        return [
          _HelpItem('y / n', isJp ? '「はい」 / 「いいえ」を実行' : 'Yes / No'),
          _HelpItem('a / q', isJp ? '「すべて」 / 「中断」を実行' : 'All / Quit'),
          _HelpItem('Tab / Shift+Tab', isJp ? '選択肢ボタン ↔ 履歴ボタンのフォーカス循環' : 'Cycle choice buttons and History'),
          _HelpItem('Enter', isJp ? 'フォーカス中の選択肢を実行（未選択時は既定値）' : 'Execute focused button (or default)'),
          _HelpItem('Space / Esc', isJp ? '既定値で応答 / キャンセル' : 'Default response / Cancel'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.guidebook:
        return [
          _HelpItem('t', isJp ? '目次を開く（開いた直後に文字入力でリアルタイム絞り込み）' : 'Open Table of Contents (type to filter)'),
          _HelpItem('n / N', isJp ? '次の一致 / 前の一致へジャンプ' : 'Jump to next / previous match'),
          _HelpItem('Space / PgDn / >', isJp ? 'ページ送り' : 'Page down'),
          _HelpItem('Shift+Space / PgUp / <', isJp ? 'ページ戻り' : 'Page up'),
          _HelpItem('Home / End', isJp ? '最先頭 / 最末尾へジャンプ' : 'Jump to top / bottom'),
          _HelpItem('↑ / ↓ (k / j)', isJp ? '本文を行単位でスクロール' : 'Scroll text lines up/down'),
          _HelpItem('← / →', isJp ? '表示中の表やコードブロックを横スクロール' : 'Horizontal scroll visible table/code block'),
          _HelpItem('Shift + ← / →', isJp ? '表を最左端 / 最右端へジャンプ' : 'Jump table to left / right edge'),
          _HelpItem('Tab / Shift+Tab', isJp ? '検索欄 ↔ 前/次の一致 ↔ 透過 ↔ 目次 ↔ 閉じるボタンのフォーカス巡回' : 'Cycle Search, Prev/Next match, Peek, TOC, Close buttons'),
          _HelpItem('Esc / q', isJp ? 'ガイドブック / スポイラーを閉じる' : 'Close Guidebook / Spoilers'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.titleScreen:
        return [
          _HelpItem('Enter', isJp ? '冒険を始める（フォーカス未選択時も即時実行可能）' : 'Start Adventure (immediate from unfocused)'),
          _HelpItem('Tab / Shift+Tab', isJp ? '各ボタンのフォーカス循環' : 'Cycle buttons'),
          _HelpItem('Space', isJp ? '言語切り替え（言語選択時）、または選択ボタンを実行' : 'Toggle language or execute focused button'),
          _HelpItem('← / →', isJp ? '言語直接選択（←: 日本語, →: English）' : 'Select language (←: Japanese, →: English)'),
          _HelpItem('Esc', isJp ? 'フォーカス枠を解除して初期状態にリセット' : 'Clear focus highlight'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.settings:
        return [
          _HelpItem('↑ / ↓', isJp ? '項目の移動・選択（端到達時は AppBar 戻るボタン経由で循環ループ）' : 'Move / select item (cycles via Back button)'),
          _HelpItem('Space / Enter', isJp ? 'トグル切り替え / 決定（戻るボタン時は前画面へ戻る）' : 'Toggle / Confirm (or Back)'),
          _HelpItem('Tab / Shift+Tab', isJp ? 'フォーカス移動' : 'Move focus'),
          _HelpItem('PgDn / PgUp', isJp ? 'ページスクロール' : 'Scroll page'),
          _HelpItem('Home / End', isJp ? '最先頭 / 最末尾へ移動' : 'Jump to top / bottom'),
          _HelpItem('Esc', isJp ? '保存して戻る' : 'Save and return'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.textInput:
        return [
          _HelpItem('文字入力', isJp ? '初期状態（未フォーカス）のままでも英数字・記号を直接入力可能' : 'Type letters/digits directly without focusing'),
          _HelpItem('Tab', isJp ? '入力欄にフォーカスを当てて日本語 IME（ローマ字かな変換・キャレット）を有効化' : 'Focus text field to enable Japanese IME & caret'),
          _HelpItem('Backspace', isJp ? '直前の1文字を削除' : 'Delete character'),
          _HelpItem('Delete', isJp ? '入力欄の全文字を消去' : 'Clear entire input'),
          _HelpItem('Enter', isJp ? '入力を確定して送信' : 'Confirm and submit input'),
          _HelpItem('Esc', isJp ? '入力をキャンセルして閉じる' : 'Cancel and close'),
          _HelpItem('Tab / Shift+Tab', isJp ? '入力欄 ↔ 決定ボタン ↔ キャンセルボタンのフォーカス循環' : 'Cycle input field and buttons'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.extCmd:
        return [
          _HelpItem('文字入力', isJp ? '初期状態のままでも直接打鍵して候補をインクリメンタル絞り込み' : 'Type letters directly to filter commands'),
          _HelpItem('Tab / Shift+Tab', isJp ? '候補の順送り・逆送り巡回オートコンプリート' : 'Cycle autocompletion forward / backward'),
          _HelpItem('↑ / ↓', isJp ? '候補リストの選択移動（自動追従スクロール）' : 'Navigate candidates list'),
          _HelpItem('Enter', isJp ? 'ハイライト・補完されたコマンドを即座に実行（# は自動切除）' : 'Execute highlighted command (# trimmed)'),
          _HelpItem('Esc', isJp ? 'キャンセルして閉じる' : 'Cancel and close'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.askName:
        return [
          _HelpItem('文字入力', isJp ? '初期状態のままでも名前入力欄に英数字を直接入力可能' : 'Type name letters directly without focusing'),
          _HelpItem('Tab / Shift+Tab', isJp ? '名前欄 ↔ セーブ一覧 ↔ プレイモード ↔ キャンセル ↔ 開始の循環' : 'Cycle name, saves, mode, and buttons'),
          _HelpItem('← / → / Space', isJp ? 'プレイモード切り替え（通常 ↔ 探索 ↔ ウィザード）※モード選択時' : 'Toggle game mode (Normal / Explore / Wizard)'),
          _HelpItem('↑ / ↓', isJp ? 'セーブデータ一覧の上下選択（名前自動入力）※セーブ一覧選択時' : 'Select saved games (auto-fills name)'),
          _HelpItem('Enter', isJp ? '冒険を開始（またはフォーカス中のボタンを実行）' : 'Start adventure or execute focused button'),
          _HelpItem('Esc', isJp ? '前画面へ戻る' : 'Return to previous screen'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.textWindow:
        return [
          _HelpItem('Space / PgDn / >', isJp ? 'ページ送り（最下部で押すと画面を閉じる）' : 'Page down (closes at bottom)'),
          _HelpItem('Shift+Space / PgUp / <', isJp ? 'ページ戻り' : 'Page up'),
          _HelpItem('↑ / ↓ (k / j)', isJp ? '1行ずつ上下スクロール' : 'Scroll 1 line up/down'),
          _HelpItem('Home / End', isJp ? '最先頭 / 最末尾へジャンプ' : 'Jump to top / bottom'),
          _HelpItem('Enter', isJp ? '任意の位置から即座に閉じる（または選択ボタン実行）' : 'Close immediately from any position'),
          _HelpItem('Tab / Shift+Tab', isJp ? '下部ボタン（OK、履歴等）のフォーカス巡回' : 'Cycle bottom action buttons'),
          _HelpItem('Esc / q', isJp ? '画面を閉じる' : 'Close window'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.anyKey:
        return [
          _HelpItem('キー入力', isJp ? '調べたいキーを押してコマンドの働きを説明' : 'Press any key to explain command'),
          _HelpItem('Space / Enter', isJp ? 'Space / Enter 自体のコマンド説明を表示（未選択時）' : 'Explain Space / Enter command (when unfocused)'),
          _HelpItem('Tab / Shift+Tab', isJp ? 'none ↔「閉じる」↔「履歴」ボタンのフォーカス循環' : 'Cycle none, Close, History buttons'),
          _HelpItem('Enter / Space', isJp ? 'フォーカス中のボタンを実行（閉じる / 履歴）' : 'Execute focused button (Close / History)'),
          _HelpItem('Esc', isJp ? '画面を閉じる' : 'Close overlay'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];

      case KeyboardHelpContext.fullMap:
        return [
          _HelpItem('z', isJp ? '6倍拡大 ⇔ 全体表示（等倍）アニメーショントグル' : 'Toggle 6x zoom and fit-all view'),
          _HelpItem('+ / =', isJp ? '画面中央を基準にズームイン' : 'Zoom in'),
          _HelpItem('-', isJp ? '画面中央を基準にズームアウト' : 'Zoom out'),
          _HelpItem('0 / Home', isJp ? '全体表示（等倍）にリセット' : 'Reset to fit-all view'),
          _HelpItem('矢印 / hjkl yubn', isJp ? 'マップのパン（平行移動）' : 'Pan map'),
          _HelpItem('Shift + 移動キー', isJp ? '2倍のスピードで高速パン移動' : 'Fast pan (2x speed)'),
          _HelpItem('Tab / Shift+Tab', isJp ? '閉じるボタンのフォーカス選択' : 'Focus Close button'),
          _HelpItem('Enter / Esc', isJp ? '全体マップを閉じる' : 'Close full map'),
          _HelpItem('F1 / Alt-h', isJp ? '操作ヘルプの表示' : 'Show controls help'),
        ];
    }
  }
}

class _HelpItem {
  final String key;
  final String desc;
  const _HelpItem(this.key, this.desc);
}
