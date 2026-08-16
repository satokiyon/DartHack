import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  late List<String> _selectedHighlights;

  static const List<String> _animChars = ['.', '..', '...', '....'];

  @override
  void initState() {
    super.initState();
    _selectedHighlights = [];

    _animTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted && !_isHighlightReady) {
        setState(() {
          _animFrame = (_animFrame + 1) % _animChars.length;
        });
      }
    });

    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      _completeLoading();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedHighlights.isEmpty) {
      final noneText = AppLocalizations.of(context)?.none ?? 'なし';
      _selectedHighlights = _selectHighlights(widget.messageHistory, noneText);
    }
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

  static List<String> _selectHighlights(List<String> rawHistory, String noneText) {
    final Set<String> uniqueMessages = {};
    for (final msg in rawHistory) {
      final trimmed = msg.trim();
      if (trimmed.isNotEmpty) {
        uniqueMessages.add(trimmed);
      }
    }

    final filteredList = uniqueMessages.toList();

    if (filteredList.isEmpty) {
      return [noneText];
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

    final List<String> result = [];
    for (int i = 0; i < picked.length; i++) {
      result.add('${i + 1}. ${picked[i]}');
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          l10n.quit,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

              Text(
                l10n.runHighlights,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              if (!_isHighlightReady) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
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
                          l10n.recallingMemories,
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
                      final isNone = text == l10n.none || text == 'なし';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isNone ? Colors.grey : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
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
