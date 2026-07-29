import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'exit_ad_banner.dart';

class ExitHighlightDialog extends StatefulWidget {
  final String dialogMessage;
  final List<String> messageHistory;

  const ExitHighlightDialog({
    super.key,
    required this.dialogMessage,
    required this.messageHistory,
  });

  @override
  State<ExitHighlightDialog> createState() => _ExitHighlightDialogState();
}

class _ExitHighlightDialogState extends State<ExitHighlightDialog>
    with SingleTickerProviderStateMixin {
  bool _isHighlightReady = false;
  Timer? _timeoutTimer;
  Timer? _animTimer;
  int _animFrame = 0;
  late final List<String> _selectedHighlights;

  static const List<String> _animChars = ['.', '..', '...', '....'];

  @override
  void initState() {
    super.initState();
    _selectedHighlights = _selectHighlights(widget.messageHistory);

    // アニメーション更新用タイマー (300ms間隔)
    _animTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted && !_isHighlightReady) {
        setState(() {
          _animFrame = (_animFrame + 1) % _animChars.length;
        });
      }
    });

    // じっくり広告を待つため、5秒のタイムアウトを設定
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      _completeLoading();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animTimer?.cancel();
    super.dispose();
  }

  void _completeLoading() {
    if (!_isHighlightReady) {
      _timeoutTimer?.cancel();
      _animTimer?.cancel();
      if (mounted) {
        setState(() {
          _isHighlightReady = true;
        });
      }
    }
  }

  static List<String> _selectHighlights(List<String> rawHistory) {
    // 1. 空白除去および重複排除
    final Set<String> uniqueMessages = {};
    for (final msg in rawHistory) {
      final trimmed = msg.trim();
      if (trimmed.isNotEmpty) {
        uniqueMessages.add(trimmed);
      }
    }

    final filteredList = uniqueMessages.toList();

    if (filteredList.isEmpty) {
      return ['なし'];
    }

    final random = Random();
    final List<String> picked = [];

    if (filteredList.length <= 3) {
      picked.addAll(filteredList);
    } else {
      final temp = List<String>.from(filteredList);
      temp.shuffle(random);
      picked.addAll(temp.take(3));
    }

    // 各メッセージの先頭にランキング数字(1. 〜 3. )を付加
    final List<String> result = [];
    for (int i = 0; i < picked.length; i++) {
      result.add('${i + 1}. ${picked[i]}');
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dots = _animChars[_animFrame];

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '終了',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dialogMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),

              // 「今回のハイライト」セクション
              const Text(
                '【今回のハイライト】',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              if (!_isHighlightReady) ...[
                // NetHackらしいアニメーション表示領域
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      // NetHackのプレイヤー記号 `@` の点滅表現
                      Text(
                        '[@]',
                        style: TextStyle(
                          color: _animFrame % 2 == 0 ? Colors.cyanAccent : Colors.lightBlue,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ダンジョンの記憶を辿っています$dots',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ハイライト表示領域
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedHighlights.map((text) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: text == 'なし' ? Colors.grey : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // 広告バナー領域
              ExitAdBanner(
                onAdLoaded: _completeLoading,
                onAdFailedToLoad: _completeLoading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
