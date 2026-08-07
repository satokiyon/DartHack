// NOTICE: Modified by NetHackJP contributor @satokiyon; latest change date: 2026-08-07.

/// PC用80桁固定改行テキストをスマートフォン画面向けに自然に整形するユーティリティクラス
class TextFormatter {
  // 改行をそのまま保持する末尾記号（句点、感嘆符・疑問符、コロン）
  static final RegExp _keepBreakCharRegex = RegExp(r'[。\.!！?？:：]\s*$');
  
  // 区切り線（---, === などが連続する行）
  static final RegExp _dividerRegex = RegExp(r'^\s*([-=*#~_+]){3,}\s*$');
  
  // 箇条書きパターン (例: "- ", "* ", "1. ", "(1) ", "・ " など)
  static final RegExp _listItemRegex =
      RegExp(r'^\s*([-\*•]\s+|\d+[\.\)]\s+|\([0-9a-zA-Z]+\)\s+|[・◆◇■□▲△▼▽]\s*)');

  /// 指定した文字コードが半角ASCII文字（英数字・半角記号）かどうかを判定
  static bool _isAsciiCode(int code) {
    return code >= 0x20 && code <= 0x7E;
  }

  /// 80桁付近でハード改行されたテキストの行リストを受け取り、自然な段落に整形して返す
  static List<String> reformatLines(List<String> rawLines) {
    if (rawLines.isEmpty) return [];

    final result = <String>[];
    String currentParagraph = '';

    for (int i = 0; i < rawLines.length; i++) {
      final rawLine = rawLines[i].replaceAll('\r', '');
      final trimmed = rawLine.trim();

      // 空白行の場合: 現在の段落をフラッシュして、空行をそのまま保持
      if (trimmed.isEmpty) {
        if (currentParagraph.isNotEmpty) {
          result.add(currentParagraph);
          currentParagraph = '';
        }
        result.add(rawLine);
        continue;
      }

      // アスキーマップ・枠線・図表行（+---+ や |...| 行など）の判定
      final isCodeBlockOrAsciiArt =
          RegExp(r'^\s*[\+|].*[\+|]\s*$').hasMatch(rawLine) ||
          RegExp(r'^\s*\+[-+=]+\s*$').hasMatch(rawLine) ||
          RegExp(r'^\s*\\ \| /\s*$').hasMatch(rawLine);

      if (isCodeBlockOrAsciiArt) {
        if (currentParagraph.isNotEmpty) {
          result.add(currentParagraph);
          currentParagraph = '';
        }
        result.add(rawLine);
        continue;
      }

      // 区切り線や箇条書きで始まる特別行の場合: 前の段落をフラッシュし、改行を保持
      final isSpecialLine =
          _dividerRegex.hasMatch(rawLine) || _listItemRegex.hasMatch(rawLine);

      if (isSpecialLine) {
        if (currentParagraph.isNotEmpty) {
          result.add(currentParagraph);
          currentParagraph = '';
        }
        // 箇条書きや区切り線行は新しい段落の開始点として蓄積または直接出力
        currentParagraph = rawLine;
        if (_keepBreakCharRegex.hasMatch(rawLine)) {
          result.add(currentParagraph);
          currentParagraph = '';
        }
        continue;
      }

      // この行の末尾で改行を強制保持すべきか判定
      final shouldKeepBreak = _keepBreakCharRegex.hasMatch(rawLine);

      if (currentParagraph.isEmpty) {
        // 段落の先頭行（インデント維持）
        currentParagraph = rawLine;
      } else {
        // 既存の段落に結合
        final prevTrimmed = currentParagraph.trimRight();
        final prevLastCode =
            prevTrimmed.isNotEmpty ? prevTrimmed.codeUnitAt(prevTrimmed.length - 1) : -1;
        final currFirstCode =
            trimmed.isNotEmpty ? trimmed.codeUnitAt(0) : -1;

        bool needsSpace = false;
        if (prevLastCode != -1 && currFirstCode != -1) {
          if (_isAsciiCode(prevLastCode) && _isAsciiCode(currFirstCode)) {
            needsSpace = true;
          }
        }

        if (needsSpace) {
          currentParagraph += ' $trimmed';
        } else {
          currentParagraph += trimmed;
        }
      }

      if (shouldKeepBreak) {
        result.add(currentParagraph);
        currentParagraph = '';
      }
    }

    if (currentParagraph.isNotEmpty) {
      result.add(currentParagraph);
    }

    return result;
  }

  /// 単一のテキスト（改行コード含む）を受け取り、整形後のテキスト文字列として返す
  static String reformatText(String rawText) {
    final lines = rawText.split('\n');
    final reformatted = reformatLines(lines);
    return reformatted.join('\n');
  }
}
