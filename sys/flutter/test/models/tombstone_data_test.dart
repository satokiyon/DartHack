import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/models/tombstone_data.dart';

void main() {
  group('TombstoneData.parse tests', () {
    test('parses tombstone lines with leading blank line (C-core output)', () {
      final lines = [
        "", // 先頭空行
        "                       ----------",
        "                      /          \\",
        "                     /    REST    \\",
        "                    /      IN      \\",
        "                   /     PEACE      \\",
        "                  /                  \\",
        "                  |      satok       |",
        "                  |     1000 Au      |",
        "                  |  killed by a...  |",
        "                  |     newt.        |",
        "                  |                  |",
        "                  |                  |",
        "                  |       2026       |",
        "                 *|     *  *  *      | *",
        "        _________)/\\\\_//(\\/(/\\)/\\//\\/|_)_______",
      ];

      final data = TombstoneData.parse(lines);

      expect(data.name, equals("satok"));
      expect(data.gold, equals("1000 Au"));
      expect(data.deathLines, equals(["killed by a...", "newt."]));
      expect(data.year, equals("2026"));
    });

    test('parses tombstone lines without leading blank line', () {
      final lines = [
        "                       ----------",
        "                      /          \\",
        "                     /    REST    \\",
        "                    /      IN      \\",
        "                   /     PEACE      \\",
        "                  /                  \\",
        "                  |     Hero        |",
        "                  |     500 Au       |",
        "                  |    quit.         |",
        "                  |                  |",
        "                  |                  |",
        "                  |                  |",
        "                  |       2025       |",
        "                 *|     *  *  *      | *",
        "        _________)/\\\\_//(\\/(/\\)/\\//\\/|_)_______",
      ];

      final data = TombstoneData.parse(lines);

      expect(data.name, equals("Hero"));
      expect(data.gold, equals("500 Au"));
      expect(data.deathLines, equals(["quit."]));
      expect(data.year, equals("2025"));
    });
  });
}
