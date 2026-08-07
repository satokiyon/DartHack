// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-07.
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/text_formatter.dart';

void main() {
  group('TextFormatter Tests', () {
    test('句読点や感嘆符で終わる行の改行を保持する', () {
      final input = [
        'これは最初の文です。',
        '二番目の文ですが、',
        '途中で80桁改行が',
        '入っている部分です。',
      ];

      final result = TextFormatter.reformatLines(input);

      expect(result, [
        'これは最初の文です。',
        '二番目の文ですが、',
        '途中で80桁改行が入っている部分です。',
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

    test('対象外（キー割り当て、倒した怪物、自主的な縛り等）の判定パターン', () {
      final skipTitles = [
        '現在のキー割り当て一覧',
        'メニュー操作キー:',
        '倒した怪物:',
        '虐殺した怪物種:',
        '絶滅した怪物種:',
        '虐殺・絶滅した怪物種:',
        '自主的な縛り:',
        '達成事項:',
        '記録済みイベント:',
        '主要イベント:',
        '最終能力:',
        '死亡数 生成数',
      ];

      for (final title in skipTitles) {
        final lines = [title, '  10  オーガ', '  5   トロル'];
        bool shouldSkip = false;
        for (int i = 0; i < lines.length && i < 5; i++) {
          final l = lines[i].trim();
          if (l.contains('現在のキー割り当て一覧') ||
              l.startsWith('メニュー操作キー:') ||
              l.startsWith('倒した怪物:') ||
              l.startsWith('虐殺した怪物種:') ||
              l.startsWith('絶滅した怪物種:') ||
              l.startsWith('虐殺・絶滅した怪物種:') ||
              l.startsWith('自主的な縛り:') ||
              l.startsWith('達成事項:') ||
              l.startsWith('記録済みイベント:') ||
              l.startsWith('主要イベント:') ||
              l.startsWith('最終能力:') ||
              l.contains('死亡数 生成数')) {
            shouldSkip = true;
            break;
          }
        }
        expect(shouldSkip, isTrue);
      }

      final deathLines = [
        '運命の大迷宮:',
        '  1階: <- ここで倒れた。',
        '最終能力:',
        '  属性: 秩序',
      ];
      final isDeathContent = deathLines.any((l) =>
          l.contains('<- ここで倒れた。') ||
          l.contains('<- ここから脱出した。') ||
          l.contains('最終能力:'));
      expect(isDeathContent, isTrue);
    });
  });
}
