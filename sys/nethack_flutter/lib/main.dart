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
import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetHackJP Flutter Port',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.amber,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

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
  int _numberPadMode = 0;

  // 拡張コマンドサジェスト用
  List<ExtCmdEntry> _extCmdList = [];
  List<ExtCmdEntry> _filteredExtCmds = [];
  final TextEditingController _extCmdFilterController = TextEditingController();
  final TextEditingController _extCmdMenuFilterController = TextEditingController();
  String _extCmdMenuFilter = "";
  Set<int> _menuSelectedIds = <int>{};

  // 詳細な操作設定（shared_preferences用）
  double _padOpacity = 0.8;
  double _padScale = 1.0;
  int _autoSaveInterval = 0;
  int _statusDisplayMode = 0; // 0: 領域に合わせて文字サイズ縮小(Fit), 1: 領域の可変高さ(Wrap)
  String _drawerPosition = 'left';
  String _menuButtonPosition = 'top_left';
  bool _isTopDrawerOpen = false;
  bool _isBottomDrawerOpen = false;
  bool _isMainGameStarted = false;
  int? _mapWinId;

  // 物理キー割り当て設定
  int _volupAction = 0;
  int _voldownAction = 0;
  int _backAction = 0;

  // 設定変更の即時反映用バージョンカウンター
  int _controlsVersion = 0;
  double _cmdPanelHeight = 58.0;
  bool _showPanelNames = true;
  DPadMoveMode _dPadMoveMode = DPadMoveMode.normal;
  List<DPadMoveMode> _enabledDPadMoveModes = List<DPadMoveMode>.from(_allDPadMoveModes);
  bool _isDirectionPromptActive = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isGameRunning && _waitingForInput && !_isKeyboardVisible) {
        _focusNode.requestFocus();
      }
    });
    _loadPreferences().then((_) => _initAssets());
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
      _padScale = prefs.getDouble('pad_scale') ?? 1.0;
      _autoSaveInterval = prefs.getInt('auto_save_interval') ?? 0;
      _statusDisplayMode = prefs.getInt('status_display_mode') ?? 0;
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

      // 物理キーのロード
      _volupAction = prefs.getInt('key_volup_action') ?? 0;
      _voldownAction = prefs.getInt('key_voldown_action') ?? 0;
      _backAction = prefs.getInt('key_back_action') ?? 0;

      // コントロールのバージョンを更新
      _controlsVersion++;
    });
    if (tilesetChanged && _assetsReady) {
      unawaited(_loadTileset(newTileset));
    }
    _syncNativeKeySettings();
    _triggerCenterOnPlayer();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_tiles', _useTiles);
    await prefs.setString('selected_tileset', _selectedTileset);
    await prefs.setBool('keyboard_visible', _isKeyboardVisible);
    await prefs.setString('controller_mode', _controllerMode == ControllerMode.keyboard ? 'keyboard' : 'pad');
    await prefs.setDouble('pad_opacity', _padOpacity);
    await prefs.setDouble('pad_scale', _padScale);
    await prefs.setInt('auto_save_interval', _autoSaveInterval);
    await prefs.setInt('status_display_mode', _statusDisplayMode);
    await prefs.setString('drawer_position', _drawerPosition);
    await prefs.setString('menu_button_position', _menuButtonPosition);
    await prefs.setString('dpad_move_mode', _moveModeName(_dPadMoveMode));
    await prefs.setString(
      'dpad_enabled_move_modes',
      _enabledDPadMoveModes.map(_moveModeName).join(','),
    );
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
      await const MethodChannel('com.tbd.nethackjp/key_interceptor')
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
                'NetHackメニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_isGameRunning) ...[
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
              _sendFfiKey(81, "Q");
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
      return 230.0 * _padScale;
    }
    const padAndShortcutHeight = 162.0;
    return (padAndShortcutHeight + _cmdPanelHeight) * _padScale;
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
    final amountStr = amount.toString();
    for (int i = 0; i < amountStr.length; i++) {
      _sendFfiKey(amountStr.codeUnitAt(i), amountStr[i]);
    }
    _sendFfiKey(item.accelerator, String.fromCharCode(item.accelerator));
  }

  void _loadExtCmds() {
    try {
      final ffi = NetHackFfi();
      final ptr = ffi.getExtCmdsFlutter();
      if (ptr != nullptr) {
        final extCmdsStr = ptr.toDartString();
        final parsed = <ExtCmdEntry>[];
        final rawItems = extCmdsStr.split(';');

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
      _waitingForInput = false;
      _isMainGameStarted = false;
      _mapWinId = null;
      _isTopDrawerOpen = false;
      _isBottomDrawerOpen = false;
      _autoAdvanceSavePending = false;
      _exitDialogShown = false;
    });

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
          }
        } else if (type == 'clearWindow') {
          _screen.clearWindow(message['winId']);
        } else if (type == 'displayWindow') {
          _screen.displayWindow(
            message['winId'],
            (message['blocking'] as int? ?? 0) != 0,
          );
          // C側の blocking に基づく
          if (_mapWinId != null && message['winId'] == _mapWinId) {
            setState(() {
              _isMainGameStarted = true;
            });
          }
        } else if (type == 'destroyWindow') {
          _screen.destroyWindow(message['winId']);
        } else if (type == 'curs') {
          _screen.setCursor(message['winId'], message['x'], message['y']);
        } else if (type == 'putstr') {
          final text = (message['text'] as String?) ?? '';
          _screen.putString(message['winId'], message['attr'], text);
          final winId = message['winId'] as int? ?? -1;
          if (winId == NetHackScreen.nhwMessage || winId == 1) {
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
          setState(() {
            _askNameSaves = saves;
            _askNameMaxChars = message['maxChars'];
            _isAskNameVisible = true;
            _askNameController.text = saves.isNotEmpty ? saves[0] : "Player";
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
          );
        } else if (type == 'endMenu') {
          _screen.endMenu(message['winId'], message['prompt']);
        } else if (type == 'selectMenu') {
          _screen.selectMenu(message['winId'], message['how']);
          setState(() {
            _waitingForInput = true;
            _extCmdMenuFilter = "";
            _extCmdMenuFilterController.clear();
            _menuSelectedIds = _screen.menuItems
                .where((item) => item.ident != 0 && item.preselected != 0)
                .map((item) => item.ident)
                .toSet();
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

  void _sendModeAppliedDirection(String viKey, {bool useLongPressRun = false}) {
    if (useLongPressRun && !_isDirectionPromptActive) {
      _sendFfiKeys(['g'.codeUnitAt(0), viKey.codeUnitAt(0)], 'g$viKey');
      return;
    }

    if (_isDirectionPromptActive) {
      _sendFfiKey(viKey.codeUnitAt(0), viKey);
      _isDirectionPromptActive = false;
      return;
    }

    final baseKey = _numberPadMode != 0 ? _viToNumPad(viKey) : viKey;

    switch (_dPadMoveMode) {
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

    // メニュー表示中は、メニューショートカットキー判定を行う
    if (_screen.isMenuWindowVisible) {
      final isMultiSelectMenu = _screen.menuHow > 1;
      if (isMultiSelectMenu) {
        if (code == 27) {
          _sendMenuSelection(-1);
          return;
        }
        if (code == 10 || code == 13) {
          _sendMenuSelections(_menuSelectedIds.toList(growable: false));
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

    _addLog("> Send Keys: '${command}' (${keys.length} keys)");
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

    _addLog("> Send Shortcut: '${command}' (${keys.length} keys)");
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
            keys.add(0x0A);
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

  void _sendExtendedCommand(String cmd) {
    _addLog("> Send Extended Command: '$cmd'");
    _sendShortcutToC('$cmd\n');
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
  void _handleMapTap(TapUpDetails details) {
    if (!_isMainGameStarted) return;
    final px = _screen.playerX;
    final py = _screen.playerY;
    if (px < 0 || py < 0) return;

    final tile = _mapLocalToTile(details.localPosition);
    if (tile == null) return;

    // 主人公タイルでも隣接タイルでも、tap したタイル座標をそのまま送信する。
    // C コア側 click_to_cmd → dotherecmdmenu が u.ux/uy 一致で here_cmd_menu
    // を呼び分ける。
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

  void _sendMenuSelection(int ident) {
    if (!_waitingForInput || !_screen.isMenuWindowVisible) return;
    setState(() {
      _waitingForInput = false;
      _extCmdMenuFilter = "";
      _extCmdMenuFilterController.clear();
    });
    _addLog("> Menu Select: ID $ident");
    _workerSendPort?.send({
      'type': 'menu_select',
      'ident': ident,
    });
    _screen.clearMenu();
    _menuSelectedIds = <int>{};
  }

  void _sendMenuSelections(List<int> idents) {
    if (!_waitingForInput || !_screen.isMenuWindowVisible) return;
    setState(() {
      _waitingForInput = false;
      _extCmdMenuFilter = "";
      _extCmdMenuFilterController.clear();
    });
    _addLog("> Menu Selects: ${idents.length} item(s)");
    _workerSendPort?.send({
      'type': 'menu_selects',
      'idents': idents,
    });
    _screen.clearMenu();
    _menuSelectedIds = <int>{};
  }

  void _toggleMenuSelection(int ident) {
    if (ident == 0) return;
    setState(() {
      if (_menuSelectedIds.contains(ident)) {
        _menuSelectedIds.remove(ident);
      } else {
        _menuSelectedIds.add(ident);
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
    return !_isMenuDividerText(item.text);
  }

  Widget _buildMenuCategoryRow(String text) {
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
          const SizedBox(width: 6),
          Expanded(
            child: Text(
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
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelectable = item.ident != 0;
                        final isCategory = _isMenuCategoryItem(item);
                        final isDivider = !isSelectable && !isCategory;
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

                        final descIndent = " " * accLabel.length;

                        if (isMultiSelectMenu) {
                          final checked = _menuSelectedIds.contains(item.ident);
                          return Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                              value: checked,
                              onChanged: (_) => _toggleMenuSelection(item.ident),
                              activeColor: Colors.tealAccent[400],
                              checkColor: Colors.black,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                "$accLabel$commandText",
                                style: TextStyle(
                                  color: itemColor,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "$accLabel$commandText",
                                  style: TextStyle(
                                    color: itemColor,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isExtCmdMenu && descriptionText.isNotEmpty)
                                  Text(
                                    "$descIndent$descriptionText",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _sendMenuSelection(item.ident),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (isMultiSelectMenu) ...[
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _menuSelectedIds = filteredItems
                                .where((item) => item.ident != 0)
                                .map((item) => item.ident)
                                .toSet();
                          });
                        },
                        child: const Text("全て選択"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _menuSelectedIds.clear();
                          });
                        },
                        child: const Text("解除"),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendMenuSelections(_menuSelectedIds.toList(growable: false)),
                        child: const Text("OK"),
                      ),
                    ],
                    ElevatedButton(
                      onPressed: () => _sendMenuSelection(-1),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYnOverlay() {
    final choices = _ynChoices.split('');
    final isYesNo = _ynChoices.toLowerCase() == 'yn' || _ynChoices.toLowerCase() == 'ynq';

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
                            return ListTile(
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
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAskNameOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.84),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _askNameController,
                    autofocus: true,
                    maxLength: _askNameMaxChars,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0E1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (val) {
                      _sendAskNameResult(val);
                    },
                  ),
                  if (_askNameSaves.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("既存のセーブデータ:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withValues(alpha: 0.2),
                        ),
                        child: ListView.builder(
                          itemCount: _askNameSaves.length,
                          itemBuilder: (context, index) {
                            final name = _askNameSaves[index];
                            return ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              leading: const Icon(Icons.account_circle, color: Colors.lightBlueAccent),
                              dense: true,
                              onTap: () {
                                _askNameController.text = name;
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
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
    );
  }

  static const List<String> _fallbackExtCommands = [
    'adjust', 'annotate', 'apply', 'attributes', 'cast', 'chat', 'chronicle',
    'close', 'force', 'invoke', 'jump', 'loot', 'monster', 'name', 'offer',
    'open', 'overview', 'pay', 'pray', 'quaff', 'quit', 'read', 'rest',
    'ride', 'rub', 'search', 'sit', 'surrender', 'takeoff', 'teleport',
    'terrain', 'therecmdmenu', 'turn', 'untrap', 'version', 'wear', 'wield',
    'wipe'
  ];

  void _showShortcutEditDialog(int index) {
    if (_extCmdList.isEmpty) {
      _loadExtCmds();
    }

    final List<Map<String, String>> extCommands = [];
    if (_extCmdList.isNotEmpty) {
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
    } else {
      for (final cmd in _fallbackExtCommands) {
        var command = cmd;
        if (!command.startsWith('#') && !command.startsWith('?')) {
          command = '#$command';
        }
        extCommands.add({'command': command, 'description': ''});
      }
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
      final controller = TextEditingController(text: currentVal);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("${shortcutLabels[index]} を編集"),
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
                          itemCount: extCommands.length,
                          itemBuilder: (context, idx) {
                            final item = extCommands[idx];
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
                prefs.setString('shortcut_btn_$index', val).then((_) {
                  setState(() {
                    _controlsVersion++;
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("保存"),
            ),
          ],
        ),
      );
    });
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
      _loadPreferences();
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
                _statusDisplayMode == 0
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
                const Divider(color: Colors.white12, height: 1),
                // 2. メッセージ領域
                Container(
                  height: 54,
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _screen.messages.isEmpty
                        ? ""
                        : _screen.messages.sublist(
                            _screen.messages.length > 3 ? _screen.messages.length - 3 : 0
                          ).join("\n"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                // 3. マップ表示
                Expanded(
                  child: Container(
                    key: _mapViewportKey,
                    color: Colors.black,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(2000.0), // 十分なマージンを設けて枠外への無限移動（クランプ解除）を許可
                      constrained: false, // 子が親(画面幅)に制限されずunconstrainedでスクロール可能にする
                      maxScale: 6.0,
                      minScale: 0.5,
                      onInteractionUpdate: (details) {
                        // ユーザーがピンチズームしたズーム倍率をリアルタイムに保存
                        _currentScale = _transformationController.value.getMaxScaleOnAxis();
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
                            onTapUp: _handleMapTap,
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
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 18, color: Colors.amber[300]),
                              const SizedBox(width: 8),
                              const Text(
                                'テキスト表示',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: SingleChildScrollView(
                                child: Text(
                                  _screen.textLines.join('\n'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              "-- [Space] or [Enter] to continue --",
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
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

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Transform.scale(
        scale: _padScale,
        alignment: Alignment.bottomCenter,
        child: _controllerMode == ControllerMode.keyboard
            ? NetHackKeyboard(
                opacity: _padOpacity,
                onKeyPress: (key) => _sendKeysToC(key),
                onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
                onToggleMode: () {
                  setState(() {
                    _controllerMode = ControllerMode.pad;
                  });
                },
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ボタンモード (左端に D-Pad, 右端に 3x3 ショートカットパッド)
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NetHackDPad(
                          opacity: _padOpacity,
                          directionLabels: _buildDirectionLabels(),
                          centerLabel: _moveModeLabel(_dPadMoveMode),
                          onDirectionPress: (viKey) {
                            _sendModeAppliedDirection(viKey);
                          },
                          onDirectionLongPress: (viKey) {
                            _sendModeAppliedDirection(viKey, useLongPressRun: true);
                          },
                          onCenterTap: _cycleDPadMoveMode,
                          onCenterLongPress: () {
                            _showMoveModeSelectDialog();
                          },
                        ),
                        NetHackShortcutPad(key: ValueKey(_controlsVersion),
                          opacity: _padOpacity,
                          onKeyPress: (key) => _sendKeysToC(key),
                          onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
                          onShortcut: (cmd) => _sendShortcutToC(cmd),
                          onShortcutLongPress: (index) => _showShortcutEditDialog(index),
                        ),
                      ],
                    ),
                  ),
                  NetHackCmdPanel(key: ValueKey(_controlsVersion),
                    opacity: _padOpacity,
                    showPanelNames: _showPanelNames,
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
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
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
              Column(
                children: [
                  Expanded(
                    child: _isGameRunning
                        ? _buildGameScreen()
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Text(
                                 _logs.join('\n'),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ),
                  ),
                  if (!_isGameRunning)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: !_assetsReady
                          ? const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text("Preparing assets..."),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                  ElevatedButton(
                                  onPressed: _startGame,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Start NetHack Game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _showSettingsDialog,
                                  icon: const Icon(Icons.settings),
                                  label: const Text("ゲーム設定を開く"),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 45),
                                  ),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
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

  // NetHackカラーテーブル
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
