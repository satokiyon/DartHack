import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:darthack/settings_page.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';

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

    testWidgets('use_physical_keyboard_notation が ON の時、F1 または Alt+h で操作ヘルプダイアログが表示されること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 「画面表示設定」を展開して「物理キーボード用の表記を使用」を確実に ON にする
      await tester.tap(find.text('画面表示設定'));
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(SwitchListTile, '物理キーボード用の表記を使用');
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      if (!switchWidget.value) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();
      }

      // F1 キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      // KeyboardHelpDialog が開いていること
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // F1 で閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsNothing);

      // Alt+h キーを押下
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      // KeyboardHelpDialog が開いていること
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);

      // Alt+h で閉じる
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('use_physical_keyboard_notation が OFF の時は F1 や Alt+h を押しても操作ヘルプが表示されないこと', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // F1 キーを押下
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsNothing);

      // Alt+h キーを押下
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });

    testWidgets('初期状態で下カーソルキーを押した後、さらに下カーソルキーを押すと次のセクションへフォーカスが遷移すること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 1回目の下キー: 最初のセクション（tileset）へ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final focus1 = FocusManager.instance.primaryFocus;
      expect(focus1, isNotNull);

      // 2回目の下キー: 次のセクション（font）へ遷移すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final focus2 = FocusManager.instance.primaryFocus;
      expect(focus2, isNotNull);
      expect(focus2, isNot(equals(focus1)));
    });

    testWidgets('Tabキーで次のセクションへ順次フォーカスが遷移すること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 1回目のTab: 最初のセクション（tileset）へ
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focus1 = FocusManager.instance.primaryFocus;
      expect(focus1, isNotNull);

      // 2回目のTab: 次のセクション（font）へ遷移すること
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focus2 = FocusManager.instance.primaryFocus;
      expect(focus2, isNotNull);
      expect(focus2, isNot(equals(focus1)));
    });

    testWidgets('セクション見出しにフォーカスがある状態で Enter または Space を押すと展開/折りたたみがトグルされること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 初期状態で下キー -> tileset セクション見出しへフォーカス
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 初期状態ではタイル設定の子要素（タイル表示を使用 スイッチ）は未展開
      expect(find.text('タイル表示を使用'), findsNothing);

      // Enter キーを押下 -> セクションが展開される
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('タイル表示を使用'), findsOneWidget);

      // 再度 Space キーを押下 -> セクションが折りたたまれる
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('タイル表示を使用'), findsNothing);
    });

    testWidgets('スライダーにフォーカスがある時、上下キーでは数値が変更されずフォーカスが脱出すること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 「フォント設定」を展開
      await tester.tap(find.text('フォント設定'));
      await tester.pumpAndSettle();

      // アスキーマップ倍率スライダーを探す
      final sliderFinder = find.byType(Slider).first;
      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();

      final sliderWidget = tester.widget<Slider>(sliderFinder);
      final initialVal = sliderWidget.value;

      // Slider の FocusNode を取得してフォーカスを当てる
      final FocusNode sliderFocus = (tester.state(sliderFinder) as dynamic).focusNode as FocusNode;
      sliderFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(sliderFocus.hasPrimaryFocus, isTrue);

      // 上カーソルキーを押下 -> スライダーの数値は変化せず、フォーカスが脱出すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(FontManager.instance.mapAsciiScale, equals(initialVal));
      expect(sliderFocus.hasPrimaryFocus, isFalse);
    });

    testWidgets('スライダーにフォーカスがある時、左右キーで数値が変更されること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 「フォント設定」を展開
      await tester.tap(find.text('フォント設定'));
      await tester.pumpAndSettle();

      // アスキーマップ倍率スライダーを探す
      final sliderFinder = find.byType(Slider).first;
      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();

      final sliderWidget = tester.widget<Slider>(sliderFinder);
      final initialVal = sliderWidget.value;

      // Slider 内部の FocusNode にフォーカスを当てる
      // Slider の FocusNode を取得してフォーカスを当てる
      final FocusNode sliderFocus = (tester.state(sliderFinder) as dynamic).focusNode as FocusNode;
      sliderFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(sliderFocus.hasPrimaryFocus, isTrue);

      // 右カーソルキーを押下 -> スライダーの数値が増加すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(FontManager.instance.mapAsciiScale, greaterThan(initialVal));
    });
  });
}

