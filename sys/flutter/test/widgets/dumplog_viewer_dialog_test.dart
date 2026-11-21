import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/dumplog_document.dart';
import 'package:darthack/models/topten_entry.dart';
import 'package:darthack/models/xlog_entry.dart';
import 'package:darthack/nethack_assets.dart';
import 'package:darthack/widgets/dumplog_viewer_dialog.dart';
import 'package:darthack/widgets/score_detail_dialog.dart';

String _recordLine({
  required int points,
  required String name,
  int deathdate = 20261121,
  int birthdate = 20261121,
}) {
  return '5.0.0 $points 0 1 1 0 16 1 $deathdate $birthdate 1000 Val Dwa Fem Law $name,killed by a jackal';
}

String _xlogLine({
  required int points,
  required String name,
  required int starttime,
  required int endtime,
  int deathdate = 20261121,
  int birthdate = 20261121,
}) {
  return [
    'version=5.0.0',
    'points=$points',
    'deathdnum=0',
    'deathlev=1',
    'maxlvl=1',
    'hp=0',
    'maxhp=16',
    'deaths=1',
    'deathdate=$deathdate',
    'birthdate=$birthdate',
    'uid=1000',
    'role=Val',
    'race=Dwa',
    'gender=Fem',
    'align=Law',
    'name=$name',
    'death=killed by a jackal',
    'conduct=0xfff',
    'turns=120',
    'achieve=0x0',
    'realtime=60',
    'starttime=$starttime',
    'endtime=$endtime',
    'gender0=Fem',
    'align0=Law',
    'flags=0x0',
    'gold=50',
    'wish_cnt=0',
    'arti_wish_cnt=0',
    'bones=0',
    'rerolls=0',
  ].join('\t');
}

const _sampleDumplogText = '''
NetHack 5.0.0

ゲーム開始: 2026-11-21 10:00:00 / 終了: 2026-11-21 10:15:00.

Taro（秩序・女・ドワーフ・ワルキューレ）

   ------
   |.@..|
   ------
階層:1  \$:50  HP:0(16)  T:120

最新メッセージ:
 ジャッカルはあなたを噛んだ！

所持品:
  a - ロングソード +1

倒した怪物:
  ゴブリン 1体

Game over:
                       ----------
                      /          \\
                     /    REST    \\
                    /      IN      \\
                   /     PEACE      \\
                  /                  \\
                  |      Player      |
                  |      46 Au       |
                  | ノームに倒された |
                  |       2026       |
                 *|     *  *  *      | *
        _________)\\\\_//(\\/(/\\)/\\//\\/|_)_______

さようなら ワルキューレのTaro...
あなたはメインダンジョンで死んだ。
''';

void main() {
  group('dumplog 同期 GC と TopTenEntry 紐付け', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('darthack_dumplog_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('syncLogsWithRecord で xlogfile 残存分以外の dumplog が削除されること', () async {
      File('${tempDir.path}/record').writeAsStringSync(
        '${_recordLine(points: 500, name: 'KeptHero')}\n',
      );
      File('${tempDir.path}/xlogfile').writeAsStringSync(
        '${_xlogLine(points: 500, name: 'KeptHero', starttime: 1000, endtime: 2000)}\n'
        '${_xlogLine(points: 100, name: 'DroppedHero', starttime: 3000, endtime: 4000)}\n',
      );
      final dumpDir = Directory('${tempDir.path}/dumplogs')..createSync();
      final keptDump = File('${dumpDir.path}/dump_1000_2000.txt')
        ..writeAsStringSync(_sampleDumplogText);
      final droppedDump = File('${dumpDir.path}/dump_3000_4000.txt')
        ..writeAsStringSync('dropped');
      final wizardDump = File('${dumpDir.path}/dump_9999_9999.txt')
        ..writeAsStringSync('wizard');
      final unrelatedFile = File('${dumpDir.path}/notes.txt')
        ..writeAsStringSync('keep me');

      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(keptDump.existsSync(), isTrue);
      expect(droppedDump.existsSync(), isFalse);
      expect(wizardDump.existsSync(), isFalse);
      expect(unrelatedFile.existsSync(), isTrue);
    });

    test('xlogfile 不在でも dumplogs/ 内の孤立 dump_*.txt が掃除されること', () async {
      final dumpDir = Directory('${tempDir.path}/dumplogs')..createSync();
      final orphanDump = File('${dumpDir.path}/dump_1111_2222.txt')
        ..writeAsStringSync('orphan');

      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(orphanDump.existsSync(), isFalse);
    });

    test('parseRecordFile / enrichTopTenEntriesWithXLog が存在する dumplogPath のみ設定すること', () {
      final recordPath = '${tempDir.path}/record';
      File(recordPath).writeAsStringSync(
        '${_recordLine(points: 500, name: 'WithDump')}\n'
        '${_recordLine(points: 300, name: 'NoDump')}\n',
      );
      File('${tempDir.path}/xlogfile').writeAsStringSync(
        '${_xlogLine(points: 500, name: 'WithDump', starttime: 1000, endtime: 2000)}\n'
        '${_xlogLine(points: 300, name: 'NoDump', starttime: 5000, endtime: 6000)}\n',
      );
      final dumpDir = Directory('${tempDir.path}${Platform.pathSeparator}dumplogs')..createSync();
      final dumpFile = File('${dumpDir.path}${Platform.pathSeparator}dump_1000_2000.txt')
        ..writeAsStringSync(_sampleDumplogText);

      final parsed = parseRecordFile(recordPath, isJp: true);
      expect(parsed, hasLength(2));
      expect(parsed[0].dumplogPath, dumpFile.path);
      expect(parsed[1].dumplogPath, isNull);

      final enriched = enrichTopTenEntriesWithXLog(
        [
          TopTenEntry(
            rank: 1,
            score: '500',
            nameAndProfile: 'WithDump ワルキューレ/ドワーフ/女/秩序',
            details: const ['ジャッカルに殺された'],
            isCurrent: true,
          ),
        ],
        assetsPath: tempDir.path,
        isJp: true,
      );
      expect(enriched.single.dumplogPath, dumpFile.path);
    });
  });

  group('ScoreDetailDialog と DumplogViewerDialog UI テスト', () {
    late Directory tempDir;
    late File dumpFile;
    late XLogEntry sampleXlog;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('darthack_dumplog_ui_');
      dumpFile = File('${tempDir.path}/dump_1000_2000.txt')
        ..writeAsStringSync(_sampleDumplogText);
      sampleXlog = XLogEntry.parseLine(
        _xlogLine(points: 500, name: 'Taro', starttime: 1000, endtime: 2000),
      )!;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('ScoreDetailDialog は dumplogPath ありのときのみ「ダンプを見る」ボタンを表示しタップで開けること', (tester) async {
      final entryWithDump = TopTenEntry(
        rank: 1,
        score: '500',
        nameAndProfile: 'Taro ワルキューレ/ドワーフ/女/秩序',
        details: const ['ジャッカルに殺された'],
        isCurrent: true,
        xlog: sampleXlog,
        dumplogPath: dumpFile.path,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: entryWithDump, isJp: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ダンプを見る'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);

      await tester.tap(find.text('ダンプを見る'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.byType(DumplogViewerDialog), findsOneWidget);
      expect(find.text('冒険ダンプ'), findsOneWidget);
      expect(find.textContaining('ロングソード +1'), findsOneWidget);
    });

    testWidgets('ScoreDetailDialog は dumplogPath が null のとき「ダンプを見る」ボタンを表示しないこと', (tester) async {
      final entryNoDump = TopTenEntry(
        rank: 1,
        score: '500',
        nameAndProfile: 'Taro ワルキューレ/ドワーフ/女/秩序',
        details: const ['ジャッカルに殺された'],
        isCurrent: false,
        xlog: sampleXlog,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: entryNoDump, isJp: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ダンプを見る'), findsNothing);
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('ScoreDetailDialog で d キーにより DumplogViewerDialog が開き Esc で閉じられること', (tester) async {
      final entryWithDump = TopTenEntry(
        rank: 1,
        score: '500',
        nameAndProfile: 'Taro ワルキューレ/ドワーフ/女/秩序',
        details: const ['ジャッカルに殺された'],
        isCurrent: true,
        xlog: sampleXlog,
        dumplogPath: dumpFile.path,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: entryWithDump, isJp: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.byType(DumplogViewerDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DumplogViewerDialog), findsNothing);
    });

    testWidgets('DumplogViewerDialog で初期折りたたみ・目次チップ展開・全展開・全文コピーが動作すること', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final doc = DumplogDocument.parse(_sampleDumplogText, isJp: true);
      final entry = TopTenEntry(
        rank: 1,
        score: '500',
        nameAndProfile: 'Taro ワルキューレ/ドワーフ/女/秩序',
        details: const ['ジャッカルに殺された'],
        isCurrent: true,
        dumplogPath: dumpFile.path,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: DumplogViewerDialog(
              entry: entry,
              initialDocument: doc,
              isJp: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 所持品は展開、倒した怪物は折りたたみ
      expect(find.textContaining('ロングソード +1'), findsOneWidget);
      expect(find.textContaining('ゴブリン 1体'), findsNothing);

      // 目次チップ（倒した怪物）をタップすると展開される
      await tester.tap(find.widgetWithText(ActionChip, '倒した怪物'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ゴブリン 1体'), findsOneWidget);

      // 全展開トグルで最新メッセージも展開される
      await tester.tap(find.byTooltip('すべて展開'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ジャッカルはあなたを噛んだ！'), findsOneWidget);

      // 全文コピー
      await tester.tap(find.byTooltip('全文コピー'));
      await tester.pumpAndSettle();
      expect(copiedText, _sampleDumplogText);

      // 最終マップは通常の monospace を使用すること（PixelMplus10 固定にしない）
      final mapTextWidget = tester.widget<Text>(find.textContaining('|.@..|'));
      expect(mapTextWidget.style?.fontFamily, 'monospace');

      // 墓石内の日本語行は通常の日本語フォント（fontFamily 継承 = null）で描画され、
      // 枠行は monospace で描画されること
      final jpTombText = tester.widget<Text>(find.text('ノームに倒された'));
      expect(jpTombText.style?.fontFamily, isNull);
      final asciiTombLine = tester.widget<Text>(find.textContaining('|      Player      |'));
      expect(asciiTombLine.style?.fontFamily, 'monospace');
    });
  });
}
