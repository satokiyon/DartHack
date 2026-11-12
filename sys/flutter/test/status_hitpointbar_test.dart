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

    test('parseStatusLine に fontSize を指定するとテキストとHPバーがスケールすること', () {
      const line = r'\B0000000A,050:Hero\b \C0000000FSt:18\c';
      final span = parseStatusLine(line, fontSize: 26.0);

      expect(span.style?.fontSize, equals(26.0));
      final widgetSpan = span.children!.first as WidgetSpan;
      final box = widgetSpan.child as ConstrainedBox;
      expect(box.constraints.minWidth, closeTo(200.0, 0.001));

      final stack = box.child as Stack;
      final baseText = (stack.children[0] as Container).child as Text;
      expect(baseText.style?.fontSize, equals(26.0));

      final clipText = ((stack.children[1] as Positioned).child as ClipRect).child as Container;
      expect((clipText.child as Text).style?.fontSize, equals(26.0));
    });

    test(r'\Lequipment:...\l がアンダーライン付きの WidgetSpan になりタップコールバックと色引き継ぎが動くこと', () {
      bool eqTapped = false;
      const line =
          r'\C0000000ADlvl:1\c \Lequipment:\C0000000E武器:ロングソード(+1)\c\l \C0000000B地形:床\c';
      final span = parseStatusLine(
        line,
        fontSize: 16.0,
        onEquipmentTap: () => eqTapped = true,
      );

      final widgetSpans = span.children!.whereType<WidgetSpan>().toList();
      expect(widgetSpans.length, equals(1));
      final eqGesture = widgetSpans.first.child as GestureDetector;
      expect(eqGesture.onTap, isNotNull);
      eqGesture.onTap!();
      expect(eqTapped, isTrue);

      final innerText = eqGesture.child as Text;
      expect(innerText.style?.decoration, equals(TextDecoration.underline));
      expect(innerText.style?.decorationStyle, equals(TextDecorationStyle.dotted));
      expect(innerText.textSpan?.toPlainText(), equals('武器:ロングソード(+1)'));

      // \L...\l 末尾の \c によって文字色が白へ戻り、次の地形色 \C0000000B (シアン等) が正しく解釈されること
      final textSpans = span.children!.whereType<TextSpan>().toList();
      expect(textSpans.any((t) => (t.text ?? '').contains('地形:床')), isTrue);
    });

    test('超コンパクト1行形式のステータス文字列が正しくパースされること', () {
      const line = r'Dlvl:1 \B0000000A,075:HP:12/16\b \C0000000CPw:5/5\c AC:6 \C0000000AXp:2\c 空腹 盲目';
      final span = parseStatusLine(line);
      final widgetSpans = span.children!.whereType<WidgetSpan>().toList();
      expect(widgetSpans.length, equals(1));

      final stack = (widgetSpans.first.child as ConstrainedBox).child as Stack;
      final baseText = (stack.children[0] as Container).child as Text;
      expect(baseText.data, equals('HP:12/16'));

      final plainParts = span.children!.whereType<TextSpan>().map((t) => t.text ?? '').join();
      expect(plainParts, contains('Dlvl:1 '));
      expect(plainParts, contains('Pw:5/5'));
      expect(plainParts, contains('AC:6'));
      expect(plainParts, contains('Xp:2'));
      expect(plainParts, contains('空腹'));
      expect(plainParts, contains('盲目'));
    });

    test('splitVerticalStatusFields がマークアップ内や空白入り地形名を分割せずアクティブ色を引き継ぐこと', () {
      final fields = splitVerticalStatusFields([
        r'\B0000000A,100:主人公 若き盾乙女\b \C0000000E筋力:18 体力:12(16)\c',
        r' \Lequipment:\C0000000B武器:ロングソード (+1)\c\l  \C0000000A地形:浅い 海\c',
      ]);

      expect(fields.length, equals(5));
      expect(fields[0], equals(r'\B0000000A,100:主人公 若き盾乙女\b'));
      expect(fields[1], equals(r'\C0000000E筋力:18'));
      // 直前のアクティブ色 \C0000000E が引き継がれること
      expect(fields[2], equals(r'\C0000000E体力:12(16)\c'));
      expect(fields[3], equals(r'\Lequipment:\C0000000B武器:ロングソード (+1)\c\l'));
      expect(fields[4], equals(r'\C0000000A地形:浅い 海\c'));
    });

    test('splitVerticalStatusFields が Dlvl:1 と直後の \\B マークアップおよび空腹・盲目・階層:1 を正しく分割すること', () {
      final compactFields = splitVerticalStatusFields([
        r'Dlvl:1 \B0000000A,100:HP:12/16\b \C0000000CPw:5/5\c AC:6 Xp:2 空腹 盲目',
      ]);

      expect(compactFields.length, equals(7));
      expect(compactFields[0], equals('Dlvl:1'));
      expect(compactFields[1], equals(r'\B0000000A,100:HP:12/16\b'));
      expect(compactFields[2], equals(r'\C0000000CPw:5/5\c'));
      expect(compactFields[3], equals('AC:6'));
      expect(compactFields[4], equals('Xp:2'));
      expect(compactFields[5], equals('空腹'));
      expect(compactFields[6], equals('盲目'));

      final standardFields = splitVerticalStatusFields([
        r'階層:1 $:50 体力:12(16) 魔力:5(5) 空腹 盲目',
      ]);
      expect(standardFields, equals(['階層:1', r'$:50', '体力:12(16)', '魔力:5(5)', '空腹', '盲目']));
    });
  });
}
