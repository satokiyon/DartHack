import 'dart:convert';
import 'dart:io';

/// dumplog 内のセクション種別
enum DumplogSectionType {
  header,
  map,
  messages,
  inventory,
  attributes,
  gamelog,
  spells,
  skills,
  conduct,
  overview,
  vanquished,
  genocided,
  tombstone,
  summary,
  other,
}

/// 解析済み dumplog の 1 セクション
class DumplogSection {
  final DumplogSectionType type;
  final String title;
  final List<String> lines;
  final bool isMonospaceScrollable;
  final bool defaultExpanded;

  const DumplogSection({
    required this.type,
    required this.title,
    required this.lines,
    this.isMonospaceScrollable = false,
    this.defaultExpanded = false,
  });

  /// セクション内の非空行数（バッジ表示用）
  int get nonEmptyLineCount => lines.where((l) => l.trim().isNotEmpty).length;
}

/// dumplog テキスト全体をセクション単位に構造化したモデル
class DumplogDocument {
  final String rawText;
  final List<DumplogSection> sections;

  const DumplogDocument({
    required this.rawText,
    required this.sections,
  });

  /// ファイルパスから UTF-8（損失許容）で同期読み込みしパースする
  static DumplogDocument loadFromFileSync(
    String path, {
    required bool isJp,
  }) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final text = utf8.decode(bytes, allowMalformed: true);
    return DumplogDocument.parse(text, isJp: isJp);
  }

  /// ファイルパスから UTF-8（損失許容）で読み込みパースする
  static Future<DumplogDocument> loadFromFile(
    String path, {
    required bool isJp,
  }) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    return DumplogDocument.parse(text, isJp: isJp);
  }

  /// セクション種別に応じた日英ラベルを返す
  static String labelForType(DumplogSectionType type, bool isJp) {
    switch (type) {
      case DumplogSectionType.header:
        return isJp ? '基本情報' : 'Overview';
      case DumplogSectionType.map:
        return isJp ? '最終マップ' : 'Final Map';
      case DumplogSectionType.messages:
        return isJp ? '最新メッセージ' : 'Latest Messages';
      case DumplogSectionType.inventory:
        return isJp ? '所持品' : 'Inventory';
      case DumplogSectionType.attributes:
        return isJp ? '状態・能力' : 'Attributes & Status';
      case DumplogSectionType.gamelog:
        return isJp ? '主要イベント' : 'Major Events';
      case DumplogSectionType.spells:
        return isJp ? '呪文' : 'Spells';
      case DumplogSectionType.skills:
        return isJp ? 'スキル' : 'Skills';
      case DumplogSectionType.conduct:
        return isJp ? '自主的な縛り' : 'Voluntary Challenges';
      case DumplogSectionType.overview:
        return isJp ? 'ダンジョン概要' : 'Dungeon Overview';
      case DumplogSectionType.vanquished:
        return isJp ? '倒した怪物' : 'Vanquished Creatures';
      case DumplogSectionType.genocided:
        return isJp ? '虐殺・絶滅種' : 'Genocided / Extinct';
      case DumplogSectionType.tombstone:
        return isJp ? '墓石' : 'Tombstone';
      case DumplogSectionType.summary:
        return isJp ? '結末サマリー' : 'Final Summary';
      case DumplogSectionType.other:
        return isJp ? 'その他' : 'Details';
    }
  }

  static bool _isDefaultExpanded(DumplogSectionType type) {
    return type == DumplogSectionType.header ||
        type == DumplogSectionType.map ||
        type == DumplogSectionType.inventory ||
        type == DumplogSectionType.tombstone ||
        type == DumplogSectionType.summary ||
        type == DumplogSectionType.other;
  }

  static bool _isMonospaceScrollable(DumplogSectionType type) {
    return type == DumplogSectionType.map ||
        type == DumplogSectionType.tombstone;
  }

  static final RegExp _gameBeganEnRegExp = RegExp(
    r'^Game began (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}), ended (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\.?$',
  );
  static final RegExp _profileEnRegExp = RegExp(
    r'^(.+?),\s+(lawful|neutral|chaotic)\s+(male|female)\s+(human|elf|dwarf|gnome|orc|elven|dwarven|gnomish|orcish)\s+(.+)$',
    caseSensitive: false,
  );
  static final RegExp _tombTopRegExp = RegExp(r'^\s*-{8,}\s*$');
  static final RegExp _tombEdgeRegExp = RegExp(r'^\s*/\s*\\');

  /// dumplog テキストを解析してセクション一覧へ変換する
  factory DumplogDocument.parse(String rawText, {required bool isJp}) {
    final normalized = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final allLines = normalized.split('\n');
    if (allLines.every((l) => l.trim().isEmpty)) {
      return DumplogDocument(rawText: rawText, sections: const []);
    }

    // 1. 先頭ヘッダー（バージョン、開始/終了日時、キャラ基本情報）と
    //    直後の位置ベース「最終マップ＋ステータス」領域を分離する
    int cursor = 0;
    while (cursor < allLines.length && allLines[cursor].trim().isEmpty) {
      cursor++;
    }

    final headerLines = <String>[];
    final mapLines = <String>[];

    // 先頭から最新メッセージ見出しまでの範囲を調べ、ヘッダーとマップを安全に切り出す
    final firstNamedIdx = _findFirstNamedSectionIndex(allLines, cursor);
    if (firstNamedIdx > cursor) {
      // バージョン・日時・キャラ行の最大 3 ブロック（空行区切り）をヘッダーとして抽出
      int blockCount = 0;
      int idx = cursor;
      while (idx < firstNamedIdx && blockCount < 3) {
        if (allLines[idx].trim().isEmpty) {
          idx++;
          continue;
        }
        final blockStart = idx;
        while (idx < firstNamedIdx && allLines[idx].trim().isNotEmpty) {
          idx++;
        }
        final block = allLines.sublist(blockStart, idx);
        // マップ行やステータス行が早く出現した場合はヘッダー終了
        if (blockCount >= 1 && _looksLikeMapBlock(block)) {
          idx = blockStart;
          break;
        }
        headerLines.addAll(block);
        blockCount++;
      }
      while (idx < firstNamedIdx && allLines[idx].trim().isEmpty) {
        idx++;
      }
      if (idx < firstNamedIdx) {
        mapLines.addAll(_trimOuterBlankLines(allLines.sublist(idx, firstNamedIdx)));
      }
      cursor = firstNamedIdx;
    } else if (cursor < allLines.length) {
      // 既知見出しが一切見つからない場合は単一フォールバックセクションへ収容
      final body = _trimOuterBlankLines(allLines.sublist(cursor));
      return DumplogDocument(
        rawText: rawText,
        sections: [
          DumplogSection(
            type: DumplogSectionType.other,
            title: labelForType(DumplogSectionType.other, isJp),
            lines: isJp ? body.map(_localizeLineLightweight).toList() : body,
            defaultExpanded: true,
          ),
        ],
      );
    }

    final sections = <DumplogSection>[];

    if (headerLines.isNotEmpty) {
      final displayHeader = isJp
          ? headerLines.map(_localizeLineLightweight).toList()
          : headerLines;
      sections.add(DumplogSection(
        type: DumplogSectionType.header,
        title: labelForType(DumplogSectionType.header, isJp),
        lines: displayHeader,
        defaultExpanded: _isDefaultExpanded(DumplogSectionType.header),
      ));
    }

    if (mapLines.isNotEmpty) {
      sections.add(DumplogSection(
        type: DumplogSectionType.map,
        title: labelForType(DumplogSectionType.map, isJp),
        lines: mapLines,
        isMonospaceScrollable: true,
        defaultExpanded: _isDefaultExpanded(DumplogSectionType.map),
      ));
    }

    // 2. 見出しベースで残りのセクションを分割
    DumplogSectionType? currentType;
    final currentLines = <String>[];

    void flushCurrent() {
      if (currentType == null) return;
      var trimmed = _trimOuterBlankLines(currentLines);
      if (trimmed.isNotEmpty) {
        final type = currentType;
        final isMono = _isMonospaceScrollable(type);
        if (type == DumplogSectionType.tombstone) {
          trimmed = _dedentLines(trimmed);
        }
        final displayLines = (!isMono && isJp)
            ? trimmed.map(_localizeLineLightweight).toList()
            : trimmed;
        sections.add(DumplogSection(
          type: type,
          title: labelForType(type, isJp),
          lines: displayLines,
          isMonospaceScrollable: isMono,
          defaultExpanded: _isDefaultExpanded(type),
        ));
      }
      currentLines.clear();
    }

    bool inTombstone = false;
    for (int i = cursor; i < allLines.length; i++) {
      final line = allLines[i];
      final trimmed = line.trim();

      // 墓石ブロック中: 結末サマリー行が来たら墓石終了
      if (inTombstone) {
        if (_isSummaryStart(trimmed)) {
          flushCurrent();
          inTombstone = false;
          currentType = DumplogSectionType.summary;
          currentLines.add(line);
          continue;
        }
        currentLines.add(line);
        continue;
      }

      final detected = _detectSectionStart(allLines, i, currentType);
      if (detected != null) {
        // 同一セクション（例: attributes 内の Background / Basics / Final Status / Final Attributes）は統合
        if (detected == currentType &&
            detected == DumplogSectionType.attributes) {
          currentLines.add(line);
          continue;
        }
        flushCurrent();
        currentType = detected;
        if (detected == DumplogSectionType.tombstone) {
          inTombstone = true;
        }
        // 見出し単独行（例: "最新メッセージ:" / "Inventory:"）はカードタイトルと重複するため、
        // 本文を持つ行や小見出し以外は適宜スキップせず、単独見出しのみ省く
        if (!_isRedundantSectionHeaderOnly(trimmed, detected)) {
          currentLines.add(line);
        }
      } else {
        currentType ??= DumplogSectionType.other;
        currentLines.add(line);
      }
    }
    flushCurrent();

    return DumplogDocument(rawText: rawText, sections: sections);
  }

  static int _findFirstNamedSectionIndex(List<String> lines, int start) {
    for (int i = start; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;
      if (trimmed == '最新メッセージ:' ||
          trimmed == 'Latest messages:' ||
          trimmed == '所持品:' ||
          trimmed == 'Inventory:') {
        return i;
      }
    }
    return -1;
  }

  static bool _looksLikeMapBlock(List<String> block) {
    if (block.length >= 3) return true;
    for (final line in block) {
      if (line.contains('----') ||
          line.contains('Dlvl:') ||
          line.contains('階層:') ||
          line.contains('HP:')) {
        return true;
      }
    }
    return false;
  }

  static DumplogSectionType? _detectSectionStart(
    List<String> lines,
    int index,
    DumplogSectionType? currentType,
  ) {
    final trimmed = lines[index].trim();
    if (trimmed.isEmpty) return null;

    if (trimmed == '最新メッセージ:' || trimmed == 'Latest messages:') {
      return DumplogSectionType.messages;
    }
    if (trimmed == '所持品:' || trimmed == 'Inventory:') {
      return DumplogSectionType.inventory;
    }
    if (trimmed == '背景:' ||
        trimmed == 'Background:' ||
        trimmed == '最終状態:' ||
        trimmed == 'Final Status:' ||
        trimmed == '最終能力:' ||
        trimmed == 'Final Attributes:' ||
        trimmed.endsWith("'s attributes:") ||
        trimmed.endsWith('の特性:')) {
      return DumplogSectionType.attributes;
    }
    if (trimmed == '主要イベント:' ||
        trimmed == '記録済みイベント:' ||
        trimmed == 'Major events:' ||
        trimmed == 'Logged events:') {
      return DumplogSectionType.gamelog;
    }
    if (trimmed == '呪文:' ||
        trimmed == '呪文を何も知らなかった.' ||
        trimmed == 'Spells:' ||
        trimmed == 'You knew no spells.' ||
        trimmed == "You don't know any spells.") {
      return DumplogSectionType.spells;
    }
    if (trimmed == 'スキル:' || trimmed == 'Skills:') {
      return DumplogSectionType.skills;
    }
    if (trimmed == '自主的な縛り:' || trimmed == 'Voluntary challenges:') {
      return DumplogSectionType.conduct;
    }
    if (trimmed == '倒した怪物:' ||
        trimmed == '倒した怪物はいなかった。' ||
        trimmed == 'Vanquished creatures:' ||
        trimmed == 'No creatures were vanquished.') {
      return DumplogSectionType.vanquished;
    }
    if (trimmed == '虐殺した怪物種' ||
        trimmed == '絶滅した怪物種' ||
        trimmed == '虐殺・絶滅した怪物種' ||
        trimmed == '虐殺または絶滅した種はいなかった。' ||
        trimmed == 'Genocided species:' ||
        trimmed == 'Extinct species:' ||
        trimmed == 'Genocided or extinct species:' ||
        trimmed == 'No species were genocided or became extinct.') {
      return DumplogSectionType.genocided;
    }
    // ダンジョン概要（自主的な縛りの後に空行を挟んでダンジョン名が来る。行頭に1スペース付く場合あり）
    if (currentType == DumplogSectionType.conduct &&
        index > 0 &&
        lines[index - 1].trim().isEmpty) {
      if (trimmed.startsWith('The ') ||
          trimmed.contains('ダンジョン') ||
          trimmed.contains('迷宮') ||
          trimmed.contains('界') ||
          trimmed.contains('鉱山') ||
          trimmed.contains('倉庫番') ||
          trimmed.contains('ゲヘナ') ||
          trimmed.contains('Dungeon') ||
          trimmed.contains('Gehennom') ||
          trimmed.contains('Planes') ||
          trimmed.contains('Mines') ||
          trimmed.contains('Sokoban')) {
        return DumplogSectionType.overview;
      }
    }
    // 墓石直前の "Game over:" 行を墓石セクション開始として扱う
    if (trimmed == 'Game over:' &&
        index + 1 < lines.length &&
        _tombTopRegExp.hasMatch(lines[index + 1])) {
      return DumplogSectionType.tombstone;
    }
    // 墓石 ASCII アート開始検出（"----------" の次行が "/        \" など）
    if (_tombTopRegExp.hasMatch(lines[index]) &&
        index + 1 < lines.length &&
        _tombEdgeRegExp.hasMatch(lines[index + 1])) {
      return DumplogSectionType.tombstone;
    }
    if (_isSummaryStart(trimmed)) {
      return DumplogSectionType.summary;
    }
    return null;
  }

  static bool _isSummaryStart(String trimmed) {
    return trimmed.startsWith('さようなら ') ||
        trimmed.startsWith('さらば ') ||
        trimmed.startsWith('Goodbye ') ||
        trimmed.startsWith('Farewell ') ||
        trimmed.startsWith('So long ');
  }

  static bool _isRedundantSectionHeaderOnly(
    String trimmed,
    DumplogSectionType type,
  ) {
    switch (type) {
      case DumplogSectionType.messages:
        return trimmed == '最新メッセージ:' || trimmed == 'Latest messages:';
      case DumplogSectionType.inventory:
        return trimmed == '所持品:' || trimmed == 'Inventory:';
      case DumplogSectionType.gamelog:
        return trimmed == '主要イベント:' ||
            trimmed == '記録済みイベント:' ||
            trimmed == 'Major events:' ||
            trimmed == 'Logged events:';
      case DumplogSectionType.spells:
        return trimmed == '呪文:' || trimmed == 'Spells:';
      case DumplogSectionType.skills:
        return trimmed == 'スキル:' || trimmed == 'Skills:';
      case DumplogSectionType.conduct:
        return trimmed == '自主的な縛り:' || trimmed == 'Voluntary challenges:';
      case DumplogSectionType.vanquished:
        return trimmed == '倒した怪物:' || trimmed == 'Vanquished creatures:';
      case DumplogSectionType.genocided:
        return trimmed == '虐殺した怪物種' ||
            trimmed == '絶滅した怪物種' ||
            trimmed == '虐殺・絶滅した怪物種' ||
            trimmed == 'Genocided species:' ||
            trimmed == 'Extinct species:' ||
            trimmed == 'Genocided or extinct species:';
      case DumplogSectionType.tombstone:
        return trimmed == 'Game over:';
      default:
        return false;
    }
  }

  /// 非空行の最小共通先頭空白数を除去する（墓石 ASCII アートの相対配置を保持）
  static List<String> _dedentLines(List<String> lines) {
    int? minSpaces;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      int count = 0;
      while (count < line.length && line.codeUnitAt(count) == 0x20) {
        count++;
      }
      if (minSpaces == null || count < minSpaces) {
        minSpaces = count;
      }
    }
    if (minSpaces == null || minSpaces <= 0) return lines;
    final cut = minSpaces;
    return lines
        .map((line) => line.length >= cut ? line.substring(cut) : line.trimLeft())
        .toList();
  }

  static List<String> _trimOuterBlankLines(List<String> lines) {
    int start = 0;
    int end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start++;
    }
    while (end > start && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(start, end);
  }

  /// 日本語モード時の軽量日本語化（定型ヘッダー行と主要小見出しのみ）
  static String _localizeLineLightweight(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return line;

    // 開始・終了日時行
    final beganMatch = _gameBeganEnRegExp.firstMatch(trimmed);
    if (beganMatch != null) {
      return 'ゲーム開始: ${beganMatch.group(1)} / 終了: ${beganMatch.group(2)}';
    }

    // 英語形式のキャラ基本情報行
    final profMatch = _profileEnRegExp.firstMatch(trimmed);
    if (profMatch != null) {
      final name = profMatch.group(1)!;
      final align = _translateAlignWord(profMatch.group(2)!);
      final gend = _translateGenderWord(profMatch.group(3)!);
      final race = _translateRaceWord(profMatch.group(4)!);
      final role = _translateRoleWord(profMatch.group(5)!);
      return '$name（$align・$gend・$race・$role）';
    }

    // 主要小見出し
    switch (trimmed) {
      case 'Background:':
        return '背景:';
      case 'Basics:':
        return '基本情報:';
      case 'Final Status:':
        return '最終状態:';
      case 'Status:':
        return '状態:';
      case 'Final Attributes:':
        return '最終能力:';
      case 'Attributes:':
        return '能力:';
      case 'Miscellaneous:':
        return 'その他:';
      case 'You knew no spells.':
      case "You don't know any spells.":
        return '呪文を何も知らなかった。';
      case 'No creatures were vanquished.':
        return '倒した怪物はいなかった。';
      case 'No species were genocided or became extinct.':
        return '虐殺または絶滅した種はいなかった。';
      default:
        return line;
    }
  }

  static String _translateAlignWord(String w) {
    switch (w.toLowerCase()) {
      case 'lawful':
        return '秩序';
      case 'neutral':
        return '中立';
      case 'chaotic':
        return '混沌';
      default:
        return w;
    }
  }

  static String _translateGenderWord(String w) {
    switch (w.toLowerCase()) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return w;
    }
  }

  static String _translateRaceWord(String w) {
    switch (w.toLowerCase()) {
      case 'human':
        return '人間';
      case 'elf':
      case 'elven':
        return 'エルフ';
      case 'dwarf':
      case 'dwarven':
        return 'ドワーフ';
      case 'gnome':
      case 'gnomish':
        return 'ノーム';
      case 'orc':
      case 'orcish':
        return 'オーク';
      default:
        return w;
    }
  }

  static String _translateRoleWord(String w) {
    const map = <String, String>{
      'archeologist': '考古学者',
      'barbarian': '蛮族',
      'caveman': '原始人',
      'cavewoman': '原始人',
      'healer': '薬師',
      'knight': '騎士',
      'monk': '僧侶',
      'priest': '司祭',
      'priestess': '司祭',
      'ranger': 'レンジャー',
      'rogue': '盗賊',
      'samurai': '侍',
      'tourist': '観光客',
      'valkyrie': 'ワルキューレ',
      'wizard': '魔法使い',
    };
    return map[w.toLowerCase()] ?? w;
  }
}
