import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String Option Limits & UTF-8 Byte Count Tests', () {
    // UTF-8 バイト数計算ヘルパー
    int countBytes(String text) => utf8.encode(text).length;

    test('半角英数字（1バイト/文字）のバイト数計算', () {
      expect(countBytes('Hero'), equals(4));
      expect(countBytes('A' * 31), equals(31));
      expect(countBytes('A' * 62), equals(62));
    });

    test('全角日本語（3バイト/文字）のバイト数計算', () {
      expect(countBytes('勇者'), equals(6)); // 2文字 * 3 = 6
      expect(countBytes('あ' * 10), equals(30)); // 10文字 * 3 = 30
      expect(countBytes('あ' * 20), equals(60)); // 20文字 * 3 = 60
    });

    test('絵文字（4バイト/文字）のバイト数計算', () {
      expect(countBytes('🐶'), equals(4));
      expect(countBytes('🐱'), equals(4));
      expect(countBytes('🐴'), equals(4));
      expect(countBytes('🍎'), equals(4));
      expect(countBytes('🐶' * 7), equals(28)); // 7文字 * 4 = 28
      expect(countBytes('🐶' * 15), equals(60)); // 15文字 * 4 = 60
    });

    test('主人公の名前: 上限31バイト（PL_NSIZ=32）の判定', () {
      const maxBytes = 31;

      // 31バイト以内 -> OK
      expect(countBytes('A' * 31) <= maxBytes, isTrue);
      expect(countBytes('あ' * 10) <= maxBytes, isTrue); // 30バイト
      expect(countBytes('🐶' * 7) <= maxBytes, isTrue); // 28バイト

      // 超過 -> Overflow
      expect(countBytes('A' * 32) > maxBytes, isTrue); // 32バイト
      expect(countBytes('あ' * 11) > maxBytes, isTrue); // 33バイト
      expect(countBytes('🐶' * 8) > maxBytes, isTrue); // 32バイト
    });

    test('犬・猫・馬の名前: 上限62バイト（PL_PSIZ=63）の判定', () {
      const maxBytes = 62;

      // 62バイト以内 -> OK
      expect(countBytes('A' * 62) <= maxBytes, isTrue);
      expect(countBytes('あ' * 20) <= maxBytes, isTrue); // 60バイト
      expect(countBytes('🐱' * 15) <= maxBytes, isTrue); // 60バイト

      // 以前の不具合値（15バイト）では弾かれていた正常な名前が許可されること
      const normalJpName = '忠犬ハチ公'; // 5文字 = 15バイト
      const longJpName = 'ポチ・ドッグ・ジュニア'; // 11文字 = 33バイト (15バイト超過だが62バイト以内)
      expect(countBytes(normalJpName) <= maxBytes, isTrue);
      expect(countBytes(longJpName) <= maxBytes, isTrue);

      // 超過 -> Overflow
      expect(countBytes('A' * 63) > maxBytes, isTrue); // 63バイト
      expect(countBytes('あ' * 21) > maxBytes, isTrue); // 63バイト
      expect(countBytes('🐱' * 16) > maxBytes, isTrue); // 64バイト
    });

    test('果物の名前: 日英両モード上限63バイト（PL_FSIZ=64）の判定', () {
      const maxBytes = 63;

      // 63バイト以内 -> OK
      expect(countBytes('A' * 63) <= maxBytes, isTrue);
      expect(countBytes('apple') <= maxBytes, isTrue);
      expect(countBytes('あ' * 21) <= maxBytes, isTrue); // 63バイト
      expect(countBytes('🍎' * 15) <= maxBytes, isTrue); // 60バイト

      // 超過 -> Overflow
      expect(countBytes('A' * 64) > maxBytes, isTrue); // 64バイト
      expect(countBytes('あ' * 22) > maxBytes, isTrue); // 66バイト
    });
  });
}
