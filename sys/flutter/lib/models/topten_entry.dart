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
        final hyphenRegex = RegExp(r'^([^\s\-]+)\-([^\s\-]+(?:\-[^\s\-]+){2,4})(?:\s+(.*))?$');
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
              translatedParts.add(_translateRoleCode(code, false));
            } else if (pIdx == 1) {
              translatedParts.add(_translateRaceCode(code, false));
            } else if (pIdx == 2) {
              translatedParts.add(_translateGendCode(code, false));
            } else if (pIdx == 3) {
              translatedParts.add(_translateAlignCode(code, false));
            } else {
              translatedParts.add(code);
            }
          }
          nameAndProfile = '$rawName ${translatedParts.join(' / ')}';
        }

        final attr = index < attrs.length ? attrs[index] : 0;
        bool isBold = (attr & 1) != 0; // ATR_BOLD (1)

        String deathDetailPart = '';
        String? hpInfo;

        // 次の行（死因の続き行）があればチェック
        if (index + 1 < lines.length) {
          var nextLine = lines[index + 1];
          final hpMatch = hpSuffixRegExp.firstMatch(nextLine);
          bool consumedNextLine = false;

          if (hpMatch != null) {
            final hpVal = hpMatch.group(1);
            final maxHpVal = hpMatch.group(2);
            hpInfo = 'HP/最大HP: $hpVal/$maxHpVal';
            nextLine = nextLine.substring(0, hpMatch.start);
            consumedNextLine = true;
          }

          final nextTrimmed = nextLine.trim();
          final nextTrimmedLower = nextTrimmed.toLowerCase();
          final isHeaderLine = nextTrimmed.contains('順位') ||
              (nextTrimmedLower.contains('no') && nextTrimmedLower.contains('points'));

          if (nextTrimmed.isNotEmpty && !entryRegExp.hasMatch(nextLine) && !isHeaderLine) {
            deathDetailPart = nextTrimmed;
            consumedNextLine = true;
          }

          if (consumedNextLine) {
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
          final translatedDeath = _translateDeathText(fullDeathText, true);
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

String _translateMonsterOrItemName(String raw) {
  var s = _stripEnglishArticle(raw.trim());
  if (s.isEmpty) return s;

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

  if (s.endsWith(' corpse')) {
    return '${_translateMonsterOrItemName(s.substring(0, s.length - 7))}の死体';
  }
  if (s.endsWith(' egg')) {
    return '${_translateMonsterOrItemName(s.substring(0, s.length - 4))}の卵';
  }
  if (s.startsWith('statue of ')) {
    return '${_translateMonsterOrItemName(s.substring(10))}の石像';
  }
  if (s.startsWith('body of ')) {
    return '${_translateMonsterOrItemName(s.substring(8))}の体';
  }

  const monsterMap = {
    'goblin': 'ゴブリン',
    'hobgoblin': 'ホブゴブリン',
    'goblin leader': 'ゴブリンの首領',
    'kobold': 'コボルド',
    'large kobold': '大型コボルド',
    'kobold lord': 'コボルドの君主',
    'kobold shaman': 'コボルドの呪術師',
    'orc': 'オーク',
    'hill orc': '丘オーク',
    'orc captain': 'オークの隊長',
    'orc shaman': 'オークの呪術師',
    'mirkwood orc': '闇の森のオーク',
    'mirkwood spider': '闇の森のクモ',
    'watchman': 'ウォッチマン',
    'watch captain': '警備隊長',
    'shopkeeper': '店主',
    'jackal': 'ジャッカル',
    'fox': 'キツネ',
    'coyote': 'コヨーテ',
    'werejackal': '狼人間（ジャッカル）',
    'little dog': '子犬',
    'dog': '犬',
    'large dog': '大型犬',
    'kitten': '子猫',
    'housecat': '猫',
    'large cat': '大型猫',
    'cave spider': '洞窟クモ',
    'giant spider': '巨大クモ',
    'grid bug': 'グリッドバグ',
    'giant ant': '巨大アリ',
    'soldier ant': '兵隊アリ',
    'fire ant': '火アリ',
    'floating eye': '浮遊する目',
    'lichen': '地衣類',
    'newt': 'イモリ',
    'gecko': 'ヤモリ',
    'iguana': 'イグアナ',
    'chameleon': 'カメレオン',
    'crocodile': 'ワニ',
    'baby dragon': '赤ん坊ドラゴン',
    'dragon': 'ドラゴン',
    'red dragon': 'レッドドラゴン',
    'blue dragon': 'ブルードラゴン',
    'white dragon': 'ホワイトドラゴン',
    'black dragon': 'ブラックドラゴン',
    'green dragon': 'グリーンドラゴン',
    'yellow dragon': 'イエロードラゴン',
    'orange dragon': 'オレンジドラゴン',
    'gray dragon': 'グレードラゴン',
    'silver dragon': 'シルバードラゴン',
    'cockatrice': 'コッカトリス',
    'chickatrice': 'ヒヨッカトリス',
    'pyrolisk': 'パイロリスク',
    'gargoyle': 'ガーゴイル',
    'wingless gargoyle': '羽無しのガーゴイル',
    'golem': 'ゴーレム',
    'straw golem': '藁ゴーレム',
    'rope golem': '縄ゴーレム',
    'leather golem': '革ゴーレム',
    'wood golem': '木ゴーレム',
    'flesh golem': '肉ゴーレム',
    'clay golem': '土ゴーレム',
    'stone golem': '石ゴーレム',
    'glass golem': 'ガラスゴーレム',
    'iron golem': '鉄ゴーレム',
    'wizard': '魔法使い',
    'archeologist': '考古学者',
    'barbarian': '野蛮人',
    'caveman': '洞窟人',
    'cavewoman': '洞窟人',
    'healer': '師',
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

  String mainDeath = death.trim();
  String locSuffix = '';

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

  final translatedMain = _translateDeathTextInternal(mainDeath, isJp);

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
  if (death.startsWith('unwisely ate ')) {
    final tr = _translateMonsterOrItemName(death.substring(13));
    return '無謀にも$trを食べようとした';
  }
  if (death.startsWith('kicking ') && death.endsWith(' barefoot')) {
    final item = death.substring(8, death.length - 9);
    final tr = _translateMonsterOrItemName(item);
    return '裸足で$trを蹴ったこと';
  }
  if (death.startsWith('throwing ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    final tr = _translateMonsterOrItemName(item);
    return '素手で$trを投げたこと';
  }
  if (death.startsWith('wielding ') && death.endsWith(' bare-handed')) {
    final item = death.substring(9, death.length - 12);
    final tr = _translateMonsterOrItemName(item);
    return '素手で$trを装備したこと';
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
