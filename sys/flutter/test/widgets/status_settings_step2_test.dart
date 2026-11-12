import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/main.dart' show parseStatusLine, StatusBarInteractiveView;
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
    tempDir = await Directory.systemTemp.createTemp('status_settings_step2_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString(
      'OPTIONS=time,showexp,hitpointbar,statuslines:2\n'
      'OPTIONS=hilite_status:hitpoints/100%/white&bold\n',
    );

    mockPrefs = await AppPrefs.setMockInitialValues({
      'status_font_size': 13.0,
      'status_line_layout': 'standard',
      'nh_opt_statuslines': 2,
      'nh_opt_hitpointbar': true,
      'nh_opt_hilite_status': true,
      'nh_opt_time': true,
      'nh_opt_showexp': true,
      'nh_opt_weaponstatus': false,
      'nh_opt_armorstatus': false,
      'nh_opt_terrainstatus': false,
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

  Future<String> waitForDefaultsContains(WidgetTester tester, String needle) async {
    String content = '';
    for (int i = 0; i < 25; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        content = await defaultsFile.readAsString();
      });
      await tester.pump();
      if (content.contains(needle)) return content;
    }
    return content;
  }

  testWidgets('ステップ2: 4択ステータス行数レイアウト切替とプレビュー・AppPrefs・defaults.nh同期が機能すること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final statusSectionTitle = find.text('ステータス領域設定');
    await tester.scrollUntilVisible(statusSectionTitle, 200);
    await tester.ensureVisible(statusSectionTitle);
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    // 追加されたUI項目が表示されていること
    expect(find.text('ステータス行数・構成'), findsOneWidget);
    expect(find.text('装備武器表示 (weaponstatus)'), findsOneWidget);
    expect(find.text('装備防具表示 (armorstatus)'), findsOneWidget);
    expect(find.text('足元地形表示 (terrainstatus)'), findsOneWidget);

    // 初期状態（2行標準）では実出力準拠（階層:1・$:50・主人公 若き盾乙女・空腹・盲目）が表示されること
    expect(find.textContaining('Dlvl:1 HP:12/16', findRichText: true), findsNothing);
    expect(find.textContaining('迷宮:1', findRichText: true), findsNothing);
    expect(find.textContaining('金貨:50', findRichText: true), findsNothing);
    expect(find.textContaining('主人公 若き盾乙女', findRichText: true), findsWidgets);
    expect(find.textContaining('階層:1', findRichText: true), findsWidgets);
    expect(find.textContaining(r'$:50', findRichText: true), findsWidgets);
    expect(find.textContaining('空腹', findRichText: true), findsWidgets);
    expect(find.textContaining('盲目', findRichText: true), findsWidgets);

    // ドロップダウンを開いて「1行（超コンパクト）」へ切替
    final layoutDropdown = find.text('2行（標準）');
    await tester.ensureVisible(layoutDropdown);
    await tester.tap(layoutDropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('1行（超コンパクト）').last);
    await tester.pumpAndSettle();

    expect(mockPrefs.getString('status_line_layout'), equals('single_compact'));
    // defaults.nh 側は C コア互換のため 2 を維持すること
    expect(mockPrefs.getInt('nh_opt_statuslines'), equals(2));
    // プレビューが NetHack 準拠の超コンパクト 1 行（Dlvl:1 HP:12/16 Pw:5/5 AC:6 Xp:2 空腹 盲目）になること
    expect(find.textContaining('Dlvl:1 ', findRichText: true), findsWidgets);
    expect(find.textContaining('HP:12/16', findRichText: true), findsWidgets);
    expect(find.textContaining('Pw:5/5', findRichText: true), findsWidgets);
    expect(find.textContaining('Xp:2', findRichText: true), findsWidgets);
    expect(find.textContaining('空腹', findRichText: true), findsWidgets);
    expect(find.textContaining('盲目', findRichText: true), findsWidgets);
    expect(find.textContaining('MP:5/5', findRichText: true), findsNothing);
    expect(find.textContaining('Lv:2', findRichText: true), findsNothing);

    // ドロップダウンを開いて「3行（拡張）」へ切替
    await tester.tap(find.text('1行（超コンパクト）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3行（拡張）').last);
    await tester.pumpAndSettle();

    expect(mockPrefs.getString('status_line_layout'), equals('standard'));
    expect(mockPrefs.getInt('nh_opt_statuslines'), equals(3));

    expect(await waitForDefaultsContains(tester, 'statuslines:3'), contains('statuslines:3'));
    // 3行プレビューで2行目に空腹、3行目に階層:1と盲目が分かれて表示されること
    expect(find.textContaining('属性:秩序 \$:50', findRichText: true), findsWidgets);
    expect(find.textContaining('レベル:2/42 空腹', findRichText: true), findsWidgets);
    expect(find.textContaining('階層:1 ターン:120 盲目', findRichText: true), findsWidgets);

    // ドロップダウンを開いて「1行（全項目を1行表示）」へ切替 -> defaults.nh は statuslines:2 に戻る
    await tester.tap(find.text('3行（拡張）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1行（全項目を1行表示）').last);
    await tester.pumpAndSettle();

    expect(mockPrefs.getString('status_line_layout'), equals('single_all'));
    expect(mockPrefs.getInt('nh_opt_statuslines'), equals(2));
    expect(await waitForDefaultsContains(tester, 'statuslines:2'), contains('statuslines:2'));
    expect(find.textContaining('階層:1 \$:50', findRichText: true), findsWidgets);
    expect(find.textContaining('ターン:120 空腹 盲目', findRichText: true), findsWidgets);
    expect(find.textContaining('迷宮:1', findRichText: true), findsNothing);
    expect(find.textContaining('金貨:50', findRichText: true), findsNothing);
  });

  testWidgets('ステップ2: 装備・地形トグルの切替で AppPrefs・defaults.nh・プレビューが更新されること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final statusSectionTitle = find.text('ステータス領域設定');
    await tester.scrollUntilVisible(statusSectionTitle, 200);
    await tester.ensureVisible(statusSectionTitle);
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    Future<void> toggleSwitch(String label) async {
      final sw = find.widgetWithText(SwitchListTile, label);
      await tester.scrollUntilVisible(sw, 200);
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pumpAndSettle();
    }

    await toggleSwitch('装備武器表示 (weaponstatus)');
    await toggleSwitch('装備防具表示 (armorstatus)');
    await toggleSwitch('足元地形表示 (terrainstatus)');

    expect(mockPrefs.getBool('nh_opt_weaponstatus'), isTrue);
    expect(mockPrefs.getBool('nh_opt_armorstatus'), isTrue);
    expect(mockPrefs.getBool('nh_opt_terrainstatus'), isTrue);

    final content = await waitForDefaultsContains(tester, 'terrainstatus');
    expect(content, contains('weaponstatus'));
    expect(content, contains('armorstatus'));
    expect(content, contains('terrainstatus'));

    // プレビューに武器・防具・地形のサンプルが表示されること
    expect(find.textContaining('武器:剣', findRichText: true), findsWidgets);
    expect(find.textContaining('防具:GCA+', findRichText: true), findsWidgets);
    expect(find.textContaining('地形:床', findRichText: true), findsWidgets);
  });

  testWidgets('ステップ2: ステータス領域の武器タップ・他領域タップ・長押しが競合せず意図通りに発火すること', (tester) async {
    int attributesCount = 0;
    int seeallCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            key: const Key('status_outer_gesture'),
            behavior: HitTestBehavior.opaque,
            onTap: () => attributesCount++,
            onLongPress: () => seeallCount++,
            child: Container(
              width: 600,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: Text.rich(
                parseStatusLine(
                  r'Dlvl:1 \Lequipment:武器:ロングソード\l 地形:床',
                  onEquipmentTap: () => seeallCount++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. 武器リンクをタップ -> #seeall 側だけが呼ばれ、外側の #attributes は呼ばれないこと
    await tester.tap(find.text('武器:ロングソード', findRichText: true));
    await tester.pumpAndSettle();
    expect(seeallCount, equals(1));
    expect(attributesCount, equals(0));

    // 2. 地形テキスト部分をタップ -> 外側の #attributes が呼ばれること
    final outerRect = tester.getRect(find.byKey(const Key('status_outer_gesture')));
    await tester.tapAt(Offset(outerRect.right - 20, outerRect.center.dy));
    await tester.pumpAndSettle();
    expect(attributesCount, equals(1));
    expect(seeallCount, equals(1));

    // 3. ステータス領域を長押し -> #seeall 側が呼ばれること
    await tester.longPressAt(Offset(outerRect.right - 20, outerRect.center.dy));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(seeallCount, equals(2));
  });

  testWidgets('ステップ2: 1行（超コンパクト）で非表示5トグルが半透明化・値維持され、1行（全項目）で推奨注記が表示されること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSettingsApp());
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final statusSectionTitle = find.text('ステータス領域設定');
    await tester.scrollUntilVisible(statusSectionTitle, 200);
    await tester.ensureVisible(statusSectionTitle);
    await tester.tap(statusSectionTitle);
    await tester.pumpAndSettle();

    // 「1行（超コンパクト）」へ切替
    final layoutDropdown = find.text('2行（標準）');
    await tester.ensureVisible(layoutDropdown);
    await tester.tap(layoutDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1行（超コンパクト）').last);
    await tester.pumpAndSettle();

    const compactHint = '※「1行（超コンパクト）」選択中は表示されません';
    expect(find.text(compactHint), findsNWidgets(5));

    const hiddenLabels = [
      '経過ターン表示 (time)',
      '経験値表示 (showexp)',
      '装備武器表示 (weaponstatus)',
      '装備防具表示 (armorstatus)',
      '足元地形表示 (terrainstatus)',
    ];

    for (final label in hiddenLabels) {
      final switchTile = find.widgetWithText(SwitchListTile, label);
      await tester.scrollUntilVisible(switchTile, 200);
      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: switchTile, matching: find.byType(Opacity)).first,
      );
      expect(opacityWidget.opacity, closeTo(0.52, 0.001));
    }

    // 半透明表示中の 経過ターン表示(time) / 装備武器表示(weaponstatus) を上から順にタップしても操作・値保存が有効なこと
    final timeSwitch = find.widgetWithText(SwitchListTile, '経過ターン表示 (time)');
    await tester.ensureVisible(timeSwitch);
    await tester.tap(timeSwitch);
    await tester.pumpAndSettle();
    expect(mockPrefs.getBool('nh_opt_time'), isFalse);

    final weaponSwitch = find.widgetWithText(SwitchListTile, '装備武器表示 (weaponstatus)');
    await tester.scrollUntilVisible(weaponSwitch, 200);
    await tester.ensureVisible(weaponSwitch);
    await tester.tap(weaponSwitch);
    await tester.pumpAndSettle();
    expect(mockPrefs.getBool('nh_opt_weaponstatus'), isTrue);

    // 上方向へ十分スクロールして「1行（全項目を1行表示）」へ切替 -> 推奨注記が表示され、半透明注記が消えること
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    final compactDropdown = find.text('1行（超コンパクト）');
    await tester.tap(compactDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1行（全項目を1行表示）').last);
    await tester.pumpAndSettle();

    expect(
      find.text('※「1行（全項目を1行表示）」は項目が多いため、「可変高さ」表示または横長画面での利用を推奨します'),
      findsOneWidget,
    );
    expect(find.text(compactHint), findsNothing);
    // 非表示中に変更した値が維持されていること
    expect(mockPrefs.getBool('nh_opt_weaponstatus'), isTrue);
    expect(mockPrefs.getBool('nh_opt_time'), isFalse);
  });

  testWidgets('ステップ2: JSON設定インポート時に defaults.nh へ statuslines と装備・地形オプションが同期されること', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clipboardJson = jsonEncode({
      'nh_opt_statuslines': 3,
      'nh_opt_weaponstatus': true,
      'nh_opt_armorstatus': true,
      'nh_opt_terrainstatus': true,
      'status_line_layout': 'standard',
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': clipboardJson};
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(createSettingsApp());
    for (int i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final advancedSection = find.text('高度な設定');
    await tester.scrollUntilVisible(advancedSection, 300);
    await tester.ensureVisible(advancedSection);
    await tester.tap(advancedSection);
    await tester.pumpAndSettle();

    final importBtn = find.text('設定をインポート');
    await tester.scrollUntilVisible(importBtn, 300);
    await tester.ensureVisible(importBtn);
    await tester.tap(importBtn);
    await tester.pumpAndSettle();

    final synced = await waitForDefaultsContains(tester, 'statuslines:3');
    expect(synced, contains('statuslines:3'));
    expect(synced, contains('OPTIONS=weaponstatus'));
    expect(synced, contains('OPTIONS=armorstatus'));
    expect(synced, contains('OPTIONS=terrainstatus'));
  });

  testWidgets('ステップ2: StatusBarInteractiveView が狭幅 FittedBox 縮小下でも装備タップ・通常タップ・長押し・無効状態を正しく処理すること', (tester) async {
    int statusTapCount = 0;
    int equipmentTapCount = 0;

    Widget buildView({
      required int displayMode,
      VoidCallback? onStatusTap,
      VoidCallback? onEquipmentTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 180,
              child: StatusBarInteractiveView(
                statusLines: const [
                  r'\Lequipment:\C0000000B武器:ロングソード(+1)\c\l      \C0000000A地形:床\c',
                ],
                statusDisplayMode: displayMode,
                statusFontSize: 16.0,
                onStatusTap: onStatusTap,
                onEquipmentTap: onEquipmentTap,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildView(
        displayMode: 0,
        onStatusTap: () => statusTapCount++,
        onEquipmentTap: () => equipmentTapCount++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FittedBox), findsOneWidget);
    final viewRect = tester.getRect(find.byType(StatusBarInteractiveView));

    // 左端付近（装備リンク上）をタップ -> onEquipmentTap のみ発火
    await tester.tapAt(Offset(viewRect.left + 20, viewRect.center.dy));
    await tester.pumpAndSettle();
    expect(equipmentTapCount, equals(1));
    expect(statusTapCount, equals(0));

    // 右端付近（非リンクの地形側）をタップ -> onStatusTap のみ発火
    await tester.tapAt(Offset(viewRect.right - 15, viewRect.center.dy));
    await tester.pumpAndSettle();
    expect(statusTapCount, equals(1));
    expect(equipmentTapCount, equals(1));

    // ステータス領域を長押し -> onEquipmentTap が発火
    await tester.longPressAt(Offset(viewRect.right - 15, viewRect.center.dy));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(equipmentTapCount, equals(2));

    // コールバック無効時はタップしても例外やカウント増加が起きないこと
    await tester.pumpWidget(
      buildView(
        displayMode: 1,
        onStatusTap: null,
        onEquipmentTap: null,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FittedBox), findsNothing);
    await tester.tapAt(Offset(viewRect.left + 20, viewRect.center.dy));
    await tester.pumpAndSettle();
    expect(statusTapCount, equals(1));
    expect(equipmentTapCount, equals(2));
  });

  group('SettingsPage ステータス領域プレビュー 実ゲーム準拠描画', () {
    const clrGreen = Color(0xFF38D9A9);
    const clrNoColor = Color(0xFFECEFF1);
    const clrOrange = Color(0xFFFFA726);
    const clrBrightGreen = Color(0xFF69F0AE);
    const clrYellow = Color(0xFFFFEE58);

    late Directory previewTempDir;
    late File previewDefaultsFile;

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
      previewTempDir =
          await Directory.systemTemp.createTemp('status_preview_hitpoint_');
      previewDefaultsFile = File('${previewTempDir.path}/defaults.nh');
      await previewDefaultsFile.writeAsString(
        'OPTIONS=symset:IBMGraphics_2\n'
        'OPTIONS=hilite_status:hitpoints/<100%/brightgreen\n',
      );
    });

    tearDown(() async {
      try {
        if (await previewTempDir.exists()) {
          await previewTempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    Future<void> pumpPreviewSection(
      WidgetTester tester, {
      required Locale locale,
      required Map<String, Object> prefsValues,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await AppPrefs.setMockInitialValues(prefsValues);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsPage(
              key: UniqueKey(),
              defaultsFilePath: previewDefaultsFile.path,
              dataDirString: previewTempDir.path,
            ),
          ),
        ),
      );
      // _loadAllSettings() は File.exists() / readAsLines() 等の実 I/O と FakeAsync マイクロタスクを
      // 交互に経由するため、runAsync + pump を数回回して確実に設定ロード完了まで進める
      for (int i = 0; i < 6; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final sectionTitle =
          locale.languageCode == 'en' ? 'Status Area Settings' : 'ステータス領域設定';
      final sectionTile = find.widgetWithText(ExpansionTile, sectionTitle);
      expect(sectionTile, findsOneWidget);
      await tester.ensureVisible(sectionTile);
      await tester.tap(sectionTile);
      await tester.pumpAndSettle();
    }

    void expectPreviewHpBar(
      WidgetTester tester, {
      required String expectedText,
      required Color expectedBarColor,
    }) {
      final previewView = find.byType(StatusBarInteractiveView);
      expect(previewView, findsOneWidget);

      final clipperFinder = find.descendant(
        of: previewView,
        matching: find.byWidgetPredicate(
          (w) =>
              w is ClipRect &&
              w.clipper?.runtimeType.toString() == 'HpBarClipper',
        ),
      );
      expect(clipperFinder, findsOneWidget);

      final clipRect = tester.widget<ClipRect>(clipperFinder);
      expect(
        clipRect.clipper!.getClip(const Size(100, 20)),
        equals(const Rect.fromLTWH(0, 0, 75, 20)),
      );

      final stackFinder = find.ancestor(
        of: clipperFinder,
        matching: find.byType(Stack),
      ).first;
      final stack = tester.widget<Stack>(stackFinder);
      expect(stack.children.length, equals(2));

      // ベース層: 黒背景 + 太字白文字
      final baseContainer = stack.children[0] as Container;
      expect(baseContainer.color, equals(Colors.black));
      final baseText = baseContainer.child as Text;
      expect(baseText.data, equals(expectedText));
      expect(baseText.style?.color, equals(Colors.white));
      expect(baseText.style?.fontWeight, equals(FontWeight.bold));

      // クリップ層: バー色背景 + 太字黒文字
      final clipContainer = tester.widget<Container>(
        find.descendant(
          of: clipperFinder,
          matching: find.byType(Container),
        ),
      );
      expect(clipContainer.color, equals(expectedBarColor));
      final clipText = clipContainer.child as Text;
      expect(clipText.data, equals(expectedText));
      expect(clipText.style?.color, equals(Colors.black));
      expect(clipText.style?.fontWeight, equals(FontWeight.bold));
    }

    List<({String text, TextStyle? style})> collectRichSegments(
      WidgetTester tester,
      Finder root,
    ) {
      final segments = <({String text, TextStyle? style})>[];

      void visitSpan(InlineSpan span, TextStyle? inheritedStyle) {
        if (span is! TextSpan) return;
        final mergedStyle =
            inheritedStyle?.merge(span.style) ?? span.style;
        if (span.text != null && span.text!.isNotEmpty) {
          segments.add((text: span.text!, style: mergedStyle));
        }
        if (span.children != null) {
          for (final child in span.children!) {
            visitSpan(child, mergedStyle);
          }
        }
      }

      for (final richText
          in tester.widgetList<RichText>(
            find.descendant(of: root, matching: find.byType(RichText)),
          )) {
        visitSpan(richText.text, null);
      }
      return segments;
    }

    ({String text, TextStyle? style}) segmentExact(
      List<({String text, TextStyle? style})> segs,
      String text,
    ) {
      return segs.firstWhere(
        (s) => s.text == text,
        orElse: () => fail('Expected segment "$text" in $segs'),
      );
    }

    ({String text, TextStyle? style}) segmentContaining(
      List<({String text, TextStyle? style})> segs,
      String substr,
    ) {
      return segs.firstWhere(
        (s) => s.text.contains(substr),
        orElse: () => fail('Expected segment containing "$substr" in $segs'),
      );
    }

    testWidgets(
      '日本語プレビューでhitpointbar ON時の2層HPバーとパレット色が一致し、hilite_status OFF切替に連動すること',
      (tester) async {
        await pumpPreviewSection(
          tester,
          locale: const Locale('ja'),
          prefsValues: {
            'selected_language': 'ja',
            'status_line_layout': 'standard',
            'nh_opt_statuslines': 2,
            'nh_opt_hitpointbar': true,
            'nh_opt_hilite_status': true,
            'nh_opt_time': true,
            'nh_opt_showexp': true,
            'nh_opt_weaponstatus': true,
            'nh_opt_armorstatus': true,
            'nh_opt_terrainstatus': true,
          },
        );

        expectPreviewHpBar(
          tester,
          expectedText: '主人公 若き盾乙女',
          expectedBarColor: clrBrightGreen,
        );

        final previewView = find.byType(StatusBarInteractiveView);
        final segsOn = collectRichSegments(tester, previewView);
        expect(segmentExact(segsOn, '体力:12(16)').style?.color, equals(clrBrightGreen));
        expect(segmentExact(segsOn, 'レベル:2').style?.color, equals(clrGreen));
        expect(segmentContaining(segsOn, '/42').style?.color, equals(Colors.white));
        expect(segmentExact(segsOn, '空腹').style?.color, equals(clrOrange));
        final blindSegOn = segmentExact(segsOn, '盲目');
        expect(blindSegOn.style?.color, equals(clrYellow));
        expect(blindSegOn.style?.fontWeight, isNot(FontWeight.bold));

        final weaponSegOn = segmentExact(segsOn, '武器:剣');
        expect(weaponSegOn.style?.color, equals(Colors.white));
        expect(weaponSegOn.style?.decoration, equals(TextDecoration.underline));
        expect(weaponSegOn.style?.decorationStyle, equals(TextDecorationStyle.dotted));

        final armorSegOn = segmentExact(segsOn, '防具:GCA+');
        expect(armorSegOn.style?.color, equals(Colors.white));
        expect(armorSegOn.style?.decoration, equals(TextDecoration.underline));
        expect(armorSegOn.style?.decorationStyle, equals(TextDecorationStyle.dotted));

        expect(segmentContaining(segsOn, '地形:床').style?.color, equals(Colors.white));

        // ステータス強調 (hilite_status) を OFF に切り替える
        final hiliteSwitch = find.widgetWithText(
          SwitchListTile,
          'ステータス強調 (hilite_status)',
        );
        expect(hiliteSwitch, findsOneWidget);
        await tester.ensureVisible(hiliteSwitch);
        await tester.tap(hiliteSwitch);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();

        expectPreviewHpBar(
          tester,
          expectedText: '主人公 若き盾乙女',
          expectedBarColor: clrNoColor,
        );
        final segsOff = collectRichSegments(tester, previewView);
        expect(segmentContaining(segsOff, '体力:12(16)').style?.color, equals(Colors.white));
        expect(segmentContaining(segsOff, 'レベル:2/42').style?.color, equals(Colors.white));
        expect(segmentContaining(segsOff, '空腹').style?.color, equals(Colors.white));
        expect(segmentContaining(segsOff, '盲目').style?.color, equals(Colors.white));
        expect(segmentExact(segsOff, '武器:剣').style?.color, equals(Colors.white));
        expect(segmentExact(segsOff, '防具:GCA+').style?.color, equals(Colors.white));
        expect(segmentContaining(segsOff, '地形:床').style?.color, equals(Colors.white));
      },
    );

    testWidgets(
      '全レイアウト(1行超コンパクト/1行全項目/3行拡張)および英語版で2層HPバーが描画されること',
      (tester) async {
        // 1行（超コンパクト）
        await pumpPreviewSection(
          tester,
          locale: const Locale('ja'),
          prefsValues: {
            'selected_language': 'ja',
            'status_line_layout': 'single_compact',
            'nh_opt_statuslines': 2,
            'nh_opt_hitpointbar': true,
            'nh_opt_hilite_status': true,
          },
        );
        expectPreviewHpBar(
          tester,
          expectedText: 'HP:12/16',
          expectedBarColor: clrBrightGreen,
        );
        final compactSegs = collectRichSegments(
          tester,
          find.byType(StatusBarInteractiveView),
        );
        expect(segmentExact(compactSegs, 'Xp:2').style?.color, equals(clrGreen));
        expect(segmentExact(compactSegs, '空腹').style?.color, equals(clrOrange));
        final compactBlind = segmentExact(compactSegs, '盲目');
        expect(compactBlind.style?.color, equals(clrYellow));
        expect(compactBlind.style?.fontWeight, isNot(FontWeight.bold));

        // 1行（全項目）
        await pumpPreviewSection(
          tester,
          locale: const Locale('ja'),
          prefsValues: {
            'selected_language': 'ja',
            'status_line_layout': 'single_all',
            'nh_opt_statuslines': 2,
            'nh_opt_hitpointbar': true,
            'nh_opt_hilite_status': true,
          },
        );
        expectPreviewHpBar(
          tester,
          expectedText: '主人公 若き盾乙女',
          expectedBarColor: clrBrightGreen,
        );

        // 3行（拡張）
        await pumpPreviewSection(
          tester,
          locale: const Locale('ja'),
          prefsValues: {
            'selected_language': 'ja',
            'status_line_layout': 'standard',
            'nh_opt_statuslines': 3,
            'nh_opt_hitpointbar': true,
            'nh_opt_hilite_status': true,
          },
        );
        expectPreviewHpBar(
          tester,
          expectedText: '主人公 若き盾乙女',
          expectedBarColor: clrBrightGreen,
        );

        // 英語版（2行標準）
        await pumpPreviewSection(
          tester,
          locale: const Locale('en'),
          prefsValues: {
            'selected_language': 'en',
            'status_line_layout': 'standard',
            'nh_opt_statuslines': 2,
            'nh_opt_hitpointbar': true,
            'nh_opt_hilite_status': true,
            'nh_opt_time': true,
            'nh_opt_showexp': true,
            'nh_opt_weaponstatus': true,
            'nh_opt_armorstatus': true,
            'nh_opt_terrainstatus': true,
          },
        );
        expectPreviewHpBar(
          tester,
          expectedText: 'Hero the Stripling',
          expectedBarColor: clrBrightGreen,
        );
        final enSegs = collectRichSegments(
          tester,
          find.byType(StatusBarInteractiveView),
        );
        expect(segmentExact(enSegs, 'HP:12(16)').style?.color, equals(clrBrightGreen));
        expect(segmentExact(enSegs, 'Xp:2').style?.color, equals(clrGreen));
        expect(segmentContaining(enSegs, '/42').style?.color, equals(Colors.white));
        expect(segmentExact(enSegs, 'Hungry').style?.color, equals(clrOrange));
        final enBlind = segmentExact(enSegs, 'Blnd');
        expect(enBlind.style?.color, equals(clrYellow));
        expect(enBlind.style?.fontWeight, isNot(FontWeight.bold));
        expect(segmentExact(enSegs, 'Sword').style?.color, equals(Colors.white));
        expect(segmentExact(enSegs, 'GCA+').style?.color, equals(Colors.white));
        expect(segmentContaining(enSegs, 'Floor').style?.color, equals(Colors.white));
      },
    );
  });
}
