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

  group('calculatePermInventLayout', () {
    test('縦長画面または無効時は非表示（幅 0）', () {
      final portrait = calculatePermInventLayout(
        enabled: true,
        screenWidth: 400.0,
        screenHeight: 800.0,
        position: 'right',
        widthRatio: 0.28,
      );
      expect(portrait.isVisible, isFalse);
      expect(portrait.width, 0.0);
      expect(portrait.leftInset, 0.0);
      expect(portrait.rightInset, 0.0);
      expect(portrait.mapAreaWidth, 400.0);

      final disabled = calculatePermInventLayout(
        enabled: false,
        screenWidth: 1000.0,
        screenHeight: 600.0,
        position: 'right',
        widthRatio: 0.28,
      );
      expect(disabled.isVisible, isFalse);
      expect(disabled.width, 0.0);
    });

    test('横長大画面: 右配置 28% で希望幅そのまま採用', () {
      final res = calculatePermInventLayout(
        enabled: true,
        screenWidth: 1000.0,
        screenHeight: 600.0,
        position: 'right',
        widthRatio: 0.28,
      );
      expect(res.isVisible, isTrue);
      expect(res.width, closeTo(280.0, 0.01));
      expect(res.leftInset, 0.0);
      expect(res.rightInset, closeTo(280.0, 0.01));
      expect(res.mapAreaWidth, closeTo(720.0, 0.01));
      expect(res.padClampAvailableWidth, closeTo(720.0, 0.01));
    });

    test('横長画面: 左配置 30% + 左右 CmdPanel 130dp 差し引き', () {
      final res = calculatePermInventLayout(
        enabled: true,
        screenWidth: 1000.0,
        screenHeight: 600.0,
        position: 'left',
        widthRatio: 0.30,
        verticalCmdPanelWidth: 130.0,
      );
      expect(res.isVisible, isTrue);
      expect(res.leftInset, closeTo(300.0, 0.01));
      expect(res.rightInset, 0.0);
      expect(res.mapAreaWidth, closeTo(700.0, 0.01));
      expect(res.padClampAvailableWidth, closeTo(570.0, 0.01));
    });

    test('スマホ横持ち: マップ最小幅 300dp 確保のため縮小クランプされる', () {
      // 640 - 115(縦ステータス) - 300(マップ最小幅) = 225dp 上限
      // 希望 45% = 288dp -> 225dp にクランプ（140dp 以上なので表示維持）
      final res = calculatePermInventLayout(
        enabled: true,
        screenWidth: 640.0,
        screenHeight: 360.0,
        position: 'right',
        widthRatio: 0.45,
        statusRightWidth: 115.0,
      );
      expect(res.isVisible, isTrue);
      expect(res.width, closeTo(225.0, 0.01));
      expect(res.mapAreaWidth, closeTo(300.0, 0.01));
    });

    test('極小横幅: 最小可読幅 140dp 未満なら自動非表示', () {
      // 520 - 115 - 300 = 105dp < 140dp -> 非表示
      final res = calculatePermInventLayout(
        enabled: true,
        screenWidth: 520.0,
        screenHeight: 360.0,
        position: 'right',
        widthRatio: 0.28,
        statusRightWidth: 115.0,
      );
      expect(res.isVisible, isFalse);
      expect(res.width, 0.0);
      expect(res.mapAreaWidth, closeTo(405.0, 0.01));
    });
  });
}
