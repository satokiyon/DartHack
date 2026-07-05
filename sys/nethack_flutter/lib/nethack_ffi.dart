import 'dart:ffi';
import 'package:ffi/ffi.dart';

// コールバックの型定義
typedef PrintCallback = Void Function(Pointer<Utf8> msg);
typedef NotifyInputCallback = Void Function(Int32 requestId);

// C側起動関数
typedef StartNetHackFunc = Void Function(Pointer<Utf8> path, Pointer<Utf8> username);
typedef StartNetHackDart = void Function(Pointer<Utf8> path, Pointer<Utf8> username);

// コールバック登録関数
typedef RegisterCallbacksFunc = Void Function(
  Pointer<NativeFunction<PrintCallback>> printCb,
  Pointer<NativeFunction<NotifyInputCallback>> inputCb,
);
typedef RegisterCallbacksDart = void Function(
  Pointer<NativeFunction<PrintCallback>> printCb,
  Pointer<NativeFunction<NotifyInputCallback>> inputCb,
);

// キー送信
typedef SendKeyFunc = Void Function(Int32 key);
typedef SendKeyDart = void Function(int key);

// カウンタ取得
typedef GetInputRequestIdFunc = Int32 Function();
typedef GetInputRequestIdDart = int Function();

class NetHackFfi {
  late final DynamicLibrary _lib;
  late final StartNetHackDart startNetHack;
  late final RegisterCallbacksDart registerCallbacks;
  late final SendKeyDart sendKeyToC;
  late final GetInputRequestIdDart getInputRequestId;

  NetHackFfi() {
    try {
      _lib = DynamicLibrary.open('libnethack.so');
    } catch (_) {
      // Windows デバッグ用フォールバック
      _lib = DynamicLibrary.open('nethack_dummy.dll');
    }

    startNetHack = _lib
        .lookup<NativeFunction<StartNetHackFunc>>('StartNetHackFlutter')
        .asFunction();

    registerCallbacks = _lib
        .lookup<NativeFunction<RegisterCallbacksFunc>>('RegisterFlutterCallbacks')
        .asFunction();

    sendKeyToC = _lib
        .lookup<NativeFunction<SendKeyFunc>>('SendKeyToFlutter')
        .asFunction();

    getInputRequestId = _lib
        .lookup<NativeFunction<GetInputRequestIdFunc>>('GetFlutterInputRequestId')
        .asFunction();
  }
}
