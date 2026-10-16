import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'guidebook_dialog.dart';

/// NetHack 5.0 スポイラー（攻略情報）閲覧ダイアログ
class SpoilerDialog extends StatefulWidget {
  final String? initialMarkdown;
  final bool? initialIsJp;

  const SpoilerDialog({
    super.key,
    this.initialMarkdown,
    this.initialIsJp,
  });

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SpoilerDialog(),
    );
  }

  @override
  State<SpoilerDialog> createState() => _SpoilerDialogState();
}

enum _BlockKind {
  heading,
  paragraph,
  table,
  code,
  image,
  divider,
}

class _SpoilerSection {
  final int blockIndex;
  final String title;
  final int level;
  final String anchorId;

  _SpoilerSection({
    required this.blockIndex,
    required this.title,
    required this.level,
    required this.anchorId,
  });
}

class _SpoilerBlock {
  final _BlockKind kind;
  final String rawText;
  final int headingLevel;
  final String anchorId;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String imagePath;
  final String imageCaption;

  _SpoilerBlock({
    required this.kind,
    required this.rawText,
    this.headingLevel = 0,
    this.anchorId = '',
    this.tableHeaders = const [],
    this.tableRows = const [],
    this.imagePath = '',
    this.imageCaption = '',
  });
}

class _SpoilerDialogState extends State<SpoilerDialog> {
  bool _isLoading = true;
  bool _isJp = true;
  List<_SpoilerBlock> _blocks = [];
  List<_SpoilerSection> _sections = [];
  final Map<String, int> _anchorMap = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  List<int> _searchResults = [];
  int _currentSearchMatchIndex = -1;
  int? _highlightedBlockIndex;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _loadSpoilers();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpoilers() async {
    try {
      if (widget.initialMarkdown != null) {
        final isJp = widget.initialIsJp ?? true;
        _parseMarkdown(widget.initialMarkdown!, isJp);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language') ?? 'ja';
      final isJp = widget.initialIsJp ?? (lang == 'ja');

      final primaryPath = isJp
          ? 'assets/nethackdir/jp/companion.jp.md'
          : 'assets/nethackdir/en/companion.md';

      String content;
      try {
        content = await rootBundle.loadString(primaryPath);
      } catch (_) {
        if (isJp) {
          content = await rootBundle.loadString('assets/nethackdir/jp/companion.ja.md');
        } else {
          rethrow;
        }
      }

      _parseMarkdown(content, isJp);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _blocks = [
            _SpoilerBlock(
              kind: _BlockKind.paragraph,
              rawText: l10n?.failedToLoadSpoilers(e.toString()) ?? 'Failed to load spoilers: $e',
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _parseMarkdown(String content, bool isJp) {
    final lines = content.split('\n');
    final blocks = <_SpoilerBlock>[];
    final sections = <_SpoilerSection>[];
    final anchorMap = <String, int>{};

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // 1. 水平線 (---)
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(_SpoilerBlock(
          kind: _BlockKind.divider,
          rawText: '',
        ));
        i++;
        continue;
      }

      // 2. コードブロック (```)
      if (trimmed.startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // 閉じ ``` をスキップ
        final codeText = codeLines.join('\n');
        blocks.add(_SpoilerBlock(
          kind: _BlockKind.code,
          rawText: codeText,
        ));
        continue;
      }

      // 3. 画像 ![caption](asset:path)
      final imgMatch = RegExp(r'^!\[(.*?)\]\(asset:(.*?)\)$').firstMatch(trimmed);
      if (imgMatch != null) {
        final caption = imgMatch.group(1)!;
        final path = imgMatch.group(2)!;
        blocks.add(_SpoilerBlock(
          kind: _BlockKind.image,
          rawText: caption,
          imageCaption: caption,
          imagePath: path,
        ));
        i++;
        continue;
      }

      // 4. 見出し (# 〜 #####)
      final headingMatch = RegExp(r'^(#{1,5})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        final hashes = headingMatch.group(1)!;
        final level = hashes.length;
        var titleRaw = headingMatch.group(2)!.trim();

        String anchorId = '';
        final anchorMatch = RegExp(r'\{#([a-zA-Z0-9_.-]+)[^}]*\}\s*$').firstMatch(titleRaw);
        if (anchorMatch != null) {
          anchorId = anchorMatch.group(1)!;
          titleRaw = titleRaw.substring(0, anchorMatch.start).trim();
        }

        final blockIndex = blocks.length;
        blocks.add(_SpoilerBlock(
          kind: _BlockKind.heading,
          rawText: titleRaw,
          headingLevel: level,
          anchorId: anchorId,
        ));

        if (anchorId.isNotEmpty) {
          anchorMap[anchorId] = blockIndex;
        }

        sections.add(_SpoilerSection(
          blockIndex: blockIndex,
          title: titleRaw,
          level: level,
          anchorId: anchorId,
        ));

        i++;
        continue;
      }

      // 5. テーブル (|...|)
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }

        if (tableLines.length >= 2) {
          List<String> parseRow(String r) {
            final inner = r.substring(1, r.length - 1);
            return inner.split('|').map((c) => c.trim()).toList();
          }

          final headers = parseRow(tableLines[0]);
          final rows = <List<String>>[];

          // 2行目がセパレータ (|---|---|...) か確認
          final hasSeparator = RegExp(r'^\|[\s:?-]+\|').hasMatch(tableLines[1]);
          final startIndex = hasSeparator ? 2 : 1;

          for (int r = startIndex; r < tableLines.length; r++) {
            rows.add(parseRow(tableLines[r]));
          }

          final rawText = tableLines.join(' ');
          blocks.add(_SpoilerBlock(
            kind: _BlockKind.table,
            rawText: rawText,
            tableHeaders: headers,
            tableRows: rows,
          ));
          continue;
        }
      }

      // 6. 通常の段落（インラインアンカー [text]{#id} を検出）
      final paragraphLines = <String>[];
      while (i < lines.length) {
        final l = lines[i];
        final tr = l.trim();
        if (tr.isEmpty || tr.startsWith('#') || tr.startsWith('```') || tr.startsWith('---') || (tr.startsWith('|') && tr.endsWith('|'))) {
          break;
        }
        paragraphLines.add(l);
        i++;
      }

      final paragraphText = paragraphLines.join('\n');
      final blockIndex = blocks.length;

      // インラインアンカーの抽出 [text]{#anchor}
      for (final match in RegExp(r'\{#([a-zA-Z0-9_.-]+)\}').allMatches(paragraphText)) {
        final aId = match.group(1)!;
        if (!anchorMap.containsKey(aId)) {
          anchorMap[aId] = blockIndex;
        }
      }

      blocks.add(_SpoilerBlock(
        kind: _BlockKind.paragraph,
        rawText: paragraphText,
      ));
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

  void _jumpToAnchor(String anchor) {
    final cleanAnchor = anchor.startsWith('#') ? anchor.substring(1) : anchor;
    final blockIdx = _anchorMap[cleanAnchor];
    if (blockIdx != null) {
      _jumpToBlock(blockIdx);
    } else {
      // 見出しのテキスト部分一致検索でフォールバック
      for (int i = 0; i < _sections.length; i++) {
        final s = _sections[i];
        if (s.anchorId == cleanAnchor || s.title.toLowerCase().contains(cleanAnchor.toLowerCase())) {
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

    int topVisibleBlock = positions
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);

    int activeIndex = 0;
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].blockIndex <= topVisibleBlock) {
        activeIndex = i;
      } else {
        break;
      }
    }
    return activeIndex;
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchMatchIndex = -1;
      });
      return;
    }

    final queryLower = query.toLowerCase();
    final results = <int>[];
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].rawText.toLowerCase().contains(queryLower)) {
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

  void _navigateSearchMatch(int delta) {
    if (_searchResults.isEmpty) return;
    int nextIndex = _currentSearchMatchIndex + delta;
    if (nextIndex < 0) {
      nextIndex = _searchResults.length - 1;
    } else if (nextIndex >= _searchResults.length) {
      nextIndex = 0;
    }

    setState(() {
      _currentSearchMatchIndex = nextIndex;
    });

    _scrollToBlock(_searchResults[nextIndex]);
  }

  void _showImageZoomDialog(String imagePath, String caption) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.amberAccent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        caption.isNotEmpty ? caption : (_isJp ? '図版の拡大表示' : 'Diagram View'),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
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
                    child: Image.asset(imagePath, fit: BoxFit.contain),
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
              if (chaptersOnly && sec.level > 3) return false;
              if (filterText.isNotEmpty && !sec.title.toLowerCase().contains(filterText.toLowerCase())) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories, color: Colors.amberAccent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              l10n?.tocTitle(_sections.length) ?? 'Table of Contents (${_sections.length})',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // 絞り込み検索バー & チップ
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n?.tocFilterHint ?? 'Filter Table of Contents...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF283144),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filterText = val.trim();
                        });
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(l10n?.tocFilterAll ?? 'All', style: const TextStyle(fontSize: 12)),
                          selected: !chaptersOnly,
                          selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                          onSelected: (val) {
                            setModalState(() {
                              chaptersOnly = false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(l10n?.tocFilterChaptersOnly ?? 'Chapters Only', style: const TextStyle(fontSize: 12)),
                          selected: chaptersOnly,
                          selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                          onSelected: (val) {
                            setModalState(() {
                              chaptersOnly = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24, height: 1),

                  // 目次リスト
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
                            contentPadding: EdgeInsets.only(left: paddingLeft, right: 16.0),
                            leading: Icon(
                              iconData,
                              size: level >= 4 ? 8 : 16,
                              color: isActive
                                  ? Colors.amberAccent
                                  : (level <= 2 ? Colors.white70 : Colors.white38),
                            ),
                            title: Text(
                              sec.title,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.amberAccent
                                    : (level <= 2 ? Colors.white : Colors.white70),
                                fontSize: fontSize,
                                fontWeight: isActive ? FontWeight.bold : fontWeight,
                              ),
                            ),
                            trailing: isActive
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      l10n?.tocCurrentLocation ?? 'Current',
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

  Widget _buildRichText(String text, {double fontSize = 13.5, Color? defaultColor, FontWeight? fontWeight}) {
    final spans = <InlineSpan>[];
    final color = defaultColor ?? Colors.white.withValues(alpha: 0.88);

    // [text]{#id} を検出して text のみを表示
    String processed = text.replaceAllMapped(RegExp(r'\[(.*?)\]\{#[a-zA-Z0-9_.-]+\}'), (m) => m.group(1)!);

    // Markdown の簡易インラインパーサー (太字 **...**, 等幅 `...`, リンク [...](...), 斜体 *...*)
    final tokenRegex = RegExp(r'(\*\*.*?\*\*|`.*?`|\[.*?\]\(.*?\)|(?<!\*)\*[^*]+?\*(?!\*))');
    int lastEnd = 0;

    for (final match in tokenRegex.allMatches(processed)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: processed.substring(lastEnd, match.start),
          style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, height: 1.45),
        ));
      }

      final token = match.group(0)!;
      if (token.startsWith('**') && token.endsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: TextStyle(color: Colors.amber.shade200, fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.45),
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(WidgetSpan(
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
              token.substring(1, token.length - 1),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: fontSize * 0.92,
                color: Colors.cyanAccent.shade100,
              ),
            ),
          ),
        ));
      } else if (token.startsWith('[') && token.contains('](') && token.endsWith(')')) {
        final linkTextMatch = RegExp(r'^\[(.*?)\]\((.*?)\)$').firstMatch(token);
        if (linkTextMatch != null) {
          final lText = linkTextMatch.group(1)!;
          final lHref = linkTextMatch.group(2)!;

          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () {
                if (lHref.startsWith('#')) {
                  _jumpToAnchor(lHref);
                } else if (lHref.contains('guidebook')) {
                  GuidebookDialog.show(context);
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
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: TextStyle(color: color, fontSize: fontSize, fontStyle: FontStyle.italic, height: 1.45),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < processed.length) {
      spans.add(TextSpan(
        text: processed.substring(lastEnd),
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, height: 1.45),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildTableWidget(_SpoilerBlock block) {
    final headers = block.tableHeaders;
    final rows = block.tableRows;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF242C3D)),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              return null; // デフォルトまたは行毎スタイル
            }),
            columnSpacing: 16,
            horizontalMargin: 12,
            headingTextStyle: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
            columns: headers.map((h) {
              return DataColumn(
                label: _buildRichText(h, fontSize: 12.5, defaultColor: Colors.amberAccent, fontWeight: FontWeight.bold),
              );
            }).toList(),
            rows: rows.asMap().entries.map((entry) {
              final rIdx = entry.key;
              final rowCells = entry.value;
              final isEven = rIdx % 2 == 0;

              return DataRow(
                color: WidgetStateProperty.all(
                  isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
                ),
                cells: List.generate(headers.length, (colIdx) {
                  final text = colIdx < rowCells.length ? rowCells[colIdx] : '';
                  return DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _buildRichText(text, fontSize: 12.0),
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

  Widget _buildBlockWidget(int index, _SpoilerBlock block) {
    final isCurrentSearchMatch = _searchResults.isNotEmpty &&
        _currentSearchMatchIndex >= 0 &&
        _searchResults[_currentSearchMatchIndex] == index;
    final isOtherSearchMatch = _searchResults.contains(index);
    final isFlashMatch = _highlightedBlockIndex == index;

    BoxDecoration? decoration;
    if (isFlashMatch) {
      decoration = BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
      );
    } else if (isCurrentSearchMatch) {
      decoration = BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      );
    } else if (isOtherSearchMatch) {
      decoration = BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      );
    }

    Widget content;
    switch (block.kind) {
      case _BlockKind.divider:
        content = const Divider(color: Colors.white24, height: 24, thickness: 1);
        break;

      case _BlockKind.heading:
        final lvl = block.headingLevel;
        double fSize = 14.0;
        Color hColor = Colors.white;
        EdgeInsets pad = const EdgeInsets.only(top: 16, bottom: 6);

        if (lvl == 1) {
          fSize = 20.0;
          hColor = Colors.amberAccent;
          pad = const EdgeInsets.only(top: 24, bottom: 10);
        } else if (lvl == 2) {
          fSize = 17.5;
          hColor = Colors.amberAccent;
          pad = const EdgeInsets.only(top: 20, bottom: 8);
        } else if (lvl == 3) {
          fSize = 15.5;
          hColor = Colors.cyanAccent;
          pad = const EdgeInsets.only(top: 16, bottom: 6);
        } else if (lvl == 4) {
          fSize = 14.0;
          hColor = Colors.white;
          pad = const EdgeInsets.only(top: 12, bottom: 4);
        } else {
          fSize = 13.0;
          hColor = Colors.white70;
          pad = const EdgeInsets.only(top: 8, bottom: 4);
        }

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
                  letterSpacing: 0.5,
                ),
              ),
              if (lvl <= 2) ...[
                const SizedBox(height: 4),
                Container(height: 1.5, color: Colors.amberAccent.withValues(alpha: 0.4)),
              ],
            ],
          ),
        );
        break;

      case _BlockKind.table:
        content = _buildTableWidget(block);
        break;

      case _BlockKind.code:
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F131C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12, width: 0.8),
          ),
          child: SingleChildScrollView(
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

      case _BlockKind.image:
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showImageZoomDialog(block.imagePath, block.imageCaption),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.asset(block.imagePath, fit: BoxFit.contain),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.amberAccent, size: 20),
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

      case _BlockKind.paragraph:
        content = Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: _buildRichText(block.rawText),
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF12161F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4), width: 1.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2430),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_stories, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.spoilersTitle ?? 'NetHack Spoilers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_sections.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.toc, color: Colors.amberAccent, size: 24),
                      onPressed: _showTOCModal,
                      tooltip: _isJp ? '目次を開く' : 'Open Table of Contents',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                    tooltip: l10n?.close ?? 'Close',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 検索バー
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF181E29),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: l10n?.searchSpoilersHint ?? 'Search Spoilers...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF242C3D),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${_currentSearchMatchIndex + 1}/${_searchResults.length}',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
                      onPressed: () => _navigateSearchMatch(-1),
                      tooltip: _isJp ? '前の一致' : 'Previous match',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
                      onPressed: () => _navigateSearchMatch(1),
                      tooltip: _isJp ? '次の一致' : 'Next match',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // 本文表示エリア
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      ),
                    )
                  : ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.all(16),
                      itemCount: _blocks.length,
                      itemBuilder: (context, index) {
                        return _buildBlockWidget(index, _blocks[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

