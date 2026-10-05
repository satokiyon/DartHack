import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/game_enums.dart';
import 'package:darthack/widgets/overlays/askname_overlay.dart';
import 'package:darthack/widgets/overlays/save_data_list_view.dart';

void main() {
  Widget buildTestWidget({
    required List<String> saves,
    required TextEditingController controller,
    PlayMode initialPlayMode = PlayMode.normal,
    Function(PlayMode, String?)? onSubmit,
    double bottomInset = 0,
    ThemeData? theme,
  }) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: Stack(
          children: [
            AskNameOverlay(
              nameController: controller,
              maxChars: 32,
              saves: saves,
              initialPlayMode: initialPlayMode,
              onSubmit: onSubmit ?? (mode, name) {},
              bottomInset: bottomInset,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('4件以上のセーブデータが存在する場合にスクロールバーが表示され、スクロールして選択できること', (tester) async {
    final saves = ['Save_Hero_1', 'Save_Hero_2', 'Save_Hero_3', 'Save_Hero_4', 'Save_Hero_5'];
    final controller = TextEditingController(text: saves[0]);

    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    final scrollbarFinder = find.byType(Scrollbar);
    expect(scrollbarFinder, findsOneWidget);
    final scrollbarWidget = tester.widget<Scrollbar>(scrollbarFinder);
    expect(scrollbarWidget.thumbVisibility, isTrue);

    final listFinder = find.byType(ListView);
    expect(find.descendant(of: listFinder, matching: find.text('Save_Hero_1')), findsOneWidget);
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);

    final item5Finder = find.descendant(of: listFinder, matching: find.text('Save_Hero_5'));
    await tester.scrollUntilVisible(
      item5Finder,
      50,
      scrollable: find.descendant(of: scrollbarFinder, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();

    expect(item5Finder, findsOneWidget);

    await tester.tap(item5Finder);
    await tester.pumpAndSettle();

    expect(controller.text, equals('Save_Hero_5'));
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('上下矢印キーでセーブデータが順次選択され、リストが自動追従すること', (tester) async {
    final saves = ['Save_Hero_1', 'Save_Hero_2', 'Save_Hero_3', 'Save_Hero_4', 'Save_Hero_5'];
    final controller = TextEditingController(text: saves[0]);

    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byType(ListView);

    // 下矢印キーを1回押下 -> Save_Hero_2 が選択される
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Hero_2'));

    // 下矢印キーをさらに連続押下して末尾まで移動
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Hero_3'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Hero_4'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Hero_5'));

    // 5件目が画面内にスクロールされてチェックマークが表示されていること
    expect(find.descendant(of: listFinder, matching: find.text('Save_Hero_5')), findsOneWidget);
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);

    // 上矢印キーを押下 -> Save_Hero_4 に戻る
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Hero_4'));
  });

  testWidgets('3件以下のセーブデータの場合はスクロールバーの thumbVisibility が false であること', (tester) async {
    final saves = ['Save_Hero_1', 'Save_Hero_2', 'Save_Hero_3'];
    final controller = TextEditingController(text: saves[0]);

    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    final scrollbarFinder = find.byType(Scrollbar);
    expect(scrollbarFinder, findsOneWidget);
    final scrollbarWidget = tester.widget<Scrollbar>(scrollbarFinder);
    expect(scrollbarWidget.thumbVisibility, isFalse);
  });

  testWidgets('ウィザードモードに切り替えた場合でもセーブデータ選択状態が維持されること', (tester) async {
    final saves = ['Save_Alpha', 'Save_Beta'];
    final controller = TextEditingController(text: saves[1]);

    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byType(ListView);

    expect(controller.text, equals('Save_Beta'));
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);

    await tester.tap(find.text('ウィザード'));
    await tester.pumpAndSettle();

    expect(controller.text, equals('wizard'));
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);

    await tester.tap(find.text('通常'));
    await tester.pumpAndSettle();
    expect(controller.text, equals('Save_Beta'));
    expect(find.descendant(of: listFinder, matching: find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('テーマカラー（ColorScheme.primary）に連動して選択色・チェックマークが表示されること', (tester) async {
    const customPrimary = Color(0xFFE91E63); // ピンク
    final customTheme = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.dark(primary: customPrimary),
    );

    final saves = ['Hero_A', 'Hero_B'];
    final controller = TextEditingController(text: saves[0]);

    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
        theme: customTheme,
      ),
    );
    await tester.pumpAndSettle();

    final checkIconFinder = find.descendant(
      of: find.byType(ListView),
      matching: find.byIcon(Icons.check),
    );
    expect(checkIconFinder, findsOneWidget);
    final checkIcon = tester.widget<Icon>(checkIconFinder);
    expect(checkIcon.color, equals(customPrimary));
  });

  testWidgets('レスポンシブな高さクランプが適用されること', (tester) async {
    final saves = ['Save_1', 'Save_2', 'Save_3', 'Save_4'];
    final controller = TextEditingController(text: saves[0]);

    // 大きな bottomInset (キーボード展開時)
    await tester.pumpWidget(
      buildTestWidget(
        saves: saves,
        controller: controller,
        bottomInset: 350,
      ),
    );
    await tester.pumpAndSettle();

    final saveListViewFinder = find.byType(SaveDataListView);
    expect(saveListViewFinder, findsOneWidget);
    final saveListView = tester.widget<SaveDataListView>(saveListViewFinder);

    // maxHeight が 80.0 から 140.0 の間にクランプされていること
    expect(saveListView.maxHeight, greaterThanOrEqualTo(80.0));
    expect(saveListView.maxHeight, lessThanOrEqualTo(140.0));
  });
}
