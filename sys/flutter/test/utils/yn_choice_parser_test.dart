import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/yn_choice_parser.dart';

void main() {
  group('YnChoiceParser.expandRangeString', () {
    test('c-z を c から z まで展開する', () {
      final list = YnChoiceParser.expandRangeString('c-z');
      expect(list.length, 24);
      expect(list.first, 'c');
      expect(list.last, 'z');
      expect(list.contains('d'), isTrue);
    });

    test('a-e,g-z のように複数範囲が混在する場合も正しく展開する', () {
      final list = YnChoiceParser.expandRangeString('a-e,g-i');
      expect(list, ['a', 'b', 'c', 'd', 'e', 'g', 'h', 'i']);
    });

    test('大文字範囲 A-C も正しく展開する', () {
      final list = YnChoiceParser.expandRangeString('A-C');
      expect(list, ['A', 'B', 'C']);
    });

    test('数字範囲 1-5 も正しく展開する', () {
      final list = YnChoiceParser.expandRangeString('1-5');
      expect(list, ['1', '2', '3', '4', '5']);
    });
  });

  group('YnChoiceParser.parse', () {
    test('#adjust スロット調整プロンプトを slotSelect としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'スロット文字を調整 移動先はどこにしますか [c-z]? (?で使用中の文字を表示)',
        choices: '',
      );
      expect(parsed.type, YnPromptType.slotSelect);
      expect(parsed.quickChoices.first, 'c');
      expect(parsed.quickChoices.last, 'z');
      expect(parsed.quickChoices.contains('?'), isFalse);
      expect(parsed.allowsFreeInput, isTrue);
      expect(parsed.hasHelpOption, isTrue);
    });

    test('分割数量プロンプトを countInput としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'いくつ分けますか?',
        choices: '',
      );
      expect(parsed.type, YnPromptType.countInput);
      expect(parsed.quickChoices, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
      expect(parsed.validKeyChars.contains('5'), isTrue);
      expect(parsed.allowsFreeInput, isTrue);
    });

    test('水晶玉探知プロンプトを symbolDetect としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: '何をお探しですか?',
        choices: '',
      );
      expect(parsed.type, YnPromptType.symbolDetect);
      expect(parsed.quickChoices.contains('\$'), isTrue);
      expect(parsed.quickChoices.contains(')'), isTrue);
      expect(parsed.allowsFreeInput, isTrue);
      expect(parsed.validKeyChars.isEmpty, isTrue); // 全文字許容
    });

    test('キャラメイクおまかせプロンプトを yesNo かつ ynaq としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: "Shall I pick a character's race, role, gender and alignment for you? [ynaq]",
        choices: '',
      );
      expect(parsed.type, YnPromptType.yesNo);
      expect(parsed.quickChoices, ['y', 'n', 'a', 'q']);
      expect(parsed.validKeyChars, {'y', 'n', 'a', 'q'});
    });

    test('標準的な [y/n] プロンプトを yesNo としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: '本当にゲームを終了しますか? [y/n]',
        choices: '',
      );
      expect(parsed.type, YnPromptType.yesNo);
      expect(parsed.quickChoices, ['y', 'n']);
    });

    test('英語モード: #adjust プロンプト (Adjust letter to what [c-z]?) を slotSelect としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'Adjust letter to what [c-z]? (? to see used letters)',
        choices: '',
      );
      expect(parsed.type, YnPromptType.slotSelect);
      expect(parsed.quickChoices.first, 'c');
      expect(parsed.quickChoices.last, 'z');
      expect(parsed.hasHelpOption, isTrue);
    });

    test('英語モード: スタック分割プロンプト (Split off how many?) を countInput としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'Split off how many?',
        choices: '',
      );
      expect(parsed.type, YnPromptType.countInput);
      expect(parsed.quickChoices, ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
      expect(parsed.validKeyChars.contains('7'), isTrue);
    });

    test('英語モード: 水晶玉探知プロンプト (What do you look for?) を symbolDetect としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'What do you look for?',
        choices: '',
      );
      expect(parsed.type, YnPromptType.symbolDetect);
      expect(parsed.quickChoices.contains('\$'), isTrue);
    });

    test('英語モード: 伝統的呪文・アイテム選択プロンプトを展開する', () {
      final spellParsed = YnChoiceParser.parse(
        question: 'Cast which spell? [a-c *?]',
        choices: '',
      );
      expect(spellParsed.type, YnPromptType.slotSelect);
      expect(spellParsed.quickChoices, ['a', 'b', 'c']);

      final dropParsed = YnChoiceParser.parse(
        question: 'What do you want to drop? [a-d or ?*]',
        choices: '',
      );
      expect(dropParsed.type, YnPromptType.slotSelect);
      expect(dropParsed.quickChoices, ['a', 'b', 'c', 'd']);
    });
  });
}
