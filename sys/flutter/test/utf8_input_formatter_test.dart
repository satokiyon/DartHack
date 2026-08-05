import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:darthack/utils/utf8_length_limiting_formatter.dart';
import 'dart:convert';

void main() {
  group('Utf8LengthLimitingTextInputFormatter Test', () {
    final formatter = Utf8LengthLimitingTextInputFormatter(100);

    test('ASCII文字（1バイト/文字）が100バイトまで入力できる', () {
      final asciiText = 'a' * 100;
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(
        text: asciiText,
        selection: TextSelection.collapsed(offset: 100),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals(asciiText));
      expect(utf8.encode(result.text).length, equals(100));
    });

    test('ASCII文字が100バイトを超える場合、100バイトに切り詰められる', () {
      final asciiText = 'a' * 110;
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(
        text: asciiText,
        selection: TextSelection.collapsed(offset: 110),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('a' * 100));
      expect(utf8.encode(result.text).length, equals(100));
    });

    test('全角日本語（3バイト/文字）が33文字（99バイト）入力でき、100バイトを超えない', () {
      final jpText = 'あ' * 34; // 34文字 = 102バイト
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(
        text: jpText,
        selection: TextSelection.collapsed(offset: jpText.length),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('あ' * 33)); // 33文字 = 99バイト
      expect(utf8.encode(result.text).length, equals(99));
    });

    test('半角と全角が混在した場合も正確に100バイト以内に収まる', () {
      // 'あ' * 33 (99バイト) + 'a' (1バイト) = 100バイト
      final mixedText = ('あ' * 33) + 'a' + 'あ'; // 103バイト
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(
        text: mixedText,
        selection: TextSelection.collapsed(offset: mixedText.length),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals(('あ' * 33) + 'a'));
      expect(utf8.encode(result.text).length, equals(100));
    });
  });
}
