import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/input/hardware_key_router.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';
import 'package:darthack/widgets/overlays/any_key_overlay.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Stack(
          children: [
            child,
          ],
        ),
      ),
    );
  }

  group('HardwareKeyRouter anyKeyOverlay tests', () {
    test('Escape returns SendKey(27, ESC)', () {
      final action = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.escape,
          logicalKey: LogicalKeyboardKey.escape,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
      );
      expect(action, const SendKey(27, 'ESC'));
    });

    test('Tab and Shift+Tab return AnyKeyTab with correct forward flag', () {
      final tabAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isShiftPressed: false,
      );
      expect(tabAction, const AnyKeyTab(forward: true));

      final shiftTabAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.tab,
          logicalKey: LogicalKeyboardKey.tab,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isShiftPressed: true,
      );
      expect(shiftTabAction, const AnyKeyTab(forward: false));
    });

    test('Unfocused Enter/Space sends keycode for command lookup', () {
      final enterAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isAnyKeyButtonFocused: false,
      );
      expect(enterAction, isA<SendKey>());
      expect((enterAction as SendKey).code, 10);

      final spaceAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.space,
          logicalKey: LogicalKeyboardKey.space,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isAnyKeyButtonFocused: false,
      );
      expect(spaceAction, isA<SendKey>());
      expect((spaceAction as SendKey).code, 32);
    });

    test('Focused Enter/Space returns AnyKeySubmit', () {
      final enterAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: LogicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isAnyKeyButtonFocused: true,
      );
      expect(enterAction, const AnyKeySubmit());

      final spaceAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.space,
          logicalKey: LogicalKeyboardKey.space,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isAnyKeyButtonFocused: true,
      );
      expect(spaceAction, const AnyKeySubmit());
    });

    test('F1 and Alt+h return ShowKeyboardHelp', () {
      final f1Action = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.f1,
          logicalKey: LogicalKeyboardKey.f1,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
      );
      expect(f1Action, const ShowKeyboardHelp());

      final altHAction = HardwareKeyRouter.route(
        event: const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyH,
          logicalKey: LogicalKeyboardKey.keyH,
          timeStamp: Duration.zero,
        ),
        context: KeyInputContext.anyKeyOverlay,
        isAltPressed: true,
      );
      expect(altHAction, const ShowKeyboardHelp());
    });
  });

  group('AnyKeyOverlay widget & keyboard focus tests', () {
    testWidgets('Tab循環で閉じる・履歴ボタンにアンバー枠が点灯し決定実行できる', (tester) async {
      final key = GlobalKey<AnyKeyOverlayState>();
      int? selectedCode;
      bool closed = false;
      bool historyOpened = false;

      await tester.pumpWidget(
        buildTestApp(
          AnyKeyOverlay(
            key: key,
            question: 'どのコマンド?',
            defaultChoice: 0,
            onSelect: (code) => selectedCode = code,
            onClose: () => closed = true,
            onShowMsgHistory: () => historyOpened = true,
            bottomInset: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: none
      expect(key.currentState?.focusTarget, AnyKeyFocusTarget.none);

      // cycleFocus(true) -> close
      key.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(key.currentState?.focusTarget, AnyKeyFocusTarget.close);

      // 閉じるボタンの決定実行
      key.currentState?.submitFocused();
      expect(closed, isTrue);

      // cycleFocus(true) -> history
      key.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(key.currentState?.focusTarget, AnyKeyFocusTarget.history);

      // 履歴ボタンの決定実行
      key.currentState?.submitFocused();
      expect(historyOpened, isTrue);

      // cycleFocus(true) -> none に戻る
      key.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(key.currentState?.focusTarget, AnyKeyFocusTarget.none);

      // 物理キーコードの直接送信 (例: 'd' = 100)
      key.currentState?.handlePhysicalKeyCode(100);
      expect(selectedCode, 100);
    });

    testWidgets('KeyboardHelpDialog で anyKey ヘルプが正常にレンダリングされる', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const KeyboardHelpDialog(
            helpContext: KeyboardHelpContext.anyKey,
            isJapanese: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('キーボード操作ガイド'), findsOneWidget);
      expect(find.text('調べたいキーを押してコマンドの働きを説明'), findsOneWidget);
      expect(find.text('none ↔「閉じる」↔「履歴」ボタンのフォーカス循環'), findsOneWidget);
      expect(find.text('フォーカス中のボタンを実行（閉じる / 履歴）'), findsOneWidget);
    });
  });
}
