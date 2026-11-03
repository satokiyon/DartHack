import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/app_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('広告付き機能の SharedPreferences フラグ判定ロジック検証', () async {
    // 1. デフォルト (未設定時はすべて true とみなす)
    await AppPrefs.setMockInitialValues({});
    var prefs = await AppPrefs.getInstance();

    bool isNewLevelRestActive() {
      final adFeatures = prefs.getBool('ad_features_enabled') ?? true;
      final rest = prefs.getBool('ad_feature_new_level_rest') ?? true;
      return adFeatures && rest;
    }

    bool isExitHighlightActive() {
      final adFeatures = prefs.getBool('ad_features_enabled') ?? true;
      final highlight = prefs.getBool('ad_feature_exit_highlight') ?? true;
      return adFeatures && highlight;
    }

    expect(isNewLevelRestActive(), isTrue);
    expect(isExitHighlightActive(), isTrue);

    // 2. 親スイッチを OFF にした場合、子スイッチが true でも無効化されること
    await prefs.setBool('ad_features_enabled', false);
    expect(isNewLevelRestActive(), isFalse);
    expect(isExitHighlightActive(), isFalse);

    // 3. 親スイッチが ON で、新階層回復のみ OFF にした場合
    await prefs.setBool('ad_features_enabled', true);
    await prefs.setBool('ad_feature_new_level_rest', false);
    expect(isNewLevelRestActive(), isFalse);
    expect(isExitHighlightActive(), isTrue);

    // 4. 親スイッチが ON で、終了時ハイライトのみ OFF にした場合
    await prefs.setBool('ad_feature_new_level_rest', true);
    await prefs.setBool('ad_feature_exit_highlight', false);
    expect(isNewLevelRestActive(), isTrue);
    expect(isExitHighlightActive(), isFalse);
  });
}

