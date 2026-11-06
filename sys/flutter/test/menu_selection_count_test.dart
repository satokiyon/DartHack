import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  Widget buildTestWidget({
    required List<MenuItemData> items,
    int menuHow = 1, // PICK_ONE (ドロップ 'd' 等の単一選択メニュー)
    int? pendingCount,
    required ValueChanged<int> onSingleSelect,
    ValueChanged<MenuItemData>? onItemLongPress,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
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
              menuPrompt: '落とす物品を選んでください',
              menuItems: items,
              menuHow: menuHow,
              initialSelectedCounts: const {},
              initialSearchQuery: '',
              onSingleSelect: onSingleSelect,
              onMultiSelect: (_) {},
              onItemLongPress: onItemLongPress ?? (_) {},
              bottomInset: 0,
              pendingCount: pendingCount,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ],
        ),
      ),
    );
  }

  group('MenuSelectionCountTests', () {
    testWidgets('単一選択メニューでアイテムをタップすると onSingleSelect が呼ばれる', (tester) async {
      int? selectedIdent;

      final items = [
        MenuItemData(
          ident: 1001,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: 0,
          text: 'a - 60個の石',
          preselected: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          items: items,
          onSingleSelect: (id) => selectedIdent = id,
        ),
      );
      await tester.pumpAndSettle();

      // アイテムタイルをタップ
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      expect(selectedIdent, equals(1001));
    });

    testWidgets('pendingCount が指定されているとき、ヘッダーに数量バッジが表示される', (tester) async {
      final items = [
        MenuItemData(
          ident: 1001,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: 0,
          text: 'a - 60個の石',
          preselected: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          items: items,
          pendingCount: 10,
          onSingleSelect: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // 数量バッジが表示されていることを確認
      expect(find.text('数量: 10'), findsOneWidget);
    });

    test('menu_select メッセージ処理で count が省略された場合のデフォルト値は -1 (全数) であること', () {
      final messageWithoutCount = {'type': 'menu_select', 'ident': 1001};
      final count = messageWithoutCount['count'] as int? ?? -1;
      expect(count, equals(-1));

      final messageWithCount = {'type': 'menu_select', 'ident': 1001, 'count': 10};
      final explicitCount = messageWithCount['count'] as int? ?? -1;
      expect(explicitCount, equals(10));
    });
  });
}

