import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/tileset_info.dart';
import 'package:darthack/services/tileset_manager.dart';

void main() {
  group('TilesetInfo & TilesetManager Tests', () {
    test('aspectRatio calculations for square and non-square tiles', () {
      final pixelhack = TilesetInfo.findById('pixelhack_32x32');
      expect(pixelhack.aspectRatio, closeTo(1.0, 0.001));

      const nonSquare = TilesetInfo(
        id: 'custom_15x25',
        displayName: 'Custom (15x25)',
        tileWidth: 15,
        tileHeight: 25,
        author: 'User',
        url: '',
        assetPath: '',
        isBuiltIn: false,
      );
      expect(nonSquare.aspectRatio, closeTo(15.0 / 25.0, 0.001));
      expect(nonSquare.aspectRatio, closeTo(0.6, 0.001));
    });

    test('TilesetInfo toJson and fromJson roundtrip', () {
      const custom = TilesetInfo(
        id: 'custom_123_mytiles',
        displayName: 'My Tiles (32x48)',
        tileWidth: 32,
        tileHeight: 48,
        author: 'User',
        url: '/path/to/custom.png',
        assetPath: '',
        isBuiltIn: false,
        localFilePath: '/path/to/custom.png',
        isTransparent: true,
        license: 'CC BY 4.0',
        isModifiedForTransparency: true,
      );

      final json = custom.toJson();
      final restored = TilesetInfo.fromJson(json);

      expect(restored.id, custom.id);
      expect(restored.displayName, custom.displayName);
      expect(restored.tileWidth, 32);
      expect(restored.tileHeight, 48);
      expect(restored.isBuiltIn, false);
      expect(restored.localFilePath, '/path/to/custom.png');
      expect(restored.isTransparent, true);
      expect(restored.license, 'CC BY 4.0');
      expect(restored.isModifiedForTransparency, true);
      expect(restored.aspectRatio, closeTo(32.0 / 48.0, 0.001));

      // 既存データの互換性（isTransparent / license / isModifiedForTransparency が未定義の場合）
      final legacyJson = {
        'id': 'legacy_tile',
        'displayName': 'Legacy Tile',
        'tileWidth': 32,
        'tileHeight': 32,
        'author': 'User',
      };
      final fromLegacy = TilesetInfo.fromJson(legacyJson);
      expect(fromLegacy.isTransparent, false);
      expect(fromLegacy.license, '');
      expect(fromLegacy.isModifiedForTransparency, false);
    });

    test('All 6 built-in tilesets are transparent and Geoduck falls back to default', () {
      expect(TilesetInfo.allTilesets.length, 6);
      for (final tileset in TilesetInfo.allTilesets) {
        expect(tileset.isBuiltIn, true);
        expect(tileset.isTransparent, true, reason: '${tileset.id} should be transparent');
        expect(tileset.license.isNotEmpty, true, reason: '${tileset.id} should have license info');
      }

      // KevinTam は元から透過のため透過化改変フラグは false、その他5種は true
      final kevin = TilesetInfo.findById('kevintamtiles_64x64');
      expect(kevin.isModifiedForTransparency, false);
      expect(kevin.license, 'NGPL');

      final pixel = TilesetInfo.findById('pixelhack_32x32');
      expect(pixel.author, 'samuel (Scunah)');
      expect(pixel.isModifiedForTransparency, true);

      // 除外された Geoduck ID はデフォルト (pixelhack_32x32) に安全フォールバックする
      final fallback = TilesetInfo.findById('geoduck_15x25');
      expect(fallback.id, 'pixelhack_32x32');
    });

    test('getMapCellSize correctly scales square tiles', () {
      final manager = TilesetManager.instance;

      // 正方形タイル: 32x32
      final sizePixelhack = manager.getMapCellSize(
        tilesetId: 'pixelhack_32x32',
        baseHeight: 32.0,
      );
      expect(sizePixelhack.width, closeTo(32.0, 0.001));
      expect(sizePixelhack.height, closeTo(32.0, 0.001));

      // 正方形タイル: 64x64 (アスペクト比 1.0)
      final sizeKevin = manager.getMapCellSize(
        tilesetId: 'kevintamtiles_64x64',
        baseHeight: 32.0,
      );
      expect(sizeKevin.width, closeTo(32.0, 0.001));
      expect(sizeKevin.height, closeTo(32.0, 0.001));
    });
  });
}

