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
    late final NativeCallable<CreateWindowCallback> createCallable;
    late final NativeCallable<ClearWindowCallback> clearCallable;
    late final NativeCallable<DisplayWindowCallback> displayCallable;
    late final NativeCallable<DestroyWindowCallback> destroyCallable;
    late final NativeCallable<CursCallback> cursCallable;
    late final NativeCallable<PutStrCallback> putstrCallable;
    late final NativeCallable<PrintGlyphCallback> glyphCallable;
    late final NativeCallable<NotifyInputCallback> inputCallable;

    receivePort.listen((message) {
      if (message is Map) {
        final type = message['type'];
        if (type == 'start') {
          final assetsPath = message['assetsPath'] as String;
          
          ffi = NetHackFfi();

          // NativeCallable の初期化
          createCallable = NativeCallable<CreateWindowCallback>.listener((int winId, int type) {
            uiSendPort.send({
              'type': 'createWindow',
              'winId': winId,
              'winType': type,
            });
          });

          clearCallable = NativeCallable<ClearWindowCallback>.listener((int winId) {
            uiSendPort.send({
              'type': 'clearWindow',
              'winId': winId,
            });
          });

          displayCallable = NativeCallable<DisplayWindowCallback>.listener((int winId, int blocking) {
            uiSendPort.send({
              'type': 'displayWindow',
              'winId': winId,
              'blocking': blocking,
            });
          });

          destroyCallable = NativeCallable<DestroyWindowCallback>.listener((int winId) {
            uiSendPort.send({
              'type': 'destroyWindow',
              'winId': winId,
            });
          });

          cursCallable = NativeCallable<CursCallback>.listener((int winId, int x, int y) {
            uiSendPort.send({
              'type': 'curs',
              'winId': winId,
              'x': x,
              'y': y,
            });
          });

          putstrCallable = NativeCallable<PutStrCallback>.listener((int winId, int attr, Pointer<Utf8> msgPtr) {
            final msg = msgPtr.toDartString();
            uiSendPort.send({
              'type': 'putstr',
              'winId': winId,
              'attr': attr,
              'text': msg,
            });
          });

          glyphCallable = NativeCallable<PrintGlyphCallback>.listener((int winId, int x, int y, int tile, int ch, int color, int special) {
            uiSendPort.send({
              'type': 'printGlyph',
              'winId': winId,
              'x': x,
              'y': y,
              'tile': tile,
              'ch': ch,
              'color': color,
              'special': special,
            });
          });

          inputCallable = NativeCallable<NotifyInputCallback>.listener((int requestId) {
            uiSendPort.send({'type': 'request_input'});
          });

          // コールバックをC側に登録
          ffi.registerCallbacks(
            createCallable.nativeFunction,
            clearCallable.nativeFunction,
            displayCallable.nativeFunction,
            destroyCallable.nativeFunction,
            cursCallable.nativeFunction,
            putstrCallable.nativeFunction,
            glyphCallable.nativeFunction,
            inputCallable.nativeFunction,
          );

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
