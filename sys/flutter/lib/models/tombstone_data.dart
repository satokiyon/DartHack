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

    int nameIndex = lines.indexWhere((line) => line.contains('|'));
    if (nameIndex == -1) {
      nameIndex = 6;
    }

    final name = lines.length > nameIndex ? clean(lines[nameIndex]) : "";
    final gold = lines.length > nameIndex + 1 ? clean(lines[nameIndex + 1]) : "";
    final deathLines = <String>[];
    for (int i = nameIndex + 2; i <= nameIndex + 5; i++) {
      if (lines.length > i) {
        final c = clean(lines[i]);
        if (c.isNotEmpty && c != "." && c != "...") {
          deathLines.add(c);
        }
      }
    }
    final year = lines.length > nameIndex + 6 ? clean(lines[nameIndex + 6]) : "";

    return TombstoneData(
      name: name,
      gold: gold,
      deathLines: deathLines,
      year: year,
    );
  }
}
