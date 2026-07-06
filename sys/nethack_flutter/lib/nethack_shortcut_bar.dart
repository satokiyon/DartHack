import 'package:flutter/material.dart';

class NetHackShortcutBar extends StatelessWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;

  const NetHackShortcutBar({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
  });

  // Java版の初期設定を参考にした9つのショートカットボタン
  static const List<String> shortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', 'o', 'd', 'e', 'r'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.black45,
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: shortcuts.map((shortcut) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Material(
              color: Colors.blueGrey[900],
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: () => _handleMacroPress(shortcut),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    shortcut,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _handleMacroPress(String shortcut) {
    if (shortcut.startsWith('#')) {
      // 拡張コマンドは末尾にEnterを自動送信してマクロ実行
      for (int i = 0; i < shortcut.length; i++) {
        onKeyPress(shortcut[i]);
      }
      onRawKeyCode(10); // Enter (\n)
    } else {
      // 通常の文字はそのまま送信
      for (int i = 0; i < shortcut.length; i++) {
        onKeyPress(shortcut[i]);
      }
    }
  }
}
