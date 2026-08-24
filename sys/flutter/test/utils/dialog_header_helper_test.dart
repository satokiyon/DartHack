// NOTICE: Created by NetHackJP contributor @satokiyon; latest change date: 2026-08-24.

import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/dialog_header_helper.dart';

void main() {
  group('DialogHeaderHelper.isDialogTitleHeader 判定テスト', () {
    test('日本語タイトルキーワードが正しく true と判定されること', () {
      expect(DialogHeaderHelper.isDialogTitleHeader('背景:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('基本情報:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('現在の能力値:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('最終能力値:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('現在の状態:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('最終状態:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('現在の能力:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('最終能力:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('その他:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('所持品:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('武器'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('防具'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('食べ物'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('宝石'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('宝石/石'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('護符'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('魔法書'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('巨石/彫像'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('倒した怪物:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('自主的な縛り:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('革のリュック の中身:'), isTrue);
    });

    test('英語タイトルキーワードが正しく true と判定されること', () {
      expect(DialogHeaderHelper.isDialogTitleHeader('Background:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Base Attributes:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Current Attributes:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Final Attributes:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Current Status:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Final Status:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Other Properties:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Inventory:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Weapons'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Armor'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Food'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Comestibles'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Gems'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Gems/Stones'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Boulders/Statues'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Vanquished creatures:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Voluntary challenges:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Contents of sack:'), isTrue);
    });

    test('#overview (ダンジョン概要) の階層名や一般文章が false と判定されること', () {
      expect(DialogHeaderHelper.isDialogTitleHeader('ゲヘナ:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('運命の大迷宮:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('鉱山:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('The Dungeons of Doom:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('Gehennom:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('The Gnomish Mines:'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('レベル1の人間'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader('あなたは死んだ。'), isFalse);
      expect(DialogHeaderHelper.isDialogTitleHeader(''), isFalse);
    });
  });
}
