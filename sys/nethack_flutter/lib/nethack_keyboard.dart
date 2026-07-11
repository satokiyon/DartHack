import 'package:flutter/material.dart';

enum _Layout { qwerty, symbols, meta, ctrl }

class _K {
  final String label;
  final int code;
  final bool raw;
  final bool spacer;

  const _K(this.label, this.code, {this.raw = false})
      : spacer = false;
  const _K.spacer()
      : label = '',
        code = 0,
        raw = false,
        spacer = true;
}

class NetHackKeyboard extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;
  final VoidCallback onToggleMode;
  final double opacity;

  const NetHackKeyboard({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
    required this.onToggleMode,
    this.opacity = 1.0,
  });

  @override
  State<NetHackKeyboard> createState() => _NetHackKeyboardState();
}

class _NetHackKeyboardState extends State<NetHackKeyboard> {
  _Layout _layout = _Layout.qwerty;
  bool _shift = false;

  static const _metaKeys = <List<_K>>[
    [
      _K('M-q', 241, raw: true),
      _K('M-w', 247, raw: true),
      _K('M-e', 229, raw: true),
      _K('M-r', 242, raw: true),
      _K('M-t', 244, raw: true),
      _K('M-2', 178, raw: true),
      _K('M-u', 245, raw: true),
      _K('M-i', 233, raw: true),
      _K('M-o', 239, raw: true),
      _K('M-p', 240, raw: true),
    ],
    [
      _K('M-a', 225, raw: true),
      _K('M-s', 243, raw: true),
      _K('M-d', 228, raw: true),
      _K('M-f', 230, raw: true),
      _K('M-R', 210, raw: true),
      _K('M-T', 212, raw: true),
      _K('M-j', 234, raw: true),
      _K.spacer(),
      _K('M-l', 236, raw: true),
    ],
    [
      _K('M-A', 193, raw: true),
      _K('M-C', 195, raw: true),
      _K('M-c', 227, raw: true),
      _K('M-v', 246, raw: true),
      _K.spacer(),
      _K('M-n', 238, raw: true),
      _K('M-m', 237, raw: true),
    ],
  ];

  static const _ctrlKeys = <List<_K>>[
    [
      _K.spacer(),
      _K('^W', 23, raw: true),
      _K('^E', 5, raw: true),
      _K('^R', 18, raw: true),
      _K('^T', 20, raw: true),
      _K.spacer(),
      _K.spacer(),
      _K('^I', 9, raw: true),
      _K('^O', 15, raw: true),
      _K('^P', 16, raw: true),
    ],
    [
      _K('^A', 1, raw: true),
      _K.spacer(),
      _K('^D', 4, raw: true),
      _K('^F', 6, raw: true),
      _K('^G', 7, raw: true),
      _K.spacer(),
      _K.spacer(),
      _K.spacer(),
      _K.spacer(),
    ],
    [
      _K.spacer(),
      _K('^X', 24, raw: true),
      _K.spacer(),
      _K('^V', 22, raw: true),
      _K.spacer(),
      _K.spacer(),
      _K.spacer(),
    ],
  ];

  static const _symRow2 = <_K>[
    _K('@', 64),
    _K('#', 35),
    _K('\$', 36),
    _K('^', 94),
    _K('&', 38),
    _K('(', 40),
    _K(')', 41),
    _K('=', 61),
    _K('_', 95),
  ];

  static const _symRow3 = <_K>[
    _K('+', 43),
    _K('-', 45),
    _K('\\', 92),
    _K('"', 34),
    _K('[', 91),
    _K('/', 47),
    _K(';', 59),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor().withValues(alpha: widget.opacity),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildLayout(),
      ),
    );
  }

  static const _darkBg = Color(0xFF121212);
  static const _keyBg = Color(0xFF1E1E1E);
  static const _navBg = Color(0xFF2A2A2A);
  static const _escBg = Color(0xFF333333);
  static const _padBg = Color(0xFF311B92);
  static const _metaActiveBg = Color(0xFF3949AB);
  static const _ctrlActiveBg = Color(0xFFB71C1C);
  static const _metaKeyBg = Color(0xFF2C2C6E);
  static const _ctrlKeyBg = Color(0xFF5E2C2C);
  static const _metaLayoutBg = Color(0xFF1A1A3E);
  static const _ctrlLayoutBg = Color(0xFF2E1A1A);

  Color _bgColor() {
    switch (_layout) {
      case _Layout.qwerty:
      case _Layout.symbols:
        return _darkBg;
      case _Layout.meta:
        return _metaLayoutBg;
      case _Layout.ctrl:
        return _ctrlLayoutBg;
    }
  }

  List<Widget> _buildLayout() {
    switch (_layout) {
      case _Layout.qwerty:
        return _buildQwerty();
      case _Layout.symbols:
        return _buildSymbols();
      case _Layout.meta:
        return _buildMeta();
      case _Layout.ctrl:
        return _buildCtrl();
    }
  }

  List<Widget> _buildQwerty() {
    return [
      _row(_letterRow(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'])),
      _row(_letterRow(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'])),
      _rowWithMods(_letterRow(['z', 'x', 'c', 'v', 'b', 'n', 'm'])),
      _bottomRow([
        _nav('?123', flex: 2),
        _nav('Meta', flex: 1),
        _key('<', 60),
        _key('>', 62),
        _key(':', 58),
        _key(',', 44),
        _nav('Ctrl', flex: 1),
        _nav('Pad', flex: 1),
        _nav('Enter', flex: 1),
      ]),
    ];
  }

  List<Widget> _buildSymbols() {
    return [
      _row(_letterRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])),
      _row(_symRow2.map((k) => _key(k.label, k.code)).toList()),
      _rowWithMods(_symRow3.map((k) => _key(k.label, k.code)).toList()),
      _bottomRow([
        _nav('ABC', flex: 2),
        _nav('Meta', flex: 1),
        _key('Space', 32, flex: 1),
        _key('.', 46),
        _key('*', 42),
        _key('?', 63),
        _nav('Ctrl', flex: 1),
        _nav('Pad', flex: 1),
        _nav('ESC', flex: 1),
      ]),
    ];
  }

  List<Widget> _buildMeta() {
    return [
      _row(_metaKeys[0].map((k) => _metaKey(k)).toList()),
      _row(_metaKeys[1].map((k) => k.spacer ? _spacer() : _metaKey(k)).toList()),
      _rowWithMods(
          _metaKeys[2].map((k) => k.spacer ? _spacer() : _metaKey(k)).toList()),
      _bottomRow([
        _nav('?123', flex: 2),
        _nav('ABC', flex: 1),
        _spacer(),
        _spacer(),
        _spacer(),
        _metaKey(const _K('M-?', 191, raw: true)),
        _nav('Ctrl', flex: 1),
        _nav('Pad', flex: 1),
        _nav('ESC', flex: 1),
      ]),
    ];
  }

  List<Widget> _buildCtrl() {
    return [
      _row(_ctrlKeys[0]
          .map((k) => k.spacer ? _spacer() : _ctrlKey(k))
          .toList()),
      _row(_ctrlKeys[1]
          .map((k) => k.spacer ? _spacer() : _ctrlKey(k))
          .toList()),
      _rowWithMods(_ctrlKeys[2]
          .map((k) => k.spacer ? _spacer() : _ctrlKey(k))
          .toList()),
      _bottomRow([
        _nav('?123', flex: 2),
        _nav('Meta', flex: 1),
        _key('!', 33),
        _key('%', 37),
        _key("'", 39),
        _key('`', 96),
        _nav('ABC', flex: 1),
        _nav('Pad', flex: 1),
        _nav('ESC', flex: 1),
      ]),
    ];
  }

  List<Widget> _letterRow(List<String> keys) {
    return keys.map((k) {
      final code = k.codeUnitAt(0);
      return _key(k, code);
    }).toList();
  }

  Widget _key(String label, int code, {double flex = 1}) {
    final displayLabel = label == 'Space'
        ? ''
        : (_shift && label.length == 1 && label.codeUnitAt(0) >= 97 &&
                label.codeUnitAt(0) <= 122)
            ? label.toUpperCase()
            : label;
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: _keyBg.withValues(alpha: widget.opacity),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _tapKey(label, code),
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

  Widget _metaKey(_K k) {
    return Expanded(
      flex: 10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: _metaKeyBg.withValues(alpha: widget.opacity),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => widget.onRawKeyCode(k.code),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                k.label,
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ctrlKey(_K k) {
    return Expanded(
      flex: 10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: _ctrlKeyBg.withValues(alpha: widget.opacity),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => widget.onRawKeyCode(k.code),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                k.label,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _spacer({double flex = 1}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: const SizedBox(height: 40),
    );
  }

  Widget _nav(String label, {double flex = 1}) {
    Color bg;
    switch (label) {
      case 'Pad':
        bg = _padBg;
        break;
      case 'Meta':
        bg = _layout == _Layout.meta ? _metaActiveBg : _navBg;
        break;
      case 'Ctrl':
        bg = _layout == _Layout.ctrl ? _ctrlActiveBg : _navBg;
        break;
      case 'ESC':
        bg = _escBg;
        break;
      default:
        bg = _navBg;
    }
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Material(
          color: bg.withValues(alpha: widget.opacity),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _tapNav(label),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys,
      ),
    );
  }

  Widget _rowWithMods(List<Widget> centerKeys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _nav('Shift', flex: 1.5),
          ...centerKeys,
          _nav('Del', flex: 1.5),
        ],
      ),
    );
  }

  Widget _bottomRow(List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys,
      ),
    );
  }

  void _tapKey(String label, int code) {
    if (label == 'Space') {
      widget.onKeyPress(' ');
      _releaseShift();
      return;
    }

    String ch = label;
    if (_shift && ch.length == 1) {
      final c = ch.codeUnitAt(0);
      if (c >= 97 && c <= 122) {
        ch = String.fromCharCode(c - 32);
      }
    }

    widget.onKeyPress(ch);
    _releaseShift();
  }

  void _tapNav(String label) {
    switch (label) {
      case 'Shift':
        setState(() => _shift = !_shift);
        break;
      case 'Del':
        widget.onRawKeyCode(127);
        break;
      case 'Enter':
        widget.onRawKeyCode(10);
        break;
      case 'ESC':
        widget.onRawKeyCode(27);
        break;
      case '?123':
        setState(() => _layout = _Layout.symbols);
        break;
      case 'ABC':
        setState(() => _layout = _Layout.qwerty);
        break;
      case 'Meta':
        setState(() => _layout = _Layout.meta);
        break;
      case 'Ctrl':
        setState(() => _layout = _Layout.ctrl);
        break;
      case 'Pad':
        widget.onToggleMode();
        break;
    }
  }

  void _releaseShift() {
    if (_shift) {
      setState(() => _shift = false);
    }
  }
}
