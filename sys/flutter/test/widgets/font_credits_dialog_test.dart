import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/widgets/font_credits_dialog.dart';

void main() {
  Widget buildTestableWidget({Locale locale = const Locale('ja')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => FontCreditsDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('FontCreditsDialog が正常に描画され、5種類の同梱フォント情報が表示されること (日本語)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('ja')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // タイトルの検証
    expect(find.text('フォント ライセンス・クレジット'), findsOneWidget);
    expect(find.text('DartHack に同梱されているフォントの著作者およびライセンス一覧です。'), findsOneWidget);

    // 5種類のフォント名が表示されていること
    expect(find.text('PixelMplus10'), findsOneWidget);
    expect(find.text('Terminus (TTF)'), findsOneWidget);
    expect(find.text('PxPlus IBM VGA 9x16'), findsOneWidget);
    expect(find.text('美咲ゴシック (Misaki Gothic)'), findsOneWidget);
    expect(find.text('Unscii 8x8'), findsOneWidget);

    // ライセンス名が表示されていること
    expect(find.text('ライセンス: M+ FONT LICENSE'), findsOneWidget);
    expect(find.text('ライセンス: SIL Open Font License 1.1'), findsOneWidget); // Terminus
    expect(find.text('ライセンス: Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)'), findsOneWidget);
    expect(find.text('ライセンス: 自由利用 (フリーソフトウェア)'), findsOneWidget);
    expect(find.text('ライセンス: Public Domain (CC0 1.0 Universal)'), findsOneWidget);

    // 閉じるボタンの検証
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('フォント ライセンス・クレジット'), findsNothing);
  });

  testWidgets('FontCreditsDialog が英語モードで正しくローカライズ表示されること', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 英語タイトルの検証
    expect(find.text('Font Licenses & Credits'), findsOneWidget);
    expect(find.text('List of authors and licenses for fonts bundled with DartHack.'), findsOneWidget);

    // 閉じるアイコンで閉じること
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Font Licenses & Credits'), findsNothing);
  });

  testWidgets('URL タップ時にクリップボードコピーの SnackBar が表示されること', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('ja')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // PixelMplus の URL をタップ
    final urlFinder = find.text('https://github.com/itouhiro/PixelMplus');
    expect(urlFinder, findsOneWidget);
    await tester.tap(urlFinder);
    await tester.pump(); // SnackBar アニメーション開始

    expect(find.text('URLをクリップボードにコピーしました'), findsOneWidget);
  });

  test('FontManager.registerFontLicenses() により LicenseRegistry にフォントライセンスが登録されること', () async {
    FontManager.registerFontLicenses();

    final licenses = <LicenseEntry>[];
    await for (final entry in LicenseRegistry.licenses) {
      licenses.add(entry);
    }

    final packages = licenses.expand((l) => l.packages).toSet();
    expect(packages.contains('PixelMplus10'), isTrue);
    expect(packages.contains('Terminus (TTF)'), isTrue);
    expect(packages.contains('PxPlus IBM VGA 9x16'), isTrue);
    expect(packages.contains('美咲ゴシック (Misaki Gothic)'), isTrue);
    expect(packages.contains('Unscii 8x8'), isTrue);
  });
}

