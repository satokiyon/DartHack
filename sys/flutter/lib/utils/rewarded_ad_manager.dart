import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// 表示可能なリワード広告の抽象インターフェース (テストDI用)
abstract class DisplayableRewardedAd {
  void setFullScreenContentCallback({
    required VoidCallback onDismissed,
    required void Function(int code, String message) onFailedToShow,
  });
  void show({
    required void Function(int amount) onUserEarnedReward,
  });
  void dispose();
}

/// Google Mobile Ads 公式 SDK の RewardedAd ラッパー実装
class GoogleMobileAdsRewardedAdWrapper implements DisplayableRewardedAd {
  final RewardedAd ad;
  bool _isDisposed = false;
  GoogleMobileAdsRewardedAdWrapper(this.ad);

  @override
  void setFullScreenContentCallback({
    required VoidCallback onDismissed,
    required void Function(int code, String message) onFailedToShow,
  }) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd _) {
        dispose();
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd _, AdError error) {
        dispose();
        onFailedToShow(error.code, error.message);
      },
    );
  }

  @override
  void show({required void Function(int amount) onUserEarnedReward}) {
    ad.show(
      onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
        final amount = (reward.amount > 0) ? reward.amount.toInt() : 1000;
        onUserEarnedReward(amount);
      },
    );
  }

  /// 二重 dispose を防ぐため冪等にしている
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    ad.dispose();
  }
}

/// リワード広告プラットフォーム操作の抽象インターフェース (テストDI用)
abstract class RewardedAdPlatformAdapter {
  Future<void> initializeMobileAds();
  Future<void> startPreloader({
    required String preloadId,
    required String adUnitId,
    required PreloadCallback callback,
  });
  Future<DisplayableRewardedAd?> pollPreloadedAd(String preloadId);
  void loadAd({
    required String adUnitId,
    required void Function(DisplayableRewardedAd ad) onAdLoaded,
    required void Function(int code, String message) onAdFailedToLoad,
  });
}

/// Google Mobile Ads 公式 SDK による標準アダプタ実装
class DefaultRewardedAdPlatformAdapter implements RewardedAdPlatformAdapter {
  @override
  Future<void> initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<void> startPreloader({
    required String preloadId,
    required String adUnitId,
    required PreloadCallback callback,
  }) async {
    await RewardedAdPreloader.start(
      preloadId: preloadId,
      preloadConfiguration: PreloadConfiguration(
        adUnitId: adUnitId,
        bufferSize: 1,
      ),
      callback: callback,
    );
  }

  @override
  Future<DisplayableRewardedAd?> pollPreloadedAd(String preloadId) async {
    try {
      final ad = await RewardedAdPreloader.pollAd(preloadId);
      if (ad != null) {
        return GoogleMobileAdsRewardedAdWrapper(ad);
      }
    } catch (e, st) {
      debugPrint('RewardedAdPreloader.pollAd failed: $e\n$st');
    }
    return null;
  }

  @override
  void loadAd({
    required String adUnitId,
    required void Function(DisplayableRewardedAd ad) onAdLoaded,
    required void Function(int code, String message) onAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          onAdLoaded(GoogleMobileAdsRewardedAdWrapper(ad));
        },
        onAdFailedToLoad: (LoadAdError error) {
          onAdFailedToLoad(error.code, error.message);
        },
      ),
    );
  }
}

/// 階段昇降時などのリワード広告を統合管理するマネージャ
///
/// ## C コアとの応答契約（重要）
/// 呼び出し側（main.dart）は、次のいずれかのタイミングで C コアへ
/// `new_level_rest_result` を **ちょうど 1 回** 送信する。
/// - [showRewardedAd] の `onUserEarnedReward(amount)` が呼ばれたとき（報酬あり）
/// - [showRewardedAd] の `onAdClosed(false)` が呼ばれたとき（報酬なし・失敗）
///
/// そのため本マネージャは 1 回の表示要求（セッション）ごとに
/// 「報酬通知」と「onAdClosed(false)」が合わせて最大 1 回しか起きないことを保証する。
/// - 応答未送信のセッションが進行中に重複要求が来た場合は、コールバックを一切呼ばずに無視する
///   （進行中セッションが必ず応答するため、ここで応答すると C コアへの二重送信になる）。
/// - ロード段階（pollAd / loadAd）が [loadTimeout] 以内に終わらない場合は
///   `onAdClosed(false)` で打ち切り、C コアのハングを防ぐ。
class RewardedAdManager {
  static const String preloadId = 'kaidan_rewarded_preload';

  /// ロード段階（pollAd + loadAd フォールバック）の上限時間
  static const Duration defaultLoadTimeout = Duration(seconds: 15);

  static RewardedAdPlatformAdapter _adapter = DefaultRewardedAdPlatformAdapter();
  static bool _isPreloaderStarted = false;
  static Duration _loadTimeout = defaultLoadTimeout;

  /// 応答（報酬通知 or onAdClosed(false)）が未送信のセッションID。null なら進行中なし
  static int? _pendingSessionId;
  static int _sessionSeq = 0;

  /// 現在の応答待ちセッションが存在するか（テスト・診断用）
  @visibleForTesting
  static bool get hasPendingSession => _pendingSessionId != null;

  /// テスト用のアダプタ注入
  @visibleForTesting
  static void setAdapterForTesting(
    RewardedAdPlatformAdapter adapter, {
    Duration loadTimeout = defaultLoadTimeout,
  }) {
    _adapter = adapter;
    _loadTimeout = loadTimeout;
    _isPreloaderStarted = false;
    _pendingSessionId = null;
  }

  /// テスト用の状態リセット
  @visibleForTesting
  static void resetForTesting() {
    _adapter = DefaultRewardedAdPlatformAdapter();
    _loadTimeout = defaultLoadTimeout;
    _isPreloaderStarted = false;
    _pendingSessionId = null;
  }

  /// アプリ起動時の AdMob 初期化およびリワード広告の先行プリロード
  static Future<void> initializeAndPreload() async {
    // 非モバイル環境ではネイティブ SDK が存在しないため初期化自体を行わない
    if (!AdConfig.isMobilePlatform) return;
    try {
      await _adapter.initializeMobileAds();
      startPreloading();
    } catch (e, st) {
      debugPrint('RewardedAdManager: initializeAndPreload failed: $e\n$st');
    }
  }

  /// バックグラウンドでのリワード広告プリロード開始
  static void startPreloading() {
    if (_isPreloaderStarted) return;
    if (!AdConfig.isMobilePlatform) return;

    final adUnitId = AdConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    _isPreloaderStarted = true;
    _adapter.startPreloader(
      preloadId: preloadId,
      adUnitId: adUnitId,
      callback: PreloadCallback(
        onAdPreloaded: (id, info) {
          debugPrint('RewardedAdManager: Preload succeeded for id=$id');
        },
        onAdsExhausted: (id) {
          debugPrint('RewardedAdManager: Preloaded ads exhausted for id=$id');
        },
        onAdFailedToPreload: (id, error) {
          debugPrint('RewardedAdManager: Preload failed for id=$id: code=${error.code}, message=${error.message}');
        },
      ),
    ).catchError((Object e, StackTrace st) {
      debugPrint('RewardedAdManager: startPreloader error: $e\n$st');
      _isPreloaderStarted = false;
    });
  }

  /// リワード広告を表示します。
  ///
  /// 応答契約はクラスのドキュメントを参照。
  /// [onUserEarnedReward]: 報酬を獲得した時のコールバック（セッション内で最大 1 回）
  /// [onAdClosed]: 広告が閉じられた、またはロード/表示に失敗・タイムアウトした時のコールバック
  ///   （セッション内で最大 1 回。報酬通知済みの場合は true で呼ばれる）
  static void showRewardedAd({
    required void Function(int amount) onUserEarnedReward,
    required void Function(bool hasEarnedReward) onAdClosed,
  }) {
    if (_pendingSessionId != null) {
      // 進行中セッションが応答を返すので、ここでは何も通知しない（二重応答防止）
      debugPrint('RewardedAdManager: Duplicate request ignored (session $_pendingSessionId pending)');
      return;
    }

    if (!AdConfig.isMobilePlatform) {
      debugPrint('RewardedAdManager: Non-mobile platform, skipping ad.');
      onAdClosed(false);
      return;
    }

    final adUnitId = AdConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('RewardedAdManager: adUnitId is empty');
      onAdClosed(false);
      return;
    }

    final sessionId = ++_sessionSeq;
    _pendingSessionId = sessionId;

    var isClosed = false; // onAdClosed 呼び出し済み
    var isResultDelivered = false; // 報酬通知 or onAdClosed(false) 済み（C コアへ応答済み）
    var earnedReward = false;
    var isPresenting = false; // 広告表示段階に入ったか
    Timer? loadTimer;

    void releasePendingIfMine() {
      if (_pendingSessionId == sessionId) {
        _pendingSessionId = null;
      }
    }

    void completeClose(bool earned) {
      if (isClosed) return;
      isClosed = true;
      loadTimer?.cancel();
      isResultDelivered = true;
      releasePendingIfMine();
      try {
        onAdClosed(earned);
      } catch (e, st) {
        debugPrint('RewardedAdManager: Exception in onAdClosed callback: $e\n$st');
      }
    }

    void presentAd(DisplayableRewardedAd ad) {
      if (isClosed) {
        // タイムアウト後に遅れて届いた広告は表示せず破棄する
        debugPrint('RewardedAdManager: Late ad arrived after session closed, disposing.');
        ad.dispose();
        return;
      }
      isPresenting = true;
      loadTimer?.cancel();
      try {
        ad.setFullScreenContentCallback(
          onDismissed: () {
            completeClose(earnedReward);
          },
          onFailedToShow: (int code, String message) {
            debugPrint('RewardedAd failed to show: code=$code, message=$message');
            completeClose(earnedReward);
          },
        );

        ad.show(
          onUserEarnedReward: (int amount) {
            if (isResultDelivered) return; // 応答済みセッションでは報酬を二重通知しない
            earnedReward = true;
            isResultDelivered = true;
            // 報酬通知の時点で C コアへ応答済みとなるため、閉じるコールバックが失われても
            // 次回の表示要求をブロックしないよう、ここで応答待ち状態を解除する
            releasePendingIfMine();
            try {
              onUserEarnedReward(amount);
            } catch (e, st) {
              debugPrint('RewardedAdManager: Exception in onUserEarnedReward: $e\n$st');
            }
          },
        );
      } catch (e, st) {
        debugPrint('RewardedAdManager: Exception in presentAd: $e\n$st');
        ad.dispose();
        completeClose(earnedReward);
      }
    }

    void fallbackLoadAndShow() {
      if (isClosed) return;
      try {
        _adapter.loadAd(
          adUnitId: adUnitId,
          onAdLoaded: presentAd,
          onAdFailedToLoad: (int code, String message) {
            debugPrint('RewardedAd failed to load: code=$code, message=$message');
            completeClose(false);
          },
        );
      } catch (e, st) {
        debugPrint('RewardedAdManager: Exception in fallbackLoadAndShow: $e\n$st');
        completeClose(false);
      }
    }

    // ロード段階の監視タイマー（表示段階に入ったら解除）
    loadTimer = Timer(_loadTimeout, () {
      if (!isPresenting && !isClosed) {
        debugPrint('RewardedAdManager: Load timed out after ${_loadTimeout.inMilliseconds}ms');
        completeClose(false);
      }
    });

    // まず Preloader (pollAd) を試行し、なければ通常の loadAd へフォールバック
    _adapter.pollPreloadedAd(preloadId).then((DisplayableRewardedAd? preloadedAd) {
      if (preloadedAd != null) {
        debugPrint('RewardedAdManager: Using preloaded ad from pollAd');
        presentAd(preloadedAd);
      } else {
        debugPrint('RewardedAdManager: Preloaded ad not ready, falling back to loadAd');
        fallbackLoadAndShow();
      }
    }).catchError((Object e, StackTrace st) {
      debugPrint('RewardedAdManager: pollPreloadedAd error, falling back to loadAd: $e\n$st');
      fallbackLoadAndShow();
    });
  }
}
