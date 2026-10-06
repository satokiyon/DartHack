import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../nethack_screen.dart';
import '../../utils/dialog_header_helper.dart';
import '../../utils/nethack_colors.dart';
import '../menu_item_tile_painter.dart';
import '../../input/hardware_key_router.dart';
import '../../utils/item_count_parser.dart';

class MenuOverlay extends StatefulWidget {
  final String menuPrompt;
  final List<MenuItemData> menuItems;
  final int menuHow;
  final Map<int, int> initialSelectedCounts;
  final String initialSearchQuery;
  final Function(int ident) onSingleSelect;
  final Function(Map<int, int> selectedCounts) onMultiSelect;
  final Function(MenuItemData item) onItemLongPress;
  final double bottomInset;
  final bool useTiles;
  final ui.Image? tileImage;
  final int tileWidth;
  final int tileHeight;

  const MenuOverlay({
    super.key,
    required this.menuPrompt,
    required this.menuItems,
    required this.menuHow,
    required this.initialSelectedCounts,
    required this.initialSearchQuery,
    required this.onSingleSelect,
    required this.onMultiSelect,
    required this.onItemLongPress,
    required this.bottomInset,
    required this.useTiles,
    required this.tileImage,
    required this.tileWidth,
    required this.tileHeight,
  });

  @override
  State<MenuOverlay> createState() => MenuOverlayState();
}

class MenuOverlayState extends State<MenuOverlay> {
  late TextEditingController _filterController;
  late String _filterQuery;
  late Map<int, int> _selectedCounts;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _filterQuery = widget.initialSearchQuery;
    _filterController = TextEditingController(text: _filterQuery);
    _selectedCounts = Map<int, int>.from(widget.initialSelectedCounts);
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant MenuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedCounts != oldWidget.initialSelectedCounts) {
      _selectedCounts = Map<int, int>.from(widget.initialSelectedCounts);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
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

  /// PageUp / PageDown / Space / < / > によるページ送り
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

  /// 外部（キー入力等）からの選択トグル
  void toggleSelectionById(int ident) {
    _toggleSelection(ident);
  }

  /// 外部（ダイアログ等）からの特定アイテムの選択個数更新
  void setSelectedCount(int ident, int count) {
    setState(() {
      if (count > 0) {
        _selectedCounts[ident] = count;
      } else {
        _selectedCounts.remove(ident);
      }
    });
  }

  Map<int, int> get selectedCounts => _selectedCounts;

  int _parseMaxCount(String text) => ItemCountParser.parseMaxCount(text);

  void _handleItemLongPress(MenuItemData item) {
    if (!ItemCountParser.isQuantitySelectionAllowed(widget.menuPrompt, widget.menuHow)) {
      // 個数指定が無効な画面ではガードし、通常の選択（またはトグル）として扱う
      if (widget.menuHow > 1) {
        _toggleSelection(item.ident);
      } else {
        widget.onSingleSelect(item.ident);
      }
      return;
    }
    widget.onItemLongPress(item);
  }

  bool _isMenuDividerText(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    return RegExp(r'^[-=\s]+$').hasMatch(t);
  }

  bool _isMenuCategoryItem(MenuItemData item) {
    if (item.ident != 0) return false;
    if (_isMenuDividerText(item.text)) return false;
    if (item.attr > 0) return true;
    return DialogHeaderHelper.isDialogTitleHeader(item.text);
  }

  void _toggleSelection(int ident) {
    if (ident == 0 || ident == 4294967294) return;
    setState(() {
      if (_selectedCounts.containsKey(ident)) {
        _selectedCounts.remove(ident);
      } else {
        try {
          final item = widget.menuItems.firstWhere((i) => i.ident == ident);
          final maxCount = _parseMaxCount(item.text);
          _selectedCounts[ident] = maxCount;
        } catch (_) {
          _selectedCounts[ident] = 1;
        }
      }
    });
  }

  /// 拡張コマンド検索時の Enter 決定処理（優先度: 完全一致 > 前方一致 > 部分一致 > 説明文一致）
  void _submitExtCmd(List<MenuItemData> filteredItems) {
    final query = _filterQuery.trim().toLowerCase();
    final selectableItems = filteredItems
        .where((i) => i.ident > 0 && i.ident != 4294967294 && !_isMenuCategoryItem(i))
        .toList();

    if (selectableItems.isEmpty) {
      // 候補がなく「(すべて表示)」項目がある場合はそれを選択して全コマンドを展開
      for (final item in widget.menuItems) {
        if (item.text.contains('(すべて表示)') || item.text.contains('(all)')) {
          if (item.ident > 0) {
            widget.onSingleSelect(item.ident);
          }
          return;
        }
      }
      return;
    }

    if (query.isEmpty) {
      widget.onSingleSelect(selectableItems.first.ident);
      return;
    }

    // 優先度 1: 完全一致
    for (final item in selectableItems) {
      final text = item.text.trim();
      final tabIdx = text.indexOf('\t');
      var cmd = (tabIdx >= 0 ? text.substring(0, tabIdx) : text).trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd == query) {
        widget.onSingleSelect(item.ident);
        return;
      }
    }

    // 優先度 2: 前方一致
    for (final item in selectableItems) {
      final text = item.text.trim();
      final tabIdx = text.indexOf('\t');
      var cmd = (tabIdx >= 0 ? text.substring(0, tabIdx) : text).trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd.startsWith(query)) {
        widget.onSingleSelect(item.ident);
        return;
      }
    }

    // 優先度 3: 部分一致
    for (final item in selectableItems) {
      final text = item.text.trim();
      final tabIdx = text.indexOf('\t');
      var cmd = (tabIdx >= 0 ? text.substring(0, tabIdx) : text).trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd.contains(query)) {
        widget.onSingleSelect(item.ident);
        return;
      }
    }

    // 優先度 4: 説明文一致 または 先頭項目
    widget.onSingleSelect(selectableItems.first.ident);
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

  Widget _buildTabSeparatedRow(
    String text,
    TextStyle baseStyle, {
    bool isHeader = false,
    String accLabel = "",
    String suffixLabel = "",
  }) {
    final parts = text.split('\t');
    if (parts.length < 2) {
      return Text(
        "$accLabel$text$suffixLabel",
        style: baseStyle,
      );
    }

    final children = <Widget>[];

    final List<double> colWidths;
    final List<TextAlign> colAligns;

    if (parts.length == 5) {
      colWidths = [0, 50, 45, 55, 45];
      colAligns = [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
        TextAlign.right,
        TextAlign.right,
      ];
    } else if (parts.length == 3) {
      colWidths = [0, 60, 120];
      colAligns = [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
      ];
    } else if (parts.length == 2) {
      colWidths = [0, 100];
      colAligns = [
        TextAlign.left,
        TextAlign.right,
      ];
    } else {
      colWidths = List.generate(parts.length, (index) => index == 0 ? 0.0 : 80.0);
      colAligns = List.generate(parts.length, (index) => index == 0 ? TextAlign.left : TextAlign.right);
    }

    for (int i = 0; i < parts.length; i++) {
      final partText = parts[i].trim();
      final displayStyle = isHeader
          ? baseStyle.copyWith(
              color: baseStyle.color?.withValues(alpha: 0.8) ?? Colors.white70,
              fontWeight: FontWeight.bold,
            )
          : baseStyle;

      var colText = partText;
      if (i == 0 && accLabel.isNotEmpty) {
        colText = "$accLabel$colText";
      }
      if (i == parts.length - 1 && suffixLabel.isNotEmpty) {
        colText = "$colText$suffixLabel";
      }

      final textWidget = Text(
        colText,
        style: displayStyle,
        textAlign: colAligns[i],
        overflow: TextOverflow.ellipsis,
      );

      if (colWidths[i] == 0) {
        children.add(Expanded(child: textWidget));
      } else {
        children.add(SizedBox(
          width: colWidths[i],
          child: textWidget,
        ));
      }

      if (i < parts.length - 1) {
        children.add(const SizedBox(width: 8));
      }
    }

    return Row(children: children);
  }

  Widget _buildMenuCategoryRow(String text) {
    final hasTab = text.contains('\t');
    if (!hasTab) {
      return DialogHeaderHelper.buildTitleHeaderBadge(text);
    }
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2214),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.label_important_outline_rounded, size: 16, color: Color(0xFFFFD54F)),
          SizedBox(width: hasTab ? 14 : 6),
          Expanded(
            child: _buildTabSeparatedRow(
              text,
              const TextStyle(
                color: Color(0xFFFFD54F),
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              isHeader: true,
            ),
          ),
        ],
      ),
    );
  }

  String _adjustMenuIndent(String rawText, int minLeadingSpaces) {
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
    final isExtCmdMenu = isExtCmdMenuPrompt(widget.menuPrompt);
    final isEnhanceMenu = widget.menuPrompt.contains("スキル") ||
        widget.menuPrompt.toLowerCase().contains("skill");
    final isMultiSelectMenu = !isExtCmdMenu && widget.menuHow > 1;
    final extCmdQuery = _filterQuery.trim().toLowerCase();

    final filteredItems = widget.menuItems.where((item) {
      final text = item.text.trim();
      if (isExtCmdMenu) {
        if (text == "#" || text == "?") {
          return false;
        }
        if (extCmdQuery.isEmpty) {
          return true;
        }
        final tabIndex = text.indexOf('\t');
        final commandText = (tabIndex >= 0 ? text.substring(0, tabIndex) : text).trim().toLowerCase();
        final descriptionText = (tabIndex >= 0 ? text.substring(tabIndex + 1) : "").trim().toLowerCase();
        return commandText.contains(extCmdQuery) || descriptionText.contains(extCmdQuery);
      }
      return true;
    }).toList();

    int minLeadingSpaces = 999;
    for (final item in filteredItems) {
      if (_isMenuCategoryItem(item) || _isMenuDividerText(item.text)) continue;
      if (item.text.trim().isEmpty) continue;

      int spaces = 0;
      while (spaces < item.text.length && item.text[spaces] == ' ') {
        spaces++;
      }
      if (spaces < minLeadingSpaces) {
        minLeadingSpaces = spaces;
      }
    }
    if (minLeadingSpaces == 999) minLeadingSpaces = 0;

    final hasTabMenu = filteredItems.any((item) => item.text.contains('\t'));

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
                if (widget.menuPrompt.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        isMultiSelectMenu ? Icons.checklist_rounded : Icons.menu_book_rounded,
                        size: 18,
                        color: Colors.amber[300],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.menuPrompt,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 8),
                ],
                if (isExtCmdMenu) ...[
                  TextField(
                    controller: _filterController,
                    autofocus: true,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _submitExtCmd(filteredItems),
                    decoration: InputDecoration(
                      hintText: l10n?.filterCmds ?? '拡張コマンドを検索...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0E1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _filterQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final listView = ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelectable = item.ident != 0 && item.ident != 4294967294 && !_isMenuCategoryItem(item);
                            final isCategory = _isMenuCategoryItem(item);
                            final isDivider = !isSelectable && _isMenuDividerText(item.text);
                            final isPlain = !isSelectable && !isCategory && !isDivider;
                            final isPrintableAccel = item.accelerator >= 0x21 && item.accelerator <= 0x7E;
                            final accLabel = isPrintableAccel
                                ? "${String.fromCharCode(item.accelerator)} - "
                                : "";

                            String commandText;
                            String descriptionText = "";
                            if (isExtCmdMenu) {
                              final itemText = item.text.trim();
                              final tabIndex = itemText.indexOf('\t');
                              if (tabIndex >= 0) {
                                commandText = itemText.substring(0, tabIndex).trim();
                                descriptionText = itemText.substring(tabIndex + 1).trim();
                              } else {
                                commandText = itemText;
                              }
                            } else {
                              commandText = _adjustMenuIndent(item.text, minLeadingSpaces);
                            }

                            if (isCategory) {
                              return _buildMenuCategoryRow(commandText);
                            }
                            if (isDivider) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                              );
                            }

                            Color itemColor = Colors.white;
                            if (!isExtCmdMenu && item.color >= 0 && item.color < 16) {
                              itemColor = NethackColors.getNhColor(item.color);
                            }

                            if (isPlain) {
                              final hasTab = commandText.contains('\t');
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Row(
                                  children: [
                                    _buildMenuItemTile(item.tile),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: hasTab
                                          ? _buildTabSeparatedRow(
                                              commandText,
                                              TextStyle(
                                                color: itemColor,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              accLabel: accLabel,
                                            )
                                          : Text(
                                              "$accLabel$commandText",
                                              style: TextStyle(
                                                color: itemColor,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (isMultiSelectMenu) {
                              final checked = _selectedCounts.containsKey(item.ident);
                              final selectedCount = _selectedCounts[item.ident] ?? 0;
                              final maxCount = _parseMaxCount(item.text);
                              final countLabel = checked
                                  ? (l10n?.selectedCountLabel(selectedCount, maxCount) ?? " ($selectedCount個選択中 / $maxCount)")
                                  : "";
                              final hasTab = commandText.contains('\t');
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                  horizontalTitleGap: 8,
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildMenuItemTile(item.tile),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: checked,
                                          onChanged: (_) => _toggleSelection(item.ident),
                                          activeColor: Colors.tealAccent[400],
                                          checkColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: hasTab
                                      ? _buildTabSeparatedRow(
                                          commandText,
                                          TextStyle(
                                            color: checked ? Colors.tealAccent[400] : itemColor,
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          accLabel: accLabel,
                                          suffixLabel: countLabel,
                                        )
                                      : Text(
                                          "$accLabel$commandText$countLabel",
                                          style: TextStyle(
                                            color: checked ? Colors.tealAccent[400] : itemColor,
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                  onTap: () => _toggleSelection(item.ident),
                                  onLongPress: () => _handleItemLongPress(item),
                                ),
                              );
                            }

                            if (isExtCmdMenu) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white12, width: 1.0),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Material(
                                    color: const Color(0xFF2C2C2C),
                                    borderRadius: BorderRadius.circular(8.0),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                      horizontalTitleGap: 8,
                                      leading: _buildMenuItemTile(item.tile),
                                      title: Text(
                                        "$accLabel$commandText",
                                        style: TextStyle(
                                          color: itemColor,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: descriptionText.isNotEmpty
                                          ? Text(
                                              descriptionText,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      onTap: () => widget.onSingleSelect(item.ident),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (isEnhanceMenu && isSelectable) {
                              final hasTab = commandText.contains('\t');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                      horizontalTitleGap: 8,
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildMenuItemTile(item.tile),
                                          if (isPrintableAccel) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.amber.withValues(alpha: 0.6),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                String.fromCharCode(item.accelerator),
                                                style: const TextStyle(
                                                  color: Color(0xFFFFD54F),
                                                  fontFamily: 'monospace',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          hasTab
                                              ? _buildTabSeparatedRow(
                                                  commandText,
                                                  const TextStyle(
                                                    color: Color(0xFFFFE082),
                                                    fontFamily: 'monospace',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                )
                                              : Text(
                                                  commandText,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFFE082),
                                                    fontFamily: 'monospace',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                        ],
                                      ),
                                      trailing: const Icon(
                                        Icons.upgrade_rounded,
                                        color: Color(0xFFFFD54F),
                                        size: 22,
                                      ),
                                      onTap: () => widget.onSingleSelect(item.ident),
                                      onLongPress: () => _handleItemLongPress(item),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final hasTab = commandText.contains('\t');
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                horizontalTitleGap: 8,
                                leading: _buildMenuItemTile(item.tile),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    hasTab
                                        ? _buildTabSeparatedRow(
                                            commandText,
                                            TextStyle(
                                              color: itemColor,
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            accLabel: accLabel,
                                          )
                                        : Text(
                                            "$accLabel$commandText",
                                            style: TextStyle(
                                              color: itemColor,
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ],
                                ),
                                onTap: () => widget.onSingleSelect(item.ident),
                                onLongPress: () => _handleItemLongPress(item),
                              ),
                            );
                          },
                        );
                        return hasTabMenu
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: constraints.maxWidth > 480 ? constraints.maxWidth : 480,
                                  child: listView,
                                ),
                              )
                            : listView;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (isMultiSelectMenu) ...[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCounts = <int, int>{};
                              for (final item in filteredItems) {
                                if (item.ident != 0 && item.ident != 4294967294 && !_isMenuCategoryItem(item)) {
                                  _selectedCounts[item.ident] = _parseMaxCount(item.text);
                                }
                              }
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.selectAll),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCounts.clear();
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.deselectAll),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final cleanCounts = <int, int>{};
                            _selectedCounts.forEach((ident, count) {
                              if (ident != 0 && ident != 4294967294) {
                                cleanCounts[ident] = count;
                              }
                            });
                            widget.onMultiSelect(cleanCounts);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40), // 深いダークティール (決定ボタンとして際立たせる)
                          ),
                          child: const Text("OK"),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: () => widget.onSingleSelect(-1),
                        child: Text(AppLocalizations.of(context)!.cancel),
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
