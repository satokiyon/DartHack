import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';

void main() {
  test('Verify companion.jp.md parses cleanly in SpoilerDialog', () {
    final file = File('books/jp/companion.jp.md');
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content.isNotEmpty, isTrue);

    // 見出し数と行数の確認
    final lines = content.split('\n');
    expect(lines.length, greaterThan(5000));
    final headings = lines.where((l) => l.startsWith('#')).toList();
    expect(headings.length, equals(399));

    // WebP画像リンクの確認
    expect(content.contains('asset:assets/images/spoiler_dmap_jp.webp'), isTrue);
    expect(content.contains('asset:assets/images/spoiler_flowchart_jp.webp'), isTrue);

    // 重要な定訳の確認
    expect(content.contains('祝福された 油が塗られた 錆びない +2 灰色ドラゴンの鱗鎧'), isTrue);
    expect(content.contains('変身(へんげ)'), isTrue);
    expect(content.contains('さまよう目'), isTrue);
    expect(content.contains('水のニンフ'), isTrue);
  });
}

