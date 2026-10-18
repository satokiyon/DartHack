import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// SharedPreferencesWithCache (内部は SharedPreferencesAsync / Jetpack DataStore) を
/// ラップしたシングルトンクラス。
///
/// 旧バージョン（Legacy SharedPreferences XML）から新バージョン（DataStore）への
/// 初回自動マイグレーション、旧 XML の完全クリア、内部システムキーの保護、
/// およびテスト用のモック差し替え機能を提供します。
class AppPrefs {
  /// DataStore への移行完了を示す内部フラグのキー名
  static const String migrationCompletedKey =
      '__datastore_migration_v1_completed__';

  /// 設定リセットや JSON エクスポート/インポートから除外すべき保護システムキー一覧
  static const Set<String> _knownSystemKeys = {
    migrationCompletedKey,
    'verDat',
    'datadir',
    'cCoreBuildId',
  };

  static AppPrefs? _instance;
  static Completer<AppPrefs>? _initCompleter;

  final SharedPreferencesWithCache _prefs;

  AppPrefs._(this._prefs);

  /// 指定されたキーが内部システムキー（リセットやエクスポートから除外すべきキー）かどうかを判定します。
  /// '__' で始まるキー、または既知の管理キー（verDat 等）をシステムキーとして保護します。
  static bool isSystemKey(String key) {
    return key.startsWith('__') || _knownSystemKeys.contains(key);
  }

  /// AppPrefs のシングルトンインスタンスを取得します。
  /// 初回呼び出し時に必要に応じて旧 XML からの自動マイグレーションを実行します。
  static Future<AppPrefs> getInstance() async {
    if (_instance != null) {
      return _instance!;
    }
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    final completer = Completer<AppPrefs>();
    _initCompleter = completer;

    try {
      final asyncPrefs = SharedPreferencesAsync();

      // 初回マイグレーション判定（DataStore に完了フラグが立っているか確認）
      final isMigrated =
          await asyncPrefs.getBool(migrationCompletedKey) ?? false;
      if (!isMigrated) {
        await _migrateFromLegacy(asyncPrefs);
      }

      // キャッシュ付きラッパーを生成（全キーを起動時にメモリキャッシュへ一括ロード）
      final withCache = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );

      _instance = AppPrefs._(withCache);
      completer.complete(_instance!);
      return _instance!;
    } catch (e, st) {
      completer.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  /// 旧 SharedPreferences（XML）から DataStore（SharedPreferencesAsync）へのマイグレーション処理
  static Future<void> _migrateFromLegacy(
      SharedPreferencesAsync asyncPrefs) async {
    try {
      final legacyPrefs = await SharedPreferences.getInstance();
      final legacyKeys = legacyPrefs.getKeys();

      if (legacyKeys.isNotEmpty) {
        debugPrint(
            '[AppPrefs] Migrating ${legacyKeys.length} keys from legacy SharedPreferences to DataStore...');
        for (final key in legacyKeys) {
          final value = legacyPrefs.get(key);
          if (value is bool) {
            await asyncPrefs.setBool(key, value);
          } else if (value is int) {
            await asyncPrefs.setInt(key, value);
          } else if (value is double) {
            await asyncPrefs.setDouble(key, value);
          } else if (value is String) {
            await asyncPrefs.setString(key, value);
          } else if (value is List<String>) {
            await asyncPrefs.setStringList(key, value);
          }
        }
      }

      // DataStore への全データ永続化が成功した直後に完了フラグを書き込む
      await asyncPrefs.setBool(migrationCompletedKey, true);
      debugPrint('[AppPrefs] Migration completed successfully.');

      // 例外安全: コピーと完了フラグの保存が両方成功した直後のみ旧 XML を消去
      try {
        await legacyPrefs.clear();
        debugPrint(
            '[AppPrefs] Legacy SharedPreferences XML cleared successfully.');
      } catch (clearErr) {
        debugPrint(
            '[AppPrefs] Warning: Failed to clear legacy SharedPreferences XML: $clearErr');
      }
    } catch (e) {
      debugPrint('[AppPrefs] Error during migration from legacy: $e');
      // マイグレーションが途中で失敗した場合は完了フラグを立てず、次回起動時に再試行できるようにする
      rethrow;
    }
  }

  /// テスト用のモック初期化メソッド。
  /// 単体テストや Widget テストで任意の初期値を注入する際に使用します。
  @visibleForTesting
  static Future<AppPrefs> setMockInitialValues(
      Map<String, Object> values) async {
    // 既存のシングルトンと Completer をリセット
    resetForTesting();

    // Legacy 側のモック値を設定
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(values));

    // DataStore (SharedPreferencesAsync) 側のモックプラットフォームを設定
    final initialData = Map<String, Object>.from(values);
    initialData[migrationCompletedKey] = true;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData(initialData);

    return await getInstance();
  }

  /// テスト用のリセットメソッド
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    _initCompleter = null;
  }

  // --- 同期キャッシュからの読み出し API ---

  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  String? getString(String key) => _prefs.getString(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Object? get(String key) => _prefs.get(key);
  bool containsKey(String key) => _prefs.containsKey(key);
  Set<String> getKeys() => _prefs.keys;

  // --- 非同期書き込み API（同期キャッシュ更新＋DataStoreへの非同期永続化） ---

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  /// ユーザー設定をリセットします。
  /// システム保護キー（移行完了フラグ、アセット管理用キーなど）は保護され、削除されません。
  Future<void> clearUserPreferences() async {
    final allKeys = Set<String>.from(_prefs.keys);
    for (final key in allKeys) {
      if (!isSystemKey(key)) {
        await _prefs.remove(key);
      }
    }
  }
}

