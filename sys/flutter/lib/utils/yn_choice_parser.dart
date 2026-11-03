/// YN プロンプトの解析結果および種別定義
enum YnPromptType {
  /// 標準的な二者択一・多肢 (y/n, y/n/q, ynaq, h/s, r/l 等)
  yesNo,

  /// スロット文字選択 ([c-z], [a-z], 移動先はどこにしますか 等)
  slotSelect,

  /// 数量入力 (いくつ分けますか?, Split off how many? 等)
  countInput,

  /// 地図記号探知 (何をお探しですか?, What do you look for? 等)
  symbolDetect,

  /// 汎用1文字入力
  genericChar,
}

/// 解析済みの YN プロンプト情報
class ParsedYnPrompt {
  final YnPromptType type;

  /// 画面に並べるボタントークン (チップ一覧)
  final List<String> quickChoices;

  /// 物理キーボードで受容する文字集合 (空の場合は全文字許容)
  final Set<String> validKeyChars;

  /// テキスト入力欄 (TextField) を併設するかどうか
  final bool allowsFreeInput;

  /// '?' による一覧表示・ヘルプ機能があるか
  final bool hasHelpOption;

  /// デフォルトの選択文字コード (0 は未設定)
  final int defaultChoice;

  const ParsedYnPrompt({
    required this.type,
    required this.quickChoices,
    required this.validKeyChars,
    required this.allowsFreeInput,
    required this.hasHelpOption,
    required this.defaultChoice,
  });

  /// 従来の Yes/No/Quit の大型ボタン表示対象かどうか
  bool get isYesNo => type == YnPromptType.yesNo;
}

/// YN プロンプト文字列および choices から質問種別や選択肢を解析するユーティリティ
class YnChoiceParser {
  /// 代表的な地図・探索記号チップ
  static const List<String> defaultSymbolChoices = [
    '\$', ')', '(', '%', '!', '?', '/', '=', '+', '[', ']', '*', '@',
  ];

  /// 数量入力用の数字チップ (1〜9, 0)
  static const List<String> defaultCountChoices = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
  ];

  /// ハイフン範囲表記 (例: c-z, a-e, A-Z, 0-9) を個別の文字リストへ展開
  static List<String> expandRangeString(String raw) {
    final result = <String>[];
    final seen = <String>{};

    void addChar(String ch) {
      if (!seen.contains(ch)) {
        seen.add(ch);
        result.add(ch);
      }
    }

    // 英語の " or " や日本語の " または " などの接続語を除去
    final cleaned = raw
        .replaceAll(RegExp(r'\bor\b', caseSensitive: false), ' ')
        .replaceAll('または', ' ');

    int i = 0;
    while (i < cleaned.length) {
      if (i + 2 < cleaned.length && cleaned[i + 1] == '-') {
        final start = cleaned.codeUnitAt(i);
        final end = cleaned.codeUnitAt(i + 2);
        if (start <= end &&
            ((start >= 97 && end <= 122) || // a-z
             (start >= 65 && end <= 90) ||  // A-Z
             (start >= 48 && end <= 57))) { // 0-9
          for (int code = start; code <= end; code++) {
            addChar(String.fromCharCode(code));
          }
          i += 3;
          continue;
        }
      }

      final ch = cleaned[i];
      if (ch != ' ' && ch != ',' && ch != '[' && ch != ']' && ch != '/') {
        addChar(ch);
      }
      i++;
    }

    return result;
  }

  /// プロンプト文字列および choices を解析して [ParsedYnPrompt] を生成
  static ParsedYnPrompt parse({
    required String question,
    required String choices,
    int defaultChoice = 0,
  }) {
    final rawChoices = choices.contains('\x1b')
        ? choices.substring(0, choices.indexOf('\x1b'))
        : choices;
    final lowerQ = question.toLowerCase();

    // 1. 数量入力 (いくつ分けますか?, Split off how many? 等)
    if (question.contains('いくつ分けますか') ||
        lowerQ.contains('split off how many')) {
      return ParsedYnPrompt(
        type: YnPromptType.countInput,
        quickChoices: defaultCountChoices,
        validKeyChars: {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'},
        allowsFreeInput: true,
        hasHelpOption: false,
        defaultChoice: defaultChoice,
      );
    }

    // 2. 地図記号探知 (何をお探しですか?, What do you look for? 等)
    if (question.contains('何をお探しですか') ||
        lowerQ.contains('what do you look for')) {
      return ParsedYnPrompt(
        type: YnPromptType.symbolDetect,
        quickChoices: defaultSymbolChoices,
        validKeyChars: const {}, // 全文字許容
        allowsFreeInput: true,
        hasHelpOption: false,
        defaultChoice: defaultChoice,
      );
    }

    // 3. スロット文字選択 (#adjust や伝統的呪文・アイテムプロンプト)
    final isSlotPrompt = question.contains('移動先はどこにしますか') ||
        lowerQ.contains('adjust letter to what') ||
        question.contains('スロット文字を調整') ||
        question.contains('どの呪文を唱えますか') ||
        lowerQ.contains('cast which spell');

    // ブラケット [ ... ] からの範囲抽出
    final bracketMatch = RegExp(r'\[([^\]]+)\]').firstMatch(question);
    final bracketContent = bracketMatch?.group(1) ?? '';
    final hasRangeNotation = bracketContent.contains('-');

    if (isSlotPrompt || hasRangeNotation) {
      final expanded = expandRangeString(bracketContent.isNotEmpty ? bracketContent : rawChoices);
      final hasHelp = question.contains('?') || bracketContent.contains('?');
      return ParsedYnPrompt(
        type: YnPromptType.slotSelect,
        quickChoices: expanded.where((c) => c != '?' && c != '*').toList(),
        validKeyChars: const {}, // 全アルファベット・記号の入力を許容
        allowsFreeInput: true,
        hasHelpOption: hasHelp,
        defaultChoice: defaultChoice,
      );
    }

    // 4. キャラメイクのおまかせプロンプト (Shall I pick ... [ynaq])
    if (lowerQ.contains('shall i pick') || question.contains('おまかせで')) {
      return ParsedYnPrompt(
        type: YnPromptType.yesNo,
        quickChoices: const ['y', 'n', 'a', 'q'],
        validKeyChars: {'y', 'n', 'a', 'q'},
        allowsFreeInput: false,
        hasHelpOption: false,
        defaultChoice: defaultChoice != 0 ? defaultChoice : 'y'.codeUnitAt(0),
      );
    }

    // 5. choices が直接指定されている場合 (例: "hs", "rl", "ynq", "ynaq" 等)
    if (rawChoices.isNotEmpty) {
      final choiceList = rawChoices.split('');
      return ParsedYnPrompt(
        type: YnPromptType.yesNo,
        quickChoices: choiceList,
        validKeyChars: choiceList.toSet(),
        allowsFreeInput: false,
        hasHelpOption: rawChoices.contains('?'),
        defaultChoice: defaultChoice,
      );
    }

    // 6. プロンプト文から [y|n], [y/n], (y/n) 等の抽出
    if (lowerQ.contains('[y|n]') ||
        lowerQ.contains('[y/n]') ||
        lowerQ.contains('(y/n)') ||
        lowerQ.contains('[y/n/q]') ||
        lowerQ.contains('[y|n|q]') ||
        lowerQ.contains('adjust?')) {
      final hasQ = lowerQ.contains('q');
      return ParsedYnPrompt(
        type: YnPromptType.yesNo,
        quickChoices: hasQ ? const ['y', 'n', 'q'] : const ['y', 'n'],
        validKeyChars: hasQ ? {'y', 'n', 'q'} : {'y', 'n'},
        allowsFreeInput: false,
        hasHelpOption: false,
        defaultChoice: defaultChoice,
      );
    }

    // 7. ブラケット内の単純選択肢 (例: [h/s] や [r/l] など)
    if (bracketMatch != null && bracketContent.isNotEmpty) {
      final extracted = bracketContent.replaceAll(RegExp(r'[/| ]'), '');
      if (extracted.isNotEmpty) {
        final list = extracted.split('');
        return ParsedYnPrompt(
          type: YnPromptType.yesNo,
          quickChoices: list,
          validKeyChars: list.toSet(),
          allowsFreeInput: false,
          hasHelpOption: extracted.contains('?'),
          defaultChoice: defaultChoice,
        );
      }
    }

    // 8. デフォルト値が 'y' または 'n' の場合のフォールバック
    if (defaultChoice == 'y'.codeUnitAt(0) || defaultChoice == 'n'.codeUnitAt(0)) {
      return ParsedYnPrompt(
        type: YnPromptType.yesNo,
        quickChoices: const ['y', 'n'],
        validKeyChars: {'y', 'n'},
        allowsFreeInput: false,
        hasHelpOption: false,
        defaultChoice: defaultChoice,
      );
    }

    // 9. それ以外の汎用1文字入力
    return ParsedYnPrompt(
      type: YnPromptType.genericChar,
      quickChoices: const [],
      validKeyChars: const {}, // 全文字許容
      allowsFreeInput: true,
      hasHelpOption: false,
      defaultChoice: defaultChoice,
    );
  }

  /// 質問文と選択肢文字から、文脈に応じたボタン表示ラベルを取得する
  static String resolveButtonLabel(
    String keyChar, {
    required String question,
    required bool isJapanese,
  }) {
    final lowerQ = question.toLowerCase();

    // 1. 'a' キーの場合
    if (keyChar == 'a') {
      // (1) 討伐・絶滅怪物一覧の開示 (並び順の指定メニューを開く)
      if (question.contains('倒した怪物の一覧') ||
          question.contains('虐殺') ||
          question.contains('絶滅') ||
          lowerQ.contains('creatures vanquished') ||
          lowerQ.contains('genocided') ||
          lowerQ.contains('extinct')) {
        return isJapanese ? 'a:並び順を指定' : 'a: Sort order';
      }

      // (2) キャラメイクおまかせ
      if (question.contains('おまかせで') ||
          question.contains('キャラクターの種族') ||
          lowerQ.contains('shall i pick')) {
        return isJapanese ? 'a:すべておまかせ' : 'a: Pick all';
      }

      // (3) アイテム連続処理または汎用 All
      return isJapanese ? 'a:すべて' : 'a: All';
    }

    // 2. 'y', 'n', 'N', 'q' の基本キー
    if (keyChar == 'y') {
      return isJapanese ? 'y:はい' : 'y: Yes';
    }
    if (keyChar == 'n') {
      return isJapanese ? 'n:いいえ' : 'n: No';
    }
    if (keyChar == 'N') {
      return isJapanese ? 'N:全ていいえ' : 'N: No to all';
    }
    if (keyChar == 'q') {
      return isJapanese ? 'q:中断' : 'q: Quit';
    }

    // 3. 特殊な2択プロンプト
    if (keyChar == 'h' && (question.contains('隠れる') || lowerQ.contains('hide'))) {
      return isJapanese ? 'h:隠れる' : 'h: Hide';
    }
    if (keyChar == 's' && (question.contains('クモの巣') || lowerQ.contains('spin web'))) {
      return isJapanese ? 's:クモの巣' : 's: Spin web';
    }
    if (keyChar == 'r' && (question.contains('指') || lowerQ.contains('ring') || lowerQ.contains('hand'))) {
      return isJapanese ? 'r:右' : 'r: Right';
    }
    if (keyChar == 'l' && (question.contains('指') || lowerQ.contains('ring') || lowerQ.contains('hand'))) {
      return isJapanese ? 'l:左' : 'l: Left';
    }

    // 4. それ以外の汎用文字
    return keyChar;
  }
}

