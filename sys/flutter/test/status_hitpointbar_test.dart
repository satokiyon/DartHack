import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/main.dart';

void main() {
  group('parseStatusLine tests', () {
    test('HPバーなしの通常ステータス行をパースできること', () {
      const line = r'Player-Val-Hum-Fem-Neu \C0000000FSt:18\c Dx:15';
      final span = parseStatusLine(line);

      expect(span, isA<TextSpan>());
      final textSpan = span;
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, greaterThanOrEqualTo(2));
      // WidgetSpan は含まれないこと
      expect(textSpan.children!.any((s) => s is WidgetSpan), isFalse);
    });

    test(r'HPバーマークアップ \B... をパースして WidgetSpan が生成されること', () {
      const line = r'\B0000000A,085:Player 巫女\b \C0000000F強:18\c';
      final span = parseStatusLine(line);

      expect(span, isA<TextSpan>());
      final children = span.children!;
      // 最初の要素が WidgetSpan (HPバー) であること
      expect(children.first, isA<WidgetSpan>());

      final widgetSpan = children.first as WidgetSpan;
      expect(widgetSpan.alignment, equals(PlaceholderAlignment.middle));

      // WidgetSpan の child 検証
      expect(widgetSpan.child, isA<ConstrainedBox>());
      final box = widgetSpan.child as ConstrainedBox;
      expect(box.constraints.minWidth, equals(100.0));

      expect(box.child, isA<Stack>());
      final stack = box.child as Stack;
      // ベースレイヤー（黒背景＋白文字）とクリップレイヤー（バー色＋黒文字）の2つが存在
      expect(stack.children.length, equals(2));

      // ベースレイヤーの検証
      expect(stack.children[0], isA<Container>());
      final baseContainer = stack.children[0] as Container;
      expect(baseContainer.color, equals(Colors.black));
      expect(baseContainer.child, isA<Text>());
      final baseText = baseContainer.child as Text;
      expect(baseText.data, equals('Player 巫女'));
      expect(baseText.style?.color, equals(Colors.white));

      // クリップレイヤーの検証 (85% > 0 なので存在)
      expect(stack.children[1], isA<Positioned>());
      final positioned = stack.children[1] as Positioned;
      expect(positioned.child, isA<ClipRect>());
      final clipRect = positioned.child as ClipRect;
      expect(clipRect.clipper, isA<HpBarClipper>());
      final clipper = clipRect.clipper as HpBarClipper;
      expect(clipper.fraction, closeTo(0.85, 0.001));

      final clipContainer = clipRect.child as Container;
      expect(clipContainer.child, isA<Text>());
      final clipText = clipContainer.child as Text;
      expect(clipText.data, equals('Player 巫女'));
      expect(clipText.style?.color, equals(Colors.black));
    });

    test('HPが 0% の場合、クリップレイヤーが生成されないこと', () {
      const line = r'\B00000001,000:DeadPlayer 僧侶\b';
      final span = parseStatusLine(line);

      final widgetSpan = span.children!.first as WidgetSpan;
      final box = widgetSpan.child as ConstrainedBox;
      final stack = box.child as Stack;
      // 0% の場合はクリップレイヤーがなく、ベースレイヤーのみ（1つ）
      expect(stack.children.length, equals(1));
    });

    test('HPパーセントが範囲外（負数や100超過）でも正常にクランプされること', () {
      // 150% の場合 -> 100% にクランプ
      const lineOver = r'\B0000000A,150:BoostPlayer\b';
      final spanOver = parseStatusLine(lineOver);
      final widgetSpanOver = spanOver.children!.first as WidgetSpan;
      final stackOver = (widgetSpanOver.child as ConstrainedBox).child as Stack;
      final clipRectOver = (stackOver.children[1] as Positioned).child as ClipRect;
      expect((clipRectOver.clipper as HpBarClipper).fraction, equals(1.0));
    });

    test('HpBarClipper が正確なクリップ領域を計算すること', () {
      const clipper = HpBarClipper(0.60);
      const size = Size(200.0, 30.0);
      final rect = clipper.getClip(size);

      expect(rect.left, equals(0.0));
      expect(rect.top, equals(0.0));
      expect(rect.width, closeTo(120.0, 0.001));
      expect(rect.height, equals(30.0));

      expect(clipper.shouldReclip(const HpBarClipper(0.60)), isFalse);
      expect(clipper.shouldReclip(const HpBarClipper(0.50)), isTrue);
    });
  });
}
