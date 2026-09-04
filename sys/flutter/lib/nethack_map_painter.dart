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
          final cellLeft = offsetX + x * cellW;
          final cellTop = offsetY + y * cellH;

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
              cellLeft,
              cellTop,
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
            _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH, offsetX, offsetY, special: glyph.special);
          }

          // 特殊マーカーの描画（ペットのハートマーク、アイテム山のプラスマーク）
          final isPet = (glyph.special & (_mgPet | _mgRidden)) != 0;
          final isPile = (glyph.special & _mgObjPile) != 0;

          if (isPet || isPile) {
            final dotSize = (cellW / 32.0 * 1.3).clamp(1.0, 3.0);

            if (isPet) {
              // ペットはタイルの左上に赤色ハートマーク
              _drawPixelPattern(
                canvas,
                _heartPattern,
                cellLeft + 1.5,
                cellTop + 1.5,
                dotSize,
                const Color(0xFFFF2222),
              );
            }

            if (isPile) {
              // アイテム山は、ペットがいる場合は右上、いなければ左上に緑色プラスマーク
              final pileStartX = isPet
                  ? cellLeft + cellW - (_pilePattern[0].length * dotSize) - 1.5
                  : cellLeft + 1.5;
              _drawPixelPattern(
                canvas,
                _pilePattern,
                pileStartX,
                cellTop + 1.5,
                dotSize,
                const Color(0xFF00FF44),
              );
            }
          }
        }
      }
    } else {
      for (int y = 0; y < NetHackScreen.mapRows; y++) {
        for (int x = 0; x < NetHackScreen.mapCols; x++) {
          final glyph = screen.mapGrid[y][x];
          _drawTextCell(canvas, glyph.char, glyph.color, x, y, cellW, cellH, offsetX, offsetY, special: glyph.special);
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

  // 特殊グリフフラグ定数
  static const int _mgPet = 0x00010;
  static const int _mgRidden = 0x00020;
  static const int _mgObjPile = 0x00080;

  // 本家NetHack Qt準拠のペットマーカー（ハートマーク）ドットパターン（7x7）
  static const List<List<int>> _heartPattern = [
    [0, 1, 1, 0, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 0, 0, 0],
  ];

  // 本家NetHack Qt準拠のアイテム山マーカー（プラスマーク）ドットパターン（5x5）
  static const List<List<int>> _pilePattern = [
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1],
    [0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0],
  ];

  // ピクセルアートパターンの描画ヘルパー（黒の輪郭シャドウ付きで高視認性）
  static void _drawPixelPattern(
    Canvas canvas,
    List<List<int>> pattern,
    double startX,
    double startY,
    double dotSize,
    Color color,
  ) {
    final shadowPaint = Paint()..color = const Color(0xCC000000);
    final mainPaint = Paint()..color = color;

    // 黒縁取りシャドウ（周囲0.5px拡張）
    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] != 0) {
          final px = startX + c * dotSize;
          final py = startY + r * dotSize;
          canvas.drawRect(
            Rect.fromLTWH(px - 0.5, py - 0.5, dotSize + 1.0, dotSize + 1.0),
            shadowPaint,
          );
        }
      }
    }

    // メイン色
    for (int r = 0; r < pattern.length; r++) {
      for (int c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] != 0) {
          final px = startX + c * dotSize;
          final py = startY + r * dotSize;
          canvas.drawRect(
            Rect.fromLTWH(px, py, dotSize, dotSize),
            mainPaint,
          );
        }
      }
    }
  }

  void _drawTextCell(
    Canvas canvas,
    String char,
    int colorVal,
    int x,
    int y,
    double cellW,
    double cellH,
    double offsetX,
    double offsetY, {
    int special = 0,
  }) {
    if (char == ' ' || char.isEmpty) return;

    final cellLeft = offsetX + x * cellW;
    final cellTop = offsetY + y * cellH;

    final isPet = (special & (_mgPet | _mgRidden)) != 0;
    final isPile = (special & _mgObjPile) != 0;

    // テキストモードでのハイライト表示
    if (isPet) {
      // ペットは反転表示（明灰色背景）
      canvas.drawRect(
        Rect.fromLTWH(cellLeft, cellTop, cellW, cellH),
        Paint()..color = const Color(0xFFDDDDDD),
      );
    } else if (isPile) {
      // アイテム山は下部に緑色の目印線を描画
      canvas.drawRect(
        Rect.fromLTWH(cellLeft, cellTop + cellH - 2.0, cellW, 2.0),
        Paint()..color = const Color(0xFF00FF44),
      );
    }

    Color textColor;
    if (isPet) {
      textColor = Colors.black; // 反転背景なので文字色は黒
    } else {
      textColor = colorVal != 0 ? Color(colorVal | 0xFF000000) : Colors.white;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: textColor,
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
        cellLeft + (cellW - textPainter.width) / 2,
        cellTop + (cellH - textPainter.height) / 2,
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
