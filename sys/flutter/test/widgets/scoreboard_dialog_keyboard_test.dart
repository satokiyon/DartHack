import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/topten_widget.dart';
import 'package:darthack/widgets/score_detail_dialog.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';
import 'package:darthack/models/topten_entry.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<TopTenEntry> createDummyEntries(int count, {int? currentIndex}) {
    return List.generate(count, (i) {
      return TopTenEntry(
        rank: i + 1,
        score: '${(count - i) * 1000}',
        nameAndProfile: 'Hero$i Valkyrie/Human/Female/Lawful',
        details: [
          'ダンジョン地下 ${i + 1} 階で子猫に倒された',
          'HP: 0 [max 30]',
        ],
        isCurrent: currentIndex != null && i == currentIndex,
      );
    });
  }

  Widget buildTestableScoreboardDialog({
    required List<TopTenEntry> entries,
    bool isJp = true,
    bool usePhysicalKeyboardNotation = false,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(isJp ? 'ja' : 'en'),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ScoreboardDialog(
                      entries: entries,
                      isJp: isJp,
                      usePhysicalKeyboardNotation: usePhysicalKeyboardNotation,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('ScoreboardDialog Keyboard Navigation Tests', () {
    testWidgets('初期フォーカスは先頭カード（isCurrent 指定時はそのカード）に設定されること', (tester) async {
      final entries = createDummyEntries(5, currentIndex: 2);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final topTenFinder = find.byType(TopTenWidget);
      expect(topTenFinder, findsOneWidget);
      final topTenState = tester.state<TopTenWidgetState>(topTenFinder);
      expect(topTenState.focusedIndex, equals(2));
      expect(topTenState.isKeyboardMode, isTrue);
    });

    testWidgets('usePhysicalKeyboardNotation に応じて閉じるボタンの表記が切り替わること', (tester) async {
      // OFF時 (日本語)
      final entries = createDummyEntries(3);
      await tester.pumpWidget(buildTestableScoreboardDialog(
        entries: entries,
        isJp: true,
        usePhysicalKeyboardNotation: false,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, '閉じる'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // ON時 (日本語)
      await tester.pumpWidget(buildTestableScoreboardDialog(
        entries: entries,
        isJp: true,
        usePhysicalKeyboardNotation: true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Esc:閉じる'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // ON時 (英語)
      await tester.pumpWidget(buildTestableScoreboardDialog(
        entries: entries,
        isJp: false,
        usePhysicalKeyboardNotation: true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ElevatedButton, 'Esc: Close'), findsOneWidget);
    });

    testWidgets('Tab / Shift+Tab でカード一覧と閉じるボタン間を循環すること', (tester) async {
      final entries = createDummyEntries(3);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final topTenState = tester.state<TopTenWidgetState>(find.byType(TopTenWidget));
      expect(topTenState.focusedIndex, equals(0));

      // Tab -> カード 1
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(1));

      // Tab -> カード 2 (末尾)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(2));

      // Tab -> リスト末尾を超えて閉じるボタンへ
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(-1));

      // Tab -> 閉じるボタンからカード先頭 (0) へ循環
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(0));

      // Shift+Tab -> 逆順で閉じるボタンへ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(-1));

      // Shift+Tab -> リスト末尾 (2) へ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(2));
    });

    testWidgets('↑ / ↓ / j / k で 1件移動、Space / Shift+Space で 5件移動、< / > で 10件移動すること', (tester) async {
      final entries = createDummyEntries(25);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final topTenState = tester.state<TopTenWidgetState>(find.byType(TopTenWidget));
      expect(topTenState.focusedIndex, equals(0));

      // ↓ キーで 1件次へ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(1));

      // j キーで 1件次へ
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(2));

      // ↑ キーで 1件前へ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(1));

      // k キーで 1件前へ
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(0));

      // Space で 5件次へ
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(5));

      // Shift+Space で 5件前へ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(0));

      // > (Period with Shift) で 10件次へ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(10));

      // < (Comma with Shift) で 10件前へ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(0));

      // End で末尾へ
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(24));

      // Home で先頭へ
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(topTenState.focusedIndex, equals(0));
    });

    testWidgets('Enter または → でカードを選択すると詳細情報ダイアログが表示されること', (tester) async {
      final entries = createDummyEntries(5);
      await tester.pumpWidget(buildTestableScoreboardDialog(
        entries: entries,
        usePhysicalKeyboardNotation: true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // カード0が選択された状態で Enter
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // ScoreDetailDialog が開くこと
      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      // 詳細ダイアログの閉じるボタンにも Esc:閉じる が反映されていること
      expect(
        find.descendant(
          of: find.byType(ScoreDetailDialog),
          matching: find.widgetWithText(ElevatedButton, 'Esc:閉じる'),
        ),
        findsOneWidget,
      );

      // Escape で詳細ダイアログを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsNothing);
      expect(find.byType(ScoreboardDialog), findsOneWidget);

      // → (arrowRight) でも詳細情報ダイアログが開くこと
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);

      // q キーで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsNothing);
    });

    testWidgets('F1 キー押下でスコアボード用 KeyboardHelpDialog が表示されること', (tester) async {
      final entries = createDummyEntries(3);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // F1 キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('Tab / Shift+Tab'), findsOneWidget);
      expect(find.textContaining('Enter / →'), findsOneWidget);

      // F1 または Escape でヘルプを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
      expect(find.byType(ScoreboardDialog), findsOneWidget);
    });

    testWidgets('詳細ダイアログ表示中に F1 を押すと詳細画面用ヘルプが表示されること', (tester) async {
      final entries = createDummyEntries(3);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter で詳細を開く
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreDetailDialog), findsOneWidget);

      // F1 キーでヘルプを開く
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('詳細画面を閉じる'), findsWidgets);

      // Escape でヘルプを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
      expect(find.byType(ScoreDetailDialog), findsOneWidget);
    });
  });
}
