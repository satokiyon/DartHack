import 'package:flutter/material.dart';

class NetHackShortcutPad extends StatelessWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;

  const NetHackShortcutPad({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
  });

  static const List<String> shortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', 'o', 'd', 'e', 'r'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: shortcuts.map((shortcut) => _buildShortcutButton(shortcut)).toList(),
      ),
    );
  }

  Widget _buildShortcutButton(String shortcut) {
    // 拡張コマンドは長いので表示ラベルを省略形にする
    String label = shortcut;
    if (shortcut.startsWith('#')) {
      if (shortcut == '#terrain') {
        label = 'terr';
      } else if (shortcut == '#therecmdmenu') {
        label = 'there';
      } else if (shortcut == '#herecmdmenu') {
        label = 'here';
      } else {
        label = shortcut.substring(1);
      }
    }

    return GestureDetector(
      onTapDown: (_) => _handleMacroPress(shortcut),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _handleMacroPress(String shortcut) {
    if (shortcut.startsWith('#')) {
      for (int i = 0; i < shortcut.length; i++) {
        onKeyPress(shortcut[i]);
      }
      onRawKeyCode(10); // Enter (\n)
    } else {
      for (int i = 0; i < shortcut.length; i++) {
        onKeyPress(shortcut[i]);
      }
    }
  }
}
