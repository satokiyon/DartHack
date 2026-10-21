import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  group('Menu Accelerator & Auto-assignment Tests', () {
    test('selectMenu assigns unique accelerators in PICK_ONE / PICK_ANY', () {
      final screen = NetHackScreen();
      const winId = 2;
      screen.startMenu(winId);

      // アイテムを複数追加（accelerator == 0）
      screen.addMenu(winId, 101, 0, 0, 0, '金の指輪', 0, 0, -1);
      screen.addMenu(winId, 102, 0, 0, 0, '銀の杖', 0, 0, -1);
      screen.addMenu(winId, 103, 0, 0, 0, 'ダイヤモンド', 0, 0, -1);

      screen.endMenu(winId, '何を拾いますか?');
      screen.selectMenu(winId, 2 /* PICK_ANY */);

      expect(screen.menuItems.length, equals(3));
      expect(String.fromCharCode(screen.menuItems[0].accelerator), equals('a'));
      expect(String.fromCharCode(screen.menuItems[1].accelerator), equals('b'));
      expect(String.fromCharCode(screen.menuItems[2].accelerator), equals('c'));
    });

    test('selectMenu skips existing accelerators to avoid collision', () {
      final screen = NetHackScreen();
      const winId = 2;
      screen.startMenu(winId);

      // 最初の項目に 'a' (97) が既に割り当てられている
      screen.addMenu(winId, 101, 97, 0, 0, '全種類の物', 0, 0, -1);
      // 次の項目は未割り当て (0)
      screen.addMenu(winId, 102, 0, 0, 0, '武器', 0, 0, -1);
      screen.addMenu(winId, 103, 0, 0, 0, '防具', 0, 0, -1);

      screen.endMenu(winId, 'どの種類の物を入れますか?');
      screen.selectMenu(winId, 2 /* PICK_ANY */);

      expect(screen.menuItems.length, equals(3));
      expect(String.fromCharCode(screen.menuItems[0].accelerator), equals('a'));
      // 'a' が既にあるため、次は 'b', 'c' が割り振られる
      expect(String.fromCharCode(screen.menuItems[1].accelerator), equals('b'));
      expect(String.fromCharCode(screen.menuItems[2].accelerator), equals('c'));
    });

    test('selectMenu does not assign accelerators in PICK_NONE (how == 0)', () {
      final screen = NetHackScreen();
      const winId = 2;
      screen.startMenu(winId);

      screen.addMenu(winId, 101, 0, 0, 0, '足元のアイテム', 0, 0, -1);
      screen.endMenu(winId, '足元にある物');
      screen.selectMenu(winId, 0 /* PICK_NONE */);

      expect(screen.menuItems.length, equals(1));
      // PICK_NONE では 0 のまま維持される
      expect(screen.menuItems[0].accelerator, equals(0));
    });

    testWidgets('MenuOverlay query_category linking and pure category filtering (Japanese)', (tester) async {
      final items = [
        MenuItemData(
          ident: 65, // 'A' (自動選択)
          accelerator: 65, // 'A'
          groupacc: 0,
          attr: 0,
          text: '該当するすべての物を自動選択',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: -2, // 'a' (全種類)
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: '全種類の物',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1, // 'b' (武器 - 純粋カテゴリ)
          accelerator: 98, // 'b'
          groupacc: 0,
          attr: 0,
          text: '武器',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 2, // 'c' (防具 - 純粋カテゴリ)
          accelerator: 99, // 'c'
          groupacc: 0,
          attr: 0,
          text: '防具',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 66, // 'B' (祝福 - メタ項目)
          accelerator: 66, // 'B'
          groupacc: 0,
          attr: 0,
          text: '祝福されている物',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      Map<int, int>? submittedCounts;
      final menuKey = GlobalKey<MenuOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
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
          home: Scaffold(
            body: Stack(
              children: [
                MenuOverlay(
                  key: menuKey,
                  menuPrompt: 'どの種類の物を取り出しますか?',
                  menuItems: items,
                  menuHow: 2 /* PICK_ANY */,
                  initialSelectedCounts: const {},
                  initialSearchQuery: '',
                  bottomInset: 0.0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                  onSingleSelect: (_) {},
                  onMultiSelect: (counts) {
                    submittedCounts = counts;
                  },
                  onItemLongPress: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. 'a' (全種類の物 ident: -2) を選択した場合
      menuKey.currentState?.toggleSelectionById(-2);
      await tester.pumpAndSettle();

      // 全種類(-2) と 純粋カテゴリ (武器: 1, 防具: 2) にのみチェックが入る
      expect(menuKey.currentState?.selectedCounts.containsKey(-2), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(1), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(2), isTrue);
      // メタ項目 (A: 65, B: 66) にはチェックが入らないこと！
      expect(menuKey.currentState?.selectedCounts.containsKey(65), isFalse);
      expect(menuKey.currentState?.selectedCounts.containsKey(66), isFalse);

      // 2. 'a' を解除した場合
      menuKey.currentState?.toggleSelectionById(-2);
      await tester.pumpAndSettle();

      expect(menuKey.currentState?.selectedCounts.containsKey(-2), isFalse);
      expect(menuKey.currentState?.selectedCounts.containsKey(1), isFalse);
      expect(menuKey.currentState?.selectedCounts.containsKey(2), isFalse);

      // 3. 個別カテゴリ (武器: 1) のみを選択
      menuKey.currentState?.toggleSelectionById(1);
      await tester.pumpAndSettle();

      expect(menuKey.currentState?.selectedCounts.containsKey(1), isTrue);
      // 'a' (-2) はまだ選択されない
      expect(menuKey.currentState?.selectedCounts.containsKey(-2), isFalse);

      // 4. 残りのカテゴリ (防具: 2) も選択
      menuKey.currentState?.toggleSelectionById(2);
      await tester.pumpAndSettle();

      // すべての純粋カテゴリが揃ったため、'a' (-2) も自動選択される
      expect(menuKey.currentState?.selectedCounts.containsKey(1), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(2), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(-2), isTrue);

      // 5. submit() の検証
      menuKey.currentState?.submit();
      await tester.pumpAndSettle();

      expect(submittedCounts, isNotNull);
      expect(submittedCounts!.containsKey(1), isTrue);
      expect(submittedCounts!.containsKey(2), isTrue);
      expect(submittedCounts!.containsKey(-2), isTrue);
      expect(submittedCounts!.containsKey(65), isFalse);
    });

    testWidgets('MenuOverlay query_category pure category filtering (English)', (tester) async {
      final items = [
        MenuItemData(
          ident: 65, // 'A' (Auto-select)
          accelerator: 65, // 'A'
          groupacc: 0,
          attr: 0,
          text: 'Auto-select every relevant item',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: -2, // 'a' (All types)
          accelerator: 97, // 'a'
          groupacc: 0,
          attr: 0,
          text: 'All types',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 1, // 'b' (Weapons)
          accelerator: 98, // 'b'
          groupacc: 0,
          attr: 0,
          text: 'Weapons',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 2, // 'c' (Armor)
          accelerator: 99, // 'c'
          groupacc: 0,
          attr: 0,
          text: 'Armor',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
        MenuItemData(
          ident: 85, // 'U' (Uncursed)
          accelerator: 85, // 'U'
          groupacc: 0,
          attr: 0,
          text: 'Items known to be Uncursed',
          preselected: 0,
          color: 0,
          tile: -1,
        ),
      ];

      Map<int, int>? submittedCounts;
      final menuKey = GlobalKey<MenuOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('ja', ''),
          ],
          home: Scaffold(
            body: Stack(
              children: [
                MenuOverlay(
                  key: menuKey,
                  menuPrompt: 'Take out what type of objects?',
                  menuItems: items,
                  menuHow: 2 /* PICK_ANY */,
                  initialSelectedCounts: const {},
                  initialSearchQuery: '',
                  bottomInset: 0.0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                  onSingleSelect: (_) {},
                  onMultiSelect: (counts) {
                    submittedCounts = counts;
                  },
                  onItemLongPress: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 'a - All types' をタップ
      menuKey.currentState?.toggleSelectionById(-2);
      await tester.pumpAndSettle();

      // Weapons(1) と Armor(2) と All types(-2) のみ選択され、Auto-select(65) と Uncursed(85) は選択されない
      expect(menuKey.currentState?.selectedCounts.containsKey(-2), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(1), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(2), isTrue);
      expect(menuKey.currentState?.selectedCounts.containsKey(65), isFalse);
      expect(menuKey.currentState?.selectedCounts.containsKey(85), isFalse);

      // submit() の検証
      menuKey.currentState?.submit();
      await tester.pumpAndSettle();

      expect(submittedCounts, isNotNull);
      expect(submittedCounts!.containsKey(1), isTrue);
      expect(submittedCounts!.containsKey(2), isTrue);
      expect(submittedCounts!.containsKey(-2), isTrue);
      expect(submittedCounts!.containsKey(65), isFalse);
      expect(submittedCounts!.containsKey(85), isFalse);
    });
  });
}
