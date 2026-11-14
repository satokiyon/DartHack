import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_prefs.dart';
import 'keyboard_help_dialog.dart';

/// 汎用 Markdown ドキュメントビューワのスクロール位置保持用データ
class MarkdownDocScrollState {
  int index = 0;
  double alignment = 0.0;
  bool? isJp;
  int blockCount = 0;

  void reset() {
    index = 0;
    alignment = 0.0;
    isJp = null;
    blockCount = 0;
  }
}

enum _DocBlockKind {
  heading,
  paragraph,
  callout,
  table,
  code,
  image,
  divider,
}

enum _DocCalloutKind {
  note,
  tip,
  important,
  warning,
  caution,
}

enum _DocButtonFocus {
  none,
  search,
  prevMatch,
  nextMatch,
  peek,
  toc,
  close,
}

class _DocSection {
  final int blockIndex;
  final String title;
  final int level;
  final String anchorId;

  const _DocSection({
    required this.blockIndex,
    required this.title,
    required this.level,
    required this.anchorId,
  });
}

class _DocBlock {
  final _DocBlockKind kind;
  final String rawText;
  final int headingLevel;
  final String anchorId;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String imagePath;
  final String imageFallbackPath;
  final String imageCaption;
  final _DocCalloutKind calloutKind;

  const _DocBlock({
    required this.kind,
    required this.rawText,
    this.headingLevel = 0,
    this.anchorId = '',
    this.tableHeaders = const [],
    this.tableRows = const [],
    this.imagePath = '',
    this.imageFallbackPath = '',
    this.imageCaption = '',
    this.calloutKind = _DocCalloutKind.note,
  });
}

/// 目次・全文検索・透過(Peek)・キーボード操作・画像ピンチズームを備えた汎用 Markdown ビューワ
class MarkdownDocViewerDialog extends StatefulWidget {
  final String title;
  final String searchHint;
  final IconData headerIcon;
  final Color accentColor;
  final Future<({String markdown, bool isJp})> Function() loadDocument;
  final ({String path, String fallbackPath}) Function(String rawPath, bool isJp)?
      imagePathResolver;
  final MarkdownDocScrollState? scrollState;
  final String? initialMarkdown;
  final bool? initialIsJp;

  const MarkdownDocViewerDialog({
    super.key,
    required this.title,
    required this.searchHint,
    required this.loadDocument,
    this.headerIcon = Icons.article_outlined,
    this.accentColor = Colors.cyanAccent,
    this.imagePathResolver,
    this.scrollState,
    this.initialMarkdown,
    this.initialIsJp,
  });

  @override
  State<MarkdownDocViewerDialog> createState() =>
      _MarkdownDocViewerDialogState();
}

class _MarkdownDocViewerDialogState extends State<MarkdownDocViewerDialog> {
  bool _isLoading = true;
  bool _isJp = true;
  List<_DocBlock> _blocks = [];
  List<_DocSection> _sections = [];
  final Map<String, int> _anchorMap = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  final Map<int, ScrollController> _horizontalScrollControllers = {};

  List<int> _searchResults = [];
  int _currentSearchMatchIndex = -1;
  int? _highlightedBlockIndex;
  Timer? _flashTimer;

  bool _isHoldPeeking = false;
  bool _isTapPeeking = false;
  bool _usePhysicalKeyboardNotation = false;
  _DocButtonFocus _buttonFocus = _DocButtonFocus.none;

  bool get _isPeeking => _isHoldPeeking || _isTapPeeking;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.onKeyEvent = _handleSearchKeyEvent;
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _load();
    AppPrefs.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _usePhysicalKeyboardNotation =
              prefs.getBool('use_physical_keyboard_notation') ?? false;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    _searchFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    _flashTimer?.cancel();
    _searchController.dispose();
    for (final c in _horizontalScrollControllers.values) {
      c.dispose();
    }
    _horizontalScrollControllers.clear();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      if (widget.initialMarkdown != null) {
        _parseMarkdown(widget.initialMarkdown!, widget.initialIsJp ?? true);
        return;
      }
      final doc = await widget.loadDocument();
      if (!mounted) return;
      _parseMarkdown(doc.markdown, widget.initialIsJp ?? doc.isJp);
    } catch (e) {
      if (mounted) {
        setState(() {
          _blocks = [
            _DocBlock(
              kind: _DocBlockKind.paragraph,
              rawText: e.toString(),
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _onItemPositionsChanged() {
    final state = widget.scrollState;
    if (state == null || _isLoading || _blocks.isEmpty) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    ItemPosition? topItem;
    for (final pos in positions) {
      if (pos.itemTrailingEdge > 0) {
        if (topItem == null || pos.index < topItem.index) {
          topItem = pos;
        }
      }
    }
    if (topItem != null) {
      state.index = topItem.index;
      state.alignment = topItem.itemLeadingEdge;
      state.isJp = _isJp;
      state.blockCount = _blocks.length;
    }
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-\u3000-\u9FFF\uFF00-\uFFEF]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
  }

  List<String> _parseTableRow(String row) {
    var inner = row.trim();
    if (inner.startsWith('|')) inner = inner.substring(1);
    if (inner.endsWith('|')) inner = inner.substring(0, inner.length - 1);

    final cells = <String>[];
    final current = StringBuffer();
    int i = 0;

    while (i < inner.length) {
      if (inner[i] == '\\' && i + 1 < inner.length && inner[i + 1] == '|') {
        current.write('|');
        i += 2;
        continue;
      }
      if (inner[i] == '`') {
        int ticks = 0;
        while (i + ticks < inner.length && inner[i + ticks] == '`') {
          ticks++;
        }
        final delim = '`' * ticks;
        current.write(delim);
        i += ticks;
        final closeIdx = inner.indexOf(delim, i);
        if (closeIdx != -1) {
          current.write(inner.substring(i, closeIdx + ticks));
          i = closeIdx + ticks;
        }
        continue;
      }
      if (inner[i] == '|') {
        cells.add(current.toString().trim());
        current.clear();
        i++;
      } else {
        current.write(inner[i]);
        i++;
      }
    }
    cells.add(current.toString().trim());
    return cells;
  }

  void _parseMarkdown(String content, bool isJp) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_DocBlock>[];
    final sections = <_DocSection>[];
    final anchorMap = <String, int>{};

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // 水平線
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(const _DocBlock(kind: _DocBlockKind.divider, rawText: ''));
        i++;
        continue;
      }

      // コードブロック
      if (trimmed.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++;
        blocks.add(_DocBlock(
          kind: _DocBlockKind.code,
          rawText: codeLines.join('\n'),
        ));
        continue;
      }

      // コールアウト (> [!TIP] など) / 引用ブロック
      if (trimmed.startsWith('>')) {
        final quoteLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          var q = lines[i].trim().substring(1);
          if (q.startsWith(' ')) q = q.substring(1);
          quoteLines.add(q);
          i++;
        }
        if (quoteLines.isNotEmpty) {
          _DocCalloutKind cKind = _DocCalloutKind.note;
          final first = quoteLines.first.trim();
          final tagMatch =
              RegExp(r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*(.*)$',
                      caseSensitive: false)
                  .firstMatch(first);
          if (tagMatch != null) {
            final tag = tagMatch.group(1)!.toUpperCase();
            switch (tag) {
              case 'TIP':
                cKind = _DocCalloutKind.tip;
                break;
              case 'IMPORTANT':
                cKind = _DocCalloutKind.important;
                break;
              case 'WARNING':
                cKind = _DocCalloutKind.warning;
                break;
              case 'CAUTION':
                cKind = _DocCalloutKind.caution;
                break;
              default:
                cKind = _DocCalloutKind.note;
            }
            final restFirst = tagMatch.group(2)?.trim() ?? '';
            quoteLines.removeAt(0);
            if (restFirst.isNotEmpty) {
              quoteLines.insert(0, restFirst);
            }
          }
          blocks.add(_DocBlock(
            kind: _DocBlockKind.callout,
            rawText: quoteLines.join('\n'),
            calloutKind: cKind,
          ));
        }
        continue;
      }

      // 画像 ![alt](path) ＋ 直後のキャプション行 (*図 ...* / *Figure ...*) 先読み消費
      final imgMatch =
          RegExp(r'^!\[(.*?)\]\((?:asset:)?(.*?)\)$').firstMatch(trimmed);
      if (imgMatch != null) {
        final alt = imgMatch.group(1)!.trim();
        final rawPath = imgMatch.group(2)!.trim();
        var caption = alt;

        if (i + 1 < lines.length) {
          final nextTrim = lines[i + 1].trim();
          if (nextTrim.startsWith('*') &&
              nextTrim.endsWith('*') &&
              nextTrim.length > 2 &&
              !nextTrim.startsWith('**')) {
            caption = nextTrim.substring(1, nextTrim.length - 1).trim();
            i++;
          }
        }

        final resolved = widget.imagePathResolver != null
            ? widget.imagePathResolver!(rawPath, isJp)
            : (path: rawPath, fallbackPath: '');

        blocks.add(_DocBlock(
          kind: _DocBlockKind.image,
          rawText: caption,
          imagePath: resolved.path,
          imageFallbackPath: resolved.fallbackPath,
          imageCaption: caption,
        ));
        i++;
        continue;
      }

      // 見出し (# .. ######)
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        var titleRaw = headingMatch.group(2)!.trim();
        String anchorId = '';
        final anchorMatch =
            RegExp(r'\{#([a-zA-Z0-9_.-]+)[^}]*\}\s*$').firstMatch(titleRaw);
        if (anchorMatch != null) {
          anchorId = anchorMatch.group(1)!;
          titleRaw = titleRaw.substring(0, anchorMatch.start).trim();
        }

        final blockIndex = blocks.length;
        blocks.add(_DocBlock(
          kind: _DocBlockKind.heading,
          rawText: titleRaw,
          headingLevel: level,
          anchorId: anchorId,
        ));

        if (anchorId.isNotEmpty) {
          anchorMap[anchorId] = blockIndex;
        }
        final autoSlug = _generateSlug(titleRaw);
        if (autoSlug.isNotEmpty && !anchorMap.containsKey(autoSlug)) {
          anchorMap[autoSlug] = blockIndex;
        }

        sections.add(_DocSection(
          blockIndex: blockIndex,
          title: titleRaw,
          level: level,
          anchorId: anchorId,
        ));

        i++;
        continue;
      }

      // テーブル
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length &&
            lines[i].trim().startsWith('|') &&
            lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        if (tableLines.length >= 2) {
          final headers = _parseTableRow(tableLines[0]);
          final rows = <List<String>>[];
          final hasSep = RegExp(r'^\|[\s:?-]+\|').hasMatch(tableLines[1]);
          for (int r = hasSep ? 2 : 1; r < tableLines.length; r++) {
            rows.add(_parseTableRow(tableLines[r]));
          }
          blocks.add(_DocBlock(
            kind: _DocBlockKind.table,
            rawText: tableLines.join(' '),
            tableHeaders: headers,
            tableRows: rows,
          ));
          continue;
        }
      }

      // 番号付きリスト項目（1項目1ブロックにして検索ジャンプ精度を高める）
      if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final itemLines = <String>[trimmed];
        i++;
        while (i < lines.length) {
          final next = lines[i];
          final nextTrim = next.trim();
          if (nextTrim.isEmpty ||
              nextTrim.startsWith('#') ||
              nextTrim.startsWith('```') ||
              nextTrim.startsWith('>') ||
              nextTrim.startsWith('---') ||
              (nextTrim.startsWith('|') && nextTrim.endsWith('|')) ||
              RegExp(r'^\d+\.\s+').hasMatch(nextTrim) ||
              RegExp(r'^!\[.*?\]\(').hasMatch(nextTrim)) {
            break;
          }
          itemLines.add(nextTrim);
          i++;
        }
        blocks.add(_DocBlock(
          kind: _DocBlockKind.paragraph,
          rawText: itemLines.join('\n'),
        ));
        continue;
      }

      // 通常段落
      final paragraphLines = <String>[];
      while (i < lines.length) {
        final l = lines[i];
        final tr = l.trim();
        if (tr.isEmpty ||
            tr.startsWith('#') ||
            tr.startsWith('```') ||
            tr.startsWith('>') ||
            tr.startsWith('---') ||
            (tr.startsWith('|') && tr.endsWith('|')) ||
            RegExp(r'^\d+\.\s+').hasMatch(tr) ||
            RegExp(r'^!\[.*?\]\(').hasMatch(tr)) {
          break;
        }
        paragraphLines.add(l);
        i++;
      }
      blocks.add(_DocBlock(
        kind: _DocBlockKind.paragraph,
        rawText: paragraphLines.join('\n'),
      ));
    }

    if (mounted) {
      setState(() {
        _isJp = isJp;
        _blocks = blocks;
        _sections = sections;
        _anchorMap
          ..clear()
          ..addAll(anchorMap);
        _isLoading = false;
      });
    }
  }

  void _scrollToBlock(int blockIndex) {
    if (_blocks.isEmpty || !_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: blockIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _jumpToAndFlash(int blockIndex) {
    _scrollToBlock(blockIndex);
    _flashTimer?.cancel();
    setState(() {
      _highlightedBlockIndex = blockIndex;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _highlightedBlockIndex = null;
        });
      }
    });
  }

  void _scrollByBlocks(int delta) {
    if (_blocks.isEmpty || !_itemScrollController.isAttached) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    ItemPosition? topItem;
    for (final pos in positions) {
      if (pos.itemTrailingEdge > 0) {
        if (topItem == null || pos.index < topItem.index) {
          topItem = pos;
        }
      }
    }
    if (topItem == null) return;
    final targetIndex = (topItem.index + delta).clamp(0, _blocks.length - 1);
    _itemScrollController.scrollTo(
      index: targetIndex,
      alignment: 0.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _scrollVisibleHorizontal(double delta) {
    final positions = _itemPositionsListener.itemPositions.value;
    for (final pos in positions) {
      final controller = _horizontalScrollControllers[pos.index];
      if (controller != null && controller.hasClients) {
        final next = (controller.offset + delta)
            .clamp(0.0, controller.position.maxScrollExtent);
        controller.animateTo(
          next,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchMatchIndex = -1;
      });
      return;
    }

    final matches = <int>[];
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].rawText.toLowerCase().contains(q)) {
        matches.add(i);
      }
    }

    setState(() {
      _searchResults = matches;
      _currentSearchMatchIndex = matches.isNotEmpty ? 0 : -1;
    });

    if (matches.isNotEmpty) {
      _scrollToBlock(matches[0]);
    }
  }

  void _navigateSearchMatch(int delta) {
    if (_searchResults.isEmpty) return;
    final nextIdx = (_currentSearchMatchIndex + delta) % _searchResults.length;
    final wrapped = nextIdx < 0 ? _searchResults.length - 1 : nextIdx;
    setState(() {
      _currentSearchMatchIndex = wrapped;
    });
    _scrollToBlock(_searchResults[wrapped]);
  }

  void _setButtonFocus(_DocButtonFocus focus) {
    setState(() {
      _buttonFocus = focus;
      if (focus == _DocButtonFocus.search) {
        _searchFocusNode.requestFocus();
      } else {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
        _mainFocusNode.requestFocus();
      }
    });
  }

  void _cycleButtonFocus(bool forward) {
    final order = <_DocButtonFocus>[
      _DocButtonFocus.none,
      _DocButtonFocus.search,
      if (_searchResults.isNotEmpty) _DocButtonFocus.prevMatch,
      if (_searchResults.isNotEmpty) _DocButtonFocus.nextMatch,
      _DocButtonFocus.peek,
      if (_sections.isNotEmpty) _DocButtonFocus.toc,
      _DocButtonFocus.close,
    ];
    final idx = order.indexOf(_buttonFocus);
    final current = idx == -1 ? 0 : idx;
    final nextIdx = forward
        ? (current + 1) % order.length
        : (current - 1 + order.length) % order.length;
    _setButtonFocus(order[nextIdx]);
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _cycleButtonFocus(!HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        _onSearchChanged('');
      } else {
        _setButtonFocus(_DocButtonFocus.none);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _navigateSearchMatch(
          HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isDown = event is KeyDownEvent;
    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    if (_isTapPeeking) {
      if (isDown) {
        setState(() {
          _isTapPeeking = false;
        });
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      if (isDown) Navigator.pop(context);
      return KeyEventResult.handled;
    }

    final isTextFieldFocused = _searchFocusNode.hasFocus ||
        FocusManager.instance.primaryFocus?.context?.widget is EditableText;
    if (isTextFieldFocused) {
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (isDown) _navigateSearchMatch(isShift ? -1 : 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.f1 ||
        (isAlt && key == LogicalKeyboardKey.keyH)) {
      if (isDown && _usePhysicalKeyboardNotation) {
        KeyboardHelpDialog.show(
          context,
          helpContext: KeyboardHelpContext.guidebook,
          isJapanese: _isJp,
        );
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.tab) {
      if (isDown) _cycleButtonFocus(!isShift);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        (key == LogicalKeyboardKey.space &&
            (_buttonFocus == _DocButtonFocus.peek ||
                _buttonFocus == _DocButtonFocus.prevMatch ||
                _buttonFocus == _DocButtonFocus.nextMatch))) {
      if (isDown) {
        switch (_buttonFocus) {
          case _DocButtonFocus.prevMatch:
            _navigateSearchMatch(-1);
            return KeyEventResult.handled;
          case _DocButtonFocus.nextMatch:
            _navigateSearchMatch(1);
            return KeyEventResult.handled;
          case _DocButtonFocus.peek:
            setState(() => _isTapPeeking = true);
            return KeyEventResult.handled;
          case _DocButtonFocus.toc:
            _showTOCModal();
            return KeyEventResult.handled;
          case _DocButtonFocus.close:
            Navigator.pop(context);
            return KeyEventResult.handled;
          case _DocButtonFocus.search:
          case _DocButtonFocus.none:
            break;
        }
      }
      if (_buttonFocus != _DocButtonFocus.none) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.keyT && !isCtrl) {
      if (isDown && _sections.isNotEmpty) _showTOCModal();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN && !isCtrl) {
      if (isDown) _navigateSearchMatch(isShift ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyQ && !isCtrl) {
      if (isDown) Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.slash && !isCtrl) {
      if (isDown) _setButtonFocus(_DocButtonFocus.search);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.pageDown ||
        event.character == '>') {
      _scrollByBlocks(
          (key == LogicalKeyboardKey.space && isShift) ? -6 : 6);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp || event.character == '<') {
      _scrollByBlocks(-6);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      if (isDown) _scrollToBlock(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end && _blocks.isNotEmpty) {
      if (isDown) _scrollToBlock(_blocks.length - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyJ) {
      _scrollByBlocks(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      _scrollByBlocks(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _scrollVisibleHorizontal(120);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _scrollVisibleHorizontal(-120);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildHoldPeekDetector({
    required Widget child,
    HitTestBehavior? behavior,
  }) {
    return RawGestureDetector(
      behavior: behavior,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 220),
          ),
          (instance) {
            instance
              ..onLongPressStart = (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (mounted) setState(() => _isHoldPeeking = true);
              }
              ..onLongPressEnd = (_) {
                if (_isHoldPeeking && mounted) {
                  setState(() => _isHoldPeeking = false);
                }
              }
              ..onLongPressCancel = () {
                if (_isHoldPeeking && mounted) {
                  setState(() => _isHoldPeeking = false);
                }
              };
          },
        ),
      },
      child: child,
    );
  }

  void _showTOCModal() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return _TOCBottomSheet(
          sections: _sections,
          accentColor: widget.accentColor,
          title: l10n?.tocTitle(_sections.length) ??
              'Table of Contents (${_sections.length})',
          filterHint: _isJp ? '見出しを絞り込み...' : 'Filter sections...',
          onSelect: (blockIndex) {
            Navigator.pop(sheetCtx);
            _jumpToAndFlash(blockIndex);
          },
          onClose: () => Navigator.pop(sheetCtx),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        _mainFocusNode.requestFocus();
      }
    });
  }

  void _showImageZoomDialog(
      String path, String fallbackPath, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dlgCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Center(
                          child: _buildAssetImageWithFallback(
                            path,
                            fallbackPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (caption.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          caption,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () => Navigator.pop(dlgCtx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetImageWithFallback(
    String path,
    String fallbackPath, {
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (ctx, err, st) {
        if (fallbackPath.isNotEmpty && fallbackPath != path) {
          return Image.asset(
            fallbackPath,
            fit: fit,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 40,
            ),
          );
        }
        return const Icon(
          Icons.broken_image_outlined,
          color: Colors.white38,
          size: 40,
        );
      },
    );
  }

  void _handleLinkTap(String href) {
    final clean = href.trim();
    if (clean.startsWith('#')) {
      final slug = clean.substring(1);
      final target = _anchorMap[slug] ?? _anchorMap[_generateSlug(slug)];
      if (target != null) {
        _jumpToAndFlash(target);
        return;
      }
    }
    Clipboard.setData(ClipboardData(text: clean));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isJp
              ? 'リンクをコピーしました: $clean'
              : 'Copied link: $clean'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildRichText(String text, {double fontSize = 14.0}) {
    final query = _searchController.text.trim().toLowerCase();
    final spans = <InlineSpan>[];
    final tokenRegex = RegExp(
      r'(`[^`]+`)|(\*\*[^*]+\*\*)|(\*[^*]+\*)|(\[[^\]]+\]\([^)]+\))',
    );

    void addPlainWithHighlight(String segment, TextStyle baseStyle) {
      if (segment.isEmpty) return;
      if (query.isEmpty) {
        spans.add(TextSpan(text: segment, style: baseStyle));
        return;
      }
      final lower = segment.toLowerCase();
      int start = 0;
      while (true) {
        final idx = lower.indexOf(query, start);
        if (idx == -1) {
          if (start < segment.length) {
            spans.add(TextSpan(text: segment.substring(start), style: baseStyle));
          }
          break;
        }
        if (idx > start) {
          spans.add(
              TextSpan(text: segment.substring(start, idx), style: baseStyle));
        }
        spans.add(TextSpan(
          text: segment.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.amberAccent.withValues(alpha: 0.45),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ));
        start = idx + query.length;
      }
    }

    final baseStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.9),
      fontSize: fontSize,
      height: 1.55,
    );

    final lines = text.split('\n');
    for (int lIdx = 0; lIdx < lines.length; lIdx++) {
      var line = lines[lIdx];
      if (line.trimLeft().startsWith('- ')) {
        final indentLen = line.length - line.trimLeft().length;
        final indentPrefix = '  ' * (indentLen ~/ 2);
        line = '$indentPrefix• ${line.trimLeft().substring(2)}';
      }

      int lastEnd = 0;
      for (final match in tokenRegex.allMatches(line)) {
        if (match.start > lastEnd) {
          addPlainWithHighlight(line.substring(lastEnd, match.start), baseStyle);
        }
        final token = match.group(0)!;
        if (token.startsWith('`') && token.endsWith('`')) {
          addPlainWithHighlight(
            token.substring(1, token.length - 1),
            baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: fontSize - 1,
              color: Colors.amberAccent,
              backgroundColor: const Color(0xFF1F2736),
            ),
          );
        } else if (token.startsWith('**') && token.endsWith('**')) {
          addPlainWithHighlight(
            token.substring(2, token.length - 2),
            baseStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          );
        } else if (token.startsWith('*') && token.endsWith('*')) {
          addPlainWithHighlight(
            token.substring(1, token.length - 1),
            baseStyle.copyWith(fontStyle: FontStyle.italic),
          );
        } else if (token.startsWith('[')) {
          final linkMatch = RegExp(r'^\[([^\]]+)\]\(([^)]+)\)$').firstMatch(token);
          if (linkMatch != null) {
            final label = linkMatch.group(1)!;
            final href = linkMatch.group(2)!;
            spans.add(TextSpan(
              text: label,
              style: baseStyle.copyWith(
                color: widget.accentColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _handleLinkTap(href),
            ));
          } else {
            addPlainWithHighlight(token, baseStyle);
          }
        }
        lastEnd = match.end;
      }
      if (lastEnd < line.length) {
        addPlainWithHighlight(line.substring(lastEnd), baseStyle);
      }
      if (lIdx < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildCalloutWidget(_DocBlock block) {
    final (Color color, IconData icon, String label) = switch (block.calloutKind) {
      _DocCalloutKind.tip => (Colors.tealAccent, Icons.lightbulb_outline, 'TIP'),
      _DocCalloutKind.important =>
        (Colors.purpleAccent, Icons.priority_high, 'IMPORTANT'),
      _DocCalloutKind.warning =>
        (Colors.amberAccent, Icons.warning_amber_rounded, 'WARNING'),
      _DocCalloutKind.caution =>
        (Colors.redAccent, Icons.report_gmailerrorred, 'CAUTION'),
      _DocCalloutKind.note => (Colors.lightBlueAccent, Icons.info_outline, 'NOTE'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 17),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (block.rawText.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRichText(block.rawText, fontSize: 13.5),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableWidget(_DocBlock block, int index) {
    final controller =
        _horizontalScrollControllers.putIfAbsent(index, () => ScrollController());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171D29),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              widget.accentColor.withValues(alpha: 0.12),
            ),
            columnSpacing: 16,
            dataRowMinHeight: 34,
            dataRowMaxHeight: double.infinity,
            columns: block.tableHeaders
                .map((h) => DataColumn(
                      label: Text(
                        h,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ))
                .toList(),
            rows: block.tableRows.asMap().entries.map((entry) {
              final rIdx = entry.key;
              final cells = entry.value;
              return DataRow(
                color: WidgetStateProperty.all(
                  rIdx.isEven
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.03),
                ),
                cells: List.generate(block.tableHeaders.length, (colIdx) {
                  final cellText = colIdx < cells.length ? cells[colIdx] : '';
                  return DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildRichText(cellText, fontSize: 12.5),
                    ),
                  );
                }),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(int index, _DocBlock block) {
    final isCurrentMatch = _searchResults.isNotEmpty &&
        _currentSearchMatchIndex >= 0 &&
        _searchResults[_currentSearchMatchIndex] == index;
    final isOtherMatch = _searchResults.contains(index);
    final isFlash = _highlightedBlockIndex == index;

    BoxDecoration? decoration;
    if (isFlash) {
      decoration = BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: widget.accentColor, width: 1.5),
      );
    } else if (isCurrentMatch) {
      decoration = BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(6),
      );
    } else if (isOtherMatch) {
      decoration = BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      );
    }

    Widget content;
    switch (block.kind) {
      case _DocBlockKind.divider:
        content = const Divider(color: Colors.white24, height: 24, thickness: 1);
        break;

      case _DocBlockKind.heading:
        final lvl = block.headingLevel;
        final fSize = switch (lvl) {
          1 => 20.0,
          2 => 17.5,
          3 => 15.5,
          _ => 14.0,
        };
        final hColor = lvl <= 2
            ? Colors.amberAccent
            : (lvl == 3 ? widget.accentColor : Colors.white);
        final pad = lvl <= 2
            ? const EdgeInsets.only(top: 18, bottom: 8)
            : const EdgeInsets.only(top: 12, bottom: 4);

        content = Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.rawText,
                style: TextStyle(
                  color: hColor,
                  fontSize: fSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (lvl <= 2) ...[
                const SizedBox(height: 4),
                Container(
                  height: 1.5,
                  color: widget.accentColor.withValues(alpha: 0.35),
                ),
              ],
            ],
          ),
        );
        break;

      case _DocBlockKind.callout:
        content = _buildCalloutWidget(block);
        break;

      case _DocBlockKind.table:
        content = _buildTableWidget(block, index);
        break;

      case _DocBlockKind.code:
        final cCtrl = _horizontalScrollControllers.putIfAbsent(
            index, () => ScrollController());
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F131C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12, width: 0.8),
          ),
          child: SingleChildScrollView(
            controller: cCtrl,
            scrollDirection: Axis.horizontal,
            child: Text(
              block.rawText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.0,
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ),
        );
        break;

      case _DocBlockKind.image:
        final maxPreviewH =
            (MediaQuery.of(context).size.height * 0.42).clamp(220.0, 360.0);
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (_isPeeking) return;
                  _showImageZoomDialog(
                    block.imagePath,
                    block.imageFallbackPath,
                    block.imageCaption,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1018),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxPreviewH),
                          child: _buildAssetImageWithFallback(
                            block.imagePath,
                            block.imageFallbackPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.zoom_in,
                              color: widget.accentColor, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (block.imageCaption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  block.imageCaption,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
        break;

      case _DocBlockKind.paragraph:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _buildRichText(block.rawText),
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: decoration,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.94;
    final dialogHeight = screenSize.height * 0.92;
    final l10n = AppLocalizations.of(context);

    final state = widget.scrollState;
    final canRestore = state != null &&
        state.isJp == _isJp &&
        state.blockCount == _blocks.length &&
        _blocks.isNotEmpty;
    final initialIndex =
        canRestore ? state.index.clamp(0, _blocks.length - 1) : 0;
    final initialAlign = canRestore ? state.alignment : 0.0;

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_isTapPeeking) {
                  setState(() => _isTapPeeking = false);
                } else {
                  Navigator.pop(context);
                }
              },
              child: AnimatedOpacity(
                opacity: _isPeeking ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Container(color: Colors.black54),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _isTapPeeking,
            child: AnimatedOpacity(
              opacity: _isPeeking ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Container(
                  width: dialogWidth,
                  height: dialogHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12161F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ヘッダー
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E2430),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildHoldPeekDetector(
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    Icon(widget.headerIcon,
                                        color: widget.accentColor, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _buildHeaderIconButton(
                              focusTarget: _DocButtonFocus.peek,
                              icon: Icons.visibility_outlined,
                              tooltip: _isJp
                                  ? '画面を確認（タップで維持 / 長押しで一時透過）'
                                  : 'Peek behind dialog (Tap to hold / Long-press to peek)',
                              wrapHoldPeek: true,
                              onPressed: () {
                                if (_isHoldPeeking) return;
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() => _isTapPeeking = true);
                              },
                            ),
                            if (_sections.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _buildHeaderIconButton(
                                focusTarget: _DocButtonFocus.toc,
                                icon: Icons.toc,
                                tooltip: _isJp
                                    ? '目次を開く'
                                    : 'Open Table of Contents',
                                onPressed: _showTOCModal,
                              ),
                            ],
                            const SizedBox(width: 4),
                            _buildHeaderIconButton(
                              focusTarget: _DocButtonFocus.close,
                              icon: Icons.close,
                              iconColor: Colors.white70,
                              tooltip: l10n?.close ?? 'Close',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // 検索バー
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: const Color(0xFF171C26),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: widget.searchHint,
                                  hintStyle:
                                      const TextStyle(color: Colors.white38),
                                  prefixIcon: Icon(Icons.search,
                                      color: widget.accentColor, size: 18),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              color: Colors.white54, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFF0E121B),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _buttonFocus ==
                                              _DocButtonFocus.search
                                          ? widget.accentColor
                                          : Colors.white12,
                                    ),
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            if (_searchResults.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${_currentSearchMatchIndex + 1}/${_searchResults.length}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              _buildHeaderIconButton(
                                focusTarget: _DocButtonFocus.prevMatch,
                                icon: Icons.keyboard_arrow_up,
                                tooltip: _isJp ? '前の一致 (N)' : 'Previous (N)',
                                onPressed: () => _navigateSearchMatch(-1),
                              ),
                              _buildHeaderIconButton(
                                focusTarget: _DocButtonFocus.nextMatch,
                                icon: Icons.keyboard_arrow_down,
                                tooltip: _isJp ? '次の一致 (n)' : 'Next (n)',
                                onPressed: () => _navigateSearchMatch(1),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      // 本文
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.accentColor),
                                ),
                              )
                            : _buildHoldPeekDetector(
                                behavior: HitTestBehavior.translucent,
                                child: ScrollablePositionedList.builder(
                                  itemScrollController: _itemScrollController,
                                  itemPositionsListener:
                                      _itemPositionsListener,
                                  initialScrollIndex: initialIndex,
                                  initialAlignment: initialAlign,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _blocks.length,
                                  itemBuilder: (ctx, idx) =>
                                      _buildBlockWidget(idx, _blocks[idx]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isTapPeeking)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility,
                            color: widget.accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _isJp ? 'タップして戻る' : 'Tap to return',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required _DocButtonFocus focusTarget,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? iconColor,
    bool wrapHoldPeek = false,
  }) {
    final isFocused = _buttonFocus == focusTarget;
    final btn = IconButton(
      icon: Icon(icon, color: iconColor ?? widget.accentColor, size: 22),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isFocused
            ? widget.accentColor.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFocused ? widget.accentColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: wrapHoldPeek ? _buildHoldPeekDetector(child: btn) : btn,
    );
  }
}

class _TOCBottomSheet extends StatefulWidget {
  final List<_DocSection> sections;
  final Color accentColor;
  final String title;
  final String filterHint;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  const _TOCBottomSheet({
    required this.sections,
    required this.accentColor,
    required this.title,
    required this.filterHint,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<_TOCBottomSheet> createState() => _TOCBottomSheetState();
}

class _TOCBottomSheetState extends State<_TOCBottomSheet> {
  final TextEditingController _filterController = TextEditingController();
  late List<_DocSection> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<_DocSection>.of(widget.sections);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Icon(Icons.toc, color: widget.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _filterController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.filterHint,
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.filter_list, color: widget.accentColor),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFF0F131C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                final q = val.trim().toLowerCase();
                setState(() {
                  _filtered = q.isEmpty
                      ? List<_DocSection>.of(widget.sections)
                      : widget.sections
                          .where((s) => s.title.toLowerCase().contains(q))
                          .toList();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, idx) {
                final sec = _filtered[idx];
                final indent = (sec.level - 1).clamp(0, 3) * 16.0;
                return ListTile(
                  dense: true,
                  contentPadding:
                      EdgeInsets.only(left: 16 + indent, right: 16),
                  title: Text(
                    sec.title,
                    style: TextStyle(
                      color: sec.level <= 2 ? Colors.white : Colors.white70,
                      fontWeight: sec.level <= 2
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: sec.level <= 2 ? 14 : 13,
                    ),
                  ),
                  onTap: () => widget.onSelect(sec.blockIndex),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
