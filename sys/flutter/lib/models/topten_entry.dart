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
    TopTenEntryBuilder? builder;

    // " 順位      点数  名前" などのヘッダー行は除外して、数字で始まる行からパースする
    final entryRegExp = RegExp(r'^\s*([0-9]+)\s+([0-9]+)\s+(.*)$');
    // 行末の HP 表示を検出する正規表現（" - [103]" や " 15 [120]" 等）
    final hpSuffixRegExp = RegExp(r'\s+(-|[0-9]+)\s+\[([0-9]+)\]\s*$');

    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.trim().isEmpty) continue;

      // ヘッダーやその他のタイトル行は無視
      if (line.contains('順位') && line.contains('点数') && line.contains('名前')) {
        continue;
      }

      // 行末の HP 表示をチェック・抽出
      String? extractedHpInfo;
      final hpMatch = hpSuffixRegExp.firstMatch(line);
      if (hpMatch != null) {
        final hpVal = hpMatch.group(1);
        final maxHpVal = hpMatch.group(2);
        extractedHpInfo = 'HP/最大HP: $hpVal/$maxHpVal';
        line = line.substring(0, hpMatch.start);
      }

      final match = entryRegExp.firstMatch(line);
      if (match != null) {
        if (builder != null) {
          entries.add(builder.build());
        }
        final rank = int.tryParse(match.group(1)!) ?? 0;
        final score = match.group(2)!;
        final nameAndProfile = match.group(3)!.trim();
        
        final attr = i < attrs.length ? attrs[i] : 0;
        final isBold = (attr & 1) != 0; // ATR_BOLD (1)

        builder = TopTenEntryBuilder(
          rank: rank,
          score: score,
          nameAndProfile: nameAndProfile,
          isCurrent: isBold,
        );
        if (extractedHpInfo != null) {
          builder.details.add(extractedHpInfo);
        }
      } else {
        if (builder != null) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            builder.details.add(trimmed);
          }
          if (extractedHpInfo != null) {
            builder.details.add(extractedHpInfo);
          }
          final attr = i < attrs.length ? attrs[i] : 0;
          final isBold = (attr & 1) != 0;
          if (isBold) {
            builder.isCurrent = true;
          }
        }
      }
    }

    if (builder != null) {
      entries.add(builder.build());
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
  ];

  for (final path in candidatePaths) {
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String _translateRoleCode(String code) {
  const map = {
    'Arc': '考古学者', 'Bar': '野蛮人', 'Cav': '洞窟人', 'Hea': '師',
    'Kni': '騎士', 'Mon': '修道士', 'Pri': '僧侶', 'Rog': '盗賊',
    'Ran': '旅人', 'Sam': '侍', 'Tou': '観光客', 'Val': 'バルキリー', 'Wiz': '魔法使い'
  };
  return map[code] ?? code;
}

String _translateRaceCode(String code) {
  const map = {'Hum': '人間', 'Elf': 'エルフ', 'Dwa': 'ドワーフ', 'Gno': 'ノーム', 'Orc': 'オーク'};
  return map[code] ?? code;
}

String _translateGendCode(String code) {
  if (code.startsWith('Mal') || code == 'M') return '男性';
  if (code.startsWith('Fem') || code == 'F') return '女性';
  return code;
}

String _translateAlignCode(String code) {
  if (code.startsWith('Law') || code == 'L') return '秩序';
  if (code.startsWith('Neu') || code == 'N') return '中立';
  if (code.startsWith('Cha') || code == 'C') return '混沌';
  return code;
}

String _translateDeathText(String death) {
  if (death == 'quit') return '自決した';
  if (death == 'starved') return '餓死した';
  if (death.startsWith('escaped')) return '脱出した';
  if (death.startsWith('ascended')) return '昇天した';
  if (death.startsWith('killed by a ')) return '${death.substring(12)}に殺された';
  if (death.startsWith('killed by an ')) return '${death.substring(13)}に殺された';
  if (death.startsWith('killed by ')) return '${death.substring(10)}に殺された';
  return death;
}

List<TopTenEntry> parseRecordFile(String filePath) {
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
      final dnum = int.tryParse(parts[2]) ?? 1;
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
      final roleJp = _translateRoleCode(e.role);
      final raceJp = _translateRaceCode(e.race);
      final gendJp = _translateGendCode(e.gend);
      final alignJp = _translateAlignCode(e.align);

      final profile = '$roleJp/$raceJp/$gendJp/$alignJp';
      final nameAndProfile = '${e.name} $profile';

      final deathJp = _translateDeathText(e.death);
      final details = <String>[];
      if (deathJp.isNotEmpty) {
        details.add('$deathJp (メインダンジョン ${e.dlev}階)');
      } else {
        details.add('メインダンジョン ${e.dlev}階 [HP: ${e.hp}/${e.maxhp}]');
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
