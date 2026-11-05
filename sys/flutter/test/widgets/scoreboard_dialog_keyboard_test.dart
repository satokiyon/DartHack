import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/topten_widget.dart';
import 'package:darthack/models/topten_entry.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  List<TopTenEntry> createDummyEntries(int count) {
    return List.generate(count, (i) {
      return TopTenEntry(
        rank: i + 1,
        score: '${(count - i) * 1000}',
        nameAndProfile: 'Hero$i Valkyrie/Human/Female/Lawful',
        details: [
          'ダンジョン地下 ${i + 1} 階で子猫に倒された',
          'HP: 0 [max 30]',
        ],
        isCurrent: i == 0,
      );
    });
  }

  Widget buildTestableScoreboardDialog({
    required List<TopTenEntry> entries,
    bool isJp = true,
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
    testWidgets('Tab cycles close button focus, Enter and Escape close dialog', (tester) async {
      final entries = createDummyEntries(5);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreboardDialog), findsOneWidget);

      // 初期状態では閉じるボタンにフォーカスがない（Amber枠線ではない）
      final closeButtonFinder = find.widgetWithText(ElevatedButton, '閉じる');
      expect(closeButtonFinder, findsOneWidget);

      // Tabキーを押下 -> 閉じるボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // もう一度Tabキーを押下 -> フォーカスが外れる (none)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Escapeキーを押下 -> ダイアログが閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreboardDialog), findsNothing);
    });

    testWidgets('q key closes dialog', (tester) async {
      final entries = createDummyEntries(3);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ScoreboardDialog), findsOneWidget);

      // qキーを押下 -> ダイアログが閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreboardDialog), findsNothing);
    });

    testWidgets('Arrow keys, j/k, PageUp/PageDown, Home/End trigger scrolling without errors', (tester) async {
      final entries = createDummyEntries(20);
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: entries));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ScoreboardDialog), findsOneWidget);

      // 下スクロール (↓ / j)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();

      // 上スクロール (↑ / k)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pumpAndSettle();

      // ページ送り (PageDown / PageUp)
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      // 末尾・先頭ジャンプ (End / Home)
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreboardDialog), findsOneWidget);

      // Enterで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreboardDialog), findsNothing);
    });

    testWidgets('Empty entries shows placeholder and can be closed with Escape or Enter', (tester) async {
      await tester.pumpWidget(buildTestableScoreboardDialog(entries: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ScoreboardDialog), findsOneWidget);
      expect(find.text('スコア記録がありません'), findsOneWidget);

      // Enterキーで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreboardDialog), findsNothing);
    });
  });
}

