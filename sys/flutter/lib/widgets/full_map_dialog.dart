import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../nethack_screen.dart';
import '../nethack_map_painter.dart';

void showFullMapDialog({
  required BuildContext context,
  required NetHackScreen screen,
  required bool useTiles,
  required ui.Image? tileImage,
  required int tileWidth,
  required int tileHeight,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final cellW = useTiles ? 32.0 : 9.0;
      final cellH = useTiles ? 32.0 : 16.0;
      final mapWidth = NetHackScreen.mapCols * cellW;
      final mapHeight = NetHackScreen.mapRows * cellH;

      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.deepPurple[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '階層の全体地図',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: CustomPaint(
                        painter: NetHackMapPainter(
                          screen: screen,
                          tileImage: tileImage,
                          tileWidth: tileWidth,
                          tileHeight: tileHeight,
                          useTiles: useTiles,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ピンチ操作でズームイン/ズームアウトが可能です',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
