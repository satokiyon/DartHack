import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/game_drawer.dart';

void main() {
  Widget buildTestableDrawer({
    required bool isKeyboardVisible,
    required VoidCallback onToggleKeyboard,
    Locale locale = const Locale('ja'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        drawer: Drawer(
          child: GameDrawerContent(
            isGameRunning: true,
            isKeyboardVisible: isKeyboardVisible,
            onClose: () {},
            onSaveAndExit: () {},
            onQuit: () {},
            onShowScoreboard: () {},
            onShowGuidebook: () {},
            onShowSpoilers: () {},
            onShowHelp: () {},
            onDatabaseSearch: () {},
            onOpenOptions: () {},
            onShowFullMap: () {},
            onToggleKeyboard: onToggleKeyboard,
            onShowSettings: () {},
          ),
        ),
        body: const Center(child: Text('Game Screen')),
      ),
    );
  }

  group('GameDrawer Keyboard Toggle Tests', () {
    testWidgets('操作ボタンが表示中のとき、「操作ボタンを非表示」と videogame_asset_off アイコンが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool toggleCalled = false;

      await tester.pumpWidget(
        buildTestableDrawer(
          isKeyboardVisible: true,
          onToggleKeyboard: () {
            toggleCalled = true;
          },
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('操作ボタンを非表示'), findsOneWidget);
      expect(find.byIcon(Icons.videogame_asset_off), findsOneWidget);

      await tester.tap(find.text('操作ボタンを非表示'));
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('操作ボタンが非表示のとき、「操作ボタンを表示」と videogame_asset アイコンが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool toggleCalled = false;

      await tester.pumpWidget(
        buildTestableDrawer(
          isKeyboardVisible: false,
          onToggleKeyboard: () {
            toggleCalled = true;
          },
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('操作ボタンを表示'), findsOneWidget);
      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);

      await tester.tap(find.text('操作ボタンを表示'));
      await tester.pump();

      expect(toggleCalled, isTrue);
    });

    testWidgets('英語ロケールでも Hide/Show Controls が正しく表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableDrawer(
          isKeyboardVisible: true,
          onToggleKeyboard: () {},
          locale: const Locale('en'),
        ),
      );

      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Hide Controls'), findsOneWidget);
      expect(find.byIcon(Icons.videogame_asset_off), findsOneWidget);
    });
  });
}
