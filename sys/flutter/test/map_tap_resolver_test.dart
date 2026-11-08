import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/map_tap_resolver.dart';

void main() {
  group('MapTapResolver Tests', () {
    const px = 25;
    const py = 10;

    test('classifyTarget correctly classifies self, adjacent (all 8 directions), and far', () {
      // 1. 主人公自身
      expect(
        MapTapResolver.classifyTarget(tileX: px, tileY: py, playerX: px, playerY: py),
        MapTapTargetType.self,
      );

      // 2. 全8方向の隣接マス
      final adjacentOffsets = [
        [-1, -1], [0, -1], [1, -1], // 上段 (左上, 上, 右上)
        [-1,  0],          [1,  0], // 中段 (左,       右)
        [-1,  1], [0,  1], [1,  1], // 下段 (左下, 下, 右下)
      ];

      for (final offset in adjacentOffsets) {
        final tx = px + offset[0];
        final ty = py + offset[1];
        expect(
          MapTapResolver.classifyTarget(tileX: tx, tileY: ty, playerX: px, playerY: py),
          MapTapTargetType.adjacent,
          reason: 'Offset $offset should be classified as adjacent',
        );
      }

      // 3. 2マス以上離れたマス（特に左2マスや右2マス、斜め2マスなど）
      final farOffsets = [
        [-2,  0], [2,  0], // 左2マス, 右2マス
        [ 0, -2], [0,  2], // 上2マス, 下2マス
        [-2, -2], [2,  2], // 左上2マス, 右下2マス
        [-5,  3], [10, 8], // 遠方
      ];

      for (final offset in farOffsets) {
        final tx = px + offset[0];
        final ty = py + offset[1];
        expect(
          MapTapResolver.classifyTarget(tileX: tx, tileY: ty, playerX: px, playerY: py),
          MapTapTargetType.far,
          reason: 'Offset $offset should be classified as far',
        );
      }
    });

    test('Targeting mode always forces modMenu (1) for any target', () {
      final resFar = MapTapResolver.resolve(
        tileX: px + 5,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'always',
        isMapScrolledOrZoomed: false,
        isTargetingMode: true,
      );
      expect(resFar.mod, MapTapResolver.modMenu);
      expect(resFar.targetType, MapTapTargetType.far);

      final resAdj = MapTapResolver.resolve(
        tileX: px + 1,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'always',
        isMapScrolledOrZoomed: false,
        isTargetingMode: true,
      );
      expect(resAdj.mod, MapTapResolver.modMenu);
      expect(resAdj.targetType, MapTapTargetType.adjacent);
    });

    test('always mode: self is menu(1), adjacent is smart(3), far is action(2)', () {
      // 主人公自身
      final resSelf = MapTapResolver.resolve(
        tileX: px,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'always',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resSelf.targetType, MapTapTargetType.self);
      expect(resSelf.mod, MapTapResolver.modMenu);

      // 全8方向の隣接マスはすべて modSmartAdjacent (3)
      final adjacentOffsets = [
        [-1, -1], [0, -1], [1, -1],
        [-1,  0],          [1,  0],
        [-1,  1], [0,  1], [1,  1],
      ];
      for (final offset in adjacentOffsets) {
        final resAdj = MapTapResolver.resolve(
          tileX: px + offset[0],
          tileY: py + offset[1],
          playerX: px,
          playerY: py,
          travelMode: 'always',
          isMapScrolledOrZoomed: false,
          isTargetingMode: false,
        );
        expect(resAdj.targetType, MapTapTargetType.adjacent);
        expect(resAdj.mod, MapTapResolver.modSmartAdjacent,
            reason: 'Adjacent offset $offset must resolve to modSmartAdjacent');
      }

      // 左に2マスの位置 (px - 2) は far と判定され modAction (2)
      final resFarLeft = MapTapResolver.resolve(
        tileX: px - 2,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'always',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resFarLeft.targetType, MapTapTargetType.far);
      expect(resFarLeft.mod, MapTapResolver.modAction);
    });

    test('after_scroll mode: self is menu(1), adjacent is smart(3), far depends on scroll', () {
      // 隣接マスはスクロール状態に関係なく smart (3)
      final resAdj = MapTapResolver.resolve(
        tileX: px + 1,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'after_scroll',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resAdj.mod, MapTapResolver.modSmartAdjacent);

      // 離れたマス: スクロール前は null (無視)
      final resFarNoScroll = MapTapResolver.resolve(
        tileX: px + 5,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'after_scroll',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resFarNoScroll.mod, isNull);

      // 離れたマス: スクロール後は modAction (2) かつ consumeScrollZoom == true
      final resFarScrolled = MapTapResolver.resolve(
        tileX: px + 5,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'after_scroll',
        isMapScrolledOrZoomed: true,
        isTargetingMode: false,
      );
      expect(resFarScrolled.mod, MapTapResolver.modAction);
      expect(resFarScrolled.consumeScrollZoom, isTrue);
    });

    test('menu mode: all locations resolve to modMenu (1)', () {
      // 主人公
      final resSelf = MapTapResolver.resolve(
        tileX: px,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'menu',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resSelf.mod, MapTapResolver.modMenu);

      // 隣接マス
      final resAdj = MapTapResolver.resolve(
        tileX: px - 1,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'menu',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resAdj.mod, MapTapResolver.modMenu);

      // 離れたマス
      final resFar = MapTapResolver.resolve(
        tileX: px + 10,
        tileY: py + 2,
        playerX: px,
        playerY: py,
        travelMode: 'menu',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resFar.mod, MapTapResolver.modMenu);
    });

    test('disabled mode: self and adjacent resolve to modMenu(1), far is ignored (null)', () {
      // 主人公
      final resSelf = MapTapResolver.resolve(
        tileX: px,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'disabled',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resSelf.mod, MapTapResolver.modMenu);

      // 隣接マス (menuと同じくmodMenu)
      final resAdj = MapTapResolver.resolve(
        tileX: px,
        tileY: py + 1,
        playerX: px,
        playerY: py,
        travelMode: 'disabled',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resAdj.mod, MapTapResolver.modMenu);

      // 離れたマス (無視)
      final resFar = MapTapResolver.resolve(
        tileX: px + 3,
        tileY: py,
        playerX: px,
        playerY: py,
        travelMode: 'disabled',
        isMapScrolledOrZoomed: false,
        isTargetingMode: false,
      );
      expect(resFar.mod, isNull);
    });
  });
}
