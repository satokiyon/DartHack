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

  // 拡張コマンドサジェスト用
  List<ExtCmdEntry> _extCmdList = [];
  List<ExtCmdEntry> _filteredExtCmds = [];
  final TextEditingController _extCmdFilterController = TextEditingController();
  final TextEditingController _extCmdMenuFilterController = TextEditingController();
  String _extCmdMenuFilter = "";

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
    setState(() {
      _useTiles = prefs.getBool('use_tiles') ?? true;
      _selectedTileset = prefs.getString('selected_tileset') ?? 'nevanda_32x32';
      _isKeyboardVisible = prefs.getBool('keyboard_visible') ?? true;
      final controllerModeStr = prefs.getString('controller_mode') ?? 'pad';
      _controllerMode = controllerModeStr == 'keyboard' ? ControllerMode.keyboard : ControllerMode.pad;
      _padOpacity = prefs.getDouble('pad_opacity') ?? 0.8;
      _padScale = prefs.getDouble('pad_scale') ?? 1.0;
      _autoSaveInterval = prefs.getInt('auto_save_interval') ?? 0;
      _statusDisplayMode = prefs.getInt('status_display_mode') ?? 0;
      _drawerPosition = prefs.getString('drawer_position') ?? 'left';
      _menuButtonPosition = prefs.getString('menu_button_position') ?? 'top_left';

      // 物理キーのロード
      _volupAction = prefs.getInt('key_volup_action') ?? 0;
      _voldownAction = prefs.getInt('key_voldown_action') ?? 0;
      _backAction = prefs.getInt('key_back_action') ?? 0;

      // コントロールのバージョンを更新
      _controlsVersion++;
    });
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

  double _controllerReservedHeight() {
    final controllerVisible = _isGameRunning && _isKeyboardVisible && _waitingForInput;
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
    return normalized.contains('セーブ中')
        || normalized.toLowerCase().contains('saving');
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
          if (_isSaveInProgressMessage(text)) {
            _autoAdvanceSavePending = true;
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
        } else if (type == 'request_input') {
          setState(() {
            _waitingForInput = true;
          });
          if (_autoAdvanceSavePending && !_screen.isMenuWindowVisible && !_isYnVisible && !_isGetLineVisible && !_isAskNameVisible) {
            _autoAdvanceSavePending = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _waitingForInput) {
                _sendFfiKey(32, 'Space(auto)');
              }
            });
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

  void _sendFfiKey(int code, String label) {
    if (!_waitingForInput) return;

    // メニュー表示中は、メニューショートカットキー判定を行う
    if (_screen.isMenuWindowVisible) {
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
  }

  Widget _buildMenuOverlay() {
    final isExtCmdMenu = _screen.menuPrompt.contains("拡張コマンド");
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
        color: Colors.black.withValues(alpha: 0.95),
        padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_screen.menuPrompt.isNotEmpty) ...[
              Text(
                _screen.menuPrompt,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                  fillColor: Colors.grey[900],
                  border: const OutlineInputBorder(),
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
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final isSelectable = item.ident != 0;
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

                  // defaults.nhのmenucolors色を反映
                  Color itemColor = isSelectable ? Colors.white : Colors.grey;
                  if (!isExtCmdMenu && item.color >= 0 && item.color < 16) {
                    itemColor = _getNhColor(item.color);
                  }

                  final descIndent = " " * accLabel.length;

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
                              fontWeight: isSelectable ? FontWeight.bold : FontWeight.normal,
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
                      onTap: isSelectable
                          ? () => _sendMenuSelection(item.ident)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _sendMenuSelection(-1),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYnOverlay() {
    final choices = _ynChoices.split('');
    final isYesNo = _ynChoices.toLowerCase() == 'yn' || _ynChoices.toLowerCase() == 'ynq';

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              color: Colors.grey[900],
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _ynQuestion,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                              backgroundColor: (_ynDefault == 'y'.codeUnitAt(0)) ? Colors.deepPurple : Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                          ElevatedButton(
                            onPressed: () => _sendYnResult('n'.codeUnitAt(0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_ynDefault == 'n'.codeUnitAt(0)) ? Colors.deepPurple : Colors.grey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                          if (_ynChoices.toLowerCase().contains('q'))
                            ElevatedButton(
                              onPressed: () => _sendYnResult('q'.codeUnitAt(0)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_ynDefault == 'q'.codeUnitAt(0)) ? Colors.deepPurple : Colors.grey[800],
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
                                backgroundColor: isDefault ? Colors.deepPurple : Colors.grey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(ch),
                            );
                          }),
                          ElevatedButton(
                            onPressed: () => _sendYnResult(27), // ESC
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.grey),
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
        color: Colors.black87,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              color: Colors.grey[950],
              elevation: 12,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    _getlinePrompt,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _getlineController,
                    autofocus: true,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: 'テキストを入力してください',
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: const OutlineInputBorder(),
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
                        fillColor: Colors.grey[900],
                        border: const OutlineInputBorder(),
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
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(4),
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
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
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
        color: Colors.black87,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              color: Colors.grey[950],
              elevation: 12,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const Text(
                    "お名前は？",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _askNameController,
                    autofocus: true,
                    maxLength: _askNameMaxChars,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: const OutlineInputBorder(),
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
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          itemCount: _askNameSaves.length,
                          itemBuilder: (context, index) {
                            final name = _askNameSaves[index];
                            return ListTile(
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              leading: const Icon(Icons.account_circle, color: Colors.deepPurpleAccent),
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
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
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
              ],
            ),
            // テキスト/ヘルプウィンドウのオーバーレイ表示
            if (_screen.isTextWindowVisible)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, _dialogBottomInset(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                            backgroundColor: Colors.deepPurple[900],
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
    if (!_isGameRunning || !_isKeyboardVisible || !_waitingForInput) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Opacity(
        opacity: _padOpacity,
        child: Transform.scale(
          scale: _padScale,
          alignment: Alignment.bottomCenter,
          child: _controllerMode == ControllerMode.keyboard
              ? NetHackKeyboard(
                  onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
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
                      color: Colors.grey[950],
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NetHackDPad(
                            onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
                          ),
                          NetHackShortcutPad(key: ValueKey(_controlsVersion),
                            onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
                            onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
                          ),
                        ],
                      ),
                    ),
                    NetHackCmdPanel(key: ValueKey(_controlsVersion),
                      onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
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
