import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/guidebook_dialog.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    await AppPrefs.setMockInitialValues({
      'selected_language': 'ja',
      'use_physical_keyboard_notation': true,
    });
    GuidebookDialog.resetSavedScrollPosition();
    SpoilerDialog.resetSavedScrollPosition();
  });

  const sampleMarkdown = '''
# 第1章 はじめに {#sec-1}

これはテスト用のテキストです。キーワード発見のテスト。

# 第2章 詳細 {#sec-2}

二つ目のキーワード発見の段落です。

# 第3章 まとめ {#sec-3}

三つ目のキーワード発見の段落です。
''';

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('GuidebookDialog 検索と物理キーボード操作テスト', () {
    testWidgets('検索UIの構成とTab巡回、n/Nショートカット、Enter/Shift+Enterジャンプの検証', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const GuidebookDialog(
            initialContent: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 初期状態では前/次の一致ボタンは非表示
      expect(find.byTooltip('前の一致'), findsNothing);
      expect(find.byTooltip('次の一致'), findsNothing);

      // 2. 検索欄をタップして「キーワード」を入力
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'キーワード');
      await tester.pumpAndSettle();

      // 件数表示 (1/3) および前/次の一致ボタンが表示される
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byTooltip('前の一致'), findsOneWidget);
      expect(find.byTooltip('次の一致'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // 3. 検索欄フォーカス中の Enter で「次の一致」(2/3) へ進む
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // 4. 検索欄フォーカス中の Shift + Enter で「前の一致」(1/3) へ戻る
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // 5. Tab キーによるフォーカス巡回:
      // 現在 search -> Tab -> prevMatch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Enter で「前の一致」を実行 (1/3 から戻って 3/3 にループ)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);

      // Tab -> nextMatch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Space で「次の一致」を実行 (3/3 から進んで 1/3 にループ)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Tab -> peek
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Tab -> toc
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Tab -> close
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Tab -> none (本文閲覧状態)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 6. 本文閲覧状態で n キーを押すと「次の一致」(2/3) へ進む
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      // 本文閲覧状態で Shift + n (N) を押すと「前の一致」(1/3) へ戻る
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // 7. クリアボタンを押すと検索結果が消去される
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsNothing);
      expect(find.byTooltip('前の一致'), findsNothing);
      expect(find.byTooltip('次の一致'), findsNothing);
    });
  });

  group('SpoilerDialog 検索と物理キーボード操作テスト', () {
    testWidgets('Tab巡回、n/Nショートカット、Shift+Enterジャンプの検証', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 検索欄をタップして「キーワード」を入力
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'キーワード');
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Tab -> prevMatch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Enter で「前の一致」を実行 (1/3 -> 3/3)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);

      // Tab -> nextMatch
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Space で「次の一致」を実行 (3/3 -> 1/3)
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);

      // Tab -> peek -> toc -> close -> none
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 本文閲覧状態で n / N 操作
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('1/3'), findsOneWidget);
    });
  });
}
