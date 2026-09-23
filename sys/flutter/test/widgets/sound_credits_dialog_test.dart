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

  testWidgets('SoundCreditsDialog renders title and close button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SoundCreditsDialog(initialText: sampleText),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // タイトルの存在確認
    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // 閉じるボタンのタップ
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('SoundCreditsDialog expands group card and renders entries without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SoundCreditsDialog(initialText: sampleText),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // ExpansionTile が表示されていることを確認（Springin' Sound Stock と Pixabay SoundEffect）
    expect(find.text("Springin' Sound Stock"), findsOneWidget);
    expect(find.text('Pixabay SoundEffect'), findsOneWidget);

    // Pixabay SoundEffect カードをタップして展開
    await tester.tap(find.text('Pixabay SoundEffect'));
    await tester.pumpAndSettle();

    // 展開後、ファイル名・説明・URLリンク・アイコンがエラーなく表示されていること
    expect(find.text('se_gear_turn.ogg'), findsOneWidget);
    expect(find.text('歯車がカチリと一段回る音'), findsOneWidget);
    expect(find.byIcon(Icons.audio_file), findsWidgets);
    expect(find.byIcon(Icons.link), findsWidgets);
  });
}
