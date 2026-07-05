import 'dart:ffi';
import 'package:ffi/ffi.dart';

// コールバックの型定義
typedef CreateWindowCallback = Void Function(Int32 winId, Int32 type);
typedef ClearWindowCallback = Void Function(Int32 winId);
typedef DisplayWindowCallback = Void Function(Int32 winId, Int32 blocking);
typedef DestroyWindowCallback = Void Function(Int32 winId);
typedef CursCallback = Void Function(Int32 winId, Int32 x, Int32 y);
typedef PutStrCallback = Void Function(Int32 winId, Int32 attr, Pointer<Utf8> msg);
typedef PrintGlyphCallback = Void Function(Int32 winId, Int32 x, Int32 y, Int32 tile, Int32 ch, Int32 color, Int32 special);
typedef NotifyInputCallback = Void Function(Int32 requestId);

// C側起動関数
typedef StartNetHackFunc = Void Function(Pointer<Utf8> path, Pointer<Utf8> username);
typedef StartNetHackDart = void Function(Pointer<Utf8> path, Pointer<Utf8> username);

// コールバック登録関数
typedef RegisterCallbacksFunc = Void Function(
  Pointer<NativeFunction<CreateWindowCallback>> createCb,
  Pointer<NativeFunction<ClearWindowCallback>> clearCb,
  Pointer<NativeFunction<DisplayWindowCallback>> displayCb,
  Pointer<NativeFunction<DestroyWindowCallback>> destroyCb,
  Pointer<NativeFunction<CursCallback>> cursCb,
  Pointer<NativeFunction<PutStrCallback>> putstrCb,
  Pointer<NativeFunction<PrintGlyphCallback>> glyphCb,
  Pointer<NativeFunction<NotifyInputCallback>> inputCb,
);
typedef RegisterCallbacksDart = void Function(
  Pointer<NativeFunction<CreateWindowCallback>> createCb,
  Pointer<NativeFunction<ClearWindowCallback>> clearCb,
  Pointer<NativeFunction<DisplayWindowCallback>> displayCb,
  Pointer<NativeFunction<DestroyWindowCallback>> destroyCb,
  Pointer<NativeFunction<CursCallback>> cursCb,
  Pointer<NativeFunction<PutStrCallback>> putstrCb,
  Pointer<NativeFunction<PrintGlyphCallback>> glyphCb,
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
