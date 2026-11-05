import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/guidebook_dialog.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    await AppPrefs.setMockInitialValues({'selected_language': 'ja'});
    GuidebookDialog.resetSavedScrollPosition();
    SpoilerDialog.resetSavedScrollPosition();
  });

  final sampleGuidebookMarkdown = List.generate(
    30,
    (i) => '## 第${i + 1}章 ガイドセクション $i {#sec-$i}\n\nガイド本文テキスト行 $i です。詳細説明テキスト。',
  ).join('\n\n');

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

  group('GuidebookDialog & SpoilerDialog Keyboard Navigation Tests', () {
    testWidgets('Guidebook: Tab cycles buttons, t opens TOC, Escape / q closes dialog', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          GuidebookDialog(
            initialContent: sampleGuidebookMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuidebookDialog), findsOneWidget);

      // Tabキーを押下 -> 目次ボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // もう一度Tabキーを押下 -> 閉じるボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // もう一度Tabキーを押下 -> noneに戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // tキーを押下 -> 目次モーダルが開く
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      expect(find.textContaining('目次 ('), findsOneWidget);

      // 目次モーダル内で Escape を押下 -> 目次が閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.textContaining('目次 ('), findsNothing);
      expect(find.byType(GuidebookDialog), findsOneWidget);

      // 本文で q キーを押下 -> ガイドブックが閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();

      expect(find.byType(GuidebookDialog), findsNothing);
    });

    testWidgets('Guidebook: Arrow keys and j/k scroll blocks, Home/End jump to ends', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          GuidebookDialog(
            initialContent: sampleGuidebookMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GuidebookDialog), findsOneWidget);

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

      expect(find.byType(GuidebookDialog), findsOneWidget);

      // Escapeで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookDialog), findsNothing);
    });

    testWidgets('SpoilerDialog: t opens TOC, Down/Up navigates items, Enter jumps, q closes', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleGuidebookMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpoilerDialog), findsOneWidget);

      // tキーで目次を開く
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      expect(find.textContaining('目次 ('), findsOneWidget);

      // ↓ キーで最初の項目を選択
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Enter キーで選択項目へジャンプして目次を閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.textContaining('目次 ('), findsNothing);
      expect(find.byType(SpoilerDialog), findsOneWidget);

      // qキーでスポイラーを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();

      expect(find.byType(SpoilerDialog), findsNothing);
    });
  });
}

