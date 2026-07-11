import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'defaults_editor.dart';
import 'nethack_ffi.dart';


class SettingsPage extends StatefulWidget {
  final String defaultsFilePath;
  final String dataDirString;

  const SettingsPage({
    super.key,
    required this.defaultsFilePath,
    required this.dataDirString,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _useTiles = true;
  String _selectedTileset = 'nevanda_32x32';
  String _controllerMode = 'pad';
  int _statusDisplayMode = 0;
  double _padOpacity = 0.8;
  double _padScale = 1.0;
  String _drawerPosition = 'left';
  String _menuButtonPosition = 'bottom_left';

  // 物理キー割り当て (デフォルト: 0 = なし)
  int _volupAction = 0;
  int _voldownAction = 0;
  int _backAction = 0;

  // ショートカット設定 (0～8)
  final List<String> _shortcuts = List.filled(9, "");
  final List<String> _defaultShortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', '#chat', '#chronicle', '#overview', '#attributes'
  ];
  final List<String> _shortcutLabels = [
    "左上ボタン (0)", "上中央ボタン (1)", "右上ボタン (2)",
    "中段左ボタン (3)", "中段中央ボタン (4)", "中段右ボタン (5)",
    "下段左ボタン (6)", "下段中央ボタン (7)", "下段右ボタン (8)"
  ];

  final _channel = const MethodChannel('com.tbd.nethackjp/key_interceptor');

  bool _showPanelNames = true;

  // コマンドパネル編集用
  final List<Map<String, dynamic>> _panels = [];

  static const List<String> _fallbackExtCommands = [
    'adjust', 'annotate', 'apply', 'attributes', 'cast', 'chat', 'chronicle',
    'close', 'force', 'invoke', 'jump', 'loot', 'monster', 'name', 'offer',
    'open', 'overview', 'pay', 'pray', 'quaff', 'quit', 'read', 'rest',
    'ride', 'rub', 'search', 'sit', 'surrender', 'takeoff', 'teleport',
    'terrain', 'therecmdmenu', 'turn', 'untrap', 'version', 'wear', 'wield',
    'wipe'
  ];

  List<Map<String, String>> _extCommands = [];

  void _loadExtCmds() {
    try {
      final ffi = NetHackFfi();
      final ptr = ffi.getExtCmdsFlutter();
      if (ptr != nullptr) {
        final extCmdsStr = ptr.toDartString();
        final parsed = <Map<String, String>>[];
        final rawItems = extCmdsStr.split(';');
        for (final item in rawItems) {
          if (item.isEmpty) continue;
          final parts = item.split('\t');
          var command = parts[0];
          final description = parts.length > 1 ? parts[1] : '';

          if (!command.startsWith('#') && !command.startsWith('?')) {
            command = '#$command';
          }
          parsed.add({'command': command, 'description': description});
        }
        if (parsed.isNotEmpty) {
          setState(() {
            _extCommands = parsed;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error loading extcmds from FFI: $e");
    }

    // フォールバック
    final parsed = <Map<String, String>>[];
    for (final cmd in _fallbackExtCommands) {
      var command = cmd;
      if (!command.startsWith('#') && !command.startsWith('?')) {
        command = '#$command';
      }
      parsed.add({'command': command, 'description': ''});
    }
    setState(() {
      _extCommands = parsed;
    });
  }


  @override
  void initState() {
    super.initState();
    _loadAllSettings();
    _loadExtCmds();
  }

  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useTiles = prefs.getBool('use_tiles') ?? true;
      _selectedTileset = prefs.getString('selected_tileset') ?? 'nevanda_32x32';
      _controllerMode = prefs.getString('controller_mode') ?? 'pad';
      _statusDisplayMode = prefs.getInt('status_display_mode') ?? 0;
      _padOpacity = prefs.getDouble('pad_opacity') ?? 0.8;
      _padScale = prefs.getDouble('pad_scale') ?? 1.0;
      _drawerPosition = prefs.getString('drawer_position') ?? 'left';
      _menuButtonPosition = prefs.getString('menu_button_position') ?? 'bottom_left';

      _volupAction = prefs.getInt('key_volup_action') ?? 0;
      _voldownAction = prefs.getInt('key_voldown_action') ?? 0;
      _backAction = prefs.getInt('key_back_action') ?? 0;

      for (int i = 0; i < 9; i++) {
        _shortcuts[i] = prefs.getString('shortcut_btn_$i') ?? _defaultShortcuts[i];
      }

      _showPanelNames = prefs.getBool('show_panel_names') ?? true;

      // コマンドパネル情報のロード
      final int panelCount = prefs.getInt('panel_count') ?? 1;
      _panels.clear();
      final p0Name = prefs.getString('pName_0') ?? "標準パネル";
      final p0CmdsStr = prefs.getString('pCmdString_0') ?? "標準"; // 後続処理の初期値に合わせる
      _panels.add({
        'name': p0Name,
        'cmds': p0CmdsStr == "標準" ? "[Kbd] # 20s . : ; , e d r z Z q t f w x i E Q P R W T o ^d ^p a A ^t D F p ^x ^o ?" : p0CmdsStr,
      });

      for (int i = 1; i < panelCount; i++) {
        final name = prefs.getString('pName_$i') ?? "パネル ${i + 1}";
        final cmdsStr = prefs.getString('pCmdString_$i') ?? "";
        _panels.add({
          'name': name,
          'cmds': cmdsStr,
        });
      }
    });

    _syncNativeKeySettings();
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _syncNativeKeySettings() async {
    try {
      await _channel.invokeMethod('updateInterceptorSettings', {
        'volumeUp': _volupAction != 0,
        'volumeDown': _voldownAction != 0,
        'back': _backAction != 0,
      });
    } catch (e) {
      debugPrint("Native key settings sync failed: $e");
    }
  }

  // クリップボードへエクスポート
  Future<void> _exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> settingsMap = {};
    for (final key in keys) {
      settingsMap[key] = prefs.get(key);
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(settingsMap);
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("設定JSONをクリップボードにコピーしました。")),
      );
    }
  }

  // クリップボードからインポート
  Future<void> _importSettings() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      _showErrorDialog("クリップボードにテキストがありません。");
      return;
    }

    try {
      final Map<String, dynamic> settingsMap = jsonDecode(data.text!);
      final prefs = await SharedPreferences.getInstance();
      
      for (final entry in settingsMap.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is int) {
          if (key == 'pad_opacity' || key == 'pad_scale') {
            await prefs.setDouble(key, value.toDouble());
          } else {
            await prefs.setInt(key, value);
          }
        } else if (value is String) {
          await prefs.setString(key, value);
        }
      }

      await _loadAllSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("設定をインポートしました。")),
        );
      }
    } catch (e) {
      _showErrorDialog("インポートに失敗しました。無効なJSONフォーマットです。\n$e");
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("インポートエラー"),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  // ショートカット編集ダイアログ
  void _editShortcut(int index) {
    if (_extCommands.isEmpty) {
      _loadExtCmds();
    }
    final controller = TextEditingController(text: _shortcuts[index]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${_shortcutLabels[index]} を編集"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "例: i, d, #terrain, #herecmdmenu 等",
                helperText: "#で始まるものは拡張コマンドとして入力送信されます",
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("拡張コマンド"),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _extCommands.length,
                        itemBuilder: (context, idx) {
                          final item = _extCommands[idx];
                          final cmd = item['command'] ?? '';
                          final desc = item['description'] ?? '';
                          final displayText = desc.isNotEmpty ? "$cmd ($desc)" : cmd;
                          return ListTile(
                            title: Text(displayText),
                            onTap: () {
                              controller.text = cmd;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("キャンセル"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("拡張コマンドから選択..."),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              setState(() {
                _shortcuts[index] = val;
              });
              _saveSetting('shortcut_btn_$index', val);
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  Widget _buildTilesetSection() {
    return ExpansionTile(
      leading: const Icon(Icons.palette, color: Colors.deepPurpleAccent),
      title: const Text("タイルセット設定"),
      children: [
        SwitchListTile(
          title: const Text("タイル表示を使用"),
          subtitle: const Text("無効時はアスキー（文字）マップになります"),
          value: _useTiles,
          onChanged: (val) {
            setState(() => _useTiles = val);
            _saveSetting('use_tiles', val);
          },
        ),
        if (_useTiles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            key: const ValueKey("tileset_dropdown"),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "タイルセットの選択"),
              value: _selectedTileset,
              items: const [
                DropdownMenuItem(value: 'nevanda_32x32', child: Text('Nevanda (32x32)')),
                DropdownMenuItem(value: 'pixelhack_32x32', child: Text('PixelHack (32x32)')),
                DropdownMenuItem(value: 'default_16x16', child: Text('Default (16x16)')),
                DropdownMenuItem(value: 'geoduck_15x25', child: Text('Geoduck (15x25)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTileset = val);
                  _saveSetting('selected_tileset', val);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildControllerSection() {
    return ExpansionTile(
      leading: const Icon(Icons.gamepad, color: Colors.amber),
      title: const Text("操作盤・ステータス設定"),
      children: [
        ListTile(
          title: const Text("操作モード"),
          trailing: DropdownButton<String>(
            value: _controllerMode,
            items: const [
              DropdownMenuItem(value: 'pad', child: Text('ボタンパッド')),
              DropdownMenuItem(value: 'keyboard', child: Text('フルキーボード')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _controllerMode = val);
                _saveSetting('controller_mode', val);
              }
            },
          ),
        ),
        ListTile(
          title: const Text("ステータス表示モード"),
          trailing: DropdownButton<int>(
            value: _statusDisplayMode,
            items: const [
              DropdownMenuItem(value: 0, child: Text('自動縮小フィット')),
              DropdownMenuItem(value: 1, child: Text('領域の可変高さ')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _statusDisplayMode = val);
                _saveSetting('status_display_mode', val);
              }
            },
          ),
        ),
        ListTile(
          title: const Text("ボタン不透明度"),
          subtitle: Slider(
            value: _padOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: _padOpacity.toStringAsFixed(1),
            onChanged: (val) {
              setState(() => _padOpacity = val);
              _saveSetting('pad_opacity', val);
            },
          ),
        ),
        ListTile(
          title: const Text("ボタンサイズ倍率"),
          subtitle: Slider(
            value: _padScale,
            min: 0.6,
            max: 1.5,
            divisions: 9,
            label: _padScale.toStringAsFixed(1),
            onChanged: (val) {
              setState(() => _padScale = val);
              _saveSetting('pad_scale', val);
            },
          ),
        ),
        ListTile(
          title: const Text("メニュー(ドロワー)の引き出し位置"),
          trailing: DropdownButton<String>(
            value: _drawerPosition,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('左側 (スワイプ可)', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'right', child: Text('右側 (スワイプ可)', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'top', child: Text('上部', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'bottom', child: Text('下部', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _drawerPosition = val);
                _saveSetting('drawer_position', val);
              }
            },
          ),
        ),
        ListTile(
          title: const Text("半透明メニューボタンの配置位置"),
          trailing: DropdownButton<String>(
            value: _menuButtonPosition,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'top_left', child: Text('左上', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'top_right', child: Text('右上', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'left_edge', child: Text('左端(中央)', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'right_edge', child: Text('右端(中央)', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'bottom_left', child: Text('左下', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'bottom_right', child: Text('右下', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _menuButtonPosition = val);
                _saveSetting('menu_button_position', val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyActionSection() {
    const volActions = {
      0: "機能なし (通常音量変化)",
      10: "決定 (Enter)",
      32: "スペース",
      27: "エスケープ (Esc)",
      105: "インベントリ (i)",
      115: "周囲の探索 (s)",
      18: "画面再描画 (^R)",
    };

    const backActions = {
      0: "機能なし (通常通りアプリを閉じる)",
      27: "エスケープ (Esc/ダイアログ閉じ)",
      105: "インベントリ (i)",
      115: "周囲の探索 (s)",
    };

    return ExpansionTile(
      leading: const Icon(Icons.keyboard, color: Colors.blueAccent),
      title: const Text("物理キーカスタムアクション"),
      subtitle: const Text("音量ボタンや戻るキーにゲームコマンドを割り当てます"),
      children: [
        ListTile(
          title: const Text("音量アップキー"),
          trailing: DropdownButton<int>(
            value: _volupAction,
            items: volActions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _volupAction = val);
                _saveSetting('key_volup_action', val);
                _syncNativeKeySettings();
              }
            },
          ),
        ),
        ListTile(
          title: const Text("音量ダウンキー"),
          trailing: DropdownButton<int>(
            value: _voldownAction,
            items: volActions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _voldownAction = val);
                _saveSetting('key_voldown_action', val);
                _syncNativeKeySettings();
              }
            },
          ),
        ),
        ListTile(
          title: const Text("戻るボタン"),
          trailing: DropdownButton<int>(
            value: _backAction,
            items: backActions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _backAction = val);
                _saveSetting('key_back_action', val);
                _syncNativeKeySettings();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutSection() {
    return ExpansionTile(
      leading: const Icon(Icons.grid_3x3, color: Colors.cyanAccent),
      title: const Text("ショートカットカスタマイズ"),
      subtitle: const Text("3x3ショートカットパッドに割り当てるキーを設定"),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final cmd = _shortcuts[index];
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () => _editShortcut(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _shortcutLabels[index].split(' ')[0],
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    cmd.isEmpty ? "(未設定)" : cmd,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return ExpansionTile(
      leading: const Icon(Icons.tune, color: Colors.orangeAccent),
      title: const Text("高度な設定"),
      children: [
        ListTile(
          leading: const Icon(Icons.edit_note, color: Colors.white),
          title: const Text("defaults.nh を手動で編集"),
          subtitle: const Text("詳細なゲームオプションファイルを直接記述します"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DefaultsEditor(defaultsFilePath: widget.defaultsFilePath),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_upload, color: Colors.lightBlueAccent),
          title: const Text("設定をエクスポート"),
          subtitle: const Text("現在の設定をJSON文字列でクリップボードにコピー"),
          onTap: _exportSettings,
        ),
        ListTile(
          leading: const Icon(Icons.file_download, color: Colors.lightGreenAccent),
          title: const Text("設定をインポート"),
          subtitle: const Text("クリップボードの設定JSONを読み込んで適用します"),
          onTap: _importSettings,
        ),
      ],
    );
  }

  Widget _buildCreditsSection() {
    return ExpansionTile(
      leading: const Icon(Icons.info_outline, color: Colors.pinkAccent),
      title: const Text("クレジット"),
      children: const [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NetHackJP Android/Flutter Port",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent),
              ),
              SizedBox(height: 8),
              Text("このアプリは NetHackJP を Android および Flutter に移植したものです。"),
              SizedBox(height: 12),
              Text(
                "Contributors:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              SizedBox(height: 4),
              Text("• TBD (Original ForkFront Developer)"),
              Text("• @satokiyon (NetHackJP Contributor)"),
              Text("• Google DeepMind Advanced Agentic Coding Team"),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("詳細ゲーム設定"),
      ),
      body: ListView(
        children: [
          _buildTilesetSection(),
          _buildControllerSection(),
          _buildCmdPanelSection(), // 追加
          _buildKeyActionSection(),
          _buildShortcutSection(),
          _buildAdvancedSection(),
          _buildCreditsSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  Future<void> _savePanels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('panel_count', _panels.length);
    for (int i = 0; i < _panels.length; i++) {
      await prefs.setString('pName_$i', _panels[i]['name']);
      await prefs.setString('pCmdString_$i', _panels[i]['cmds']);
    }
    // 古い定義を消去
    for (int i = _panels.length; i < 10; i++) {
      await prefs.remove('pName_$i');
      await prefs.remove('pCmdString_$i');
    }
  }

  void _editPanel(int index) {
    final nameController = TextEditingController(text: _panels[index]['name']);
    final cmdsController = TextEditingController(text: _panels[index]['cmds']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("パネル ${index + 1} を編集"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "パネル名"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cmdsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "ボタンコマンド一覧",
                helperText: "スペース区切りでコマンドを入力してください",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _panels[index]['name'] = nameController.text.trim();
                _panels[index]['cmds'] = cmdsController.text.trim();
              });
              _savePanels();
              Navigator.pop(context);
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  Widget _buildCmdPanelSection() {
    return ExpansionTile(
      leading: const Icon(Icons.dashboard_customize, color: Colors.indigoAccent),
      title: const Text("コマンドパネル編集"),
      subtitle: const Text("ゲーム下部スワイプ対応のボタン群を管理"),
      children: [
        SwitchListTile(
          title: const Text("パネル名を表示"),
          subtitle: const Text("各パネル行の左端に名前バッジを表示"),
          value: _showPanelNames,
          onChanged: (val) {
            setState(() => _showPanelNames = val);
            _saveSetting('show_panel_names', val);
          },
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _panels.length,
          itemBuilder: (context, index) {
            final panel = _panels[index];
            return ListTile(
              title: Text(panel['name']),
              subtitle: Text(
                panel['cmds'].toString().isEmpty ? "(ボタンなし)" : panel['cmds'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.amber),
                    onPressed: () => _editPanel(index),
                  ),
                  if (_panels.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _panels.removeAt(index);
                        });
                        _savePanels();
                      },
                    ),
                ],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.add, color: Colors.green),
          title: const Text("新しいコマンドパネルを追加"),
          onTap: () {
            setState(() {
              _panels.add({
                'name': "パネル ${_panels.length + 1}",
                'cmds': "e d r z Z q t f w x i",
              });
            });
            _savePanels();
          },
        ),
      ],
    );
  }
}
