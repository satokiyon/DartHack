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

      // 「画面表示設定」を展開して「物理キーボード用ヘルプを有効化」を確実に ON にする
      await tester.tap(find.text('画面表示設定'));
      await tester.pumpAndSettle();

      final textFinder = find.text('物理キーボード用ヘルプを有効化');
      await tester.ensureVisible(textFinder);
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.ancestor(of: textFinder, matching: find.byType(ListTile)),
        matching: find.byType(Switch),
      );
      final switchWidget = tester.widget<Switch>(switchFinder);
      if (!switchWidget.value) {
        await tester.tap(textFinder);
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

      // キーボード操作モードにして、Slider の FocusNode を取得してフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
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
      // キーボード操作モードにして、Slider の FocusNode を取得してフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      final FocusNode sliderFocus = (tester.state(sliderFinder) as dynamic).focusNode as FocusNode;
      sliderFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(sliderFocus.hasPrimaryFocus, isTrue);

      // 右カーソルキーを押下 -> スライダーの数値が増加すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(FontManager.instance.mapAsciiScale, greaterThan(initialVal));
    });

    testWidgets('カードが折りたたまれている時、下キーまたはTabキー1回で次のカードへ遷移し二重フォーカスにならないこと', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 初期状態で下キーを押す -> 一番上のセクション（タイル／シンボル設定）が選択される
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // カード外枠（Card）の境界線がアンバー色になっていること
      final firstCardFinder = find.ancestor(
        of: find.text('タイル／シンボル設定'),
        matching: find.byType(Card),
      ).first;
      final cardWidget = tester.widget<Card>(firstCardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect((shape.side.color), equals(Colors.amberAccent));

      // もう一度下キーを押す -> 同じカードに留まらず、直接2番目のセクション（フォント設定）へ遷移すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final secondCardFinder = find.ancestor(
        of: find.text('フォント設定'),
        matching: find.byType(Card),
      ).first;
      final secondCardWidget = tester.widget<Card>(secondCardFinder);
      final secondShape = secondCardWidget.shape as RoundedRectangleBorder;
      expect((secondShape.side.color), equals(Colors.amberAccent));
    });

    testWidgets('スライダーにフォーカスがある時、行全体の背景がハイライトされること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「フォント設定」を展開
      await tester.tap(find.text('フォント設定'));
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider).first;
      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();

      // キーボード操作モードにして、Slider の FocusNode を取得してフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      final FocusNode sliderFocus = (tester.state(sliderFinder) as dynamic).focusNode as FocusNode;
      sliderFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(sliderFocus.hasPrimaryFocus, isTrue);

      // 祖先の AnimatedContainer の色がアンバー透過色になっていること
      final animatedContainerFinder = find.ancestor(
        of: sliderFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final containerWidget = tester.widget<AnimatedContainer>(animatedContainerFinder);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(
        decoration?.color,
        equals(Colors.amberAccent.withValues(alpha: 0.25)),
      );
    });

    testWidgets('プルダウン項目にフォーカスがある時、背景がハイライトされ、左右キーで値が切り替わり、Enterでダイアログが開くこと', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「画面表示設定」を展開
      await tester.tap(find.text('画面表示設定'));
      await tester.pumpAndSettle();

      // カメラ追従モードのプルダウンを探す
      final dropdownTileFinder = find.ancestor(
        of: find.text('カメラ追従モード'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsDropdownTile')),
      ).first;
      await tester.ensureVisible(dropdownTileFinder);
      await tester.pumpAndSettle();

      // キーボード操作モードにして、Focus ウィジェットを探してフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      final focusFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(Focus),
      ).first;
      final focusWidget = tester.widget<Focus>(focusFinder);
      focusWidget.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(focusWidget.focusNode!.hasFocus, isTrue);

      // 行全体の背景色がアンバー透過色になっていること
      final animatedContainerFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final containerWidget = tester.widget<AnimatedContainer>(animatedContainerFinder);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(
        decoration?.color,
        equals(Colors.amberAccent.withValues(alpha: 0.25)),
      );

      // 左右キーで値が変更できること（右キーを押す）
      expect(find.textContaining('常時センタリング'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      // 'fixed'（マップ固定）に切り替わっていること
      expect(find.textContaining('マップ固定'), findsOneWidget);

      // 左キーを押すと元の 'center'（常時センタリング）に戻ること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.textContaining('常時センタリング'), findsOneWidget);

      // Enter キーを押すと選択ダイアログが表示されること
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);

      // ダイアログ内の選択肢をタップまたはEscapeで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('スイッチ項目にフォーカスがある時、行全体がハイライトされ、SpaceまたはEnterでトグル反転し親カードが閉じないこと', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      // 「画面表示設定」カードを展開
      final sectionTitleFinder = find.text('画面表示設定');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.tap(sectionTitleFinder);
      await tester.pumpAndSettle();

      // 「物理キーボード用ヘルプを有効化」の _SettingsSwitchTile を探す
      final switchTileFinder = find.ancestor(
        of: find.text('物理キーボード用ヘルプを有効化'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsSwitchTile')),
      ).first;
      await tester.ensureVisible(switchTileFinder);
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: switchTileFinder,
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);

      // キーボード操作モードにして、Focus ウィジェットを探してフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      final focusFinder = find.descendant(
        of: switchTileFinder,
        matching: find.byType(Focus),
      ).first;
      final focusWidget = tester.widget<Focus>(focusFinder);
      focusWidget.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(focusWidget.focusNode!.hasFocus, isTrue);

      // 行全体（AnimatedContainer）の背景色がアンバー透過色になっていること
      final animatedContainerFinder = find.descendant(
        of: switchTileFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final containerWidget = tester.widget<AnimatedContainer>(animatedContainerFinder);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(
        decoration?.color,
        equals(Colors.amberAccent.withValues(alpha: 0.25)),
      );

      // 初期値を確認
      final initialVal = tester.widget<Switch>(switchFinder).value;

      // Space キーを押下 -> 値が反転し、かつカードが閉じていないこと
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(switchFinder).value, equals(!initialVal));
      expect(find.text('物理キーボード用ヘルプを有効化'), findsOneWidget); // カードが開いたまま

      // Enter キーを押下 -> 値が再度反転し、かつカードが閉じていないこと
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(switchFinder).value, equals(initialVal));
      expect(find.text('物理キーボード用ヘルプを有効化'), findsOneWidget); // カードが開いたまま
    });

    testWidgets('自動セーブのターン間隔項目が共通プルダウンとして描画され左右キーやEnterキーで操作できること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「自動セーブ」カードまでスクロールして展開
      final sectionFinder = find.text('自動セーブ');
      await tester.scrollUntilVisible(
        sectionFinder,
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(sectionFinder);
      await tester.pumpAndSettle();

      // 「自動セーブを有効化」がONになっているか確認（OFFならタップしてONにする）
      final enableSwitchTile = find.ancestor(
        of: find.text('自動セーブを有効化'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsSwitchTile')),
      ).first;
      await tester.ensureVisible(enableSwitchTile);
      final switchFinder = find.descendant(
        of: enableSwitchTile,
        matching: find.byType(Switch),
      );
      if (!tester.widget<Switch>(switchFinder).value) {
        await tester.tap(enableSwitchTile);
        await tester.pumpAndSettle();
      }

      // 「自動セーブのターン間隔」プルダウンを探す
      final dropdownTileFinder = find.ancestor(
        of: find.text('自動セーブのターン間隔'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsDropdownTile')),
      ).first;
      await tester.ensureVisible(dropdownTileFinder);
      await tester.pumpAndSettle();

      // キーボード操作モードにして、プルダウンの Focus ウィジェットにフォーカスを当てる
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      final focusFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(Focus),
      ).first;
      final focusWidget = tester.widget<Focus>(focusFinder);
      focusWidget.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(focusWidget.focusNode!.hasFocus, isTrue);

      // 背景色がアンバー透過色になっていること
      final animatedContainerFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final containerWidget = tester.widget<AnimatedContainer>(animatedContainerFinder);
      final decoration = containerWidget.decoration as BoxDecoration?;
      expect(
        decoration?.color,
        equals(Colors.amberAccent.withValues(alpha: 0.25)),
      );

      // Enter キーを押すとダイアログが開くこと
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);

      // Escape でダイアログを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('プルダウン一覧ダイアログ内で上下キーを押すとフォーカスが移動し、背景ハイライトが移動先に追従すること、およびEnterで決定されること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「画面表示設定」カードを展開
      final sectionTitleFinder = find.text('画面表示設定');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.tap(sectionTitleFinder);
      await tester.pumpAndSettle();

      // カメラ追従モードのプルダウンを探す
      final dropdownTileFinder = find.ancestor(
        of: find.text('カメラ追従モード'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsDropdownTile')),
      ).first;
      await tester.ensureVisible(dropdownTileFinder);
      await tester.pumpAndSettle();

      // プルダウンにフォーカスを当てて Enter を押す -> ダイアログ展開
      final focusFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(Focus),
      ).first;
      tester.widget<Focus>(focusFinder).focusNode!.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);

      // ダイアログ内の選択肢アイテムを探す
      final dialogItemFinders = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('_DropdownDialogItem'),
      );
      expect(dialogItemFinders, findsNWidgets(2)); // 'center' と 'fixed'

      // 初期フォーカス（'center'）の背景色がアンバー色（alpha: 0.35）であること
      final firstItemContainer = find.descendant(
        of: dialogItemFinders.first,
        matching: find.byType(AnimatedContainer),
      ).first;
      final firstDecor = tester.widget<AnimatedContainer>(firstItemContainer).decoration as BoxDecoration?;
      expect(firstDecor?.color, equals(Colors.amberAccent.withValues(alpha: 0.35)));

      // 2番目のアイテム（'fixed'）の背景色は透明であること
      final secondItemContainer = find.descendant(
        of: dialogItemFinders.last,
        matching: find.byType(AnimatedContainer),
      ).first;
      final secondDecor = tester.widget<AnimatedContainer>(secondItemContainer).decoration as BoxDecoration?;
      expect(secondDecor?.color, equals(Colors.transparent));

      // 下キー（ArrowDown）を押下 -> 2番目のアイテムへフォーカス移動
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 移動先（'fixed'）の背景色がアンバー色になり、移動元（'center'）は透明に戻ること！
      final firstDecorAfter = tester.widget<AnimatedContainer>(firstItemContainer).decoration as BoxDecoration?;
      final secondDecorAfter = tester.widget<AnimatedContainer>(secondItemContainer).decoration as BoxDecoration?;
      expect(firstDecorAfter?.color, equals(Colors.transparent));
      expect(secondDecorAfter?.color, equals(Colors.amberAccent.withValues(alpha: 0.35)));

      // Enter キーを押下 -> 選択中の 'fixed' が決定されてダイアログが閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);

      // 設定値が「マップ固定」に変更されていること
      expect(find.textContaining('マップ固定'), findsOneWidget);
    });

    testWidgets('valueがnullのプルダウン（一括フォント変更）でもダイアログの先頭アイテムが初期フォーカスされ上下キーで追従すること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「フォント設定」カードを展開
      final sectionTitleFinder = find.text('フォント設定');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.tap(sectionTitleFinder);
      await tester.pumpAndSettle();

      // 「一括フォント変更」プルダウン（value: null）を探す
      final dropdownTileFinder = find.ancestor(
        of: find.text('一括フォント変更'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsDropdownTile')),
      ).first;
      await tester.ensureVisible(dropdownTileFinder);
      await tester.pumpAndSettle();

      // フォーカスを当てて Enter を押す -> ダイアログ展開
      final focusFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(Focus),
      ).first;
      tester.widget<Focus>(focusFinder).focusNode!.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);

      // ダイアログ内の選択肢アイテムを探す
      final dialogItemFinders = find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('_DropdownDialogItem'),
      );
      expect(dialogItemFinders, findsWidgets);

      // 先頭アイテムが初期フォーカスされ、背景色がアンバー色（alpha: 0.35）であること！
      final firstItemContainer = find.descendant(
        of: dialogItemFinders.first,
        matching: find.byType(AnimatedContainer),
      ).first;
      final firstDecor = tester.widget<AnimatedContainer>(firstItemContainer).decoration as BoxDecoration?;
      expect(firstDecor?.color, equals(Colors.amberAccent.withValues(alpha: 0.35)));

      // 下キーを押すと2番目のアイテムへアンバー色が移動すること
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final firstDecorAfter = tester.widget<AnimatedContainer>(firstItemContainer).decoration as BoxDecoration?;
      expect(firstDecorAfter?.color, equals(Colors.transparent));

      // Escape でダイアログを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Touch interaction on dropdown does not highlight tile background or parent card border', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 「画面表示設定」カードを展開
      final sectionTitleFinder = find.text('画面表示設定');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.tap(sectionTitleFinder);
      await tester.pumpAndSettle();

      // タッチ操作モードであることを確認
      expect(FocusManager.instance.highlightMode, equals(FocusHighlightMode.touch));

      // カメラ追従モードのプルダウンを探す
      final dropdownTileFinder = find.ancestor(
        of: find.text('カメラ追従モード'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsDropdownTile')),
      ).first;
      await tester.ensureVisible(dropdownTileFinder);
      await tester.pumpAndSettle();

      // プルダウンの DropdownButton をタップ
      final dropdownButtonFinder = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(DropdownButton<String>),
      );
      await tester.tap(dropdownButtonFinder);
      await tester.pumpAndSettle();

      // ポップアップメニューから 'fixed' (マップ固定) をタップ選択
      final menuItemFinder = find.text('マップ固定 (PC版スタイル・端スクロール)').last;
      await tester.tap(menuItemFinder);
      await tester.pumpAndSettle();

      // タップ選択後: プルダウンタイルの AnimatedContainer の背景色が透明であること（アンバーハイライトされていないこと）
      final tileAnimatedContainer = find.descendant(
        of: dropdownTileFinder,
        matching: find.byType(AnimatedContainer),
      ).last;
      final tileDecor = tester.widget<AnimatedContainer>(tileAnimatedContainer).decoration as BoxDecoration?;
      expect(tileDecor?.color, equals(Colors.transparent));

      // 親カード（画面表示設定）の枠線が通常色（Colors.white12, width: 1.0）であり、アンバーの太線（width: 2.5）でないこと
      final cardFinder = find.ancestor(
        of: sectionTitleFinder,
        matching: find.byType(Card),
      ).first;
      final cardShape = tester.widget<Card>(cardFinder).shape as RoundedRectangleBorder;
      expect(cardShape.side.color, equals(Colors.white12));
      expect(cardShape.side.width, equals(1.0));
    });

    testWidgets('キーボードでカード見出しを選択中、カード外枠が太枠(width: 2.5)かつ見出し行がアンバー色でハイライトされ、展開時も維持されること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 初期状態で下キー -> 最初のカード「タイル／シンボル設定」を選択
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      final cardFinder = find.ancestor(
        of: find.text('タイル／シンボル設定'),
        matching: find.byType(Card),
      ).first;
      final cardWidget = tester.widget<Card>(cardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;

      // カード外枠が太いアンバー枠線（width: 2.5）であること
      expect(shape.side.color, equals(Colors.amberAccent));
      expect(shape.side.width, equals(2.5));

      // 見出しテーマの背景色がアンバー色（alphaBlend: 0.25）であること
      final themeFinder = find.descendant(
        of: cardFinder,
        matching: find.byType(ExpansionTileTheme),
      ).first;
      final tileTheme = tester.widget<ExpansionTileTheme>(themeFinder);
      final headerHighlightBg = Color.alphaBlend(
        Colors.amberAccent.withValues(alpha: 0.25),
        const Color(0xFF25262E),
      );
      expect(tileTheme.data.collapsedBackgroundColor, equals(headerHighlightBg));
      expect(tileTheme.data.backgroundColor, equals(headerHighlightBg));

      // Enter キーでカードを展開
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // 展開後も見出し選択中はカード外枠が太枠（width: 2.5）であり、backgroundColor がアンバー色を維持していること
      final expandedCardWidget = tester.widget<Card>(cardFinder);
      final expandedShape = expandedCardWidget.shape as RoundedRectangleBorder;
      expect(expandedShape.side.color, equals(Colors.amberAccent));
      expect(expandedShape.side.width, equals(2.5));

      final expandedTileTheme = tester.widget<ExpansionTileTheme>(themeFinder);
      expect(expandedTileTheme.data.backgroundColor, equals(headerHighlightBg));
    });

    testWidgets('展開されたカード内で下キーを押すと1回のキー押下で子項目へ進み、カード外枠がwidth: 1.5を維持しつつ項目行がハイライトされること', (tester) async {
      await tester.pumpWidget(buildTestableSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // 下キーで「タイル／シンボル設定」を選択し、Enter で展開
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // 下キーを1回押下 -> 内部ヘッダーをスキップして直接最初の設定項目（タイル表示を使用）へ進むこと
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // 選択中の設定項目「タイル表示を使用」の行背景がアンバー色（alpha: 0.25）でハイライトされていること
      final switchTileFinder = find.ancestor(
        of: find.text('タイル表示を使用'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_SettingsSwitchTile')),
      ).first;
      final tileAnimatedContainer = find.descendant(
        of: switchTileFinder,
        matching: find.byType(AnimatedContainer),
      ).first;
      final tileDecor = tester.widget<AnimatedContainer>(tileAnimatedContainer).decoration as BoxDecoration?;
      expect(tileDecor?.color, equals(Colors.amberAccent.withValues(alpha: 0.25)));

      // 親カードの枠線が幅 1.5（子項目操作中の中太枠線）でアンバー枠線を維持していること
      final cardFinder = find.ancestor(
        of: find.text('タイル／シンボル設定'),
        matching: find.byType(Card),
      ).first;
      final cardWidget = tester.widget<Card>(cardFinder);
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.side.width, equals(1.5));
      expect(shape.side.color, equals(Colors.amberAccent.withValues(alpha: 0.65)));
    });
  });
}

