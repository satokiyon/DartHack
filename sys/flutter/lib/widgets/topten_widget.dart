import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topten_entry.dart';

class TopTenWidget extends StatelessWidget {
  final List<TopTenEntry> entries;
  final bool? isJp;
  final ScrollController? scrollController;

  const TopTenWidget({
    super.key,
    required this.entries,
    this.isJp,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final jaMode = isJp ?? (Localizations.localeOf(context).languageCode == 'ja');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                jaMode ? "スコアボード" : "Scoreboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[200],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 16),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrent = entry.isCurrent;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                color: isCurrent ? const Color(0xFF2C2214) : const Color(0xFF1E222B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isCurrent ? const Color(0xFFFFB300) : Colors.white12,
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                ),
                elevation: isCurrent ? 6 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 順位表示
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
                                  "${entry.rank}",
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
                                    Text(
                                      jaMode ? "${entry.score} 点" : "${entry.score} pts",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent
                                            ? const Color(0xFFFFD54F)
                                            : Colors.grey[300],
                                      ),
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
                      if (isCurrent)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                        ),
                    ],
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
