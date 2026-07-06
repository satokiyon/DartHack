import 'package:flutter/material.dart';

class NetHackKeyboard extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;

  const NetHackKeyboard({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
  });

  @override
  State<NetHackKeyboard> createState() => _NetHackKeyboardState();
}

class _NetHackKeyboardState extends State<NetHackKeyboard> {
  bool _isShiftEnabled = false;
  bool _isCtrlEnabled = false;
  bool _isMetaEnabled = false;
  bool _isSymbolsMode = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[950],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSymbolsMode)
            _buildSymbolsLayout()
          else
            _buildQwertyLayout(),
        ],
      ),
    );
  }

  // 通常の Qwerty レイアウト
  Widget _buildQwertyLayout() {
    return Column(
      children: [
        _buildRow(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']),
        _buildRow(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']),
        _buildRowWithModifiers(
          'Shift',
          ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
          'Del',
        ),
        _buildBottomRow(),
      ],
    );
  }

  // 記号レイアウト
  Widget _buildSymbolsLayout() {
    return Column(
      children: [
        _buildRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']),
        _buildRow(['-', '/', ':', ';', '(', ')', '\$', '&', '@', '"']),
        _buildRowWithModifiers(
          'Shift',
          ['.', ',', '?', '!', '\'', '\\', '_'],
          'Del',
        ),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _buildKeyButton(key)).toList(),
      ),
    );
  }

  Widget _buildRowWithModifiers(String leftLabel, List<String> centerKeys, String rightLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSpecialButton(leftLabel, flex: 2),
          ...centerKeys.map((key) => _buildKeyButton(key)),
          _buildSpecialButton(rightLabel, flex: 2),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSpecialButton(_isSymbolsMode ? 'abc' : '?123', flex: 2),
          _buildSpecialButton('Meta', flex: 2, isActivated: _isMetaEnabled),
          _buildKeyButton('Space', flex: 4),
          _buildSpecialButton('Ctrl', flex: 2, isActivated: _isCtrlEnabled),
          _buildSpecialButton('Enter', flex: 2),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String key, {int flex = 1}) {
    final displayLabel = (key == 'Space') ? '' : (_isShiftEnabled ? key.toUpperCase() : key);
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _handleKeyPress(key),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                displayLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton(String label, {int flex = 1, bool isActivated = false}) {
    Color? btnColor = Colors.grey[850];
    if (isActivated) {
      btnColor = Colors.blueGrey[700];
    }
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: btnColor,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _handleSpecialPress(label),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyPress(String key) {
    if (key == 'Space') {
      widget.onKeyPress(' ');
      return;
    }

    String char = _isShiftEnabled ? key.toUpperCase() : key;

    if (_isCtrlEnabled) {
      final codeUnit = char.toLowerCase().codeUnitAt(0);
      if (codeUnit >= 97 && codeUnit <= 122) { // a-z
        final ctrlCode = codeUnit - 96;
        widget.onRawKeyCode(ctrlCode);
      }
      setState(() {
        _isCtrlEnabled = false;
      });
      return;
    }

    if (_isMetaEnabled) {
      widget.onKeyPress('#'); // Metaは通常拡張入力(#)を送信など、ゲーム側仕様にフォールバック
      setState(() {
        _isMetaEnabled = false;
      });
    }

    widget.onKeyPress(char);

    // 一時的なShift状態の解除
    if (_isShiftEnabled) {
      setState(() {
        _isShiftEnabled = false;
      });
    }
  }

  void _handleSpecialPress(String label) {
    if (label == 'Shift') {
      setState(() {
        _isShiftEnabled = !_isShiftEnabled;
      });
    } else if (label == 'Ctrl') {
      setState(() {
        _isCtrlEnabled = !_isCtrlEnabled;
      });
    } else if (label == 'Meta') {
      setState(() {
        _isMetaEnabled = !_isMetaEnabled;
      });
    } else if (label == 'Del') {
      widget.onRawKeyCode(127); // アスキーDEL / バックスペース相当
    } else if (label == 'Enter') {
      widget.onRawKeyCode(10); // LF (\n)
    } else if (label == '?123') {
      setState(() {
        _isSymbolsMode = true;
      });
    } else if (label == 'abc') {
      setState(() {
        _isSymbolsMode = false;
      });
    }
  }
}
