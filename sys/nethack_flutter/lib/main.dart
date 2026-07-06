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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> _logs = [];
  final FocusNode _focusNode = FocusNode();
  final NetHackScreen _screen = NetHackScreen();
  
  SendPort? _workerSendPort;
  bool _isGameRunning = false;
  bool _waitingForInput = false;
  bool _assetsReady = false;
  String _assetsPath = '';

  // タイルセット用変数
  ui.Image? _tileImage;
  bool _useTiles = true; // デフォルトでタイル表示を有効化
  int _tileSize = 32;
  String _selectedTileset = 'nevanda_32x32';
  bool _isKeyboardVisible = true; // デフォルトで仮想キーボードを表示

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isGameRunning && _waitingForInput && !_isKeyboardVisible) {
        _focusNode.requestFocus();
      }
    });
    _initAssets();
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
      // タイル画像のロード
      await _loadTileset(_selectedTileset);
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

  Future<void> _startGame() async {
    if (_isGameRunning) return;

    setState(() {
      _logs.clear();
      _isGameRunning = true;
      _waitingForInput = false;
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
        } else if (type == 'clearWindow') {
          _screen.clearWindow(message['winId']);
        } else if (type == 'displayWindow') {
          // C側の blocking に基づく
        } else if (type == 'destroyWindow') {
          _screen.destroyWindow(message['winId']);
        } else if (type == 'curs') {
          _screen.setCursor(message['winId'], message['x'], message['y']);
        } else if (type == 'putstr') {
          _screen.putString(message['winId'], message['attr'], message['text']);
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
          if (!_isKeyboardVisible) {
            _focusNode.requestFocus();
          }
        } else if (type == 'startMenu') {
          _screen.startMenu(message['winId']);
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
          });
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
    });
    _addLog("> Menu Select: ID $ident");
    _workerSendPort?.send({
      'type': 'menu_select',
      'ident': ident,
    });
    _screen.clearMenu();
  }

  Widget _buildMenuOverlay() {
    // 拡張コマンド選択のメタコマンド（#や?など）をフィルタリングして除外する（開発制約 9）
    final filteredItems = _screen.menuItems.where((item) {
      final text = item.text.trim();
      return !text.startsWith('#') && !text.startsWith('?');
    }).toList();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(16),
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
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final isSelectable = item.ident != 0;
                  final accLabel = item.accelerator != 0 
                      ? "${String.fromCharCode(item.accelerator)} - " 
                      : "";

                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      title: Text(
                        "$accLabel${item.text}",
                        style: TextStyle(
                          color: isSelectable ? Colors.white : Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: isSelectable ? FontWeight.bold : FontWeight.normal,
                        ),
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

  Widget _buildGameScreen() {
    return ListenableBuilder(
      listenable: _screen,
      builder: (context, _) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. メッセージ領域
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
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: InteractiveViewer(
                      constrained: false, // 子が親(画面幅)に制限されずunconstrainedでスクロール可能にする
                      maxScale: 6.0,
                      minScale: 0.5,
                      child: Center(
                        child: SizedBox(
                          width: 80 * (_useTiles ? 16.0 : 9.0),
                          height: 21 * 16.0,
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
                const Divider(color: Colors.white12, height: 1),
                // 3. ステータス領域
                Container(
                  height: 38,
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _screen.statusLines.join("\n"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            // 移動用の半透明 D-Pad (入力待ちでメニュー等がない場合のみ表示)
            if (_isGameRunning && _waitingForInput && !_screen.isMenuWindowVisible && !_screen.isTextWindowVisible)
              Positioned(
                right: 12,
                bottom: 12,
                child: NetHackDPad(
                  onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
                ),
              ),
            // テキスト/ヘルプウィンドウのオーバーレイ表示
            if (_screen.isTextWindowVisible)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.95),
                  padding: const EdgeInsets.all(16),
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
                    ],
                  ),
                ),
              ),
            // メニュー選択ウィンドウのオーバーレイ表示
            if (_screen.isMenuWindowVisible)
              _buildMenuOverlay(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetHackJP Flutter'),
        actions: [
          if (_isGameRunning) ...[
            // タイルとASCIIの切り替えトグル
            IconButton(
              icon: Icon(_useTiles ? Icons.grid_view : Icons.text_fields),
              tooltip: _useTiles ? 'Switch to ASCII Map' : 'Switch to Tile Map',
              onPressed: () {
                setState(() {
                  _useTiles = !_useTiles;
                });
              },
            ),
            // タイルセット選択メニュー
            if (_useTiles)
              PopupMenuButton<String>(
                icon: const Icon(Icons.palette),
                onSelected: _loadTileset,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'nevanda_32x32', child: Text('Nevanda (32x32)')),
                  const PopupMenuItem(value: 'pixelhack_32x32', child: Text('PixelHack (32x32)')),
                  const PopupMenuItem(value: 'default_16x16', child: Text('Default (16x16)')),
                  const PopupMenuItem(value: 'geoduck_15x25', child: Text('Geoduck (15x25)')),
                ],
              ),
            // 仮想キーボード表示切り替え
            IconButton(
              icon: Icon(_isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard),
              tooltip: _isKeyboardVisible ? 'Hide Keyboard' : 'Show Keyboard',
              onPressed: () {
                setState(() {
                  _isKeyboardVisible = !_isKeyboardVisible;
                });
                if (!_isKeyboardVisible) {
                  _focusNode.requestFocus();
                }
              },
            ),
          ]
        ],
      ),
      body: KeyboardListener(
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
        child: Column(
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
                    : ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Start NetHack Game'),
                      ),
              ),
            // ゲーム進行中の操作盤 (横一列コマンドバー + 仮想キーボード)
            if (_isGameRunning && _isKeyboardVisible) ...[
              NetHackCmdPanel(
                onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
                onRawKeyCode: (code) => _sendFfiKey(code, "^${String.fromCharCode(code + 96)}"),
              ),
              NetHackKeyboard(
                onKeyPress: (key) => _sendFfiKey(key.codeUnitAt(0), key),
                onRawKeyCode: (code) => _sendFfiKey(code, "Raw($code)"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
