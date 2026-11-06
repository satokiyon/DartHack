import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/ext_cmd_entry.dart';
import 'package:darthack/widgets/overlays/getline_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyExtCmds = [
    const ExtCmdEntry(command: '#adjust', description: 'インベントリ文字を調整する'),
    const ExtCmdEntry(command: '#chat', description: 'モンスターと会話する'),
    const ExtCmdEntry(command: '#overview', description: 'ダンジョンの構造を表示する'),
    const ExtCmdEntry(command: '#pray', description: '神に祈りを捧げる'),
  ];

  Widget buildTestWidget({
    required Function(String? result) onSubmit,
    required GlobalKey<GetLineOverlayState> key,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Stack(
          children: [
            GetLineOverlay(
              key: key,
              prompt: '#',
              inputController: TextEditingController(),
              extCmdList: dummyExtCmds,
              onSubmit: onSubmit,
              onShowMsgHistory: () {},
              bottomInset: 0,
              isCallOrNamePrompt: (_) => false,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('拡張コマンドで "over" 入力後に Tab を押すと #overview が補完され、Enter で先頭#なしの "overview" が送信される', (tester) async {
    String? submittedResult;
    final overlayKey = GlobalKey<GetLineOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onSubmit: (result) => submittedResult = result,
      key: overlayKey,
    ));
    await tester.pumpAndSettle();

    // フォーカスレス物理キーで 'o', 'v', 'e', 'r' を入力
    overlayKey.currentState?.appendText('o');
    overlayKey.currentState?.appendText('v');
    overlayKey.currentState?.appendText('e');
    overlayKey.currentState?.appendText('r');
    await tester.pumpAndSettle();

    // Tab キーを押して補完
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();

    // Enter キーで送信
    overlayKey.currentState?.submit();
    await tester.pumpAndSettle();

    // C コアには先頭の '#' を除いた 'overview' が送られること！
    expect(submittedResult, equals('overview'));
  });

  testWidgets('拡張コマンドで Tab を複数回押すと候補が順送り巡回する', (tester) async {
    String? submittedResult;
    final overlayKey = GlobalKey<GetLineOverlayState>();

    await tester.pumpWidget(buildTestWidget(
      onSubmit: (result) => submittedResult = result,
      key: overlayKey,
    ));
    await tester.pumpAndSettle();

    // 初期状態（全4件）で Tab 1回目 -> インデックス 0 (adjust)
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();

    overlayKey.currentState?.submit();
    expect(submittedResult, equals('adjust'));

    // Tab 2回目 -> インデックス 1 (chat)
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();

    overlayKey.currentState?.submit();
    expect(submittedResult, equals('chat'));

    // Tab 3回目 -> インデックス 2 (overview)
    overlayKey.currentState?.cycleFocus(true);
    await tester.pumpAndSettle();

    overlayKey.currentState?.submit();
    expect(submittedResult, equals('overview'));

    // Shift+Tab で逆送り -> インデックス 1 (chat)
    overlayKey.currentState?.cycleFocus(false);
    await tester.pumpAndSettle();

    overlayKey.currentState?.submit();
    expect(submittedResult, equals('chat'));
  });
}
