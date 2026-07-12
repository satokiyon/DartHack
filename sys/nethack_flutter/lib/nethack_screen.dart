import 'package:flutter/foundation.dart';

class GlyphData {
  final String char;
  final int color;
  final int tile;
  final int special;

  GlyphData({
    required this.char,
    required this.color,
    required this.tile,
    required this.special,
  });

  factory GlyphData.empty() => GlyphData(char: ' ', color: 0, tile: -1, special: 0);
}

class MenuItemData {
  final int ident;
  final int accelerator;
  final int groupacc;
  final int attr;
  final String text;
  final int preselected;
  final int color;

  MenuItemData({
    required this.ident,
    required this.accelerator,
    required this.groupacc,
    required this.attr,
    required this.text,
    required this.preselected,
    required this.color,
  });
}

class NetHackScreen extends ChangeNotifier {
  // ウィンドウタイプ定義
  static const int nhwMessage = 1;
  static const int nhwStatus = 2;
  static const int nhwMap = 3;
  static const int nhwMenu = 4;
  static const int nhwText = 5;

  // ウィンドウID -> ウィンドウタイプ
  final Map<int, int> _winTypes = {};

  // メッセージ
  final List<String> _messages = [];
  List<String> get messages => _messages;

  // メッセージ履歴 (clearWindow で消去されない永続バッファ)
  final List<String> _messageHistory = [];
  List<String> get messageHistory => _messageHistory;

  // ステータス (通常2行)
  final List<String> _statusLines = ["", ""];
  List<String> get statusLines => _statusLines;

  // マップ (21行 x 80列)
  static const int mapRows = 21;
  static const int mapCols = 80;
  final List<List<GlyphData>> _mapGrid = List.generate(
    mapRows,
    (_) => List.generate(mapCols, (_) => GlyphData.empty()),
  );
  List<List<GlyphData>> get mapGrid => _mapGrid;

  // テキスト表示用バッファ (NHW_TEXT 用)
  final List<String> _textLines = [];
  List<String> get textLines => _textLines;
  bool _isTextWindowVisible = false;
  bool get isTextWindowVisible => _isTextWindowVisible && _menuItems.isEmpty;

  // メニュー表示用バッファ (NHW_MENU 用)
  final List<MenuItemData> _menuItems = [];
  List<MenuItemData> get menuItems => _menuItems;
  String _menuPrompt = "";
  String get menuPrompt => _menuPrompt;
  bool _isMenuWindowVisible = false;
  bool get isMenuWindowVisible => _isMenuWindowVisible;
  int _menuHow = 0;
  int get menuHow => _menuHow;
  int _activeMenuWinId = -1;
  int get activeMenuWinId => _activeMenuWinId;

  // カーソル
  int _cursorX = 0;
  int _cursorY = 0;
  int get cursorX => _cursorX;
  int get cursorY => _cursorY;
  int _statusCursorY = 0;

  // プレイヤー位置 (u.ux, u.uy)。C 側の flutter_cliparound から通知される。
  // 未初期化時は -1 とし、マップタップでの #herecmdmenu 判定に使用する。
  int _playerX = -1;
  int _playerY = -1;
  int get playerX => _playerX;
  int get playerY => _playerY;

  NetHackScreen() {
    _clearMapGrid();
  }

  void _clearMapGrid() {
    for (int r = 0; r < mapRows; r++) {
      for (int c = 0; c < mapCols; c++) {
        _mapGrid[r][c] = GlyphData.empty();
      }
    }
  }

  void createWindow(int winId, int type) {
    _winTypes[winId] = type;
    if (type == nhwText) {
      _textLines.clear();
      _isTextWindowVisible = true;
    }
    if (type == nhwMenu) {
      _textLines.clear();
      _isTextWindowVisible = false;
      _menuItems.clear();
      _menuPrompt = "";
    }
    if (type == nhwMessage) {
      _messageHistory.clear();
    }
    notifyListeners();
  }

  void clearWindow(int winId) {
    final type = _winTypes[winId];
    if (type == nhwMap) {
      _clearMapGrid();
    } else if (type == nhwMessage) {
      _messages.clear();
    } else if (type == nhwStatus) {
      _statusLines[0] = "";
      _statusLines[1] = "";
    } else if (type == nhwText || type == nhwMenu) {
      _textLines.clear();
    }
    if (type == nhwMenu) {
      _menuItems.clear();
      _menuPrompt = "";
    }
    notifyListeners();
  }

  void destroyWindow(int winId) {
    final type = _winTypes[winId];
    _winTypes.remove(winId);
    if (type == nhwText || type == nhwMenu) {
      _isTextWindowVisible = false;
      _textLines.clear();
    }
    if (type == nhwMenu) {
      _isMenuWindowVisible = false;
      _menuItems.clear();
      _menuPrompt = "";
    }
    notifyListeners();
  }

  void setCursor(int winId, int x, int y) {
    final type = _winTypes[winId];
    if (type == nhwMap || winId == 3 /* WIN_MAP */) {
      _cursorX = x;
      _cursorY = y;
      notifyListeners();
    } else if (type == nhwStatus || winId == 2 /* WIN_STATUS */) {
      _statusCursorY = y;
    }
  }

  // プレイヤー位置 (u.ux, u.uy) を C 側から受け取り保持する。
  // マップの主人公タップ → #herecmdmenu 起動の判定に利用する。
  // 値が変わったときのみ notifyListeners() を呼んで再描画を抑える。
  void setPlayerPos(int x, int y) {
    if (_playerX == x && _playerY == y) {
      return;
    }
    _playerX = x;
    _playerY = y;
    notifyListeners();
  }

  void putString(int winId, int attr, String text) {
    final type = _winTypes[winId];
    final bool noHistory = (attr & 0x8000) != 0;

    if (type == nhwMessage || winId == 1 /* WIN_MESSAGE */) {
      _messages.add(text);
      if (_messages.length > 100) {
        _messages.removeAt(0);
      }
      if (!noHistory) {
        _messageHistory.add(text);
        if (_messageHistory.length > 100) {
          _messageHistory.removeAt(0);
        }
      }
    } else if (type == nhwStatus || winId == 2 /* WIN_STATUS */) {
      if (_statusCursorY >= 0 && _statusCursorY < _statusLines.length) {
        _statusLines[_statusCursorY] = text;
      } else {
        // フォールバック
        if (_statusLines[0].isEmpty) {
          _statusLines[0] = text;
        } else if (_statusLines[1].isEmpty) {
          _statusLines[1] = text;
        } else {
          _statusLines[0] = _statusLines[1];
          _statusLines[1] = text;
        }
      }
    } else if (type == nhwText || type == nhwMenu) {
      _textLines.add(text);
    }
    notifyListeners();
  }

  void displayWindow(int winId, bool blocking) {
    final type = _winTypes[winId];

    if (type == nhwText) {
      _isTextWindowVisible = true;
      _isMenuWindowVisible = false;
      notifyListeners();
      return;
    }

    if (type == nhwMenu) {
      if (_menuItems.isNotEmpty) {
        _isMenuWindowVisible = true;
        _isTextWindowVisible = false;
      } else if (_textLines.isNotEmpty) {
        _isTextWindowVisible = true;
        _isMenuWindowVisible = false;
      }
      notifyListeners();
      return;
    }
  }

  void printGlyph(int winId, int x, int y, int tile, int ch, int color, int special) {
    final type = _winTypes[winId];
    if ((type == nhwMap || winId == 3 /* WIN_MAP */) && x >= 0 && x < mapCols && y >= 0 && y < mapRows) {
      final charStr = String.fromCharCode(ch);
      _mapGrid[y][x] = GlyphData(
        char: charStr.isNotEmpty ? charStr : ' ',
        color: color,
        tile: tile,
        special: special,
      );
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // メニュー関連制御メソッド
  // ----------------------------------------------------

  void startMenu(int winId) {
    _textLines.clear();
    _isTextWindowVisible = false;
    _isMenuWindowVisible = false;
    _menuItems.clear();
    _menuPrompt = "";
    notifyListeners();
  }

  void addMenu(
    int winId,
    int ident,
    int accelerator,
    int groupacc,
    int attr,
    String text,
    int preselected,
    int color,
  ) {
    _menuItems.add(MenuItemData(
      ident: ident,
      accelerator: accelerator,
      groupacc: groupacc,
      attr: attr,
      text: text,
      preselected: preselected,
      color: color,
    ));
    notifyListeners();
  }

  void endMenu(int winId, String prompt) {
    _menuPrompt = prompt;
    notifyListeners();
  }

  void selectMenu(int winId, int how) {
    _isMenuWindowVisible = true;
    _menuHow = how;
    _activeMenuWinId = winId;
    notifyListeners();
  }

  void clearMenu() {
    _isMenuWindowVisible = false;
    _isTextWindowVisible = false;
    _menuItems.clear();
    _menuPrompt = "";
    _activeMenuWinId = -1;
    notifyListeners();
  }
}
