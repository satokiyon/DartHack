import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 広告機能・ハイライト機能無効時に表示される標準のゲーム終了ダイアログ
class StandardExitDialog extends StatefulWidget {
  final String dialogMessage;
  final bool isJapanese;

  const StandardExitDialog({
    super.key,
    required this.dialogMessage,
    this.isJapanese = true,
  });

  @override
  State<StandardExitDialog> createState() => _StandardExitDialogState();
}

class _StandardExitDialogState extends State<StandardExitDialog> {
  bool _isOkFocused = false;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Space, Enter, NumpadEnter, Escape でダイアログを閉じる
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Tab / Shift+Tab で OK ボタンのフォーカス枠をトグル巡回
    if (key == LogicalKeyboardKey.tab) {
      setState(() {
        _isOkFocused = !_isOkFocused;
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.grey[950],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Text(widget.isJapanese ? 'ゲーム終了' : 'Game Over'),
            ],
          ),
          content: Text(
            widget.dialogMessage,
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
          ),
          actions: [
            Container(
              decoration: _isOkFocused
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amberAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.amberAccent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: _isOkFocused ? Colors.amberAccent : Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: _isOkFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
