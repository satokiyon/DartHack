import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/image_cache_helper.dart';
import '../widgets/guidebook_dialog.dart';
import '../widgets/spoiler_dialog.dart';
import '../widgets/darthack_help_dialog.dart';

/// タイトル画面でのキーボードフォーカス対象
enum TitleScreenFocusTarget {
  none,
  language,
  startGame,
  settings,
  guidebook,
  spoilers,
  darthackHelp,
}

class StartScreen extends StatelessWidget {
  final bool assetsReady;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onStartGame;
  final VoidCallback onShowSettings;
  final TitleScreenFocusTarget currentFocusTarget;

  const StartScreen({
    super.key,
    required this.assetsReady,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onStartGame,
    required this.onShowSettings,
    this.currentFocusTarget = TitleScreenFocusTarget.none,
  });

  Widget _buildLanguageSelector(BuildContext context) {
    final isJp = (selectedLanguage == 'ja');
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.language;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused ? Colors.amberAccent : Colors.white24,
          width: isFocused ? 2.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, right: 6),
            child: Icon(
              Icons.translate,
              color: Colors.white70,
              size: 20,
            ),
          ),
          InkWell(
            onTap: () => onLanguageChanged('ja'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isJp ? Colors.deepPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isJp
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                '日本語',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isJp ? FontWeight.bold : FontWeight.normal,
                  color: isJp ? Colors.white : Colors.white60,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onLanguageChanged('en'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !isJp ? Colors.deepPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: !isJp
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: !isJp ? FontWeight.bold : FontWeight.normal,
                  color: !isJp ? Colors.white : Colors.white60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidebookButton(BuildContext context, AppLocalizations l10n) {
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.guidebook;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFocused ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: const Icon(Icons.menu_book, color: Colors.white70, size: 28),
        onPressed: () => GuidebookDialog.show(context),
        tooltip: l10n.guidebookTooltip,
        style: IconButton.styleFrom(
          backgroundColor: isFocused ? Colors.amberAccent.withValues(alpha: 0.2) : Colors.black38,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildSpoilerButton(BuildContext context, AppLocalizations l10n) {
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.spoilers;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFocused ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: const Icon(Icons.auto_stories, color: Colors.amberAccent, size: 28),
        onPressed: () => SpoilerDialog.show(context),
        tooltip: l10n.spoilersTooltip,
        style: IconButton.styleFrom(
          backgroundColor: isFocused ? Colors.amberAccent.withValues(alpha: 0.2) : Colors.black38,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildDartHackHelpButton(BuildContext context, AppLocalizations l10n) {
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.darthackHelp;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFocused ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: const Icon(Icons.article_outlined, color: Colors.cyanAccent, size: 28),
        onPressed: () => DartHackHelpDialog.show(context),
        tooltip: l10n.dartHackHelpTooltip,
        style: IconButton.styleFrom(
          backgroundColor: isFocused ? Colors.amberAccent.withValues(alpha: 0.2) : Colors.black38,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, AppLocalizations l10n) {
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.settings;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFocused ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
        onPressed: onShowSettings,
        tooltip: l10n.settingsTooltip,
        style: IconButton.styleFrom(
          backgroundColor: isFocused ? Colors.amberAccent.withValues(alpha: 0.2) : Colors.black38,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildStartGameButton(BuildContext context, AppLocalizations l10n) {
    final isFocused = currentFocusTarget == TitleScreenFocusTarget.startGame;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: isFocused ? Border.all(color: Colors.amberAccent, width: 2.5) : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStartGame,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              l10n.startAdventure,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black38,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          _buildGuidebookButton(context, l10n),
          const SizedBox(width: 10),
          _buildSpoilerButton(context, l10n),
          const SizedBox(width: 10),
          _buildDartHackHelpButton(context, l10n),
          const Spacer(),
          _buildSettingsButton(context, l10n),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, AppLocalizations l10n) {
    if (!assetsReady) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.preparingAssets,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(blurRadius: 4, color: Colors.black, offset: Offset(1, 1)),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildLanguageSelector(context),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _buildStartGameButton(context, l10n),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final bgCacheWidth = computeStableCacheWidth(context, maxWidth: 1920);
    final logoCacheWidth = computeStableCacheWidth(
      context,
      widthFactor: 0.75,
      maxWidth: 1024,
    );

    final Widget startScreenContent = isPortrait
        ? Column(
            children: [
              _buildTopToolbar(context, l10n),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Center(
                    child: Image.asset(
                      'assets/images/darthack_logo.webp',
                      cacheWidth: logoCacheWidth,
                      gaplessPlayback: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: _buildActionSection(context, l10n),
              ),
            ],
          )
        : Column(
            children: [
              _buildTopToolbar(context, l10n),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40.0, 8.0, 40.0, 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: Image.asset(
                            'assets/images/darthack_logo.webp',
                            cacheWidth: logoCacheWidth,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: SingleChildScrollView(
                            child: _buildActionSection(context, l10n),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isPortrait ? 'assets/images/darthack_title.webp' : 'assets/images/darthack_title_yoko.webp',
            cacheWidth: bgCacheWidth,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: startScreenContent,
          ),
        ),
      ],
    );
  }
}
