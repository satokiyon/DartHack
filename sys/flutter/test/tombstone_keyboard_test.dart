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
}

