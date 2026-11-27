import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:darthack/models/tileset_info.dart';

/// VFX Studio 用のタイルセットエントリ
class StudioTilesetOption {
  final String id;
  final String label;
  final int tileWidth;
  final int tileHeight;
  final bool isTransparent;
  final String? filePath;

  const StudioTilesetOption({
    required this.id,
    required this.label,
    required this.tileWidth,
    required this.tileHeight,
    required this.isTransparent,
    this.filePath,
  });
}

/// 開発環境の `DartHack_private` および公開 `DartHack` から実タイル画像を検出し、
/// 不在環境（CI・単体テスト等）では手続き生成ダミータイルを提供するローダー。
class StudioTileLoader {
  static List<Directory> _candidateTileDirs() {
    final dirs = <Directory>[];
    final relPaths = <String>[
      '../../DartHack_private/sys/flutter/assets/tiles',
      '../DartHack_private/sys/flutter/assets/tiles',
      '../../../DartHack_private/sys/flutter/assets/tiles',
      'assets/tiles',
      'sys/flutter/assets/tiles',
    ];
    for (final p in relPaths) {
      final d = Directory(p);
      if (d.existsSync()) dirs.add(d);
    }
    try {
      var cur = File(Platform.resolvedExecutable).parent;
      for (int i = 0; i < 8; i++) {
        final priv = Directory('${cur.path}/DartHack_private/sys/flutter/assets/tiles');
        if (priv.existsSync()) dirs.add(priv);
        final pub = Directory('${cur.path}/DartHack/sys/flutter/assets/tiles');
        if (pub.existsSync()) dirs.add(pub);
        final local = Directory('${cur.path}/assets/tiles');
        if (local.existsSync()) dirs.add(local);
        final parent = cur.parent;
        if (parent.path == cur.path) break;
        cur = parent;
      }
    } catch (_) {}
    return dirs;
  }

  /// 利用可能なタイルセット選択肢を列挙する（実ファイルが無い場合もダミー透過/非透過を用意）
  static List<StudioTilesetOption> discoverOptions({bool includeDiskScan = true}) {
    final options = <StudioTilesetOption>[];
    if (includeDiskScan) {
      final dirs = _candidateTileDirs();
      for (final info in TilesetInfo.allTilesets) {
        final fileName = info.assetPath.split('/').last;
        String? foundPath;
        for (final d in dirs) {
          final f = File('${d.path}/$fileName');
          if (f.existsSync()) {
            foundPath = f.path;
            break;
          }
        }
        if (foundPath != null) {
          final tag = info.isTransparent ? '透過' : '非透過';
          options.add(StudioTilesetOption(
            id: info.id,
            label: '${info.displayName} [$tag]',
            tileWidth: info.tileWidth,
            tileHeight: info.tileHeight,
            isTransparent: info.isTransparent,
            filePath: foundPath,
          ));
        }
      }
    }

    // 実ファイルが見つからない環境（テストや単体クローン）でも透過・非透過を検証可能な合成タイルを追加
    if (!options.any((o) => o.isTransparent)) {
      options.add(const StudioTilesetOption(
        id: 'synthetic_transparent_32',
        label: 'Synthetic 32x32 [透過・テスト用]',
        tileWidth: 32,
        tileHeight: 32,
        isTransparent: true,
      ));
    }
    if (!options.any((o) => !o.isTransparent)) {
      options.add(const StudioTilesetOption(
        id: 'synthetic_opaque_32',
        label: 'Synthetic 32x32 [非透過・テスト用]',
        tileWidth: 32,
        tileHeight: 32,
        isTransparent: false,
      ));
    }
    return options;
  }

  /// 指定されたオプションの `ui.Image` をロード（または合成生成）する
  static Future<ui.Image> loadImage(StudioTilesetOption option) async {
    if (option.filePath != null) {
      final file = File(option.filePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    }
    return _buildSyntheticSheet(
      tileW: option.tileWidth,
      tileH: option.tileHeight,
      transparent: option.isTransparent,
    );
  }

  /// 40列×10行の軽量テスト用スプライトシートを合成する
  /// タイル番号の目安:
  /// 0: 床, 1: 壁, 2: 扉, 3: 水, 4: 溶岩, 5: 落とし穴, 6: 大岩, 7: 武器/矢,
  /// 10: 主人公(@), 11: オーク(o), 12: ドラゴン(D), 13: ゴブリン(g)
  static Future<ui.Image> _buildSyntheticSheet({
    required int tileW,
    required int tileH,
    required bool transparent,
  }) async {
    const cols = 40;
    const rows = 10;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = (cols * tileW).toDouble();
    final h = (rows * tileH).toDouble();

    if (!transparent) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1A1D24));
    }

    Rect cellRect(int idx) {
      final r = idx ~/ cols;
      final c = idx % cols;
      return Rect.fromLTWH(
        (c * tileW).toDouble(),
        (r * tileH).toDouble(),
        tileW.toDouble(),
        tileH.toDouble(),
      );
    }

    // 0: 床
    final r0 = cellRect(0);
    canvas.drawRect(r0, Paint()..color = const Color(0xFF262B36));
    canvas.drawCircle(r0.center, 1.5, Paint()..color = const Color(0xFF4B5568));

    // 1: 石壁
    final r1 = cellRect(1);
    canvas.drawRect(r1, Paint()..color = const Color(0xFF546E7A));
    canvas.drawRect(
      r1.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF90A4AE),
    );

    // 2: 閉じた木扉
    final r2 = cellRect(2);
    if (!transparent) {
      canvas.drawRect(r2, Paint()..color = const Color(0xFF262B36));
    }
    canvas.drawRect(r2.deflate(4), Paint()..color = const Color(0xFF8D6E63));

    // 3: 水たまり
    canvas.drawRect(cellRect(3), Paint()..color = const Color(0xFF1565C0));
    // 4: 溶岩
    canvas.drawRect(cellRect(4), Paint()..color = const Color(0xFFD84315));
    // 5: 落とし穴
    final r5 = cellRect(5);
    canvas.drawRect(r5, Paint()..color = const Color(0xFF262B36));
    canvas.drawOval(r5.deflate(5), Paint()..color = const Color(0xFF090A0D));

    // 6: 大岩
    final r6 = cellRect(6);
    canvas.drawCircle(r6.center, tileW * 0.36, Paint()..color = const Color(0xFFB0BEC5));

    // 7: 飛び道具/アイテム
    final r7 = cellRect(7);
    canvas.drawLine(
      Offset(r7.left + 6, r7.bottom - 6),
      Offset(r7.right - 6, r7.top + 6),
      Paint()
        ..strokeWidth = 3.0
        ..color = const Color(0xFFFFEE58),
    );

    // 10..13: キャラクター・モンスター
    void drawActor(int idx, Color bodyColor) {
      final rc = cellRect(idx);
      canvas.drawCircle(
        Offset(rc.center.dx, rc.center.dy - tileH * 0.14),
        tileW * 0.18,
        Paint()..color = bodyColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rc.center.dx, rc.center.dy + tileH * 0.16),
            width: tileW * 0.48,
            height: tileH * 0.36,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = bodyColor,
      );
    }

    drawActor(10, const Color(0xFFFFFFFF)); // @
    drawActor(11, const Color(0xFF66BB6A)); // o
    drawActor(12, const Color(0xFFEF5350)); // D
    drawActor(13, const Color(0xFF42A5F5)); // g

    final picture = recorder.endRecording();
    return picture.toImage(cols * tileW, rows * tileH);
  }
}
