import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// C関数の型定義
typedef RegisterPrintCallbackC = ffi.Void Function(ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>> callback);
typedef RegisterPrintCallbackDart = void Function(ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>> callback);

typedef StartDummyGameC = ffi.Void Function();
typedef StartDummyGameDart = void Function();

typedef StopDummyGameC = ffi.Void Function();
typedef StopDummyGameDart = void Function();

typedef SendKeyToCC = ffi.Void Function(ffi.Int32 key);
typedef SendKeyToCDart = void Function(int key);

typedef GetInputRequestIdC = ffi.Int32 Function();
typedef GetInputRequestIdDart = int Function();

class NetHackFFI {
  final ffi.DynamicLibrary dyLib;
  late final RegisterPrintCallbackDart registerPrintCallback;
  late final StartDummyGameDart startDummyGame;
  late final StopDummyGameDart stopDummyGame;
  late final SendKeyToCDart sendKeyToC;
  late final GetInputRequestIdDart getInputRequestId;

  NetHackFFI(this.dyLib) {
    registerPrintCallback = dyLib
        .lookup<ffi.NativeFunction<RegisterPrintCallbackC>>('register_print_callback')
        .asFunction<RegisterPrintCallbackDart>();

    startDummyGame = dyLib
        .lookup<ffi.NativeFunction<StartDummyGameC>>('start_dummy_game')
        .asFunction<StartDummyGameDart>();

    stopDummyGame = dyLib
        .lookup<ffi.NativeFunction<StopDummyGameC>>('stop_dummy_game')
        .asFunction<StopDummyGameDart>();

    sendKeyToC = dyLib
        .lookup<ffi.NativeFunction<SendKeyToCC>>('send_key_to_c')
        .asFunction<SendKeyToCDart>();

    getInputRequestId = dyLib
        .lookup<ffi.NativeFunction<GetInputRequestIdC>>('get_input_request_id')
        .asFunction<GetInputRequestIdDart>();
  }
}
