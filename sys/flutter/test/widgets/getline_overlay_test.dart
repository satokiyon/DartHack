import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/ext_cmd_entry.dart';
import 'package:darthack/widgets/overlays/getline_overlay.dart';

void main() {
  Widget buildTestWidget({
    required GlobalKey<GetLineOverlayState> overlayKey,
    required String prompt,
    required TextEditingController controller,
    List<ExtCmdEntry> extCmdList = const [],
    required Function(String?) onSubmit,
    List<String> recentMessages = const [],
    VoidCallback? onShowHistory,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            GetLineOverlay(
              key: overlayKey,
              prompt: prompt,
              inputController: controller,
              extCmdList: extCmdList,
              onSubmit: onSubmit,
              onShowMsgHistory: onShowHistory ?? () {},
              bottomInset: 0,
              isCallOrNamePrompt: (p) => p.contains('何と呼びますか') || p.contains('注釈'),
              recentMessages: recentMessages,
            ),
          ],
        ),
      ),
    );
  }

  group('GetLineOverlay フォーカスレス物理キーボード入力とIME自動表示抑止テスト', () {
    testWidgets('願い・金庫番の誰何・#annotate 等で autofocus が false であり、フォーカスレス文字入力と Enter 決定が動作すること', (tester) async {
      final key = GlobalKey<GetLineOverlayState>();
      final controller = TextEditingController();
      String? submitted;

      await tester.pumpWidget(
        buildTestWidget(
          overlayKey: key,
          prompt: '何を願いますか？',
          controller: controller,
          onSubmit: (res) => submitted = res,
        ),
      );
      await tester.pumpAndSettle();

      // TextField の autofocus が false であること（IME自動起動の防止）
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isFalse);

      // フォーカスを当てずに物理キーボードから文字入力 (appendText / deleteChar / clearText / submit)
      key.currentState!.appendText('b');
      key.currentState!.appendText('l');
      key.currentState!.appendText('e');
      await tester.pump();
      expect(controller.text, equals('ble'));

      key.currentState!.deleteChar();
      await tester.pump();
      expect(controller.text, equals('bl'));

      key.currentState!.clearText();
      await tester.pump();
      expect(controller.text, isEmpty);

      for (final ch in 'Croesus'.split('')) {
        key.currentState!.appendText(ch);
      }
      await tester.pump();
      expect(controller.text, equals('Croesus'));

      key.currentState!.submit();
      await tester.pump();
      expect(submitted, equals('Croesus'));
    });

    testWidgets('拡張コマンド候補リストの上下移動・Tab補完・Enter決定がフォーカスレスで動作すること', (tester) async {
      final key = GlobalKey<GetLineOverlayState>();
      final controller = TextEditingController();
      String? submitted;
      final extCmds = const [
        ExtCmdEntry(command: '#adjust', description: '所持品のスロット文字を調整する'),
        ExtCmdEntry(command: '#annotate', description: '現在の階層にメモ（注釈）を残す'),
        ExtCmdEntry(command: '#chat', description: '隣接する相手と話す'),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          overlayKey: key,
          prompt: '拡張コマンド:',
          controller: controller,
          extCmdList: extCmds,
          onSubmit: (res) => submitted = res,
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態では未選択（ハイライトなし）であること
      expect(find.byWidgetPredicate((w) => w is Material && w.color == Colors.teal.withValues(alpha: 0.25)), findsNothing);

      // 'a' を入力 -> 絞り込み欄に 'a' が入り、#adjust と #annotate に絞り込まれ、未選択状態が維持されること
      key.currentState!.appendText('a');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'a'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Material && w.color == Colors.teal.withValues(alpha: 0.25)), findsNothing);

      // 下矢印で先頭候補 (#adjust) が選択され、さらにもう一度下矢印で2番目の候補 (#annotate) に移動
      key.currentState!.moveCandidate(1);
      await tester.pumpAndSettle();
      key.currentState!.moveCandidate(1);
      await tester.pumpAndSettle();
      key.currentState!.autocompleteCandidate();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'annotate'), findsOneWidget);
      expect(controller.text, equals('#annotate'));

      // Enter で決定
      key.currentState!.submit();
      await tester.pumpAndSettle();
      expect(submitted, equals('#annotate'));
    });

    testWidgets('階層テレポートやOコマンドのオプション変更（autopickupの例外設定など）でもフォーカスレス文字入力・記号入力・Enter決定が動作すること', (tester) async {
      final key = GlobalKey<GetLineOverlayState>();
      final controller = TextEditingController();
      String? submitted;

      // 1. 階層テレポート ("どの階へテレポートしますか?")
      await tester.pumpWidget(
        buildTestWidget(
          overlayKey: key,
          prompt: 'どの階へテレポートしますか?',
          controller: controller,
          onSubmit: (res) => submitted = res,
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isFalse);

      // '-5' をフォーカスレス入力して Enter で確定
      key.currentState!.appendText('-');
      key.currentState!.appendText('5');
      await tester.pump();
      expect(controller.text, equals('-5'));
      key.currentState!.submit();
      await tester.pump();
      expect(submitted, equals('-5'));

      // 2. "O" コマンドによる autopickup の例外設定 ("新しい自動拾いの例外パターンは?")
      controller.clear();
      submitted = null;
      await tester.pumpWidget(
        buildTestWidget(
          overlayKey: key,
          prompt: '新しい自動拾いの例外パターンは?',
          controller: controller,
          onSubmit: (res) => submitted = res,
        ),
      );
      await tester.pumpAndSettle();

      for (final ch in '<*scroll*'.split('')) {
        key.currentState!.appendText(ch);
      }
      await tester.pump();
      expect(controller.text, equals('<*scroll*'));
      key.currentState!.submit();
      await tester.pump();
      expect(submitted, equals('<*scroll*'));
    });

    testWidgets('TabキーおよびShift+Tabキーによるフォーカス循環ナビゲーションとEnter決定が正しく動作すること', (tester) async {
      final key = GlobalKey<GetLineOverlayState>();
      final controller = TextEditingController(text: 'test entry');
      String? submitted;
      bool historyCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          overlayKey: key,
          prompt: '何か身につけるものを願ってください:',
          controller: controller,
          onSubmit: (res) => submitted = res,
          recentMessages: ['前回のメッセージ1', '前回のメッセージ2'],
          onShowHistory: () => historyCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      final state = key.currentState!;

      // 1. 初期状態: フォーカスなし (none)
      expect(find.byType(TextField), findsOneWidget);

      // 2. Tab 1回目 -> input
      state.cycleFocus(true);
      await tester.pump();
      // TextField にフォーカスが当たる

      // 3. Tab 2回目 -> history
      state.cycleFocus(true);
      await tester.pump();
      // history ボタンフォーカス時に submit() すると onShowHistory が呼ばれる
      state.submit();
      expect(historyCalled, isTrue);

      // 4. Tab 3回目 -> cancel
      state.cycleFocus(true);
      await tester.pump();
      // cancel ボタンフォーカス時に submit() すると onSubmit(null) が呼ばれる
      state.submit();
      expect(submitted, isNull);

      // 5. Tab 4回目 -> confirm
      state.cycleFocus(true);
      await tester.pump();
      // confirm ボタンフォーカス時に submit() すると onSubmit('test entry') が呼ばれる
      state.submit();
      expect(submitted, equals('test entry'));

      // 6. Tab 5回目 -> none (初期状態に復帰)
      state.cycleFocus(true);
      await tester.pump();

      // 7. Shift+Tab (逆順) -> confirm に移動
      state.cycleFocus(false);
      await tester.pump();
      submitted = null;
      state.submit();
      expect(submitted, equals('test entry'));

      // 8. Shift+Tab -> cancel に移動
      state.cycleFocus(false);
      await tester.pump();
      submitted = 'will be cleared';
      state.submit();
      expect(submitted, isNull);
    });
  });
}
