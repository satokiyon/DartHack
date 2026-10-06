import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/item_count_parser.dart';

void main() {
  group('ItemCountParser.parseMaxCount Tests', () {
    test('日本語アイテムのスタック数量パース', () {
      expect(ItemCountParser.parseMaxCount('a - 4個の食料'), 4);
      expect(ItemCountParser.parseMaxCount('b - 10本の+1矢'), 10);
      expect(ItemCountParser.parseMaxCount('c - 3枚の白紙の巻物'), 3);
      expect(ItemCountParser.parseMaxCount('5個のりんご'), 5);
      expect(ItemCountParser.parseMaxCount('d - 200枚の金貨'), 200);
    });

    test('日本語アイテムの単数（1個）は1を返す（エンチャント値を誤認しない）', () {
      expect(ItemCountParser.parseMaxCount('a - +1短剣'), 1);
      expect(ItemCountParser.parseMaxCount('b - +2銀のサーベル'), 1);
      expect(ItemCountParser.parseMaxCount('c - -1皮の鎧'), 1);
      expect(ItemCountParser.parseMaxCount('呪われていない兜'), 1);
    });

    test('英語アイテムのスタック数量パース', () {
      expect(ItemCountParser.parseMaxCount('a - 4 rations of food'), 4);
      expect(ItemCountParser.parseMaxCount('b - 10 +1 darts'), 10);
      expect(ItemCountParser.parseMaxCount('c - 2 potions of water'), 2);
      expect(ItemCountParser.parseMaxCount('15 uncursed rocks'), 15);
    });

    test('英語アイテムの単数は1を返す', () {
      expect(ItemCountParser.parseMaxCount('a - a +1 dagger'), 1);
      expect(ItemCountParser.parseMaxCount('b - an uncursed helmet'), 1);
      expect(ItemCountParser.parseMaxCount('c - a +2 arrow'), 1);
      expect(ItemCountParser.parseMaxCount('an uncursed -1 ring'), 1);
    });
  });

  group('ItemCountParser.isQuantitySelectionAllowed Tests', () {
    test('複数選択メニュー（menuHow > 1）での判定', () {
      expect(ItemCountParser.isQuantitySelectionAllowed('何を捨てますか?', 2), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を箱から取り出しますか?', 2), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を拾いますか?', 2), isTrue);
      // 支払いはガードされる
      expect(ItemCountParser.isQuantitySelectionAllowed('どの品の代金を支払いますか?', 2), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('What will you pay for?', 2), isFalse);
    });

    test('単一選択メニュー（menuHow <= 1）での判定', () {
      // ドロップ、矢筒、浸す、持ち物一覧は許可
      expect(ItemCountParser.isQuantitySelectionAllowed('何を落としますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('矢筒に何を用意しますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を浸しますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('持ち物一覧', 1), isTrue);

      // 袋・箱への出し入れ、投げる等の未確認・追加操作もブラックリスト方式により許可
      expect(ItemCountParser.isQuantitySelectionAllowed('袋に何を入れますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('What do you want to put in?', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('袋から何を取り出しますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('What do you want to take out?', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を投げますか? [a-z or ?*]', 1), isTrue);
      expect(ItemCountParser.isQuantitySelectionAllowed('What do you want to throw?', 1), isTrue);

      // 明確に無効と判明している操作（飲む、読む、装備、食べる、振る、名付け、識別、充填、油塗り）はガード
      expect(ItemCountParser.isQuantitySelectionAllowed('何を飲みますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('What do you want to drink?', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を読みますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を装備しますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を着ますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を食べますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('どの杖を振りますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何に名付けますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を識別しますか? [a-z or ?*]', 1), isFalse);
      expect(ItemCountParser.isQuantitySelectionAllowed('何を充填しますか? [a-z or ?*]', 1), isFalse);
    });
  });
}
