import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/guidebook_dialog.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    await AppPrefs.setMockInitialValues({'selected_language': 'ja'});
    GuidebookDialog.resetSavedScrollPosition();
    SpoilerDialog.resetSavedScrollPosition();
  });

  final sampleMarkdown = List.generate(
    40,
    (i) => '## セクション $i {#sec-$i}\n\n本文テキスト行 $i です。[セクション30へ](#sec-30)',
  ).join('\n\n');

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }

  group('SpoilerDialog peek & scroll persistence tests', () {
    testWidgets('ヘッダーの目アイコンタップで透過維持モードになり、画面タップで復帰する', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態では不透明度 1.0、復帰バッジは非表示
      expect(find.text('タップして戻る'), findsNothing);
      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // ヘッダーの目アイコンをタップ
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // 透過状態 (opacity: 0.0) になり、上部に「タップして戻る」バッジが表示される
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );
      expect(find.text('タップして戻る'), findsOneWidget);

      // 画面中央をタップすると元の表示 (opacity: 1.0) に復帰し、バッジが消える
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
      expect(find.text('タップして戻る'), findsNothing);
    });

    testWidgets('本文領域を長押ししている間だけ透明になり、指を離すと復帰する（リンク誤爆しない）', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );

      // 本文のリンクテキスト上でポインタを押下して400ms保持
      final linkPos = tester.getCenter(find.text('セクション30へ').first);
      final gesture = await tester.startGesture(linkPos);
      await tester.pump(const Duration(milliseconds: 400));

      // 長押し中は不透明度 0.0 になり、かつタップ維持用バッジは出ない
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );
      expect(find.text('タップして戻る'), findsNothing);

      // 指を離すと元の表示 (opacity: 1.0) に戻り、リンクジャンプも誤発動しない
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
      expect(find.text('セクション 0'), findsOneWidget);
    });

    testWidgets('リンクを持たない通常テキストを長押ししても透明化する', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );

      // 通常本文テキスト（リンクではない領域）を長押し
      final plainTextFinder = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          return widget.text.toPlainText().contains('本文テキスト行 0 です。');
        }
        return false;
      });
      final plainTextPos = tester.getCenter(plainTextFinder.first);
      final gesture = await tester.startGesture(plainTextPos);
      await tester.pump(const Duration(milliseconds: 400));

      // 期待通り透明化する
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );

      // 指を離すと復帰する
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
    });

    testWidgets('長押し前の微小な指の広がり (<= 18px) ではスクロールせず透過し、透過後にドラッグしてもスクロールしない', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );

      final initialPos = tester.getTopLeft(find.text('セクション 0'));

      // 1. 本文テキストを押下し、100ms ごとに 3px ずつ微小移動（合計 9px <= 18px）
      final gesture = await tester.startGesture(tester.getCenter(find.text('セクション 0')));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 3));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 3));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 3));
      await tester.pump(const Duration(milliseconds: 100)); // 合計 400ms

      // スクロールせず元の位置のまま透明化している
      expect(tester.getTopLeft(find.text('セクション 0')), initialPos);
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );

      // 2. 透過が成立した後に大きく指を動かしても、アリーナで勝利済みのため本文はスクロールしない
      await gesture.moveBy(const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.text('セクション 0')), initialPos);

      // 指を離すと元の表示に復帰する
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
    });

    testWidgets('検索入力欄の長押しや通常スクロール中は透明化しない', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );

      // 1. 検索バーの TextField を長押ししても透明化しない
      final searchFieldPos = tester.getCenter(find.byType(TextField));
      final searchGesture = await tester.startGesture(searchFieldPos);
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
      await searchGesture.up();
      await tester.pumpAndSettle();

      // 2. 本文をドラッグしてスクロールしている最中は透明化しない
      final bodyPos = tester.getCenter(find.text('セクション 0'));
      final scrollGesture = await tester.startGesture(bodyPos);
      await tester.pump(const Duration(milliseconds: 100));
      await scrollGesture.moveBy(const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
      await scrollGesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('閉じて再度開いたときに前回のスクロール位置が維持される', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (_) => SpoilerDialog(
                    initialMarkdown: sampleMarkdown,
                    initialIsJp: true,
                  ),
                );
              },
              child: const Text('Open Spoiler'),
            ),
          ),
        ),
      );

      // 1回目のオープン
      await tester.tap(find.text('Open Spoiler'));
      await tester.pumpAndSettle();
      expect(find.text('セクション 0'), findsOneWidget);

      // リスト内のリンクをタップしてセクション30へジャンプ
      await tester.tap(find.text('セクション30へ').first);
      await tester.pumpAndSettle();
      expect(find.text('セクション 30'), findsOneWidget);

      // ダイアログを閉じる
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(SpoilerDialog), findsNothing);

      // 2回目のオープン：前回のスクロール位置（セクション30付近）から表示される
      await tester.tap(find.text('Open Spoiler'));
      await tester.pumpAndSettle();
      expect(find.text('セクション 30'), findsOneWidget);
    });
  });

  group('GuidebookDialog peek tests', () {
    testWidgets('ガイドブックでも目アイコンタップと本文・ヘッダー長押しで透明化できる', (tester) async {
      final sampleGuidebook = List.generate(
        30,
        (i) => '$i. セクション見出し $i\nガイドブックの本文テスト行 $i です。',
      ).join('\n\n');

      await tester.pumpWidget(
        buildTestApp(
          GuidebookDialog(
            initialContent: sampleGuidebook,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogOpacityFinder = find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(AnimatedOpacity),
      );
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // 目アイコンをタップして透過維持
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );
      expect(find.text('タップして戻る'), findsOneWidget);

      // 画面タップで復帰
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // ヘッダータイトルの長押しで一時透過し、離すと復帰
      final titlePos = tester.getCenter(find.text('NetHack ガイドブック'));
      final holdGesture = await tester.startGesture(titlePos);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );
      await holdGesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // 本文行の長押しで一時透過し、離すと復帰
      final bodyTextPos = tester.getCenter(find.textContaining('ガイドブックの本文テスト行 0 です。'));
      final bodyHoldGesture = await tester.startGesture(bodyTextPos);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        0.0,
      );
      await bodyHoldGesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );
    });
  });
}

