import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topten_entry.dart';
import 'score_detail_dialog.dart';

class TopTenWidget extends StatefulWidget {
  final List<TopTenEntry> entries;
  final bool? isJp;
  final ScrollController? scrollController;
  final VoidCallback? onDetailClosed;
  final String? unrecordedMessage;

  const TopTenWidget({
    super.key,
    required this.entries,
    this.isJp,
    this.scrollController,
    this.onDetailClosed,
    this.unrecordedMessage,
  });

  @override
  State<TopTenWidget> createState() => _TopTenWidgetState();
}

class _TopTenWidgetState extends State<TopTenWidget> {
  static const int _maxSeekAttempts = 24;

  ScrollController? _internalScrollController;
  final GlobalKey _currentCardKey = GlobalKey();
  final Set<int> _mountedIndices = <int>{};
  int _targetCurrentIndex = -1;
  int _autoCenterGeneration = 0;

  ScrollController get _effectiveScrollController {
    if (widget.scrollController != null) {
      return widget.scrollController!;
    }
    return _internalScrollController ??= ScrollController();
  }

  @override
  void initState() {
    super.initState();
    _targetCurrentIndex = widget.entries.lastIndexWhere((e) => e.isCurrent);
    if (_targetCurrentIndex >= 0) {
      _scheduleAutoCenter(generation: _autoCenterGeneration);
    }
  }

  @override
  void didUpdateWidget(covariant TopTenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != null && _internalScrollController != null) {
      _internalScrollController!.dispose();
      _internalScrollController = null;
    }

    if (!_areEntriesEquivalent(oldWidget.entries, widget.entries) ||
        oldWidget.scrollController != widget.scrollController) {
      _targetCurrentIndex = widget.entries.lastIndexWhere((e) => e.isCurrent);
      _autoCenterGeneration++;
      if (_targetCurrentIndex >= 0) {
        _scheduleAutoCenter(generation: _autoCenterGeneration);
      }
    }
  }

  @override
  void dispose() {
    _autoCenterGeneration++;
    _internalScrollController?.dispose();
    super.dispose();
  }

  bool _areEntriesEquivalent(List<TopTenEntry> a, List<TopTenEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final ea = a[i];
      final eb = b[i];
      if (ea.rank != eb.rank ||
          ea.score != eb.score ||
          ea.nameAndProfile != eb.nameAndProfile ||
          ea.isCurrent != eb.isCurrent ||
          ea.xlog?.rawLine != eb.xlog?.rawLine) {
        return false;
      }
    }
    return true;
  }

  void _onItemVisibilityChanged(int index, bool isMounted) {
    if (isMounted) {
      _mountedIndices.add(index);
    } else {
      _mountedIndices.remove(index);
    }
  }

  /// 今回スコアのカード（ランクイン時は中央、末尾圏外時は最下部）を
  /// ポストフレーム収束でアニメーション無し（即時）に画面内へ配置する。
  void _scheduleAutoCenter({int attempt = 0, required int generation}) {
    if (!mounted || generation != _autoCenterGeneration) return;
    if (_targetCurrentIndex < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _autoCenterGeneration) return;
      final currentTarget = _targetCurrentIndex;
      if (currentTarget < 0) return;

      final targetCtx = _currentCardKey.currentContext;
      if (targetCtx != null) {
        Scrollable.ensureVisible(
          targetCtx,
          duration: Duration.zero,
          alignment: 0.5,
        );
        return;
      }

      if (attempt >= _maxSeekAttempts) return;
      final controller = _effectiveScrollController;
      if (!controller.hasClients || widget.entries.isEmpty) {
        _scheduleAutoCenter(attempt: attempt + 1, generation: generation);
        return;
      }

      final position = controller.position;
      final maxExtent = position.maxScrollExtent;
      if (maxExtent <= 0) return;

      final total = widget.entries.length;
      double nextOffset;
      if (attempt == 0) {
        if (currentTarget >= total - 1) {
          nextOffset = maxExtent;
        } else if (currentTarget == 0) {
          nextOffset = 0.0;
        } else {
          final ratio = currentTarget / (total - 1);
          nextOffset = (maxExtent * ratio).clamp(0.0, maxExtent);
        }
      } else {
        final viewport = position.viewportDimension;
        final step = viewport > 0 ? viewport * 0.75 : 240.0;
        int? minMounted;
        int? maxMounted;
        for (final idx in _mountedIndices) {
          if (minMounted == null || idx < minMounted) minMounted = idx;
          if (maxMounted == null || idx > maxMounted) maxMounted = idx;
        }
        if (maxMounted != null && currentTarget > maxMounted) {
          nextOffset = (controller.offset + step).clamp(0.0, maxExtent);
        } else if (minMounted != null && currentTarget < minMounted) {
          nextOffset = (controller.offset - step).clamp(0.0, maxExtent);
        } else {
          final ratio = total > 1 ? currentTarget / (total - 1) : 0.0;
          nextOffset = (maxExtent * ratio).clamp(0.0, maxExtent);
        }
        if ((nextOffset - controller.offset).abs() < 0.5) {
          if (currentTarget >= total - 1 &&
              (maxExtent - controller.offset).abs() >= 0.5) {
            nextOffset = maxExtent;
          } else if (currentTarget <= 0 && controller.offset >= 0.5) {
            nextOffset = 0.0;
          } else {
            return;
          }
        }
      }

      controller.jumpTo(nextOffset);
      _scheduleAutoCenter(attempt: attempt + 1, generation: generation);
    });
  }

  void _openDetailDialog(BuildContext context, TopTenEntry entry, bool jaMode) {
    showDialog<void>(
      context: context,
      builder: (context) => ScoreDetailDialog(entry: entry, isJp: jaMode),
    ).then((_) {
      widget.onDetailClosed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jaMode = widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
    final effectiveUnrecordedMessage = widget.unrecordedMessage ??
        (widget.entries.any((e) => e.isCurrent && e.rank <= 0)
            ? TopTenEntry.extractUnrecordedNotice(
                const [],
                widget.entries,
                isJp: jaMode,
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  jaMode ? "スコアボード" : "Scoreboard",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[200],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (effectiveUnrecordedMessage != null &&
            effectiveUnrecordedMessage.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2, bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber[300],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effectiveUnrecordedMessage,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.amber[100],
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            controller: _effectiveScrollController,
            itemCount: widget.entries.length,
            itemBuilder: (context, index) {
              final entry = widget.entries[index];
              final isCurrent = entry.isCurrent;
              final isScrollTarget = index == _targetCurrentIndex;

              return _MountedIndexTracker(
                index: index,
                onVisibilityChanged: _onItemVisibilityChanged,
                child: Card(
                  key: isScrollTarget ? _currentCardKey : null,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  color: isCurrent ? const Color(0xFF2C2214) : const Color(0xFF1E222B),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isCurrent ? const Color(0xFFFFB300) : Colors.white12,
                      width: isCurrent ? 2.0 : 1.0,
                    ),
                  ),
                  elevation: isCurrent ? 6 : 2,
                  child: InkWell(
                    onTap: () => _openDetailDialog(context, entry, jaMode),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 順位表示（圏外ランク 0 以下はハイフン "-" を表示）
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  entry.rank > 0 ? "${entry.rank}" : "-",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // スコアとプレイヤー名
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            jaMode ? "${entry.score} 点" : "${entry.score} pts",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrent
                                                  ? const Color(0xFFFFD54F)
                                                  : Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFB300),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              jaMode ? "今回の記録" : "Current Game",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (entry.xlog != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.amber.withValues(alpha: 0.45),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              jaMode ? "詳細" : "Details",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.amber[200],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: entry.xlog != null
                                              ? Colors.amber[200]
                                              : Colors.white38,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.nameAndProfile,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isCurrent ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (entry.details.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            ...entry.details.map((detail) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    detail,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isCurrent ? Colors.white.withValues(alpha: 0.87) : Colors.grey[400],
                                      height: 1.3,
                                    ),
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ListView.builder 内で現在ビルド済みの項目インデックス範囲を追跡する補助ウィジェット
class _MountedIndexTracker extends StatefulWidget {
  final int index;
  final void Function(int index, bool isMounted) onVisibilityChanged;
  final Widget child;

  const _MountedIndexTracker({
    required this.index,
    required this.onVisibilityChanged,
    required this.child,
  });

  @override
  State<_MountedIndexTracker> createState() => _MountedIndexTrackerState();
}

class _MountedIndexTrackerState extends State<_MountedIndexTracker> {
  @override
  void initState() {
    super.initState();
    widget.onVisibilityChanged(widget.index, true);
  }

  @override
  void didUpdateWidget(covariant _MountedIndexTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      oldWidget.onVisibilityChanged(oldWidget.index, false);
      widget.onVisibilityChanged(widget.index, true);
    }
  }

  @override
  void dispose() {
    widget.onVisibilityChanged(widget.index, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// ドロワーやメニューから開く、物理キーボード操作・Tab循環フォーカス対応のスコアボードダイアログ
class ScoreboardDialog extends StatefulWidget {
  final List<TopTenEntry> entries;
  final bool? isJp;

  const ScoreboardDialog({
    super.key,
    required this.entries,
    this.isJp,
  });

  @override
  State<ScoreboardDialog> createState() => _ScoreboardDialogState();
}

class _ScoreboardDialogState extends State<ScoreboardDialog> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  bool _isCloseButtonFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    final step = viewport > 0 ? viewport * 0.85 : 320.0;
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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // 閉じる: Escape / q
    if (key == LogicalKeyboardKey.escape || (key == LogicalKeyboardKey.keyQ && !isCtrl)) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // 決定: Enter / numpadEnter
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Tab / Shift+Tab: フォーカス循環 (none ↔ closeButton)
    if (key == LogicalKeyboardKey.tab) {
      if (isDown) {
        setState(() {
          _isCloseButtonFocused = !_isCloseButtonFocused;
        });
      }
      return KeyEventResult.handled;
    }

    // 行スクロール: ↑ / k (上へ)
    if (key == LogicalKeyboardKey.arrowUp || (key == LogicalKeyboardKey.keyK && !isCtrl)) {
      _scrollBy(-48.0);
      return KeyEventResult.handled;
    }

    // 行スクロール: ↓ / j (下へ)
    if (key == LogicalKeyboardKey.arrowDown || (key == LogicalKeyboardKey.keyJ && !isCtrl)) {
      _scrollBy(48.0);
      return KeyEventResult.handled;
    }

    // ページ下スクロール: PageDown / >
    if (key == LogicalKeyboardKey.pageDown || event.character == '>' || (!isShift && key == LogicalKeyboardKey.period)) {
      _pageScroll(1);
      return KeyEventResult.handled;
    }

    // ページ上スクロール: PageUp / <
    if (key == LogicalKeyboardKey.pageUp || event.character == '<' || (!isShift && key == LogicalKeyboardKey.comma)) {
      _pageScroll(-1);
      return KeyEventResult.handled;
    }

    // 先頭へジャンプ: Home / ^
    if (key == LogicalKeyboardKey.home || event.character == '^' || key == LogicalKeyboardKey.caret) {
      if (isDown) _jumpToEdge(true);
      return KeyEventResult.handled;
    }

    // 末尾へジャンプ: End / |
    if (key == LogicalKeyboardKey.end || event.character == '|') {
      if (isDown) _jumpToEdge(false);
      return KeyEventResult.handled;
    }

    // Space / Shift+Space: ページスクロールまたは最下部での閉じる
    if (key == LogicalKeyboardKey.space) {
      if (isDown) {
        if (isShift) {
          _pageScroll(-1);
        } else {
          if (_scrollController.hasClients &&
              _scrollController.offset >= _scrollController.position.maxScrollExtent - 10) {
            Navigator.of(context).pop();
          } else {
            _pageScroll(1);
          }
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final jaMode = widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');

    return Dialog(
      backgroundColor: const Color(0xFF12161D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: widget.entries.isNotEmpty
                    ? TopTenWidget(
                        entries: widget.entries,
                        isJp: jaMode,
                        scrollController: _scrollController,
                        onDetailClosed: () {
                          if (mounted) _focusNode.requestFocus();
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              jaMode ? 'スコア記録がありません' : 'No score records found',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              jaMode ? 'ゲームをプレイしてハイスコアを目指しましょう！' : 'Play games to set high scores!',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCloseButtonFocused ? Colors.amber[700] : Colors.teal[600],
                    foregroundColor: _isCloseButtonFocused ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: _isCloseButtonFocused
                          ? const BorderSide(color: Colors.amberAccent, width: 2)
                          : BorderSide.none,
                    ),
                    elevation: _isCloseButtonFocused ? 6 : 2,
                  ),
                  child: Text(
                    jaMode ? '閉じる' : 'Close',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
