import 'package:flutter/material.dart';

class GameDrawerContent extends StatelessWidget {
  final bool isGameRunning;
  final bool isKeyboardVisible;
  final VoidCallback onClose;
  final VoidCallback onSaveAndExit;
  final VoidCallback onQuit;
  final VoidCallback onShowScoreboard;
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
    required this.onShowHelp,
    required this.onDatabaseSearch,
    required this.onOpenOptions,
    required this.onShowFullMap,
    required this.onToggleKeyboard,
    required this.onShowSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.deepPurple[900],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports, size: 48, color: Colors.amber),
              SizedBox(height: 8),
              Text(
                'DartHackメニュー',
                style: TextStyle(
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
            title: const Text('セーブして終了', style: TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onSaveAndExit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.dangerous, color: Colors.redAccent),
            title: const Text('セーブせず終了 (放棄)', style: TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onQuit();
            },
          ),
        ],
        const Divider(color: Colors.white24, height: 1),
        ListTile(
          leading: const Icon(Icons.emoji_events, color: Colors.amber),
          title: const Text('スコアボード', style: TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onShowScoreboard();
          },
        ),
        if (isGameRunning) ...[
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.tealAccent),
            title: const Text('ヘルプを表示 (?)', style: TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onShowHelp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.orangeAccent),
            title: const Text('データベース検索 ( /? )', style: TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onDatabaseSearch();
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.cyanAccent),
            title: const Text('オプション設定 ( O )', style: TextStyle(color: Colors.white)),
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
            title: const Text('階層の全体地図を表示', style: TextStyle(color: Colors.white)),
            onTap: () {
              onClose();
              onShowFullMap();
            },
          ),
        ],
        ListTile(
          leading: Icon(isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard, color: Colors.blueAccent),
          title: Text(isKeyboardVisible ? '仮想キーボードを非表示' : '仮想キーボードを表示', style: const TextStyle(color: Colors.white)),
          onTap: () {
            onClose();
            onToggleKeyboard();
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.grey),
          title: const Text('ゲーム設定を開く', style: TextStyle(color: Colors.white)),
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
