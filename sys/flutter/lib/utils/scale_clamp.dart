import 'package:flutter/foundation.dart';

@immutable
class PadClampResult {
  final double dpadEffectiveScale;
  final double shortcutPadEffectiveScale;
  final bool isClamped;

  const PadClampResult({
    required this.dpadEffectiveScale,
    required this.shortcutPadEffectiveScale,
    required this.isClamped,
  });
}

PadClampResult calculatePadClamp({
  required double dpadScale,
  required double shortcutPadScale,
  required double screenWidth,
  double baseSize = 150.0,
  double minGap = 8.0,
}) {
  final availableWidth = screenWidth - minGap;
  final combinedScaledWidth =
      baseSize * dpadScale + baseSize * shortcutPadScale;

  if (combinedScaledWidth > availableWidth) {
    final equalScale = availableWidth / (2 * baseSize);
    return PadClampResult(
      dpadEffectiveScale: equalScale,
      shortcutPadEffectiveScale: equalScale,
      isClamped: true,
    );
  }

  return PadClampResult(
    dpadEffectiveScale: dpadScale,
    shortcutPadEffectiveScale: shortcutPadScale,
    isClamped: false,
  );
}

@immutable
class PermInventLayoutResult {
  final double width;
  final double leftInset;
  final double rightInset;
  final double mapAreaWidth;
  final double padClampAvailableWidth;

  const PermInventLayoutResult({
    required this.width,
    required this.leftInset,
    required this.rightInset,
    required this.mapAreaWidth,
    required this.padClampAvailableWidth,
  });

  bool get isVisible => width > 0.0;
}

/// 常時表示インベントリ (`perm_invent`) の実効幅とマップ領域サイズを算出する純関数
PermInventLayoutResult calculatePermInventLayout({
  required bool enabled,
  required double screenWidth,
  required double screenHeight,
  required String position,
  required double widthRatio,
  double statusLeftWidth = 0.0,
  double statusRightWidth = 0.0,
  double verticalCmdPanelWidth = 0.0,
  double minMapWidth = 300.0,
  double minReadableWidth = 140.0,
}) {
  final verticalStatusWidth = statusLeftWidth + statusRightWidth;
  double effectiveWidth = 0.0;

  if (enabled && screenWidth > screenHeight) {
    final clampedRatio = widthRatio.clamp(0.20, 0.45);
    final desired = screenWidth * clampedRatio;
    final maxAvailable = screenWidth - verticalStatusWidth - minMapWidth;
    final candidate = desired > maxAvailable ? maxAvailable : desired;
    if (candidate >= minReadableWidth) {
      effectiveWidth = candidate;
    }
  }

  final leftInset = position == 'left' ? effectiveWidth : 0.0;
  final rightInset = position == 'right' ? effectiveWidth : 0.0;
  final mapAreaWidth =
      (screenWidth - verticalStatusWidth - effectiveWidth).clamp(0.0, double.infinity);
  final padClampAvailableWidth =
      (mapAreaWidth - verticalCmdPanelWidth).clamp(0.0, double.infinity);

  return PermInventLayoutResult(
    width: effectiveWidth,
    leftInset: leftInset,
    rightInset: rightInset,
    mapAreaWidth: mapAreaWidth,
    padClampAvailableWidth: padClampAvailableWidth,
  );
}
