import 'dart:isolate';
import 'package:flutter/material.dart';
import 'nethack_assets.dart';
import 'nethack_worker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetHack Flutter FFI Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
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
          _workerSendPort?.send({'type': 'start'});
        } else if (type == 'print') {
          _addLog(message['message']);
        } else if (type == 'request_input') {
          setState(() {
            _waitingForInput = true;
          });
          _focusNode.requestFocus();
        } else if (type == 'error') {
          _addLog("ERROR: ${message['message']}");
          _addLog(message['stack'] ?? "");
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

  void _sendInput() {
    final text = _inputController.text;
    if (text.isEmpty) return;

    final charCode = text.codeUnitAt(0);
    _inputController.clear();

    _addLog("> Send Key: '$text' ($charCode)");
    _workerSendPort?.send({
      'type': 'key',
      'key': charCode,
    });

    setState(() {
      _waitingForInput = false;
    });
  }

  @override
  void dispose() {
    _stopGame();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NetHack Flutter FFI Demo'),
        actions: [
          if (_isGameRunning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopGame,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey.shade800),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.lightGreenAccent,
                      ),
                    );
                  },
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
                  child: const Text('Start Dummy Game'),
                )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: _waitingForInput ? 'Waiting for input...' : 'Game running...',
                        border: const OutlineInputBorder(),
                        enabled: _waitingForInput,
                      ),
                      maxLength: 1,
                      onSubmitted: (_) => _sendInput(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _waitingForInput ? _sendInput : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 50),
                    ),
                    child: const Text('Send'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
