import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/input/hardware_key_router.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/game_enums.dart';
import 'package:darthack/widgets/overlays/askname_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AskNameOverlay キーボードルーティングテスト', () {
    test('TextField 未フォーカス時の左右矢印で TextOverlayHorizontalMove が返される', () {
      final leftDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: leftDown,
        context: KeyInputContext.textInputOverlay,
        isTextFieldFocused: false,
      );
      expect(action, equals(const TextOverlayHorizontalMove(-1)));

      final rightDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );
      final rightAction = HardwareKeyRouter.route(
        event: rightDown,
        context: KeyInputContext.textInputOverlay,
        isTextFieldFocused: false,
      );
      expect(rightAction, equals(const TextOverlayHorizontalMove(1)));
    });

    test('TextField 未フォーカス時の Space で TextOverlayAppendChar(\' \') が返される（願い入力のスペース文字互換）', () {
      final spaceDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        character: ' ',
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: spaceDown,
        context: KeyInputContext.textInputOverlay,
        isTextFieldFocused: false,
      );
      expect(action, equals(const TextOverlayAppendChar(' ')));
    });

    test('TextField フォーカス時は IgnoreKey が返され、キャレット移動や文字入力が OS / TextField に委ねられる', () {
      final leftDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: leftDown,
        context: KeyInputContext.textInputOverlay,
        isTextFieldFocused: true,
      );
      expect(action, equals(const IgnoreKey()));
    });
  });

  group('AskNameOverlayState ウィジェットテスト', () {
    Widget buildAskNameOverlay({
      required TextEditingController controller,
      required List<String> saves,
      required GlobalKey<AskNameOverlayState> key,
      Function(PlayMode mode, String? name)? onSubmit,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Stack(
            children: [
              AskNameOverlay(
                key: key,
                nameController: controller,
                maxChars: 32,
                saves: saves,
                initialPlayMode: PlayMode.normal,
                onSubmit: onSubmit ?? (mode, name) {},
                bottomInset: 0,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('Tab キー巡回に saveList と playMode が含まれ、アンバー枠が表示される', (tester) async {
      final controller = TextEditingController(text: 'Hero');
      final overlayKey = GlobalKey<AskNameOverlayState>();

      await tester.pumpWidget(buildAskNameOverlay(
        controller: controller,
        saves: ['HeroSave1'],
        key: overlayKey,
      ));
      await tester.pumpAndSettle();

      // 1. Tab -> input
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(tester.state<AskNameOverlayState>(find.byType(AskNameOverlay)).currentFocusTarget,
          equals(AskNameFocusTarget.input));
      expect(overlayKey.currentState?.nameFocusNode.hasFocus, isTrue);

      // 2. Tab -> saveList (セーブデータが存在するため)
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(tester.state<AskNameOverlayState>(find.byType(AskNameOverlay)).currentFocusTarget,
          equals(AskNameFocusTarget.saveList));
      expect(overlayKey.currentState?.nameFocusNode.hasFocus, isFalse);

      // 3. Tab -> playMode
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(tester.state<AskNameOverlayState>(find.byType(AskNameOverlay)).currentFocusTarget,
          equals(AskNameFocusTarget.playMode));

      // 4. playMode フォーカス中に handleHorizontalMove(1) でモードが通常から探索へ切り替わる
      overlayKey.currentState?.handleHorizontalMove(1);
      await tester.pumpAndSettle();
      expect(controller.text, equals('Hero'));

      // 5. handleHorizontalMove(1) で探索からウィザードへ切り替わり、名前が "wizard" になる
      overlayKey.currentState?.handleHorizontalMove(1);
      await tester.pumpAndSettle();
      expect(controller.text, equals('wizard'));

      // 6. 再度 handleHorizontalMove(1) でウィザードから通常へ戻り、元の名前 "Hero" が復元される
      overlayKey.currentState?.handleHorizontalMove(1);
      await tester.pumpAndSettle();
      expect(controller.text, equals('Hero'));
    });
  });
}

