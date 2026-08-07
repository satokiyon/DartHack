import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

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
    int next = amount.clamp(1, widget.maxCount);
    setState(() {
      _currentAmount = next;
      _textController.text = next.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showTile = widget.tileIndex >= 0 && widget.tileImage != null;

    return AlertDialog(
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
          const Text(
            "個数を選択してください",
            style: TextStyle(color: Colors.grey, fontSize: 13),
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
          onPressed: () => Navigator.of(context).pop(-1), // キャンセルは -1 を返却
          child: const Text("キャンセル", style: TextStyle(color: Colors.grey)),
        ),
        Row(
          children: [
            if (widget.maxCount > 1)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(widget.maxCount), // 全て
                child: const Text("全て"),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final amount = int.tryParse(_textController.text) ?? _currentAmount;
                Navigator.of(context).pop(amount.clamp(1, widget.maxCount));
              },
              child: const Text("決定"),
            ),
          ],
        ),
      ],
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
