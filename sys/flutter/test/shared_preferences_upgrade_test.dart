import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darthack/utils/defaults_helper.dart';

/// SharedPreferences 2.5.6（レガシー API ラッパー）および DefaultsHelper の設定引き継ぎ・互換性テスト
///
/// 【検証範囲に関する注記】
/// `SharedPreferences.setMockInitialValues` はメモリ上のモックストア（InMemorySharedPreferencesStore）を
/// 使用するため、Android の Pigeon JNI 層（`shared_preferences_android 2.5.0`）や iOS の Pigeon FFI 層
/// （`shared_preferences_foundation 2.6.0`）のネイティブ通信自体は通過しない。
/// ネイティブ層の保存形式互換（`FlutterSharedPreferences` XML、DOUBLE_PREFIX、LIST_PREFIX 等）は
/// パッケージソースコードの直接検査および実機の上書きインストール試験で担保し、
/// 本テストでは以下を検証する：
/// 1. Dart 側の `SharedPreferences.getInstance()` における各型（特に DartHack が多用する `double` / `int` / `bool` / `String` / `List<String>`）の契約維持
/// 2. アップデート時に実行される `DefaultsHelper.mergeAssetDefaultsWithPrefs` および双方向同期において、
///    既存ユーザーの設定値が失われず `defaults.nh` に正しく引き継がれること
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferences Dart層 API および DartHack 設定キーの読み書き検証', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pad_opacity': 0.75,
        'dpad_scale': 1.2,
        'shortcut_pad_scale': 0.9,
        'cmd_panel_scale': 1.1,
        'msg_opacity': 0.65,
        'msg_font_size': 15.0,
        'sound_bgm_volume': 0.4,
        'sound_se_volume': 0.9,
        'sound_ambience_volume': 0.5,
        'nh_opt_name': 'テスト冒険者',
        'nh_opt_tutorial_mode': 2,
        'nh_opt_autopickup': false,
        'custom_shortcuts': <String>['#pray', '#enhance', 'Z'],
      });
    });

    test('DartHack の既存設定キー（double / int / bool / String / List<String>）が正確に取得・更新できること', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getDouble('pad_opacity'), 0.75);
      expect(prefs.getDouble('dpad_scale'), 1.2);
      expect(prefs.getDouble('sound_bgm_volume'), 0.4);
      expect(prefs.getString('nh_opt_name'), 'テスト冒険者');
      expect(prefs.getInt('nh_opt_tutorial_mode'), 2);
      expect(prefs.getBool('nh_opt_autopickup'), isFalse);
      expect(prefs.getStringList('custom_shortcuts'), <String>['#pray', '#enhance', 'Z']);

      // 値の更新と再取得
      await prefs.setDouble('pad_opacity', 0.5);
      await prefs.setStringList('custom_shortcuts', <String>['#loot', 's']);
      expect(prefs.getDouble('pad_opacity'), 0.5);
      expect(prefs.getStringList('custom_shortcuts'), <String>['#loot', 's']);
    });

    test('remove()・clear()・reload() が正常に動作すること', () async {
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.containsKey('nh_opt_name'), isTrue);
      await prefs.remove('nh_opt_name');
      expect(prefs.containsKey('nh_opt_name'), isFalse);
      expect(prefs.getString('nh_opt_name'), isNull);

      await expectLater(prefs.reload(), completes);

      await prefs.clear();
      expect(prefs.getKeys(), isEmpty);
    });
  });

  group('アップデート時の DefaultsHelper 設定マージ・引き継ぎ互換性検証', () {
    late Directory tempDir;
    late File assetDefaultsFile;
    late File userDefaultsFile;

    setUp(() async {
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

    test('mergeAssetDefaultsWithPrefs 実行時に既存ユーザーの SharedPreferences 設定が維持され、廃止キーのみ削除されること', () async {
      // 旧バージョンで保存されていたユーザー設定と廃止キーを模擬
      SharedPreferences.setMockInitialValues(<String, Object>{
        'nh_opt_name': '既存プレイヤー',
        'nh_opt_dogname': 'ポチ',
        'nh_opt_autopickup': false,
        'nh_opt_tutorial_mode': 2, // 常に通常プレイ
        'nh_opt_number_pad': 1,
        'nh_opt_old_unused_key': true, // 廃止キー
      });

      final helper = DefaultsHelper();
      await helper.mergeAssetDefaultsWithPrefs(
        assetDefaultsFile.path,
        userDefaultsFile.path,
      );

      final prefs = await SharedPreferences.getInstance();

      // 廃止キーは削除されていること
      expect(prefs.containsKey('nh_opt_old_unused_key'), isFalse);

      // 既存のユーザー設定が上書きされずに保持されていること
      expect(prefs.getString('nh_opt_name'), '既存プレイヤー');
      expect(prefs.getString('nh_opt_dogname'), 'ポチ');
      expect(prefs.getBool('nh_opt_autopickup'), isFalse);
      expect(prefs.getInt('nh_opt_tutorial_mode'), 2);
      expect(prefs.getInt('nh_opt_number_pad'), 1);

      // 未設定だった新規キーはアセットのデフォルト値で補完されていること
      expect(prefs.getBool('nh_opt_time'), isTrue);
      expect(prefs.getBool('nh_opt_showexp'), isTrue);
      expect(prefs.getBool('nh_opt_hitpointbar'), isTrue);

      // 出力された defaults.nh ファイルにもユーザー設定が正しく書き出されていること
      final savedContent = await userDefaultsFile.readAsString();
      expect(savedContent, contains('name:既存プレイヤー'));
      expect(savedContent, contains('dogname:ポチ'));
      expect(savedContent, contains('!autopickup'));
      expect(savedContent, contains('number_pad:1'));
    });
  });
}
