import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/input/hardware_key_router.dart';

void main() {
  group('HardwareKeyRouter Tests', () {
    test('normalizeCharacter should convert fullwidth to halfwidth', () {
      expect(HardwareKeyRouter.normalizeCharacter('　'), equals(' '));
      expect(HardwareKeyRouter.normalizeCharacter('ａ'), equals('a'));
      expect(HardwareKeyRouter.normalizeCharacter('Ｚ'), equals('Z'));
      expect(HardwareKeyRouter.normalizeCharacter('１'), equals('1'));
      expect(HardwareKeyRouter.normalizeCharacter('＃'), equals('#'));
      expect(HardwareKeyRouter.normalizeCharacter('a'), equals('a'));
    });

    test('Game mode with number_pad == 0 (Traditional NetHack)', () {
      // 矢印キー
      final upEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: upEvent, context: KeyInputContext.game, numberPadMode: 0),
        equals(const SendKey(107, 'k')),
      );

      // Shift + 矢印キー (大文字走り)
      expect(
        HardwareKeyRouter.route(event: upEvent, context: KeyInputContext.game, numberPadMode: 0, isShiftPressed: true),
        equals(const SendKey(75, 'K')),
      );

      // テンキー 7 (y), 8 (k), 9 (u), 5 (.)
      final numpad7 = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.numpad7,
        logicalKey: LogicalKeyboardKey.numpad7,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: numpad7, context: KeyInputContext.game, numberPadMode: 0),
        equals(const SendKey(121, 'y')),
      );

      final numpad5 = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.numpad5,
        logicalKey: LogicalKeyboardKey.numpad5,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: numpad5, context: KeyInputContext.game, numberPadMode: 0),
        equals(const SendKey(46, '.')),
      );

      // 通常文字 '#'
      final hashEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit3,
        logicalKey: LogicalKeyboardKey.numberSign,
        character: '#',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: hashEvent, context: KeyInputContext.game, numberPadMode: 0),
        equals(const SendKey(35, '#')),
      );
    });

    test('Game mode with number_pad == 1 (Numpad movement)', () {
      final upEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: upEvent, context: KeyInputContext.game, numberPadMode: 1),
        equals(const SendKey(56, '8')),
      );

      final numpad7 = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.numpad7,
        logicalKey: LogicalKeyboardKey.numpad7,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: numpad7, context: KeyInputContext.game, numberPadMode: 1),
        equals(const SendKey(55, '7')),
      );
    });

    test('Game mode with Control key (Ctrl+P, Ctrl+D)', () {
      final keyP = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyP,
        logicalKey: LogicalKeyboardKey.keyP,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyP, context: KeyInputContext.game, isControlPressed: true),
        equals(const SendKey(16, 'Ctrl+P')),
      );

      final keyD = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyD,
        logicalKey: LogicalKeyboardKey.keyD,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyD, context: KeyInputContext.game, isControlPressed: true),
        equals(const SendKey(4, 'Ctrl+D')),
      );
    });

    test('YN Prompt handling', () {
      // 'y' in 'yn'
      final yEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyY,
        logicalKey: LogicalKeyboardKey.keyY,
        character: 'y',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: yEvent, context: KeyInputContext.yn, ynChoices: 'yn'),
        equals(const SendYn(121)),
      );

      // 'y' in 'YN' (実在ケース 'Y' 89 に正規化)
      expect(
        HardwareKeyRouter.route(event: yEvent, context: KeyInputContext.yn, ynChoices: 'YN'),
        equals(const SendYn(89)),
      );

      // 'a' in 'ynaq'
      final aEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: aEvent, context: KeyInputContext.yn, ynChoices: 'ynaq'),
        equals(const SendYn(97)),
      );

      // 'a' in 'yn' (無効なキーは SwallowKey)
      expect(
        HardwareKeyRouter.route(event: aEvent, context: KeyInputContext.yn, ynChoices: 'yn'),
        equals(const SwallowKey()),
      );

      // ESC -> 27
      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.yn, ynChoices: 'yn'),
        equals(const SendYn(27)),
      );

      // Enter when defaultChoice is 'n' (110)
      final enterEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.yn, ynChoices: 'yn', ynDefault: 110),
        equals(const SendYn(110)),
      );

      // Enter when defaultChoice is 0 (Swallow to prevent accidental yes/no)
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.yn, ynChoices: 'yn', ynDefault: 0),
        equals(const SwallowKey()),
      );
    });

    test('extCmdMenu should ignore characters so TextField can consume them', () {
      final lEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyL,
        logicalKey: LogicalKeyboardKey.keyL,
        character: 'l',
        timeStamp: Duration.zero,
      );
      // 'l' はアクセラレータ即決されず IgnoreKey となること
      expect(
        HardwareKeyRouter.route(event: lEvent, context: KeyInputContext.extCmdMenu),
        equals(const IgnoreKey()),
      );

      // ESC は SendKey(27, 'ESC')
      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.extCmdMenu),
        equals(const SendKey(27, 'ESC')),
      );
    });

    test('Regular menu should handle scroll, submit, cancel, and accelerators', () {
      // 矢印キー下 -> MenuScroll(1)
      final downEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: downEvent, context: KeyInputContext.menu),
        equals(const MenuScroll(1)),
      );

      // 矢印キー上 -> MenuScroll(-1)
      final upEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: upEvent, context: KeyInputContext.menu),
        equals(const MenuScroll(-1)),
      );

      // Space -> MenuScroll(1) (メニュー画面では下スクロール)
      final spaceEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.menu),
        equals(const MenuScroll(1)),
      );

      // Enter -> MenuSubmit()
      final enterEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.menu),
        equals(const MenuSubmit()),
      );

      // PageDown / PageUp
      final pageDownEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.pageDown,
        logicalKey: LogicalKeyboardKey.pageDown,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: pageDownEvent, context: KeyInputContext.menu),
        equals(const MenuPage(1)),
      );

      // > / < キー
      final gtEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.period,
        logicalKey: LogicalKeyboardKey.greater,
        character: '>',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: gtEvent, context: KeyInputContext.menu),
        equals(const MenuPage(1)),
      );

      // ESC -> MenuCancel()
      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.menu),
        equals(const MenuCancel()),
      );

      // 通常文字 'a' は MenuAccelerator(97)
      final aEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: aEvent, context: KeyInputContext.menu),
        equals(const MenuAccelerator(97)),
      );

      // 大文字 'A' は MenuAccelerator(65) (大文字小文字を厳密区別)
      final bigAEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'A',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: bigAEvent, context: KeyInputContext.menu),
        equals(const MenuAccelerator(65)),
      );
    });

    test('Text window should handle Space (TextSpaceAction), Shift+Space, PageUp/Down, arrows, and dismiss', () {
      // Space -> TextSpaceAction()
      final spaceEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.textWindow),
        equals(const TextSpaceAction()),
      );

      // Shift + Space -> TextPage(-1)
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.textWindow, isShiftPressed: true),
        equals(const TextPage(-1)),
      );

      // 矢印キー下 -> TextScroll(1)
      final downEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: downEvent, context: KeyInputContext.textWindow),
        equals(const TextScroll(1)),
      );

      // 矢印キー上 -> TextScroll(-1)
      final upEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: upEvent, context: KeyInputContext.textWindow),
        equals(const TextScroll(-1)),
      );

      // Enter / ESC -> DismissText()
      final enterEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.textWindow),
        equals(const DismissText()),
      );

      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.textWindow),
        equals(const DismissText()),
      );

      // 無効な通常文字 -> SwallowKey()
      final otherEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: otherEvent, context: KeyInputContext.textWindow),
        equals(const SwallowKey()),
      );
    });

    test('textInputOverlay should ignore typing but handle ESC', () {
      final aEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: aEvent, context: KeyInputContext.textInputOverlay),
        equals(const IgnoreKey()),
      );

      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.textInputOverlay),
        equals(const SendKey(27, 'ESC')),
      );
    });

    test('Game mode with Alt/Meta key (M-l, M-c, M-2, M-?)', () {
      // Alt+l (M-l = #loot: 108 | 0x80 = 236)
      final keyL = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyL,
        logicalKey: LogicalKeyboardKey.keyL,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyL, context: KeyInputContext.game, isAltPressed: true),
        equals(const SendKey(236, 'M-l')),
      );

      // Alt+c (M-c = #chat: 99 | 0x80 = 227)
      final keyC = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyC,
        logicalKey: LogicalKeyboardKey.keyC,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyC, context: KeyInputContext.game, isAltPressed: true),
        equals(const SendKey(227, 'M-c')),
      );

      // Alt+2 (M-2 = #twoweapon: 50 | 0x80 = 178)
      final key2 = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit2,
        logicalKey: LogicalKeyboardKey.digit2,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: key2, context: KeyInputContext.game, isAltPressed: true),
        equals(const SendKey(178, 'M-2')),
      );

      // Alt+? (M-? = #?: 63 | 0x80 = 191)
      final keyQuestion = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.slash,
        logicalKey: LogicalKeyboardKey.question,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyQuestion, context: KeyInputContext.game, isAltPressed: true),
        equals(const SendKey(191, 'M-?')),
      );

      // Alt+Shift+/ (M-? = #?: 63 | 0x80 = 191)
      final keySlash = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.slash,
        logicalKey: LogicalKeyboardKey.slash,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: keySlash,
          context: KeyInputContext.game,
          isAltPressed: true,
          isShiftPressed: true,
        ),
        equals(const SendKey(191, 'M-?')),
      );
    });

    test('Game mode with Alt+Shift (Uppercase Meta keys: M-C, M-A, M-X)', () {
      // Alt+Shift+C (M-C = #conduct: 67 | 0x80 = 195)
      final keyC = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyC,
        logicalKey: LogicalKeyboardKey.keyC,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: keyC,
          context: KeyInputContext.game,
          isAltPressed: true,
          isShiftPressed: true,
        ),
        equals(const SendKey(195, 'M-C')),
      );

      // Alt+Shift+A (M-A = #annotate: 65 | 0x80 = 193)
      final keyA = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: keyA,
          context: KeyInputContext.game,
          isAltPressed: true,
          isShiftPressed: true,
        ),
        equals(const SendKey(193, 'M-A')),
      );

      // Alt+Shift+X (M-X = #exploremode: 88 | 0x80 = 216)
      final keyX = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyX,
        logicalKey: LogicalKeyboardKey.keyX,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: keyX,
          context: KeyInputContext.game,
          isAltPressed: true,
          isShiftPressed: true,
        ),
        equals(const SendKey(216, 'M-X')),
      );
    });

    test('Alt standalone and system shortcuts protection', () {
      // AltLeft 単体押下は SwallowKey
      final altLeft = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.altLeft,
        logicalKey: LogicalKeyboardKey.altLeft,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: altLeft, context: KeyInputContext.game, isAltPressed: true),
        equals(const SwallowKey()),
      );

      // Alt+F4 や Alt+Tab などのシステム予約キーは IgnoreKey (OSへ透過)
      final keyF4 = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.f4,
        logicalKey: LogicalKeyboardKey.f4,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyF4, context: KeyInputContext.game, isAltPressed: true),
        equals(const IgnoreKey()),
      );

      final keyTab = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyTab, context: KeyInputContext.game, isAltPressed: true),
        equals(const IgnoreKey()),
      );
    });

    test('Alt in textInputOverlay should be ignored', () {
      final keyL = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyL,
        logicalKey: LogicalKeyboardKey.keyL,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: keyL,
          context: KeyInputContext.textInputOverlay,
          isAltPressed: true,
        ),
        equals(const IgnoreKey()),
      );
    });
  });
}
