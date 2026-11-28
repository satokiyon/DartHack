import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/tileset_validator.dart';

/// 指定サイズ・塗りつぶし色のインメモリ PNG バイト列を生成するテスト用ヘルパー
Future<Uint8List> _createSolidPngBytes(int width, int height, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TilesetValidator Header Parsing & Validation Tests', () {
    test('Validates actual pixelhack_32x32.webp', () async {
      final file = File('assets/tiles/pixelhack_32x32.webp');
      if (!await file.exists()) {
        // テスト実行ディレクトリの差異対策
        final altFile = File('sys/flutter/assets/tiles/pixelhack_32x32.webp');
        if (await altFile.exists()) {
          final bytes = await altFile.readAsBytes();
          final result = await TilesetValidator.validate(bytes, fileName: 'pixelhack_32x32.webp');
          expect(result.isValid, true);
          expect(result.tileWidth, 32);
          expect(result.tileHeight, 32);
          expect(result.cols, 40);
          expect(result.rows, 58);
          expect(result.aspectRatio, closeTo(1.0, 0.001));
          return;
        }
      }
      final bytes = await file.readAsBytes();
      final result = await TilesetValidator.validate(bytes, fileName: 'pixelhack_32x32.webp');
      expect(result.isValid, true);
      expect(result.tileWidth, 32);
      expect(result.tileHeight, 32);
      expect(result.cols, 40);
      expect(result.rows, 58);
    });

    test('Validates non-square 15x25 tileset (600x1500) without filename hints', () async {
      // 非正方形タイル (15x25, 40列x60行 = 600x1500) をインメモリ生成し、ファイル名ヒントなしで判定をテスト
      final bytes = await _createSolidPngBytes(600, 1500, const Color(0xFF224466));

      final result = await TilesetValidator.validate(bytes, fileName: 'unknown.png');
      expect(result.isValid, true);
      expect(result.imageWidth, 600);
      expect(result.imageHeight, 1500);
      expect(result.tileWidth, 15);
      expect(result.tileHeight, 25);
      expect(result.cols, 40);
      expect(result.rows, 60);
      expect(result.aspectRatio, closeTo(0.6, 0.001));
      expect(result.isTransparent, false);
    });

    test('Validates actual default_16x16.webp', () async {
      File file = File('assets/tiles/default_16x16.webp');
      if (!await file.exists()) {
        file = File('sys/flutter/assets/tiles/default_16x16.webp');
      }
      final bytes = await file.readAsBytes();
      final result = await TilesetValidator.validate(bytes, fileName: 'default_16x16.webp');
      expect(result.isValid, true);
      expect(result.tileWidth, 16);
      expect(result.tileHeight, 16);
      expect(result.cols, 40);
    });

    test('Rejects image with width not divisible by 40', () async {
      // 偽のPNGヘッダー (幅 100, 高さ 100) -> 100 % 40 != 0 (128バイト以上)
      final bytes = Uint8List(256);
      bytes.setRange(0, 8, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final bd = ByteData.sublistView(bytes);
      bd.setUint32(16, 100, Endian.big); // width: 100
      bd.setUint32(20, 100, Endian.big); // height: 100

      final result = await TilesetValidator.validate(bytes, fileName: 'invalid_width.png');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('40 列'));
    });

    test('Rejects file too small', () async {
      final bytes = Uint8List(50);
      final result = await TilesetValidator.validate(bytes, fileName: 'tiny.png');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('ファイルサイズが小さすぎます'));
    });

    test('Correctly identifies transparent tileset (kevintamtiles_64x64.webp)', () async {
      File file = File('assets/tiles/kevintamtiles_64x64.webp');
      if (!await file.exists()) {
        file = File('sys/flutter/assets/tiles/kevintamtiles_64x64.webp');
      }
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final result = await TilesetValidator.validate(bytes, fileName: 'kevintamtiles_64x64.webp');
        expect(result.isValid, true);
        expect(result.isTransparent, true);
      }
    });

    test('Correctly identifies transparent built-in tileset (pixelhack_32x32.webp)', () async {
      File file = File('assets/tiles/pixelhack_32x32.webp');
      if (!await file.exists()) {
        file = File('sys/flutter/assets/tiles/pixelhack_32x32.webp');
      }
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final result = await TilesetValidator.validate(bytes, fileName: 'pixelhack_32x32.webp');
        expect(result.isValid, true);
        expect(result.isTransparent, true);
      }
    });

    test('Correctly identifies opaque custom tileset', () async {
      // 完全不透明な 640x640 (16x16, 40列x40行) PNG を生成して不透明判定を検証
      final bytes = await _createSolidPngBytes(640, 640, const Color(0xFF000000));
      final result = await TilesetValidator.validate(bytes, fileName: 'opaque_16x16.png');
      expect(result.isValid, true);
      expect(result.isTransparent, false);
    });
  });
}
