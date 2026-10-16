import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/any_key_overlay.dart';

void main() {
  Widget buildTestWidget({
    required Locale locale,
    required String question,
    required Function(int) onSelect,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            AnyKeyOverlay(
              question: question,
              defaultChoice: 0,
              onSelect: onSelect,
              onClose: () {},
              onShowMsgHistory: () {},
              bottomInset: 0,
            ),
          ],
        ),
      ),
    );
  }

  group('AnyKeyOverlay 修飾子ラベルおよびQWERTYキーパッドのテスト', () {
    testWidgets('日本語モードで日本語修飾子ラベルが表示されること', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('ja'),
          question: 'どのキーの機能を調べますか？',
          onSelect: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shift (大文字)'), findsOneWidget);
      expect(find.text('Ctrl (^キー)'), findsOneWidget);
      expect(find.text('Meta (Alt)'), findsOneWidget);

      // Shiftをタップすると [ON] になる
      await tester.tap(find.text('Shift (大文字)'));
      await tester.pumpAndSettle();
      expect(find.text('Shift (大文字) [ON]'), findsOneWidget);

      // Ctrlをタップすると [ON] になる
      await tester.tap(find.text('Ctrl (^キー)'));
      await tester.pumpAndSettle();
      expect(find.text('Ctrl (^キー) [ON]'), findsOneWidget);
    });

    testWidgets('英語モードで英語修飾子ラベルが表示され、日本語が混入しないこと', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          question: 'What key do you want explained?',
          onSelect: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shift (Caps)'), findsOneWidget);
      expect(find.text('Ctrl (^)'), findsOneWidget);
      expect(find.text('Meta (Alt)'), findsOneWidget);

      // 日本語の語句が含まれていないこと
      expect(find.textContaining('大文字'), findsNothing);
      expect(find.textContaining('^キー'), findsNothing);

      // Shiftをタップすると [ON] になる
      await tester.tap(find.text('Shift (Caps)'));
      await tester.pumpAndSettle();
      expect(find.text('Shift (Caps) [ON]'), findsOneWidget);

      // Ctrlをタップすると [ON] になる
      await tester.tap(find.text('Ctrl (^)'));
      await tester.pumpAndSettle();
      expect(find.text('Ctrl (^) [ON]'), findsOneWidget);

      // 日本語の語句が依然として含まれていないこと
      expect(find.textContaining('大文字'), findsNothing);
      expect(find.textContaining('^キー'), findsNothing);
    });

    testWidgets('QWERTY配列で文字が表示され、タップ時に正しいコードが送信されること', (tester) async {
      int sentCode = 0;
      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          question: 'What key do you want explained?',
          onSelect: (code) => sentCode = code,
        ),
      );
      await tester.pumpAndSettle();

      // QWERTYの先頭キー 'q' が表示されていること
      final qKey = find.text('q');
      expect(qKey, findsOneWidget);

      await tester.tap(qKey);
      await tester.pumpAndSettle();
      expect(sentCode, equals('q'.codeUnitAt(0)));

      // Shift を ON にすると 'Q' になること
      await tester.tap(find.text('Shift (Caps)'));
      await tester.pumpAndSettle();

      final capitalQKey = find.text('Q');
      expect(capitalQKey, findsOneWidget);

      await tester.tap(capitalQKey);
      await tester.pumpAndSettle();
      expect(sentCode, equals('Q'.codeUnitAt(0)));
    });
  });
}

