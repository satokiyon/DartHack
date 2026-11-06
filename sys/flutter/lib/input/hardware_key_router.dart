import 'package:flutter/services.dart';
import '../utils/yn_choice_parser.dart';

/// 拡張コマンドメニューのプロンプトかどうかを判定する共通関数
bool isExtCmdMenuPrompt(String prompt) {
  return prompt.contains('拡張コマンド') ||
      prompt.toLowerCase().contains('extended') ||
      prompt.trimLeft().startsWith('#');
}

/// 現在のゲームおよびUIの入力状況
enum KeyInputContext {
  /// テキスト入力中（GetLine, AskName などのオーバーレイ）
  textInputOverlay,

  /// 1文字コマンド説明検索（AnyKeyOverlay: `?` コマンド説明）
  anyKeyOverlay,

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

  /// タイトル画面（言語選択、開始、設定、ヘルプ等）
  titleScreen,

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

/// メニュー表示中の数量プレフィックス数字入力（0〜9）
class MenuDigit extends KeyAction {
  final int digit;
  const MenuDigit(this.digit);

  @override
  String toString() => 'MenuDigit($digit)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuDigit &&
          runtimeType == other.runtimeType &&
          digit == other.digit;

  @override
  int get hashCode => digit.hashCode;
}

/// メニュー表示中の数量プレフィックス1桁削除（BackSpace）
class MenuCountBackspace extends KeyAction {
  const MenuCountBackspace();

  @override
  String toString() => 'MenuCountBackspace()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuCountBackspace;

  @override
  int get hashCode => runtimeType.hashCode;
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

/// メニューの横スクロール（1: 右、-1: 左）
class MenuHorizontalScroll extends KeyAction {
  final int direction;
  const MenuHorizontalScroll(this.direction);

  @override
  String toString() => 'MenuHorizontalScroll($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuHorizontalScroll &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// メニューの横端ジャンプ（true: 左端、false: 右端）
class MenuHorizontalJumpEdge extends KeyAction {
  final bool toLeft;
  const MenuHorizontalJumpEdge(this.toLeft);

  @override
  String toString() => 'MenuHorizontalJumpEdge($toLeft)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuHorizontalJumpEdge &&
          runtimeType == other.runtimeType &&
          toLeft == other.toLeft;

  @override
  int get hashCode => toLeft.hashCode;
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

/// メニュー画面での Space キー（スクロール余地ありなら1ページ下スクロール、最下部なら閉じる／決定）
class MenuSpaceAction extends KeyAction {
  const MenuSpaceAction();

  @override
  String toString() => 'MenuSpaceAction()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuSpaceAction;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 複数選択メニューの全選択（.）
class MenuSelectAll extends KeyAction {
  const MenuSelectAll();

  @override
  String toString() => 'MenuSelectAll()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuSelectAll;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 複数選択メニューの選択解除（-）
class MenuDeselectAll extends KeyAction {
  const MenuDeselectAll();

  @override
  String toString() => 'MenuDeselectAll()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuDeselectAll;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// 複数選択メニューの選択反転（@）
class MenuInvertAll extends KeyAction {
  const MenuInvertAll();

  @override
  String toString() => 'MenuInvertAll()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MenuInvertAll;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// メニュー画面の一覧先頭・末尾ジャンプ（toTop: true=先頭, false=末尾）
class MenuJumpEdge extends KeyAction {
  final bool toTop;
  const MenuJumpEdge(this.toTop);

  @override
  String toString() => 'MenuJumpEdge(toTop: $toTop)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuJumpEdge &&
          runtimeType == other.runtimeType &&
          toTop == other.toTop;

  @override
  int get hashCode => toTop.hashCode;
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

/// テキスト画面の先頭・末尾ジャンプ（toTop: true=先頭, false=末尾）
class TextJumpEdge extends KeyAction {
  final bool toTop;
  const TextJumpEdge(this.toTop);

  @override
  String toString() => 'TextJumpEdge(toTop: $toTop)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextJumpEdge &&
          runtimeType == other.runtimeType &&
          toTop == other.toTop;

  @override
  int get hashCode => toTop.hashCode;
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

/// YN 数量入力のテキスト追記アクション
class YnAppendChar extends KeyAction {
  final String char;
  const YnAppendChar(this.char);

  @override
  String toString() => 'YnAppendChar("$char")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YnAppendChar && runtimeType == other.runtimeType && char == other.char;

  @override
  int get hashCode => char.hashCode;
}

/// YN 数量入力の1文字削除アクション (Backspace)
class YnBackspace extends KeyAction {
  const YnBackspace();

  @override
  String toString() => 'YnBackspace()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is YnBackspace;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// YN 数量入力の全消去アクション (Clear)
class YnClear extends KeyAction {
  const YnClear();

  @override
  String toString() => 'YnClear()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is YnClear;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// YN 数量入力の確定アクション (Enter)
class YnSubmit extends KeyAction {
  const YnSubmit();

  @override
  String toString() => 'YnSubmit()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is YnSubmit;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト入力オーバーレイ（GetLine, AskName, 拡張コマンド検索等）のフォーカスレス文字追記アクション
class TextOverlayAppendChar extends KeyAction {
  final String char;
  const TextOverlayAppendChar(this.char);

  @override
  String toString() => 'TextOverlayAppendChar("$char")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayAppendChar &&
          runtimeType == other.runtimeType &&
          char == other.char;

  @override
  int get hashCode => char.hashCode;
}

/// テキスト入力オーバーレイの1文字削除アクション (Backspace)
class TextOverlayBackspace extends KeyAction {
  const TextOverlayBackspace();

  @override
  String toString() => 'TextOverlayBackspace()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextOverlayBackspace;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト入力オーバーレイの全消去アクション (Delete)
class TextOverlayClear extends KeyAction {
  const TextOverlayClear();

  @override
  String toString() => 'TextOverlayClear()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextOverlayClear;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト入力オーバーレイの確定アクション (Enter)
class TextOverlaySubmit extends KeyAction {
  const TextOverlaySubmit();

  @override
  String toString() => 'TextOverlaySubmit()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextOverlaySubmit;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト入力オーバーレイ・拡張コマンドメニューの候補/履歴選択移動 (↑: -1, ↓: 1)
class TextOverlayMoveCandidate extends KeyAction {
  final int delta;
  const TextOverlayMoveCandidate(this.delta);

  @override
  String toString() => 'TextOverlayMoveCandidate($delta)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayMoveCandidate &&
          runtimeType == other.runtimeType &&
          delta == other.delta;

  @override
  int get hashCode => delta.hashCode;
}

/// テキスト入力画面での水平操作 (←: -1, →: 1、モード切り替え等)
class TextOverlayHorizontalMove extends KeyAction {
  final int direction;
  const TextOverlayHorizontalMove(this.direction);

  @override
  String toString() => 'TextOverlayHorizontalMove($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayHorizontalMove &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// テキスト入力オーバーレイでのスペース操作（フォーカス要素のトグル等）
class TextOverlaySpace extends KeyAction {
  const TextOverlaySpace();

  @override
  String toString() => 'TextOverlaySpace()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextOverlaySpace;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// テキスト入力オーバーレイ・拡張コマンドメニューのページ送り (PageUp: -1, PageDown: 1)
class TextOverlayPage extends KeyAction {
  final int direction;
  const TextOverlayPage(this.direction);

  @override
  String toString() => 'TextOverlayPage($direction)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayPage &&
          runtimeType == other.runtimeType &&
          direction == other.direction;

  @override
  int get hashCode => direction.hashCode;
}

/// テキスト入力画面・ダイアログのフォーカス循環（forward: true=次, false=前）
class TextOverlayTab extends KeyAction {
  final bool forward;
  const TextOverlayTab({this.forward = true});

  @override
  String toString() => 'TextOverlayTab(forward: $forward)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextOverlayTab &&
          runtimeType == other.runtimeType &&
          forward == other.forward;

  @override
  int get hashCode => forward.hashCode;
}

/// メニュー画面のアクションボタンフォーカス循環（forward: true=次, false=前）
class MenuTab extends KeyAction {
  final bool forward;
  const MenuTab({this.forward = true});

  @override
  String toString() => 'MenuTab(forward: $forward)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuTab &&
          runtimeType == other.runtimeType &&
          forward == other.forward;

  @override
  int get hashCode => forward.hashCode;
}

/// ゲームマップ画面のフローティングボタン（メニュー、全体地図等）のフォーカス循環（forward: true=次, false=前）
class GameTab extends KeyAction {
  final bool forward;
  const GameTab({this.forward = true});

  @override
  String toString() => 'GameTab(forward: $forward)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameTab &&
          runtimeType == other.runtimeType &&
          forward == other.forward;

  @override
  int get hashCode => forward.hashCode;
}

/// ドロワーメニューを開閉するアクション（F10, ContextMenu, Ctrl+M）
class OpenDrawerMenu extends KeyAction {
  const OpenDrawerMenu();

  @override
  String toString() => 'OpenDrawerMenu()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OpenDrawerMenu;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// タイトル画面でのフォーカス循環 (Tab / Shift+Tab)
class TitleTab extends KeyAction {
  final bool forward;
  const TitleTab({this.forward = true});

  @override
  String toString() => 'TitleTab(forward: $forward)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleTab &&
          runtimeType == other.runtimeType &&
          forward == other.forward;

  @override
  int get hashCode => forward.hashCode;
}

/// タイトル画面での決定操作 (Enter)
class TitleSubmit extends KeyAction {
  const TitleSubmit();

  @override
  String toString() => 'TitleSubmit()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TitleSubmit;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// タイトル画面でのスペースキー操作
class TitleSpaceAction extends KeyAction {
  const TitleSpaceAction();

  @override
  String toString() => 'TitleSpaceAction()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TitleSpaceAction;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// タイトル画面でのキャンセル・フォーカスリセット (ESC)
class TitleEscape extends KeyAction {
  const TitleEscape();

  @override
  String toString() => 'TitleEscape()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TitleEscape;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// タイトル画面での特定言語選択 (ArrowLeft -> ja, ArrowRight -> en)
class TitleSelectLanguage extends KeyAction {
  final String language;
  const TitleSelectLanguage(this.language);

  @override
  String toString() => 'TitleSelectLanguage($language)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleSelectLanguage &&
          runtimeType == other.runtimeType &&
          language == other.language;

  @override
  int get hashCode => language.hashCode;
}

/// テキスト入力オーバーレイ・拡張コマンドメニューの候補補完アクション (Tab)
class TextOverlayAutocomplete extends KeyAction {
  const TextOverlayAutocomplete();

  @override
  String toString() => 'TextOverlayAutocomplete()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextOverlayAutocomplete;

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
    String ynQuestion = '',
    int ynDefault = 0,
    bool isShiftPressed = false,
    bool isControlPressed = false,
    bool isAltPressed = false,
    bool isTextFieldFocused = false,
  }) {
    // KeyDownEvent または KeyRepeatEvent のみを処理（KeyUp は無視）
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return const IgnoreKey();
    }

    if (context == KeyInputContext.inactive) {
      return const IgnoreKey();
    }

    // 0. タイトル画面
    if (context == KeyInputContext.titleScreen) {
      return _routeTitleScreen(event, isShiftPressed: isShiftPressed);
    }

    // 1a. 1文字コマンド説明検索（AnyKeyOverlay: `?` コマンド説明）
    if (context == KeyInputContext.anyKeyOverlay) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        return const SendKey(27, 'ESC');
      }
      if (isTextFieldFocused) {
        return const IgnoreKey();
      }
      if (event is! KeyDownEvent) {
        return const SwallowKey();
      }
      return _routeGame(
        event: event,
        numberPadMode: 0,
        isShiftPressed: isShiftPressed,
        isControlPressed: isControlPressed,
        isAltPressed: isAltPressed,
      );
    }

    // 1b. テキスト入力中（GetLine, AskName 等）および拡張コマンドメニュー表示中
    if (context == KeyInputContext.textInputOverlay ||
        context == KeyInputContext.extCmdMenu) {
      return _routeTextInputOrExtCmd(
        event: event,
        isTextFieldFocused: isTextFieldFocused,
        isShiftPressed: isShiftPressed,
        isControlPressed: isControlPressed,
        isAltPressed: isAltPressed,
        isExtCmdMenu: context == KeyInputContext.extCmdMenu,
      );
    }

    // 2. YN プロンプト表示中
    if (context == KeyInputContext.yn) {
      if (isTextFieldFocused && event.logicalKey != LogicalKeyboardKey.escape) {
        return const IgnoreKey();
      }
      return _routeYn(
        event,
        ynChoices,
        ynDefault,
        question: ynQuestion,
        isShiftPressed: isShiftPressed,
      );
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
      if (event.logicalKey == LogicalKeyboardKey.home) {
        return const TextJumpEdge(true);
      }
      if (event.logicalKey == LogicalKeyboardKey.end) {
        return const TextJumpEdge(false);
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        return const TextScroll(1);
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        return const TextScroll(-1);
      }
      if (event.logicalKey == LogicalKeyboardKey.tab && !isAltPressed) {
        return (event is KeyDownEvent)
            ? TextOverlayTab(forward: !isShiftPressed)
            : const SwallowKey();
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        return (event is KeyDownEvent)
            ? const DismissText()
            : const SwallowKey();
      }

      String? char = event.character;
      if (char != null && char.isNotEmpty) {
        char = normalizeCharacter(char);
        if (char == '>') return const TextPage(1);
        if (char == '<') return const TextPage(-1);
        if (char == '^') return const TextJumpEdge(true);
        if (char == '|') return const TextJumpEdge(false);
      }

      return const SwallowKey();
    }

    // 5. 通常メニュー表示中（インベントリ、ドロップなど）
    if (context == KeyInputContext.menu) {
      return _routeMenu(event, isShiftPressed: isShiftPressed);
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

  /// テキスト入力オーバーレイ（GetLine, AskName 等）および拡張コマンドメニューのキー判定
  static KeyAction _routeTextInputOrExtCmd({
    required KeyEvent event,
    required bool isTextFieldFocused,
    required bool isShiftPressed,
    required bool isControlPressed,
    required bool isAltPressed,
    bool isExtCmdMenu = false,
  }) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const SendKey(27, 'ESC');
    }

    // 上下矢印キー・PageUp/PageDown・Tab キーは候補・履歴選択やフォーカス移動・補完として処理
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return const TextOverlayMoveCandidate(-1);
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return const TextOverlayMoveCandidate(1);
    }
    if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      return const TextOverlayPage(-1);
    }
    if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      return const TextOverlayPage(1);
    }
    if (event.logicalKey == LogicalKeyboardKey.tab && !isAltPressed) {
      return (event is KeyDownEvent)
          ? TextOverlayTab(forward: !isShiftPressed)
          : const SwallowKey();
    }

    // ユーザーが画面上の TextField を明示的にタップしてフォーカスしている場合は、
    // 通常の文字入力・変換・Backspace・Enter はすべて TextField / OS IME に委ねる
    if (isTextFieldFocused) {
      return const IgnoreKey();
    }

    // --- 以下は TextField 未フォーカス時（フォーカスレス物理キーボード入力） ---
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      return (event is KeyDownEvent)
          ? const TextOverlayHorizontalMove(-1)
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return (event is KeyDownEvent)
          ? const TextOverlayHorizontalMove(1)
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return (event is KeyDownEvent)
          ? const TextOverlaySubmit()
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return const TextOverlayBackspace();
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      return const TextOverlayClear();
    }

    // Alt / Ctrl 同時押し時は文字追記を行わず IgnoreKey とする
    if (isAltPressed || isControlPressed) {
      return const IgnoreKey();
    }

    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
    } else {
      char = _charFromLogicalKey(event.logicalKey, isShiftPressed);
    }

    if (char != null && char.isNotEmpty) {
      final code = char.codeUnitAt(0);
      if (code >= 32 && code <= 126) {
        return TextOverlayAppendChar(char);
      }
    }

    return const SwallowKey();
  }

  /// タイトル画面のキー判定
  static KeyAction _routeTitleScreen(KeyEvent event, {required bool isShiftPressed}) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return (event is KeyDownEvent)
          ? TitleTab(forward: !isShiftPressed)
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return (event is KeyDownEvent)
          ? const TitleSubmit()
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      return (event is KeyDownEvent)
          ? const TitleSpaceAction()
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return (event is KeyDownEvent)
          ? const TitleEscape()
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      return (event is KeyDownEvent)
          ? const TitleSelectLanguage('ja')
          : const SwallowKey();
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return (event is KeyDownEvent)
          ? const TitleSelectLanguage('en')
          : const SwallowKey();
    }
    return const SwallowKey();
  }

  /// YN プロンプトのキー判定
  static KeyAction _routeYn(
    KeyEvent event,
    String choices,
    int defaultChoice, {
    String question = '',
    bool isShiftPressed = false,
  }) {
    // Tab / Shift+Tab によるフォーカス循環
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return (event is KeyDownEvent)
          ? TextOverlayTab(forward: !isShiftPressed)
          : const SwallowKey();
    }

    // ESC は常にキャンセル (27)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const SendYn(27);
    }

    final parsed = YnChoiceParser.parse(
      question: question,
      choices: choices,
      defaultChoice: defaultChoice,
    );

    // 数量入力 (いくつ分けますか? 等): 複数桁入力・BS・Enter・Delete をサポート
    if (parsed.type == YnPromptType.countInput) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        return const YnSubmit();
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        return const YnBackspace();
      }
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        return const YnClear();
      }

      String? char = event.character;
      if (char != null && char.isNotEmpty) {
        char = normalizeCharacter(char);
      } else {
        char = _charFromLogicalKey(event.logicalKey, isShiftPressed);
      }

      if (char != null && parsed.validKeyChars.contains(char)) {
        return YnAppendChar(char);
      }
      return const SwallowKey();
    }

    // 1文字即決の YN プロンプトでは長押しリピート (KeyRepeatEvent) による連続応答誤爆を防止
    if (event is! KeyDownEvent) {
      return const SwallowKey();
    }

    // Enter または Space: フォーカス中の項目または既定値を確定実行
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      return const YnSubmit();
    }

    // 入力された文字の抽出
    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
    } else {
      char = _charFromLogicalKey(event.logicalKey, isShiftPressed);
    }

    if (char == null || char.isEmpty) {
      return const SwallowKey();
    }

    switch (parsed.type) {
      case YnPromptType.countInput:
        // 上記の countInput ブロックで処理済み
        return const SwallowKey();

      case YnPromptType.slotSelect:
        final code = char.codeUnitAt(0);
        final isLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
        final isDigit = code >= 48 && code <= 57;
        if (isLetter || isDigit || char == '?' || char == '*' || char == '\$' || char == '#' || char == '-') {
          return SendYn(code);
        }
        return const SwallowKey();

      case YnPromptType.symbolDetect:
      case YnPromptType.genericChar:
        final code = char.codeUnitAt(0);
        if (code >= 32 && code <= 126) {
          return SendYn(code);
        }
        return const SwallowKey();

      case YnPromptType.yesNo:
        final lowerChar = char.toLowerCase();
        // 1. 完全一致
        for (final c in parsed.quickChoices) {
          if (c == char) {
            return SendYn(c.codeUnitAt(0));
          }
        }
        // 2. 大文字小文字同一視
        for (final c in parsed.quickChoices) {
          if (c.toLowerCase() == lowerChar) {
            return SendYn(c.codeUnitAt(0));
          }
        }
        return const SwallowKey();
    }
  }

  static String? _charFromLogicalKey(LogicalKeyboardKey key, bool isShiftPressed) {
    if (key == LogicalKeyboardKey.space) return ' ';
    if (key == LogicalKeyboardKey.keyA) return isShiftPressed ? 'A' : 'a';
    if (key == LogicalKeyboardKey.keyB) return isShiftPressed ? 'B' : 'b';
    if (key == LogicalKeyboardKey.keyC) return isShiftPressed ? 'C' : 'c';
    if (key == LogicalKeyboardKey.keyD) return isShiftPressed ? 'D' : 'd';
    if (key == LogicalKeyboardKey.keyE) return isShiftPressed ? 'E' : 'e';
    if (key == LogicalKeyboardKey.keyF) return isShiftPressed ? 'F' : 'f';
    if (key == LogicalKeyboardKey.keyG) return isShiftPressed ? 'G' : 'g';
    if (key == LogicalKeyboardKey.keyH) return isShiftPressed ? 'H' : 'h';
    if (key == LogicalKeyboardKey.keyI) return isShiftPressed ? 'I' : 'i';
    if (key == LogicalKeyboardKey.keyJ) return isShiftPressed ? 'J' : 'j';
    if (key == LogicalKeyboardKey.keyK) return isShiftPressed ? 'K' : 'k';
    if (key == LogicalKeyboardKey.keyL) return isShiftPressed ? 'L' : 'l';
    if (key == LogicalKeyboardKey.keyM) return isShiftPressed ? 'M' : 'm';
    if (key == LogicalKeyboardKey.keyN) return isShiftPressed ? 'N' : 'n';
    if (key == LogicalKeyboardKey.keyO) return isShiftPressed ? 'O' : 'o';
    if (key == LogicalKeyboardKey.keyP) return isShiftPressed ? 'P' : 'p';
    if (key == LogicalKeyboardKey.keyQ) return isShiftPressed ? 'Q' : 'q';
    if (key == LogicalKeyboardKey.keyR) return isShiftPressed ? 'R' : 'r';
    if (key == LogicalKeyboardKey.keyS) return isShiftPressed ? 'S' : 's';
    if (key == LogicalKeyboardKey.keyT) return isShiftPressed ? 'T' : 't';
    if (key == LogicalKeyboardKey.keyU) return isShiftPressed ? 'U' : 'u';
    if (key == LogicalKeyboardKey.keyV) return isShiftPressed ? 'V' : 'v';
    if (key == LogicalKeyboardKey.keyW) return isShiftPressed ? 'W' : 'w';
    if (key == LogicalKeyboardKey.keyX) return isShiftPressed ? 'X' : 'x';
    if (key == LogicalKeyboardKey.keyY) return isShiftPressed ? 'Y' : 'y';
    if (key == LogicalKeyboardKey.keyZ) return isShiftPressed ? 'Z' : 'z';

    // 数字キー
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) return '0';
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) return isShiftPressed ? '!' : '1';
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) return isShiftPressed ? '"' : '2';
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) return isShiftPressed ? '#' : '3';
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) return isShiftPressed ? '\$' : '4';
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) return isShiftPressed ? '%' : '5';
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) return isShiftPressed ? '&' : '6';
    if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) return isShiftPressed ? '\'' : '7';
    if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) return isShiftPressed ? '(' : '8';
    if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) return isShiftPressed ? ')' : '9';

    // 記号キー（JIS/US配列および直接LogicalKeyboardKeyが飛んでくる環境の両対応）
    if (key == LogicalKeyboardKey.slash) return isShiftPressed ? '?' : '/';
    if (key == LogicalKeyboardKey.question) return '?';
    if (key == LogicalKeyboardKey.asterisk) return '*';
    if (key == LogicalKeyboardKey.numpadMultiply) return '*';
    if (key == LogicalKeyboardKey.numpadDivide) return '/';
    if (key == LogicalKeyboardKey.minus) return isShiftPressed ? '_' : '-';
    if (key == LogicalKeyboardKey.numpadSubtract) return '-';
    if (key == LogicalKeyboardKey.underscore) return '_';
    if (key == LogicalKeyboardKey.equal) return isShiftPressed ? '+' : '=';
    if (key == LogicalKeyboardKey.numpadAdd) return '+';
    if (key == LogicalKeyboardKey.add) return '+';
    if (key == LogicalKeyboardKey.comma) return isShiftPressed ? '<' : ',';
    if (key == LogicalKeyboardKey.less) return '<';
    if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) return isShiftPressed ? '>' : '.';
    if (key == LogicalKeyboardKey.greater) return '>';
    if (key == LogicalKeyboardKey.semicolon) return isShiftPressed ? ':' : ';';
    if (key == LogicalKeyboardKey.colon) return ':';
    if (key == LogicalKeyboardKey.quote) return isShiftPressed ? '"' : '\'';
    if (key == LogicalKeyboardKey.quoteSingle) return '\'';
    if (key == LogicalKeyboardKey.bracketLeft) return isShiftPressed ? '{' : '[';
    if (key == LogicalKeyboardKey.braceLeft) return '{';
    if (key == LogicalKeyboardKey.bracketRight) return isShiftPressed ? '}' : ']';
    if (key == LogicalKeyboardKey.braceRight) return '}';
    if (key == LogicalKeyboardKey.backslash) return isShiftPressed ? '|' : '\\';
    if (key == LogicalKeyboardKey.bar) return '|';
    if (key == LogicalKeyboardKey.backquote) return isShiftPressed ? '~' : '`';
    if (key == LogicalKeyboardKey.tilde) return '~';
    if (key == LogicalKeyboardKey.caret) return '^';
    if (key == LogicalKeyboardKey.at) return '@';
    if (key == LogicalKeyboardKey.exclamation) return '!';
    if (key == LogicalKeyboardKey.numberSign) return '#';
    if (key == LogicalKeyboardKey.dollar) return '\$';
    if (key == LogicalKeyboardKey.percent) return '%';
    if (key == LogicalKeyboardKey.ampersand) return '&';
    if (key == LogicalKeyboardKey.parenthesisLeft) return '(';
    if (key == LogicalKeyboardKey.parenthesisRight) return ')';
    return null;
  }

  /// 通常メニューのキー判定
  static KeyAction _routeMenu(KeyEvent event, {required bool isShiftPressed}) {
    // スクロール操作（Space, 矢印上下, PageUp/Down）は長押し連続スクロール（KeyRepeatEvent）を許可
    if (event.logicalKey == LogicalKeyboardKey.space) {
      return isShiftPressed ? const MenuPage(-1) : const MenuSpaceAction();
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
    if (event.logicalKey == LogicalKeyboardKey.home) {
      return const MenuJumpEdge(true);
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      return const MenuJumpEdge(false);
    }

    // スクロール以外の決定・キャンセル・アクセラレータ選択・Tabフォーカス移動は、長押しトグル誤爆防止のため KeyDownEvent のみ処理
    if (event is! KeyDownEvent) {
      return const SwallowKey();
    }

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return MenuTab(forward: !isShiftPressed);
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return const MenuCancel();
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      return const MenuCountBackspace();
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return const MenuSubmit();
    }

    // テンキーの数字入力（数量指定）
    final numpadDigit = _digitFromNumpad(event.logicalKey);
    if (numpadDigit != null) {
      return MenuDigit(numpadDigit);
    }

    // 左右矢印キー: 横スクロール（Shift併用時は最左端/最右端ジャンプ）
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final isLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft;
      if (isShiftPressed) {
        return MenuHorizontalJumpEdge(isLeft);
      }
      return MenuHorizontalScroll(isLeft ? -1 : 1);
    }

    // メインキーの数字入力（Shiftなし時: 数量指定）
    if (!isShiftPressed) {
      final digit = _digitFromLogicalKey(event.logicalKey);
      if (digit != null) {
        return MenuDigit(digit);
      }
    }

    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
    } else {
      // IME 有効時など event.character が空の場合のフォールバック
      char = _charFromLogicalKey(event.logicalKey, isShiftPressed);
    }

    if (char != null && char.isNotEmpty) {
      // 文字が数字 '0'〜'9' の場合も数量指定として処理
      if (char.length == 1) {
        final code = char.codeUnitAt(0);
        if (code >= 48 && code <= 57) {
          return MenuDigit(code - 48);
        }
      }

      if (char == '>') return const MenuPage(1);
      if (char == '<') return const MenuPage(-1);
      if (char == '^') return const MenuJumpEdge(true);
      if (char == '|') return const MenuJumpEdge(false);
      if (char == '.') return const MenuSelectAll();
      if (char == '-') return const MenuDeselectAll();
      if (char == '@') return const MenuInvertAll();
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
    // 0. ドロワーメニュー起動キー（F10, ContextMenu, Ctrl+M）
    if (event.logicalKey == LogicalKeyboardKey.f10 ||
        event.logicalKey == LogicalKeyboardKey.contextMenu ||
        (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyM)) {
      return (event is KeyDownEvent)
          ? const OpenDrawerMenu()
          : const SwallowKey();
    }

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

    // C. テンキー移動判定（character 判定より優先して評価）
    final numpadAction = _getNumpadAction(
      event.logicalKey,
      numberPadMode: numberPadMode,
      isShiftPressed: isShiftPressed,
    );
    if (numpadAction != null) {
      return numpadAction;
    }

    // D. 矢印キー移動判定
    final arrowAction = _getArrowAction(
      event.logicalKey,
      numberPadMode: numberPadMode,
      isShiftPressed: isShiftPressed,
    );
    if (arrowAction != null) {
      return arrowAction;
    }

    // E. 特殊固定キー
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
      return (event is KeyDownEvent)
          ? GameTab(forward: !isShiftPressed)
          : const SwallowKey();
    }

    // E. 通常文字入力
    String? char = event.character;
    if (char != null && char.isNotEmpty) {
      char = normalizeCharacter(char);
      return SendKey(char.codeUnitAt(0), char);
    }

    return const SwallowKey();
  }

  /// テンキーからの数字（0〜9）取得
  static int? _digitFromNumpad(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.numpad0) return 0;
    if (key == LogicalKeyboardKey.numpad1) return 1;
    if (key == LogicalKeyboardKey.numpad2) return 2;
    if (key == LogicalKeyboardKey.numpad3) return 3;
    if (key == LogicalKeyboardKey.numpad4) return 4;
    if (key == LogicalKeyboardKey.numpad5) return 5;
    if (key == LogicalKeyboardKey.numpad6) return 6;
    if (key == LogicalKeyboardKey.numpad7) return 7;
    if (key == LogicalKeyboardKey.numpad8) return 8;
    if (key == LogicalKeyboardKey.numpad9) return 9;
    return null;
  }

  /// メインキーボードの数字キー（0〜9）判定
  static int? _digitFromLogicalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit0) return 0;
    if (key == LogicalKeyboardKey.digit1) return 1;
    if (key == LogicalKeyboardKey.digit2) return 2;
    if (key == LogicalKeyboardKey.digit3) return 3;
    if (key == LogicalKeyboardKey.digit4) return 4;
    if (key == LogicalKeyboardKey.digit5) return 5;
    if (key == LogicalKeyboardKey.digit6) return 6;
    if (key == LogicalKeyboardKey.digit7) return 7;
    if (key == LogicalKeyboardKey.digit8) return 8;
    if (key == LogicalKeyboardKey.digit9) return 9;
    return null;
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
