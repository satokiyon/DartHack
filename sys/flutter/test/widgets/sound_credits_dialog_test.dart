import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/widgets/sound_credits_dialog.dart';

void main() {
  const sampleText = '''
File:        se_bars_clonk.ogg
Description: 鉄格子への重い金属衝突音
Source:      Springin' Sound Stock (https://www.springin.org/sound-stock/)
Author:      Springin' Sound Stock
License:     Springin'利用規約（商用可・クレジット不要）
-------------------------------------------------------
File:        se_gear_turn.ogg
Description: 歯車がカチリと一段回る音
Source:      Pixabay SoundEffect (https://pixabay.com/sound-effects/)
Author:      Pixabay SoundEffect
License:     Pixabay Content License（商用可・ゲーム組込可・クレジット不要）
''';

  testWidgets('SoundCreditsDialog renders title, desc, and close button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SoundCreditsDialog(initialText: sampleText),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // タイトルとアイコン、説明文の存在確認
    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('DartHack で使用されているBGM・効果音の提供元およびライセンス一覧です。'), findsOneWidget);

    // 閉じるボタンのタップ
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('SoundCreditsDialog renders flat credit cards with source, author, license, and url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SoundCreditsDialog(initialText: sampleText),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 提供元カードが表示されていることを確認
    expect(find.text("Springin' Sound Stock"), findsOneWidget);
    expect(find.text('Pixabay SoundEffect'), findsOneWidget);

    // 作者名が表示されていることを確認（Pixabayはコミュニティ集約）
    expect(find.text("作者: Springin' Sound Stock"), findsOneWidget);
    expect(find.text('作者: Pixabay コミュニティの各クリエイター'), findsOneWidget);

    // 代表URLが表示されていることを確認
    expect(find.text('https://www.springin.org/sound-stock/'), findsOneWidget);
    expect(find.text('https://pixabay.com/sound-effects/'), findsOneWidget);

    // 個別曲名・ファイル名は表示されないこと（冗長性排除の確認）
    expect(find.text('se_gear_turn.ogg'), findsNothing);
    expect(find.text('se_bars_clonk.ogg'), findsNothing);

    // URLタップでSnackBar（コピー通知）が表示されること
    await tester.tap(find.text('https://pixabay.com/sound-effects/'));
    await tester.pump(); // SnackBar アニメーション開始
    expect(find.text('URLをクリップボードにコピーしました'), findsOneWidget);
  });

  testWidgets('SoundCreditsDialog displays BGM accordion and triggers BGM preview on tap', (tester) async {
    const sampleWithBgm = '''
File:        amb_dungeon.ogg
Description: メインダンジョンの探索曲
Source:      PeriTune (https://peritune.com/)
Author:      Seiko
License:     CC-BY 4.0
-------------------------------------------------------
File:        se_coin.ogg
Description: コインの音
Source:      効果音ラボ (https://soundeffect-lab.info/)
Author:      効果音ラボ
License:     効果音ラボ利用規約
''';

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SoundCreditsDialog(initialText: sampleWithBgm),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // PeriTune カード内に使用BGM一覧アコーディオンが表示されること
    expect(find.text('使用BGM一覧 (1曲)'), findsOneWidget);

    // 効果音ラボカードにはBGM一覧が表示されないこと
    expect(find.byKey(const ValueKey<String>('bgm_expansion_効果音ラボ')), findsNothing);

    // アコーディオンを展開
    await tester.tap(find.text('使用BGM一覧 (1曲)'));
    await tester.pumpAndSettle();

    // フロア名・部屋名（「運命の大迷宮」）とファイル名が表示されること
    expect(find.text('運命の大迷宮'), findsOneWidget);
    expect(find.textContaining('amb_dungeon.ogg'), findsOneWidget);

    // 再生アイコンが表示されること
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });
}
