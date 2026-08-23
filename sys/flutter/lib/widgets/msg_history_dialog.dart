import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

void showMsgHistoryPanel({
  required BuildContext context,
  required List<String> messages,
  required double msgFontSize,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF12161D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: Colors.amber[300]),
                      const SizedBox(width: 8),
                      Text(
                        l10n.msgHistoryTitle,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.entriesCount(messages.length),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noMsgHistory,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final dataIndex = messages.length - 1 - index;
                            final line = messages[dataIndex];
                            final ratio = (dataIndex + 1) / messages.length;
                            final color = Color.lerp(Colors.white38, Colors.white, ratio)!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: color,
                                  fontFamily: 'monospace',
                                  fontSize: msgFontSize,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheetContext).padding.bottom + 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(l10n.close),
                    ),
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

Widget buildMsgHistoryButton({
  required VoidCallback onPressed,
  String label = '履歴',
}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.history, size: 18, color: Colors.amber),
    label: Text(label, style: const TextStyle(color: Colors.amber)),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.amber,
      side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

bool isCallOrNamePrompt(String prompt) {
  if (prompt.isEmpty) return false;
  final p = prompt.toLowerCase();
  return prompt.contains('何と呼びますか')
      || prompt.contains('何と名付けますか')
      || prompt.contains('名前を付け')
      || p.contains('call ')
      || p.contains('name ')
      || p.contains('call this')
      || p.contains('name this')
      || p.contains('what do you want to call')
      || p.contains('what do you want to name');
}
