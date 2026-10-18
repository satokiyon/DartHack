// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-15.
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/text_formatter.dart';

/// ガイドブック（日本語 Guidebook_JP.txt / 英語 Guidebook.txt）を閲覧するためのダイアログウィジェット
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
  static int _savedLineCount = 0;

  @visibleForTesting
  static void resetSavedScrollPosition() {
    _savedScrollIndex = 0;
    _savedScrollAlignment = 0.0;
    _savedIsJp = null;
    _savedLineCount = 0;
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

class _GuidebookSection {
  final int lineIndex;
  final String title;
  final String number;
  final int level;

  _GuidebookSection({
    required this.lineIndex,
    required this.title,
    required this.number,
    required this.level,
  });
}

class _GuidebookDialogState extends State<GuidebookDialog> {
  bool _isLoading = true;
  bool _isJp = true;
  List<String> _lines = [];
  List<_GuidebookSection> _sections = [];
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();

  List<int> _searchResults = [];
  int _currentSearchMatchIndex = -1;

  int? _highlightedLineIndex;
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
    if (_isLoading || _lines.isEmpty) return;
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
    GuidebookDialog._savedLineCount = _lines.length;
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
            duration: const Duration(milliseconds: 350),
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

  Future<void> _loadGuidebook() async {
    try {
      String content;
      bool isJp;
      if (widget.initialContent != null) {
        content = widget.initialContent!;
        isJp = widget.initialIsJp ?? true;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('selected_language') ?? 'ja';
        isJp = widget.initialIsJp ?? (lang == 'ja');

        final primaryPath = isJp
            ? 'assets/nethackdir/jp/Guidebook_JP.txt'
            : 'assets/nethackdir/en/Guidebook.txt';

        try {
          content = await rootBundle.loadString(primaryPath);
        } catch (_) {
          if (isJp) {
            content = await rootBundle
                .loadString('assets/nethackdir/jp/Guidebook_jp.txt');
          } else {
            rethrow;
          }
        }
      }

      final rawLines = content.split('\n');
      final lines = TextFormatter.reformatLines(rawLines);
      final sections = <_GuidebookSection>[];

      // 数字見出しの抽出正規表現 (例: "1. はじめに", "1. Introduction", "5.4. 店と買い物", "5.4. Shops")
      final sectionRegex = RegExp(r'^(\d+(?:\.\d+)*\.)[ \t\u3000]+(.+)$');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        // 行頭の全角・半角スペース、タブを除去した文字列で見出し判定
        final trimmedLeading = line.replaceAll(RegExp(r'^[ \t\u3000]+'), '');
        final match = sectionRegex.firstMatch(trimmedLeading);
        if (match != null) {
          final number = match.group(1)!;
          final title = match.group(2)!.trim();
          final numClean = number.endsWith('.')
              ? number.substring(0, number.length - 1)
              : number;
          final level = numClean.split('.').length;

          sections.add(
            _GuidebookSection(
              lineIndex: i,
              title: '$number $title',
              number: number,
              level: level,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isJp = isJp;
          _lines = lines;
          _sections = sections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lines = [
            _isJp
                ? 'ガイドブックの読み込みに失敗しました: $e'
                : 'Failed to load Guidebook: $e'
          ];
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

  void _jumpToSection(int lineIndex) {
    _flashTimer?.cancel();
    setState(() {
      _highlightedLineIndex = lineIndex;
    });

    _scrollToLine(lineIndex);

    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _highlightedLineIndex = null;
        });
      }
    });
  }

  int _getCurrentSectionIndex() {
    if (_sections.isEmpty) return -1;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return 0;

    int topVisibleLine = positions
        .map((p) => p.index)
        .reduce((a, b) => a < b ? a : b);

    int activeIndex = 0;
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].lineIndex <= topVisibleLine) {
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
    final activeIndex = _getCurrentSectionIndex();
    final tocScrollController = ScrollController();

    // モーダル表示後にアクティブセクションまで自動スクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeIndex > 0 && tocScrollController.hasClients) {
        final targetOffset = (activeIndex * 44.0).clamp(
          0.0,
          tocScrollController.position.maxScrollExtent,
        );
        tocScrollController.jumpTo(targetOffset);
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2430),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.toc, color: Colors.amberAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          _isJp
                              ? '目次 (${_sections.length}項目)'
                              : 'Table of Contents (${_sections.length} items)',
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
              const SizedBox(height: 8),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: tocScrollController,
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final sec = _sections[index];
                    final isActive = index == activeIndex;
                    final level = sec.level;

                    double paddingLeft = 16.0;
                    double fontSize = 14.0;
                    FontWeight fontWeight = FontWeight.normal;
                    IconData iconData = Icons.short_text;

                    if (level == 1) {
                      paddingLeft = 16.0;
                      fontSize = 14.5;
                      fontWeight = FontWeight.bold;
                      iconData = Icons.article;
                    } else if (level == 2) {
                      paddingLeft = 32.0;
                      fontSize = 13.5;
                      fontWeight = FontWeight.w600;
                      iconData = Icons.subdirectory_arrow_right;
                    } else {
                      paddingLeft = 48.0;
                      fontSize = 13.0;
                      fontWeight = FontWeight.normal;
                      iconData = Icons.short_text;
                    }

                    return Material(
                      color: isActive
                          ? Colors.amberAccent.withValues(alpha: 0.18)
                          : Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.only(
                          left: paddingLeft,
                          right: 16.0,
                        ),
                        leading: Icon(
                          iconData,
                          size: 16,
                          color: isActive
                              ? Colors.amberAccent
                              : (level == 1 ? Colors.white70 : Colors.white38),
                        ),
                        title: Text(
                          sec.title,
                          style: TextStyle(
                            color: isActive
                                ? Colors.amberAccent
                                : (level == 1 ? Colors.white : Colors.white70),
                            fontSize: fontSize,
                            fontWeight: isActive ? FontWeight.bold : fontWeight,
                          ),
                        ),
                        trailing: isActive
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _isJp ? '現在地' : 'Current',
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
                          _jumpToSection(sec.lineIndex);
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
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.92;
    final dialogHeight = screenSize.height * 0.90;

    final canRestoreScroll = GuidebookDialog._savedIsJp == _isJp &&
        GuidebookDialog._savedLineCount == _lines.length &&
        _lines.isNotEmpty;
    final initialIndex = canRestoreScroll
        ? GuidebookDialog._savedScrollIndex.clamp(0, _lines.length - 1)
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                      _isJp
                                          ? 'NetHack ガイドブック'
                                          : 'NetHack Guidebook',
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
                                  ? 'ゲーム画面を確認（タップで維持 / 長押しで一時透過）'
                                  : 'Peek at game screen (Tap to hold / Long-press to peek)',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_sections.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.toc,
                                  color: Colors.amberAccent, size: 24),
                              onPressed: _showTOCModal,
                              tooltip: _isJp
                                  ? '目次を開く'
                                  : 'Open Table of Contents',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white70, size: 22),
                            onPressed: () => Navigator.pop(context),
                            tooltip: _isJp ? '閉じる' : 'Close',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // 検索バー
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      color: const Color(0xFF181E29),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: _isJp
                                    ? 'ガイドブック内を検索...'
                                    : 'Search Guidebook...',
                                hintStyle: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
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
                              tooltip: _isJp ? '前の一致' : 'Previous match',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white70, size: 20),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amberAccent),
                              ),
                            )
                          : _buildHoldPeekDetector(
                              behavior: HitTestBehavior.translucent,
                              child: ScrollablePositionedList.builder(
                                itemScrollController: _itemScrollController,
                                itemPositionsListener: _itemPositionsListener,
                                initialScrollIndex: initialIndex,
                                initialAlignment: initialAlign,
                                padding: const EdgeInsets.all(16),
                                itemCount: _lines.length,
                                itemBuilder: (context, index) {
                                    final line = _lines[index];
                                    final isCurrentSearchMatch =
                                        _searchResults.isNotEmpty &&
                                            _currentSearchMatchIndex >= 0 &&
                                            _searchResults[
                                                    _currentSearchMatchIndex] ==
                                                index;
                                    final isOtherSearchMatch =
                                        _searchResults.contains(index);
                                    final isFlashMatch =
                                        _highlightedLineIndex == index;

                                    // 見出し行かの判定（目次に含まれているか）
                                    final isHeader = _sections
                                        .any((s) => s.lineIndex == index);

                                    Color textColor = Colors.white70;
                                    FontWeight fontWeight = FontWeight.normal;
                                    double fontSize = 13.0;

                                    if (isHeader) {
                                      textColor = Colors.amberAccent;
                                      fontWeight = FontWeight.bold;
                                      fontSize = 15.0;
                                    }

                                    BoxDecoration? decoration;
                                    if (isFlashMatch) {
                                      decoration = BoxDecoration(
                                        color: Colors.amberAccent
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.amberAccent,
                                            width: 1.5),
                                      );
                                    } else if (isCurrentSearchMatch) {
                                      decoration = BoxDecoration(
                                        color: Colors.amberAccent
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(4),
                                      );
                                    } else if (isOtherSearchMatch) {
                                      decoration = BoxDecoration(
                                        color: Colors.blueAccent
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(4),
                                      );
                                    }

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      decoration: decoration,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0),
                                      child: Text(
                                        line.isEmpty ? ' ' : line,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          color: isFlashMatch
                                              ? Colors.black
                                              : textColor,
                                          fontWeight: isFlashMatch
                                              ? FontWeight.bold
                                              : fontWeight,
                                          fontSize: fontSize,
                                          height: 1.4,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // タップ透過維持中のみ画面上部に表示する復帰案内バッジ
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
                      color: Colors.amberAccent.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.amberAccent,
                        size: 16,
                      ),
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
    );
  }
}
