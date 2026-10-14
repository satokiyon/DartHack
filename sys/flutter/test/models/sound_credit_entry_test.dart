import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/sound_credit_entry.dart';

void main() {
  group('SoundCreditParser Tests', () {
    const sampleText = '''
NetHack 5.0 / DartHack Sound Attributions and Credits
=======================================================
This file contains licensing and credit information for all audio assets used in DartHack.

File:        se_bars_clonk.ogg
Description: 鉄格子への重い金属衝突音
Source:      Springin' Sound Stock (https://www.springin.org/sound-stock/)
Author:      Springin' Sound Stock
License:     Springin'利用規約（商用可・クレジット不要）
-------------------------------------------------------
File:        se_crash_door.ogg
Description: ドアがドカンと破壊される音（強制突破）
Source:      自作音源（クレジット対象外） ()
Author:      DartHack Sound Team
License:     
Notes:       隠し扉・隠し通路蹴り開け突破音
-------------------------------------------------------
File:        se_door_open.ogg
Description: ドアがギィッと開く音（通常の開扉）
Source:      効果音ラボ (https://soundeffect-lab.info/)
Author:      
License:     効果音ラボ利用規約（商用可・ゲーム組込可・クレジット任意）
-------------------------------------------------------
File:        amb_theme_fake_delphi.ogg
Description: 偽神託所
Source:      その他 (https://gemini.google.com/)
Author:      その他
License:     その他
-------------------------------------------------------
File:        amb_dungeon.ogg
Description: ダンジョン
Source:      PeriTune (https://peritune.com/blog/2019/11/10/pray_organ2/)
Author:      Seiko
License:     CC-BY 4.0
''';

    test('parseSources による提供元・作者・ライセンス・URLの集約が正しく動作する', () {
      final sources = SoundCreditParser.parseSources(sampleText);

      // 自作音源は除外され、4つの提供元に集約される
      expect(sources.length, 4);

      final periTune = sources.firstWhere((s) => s.sourceName == 'PeriTune');
      expect(periTune.author, 'Seiko');
      expect(periTune.license, 'CC-BY 4.0');
      expect(periTune.url, 'https://peritune.com/');

      final soundLab = sources.firstWhere((s) => s.sourceName == '効果音ラボ');
      expect(soundLab.author, '効果音ラボ');
      expect(soundLab.url, 'https://soundeffect-lab.info/');

      final gemini = sources.firstWhere((s) => s.sourceName == 'Google Gemini (AI生成)');
      expect(gemini.author, 'Google Gemini');
      expect(gemini.url, 'https://gemini.google.com/');

      // 「その他」や自作音源が混入していないこと
      for (final src in sources) {
        expect(src.sourceName, isNot(contains('その他')));
        expect(src.sourceName, isNot(contains('自作')));
        expect(src.author, isNot(contains('その他')));
        expect(src.license, isNot(contains('その他')));
      }
    });

    test('parseSources で BGM が正しく抽出され、環境音は除外される', () {
      final sources = SoundCreditParser.parseSources(sampleText);
      final periTune = sources.firstWhere((s) => s.sourceName == 'PeriTune');
      expect(periTune.bgmEntries.length, 1);
      expect(periTune.bgmEntries.first.fileName, 'amb_dungeon.ogg');

      final gemini = sources.firstWhere((s) => s.sourceName == 'Google Gemini (AI生成)');
      expect(gemini.bgmEntries.length, 1);
      expect(gemini.bgmEntries.first.fileName, 'amb_theme_fake_delphi.ogg');

      // 効果音のみの提供元は bgmEntries が空であること
      final soundLab = sources.firstWhere((s) => s.sourceName == '効果音ラボ');
      expect(soundLab.bgmEntries, isEmpty);
    });

    test('getBgmTitle による日本語・英語のフロア名・部屋名の取得が正しく動作する', () {
      expect(SoundCreditParser.getBgmTitle('amb_dungeon.ogg'), '運命の大迷宮');
      expect(SoundCreditParser.getBgmTitle('amb_dungeon.ogg', isEnglish: true), 'The Dungeons of Doom');

      expect(SoundCreditParser.getBgmTitle('amb_oracle.ogg'), '神託所');
      expect(SoundCreditParser.getBgmTitle('amb_oracle.ogg', isEnglish: true), 'The Oracle');

      expect(SoundCreditParser.getBgmTitle('amb_theme_statuary.ogg'), '彫像展示室');
      expect(SoundCreditParser.getBgmTitle('amb_theme_statuary.ogg', isEnglish: true), 'Statuary');

      // 未知のBGMファイルの場合は Description からフォールバック抽出
      expect(
        SoundCreditParser.getBgmTitle('amb_unknown.ogg', description: '秘密の地下室（Secret Basement）。不穏な足音。'),
        '秘密の地下室',
      );
      expect(
        SoundCreditParser.getBgmTitle('amb_unknown.ogg', isEnglish: true, description: '秘密の地下室（Secret Basement）。不穏な足音。'),
        'Secret Basement',
      );
    });

    test('実ファイル assets/sounds/attributions.txt からの集約カード一覧生成で「その他」が存在しない', () {
      final file = File('assets/sounds/attributions.txt');
      if (!file.existsSync()) {
        return;
      }
      final content = file.readAsStringSync();
      final sources = SoundCreditParser.parseSources(content);

      // 提供元数（10〜15サービス程度）に綺麗に集約されていること
      expect(sources.length, inInclusiveRange(10, 20));

      for (final s in sources) {
        expect(s.sourceName, isNot(contains('その他')));
        expect(s.sourceName, isNot('Unknown'));
        expect(s.author, isNot(contains('その他')));
        expect(s.author, isNot('Unknown'));
        expect(s.license, isNot(contains('その他')));
        expect(s.license, isNot('Unknown'));
        expect(s.url, isNotEmpty);
        expect(s.url.startsWith('http'), isTrue);

        // 各BGMエントリに環境音が含まれていないこと
        for (final bgm in s.bgmEntries) {
          expect(SoundCreditParser.terrainAmbienceFiles.contains(bgm.fileName), isFalse);
          expect(bgm.fileName.startsWith('amb_'), isTrue);
        }
      }
    });
  });
}
