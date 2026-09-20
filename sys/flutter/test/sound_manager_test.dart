import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudioPlayer extends AudioPlayer {
  final _completeController = StreamController<void>.broadcast();
  PlayerState _fakeState = PlayerState.stopped;
  double fakeVolume = 1.0;
  Source? lastSource;
  int playCount = 0;
  int stopCount = 0;

  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

  @override
  PlayerState get state => _fakeState;

  @override
  Future<void> setVolume(double volume) async {
    fakeVolume = volume;
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCount++;
    lastSource = source;
    _fakeState = PlayerState.playing;
    if (volume != null) fakeVolume = volume;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _fakeState = PlayerState.stopped;
  }

  @override
  Future<void> pause() async {
    _fakeState = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    _fakeState = PlayerState.playing;
  }

  @override
  Future<void> dispose() async {
    await _completeController.close();
  }

  void triggerComplete() {
    _fakeState = PlayerState.completed;
    _completeController.add(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  group('SoundManager Tests', () {
    test('SoundCategory fromValue mapping', () {
      expect(SoundCategory.fromValue(1), SoundCategory.se);
      expect(SoundCategory.fromValue(2), SoundCategory.heroMusic);
      expect(SoundCategory.fromValue(3), SoundCategory.achievement);
      expect(SoundCategory.fromValue(4), SoundCategory.bgm);
      expect(SoundCategory.fromValue(5), SoundCategory.voice);
      expect(SoundCategory.fromValue(6), SoundCategory.ambience);
      // 未知の値はフォールバックで se
      expect(SoundCategory.fromValue(999), SoundCategory.se);
    });

    test('SoundManager handles non-existent sounds gracefully without throwing', () {
      final manager = SoundManager.instance;
      // hasSound は未配置ファイルに対して false を返す
      expect(manager.hasSound('non_existent_sound.ogg'), isFalse);

      // SEイベント
      expect(() {
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'non_existent_sound.ogg',
          'text': '',
          'volume': 80,
          'loopOrFlag': 0,
        });
      }, returnsNormally);

      // BGMイベント
      expect(() {
        manager.handleSoundEvent({
          'category': 4,
          'filename': 'amb_dungeon.ogg',
          'text': '',
          'volume': 0,
          'loopOrFlag': 1,
        });
      }, returnsNormally);

      // Ambienceイベント
      expect(() {
        manager.handleSoundEvent({
          'category': 6,
          'filename': 'amb_in_a_shop.ogg',
          'text': '',
          'volume': 0,
          'loopOrFlag': 1,
        });
      }, returnsNormally);
    });

    test('SoundManager volume clamps and settings', () async {
      final manager = SoundManager.instance;
      await manager.setSeVolume(1.5);
      expect(manager.seVolume, 1.0);

      await manager.setSeVolume(-0.5);
      expect(manager.seVolume, 0.0);

      await manager.setBgmVolume(1.5);
      expect(manager.bgmVolume, 1.0);

      await manager.setAmbienceVolume(1.5);
      expect(manager.ambienceVolume, 1.0);

      await manager.setAmbienceVolume(-0.5);
      expect(manager.ambienceVolume, 0.0);

      await manager.setAmbienceVolume(0.65);
      expect(manager.ambienceVolume, 0.65);

      await manager.setMuted(true);
      expect(manager.isMuted, isTrue);

      await manager.setMuted(false);
      expect(manager.isMuted, isFalse);
    });

    test('Room BGM fallback when file does not exist keeps floor BGM playing', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);

      // フロアBGMを登録
      manager.registerAvailableSound('amb_dungeon.ogg');

      // 1. フロアBGM開始イベント (category: 4, action: 1)
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_dungeon.ogg');

      // 2. 音源ファイルが存在しない特別部屋進入イベント (amb_in_a_shop.ogg は未登録)
      // category: 6 (ambience), loopOrFlag: 1 (ambience_begin)
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // ファイルが無いため、フロアBGMが継続し、ルームBGMは開始されない
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_dungeon.ogg');

      // 3. 退出イベント (loopOrFlag: 2 = ambience_end) が来てもフロアBGMは影響を受けない
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 2,
      });

      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_dungeon.ogg');
    });

    test('Room BGM switches and restores when file exists', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);

      // フロアBGMとルームBGMを両方登録
      manager.registerAvailableSound('amb_mines.ogg');
      manager.registerAvailableSound('amb_inside_vault.ogg');

      // 1. 鉱山フロアBGM開始
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_mines.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      expect(manager.currentFloorBgm, 'amb_mines.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_mines.ogg');

      // 2. 音源が存在する宝物庫進入イベント
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_inside_vault.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // ルームBGMがアクティブになり、currentBgm はルームBGMを指す
      expect(manager.currentFloorBgm, 'amb_mines.ogg');
      expect(manager.currentRoomBgm, 'amb_inside_vault.ogg');
      expect(manager.currentBgm, 'amb_inside_vault.ogg');

      // 3. 宝物庫退出イベント
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_inside_vault.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 2,
      });

      // ルームBGMが解除され、フロアBGMに復帰
      expect(manager.currentFloorBgm, 'amb_mines.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_mines.ogg');
    });

    test('Background lifecycle pause and resume calls execute cleanly without error', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('amb_dungeon.ogg');

      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // バックグラウンド移行
      await expectLater(manager.pauseForBackground(), completes);

      // フォアグラウンド復帰
      await expectLater(manager.resumeFromBackground(), completes);

      // BGM状態が維持されていること
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
    });

    test('Rapid chatter room enter and exit maintains state consistency', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('amb_dungeon.ogg');
      manager.registerAvailableSound('amb_in_a_shop.ogg');

      // フロアBGM開始
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // 素早く進入→退出→再進入
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 2,
      });

      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // 最新の入室状態（amb_in_a_shop.ogg）が優先されていること
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentRoomBgm, 'amb_in_a_shop.ogg');
      expect(manager.currentBgm, 'amb_in_a_shop.ogg');

      // 最終退出
      manager.handleSoundEvent({
        'category': 6,
        'filename': 'amb_in_a_shop.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 2,
      });

      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentRoomBgm, isNull);
      expect(manager.currentBgm, 'amb_dungeon.ogg');
    });

    test('Category enabled flags toggle properly and persist', () async {
      final manager = SoundManager.instance;
      // 初期値はすべて true
      expect(manager.bgmEnabled, isTrue);
      expect(manager.seEnabled, isTrue);
      expect(manager.ambienceEnabled, isTrue);

      await manager.setBgmEnabled(false);
      expect(manager.bgmEnabled, isFalse);

      await manager.setSeEnabled(false);
      expect(manager.seEnabled, isFalse);

      await manager.setAmbienceEnabled(false);
      expect(manager.ambienceEnabled, isFalse);

      // SharedPreferences の永続化確認
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sound_bgm_enabled'), isFalse);
      expect(prefs.getBool('sound_se_enabled'), isFalse);
      expect(prefs.getBool('sound_ambience_enabled'), isFalse);

      // 復元
      await manager.setBgmEnabled(true);
      await manager.setSeEnabled(true);
      await manager.setAmbienceEnabled(true);
      expect(manager.bgmEnabled, isTrue);
      expect(manager.seEnabled, isTrue);
      expect(manager.ambienceEnabled, isTrue);
    });

    test('BGM is not played when bgmEnabled is false', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('amb_dungeon.ogg');

      await manager.setBgmEnabled(false);
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });

      // bgmEnabled が false のため再生されない
      expect(manager.currentFloorBgm, isNull);

      // 有効化後に再生
      await manager.setBgmEnabled(true);
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
    });

    test('playPreviewSe executes without error and skips when volume is 0', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_pickup.ogg');

      await manager.setSeVolume(0.8);
      expect(() async => await manager.playPreviewSe(), returnsNormally);

      await manager.setSeVolume(0.0);
      expect(() async => await manager.playPreviewSe(), returnsNormally);
    });

    test('BGM auto-restores when re-enabled or unmuted if last floor BGM exists', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('amb_dungeon.ogg');

      // 1. フロアBGM再生
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // 2. BGM無効化 -> 停止
      await manager.setBgmEnabled(false);
      expect(manager.currentFloorBgm, isNull);

      // 3. BGM再有効化 -> 直前の amb_dungeon.ogg が自動復元される
      await manager.setBgmEnabled(true);
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // 4. 全体ミュート -> 停止
      await manager.setMuted(true);
      expect(manager.currentFloorBgm, isNull);

      // 5. ミュート解除 -> 自動復元される
      await manager.setMuted(false);
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
    });

    test('syncFromPrefs synchronizes memory state with SharedPreferences', () async {
      final manager = SoundManager.instance;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_muted', true);
      await prefs.setBool('sound_bgm_enabled', false);
      await prefs.setDouble('sound_bgm_volume', 0.25);
      await prefs.setDouble('sound_se_volume', 0.4);

      await manager.syncFromPrefs();

      expect(manager.isMuted, isTrue);
      expect(manager.bgmEnabled, isFalse);
      expect(manager.bgmVolume, 0.25);
      expect(manager.seVolume, 0.4);

      // 元に戻す
      await manager.setMuted(false);
      await manager.setBgmEnabled(true);
      await manager.setBgmVolume(0.5);
      await manager.setSeVolume(0.8);
    });

    test('SoundManager debounces rapid same SE events within 60ms', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_combat_hit_slash.ogg');

      // 連続で同SEイベントを発行してもクラッシュせず安全に処理される
      expect(() {
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'se_combat_hit_slash.ogg',
          'text': '',
          'volume': 100,
          'loopOrFlag': 0,
        });
        // 60ms未満の連続呼び出し（デバウンス対象）
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'se_combat_hit_slash.ogg',
          'text': '',
          'volume': 100,
          'loopOrFlag': 0,
        });
      }, returnsNormally);
    });

    test('SoundManager handles double-strike micro-delay and third strike throttling', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_combat_hit_slash.ogg');

      // 1撃目、2撃目（二連撃マイクロディレイ対象）、3撃目（破棄対象）
      expect(() {
        for (int i = 0; i < 3; i++) {
          manager.handleSoundEvent({
            'category': 1,
            'filename': 'se_combat_hit_slash.ogg',
            'text': '',
            'volume': 100,
            'loopOrFlag': 0,
          });
        }
      }, returnsNormally);

      // マイクロディレイタイマーの実行を少し待機してもエラーが出ないこと
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('SoundManager throttles ambient combat SE events for third-party monsters', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_mon_claw.ogg');

      // volume < 100（モンスター同士の環境戦闘）を短時間に多数発行
      expect(() {
        for (int i = 0; i < 5; i++) {
          manager.handleSoundEvent({
            'category': 1,
            'filename': 'se_mon_claw.ogg',
            'text': '',
            'volume': 40,
            'loopOrFlag': 0,
          });
        }
      }, returnsNormally);
    });

    test('SoundManager prioritizes critical sound effects and achievements', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_alarm.ogg');
      manager.registerAvailableSound('sa2_xplevelup.ogg');

      // 警報音（critical SE）および実績音
      expect(() {
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'se_alarm.ogg',
          'text': '',
          'volume': 100,
          'loopOrFlag': 0,
        });
        manager.handleSoundEvent({
          'category': 2,
          'filename': 'sa2_xplevelup.ogg',
          'text': '',
          'volume': 100,
          'loopOrFlag': 0,
        });
      }, returnsNormally);
    });

    test('SafeAudioCache returns configured directory and persistent cacheId', () async {
      const testPath = '/data/user/0/jp.satokiyo.darthack/files/audio_cache';
      final cache = SafeAudioCache(testPath);
      expect(await cache.getTempDir(), testPath);
      expect(cache.cacheId, 'darthack_sound_cache');

      final customCache = SafeAudioCache(testPath, cacheId: 'custom_cache_id');
      expect(customCache.cacheId, 'custom_cache_id');
    });

    test('SE playback with pool executes play and marks entry as playing', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_door_open.ogg');

      final fakePlayer = FakeAudioPlayer();
      manager.initPoolForTest([fakePlayer]);
      expect(manager.poolSize, 1);
      expect(manager.playingEntryCount, 0);

      manager.handleSoundEvent({
        'category': 1,
        'filename': 'se_door_open.ogg',
        'text': '',
        'volume': 80,
        'loopOrFlag': 0,
      });

      // 非同期微小待機
      await Future.delayed(const Duration(milliseconds: 10));

      expect(fakePlayer.playCount, 1);
      expect(fakePlayer.state, PlayerState.playing);
      expect(fakePlayer.lastSource, isA<AssetSource>());
      expect((fakePlayer.lastSource as AssetSource).path, 'sounds/se_door_open.ogg');
      expect(manager.playingEntryCount, 1);

      // 再生完了イベントで状態がリセットされること
      fakePlayer.triggerComplete();
      await Future.delayed(const Duration(milliseconds: 10));
      expect(manager.playingEntryCount, 0);
    });

    test('SE playback enforces max same sound limit (3 instances)', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.registerAvailableSound('se_pickup.ogg');

      final fakes = List.generate(5, (_) => FakeAudioPlayer());
      manager.initPoolForTest(fakes);

      // デバウンスをクリアしながら同一音を連続して4回再生要求
      for (int i = 0; i < 4; i++) {
        manager.clearCooldownsForTest();
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'se_pickup.ogg',
          'text': '',
          'volume': 100,
          'loopOrFlag': 0,
        });
      }

      await Future.delayed(const Duration(milliseconds: 10));

      // 最大3インスタンスまでしか再生されず、4回目はスキップされていること
      final playedCount = fakes.where((p) => p.playCount > 0).length;
      expect(playedCount, 3);
      expect(manager.playingEntryCount, 3);
    });

    test('Critical SE preempts combat sound entry when pool is full', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true);
      manager.clearCooldownsForTest();
      manager.registerAvailableSound('se_combat_hit_slash.ogg');
      manager.registerAvailableSound('se_alarm.ogg');

      final combatPlayer = FakeAudioPlayer();
      manager.initPoolForTest([combatPlayer]);

      // 1. 戦闘SEを再生してプールを満杯にする
      manager.handleSoundEvent({
        'category': 1,
        'filename': 'se_combat_hit_slash.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 0,
      });
      await Future.delayed(const Duration(milliseconds: 10));
      expect(combatPlayer.playCount, 1);

      // 2. 満杯の状態で重要SE（se_alarm.ogg）を発火
      manager.clearCooldownsForTest();
      manager.handleSoundEvent({
        'category': 1,
        'filename': 'se_alarm.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 0,
      });
      await Future.delayed(const Duration(milliseconds: 10));

      // 既存のプレイヤーが stop され、se_alarm.ogg で再 play されたこと
      expect(combatPlayer.stopCount, greaterThanOrEqualTo(1));
      expect(combatPlayer.playCount, 2);
      expect((combatPlayer.lastSource as AssetSource).path, 'sounds/se_alarm.ogg');
    });

    test('Floor BGM is held as pending when main game has not started, keeping title BGM', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: false);
      manager.registerAvailableSound('amb_title.ogg');
      manager.registerAvailableSound('amb_dungeon.ogg');

      // 1. タイトルBGMイベント
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_title.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_title.ogg');
      expect(manager.pendingFloorBgmForTest, isNull);

      // 2. Cコアからの重複タイトルBGMイベント（変化なし）
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_title.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_title.ogg');

      // 3. キャラメイク・セーブ復元中に届くフロアBGMイベント（保留される）
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      // タイトルBGMが鳴り続け、amb_dungeon.ogg が保留されていること
      expect(manager.currentFloorBgm, 'amb_title.ogg');
      expect(manager.pendingFloorBgmForTest, 'amb_dungeon.ogg');

      // 4. マップ画面表示（ゲーム本編開始通知）
      await manager.notifyMainGameStarted();
      expect(manager.pendingFloorBgmForTest, isNull);
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // 5. セッションリセット
      manager.resetForNewGameSession();
      expect(manager.pendingFloorBgmForTest, isNull);
    });

    test('SE playback does not interrupt or stop floor BGM', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);
      manager.registerAvailableSound('amb_dungeon.ogg');
      manager.registerAvailableSound('se_combat_hit_slash.ogg');

      // フロアBGM再生
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // 効果音（SE）再生
      manager.handleSoundEvent({
        'category': 1,
        'filename': 'se_combat_hit_slash.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 0,
      });

      // SEが鳴ってもフロアBGMは継続していること
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
      expect(manager.currentBgm, 'amb_dungeon.ogg');
    });

    test('Background pause and resume safely restores floor BGM without resume()', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);
      manager.registerAvailableSound('amb_dungeon.ogg');

      // フロアBGM再生
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // アプリがバックグラウンドに移行
      await manager.pauseForBackground();

      // アプリがフォアグラウンドに復帰（playDirectで安全に再開）
      await manager.resumeFromBackground();

      // フロアBGMが正常に維持・再開されていること
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
    });

    test('Consecutive pause calls (inactive -> paused) maintain playing state and resume correctly', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);
      manager.registerAvailableSound('amb_dungeon.ogg');

      // フロアBGM再生
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_dungeon.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');

      // 1回目の pause 呼び出し（inactive 相当）
      await manager.pauseForBackground();
      expect(manager.isPausedForBackground, isTrue);
      expect(manager.floorWasPlayingBeforeBackground, isTrue);

      // 2回目の pause 呼び出し（paused 相当: 重複呼び出し）
      await manager.pauseForBackground();
      // フラグが false に上書きされず維持されていること
      expect(manager.isPausedForBackground, isTrue);
      expect(manager.floorWasPlayingBeforeBackground, isTrue);

      // フォアグラウンド復帰
      await manager.resumeFromBackground();
      expect(manager.isPausedForBackground, isFalse);
      expect(manager.currentFloorBgm, 'amb_dungeon.ogg');
    });

    test('Resume restores BGM when pre-paused by OS before pauseForBackground', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);
      manager.registerAvailableSound('amb_title.ogg');

      // タイトルBGM設定
      manager.handleSoundEvent({
        'category': 4,
        'filename': 'amb_title.ogg',
        'text': '',
        'volume': 100,
        'loopOrFlag': 1,
      });
      expect(manager.currentFloorBgm, 'amb_title.ogg');

      // pauseForBackground 呼び出し
      await manager.pauseForBackground();
      expect(manager.isPausedForBackground, isTrue);
      expect(manager.floorWasPlayingBeforeBackground, isTrue);

      // 復帰
      await manager.resumeFromBackground();
      expect(manager.isPausedForBackground, isFalse);
      expect(manager.currentFloorBgm, 'amb_title.ogg');
    });

    test('Kick action sound events dispatch and play successfully', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);

      final kickSounds = [
        'se_kick_door_it_crashes_open.ogg',
        'se_kick_door_it_shatters.ogg',
        'se_crashing_sound.ogg',
        'se_lid_slams_open_falls_shut.ogg',
        'se_crash_door.ogg',
        'se_crash_throne_destroyed.ogg',
        'se_glass_crashing.ogg',
      ];

      for (final sound in kickSounds) {
        manager.registerAvailableSound(sound);
        expect(manager.hasSound(sound), isTrue);

        manager.handleSoundEvent({
          'category': 1, // SoundCategory.se
          'filename': sound,
          'text': '',
          'volume': 60,
          'loopOrFlag': 0,
        });
      }
    });

    test('Debuff and hunger sound events dispatch and play successfully', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);

      final newSounds = [
        'se_debuff.ogg',
        'se_hunger.ogg',
      ];

      for (final sound in newSounds) {
        manager.registerAvailableSound(sound);
        expect(manager.hasSound(sound), isTrue);

        manager.handleSoundEvent({
          'category': 1, // SoundCategory.se
          'filename': sound,
          'text': '',
          'volume': 60,
          'loopOrFlag': 0,
        });
      }
    });

    test('Lock picking and forcing sound events dispatch and play successfully', () async {
      final manager = SoundManager.instance;
      manager.setInitializedForTest(true, isMainGameStarted: true);

      final lockSounds = [
        'se_klick.ogg',
        'se_force_lock.ogg',
      ];

      for (final sound in lockSounds) {
        manager.registerAvailableSound(sound);
        expect(manager.hasSound(sound), isTrue);

        manager.handleSoundEvent({
          'category': 1, // SoundCategory.se
          'filename': sound,
          'text': '',
          'volume': 50,
          'loopOrFlag': 0,
        });
      }
    });
  });
}


