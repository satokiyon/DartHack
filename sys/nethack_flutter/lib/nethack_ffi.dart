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

// メニュー関連コールバック
typedef StartMenuCallback = Void Function(Int32 winId);
typedef AddMenuCallback = Void Function(
  Int32 winId,
  Int64 ident,
  Int32 accelerator,
  Int32 groupacc,
  Int32 attr,
  Pointer<Utf8> str,
  Int32 preselected,
  Int32 color
);
typedef EndMenuCallback = Void Function(Int32 winId, Pointer<Utf8> prompt);
typedef SelectMenuCallback = Void Function(Int32 winId, Int32 how);

// 新規追加コールバック
typedef YnFunctionCallback = Void Function(Pointer<Utf8> question, Pointer<Utf8> choices, Int32 def);
typedef GetLineCallback = Void Function(Pointer<Utf8> prompt, Pointer<Utf8> initText);
typedef AskNameCallback = Void Function(Pointer<Utf8> saves, Int32 maxChars);
typedef ExitCallback = Void Function(Pointer<Utf8> msg);

// C側起動関数
typedef StartNetHackFunc = Void Function(Pointer<Utf8> path, Pointer<Utf8> username);
typedef StartNetHackDart = void Function(Pointer<Utf8> path, Pointer<Utf8> username);

// コールバック登録関数 (16個の引数へ拡張)
typedef RegisterCallbacksFunc = Void Function(
  Pointer<NativeFunction<CreateWindowCallback>> createCb,
  Pointer<NativeFunction<ClearWindowCallback>> clearCb,
  Pointer<NativeFunction<DisplayWindowCallback>> displayCb,
  Pointer<NativeFunction<DestroyWindowCallback>> destroyCb,
  Pointer<NativeFunction<CursCallback>> cursCb,
  Pointer<NativeFunction<PutStrCallback>> putstrCb,
  Pointer<NativeFunction<PrintGlyphCallback>> glyphCb,
  Pointer<NativeFunction<NotifyInputCallback>> inputCb,
  Pointer<NativeFunction<StartMenuCallback>> startMenuCb,
  Pointer<NativeFunction<AddMenuCallback>> addMenuCb,
  Pointer<NativeFunction<EndMenuCallback>> endMenuCb,
  Pointer<NativeFunction<SelectMenuCallback>> selectMenuCb,
  Pointer<NativeFunction<YnFunctionCallback>> ynCb,
  Pointer<NativeFunction<GetLineCallback>> getlineCb,
  Pointer<NativeFunction<AskNameCallback>> asknameCb,
  Pointer<NativeFunction<ExitCallback>> exitCb,
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
  Pointer<NativeFunction<StartMenuCallback>> startMenuCb,
  Pointer<NativeFunction<AddMenuCallback>> addMenuCb,
  Pointer<NativeFunction<EndMenuCallback>> endMenuCb,
  Pointer<NativeFunction<SelectMenuCallback>> selectMenuCb,
  Pointer<NativeFunction<YnFunctionCallback>> ynCb,
  Pointer<NativeFunction<GetLineCallback>> getlineCb,
  Pointer<NativeFunction<AskNameCallback>> asknameCb,
  Pointer<NativeFunction<ExitCallback>> exitCb,
);

// キー送信
typedef SendKeyFunc = Void Function(Int32 key);
typedef SendKeyDart = void Function(int key);

// メニュー選択結果送信
typedef SendMenuSelectionFunc = Void Function(Int64 ident);
typedef SendMenuSelectionDart = void Function(int ident);

// カウンタ取得
typedef GetInputRequestIdFunc = Int32 Function();
typedef GetInputRequestIdDart = int Function();

// 結果返信用関数
typedef SendYnResultFunc = Void Function(Int8 result);
typedef SendYnResultDart = void Function(int result);

typedef SendGetLineResultFunc = Void Function(Pointer<Utf8> result);
typedef SendGetLineResultDart = void Function(Pointer<Utf8> result);

typedef SendAskNameResultFunc = Void Function(Pointer<Utf8> result);
typedef SendAskNameResultDart = void Function(Pointer<Utf8> result);

// 拡張コマンド取得
typedef GetExtCmdsFunc = Pointer<Utf8> Function();
typedef GetExtCmdsDart = Pointer<Utf8> Function();

class NetHackFfi {
  late final DynamicLibrary _lib;
  late final StartNetHackDart startNetHack;
  late final RegisterCallbacksDart registerCallbacks;
  late final SendKeyDart sendKeyToC;
  late final SendMenuSelectionDart sendMenuSelection;
  late final GetInputRequestIdDart getInputRequestId;
  
  late final SendYnResultDart sendYnResult;
  late final SendGetLineResultDart sendGetLineResult;
  late final SendAskNameResultDart sendAskNameResult;
  late final GetExtCmdsDart getExtCmdsFlutter;

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

    sendMenuSelection = _lib
        .lookup<NativeFunction<SendMenuSelectionFunc>>('SendMenuSelection')
        .asFunction();

    getInputRequestId = _lib
        .lookup<NativeFunction<GetInputRequestIdFunc>>('GetFlutterInputRequestId')
        .asFunction();

    sendYnResult = _lib
        .lookup<NativeFunction<SendYnResultFunc>>('SendYnResultToC')
        .asFunction();

    sendGetLineResult = _lib
        .lookup<NativeFunction<SendGetLineResultFunc>>('SendGetLineResultToC')
        .asFunction();

    sendAskNameResult = _lib
        .lookup<NativeFunction<SendAskNameResultFunc>>('SendAskNameResultToC')
        .asFunction();

    getExtCmdsFlutter = _lib
        .lookup<NativeFunction<GetExtCmdsFunc>>('GetExtCmdsFlutter')
        .asFunction();
  }
}
