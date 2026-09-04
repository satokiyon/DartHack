import 'dart:io';
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
        ' 21          4  Player 騎士/人間/男性/秩序 killed by a falling drawbridge (運命の大迷宮 10階).',
        '                                                                       -  [0]',
        ' 22          3  Player 洞窟人/人間/男性/中立 unwisely ate the body of cockatrice (運命の大迷宮 12階).',
        '                                                                       -  [0]',
        ' 23          2  Player 考古学者/人間/男性/中立 unwisely ate the brain of mind flayer (運命の大迷宮 15階).',
        '                                                                       -  [0]',
        ' 24          1  Player 侍/人間/男性/秩序 touching cockatrice corpse bare-handed (運命の大迷宮 12階).',
        '                                                                       -  [0]',
        ' 25          1  Player 侍/人間/男性/秩序 kicking cockatrice corpse barefoot (運命の大迷宮 12階).',
        '                                                                       -  [0]',
        ' 26          1  Player 魔法使い/人間/男性/中立 killed by alchemic blast (運命の大迷宮 5階).',
        '                                                                       -  [0]',
        ' 27          1  Player 騎士/人間/男性/秩序 killed by Vlad the Impaler (ゲヘナ 35階).',
        '                                                                       -  [0]',
        ' 28          1  Player 魔法使い/人間/男性/中立 shot himself with a death ray (運命の大迷宮 10階).',
        '                                                                       -  [0]',
        ' 29          1  Player 僧侶/人間/男性/秩序 killed by Moloch\'s indifference (アストラル界 1階).',
        '                                                                       -  [0]',
        ' 30          1  Player 侍/人間/男性/秩序 committed suicide (運命の大迷宮 1階).',
        '                                                                       -  [0]',
        ' 31          1  Player 探検家/人間/男性/中立 killed by brainlessness (運命の大迷宮 12階).',
        '                                                                       -  [0]',
        ' 32          1  Player 侍/人間/男性/秩序 escaped (with the Amulet).',
        '                                                                       -  [0]',
        ' 33          1  Player 魔法使い/人間/男性/中立 killed by self-genocide (運命の大迷宮 1階).',
        '                                                                       -  [0]',
        ' 34          1  Player 騎士/人間/男性/秩序 killed by unsuccessful polymorph (運命の大迷宮 2階).',
        '                                                                       -  [0]',
        ' 35          1  Player 探検家/人間/男性/中立 killed by elementary physics (運命の大迷宮 3階).',
        '                                                                       -  [0]',
        ' 36          1  Player 騎士/人間/男性/秩序 killed by vampire in bat form (運命の大迷宮 14階).',
        '                                                                       -  [0]',
        ' 37          1  Player 盗賊/人間/男性/混沌 killed by doppelganger disguised as goblin (運命の大迷宮 5階).',
        '                                                                       -  [0]',
        ' 38          1  Player 洞窟人/人間/男性/中立 killed by chameleon imitating giant ant (運命の大迷宮 8階).',
        '                                                                       -  [0]',
      ];
      final attrs = List.filled(inputLines.length, 0);

      final entries = TopTenEntry.parse(inputLines, attrs);

      expect(entries.length, 38);
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
      expect(entries[20].details[0], contains('落ちてくる跳ね橋に倒された'));
      expect(entries[21].details[0], contains('軽率にもコカトリスの肉を食べたこと'));
      expect(entries[22].details[0], contains('マインドフレアの脳を食べたこと'));
      expect(entries[23].details[0], contains('素手でコカトリスの死体に触れたことで石化した'));
      expect(entries[24].details[0], contains('裸足でコカトリスの死体を蹴ったことで石化した'));
      expect(entries[25].details[0], contains('錬金術の爆発に倒された'));
      expect(entries[26].details[0], contains('ヴラド公に倒された'));
      expect(entries[27].details[0], contains('死の光線で自分を照射したこと'));
      expect(entries[28].details[0], contains('モロクの冷淡さで倒された'));
      expect(entries[29].details[0], contains('自殺'));
      expect(entries[30].details[0], contains('脳の損失で倒された'));
      expect(entries[31].details[0], contains('脱出した (魔除けを持ったまま)'));
      expect(entries[32].details[0], contains('自己虐殺'));
      expect(entries[33].details[0], contains('へんげの失敗'));
      expect(entries[34].details[0], contains('基礎物理学'));
      expect(entries[35].details[0], contains('コウモリの姿をしたヴァンパイアに倒された'));
      expect(entries[36].details[0], contains('ゴブリンに変装したドッペルゲンガーに倒された'));
      expect(entries[37].details[0], contains('巨大アリに擬態したカメレオンに倒された'));
    });

    test('3行以上にまたがる長い死因テキストとHP/最大HPが途切れず全文結合・パースできる（ユーザー報告の症例）', () {
      final inputLines = [
        '順位      点数  名前                                                   HP[最大]',
        '  1     12345  satok 侍/人間/男性/秩序',
        '               幻覚でゆがんだ店主のスハイグアトスエに倒された（ノー',
        '               ムの鉱山 1階）.                                          - [ 25]',
        '  2       800  Player 洞窟人/ノーム/男性/イシュタル',
        '               中断した（運命の大迷宮 2階）.                          15  [15]',
      ];
      final attrs = List.filled(inputLines.length, 0);

      final entries = TopTenEntry.parse(inputLines, attrs);

      expect(entries.length, 2);

      // Entry 1 (3行に分割されたエントリ)
      expect(entries[0].rank, 1);
      expect(entries[0].score, '12345');
      expect(entries[0].nameAndProfile, 'satok 侍/人間/男性/秩序');
      expect(entries[0].details, [
        '幻覚でゆがんだ店主のスハイグアトスエに倒された（ノームの鉱山 1階）.',
        'HP/最大HP: -/25',
      ]);

      // Entry 2 (通常のエントリ)
      expect(entries[1].rank, 2);
      expect(entries[1].score, '800');
      expect(entries[1].nameAndProfile, 'Player 洞窟人/ノーム/男性/イシュタル');
      expect(entries[1].details, [
        '中断した（運命の大迷宮 2階）.',
        'HP/最大HP: 15/15',
      ]);
    });

    test('4行に分割された非常に長い死因テキストでも正常に結合・パースできる', () {
      final inputLines = [
        '順位      点数  名前                                                   HP[最大]',
        '  1     99999  Player 魔法使い/エルフ/女性/混沌',
        '               長い死因の前半部分で始まって',
        '               さらに中盤部分へと続き',
        '               最後に終盤部分に到達した（ゲヘナ 35階）.                  - [ 50]',
      ];
      final attrs = List.filled(inputLines.length, 0);

      final entries = TopTenEntry.parse(inputLines, attrs);

      expect(entries.length, 1);
      expect(entries[0].rank, 1);
      expect(entries[0].details, [
        '長い死因の前半部分で始まってさらに中盤部分へと続き最後に終盤部分に到達した（ゲヘナ 35階）.',
        'HP/最大HP: -/25'.replaceAll('25', '50'),
      ]);
    });

    test('parseRecordFileにおいて死因の有無に関わらずHP/最大HPが独立行として正常にパースされる', () {
      // テスト用の一時ファイルを作成して検証
      final tempDir = Directory.systemTemp.createTempSync('record_test_');
      final recordFile = File('${tempDir.path}/record');
      // record format:
      // version points dnum dlev maxlvl hp maxhp deaths deathdate birthdate uid role race gend align name, death
      final line1 = '5.0.0 12345 0 5 10 0 25 1 20260904 20260901 1000 Sam Hum Mal Cha satok, killed by a goblin';
      final line2 = '5.0.0 50000 0 1 1 30 30 0 20260904 20260901 1000 Wiz Elf Fem Cha hero, ascended';
      recordFile.writeAsStringSync('$line1\n$line2\n');

      final entriesJp = parseRecordFile(recordFile.path, isJp: true);
      expect(entriesJp.length, 2);

      // Entry 1: points 50000 (昇天・生存)
      expect(entriesJp[0].score, '50000');
      expect(entriesJp[0].details.length, 2);
      expect(entriesJp[0].details[0], contains('昇天した'));
      expect(entriesJp[0].details[1], 'HP/最大HP: 30/30');

      // Entry 2: points 12345 (死亡・HP <= 0)
      expect(entriesJp[1].score, '12345');
      expect(entriesJp[1].details.length, 2);
      expect(entriesJp[1].details[0], contains('ゴブリンに倒された'));
      expect(entriesJp[1].details[1], 'HP/最大HP: -/25');

      tempDir.deleteSync(recursive: true);
    });
  });
}
