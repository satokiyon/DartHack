import 'package:flutter/widgets.dart';

/// ウィンドウリサイズ時に不要なキャッシュミスや GPU テクスチャ再生成を防ぐため、
/// ディスプレイの物理幅を基準とした安定した `cacheWidth` を算出する。
int computeStableCacheWidth(
  BuildContext context, {
  double widthFactor = 1.0,
  int maxWidth = 1920,
}) {
  final view = View.maybeOf(context);
  final double physicalDisplayWidth;
  if (view != null && view.display.size.width > 0) {
    physicalDisplayWidth = view.display.size.width;
  } else {
    final mq = MediaQuery.of(context);
    physicalDisplayWidth = mq.size.width * mq.devicePixelRatio;
  }
  final computed = (physicalDisplayWidth * widthFactor).round();
  return computed.clamp(1, maxWidth);
}
