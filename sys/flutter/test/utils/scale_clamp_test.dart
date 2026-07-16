import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/scale_clamp.dart';

void main() {
  group('calculatePadClamp', () {
    test('クランプなし: 360px 端末 + D-Pad 1.0 + ShortcutPad 1.0', () {
      final result = calculatePadClamp(
        dpadScale: 1.0,
        shortcutPadScale: 1.0,
        screenWidth: 360.0,
      );
      expect(result.dpadEffectiveScale, 1.0);
      expect(result.shortcutPadEffectiveScale, 1.0);
      expect(result.isClamped, false);
    });

    test('クランプ発動: 360px 端末 + D-Pad 1.5 + ShortcutPad 1.5', () {
      final result = calculatePadClamp(
        dpadScale: 1.5,
        shortcutPadScale: 1.5,
        screenWidth: 360.0,
      );
      expect(result.dpadEffectiveScale, closeTo(1.1733, 0.001));
      expect(result.shortcutPadEffectiveScale, closeTo(1.1733, 0.001));
      expect(result.isClamped, true);
    });

    test('クランプなし（非対称）: 360px 端末 + D-Pad 1.5 + ShortcutPad 0.6', () {
      final result = calculatePadClamp(
        dpadScale: 1.5,
        shortcutPadScale: 0.6,
        screenWidth: 360.0,
      );
      expect(result.dpadEffectiveScale, 1.5);
      expect(result.shortcutPadEffectiveScale, 0.6);
      expect(result.isClamped, false);
    });

    test('クランプなし: 600px 端末 + 両 1.5', () {
      final result = calculatePadClamp(
        dpadScale: 1.5,
        shortcutPadScale: 1.5,
        screenWidth: 600.0,
      );
      expect(result.dpadEffectiveScale, 1.5);
      expect(result.shortcutPadEffectiveScale, 1.5);
      expect(result.isClamped, false);
    });

    test('クランプなし（極小）: 360px 端末 + 両 0.6', () {
      final result = calculatePadClamp(
        dpadScale: 0.6,
        shortcutPadScale: 0.6,
        screenWidth: 360.0,
      );
      expect(result.dpadEffectiveScale, 0.6);
      expect(result.shortcutPadEffectiveScale, 0.6);
      expect(result.isClamped, false);
    });

    test('境界値: combinedScaledWidth が availableWidth 以下', () {
      final result = calculatePadClamp(
        dpadScale: 1.1733,
        shortcutPadScale: 1.1733,
        screenWidth: 360.0,
      );
      expect(result.isClamped, false);
    });

    test('カスタム minGap: minGap 16px で 360px 端末 + 両 1.5', () {
      final result = calculatePadClamp(
        dpadScale: 1.5,
        shortcutPadScale: 1.5,
        screenWidth: 360.0,
        minGap: 16.0,
      );
      expect(result.dpadEffectiveScale, closeTo(1.1466, 0.001));
      expect(result.shortcutPadEffectiveScale, closeTo(1.1466, 0.001));
      expect(result.isClamped, true);
    });

    test('タブレット: 800px 端末 + 両 1.5', () {
      final result = calculatePadClamp(
        dpadScale: 1.5,
        shortcutPadScale: 1.5,
        screenWidth: 800.0,
      );
      expect(result.dpadEffectiveScale, 1.5);
      expect(result.shortcutPadEffectiveScale, 1.5);
      expect(result.isClamped, false);
    });

    test('極小画面: 300px 端末 + 両 1.0', () {
      final result = calculatePadClamp(
        dpadScale: 1.0,
        shortcutPadScale: 1.0,
        screenWidth: 300.0,
      );
      expect(result.dpadEffectiveScale, closeTo(0.9733, 0.001));
      expect(result.shortcutPadEffectiveScale, closeTo(0.9733, 0.001));
      expect(result.isClamped, true);
    });
  });
}
