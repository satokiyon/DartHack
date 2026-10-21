import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/config/ad_config.dart';
import 'package:darthack/nethack_core_loader.dart';
import 'package:darthack/utils/defaults_helper.dart';
import 'package:darthack/utils/rewarded_ad_manager.dart';

void main() {
  group('Platform Features Tests (Windows Desktop vs Android Mobile)', () {
    tearDown(() {
      AdConfig.isAndroidOverride = null;
      AdConfig.isIOSOverride = null;
      AdConfig.bannerAdUnitIdOverride = null;
      AdConfig.rewardedAdUnitIdOverride = null;
      NetHackCoreLoader.resetForTesting();
    });

    group('RewardedAdManager Platform Guard Tests', () {
      test('Windows/非モバイル環境ではプリロードおよび広告ロードがスキップされ安全であること', () async {
        // Windows 環境をシミュレート
        AdConfig.isAndroidOverride = false;
        AdConfig.isIOSOverride = false;
        RewardedAdManager.resetForTesting();

        // Windows環境で initializeAndPreload を呼んでも例外を出さず安全に終了すること
        await RewardedAdManager.initializeAndPreload();
        expect(RewardedAdManager.hasPendingSession, isFalse);

        // 広告表示を試みても onAdClosed(false) が即座に呼ばれ、報酬は得られないこと
        bool rewardEarned = false;
        bool closedWithReward = true;
        RewardedAdManager.showRewardedAd(
          onUserEarnedReward: (amount) {
            rewardEarned = true;
          },
          onAdClosed: (hasEarnedReward) {
            closedWithReward = hasEarnedReward;
          },
        );

        expect(rewardEarned, isFalse);
        expect(closedWithReward, isFalse);
        expect(RewardedAdManager.hasPendingSession, isFalse);
      });
    });

    group('NetHackCoreLoader Platform Switching & Subdir Tests', () {
      test('言語切り替え時にアセットパスとライブラリ名が連動して切り替わること', () {
        // 日本語モード
        expect(NetHackCoreLoader.getAssetSubdir('ja'), 'jp');
        expect(
          NetHackCoreLoader.getLibraryName(langCode: 'ja', platformOverride: 'windows'),
          'nethack_jp.dll',
        );
        expect(
          NetHackCoreLoader.getLibraryName(langCode: 'ja', platformOverride: 'android'),
          'libnethack_jp.so',
        );

        // 英語モード
        expect(NetHackCoreLoader.getAssetSubdir('en'), 'en');
        expect(
          NetHackCoreLoader.getLibraryName(langCode: 'en', platformOverride: 'windows'),
          'nethack_en.dll',
        );
        expect(
          NetHackCoreLoader.getLibraryName(langCode: 'en', platformOverride: 'android'),
          'libnethack_en.so',
        );
      });
    });

    group('DefaultsHelper Windows CRLF & Multibyte Handling Tests', () {
      late Directory tempDir;
      late File testFile;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('darthack_test_');
        testFile = File('${tempDir.path}${Platform.pathSeparator}defaults.nh');
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('Windows標準のCRLF改行および日本語MENUCOLOR設定を正常にパース・保存できること', () async {
        // WindowsスタイルのCRLF改行を含むdefaults.nhコンテンツ
        const windowsDefaultsContent =
            'OPTIONS=autopickup, showexp, time\r\n'
            'OPTIONS=number_pad:1\r\n'
            'MENUCOLOR="祝福された"=green\r\n'
            'MENUCOLOR="呪われた"=red\r\n'
            'OPTIONS=hilite_status:hitpoints/100%/white&bold\r\n';

        await testFile.writeAsString(windowsDefaultsContent);

        final helper = DefaultsHelper();
        await helper.loadFromFile(testFile.path);

        // パース結果の検証
        expect(helper.getBoolOption('autopickup'), isTrue);
        expect(helper.getBoolOption('showexp'), isTrue);
        expect(helper.getBoolOption('time'), isTrue);
        expect(helper.getOption('number_pad'), '1');
        expect(helper.getBoolOption('menucolor'), isTrue);
        expect(helper.getBoolOption('hilite_status'), isTrue);

        // オプション変更と保存
        helper.setBoolOption('autopickup', false);
        helper.setOption('name', 'テスト勇者');
        await helper.saveToFile(testFile.path);

        // 再読込して保存結果を検証
        final helper2 = DefaultsHelper();
        await helper2.loadFromFile(testFile.path);
        expect(helper2.getBoolOption('autopickup'), isFalse);
        expect(helper2.getOption('name'), 'テスト勇者');
        expect(helper2.getBoolOption('menucolor'), isTrue);

        // 日本語MENUCOLOR行がファイル内に保持されていることを確認
        final savedContent = await testFile.readAsString();
        expect(savedContent.contains('MENUCOLOR="祝福された"=green'), isTrue);
        expect(savedContent.contains('MENUCOLOR="呪われた"=red'), isTrue);
      });
    });
  });
}

