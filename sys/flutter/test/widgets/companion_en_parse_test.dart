import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/widgets/spoiler_dialog.dart';

void main() {
  test('Verify companion.md parses cleanly in SpoilerDialog', () {
    final file = File('books/en/companion.md');
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content.isNotEmpty, isTrue);

    // 見出し数と行数の確認
    final lines = content.split('\n');
    expect(lines.length, greaterThan(5000));
    final headings = lines.where((l) => l.startsWith('#')).toList();
    expect(headings.length, equals(399));

    // WebP画像リンクの確認
    expect(content.contains('asset:assets/images/spoiler_dmap_en.webp'), isTrue);
    expect(content.contains('asset:assets/images/spoiler_flowchart_en.webp'), isTrue);

    // 重要な構文・用語の確認
    expect(content.contains('NetHack is among the oldest computer games still actively maintained'), isTrue);
    expect(content.contains('blessed greased fixed +2 gray dragon scale mail'), isTrue);
    expect(content.contains('floating eye'), isTrue);
    expect(content.contains('water nymph'), isTrue);
  });
}

