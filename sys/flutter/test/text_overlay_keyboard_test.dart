import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/text_overlay.dart';
import 'package:darthack/widgets/score_detail_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required VoidCallback onDismiss,
    required VoidCallback onShowMsgHistory,
    required GlobalKey<TextOverlayState> key,
    List<String> textLines = const ['行1: 倒した怪物', '行2: コボルド 3体', '行3: オーク 5体'],
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Stack(
          children: [
            TextOverlay(
              key: key,
              textLines: textLines,
              textAttrs: List.filled(textLines.length, 0),
              textTiles: List.filled(textLines.length, -1),
              isPlainDialog: false,
              plainType: 0,
              tombstoneDisplayMode: 0,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
              onDismiss: onDismiss,
              onShowMsgHistory: onShowMsgHistory,
              bottomInset: 0,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('TextOverlayでTabキーを押すとokとhistoryボタン間をフォーカス循環する', (tester) async {
    final overlayKey = GlobalKey<TextOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onDismiss: () {},
      onShowMsgHistory: () {},
      key: overlayKey,
    ));
    await tester.pumpAndSettle();

    expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.none));

    // Tab 1回目 -> ok
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();
    expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.ok));

    // Tab 2回目 -> history
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();
    expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.history));

    // Tab 3回目 -> none
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();
    expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.none));
  });

  testWidgets('TextOverlayでEnter(submit)を押すと即座に閉じる(onDismissが呼ばれる)', (tester) async {
    bool dismissed = false;
    final overlayKey = GlobalKey<TextOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onDismiss: () => dismissed = true,
      onShowMsgHistory: () {},
      key: overlayKey,
    ));
    await tester.pumpAndSettle();

    overlayKey.currentState?.submit();
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  testWidgets('TextOverlayでSpace(handleSpace)を押すと最下部到達時またはスクロール不要時に閉じる', (tester) async {
    bool dismissed = false;
    final overlayKey = GlobalKey<TextOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onDismiss: () => dismissed = true,
      onShowMsgHistory: () {},
      key: overlayKey,
      textLines: const ['短い行1', '短い行2'],
    ));
    await tester.pumpAndSettle();

    overlayKey.currentState?.handleSpace();
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  group('TextOverlay TopTen Scoreboard Mode Tests', () {
    const scoreLines = [
      ' 順位      点数  名前',
      '    1      5000  Player-Val-Hum-Fem-Law',
      '                 地下 3 階でコボルドに倒された',
      '    2      3000  Player2-Wiz-Elf-Mal-Cha',
      '                 地下 2 階でジャッカルに倒された',
    ];

    testWidgets('TopTen 表示時に Tab 循環でカード・OKボタン・履歴ボタン間を移動すること', (tester) async {
      final overlayKey = GlobalKey<TextOverlayState>();

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Stack(
            children: [
              TextOverlay(
                key: overlayKey,
                textLines: scoreLines,
                textAttrs: List.filled(scoreLines.length, 0),
                textTiles: List.filled(scoreLines.length, -1),
                isPlainDialog: false,
                plainType: 0,
                tombstoneDisplayMode: 0,
                useTiles: false,
                tileImage: null,
                tileWidth: 32,
                tileHeight: 32,
                onDismiss: () {},
                onShowMsgHistory: () {},
                bottomInset: 0,
                usePhysicalKeyboardNotation: true,
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(overlayKey.currentState?.isTopTen, isTrue);
      // usePhysicalKeyboardNotation が有効なため Enter:OK と表示されること
      expect(find.widgetWithText(ElevatedButton, 'Enter:OK'), findsOneWidget);

      // 初期状態ではカード 0 にフォーカス、ボタンターゲットは none
      expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.none));

      // Tab -> カード 1
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.none));

      // Tab -> リスト末尾を超えて OK ボタンへ
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.ok));

      // Tab -> 履歴ボタンへ
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.history));

      // Tab -> カード先頭 (none) へ循環
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
      expect(overlayKey.currentState?.currentFocusTarget, equals(TextOverlayFocusTarget.none));
    });

    testWidgets('TopTen 表示時にカード選択状態で submit すると詳細ダイアログが開くこと', (tester) async {
      final overlayKey = GlobalKey<TextOverlayState>();
      bool dismissed = false;

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Stack(
            children: [
              TextOverlay(
                key: overlayKey,
                textLines: scoreLines,
                textAttrs: List.filled(scoreLines.length, 0),
                textTiles: List.filled(scoreLines.length, -1),
                isPlainDialog: false,
                plainType: 0,
                tombstoneDisplayMode: 0,
                useTiles: false,
                tileImage: null,
                tileWidth: 32,
                tileHeight: 32,
                onDismiss: () => dismissed = true,
                onShowMsgHistory: () {},
                bottomInset: 0,
                usePhysicalKeyboardNotation: true,
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // カード0が選択された状態で submit()
      overlayKey.currentState?.submit();
      await tester.pumpAndSettle();

      // 詳細ダイアログが表示され、onDismiss は呼ばれていないこと
      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(dismissed, isFalse);
    });
  });
}
