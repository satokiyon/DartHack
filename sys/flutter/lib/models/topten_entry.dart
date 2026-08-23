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

  static List<TopTenEntry> parse(List<String> lines, List<int> attrs) {
    final entries = <TopTenEntry>[];

    // 順位は空スペースの場合もあるため ([0-9]*) とし、スコア ([0-9]+) にマッチさせる
    final entryRegExp = RegExp(r'^\s*([0-9]*)\s+([0-9]+)\s+(.*)$');
    // 名前とプロフィールの境界を特定する正規表現 ("名前 職業/種族/性別/神")
    final profileRegex = RegExp(r'^(.*?\s+[^\s\/]+\/[^\s\/]+\/[^\s\/]+\/[^\s]+)(.*)$');
    // 行末の HP 表示を検出する正規表現（" - [103]" や " 15 [120]" 等）
    final hpSuffixRegExp = RegExp(r'\s+(-|[0-9]+)\s+\[([0-9]+)\]\s*$');

    int index = 0;
    while (index < lines.length) {
      final rawLine = lines[index];
      final trimmed = rawLine.trim();

      if (trimmed.isEmpty || (trimmed.contains('順位') && trimmed.contains('点数') && trimmed.contains('名前'))) {
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

        final profileMatch = profileRegex.firstMatch(rest);
        if (profileMatch != null) {
          nameAndProfile = profileMatch.group(1)!.trim();
          inlineDeathPart = profileMatch.group(2)!.trim();
        }

        final attr = index < attrs.length ? attrs[index] : 0;
        bool isBold = (attr & 1) != 0; // ATR_BOLD (1)

        String deathDetailPart = '';
        String? hpInfo;

        // 次の行（死因の続き行）があればチェック
        if (index + 1 < lines.length) {
          var nextLine = lines[index + 1];
          final hpMatch = hpSuffixRegExp.firstMatch(nextLine);
          if (hpMatch != null) {
            final hpVal = hpMatch.group(1);
            final maxHpVal = hpMatch.group(2);
            hpInfo = 'HP/最大HP: $hpVal/$maxHpVal';
            nextLine = nextLine.substring(0, hpMatch.start);
          }
          final nextTrimmed = nextLine.trim();
          if (nextTrimmed.isNotEmpty && !entryRegExp.hasMatch(nextLine) && !nextTrimmed.contains('順位')) {
            deathDetailPart = nextTrimmed;
            index++; // 2行目を消費
          }
        }

        // 食い込んだ死因テキストと2行目の続きを結合
        String fullDeathText = '';
        if (inlineDeathPart.isNotEmpty && deathDetailPart.isNotEmpty) {
          final lastCode = inlineDeathPart.codeUnitAt(inlineDeathPart.length - 1);
          final firstCode = deathDetailPart.codeUnitAt(0);
          bool isAsciiBoth = (lastCode >= 0x20 && lastCode <= 0x7E) && (firstCode >= 0x20 && firstCode <= 0x7E);
          fullDeathText = isAsciiBoth ? '$inlineDeathPart $deathDetailPart' : '$inlineDeathPart$deathDetailPart';
        } else if (inlineDeathPart.isNotEmpty) {
          fullDeathText = inlineDeathPart;
        } else if (deathDetailPart.isNotEmpty) {
          fullDeathText = deathDetailPart;
        }

        final details = <String>[];
        if (fullDeathText.isNotEmpty) {
          details.add(fullDeathText);
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

String _translateDeathText(String death, bool isJp) {
  if (death.isEmpty) return death;
  if (!isJp) {
    if (death == 'quit') return 'Quit';
    if (death == 'starved') return 'Starved';
    if (death.startsWith('escaped')) return 'Escaped';
    if (death.startsWith('ascended')) return 'Ascended';
    return death;
  }

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
    'self-genocide': '自分自身の虐殺',
    'unsuccessful polymorph': 'へんげの失敗',
    'genocidal confusion': '虐殺による混乱',
    'committed suicide': '自殺',
    'went to heaven prematurely': '早すぎる天国への旅',
    'elementary physics': '物理法則',
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
    'rotten lump of royal jelly': '腐ったローヤルゼリー',
    'very rich meal': '豪華すぎる食事',
    'quick snack': '軽いスナック',
    'axing a hard object': '硬いものを斧で叩いたこと',
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
  };

  if (exactMap.containsKey(death)) {
    return exactMap[death]!;
  }

  if (death.startsWith('escaped')) {
    if (death == 'escaped (with the Amulet)') return 'アミュレットを持ったまま脱出した';
    if (death == 'escaped (in celestial disgrace)') return '天上界の不名誉を背負って脱出した';
    if (death == 'escaped (with a fake Amulet)') return '偽物のアミュレットを持って脱出した';
    return '脱出した';
  }
  if (death.startsWith('ascended')) return '昇天した';

  if (death.startsWith('killed by a ')) return '${_stripEnglishArticle(death.substring(12))}に倒された';
  if (death.startsWith('killed by an ')) return '${_stripEnglishArticle(death.substring(13))}に倒された';
  if (death.startsWith('killed by ')) return '${_stripEnglishArticle(death.substring(10))}に倒された';
  if (death.startsWith('petrified by ')) return '${_stripEnglishArticle(death.substring(13))}による石化';
  if (death.startsWith('turned to slime by ')) return '${_stripEnglishArticle(death.substring(19))}によるスライム化';
  if (death.startsWith('choked on ')) return '${_stripEnglishArticle(death.substring(10))}で窒息した';
  if (death.startsWith('poisoned by ')) return '${_stripEnglishArticle(death.substring(12))}で毒に侵された';
  if (death.startsWith('died of ')) return '${_stripEnglishArticle(death.substring(8))}で死亡した';
  if (death.startsWith('drowned in ')) return '${_stripEnglishArticle(death.substring(11))}で溺死した';
  if (death.startsWith('unwisely drank from ')) return '${_stripEnglishArticle(death.substring(20))}から飲んだ不心得';
  if (death.startsWith('unwisely ate ')) return '無謀にも${_stripEnglishArticle(death.substring(13))}を食べようとした';
  if (death.startsWith('kicking ') && death.endsWith(' barefoot')) {
    final item = death.substring(8, death.length - 9);
    return '裸足で${_stripEnglishArticle(item)}を蹴ったこと';
  }
  if (death.startsWith('throwing ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    return '素手で${_stripEnglishArticle(item)}を投げたこと';
  }
  if (death.startsWith('wielding ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    return '素手で${_stripEnglishArticle(item)}を装備したこと';
  }
  if (death.startsWith('caught in own ')) return '自分の${_stripEnglishArticle(death.substring(14))}の爆発に巻き込まれた';
  if (death.startsWith('caught in a ')) return '${_stripEnglishArticle(death.substring(12))}の爆発に巻き込まれた';
  if (death.startsWith('caught in an ')) return '${_stripEnglishArticle(death.substring(13))}の爆発に巻き込まれた';
  if (death.startsWith('caught in ')) return '${_stripEnglishArticle(death.substring(10))}の爆発に巻き込まれた';

  if (death.startsWith('the wrath of ')) return '${_stripEnglishArticle(death.substring(13))}の怒り';
  if (death.startsWith('the anger of ')) return '${_stripEnglishArticle(death.substring(13))}の怒り';
  if (death.contains("'s anger")) return '${_stripEnglishArticle(death.replaceAll("'s anger", ''))}の怒り';
  if (death.contains("'s wrath")) return '${_stripEnglishArticle(death.replaceAll("'s wrath", ''))}の怒り';

  return death;
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
      if (isJp) {
        if (deathStr.isNotEmpty) {
          details.add('$deathStr ($locationStr)');
        } else {
          details.add('$locationStr [HP: ${e.hp}/${e.maxhp}]');
        }
      } else {
        if (deathStr.isNotEmpty) {
          details.add('$deathStr ($locationStr)');
        } else {
          details.add('$locationStr [HP: ${e.hp}/${e.maxhp}]');
        }
      }

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
