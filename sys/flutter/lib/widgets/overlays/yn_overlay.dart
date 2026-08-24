import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class YnOverlay extends StatelessWidget {
  final String question;
  final String choices;
  final int defaultChoice;
  final Function(int choiceCode) onSelect;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;

  const YnOverlay({
    super.key,
    required this.question,
    required this.choices,
    required this.defaultChoice,
    required this.onSelect,
    required this.onShowMsgHistory,
    required this.bottomInset,
  });

  String _parseEffectiveChoices() {
    final rawChoices = choices.contains('\x1b')
        ? choices.substring(0, choices.indexOf('\x1b'))
        : choices;
    if (rawChoices.isNotEmpty) {
      return rawChoices;
    }

    final lowerQ = question.toLowerCase();
    // [y|n], [y/n], (y/n), [y/n/q] などの y/n 問合せパターンの検知
    if (lowerQ.contains('[y|n]') ||
        lowerQ.contains('[y/n]') ||
        lowerQ.contains('(y/n)') ||
        lowerQ.contains('[y/n/q]') ||
        lowerQ.contains('[y|n|q]') ||
        lowerQ.contains('adjust?')) {
      if (lowerQ.contains('q')) {
        return 'ynq';
      }
      return 'yn';
    }

    // ブラケット [x|y] や [x/y] から選択キーを抽出する処理
    final match = RegExp(r'\[([a-zA-Z0-9/|]+)\]').firstMatch(question);
    if (match != null) {
      final inside = match.group(1)!;
      final extracted = inside.replaceAll(RegExp(r'[/|]'), '');
      if (extracted.isNotEmpty) {
        return extracted;
      }
    }

    // デフォルト値が 'y' や 'n' の場合のフォールバック
    if (defaultChoice == 'y'.codeUnitAt(0) || defaultChoice == 'n'.codeUnitAt(0)) {
      return 'yn';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveChoices = _parseEffectiveChoices();
    final choiceList = effectiveChoices.split('');
    final isYesNo = effectiveChoices.toLowerCase() == 'yn' || effectiveChoices.toLowerCase() == 'ynq';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded, color: Colors.amber[300], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.confirmTitle,
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                    const SizedBox(height: 14),
                    Text(
                      question,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (isYesNo)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => onSelect('y'.codeUnitAt(0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (defaultChoice == 'y'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Yes'),
                          ),
                          ElevatedButton(
                            onPressed: () => onSelect('n'.codeUnitAt(0)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (defaultChoice == 'n'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('No'),
                          ),
                          if (effectiveChoices.toLowerCase().contains('q'))
                            ElevatedButton(
                              onPressed: () => onSelect('q'.codeUnitAt(0)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (defaultChoice == 'q'.codeUnitAt(0)) ? Colors.teal[500] : Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Quit'),
                            ),
                          ElevatedButton.icon(
                            onPressed: onShowMsgHistory,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: Text(l10n.history),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[900],
                              foregroundColor: Colors.amber[200],
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          ...choiceList.map((ch) {
                            final isDefault = ch.codeUnitAt(0) == defaultChoice;
                            return ElevatedButton(
                              onPressed: () => onSelect(ch.codeUnitAt(0)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDefault ? Colors.teal[500] : Colors.blueGrey[800],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(ch),
                            );
                          }),
                          ElevatedButton(
                            onPressed: () => onSelect(27), // ESC
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white70),
                            child: Text(l10n.cancel),
                          ),
                          ElevatedButton.icon(
                            onPressed: onShowMsgHistory,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: Text(l10n.history),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[900],
                              foregroundColor: Colors.amber[200],
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
