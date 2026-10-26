import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

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

    // 内部アンカーリンクの解決検証
    final linkMatches = RegExp(r'\]\(#([a-zA-Z0-9_.-]+)\)').allMatches(content);
    final linkTargets = linkMatches.map((m) => m.group(1)!).toSet();
    expect(linkTargets.length, greaterThan(150));

    final anchorMatches = RegExp(r'\{#([a-zA-Z0-9_.-]+)').allMatches(content);
    final availableAnchors = anchorMatches.map((m) => m.group(1)!).toSet();

    for (final target in linkTargets) {
      expect(
        availableAnchors.contains(target),
        isTrue,
        reason: 'Anchor link "#$target" must exist in companion.jp.md',
      );
    }

    // 特定アンカーが存在することを確認
    expect(availableAnchors.contains('the-gnomish-mines'), isTrue);
    expect(availableAnchors.contains('delayed-deaths'), isTrue);

    // 非Markdown残骸（HTMLタグ・スクリプト・ツールバー等）が存在しないことを検証
    expect(content.contains('price-id-toolbar'), isFalse, reason: 'price-id-toolbar must not exist');
    expect(content.contains('<script'), isFalse, reason: '<script> must not exist');
    expect(content.contains('</script>'), isFalse, reason: '</script> must not exist');
    expect(content.contains('<div'), isFalse, reason: '<div> must not exist');
    expect(content.contains('<button'), isFalse, reason: '<button> must not exist');
    expect(content.contains('<small'), isFalse, reason: '<small> must not exist');
    expect(content.contains('魅力 / 売却 / 観光客 / 激怒ツールバー'), isFalse, reason: 'Toolbar mention must not exist');
  });
}

