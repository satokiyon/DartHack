import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/text_formatter.dart';
import '../../utils/dialog_header_helper.dart';
import '../../models/tombstone_data.dart';
import '../../models/topten_entry.dart';
import '../tombstone_widget.dart';
import '../topten_widget.dart';
import '../menu_item_tile_painter.dart';

class TextOverlay extends StatefulWidget {
  final List<String> textLines;
  final List<int> textAttrs;
  final List<int> textTiles;
  final bool isPlainDialog;
  final int plainType;
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
    this.plainType = 0,
    required this.tombstoneDisplayMode,
    required this.onDismiss,
    required this.onShowMsgHistory,
    required this.bottomInset,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  State<TextOverlay> createState() => TextOverlayState();
}

class TextOverlayState extends State<TextOverlay> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Space キー処理: スクロール余地があれば1ページ下へ、最下部に達していれば閉じる
  void handleSpace() {
    if (_scrollController.hasClients &&
        _scrollController.offset < _scrollController.position.maxScrollExtent - 5.0) {
      final viewport = _scrollController.position.viewportDimension;
      final step = viewport > 0 ? viewport * 0.85 : 320.0;
      final nextOffset = (_scrollController.offset + step)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        nextOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } else {
      widget.onDismiss();
    }
  }

  /// 矢印キー（↑ / ↓）による行スクロール
  void scroll(int direction) {
    if (!_scrollController.hasClients) return;
    const step = 40.0;
    final nextOffset = (_scrollController.offset + direction * step)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  /// PageUp / PageDown / < / > によるページ送り
  void pageScroll(int direction) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final step = viewport > 0 ? viewport * 0.85 : 320.0;
    final nextOffset = (_scrollController.offset + direction * step)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  Widget _buildMenuItemTile(int tile) {
    if (!widget.useTiles || widget.tileImage == null || tile < 0) {
      return const SizedBox(width: 24, height: 24);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: MenuItemTilePainter(
          image: widget.tileImage!,
          tileIndex: tile,
          tileWidth: widget.tileWidth,
          tileHeight: widget.tileHeight,
        ),
      ),
    );
  }

  String _adjustTextIndent(String rawText, int minLeadingSpaces) {
    if (minLeadingSpaces <= 0) return rawText.trimRight();
    int spaces = 0;
    while (spaces < rawText.length && rawText[spaces] == ' ') {
      spaces++;
    }
    int spacesToRemove = spaces < minLeadingSpaces ? spaces : minLeadingSpaces;
    return rawText.substring(spacesToRemove).trimRight();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomInset),
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
                    final isTombstone = widget.textLines.length >= 13 &&
                        ((widget.textLines.any((line) => line.contains('REST')) &&
                            widget.textLines.any((line) => line.contains('PEACE'))) ||
                        widget.textLines.any((line) => line.contains('REST    \\')));

                    if (isTombstone) {
                      if (widget.tombstoneDisplayMode == 0) {
                        final data = TombstoneData.parse(widget.textLines);
                        return UniversalTombstoneWidget(
                          mode: TombstoneDisplayMode.image,
                          data: data,
                          lines: widget.textLines,
                        );
                      }
                      return UniversalTombstoneWidget(
                        mode: TombstoneDisplayMode.text,
                        lines: widget.textLines,
                      );
                    }

                    final isTopTen = widget.textLines.any((line) {
                      final l = line.toLowerCase();
                      return (line.contains('順位') && line.contains('点数') && line.contains('名前')) ||
                          (l.contains('no') && l.contains('points') && l.contains('name'));
                    });

                    if (isTopTen) {
                      final isJp = Localizations.localeOf(context).languageCode == 'ja';
                      final data = TopTenEntry.parse(widget.textLines, widget.textAttrs, isJp: isJp);
                      return TopTenWidget(entries: data, isJp: isJp);
                    }

                    final hasAnyTile = widget.useTiles && widget.tileImage != null && widget.textTiles.any((t) => t >= 0);

                    bool shouldReformat = false;

                    // 1. Cコアからの明示的なプレーンテキスト種別フラグ判定
                    // PLAIN_TEXT_QUEST = 2 (クエスト文章), PLAIN_TEXT_DATABASE = 3 (データベース検索結果)
                    if (widget.plainType == 2 || widget.plainType == 3) {
                      shouldReformat = true;
                    } else {
                      // 2. 先頭10行のスキャンによるオプトイン判定 (小説、歴史、ライセンスのみ)
                      for (int i = 0; i < widget.textLines.length && i < 10; i++) {
                        final l = widget.textLines[i].trim();

                        // 小説 (tribute / tribute_jp)
                        if (l.contains('Terry Pratchett') ||
                            l.contains('テリー・プラチェット 著') ||
                            l.contains('『魔法の色』')) {
                          shouldReformat = true;
                          break;
                        }

                        // 一般ヘルプのうち「NetHack の簡易な歴史」と「NetHack ライセンス」
                        if (l.contains('NetHack 5.0 版履歴ファイル') ||
                            l.contains('NetHack History file for release') ||
                            l.contains('見よ、定命の者よ。NetHackの起源を') ||
                            l.contains('Behold, mortal, the origins of NetHack') ||
                            l.contains('NETHACK GENERAL PUBLIC LICENSE') ||
                            l.contains('NetHack General Public License')) {
                          shouldReformat = true;
                          break;
                        }
                      }
                    }

                    final displayLines = shouldReformat
                        ? TextFormatter.reformatLines(widget.textLines)
                        : widget.textLines;

                    int minLeadingSpaces = 999;
                    for (final line in displayLines) {
                      final trimmed = line.trim();
                      if (trimmed.isEmpty || RegExp(r'^[-=\s]+$').hasMatch(trimmed)) continue;
                      if (DialogHeaderHelper.isDialogTitleHeader(line)) continue;

                      int spaces = 0;
                      while (spaces < line.length && line[spaces] == ' ') {
                        spaces++;
                      }
                      if (spaces < minLeadingSpaces) {
                        minLeadingSpaces = spaces;
                      }
                    }
                    if (minLeadingSpaces == 999) minLeadingSpaces = 0;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: displayLines.length,
                        itemBuilder: (context, index) {
                          final line = displayLines[index];
                          final trimmed = line.trim();
                          final isDivider = trimmed.isEmpty || RegExp(r'^[-=\s]+$').hasMatch(trimmed);

                          if (isDivider) {
                            if (trimmed.isEmpty) {
                              return const SizedBox(height: 6);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                            );
                          }

                          if (DialogHeaderHelper.isDialogTitleHeader(line)) {
                            return DialogHeaderHelper.buildTitleHeaderBadge(line);
                          }

                          final displayLine = _adjustTextIndent(line, minLeadingSpaces);
                          final tile = (index < widget.textTiles.length)
                              ? widget.textTiles[index]
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
                                    displayLine,
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
                        onPressed: widget.onShowMsgHistory,
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text(l10n?.history ?? 'History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[900],
                          foregroundColor: Colors.amber[200],
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: widget.onDismiss,
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
