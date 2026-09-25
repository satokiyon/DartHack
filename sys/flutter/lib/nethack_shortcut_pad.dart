import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nethack_cmd_panel.dart';

class NetHackShortcutPad extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;
  final Function(String) onShortcut;
  final Function(int)? onShortcutLongPress;

  final double opacity;

  static const List<String> defaultShortcuts = [
    'i', '/', ',', '#therecmdmenu', '#herecmdmenu', '#chat', 'e', '^a', r'\e'
  ];

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
  final List<CmdItem> _shortcuts = List.filled(9, const CmdItem(command: ""));
  String _buttonDisplayMode = 'label';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    _buttonDisplayMode = prefs.getString('button_display_mode') ?? 'label';
    setState(() {
      for (int i = 0; i < 9; i++) {
        final raw = prefs.getString('shortcut_btn_$i') ?? NetHackShortcutPad.defaultShortcuts[i];
        final parsed = CmdItem.parseCmds(raw);
        _shortcuts[i] = parsed.isNotEmpty ? parsed.first : CmdItem(command: raw);
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

  Widget _buildShortcutButton(int index, CmdItem item) {
    if (item.command.isEmpty && item.label.isEmpty) {
      return const SizedBox.shrink();
    }

    final langCode = Localizations.localeOf(context).languageCode;
    final displayLabel = item.getEffectiveLabel(
      showLabel: _buttonDisplayMode == 'label',
      langCode: langCode,
    );
    final int labelLength = displayLabel.length;
    final double fontSize = labelLength >= 3 ? 9.5 : (labelLength == 2 ? 10.5 : 12.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: widget.opacity),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMacroPress(item.command),
          onLongPress: () {
            if (widget.onShortcutLongPress != null) {
              widget.onShortcutLongPress!(index);
            }
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              displayLabel,
              style: TextStyle(
                color: Colors.white70,
                fontSize: fontSize,
                fontWeight: item.hasLabel ? FontWeight.bold : FontWeight.normal,
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
    } else if (shortcut.startsWith('^') && shortcut.length == 2) {
      final charCode = shortcut.codeUnitAt(1);
      if (charCode >= 97 && charCode <= 122) {
        widget.onRawKeyCode(charCode - 96);
      } else if (charCode >= 65 && charCode <= 90) {
        widget.onRawKeyCode(charCode - 64);
      } else {
        widget.onKeyPress(shortcut);
      }
    } else {
      widget.onKeyPress(shortcut);
    }
  }
}
