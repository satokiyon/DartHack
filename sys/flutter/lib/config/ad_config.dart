import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConfig {
  /// AdMob App ID (本番環境): ca-app-pub-8927748822227673~4813173081
  /// AdMob Banner ID (本番環境): ca-app-pub-8927748822227673/2226418056

  /// テスト用のプラットフォーム判定オーバーライド
  @visibleForTesting
  static bool? isAndroidOverride;

  @visibleForTesting
  static bool? isIOSOverride;

  /// Android プラットフォームであるか
  static bool get isAndroid => isAndroidOverride ?? Platform.isAndroid;

  /// iOS プラットフォームであるか
  static bool get isIOS => isIOSOverride ?? Platform.isIOS;

  /// Android または iOS のモバイルプラットフォームであるか
  static bool get isMobilePlatform => isAndroid || isIOS;

  /// テスト用の広告ユニットIDオーバーライド（null の場合は通常の解決ロジックを使用）
  @visibleForTesting
  static String? bannerAdUnitIdOverride;

  @visibleForTesting
  static String? rewardedAdUnitIdOverride;

  /// バナー広告ユニットIDの取得 (ゲーム終了時バナー)
  /// `--dart-define=ADMOB_GAME_END_BANNER_ID=xxx` または `--dart-define-from-file=...`
  /// で環境変数が渡されている場合は指定されたIDを使用し、
  /// 未指定時はGoogle公式のテスト用広告ユニットIDを安全なデフォルトとして返します。
  static String get bannerAdUnitId {
    final override = bannerAdUnitIdOverride;
    if (override != null) return override;

    const definedId = String.fromEnvironment('ADMOB_GAME_END_BANNER_ID');
    if (definedId.isNotEmpty) {
      return definedId;
    }

    if (isAndroid) {
      // Google公式 テスト用バナー広告ユニットID (Android)
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (isIOS) {
      // Google公式 テスト用バナー広告ユニットID (iOS)
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return '';
    }
  }

  /// リワード広告ユニットIDの取得 (階段昇降時リワード)
  /// AdMob本番リワードID: ca-app-pub-8927748822227673/3801358216
  /// `--dart-define=ADMOB_KAIDAN_REWARDED_ID=xxx` または `--dart-define-from-file=...`
  /// で環境変数が渡されている場合は指定されたIDを使用し、
  /// 未指定時はGoogle公式のテスト用リワード広告ユニットIDを安全なデフォルトとして返します。
  static String get rewardedAdUnitId {
    final override = rewardedAdUnitIdOverride;
    if (override != null) return override;

    const definedId = String.fromEnvironment('ADMOB_KAIDAN_REWARDED_ID');
    if (definedId.isNotEmpty) {
      return definedId;
    }

    if (isAndroid) {
      // Google公式 テスト用リワード広告ユニットID (Android)
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (isIOS) {
      // Google公式 テスト用リワード広告ユニットID (iOS)
      return 'ca-app-pub-3940256099942544/1712484513';
    } else {
      return '';
    }
  }
}



