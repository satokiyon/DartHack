import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MenuItemTilePainter extends CustomPainter {
  final ui.Image image;
  final int tileIndex;
  final int tileWidth;
  final int tileHeight;

  MenuItemTilePainter({
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
  bool shouldRepaint(covariant MenuItemTilePainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.tileIndex != tileIndex ||
           oldDelegate.tileWidth != tileWidth ||
           oldDelegate.tileHeight != tileHeight;
  }
}
