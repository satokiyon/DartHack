import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/settings_page.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File defaultsFile;
  late AppPrefs mockPrefs;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('darthack/key_interceptor'),
      (call) async => null,
    );
    PackageInfo.setMockInitialValues(
      appName: 'DartHack',
      packageName: 'com.darthack',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    FontManager.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('anim_settings_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString('OPTIONS=symset:IBMGraphics_2,runmode:walk\n');

    mockPrefs = await AppPrefs.setMockInitialValues({
      'use_tiles': true,
      'map_animation_enabled': true,
      'map_animation_speed': 'normal',
    });

    await FontManager.instance.init(prefs: mockPrefs, customFontsDir: tempDir);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget createSettingsApp({Locale locale = const Locale('ja')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SettingsPage(
          defaultsFilePath: defaultsFile.path,
          dataDirString: tempDir.path,
        ),
      ),
    );
  }

  group('Map Animation Settings Tests', () {
    testWidgets('日本語画面でアニメーション ON/OFF と速度変更が永続化され、OFF 時に速度が無効化される', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSettingsApp(locale: const Locale('ja')));
      await tester.pump(const Duration(milliseconds: 400));

      final sectionFinder = find.text('画面表示設定');
      await tester.scrollUntilVisible(sectionFinder, 200);
      await tester.pumpAndSettle();
      await tester.tap(sectionFinder);
      await tester.pumpAndSettle();

      final animTitle = find.text('アニメーション');
      await tester.scrollUntilVisible(animTitle, 200);
      await tester.pumpAndSettle();
      expect(animTitle, findsOneWidget);
      expect(find.text('アニメーション速度'), findsOneWidget);

      // 速度を「速い」に変更
      final speedValue = find.text('標準');
      await tester.scrollUntilVisible(speedValue, 200);
      await tester.pumpAndSettle();
      await tester.tap(speedValue);
      await tester.pumpAndSettle();
      await tester.tap(find.text('速い').last);
      await tester.pumpAndSettle();
      expect(mockPrefs.getString('map_animation_speed'), 'fast');

      // アニメーションスイッチを OFF に切替
      final switchTile = find.ancestor(
        of: animTitle,
        matching: find.byType(SwitchListTile),
      );
      await tester.scrollUntilVisible(switchTile, -200);
      await tester.pumpAndSettle();
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      expect(mockPrefs.getBool('map_animation_enabled'), isFalse);
      expect(find.text('※「アニメーション」がONのときのみ設定可能です'), findsOneWidget);

      // フローティングテキストはアニメーション OFF でも独立して操作・永続化できる
      final floatTitle = find.text('フローティングテキスト');
      await tester.scrollUntilVisible(floatTitle, 200);
      await tester.pumpAndSettle();
      expect(floatTitle, findsOneWidget);
      final floatSwitch = find.ancestor(
        of: floatTitle,
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(floatSwitch);
      await tester.pumpAndSettle();
      expect(mockPrefs.getBool('floating_text_enabled'), isFalse);
    });

    testWidgets('英語画面でもアニメーション設定項目が正しく表示される', (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSettingsApp(locale: const Locale('en')));
      await tester.pump(const Duration(milliseconds: 400));

      final sectionFinder = find.text('Screen Display Settings');
      await tester.scrollUntilVisible(sectionFinder, 200);
      await tester.pumpAndSettle();
      await tester.tap(sectionFinder);
      await tester.pumpAndSettle();

      final animTitle = find.text('Smooth Animations');
      await tester.scrollUntilVisible(animTitle, 200);
      await tester.pumpAndSettle();
      expect(animTitle, findsOneWidget);
      expect(find.text('Animation Speed'), findsOneWidget);
      expect(find.text('Floating Text'), findsOneWidget);
    });
  });
}
