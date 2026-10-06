import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/full_map_dialog.dart';

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
}
