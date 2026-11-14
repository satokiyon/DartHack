import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_prefs.dart';
import 'markdown_doc_viewer_dialog.dart';

/// DartHack 公式ユーザーマニュアル（アプリ内ヘルプ）閲覧ダイアログ
class DartHackHelpDialog extends StatelessWidget {
  final String? initialMarkdown;
  final bool? initialIsJp;

  const DartHackHelpDialog({
    super.key,
    this.initialMarkdown,
    this.initialIsJp,
  });

  static final MarkdownDocScrollState _scrollState = MarkdownDocScrollState();

  @visibleForTesting
  static void resetSavedScrollPosition() {
    _scrollState.reset();
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => const DartHackHelpDialog(),
    );
  }

  /// Markdown 内の相対画像パス (`images/manual/{ja,en}/xx.png`) をアセットパスへ解決する
  @visibleForTesting
  static ({String path, String fallbackPath}) resolveManualImagePath(
    String rawPath,
    bool isJp,
  ) {
    final normalized = rawPath.trim().replaceAll('\\', '/');
    final langDir = normalized.contains('/en/')
        ? 'en'
        : (normalized.contains('/ja/') ? 'ja' : (isJp ? 'ja' : 'en'));
    final fileName = normalized.split('/').last;
    final webpName = fileName.replaceFirst(
      RegExp(r'\.png$', caseSensitive: false),
      '.webp',
    );
    return (
      path: 'assets/manual/$langDir/images/$webpName',
      fallbackPath: 'assets/manual/$langDir/images/$fileName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MarkdownDocViewerDialog(
      title: l10n?.dartHackHelpTitle ?? 'DartHack Help',
      searchHint: l10n?.searchDartHackHelpHint ?? 'Search DartHack Help...',
      headerIcon: Icons.article_outlined,
      accentColor: Colors.cyanAccent,
      scrollState: _scrollState,
      initialMarkdown: initialMarkdown,
      initialIsJp: initialIsJp,
      imagePathResolver: resolveManualImagePath,
      loadDocument: () async {
        final prefs = await AppPrefs.getInstance();
        final lang = prefs.getString('selected_language') ?? 'ja';
        final isJp = lang == 'ja';
        final assetPath = isJp
            ? 'assets/manual/ja/darthack_help.md'
            : 'assets/manual/en/darthack_help.md';
        try {
          final md = await rootBundle.loadString(assetPath);
          return (markdown: md, isJp: isJp);
        } catch (e) {
          throw Exception(
            l10n?.failedToLoadDartHackHelp(e.toString()) ??
                'Failed to load DartHack Help: $e',
          );
        }
      },
    );
  }
}
