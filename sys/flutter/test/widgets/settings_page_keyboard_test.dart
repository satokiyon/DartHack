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
    tempDir = await Directory.systemTemp.createTemp('settings_keyboard_test_');
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

  Widget buildTestableSettingsApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        defaultsFilePath: defaultsFile.path,
                        dataDirString: tempDir.path,
                      ),
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          );
        },
      ),
    );
  }

  group('SettingsPage Keyboard Navigation Tests', () {
    testWidgets('Escape key navigates back from settings page', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      // 設定画面を開く
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      // Escapeキーを押下 -> 前の画面に戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('PageDown, PageUp, Home, End scroll the settings list without error', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // PageDown
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();

      // PageUp
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();

      // End
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      // Home
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      // 最後に Escape で戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
    });

    testWidgets('Tab navigates through focusable controls and Enter triggers action', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // Tabキーでフォーカス移動
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Shift+Tabで逆移動
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('初期状態で下カーソルキー (ArrowDown) を押すと一番上の項目（タイル設定）が選択され最上部にスクロールされること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      final scrollController = tester.widget<ListView>(find.byType(ListView)).controller!;

      // 初期状態で ArrowDown 押下 -> 一番上の項目（タイル／シンボル設定）にフォーカス
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(scrollController.offset, equals(0.0));
      expect(find.text('タイル／シンボル設定'), findsOneWidget);
    });

    testWidgets('初期状態で上カーソルキー (ArrowUp) を押すと一番下の項目（クレジット）が選択され最下部にスクロールされること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      final scrollController = tester.widget<ListView>(find.byType(ListView)).controller!;

      // 初期状態で ArrowUp 押下 -> 一番下の項目（クレジット）にフォーカス＆最下部へスクロール
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(200.0));
      expect(find.text('クレジット'), findsOneWidget);
    });

    testWidgets('一番上の項目から ArrowUp で AppBar 戻るボタンへ移動し、さらに ArrowUp で一番下の項目へループすること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      final scrollController = tester.widget<ListView>(find.byType(ListView)).controller!;

      // 1. ArrowDown で先頭項目へ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 2. ArrowUp で AppBar 戻るボタンへ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // 3. さらに ArrowUp で末尾項目（クレジット）へループ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(200.0));
      expect(find.text('クレジット'), findsOneWidget);
    });

    testWidgets('一番下の項目から ArrowDown で AppBar 戻るボタンへ移動し、さらに ArrowDown で一番上の項目へループすること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      final scrollController = tester.widget<ListView>(find.byType(ListView)).controller!;

      // 1. 初期状態で ArrowUp で末尾項目へ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(scrollController.offset, greaterThan(200.0));

      // 2. ArrowDown で AppBar 戻るボタンへ移動＆最上部へスクロール
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(scrollController.offset, equals(0.0));

      // 3. さらに ArrowDown で先頭項目（タイル設定）へループ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(scrollController.offset, equals(0.0));
      expect(find.text('タイル／シンボル設定'), findsOneWidget);
    });

    testWidgets('AppBar 戻るボタンにフォーカスがある状態で Enter または Space を押すと設定画面が閉じること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 先頭項目へ -> ArrowUp で戻るボタンへ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Enter を押下 -> 画面が閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text('Open Settings'), findsOneWidget);
    });
  });
}

