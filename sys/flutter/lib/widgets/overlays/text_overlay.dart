import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/tombstone_data.dart';
import '../../models/topten_entry.dart';
import '../tombstone_widget.dart';
import '../topten_widget.dart';
import '../menu_item_tile_painter.dart';

class TextOverlay extends StatelessWidget {
  final List<String> textLines;
  final List<int> textAttrs;
  final List<int> textTiles;
  final bool isPlainDialog;
  final int tombstoneDisplayMode;
  final VoidCallback onDismiss;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;
  final bool useTiles;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;

  const TextOverlay({
    super.key,
    required this.textLines,
    required this.textAttrs,
    required this.textTiles,
    required this.isPlainDialog,
    required this.tombstoneDisplayMode,
    required this.onDismiss,
    required this.onShowMsgHistory,
    required this.bottomInset,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
  });

  Widget _buildMenuItemTile(int tile) {
    if (!useTiles || tileImage == null || tile < 0) {
      return const SizedBox(width: 24, height: 24);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: MenuItemTilePainter(
          image: tileImage!,
          tileIndex: tile,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
        ),
      ),
    );
  }

  Widget _buildMenuCategoryRow(String text) {
    final hasTab = text.contains('\t');
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 16, color: Colors.lightBlueAccent),
          SizedBox(width: hasTab ? 14 : 6),
          Expanded(
            child: Text(
              text.trim(),
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        child: Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFF12161D),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: () {
                    final isTombstone = textLines.length >= 13 &&
                        ((textLines.any((line) => line.contains('REST')) &&
                            textLines.any((line) => line.contains('PEACE'))) ||
                        textLines.any((line) => line.contains('REST    \\')));

                    if (isTombstone) {
                      if (tombstoneDisplayMode == 0) {
                        final data = TombstoneData.parse(textLines);
                        return UniversalTombstoneWidget(
                          mode: TombstoneDisplayMode.image,
                          data: data,
                          lines: textLines,
                        );
                      }
                      return UniversalTombstoneWidget(
                        mode: TombstoneDisplayMode.text,
                        lines: textLines,
                      );
                    }

                    final isTopTen = textLines.any((line) =>
                        line.contains('順位') &&
                        line.contains('点数') &&
                        line.contains('名前'));

                    if (isTopTen) {
                      final data = TopTenEntry.parse(textLines, textAttrs);
                      return TopTenWidget(entries: data);
                    }

                    final hasAnyTile = useTiles && tileImage != null && textTiles.any((t) => t >= 0);

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: textLines.length,
                        itemBuilder: (context, index) {
                          final line = textLines[index];
                          final trimmed = line.trim();
                          final isDivider = trimmed.isEmpty || RegExp(r'^[-=\s]+$').hasMatch(trimmed);
                          final isCategory = !isDivider && (trimmed.endsWith(':') || trimmed.endsWith('：'));

                          if (isCategory) {
                            return _buildMenuCategoryRow(line);
                          }
                          if (isDivider) {
                            if (trimmed.isEmpty) {
                              return const SizedBox(height: 6);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                            );
                          }

                          final tile = (index < textTiles.length)
                              ? textTiles[index]
                              : -1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (hasAnyTile) ...[
                                  _buildMenuItemTile(tile),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    line,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }(),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onShowMsgHistory,
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('履歴'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Colors.amber[200],
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
