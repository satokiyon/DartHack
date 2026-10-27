import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

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
    expect(content.contains('**A Traveler\'s Companion to the Mazes of Menace**'), isTrue);
    expect(content.contains('NetHack is among the oldest computer games still actively maintained'), isTrue);
    expect(content.contains('blessed greased fixed +2 gray dragon scale mail'), isTrue);
    expect(content.contains('floating eye'), isTrue);
    expect(content.contains('water nymph'), isTrue);

    // 内部アンカーリンクの解決検証
    final linkMatches = RegExp(r'\]\(#([a-zA-Z0-9_.-]+)\)').allMatches(content);
    final linkTargets = linkMatches.map((m) => m.group(1)!).toSet();
    expect(linkTargets.length, greaterThan(150));

    // 全てのリンク先アンカーが本文中に {#anchor} として存在することを確認
    final anchorMatches = RegExp(r'\{#([a-zA-Z0-9_.-]+)').allMatches(content);
    final availableAnchors = anchorMatches.map((m) => m.group(1)!).toSet();

    for (final target in linkTargets) {
      expect(
        availableAnchors.contains(target),
        isTrue,
        reason: 'Anchor link "#$target" must exist in companion.md',
      );
    }

    // ユーザー報告の特定アンカーが存在することを確認
    expect(availableAnchors.contains('the-gnomish-mines'), isTrue);
    expect(availableAnchors.contains('delayed-deaths'), isTrue);

    // 非Markdown残骸（HTMLタグ・スクリプト・ツールバー等）が存在しないことを検証
    expect(content.contains('price-id-toolbar'), isFalse, reason: 'price-id-toolbar must not exist');
    expect(content.contains('<script'), isFalse, reason: '<script> must not exist');
    expect(content.contains('</script>'), isFalse, reason: '</script> must not exist');
    expect(content.contains('<div'), isFalse, reason: '<div> must not exist');
    expect(content.contains('<button'), isFalse, reason: '<button> must not exist');
    expect(content.contains('<small'), isFalse, reason: '<small> must not exist');
    expect(content.contains('Use the Cha/Sell/Tourist/Angry toolbar'), isFalse, reason: 'Toolbar mention must not exist');
  });
}

