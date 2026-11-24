import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/menu_tab_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MenuTabColumnLayout 動的列幅計算テスト', () {
    const bodyStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    const headerStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);

    test('空入力時に安全なデフォルト値を返すこと', () {
      final layout = MenuTabColumnLayout.measure(
        rows: const [],
        bodyStyle: bodyStyle,
        headerStyle: headerStyle,
        textScaler: TextScaler.noScaling,
        horizontalChromeWidth: 64.0,
      );

      expect(layout.columnWidths, isEmpty);
      expect(layout.minTotalWidth, equals(64.0));
      expect(layout.widthForColumn(0), equals(80.0));
    });

    test('ヘッダーとデータ行のうち最大幅が各列に採用されること', () {
      final layout = MenuTabColumnLayout.measure(
        rows: const [
          MenuTabRowSpec(
            cells: ['Name', 'Level', 'Category', 'Fail', 'Retention'],
            isHeader: true,
          ),
          MenuTabRowSpec(
            cells: ['a - detect monsters', '1', 'divination', '0%', '91%-100%'],
          ),
        ],
        bodyStyle: bodyStyle,
        headerStyle: headerStyle,
        textScaler: TextScaler.noScaling,
      );

      expect(layout.columnWidths.length, equals(5));
      // 各列は正の幅を持つ
      for (final w in layout.columnWidths) {
        expect(w, greaterThan(0.0));
      }
      // 1列目（'a - detect monsters'）は2列目（'Level'）より広い
      expect(layout.columnWidths[0], greaterThan(layout.columnWidths[1]));
      // 3列目（'divination'）は2列目（'Level'）より広い
      expect(layout.columnWidths[2], greaterThan(layout.columnWidths[1]));
      // 合計幅は全列幅 + 列間スペース + クローム幅と一致
      final expectedTotal = layout.columnWidths.reduce((a, b) => a + b) +
          layout.columnSpacing * 4 +
          64.0;
      expect(layout.minTotalWidth, closeTo(expectedTotal, 0.001));
    });

    test('textScaler の拡大に応じて列幅・列間スペース・合計幅が増加すること', () {
      const rows = [
        MenuTabRowSpec(
          cells: ['呪文名', 'レベル', '系統', '失敗率', '記憶'],
          isHeader: true,
        ),
        MenuTabRowSpec(
          cells: ['a - 灯り', '1', '聖職', '0%', '91%-100%'],
        ),
      ];

      final normal = MenuTabColumnLayout.measure(
        rows: rows,
        bodyStyle: bodyStyle,
        headerStyle: headerStyle,
        textScaler: const TextScaler.linear(1.0),
      );
      final large = MenuTabColumnLayout.measure(
        rows: rows,
        bodyStyle: bodyStyle,
        headerStyle: headerStyle,
        textScaler: const TextScaler.linear(1.5),
      );
      final extraLarge = MenuTabColumnLayout.measure(
        rows: rows,
        bodyStyle: bodyStyle,
        headerStyle: headerStyle,
        textScaler: const TextScaler.linear(2.0),
      );

      for (int i = 0; i < 5; i++) {
        expect(large.columnWidths[i], greaterThan(normal.columnWidths[i]));
        expect(extraLarge.columnWidths[i], greaterThan(large.columnWidths[i]));
      }
      expect(large.columnSpacing, greaterThan(normal.columnSpacing));
      expect(extraLarge.minTotalWidth, greaterThan(large.minTotalWidth));
      expect(large.minTotalWidth, greaterThan(normal.minTotalWidth));
    });

    test('列数ごとの標準アライメントが正しく返ること', () {
      expect(
        MenuTabColumnLayout.alignmentsForColumnCount(6),
        equals([
          TextAlign.left,
          TextAlign.right,
          TextAlign.left,
          TextAlign.right,
          TextAlign.right,
          TextAlign.right,
        ]),
      );
      expect(
        MenuTabColumnLayout.alignmentsForColumnCount(5),
        equals([
          TextAlign.left,
          TextAlign.right,
          TextAlign.left,
          TextAlign.right,
          TextAlign.right,
        ]),
      );
      expect(
        MenuTabColumnLayout.alignmentsForColumnCount(3),
        equals([TextAlign.left, TextAlign.right, TextAlign.left]),
      );
      expect(
        MenuTabColumnLayout.alignmentsForColumnCount(2),
        equals([TextAlign.left, TextAlign.right]),
      );
      expect(
        MenuTabColumnLayout.alignmentsForColumnCount(4),
        equals([TextAlign.left, TextAlign.right, TextAlign.right, TextAlign.right]),
      );
    });
  });
}
