import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/dumplog_document.dart';

void main() {
  group('DumplogDocument.parse', () {
    const jpSample = '''
NetHack, Copyright 1985-2026
         By Stichting Mathematisch Centrum and M. Stephenson.

ゲーム開始: 2026-11-21 10:00:00 / 終了: 2026-11-21 10:30:00.

Taro（秩序・女・ドワーフ・ワルキューレ）

   ------
   |....|
   |.@d.|
   ------
Taro 戦乙女  筋:18/01 知:9 賢:10 器:12 体:18 魅:8 秩
階層:3  \$:120  HP:0(16)  魔:2(2)  AC:5  経:2  T:315

最新メッセージ:
 ジャッカルはあなたを噛んだ！
 あなたは死んだ...

所持品:
武器
  a - 祝福されていないロングソード +1（右手に装備）
防具
  b - 祝福されていない小型の盾 +3（装備中）

背景:
 あなたはドワーフのワルキューレだった。

最終状態:
 あなたは死んだ。

最終能力:
 あなたは毒に対する耐性を持っていた。

主要イベント:
 ターン
    1: 冒険を開始した
  315: ジャッカルに殺された

呪文を何も知らなかった.

スキル:
武器のスキル
  ロングソード [初級]

自主的な縛り:
 どの怪物種も虐殺していない

メインダンジョン:
  階層 1〜3 まで探索した。

倒した怪物:
  ゴブリン 2体
2体を倒した。

虐殺または絶滅した種はいなかった。

          ----------
         /          \\
        /    REST    \\
       /      IN      \\
      /     PEACE      \\
     /                  \\
     |       Taro       |
     |      120 Au      |
     |  ジャッカルに    |
     |     殺された     |
     |       2026       |
    *|     *  *  *      | *
_________)/\\\\_//(\\/(/\\)/\\//\\/|_)_______

さようなら ワルキューレのTaro...

あなたはメインダンジョンで死んだ（ダンジョン階層 3）。得点は450点,
所持金120枚、行動回数315回。
死んだ時点でのレベルは2、最大HPは16だった。
''';

    const enSample = '''
NetHack 5.0.0

Game began 2026-11-21 10:00:00, ended 2026-11-21 10:15:00.

Alice, lawful female dwarf Valkyrie

   ------
   |..@.|
   ------
Alice the Stripling  St:18/01 Dx:12 Co:18 In:9 Wi:10 Ch:8  Lawful
Dlvl:1  \$:50  HP:0(16)  Pw:2(2)  AC:5  Xp:1/10  T:120

Latest messages:
 The grid bug bites!
 You die...

Inventory:
Weapons
  a - a +1 long sword (weapon in hand)

Background:
 You were a lawful dwarven Valkyrie.

Final Status:
 You were dead.

Final Attributes:
 You were poison resistant.

Major events:
 Turn
    1: Entered the dungeon

You knew no spells.

Skills:
  long sword [Basic]

Voluntary challenges:
 You never genocided any monsters.

The Dungeons of Doom:
  Level 1: explored

Vanquished creatures:
  1 grid bug

No species were genocided or became extinct.

          ----------
         /          \\
        /    REST    \\
       /      IN      \\
      /     PEACE      \\
     /                  \\
     |      Alice       |
     |      50 Au       |
     |  killed by a     |
     |    grid bug      |
     |       2026       |
    *|     *  *  *      | *
_________)/\\\\_//(\\/(/\\)/\\//\\/|_)_______

Goodbye Alice the Valkyrie...

You died in The Dungeons of Doom on dungeon level 1 with 120 points,
and 50 pieces of gold, after 120 moves.
''';

    test('日本語コアの dumplog を全セクション正確に分割できること', () {
      final doc = DumplogDocument.parse(jpSample, isJp: true);

      final types = doc.sections.map((s) => s.type).toList();
      expect(
        types,
        containsAllInOrder([
          DumplogSectionType.header,
          DumplogSectionType.map,
          DumplogSectionType.messages,
          DumplogSectionType.inventory,
          DumplogSectionType.attributes,
          DumplogSectionType.gamelog,
          DumplogSectionType.spells,
          DumplogSectionType.skills,
          DumplogSectionType.conduct,
          DumplogSectionType.overview,
          DumplogSectionType.vanquished,
          DumplogSectionType.genocided,
          DumplogSectionType.tombstone,
          DumplogSectionType.summary,
        ]),
      );

      final mapSec =
          doc.sections.firstWhere((s) => s.type == DumplogSectionType.map);
      expect(mapSec.isMonospaceScrollable, isTrue);
      expect(mapSec.defaultExpanded, isTrue);
      expect(mapSec.lines.join('\n'), contains('|.|'.replaceFirst('|.|', '|.@d.|')));
      expect(mapSec.lines.join('\n'), contains('階層:3'));

      final tombSec =
          doc.sections.firstWhere((s) => s.type == DumplogSectionType.tombstone);
      expect(tombSec.isMonospaceScrollable, isTrue);
      expect(tombSec.defaultExpanded, isTrue);
      expect(tombSec.lines.join('\n'), contains('REST'));

      final vanqSec = doc.sections
          .firstWhere((s) => s.type == DumplogSectionType.vanquished);
      expect(vanqSec.defaultExpanded, isFalse);
      expect(vanqSec.lines.join('\n'), contains('ゴブリン'));
    });

    test('英語コアの dumplog を日本語モードで開いた際、見出しと定型ヘッダーが日本語化され原文とマップは保持されること', () {
      final doc = DumplogDocument.parse(enSample, isJp: true);

      expect(doc.rawText, enSample);

      final header =
          doc.sections.firstWhere((s) => s.type == DumplogSectionType.header);
      expect(header.title, '基本情報');
      expect(header.lines.join('\n'),
          contains('ゲーム開始: 2026-11-21 10:00:00 / 終了: 2026-11-21 10:15:00'));
      expect(header.lines.join('\n'), contains('Alice（秩序・女・ドワーフ・ワルキューレ）'));

      final mapSec =
          doc.sections.firstWhere((s) => s.type == DumplogSectionType.map);
      expect(mapSec.lines.join('\n'), contains('|..@.|'));
      expect(mapSec.lines.join('\n'), contains('Dlvl:1'));

      final attrSec = doc.sections
          .firstWhere((s) => s.type == DumplogSectionType.attributes);
      expect(attrSec.lines, contains('背景:'));
      expect(attrSec.lines, contains('最終状態:'));
      expect(attrSec.lines, contains('最終能力:'));

      final spellsSec =
          doc.sections.firstWhere((s) => s.type == DumplogSectionType.spells);
      expect(spellsSec.lines.join('\n'), contains('呪文を何も知らなかった。'));
    });

    test('空や未知フォーマットでもクラッシュせず安全にフォールバックすること', () {
      final emptyDoc = DumplogDocument.parse('   \n\n  ', isJp: true);
      expect(emptyDoc.sections, isEmpty);

      final unknownDoc =
          DumplogDocument.parse('custom line 1\ncustom line 2\n', isJp: false);
      expect(unknownDoc.sections, hasLength(1));
      expect(unknownDoc.sections.first.type, DumplogSectionType.other);
      expect(unknownDoc.sections.first.lines, ['custom line 1', 'custom line 2']);
    });
  });
}
