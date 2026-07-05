import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'nethack_ffi.dart';

// FFI用のトップレベル変数
SendPort? _uiSendPort;
NetHackFFI? _nethack;
ffi.NativeCallable<ffi.Void Function(ffi.Pointer<Utf8>)>? _printCallable;
bool _monitoring = false;

// Cスレッドから呼ばれるコールバック（NativeCallable.listenerにより安全にIsolateスレッドで実行される）
void _printCallback(ffi.Pointer<Utf8> cmsg) {
  final msg = cmsg.toDartString();
  _uiSendPort?.send({'type': 'print', 'message': msg});
}

class NetHackWorker {
  static void start(SendPort uiSendPort) {
    _uiSendPort = uiSendPort;

    // Worker Isolateの入力を受けるReceivePort
    final workerReceivePort = ReceivePort();
    uiSendPort.send({'type': 'ready', 'sendPort': workerReceivePort.sendPort});

    workerReceivePort.listen((message) {
      if (message is Map) {
        final type = message['type'];
        if (type == 'key') {
          _nethack?.sendKeyToC(message['key']);
        } else if (type == 'start') {
          _runGame();
        } else if (type == 'stop') {
          _stopGame();
        }
      }
    });
  }

  static void _runGame() {
    try {
      // Android/Windows向けにダミー共有ライブラリをロード
      final ffi.DynamicLibrary dyLib = Platform.isAndroid
          ? ffi.DynamicLibrary.open('libnethack_dummy.so')
          : Platform.isWindows
              ? ffi.DynamicLibrary.open('nethack_dummy.dll')
              : ffi.DynamicLibrary.process();

      _nethack = NetHackFFI(dyLib);

      // コールバックのライフサイクルをIsolateで管理（GC回避）
      _printCallable = ffi.NativeCallable<ffi.Void Function(ffi.Pointer<Utf8>)>.listener(_printCallback);
      _nethack!.registerPrintCallback(_printCallable!.nativeFunction);

      // バックグラウンドでゲームスレッドを開始
      _nethack!.startDummyGame();

      // Cスレッドの状態（入力待ちカウンタ）を監視する非同期ポーリング
      _monitoring = true;
      int lastRequestId = 0;

      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (!_monitoring || _nethack == null) return false;
        
        final requestId = _nethack!.getInputRequestId();
        if (requestId != lastRequestId) {
          lastRequestId = requestId;
          _uiSendPort?.send({'type': 'request_input'});
        }
        return true;
      });

    } catch (e, stack) {
      _uiSendPort?.send({'type': 'error', 'message': e.toString(), 'stack': stack.toString()});
    }
  }

  static void _stopGame() {
    _monitoring = false;
    _nethack?.stopDummyGame();
    _nethack = null;
    _printCallable?.close();
    _printCallable = null;
  }
}
