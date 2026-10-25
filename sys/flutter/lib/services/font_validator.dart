import 'dart:io';
import 'dart:typed_data';

/// フォントバイナリのセキュリティ検証結果
class FontValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Uint8List? normalizedBytes;
  final String? formatDescription;

  const FontValidationResult.success({
    required this.normalizedBytes,
    required this.formatDescription,
  })  : isValid = true,
        errorMessage = null;

  const FontValidationResult.failure(this.errorMessage)
      : isValid = false,
        normalizedBytes = null,
        formatDescription = null;
}

/// 外部フォントファイルに対する SFNT / WOFF 構造の厳密なバイナリ検証器
class FontValidator {
  /// 許可する最大ファイルサイズ (20MB)
  static const int maxFileSize = 20 * 1024 * 1024;

  /// 展開後の最大サイズ制限 (30MB: zip爆弾防御)
  static const int maxExpandedSize = 30 * 1024 * 1024;

  /// サポート対象拡張子
  static const Set<String> supportedExtensions = {
    '.ttf',
    '.otf',
    '.ttc',
    '.woff',
  };

  /// ファイルパスから拡張子を検証
  static bool hasSupportedExtension(String filePath) {
    final lower = filePath.toLowerCase();
    return supportedExtensions.any((ext) => lower.endsWith(ext));
  }

  /// フォントバイト列を厳密に検証し、WOFF1 の場合は非圧縮 SFNT へ正規化して返す
  static FontValidationResult validateAndNormalize(Uint8List bytes) {
    if (bytes.length < 128) {
      return const FontValidationResult.failure('ファイルサイズが小さすぎます（有効なフォントファイルではありません）');
    }

    if (bytes.length > maxFileSize) {
      return const FontValidationResult.failure('ファイルサイズが上限（20MB）を超えています');
    }

    final byteData = ByteData.sublistView(bytes);
    final magic = byteData.getUint32(0, Endian.big);

    // 1. WOFF 1.0 (マジック 'wOFF' = 0x774F4646) の展開処理
    if (magic == 0x774F4646) {
      return _unpackAndValidateWoff1(bytes, byteData);
    }

    // 2. TrueType Collection ('ttcf' = 0x74746366)
    if (magic == 0x74746366) {
      return _validateTtc(bytes, byteData);
    }

    // 3. 標準 SFNT (TrueType: 0x00010000 または 'true' = 0x74727565, OpenType CFF: 'OTTO' = 0x4F54544F)
    if (magic == 0x00010000 || magic == 0x74727565 || magic == 0x4F54544F) {
      final validationError = _validateSfntDirectory(bytes, 0);
      if (validationError != null) {
        return FontValidationResult.failure(validationError);
      }
      final format = magic == 0x4F54544F ? 'OpenType (CFF)' : 'TrueType';
      return FontValidationResult.success(
        normalizedBytes: bytes,
        formatDescription: format,
      );
    }

    return const FontValidationResult.failure('未対応または破損したフォントシグネチャです (TTF/OTF/TTC/WOFF のみ対応)');
  }

  /// SFNT テーブルディレクトリの境界と必須テーブルの検証
  static String? _validateSfntDirectory(Uint8List bytes, int offset) {
    if (offset + 12 > bytes.length) {
      return 'テーブルヘッダが切り詰められています';
    }

    final data = ByteData.sublistView(bytes, offset);
    final numTables = data.getUint16(4, Endian.big);

    if (numTables < 1 || numTables > 100) {
      return 'テーブル数 ($numTables) が異常です（破損ファイルの可能性があります）';
    }

    final headerSize = 12 + numTables * 16;
    if (offset + headerSize > bytes.length) {
      return 'テーブルディレクトリがファイルサイズを超過しています';
    }

    final tableTags = <String>{};
    int? headTableOffset;
    int? headTableLength;

    for (int i = 0; i < numTables; i++) {
      final recOffset = 12 + i * 16;
      final tagChars = [
        data.getUint8(recOffset),
        data.getUint8(recOffset + 1),
        data.getUint8(recOffset + 2),
        data.getUint8(recOffset + 3),
      ];
      final tag = String.fromCharCodes(tagChars);
      final tableOffset = data.getUint32(recOffset + 8, Endian.big);
      final tableLength = data.getUint32(recOffset + 12, Endian.big);

      // 領域外参照・オーバーフローの防止 (OOB Read 防御)
      if (tableOffset > bytes.length ||
          tableLength > bytes.length ||
          tableOffset + tableLength > bytes.length) {
        return 'テーブル $tag のポインタ (offset: $tableOffset, length: $tableLength) が領域外を参照しています';
      }

      tableTags.add(tag);
      if (tag == 'head') {
        headTableOffset = tableOffset;
        headTableLength = tableLength;
      }
    }

    // 必須テーブル存在チェック (OpenType 仕様で必須とされる基本テーブル)
    const requiredTables = {'cmap', 'head', 'hhea', 'maxp'};
    for (final req in requiredTables) {
      if (!tableTags.contains(req)) {
        return '必須テーブル $req が見つかりません';
      }
    }

    // グリフ表現テーブルの存在チェック
    const glyphTables = {'glyf', 'CFF ', 'CFF2', 'EBDT', 'CBDT', 'SVG '};
    if (!tableTags.any(glyphTables.contains)) {
      return 'グリフアウトラインまたはビットマップテーブルが見つかりません';
    }

    // 'head' テーブルの整合性 (magicNumber == 0x5F0F3CF5)
    if (headTableOffset != null && headTableLength != null) {
      if (headTableLength < 54) {
        return 'head テーブルのサイズ ($headTableLength) が不足しています';
      }
      final headData = ByteData.sublistView(bytes, headTableOffset);
      final magicNumber = headData.getUint32(12, Endian.big);
      if (magicNumber != 0x5F0F3CF5) {
        return 'head テーブルの magicNumber (0x${magicNumber.toRadixString(16)}) が不正です';
      }
    }

    return null;
  }

  /// TrueType Collection (.ttc) の検証
  static FontValidationResult _validateTtc(Uint8List bytes, ByteData data) {
    if (bytes.length < 16) {
      return const FontValidationResult.failure('TTC ヘッダが短すぎます');
    }

    final numFonts = data.getUint32(8, Endian.big);
    if (numFonts < 1 || numFonts > 50) {
      return FontValidationResult.failure('TTC 内フォント数 ($numFonts) が異常です');
    }

    if (12 + numFonts * 4 > bytes.length) {
      return const FontValidationResult.failure('TTC オフセットテーブルが超過しています');
    }

    // 先頭フォントディレクトリを検証
    final firstOffset = data.getUint32(12, Endian.big);
    if (firstOffset + 12 > bytes.length) {
      return const FontValidationResult.failure('TTC 先頭フォントのオフセットが領域外です');
    }

    final sfntError = _validateSfntDirectory(bytes, firstOffset);
    if (sfntError != null) {
      return FontValidationResult.failure('TTC 内フォント検証失敗: $sfntError');
    }

    return FontValidationResult.success(
      normalizedBytes: bytes,
      formatDescription: 'TrueType Collection (TTC)',
    );
  }

  /// WOFF 1.0 の展開・SFNT 再構築と検証
  static FontValidationResult _unpackAndValidateWoff1(Uint8List bytes, ByteData data) {
    if (bytes.length < 44) {
      return const FontValidationResult.failure('WOFF ヘッダが短すぎます');
    }

    final flavor = data.getUint32(4, Endian.big);
    final totalLength = data.getUint32(8, Endian.big);
    final numTables = data.getUint16(12, Endian.big);
    final totalSfntSize = data.getUint32(16, Endian.big);

    if (totalLength > bytes.length) {
      return const FontValidationResult.failure('WOFF ファイルサイズが宣言値より短いです');
    }

    if (numTables < 1 || numTables > 100) {
      return FontValidationResult.failure('WOFF テーブル数 ($numTables) が異常です');
    }

    if (totalSfntSize > maxExpandedSize) {
      return const FontValidationResult.failure('展開後サイズが制限 (30MB) を超過しています (圧縮爆弾防御)');
    }

    final dirEnd = 44 + numTables * 20;
    if (dirEnd > bytes.length) {
      return const FontValidationResult.failure('WOFF テーブルディレクトリが超過しています');
    }

    // SFNT ヘッダ構築準備
    // searchRange = (2^floor(log2(numTables))) * 16
    int maxPowerOf2 = 1;
    while ((maxPowerOf2 << 1) <= numTables) {
      maxPowerOf2 <<= 1;
    }
    final searchRange = maxPowerOf2 * 16;
    final entrySelector = (maxPowerOf2.bitLength - 1);
    final rangeShift = numTables * 16 - searchRange;

    final sfntBuilder = BytesBuilder(copy: false);

    // 12 バイト SFNT ヘッダ
    final sfntHeader = ByteData(12);
    sfntHeader.setUint32(0, flavor, Endian.big);
    sfntHeader.setUint16(4, numTables, Endian.big);
    sfntHeader.setUint16(6, searchRange, Endian.big);
    sfntHeader.setUint16(8, entrySelector, Endian.big);
    sfntHeader.setUint16(10, rangeShift, Endian.big);
    sfntBuilder.add(sfntHeader.buffer.asUint8List());

    // 各テーブルの展開と配置計算
    // SFNT ディレクトリのサイズ: 12 + numTables * 16
    int currentOffset = 12 + numTables * 16;
    final tableDataBlocks = <Uint8List>[];
    final sfntDirEntries = ByteData(numTables * 16);

    for (int i = 0; i < numTables; i++) {
      final entryOffset = 44 + i * 20;
      final tagBytes = bytes.sublist(entryOffset, entryOffset + 4);
      final tableOffset = data.getUint32(entryOffset + 4, Endian.big);
      final compLength = data.getUint32(entryOffset + 8, Endian.big);
      final origLength = data.getUint32(entryOffset + 12, Endian.big);
      final origChecksum = data.getUint32(entryOffset + 16, Endian.big);

      if (tableOffset + compLength > bytes.length) {
        return const FontValidationResult.failure('WOFF テーブルデータが領域外を参照しています');
      }

      Uint8List tableData;
      if (compLength < origLength) {
        // zlib 圧縮されているため展開
        final compressed = bytes.sublist(tableOffset, tableOffset + compLength);
        try {
          tableData = Uint8List.fromList(zlib.decode(compressed));
        } catch (e) {
          return FontValidationResult.failure('WOFF テーブル展開エラー: $e');
        }
        if (tableData.length != origLength) {
          return const FontValidationResult.failure('WOFF 展開サイズが宣言値と一致しません');
        }
      } else {
        tableData = bytes.sublist(tableOffset, tableOffset + origLength);
      }

      // 4バイト境界アライメント用パディング
      final padding = (4 - (origLength % 4)) % 4;
      if (padding > 0) {
        final padded = Uint8List(origLength + padding);
        padded.setRange(0, origLength, tableData);
        tableDataBlocks.add(padded);
      } else {
        tableDataBlocks.add(tableData);
      }

      // SFNT ディレクトリエントリ書き込み
      final dirIdx = i * 16;
      sfntDirEntries.buffer.asUint8List().setRange(dirIdx, dirIdx + 4, tagBytes);
      sfntDirEntries.setUint32(dirIdx + 4, origChecksum, Endian.big);
      sfntDirEntries.setUint32(dirIdx + 8, currentOffset, Endian.big);
      sfntDirEntries.setUint32(dirIdx + 12, origLength, Endian.big);

      currentOffset += tableDataBlocks.last.length;
    }

    sfntBuilder.add(sfntDirEntries.buffer.asUint8List());
    for (final block in tableDataBlocks) {
      sfntBuilder.add(block);
    }

    final sfntBytes = sfntBuilder.toBytes();

    // 展開・再構築された SFNT を再度完全検証
    final sfntError = _validateSfntDirectory(sfntBytes, 0);
    if (sfntError != null) {
      return FontValidationResult.failure('WOFF 展開後の SFNT 検証失敗: $sfntError');
    }

    return FontValidationResult.success(
      normalizedBytes: sfntBytes,
      formatDescription: 'Web Open Font Format (WOFF 1.0)',
    );
  }
}

