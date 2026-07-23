import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetHackShortcutPad extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;
  final Function(String) onShortcut;
  final Function(int)? onShortcutLongPress;

  final double opacity;

  const NetHackShortcutPad({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
    required this.onShortcut,
    this.onShortcutLongPress,
    this.opacity = 1.0,
  });

  @override
  State<NetHackShortcutPad> createState() => _NetHackShortcutPadState();
}

class _NetHackShortcutPadState extends State<NetHackShortcutPad> {
  final List<String> _shortcuts = List.filled(9, "");
  final List<String> _defaultShortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', '#chat', '#chronicle', '#overview', '#attributes'
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3E3E3E).withValues(alpha: widget.opacity), width: 1.5),
      ),
      padding: const EdgeInsets.all(6),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: List.generate(9, (index) => _buildShortcutButton(index, _shortcuts[index])),
      ),
    );
  }

  Widget _buildShortcutButton(int index, String shortcut) {
    if (shortcut.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: widget.opacity),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMacroPress(shortcut),
          onLongPress: () {
            if (widget.onShortcutLongPress != null) {
              widget.onShortcutLongPress!(index);
            }
          },
          child: Container(
            alignment: Alignment.center,
            child: Text(
              _formatShortcutLabel(shortcut),
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
        ),
      ),
    );
  }

  void _handleMacroPress(String shortcut) {
    if (shortcut.startsWith('#')) {
      widget.onShortcut(shortcut.length > 1 ? '$shortcut\n' : shortcut);
    } else {
      widget.onKeyPress(shortcut);
    }
  }

  String _formatShortcutLabel(String shortcut) {
    if (shortcut == r'\n' || shortcut == r'\r' || shortcut == '\n' || shortcut == '\r') {
      return 'Enter';
    }
    if (shortcut == r'\s' || shortcut == ' ') {
      return 'Space';
    }
    if (shortcut == r'\e' || shortcut == '\x1b' || shortcut == '^[') {
      return 'Esc';
    }
    return shortcut;
  }
}
