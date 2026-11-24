import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  group('Menu Tab Row & Dynamic Column Width Tests', () {
    Widget buildTestWidget({
      required List<MenuItemData> items,
      required String prompt,
      double screenWidth = 360.0,
      double screenHeight = 740.0,
      Locale locale = const Locale('ja', ''),
    }) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ja', ''),
          Locale('en', ''),
        ],
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(screenWidth, screenHeight),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                MenuOverlay(
                  menuPrompt: prompt,
                  menuItems: items,
                  menuHow: 1 /* PICK_ONE */,
                  initialSelectedCounts: const {},
                  initialSearchQuery: '',
                  bottomInset: 0.0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                  onSingleSelect: (_) {},
                  onMultiSelect: (_) {},
                  onItemLongPress: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// 指定テキストを描画する RenderParagraph が省略（オーバーフロー）していないことを検証
    void expectNotEllipsized(WidgetTester tester, String text) {
      final finder = find.text(text);
      expect(finder, findsOneWidget, reason: 'テキスト "$text" が見つかりません');
      final renderObj = tester.renderObject(finder);
      expect(renderObj, isA<RenderParagraph>());
      final paragraph = renderObj as RenderParagraph;
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'テキスト "$text" が省略表示（didExceedMaxLines == true）されています',
      );
    }

    testWidgets('広い画面（Windows版相当: 1280x720）の5列呪文メニューで横スクロールなし＆全項目省略なし', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          ident: 0,
          accelerator: 0,
          groupacc: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: '灯り\t1\t聖職\t 0%\t91%-100%',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 2,
          accelerator: 98, // 'b'
          groupacc: 0,
          attr: 0,
          text: 'モンスター探知\t1\t予言\t 0%\t76%-100%',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: '現在習得している呪文',
        screenWidth: 1280.0,
        screenHeight: 720.0,
      ));
      await tester.pumpAndSettle();

      // 画面幅に十分収まるため不要な横スクロールは表示されない
      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsNothing);

      // ヘッダーおよびデータ行の全項目が省略されず描画されていること
      expectNotEllipsized(tester, '呪文名');
      expectNotEllipsized(tester, 'レベル');
      expectNotEllipsized(tester, '系統');
      expectNotEllipsized(tester, '失敗率');
      expectNotEllipsized(tester, '記憶');
      expectNotEllipsized(tester, 'a - 灯り');
      expectNotEllipsized(tester, '91%-100%');
      expectNotEllipsized(tester, '76%-100%');
    });

    testWidgets('特大フォント（22pt）の5列・6列呪文メニューでも全項目が省略されないこと', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final origSize = FontManager.instance.menuFontSize;
      await FontManager.instance.setMenuFontSize(22.0);
      addTearDown(() async => FontManager.instance.setMenuFontSize(origSize));

      final items = [
        MenuItemData(
          ident: 0,
          accelerator: 0,
          groupacc: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶\tターン',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: '使い魔召喚\t3\t念術\t10%\t91%-100%\t20000',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: '現在習得している呪文',
        screenWidth: 1280.0,
        screenHeight: 720.0,
      ));
      await tester.pumpAndSettle();

      expectNotEllipsized(tester, 'レベル');
      expectNotEllipsized(tester, '系統');
      expectNotEllipsized(tester, '失敗率');
      expectNotEllipsized(tester, '記憶');
      expectNotEllipsized(tester, 'ターン');
      expectNotEllipsized(tester, '91%-100%');
      expectNotEllipsized(tester, '20000');
    });

    testWidgets('狭い画面（Android縦画面相当: 360x740）の5列呪文メニューで横スクロールが有効になり全項目省略なし', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          ident: 0,
          accelerator: 0,
          groupacc: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: 'テレポート\t1\t脱出\t 0%\t100%',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 2,
          accelerator: 98, // 'b'
          groupacc: 0,
          attr: 0,
          text: 'モンスター探知\t1\t予言\t 0%\t76%-100%',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 3,
          accelerator: 99, // 'c'
          groupacc: 0,
          attr: 0,
          text: '致命傷治癒\t2\t治癒\t 5%\t(消失)',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: '唱える呪文を選んでください',
        screenWidth: 360.0,
        screenHeight: 740.0,
      ));
      await tester.pumpAndSettle();

      // 実測合計幅が 360px を超えるため横スクロールが有効化される
      expect(find.byType(Scrollbar), findsOneWidget);
      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      // どの項目も省略表示されないこと
      expectNotEllipsized(tester, 'レベル');
      expectNotEllipsized(tester, '76%-100%');
      expectNotEllipsized(tester, '(消失)');
      expectNotEllipsized(tester, '100%');
      expectNotEllipsized(tester, '予言');
      expectNotEllipsized(tester, '治癒');
    });

    testWidgets('狭い画面（360x740）の6列ウィザード呪文メニューで横スクロールが有効になりターン列も省略なし', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          ident: 0,
          accelerator: 0,
          groupacc: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶\tターン',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: '使い魔召喚\t3\t念術\t10%\t91%-100%\t20000',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: '唱える呪文を選んでください',
        screenWidth: 360.0,
        screenHeight: 740.0,
      ));
      await tester.pumpAndSettle();

      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      expectNotEllipsized(tester, 'ターン');
      expectNotEllipsized(tester, '20000');
      expectNotEllipsized(tester, '91%-100%');
    });

    testWidgets('英語版の5列呪文メニューで長い系統名・Retention表記が省略されないこと', (tester) async {
      tester.view.physicalSize = const Size(1024, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          ident: 0,
          accelerator: 0,
          groupacc: 0,
          attr: 1,
          text: 'Name\tLevel\tCategory\tFail\tRetention',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 97,
          groupacc: 0,
          attr: 0,
          text: 'charm monster\t3\tenchantment\t12%\t(forgotten)',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: 'Currently known spells',
        screenWidth: 1024.0,
        screenHeight: 720.0,
        locale: const Locale('en', ''),
      ));
      await tester.pumpAndSettle();

      expectNotEllipsized(tester, 'Level');
      expectNotEllipsized(tester, 'Category');
      expectNotEllipsized(tester, 'Retention');
      expectNotEllipsized(tester, 'enchantment');
      expectNotEllipsized(tester, '(forgotten)');
    });

    testWidgets('2列タブ区切りメニュー（オプション・スキル等）でも長い右列項目が省略されないこと', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          ident: 1,
          accelerator: 97,
          groupacc: 0,
          attr: 0,
          text: 'long sword\t[Grand Master]',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 2,
          accelerator: 98,
          groupacc: 0,
          attr: 0,
          text: 'pickup_types\t[\$?!/=+"(]',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: items,
        prompt: 'Set what options?',
        screenWidth: 800.0,
        screenHeight: 600.0,
        locale: const Locale('en', ''),
      ));
      await tester.pumpAndSettle();

      expectNotEllipsized(tester, '[Grand Master]');
      expectNotEllipsized(tester, '[\$?!/=+"(]');
    });
  });
}
