import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/font_manager.dart';
import '../utils/nethack_colors.dart';

/// 水平配置のステータスバー描画とタップ（属性／装備一覧）／長押しハンドリングを担当するウィジェット
class StatusBarInteractiveView extends StatelessWidget {
  final List<String> statusLines;
  final int statusDisplayMode;
  final double statusFontSize;
  final VoidCallback? onStatusTap;
  final VoidCallback? onEquipmentTap;

  const StatusBarInteractiveView({
    super.key,
    required this.statusLines,
    required this.statusDisplayMode,
    required this.statusFontSize,
    this.onStatusTap,
    this.onEquipmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawVisibleLines = statusLines.where((l) => l.trim().isNotEmpty).toList();
    final visibleLines = rawVisibleLines.isEmpty ? const [''] : rawVisibleLines;
    final activeLineCount = math.max(1, visibleLines.length);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxFitHeight = (screenHeight * 0.28).clamp(60.0, 240.0);
    final fitStatusHeight =
        (statusFontSize * 1.38 * activeLineCount + 6.0).clamp(24.0, maxFitHeight);

    final children = <InlineSpan>[];
    for (int i = 0; i < visibleLines.length; i++) {
      if (i > 0) {
        children.add(const TextSpan(text: '\n'));
      }
      children.add(parseStatusLine(
        visibleLines[i],
        fontSize: statusFontSize,
        onEquipmentTap: onEquipmentTap,
      ));
    }
    final richContent = Text.rich(TextSpan(children: children));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onStatusTap,
      onLongPress: onEquipmentTap,
      child: statusDisplayMode == 0
          ? Container(
              height: fitStatusHeight,
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: richContent,
              ),
            )
          : Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: richContent,
            ),
    );
  }
}

/// HPバーのクリッピング領域を計算する CustomClipper
class HpBarClipper extends CustomClipper<Rect> {
  final double fraction;
  const HpBarClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(HpBarClipper oldClipper) => oldClipper.fraction != fraction;
}

/// 縦パネル表示用に、マークアップ (\B...\b, \L...\l, \C..., \c) を壊さずにステータス行を項目ごとに分割する
List<String> splitVerticalStatusFields(List<String> statusLines) {
  final result = <String>[];
  final labelStartPattern = RegExp(
    r'^(?:\\C[0-9a-fA-F]{8}|\\c)*(?:\\B|\\L[a-zA-Z0-9_]+:|筋力:|器用:|耐久:|知力:|賢明:|魅力:|属性:|金貨:|体力:|魔力:|防御\(AC\):|防御:|レベル:|得点:|ターン:|階層:|迷宮:|地形:|状態:|空腹|衰弱|飢餓|満腹|満腹すぎ|重荷|過負荷|大過負荷|極過負荷|超過負荷|盲目|難聴|混乱|幻覚|HP:|MP:|AC:|Lv:|HD:|St:|Dx:|Co:|In:|Wi:|Ch:|Law|Neu|Cha|\$:|Pw:|Xp:|T:|S:|Dlvl:|Hungry|Weak|Fainting|Satiated|Burdened|Stressed|Strained|Overtaxed|Overloaded|Blnd|Blind)',
  );
  final colorTokenRegex = RegExp(r'\\C([0-9a-fA-F]{8})|\\c');

  for (final rawLine in statusLines) {
    for (final line in rawLine.split(RegExp(r'[\n\r]+'))) {
      if (line.trim().isEmpty) continue;

      final parts = <String>[];
      final buffer = StringBuffer();
      String activeColorCode = '';
      int i = 0;

      void flushPart() {
        final s = buffer.toString().trim();
        buffer.clear();
        if (s.isNotEmpty) {
          parts.add(s);
          if (activeColorCode.isNotEmpty) {
            buffer.write(activeColorCode);
          }
        }
      }

      while (i < line.length) {
        if (line.startsWith(r'\B', i)) {
          final end = line.indexOf(r'\b', i + 2);
          if (end != -1) {
            buffer.write(line.substring(i, end + 2));
            i = end + 2;
            continue;
          }
        } else if (line.startsWith(r'\L', i)) {
          final end = line.indexOf(r'\l', i + 2);
          if (end != -1) {
            final segment = line.substring(i, end + 2);
            buffer.write(segment);
            for (final m in colorTokenRegex.allMatches(segment)) {
              activeColorCode = m.group(0) == r'\c' ? '' : m.group(0)!;
            }
            i = end + 2;
            continue;
          }
        } else if (line.startsWith(r'\C', i) && i + 10 <= line.length) {
          final code = line.substring(i, i + 10);
          if (RegExp(r'^\\C[0-9a-fA-F]{8}$').hasMatch(code)) {
            activeColorCode = code;
            buffer.write(code);
            i += 10;
            continue;
          }
        } else if (line.startsWith(r'\c', i)) {
          activeColorCode = '';
          buffer.write(r'\c');
          i += 2;
          continue;
        }

        if (line[i] == ' ' || line[i] == '\t') {
          int spaceEnd = i;
          while (spaceEnd < line.length && (line[spaceEnd] == ' ' || line[spaceEnd] == '\t')) {
            spaceEnd++;
          }
          final spaceCount = spaceEnd - i;
          final rest = line.substring(spaceEnd);
          final hasContentBefore =
              buffer.toString().replaceAll(colorTokenRegex, '').trim().isNotEmpty;
          if (hasContentBefore &&
              (spaceCount >= 2 || (rest.isNotEmpty && labelStartPattern.hasMatch(rest)))) {
            flushPart();
            i = spaceEnd;
            continue;
          }
          buffer.write(line.substring(i, spaceEnd));
          i = spaceEnd;
          continue;
        }

        buffer.write(line[i]);
        i++;
      }

      final tail = buffer.toString();
      if (tail.replaceAll(colorTokenRegex, '').trim().isNotEmpty) {
        parts.add(tail.trim());
      }
      result.addAll(parts);
    }
  }
  return result;
}

/// 文字列内の \CXXXXXXXX と \c を解釈し、TextSpan リストと最終アクティブ色を返す
(List<InlineSpan>, Color) _parseColorCodedSpans(
  String text, {
  required Color initialColor,
}) {
  final spans = <InlineSpan>[];
  final colorRegex = RegExp(r'\\C([0-9a-fA-F]{8})|\\c');
  int lastIndex = 0;
  Color currentColor = initialColor;

  for (final m in colorRegex.allMatches(text)) {
    if (m.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, m.start),
        style: TextStyle(color: currentColor),
      ));
    }
    if (m.group(0) == r'\c') {
      currentColor = Colors.white;
    } else if (m.group(1) != null) {
      final colorIndex = int.tryParse(m.group(1)!, radix: 16) ?? 15;
      currentColor = NethackColors.getNhColor(colorIndex);
    }
    lastIndex = m.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: TextStyle(color: currentColor),
    ));
  }
  return (spans, currentColor);
}

/// ステータス行の `\CXXXXXXXX`, `\c`, `\BXXXXXXXX,PPP:...\b`, `\L<action>:...\l` マークアップパース処理
TextSpan parseStatusLine(
  String line, {
  double fontSize = 13.0,
  VoidCallback? onEquipmentTap,
}) {
  // 1. まず、金貨のエスケープ \G が残っていれば $: に置換する (フォールバック)
  final processedLine = line.replaceAll(RegExp(r'\\G([0-9a-fA-F]{8}):?'), '\$:');

  // 2. マークアップをパースして TextSpan を構築
  // \BXXXXXXXX,PPP:...\b (HPバー), \L<action>:...\l (インタラクティブ領域), \CXXXXXXXX, \c
  final spans = <InlineSpan>[];
  final regex = RegExp(
    r'\\B([0-9a-fA-F]{8}),([0-9]{1,3}):(.*?)\\b|\\L([a-zA-Z0-9_]+):(.*?)\\l|\\C([0-9a-fA-F]{8})|\\c',
  );

  int lastIndex = 0;
  Color currentColor = Colors.white;

  for (final match in regex.allMatches(processedLine)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: processedLine.substring(lastIndex, match.start),
        style: TextStyle(color: currentColor),
      ));
    }

    final matchedText = match.group(0);
    if (matchedText == '\\c') {
      currentColor = Colors.white;
    } else if (match.group(1) != null && match.group(2) != null && match.group(3) != null) {
      // HPバーマークアップ: \B<color8>,<percent3>:<titleText>\b
      final hexStr = match.group(1)!;
      final percent = (int.tryParse(match.group(2)!) ?? 100).clamp(0, 100);
      final titleText = match.group(3)!;
      final colorIndex = int.tryParse(hexStr, radix: 16) ?? 15;
      final barColor = NethackColors.getNhColor(colorIndex);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 100.0 * (fontSize / 13.0)),
            child: Stack(
              children: [
                // 1. ベースレイヤー: 黒背景 + 通常白文字
                Container(
                  color: Colors.black,
                  child: Text(
                    titleText,
                    style: FontManager.instance.getStyle(
                      FontTarget.status,
                      fontSize: fontSize,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 2. クリップレイヤー: HP% 幅だけクリッピング + バー色背景 + 反転黒文字
                if (percent > 0)
                  Positioned.fill(
                    child: ClipRect(
                      clipper: HpBarClipper(percent / 100.0),
                      child: Container(
                        color: barColor,
                        child: Text(
                          titleText,
                          style: FontManager.instance.getStyle(
                            FontTarget.status,
                            fontSize: fontSize,
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else if (match.group(4) != null && match.group(5) != null) {
      // \L<action>:<bodyWithColorMarkup>\l インタラクティブ領域（武器・防具ステータス等）
      final action = match.group(4)!;
      final body = match.group(5)!;
      final (innerSpans, updatedColor) =
          _parseColorCodedSpans(body, initialColor: currentColor);
      currentColor = updatedColor;

      final VoidCallback? spanTap = action == 'equipment' ? onEquipmentTap : null;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: spanTap,
            child: Text.rich(
              TextSpan(children: innerSpans),
              style: FontManager.instance
                  .getStyle(
                    FontTarget.status,
                    fontSize: fontSize,
                  )
                  .copyWith(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: Colors.amberAccent.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ),
      );
    } else if (match.group(6) != null) {
      // 通常の \CXXXXXXXX 文字色マークアップ
      final hexStr = match.group(6)!;
      final colorIndex = int.tryParse(hexStr, radix: 16) ?? 15;
      currentColor = NethackColors.getNhColor(colorIndex);
    }

    lastIndex = match.end;
  }

  if (lastIndex < processedLine.length) {
    spans.add(TextSpan(
      text: processedLine.substring(lastIndex),
      style: TextStyle(color: currentColor),
    ));
  }

  return TextSpan(
    style: FontManager.instance.getStyle(
      FontTarget.status,
      fontSize: fontSize,
    ),
    children: spans,
  );
}
