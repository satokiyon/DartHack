import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class GameDrawerContent extends StatefulWidget {
  final bool isGameRunning;
  final bool isKeyboardVisible;
  final VoidCallback onClose;
  final VoidCallback onSaveAndExit;
  final VoidCallback onQuit;
  final VoidCallback onShowScoreboard;
  final VoidCallback onShowGuidebook;
  final VoidCallback onShowSpoilers;
  final VoidCallback onShowHelp;
  final VoidCallback onDatabaseSearch;
  final VoidCallback onOpenOptions;
  final VoidCallback onShowFullMap;
  final VoidCallback onToggleKeyboard;
  final VoidCallback onShowSettings;

  const GameDrawerContent({
    super.key,
    required this.isGameRunning,
    required this.isKeyboardVisible,
    required this.onClose,
    required this.onSaveAndExit,
    required this.onQuit,
    required this.onShowScoreboard,
    required this.onShowGuidebook,
    required this.onShowSpoilers,
    required this.onShowHelp,
    required this.onDatabaseSearch,
    required this.onOpenOptions,
    required this.onShowFullMap,
    required this.onToggleKeyboard,
    required this.onShowSettings,
  });

  @override
  State<GameDrawerContent> createState() => _GameDrawerContentState();
}

class _DrawerItemDef {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final GlobalKey key = GlobalKey();

  _DrawerItemDef({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });
}

class _GameDrawerContentState extends State<GameDrawerContent> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_DrawerItemDef> _buildItems(AppLocalizations l10n) {
    final items = <_DrawerItemDef>[];

    if (widget.isGameRunning) {
      items.add(_DrawerItemDef(
        icon: Icons.save,
        iconColor: Colors.greenAccent,
        title: l10n.menuSaveQuit,
        onTap: () {
          widget.onClose();
          widget.onSaveAndExit();
        },
      ));
      items.add(_DrawerItemDef(
        icon: Icons.dangerous,
        iconColor: Colors.redAccent,
        title: l10n.menuQuitWithoutSave,
        onTap: () {
          widget.onClose();
          widget.onQuit();
        },
      ));
    }

    items.add(_DrawerItemDef(
      icon: Icons.emoji_events,
      iconColor: Colors.amber,
      title: l10n.scoreboard,
      onTap: () {
        widget.onClose();
        widget.onShowScoreboard();
      },
    ));
    items.add(_DrawerItemDef(
      icon: Icons.menu_book,
      iconColor: Colors.lightBlueAccent,
      title: l10n.readGuidebook,
      onTap: () {
        widget.onClose();
        widget.onShowGuidebook();
      },
    ));
    items.add(_DrawerItemDef(
      icon: Icons.auto_stories,
      iconColor: Colors.amberAccent,
      title: l10n.readSpoilers,
      onTap: () {
        widget.onClose();
        widget.onShowSpoilers();
      },
    ));

    if (widget.isGameRunning) {
      items.add(_DrawerItemDef(
        icon: Icons.help_outline,
        iconColor: Colors.tealAccent,
        title: l10n.showHelp,
        onTap: () {
          widget.onClose();
          widget.onShowHelp();
        },
      ));
      items.add(_DrawerItemDef(
        icon: Icons.search,
        iconColor: Colors.orangeAccent,
        title: l10n.dbSearch,
        onTap: () {
          widget.onClose();
          widget.onDatabaseSearch();
        },
      ));
      items.add(_DrawerItemDef(
        icon: Icons.tune,
        iconColor: Colors.cyanAccent,
        title: l10n.gameOptions,
        onTap: () {
          widget.onClose();
          widget.onOpenOptions();
        },
      ));
      items.add(_DrawerItemDef(
        icon: Icons.map,
        iconColor: Colors.amberAccent,
        title: l10n.showFullMap,
        onTap: () {
          widget.onClose();
          widget.onShowFullMap();
        },
      ));
    }

    items.add(_DrawerItemDef(
      icon: widget.isKeyboardVisible ? Icons.videogame_asset_off : Icons.videogame_asset,
      iconColor: Colors.blueAccent,
      title: widget.isKeyboardVisible ? l10n.hideKeyboard : l10n.showKeyboard,
      onTap: () {
        widget.onClose();
        widget.onToggleKeyboard();
      },
    ));

    items.add(_DrawerItemDef(
      icon: Icons.settings,
      iconColor: Colors.grey,
      title: l10n.openSettings,
      onTap: () {
        widget.onClose();
        widget.onShowSettings();
      },
    ));

    return items;
  }

  void _scrollToItem(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: 0.5,
        );
      }
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;

    if (!isDown && !isRepeat) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // ドロワー閉鎖キー: Escape, F10, ContextMenu, Ctrl+M
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.f10 ||
        key == LogicalKeyboardKey.contextMenu ||
        (isCtrl && key == LogicalKeyboardKey.keyM)) {
      if (isDown) {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }

    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(l10n);
    if (items.isEmpty) return KeyEventResult.ignored;

    // ↓ / Tab / j : 次の項目へ（末尾超えで none に復帰）
    if ((key == LogicalKeyboardKey.arrowDown) ||
        (key == LogicalKeyboardKey.tab && !isShift) ||
        (key == LogicalKeyboardKey.keyJ && !isCtrl)) {
      if (isDown || isRepeat) {
        setState(() {
          if (_focusedIndex == null) {
            _focusedIndex = 0;
          } else if (_focusedIndex! < items.length - 1) {
            _focusedIndex = _focusedIndex! + 1;
          } else {
            _focusedIndex = null; // none に復帰
          }
        });
        if (_focusedIndex != null) {
          _scrollToItem(items[_focusedIndex!].key);
        }
      }
      return KeyEventResult.handled;
    }

    // ↑ / Shift+Tab / k : 前の項目へ（先頭前で none に復帰）
    if ((key == LogicalKeyboardKey.arrowUp) ||
        (key == LogicalKeyboardKey.tab && isShift) ||
        (key == LogicalKeyboardKey.keyK && !isCtrl)) {
      if (isDown || isRepeat) {
        setState(() {
          if (_focusedIndex == null) {
            _focusedIndex = items.length - 1;
          } else if (_focusedIndex! > 0) {
            _focusedIndex = _focusedIndex! - 1;
          } else {
            _focusedIndex = null; // none に復帰
          }
        });
        if (_focusedIndex != null) {
          _scrollToItem(items[_focusedIndex!].key);
        }
      }
      return KeyEventResult.handled;
    }

    // Home / ^ : 先頭項目へ
    if (key == LogicalKeyboardKey.home) {
      if (isDown) {
        setState(() {
          _focusedIndex = 0;
        });
        _scrollToItem(items[0].key);
      }
      return KeyEventResult.handled;
    }

    // End / | : 末尾項目へ
    if (key == LogicalKeyboardKey.end) {
      if (isDown) {
        setState(() {
          _focusedIndex = items.length - 1;
        });
        _scrollToItem(items[items.length - 1].key);
      }
      return KeyEventResult.handled;
    }

    // PageDown / PageUp
    if (key == LogicalKeyboardKey.pageDown) {
      if (_scrollController.hasClients) {
        final next = (_scrollController.offset + 250.0)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(next,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      if (_scrollController.hasClients) {
        final next = (_scrollController.offset - 250.0)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(next,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      }
      return KeyEventResult.handled;
    }

    // Enter / numpadEnter: 選択中項目の実行
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (isDown && _focusedIndex != null && _focusedIndex! < items.length) {
        items[_focusedIndex!].onTap();
      }
      return KeyEventResult.handled;
    }

    // Space: 誤爆防止のため決定には割り当てず安全に消費
    if (key == LogicalKeyboardKey.space) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(l10n);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple[900],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_esports, size: 48, color: Colors.amber),
                const SizedBox(height: 8),
                Text(
                  l10n.drawerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isFocused = _focusedIndex == index;

            // セーブ項目とスコアボードの間、および設定項目の前に区切り線を表示
            final showDividerBefore = (widget.isGameRunning && index == 2) ||
                (widget.isGameRunning && index == 5) ||
                (widget.isGameRunning && index == 9) ||
                (!widget.isGameRunning && index == 3);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDividerBefore)
                  const Divider(color: Colors.white24, height: 1),
                Padding(
                  key: item.key,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Material(
                    color: isFocused
                        ? Colors.amberAccent.withValues(alpha: 0.16)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isFocused ? Colors.amberAccent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(item.icon, color: item.iconColor),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isFocused ? Colors.amberAccent : Colors.white,
                          fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: item.onTap,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

Widget buildDrawerBarrier({required bool isOpen, required VoidCallback onClose}) {
  if (!isOpen) return const SizedBox.shrink();
  return Positioned.fill(
    child: GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
      ),
    ),
  );
}
