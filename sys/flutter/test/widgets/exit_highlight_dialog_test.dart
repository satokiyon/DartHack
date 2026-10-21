import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/config/ad_config.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/exit_highlight_dialog.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ja'),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('ExitHighlightDialog Tests (Windows vs Android Platform Behaviors)', () {
    tearDown(() {
      AdConfig.isAndroidOverride = null;
      AdConfig.isIOSOverride = null;
      AdConfig.bannerAdUnitIdOverride = null;
      AdConfig.rewardedAdUnitIdOverride = null;
    });

    testWidgets('Windows/非モバイル環境では広告待機アニメーションなしで即座にハイライトが表示されること', (tester) async {
      // Windows デスクトップ環境をシミュレート
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      const testMsg = 'ゲームを終了しました。';
      final testHistory = [
        'コボルドを倒した。',
        '青い薬を飲んだ。',
        '階段を降りた。',
      ];

      await tester.pumpWidget(
        createTestApp(
          ExitHighlightDialog(
            dialogMessage: testMsg,
            messageHistory: testHistory,
          ),
        ),
      );

      // 初回ビルド直後の状態
      await tester.pump();

      // 1. ダイアログ本文が表示されていること
      expect(find.text(testMsg), findsOneWidget);

      // 2. Windows環境では読込アニメーション（[@] や「記憶を辿っています」）が存在しないこと
      expect(find.text('[@]'), findsNothing);

      // 3. 即座にハイライト一覧（番号付き）が表示されていること
      expect(find.textContaining('1. '), findsOneWidget);

      // 4. OK ボタンが存在し、タップ可能であること
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('Android/モバイル環境では初期表示時に記憶探索中アニメーションが表示され、ロード完了後にハイライトが表示されること', (tester) async {
      // Android 環境をシミュレート
      AdConfig.isAndroidOverride = true;
      AdConfig.isIOSOverride = false;

      const testMsg = 'あなたは死んでしまった...';
      final testHistory = [
        'オークに攻撃された。',
        '毒針の罠にかかった。',
      ];

      await tester.pumpWidget(
        createTestApp(
          ExitHighlightDialog(
            dialogMessage: testMsg,
            messageHistory: testHistory,
          ),
        ),
      );

      await tester.pump();

      // モバイル環境の初期表示では、読込アニメーションが表示されること
      expect(find.text('[@]'), findsOneWidget);

      // タイマーを進める (5秒タイムアウト)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // タイムアウトまたは広告ロード完了後、アニメーションが消えハイライトが表示されること
      expect(find.text('[@]'), findsNothing);
      expect(find.textContaining('1. '), findsOneWidget);
    });

    testWidgets('履歴が空の場合は「なし」が表示されること', (tester) async {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      await tester.pumpWidget(
        createTestApp(
          const ExitHighlightDialog(
            dialogMessage: 'テスト終了',
            messageHistory: [],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('なし'), findsOneWidget);
    });

    testWidgets('履歴に重複がある場合に重複排除され最大3件まで表示されること', (tester) async {
      AdConfig.isAndroidOverride = false;
      AdConfig.isIOSOverride = false;

      final duplicatedHistory = [
        '同じメッセージ',
        '同じメッセージ',
        '同じメッセージ',
        '別のメッセージA',
        '別のメッセージB',
        '別のメッセージC',
        '別のメッセージD',
      ];

      await tester.pumpWidget(
        createTestApp(
          ExitHighlightDialog(
            dialogMessage: '重複テスト',
            messageHistory: duplicatedHistory,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 最大3件（1., 2., 3.）が表示され、4. は存在しないこと
      expect(find.textContaining('1. '), findsOneWidget);
      expect(find.textContaining('2. '), findsOneWidget);
      expect(find.textContaining('3. '), findsOneWidget);
      expect(find.textContaining('4. '), findsNothing);
    });
  });
}

