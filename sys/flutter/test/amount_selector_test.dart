import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  group('AmountSelector Length & Digits Limit Test', () {
    test('FilteringTextInputFormatter.digitsOnly と LengthLimitingTextInputFormatter の検証', () {
      const maxCount = 50; // 2桁
      final maxLen = maxCount.toString().length;
      final formatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ];

      // 数字かつ2桁以内のテスト
      final validValue = TextEditingValue(
        text: '50',
        selection: const TextSelection.collapsed(offset: 2),
      );
      var res = validValue;
      for (final f in formatters) {
        res = f.formatEditUpdate(TextEditingValue.empty, res);
      }
      expect(res.text, equals('50'));

      // 3桁以上の入力テスト
      final overValue = TextEditingValue(
        text: '500',
        selection: const TextSelection.collapsed(offset: 3),
      );
      res = overValue;
      for (final f in formatters) {
        res = f.formatEditUpdate(TextEditingValue.empty, res);
      }
      expect(res.text, equals('50'));
    });
  });
}
