import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/tileset_info.dart';
import 'package:darthack/services/tileset_manager.dart';

void main() {
  group('TilesetInfo & TilesetManager Tests', () {
    test('aspectRatio calculations for square and non-square tiles', () {
      final pixelhack = TilesetInfo.findById('pixelhack_32x32');
      expect(pixelhack.aspectRatio, closeTo(1.0, 0.001));

      final geoduck = TilesetInfo.findById('geoduck_15x25');
      expect(geoduck.aspectRatio, closeTo(15.0 / 25.0, 0.001));
      expect(geoduck.aspectRatio, closeTo(0.6, 0.001));
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
      );

      final json = custom.toJson();
      final restored = TilesetInfo.fromJson(json);

      expect(restored.id, custom.id);
      expect(restored.displayName, custom.displayName);
      expect(restored.tileWidth, 32);
      expect(restored.tileHeight, 48);
      expect(restored.isBuiltIn, false);
      expect(restored.localFilePath, '/path/to/custom.png');
      expect(restored.aspectRatio, closeTo(32.0 / 48.0, 0.001));
    });

    test('getMapCellSize correctly scales non-square tiles', () {
      final manager = TilesetManager.instance;

      // 正方形タイル: 32x32
      final sizePixelhack = manager.getMapCellSize(
        tilesetId: 'pixelhack_32x32',
        baseHeight: 32.0,
      );
      expect(sizePixelhack.width, closeTo(32.0, 0.001));
      expect(sizePixelhack.height, closeTo(32.0, 0.001));

      // 縦長タイル (Geoduck 15x25): 比率 0.6
      // cellH = 32.0, cellW = 32.0 * (15 / 25) = 19.2
      final sizeGeoduck = manager.getMapCellSize(
        tilesetId: 'geoduck_15x25',
        baseHeight: 32.0,
      );
      expect(sizeGeoduck.width, closeTo(19.2, 0.001));
      expect(sizeGeoduck.height, closeTo(32.0, 0.001));
    });
  });
}

