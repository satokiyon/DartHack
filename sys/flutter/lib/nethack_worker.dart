import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'nethack_ffi.dart';

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

    void wlog(String text) {
      print("[WorkerLog Direct] $text");
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
      final gameover = ffi.getIsGameOver() != 0;
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

    // FFI とコールバックの初期化（1回のみ）
    wlog("Initializing NetHackFfi and registering callbacks via struct...");
    ffi = NetHackFfi();

    ffi.registerDartLog(logCallable.nativeFunction);

    final structPtr = calloc<FlutterCallbacksStruct>();
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

    wlog("Calling ffi.registerCallbacksStruct...");
    ffi.registerCallbacksStruct(structPtr);
    wlog("ffi.registerCallbacksStruct returned.");

    wlog("Freeing structPtr...");
    calloc.free(structPtr);
    wlog("calloc.free completed.");

    wlog("Sending ready message to UI Isolate...");
    uiSendPort.send({'type': 'ready', 'sendPort': receivePort.sendPort});
    wlog("uiSendPort.send ready completed.");

    receivePort.listen((message) {
      try {
        wlog("Received message in Worker Isolate: $message");
        if (message is Map) {
          final type = message['type'];
          if (type == 'start') {
            final assetsPath = message['assetsPath'] as String;
            final pathPtr = assetsPath.toNativeUtf8();
            final userPtr = "Player".toNativeUtf8();
            
            wlog("Calling ffi.startNetHack with path='$assetsPath'...");
            ffi.startNetHack(pathPtr, userPtr);
            wlog("ffi.startNetHack returned.");
          } else if (type == 'key') {
          final key = message['key'] as int;
          ffi.sendKeyToC(key);
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
                ffi.sendKeysToC(ptr, length);
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
                ffi.sendShortcutToC(ptr, length);
              } finally {
                calloc.free(ptr);
              }
            }
          }
        } else if (type == 'pos_cmd') {
          final x = message['x'] as int;
          final y = message['y'] as int;
          final mod = message['mod'] as int? ?? 1;
          ffi.sendPosCmdToC(x, y, mod);
        } else if (type == 'menu_select') {
          final ident = message['ident'] as int;
          final count = message['count'] as int? ?? 1;
          ffi.sendMenuSelection(ident, count);
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
          ffi.sendMenuSelections(csv);
          calloc.free(csv);
        } else if (type == 'yn_result') {
          final result = message['result'] as int;
          ffi.sendYnResult(result);
        } else if (type == 'new_level_rest_result') {
          final rewardAmount = message['rewardAmount'] as int? ?? 0;
          ffi.sendNewLevelRestResult(rewardAmount);
        } else if (type == 'getline_result') {
          final result = message['result'] as String?;
          if (result != null) {
            final resultPtr = result.toNativeUtf8();
            ffi.sendGetLineResult(resultPtr);
            calloc.free(resultPtr);
          } else {
            ffi.sendGetLineResult(nullptr);
          }
        } else if (type == 'askname_result') {
          final result = message['result'] as String?;
          final mode = (message['mode'] as int?) ?? 0;
          if (result != null) {
            final resultPtr = result.toNativeUtf8();
            ffi.sendAskNameResult(resultPtr, mode);
            calloc.free(resultPtr);
          } else {
            ffi.sendAskNameResult(nullptr, mode);
          }
        }
        }
      } catch (e, st) {
        print("[NetHackWorker ERROR] Exception in Worker Isolate: $e\n$st");
        uiSendPort.send({'type': 'worker_error', 'error': e.toString(), 'stack': st.toString()});
      }
    });
    } catch (e, st) {
      wlog("FATAL WORKER INIT ERROR: $e\n$st");
      uiSendPort.send({'type': 'worker_error', 'error': e.toString(), 'stack': st.toString()});
    }
  }
}
