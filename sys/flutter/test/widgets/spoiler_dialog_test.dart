import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';

void main() {
  const sampleMarkdown = '''
# NetHack Spoilers {#intro}

NetHack は古典的なローグライクゲームです。詳細は[ダンジョン構造](#dungeon)を参照してください。

## ダンジョン構造 {#dungeon}

| 階層名 | 深度 | 備考 |
| --- | --- | --- |
| 運命の大迷宮 | 1-30 | メインルート |
| 鉱山 | 3-5から分岐 | ノーム鉱山 |

```
# サンプルコードブロック
Elbereth
```

![ダンジョン全景マップ](spoiler_dmap_jp.webp)

---

最後の段落です。
''';

  testWidgets('SpoilerDialog renders content, headings, table, and controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SpoilerDialog(
            initialMarkdown: sampleMarkdown,
            initialIsJp: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // タイトルと各ボタンの存在確認
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    expect(find.byIcon(Icons.toc), findsOneWidget); // 目次ボタン
    expect(find.byIcon(Icons.close), findsOneWidget);

    // 見出しと本文、リンクの存在確認
    expect(find.text('NetHack Spoilers', findRichText: true), findsOneWidget);
    expect(find.text('ダンジョン構造', findRichText: true), findsNWidgets(2)); // リンクと見出し
    expect(find.text('階層名', findRichText: true), findsOneWidget);
    expect(find.text('運命の大迷宮', findRichText: true), findsOneWidget);

    // 目次モーダルを開く
    await tester.tap(find.byIcon(Icons.toc));
    await tester.pumpAndSettle();

    // 目次ダイアログの要素確認
    expect(find.text('目次 (2項目)'), findsOneWidget);
    expect(find.text('NetHack Spoilers', findRichText: true), findsWidgets); // メイン画面と目次内

    // 目次ダイアログを閉じる
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // 検索機能のテスト
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'ノーム鉱山');
    await tester.pumpAndSettle();

    // 検索結果がヒットすること（「1/1」および前次ナビゲーションアイコン）
    expect(find.text('1/1'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    // 検索クリア
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // 検索クリア後は「1/1」が消えていること
    expect(find.text('1/1'), findsNothing);
  });
}

