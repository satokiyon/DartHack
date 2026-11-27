import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/map_camera.dart';

void main() {
  group('MapCamera computeAxis Tests', () {
    const mapCellsX = 80;
    const cellW = 32.0;
    const mapStartX = (4000.0 - mapCellsX * cellW) / 2.0; // 720.0

    test('軸方向にマップ全体が収まる場合は、フォーカスが動いても常に実効ビューポート中央に固定される', () {
      const viewStart = 0.0;
      const viewSize = 3000.0; // 3000px の広い画面
      const scale = 1.0; // マップ幅は 80 * 32 = 2560px <= 3000px (収まる)

      // 中央配置時の期待される t:
      // centerT = 0 + (3000 - 2560)/2 - 720 * 1 = 220 - 720 = -500.0
      const expectedT = -500.0;

      // フォーカスがどこにあっても同じ中央配置の t が返る
      for (final focusX in [0, 10, 40, 79]) {
        final t = MapCamera.computeAxis(
          viewStart: viewStart,
          viewSize: viewSize,
          mapStart: mapStartX,
          mapCells: mapCellsX,
          cell: cellW,
          scale: scale,
          focus: focusX,
          currentT: 0.0,
          margin: 3,
          amount: 3,
          force: false,
        );
        expect(t, closeTo(expectedT, 0.001));
      }
    });

    test('マップがはみ出す場合、マージン内であればカメラ位置は動かず維持される', () {
      const viewStart = 0.0;
      const viewSize = 800.0; // 800px 画面 (800 / 32 = 25セル分表示可能)
      const scale = 1.0;
      // 現在の t が -720.0 だとすると、pos は 0.0 (0〜25マス目が画面内)
      const currentT = -720.0;

      // マージンが 3 のとき、pos+3 = 3 から pos+25-3-1 = 21 までの間はマージン内
      for (final focusX in [5, 10, 15, 20]) {
        final t = MapCamera.computeAxis(
          viewStart: viewStart,
          viewSize: viewSize,
          mapStart: mapStartX,
          mapCells: mapCellsX,
          cell: cellW,
          scale: scale,
          focus: focusX,
          currentT: currentT,
          margin: 3,
          amount: 3,
          force: false,
        );
        expect(t, equals(currentT), reason: 'フォーカス $focusX はマージン内なのでカメラは動かない');
      }
    });

    test('右側のマージンに達したとき、本家win32式 (mcam = margin + amount - 1) に従ってスクロールする', () {
      const viewStart = 0.0;
      const viewSize = 800.0; // page = 25セル
      const scale = 1.0;
      const currentT = -720.0; // pos = 0.0 (表示セル範囲: 0..25)
      const margin = 3;
      const amount = 3;
      // mcam = 3 + 3 - 1 = 5

      // focusX = 23 (25 - 3 = 22 より右、マージン到達)
      // newPos = focusX + 1 - page + mcam = 24 - 25 + 5 = 4.0
      // expectedT = 0 - (720 / 32 + 4.0) * 32 = -(22.5 + 4.0) * 32 = -848.0
      final t = MapCamera.computeAxis(
        viewStart: viewStart,
        viewSize: viewSize,
        mapStart: mapStartX,
        mapCells: mapCellsX,
        cell: cellW,
        scale: scale,
        focus: 23,
        currentT: currentT,
        margin: margin,
        amount: amount,
        force: false,
      );
      expect(t, closeTo(-848.0, 0.001));
    });

    test('テレポートや画面外への大移動時、主人公が画面内に収まるよう即座に再配置される', () {
      const viewStart = 0.0;
      const viewSize = 800.0; // page = 25セル
      const scale = 1.0;
      const currentT = -720.0; // 表示範囲: 0..25

      // テレポートで遠くの focusX = 60 へ飛んだ場合
      final t = MapCamera.computeAxis(
        viewStart: viewStart,
        viewSize: viewSize,
        mapStart: mapStartX,
        mapCells: mapCellsX,
        cell: cellW,
        scale: scale,
        focus: 60,
        currentT: currentT,
        margin: 3,
        amount: 3,
        force: false,
      );
      expect(t, isNot(equals(currentT)));

      // 再配置後の位置でフォーカス 60 が画面内（viewStart..viewStart+viewSize）に入っていることを検証
      // screenX = (mapStartX + 60 * cellW) * scale + t
      final screenX = (mapStartX + 60.0 * cellW) * scale + t;
      expect(screenX, greaterThanOrEqualTo(viewStart));
      expect(screenX, lessThanOrEqualTo(viewStart + viewSize));
    });

    test('表示幅が狭い場合 (page <= 2 * mcam)、主人公が画面中央に寄せられる', () {
      const viewStart = 0.0;
      const viewSize = 250.0; // 250 / 32 ≈ 7.8 セル
      const scale = 1.0;
      const margin = 3;
      const amount = 3;
      // mcam = 5, 2 * mcam = 10 > page (7.8) -> 中央寄せ分岐に入る

      final t = MapCamera.computeAxis(
        viewStart: viewStart,
        viewSize: viewSize,
        mapStart: mapStartX,
        mapCells: mapCellsX,
        cell: cellW,
        scale: scale,
        focus: 30,
        currentT: -720.0,
        margin: margin,
        amount: amount,
        force: false,
      );

      // 主人公の中心ピクセルが viewSize の中央 (125.0) に来ているか確認
      final heroCenterScreenX = (mapStartX + (30.0 + 0.5) * cellW) * scale + t;
      expect(heroCenterScreenX, closeTo(125.0, 0.1));
    });

    test('force フラグが true の場合、マージン接触に関わらず再配置が実行される', () {
      const viewStart = 0.0;
      const viewSize = 800.0;
      const scale = 1.0;
      const currentT = -1200.0; // 手動パンでずれている位置

      final t = MapCamera.computeAxis(
        viewStart: viewStart,
        viewSize: viewSize,
        mapStart: mapStartX,
        mapCells: mapCellsX,
        cell: cellW,
        scale: scale,
        focus: 40,
        currentT: currentT,
        margin: 3,
        amount: 3,
        force: true,
      );
      expect(t, isNot(equals(currentT)));
    });

    test('fitScale が縦横の最小比率を正しく算出する', () {
      final scale = MapCamera.fitScale(
        viewportSize: const Size(800, 600),
        mapWidth: 2560,
        mapHeight: 672,
      );
      // scaleX = 800 / 2560 = 0.3125
      // scaleY = 600 / 672 ≈ 0.8928
      // min は 0.3125
      expect(scale, closeTo(0.3125, 0.001));
    });

    test('縦長画面で下部インセット（コントローラー）がある場合、最下端の主人公が実効ビューポート下端に正しくスクロールする', () {
      const mapCellsY = 21;
      const cellH = 28.0;
      const mapStartY = (3000.0 - mapCellsY * cellH) / 2.0; // 3000 - 588 = 2412 / 2 = 1206.0
      const viewStart = 100.0; // 上部メッセージ領域インセット
      const viewSize = 490.0;  // 画面高820 - 上部100 - 下部コントローラー230 = 490px
      const scale = 1.0;
      // マップ全高 588px > viewSize 490px なのでスクロール対象

      // 最下端 (focusY = 20) に主人公がいる場合
      final t = MapCamera.computeAxis(
        viewStart: viewStart,
        viewSize: viewSize,
        mapStart: mapStartY,
        mapCells: mapCellsY,
        cell: cellH,
        scale: scale,
        focus: 20,
        currentT: 0.0,
        margin: 3,
        amount: 3,
        force: true,
      );

      // screenY = (mapStartY + focusY * cellH) * scale + t
      final heroScreenY = (mapStartY + 20 * cellH) * scale + t;

      // 主人公セルの下端 (heroScreenY + cellH) は実効ビューポート下端 (viewStart + viewSize = 590.0) を超えない
      expect(heroScreenY + cellH, closeTo(viewStart + viewSize, 0.001));
      // 主人公は実効ビューポート内 (100.0 .. 590.0) に収まっている
      expect(heroScreenY, greaterThanOrEqualTo(viewStart));
      expect(heroScreenY + cellH, lessThanOrEqualTo(viewStart + viewSize));
    });
  });

  group('MapCamera animation sync helpers', () {
    test('shouldAnimateFollow は通常 1〜2 マス移動のみ true、強制/ターゲット/大移動/未初期化は false', () {
      expect(
        MapCamera.shouldAnimateFollow(
          force: false,
          isTargetingMode: false,
          prevX: 10,
          prevY: 10,
          nextX: 11,
          nextY: 10,
        ),
        isTrue,
      );
      // 強制再配置
      expect(
        MapCamera.shouldAnimateFollow(
          force: true,
          isTargetingMode: false,
          prevX: 10,
          prevY: 10,
          nextX: 11,
          nextY: 10,
        ),
        isFalse,
      );
      // 位置指定 / Farlook モード (getposInp)
      expect(
        MapCamera.shouldAnimateFollow(
          force: false,
          isTargetingMode: true,
          prevX: 10,
          prevY: 10,
          nextX: 11,
          nextY: 10,
        ),
        isFalse,
      );
      // テレポート等の 3 マス以上移動
      expect(
        MapCamera.shouldAnimateFollow(
          force: false,
          isTargetingMode: false,
          prevX: 10,
          prevY: 10,
          nextX: 15,
          nextY: 10,
        ),
        isFalse,
      );
      // 初回未初期化
      expect(
        MapCamera.shouldAnimateFollow(
          force: false,
          isTargetingMode: false,
          prevX: -1,
          prevY: -1,
          nextX: 10,
          nextY: 10,
        ),
        isFalse,
      );
    });

    test('isSameTarget は重複カメラ更新の同一目標座標を正しく判定する', () {
      expect(MapCamera.isSameTarget(-500.0, -300.0, -500.2, -299.8), isTrue);
      expect(MapCamera.isSameTarget(-500.0, -300.0, -532.0, -300.0), isFalse);
    });
  });

  group('MapCamera scale and Matrix4 transform regression tests', () {
    test('縮小倍率で buildTransform した行列は extractScale と getMaxScaleOnAxis の両方が縮小倍率を返す', () {
      for (final scale in [0.25, 0.35, 0.5, 0.8, 1.0, 2.5]) {
        final matrix = MapCamera.buildTransform(scale: scale, tx: -420.0, ty: -180.0);
        expect(MapCamera.extractScale(matrix), closeTo(scale, 0.0001));
        expect(matrix.getMaxScaleOnAxis(), closeTo(scale, 0.0001));
        expect(matrix.storage[12], closeTo(-420.0, 0.0001));
        expect(matrix.storage[13], closeTo(-180.0, 0.0001));
      }
    });

    test('Z 軸が 1.0 の行列でも extractScale は縮小倍率を 1.0 に化けさせずに抽出する', () {
      final legacyMatrix = Matrix4(
        0.5, 0.0, 0.0, 0.0,
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -600.0, -300.0, 0.0, 1.0,
      );
      // getMaxScaleOnAxis() は Z=1.0 の影響で 1.0 を返してしまうが、extractScale() は 0.5 を維持
      expect(legacyMatrix.getMaxScaleOnAxis(), closeTo(1.0, 0.0001));
      expect(MapCamera.extractScale(legacyMatrix), closeTo(0.5, 0.0001));
    });

    test('縮小状態での連続フレーム補間（buildTransform → extractScale）でスケールも主人公位置もズレない', () {
      const initialScale = 0.45;
      const viewW = 800.0;
      const viewH = 600.0;
      const playerX = 2000.0;
      const playerY = 1500.0;

      var matrix = MapCamera.buildTransform(
        scale: initialScale,
        tx: (viewW / 2) - playerX * initialScale,
        ty: (viewH * 0.4) - playerY * initialScale,
      );

      // 10 フレーム連続でスケール読み戻し＋平行移動補間を繰り返す
      const nextPlayerX = playerX + 32.0;
      final startTx = matrix.storage[12];
      final targetTx = (viewW / 2) - nextPlayerX * initialScale;
      final targetTy = (viewH * 0.4) - playerY * initialScale;

      for (int i = 1; i <= 10; i++) {
        final t = i / 10.0;
        final activeScale = MapCamera.extractScale(matrix);
        final tx = startTx + (targetTx - startTx) * t;
        matrix = MapCamera.buildTransform(scale: activeScale, tx: tx, ty: targetTy);
      }

      expect(MapCamera.extractScale(matrix), closeTo(initialScale, 0.0001));
      expect(matrix.getMaxScaleOnAxis(), closeTo(initialScale, 0.0001));
      // 最終フレームで主人公のスクリーン座標が画面中央に来ていること
      final finalScreenX = nextPlayerX * MapCamera.extractScale(matrix) + matrix.storage[12];
      final finalScreenY = playerY * MapCamera.extractScale(matrix) + matrix.storage[13];
      expect(finalScreenX, closeTo(viewW / 2, 0.01));
      expect(finalScreenY, closeTo(viewH * 0.4, 0.01));
    });
  });
}

