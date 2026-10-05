import 'package:flutter/services.dart';

/// 拡張コマンドメニューのプロンプトかどうかを判定する共通関数
bool isExtCmdMenuPrompt(String prompt) {
  return prompt.contains('拡張コマンド') ||
      prompt.toLowerCase().contains('extended') ||
      prompt.trimLeft().startsWith('#');
}

/// 現在のゲームおよびUIの入力状況
enum KeyInputContext {
  /// テキスト入力中（GetLine, AskName, 拡張コマンドメニューの検索窓など）
  textInputOverlay,

  /// [y/n] などの二者択一・多肢確認ダイアログ
  yn,

  /// テキスト画面（ダンプログ、TopTen、ガイドブック等）
  textWindow,

  /// 拡張コマンド選択メニュー
  extCmdMenu,

  /// 通常メニュー（インベントリ、ドロップ等）
  menu,

  /// ゲーム本編（マップ・コマンド入力待ち）
  game,

  /// 非アクティブ（ゲーム停止中、または入力不可状態）
  inactive,
}

/// キー入力に対する実行アクション
sealed class KeyAction {
  const KeyAction();
}

/// FFI 経由で C コアに単一キーコードを送信
class SendKey extends KeyAction {
  final int code;
  final String label;
  const SendKey(this.code, [this.label = '']);

  @override
  String toString() => 'SendKey($code, "$label")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendKey &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          label == other.label;

  @override
  int get hashCode => code.hashCode ^ label.hashCode;
}

/// YN プロンプトに回答文字コードを送信
class SendYn extends KeyAction {
  final int code;
  const SendYn(this.code);

  @override
  String toString() => 'SendYn($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SendYn && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// テキスト画面を閉じる（Space 等で次ページ / 終了）
class DismissText extends KeyAction {
  const DismissText();

  @override
  String toString() => 'DismissText()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DismissText;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// メニューのアクセラレータキー選択
class MenuAccelerator extends KeyAction {
  final int code;
  const MenuAccelerator(this.code);

  @override
  String toString() => 'MenuAccelerator($code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuAccelerator &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// メニューのスクロール（1: 下、-1: 上）
class MenuScroll extends KeyAction {
  final int direction;
  const MenuScroll(this.direction);

  @override
  String toString() => 'MenuScroll($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuScroll &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// メニューのページ送り（1: 次、-1: 前）
class MenuPage extends KeyAction {
  final int direction;
  const MenuPage(this.direction);

  @override
  String toString() => 'MenuPage($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuPage &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// 複数選択メニューの確定（Enter）
class MenuSubmit extends KeyAction {
  const MenuSubmit();

  @override
  String toString() => 'MenuSubmit()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuSubmit;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// メニューのキャンセル（ESC）
class MenuCancel extends KeyAction {
  const MenuCancel();

  @override
  String toString() => 'MenuCancel()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuCancel;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト画面での Space キー（スクロール余地ありなら下スクロール、最下部なら閉じる）
class TextSpaceAction extends KeyAction {
  const TextSpaceAction();

  @override
  String toString() => 'TextSpaceAction()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextSpaceAction;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト画面の行スクロール（1: 下、-1: 上）
class TextScroll extends KeyAction {
  final int direction;
  const TextScroll(this.direction);

  @override
  String toString() => 'TextScroll($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextScroll &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// テキスト画面のページ送り（1: 次、-1: 前）
class TextPage extends KeyAction {
  final int direction;
  const TextPage(this.direction);

  @override
  String toString() => 'TextPage($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextPage &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}


/// キーイベントを無視し、Flutter Widget ツリー / TextField / IME にそのまま渡す (KeyEventResult.ignored)
class IgnoreKey extends KeyAction {
  const IgnoreKey();

  @override
  String toString() => 'IgnoreKey()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IgnoreKey;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// キーイベントを消費するが、何もしない (KeyEventResult.handled)
class SwallowKey extends KeyAction {
  const SwallowKey();

  @override
  String toString() => 'SwallowKey()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SwallowKey;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 物理キーボード入力を解析し、適切なアクションに振り分けるルーター
class HardwareKeyRouter {
  /// 全角英数を半角英数に変換（日本語IMEがONになっているPC対策）
  static String normalizeCharacter(String char) {
    if (char.isEmpty) return char;
    final code = char.codeUnitAt(0);
    // 全角スペース (U+3000)
    if (code == 0x3000) return ' ';
    // 全角英数・記号 (U+FF01〜U+FF5E) -> 半角 (U+0021〜U+007E)
    if (code >= 0xFF01 && code <= 0xFF5E) {
      return String.fromCharCode(code - 0xFEE0);
    }
    return char;
  }

  /// キーイベントを評価して対応する [KeyAction] を返す
  static KeyAction route({
    required KeyEvent event,
    required KeyInputContext context,
    int numberPadMode = 0,
    String ynChoices = '',
    int ynDefault = 0,
    bool isShiftPressed = false,
    bool isControlPressed = false,
    bool isAltPressed = false,
  }) {
    // KeyDownEvent または KeyRepeatEvent のみを処理（KeyUp は無視）
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return const IgnoreKey();
    }

    if (context == KeyInputContext.inactive) {
      return const IgnoreKey();
    }

    // 1. テキスト入力中（GetLine, AskName 等のオーバーレイ表示中）
    if (context == KeyInputContext.textInputOverlay) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        return const SendKey(27, 'ESC');
      }
      // それ以外のキーはすべて TextField / IME に委ねる
      return const IgnoreKey();
    }

    // 2. YN プロンプト表示中
    if (context == KeyInputContext.yn) {
      return _routeYn(event, ynChoices, ynDefault);
    }

    // 3. テキスト画面表示中（ダンプログ、TopTen、ガイドブック等）
    if (context == KeyInputContext.textWindow) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        return isShiftPressed ? const TextPage(-1) : const TextSpaceAction();
      }
      if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        return const TextPage(1);
      }
      if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        return const TextPage(-1);
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        return const TextScroll(1);
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        return const TextScroll(-1);
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        return const DismissText();
      }

      String? char = event.character;
      if (char != null && char.isNotEmpty) {
        char = normalizeCharacter(char);
        if (char == '>') return const TextPage(1);
        if (char == '<') return const TextPage(-1);
      }

      return const SwallowKey();
    }

    // 4. 拡張コマンドメニュー表示中
    if (context == KeyInputContext.extCmdMenu) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        return const SendKey(27, 'ESC');
      }
      // 拡張コマンドメニューでは、1文字でのアクセラレータ即決を行わず、
      // 検索フィルター TextField へ文字を入力させるため Ignore を返す
      return const IgnoreKey();
    }

    // 5. 通常メニュー表示中（インベントリ、ドロップなど）
    if (context == KeyInputContext.menu) {
      return _routeMenu(event);
    }

    // 6. ゲーム本編
    if (context == KeyInputContext.game) {
      return _routeGame(
        event: event,
        numberPadMode: numberPadMode,
        isShiftPressed: isShiftPressed,
        isControlPressed: isControlPressed,
        isAltPressed: isAltPressed,
      );
    }

    return const IgnoreKey();
  }

  /// YN プロンプトのキー判定
  static KeyAction _routeYn(KeyEvent event, String choices, int defaultChoice) {
    // ESC は常にキャンセル (27)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const SendYn(27);
    }

    // Enter または Space: 既定値があればそれを送信、なければ誤爆防止のため何もしない (Swallow)
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      if (defaultChoice != 0) {
        return SendYn(defaultChoice);
      }
      return const SwallowKey();
    }

    // 有効な選択肢文字列のパース（ESC文字 \x1b を除去）
    final cleanChoices = choices.replaceAll('\x1b', '');

    // 入力された文字の抽出
    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
    }

    if (char != null && char.isNotEmpty) {
      final lowerChar = char.toLowerCase();

      // cleanChoices に含まれているか判定（完全一致優先、次いでケース非依存で実在文字コードに正規化）
      if (cleanChoices.isNotEmpty) {
        // 1. 完全一致
        for (int i = 0; i < cleanChoices.length; i++) {
          final c = cleanChoices[i];
          if (c == char) {
            return SendYn(c.codeUnitAt(0));
          }
        }
        // 2. 大文字小文字同一視（choices 側の実在ケースに正規化して C コアに返す）
        for (int i = 0; i < cleanChoices.length; i++) {
          final c = cleanChoices[i];
          if (c.toLowerCase() == lowerChar) {
            return SendYn(c.codeUnitAt(0));
          }
        }
      } else {
        // choices が明示されていない標準 YN の場合
        if (lowerChar == 'y') return const SendYn(121); // 'y'
        if (lowerChar == 'n') return const SendYn(110); // 'n'
        if (lowerChar == 'q') return const SendYn(113); // 'q'
      }

      // 期待する選択肢に含まれないキーは無視（Swallow）
      return const SwallowKey();
    }

    return const SwallowKey();
  }

  /// 通常メニューのキー判定
  static KeyAction _routeMenu(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const MenuCancel();
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return const MenuSubmit();
    }
    // Space はメニュー画面では「下スクロール」
    if (event.logicalKey == LogicalKeyboardKey.space) {
      return const MenuScroll(1);
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return const MenuScroll(1);
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return const MenuScroll(-1);
    }
    if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      return const MenuPage(1);
    }
    if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      return const MenuPage(-1);
    }

    // テンキーや左右矢印キーはアクセラレータ誤選択を防ぐため抑止
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        _isNumpadKey(event.logicalKey)) {
      return const SwallowKey();
    }

    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
      if (char == '>') return const MenuPage(1);
      if (char == '<') return const MenuPage(-1);
      // アクセラレータは大文字小文字を厳密に区別して渡す
      return MenuAccelerator(char.codeUnitAt(0));
    }

    return const SwallowKey();
  }

  /// ゲーム本編のキー判定
  static KeyAction _routeGame({
    required KeyEvent event,
    required int numberPadMode,
    required bool isShiftPressed,
    required bool isControlPressed,
    required bool isAltPressed,
  }) {
    // A. Alt (Meta) キーとの組み合わせ (M-a〜M-z, M-A〜M-Z, M-2, M-?)
    if (isAltPressed) {
      final metaAction = _getMetaAction(
        event.logicalKey,
        isShiftPressed: isShiftPressed,
      );
      if (metaAction != null) {
        return metaAction;
      }
      // Alt 単体キーは Windows 等でシステムメニューにフォーカスが吸われるのを防ぐため安全に消費
      if (event.logicalKey == LogicalKeyboardKey.altLeft ||
          event.logicalKey == LogicalKeyboardKey.altRight) {
        return const SwallowKey();
      }
      // Alt+F4 や Alt+Tab などのシステムキーは OS に委ねる
      return const IgnoreKey();
    }

    // B. Control キーとの組み合わせ (Ctrl+A〜Z -> 1〜26)
    if (isControlPressed) {
      final ctrlCode = _getCtrlCode(event.logicalKey);
      if (ctrlCode != null) {
        return SendKey(ctrlCode, 'Ctrl+${event.logicalKey.keyLabel}');
      }
    }

    // B. テンキー移動判定（character 判定より優先して評価）
    final numpadAction = _getNumpadAction(
      event.logicalKey,
      numberPadMode: numberPadMode,
      isShiftPressed: isShiftPressed,
    );
    if (numpadAction != null) {
      return numpadAction;
    }

    // C. 矢印キー移動判定
    final arrowAction = _getArrowAction(
      event.logicalKey,
      numberPadMode: numberPadMode,
      isShiftPressed: isShiftPressed,
    );
    if (arrowAction != null) {
      return arrowAction;
    }

    // D. 特殊固定キー
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return const SendKey(10, 'Enter');
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const SendKey(27, 'ESC');
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      return const SendKey(32, 'Space');
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return const SendKey(9, 'Tab');
    }

    // E. 通常文字入力
    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
      return SendKey(char.codeUnitAt(0), char);
    }

    return const SwallowKey();
  }

  /// テンキーかどうかの判定
  static bool _isNumpadKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.numpad1 ||
        key == LogicalKeyboardKey.numpad2 ||
        key == LogicalKeyboardKey.numpad3 ||
        key == LogicalKeyboardKey.numpad4 ||
        key == LogicalKeyboardKey.numpad5 ||
        key == LogicalKeyboardKey.numpad6 ||
        key == LogicalKeyboardKey.numpad7 ||
        key == LogicalKeyboardKey.numpad8 ||
        key == LogicalKeyboardKey.numpad9 ||
        key == LogicalKeyboardKey.numpad0;
  }

  /// テンキーのアクション解決
  static KeyAction? _getNumpadAction(
    LogicalKeyboardKey key, {
    required int numberPadMode,
    required bool isShiftPressed,
  }) {
    if (numberPadMode == 0) {
      // 伝統的 NetHack モード (!number_pad): テンキーを hjkl + yubn に変換
      if (key == LogicalKeyboardKey.numpad7) {
        return SendKey(isShiftPressed ? 89 : 121, isShiftPressed ? 'Y' : 'y');
      }
      if (key == LogicalKeyboardKey.numpad8) {
        return SendKey(isShiftPressed ? 75 : 107, isShiftPressed ? 'K' : 'k');
      }
      if (key == LogicalKeyboardKey.numpad9) {
        return SendKey(isShiftPressed ? 85 : 117, isShiftPressed ? 'U' : 'u');
      }
      if (key == LogicalKeyboardKey.numpad4) {
        return SendKey(isShiftPressed ? 72 : 104, isShiftPressed ? 'H' : 'h');
      }
      if (key == LogicalKeyboardKey.numpad5) {
        return const SendKey(46, '.'); // 待機
      }
      if (key == LogicalKeyboardKey.numpad6) {
        return SendKey(isShiftPressed ? 76 : 108, isShiftPressed ? 'L' : 'l');
      }
      if (key == LogicalKeyboardKey.numpad1) {
        return SendKey(isShiftPressed ? 66 : 98, isShiftPressed ? 'B' : 'b');
      }
      if (key == LogicalKeyboardKey.numpad2) {
        return SendKey(isShiftPressed ? 74 : 106, isShiftPressed ? 'J' : 'j');
      }
      if (key == LogicalKeyboardKey.numpad3) {
        return SendKey(isShiftPressed ? 78 : 110, isShiftPressed ? 'N' : 'n');
      }
    } else {
      // number_pad モード (number_pad >= 1): テンキー数字そのものを送信
      if (key == LogicalKeyboardKey.numpad1) return const SendKey(49, '1');
      if (key == LogicalKeyboardKey.numpad2) return const SendKey(50, '2');
      if (key == LogicalKeyboardKey.numpad3) return const SendKey(51, '3');
      if (key == LogicalKeyboardKey.numpad4) return const SendKey(52, '4');
      if (key == LogicalKeyboardKey.numpad5) return const SendKey(53, '5');
      if (key == LogicalKeyboardKey.numpad6) return const SendKey(54, '6');
      if (key == LogicalKeyboardKey.numpad7) return const SendKey(55, '7');
      if (key == LogicalKeyboardKey.numpad8) return const SendKey(56, '8');
      if (key == LogicalKeyboardKey.numpad9) return const SendKey(57, '9');
    }
    return null;
  }

  /// 矢印キーのアクション解決
  static KeyAction? _getArrowAction(
    LogicalKeyboardKey key, {
    required int numberPadMode,
    required bool isShiftPressed,
  }) {
    if (numberPadMode == 0) {
      if (key == LogicalKeyboardKey.arrowUp) {
        return SendKey(isShiftPressed ? 75 : 107, isShiftPressed ? 'K' : 'k');
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        return SendKey(isShiftPressed ? 74 : 106, isShiftPressed ? 'J' : 'j');
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        return SendKey(isShiftPressed ? 72 : 104, isShiftPressed ? 'H' : 'h');
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        return SendKey(isShiftPressed ? 76 : 108, isShiftPressed ? 'L' : 'l');
      }
    } else {
      // number_pad >= 1 の場合、矢印キーを 8, 2, 4, 6 にマッピング
      if (key == LogicalKeyboardKey.arrowUp) return const SendKey(56, '8');
      if (key == LogicalKeyboardKey.arrowDown) return const SendKey(50, '2');
      if (key == LogicalKeyboardKey.arrowLeft) return const SendKey(52, '4');
      if (key == LogicalKeyboardKey.arrowRight) return const SendKey(54, '6');
    }
    return null;
  }

  /// 英字キー (keyA〜keyZ) の小文字 ASCII コード (97〜122) を返す
  static int? _getLetterCharCode(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyA) return 97;
    if (key == LogicalKeyboardKey.keyB) return 98;
    if (key == LogicalKeyboardKey.keyC) return 99;
    if (key == LogicalKeyboardKey.keyD) return 100;
    if (key == LogicalKeyboardKey.keyE) return 101;
    if (key == LogicalKeyboardKey.keyF) return 102;
    if (key == LogicalKeyboardKey.keyG) return 103;
    if (key == LogicalKeyboardKey.keyH) return 104;
    if (key == LogicalKeyboardKey.keyI) return 105;
    if (key == LogicalKeyboardKey.keyJ) return 106;
    if (key == LogicalKeyboardKey.keyK) return 107;
    if (key == LogicalKeyboardKey.keyL) return 108;
    if (key == LogicalKeyboardKey.keyM) return 109;
    if (key == LogicalKeyboardKey.keyN) return 110;
    if (key == LogicalKeyboardKey.keyO) return 111;
    if (key == LogicalKeyboardKey.keyP) return 112;
    if (key == LogicalKeyboardKey.keyQ) return 113;
    if (key == LogicalKeyboardKey.keyR) return 114;
    if (key == LogicalKeyboardKey.keyS) return 115;
    if (key == LogicalKeyboardKey.keyT) return 116;
    if (key == LogicalKeyboardKey.keyU) return 117;
    if (key == LogicalKeyboardKey.keyV) return 118;
    if (key == LogicalKeyboardKey.keyW) return 119;
    if (key == LogicalKeyboardKey.keyX) return 120;
    if (key == LogicalKeyboardKey.keyY) return 121;
    if (key == LogicalKeyboardKey.keyZ) return 122;
    return null;
  }

  /// Meta (Alt) キーのアクション解決 (0x80 | charCode)
  static KeyAction? _getMetaAction(
    LogicalKeyboardKey key, {
    required bool isShiftPressed,
  }) {
    // 1. 英字キー (A〜Z)
    final letterCode = _getLetterCharCode(key);
    if (letterCode != null) {
      final code = isShiftPressed ? (letterCode - 32) : letterCode;
      final label = String.fromCharCode(code);
      return SendKey(0x80 | code, 'M-$label');
    }

    // 2. 数字キー 2 (M-2: twoweapon / 二刀流)
    if (key == LogicalKeyboardKey.digit2) {
      return const SendKey(0x80 | 50, 'M-2');
    }

    // 3. 記号キー ? (M-?: extlist / 拡張コマンド一覧)
    if (key == LogicalKeyboardKey.question ||
        (key == LogicalKeyboardKey.slash && isShiftPressed)) {
      return const SendKey(0x80 | 63, 'M-?');
    }

    return null;
  }

  /// Control キーのコード変換 (1〜26)
  static int? _getCtrlCode(LogicalKeyboardKey key) {
    final letterCode = _getLetterCharCode(key);
    if (letterCode != null) {
      return letterCode - 96;
    }
    return null;
  }
}
