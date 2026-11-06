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
    testWidgets('Guidebook: Tab cycles search, peek, toc, close and any key dismisses peek', (tester) async {
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

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);

      // 1回目の Tab -> 検索欄にフォーカスが当たる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final textField = tester.widget<TextField>(searchTextFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // 2回目の Tab -> 透過アイコン（peek）にフォーカス
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(textField.focusNode?.hasFocus, isFalse);

      // 透過アイコンで Enter を押下 -> 透過モード（opacity: 0.0）になる
      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );

      // 透過状態のときに任意のキー（例: 矢印キーやスペースキー）を押下 -> 透過解除して元の表示に戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // 3回目の Tab -> 目次ボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 4回目の Tab -> 閉じるボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 5回目の Tab -> none に戻る
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

    testWidgets('SpoilerDialog: Tab cycles search, peek, toc, close and any key dismisses peek', (tester) async {
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

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);

      // 1回目の Tab -> 検索欄にフォーカス
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final textField = tester.widget<TextField>(searchTextFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // 2回目の Tab -> 透過アイコン（peek）にフォーカス
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(textField.focusNode?.hasFocus, isFalse);

      // 透過アイコンで Enter を押下 -> 透過モード（opacity: 0.0）
      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );

      // 透過状態のときに任意のキー（Space 等）を押下 -> 透過解除して元の表示に戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // 3回目の Tab -> 目次ボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 4回目の Tab -> 閉じるボタンがフォーカス状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 5回目の Tab -> none に戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
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

    testWidgets('Guidebook: ArrowLeft/ArrowRight scrolls visible table horizontally, Shift jumps to edge', (tester) async {
      const tableMarkdown = '''
## テーブルテスト

| 列1 | 列2 | 列3 | 列4 | 列5 | 列6 | 列7 | 列8 | 列9 | 列10 |
|---|---|---|---|---|---|---|---|---|---|
| 非常に長いテキスト1 | 非常に長いテキスト2 | 非常に長いテキスト3 | 非常に長いテキスト4 | 非常に長いテキスト5 | 非常に長いテキスト6 | 非常に長いテキスト7 | 非常に長いテキスト8 | 非常に長いテキスト9 | 非常に長いテキスト10 |
''';

      await tester.pumpWidget(
        buildTestApp(
          const GuidebookDialog(
            initialContent: tableMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DataTable), findsOneWidget);

      // 右矢印キー押下 -> 右へ横スクロール
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Shift + 右矢印キー押下 -> 最右端へジャンプ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      // Shift + 左矢印キー押下 -> 最左端へジャンプ
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
    });
  });
}

