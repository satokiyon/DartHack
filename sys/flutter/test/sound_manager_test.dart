import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/sound_manager.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
  });
}
