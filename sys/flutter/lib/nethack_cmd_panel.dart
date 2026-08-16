import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CmdItem {
  final String command;
  final String label;

  const CmdItem({required this.command, this.label = ''});

  String get displayLabel {
    if (label.isNotEmpty) return label;
    if (command == r'\n' || command == r'\r' || command == '\n' || command == '\r') return 'Enter';
    if (command == r'\s' || command == ' ') return 'Space';
    if (command == r'\e' || command == '\x1b' || command == '^[') return 'Esc';
    return command;
  }
  bool get hasLabel => label.isNotEmpty;

  static String escape(String str) {
    return str.replaceAll('\\', '\\\\').replaceAll('|', '\\|').replaceAll(' ', '\\ ');
  }

  static List<CmdItem> parseCmds(String cmds) {
    if (cmds.trim().isEmpty) return [];
    final List<CmdItem> items = [];
    final List<String> parts = [];
    StringBuffer sb = StringBuffer();
    bool esc = false;
    bool hasLabel = false;

    for (int i = 0; i < cmds.length; i++) {
      final char = cmds[i];
      if (esc) {
        sb.write(char);
        esc = false;
      } else if (char == '\\') {
        esc = true;
      } else if (char == '|') {
        parts.add(sb.toString());
        sb = StringBuffer();
        hasLabel = true;
      } else if (char == ' ') {
        parts.add(sb.toString());
        sb = StringBuffer();
        if (!hasLabel) parts.add("");
        hasLabel = false;
      } else {
        sb.write(char);
      }
    }
    if (sb.isNotEmpty || hasLabel) {
      parts.add(sb.toString());
      if (!hasLabel) parts.add("");
    }

    for (int i = 0; i < parts.length - 1; i += 2) {
      items.add(CmdItem(command: parts[i], label: parts[i + 1]));
    }
    return items;
  }

  static String serializeCmds(List<CmdItem> items) {
    final List<String> encoded = [];
    for (final item in items) {
      String s = escape(item.command);
      if (item.hasLabel) {
        s += '|${escape(item.label)}';
      }
      encoded.add(s);
    }
    return encoded.join(' ');
  }
}

class NetHackCmdPanel extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function(int) onRawKeyCode;
  final Function(String)? onShortcut;
  final VoidCallback onToggleMode;
  final ValueChanged<double>? onPanelHeightChanged;
  final bool showPanelNames;
  final double opacity;
  final List<Map<String, String>>? extCmdList;

  final bool isVertical;
  final String position;
  final bool isKeyboardMode;

  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  const NetHackCmdPanel({
    super.key,
    required this.onKeyPress,
    required this.onRawKeyCode,
    this.onShortcut,
    required this.onToggleMode,
    this.onPanelHeightChanged,
    this.showPanelNames = true,
    this.opacity = 1.0,
    this.extCmdList,
    this.isVertical = false,
    this.position = 'top',
    this.isKeyboardMode = false,
    this.isExpanded,
    this.onExpandedChanged,
  });

  @override
  State<NetHackCmdPanel> createState() => _NetHackCmdPanelState();
}

class _NetHackCmdPanelState extends State<NetHackCmdPanel> {
  final List<Map<String, dynamic>> _panels = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  double _lastReportedHeight = -1;

  bool get _effectiveIsExpanded => widget.isExpanded ?? _isExpanded;

  void _setExpanded(bool value) {
    if (widget.isExpanded != null) {
      widget.onExpandedChanged?.call(value);
    } else {
      setState(() {
        _isExpanded = value;
      });
      widget.onExpandedChanged?.call(value);
    }
  }

  static const List<String> defaultCmdsStr = [
    '[Kbd]', '#', '20s', '.', ':', ';', ',', 'e', 'd', 'r', 'z', 'Z', 'q',
    't', 'f', 'w', 'x', 'i', 'E', 'Q', 'P', 'R', 'W', 'T', 'o', '^d', '^p',
    'a', 'A', '^t', 'D', 'F', 'p', '^x', '^o', '?'
  ];

  static const List<Map<String, String>> fallbackExtCmdsEn = [
    {'command': '#adjust', 'description': 'Adjust item letter'},
    {'command': '#annotate', 'description': 'Name level'},
    {'command': '#apply', 'description': 'Apply item'},
    {'command': '#attributes', 'description': 'Attributes'},
    {'command': '#cast', 'description': 'Cast spell'},
    {'command': '#chat', 'description': 'Chat/Talk'},
    {'command': '#chronicle', 'description': 'Record events'},
    {'command': '#close', 'description': 'Close door'},
    {'command': '#force', 'description': 'Force lock'},
    {'command': '#invoke', 'description': 'Invoke object'},
    {'command': '#jump', 'description': 'Jump'},
    {'command': '#loot', 'description': 'Loot container'},
    {'command': '#monster', 'description': 'Monster power'},
    {'command': '#name', 'description': 'Name item/monster'},
    {'command': '#offer', 'description': 'Offer sacrifice'},
    {'command': '#open', 'description': 'Open door'},
    {'command': '#overview', 'description': 'Dungeon overview'},
    {'command': '#pay', 'description': 'Pay bill'},
    {'command': '#pray', 'description': 'Pray to god'},
    {'command': '#quaff', 'description': 'Quaff potion'},
    {'command': '#quit', 'description': 'Quit game'},
    {'command': '#read', 'description': 'Read scroll/book'},
    {'command': '#rest', 'description': 'Rest/Wait'},
    {'command': '#ride', 'description': 'Ride steed'},
    {'command': '#rub', 'description': 'Rub lamp/stone'},
    {'command': '#search', 'description': 'Search area'},
    {'command': '#sit', 'description': 'Sit down'},
    {'command': '#surrender', 'description': 'Surrender'},
    {'command': '#takeoff', 'description': 'Take off armor'},
    {'command': '#teleport', 'description': 'Teleport'},
    {'command': '#terrain', 'description': 'Show terrain'},
    {'command': '#therecmdmenu', 'description': 'Menu at cursor'},
    {'command': '#turn', 'description': 'Turn undead'},
    {'command': '#untrap', 'description': 'Untrap'},
    {'command': '#version', 'description': 'Version info'},
    {'command': '#wear', 'description': 'Wear armor'},
    {'command': '#wield', 'description': 'Wield weapon'},
    {'command': '#wipe', 'description': 'Wipe face'},
  ];

  static const List<Map<String, String>> fallbackExtCmdsJp = [
    {'command': '#adjust', 'description': 'アイテムの文字を付け替える'},
    {'command': '#annotate', 'description': 'レベル注釈'},
    {'command': '#apply', 'description': '道具を使う'},
    {'command': '#attributes', 'description': '属性・状態'},
    {'command': '#cast', 'description': '呪文を唱える'},
    {'command': '#chat', 'description': '話しかける'},
    {'command': '#chronicle', 'description': '出来事の記録'},
    {'command': '#close', 'description': 'ドアを閉める'},
    {'command': '#force', 'description': '鍵を壊す'},
    {'command': '#invoke', 'description': '発動する'},
    {'command': '#jump', 'description': 'ジャンプする'},
    {'command': '#loot', 'description': 'あさる'},
    {'command': '#monster', 'description': 'モンスターの特殊能力'},
    {'command': '#name', 'description': '名前をつける'},
    {'command': '#offer', 'description': '捧げる'},
    {'command': '#open', 'description': 'ドアを開ける'},
    {'command': '#overview', 'description': 'ダンジョン概要'},
    {'command': '#pay', 'description': '支払う'},
    {'command': '#pray', 'description': '祈る'},
    {'command': '#quaff', 'description': '飲む'},
    {'command': '#quit', 'description': 'ゲームを終了'},
    {'command': '#read', 'description': '読む'},
    {'command': '#rest', 'description': '待機'},
    {'command': '#ride', 'description': '乗る'},
    {'command': '#rub', 'description': 'こする'},
    {'command': '#search', 'description': '探す'},
    {'command': '#sit', 'description': '座る'},
    {'command': '#surrender', 'description': '投降する'},
    {'command': '#takeoff', 'description': '脱ぐ'},
    {'command': '#teleport', 'description': 'テレポート'},
    {'command': '#terrain', 'description': '地形を表示'},
    {'command': '#therecmdmenu', 'description': 'カーソル位置のメニュー'},
    {'command': '#turn', 'description': 'アンデッド退散'},
    {'command': '#untrap', 'description': '罠を解除'},
    {'command': '#version', 'description': 'バージョン情報'},
    {'command': '#wear', 'description': '着る'},
    {'command': '#wield', 'description': '構える'},
    {'command': '#wipe', 'description': '顔を拭く'},
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
    final p0CmdsStr = prefs.getString('pCmdString_0') ?? defaultCmdsStr.join(' ');
    _panels.add({
      'name': p0Name,
      'cmds': CmdItem.parseCmds(p0CmdsStr),
    });

    for (int i = 1; i < count; i++) {
      final name = prefs.getString('pName_$i') ?? "パネル ${i + 1}";
      final cmdsStr = prefs.getString('pCmdString_$i') ?? "";
      _panels.add({
        'name': name,
        'cmds': CmdItem.parseCmds(cmdsStr),
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _savePanel(int panelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final cmds = _panels[panelIndex]['cmds'] as List<CmdItem>;
    final serialized = CmdItem.serializeCmds(cmds);
    await prefs.setString('pCmdString_$panelIndex', serialized);
    setState(() {});
  }

  Future<void> _resetPanelToDefault(int panelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    if (panelIndex == 0) {
      await prefs.remove('pCmdString_0');
      _panels[0]['cmds'] = CmdItem.parseCmds(defaultCmdsStr.join(' '));
    } else {
      await prefs.remove('pCmdString_$panelIndex');
      _panels[panelIndex]['cmds'] = <CmdItem>[];
    }
    setState(() {});
  }

  List<Map<String, String>> get _effectiveExtCmds {
    if (widget.extCmdList != null && widget.extCmdList!.isNotEmpty) {
      return widget.extCmdList!;
    }
    final lang = Localizations.localeOf(context).languageCode;
    return lang == 'ja' ? fallbackExtCmdsJp : fallbackExtCmdsEn;
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

    final visiblePanels = _effectiveIsExpanded ? _panels : [_panels.first];

    if (widget.isVertical) {
      const double panelWidth = 130.0;
      _reportPanelHeight(panelWidth);

      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          final velocity = details.primaryVelocity!;
          if (widget.position == 'left') {
            if (velocity > 100 && _panels.length > 1) {
              _setExpanded(true);
            } else if (velocity < -100) {
              _setExpanded(false);
            }
          } else if (widget.position == 'right') {
            if (velocity < -100 && _panels.length > 1) {
              _setExpanded(true);
            } else if (velocity > 100) {
              _setExpanded(false);
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          width: panelWidth,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.87 * widget.opacity),
            border: Border(
              left: BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5),
              right: BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 20,
                width: double.infinity,
                color: (Colors.grey[900] ?? const Color(0xFF212121)).withValues(alpha: widget.opacity),
                alignment: Alignment.center,
                child: Text(
                  widget.position == 'left'
                      ? (_effectiveIsExpanded ? "← 閉じる" : "内側(→)スワイプで展開")
                      : (_effectiveIsExpanded ? "閉じる →" : "内側(←)スワイプで展開"),
                  style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: visiblePanels.length,
                  itemBuilder: (context, pIdx) {
                    final panel = visiblePanels[pIdx];
                    final List<CmdItem> cmds = panel['cmds'] as List<CmdItem>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1 * widget.opacity), width: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showPanelNames)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                panel['name'],
                                style: const TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            alignment: WrapAlignment.start,
                            children: cmds
                                .asMap()
                                .entries
                                .map((entry) => _buildCmdButton(context, pIdx, entry.key, entry.value))
                                .toList(),
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

    const double headerHeight = 18;
    const double rowHeight = 40;
    final double totalHeight = headerHeight + (visiblePanels.length * rowHeight);
    _reportPanelHeight(totalHeight);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (widget.position == 'top') {
          if (details.primaryVelocity! > 100) {
            if (_panels.length > 1 && !_effectiveIsExpanded) {
              _setExpanded(true);
            }
          } else if (details.primaryVelocity! < -100) {
            if (_effectiveIsExpanded) {
              _setExpanded(false);
            }
          }
        } else {
          if (details.primaryVelocity! < -100) {
            if (_panels.length > 1 && !_effectiveIsExpanded) {
              _setExpanded(true);
            }
          } else if (details.primaryVelocity! > 100) {
            if (_effectiveIsExpanded) {
              _setExpanded(false);
            }
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
            Container(
              height: headerHeight,
              width: double.infinity,
              color: (Colors.grey[900] ?? const Color(0xFF212121)).withValues(alpha: widget.opacity),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_panels.length > 1) ...[
                    Icon(
                      _effectiveIsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: Colors.white60,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _effectiveIsExpanded
                        ? "パネルを閉じる"
                        : (_panels.length > 1
                            ? (widget.position == 'top' ? "下へスワイプして全パネルを表示" : "上へスワイプして全パネルを表示")
                            : _panels.first['name']),
                    style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visiblePanels.length,
                itemBuilder: (context, pIdx) {
                  final panel = visiblePanels[pIdx];
                  final List<CmdItem> cmds = panel['cmds'] as List<CmdItem>;

                  return Container(
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: pIdx < visiblePanels.length - 1
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
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              children: cmds
                                  .asMap()
                                  .entries
                                  .map((entry) => _buildCmdButton(context, pIdx, entry.key, entry.value))
                                  .toList(),
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

  bool _isKbdToggleCmd(String cmd) {
    final lower = cmd.toLowerCase();
    return lower == '[kbd]' || lower == '[pad]';
  }

  Widget _buildCmdButton(BuildContext context, int panelIndex, int itemIndex, CmdItem item) {
    final isKbdToggle = _isKbdToggleCmd(item.command);
    final buttonColor = isKbdToggle
        ? (Colors.deepPurple[900] ?? const Color(0xFF311B92))
        : (Colors.grey[900] ?? const Color(0xFF212121));
    final textColor = isKbdToggle ? Colors.amber : Colors.white70;
    final displayLabel = isKbdToggle
        ? (widget.isKeyboardMode ? '[pad]' : '[kbd]')
        : item.displayLabel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 3),
      child: Material(
        color: buttonColor.withValues(alpha: widget.opacity),
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _handleCmdPress(item.command),
          onLongPress: () => _showButtonCustomizeDialog(panelIndex, itemIndex, item),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 34),
            child: Text(
              displayLabel,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: (item.hasLabel || isKbdToggle) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCmdPress(String cmd) {
    if (_isKbdToggleCmd(cmd)) {
      widget.onToggleMode();
    } else if (cmd.startsWith('#')) {
      if (widget.onShortcut != null) {
        widget.onShortcut!(cmd.length > 1 && !cmd.endsWith('\n') ? '$cmd\n' : cmd);
      } else {
        widget.onKeyPress(cmd);
      }
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

  void _showButtonCustomizeDialog(int panelIndex, int itemIndex, CmdItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("ボタン編集: ${item.displayLabel}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text("コマンドを変更"),
                subtitle: Text("現在: ${item.command}"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCommandEditDialog(panelIndex, itemIndex, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.label, color: Colors.amberAccent),
                title: const Text("表示ラベルを変更"),
                subtitle: Text(item.hasLabel ? "現在: ${item.label}" : "未設定 (コマンド名を表示)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLabelEditDialog(panelIndex, itemIndex, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.greenAccent),
                title: const Text("前にボタンを追加"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddButtonDialog(panelIndex, itemIndex, isBefore: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.tealAccent),
                title: const Text("後にボタンを追加"),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddButtonDialog(panelIndex, itemIndex + 1, isBefore: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("ボタンを削除"),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeButton(panelIndex, itemIndex);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orangeAccent),
                title: const Text("パネルをデフォルトに戻す"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmResetPanel(panelIndex);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
        ],
      ),
    );
  }

  void _showCommandEditDialog(int panelIndex, int itemIndex, CmdItem item) {
    final controller = TextEditingController(text: item.command);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: const Text("コマンドの変更"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "例: e, d, #adjust, #terrain 等",
                  helperText: "#で始まるものは拡張コマンドとして実行されます",
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('Enter'),
                    onPressed: () => controller.text = r'\n',
                  ),
                  ActionChip(
                    label: const Text('Space'),
                    onPressed: () => controller.text = r'\s',
                  ),
                  ActionChip(
                    label: const Text('Esc'),
                    onPressed: () => controller.text = r'\e',
                  ),
                  ActionChip(
                    label: const Text('[kbd] / [pad]'),
                    onPressed: () => controller.text = '[kbd]',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("拡張コマンドから選択..."),
                onPressed: () {
                  _selectExtCmdDialog((selectedCmd) {
                    controller.text = selectedCmd;
                  });
                },
              ),
            ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              final newCmd = controller.text.trim();
              if (newCmd.isNotEmpty) {
                final cmds = _panels[panelIndex]['cmds'] as List<CmdItem>;
                cmds[itemIndex] = CmdItem(command: newCmd, label: item.label);
                _savePanel(panelIndex);
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLabelEditDialog(int panelIndex, int itemIndex, CmdItem item) {
    final controller = TextEditingController(text: item.label);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: const Text("表示ラベルの変更"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "例: 食べる, 道具, #整理",
                  helperText: "空にするとコマンド名がそのまま表示されます",
                ),
                autofocus: true,
              ),
            ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              final newLabel = controller.text.trim();
              final cmds = _panels[panelIndex]['cmds'] as List<CmdItem>;
              cmds[itemIndex] = CmdItem(command: item.command, label: newLabel);
              _savePanel(panelIndex);
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAddButtonDialog(int panelIndex, int insertIndex, {required bool isBefore}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(isBefore ? "前にボタンを追加" : "後にボタンを追加"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "例: e, d, #adjust 等",
                  helperText: "#で始まるものは拡張コマンドとして実行されます",
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('Enter'),
                    onPressed: () => controller.text = r'\n',
                  ),
                  ActionChip(
                    label: const Text('Space'),
                    onPressed: () => controller.text = r'\s',
                  ),
                  ActionChip(
                    label: const Text('Esc'),
                    onPressed: () => controller.text = r'\e',
                  ),
                  ActionChip(
                    label: const Text('[kbd] / [pad]'),
                    onPressed: () => controller.text = '[kbd]',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("拡張コマンドから選択..."),
                onPressed: () {
                  _selectExtCmdDialog((selectedCmd) {
                    controller.text = selectedCmd;
                  });
                },
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text("[kbd] / [pad] (キーボード切替) を追加"),
                onPressed: () {
                  controller.text = '[kbd]';
                },
              ),
            ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              final newCmd = controller.text.trim();
              if (newCmd.isNotEmpty) {
                final cmds = _panels[panelIndex]['cmds'] as List<CmdItem>;
                final idx = insertIndex.clamp(0, cmds.length);
                cmds.insert(idx, CmdItem(command: newCmd));
                _savePanel(panelIndex);
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _removeButton(int panelIndex, int itemIndex) {
    final cmds = _panels[panelIndex]['cmds'] as List<CmdItem>;
    if (cmds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("これ以上ボタンを削除できません")),
      );
      return;
    }
    cmds.removeAt(itemIndex);
    _savePanel(panelIndex);
  }

  void _confirmResetPanel(int panelIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("パネル初期化の確認"),
        content: const Text("このパネルのボタン配置を初期設定に戻しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _resetPanelToDefault(panelIndex);
            },
            child: const Text("初期化", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _selectExtCmdDialog(Function(String) onSelect) {
    String filterText = '';
    final extCmds = _effectiveExtCmds;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final filtered = extCmds.where((item) {
              final cmd = (item['command'] ?? '').toLowerCase();
              final desc = (item['description'] ?? '').toLowerCase();
              final query = filterText.toLowerCase();
              return cmd.contains(query) || desc.contains(query);
            }).toList();

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: const Text("拡張コマンドから選択"),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "コマンド名や説明で検索...",
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          filterText = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "該当するコマンドがありません",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final item = filtered[idx];
                                var cmd = item['command'] ?? '';
                                final desc = item['description'] ?? '';
                                if (!cmd.startsWith('#') && !cmd.startsWith('?')) {
                                  cmd = '#$cmd';
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Material(
                                    color: const Color(0xFF2C2C2C),
                                    borderRadius: BorderRadius.circular(6.0),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      title: Text(
                                        cmd,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: desc.isNotEmpty
                                          ? Text(
                                              desc,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        onSelect(cmd);
                                        Navigator.pop(dialogCtx);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("キャンセル"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
