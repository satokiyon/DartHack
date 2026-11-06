import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NewLevelRestChoice {
  none,
  restWithAd,
  proceed,
}

/// 新しい階層到達時に表示される休憩確認ダイアログ
class NewLevelRestDialog extends StatefulWidget {
  final bool isJapanese;

  const NewLevelRestDialog({
    super.key,
    this.isJapanese = true,
  });

  @override
  State<NewLevelRestDialog> createState() => _NewLevelRestDialogState();
}

class _NewLevelRestDialogState extends State<NewLevelRestDialog> {
  NewLevelRestChoice _focusedChoice = NewLevelRestChoice.none;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Space, Enter, NumpadEnter で選択中のボタン（または初期状態なら「そのまま進む」）を実行
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_focusedChoice == NewLevelRestChoice.restWithAd) {
        Navigator.of(context).pop(true);
      } else {
        // 初期状態 (none) または proceed 選択時は「そのまま進む」を実行
        Navigator.of(context).pop(false);
      }
      return KeyEventResult.handled;
    }

    // Escape キー押下時は「そのまま進む」を実行
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(false);
      return KeyEventResult.handled;
    }

    // Tab / Shift+Tab でフォーカスを巡回
    if (key == LogicalKeyboardKey.tab) {
      final isShift = HardwareKeyboard.instance.isShiftPressed;
      setState(() {
        if (!isShift) {
          switch (_focusedChoice) {
            case NewLevelRestChoice.none:
              _focusedChoice = NewLevelRestChoice.restWithAd;
              break;
            case NewLevelRestChoice.restWithAd:
              _focusedChoice = NewLevelRestChoice.proceed;
              break;
            case NewLevelRestChoice.proceed:
              _focusedChoice = NewLevelRestChoice.none;
              break;
          }
        } else {
          switch (_focusedChoice) {
            case NewLevelRestChoice.none:
              _focusedChoice = NewLevelRestChoice.proceed;
              break;
            case NewLevelRestChoice.proceed:
              _focusedChoice = NewLevelRestChoice.restWithAd;
              break;
            case NewLevelRestChoice.restWithAd:
              _focusedChoice = NewLevelRestChoice.none;
              break;
          }
        }
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isJp = widget.isJapanese;

    final isAdFocused = _focusedChoice == NewLevelRestChoice.restWithAd;
    final isProceedFocused = _focusedChoice == NewLevelRestChoice.proceed;

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
              const Icon(Icons.explore_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text(isJp ? '未知の階層に到達' : 'Reached New Floor'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isJp
                    ? '新しい階層に足を踏み入れた。\n広告を見て少し休息しますか？'
                    : 'Stepped onto a new floor.\nWould you like to rest briefly by watching an ad?',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: isAdFocused
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                  label: Text(
                    isJp
                        ? '広告を見て休む (体力か魔力を回復)'
                        : 'Rest by watching ad (Restore either HP or PW)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: isProceedFocused
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(isJp ? 'そのまま進む' : 'Proceed as is'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
