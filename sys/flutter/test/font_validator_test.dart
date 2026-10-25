import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/services/font_validator.dart';

/// テスト用の有効な最小 SFNT (TrueType) バイト列を構築するヘルパー
Uint8List createDummySfnt({
  int magic = 0x00010000,
  bool includeRequiredTables = true,
  bool includeGlyphTable = true,
  int headMagic = 0x5F0F3CF5,
  int headSize = 54,
  int? corruptTableOffset,
  int? corruptTableLength,
  int? overrideNumTables,
}) {
  final tables = <String, Uint8List>{};

  if (includeRequiredTables) {
    // head テーブル (最低54バイト、オフセット12に 0x5F0F3CF5)
    final headBytes = Uint8List(headSize);
    final headData = ByteData.sublistView(headBytes);
    if (headSize >= 16) {
      headData.setUint32(12, headMagic, Endian.big);
    }
    tables['head'] = headBytes;

    // cmap, hhea, maxp テーブル (任意のダミーデータ)
    tables['cmap'] = Uint8List(16);
    tables['hhea'] = Uint8List(36);
    tables['maxp'] = Uint8List(32);
  }

  if (includeGlyphTable) {
    tables['glyf'] = Uint8List(16);
  }

  final numTables = overrideNumTables ?? tables.length;
  final headerSize = 12 + numTables * 16;

  // 各テーブルの配置オフセットを計算
  var currentOffset = headerSize;
  final tableOffsets = <String, int>{};
  for (final entry in tables.entries) {
    // 4バイト境界アライメント
    final pad = (4 - (entry.value.length % 4)) % 4;
    tableOffsets[entry.key] = currentOffset;
    currentOffset += entry.value.length + pad;
  }

  // 全体サイズが 128 バイト以上になるように調整
  final totalSize = currentOffset < 128 ? 128 : currentOffset;
  final result = Uint8List(totalSize);
  final data = ByteData.sublistView(result);

  // SFNT ヘッダ
  data.setUint32(0, magic, Endian.big);
  data.setUint16(4, numTables, Endian.big);

  int tableIndex = 0;
  for (final entry in tables.entries) {
    if (tableIndex >= numTables) break;
    final recOffset = 12 + tableIndex * 16;
    final tagChars = entry.key.codeUnits;
    for (int j = 0; j < 4; j++) {
      data.setUint8(recOffset + j, tagChars[j]);
    }
    data.setUint32(recOffset + 4, 0, Endian.big); // checksum

    final offset = (corruptTableOffset != null && entry.key == 'head')
        ? corruptTableOffset
        : tableOffsets[entry.key]!;
    final length = (corruptTableLength != null && entry.key == 'head')
        ? corruptTableLength
        : entry.value.length;

    data.setUint32(recOffset + 8, offset, Endian.big);
    data.setUint32(recOffset + 12, length, Endian.big);

    // テーブル実データをコピー
    if (offset + entry.value.length <= totalSize) {
      result.setRange(offset, offset + entry.value.length, entry.value);
    }
    tableIndex++;
  }

  return result;
}

/// テスト用の WOFF 1.0 バイト列を構築するヘルパー
Uint8List createDummyWoff1({
  bool compress = false,
  bool corruptCompressedData = false,
}) {
  // SFNT を元に WOFF を生成
  final sfnt = createDummySfnt();
  final sfntData = ByteData.sublistView(sfnt);
  final numTables = sfntData.getUint16(4, Endian.big);

  final woffDirSize = 44 + numTables * 20;
  final tableDataList = <Uint8List>[];
  final woffEntries = <Map<String, dynamic>>[];

  int currentWoffOffset = woffDirSize;
  for (int i = 0; i < numTables; i++) {
    final sfntEntryOffset = 12 + i * 16;
    final tag = String.fromCharCodes(sfnt.sublist(sfntEntryOffset, sfntEntryOffset + 4));
    final offset = sfntData.getUint32(sfntEntryOffset + 8, Endian.big);
    final length = sfntData.getUint32(sfntEntryOffset + 12, Endian.big);
    final rawData = sfnt.sublist(offset, offset + length);

    Uint8List storedData;
    if (compress) {
      storedData = Uint8List.fromList(zlib.encode(rawData));
      if (corruptCompressedData) {
        // 圧縮データを壊す
        storedData = Uint8List.fromList([0, 1, 2, 3]);
      }
    } else {
      storedData = rawData;
    }

    final pad = (4 - (storedData.length % 4)) % 4;
    final paddedData = Uint8List(storedData.length + pad);
    paddedData.setRange(0, storedData.length, storedData);
    tableDataList.add(paddedData);

    woffEntries.add({
      'tag': tag,
      'offset': currentWoffOffset,
      'compLength': storedData.length,
      'origLength': rawData.length,
      'checksum': 0,
    });
    currentWoffOffset += paddedData.length;
  }

  final totalSize = currentWoffOffset < 128 ? 128 : currentWoffOffset;
  final result = Uint8List(totalSize);
  final woffData = ByteData.sublistView(result);

  // WOFF ヘッダ
  woffData.setUint32(0, 0x774F4646, Endian.big); // 'wOFF'
  woffData.setUint32(4, 0x00010000, Endian.big); // flavor (TrueType)
  woffData.setUint32(8, totalSize, Endian.big);
  woffData.setUint16(12, numTables, Endian.big);
  woffData.setUint16(14, 0, Endian.big); // reserved
  woffData.setUint32(16, sfnt.length, Endian.big); // totalSfntSize

  for (int i = 0; i < numTables; i++) {
    final entry = woffEntries[i];
    final entryOffset = 44 + i * 20;
    final tagBytes = (entry['tag'] as String).codeUnits;
    for (int j = 0; j < 4; j++) {
      woffData.setUint8(entryOffset + j, tagBytes[j]);
    }
    woffData.setUint32(entryOffset + 4, entry['offset'] as int, Endian.big);
    woffData.setUint32(entryOffset + 8, entry['compLength'] as int, Endian.big);
    woffData.setUint32(entryOffset + 12, entry['origLength'] as int, Endian.big);
    woffData.setUint32(entryOffset + 16, entry['checksum'] as int, Endian.big);

    final dataBlock = tableDataList[i];
    result.setRange(
      entry['offset'] as int,
      (entry['offset'] as int) + dataBlock.length,
      dataBlock,
    );
  }

  return result;
}

void main() {
  group('FontValidator 拡張子テスト', () {
    test('有効な拡張子を認識する', () {
      expect(FontValidator.hasSupportedExtension('font.ttf'), isTrue);
      expect(FontValidator.hasSupportedExtension('FONT.OTF'), isTrue);
      expect(FontValidator.hasSupportedExtension('my_font.ttc'), isTrue);
      expect(FontValidator.hasSupportedExtension('webfont.woff'), isTrue);
    });

    test('無効な拡張子を拒絶する', () {
      expect(FontValidator.hasSupportedExtension('font.exe'), isFalse);
      expect(FontValidator.hasSupportedExtension('font.png'), isFalse);
      expect(FontValidator.hasSupportedExtension('font.woff2'), isFalse);
      expect(FontValidator.hasSupportedExtension('font'), isFalse);
    });
  });

  group('FontValidator SFNT 正常系検証', () {
    test('有効な TrueType (0x00010000) を検証・受理する', () {
      final bytes = createDummySfnt(magic: 0x00010000);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.formatDescription, 'TrueType');
      expect(result.normalizedBytes, isNotNull);
      expect(result.normalizedBytes!.length, bytes.length);
    });

    test('有効な OpenType CFF (OTTO = 0x4F54544F) を検証・受理する', () {
      final bytes = createDummySfnt(magic: 0x4F54544F);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isTrue);
      expect(result.formatDescription, 'OpenType (CFF)');
    });
  });

  group('FontValidator WOFF 1.0 検証', () {
    test('非圧縮 WOFF 1.0 を正しく SFNT に再構築・受理する', () {
      final bytes = createDummyWoff1(compress: false);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isTrue);
      expect(result.formatDescription, 'Web Open Font Format (WOFF 1.0)');
      expect(result.normalizedBytes, isNotNull);

      // 再構築されたバイナリが有効な SFNT であることを確認
      final sfntResult = FontValidator.validateAndNormalize(result.normalizedBytes!);
      expect(sfntResult.isValid, isTrue);
    });

    test('zlib 圧縮 WOFF 1.0 を正しく展開して SFNT に再構築・受理する', () {
      final bytes = createDummyWoff1(compress: true);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isTrue);
      expect(result.formatDescription, 'Web Open Font Format (WOFF 1.0)');
      expect(result.normalizedBytes, isNotNull);

      final sfntResult = FontValidator.validateAndNormalize(result.normalizedBytes!);
      expect(sfntResult.isValid, isTrue);
    });

    test('破損した zlib 圧縮データを拒絶する', () {
      final bytes = createDummyWoff1(compress: true, corruptCompressedData: true);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('WOFF テーブル展開エラー'));
    });
  });

  group('FontValidator TTC 検証', () {
    test('有効な TTC (ttcf) を検証・受理する', () {
      // TTC ヘッダ長は 12 + 4 = 16 バイト
      const ttcHeaderSize = 16;
      final sfnt = createDummySfnt();

      // SFNT 内のテーブルオフセットを TTC 先頭からの絶対オフセットに +16 補正
      final shiftedSfnt = Uint8List.fromList(sfnt);
      final sfntData = ByteData.sublistView(shiftedSfnt);
      final numTables = sfntData.getUint16(4, Endian.big);
      for (int i = 0; i < numTables; i++) {
        final recOffset = 12 + i * 16;
        final origOffset = sfntData.getUint32(recOffset + 8, Endian.big);
        sfntData.setUint32(recOffset + 8, origOffset + ttcHeaderSize, Endian.big);
      }

      final ttcSize = ttcHeaderSize + shiftedSfnt.length;
      final ttc = Uint8List(ttcSize < 128 ? 128 : ttcSize);
      final data = ByteData.sublistView(ttc);

      data.setUint32(0, 0x74746366, Endian.big); // 'ttcf'
      data.setUint32(4, 0x00010000, Endian.big); // version 1.0
      data.setUint32(8, 1, Endian.big); // numFonts = 1
      data.setUint32(12, ttcHeaderSize, Endian.big); // OffsetTable[0] = 16

      ttc.setRange(ttcHeaderSize, ttcHeaderSize + shiftedSfnt.length, shiftedSfnt);

      final result = FontValidator.validateAndNormalize(ttc);
      expect(result.isValid, isTrue, reason: result.errorMessage);
      expect(result.formatDescription, contains('TrueType Collection'));
    });
  });

  group('FontValidator 異常系・セキュリティ境界防御', () {
    test('128バイト未満の小さすぎるバイナリを拒絶する', () {
      final tinyBytes = Uint8List(64);
      final result = FontValidator.validateAndNormalize(tinyBytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('小さすぎます'));
    });

    test('不正なマジックナンバー（例: 実行ファイルや画像）を拒絶する', () {
      final fakeBytes = Uint8List(256);
      fakeBytes[0] = 0x4D; // 'MZ'
      fakeBytes[1] = 0x5A;
      final result = FontValidator.validateAndNormalize(fakeBytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('未対応または破損したフォントシグネチャ'));
    });

    test('SFNT テーブル数が異常（0 または 100 超）なファイルを拒絶する', () {
      final bytes = createDummySfnt(overrideNumTables: 0);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('テーブル数'));
    });

    test('OOB Read 攻撃: テーブルオフセットがファイルサイズ外を参照している場合を検知・拒絶する', () {
      final bytes = createDummySfnt(corruptTableOffset: 999999);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('領域外を参照しています'));
    });

    test('必須テーブル（cmap, head, hhea, maxp）欠損を検知・拒絶する', () {
      final bytes = createDummySfnt(includeRequiredTables: false);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('必須テーブル'));
    });

    test('グリフアウトラインテーブル欠損を検知・拒絶する', () {
      final bytes = createDummySfnt(includeGlyphTable: false);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('グリフアウトライン'));
    });

    test('head テーブルの magicNumber が不正なファイルを検知・拒絶する', () {
      final bytes = createDummySfnt(headMagic: 0x12345678);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('magicNumber'));
    });

    test('head テーブルが短すぎる（< 54バイト）場合を検知・拒絶する', () {
      final bytes = createDummySfnt(headSize: 32);
      final result = FontValidator.validateAndNormalize(bytes);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('head テーブルのサイズ'));
    });
  });
}
