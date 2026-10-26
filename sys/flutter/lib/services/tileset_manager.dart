import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tileset_info.dart';
import '../utils/app_prefs.dart';
import 'tileset_validator.dart';

/// タイルセットの管理（内蔵タイルセットとカスタムタイルセットの統合・永続化・セルサイズ算出）を司るマネージャークラス
class TilesetManager extends ChangeNotifier {
  static TilesetManager? _instance;

  /// シングルトンインスタンス取得
  static TilesetManager get instance => _instance ??= TilesetManager._();

  // Prefs キー名
  static const String prefSelectedTileset = 'selected_tileset';
  static const String prefCustomTilesetsJson = 'custom_tilesets_json';

  /// デフォルトタイルセットID
  static const String defaultTilesetId = 'pixelhack_32x32';

  /// 外部インポートされたタイルセット一覧
  final List<TilesetInfo> _customTilesets = [];

  /// カスタムタイルセットの保存先ディレクトリ
  Directory? _customTilesDir;

  bool _initialized = false;

  TilesetManager._();

  /// 利用可能なすべてのタイルセット一覧（内蔵 + カスタム）
  List<TilesetInfo> get allTilesets => [
        ...TilesetInfo.allTilesets,
        ..._customTilesets,
      ];

  /// カスタムタイルセットのみの一覧
  List<TilesetInfo> get customTilesets => List.unmodifiable(_customTilesets);

  /// 初期化処理（Prefsからのカスタムタイルセット読み込みと実体ファイル検証）
  Future<void> init() async {
    if (_initialized) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _customTilesDir = Directory('${appDocDir.path}/custom_tiles');
      if (!await _customTilesDir!.exists()) {
        await _customTilesDir!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[TilesetManager] ディレクトリ初期化スキップ（テスト環境等）: $e');
    }

    await _loadCustomTilesetsFromPrefs();
    _initialized = true;
    notifyListeners();
  }

  /// SharedPreferences から保存されたカスタムタイルセットを読み込む
  Future<void> _loadCustomTilesetsFromPrefs() async {
    try {
      final prefs = await AppPrefs.getInstance();
      final jsonStr = prefs.getString(prefCustomTilesetsJson);
      if (jsonStr == null || jsonStr.isEmpty) return;

      final list = jsonDecode(jsonStr) as List<dynamic>;
      _customTilesets.clear();
      bool needsResave = false;

      for (final item in list) {
        try {
          final map = item as Map<String, dynamic>;
          var info = TilesetInfo.fromJson(map);
          // 実ファイルが存在するか検証（存在しない孤立レコードはスキップ）
          if (info.localFilePath != null) {
            final file = File(info.localFilePath!);
            if (await file.exists()) {
              // 既存データで透過情報が未保持の場合、画像から自動判定して補完
              if (!map.containsKey('isTransparent')) {
                try {
                  final bytes = await file.readAsBytes();
                  final valResult = await TilesetValidator.validate(bytes, fileName: file.path);
                  final isTrans = valResult.isValid
                      ? valResult.isTransparent
                      : await TilesetValidator.detectTransparency(
                          bytes,
                          tileWidth: info.tileWidth,
                          tileHeight: info.tileHeight,
                          rows: 60,
                        );
                  info = TilesetInfo(
                    id: info.id,
                    displayName: info.displayName,
                    tileWidth: info.tileWidth,
                    tileHeight: info.tileHeight,
                    author: info.author,
                    url: info.url,
                    assetPath: info.assetPath,
                    isBuiltIn: info.isBuiltIn,
                    localFilePath: info.localFilePath,
                    isTransparent: isTrans,
                  );
                  needsResave = true;
                } catch (e) {
                  debugPrint('[TilesetManager] 既存タイルの透過マイグレーションスキップ: $e');
                }
              }
              _customTilesets.add(info);
            }
          }
        } catch (e) {
          debugPrint('[TilesetManager] タイルセットメタデータ復元エラー: $e');
        }
      }

      if (needsResave) {
        await _saveCustomTilesetsToPrefs();
      }
    } catch (e) {
      debugPrint('[TilesetManager] カスタムタイルセット読み込みエラー: $e');
    }
  }

  /// SharedPreferences へカスタムタイルセット一覧を永続保存
  Future<void> _saveCustomTilesetsToPrefs() async {
    try {
      final prefs = await AppPrefs.getInstance();
      final list = _customTilesets.map((t) => t.toJson()).toList();
      await prefs.setString(prefCustomTilesetsJson, jsonEncode(list));
    } catch (e) {
      debugPrint('[TilesetManager] カスタムタイルセット永続化エラー: $e');
    }
  }

  /// ID から TilesetInfo を検索（内蔵・カスタム両方から探索）
  TilesetInfo getTilesetById(String id) {
    return allTilesets.firstWhere(
      (t) => t.id == id,
      orElse: () => TilesetInfo.findById(id),
    );
  }

  /// 外部タイルセット画像を検証・インポートして永続保存
  Future<TilesetValidationResult> importCustomTileset(
    Uint8List rawBytes,
    String originalFileName,
  ) async {
    final validation = await TilesetValidator.validate(
      rawBytes,
      fileName: originalFileName,
    );

    if (!validation.isValid) {
      return validation;
    }

    if (_customTilesDir == null) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        _customTilesDir = Directory('${appDocDir.path}/custom_tiles');
        if (!await _customTilesDir!.exists()) {
          await _customTilesDir!.create(recursive: true);
        }
      } catch (e) {
        return TilesetValidationResult.failure('タイルセット保存先ディレクトリを作成できませんでした: $e');
      }
    }

    // 拡張子の取得とサニタイズ
    String ext = '.png';
    final lower = originalFileName.toLowerCase();
    if (lower.endsWith('.webp')) {
      ext = '.webp';
    } else if (lower.endsWith('.bmp')) {
      ext = '.bmp';
    }

    final nameWithoutExt = originalFileName.contains('.')
        ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
        : originalFileName;

    final sanitizedBase = nameWithoutExt
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileId = 'custom_${timestamp}_$sanitizedBase';
    final targetFileName = '$fileId$ext';
    final targetFile = File('${_customTilesDir!.path}/$targetFileName');

    try {
      await targetFile.writeAsBytes(rawBytes);
    } catch (e) {
      return TilesetValidationResult.failure('ファイルの書き込みに失敗しました: $e');
    }

    final tileW = validation.tileWidth!;
    final tileH = validation.tileHeight!;
    final aspectStr = tileW != tileH ? ' (比率 $tileW:$tileH)' : '';

    final newTileset = TilesetInfo(
      id: fileId,
      displayName: '$sanitizedBase (${tileW}x$tileH)$aspectStr',
      tileWidth: tileW,
      tileHeight: tileH,
      author: 'User Imported',
      url: targetFile.path,
      assetPath: '',
      isBuiltIn: false,
      localFilePath: targetFile.path,
      isTransparent: validation.isTransparent,
    );

    _customTilesets.add(newTileset);
    await _saveCustomTilesetsToPrefs();
    notifyListeners();

    return validation;
  }

  /// 外部インポートされたタイルセットを削除
  Future<bool> deleteCustomTileset(String tilesetId) async {
    final index = _customTilesets.indexWhere((t) => t.id == tilesetId);
    if (index < 0) return false;

    final item = _customTilesets[index];
    if (item.localFilePath != null) {
      try {
        final file = File(item.localFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[TilesetManager] ファイル削除エラー: $e');
      }
    }

    _customTilesets.removeAt(index);
    await _saveCustomTilesetsToPrefs();

    // 削除されたタイルセットが現在選択中の場合、デフォルトへ戻す
    final prefs = await AppPrefs.getInstance();
    final currentSelected = prefs.getString(prefSelectedTileset);
    if (currentSelected == tilesetId) {
      await prefs.setString(prefSelectedTileset, defaultTilesetId);
    }

    notifyListeners();
    return true;
  }

  /// タイルモード時のマップセルサイズを一元計算
  ///
  /// タイルセットの縦横比（tileWidth / tileHeight）に基づき、
  /// 基準高さ（デフォルト 32.0）に対する cellW を動的に決定します。
  Size getMapCellSize({
    required String tilesetId,
    double baseHeight = 32.0,
  }) {
    final tileset = getTilesetById(tilesetId);
    final ratio = tileset.aspectRatio;
    final cellH = baseHeight;
    final cellW = (baseHeight * ratio);
    return Size(cellW, cellH);
  }
}
