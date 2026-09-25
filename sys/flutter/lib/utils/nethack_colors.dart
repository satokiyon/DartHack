import 'package:flutter/material.dart';

/// NetHack の 16色カラーパレット管理ユーティリティ
///
/// ダーク背景（#000000, #111111, #12161D 等）に最適化され、
/// 黒と灰色の識別性、茶と橙の色相分離、通常色とブライト色の階層差、
/// および色覚多様性（CUD）に配慮した配色を提供します。
class NethackColors {
  // CLR_0: 黒 (不可視を解消しつつ、灰色と混同しないダークスレート)
  static const Color clrBlack = Color(0xFF546E7A);

  // CLR_1: 赤 (警告感が高く、緑と色相・明度を明確分離した朱赤)
  static const Color clrRed = Color(0xFFFF5252);

  // CLR_2: 緑 (赤緑色覚特性に配慮した青みを含むミント緑)
  static const Color clrGreen = Color(0xFF38D9A9);

  // CLR_3: 茶色 (オレンジと明確に分離された赤褐色)
  static const Color clrBrown = Color(0xFFBA7C59);

  // CLR_4: 青 (クリアなコバルト青。ブライト青との階層差を維持)
  static const Color clrBlue = Color(0xFF42A5F5);

  // CLR_5: 紫 / マゼンタ (黒背景で明瞭かつ重厚感のあるオーキッドパープル)
  static const Color clrMagenta = Color(0xFFBA68C8);

  // CLR_6: シアン (落ち着きと高い視認性を兼ね備えたティールシアン)
  static const Color clrCyan = Color(0xFF26C6DA);

  // CLR_7: 灰色 (黒より一段明確に明るい明灰色)
  static const Color clrGray = Color(0xFFCFD8DC);

  // CLR_8: 無色 (自然で目に優しい標準オフホワイト)
  static const Color clrNoColor = Color(0xFFECEFF1);

  // CLR_9: オレンジ (鮮明なマンダリンオレンジ。茶色と明瞭に弁別)
  static const Color clrOrange = Color(0xFFFFA726);

  // CLR_10: 明るい緑 (目の覚めるようなハイライト黄緑)
  static const Color clrBrightGreen = Color(0xFF69F0AE);

  // CLR_11: 黄色 (白飛びせず文字が明瞭に浮き上がる鮮明なイエロー)
  static const Color clrYellow = Color(0xFFFFEE58);

  // CLR_12: 明るい青 (通常青との格差が明瞭なアイシーライトブルー)
  static const Color clrBrightBlue = Color(0xFF80D8FF);

  // CLR_13: 明るい紫 / ピンク (通常紫と明確に異なる鮮烈なネオンピンク)
  static const Color clrBrightMagenta = Color(0xFFFF4081);

  // CLR_14: 明るいシアン (最上位の輝度を誇るブライトアクアシアン)
  static const Color clrBrightCyan = Color(0xFF84FFFF);

  // CLR_15: 白 (完全な純白。最大HPや重要ハイライト用)
  static const Color clrWhite = Color(0xFFFFFFFF);

  /// 16色のパレット配列
  static const List<Color> palette = [
    clrBlack,
    clrRed,
    clrGreen,
    clrBrown,
    clrBlue,
    clrMagenta,
    clrCyan,
    clrGray,
    clrNoColor,
    clrOrange,
    clrBrightGreen,
    clrYellow,
    clrBrightBlue,
    clrBrightMagenta,
    clrBrightCyan,
    clrWhite,
  ];

  /// NetHack のカラーインデックス（0〜15）から Color を取得します。
  /// 範囲外の値が渡された場合は clrWhite を返します。
  static Color getNhColor(int colorIndex) {
    if (colorIndex >= 0 && colorIndex < palette.length) {
      return palette[colorIndex];
    }
    return clrWhite;
  }

  /// NetHack のカラーインデックスから 32bit ARGB 整数値（0xAARRGGBB）を取得します。
  static int getNhColorRgb(int colorIndex) {
    return getNhColor(colorIndex).toARGB32();
  }
}
