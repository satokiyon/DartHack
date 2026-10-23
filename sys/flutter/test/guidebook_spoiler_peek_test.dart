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

      // 本文のリンクテキスト上でポインタを押下
      final linkPos = tester.getCenter(find.text('セクション30へ').first);
      final gesture = await tester.startGesture(linkPos);

      // 500ms 時点（800ms 未満）ではまだ透明化しない
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<AnimatedOpacity>(dialogOpacityFinder.first).opacity,
        1.0,
      );

      // さらに 350ms 経過（合計 850ms > 800ms）で透明化する
      await tester.pump(const Duration(milliseconds: 350));

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
      await tester.pump(const Duration(milliseconds: 850));

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

      // 1. 本文テキストを押下し、100ms ごとに 2px ずつ微小移動（合計 10px <= 18px）
      final gesture = await tester.startGesture(tester.getCenter(find.text('セクション 0')));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveBy(const Offset(0, 2));
      }
      await tester.pump(const Duration(milliseconds: 400)); // 合計 900ms (> 800ms)

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
      await tester.pump(const Duration(milliseconds: 900));
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
      await tester.pump(const Duration(milliseconds: 850));
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
      await tester.pump(const Duration(milliseconds: 850));
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
      await tester.pump(const Duration(milliseconds: 850));
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

    testWidgets('ガイドブックのMarkdown要素（見出し・画像・details折りたたみ・テーブル・検索）が正しくレンダリングされる', (tester) async {
      const sampleMarkdown = '''
# NetHack 5.0 ガイドブック

## 1. はじめに (Introduction)
冒険者への最初のメッセージです。

![図1: 画面レイアウトサンプル](images/fig1.webp)

<details>
<summary>テキスト版（アスキーアート）を表示</summary>

```text
+-----------------------+
| Sample ASCII Art      |
+-----------------------+
```
</details>

### 1.1 基本操作
コマンド一覧の表です。

| コマンド | 説明 |
| --- | --- |
| h | 左移動 |
| j | 下移動 |

終わり。
''';

      await tester.pumpWidget(
        buildTestApp(
          const GuidebookDialog(
            initialContent: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 見出しの表示確認
      expect(find.text('NetHack 5.0 ガイドブック'), findsOneWidget);
      expect(find.text('1. はじめに (Introduction)'), findsOneWidget);

      // キャプションの表示確認
      expect(find.text('図1: 画面レイアウトサンプル'), findsOneWidget);

      // details 折りたたみサマリーの表示確認
      expect(find.text('テキスト版（アスキーアート）を表示'), findsOneWidget);

      // 検索機能のテスト（「コマンド」を検索してテーブルブロックへ自動スクロール）
      await tester.enterText(find.byType(TextField).first, 'コマンド');
      await tester.pumpAndSettle();
      expect(find.textContaining('/'), findsWidgets);

      // スクロール先でテーブルのヘッダー・セル確認
      expect(find.text('説明'), findsOneWidget);
      expect(find.text('左移動'), findsOneWidget);

      // 目次モーダルのオープンと項目確認
      await tester.tap(find.byIcon(Icons.toc));
      await tester.pumpAndSettle();
      expect(find.textContaining('目次'), findsWidgets);
      expect(find.text('1. はじめに (Introduction)'), findsWidgets);

      // 目次を閉じる
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
    });

    testWidgets('NetHack特有の#コマンド行（#? や # SYMBOLS）が含まれていても無限ループせず高速描画される', (tester) async {
      const sampleNetHackMarkdown = '''
# コマンド一覧

## 拡張コマンド
以下は拡張コマンドです。

  #? ヘルプメニュー：利用可能な拡張コマンドのリストを取得します。
  #loot 容器を漁る、または隣接するモンスターの鞍を外します。
  # SYMBOLS=S_golem:7

正常終了。
''';

      await tester.pumpWidget(
        buildTestApp(
          const GuidebookDialog(
            initialContent: sampleNetHackMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('拡張コマンド'), findsOneWidget);
      expect(find.textContaining('#? ヘルプメニュー'), findsOneWidget);
      expect(find.textContaining('#loot 容器を漁る'), findsOneWidget);
    });

    testWidgets('インラインコード（`*` や `` ` ``）およびセル内パイプ（`|`）を含むテーブルが例外なく正確に描画される', (tester) async {
      const backtickMarkdown = '''
# バッククォートとアスタリスクのテスト

この例では、`*` も表示されており、予期しないものを使いたい場合に、リストにないアイテムを選択できることを示しています。`*` と入力すると次のプロンプトが出ます。

インベントリ内には、キー `*` や `` ` ``（特定のクラスの既知の発見済みアイテム一覧を表示）があります。

### 9.15 NetHackの記号の変更
| デフォルトの記号 | 名前 | 説明 |
|---|---|---|
| `|` | S_vwall | 垂直な壁 |
| `-` | S_hwall | 水平な壁 |
| `|` | S_grave | 墓 |
| `\\|` | S_pipe | パイプエスケープ |
''';

      await tester.pumpWidget(
        buildTestApp(
          const GuidebookDialog(
            initialContent: backtickMarkdown,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 各インラインコードスパンが Text ウィジェットとして正しく抽出・描画されていること
      expect(find.text('*'), findsWidgets);
      expect(find.text('`'), findsOneWidget);
      expect(find.text('|'), findsNWidgets(2)); // テーブル内の `|` セル

      // 説明文の通常テキストも正常に表示されていること
      expect(find.text('S_vwall'), findsOneWidget);
      expect(find.text('S_grave'), findsOneWidget);
      expect(find.text('垂直な壁'), findsOneWidget);
      expect(find.text('墓'), findsOneWidget);

      // DataTable が 1 個描画されており、アサーション例外なく行が表示されていること
      expect(find.byType(DataTable), findsOneWidget);
    });

    testWidgets('SpoilerDialog でもダブルバッククォートやセル内パイプテーブルが例外なく正確に描画される', (tester) async {
      const sampleSpoilerTable = '''
# スポイラーテーブルテスト

キー `` ` `` で発見済みアイテムを表示します。

| 記号 | 名前 | 概要 |
|---|---|---|
| `|` | wall | 壁 |
| `.` | floor | 床 |
''';

      await tester.pumpWidget(
        buildTestApp(
          SpoilerDialog(
            initialMarkdown: sampleSpoilerTable,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('`'), findsOneWidget);
      expect(find.text('|'), findsOneWidget);
      expect(find.text('wall'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
    });
  });
}

