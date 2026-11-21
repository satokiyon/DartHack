import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../nethack_screen.dart';
import '../services/font_manager.dart';
import '../utils/nethack_colors.dart';
import 'menu_item_tile_painter.dart';

/// ステータスバー（上／下／左／右）とマップ、常時表示インベントリ（最外側フルハイト）を組み立てるレイアウト関数
Widget buildGameSplitLayout({
  required String statusPosition,
  required Widget mapWidget,
  required Widget horizontalStatusWidget,
  required Widget Function(bool isRight) buildVerticalStatusPanel,
  required bool showPermInvent,
  required String permInventPosition,
  required Widget? permInventWidget,
}) {
  final Widget statusAndMap;
  if (statusPosition == 'left') {
    statusAndMap = Row(
      children: [
        buildVerticalStatusPanel(false),
        Expanded(child: mapWidget),
      ],
    );
  } else if (statusPosition == 'right') {
    statusAndMap = Row(
      children: [
        Expanded(child: mapWidget),
        buildVerticalStatusPanel(true),
      ],
    );
  } else if (statusPosition == 'bottom') {
    statusAndMap = Column(
      children: [
        Expanded(child: mapWidget),
        horizontalStatusWidget,
      ],
    );
  } else {
    statusAndMap = Column(
      children: [
        horizontalStatusWidget,
        Expanded(child: mapWidget),
      ],
    );
  }

  if (!showPermInvent || permInventWidget == null) {
    return statusAndMap;
  }

  return Row(
    children: permInventPosition == 'left'
        ? [
            permInventWidget,
            Expanded(child: statusAndMap),
          ]
        : [
            Expanded(child: statusAndMap),
            permInventWidget,
          ],
  );
}

/// 横長画面で画面最上部〜最下部の最外側ペインとして表示する常時表示インベントリ (`perm_invent`) パネル
class PermanentInventoryPanel extends StatelessWidget {
  final ValueNotifier<PermInventState> permInventNotifier;
  final ScrollController scrollController;
  final double width;
  final bool isLeftSide;
  final bool isScrollMode;
  final bool canTapItem;
  final bool useTiles;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;
  final double? fontSize;
  final ValueChanged<MenuItemData>? onItemTap;

  const PermanentInventoryPanel({
    super.key,
    required this.permInventNotifier,
    required this.scrollController,
    required this.width,
    required this.isLeftSide,
    required this.isScrollMode,
    required this.canTapItem,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
    this.fontSize,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleText = l10n?.permInventTitle ?? 'Inventory';
    final scrollHintText =
        l10n?.permInventScrollModeHint ?? 'Focused (a-z:Item / ↑↓/PgUp/PgDn/Space/Enter/Esc)';
    final emptyText = l10n?.permInventEmpty ?? 'Not carrying anything';

    final borderColor = isScrollMode ? Colors.amberAccent : Colors.white24;
    final borderWidth = isScrollMode ? 2.0 : 1.0;

    return ListenableBuilder(
      listenable: FontManager.instance,
      builder: (context, _) {
        final effectiveFontSize = fontSize ?? FontManager.instance.permInventFontSize;
        final headerFontSize = (effectiveFontSize + 0.5).clamp(10.0, 32.0);
        final hintFontSize = (effectiveFontSize * 0.8).clamp(9.5, 22.0);

        return Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF101216),
            border: Border(
              left: isLeftSide
                  ? BorderSide.none
                  : BorderSide(color: borderColor, width: borderWidth),
              right: isLeftSide
                  ? BorderSide(color: borderColor, width: borderWidth)
                  : BorderSide.none,
              top: isScrollMode
                  ? BorderSide(color: borderColor, width: borderWidth)
                  : BorderSide.none,
              bottom: isScrollMode
                  ? BorderSide(color: borderColor, width: borderWidth)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isScrollMode ? const Color(0xFF2E2612) : const Color(0xFF1A1D24),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: FontManager.instance.getStyle(
                        FontTarget.permInvent,
                        color: isScrollMode ? Colors.amberAccent : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                      ),
                    ),
                    if (isScrollMode) ...[
                      const SizedBox(height: 2),
                      Text(
                        scrollHintText,
                        style: FontManager.instance.getStyle(
                          FontTarget.permInvent,
                          color: Colors.amberAccent,
                          fontSize: hintFontSize,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<PermInventState>(
                  valueListenable: permInventNotifier,
                  builder: (context, state, _) {
                    final items = state.items;
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          emptyText,
                          style: FontManager.instance.getStyle(
                            FontTarget.permInvent,
                            color: Colors.white54,
                            fontSize: effectiveFontSize,
                          ),
                          softWrap: true,
                        ),
                      );
                    }

                    return Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildRow(item, effectiveFontSize);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(MenuItemData item, double effectiveFontSize) {
    final bool isHeader = item.ident == 0 && item.accelerator == 0;
    final bool isTappable = !isHeader &&
        canTapItem &&
        item.accelerator > 0 &&
        onItemTap != null;

    if (isHeader) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2),
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: Text(
          item.text,
          style: FontManager.instance.getStyle(
            FontTarget.permInvent,
            color: Colors.amberAccent,
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.bold,
          ),
          softWrap: true,
        ),
      );
    }

    final textColor = NethackColors.getNhColor(item.color);
    final accText = item.accelerator > 0
        ? '${String.fromCharCode(item.accelerator)} - '
        : '';
    final showTile = useTiles && tileImage != null && item.tile >= 0;
    final double tileDisplaySize = (effectiveFontSize * 1.45).clamp(16.0, 36.0);

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTile) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 5),
              child: SizedBox(
                width: tileDisplaySize,
                height: tileDisplaySize,
                child: CustomPaint(
                  painter: MenuItemTilePainter(
                    image: tileImage!,
                    tileIndex: item.tile,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                  ),
                ),
              ),
            ),
          ],
          if (accText.isNotEmpty)
            Text(
              accText,
              style: FontManager.instance.getStyle(
                FontTarget.permInvent,
                color: Colors.lightBlueAccent,
                fontSize: effectiveFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          Expanded(
            child: Text(
              item.text,
              style: FontManager.instance.getStyle(
                FontTarget.permInvent,
                color: textColor,
                fontSize: effectiveFontSize,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );

    if (!isTappable) {
      return rowContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemTap?.call(item),
        borderRadius: BorderRadius.circular(4),
        child: rowContent,
      ),
    );
  }
}
