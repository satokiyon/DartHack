import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'nethack_ffi.dart';

class NetHackWorker {
  /// Worker Isolate のエントリーポイント
  static void start(SendPort uiSendPort) {
    final receivePort = ReceivePort();
    uiSendPort.send({'type': 'ready', 'sendPort': receivePort.sendPort});

    late final NetHackFfi ffi;

    // FFI コールバック用 NativeCallable
    late final NativeCallable<PrintCallback> printCallable;
    late final NativeCallable<NotifyInputCallback> inputCallable;

    receivePort.listen((message) {
      if (message is Map) {
        final type = message['type'];
        if (type == 'start') {
          final assetsPath = message['assetsPath'] as String;
          
          ffi = NetHackFfi();

          // NativeCallable の初期化
          printCallable = NativeCallable<PrintCallback>.listener((Pointer<Utf8> msgPtr) {
            final msg = msgPtr.toDartString();
            uiSendPort.send({'type': 'print', 'message': msg});
          });

          inputCallable = NativeCallable<NotifyInputCallback>.listener((int requestId) {
            uiSendPort.send({'type': 'request_input'});
          });

          // コールバックをC側に登録
          ffi.registerCallbacks(printCallable.nativeFunction, inputCallable.nativeFunction);

          // NetHack コアを起動
          final pathPtr = assetsPath.toNativeUtf8();
          final userPtr = "Player".toNativeUtf8();
          
          ffi.startNetHack(pathPtr, userPtr);
        } else if (type == 'key') {
          final key = message['key'] as int;
          ffi.sendKeyToC(key);
        }
      }
    });
  }
}
