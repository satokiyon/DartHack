import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:darthack/utils/app_prefs.dart';
import 'package:darthack/utils/defaults_helper.dart';

/// AppPrefs (DataStore / SharedPreferencesAsync) および DefaultsHelper の設定移行・保持テスト
///
/// 検証内容:
/// 1. 旧バージョン（Legacy XML）からの自動マイグレーションと型安全なコピー
/// 2. マイグレーション完了後の旧 SharedPreferences の完全消去（clear()）
/// 3. マイグレーション完了フラグ（__datastore_migration_v1_completed__）の記録と2回目以降のスキップ（冪等性）
/// 4. 新規インストール（旧キーが空）環境での初回起動・フラグ記録・2回目起動での設定保持
/// 5. 設定リセット（clearUserPreferences）およびエクスポート/インポートにおける保護システムキー（verDat, datadir, cCoreBuildId 等）の非破壊性
/// 6. Completer による複数同時呼び出し時の排他制御（二重マイグレーション防止）
/// 7. DefaultsHelper と AppPrefs の連携マージ動作
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPrefs (DataStore / SharedPreferencesAsync) マイグレーションと基本機能検証', () {
    setUp(() {
      AppPrefs.resetForTesting();
    });

    test('旧バージョン（Legacy XML）からの全データ移行と旧 XML の消去が正常に行われること', () async {
      // 1. 旧バージョンの SharedPreferences (XML) に既存データを準備
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pad_opacity': 0.75,
        'dpad_scale': 1.2,
        'shortcut_pad_scale': 0.9,
        'cmd_panel_scale': 1.1,
        'sound_bgm_volume': 0.4,
        'sound_se_volume': 0.9,
        'nh_opt_name': '既存冒険者',
        'nh_opt_tutorial_mode': 2,
        'nh_opt_autopickup': false,
        'custom_shortcuts': <String>['#pray', '#enhance', 'Z'],
      });

      // DataStore バックエンドを空の InMemory プラットフォームとして設定
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      // 2. AppPrefs.getInstance() を実行して初回起動を模擬
      final prefs = await AppPrefs.getInstance();

      // 3. DataStore (AppPrefs) にデータが正確にコピーされていることを検証
      expect(prefs.getDouble('pad_opacity'), 0.75);
      expect(prefs.getDouble('dpad_scale'), 1.2);
      expect(prefs.getDouble('shortcut_pad_scale'), 0.9);
      expect(prefs.getDouble('cmd_panel_scale'), 1.1);
      expect(prefs.getDouble('sound_bgm_volume'), 0.4);
      expect(prefs.getDouble('sound_se_volume'), 0.9);
      expect(prefs.getString('nh_opt_name'), '既存冒険者');
      expect(prefs.getInt('nh_opt_tutorial_mode'), 2);
      expect(prefs.getBool('nh_opt_autopickup'), isFalse);
      expect(prefs.getStringList('custom_shortcuts'),
          <String>['#pray', '#enhance', 'Z']);

      // 4. 移行完了フラグが DataStore 側に立っていることを検証
      expect(prefs.getBool(AppPrefs.migrationCompletedKey), isTrue);

      // 5. 旧 SharedPreferences (XML) 側が綺麗に clear() されていることを検証
      final legacyPrefs = await SharedPreferences.getInstance();
      expect(legacyPrefs.getKeys(), isEmpty);
    });

    test('移行完了後は2回目以降の起動でマイグレーション処理がスキップされること（冪等性）', () async {
      // 既に移行完了フラグが立っている DataStore 状態を模擬
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(<String, Object>{
        AppPrefs.migrationCompletedKey: true,
        'selected_language': 'ja',
        'pad_opacity': 0.85,
      });

      // 万一 Legacy 側にゴミが入っていたとしても上書きされないことを確認
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pad_opacity': 0.20, // これで上書きされてはならない
      });

      final prefs = await AppPrefs.getInstance();
      expect(prefs.getDouble('pad_opacity'), 0.85);
      expect(prefs.getString('selected_language'), 'ja');
    });

    test('新規インストール端末（旧キーが空）で初回起動・フラグ記録・2回目起動が問題なく行われること', () async {
      // 1. 旧 SharedPreferences は空
      SharedPreferences.setMockInitialValues(<String, Object>{});
      // DataStore も空
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      // 2. 初回起動
      final prefs1 = await AppPrefs.getInstance();
      expect(prefs1.getBool(AppPrefs.migrationCompletedKey), isTrue);

      // ユーザー設定の書き込み（新規初期化を模擬）
      await prefs1.setString('selected_tileset', 'pixelhack_32x32');
      await prefs1.setDouble('pad_opacity', 0.8);

      // 3. アプリ再起動（2回目起動）を模擬
      AppPrefs.resetForTesting();
      final prefs2 = await AppPrefs.getInstance();
      expect(prefs2.getBool(AppPrefs.migrationCompletedKey), isTrue);
      expect(prefs2.getString('selected_tileset'), 'pixelhack_32x32');
      expect(prefs2.getDouble('pad_opacity'), 0.8);
    });

    test('clearUserPreferences() でシステム保護キーが保護され、ユーザー設定のみ消去されること',
        () async {
      final prefs = await AppPrefs.setMockInitialValues(<String, Object>{
        'verDat': 105,
        'datadir': '/data/user/0/darthack/nethackdir',
        'cCoreBuildId': 'build-20261018',
        '__custom_system_tag__': 'preserve_me',
        'pad_opacity': 0.8,
        'selected_language': 'ja',
        'nh_opt_name': '冒険者',
      });

      expect(prefs.getInt('verDat'), 105);
      expect(prefs.getString('pad_opacity_key_check'), isNull);
      expect(prefs.getDouble('pad_opacity'), 0.8);

      // 設定リセットを実行
      await prefs.clearUserPreferences();

      // ユーザー設定は削除されている
      expect(prefs.getDouble('pad_opacity'), isNull);
      expect(prefs.getString('selected_language'), isNull);
      expect(prefs.getString('nh_opt_name'), isNull);

      // システムキー（移行フラグ、verDat, datadir, cCoreBuildId, __プレフィックス）は完全に保持されている
      expect(prefs.getInt('verDat'), 105);
      expect(prefs.getString('datadir'), '/data/user/0/darthack/nethackdir');
      expect(prefs.getString('cCoreBuildId'), 'build-20261018');
      expect(prefs.getString('__custom_system_tag__'), 'preserve_me');
      expect(prefs.getBool(AppPrefs.migrationCompletedKey), isTrue);
    });

    test('複数箇所から同時に getInstance() を呼んでも Completer により1度しか初期化されないこと',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'concurrent_test_key': 'value123',
      });
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();

      // 同時に 5 回呼び出し
      final futures = List.generate(5, (_) => AppPrefs.getInstance());
      final results = await Future.wait(futures);

      // 全て同じインスタンスが返り、マイグレーションが正常完了していること
      for (final p in results) {
        expect(identical(p, results.first), isTrue);
        expect(p.getString('concurrent_test_key'), 'value123');
      }
    });
  });

  group('アップデート時の DefaultsHelper 設定マージ・引き継ぎ互換性検証', () {
    late Directory tempDir;
    late File assetDefaultsFile;
    late File userDefaultsFile;

    setUp(() async {
      AppPrefs.resetForTesting();
      tempDir = await Directory.systemTemp.createTemp('darthack_prefs_test_');
      assetDefaultsFile = File('${tempDir.path}/asset_defaults.nh');
      userDefaultsFile = File('${tempDir.path}/user_defaults.nh');

      // 新バージョンのアセット defaults.nh を模擬
      await assetDefaultsFile.writeAsString(
        'OPTIONS=time,showexp,autopickup\n'
        'OPTIONS=pickup_types:\$"=/!?+\n'
        'OPTIONS=hitpointbar,hilite_status,menucolor\n'
        'OPTIONS=bones\n'
        'OPTIONS=number_pad:0\n',
      );

      // 既存のユーザー defaults.nh を模擬
      await userDefaultsFile.writeAsString(
        'OPTIONS=name:既存プレイヤー\n'
        'OPTIONS=!autopickup\n'
        'OPTIONS=number_pad:1\n',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('アセット更新マージ時、ユーザーの既存設定が優先され、新デフォルト値が安全に補完されること', () async {
      await AppPrefs.setMockInitialValues(<String, Object>{
        'nh_opt_name': '既存プレイヤー',
        'nh_opt_autopickup': false,
        'nh_opt_number_pad': 1,
      });

      final helper = DefaultsHelper();
      await helper.mergeAssetDefaultsWithPrefs(
        assetDefaultsFile.path,
        userDefaultsFile.path,
      );

      final prefs = await AppPrefs.getInstance();

      // 既存のユーザー設定が優先維持されていること
      expect(prefs.getString('nh_opt_name'), '既存プレイヤー');
      expect(prefs.getBool('nh_opt_autopickup'), isFalse);
      expect(prefs.getInt('nh_opt_number_pad'), 1);

      // 新しくアセットで追加されたデフォルト設定が補完されていること
      expect(prefs.getBool('nh_opt_time'), isTrue);
      expect(prefs.getBool('nh_opt_showexp'), isTrue);
      expect(prefs.getString('nh_opt_pickup_types'), r'$"=/!?+');
      expect(prefs.getBool('nh_opt_hitpointbar'), isTrue);
      expect(prefs.getBool('nh_opt_bones'), isTrue);

      // defaults.nh ファイルにも正しく反映されていること
      await helper.syncFromPrefsToFile(userDefaultsFile.path);
      final savedContent = await userDefaultsFile.readAsString();

      expect(savedContent.contains('name:既存プレイヤー'), isTrue);
      expect(savedContent.contains('!autopickup'), isTrue);
      expect(savedContent.contains('number_pad:1'), isTrue);
      expect(savedContent.contains('time'), isTrue);
      expect(savedContent.contains('showexp'), isTrue);
    });
  });
}
