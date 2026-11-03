import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late File defaultsFile;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('jp.satokiyo.darthack/key_interceptor'),
      (call) async => null,
    );
    PackageInfo.setMockInitialValues(
      appName: 'DartHack',
      packageName: 'com.darthack',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    tempDir = await Directory.systemTemp.createTemp('credits_support_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString('OPTIONS=symset:IBMGraphics_2\n');
    await AppPrefs.setMockInitialValues({});
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget buildTestableWidget({Locale locale = const Locale('ja')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SettingsPage(
          defaultsFilePath: defaultsFile.path,
          dataDirString: tempDir.path,
        ),
      ),
    );
  }

  testWidgets('クレジット画面にチップ支援リンク（Ko-fi, GitHub Sponsors）が表示されタップでコピーされること (日本語)', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final log = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
      log.add(methodCall);
      if (methodCall.method == 'Clipboard.setData') {
        return null;
      }
      return null;
    });

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('ja')));
    await tester.pumpAndSettle();

    // クレジットアコーディオンを探して展開
    final creditsTile = find.widgetWithText(ExpansionTile, 'クレジット');
    expect(creditsTile, findsOneWidget);
    await tester.ensureVisible(creditsTile);
    await tester.tap(creditsTile);
    await tester.pumpAndSettle();

    // 支援セクション見出しと各リンクの表示確認
    expect(find.text('開発者を支援:'), findsWidgets);
    expect(find.text('https://ko-fi.com/satokiyon'), findsWidgets);
    expect(find.text('https://github.com/sponsors/satokiyon'), findsWidgets);

    // Ko-fi リンクをタップ
    final kofiRow = find.text('https://ko-fi.com/satokiyon').first;
    await tester.ensureVisible(kofiRow);
    await tester.tap(kofiRow);
    await tester.pumpAndSettle();

    // クリップボードにコピーされたことを検証
    expect(
      log.any((call) =>
          call.method == 'Clipboard.setData' &&
          (call.arguments as Map)['text'] == 'https://ko-fi.com/satokiyon'),
      isTrue,
    );

    // スナックバーの表示確認
    expect(find.text('URLをクリップボードにコピーしました'), findsWidgets);
  });

  testWidgets('クレジット画面の支援見出しが英語モードで正しく表示されること (英語)', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    // Credits アコーディオンを探して展開
    final creditsTile = find.widgetWithText(ExpansionTile, 'Credits');
    expect(creditsTile, findsOneWidget);
    await tester.ensureVisible(creditsTile);
    await tester.tap(creditsTile);
    await tester.pumpAndSettle();

    expect(find.text('Support the Developer:'), findsWidgets);
    expect(find.text('https://ko-fi.com/satokiyon'), findsWidgets);
    expect(find.text('https://github.com/sponsors/satokiyon'), findsWidgets);
  });
}
