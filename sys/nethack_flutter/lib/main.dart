import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nethack_assets.dart';
import 'nethack_screen.dart';
import 'nethack_worker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetHackJP Flutter Port',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final NetHackScreen _screen = NetHackScreen();
  
  Isolate? _workerIsolate;
  SendPort? _workerSendPort;
  bool _isGameRunning = false;
  bool _waitingForInput = false;
  bool _assetsReady = false;
  String _assetsPath = '';

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      _addLog("Error initializing assets: $e");
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
    _workerIsolate = await Isolate.spawn(NetHackWorker.start, receivePort.sendPort);

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
          // blocking の場合は getch を待つ処理が C 側で走る
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
          _focusNode.requestFocus();
        } else if (type == 'error') {
          _addLog("ERROR: ${message['message']}");
          _stopGame();
        }
      }
    });
  }

  void _stopGame() {
    _workerIsolate?.kill(priority: Isolate.beforeNextEvent);
    _workerIsolate = null;
    _workerSendPort = null;
    setState(() {
      _isGameRunning = false;
      _waitingForInput = false;
    });
    _addLog("Game stopped.");
  }

  void _sendFfiKey(int code, String label) {
    if (!_waitingForInput) return;
    setState(() {
      _waitingForInput = false;
    });
    _addLog("> Send Key: '$label' ($code)");
    _workerSendPort?.send({
      'type': 'key',
      'key': code,
    });
  }

  Widget _buildGameScreen() {
    return ListenableBuilder(
      listenable: _screen,
      builder: (context, _) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. メッセージ領域 (直近3行)
              Container(
                height: 60,
                width: double.infinity,
                color: Colors.black,
                child: Text(
                  _screen.messages.isEmpty
                      ? ""
                      : _screen.messages.sublist(
                          _screen.messages.length > 3 ? _screen.messages.length - 3 : 0
                        ).join("\n"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              // 2. マップグリッド領域 (21行 x 80列)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Container(
                      width: 80 * 8.5,
                      height: 21 * 16.0,
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(NetHackScreen.mapRows, (row) {
                          return Row(
                            children: List.generate(NetHackScreen.mapCols, (col) {
                              final glyph = _screen.mapGrid[row][col];
                              Color textColor = Color(glyph.color | 0xFF000000);
                              if (glyph.color == 0) {
                                textColor = Colors.white;
                              }
                              
                              return SizedBox(
                                width: 8.5,
                                height: 16.0,
                                child: Center(
                                  child: Text(
                                    glyph.char,
                                    style: TextStyle(
                                      color: textColor,
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: (glyph.special & 0x01 != 0)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              // 3. ステータス領域 (2行)
              Container(
                height: 40,
                width: double.infinity,
                color: Colors.black,
                child: Text(
                  _screen.statusLines.join("\n"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetHackJP Flutter Port'),
        actions: [
          if (_isGameRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopGame,
            ),
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
              
              if (code != null) {
                _sendFfiKey(code, name ?? "");
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _isGameRunning
                    ? _buildGameScreen()
                    : SingleChildScrollView(
                        child: Text(
                          _logs.join('\n'),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              if (!_isGameRunning)
                if (!_assetsReady)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text("Preparing assets..."),
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Start NetHack Game'),
                  )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: _waitingForInput ? 'Waiting for key input...' : 'Game running...',
                          border: const OutlineInputBorder(),
                          enabled: _waitingForInput,
                        ),
                        maxLength: 1,
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            final code = text.codeUnitAt(0);
                            _sendFfiKey(code, text);
                            _inputController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
