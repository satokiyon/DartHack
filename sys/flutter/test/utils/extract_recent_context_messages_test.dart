import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/msg_history_dialog.dart';


void main() {
  group('extractRecentContextMessages テスト', () {
    test('空のメッセージ履歴の場合は空リストを返すこと', () {
      final result = extractRecentContextMessages([]);
      expect(result, isEmpty);
    });

    test('直近のメッセージが最大件数（デフォルト6行）まで時系列順で抽出されること', () {
      final history = [
        'メッセージ1',
        'メッセージ2',
        'メッセージ3',
        'メッセージ4',
        'メッセージ5',
        'メッセージ6',
        'メッセージ7',
        'メッセージ8',
      ];
      final result = extractRecentContextMessages(history);
      expect(result, [
        'メッセージ3',
        'メッセージ4',
        'メッセージ5',
        'メッセージ6',
        'メッセージ7',
        'メッセージ8',
      ]);
    });

    test('空行や空白文字のみの行が除外されること', () {
      final history = [
        '巻物を読んだ。',
        '',
        '   ',
        'あなたはテレポートした！',
      ];
      final result = extractRecentContextMessages(history);
      expect(result, [
        '巻物を読んだ。',
        'あなたはテレポートした！',
      ]);
    });

    test('-- MORE -- 制御行が除外されること', () {
      final history = [
        '炎が立ち込めた！',
        '-- MORE --',
        '--more--',
        'あなたは死んでしまった...',
      ];
      final result = extractRecentContextMessages(history);
      expect(result, [
        '炎が立ち込めた！',
        'あなたは死んでしまった...',
      ]);
    });

    test('プロンプト文と重複する行が除外されること', () {
      final history = [
        '巻物はまばゆい光を放って消えた。',
        'この巻物を何と呼びますか?',
      ];
      final result = extractRecentContextMessages(
        history,
        prompt: 'この巻物を何と呼びますか?',
      );
      expect(result, [
        '巻物はまばゆい光を放って消えた。',
      ]);
    });

    test('英語プロンプトでも大文字小文字を無視して重複が除外されること', () {
      final history = [
        'The scroll turns to dust.',
        'What do you want to call this scroll?',
      ];
      final result = extractRecentContextMessages(
        history,
        prompt: 'what do you want to call this scroll?',
      );
      expect(result, [
        'The scroll turns to dust.',
      ]);
    });
  });

  group('shouldShowRecentMessagesInDialog 判定テスト', () {
    test('アイテム名前付け・呼び名プロンプト（日英）で true を返すこと', () {
      expect(shouldShowRecentMessagesInDialog('この巻物を何と呼びますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('この液体を何と呼びますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('この薬を何と名付けますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('このアイテムに名前を付けますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Call a scroll:'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Call a potion:'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Call a wand:'), isTrue);
      expect(shouldShowRecentMessagesInDialog('What do you want to call this scroll?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('What do you want to name this sword?'), isTrue);
    });

    test('死亡直後の持ち物識別表示および bones 保存プロンプト（日英）で true を返すこと', () {
      // 日本語
      expect(shouldShowRecentMessagesInDialog('持ち物を識別表示しますか? [ynq] (y)'), isTrue);
      expect(shouldShowRecentMessagesInDialog('死亡時点の所持品を表示しますか? [ynq] (y)'), isTrue);
      expect(shouldShowRecentMessagesInDialog('bones ファイルを保存しますか? [yn] (n)'), isTrue);

      // 英語
      expect(shouldShowRecentMessagesInDialog('Do you want your possessions identified? [ynq] (y)'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Do you want to see what you had when you died? [ynq] (y)'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Save bones? [yn] (n)'), isTrue);
    });

    test('死亡後の後続統計・記録ダイアログ（日英）で false を返すこと', () {
      // 日本語（後続ダイアログは表示不要）
      expect(shouldShowRecentMessagesInDialog('能力値を表示しますか? [yn] (n)'), isFalse);
      expect(shouldShowRecentMessagesInDialog('倒した怪物の一覧を表示しますか? [yn] (n)'), isFalse);
      expect(shouldShowRecentMessagesInDialog('行跡を表示しますか? [yn] (n)'), isFalse);
      expect(shouldShowRecentMessagesInDialog('墓石を見ますか? [yn] (n)'), isFalse);

      // 英語（後続ダイアログは表示不要）
      expect(shouldShowRecentMessagesInDialog('Do you want to see your attributes? [yn] (n)'), isFalse);
      expect(shouldShowRecentMessagesInDialog('Do you want to see the creatures vanquished? [yn] (n)'), isFalse);
      expect(shouldShowRecentMessagesInDialog('Do you want to see your conduct? [yn] (n)'), isFalse);
    });

    test('危険行動警告およびテレポート確認（日英）で true を返すこと', () {
      expect(shouldShowRecentMessagesInDialog('本当に飲みますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('本当に攻撃しますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('本当に飛び込みますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('本当にその毒ガスの雲へ入るか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('本当にその溶岩へ進むか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('本当に祈りを捧げますか？'), isTrue);
      expect(shouldShowRecentMessagesInDialog('食事を続けますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('テレポートしますか?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('飛び込みますか?'), isTrue);

      // 英語
      expect(shouldShowRecentMessagesInDialog('Really attack the peaceful dog?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Really drink this?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Really enter that cloud of gas?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Really move into the lava?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Are you sure you want to attack?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Are you sure you want to pray?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Are you really sure you want to break that wand?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Continue eating?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Teleport?'), isTrue);
      expect(shouldShowRecentMessagesInDialog('Jump in?'), isTrue);
    });

    test('対象外プロンプト（拡張コマンド、注釈メモ、終了確認、通常確認）で false を返すこと', () {
      // 拡張コマンド
      expect(shouldShowRecentMessagesInDialog('拡張コマンドを入力してください:'), isFalse);
      expect(shouldShowRecentMessagesInDialog('#'), isFalse);

      // マップ注釈メモ
      expect(shouldShowRecentMessagesInDialog('注釈を入力してください:'), isFalse);
      expect(shouldShowRecentMessagesInDialog('What is the annotation?'), isFalse);
      expect(shouldShowRecentMessagesInDialog('Replace annotation:'), isFalse);

      // ゲーム終了確認（Really quit?）
      expect(shouldShowRecentMessagesInDialog('本当に終了しますか?'), isFalse);
      expect(shouldShowRecentMessagesInDialog('Really quit?'), isFalse);

      // 通常確認
      expect(shouldShowRecentMessagesInDialog('階段を降りますか?'), isFalse);
      expect(shouldShowRecentMessagesInDialog('扉を開けますか?'), isFalse);
      expect(shouldShowRecentMessagesInDialog(''), isFalse);
    });
  });
}

