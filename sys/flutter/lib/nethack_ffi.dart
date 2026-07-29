import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// コールバックの型定義
typedef CreateWindowCallback = Void Function(Int32 winId, Int32 type);
typedef ClearWindowCallback = Void Function(Int32 winId);
typedef DisplayWindowCallback = Void Function(Int32 winId, Int32 blocking, Int32 isPlain);
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
  Int32 color,
  Int32 tile
);
typedef EndMenuCallback = Void Function(Int32 winId, Pointer<Utf8> prompt);
typedef SelectMenuCallback = Void Function(Int32 winId, Int32 how);

// 新規追加コールバック
typedef YnFunctionCallback = Void Function(Pointer<Utf8> question, Pointer<Utf8> choices, Int32 def);
typedef GetLineCallback = Void Function(Pointer<Utf8> prompt, Pointer<Utf8> initText);
typedef AskNameCallback = Void Function(Pointer<Utf8> saves, Int32 maxChars);
typedef ExitCallback = Void Function(Pointer<Utf8> msg);
typedef NumberPadModeCallback = Void Function(Int32 state);
typedef CliparoundCallback = Void Function(Int32 x, Int32 y, Int32 playerX, Int32 playerY);
typedef PutMixedWithTileCallback = Void Function(Int32 winId, Int32 attr, Int32 tile, Pointer<Utf8> msg);

// C側起動関数
typedef StartNetHackFunc = Void Function(Pointer<Utf8> path, Pointer<Utf8> username);
typedef StartNetHackDart = void Function(Pointer<Utf8> path, Pointer<Utf8> username);

// コールバック登録関数 (19個の引数: CliparoundCallback と PutMixedWithTileCallback を追加)
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
  Pointer<NativeFunction<NumberPadModeCallback>> numberPadCb,
  Pointer<NativeFunction<CliparoundCallback>> cliparoundCb,
  Pointer<NativeFunction<PutMixedWithTileCallback>> putMixedCb,
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
  Pointer<NativeFunction<NumberPadModeCallback>> numberPadCb,
  Pointer<NativeFunction<CliparoundCallback>> cliparoundCb,
  Pointer<NativeFunction<PutMixedWithTileCallback>> putMixedCb,
);

// キー送信
typedef SendKeyFunc = Void Function(Int32 key);
typedef SendKeyDart = void Function(int key);

// メニュー選択結果送信
typedef SendMenuSelectionFunc = Void Function(Int64 ident, Int64 count);
typedef SendMenuSelectionDart = void Function(int ident, int count);

typedef SendMenuSelectionsFunc = Void Function(Pointer<Utf8> csv);
typedef SendMenuSelectionsDart = void Function(Pointer<Utf8> csv);

// カウンタ取得
typedef GetInputRequestIdFunc = Int32 Function();
typedef GetInputRequestIdDart = int Function();

typedef GetIsGameOverFunc = Int32 Function();
typedef GetIsGameOverDart = int Function();

// 結果返信用関数
typedef SendYnResultFunc = Void Function(Int8 result);
typedef SendYnResultDart = void Function(int result);

typedef SendGetLineResultFunc = Void Function(Pointer<Utf8> result);
typedef SendGetLineResultDart = void Function(Pointer<Utf8> result);

typedef SendAskNameResultFunc = Void Function(Pointer<Utf8> result, Int32 mode);
typedef SendAskNameResultDart = void Function(Pointer<Utf8> result, int mode);

// 拡張コマンド取得
typedef GetExtCmdsFunc = Pointer<Utf8> Function();
typedef GetExtCmdsDart = Pointer<Utf8> Function();

typedef GetTopTenTextFunc = Pointer<Utf8> Function();
typedef GetTopTenTextDart = Pointer<Utf8> Function();

typedef TriggerDatabaseSearchFunc = Void Function();
typedef TriggerDatabaseSearchDart = void Function();

// PosCmd (座標クリック) 送信
typedef SendPosCmdFunc = Void Function(Int32 x, Int32 y, Int32 mod);
typedef SendPosCmdDart = void Function(int x, int y, int mod);

// 複数キー送信
typedef SendKeysFunc = Void Function(Pointer<Int32> keys, Int32 len);
typedef SendKeysDart = void Function(Pointer<Int32> keys, int len);

// CコアビルドID取得
typedef GetBuildIdFunc = Pointer<Utf8> Function();
typedef GetBuildIdDart = Pointer<Utf8> Function();

// ショートカットボタン用送信 (extcmd テキストパスを強制)
typedef SendShortcutFunc = Void Function(Pointer<Int32> keys, Int32 len);
typedef SendShortcutDart = void Function(Pointer<Int32> keys, int len);

// 新階層リワード用コールバックおよび FFI
typedef NewLevelRestCallback = Void Function();
typedef RegisterNewLevelRestFunc = Void Function(Pointer<NativeFunction<NewLevelRestCallback>> cb);
typedef RegisterNewLevelRestDart = void Function(Pointer<NativeFunction<NewLevelRestCallback>> cb);

typedef SendNewLevelRestResultFunc = Void Function(Int32 rewardAmount);
typedef SendNewLevelRestResultDart = void Function(int rewardAmount);

class NetHackFfi {
  late final DynamicLibrary _lib;
  late final StartNetHackDart startNetHack;
  late final RegisterCallbacksDart registerCallbacks;
  late final SendKeyDart sendKeyToC;
  late final SendKeysDart sendKeysToC;
  late final SendShortcutDart sendShortcutToC;
  late final SendMenuSelectionDart sendMenuSelection;
  late final SendMenuSelectionsDart sendMenuSelections;
  late final GetInputRequestIdDart getInputRequestId;
  late final GetIsGameOverDart getIsGameOver;

  late final SendYnResultDart sendYnResult;
  late final SendGetLineResultDart sendGetLineResult;
  late final SendAskNameResultDart sendAskNameResult;
  late final GetExtCmdsDart getExtCmdsFlutter;
  late final SendPosCmdDart sendPosCmdToC;
  late final GetTopTenTextDart getTopTenTextFlutter;
  late final TriggerDatabaseSearchDart triggerDatabaseSearch;
  late final GetBuildIdDart getBuildIdNative;
  late final RegisterNewLevelRestDart registerNewLevelRest;
  late final SendNewLevelRestResultDart sendNewLevelRestResult;

  NetHackFfi() {
    try {
      _lib = DynamicLibrary.open('libnethack.so');
    } catch (_) {
      // Windows デバッグ用フォールバック
      _lib = DynamicLibrary.open('nethack_dummy.dll');
    }

    try {
      registerNewLevelRest = _lib
          .lookup<NativeFunction<RegisterNewLevelRestFunc>>('RegisterNewLevelRestCallback')
          .asFunction();
    } catch (e) {
      registerNewLevelRest = (_) {};
    }

    try {
      sendNewLevelRestResult = _lib
          .lookup<NativeFunction<SendNewLevelRestResultFunc>>('SendNewLevelRestResultToC')
          .asFunction();
    } catch (e) {
      sendNewLevelRestResult = (_) {};
    }

    try {
      getBuildIdNative = _lib
          .lookup<NativeFunction<GetBuildIdFunc>>('flutter_get_build_id')
          .asFunction();
    } catch (e) {
      getBuildIdNative = () => nullptr;
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

    sendKeysToC = _lib
        .lookup<NativeFunction<SendKeysFunc>>('SendKeysToFlutter')
        .asFunction();

    sendShortcutToC = _lib
        .lookup<NativeFunction<SendShortcutFunc>>('SendShortcutToFlutter')
        .asFunction();

    sendMenuSelection = _lib
        .lookup<NativeFunction<SendMenuSelectionFunc>>('SendMenuSelection')
        .asFunction();

    sendMenuSelections = _lib
      .lookup<NativeFunction<SendMenuSelectionsFunc>>('SendMenuSelectionsToC')
      .asFunction();

    getInputRequestId = _lib
        .lookup<NativeFunction<GetInputRequestIdFunc>>('GetFlutterInputRequestId')
        .asFunction();

    getIsGameOver = _lib
        .lookup<NativeFunction<GetIsGameOverFunc>>('GetIsGameOver')
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

    sendPosCmdToC = _lib
        .lookup<NativeFunction<SendPosCmdFunc>>('SendPosCmdToFlutter')
        .asFunction();

    getTopTenTextFlutter = _lib
        .lookup<NativeFunction<GetTopTenTextFunc>>('GetTopTenTextFlutter')
        .asFunction();

    triggerDatabaseSearch = _lib
        .lookup<NativeFunction<TriggerDatabaseSearchFunc>>('TriggerDatabaseSearchFlutter')
        .asFunction();
  }

  String getBuildId() {
    try {
      final ptr = getBuildIdNative();
      if (ptr != nullptr) {
        return ptr.toDartString();
      }
    } catch (e) {
      debugPrint("Warning: Failed to get build id: $e");
    }
    return "unknown";
  }
}

