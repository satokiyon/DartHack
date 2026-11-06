import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';

void main() {
  Widget buildTestWidget({
    required KeyboardHelpContext helpContext,
    int menuHow = 0,
    Locale locale = const Locale('ja'),
    bool isJapanese = true,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                KeyboardHelpDialog.show(
                  ctx,
                  helpContext: helpContext,
                  menuHow: menuHow,
                  isJapanese: isJapanese,
                );
              },
              child: const Text('Open Help'),
            ),
          ),
        ),
      ),
    );
  }

  group('KeyboardHelpDialog Tests', () {
    testWidgets('menuHow == 0 (閲覧専用メニュー) では数量指定の項目が表示されないこと', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 0,
      ));

      // ダイアログを開く
      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定関連のテキストが存在しないことを確認
      expect(find.textContaining('0〜9'), findsNothing);
      expect(find.textContaining('数量指定'), findsNothing);

      // 基本的なメニュー操作は表示されていること
      expect(find.textContaining('Space'), findsWidgets);
      expect(find.textContaining('Esc'), findsWidgets);
    });

    testWidgets('menuHow == 1 (単一選択メニュー) では数量指定の項目が表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 1,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定関連のテキストが表示されていること
      expect(find.textContaining('0 〜 9'), findsOneWidget);
      expect(find.textContaining('BackSpace'), findsOneWidget);
      expect(find.textContaining('数量'), findsWidgets);
    });

    testWidgets('menuHow == 2 (複数選択メニュー) では一括操作と数量指定が表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 2,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定および一括選択が表示されていること
      expect(find.textContaining('0 〜 9'), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('@'), findsOneWidget);
      expect(find.textContaining('menu_select_all'), findsOneWidget);
      expect(find.textContaining('menu_deselect_all'), findsOneWidget);
      expect(find.textContaining('menu_invert_all'), findsOneWidget);
    });

    testWidgets('F1 キー押下でダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // F1 キーを送信
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('Escape キー押下でダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // Escape キーを送信
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('閉じるアイコンボタンをタップするとダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.yn,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 閉じるアイコン (Icons.close_rounded) をタップ
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });
  });
}

