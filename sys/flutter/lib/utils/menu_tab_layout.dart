import 'package:flutter/material.dart';

/// タブ区切りメニューの1行分の計測用データ
class MenuTabRowSpec {
  final List<String> cells;
  final bool isHeader;

  const MenuTabRowSpec({
    required this.cells,
    this.isHeader = false,
  });
}

/// タブ区切りメニューの各列の動的計測レイアウト結果
class MenuTabColumnLayout {
  /// 各列の実測必要幅（インデックス 0 は 1列目の最小必要幅、1以降は固定幅として使用）
  final List<double> columnWidths;

  /// 列間のスペース幅
  final double columnSpacing;

  /// 全列＋列間スペース＋左右クローム幅を含めた最小合計幅
  final double minTotalWidth;

  const MenuTabColumnLayout({
    required this.columnWidths,
    required this.columnSpacing,
    required this.minTotalWidth,
  });

  /// 全タブ区切り行のテキストを TextPainter で実測し、各列の必要幅を算出する
  factory MenuTabColumnLayout.measure({
    required List<MenuTabRowSpec> rows,
    required TextStyle bodyStyle,
    required TextStyle headerStyle,
    required TextScaler textScaler,
    double horizontalChromeWidth = 64.0,
    double cellPadding = 8.0,
    double baseColumnSpacing = 12.0,
  }) {
    int maxCols = 0;
    for (final row in rows) {
      if (row.cells.length > maxCols) {
        maxCols = row.cells.length;
      }
    }

    final scale = textScaler.scale(14.0) / 14.0;
    final spacing = (baseColumnSpacing * scale).clamp(10.0, 24.0);

    if (maxCols == 0) {
      return MenuTabColumnLayout(
        columnWidths: const [],
        columnSpacing: spacing,
        minTotalWidth: horizontalChromeWidth,
      );
    }

    final maxWidths = List<double>.filled(maxCols, 0.0);
    final painter = TextPainter(
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );

    try {
      for (final row in rows) {
        final style = row.isHeader ? headerStyle : bodyStyle;
        for (int i = 0; i < row.cells.length; i++) {
          final text = row.cells[i];
          if (text.isEmpty) continue;
          painter.text = TextSpan(text: text, style: style);
          painter.layout();
          final needed = painter.width.ceilToDouble() + cellPadding;
          if (needed > maxWidths[i]) {
            maxWidths[i] = needed;
          }
        }
      }
    } finally {
      painter.dispose();
    }

    double sumCols = 0.0;
    for (final w in maxWidths) {
      sumCols += w;
    }
    final totalSpacing = maxCols > 1 ? spacing * (maxCols - 1) : 0.0;
    final minTotalWidth = sumCols + totalSpacing + horizontalChromeWidth;

    return MenuTabColumnLayout(
      columnWidths: List<double>.unmodifiable(maxWidths),
      columnSpacing: spacing,
      minTotalWidth: minTotalWidth,
    );
  }

  /// 指定列インデックスの必要幅を返す（範囲外はフォールバック幅）
  double widthForColumn(int index, {double fallback = 80.0}) {
    if (index >= 0 && index < columnWidths.length && columnWidths[index] > 0) {
      return columnWidths[index];
    }
    return fallback;
  }

  /// 列数に応じた標準のテキスト揃えを返す
  static List<TextAlign> alignmentsForColumnCount(int count) {
    if (count == 6) {
      return const [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
        TextAlign.right,
        TextAlign.right,
        TextAlign.right,
      ];
    } else if (count == 5) {
      return const [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
        TextAlign.right,
        TextAlign.right,
      ];
    } else if (count == 3) {
      return const [
        TextAlign.left,
        TextAlign.right,
        TextAlign.left,
      ];
    } else if (count == 2) {
      return const [
        TextAlign.left,
        TextAlign.right,
      ];
    }
    return List<TextAlign>.generate(
      count,
      (index) => index == 0 ? TextAlign.left : TextAlign.right,
    );
  }
}
