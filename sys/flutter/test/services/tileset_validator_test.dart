import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/tileset_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TilesetValidator Header Parsing & Validation Tests', () {
    test('Validates actual pixelhack_32x32.webp', () async {
      final file = File('assets/tiles/pixelhack_32x32.webp');
      if (!await file.exists()) {
        // テスト実行ディレクトリの差異対策
        final altFile = File('sys/flutter/assets/tiles/pixelhack_32x32.webp');
        if (await altFile.exists()) {
          final bytes = await altFile.readAsBytes();
          final result = await TilesetValidator.validate(bytes, fileName: 'pixelhack_32x32.webp');
          expect(result.isValid, true);
          expect(result.tileWidth, 32);
          expect(result.tileHeight, 32);
          expect(result.cols, 40);
          expect(result.rows, 58);
          expect(result.aspectRatio, closeTo(1.0, 0.001));
          return;
        }
      }
      final bytes = await file.readAsBytes();
      final result = await TilesetValidator.validate(bytes, fileName: 'pixelhack_32x32.webp');
      expect(result.isValid, true);
      expect(result.tileWidth, 32);
      expect(result.tileHeight, 32);
      expect(result.cols, 40);
      expect(result.rows, 58);
    });

    test('Validates actual geoduck_15x25.webp without filename hints', () async {
      File file = File('assets/tiles/geoduck_15x25.webp');
      if (!await file.exists()) {
        file = File('sys/flutter/assets/tiles/geoduck_15x25.webp');
      }
      final bytes = await file.readAsBytes();

      // ファイル名をヒントなし ("unknown.webp") にして自動寸法判定をテスト
      final result = await TilesetValidator.validate(bytes, fileName: 'unknown.webp');
      expect(result.isValid, true);
      expect(result.imageWidth, 600);
      expect(result.imageHeight, 1500);
      expect(result.tileWidth, 15);
      expect(result.tileHeight, 25);
      expect(result.cols, 40);
      expect(result.rows, 60);
      expect(result.aspectRatio, closeTo(0.6, 0.001));
    });

    test('Validates actual default_16x16.webp', () async {
      File file = File('assets/tiles/default_16x16.webp');
      if (!await file.exists()) {
        file = File('sys/flutter/assets/tiles/default_16x16.webp');
      }
      final bytes = await file.readAsBytes();
      final result = await TilesetValidator.validate(bytes, fileName: 'default_16x16.webp');
      expect(result.isValid, true);
      expect(result.tileWidth, 16);
      expect(result.tileHeight, 16);
      expect(result.cols, 40);
    });

    test('Rejects image with width not divisible by 40', () async {
      // 偽のPNGヘッダー (幅 100, 高さ 100) -> 100 % 40 != 0 (128バイト以上)
      final bytes = Uint8List(256);
      bytes.setRange(0, 8, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final bd = ByteData.sublistView(bytes);
      bd.setUint32(16, 100, Endian.big); // width: 100
      bd.setUint32(20, 100, Endian.big); // height: 100

      final result = await TilesetValidator.validate(bytes, fileName: 'invalid_width.png');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('40 列'));
    });

    test('Rejects file too small', () async {
      final bytes = Uint8List(50);
      final result = await TilesetValidator.validate(bytes, fileName: 'tiny.png');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('ファイルサイズが小さすぎます'));
    });
  });
}
