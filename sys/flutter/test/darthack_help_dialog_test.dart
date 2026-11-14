import 'dart:io';

import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/screens/start_screen.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/darthack_help_dialog.dart';
import 'package:darthack/widgets/game_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AppPrefs.setMockInitialValues({'selected_language': 'ja'});
    DartHackHelpDialog.resetSavedScrollPosition();
  });

  Widget buildApp(Widget child, {Locale locale = const Locale('ja')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );
  }

  group('DartHackHelpDialog unit & widget tests', () {
    test('resolveManualImagePath が日英 PNG パスを WebP アセットパスへ解決する', () {
      final ja = DartHackHelpDialog.resolveManualImagePath(
        'images/manual/ja/01_title.png',
        true,
      );
      expect(ja.path, 'assets/manual/ja/images/01_title.webp');
      expect(ja.fallbackPath, 'assets/manual/ja/images/01_title.png');

      final en = DartHackHelpDialog.resolveManualImagePath(
        'images/manual/en/03c_cmd_button_customize.png',
        false,
      );
      expect(en.path, 'assets/manual/en/images/03c_cmd_button_customize.webp');
      expect(
        en.fallbackPath,
        'assets/manual/en/images/03c_cmd_button_customize.png',
      );
    });

    testWidgets('検索・目次・透過(Peek)の基本操作が動作する', (tester) async {
      const md = '''
# DartHack テストマニュアル

## 1. はじめに

これはテスト用の導入段落です。キーワード alpha を含みます。

> [!TIP]
> ヒント用のコールアウトです。

## 2. 操作説明

1. 最初の項目です。キーワード beta を含みます。
2. 二番目の項目です。キーワード alpha を再度含みます。
''';

      await tester.pumpWidget(
        buildApp(
          const DartHackHelpDialog(
            initialMarkdown: md,
            initialIsJp: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // コールアウトタグ生文字列は消え、TIP ラベルとして表示される
      expect(find.text('[!TIP]'), findsNothing);
      expect(find.text('TIP'), findsOneWidget);

      // 検索バーで "alpha" を検索 -> 2件ヒット ("1/2")
      await tester.enterText(find.byType(TextField), 'alpha');
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);

      // 次の一致ボタンで 2/2 へ
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);

      // 目次を開く
      await tester.tap(find.byIcon(Icons.toc));
      await tester.pumpAndSettle();
      final tocSheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: tocSheet, matching: find.text('1. はじめに')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tocSheet, matching: find.text('2. 操作説明')),
        findsOneWidget,
      );

      // 目次項目タップで閉じる
      await tester.tap(
        find.descendant(of: tocSheet, matching: find.text('2. 操作説明')),
      );
      await tester.pumpAndSettle();

      // 透過（Peek）ボタンタップで半透明モードに入り、タップで戻る
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.text('タップして戻る'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('タップして戻る'), findsNothing);
    });

    testWidgets('実際の生成済み日英 darthack_help.md 全文を破綻なくパースして表示できる',
        (tester) async {
      final jaFile = File('assets/manual/ja/darthack_help.md');
      final enFile = File('assets/manual/en/darthack_help.md');
      if (!jaFile.existsSync() || !enFile.existsSync()) {
        return;
      }

      for (final entry in [
        (file: jaFile, isJp: true, locale: const Locale('ja'), ch16: '16. 高度な設定'),
        (file: enFile, isJp: false, locale: const Locale('en'), ch16: '16. Advanced'),
      ]) {
        final content = entry.file.readAsStringSync();
        await tester.pumpWidget(
          buildApp(
            DartHackHelpDialog(
              key: ValueKey(entry.isJp),
              initialMarkdown: content,
              initialIsJp: entry.isJp,
            ),
            locale: entry.locale,
          ),
        );
        await tester.pumpAndSettle();

        // 生の [!TIP] / [!NOTE] 文字列が残っていないこと
        expect(find.textContaining('[!TIP]'), findsNothing);
        expect(find.textContaining('[!NOTE]'), findsNothing);

        // 目次を開き、絞り込みで16章が抽出されていること
        await tester.tap(find.byIcon(Icons.toc));
        await tester.pumpAndSettle();
        final tocFilterField = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        );
        await tester.enterText(tocFilterField, '16.');
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining(entry.ch16),
          ),
          findsOneWidget,
        );

        // 目次を Esc キーで閉じる
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      }
    });
  });

  group('タイトル画面とドロワーメニューの導線テスト', () {
    testWidgets('StartScreen の上部左にガイドブック・スポイラー・DartHackヘルプの3アイコンが並ぶ',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          StartScreen(
            assetsReady: true,
            selectedLanguage: 'ja',
            onLanguageChanged: (_) {},
            onStartGame: () {},
            onShowSettings: () {},
          ),
        ),
      );
      await tester.pump();

      final guidebookPos = tester.getTopLeft(find.byIcon(Icons.menu_book));
      final spoilerPos = tester.getTopLeft(find.byIcon(Icons.auto_stories));
      final helpPos = tester.getTopLeft(find.byIcon(Icons.article_outlined));

      expect(guidebookPos.dx, lessThan(spoilerPos.dx));
      expect(spoilerPos.dx, lessThan(helpPos.dx));
      expect((spoilerPos.dy - helpPos.dy).abs(), lessThan(4.0));
    });

    testWidgets('GameDrawerContent に日英それぞれ正しい順序でヘルプ項目と境界線が表示される',
        (tester) async {
      for (final entry in [
        (
          locale: const Locale('ja'),
          spoilers: 'スポイラーを読む',
          darthackHelp: 'マニュアルを読む',
          nethackHelp: 'ヘルプを表示 (?)',
        ),
        (
          locale: const Locale('en'),
          spoilers: 'Read Spoilers',
          darthackHelp: 'Read Manual',
          nethackHelp: 'Show Help (?)',
        ),
      ]) {
        bool helpTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: entry.locale,
            home: Scaffold(
              body: SizedBox(
                height: 900,
                child: GameDrawerContent(
                  isGameRunning: true,
                  isKeyboardVisible: false,
                  onClose: () {},
                  onSaveAndExit: () {},
                  onQuit: () {},
                  onShowScoreboard: () {},
                  onShowGuidebook: () {},
                  onShowSpoilers: () {},
                  onShowDartHackHelp: () => helpTapped = true,
                  onShowHelp: () {},
                  onDatabaseSearch: () {},
                  onOpenOptions: () {},
                  onShowFullMap: () {},
                  onToggleKeyboard: () {},
                  onShowSettings: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final spoilersFinder = find.text(entry.spoilers);
        final darthackHelpFinder = find.text(entry.darthackHelp);
        final nethackHelpFinder = find.text(entry.nethackHelp);

        expect(spoilersFinder, findsOneWidget);
        expect(darthackHelpFinder, findsOneWidget);
        expect(nethackHelpFinder, findsOneWidget);

        final spoilersY = tester.getTopLeft(spoilersFinder).dy;
        final darthackHelpY = tester.getTopLeft(darthackHelpFinder).dy;
        final nethackHelpY = tester.getTopLeft(nethackHelpFinder).dy;

        // スポイラーの下、NetHackヘルプの上に配置されていること
        expect(spoilersY, lessThan(darthackHelpY));
        expect(darthackHelpY, lessThan(nethackHelpY));

        // 境界線（Divider）が DartHackヘルプと NetHackヘルプの間にあること
        final dividers = tester
            .widgetList<Divider>(find.byType(Divider))
            .toList();
        final dividerYs = find
            .byType(Divider)
            .evaluate()
            .map((e) => (e.renderObject as RenderBox).localToGlobal(Offset.zero).dy)
            .toList();
        expect(
          dividers.isNotEmpty &&
              dividerYs.any((y) => y > darthackHelpY && y < nethackHelpY),
          isTrue,
        );

        await tester.tap(darthackHelpFinder);
        await tester.pump();
        expect(helpTapped, isTrue);
      }
    });
  });
}
