import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_ffi.dart';
import 'package:darthack/nethack_worker.dart';

/// ネイティブライブラリに依存せず Worker セッションの呼び出し順とガードを検証するためのフェイク FFI
class _FakeNetHackFfi implements NetHackFfi {
  final List<String> callLog;
  bool throwOnSendKey = false;

  _FakeNetHackFfi(this.callLog);

  void _setLanguageMode(int isJp) {
    callLog.add('setLanguageMode:$isJp');
  }

  @override
  SetLanguageModeDart get setLanguageMode => _setLanguageMode;

  void _setAutosaveSettings(int enabled, int interval) {
    callLog.add('setAutosaveSettings:$enabled:$interval');
  }

  @override
  SetAutosaveSettingsDart get setAutosaveSettings => _setAutosaveSettings;

  void _startNetHack(Pointer<Utf8> pathPtr, Pointer<Utf8> userPtr) {
    callLog.add('startNetHack:${pathPtr.toDartString()}:${userPtr.toDartString()}');
  }

  @override
  StartNetHackDart get startNetHack => _startNetHack;

  void _sendKeyToC(int key) {
    if (throwOnSendKey) {
      throw StateError('Simulated runtime sendKey error');
    }
    callLog.add('sendKeyToC:$key');
  }

  @override
  SendKeyDart get sendKeyToC => _sendKeyToC;

  @override
  void setStatusLayout(String layout) {
    callLog.add('setStatusLayout:$layout');
  }

  @override
  void requestStatusOptionsChange({
    required bool hitpointbar,
    required bool hiliteStatus,
    required bool timeOpt,
    required bool showexp,
    int statuslines = 2,
    bool weaponstatus = false,
    bool armorstatus = false,
    bool terrainstatus = false,
    String statusLayout = 'standard',
  }) {
    callLog.add('requestStatusOptionsChange:$statuslines:$statusLayout');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NetHackWorkerSession 起動シーケンスとガード検証', () {
    late List<String> logs;
    late List<Map<String, dynamic>> uiMessages;
    late List<String> callLog;
    late _FakeNetHackFfi fakeFfi;
    late NetHackWorkerSession session;
    var throwInRegisterCallbacks = false;
    var throwInFfiFactory = false;

    setUp(() {
      logs = <String>[];
      uiMessages = <Map<String, dynamic>>[];
      callLog = <String>[];
      fakeFfi = _FakeNetHackFfi(callLog);
      throwInRegisterCallbacks = false;
      throwInFfiFactory = false;

      session = NetHackWorkerSession(
        onLog: logs.add,
        onSendToUi: uiMessages.add,
        ffiFactory: (langCode) {
          callLog.add('ffiFactory:$langCode');
          if (throwInFfiFactory) {
            throw ArgumentError('Simulated library open failure');
          }
          return fakeFfi;
        },
        registerCallbacks: (_) {
          callLog.add('registerCallbacks');
          if (throwInRegisterCallbacks) {
            throw StateError('Simulated callback registration failure');
          }
        },
      );
    });

    test('start 前に set_status_layout 等が届いても LateInitializationError にならず無視されること', () {
      session.handleMessage({
        'type': 'set_status_layout',
        'status_line_layout': 'single_compact',
      });
      session.handleMessage({
        'type': 'set_autosave_settings',
        'enabled': false,
        'interval': 30,
      });
      session.handleMessage({
        'type': 'request_status_options_change',
        'statuslines': 3,
        'status_line_layout': 'single_all',
      });
      session.handleMessage({'type': 'key', 'key': 104});

      expect(session.ffi, isNull);
      expect(session.isCoreThreadStarted, isFalse);
      expect(uiMessages, isEmpty);
      expect(callLog, isEmpty);
      expect(logs.any((l) => l.contains("Ignoring 'set_status_layout'")), isTrue);
    });

    test('start に同梱された初期設定が startNetHack より前の順序で同期適用されること', () {
      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'en',
        'status_line_layout': 'single_compact',
        'autosave_enabled': false,
        'autosave_interval': 25,
      });

      expect(session.ffi, same(fakeFfi));
      expect(session.isCoreThreadStarted, isTrue);
      expect(session.currentPhase, WorkerErrorPhase.workerRuntime);
      expect(uiMessages, isEmpty);

      expect(callLog, [
        'ffiFactory:en',
        'registerCallbacks',
        'setLanguageMode:0',
        'setStatusLayout:single_compact',
        'setAutosaveSettings:0:25',
        'startNetHack:/data/test/nethackdir:Player',
      ]);
    });

    test('start で任意設定が省略された場合は既定値で初期化されること', () {
      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
      });

      expect(callLog, [
        'ffiFactory:ja',
        'registerCallbacks',
        'setLanguageMode:1',
        'setStatusLayout:standard',
        'setAutosaveSettings:1:50',
        'startNetHack:/data/test/nethackdir:Player',
      ]);
    });

    test('重複した start メッセージは無視され C スレッドを二重起動しないこと', () {
      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });
      callLog.clear();

      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });

      expect(callLog, isEmpty);
      expect(logs.any((l) => l.contains("Ignoring duplicate 'start'")), isTrue);
    });

    test('start 完了後は設定変更や入力メッセージが FFI に転送されること', () {
      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });
      callLog.clear();

      session.handleMessage({
        'type': 'set_status_layout',
        'status_line_layout': 'single_all',
      });
      session.handleMessage({'type': 'key', 'key': 64});

      expect(callLog, [
        'setStatusLayout:single_all',
        'sendKeyToC:64',
      ]);
    });

    test('コア読込失敗時は phase=core_load, coreStarted=false を返すこと', () {
      throwInFfiFactory = true;

      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });

      expect(session.ffi, isNull);
      expect(session.isCoreThreadStarted, isFalse);
      expect(uiMessages, hasLength(1));
      final err = uiMessages.single;
      expect(err['type'], 'worker_error');
      expect(err['phase'], WorkerErrorPhase.coreLoad);
      expect(err['coreStarted'], isFalse);
    });

    test('コールバック登録失敗時は phase=worker_init, coreStarted=false を返し ffi を破棄すること', () {
      throwInRegisterCallbacks = true;

      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });

      expect(session.ffi, isNull);
      expect(session.isCoreThreadStarted, isFalse);
      expect(uiMessages, hasLength(1));
      final err = uiMessages.single;
      expect(err['type'], 'worker_error');
      expect(err['phase'], WorkerErrorPhase.workerInit);
      expect(err['coreStarted'], isFalse);
    });

    test('startNetHack 後のランタイム例外時は phase=worker_runtime, coreStarted=true を返すこと', () {
      session.handleMessage({
        'type': 'start',
        'assetsPath': '/data/test/nethackdir',
        'langCode': 'ja',
      });
      fakeFfi.throwOnSendKey = true;

      session.handleMessage({'type': 'key', 'key': 65});

      expect(session.isCoreThreadStarted, isTrue);
      expect(uiMessages, hasLength(1));
      final err = uiMessages.single;
      expect(err['type'], 'worker_error');
      expect(err['phase'], WorkerErrorPhase.workerRuntime);
      expect(err['coreStarted'], isTrue);
    });
  });

  group('WorkerStartupErrorPresentation エラー表示判定', () {
    test('core_load 失敗時はコア読込エラー文言かつ Worker 終了対象と判定されること', () {
      final jp = WorkerStartupErrorPresentation.fromWorkerMessage(
        message: {
          'phase': WorkerErrorPhase.coreLoad,
          'coreStarted': false,
          'error': 'dlopen failed',
        },
        libraryName: 'libnethack_jp.so',
        isJapanese: true,
      );
      expect(jp.title, 'コア読込エラー');
      expect(jp.message, contains('libnethack_jp.so'));
      expect(jp.details, 'dlopen failed');
      expect(jp.shouldTerminateWorker, isTrue);

      final en = WorkerStartupErrorPresentation.fromWorkerMessage(
        message: {
          'phase': WorkerErrorPhase.coreLoad,
          'coreStarted': false,
          'error': 'dlopen failed',
        },
        libraryName: 'libnethack_en.so',
        isJapanese: false,
      );
      expect(en.title, 'Core Load Error');
      expect(en.message, contains('libnethack_en.so'));
      expect(en.shouldTerminateWorker, isTrue);
    });

    test('worker_init 失敗時はライブラリ読込失敗と誤表示せずワーカー初期化エラーになること', () {
      final jp = WorkerStartupErrorPresentation.fromWorkerMessage(
        message: {
          'phase': WorkerErrorPhase.workerInit,
          'coreStarted': false,
          'error': 'LateInitializationError',
        },
        libraryName: 'libnethack_jp.so',
        isJapanese: true,
      );
      expect(jp.title, 'ゲーム初期化エラー');
      expect(jp.message, isNot(contains('libnethack_jp.so')));
      expect(jp.shouldTerminateWorker, isTrue);

      final en = WorkerStartupErrorPresentation.fromWorkerMessage(
        message: {
          'phase': WorkerErrorPhase.workerInit,
          'coreStarted': false,
          'error': 'Bad state',
        },
        libraryName: 'libnethack_en.so',
        isJapanese: false,
      );
      expect(en.title, 'Game Initialization Error');
      expect(en.message, isNot(contains('libnethack_en.so')));
      expect(en.shouldTerminateWorker, isTrue);
    });

    test('coreStarted=true のランタイム例外は Worker/Port 破棄対象にならないこと', () {
      final runtime = WorkerStartupErrorPresentation.fromWorkerMessage(
        message: {
          'phase': WorkerErrorPhase.workerRuntime,
          'coreStarted': true,
          'error': 'Runtime failure',
        },
        libraryName: 'libnethack_jp.so',
        isJapanese: true,
      );
      expect(runtime.shouldTerminateWorker, isFalse);
    });
  });
}
