// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-07.
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/topten_entry.dart';

void main() {
  group('TopTenEntry Parse Tests', () {
    test('1行目に死因の一部が食い込む80桁スコアボード表示の正しく分離・パースできる', () {
      final inputLines = [
        '順位      点数  名前                                                   HP[最大]',
        '  1         84  さとう 洞窟人/ノーム/男性/イシュタル',
        '                中断した（運命の大迷宮 2階）.                          15  [15]',
        '  2         63  Player 侍/人間/女性/天照大神 中断した（運命の大迷宮',
        '                2階）.                                                 13  [15]',
        '              0  Player 野蛮人/人間/男性/クロム 中断した（運命の大迷宮',
        '                1階）.                                                 16  [16]',
      ];
      final attrs = List.filled(inputLines.length, 0);

      final entries = TopTenEntry.parse(inputLines, attrs);

      expect(entries.length, 3);

      // Entry 1
      expect(entries[0].rank, 1);
      expect(entries[0].score, '84');
      expect(entries[0].nameAndProfile, 'さとう 洞窟人/ノーム/男性/イシュタル');
      expect(entries[0].details, [
        '中断した（運命の大迷宮 2階）.',
        'HP/最大HP: 15/15',
      ]);

      // Entry 2
      expect(entries[1].rank, 2);
      expect(entries[1].score, '63');
      expect(entries[1].nameAndProfile, 'Player 侍/人間/女性/天照大神');
      expect(entries[1].details, [
        '中断した（運命の大迷宮2階）.',
        'HP/最大HP: 13/15',
      ]);

      // Entry 3
      expect(entries[2].rank, 0);
      expect(entries[2].score, '0');
      expect(entries[2].nameAndProfile, 'Player 野蛮人/人間/男性/クロム');
      expect(entries[2].details, [
        '中断した（運命の大迷宮1階）.',
        'HP/最大HP: 16/16',
      ]);
    });

    test('英語モードのスコアボードヘッダーとハイフンプロフィールの正しいパース', () {
      final inputLines = [
        ' No  Points     Name',
        '  1      12345  satok-Wiz-Elf-Mal-Cha died in The Dungeons of Doom on level 5.',
        '                Killed by a goblin. - [25]',
        '  2       6789  hero-Kni-Hum-Fem-Law quit in The Dungeons of Doom on level 2.',
        '                12 [30]',
        '  3       5000  escaped-Tou-Gno-Mal-Neu escaped (with the Amulet) [max level 10].',
        '                25 [40]',
      ];
      final attrs = List.filled(inputLines.length, 0);
      attrs[1] = 1; // ATR_BOLD for current game

      final entries = TopTenEntry.parse(inputLines, attrs, isJp: false);

      expect(entries.length, 3);

      // Entry 1
      expect(entries[0].rank, 1);
      expect(entries[0].score, '12345');
      expect(entries[0].nameAndProfile, 'satok Wizard / Elf / Male / Chaotic');
      expect(entries[0].isCurrent, true);
      expect(entries[0].details, [
        'Died in The Dungeons of Doom on level 5. Killed by a goblin.',
        'HP/Max HP: -/25',
      ]);

      // Entry 2
      expect(entries[1].rank, 2);
      expect(entries[1].score, '6789');
      expect(entries[1].nameAndProfile, 'hero Knight / Human / Female / Lawful');
      expect(entries[1].isCurrent, false);
      expect(entries[1].details, [
        'Quit in The Dungeons of Doom on level 2.',
        'HP/Max HP: 12/30',
      ]);

      // Entry 3
      expect(entries[2].rank, 3);
      expect(entries[2].score, '5000');
      expect(entries[2].nameAndProfile, 'escaped Tourist / Gnome / Male / Neutral');
      expect(entries[2].isCurrent, false);
      expect(entries[2].details, [
        'Escaped (with the Amulet) [max level 10].',
        'HP/Max HP: 25/40',
      ]);
    });

    test('Cコアから届く英語死因テキストの日本語化フォールバックテスト', () {
      final inputLines = [
        '順位      点数  名前                                                   HP[最大]',
        '  1       1000  Player 魔法使い/人間/男性/秩序 killed by a goblin (運命の大迷宮 5階).',
        '                                                                       -  [25]',
        '  2        800  Player 侍/人間/女性/天照大神 killed by a ghost of a wizard (運命の大迷宮 3階).',
        '                                                                       -  [30]',
        '  3        500  Player 洞窟人/ノーム/男性/イシュタル killed by a poisonous corpse (運命の大迷宮 2階).',
        '                                                                       -  [15]',
        '  4        400  Player 野蛮人/人間/男性/クロム killed by an acidic glob (運命の大迷宮 1階).',
        '                                                                       -  [16]',
        '  5        300  Player 盗賊/人間/女性/混沌 choked on a poisonous corpse (運命の大迷宮 1階).',
        '                                                                       -  [20]',
        '  6        250  Player 騎士/人間/男性/秩序 killed by a guard (運命の大迷宮 1階).',
        '                                                                       -  [18]',
        '  7        200  Player 旅人/ノーム/女性/混沌 killed by a giant bat (運命の大迷宮 1階).',
        '                                                                       -  [10]',
        '  8        150  Player 考古学者/ドワーフ/男性/中立 killed by a sewer rat (運命の大迷宮 1階).',
        '                                                                       -  [12]',
        '  9        120  Player 魔法使い/エルフ/女性/混沌 killed by an arrow (運命の大迷宮 1階).',
        '                                                                       -  [8]',
        ' 10        100  Player 盗賊/人間/男性/中立 killed by a poisoned needle (運命の大迷宮 2階).',
        '                                                                       -  [5]',
        ' 11         90  Player 侍/人間/男性/秩序 drowned in a pool of water (運命の大迷宮 3階).',
        '                                                                       -  [10]',
        ' 12         80  Player 騎士/人間/男性/秩序 drowned in a moat (運命の大迷宮 4階).',
        '                                                                       -  [15]',
        ' 13         70  Player 野蛮人/人間/男性/中立 killed by a land mine (運命の大迷宮 2階).',
        '                                                                       -  [10]',
        ' 14         50  Player 騎士/人間/男性/秩序 killed by Excalibur (運命の大迷宮 5階).',
        '                                                                       -  [20]',
        ' 15         30  Player 修道士/人間/男性/秩序 crunched in the head by an iron ball (運命の大迷宮 1階).',
        '                                                                       -  [0]',
        ' 16         25  Player 労働者/人間/男性/秩序 killed by Mr. Shigatse; the shopkeeper (ノームの鉱山 6階).',
        '                                                                       -  [0]',
        ' 17         20  Player 労働者/人間/男性/秩序 killed by 幻覚でゆがんだMr. Shigatse; the shopkeeper (ノームの鉱山 6階).',
        '                                                                       -  [0]',
        ' 18         15  Player 僧侶/人間/男性/秩序 killed by high priest of Moloch (アストラル界 1階).',
        '                                                                       -  [0]',
        ' 19         10  Player 魔法使い/エルフ/女性/混沌 killed by kitten called Tama (運命の大迷宮 1階).',
        '                                                                       -  [0]',
        ' 20          5  Player 盗賊/人間/男性/中立 killed by doppelganger in goblin form (運命の大迷宮 3階).',
        '                                                                       -  [0]',
      ];
      final attrs = List.filled(inputLines.length, 0);

      final entries = TopTenEntry.parse(inputLines, attrs);

      expect(entries.length, 20);
      expect(entries[0].details[0], contains('ゴブリンに倒された'));
      expect(entries[1].details[0], contains('魔法使いの幽霊に倒された'));
      expect(entries[2].details[0], contains('有毒な死体に倒された'));
      expect(entries[3].details[0], contains('酸性の塊に倒された'));
      expect(entries[4].details[0], contains('有毒な死体で窒息した'));
      expect(entries[5].details[0], contains('番兵に倒された'));
      expect(entries[6].details[0], contains('巨大コウモリに倒された'));
      expect(entries[7].details[0], contains('ドブネズミに倒された'));
      expect(entries[8].details[0], contains('矢に倒された'));
      expect(entries[9].details[0], contains('毒針に倒された'));
      expect(entries[10].details[0], contains('水たまりで溺死した'));
      expect(entries[11].details[0], contains('お堀で溺死した'));
      expect(entries[12].details[0], contains('地雷に倒された'));
      expect(entries[13].details[0], contains('エクスカリバーに倒された'));
      expect(entries[14].details[0], contains('鉄球に頭を打ち砕かれた'));
      expect(entries[15].details[0], contains('店主のシガツェに倒された'));
      expect(entries[16].details[0], contains('幻覚でゆがんだ店主のシガツェに倒された'));
      expect(entries[17].details[0], contains('モロクの高位神官に倒された'));
      expect(entries[18].details[0], contains('Tamaという名前の子猫に倒された'));
      expect(entries[19].details[0], contains('ゴブリンの姿をしたドッペルゲンガーに倒された'));
    });
  });
}
