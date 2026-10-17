/// BGM・効果音クレジット用モデルおよびパーサー
library;

/// BGM・効果音の提供元（サービス・サイト）単位のクレジット情報
class SoundCreditSource {
  final String sourceName;
  final String author;
  final String license;
  final String url;
  final int soundCount;
  final List<SoundCreditEntry> bgmEntries;

  const SoundCreditSource({
    required this.sourceName,
    required this.author,
    required this.license,
    required this.url,
    this.soundCount = 0,
    this.bgmEntries = const [],
  });

  @override
  String toString() {
    return 'SoundCreditSource(source: $sourceName, author: $author, license: $license, url: $url, bgmCount: ${bgmEntries.length})';
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
      } else if (sourceName.contains('Gemini')) {
        author = 'Google Gemini';
      } else if (authors.length == 1) {
        author = authors.first;
      } else if (authors.isEmpty) {
        author = sourceName;
      } else {
        author = isEnglish ? 'Various Creators' : '各クリエイター';
      }

      // 代表ライセンスの決定
      final rawLicense = entries.first.license.trim();
      final license = formatLicense(
        rawLicense,
        isEnglish: isEnglish,
        sourceName: sourceName,
      );

      // 代表URLの正規化（サイトトップまたは代表URL）
      String url = _getPrimaryUrl(sourceName, entries.first.url);

      // BGMエントリの抽出（amb_*.ogg かつ環境音除外）
      final bgmEntries = entries.where((e) {
        final name = e.fileName.trim();
        return name.startsWith('amb_') && !terrainAmbienceFiles.contains(name);
      }).toList();

      // BGM一覧をフロア名・部屋名順でソート
      bgmEntries.sort((a, b) {
        final titleA = getBgmTitle(a.fileName, isEnglish: isEnglish, description: a.description);
        final titleB = getBgmTitle(b.fileName, isEnglish: isEnglish, description: b.description);
        return titleA.compareTo(titleB);
      });

      sources.add(SoundCreditSource(
        sourceName: sourceName,
        author: author,
        license: license,
        url: url,
        soundCount: entries.length,
        bgmEntries: bgmEntries,
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

  /// 除外対象の地形・天候環境音
  static const Set<String> terrainAmbienceFiles = {
    'amb_water.ogg',
    'amb_lava.ogg',
    'amb_wind.ogg',
    'amb_rain.ogg',
    'amb_swamp.ogg',
  };

  /// BGMファイル名に対応するフロア名・部屋名（日本語・英語）
  static const Map<String, (String ja, String en)> bgmFloorAndRoomTitles = {
    'amb_title.ogg': ('タイトル', 'Title Screen'),
    'amb_gameover.ogg': ('ゲームオーバー', 'Game Over'),
    'amb_dungeon.ogg': ('運命の大迷宮', 'The Dungeons of Doom'),
    'amb_mines.ogg': ('ノーム鉱山', 'The Gnomish Mines'),
    'amb_sokoban.ogg': ('倉庫番', 'Sokoban'),
    'amb_town.ogg': ('鉱山街', 'Minetown'),
    'amb_quest.ogg': ('クエスト', 'The Quest'),
    'amb_gehennom.ogg': ('ゲヘナ', 'Gehennom'),
    'amb_vlad.ogg': ('ヴラドの塔', "Vlad's Tower"),
    'amb_wizard_tower.ogg': ('イェンダーの魔法の塔', "The Wizard's Tower"),
    'amb_astral.ogg': ('アストラル界', 'The Astral Plane'),
    'amb_ludios.ogg': ('狂えるクロイソスの財宝庫', 'Fort Ludios'),
    'amb_tutorial.ogg': ('チュートリアル', 'Tutorial'),
    'amb_oracle.ogg': ('神託所', 'The Oracle'),
    'amb_rogue.ogg': ('ローグ階', 'The Rogue Level'),
    'amb_bigroom.ogg': ('大部屋', 'The Big Room'),
    'amb_medusa.ogg': ('メドゥーサの島', "Medusa's Island"),
    'amb_castle.ogg': ('城', 'The Castle'),
    'amb_minend.ogg': ('鉱山最下層', "Mine's End"),
    'amb_sokoend.ogg': ('倉庫番最上階', 'Sokoban Top Level'),
    'amb_quest_nemesis.ogg': ('クエスト宿敵の階', 'Quest Nemesis Lair'),
    'amb_valley.ogg': ('死者の谷', 'Valley of the Dead'),
    'amb_juiblex.ogg': ('ジュイブレクスの沼', "Juiblex's Swamp"),
    'amb_baalzebub.ogg': ('バアルゼブルの棲家', "Baalzebub's Lair"),
    'amb_asmodeus.ogg': ('アスモデウスの宮殿', "Asmodeus' Palace"),
    'amb_orcus.ogg': ('オルクスの町', "Orcus' Town"),
    'amb_fakewiz.ogg': ('偽魔法使いの塔', "Fake Wizard's Tower"),
    'amb_sanctum.ogg': ('鮮血の聖所', "Moloch's Sanctum"),
    'amb_plane_earth.ogg': ('土の精霊界', 'Plane of Earth'),
    'amb_plane_air.ogg': ('風の精霊界', 'Plane of Air'),
    'amb_plane_fire.ogg': ('火の精霊界', 'Plane of Fire'),
    'amb_plane_water.ogg': ('水の精霊界', 'Plane of Water'),
    'amb_ascension.ogg': ('昇天', 'Ascension'),
    // 部屋BGM・テーマ部屋BGM
    'amb_in_a_shop.ogg': ('店', 'Shop'),
    'amb_inside_temple.ogg': ('寺院', 'Temple'),
    'amb_inside_vault.ogg': ('金庫室', 'Vault'),
    'amb_inside_leprehall.ogg': ('レプラコーンの広間', 'Leprechaun Hall'),
    'amb_approaching_oracle.ogg': ('デルフィの神託所', 'Delphi Oracle Room'),
    'amb_in_a_court.ogg': ('玉座の間', 'Throne Room'),
    'amb_in_a_barracks.ogg': ('兵舎', 'Barracks'),
    'amb_in_a_zoo.ogg': ('モンスター動物園', 'Monster Zoo'),
    'amb_in_a_beehive.ogg': ('蜂の巣', 'Beehive'),
    'amb_inside_anthole.ogg': ('アリの巣', 'Ant Hole'),
    'amb_in_cemetery.ogg': ('墓地', 'Graveyard'),
    'amb_in_a_cockatrice_nest.ogg': ('コカトリスの巣', 'Cockatrice Nest'),
    'amb_in_a_lemure_pit.ogg': ('レムレースの穴', 'Lemure Pit'),
    'amb_in_a_migot_nest.ogg': ('ミ＝ゴの巣', 'Mi-Go Nest'),
    'amb_in_a_black_market.ogg': ('闇市場', 'Black Market'),
    'amb_inside_morgue.ogg': ('死体安置所', 'Morgue'),
    'amb_in_a_morgue.ogg': ('死体安置所', 'Morgue'),
    'amb_inside_armory.ogg': ('武器庫', 'Armory'),
    'amb_inside_pool.ogg': ('泉・水泳場', 'Pool Room'),
    'amb_inside_garden.ogg': ('庭園', 'Garden'),
    'amb_inside_library.ogg': ('図書館', 'Library'),
    'amb_inside_nymph_garden.ogg': ('ニンフの園', 'Nymph Garden'),
    'amb_theme_nymph_garden.ogg': ('ニンフの園', 'Nymph Garden'),
    'amb_theme_boulder_room.ogg': ('巨石の部屋', 'Boulder Room'),
    'amb_theme_trap_room.ogg': ('トラップの部屋', 'Trap Room'),
    'amb_theme_buried_treasure.ogg': ('埋没財宝の部屋', 'Buried Treasure Room'),
    'amb_theme_buried_zombies.ogg': ('蠢く土葬室', 'Buried Zombies Room'),
    'amb_theme_massacre.ogg': ('大虐殺跡', 'Massacre Site'),
    'amb_theme_statuary.ogg': ('彫像展示室', 'Statuary'),
    'amb_theme_light_source.ogg': ('暗闇の灯火', 'Light Source Room'),
    'amb_theme_temple_of_the_gods.ogg': ('三神の合祀殿', 'Temple of the Gods'),
    'amb_theme_ghost_adventurer.ogg': ('冒険者の亡霊', 'Ghost of an Adventurer Room'),
    'amb_theme_storeroom.ogg': ('物置部屋', 'Storeroom'),
    'amb_theme_teleport_hub.ogg': ('テレポート中枢室', 'Teleportation Hub'),
    'amb_theme_mausoleum.ogg': ('霊廟', 'Mausoleum'),
    'amb_theme_pillars.ogg': ('列柱の間', 'Pillars Room'),
    'amb_theme_fake_delphi.ogg': ('偽神託所', 'Fake Delphi'),
    'amb_in_swamp_room.ogg': ('沼地部屋', 'Swamp Room'),
    'amb_theme_spider_nest.ogg': ('蜘蛛の巣窟', 'Spider Nest'),
    'amb_theme_ice_room.ogg': ('氷の部屋', 'Ice Room'),
    'amb_theme_cloud_room.ogg': ('雲・霧の部屋', 'Cloud Room'),
  };

  /// ライセンス表記を言語設定（日本語 / 英語）に合わせてフォーマットする
  static String formatLicense(
    String rawLicense, {
    required bool isEnglish,
    String sourceName = '',
  }) {
    final trimmed = rawLicense.trim();
    if (trimmed.isEmpty) return '';

    // Pixabay
    if (sourceName.contains('Pixabay') || trimmed.contains('Pixabay')) {
      return 'Pixabay Content License';
    }

    // CC-BY / PeriTune / CreatorChords
    if (sourceName.contains('PeriTune') ||
        sourceName.contains('CreatorChords') ||
        trimmed.startsWith('CC-BY') ||
        trimmed.startsWith('CC BY')) {
      return 'CC-BY 4.0';
    }

    // 英語モード時の多言語化処理
    if (isEnglish) {
      if (trimmed.contains('OtoLogic')) {
        return 'OtoLogic Terms of Service (CC BY 4.0)';
      }
      if (trimmed.contains('Gemini')) {
        return 'Gemini Terms of Service';
      }
      if (trimmed.contains('Howling')) {
        return 'Howling-Indicator Terms of Service';
      }
      if (trimmed.contains('Springin')) {
        return "Springin' Terms of Service";
      }
      if (trimmed.contains('効果音ラボ')) {
        return '効果音ラボ Terms of Service';
      }
      if (trimmed.contains('効果音辞典')) {
        return '効果音辞典 Terms of Service';
      }
      if (trimmed.contains('利用規約')) {
        // 一般的な "X利用規約" -> "X Terms of Service"
        final base = trimmed
            .replaceAll(RegExp(r'[（\(].*?[）\)]'), '')
            .replaceAll('利用規約', '')
            .trim();
        return base.isNotEmpty ? '$base Terms of Service' : 'Terms of Service';
      }
      // その他日本語の括弧表記（商用可・...）が含まれていれば除去
      return trimmed.replaceAll(RegExp(r'[（\(][^a-zA-Z0-9]*?[）\)]'), '').trim();
    }

    // 日本語モード時
    return trimmed;
  }

  /// BGMファイル名に対応するフロア名・部屋名を取得する
  static String getBgmTitle(String fileName, {bool isEnglish = false, String description = ''}) {
    final cleanName = fileName.trim();
    final entry = bgmFloorAndRoomTitles[cleanName];
    if (entry != null) {
      return isEnglish ? entry.$2 : entry.$1;
    }
    // マップにない場合のフォールバック: Description の先頭から抽出
    if (description.isNotEmpty) {
      final parenMatch = RegExp(r'^(.*?)[（\(](.*?)[）\)]').firstMatch(description);
      if (parenMatch != null) {
        return isEnglish ? parenMatch.group(2)!.trim() : parenMatch.group(1)!.trim();
      }
      final periodIdx = description.indexOf('。');
      if (periodIdx != -1) {
        return description.substring(0, periodIdx).trim();
      }
    }
    return cleanName;
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
