import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/tombstone_data.dart';
import 'package:darthack/widgets/tombstone_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyTombstoneLines = [
    '               REST',
    '          IN      PEACE',
    '               --',
    '             Player',
    '             100 Pt',
    '          システムショック',
    '             で死んだ',
    '               --',
    '               2026',
    '               --',
    '       /\\           /\\',
    '      /  \\         /  \\',
    '     /____\\       /____\\',
    '    _____________________',
    'ダンジョン階層 1',
  ];

  testWidgets('UniversalTombstoneWidgetにscrollControllerを渡すとスクロールコントローラーが接続される', (tester) async {
    final controller = ScrollController();
    addTearDown(() => controller.dispose());

    final data = TombstoneData.parse(dummyTombstoneLines);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UniversalTombstoneWidget(
            mode: TombstoneDisplayMode.image,
            data: data,
            lines: dummyTombstoneLines,
            scrollController: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // scrollController がクライアント（SingleChildScrollView）にアタッチされていることを検証
    expect(controller.hasClients, isTrue);
  });

  testWidgets('UniversalTombstoneWidget のテキスト表示モードでも日本語死因行が固定幅中央揃え・枠 monospace で描画されること', (tester) async {
    final controller = ScrollController();
    addTearDown(() => controller.dispose());

    const jpTextLines = [
      '                       ----------',
      '                      /          \\',
      '                     /    REST    \\',
      '                    /      IN      \\',
      '                   /     PEACE      \\',
      '                  /                  \\',
      '                  |      Player      |',
      '                  |      46 Au       |',
      '                  | ノームに倒された |',
      '                  |       2026       |',
      '                 *|     *  *  *      | *',
      '        _________)\\\\_//(\\/(/\\)/\\//\\/|_)_______',
      '',
      'さようなら 野蛮人のPlayer...',
      'あなたはノームの鉱山で死んだ。',
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        home: Scaffold(
          body: UniversalTombstoneWidget(
            mode: TombstoneDisplayMode.text,
            lines: jpTextLines,
            scrollController: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.hasClients, isTrue);
    expect(find.byType(TombstoneAsciiView), findsOneWidget);

    // 日本語死因行は通常フォント継承（fontFamily == null）で描画されること
    final jpDeathText = tester.widget<Text>(find.text('ノームに倒された'));
    expect(jpDeathText.style?.fontFamily, isNull);

    // ASCII 枠行は monospace で描画されること
    final asciiLine = tester.widget<Text>(find.textContaining('|      Player      |'));
    expect(asciiLine.style?.fontFamily, 'monospace');

    // 底辺より下の結末テキストも表示されること
    expect(find.textContaining('さようなら 野蛮人のPlayer...'), findsOneWidget);
  });
}

