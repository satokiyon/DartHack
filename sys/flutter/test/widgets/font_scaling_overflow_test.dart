import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/settings_page.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/widgets/exit_highlight_dialog.dart';
import 'package:darthack/widgets/overlays/menu_overlay.dart';
import 'package:darthack/widgets/overlays/text_overlay.dart';

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
    tempDir = await Directory.systemTemp.createTemp('font_scaling_overflow_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString('OPTIONS=symset:IBMGraphics_2,runmode:walk\n');

    mockPrefs = await AppPrefs.setMockInitialValues({
      FontManager.prefMenuFontSize: 32.0,
      FontManager.prefUiFontScale: 2.5,
      FontManager.prefMsgFontSize: 32.0,
      FontManager.prefStatusFontSize: 32.0,
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

  Widget wrapWithUiScale(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      builder: (context, appChild) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(FontManager.instance.uiFontScale),
          ),
          child: appChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(body: child),
    );
  }

  testWidgets('最大サイズ (uiFontScale=2.5, menuFontSize=32pt) で SettingsPage がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapWithUiScale(
        SettingsPage(
          defaultsFilePath: defaultsFile.path,
          dataDirString: tempDir.path,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final fontSectionTitle = find.text('フォント設定');
    await tester.scrollUntilVisible(fontSectionTitle, 200);
    await tester.ensureVisible(fontSectionTitle);
    await tester.tap(fontSectionTitle);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('最大サイズ (uiFontScale=2.0, menuFontSize=32pt) で MenuOverlay がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = [
      MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 1, text: '武器', preselected: 0, color: 0, tile: -1),
      MenuItemData(ident: 1, accelerator: 97, groupacc: 0, attr: 0, text: 'a - +1 ロングソード (装備中)', preselected: 0, color: 7, tile: -1),
    ];

    await tester.pumpWidget(
      wrapWithUiScale(
        Stack(
          children: [
            MenuOverlay(
              menuPrompt: '所持品',
              menuItems: items,
              menuHow: 0,
              initialSelectedCounts: const {},
              initialSearchQuery: '',
              bottomInset: 0.0,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
              onSingleSelect: (_) {},
              onMultiSelect: (_) {},
              onItemLongPress: (_) {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('最大サイズ (uiFontScale=2.0, menuFontSize=32pt) で TextOverlay がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapWithUiScale(
        Stack(
          children: [
            TextOverlay(
              textLines: const [
                'ヘルプメッセージのサンプル行です。',
                '長めのテキストが折り返されてもレイアウトが崩れないことを確認します。',
              ],
              textAttrs: const [0, 0],
              textTiles: const [-1, -1],
              isPlainDialog: true,
              bottomInset: 0.0,
              windowRevision: 1,
              tombstoneDisplayMode: 0,
              usePhysicalKeyboardNotation: false,
              useTiles: false,
              tileImage: null,
              tileWidth: 32,
              tileHeight: 32,
              onDismiss: () {},
              onShowMsgHistory: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('最大サイズ (uiFontScale=2.0, menuFontSize=32pt) で ExitHighlightDialog がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapWithUiScale(
        const ExitHighlightDialog(
          dialogMessage: '本当に終了しますか？',
          messageHistory: ['スライムを倒した。', 'レベルが上がった！'],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });
}
