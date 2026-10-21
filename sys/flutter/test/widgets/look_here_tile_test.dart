import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/utils/dialog_header_helper.dart';
import 'package:darthack/widgets/overlays/text_overlay.dart';

void main() {
  group('Look Here & Container Contents Tile Tests', () {
    test('DialogHeaderHelper recognizes look here headers as title badges', () {
      expect(DialogHeaderHelper.isDialogTitleHeader('ここにあるもの:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('ここにある他のもの:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('手探りで分かったもの:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('手探りで分かった他のもの:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Things that are here:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Other things that are here:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('チェスト の中身:'), isTrue);
      expect(DialogHeaderHelper.isDialogTitleHeader('Contents of bag:'), isTrue);
    });

    test('NetHackScreen correctly stores textTiles when putMixedWithTile is sent to NHW_MENU', () {
      final screen = NetHackScreen();
      const winId = 10; // 動的 NHW_MENU ウィンドウID (1: WIN_MESSAGE, 2: WIN_STATUS, 3: WIN_MAP 以外の空きID)
      screen.createWindow(winId, NetHackScreen.nhwMenu);

      // 足元の物閲覧シナリオ: ヘッダー行(tile: -1) + アイテム行(tile: 120, 125)
      screen.putMixedWithTile(winId, 0, -1, 'ここにあるもの:');
      screen.putMixedWithTile(winId, 0, 120, '  短剣');
      screen.putMixedWithTile(winId, 0, 125, '  金の指輪');

      // メニューアイテムが追加されていない状態で displayWindow が呼ばれる
      screen.displayWindow(winId, true);

      // TextOverlay 用のプロパティが更新されていること
      expect(screen.isTextWindowVisible, isTrue);
      expect(screen.isMenuWindowVisible, isFalse);
      expect(screen.textLines.length, equals(3));
      expect(screen.textTiles.length, equals(3));
      expect(screen.textTiles[0], equals(-1));
      expect(screen.textTiles[1], equals(120));
      expect(screen.textTiles[2], equals(125));
    });

    testWidgets('TextOverlay renders title badge and item tile placeholders correctly', (tester) async {
      final textLines = [
        'ここにあるもの:',
        '  短剣',
        '  金の指輪',
      ];
      final textTiles = [-1, 120, 125];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TextOverlay(
                  textLines: textLines,
                  textAttrs: const [0, 0, 0],
                  textTiles: textTiles,
                  isPlainDialog: false,
                  plainType: 0,
                  tombstoneDisplayMode: 0,
                  onDismiss: () {},
                  onShowMsgHistory: () {},
                  bottomInset: 0.0,
                  useTiles: true,
                  tileImage: null, // テスト環境では画像なし
                  tileWidth: 32,
                  tileHeight: 32,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ヘッダーがピルバッジとしてレンダリングされていること
      expect(find.text('ここにあるもの:'), findsOneWidget);
      // アイテムテキストがレンダリングされていること
      expect(find.textContaining('短剣'), findsOneWidget);
      expect(find.textContaining('金の指輪'), findsOneWidget);
    });
  });
}
