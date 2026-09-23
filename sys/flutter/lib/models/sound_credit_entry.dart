/// BGM・効果音クレジット用モデルおよびパーサー
library;

/// BGM・効果音の提供元（サービス・サイト）単位のクレジット情報
class SoundCreditSource {
  final String sourceName;
  final String author;
  final String license;
  final String url;
  final int soundCount;

  const SoundCreditSource({
    required this.sourceName,
    required this.author,
    required this.license,
    required this.url,
    this.soundCount = 0,
  });

  @override
  String toString() {
    return 'SoundCreditSource(source: $sourceName, author: $author, license: $license, url: $url)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundCreditSource &&
          runtimeType == other.runtimeType &&
          sourceName == other.sourceName &&
          author == other.author &&
          license == other.license &&
          url == other.url;

  @override
  int get hashCode =>
      sourceName.hashCode ^ author.hashCode ^ license.hashCode ^ url.hashCode;
}

/// 個別ファイル用のクレジットエントリ（下位互換性およびパース用）
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

/// attributions.txt を解析してクレジット情報を生成するパーサー
class SoundCreditParser {
  /// attributions.txt を解析し、提供元・サービス単位に集約した [SoundCreditSource] のリストを返す
  static List<SoundCreditSource> parseSources(String text, {bool isEnglish = false}) {
    final grouped = parse(text);
    final List<SoundCreditSource> sources = [];

    for (final entry in grouped.entries) {
      final sourceName = entry.key;
      final entries = entry.value;
      if (entries.isEmpty) continue;

      // ユニークな作者リストの収集
      final authors = entries
          .map((e) => e.author.trim())
          .where((a) => a.isNotEmpty)
          .toSet()
          .toList();

      // 代表作者の決定
      String author;
      if (sourceName.contains('Pixabay')) {
        author = isEnglish ? 'Pixabay Community Creators' : 'Pixabay コミュニティの各クリエイター';
      } else if (authors.length == 1) {
        author = authors.first;
      } else if (authors.isEmpty) {
        author = sourceName;
      } else {
        author = isEnglish ? 'Various Creators' : '各クリエイター';
      }

      // 代表ライセンスの決定
      String license = entries.first.license.trim();
      if (sourceName.contains('Pixabay')) {
        license = 'Pixabay Content License';
      } else if (sourceName.contains('PeriTune') || sourceName.contains('CreatorChords')) {
        license = 'CC-BY 4.0';
      }

      // 代表URLの正規化（サイトトップまたは代表URL）
      String url = _getPrimaryUrl(sourceName, entries.first.url);

      sources.add(SoundCreditSource(
        sourceName: sourceName,
        author: author,
        license: license,
        url: url,
        soundCount: entries.length,
      ));
    }

    // 音源数が多い順にソート（同数の場合は名称昇順）
    sources.sort((a, b) {
      final cmp = b.soundCount.compareTo(a.soundCount);
      if (cmp != 0) return cmp;
      return a.sourceName.compareTo(b.sourceName);
    });

    return sources;
  }

  /// サービス名に応じた代表URLの正規化
  static String _getPrimaryUrl(String sourceName, String sampleUrl) {
    if (sourceName == 'Pixabay SoundEffect') {
      return 'https://pixabay.com/sound-effects/';
    } else if (sourceName == 'Pixabay Music') {
      return 'https://pixabay.com/music/';
    } else if (sourceName == 'PeriTune') {
      return 'https://peritune.com/';
    } else if (sourceName == 'CreatorChords') {
      return 'https://creatorchords.com/';
    } else if (sourceName == '効果音ラボ') {
      return 'https://soundeffect-lab.info/';
    } else if (sourceName == "Springin' Sound Stock") {
      return 'https://www.springin.org/sound-stock/';
    } else if (sourceName == 'OtoLogic') {
      return 'https://otologic.jp/';
    } else if (sourceName == 'Howling-Indicator') {
      return 'https://howlingindicator.net/';
    } else if (sourceName == '効果音辞典') {
      return 'https://sounddictionary.info/';
    } else if (sourceName.contains('Gemini')) {
      return 'https://gemini.google.com/';
    } else if (sourceName.contains('NetHack')) {
      return 'https://www.nethack.org/';
    } else if (sourceName.contains('FluidR3')) {
      return 'https://raw.githubusercontent.com/urish/cinto/master/media/FluidR3%20GM.sf2';
    }

    // 一般的なURLのオリジン化
    if (sampleUrl.isNotEmpty) {
      final uri = Uri.tryParse(sampleUrl);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        return '${uri.scheme}://${uri.host}/';
      }
    }
    return sampleUrl;
  }

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
        commitEntry();
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

    commitEntry();

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
