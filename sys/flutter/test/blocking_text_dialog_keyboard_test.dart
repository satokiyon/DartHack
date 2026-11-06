import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/input/hardware_key_router.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ブロッキングダイアログ（MenuOverlay）キーボードテスト', () {
    Widget buildMenuOverlay({
      required List<MenuItemData> items,
      required GlobalKey<MenuOverlayState> key,
      required Function(int ident) onSingleSelect,
      String menuPrompt = '遠見の操作説明',
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Stack(
            children: [
              MenuOverlay(
                key: key,
                menuPrompt: menuPrompt,
                menuItems: items,
                menuHow: 0, // PICK_NONE
                initialSelectedCounts: const {},
                initialSearchQuery: '',
                onSingleSelect: onSingleSelect,
                onMultiSelect: (_) {},
                onItemLongPress: (_) {},
                bottomInset: 0,
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

    testWidgets('アイテムが無くテキストのみのブロッキングメニューで、handleSpaceが最下部でonSingleSelect(-1)を呼ぶ', (tester) async {
      int? selectedIdent;
      final overlayKey = GlobalKey<MenuOverlayState>();

      await tester.pumpWidget(buildMenuOverlay(
        items: const [],
        key: overlayKey,
        onSingleSelect: (id) => selectedIdent = id,
      ));
      await tester.pumpAndSettle();

      // 最下部で handleSpace() を実行
      overlayKey.currentState?.handleSpace();
      await tester.pumpAndSettle();

      // 閉じる要求 (-1) が安全に送信されること
      expect(selectedIdent, equals(-1));
    });

    test('KeyInputContext.menu において Enter / Space / ESC のルーティングが正常に行われる', () {
      final enterDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      final submitAction = HardwareKeyRouter.route(
        event: enterDown,
        context: KeyInputContext.menu,
      );
      expect(submitAction, equals(const MenuSubmit()));

      final spaceDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );
      final spaceAction = HardwareKeyRouter.route(
        event: spaceDown,
        context: KeyInputContext.menu,
      );
      expect(spaceAction, equals(const MenuSpaceAction()));

      final escDown = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      final escAction = HardwareKeyRouter.route(
        event: escDown,
        context: KeyInputContext.menu,
      );
      expect(escAction, equals(const MenuCancel()));
    });
  });
}

