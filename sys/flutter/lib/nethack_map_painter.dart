import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'nethack_screen.dart';

class NetHackMapPainter extends CustomPainter {
  final NetHackScreen screen;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;
  final bool useTiles;

  NetHackMapPainter({
    required this.screen,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
    required this.useTiles,
  }) : super(repaint: screen);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = useTiles ? 32.0 : 9.0;
    final cellH = useTiles ? 32.0 : 16.0;

    final mapWidth = NetHackScreen.mapCols * cellW;
    final mapHeight = NetHackScreen.mapRows * cellH;

    final offsetX = (size.width - mapWidth) / 2;
    final offsetY = (size.height - mapHeight) / 2;

    if (!useTiles) {
      final mapRect = Rect.fromLTWH(offsetX, offsetY, mapWidth, mapHeight);
      canvas.drawRect(
        mapRect,
        Paint()
          ..color = const Color(0xFF111111)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        mapRect,
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    if (useTiles && tileImage != null) {
      final cols = tileImage!.width ~/ tileWidth;

      for (int y = 0; y < NetHackScreen.mapRows; y++) {
        for (int x = 0; x < NetHackScreen.mapCols; x++) {
          final glyph = screen.mapGrid[y][x];
          if (glyph.tile >= 0) {
            final iRow = glyph.tile ~/ cols;
            final iCol = glyph.tile % cols;

            final srcRect = Rect.fromLTWH(
              (iCol * tileWidth).toDouble(),
              (iRow * tileHeight).toDouble(),
              tileWidth.toDouble(),
              tileHeight.toDouble(),
            );

            final destRect = Rect.fromLTWH(
              offsetX + x * cellW,
              offsetY + y * cellH,
              cellW,
              cellH,
            );

            canvas.drawImageRect(
              tileImage!,
              srcRect,
              destRect,
              Paint()..isAntiAlias = false,
            );
          } else {
            _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH, offsetX, offsetY);
          }
        }
      }
    } else {
      for (int y = 0; y < NetHackScreen.mapRows; y++) {
        for (int x = 0; x < NetHackScreen.mapCols; x++) {
          final glyph = screen.mapGrid[y][x];
          _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH, offsetX, offsetY);
        }
      }
    }

    final cursorRect = Rect.fromLTWH(
      offsetX + screen.cursorX * cellW,
      offsetY + screen.cursorY * cellH,
      cellW,
      cellH,
    );
    canvas.drawRect(
      cursorRect,
      Paint()
        ..color = Colors.yellow.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawTextCell(Canvas canvas, String char, int colorVal, int x, int y, double cellW, double cellH, double offsetX, double offsetY) {
    if (char == ' ' || char.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: colorVal != 0 ? Color(colorVal | 0xFF000000) : Colors.white,
          fontSize: cellH * 0.95,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        offsetX + x * cellW + (cellW - textPainter.width) / 2,
        offsetY + y * cellH + (cellH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant NetHackMapPainter oldDelegate) {
    return oldDelegate.screen != screen ||
           oldDelegate.tileImage != tileImage ||
           oldDelegate.useTiles != useTiles ||
           oldDelegate.tileWidth != tileWidth ||
           oldDelegate.tileHeight != tileHeight;
  }
}
