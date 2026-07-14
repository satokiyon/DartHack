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
