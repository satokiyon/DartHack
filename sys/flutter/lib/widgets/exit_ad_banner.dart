import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// ExitAdBanner のバナー広告表示ウィジェット
class ExitAdBanner extends StatefulWidget {
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;

  /// テスト用のカスタム AdWidget ビルダー (Widgetテスト用DI)
  @visibleForTesting
  final Widget Function(BuildContext context, BannerAd ad)? testAdWidgetBuilder;

  const ExitAdBanner({
    super.key,
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.testAdWidgetBuilder,
  });

  @override
  State<ExitAdBanner> createState() => _ExitAdBannerState();
}

class _ExitAdBannerState extends State<ExitAdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdConfig.isMobilePlatform) {
      widget.onAdFailedToLoad?.call();
      return;
    }

    final adUnitId = AdConfig.bannerAdUnitId;
    if (adUnitId.isEmpty) {
      widget.onAdFailedToLoad?.call();
      return;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
              widget.onAdLoaded?.call();
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('ExitAdBanner failed to load: $error');
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isAdLoaded = false;
              });
              widget.onAdFailedToLoad?.call();
            }
          },
        ),
      );

      _bannerAd!.load();
    } catch (e, st) {
      debugPrint('ExitAdBanner load exception: $e\n$st');
      widget.onAdFailedToLoad?.call();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final childWidget = widget.testAdWidgetBuilder != null
        ? widget.testAdWidgetBuilder!(context, _bannerAd!)
        : AdWidget(ad: _bannerAd!);

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: childWidget,
    );
  }
}
