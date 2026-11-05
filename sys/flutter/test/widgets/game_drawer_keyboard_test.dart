import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/game_drawer.dart';
import 'package:darthack/l10n/app_localizations.dart';

void main() {
  Widget buildTestableDrawer({
    bool isGameRunning = true,
    bool isKeyboardVisible = true,
    required VoidCallback onClose,
    VoidCallback? onSaveAndExit,
    VoidCallback? onQuit,
    VoidCallback? onShowScoreboard,
    VoidCallback? onShowGuidebook,
    VoidCallback? onShowSpoilers,
    VoidCallback? onShowHelp,
    VoidCallback? onDatabaseSearch,
    VoidCallback? onOpenOptions,
    VoidCallback? onShowFullMap,
    VoidCallback? onToggleKeyboard,
    VoidCallback? onShowSettings,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: GameDrawerContent(
          isGameRunning: isGameRunning,
          isKeyboardVisible: isKeyboardVisible,
          onClose: onClose,
          onSaveAndExit: onSaveAndExit ?? () {},
          onQuit: onQuit ?? () {},
          onShowScoreboard: onShowScoreboard ?? () {},
          onShowGuidebook: onShowGuidebook ?? () {},
          onShowSpoilers: onShowSpoilers ?? () {},
          onShowHelp: onShowHelp ?? () {},
          onDatabaseSearch: onDatabaseSearch ?? () {},
          onOpenOptions: onOpenOptions ?? () {},
          onShowFullMap: onShowFullMap ?? () {},
          onToggleKeyboard: onToggleKeyboard ?? () {},
          onShowSettings: onShowSettings ?? () {},
        ),
      ),
    );
  }

  group('GameDrawer Keyboard Navigation Tests', () {
    testWidgets('Initial state is focusless (none), navigation with Down/Tab and Up/Shift+Tab cycles through items', (tester) async {
      int closeCount = 0;
      int saveCount = 0;
      int scoreboardCount = 0;

      await tester.pumpWidget(buildTestableDrawer(
        onClose: () => closeCount++,
        onSaveAndExit: () => saveCount++,
        onShowScoreboard: () => scoreboardCount++,
      ));
      await tester.pumpAndSettle();

      // 1. 初期状態: 未選択（none）の状態で Enter を押しても何も実行されない
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saveCount, equals(0));
      expect(closeCount, equals(0));

      // 2. Space を押しても誤爆防止のため何も実行されない
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(saveCount, equals(0));
      expect(closeCount, equals(0));

      // 3. ArrowDown で先頭項目（セーブして終了）を選択
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // セーブして終了にフォーカスがある状態で Enter を押すと実行される
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saveCount, equals(1));
      expect(closeCount, equals(1));
    });

    testWidgets('Tab cycling: none -> item 0 -> ... -> none', (tester) async {
      int quitCount = 0;
      int scoreboardCount = 0;

      await tester.pumpWidget(buildTestableDrawer(
        onClose: () {},
        onQuit: () => quitCount++,
        onShowScoreboard: () => scoreboardCount++,
      ));
      await tester.pumpAndSettle();

      // Tab -> item 0 (セーブして終了)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Tab -> item 1 (セーブせず終了)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Tab -> item 2 (スコアボード)
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(scoreboardCount, equals(1));
    });

    testWidgets('j and k keys work for navigation in drawer', (tester) async {
      int scoreboardCount = 0;

      await tester.pumpWidget(buildTestableDrawer(
        onClose: () {},
        onShowScoreboard: () => scoreboardCount++,
      ));
      await tester.pumpAndSettle();

      // 'j' -> item 0
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();

      // 'j' -> item 1
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();

      // 'j' -> item 2 (スコアボード)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();

      // 'k' -> item 1 に戻る
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.pump();

      // 'j' -> item 2 (スコアボード)
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump();
      expect(scoreboardCount, equals(1));
    });

    testWidgets('Home and End jump to first and last items', (tester) async {
      int settingsCount = 0;
      int saveCount = 0;

      await tester.pumpWidget(buildTestableDrawer(
        onClose: () {},
        onSaveAndExit: () => saveCount++,
        onShowSettings: () => settingsCount++,
      ));
      await tester.pumpAndSettle();

      // End -> 末尾項目（設定）
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(settingsCount, equals(1));

      // Home -> 先頭項目（セーブして終了）
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(saveCount, equals(1));
    });

    testWidgets('Escape, F10, ContextMenu, and Ctrl+M close the drawer', (tester) async {
      int closeCount = 0;

      await tester.pumpWidget(buildTestableDrawer(
        onClose: () => closeCount++,
      ));
      await tester.pumpAndSettle();

      // Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closeCount, equals(1));

      // F10
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pump();
      expect(closeCount, equals(2));

      // ContextMenu
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(closeCount, equals(3));
    });
  });
}

