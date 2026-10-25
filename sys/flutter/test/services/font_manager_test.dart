import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/font_manager.dart';
import 'package:darthack/utils/app_prefs.dart';
import '../font_validator_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppPrefs mockPrefs;

  setUp(() async {
    FontManager.resetForTesting();
    tempDir = await Directory.systemTemp.createTemp('font_manager_test_');
    mockPrefs = await AppPrefs.setMockInitialValues({});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FontManager 初期化 & デフォルト値', () {
    test('初期状態でデフォルトフォントが設定されている', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      expect(manager.isInitialized, isTrue);
      expect(manager.getSelectedFont(FontTarget.map).id, 'Terminus');
      expect(manager.getSelectedFont(FontTarget.message).id, 'system');
      expect(manager.getSelectedFont(FontTarget.status).id, 'system');
      expect(manager.getSelectedFont(FontTarget.menu).id, 'system');
      expect(manager.getSelectedFont(FontTarget.ui).id, 'system');
      expect(manager.mapAsciiScale, 1.0);
    });

    test('内蔵フォント 5 種が利用可能リストに含まれる', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final available = manager.availableFonts;
      expect(available.any((f) => f.id == 'system'), isTrue);
      expect(available.any((f) => f.id == 'Terminus'), isTrue);
      expect(available.any((f) => f.id == 'Unscii-8'), isTrue);
      expect(available.any((f) => f.id == 'Unscii-16'), isTrue);
      expect(available.any((f) => f.id == 'MisakiGothic'), isTrue);
    });
  });

  group('FontManager フォント変更 & 永続化', () {
    test('個別ターゲットのフォントを変更し Prefs に保存される', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      bool notified = false;
      manager.addListener(() => notified = true);

      await manager.setFont(FontTarget.map, 'Unscii-8');
      expect(manager.getSelectedFont(FontTarget.map).id, 'Unscii-8');
      expect(mockPrefs.getString(FontManager.prefFontMap), 'Unscii-8');
      expect(notified, isTrue);

      await manager.setFont(FontTarget.message, 'MisakiGothic');
      expect(manager.getSelectedFont(FontTarget.message).id, 'MisakiGothic');
      expect(mockPrefs.getString(FontManager.prefFontMessage), 'MisakiGothic');
    });

    test('全ターゲットの一括変更 (setAllFonts) が機能する', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      await manager.setAllFonts('Unscii-16');

      for (final target in FontTarget.values) {
        expect(manager.getSelectedFont(target).id, 'Unscii-16');
      }
      expect(mockPrefs.getString(FontManager.prefFontMap), 'Unscii-16');
      expect(mockPrefs.getString(FontManager.prefFontUi), 'Unscii-16');
    });
  });

  group('FontManager TextStyle 生成 & フォールバック保護', () {
    test('マップ用 TextStyle では日本語フォールバックが null になる (全角記号混入防止)', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final style = manager.getStyle(FontTarget.map, fontSize: 16.0);
      expect(style.fontFamily, 'Terminus');
      expect(style.fontFamilyFallback, isNull);
      expect(style.fontWeight, FontWeight.normal);
      expect(style.height, 1.0);
    });

    test('マップ以外用 TextStyle では日本語フォールバックが付与される', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final style = manager.getStyle(FontTarget.message, fontSize: 14.0);
      expect(style.fontFamilyFallback, isNotNull);
      expect(style.fontFamilyFallback, contains('Noto Sans JP'));
    });
  });

  group('FontManager セルサイズ一元管理', () {
    test('タイル表示モードでは固定 32x32 を返す', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final size = manager.getMapCellSize(useTiles: true);
      expect(size.width, 32.0);
      expect(size.height, 32.0);
    });

    test('アスキーモードではフォントアスペクト比と倍率設定に基づいてサイズを算出する', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final sizeDefault = manager.getMapCellSize(useTiles: false);
      expect(sizeDefault.height, 28.0);
      expect(sizeDefault.width, greaterThan(8.0));
      expect(sizeDefault.width, lessThanOrEqualTo(28.0));

      // 倍率変更 (1.5x)
      await manager.setMapAsciiScale(1.5);
      final sizeScaled = manager.getMapCellSize(useTiles: false);
      expect(sizeScaled.height, 42.0);
      expect(sizeScaled.width, greaterThan(sizeDefault.width));
    });
  });

  group('FontManager 外部フォント管理', () {
    test('有効な外部フォントをインポートし、リストに追加・削除できる', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final validFontBytes = createDummySfnt();
      final result = await manager.importCustomFont(validFontBytes, 'my_custom_font.ttf');
      if (!result.isValid) {
        fail('IMPORT ERROR: ${result.errorMessage}');
      }
      expect(manager.availableFonts.any((f) => f.id == 'custom_my_custom_font'), isTrue);

      // カスタムフォントを選択
      await manager.setFont(FontTarget.map, 'custom_my_custom_font');
      expect(manager.getSelectedFont(FontTarget.map).id, 'custom_my_custom_font');

      // カスタムフォントを削除
      final deleted = await manager.deleteCustomFont('custom_my_custom_font');
      expect(deleted, isTrue);
      expect(manager.availableFonts.any((f) => f.id == 'custom_my_custom_font'), isFalse);

      // 削除後は 'system' に自動フォールバックされる
      expect(manager.getSelectedFont(FontTarget.map).id, 'system');
    });

    test('破損した外部フォントのインポートは拒絶される', () async {
      final manager = FontManager.instance;
      await manager.init(prefs: mockPrefs, customFontsDir: tempDir);

      final corruptBytes = createDummySfnt(headMagic: 0x99999999);
      final result = await manager.importCustomFont(corruptBytes, 'bad_font.ttf');

      expect(result.isValid, isFalse);
      expect(manager.availableFonts.any((f) => f.id == 'custom_bad_font'), isFalse);
    });
  });
}
