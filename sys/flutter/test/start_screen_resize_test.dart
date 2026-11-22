import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/screens/end_screen.dart';
import 'package:darthack/screens/start_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    );
  }

  group('StartScreen / EndScreen ウィンドウリサイズ耐性テスト', () {
    testWidgets('StartScreen は連続リサイズでも gaplessPlayback=true かつオーバーフローせず安定表示される', (tester) async {
      // モニター物理サイズを固定した状態でウィンドウサイズ（MediaQuery.size）を連続変更する
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final testSizes = <Size>[
        const Size(1280, 720),
        const Size(1000, 680),
        const Size(720, 500),
        const Size(480, 360), // Windows 最小サイズ想定
        const Size(500, 500), // 正方形
        const Size(480, 800), // 縦長
        const Size(1920, 1080),
      ];

      // テスト環境では TestFlutterView.display.size が physicalSize に連動するため、
      // まずディスプレイ幅一定（1920x1080）の下で MediaQuery サイズを連続変更して cacheWidth 固定を検証する。
      tester.view.physicalSize = const Size(1920, 1080);

      final observedCacheWidths = <int>{};
      for (final size in testSizes) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: 1.0),
            child: wrapWithApp(
              StartScreen(
                assetsReady: true,
                selectedLanguage: 'ja',
                onLanguageChanged: (_) {},
                onStartGame: () {},
                onShowSettings: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'サイズ $size でレイアウト例外が発生しました');

        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        expect(images.length, greaterThanOrEqualTo(2));
        for (final img in images) {
          expect(img.gaplessPlayback, isTrue, reason: 'リサイズ黒画面防止のため gaplessPlayback は true である必要があります');
          expect(img.image, isA<ResizeImage>());
          final resizeImg = img.image as ResizeImage;
          expect(resizeImg.width, isNotNull);
          expect(resizeImg.width!, greaterThanOrEqualTo(1));
          observedCacheWidths.add(resizeImg.width!);
        }
      }

      // 背景 (1920) とロゴ (1024) の 2 種類のみに固定され、リサイズ回数分増えないこと
      expect(observedCacheWidths, equals({1920, 1024}));
    });

    testWidgets('EndScreen も連続リサイズで gaplessPlayback=true かつ cacheWidth が安定している', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1920, 1080);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final observedCacheWidths = <int>{};
      for (final size in const [Size(1280, 720), Size(800, 600), Size(480, 360), Size(480, 800)]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: 1.0),
            child: wrapWithApp(const EndScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final img = tester.widget<Image>(find.byType(Image));
        expect(img.gaplessPlayback, isTrue);
        expect(img.image, isA<ResizeImage>());
        observedCacheWidths.add((img.image as ResizeImage).width!);
      }

      expect(observedCacheWidths, equals({1920}));
    });
  });
}
