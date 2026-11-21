import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/settings_page.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/permanent_inventory_panel.dart';

void main() {
  group('NetHackScreen permInvent snapshot parsing', () {
    test('スナップショットをパースし、マップの ChangeNotifier を発火させない', () {
      final screen = NetHackScreen();
      int mapNotifyCount = 0;
      screen.addListener(() => mapNotifyCount++);

      const payload = '0\x1F0\x1F0\x1F1\x1F7\x1F-1\x1F武器\x1E'
          '101\x1F97\x1F41\x1F0\x1F15\x1F12\x1F祝福された+2ロングソード（装備中）\x1E';
      screen.applyPermInventSnapshot(payload);

      expect(mapNotifyCount, 0);
      expect(screen.permInventState.enabledByCore, isTrue);
      expect(screen.permInventState.items.length, 2);
      expect(screen.permInventState.items[0].text, '武器');
      expect(screen.permInventState.items[0].accelerator, 0);
      expect(screen.permInventState.items[1].accelerator, 97); // 'a'
      expect(screen.permInventState.items[1].tile, 12);
      expect(screen.permInventState.items[1].text, '祝福された+2ロングソード（装備中）');

      screen.clearPermInvent();
      expect(mapNotifyCount, 0);
      expect(screen.permInventState.enabledByCore, isFalse);
      expect(screen.permInventState.items, isEmpty);
    });
  });

  group('PermanentInventoryPanel widget', () {
    Widget wrapPanel({
      required ValueNotifier<PermInventState> notifier,
      required ScrollController scrollController,
      bool isScrollMode = false,
      bool canTapItem = true,
      ValueChanged<MenuItemData>? onItemTap,
    }) {
      return MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 220,
            child: PermanentInventoryPanel(
              permInventNotifier: notifier,
              scrollController: scrollController,
              width: 240,
              isLeftSide: false,
              isScrollMode: isScrollMode,
              canTapItem: canTapItem,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
              onItemTap: onItemTap,
            ),
          ),
        ),
      );
    }

    testWidgets('見出し・アイテム表示、通常待機中のタップ、プロンプト中のタップ無効を検証', (tester) async {
      final notifier = ValueNotifier<PermInventState>(
        PermInventState(
          enabledByCore: true,
          items: [
            MenuItemData(
              ident: 0,
              accelerator: 0,
              groupacc: 0,
              attr: 1,
              text: '武器',
              preselected: 0,
              color: 7,
              tile: -1,
            ),
            MenuItemData(
              ident: 1,
              accelerator: 97, // 'a'
              groupacc: 41,
              attr: 0,
              text: 'とても長い名前の祝福された+2エクスカリバー（右手に装備中）',
              preselected: 0,
              color: 15,
              tile: -1,
            ),
          ],
          revision: 1,
        ),
      );
      final sc = ScrollController();
      addTearDown(() {
        notifier.dispose();
        sc.dispose();
      });

      MenuItemData? tapped;
      await tester.pumpWidget(
        wrapPanel(
          notifier: notifier,
          scrollController: sc,
          canTapItem: true,
          onItemTap: (item) => tapped = item,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('持ち物'), findsOneWidget);
      expect(find.text('武器'), findsOneWidget);
      expect(find.text('a - '), findsOneWidget);
      expect(find.text('とても長い名前の祝福された+2エクスカリバー（右手に装備中）'), findsOneWidget);

      await tester.tap(find.text('とても長い名前の祝福された+2エクスカリバー（右手に装備中）'));
      await tester.pump();
      expect(tapped?.accelerator, 97);

      // プロンプト中 (canTapItem: false) はタップ無効
      tapped = null;
      await tester.pumpWidget(
        wrapPanel(
          notifier: notifier,
          scrollController: sc,
          canTapItem: false,
          onItemTap: (item) => tapped = item,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('とても長い名前の祝福された+2エクスカリバー（右手に装備中）'));
      await tester.pump();
      expect(tapped, isNull);
    });

    testWidgets('スクロールモード時は操作ヒントを表示し、空状態では空メッセージを表示', (tester) async {
      final notifier = ValueNotifier<PermInventState>(
        const PermInventState(enabledByCore: true, items: [], revision: 1),
      );
      final sc = ScrollController();
      addTearDown(() {
        notifier.dispose();
        sc.dispose();
      });

      await tester.pumpWidget(
        wrapPanel(
          notifier: notifier,
          scrollController: sc,
          isScrollMode: true,
          canTapItem: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('操作中'), findsOneWidget);
      expect(find.text('何も持っていない'), findsOneWidget);
    });
  });

  group('SettingsPage 画面表示設定末尾の perm_invent 設定', () {
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
      FontManager.resetForTesting();

      tempDir = await Directory.systemTemp.createTemp('darthack_perminv_settings_');
      defaultsFile = File('${tempDir.path}${Platform.pathSeparator}defaults.nh');
      await defaultsFile.writeAsString('OPTIONS=autopickup\n');

      final mockPrefs = await AppPrefs.setMockInitialValues({
        'nh_opt_perm_invent': false,
        'perm_invent_position': 'right',
        'perm_invent_width_ratio': 0.28,
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

    testWidgets('画面表示設定に perm_invent・配置・幅スライダーが存在し ON/OFF で保存される', (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsPage(
              defaultsFilePath: defaultsFile.path,
              dataDirString: tempDir.path,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 「画面表示設定」を展開
      final screenSec = find.text('画面表示設定');
      await tester.scrollUntilVisible(screenSec, 200);
      await tester.ensureVisible(screenSec);
      await tester.tap(screenSec);
      await tester.pumpAndSettle();

      final permSwitch = find.text('常時表示インベントリ (perm_invent)');
      await tester.scrollUntilVisible(permSwitch, 200);
      await tester.ensureVisible(permSwitch);
      await tester.pumpAndSettle();
      expect(permSwitch, findsOneWidget);
      expect(find.text('常時表示インベントリの配置'), findsOneWidget);
      expect(find.text('常時表示インベントリの幅'), findsOneWidget);

      await tester.tap(permSwitch);
      await tester.pumpAndSettle();
      final prefs = await AppPrefs.getInstance();
      expect(prefs.getBool('nh_opt_perm_invent'), isTrue);

      String savedDefaults = '';
      for (int i = 0; i < 12; i++) {
        savedDefaults = await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return defaultsFile.readAsString();
        }) ?? '';
        await tester.pump();
        if (savedDefaults.contains('perm_invent')) break;
      }
      expect(savedDefaults.contains('perm_invent'), isTrue);
    });
  });

  group('buildGameSplitLayout & 独自フォント設定', () {
    late Directory tempDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      FontManager.resetForTesting();
      tempDir = await Directory.systemTemp.createTemp('perminv_font_test_');
      final mockPrefs = await AppPrefs.setMockInitialValues({});
      await FontManager.instance.init(prefs: mockPrefs, customFontsDir: tempDir);
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('上ステータス＋右インベントリ時、インベントリが全高でステータスはマップ幅に収まる', (tester) async {
      const screenSize = Size(800, 600);
      const statusKey = Key('status_top');
      const mapKey = Key('map_area');
      const invKey = Key('perm_inv');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: buildGameSplitLayout(
                statusPosition: 'top',
                mapWidget: const SizedBox.expand(key: mapKey),
                horizontalStatusWidget: const SizedBox(
                  key: statusKey,
                  width: double.infinity,
                  height: 48,
                ),
                buildVerticalStatusPanel: (_) => const SizedBox(width: 70),
                showPermInvent: true,
                permInventPosition: 'right',
                permInventWidget: const SizedBox(
                  key: invKey,
                  width: 280,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ),
      );

      final invRect = tester.getRect(find.byKey(invKey));
      final statusRect = tester.getRect(find.byKey(statusKey));
      final mapRect = tester.getRect(find.byKey(mapKey));

      expect(invRect.top, 0.0);
      expect(invRect.bottom, screenSize.height);
      expect(invRect.right, screenSize.width);
      expect(statusRect.right, lessThanOrEqualTo(invRect.left));
      expect(statusRect.width, closeTo(mapRect.width, 0.5));
      expect(mapRect.top, closeTo(statusRect.bottom, 0.5));
    });

    testWidgets('下ステータス＋左インベントリ時、インベントリが全高でステータスは右側メイン幅に収まる', (tester) async {
      const screenSize = Size(800, 600);
      const statusKey = Key('status_bottom');
      const mapKey = Key('map_area');
      const invKey = Key('perm_inv');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: buildGameSplitLayout(
                statusPosition: 'bottom',
                mapWidget: const SizedBox.expand(key: mapKey),
                horizontalStatusWidget: const SizedBox(
                  key: statusKey,
                  width: double.infinity,
                  height: 48,
                ),
                buildVerticalStatusPanel: (_) => const SizedBox(width: 70),
                showPermInvent: true,
                permInventPosition: 'left',
                permInventWidget: const SizedBox(
                  key: invKey,
                  width: 280,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ),
      );

      final invRect = tester.getRect(find.byKey(invKey));
      final statusRect = tester.getRect(find.byKey(statusKey));
      final mapRect = tester.getRect(find.byKey(mapKey));

      expect(invRect.top, 0.0);
      expect(invRect.bottom, screenSize.height);
      expect(invRect.left, 0.0);
      expect(statusRect.left, greaterThanOrEqualTo(invRect.right));
      expect(statusRect.bottom, screenSize.height);
      expect(statusRect.width, closeTo(mapRect.width, 0.5));
    });

    testWidgets('右ステータス＋右インベントリ時、[マップ | 縦ステータス | インベントリ] の順に並ぶ', (tester) async {
      const screenSize = Size(800, 600);
      const statusKey = Key('status_right');
      const mapKey = Key('map_area');
      const invKey = Key('perm_inv');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: buildGameSplitLayout(
                statusPosition: 'right',
                mapWidget: const SizedBox.expand(key: mapKey),
                horizontalStatusWidget: const SizedBox(height: 48),
                buildVerticalStatusPanel: (_) => const SizedBox(
                  key: statusKey,
                  width: 70,
                  height: double.infinity,
                ),
                showPermInvent: true,
                permInventPosition: 'right',
                permInventWidget: const SizedBox(
                  key: invKey,
                  width: 280,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ),
      );

      final mapRect = tester.getRect(find.byKey(mapKey));
      final statusRect = tester.getRect(find.byKey(statusKey));
      final invRect = tester.getRect(find.byKey(invKey));

      expect(invRect.top, 0.0);
      expect(invRect.bottom, screenSize.height);
      expect(invRect.right, screenSize.width);
      expect(mapRect.right, closeTo(statusRect.left, 0.5));
      expect(statusRect.right, closeTo(invRect.left, 0.5));
    });

    testWidgets('FontManager の permInvent 専用フォント・サイズが即時反映される', (tester) async {
      final notifier = ValueNotifier<PermInventState>(
        PermInventState(
          enabledByCore: true,
          items: [
            MenuItemData(
              ident: 1,
              accelerator: 97,
              groupacc: 0,
              attr: 0,
              color: 7,
              preselected: 0,
              tile: -1,
              text: '+1 ロングソード (装備中)',
            ),
          ],
        ),
      );
      final scrollController = ScrollController();
      addTearDown(() {
        notifier.dispose();
        scrollController.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PermanentInventoryPanel(
              permInventNotifier: notifier,
              scrollController: scrollController,
              width: 280,
              isLeftSide: false,
              isScrollMode: false,
              canTapItem: true,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
            ),
          ),
        ),
      );

      Text itemText = tester.widget<Text>(find.text('+1 ロングソード (装備中)'));
      expect(itemText.style?.fontSize, 13.0);

      // メニュー設定を変更しても常時表示インベントリには影響しないこと
      await tester.runAsync(() async {
        await FontManager.instance.setMenuFontSize(22.0);
        await FontManager.instance.setFont(FontTarget.menu, 'Unscii-8');
      });
      await tester.pump();

      itemText = tester.widget<Text>(find.text('+1 ロングソード (装備中)'));
      expect(itemText.style?.fontSize, 13.0);

      // permInvent 専用設定を変更すると即時反映されること
      await tester.runAsync(() async {
        await FontManager.instance.setPermInventFontSize(17.0);
        await FontManager.instance.setFont(FontTarget.permInvent, 'MisakiGothic');
      });
      await tester.pump();

      itemText = tester.widget<Text>(find.text('+1 ロングソード (装備中)'));
      expect(itemText.style?.fontSize, 17.0);
      expect(itemText.style?.fontFamily, 'MisakiGothic');
    });
  });
}
