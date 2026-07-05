import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'nethack_screen.dart';

class NetHackMapPainter extends CustomPainter {
  final NetHackScreen screen;
  final ui.Image? tileImage;
  final int tileSize;
  final bool useTiles;

  NetHackMapPainter({
    required this.screen,
    required this.tileImage,
    required this.tileSize,
    required this.useTiles,
  }) : super(repaint: screen);

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / NetHackScreen.mapCols;
    final cellH = size.height / NetHackScreen.mapRows;

    if (useTiles && tileImage != null) {
      final cols = tileImage!.width ~/ tileSize;

      for (int y = 0; y < NetHackScreen.mapRows; y++) {
        for (int x = 0; x < NetHackScreen.mapCols; x++) {
          final glyph = screen.mapGrid[y][x];
          // tileが0以上の場合のみタイル描画
          if (glyph.tile >= 0) {
            final iRow = glyph.tile ~/ cols;
            final iCol = glyph.tile % cols;

            final srcRect = Rect.fromLTWH(
              (iCol * tileSize).toDouble(),
              (iRow * tileSize).toDouble(),
              tileSize.toDouble(),
              tileSize.toDouble(),
            );

            final destRect = Rect.fromLTWH(
              x * cellW,
              y * cellH,
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
            // タイルがない場合のフォールバック描画
            _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH);
          }
        }
      }
    } else {
      // 従来の ASCII モードでの描画
      for (int y = 0; y < NetHackScreen.mapRows; y++) {
        for (int x = 0; x < NetHackScreen.mapCols; x++) {
          final glyph = screen.mapGrid[y][x];
          _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH);
        }
      }
    }

    // カーソル（プレイヤー位置のハイライト等）の描画
    final cursorRect = Rect.fromLTWH(
      screen.cursorX * cellW,
      screen.cursorY * cellH,
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

  void _drawTextCell(Canvas canvas, String char, int colorVal, int x, int y, double cellW, double cellH) {
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
        x * cellW + (cellW - textPainter.width) / 2,
        y * cellH + (cellH - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant NetHackMapPainter oldDelegate) {
    return oldDelegate.screen != screen ||
           oldDelegate.tileImage != tileImage ||
           oldDelegate.useTiles != useTiles ||
           oldDelegate.tileSize != tileSize;
  }
}
