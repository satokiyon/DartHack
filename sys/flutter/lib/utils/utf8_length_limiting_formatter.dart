import 'dart:convert';
import 'package:flutter/services.dart';

/// UTF-8 バイト数で入力文字数を制限する TextInputFormatter
class Utf8LengthLimitingTextInputFormatter extends TextInputFormatter {
  final int maxBytes;

  Utf8LengthLimitingTextInputFormatter(this.maxBytes);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final bytes = utf8.encode(newValue.text);
    if (bytes.length <= maxBytes) {
      return newValue;
    }

    // maxBytes を超える場合、文字単位で安全に切り詰める
    int currentBytes = 0;
    final buffer = StringBuffer();

    for (final rune in newValue.text.runes) {
      final charStr = String.fromCharCode(rune);
      final charBytes = utf8.encode(charStr).length;
      if (currentBytes + charBytes > maxBytes) {
        break;
      }
      buffer.write(charStr);
      currentBytes += charBytes;
    }

    final truncatedText = buffer.toString();
    final newOffset = truncatedText.length;

    return TextEditingValue(
      text: truncatedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
