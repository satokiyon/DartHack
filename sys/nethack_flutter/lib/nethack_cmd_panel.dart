import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetHackCmdPanel extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;
  final VoidCallback onToggleMode;
  final ValueChanged<double>? onPanelHeightChanged;
  final bool showPanelNames;

  final double opacity;

  const NetHackCmdPanel({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
    required this.onToggleMode,
    this.onPanelHeightChanged,
    this.showPanelNames = true,
    this.opacity = 1.0,
  });

  @override
  State<NetHackCmdPanel> createState() => _NetHackCmdPanelState();
}

class _NetHackCmdPanelState extends State<NetHackCmdPanel> {
  final List<Map<String, dynamic>> _panels = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  double _lastReportedHeight = -1;

  static const List<String> defaultCmds = [
    '[Kbd]', '#', '20s', '.', ':', ';', ',', 'e', 'd', 'r', 'z', 'Z', 'q',
    't', 'f', 'w', 'x', 'i', 'E', 'Q', 'P', 'R', 'W', 'T', 'o', '^d', '^p',
    'a', 'A', '^t', 'D', 'F', 'p', '^x', '^o', '?'
  ];

  @override
  void initState() {
    super.initState();
    _loadPanels();
  }

  Future<void> _loadPanels() async {
    final prefs = await SharedPreferences.getInstance();
    final int count = prefs.getInt('panel_count') ?? 1;
    
    _panels.clear();
    
    final p0Name = prefs.getString('pName_0') ?? "標準パネル";
    final p0CmdsStr = prefs.getString('pCmdString_0') ?? defaultCmds.join(' ');
    _panels.add({
      'name': p0Name,
      'cmds': p0CmdsStr.split(' ').where((s) => s.isNotEmpty).toList(),
    });

    for (int i = 1; i < count; i++) {
      final name = prefs.getString('pName_$i') ?? "パネル ${i + 1}";
      final cmdsStr = prefs.getString('pCmdString_$i') ?? "";
      _panels.add({
        'name': name,
        'cmds': cmdsStr.split(' ').where((s) => s.isNotEmpty).toList(),
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      _reportPanelHeight(50);
      return Container(
        height: 50,
        color: Colors.grey[950],
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 表示するパネルの数
    final visiblePanels = _isExpanded ? _panels : [_panels.first];
    const double headerHeight = 18;
    const double rowHeight = 40;
    final double totalHeight = headerHeight + (visiblePanels.length * rowHeight);
    _reportPanelHeight(totalHeight);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -100) {
          // 上にスワイプ -> 展開
          if (_panels.length > 1 && !_isExpanded) {
            setState(() {
              _isExpanded = true;
            });
          }
        } else if (details.primaryVelocity! > 100) {
          // 下にスワイプ -> 縮小
          if (_isExpanded) {
            setState(() {
              _isExpanded = false;
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.fastOutSlowIn,
        height: totalHeight,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.87 * widget.opacity),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // ドラッグガイドバー
            Container(
              height: headerHeight,
              width: double.infinity,
              color: (Colors.grey[900] ?? const Color(0xFF212121)).withValues(alpha: widget.opacity),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_panels.length > 1) ...[
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _isExpanded 
                        ? "パネルを引き下げる" 
                        : (_panels.length > 1 ? "上にスワイプして全パネルを表示" : _panels.first['name']),
                    style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // パネルリスト
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visiblePanels.length,
                itemBuilder: (context, index) {
                  final panel = visiblePanels[index];
                  final List<String> cmds = panel['cmds'] as List<String>;
                  
                  return Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: index < visiblePanels.length - 1
                            ? BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (widget.showPanelNames)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(left: 6, right: 2),
                            decoration: BoxDecoration(
                              color: (Colors.grey[800] ?? const Color(0xFF424242)).withValues(alpha: widget.opacity),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              panel['name'],
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        // 横スクロール可能なボタン行
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              children: cmds.map((cmd) => _buildCmdButton(context, cmd)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportPanelHeight(double height) {
    if (widget.onPanelHeightChanged == null) {
      return;
    }
    if ((_lastReportedHeight - height).abs() < 0.1) {
      return;
    }
    _lastReportedHeight = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onPanelHeightChanged?.call(height);
    });
  }

  Widget _buildCmdButton(BuildContext context, String cmd) {
    final isKbdToggle = cmd == '[Kbd]';
    final buttonColor = isKbdToggle
        ? (Colors.deepPurple[900] ?? const Color(0xFF311B92))
        : (Colors.grey[900] ?? const Color(0xFF212121));
    final textColor = isKbdToggle ? Colors.amber : Colors.white70;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
      child: Material(
        color: buttonColor.withValues(alpha: widget.opacity),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _handleCmdPress(cmd),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 34),
            child: Text(
              cmd,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCmdPress(String cmd) {
    if (cmd == '[Kbd]') {
      widget.onToggleMode();
    } else if (cmd.startsWith('^') && cmd.length == 2) {
      final charCode = cmd.codeUnitAt(1);
      if (charCode >= 97 && charCode <= 122) {
        final ctrlCode = charCode - 96;
        widget.onRawKeyCode(ctrlCode);
      }
    } else {
      widget.onKeyPress(cmd);
    }
  }
}
