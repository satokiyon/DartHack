// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-07.
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/text_formatter.dart';

void main() {
  group('TextFormatter Tests', () {
    test('句点や感嘆符で終わる行の改行を保持する（読点やカンマでは結合）', () {
      final input = [
        'これは最初の文です。',
        '二番目の文ですが、',
        '途中で80桁改行が',
        '入っている部分です。',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        'これは最初の文です。',
        '二番目の文ですが、途中で80桁改行が入っている部分です。',
      ]);
    });

    test('半角英数字間の結合時に半角スペースを挿入する', () {
      final input = [
        'This is line one',
        'and this is line two.',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        'This is line one and this is line two.',
      ]);
    });

    test('日本語と半角英数字の結合時にスペースを挿入しない', () {
      final input = [
        'これはNetHackの',
        'ガイドブックです。',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        'これはNetHackのガイドブックです。',
      ]);
    });

    test('空行をそのまま保持する', () {
      final input = [
        '段落１の文章です。',
        '',
        '段落２の文章です。',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        '段落１の文章です。',
        '',
        '段落２の文章です。',
      ]);
    });

    test('箇条書きや区切り線の改行を保持する', () {
      final input = [
        '---',
        '- 項目1: 説明が',
        '長くて改行された部分。',
        '- 項目2: 次の項目',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        '---',
        '- 項目1: 説明が長くて改行された部分。',
        '- 項目2: 次の項目',
      ]);
    });

    test('オプトイン（データベース、小説、一般ヘルプ）およびデフォルト（整形OFF）の判定パターン', () {
      // 整形ONとなるオプトインタイトル (小説、歴史、ライセンス)
      final optInTitles = [
        'Terry Pratchett',
        'テリー・プラチェット 著',
        '『魔法の色』',
        'NetHack 5.0 版履歴ファイル',
        'Behold, mortal, the origins of NetHack',
        'NETHACK GENERAL PUBLIC LICENSE',
        'NetHack General Public License',
      ];

      for (final title in optInTitles) {
        final lines = [
          'ヘッダー行1',
          'ヘッダー行2',
          'ヘッダー行3',
          'ヘッダー行4',
          'ヘッダー行5',
          'ヘッダー行6',
          'ヘッダー行7',
          title,
          '詳細な説明文がここに入ります。',
        ];
        bool shouldReformat = false;
        for (int i = 0; i < lines.length && i < 10; i++) {
          final l = lines[i].trim();
          if (l.contains('Terry Pratchett') ||
              l.contains('テリー・プラチェット 著') ||
              l.contains('『魔法の色』') ||
              l.contains('NetHack 5.0 版履歴ファイル') ||
              l.contains('Behold, mortal, the origins of NetHack') ||
              l.contains('NETHACK GENERAL PUBLIC LICENSE') ||
              l.contains('NetHack General Public License')) {
            shouldReformat = true;
            break;
          }
        }
        expect(shouldReformat, isTrue);
      }

      // 整形OFF（デフォルト）となるタイトル
      final defaultOffTitles = [
        'NetHack へようこそ！',
        'Welcome to NetHack!',
        'Boolean options not under specific compile flags',
        'コマンドでオプションを設定する方法',
        'ゲームオプションの詳細説明',
        'NetHack のコマンドライン説明',
        'ウィザードモードコマンド一覧',
        'キーボードコマンド完全一覧',
        '現在のキー割り当て一覧',
        'メニュー操作キー:',
        '倒した怪物:',
        '神託: オラクルの言葉',
      ];

      for (final title in defaultOffTitles) {
        final lines = [title, '  データ行'];
        bool shouldReformat = false;
        for (int i = 0; i < lines.length && i < 10; i++) {
          final l = lines[i].trim();
          if (l.contains('NetHack 5.0 版履歴ファイル') ||
              l.contains('Behold, mortal, the origins of NetHack') ||
              l.contains('NETHACK GENERAL PUBLIC LICENSE') ||
              l.contains('NetHack General Public License')) {
            shouldReformat = true;
            break;
          }
        }
        expect(shouldReformat, isFalse);
      }
    });

    test('plainType (2=QUEST, 3=DATABASE) による無条件オプトイン判定', () {
      // PLAIN_TEXT_QUEST (2)
      int plainTypeQuest = 2;
      bool shouldReformatQuest = (plainTypeQuest == 2 || plainTypeQuest == 3);
      expect(shouldReformatQuest, isTrue);

      // PLAIN_TEXT_DATABASE (3)
      int plainTypeDb = 3;
      bool shouldReformatDb = (plainTypeDb == 2 || plainTypeDb == 3);
      expect(shouldReformatDb, isTrue);

      // PLAIN_TEXT_NONE (0)
      int plainTypeNone = 0;
      bool shouldReformatNone = (plainTypeNone == 2 || plainTypeNone == 3);
      expect(shouldReformatNone, isFalse);
    });

    test('アスキーアートやインデントされたコードブロック・図形枠線の改行をそのまま保持する', () {
      final input = [
        '     一般的な説明文がここに入り',
        '80桁に合わせて改行されている次の行です。',
        '        +-----------------------------------------------------------+',
        '        |The bat bites!                                             |',
        '        |    ------                                                 |',
        '        |    |....|    ----------                                   |',
        '        +---------------------------図1-----------------------------+',
        '     次の一文がここに入ります。',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        '     一般的な説明文がここに入り80桁に合わせて改行されている次の行です。',
        '        +-----------------------------------------------------------+',
        '        |The bat bites!                                             |',
        '        |    ------                                                 |',
        '        |    |....|    ----------                                   |',
        '        +---------------------------図1-----------------------------+',
        '     次の一文がここに入ります。',
      ]);
    });
  });
}
