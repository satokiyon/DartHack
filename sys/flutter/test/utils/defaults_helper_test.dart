import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/utils/defaults_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testFilePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('defaults_helper_test_');
    testFilePath = '${tempDir.path}/defaults.nh';
    await AppPrefs.setMockInitialValues({});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('文字列オプションの削除および saveToFile でのトークン除去検証', () async {
    final initialContent = '''
# NetHack options file
OPTIONS=name:satok, dogname:Fido, catname:Tama, horsename:Silver, fruit:orange
OPTIONS=autopickup, number_pad:1
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    final helper = DefaultsHelper();
    await helper.loadFromFile(testFilePath);

    expect(helper.getOption('name'), equals('satok'));
    expect(helper.getOption('dogname'), equals('Fido'));
    expect(helper.getOption('catname'), equals('Tama'));

    // dogname と fruit を空文字列（削除）に設定
    helper.setOption('dogname', '');
    helper.setOption('fruit', '');

    await helper.saveToFile(testFilePath);

    final savedContent = await file.readAsString();

    // 削除したオプションのトークンがファイルから除去されていることを検証
    expect(savedContent.contains('dogname:Fido'), isFalse);
    expect(savedContent.contains('dogname:'), isFalse);
    expect(savedContent.contains('fruit:orange'), isFalse);
    expect(savedContent.contains('fruit:'), isFalse);

    // 削除していないオプションは残っていることを検証
    expect(savedContent.contains('name:satok'), isTrue);
    expect(savedContent.contains('catname:Tama'), isTrue);
    expect(savedContent.contains('horsename:Silver'), isTrue);
    expect(savedContent.contains('autopickup'), isTrue);

    // 再ロードして検証
    final reloadHelper = DefaultsHelper();
    await reloadHelper.loadFromFile(testFilePath);

    expect(reloadHelper.getOption('dogname'), isNull);
    expect(reloadHelper.getOption('fruit'), isNull);
    expect(reloadHelper.getOption('name'), equals('satok'));
  });

  test('AppPrefs からの同期 (syncFromPrefsToFile) での空文字列削除検証', () async {
    final initialContent = 'OPTIONS=dogname:Rex\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({
      'nh_opt_dogname': '',
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    expect(savedContent.contains('dogname'), isFalse);
  });

  test('hilite_status および menucolor を OFF に変更・保存した際に OFF が維持されることの検証', () async {
    final initialContent = '''
OPTIONS=hilite_status:true
MENUCOLOR=red=dragon
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({
      'nh_opt_hilite_status': false,
      'nh_opt_menucolor': false,
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    // 各行がコメントアウトされていることを確認
    expect(savedContent.contains('#OPTIONS=hilite_status:true') || savedContent.contains('# OPTIONS=hilite_status:true'), isTrue);
    expect(savedContent.contains('#MENUCOLOR=red=dragon') || savedContent.contains('# MENUCOLOR=red=dragon'), isTrue);

    // syncFromFileToPrefs を実行して AppPrefs が false のまま維持されるか検証
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    expect(prefs.getBool('nh_opt_hilite_status'), isFalse);
    expect(prefs.getBool('nh_opt_menucolor'), isFalse);
  });

  test('tutorial_mode を「毎回確認 (0)」に変更・保存した際に「毎回確認」が維持されることの検証', () async {
    final initialContent = 'OPTIONS=tutorial\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({
      'nh_opt_tutorial_mode': 0, // 毎回確認 (ask)
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=tutorial'), isFalse);

    // syncFromFileToPrefs を実行して 0 (ask) が維持されることを検証
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    expect(prefs.getInt('nh_opt_tutorial_mode'), equals(0));
  });

  test('autopickup のデフォルト有効 (true) および未設定時のフォールバック検証', () async {
    final initialContent = 'OPTIONS=autopickup\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({});

    final helper = DefaultsHelper();
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    // defaults.nh に OPTIONS=autopickup がある場合は true
    expect(prefs.getBool('nh_opt_autopickup'), isTrue);

    // defaults.nh に autopickup が記述されていない場合でも未設定時は true が補完される
    await file.writeAsString('OPTIONS=number_pad:0\n');
    await AppPrefs.setMockInitialValues({});
    await helper.syncFromFileToPrefs(testFilePath);
    final prefsAfterEmpty = await AppPrefs.getInstance();
    expect(prefsAfterEmpty.getBool('nh_opt_autopickup'), isTrue);
  });

  test('autopickup を OFF に変更・保存した際に OFF が維持されることの検証', () async {
    final initialContent = 'OPTIONS=autopickup\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({
      'nh_opt_autopickup': false,
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=!autopickup'), isTrue);

    // syncFromFileToPrefs で再読み込みしても false が維持される
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();
    expect(prefs.getBool('nh_opt_autopickup'), isFalse);
  });

  test('ハードモードオプションのデフォルト値（未指定時はすべてOFF・通常プレイ）の検証', () async {
    final initialContent = 'OPTIONS=autopickup\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({});

    final helper = DefaultsHelper();
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    expect(prefs.getBool('nh_opt_blind'), isFalse);
    expect(prefs.getBool('nh_opt_nudist'), isFalse);
    expect(prefs.getBool('nh_opt_deaf'), isFalse);
    expect(prefs.getBool('nh_opt_pauper'), isFalse);
    expect(prefs.getBool('nh_opt_bones'), isTrue); // bones許可（禁止ではない）
  });

  test('defaults.nh からのハードモードオプションのパース検証', () async {
    final initialContent = '''
OPTIONS=blind, nudist, deaf, pauper
OPTIONS=!bones
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({});

    final helper = DefaultsHelper();
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    expect(prefs.getBool('nh_opt_blind'), isTrue);
    expect(prefs.getBool('nh_opt_nudist'), isTrue);
    expect(prefs.getBool('nh_opt_deaf'), isTrue);
    expect(prefs.getBool('nh_opt_pauper'), isTrue);
    expect(prefs.getBool('nh_opt_bones'), isFalse); // !bones -> bones=false
  });

  test('AppPrefs から defaults.nh へのハードモード保存と初期化リセットの検証', () async {
    final initialContent = 'OPTIONS=autopickup\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    // 1. ハードモードを有効化して保存
    await AppPrefs.setMockInitialValues({
      'nh_opt_blind': true,
      'nh_opt_nudist': true,
      'nh_opt_deaf': true,
      'nh_opt_pauper': true,
      'nh_opt_bones': false, // 骨塚禁止
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    var savedContent = await file.readAsString();
    expect(savedContent.contains('blind'), isTrue);
    expect(savedContent.contains('nudist'), isTrue);
    expect(savedContent.contains('deaf'), isTrue);
    expect(savedContent.contains('pauper'), isTrue);
    expect(savedContent.contains('!bones'), isTrue);

    // 2. リセット（すべて通常プレイに戻す）
    final prefs = await AppPrefs.getInstance();
    await prefs.setBool('nh_opt_blind', false);
    await prefs.setBool('nh_opt_nudist', false);
    await prefs.setBool('nh_opt_deaf', false);
    await prefs.setBool('nh_opt_pauper', false);
    await prefs.setBool('nh_opt_bones', true);

    await helper.syncFromPrefsToFile(testFilePath);

    savedContent = await file.readAsString();
    expect(savedContent.contains('!blind'), isTrue);
    expect(savedContent.contains('!nudist'), isTrue);
    expect(savedContent.contains('!deaf'), isTrue);
    expect(savedContent.contains('!pauper'), isTrue);
    expect(savedContent.contains('bones') && !savedContent.contains('!bones'), isTrue);
  });

  test('OPTIONS=symset:IBMGraphics_2,runmode:walk の複合行における symset インプレース更新と runmode:walk 保護の検証', () async {
    final initialContent = '''
OPTIONS=lit_corridor,showexp,time,toptenwin
OPTIONS=pile_limit:2,hilite_pile,hilite_pet
OPTIONS=symset:IBMGraphics_2,runmode:walk
OPTIONS=boulder:0
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    // 1. ロードして symset がパースされていることを確認
    final helper = DefaultsHelper();
    await helper.loadFromFile(testFilePath);
    expect(helper.getOption('symset'), equals('IBMGraphics_2'));

    // 2. symset を Enhanced1 に変更して保存
    helper.setOption('symset', 'Enhanced1');
    await helper.saveToFile(testFilePath);

    final savedContent = await file.readAsString();

    // symset が Enhanced1 に更新され、runmode:walk がそのまま同一行に残っていることを検証
    expect(savedContent.contains('symset:Enhanced1'), isTrue);
    expect(savedContent.contains('runmode:walk'), isTrue);
    expect(savedContent.contains('symset:IBMGraphics_2'), isFalse);
    expect(savedContent.contains('OPTIONS=symset:Enhanced1, runmode:walk'), isTrue);

    // 他の行も健全に維持されていることを確認
    expect(savedContent.contains('OPTIONS=boulder:0'), isTrue);
  });

  test('OPTIONS=roguesymset の保存および defaults.nh 反映の検証 (重複出力防止)', () async {
    final initialContent = 'OPTIONS=symset:IBMGraphics_2\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    final helper = DefaultsHelper();
    await helper.loadFromFile(testFilePath);
    helper.setOption('roguesymset', 'RogueIBM');
    await helper.saveToFile(testFilePath);

    var savedContent = await file.readAsString();
    expect(savedContent.contains('roguesymset:RogueIBM'), isTrue);
    // 重複出力 (compound option specified multiple times: roguesymset) が起きていないこと（出現回数1回）
    final matches = RegExp(r'roguesymset:').allMatches(savedContent);
    expect(matches.length, equals(1));

    // さらに再度読み込んで連続保存しても重複が増殖しないことを検証
    final reloadHelper = DefaultsHelper();
    await reloadHelper.loadFromFile(testFilePath);
    expect(reloadHelper.getOption('roguesymset'), equals('RogueIBM'));
    await reloadHelper.saveToFile(testFilePath);

    savedContent = await file.readAsString();
    final matchesAfterSecondSave = RegExp(r'roguesymset:').allMatches(savedContent);
    expect(matchesAfterSecondSave.length, equals(1));
  });

  test('レガシー記法 OPTIONS=DECgraphics / IBMgraphics のパースと正規化保存の検証', () async {
    final initialContent = 'OPTIONS=DECgraphics,autopickup\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    final helper = DefaultsHelper();
    await helper.loadFromFile(testFilePath);
    expect(helper.getOption('symset'), equals('DECgraphics'));

    // 新しい symset:Enhanced2 に更新して保存
    helper.setOption('symset', 'Enhanced2');
    await helper.saveToFile(testFilePath);

    final savedContent = await file.readAsString();
    expect(savedContent.contains('symset:Enhanced2'), isTrue);
    expect(savedContent.contains('DECgraphics'), isFalse);
    expect(savedContent.contains('autopickup'), isTrue);
  });

  test('mergeAssetDefaultsWithPrefs における symset / roguesymset の文字列型保護マイグレーション検証', () async {
    final assetFilePath = '${tempDir.path}/asset_defaults.nh';
    final assetFile = File(assetFilePath);
    await assetFile.writeAsString('''
OPTIONS=symset:IBMGraphics_2,runmode:walk
OPTIONS=roguesymset:RogueEpyx
''');

    final targetFile = File(testFilePath);
    await targetFile.writeAsString('''
OPTIONS=name:MyHero
OPTIONS=symset:Enhanced1,runmode:walk
''');

    await AppPrefs.setMockInitialValues({
      'nh_opt_symset': 'Enhanced1',
    });

    final helper = DefaultsHelper();
    await helper.mergeAssetDefaultsWithPrefs(assetFilePath, testFilePath);

    final prefs = await AppPrefs.getInstance();
    // 既存設定が文字列型として維持され、bool に化けていないこと
    expect(prefs.getString('nh_opt_symset'), equals('Enhanced1'));
    // アセットの新規キー roguesymset が文字列型として補完されていること
    expect(prefs.getString('nh_opt_roguesymset'), equals('RogueEpyx'));

    // ターゲットファイルの複合行が壊れずに維持されていること
    final savedContent = await targetFile.readAsString();
    expect(savedContent.contains('symset:Enhanced1'), isTrue);
    expect(savedContent.contains('runmode:walk'), isTrue);
  });

  test('無効な roguesymset (RogueUnicode 等) が Default に安全にサニタイズ・修復されることの検証', () async {
    final initialContent = '''
OPTIONS=name:satok
OPTIONS=roguesymset:RogueUnicode
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({
      'nh_opt_roguesymset': 'RogueUnicode',
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    // RogueUnicode が消去され、安全な Default に修復されていること
    expect(savedContent.contains('RogueUnicode'), isFalse);
    expect(savedContent.contains('roguesymset:Default'), isTrue);

    // AppPrefs 側も Default に修復されていること
    final prefs = await AppPrefs.getInstance();
    expect(prefs.getString('nh_opt_roguesymset'), equals('Default'));
  });

  test('OPTIONS=runmode のパース、AppPrefs同期、および複合行でのインプレース更新の検証', () async {
    final initialContent = '''
OPTIONS=symset:IBMGraphics_2,runmode:walk
OPTIONS=boulder:0
''';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    await AppPrefs.setMockInitialValues({});

    final helper = DefaultsHelper();
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await AppPrefs.getInstance();

    // 1. defaults.nh から walk が読み込まれること
    expect(prefs.getString('nh_opt_runmode'), equals('walk'));

    // 2. run に変更して defaults.nh に反映
    await prefs.setString('nh_opt_runmode', 'run');
    await helper.syncFromPrefsToFile(testFilePath);

    var savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=symset:IBMGraphics_2, runmode:run'), isTrue);
    expect(savedContent.contains('runmode:walk'), isFalse);

    // 3. teleport に変更
    await prefs.setString('nh_opt_runmode', 'teleport');
    await helper.syncFromPrefsToFile(testFilePath);

    savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=symset:IBMGraphics_2, runmode:teleport'), isTrue);

    // 4. 不正な値が入った場合のサニタイズ（walk へのフォールバック）
    await prefs.setString('nh_opt_runmode', 'invalid_mode');
    await helper.syncFromPrefsToFile(testFilePath);

    savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=symset:IBMGraphics_2, runmode:walk'), isTrue);
    expect(prefs.getString('nh_opt_runmode'), equals('walk'));
  });
}
