import 'dart:math' as math;
import 'package:flutter/material.dart';

/// マップ固定モード（Fixed Map Mode）における 1 軸分のカメラ平行移動量および
/// 全体表示フィット倍率を算出する純粋計算クラス。
///
/// 座標系: screen = canvas * scale + t
/// （キャンバス上の座標 canvas に scale を掛け、平行移動量 t を加えたものが画面座標 screen となる）
class MapCamera {
  /// 1 軸分の新しい平行移動量 `t` を算出する。
  ///
  /// [viewStart]: 実効ビューポートの開始座標（X軸なら left, Y軸なら top）
  /// [viewSize]: 実効ビューポートの幅または高さ
  /// [mapStart]: 4000x3000 キャンバス内でのマップ開始オフセット (mapOffsetX または mapOffsetY)
  /// [mapCells]: マップ全体のセル数（横なら 80, 縦なら 21）
  /// [cell]: セルの基準寸法（倍率前のセル幅またはセル高さ）
  /// [scale]: 現在のズーム倍率
  /// [focus]: 追従対象（主人公またはカーソル）のセル座標（0 起点）
  /// [currentT]: 現在のカメラ平行移動量 `t` (Matrix4 の translation 成分)
  /// [margin]: 画面端からスクロールを開始するマス数（scroll_margin）
  /// [amount]: 端に達したときに余分にスクロールするマス数（scroll_amount）
  /// [force]: 階層移動や設定変更などによる強制再配置フラグ
  static double computeAxis({
    required double viewStart,
    required double viewSize,
    required double mapStart,
    required int mapCells,
    required double cell,
    required double scale,
    required int focus,
    required double currentT,
    required int margin,
    required int amount,
    required bool force,
  }) {
    final cs = cell * scale;
    if (cs <= 0.0 || viewSize <= 0.0) return currentT;

    final scaledMap = mapCells * cs;

    // 1) 軸方向にマップ全体が実効ビューポート内に収まる場合: マップ全体を実効ビューポート中央に固定
    if (scaledMap <= viewSize) {
      final centerT = viewStart + (viewSize - scaledMap) / 2.0 - mapStart * scale;
      return centerT;
    }

    // 2) 現在の表示枠における開始セル位置（pos: 浮動小数セル座標）と、画面に表示できるセル数（page）
    final page = viewSize / cs;
    // screenX = (mapStart + cellX * cell) * scale + t = viewStart
    // cellX = (viewStart - t) / (cell * scale) - mapStart / cell
    final pos = (viewStart - currentT) / cs - (mapStart / cell);

    // フォーカスが画面枠外にはみ出ているか？
    final outOfView = focus < pos || focus + 1 > pos + page;
    // フォーカスが scroll_margin 以内に触れているか？
    final hitMargin = focus < pos + margin || focus + 1 > pos + page - margin;

    // 強制再配置でなく、かつ画面外でもマージン接触でもない場合は現在のカメラ位置を維持（動かさない）
    if (!force && !outOfView && !hitMargin) {
      return currentT;
    }

    // 3) NetHack 本家 win32 (mhmap.c) と同等の再配置式:
    // mcam = margin + amount - 1
    final mcam = margin + amount - 1;
    double newPos;

    if (page <= 2 * mcam) {
      // 表示できるセル数が 2 * mcam 以下の狭い画面の場合は、主人公/カーソルを画面中央に寄せる
      newPos = focus + 0.5 - (page / 2.0);
    } else if (focus < pos + (page / 2.0)) {
      // 左側（上側）のマージンに達した場合は、端から mcam だけ内側に来るように配置
      newPos = (focus - mcam).toDouble();
    } else {
      // 右側（下側）のマージンに達した場合は、端から mcam だけ内側に来るように配置
      newPos = (focus + 1.0) - page + mcam;
    }

    // 4) マップの有効範囲 (0 .. mapCells - page) の外側を過剰に映さないようにクランプ
    final maxPos = mapCells - page;
    if (maxPos > 0) {
      newPos = newPos.clamp(0.0, maxPos);
    } else {
      newPos = 0.0;
    }

    return viewStart - (mapStart / cell + newPos) * cs;
  }

  /// マップ全体（80x21）が実効ビューポートに完全に収まる最適なフィット倍率を算出する。
  static double fitScale({
    required Size viewportSize,
    required double mapWidth,
    required double mapHeight,
  }) {
    if (mapWidth <= 0 || mapHeight <= 0 || viewportSize.width <= 0 || viewportSize.height <= 0) {
      return 1.0;
    }
    final scaleX = viewportSize.width / mapWidth;
    final scaleY = viewportSize.height / mapHeight;
    return math.min(scaleX, scaleY);
  }
}

