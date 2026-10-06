import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final cellW = useTiles ? 32.0 : 9.0;
      final cellH = useTiles ? 32.0 : 16.0;
      final mapWidth = NetHackScreen.mapCols * cellW;
      final mapHeight = NetHackScreen.mapRows * cellH;

      final mediaQuery = MediaQuery.of(context);
      final isPortrait = mediaQuery.orientation == Orientation.portrait;

      final mapWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
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
      );

      Widget dialogContent = Column(
        mainAxisSize: isPortrait ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            color: Colors.deepPurple[900],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.fullLevelMap,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
          if (isPortrait)
            Expanded(child: mapWidget)
          else
            Flexible(child: mapWidget),
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.pinchToZoom,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );

      if (isPortrait) {
        dialogContent = SizedBox(
          width: double.infinity,
          height: mediaQuery.size.height * 0.65,
          child: dialogContent,
        );
      }

      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.deepPurpleAccent, width: 1.5),
        ),
        child: dialogContent,
      );
    },
  );
}
