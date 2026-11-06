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

      // Cコア標準の「(?で使用中の文字を表示)?」形式でも正しくパースされること
      final parsedCore = YnChoiceParser.parse(
        question: '何の文字に調整しますか [c-z] (?で使用中の文字を表示)? ',
        choices: '',
      );
      expect(parsedCore.type, YnPromptType.slotSelect);
      expect(parsedCore.quickChoices.first, 'c');
      expect(parsedCore.quickChoices.last, 'z');
      expect(parsedCore.hasHelpOption, isTrue);
    });

    test('日本語 getobj スロット選択プロンプト ([ab または ?*]) を slotSelect としてパースする', () {
      final parsed = YnChoiceParser.parse(
        question: 'どのアイテムを順番を入れ替えますか？ [ab または ?*] ',
        choices: '',
      );
      expect(parsed.type, YnPromptType.slotSelect);
      expect(parsed.quickChoices, ['a', 'b']);
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

  group('YnChoiceParser.resolveButtonLabel', () {
    test('討伐怪物一覧プロンプトで a が並び順指定になる (デフォルト: キー表記なし)', () {
      const qJp = '倒した怪物の一覧を表示しますか?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true), '並び順を指定');
      expect(YnChoiceParser.resolveButtonLabel('y', question: qJp, isJapanese: true), 'はい');
      expect(YnChoiceParser.resolveButtonLabel('n', question: qJp, isJapanese: true), 'いいえ');
      expect(YnChoiceParser.resolveButtonLabel('q', question: qJp, isJapanese: true), '中断');

      const qEn = 'Do you want an account of creatures vanquished?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false), 'Sort order');
      expect(YnChoiceParser.resolveButtonLabel('y', question: qEn, isJapanese: false), 'Yes');
      expect(YnChoiceParser.resolveButtonLabel('n', question: qEn, isJapanese: false), 'No');
      expect(YnChoiceParser.resolveButtonLabel('q', question: qEn, isJapanese: false), 'Quit');
    });

    test('討伐怪物一覧プロンプトで useKeyboardNotation: true の場合はキー表記が付くこと', () {
      const qJp = '倒した怪物の一覧を表示しますか?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true, useKeyboardNotation: true), 'a:並び順を指定');
      expect(YnChoiceParser.resolveButtonLabel('y', question: qJp, isJapanese: true, useKeyboardNotation: true), 'y:はい');
      expect(YnChoiceParser.resolveButtonLabel('n', question: qJp, isJapanese: true, useKeyboardNotation: true), 'n:いいえ');
      expect(YnChoiceParser.resolveButtonLabel('q', question: qJp, isJapanese: true, useKeyboardNotation: true), 'q:中断');

      const qEn = 'Do you want an account of creatures vanquished?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false, useKeyboardNotation: true), 'a: Sort order');
      expect(YnChoiceParser.resolveButtonLabel('y', question: qEn, isJapanese: false, useKeyboardNotation: true), 'y: Yes');
      expect(YnChoiceParser.resolveButtonLabel('n', question: qEn, isJapanese: false, useKeyboardNotation: true), 'n: No');
      expect(YnChoiceParser.resolveButtonLabel('q', question: qEn, isJapanese: false, useKeyboardNotation: true), 'q: Quit');
    });

    test('虐殺・絶滅怪物一覧プロンプトで a が並び順指定になる', () {
      const qJp = '虐殺・絶滅した怪物種の一覧を表示しますか?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true), '並び順を指定');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true, useKeyboardNotation: true), 'a:並び順を指定');

      const qEn = 'Do you want to see a list of genocided species?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false), 'Sort order');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false, useKeyboardNotation: true), 'a: Sort order');
    });

    test('キャラメイクおまかせプロンプトで a がすべておまかせ / Pick all になる', () {
      const qJp = 'おまかせでキャラクターの種族、役割、性別、属性を選びますか? [ynaq]';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true), 'すべておまかせ');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true, useKeyboardNotation: true), 'a:すべておまかせ');

      const qEn = "Shall I pick a character's race, role, gender and alignment for you? [ynaq]";
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false), 'Pick all');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false, useKeyboardNotation: true), 'a: Pick all');
    });

    test('アイテム連続処理プロンプトで a がすべて / All になり、大文字Nが全ていいえになる', () {
      const qJp = '大きな箱を取り出しますか?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true), 'すべて');
      expect(YnChoiceParser.resolveButtonLabel('N', question: qJp, isJapanese: true), '全ていいえ');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qJp, isJapanese: true, useKeyboardNotation: true), 'a:すべて');
      expect(YnChoiceParser.resolveButtonLabel('N', question: qJp, isJapanese: true, useKeyboardNotation: true), 'N:全ていいえ');

      const qEn = 'Drop an uncursed dagger?';
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false), 'All');
      expect(YnChoiceParser.resolveButtonLabel('N', question: qEn, isJapanese: false), 'No to all');
      expect(YnChoiceParser.resolveButtonLabel('a', question: qEn, isJapanese: false, useKeyboardNotation: true), 'a: All');
      expect(YnChoiceParser.resolveButtonLabel('N', question: qEn, isJapanese: false, useKeyboardNotation: true), 'N: No to all');
    });

    test('特殊な2択プロンプト (隠れる/クモの巣、指輪の左右) のラベル解決', () {
      const qWeb = '隠れる [h] か、クモの巣を張る [s] か、どちらにしますか?';
      expect(YnChoiceParser.resolveButtonLabel('h', question: qWeb, isJapanese: true), '隠れる');
      expect(YnChoiceParser.resolveButtonLabel('s', question: qWeb, isJapanese: true), 'クモの巣');
      expect(YnChoiceParser.resolveButtonLabel('h', question: qWeb, isJapanese: true, useKeyboardNotation: true), 'h:隠れる');
      expect(YnChoiceParser.resolveButtonLabel('s', question: qWeb, isJapanese: true, useKeyboardNotation: true), 's:クモの巣');

      const qWebEn = 'hide in web [h] or spin web [s]?';
      expect(YnChoiceParser.resolveButtonLabel('h', question: qWebEn, isJapanese: false), 'Hide');
      expect(YnChoiceParser.resolveButtonLabel('s', question: qWebEn, isJapanese: false), 'Spin web');
      expect(YnChoiceParser.resolveButtonLabel('h', question: qWebEn, isJapanese: false, useKeyboardNotation: true), 'h: Hide');
      expect(YnChoiceParser.resolveButtonLabel('s', question: qWebEn, isJapanese: false, useKeyboardNotation: true), 's: Spin web');

      const qRing = 'どちらの指にはめますか? [r/l]';
      expect(YnChoiceParser.resolveButtonLabel('r', question: qRing, isJapanese: true), '右');
      expect(YnChoiceParser.resolveButtonLabel('l', question: qRing, isJapanese: true), '左');
      expect(YnChoiceParser.resolveButtonLabel('r', question: qRing, isJapanese: true, useKeyboardNotation: true), 'r:右');
      expect(YnChoiceParser.resolveButtonLabel('l', question: qRing, isJapanese: true, useKeyboardNotation: true), 'l:左');

      const qRingEn = 'Which ring finger, right or left? [r/l]';
      expect(YnChoiceParser.resolveButtonLabel('r', question: qRingEn, isJapanese: false), 'Right');
      expect(YnChoiceParser.resolveButtonLabel('l', question: qRingEn, isJapanese: false), 'Left');
      expect(YnChoiceParser.resolveButtonLabel('r', question: qRingEn, isJapanese: false, useKeyboardNotation: true), 'r: Right');
      expect(YnChoiceParser.resolveButtonLabel('l', question: qRingEn, isJapanese: false, useKeyboardNotation: true), 'l: Left');
    });

    test('未知の文字キーはキー文字単体でフォールバックする', () {
      expect(YnChoiceParser.resolveButtonLabel('x', question: 'test?', isJapanese: true), 'x');
    });
  });
}
