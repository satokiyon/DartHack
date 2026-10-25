import 'dart:typed_data';
import 'dart:ui' as ui;

/// タイルセット画像のバリデーション結果
class TilesetValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? imageWidth;
  final int? imageHeight;
  final int? tileWidth;
  final int? tileHeight;
  final int? rows;
  final int? cols;
  final String? formatDescription;

  const TilesetValidationResult.success({
    required this.imageWidth,
    required this.imageHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.rows,
    required this.cols,
    required this.formatDescription,
  })  : isValid = true,
        errorMessage = null;

  const TilesetValidationResult.failure(this.errorMessage)
      : isValid = false,
        imageWidth = null,
        imageHeight = null,
        tileWidth = null,
        tileHeight = null,
        rows = null,
        cols = null,
        formatDescription = null;

  /// アスペクト比 (tileWidth / tileHeight)
  double? get aspectRatio {
    if (tileWidth == null || tileHeight == null || tileHeight == 0) return null;
    return tileWidth! / tileHeight!;
  }
}

/// 外部タイルセット画像（PNG / WebP / BMP）に対する厳密なバリデータ
class TilesetValidator {
  /// 許可する最大ファイルサイズ (20MB)
  static const int maxFileSize = 20 * 1024 * 1024;

  /// NetHack の標準タイルスプライトシートの1行あたりタイル数 (40列)
  static const int standardCols = 40;

  /// 許容する最小行数 (NetHack 3.4/3.6等の初期タイルで約20〜30行)
  static const int minRows = 20;

  /// 許容する最大行数 (NetHack 3.7+派生タイルで約60〜80行)
  static const int maxRows = 85;

  /// サポート対象拡張子
  static const Set<String> supportedExtensions = {
    '.png',
    '.webp',
    '.bmp',
  };

  /// ファイルパスから拡張子を検証
  static bool hasSupportedExtension(String filePath) {
    final lower = filePath.toLowerCase();
    return supportedExtensions.any((ext) => lower.endsWith(ext));
  }

  /// バイナリから直接画像サイズ（幅・高さ）とフォーマットを解析
  static ({int width, int height, String format})? parseImageHeader(Uint8List bytes) {
    if (bytes.length < 32) return null;

    final bd = ByteData.sublistView(bytes);

    // 1. PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      if (bytes.length >= 24) {
        final w = bd.getUint32(16, Endian.big);
        final h = bd.getUint32(20, Endian.big);
        return (width: w, height: h, format: 'PNG');
      }
    }

    // 2. BMP: 'BM' = 0x42 0x4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      if (bytes.length >= 26) {
        final w = bd.getInt32(18, Endian.little);
        final h = bd.getInt32(22, Endian.little).abs();
        if (w > 0 && h > 0) {
          return (width: w, height: h, format: 'BMP');
        }
      }
    }

    // 3. WebP: RIFF .... WEBP
    if (bytes.length >= 30 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      final chunk = String.fromCharCodes(bytes.sublist(12, 16));
      if (chunk == 'VP8 ') {
        final w = (bytes[26] | (bytes[27] << 8)) & 0x3fff;
        final h = (bytes[28] | (bytes[29] << 8)) & 0x3fff;
        return (width: w, height: h, format: 'WebP (Lossy)');
      } else if (chunk == 'VP8L') {
        final b1 = bytes[21];
        final b2 = bytes[22];
        final b3 = bytes[23];
        final b4 = bytes[24];
        final w = 1 + (b1 | ((b2 & 0x3f) << 8));
        final h = 1 + (((b2 >> 6) | (b3 << 2) | ((b4 & 0xf) << 10)));
        return (width: w, height: h, format: 'WebP (Lossless)');
      } else if (chunk == 'VP8X') {
        final w = 1 + (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16));
        final h = 1 + (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16));
        return (width: w, height: h, format: 'WebP (Extended)');
      }
    }

    return null;
  }

  /// タイルセット画像を検証し、サイズとアスペクト比を自動判定する
  static Future<TilesetValidationResult> validate(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (bytes.length < 128) {
      return const TilesetValidationResult.failure('ファイルサイズが小さすぎます（有効な画像ファイルではありません）');
    }

    if (bytes.length > maxFileSize) {
      return const TilesetValidationResult.failure('ファイルサイズが上限（20MB）を超えています');
    }

    // 画像寸法の取得（ヘッダー解析を優先、失敗時は ui.instantiateImageCodec にフォールバック）
    int imgW = 0;
    int imgH = 0;
    String format = 'Unknown';

    final headerInfo = parseImageHeader(bytes);
    if (headerInfo != null) {
      imgW = headerInfo.width;
      imgH = headerInfo.height;
      format = headerInfo.format;
    } else {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        imgW = frame.image.width;
        imgH = frame.image.height;
        format = 'ImageCodec';
      } catch (e) {
        return const TilesetValidationResult.failure('対応していない画像形式か、破損した画像ファイルです (PNG/WebP/BMP のみ対応)');
      }
    }

    if (imgW <= 0 || imgH <= 0) {
      return const TilesetValidationResult.failure('画像の解像度を正常に取得できませんでした');
    }

    // NetHackスプライトシート標準の「横40列」チェック
    if (imgW % standardCols != 0) {
      return TilesetValidationResult.failure(
        '横幅 ($imgW px) が NetHack 標準の 40 列で割り切れません。\n'
        'NetHack のタイルシート画像は横 40 タイル構成である必要があります。',
      );
    }

    final detectedTileW = imgW ~/ standardCols;
    if (detectedTileW < 8 || detectedTileW > 256) {
      return TilesetValidationResult.failure(
        '検出されたタイル幅 ($detectedTileW px) が許容範囲外 (8〜256px) です。',
      );
    }

    int? resolvedTileH;

    // 1. ファイル名からのサイズ判別 (例: "geoduck_15x25.png", "my_32x32.webp")
    if (fileName != null) {
      final match = RegExp(r'(\d+)x(\d+)').firstMatch(fileName);
      if (match != null) {
        final fnW = int.tryParse(match.group(1)!);
        final fnH = int.tryParse(match.group(2)!);
        if (fnW != null && fnH != null && fnW == detectedTileW && fnH >= 8 && fnH <= 256) {
          // 画像全体の高さが fnH で妥当に行数分割できるか検証
          final rows = imgH ~/ fnH;
          if (rows >= minRows && rows <= maxRows) {
            resolvedTileH = fnH;
          }
        }
      }
    }

    // 2. 実画像サイズからの自動判定 (ファイル名指定が無い、または不一致の場合)
    if (resolvedTileH == null) {
      // 2-1. 正方形タイル (tileWidth == tileHeight) の検証
      if (imgH % detectedTileW == 0) {
        final rows = imgH ~/ detectedTileW;
        if (rows >= minRows && rows <= maxRows) {
          resolvedTileH = detectedTileW;
        }
      }

      // 2-2. 既知のNetHack標準行数（58行、60行、27行、40行等）での分割チェック
      if (resolvedTileH == null) {
        const knownRows = [58, 60, 59, 27, 40, 30];
        for (final r in knownRows) {
          if (imgH % r == 0) {
            final h = imgH ~/ r;
            if (h >= 8 && h <= 256) {
              resolvedTileH = h;
              break;
            }
          }
        }
      }

      // 2-3. 余白ピクセル（ヘッダー・フッターにわずかな端数がある場合）を考慮した行数算出
      if (resolvedTileH == null) {
        // 正方形として行数を算出して範囲内なら採用
        final estimatedRows = (imgH / detectedTileW).round();
        if (estimatedRows >= minRows && estimatedRows <= maxRows) {
          resolvedTileH = detectedTileW;
        }
      }
    }

    if (resolvedTileH == null) {
      return TilesetValidationResult.failure(
        '画像の高さ ($imgH px) からタイルの高さを判定できませんでした。\n'
        'NetHack の標準タイル行数 (20〜80行) に適合しません。',
      );
    }

    final finalRows = imgH ~/ resolvedTileH;
    if (finalRows < minRows || finalRows > maxRows) {
      return TilesetValidationResult.failure(
        '検出されたタイル行数 ($finalRows 行) が NetHack の許容範囲 ($minRows〜$maxRows 行) を外れています。',
      );
    }

    return TilesetValidationResult.success(
      imageWidth: imgW,
      imageHeight: imgH,
      tileWidth: detectedTileW,
      tileHeight: resolvedTileH,
      rows: finalRows,
      cols: standardCols,
      formatDescription: format,
    );
  }
}

