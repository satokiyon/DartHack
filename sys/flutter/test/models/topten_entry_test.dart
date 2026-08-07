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
  });
}
