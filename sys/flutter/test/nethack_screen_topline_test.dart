import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_screen.dart';

void main() {
  group('NetHackScreen topline lifecycle tests', () {
    test('clearWindow on WIN_MESSAGE clears residual topline', () {
      final screen = NetHackScreen();
      const messageWinId = 1;
      const atrNoHistory = 0x0020;

      screen.createWindow(messageWinId, NetHackScreen.nhwMessage);
      screen.putString(messageWinId, atrNoHistory, '床 (移動先)');
      expect(screen.topline, '床 (移動先)');

      screen.clearWindow(messageWinId);
      expect(screen.topline, isNull);
    });

    test('clearWindow on WIN_MESSAGE also clears topline set via putMixedWithTile', () {
      final screen = NetHackScreen();
      const messageWinId = 1;
      const atrNoHistory = 0x0020;

      screen.createWindow(messageWinId, NetHackScreen.nhwMessage);
      screen.putMixedWithTile(messageWinId, atrNoHistory, 10, 'ドア');
      expect(screen.topline, 'ドア');

      screen.clearWindow(messageWinId);
      expect(screen.topline, isNull);
    });
  });
}
