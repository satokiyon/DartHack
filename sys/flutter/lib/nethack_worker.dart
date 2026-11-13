import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'nethack_ffi.dart';

/// Worker Isolate で発生したエラーのフェーズ識別定数
abstract final class WorkerErrorPhase {
  static const String coreLoad = 'core_load';
  static const String workerInit = 'worker_init';
  static const String workerRuntime = 'worker_runtime';
}

/// Worker Isolate の起動エラーを UI ダイアログ表示用に整形する記述子
class WorkerStartupErrorPresentation {
  final String title;
  final String message;
  final String details;
  final bool shouldTerminateWorker;

  const WorkerStartupErrorPresentation({
    required this.title,
    required this.message,
    required this.details,
    required this.shouldTerminateWorker,
  });

  /// Worker からの `worker_error` メッセージを解析してダイアログ表示内容を返す
  static WorkerStartupErrorPresentation fromWorkerMessage({
    required Map<dynamic, dynamic> message,
    required String libraryName,
    required bool isJapanese,
  }) {
    final phase = message['phase']?.toString() ?? WorkerErrorPhase.workerRuntime;
    final coreStarted = message['coreStarted'] == true;
    final errorDetails = message['error']?.toString() ?? 'Unknown core error';

    if (phase == WorkerErrorPhase.coreLoad) {
      return WorkerStartupErrorPresentation(
        title: isJapanese ? 'コア読込エラー' : 'Core Load Error',
        message: isJapanese
            ? 'NetHack コアライブラリ ($libraryName) の読み込みに失敗したため、ゲームを開始できません。'
            : 'Failed to load NetHack core library ($libraryName). Cannot start the game.',
        details: errorDetails,
        shouldTerminateWorker: !coreStarted,
      );
    }

    return WorkerStartupErrorPresentation(
      title: isJapanese ? 'ゲーム初期化エラー' : 'Game Initialization Error',
      message: isJapanese
          ? 'ゲームワーカーの初期化中にエラーが発生したため、ゲームを開始できませんでした。'
          : 'An error occurred while initializing the game worker. Cannot start the game.',
      details: errorDetails,
      shouldTerminateWorker: !coreStarted,
    );
  }
}

/// Worker Isolate の状態とメッセージ処理を管理するセッション
///
/// ネイティブライブラリを伴わないユニットテストでも起動順やガードを検証できるよう分離している。
@visibleForTesting
class NetHackWorkerSession {
  NetHackFfi? ffi;
  bool isCoreThreadStarted = false;
  String currentPhase = WorkerErrorPhase.workerInit;

  final void Function(String) onLog;
  final void Function(Map<String, dynamic>) onSendToUi;
  final NetHackFfi Function(String langCode) ffiFactory;
  final void Function(NetHackFfi ffi) registerCallbacks;

  NetHackWorkerSession({
    required this.onLog,
    required this.onSendToUi,
    NetHackFfi Function(String langCode)? ffiFactory,
    required this.registerCallbacks,
  }) : ffiFactory = ffiFactory ?? ((langCode) => NetHackFfi(langCode));

  /// UI Isolate から受信したメッセージを処理する
  void handleMessage(dynamic message) {
    try {
      onLog("Received message in Worker Isolate: $message");
      if (message is! Map) return;

      final type = message['type'];
      if (type == 'start') {
        if (ffi != null) {
          onLog("Ignoring duplicate 'start' message (already initialized)");
          return;
        }
        final assetsPath = message['assetsPath'] as String;
        final langCode = (message['langCode'] as String?) ?? 'ja';
        final initialLayout = message['status_line_layout'] as String? ?? 'standard';
        final initialAutosaveEnabled = (message['autosave_enabled'] as bool? ?? true) ? 1 : 0;
        final initialAutosaveInterval = message['autosave_interval'] as int? ?? 50;

        currentPhase = WorkerErrorPhase.coreLoad;
        onLog("Initializing NetHackFfi for langCode='$langCode' and registering callbacks via struct...");
        final loadedFfi = ffiFactory(langCode);
        ffi = loadedFfi;

        currentPhase = WorkerErrorPhase.workerInit;
        registerCallbacks(loadedFfi);

        onLog("Setting C core language mode for langCode='$langCode'");
        loadedFfi.setLanguageMode(langCode == 'ja' ? 1 : 0);

        onLog(
          "Applying initial settings before startNetHack: "
          "layout='$initialLayout', autosave=($initialAutosaveEnabled, $initialAutosaveInterval)",
        );
        loadedFfi.setStatusLayout(initialLayout);
        loadedFfi.setAutosaveSettings(initialAutosaveEnabled, initialAutosaveInterval);

        final pathPtr = assetsPath.toNativeUtf8();
        final userPtr = "Player".toNativeUtf8();
        try {
          onLog("Calling ffi.startNetHack with path='$assetsPath'...");
          loadedFfi.startNetHack(pathPtr, userPtr);
          isCoreThreadStarted = true;
          currentPhase = WorkerErrorPhase.workerRuntime;
          onLog("ffi.startNetHack returned.");
        } finally {
          calloc.free(pathPtr);
          calloc.free(userPtr);
        }
        return;
      }

      // 'start' 未完了（ffi 未初期化）のメッセージは一括ガードして LateInitializationError を防ぐ
      final activeFfi = ffi;
      if (activeFfi == null) {
        onLog("Ignoring '$type' message before 'start' completes.");
        return;
      }

      if (type == 'key') {
        final key = message['key'] as int;
        activeFfi.sendKeyToC(key);
      } else if (type == 'keys') {
        final raw = message['keys'];
        if (raw is List) {
          final int length = raw.length;
          if (length > 0) {
            final Pointer<Int32> ptr = calloc<Int32>(length);
            try {
              for (int i = 0; i < length; i++) {
                ptr[i] = raw[i] as int;
              }
              activeFfi.sendKeysToC(ptr, length);
            } finally {
              calloc.free(ptr);
            }
          }
        }
      } else if (type == 'shortcut') {
        final raw = message['keys'];
        if (raw is List) {
          final int length = raw.length;
          if (length > 0) {
            final Pointer<Int32> ptr = calloc<Int32>(length);
            try {
              for (int i = 0; i < length; i++) {
                ptr[i] = raw[i] as int;
              }
              activeFfi.sendShortcutToC(ptr, length);
            } finally {
              calloc.free(ptr);
            }
          }
        }
      } else if (type == 'pos_cmd') {
        final x = message['x'] as int;
        final y = message['y'] as int;
        final mod = message['mod'] as int? ?? 1;
        activeFfi.sendPosCmdToC(x, y, mod);
      } else if (type == 'menu_cancel') {
        activeFfi.sendMenuCancel();
      } else if (type == 'menu_select') {
        final ident = message['ident'] as int;
        final count = message['count'] as int? ?? -1;
        activeFfi.sendMenuSelection(ident, count);
      } else if (type == 'menu_selects') {
        final selections = message['selections'] as List<dynamic>? ?? const <dynamic>[];
        final List<String> pairs = [];
        for (final sel in selections) {
          if (sel is Map) {
            final id = sel['ident'] as int;
            final count = sel['count'] as int? ?? 1;
            pairs.add('$id:$count');
          }
        }
        final csv = pairs.join(',').toNativeUtf8();
        try {
          activeFfi.sendMenuSelections(csv);
        } finally {
          calloc.free(csv);
        }
      } else if (type == 'yn_result') {
        final result = message['result'] as int;
        activeFfi.sendYnResult(result);
      } else if (type == 'lookup_key') {
        final code = message['code'] as int;
        onLog("lookup_key invoked for code: $code");
        activeFfi.lookupKeyDescription(code);
      } else if (type == 'new_level_rest_result') {
        final rewardAmount = message['rewardAmount'] as int? ?? 0;
        activeFfi.sendNewLevelRestResult(rewardAmount);
      } else if (type == 'getline_result') {
        final result = message['result'] as String?;
        if (result != null) {
          final resultPtr = result.toNativeUtf8();
          try {
            activeFfi.sendGetLineResult(resultPtr);
          } finally {
            calloc.free(resultPtr);
          }
        } else {
          activeFfi.sendGetLineResult(nullptr);
        }
      } else if (type == 'askname_result') {
        final result = message['result'] as String?;
        final mode = (message['mode'] as int?) ?? 0;
        if (result != null) {
          final resultPtr = result.toNativeUtf8();
          try {
            activeFfi.sendAskNameResult(resultPtr, mode);
          } finally {
            calloc.free(resultPtr);
          }
        } else {
          activeFfi.sendAskNameResult(nullptr, mode);
        }
      } else if (type == 'set_autosave_settings') {
        final enabled = (message['enabled'] as bool? ?? true) ? 1 : 0;
        final interval = message['interval'] as int? ?? 50;
        onLog("set_autosave_settings message received: enabled=$enabled, interval=$interval");
        activeFfi.setAutosaveSettings(enabled, interval);
      } else if (type == 'set_status_layout') {
        final layout = message['status_line_layout'] as String? ?? 'standard';
        onLog("set_status_layout message received: layout=$layout");
        activeFfi.setStatusLayout(layout);
      } else if (type == 'request_status_options_change') {
        final hitpointbar = message['hitpointbar'] as bool? ?? true;
        final hiliteStatus = message['hilite_status'] as bool? ?? true;
        final timeOpt = message['time'] as bool? ?? true;
        final showexp = message['showexp'] as bool? ?? true;
        final statuslines = message['statuslines'] as int? ?? 2;
        final weaponstatus = message['weaponstatus'] as bool? ?? false;
        final armorstatus = message['armorstatus'] as bool? ?? false;
        final terrainstatus = message['terrainstatus'] as bool? ?? false;
        final statusLayout = message['status_line_layout'] as String? ?? 'standard';
        onLog(
          "request_status_options_change: hpbar=$hitpointbar hilite=$hiliteStatus "
          "time=$timeOpt exp=$showexp lines=$statuslines wep=$weaponstatus "
          "arm=$armorstatus ter=$terrainstatus layout=$statusLayout",
        );
        activeFfi.requestStatusOptionsChange(
          hitpointbar: hitpointbar,
          hiliteStatus: hiliteStatus,
          timeOpt: timeOpt,
          showexp: showexp,
          statuslines: statuslines,
          weaponstatus: weaponstatus,
          armorstatus: armorstatus,
          terrainstatus: terrainstatus,
          statusLayout: statusLayout,
        );
      } else if (type == 'trigger_database_search') {
        onLog("trigger_database_search message received in worker isolate");
        activeFfi.triggerDatabaseSearch();
      }
    } catch (e, st) {
      if (!isCoreThreadStarted && currentPhase != WorkerErrorPhase.workerRuntime) {
        ffi = null;
      }
      onLog("[NetHackWorker ERROR] Exception in Worker Isolate: $e\n$st");
      onSendToUi({
        'type': 'worker_error',
        'error': e.toString(),
        'stack': st.toString(),
        'phase': currentPhase,
        'coreStarted': isCoreThreadStarted,
      });
    }
  }
}

class NetHackWorker {
  /// 不正なバイトを含む文字列でもクラッシュさせずにデコードする安全なヘルパー
  static String _utf8DecodeLossy(Pointer<Utf8> ptr) {
    if (ptr == nullptr) return "";
    final List<int> bytes = [];
    final Pointer<Uint8> bytePtr = ptr.cast<Uint8>();
    int i = 0;
    while (true) {
      final byte = bytePtr[i];
      if (byte == 0) break;
      bytes.add(byte);
      i++;
    }
    // allowMalformed: true を指定してデコードすることで FormatException を防ぐ
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }

  /// Worker Isolate のエントリーポイント
  static void start(SendPort uiSendPort) {
    final receivePort = ReceivePort();

    NetHackWorkerSession? session;

    // FFI コールバック用 NativeCallable
    late final NativeCallable<CreateWindowCallback> createCallable;
    late final NativeCallable<ClearWindowCallback> clearCallable;
    late final NativeCallable<DisplayWindowCallback> displayCallable;
    late final NativeCallable<DestroyWindowCallback> destroyCallable;
    late final NativeCallable<CursCallback> cursCallable;
    late final NativeCallable<PutStrCallback> putstrCallable;
    late final NativeCallable<PrintGlyphCallback> glyphCallable;
    late final NativeCallable<NotifyInputCallback> inputCallable;

    // 新しいメニュー用の NativeCallable
    late final NativeCallable<StartMenuCallback> startMenuCallable;
    late final NativeCallable<AddMenuCallback> addMenuCallable;
    late final NativeCallable<EndMenuCallback> endMenuCallable;
    late final NativeCallable<SelectMenuCallback> selectMenuCallable;

    // 新しい同期待信用 NativeCallable
    late final NativeCallable<YnFunctionCallback> ynCallable;
    late final NativeCallable<GetLineCallback> getlineCallable;
    late final NativeCallable<AskNameCallback> asknameCallable;
    late final NativeCallable<ExitCallback> exitCallable;
    late final NativeCallable<NumberPadModeCallback> numberPadCallable;

    // プレイヤー位置通知用 NativeCallable (マップタップの #herecmdmenu 連動で使用)
    late final NativeCallable<CliparoundCallback> cliparoundCallable;

    // putmixed タイル ID 付き送信用 NativeCallable (`/` 結果リスト表示用)
    late final NativeCallable<PutMixedWithTileCallback> putMixedCallable;

    // Cコアデバッグログ中継用 NativeCallable
    late final NativeCallable<DartLogCallback> logCallable;

    // 新階層リワード用 NativeCallable
    late final NativeCallable<NewLevelRestCallback> newLevelRestCallable;

    // 効果音・サウンド再生用 NativeCallable
    late final NativeCallable<DartSoundEventCallback> soundEventCallable;

    void wlog(String text) {
      uiSendPort.send({'type': 'worker_log', 'text': text});
    }

    try {
      wlog("Worker Isolate start method running. Initializing NativeCallables...");

    // NativeCallable の初期化（Isolate 起動時に1回だけ永続化して生成）
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

    displayCallable = NativeCallable<DisplayWindowCallback>.listener((int winId, int blocking, int isPlain) {
      wlog("displayCallable: winId=$winId, blocking=$blocking");
      uiSendPort.send({
        'type': 'displayWindow',
        'winId': winId,
        'blocking': blocking,
        'isPlain': isPlain,
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
      if (msgPtr == nullptr) {
        return;
      }
      final msg = _utf8DecodeLossy(msgPtr);
      uiSendPort.send({
        'type': 'putstr',
        'winId': winId,
        'attr': attr,
        'text': msg,
      });
    });

    glyphCallable = NativeCallable<PrintGlyphCallback>.listener((int winId, int x, int y, int tile, int ch, int color, int special, int bktile) {
      uiSendPort.send({
        'type': 'printGlyph',
        'winId': winId,
        'x': x,
        'y': y,
        'tile': tile,
        'ch': ch,
        'color': color,
        'special': special,
        'bktile': bktile,
      });
    });

    inputCallable = NativeCallable<NotifyInputCallback>.listener((int requestId) {
      final gameover = (session?.ffi?.getIsGameOver() ?? 0) != 0;
      wlog("inputCallable: requestId=$requestId, gameover=$gameover");
      uiSendPort.send({
        'type': 'request_input',
        'gameover': gameover,
      });
    });

    // メニュー関連コールバックの初期化
    startMenuCallable = NativeCallable<StartMenuCallback>.listener((int winId) {
      wlog("startMenuCallable invoked: winId=$winId");
      uiSendPort.send({
        'type': 'startMenu',
        'winId': winId,
      });
    });

    addMenuCallable = NativeCallable<AddMenuCallback>.listener((
      int winId,
      int ident,
      int accelerator,
      int groupacc,
      int attr,
      Pointer<Utf8> strPtr,
      int preselected,
      int color,
      int tile,
    ) {
      final str = _utf8DecodeLossy(strPtr);
      uiSendPort.send({
        'type': 'addMenu',
        'winId': winId,
        'ident': ident,
        'accelerator': accelerator,
        'groupacc': groupacc,
        'attr': attr,
        'text': str,
        'preselected': preselected,
        'color': color,
        'tile': tile,
      });
    });

    endMenuCallable = NativeCallable<EndMenuCallback>.listener((int winId, Pointer<Utf8> promptPtr) {
      final prompt = _utf8DecodeLossy(promptPtr);
      wlog("endMenuCallable invoked: winId=$winId, prompt='$prompt'");
      uiSendPort.send({
        'type': 'endMenu',
        'winId': winId,
        'prompt': prompt,
      });
    });

    selectMenuCallable = NativeCallable<SelectMenuCallback>.listener((int winId, int how) {
      wlog("selectMenuCallable invoked: winId=$winId, how=$how");
      uiSendPort.send({
        'type': 'selectMenu',
        'winId': winId,
        'how': how,
      });
    });

    // 同期待信用コールバックの初期化
    ynCallable = NativeCallable<YnFunctionCallback>.listener((Pointer<Utf8> questionPtr, Pointer<Utf8> choicesPtr, int def) {
      final question = _utf8DecodeLossy(questionPtr);
      final choices = choicesPtr != nullptr ? choicesPtr.toDartString() : "";
      wlog("ynCallable invoked: question='$question'");
      uiSendPort.send({
        'type': 'yn_function',
        'question': question,
        'choices': choices,
        'def': def,
      });
    });

    getlineCallable = NativeCallable<GetLineCallback>.listener((Pointer<Utf8> promptPtr, Pointer<Utf8> initTextPtr) {
      final prompt = _utf8DecodeLossy(promptPtr);
      final initText = _utf8DecodeLossy(initTextPtr);
      wlog("getlineCallable invoked: prompt='$prompt'");
      uiSendPort.send({
        'type': 'getline',
        'prompt': prompt,
        'initText': initText,
      });
    });

    asknameCallable = NativeCallable<AskNameCallback>.listener((Pointer<Utf8> savesPtr, int maxChars) {
      final saves = _utf8DecodeLossy(savesPtr);
      wlog("asknameCallable invoked: saves='$saves', maxChars=$maxChars");
      uiSendPort.send({
        'type': 'askname',
        'saves': saves,
        'maxChars': maxChars,
      });
    });

    exitCallable = NativeCallable<ExitCallback>.listener((Pointer<Utf8> msgPtr) {
      final msg = _utf8DecodeLossy(msgPtr);
      wlog("exitCallable invoked: msg='$msg'");
      uiSendPort.send({
        'type': 'game_exit',
        'message': msg,
      });
    });

    numberPadCallable = NativeCallable<NumberPadModeCallback>.listener((int state) {
      uiSendPort.send({
        'type': 'number_pad_mode',
        'state': state,
      });
    });

    cliparoundCallable = NativeCallable<CliparoundCallback>.listener((int x, int y, int playerX, int playerY) {
      uiSendPort.send({
        'type': 'cliparound',
        'x': x,
        'y': y,
        'playerX': playerX,
        'playerY': playerY,
      });
    });

    putMixedCallable = NativeCallable<PutMixedWithTileCallback>.listener(
      (int winId, int attr, int tile, Pointer<Utf8> msgPtr) {
        if (msgPtr == nullptr) {
          return;
        }
        final msg = _utf8DecodeLossy(msgPtr);
        uiSendPort.send({
          'type': 'putMixed',
          'winId': winId,
          'attr': attr,
          'tile': tile,
          'text': msg,
        });
      },
    );

    logCallable = NativeCallable<DartLogCallback>.listener((Pointer<Utf8> msgPtr) {
      if (msgPtr != nullptr) {
        final msg = _utf8DecodeLossy(msgPtr);
        wlog("[C-Core Log] $msg");
        if (msg.startsWith("CONFIG_ERROR_ALERT:")) {
          final alertText = msg.substring("CONFIG_ERROR_ALERT:".length);
          uiSendPort.send({
            'type': 'config_error_alert',
            'message': alertText,
          });
        }
      }
    });

    newLevelRestCallable = NativeCallable<NewLevelRestCallback>.listener(() {
      uiSendPort.send({
        'type': 'new_level_rest',
      });
    });

    soundEventCallable = NativeCallable<DartSoundEventCallback>.listener((
      int category,
      Pointer<Utf8> filenamePtr,
      Pointer<Utf8> textPtr,
      int volume,
      int loopOrFlag,
    ) {
      final filename = filenamePtr != nullptr ? _utf8DecodeLossy(filenamePtr) : '';
      final text = textPtr != nullptr ? _utf8DecodeLossy(textPtr) : '';
      uiSendPort.send({
        'type': 'sound_event',
        'category': category,
        'filename': filename,
        'text': text,
        'volume': volume,
        'loopOrFlag': loopOrFlag,
      });
    });

    final activeSession = NetHackWorkerSession(
      onLog: wlog,
      onSendToUi: uiSendPort.send,
      registerCallbacks: (loadedFfi) {
        loadedFfi.registerDartLog(logCallable.nativeFunction);

        final structPtr = calloc<FlutterCallbacksStruct>();
        try {
          structPtr.ref.createCb = createCallable.nativeFunction;
          structPtr.ref.clearCb = clearCallable.nativeFunction;
          structPtr.ref.displayCb = displayCallable.nativeFunction;
          structPtr.ref.destroyCb = destroyCallable.nativeFunction;
          structPtr.ref.cursCb = cursCallable.nativeFunction;
          structPtr.ref.putstrCb = putstrCallable.nativeFunction;
          structPtr.ref.glyphCb = glyphCallable.nativeFunction;
          structPtr.ref.inputCb = inputCallable.nativeFunction;
          structPtr.ref.startMenuCb = startMenuCallable.nativeFunction;
          structPtr.ref.addMenuCb = addMenuCallable.nativeFunction;
          structPtr.ref.endMenuCb = endMenuCallable.nativeFunction;
          structPtr.ref.selectMenuCb = selectMenuCallable.nativeFunction;
          structPtr.ref.ynCb = ynCallable.nativeFunction;
          structPtr.ref.getlineCb = getlineCallable.nativeFunction;
          structPtr.ref.asknameCb = asknameCallable.nativeFunction;
          structPtr.ref.exitCb = exitCallable.nativeFunction;
          structPtr.ref.numberPadCb = numberPadCallable.nativeFunction;
          structPtr.ref.cliparoundCb = cliparoundCallable.nativeFunction;
          structPtr.ref.putMixedCb = putMixedCallable.nativeFunction;
          structPtr.ref.newLevelRestCb = newLevelRestCallable.nativeFunction;
          structPtr.ref.soundEventCb = soundEventCallable.nativeFunction;

          wlog("Calling ffi.registerCallbacksStruct...");
          loadedFfi.registerCallbacksStruct(structPtr);
          wlog("ffi.registerCallbacksStruct returned.");
        } finally {
          wlog("Freeing structPtr...");
          calloc.free(structPtr);
          wlog("calloc.free completed.");
        }
      },
    );
    session = activeSession;

    receivePort.listen(activeSession.handleMessage);

    wlog("Sending ready message to UI Isolate...");
    uiSendPort.send({'type': 'ready', 'sendPort': receivePort.sendPort});
    wlog("uiSendPort.send ready completed.");
    } catch (e, st) {
      wlog("FATAL WORKER INIT ERROR: $e\n$st");
      uiSendPort.send({
        'type': 'worker_error',
        'error': e.toString(),
        'stack': st.toString(),
        'phase': WorkerErrorPhase.workerInit,
        'coreStarted': false,
      });
    }
  }
}
