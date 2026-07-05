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

  factory GlyphData.empty() {
    return GlyphData(char: ' ', color: 0, tile: -1, special: 0);
  }
}

class NetHackScreen extends ChangeNotifier {
  static const int nhwMessage = 1;
  static const int nhwStatus = 2;
  static const int nhwMap = 3;
  static const int nhwMenu = 4;
  static const int nhwText = 5;

  final Map<int, int> _winTypes = {};

  // メッセージ
  final List<String> _messages = [];
  List<String> get messages => _messages;

  // ステータス (通常2行)
  final List<String> _statusLines = ["", ""];
  List<String> get statusLines => _statusLines;

  // マップ (21行 x 80列)
  static const int mapRows = 21;
  static const int mapCols = 80;
  late final List<List<GlyphData>> _mapGrid;
  List<List<GlyphData>> get mapGrid => _mapGrid;

  // テキスト表示用バッファ (NHW_TEXT 用)
  final List<String> _textLines = [];
  List<String> get textLines => _textLines;
  bool _isTextWindowVisible = false;
  bool get isTextWindowVisible => _isTextWindowVisible;

  // カーソル
  int _cursorX = 0;
  int _cursorY = 0;
  int get cursorX => _cursorX;
  int get cursorY => _cursorY;

  NetHackScreen() {
    _clearMapGrid();
  }

  void _clearMapGrid() {
    _mapGrid = List.generate(
      mapRows,
      (_) => List.generate(mapCols, (_) => GlyphData.empty()),
    );
  }

  void createWindow(int winId, int type) {
    _winTypes[winId] = type;
    if (type == nhwText) {
      _textLines.clear();
      _isTextWindowVisible = true;
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
    } else if (type == nhwText) {
      _textLines.clear();
    }
    notifyListeners();
  }

  void destroyWindow(int winId) {
    final type = _winTypes[winId];
    _winTypes.remove(winId);
    if (type == nhwText) {
      _isTextWindowVisible = false;
    }
    notifyListeners();
  }

  void setCursor(int winId, int x, int y) {
    final type = _winTypes[winId];
    if (type == nhwMap) {
      _cursorX = x;
      _cursorY = y;
      notifyListeners();
    }
  }

  void putString(int winId, int attr, String text) {
    final type = _winTypes[winId];
    if (type == nhwMessage || winId == 1 /* WIN_MESSAGE */) {
      _messages.add(text);
      if (_messages.length > 100) {
        _messages.removeAt(0);
      }
    } else if (type == nhwStatus || winId == 2 /* WIN_STATUS */) {
      if (_statusLines[0].isEmpty) {
        _statusLines[0] = text;
      } else if (_statusLines[1].isEmpty) {
        _statusLines[1] = text;
      } else {
        _statusLines[0] = _statusLines[1];
        _statusLines[1] = text;
      }
    } else if (type == nhwText) {
      _textLines.add(text);
    }
    notifyListeners();
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
}
