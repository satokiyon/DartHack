import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'defaults_editor.dart';
import 'models/ext_cmd_entry.dart';
import 'nethack_cmd_panel.dart';
import 'nethack_ffi.dart';
import 'utils/defaults_helper.dart';
import 'utils/scale_clamp.dart';
import 'widgets/shortcut_edit_dialog.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';


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
  String _selectedLanguage = 'ja';
  String _selectedTileset = 'pixelhack_32x32';
  String _controllerMode = 'pad';
  int _statusDisplayMode = 0;
  int _tombstoneDisplayMode = 0; // 0: 画像+文字オーバーレイ, 1: Cコア出力そのまま(テキスト)
  int _screenMode = 0; // 0: 通常, 1: イマーシブ
  double _padOpacity = 0.8;
  double _dpadScale = 1.0;
  double _shortcutPadScale = 1.0;
  double _cmdPanelScale = 1.0;
  String _drawerPosition = 'left';
  String _menuButtonPosition = 'bottom_left';
  // ignore: unused_field
  bool _showMapButton = true;
  String _mapButtonPosition = 'bottom_right';
  String _dpadPosition = 'bottom_left';
  String _shortcutPosition = 'bottom_right';
  String _msgPosition = 'bottom';
  // ignore: unused_field
  int _msgCharWidth = 30; // main.dart での設定ロード互換のため保持
  String _statusPosition = 'bottom';
  String _cmdPanelPosition = 'top';
  int _layoutPattern = 1; // UIレイアウトパターン (1 or 2)
  bool _swapPadSide = false; // 移動パッドとショートカットパッドの左右反転
  String _dpadLongPressMoveMode = 'G_UPPER';
  String _mapTapTravelMode = 'always';

  // defaults.nh 連動ゲームオプション
  int _optTutorialMode = 0;
  bool _optAutopickup = false;
  String _optPickupTypes = r'$"=/!?+';
  bool _optTime = true;
  bool _optShowexp = true;
  bool _optPriceQuotes = true;
  bool _optHiliteStatus = true;
  bool _optMenucolor = true;
  String _optName = '';
  String _optDogname = '';
  String _optCatname = '';
  String _optHorsename = '';
  String _optFruit = '';
  int _optNumberPad = 0;

  Map<String, String> _getItemTypeSymbols(AppLocalizations l10n) => {
    '\$': l10n.itemGold,
    '"': l10n.itemAmulet,
    '[': l10n.itemArmor,
    '%': l10n.itemFood,
    '?': l10n.itemScroll,
    '+': l10n.itemSpellbook,
    '/': l10n.itemWand,
    '=': l10n.itemRing,
    '!': l10n.itemPotion,
    '(': l10n.itemTool,
    '*': l10n.itemGem,
    '0': l10n.itemBall,
    ')': l10n.itemWeapon,
    '_': l10n.itemOther,
  };

  // メッセージ領域設定
  int _msgLineCount = 5;      // 表示行数 (1〜15)
  double _msgOpacity = 0.40;  // 背景透過度 (0.0〜1.0)
  double _msgFontSize = 13.0; // フォントサイズ (pt)

  // 物理キー割り当て (デフォルト: 0 = なし)
  int _volupAction = 0;
  int _voldownAction = 0;
  int _backAction = 0;

  // ショートカット設定 (0～8)
  final List<String> _shortcuts = List.filled(9, "");
  final List<String> _defaultShortcuts = [
    'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', '#chat', '#chronicle', '#overview', r'\\e'
  ];

  String _getShortcutButtonLabel(AppLocalizations l10n, int index) {
    final positions = [
      l10n.shortcutBtnTL, l10n.shortcutBtnTC, l10n.shortcutBtnTR,
      l10n.shortcutBtnML, l10n.shortcutBtnMC, l10n.shortcutBtnMR,
      l10n.shortcutBtnBL, l10n.shortcutBtnBC, l10n.shortcutBtnBR,
    ];
    return l10n.shortcutLabelFormat(positions[index], index.toString());
  }

  final _channel = const MethodChannel('jp.satokiyo.darthack/key_interceptor');

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

  String _utf8DecodeLossy(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return '';
    final Pointer<Uint8> temp = ptr.cast<Uint8>();
    int len = 0;
    while (temp[len] != 0) {
      len++;
    }
    final bytes = temp.asTypedList(len);
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }

  void _loadExtCmds() {
    try {
      final ffi = NetHackFfi();
      final ptr = ffi.getExtCmdsFlutter();
      if (ptr != nullptr) {
        final extCmdsStr = _utf8DecodeLossy(ptr);
        final parsed = <Map<String, String>>[];
        final rawItems = extCmdsStr.split('\n');
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
    final defaultsHelper = DefaultsHelper();
    await defaultsHelper.syncFromFileToPrefs(widget.defaultsFilePath);

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useTiles = prefs.getBool('use_tiles') ?? true;
      _selectedLanguage = prefs.getString('selected_language') ?? 'ja';
      _selectedTileset = prefs.getString('selected_tileset') ?? 'pixelhack_32x32';
      _controllerMode = prefs.getString('controller_mode') ?? 'pad';
      _statusDisplayMode = prefs.getInt('status_display_mode') ?? 0;
      final tombstoneModeRaw = prefs.getInt('tombstone_display_mode');
      _tombstoneDisplayMode = (tombstoneModeRaw == 1) ? 1 : 0;
      final screenModeRaw = prefs.getInt('screen_mode');
      _screenMode = (screenModeRaw == 1) ? 1 : 0;
      _padOpacity = prefs.getDouble('pad_opacity') ?? 0.8;
      _dpadScale = prefs.getDouble('dpad_scale') ?? 1.0;
      _shortcutPadScale = prefs.getDouble('shortcut_pad_scale') ?? 1.0;
      _cmdPanelScale = prefs.getDouble('cmd_panel_scale') ?? 1.0;
      _drawerPosition = prefs.getString('drawer_position') ?? 'left';
      _menuButtonPosition = prefs.getString('menu_button_position') ?? 'bottom_left';
      _showMapButton = prefs.getBool('show_map_button') ?? true;
      _mapButtonPosition = prefs.getString('map_button_position') ?? 'bottom_right';
      _dpadPosition = prefs.getString('dpad_position') ?? 'bottom_left';
      _shortcutPosition = prefs.getString('shortcut_position') ?? 'bottom_right';
      _msgPosition = prefs.getString('msg_position') ?? 'top';
      _msgCharWidth = prefs.getInt('msg_char_width') ?? 30;
      _statusPosition = prefs.getString('status_position') ?? 'top';
      _cmdPanelPosition = prefs.getString('cmd_panel_position') ?? 'bottom';
      _layoutPattern = prefs.getInt('layout_pattern') ?? 1;
      _swapPadSide = prefs.getBool('swap_pad_side') ?? false;
      // パターン番号から各配置変数を復元（左右反転も反映）
      final patternDef = _layoutPatterns[_layoutPattern];
      if (patternDef != null) {
        var dpadPos = patternDef['dpad_position'] ?? _dpadPosition;
        var scPos = patternDef['shortcut_position'] ?? _shortcutPosition;
        if (_swapPadSide) {
          dpadPos = _swapPositionLeftRight(dpadPos);
          scPos = _swapPositionLeftRight(scPos);
        }
        _dpadPosition       = dpadPos;
        _shortcutPosition   = scPos;
        _msgPosition        = patternDef['msg_position'] ?? _msgPosition;
        _statusPosition     = patternDef['status_position'] ?? _statusPosition;
        _cmdPanelPosition   = patternDef['cmd_panel_position'] ?? _cmdPanelPosition;
      }
      _dpadLongPressMoveMode = prefs.getString('dpad_long_press_move_mode') ?? 'G_UPPER';
      _mapTapTravelMode = prefs.getString('map_tap_travel_mode') ?? 'always';

      _volupAction = prefs.getInt('key_volup_action') ?? 0;
      _voldownAction = prefs.getInt('key_voldown_action') ?? 0;
      _backAction = prefs.getInt('key_back_action') ?? 0;

      // メッセージ領域設定のロード
      _msgLineCount = prefs.getInt('msg_line_count') ?? 5;
      _msgOpacity = prefs.getDouble('msg_opacity') ?? 0.40;
      _msgFontSize = prefs.getDouble('msg_font_size') ?? 13.0;

      // ゲームオプション (defaults.nh 連動) のロード
      _optTutorialMode = prefs.getInt('nh_opt_tutorial_mode') ?? 0;
      _optAutopickup = prefs.getBool('nh_opt_autopickup') ?? false;
      _optPickupTypes = prefs.getString('nh_opt_pickup_types') ?? r'$"=/!?+';
      _optTime = prefs.getBool('nh_opt_time') ?? true;
      _optShowexp = prefs.getBool('nh_opt_showexp') ?? true;
      _optPriceQuotes = prefs.getBool('nh_opt_price_quotes') ?? true;
      _optHiliteStatus = prefs.getBool('nh_opt_hilite_status') ?? true;
      _optMenucolor = prefs.getBool('nh_opt_menucolor') ?? true;
      _optName = prefs.getString('nh_opt_name') ?? '';
      _optDogname = prefs.getString('nh_opt_dogname') ?? '';
      _optCatname = prefs.getString('nh_opt_catname') ?? '';
      _optHorsename = prefs.getString('nh_opt_horsename') ?? '';
      _optFruit = prefs.getString('nh_opt_fruit') ?? '';
      _optNumberPad = prefs.getInt('nh_opt_number_pad') ?? 0;

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

  // UIレイアウトパターン定義
  // キー: パターン番号 (1, 2, ...)
  // 値: SharedPreferences キー -> 設定値 の Map
  static const Map<int, Map<String, String>> _layoutPatterns = {
    1: {
      'status_position':   'top',
      'msg_position':      'top',
      'dpad_position':     'bottom_left',
      'shortcut_position': 'bottom_right',
      'cmd_panel_position':'bottom',
      'menu_button_position': 'bottom_left',
      'map_button_position':  'bottom_right',
    },
    2: {
      'status_position':   'bottom',
      'msg_position':      'bottom',
      'dpad_position':     'top_left',
      'shortcut_position': 'top_right',
      'cmd_panel_position':'top',
      'menu_button_position': 'top_left',
      'map_button_position':  'top_right',
    },
  };

  /// 位置文字列の left と right を入れ替える
  String _swapPositionLeftRight(String pos) {
    if (pos.endsWith('left')) {
      return pos.replaceAll('left', 'right');
    } else if (pos.endsWith('right')) {
      return pos.replaceAll('right', 'left');
    }
    return pos;
  }

  /// パターンを適用して個別設定キーを一括保存し、UIに反映する
  Future<void> _applyPattern(int pattern) async {
    final def = _layoutPatterns[pattern];
    if (def == null) return;

    var dpadPos = def['dpad_position']!;
    var scPos = def['shortcut_position']!;
    if (_swapPadSide) {
      dpadPos = _swapPositionLeftRight(dpadPos);
      scPos = _swapPositionLeftRight(scPos);
    }

    setState(() {
      _layoutPattern        = pattern;
      _statusPosition       = def['status_position']!;
      _msgPosition          = def['msg_position']!;
      _dpadPosition         = dpadPos;
      _shortcutPosition     = scPos;
      _cmdPanelPosition     = def['cmd_panel_position']!;
      _menuButtonPosition   = def['menu_button_position']!;
      _mapButtonPosition    = def['map_button_position']!;
    });

    // 個別キーとパターン番号を SharedPreferences に一括保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('layout_pattern', pattern);
    for (final entry in def.entries) {
      if (entry.key == 'dpad_position') {
        await prefs.setString('dpad_position', dpadPos);
      } else if (entry.key == 'shortcut_position') {
        await prefs.setString('shortcut_position', scPos);
      } else {
        await prefs.setString(entry.key, entry.value);
      }
    }
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

  Future<void> _saveGameOption<T>(String key, T value) async {
    await _saveSetting(key, value);
    final defaultsHelper = DefaultsHelper();
    await defaultsHelper.syncFromPrefsToFile(widget.defaultsFilePath);
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
    final l10n = AppLocalizations.of(context)!;
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
        SnackBar(content: Text(l10n.copiedJsonSuccess)),
      );
    }
  }

  // クリップボードからインポート
  Future<void> _importSettings() async {
    final l10n = AppLocalizations.of(context)!;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      _showErrorDialog(l10n.noTextInClipboard);
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
          if (key == 'pad_opacity' ||
              key == 'dpad_scale' ||
              key == 'shortcut_pad_scale' ||
              key == 'cmd_panel_scale') {
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
          SnackBar(content: Text(l10n.importedSuccess)),
        );
      }
    } catch (e) {
      _showErrorDialog(l10n.importErrorMsg(e.toString()));
    }
  }

  void _showErrorDialog(String msg) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importErrorTitle),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok)),
        ],
      ),
    );
  }

  // ショートカット編集ダイアログ
  void _editShortcut(int index) {
    if (_extCommands.isEmpty) {
      _loadExtCmds();
    }
    final extCmdEntries = _extCommands
        .map((e) => ExtCmdEntry(
              command: e['command'] ?? '',
              description: e['description'] ?? '',
            ))
        .toList();

    showShortcutEditDialog(
      context: context,
      index: index,
      extCmdList: extCmdEntries,
      onSaved: () async {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _shortcuts[index] = prefs.getString('shortcut_btn_$index') ?? _defaultShortcuts[index];
        });
      },
    );
  }

  Widget _buildSectionCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    if (children.isEmpty) return children;
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Colors.white12,
        ));
      }
    }
    return result;
  }

  Widget _buildScreenModeSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.crop_landscape, color: Colors.greenAccent),
        title: Text(l10n.secStatusTitle),
        subtitle: Text(l10n.secStatusSub),
        children: _withDividers([
          ListTile(
            title: Text(l10n.displayLanguage),
            subtitle: Text(l10n.displayLanguageSub),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: [
                DropdownMenuItem(value: 'ja', child: Text(l10n.japanese)),
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                  _saveSetting('selected_language', val);
                  if (mounted) {
                    MyApp.of(context)?.setLocale(val);
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              l10n.coreLangNote,
              style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
            ),
          ),
          ListTile(
            title: Text(l10n.screenMode),
            trailing: DropdownButton<int>(
              value: _screenMode,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.screenModeNormal)),
                DropdownMenuItem(value: 1, child: Text(l10n.screenModeImmersive)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _screenMode = val);
                  _saveSetting('screen_mode', val);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.statusDisplayMode),
            trailing: DropdownButton<int>(
              value: _statusDisplayMode,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.statusModeAuto)),
                DropdownMenuItem(value: 1, child: Text(l10n.statusModeVariable)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _statusDisplayMode = val);
                  _saveSetting('status_display_mode', val);
                }
              },
            ),
          ), 
        ]),
      ),
    );
  }

  Widget _buildTilesetSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.palette, color: Colors.deepPurpleAccent),
        title: Text(l10n.secTilesetTitle),
        children: _withDividers([
          SwitchListTile(
            title: Text(l10n.useTiles),
            subtitle: Text(l10n.useTilesSub),
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
                decoration: InputDecoration(labelText: l10n.tilesetSelect),
                initialValue: _selectedTileset,
                items: const [
                  DropdownMenuItem(value: 'nevanda_32x32', child: Text('Nevanda (32x32)')),
                  DropdownMenuItem(value: 'pixelhack_32x32', child: Text('PixelHack (32x32)')),
                  DropdownMenuItem(value: 'zeldhack_32x32', child: Text('ZeldHack (32x32)')),
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
        ]),
      ),
    );
  }

  Widget _buildUILayoutSection() {
    final l10n = AppLocalizations.of(context)!;
    final patternDescriptions = {
      1: l10n.layoutPatternDesc1,
      2: l10n.layoutPatternDesc2,
    };

    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.dashboard_customize, color: Colors.cyanAccent),
        title: Text(l10n.secUILayoutTitle),
        subtitle: Text(l10n.secUILayoutSub),
        children: _withDividers([
          // パターン選択 (RadioGroup)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Text(l10n.layoutPatternLabel, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ),
                // ignore: deprecated_member_use
                for (final entry in patternDescriptions.entries)
                  // ignore: deprecated_member_use
                  ListTile(
                    leading: Radio<int>(
                      value: entry.key,
                      // ignore: deprecated_member_use
                      groupValue: _layoutPattern,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) _applyPattern(val);
                      },
                    ),
                    title: Text(entry.key == 1 ? l10n.layoutPattern1 : l10n.layoutPattern2),
                    subtitle: Text(entry.value, style: const TextStyle(fontSize: 12)),
                    onTap: () => _applyPattern(entry.key),
                  ),
              ],
            ),
          ),
          // 移動パッドとショートカットの左右入れ替えスイッチ
          SwitchListTile(
            title: Text(l10n.swapPadSideTitle),
            subtitle: Text(l10n.swapPadSideDesc),
            value: _swapPadSide,
            onChanged: (val) {
              setState(() => _swapPadSide = val);
              _saveSetting('swap_pad_side', val);
              _applyPattern(_layoutPattern);
            },
          ),
          // メニューボタン・地図ボタンの配置設定（個別設定として残す）
          ListTile(
            title: Text(l10n.menuButtonPos),
            trailing: DropdownButton<String>(
              value: _menuButtonPosition,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(value: 'top_left', child: Text(l10n.posTopLeft, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'top_right', child: Text(l10n.posTopRight, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'left_edge', child: Text(l10n.posLeftEdge, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'right_edge', child: Text(l10n.posRightEdge, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bottom_left', child: Text(l10n.posBottomLeft, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bottom_right', child: Text(l10n.posBottomRight, style: const TextStyle(color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _menuButtonPosition = val);
                  _saveSetting('menu_button_position', val);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.mapButtonPos),
            trailing: DropdownButton<String>(
              value: _mapButtonPosition,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(value: 'top_left', child: Text(l10n.posTopLeft, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'top_right', child: Text(l10n.posTopRight, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'left_edge', child: Text(l10n.posLeftEdge, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'right_edge', child: Text(l10n.posRightEdge, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bottom_left', child: Text(l10n.posBottomLeft, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bottom_right', child: Text(l10n.posBottomRight, style: const TextStyle(color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _mapButtonPosition = val);
                  _saveSetting('map_button_position', val);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildControllerSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.gamepad, color: Colors.amber),
        title: Text(l10n.secControllerTitle),
        children: _withDividers([
          ListTile(
            title: Text(l10n.controllerMode),
            trailing: DropdownButton<String>(
              value: _controllerMode,
              items: [
                DropdownMenuItem(value: 'pad', child: Text(l10n.modePad)),
                DropdownMenuItem(value: 'keyboard', child: Text(l10n.modeKeyboard)),
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
            title: Text(l10n.padOpacityTitle),
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
            title: Text(l10n.dpadScaleTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _dpadScale,
                  min: 0.6,
                  max: 1.5,
                  divisions: 9,
                  label: _dpadScale.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() => _dpadScale = val);
                    _saveSetting('dpad_scale', val);
                  },
                ),
                _buildAppliedScaleLabel(
                  setting: _dpadScale,
                  effective: _previewDpadEffectiveScale,
                  label: l10n.dpadScaleLabel,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.dpadLongPressTitle),
            trailing: DropdownButton<String>(
              value: _dpadLongPressMoveMode,
              items: [
                DropdownMenuItem(value: 'NORMAL', child: Text(l10n.dpadModeNormal)),
                DropdownMenuItem(value: 'UPPER', child: Text(l10n.dpadModeUpper)),
                DropdownMenuItem(value: 'G_LOWER', child: Text(l10n.dpadModeGLower)),
                DropdownMenuItem(value: 'G_UPPER', child: Text(l10n.dpadModeGUpper)),
                DropdownMenuItem(value: 'CTRL', child: Text(l10n.dpadModeCtrl)),
                DropdownMenuItem(value: 'M_CMD', child: Text(l10n.dpadModeMCmd)),
                DropdownMenuItem(value: 'F_CMD', child: Text(l10n.dpadModeFCmd)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _dpadLongPressMoveMode = val);
                  _saveSetting('dpad_long_press_move_mode', val);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.mapTapTravelTitle),
            trailing: DropdownButton<String>(
              value: _mapTapTravelMode,
              items: [
                DropdownMenuItem(value: 'always', child: Text(l10n.mapTapAlways)),
                DropdownMenuItem(value: 'after_scroll', child: Text(l10n.mapTapAfterScroll)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _mapTapTravelMode = val);
                  _saveSetting('map_tap_travel_mode', val);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.shortcutPadScaleTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _shortcutPadScale,
                  min: 0.6,
                  max: 1.5,
                  divisions: 9,
                  label: _shortcutPadScale.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() => _shortcutPadScale = val);
                    _saveSetting('shortcut_pad_scale', val);
                  },
                ),
                _buildAppliedScaleLabel(
                  setting: _shortcutPadScale,
                  effective: _previewShortcutPadEffectiveScale,
                  label: l10n.shortcutPadScaleLabel,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.cmdPanelScaleTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _cmdPanelScale,
                  min: 0.6,
                  max: 1.5,
                  divisions: 9,
                  label: _cmdPanelScale.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() => _cmdPanelScale = val);
                    _saveSetting('cmd_panel_scale', val);
                  },
                ),
                _buildAppliedScaleLabel(
                  setting: _cmdPanelScale,
                  effective: _cmdPanelScale,
                  label: l10n.cmdPanelScaleLabel,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.drawerPosTitle),
            trailing: DropdownButton<String>(
              value: _drawerPosition,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(value: 'left', child: Text(l10n.posLeft, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'right', child: Text(l10n.posRight, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'top', child: Text(l10n.posTop, style: const TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'bottom', child: Text(l10n.posBottom, style: const TextStyle(color: Colors.white))),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _drawerPosition = val);
                  _saveSetting('drawer_position', val);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }

  double get _previewDpadEffectiveScale {
    if (!mounted) return _dpadScale;
    final width = MediaQuery.of(context).size.width;
    return calculatePadClamp(
      dpadScale: _dpadScale,
      shortcutPadScale: _shortcutPadScale,
      screenWidth: width,
    ).dpadEffectiveScale;
  }

  double get _previewShortcutPadEffectiveScale {
    if (!mounted) return _shortcutPadScale;
    final width = MediaQuery.of(context).size.width;
    return calculatePadClamp(
      dpadScale: _dpadScale,
      shortcutPadScale: _shortcutPadScale,
      screenWidth: width,
    ).shortcutPadEffectiveScale;
  }

  Widget _buildAppliedScaleLabel({
    required double setting,
    required double effective,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isClamped = (setting - effective).abs() > 0.01;
    final clampedColor = Colors.amber[300] ?? const Color(0xFFFFD54F);
    final color = isClamped ? clampedColor : Colors.white60;
    final fontWeight = isClamped ? FontWeight.bold : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Text(
            l10n.appliedScale(effective.toStringAsFixed(2)),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: fontWeight,
            ),
          ),
          if (isClamped) ...[
            const SizedBox(width: 6),
            Text(
              l10n.autoAdjustedScreen,
              style: TextStyle(
                fontSize: 10,
                color: clampedColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ステータス・メッセージ領域の表示設定セクション
  Widget _buildMessageSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.chat_bubble_outline, color: Colors.tealAccent),
        title: Text(l10n.secMsgTitle),
        subtitle: Text(l10n.secMsgSub),
        children: _withDividers([         
          // 行数スライダー（1〜15）
          ListTile(
            title: Text(l10n.msgLineCount),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _msgLineCount.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '$_msgLineCount',
                  onChanged: (val) {
                    final intVal = val.round();
                    setState(() => _msgLineCount = intVal);
                    _saveSetting('msg_line_count', intVal);
                  },
                ),
                Text(
                  l10n.msgLineCountLabel(_msgLineCount.toString()),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          // 透過度スライダー（0〜100、実際は 0.0〜1.0 で保存）
          ListTile(
            title: Text(l10n.msgOpacity),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _msgOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(_msgOpacity * 100).round()}%',
                  onChanged: (val) {
                    setState(() => _msgOpacity = val);
                    _saveSetting('msg_opacity', val);
                  },
                ),
                Text(
                  l10n.msgOpacityLabel((_msgOpacity * 100).round().toString()),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          // フォントサイズスライダー（8〜24）
          ListTile(
            title: Text(l10n.msgFontSize),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _msgFontSize,
                  min: 8.0,
                  max: 24.0,
                  divisions: 16,
                  label: '${_msgFontSize.round()} pt',
                  onChanged: (val) {
                    setState(() => _msgFontSize = val);
                    _saveSetting('msg_font_size', val);
                  },
                ),
                Text(
                  l10n.msgFontSizeLabel(_msgFontSize.round().toString()),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          // プレビュー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.preview,
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Stack(
                    children: [
                      // 背景（マップのイメージ）
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blueGrey[900]!, Colors.blueGrey[800]!],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            '.  .  .  @  .  .\n.  .  .  .  .  .\n.  .  .  .  d  .',
                            style: TextStyle(
                              color: Colors.white24,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // メッセージオーバーレイのプレビュー
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withValues(alpha: _msgOpacity),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            l10n.msgSampleText,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: _msgFontSize,
                            ),
                            maxLines: _msgLineCount,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildKeyActionSection() {
    final l10n = AppLocalizations.of(context)!;
    final volActions = {
      0: l10n.volActNone,
      10: l10n.volActEnter,
      32: l10n.volActSpace,
      27: l10n.volActEsc,
      105: l10n.volActInv,
      115: l10n.volActSearch,
      18: l10n.volActRedraw,
    };

    final backActions = {
      0: l10n.backActNone,
      27: l10n.backActEsc,
      105: l10n.backActInv,
      115: l10n.backActSearch,
      46: l10n.backActWait,
      83: l10n.backActSave,
    };

    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.keyboard, color: Colors.blueAccent),
        title: Text(l10n.secKeyTitle),
        subtitle: Text(l10n.secKeySub),
        children: _withDividers([
          ListTile(
            title: Text(l10n.keyVolUpTitle),
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
            title: Text(l10n.keyVolDownTitle),
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
            title: Text(l10n.keyBackTitle),
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
        ]),
      ),
    );
  }

  Widget _buildShortcutSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.grid_3x3, color: Colors.cyanAccent),
        title: Text(l10n.secShortcutTitle),
        subtitle: Text(l10n.secShortcutSub),
        children: _withDividers([
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
              final raw = _shortcuts[index];
              final parsed = CmdItem.parseCmds(raw);
              final item = parsed.isNotEmpty ? parsed.first : CmdItem(command: raw);
              final displayStr = item.displayLabel;
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
                      _getShortcutButtonLabel(l10n, index).split(' ')[0],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      displayStr.isEmpty ? l10n.shortcutNotSet : displayStr,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildOtherSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.more_horiz, color: Colors.lightBlueAccent),
        title: Text(l10n.secOtherTitle),
        children: _withDividers([
          ListTile(
            title: Text(l10n.tombstoneModeTitle),
            trailing: DropdownButton<int>(
              value: _tombstoneDisplayMode,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.tombstoneModeImage)),
                DropdownMenuItem(value: 1, child: Text(l10n.tombstoneModeText)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _tombstoneDisplayMode = val);
                  _saveSetting('tombstone_display_mode', val);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.tune, color: Colors.orangeAccent),
        title: Text(l10n.secAdvancedTitle),
        children: _withDividers([
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.white),
            title: Text(l10n.manualEditDefaults),
            subtitle: Text(l10n.manualEditDefaultsSub),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DefaultsEditor(defaultsFilePath: widget.defaultsFilePath),
                ),
              );
              _loadAllSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload, color: Colors.lightBlueAccent),
            title: Text(l10n.exportSettings),
            subtitle: Text(l10n.exportSettingsSub),
            onTap: _exportSettings,
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.lightGreenAccent),
            title: Text(l10n.importSettings),
            subtitle: Text(l10n.importSettingsSub),
            onTap: _importSettings,
          ),
        ]),
      ),
    );
  }

  void _editPickupTypes() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _optPickupTypes);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final currentText = controller.text;
            final symbolsMap = _getItemTypeSymbols(l10n);

            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Text(l10n.pickupTypesDialogTitle),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: l10n.directInputLabel,
                          hintText: l10n.directInputHint,
                          helperText: l10n.directInputHelper,
                        ),
                        onChanged: (val) {
                          setStateDialog(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.toggleFromOptions,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...symbolsMap.entries.map((entry) {
                        final char = entry.key;
                        final label = entry.value;
                        final isSelected = currentText.contains(char);

                        return CheckboxListTile(
                          dense: true,
                          title: Text(label),
                          value: isSelected,
                          onChanged: (checked) {
                            var text = controller.text;
                            if (checked == true) {
                              if (!text.contains(char)) {
                                text += char;
                              }
                            } else {
                              text = text.replaceAll(char, '');
                            }
                            controller.text = text;
                            setStateDialog(() {});
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final val = controller.text.trim();
                    setState(() {
                      _optPickupTypes = val;
                    });
                    _saveGameOption('nh_opt_pickup_types', val);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editStringOption(String title, String prefKey, String currentVal, int maxChars) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentVal);
    final maxBytes = maxChars > 0 ? maxChars - 1 : 31;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final bytesCount = utf8.encode(controller.text).length;
            final isOverflow = bytesCount > maxBytes;

            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.hintEmptyDefault,
                      counterText: l10n.bytesCount(bytesCount, maxBytes),
                      counterStyle: TextStyle(
                        color: isOverflow ? Colors.red : Colors.white70,
                        fontWeight: isOverflow ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onChanged: (val) {
                      setStateDialog(() {});
                    },
                  ),
                  if (isOverflow) ...[
                    const SizedBox(height: 6),
                    Text(
                      prefKey == 'nh_opt_name'
                          ? l10n.nameTooLongMaxBytes(maxBytes.toString())
                          : l10n.textTooLongMaxBytes(maxBytes.toString()),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isOverflow
                      ? null
                      : () {
                          final val = controller.text.trim();
                          setState(() {
                            if (prefKey == 'nh_opt_name') _optName = val;
                            if (prefKey == 'nh_opt_dogname') _optDogname = val;
                            if (prefKey == 'nh_opt_catname') _optCatname = val;
                            if (prefKey == 'nh_opt_horsename') _optHorsename = val;
                            if (prefKey == 'nh_opt_fruit') _optFruit = val;
                          });
                          _saveGameOption(prefKey, val);
                          Navigator.pop(context);
                        },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGameRulesSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.sports_esports, color: Colors.tealAccent),
        title: Text(l10n.secGameRulesTitle),
        subtitle: Text(l10n.secGameRulesSub),
        children: _withDividers([
          ListTile(
            title: Text(l10n.tutorialModeTitle),
            subtitle: Text(l10n.tutorialModeSub),
            trailing: DropdownButton<int>(
              value: _optTutorialMode,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.tutorialAsk)),
                DropdownMenuItem(value: 1, child: Text(l10n.tutorialAlways)),
                DropdownMenuItem(value: 2, child: Text(l10n.tutorialNever)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _optTutorialMode = val);
                  _saveGameOption('nh_opt_tutorial_mode', val);
                }
              },
            ),
          ),
          ListTile(
            title: Text(l10n.numberPadTitle),
            subtitle: Text(l10n.numberPadSub),
            trailing: DropdownButton<int>(
              value: _optNumberPad,
              items: [
                DropdownMenuItem(value: 0, child: Text(l10n.numPadOff)),
                DropdownMenuItem(value: 1, child: Text(l10n.numPadStandard)),
                DropdownMenuItem(value: 2, child: Text(l10n.numPadPCHack)),
                DropdownMenuItem(value: 3, child: Text(l10n.numPadPhone)),
                DropdownMenuItem(value: 4, child: Text(l10n.numPadPhonePCHack)),
                DropdownMenuItem(value: -1, child: Text(l10n.numPadGerman)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _optNumberPad = val);
                  _saveGameOption('nh_opt_number_pad', val);
                }
              },
            ),
          ),
          SwitchListTile(
            title: Text(l10n.optAutopickup),
            subtitle: Text(l10n.autopickupSub),
            value: _optAutopickup,
            onChanged: (val) async {
              setState(() {
                _optAutopickup = val;
                if (val && _optPickupTypes.isEmpty) {
                  _optPickupTypes = r'$"=/!?+';
                }
              });
              await _saveSetting('nh_opt_autopickup', val);
              if (val) {
                await _saveSetting('nh_opt_pickup_types', _optPickupTypes);
              }
              final defaultsHelper = DefaultsHelper();
              await defaultsHelper.syncFromPrefsToFile(widget.defaultsFilePath);
            },
          ),
          ListTile(
            enabled: _optAutopickup,
            title: Text(l10n.pickupTypesTitle),
            subtitle: Text(
              _optAutopickup
                  ? (_optPickupTypes.isEmpty ? l10n.pickupTypesAll : l10n.pickupTypesSymbols(_optPickupTypes))
                  : l10n.pickupTypesDisabledNote,
              style: TextStyle(
                color: _optAutopickup ? Colors.white70 : Colors.grey,
              ),
            ),
            onTap: _optAutopickup ? _editPickupTypes : null,
          ),
          SwitchListTile(
            title: Text(l10n.optTime),
            subtitle: Text(l10n.timeSub),
            value: _optTime,
            onChanged: (val) {
              setState(() => _optTime = val);
              _saveGameOption('nh_opt_time', val);
            },
          ),
          SwitchListTile(
            title: Text(l10n.optShowexp),
            subtitle: Text(l10n.showexpSub),
            value: _optShowexp,
            onChanged: (val) {
              setState(() => _optShowexp = val);
              _saveGameOption('nh_opt_showexp', val);
            },
          ),
          SwitchListTile(
            title: Text(l10n.optPriceQuotes),
            subtitle: Text(l10n.priceQuotesSub),
            value: _optPriceQuotes,
            onChanged: (val) {
              setState(() => _optPriceQuotes = val);
              _saveGameOption('nh_opt_price_quotes', val);
            },
          ),
          SwitchListTile(
            title: Text(l10n.optHiliteStatus),
            subtitle: Text(l10n.hiliteStatusSub),
            value: _optHiliteStatus,
            onChanged: (val) {
              setState(() => _optHiliteStatus = val);
              _saveGameOption('nh_opt_hilite_status', val);
            },
          ),
          SwitchListTile(
            title: Text(l10n.optMenucolor),
            subtitle: Text(l10n.menucolorSub),
            value: _optMenucolor,
            onChanged: (val) {
              setState(() => _optMenucolor = val);
              _saveGameOption('nh_opt_menucolor', val);
            },
          ),
          ListTile(
            title: Text(l10n.nameSub),
            subtitle: Text(_optName.isEmpty ? l10n.defaultUnspecified : _optName),
            onTap: () => _editStringOption(l10n.nameSub, 'nh_opt_name', _optName, 32),
          ),
          ListTile(
            title: Text(l10n.dognameSub),
            subtitle: Text(_optDogname.isEmpty ? l10n.defaultUnspecified : _optDogname),
            onTap: () => _editStringOption(l10n.dognameSub, 'nh_opt_dogname', _optDogname, 16),
          ),
          ListTile(
            title: Text(l10n.catnameSub),
            subtitle: Text(_optCatname.isEmpty ? l10n.defaultUnspecified : _optCatname),
            onTap: () => _editStringOption(l10n.catnameSub, 'nh_opt_catname', _optCatname, 16),
          ),
          ListTile(
            title: Text(l10n.horsenameSub),
            subtitle: Text(_optHorsename.isEmpty ? l10n.defaultUnspecified : _optHorsename),
            onTap: () => _editStringOption(l10n.horsenameSub, 'nh_opt_horsename', _optHorsename, 16),
          ),
          ListTile(
            title: Text(l10n.fruitSub),
            subtitle: Text(_optFruit.isEmpty ? l10n.defaultSlimeMold : _optFruit),
            onTap: () => _editStringOption(l10n.fruitSub, 'nh_opt_fruit', _optFruit, 16),
          ),
        ]),
      ),
    );
  }

  Widget _buildCreditsSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.info_outline, color: Colors.pinkAccent),
        title: Text(l10n.secCreditsTitle),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DartHack",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent),
                ),
                const SizedBox(height: 8),
                Text(l10n.creditsBody1),
                const SizedBox(height: 8),
                Text(l10n.creditsBody2),
                const SizedBox(height: 8),
                Text(l10n.creditsBody3),
                const SizedBox(height: 12),
                Text(
                  l10n.creditsContributors,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(l10n.creditsContributorList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPanelDisplayName(int index, String rawName) {
    final l10n = AppLocalizations.of(context);
    final isJp = Localizations.localeOf(context).languageCode == 'ja';
    if (index == 0) {
      if (rawName.isEmpty || rawName == "標準パネル" || rawName == "Default Panel") {
        return l10n?.defaultPanelName ?? (isJp ? "標準パネル" : "Default Panel");
      }
    } else {
      final defaultJp = "パネル ${index + 1}";
      final defaultEn = "Panel ${index + 1}";
      if (rawName.isEmpty || rawName == defaultJp || rawName == defaultEn) {
        return l10n?.panelNName((index + 1).toString()) ?? (isJp ? defaultJp : defaultEn);
      }
    }
    return rawName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailedSettings),
      ),
      body: ListView(
        children: [
          _buildTilesetSection(), //タイルセット設定
          _buildScreenModeSection(), //イマーシブ・ステータス表示モード・
          _buildMessageSection(),  // メッセージ設定
          const Divider(height: 1),   //区切り線
          _buildUILayoutSection(), // UI配置カスタマイズ
          _buildControllerSection(), //コントローラー設定
          _buildShortcutSection(), // ショートカットカスタマイズ
          _buildCmdPanelSection(), //コマンドパネル編集
          _buildKeyActionSection(), // 物理キーカスタムアクション
          const Divider(height: 1),   //区切り線
          _buildGameRulesSection(), //ゲームルール・プレイ設定
          _buildAdvancedSection(), // 高度な設定
          _buildOtherSection(), // その他の設定
          const Divider(height: 1),   //区切り線
          _buildCreditsSection(),  // クレジット
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

  void _appendCmdToController(TextEditingController controller, String cmdToAppend) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final before = text.substring(0, selection.start);
      final after = text.substring(selection.end);
      String insertText = cmdToAppend;
      if (before.isNotEmpty && !before.endsWith(' ')) {
        insertText = ' $insertText';
      }
      if (after.isNotEmpty && !after.startsWith(' ')) {
        insertText = '$insertText ';
      }
      final newText = before + insertText + after;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + insertText.length),
      );
    } else {
      if (text.isEmpty) {
        controller.text = cmdToAppend;
      } else if (text.endsWith(' ')) {
        controller.text = '$text$cmdToAppend';
      } else {
        controller.text = '$text $cmdToAppend';
      }
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
  }

  void _editPanel(int index) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _getPanelDisplayName(index, _panels[index]['name']));
    final cmdsController = TextEditingController(text: _panels[index]['cmds']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(l10n.editPanelTitle((index + 1).toString())),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.panelNameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cmdsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.cmdListLabel,
                helperText: l10n.cmdListHelper,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('Enter'),
                  onPressed: () => _appendCmdToController(cmdsController, r'\n'),
                ),
                ActionChip(
                  label: const Text('Space'),
                  onPressed: () => _appendCmdToController(cmdsController, r'\s'),
                ),
                ActionChip(
                  label: const Text('Esc'),
                  onPressed: () => _appendCmdToController(cmdsController, r'\e'),
                ),
                ActionChip(
                  label: const Text('[kbd] / [pad]'),
                  onPressed: () => _appendCmdToController(cmdsController, '[kbd]'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildCmdPanelSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionCard(
      ExpansionTile(
        leading: const Icon(Icons.dashboard_customize, color: Colors.indigoAccent),
        title: Text(l10n.secCmdPanelTitle),
        subtitle: Text(l10n.secCmdPanelSub),
        children: _withDividers([
          SwitchListTile(
            title: Text(l10n.showPanelNamesTitle),
            subtitle: Text(l10n.showPanelNamesSub),
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
                title: Text(_getPanelDisplayName(index, panel['name'])),
                subtitle: Text(
                  panel['cmds'].toString().isEmpty ? l10n.noButtons : panel['cmds'].toString(),
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
            title: Text(l10n.addNewPanel),
            onTap: () {
              setState(() {
                _panels.add({
                  'name': l10n.panelNName((_panels.length + 1).toString()),
                  'cmds': "e d r z Z q t f w x i",
                });
              });
              _savePanels();
            },
          ),
        ]),
      ),
    );
  }
}
