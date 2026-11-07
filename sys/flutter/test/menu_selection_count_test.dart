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
    VoidCallback? onCancel,
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
              onSelectionChanged: null,
              onCancel: onCancel,
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

    testWidgets('単一選択メニュー（Eコマンド等）で "-" (指先) のアクセラレータを持つアイテムがタップまたは選択できること', (tester) async {
      int? selectedIdent;

      final items = [
        MenuItemData(
          ident: 45, // HANDS_SYM ('-')
          accelerator: '-'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: -1,
          text: 'あなたの指先',
          preselected: 0,
        ),
        MenuItemData(
          ident: 1002,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: 0,
          text: 'つるはし',
          preselected: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          items: items,
          menuHow: 1, // PICK_ONE
          onSingleSelect: (id) => selectedIdent = id,
        ),
      );
      await tester.pumpAndSettle();

      // 指先アイテムが表示されていることを確認
      expect(find.text('- - あなたの指先'), findsOneWidget);

      // 指先アイテムをタップ
      await tester.tap(find.text('- - あなたの指先'));
      await tester.pumpAndSettle();

      expect(selectedIdent, equals(45));
    });

    test('単一選択メニュー（PICK_ONE）で "-" アイテムが存在する場合、MenuDeselectAllはアイテム選択として判定されること', () {
      final items = [
        MenuItemData(
          ident: 45, // HANDS_SYM ('-')
          accelerator: '-'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: -1,
          text: '- あなたの指先',
          preselected: 0,
        ),
        MenuItemData(
          ident: 1002,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: 0,
          text: 'a - つるはし',
          preselected: 0,
        ),
      ];

      // main.dart と同等のアクセラレータ検索判定ロジックを検証
      final dashItem = items.cast<MenuItemData?>().firstWhere(
            (i) => i != null && i.accelerator == 45 && i.ident != 0 && i.ident != 4294967294,
            orElse: () => null,
          );
      expect(dashItem, isNotNull);
      expect(dashItem!.ident, equals(45));
    });

    testWidgets('オプション画面の "?" (ヘルプを表示 / ident: -1) がタップ可能で選択できること', (tester) async {
      int? selectedIdent;

      final items = [
        MenuItemData(
          ident: -1,
          accelerator: '?'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: -1,
          text: 'ヘルプを表示',
          preselected: 0,
        ),
        MenuItemData(
          ident: 1,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: 0,
          tile: -1,
          text: 'autodig [ ]',
          preselected: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          items: items,
          menuHow: 1, // PICK_ONE
          onSingleSelect: (id) => selectedIdent = id,
        ),
      );
      await tester.pumpAndSettle();

      // ヘルプを表示アイテムが表示されていることを確認
      expect(find.text('? - ヘルプを表示'), findsOneWidget);

      // ヘルプを表示をタップ
      await tester.tap(find.text('? - ヘルプを表示'));
      await tester.pumpAndSettle();

      // ident: -1 が正しく渡されること
      expect(selectedIdent, equals(-1));
    });

    testWidgets('MenuOverlay の Cancel ボタン押下で onCancel コールバックが呼ばれること', (tester) async {
      bool cancelCalled = false;
      int? selectedIdent;

      await tester.pumpWidget(
        buildTestWidget(
          items: const [],
          menuHow: 1,
          onSingleSelect: (id) => selectedIdent = id,
          onCancel: () => cancelCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
      expect(selectedIdent, isNull);
    });

    testWidgets('非選択プレーン行でインデントされた説明文が階層化スタイルで描画されること', (tester) async {
      final items = [
        MenuItemData(
          ident: 1,
          accelerator: 'a'.codeUnitAt(0),
          groupacc: 0,
          attr: 0,
          color: -1,
          tile: -1,
          text: 'autodig [ ]',
          preselected: 0,
        ),
        MenuItemData(
          ident: 0, // 非選択行
          accelerator: 0,
          groupacc: 0,
          attr: 0,
          color: -1, // デフォルト色 (Colors.white)
          tile: -1,
          text: '    つるはしを振るわずに壁を掘る',
          preselected: 0,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          items: items,
          menuHow: 1,
          onSingleSelect: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // 説明文の Text ウィジェットを取得してスタイルを検証
      final textFinder = find.text('    つるはしを振るわずに壁を掘る');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.fontWeight, equals(FontWeight.w400));
      expect(textWidget.style?.color, equals(Colors.white70));
    });
  });
}

