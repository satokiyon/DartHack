import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/map_animation_event.dart';
import '../nethack_map_painter.dart';
import '../nethack_screen.dart';
import '../services/font_manager.dart';
import '../utils/map_animation_controller.dart';

/// 2 レイヤー分離構成の動的マップアニメーションオーバーレイペインタ。
///
/// 静止マップ（1,680 セル）は下層の `NetHackMapPainter`（RepaintBoundary 配下）に任せ、
/// 本ペインタはアニメーション中の数セル・死亡フェード・飛び道具・パーティクル・
/// 光リング・持続的な状態マイクロ演出・フローティングテキストのみを描画する。
class NetHackAnimationOverlayPainter extends CustomPainter {
  final NetHackScreen screen;
  final MapAnimationController animationController;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;
  final bool useTiles;
  final bool isTransparentTileset;
  final String? fontId;

  static final Map<String, TextPainter> _textCache = {};
  static final Map<String, TextPainter> _badgeTextCache = {};

  NetHackAnimationOverlayPainter({
    required this.screen,
    required this.animationController,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
    required this.useTiles,
    this.isTransparentTileset = false,
    this.fontId,
  }) : super(repaint: animationController);

  @override
  void paint(Canvas canvas, Size size) {
    if (!animationController.hasAnyVisuals) return;

    final cellSize = FontManager.instance.getMapCellSize(
      useTiles: useTiles,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    final cellW = cellSize.width;
    final cellH = cellSize.height;

    final mapWidth = NetHackScreen.mapCols * cellW;
    final mapHeight = NetHackScreen.mapRows * cellH;
    final offsetX = (size.width - mapWidth) / 2;
    final offsetY = (size.height - mapHeight) / 2;

    final activeKeys = animationController.animatedCellKeys.toList(growable: false);
    final int sheetCols = (useTiles && tileImage != null && tileWidth > 0)
        ? tileImage!.width ~/ tileWidth
        : 0;
    final tuning = animationController.tuning;

    // 1. アニメーション・浮遊対象セルの静止グリフを背景地形でマスク上書き
    for (final key in activeKeys) {
      final y = key ~/ NetHackScreen.mapCols;
      final x = key % NetHackScreen.mapCols;
      if (y < 0 || y >= NetHackScreen.mapRows || x < 0 || x >= NetHackScreen.mapCols) continue;
      final glyph = screen.mapGrid[y][x];
      final cellLeft = offsetX + x * cellW;
      final cellTop = offsetY + y * cellH;
      _drawBackgroundMask(
        canvas,
        glyph,
        cellLeft,
        cellTop,
        cellW,
        cellH,
        sheetCols,
      );
    }

    // 2. 移動・バンプ・被弾・浮遊中の前面エンティティを描画（浮遊時は移動追従の足元影を先に描画）
    for (final key in activeKeys) {
      final y = key ~/ NetHackScreen.mapCols;
      final x = key % NetHackScreen.mapCols;
      if (y < 0 || y >= NetHackScreen.mapRows || x < 0 || x >= NetHackScreen.mapCols) continue;
      final transform = animationController.getCellTransform(x, y);
      if (transform == null) continue;

      if (transform.isFloating) {
        final shadowCenterX = offsetX + (x + transform.moveDx + 0.5) * cellW;
        final shadowCenterY = offsetY + (y + transform.moveDy + 0.86) * cellH;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(shadowCenterX, shadowCenterY),
            width: cellW * tuning.ambient.shadowWidthRatio,
            height: cellH * tuning.ambient.shadowHeightRatio,
          ),
          Paint()..color = Color.fromRGBO(0, 0, 0, tuning.ambient.shadowAlpha.clamp(0.0, 1.0)),
        );
      }

      final glyph = screen.mapGrid[y][x];
      final drawLeft = offsetX + (x + transform.dx) * cellW;
      final drawTop = offsetY + (y + transform.dy) * cellH;

      _drawForegroundGlyph(
        canvas,
        glyph,
        drawLeft,
        drawTop,
        cellW,
        cellH,
        sheetCols,
        flashAlpha: transform.flashAlpha,
        flashColor: transform.flashColor,
        fallbackTile: transform.fallbackTile,
        fallbackChar: transform.fallbackChar,
        fallbackColor: transform.fallbackColor,
      );
    }

    // 3. 消滅岩押し（穴埋め・水没・落とし穴・テレポ罠）描画
    for (final obj in animationController.activeVanishingObjectMoves) {
      if (obj.opacity <= 0.01) continue;
      final centerX = offsetX + (obj.x + 0.5) * cellW;
      final centerY = offsetY + (obj.y + 0.5) * cellH;
      final scaledW = cellW * obj.scale;
      final scaledH = cellH * obj.scale;
      final left = centerX - scaledW / 2;
      final top = centerY - scaledH / 2;

      if (useTiles && tileImage != null && obj.tile >= 0 && sheetCols > 0) {
        canvas.drawImageRect(
          tileImage!,
          _tileSrcRect(obj.tile, sheetCols),
          Rect.fromLTWH(left, top, scaledW, scaledH),
          Paint()
            ..isAntiAlias = false
            ..color = Color.fromRGBO(255, 255, 255, obj.opacity),
        );
      } else {
        final baseColor = obj.color != 0 ? Color(obj.color | 0xFF000000) : Colors.grey;
        _drawTextChar(
          canvas,
          obj.char,
          baseColor.withValues(alpha: obj.opacity),
          left,
          top,
          scaledW,
          scaledH,
        );
      }
    }

    // 4. 死亡フェードアウト描画
    for (final death in animationController.activeDeathFades) {
      if (death.opacity <= 0.01) continue;
      final centerX = offsetX + (death.x + 0.5) * cellW;
      final centerY = offsetY + (death.y + 0.5) * cellH;
      final scaledW = cellW * death.scale;
      final scaledH = cellH * death.scale;
      final left = centerX - scaledW / 2;
      final top = centerY - scaledH / 2;

      if (useTiles && tileImage != null && death.tile >= 0 && sheetCols > 0) {
        final srcRect = _tileSrcRect(death.tile, sheetCols);
        canvas.drawImageRect(
          tileImage!,
          srcRect,
          Rect.fromLTWH(left, top, scaledW, scaledH),
          Paint()
            ..isAntiAlias = false
            ..color = Color.fromRGBO(255, 255, 255, death.opacity),
        );
      } else {
        final baseColor = death.color != 0 ? Color(death.color | 0xFF000000) : Colors.white;
        _drawTextChar(
          canvas,
          death.char,
          baseColor.withValues(alpha: death.opacity),
          left,
          top,
          scaledW,
          scaledH,
        );
      }
    }

    // 5. 飛び道具・光線描画
    for (final proj in animationController.activeProjectiles) {
      final drawLeft = offsetX + proj.x * cellW;
      final drawTop = offsetY + proj.y * cellH;
      if (useTiles && tileImage != null && proj.tile >= 0 && sheetCols > 0) {
        final srcRect = _tileSrcRect(proj.tile, sheetCols);
        canvas.drawImageRect(
          tileImage!,
          srcRect,
          Rect.fromLTWH(drawLeft, drawTop, cellW, cellH),
          Paint()..isAntiAlias = false,
        );
      } else {
        final baseColor = proj.color != 0 ? Color(proj.color | 0xFF000000) : Colors.white;
        _drawTextChar(
          canvas,
          proj.char,
          baseColor,
          drawLeft,
          drawTop,
          cellW,
          cellH,
        );
      }
    }

    // 6. 持続的な状態マイクロ演出（4スロット優先度排他・MaskFilter.blur 不使用）
    for (final status in animationController.activeAmbientStatuses) {
      _drawAmbientStatus(
        canvas,
        status,
        offsetX,
        offsetY,
        cellW,
        cellH,
      );
    }

    // 7. 同心円光リング VFX（MaskFilter.blur 不使用）
    for (final ring in animationController.activeRings) {
      if (ring.opacity <= 0.01) continue;
      final center = Offset(offsetX + ring.x * cellW, offsetY + ring.y * cellH);
      final radius = ring.radiusCells * cellW;
      final stroke = math.max(1.0, ring.strokeRatio * cellW);
      // 外側の淡いハロー線 + 内側のクッキリしたコア線
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 2.0
          ..color = ring.color.withValues(alpha: ring.opacity * 0.30),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = ring.color.withValues(alpha: ring.opacity * 0.88),
      );
    }

    // 8. ドット粒・発光粒パーティクル VFX
    for (final p in animationController.activeParticles) {
      if (p.opacity <= 0.01) continue;
      final px = offsetX + p.x * cellW;
      final py = offsetY + p.y * cellH;
      final sz = math.max(1.5, p.sizeRatio * cellW);
      if (p.isGlow) {
        canvas.drawCircle(
          Offset(px, py),
          sz * 0.95,
          Paint()..color = p.color.withValues(alpha: p.opacity * 0.32),
        );
        canvas.drawCircle(
          Offset(px, py),
          sz * 0.5,
          Paint()..color = p.color.withValues(alpha: p.opacity),
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: sz, height: sz),
          Paint()..color = p.color.withValues(alpha: p.opacity),
        );
      }
    }

    // 9. フローティングテキスト（最前面・4方向黒縁取り）
    for (final ft in animationController.activeFloatingTexts) {
      if (ft.opacity <= 0.01) continue;
      final centerX = offsetX + (ft.x + 0.5) * cellW;
      final centerY = offsetY + (ft.y + ft.yOffsetCells) * cellH;
      _drawOutlinedText(
        canvas,
        ft.text,
        ft.color.withValues(alpha: ft.opacity),
        Colors.black.withValues(
          alpha: (ft.opacity * tuning.floatingText.outlineAlpha).clamp(0.0, 1.0),
        ),
        centerX,
        centerY,
        (cellH * tuning.floatingText.fontSizeRatio * ft.scale).clamp(8.0, 26.0),
        fontWeight: FontWeight.w700,
      );
    }
  }

  void _drawAmbientStatus(
    Canvas canvas,
    AmbientCellStatusSnapshot status,
    double offsetX,
    double offsetY,
    double cellW,
    double cellH,
  ) {
    final mask = status.mask;
    final amb = animationController.tuning.ambient;
    final cellLeft = offsetX + (status.x + status.moveDx) * cellW;
    final cellTop = offsetY + (status.y + status.moveDy) * cellH;
    final rect = Rect.fromLTWH(cellLeft, cellTop, cellW, cellH);

    // スロットA: 外枠＆粒子（最上位 1 種のみ）
    // 石化 > 粘液化 > 窒息・溶岩・捕縛 > 食中毒・病気
    if ((mask & AmbientStatusBits.stoning) != 0) {
      _drawStatusFrame(
        canvas,
        rect,
        const Color(0xFFB0BEC5),
        const Color(0xFFFF6E6E),
        cellW,
        amb.frameStrokeRatio,
        amb.frameAlpha,
      );
      _drawCornerDots(canvas, rect, const Color(0xFFCFD8DC), status.phase, cellW);
    } else if ((mask & AmbientStatusBits.slimed) != 0) {
      _drawStatusFrame(
        canvas,
        rect,
        const Color(0xFF76FF03),
        const Color(0xFF64DD17),
        cellW,
        amb.frameStrokeRatio,
        amb.frameAlpha,
      );
      _drawCornerDots(canvas, rect, const Color(0xFFB2FF59), status.phase, cellW);
    } else if ((mask & AmbientStatusBits.strangledOrLava) != 0) {
      _drawStatusFrame(
        canvas,
        rect,
        const Color(0xFFFF5252),
        const Color(0xFFFF1744),
        cellW,
        amb.frameStrokeRatio,
        amb.frameAlpha,
      );
    } else if ((mask & AmbientStatusBits.sick) != 0) {
      _drawStatusFrame(
        canvas,
        rect,
        const Color(0xFFE040FB),
        const Color(0xFFAA00FF),
        cellW,
        amb.frameStrokeRatio,
        amb.frameAlpha,
      );
      _drawCornerDots(canvas, rect, const Color(0xFFEA80FC), status.phase, cellW);
    }

    // スロットB: 足元（全モードでステップ2の影＋上浮きを適用。非透過タイル時は浮遊弧も重ねて視認性を補う）
    if (useTiles && !isTransparentTileset && (mask & AmbientStatusBits.levitating) != 0) {
      final arcRect = Rect.fromLTWH(
        cellLeft + cellW * 0.14,
        cellTop + cellH * 0.78,
        cellW * 0.72,
        cellH * 0.22,
      );
      canvas.drawArc(
        arcRect,
        0.15,
        math.pi - 0.30,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, cellW * amb.arcStrokeRatio)
          ..color = Color(amb.arcColor),
      );
    }

    // スロットC: 左右中段（混乱の手 u.umconf の極小赤桃色光点）
    if ((mask & AmbientStatusBits.confusingHands) != 0) {
      final r = math.max(1.6, cellW * 0.08);
      final leftCenter = Offset(cellLeft + cellW * 0.12, cellTop + cellH * 0.54);
      final rightCenter = Offset(cellLeft + cellW * 0.88, cellTop + cellH * 0.54);
      final haloPaint = Paint()..color = const Color(0x55FF4081);
      final corePaint = Paint()..color = const Color(0xFFFF80AB);
      canvas.drawCircle(leftCenter, r * 1.7, haloPaint);
      canvas.drawCircle(leftCenter, r, corePaint);
      canvas.drawCircle(rightCenter, r * 1.7, haloPaint);
      canvas.drawCircle(rightCenter, r, corePaint);
    }

    // スロットD: 頭上バッジ（最上位 1 種のみ）
    // 睡眠(Zzz) > 麻痺・失神(||) > 混乱(?) > 朦朧(★) > 敵逃走(汗粒)
    final badgeCenterX = cellLeft + cellW * 0.5;
    final bobY = math.sin(status.phase) * cellH * amb.badgeBobAmplitude;
    final badgeCenterY = cellTop - cellH * 0.06 + bobY;
    final badgeFontSize = (cellH * amb.badgeFontSizeRatio).clamp(8.0, 18.0);

    if ((mask & AmbientStatusBits.sleep) != 0) {
      _drawOutlinedText(
        canvas,
        'Zzz',
        const Color(0xFF90CAF9),
        const Color(0xE6000000),
        badgeCenterX,
        badgeCenterY,
        badgeFontSize,
        fontWeight: FontWeight.w700,
      );
    } else if ((mask & AmbientStatusBits.paralyzed) != 0) {
      _drawParalyzedZigzag(canvas, badgeCenterX, badgeCenterY, cellW, cellH);
    } else if ((mask & AmbientStatusBits.confused) != 0) {
      _drawOutlinedText(
        canvas,
        '?',
        const Color(0xFFFFD54F),
        const Color(0xE6000000),
        badgeCenterX,
        badgeCenterY,
        badgeFontSize * 1.05,
        fontWeight: FontWeight.w800,
      );
    } else if ((mask & AmbientStatusBits.stunned) != 0) {
      _drawOutlinedText(
        canvas,
        '★',
        const Color(0xFFFFCA28),
        const Color(0xE6000000),
        badgeCenterX,
        badgeCenterY,
        badgeFontSize,
        fontWeight: FontWeight.w700,
      );
    } else if ((mask & AmbientStatusBits.fleeing) != 0) {
      _drawSweatDrop(canvas, cellLeft, cellTop, bobY, cellW, cellH);
    }
  }

  /// 麻痺・失神時の「痺れてビリビリしている黄色のギザギザ縦棒 2 本」を描画する
  void _drawParalyzedZigzag(
    Canvas canvas,
    double centerX,
    double centerY,
    double cellW,
    double cellH,
  ) {
    final totalH = math.max(9.0, cellH * 0.34);
    final zigW = math.max(1.8, cellW * 0.055);
    final halfGap = math.max(2.2, cellW * 0.085);
    final coreStroke = math.max(1.4, cellW * 0.05);
    final topY = centerY - totalH * 0.5;

    Path buildBolt(double baseX) {
      final p = Path()..moveTo(baseX - zigW * 0.4, topY);
      p.lineTo(baseX + zigW * 0.8, topY + totalH * 0.25);
      p.lineTo(baseX - zigW * 0.8, topY + totalH * 0.50);
      p.lineTo(baseX + zigW * 0.8, topY + totalH * 0.75);
      p.lineTo(baseX - zigW * 0.4, topY + totalH);
      return p;
    }

    final leftBolt = buildBolt(centerX - halfGap);
    final rightBolt = buildBolt(centerX + halfGap);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = coreStroke + 2.2
      ..color = const Color(0xE6000000);
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = coreStroke
      ..color = const Color(0xFFFFEA00);

    canvas.drawPath(leftBolt, outlinePaint);
    canvas.drawPath(rightBolt, outlinePaint);
    canvas.drawPath(leftBolt, corePaint);
    canvas.drawPath(rightBolt, corePaint);
  }

  /// 敵逃走時の「水色の汗マーク（水滴シルエット）」を描画する
  void _drawSweatDrop(
    Canvas canvas,
    double cellLeft,
    double cellTop,
    double bobY,
    double cellW,
    double cellH,
  ) {
    final tipX = cellLeft + cellW * 0.79;
    final tipY = cellTop + cellH * 0.02 + bobY;
    final dropH = math.max(7.5, cellH * 0.30);
    final dropW = dropH * 0.74;

    final path = Path()
      ..moveTo(tipX, tipY)
      ..cubicTo(
        tipX + dropW * 0.18,
        tipY + dropH * 0.32,
        tipX + dropW * 0.55,
        tipY + dropH * 0.58,
        tipX + dropW * 0.50,
        tipY + dropH * 0.76,
      )
      ..cubicTo(
        tipX + dropW * 0.45,
        tipY + dropH * 0.94,
        tipX + dropW * 0.22,
        tipY + dropH,
        tipX,
        tipY + dropH,
      )
      ..cubicTo(
        tipX - dropW * 0.22,
        tipY + dropH,
        tipX - dropW * 0.45,
        tipY + dropH * 0.94,
        tipX - dropW * 0.50,
        tipY + dropH * 0.76,
      )
      ..cubicTo(
        tipX - dropW * 0.55,
        tipY + dropH * 0.58,
        tipX - dropW * 0.18,
        tipY + dropH * 0.32,
        tipX,
        tipY,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, cellW * 0.06)
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xE6000000),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF40C4FF),
    );
    canvas.drawCircle(
      Offset(tipX - dropW * 0.14, tipY + dropH * 0.66),
      math.max(0.9, dropW * 0.13),
      Paint()..color = const Color(0xD9FFFFFF),
    );
  }

  void _drawStatusFrame(
    Canvas canvas,
    Rect rect,
    Color primary,
    Color accent,
    double cellW,
    double strokeRatio,
    double frameAlpha,
  ) {
    final stroke = math.max(1.2, cellW * strokeRatio);
    final inset = stroke * 0.5;
    final frameRect = rect.deflate(inset);
    canvas.drawRect(
      frameRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = primary.withValues(alpha: frameAlpha.clamp(0.0, 1.0)),
    );
    // 4隅に短いアクセントドットで視認性を補強
    final dot = math.max(1.5, cellW * 0.08);
    final cornerPaint = Paint()..color = accent.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(frameRect.left, frameRect.top, dot, dot), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(frameRect.right - dot, frameRect.top, dot, dot), cornerPaint);
    canvas.drawRect(Rect.fromLTWH(frameRect.left, frameRect.bottom - dot, dot, dot), cornerPaint);
    canvas.drawRect(
      Rect.fromLTWH(frameRect.right - dot, frameRect.bottom - dot, dot, dot),
      cornerPaint,
    );
  }

  void _drawCornerDots(
    Canvas canvas,
    Rect rect,
    Color color,
    double phase,
    double cellW,
  ) {
    final sz = math.max(1.5, cellW * 0.075);
    final shift = math.sin(phase) * cellW * 0.06;
    final paint = Paint()..color = color.withValues(alpha: 0.88);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(rect.left + rect.width * 0.22, rect.top + rect.height * 0.24 + shift),
        width: sz,
        height: sz,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(rect.right - rect.width * 0.22, rect.bottom - rect.height * 0.24 - shift),
        width: sz,
        height: sz,
      ),
      paint,
    );
  }

  void _drawOutlinedText(
    Canvas canvas,
    String text,
    Color fillColor,
    Color outlineColor,
    double centerX,
    double centerY,
    double fontSize, {
    FontWeight fontWeight = FontWeight.bold,
  }) {
    if (text.isEmpty) return;
    final roundedSize = (fontSize * 2).round() / 2.0;
    final fillTp = _getBadgeTextPainter(text, fillColor, roundedSize, fontWeight);
    final outlineTp = _getBadgeTextPainter(text, outlineColor, roundedSize, fontWeight);

    final left = centerX - fillTp.width / 2;
    final top = centerY - fillTp.height / 2;

    // 4方向黒縁取り（1px）
    outlineTp.paint(canvas, Offset(left - 1.0, top));
    outlineTp.paint(canvas, Offset(left + 1.0, top));
    outlineTp.paint(canvas, Offset(left, top - 1.0));
    outlineTp.paint(canvas, Offset(left, top + 1.0));
    fillTp.paint(canvas, Offset(left, top));
  }

  TextPainter _getBadgeTextPainter(
    String text,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final cacheKey = '$text|${color.toARGB32()}|$fontSize|${fontWeight.value}';
    var tp = _badgeTextCache[cacheKey];
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (_badgeTextCache.length >= 256) {
        _badgeTextCache.clear();
      }
      _badgeTextCache[cacheKey] = tp;
    }
    return tp;
  }

  void _drawBackgroundMask(
    Canvas canvas,
    GlyphData glyph,
    double cellLeft,
    double cellTop,
    double cellW,
    double cellH,
    int sheetCols,
  ) {
    final destRect = Rect.fromLTWH(cellLeft, cellTop, cellW, cellH);

    if (useTiles && tileImage != null && glyph.tile >= 0 && sheetCols > 0) {
      // まず黒下地で静止前面タイルを消去してから背景タイルを描く
      canvas.drawRect(destRect, Paint()..color = Colors.black);
      if (glyph.bktile >= 0) {
        canvas.drawImageRect(
          tileImage!,
          _tileSrcRect(glyph.bktile, sheetCols),
          destRect,
          Paint()..isAntiAlias = false,
        );
      }
      return;
    }

    // テキストモード：黒背景で静止前面文字を消去し、bkchar/bkcolor で背景地形を描画（穴あき防止）
    canvas.drawRect(destRect, Paint()..color = const Color(0xFF111111));
    if (glyph.bkchar.isNotEmpty && glyph.bkchar != ' ') {
      final bkColor = glyph.bkcolor != 0 ? Color(glyph.bkcolor | 0xFF000000) : Colors.grey;
      _drawTextChar(canvas, glyph.bkchar, bkColor, cellLeft, cellTop, cellW, cellH);
    }
  }

  void _drawForegroundGlyph(
    Canvas canvas,
    GlyphData glyph,
    double cellLeft,
    double cellTop,
    double cellW,
    double cellH,
    int sheetCols, {
    required double flashAlpha,
    required Color flashColor,
    int? fallbackTile,
    String? fallbackChar,
    int? fallbackColor,
  }) {
    final destRect = Rect.fromLTWH(cellLeft, cellTop, cellW, cellH);
    final isPet = (glyph.special & (NetHackMapPainter.mgPet | NetHackMapPainter.mgRidden)) != 0;
    final isPile = (glyph.special & NetHackMapPainter.mgObjPile) != 0;

    // `anim_event` が `printGlyph` より先行到着して移動先セルがまだ床のままの場合、
    // イベント付属のフォールバックグリフで 1 フレーム目から正確に描画する。
    final bool useFallbackTile =
        fallbackTile != null && fallbackTile >= 0 && (glyph.tile < 0 || glyph.tile == glyph.bktile);
    final int effectiveTile = useFallbackTile ? fallbackTile : glyph.tile;

    if (useTiles && tileImage != null && effectiveTile >= 0 && sheetCols > 0) {
      final paint = Paint()..isAntiAlias = false;
      if (flashAlpha > 0.01) {
        paint.colorFilter = ColorFilter.mode(
          flashColor.withValues(alpha: flashAlpha),
          BlendMode.srcATop,
        );
      }
      canvas.drawImageRect(
        tileImage!,
        _tileSrcRect(effectiveTile, sheetCols),
        destRect,
        paint,
      );

      if (isPet || isPile) {
        final dotSize = (cellW / 32.0 * 1.3).clamp(1.0, 3.0);
        if (isPet) {
          final heartStartX =
              cellLeft + cellW - (NetHackMapPainter.heartPattern[0].length * dotSize) - 1.5;
          NetHackMapPainter.drawPixelPattern(
            canvas,
            NetHackMapPainter.heartPattern,
            heartStartX,
            cellTop + 1.5,
            dotSize,
            const Color(0xFFFF2222),
          );
        }
        if (isPile) {
          NetHackMapPainter.drawPixelPattern(
            canvas,
            NetHackMapPainter.pilePattern,
            cellLeft + 1.5,
            cellTop + 1.5,
            dotSize,
            const Color(0xFF00FF44),
          );
        }
      }
      return;
    }

    // テキストモードの前面文字描画
    final bool useFallbackChar = fallbackChar != null &&
        fallbackChar.isNotEmpty &&
        fallbackChar != ' ' &&
        (glyph.char.isEmpty || glyph.char == ' ' || glyph.char == glyph.bkchar);
    final String effectiveChar = useFallbackChar ? fallbackChar : glyph.char;
    final int effectiveColor = useFallbackChar ? (fallbackColor ?? glyph.color) : glyph.color;

    if (effectiveChar.isEmpty || effectiveChar == ' ') return;

    if (isPet) {
      canvas.drawRect(
        destRect,
        Paint()
          ..color = flashAlpha > 0.01
              ? Color.lerp(const Color(0xFFDDDDDD), flashColor, flashAlpha)!
              : const Color(0xFFDDDDDD),
      );
    } else if (isPile) {
      canvas.drawRect(
        Rect.fromLTWH(cellLeft, cellTop + cellH - 2.0, cellW, 2.0),
        Paint()..color = const Color(0xFF00FF44),
      );
    }

    Color textColor = isPet
        ? Colors.black
        : (effectiveColor != 0 ? Color(effectiveColor | 0xFF000000) : Colors.white);
    if (flashAlpha > 0.01) {
      textColor = Color.lerp(textColor, flashColor, flashAlpha) ?? textColor;
    }

    _drawTextChar(canvas, effectiveChar, textColor, cellLeft, cellTop, cellW, cellH);
  }

  Rect _tileSrcRect(int tileIdx, int sheetCols) {
    final row = tileIdx ~/ sheetCols;
    final col = tileIdx % sheetCols;
    return Rect.fromLTWH(
      (col * tileWidth).toDouble(),
      (row * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
  }

  void _drawTextChar(
    Canvas canvas,
    String char,
    Color textColor,
    double cellLeft,
    double cellTop,
    double cellW,
    double cellH,
  ) {
    if (char.isEmpty || char == ' ') return;
    final activeFontId = fontId ?? FontManager.instance.getSelectedFont(FontTarget.map).id;
    final cacheKey = '$char|${textColor.toARGB32()}|$cellH|$activeFontId';

    var tp = _textCache[cacheKey];
    if (tp == null) {
      final style = FontManager.instance.getStyle(
        FontTarget.map,
        fontSize: cellH * 0.95,
        color: textColor,
        fontWeight: FontWeight.normal,
      );
      tp = TextPainter(
        text: TextSpan(text: char, style: style),
        strutStyle: StrutStyle(
          fontSize: cellH * 0.95,
          height: 1.0,
          forceStrutHeight: true,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (_textCache.length >= 512) {
        _textCache.clear();
      }
      _textCache[cacheKey] = tp;
    }

    tp.paint(
      canvas,
      Offset(
        cellLeft + (cellW - tp.width) / 2,
        cellTop + (cellH - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant NetHackAnimationOverlayPainter oldDelegate) {
    return oldDelegate.screen != screen ||
        oldDelegate.animationController != animationController ||
        oldDelegate.tileImage != tileImage ||
        oldDelegate.useTiles != useTiles ||
        oldDelegate.isTransparentTileset != isTransparentTileset ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight ||
        oldDelegate.fontId != fontId;
  }
}
