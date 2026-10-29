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
      'use_tiles': true,
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

  testWidgets('SettingsPage にタイル／シンボル設定およびフォント設定が表示されること', (tester) async {
    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // セクションタイトルの存在確認
    expect(find.text('タイル／シンボル設定'), findsOneWidget);
    expect(find.text('フォント設定'), findsOneWidget);
  });

  testWidgets('タイル／シンボル設定でタイル表示をOFFにすると symset / roguesymset が表示され変更・保存できること', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // タイル／シンボル設定セクションを展開
    final sectionTitle = find.text('タイル／シンボル設定');
    await tester.scrollUntilVisible(sectionTitle, 200);
    await tester.ensureVisible(sectionTitle);
    await tester.tap(sectionTitle);
    await tester.pumpAndSettle();

    // タイル表示を使用がONの間はシンボルセットは非表示
    expect(find.text('通常階層シンボルセット (symset)'), findsNothing);

    // 「タイル表示を使用」スイッチをタップしてOFFにする
    final useTilesSwitch = find.widgetWithText(SwitchListTile, 'タイル表示を使用');
    await tester.scrollUntilVisible(useTilesSwitch, 200);
    await tester.ensureVisible(useTilesSwitch);
    await tester.tap(useTilesSwitch);
    await tester.pumpAndSettle();

    // OFFになったことでシンボルセット設定が表示される
    final symsetTitle = find.text('通常階層シンボルセット (symset)');
    await tester.scrollUntilVisible(symsetTitle, 200);
    await tester.ensureVisible(symsetTitle);
    expect(symsetTitle, findsOneWidget);
    expect(find.text('ローグ階層シンボルセット (roguesymset)'), findsOneWidget);

    // ドロップダウンで通常 symset を変更
    final symsetFinder = find.widgetWithText(ListTile, '通常階層シンボルセット (symset)');
    await tester.scrollUntilVisible(symsetFinder, 200);
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

    // フォント設定セクションを展開
    final fontSectionFinder = find.text('フォント設定');
    await tester.scrollUntilVisible(fontSectionFinder, 200);
    await tester.ensureVisible(fontSectionFinder);
    await tester.tap(fontSectionFinder);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('一括フォント変更'), findsOneWidget);
    expect(find.text('マップフォント'), findsOneWidget);
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
    expect(find.text('Map Font'), findsOneWidget);

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
    expect(find.text('IBM VGA 9x16 (Classic PC)'), findsWidgets);
    expect(find.text('PixelMplus12 (8-bit Pixel JP)'), findsWidgets);
    expect(find.text('Misaki Gothic (Retro Pixel JP)'), findsWidgets);
  });

  testWidgets('スマホ縦画面 (幅 < 600px) でプルダウン項目が上下配置になり正常に選択できること', (tester) async {
    // 典型的なスマホ縦画面サイズ (幅 380px)
    tester.view.physicalSize = const Size(380, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await mockPrefs.setString('selected_language', 'ja');

    await tester.pumpWidget(createSettingsApp());
    await tester.pump(const Duration(milliseconds: 500));

    // タイル／シンボル設定セクションを展開
    final symsetSectionTitle = find.text('タイル／シンボル設定');
    await tester.scrollUntilVisible(symsetSectionTitle, 200);
    await tester.ensureVisible(symsetSectionTitle);
    await tester.tap(symsetSectionTitle);
    await tester.pumpAndSettle();

    // 「タイル表示を使用」をタップしてOFFにする
    final useTilesSwitch = find.widgetWithText(SwitchListTile, 'タイル表示を使用');
    await tester.scrollUntilVisible(useTilesSwitch, 200);
    await tester.ensureVisible(useTilesSwitch);
    await tester.tap(useTilesSwitch);
    await tester.pumpAndSettle();

    // タイトルと説明文が表示されていること
    final titleFinder = find.text('通常階層シンボルセット (symset)');
    await tester.scrollUntilVisible(titleFinder, 200);
    await tester.ensureVisible(titleFinder);
    expect(titleFinder, findsOneWidget);
    expect(find.text('アスキー描画時に壁・床・道具等を描画するシンボル定義セットです。'), findsOneWidget);

    // スマホ縦画面では上下配置 (Column) として描画されていることを検証
    final columnFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(Column),
    ).first;
    expect(columnFinder, findsOneWidget);

    // ドロップダウンに表示されている現在の選択値テキスト ('IBMGraphics_2') を特定
    final currentSymsetText = find.descendant(
      of: columnFinder,
      matching: find.text('IBMGraphics_2'),
    );
    expect(currentSymsetText, findsOneWidget);

    // スクロールして画面中央に表示
    await Scrollable.ensureVisible(tester.element(currentSymsetText), alignment: 0.5);
    await tester.pumpAndSettle();

    await tester.tap(currentSymsetText);
    await tester.pump(const Duration(milliseconds: 500));

    // メニューから 'Enhanced1' を選択
    final itemFinder = find.text('Enhanced1').last;
    expect(itemFinder, findsOneWidget);
    await tester.tap(itemFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // Prefs に正しく保存されたことを検証
    expect(mockPrefs.getString('nh_opt_symset'), 'Enhanced1');
  });
}
