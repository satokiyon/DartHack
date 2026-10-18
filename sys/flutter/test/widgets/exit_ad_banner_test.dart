import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/config/ad_config.dart';
import 'package:darthack/widgets/exit_ad_banner.dart';

void main() {
  group('ExitAdBanner Widget Tests', () {
    tearDown(() {
      AdConfig.isAndroidOverride = null;
      AdConfig.isIOSOverride = null;
      AdConfig.bannerAdUnitIdOverride = null;
      AdConfig.rewardedAdUnitIdOverride = null;
    });

    testWidgets('非モバイル環境ではロードを行わず onAdFailedToLoad が呼ばれ空ウィジェットが表示されること', (tester) async {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      bool failedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitAdBanner(
              onAdFailedToLoad: () {
                failedCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(failedCalled, isTrue);
      // SizedBox.shrink であることの確認
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('モバイル環境であっても広告IDが空の場合に onAdFailedToLoad が呼ばれ空ウィジェットが表示されること', (tester) async {
      AdConfig.isAndroidOverride = true;
      AdConfig.isIOSOverride = false;
      AdConfig.bannerAdUnitIdOverride = '';

      bool failedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitAdBanner(
              onAdFailedToLoad: () {
                failedCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(failedCalled, isTrue);
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });
  });
}
