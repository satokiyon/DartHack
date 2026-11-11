import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/models/topten_entry.dart';
import 'package:darthack/models/xlog_entry.dart';
import 'package:darthack/nethack_assets.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/widgets/overlays/text_overlay.dart';
import 'package:darthack/widgets/score_detail_dialog.dart';
import 'package:darthack/widgets/topten_widget.dart';

String _buildRecordLine({
  String version = '5.0.0',
  int points = 1000,
  int dnum = 0,
  int dlev = 5,
  int maxlvl = 6,
  int hp = 0,
  int maxhp = 40,
  int deaths = 1,
  int deathdate = 20261111,
  int birthdate = 20261110,
  int uid = 10470,
  String role = 'Wiz',
  String race = 'Elf',
  String gend = 'Mal',
  String align = 'Cha',
  String name = 'Hero',
  String death = 'killed by a newt',
}) {
  return '$version $points $dnum $dlev $maxlvl $hp $maxhp $deaths '
      '$deathdate $birthdate $uid $role $race $gend $align $name,$death';
}

String _buildXLogLine({
  String version = '5.0.0',
  int points = 1000,
  int deathdnum = 0,
  int deathlev = 5,
  int maxlvl = 6,
  int hp = 0,
  int maxhp = 40,
  int deaths = 1,
  int deathdate = 20261111,
  int birthdate = 20261110,
  int uid = 10470,
  String role = 'Wiz',
  String race = 'Elf',
  String gender = 'Mal',
  String align = 'Cha',
  String name = 'Hero',
  String death = 'killed by a newt',
  String? whileReason,
  String conduct = '0xfff',
  int turns = 1234,
  String achieve = '0x18000',
  String achieveX = 'entered_the_gnomish_mines,entered_mine_town',
  String conductX = 'wishless,artiwishless,genocideless',
  int realtime = 3665,
  int starttime = 1762732800,
  int endtime = 1762819200,
  String gender0 = 'Mal',
  String align0 = 'Cha',
  String flags = '0x0',
  int gold = 543,
  int wishCnt = 0,
  int artiWishCnt = 0,
  int bones = 1,
  int rerolls = 0,
}) {
  final parts = <String>[
    'version=$version',
    'points=$points',
    'deathdnum=$deathdnum',
    'deathlev=$deathlev',
    'maxlvl=$maxlvl',
    'hp=$hp',
    'maxhp=$maxhp',
    'deaths=$deaths',
    'deathdate=$deathdate',
    'birthdate=$birthdate',
    'uid=$uid',
    'role=$role',
    'race=$race',
    'gender=$gender',
    'align=$align',
    'name=$name',
    'death=$death',
    if (whileReason != null && whileReason.isNotEmpty) 'while=$whileReason',
    'conduct=$conduct',
    'turns=$turns',
    'achieve=$achieve',
    'achieveX=$achieveX',
    'conductX=$conductX',
    'realtime=$realtime',
    'starttime=$starttime',
    'endtime=$endtime',
    'gender0=$gender0',
    'align0=$align0',
    'flags=$flags',
    'gold=$gold',
    'wish_cnt=$wishCnt',
    'arti_wish_cnt=$artiWishCnt',
    'bones=$bones',
    'rerolls=$rerolls',
  ];
  return parts.join('\t');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('新規インストール起動・ログ同期・モデルパース検証', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('darthack_xlog_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('新規インストール起動時（record/logfile/xlogfile すべて未存在）に空ログを生成せず正常終了すること', () async {
      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(File('${tempDir.path}/record').existsSync(), isFalse);
      expect(File('${tempDir.path}/logfile').existsSync(), isFalse);
      expect(File('${tempDir.path}/xlogfile').existsSync(), isFalse);
      expect(findRecordFilePath(tempDir.path), isNull);
    });

    test('新規インストール時に 0 バイト空の record のみ存在しても logfile / xlogfile を生成しないこと', () async {
      File('${tempDir.path}/record').writeAsStringSync('');

      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(File('${tempDir.path}/logfile').existsSync(), isFalse);
      expect(File('${tempDir.path}/xlogfile').existsSync(), isFalse);
      expect(parseRecordFile('${tempDir.path}/record'), isEmpty);
    });

    test('バックアップ復旧等で record が空なのに肥大化 logfile / xlogfile だけ残っていたら空へトリムすること', () async {
      File('${tempDir.path}/logfile').writeAsStringSync('${_buildRecordLine(points: 50)}\n');
      File('${tempDir.path}/xlogfile').writeAsStringSync('${_buildXLogLine(points: 50)}\n');

      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(File('${tempDir.path}/logfile').readAsStringSync(), '');
      expect(File('${tempDir.path}/xlogfile').readAsStringSync(), '');
    });

    test('record に 5 件あり xlogfile のみ 120 件（wizard/圏外含む）・logfile 不在なら xlogfile のみ 5 件に整理し logfile は作らないこと', () async {
      final recLines = <String>[];
      final xlogLines = <String>[];

      for (int i = 0; i < 5; i++) {
        final pts = 1000 - i * 10;
        recLines.add(_buildRecordLine(points: pts, name: 'Hero$i'));
        xlogLines.add(_buildXLogLine(points: pts, name: 'Hero$i'));
      }
      // 圏外・wizard・重複ゴミ行を大量に追加
      for (int i = 0; i < 115; i++) {
        xlogLines.add(_buildXLogLine(
          points: 10 + i,
          name: 'Wizard$i',
          flags: '0x1',
        ));
      }
      // <eod> ダミー行も混ぜて無視されることを確認
      recLines.add('5.0.0 0 0 0 0 0 0 0 19700101 19700101 0 - - - - @,<eod>');

      File('${tempDir.path}/record').writeAsStringSync('${recLines.join('\n')}\n');
      File('${tempDir.path}/xlogfile').writeAsStringSync('${xlogLines.join('\n')}\n');

      await NetHackAssets.syncLogsWithRecordForTesting(tempDir);

      expect(File('${tempDir.path}/logfile').existsSync(), isFalse);
      final trimmedXLog = File('${tempDir.path}/xlogfile')
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      expect(trimmedXLog.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(trimmedXLog[i], contains('name=Hero$i'));
      }
    });

    test('同点スコア時の安定ソート、UTF-8 長名切り詰め・空白入り名でも 1対1 で xlogfile に紐付くこと', () {
      const longJpName = 'とてもながいぼうけんしゃのなまえ'; // 16文字 -> record側は10文字切り詰め
      const truncatedJpName = 'とてもながいぼうけんし'; // 10文字

      final recLines = <String>[
        _buildRecordLine(points: 500, name: 'First Hero', death: 'killed by a goblin'),
        _buildRecordLine(points: 500, name: 'Second Hero', death: 'killed by an orc'),
        _buildRecordLine(points: 300, name: truncatedJpName, death: 'petrified by a cockatrice'),
      ];
      final xlogLines = <String>[
        _buildXLogLine(points: 500, name: 'Second Hero', turns: 222, death: 'killed by an orc'),
        _buildXLogLine(points: 500, name: 'First Hero', turns: 111, death: 'killed by a goblin'),
        _buildXLogLine(
          points: 300,
          name: longJpName,
          turns: 333,
          whileReason: '無防備',
          achieveX: 'attained_the_rank_of_見習い魔術師,entered_the_gnomish_mines',
          conductX: 'foodless,pacifist',
          gender0: 'Fem',
          align0: 'Neu',
        ),
      ];

      final recPath = '${tempDir.path}/record';
      File(recPath).writeAsStringSync('${recLines.join('\n')}\n');
      File('${tempDir.path}/xlogfile').writeAsStringSync('${xlogLines.join('\n')}\n');

      final parsed = parseRecordFile(recPath, isJp: true);
      expect(parsed.length, 3);
      // 同点500点でも元の順位が保たれること
      expect(parsed[0].rank, 1);
      expect(parsed[0].nameAndProfile, startsWith('First Hero '));
      expect(parsed[0].xlog?.turns, 111);

      expect(parsed[1].rank, 2);
      expect(parsed[1].nameAndProfile, startsWith('Second Hero '));
      expect(parsed[1].xlog?.turns, 222);

      expect(parsed[2].rank, 3);
      expect(parsed[2].xlog?.turns, 333);
      expect(parsed[2].xlog?.whileReason, '無防備');
      expect(
        XLogEntry.translateAchievement(parsed[2].xlog!.achievements.first, true),
        '到達ランク: 見習い魔術師',
      );
    });

    test('初回通常死亡直後の TextOverlay 用パース結果に enrichTopTenEntriesWithXLog で xlogfile が紐付くこと', () {
      final recPath = '${tempDir.path}/record';
      File(recPath).writeAsStringSync('${_buildRecordLine(points: 777, name: 'FirstPlayer')}\n');
      File('${tempDir.path}/xlogfile').writeAsStringSync('${_buildXLogLine(points: 777, name: 'FirstPlayer', turns: 456, gold: 888)}\n');

      final parsedFromText = TopTenEntry.parse(
        [
          '順位      点数  名前                                                    HP[最大]',
          '  1        777  FirstPlayer 魔法使い/エルフ/男性/混沌 運命の大迷宮 5階（最大到達 6階）でニュートに殺された - [40]',
        ],
        [0, 1],
        isJp: true,
      );

      final enriched = enrichTopTenEntriesWithXLog(
        parsedFromText,
        assetsPath: tempDir.path,
        isJp: true,
      );

      expect(enriched.length, 1);
      expect(enriched.first.isCurrent, isTrue);
      expect(enriched.first.xlog, isNotNull);
      expect(enriched.first.xlog!.turns, 456);
      expect(enriched.first.xlog!.gold, 888);
    });

    test('XLogEntry のビットマスクフォールバックと時間フォーマットが日英で正しく動作すること', () {
      final line = 'version=5.0.0\tpoints=2000\tdeathdnum=0\tdeathlev=1\tmaxlvl=1\t'
          'hp=50\tmaxhp=50\tdeaths=0\tdeathdate=20261111\tbirthdate=20261111\t'
          'uid=10470\trole=Val\trace=Hum\tgender=Fem\talign=Law\tname=Valk\t'
          'death=ascended\tconduct=0x21\tturns=5000\tachieve=0x101\t'
          'achieveX=\tconductX=\trealtime=3661\tstarttime=0\tendtime=0\t'
          'gender0=Fem\talign0=Law\tflags=0x4\tgold=100\twish_cnt=1\t'
          'arti_wish_cnt=0\tbones=0\trerolls=2';

      final parsed = XLogEntry.parseLine(line)!;
      expect(parsed.achievements, containsAll(['obtained_the_bell_of_opening', 'ascended']));
      expect(parsed.conducts, containsAll(['foodless', 'pacifist']));
      expect(XLogEntry.formatDuration(parsed.realtime, true), '1時間 1分 1秒');
      expect(XLogEntry.formatDuration(parsed.realtime, false), '1h 1m 1s');
      expect(XLogEntry.decodeFlags(parsed.flags, true), ['骨ファイル未遭遇']);
      expect(XLogEntry.decodeFlags(parsed.flags, false), ['No Bones Loaded']);
    });
  });

  group('スコアボード・詳細ダイアログ UI / スクロール / キーボード検証', () {
    testWidgets('新規インストール直後のスコアボードは空メッセージを表示しエラーにならないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ja'),
          home: Scaffold(
            body: ScoreboardDialog(entries: [], isJp: true),
          ),
        ),
      );

      expect(find.text('スコア記録がありません'), findsOneWidget);
    });

    testWidgets('カードタップで ScoreDetailDialog が開き、閉じると onDetailClosed / 親フォーカス復帰が呼ばれること', (tester) async {
      final xlog = XLogEntry.parseLine(_buildXLogLine(
        points: 1500,
        name: 'TapHero',
        turns: 999,
        gold: 321,
        wishCnt: 2,
        artiWishCnt: 1,
      ))!;

      final entry = TopTenEntry(
        rank: 1,
        score: '1500',
        nameAndProfile: 'TapHero 魔法使い/エルフ/男性/混沌',
        details: const ['ニュートに殺された (運命の大迷宮 5階)', 'HP/最大HP: -/40'],
        isCurrent: true,
        xlog: xlog,
      );

      bool closedCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: TopTenWidget(
              entries: [entry],
              isJp: true,
              onDetailClosed: () => closedCallbackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('TapHero 魔法使い/エルフ/男性/混沌'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('321 Zm'), findsOneWidget);
      expect(find.text('2 回（アーティファクト: 1 回）'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsNothing);
      expect(closedCallbackCalled, isTrue);
    });

    testWidgets('狭い画面でもオーバーフローせず縦スクロールでき、Space で下スクロール・Shift+Space で上スクロール・最下部で Space で閉じること', (tester) async {
      tester.view.physicalSize = const Size(320, 420);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final xlog = XLogEntry.parseLine(_buildXLogLine(
        points: 99999,
        name: 'NarrowHero',
        achieveX: 'ascended,entered_astral_plane,entered_elemental_planes,'
            'obtained_the_amulet_of_yendor,performed_the_invocation_ritual,'
            'obtained_the_book_of_the_dead,obtained_the_bell_of_opening,'
            'obtained_the_candelabrum_of_invocation,entered_gehennom,defeated_medusa',
        conductX: 'foodless,vegan,vegetarian,atheist,weaponless,pacifist,illiterate,wishless',
        gender0: 'Fem',
        align0: 'Law',
      ))!;

      final entry = TopTenEntry(
        rank: 1,
        score: '99999',
        nameAndProfile: 'NarrowHero 魔法使い/エルフ/男性/混沌',
        details: const ['昇天した'],
        isCurrent: false,
        xlog: xlog,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => ScoreDetailDialog(entry: entry, isJp: true),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(tester.takeException(), isNull);

      final scrollable = find.descendant(
        of: find.byType(ScoreDetailDialog),
        matching: find.byType(Scrollable),
      );
      final scrollState = tester.state<ScrollableState>(scrollable);
      expect(scrollState.position.maxScrollExtent, greaterThan(50.0));
      expect(scrollState.position.pixels, 0.0);

      // 1回目の Space: 下へスクロールし、ダイアログは閉じない
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      final afterFirstSpace = scrollState.position.pixels;
      expect(afterFirstSpace, greaterThan(0.0));

      // Shift + Space: 上へ戻る
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(scrollState.position.pixels, lessThan(afterFirstSpace));

      // End キーで最下部へジャンプ -> Space キーリピートでは閉じないが、KeyDown で閉じること
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(
        scrollState.position.pixels,
        greaterThanOrEqualTo(scrollState.position.maxScrollExtent - 5.0),
      );

      // KeyRepeatEvent の Space では誤爆クローズしない
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreDetailDialog), findsOneWidget);

      // KeyDownEvent の Space を最下部で押すと閉じる
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreDetailDialog), findsNothing);
    });

    testWidgets('初回 wizard/探索モード・xlogfile 不在レコード（1画面に収まる場合）はフォールバック表示し Space 1回で閉じること', (tester) async {
      final wizardEntry = TopTenEntry(
        rank: 0,
        score: '150',
        nameAndProfile: 'WizTester 魔法使い/人間/男性/混沌',
        details: const ['ニュートに殺された', 'HP/最大HP: -/15'],
        isCurrent: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => ScoreDetailDialog(entry: wizardEntry, isJp: true),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(find.textContaining('ウィザード・探索モードまたはランキング圏外'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(ScoreDetailDialog), findsNothing);
    });

    testWidgets('TextOverlay 内の TopTenWidget でも初回死亡時にキャッシュ済みデータから詳細ダイアログを開けること', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('darthack_text_overlay_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      File('${tempDir.path}/record')
          .writeAsStringSync('${_buildRecordLine(points: 420, name: 'OverlayHero')}\n');
      File('${tempDir.path}/xlogfile')
          .writeAsStringSync('${_buildXLogLine(points: 420, name: 'OverlayHero', turns: 321)}\n');

      bool restoredFocus = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: Stack(
              children: [
                TextOverlay(
                  textLines: const [
                    '順位      点数  名前                                                    HP[最大]',
                    '  1        420  OverlayHero 魔法使い/エルフ/男性/混沌 運命の大迷宮 5階でニュートに殺された - [40]',
                  ],
                  textAttrs: const [0, 1],
                  textTiles: const [-1, -1],
                  isPlainDialog: false,
                  tombstoneDisplayMode: 1,
                  onDismiss: () {},
                  onShowMsgHistory: () {},
                  bottomInset: 0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                  assetsPath: tempDir.path,
                  onRestoreGameFocus: () => restoredFocus = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('OverlayHero'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(find.text('321'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsNothing);
      expect(restoredFocus, isTrue);
    });

    test('matchesRecordFields で前後空白・UTF-8切り詰め・旧記録 U+FFFD 末尾を許容し、短名誤一致を防ぐこと', () {
      final baseArgs = <String, dynamic>{
        'points': 500,
        'deathdnum': 0,
        'deathlev': 5,
        'maxlvl': 6,
        'hp': 0,
        'maxhp': 40,
        'deaths': 1,
        'deathdate': 20261111,
        'birthdate': 20261110,
        'uid': 10470,
        'role': 'Wiz',
        'race': 'Elf',
        'gender': 'Mal',
        'align': 'Cha',
      };

      bool match(String xlogName, String recName) {
        final entry = XLogEntry.parseLine(_buildXLogLine(
          points: 500,
          name: xlogName,
        ))!;
        return entry.matchesRecordFields(
          points: baseArgs['points'] as int,
          deathdnum: baseArgs['deathdnum'] as int,
          deathlev: baseArgs['deathlev'] as int,
          maxlvl: baseArgs['maxlvl'] as int,
          hp: baseArgs['hp'] as int,
          maxhp: baseArgs['maxhp'] as int,
          deaths: baseArgs['deaths'] as int,
          deathdate: baseArgs['deathdate'] as int,
          birthdate: baseArgs['birthdate'] as int,
          uid: baseArgs['uid'] as int,
          role: baseArgs['role'] as String,
          race: baseArgs['race'] as String,
          gender: baseArgs['gender'] as String,
          align: baseArgs['align'] as String,
          name: recName,
        );
      }

      // 前後空白の吸収
      expect(match('  Alice  ', 'Alice'), isTrue);
      expect(match('Alice', '  Alice  '), isTrue);

      // UTF-8 10文字切り詰め（日本語・絵文字）
      expect(match('勇者A🎨冒険者12345', '勇者A🎨冒険者123'), isTrue);

      // 旧英語コア (10バイト切断) での途中切れ U+FFFD や 8バイト絵文字切り詰め
      expect(match('あいうえお', 'あいう\uFFFD'), isTrue);
      expect(match('😀😀😀', '😀😀\uFFFD'), isTrue);
      expect(match('😀😀😀', '😀😀'), isTrue);

      // 短い名前の前方誤一致を防止
      expect(match('Heroine', 'Hero'), isFalse);
      expect(match('Alexander', 'Alex'), isFalse);
    });

    testWidgets('TopTenWidget は xlogfile ありの記録のみ「詳細」/「Details」バッジを表示し、なしでは非表示にすること', (tester) async {
      final withXlog = TopTenEntry(
        rank: 1,
        score: '1200',
        nameAndProfile: 'NewHero 魔法使い/エルフ/男性/混沌',
        details: const ['ゴブリンに殺された', 'HP/最大HP: -/30'],
        isCurrent: false,
        xlog: XLogEntry.parseLine(_buildXLogLine(points: 1200, name: 'NewHero')),
      );
      final withoutXlog = TopTenEntry(
        rank: 2,
        score: '800',
        nameAndProfile: 'LegacyHero 戦士/人間/男性/秩序',
        details: const ['ニュートに殺された', 'HP/最大HP: -/25'],
        isCurrent: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: TopTenWidget(
              entries: [withXlog, withoutXlog],
              isJp: true,
            ),
          ),
        ),
      );

      expect(find.text('詳細'), findsOneWidget);
      expect(find.text('Details'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: TopTenWidget(
              entries: [withXlog, withoutXlog],
              isJp: false,
            ),
          ),
        ),
      );

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('詳細'), findsNothing);
    });

    testWidgets('rank > 0 かつ xlogfile なしの旧レコードで ScoreDetailDialog が旧バージョン案内文を表示すること', (tester) async {
      final legacyEntry = TopTenEntry(
        rank: 3,
        score: '650',
        nameAndProfile: 'OldTimer 魔法使い/人間/男性/混沌',
        details: const ['キラー・ビーに殺された', 'HP/最大HP: -/20'],
        isCurrent: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: legacyEntry, isJp: true),
          ),
        ),
      );

      expect(find.textContaining('旧バージョンで記録されたスコアには詳細データが含まれない場合があります。'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: legacyEntry, isJp: false),
          ),
        ),
      );

      expect(find.textContaining('Scores recorded in older versions may not include detailed data.'), findsOneWidget);
    });

    testWidgets('TopTenWidget はタイトル横に「タップで詳細」/「Tap for details」を表示しないこと', (tester) async {
      final entry = TopTenEntry(
        rank: 1,
        score: '1200',
        nameAndProfile: 'TitleHero 魔法使い/エルフ/男性/混沌',
        details: const ['ゴブリンに殺された', 'HP/最大HP: -/30'],
        isCurrent: true,
        xlog: XLogEntry.parseLine(_buildXLogLine(points: 1200, name: 'TitleHero')),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: TopTenWidget(entries: [entry], isJp: true),
          ),
        ),
      );
      expect(find.text('スコアボード'), findsOneWidget);
      expect(find.text('詳細'), findsOneWidget);
      expect(find.text('タップで詳細'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: TopTenWidget(entries: [entry], isJp: false),
          ),
        ),
      );
      expect(find.text('Scoreboard'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Tap for details'), findsNothing);
    });

    testWidgets('ScoreDetailDialog が flags=0x4 を日英で「骨ファイル未遭遇」/「No Bones Loaded」と表示すること', (tester) async {
      final line = 'version=5.0.1\tpoints=1500\tdeathdnum=0\tdeathlev=3\tmaxlvl=4\t'
          'hp=0\tmaxhp=30\tdeaths=1\tdeathdate=20261111\tbirthdate=20261111\t'
          'uid=10470\trole=Wiz\trace=Elf\tgender=Mal\talign=Cha\tname=BonesHero\t'
          'death=killed by a newt\tconduct=0x0\tturns=120\tachieve=0x0\t'
          'achieveX=\tconductX=\trealtime=60\tstarttime=0\tendtime=0\t'
          'gender0=Mal\talign0=Cha\tflags=0x4\tgold=0\twish_cnt=0\t'
          'arti_wish_cnt=0\tbones=0\trerolls=0';
      final entry = TopTenEntry(
        rank: 1,
        score: '1500',
        nameAndProfile: 'BonesHero 魔法使い/エルフ/男性/混沌',
        details: const ['ニュートに殺された'],
        isCurrent: true,
        xlog: XLogEntry.parseLine(line),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(body: ScoreDetailDialog(entry: entry, isJp: true)),
        ),
      );
      expect(find.text('骨ファイル未遭遇'), findsOneWidget);
      expect(find.text('骨ファイル無効'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(body: ScoreDetailDialog(entry: entry, isJp: false)),
        ),
      );
      expect(find.text('No Bones Loaded'), findsOneWidget);
      expect(find.text('Bones Disabled'), findsNothing);
    });

    testWidgets('TextOverlay で同一ミュータブル List 参照がインプレース更新されても墓石から TopTenWidget へ切り替わること', (tester) async {
      final mutableLines = <String>[
        for (int i = 0; i < 12; i++) '---------- line $i ----------',
        'REST',
        'IN',
        'PEACE',
      ];
      final mutableAttrs = List<int>.filled(mutableLines.length, 0, growable: true);
      final mutableTiles = List<int>.filled(mutableLines.length, -1, growable: true);

      Widget buildApp() => MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Stack(
                children: [
                  TextOverlay(
                    textLines: mutableLines,
                    textAttrs: mutableAttrs,
                    textTiles: mutableTiles,
                    isPlainDialog: false,
                    tombstoneDisplayMode: 1,
                    onDismiss: () {},
                    onShowMsgHistory: () {},
                    bottomInset: 0,
                    useTiles: false,
                    tileImage: null,
                    tileWidth: 32,
                    tileHeight: 32,
                  ),
                ],
              ),
            ),
          );

      await tester.pumpWidget(buildApp());
      expect(find.byType(TopTenWidget), findsNothing);

      // 同じ List インスタンスの中身を死亡時トップ100へインプレース書き換え
      mutableLines
        ..clear()
        ..addAll([
          'トップ10入りした。',
          '',
          '順位      点数  名前                                                    HP[最大]',
          '  1        900  MutableHero 魔法使い/エルフ/男性/混沌 運命の大迷宮 4階でゴブリンに殺された - [30]',
        ]);
      mutableAttrs
        ..clear()
        ..addAll([0, 0, 0, 1]);
      mutableTiles
        ..clear()
        ..addAll([-1, -1, -1, -1]);

      await tester.pumpWidget(buildApp());
      expect(find.byType(TopTenWidget), findsOneWidget);
      expect(find.textContaining('MutableHero'), findsOneWidget);
      expect(find.text('今回の記録'), findsOneWidget);
    });

    testWidgets('NetHackScreen 経由で endwin 破棄後に再ビルドなしで toptenwin へ遷移してもカード形式・先頭スクロール・詳細表示が動作すること', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('darthack_death_flow_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      File('${tempDir.path}/record')
          .writeAsStringSync('${_buildRecordLine(points: 777, name: 'DeathFlowHero')}\n');
      File('${tempDir.path}/xlogfile')
          .writeAsStringSync('${_buildXLogLine(points: 777, name: 'DeathFlowHero', turns: 456, flags: '0x4', bones: 0)}\n');

      final screen = NetHackScreen();
      final overlayKey = GlobalKey<TextOverlayState>();
      late void Function(VoidCallback) hostSetState;

      // 1. endwin (墓石 + 長文) 作成・表示
      screen.createWindow(10, NetHackScreen.nhwText);
      screen.putString(10, 0, '      REST');
      screen.putString(10, 0, '      IN');
      screen.putString(10, 0, '      PEACE');
      for (int i = 0; i < 30; i++) {
        screen.putString(10, 0, '最終結果行 $i');
      }
      screen.displayWindow(10, true);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                hostSetState = setState;
                return Stack(
                  children: [
                    if (screen.isTextWindowVisible)
                      TextOverlay(
                        key: overlayKey,
                        textLines: List<String>.unmodifiable(screen.textLines),
                        textAttrs: List<int>.unmodifiable(screen.textAttrs),
                        textTiles: List<int>.unmodifiable(screen.textTiles),
                        isPlainDialog: screen.isPlainDialog,
                        plainType: screen.plainType,
                        tombstoneDisplayMode: 1,
                        onDismiss: () {},
                        onShowMsgHistory: () {},
                        bottomInset: 0,
                        useTiles: false,
                        tileImage: null,
                        tileWidth: 32,
                        tileHeight: 32,
                        assetsPath: tempDir.path,
                        windowRevision: screen.textWindowRevision,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(TopTenWidget), findsNothing);
      overlayKey.currentState!.scrollController.jumpTo(120.0);
      await tester.pump();
      expect(overlayKey.currentState!.scrollController.offset, greaterThan(0.0));

      // 2. main.dart と同様に destroyWindow 時は setState せず、toptenwin の displayWindow で初めて setState する
      screen.destroyWindow(10);
      screen.createWindow(11, NetHackScreen.nhwText);
      screen.putString(11, 0, 'トップ10入りした。');
      screen.putString(11, 0, '');
      screen.putString(11, 0, '順位      点数  名前                                                    HP[最大]');
      screen.putString(11, 1, '  1        777  DeathFlowHero 魔法使い/エルフ/男性/混沌 運命の大迷宮 5階でニュートに殺された - [40]');
      screen.displayWindow(11, true);
      hostSetState(() {});
      await tester.pump();

      expect(find.byType(TopTenWidget), findsOneWidget);
      expect(overlayKey.currentState!.scrollController.offset, equals(0.0));
      expect(find.text('今回の記録'), findsOneWidget);
      expect(find.text('詳細'), findsOneWidget);
      expect(find.text('タップで詳細'), findsNothing);

      await tester.tap(find.textContaining('DeathFlowHero'));
      await tester.pumpAndSettle();

      expect(find.byType(ScoreDetailDialog), findsOneWidget);
      expect(find.text('456'), findsOneWidget);
      expect(find.text('骨ファイル未遭遇'), findsOneWidget);
    });

    testWidgets('英語一般テキストの部分一致やエントリ0件ヘッダーでは TopTenWidget へ誤遷移せずプレーンテキスト表示を維持すること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Stack(
              children: [
                TextOverlay(
                  textLines: const [
                    'Another item with unknown points and name appears here.',
                    'Second plain line.',
                  ],
                  textAttrs: const [0, 0],
                  textTiles: const [-1, -1],
                  isPlainDialog: false,
                  tombstoneDisplayMode: 1,
                  onDismiss: () {},
                  onShowMsgHistory: () {},
                  bottomInset: 0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TopTenWidget), findsNothing);
      expect(find.textContaining('Another item with unknown points and name'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Stack(
              children: [
                TextOverlay(
                  textLines: const [
                    ' No  Points     Name                                                     Hp [max]',
                    'No entries yet.',
                  ],
                  textAttrs: const [0, 0],
                  textTiles: const [-1, -1],
                  isPlainDialog: false,
                  tombstoneDisplayMode: 1,
                  onDismiss: () {},
                  onShowMsgHistory: () {},
                  bottomInset: 0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                  windowRevision: 2,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TopTenWidget), findsNothing);
      expect(find.text('No entries yet.'), findsOneWidget);
    });

    test('translateConduct で genocideless が 虐殺なし になり extractUnrecordedNotice が各未記録ケースを判定すること', () {
      expect(XLogEntry.translateConduct('genocideless', true), equals('虐殺なし'));

      final ranked = [
        TopTenEntry(
          rank: 5,
          score: '1200',
          nameAndProfile: 'Hero 魔法使い/エルフ/男性/混沌',
          details: const ['ニュートに殺された'],
          isCurrent: true,
        ),
      ];
      expect(
        TopTenEntry.extractUnrecordedNotice(
          const ['トップ10入りした。', '', '順位 点数 名前'],
          ranked,
          isJp: true,
        ),
        isNull,
      );

      final outOfTop100 = [
        TopTenEntry(
          rank: 0,
          score: '50',
          nameAndProfile: 'OutHero 魔法使い/エルフ/男性/混沌',
          details: const ['ゴブリンに殺された'],
          isCurrent: true,
        ),
      ];
      expect(
        TopTenEntry.extractUnrecordedNotice(const [], outOfTop100, isJp: true),
        equals('トップ100圏外のため、スコア記録には保存されませんでした。'),
      );
      expect(
        TopTenEntry.extractUnrecordedNotice(const [], outOfTop100, isJp: false),
        equals('Your score did not make the top 100 and was not recorded.'),
      );

      final zeroPoints = [
        TopTenEntry(
          rank: 0,
          score: '0',
          nameAndProfile: 'ZeroHero 魔法使い/エルフ/男性/混沌',
          details: const ['自爆した'],
          isCurrent: true,
        ),
      ];
      expect(
        TopTenEntry.extractUnrecordedNotice(const [], zeroPoints, isJp: true),
        equals('0点（最低点未満）のため、スコア記録には保存されませんでした。'),
      );
      expect(
        TopTenEntry.extractUnrecordedNotice(const [], zeroPoints, isJp: false),
        equals('Scores of 0 points are not recorded on the scoreboard.'),
      );

      expect(
        TopTenEntry.extractUnrecordedNotice(
          const [
            '',
            '前回の自己記録 5000 点を更新できなかった。',
            '',
            '順位      点数  名前',
          ],
          outOfTop100,
          isJp: true,
        ),
        equals('前回の自己記録 5000 点を更新できなかった。 今回のスコアはランキングに記録されませんでした。'),
      );
      expect(
        TopTenEntry.extractUnrecordedNotice(
          const [
            '',
            "You didn't beat your previous score of 5000 points.",
            '',
            ' No  Points  Name',
          ],
          outOfTop100,
          isJp: false,
        ),
        equals("You didn't beat your previous score of 5000 points. This score was not recorded."),
      );
    });

    testWidgets('ScoreDetailDialog の縛りプレイ表示で ジェノサイドなし ではなく 虐殺なし が表示されること', (tester) async {
      final xlog = XLogEntry.parseLine(
        _buildXLogLine(
          points: 3200,
          name: 'ConductHero',
          conductX: 'wishless,genocideless',
        ),
      )!;
      final entry = TopTenEntry(
        rank: 1,
        score: '3200',
        nameAndProfile: 'ConductHero 魔法使い / エルフ / 男性 / 混沌',
        details: const ['ニュートに殺された'],
        isCurrent: true,
        xlog: xlog,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: ScoreDetailDialog(entry: entry, isJp: true),
          ),
        ),
      );

      expect(find.textContaining('虐殺なし'), findsOneWidget);
      expect(find.textContaining('ジェノサイドなし'), findsNothing);
    });

    List<TopTenEntry> buildSampleTopTenEntries({
      int count = 25,
      Set<int> currentIndices = const {},
      int? lastRankOverride,
      String? lastScoreOverride,
    }) {
      return List<TopTenEntry>.generate(count, (i) {
        final isLast = i == count - 1;
        final rank = (isLast && lastRankOverride != null) ? lastRankOverride : (i + 1);
        final score = (isLast && lastScoreOverride != null)
            ? lastScoreOverride
            : '${(count - i) * 100}';
        // 可変カード高さを再現するため一部エントリは複数行詳細を持たせる
        final details = i.isEven
            ? [
                '運命の大迷宮 ${i + 1}階で${i % 4 == 0 ? '非常に手強い古代のドラゴンに炎のブレスで焼かれて' : 'ゴブリンに'}殺された',
                'HP/最大HP: 0/50',
              ]
            : ['運命の大迷宮 ${i + 1}階でニュートに殺された'];
        return TopTenEntry(
          rank: rank,
          score: score,
          nameAndProfile: 'SampleHero$i 魔法使い / エルフ / 男性 / 混沌',
          details: details,
          isCurrent: currentIndices.contains(i),
        );
      });
    }

    testWidgets('TopTenWidget が中位ランクイン時に画面中央付近へ即時スクロールし手動スクロール後の再ビルドでも維持されること', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final entries = buildSampleTopTenEntries(count: 25, currentIndices: {14});
      late void Function(VoidCallback) hostSetState;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 460,
              child: StatefulBuilder(
                builder: (context, setState) {
                  hostSetState = setState;
                  return TopTenWidget(
                    entries: List<TopTenEntry>.of(entries),
                    isJp: true,
                    scrollController: controller,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listRect = tester.getRect(find.byType(ListView));
      final targetFinder = find.textContaining('SampleHero14 ');
      expect(targetFinder, findsOneWidget);
      final targetCardFinder = find.ancestor(of: targetFinder, matching: find.byType(Card));
      final targetCenterY = tester.getCenter(targetCardFinder).dy;
      expect((targetCenterY - listRect.center.dy).abs(), lessThanOrEqualTo(48.0));
      expect(controller.offset, greaterThan(0.0));

      // 手動スクロール後に同内容の新しい List インスタンスで再ビルドしても先頭等へ戻らないこと
      controller.jumpTo(120.0);
      await tester.pump();
      hostSetState(() {});
      await tester.pumpAndSettle();
      expect(controller.offset, equals(120.0));
    });

    testWidgets('TopTenWidget が先頭ランクイン時はオフセット0、100位圏外や0点時は固定バナー・ハイフン表記・最下部スクロールになること', (tester) async {
      final firstController = ScrollController();
      addTearDown(firstController.dispose);
      final firstEntries = buildSampleTopTenEntries(count: 25, currentIndices: {0});

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 460,
              child: TopTenWidget(
                entries: firstEntries,
                isJp: true,
                scrollController: firstController,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstController.offset, equals(0.0));
      expect(find.textContaining('記録には保存されませんでした'), findsNothing);

      // 100位圏外 (rank: 0, score: 50) が末尾にあるケース
      final outController = ScrollController();
      addTearDown(outController.dispose);
      final outEntries = buildSampleTopTenEntries(
        count: 25,
        currentIndices: {24},
        lastRankOverride: 0,
        lastScoreOverride: '50',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 460,
              child: TopTenWidget(
                entries: outEntries,
                isJp: true,
                scrollController: outController,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      const outBanner = 'トップ100圏外のため、スコア記録には保存されませんでした。';
      expect(find.text(outBanner), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text(outBanner)).dy,
        lessThan(tester.getTopLeft(find.byType(ListView)).dy),
      );
      expect(find.text('-'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.textContaining('SampleHero24 '), findsOneWidget);
      expect(outController.offset, equals(outController.position.maxScrollExtent));

      // 0点未記録ケース
      final zeroEntries = buildSampleTopTenEntries(
        count: 25,
        currentIndices: {24},
        lastRankOverride: 0,
        lastScoreOverride: '0',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 460,
              child: TopTenWidget(
                entries: zeroEntries,
                isJp: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0点（最低点未満）のため、スコア記録には保存されませんでした。'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.textContaining('SampleHero24 '), findsOneWidget);
    });

    testWidgets('TextOverlay で自己記録上限(PERSMAX=10)未更新の2重ハイライト時は今回側を中心に配置し未記録バナーを表示すること', (tester) async {
      final lines = <String>[
        '',
        '前回の自己記録 1200 点を更新できなかった。',
        '',
        '順位      点数  名前                                                    HP[最大]',
      ];
      final attrs = <int>[0, 0, 0, 0];
      for (int rank = 1; rank <= 20; rank++) {
        lines.add('${rank.toString().padLeft(3)}  ${(3000 - rank * 100).toString().padLeft(9)}  PersHero 魔法使い/エルフ/男性/混沌 運命の大迷宮 $rank階でゴブリンに殺された - [30]');
        attrs.add(rank == 14 ? 1 : 0);
        if (rank == 14) {
          lines.add('          950  PersHero 魔法使い/エルフ/男性/混沌 運命の大迷宮 4階でコボルトに殺された - [25]');
          attrs.add(1);
        }
      }
      final tiles = List<int>.filled(lines.length, -1);
      final overlayKey = GlobalKey<TextOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Stack(
              children: [
                TextOverlay(
                  key: overlayKey,
                  textLines: lines,
                  textAttrs: attrs,
                  textTiles: tiles,
                  isPlainDialog: false,
                  tombstoneDisplayMode: 1,
                  onDismiss: () {},
                  onShowMsgHistory: () {},
                  bottomInset: 0,
                  useTiles: false,
                  tileImage: null,
                  tileWidth: 32,
                  tileHeight: 32,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('前回の自己記録 1200 点を更新できなかった。 今回のスコアはランキングに記録されませんでした。'),
        findsOneWidget,
      );
      expect(find.text('-'), findsOneWidget);
      final listRect = tester.getRect(find.byType(ListView));
      final targetText = find.textContaining('950 点');
      expect(targetText, findsOneWidget);
      final targetCard = find.ancestor(of: targetText, matching: find.byType(Card)).first;
      expect((tester.getCenter(targetCard).dy - listRect.center.dy).abs(), lessThanOrEqualTo(48.0));
    });

    testWidgets('NetHackScreen 経由でスクロール済み墓石から中位ランクインおよび100位圏外スコア一覧へ遷移した際も正しい位置へ自動スクロールすること', (tester) async {
      final screen = NetHackScreen();
      final overlayKey = GlobalKey<TextOverlayState>();
      late void Function(VoidCallback) hostSetState;

      screen.createWindow(20, NetHackScreen.nhwText);
      screen.putString(20, 0, '      REST');
      screen.putString(20, 0, '      IN');
      screen.putString(20, 0, '      PEACE');
      for (int i = 0; i < 30; i++) {
        screen.putString(20, 0, '開示行 $i');
      }
      screen.displayWindow(20, true);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                hostSetState = setState;
                return Stack(
                  children: [
                    if (screen.isTextWindowVisible)
                      TextOverlay(
                        key: overlayKey,
                        textLines: List<String>.unmodifiable(screen.textLines),
                        textAttrs: List<int>.unmodifiable(screen.textAttrs),
                        textTiles: List<int>.unmodifiable(screen.textTiles),
                        isPlainDialog: screen.isPlainDialog,
                        plainType: screen.plainType,
                        tombstoneDisplayMode: 1,
                        onDismiss: () {},
                        onShowMsgHistory: () {},
                        bottomInset: 0,
                        useTiles: false,
                        tileImage: null,
                        tileWidth: 32,
                        tileHeight: 32,
                        windowRevision: screen.textWindowRevision,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      overlayKey.currentState!.scrollController.jumpTo(140.0);
      await tester.pump();
      expect(overlayKey.currentState!.scrollController.offset, greaterThan(0.0));

      // 15位ランクイン画面へ遷移
      screen.destroyWindow(20);
      screen.createWindow(21, NetHackScreen.nhwText);
      screen.putString(21, 0, 'トップ100のうち 15 位に入った。');
      screen.putString(21, 0, '');
      screen.putString(21, 0, '順位      点数  名前                                                    HP[最大]');
      for (int rank = 1; rank <= 25; rank++) {
        screen.putString(
          21,
          rank == 15 ? 1 : 0,
          '${rank.toString().padLeft(3)}  ${(5000 - rank * 100).toString().padLeft(9)}  FlowMid$rank 魔法使い/エルフ/男性/混沌 運命の大迷宮 $rank階でゴブリンに殺された - [30]',
        );
      }
      screen.displayWindow(21, true);
      hostSetState(() {});
      await tester.pumpAndSettle();

      final listRect = tester.getRect(find.byType(ListView));
      final midFinder = find.textContaining('FlowMid15 ');
      expect(midFinder, findsOneWidget);
      final midCard = find.ancestor(of: midFinder, matching: find.byType(Card)).first;
      expect((tester.getCenter(midCard).dy - listRect.center.dy).abs(), lessThanOrEqualTo(48.0));

      // さらに100位圏外画面（末尾に rank=0 の今回スコア）へ遷移
      screen.destroyWindow(21);
      screen.createWindow(22, NetHackScreen.nhwText);
      screen.putString(22, 0, '');
      screen.putString(22, 0, '順位      点数  名前                                                    HP[最大]');
      for (int rank = 1; rank <= 24; rank++) {
        screen.putString(
          22,
          0,
          '${rank.toString().padLeft(3)}  ${(5000 - rank * 100).toString().padLeft(9)}  FlowTop$rank 魔法使い/エルフ/男性/混沌 運命の大迷宮 $rank階でゴブリンに殺された - [30]',
        );
      }
      screen.putString(
        22,
        1,
        '     ${50.toString().padLeft(9)}  FlowOut 魔法使い/エルフ/男性/混沌 運命の大迷宮 1階でコボルトに殺された - [20]',
      );
      screen.displayWindow(22, true);
      hostSetState(() {});
      await tester.pumpAndSettle();

      expect(find.text('トップ100圏外のため、スコア記録には保存されませんでした。'), findsOneWidget);
      expect(find.textContaining('FlowOut '), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      final controller = overlayKey.currentState!.scrollController;
      expect(controller.offset, equals(controller.position.maxScrollExtent));
    });
  });
}
