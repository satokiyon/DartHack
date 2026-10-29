// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-10-30.
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../utils/app_prefs.dart';

import '../l10n/app_localizations.dart';
import 'spoiler_dialog.dart';

/// NetHack 5.0 ガイドブック（日本語 Guidebook_JP.md / 英語 Guidebook.md）閲覧ダイアログ
class GuidebookDialog extends StatefulWidget {
  final String? initialContent;
  final bool? initialIsJp;

  const GuidebookDialog({
    super.key,
    this.initialContent,
    this.initialIsJp,
  });

  static int _savedScrollIndex = 0;
  static double _savedScrollAlignment = 0.0;
  static bool? _savedIsJp;
  static int _savedBlockCount = 0;

  @visibleForTesting
  static void resetSavedScrollPosition() {
    _savedScrollIndex = 0;
    _savedScrollAlignment = 0.0;
    _savedIsJp = null;
    _savedBlockCount = 0;
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => const GuidebookDialog(),
    );
  }

  @override
  State<GuidebookDialog> createState() => _GuidebookDialogState();
}

enum _BlockKind {
  heading,
  paragraph,
  table,
  code,
  details,
  image,
  divider,
}

class _GuidebookSection {
  final int blockIndex;
  final String title;
  final int level;
  final String anchorId;

  _GuidebookSection({
    required this.blockIndex,
    required this.title,
    required this.level,
    required this.anchorId,
  });
}

class _GuidebookBlock {
  final _BlockKind kind;
  final String rawText;
  final int headingLevel;
  final String anchorId;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String imagePath;
  final String imageCaption;
  final String detailsSummary;
  final String detailsContent;

  _GuidebookBlock({
    required this.kind,
    required this.rawText,
    this.headingLevel = 0,
    this.anchorId = '',
    this.tableHeaders = const [],
    this.tableRows = const [],
    this.imagePath = '',
    this.imageCaption = '',
    this.detailsSummary = '',
    this.detailsContent = '',
  });
}

class _GuidebookDialogState extends State<GuidebookDialog> {
  bool _isLoading = true;
  bool _isJp = true;
  List<_GuidebookBlock> _blocks = [];
  List<_GuidebookSection> _sections = [];
  final Map<String, int> _anchorMap = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  List<int> _searchResults = [];
  int _currentSearchMatchIndex = -1;
  int? _highlightedBlockIndex;
  Timer? _flashTimer;

  // 一時透過（覗き見）制御用状態
  bool _isHoldPeeking = false;
  bool _isTapPeeking = false;

  bool get _isPeeking => _isHoldPeeking || _isTapPeeking;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _loadGuidebook();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions
        .removeListener(_onItemPositionsChanged);
    _flashTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onItemPositionsChanged() {
    if (_isLoading || _blocks.isEmpty) return;
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
    topItem ??= positions.reduce((a, b) => a.index < b.index ? a : b);

    GuidebookDialog._savedScrollIndex = topItem.index;
    GuidebookDialog._savedScrollAlignment = topItem.itemLeadingEdge;
    GuidebookDialog._savedIsJp = _isJp;
    GuidebookDialog._savedBlockCount = _blocks.length;
  }

  Widget _buildHoldPeekDetector({
    required Widget child,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
  }) {
    return RawGestureDetector(
      behavior: behavior,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 800),
          ),
          (instance) {
            instance
              ..onLongPressStart = (_) {
                if (_isTapPeeking) return;
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  _isHoldPeeking = true;
                });
              }
              ..onLongPressEnd = (_) {
                if (_isHoldPeeking && mounted) {
                  setState(() {
                    _isHoldPeeking = false;
                  });
                }
              }
              ..onLongPressCancel = () {
                if (_isHoldPeeking && mounted) {
                  setState(() {
                    _isHoldPeeking = false;
                  });
                }
              };
          },
        ),
      },
      child: child,
    );
  }

  Future<void> _loadGuidebook({bool? isJp}) async {
    try {
      String content;
      bool targetIsJp;

      if (widget.initialContent != null && isJp == null) {
        content = widget.initialContent!;
        targetIsJp = widget.initialIsJp ?? true;
      } else {
        if (isJp != null) {
          targetIsJp = isJp;
        } else if (widget.initialIsJp != null) {
          targetIsJp = widget.initialIsJp!;
        } else {
          final prefs = await AppPrefs.getInstance();
          final lang = prefs.getString('selected_language') ?? 'ja';
          targetIsJp = (lang == 'ja');
        }

        final primaryPath = targetIsJp
            ? 'assets/nethackdir/jp/Guidebook_JP.md'
            : 'assets/nethackdir/en/Guidebook.md';

        try {
          content = await rootBundle.loadString(primaryPath);
        } catch (_) {
          if (targetIsJp) {
            content = await rootBundle
                .loadString('assets/nethackdir/jp/Guidebook_jp.md');
          } else {
            rethrow;
          }
        }
      }

      _parseMarkdown(content, targetIsJp);
    } catch (e) {
      if (mounted) {
        setState(() {
          _blocks = [
            _GuidebookBlock(
              kind: _BlockKind.paragraph,
              rawText: 'ガイドブックの読み込みに失敗しました: $e',
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  /// 画像パスの解決（すべて assets/images/guidebook/ 配下に一元解決）
  String _resolveImagePath(String rawPath) {
    var p = rawPath.trim();
    if (p.startsWith('asset:')) {
      p = p.substring(6).trim();
    }
    if (p.startsWith('./')) {
      p = p.substring(2).trim();
    }
    if (p.startsWith('images/')) {
      return 'assets/images/guidebook/${p.substring(7)}';
    }
    if (p.startsWith('assets/images/guidebook/')) {
      return p;
    }
    if (p.startsWith('assets/images/')) {
      return 'assets/images/guidebook/${p.substring(14)}';
    }
    if (p.startsWith('assets/')) {
      return p;
    }
    return 'assets/images/guidebook/$p';
  }

  /// CommonMark 準拠のテーブル行パース（インラインコードやエスケープ内のパイプ記号を保護）
  List<String> _parseTableRow(String r) {
    final trimmed = r.trim();
    if (trimmed.length < 2) return [];

    String inner = trimmed;
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
        int tickCount = 0;
        while (i + tickCount < inner.length && inner[i + tickCount] == '`') {
          tickCount++;
        }
        final delimiter = '`' * tickCount;
        current.write(delimiter);
        i += tickCount;

        final closeIdx = inner.indexOf(delimiter, i);
        if (closeIdx != -1) {
          current.write(inner.substring(i, closeIdx + tickCount));
          i = closeIdx + tickCount;
        }
        continue;
      }

      if (inner[i] == '|') {
        cells.add(current.toString().trim());
        current.clear();
        i++;
        continue;
      }

      current.write(inner[i]);
      i++;
    }
    cells.add(current.toString().trim());

    return cells;
  }

  void _parseMarkdown(String content, bool isJp) {
    final lines = content.split('\n');
    final blocks = <_GuidebookBlock>[];
    final sections = <_GuidebookSection>[];
    final anchorMap = <String, int>{};

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      final prevI = i;

      // 1. 水平線 (---, ***, ___)
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(_GuidebookBlock(
          kind: _BlockKind.divider,
          rawText: '',
        ));
        i++;
        continue;
      }

      // 2. <details><summary>アスキーアート等の折りたたみ
      if (trimmed.toLowerCase().startsWith('<details')) {
        final detailsLines = <String>[];
        String summary = '';
        i++;
        while (i < lines.length) {
          final curLine = lines[i];
          final curTrimmed = curLine.trim();
          if (curTrimmed.toLowerCase().startsWith('</details>')) {
            i++;
            break;
          }

          final summaryMatch = RegExp(r'<summary>(.*?)</summary>', caseSensitive: false).firstMatch(curLine);
          if (summaryMatch != null) {
            summary = summaryMatch.group(1)!.trim();
          } else {
            detailsLines.add(curLine);
          }
          i++;
        }

        // コードブロック ```text ... ``` の内側をクレンジング抽出
        var detailsContent = detailsLines.join('\n').trim();
        if (detailsContent.startsWith('```')) {
          final firstNl = detailsContent.indexOf('\n');
          final lastFence = detailsContent.lastIndexOf('```');
          if (firstNl != -1 && lastFence > firstNl) {
            detailsContent = detailsContent.substring(firstNl + 1, lastFence).trimRight();
          }
        }

        blocks.add(_GuidebookBlock(
          kind: _BlockKind.details,
          rawText: '$summary\n$detailsContent',
          detailsSummary: summary.isNotEmpty
              ? summary
              : (isJp ? 'テキスト版（アスキーアート）を表示' : 'Show text version (ASCII art)'),
          detailsContent: detailsContent,
        ));
        continue;
      }

      // 3. コードブロック (```)
      if (trimmed.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // 閉じ ``` をスキップ
        final codeText = codeLines.join('\n');
        blocks.add(_GuidebookBlock(
          kind: _BlockKind.code,
          rawText: codeText,
        ));
        continue;
      }

      // 4. 画像 ![caption](path)
      final imgMatch = RegExp(r'^!\[(.*?)\]\((?:asset:)?(.*?)\)$').firstMatch(trimmed);
      if (imgMatch != null) {
        final caption = imgMatch.group(1)!;
        final rawPath = imgMatch.group(2)!;
        final resolvedPath = _resolveImagePath(rawPath);

        blocks.add(_GuidebookBlock(
          kind: _BlockKind.image,
          rawText: caption,
          imageCaption: caption,
          imagePath: resolvedPath,
        ));
        i++;
        continue;
      }

      // 5. 見出し (# 〜 #####) または 行頭数字見出し (例: "1. はじめに")
      final headingMatch = RegExp(r'^(#{1,5})\s+(.+)$').firstMatch(trimmed);
      final numberedHeadingMatch = (headingMatch == null)
          ? RegExp(r'^(\d+(?:\.\d+)*\.)\s+(.+)$').firstMatch(trimmed)
          : null;

      if (headingMatch != null || numberedHeadingMatch != null) {
        final int level;
        String titleRaw;

        if (headingMatch != null) {
          level = headingMatch.group(1)!.length;
          titleRaw = headingMatch.group(2)!.trim();
        } else {
          // 数字見出し (例: "1. はじめに" -> level 2 相当)
          final numPrefix = numberedHeadingMatch!.group(1)!;
          level = numPrefix.split('.').where((s) => s.isNotEmpty).length > 1 ? 3 : 2;
          titleRaw = trimmed;
        }

        String anchorId = '';
        final anchorMatch =
            RegExp(r'\{#([a-zA-Z0-9_.-]+)[^}]*\}\s*$').firstMatch(titleRaw);
        if (anchorMatch != null) {
          anchorId = anchorMatch.group(1)!;
          titleRaw = titleRaw.substring(0, anchorMatch.start).trim();
        }

        final blockIndex = blocks.length;
        blocks.add(_GuidebookBlock(
          kind: _BlockKind.heading,
          rawText: titleRaw,
          headingLevel: level,
          anchorId: anchorId,
        ));

        if (anchorId.isNotEmpty) {
          anchorMap[anchorId] = blockIndex;
        }

        // 自動スラグも補完登録（未登録の場合）
        final autoSlug = _generateSlug(titleRaw);
        if (autoSlug.isNotEmpty) {
          if (!anchorMap.containsKey(autoSlug)) {
            anchorMap[autoSlug] = blockIndex;
          }
          if (autoSlug.startsWith('the-') && !anchorMap.containsKey(autoSlug.substring(4))) {
            anchorMap[autoSlug.substring(4)] = blockIndex;
          } else if (!autoSlug.startsWith('the-') && !anchorMap.containsKey('the-$autoSlug')) {
            anchorMap['the-$autoSlug'] = blockIndex;
          }
        }

        sections.add(_GuidebookSection(
          blockIndex: blockIndex,
          title: titleRaw,
          level: level,
          anchorId: anchorId,
        ));

        i++;
        continue;
      }

      // 6. テーブル (|...|)
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

          final hasSeparator =
              RegExp(r'^\|[\s:?-]+\|').hasMatch(tableLines[1]);
          final startIndex = hasSeparator ? 2 : 1;

          for (int r = startIndex; r < tableLines.length; r++) {
            rows.add(_parseTableRow(tableLines[r]));
          }

          final rawText = tableLines.join(' ');
          blocks.add(_GuidebookBlock(
            kind: _BlockKind.table,
            rawText: rawText,
            tableHeaders: headers,
            tableRows: rows,
          ));
          continue;
        } else if (tableLines.isNotEmpty) {
          // 単一行の |...| は通常の段落として処理
          blocks.add(_GuidebookBlock(
            kind: _BlockKind.paragraph,
            rawText: tableLines.join('\n'),
          ));
          continue;
        }
      }

      // 7. 通常の段落
      final paragraphLines = <String>[];
      while (i < lines.length) {
        final l = lines[i];
        final tr = l.trim();
        // 既に段落内に1行以上読まれており、かつ次行が別ブロックの開始行である場合は段落を終了
        if (paragraphLines.isNotEmpty) {
          if (tr.isEmpty ||
              RegExp(r'^(#{1,5})\s+').hasMatch(tr) ||
              tr.startsWith('```') ||
              tr == '---' ||
              tr == '***' ||
              tr == '___' ||
              tr.toLowerCase().startsWith('<details') ||
              (tr.startsWith('|') && tr.endsWith('|')) ||
              RegExp(r'^!\[(.*?)\]\((?:asset:)?(.*?)\)$').hasMatch(tr) ||
              RegExp(r'^\d+(?:\.\d+)*\.\s+').hasMatch(tr)) {
            break;
          }
        }
        paragraphLines.add(l);
        i++;
      }

      if (paragraphLines.isNotEmpty) {
        final paragraphText = paragraphLines.join('\n');
        final blockIndex = blocks.length;

        // インラインアンカーの抽出 [text]{#anchor}
        for (final match in RegExp(r'\{#([a-zA-Z0-9_.-]+)\}')
            .allMatches(paragraphText)) {
          final aId = match.group(1)!;
          if (!anchorMap.containsKey(aId)) {
            anchorMap[aId] = blockIndex;
          }
        }

        blocks.add(_GuidebookBlock(
          kind: _BlockKind.paragraph,
          rawText: paragraphText,
        ));
      }

      // フェイルセーフ：万が一 i が全く進まなかった場合のループ進行保証
      if (i == prevI) {
        blocks.add(_GuidebookBlock(
          kind: _BlockKind.paragraph,
          rawText: lines[i],
        ));
        i++;
      }
    }

    if (mounted) {
      setState(() {
        _isJp = isJp;
        _blocks = blocks;
        _sections = sections;
        _anchorMap.addAll(anchorMap);
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

  void _jumpToBlock(int blockIndex) {
    _flashTimer?.cancel();
    setState(() {
      _highlightedBlockIndex = blockIndex;
    });

    _scrollToBlock(blockIndex);

    _flashTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _highlightedBlockIndex = null;
        });
      }
    });
  }

  /// GFM / Pandoc 準拠のスラグ生成（見出しからアンカーIDを自動解決）
  String _generateSlug(String text) {
    // 括弧内の英語表記があれば優先抽出: 例 "ノームの鉱山 (The Gnomish Mines)" -> "The Gnomish Mines"
    final enMatch = RegExp(r'\(([A-Za-z0-9\s`_-]+)\)').firstMatch(text);
    var t = (enMatch != null && RegExp(r'[A-Za-z]').hasMatch(enMatch.group(1)!))
        ? enMatch.group(1)!
        : text;

    t = t.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    t = t.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    t = t.replaceAll(RegExp(r'[*_~]'), '');
    t = t.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '').trim().toLowerCase();
    t = t.replaceAll(RegExp(r'[\s_]+'), '-');
    t = t.replaceAll(RegExp(r'-+'), '-');
    return t;
  }

  void _jumpToAnchor(String anchor) {
    final cleanAnchor = anchor.startsWith('#') ? anchor.substring(1) : anchor;
    final blockIdx = _anchorMap[cleanAnchor];
    if (blockIdx != null) {
      _jumpToBlock(blockIdx);
    } else {
      // 見出しのテキスト正規化・部分一致検索でフォールバック
      final normalizedAnchor = cleanAnchor.replaceAll('-', ' ').toLowerCase().trim();
      final slugFromAnchor = _generateSlug(cleanAnchor);

      for (int i = 0; i < _sections.length; i++) {
        final s = _sections[i];
        final sectionSlug = _generateSlug(s.title);
        final normalizedTitle = s.title.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ').toLowerCase().trim();

        if (s.anchorId == cleanAnchor ||
            (sectionSlug.isNotEmpty && sectionSlug == slugFromAnchor) ||
            normalizedTitle == normalizedAnchor ||
            normalizedTitle.contains(normalizedAnchor) ||
            normalizedAnchor.contains(normalizedTitle)) {
          _jumpToBlock(s.blockIndex);
          return;
        }
      }
    }
  }

  int _getCurrentSectionIndex() {
    if (_sections.isEmpty) return -1;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return 0;

    int minBlockIndex = 999999;
    for (final pos in positions) {
      if (pos.itemTrailingEdge > 0 && pos.index < minBlockIndex) {
        minBlockIndex = pos.index;
      }
    }
    if (minBlockIndex == 999999) minBlockIndex = positions.first.index;

    int activeIdx = 0;
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].blockIndex <= minBlockIndex) {
        activeIdx = i;
      } else {
        break;
      }
    }
    return activeIdx;
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchMatchIndex = -1;
      });
      return;
    }

    final lower = query.toLowerCase();
    final results = <int>[];
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].rawText.toLowerCase().contains(lower)) {
        results.add(i);
      }
    }

    setState(() {
      _searchResults = results;
      _currentSearchMatchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _scrollToBlock(results[0]);
    }
  }

  void _searchNext() {
    if (_searchResults.isEmpty) return;
    final nextIndex = (_currentSearchMatchIndex + 1) % _searchResults.length;
    setState(() {
      _currentSearchMatchIndex = nextIndex;
    });
    _scrollToBlock(_searchResults[nextIndex]);
  }

  void _searchPrev() {
    if (_searchResults.isEmpty) return;
    final prevIndex = (_currentSearchMatchIndex - 1 + _searchResults.length) %
        _searchResults.length;
    setState(() {
      _currentSearchMatchIndex = prevIndex;
    });
    _scrollToBlock(_searchResults[prevIndex]);
  }

  void _showImageZoomDialog(String imagePath, String caption) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2430),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caption.isNotEmpty
                            ? caption
                            : (_isJp ? '画像プレビュー' : 'Image Preview'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: _isJp ? '閉じる' : 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _GuidebookImageWidget(
                      imagePath: imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _isJp ? 'ピンチ操作でズーム・ドラッグで移動できます' : 'Pinch to zoom, drag to move',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTOCModal() {
    final activeIndex = _getCurrentSectionIndex();
    final l10n = AppLocalizations.of(context);
    final tocScrollController = ScrollController();
    String filterText = '';
    bool chaptersOnly = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2430),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenHeight = MediaQuery.of(context).size.height;

            final filteredSections = _sections.where((sec) {
              if (chaptersOnly && sec.level > 2) return false;
              if (filterText.isNotEmpty &&
                  !sec.title.toLowerCase().contains(filterText.toLowerCase())) {
                return false;
              }
              return true;
            }).toList();

            return Container(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ヘッダー部
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book,
                                color: Colors.amberAccent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              l10n?.tocTitle(_sections.length) ??
                                  '目次 (${_sections.length}件)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // フィルターバー
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF12161F),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list,
                                    size: 18, color: Colors.white54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: l10n?.tocFilterHint ??
                                          '目次を絞り込み...',
                                      hintStyle: const TextStyle(
                                          color: Colors.white38, fontSize: 13),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      setModalState(() {
                                        filterText = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            chaptersOnly
                                ? (l10n?.tocFilterChaptersOnly ?? '章のみ')
                                : (l10n?.tocFilterAll ?? 'すべて'),
                            style: TextStyle(
                              color: chaptersOnly
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: chaptersOnly
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: chaptersOnly,
                          selectedColor: Colors.amberAccent,
                          backgroundColor: const Color(0xFF12161F),
                          onSelected: (val) {
                            setModalState(() {
                              chaptersOnly = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24, height: 1),

                  // セクション一覧リスト
                  Expanded(
                    child: ListView.builder(
                      controller: tocScrollController,
                      itemCount: filteredSections.length,
                      itemBuilder: (context, index) {
                        final sec = filteredSections[index];
                        final isActive = _sections.isNotEmpty &&
                            activeIndex >= 0 &&
                            activeIndex < _sections.length &&
                            _sections[activeIndex].blockIndex == sec.blockIndex;
                        final level = sec.level;

                        double paddingLeft = 16.0;
                        double fontSize = 14.0;
                        FontWeight fontWeight = FontWeight.normal;
                        IconData iconData = Icons.short_text;

                        if (level == 1) {
                          paddingLeft = 16.0;
                          fontSize = 15.0;
                          fontWeight = FontWeight.bold;
                          iconData = Icons.menu_book;
                        } else if (level == 2) {
                          paddingLeft = 16.0;
                          fontSize = 14.5;
                          fontWeight = FontWeight.bold;
                          iconData = Icons.article;
                        } else if (level == 3) {
                          paddingLeft = 28.0;
                          fontSize = 13.5;
                          fontWeight = FontWeight.w600;
                          iconData = Icons.subdirectory_arrow_right;
                        } else {
                          paddingLeft = 42.0;
                          fontSize = 12.5;
                          fontWeight = FontWeight.normal;
                          iconData = Icons.circle;
                        }

                        return Material(
                          color: isActive
                              ? Colors.amberAccent.withValues(alpha: 0.18)
                              : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.only(
                                left: paddingLeft, right: 16.0),
                            leading: Icon(
                              iconData,
                              size: level >= 4 ? 8 : 16,
                              color: isActive
                                  ? Colors.amberAccent
                                  : (level <= 2
                                      ? Colors.white70
                                      : Colors.white38),
                            ),
                            title: Text(
                              sec.title,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.amberAccent
                                    : (level <= 2
                                        ? Colors.white
                                        : Colors.white70),
                                fontSize: fontSize,
                                fontWeight:
                                    isActive ? FontWeight.bold : fontWeight,
                              ),
                            ),
                            trailing: isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n?.tocCurrentLocation ?? '現在地',
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _jumpToBlock(sec.blockIndex);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  WidgetSpan _buildCodeSpan(String codeText, double fontSize) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF242C3D),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12, width: 0.8),
        ),
        child: Text(
          codeText,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize * 0.92,
            color: Colors.cyanAccent.shade100,
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String text,
      {double fontSize = 13.5,
      Color? defaultColor,
      FontWeight? fontWeight}) {
    final spans = <InlineSpan>[];
    final color = defaultColor ?? Colors.white.withValues(alpha: 0.88);

    // テーブルセル内等の <br> / <br/> を改行 (\n) に変換
    String processed = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // 未知または残存する不要な HTML タグ (<small>, </small>, <div> 等) を防御的にサニタイズ除去
    processed = processed.replaceAll(RegExp(r'</?(?:small|div|span|button|p)\b[^>]*>', caseSensitive: false), '');

    // [text]{#id} を検出して text のみを表示
    processed = processed.replaceAllMapped(
        RegExp(r'\[(.*?)\]\{#[a-zA-Z0-9_.-]+\}'), (m) => m.group(1)!);

    // Markdown のインラインパーサー (コードスパン ``...`` / `...`, 太字 **...**, リンク [...](...))
    // ガイドブック中では単一の '*' はアイテム選択記号やワイルドカードなど本文中の記号として多用されるため、
    // 斜体（イタリック）修飾としては扱わず、通常の文字としてそのまま描画する。
    final tokenRegex =
        RegExp(r'(``.+?``|`[^`\r\n]+`|\*\*.*?\*\*|\[.*?\]\(.*?\))');
    int lastEnd = 0;

    for (final match in tokenRegex.allMatches(processed)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: processed.substring(lastEnd, match.start),
          style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: 1.45),
        ));
      }

      final token = match.group(0)!;
      if (token.startsWith('``') &&
          token.endsWith('``') &&
          token.length >= 4) {
        var inner = token.substring(2, token.length - 2);
        if (inner.startsWith(' ') && inner.endsWith(' ') && inner.length >= 2) {
          inner = inner.substring(1, inner.length - 1);
        }
        spans.add(_buildCodeSpan(inner, fontSize));
      } else if (token.startsWith('`') &&
          token.endsWith('`') &&
          token.length >= 2) {
        final inner = token.substring(1, token.length - 1);
        spans.add(_buildCodeSpan(inner, fontSize));
      } else if (token.startsWith('**') && token.endsWith('**') && token.length >= 4) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: TextStyle(
              color: Colors.amber.shade200,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.45),
        ));
      } else if (token.startsWith('[') &&
          token.contains('](') &&
          token.endsWith(')')) {
        final linkTextMatch =
            RegExp(r'^\[(.*?)\]\((.*?)\)$').firstMatch(token);
        if (linkTextMatch != null) {
          final lText = linkTextMatch.group(1)!;
          final lHref = linkTextMatch.group(2)!;

          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () {
                if (_isPeeking) return;
                if (lHref.startsWith('#')) {
                  _jumpToAnchor(lHref);
                } else if (lHref.contains('spoiler') ||
                    lHref.contains('companion')) {
                  SpoilerDialog.show(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  lText,
                  style: TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: fontSize,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < processed.length) {
      spans.add(TextSpan(
        text: processed.substring(lastEnd),
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.45),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTableWidget(_GuidebookBlock block) {
    final headers = block.tableHeaders;
    final rows = block.tableRows;
    final columnCount = headers.length;

    // DataTable アサーション例外 (!rows.any((row) => row.cells.length != columns.length)) を恒久防御
    final safeRows = rows.map((r) {
      final paddedCells = List<String>.from(r);
      if (paddedCells.length < columnCount) {
        paddedCells.addAll(List.filled(columnCount - paddedCells.length, ''));
      } else if (paddedCells.length > columnCount) {
        paddedCells.removeRange(columnCount, paddedCells.length);
      }
      return paddedCells;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFF242C3D)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            return Colors.transparent;
          }),
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: headers.map((h) {
            return DataColumn(
              label: Text(
                h,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          rows: safeRows.map((r) {
            return DataRow(
              cells: r.map((c) {
                return DataCell(_buildRichText(c, fontSize: 12.5));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailsWidget(_GuidebookBlock block) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white24, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: Colors.amberAccent,
            collapsedIconColor: Colors.white60,
            title: Text(
              block.detailsSummary,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12, width: 0.8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    block.detailsContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFFC9D1D9),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlockItem(BuildContext context, int index) {
    final block = _blocks[index];
    final isHighlighted = index == _highlightedBlockIndex;
    final isSearchMatch = _searchResults.contains(index);
    final isCurrentSearchMatch = _currentSearchMatchIndex >= 0 &&
        _currentSearchMatchIndex < _searchResults.length &&
        _searchResults[_currentSearchMatchIndex] == index;

    Widget content;

    switch (block.kind) {
      case _BlockKind.divider:
        content = const Divider(color: Colors.white24, height: 24, thickness: 1);
        break;

      case _BlockKind.heading:
        final lvl = block.headingLevel;
        double fSize = 16.0;
        Color hColor = Colors.white;
        FontWeight fWeight = FontWeight.bold;
        EdgeInsets margin = const EdgeInsets.only(top: 20, bottom: 8);

        if (lvl == 1) {
          fSize = 22.0;
          hColor = Colors.amberAccent;
          margin = const EdgeInsets.only(top: 24, bottom: 12);
        } else if (lvl == 2) {
          fSize = 18.0;
          hColor = Colors.cyanAccent.shade200;
          margin = const EdgeInsets.only(top: 18, bottom: 8);
        } else if (lvl == 3) {
          fSize = 15.5;
          hColor = Colors.lightBlueAccent.shade100;
          margin = const EdgeInsets.only(top: 14, bottom: 6);
        } else {
          fSize = 14.0;
          hColor = Colors.white70;
          margin = const EdgeInsets.only(top: 10, bottom: 4);
        }

        content = Container(
          margin: margin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.rawText,
                style: TextStyle(
                  color: hColor,
                  fontSize: fSize,
                  fontWeight: fWeight,
                  letterSpacing: 0.4,
                ),
              ),
              if (lvl <= 2) ...[
                const SizedBox(height: 4),
                Container(
                  height: lvl == 1 ? 2.5 : 1.5,
                  color: hColor.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        );
        break;

      case _BlockKind.code:
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12, width: 0.8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              block.rawText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: Color(0xFFC9D1D9),
                height: 1.4,
              ),
            ),
          ),
        );
        break;

      case _BlockKind.table:
        content = _buildTableWidget(block);
        break;

      case _BlockKind.details:
        content = _buildDetailsWidget(block);
        break;

      case _BlockKind.image:
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (_isPeeking) return;
                  _showImageZoomDialog(block.imagePath, block.imageCaption);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.5),
                        width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _GuidebookImageWidget(
                        imagePath: block.imagePath,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.amberAccent, size: 20),
                      ),
                    ],
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

      case _BlockKind.paragraph:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildRichText(block.rawText),
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.amberAccent.withValues(alpha: 0.25)
            : (isCurrentSearchMatch
                ? Colors.cyanAccent.withValues(alpha: 0.25)
                : (isSearchMatch
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final l10n = AppLocalizations.of(context);

    final dialogWidth = (screenWidth * 0.94).clamp(320.0, 960.0);
    final dialogHeight = (screenHeight * 0.92).clamp(420.0, 1100.0);

    final canRestoreScroll = GuidebookDialog._savedIsJp == _isJp &&
        GuidebookDialog._savedBlockCount == _blocks.length &&
        _blocks.isNotEmpty;
    final initialIndex = canRestoreScroll
        ? GuidebookDialog._savedScrollIndex.clamp(0, _blocks.length - 1)
        : 0;
    final initialAlign =
        canRestoreScroll ? GuidebookDialog._savedScrollAlignment : 0.0;

    return Stack(
      children: [
        // 背景暗幕（バリア）：透過中は透明になり、タップ透過維持中は画面のどこをタップしても復帰する
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isTapPeeking) {
                setState(() {
                  _isTapPeeking = false;
                });
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
        // ダイアログ本体
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
                      color: Colors.amberAccent.withValues(alpha: 0.4),
                      width: 1.5),
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
                    // ヘッダーバー
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
                                  const Icon(Icons.menu_book,
                                      color: Colors.amberAccent, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n?.guidebookTitle ??
                                          'NetHack ガイドブック',
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
                          _buildHoldPeekDetector(
                            child: IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                color: Colors.amberAccent,
                                size: 22,
                              ),
                              onPressed: () {
                                if (_isHoldPeeking) return;
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  _isTapPeeking = true;
                                });
                              },
                              tooltip: _isJp
                                  ? '一時透過 (長押しでも可)'
                                  : 'Peek (Hold to peek)',
                            ),
                          ),
                          // 目次ボタン
                          if (_sections.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.toc,
                                  color: Colors.amberAccent, size: 24),
                              onPressed: _showTOCModal,
                              tooltip: _isJp
                                  ? '目次を開く'
                                  : 'Open Table of Contents',
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white70, size: 22),
                            onPressed: () => Navigator.pop(context),
                            tooltip: l10n?.close ?? 'Close',
                          ),
                        ],
                      ),
                    ),

                    // 検索バー
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: const Color(0xFF161B24),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              size: 18, color: Colors.white54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: _isJp
                                    ? 'ガイドブック内を検索...'
                                    : 'Search guidebook...',
                                hintStyle: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_searchResults.isNotEmpty) ...[
                            Text(
                              '${_currentSearchMatchIndex + 1}/${_searchResults.length}',
                              style: const TextStyle(
                                  color: Colors.amberAccent, fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_upward,
                                  size: 18, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _searchPrev,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward,
                                  size: 18, color: Colors.white70),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _searchNext,
                            ),
                          ],
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 18, color: Colors.white54),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 1),

                    // ガイドブック本文ブロックリスト
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amberAccent),
                            )
                          : _blocks.isEmpty
                              ? const Center(
                                  child: Text('コンテンツがありません',
                                      style: TextStyle(color: Colors.white54)),
                                )
                              : _buildHoldPeekDetector(
                                  behavior: HitTestBehavior.translucent,
                                  child: ScrollablePositionedList.builder(
                                    itemScrollController:
                                        _itemScrollController,
                                    itemPositionsListener:
                                        _itemPositionsListener,
                                    initialScrollIndex: initialIndex,
                                    initialAlignment: initialAlign,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    itemCount: _blocks.length,
                                    itemBuilder: (context, index) =>
                                        _buildBlockItem(context, index),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // タップ透過モード中の復帰ガイドバー（画面上部に表示）
        if (_isTapPeeking)
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isTapPeeking = false;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amberAccent, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility,
                          color: Colors.amberAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isJp ? 'タップして戻る' : 'Tap to return',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ガイドブック用画像ウィジェット（AssetBundle から直接読込、失敗時は代替画像を表示）
class _GuidebookImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const _GuidebookImageWidget({
    required this.imagePath,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: const EdgeInsets.all(24),
          color: const Color(0xFF161B22),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, color: Colors.white38, size: 36),
              const SizedBox(height: 6),
              Text(
                '画像を読み込めませんでした: $imagePath',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

