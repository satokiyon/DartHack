import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/input/hardware_key_router.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/screens/start_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('タイトル画面のキーボードルーティングテスト', () {
    test('Tab / Shift+Tab で TitleTab が返される', () {
      final tabDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      final tabAction = HardwareKeyRouter.route(
        event: tabDown,
        context: KeyInputContext.titleScreen,
      );
      expect(tabAction, equals(const TitleTab(forward: true)));

      final shiftTabAction = HardwareKeyRouter.route(
        event: tabDown,
        context: KeyInputContext.titleScreen,
        isShiftPressed: true,
      );
      expect(shiftTabAction, equals(const TitleTab(forward: false)));
    });

    test('Enter キーで TitleSubmit が返される', () {
      final enterDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: enterDown,
        context: KeyInputContext.titleScreen,
      );
      expect(action, equals(const TitleSubmit()));
    });

    test('Space キーで TitleSpaceAction が返される', () {
      final spaceDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: spaceDown,
        context: KeyInputContext.titleScreen,
      );
      expect(action, equals(const TitleSpaceAction()));
    });

    test('左右矢印キーで言語選択アクションが返される', () {
      final leftDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      );
      final leftAction = HardwareKeyRouter.route(
        event: leftDown,
        context: KeyInputContext.titleScreen,
      );
      expect(leftAction, equals(const TitleSelectLanguage('ja')));

      final rightDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      );
      final rightAction = HardwareKeyRouter.route(
        event: rightDown,
        context: KeyInputContext.titleScreen,
      );
      expect(rightAction, equals(const TitleSelectLanguage('en')));
    });

    test('Esc キーで TitleEscape が返される', () {
      final escDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      final action = HardwareKeyRouter.route(
        event: escDown,
        context: KeyInputContext.titleScreen,
      );
      expect(action, equals(const TitleEscape()));
    });
  });

  group('StartScreen ウィジェットのフォーカスハイライトテスト', () {
    Widget buildStartScreen({
      required TitleScreenFocusTarget focusTarget,
      String selectedLanguage = 'ja',
      bool assetsReady = true,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: StartScreen(
            assetsReady: assetsReady,
            selectedLanguage: selectedLanguage,
            onLanguageChanged: (_) {},
            onStartGame: () {},
            onShowSettings: () {},
            currentFocusTarget: focusTarget,
          ),
        ),
      );
    }

    testWidgets('startGame フォーカス時に開始ボタンにアンバー枠が表示される', (tester) async {
      await tester.pumpWidget(buildStartScreen(focusTarget: TitleScreenFocusTarget.startGame));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasAmberBorder = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration && dec.border != null) {
          final border = dec.border!;
          return border.top.color == Colors.amberAccent;
        }
        return false;
      });
      expect(hasAmberBorder, isTrue);
    });

    testWidgets('language フォーカス時に言語セレクタにアンバー枠が表示される', (tester) async {
      await tester.pumpWidget(buildStartScreen(focusTarget: TitleScreenFocusTarget.language));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasAmberBorder = containers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration && dec.border != null) {
          final border = dec.border!;
          return border.top.color == Colors.amberAccent;
        }
        return false;
      });
      expect(hasAmberBorder, isTrue);
    });
  });
}

