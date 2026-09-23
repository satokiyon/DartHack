/// BGM・効果音クレジット用エントリおよびパーサー
class SoundCreditEntry {
  final String fileName;
  final String description;
  final String sourceName;
  final String author;
  final String license;
  final String notes;
  final String url;

  const SoundCreditEntry({
    required this.fileName,
    required this.description,
    required this.sourceName,
    required this.author,
    required this.license,
    required this.notes,
    required this.url,
  });

  @override
  String toString() {
    return 'SoundCreditEntry(file: $fileName, source: $sourceName, author: $author)';
  }
}

/// attributions.txt を解析して提供元ごとにグループ化するパーサー
class SoundCreditParser {
  /// attributions.txt のテキストを解析し、提供元名ごとにグループ化したマップを返す
  static Map<String, List<SoundCreditEntry>> parse(String text) {
    final Map<String, List<SoundCreditEntry>> grouped = {};
    final lines = text.split('\n');

    String? currentFile;
    String? currentDesc;
    String? currentSource;
    String? currentAuthor;
    String? currentLicense;
    String? currentNotes;

    void commitEntry() {
      if (currentFile == null || currentFile!.trim().isEmpty) {
        return;
      }

      // 出典名とURLの解析: "サイト名 (https://...)" または "サイト名 ()"
      String rawSource = currentSource?.trim() ?? '';
      String sourceName = rawSource;
      String url = '';

      final match = RegExp(r'^(.*?)\s*\((https?://[^\)]*|\s*)\)$').firstMatch(rawSource);
      if (match != null) {
        sourceName = match.group(1)?.trim() ?? '';
        url = match.group(2)?.trim() ?? '';
      }

      // 自作音源（クレジット対象外）はスキップ
      if (sourceName.contains('自作') && url.isEmpty) {
        return;
      }

      // 提供元名が空または「その他」の場合、URLからドメイン・サイト名を解決
      if (sourceName.isEmpty || sourceName.contains('その他') || sourceName == 'Unknown') {
        if (url.contains('gemini.google.com')) {
          sourceName = 'Google Gemini (AI生成)';
        } else if (url.contains('creatorchords.com')) {
          sourceName = 'CreatorChords';
        } else if (url.contains('howlingindicator.net')) {
          sourceName = 'Howling-Indicator';
        } else if (url.contains('peritune.com')) {
          sourceName = 'PeriTune';
        } else if (url.contains('pixabay.com/sound-effects')) {
          sourceName = 'Pixabay SoundEffect';
        } else if (url.contains('pixabay.com')) {
          sourceName = 'Pixabay Music';
        } else if (url.contains('soundeffect-lab.info')) {
          sourceName = '効果音ラボ';
        } else if (url.contains('springin.org')) {
          sourceName = "Springin' Sound Stock";
        } else if (url.contains('sounddictionary.info')) {
          sourceName = '効果音辞典';
        } else if (url.isNotEmpty) {
          // URLのホスト名からサイト名を推測
          final uri = Uri.tryParse(url);
          sourceName = uri?.host.replaceAll('www.', '') ?? 'Web Sound Source';
        } else {
          // 外部URLのない音源はクレジット表示をスキップ
          return;
        }
      }

      if (sourceName == 'Pixabay' || (sourceName == 'Pixabay Music' && url.contains('sound-effects'))) {
        sourceName = 'Pixabay SoundEffect';
      }

      String author = currentAuthor?.trim() ?? '';
      if (author == 'Pixabay') {
        author = 'Pixabay SoundEffect';
      } else if (author.isEmpty || author.contains('その他') || author == 'Unknown') {
        if (sourceName.contains('Gemini')) {
          author = 'Google Gemini';
        } else if (sourceName.contains('CreatorChords')) {
          author = 'Alexander Nakarada';
        } else {
          author = sourceName;
        }
      }

      String license = currentLicense?.trim() ?? '';
      if (license.isEmpty || license.contains('その他') || license == 'Unknown') {
        if (sourceName.contains('Gemini')) {
          license = 'Gemini 利用規約';
        } else if (sourceName.contains('Howling')) {
          license = 'Howling-Indicator利用規約';
        } else if (sourceName.contains('CreatorChords')) {
          license = 'CC-BY 4.0';
        } else {
          license = '$sourceName 利用規約';
        }
      }

      final entry = SoundCreditEntry(
        fileName: currentFile!.trim(),
        description: currentDesc?.trim() ?? '',
        sourceName: sourceName,
        author: author,
        license: license,
        notes: currentNotes?.trim() ?? '',
        url: url,
      );

      grouped.putIfAbsent(sourceName, () => []).add(entry);

      currentFile = null;
      currentDesc = null;
      currentSource = null;
      currentAuthor = null;
      currentLicense = null;
      currentNotes = null;
    }

    for (var rawLine in lines) {
      final line = rawLine.trim();

      if (line.startsWith('---') || line.startsWith('===')) {
        commitEntry();
        continue;
      }

      if (line.startsWith('File:')) {
        commitEntry(); // 新しいブロック開始
        currentFile = line.substring('File:'.length).trim();
      } else if (line.startsWith('Description:')) {
        currentDesc = line.substring('Description:'.length).trim();
      } else if (line.startsWith('Source:')) {
        currentSource = line.substring('Source:'.length).trim();
      } else if (line.startsWith('Author:')) {
        currentAuthor = line.substring('Author:'.length).trim();
      } else if (line.startsWith('License:')) {
        currentLicense = line.substring('License:'.length).trim();
      } else if (line.startsWith('Notes:')) {
        currentNotes = line.substring('Notes:'.length).trim();
      }
    }

    commitEntry(); // 末尾エントリの確定

    // 提供元ごとのソート（件数が多い順にソート）
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final cmp = grouped[b]!.length.compareTo(grouped[a]!.length);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });

    final Map<String, List<SoundCreditEntry>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }
}
