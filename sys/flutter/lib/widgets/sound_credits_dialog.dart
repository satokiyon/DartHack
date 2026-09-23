import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/sound_credit_entry.dart';

/// BGM・効果音クレジットを閲覧するためのモーダルダイアログ
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
  Future<List<SoundCreditSource>>? _creditsFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final l10n = AppLocalizations.of(context);
      final isEnglish = l10n?.localeName == 'en';
      _creditsFuture = _loadSoundCredits(isEnglish: isEnglish);
      _initialized = true;
    }
  }

  Future<List<SoundCreditSource>> _loadSoundCredits({required bool isEnglish}) async {
    if (widget.initialText != null) {
      return SoundCreditParser.parseSources(widget.initialText!, isEnglish: isEnglish);
    }
    try {
      final text = await rootBundle.loadString('assets/sounds/attributions.txt');
      return SoundCreditParser.parseSources(text, isEnglish: isEnglish);
    } catch (e) {
      debugPrint('Error loading sound attributions: $e');
      return [];
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
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
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

            // 説明文
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.soundCreditsDialogDesc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),

            // コンテンツ部（カード一覧）
            Expanded(
              child: FutureBuilder<List<SoundCreditSource>>(
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
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    );
                  }

                  final sources = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: sources.length,
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      return _buildSourceCard(context, source, l10n);
                    },
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

  /// 提供元ごとのカードUI
  Widget _buildSourceCard(
    BuildContext context,
    SoundCreditSource source,
    AppLocalizations l10n,
  ) {
    return Card(
      key: ValueKey<String>('sound_credit_card_${source.sourceName}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: const Color(0xFF28283E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提供元タイトル
            Row(
              children: [
                const Icon(Icons.library_music_outlined, color: Colors.tealAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source.sourceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 作者名
            if (source.author.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  l10n.soundCreditsAuthor(source.author),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // ライセンスバッジ
            if (source.license.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    source.license,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.tealAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // URL（タップでコピー）
            if (source.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: InkWell(
                  onTap: () => _copyToClipboard(context, source.url, l10n.soundCreditsCopiedUrl),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link, size: 15, color: Colors.lightBlueAccent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            source.url,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.lightBlueAccent,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy, size: 13, color: Colors.lightBlueAccent),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
