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
  });
}


