import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Menu & Map Button Keyboard Shift Calculation Tests', () {
    const keyboardHeight = 176.0;

    double calcKeyboardBottomShift({
      required bool isControllerVisible,
      required String controllerMode,
      required int layoutPattern,
      required String cmdPanelPosition,
    }) {
      final isKeyboardMode = isControllerVisible && controllerMode == 'keyboard';
      final isKeyboardAtBottom = isKeyboardMode && (layoutPattern == 1 || cmdPanelPosition != 'top');
      return isKeyboardAtBottom ? (keyboardHeight + 8.0) : 0.0;
    }

    double calcKeyboardTopShift({
      required bool isControllerVisible,
      required String controllerMode,
      required int layoutPattern,
      required String cmdPanelPosition,
    }) {
      final isKeyboardMode = isControllerVisible && controllerMode == 'keyboard';
      final isKeyboardAtTop = isKeyboardMode && (layoutPattern == 2 || cmdPanelPosition == 'top');
      return isKeyboardAtTop ? (keyboardHeight + 8.0) : 0.0;
    }

    test('パターン1でキーボード表示時、下部シフトが184px（キーボード176px+マージン8px）になり上部シフトは0pxであること', () {
      final bottomShift = calcKeyboardBottomShift(
        isControllerVisible: true,
        controllerMode: 'keyboard',
        layoutPattern: 1,
        cmdPanelPosition: 'bottom',
      );
      final topShift = calcKeyboardTopShift(
        isControllerVisible: true,
        controllerMode: 'keyboard',
        layoutPattern: 1,
        cmdPanelPosition: 'bottom',
      );

      expect(bottomShift, equals(184.0));
      expect(topShift, equals(0.0));
    });

    test('パターン2でキーボード表示時、上部シフトが184px（キーボード176px+マージン8px）になり下部シフトは0pxであること', () {
      final bottomShift = calcKeyboardBottomShift(
        isControllerVisible: true,
        controllerMode: 'keyboard',
        layoutPattern: 2,
        cmdPanelPosition: 'top',
      );
      final topShift = calcKeyboardTopShift(
        isControllerVisible: true,
        controllerMode: 'keyboard',
        layoutPattern: 2,
        cmdPanelPosition: 'top',
      );

      expect(bottomShift, equals(0.0));
      expect(topShift, equals(184.0));
    });

    test('移動パッド（pad）モード時は、キーボードシフトが適用されないこと', () {
      final bottomShift1 = calcKeyboardBottomShift(
        isControllerVisible: true,
        controllerMode: 'pad',
        layoutPattern: 1,
        cmdPanelPosition: 'bottom',
      );
      final topShift2 = calcKeyboardTopShift(
        isControllerVisible: true,
        controllerMode: 'pad',
        layoutPattern: 2,
        cmdPanelPosition: 'top',
      );

      expect(bottomShift1, equals(0.0));
      expect(topShift2, equals(0.0));
    });

    test('コントローラ非表示（isControllerVisible == false）時は、キーボードシフトが0pxであること', () {
      final bottomShift1 = calcKeyboardBottomShift(
        isControllerVisible: false,
        controllerMode: 'keyboard',
        layoutPattern: 1,
        cmdPanelPosition: 'bottom',
      );
      final topShift2 = calcKeyboardTopShift(
        isControllerVisible: false,
        controllerMode: 'keyboard',
        layoutPattern: 2,
        cmdPanelPosition: 'top',
      );

      expect(bottomShift1, equals(0.0));
      expect(topShift2, equals(0.0));
    });
  });
}

