import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/full_map_dialog.dart';
import 'package:darthack/widgets/keyboard_help_dialog.dart';

void main() {
  testWidgets('縦長画面（Portrait）で全体マップダイアログの高さが画面の65%になること', (tester) async {
    // 画面サイズを縦長（幅400、高さ800）に設定
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final screen = NetHackScreen();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showFullMapDialog(
                    context: context,
                    screen: screen,
                    useTiles: false,
                    tileImage: null,
                    tileWidth: 16,
                    tileHeight: 16,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    // ダイアログを開く
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // ダイアログおよびヘッダー・フッターの表示確認
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('階層の全体地図'), findsOneWidget);

    // ダイアログのコンテンツサイズを確認（高さが 800 * 0.65 = 520px であること）
    final dialogContentFinder = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.height == 800 * 0.65,
    );
    expect(dialogContentFinder, findsOneWidget);

    final dialogBox = tester.renderObject<RenderBox>(dialogContentFinder);
    expect(dialogBox.size.height, closeTo(520.0, 1.0));

    // 閉じるボタンの動作確認
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('横長画面（Landscape）で固定の65%高さが適用されないこと', (tester) async {
    // 画面サイズを横長（幅800、高さ400）に設定
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final screen = NetHackScreen();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showFullMapDialog(
                    context: context,
                    screen: screen,
                    useTiles: false,
                    tileImage: null,
                    tileWidth: 16,
                    tileHeight: 16,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    // ダイアログを開く
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 横長画面では 65% 指定の SizedBox は存在しないこと
    final dialogContentFinder = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.height == 400 * 0.65,
    );
    expect(dialogContentFinder, findsNothing);

    // 閉じるボタンの動作確認
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('maxScaleが30.0に設定され、ダブルタップでズームイン・リセットが行えること', (tester) async {
    final screen = NetHackScreen();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showFullMapDialog(
                    context: context,
                    screen: screen,
                    useTiles: false,
                    tileImage: null,
                    tileWidth: 16,
                    tileHeight: 16,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    // ダイアログを開く
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // InteractiveViewer の maxScale が 30.0 であること
    final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    expect(viewer.maxScale, 30.0);

    // 初期状態のスケール確認（1.0）
    final controller = viewer.transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));

    // 全体表示中にマップ領域をダブルタップ -> 約6倍にズームイン
    final mapCenter = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(mapCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(mapCenter);
    await tester.pumpAndSettle();

    // 拡大されたことを確認（scale > 1.05、約6倍）
    expect(controller.value.getMaxScaleOnAxis(), closeTo(6.0, 0.5));

    // 拡大状態で再度ダブルタップ -> 全体表示（1.0）にリセット
    await tester.tapAt(mapCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(mapCenter);
    await tester.pumpAndSettle();

    // スケールが初期状態（1.0）にリセットされたことを確認
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));
  });

  group('FullMapDialog Keyboard Navigation Tests', () {
    testWidgets('Tab cycles close button focus, Escape / Space / q / Enter close dialog', (tester) async {
      final screen = NetHackScreen();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFullMapDialog(
                      context: context,
                      screen: screen,
                      useTiles: false,
                      tileImage: null,
                      tileWidth: 16,
                      tileHeight: 16,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // Tabキーを押下 -> 閉じるボタンがハイライト状態になる
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // もう一度Tabキーを押下 -> noneに戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // qキーで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 再度開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // Escapeキーで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      // 再度開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // Spaceキーで閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('+ / - zoom in / out, 0 / Home resets zoom, and z toggles zoom', (tester) async {
      final screen = NetHackScreen();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFullMapDialog(
                      context: context,
                      screen: screen,
                      useTiles: false,
                      tileImage: null,
                      tileWidth: 16,
                      tileHeight: 16,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final controller = viewer.transformationController!;
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));

      // + キーでズームイン
      await tester.sendKeyEvent(LogicalKeyboardKey.equal); // = / +
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(1.1));

      // - キーでズームアウト
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.05));

      // 0 キーでリセット
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));

      // z キーでズームイン（約6倍）
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(6.0, 0.5));

      // z キーでズームリセット（等倍）
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.01));
    });

    testWidgets('Arrow keys and Vi keys pan the map', (tester) async {
      final screen = NetHackScreen();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFullMapDialog(
                      context: context,
                      screen: screen,
                      useTiles: false,
                      tileImage: null,
                      tileWidth: 16,
                      tileHeight: 16,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final controller = viewer.transformationController!;

      final initialTx = controller.value.storage[12];
      final initialTy = controller.value.storage[13];

      // 矢印キー（左）で右方向へパン
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(controller.value.storage[12], greaterThan(initialTx));

      // Viキー（l: 右）で左方向へパン
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pumpAndSettle();
      expect(controller.value.storage[12], closeTo(initialTx, 0.1));

      // 矢印キー（上）で下方向へパン
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(controller.value.storage[13], greaterThan(initialTy));

      // Viキー（j: 下）で上方向へパン
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle();
      expect(controller.value.storage[13], closeTo(initialTy, 0.1));
    });

    testWidgets('Alt+h does not pan the map, and opens KeyboardHelpDialog when usePhysicalKeyboardNotation is true', (tester) async {
      final screen = NetHackScreen();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFullMapDialog(
                      context: context,
                      screen: screen,
                      useTiles: false,
                      tileImage: null,
                      tileWidth: 16,
                      tileHeight: 16,
                      usePhysicalKeyboardNotation: true,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final viewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final controller = viewer.transformationController!;

      final initialTx = controller.value.storage[12];

      // Alt+h を送信
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      // パン移動していないこと（hキーが誤爆していないこと）
      expect(controller.value.storage[12], equals(initialTx));

      // KeyboardHelpDialog が開いていること
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
      expect(find.textContaining('6倍拡大 ⇔ 全体表示'), findsOneWidget);
      expect(find.textContaining('マップのパン（平行移動）'), findsOneWidget);

      // Escape でヘルプを閉じる
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsNothing);

      // F1 キーでもヘルプが開くこと
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardHelpDialog), findsOneWidget);
    });

    testWidgets('Alt+h or F1 does not open KeyboardHelpDialog when usePhysicalKeyboardNotation is false', (tester) async {
      final screen = NetHackScreen();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showFullMapDialog(
                      context: context,
                      screen: screen,
                      useTiles: false,
                      tileImage: null,
                      tileWidth: 16,
                      tileHeight: 16,
                      usePhysicalKeyboardNotation: false,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Alt+h を送信
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      // ヘルプが開かないこと
      expect(find.byType(KeyboardHelpDialog), findsNothing);

      // F1 を送信
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      // ヘルプが開かないこと
      expect(find.byType(KeyboardHelpDialog), findsNothing);
    });
  });
}
