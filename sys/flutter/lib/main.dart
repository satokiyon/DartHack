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
import 'utils/defaults_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'amount_selector_dialog.dart';
import 'utils/scale_clamp.dart';
import 'dart:ffi' hide Size;
import 'dart:convert';
import 'package:ffi/ffi.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'widgets/exit_highlight_dialog.dart';

import 'models/game_enums.dart';
import 'models/ext_cmd_entry.dart';
import 'models/topten_entry.dart';
import 'widgets/topten_widget.dart';
import 'widgets/full_map_dialog.dart';
import 'widgets/msg_history_dialog.dart';
import 'widgets/shortcut_edit_dialog.dart';
import 'widgets/game_drawer.dart';
import 'widgets/overlays/menu_overlay.dart';
import 'widgets/overlays/yn_overlay.dart';
import 'widgets/overlays/getline_overlay.dart';
import 'widgets/overlays/askname_overlay.dart';
import 'widgets/overlays/text_overlay.dart';
import 'screens/start_screen.dart';
import 'screens/end_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
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
  int _tileWidth = 32;
  int _tileHeight = 32;
  String _selectedTileset = 'pixelhack_32x32';
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
  int _numberPadMode = 0;

  // 拡張コマンドサジェスト用
  List<ExtCmdEntry> _extCmdList = [];
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
  bool _showMapButton = true;
  String _mapButtonPosition = 'bottom_right';
  String _dpadPosition = 'bottom_left';
  String _shortcutPosition = 'bottom_right';
  String _msgPosition = 'top';
  int _msgCharWidth = 30;
  String _statusPosition = 'top';
  String _cmdPanelPosition = 'bottom';
  int _layoutPattern = 1; // UIレイアウトパターン (1 or 2)
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
  double _statusHeight = 38.0;
  double _statusWidth = 70.0;
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
    final newTileset = prefs.getString('selected_tileset') ?? 'pixelhack_32x32';
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
      _showMapButton = prefs.getBool('show_map_button') ?? true;
      _mapButtonPosition = prefs.getString('map_button_position') ?? 'bottom_right';
      _dpadPosition = prefs.getString('dpad_position') ?? 'bottom_left';
      _shortcutPosition = prefs.getString('shortcut_position') ?? 'bottom_right';
      _msgPosition = prefs.getString('msg_position') ?? 'top';
      _msgCharWidth = prefs.getInt('msg_char_width') ?? 30;
      _statusPosition = prefs.getString('status_position') ?? 'top';
      _cmdPanelPosition = prefs.getString('cmd_panel_position') ?? 'bottom';
      _layoutPattern = prefs.getInt('layout_pattern') ?? 1;
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
    return GameDrawerContent(
      isGameRunning: _isGameRunning,
      isKeyboardVisible: _isKeyboardVisible,
      onClose: _closeDrawer,
      onSaveAndExit: () => _sendFfiKey(83, "S"),
      onQuit: () => _sendShortcutToC("#quit\n"),
      onShowScoreboard: _showScoreboardDialog,
      onShowHelp: () => _sendFfiKey('?'.codeUnitAt(0), "?"),
      onDatabaseSearch: () {
        try {
          NetHackFfi().triggerDatabaseSearch();
        } catch (_) {
          _sendFfiKeys(['/'.codeUnitAt(0), '?'.codeUnitAt(0)], "/?");
        }
      },
      onOpenOptions: () => _sendFfiKey('O'.codeUnitAt(0), "O"),
      onShowFullMap: _showFullMapDialog,
      onToggleKeyboard: () {
        setState(() {
          _isKeyboardVisible = !_isKeyboardVisible;
        });
        if (!_isKeyboardVisible) {
          _focusNode.requestFocus();
        }
      },
      onShowSettings: _showSettingsDialog,
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
    return buildDrawerBarrier(isOpen: isOpen, onClose: onClose);
  }


  Widget _buildMenuButton() {
    double? top;
    double? bottom;
    double? left;
    double? right;

    final mediaQuery = MediaQuery.of(context);
    final statusTopShift = (_statusPosition == 'top') ? _statusHeight : 0.0;
    final statusBottomShift = (_statusPosition == 'bottom') ? _statusHeight : 0.0;
    final statusLeftShift = (_statusPosition == 'left') ? _statusWidth : 0.0;
    final statusRightShift = (_statusPosition == 'right') ? _statusWidth : 0.0;

    final cmdTopShift = (_cmdPanelPosition == 'top') ? (_cmdPanelHeight * _cmdPanelEffectiveScale) : 0.0;
    final cmdBottomShift = (_cmdPanelPosition == 'bottom') ? (_cmdPanelHeight * _cmdPanelEffectiveScale) : 0.0;
    final cmdLeftShift = (_cmdPanelPosition == 'left') ? (130.0 * _cmdPanelEffectiveScale) : 0.0;
    final cmdRightShift = (_cmdPanelPosition == 'right') ? (130.0 * _cmdPanelEffectiveScale) : 0.0;

    // SafeAreaのbottom（ナビゲーションバー等）
    final safeBottom = mediaQuery.padding.bottom;

    double dpadShift(String pos) => (_dpadPosition == pos) ? (150.0 * _dpadEffectiveScale + 8.0) : 0.0;
    double scShift(String pos) => (_shortcutPosition == pos) ? (150.0 * _shortcutPadEffectiveScale + 8.0) : 0.0;

    // メッセージ領域の高さ見積もり（フォントサイズ・行数+1行分・コンテナPadding・マージンから正確に算出）
    final estimatedMsgHeight = (_msgFontSize * 1.35 + 2.0) * (_msgLineCount + 1) + 14.0;

    // メッセージ領域が上部に配置されている場合のシフト量 (padTopPadding 6.0px を含む)
    double msgTopShift(String buttonCorner) {
      if (_msgPosition == 'top' || _msgPosition == buttonCorner) {
        return estimatedMsgHeight + 6.0;
      }
      return 0.0;
    }

    // メッセージ領域が下部に配置されている場合のシフト量 (メッセージ領域オフセット 12.0px を含む)
    double msgBottomShift(String buttonCorner) {
      if ((buttonCorner.startsWith('bottom') && _msgPosition == 'bottom') || _msgPosition == buttonCorner) {
        return estimatedMsgHeight + 12.0;
      }
      return 0.0;
    }

    switch (_menuButtonPosition) {
      case 'top_left':
        top = 8.0 + statusTopShift + cmdTopShift + dpadShift('top_left') + scShift('top_left')
            + msgTopShift('top_left');
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'top_right':
        top = 8.0 + statusTopShift + cmdTopShift + dpadShift('top_right') + scShift('top_right')
            + msgTopShift('top_right');
        right = 8.0 + statusRightShift + cmdRightShift;
        break;
      case 'left_edge':
        top = mediaQuery.size.height * 0.4;
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'right_edge':
        top = mediaQuery.size.height * 0.4;
        right = 8.0 + statusRightShift + cmdRightShift;
        break;
      case 'bottom_left':
        // _dialogBottomInset は使用しない（二重加算バグを防ぐため）
        // safeBottom + ステータス + コマンドパネル + 同コーナーのDPad/Shortcut + メッセージを積む
        bottom = 8.0 + safeBottom + statusBottomShift + cmdBottomShift
               + dpadShift('bottom_left') + scShift('bottom_left')
               + msgBottomShift('bottom_left');
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'bottom_right':
        bottom = 8.0 + safeBottom + statusBottomShift + cmdBottomShift
               + dpadShift('bottom_right') + scShift('bottom_right')
               + msgBottomShift('bottom_right');
        right = 8.0 + statusRightShift + cmdRightShift;
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

  Widget _buildMapButton() {
    if (!_showMapButton || !_isMainGameStarted || !_isGameRunning) {
      return const SizedBox.shrink();
    }

    double? top;
    double? bottom;
    double? left;
    double? right;

    final mediaQuery = MediaQuery.of(context);
    final statusTopShift = (_statusPosition == 'top') ? _statusHeight : 0.0;
    final statusBottomShift = (_statusPosition == 'bottom') ? _statusHeight : 0.0;
    final statusLeftShift = (_statusPosition == 'left') ? _statusWidth : 0.0;
    final statusRightShift = (_statusPosition == 'right') ? _statusWidth : 0.0;

    final cmdTopShift = (_cmdPanelPosition == 'top') ? (_cmdPanelHeight * _cmdPanelEffectiveScale) : 0.0;
    final cmdBottomShift = (_cmdPanelPosition == 'bottom') ? (_cmdPanelHeight * _cmdPanelEffectiveScale) : 0.0;
    final cmdLeftShift = (_cmdPanelPosition == 'left') ? (130.0 * _cmdPanelEffectiveScale) : 0.0;
    final cmdRightShift = (_cmdPanelPosition == 'right') ? (130.0 * _cmdPanelEffectiveScale) : 0.0;

    // SafeAreaのbottom（ナビゲーションバー等）
    final safeBottom = mediaQuery.padding.bottom;

    double dpadShift(String pos) => (_dpadPosition == pos) ? (150.0 * _dpadEffectiveScale + 8.0) : 0.0;
    double scShift(String pos) => (_shortcutPosition == pos) ? (150.0 * _shortcutPadEffectiveScale + 8.0) : 0.0;
    // メニューボタンが同じコーナーにある場合のみシフト
    double menuShift(String pos) => (_menuButtonPosition == pos) ? 48.0 : 0.0;

    // メッセージ領域の高さ見積もり（フォントサイズ・行数+1行分・コンテナPadding・マージンから正確に算出）
    final estimatedMsgHeight = (_msgFontSize * 1.35 + 2.0) * (_msgLineCount + 1) + 14.0;

    // メッセージ領域が上部に配置されている場合のシフト量 (padTopPadding 6.0px を含む)
    double msgTopShift(String buttonCorner) {
      if (_msgPosition == 'top' || _msgPosition == buttonCorner) {
        return estimatedMsgHeight + 6.0;
      }
      return 0.0;
    }

    // メッセージ領域が下部に配置されている場合のシフト量 (メッセージ領域オフセット 12.0px を含む)
    double msgBottomShift(String buttonCorner) {
      if ((buttonCorner.startsWith('bottom') && _msgPosition == 'bottom') || _msgPosition == buttonCorner) {
        return estimatedMsgHeight + 12.0;
      }
      return 0.0;
    }

    switch (_mapButtonPosition) {
      case 'top_left':
        top = 8.0 + statusTopShift + cmdTopShift + dpadShift('top_left') + scShift('top_left')
            + msgTopShift('top_left') + menuShift('top_left');
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'top_right':
        top = 8.0 + statusTopShift + cmdTopShift + dpadShift('top_right') + scShift('top_right')
            + msgTopShift('top_right') + menuShift('top_right');
        right = 8.0 + statusRightShift + cmdRightShift;
        break;
      case 'left_edge':
        top = mediaQuery.size.height * 0.4 + menuShift('left_edge');
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'right_edge':
        top = mediaQuery.size.height * 0.4 + menuShift('right_edge');
        right = 8.0 + statusRightShift + cmdRightShift;
        break;
      case 'bottom_left':
        // _dialogBottomInset は使用しない（二重加算バグを防ぐため）
        bottom = 8.0 + safeBottom + statusBottomShift + cmdBottomShift
               + dpadShift('bottom_left') + scShift('bottom_left')
               + msgBottomShift('bottom_left') + menuShift('bottom_left');
        left = 8.0 + statusLeftShift + cmdLeftShift;
        break;
      case 'bottom_right':
        bottom = 8.0 + safeBottom + statusBottomShift + cmdBottomShift
               + dpadShift('bottom_right') + scShift('bottom_right')
               + msgBottomShift('bottom_right') + menuShift('bottom_right');
        right = 8.0 + statusRightShift + cmdRightShift;
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
                tooltip: '階層全体地図',
                icon: const Icon(Icons.map, color: Colors.white, size: 20),
                onPressed: _showFullMapDialog,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullMapDialog() {
    showFullMapDialog(
      context: context,
      screen: _screen,
      useTiles: _useTiles,
      tileImage: _tileImage,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
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
        tileWidth: _tileWidth,
        tileHeight: _tileHeight,
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

    // コントローラの遮りを考慮し、視覚的中心に主人公が来るよう調整
    // パターン1（下部コントローラ等）: 上から40% (0.40)
    // パターン2（上部コントローラ等）: 上から60% (0.60)
    final double yRatio = (_layoutPattern == 2 || _dpadPosition.startsWith('top')) ? 0.60 : 0.40;
    final tx = (viewportSize.width / 2) - (playerX * _currentScale);
    final ty = (viewportSize.height * yRatio) - (playerY * _currentScale);

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
      String? currentBuildId;
      try {
        final ffi = NetHackFfi();
        currentBuildId = ffi.getBuildId();
      } catch (e) {
        debugPrint("Ffi buildId lookup: $e");
      }

      final dstDir = await NetHackAssets.initialize(currentBuildId: currentBuildId);
      setState(() {
        _assetsPath = dstDir.path;
        _assetsReady = true;
      });
      _addLog("Assets initialized at: $_assetsPath (Build ID: ${currentBuildId ?? 'unknown'})");

      final defaultsHelper = DefaultsHelper();
      await defaultsHelper.syncFromPrefsToFile('$_assetsPath/defaults.nh');
      await defaultsHelper.syncFromFileToPrefs('$_assetsPath/defaults.nh');

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
      int width = 32;
      int height = 32;
      final match = RegExp(r'(\d+)x(\d+)').firstMatch(tilesetName);
      if (match != null) {
        width = int.parse(match.group(1)!);
        height = int.parse(match.group(2)!);
      }
      final img = await _loadTileImageFromAsset('assets/tiles/$tilesetName.png');
      setState(() {
        _tileImage = img;
        _tileWidth = width;
        _tileHeight = height;
        _selectedTileset = tilesetName;
      });
      _addLog("Tileset loaded successfully: $tilesetName (${width}x$height)");
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
        return ExitHighlightDialog(
          dialogMessage: dialogMessage,
          messageHistory: List<String>.from(_screen.messageHistory),
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
            _askNameController.text = defaultName;
          });
        } else if (type == 'number_pad_mode') {
          final state = message['state'] as int? ?? 0;
          setState(() {
            _numberPadMode = state;
            if (_numberPadMode > 0 &&
                (_dPadMoveMode == DPadMoveMode.upper ||
                    _dPadMoveMode == DPadMoveMode.ctrl)) {
              _dPadMoveMode = DPadMoveMode.normal;
              unawaited(_saveDPadModePrefs());
            }
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
    if (_numberPadMode == 3 || _numberPadMode == 4) {
      // 電話配列 (phone keypad layout: 12346789)
      switch (viKey) {
        case 'y':
          return '1';
        case 'k':
          return '2';
        case 'u':
          return '3';
        case 'h':
          return '4';
        case 'l':
          return '6';
        case 'b':
          return '7';
        case 'j':
          return '8';
        case 'n':
          return '9';
        default:
          return viKey;
      }
    } else if (_numberPadMode == -1) {
      // ドイツ語 QWERTZ 配列 (y <-> z)
      switch (viKey) {
        case 'y':
          return 'z';
        default:
          return viKey;
      }
    } else if (_numberPadMode != 0) {
      // 標準テンキー (1, 2)
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
    return viKey;
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
    final baseDir = _viToNumPad(viKey);
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
    List<DPadMoveMode> modes = _enabledDPadMoveModes.isEmpty
        ? <DPadMoveMode>[DPadMoveMode.normal]
        : List<DPadMoveMode>.from(_enabledDPadMoveModes);
    if (_numberPadMode > 0) {
      modes.remove(DPadMoveMode.upper);
      modes.remove(DPadMoveMode.ctrl);
      if (modes.isEmpty) {
        modes = <DPadMoveMode>[DPadMoveMode.normal];
      }
    }
    final currentIdx = modes.indexOf(_dPadMoveMode);
    final nextIdx = (currentIdx < 0) ? 0 : (currentIdx + 1) % modes.length;
    setState(() {
      _dPadMoveMode = modes[nextIdx];
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
      final baseKey = _viToNumPad(viKey);
      _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
      _isDirectionPromptActive = false;
      return;
    }

    final mode = modeOverride ?? _dPadMoveMode;
    final baseKey = _viToNumPad(viKey);

    switch (mode) {
      case DPadMoveMode.normal:
        _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
        break;
      case DPadMoveMode.upper:
        if (_numberPadMode > 0) {
          _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
        } else {
          final key = baseKey.toUpperCase();
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
        if (_numberPadMode > 0) {
          _sendFfiKey(baseKey.codeUnitAt(0), baseKey);
        } else {
          _sendFfiKey(_ctrlFromVi(baseKey), '^$baseKey');
        }
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



  Widget _buildMenuOverlay() {
    return MenuOverlay(
      menuPrompt: _screen.menuPrompt,
      menuItems: _screen.menuItems,
      menuHow: _screen.menuHow,
      initialSelectedCounts: _menuSelectedCounts,
      initialSearchQuery: _extCmdMenuFilter,
      onSingleSelect: (ident) => _sendMenuSelection(ident),
      onMultiSelect: (counts) => _sendMenuSelections(counts),
      onItemLongPress: (item) => _onMenuItemLongPress(item),
      bottomInset: _dialogBottomInset(context),
      useTiles: _useTiles,
      tileImage: _tileImage,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
    );
  }

  Widget _buildYnOverlay() {
    return YnOverlay(
      question: _ynQuestion,
      choices: _ynChoices,
      defaultChoice: _ynDefault,
      onSelect: (choiceCode) => _sendYnResult(choiceCode),
      onShowMsgHistory: _showMsgHistoryPanel,
      bottomInset: _dialogBottomInset(context),
    );
  }

  Widget _buildGetLineOverlay() {
    return GetLineOverlay(
      prompt: _getlinePrompt,
      inputController: _getlineController,
      extCmdList: _extCmdList,
      onSubmit: (result) => _sendGetLineResult(result),
      onShowMsgHistory: _showMsgHistoryPanel,
      bottomInset: _dialogBottomInset(context),
      isCallOrNamePrompt: isCallOrNamePrompt,
    );
  }

  Widget _buildAskNameOverlay() {
    return AskNameOverlay(
      nameController: _askNameController,
      maxChars: _askNameMaxChars,
      saves: _askNameSaves,
      initialPlayMode: _selectedPlayMode,
      onSubmit: (mode, name) {
        _selectedPlayMode = mode;
        _sendAskNameResult(name);
      },
      bottomInset: _dialogBottomInset(context),
    );
  }

  void _showShortcutEditDialog(int index) {
    _loadExtCmds();
    showShortcutEditDialog(
      context: context,
      index: index,
      extCmdList: _extCmdList,
      onSaved: () {
        if (mounted) {
          setState(() {
            _controlsVersion++;
          });
        }
      },
    );
  }

  void _showMsgHistoryPanel() {
    if (!mounted) return;
    showMsgHistoryPanel(
      context: context,
      messages: List<String>.from(_screen.messageHistory),
      msgFontSize: _msgFontSize,
    );
  }



  Widget _buildGameScreen() {
    return ListenableBuilder(
      listenable: _screen,
      builder: (context, _) {
        final mapWidget = Container(
          key: _mapViewportKey,
          color: Colors.black,
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(2000.0),
            constrained: false,
            maxScale: 6.0,
            minScale: 0.5,
            onInteractionStart: (details) {
              _isMapScrolledOrZoomed = true;
            },
            onInteractionUpdate: (details) {
              _currentScale = _transformationController.value.getMaxScaleOnAxis();
              _isMapScrolledOrZoomed = true;
            },
            child: Center(
              child: SizedBox(
                width: 4000.0,
                height: 3000.0,
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
                      tileWidth: _tileWidth,
                      tileHeight: _tileHeight,
                      useTiles: _useTiles,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final horizontalStatusWidget = LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box != null && box.hasSize) {
                  final h = box.size.height;
                  if ((_statusHeight - h).abs() > 0.5) {
                    setState(() => _statusHeight = h);
                  }
                }
              }
            });
            return GestureDetector(
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
            );
          },
        );

        if (_statusPosition == 'left') {
          return Row(
            children: [
              _buildVerticalStatusPanel(false),
              Expanded(child: mapWidget),
            ],
          );
        } else if (_statusPosition == 'right') {
          return Row(
            children: [
              Expanded(child: mapWidget),
              _buildVerticalStatusPanel(true),
            ],
          );
        } else if (_statusPosition == 'bottom') {
          return Column(
            children: [
              Expanded(child: mapWidget),
              horizontalStatusWidget,
            ],
          );
        }

        return Column(
          children: [
            horizontalStatusWidget,
            Expanded(child: mapWidget),
          ],
        );
      },
    );
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
      final recordPath = findRecordFilePath();
      if (recordPath != null) {
        entries = parseRecordFile(recordPath);
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

  Widget _buildVerticalStatusPanel(bool isRight) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              final w = box.size.width;
              if ((_statusWidth - w).abs() > 0.5) {
                setState(() => _statusWidth = w);
              }
            }
          }
        });

        final statusText = _screen.statusLines.join('\n');
        final lines = statusText.split(RegExp(r'[\n\r]+')).expand((l) {
          // 1行に複数項目がスペース区切りで入っている場合、適度に改行に分割する
          final parts = l.split(RegExp(r'\s{2,}')).where((p) => p.trim().isNotEmpty);
          return parts.isEmpty ? [l] : parts;
        }).toList();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isGameRunning && _isMainGameStarted && _waitingForInput
              ? () => _sendShortcutToC('#attributes\n')
              : null,
          child: Container(
            width: 115.0,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.85),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            alignment: isRight ? Alignment.topRight : Alignment.topLeft,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Text.rich(_parseStatusLine(line)),
                  );
                }).toList(),
              ),
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

  Widget _buildTextOverlay() {
    return TextOverlay(
      textLines: _screen.textLines,
      textAttrs: _screen.textAttrs,
      textTiles: _screen.textTiles,
      isPlainDialog: _screen.isPlainDialog,
      tombstoneDisplayMode: _tombstoneDisplayMode,
      onDismiss: () => _sendFfiKey(32, "Space"),
      onShowMsgHistory: _showMsgHistoryPanel,
      bottomInset: _dialogBottomInset(context),
      useTiles: _useTiles,
      tileImage: _tileImage,
      tileWidth: _tileWidth,
      tileHeight: _tileHeight,
    );
  }

  Widget _buildMessageWidget() {
    return ListenableBuilder(
      listenable: _screen,
      builder: (context, _) {
        final displayedLines = List<String>.from(
          _screen.messageHistory.sublist(
            _screen.messageHistory.length > _msgLineCount
                ? _screen.messageHistory.length - _msgLineCount
                : 0,
          ),
        );
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

        if (displayedLines.isEmpty) return const SizedBox.shrink();

        final screenWidth = MediaQuery.of(context).size.width;
        final double? targetWidth = (_msgPosition == 'bottom' || _msgPosition == 'top')
            ? null
            : (screenWidth * (_msgCharWidth / 60.0)).clamp(180.0, screenWidth - 16.0);

        return Container(
          width: targetWidth,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _msgOpacity),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
  Alignment _getAlignment(String position) {
    switch (position) {
      case 'top_left':
        return Alignment.topLeft;
      case 'top_right':
        return Alignment.topRight;
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottom_right':
        return Alignment.bottomRight;
      default:
        return Alignment.bottomLeft;
    }
  }

  Widget _buildControllerOverlay() {
    if (!_shouldShowController) {
      return const SizedBox.shrink();
    }

    final statusTopOffset = (_statusPosition == 'top') ? _statusHeight : 0.0;
    final statusBottomOffset = (_statusPosition == 'bottom') ? _statusHeight : 0.0;
    final statusLeftOffset = (_statusPosition == 'left') ? _statusWidth : 0.0;
    final statusRightOffset = (_statusPosition == 'right') ? _statusWidth : 0.0;

    final cmdPanelScaledHeight = _cmdPanelHeight * _cmdPanelEffectiveScale;
    final cmdPanelScaledWidth = 130.0 * _cmdPanelEffectiveScale;
    const padTopPadding = 6.0;
    const sideMargin = 8.0;

    // オフセット算出用
    double cmdPanelTopOffset = 0.0;
    double cmdPanelLeftOffset = 0.0;
    double cmdPanelRightOffset = 0.0;

    if (_cmdPanelPosition == 'top') {
      cmdPanelTopOffset = cmdPanelScaledHeight;
    } else if (_cmdPanelPosition == 'left') {
      cmdPanelLeftOffset = cmdPanelScaledWidth;
    } else if (_cmdPanelPosition == 'right') {
      cmdPanelRightOffset = cmdPanelScaledWidth;
    }

    // DPad オフセット計算
    double? dpadTop, dpadBottom, dpadLeft, dpadRight;
    if (_dpadPosition.startsWith('top')) {
      dpadTop = statusTopOffset + padTopPadding + (_cmdPanelPosition == 'top' ? cmdPanelTopOffset : 0.0);
    } else {
      dpadBottom = statusBottomOffset + padTopPadding + (_cmdPanelPosition == 'bottom' ? cmdPanelScaledHeight : 0.0);
    }

    if (_dpadPosition.endsWith('left')) {
      dpadLeft = statusLeftOffset + sideMargin + (_cmdPanelPosition == 'left' ? cmdPanelLeftOffset : 0.0);
    } else {
      dpadRight = statusRightOffset + sideMargin + (_cmdPanelPosition == 'right' ? cmdPanelRightOffset : 0.0);
    }

    // ShortcutPad オフセット計算
    double? scTop, scBottom, scLeft, scRight;
    bool sameAsDpad = _shortcutPosition == _dpadPosition;
    double dpadSizeShift = sameAsDpad ? (150.0 * _dpadEffectiveScale + 12.0) : 0.0;

    if (_shortcutPosition.startsWith('top')) {
      scTop = statusTopOffset + padTopPadding + (_cmdPanelPosition == 'top' ? cmdPanelTopOffset : 0.0) + (sameAsDpad && _dpadPosition.startsWith('top') ? dpadSizeShift : 0.0);
    } else {
      scBottom = statusBottomOffset + padTopPadding + (_cmdPanelPosition == 'bottom' ? cmdPanelScaledHeight : 0.0) + (sameAsDpad && _dpadPosition.startsWith('bottom') ? dpadSizeShift : 0.0);
    }

    if (_shortcutPosition.endsWith('left')) {
      scLeft = statusLeftOffset + sideMargin + (_cmdPanelPosition == 'left' ? cmdPanelLeftOffset : 0.0);
    } else {
      scRight = statusRightOffset + sideMargin + (_cmdPanelPosition == 'right' ? cmdPanelRightOffset : 0.0);
    }

    // メッセージ領域 オフセット計算
    double? msgTop, msgBottom, msgLeft, msgRight;
    if (_msgPosition == 'bottom') {
      msgBottom = statusBottomOffset + (_cmdPanelPosition == 'bottom' ? cmdPanelScaledHeight : 0.0) +
          (_dpadPosition.startsWith('bottom') ? (150.0 * _dpadEffectiveScale) : 0.0) + 12.0;
      msgLeft = statusLeftOffset;
      msgRight = statusRightOffset;
    } else if (_msgPosition == 'top') {
      msgTop = statusTopOffset + padTopPadding + (_cmdPanelPosition == 'top' ? cmdPanelTopOffset : 0.0);
      msgLeft = statusLeftOffset;
      msgRight = statusRightOffset;
    } else {
      if (_msgPosition.startsWith('top')) {
        msgTop = statusTopOffset + padTopPadding + (_cmdPanelPosition == 'top' ? cmdPanelTopOffset : 0.0);
      } else {
        msgBottom = statusBottomOffset + padTopPadding + (_cmdPanelPosition == 'bottom' ? cmdPanelScaledHeight : 0.0);
      }

      if (_msgPosition.endsWith('left')) {
        msgLeft = statusLeftOffset + sideMargin + (_cmdPanelPosition == 'left' ? cmdPanelLeftOffset : 0.0);
      } else {
        msgRight = statusRightOffset + sideMargin + (_cmdPanelPosition == 'right' ? cmdPanelRightOffset : 0.0);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. コマンドパネル (常時表示)
        Positioned(
          left: _cmdPanelPosition == 'right' ? null : statusLeftOffset,
          right: _cmdPanelPosition == 'left' ? null : statusRightOffset,
          top: _cmdPanelPosition == 'top'
              ? statusTopOffset
              : (_cmdPanelPosition == 'left' || _cmdPanelPosition == 'right' ? statusTopOffset : null),
          bottom: _cmdPanelPosition == 'bottom'
              ? statusBottomOffset
              : (_cmdPanelPosition == 'left' || _cmdPanelPosition == 'right' ? statusBottomOffset : null),
          child: Transform.scale(
            scale: _cmdPanelEffectiveScale,
            alignment: _cmdPanelPosition == 'top'
                ? Alignment.topCenter
                : (_cmdPanelPosition == 'bottom'
                    ? Alignment.bottomCenter
                    : (_cmdPanelPosition == 'left' ? Alignment.centerLeft : Alignment.centerRight)),
            child: NetHackCmdPanel(
              key: ValueKey(_controlsVersion),
              opacity: _padOpacity,
              showPanelNames: _showPanelNames,
              position: _cmdPanelPosition,
              isVertical: _cmdPanelPosition == 'left' || _cmdPanelPosition == 'right',
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
                  _controllerMode = _controllerMode == ControllerMode.keyboard
                      ? ControllerMode.pad
                      : ControllerMode.keyboard;
                });
              },
            ),
          ),
        ),
        // 2. キーボード (キーボードモード時のみ)
        if (_controllerMode == ControllerMode.keyboard) ...[
          Positioned(
            left: 0,
            right: 0,
            top: _cmdPanelPosition == 'top'
                ? (statusTopOffset + cmdPanelScaledHeight)
                : null,
            bottom: _cmdPanelPosition != 'top'
                ? (statusBottomOffset + cmdPanelScaledHeight)
                : null,
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
          ),
        ],
        // 3. 移動パッド (DPad) (パッドモード時のみ)
        if (_controllerMode != ControllerMode.keyboard) ...[
          Positioned(
            top: dpadTop,
            bottom: dpadBottom,
            left: dpadLeft,
            right: dpadRight,
            child: Padding(
              padding: const EdgeInsets.only(top: padTopPadding),
              child: Transform.scale(
                scale: _dpadEffectiveScale,
                alignment: _getAlignment(_dpadPosition),
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
          // 4. ショートカットパッド (パッドモード時のみ)
          Positioned(
            top: scTop,
            bottom: scBottom,
            left: scLeft,
            right: scRight,
            child: Padding(
              padding: const EdgeInsets.only(top: padTopPadding),
              child: Transform.scale(
                scale: _shortcutPadEffectiveScale,
                alignment: _getAlignment(_shortcutPosition),
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
        // 5. メッセージ領域
        Positioned(
          top: msgTop,
          bottom: msgBottom,
          left: msgLeft,
          right: msgRight,
          child: _buildMessageWidget(),
        ),
      ],
    );
  }

  Widget _buildStartScreen() {
    return StartScreen(
      assetsReady: _assetsReady,
      onStartGame: _startGame,
      onShowSettings: _showSettingsDialog,
    );
  }

  Widget _buildEndScreen() {
    return const EndScreen();
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
                _buildMapButton(),
                _buildDrawerBarrier(_isTopDrawerOpen, () => setState(() => _isTopDrawerOpen = false)),
                _buildDrawerBarrier(_isBottomDrawerOpen, () => setState(() => _isBottomDrawerOpen = false)),
                _buildTopDrawer(),
                _buildBottomDrawer(),
              ],
              // ★ダイアログ・メニュー・テキストオーバーレイ（最前面・ゲーム全フェーズで描画可能）
              if (_screen.isMenuWindowVisible) _buildMenuOverlay(),
              if (_isYnVisible) _buildYnOverlay(),
              if (_isGetLineVisible) _buildGetLineOverlay(),
              if (_isAskNameVisible) _buildAskNameOverlay(),
              if (_screen.isTextWindowVisible) _buildTextOverlay(),
            ],
          ),
        ),
      ),
    ),
  );
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




