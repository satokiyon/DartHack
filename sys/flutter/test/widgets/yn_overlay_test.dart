import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/yn_overlay.dart';

void main() {
  Widget buildTestWidget({
    required String question,
    String choices = '',
    int defaultChoice = 0,
    Locale locale = const Locale('ja'),
    required Function(int) onSelect,
    Function(String)? onSelectText,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            YnOverlay(
              question: question,
              choices: choices,
              defaultChoice: defaultChoice,
              onSelect: onSelect,
              onSelectText: onSelectText,
              onShowMsgHistory: () {},
              bottomInset: 0,
            ),
          ],
        ),
      ),
    );
  }

  group('YnOverlay Widget Tests', () {
    testWidgets('標準 YN プロンプトで Yes / No ボタンが表示されタップできること', (tester) async {
      int? selected;
      await tester.pumpWidget(
        buildTestWidget(
          question: '本当にゲームを終了しますか? [y/n]',
          onSelect: (code) => selected = code,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(selected, equals('y'.codeUnitAt(0)));
    });

    testWidgets('#adjust スロット選択でチップと?ボタンが表示されタップできること', (tester) async {
      int? selected;
      await tester.pumpWidget(
        buildTestWidget(
          question: 'スロット文字を調整 移動先はどこにしますか [c-z]? (?で使用中の文字を表示)',
          onSelect: (code) => selected = code,
        ),
      );
      await tester.pumpAndSettle();

      // チップ 'c', 'd' が表示されていること
      expect(find.text('c'), findsOneWidget);
      expect(find.text('d'), findsOneWidget);

      // 'c' をタップ
      await tester.tap(find.text('c'));
      await tester.pumpAndSettle();
      expect(selected, equals('c'.codeUnitAt(0)));

      // '? 使用中スロット' ボタンが存在すること
      expect(find.text('? 使用中スロット'), findsOneWidget);
    });

    testWidgets('スタック分割プロンプトでテンキー操作（複数桁・削除・クリア・決定）と数量テキスト入力が動作すること', (tester) async {
      String? submittedText;
      await tester.pumpWidget(
        buildTestWidget(
          question: 'いくつ分けますか?',
          onSelect: (_) {},
          onSelectText: (text) => submittedText = text,
        ),
      );
      await tester.pumpAndSettle();

      // 数字チップ '2' をタップ -> 即確定せず入力欄に '2' が入る
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(submittedText, isNull);
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);

      // 数字チップ '0' をタップ -> '20' になる
      expect(find.text('0'), findsOneWidget);
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      expect(submittedText, isNull);
      expect(find.widgetWithText(TextField, '20'), findsOneWidget);

      // '⌫' (削除) ボタンをタップ -> '2' に戻る
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);

      // '5' をタップ -> '25' になる
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '25'), findsOneWidget);

      // 「決定」をタップ -> '25' で確定
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();
      expect(submittedText, equals('25'));

      // 'C' (クリア) ボタンの検証
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '9'), findsOneWidget);
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, ''), findsOneWidget);
    });

    testWidgets('水晶玉探知プロンプトで主要記号チップが表示されること', (tester) async {
      int? selected;
      await tester.pumpWidget(
        buildTestWidget(
          question: '何をお探しですか?',
          onSelect: (code) => selected = code,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$'), findsOneWidget);
      expect(find.text(')'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);

      await tester.tap(find.text('\$'));
      await tester.pumpAndSettle();
      expect(selected, equals('\$'.codeUnitAt(0)));
    });

    testWidgets('英語モード時に英語ラベル (OK, ? Used Slots, All) が表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          question: 'Adjust letter to what [c-z]? (? to see used letters)',
          onSelect: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('? Used Slots'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}

