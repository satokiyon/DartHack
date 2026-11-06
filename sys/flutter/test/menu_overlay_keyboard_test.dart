import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  Widget buildTestWidget({
    required List<MenuItemData> items,
    int menuHow = 0, // PICK_NONE (所持品一覧 'i' 相当)
    required ValueChanged<int> onSingleSelect,
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
            MenuOverlay(
              menuPrompt: '所持品',
              menuItems: items,
              menuHow: menuHow,
              initialSelectedCounts: const {},
              initialSearchQuery: '',
              bottomInset: 0.0,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
              onSingleSelect: onSingleSelect,
              onMultiSelect: (_) {},
              onItemLongPress: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  group('MenuOverlay 物理キーボード操作・フォーカス保護テスト', () {
    testWidgets('Tabキーでキャンセルボタンにフォーカスが合い、アンバー枠が表示される', (tester) async {
      final testItems = List<MenuItemData>.generate(
        10,
        (i) => MenuItemData(
          ident: i + 1,
          accelerator: 'a'.codeUnitAt(0) + i,
          groupacc: 0,
          attr: 0,
          text: 'アイテム $i',
          preselected: 0,
          color: 7,
          tile: 0,
        ),
      );

      await tester.pumpWidget(buildTestWidget(
        items: testItems,
        menuHow: 0, // PICK_NONE
        onSingleSelect: (_) {},
      ));
      await tester.pumpAndSettle();

      final state = tester.state<MenuOverlayState>(find.byType(MenuOverlay));
      expect(state.currentFocusTarget, MenuFocusTarget.none);

      // Tab キーでフォーカス循環
      state.cycleFocus(true);
      await tester.pump();

      expect(state.currentFocusTarget, MenuFocusTarget.cancel);

      // キャンセルボタンにアンバー枠（Colors.amberAccent, 2.5px）が表示されていることを検証
      final cancelBtnFinder = find.byType(ElevatedButton);
      expect(cancelBtnFinder, findsOneWidget);
      final cancelBtn = tester.widget<ElevatedButton>(cancelBtnFinder);
      final borderSide = cancelBtn.style?.side?.resolve({});
      expect(borderSide?.color, Colors.amberAccent);
      expect(borderSide?.width, 2.5);

      // キャンセルボタンが ExcludeFocus(excluding: true) 配下にあり、フォーカス探索から除外されていることを検証
      final excludeFocusFinder = find.ancestor(of: cancelBtnFinder, matching: find.byType(ExcludeFocus));
      expect(excludeFocusFinder, findsWidgets);
      expect(tester.widget<ExcludeFocus>(excludeFocusFinder.first).excluding, isTrue);
    });

    testWidgets('handleSpace() で最下部到達時は onSingleSelect(-1) が呼ばれて閉じる', (tester) async {
      int? selectedId;
      final testItems = [
        MenuItemData(
          ident: 1,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          text: 'りんご',
          preselected: 0,
          color: 7,
          tile: 0,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: testItems,
        menuHow: 0,
        onSingleSelect: (id) => selectedId = id,
      ));
      await tester.pumpAndSettle();

      final state = tester.state<MenuOverlayState>(find.byType(MenuOverlay));
      state.handleSpace();
      await tester.pump();

      expect(selectedId, -1);
    });

    testWidgets('scrollHorizontal and jumpToHorizontalEdge scroll horizontal menu smoothly', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final tabItems = [
        MenuItemData(
          ident: 1,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          text: 'オプション設定項目A\t現在の値: 有効\t詳細な説明テキスト長い長い説明文その1\t追加フラグ: ON',
          preselected: 0,
          color: 7,
          tile: 0,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        items: tabItems,
        menuHow: 1,
        onSingleSelect: (_) {},
      ));
      await tester.pumpAndSettle();

      final state = tester.state<MenuOverlayState>(find.byType(MenuOverlay));
      final hController = state.horizontalScrollController;
      expect(hController.hasClients, isTrue);

      if (hController.position.maxScrollExtent > 0.0) {
        // scrollHorizontal(1) -> 右へスクロール
        state.scrollHorizontal(1);
        await tester.pumpAndSettle();
        expect(hController.offset, greaterThan(0.0));

        // jumpToHorizontalEdge(false) -> 最右端へジャンプ
        state.jumpToHorizontalEdge(false);
        await tester.pumpAndSettle();
        expect(hController.offset, equals(hController.position.maxScrollExtent));

        // jumpToHorizontalEdge(true) -> 最左端へジャンプ
        state.jumpToHorizontalEdge(true);
        await tester.pumpAndSettle();
        expect(hController.offset, equals(0.0));
      }
    });
  });
}
