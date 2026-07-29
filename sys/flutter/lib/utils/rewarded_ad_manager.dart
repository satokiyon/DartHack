import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  /// リワード広告をロードして表示します。
  /// [onUserEarnedReward]: ユーザーが広告を最後まで視聴して報酬を得た時のコールバック
  /// [onAdClosed]: 広告が閉じられた、またはロード/表示に失敗した時のコールバック
  static void showRewardedAd({
    required Function(int amount) onUserEarnedReward,
    required Function(bool hasEarnedReward) onAdClosed,
  }) {
    final adUnitId = AdConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('RewardedAd: adUnitId is empty');
      onAdClosed(false);
      return;
    }

    if (_isLoading) {
      debugPrint('RewardedAd: Already loading');
      return;
    }

    _isLoading = true;
    bool earnedReward = false;
    int rewardAmount = 1000;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _isLoading = false;
          _rewardedAd = ad;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
              _rewardedAd = null;
              onAdClosed(earnedReward);
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('RewardedAd failed to show: code=${error.code}, message=${error.message}');
              ad.dispose();
              _rewardedAd = null;
              onAdClosed(false);
            },
          );

          _rewardedAd!.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              earnedReward = true;
              final amount = (reward.amount > 0) ? reward.amount.toInt() : 1000;
              rewardAmount = amount;
              onUserEarnedReward(rewardAmount);
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          debugPrint('RewardedAd failed to load: code=${error.code}, message=${error.message}');
          _rewardedAd = null;
          onAdClosed(false);
        },
      ),
    );
  }
}
