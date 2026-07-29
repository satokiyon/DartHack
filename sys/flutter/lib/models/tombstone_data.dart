enum TombstoneDisplayMode {
  image,
  text,
}

class TombstoneData {
  final String name;
  final String gold;
  final List<String> deathLines;
  final String year;

  TombstoneData({
    required this.name,
    required this.gold,
    required this.deathLines,
    required this.year,
  });

  factory TombstoneData.parse(List<String> lines) {
    String clean(String line) {
      var content = line;
      if (line.contains('|')) {
        final parts = line.split('|');
        if (parts.length >= 3) {
          content = parts[1];
        } else {
          content = line.replaceAll('|', '');
        }
      }
      return content.trim();
    }

    final name = lines.length > 6 ? clean(lines[6]) : "";
    final gold = lines.length > 7 ? clean(lines[7]) : "";
    final deathLines = <String>[];
    for (int i = 8; i <= 11; i++) {
      if (lines.length > i) {
        final c = clean(lines[i]);
        if (c.isNotEmpty && c != "." && c != "...") {
          deathLines.add(c);
        }
      }
    }
    final year = lines.length > 12 ? clean(lines[12]) : "";

    return TombstoneData(
      name: name,
      gold: gold,
      deathLines: deathLines,
      year: year,
    );
  }
}
