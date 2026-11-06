import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/new_level_rest_dialog.dart';

void main() {
  Widget buildTestApp({
    bool isJapanese = true,
    required void Function(bool? result) onClosed,
  }) {
    return MaterialApp(
      locale: isJapanese ? const Locale('ja') : const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              final res = await showDialog<bool>(
                context: ctx,
                builder: (dialogCtx) => NewLevelRestDialog(
                  isJapanese: isJapanese,
                ),
              );
              onClosed(res);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('NewLevelRestDialog Tests', () {
    testWidgets('初期状態で Space キーを押すと false (そのまま進む) でダイアログが閉じること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);
      expect(find.text('未知の階層に到達'), findsOneWidget);
      expect(find.text('そのまま進む'), findsOneWidget);

      // 初期状態で Space キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byType(NewLevelRestDialog), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('初期状態で Enter キーを押すと false (そのまま進む) でダイアログが閉じること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);

      // 初期状態で Enter キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(NewLevelRestDialog), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('初期状態で Escape キーを押すと false (そのまま進む) でダイアログが閉じること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);

      // 初期状態で Escape キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(NewLevelRestDialog), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('Tab キーで「広告を見て休む」にフォーカスが当たり、Enter で true が返ること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);

      // Tab キーを1回押すと「広告を見て休む」にフォーカス枠が点灯
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Enter キーを押下すると true（広告を見て休む）で閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(NewLevelRestDialog), findsNothing);
      expect(dialogResult, isTrue);
    });

    testWidgets('Tab キーを2回押すと「そのまま進む」にフォーカスが移動し、Enter で false が返ること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);

      // Tab を2回押す (none -> restWithAd -> proceed)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Enter キーを押下すると false（そのまま進む）で閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(NewLevelRestDialog), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('英語モードで Restore either HP or PW が正しく表示されること', (tester) async {
      bool? dialogResult;
      await tester.pumpWidget(
        buildTestApp(
          isJapanese: false,
          onClosed: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(NewLevelRestDialog), findsOneWidget);
      expect(find.text('Reached New Floor'), findsOneWidget);
      expect(find.text('Proceed as is'), findsOneWidget);

      // HP/PWどちらかの回復であることが明確な表現が表示されていること
      expect(find.textContaining('Restore either HP or PW'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(dialogResult, isFalse);
    });
  });
}
