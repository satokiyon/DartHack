import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  group('Menu Tab Row & Horizontal Scroll Tests', () {
    Widget buildTestWidget({
      required List<MenuItemData> items,
      required String prompt,
      double screenWidth = 360.0,
      double screenHeight = 740.0,
    }) {
      return MaterialApp(
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

    testWidgets('5-column spell menu sets min width to 600px and displays all spell fields', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          glyph: 0,
          ident: 0,
          accelerator: 0,
          groupAccel: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶',
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          glyph: 0,
          ident: 1,
          accelerator: 97, // 'a'
          groupAccel: 0,
          attr: 0,
          text: 'テレポート\t1\t脱出\t 0%\t100%',
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          glyph: 0,
          ident: 2,
          accelerator: 98, // 'b'
          groupAccel: 0,
          attr: 0,
          text: 'モンスター探知\t1\t予言\t 0%\t76%-100%',
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          glyph: 0,
          ident: 3,
          accelerator: 99, // 'c'
          groupAccel: 0,
          attr: 0,
          text: '致命傷治癒\t2\t治癒\t 5%\t(消失)',
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(items: items, prompt: '唱える呪文を選んでください'));
      await tester.pumpAndSettle();

      // 横スクロール用の Scrollbar と SingleChildScrollView の存在を検証
      expect(find.byType(Scrollbar), findsOneWidget);
      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      // 横スクロール用コンテナの幅が 600px 以上確保されていることを確認
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(of: horizontalScroll, matching: find.byType(SizedBox)),
      );
      final hasWidth600 = sizedBoxes.any((box) => box.width != null && box.width! >= 600.0);
      expect(hasWidth600, isTrue);

      // 記憶のテキストが省略されず完全な文字列として Widget ツリーに存在することを確認
      expect(find.text('76%-100%'), findsOneWidget);
      expect(find.text('(消失)'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('予言'), findsOneWidget);
      expect(find.text('治癒'), findsOneWidget);
    });

    testWidgets('6-column wizard spell menu sets min width to 700px and displays turns column', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final items = [
        MenuItemData(
          glyph: 0,
          ident: 0,
          accelerator: 0,
          groupAccel: 0,
          attr: 1, // Heading
          text: '呪文名\tレベル\t系統\t失敗率\t記憶\tターン',
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          glyph: 0,
          ident: 1,
          accelerator: 97, // 'a'
          groupAccel: 0,
          attr: 0,
          text: '使い魔召喚\t3\t念術\t10%\t91%-100%\t20000',
          color: 0,
          tile: -1,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(items: items, prompt: '唱える呪文を選んでください'));
      await tester.pumpAndSettle();

      // 6カラム時は最小幅が 700px 以上確保されていることを確認
      final horizontalScroll = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScroll, findsOneWidget);

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(of: horizontalScroll, matching: find.byType(SizedBox)),
      );
      final hasWidth700 = sizedBoxes.any((box) => box.width != null && box.width! >= 700.0);
      expect(hasWidth700, isTrue);

      // ターンカラムのヘッダーおよび数値が描画されていることを確認
      expect(find.text('ターン'), findsOneWidget);
      expect(find.text('20000'), findsOneWidget);
      expect(find.text('91%-100%'), findsOneWidget);
    });
  });
}
