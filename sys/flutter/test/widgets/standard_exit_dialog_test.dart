import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/standard_exit_dialog.dart';

void main() {
  Widget buildTestApp({
    required String message,
    bool isJapanese = true,
    required VoidCallback onClosed,
  }) {
    return MaterialApp(
      locale: isJapanese ? const Locale('ja') : const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              await showDialog<void>(
                context: ctx,
                builder: (dialogCtx) => StandardExitDialog(
                  dialogMessage: message,
                  isJapanese: isJapanese,
                ),
              );
              onClosed();
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
  }

  group('StandardExitDialog Tests', () {
    testWidgets('初期状態で Space キーを押すとダイアログが閉じること', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        buildTestApp(
          message: 'セーブして終了しました。',
          onClosed: () => closed = true,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(StandardExitDialog), findsOneWidget);
      expect(find.text('ゲーム終了'), findsOneWidget);
      expect(find.text('セーブして終了しました。'), findsOneWidget);

      // 初期状態で Space を押下
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.byType(StandardExitDialog), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('初期状態で Enter キーを押すとダイアログが閉じること', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        buildTestApp(
          message: '死亡時メッセージ',
          onClosed: () => closed = true,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(StandardExitDialog), findsOneWidget);

      // 初期状態で Enter を押下
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(StandardExitDialog), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('初期状態で Escape キーを押すとダイアログが閉じること', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        buildTestApp(
          message: 'See you again...',
          isJapanese: false,
          onClosed: () => closed = true,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(StandardExitDialog), findsOneWidget);
      expect(find.text('Game Over'), findsOneWidget);

      // 初期状態で Escape を押下
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(StandardExitDialog), findsNothing);
      expect(closed, isTrue);
    });

    testWidgets('Tab キーで OK ボタンにフォーカス枠が当たり、Space/Enter で閉じられること', (tester) async {
      bool closed = false;
      await tester.pumpWidget(
        buildTestApp(
          message: '終了メッセージ',
          onClosed: () => closed = true,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(StandardExitDialog), findsOneWidget);

      // 初期状態では枠線なし
      final initialContainer = tester.widget<Container>(
        find.ancestor(of: find.text('OK'), matching: find.byType(Container)).first,
      );
      expect(initialContainer.decoration, isNull);

      // Tab キーを押すと OK ボタンにアンバー枠が点灯
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final focusedContainer = tester.widget<Container>(
        find.ancestor(of: find.text('OK'), matching: find.byType(Container)).first,
      );
      final decoration = focusedContainer.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);

      // フォーカス状態で Enter を押すと閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(StandardExitDialog), findsNothing);
      expect(closed, isTrue);
    });
  });
}
