import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class GameDrawerContent extends StatelessWidget {
  final bool isGameRunning;
  final bool isKeyboardVisible;
  final VoidCallback onClose;
  final VoidCallback onSaveAndExit;
  final VoidCallback onQuit;
  final VoidCallback onShowScoreboard;
  final VoidCallback onShowGuidebook;
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
    required this.onShowHelp,
    required this.onDatabaseSearch,
    required this.onOpenOptions,
    required this.onShowFullMap,
    required this.onToggleKeyboard,
    required this.onShowSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
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
        if (isGameRunning) ...[
          ListTile(
            leading: const Icon(Icons.save, color: Colors.greenAccent),
            title: Text(l10n.menuSaveQuit, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onSaveAndExit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.dangerous, color: Colors.redAccent),
            title: Text(l10n.menuQuitWithoutSave, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onQuit();
            },
          ),
        ],
        const Divider(color: Colors.white24, height: 1),
        ListTile(
          leading: const Icon(Icons.emoji_events, color: Colors.amber),
          title: Text(l10n.scoreboard, style: const TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onShowScoreboard();
          },
        ),
        ListTile(
          leading: const Icon(Icons.menu_book, color: Colors.lightBlueAccent),
          title: Text(l10n.readGuidebook, style: const TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onShowGuidebook();
          },
        ),
        if (isGameRunning) ...[
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.tealAccent),
            title: Text(l10n.showHelp, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onShowHelp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.orangeAccent),
            title: Text(l10n.dbSearch, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onDatabaseSearch();
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.cyanAccent),
            title: Text(l10n.gameOptions, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onOpenOptions();
            },
          ),
        ],
        const Divider(color: Colors.white24, height: 1),
        if (isGameRunning) ...[
          ListTile(
            leading: const Icon(Icons.map, color: Colors.amberAccent),
            title: Text(l10n.showFullMap, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onShowFullMap();
            },
          ),
        ],
        ListTile(
          leading: Icon(isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard, color: Colors.blueAccent),
          title: Text(isKeyboardVisible ? l10n.hideKeyboard : l10n.showKeyboard, style: const TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onToggleKeyboard();
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.grey),
          title: Text(l10n.openSettings, style: const TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onShowSettings();
          },
        ),
      ],
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
