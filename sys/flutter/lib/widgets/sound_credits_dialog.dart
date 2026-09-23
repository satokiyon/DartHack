import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/sound_credit_entry.dart';

/// BGM・効果音クレジットを閲覧するための大画面モーダルダイアログ
class SoundCreditsDialog extends StatefulWidget {
  final String? initialText;

  const SoundCreditsDialog({super.key, this.initialText});

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SoundCreditsDialog(),
    );
  }

  @override
  State<SoundCreditsDialog> createState() => _SoundCreditsDialogState();
}

class _SoundCreditsDialogState extends State<SoundCreditsDialog> {
  late final Future<Map<String, List<SoundCreditEntry>>> _creditsFuture;

  @override
  void initState() {
    super.initState();
    _creditsFuture = _loadSoundCredits();
  }

  Future<Map<String, List<SoundCreditEntry>>> _loadSoundCredits() async {
    if (widget.initialText != null) {
      return SoundCreditParser.parse(widget.initialText!);
    }
    try {
      final text = await rootBundle.loadString('assets/sounds/attributions.txt');
      return SoundCreditParser.parse(text);
    } catch (e) {
      debugPrint('Error loading sound attributions: $e');
      return {};
    }
  }

  void _copyToClipboard(BuildContext context, String url, String message) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          children: [
            // ヘッダー部
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.amberAccent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.soundCreditsDialogTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white24),

            // コンテンツ部
            Expanded(
              child: FutureBuilder<Map<String, List<SoundCreditEntry>>>(
                future: _creditsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amberAccent),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'クレジット情報を読み込めませんでした。',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    );
                  }

                  final grouped = snapshot.data!;
                  final totalCount = grouped.values.fold<int>(0, (sum, list) => sum + list.length);

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'DartHack で使用されているBGM、効果音、環境音の権利表記およびライセンス一覧です。（計 $totalCount 件）',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                      ...grouped.entries.map((group) {
                        return _buildSourceGroup(
                          context,
                          group.key,
                          group.value,
                          l10n,
                          theme,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Colors.white24),
            // フッター部
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.close,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceGroup(
    BuildContext context,
    String sourceName,
    List<SoundCreditEntry> entries,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      color: const Color(0xFF28283E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey<String>('sound_credit_group_$sourceName'),
        leading: const Icon(Icons.library_music_outlined, color: Colors.tealAccent, size: 22),
        title: Text(
          sourceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.soundCreditsItemsCount(entries.length.toString()),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
        children: [
          Container(
            color: const Color(0xFF202032),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Colors.white12),
                  _buildEntryItem(context, entries[i], l10n),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryItem(
    BuildContext context,
    SoundCreditEntry entry,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ファイル名 & 用途説明
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.audio_file, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.amberAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                entry.description,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],

          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry.author.isNotEmpty)
                  Text(
                    '作者: ${entry.author}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                  ),
                if (entry.license.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.4), width: 0.8),
                    ),
                    child: Text(
                      entry.license,
                      style: const TextStyle(fontSize: 11, color: Colors.tealAccent),
                    ),
                  ),
                if (entry.notes.isNotEmpty)
                  Text(
                    '(${entry.notes})',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55)),
                  ),
              ],
            ),
          ),

          if (entry.url.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: InkWell(
                onTap: () => _copyToClipboard(context, entry.url, l10n.soundCreditsCopiedUrl),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.lightBlueAccent),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          entry.url,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.lightBlueAccent,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 12, color: Colors.lightBlueAccent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
