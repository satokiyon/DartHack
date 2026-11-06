import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/overlays/yn_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required Function(int choiceCode) onSelect,
    required VoidCallback onShowMsgHistory,
    required GlobalKey<YnOverlayState> key,
    String question = '能力値を表示しますか?',
    String choices = 'ynq',
    int defaultChoice = 110, // 'n'
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Stack(
          children: [
            YnOverlay(
              key: key,
              question: question,
              choices: choices,
              defaultChoice: defaultChoice,
              onSelect: onSelect,
              onShowMsgHistory: onShowMsgHistory,
              bottomInset: 0,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('YNプロンプトでTabキーで「y」にフォーカスを合わせてEnterを押すと、既定値nではなくyが送信される', (tester) async {
    int? selectedCode;
    final overlayKey = GlobalKey<YnOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onSelect: (code) => selectedCode = code,
      onShowMsgHistory: () {},
      key: overlayKey,
      defaultChoice: 'n'.codeUnitAt(0), // デフォルトは 'n'
    ));
    await tester.pumpAndSettle();

    // Tab キーを1回押して最初のボタン (choice:y) にフォーカス
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();

    expect(overlayKey.currentState?.currentFocusTarget, equals('choice:y'));

    // Enter キー (submit) を実行
    overlayKey.currentState?.submit();
    await tester.pumpAndSettle();

    // 既定値 'n' (110) ではなく、フォーカス中の 'y' (121) が送信されること！
    expect(selectedCode, equals('y'.codeUnitAt(0)));
  });

  testWidgets('YNプロンプトでTabキーで履歴ボタンにフォーカスを合わせてEnterを押すと、履歴パネルが開く', (tester) async {
    bool historyOpened = false;
    final overlayKey = GlobalKey<YnOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onSelect: (_) {},
      onShowMsgHistory: () => historyOpened = true,
      key: overlayKey,
    ));
    await tester.pumpAndSettle();

    // Tab を順次押して 'history' ボタンへフォーカス移動
    // 循環順: none -> choice:y -> choice:n -> choice:q -> cancel -> history
    for (int i = 0; i < 5; i++) {
      overlayKey.currentState?.cycleFocus(true);
      await tester.pumpAndSettle();
    }

    expect(overlayKey.currentState?.currentFocusTarget, equals('history'));

    // Enter キー (submit) を実行
    overlayKey.currentState?.submit();
    await tester.pumpAndSettle();

    expect(historyOpened, isTrue);
  });
}
