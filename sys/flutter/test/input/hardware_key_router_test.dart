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

      // Ctrl+M (ドロワー起動)
      final keyM = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyM,
        logicalKey: LogicalKeyboardKey.keyM,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: keyM, context: KeyInputContext.game, isControlPressed: true),
        equals(const OpenDrawerMenu()),
      );
    });

    test('Game mode Tab and Drawer menu triggers', () {
      final tabEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: tabEvent, context: KeyInputContext.game),
        equals(const GameTab(forward: true)),
      );
      expect(
        HardwareKeyRouter.route(event: tabEvent, context: KeyInputContext.game, isShiftPressed: true),
        equals(const GameTab(forward: false)),
      );

      final f10Event = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.f10,
        logicalKey: LogicalKeyboardKey.f10,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: f10Event, context: KeyInputContext.game),
        equals(const OpenDrawerMenu()),
      );

      final contextMenuEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.contextMenu,
        logicalKey: LogicalKeyboardKey.contextMenu,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: contextMenuEvent, context: KeyInputContext.game),
        equals(const OpenDrawerMenu()),
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

    test('YN mode with special prompts (#adjust, split, symbol detect, charFromLogicalKey)', () {
      // 1. #adjust スロット選択: 'c', '?', ESC
      final cEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyC,
        logicalKey: LogicalKeyboardKey.keyC,
        character: 'c',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: cEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'スロット文字を調整 移動先はどこにしますか [c-z]?',
        ),
        equals(const SendYn(99)), // 'c'
      );

      final qmarkEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.slash,
        logicalKey: LogicalKeyboardKey.slash,
        character: '?',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: qmarkEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'スロット文字を調整 移動先はどこにしますか [c-z]?',
        ),
        equals(const SendYn(63)), // '?'
      );

      // 2. スタック分割: '5' (数字追記) / Backspace (削除) / Enter (確定)
      final fiveEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit5,
        logicalKey: LogicalKeyboardKey.digit5,
        character: '5',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: fiveEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'いくつ分けますか?',
        ),
        equals(const YnAppendChar('5')),
      );

      final bsEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: bsEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'いくつ分けますか?',
        ),
        equals(const YnBackspace()),
      );

      final enterCountEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: enterCountEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'いくつ分けますか?',
        ),
        equals(const YnSubmit()),
      );

      // 3. 水晶玉探知: '$' (記号)
      final dollarEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit4,
        logicalKey: LogicalKeyboardKey.dollar,
        character: '\$',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: dollarEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: '何をお探しですか?',
        ),
        equals(const SendYn(36)), // '$'
      );

      // 4. キャラメイクおまかせ: 'a' キー
      final aEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: aEvent,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: "Shall I pick a character's race, role, gender and alignment for you? [ynaq]",
        ),
        equals(const SendYn(97)), // 'a'
      );

      // 5. character が null の場合のフォールバック (IME有効時など)
      final noCharC = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyC,
        logicalKey: LogicalKeyboardKey.keyC,
        character: null,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(
          event: noCharC,
          context: KeyInputContext.yn,
          ynChoices: '',
          ynQuestion: 'スロット文字を調整 移動先はどこにしますか [c-z]?',
        ),
        equals(const SendYn(99)), // 'c'
      );
    });

    test('extCmdMenu should support focusless typing & navigation when TextField is not focused, and ignore typing when focused', () {
      final lEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyL,
        logicalKey: LogicalKeyboardKey.keyL,
        character: 'l',
        timeStamp: Duration.zero,
      );
      // フォーカスレス時 (isTextFieldFocused: false) は TextOverlayAppendChar('l')
      expect(
        HardwareKeyRouter.route(event: lEvent, context: KeyInputContext.extCmdMenu),
        equals(const TextOverlayAppendChar('l')),
      );
      // TextField にフォーカスがある時 (isTextFieldFocused: true) は IgnoreKey
      expect(
        HardwareKeyRouter.route(
          event: lEvent,
          context: KeyInputContext.extCmdMenu,
          isTextFieldFocused: true,
        ),
        equals(const IgnoreKey()),
      );

      // 矢印キー上下 -> TextOverlayMoveCandidate(1 / -1) (フォーカス有無に関わらず動作)
      final downEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: downEvent, context: KeyInputContext.extCmdMenu),
        equals(const TextOverlayMoveCandidate(1)),
      );
      expect(
        HardwareKeyRouter.route(
          event: downEvent,
          context: KeyInputContext.extCmdMenu,
          isTextFieldFocused: true,
        ),
        equals(const TextOverlayMoveCandidate(1)),
      );

      // Tab -> TextOverlayAutocomplete()
      final tabEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: tabEvent, context: KeyInputContext.extCmdMenu),
        equals(const TextOverlayAutocomplete()),
      );

      // Enter -> TextOverlaySubmit() (フォーカスレス時)
      final enterEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.extCmdMenu),
        equals(const TextOverlaySubmit()),
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

      // Space -> MenuSpaceAction() (1ページ下スクロール、最下部では決定/閉鎖)
      final spaceEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.menu),
        equals(const MenuSpaceAction()),
      );

      // Shift + Space -> MenuPage(-1) (1ページ上スクロール)
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.menu, isShiftPressed: true),
        equals(const MenuPage(-1)),
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

      // IME有効時などで character が空の場合の logicalKey フォールバック ('a' / 'A')
      final nullCharAEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: nullCharAEvent, context: KeyInputContext.menu),
        equals(const MenuAccelerator(97)), // 'a'
      );
      expect(
        HardwareKeyRouter.route(event: nullCharAEvent, context: KeyInputContext.menu, isShiftPressed: true),
        equals(const MenuAccelerator(65)), // 'A'
      );

      // KeyRepeatEvent: スクロールキーは許可、アクセラレータや決定は SwallowKey
      final repeatScrollEvent = const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: repeatScrollEvent, context: KeyInputContext.menu),
        equals(const MenuScroll(1)),
      );

      final repeatAccelEvent = const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: repeatAccelEvent, context: KeyInputContext.menu),
        equals(const SwallowKey()),
      );

      final repeatEnterEvent = const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: repeatEnterEvent, context: KeyInputContext.menu),
        equals(const SwallowKey()),
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

    test('textInputOverlay should support focusless typing, backspace, delete, submit, and ignore typing when TextField is focused', () {
      final aEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        character: 'a',
        timeStamp: Duration.zero,
      );
      // フォーカスレス時 (isTextFieldFocused: false) は TextOverlayAppendChar('a')
      expect(
        HardwareKeyRouter.route(event: aEvent, context: KeyInputContext.textInputOverlay),
        equals(const TextOverlayAppendChar('a')),
      );
      // TextField にフォーカスがある時 (isTextFieldFocused: true) は IgnoreKey
      expect(
        HardwareKeyRouter.route(
          event: aEvent,
          context: KeyInputContext.textInputOverlay,
          isTextFieldFocused: true,
        ),
        equals(const IgnoreKey()),
      );

      // スペース文字の入力（願いの入力 "blessed +2 silver dragon scale mail" 等）
      final spaceEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        character: ' ',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: spaceEvent, context: KeyInputContext.textInputOverlay),
        equals(const TextOverlayAppendChar(' ')),
      );

      // Backspace / Delete / Enter (フォーカスレス時)
      final bsEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: bsEvent, context: KeyInputContext.textInputOverlay),
        equals(const TextOverlayBackspace()),
      );

      final delEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.delete,
        logicalKey: LogicalKeyboardKey.delete,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: delEvent, context: KeyInputContext.textInputOverlay),
        equals(const TextOverlayClear()),
      );

      final enterEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: enterEvent, context: KeyInputContext.textInputOverlay),
        equals(const TextOverlaySubmit()),
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

    test('anyKeyOverlay should send physical keys directly without focusing TextField', () {
      final dEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyD,
        logicalKey: LogicalKeyboardKey.keyD,
        character: 'd',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: dEvent, context: KeyInputContext.anyKeyOverlay),
        equals(const SendKey(100, 'd')),
      );

      final escEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: escEvent, context: KeyInputContext.anyKeyOverlay),
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

    test('Tab and Shift+Tab should route to TextOverlayTab or MenuTab correctly', () {
      final tabEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.tab,
        logicalKey: LogicalKeyboardKey.tab,
        timeStamp: Duration.zero,
      );

      // textInputOverlay: Tab -> TextOverlayTab(forward: true), Shift+Tab -> TextOverlayTab(forward: false)
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.textInputOverlay,
          isShiftPressed: false,
        ),
        equals(const TextOverlayTab(forward: true)),
      );
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.textInputOverlay,
          isShiftPressed: true,
        ),
        equals(const TextOverlayTab(forward: false)),
      );

      // menu: Tab -> MenuTab(forward: true), Shift+Tab -> MenuTab(forward: false)
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.menu,
          isShiftPressed: false,
        ),
        equals(const MenuTab(forward: true)),
      );
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.menu,
          isShiftPressed: true,
        ),
        equals(const MenuTab(forward: false)),
      );

      // yn: Tab -> TextOverlayTab(forward: true), Shift+Tab -> TextOverlayTab(forward: false)
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.yn,
          ynChoices: 'ynq',
          isShiftPressed: false,
        ),
        equals(const TextOverlayTab(forward: true)),
      );
      expect(
        HardwareKeyRouter.route(
          event: tabEvent,
          context: KeyInputContext.yn,
          ynChoices: 'ynq',
          isShiftPressed: true,
        ),
        equals(const TextOverlayTab(forward: false)),
      );
    });

    test('Menu and textWindow should support jump to edge (^, |, Home, End) and selection keys (., -, @)', () {
      // 1. Menu selection keys
      final dotEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.period,
        logicalKey: LogicalKeyboardKey.period,
        character: '.',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: dotEvent, context: KeyInputContext.menu),
        equals(const MenuSelectAll()),
      );

      final minusEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.minus,
        logicalKey: LogicalKeyboardKey.minus,
        character: '-',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: minusEvent, context: KeyInputContext.menu),
        equals(const MenuDeselectAll()),
      );

      final atEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.bracketLeft,
        logicalKey: LogicalKeyboardKey.at,
        character: '@',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: atEvent, context: KeyInputContext.menu),
        equals(const MenuInvertAll()),
      );

      // 2. Menu jump edge keys (^, |, Home, End)
      final caretEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.digit6,
        logicalKey: LogicalKeyboardKey.caret,
        character: '^',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: caretEvent, context: KeyInputContext.menu),
        equals(const MenuJumpEdge(true)),
      );

      final barEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backslash,
        logicalKey: LogicalKeyboardKey.bar,
        character: '|',
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: barEvent, context: KeyInputContext.menu),
        equals(const MenuJumpEdge(false)),
      );

      final homeEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.home,
        logicalKey: LogicalKeyboardKey.home,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: homeEvent, context: KeyInputContext.menu),
        equals(const MenuJumpEdge(true)),
      );

      final endEvent = const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.end,
        logicalKey: LogicalKeyboardKey.end,
        timeStamp: Duration.zero,
      );
      expect(
        HardwareKeyRouter.route(event: endEvent, context: KeyInputContext.menu),
        equals(const MenuJumpEdge(false)),
      );

      // 3. Text window jump edge keys (^, |, Home, End)
      expect(
        HardwareKeyRouter.route(event: caretEvent, context: KeyInputContext.textWindow),
        equals(const TextJumpEdge(true)),
      );
      expect(
        HardwareKeyRouter.route(event: barEvent, context: KeyInputContext.textWindow),
        equals(const TextJumpEdge(false)),
      );
      expect(
        HardwareKeyRouter.route(event: homeEvent, context: KeyInputContext.textWindow),
        equals(const TextJumpEdge(true)),
      );
      expect(
        HardwareKeyRouter.route(event: endEvent, context: KeyInputContext.textWindow),
        equals(const TextJumpEdge(false)),
      );
    });
  });
}
