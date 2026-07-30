// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-07-30.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// 日本語ガイドブック（Guidebook_JP.txt）を閲覧するためのダイアログウィジェット
class GuidebookDialog extends StatefulWidget {
  const GuidebookDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const GuidebookDialog(),
    );
  }

  @override
  State<GuidebookDialog> createState() => _GuidebookDialogState();
}

class _GuidebookSection {
  final int lineIndex;
  final String title;

  _GuidebookSection({required this.lineIndex, required this.title});
}

class _GuidebookDialogState extends State<GuidebookDialog> {
  bool _isLoading = true;
  List<String> _lines = [];
  List<_GuidebookSection> _sections = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  List<int> _searchResults = [];
  int _currentSearchMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadGuidebook();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuidebook() async {
    try {
      final content =
          await rootBundle.loadString('assets/nethackdir/Guidebook_JP.txt');
      final lines = content.split('\n');
      final sections = <_GuidebookSection>[];

      // 目次セクション抽出の正規表現（例: "1. はじめに", "5.4. 店と買い物", "5.4.1. 店の特異な点"）
      final sectionRegex = RegExp(r'^\s*(\d+(?:\.\d+)*\.)\s+(.+)$');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final match = sectionRegex.firstMatch(line);
        if (match != null) {
          final number = match.group(1)!;
          final title = match.group(2)!.trim();
          sections.add(
            _GuidebookSection(
              lineIndex: i,
              title: '$number $title',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _lines = lines;
          _sections = sections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lines = ['ガイドブックの読み込みに失敗しました: $e'];
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToLine(int lineIndex) {
    if (_lines.isEmpty || !_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: lineIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
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
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].toLowerCase().contains(queryLower)) {
        results.add(i);
      }
    }

    setState(() {
      _searchResults = results;
      _currentSearchMatchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _scrollToLine(results[0]);
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

    _scrollToLine(_searchResults[nextIndex]);
  }

  void _showTOCModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2430),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '目次',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final sec = _sections[index];
                    final isSubSection =
                        sec.title.contains(RegExp(r'^\d+\.\d+'));
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.only(
                        left: isSubSection ? 32.0 : 16.0,
                        right: 16.0,
                      ),
                      title: Text(
                        sec.title,
                        style: TextStyle(
                          color: isSubSection ? Colors.white70 : Colors.white,
                          fontSize: isSubSection ? 13 : 14,
                          fontWeight: isSubSection
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToLine(sec.lineIndex);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.92;
    final dialogHeight = screenSize.height * 0.90;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF12161F),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.amberAccent.withOpacity(0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
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
                  const Icon(Icons.menu_book,
                      color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'NetHack ガイドブック',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_sections.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted,
                          color: Colors.amberAccent, size: 22),
                      onPressed: _showTOCModal,
                      tooltip: '目次',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white70, size: 22),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '閉じる',
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
                        hintText: 'ガイドブック内を検索...',
                        hintStyle:
                            const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white54, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white54, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
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
                      style: const TextStyle(
                          color: Colors.amberAccent, fontSize: 11),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up,
                          color: Colors.white70, size: 20),
                      onPressed: () => _navigateSearchMatch(-1),
                      tooltip: '前の一致',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white70, size: 20),
                      onPressed: () => _navigateSearchMatch(1),
                      tooltip: '次の一致',
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                      ),
                    )
                  : ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.all(16),
                      itemCount: _lines.length,
                      itemBuilder: (context, index) {
                        final line = _lines[index];
                        final isCurrentSearchMatch =
                            _searchResults.isNotEmpty &&
                                _currentSearchMatchIndex >= 0 &&
                                _searchResults[_currentSearchMatchIndex] ==
                                    index;
                        final isOtherSearchMatch =
                            _searchResults.contains(index);

                        // 見出し行かの判定（目次に含まれているか）
                        final isHeader =
                            _sections.any((s) => s.lineIndex == index);

                        Color textColor = Colors.white70;
                        FontWeight fontWeight = FontWeight.normal;
                        double fontSize = 13.0;

                        if (isHeader) {
                          textColor = Colors.amberAccent;
                          fontWeight = FontWeight.bold;
                          fontSize = 15.0;
                        }

                        BoxDecoration? decoration;
                        if (isCurrentSearchMatch) {
                          decoration = BoxDecoration(
                            color: Colors.amberAccent.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                          );
                        } else if (isOtherSearchMatch) {
                          decoration = BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          );
                        }

                        return Container(
                          decoration: decoration,
                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                          child: Text(
                            line.isEmpty ? ' ' : line,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: textColor,
                              fontWeight: fontWeight,
                              fontSize: fontSize,
                              height: 1.4,
                            ),
                          ),
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
