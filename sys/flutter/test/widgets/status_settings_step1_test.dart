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
    FontManager.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('status_settings_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString(
      'OPTIONS=time,showexp,hitpointbar\n'
      'OPTIONS=hilite_status:hitpoints/100%/white&bold\n',
    );

    mockPrefs = await AppPrefs.setMockInitialValues({
      'status_font_size': 13.0,
      'msg_font_size': 13.0,
      'nh_opt_hitpointbar': true,
      'nh_opt_hilite_status': true,
      'nh_opt_time': true,
      'nh_opt_showexp': true,
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

  Widget createSettingsApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: SettingsPage(
          defaultsFilePath: defaultsFile.path,
          dataDirString: tempDir.path,
        ),
      ),
    );
  }

  testWidgets('ステップ1: ステータス領域設定にフォントサイズ(8-32pt)と移動4項目が配置され、ゲームルール設定から消えていること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // ステータス領域設定セクションを展開
    final statusSectionTitle = find.text('ステータス領域設定');
    await tester.scrollUntilVisible(statusSectionTitle, 200);
    await tester.ensureVisible(statusSectionTitle);
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    // 4項目がステータス領域設定内に存在すること
    expect(find.text('HPバー表示 (hitpointbar)'), findsOneWidget);
    expect(find.text('ステータス強調 (hilite_status)'), findsOneWidget);
    expect(find.text('経過ターン表示 (time)'), findsOneWidget);
    expect(find.text('経験値表示 (showexp)'), findsOneWidget);

    // ステータスフォントサイズスライダーの最大値が 32.0 であること
    final statusCard = find.ancestor(
      of: statusSectionTitle,
      matching: find.byType(ExpansionTile),
    );
    final statusSlider = tester.widget<Slider>(
      find.descendant(of: statusCard, matching: find.byType(Slider)),
    );
    expect(statusSlider.min, equals(8.0));
    expect(statusSlider.max, equals(32.0));
    expect(statusSlider.divisions, equals(24));

    // ステータス領域設定を閉じる
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    // メッセージ領域設定を展開し、フォントサイズスライダーの最大値が 32.0 であることを確認
    final msgSectionTitle = find.text('メッセージ領域設定');
    await tester.scrollUntilVisible(msgSectionTitle, 200);
    await tester.ensureVisible(msgSectionTitle);
    await tester.tap(msgSectionTitle);
    await tester.pumpAndSettle();

    final msgCard = find.ancestor(
      of: msgSectionTitle,
      matching: find.byType(ExpansionTile),
    );
    final msgSliders = tester.widgetList<Slider>(
      find.descendant(of: msgCard, matching: find.byType(Slider)),
    ).toList();
    expect(msgSliders.last.min, equals(8.0));
    expect(msgSliders.last.max, equals(32.0));

    await tester.tap(msgSectionTitle);
    await tester.pumpAndSettle();

    // ゲームルール・プレイ設定セクションを展開し、移動した4項目が存在しないこと
    final gameRulesTitle = find.text('ゲームルール・プレイ設定 (defaults.nh)');
    await tester.scrollUntilVisible(gameRulesTitle, 200);
    await tester.ensureVisible(gameRulesTitle);
    await tester.tap(gameRulesTitle);
    await tester.pumpAndSettle();

    expect(find.text('HPバー表示 (hitpointbar)'), findsNothing);
    expect(find.text('ステータス強調 (hilite_status)'), findsNothing);
    expect(find.text('経過ターン表示 (time)'), findsNothing);
    expect(find.text('経験値表示 (showexp)'), findsNothing);
  });

  testWidgets('ステップ1: 移動した項目をステータス領域設定内で切り替えると AppPrefs と defaults.nh に保存されること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final statusSectionTitle = find.text('ステータス領域設定');
    await tester.scrollUntilVisible(statusSectionTitle, 200);
    await tester.ensureVisible(statusSectionTitle);
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    final timeSwitch = find.widgetWithText(SwitchListTile, '経過ターン表示 (time)');
    await tester.scrollUntilVisible(timeSwitch, 200);
    await tester.ensureVisible(timeSwitch);
    await tester.tap(timeSwitch);
    await tester.pumpAndSettle();

    expect(mockPrefs.getBool('nh_opt_time'), isFalse);

    String defaultsContent = '';
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        defaultsContent = await defaultsFile.readAsString();
      });
      await tester.pump();
      if (defaultsContent.contains('!time')) break;
    }
    expect(defaultsContent, contains('!time'));
  });
}
