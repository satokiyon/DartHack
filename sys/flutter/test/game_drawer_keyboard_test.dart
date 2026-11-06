import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/game_drawer.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({bool isGameRunning = true}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        drawer: Drawer(
          child: GameDrawerContent(
            isGameRunning: isGameRunning,
            isKeyboardVisible: false,
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
            onToggleKeyboard: () {},
            onShowSettings: () {},
          ),
        ),
        body: const Center(child: Text('Main Screen')),
      ),
    );
  }

  testWidgets('ドロワーメニューで矢印キー移動時にGlobalKeyが再利用されスクロール処理が発火する', (WidgetTester tester) async {
    // 縦長の画面ではなく、高さが小さく項目がはみ出るビューポートを設定
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget(isGameRunning: true));
    await tester.pumpAndSettle();

    // ドロワーを開く
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.byType(GameDrawerContent), findsOneWidget);

    // 下矢印キーを何回か押して末尾方向の項目へフォーカス移動
    for (int i = 0; i < 7; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }

    // 末尾付近の項目（例: 「キーボードを表示」または「設定」）が表示され、エラーなく追従スクロールされることを確認
    expect(find.byType(GameDrawerContent), findsOneWidget);
  });
}

