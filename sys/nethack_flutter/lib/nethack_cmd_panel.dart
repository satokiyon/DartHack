import 'package:flutter/material.dart';

class NetHackCmdPanel extends StatelessWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;

  const NetHackCmdPanel({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
  });

  static const List<String> defaultCmds = [
    '#', '20s', '.', ':', ';', ',', 'e', 'd', 'r', 'z', 'Z', 'q',
    't', 'f', 'w', 'x', 'i', 'E', 'Q', 'P', 'R', 'W', 'T', 'o', '^d', '^p',
    'a', 'A', '^t', 'D', 'F', 'p', '^x', '^o', '?'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white10, width: 0.5),
          bottom: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: defaultCmds.map((cmd) => _buildCmdButton(context, cmd)).toList(),
        ),
      ),
    );
  }

  Widget _buildCmdButton(BuildContext context, String cmd) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _handleCmdPress(cmd),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 36),
            child: Text(
              cmd,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCmdPress(String cmd) {
    if (cmd.startsWith('^') && cmd.length == 2) {
      // Ctrlキーコード (a-z -> 1-26)
      final charCode = cmd.codeUnitAt(1);
      if (charCode >= 97 && charCode <= 122) { // a-z
        final ctrlCode = charCode - 96;
        onRawKeyCode(ctrlCode);
      }
    } else if (cmd == '20s') {
      // マクロ送信
      onKeyPress('2');
      onKeyPress('0');
      onKeyPress('s');
    } else {
      // 通常の文字送信
      for (int i = 0; i < cmd.length; i++) {
        onKeyPress(cmd[i]);
      }
    }
  }
}
