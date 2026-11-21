import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dumplog_document.dart';
import '../models/topten_entry.dart';
import '../services/font_manager.dart';
import '../utils/app_prefs.dart';
import 'keyboard_help_dialog.dart';
import 'tombstone_widget.dart';

/// dumplog をセクション別折りたたみカード・目次チップ付きで見やすく表示するダイアログ
class DumplogViewerDialog extends StatefulWidget {
  final TopTenEntry entry;
  final String? dumplogPath;
  final DumplogDocument? initialDocument;
  final bool? isJp;
  final bool? usePhysicalKeyboardNotation;

  const DumplogViewerDialog({
    super.key,
    required this.entry,
    this.dumplogPath,
    this.initialDocument,
    this.isJp,
    this.usePhysicalKeyboardNotation,
  });

  @override
  State<DumplogViewerDialog> createState() => _DumplogViewerDialogState();
}

class _DumplogViewerDialogState extends State<DumplogViewerDialog> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  final Map<int, ScrollController> _horizontalControllers = {};
  final Map<int, GlobalKey> _sectionKeys = {};

  DumplogDocument? _document;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, bool> _expandedMap = {};
  bool _isCloseButtonFocused = false;
  bool _usePhysicalKeyboardNotation = false;
  bool _copiedFeedback = false;
  Timer? _copiedResetTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    if (widget.usePhysicalKeyboardNotation != null) {
      _usePhysicalKeyboardNotation = widget.usePhysicalKeyboardNotation!;
    } else if (AppPrefs.instance != null) {
      _usePhysicalKeyboardNotation =
          AppPrefs.instance!.getBool('use_physical_keyboard_notation') ?? false;
    }

    if (widget.initialDocument != null) {
      _applyDocument(widget.initialDocument!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_document == null && _isLoading && _errorMessage == null) {
      _loadDocument();
    }
  }

  void _loadDocument() {
    final path = widget.dumplogPath ?? widget.entry.dumplogPath;
    if (path == null || path.isEmpty) {
      _isLoading = false;
      _errorMessage = 'not_found';
      return;
    }

    final jaMode =
        widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
    try {
      final doc = DumplogDocument.loadFromFileSync(path, isJp: jaMode);
      _applyDocument(doc);
    } catch (e, st) {
      debugPrint('DumplogViewerDialog: failed to load "$path": $e\n$st');
      _isLoading = false;
      _errorMessage = e.toString();
    }
  }

  void _applyDocument(DumplogDocument doc) {
    _document = doc;
    _isLoading = false;
    _errorMessage = null;
    _expandedMap.clear();
    _sectionKeys.clear();
    for (int i = 0; i < doc.sections.length; i++) {
      _expandedMap[i] = doc.sections[i].defaultExpanded;
      _sectionKeys[i] = GlobalKey();
    }
  }

  ScrollController _horizontalControllerFor(int index) {
    return _horizontalControllers.putIfAbsent(index, () => ScrollController());
  }

  @override
  void dispose() {
    _copiedResetTimer?.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    for (final c in _horizontalControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _areAllExpanded {
    final doc = _document;
    if (doc == null || doc.sections.isEmpty) return false;
    for (int i = 0; i < doc.sections.length; i++) {
      if (!(_expandedMap[i] ?? false)) return false;
    }
    return true;
  }

  void _toggleExpandAll() {
    final doc = _document;
    if (doc == null || doc.sections.isEmpty) return;
    final nextState = !_areAllExpanded;
    setState(() {
      for (int i = 0; i < doc.sections.length; i++) {
        _expandedMap[i] = nextState;
      }
    });
  }

  Future<void> _copyAllText(bool jaMode) async {
    final doc = _document;
    if (doc == null || doc.rawText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: doc.rawText));
    if (!mounted) return;
    setState(() => _copiedFeedback = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          jaMode ? 'ダンプログをクリップボードにコピーしました' : 'Dumplog copied to clipboard',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    _copiedResetTimer?.cancel();
    _copiedResetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedFeedback = false);
      }
    });
  }

  void _jumpToSection(int index) {
    setState(() {
      _expandedMap[index] = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _sectionKeys[index]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 180),
          alignment: 0.05,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _pageScroll(int direction) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final step = viewport > 0 ? viewport * 0.85 : 280.0;
    _scrollBy(direction * step);
  }

  void _jumpToEdge(bool toTop) {
    if (!_scrollController.hasClients) return;
    final target = toTop ? 0.0 : _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  bool get _canScrollFurtherDown {
    if (!_scrollController.hasClients) return false;
    final maxExtent = _scrollController.position.maxScrollExtent;
    return maxExtent > 10.0 && _scrollController.offset < maxExtent - 5.0;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // 操作ヘルプ: F1 / Alt+h
    if (key == LogicalKeyboardKey.f1 ||
        (key == LogicalKeyboardKey.keyH &&
            HardwareKeyboard.instance.isAltPressed)) {
      if (isDown) {
        final jaMode =
            widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
        KeyboardHelpDialog.show(
          context,
          helpContext: KeyboardHelpContext.scoreDetail,
          isJapanese: jaMode,
        );
      }
      return KeyEventResult.handled;
    }

    // 閉じる: Escape / q / Enter / NumpadEnter
    if (key == LogicalKeyboardKey.escape ||
        (key == LogicalKeyboardKey.keyQ && !isCtrl) ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Tab: 閉じるボタンのフォーカス切替
    if (key == LogicalKeyboardKey.tab) {
      if (isDown) {
        setState(() {
          _isCloseButtonFocused = !_isCloseButtonFocused;
        });
      }
      return KeyEventResult.handled;
    }

    // Space / Shift+Space: ページスクロール（最下部到達時は閉じる）
    if (key == LogicalKeyboardKey.space) {
      if (isShift) {
        _pageScroll(-1);
      } else if (_canScrollFurtherDown) {
        _pageScroll(1);
      } else if (isDown) {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    }

    // 行スクロール: ↑ / k
    if (key == LogicalKeyboardKey.arrowUp ||
        (key == LogicalKeyboardKey.keyK && !isCtrl)) {
      _scrollBy(-48.0);
      return KeyEventResult.handled;
    }

    // 行スクロール: ↓ / j
    if (key == LogicalKeyboardKey.arrowDown ||
        (key == LogicalKeyboardKey.keyJ && !isCtrl)) {
      _scrollBy(48.0);
      return KeyEventResult.handled;
    }

    // ページ下スクロール: PageDown / > / .
    if (key == LogicalKeyboardKey.pageDown ||
        event.character == '>' ||
        key == LogicalKeyboardKey.period) {
      _pageScroll(1);
      return KeyEventResult.handled;
    }

    // ページ上スクロール: PageUp / < / ,
    if (key == LogicalKeyboardKey.pageUp ||
        event.character == '<' ||
        key == LogicalKeyboardKey.comma) {
      _pageScroll(-1);
      return KeyEventResult.handled;
    }

    // 先頭 / 末尾ジャンプ: Home / ^ , End / |
    if (key == LogicalKeyboardKey.home ||
        event.character == '^' ||
        key == LogicalKeyboardKey.caret) {
      if (isDown) _jumpToEdge(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end || event.character == '|') {
      if (isDown) _jumpToEdge(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  IconData _iconForSection(DumplogSectionType type) {
    switch (type) {
      case DumplogSectionType.header:
        return Icons.badge_outlined;
      case DumplogSectionType.map:
        return Icons.map_outlined;
      case DumplogSectionType.messages:
        return Icons.chat_bubble_outline;
      case DumplogSectionType.inventory:
        return Icons.backpack_outlined;
      case DumplogSectionType.attributes:
        return Icons.person_outline;
      case DumplogSectionType.gamelog:
        return Icons.timeline_outlined;
      case DumplogSectionType.spells:
        return Icons.auto_fix_high_outlined;
      case DumplogSectionType.skills:
        return Icons.fitness_center_outlined;
      case DumplogSectionType.conduct:
        return Icons.verified_outlined;
      case DumplogSectionType.overview:
        return Icons.layers_outlined;
      case DumplogSectionType.vanquished:
        return Icons.shield_outlined;
      case DumplogSectionType.genocided:
        return Icons.block_outlined;
      case DumplogSectionType.tombstone:
        return Icons.sentiment_very_dissatisfied_outlined;
      case DumplogSectionType.summary:
        return Icons.flag_outlined;
      case DumplogSectionType.other:
        return Icons.description_outlined;
    }
  }

  Color _accentForSection(DumplogSectionType type) {
    switch (type) {
      case DumplogSectionType.header:
      case DumplogSectionType.summary:
        return Colors.amber[200]!;
      case DumplogSectionType.map:
      case DumplogSectionType.overview:
        return Colors.lightBlue[200]!;
      case DumplogSectionType.inventory:
        return Colors.greenAccent[200]!;
      case DumplogSectionType.attributes:
      case DumplogSectionType.conduct:
        return Colors.purple[200]!;
      case DumplogSectionType.tombstone:
      case DumplogSectionType.vanquished:
      case DumplogSectionType.genocided:
        return Colors.orange[200]!;
      default:
        return Colors.teal[200]!;
    }
  }

  Widget _buildSectionCard(int index, DumplogSection section, bool jaMode) {
    final isExpanded = _expandedMap[index] ?? section.defaultExpanded;
    final accent = _accentForSection(section.type);
    final lineCount = section.nonEmptyLineCount;

    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2029),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: Radius.circular(isExpanded ? 0 : 8),
            ),
            child: InkWell(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(8),
                bottom: Radius.circular(isExpanded ? 0 : 8),
              ),
              onTap: () {
                setState(() {
                  _expandedMap[index] = !isExpanded;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(_iconForSection(section.type), size: 17, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        jaMode ? '$lineCount行' : '$lineCount lines',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: section.type == DumplogSectionType.tombstone
                  ? _buildTombstoneBlock(index, section.lines)
                  : section.isMonospaceScrollable
                      ? _buildMonospaceBlock(index, section.lines)
                      : _buildTextBlock(section.lines),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTombstoneBlock(int index, List<String> lines) {
    return TombstoneAsciiView(
      lines: lines,
      fontSize: 11.5,
      horizontalController: _horizontalControllerFor(index),
      dedent: false,
    );
  }

  Widget _buildMonospaceBlock(int index, List<String> lines) {
    final hCtrl = _horizontalControllerFor(index);
    final text = lines.join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Scrollbar(
          controller: hCtrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: hCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              text,
              softWrap: false,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.25,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBlock(List<String> lines) {
    return Text(
      lines.join('\n'),
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.4,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jaMode =
        widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
    final screenSize = MediaQuery.sizeOf(context);
    final maxDialogWidth =
        math.min(680.0, math.max(280.0, screenSize.width - 20));
    final maxDialogHeight =
        math.min(760.0, math.max(260.0, screenSize.height * 0.90));
    final doc = _document;
    final allExpanded = _areAllExpanded;

    return Dialog(
      backgroundColor: const Color(0xFF12161D),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 固定ヘッダー
                Row(
                  children: [
                    Icon(Icons.article_outlined,
                        size: 22, color: Colors.lightBlue[200]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jaMode ? '冒険ダンプ' : 'Adventure Dumplog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.lightBlue[200],
                            ),
                          ),
                          Text(
                            '${widget.entry.nameAndProfile} (${jaMode ? '${widget.entry.score} 点' : '${widget.entry.score} pts'})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (doc != null && doc.sections.isNotEmpty) ...[
                      Tooltip(
                        message: allExpanded
                            ? (jaMode ? 'すべて折りたたむ' : 'Collapse All')
                            : (jaMode ? 'すべて展開' : 'Expand All'),
                        child: IconButton(
                          icon: Icon(
                            allExpanded
                                ? Icons.unfold_less
                                : Icons.unfold_more,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: _toggleExpandAll,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Tooltip(
                        message: jaMode ? '全文コピー' : 'Copy All',
                        child: IconButton(
                          icon: Icon(
                            _copiedFeedback ? Icons.check : Icons.copy_outlined,
                            color: _copiedFeedback
                                ? Colors.greenAccent[200]
                                : Colors.white70,
                            size: 19,
                          ),
                          onPressed: () => _copyAllText(jaMode),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),

                // 目次チップバー
                if (doc != null && doc.sections.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: doc.sections.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final sec = doc.sections[index];
                        final accent = _accentForSection(sec.type);
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0),
                          backgroundColor: const Color(0xFF1E2633),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.35),
                          ),
                          avatar: Icon(
                            _iconForSection(sec.type),
                            size: 14,
                            color: accent,
                          ),
                          label: Text(
                            sec.title,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => _jumpToSection(index),
                        );
                      },
                    ),
                  ),
                ],

                const Divider(color: Colors.white12, height: 14),

                // 本体
                Expanded(
                  child: FontManager.wrapMenuContent(
                    context,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (_errorMessage != null ||
                                doc == null ||
                                doc.sections.isEmpty)
                            ? Center(
                                child: Text(
                                  jaMode
                                      ? 'ダンプログを読み込めませんでした。'
                                      : 'Could not load dumplog.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (int i = 0;
                                          i < doc.sections.length;
                                          i++)
                                        _buildSectionCard(
                                          i,
                                          doc.sections[i],
                                          jaMode,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),

                const SizedBox(height: 10),
                // 固定フッター
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCloseButtonFocused
                          ? Colors.amber[700]
                          : Colors.teal[600],
                      foregroundColor:
                          _isCloseButtonFocused ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: _isCloseButtonFocused
                            ? const BorderSide(
                                color: Colors.amberAccent, width: 2)
                            : BorderSide.none,
                      ),
                      elevation: _isCloseButtonFocused ? 6 : 2,
                    ),
                    child: Text(
                      _usePhysicalKeyboardNotation
                          ? (jaMode ? 'Esc:閉じる' : 'Esc: Close')
                          : (jaMode ? '閉じる' : 'Close'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
