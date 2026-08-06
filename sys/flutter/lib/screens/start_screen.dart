import 'package:flutter/material.dart';
import '../widgets/guidebook_dialog.dart';

class StartScreen extends StatelessWidget {
  final bool assetsReady;
  final VoidCallback onStartGame;
  final VoidCallback onShowSettings;

  const StartScreen({
    super.key,
    required this.assetsReady,
    required this.onStartGame,
    required this.onShowSettings,
  });

  @override
  Widget build(BuildContext context) {
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
              tooltip: "ガイドブック",
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
              tooltip: "ゲーム設定",
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
            bottom: 40,
            left: 24,
            right: 24,
            child: !assetsReady
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "アセットを準備中...",
                        style: TextStyle(
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
                            child: const Center(
                              child: Text(
                                '冒険を始める',
                                style: TextStyle(
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
              tooltip: "ガイドブック",
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
              tooltip: "ゲーム設定",
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
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "アセットを準備中...",
                                  style: TextStyle(
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
                                      child: const Center(
                                        child: Text(
                                          '冒険を始める',
                                          style: TextStyle(
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
