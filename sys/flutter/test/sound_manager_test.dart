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
      // 未知の値はフォールバックで se
      expect(SoundCategory.fromValue(999), SoundCategory.se);
    });

    test('SoundManager handles non-existent sounds gracefully without throwing', () {
      final manager = SoundManager.instance;
      // hasSound は未配置ファイルに対して false を返す
      expect(manager.hasSound('non_existent_sound.ogg'), isFalse);

      // handleSoundEvent を呼んでも例外が発生せず安全にスキップされること
      expect(() {
        manager.handleSoundEvent({
          'category': 1,
          'filename': 'non_existent_sound.ogg',
          'text': '',
          'volume': 80,
          'loopOrFlag': 0,
        });
      }, returnsNormally);
    });

    test('SoundManager volume clamps and settings', () async {
      final manager = SoundManager.instance;
      await manager.setSeVolume(1.5);
      expect(manager.seVolume, 1.0);

      await manager.setSeVolume(-0.5);
      expect(manager.seVolume, 0.0);

      await manager.setSeVolume(0.7);
      expect(manager.seVolume, 0.7);

      await manager.setMuted(true);
      expect(manager.isMuted, isTrue);

      await manager.setMuted(false);
      expect(manager.isMuted, isFalse);
    });
  });
}
