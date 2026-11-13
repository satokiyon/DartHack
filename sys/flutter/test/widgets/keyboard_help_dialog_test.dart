import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';

void main() {
  Widget buildTestWidget({
    required KeyboardHelpContext helpContext,
    int menuHow = 0,
    Locale locale = const Locale('ja'),
    bool isJapanese = true,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                KeyboardHelpDialog.show(
                  ctx,
                  helpContext: helpContext,
                  menuHow: menuHow,
                  isJapanese: isJapanese,
                );
              },
              child: const Text('Open Help'),
            ),
          ),
        ),
      ),
    );
  }

  group('KeyboardHelpDialog Tests', () {
    testWidgets('menuHow == 0 (閲覧専用メニュー) では数量指定の項目が表示されないこと', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 0,
      ));

      // ダイアログを開く
      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定関連のテキストが存在しないことを確認
      expect(find.textContaining('0〜9'), findsNothing);
      expect(find.textContaining('数量指定'), findsNothing);

      // 基本的なメニュー操作は表示されていること
      expect(find.textContaining('Space'), findsWidgets);
      expect(find.textContaining('Esc'), findsWidgets);
    });

    testWidgets('menuHow == 1 (単一選択メニュー) では数量指定の項目が表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 1,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定関連のテキストが表示されていること
      expect(find.textContaining('0 〜 9'), findsOneWidget);
      expect(find.textContaining('BackSpace'), findsOneWidget);
      expect(find.textContaining('数量'), findsWidgets);
    });

    testWidgets('menuHow == 2 (複数選択メニュー) では一括操作と数量指定が表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.menu,
        menuHow: 2,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 数量指定および一括選択が表示されていること
      expect(find.textContaining('0 〜 9'), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('@'), findsOneWidget);
      expect(find.textContaining('menu_select_all'), findsOneWidget);
      expect(find.textContaining('menu_deselect_all'), findsOneWidget);
      expect(find.textContaining('menu_invert_all'), findsOneWidget);
    });

    testWidgets('F1 キー押下でダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // F1 キーを送信
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('Alt + h キー押下でダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // Alt + h キーを送信
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('game コンテキストでDartHackのUI操作およびNetHack標準ヘルプ導線が表示され、NetHack本来の移動操作等は表示されないこと', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('F9 / Alt-z'), findsOneWidget);
      expect(find.textContaining('階層の全体地図を表示'), findsOneWidget);
      expect(find.textContaining('Ctrl+M / F10'), findsOneWidget);
      expect(find.textContaining('Tab / Shift+Tab'), findsOneWidget);
      expect(find.textContaining('選択中の半透明ボタンを実行'), findsOneWidget);
      expect(find.textContaining('NetHack標準のヘルプ・コマンド一覧を表示'), findsOneWidget);

      // NetHack 自体の操作（移動、履歴表示等）は表示されないこと
      expect(find.textContaining('8方向移動'), findsNothing);
      expect(find.textContaining('メッセージ履歴'), findsNothing);
    });

    testWidgets('titleScreen コンテキストでタイトル画面向け操作ヘルプが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.titleScreen,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('Enter'), findsWidgets);
      expect(find.textContaining('Tab'), findsWidgets);
      expect(find.textContaining('Esc'), findsWidgets);
      expect(find.textContaining('冒険を始める'), findsWidgets);
    });

    testWidgets('fullMap コンテキストで全体地図向け操作ヘルプが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.fullMap,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('6倍拡大 ⇔ 全体表示'), findsOneWidget);
      expect(find.textContaining('マップのパン（平行移動）'), findsOneWidget);
      expect(find.textContaining('全体マップを閉じる'), findsOneWidget);
      // 閉じるキー表記が Enter / Esc に簡潔化され、冗長な全キー列挙が表示されないこと
      expect(find.text('Enter / Esc'), findsOneWidget);
      expect(find.textContaining('Enter / Space / Esc / q / F9 / Alt-z'), findsNothing);
    });

    testWidgets('狭幅画面 (360x640) でも Table のキー列幅制限 (45%) により説明文が押し出されず正常にレンダリングされること', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.fullMap,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.text('Enter / Esc'), findsOneWidget);
      expect(find.text('全体マップを閉じる'), findsOneWidget);

      // 説明文の RenderBox 幅が極狭（50px未満）に押し出されず、十分な表示幅を確保できていること
      final descFinder = find.text('全体マップを閉じる');
      final descRenderBox = tester.renderObject<RenderBox>(descFinder);
      expect(descRenderBox.size.width, greaterThan(100.0));
    });

    testWidgets('settings コンテキストで設定画面向け操作ヘルプが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.settings,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('↓'), findsWidgets);
      expect(find.textContaining('↑'), findsWidgets);
      expect(find.textContaining('PgDn'), findsWidgets);
      expect(find.textContaining('Esc'), findsWidgets);
      expect(find.textContaining('スクロール'), findsWidgets);
    });

    testWidgets('scoreboard コンテキストでスコアボード向け操作ヘルプが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.scoreboard,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('Tab / Shift+Tab'), findsOneWidget);
      expect(find.textContaining('前後のスコアを選択'), findsOneWidget);
    });

    testWidgets('scoreDetail コンテキストでスコア詳細画面向け操作ヘルプが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.scoreDetail,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.textContaining('1画面分下スクロール'), findsWidgets);
    });

    testWidgets('Escape キー押下でダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.game,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // Escape キーを送信
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('閉じるアイコンボタンをタップするとダイアログが閉じること', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        helpContext: KeyboardHelpContext.yn,
      ));

      await tester.tap(find.text('Open Help'));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // 閉じるアイコン (Icons.close_rounded) をタップ
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });
  });
}

