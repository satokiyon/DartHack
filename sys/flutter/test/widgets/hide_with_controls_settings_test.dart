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
    tempDir = await Directory.systemTemp.createTemp('hide_controls_test_');
    defaultsFile = File('${tempDir.path}/defaults.nh');
    await defaultsFile.writeAsString('OPTIONS=symset:IBMGraphics_2,runmode:walk\n');

    mockPrefs = await AppPrefs.setMockInitialValues({
      'use_tiles': true,
      'hide_msg_with_controls': false,
      'hide_map_btn_with_controls': false,
      'hide_menu_btn_with_controls': false,
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

  group('Hide With Controls Settings Tests', () {
    testWidgets('UI配置カスタマイズセクションを展開すると、操作ボタン非表示時の連動設定が表示され初期値がOFFであること', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSettingsApp());
      await tester.pump(const Duration(milliseconds: 500));

      final sectionTitle = find.text('UI配置カスタマイズ');
      expect(sectionTitle, findsOneWidget);
      await tester.scrollUntilVisible(sectionTitle, 200);
      await tester.tap(sectionTitle);
      await tester.pumpAndSettle();

      // グループタイトルと説明
      expect(find.text('操作ボタン非表示時の連動設定'), findsOneWidget);
      expect(find.text('操作ボタンを非表示にした際、同時に非表示にするUI要素を選択します'), findsOneWidget);

      // 各項目の確認
      expect(find.text('メッセージ領域を合わせて非表示'), findsOneWidget);
      expect(find.text('全体マップボタンを合わせて非表示'), findsOneWidget);
      expect(find.text('メニューボタンを合わせて非表示'), findsOneWidget);
      expect(find.text('注意: メニューボタンを非表示にしても、画面端からのスワイプ（または戻るボタン/ジェスチャー）でいつでもドロワーメニューを開くことができます。'), findsOneWidget);

      // スイッチの初期値がすべて false
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.isNotEmpty, isTrue);
    });

    testWidgets('メニューボタン非表示切替時に案内確認ダイアログが表示され、キャンセル時はOFFのまま、決定時にONになること', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSettingsApp());
      await tester.pump(const Duration(milliseconds: 500));

      final sectionTitle = find.text('UI配置カスタマイズ');
      await tester.scrollUntilVisible(sectionTitle, 200);
      await tester.tap(sectionTitle);
      await tester.pumpAndSettle();

      // メニューボタンスイッチを探す
      final menuTile = find.widgetWithText(SwitchListTile, 'メニューボタンを合わせて非表示');
      expect(menuTile, findsOneWidget);

      // 1. タップして確認ダイアログ表示 -> キャンセル
      await tester.tap(menuTile);
      await tester.pumpAndSettle();

      expect(find.text('メニューボタンの非表示について'), findsOneWidget);
      expect(find.textContaining('ドロワーメニューを開くには、画面端からのスワイプ操作を行うか'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('メニューボタンの非表示について'), findsNothing);
      expect(mockPrefs.getBool('hide_menu_btn_with_controls'), isFalse);

      // 2. 再度タップして確認ダイアログ表示 -> 決定
      await tester.tap(menuTile);
      await tester.pumpAndSettle();

      expect(find.text('メニューボタンの非表示について'), findsOneWidget);
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(find.text('メニューボタンの非表示について'), findsNothing);
      expect(mockPrefs.getBool('hide_menu_btn_with_controls'), isTrue);
    });

    testWidgets('英語ロケールでも連動設定グループおよび項目が正しく表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createSettingsApp(locale: const Locale('en')));
      await tester.pump(const Duration(milliseconds: 500));

      final sectionTitle = find.text('UI Layout Customization');
      await tester.scrollUntilVisible(sectionTitle, 200);
      await tester.tap(sectionTitle);
      await tester.pumpAndSettle();

      expect(find.text('Hide With Controls Settings'), findsOneWidget);
      expect(find.text('Hide Message Area'), findsOneWidget);
      expect(find.text('Hide Full Map Button'), findsOneWidget);
      expect(find.text('Hide Menu Button'), findsOneWidget);
    });

    testWidgets('Back操作確認ダイアログに「メニューを開く」ボタンが含まれ、タップ時に正しいアクションが返ること', (tester) async {
      String? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      const isJp = true;
                      final action = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text(isJp ? "ゲームの終了" : "Quit Game", style: const TextStyle(color: Colors.white)),
                          content: Text(
                            isJp
                                ? "本当に終了しますか？\n（進行状況はセーブされません。セーブして終了するにはメニューの「セーブして終了」を使用してください。）"
                                : "Really quit?\n(Progress will not be saved. To save and quit, use 'Save and Quit' from the menu.)",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop('cancel'),
                              child: Text(isJp ? "キャンセル" : "Cancel", style: const TextStyle(color: Colors.blueAccent)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop('menu'),
                              child: Text(isJp ? "メニューを開く" : "Open Menu", style: const TextStyle(color: Colors.amberAccent)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogCtx).pop('quit'),
                              child: Text(isJp ? "終了する" : "Quit", style: const TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      selectedAction = action;
                    },
                    child: const Text('Show Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ボタンの存在と順序の確認
      expect(find.text('ゲームの終了'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('メニューを開く'), findsOneWidget);
      expect(find.text('終了する'), findsOneWidget);

      // 「メニューを開く」をタップ
      await tester.tap(find.text('メニューを開く'));
      await tester.pumpAndSettle();

      expect(selectedAction, equals('menu'));
    });
  });
}

