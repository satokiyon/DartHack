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
  if (s.startsWith('hallucinatory ')) {
    return '幻覚の${_translateMonsterOrItemName(s.substring(14))}';
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
    // A - Ant, Bee, Blob
    'giant ant': '巨大アリ',
    'killer bee': '殺人バチ',
    'soldier ant': '兵隊アリ',
    'fire ant': '火アリ',
    'giant beetle': '巨大カブトムシ',
    'queen bee': '女王バチ',
    'acid blob': '酸のブロッブ',
    'quivering blob': '震えるブロッブ',
    'gelatinous cube': 'ゼラチンキューブ',
    // B - Bat, Bird
    'bat': 'コウモリ',
    'giant bat': '巨大コウモリ',
    'vampire bat': '吸血コウモリ',
    'raven': 'オオガラス',
    // C - Centaur, Cat, Chameleon, Cockatrice
    'chickatrice': 'チカトリス',
    'cockatrice': 'コカトリス',
    'pyrolisk': 'パイロリスク',
    'plains centaur': '草原のケンタウロス',
    'forest centaur': '森のケンタウロス',
    'mountain centaur': '山のケンタウロス',
    'kitten': '子猫',
    'housecat': '猫',
    'large cat': '大型猫',
    'jaguar': 'ジャガー',
    'lynx': 'ヤマネコ',
    'panther': 'パンサー',
    'tiger': 'トラ',
    // D - Dragon, Dog, Doppelganger
    'doppelganger': 'ドッペルゲンガー',
    'baby red dragon': '赤ん坊レッドドラゴン',
    'baby white dragon': '赤ん坊ホワイトドラゴン',
    'baby blue dragon': '赤ん坊ブルードラゴン',
    'baby green dragon': '赤ん坊グリーンドラゴン',
    'baby black dragon': '赤ん坊ブラックドラゴン',
    'baby yellow dragon': '赤ん坊イエロードラゴン',
    'baby orange dragon': '赤ん坊オレンジドラゴン',
    'baby gray dragon': '赤ん坊グレードラゴン',
    'baby silver dragon': '赤ん坊シルバードラゴン',
    'red dragon': 'レッドドラゴン',
    'white dragon': 'ホワイトドラゴン',
    'blue dragon': 'ブルードラゴン',
    'green dragon': 'グリーンドラゴン',
    'black dragon': 'ブラックドラゴン',
    'yellow dragon': 'イエロードラゴン',
    'orange dragon': 'オレンジドラゴン',
    'gray dragon': 'グレードラゴン',
    'silver dragon': 'シルバードラゴン',
    'baby dragon': '赤ん坊ドラゴン',
    'dragon': 'ドラゴン',
    'jackal': 'ジャッカル',
    'fox': 'キツネ',
    'coyote': 'コヨーテ',
    'werejackal': '狼人間（ジャッカル）',
    'little dog': '子犬',
    'dog': '犬',
    'large dog': '大型犬',
    'wolf': '狼',
    'winter wolf': '冬狼',
    'winter wolf cub': '冬狼の子',
    'dingo': 'ディンゴ',
    'wererat': 'ねずみ人間',
    'werewolf': '狼人間',
    'warg': 'ワーグ',
    'hell hound pup': 'ヘルハウンドの子',
    'hell hound': 'ヘルハウンド',
    // E - Elementals, Eye
    'floating eye': '浮遊する目',
    'freezing sphere': '氷の球体',
    'flaming sphere': '炎の球体',
    'shocking sphere': '電撃の球体',
    'stalker': 'ストーカー',
    'air elemental': '風のエレメンタル',
    'fire elemental': '火のエレメンタル',
    'earth elemental': '土のエレメンタル',
    'water elemental': '水のエレメンタル',
    // F - Fungus
    'lichen': '地衣類',
    'brown mold': '茶色モールド',
    'yellow mold': '黄色モールド',
    'green mold': '緑色モールド',
    'red mold': '赤色モールド',
    'shrieker': 'シュリーカー',
    'violet fungus': '紫キノコ',
    // G - Gnomish, Goblin, Giant, Golem
    'gnome': 'ノーム',
    'gnome leader': 'ノームの首領',
    'gnomish wizard': 'ノームの魔法使い',
    'gnome ruler': 'ノームの支配者',
    'gnome mummy': 'ノームのミイラ',
    'gnome zombie': 'ノームのゾンビ',
    'goblin': 'ゴブリン',
    'hobgoblin': 'ホブゴブリン',
    'goblin leader': 'ゴブリンの首領',
    'kobold': 'コボルド',
    'large kobold': '大型コボルド',
    'kobold lord': 'コボルドの君主',
    'kobold shaman': 'コボルドの呪術師',
    'giant': '巨人',
    'stone giant': '岩石巨人',
    'hill giant': '丘の巨人',
    'fire giant': '炎の巨人',
    'frost giant': '吹雪の巨人',
    'storm giant': '雷の巨人',
    'titan': 'タイタン',
    'minotaur': 'ミノタウロス',
    'jabberwock': 'ジャバウォック',
    'giant mummy': '巨人のミイラ',
    'giant zombie': '巨人のゾンビ',
    'ettin': 'エティン',
    'ettin mummy': 'エティンのミイラ',
    'ettin zombie': 'エティンのゾンビ',
    'gargoyle': 'ガーゴイル',
    'wingless gargoyle': '羽無しのガーゴイル',
    'winged gargoyle': '羽のあるガーゴイル',
    'straw golem': '藁ゴーレム',
    'rope golem': '縄ゴーレム',
    'leather golem': '革ゴーレム',
    'wood golem': '木ゴーレム',
    'flesh golem': '肉ゴーレム',
    'clay golem': '土ゴーレム',
    'stone golem': '石ゴーレム',
    'glass golem': 'ガラスゴーレム',
    'iron golem': '鉄ゴーレム',
    'golem': 'ゴーレム',
    'grid bug': 'グリッドバグ',
    // H - Human, Horse
    'human': '人間',
    'human wererat': 'ねずみ人間',
    'human werejackal': 'ジャッカル人間',
    'human werewolf': '狼人間',
    'human mummy': '人間のミイラ',
    'human zombie': '人間のゾンビ',
    'pony': 'ポニー',
    'horse': '馬',
    'warhorse': '軍馬',
    // I - Imp, Incubus
    'imp': 'インプ',
    'homunculus': 'ホムンクルス',
    'tengu': '天狗',
    'succubus': 'サキュバス',
    'incubus': 'インキュバス',
    // K - Kop, Knight
    'keystone kop': '警備員',
    'kop sergeant': '巡査部長',
    'kop lieutenant': '警部補',
    'kop kaptain': '警部',
    // L - Lich
    'lich': 'リッチ',
    'demilich': 'デミリッチ',
    'master lich': 'マスターリッチ',
    'arch-lich': 'アーチリッチ',
    // M - Mind Flayer, Mummy, Naga
    'mind flayer': 'マインドフレア',
    'master mind flayer': 'マスター・マインドフレア',
    'red naga hatchling': 'レッドナーガの子供',
    'black naga hatchling': 'ブラックナーガの子供',
    'golden naga hatchling': 'ゴールデンナーガの子供',
    'guardian naga hatchling': 'ガーディアンナーガの子供',
    'red naga': 'レッドナーガ',
    'black naga': 'ブラックナーガ',
    'golden naga': 'ゴールデンナーガ',
    'guardian naga': 'ガーディアンナーガ',
    // O - Orc, Ogre
    'orc': 'オーク',
    'hill orc': '丘オーク',
    'mordor orc': 'モルドールのオーク',
    'uruk-hai': 'ウルク・ハイ',
    'orc captain': 'オークの隊長',
    'orc shaman': 'オークの呪術師',
    'mirkwood orc': '闇の森のオーク',
    'mirkwood spider': '闇の森のクモ',
    'orc mummy': 'オークのミイラ',
    'orc zombie': 'オークのゾンビ',
    'ogre': 'オーガ',
    'ogre leader': 'オーガの首領',
    'ogre tyrant': 'オーガの暴君',
    // P - Piercer, Puddings
    'rock piercer': 'ロックピアサー',
    'iron piercer': 'アイアンピアサー',
    'glass piercer': 'ガラスピアサー',
    'black pudding': 'ブラックプリン',
    'brown pudding': 'ブラウンプリン',
    'gray ooze': 'グレーウーズ',
    'spotted jelly': 'マダラゼリー',
    // Q - Quantum
    'quantum mechanic': '量子力学者',
    // R - Rat, Reptile
    'sewer rat': 'ドブネズミ',
    'giant rat': '巨大ネズミ',
    'rabid rat': '兇暴ネズミ',
    'rock mole': '岩モグラ',
    'woodchuck': 'ウッドチャック',
    'cave spider': '洞窟クモ',
    'giant spider': '巨大クモ',
    'newt': 'イモリ',
    'gecko': 'ヤモリ',
    'iguana': 'イグアナ',
    'chameleon': 'カメレオン',
    'crocodile': 'ワニ',
    // S - Snake, Skeleton, Shopkeeper, Guard
    'garter snake': 'ガータースネーク',
    'snake': 'ヘビ',
    'pit viper': 'マムシ',
    'python': 'ニシキヘビ',
    'cobra': 'コブラ',
    'skeleton': 'スケルトン',
    'shopkeeper': '店主',
    'guard': '番兵',
    'prisoner': '囚人',
    'oracle': '賢者',
    'aligned priest': '神官',
    'high priest': '高位神官',
    'soldier': '兵士',
    'sergeant': '下士官',
    'nurse': '看護婦',
    'lieutenant': '副官',
    'captain': '指揮官',
    'watchman': 'ウォッチマン',
    'watch captain': '警備隊長',
    // T - Troll
    'troll': 'トロル',
    'ice troll': '氷トロル',
    'rock troll': '岩トロル',
    'water troll': '水トロル',
    'olog-hai': 'オログ・ハイ',
    // U - Unicorn
    'white unicorn': '一角獣（白）',
    'gray unicorn': '一角獣（灰）',
    'black unicorn': '一角獣（黒）',
    // V - Vampire
    'vampire': 'ヴァンパイア',
    'vampire lord': 'ヴァンパイアロード',
    'vampire mage': 'ヴァンパイアメイジ',
    // W - Worm, Wasp
    'baby long worm': 'ロングワームの子供',
    'baby purple worm': '紫ワームの子供',
    'long worm': 'ロングワーム',
    'purple worm': '紫ワーム',
    'wasp': 'スズメバチ',
    'giant wasp': '巨大スズメバチ',
    // X - Xan
    'xan': 'ザン',
    // Y - Yellow light
    'yellow light': '黄色の光',
    'black light': '黒色の光',
    // Z - Zombie
    'zombie': 'ゾンビ',
    'zruty': 'ズルティ',

    // Special & Boss Monsters
    'Medusa': 'メデューサ',
    'Wizard of Yendor': 'イェンダーの魔法使い',
    'Croesus': 'クロイソス',
    'Vlad the Impaler': 'ヴラド公',
    'Juiblex': 'ジョウビレックス',
    'Yeenoghu': 'イーノグ',
    'Orcus': 'オーケス',
    'Geryon': 'ゲーリュオーン',
    'Dispater': 'ディスペータ',
    'Baalzebub': 'ベルゼブブ',
    'Asmodeus': 'アスモデウス',
    'Demogorgon': 'デモゴルゴン',
    'Death': 'デス',
    'Pestilence': 'ペスティレンス',
    'Famine': 'フェミン',
    'Mail Daemon': 'メイルデーモン',
    'djinni': 'ジン',

    // Roles & Player Classes
    'wizard': '魔法使い',
    'archeologist': '考古学者',
    'barbarian': '野蛮人',
    'caveman': '洞窟人',
    'cavewoman': '洞窟人',
    'healer': '治療師',
    'knight': '騎士',
    'monk': '修道士',
    'priest': '僧侶',
    'priestess': '僧侶',
    'rogue': '盗賊',
    'ranger': '旅人',
    'samurai': '侍',
    'tourist': '観光客',
    'valkyrie': 'バルキリー',
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
    // Weapons & Missiles
    'arrow': '矢',
    'arrows': '矢',
    'crossbow bolt': 'ボルト',
    'crossbow bolts': 'ボルト',
    'dart': 'ダーツ',
    'darts': 'ダーツ',
    'little dart': '小さなダーツ',
    'poisoned needle': '毒針',
    'poisoned needles': '毒針',
    'needle': '針',
    'needles': '針',
    'spear': '槍',
    'javelin': '投げ槍',
    'dagger': '短剣',
    'knife': 'ナイフ',
    'short sword': 'ショートソード',
    'broadsword': 'ブロードソード',
    'long sword': 'ロングソード',
    'two-handed sword': '両手持ちの剣',
    'scimitar': 'シミター',
    'axe': '斧',
    'battle-axe': 'バトルアックス',
    'mace': 'メイス',
    'morning star': 'モーニングスター',
    'flail': 'フレイル',
    'war hammer': 'ウォーハンマー',
    'trident': 'トライデント',
    'halberd': 'ハルバード',
    'lance': 'ランス',
    'bow': '弓',
    'crossbow': 'クロスボウ',
    'sling': 'スリング',
    'bullwhip': '鞭',
    'boulder': '大岩',
    'rolling boulder': '転がる大岩',

    // Traps & Structures
    'land mine': '地雷',
    'bear trap': 'トラバサミ',
    'spiked pit': '杭の穴',
    'pit': '落とし穴',
    'hole': '穴',
    'rolling boulder trap': '転がる大岩の罠',
    'statue': '石像',
    'statue trap': '石像の罠',
    'fire trap': '火炎の罠',
    'magic trap': '魔法の罠',
    'anti-magic trap': '反魔法の罠',
    'polymorph trap': 'へんげの罠',
    'teleportation trap': 'テレポートの罠',
    'level teleport trap': '階層テレポートの罠',
    'sleeping gas trap': '睡眠ガスの罠',
    'rust trap': '錆の罠',
    'web': 'クモの巣',
    'carnivorous bag': '人食い袋',
    'iron ball': '鉄の球',
    'heavy iron ball': '重い鉄の球',

    // Dungeon Features & Liquids
    'moat': 'お堀',
    'pool of water': '水たまり',
    'pool': '水たまり',
    'deep water': '深い水',
    'limitless water': '無限の水',
    'swamp': '沼',
    'bog': '湿原',
    'river': '川',
    'lake': '湖',
    'sea': '海',
    'ocean': '洋',
    'fountain': '泉',
    'water': '水',
    'lava': '溶岩',
    'molten lava': '溶融した溶岩',
    'mine shaft': '坑道の竪穴',
    'ceiling': '天井',
    'disintegration field': '分解フィールド',
    'death field': '死のフィールド',
    'electric shock': '電撃',
    'splash of acid': '酸の飛沫',
    'acid': '酸',

    // Magical Items & Objects
    'crystal ball': '水晶の玉',
    'exploding crystal ball': '水晶の玉の爆発',
    'wand': '杖',
    'ring': '指輪',
    'scroll': '巻物',
    'potion': '薬',
    'spellbook': '魔法書',
    'amulet': 'アミュレット',
    'Amulet of Yendor': 'イェンダーのアミュレット',
    'Amulet': 'アミュレット',

    // Artifacts & Unique Bosses
    'wizard of Yendor': 'イェンダーの魔法使い',
    'Wizard of Yendor': 'イェンダーの魔法使い',
    'Vlad the Impaler': '串刺し公ヴラド',
    'Medusa': 'メドゥーサ',
    'Croesus': 'クロイソス',
    'alchemic blast': '錬金術の爆発',
    'system shock': 'システムショック',
    'residual undead turning effect': 'アンデッド退散の残留効果',
    'imperious order': '傲慢な命令',
    'resistance timing out': '耐性の時間切れ',
    'falling drawbridge': '落ちてくる跳ね橋',
    'closing drawbridge': '閉まる跳ね橋',
    'exploding drawbridge': '跳ね橋の爆発',
    'collapsing drawbridge': '跳ね橋の崩壊',
    'Excalibur': 'エクスカリバー',
    'Stormbringer': 'ストームブリンガー',
    'Mjollnir': 'ミョルニル',
    'Vorpal Blade': 'ヴォーパルブレード',
    'Orcrist': 'オークリスト',
    'Sting': 'スティング',
    'Sunsword': 'サンソード',
    'Grayswandir': 'グレイスワンディル',
    'Snickersnee': 'スニッカースニー',
    'Magicbane': 'マジックベイン',

    // Gods
    'Moloch': 'モロク',
    'Anubis': 'アヌビス',
    'Offler': 'オフラー',
    'Ptah': 'プタハ',
    'Tyr': 'ティール',
    'Odin': 'オーディン',
    'Loki': 'ロキ',
    'Cthulhu': 'クトゥルフ',
    'Elbereth': 'エルベレス',
    'Ishtar': 'イシュタル',
    'Anhur': 'アンフル',
    'Thoth': 'トト',
    'Set': 'セト',
    'Athena': 'アテナ',
    'Hermes': 'ヘルメス',
    'Poseidon': 'ポセイドン',
    'Quetzalcoatl': 'ケツァルコアトル',
    'Camazotz': 'カマソッソ',
    'Huitzilopochtli': 'ウィツィロポチトリ',
    'Mitra': 'ミトラ',
    'Crom': 'クロム',
    'Lugh': 'ルー',
    'Brigit': 'ブリギッド',
    'Manannan Mac Lir': 'マナナン・マクリル',
    'Shan Lai Ching': '山海経',
    'Chih Sung Tzi': '赤松子',
    'Huan Ti': '黄帝',
    'Amaterasu Omikami': '天照大神',
    'Raijin': '雷神',
    'Blind Io': 'ブラインド・アイオー',
    'The Lady': 'ザ・レディ',
    'Fate': 'フェイト',
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

  return s;
}

String _capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _translateDeathText(String death, bool isJp) {
  if (death.isEmpty) return death;
  if (!isJp) {
    final d = death.trim();
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

  final translatedMain = '${_translateDeathTextInternal(mainDeath, isJp)}$itemSuffix';

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
  };

  if (exactMap.containsKey(death)) {
    return exactMap[death]!;
  }

  if (death == 'escaped' || death.startsWith('escaped ')) {
    return '脱出した';
  }
  if (death.startsWith('ascended')) return '昇天した';

  if (death.startsWith('killed by a ')) {
    final tr = _translateMonsterOrItemName(death.substring(12));
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('killed by an ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('killed by ')) {
    final tr = _translateMonsterOrItemName(death.substring(10));
    return tr.endsWith('倒された') || tr.endsWith('石化した') || tr.endsWith('死んだ') ? tr : '$trに倒された';
  }
  if (death.startsWith('petrified by ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
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
