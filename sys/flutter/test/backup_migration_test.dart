import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:darthack/models/tileset_info.dart';
import 'package:darthack/models/topten_entry.dart';
import 'package:darthack/nethack_assets.dart';
import 'package:darthack/services/tileset_manager.dart';
import 'package:darthack/utils/app_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google バックアップ・リストア時のマイグレーション・堅牢性検証', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('darthack_backup_test_');
      AppPrefs.resetForTesting();
      TilesetManager.instance.resetForTesting();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('旧バージョン直下の一時レベルファイルを現行UID移動・別UID削除し、骨やログは完全保護すること', () async {
      final nethackDir = Directory('${tempDir.path}/nethackdir')..createSync();
      final levelsDir = Directory('${nethackDir.path}/levels')..createSync();

      // 現行 UID (10470) の進行中レベルファイル
      File('${nethackDir.path}/10470Hero.0').writeAsStringSync('lvl0');
      File('${nethackDir.path}/10470Hero.1').writeAsStringSync('lvl1');

      // 別 UID (10301) の残骸レベルファイル（リストア等による孤立データ）
      File('${nethackDir.path}/10301OldHero.0').writeAsStringSync('old0');
      File('${nethackDir.path}/10301OldHero.2').writeAsStringSync('old2');

      // 保護されるべきファイル群（骨・スコア・ログ・設定・dumplogs）
      File('${nethackDir.path}/bonD0.1').writeAsStringSync('bones');
      File('${nethackDir.path}/bonM0.2').writeAsStringSync('bones2');
      File('${nethackDir.path}/record').writeAsStringSync('100 Hero');
      File('${nethackDir.path}/logfile').writeAsStringSync('log');
      File('${nethackDir.path}/xlogfile').writeAsStringSync('xlog');
      File('${nethackDir.path}/livelog').writeAsStringSync('livelog');
      File('${nethackDir.path}/defaults.nh').writeAsStringSync('OPTIONS=time');
      File('${nethackDir.path}/perm').writeAsStringSync('');
      final dumplogsDir = Directory('${nethackDir.path}/dumplogs')..createSync();
      File('${dumplogsDir.path}/dump_1000_2000.txt').writeAsStringSync('dumplog');

      await NetHackAssets.migrateLegacyLevelFilesForTesting(
        nethackDir,
        levelsDir,
        currentUidOverride: 10470,
      );

      // 現行 UID のレベルファイルは levels/ へ移動済み
      expect(File('${nethackDir.path}/10470Hero.0').existsSync(), isFalse);
      expect(File('${nethackDir.path}/10470Hero.1').existsSync(), isFalse);
      expect(File('${levelsDir.path}/10470Hero.0').existsSync(), isTrue);
      expect(File('${levelsDir.path}/10470Hero.1').existsSync(), isTrue);

      // 別 UID の残骸は削除済み
      expect(File('${nethackDir.path}/10301OldHero.0').existsSync(), isFalse);
      expect(File('${nethackDir.path}/10301OldHero.2').existsSync(), isFalse);
      expect(File('${levelsDir.path}/10301OldHero.0').existsSync(), isFalse);

      // 骨・スコア・ログ・設定はすべて直下にそのまま保護されている
      expect(File('${nethackDir.path}/bonD0.1').existsSync(), isTrue);
      expect(File('${nethackDir.path}/bonM0.2').existsSync(), isTrue);
      expect(File('${nethackDir.path}/record').existsSync(), isTrue);
      expect(File('${nethackDir.path}/logfile').existsSync(), isTrue);
      expect(File('${nethackDir.path}/xlogfile').existsSync(), isTrue);
      expect(File('${nethackDir.path}/livelog').existsSync(), isTrue);
      expect(File('${nethackDir.path}/defaults.nh').existsSync(), isTrue);
      expect(File('${nethackDir.path}/perm').existsSync(), isTrue);
      expect(File('${dumplogsDir.path}/dump_1000_2000.txt').existsSync(), isTrue);
    });

    test('端末移行等でカスタムタイルの絶対パスが変わってもファイル名ベースで自動修復されること', () async {
      final newCustomTilesDir = Directory('${tempDir.path}/custom_tiles')..createSync();
      final actualFile = File('${newCustomTilesDir.path}/custom_12345_my_tiles.png');
      actualFile.writeAsBytesSync(<int>[0, 1, 2, 3]);

      final oldInfo = TilesetInfo(
        id: 'custom_12345_my_tiles',
        displayName: 'My Custom Tiles',
        tileWidth: 32,
        tileHeight: 32,
        author: 'User',
        url: '/data/user/0/old.pkg/app_flutter/custom_tiles/custom_12345_my_tiles.png',
        assetPath: '',
        isBuiltIn: false,
        localFilePath: '/data/user/0/old.pkg/app_flutter/custom_tiles/custom_12345_my_tiles.png',
        isTransparent: true,
      );

      SharedPreferences.setMockInitialValues(<String, Object>{});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(<String, Object>{
        AppPrefs.migrationCompletedKey: true,
        TilesetManager.prefCustomTilesetsJson: jsonEncode([oldInfo.toJson()]),
      });

      await TilesetManager.instance.init(customTilesDir: newCustomTilesDir);

      final loaded = TilesetManager.instance.customTilesets;
      expect(loaded.length, 1);
      expect(loaded.first.id, 'custom_12345_my_tiles');
      expect(loaded.first.localFilePath, actualFile.path);
      expect(loaded.first.isTransparent, isTrue);

      // Prefs 側も新しいパスで自動更新されていることを確認
      final prefs = await AppPrefs.getInstance();
      final savedJson = prefs.getString(TilesetManager.prefCustomTilesetsJson)!;
      final savedList = jsonDecode(savedJson) as List<dynamic>;
      expect(savedList.first['localFilePath'], actualFile.path);
    });

    test('findRecordFilePath が指定した basePath 配下の record を最優先で検知すること', () {
      final nethackDir = Directory('${tempDir.path}/nethackdir')..createSync();
      final recordFile = File('${nethackDir.path}/record');
      recordFile.writeAsStringSync('5.0.0 1000 1 1 1 0 10 10 20261111 20261111 10470 Wiz Hum Mal Cha Hero,killed by a newt\n');

      final found = findRecordFilePath(nethackDir.path);
      expect(found, '${nethackDir.path}/record');
    });

    test('Android Auto Backup 設定で nethackdir/dumplogs がクラウドバックアップ対象に含まれていること', () {
      final backupRulesFile = File('android/app/src/main/res/xml/backup_rules.xml');
      final extractionRulesFile = File('android/app/src/main/res/xml/data_extraction_rules.xml');

      expect(backupRulesFile.existsSync(), isTrue);
      expect(extractionRulesFile.existsSync(), isTrue);

      final backupXml = backupRulesFile.readAsStringSync();
      expect(backupXml, contains('<include domain="file" path="nethackdir"'));
      expect(backupXml, contains('<exclude domain="file" path="nethackdir/save"'));
      expect(backupXml, contains('<exclude domain="file" path="nethackdir/levels"'));
      expect(backupXml, isNot(contains('dumplogs')));

      final extractionXml = extractionRulesFile.readAsStringSync();
      final cloudMatch = RegExp(r'<cloud-backup>([\s\S]*?)</cloud-backup>').firstMatch(extractionXml);
      final transferMatch = RegExp(r'<device-transfer>([\s\S]*?)</device-transfer>').firstMatch(extractionXml);
      expect(cloudMatch, isNotNull);
      expect(transferMatch, isNotNull);

      final cloudBlock = cloudMatch!.group(1)!;
      expect(cloudBlock, contains('<include domain="file" path="nethackdir"'));
      expect(cloudBlock, contains('<exclude domain="file" path="nethackdir/save"'));
      expect(cloudBlock, contains('<exclude domain="file" path="nethackdir/levels"'));
      expect(cloudBlock, isNot(contains('dumplogs')));

      final transferBlock = transferMatch!.group(1)!;
      expect(transferBlock, contains('<include domain="file" path="nethackdir"'));
      expect(transferBlock, isNot(contains('dumplogs')));
    });
  });
}
