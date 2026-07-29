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

    // 新階層リワード用 NativeCallable
    late final NativeCallable<NewLevelRestCallback> newLevelRestCallable;

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

          displayCallable = NativeCallable<DisplayWindowCallback>.listener((int winId, int blocking, int isPlain) {
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
            uiSendPort.send({
              'type': 'request_input',
              'gameover': gameover,
            });
          });

          // メニュー関連コールバックの初期化
          startMenuCallable = NativeCallable<StartMenuCallback>.listener((int winId) {
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
            uiSendPort.send({
              'type': 'endMenu',
              'winId': winId,
              'prompt': prompt,
            });
          });

          selectMenuCallable = NativeCallable<SelectMenuCallback>.listener((int winId, int how) {
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
            uiSendPort.send({
              'type': 'getline',
              'prompt': prompt,
              'initText': initText,
            });
          });

          asknameCallable = NativeCallable<AskNameCallback>.listener((Pointer<Utf8> savesPtr, int maxChars) {
            final saves = _utf8DecodeLossy(savesPtr);
            uiSendPort.send({
              'type': 'askname',
              'saves': saves,
              'maxChars': maxChars,
            });
          });

          exitCallable = NativeCallable<ExitCallback>.listener((Pointer<Utf8> msgPtr) {
            final msg = _utf8DecodeLossy(msgPtr);
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

          // プレイヤー位置通知: C 側から (x, y, u.ux-1, u.uy) を受け取り
          // Dart 側に転送。マップの主人公タップ検出 (#herecmdmenu) で利用する。
          // C 側でマップグリッド座標系 (0-based) に変換済み。
          cliparoundCallable = NativeCallable<CliparoundCallback>.listener((int x, int y, int playerX, int playerY) {
            uiSendPort.send({
              'type': 'cliparound',
              'x': x,
              'y': y,
              'playerX': playerX,
              'playerY': playerY,
            });
          });

          // putmixed タイル ID 付き送信: C 側の `look_all` / `look_traps` /
          // `look_engrs` 結果リストから、 タイル ID 付きのテキスト (例:
          // "(12,05)  \G00560042  ジャッカル") を受け取り Dart 側に転送する。
          // Dart 側は \G をパースしてタイル列を表示する。
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

          newLevelRestCallable = NativeCallable<NewLevelRestCallback>.listener(() {
            uiSendPort.send({
              'type': 'new_level_rest',
            });
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
            startMenuCallable.nativeFunction,
            addMenuCallable.nativeFunction,
            endMenuCallable.nativeFunction,
            selectMenuCallable.nativeFunction,
            ynCallable.nativeFunction,
            getlineCallable.nativeFunction,
            asknameCallable.nativeFunction,
            exitCallable.nativeFunction,
            numberPadCallable.nativeFunction,
            cliparoundCallable.nativeFunction,
            putMixedCallable.nativeFunction,
          );

          ffi.registerNewLevelRest(newLevelRestCallable.nativeFunction);

          // NetHack コアを起動
          final pathPtr = assetsPath.toNativeUtf8();
          final userPtr = "Player".toNativeUtf8();
          
          ffi.startNetHack(pathPtr, userPtr);
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
    });
  }
}
