import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_screen.dart';
import 'package:darthack/nethack_map_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NetHackMapPainter paints correctly in text mode with pet and pile', () {
    final screen = NetHackScreen();

    // 通常のモンスター/文字
    screen.printGlyph(3, 10, 10, -1, 'd'.codeUnitAt(0), 0xFFFFFF, 0);

    // ペット (MG_PET = 0x10)
    screen.printGlyph(3, 11, 10, -1, 'd'.codeUnitAt(0), 0xFFFFFF, 0x10);

    // 乗馬ペット (MG_RIDDEN = 0x20)
    screen.printGlyph(3, 12, 10, -1, 'h'.codeUnitAt(0), 0xFFFFFF, 0x20);

    // アイテム山 (MG_OBJPILE = 0x80)
    screen.printGlyph(3, 13, 10, -1, '%'.codeUnitAt(0), 0xFFFFFF, 0x80);

    final painter = NetHackMapPainter(
      screen: screen,
      tileImage: null,
      tileWidth: 32,
      tileHeight: 32,
      useTiles: false,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 600);

    // エラーなく paint が完了することを検証
    expect(() => painter.paint(canvas, size), returnsNormally);
    final picture = recorder.endRecording();
    picture.dispose();
  });

  test('NetHackMapPainter paints correctly in tile mode with pet and pile overlays', () async {
    final screen = NetHackScreen();

    // 通常タイル
    screen.printGlyph(3, 5, 5, 100, 'd'.codeUnitAt(0), 0xFFFFFF, 0);

    // ペットタイル (MG_PET = 0x10)
    screen.printGlyph(3, 6, 5, 101, 'd'.codeUnitAt(0), 0xFFFFFF, 0x10);

    // 乗馬ペットタイル (MG_RIDDEN = 0x20)
    screen.printGlyph(3, 7, 5, 102, 'h'.codeUnitAt(0), 0xFFFFFF, 0x20);

    // アイテム山タイル (MG_OBJPILE = 0x80)
    screen.printGlyph(3, 8, 5, 103, '%'.codeUnitAt(0), 0xFFFFFF, 0x80);

    // ペットかつアイテム山
    screen.printGlyph(3, 9, 5, 104, 'd'.codeUnitAt(0), 0xFFFFFF, 0x10 | 0x80);

    // 64x64 のダミー tileImage を作成
    final recorderImg = ui.PictureRecorder();
    final canvasImg = Canvas(recorderImg);
    canvasImg.drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = Colors.blue);
    final dummyImg = await recorderImg.endRecording().toImage(64, 64);

    final painter = NetHackMapPainter(
      screen: screen,
      tileImage: dummyImg,
      tileWidth: 32,
      tileHeight: 32,
      useTiles: true,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 600);

    expect(() => painter.paint(canvas, size), returnsNormally);
    final picture = recorder.endRecording();
    picture.dispose();
    dummyImg.dispose();
  });
}
