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
    tempDir = await Directory.systemTemp.createTemp('ad_features_test_');
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

  testWidgets('「その他の設定」に広告付き機能設定と支援リンクが表示され、トグル操作できること', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final prefs = await AppPrefs.getInstance();

    await tester.pumpWidget(buildTestableWidget(locale: const Locale('ja')));
    await tester.pumpAndSettle();

    // 「その他の設定」アコーディオンを展開
    final otherTile = find.widgetWithText(ExpansionTile, 'その他の設定');
    expect(otherTile, findsOneWidget);
    await tester.ensureVisible(otherTile);
    await tester.tap(otherTile);
    await tester.pumpAndSettle();

    // タイトルと各スイッチの存在確認
    expect(find.text('広告付き機能の利用'), findsOneWidget);
    expect(find.text('新階層到達時のHP/Pw回復確認'), findsOneWidget);
    expect(find.text('ゲーム終了時のハイライト表示'), findsOneWidget);
    expect(find.text('本アプリは広告非表示でも快適にプレイいただけます。もし開発を応援していただける場合は、チップ支援をいただけますと幸いです。'), findsOneWidget);

    // デフォルトでONになっていること
    final parentSwitch = find.widgetWithText(SwitchListTile, '広告付き機能の利用');
    expect(tester.widget<SwitchListTile>(parentSwitch).value, isTrue);

    // 子スイッチ1「新階層到達時のHP/Pw回復確認」をOFFに切り替え
    final newLevelSwitch = find.widgetWithText(SwitchListTile, '新階層到達時のHP/Pw回復確認');
    expect(tester.widget<SwitchListTile>(newLevelSwitch).value, isTrue);
    await tester.tap(newLevelSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(newLevelSwitch).value, isFalse);
    expect(prefs.getBool('ad_feature_new_level_rest'), isFalse);

    // 親スイッチ「広告付き機能の利用」をOFFに切り替え
    await tester.tap(parentSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(parentSwitch).value, isFalse);
    expect(prefs.getBool('ad_features_enabled'), isFalse);

    // 親がOFFのとき、子スイッチのonChangedがnull（無効化）であること
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, '新階層到達時のHP/Pw回復確認')).onChanged, isNull);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'ゲーム終了時のハイライト表示')).onChanged, isNull);
  });
}
