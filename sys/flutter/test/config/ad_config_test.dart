import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/config/ad_config.dart';

void main() {
  group('AdConfig Tests', () {
    tearDown(() {
      AdConfig.isAndroidOverride = null;
      AdConfig.isIOSOverride = null;
      AdConfig.bannerAdUnitIdOverride = null;
      AdConfig.rewardedAdUnitIdOverride = null;
    });

    test('Android環境で適切なテスト広告IDとフラグが返ること', () {
      AdConfig.isAndroidOverride = true;
      AdConfig.isIOSOverride = false;

      expect(AdConfig.isAndroid, isTrue);
      expect(AdConfig.isIOS, isFalse);
      expect(AdConfig.isMobilePlatform, isTrue);
      expect(AdConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AdConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('iOS環境で適切なテスト広告IDとフラグが返ること', () {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = true;

      expect(AdConfig.isAndroid, isFalse);
      expect(AdConfig.isIOS, isTrue);
      expect(AdConfig.isMobilePlatform, isTrue);
      expect(AdConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AdConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/1712484513');
    });

    test('非モバイル環境 (デスクトップ/Web等) では空文字と非モバイルフラグが返ること', () {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      expect(AdConfig.isAndroid, isFalse);
      expect(AdConfig.isIOS, isFalse);
      expect(AdConfig.isMobilePlatform, isFalse);
      expect(AdConfig.bannerAdUnitId, isEmpty);
      expect(AdConfig.rewardedAdUnitId, isEmpty);
    });

    test('広告ユニットIDオーバーライドが設定されている場合は最優先で返ること', () {
      AdConfig.isAndroidOverride = true;
      AdConfig.bannerAdUnitIdOverride = 'custom-banner-id';
      AdConfig.rewardedAdUnitIdOverride = 'custom-rewarded-id';

      expect(AdConfig.bannerAdUnitId, 'custom-banner-id');
      expect(AdConfig.rewardedAdUnitId, 'custom-rewarded-id');

      AdConfig.bannerAdUnitIdOverride = '';
      AdConfig.rewardedAdUnitIdOverride = '';

      expect(AdConfig.bannerAdUnitId, isEmpty);
      expect(AdConfig.rewardedAdUnitId, isEmpty);
    });
  });
}
