import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'l10n/app_localizations.dart';

class AmountSelectorDialog extends StatefulWidget {
  final String itemName;
  final int maxCount;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;
  final int tileIndex; // 0以上のときタイル表示、それ以外は非表示

  const AmountSelectorDialog({
    super.key,
    required this.itemName,
    required this.maxCount,
    this.tileImage,
    this.tileWidth = 32,
    this.tileHeight = 32,
    this.tileIndex = -1,
  });

  @override
  State<AmountSelectorDialog> createState() => _AmountSelectorDialogState();
}

class _AmountSelectorDialogState extends State<AmountSelectorDialog> {
  late int _currentAmount;
  late TextEditingController _textController;
  bool _hasTypedDigits = false;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.maxCount;
    _textController = TextEditingController(text: _currentAmount.toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateAmount(int amount) {
    final next = amount.clamp(1, widget.maxCount);
    setState(() {
      _currentAmount = next;
      _textController.text = next.toString();
      _hasTypedDigits = false;
    });
  }

  void _confirm() {
    final amount = int.tryParse(_textController.text) ?? _currentAmount;
    Navigator.of(context).pop(amount.clamp(1, widget.maxCount));
  }

  String? _digitFromKey(KeyEvent event) {
    final ch = event.character;
    if (ch != null && ch.length == 1) {
      final cu = ch.codeUnitAt(0);
      if (cu >= 48 && cu <= 57) return ch;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) return '0';
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) return '1';
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) return '2';
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) return '3';
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) return '4';
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) return '5';
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) return '6';
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) return '7';
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) return '8';
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) return '9';
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _confirm();
      return KeyEventResult.handled;
    }

    final isTextFieldFocused =
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;
    if (isTextFieldFocused) {
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.numpadAdd ||
        event.character == '+') {
      _updateAmount(_currentAmount + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.numpadSubtract ||
        key == LogicalKeyboardKey.minus ||
        event.character == '-') {
      _updateAmount(_currentAmount - 1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace) {
      final text = _textController.text;
      if (text.length > 1) {
        final nextText = text.substring(0, text.length - 1);
        final parsed = int.tryParse(nextText) ?? 1;
        setState(() {
          _currentAmount = parsed.clamp(1, widget.maxCount);
          _textController.text = nextText;
          _hasTypedDigits = true;
        });
      } else {
        setState(() {
          _currentAmount = 1;
          _textController.text = '1';
          _hasTypedDigits = false;
        });
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.delete) {
      setState(() {
        _currentAmount = 1;
        _textController.text = '1';
        _hasTypedDigits = false;
      });
      return KeyEventResult.handled;
    }

    final digit = _digitFromKey(event);
    if (digit != null) {
      final maxLen = widget.maxCount.toString().length;
      String nextText;
      if (!_hasTypedDigits) {
        nextText = digit == '0' ? '1' : digit;
      } else {
        final candidate = _textController.text + digit;
        nextText = candidate.length <= maxLen ? candidate : candidate.substring(0, maxLen);
      }
      final parsed = (int.tryParse(nextText) ?? 1).clamp(1, widget.maxCount);
      setState(() {
        _currentAmount = parsed;
        _textController.text = parsed.toString();
        _hasTypedDigits = true;
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showTile = widget.tileIndex >= 0 && widget.tileImage != null;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        backgroundColor: Colors.grey[950],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (showTile) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _TilePainter(
                    image: widget.tileImage!,
                    tileIndex: widget.tileIndex,
                    tileWidth: widget.tileWidth,
                    tileHeight: widget.tileHeight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                widget.itemName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.howMany,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 32, color: Colors.amber),
                  onPressed: () => _updateAmount(_currentAmount - 1),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _textController,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.maxCount.toString().length),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    ),
                    onChanged: (val) {
                      final amount = int.tryParse(val);
                      if (amount != null) {
                        _currentAmount = amount.clamp(1, widget.maxCount);
                      }
                    },
                    onSubmitted: (_) => _confirm(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 32, color: Colors.amber),
                  onPressed: () => _updateAmount(_currentAmount + 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.maxCount > 1) ...[
              Slider(
                value: _currentAmount.toDouble(),
                min: 1,
                max: widget.maxCount.toDouble(),
                divisions: widget.maxCount > 1 ? widget.maxCount - 1 : 1,
                activeColor: Colors.amber,
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  _updateAmount(val.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("1", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(widget.maxCount.toString(), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(-1),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          Row(
            children: [
              if (widget.maxCount > 1)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(widget.maxCount),
                  child: Text(l10n.all),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: _confirm,
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  final int tileIndex;
  final int tileWidth;
  final int tileHeight;

  _TilePainter({
    required this.image,
    required this.tileIndex,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = image.width ~/ tileWidth;
    final iRow = tileIndex ~/ cols;
    final iCol = tileIndex % cols;

    final srcRect = Rect.fromLTWH(
      (iCol * tileWidth).toDouble(),
      (iRow * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );

    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image,
      srcRect,
      destRect,
      Paint()..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _TilePainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.tileIndex != tileIndex ||
           oldDelegate.tileWidth != tileWidth ||
           oldDelegate.tileHeight != tileHeight;
  }
}
