import 'package:flutter/material.dart';
import '../models/tombstone_data.dart';

/// 墓石 ASCII アートを等幅枠＋固定幅ボックス内通常日本語フォント中央揃えで描画する共通ウィジェット。
/// 日本語死因行でも右枠 `|` が一切ズレず一直線に揃う。
class TombstoneAsciiView extends StatelessWidget {
  static final RegExp _tombWallRegExp = RegExp(r'^([^|]*\|)(.*)(\|[^|]*)$');
  static final RegExp _asciiOnlyRegExp = RegExp(r'^[\x00-\x7F]*$');

  final List<String> lines;
  final double fontSize;
  final ScrollController? horizontalController;
  final bool dedent;
  final EdgeInsetsGeometry scrollPadding;

  const TombstoneAsciiView({
    super.key,
    required this.lines,
    this.fontSize = 11.5,
    this.horizontalController,
    this.dedent = true,
    this.scrollPadding = const EdgeInsets.only(bottom: 10),
  });

  static List<String> _dedentLines(List<String> source) {
    int? minSpaces;
    for (final line in source) {
      if (line.trim().isEmpty) continue;
      int count = 0;
      while (count < line.length && line.codeUnitAt(count) == 0x20) {
        count++;
      }
      if (minSpaces == null || count < minSpaces) {
        minSpaces = count;
      }
    }
    if (minSpaces == null || minSpaces <= 0) return source;
    final cut = minSpaces;
    return source
        .map((line) => line.length >= cut ? line.substring(cut) : line.trimLeft())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayLines = dedent ? _dedentLines(lines) : lines;
    final monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.25,
      color: Colors.white,
    );

    // 墓石内の ASCII のみで構成された |...| 行から内枠カラム数（標準 18）を取得
    int innerCols = 18;
    for (final line in displayLines) {
      if (line.contains('____')) continue;
      final m = _tombWallRegExp.firstMatch(line);
      if (m != null && _asciiOnlyRegExp.hasMatch(m.group(2)!)) {
        innerCols = m.group(2)!.length;
        break;
      }
    }

    // DefaultTextStyle をマージし、行末空白トリミングを避けるため非空白文字で実測
    final effectiveMonoStyle = DefaultTextStyle.of(context).style.merge(monoStyle);
    final textScaler = MediaQuery.textScalerOf(context);
    final tp = TextPainter(
      text: TextSpan(text: 'M' * innerCols, style: effectiveMonoStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final innerWidth = tp.width;
    final lineHeight = tp.height;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayLines.map((line) {
        if (!line.contains('____') && !line.trimLeft().startsWith('*|')) {
          final m = _tombWallRegExp.firstMatch(line);
          if (m != null) {
            final leftPart = m.group(1)!;
            final innerRaw = m.group(2)!;
            final rightPart = m.group(3)!;
            final innerText = innerRaw.trim();
            // 非 ASCII 文字を含む行は通常フォント（FontTarget.menu 等）で固定幅中央揃え
            if (!_asciiOnlyRegExp.hasMatch(innerRaw)) {
              return SizedBox(
                height: lineHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(leftPart, softWrap: false, style: monoStyle),
                    SizedBox(
                      width: innerWidth,
                      height: lineHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            innerText,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize,
                              height: 1.25,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(rightPart, softWrap: false, style: monoStyle),
                  ],
                ),
              );
            }
          }
        }
        return Text(line, softWrap: false, style: monoStyle);
      }).toList(),
    );

    final scrollView = SingleChildScrollView(
      controller: horizontalController,
      scrollDirection: Axis.horizontal,
      padding: scrollPadding,
      child: content,
    );

    if (horizontalController != null) {
      return Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        child: scrollView,
      );
    }
    return scrollView;
  }
}

class UniversalTombstoneWidget extends StatelessWidget {
  final TombstoneDisplayMode mode;
  final TombstoneData? data;
  final List<String>? lines;
  final ScrollController? scrollController;

  const UniversalTombstoneWidget({
    super.key,
    this.mode = TombstoneDisplayMode.image,
    this.data,
    this.lines,
    this.scrollController,
  }) : assert(
          mode == TombstoneDisplayMode.image ? data != null : lines != null,
          'image mode requires data, text mode requires lines',
        );

  @override
  Widget build(BuildContext context) {
    if (mode == TombstoneDisplayMode.text) {
      return _buildTextMode();
    }
    return _buildImageMode(context);
  }

  Widget _buildTextMode() {
    final source = lines ?? const <String>[];
    final bottomIndex = source.indexWhere((line) => line.contains('_________'));
    final List<String> tombstoneLines;
    final List<String> belowLines;
    if (bottomIndex >= 0) {
      tombstoneLines = source.sublist(0, bottomIndex + 1);
      final rest = source.length > bottomIndex + 1
          ? List<String>.from(source.sublist(bottomIndex + 1))
          : <String>[];
      while (rest.isNotEmpty && rest.first.trim().isEmpty) {
        rest.removeAt(0);
      }
      while (rest.isNotEmpty && rest.last.trim().isEmpty) {
        rest.removeLast();
      }
      belowLines = rest;
    } else {
      tombstoneLines = source;
      belowLines = const [];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: TombstoneAsciiView(
                lines: tombstoneLines,
                fontSize: 12.0,
                dedent: true,
                scrollPadding: EdgeInsets.zero,
              ),
            ),
            if (belowLines.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                belowLines.join('\n'),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageMode(BuildContext context) {
    final d = data!;
    final source = lines ?? const <String>[];

    // 墓石アスキーアートの芝生部分（底辺）のインデックスを探す
    int bottomIndex = source.indexWhere((line) => line.contains('_________'));
    if (bottomIndex == -1) {
      bottomIndex = 14;
    }

    // 底辺以降のテキストを取得
    List<String> belowTombstoneLines = [];
    if (source.length > bottomIndex + 1) {
      belowTombstoneLines = source.sublist(bottomIndex + 1);
    }

    // トリミング：先頭と末尾の空行を削除
    while (belowTombstoneLines.isNotEmpty && belowTombstoneLines.first.trim().isEmpty) {
      belowTombstoneLines.removeAt(0);
    }
    while (belowTombstoneLines.isNotEmpty && belowTombstoneLines.last.trim().isEmpty) {
      belowTombstoneLines.removeLast();
    }

    final belowTombstoneText = belowTombstoneLines.join('\n');

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/tombstone.webp',
                        cacheWidth: (400 * MediaQuery.of(context).devicePixelRatio).round(),
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: MediaQuery.withNoTextScaling(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;
                            final scale = width / 400;

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: width * 0.12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: height * 0.32),
                                  Text(
                                    d.name,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 20 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFCCCCCC),
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: height * 0.02),
                                  Text(
                                    d.gold,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 16 * scale,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB0B0B0),
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black.withValues(alpha: 0.8),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: height * 0.03),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        ...d.deathLines.map((line) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text(
                                              line,
                                              style: TextStyle(
                                                fontFamily: 'serif',
                                                fontSize: 13 * scale,
                                                fontWeight: FontWeight.normal,
                                                color: const Color(0xFFAAAAAA),
                                                height: 1.3,
                                                shadows: [
                                                  const Shadow(
                                                   offset: Offset(1, 1),
                                                   blurRadius: 1.5,
                                                   color: Color(0xCC000000),
                                                 ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                        if (d.year.isNotEmpty) ...[
                                          SizedBox(height: 6 * scale),
                                          Text(
                                            d.year,
                                            style: TextStyle(
                                              fontFamily: 'serif',
                                              fontSize: 14 * scale,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF999999),
                                              shadows: [
                                                const Shadow(
                                                  offset: Offset(1, 1),
                                                  blurRadius: 1.5,
                                                  color: Color(0xCC000000),
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: height * 0.30),
                                ],
                              ),
                            );
                          },
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (belowTombstoneText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: SelectableText(
                    belowTombstoneText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
