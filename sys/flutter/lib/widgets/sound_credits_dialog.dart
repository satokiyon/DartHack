import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/sound_credit_entry.dart';
import 'package:darthack/services/sound_manager.dart';

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
  bool _isEnglish = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final l10n = AppLocalizations.of(context);
      _isEnglish = l10n?.localeName == 'en';
      _creditsFuture = _loadSoundCredits(isEnglish: _isEnglish);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    // ダイアログを閉じる際にBGM試聴を停止し、本編BGMへ安全に復帰
    SoundManager.instance.stopPreviewBgm(restorePrevious: true);
    super.dispose();
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

            // 使用BGM一覧アコーディオン（BGMが存在する場合のみ表示）
            if (source.bgmEntries.isNotEmpty) ...[
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: Material(
                  color: const Color(0xFF1F1F32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ExpansionTile(
                    key: ValueKey<String>('bgm_expansion_${source.sourceName}'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    dense: true,
                    leading: const Icon(Icons.music_note, color: Colors.amberAccent, size: 20),
                    title: Text(
                      l10n.soundCreditsBgmList(source.bgmEntries.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    iconColor: Colors.amberAccent,
                    collapsedIconColor: Colors.white54,
                    children: source.bgmEntries.map((bgm) {
                      return _buildBgmTile(context, bgm, _isEnglish, l10n);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 個別BGMの試聴タイルUI
  Widget _buildBgmTile(
    BuildContext context,
    SoundCreditEntry entry,
    bool isEnglish,
    AppLocalizations l10n,
  ) {
    final title = SoundCreditParser.getBgmTitle(
      entry.fileName,
      isEnglish: isEnglish,
      description: entry.description,
    );

    return ValueListenableBuilder<String?>(
      valueListenable: SoundManager.instance.previewBgmNotifier,
      builder: (context, playingBgm, _) {
        final isPlaying = playingBgm == entry.fileName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Material(
            color: isPlaying
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isPlaying
                    ? Colors.amberAccent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.05),
                width: isPlaying ? 1.2 : 0.6,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              leading: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_outline,
                color: isPlaying ? Colors.amberAccent : Colors.tealAccent,
                size: 28,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPlaying ? Colors.amberAccent : Colors.white,
                      ),
                    ),
                  ),
                  if (isPlaying) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.soundCreditsPlay,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  entry.fileName + (entry.description.isNotEmpty ? '  •  ${entry.description}' : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () {
                if (isPlaying) {
                  // ダイアログ内での停止時は本編BGMを復帰させず無音停止
                  SoundManager.instance.stopPreviewBgm(restorePrevious: false);
                } else {
                  SoundManager.instance.startPreviewBgm(entry.fileName);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
