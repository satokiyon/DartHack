import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetHackShortcutPad extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;

  const NetHackShortcutPad({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
  });

  @override
  State<NetHackShortcutPad> createState() => _NetHackShortcutPadState();
}

class _NetHackShortcutPadState extends State<NetHackShortcutPad> {
  final List<String> _shortcuts = List.filled(9, "");
  final List<String> _defaultShortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', 'o', 'd', 'e', 'r'
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < 9; i++) {
        _shortcuts[i] = prefs.getString('shortcut_btn_$i') ?? _defaultShortcuts[i];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 150,
        height: 150,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

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
        children: List.generate(9, (index) => _buildShortcutButton(_shortcuts[index])),
      ),
    );
  }

  Widget _buildShortcutButton(String shortcut) {
    if (shortcut.isEmpty) {
      return const SizedBox.shrink();
    }

    String label = shortcut;
    if (shortcut.startsWith('#')) {
      if (shortcut == '#terrain') {
        label = 'terr';
      } else if (shortcut == '#therecmdmenu') {
        label = 'there';
      } else if (shortcut == '#herecmdmenu') {
        label = 'here';
      } else if (shortcut == '#chronicle') {
        label = 'chron';
      } else if (shortcut == '#overview') {
        label = 'overv';
      } else if (shortcut == '#attributes') {
        label = 'attr';
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
        widget.onKeyPress(shortcut[i]);
      }
      widget.onRawKeyCode(10); // Enter (\n)
    } else {
      for (int i = 0; i < shortcut.length; i++) {
        widget.onKeyPress(shortcut[i]);
      }
    }
  }
}
