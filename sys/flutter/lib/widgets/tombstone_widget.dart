import 'package:flutter/material.dart';
import '../models/tombstone_data.dart';

class UniversalTombstoneWidget extends StatelessWidget {
  final TombstoneDisplayMode mode;
  final TombstoneData? data;
  final List<String>? lines;

  const UniversalTombstoneWidget({
    super.key,
    this.mode = TombstoneDisplayMode.image,
    this.data,
    this.lines,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            source.join('\n'),
            softWrap: false,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.white,
              height: 1.25,
            ),
          ),
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
