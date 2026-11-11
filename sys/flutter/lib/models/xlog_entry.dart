import 'dart:convert';

/// xlogfile の 1 行（タブ区切り key=value 形式）を表すデータモデル
class XLogEntry {
  final String version;
  final int points;
  final int deathdnum;
  final int deathlev;
  final int maxlvl;
  final int hp;
  final int maxhp;
  final int deaths;
  final int deathdate;
  final int birthdate;
  final int uid;
  final String role;
  final String race;
  final String gender;
  final String align;
  final String name;
  final String death;
  final String? whileReason;
  final int conductMask;
  final int turns;
  final int achieveMask;
  final List<String> achievements;
  final List<String> conducts;
  final int realtime;
  final int starttime;
  final int endtime;
  final String gender0;
  final String align0;
  final int flags;
  final int gold;
  final int wishCnt;
  final int artiWishCnt;
  final int bones;
  final int rerolls;
  final String rawLine;

  const XLogEntry({
    required this.version,
    required this.points,
    required this.deathdnum,
    required this.deathlev,
    required this.maxlvl,
    required this.hp,
    required this.maxhp,
    required this.deaths,
    required this.deathdate,
    required this.birthdate,
    required this.uid,
    required this.role,
    required this.race,
    required this.gender,
    required this.align,
    required this.name,
    required this.death,
    this.whileReason,
    required this.conductMask,
    required this.turns,
    required this.achieveMask,
    required this.achievements,
    required this.conducts,
    required this.realtime,
    required this.starttime,
    required this.endtime,
    required this.gender0,
    required this.align0,
    required this.flags,
    required this.gold,
    required this.wishCnt,
    required this.artiWishCnt,
    required this.bones,
    required this.rerolls,
    required this.rawLine,
  });

  /// 16進または10進の整数文字列を安全にパースする
  static int _parseInt(String? raw, [int fallback = 0]) {
    if (raw == null || raw.isEmpty) return fallback;
    final trimmed = raw.trim();
    if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
      return int.tryParse(trimmed.substring(2), radix: 16) ?? fallback;
    }
    return int.tryParse(trimmed) ?? fallback;
  }

  /// xlogfile の 1 行をパースする（必須項目が欠落した無効行の場合は null）
  static XLogEntry? parseLine(String rawLine) {
    final trimmedLine = rawLine.trimRight();
    if (trimmedLine.isEmpty) return null;

    final fields = <String, String>{};
    for (final token in trimmedLine.split('\t')) {
      final eqIndex = token.indexOf('=');
      if (eqIndex <= 0) continue;
      final key = token.substring(0, eqIndex);
      final value = token.substring(eqIndex + 1);
      fields[key] = value;
    }

    if (!fields.containsKey('points') ||
        !fields.containsKey('name') ||
        !fields.containsKey('role')) {
      return null;
    }

    final points = _parseInt(fields['points']);
    if (points <= 0) return null;

    final conductMask = _parseInt(fields['conduct']);
    final achieveMask = _parseInt(fields['achieve']);

    final rawAchieveX = fields['achieveX'] ?? '';
    final achievements = rawAchieveX.isNotEmpty
        ? rawAchieveX
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : decodeAchieveBitmask(achieveMask);

    final rawConductX = fields['conductX'] ?? '';
    final conducts = rawConductX.isNotEmpty
        ? rawConductX
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : decodeConductBitmask(conductMask);

    final rawWhile = fields['while'];

    return XLogEntry(
      version: fields['version'] ?? '',
      points: points,
      deathdnum: _parseInt(fields['deathdnum']),
      deathlev: _parseInt(fields['deathlev'], 1),
      maxlvl: _parseInt(fields['maxlvl'], 1),
      hp: _parseInt(fields['hp']),
      maxhp: _parseInt(fields['maxhp']),
      deaths: _parseInt(fields['deaths']),
      deathdate: _parseInt(fields['deathdate']),
      birthdate: _parseInt(fields['birthdate']),
      uid: _parseInt(fields['uid']),
      role: fields['role'] ?? '',
      race: fields['race'] ?? '',
      gender: fields['gender'] ?? '',
      align: fields['align'] ?? '',
      name: fields['name'] ?? '',
      death: fields['death'] ?? '',
      whileReason: (rawWhile != null && rawWhile.isNotEmpty) ? rawWhile : null,
      conductMask: conductMask,
      turns: _parseInt(fields['turns']),
      achieveMask: achieveMask,
      achievements: achievements,
      conducts: conducts,
      realtime: _parseInt(fields['realtime']),
      starttime: _parseInt(fields['starttime']),
      endtime: _parseInt(fields['endtime']),
      gender0: fields['gender0'] ?? '',
      align0: fields['align0'] ?? '',
      flags: _parseInt(fields['flags']),
      gold: _parseInt(fields['gold']),
      wishCnt: _parseInt(fields['wish_cnt']),
      artiWishCnt: _parseInt(fields['arti_wish_cnt']),
      bones: _parseInt(fields['bones']),
      rerolls: _parseInt(fields['rerolls']),
      rawLine: trimmedLine,
    );
  }

  /// record 側の各フィールドと本 xlogfile エントリが一致するか判定する
  bool matchesRecordFields({
    required int points,
    required int deathdnum,
    required int deathlev,
    required int maxlvl,
    required int hp,
    required int maxhp,
    required int deaths,
    required int deathdate,
    required int birthdate,
    required int uid,
    required String role,
    required String race,
    required String gender,
    required String align,
    required String name,
  }) {
    if (this.points != points ||
        this.deathdnum != deathdnum ||
        this.deathlev != deathlev ||
        this.maxlvl != maxlvl ||
        this.hp != hp ||
        this.maxhp != maxhp ||
        this.deaths != deaths ||
        this.deathdate != deathdate ||
        this.birthdate != birthdate ||
        this.uid != uid ||
        this.role != role ||
        this.race != race ||
        this.gender != gender ||
        this.align != align) {
      return false;
    }

    final xlogName = this.name.trim();
    final recName = name.trim();
    if (this.name == name || xlogName == recName) return true;
    if (recName == '_' && xlogName.isEmpty) return true;

    // 旧仕様（NAMSZ=10バイト）の英語コア等でマルチバイト文字が途中切断されると
    // 末尾に U+FFFD が入るため、除去した文字列でも前方一致を判定できるようにする
    final cleanRecName = recName.replaceFirst(RegExp(r'\uFFFD+$'), '');
    final hasReplacementSuffix = cleanRecName.length != recName.length;

    // record 側は NAMSZ_CHARS (10 UTF-8文字) または旧仕様 NAMSZ (10バイト) で
    // 切り詰められるため、切り詰めが発生し得る長さ以上での先頭一致を許容する
    // （"Hero" と "Heroine" 等の短い名前の誤一致防止）
    if (cleanRecName.isNotEmpty &&
        xlogName.length > cleanRecName.length &&
        xlogName.startsWith(cleanRecName)) {
      final runeCount = cleanRecName.runes.length;
      final byteCount = utf8.encode(recName).length;
      final cleanByteCount = utf8.encode(cleanRecName).length;
      final hasMultibyte = cleanByteCount > runeCount;
      if (runeCount >= 10 ||
          byteCount >= 9 ||
          (hasMultibyte && cleanByteCount >= 7) ||
          (hasReplacementSuffix && cleanByteCount >= 7)) {
        return true;
      }
    }

    return false;
  }

  /// achieve ビットマスクからのフォールバック展開
  static List<String> decodeAchieveBitmask(int mask) {
    if (mask == 0) return const [];
    const bitToKey = <int, String>{
      0: 'obtained_the_bell_of_opening',
      1: 'entered_gehennom',
      2: 'obtained_the_candelabrum_of_invocation',
      3: 'obtained_the_book_of_the_dead',
      4: 'performed_the_invocation_ritual',
      5: 'obtained_the_amulet_of_yendor',
      6: 'entered_elemental_planes',
      7: 'entered_astral_plane',
      8: 'ascended',
      9: 'obtained_the_luckstone_from_the_mines',
      10: 'obtained_the_sokoban_prize',
      11: 'defeated_medusa',
      14: 'entered_the_gnomish_mines',
      15: 'entered_mine_town',
      16: 'entered_a_shop',
      17: 'entered_a_temple',
      18: 'consulted_the_oracle',
      19: 'read_a_discworld_novel',
      20: 'entered_sokoban',
      21: 'entered_bigroom',
      30: 'learned_castle_drawbridge_tune',
    };
    final result = <String>[];
    for (final entry in bitToKey.entries) {
      if ((mask & (1 << entry.key)) != 0) {
        result.add(entry.value);
      }
    }
    return result;
  }

  /// conduct ビットマスクからのフォールバック展開
  static List<String> decodeConductBitmask(int mask) {
    if (mask == 0) return const [];
    const bitToKey = <int, String>{
      0: 'foodless',
      1: 'vegan',
      2: 'vegetarian',
      3: 'atheist',
      4: 'weaponless',
      5: 'pacifist',
      6: 'illiterate',
      7: 'polyless',
      8: 'polyselfless',
      9: 'wishless',
      10: 'artiwishless',
      11: 'genocideless',
      12: 'sokoban',
      13: 'petless',
    };
    final result = <String>[];
    for (final entry in bitToKey.entries) {
      if ((mask & (1 << entry.key)) != 0) {
        result.add(entry.value);
      }
    }
    return result;
  }

  /// 達成項目キーを日英表示文言へ変換（日英コア混在ランク名対応）
  static String translateAchievement(String key, bool isJp) {
    const rankPrefix = 'attained_the_rank_of_';
    if (key.startsWith(rankPrefix)) {
      final rawRank = key.substring(rankPrefix.length).replaceAll('_', ' ').trim();
      final formattedRank = _capitalizeWordsIfAscii(rawRank);
      return isJp ? '到達ランク: $formattedRank' : 'Attained rank: $formattedRank';
    }

    const mapJp = <String, String>{
      'ascended': '昇天',
      'entered_astral_plane': 'アストラル界へ到達',
      'entered_elemental_planes': '精霊界へ到達',
      'obtained_the_amulet_of_yendor': 'イェンダーの魔除けを入手',
      'performed_the_invocation_ritual': '召喚の儀式を実行',
      'obtained_the_book_of_the_dead': '死者の書を入手',
      'obtained_the_bell_of_opening': '開門の鐘を入手',
      'obtained_the_candelabrum_of_invocation': '召喚の燭台を入手',
      'entered_gehennom': 'ゲヘナへ到達',
      'defeated_medusa': 'メデューサを撃破',
      'obtained_the_luckstone_from_the_mines': '鉱山の幸運の石を入手',
      'obtained_the_sokoban_prize': '倉庫番の報酬を入手',
      'consulted_the_oracle': '賢者に助言を求めた',
      'read_a_discworld_novel': '小説を読んだ',
      'entered_the_gnomish_mines': 'ノームの鉱山へ到達',
      'entered_mine_town': '鉱山の街へ到達',
      'entered_a_shop': '店に入った',
      'entered_a_temple': '寺院に入った',
      'entered_sokoban': '倉庫番に入った',
      'entered_bigroom': 'ビッグルームに入った',
      'learned_castle_drawbridge_tune': '城の跳ね橋のメロディを習得',
    };

    const mapEn = <String, String>{
      'ascended': 'Ascended',
      'entered_astral_plane': 'Entered Astral Plane',
      'entered_elemental_planes': 'Entered Elemental Planes',
      'obtained_the_amulet_of_yendor': 'Obtained Amulet of Yendor',
      'performed_the_invocation_ritual': 'Performed Invocation Ritual',
      'obtained_the_book_of_the_dead': 'Obtained Book of the Dead',
      'obtained_the_bell_of_opening': 'Obtained Bell of Opening',
      'obtained_the_candelabrum_of_invocation': 'Obtained Candelabrum of Invocation',
      'entered_gehennom': 'Entered Gehennom',
      'defeated_medusa': 'Defeated Medusa',
      'obtained_the_luckstone_from_the_mines': 'Obtained Mines Luckstone',
      'obtained_the_sokoban_prize': 'Obtained Sokoban Prize',
      'consulted_the_oracle': 'Consulted the Oracle',
      'read_a_discworld_novel': 'Read a Discworld Novel',
      'entered_the_gnomish_mines': 'Entered Gnomish Mines',
      'entered_mine_town': 'Entered Minetown',
      'entered_a_shop': 'Entered a Shop',
      'entered_a_temple': 'Entered a Temple',
      'entered_sokoban': 'Entered Sokoban',
      'entered_bigroom': 'Entered Bigroom',
      'learned_castle_drawbridge_tune': 'Learned Castle Drawbridge Tune',
    };

    final table = isJp ? mapJp : mapEn;
    return table[key] ?? _capitalizeWordsIfAscii(key.replaceAll('_', ' '));
  }

  /// 縛りプレイキーを日英表示文言へ変換
  static String translateConduct(String key, bool isJp) {
    const mapJp = <String, String>{
      'foodless': '絶食',
      'vegan': '厳格な菜食 (ビーガン)',
      'vegetarian': '菜食主義',
      'atheist': '無神論',
      'weaponless': '武器不使用',
      'pacifist': '不殺',
      'illiterate': '文盲',
      'polyless': '変化不使用',
      'polyselfless': '変身なし',
      'wishless': '願いなし',
      'artiwishless': 'アーティファクト願いなし',
      'genocideless': '虐殺なし',
      'sokoban': '倉庫番遵守',
      'blind': '盲目',
      'deaf': '聾',
      'nudist': '全裸',
      'pauper': '貧乏',
      'bonesless': '骨ファイルなし',
      'petless': 'ペットなし',
      'unrerolled': 'リロールなし',
    };

    const mapEn = <String, String>{
      'foodless': 'Foodless',
      'vegan': 'Vegan',
      'vegetarian': 'Vegetarian',
      'atheist': 'Atheist',
      'weaponless': 'Weaponless',
      'pacifist': 'Pacifist',
      'illiterate': 'Illiterate',
      'polyless': 'Polypileless',
      'polyselfless': 'Polyselfless',
      'wishless': 'Wishless',
      'artiwishless': 'Artiwishless',
      'genocideless': 'Genocideless',
      'sokoban': 'Sokoban',
      'blind': 'Blind',
      'deaf': 'Deaf',
      'nudist': 'Nudist',
      'pauper': 'Pauper',
      'bonesless': 'Bonesless',
      'petless': 'Petless',
      'unrerolled': 'Unrerolled',
    };

    final table = isJp ? mapJp : mapEn;
    return table[key] ?? _capitalizeWordsIfAscii(key.replaceAll('_', ' '));
  }

  /// 無防備理由 (while=) を日英向けに整形（日本語コア由来の既知文言・英語文言の双方に対応）
  static String translateWhileReason(String reason, bool isJp) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!isJp) return trimmed;

    const mapJp = <String, String>{
      'helpless': '行動不能',
      'sleeping': '眠っていた',
      'paralyzed': '麻痺していた',
      'unconscious': '気絶していた',
      'stunned': '朦朧としていた',
      'fainted from lack of food': '空腹で気絶していた',
      'putting on armor': '防具を着けていた',
      'taking off armor': '防具を外していた',
      'reading': '読んでいた',
      'praying': '祈っていた',
      'digging': '掘っていた',
      'eating': '食べていた',
    };
    return mapJp[trimmed.toLowerCase()] ?? trimmed;
  }

  /// flags ビットマスクを表示用ラベル群にデコードする
  static List<String> decodeFlags(int flagsMask, bool isJp) {
    final labels = <String>[];
    if ((flagsMask & (1 << 0)) != 0) {
      labels.add(isJp ? 'ウィザードモード' : 'Wizard Mode');
    }
    if ((flagsMask & (1 << 1)) != 0) {
      labels.add(isJp ? '探索モード' : 'Discover Mode');
    }
    // bit 2 (0x4) は !u.uroleplay.numbones（今回のプレイで骨ファイルを1度も読み込んでいない）を表す。
    // オプションで骨ファイルを無効にした場合 (!flags.bones) は別途 conductX の 'bonesless' として記録される。
    if ((flagsMask & (1 << 2)) != 0) {
      labels.add(isJp ? '骨ファイル未遭遇' : 'No Bones Loaded');
    }
    if ((flagsMask & (1 << 3)) != 0) {
      labels.add(isJp ? 'キャラ再生成あり' : 'Reroll Used');
    }
    return labels;
  }

  /// UNIX 秒をローカル日時文字列へフォーマットする
  static String formatTimestamp(int unixSeconds, bool isJp) {
    if (unixSeconds <= 0) return isJp ? '不明' : 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  /// yyyymmdd 整数を YYYY/MM/DD 文字列へフォーマットする
  static String formatDateInt(int yyyymmdd, bool isJp) {
    if (yyyymmdd <= 0) return isJp ? '不明' : 'Unknown';
    final s = yyyymmdd.toString().padLeft(8, '0');
    if (s.length != 8) return yyyymmdd.toString();
    return '${s.substring(0, 4)}/${s.substring(4, 6)}/${s.substring(6, 8)}';
  }

  /// 実プレイ秒数を読みやすい経過時間へフォーマットする
  static String formatDuration(int totalSeconds, bool isJp) {
    if (totalSeconds < 0) return isJp ? '不明' : 'Unknown';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (isJp) {
      if (hours > 0) return '$hours時間 $minutes分 $seconds秒';
      if (minutes > 0) return '$minutes分 $seconds秒';
      return '$seconds秒';
    } else {
      if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
      if (minutes > 0) return '${minutes}m ${seconds}s';
      return '${seconds}s';
    }
  }

  static String _capitalizeWordsIfAscii(String text) {
    if (text.isEmpty) return text;
    final words = text.split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return w;
      final first = w.codeUnitAt(0);
      if (first >= 0x61 && first <= 0x7A) {
        return String.fromCharCode(first - 32) + w.substring(1);
      }
      return w;
    }).join(' ');
  }
}
