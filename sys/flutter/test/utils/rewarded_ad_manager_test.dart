import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:darthack/config/ad_config.dart';
import 'package:darthack/utils/rewarded_ad_manager.dart';

/// 表示時の振る舞いを切り替えられるフェイク広告
enum FakeShowBehavior {
  /// 報酬付与 → 閉じる
  earnAndDismiss,

  /// 報酬なしで閉じる（途中スキップ）
  dismissWithoutReward,

  /// 表示失敗
  failToShow,

  /// 報酬付与後、閉じるコールバックが失われる（SDK 側の異常を模擬）
  earnAndLoseDismiss,

  /// 何も起きない（表示中のまま）
  hang,
}

class FakeDisplayableRewardedAd implements DisplayableRewardedAd {
  VoidCallback? onDismissed;
  void Function(int code, String message)? onFailedToShow;
  int disposeCount = 0;
  bool isShown = false;
  final int rewardAmountToEarn;
  final FakeShowBehavior behavior;

  FakeDisplayableRewardedAd({
    this.rewardAmountToEarn = 1000,
    this.behavior = FakeShowBehavior.earnAndDismiss,
  });

  bool get isDisposed => disposeCount > 0;

  @override
  void setFullScreenContentCallback({
    required VoidCallback onDismissed,
    required void Function(int code, String message) onFailedToShow,
  }) {
    this.onDismissed = onDismissed;
    this.onFailedToShow = onFailedToShow;
  }

  @override
  void show({required void Function(int amount) onUserEarnedReward}) {
    isShown = true;
    switch (behavior) {
      case FakeShowBehavior.earnAndDismiss:
        onUserEarnedReward(rewardAmountToEarn);
        onDismissed?.call();
      case FakeShowBehavior.dismissWithoutReward:
        onDismissed?.call();
      case FakeShowBehavior.failToShow:
        onFailedToShow?.call(1, 'Simulated display failure');
      case FakeShowBehavior.earnAndLoseDismiss:
        onUserEarnedReward(rewardAmountToEarn);
      case FakeShowBehavior.hang:
        break;
    }
  }

  @override
  void dispose() {
    disposeCount++;
  }
}

class FakeRewardedAdPlatformAdapter implements RewardedAdPlatformAdapter {
  bool initialized = false;
  int startPreloaderCalls = 0;
  PreloadCallback? lastPreloadCallback;

  DisplayableRewardedAd? nextPollAd;
  bool pollShouldThrow = false;

  DisplayableRewardedAd? nextLoadAd;
  bool loadShouldFail = false;
  int loadAdCalls = 0;

  /// true の場合 loadAd のコールバックを即時に呼ばず保留する（ネットワーク停滞を模擬）
  bool holdLoadCallback = false;
  void Function(DisplayableRewardedAd ad)? heldOnAdLoaded;

  @override
  Future<void> initializeMobileAds() async {
    initialized = true;
  }

  @override
  Future<void> startPreloader({
    required String preloadId,
    required String adUnitId,
    required PreloadCallback callback,
  }) async {
    startPreloaderCalls++;
    lastPreloadCallback = callback;
  }

  @override
  Future<DisplayableRewardedAd?> pollPreloadedAd(String preloadId) async {
    if (pollShouldThrow) {
      throw Exception('Simulated poll exception');
    }
    final ad = nextPollAd;
    nextPollAd = null; // pollAd は 1 回取り出すと消費される
    return ad;
  }

  @override
  void loadAd({
    required String adUnitId,
    required void Function(DisplayableRewardedAd ad) onAdLoaded,
    required void Function(int code, String message) onAdFailedToLoad,
  }) {
    loadAdCalls++;
    if (holdLoadCallback) {
      heldOnAdLoaded = onAdLoaded;
      return;
    }
    if (loadShouldFail || nextLoadAd == null) {
      onAdFailedToLoad(2, 'Simulated load failure');
    } else {
      onAdLoaded(nextLoadAd!);
    }
  }
}

/// main.dart と同じ規則で「C コアへの応答送信回数」を数えるレコーダー
class CoreResultRecorder {
  final List<int> sentResults = <int>[];
  final List<bool> closedCalls = <bool>[];

  void onUserEarnedReward(int amount) => sentResults.add(amount);

  void onAdClosed(bool hasEarned) {
    closedCalls.add(hasEarned);
    if (!hasEarned) sentResults.add(0);
  }

  void show() => RewardedAdManager.showRewardedAd(
        onUserEarnedReward: onUserEarnedReward,
        onAdClosed: onAdClosed,
      );
}

Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRewardedAdPlatformAdapter fakeAdapter;

  setUp(() {
    fakeAdapter = FakeRewardedAdPlatformAdapter();
    RewardedAdManager.setAdapterForTesting(
      fakeAdapter,
      loadTimeout: const Duration(milliseconds: 50),
    );
    AdConfig.isAndroidOverride = true;
    AdConfig.isIOSOverride = false;
  });

  tearDown(() {
    RewardedAdManager.resetForTesting();
    AdConfig.isAndroidOverride = null;
    AdConfig.isIOSOverride = null;
    AdConfig.rewardedAdUnitIdOverride = null;
  });

  group('初期化とプリロード', () {
    test('initializeAndPreload() で SDK 初期化とプリロードが開始され、重複開始しないこと', () async {
      await RewardedAdManager.initializeAndPreload();

      expect(fakeAdapter.initialized, isTrue);
      expect(fakeAdapter.startPreloaderCalls, 1);
      expect(fakeAdapter.lastPreloadCallback, isNotNull);

      RewardedAdManager.startPreloading();
      expect(fakeAdapter.startPreloaderCalls, 1);
    });

    test('非モバイル環境では SDK 初期化自体を行わないこと', () async {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      await RewardedAdManager.initializeAndPreload();

      expect(fakeAdapter.initialized, isFalse);
      expect(fakeAdapter.startPreloaderCalls, 0);
    });
  });

  group('C コアへの応答はちょうど 1 回', () {
    test('非モバイル環境: 即座に報酬なしで 1 回応答', () {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;
      final rec = CoreResultRecorder()..show();

      expect(rec.sentResults, <int>[0]);
      expect(RewardedAdManager.hasPendingSession, isFalse);
    });

    test('広告IDが空: 即座に報酬なしで 1 回応答', () {
      AdConfig.rewardedAdUnitIdOverride = '';
      final rec = CoreResultRecorder()..show();

      expect(rec.sentResults, <int>[0]);
    });

    test('pollAd 成功: プリロード済み広告を表示し、報酬額で 1 回応答（loadAd は呼ばない）', () async {
      final ad = FakeDisplayableRewardedAd(rewardAmountToEarn: 500);
      fakeAdapter.nextPollAd = ad;
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(ad.isShown, isTrue);
      expect(rec.sentResults, <int>[500]);
      expect(rec.closedCalls, <bool>[true]);
      expect(fakeAdapter.loadAdCalls, 0);
      expect(RewardedAdManager.hasPendingSession, isFalse);
    });

    test('pollAd が null: loadAd にフォールバックして 1 回応答', () async {
      final ad = FakeDisplayableRewardedAd(rewardAmountToEarn: 1000);
      fakeAdapter.nextLoadAd = ad;
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(fakeAdapter.loadAdCalls, 1);
      expect(rec.sentResults, <int>[1000]);
    });

    test('pollAd が例外: loadAd にフォールバックして 1 回応答', () async {
      fakeAdapter.pollShouldThrow = true;
      fakeAdapter.nextLoadAd = FakeDisplayableRewardedAd(rewardAmountToEarn: 2000);
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(fakeAdapter.loadAdCalls, 1);
      expect(rec.sentResults, <int>[2000]);
    });

    test('loadAd も失敗: 報酬なしで 1 回応答', () async {
      fakeAdapter.loadShouldFail = true;
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(rec.sentResults, <int>[0]);
      expect(RewardedAdManager.hasPendingSession, isFalse);
    });

    test('表示失敗: 報酬なしで 1 回応答', () async {
      final ad = FakeDisplayableRewardedAd(behavior: FakeShowBehavior.failToShow);
      fakeAdapter.nextPollAd = ad;
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(rec.sentResults, <int>[0]);
    });

    test('報酬なしで閉じた: 報酬なしで 1 回応答', () async {
      fakeAdapter.nextPollAd = FakeDisplayableRewardedAd(behavior: FakeShowBehavior.dismissWithoutReward);
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(rec.sentResults, <int>[0]);
      expect(rec.closedCalls, <bool>[false]);
    });
  });

  group('重複要求（二重応答の防止）', () {
    test('応答待ちセッション中の重複要求はコールバックを一切呼ばず無視されること', () async {
      fakeAdapter.nextPollAd = FakeDisplayableRewardedAd(behavior: FakeShowBehavior.hang);
      final first = CoreResultRecorder()..show();
      final second = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(second.sentResults, isEmpty);
      expect(second.closedCalls, isEmpty);
      expect(first.sentResults, isEmpty); // 1 回目は表示中のまま
      expect(RewardedAdManager.hasPendingSession, isTrue);
    });

    test('報酬通知後に閉じるコールバックが失われても、次回の要求はブロックされないこと', () async {
      fakeAdapter.nextPollAd = FakeDisplayableRewardedAd(
        rewardAmountToEarn: 300,
        behavior: FakeShowBehavior.earnAndLoseDismiss,
      );
      final first = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(first.sentResults, <int>[300]);
      expect(RewardedAdManager.hasPendingSession, isFalse);

      // 次の階段イベント
      fakeAdapter.nextPollAd = FakeDisplayableRewardedAd(rewardAmountToEarn: 400);
      final second = CoreResultRecorder()..show();
      await flushMicrotasks();

      expect(second.sentResults, <int>[400]);
      expect(first.sentResults, <int>[300]); // 1 回目へ追加の応答は無い
    });
  });

  group('タイムアウト（C コアのハング防止）', () {
    test('loadAd のコールバックが返らない場合、タイムアウトで報酬なし 1 回応答すること', () async {
      fakeAdapter.holdLoadCallback = true;
      final rec = CoreResultRecorder()..show();
      await flushMicrotasks();
      expect(rec.sentResults, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(rec.sentResults, <int>[0]);
      expect(RewardedAdManager.hasPendingSession, isFalse);
    });

    test('タイムアウト後に遅れて届いた広告は表示されず破棄され、追加の応答もないこと', () async {
      fakeAdapter.holdLoadCallback = true;
      final rec = CoreResultRecorder()..show();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(rec.sentResults, <int>[0]);

      final lateAd = FakeDisplayableRewardedAd(rewardAmountToEarn: 999);
      fakeAdapter.heldOnAdLoaded!(lateAd);

      expect(lateAd.isShown, isFalse);
      expect(lateAd.isDisposed, isTrue);
      expect(rec.sentResults, <int>[0]);
    });

    test('表示段階に入った後はタイムアウトしない（視聴中に打ち切らない）こと', () async {
      final ad = FakeDisplayableRewardedAd(behavior: FakeShowBehavior.hang);
      fakeAdapter.nextPollAd = ad;
      final rec = CoreResultRecorder()..show();
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(ad.isShown, isTrue);
      expect(rec.sentResults, isEmpty);

      // ユーザーが視聴を終えて閉じる
      ad.onDismissed!();
      expect(rec.sentResults, <int>[0]);
    });
  });
}
