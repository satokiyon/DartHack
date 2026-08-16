import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/guidebook_dialog.dart';

class StartScreen extends StatelessWidget {
  final bool assetsReady;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onStartGame;
  final VoidCallback onShowSettings;

  const StartScreen({
    super.key,
    required this.assetsReady,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onStartGame,
    required this.onShowSettings,
  });

  Widget _buildLanguageSelector(BuildContext context) {
    final isJp = (selectedLanguage == 'ja');
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              child: Row(
                children: [
                  Text(
                    '🇯🇵 日本語',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isJp ? FontWeight.bold : FontWeight.normal,
                      color: isJp ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
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
              child: Row(
                children: [
                  Text(
                    '🇺🇸 English',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: !isJp ? FontWeight.bold : FontWeight.normal,
                      color: !isJp ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    Widget startScreenContent;

    if (isPortrait) {
      startScreenContent = Stack(
        children: [
          Positioned(
            top: 16,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.menu_book, color: Colors.white70, size: 28),
              onPressed: () => GuidebookDialog.show(context),
              tooltip: l10n.guidebookTooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
              onPressed: onShowSettings,
              tooltip: l10n.settingsTooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.15,
            left: 24,
            right: 24,
            child: Center(
              child: Image.asset(
                'assets/images/darthack_logo.webp',
                width: screenWidth * 0.75,
                cacheWidth: (screenWidth * 0.75 * MediaQuery.of(context).devicePixelRatio).round(),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: !assetsReady
                ? Column(
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
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageSelector(context),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.indigo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
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
                      ),
                    ],
                  ),
          ),
        ],
      );
    } else {
      startScreenContent = Stack(
        children: [
          Positioned(
            top: 16,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.menu_book, color: Colors.white70, size: 28),
              onPressed: () => GuidebookDialog.show(context),
              tooltip: l10n.guidebookTooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70, size: 28),
              onPressed: onShowSettings,
              tooltip: l10n.settingsTooltip,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 60.0, 40.0, 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Image.asset(
                        'assets/images/darthack_logo.webp',
                        cacheWidth: (screenWidth * 0.4 * MediaQuery.of(context).devicePixelRatio).round(),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: !assetsReady
                          ? Column(
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
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLanguageSelector(context),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.deepPurple, Colors.indigo],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
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
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            isPortrait ? 'assets/images/darthack_title.webp' : 'assets/images/darthack_title_yoko.webp',
            cacheWidth: (screenWidth * MediaQuery.of(context).devicePixelRatio).round(),
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
