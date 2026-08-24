import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darthack/utils/defaults_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testFilePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('defaults_helper_test_');
    testFilePath = '${tempDir.path}/defaults.nh';
    SharedPreferences.setMockInitialValues({});
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

  test('SharedPreferences からの同期 (syncFromPrefsToFile) での空文字列削除検証', () async {
    final initialContent = 'OPTIONS=dogname:Rex\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    SharedPreferences.setMockInitialValues({
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

    SharedPreferences.setMockInitialValues({
      'nh_opt_hilite_status': false,
      'nh_opt_menucolor': false,
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    // 各行がコメントアウトされていることを確認
    expect(savedContent.contains('#OPTIONS=hilite_status:true') || savedContent.contains('# OPTIONS=hilite_status:true'), isTrue);
    expect(savedContent.contains('#MENUCOLOR=red=dragon') || savedContent.contains('# MENUCOLOR=red=dragon'), isTrue);

    // syncFromFileToPrefs を実行して SharedPreferences が false のまま維持されるか検証
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getBool('nh_opt_hilite_status'), isFalse);
    expect(prefs.getBool('nh_opt_menucolor'), isFalse);
  });

  test('tutorial_mode を「毎回確認 (0)」に変更・保存した際に「毎回確認」が維持されることの検証', () async {
    final initialContent = 'OPTIONS=tutorial\n';
    final file = File(testFilePath);
    await file.writeAsString(initialContent);

    SharedPreferences.setMockInitialValues({
      'nh_opt_tutorial_mode': 0, // 毎回確認 (ask)
    });

    final helper = DefaultsHelper();
    await helper.syncFromPrefsToFile(testFilePath);

    final savedContent = await file.readAsString();
    expect(savedContent.contains('OPTIONS=tutorial'), isFalse);

    // syncFromFileToPrefs を実行して 0 (ask) が維持されることを検証
    await helper.syncFromFileToPrefs(testFilePath);
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getInt('nh_opt_tutorial_mode'), equals(0));
  });
}
