import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/text_overlay.dart';

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
}
