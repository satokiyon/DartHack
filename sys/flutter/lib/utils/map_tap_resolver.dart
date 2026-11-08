enum MapTapTargetType {
  self,
  adjacent,
  far,
}

class MapTapResolution {
  final MapTapTargetType targetType;
  final int? mod; // null の場合はタップ無視 (disabled / スクロール待ち等)
  final bool consumeScrollZoom;

  const MapTapResolution({
    required this.targetType,
    required this.mod,
    this.consumeScrollZoom = false,
  });
}

/// マップタップ時の対象分類および送信コマンド (mod) を決定する純粋関数ヘルパー
class MapTapResolver {
  static const int modMenu = 1;          // CLICK_1 (therecmdmenu / herecmdmenu)
  static const int modAction = 2;        // CLICK_2 (mouseaction: travel / direct action)
  static const int modSmartAdjacent = 3; // FLUTTER_POSCMD_SMART_ADJACENT (C移植層で移動/攻撃/メニューを解決)

  /// タイル座標とプレイヤー座標から相対位置関係を分類する
  static MapTapTargetType classifyTarget({
    required int tileX,
    required int tileY,
    required int playerX,
    required int playerY,
  }) {
    final dx = (tileX - playerX).abs();
    final dy = (tileY - playerY).abs();
    if (dx == 0 && dy == 0) {
      return MapTapTargetType.self;
    }
    if (dx <= 1 && dy <= 1) {
      return MapTapTargetType.adjacent;
    }
    return MapTapTargetType.far;
  }

  /// 現在の設定値に基づいて送信すべき PosCmd の mod 値を算出する
  static MapTapResolution resolve({
    required int tileX,
    required int tileY,
    required int playerX,
    required int playerY,
    required String travelMode,
    required bool isMapScrolledOrZoomed,
    required bool isTargetingMode,
  }) {
    final targetType = classifyTarget(
      tileX: tileX,
      tileY: tileY,
      playerX: playerX,
      playerY: playerY,
    );

    // ターゲット選択・遠見入力待ち中は座標指定 (CLICK_1) として送信
    if (isTargetingMode) {
      return MapTapResolution(
        targetType: targetType,
        mod: modMenu,
      );
    }

    switch (targetType) {
      case MapTapTargetType.self:
        // 主人公自身はどのモードでも足元アクションメニューを表示
        return const MapTapResolution(
          targetType: MapTapTargetType.self,
          mod: modMenu,
        );

      case MapTapTargetType.adjacent:
        // 隣接マス:
        // - 'always' / 'after_scroll': mod=3 (C側で床・敵・ペットは即時移動/攻撃/入れ替え、扉・罠等はメニュー)
        // - 'menu' / 'disabled': mod=1 (メニュー表示)
        if (travelMode == 'always' || travelMode == 'after_scroll') {
          return const MapTapResolution(
            targetType: MapTapTargetType.adjacent,
            mod: modSmartAdjacent,
          );
        } else {
          return const MapTapResolution(
            targetType: MapTapTargetType.adjacent,
            mod: modMenu,
          );
        }

      case MapTapTargetType.far:
        // 離れたマス (2マス以上離れた場所への移動)
        switch (travelMode) {
          case 'disabled':
            return const MapTapResolution(
              targetType: MapTapTargetType.far,
              mod: null, // 無視
            );

          case 'after_scroll':
            if (!isMapScrolledOrZoomed) {
              return const MapTapResolution(
                targetType: MapTapTargetType.far,
                mod: null, // スクロール前は無視
              );
            }
            return const MapTapResolution(
              targetType: MapTapTargetType.far,
              mod: modAction,
              consumeScrollZoom: true,
            );

          case 'always':
            return const MapTapResolution(
              targetType: MapTapTargetType.far,
              mod: modAction,
            );

          case 'menu':
          default:
            return const MapTapResolution(
              targetType: MapTapTargetType.far,
              mod: modMenu,
            );
        }
    }
  }
}
