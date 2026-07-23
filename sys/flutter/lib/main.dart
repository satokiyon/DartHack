import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nethack_assets.dart';
import 'nethack_screen.dart';
import 'nethack_worker.dart';
import 'nethack_map_painter.dart';
import 'nethack_dpad.dart';
import 'nethack_cmd_panel.dart';
import 'nethack_keyboard.dart';
import 'nethack_shortcut_pad.dart';
import 'nethack_ffi.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'amount_selector_dialog.dart';
import 'utils/scale_clamp.dart';
import 'dart:ffi' hide Size;
import 'dart:convert';
import 'package:ffi/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartHack',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.amber,
        ),
        highlightColor: Colors.white.withValues(alpha: 0.25),
        splashColor: Colors.white.withValues(alpha: 0.15),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom().copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.25);
              }
              return null;
            }),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom().copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.25);
              }
              return null;
            }),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

enum PlayMode { normal, explore, wizard }

enum ControllerMode { keyboard, pad }

enum DPadMoveMode { normal, upper, gLower, gUpper, ctrl, mCmd, fCmd }

class ExtCmdEntry {
  final String command;
  final String description;

  const ExtCmdEntry({
    required this.command,
    required this.description,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const List<DPadMoveMode> _allDPadMoveModes = [
    DPadMoveMode.normal,
    DPadMoveMode.upper,
    DPadMoveMode.gLower,
    DPadMoveMode.gUpper,
    DPadMoveMode.ctrl,
    DPadMoveMode.mCmd,
    DPadMoveMode.fCmd,
  ];

  ControllerMode _controllerMode = ControllerMode.pad; // デフォルトはボタンモード

  final List<String> _logs = [];
  final FocusNode _focusNode = FocusNode();
  final NetHackScreen _screen = NetHackScreen();
  
  SendPort? _workerSendPort;
  bool _isGameRunning = false;
  bool _isGameFinished = false;
  bool _waitingForInput = false;
  bool _assetsReady = false;
  String _assetsPath = '';
  bool _autoAdvanceSavePending = false;
  int _autoAdvanceSavePendingUntilMs = 0;
  bool _exitDialogShown = false;

  // タイルセット用変数
  ui.Image? _tileImage;
  bool _useTiles = true; // デフォルトでタイル表示を有効化
  int _tileSize = 32;
  String _selectedTileset = 'nevanda_32x32';
  bool _isKeyboardVisible = true; // デフォルトで仮想キーボードを表示

  // 主人公追従・スクロール用変数
  final GlobalKey _mapViewportKey = GlobalKey();
  late TransformationController _transformationController;
  double _currentScale = 1.0; // ピンチズームで設定された現在のズーム率を保持する状態変数
  TapDownDetails? _lastMapTapDownDetails; // マップタップ時の座標一時保持用

  // --- 新規同期ダイアログ用状態変数 ---
  bool _isYnVisible = false;
  String _ynQuestion = "";
  String _ynChoices = "";
  int _ynDefault = 0;

  bool _isGetLineVisible = false;
  String _getlinePrompt = "";
  final TextEditingController _getlineController = TextEditingController();

  bool _isAskNameVisible = false;
  List<String> _askNameSaves = [];
  int _askNameMaxChars = 0;
  final TextEditingController _askNameController = TextEditingController();
  PlayMode _selectedPlayMode = PlayMode.normal;
  String _previousCustomName = "Player";
  int _numberPadMode = 0;

  // 拡張コマンドサジェスト用
  List<ExtCmdEntry> _extCmdList = [];
  List<ExtCmdEntry> _filteredExtCmds = [];
  final TextEditingController _extCmdFilterController = TextEditingController();
  final TextEditingController _extCmdMenuFilterController = TextEditingController();
  String _extCmdMenuFilter = "";
  Map<int, int> _menuSelectedCounts = <int, int>{};

  // 詳細な操作設定（shared_preferences用）
  double _padOpacity = 0.8;
  double _dpadScale = 1.0;
  double _shortcutPadScale = 1.0;
  double _cmdPanelScale = 1.0;
  // 実効 scale（クランプ適用後、build 内で更新）
  double _dpadEffectiveScale = 1.0;
  double _shortcutPadEffectiveScale = 1.0;
  double _cmdPanelEffectiveScale = 1.0;
  int _statusDisplayMode = 0; // 0: 領域に合わせて文字サイズ縮小(Fit), 1: 領域の可変高さ(Wrap)
  int _tombstoneDisplayMode = 0; // 0: 画像+文字オーバーレイ, 1: Cコア出力そのまま(テキスト)
  ScreenMode _screenMode = ScreenMode.normal; // 0: 通常, 1: イマーシブ
  String _drawerPosition = 'left';
  String _menuButtonPosition = 'top_left';
  bool _isTopDrawerOpen = false;
  bool _isBottomDrawerOpen = false;
  bool _isMainGameStarted = false;
  int? _mapWinId;
  int? _messageWinId;

  // メッセージ領域設定
  int _msgLineCount = 5;         // 表示行数 (1〜15)
  double _msgOpacity = 0.70;     // 背景透過度 (0.0〜1.0)
  double _msgFontSize = 13.0;    // フォントサイズ (pt)

  // 物理キー割り当て設定
  int _volupAction = 0;
  int _voldownAction = 0;
  int _backAction = 0;

  // 設定変更の即時反映用バージョンカウンター
  int _controlsVersion = 0;
  double _cmdPanelHeight = 58.0;
  bool _showPanelNames = true;
  DPadMoveMode _dPadMoveMode = DPadMoveMode.normal;
  DPadMoveMode _dPadLongPressMoveMode = DPadMoveMode.gUpper;
  List<DPadMoveMode> _enabledDPadMoveModes = List<DPadMoveMode>.from(_allDPadMoveModes);
  bool _isDirectionPromptActive = false;
  String _mapTapTravelMode = 'always';
  bool _isMapScrolledOrZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    const MethodChannel('jp.satokiyo.darthack/key_interceptor')
        .setMethodCallHandler((call) async {
      if (call.method == 'onKeyEvent') {
        final String? key = call.arguments['key'];
        if (key != null) {
          _handleNativeKeyEvent(key);
        }
      }
    });
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isGameRunning && _waitingForInput && !_isKeyboardVisible) {
        _focusNode.requestFocus();
      }
    });
    _loadPreferences().then((_) {
      _applyScreenMode(_screenMode);
      _initAssets();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final newTileset = prefs.getString('selected_tileset') ?? 'nevanda_32x32';
    final tilesetChanged = newTileset != _selectedTileset;
    setState(() {
      _useTiles = prefs.getBool('use_tiles') ?? true;
      _selectedTileset = newTileset;
      _isKeyboardVisible = prefs.getBool('keyboard_visible') ?? true;
      final controllerModeStr = prefs.getString('controller_mode') ?? 'pad';
      _controllerMode = controllerModeStr == 'keyboard' ? ControllerMode.keyboard : ControllerMode.pad;
      _padOpacity = prefs.getDouble('pad_opacity') ?? 0.8;
      _dpadScale = prefs.getDouble('dpad_scale') ?? 1.0;
      _shortcutPadScale = prefs.getDouble('shortcut_pad_scale') ?? 1.0;
      _cmdPanelScale = prefs.getDouble('cmd_panel_scale') ?? 1.0;
      _statusDisplayMode = prefs.getInt('status_display_mode') ?? 0;
      _tombstoneDisplayMode = _loadTombstoneDisplayMode(prefs.getInt('tombstone_display_mode'));
      _screenMode = _loadScreenMode(prefs.getInt('screen_mode'));
      _showPanelNames = prefs.getBool('show_panel_names') ?? true;
      _drawerPosition = prefs.getString('drawer_position') ?? 'left';
      _menuButtonPosition = prefs.getString('menu_button_position') ?? 'bottom_left';
      _enabledDPadMoveModes = _parseEnabledMoveModes(
        prefs.getString('dpad_enabled_move_modes') ??
            'NORMAL,UPPER,G_LOWER,G_UPPER,CTRL,M_CMD,F_CMD',
      );
      final savedMoveModeName = prefs.getString('dpad_move_mode') ?? 'NORMAL';
      _dPadMoveMode = _parseMoveMode(savedMoveModeName);
      if (!_enabledDPadMoveModes.contains(_dPadMoveMode)) {
        _dPadMoveMode = _enabledDPadMoveModes.first;
      }
      final savedLongPressMoveModeName = prefs.getString('dpad_long_press_move_mode') ?? 'G_UPPER';
      _dPadLongPressMoveMode = _parseMoveMode(savedLongPressMoveModeName);
      _mapTapTravelMode = prefs.getString('map_tap_travel_mode') ?? 'always';

      // 物理キーのロード
      _volupAction = prefs.getInt('key_volup_action') ?? 0;
      _voldownAction = prefs.getInt('key_voldown_action') ?? 0;
      _backAction = prefs.getInt('key_back_action') ?? 0;

      // メッセージ領域設定のロード
      _msgLineCount = prefs.getInt('msg_line_count') ?? 5;
      _msgOpacity = prefs.getDouble('msg_opacity') ?? 0.70;
      _msgFontSize = prefs.getDouble('msg_font_size') ?? 13.0;

      // コントロールのバージョンを更新
      _controlsVersion++;
    });
    if (tilesetChanged && _assetsReady) {
      unawaited(_loadTileset(newTileset));
    }
    _syncNativeKeySettings();
    _triggerCenterOnPlayer();
  }

  DPadMoveMode _parseMoveMode(String name) {
    switch (name.trim()) {
      case 'UPPER':
        return DPadMoveMode.upper;
      case 'G_LOWER':
        return DPadMoveMode.gLower;
      case 'G_UPPER':
        return DPadMoveMode.gUpper;
      case 'CTRL':
        return DPadMoveMode.ctrl;
      case 'M_CMD':
        return DPadMoveMode.mCmd;
      case 'F_CMD':
        return DPadMoveMode.fCmd;
      case 'NORMAL':
      default:
        return DPadMoveMode.normal;
    }
  }

  int _loadTombstoneDisplayMode(int? raw) {
    if (raw == 0) return 0;
    if (raw == 1) return 1;
    return 0;
  }

  ScreenMode _loadScreenMode(int? raw) {
    if (raw == 0) return ScreenMode.normal;
    if (raw == 1) return ScreenMode.immersive;
    return ScreenMode.normal;
  }

  void _applyScreenMode(ScreenMode mode) {
    if (Platform.isAndroid) {
      const MethodChannel('jp.satokiyo.darthack/screen_mode')
          .invokeMethod('setScreenMode', <String, int>{'mode': mode.index});
    } else {
      final overlays = (mode == ScreenMode.normal)
          ? <SystemUiOverlay>[SystemUiOverlay.top, SystemUiOverlay.bottom]
          : <SystemUiOverlay>[SystemUiOverlay.bottom];
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: overlays);
    }
  }

  String _moveModeName(DPadMoveMode mode) {
    switch (mode) {
      case DPadMoveMode.normal:
        return 'NORMAL';
      case DPadMoveMode.upper:
        return 'UPPER';
      case DPadMoveMode.gLower:
        return 'G_LOWER';
      case DPadMoveMode.gUpper:
        return 'G_UPPER';
      case DPadMoveMode.ctrl:
        return 'CTRL';
      case DPadMoveMode.mCmd:
        return 'M_CMD';
      case DPadMoveMode.fCmd:
        return 'F_CMD';
    }
  }

  List<DPadMoveMode> _parseEnabledMoveModes(String raw) {
    final modes = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_parseMoveMode)
        .toSet()
        .toList();

    if (modes.isEmpty) {
      return <DPadMoveMode>[DPadMoveMode.normal];
    }
    return modes;
  }

  Future<void> _syncNativeKeySettings() async {
    try {
      await const MethodChannel('jp.satokiyo.darthack/key_interceptor')
          .invokeMethod('updateInterceptorSettings', {
        'volumeUp': _volupAction != 0,
        'volumeDown': _voldownAction != 0,
        'back': _backAction != 0,
      });
    } catch (e) {
      debugPrint("Native key settings sync failed: $e");
    }
  }

  void _openMenu(BuildContext context) {
    if (_drawerPosition == 'left') {
      Scaffold.of(context).openDrawer();
    } else if (_drawerPosition == 'right') {
      Scaffold.of(context).openEndDrawer();
    } else if (_drawerPosition == 'top') {
      setState(() {
        _isTopDrawerOpen = true;
      });
    } else if (_drawerPosition == 'bottom') {
      setState(() {
        _isBottomDrawerOpen = true;
      });
    }
  }

  void _closeDrawer() {
    if (_drawerPosition == 'left' || _drawerPosition == 'right') {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isTopDrawerOpen = false;
        _isBottomDrawerOpen = false;
      });
    }
  }

  Widget _buildDrawerContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.deepPurple[900],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports, size: 48, color: Colors.amber),
              SizedBox(height: 8),
              Text(
                'DartHackメニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.emoji_events, color: Colors.amber),
          title: const Text('スコアボード', style: TextStyle(color: Colors.white)),
          onTap: () {
            _closeDrawer();
            _showScoreboardDialog();
          },
        ),
        if (_isGameRunning) ...[
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.tealAccent),
            title: const Text('ヘルプを表示 (?)', style: TextStyle(color: Colors.white)),
            onTap: () {
              _closeDrawer();
              _sendFfiKey('?'.codeUnitAt(0), "?");
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.orangeAccent),
            title: const Text('データベース検索 ( /? )', style: TextStyle(color: Colors.white)),
            onTap: () {
              _closeDrawer();
              try {
                NetHackFfi().triggerDatabaseSearch();
              } catch (_) {
                _sendFfiKeys(['/'.codeUnitAt(0), '?'.codeUnitAt(0)], "/?");
              }
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.save, color: Colors.greenAccent),
            title: const Text('セーブして終了', style: TextStyle(color: Colors.white)),
            onTap: () {
              _closeDrawer();
              _sendFfiKey(83, "S");
            },
          ),
          ListTile(
            leading: const Icon(Icons.dangerous, color: Colors.redAccent),
            title: const Text('セーブせず終了 (放棄)', style: TextStyle(color: Colors.white)),
            onTap: () {
              _closeDrawer();
              _sendShortcutToC("#quit\n");
            },
          ),
          ListTile(
            leading: Icon(_isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard, color: Colors.blueAccent),
            title: Text(_isKeyboardVisible ? '仮想キーボードを非表示' : '仮想キーボードを表示', style: const TextStyle(color: Colors.white)),
            onTap: () {
              _closeDrawer();
              setState(() {
                _isKeyboardVisible = !_isKeyboardVisible;
              });
              if (!_isKeyboardVisible) {
                _focusNode.requestFocus();
              }
            },
          ),
        ],
        const Divider(color: Colors.white24, height: 1),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.grey),
          title: const Text('ゲーム設定を開く', style: TextStyle(color: Colors.white)),
          onTap: () {
            _closeDrawer();
            _showSettingsDialog();
          },
        ),
      ],
    );
  }

  Widget _buildTopDrawer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: _isTopDrawerOpen ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.75,
      child: Material(
        color: Colors.grey[950],
        elevation: 16,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: _buildDrawerContent(),
        ),
      ),
    );
  }

  Widget _buildBottomDrawer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _isBottomDrawerOpen ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.75,
      child: Material(
        color: Colors.grey[950],
        elevation: 16,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: _buildDrawerContent(),
        ),
      ),
    );
  }

  Widget _buildDrawerBarrier(bool isOpen, VoidCallback onClose) {
    if (!isOpen) return const SizedBox.shrink();
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    double? top;
    double? bottom;
    double? left;
    double? right;

    final mediaQuery = MediaQuery.of(context);
    final topOffset = 100.0; // ステータス(38px)+メッセージ(54px)+マージン

    // コントローラ表示時は重なりを避けるために十分な下余白を確保する
    final double bottomOffset = _dialogBottomInset(context);

    switch (_menuButtonPosition) {
      case 'top_left':
        top = topOffset;
        left = 8;
        break;
      case 'top_right':
        top = topOffset;
        right = 8;
        break;
      case 'left_edge':
        top = mediaQuery.size.height * 0.4;
        left = 8;
        break;
      case 'right_edge':
        top = mediaQuery.size.height * 0.4;
        right = 8;
        break;
      case 'bottom_left':
        bottom = bottomOffset;
        left = 8;
        break;
      case 'bottom_right':
        bottom = bottomOffset;
        right = 8;
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Builder(
        builder: (context) {
          return Opacity(
            opacity: 0.6,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 20),
                onPressed: () => _openMenu(context),
              ),
            ),
          );
        }
      ),
    );
  }

  bool get _hasAnyActiveOverlay {
    return _screen.isMenuWindowVisible ||
        _screen.isTextWindowVisible ||
        _isYnVisible ||
        _isGetLineVisible ||
        _isAskNameVisible;
  }

  bool get _shouldShowController {
    return _isGameRunning && _isKeyboardVisible && !_hasAnyActiveOverlay;
  }

  double _controllerReservedHeight() {
    final controllerVisible = _shouldShowController;
    if (!controllerVisible) {
      return 0.0;
    }
    if (_controllerMode == ControllerMode.keyboard) {
      return 230.0; // ソフトウェアキーボードは scale 1.0 固定
    }
    // 新レイアウト: コマンドパネル(scaled) + 6(gap) + 6(上padding) + max(D-Pad, ShortcutPad) scaled
    // = cmdPanelHeight * cmdPanelEffective + 12 + max(150 * dpadEffective, 150 * shortcutPadEffective)
    final cmdPanelScaledHeight = _cmdPanelHeight * _cmdPanelEffectiveScale;
    final dpadOrShortcutScaledHeight =
        150.0 * (_dpadEffectiveScale > _shortcutPadEffectiveScale
                ? _dpadEffectiveScale
                : _shortcutPadEffectiveScale);
    return cmdPanelScaledHeight + 12.0 + dpadOrShortcutScaledHeight;
  }

  void _updateEffectiveScales(double screenWidth) {
    final result = calculatePadClamp(
      dpadScale: _dpadScale,
      shortcutPadScale: _shortcutPadScale,
      screenWidth: screenWidth,
    );
    _dpadEffectiveScale = result.dpadEffectiveScale;
    _shortcutPadEffectiveScale = result.shortcutPadEffectiveScale;
    _cmdPanelEffectiveScale = _cmdPanelScale; // CmdPanel はクランプなし
  }

  double _dialogBottomInset(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final reserved = _controllerReservedHeight();
    return reserved > 0.0 ? reserved + safeBottom + 12.0 : 16.0;
  }

  void _handleNativeKeyEvent(String key) {
    if (!_isGameRunning || !_waitingForInput) return;

    int action = 0;
    if (key == 'volume_up') {
      action = _volupAction;
    } else if (key == 'volume_down') {
      action = _voldownAction;
    } else if (key == 'back') {
      action = _backAction;
    }

    if (action != 0) {
      _sendFfiKey(action, "PhysicalKey($key)");
    }
  }

  int _parseMaxCount(String text) {
    final trimmed = text.trim();
    int count = 0;
    int i = 0;
    while (i < trimmed.length) {
      final code = trimmed.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        count = count * 10 + (code - 48);
        i++;
      } else {
        break;
      }
    }
    return i > 0 && count > 0 ? count : 1;
  }

  String _cleanItemText(String text) {
    final trimmed = text.trim();
    int i = 0;
    while (i < trimmed.length) {
      final code = trimmed.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        i++;
      } else {
        break;
      }
    }
    return i > 0 ? trimmed.substring(i).trim() : trimmed;
  }

  void _handleAmountSelection(MenuItemData item, int amount) {
    if (amount <= 0) return;
    final isMultiSelectMenu = !_screen.menuPrompt.contains("拡張コマンド") && _screen.menuHow > 1;
    if (isMultiSelectMenu) {
      setState(() {
        _menuSelectedCounts[item.ident] = amount;
      });
    } else {
      _sendMenuSelection(item.ident, amount);
    }
  }

  Future<void> _onMenuItemLongPress(MenuItemData item) async {
    if (item.ident == 0) return;
    final maxCount = _parseMaxCount(item.text);
    if (maxCount <= 1) return;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AmountSelectorDialog(
        itemName: _cleanItemText(item.text),
        maxCount: maxCount,
        tileImage: _tileImage,
        tileSize: _tileSize,
        tileIndex: item.tile,
      ),
    );

    if (selected != null && selected > 0) {
      _handleAmountSelection(item, selected);
    }
  }

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
        final parsed = <ExtCmdEntry>[];
        final rawItems = extCmdsStr.split('\n');

        for (final raw in rawItems) {
          final item = raw.trim();
          if (item.isEmpty) continue;

          final tabIndex = item.indexOf('\t');
          final rawCommand = tabIndex >= 0 ? item.substring(0, tabIndex).trim() : item;
          if (rawCommand.isEmpty) continue;

          final command = rawCommand.startsWith('#') ? rawCommand : '#$rawCommand';
          final description = tabIndex >= 0 ? item.substring(tabIndex + 1).trim() : '';
          parsed.add(ExtCmdEntry(command: command, description: description));
        }

        setState(() {
          _extCmdList = parsed;
          _filteredExtCmds = List.from(parsed);
        });
        _extCmdFilterController.clear();
      }
    } catch (e) {
      debugPrint("Error loading extcmds: $e");
    }
  }

  void _sendYnResult(int result) {
    _workerSendPort?.send({
      'type': 'yn_result',
      'result': result,
    });
    setState(() {
      _isYnVisible = false;
    });
  }

  void _sendGetLineResult(String? result) {
    _workerSendPort?.send({
      'type': 'getline_result',
      'result': result,
    });
    setState(() {
      _isGetLineVisible = false;
    });
  }

  void _sendAskNameResult(String? result) {
    _workerSendPort?.send({
      'type': 'askname_result',
      'result': result,
      'mode': _selectedPlayMode.index,
    });
    setState(() {
      _isAskNameVisible = false;
    });
    if (result != null && result.isNotEmpty) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString("lastUsername", result);
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    _getlineController.dispose();
    _askNameController.dispose();
    _extCmdFilterController.dispose();
    _extCmdMenuFilterController.dispose();
    super.dispose();
  }

  void _centerOnPlayer(Size viewportSize) {
    if (!_isGameRunning) return;

    final cellWidth = _useTiles ? 32.0 : 9.0;
    final cellHeight = _useTiles ? 32.0 : 16.0;

    final cursorX = _screen.cursorX;
    final cursorY = _screen.cursorY;

    // 巨大キャンバス (4000x3000) 内でのマップ全体のサイズと余白オフセット
    final mapWidth = 80 * cellWidth;
    final mapHeight = 21 * cellHeight;
    final mapOffsetX = (4000.0 - mapWidth) / 2;
    final mapOffsetY = (3000.0 - mapHeight) / 2;

    // キャンバス上のプレイヤー絶対ピクセル座標
    final playerX = mapOffsetX + cursorX * cellWidth + (cellWidth / 2);
    final playerY = mapOffsetY + cursorY * cellHeight + (cellHeight / 2);

    // 下部コントローラの遮りを考慮し、視覚的中心（上から35%の高さ）に主人公が来るよう調整
    final tx = (viewportSize.width / 2) - (playerX * _currentScale);
    final ty = (viewportSize.height * 0.35) - (playerY * _currentScale);

    _transformationController.value = Matrix4(
      _currentScale, 0.0, 0.0, 0.0, // column 1
      0.0, _currentScale, 0.0, 0.0, // column 2
      0.0, 0.0, 1.0, 0.0,          // column 3
      tx, ty, 0.0, 1.0,            // column 4
    );
    _isMapScrolledOrZoomed = false;
  }

  void _triggerCenterOnPlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final renderBox = _mapViewportKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          _centerOnPlayer(renderBox.size);
        }
      }
    });
  }

  Future<void> _initAssets() async {
    _addLog("Initializing game assets...");
    try {
      final dstDir = await NetHackAssets.initialize();
      setState(() {
        _assetsPath = dstDir.path;
        _assetsReady = true;
      });
      _addLog("Assets initialized at: $_assetsPath");
      // 初期フレーム描画を阻害しないようタイル読み込みは非同期で後追いする
      unawaited(_loadTileset(_selectedTileset));
    } catch (e) {
      _addLog("Error initializing assets: $e");
    }
  }

  Future<ui.Image> _loadTileImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadTileset(String tilesetName) async {
    _addLog("Loading tileset: $tilesetName...");
    try {
      final size = tilesetName.contains('32x32') ? 32 : (tilesetName.contains('15x25') ? 15 : 16);
      final img = await _loadTileImageFromAsset('assets/tiles/$tilesetName.png');
      setState(() {
        _tileImage = img;
        _tileSize = size;
        _selectedTileset = tilesetName;
      });
      _addLog("Tileset loaded successfully: $tilesetName");
    } catch (e) {
      _addLog("Failed to load tileset $tilesetName: $e");
    }
  }

  void _addLog(String msg) {
    setState(() {
      _logs.add(msg);
    });
  }

  bool _isSaveInProgressMessage(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('セーブ中')
        || normalized.startsWith('Saving...');
  }

  Future<void> _showExitDialogAndTerminate(String message) async {
    if (!mounted || _exitDialogShown) return;
    _exitDialogShown = true;

    final dialogMessage = message.trim().isEmpty ? 'また会いましょう...' : message.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('終了', style: TextStyle(color: Colors.white)),
            content: Text(
              dialogMessage,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      _stopGame();
    }
  }

  Future<void> _startGame() async {
    if (_isGameRunning) return;

    setState(() {
      _logs.clear();
      _isGameRunning = true;
      _isGameFinished = false;
      _waitingForInput = false;
      _isMainGameStarted = false;
      _mapWinId = null;
      _messageWinId = null;
      _isTopDrawerOpen = false;
      _isBottomDrawerOpen = false;
      _autoAdvanceSavePending = false;
      _exitDialogShown = false;
    });

    _applyScreenMode(_screenMode);

    _addLog("Spawning NetHack Worker Isolate...");

    final receivePort = ReceivePort();
    await Isolate.spawn(NetHackWorker.start, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is Map) {
        final type = message['type'];
        if (type == 'ready') {
          _workerSendPort = message['sendPort'];
          _addLog("Worker Isolate Ready. Starting Game...");
          _workerSendPort?.send({
            'type': 'start',
            'assetsPath': _assetsPath,
          });
        } else if (type == 'createWindow') {
          _screen.createWindow(message['winId'], message['winType']);
          if (message['winType'] == 3) { // 3 == NHW_MAP
            _mapWinId = message['winId'];
          } else if (message['winType'] == 1) { // 1 == NHW_MESSAGE
            _messageWinId = message['winId'];
          }
        } else if (type == 'clearWindow') {
          _screen.clearWindow(message['winId']);
        } else if (type == 'displayWindow') {
          final winId = message['winId'] as int;
          final blocking = (message['blocking'] as int? ?? 0) != 0;
          final isPlain = (message['isPlain'] as int? ?? 0) != 0;
          _addLog("displayWindow: winId=$winId, blocking=$blocking, isPlain=$isPlain, textVisible=${_screen.isTextWindowVisible}, menuVisible=${_screen.isMenuWindowVisible}");
          _screen.displayWindow(winId, blocking, isPlain: isPlain);
          _addLog("displayWindow after: textVisible=${_screen.isTextWindowVisible}, menuVisible=${_screen.isMenuWindowVisible}");
          // C側の blocking に基づく
          if (_mapWinId != null && winId == _mapWinId) {
            setState(() {
              _isMainGameStarted = true;
              _autoAdvanceSavePending = false;
              _autoAdvanceSavePendingUntilMs = 0;
            });
          } else {
            // テキスト/メニューウィンドウの場合も setState を呼んで確実に UI を更新
            setState(() {});
          }
        } else if (type == 'destroyWindow') {
          _addLog("destroyWindow: winId=${message['winId']}");
          _screen.destroyWindow(message['winId']);
        } else if (type == 'curs') {
          _screen.setCursor(message['winId'], message['x'], message['y']);
        } else if (type == 'putstr') {
          final text = (message['text'] as String?) ?? '';
          _screen.putString(message['winId'], message['attr'], text);
          final winId = message['winId'] as int? ?? -1;
          if (winId == _messageWinId || winId == 1) {
            if (_isDirectionPromptText(text)) {
              _isDirectionPromptActive = true;
            } else if (text.trim().isNotEmpty) {
              _isDirectionPromptActive = false;
            }
          }
          if (_isSaveInProgressMessage(text)) {
            _autoAdvanceSavePending = true;
            _autoAdvanceSavePendingUntilMs = DateTime.now().millisecondsSinceEpoch + 5000;
          }
        } else if (type == 'putMixed') {
          // putmixed タイル ID 付き送信 (`/` 結果リスト用)。
          // putstr と同じダイアログ検出 (方向プロンプト、 セーブ進行) も行う。
          final text = (message['text'] as String?) ?? '';
          _screen.putMixedWithTile(
            message['winId'],
            message['attr'],
            message['tile'] ?? -1,
            text,
          );
          final winId = message['winId'] as int? ?? -1;
          if (winId == _messageWinId || winId == 1) {
            if (_isDirectionPromptText(text)) {
              _isDirectionPromptActive = true;
            } else if (text.trim().isNotEmpty) {
              _isDirectionPromptActive = false;
            }
          }
          if (_isSaveInProgressMessage(text)) {
            _autoAdvanceSavePending = true;
            _autoAdvanceSavePendingUntilMs = DateTime.now().millisecondsSinceEpoch + 5000;
          }
        } else if (type == 'printGlyph') {
          _screen.printGlyph(
            message['winId'],
            message['x'],
            message['y'],
            message['tile'],
            message['ch'],
            message['color'],
            message['special'],
          );
        } else if (type == 'cliparound') {
          // C 側からプレイヤー位置 (u.ux, u.uy) を受信。
          // マップの主人公タップ → #herecmdmenu 起動の判定に使用する。
          _screen.setPlayerPos(message['playerX'], message['playerY']);
          _triggerCenterOnPlayer();
        } else if (type == 'request_input') {
          setState(() {
            _waitingForInput = true;
          });

          final isGameOver = message['gameover'] as bool? ?? false;
          if (isGameOver && _screen.isMoreActive && !_screen.isTextWindowVisible) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _waitingForInput) {
                _sendFfiKey(32, 'Space(auto)');
              }
            });
          }

          if (_autoAdvanceSavePending) {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            final canAutoAdvance =
                nowMs <= _autoAdvanceSavePendingUntilMs
                && !_screen.isMenuWindowVisible
                && !_screen.isTextWindowVisible
                && _screen.textLines.isEmpty
                && !_isYnVisible
                && !_isGetLineVisible
                && !_isAskNameVisible;

            if (canAutoAdvance) {
              _autoAdvanceSavePending = false;
              _autoAdvanceSavePendingUntilMs = 0;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // メニューやテキストウィンドウが表示されている場合は
                // 自動 Space 送信をスキップ (メニュー項目タップを
                // 妨げないため、またキャンセルを誤発動させないため)。
                if (mounted && _waitingForInput
                    && !_screen.isMenuWindowVisible
                    && !_screen.isTextWindowVisible
                    && _screen.textLines.isEmpty
                    && !_isYnVisible
                    && !_isGetLineVisible
                    && !_isAskNameVisible) {
                  _sendFfiKey(32, 'Space(auto)');
                }
              });
            } else if (nowMs > _autoAdvanceSavePendingUntilMs
                || _screen.isMenuWindowVisible
                || _screen.isTextWindowVisible
                || _screen.textLines.isNotEmpty
                || _isYnVisible
                || _isGetLineVisible
                || _isAskNameVisible) {
              _autoAdvanceSavePending = false;
              _autoAdvanceSavePendingUntilMs = 0;
            }
          }
          if (!_isKeyboardVisible) {
            _focusNode.requestFocus();
          }
          _triggerCenterOnPlayer();
        } else if (type == 'yn_function') {
          setState(() {
            _ynQuestion = message['question'];
            _ynChoices = message['choices'];
            _ynDefault = message['def'];
            _isYnVisible = true;
          });
        } else if (type == 'getline') {
          final prompt = message['prompt'] as String;
          final initText = message['initText'] as String;
          final lowerPrompt = prompt.toLowerCase();
          final isExtCmdPrompt = lowerPrompt.contains("extended command")
              || prompt.contains("拡張コマンド")
              || initText.trimLeft().startsWith('#');
          _getlineController.text = initText;
          if (isExtCmdPrompt) {
            _loadExtCmds();
          } else {
            _extCmdList = [];
            _filteredExtCmds = [];
          }
          setState(() {
            _getlinePrompt = prompt;
            _isGetLineVisible = true;
          });
        } else if (type == 'askname') {
          final savesStr = message['saves'] as String;
          final saves = savesStr.isNotEmpty ? savesStr.split(';') : <String>[];
          final defaultName = saves.isNotEmpty ? saves[0] : "Player";
          setState(() {
            _askNameSaves = saves;
            _askNameMaxChars = message['maxChars'];
            _isAskNameVisible = true;
            _selectedPlayMode = PlayMode.normal;
            _previousCustomName = defaultName;
            _askNameController.text = defaultName;
          });
        } else if (type == 'number_pad_mode') {
          final state = message['state'] as int? ?? 0;
          setState(() {
            _numberPadMode = state;
          });
          _addLog("number_pad mode: $state");
        } else if (type == 'startMenu') {
          _screen.startMenu(message['winId']);
        } else if (type == 'game_exit') {
          final exitMessage = (message['message'] as String?) ?? '';
          setState(() {
            _waitingForInput = false;
            _isGameRunning = false;
            _isGameFinished = true;
          });
          unawaited(_showExitDialogAndTerminate(exitMessage));
        } else if (type == 'addMenu') {
          _screen.addMenu(
            message['winId'],
            message['ident'],
            message['accelerator'],
            message['groupacc'],
            message['attr'],
            message['text'],
            message['preselected'],
            message['color'],
            message['tile'] ?? -1,
          );
        } else if (type == 'endMenu') {
          _screen.endMenu(message['winId'], message['prompt']);
        } else if (type == 'selectMenu') {
          _screen.selectMenu(message['winId'], message['how']);
          setState(() {
            _waitingForInput = true;
            _extCmdMenuFilter = "";
            _extCmdMenuFilterController.clear();
            _menuSelectedCounts = <int, int>{};
            for (final item in _screen.menuItems) {
              if (item.ident != 0 && item.preselected != 0) {
                _menuSelectedCounts[item.ident] = _parseMaxCount(item.text);
              }
            }
          });
          _triggerCenterOnPlayer();
        } else if (type == 'error') {
          _addLog("ERROR: ${message['message']}");
          _stopGame();
        }
      }
    });
  }

  void _stopGame() {
    exit(0);
  }

  bool _isDirectionPromptText(String text) {
    final lower = text.toLowerCase();
    return lower.contains('what direction') || text.contains('どの方向');
  }

  String _moveModeLabel(DPadMoveMode mode) {
    switch (mode) {
      case DPadMoveMode.normal:
        return '標準';
      case DPadMoveMode.upper:
        return '大文字';
      case DPadMoveMode.gLower:
        return 'g';
      case DPadMoveMode.gUpper:
        return 'G';
      case DPadMoveMode.ctrl:
        return '^(Ctrl)';
      case DPadMoveMode.mCmd:
        return 'm';
      case DPadMoveMode.fCmd:
        return 'F';
    }
  }

  String _moveModeDescription(DPadMoveMode mode) {
    switch (mode) {
      case DPadMoveMode.normal:
        return '指定方向へ1マス移動 (yuhjklbn)';
      case DPadMoveMode.upper:
        return '指定方向へ、壁に当たるか何かにぶつかるまで進む (YUHJKLBN)';
      case DPadMoveMode.gLower:
        return '指定方向へ、何か興味深いものを見つけるまで進む (g<dir>)';
      case DPadMoveMode.gUpper:
        return '指定方向へ、何か興味深いものを見つけるまで進む（分岐無視） (G<dir>)';
      case DPadMoveMode.ctrl:
        return '指定方向へ、何か興味深いものを見つけるまで進む（分岐無視） (^<dir>)';
      case DPadMoveMode.mCmd:
        return 'アイテムを拾わずに移動、危険な地形でも移動 (m<dir>)';
      case DPadMoveMode.fCmd:
        return 'モンスターを感知していなくても攻撃 (F<dir>)';
    }
  }

  String _viToNumPad(String viKey) {
    switch (viKey) {
      case 'y':
        return '7';
      case 'k':
        return '8';
      case 'u':
        return '9';
      case 'h':
        return '4';
      case 'l':
        return '6';
      case 'b':
        return '1';
      case 'j':
        return '2';
      case 'n':
        return '3';
      default:
        return viKey;
    }
  }

  int _ctrlFromVi(String viKey) {
    final code = viKey.codeUnitAt(0);
    return code - 'a'.codeUnitAt(0) + 1;
  }

  String _applyMoveModeForDisplay(String baseDir) {
    switch (_dPadMoveMode) {
      case DPadMoveMode.normal:
        return baseDir;
      case DPadMoveMode.upper:
        return baseDir.toUpperCase();
      case DPadMoveMode.gLower:
        return 'g$baseDir';
      case DPadMoveMode.gUpper:
        return 'G$baseDir';
      case DPadMoveMode.ctrl:
        return '^$baseDir';
      case DPadMoveMode.mCmd:
        return 'm$baseDir';
      case DPadMoveMode.fCmd:
        return 'F$baseDir';
    }
  }

  String _directionDisplayLabel(String viKey) {
    final baseDir = _numberPadMode != 0 ? _viToNumPad(viKey) : viKey;
    return _applyMoveModeForDisplay(baseDir);
  }

  Map<String, String> _buildDirectionLabels() {
    return <String, String>{
      'y': _directionDisplayLabel('y'),
      'k': _directionDisplayLabel('k'),
      'u': _directionDisplayLabel('u'),
      'h': _directionDisplayLabel('h'),
      'l': _directionDisplayLabel('l'),
      'b': _directionDisplayLabel('b'),
      'j': _directionDisplayLabel('j'),
      'n': _directionDisplayLabel('n'),
    };
  }

  Future<void> _saveDPadModePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dpad_move_mode', _moveModeName(_dPadMoveMode));
    await prefs.setString(
      'dpad_enabled_move_modes',
      _enabledDPadMoveModes.map(_moveModeName).join(','),
    );
  }

  void _cycleDPadMoveMode() {
    if (_enabledDPadMoveModes.isEmpty) {
      _enabledDPadMoveModes = <DPadMoveMode>[DPadMoveMode.normal];
    }
    final currentIdx = _enabledDPadMoveModes.indexOf(_dPadMoveMode);
    final nextIdx = (currentIdx + 1) % _enabledDPadMoveModes.length;
    setState(() {
      _dPadMoveMode = _enabledDPadMoveModes[nextIdx];
    });
    unawaited(_saveDPadModePrefs());
  }

  void _handleCenterTap() {
    if (_isDirectionPromptActive) {
      _sendFfiKey('.'.codeUnitAt(0), '.');
      setState(() {
        _isDirectionPromptActive = false;
      });
    } else {
      _cycleDPadMoveMode();
    }
  }

  Future<void> _showMoveModeSelectDialog() async {
    final selected = Set<DPadMoveMode>.from(_enabledDPadMoveModes);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('使用する移動モードの選択'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allDPadMoveModes.map((mode) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(mode),
                      title: Text(_moveModeLabel(mode)),
                      subtitle: Text(_moveModeDescription(mode)),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            selected.add(mode);
                          } else {
                            selected.remove(mode);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final newModes = _allDPadMoveModes
                        .where((mode) => selected.contains(mode))
                        .toList();
                    if (newModes.isEmpty) {
                      newModes.add(DPadMoveMode.normal);
                    }
                    setState(() {
                      _enabledDPadMoveModes = newModes;
                      if (!_enabledDPadMoveModes.contains(_dPadMoveMode)) {
                        _dPadMoveMode = _enabledDPadMoveModes.first;
                      }
                    });
                    unawaited(_saveDPadModePrefs());
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isTextOrPromptInputActive() {
    if (_isDirectionPromptActive ||
        _isYnVisible ||
        _isGetLineVisible ||
        _isAskNameVisible ||
        _screen.isMenuWindowVisible ||
        _screen.isTextWindowVisible) {
      return true;
    }
    if (_screen.messages.isNotEmpty) {
      final lastMsg = _screen.messages.last.toLowerCase();
      if (lastMsg.contains('[y/n]') ||
          lastMsg.contains('[yn]') ||
          lastMsg.contains('(y/n)') ||
          lastMsg.contains('[y/n?]')) {
        return true;
      }
    }
    return false;
  }

  void _sendModeAppliedDirection(String viKey, {DPadMoveMode? modeOverride}) {
    if (_isTextOrPromptInputActive()) {
      final baseKey = _numberPadMode != 0 ? _viToNumPad(viKey) : viKey;
      _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
      _isDirectionPromptActive = false;
      return;
    }

    final mode = modeOverride ?? _dPadMoveMode;
    final baseKey = _numberPadMode != 0 ? _viToNumPad(viKey) : viKey;

    switch (mode) {
      case DPadMoveMode.normal:
        _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
        break;
      case DPadMoveMode.upper:
        if (_numberPadMode != 0) {
          final runKey = viKey.toUpperCase();
          _sendFfiKey(runKey.codeUnitAt(0), runKey);
        } else {
          final key = viKey.toUpperCase();
          _sendFfiKey(key.codeUnitAt(0), key);
        }
        break;
      case DPadMoveMode.gLower:
        _sendFfiKeys(['g'.codeUnitAt(0), baseKey.codeUnitAt(0)], 'g$baseKey');
        break;
      case DPadMoveMode.gUpper:
        _sendFfiKeys(['G'.codeUnitAt(0), baseKey.codeUnitAt(0)], 'G$baseKey');
        break;
      case DPadMoveMode.ctrl:
        _sendFfiKey(_ctrlFromVi(viKey), '^$viKey');
        break;
      case DPadMoveMode.mCmd:
        _sendFfiKeys(['m'.codeUnitAt(0), baseKey.codeUnitAt(0)], 'm$baseKey');
        break;
      case DPadMoveMode.fCmd:
        _sendFfiKeys(['F'.codeUnitAt(0), baseKey.codeUnitAt(0)], 'F$baseKey');
        break;
    }
  }

  void _sendFfiKey(int code, String label) {
    if (!_waitingForInput) return;

    if (_screen.isMoreActive) {
      if (code == 32 || code == 10 || code == 13 || code == 27) {
        _screen.setMoreActive(false);
      }
    }

    // メニュー表示中は、メニューショートカットキー判定を行う
    if (_screen.isMenuWindowVisible) {
      final isMultiSelectMenu = _screen.menuHow > 1;
      if (isMultiSelectMenu) {
        if (code == 27) {
          _sendMenuSelection(-1);
          return;
        }
        if (code == 10 || code == 13) {
          _sendMenuSelections(_menuSelectedCounts);
          return;
        }
        for (final item in _screen.menuItems) {
          if (item.ident != 0 && item.accelerator != 0 && item.accelerator == code) {
            _toggleMenuSelection(item.ident);
            return;
          }
        }
        return;
      }

      if (code == 32 || code == 10 || code == 13 || code == 27) {
        _sendMenuSelection(-1);
        return;
      }
      for (final item in _screen.menuItems) {
        if (item.accelerator != 0 && item.accelerator == code) {
          _sendMenuSelection(item.ident);
          return;
        }
      }
      return; // メニュー表示中は他のキーは無視
    }

    setState(() {
      _waitingForInput = false;
    });
    _addLog("> Send Key: '$label' ($code)");
    _workerSendPort?.send({
      'type': 'key',
      'key': code,
    });
  }

  void _sendFfiKeys(List<int> codes, String label) {
    if (!_waitingForInput) return;
    if (_screen.isMenuWindowVisible) return;

    setState(() {
      _waitingForInput = false;
    });
    _addLog("> Send Keys: '$label' ($codes)");
    _workerSendPort?.send({
      'type': 'keys',
      'keys': codes,
    });
  }

  void _sendKeysToC(String command) {
    if (!_waitingForInput) return;
    if (_screen.isMenuWindowVisible) return;
    if (_screen.isTextWindowVisible) return;
    if (_isYnVisible) return;
    if (_isGetLineVisible) return;
    if (_isAskNameVisible) return;

    final List<int> keys = _parseKeys(command);
    if (keys.isEmpty) return;

    _addLog("> Send Keys: '$command' (${keys.length} keys)");
    setState(() {
      _waitingForInput = false;
    });
    _workerSendPort?.send({
      'type': 'keys',
      'keys': keys,
    });
  }

  void _sendShortcutToC(String command) {
    if (!_waitingForInput) return;
    if (_screen.isMenuWindowVisible) return;
    if (_screen.isTextWindowVisible) return;
    if (_isYnVisible) return;
    if (_isGetLineVisible) return;
    if (_isAskNameVisible) return;

    final List<int> keys = _parseKeys(command);
    if (keys.isEmpty) return;

    _addLog("> Send Shortcut: '$command' (${keys.length} keys)");
    setState(() {
      _waitingForInput = false;
    });
    _workerSendPort?.send({
      'type': 'shortcut',
      'keys': keys,
    });
  }

  List<int> _parseKeys(String command) {
    final List<int> keys = [];
    int i = 0;
    while (i < command.length) {
      final c = command[i];
      if (c == '^' && i + 1 < command.length && command[i + 1] != ' ') {
        keys.add(command.codeUnitAt(i + 1) & 0x1f);
        i += 2;
      } else if (c == 'M' && i + 2 < command.length && command[i + 1] == '-') {
        keys.add(command.codeUnitAt(i + 2) | 0x80);
        i += 3;
      } else if (c == r'\' && i + 1 < command.length) {
        switch (command[i + 1]) {
          case 'e':
            keys.add(0x1B);
            break;
          case 'n':
          case 'r':
            keys.add(0x0A);
            break;
          case 's':
            keys.add(0x20);
            break;
          case 'b':
            keys.add(0x7F);
            break;
          default:
            keys.add(command.codeUnitAt(i + 1));
            break;
        }
        i += 2;
      } else {
        keys.add(c.codeUnitAt(0));
        i += 1;
      }
    }
    return keys;
  }



  // マップ座標 (SizedBox 4000x3000 ローカル) を 0-based タイル座標に変換する。
  // NetHackMapPainter.paint() と同じ計算式を共有する。
  ({int tileX, int tileY, bool inMap})? _mapLocalToTile(Offset localPosition) {
    final cellW = _useTiles ? 32.0 : 9.0;
    final cellH = _useTiles ? 32.0 : 16.0;
    const canvasW = 4000.0;
    const canvasH = 3000.0;
    final mapWidth = NetHackScreen.mapCols * cellW;
    final mapHeight = NetHackScreen.mapRows * cellH;
    final offsetX = (canvasW - mapWidth) / 2;
    final offsetY = (canvasH - mapHeight) / 2;

    final tileX = ((localPosition.dx - offsetX) / cellW).floor();
    final tileY = ((localPosition.dy - offsetY) / cellH).floor();

    if (tileX < 0 || tileX >= NetHackScreen.mapCols
        || tileY < 0 || tileY >= NetHackScreen.mapRows) {
      return null; // マップ領域外
    }
    return (tileX: tileX, tileY: tileY, inMap: true);
  }

  // マップタップ処理。主人公タイルをタップしたとき Java 版と同じ流れで
  // PosCmd(x, y, mod) を C コアに送信し、C コア側の click_to_cmd 経由で
  // #herecmdmenu (主人公) / #therecmdmenu (隣接) を起動する。
  // (拡張コマンド "#herecmdmenu" の文字列送信は Flutter 版の get_ext_cmd
  //  実装 (メニュー起動型) と整合せず、メニュー表示前の残文字が暴走する
  //  ため廃止。Java 版の PosCmd 送信方式を踏襲する。)
  void _handleMapTap(TapDownDetails details) {
    if (!_isMainGameStarted) return;
    final px = _screen.playerX;
    final py = _screen.playerY;
    if (px < 0 || py < 0) return;

    final tile = _mapLocalToTile(details.localPosition);
    if (tile == null) return;

    // farlookモード (/) や ; コマンド、ターゲット選択（getpos等）入力待ち中の判定
    // toplineプロンプト、またはメッセージ末尾が?で終わる場合はターゲット選択中とみなす
    final bool isGetposOrTargetingMode = _screen.topline != null ||
        (_screen.messages.isNotEmpty && _screen.messages.last.trim().endsWith("?"));

    // 主人公タイルまたは隣接8マスの判定
    final dx = (tile.tileX - px).abs();
    final dy = (tile.tileY - py).abs();
    final bool isAdjacentOrSelf = (dx <= 1 && dy <= 1);

    // 自動トラベル（2マス以上離れた場所への移動）の制限判定
    if (!isGetposOrTargetingMode && !isAdjacentOrSelf && _mapTapTravelMode == 'after_scroll') {
      if (!_isMapScrolledOrZoomed) {
        _addLog("Map tap travel ignored: scroll or zoom required");
        return;
      }
      _isMapScrolledOrZoomed = false;
    }

    sendPosCmd(tile.tileX, tile.tileY, 1 /* CLICK_1 */);
  }

  // マップ座標クリック (PosCmd) を C コアに送信する。
  // C コアの flutter_nh_poskey が PosCmd キューを消費し、click_to_cmd 経由で
  // #therecmdmenu (および主人公タイル時は #herecmdmenu) を起動する。
  void sendPosCmd(int x, int y, int mod) {
    _workerSendPort?.send({
      'type': 'pos_cmd',
      'x': x,
      'y': y,
      'mod': mod,
    });
  }

  void _sendMenuSelection(int ident, [int count = 1]) {
    if (!_waitingForInput || !_screen.isMenuWindowVisible) return;
    setState(() {
      _waitingForInput = false;
      _extCmdMenuFilter = "";
      _extCmdMenuFilterController.clear();
    });
    _addLog("> Menu Select: ID $ident (count: $count)");
    _workerSendPort?.send({
      'type': 'menu_select',
      'ident': ident,
      'count': count,
    });
    _screen.clearMenu();
    _menuSelectedCounts = <int, int>{};
  }

  void _sendMenuSelections(Map<int, int> selections) {
    if (!_waitingForInput || !_screen.isMenuWindowVisible) return;
    setState(() {
      _waitingForInput = false;
      _extCmdMenuFilter = "";
      _extCmdMenuFilterController.clear();
    });
    _addLog("> Menu Selects: ${selections.length} item(s)");
    final List<Map<String, int>> payload = selections.entries
        .map((e) => {'ident': e.key, 'count': e.value})
        .toList();
    _workerSendPort?.send({
      'type': 'menu_selects',
      'selections': payload,
    });
    _screen.clearMenu();
    _menuSelectedCounts = <int, int>{};
  }

  void _toggleMenuSelection(int ident) {
    if (ident == 0) return;
    setState(() {
      if (_menuSelectedCounts.containsKey(ident)) {
        _menuSelectedCounts.remove(ident);
      } else {
        try {
          final item = _screen.menuItems.firstWhere((i) => i.ident == ident);
          final maxCount = _parseMaxCount(item.text);
          _menuSelectedCounts[ident] = maxCount;
        } catch (_) {
          _menuSelectedCounts[ident] = 1;
        }
      }
    });
  }

  bool _isMenuDividerText(String text) {
    final t = text.trim();
    if (t.isEmpty) return true;
    return RegExp(r'^[-=\s]+$').hasMatch(t);
  }

  bool _isMenuCategoryItem(MenuItemData item) {
    if (item.ident != 0) return false;
    if (_isMenuDividerText(item.text)) return false;
    // add_menu_heading() は attr != ATR_NONE (= 0) でアイテムを追加するため、
    // attr > 0 ならメニューのタイトル行として判定する
    if (item.attr > 0) return true;
    // nhwText ウィンドウで putstr で流れてくる行（attr=0）は
    // コロンで終わる行をタイトル行として扱う
    final t = item.text.trim();
    return t.endsWith(':') || t.endsWith('：');
  }

  Widget _buildMenuItemTile(int tile) {
    if (!_useTiles || _tileImage == null || tile < 0) {
      return const SizedBox(width: 24, height: 24);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MenuItemTilePainter(
          image: _tileImage!,
          tileIndex: tile,
          tileSize: _tileSize,
        ),
      ),
    );
  }

  Widget _buildTabSeparatedRow(
    String text,
    TextStyle baseStyle, {
    bool isHeader = false,
    String accLabel = "",
    String suffixLabel = "",
  }) {
    final parts = text.split('\t');
    if (parts.length < 2) {
      return Text(
        "$accLabel$text$suffixLabel",
        style: baseStyle,
      );
    }

    final children = <Widget>[];

    // カラム数に応じた幅のリストを定義する
    final List<double> colWidths;
    final List<TextAlign> colAligns;

    if (parts.length == 5) {
      // 呪文一覧などの 5カラム構成
      // 呪文名, レベル, 系統, 失敗率, 記憶
      colWidths = [0, 50, 45, 55, 45]; // 0 は Expanded
      colAligns = [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
        TextAlign.right,
        TextAlign.right,
      ];
    } else if (parts.length == 3) {
      // インベントリなどの 3カラム構成
      // 名前, 重量, 説明
      colWidths = [0, 60, 120];
      colAligns = [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
      ];
    } else if (parts.length == 2) {
      // 2カラム構成
      colWidths = [0, 100];
      colAligns = [
        TextAlign.left,
        TextAlign.right,
      ];
    } else {
      // 汎用フォールバック
      colWidths = List.generate(parts.length, (index) => index == 0 ? 0.0 : 80.0);
      colAligns = List.generate(parts.length, (index) => index == 0 ? TextAlign.left : TextAlign.right);
    }

    for (int i = 0; i < parts.length; i++) {
      final partText = parts[i].trim();
      final displayStyle = isHeader
          ? baseStyle.copyWith(
              color: baseStyle.color?.withValues(alpha: 0.8) ?? Colors.white70,
              fontWeight: FontWeight.bold,
            )
          : baseStyle;

      // 最初の列にのみアクセラレータを付与し、最後の列にのみ suffixLabel を付与する
      var colText = partText;
      if (i == 0 && accLabel.isNotEmpty) {
        colText = "$accLabel$colText";
      }
      if (i == parts.length - 1 && suffixLabel.isNotEmpty) {
        colText = "$colText$suffixLabel";
      }

      final widget = Text(
        colText,
        style: displayStyle,
        textAlign: colAligns[i],
        overflow: TextOverflow.ellipsis,
      );

      if (colWidths[i] == 0) {
        children.add(Expanded(child: widget));
      } else {
        children.add(SizedBox(
          width: colWidths[i],
          child: widget,
        ));
      }

      // 列間のパディング
      if (i < parts.length - 1) {
        children.add(const SizedBox(width: 8));
      }
    }

    return Row(
      children: children,
    );
  }

  Widget _buildMenuCategoryRow(String text) {
    final hasTab = text.contains('\t');
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 16, color: Colors.lightBlueAccent),
          // 左端インセットを 40px に揃える (padding.left=10 + icon=16 + SizedBox=14)
          SizedBox(width: hasTab ? 14 : 6),
          Expanded(
            child: hasTab
                ? _buildTabSeparatedRow(
                    text,
                    const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    isHeader: true,
                  )
                : Text(
                    text.trim(),
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOverlay() {
    final isExtCmdMenu = _screen.menuPrompt.contains("拡張コマンド");
    final isMultiSelectMenu = !isExtCmdMenu && _screen.menuHow > 1;
    final extCmdQuery = _extCmdMenuFilter.trim().toLowerCase();

    // 拡張コマンド選択のメタコマンド（#や?など）をフィルタリングして除外する（開発制約 9）
    final filteredItems = _screen.menuItems.where((item) {
      final text = item.text.trim();
      if (isExtCmdMenu) {
        if (text == "#" || text == "?") {
          return false;
        }
        if (extCmdQuery.isEmpty) {
          return true;
        }
        final tabIndex = text.indexOf('\t');
        final commandText = (tabIndex >= 0 ? text.substring(0, tabIndex) : text).trim().toLowerCase();
        final descriptionText = (tabIndex >= 0 ? text.substring(tabIndex + 1) : "").trim().toLowerCase();
        return commandText.contains(extCmdQuery) || descriptionText.contains(extCmdQuery);
      }
      return !text.startsWith('#') && !text.startsWith('?');
    }).toList();

    final hasTabMenu = filteredItems.any((item) => item.text.contains('\t'));

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.92),
        padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
        child: Card(
          margin: EdgeInsets.zero,
          color: const Color(0xFF12161D),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_screen.menuPrompt.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        isMultiSelectMenu ? Icons.checklist_rounded : Icons.menu_book_rounded,
                        size: 18,
                        color: Colors.amber[300],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _screen.menuPrompt,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 8),
                ],
                if (isExtCmdMenu) ...[
                  TextField(
                    controller: _extCmdMenuFilterController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '拡張コマンドを検索...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0E1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _extCmdMenuFilter = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final listView = ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelectable = item.ident != 0;
                            final isCategory = _isMenuCategoryItem(item);
                            final isDivider = !isSelectable && _isMenuDividerText(item.text);
                            final isPlain = !isSelectable && !isCategory && !isDivider;
                            final isPrintableAccel = item.accelerator >= 0x21 && item.accelerator <= 0x7E;
                            final accLabel = isPrintableAccel
                                ? "${String.fromCharCode(item.accelerator)} - "
                                : "";
                            final itemText = item.text.trim();

                            String commandText = itemText;
                            String descriptionText = "";
                            if (isExtCmdMenu) {
                              final tabIndex = itemText.indexOf('\t');
                              if (tabIndex >= 0) {
                                commandText = itemText.substring(0, tabIndex).trim();
                                descriptionText = itemText.substring(tabIndex + 1).trim();
                              }
                            }

                            if (isCategory) {
                              return _buildMenuCategoryRow(commandText);
                            }
                            if (isDivider) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                              );
                            }

                            Color itemColor = Colors.white;
                            if (!isExtCmdMenu && item.color >= 0 && item.color < 16) {
                              itemColor = _getNhColor(item.color);
                            }

                            if (isPlain) {
                              final hasTab = commandText.contains('\t');
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                child: Row(
                                  children: [
                                    _buildMenuItemTile(item.tile),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: hasTab
                                          ? _buildTabSeparatedRow(
                                              commandText,
                                              TextStyle(
                                                color: itemColor,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              accLabel: accLabel,
                                            )
                                          : Text(
                                              "$accLabel$commandText",
                                              style: TextStyle(
                                                color: itemColor,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (isMultiSelectMenu) {
                              final checked = _menuSelectedCounts.containsKey(item.ident);
                              final selectedCount = _menuSelectedCounts[item.ident] ?? 0;
                              final maxCount = _parseMaxCount(item.text);
                              final countLabel = checked ? " ($selectedCount個選択中 / $maxCount)" : "";
                              final hasTab = commandText.contains('\t');
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                  horizontalTitleGap: 8,
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildMenuItemTile(item.tile),
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: checked,
                                          onChanged: (_) => _toggleMenuSelection(item.ident),
                                          activeColor: Colors.tealAccent[400],
                                          checkColor: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: hasTab
                                      ? _buildTabSeparatedRow(
                                          commandText,
                                          TextStyle(
                                            color: checked ? Colors.tealAccent[400] : itemColor,
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          accLabel: accLabel,
                                          suffixLabel: countLabel,
                                        )
                                      : Text(
                                          "$accLabel$commandText$countLabel",
                                          style: TextStyle(
                                            color: checked ? Colors.tealAccent[400] : itemColor,
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                  onTap: () => _toggleMenuSelection(item.ident),
                                  onLongPress: () => _onMenuItemLongPress(item),
                                ),
                              );
                            }

                            if (isExtCmdMenu) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white12, width: 1.0),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Material(
                                    color: const Color(0xFF2C2C2C),
                                    borderRadius: BorderRadius.circular(8.0),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                      horizontalTitleGap: 8,
                                      leading: _buildMenuItemTile(item.tile),
                                      title: Text(
                                        "$accLabel$commandText",
                                        style: TextStyle(
                                          color: itemColor,
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: descriptionText.isNotEmpty
                                          ? Text(
                                              descriptionText,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      onTap: () => _sendMenuSelection(item.ident),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final hasTab = commandText.contains('\t');
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                horizontalTitleGap: 8,
                                leading: _buildMenuItemTile(item.tile),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    hasTab
                                        ? _buildTabSeparatedRow(
                                            commandText,
                                            TextStyle(
                                              color: itemColor,
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            accLabel: accLabel,
                                          )
                                        : Text(
                                            "$accLabel$commandText",
                                            style: TextStyle(
                                              color: itemColor,
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ],
                                ),
                                onTap: () => _sendMenuSelection(item.ident),
                                onLongPress: () => _onMenuItemLongPress(item),
                              ),
                            );
                          },
                        );
                        return hasTabMenu
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: constraints.maxWidth > 480 ? constraints.maxWidth : 480,
                                  child: listView,
                                ),
                              )
                            : listView;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (isMultiSelectMenu) ...[
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _menuSelectedCounts = <int, int>{};
                              for (final item in filteredItems) {
                                if (item.ident != 0) {
                                  _menuSelectedCounts[item.ident] = _parseMaxCount(item.text);
                                }
                              }
                            });
                          },
                          child: const Text("全て選択"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _menuSelectedCounts.clear();
                            });
                          },
                          child: const Text("解除"),
                        ),
                        ElevatedButton(
                          onPressed: () => _sendMenuSelections(_menuSelectedCounts),
                          child: const Text("OK"),
                        ),
                      ],
                      ElevatedButton(
                        onPressed: () => _sendMenuSelection(-1),
                        child: const Text("キャンセル"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYnOverlay() {
    final displayChoices = _ynChoices.contains('\x1b')
        ? _ynChoices.substring(0, _ynChoices.indexOf('\x1b'))
        : _ynChoices;
    final choices = displayChoices.split('');
    final isYesNo = displayChoices.toLowerCase() == 'yn' || displayChoices.toLowerCase() == 'ynq';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded, color: Colors.amber[300], size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '確認',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                    const SizedBox(height: 14),
                    Text(
                      _ynQuestion,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (isYesNo)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _sendYnResult('y'.codeUnitAt(0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_ynDefault == 'y'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendYnResult('n'.codeUnitAt(0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_ynDefault == 'n'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                          if (_ynChoices.toLowerCase().contains('q'))
                            ElevatedButton(
                              onPressed: () => _sendYnResult('q'.codeUnitAt(0)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_ynDefault == 'q'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Quit'),
                            ),
                          _buildMsgHistoryButton(),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ...choices.map((ch) {
                            final isDefault = ch.codeUnitAt(0) == _ynDefault;
                            return ElevatedButton(
                              onPressed: () => _sendYnResult(ch.codeUnitAt(0)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDefault ? Colors.teal[500] : Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(ch),
                            );
                          }),
                          ElevatedButton(
                            onPressed: () => _sendYnResult(27), // ESC
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white70),
                            child: const Text('キャンセル'),
                          ),
                          _buildMsgHistoryButton(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGetLineOverlay() {
    final isExtCmd = _extCmdList.isNotEmpty;
    
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.84),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber[300]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getlinePrompt,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _getlineController,
                    autofocus: true,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'テキストを入力してください',
                      filled: true,
                      fillColor: const Color(0xFF0E1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (val) {
                      _sendGetLineResult(val);
                    },
                  ),
                  if (isExtCmd) ...[
                    const SizedBox(height: 8),
                    const Text("拡張コマンドの選択:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _extCmdFilterController,
                      decoration: InputDecoration(
                        hintText: 'コマンドを絞り込み...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF0E1117),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) {
                        final query = val.toLowerCase();
                        setState(() {
                          _filteredExtCmds = _extCmdList
                              .where((entry) {
                                return entry.command.toLowerCase().contains(query)
                                    || entry.description.toLowerCase().contains(query);
                              })
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filteredExtCmds.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredExtCmds[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                title: Text(
                                  entry.command,
                                  style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                                ),
                                subtitle: entry.description.isNotEmpty
                                    ? Text(
                                        entry.description,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      )
                                    : null,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                onTap: () {
                                  _getlineController.text = entry.command;
                                  _sendGetLineResult(entry.command);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 道具/階層への命名入力時のみ履歴ボタンを表示。
                      // 銘刻/拡張コマンド/ウィッシュ/その他自由入力では出さない (UX ノイズ回避)。
                      if (_isCallOrNamePrompt(_getlinePrompt))
                        _buildMsgHistoryButton()
                      else
                        const SizedBox.shrink(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _sendGetLineResult(null),
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _sendGetLineResult(_getlineController.text),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[500]),
                            child: const Text('決定'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAskNameOverlay() {
    String modeDescText;
    Color modeDescBorderColor;
    switch (_selectedPlayMode) {
      case PlayMode.normal:
        modeDescText = "🏆 通常のスコアアタック・標準プレイ用。死亡するとゲームオーバーになります。";
        modeDescBorderColor = Colors.amber.withValues(alpha: 0.4);
        break;
      case PlayMode.explore:
        modeDescText = "🔍 死亡時に復活を選択できる練習用モード。スコアはハイスコア一覧に記録されません。";
        modeDescBorderColor = Colors.lightBlueAccent.withValues(alpha: 0.4);
        break;
      case PlayMode.wizard:
        modeDescText = "🧙 デバッグ・検証用モード。任意のアイテム生成や無敵化コマンドなどのデバッグ機能が使用できます（名前は wizard に固定）。";
        modeDescBorderColor = Colors.purpleAccent.withValues(alpha: 0.4);
        break;
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.84),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18, color: Colors.amber[300]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "お名前は？",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _askNameController,
                        autofocus: true,
                        enabled: _selectedPlayMode != PlayMode.wizard,
                        maxLength: _askNameMaxChars,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _selectedPlayMode == PlayMode.wizard
                              ? const Color(0xFF1E2530)
                              : const Color(0xFF0E1117),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          _sendAskNameResult(val);
                        },
                      ),
                      if (_askNameSaves.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("既存のセーブデータ:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _askNameSaves.length,
                            itemBuilder: (context, index) {
                              final name = _askNameSaves[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  leading: const Icon(Icons.account_circle, color: Colors.lightBlueAccent, size: 20),
                                  dense: true,
                                  onTap: () {
                                    if (_selectedPlayMode == PlayMode.wizard) {
                                      _previousCustomName = name;
                                    } else {
                                      _askNameController.text = name;
                                      _previousCustomName = name;
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text("プレイモード:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      SegmentedButton<PlayMode>(
                        segments: const [
                          ButtonSegment<PlayMode>(
                            value: PlayMode.normal,
                            label: Text("通常", style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.emoji_events_outlined, size: 15),
                          ),
                          ButtonSegment<PlayMode>(
                            value: PlayMode.explore,
                            label: Text("探索", style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.search, size: 15),
                          ),
                          ButtonSegment<PlayMode>(
                            value: PlayMode.wizard,
                            label: Text("ウィザード", style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.auto_fix_high, size: 15),
                          ),
                        ],
                        selected: {_selectedPlayMode},
                        onSelectionChanged: (Set<PlayMode> newSelection) {
                          final newMode = newSelection.first;
                          setState(() {
                            if (newMode == PlayMode.wizard) {
                              if (_selectedPlayMode != PlayMode.wizard) {
                                _previousCustomName = _askNameController.text;
                              }
                              _askNameController.text = "wizard";
                            } else {
                              if (_selectedPlayMode == PlayMode.wizard) {
                                _askNameController.text = _previousCustomName.isNotEmpty ? _previousCustomName : "Player";
                              }
                            }
                            _selectedPlayMode = newMode;
                          });
                        },
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: modeDescBorderColor),
                        ),
                        child: Text(
                          modeDescText,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _sendAskNameResult(null),
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _sendAskNameResult(_askNameController.text),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[500]),
                            child: const Text('ゲーム開始'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShortcutEditDialog(int index) {
    _loadExtCmds();

    final List<Map<String, String>> extCommands = [];
    for (final entry in _extCmdList) {
      var cmd = entry.command;
      if (!cmd.startsWith('#') && !cmd.startsWith('?')) {
        cmd = '#$cmd';
      }
      extCommands.add({
        'command': cmd,
        'description': entry.description,
      });
    }

    final shortcutLabels = [
      "左上ボタン (0)", "上中央ボタン (1)", "右上ボタン (2)",
      "中段左ボタン (3)", "中段中央ボタン (4)", "中段右ボタン (5)",
      "下段左ボタン (6)", "下段中央ボタン (7)", "下段右ボタン (8)"
    ];

    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      final defaultShortcuts = [
        'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', '#chat', '#chronicle', '#overview', '#attributes'
      ];
      final currentVal = prefs.getString('shortcut_btn_$index') ?? defaultShortcuts[index];
      final parsed = CmdItem.parseCmds(currentVal);
      final currentCmdItem = parsed.isNotEmpty ? parsed.first : CmdItem(command: currentVal);

      final controller = TextEditingController(text: currentCmdItem.command);
      final labelController = TextEditingController(text: currentCmdItem.label);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("${shortcutLabels[index]} を編集"),
          content: SingleChildScrollView(
            child: Column(
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
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
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      String filterText = '';
                      return StatefulBuilder(
                        builder: (context, setStateDialog) {
                          final filtered = extCommands.where((item) {
                            final cmd = (item['command'] ?? '').toLowerCase();
                            final desc = (item['description'] ?? '').toLowerCase();
                            final query = filterText.toLowerCase();
                            return cmd.contains(query) || desc.contains(query);
                          }).toList();

                          return AlertDialog(
                            title: const Text("拡張コマンド"),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: 350,
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
                                              "見つかりませんでした",
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: filtered.length,
                                            itemBuilder: (context, idx) {
                                              final item = filtered[idx];
                                              final cmd = item['command'] ?? '';
                                              final desc = item['description'] ?? '';
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.white12, width: 1.0),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                  ),
                                                  child: Material(
                                                    color: const Color(0xFF2C2C2C),
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: ListTile(
                                                      title: Text(
                                                        cmd,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      subtitle: desc.isNotEmpty
                                                          ? Text(
                                                              desc,
                                                              style: const TextStyle(
                                                                color: Colors.white70,
                                                                fontSize: 12,
                                                              ),
                                                            )
                                                          : null,
                                                      onTap: () {
                                                        controller.text = cmd;
                                                        Navigator.pop(context);
                                                      },
                                                    ),
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
                                onPressed: () => Navigator.pop(context),
                                child: const Text("キャンセル"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text("拡張コマンドから選択..."),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: "表示ラベル (任意)",
                  hintText: "例: 道具, 地形, #メニュー",
                  helperText: "空にするとコマンド名がそのまま表示されます",
                ),
              ),
            ],
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () {
                final cmdVal = controller.text.trim();
                final labelVal = labelController.text.trim();
                if (cmdVal.isNotEmpty || labelVal.isNotEmpty) {
                  final serialized = CmdItem.serializeCmds([CmdItem(command: cmdVal, label: labelVal)]);
                  prefs.setString('shortcut_btn_$index', serialized).then((_) {
                    if (mounted) {
                      setState(() {
                        _controlsVersion++;
                      });
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("保存"),
            ),
          ],
        ),
      );
    });
  }

  /// メッセージ履歴パネルを表示する。
  /// 画面下半部（約60%）をスライドアップして _screen.messageHistory の全履歴を表示。
  /// ゲームに入力を送らずに閉じることができる。
  void _showMsgHistoryPanel() {
    if (!mounted) return;
    final messages = List<String>.from(_screen.messageHistory);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // 領域外タップで閉じる（ゲームに入力は送らない）
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF12161D),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  // ドラッグハンドル
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // タイトル行
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18, color: Colors.amber[300]),
                        const SizedBox(width: 8),
                        const Text(
                          'メッセージ履歴',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${messages.length}件',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                  // メッセージ一覧（新しいメッセージが下）
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Text(
                              'メッセージ履歴はありません',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: messages.length,
                            // reverse: true により index=0 が一番下になるため、逆順でデータ参照
                            itemBuilder: (_, index) {
                              final dataIndex = messages.length - 1 - index;
                              final line = messages[dataIndex];
                              // 最新メッセージは白、古いものはグレーでフェード表示
                              final ratio = (dataIndex + 1) / messages.length;
                              final color = Color.lerp(Colors.white38, Colors.white, ratio)!;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: color,
                                    fontFamily: 'monospace',
                                    fontSize: _msgFontSize,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // 閉じるボタン
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheetContext).padding.bottom + 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('閉じる'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 履歴ボタン。YN/getline/テキストウィンドウ オーバーレイに共通で載せる。
  // 押下で既存の _showMsgHistoryPanel() (ボトムシート) を開く。
  // 視覚的に応答ボタンと区別するため、Amber 系のアウトラインで「補助操作」感を出す。
  Widget _buildMsgHistoryButton({String label = '履歴'}) {
    return OutlinedButton.icon(
      onPressed: _showMsgHistoryPanel,
      icon: const Icon(Icons.history, size: 18, color: Colors.amber),
      label: Text(label, style: const TextStyle(color: Colors.amber)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber,
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // getline のプロンプトが「アイテム/階層に名前を付ける」系か判定する。
  // 該当する場合のみ getline オーバーレイに履歴ボタンを表示する。
  // 対応パターン (C 側 src/do_name.c, src/nhlua.c 由来):
  //   "%sを何と呼びますか?" (docall / do_oname 経由の call)
  //   "%s%sを何と名付けますか?" (do_oname 経由の name)
  //   "この液体を何と呼びますか?" (流し台の药水)
  //   "このダンジョン階層にどのような名前を付けますか?" (nhlua.c:693)
  //   英語版: "What do you want to call/name this ___?" も念のため拾う。
  // 銘刻/ウィッシュ/虐殺/拡張コマンドは除外。
  bool _isCallOrNamePrompt(String prompt) {
    if (prompt.isEmpty) return false;
    return prompt.contains('何と呼びますか')
        || prompt.contains('何と名付けますか')
        || prompt.contains('名前を付け')
        || prompt.toLowerCase().contains('call this')
        || prompt.toLowerCase().contains('name this');
  }

  void _showScoreboardDialog() {
    List<TopTenEntry> entries = [];
    try {
      final ffi = NetHackFfi();
      final ptr = ffi.getTopTenTextFlutter();
      if (ptr != nullptr) {
        final text = ptr.toDartString();
        if (text.trim().isNotEmpty) {
          final lines = text.split('\n');
          entries = TopTenEntry.parse(lines, const []);
        }
      }
    } catch (e) {
      debugPrint('getTopTenTextFlutter fetch info/error: $e');
    }

    if (entries.isEmpty) {
      final recordPath = _findRecordFilePath();
      if (recordPath != null) {
        entries = _parseRecordFile(recordPath);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF12161D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: entries.isNotEmpty
                      ? TopTenWidget(entries: entries)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'スコア記録がありません',
                                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ゲームをプレイしてハイスコアを目指しましょう！',
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          defaultsFilePath: '$_assetsPath/defaults.nh',
          dataDirString: _assetsPath,
        ),
      ),
    ).then((_) {
      _loadPreferences().then((_) {
        if (_isGameRunning) {
          _applyScreenMode(_screenMode);
        }
      });
    });
  }

  Widget _buildGameScreen() {
    return ListenableBuilder(
      listenable: _screen,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ステータス領域 (Java版に合わせて最上部に配置)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isGameRunning && _isMainGameStarted && _waitingForInput
                      ? () => _sendShortcutToC('#attributes\n')
                      : null,
                  child: _statusDisplayMode == 0
                      ? Container(
                          height: 38,
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text.rich(
                              TextSpan(
                                children: _screen.statusLines.map((line) => _parseStatusLine(line)).toList().fold<List<InlineSpan>>([], (prev, element) {
                                  if (prev.isNotEmpty) {
                                    prev.add(const TextSpan(text: '\n'));
                                  }
                                  prev.add(element);
                                  return prev;
                                }),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text.rich(
                            TextSpan(
                              children: _screen.statusLines.map((line) => _parseStatusLine(line)).toList().fold<List<InlineSpan>>([], (prev, element) {
                                if (prev.isNotEmpty) {
                                  prev.add(const TextSpan(text: '\n'));
                                }
                                prev.add(element);
                                return prev;
                              }),
                            ),
                          ),
                        ),
                ),
                // 2(旧). メッセージ領域は廃止 — マップ上のオーバーレイで表示
                // 3. マップ表示（メッセージオーバーレイを重ねるため Stack でラップ）
                Expanded(
                  child: Stack(
                    children: [
                      // マップ本体
                      Container(
                        key: _mapViewportKey,
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          boundaryMargin: const EdgeInsets.all(2000.0), // 十分なマージンを設けて枠外への無限移動（クランプ解除）を許可
                          constrained: false, // 子が親(画面幅)に制限されずunconstrainedでスクロール可能にする
                          maxScale: 6.0,
                          minScale: 0.5,
                          onInteractionStart: (details) {
                            _isMapScrolledOrZoomed = true;
                          },
                          onInteractionUpdate: (details) {
                            // ユーザーがピンチズームしたズーム倍率をリアルタイムに保存
                            _currentScale = _transformationController.value.getMaxScaleOnAxis();
                            _isMapScrolledOrZoomed = true;
                          },
                          child: Center(
                            child: SizedBox(
                              width: 4000.0, // 巨大キャンバスでくるみ InteractiveViewer のクランプを完全無効化
                              height: 3000.0,
                              // マップタップ検出: 主人公タイルをタップで
                              // #herecmdmenu を発動する (Java 版と同じ挙動)。
                              // 単発タップのみ拾う (onTapUp) ことで
                              // InteractiveViewer のパン/ピンチ操作と競合させない。
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapDown: (details) {
                                  _lastMapTapDownDetails = details;
                                },
                                onTap: () {
                                  if (_lastMapTapDownDetails != null) {
                                    _handleMapTap(_lastMapTapDownDetails!);
                                  }
                                },
                                child: CustomPaint(
                                  painter: NetHackMapPainter(
                                    screen: _screen,
                                    tileImage: _tileImage,
                                    tileSize: _tileSize,
                                    useTiles: _useTiles,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // メッセージオーバーレイ（マップ上部に半透明で重ねる）
                      // タップすると履歴パネルを表示する、またはMORE状態を解除する
                      if (_screen.messageHistory.isNotEmpty || _screen.topline != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Builder(
                            builder: (context) {
                              final displayedLines = List<String>.from(
                                _screen.messageHistory.sublist(
                                  _screen.messageHistory.length > _msgLineCount
                                      ? _screen.messageHistory.length - _msgLineCount
                                      : 0,
                                ),
                              );
                              // topline (farlook 説明など) があれば
                              // 履歴の最下行を上書きする。 履歴が空なら
                              // topline 単独で 1 行表示。
                              final topline = _screen.topline;
                              final isToplineActive = topline != null;
                              if (isToplineActive) {
                                if (displayedLines.isNotEmpty) {
                                  displayedLines[displayedLines.length - 1] = topline;
                                } else {
                                  displayedLines.add(topline);
                                }
                              }
                              if (_screen.isMoreActive) {
                                displayedLines.add(" -- MORE --");
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: displayedLines.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final line = entry.value;
                                  final isMoreLine = _screen.isMoreActive && index == displayedLines.length - 1;
                                  final isToplineLine = isToplineActive &&
                                      index == displayedLines.length - 1 - (_screen.isMoreActive ? 1 : 0);
                                  final double ratio = displayedLines.length > 1
                                      ? index / (displayedLines.length - 1)
                                      : 1.0;
                                  final color = isMoreLine
                                      ? Colors.amber[400]!
                                      : isToplineLine
                                          ? Colors.cyanAccent[200]!
                                          : Color.lerp(Colors.white30, Colors.white, ratio)!;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_screen.isMoreActive) {
                                          _sendFfiKey(32, 'Space');
                                          _screen.setMoreActive(false);
                                        } else {
                                          _showMsgHistoryPanel();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: _msgOpacity),
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        child: Text(
                                          line,
                                          style: TextStyle(
                                            color: color,
                                            fontFamily: 'monospace',
                                            fontSize: _msgFontSize,
                                            fontWeight: (isMoreLine || isToplineLine)
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // テキスト/ヘルプウィンドウのオーバーレイ表示
            if (_screen.isTextWindowVisible)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.92),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: const Color(0xFF12161D),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: () {
                              final isTombstone = _screen.textLines.length >= 13 &&
                                  ((_screen.textLines.any((line) => line.contains('REST')) &&
                                      _screen.textLines.any((line) => line.contains('PEACE'))) ||
                                  _screen.textLines.any((line) => line.contains('REST    \\')));

                              if (isTombstone) {
                                if (_tombstoneDisplayMode == 0) {
                                  final data = TombstoneData.parse(_screen.textLines);
                                  return UniversalTombstoneWidget(
                                    mode: TombstoneDisplayMode.image,
                                    data: data,
                                    lines: _screen.textLines,
                                  );
                                }
                                return UniversalTombstoneWidget(
                                  mode: TombstoneDisplayMode.text,
                                  lines: _screen.textLines,
                                );
                              }

                              final isTopTen = _screen.textLines.any((line) =>
                                  line.contains('順位') &&
                                  line.contains('点数') &&
                                  line.contains('名前'));

                              if (isTopTen) {
                                final data = TopTenEntry.parse(_screen.textLines, _screen.textAttrs);
                                return TopTenWidget(entries: data);
                              }

                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _screen.textLines.length,
                                  itemBuilder: (context, index) {
                                    final line = _screen.textLines[index];
                                    final trimmed = line.trim();
                                    final isDivider = trimmed.isEmpty || RegExp(r'^[-=\s]+$').hasMatch(trimmed);
                                    final isCategory = !_screen.isPlainDialog && !isDivider && (trimmed.endsWith(':') || trimmed.endsWith('：'));

                                    if (isCategory) {
                                      return _buildMenuCategoryRow(line);
                                    }
                                    if (isDivider) {
                                      if (trimmed.isEmpty) {
                                        return const SizedBox(height: 8);
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                                      );
                                    }

                                    // putmixed 経由のテキスト (例: `/` 結果リスト) は
                                    // C 側 (`winflutter.c::flutter_putmixed_with_tile`)
                                    // で `decode_mixed()` により showsym 1 文字
                                    // (CP437) にデコード済み。 そのまま表示する。
                                    // タイルモード時のみ、 テキスト先頭にタイル画像を
                                    // 並べて表示する (showsym 文字と重複しない)。
                                    final tile = (index < _screen.textTiles.length)
                                        ? _screen.textTiles[index]
                                        : -1;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          _buildMenuItemTile(tile),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'monospace',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            }(),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMsgHistoryButton(),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _sendFfiKey(32, "Space"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[500],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    "OK",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // メニュアル選択ウィンドウのオーバーレイ表示
            if (_screen.isMenuWindowVisible)
              _buildMenuOverlay(),
            // 同期型ダイアログオーバーレイ
            if (_isYnVisible) _buildYnOverlay(),
            if (_isGetLineVisible) _buildGetLineOverlay(),
            if (_isAskNameVisible) _buildAskNameOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildControllerOverlay() {
    if (!_shouldShowController) {
      return const SizedBox.shrink();
    }

    if (_controllerMode == ControllerMode.keyboard) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: NetHackKeyboard(
          opacity: _padOpacity,
          onKeyPress: (key) => _sendKeysToC(key),
          onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
          onToggleMode: () {
            setState(() {
              _controllerMode = ControllerMode.pad;
            });
          },
        ),
      );
    }

    final cmdPanelScaledHeight = _cmdPanelHeight * _cmdPanelEffectiveScale;
    const padTopPadding = 6.0;
    const sideMargin = 8.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // コマンドパネル: 画面最下端、左下起点で scale
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.scale(
            scale: _cmdPanelEffectiveScale,
            alignment: Alignment.bottomLeft,
            child: NetHackCmdPanel(
              key: ValueKey(_controlsVersion),
              opacity: _padOpacity,
              showPanelNames: _showPanelNames,
              extCmdList: _extCmdList.map((e) => {'command': e.command, 'description': e.description}).toList(),
              onKeyPress: (key) => _sendKeysToC(key),
              onRawKeyCode: (code) => _sendFfiKey(code, "^${String.fromCharCode(code + 96)}"),
              onPanelHeightChanged: (height) {
                if ((_cmdPanelHeight - height).abs() < 0.1) {
                  return;
                }
                if (!mounted) {
                  return;
                }
                setState(() {
                  _cmdPanelHeight = height;
                });
              },
              onToggleMode: () {
                setState(() {
                  _controllerMode = ControllerMode.keyboard;
                });
              },
            ),
          ),
        ),
        // 移動パッド: コマンドパネルの上、左下起点で scale
        Positioned(
          left: sideMargin,
          bottom: cmdPanelScaledHeight + padTopPadding,
          child: Padding(
            padding: const EdgeInsets.only(top: padTopPadding),
            child: Transform.scale(
              scale: _dpadEffectiveScale,
              alignment: Alignment.bottomLeft,
              child: NetHackDPad(
                opacity: _padOpacity,
                directionLabels: _buildDirectionLabels(),
                centerLabel: _isDirectionPromptActive ? '.' : _moveModeLabel(_dPadMoveMode),
                onDirectionPress: (viKey) {
                  _sendModeAppliedDirection(viKey);
                },
                onDirectionLongPress: (viKey) {
                  _sendModeAppliedDirection(viKey, modeOverride: _dPadLongPressMoveMode);
                },
                onCenterTap: _handleCenterTap,
                onCenterLongPress: () {
                  _showMoveModeSelectDialog();
                },
              ),
            ),
          ),
        ),
        // ショートカットパッド: コマンドパネルの上、右下起点で scale
        Positioned(
          right: sideMargin,
          bottom: cmdPanelScaledHeight + padTopPadding,
          child: Padding(
            padding: const EdgeInsets.only(top: padTopPadding),
            child: Transform.scale(
              scale: _shortcutPadEffectiveScale,
              alignment: Alignment.bottomRight,
              child: NetHackShortcutPad(
                key: ValueKey(_controlsVersion),
                opacity: _padOpacity,
                onKeyPress: (key) => _sendKeysToC(key),
                onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
                onShortcut: (cmd) => _sendShortcutToC(cmd),
                onShortcutLongPress: (index) => _showShortcutEditDialog(index),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartScreen() {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    Widget startScreenContent;

    if (isPortrait) {
      startScreenContent = Stack(
        children: [
          // ⚙設定ボタンを右上に配置
          Positioned(
            top: 16,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
              onPressed: _showSettingsDialog,
              tooltip: "ゲーム設定",
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          // タイトルロゴを画面上から15%の位置に配置
          Positioned(
            top: screenHeight * 0.15,
            left: 24,
            right: 24,
            child: Center(
              child: Image.asset(
                'assets/darthack_logo.png',
                width: screenWidth * 0.75,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // 下部にボタンを配置
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: !_assetsReady
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "アセットを準備中...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.indigo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _startGame,
                            borderRadius: BorderRadius.circular(28),
                            child: const Center(
                              child: Text(
                                '冒険を始める',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black38,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    } else {
      // 横長画面（Landscape）時のレイアウト
      startScreenContent = Stack(
        children: [
          // ⚙設定ボタンを右上に配置
          Positioned(
            top: 16,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
              onPressed: _showSettingsDialog,
              tooltip: "ゲーム設定",
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          // 左右に分割するレイアウト
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 60.0, 40.0, 16.0), // 上部設定ボタンと被らないように上部にマージン
              child: Row(
                children: [
                  // 左側：タイトルロゴ
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Image.asset(
                        'assets/darthack_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  // 右側：ボタンや進捗
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: !_assetsReady
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "アセットを準備中...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.deepPurple, Colors.indigo],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepPurple.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _startGame,
                                      borderRadius: BorderRadius.circular(28),
                                      child: const Center(
                                        child: Text(
                                          '冒険を始める',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4,
                                                color: Colors.black38,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        // 背景画像
        Positioned.fill(
          child: Image.asset(
            'assets/darthack_title.png',
            fit: BoxFit.cover,
          ),
        ),
        // 暗めのオーバーレイ
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        // コンテンツ（SafeAreaを適用）
        Positioned.fill(
          child: SafeArea(
            child: startScreenContent,
          ),
        ),
      ],
    );
  }

  Widget _buildEndScreen() {
    return Stack(
      children: [
        // 終了時専用の背景画像
        Positioned.fill(
          child: Image.asset(
            'assets/darthack_end.png',
            fit: BoxFit.cover,
          ),
        ),
        // 暗めのオーバーレイ
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateEffectiveScales(MediaQuery.of(context).size.width);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isGameRunning && _isMainGameStarted) {
          final bool? exitConfirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text("ゲームの終了", style: TextStyle(color: Colors.white)),
              content: const Text(
                "本当に終了しますか？\n（進行状況はセーブされません。セーブして終了するにはメニューの「セーブして終了」を使用してください。）",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("キャンセル", style: TextStyle(color: Colors.blueAccent)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("終了する", style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          );
          if (exitConfirmed == true) {
            _stopGame();
          }
        } else {
          _stopGame();
        }
      },
      child: Scaffold(
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2,
        drawer: _isMainGameStarted && _drawerPosition == 'left' ? Drawer(
          child: Container(
            color: Colors.grey[950],
            child: _buildDrawerContent(),
          ),
        ) : null,
        endDrawer: _isMainGameStarted && _drawerPosition == 'right' ? Drawer(
          child: Container(
            color: Colors.grey[950],
            child: _buildDrawerContent(),
          ),
        ) : null,
      body: SafeArea(
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (!_isGameRunning || !_waitingForInput) return;
            if (event is KeyDownEvent) {
              final char = event.character;
              if (char != null && char.isNotEmpty) {
                final code = char.codeUnitAt(0);
                _sendFfiKey(code, char);
              } else {
                int? code;
                String? name;
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) { code = 107; name = "k"; }
                else if (event.logicalKey == LogicalKeyboardKey.arrowDown) { code = 106; name = "j"; }
                else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) { code = 104; name = "h"; }
                else if (event.logicalKey == LogicalKeyboardKey.arrowRight) { code = 108; name = "l"; }
                else if (event.logicalKey == LogicalKeyboardKey.enter) { code = 10; name = "Enter"; }
                else if (event.logicalKey == LogicalKeyboardKey.escape) { code = 27; name = "ESC"; }
                else if (event.logicalKey == LogicalKeyboardKey.space) { code = 32; name = "Space"; }
                
                if (code != null) {
                  _sendFfiKey(code, name ?? "");
                }
              }
            }
          },
          child: Stack(
            children: [
              _isGameRunning
                  ? Column(
                      children: [
                        Expanded(
                          child: _buildGameScreen(),
                        ),
                      ],
                    )
                  : (_isGameFinished ? _buildEndScreen() : _buildStartScreen()),
              _buildControllerOverlay(),
              if (_isGameRunning && _isMainGameStarted) ...[
                _buildMenuButton(),
                _buildDrawerBarrier(_isTopDrawerOpen, () => setState(() => _isTopDrawerOpen = false)),
                _buildDrawerBarrier(_isBottomDrawerOpen, () => setState(() => _isBottomDrawerOpen = false)),
                _buildTopDrawer(),
                _buildBottomDrawer(),
              ],
            ],
          ),
        ),
      ),
    ),);
  }

  // DartHackカラーテーブル
  Color _getNhColor(int colorIndex) {
    switch (colorIndex) {
      case 0: return Colors.black; // CLR_BLACK
      case 1: return Colors.red; // CLR_RED
      case 2: return Colors.green; // CLR_GREEN
      case 3: return const Color(0xFF8B4513); // CLR_BROWN (サドルブラウン等)
      case 4: return Colors.blue; // CLR_BLUE
      case 5: return Colors.purple; // CLR_MAGENTA
      case 6: return Colors.cyan; // CLR_CYAN
      case 7: return Colors.grey; // CLR_GRAY
      case 8: return Colors.white70; // CLR_NO_COLOR
      case 9: return Colors.orange; // CLR_ORANGE
      case 10: return Colors.lightGreen; // CLR_BRIGHT_GREEN
      case 11: return Colors.yellow; // CLR_YELLOW
      case 12: return Colors.lightBlue; // CLR_BRIGHT_BLUE
      case 13: return Colors.pinkAccent; // CLR_BRIGHT_MAGENTA
      case 14: return Colors.cyanAccent; // CLR_BRIGHT_CYAN
      case 15: return Colors.white; // CLR_WHITE
      default: return Colors.white;
    }
  }

  // ステータス行の \CXXXXXXXX と \c マークアップパース処理
  TextSpan _parseStatusLine(String line) {
    // 1. まず、金貨のエスケープ \G が残っていれば $ に置換する (フォールバック)
    var processedLine = line.replaceAll(RegExp(r'\\G([0-9a-fA-F]{8}):?'), '\$ ');
    
    // 2. \\CXXXXXXXX と \\c のマークアップをパースして TextSpan を構築
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\\C([0-9a-fA-F]{8})|\\c');
    
    int lastIndex = 0;
    Color currentColor = Colors.white;
    
    for (final match in regex.allMatches(processedLine)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: processedLine.substring(lastIndex, match.start),
          style: TextStyle(color: currentColor),
        ));
      }
      
      final matchedText = match.group(0);
      if (matchedText == '\\c') {
        currentColor = Colors.white;
      } else {
        final hexStr = match.group(1)!;
        final colorIndex = int.tryParse(hexStr, radix: 16) ?? 15;
        currentColor = _getNhColor(colorIndex);
      }
      
      lastIndex = match.end;
    }
    
    if (lastIndex < processedLine.length) {
      spans.add(TextSpan(
        text: processedLine.substring(lastIndex),
        style: TextStyle(color: currentColor),
      ));
    }
    
    return TextSpan(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      children: spans,
    );
  }
}

enum TombstoneDisplayMode {
  image,
  text,
}

enum ScreenMode {
  normal,
  immersive,
}

class TombstoneData {
  final String name;
  final String gold;
  final List<String> deathLines;
  final String year;

  TombstoneData({
    required this.name,
    required this.gold,
    required this.deathLines,
    required this.year,
  });

  factory TombstoneData.parse(List<String> lines) {
    String clean(String line) {
      var content = line;
      if (line.contains('|')) {
        final parts = line.split('|');
        if (parts.length >= 3) {
          content = parts[1];
        } else {
          content = line.replaceAll('|', '');
        }
      }
      return content.trim();
    }

    final name = lines.length > 6 ? clean(lines[6]) : "";
    final gold = lines.length > 7 ? clean(lines[7]) : "";
    final deathLines = <String>[];
    for (int i = 8; i <= 11; i++) {
      if (lines.length > i) {
        final c = clean(lines[i]);
        if (c.isNotEmpty && c != "." && c != "...") {
          deathLines.add(c);
        }
      }
    }
    final year = lines.length > 12 ? clean(lines[12]) : "";

    return TombstoneData(
      name: name,
      gold: gold,
      deathLines: deathLines,
      year: year,
    );
  }
}

class UniversalTombstoneWidget extends StatelessWidget {
  final TombstoneDisplayMode mode;
  final TombstoneData? data;
  final List<String>? lines;

  const UniversalTombstoneWidget({
    super.key,
    this.mode = TombstoneDisplayMode.image,
    this.data,
    this.lines,
  }) : assert(
          mode == TombstoneDisplayMode.image ? data != null : lines != null,
          'image mode requires data, text mode requires lines',
        );

  @override
  Widget build(BuildContext context) {
    if (mode == TombstoneDisplayMode.text) {
      return _buildTextMode();
    }
    return _buildImageMode();
  }

  Widget _buildTextMode() {
    final source = lines ?? const <String>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            source.join('\n'),
            softWrap: false,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMode() {
    final d = data!;
    final source = lines ?? const <String>[];

    // 墓石アスキーアートの芝生部分（底辺）のインデックスを探す
    int bottomIndex = source.indexWhere((line) => line.contains('_________'));
    if (bottomIndex == -1) {
      bottomIndex = 14;
    }

    // 底辺以降のテキストを取得
    List<String> belowTombstoneLines = [];
    if (source.length > bottomIndex + 1) {
      belowTombstoneLines = source.sublist(bottomIndex + 1);
    }

    // トリミング：先頭と末尾の空行を削除
    while (belowTombstoneLines.isNotEmpty && belowTombstoneLines.first.trim().isEmpty) {
      belowTombstoneLines.removeAt(0);
    }
    while (belowTombstoneLines.isNotEmpty && belowTombstoneLines.last.trim().isEmpty) {
      belowTombstoneLines.removeLast();
    }

    final belowTombstoneText = belowTombstoneLines.join('\n');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/tombstone.png',
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;
                            final scale = width / 400;

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: width * 0.12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: height * 0.32),
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 20 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFCCCCCC),
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: height * 0.02),
                                  Text(
                                    d.gold,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 16 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB0B0B0),
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: height * 0.03),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: d.deathLines.map((line) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            line,
                                            style: TextStyle(
                                              fontFamily: 'serif',
                                              fontSize: 13 * scale,
                                              fontWeight: FontWeight.normal,
                                              color: const Color(0xFFAAAAAA),
                                              height: 1.3,
                                              shadows: [
                                                Shadow(
                                                  offset: const Offset(1, 1),
                                                  blurRadius: 1.5,
                                                  color: Colors.black.withValues(alpha: 0.8),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  Text(
                                    d.year,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 15 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF999999),
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 1.5,
                                          color: Colors.black.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: height * 0.08),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (belowTombstoneText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: SelectableText(
                    belowTombstoneText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TopTenEntry {
  final int rank;
  final String score;
  final String nameAndProfile;
  final List<String> details;
  final bool isCurrent;

  TopTenEntry({
    required this.rank,
    required this.score,
    required this.nameAndProfile,
    required this.details,
    required this.isCurrent,
  });

  static List<TopTenEntry> parse(List<String> lines, List<int> attrs) {
    final entries = <TopTenEntry>[];
    TopTenEntryBuilder? builder;

    // " 順位      点数  名前" などのヘッダー行は除外して、数字で始まる行からパースする
    final entryRegExp = RegExp(r'^\s*([0-9]+)\s+([0-9]+)\s+(.*)$');
    // 行末の HP 表示を検出する正規表現（" - [103]" や " 15 [120]" 等）
    final hpSuffixRegExp = RegExp(r'\s+(-|[0-9]+)\s+\[([0-9]+)\]\s*$');

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.trim().isEmpty) continue;

      // ヘッダーやその他のタイトル行は無視
      if (line.contains('順位') && line.contains('点数') && line.contains('名前')) {
        continue;
      }

      // 行末の HP 表示をチェック・抽出
      String? extractedHpInfo;
      final hpMatch = hpSuffixRegExp.firstMatch(line);
      if (hpMatch != null) {
        final hpVal = hpMatch.group(1);
        final maxHpVal = hpMatch.group(2);
        extractedHpInfo = 'HP/最大HP: $hpVal/$maxHpVal';
        line = line.substring(0, hpMatch.start);
      }

      final match = entryRegExp.firstMatch(line);
      if (match != null) {
        if (builder != null) {
          entries.add(builder.build());
        }
        final rank = int.tryParse(match.group(1)!) ?? 0;
        final score = match.group(2)!;
        final nameAndProfile = match.group(3)!.trim();
        
        final attr = i < attrs.length ? attrs[i] : 0;
        final isBold = (attr & 1) != 0; // ATR_BOLD (1)

        builder = TopTenEntryBuilder(
          rank: rank,
          score: score,
          nameAndProfile: nameAndProfile,
          isCurrent: isBold,
        );
        if (extractedHpInfo != null) {
          builder.details.add(extractedHpInfo);
        }
      } else {
        if (builder != null) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            builder.details.add(trimmed);
          }
          if (extractedHpInfo != null) {
            builder.details.add(extractedHpInfo);
          }
          final attr = i < attrs.length ? attrs[i] : 0;
          final isBold = (attr & 1) != 0;
          if (isBold) {
            builder.isCurrent = true;
          }
        }
      }
    }

    if (builder != null) {
      entries.add(builder.build());
    }

    return entries;
  }
}

class TopTenEntryBuilder {
  final int rank;
  final String score;
  final String nameAndProfile;
  final List<String> details = [];
  bool isCurrent;

  TopTenEntryBuilder({
    required this.rank,
    required this.score,
    required this.nameAndProfile,
    required this.isCurrent,
  });

  TopTenEntry build() {
    return TopTenEntry(
      rank: rank,
      score: score,
      nameAndProfile: nameAndProfile,
      details: details,
      isCurrent: isCurrent,
    );
  }
}

class TopTenWidget extends StatelessWidget {
  final List<TopTenEntry> entries;

  const TopTenWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                "スコアボード",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[200],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrent = entry.isCurrent;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                color: isCurrent ? const Color(0xFF2C2214) : const Color(0xFF1E222B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isCurrent ? const Color(0xFFFFB300) : Colors.white12,
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                ),
                elevation: isCurrent ? 6 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 順位表示
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${entry.rank}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // スコアとプレイヤー名
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${entry.score} 点",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.nameAndProfile,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isCurrent ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (entry.details.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            ...entry.details.map((detail) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCurrent ? Colors.white.withValues(alpha: 0.87) : Colors.grey[400],
                                      height: 1.3,
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                      if (isCurrent)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "今回の記録",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItemTilePainter extends CustomPainter {
  final ui.Image image;
  final int tileIndex;
  final int tileSize;

  _MenuItemTilePainter({
    required this.image,
    required this.tileIndex,
    required this.tileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cols = image.width ~/ tileSize;
    final iRow = tileIndex ~/ cols;
    final iCol = tileIndex % cols;

    final srcRect = Rect.fromLTWH(
      (iCol * tileSize).toDouble(),
      (iRow * tileSize).toDouble(),
      tileSize.toDouble(),
      tileSize.toDouble(),
    );

    final destRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      image,
      srcRect,
      destRect,
      Paint()..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _MenuItemTilePainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.tileIndex != tileIndex ||
           oldDelegate.tileSize != tileSize;
  }
}

class _RecordRawEntry {
  final int points;
  final int dnum;
  final int dlev;
  final int maxlvl;
  final int hp;
  final int maxhp;
  final String role;
  final String race;
  final String gend;
  final String align;
  final String name;
  final String death;

  _RecordRawEntry({
    required this.points,
    required this.dnum,
    required this.dlev,
    required this.maxlvl,
    required this.hp,
    required this.maxhp,
    required this.role,
    required this.race,
    required this.gend,
    required this.align,
    required this.name,
    required this.death,
  });
}

String? _findRecordFilePath() {
  final candidatePaths = [
    'record',
    './record',
    '../record',
    'sys/flutter/record',
  ];

  for (final path in candidatePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String _translateRoleCode(String code) {
  const map = {
    'Arc': '考古学者', 'Bar': '野蛮人', 'Cav': '洞窟人', 'Hea': '師',
    'Kni': '騎士', 'Mon': '修道士', 'Pri': '僧侶', 'Rog': '盗賊',
    'Ran': '旅人', 'Sam': '侍', 'Tou': '観光客', 'Val': 'バルキリー', 'Wiz': '魔法使い'
  };
  return map[code] ?? code;
}

String _translateRaceCode(String code) {
  const map = {'Hum': '人間', 'Elf': 'エルフ', 'Dwa': 'ドワーフ', 'Gno': 'ノーム', 'Orc': 'オーク'};
  return map[code] ?? code;
}

String _translateGendCode(String code) {
  if (code.startsWith('Mal') || code == 'M') return '男性';
  if (code.startsWith('Fem') || code == 'F') return '女性';
  return code;
}

String _translateAlignCode(String code) {
  if (code.startsWith('Law') || code == 'L') return '秩序';
  if (code.startsWith('Neu') || code == 'N') return '中立';
  if (code.startsWith('Cha') || code == 'C') return '混沌';
  return code;
}

String _translateDeathText(String death) {
  if (death == 'quit') return '自決した';
  if (death == 'starved') return '餓死した';
  if (death.startsWith('escaped')) return '脱出した';
  if (death.startsWith('ascended')) return '昇天した';
  if (death.startsWith('killed by a ')) return '${death.substring(12)}に殺された';
  if (death.startsWith('killed by an ')) return '${death.substring(13)}に殺された';
  if (death.startsWith('killed by ')) return '${death.substring(10)}に殺された';
  return death;
}

List<TopTenEntry> _parseRecordFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return [];

  try {
    final lines = file.readAsLinesSync();
    final rawEntries = <_RecordRawEntry>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 15) continue;

      final points = int.tryParse(parts[1]) ?? 0;
      final dnum = int.tryParse(parts[2]) ?? 1;
      final dlev = int.tryParse(parts[3]) ?? 1;
      final maxlvl = int.tryParse(parts[4]) ?? 1;
      final hp = int.tryParse(parts[5]) ?? 0;
      final maxhp = int.tryParse(parts[6]) ?? 0;
      final role = parts[11];
      final race = parts[12];
      final gend = parts[13];
      final align = parts[14];

      final rest = parts.sublist(15).join(' ');
      String name = rest;
      String death = '';
      final commaIdx = rest.indexOf(',');
      if (commaIdx != -1) {
        name = rest.substring(0, commaIdx).trim();
        death = rest.substring(commaIdx + 1).trim();
      }

      rawEntries.add(_RecordRawEntry(
        points: points,
        dnum: dnum,
        dlev: dlev,
        maxlvl: maxlvl,
        hp: hp,
        maxhp: maxhp,
        role: role,
        race: race,
        gend: gend,
        align: align,
        name: name,
        death: death,
      ));
    }

    rawEntries.sort((a, b) => b.points.compareTo(a.points));

    final entries = <TopTenEntry>[];
    for (int i = 0; i < rawEntries.length; i++) {
      final e = rawEntries[i];
      final rank = i + 1;
      final roleJp = _translateRoleCode(e.role);
      final raceJp = _translateRaceCode(e.race);
      final gendJp = _translateGendCode(e.gend);
      final alignJp = _translateAlignCode(e.align);

      final profile = '$roleJp/$raceJp/$gendJp/$alignJp';
      final nameAndProfile = '${e.name} $profile';

      final deathJp = _translateDeathText(e.death);
      final details = <String>[];
      if (deathJp.isNotEmpty) {
        details.add('$deathJp (メインダンジョン ${e.dlev}階)');
      } else {
        details.add('メインダンジョン ${e.dlev}階 [HP: ${e.hp}/${e.maxhp}]');
      }

      entries.add(TopTenEntry(
        rank: rank,
        score: '${e.points}',
        nameAndProfile: nameAndProfile,
        details: details,
        isCurrent: false,
      ));
    }

    return entries;
  } catch (e) {
    return [];
  }
}


