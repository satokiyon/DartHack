// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-07.
import 'dart:io';

class TopTenEntry {
  final int rank;
  final String score;
  final String nameAndProfile;
  final List<String> details;
  final bool isCurrent;

  TopTenEntry({
    required this.rank,
    required this.score,
    required this.nameAndProfile,
    required this.details,
    required this.isCurrent,
  });

  static List<TopTenEntry> parse(List<String> lines, List<int> attrs, {bool isJp = true}) {
    final entries = <TopTenEntry>[];

    // 順位は空スペースの場合もあるため ([0-9]*) とし、スコア ([0-9]+) にマッチさせる
    final entryRegExp = RegExp(r'^\s*([0-9]*)\s+([0-9]+)\s+(.*)$');
    // 名前とプロフィールの境界を特定する正規表現 ("名前 職業/種族/性別/神")
    final profileRegex = RegExp(r'^(.*?\s+[^\s\/]+\/[^\s\/]+\/[^\s\/]+\/[^\s]+)(.*)$');
    // 行末の HP 表示を検出する正規表現（" - [103]", " 15 [120]", " - [ 25]" 等）
    final hpSuffixRegExp = RegExp(r'\s+(-|[0-9]+)\s+\[\s*([0-9]+)\]\s*$');
    final hyphenRegex = RegExp(r'^([^\s\-]+)\-([^\s\-]+(?:\-[^\s\-]+){2,4})(?:\s+(.*))?$');

    int index = 0;
    while (index < lines.length) {
      final rawLine = lines[index];
      final trimmed = rawLine.trim();
      final trimmedLower = trimmed.toLowerCase();

      if (trimmed.isEmpty ||
          (trimmed.contains('順位') && trimmed.contains('点数') && trimmed.contains('名前')) ||
          (trimmedLower.contains('no') && trimmedLower.contains('points') && trimmedLower.contains('name'))) {
        index++;
        continue;
      }

      final entryMatch = entryRegExp.firstMatch(rawLine);
      if (entryMatch != null) {
        final rankStr = entryMatch.group(1)!;
        final rank = rankStr.isNotEmpty ? (int.tryParse(rankStr) ?? 0) : 0;
        final score = entryMatch.group(2)!;
        final rest = entryMatch.group(3)!;

        String nameAndProfile = rest.trim();
        String inlineDeathPart = '';

        final profileMatchSlash = profileRegex.firstMatch(rest);
        final profileMatchHyphen = hyphenRegex.firstMatch(rest);

        if (profileMatchSlash != null) {
          nameAndProfile = profileMatchSlash.group(1)!.trim();
          inlineDeathPart = profileMatchSlash.group(2)!.trim();
        } else if (profileMatchHyphen != null) {
          final rawName = profileMatchHyphen.group(1)!.trim();
          final profileStr = profileMatchHyphen.group(2)!.trim();
          inlineDeathPart = (profileMatchHyphen.group(3) ?? '').trim();

          final parts = profileStr.split('-');
          final translatedParts = <String>[];
          for (int pIdx = 0; pIdx < parts.length; pIdx++) {
            final code = parts[pIdx];
            if (pIdx == 0) {
              translatedParts.add(_translateRoleCode(code, isJp));
            } else if (pIdx == 1) {
              translatedParts.add(_translateRaceCode(code, isJp));
            } else if (pIdx == 2) {
              translatedParts.add(_translateGendCode(code, isJp));
            } else if (pIdx == 3) {
              translatedParts.add(_translateAlignCode(code, isJp));
            } else {
              translatedParts.add(code);
            }
          }
          nameAndProfile = '$rawName ${translatedParts.join(' / ')}';
        }

        final attr = index < attrs.length ? attrs[index] : 0;
        bool isBold = (attr & 1) != 0; // ATR_BOLD (1)

        String? hpInfo;
        final deathParts = <String>[];
        if (inlineDeathPart.isNotEmpty) {
          deathParts.add(inlineDeathPart);
        }

        // 後続行（死因の続き行やHP行）をすべてスキャンして消費
        while (index + 1 < lines.length) {
          final peekLine = lines[index + 1];
          final peekTrimmed = peekLine.trim();
          final peekTrimmedLower = peekTrimmed.toLowerCase();
          final isHeaderLine = peekTrimmed.contains('順位') ||
              (peekTrimmedLower.contains('no') && peekTrimmedLower.contains('points'));

          if (peekTrimmed.isEmpty || isHeaderLine) {
            break;
          }

          final hpMatch = hpSuffixRegExp.firstMatch(peekLine);

          // HP情報を含まない行で、かつ新しいスコアエントリ（プロフィールを含む）であれば終了
          if (hpMatch == null) {
            final nextEntryMatch = entryRegExp.firstMatch(peekLine);
            if (nextEntryMatch != null) {
              final nextRest = nextEntryMatch.group(3)!.trim();
              if (profileRegex.hasMatch(nextRest) || hyphenRegex.hasMatch(nextRest)) {
                break;
              }
            }
          }

          var nextLine = peekLine;
          if (hpMatch != null) {
            final hpVal = hpMatch.group(1);
            final maxHpVal = hpMatch.group(2);
            hpInfo = isJp ? 'HP/最大HP: $hpVal/$maxHpVal' : 'HP/Max HP: $hpVal/$maxHpVal';
            nextLine = nextLine.substring(0, hpMatch.start);
          }

          final nextTrimmed = nextLine.trim();
          if (nextTrimmed.isNotEmpty) {
            deathParts.add(nextTrimmed);
          }

          index++; // 継続行を消費

          // HP情報を消費したら、そのエントリの後続行は完了
          if (hpMatch != null) {
            break;
          }
        }

        // 分割された死因テキストを自然に結合
        String fullDeathText = '';
        for (int i = 0; i < deathParts.length; i++) {
          final part = deathParts[i];
          if (fullDeathText.isEmpty) {
            fullDeathText = part;
          } else {
            final lastCode = fullDeathText.codeUnitAt(fullDeathText.length - 1);
            final firstCode = part.codeUnitAt(0);
            // 英数字・半角記号同士ならスペース1つを挟み、日本語（全角）が含まれる場合はそのまま結合
            final isAsciiBoth = (lastCode >= 0x20 && lastCode <= 0x7E) &&
                (firstCode >= 0x20 && firstCode <= 0x7E);
            fullDeathText = isAsciiBoth ? '$fullDeathText $part' : '$fullDeathText$part';
          }
        }

        final details = <String>[];
        if (fullDeathText.isNotEmpty) {
          final translatedDeath = _translateDeathText(fullDeathText, isJp);
          details.add(translatedDeath);
        }
        if (hpInfo != null) {
          details.add(hpInfo);
        }

        entries.add(TopTenEntry(
          rank: rank,
          score: score,
          nameAndProfile: nameAndProfile,
          details: details,
          isCurrent: isBold,
        ));
      }
      index++;
    }

    return entries;
  }
}

class TopTenEntryBuilder {
  final int rank;
  final String score;
  final String nameAndProfile;
  final List<String> details = [];
  bool isCurrent;

  TopTenEntryBuilder({
    required this.rank,
    required this.score,
    required this.nameAndProfile,
    required this.isCurrent,
  });

  TopTenEntry build() {
    return TopTenEntry(
      rank: rank,
      score: score,
      nameAndProfile: nameAndProfile,
      details: details,
      isCurrent: isCurrent,
    );
  }
}

class _RecordRawEntry {
  final int points;
  final int dnum;
  final int dlev;
  final int maxlvl;
  final int hp;
  final int maxhp;
  final String role;
  final String race;
  final String gend;
  final String align;
  final String name;
  final String death;

  _RecordRawEntry({
    required this.points,
    required this.dnum,
    required this.dlev,
    required this.maxlvl,
    required this.hp,
    required this.maxhp,
    required this.role,
    required this.race,
    required this.gend,
    required this.align,
    required this.name,
    required this.death,
  });
}

String? findRecordFilePath() {
  final candidatePaths = [
    'record',
    './record',
    '../record',
    'sys/flutter/record',
    'record_jp',
    './record_jp',
    '../record_jp',
  ];

  for (final path in candidatePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String _translateRoleCode(String code, bool isJp) {
  if (!isJp) {
    const mapEn = {
      'Arc': 'Archeologist', 'Bar': 'Barbarian', 'Cav': 'Caveman', 'Hea': 'Healer',
      'Kni': 'Knight', 'Mon': 'Monk', 'Pri': 'Priest', 'Rog': 'Rogue',
      'Ran': 'Ranger', 'Sam': 'Samurai', 'Tou': 'Tourist', 'Val': 'Valkyrie', 'Wiz': 'Wizard'
    };
    return mapEn[code] ?? code;
  }
  const mapJp = {
    'Arc': '考古学者', 'Bar': '野蛮人', 'Cav': '洞窟人', 'Hea': '師',
    'Kni': '騎士', 'Mon': '修道士', 'Pri': '僧侶', 'Rog': '盗賊',
    'Ran': '旅人', 'Sam': '侍', 'Tou': '観光客', 'Val': 'バルキリー', 'Wiz': '魔法使い'
  };
  return mapJp[code] ?? code;
}

String _translateRaceCode(String code, bool isJp) {
  if (!isJp) {
    const mapEn = {'Hum': 'Human', 'Elf': 'Elf', 'Dwa': 'Dwarf', 'Gno': 'Gnome', 'Orc': 'Orc'};
    return mapEn[code] ?? code;
  }
  const mapJp = {'Hum': '人間', 'Elf': 'エルフ', 'Dwa': 'ドワーフ', 'Gno': 'ノーム', 'Orc': 'オーク'};
  return mapJp[code] ?? code;
}

String _translateGendCode(String code, bool isJp) {
  if (code.startsWith('Mal') || code == 'M') return isJp ? '男性' : 'Male';
  if (code.startsWith('Fem') || code == 'F') return isJp ? '女性' : 'Female';
  return code;
}

String _translateAlignCode(String code, bool isJp) {
  if (code.startsWith('Law') || code == 'L') return isJp ? '秩序' : 'Lawful';
  if (code.startsWith('Neu') || code == 'N') return isJp ? '中立' : 'Neutral';
  if (code.startsWith('Cha') || code == 'C') return isJp ? '混沌' : 'Chaotic';
  return code;
}

String _translateDungeonName(int dnum, bool isJp) {
  if (!isJp) {
    switch (dnum) {
      case 0:
        return 'The Dungeons of Doom';
      case 1:
        return 'Gehennom';
      case 2:
        return 'The Gnomish Mines';
      case 3:
        return 'The Quest';
      case 4:
        return 'Sokoban';
      case 5:
        return 'Fort Ludios';
      case 6:
        return "Vlad's Tower";
      case 7:
        return 'The Elemental Planes';
      default:
        return 'Dungeon';
    }
  }
  switch (dnum) {
    case 0:
      return '運命の大迷宮';
    case 1:
      return 'ゲヘナ';
    case 2:
      return 'ノームの鉱山';
    case 3:
      return 'クエスト';
    case 4:
      return '倉庫番';
    case 5:
      return 'ローディオス砦';
    case 6:
      return 'ヴラド侯の塔';
    case 7:
      return '精霊界';
    default:
      return 'ダンジョン';
  }
}

String _translateEndgameLevel(int dlev, bool isJp) {
  if (!isJp) {
    switch (dlev) {
      case -5:
        return 'Astral Plane';
      case -4:
        return 'Plane of Water';
      case -3:
        return 'Plane of Fire';
      case -2:
        return 'Plane of Air';
      case -1:
        return 'Plane of Earth';
      default:
        return 'Elemental Planes';
    }
  }
  switch (dlev) {
    case -5:
      return 'アストラル界';
    case -4:
      return '水の精霊界';
    case -3:
      return '火の精霊界';
    case -2:
      return '風の精霊界';
    case -1:
      return '地の精霊界';
    default:
      return '精霊界';
  }
}

String _stripEnglishArticle(String s) {
  if (s.startsWith('an ')) return s.substring(3);
  if (s.startsWith('a ')) return s.substring(2);
  if (s.startsWith('the ')) return s.substring(4);
  return s;
}

String _translateShkName(String rawName) {
  var s = _stripEnglishArticle(rawName.trim());
  if (s.toLowerCase().startsWith('mr. ')) {
    s = s.substring(4).trim();
  } else if (s.toLowerCase().startsWith('ms. ')) {
    s = s.substring(4).trim();
  }

  const shkNameMap = {
    'Shigatse': 'シガツェ',
    'Asidonhopo': 'アシドンホポ',
    'Hesiod': 'ヘシオド',
    'Izchak': 'イズチャク',
    'Dirk': 'ディルク',
    'Lucrezia': 'ルクレツィア',
    'Rikaze': 'リカゼ',
    'Lhasa': 'ラサ',
    'Skibbereen': 'スキベリーン',
    'Kanturk': 'カンターク',
    'Rath Luirc': 'ラス・ルアーク',
    'Ennistymon': 'エニスタイモン',
    'Lahinch': 'ラヒンチ',
    'Voulgezac': 'ヴルジェザック',
    'Rouffiac': 'ルフィアック',
    'Lerignac': 'レリニャック',
    'Touverac': 'トゥヴラック',
    'Guizengeard': 'ギザンジャール',
    'Djasinga': 'ジャシンガ',
    'Tjibarusa': 'チバルサ',
    'Tjiwidej': 'チウィデイ',
    'Pengalengan': 'プンガレンガン',
    'Bandjar': 'バンジャル',
    'Feyfer': 'フェイファー',
    'Flugi': 'フルギ',
    'Gheel': 'ヒール',
    'Havic': 'ハヴィク',
    'Haynin': 'ヘイニン',
    'Nairn': 'ネアン',
    'Turriff': 'タリフ',
    'Inverurie': 'インヴァルリー',
    'Braemar': 'ブレーマー',
    'Lochnagar': 'ロッホナガー',
    'Ymla': 'イムラ',
    'Eed-morra': 'イード・モラ',
    'Cubask': 'キューバスク',
    'Nieb': 'ニーブ',
    'Yawolloh': 'ヤウォロ',
    "Ga'er": 'ガエル',
    'Zhangmu': 'チャンムー',
  };

  if (shkNameMap.containsKey(s)) {
    return shkNameMap[s]!;
  }
  final capS = _capitalizeFirst(s);
  if (shkNameMap.containsKey(capS)) {
    return shkNameMap[capS]!;
  }

  return _katakanaFallback(s);
}

String _katakanaFallback(String name) {
  final buf = StringBuffer();
  for (int i = 0; i < name.length; i++) {
    final c = name[i].toLowerCase();
    switch (c) {
      case 'a': buf.write('ア'); break;
      case 'b': buf.write('ブ'); break;
      case 'c': buf.write('ク'); break;
      case 'd': buf.write('ド'); break;
      case 'e': buf.write('エ'); break;
      case 'f': buf.write('フ'); break;
      case 'g': buf.write('グ'); break;
      case 'h': buf.write('ハ'); break;
      case 'i': buf.write('イ'); break;
      case 'j': buf.write('ジ'); break;
      case 'k': buf.write('ク'); break;
      case 'l': buf.write('ル'); break;
      case 'm': buf.write('ム'); break;
      case 'n': buf.write('ン'); break;
      case 'o': buf.write('オ'); break;
      case 'p': buf.write('プ'); break;
      case 'q': buf.write('ク'); break;
      case 'r': buf.write('ル'); break;
      case 's': buf.write('ス'); break;
      case 't': buf.write('ト'); break;
      case 'u': buf.write('ウ'); break;
      case 'v': buf.write('ヴ'); break;
      case 'w': buf.write('ワ'); break;
      case 'x': buf.write('クス'); break;
      case 'y': buf.write('イ'); break;
      case 'z': buf.write('ズ'); break;
      case ' ': case '-': case '\'':
        if (buf.isNotEmpty && !buf.toString().endsWith('・')) {
          buf.write('・');
        }
        break;
    }
  }
  var res = buf.toString();
  while (res.endsWith('・')) {
    res = res.substring(0, res.length - 1);
  }
  return res.isNotEmpty ? res : name;
}

String _translateMonsterOrItemName(String raw) {
  var s = _stripEnglishArticle(raw.trim());
  if (s.isEmpty) return s;

  if (s.startsWith('幻覚でゆがんだ')) {
    return '幻覚でゆがんだ${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('hallucinogen-distorted ')) {
    return '幻覚でゆがんだ${_translateMonsterOrItemName(s.substring(23))}';
  }
  if (s.startsWith('hallucinatory ')) {
    return '幻覚でゆがんだ${_translateMonsterOrItemName(s.substring(14))}';
  }
  if (s.startsWith('透明な')) {
    return '不可視の${_translateMonsterOrItemName(s.substring(3))}';
  }
  if (s.startsWith('invisible ')) {
    return '不可視の${_translateMonsterOrItemName(s.substring(10))}';
  }

  // 店主パターン (e.g., "Mr. Shigatse, the shopkeeper", "Mr. Shigatse; the shopkeeper")
  if (s.contains(', the shopkeeper') || s.contains('; the shopkeeper')) {
    final idx = s.indexOf(', the shopkeeper');
    final altIdx = s.indexOf('; the shopkeeper');
    final cutPos = (idx != -1) ? idx : altIdx;
    final base = s.substring(0, cutPos);
    final shkJp = _translateShkName(base);
    return '店主の$shkJp';
  }

  // 神官パターン (e.g., "high priest of Moloch", "priest of Anubis")
  if (s.startsWith('high priest of ')) {
    final god = _translateMonsterOrItemName(s.substring(15));
    return '$godの高位神官';
  }
  if (s.startsWith('high priestess of ')) {
    final god = _translateMonsterOrItemName(s.substring(18));
    return '$godの高位神官';
  }
  if (s.startsWith('priest of ')) {
    final god = _translateMonsterOrItemName(s.substring(10));
    return '$godの神官';
  }
  if (s.startsWith('priestess of ')) {
    final god = _translateMonsterOrItemName(s.substring(13));
    return '$godの神官';
  }
  if (s == 'temple priest' || s == 'temple priestess') {
    return '寺院の神官';
  }

  // 名前付きペット・モンスター (e.g., "kitten called Tama", "dog named Pochi")
  if (s.contains(' called ') || s.contains(' named ')) {
    final isCalled = s.contains(' called ');
    final parts = s.split(isCalled ? ' called ' : ' named ');
    if (parts.length == 2) {
      final base = _translateMonsterOrItemName(parts[0]);
      final name = parts[1];
      return '$nameという名前の$base';
    }
  }

  // 擬態・フォームモンスター (e.g., "doppelganger in goblin form")
  if (s.contains(' in ') && s.endsWith(' form')) {
    final parts = s.substring(0, s.length - 5).split(' in ');
    if (parts.length == 2) {
      final real = _translateMonsterOrItemName(parts[0]);
      final shape = _translateMonsterOrItemName(parts[1]);
      return '$shapeの姿をした$real';
    }
  }
  if (s.contains(' disguised as ')) {
    final parts = s.split(' disguised as ');
    if (parts.length == 2) {
      final real = _translateMonsterOrItemName(parts[0]);
      final shape = _translateMonsterOrItemName(parts[1]);
      return '$shapeに変装した$real';
    }
  }
  if (s.contains(' imitating ')) {
    final parts = s.split(' imitating ');
    if (parts.length == 2) {
      final real = _translateMonsterOrItemName(parts[0]);
      final shape = _translateMonsterOrItemName(parts[1]);
      return '$shapeに擬態した$real';
    }
  }

  // 素手・裸足での操作による石化
  if (s.contains('touching ') && s.contains(' bare-handed')) {
    final ep = s.indexOf(' bare-handed');
    final target = s.substring(9, ep);
    final tr = _translateMonsterOrItemName(target);
    return '素手で$trに触れたことで石化した';
  }
  if (s.contains('throwing ') && s.contains(' bare-handed')) {
    final ep = s.indexOf(' bare-handed');
    final target = s.substring(9, ep);
    final tr = _translateMonsterOrItemName(target);
    return '素手で$trを投げたことで石化した';
  }
  if (s.contains('kicking ') && s.contains(' barefoot')) {
    final ep = s.indexOf(' barefoot');
    final target = s.substring(8, ep);
    final tr = _translateMonsterOrItemName(target);
    return '裸足で$trを蹴ったことで石化した';
  }
  if (s.contains('wielding ') && s.contains(' bare-handed')) {
    final ep = s.indexOf(' bare-handed');
    final target = s.substring(9, ep);
    final tr = _translateMonsterOrItemName(target);
    return '素手で$trを装備したことで石化した';
  }
  if (s.startsWith('bumping into ')) {
    final tr = _translateMonsterOrItemName(s.substring(13));
    return '$trへの衝突で石化した';
  }

  // 特殊な食事・脳食・卵食
  if (s.startsWith('unwisely ate the body of ')) {
    final tr = _translateMonsterOrItemName(s.substring(25));
    return '軽率にも$trの肉を食べたこと';
  }
  if (s.startsWith('unwisely ate the brain of ')) {
    final tr = _translateMonsterOrItemName(s.substring(26));
    return '$trの脳を食べたこと';
  }
  if (s.startsWith('tasting ') && s.endsWith(' meat')) {
    final target = s.substring(8, s.length - 5);
    final tr = _translateMonsterOrItemName(target);
    return '$trの肉の試食';
  }
  if (s.endsWith(' egg') && !s.contains(' ')) {
    final target = s.substring(0, s.length - 4);
    final tr = _translateMonsterOrItemName(target);
    return '$trの卵';
  }

  if (s == 'committed suicide') {
    return '自殺したこと';
  }
  if (s == 'brainlessness') {
    return '脳の損失で倒された';
  }
  if (s == 'self-genocide') return '自己虐殺';
  if (s == 'unsuccessful polymorph') return 'へんげの失敗';
  if (s == 'elementary physics') return '基礎物理学';
  if (s == 'killed while stuck in creature form') return 'へんげした姿のまま死亡したこと';
  if (s.contains('shot ') && s.contains('self with a death ray')) {
    return '死の光線で自分を照射したこと';
  }
  if (s.startsWith('disintegration breath by ')) {
    return '自分の分解のブレスで倒された';
  }
  if (s.startsWith('magic missile by ')) {
    return '自分のマジックミサイルで倒された';
  }
  if (s.endsWith("'s indifference") || s.endsWith(" indifference")) {
    final god = s.replaceAll("'s indifference", '').replaceAll(" indifference", '');
    final tr = _translateMonsterOrItemName(god);
    return '$trの冷淡さで倒された';
  }

  if (s.startsWith('ghost of ')) {
    return '${_translateMonsterOrItemName(s.substring(9))}の幽霊';
  }
  if (s.startsWith('shade of ')) {
    return '${_translateMonsterOrItemName(s.substring(9))}の影';
  }
  if (s.startsWith('zombie of ')) {
    return '${_translateMonsterOrItemName(s.substring(10))}のゾンビ';
  }
  if (s.startsWith('mummy of ')) {
    return '${_translateMonsterOrItemName(s.substring(9))}のマミー';
  }
  if (s.startsWith('skeleton of ')) {
    return '${_translateMonsterOrItemName(s.substring(12))}のスケルトン';
  }
  if (s.contains("'s ghost") || s.contains("'s shade")) {
    final idx = s.indexOf("'s ");
    if (idx != -1) {
      final base = s.substring(0, idx);
      final isGhost = s.contains('ghost');
      return '${_translateMonsterOrItemName(base)}${isGhost ? 'の幽霊' : 'の影'}';
    }
  }
  if (s.startsWith('hallucinogen-distorted ')) {
    return '幻覚でゆがんだ${_translateMonsterOrItemName(s.substring(23))}';
  }
  if (s.startsWith('hallucinatory ')) {
    return '幻覚でゆがんだ${_translateMonsterOrItemName(s.substring(14))}';
  }
  if (s.startsWith('invisible ')) {
    return '不可視の${_translateMonsterOrItemName(s.substring(10))}';
  }
  if (s.startsWith('displaced ')) {
    return '位置のずれた${_translateMonsterOrItemName(s.substring(10))}';
  }
  if (s.startsWith('tame ')) {
    return 'ペットの${_translateMonsterOrItemName(s.substring(5))}';
  }
  if (s.startsWith('peaceful ')) {
    return '大人しい${_translateMonsterOrItemName(s.substring(9))}';
  }
  if (s.endsWith(' zombie')) {
    return '${_translateMonsterOrItemName(s.substring(0, s.length - 7))}のゾンビ';
  }
  if (s.endsWith(' mummy')) {
    return '${_translateMonsterOrItemName(s.substring(0, s.length - 6))}のマミー';
  }
  if (s.endsWith(' skeleton')) {
    return '${_translateMonsterOrItemName(s.substring(0, s.length - 9))}のスケルトン';
  }

  if (s.startsWith('poisonous ')) {
    return '有毒な${_translateMonsterOrItemName(s.substring(10))}';
  }
  if (s.startsWith('acidic ')) {
    return '酸性の${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('rotted ')) {
    return '腐った${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('rotten ')) {
    return '腐った${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('tainted ')) {
    return '汚染された${_translateMonsterOrItemName(s.substring(8))}';
  }
  if (s.startsWith('diseased ')) {
    return '病気の${_translateMonsterOrItemName(s.substring(9))}';
  }
  if (s.startsWith('petrifying ')) {
    return '石化させる${_translateMonsterOrItemName(s.substring(11))}';
  }
  if (s.startsWith('hallucinogenic ')) {
    return '幻覚作用のある${_translateMonsterOrItemName(s.substring(15))}';
  }
  if (s.startsWith('deadly ')) {
    return '致命的な${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('stolen ')) {
    return '奪った${_translateMonsterOrItemName(s.substring(7))}';
  }
  if (s.startsWith('very rich ')) {
    return '豪華すぎる${_translateMonsterOrItemName(s.substring(10))}';
  }
  if (s.startsWith('quick ')) {
    return '軽い${_translateMonsterOrItemName(s.substring(6))}';
  }

  if (s == 'corpse') return '死体';
  if (s == 'glob') return '塊';
  if (s == 'egg') return '卵';

  if (s.endsWith(' corpse')) {
    final sub = s.substring(0, s.length - 7);
    final tr = _translateMonsterOrItemName(sub);
    return tr.isEmpty ? '死体' : '$trの死体';
  }
  if (s.endsWith(' egg')) {
    final sub = s.substring(0, s.length - 4);
    final tr = _translateMonsterOrItemName(sub);
    return tr.isEmpty ? '卵' : '$trの卵';
  }
  if (s.startsWith('statue of ')) {
    return '${_translateMonsterOrItemName(s.substring(10))}の石像';
  }
  if (s.startsWith('body of ')) {
    return '${_translateMonsterOrItemName(s.substring(8))}の体';
  }

  const monsterMap = {
    // A
    'abbot': '師範',
    'acid blob': '酸のブロッブ',
    'acolyte': '侍者',
    'air elemental': '風のエレメンタル',
    'Aleax': 'アレアックス',
    'aligned priest': '神官',
    'Angel': '天使',
    'ape': '類人猿',
    'apprentice': '実習生',
    'Arch Priest': '主席司祭',
    'arch-lich': 'アーチリッチ',
    'archeologist': '考古学者',
    'Archon': 'アルコン',
    'Ashikaga Takauji': '足利尊氏',
    'Asmodeus': 'アスモデウス',
    'attendant': '随行員',
    // B
    'Baalzebub': 'ベルゼブブ',
    'baby black dragon': '赤ん坊ブラックドラゴン',
    'baby blue dragon': '赤ん坊ブルードラゴン',
    'baby crocodile': 'ワニの子供',
    'baby dragon': '赤ん坊ドラゴン',
    'baby gold dragon': '金色ドラゴンの子供',
    'baby gray dragon': '赤ん坊グレードラゴン',
    'baby green dragon': '赤ん坊グリーンドラゴン',
    'baby long worm': 'ロングワームの子供',
    'baby orange dragon': '赤ん坊オレンジドラゴン',
    'baby purple worm': '紫ワームの子供',
    'baby red dragon': '赤ん坊レッドドラゴン',
    'baby shimmering dragon': '揺らめくドラゴンの子供',
    'baby silver dragon': '赤ん坊シルバードラゴン',
    'baby white dragon': '赤ん坊ホワイトドラゴン',
    'baby yellow dragon': '赤ん坊イエロードラゴン',
    'balrog': 'バルログ',
    'baluchitherium': 'バルキテリウム',
    'barbarian': '野蛮人',
    'barbed devil': '棘の悪魔',
    'barrow wight': 'バロウ・ワイト',
    'bat': 'コウモリ',
    'beholder': 'ビホルダー',
    'black dragon': 'ブラックドラゴン',
    'black light': '黒色の光',
    'black naga': 'ブラックナーガ',
    'black naga hatchling': 'ブラックナーガの子供',
    'black pudding': 'ブラックプリン',
    'black unicorn': '一角獣（黒）',
    'blue dragon': 'ブルードラゴン',
    'blue jelly': '青色ゼリー',
    'bone devil': '骨の悪魔',
    'brown mold': '茶色モールド',
    'brown pudding': 'ブラウンプリン',
    'bugbear': 'バグベアー',
    // C
    'captain': '指揮官',
    'carnivorous ape': '人喰い猿',
    'cave spider': '洞窟クモ',
    'caveman': '洞窟人',
    'cavewoman': '洞窟人',
    'centipede': 'ムカデ',
    'Cerberus': 'ケルベロス',
    'chameleon': 'カメレオン',
    'Charon': 'カロン',
    'chickatrice': 'チカトリス',
    'chieftain': '首領',
    'Chromatic Dragon': 'クロマティック・ドラゴン',
    'clay golem': '土ゴーレム',
    'cobra': 'コブラ',
    'cockatrice': 'コカトリス',
    'couatl': 'コウアトル',
    'coyote': 'コヨーテ',
    'crocodile': 'ワニ',
    'Croesus': 'クロイソス',
    'Cyclops': 'サイクロプス',
    // D
    'Dark One': '暗きもの',
    'Death': 'デス',
    'demilich': 'デミリッチ',
    'Demogorgon': 'デモゴルゴン',
    'dingo': 'ディンゴ',
    'disenchanter': '吸魔の怪物',
    'Dispater': 'ディスペータ',
    'displacer beast': 'ディスプレイサービースト',
    'djinni': 'ジン',
    'dog': '犬',
    'doppelganger': 'ドッペルゲンガー',
    'dragon': 'ドラゴン',
    'dust vortex': 'ほこりの渦',
    'dwarf': 'ドワーフ',
    'dwarf mummy': 'ドワーフのミイラ',
    'dwarf zombie': 'ドワーフのゾンビ',
    // E
    'Earendil': 'エアレンディル',
    'earth elemental': '土のエレメンタル',
    'electric eel': '電気ウナギ',
    'elf': 'エルフ',
    'elf mummy': 'エルフのミイラ',
    'elf zombie': 'エルフのゾンビ',
    'Elwing': 'エルウィング',
    'energy vortex': 'エネルギーの渦',
    'erinys': 'イリニス',
    'ettin': 'エティン',
    'ettin mummy': 'エティンのミイラ',
    'ettin zombie': 'エティンのゾンビ',
    // F
    'Famine': 'フェミン',
    'fire ant': '火アリ',
    'fire elemental': '火のエレメンタル',
    'fire giant': '炎の巨人',
    'fire vortex': '炎の渦',
    'flaming sphere': '炎の球体',
    'flesh golem': '肉ゴーレム',
    'floating eye': '浮遊する目',
    'fog cloud': '霧の雲',
    'forest centaur': '森のケンタウロス',
    'fox': 'キツネ',
    'freezing sphere': '氷の球体',
    'frost giant': '吹雪の巨人',
    // G
    'gargoyle': 'ガーゴイル',
    'garter snake': 'ガータースネーク',
    'gas spore': '包子ガス',
    'gecko': 'ヤモリ',
    'gelatinous cube': 'ゼラチンキューブ',
    'genetic engineer': '遺伝子工学者',
    'Geryon': 'ゲーリュオーン',
    'ghost': '幽霊',
    'ghoul': 'グール',
    'giant': '巨人',
    'giant ant': '巨大アリ',
    'giant bat': '巨大コウモリ',
    'giant beetle': '巨大カブトムシ',
    'giant eel': '巨大ウナギ',
    'giant mimic': '巨大なミミック',
    'giant mummy': '巨人のミイラ',
    'giant rat': '巨大ネズミ',
    'giant spider': '巨大クモ',
    'giant wasp': '巨大スズメバチ',
    'giant zombie': '巨人のゾンビ',
    'glass golem': 'ガラスゴーレム',
    'glass piercer': 'ガラスピアサー',
    'gnome': 'ノーム',
    'gnome leader': 'ノームの首領',
    'gnome mummy': 'ノームのミイラ',
    'gnome ruler': 'ノームの支配者',
    'gnome zombie': 'ノームのゾンビ',
    'gnomish wizard': 'ノームの魔法使い',
    'goblin': 'ゴブリン',
    'Goblin King': 'ゴブリンの王',
    'goblin leader': 'ゴブリンの首領',
    'gold dragon': '金色ドラゴン',
    'gold golem': '金のゴーレム',
    'golden naga': 'ゴールデンナーガ',
    'golden naga hatchling': 'ゴールデンナーガの子供',
    'golem': 'ゴーレム',
    'Grand Master': '総師範',
    'gray dragon': 'グレードラゴン',
    'gray ooze': 'グレーウーズ',
    'gray unicorn': '一角獣（灰）',
    'green dragon': 'グリーンドラゴン',
    'green mold': '緑色モールド',
    'green slime': '緑スライム',
    'Green-elf': '緑エルフ',
    'gremlin': 'グレムリン',
    'Grey-elf': '灰色エルフ',
    'grid bug': 'グリッドバグ',
    'guard': '番兵',
    'guardian naga': 'ガーディアンナーガ',
    'guardian naga hatchling': 'ガーディアンナーガの子供',
    'guide': 'ガイド',
    // H
    'healer': '治療師',
    'hell hound': 'ヘルハウンド',
    'hell hound pup': 'ヘルハウンドの子',
    'hezrou': 'ヘズロウ',
    'high priest': '高位神官',
    'High-elf': 'ハイエルフ',
    'hill giant': '丘の巨人',
    'hill orc': '丘オーク',
    'Hippocrates': 'ヒポクラテス',
    'hobbit': 'ホビット',
    'hobgoblin': 'ホブゴブリン',
    'homunculus': 'ホムンクルス',
    'horned devil': '角のある悪魔',
    'horse': '馬',
    'housecat': '猫',
    'human': '人間',
    'human mummy': '人間のミイラ',
    'human werejackal': 'ジャッカル人間',
    'human wererat': 'ねずみ人間',
    'human werewolf': '狼人間',
    'human zombie': '人間のゾンビ',
    'hunter': 'ハンター',
    // I
    'ice devil': '氷の悪魔',
    'ice troll': '氷トロル',
    'ice vortex': '氷の渦',
    'iguana': 'イグアナ',
    'imp': 'インプ',
    'incubus': 'インキュバス',
    'iron golem': '鉄ゴーレム',
    'iron piercer': 'アイアンピアサー',
    'Ixoth': 'イクソス',
    // J
    'jabberwock': 'ジャバウォック',
    'jackal': 'ジャッカル',
    'jaguar': 'ジャガー',
    'jellyfish': 'クラゲ',
    'Juiblex': 'ジョウビレックス',
    // K
    'keystone kop': '警備員',
    'ki-rin': '麒麟',
    'killer bee': '殺人バチ',
    'King Arthur': 'アーサー王',
    'kitten': '子猫',
    'knight': '騎士',
    'kobold': 'コボルド',
    'kobold lord': 'コボルドの君主',
    'kobold mummy': 'コボルドのミイラ',
    'kobold shaman': 'コボルドの呪術師',
    'kobold zombie': 'コボルドのゾンビ',
    'kop kaptain': '警部',
    'kop lieutenant': '警部補',
    'kop sergeant': '巡査部長',
    'kraken': 'クラーケン',
    // L
    'large cat': '大型猫',
    'large dog': '大型犬',
    'large kobold': '大型コボルド',
    'large mimic': '大きなミミック',
    'leather golem': '革ゴーレム',
    'lemure': 'レムレース',
    'leocrotta': 'レオクロッタ',
    'leprechaun': 'レプラコーン',
    'lich': 'リッチ',
    'lichen': '地衣類',
    'lieutenant': '副官',
    'little dog': '子犬',
    'lizard': 'トカゲ',
    'long worm': 'ロングワーム',
    'long worm tail': 'ロングワームの尻尾',
    'Lord Carnarvon': 'カーナボン卿',
    'Lord Sato': '大名佐藤',
    'Lord Surtur': '支配者スルト',
    'lurker above': 'ラーカー',
    'lynx': 'ヤマネコ',
    // M
    'Mail Daemon': 'メイルデーモン',
    'manes': '亡霊',
    'marilith': 'マリリス',
    'Master Assassin': '暗殺者の頭領',
    'Master Kaen': 'カエン',
    'master lich': 'マスターリッチ',
    'master mind flayer': 'マスター・マインドフレア',
    'Master of Thieves': '盗賊の頭領',
    'mastodon': 'マストドン',
    'Medusa': 'メデューサ',
    'mind flayer': 'マインドフレア',
    'Minion of Huhetotl': 'フヘトトルの使い',
    'minotaur': 'ミノタウロス',
    'mirkwood orc': '闇の森のオーク',
    'mirkwood spider': '闇の森のクモ',
    'monk': '修道士',
    'monkey': '猿',
    'mordor orc': 'モルドールのオーク',
    'mountain centaur': '山のケンタウロス',
    'mountain nymph': '山のニンフ',
    'mumak': 'ムーマク',
    // N
    'nalfeshnee': 'ナルフェシニ',
    'Nalzok': 'ナルゾク',
    'Nazgul': 'ナズグル',
    'neanderthal': 'ネアンデルタール人',
    'Neferet the Green': '緑のネフェレト',
    'newt': 'イモリ',
    'ninja': '忍者',
    'Norn': 'ノルン',
    'nurse': '看護婦',
    // O
    'ochre jelly': '黄土色ゼリー',
    'ogre': 'オーガ',
    'ogre leader': 'オーガの首領',
    'ogre tyrant': 'オーガの暴君',
    'olog-hai': 'オログ・ハイ',
    'oracle': '賢者',
    'orange dragon': 'オレンジドラゴン',
    'orc': 'オーク',
    'orc captain': 'オークの隊長',
    'orc mummy': 'オークのミイラ',
    'orc shaman': 'オークの呪術師',
    'orc zombie': 'オークのゾンビ',
    'orc-captain': 'オークの隊長',
    'Orcus': 'オーケス',
    'Orion': '勇者オリオン',
    'owlbear': 'アウルベア',
    // P
    'page': '小姓',
    'panther': 'パンサー',
    'paper golem': '紙のゴーレム',
    'Pelias': 'ペリアス',
    'Pestilence': 'ペスティレンス',
    'piranha': 'ピラニア',
    'pit fiend': '穴の悪霊',
    'pit viper': 'マムシ',
    'plains centaur': '草原のケンタウロス',
    'pony': 'ポニー',
    'priest': '僧侶',
    'priestess': '僧侶',
    'prisoner': '囚人',
    'purple worm': '紫ワーム',
    'pyrolisk': 'パイロリスク',
    'python': 'ニシキヘビ',
    // Q
    'quantum mechanic': '量子力学者',
    'quasit': 'クアシト',
    'queen bee': '女王バチ',
    'quivering blob': '震えるブロッブ',
    // R
    'rabid rat': '兇暴ネズミ',
    'ranger': '旅人',
    'raven': 'オオガラス',
    'red dragon': 'レッドドラゴン',
    'red mold': '赤色モールド',
    'red naga': 'レッドナーガ',
    'red naga hatchling': 'レッドナーガの子供',
    'rock mole': '岩モグラ',
    'rock piercer': 'ロックピアサー',
    'rock troll': '岩トロル',
    'rogue': '盗賊',
    'rope golem': '縄ゴーレム',
    'roshi': '浪士',
    'rothe': 'ロゼ',
    'rust monster': '錆の怪物',
    // S
    'salamander': 'サラマンダー',
    'samurai': '侍',
    'sandestin': 'サンデスティン',
    'sasquatch': 'サスカッチ',
    'scorpion': 'サソリ',
    'Scorpius': '大蠍',
    'sergeant': '下士官',
    'sewer rat': 'ドブネズミ',
    'shade': '影',
    'Shaman Karnov': '呪術師カルノフ',
    'shark': 'サメ',
    'shimmering dragon': '揺らめくドラゴン',
    'shocking sphere': '電撃の球体',
    'shopkeeper': '店主',
    'shrieker': 'シュリーカー',
    'silver dragon': 'シルバードラゴン',
    'skeleton': 'スケルトン',
    'small mimic': '小さなミミック',
    'snake': 'ヘビ',
    'soldier': '兵士',
    'soldier ant': '兵隊アリ',
    'spotted jelly': 'マダラゼリー',
    'stalker': 'ストーカー',
    'steam vortex': '蒸気の渦',
    'stone giant': '岩石巨人',
    'stone golem': '石ゴーレム',
    'storm giant': '雷の巨人',
    'straw golem': '藁ゴーレム',
    'student': '学生',
    'succubus': 'サキュバス',
    // T
    'tengu': '天狗',
    'Thoth Amon': 'トート・アモン',
    'thug': 'ちんぴら',
    'tiger': 'トラ',
    'titan': 'タイタン',
    'titanothere': 'チタノゼア',
    'tourist': '観光客',
    'trapper': 'トラッパー',
    'troll': 'トロル',
    'Twoflower': 'ツーフラワー',
    // U
    'umber hulk': 'アンバーハルク',
    'uruk-hai': 'ウルク・ハイ',
    // V
    'valkyrie': 'バルキリー',
    'vampire': 'ヴァンパイア',
    'vampire bat': '吸血コウモリ',
    'vampire lord': 'ヴァンパイアロード',
    'vampire mage': 'ヴァンパイアメイジ',
    'violet fungus': '紫キノコ',
    'Vlad the Impaler': 'ヴラド公',
    'vorpal jabberwock': 'ヴォーパル・ジャバウォック',
    'vrock': 'ヴァロック',
    // W
    'warg': 'ワーグ',
    'warhorse': '軍馬',
    'warrior': '戦士',
    'wasp': 'スズメバチ',
    'watch captain': '警備隊長',
    'watchman': 'ウォッチマン',
    'water demon': '水の魔神',
    'water elemental': '水のエレメンタル',
    'water moccasin': '水ヘビ',
    'water nymph': '水のニンフ',
    'water troll': '水トロル',
    'werejackal': '狼人間（ジャッカル）',
    'wererat': 'ねずみ人間',
    'werewolf': '狼人間',
    'white dragon': 'ホワイトドラゴン',
    'white unicorn': '一角獣（白）',
    'winged gargoyle': '羽のあるガーゴイル',
    'wingless gargoyle': '羽無しのガーゴイル',
    'winter wolf': '冬狼',
    'winter wolf cub': '冬狼の子',
    'wizard': '魔法使い',
    'Wizard of Yendor': 'イェンダーの魔法使い',
    'wolf': '狼',
    'wood golem': '木ゴーレム',
    'wood nymph': '木のニンフ',
    'woodchuck': 'ウッドチャック',
    'Woodland-elf': '森のエルフ',
    'wraith': 'レイス',
    'wumpus': 'ワンパス',
    // X
    'xan': 'ザン',
    'xorn': 'ゾーン',
    // Y
    'Yeenoghu': 'イーノグ',
    'yellow dragon': 'イエロードラゴン',
    'yellow light': '黄色の光',
    'yellow mold': '黄色モールド',
    'yeti': 'イエティ',
    // Z
    'zombie': 'ゾンビ',
    'zruty': 'ズルティ',
  };

  if (monsterMap.containsKey(s)) {
    return monsterMap[s]!;
  }

  // 複数形（s / es）に対するフォールバック単数化
  if (s.endsWith('s')) {
    var singular = s.substring(0, s.length - 1);
    if (monsterMap.containsKey(singular)) {
      return monsterMap[singular]!;
    }
    if (s.endsWith('es')) {
      singular = s.substring(0, s.length - 2);
      if (monsterMap.containsKey(singular)) {
        return monsterMap[singular]!;
      }
    }
  }

  const itemAndEnvironmentMap = {
    // A
    'acid': '酸',
    'acidic corpse': '酸性の死体',
    'acidic glob': '酸性の塊',
    'adornment': '飾りの指輪',
    'agate': 'めのう',
    'aggravate monster': '反感の指輪',
    'aklys': 'アキリス',
    'alchemic blast': '錬金術の爆発',
    'alchemy smock': '錬金術の仕事着',
    'Amaterasu Omikami': '天照大神',
    'amber': '琥珀',
    'amethyst': 'アメジスト',
    'amnesia': '記憶喪失の巻物',
    'Amulet': 'アミュレット',
    'amulet of amulet of change': '性転換の魔除け',
    'amulet of amulet of ESP': '遠視の魔除け',
    'amulet of amulet of flying': '飛行の魔除け',
    'amulet of amulet of guarding': '守りの魔除け',
    'amulet of amulet of life saving': '命の魔除け',
    'amulet of amulet of magical breathing': '呼吸の魔除け',
    'amulet of amulet of reflection': '反射の魔除け',
    'amulet of amulet of restful sleep': '安眠の魔除け',
    'amulet of amulet of strangulation': '絞殺の魔除け',
    'amulet of amulet of unchanging': '耐へんげの魔除け',
    'amulet of amulet versus poison': '耐毒の魔除け',
    'amulet of change': '性転換の魔除け',
    'amulet of ESP': '遠視の魔除け',
    'amulet of flying': '飛行の魔除け',
    'amulet of guarding': '守りの魔除け',
    'amulet of life saving': '命の魔除け',
    'amulet of magical breathing': '呼吸の魔除け',
    'amulet of reflection': '反射の魔除け',
    'amulet of restful sleep': '安眠の魔除け',
    'amulet of strangulation': '絞殺の魔除け',
    'amulet of unchanging': '耐へんげの魔除け',
    'Amulet of Yendor': 'イェンダーのアミュレット',
    'amulet versus poison': '耐毒の魔除け',
    'Anhur': 'アンフル',
    'anti-magic trap': '反魔法の罠',
    'Anubis': 'アヌビス',
    'apple': 'りんご',
    'aquamarine': 'アクアマリン',
    'arrow': '矢',
    'arrows': '矢',
    'athame': 'アサメ',
    'Athena': 'アテナ',
    'axe': '斧',
    // B
    'bag of holding': '軽量化の鞄',
    'bag of tricks': 'トリックの鞄',
    'banana': 'バナナ',
    'banded mail': '帯金の鎧',
    'bardiche': 'バーディック',
    'battle-axe': 'バトルアックス',
    'bear trap': 'トラバサミ',
    'beartrap': '熊の罠',
    'bec de corbin': 'ベック・ド・コルバン',
    'bell': 'ベル',
    'Bell of Opening': '開放の鐘',
    'bill-guisarme': 'ビル・ギザルム',
    'black opal': '黒オパール',
    'blank paper': '白紙の巻物',
    'Blind Io': 'ブラインド・アイオー',
    'blindness': '盲目の薬',
    'bog': '湿原',
    'Book of the Dead': '死者の書',
    'boomerang': 'ブーメラン',
    'booze': '酔っぱらいの薬',
    'boulder': '大岩',
    'bow': '弓',
    'brass lantern': '真鍮のランタン',
    'Brigit': 'ブリギッド',
    'broadsword': 'ブロードソード',
    'bronze plate mail': '青銅の鎧',
    'bugle': 'ラッパ',
    'bullwhip': '鞭',
    // C
    'C-ration': 'Ｃレーション',
    'cadaver': '腐った死体',
    'Camazotz': 'カマソッソ',
    'can of grease': '脂の缶',
    'cancellation': '無力化の杖',
    'Candelabrum of Invocation': '祈りの燭台',
    'candy bar': 'キャンディバー',
    'carnivorous bag': '人食い袋',
    'carrot': 'にんじん',
    'ceiling': '天井',
    'chain mail': '鎖かたびら',
    'charging': '充填の巻物',
    'cheap plastic imitation of the Amulet of Yendor': 'イェンダーの魔除けの模造品',
    'chest': '宝箱',
    'Chih Sung Tzi': '赤松子',
    'chrysoberyl': '金緑石',
    'citrine': '黄水晶',
    'Cleaver': 'クリーバー',
    'cloak of displacement': '幻影のクローク',
    'cloak of invisibility': '透明のクローク',
    'cloak of magic resistance': '魔法を防ぐクローク',
    'cloak of protection': '守りのクローク',
    'closing drawbridge': '閉まる跳ね橋',
    'clove of garlic': 'にんにく片',
    'club': 'こん棒',
    'cold': '吹雪の杖',
    'cold resistance': '耐冷の指輪',
    'collapsing drawbridge': '跳ね橋の崩壊',
    'conflict': '争いの指輪',
    'confuse monster': '怪物を混乱させる巻物',
    'confusion': '混乱の薬',
    'contusion from a small passage': '狭い通路で頭を打ったこと',
    'cornuthaum': 'くぼんだ鍋',
    'corpse': '死体',
    'cram ration': '携帯糧食',
    'cream pie': 'クリームパイ',
    'create monster': '怪物を造る杖',
    'credit card': 'クレジットカード',
    'Croesus': 'クロイソス',
    'Crom': 'クロム',
    'crossbow': 'クロスボウ',
    'crossbow bolt': 'ボルト',
    'crossbow bolts': 'ボルト',
    'crysknife': 'クリスナイフ',
    'crystal ball': '水晶の玉',
    'crystal plate mail': '水晶の鎧',
    'Cthulhu': 'クトゥルフ',
    // D
    'dagger': '短剣',
    'dart': 'ダーツ',
    'darts': 'ダーツ',
    'death': '死の杖',
    'death field': '死のフィールド',
    'deep water': '深い水',
    'Demonbane': 'デーモンベイン',
    'dented pot': 'くぼんだ鍋',
    'destroy armor': '鎧を破壊する巻物',
    'diamond': 'ダイヤモンド',
    'digging': '穴掘りの杖',
    'dilithium crystal': 'ディリジウムの結晶',
    'disintegration field': '分解フィールド',
    'Dragonbane': 'ドラゴンベイン',
    'drum of earthquake': '地震の太鼓',
    'dwarvish cloak': 'ドワーフのクローク',
    'dwarvish iron helm': 'ドワーフの鉄兜',
    'dwarvish mattock': 'ドワーフのつるはし',
    'dwarvish mithril-coat': 'ドワーフのミスリル服',
    'dwarvish roundshield': 'ドワーフの丸盾',
    'dwarvish short sword': 'ドワーフの小剣',
    'dwarvish spear': 'ドワーフの槍',
    // E
    'earth': '大地の巻物',
    'egg': '卵',
    'Elbereth': 'エルベレス',
    'electric shock': '電撃',
    'elven arrow': 'エルフの矢',
    'elven boots': 'エルフの靴',
    'elven bow': 'エルフの弓',
    'elven broadsword': 'エルフの幅広の剣',
    'elven cloak': 'エルフのクローク',
    'elven dagger': 'エルフの短剣',
    'elven leather helm': 'エルフの革帽子',
    'elven mithril-coat': 'エルフのミスリル服',
    'elven shield': 'エルフの盾',
    'elven short sword': 'エルフの小剣',
    'elven spear': 'エルフの槍',
    'emerald': 'エメラルド',
    'enchant armor': '鎧に魔法をかける巻物',
    'enchant weapon': '武器に魔法をかける巻物',
    'enlightenment': '啓蒙の杖',
    'enormous meatball': '巨大な肉団子',
    'eucalyptus leaf': 'ユーカリの葉',
    'Excalibur': 'エクスカリバー',
    'expensive camera': '高価なカメラ',
    'exploding crystal ball': '水晶の玉の爆発',
    'exploding drawbridge': '跳ね橋の爆発',
    'extra healing': '超回復の薬',
    'Eye of the Aethiopica': 'エチオピカの目',
    'Eyes of the Overworld': 'オーバーワールドの目',
    // F
    'falling drawbridge': '落ちてくる跳ね橋',
    'Fate': 'フェイト',
    'fauchard': 'フォシャール',
    'fedora': 'フィドーラ',
    'figurine': '人形',
    'fire': '炎の杖',
    'Fire Brand': 'ファイアブランド',
    'fire horn': '炎のホルン',
    'fire resistance': '耐炎の指輪',
    'fire trap': '火炎の罠',
    'flail': 'フレイル',
    'flint': '火打ち石',
    'fluorite': 'フルオライト',
    'food detection': '食料を探す巻物',
    'food ration': '食料',
    'fortune cookie': 'フォーチュンクッキー',
    'fountain': '泉',
    'free action': '自由行動の指輪',
    'Frost Brand': 'フロストブランド',
    'frost horn': '吹雪のホルン',
    'fruit juice': 'フルーツジュース',
    'full healing': '完全回復の薬',
    'fumble boots': 'つまずきの靴',
    // G
    'gain ability': '能力獲得の薬',
    'gain constitution': '体力の指輪',
    'gain energy': '魔力の薬',
    'gain level': 'レベルアップの薬',
    'gain strength': '強さの指輪',
    'garnet': 'ガーネット',
    'gauntlets of dexterity': '器用さの小手',
    'gauntlets of fumbling': 'お手玉の小手',
    'gauntlets of power': '力の小手',
    'genocide': '虐殺の巻物',
    'Giantslayer': 'ジャイアントスレイヤー',
    'glaive': 'グレイブ',
    'glob of black pudding': '黒プリンの塊',
    'glob of brown pudding': '茶色プリンの塊',
    'glob of gray ooze': '灰色ウーズの塊',
    'glob of green slime': '緑スライムの塊',
    'gold detection': '金貨を探す巻物',
    'grappling hook': 'ひっかけ棒',
    'Grayswandir': 'グレイスワンディル',
    'Grimtooth': 'グリムトゥース',
    'guisarme': 'ギザルム',
    // H
    'halberd': 'ハルバード',
    'hallucination': '幻覚の薬',
    'Hawaiian shirt': 'アロハシャツ',
    'healing': '回復の薬',
    'Heart of Ahriman': 'アーリマンの心臓',
    'heavy iron ball': '重い鉄の球',
    'helm of brilliance': '兜',
    'helm of caution': '知性の兜',
    'helm of opposite alignment': '逆属性の兜',
    'helm of telepathy': 'テレパシーの兜',
    'helmet': '兜',
    'Hermes': 'ヘルメス',
    'high boots': 'かかとの高い靴',
    'hole': '穴',
    'holy water': '聖水',
    'horn of plenty': '恵みのホルン',
    'Huan Ti': '黄帝',
    'Huitzilopochtli': 'ウィツィロポチトリ',
    'hunger': '飢餓の指輪',
    // I
    'ice box': 'アイスボックス',
    'identify': '識別の巻物',
    'imperious order': '傲慢な命令',
    'increase accuracy': '命中の指輪',
    'increase damage': '攻撃の指輪',
    'invisibility': '透明の薬',
    'iron ball': '鉄の球',
    'iron chain': '鉄の鎖',
    'iron shoes': '鉄の靴',
    'Ishtar': 'イシュタル',
    // J
    'jacinth': '橙水晶',
    'jade': 'ひすい',
    'jasper': 'ジャスパー',
    'javelin': '投げ槍',
    'jet': '黒玉',
    'jumping boots': '飛び跳ねる靴',
    // K
    'K-ration': 'Ｋレーション',
    'katana': '刀',
    'kelp frond': '昆布',
    'kicking boots': '蹴り挙げ靴',
    'knife': 'ナイフ',
    // L
    'lake': '湖',
    'lance': 'ランス',
    'land mine': '地雷',
    'large box': '大箱',
    'large shield': '大きな盾',
    'lava': '溶岩',
    'leash': '紐',
    'leather armor': '革鎧',
    'leather cloak': '革のクローク',
    'leather drum': '革の太鼓',
    'leather gloves': '革の手袋',
    'leather jacket': '革の服',
    'lembas wafer': 'レンバス',
    'level teleport trap': '階層テレポートの罠',
    'levitation': '浮遊の薬',
    'levitation boots': '浮遊の靴',
    'life drainage': '生命力吸収',
    'light': '灯りの杖',
    'lightning': '雷の杖',
    'limitless water': '無限の水',
    'little dart': '小さなダーツ',
    'loadstone': '重し',
    'lock pick': '鍵開け器具',
    'locking': '施錠の杖',
    'Loki': 'ロキ',
    'long sword': 'ロングソード',
    'Longbow of Diana': 'ディアナの長弓',
    'low boots': 'かかとの低い靴',
    'lucern hammer': 'ルッツェルンハンマー',
    'luckstone': '幸せの石',
    'Lugh': 'ルー',
    'lump of royal jelly': 'ロイヤルゼリー',
    // M
    'mace': 'メイス',
    'magic flute': '魔法のフルート',
    'magic harp': '魔法の竪琴',
    'magic lamp': '魔法のランプ',
    'magic mapping': '地図の巻物',
    'magic marker': '魔法のマーカ',
    'Magic Mirror of Merlin': 'マーリンの魔法の鏡',
    'magic missile': '矢の杖',
    'magic trap': '魔法の罠',
    'magic whistle': '魔法の笛',
    'Magicbane': 'マジックベイン',
    'mail': '手紙の巻物',
    'make invisible': '透明化の杖',
    'Manannan Mac Lir': 'マナナン・マクリル',
    'Master Key of Thievery': '盗賊術のマスターキー',
    'meat ring': '肉の輪',
    'meat stick': '肉の串',
    'meatball': '肉団子',
    'Medusa': 'メドゥーサ',
    'melon': 'メロン',
    'mildly contaminated potion': '少し古くなった薬',
    'mine shaft': '坑道の竪穴',
    'mirror': '鏡',
    'Mitra': 'ミトラ',
    'Mitre of Holiness': '神聖の僧帽',
    'Mjollnir': 'ミョルニル',
    'moat': 'お堀',
    'Moloch': 'モロク',
    'molten lava': '溶融した溶岩',
    'monster detection': '怪物を探す薬',
    'morning star': 'モーニングスター',
    'mummy wrapping': 'ミイラの包帯',
    // N
    'needle': '針',
    'needles': '針',
    'nothing': '単なる杖',
    'novel': '小説',
    // O
    'object detection': '物体を探す薬',
    'obsidian': '黒燿石',
    'ocean': '洋',
    'Odin': 'オーディン',
    'Offler': 'オフラー',
    'Ogresmasher': 'オウガスマッシャー',
    'oil': '油',
    'oil lamp': 'オイルランプ',
    'oilskin cloak': '防水クローク',
    'oilskin sack': '防水袋',
    'opal': 'オパール',
    'opening': '開錠の杖',
    'orange': 'オレンジ',
    'Orb of Detection': '探知のオーブ',
    'Orb of Fate': '運命のオーブ',
    'orcish arrow': 'オークの矢',
    'orcish bow': 'オークの弓',
    'orcish chain mail': 'オークの鎖かたびら',
    'orcish cloak': 'オークのクローク',
    'orcish dagger': 'オークの短剣',
    'orcish helm': 'オークの兜',
    'orcish ring mail': 'オークの鉄環の鎧',
    'orcish shield': 'オークの盾',
    'orcish short sword': 'オークの小剣',
    'orcish spear': 'オークの槍',
    'Orcrist': 'オークリスト',
    'overexertion': '力尽きたこと',
    // P
    'pancake': 'パンケーキ',
    'paralysis': '麻痺の薬',
    'partisan': 'パルチザン',
    'pear': '梨',
    'pick-axe': 'つるはし',
    'pit': '落とし穴',
    'plate mail': '鋼鉄の鎧',
    'Platinum Yendorian Express Card': 'プラチナイェンダー印エクスプレスカード',
    'poison resistance': '耐毒の指輪',
    'poisoned needle': '毒針',
    'poisoned needles': '毒針',
    'polymorph': 'へんげの杖',
    'polymorph control': 'へんげ制御の指輪',
    'polymorph trap': 'へんげの罠',
    'pool': '水たまり',
    'pool of water': '水たまり',
    'Poseidon': 'ポセイドン',
    'potion': '薬',
    'potion of acid': '酸の薬',
    'potion of blindness': '盲目の薬',
    'potion of booze': '酔っぱらいの薬',
    'potion of confusion': '混乱の薬',
    'potion of enlightenment': '啓蒙の薬',
    'potion of extra healing': '超回復の薬',
    'potion of fruit juice': 'フルーツジュース',
    'potion of full healing': '完全回復の薬',
    'potion of gain ability': '能力獲得の薬',
    'potion of gain energy': '魔力の薬',
    'potion of gain level': 'レベルアップの薬',
    'potion of hallucination': '幻覚の薬',
    'potion of healing': '回復の薬',
    'potion of holy water': '聖水',
    'potion of invisibility': '透明の薬',
    'potion of levitation': '浮遊の薬',
    'potion of monster detection': '怪物を探す薬',
    'potion of object detection': '物体を探す薬',
    'potion of oil': '油',
    'potion of paralysis': '麻痺の薬',
    'potion of polymorph': 'へんげの薬',
    'potion of restore ability': '能力回復の薬',
    'potion of see invisible': '可視の薬',
    'potion of sickness': '病気の薬',
    'potion of sleeping': '睡眠の薬',
    'potion of speed': '加速の薬',
    'potion of unholy water': '不浄な水',
    'potion of water': '水',
    'probing': '探査する杖',
    'protection': '守りの指輪',
    'protection from shape changers': '耐へんげの指輪',
    'Ptah': 'プタハ',
    'punishment': '罰の巻物',
    // Q
    'quarterstaff': '六尺棒',
    'Quetzalcoatl': 'ケツァルコアトル',
    // R
    'Raijin': '雷神',
    'ranseur': 'ランサー',
    'regeneration': '回復の指輪',
    'remove curse': '解呪の巻物',
    'residual undead turning effect': 'アンデッド退散の残留効果',
    'resistance timing out': '耐性の時間切れ',
    'restore ability': '能力回復の薬',
    'ring': '指輪',
    'ring mail': '鉄環の鎧',
    'ring of adornment': '飾りの指輪',
    'ring of aggravate monster': '反感の指輪',
    'ring of cold resistance': '耐冷の指輪',
    'ring of conflict': '争いの指輪',
    'ring of fire resistance': '耐炎の指輪',
    'ring of free action': '自由行動の指輪',
    'ring of gain constitution': '体力の指輪',
    'ring of gain strength': '強さの指輪',
    'ring of hunger': '飢餓の指輪',
    'ring of increase accuracy': '命中の指輪',
    'ring of increase damage': '攻撃の指輪',
    'ring of invisibility': '透明の指輪',
    'ring of levitation': '浮遊の指輪',
    'ring of poison resistance': '耐毒の指輪',
    'ring of polymorph': 'へんげの指輪',
    'ring of polymorph control': 'へんげ制御の指輪',
    'ring of protection': '守りの指輪',
    'ring of protection from shape changers': '耐へんげの指輪',
    'ring of regeneration': '回復の指輪',
    'ring of searching': '探索の指輪',
    'ring of see invisible': '可視の指輪',
    'ring of shock resistance': '耐電の指輪',
    'ring of slow digestion': '消化不良の指輪',
    'ring of stealth': '忍びの指輪',
    'ring of sustain ability': '能力維持の指輪',
    'ring of teleport control': '瞬間移動制御の指輪',
    'ring of teleportation': '瞬間移動の指輪',
    'ring of warning': '警告の指輪',
    'river': '川',
    'robe': 'ローブ',
    'rock': '石',
    'rolling boulder': '転がる大岩',
    'rolling boulder trap': '転がる大岩の罠',
    'rotted glob': '腐った塊',
    'rotten lump of royal jelly': '腐ったローヤルゼリーの塊',
    'rubber hose': 'ゴムホース',
    'ruby': 'ルビー',
    'runesword': 'ルーンの剣',
    'rust trap': '錆の罠',
    // S
    'sack': '袋',
    'saddle': '鞍',
    'sapphire': 'サファイア',
    'scale mail': '鱗の鎧',
    'scalpel': 'メス',
    'scare monster': '怪物を怯えさせる巻物',
    'Sceptre of Might': '力の王笏',
    'scimitar': 'シミター',
    'scroll': '巻物',
    'scroll of amnesia': '記憶喪失の巻物',
    'scroll of blank paper': '白紙の巻物',
    'scroll of charging': '充填の巻物',
    'scroll of confuse monster': '怪物を混乱させる巻物',
    'scroll of create monster': '怪物を作る巻物',
    'scroll of destroy armor': '鎧を破壊する巻物',
    'scroll of earth': '大地の巻物',
    'scroll of enchant armor': '鎧に魔法をかける巻物',
    'scroll of enchant weapon': '武器に魔法をかける巻物',
    'scroll of fire': '炎の巻物',
    'scroll of food detection': '食料を探す巻物',
    'scroll of genocide': '虐殺の巻物',
    'scroll of gold detection': '金貨を探す巻物',
    'scroll of identify': '識別の巻物',
    'scroll of light': '光の巻物',
    'scroll of magic mapping': '地図の巻物',
    'scroll of mail': '手紙の巻物',
    'scroll of punishment': '罰の巻物',
    'scroll of remove curse': '解呪の巻物',
    'scroll of scare monster': '怪物を怯えさせる巻物',
    'scroll of stinking cloud': '悪臭雲の巻物',
    'scroll of taming': '怪物を飼いならす巻物',
    'scroll of teleportation': '瞬間移動の巻物',
    'sea': '海',
    'searching': '探索の指輪',
    'secret door detection': '扉探索の杖',
    'see invisible': '可視の薬',
    'Set': 'セト',
    'Shan Lai Ching': '山海経',
    'shield of drain resistance': '吸命耐性の盾',
    'shield of reflection': '反射の盾',
    'shield of shock resistance': '電撃耐性の盾',
    'shock resistance': '耐電の指輪',
    'short sword': 'ショートソード',
    'shuriken': '手裏剣',
    'sickness': '病気の薬',
    'silver arrow': '銀の矢',
    'silver dagger': '銀の短剣',
    'silver mace': '銀のメイス',
    'silver saber': '銀のサーベル',
    'silver spear': '銀の槍',
    'skeleton key': '万能鍵',
    'sleep': '眠りの杖',
    'sleeping': '睡眠の薬',
    'sleeping gas trap': '睡眠ガスの罠',
    'slime mold': '果物',
    'sling': 'スリング',
    'slow digestion': '消化不良の指輪',
    'slow monster': '減速の杖',
    'small shield': '小さな盾',
    'Snickersnee': 'スニッカースニー',
    'spear': '槍',
    'speed': '加速の薬',
    'speed boots': '韋駄天の靴',
    'speed monster': '加速の杖',
    'spellbook': '魔法書',
    'spetum': 'スペタム',
    'spiked pit': '杭の穴',
    'splash of acid': '酸の飛沫',
    'splash of acid venom': '酸の毒液',
    'splash of blinding venom': '目潰しの毒液',
    'splint mail': '鉄片の鎧',
    'sprig of wolfsbane': 'トリカブト',
    'Staff of Aesculapius': 'アスクレピオスの杖',
    'stasis': '静止の杖',
    'statue': '石像',
    'statue trap': '石像の罠',
    'stealth': '忍びの指輪',
    'stethoscope': '聴診器',
    'stiletto': 'スティレット',
    'Sting': 'スティング',
    'stinking cloud': '悪臭雲の巻物',
    'Stormbringer': 'ストームブリンガー',
    'striking': '衝撃の杖',
    'studded leather armor': '鋲付き革鎧',
    'Sunsword': 'サンソード',
    'sustain ability': '能力維持の指輪',
    'swamp': '沼',
    'system shock': 'システムショック',
    // T
    'T-shirt': 'Ｔシャツ',
    'tallow candle': '獣脂のろうそく',
    'taming': '怪物を飼いならす巻物',
    'teleport control': '瞬間移動制御の指輪',
    'teleportation': '瞬間移動の杖',
    'teleportation trap': 'テレポートの罠',
    'The Eye of the Aethiopica': 'エチオピカの目',
    'The Eyes of the Overworld': 'オーバーワールドの目',
    'The Heart of Ahriman': 'アーリマンの心臓',
    'The Lady': 'ザ・レディ',
    'The Longbow of Diana': 'ディアナの長弓',
    'The Magic Mirror of Merlin': 'マーリンの魔法の鏡',
    'The Master Key of Thievery': '盗賊術のマスターキー',
    'The Mitre of Holiness': '神聖の僧帽',
    'The Orb of Detection': '探知のオーブ',
    'The Orb of Fate': '運命のオーブ',
    'The Platinum Yendorian Express Card': 'プラチナイェンダー印エクスプレスカード',
    'The Sceptre of Might': '力の王笏',
    'The Staff of Aesculapius': 'アスクレピオスの杖',
    'The Tsurugi of Muramasa': '村正の剣',
    'Thoth': 'トト',
    'tin': '缶詰',
    'tin opener': '缶切り',
    'tin whistle': 'ブリキの笛',
    'tinning kit': '缶詰作成道具',
    'tooled horn': '細工のほどこされたホルン',
    'topaz': 'トパーズ',
    'touchstone': '試金石',
    'trident': 'トライデント',
    'tripe ration': 'モツの塊',
    'Trollsbane': 'トロルズベイン',
    'tsurugi': '大刀',
    'Tsurugi of Muramasa': '村正の剣',
    'turquoise': 'トルコ石',
    'two-handed sword': '両手持ちの剣',
    'Tyr': 'ティール',
    // U
    'undead turning': '蘇生の杖',
    'unholy water': '不浄な水',
    'unicorn horn': 'ユニコーンの角',
    'Uruk-hai shield': 'ウルク＝ハイの盾',
    // V
    'Vlad the Impaler': '串刺し公ヴラド',
    'Vorpal Blade': 'ヴォーパルブレード',
    'voulge': 'ヴォウジェ',
    // W
    'wand': '杖',
    'wand of cancellation': '無力化の杖',
    'wand of cold': '吹雪の杖',
    'wand of create monster': '怪物を造る杖',
    'wand of death': '死の杖',
    'wand of digging': '穴掘りの杖',
    'wand of enlightenment': '啓蒙の杖',
    'wand of fire': '炎の杖',
    'wand of light': '灯りの杖',
    'wand of lightning': '雷の杖',
    'wand of locking': '施錠の杖',
    'wand of magic missile': '矢の杖',
    'wand of make invisible': '透明化の杖',
    'wand of nothing': '単なる杖',
    'wand of opening': '開錠の杖',
    'wand of polymorph': 'へんげの杖',
    'wand of probing': '探査する杖',
    'wand of secret door detection': '扉探索の杖',
    'wand of sleep': '眠りの杖',
    'wand of slow monster': '減速の杖',
    'wand of speed monster': '加速の杖',
    'wand of stasis': '静止の杖',
    'wand of striking': '衝撃の杖',
    'wand of teleportation': '瞬間移動の杖',
    'wand of undead turning': '蘇生の杖',
    'wand of wishing': '願いの杖',
    'war hammer': 'ウォーハンマー',
    'warning': '警告の指輪',
    'water': '水',
    'water walking boots': '水上歩行の靴',
    'wax candle': '蜜蝋のろうそく',
    'web': 'クモの巣',
    'Werebane': 'ウェアベイン',
    'wishing': '願いの杖',
    'Wizard of Yendor': 'イェンダーの魔法使い',
    'wooden flute': '木のフルート',
    'wooden harp': '木の竪琴',
    'worm tooth': 'ワームの歯',
    'worthless piece of black glass': '黒色のガラス',
    'worthless piece of blue glass': '青いガラス',
    'worthless piece of green glass': '緑のガラス',
    'worthless piece of orange glass': '橙色のガラス',
    'worthless piece of red glass': '赤いガラス',
    'worthless piece of violet glass': '紫のガラス',
    'worthless piece of white glass': '白いガラス',
    'worthless piece of yellow glass': '黄色のガラス',
    'worthless piece of yellowish brown glass': '茶褐色のガラス',
    // Y
    'ya': '竹矢',
    'yumi': '和弓',
  };

  if (monsterMap.containsKey(s)) {
    return monsterMap[s]!;
  }
  final capS = _capitalizeFirst(s);
  if (monsterMap.containsKey(capS)) {
    return monsterMap[capS]!;
  }

  if (itemAndEnvironmentMap.containsKey(s)) {
    return itemAndEnvironmentMap[s]!;
  }
  if (itemAndEnvironmentMap.containsKey(capS)) {
    return itemAndEnvironmentMap[capS]!;
  }

  // アイテムの複数形（s / es）に対するフォールバック単数化
  if (s.endsWith('s')) {
    final singular = s.substring(0, s.length - 1);
    if (itemAndEnvironmentMap.containsKey(singular)) {
      return itemAndEnvironmentMap[singular]!;
    }
    final capSingular = _capitalizeFirst(singular);
    if (itemAndEnvironmentMap.containsKey(capSingular)) {
      return itemAndEnvironmentMap[capSingular]!;
    }
    if (s.endsWith('es')) {
      final singularEs = s.substring(0, s.length - 2);
      if (itemAndEnvironmentMap.containsKey(singularEs)) {
        return itemAndEnvironmentMap[singularEs]!;
      }
      final capSingularEs = _capitalizeFirst(singularEs);
      if (itemAndEnvironmentMap.containsKey(capSingularEs)) {
        return itemAndEnvironmentMap[capSingularEs]!;
      }
    }
  }

  return s;
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _translateMultiReason(String rawReason) {
  var reason = rawReason.trim();
  if (reason.endsWith('.')) {
    reason = reason.substring(0, reason.length - 1).trim();
  }

  const reasonMap = {
    'dragging an iron ball': '鉄球を引きずっていた',
    'digesting something': '何かを消化していた',
    'gazing into a mirror': '鏡をのぞき込んでいた',
    'jumping around': '跳び回っていた',
    'stuck in a spider web': '蜘蛛の巣に絡まっていた',
    'disrobing': '服を脱いでいた',
    'dressing up': '着替えていた',
    'moving through the air': '空中を移動していた',
    'pretending to be a pile of gold': '金貨の山のふりをしていた',
    'feigning a pile of gold coins': '金貨の山のふりをしていた',
    'unconscious from rotten food': '腐った食べ物で意識を失っていた',
    'fainted from lack of food': '食料不足で気絶していた',
    'fainting from hunger': '飢えで気絶していた',
    'vomiting': '吐いていた',
    'opening a container': '容器を開けていた',
    'tipping a container': '容器を傾けていた',
    'looking into a magic 8-ball': 'マジック8ボールを覗き込んでいた',
    'looking into a crystal ball': '水晶玉を覗き込んでいた',
    'toyed with by fate': '運命に翻弄されていた',
    'paralyzed by fear': '恐怖で身動きできなかった',
    'being scared stiff': '恐怖で身動きできなかった',
    'being frightened to death': '恐怖で死にかけていた',
    'sleeping off a magical draught': '魔法の薬で眠っていた',
    'reading a book': '本を読んでいた',
    'taking off clothes': '服を脱いでいた',
    'praying': '祈っていた',
    'trying to turn the monsters': 'モンスターを退散させようとしていた',
    'being terrified of a demon': '悪魔におびえていた',
    'being terrified of a ghost': '幽霊におびえていた',
    'scared by rattling': 'ガタガタいう音に驚いていた',
    'frozen by a potion': 'ポーションで凍りついていた',
    'getting stoned': '石化していた',
    'fumbling': 'もたついていた',
    'sleeping': '眠っていた',
    'hiding from thunderstorm': '雷雨を避けて隠れていた',
    'paralyzed by a monster': 'モンスターに麻痺させられていた',
    'frozen by a monster\'s gaze': 'モンスターの視線で凍りついていた',
    'frozen by a monster': 'モンスターに凍りつかされていた',
    'exhaustion': '疲労困憊していた',
    'elementary physics': '物理法則に翻弄されていた',
    'brainlessness': '脳を失っていた',
    'starvation': '飢えに苦しんでいた',
    'system shock': 'システムショック状態だった',
    'alchemic blast': '錬金術の爆発に巻き込まれていた',
    'helpless': '無力状態',
  };

  final lower = reason.toLowerCase();
  for (final entry in reasonMap.entries) {
    if (lower == entry.key.toLowerCase()) {
      return entry.value;
    }
  }

  if (reason.startsWith('paralyzed by ')) {
    final who = _stripEnglishArticle(reason.substring(13));
    final whoTr = _translateMonsterOrItemName(who);
    return '$whoTrに麻痺させられていた';
  }
  if (reason.startsWith('frozen by ')) {
    var who = _stripEnglishArticle(reason.substring(10));
    if (who.endsWith(' gaze')) {
      var base = who.substring(0, who.length - 5).trim();
      if (base.endsWith("'s")) {
        base = base.substring(0, base.length - 2).trim();
      } else if (base.endsWith("'")) {
        base = base.substring(0, base.length - 1).trim();
      }
      final whoTr = _translateMonsterOrItemName(base);
      return '$whoTrの視線で凍りついていた';
    } else {
      final whoTr = _translateMonsterOrItemName(who);
      return '$whoTrに凍りつかされていた';
    }
  }

  return _translateMonsterOrItemName(reason);
}

String _translateDeathText(String death, bool isJp) {
  if (death.isEmpty) return death;
  if (!isJp) {
    var d = death.trim();
    if (d.contains('幻覚でゆがんだ')) {
      d = d.replaceAll('幻覚でゆがんだ', 'hallucinogen-distorted ');
    }
    if (d.contains('透明な')) {
      d = d.replaceAll('透明な', 'invisible ');
    }
    if (d.startsWith('escaped')) {
      return 'Escaped${d.substring(7)}';
    }
    if (d.startsWith('ascended')) {
      return 'Ascended${d.substring(8)}';
    }
    return _capitalizeFirst(d);
  }

  String mainDeath = death.trim();
  String locSuffix = '';

  String itemSuffix = '';
  if (mainDeath.contains(' (with the Amulet)')) {
    itemSuffix = ' (魔除けを持ったまま)';
    mainDeath = mainDeath.replaceAll(' (with the Amulet)', '');
  } else if (mainDeath.contains(' (in celestial disgrace)')) {
    itemSuffix = ' (神の不興を買って)';
    mainDeath = mainDeath.replaceAll(' (in celestial disgrace)', '');
  } else if (mainDeath.contains(' (with a fake Amulet)')) {
    itemSuffix = ' (偽物の魔除けを持ったまま)';
    mainDeath = mainDeath.replaceAll(' (with a fake Amulet)', '');
  }

  String whileSuffix = '';
  final whileIdx = mainDeath.indexOf(', while ');
  if (whileIdx != -1) {
    final rawWhile = mainDeath.substring(whileIdx + 8).trim();
    mainDeath = mainDeath.substring(0, whileIdx).trim();
    whileSuffix = '（${_translateMultiReason(rawWhile)}）';
  }

  int cutIdx = -1;
  final parenIdx = mainDeath.lastIndexOf(' (');
  final jpParenIdx = mainDeath.lastIndexOf('（');
  if (parenIdx != -1) cutIdx = parenIdx;
  if (jpParenIdx != -1 && (cutIdx == -1 || jpParenIdx > cutIdx)) cutIdx = jpParenIdx;

  if (cutIdx != -1) {
    locSuffix = mainDeath.substring(cutIdx).trim();
    mainDeath = mainDeath.substring(0, cutIdx).trim();
  }

  bool hadDot = mainDeath.endsWith('.');
  if (hadDot) {
    mainDeath = mainDeath.substring(0, mainDeath.length - 1).trim();
  }

  final translatedMain = '${_translateDeathTextInternal(mainDeath, isJp)}$whileSuffix$itemSuffix';

  var result = translatedMain;
  if (locSuffix.isNotEmpty) {
    if (locSuffix.startsWith('（')) {
      result = '$translatedMain$locSuffix';
    } else {
      result = '$translatedMain $locSuffix';
    }
  }

  if (hadDot && !result.endsWith('.')) {
    final lastChar = result.codeUnitAt(result.length - 1);
    if ((lastChar >= 0x61 && lastChar <= 0x7A) ||
        (lastChar >= 0x41 && lastChar <= 0x5A) ||
        (lastChar >= 0x30 && lastChar <= 0x39)) {
      result += '.';
    }
  }

  return result;
}

String _translateDeathTextInternal(String death, bool isJp) {
  const exactMap = {
    'quit': '中断した',
    'starved': '餓死した',
    'starvation': '餓死',
    'trickery': '不正行為',
    'panic': 'パニック',
    'choked': '窒息した',
    'poisoned': '毒に侵された',
    'drowning': '溺死した',
    'burning': '焼死した',
    'dissolving under the heat and pressure': '熱と圧力で溶解した',
    'crushed': '押しつぶされた',
    'turned to stone': '石になった',
    'turned into slime': 'スライムになった',
    'genocided': '虐殺された',
    'self-genocide': '自己虐殺',
    'unsuccessful polymorph': 'へんげの失敗',
    'genocidal confusion': '虐殺による混乱',
    'committed suicide': '自殺',
    'went to heaven prematurely': '早すぎる天国への旅',
    'elementary physics': '基礎物理学',
    'colliding with the ceiling': '天井への激突',
    'system shock': 'システムショック',
    'alchemic blast': '錬金術の爆発',
    'exhaustion': '過労死',
    'overexertion': '力尽きたこと',
    'life drainage': '生命力吸収',
    'a bad experience sitting on a throne': '玉座に座った悪影響',
    'bad experience sitting on a throne': '玉座に座った悪影響',
    'sitting on lava': '溶岩に座ったこと',
    'mildly contaminated potion': '少し古くなった薬',
    'contusion from a small passage': '狭い通路で頭を打ったこと',
    'brainlessness': '脳を失ったこと',
    'psychic blast': '精神波の爆発',
    'gas cloud': '毒ガスの雲',
    'falling rock': '落石',
    'falling object': '落下物',
    'a grappling hook': 'グラップリングフック',
    'jumping out of a bear trap': '熊罠からの脱出失敗',
    'sitting in lava': '溶岩に座ったこと',
    'cursed throne': '呪われた玉座',
    'cadaver': '腐った死体',
    'rotted glob': '腐った塊',
    'rotten lump of royal jelly': '腐ったローヤルゼリーの塊',
    'very rich meal': '豪華すぎる食事',
    'quick snack': '手軽なおやつ',
    'axing a hard object': '硬いものを斧で叩いたこと',
    'crunched in the head by an iron ball': '鉄球に頭を打ち砕かれた',
    'iron ball collision': '鉄球との衝突で倒された',
    'exploding ring': '指輪の爆発',
    'exploding wand': '杖の爆発',
    'exploding rune': 'ルーンの爆発',
    'residual undead turning effect': 'アンデッド退散の残留効果',
    'imperious order': '傲慢な命令',
    'removing gloves': '手袋を脱いだこと',
    'losing gloves': '手袋を失ったこと',
    'removing boots': '靴を脱いだこと',
    'losing boots': '靴を失ったこと',
    'resistance timing out': '石化耐性が切れたこと',
    'killed while stuck in creature form': 'へんげした姿のまま死亡したこと',
    'scroll of genocide': '虐殺の巻物',
    'deliberately meeting Medusa\'s gaze': '意図的にメドゥーサの視線と目を合わせたこと',
    'boiling potion': '沸騰して爆発した薬',
    'boiling potions': '沸騰して爆発した薬',
    'exploding potion': '引火して爆発した薬',
    'exploding potions': '引火して爆発した薬',
    'shattered potion': '凍結して砕け散った薬',
    'shattered potions': '凍結して砕け散った薬',
    'burning scroll': '燃え上がった巻物',
    'burning scrolls': '燃え上がった巻物',
    'burning book': '燃え上がった魔法書',
    'exploding glob of slime': '爆発したスライムの塊',
    'exploding globs of slime': '爆発したスライムの塊',
    'turned into green slime': '緑のスライムになったこと',
    'killed by petrification': '石化による死',
    'quit while already on Charon\'s boat': 'カロンの舟の上で人生を諦めた',
    'crushed to death underneath a drawbridge': '跳ね橋の下敷きになった',
    'fell from a drawbridge': '跳ね橋から落ちた',
    'strangulation': '首を絞められたこと',
    'suffocation': '窒息',
    'slimicide': 'スライム化による死',
    'acidic chair': '酸の椅子',
    'electric chair': '電気椅子',
    'acidic corpse': '酸性の死体',
    'acidic glob': '酸性の塊',
    'falling down a mine shaft': '坑道への落下',
    'exploding crystal ball': '水晶玉の爆発',
    'dangerous winds': '危険な突風',
    'rusting away': '錆び崩れたこと',
    'arrow': '矢に倒された',
    'little dart': '吹き矢に倒された',
    'dart': '吹き矢に倒された',
    'poisoned needle': '毒針に刺されて倒された',
    'needle': '毒針に刺されて倒された',
    'land mine': '地雷の爆発',
    'electric shock': '電撃',
    'bear trap': '熊罠',
    'rolling boulder trap': '転がる大岩の罠',
    'statue trap': '石像の罠',
    'spiked pit': '杭のある落とし穴',
    'pit': '落とし穴',
    'fire trap': '火の罠',
    'magic trap': '魔法の罠',
    'anti-magic trap': '反魔法の罠',
    'polymorph trap': 'へんげの罠',
    'cloud of poison gas': '毒ガスの雲',
    'magical explosion': '魔法の爆発',
    'splash of acid': '酸の飛沫',
    'death field': '死の領域',
    'disintegration field': '分解領域',
    'unrefrigerated sip of juice': '冷やされていない果汁をすすったこと',
    'sipping boiling water': '煮えたぎる湯をすすったこと',
    'carnivorous bag': '肉食の袋に倒された',
    'died': '死亡した',
    'ascended': '昇天した',
  };

  if (exactMap.containsKey(death)) {
    return exactMap[death]!;
  }

  if (death.startsWith('teleported out of the dungeon and fell to ')) {
    return 'ダンジョン外へテレポートして落下死した';
  }

  if (death.startsWith('reverting to unhealthy ') && death.endsWith(' form')) {
    final raw = death.substring(23, death.length - 5);
    const raceMap = {
      'human': '人間',
      'elf': 'エルフ',
      'dwarf': 'ドワーフ',
      'gnome': 'ノーム',
      'orc': 'オーク',
    };
    final tr = raceMap[raw.toLowerCase()] ?? _translateMonsterOrItemName(raw);
    return '不健康な$trの姿に戻って倒れた';
  }

  if (death == 'escaped' || death.startsWith('escaped ')) {
    return '脱出した';
  }
  if (death.startsWith('ascended')) return '昇天した';

  if (death.startsWith('killed by a ')) {
    final raw = death.substring(12);
    if (raw == 'scroll of genocide') return '虐殺の巻物に倒された';
    if (raw == 'bad experience sitting on a throne') return '玉座に座った悪影響で倒された';
    if (raw == 'mildly contaminated potion') return '少し古くなった薬で倒された';
    if (raw == 'contusion from a small passage') return '狭い通路で頭を打ったことで倒された';
    final tr = _translateMonsterOrItemName(raw);
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('killed by an ')) {
    final raw = death.substring(13);
    final tr = _translateMonsterOrItemName(raw);
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('killed by ')) {
    final raw = death.substring(10);
    if (raw == 'overexertion') return '精根尽き果てて倒された';
    if (raw == 'life drainage') return '生命力吸収で倒された';
    if (raw == 'a bad experience sitting on a throne' || raw == 'bad experience sitting on a throne') {
      return '玉座に座った悪影響で倒された';
    }
    if (raw == 'sitting on lava' || raw == 'sitting in lava') {
      return '溶岩に座ったことで倒された';
    }
    if (raw == 'mildly contaminated potion' || raw == 'a mildly contaminated potion') {
      return '少し古くなった薬で倒された';
    }
    if (raw == 'contusion from a small passage' || raw == 'a contusion from a small passage') {
      return '狭い通路で頭を打ったことで倒された';
    }
    if (raw == 'falling drawbridge') return '落下した跳ね橋に倒された';
    if (raw == 'closing drawbridge') return '閉じる跳ね橋に倒された';
    if (raw == 'exploding drawbridge') return '爆発する跳ね橋に倒された';
    if (raw == 'collapsing drawbridge') return '崩れ落ちる跳ね橋に倒された';
    if (raw == 'boiling potion' || raw == 'boiling potions') return '沸騰して爆発した薬で倒された';
    if (raw == 'exploding potion' || raw == 'exploding potions') return '引火して爆発した薬で倒された';
    if (raw == 'shattered potion' || raw == 'shattered potions') return '凍結して砕け散った薬で倒された';
    if (raw == 'burning scroll' || raw == 'burning scrolls') return '燃え上がった巻物で倒された';
    if (raw == 'burning book') return '燃え上がった魔法書で倒された';
    if (raw == 'exploding glob of slime' || raw == 'exploding globs of slime') return '爆発したスライムの塊で倒された';
    if (raw == 'strangulation') return '首を絞められて倒された';
    if (raw == 'suffocation') return '窒息して倒された';
    if (raw == 'slimicide') return 'スライム化による死';
    if (raw == 'potion of poison') return '毒薬に倒された';
    if (raw == 'potion of polymorph') return 'へんげの薬に倒された';
    final tr = _translateMonsterOrItemName(raw);
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('petrified by ')) {
    final raw = death.substring(13);
    if (raw == "deliberately meeting Medusa's gaze") {
      return '意図的にメドゥーサの視線と目を合わせたことで石化した';
    }
    final tr = _translateMonsterOrItemName(raw);
    return tr.endsWith('石化した') ? tr : '$trによる石化';
  }
  if (death.startsWith('turned to slime by ')) {
    final tr = _translateMonsterOrItemName(death.substring(19));
    return '$trによるスライム化';
  }
  if (death.startsWith('choked on ')) {
    final tr = _translateMonsterOrItemName(death.substring(10));
    return '$trで窒息した';
  }
  if (death.startsWith('poisoned by ')) {
    final tr = _translateMonsterOrItemName(death.substring(12));
    return '$trで毒に侵された';
  }
  if (death.startsWith('died of ')) {
    final tr = _translateMonsterOrItemName(death.substring(8));
    return '$trで死亡した';
  }
  if (death.startsWith('drowned in ')) {
    final tr = _translateMonsterOrItemName(death.substring(11));
    return '$trで溺死した';
  }
  if (death.startsWith('unwisely drank from ')) {
    final tr = _translateMonsterOrItemName(death.substring(20));
    return '$trから飲んだ不心得';
  }
  if (death.startsWith('unwisely ate the body of ')) {
    final tr = _translateMonsterOrItemName(death.substring(25));
    return '軽率にも$trの肉を食べたこと';
  }
  if (death.startsWith('unwisely ate the brain of ')) {
    final tr = _translateMonsterOrItemName(death.substring(26));
    return '$trの脳を食べたこと';
  }
  if (death.startsWith('unwisely ate ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return '無謀にも$trを食べようとした';
  }
  if (death.startsWith('kicking ') && death.endsWith(' barefoot')) {
    final item = death.substring(8, death.length - 9);
    final tr = _translateMonsterOrItemName(item);
    return '裸足で$trを蹴ったことで石化した';
  }
  if (death.startsWith('throwing ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    final tr = _translateMonsterOrItemName(item);
    return '素手で$trを投げたことで石化した';
  }
  if (death.startsWith('wielding ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    final tr = _translateMonsterOrItemName(item);
    return '素手で$trを装備したことで石化した';
  }
  if (death.startsWith('caught in own ')) {
    final tr = _translateMonsterOrItemName(death.substring(14));
    return '自分の$trの爆発に巻き込まれた';
  }
  if (death.startsWith('caught in a ')) {
    final tr = _translateMonsterOrItemName(death.substring(12));
    return '$trの爆発に巻き込まれた';
  }
  if (death.startsWith('caught in an ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return '$trの爆発に巻き込まれた';
  }
  if (death.startsWith('caught in ')) {
    final tr = _translateMonsterOrItemName(death.substring(10));
    return '$trの爆発に巻き込まれた';
  }

  if (death == 'committed suicide') {
    return '自殺したこと';
  }
  if (death == 'brainlessness') {
    return '脳の損失で倒された';
  }
  if (death.contains('shot ') && death.contains('self with a death ray')) {
    return '死の光線で自分を照射したこと';
  }
  if (death.startsWith('disintegration breath by ')) {
    return '自分の分解のブレスで倒された';
  }
  if (death.startsWith('magic missile by ')) {
    return '自分のマジックミサイルで倒された';
  }
  if (death.endsWith("'s indifference") || death.endsWith(" indifference")) {
    final god = death.replaceAll("'s indifference", '').replaceAll(" indifference", '');
    final tr = _translateMonsterOrItemName(god);
    return '$trの冷淡さで倒された';
  }

  if (death.startsWith('the wrath of ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return '$trの怒り';
  }
  if (death.startsWith('the anger of ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return '$trの怒り';
  }
  if (death.contains("'s anger")) {
    final tr = _translateMonsterOrItemName(death.replaceAll("'s anger", ''));
    return '$trの怒り';
  }
  if (death.contains("'s wrath")) {
    final tr = _translateMonsterOrItemName(death.replaceAll("'s wrath", ''));
    return '$trの怒り';
  }

  return _translateMonsterOrItemName(death);
}

List<TopTenEntry> parseRecordFile(String filePath, {bool isJp = true}) {
  final file = File(filePath);
  if (!file.existsSync()) return [];

  try {
    final lines = file.readAsLinesSync();
    final rawEntries = <_RecordRawEntry>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 15) continue;

      final points = int.tryParse(parts[1]) ?? 0;
      final dnum = int.tryParse(parts[2]) ?? 0;
      final dlev = int.tryParse(parts[3]) ?? 1;
      final maxlvl = int.tryParse(parts[4]) ?? 1;
      final hp = int.tryParse(parts[5]) ?? 0;
      final maxhp = int.tryParse(parts[6]) ?? 0;
      final role = parts[11];
      final race = parts[12];
      final gend = parts[13];
      final align = parts[14];

      final rest = parts.sublist(15).join(' ');
      String name = rest;
      String death = '';
      final commaIdx = rest.indexOf(',');
      if (commaIdx != -1) {
        name = rest.substring(0, commaIdx).trim();
        death = rest.substring(commaIdx + 1).trim();
      }

      rawEntries.add(_RecordRawEntry(
        points: points,
        dnum: dnum,
        dlev: dlev,
        maxlvl: maxlvl,
        hp: hp,
        maxhp: maxhp,
        role: role,
        race: race,
        gend: gend,
        align: align,
        name: name,
        death: death,
      ));
    }

    rawEntries.sort((a, b) => b.points.compareTo(a.points));

    final entries = <TopTenEntry>[];
    for (int i = 0; i < rawEntries.length; i++) {
      final e = rawEntries[i];
      final rank = i + 1;
      final roleStr = _translateRoleCode(e.role, isJp);
      final raceStr = _translateRaceCode(e.race, isJp);
      final gendStr = _translateGendCode(e.gend, isJp);
      final alignStr = _translateAlignCode(e.align, isJp);

      final profile = '$roleStr/$raceStr/$gendStr/$alignStr';
      final nameAndProfile = '${e.name} $profile';

      final deathStr = _translateDeathText(e.death, isJp);
      String locationStr;
      if (e.dnum == 7 || e.dlev < 0) {
        locationStr = _translateEndgameLevel(e.dlev, isJp);
      } else {
        final dungeonName = _translateDungeonName(e.dnum, isJp);
        locationStr = isJp ? '$dungeonName ${e.dlev}階' : '$dungeonName level ${e.dlev}';
      }

      final details = <String>[];
      if (deathStr.isNotEmpty) {
        details.add('$deathStr ($locationStr)');
      } else {
        details.add(locationStr);
      }

      final hpValStr = e.hp <= 0 ? '-' : '${e.hp}';
      final hpInfo = isJp ? 'HP/最大HP: $hpValStr/${e.maxhp}' : 'HP/Max HP: $hpValStr/${e.maxhp}';
      details.add(hpInfo);

      entries.add(TopTenEntry(
        rank: rank,
        score: '${e.points}',
        nameAndProfile: nameAndProfile,
        details: details,
        isCurrent: false,
      ));
    }

    return entries;
  } catch (e) {
    return [];
  }
}
