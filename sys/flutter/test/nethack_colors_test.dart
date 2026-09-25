import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/utils/nethack_colors.dart';

void main() {
  group('NethackColors tests', () {
    test('Palette contains exactly 16 defined colors', () {
      expect(NethackColors.palette.length, equals(16));
    });

    test('getNhColor returns valid colors for indices 0 to 15', () {
      for (int i = 0; i < 16; i++) {
        final color = NethackColors.getNhColor(i);
        expect(color, equals(NethackColors.palette[i]));
      }
    });

    test('getNhColor falls back to pure white for out of range indices', () {
      expect(NethackColors.getNhColor(-1), equals(NethackColors.clrWhite));
      expect(NethackColors.getNhColor(16), equals(NethackColors.clrWhite));
      expect(NethackColors.getNhColor(999), equals(NethackColors.clrWhite));
    });

    test('getNhColorRgb returns correct 32bit ARGB hex values', () {
      // CLR_BLACK: 0xFF546E7A
      expect(NethackColors.getNhColorRgb(0), equals(0xFF546E7A));
      // CLR_RED: 0xFFFF5252
      expect(NethackColors.getNhColorRgb(1), equals(0xFFFF5252));
      // CLR_GREEN: 0xFF38D9A9
      expect(NethackColors.getNhColorRgb(2), equals(0xFF38D9A9));
      // CLR_BROWN: 0xFFBA7C59
      expect(NethackColors.getNhColorRgb(3), equals(0xFFBA7C59));
      // CLR_BLUE: 0xFF42A5F5
      expect(NethackColors.getNhColorRgb(4), equals(0xFF42A5F5));
      // CLR_MAGENTA: 0xFFBA68C8 (黒背景で見やすいオーキッドパープル)
      expect(NethackColors.getNhColorRgb(5), equals(0xFFBA68C8));
      // CLR_CYAN: 0xFF26C6DA
      expect(NethackColors.getNhColorRgb(6), equals(0xFF26C6DA));
      // CLR_GRAY: 0xFFCFD8DC
      expect(NethackColors.getNhColorRgb(7), equals(0xFFCFD8DC));
      // NO_COLOR: 0xFFECEFF1
      expect(NethackColors.getNhColorRgb(8), equals(0xFFECEFF1));
      // CLR_ORANGE: 0xFFFFA726
      expect(NethackColors.getNhColorRgb(9), equals(0xFFFFA726));
      // CLR_BRIGHT_GREEN: 0xFF69F0AE
      expect(NethackColors.getNhColorRgb(10), equals(0xFF69F0AE));
      // CLR_YELLOW: 0xFFFFEE58
      expect(NethackColors.getNhColorRgb(11), equals(0xFFFFEE58));
      // CLR_BRIGHT_BLUE: 0xFF80D8FF
      expect(NethackColors.getNhColorRgb(12), equals(0xFF80D8FF));
      // CLR_BRIGHT_MAGENTA: 0xFFFF4081
      expect(NethackColors.getNhColorRgb(13), equals(0xFFFF4081));
      // CLR_BRIGHT_CYAN: 0xFF84FFFF
      expect(NethackColors.getNhColorRgb(14), equals(0xFF84FFFF));
      // CLR_WHITE: 0xFFFFFFFF
      expect(NethackColors.getNhColorRgb(15), equals(0xFFFFFFFF));
    });

    test('Color luminance and contrast design integrity', () {
      // 1. 黒 (CLR_BLACK) と 灰色 (CLR_GRAY) は誤認を防ぐため明度差が明確であること
      final blackLum = NethackColors.clrBlack.computeLuminance();
      final grayLum = NethackColors.clrGray.computeLuminance();
      expect(grayLum > blackLum + 0.3, isTrue,
          reason: '灰色は黒モンスターとの識別のため明確に明るくなければならない');

      // 2. 通常青 (CLR_BLUE) と ブライト青 (CLR_BRIGHT_BLUE) の階層差
      final blueLum = NethackColors.clrBlue.computeLuminance();
      final brightBlueLum = NethackColors.clrBrightBlue.computeLuminance();
      expect(brightBlueLum > blueLum + 0.15, isTrue,
          reason: 'ブライト青は通常青より一段明るく階層差を維持しなければならない');

      // 3. 通常紫 (CLR_MAGENTA) と ブライト紫 (CLR_BRIGHT_MAGENTA) の差別化
      expect(NethackColors.clrMagenta, isNot(equals(NethackColors.clrBrightMagenta)),
          reason: '通常紫とブライト紫は明確に差別化されなければならない');

      // 4. 黒背景 (#12161D) に対して全色がある程度以上の輝度を保ち不可視でないこと
      for (int i = 0; i < 16; i++) {
        final lum = NethackColors.palette[i].computeLuminance();
        expect(lum > 0.08, isTrue,
            reason: 'インデックス $i の色は黒背景で視認可能でなければならない (luminance: $lum)');
      }
    });
  });
}
