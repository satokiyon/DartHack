import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/settings_page.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/utils/defaults_helper.dart';
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
    tempDir = await Directory.systemTemp.createTemp('settings_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString('OPTIONS=symset:IBMGraphics_2,runmode:walk\n');

    mockPrefs = await AppPrefs.setMockInitialValues({
      'nh_opt_symset': 'IBMGraphics_2',
      'nh_opt_roguesymset': 'Default',
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

  testWidgets('SettingsPage にシンボルセット設定およびフォント設定が表示されること', (tester) async {
    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // セクションタイトルの存在確認
    expect(find.text('シンボルセット設定 (symset)'), findsOneWidget);
    expect(find.text('フォント設定'), findsOneWidget);
  });

  testWidgets('シンボルセットセクションを展開して symset / roguesymset を変更・保存できること', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // シンボルセットセクションを展開
    final symsetSectionTitle = find.text('シンボルセット設定 (symset)');
    await tester.ensureVisible(symsetSectionTitle);
    await tester.tap(symsetSectionTitle);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('通常階層シンボルセット (symset)'), findsOneWidget);
    expect(find.text('ローグ階層シンボルセット (roguesymset)'), findsOneWidget);

    // ドロップダウンで通常 symset を変更
    final symsetFinder = find.widgetWithText(ListTile, '通常階層シンボルセット (symset)');
    await tester.ensureVisible(symsetFinder);
    await tester.pump(const Duration(milliseconds: 300));

    final currentSymsetText = find.descendant(
      of: symsetFinder,
      matching: find.text('IBMGraphics_2'),
    );
    expect(currentSymsetText, findsOneWidget);

    await tester.tap(currentSymsetText);
    await tester.pump(const Duration(milliseconds: 500));

    // ドロップダウンアイテムに Enhanced1 と Enhanced2 が含まれることを検証
    expect(find.text('Enhanced1'), findsWidgets);
    expect(find.text('Enhanced2'), findsWidgets);

    final itemFinder = find.text('Enhanced1').last;
    await tester.tap(itemFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // Prefs への即時反映を検証
    expect(mockPrefs.getString('nh_opt_symset'), 'Enhanced1');

    // DefaultsHelper による defaults.nh への書き込みと runmode:walk の保護を検証 (runAsync 内で実 I/O を実行)
    String savedContent = '';
    await tester.runAsync(() async {
      final helper = DefaultsHelper();
      await helper.syncFromPrefsToFile(defaultsFile.path);
      savedContent = await defaultsFile.readAsString();
    });
    expect(savedContent, contains('symset:Enhanced1'));
    expect(savedContent, contains('runmode:walk')); // 既存オプション保護
  });

  testWidgets('フォント設定セクションを展開して一括変更およびマップフォントを変更できること', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // フォント設定セクションをスクロールして見つけて展開
    final fontSectionFinder = find.text('フォント設定');
    await tester.scrollUntilVisible(fontSectionFinder, 200);
    await tester.ensureVisible(fontSectionFinder);
    await tester.tap(fontSectionFinder);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('一括フォント変更'), findsOneWidget);
    expect(find.text('マップフォント (font_map)'), findsOneWidget);
    expect(find.text('アスキーマップ表示倍率'), findsOneWidget);

    // 一括変更ドロップダウンをタップ
    final allTileFinder = find.widgetWithText(ListTile, '一括フォント変更');
    await tester.ensureVisible(allTileFinder);
    await tester.pump(const Duration(milliseconds: 300));

    final hintText = find.descendant(
      of: allTileFinder,
      matching: find.text('フォント選択'),
    );
    expect(hintText, findsOneWidget);

    await tester.tap(hintText, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // 'Unscii 8x8 (レトロPC)' を選択
    final unsciiItem = find.text('Unscii 8x8 (レトロPC)').last;
    await tester.tap(unsciiItem, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // 全ターゲットが Unscii-8 に更新されたことを検証
    for (final target in FontTarget.values) {
      expect(FontManager.instance.getSelectedFont(target).id, 'Unscii-8');
    }
  });

  testWidgets('英語モード時にフォント設定の選択肢が英語表示されること', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await mockPrefs.setString('selected_language', 'en');

    // 英語ロケールでアプリを構築
    await tester.pumpWidget(createSettingsApp(locale: const Locale('en')));
    await tester.pump(const Duration(milliseconds: 500));

    // フォント設定セクション (Font Settings) をスクロールして展開
    final fontSectionFinder = find.text('Font Settings');
    await tester.scrollUntilVisible(fontSectionFinder, 200);
    await tester.ensureVisible(fontSectionFinder);
    await tester.tap(fontSectionFinder);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Apply Font to All'), findsOneWidget);
    expect(find.text('Map Font (font_map)'), findsOneWidget);

    // 一括変更ドロップダウンをタップ
    final allTileFinder = find.widgetWithText(ListTile, 'Apply Font to All');
    await tester.ensureVisible(allTileFinder);
    await tester.pump(const Duration(milliseconds: 300));

    final hintText = find.descendant(
      of: allTileFinder,
      matching: find.text('Select Font'),
    );
    expect(hintText, findsOneWidget);

    await tester.tap(hintText, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    // ドロップダウンアイテムが英語表記になっていること
    expect(find.text('System Default (Monospace)'), findsWidgets);
    expect(find.text('Terminus TTF (Classic ASCII)'), findsWidgets);
    expect(find.text('Unscii 8x8 (Retro PC)'), findsWidgets);
    expect(find.text('Unscii 16x16 (Hi-Res Retro)'), findsWidgets);
    expect(find.text('Misaki Gothic (Retro Pixel JP)'), findsWidgets);
  });
}
