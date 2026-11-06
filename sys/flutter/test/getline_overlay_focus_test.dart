import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/getline_overlay.dart';

void main() {
  Widget buildTestWidget({
    required TextEditingController controller,
    required ValueChanged<String?> onSubmit,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja'), Locale('en')],
      home: Scaffold(
        body: Stack(
          children: [
            GetLineOverlay(
              prompt: '名前をつけてください',
              inputController: controller,
              extCmdList: const [],
              bottomInset: 0.0,
              isCallOrNamePrompt: (p) => true,
              onSubmit: onSubmit,
              onShowMsgHistory: () {},
            ),
          ],
        ),
      ),
    );
  }

  group('GetLineOverlay 物理キーボードフォーカス保護テスト', () {
    testWidgets('Tabキーでinputにフォーカスが当たった際は本物のフォーカス(hasFocus=true)が当たり、次のTabで解除される', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(buildTestWidget(
        controller: controller,
        onSubmit: (_) {},
      ));
      await tester.pumpAndSettle();

      final state = tester.state<GetLineOverlayState>(find.byType(GetLineOverlay));
      expect(state.currentFocusTarget, GetLineFocusTarget.none);

      // 1回目の Tab: input へ移動 -> 日本語 IME のため本物のフォーカス(hasFocus=true)が当たる
      state.cycleFocus(true);
      await tester.pump();
      expect(state.currentFocusTarget, GetLineFocusTarget.input);

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // 2回目の Tab: cancel へ移動 -> TextField のフォーカスが解除され安全に遷移する
      state.cycleFocus(true);
      await tester.pump();
      expect(state.currentFocusTarget, GetLineFocusTarget.cancel);
      expect(textField.focusNode?.hasFocus, isFalse);

      // 3回目の Tab: confirm へ移動
      state.cycleFocus(true);
      await tester.pump();
      expect(state.currentFocusTarget, GetLineFocusTarget.confirm);
      expect(textField.focusNode?.hasFocus, isFalse);

      // 4回目の Tab: none へ戻る
      state.cycleFocus(true);
      await tester.pump();
      expect(state.currentFocusTarget, GetLineFocusTarget.none);
      expect(textField.focusNode?.hasFocus, isFalse);

      // 各ボタンが ExcludeFocus(excluding: true) 配下にあり、フォーカス探索から除外されていることを検証
      final cancelBtnFinder = find.byType(TextButton);
      expect(cancelBtnFinder, findsOneWidget);
      final cancelExcludeFinder = find.ancestor(of: cancelBtnFinder, matching: find.byType(ExcludeFocus));
      expect(cancelExcludeFinder, findsWidgets);
      expect(tester.widget<ExcludeFocus>(cancelExcludeFinder.first).excluding, isTrue);

      final elevatedBtnsFinder = find.byType(ElevatedButton);
      expect(elevatedBtnsFinder, findsNWidgets(2));
      for (final btnElement in elevatedBtnsFinder.evaluate()) {
        final btnFinder = find.byWidget(btnElement.widget);
        final excludeFinder = find.ancestor(of: btnFinder, matching: find.byType(ExcludeFocus));
        expect(excludeFinder, findsWidgets);
        expect(tester.widget<ExcludeFocus>(excludeFinder.first).excluding, isTrue);
      }
    });

    testWidgets('inputFocusNode にフォーカスがある状態で Tab 物理キーを押すと onKeyEvent で handled され cycleFocus が発動する', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(
        controller: controller,
        onSubmit: (_) {},
      ));
      await tester.pumpAndSettle();

      final state = tester.state<GetLineOverlayState>(find.byType(GetLineOverlay));
      state.cycleFocus(true); // input へフォーカス
      await tester.pump();
      expect(state.currentFocusTarget, GetLineFocusTarget.input);
      expect(state.inputFocusNode.hasFocus, isTrue);

      // FocusNode.onKeyEvent 経由で Tab キーイベントを送信
      const tabEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      final result = state.inputFocusNode.onKeyEvent!(state.inputFocusNode, tabEvent);
      expect(result, equals(KeyEventResult.handled));

      await tester.pump();
      // handled されると同時に次のターゲット (cancel) へ安全に遷移していることを検証
      expect(state.currentFocusTarget, GetLineFocusTarget.cancel);
      expect(state.inputFocusNode.hasFocus, isFalse);
    });
  });
}
