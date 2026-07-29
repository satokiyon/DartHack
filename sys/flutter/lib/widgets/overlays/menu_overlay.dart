import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../nethack_screen.dart';
import '../menu_item_tile_painter.dart';

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
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay> {
  late TextEditingController _filterController;
  late String _filterQuery;
  late Map<int, int> _selectedCounts;

  @override
  void initState() {
    super.initState();
    _filterQuery = widget.initialSearchQuery;
    _filterController = TextEditingController(text: _filterQuery);
    _selectedCounts = Map<int, int>.from(widget.initialSelectedCounts);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Color _getNhColor(int colorIndex) {
    switch (colorIndex) {
      case 0: return Colors.black;
      case 1: return Colors.red;
      case 2: return Colors.green;
      case 3: return const Color(0xFF8B4513);
      case 4: return Colors.blue;
      case 5: return Colors.purple;
      case 6: return Colors.cyan;
      case 7: return Colors.grey;
      case 8: return Colors.white70;
      case 9: return Colors.orange;
      case 10: return Colors.lightGreen;
      case 11: return Colors.yellow;
      case 12: return Colors.lightBlue;
      case 13: return Colors.pinkAccent;
      case 14: return Colors.cyanAccent;
      case 15: return Colors.white;
      default: return Colors.white;
    }
  }

  int _parseMaxCount(String text) {
    final trimmed = text.trim();
    int count = 0;
    int i = 0;
    while (i < trimmed.length) {
      final code = trimmed.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        count = count * 10 + (code - 48);
        i++;
      } else {
        break;
      }
    }
    return count > 0 ? count : 1;
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
    final t = item.text.trim();
    return t.endsWith(':') || t.endsWith('：');
  }

  void _toggleSelection(int ident) {
    if (ident == 0) return;
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
            child: hasTab
                ? _buildTabSeparatedRow(
                    text,
                    const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    isHeader: true,
                  )
                : Text(
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
    final isExtCmdMenu = widget.menuPrompt.contains("拡張コマンド");
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
      return !text.startsWith('#') && !text.startsWith('?');
    }).toList();

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
                    decoration: InputDecoration(
                      hintText: '拡張コマンドを検索...',
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelectable = item.ident != 0;
                            final isCategory = _isMenuCategoryItem(item);
                            final isDivider = !isSelectable && _isMenuDividerText(item.text);
                            final isPlain = !isSelectable && !isCategory && !isDivider;
                            final isPrintableAccel = item.accelerator >= 0x21 && item.accelerator <= 0x7E;
                            final accLabel = isPrintableAccel
                                ? "${String.fromCharCode(item.accelerator)} - "
                                : "";
                            final itemText = item.text.trim();

                            String commandText = itemText;
                            String descriptionText = "";
                            if (isExtCmdMenu) {
                              final tabIndex = itemText.indexOf('\t');
                              if (tabIndex >= 0) {
                                commandText = itemText.substring(0, tabIndex).trim();
                                descriptionText = itemText.substring(tabIndex + 1).trim();
                              }
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
                              itemColor = _getNhColor(item.color);
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
                              final countLabel = checked ? " ($selectedCount個選択中 / $maxCount)" : "";
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
                                  onLongPress: () => widget.onItemLongPress(item),
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
                                onLongPress: () => widget.onItemLongPress(item),
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
                                if (item.ident != 0) {
                                  _selectedCounts[item.ident] = _parseMaxCount(item.text);
                                }
                              }
                            });
                          },
                          child: const Text("全て選択"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCounts.clear();
                            });
                          },
                          child: const Text("解除"),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.onMultiSelect(_selectedCounts),
                          child: const Text("OK"),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: () => widget.onSingleSelect(-1),
                        child: const Text("キャンセル"),
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
