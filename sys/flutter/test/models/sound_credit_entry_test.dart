import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/sound_credit_entry.dart';

void main() {
  group('SoundCreditParser Tests', () {
    test('サンプルテキストのパースが正しく動作し、自作音源はスキップされる', () {
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
''';

      final grouped = SoundCreditParser.parse(sampleText);

      // 自作音源は除外され、外部音源のみが残る
      expect(grouped.containsKey('自作音源（クレジット対象外）'), isFalse);
      expect(grouped.containsKey("Springin' Sound Stock"), isTrue);
      expect(grouped.containsKey('効果音ラボ'), isTrue);
      expect(grouped.containsKey('Google Gemini (AI生成)'), isTrue);

      // 「その他」が提供元や作者、ライセンスに含まれないこと
      for (final group in grouped.entries) {
        expect(group.key, isNot(contains('その他')));
        expect(group.key, isNot('Unknown'));

        for (final entry in group.value) {
          expect(entry.sourceName, isNot(contains('その他')));
          expect(entry.sourceName, isNot('Unknown'));
          expect(entry.author, isNot(contains('その他')));
          expect(entry.author, isNot('Unknown'));
          expect(entry.license, isNot(contains('その他')));
          expect(entry.license, isNot('Unknown'));
        }
      }

      // 作者が空の場合はサイト名が補完されていること
      final lab = grouped['効果音ラボ']!;
      expect(lab[0].author, '効果音ラボ');
    });

    test('実ファイル assets/sounds/attributions.txt を正常にパースでき、「その他」が存在しない', () {
      final file = File('assets/sounds/attributions.txt');
      if (!file.existsSync()) {
        return;
      }
      final content = file.readAsStringSync();
      final grouped = SoundCreditParser.parse(content);

      expect(grouped.isNotEmpty, isTrue);

      int totalItems = 0;
      for (final group in grouped.entries) {
        // 提供元グループ名に「その他」や「Unknown」がないこと
        expect(group.key, isNot(contains('その他')));
        expect(group.key, isNot('Unknown'));

        for (final entry in group.value) {
          totalItems++;
          // 作者やライセンスに「その他」や「Unknown」がないこと
          expect(entry.sourceName, isNot(contains('その他')));
          expect(entry.sourceName, isNot('Unknown'));
          expect(entry.author, isNot(contains('その他')));
          expect(entry.author, isNot('Unknown'));
          expect(entry.license, isNot(contains('その他')));
          expect(entry.license, isNot('Unknown'));
        }
      }

      // 外部音源の合計（自作音源が除外された184件）
      expect(totalItems, greaterThanOrEqualTo(180));
    });
  });
}
