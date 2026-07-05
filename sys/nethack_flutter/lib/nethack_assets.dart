import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetHackAssets {
  static const String _verKey = "verDat";
  static const String _dataDirKey = "datadir";

  /// アセットの展開を行い、展開先の File パス（ディレクトリ）を返す。
  static Future<Directory> initialize() async {
    final docDir = await getApplicationSupportDirectory();
    // NetHackのデータフォルダ名
    final dstDir = Directory('${docDir.path}/nethackdir');
    if (!await dstDir.exists()) {
      await dstDir.create(recursive: true);
    }

    // 1. アセット側のバージョンを取得 (assets/ver)
    String assetVerStr = "0";
    try {
      assetVerStr = await rootBundle.loadString('assets/ver');
      assetVerStr = assetVerStr.trim();
    } catch (e) {
      debugPrint("Warning: Could not read assets/ver: $e");
    }
    final int assetVer = int.tryParse(assetVerStr) ?? 0;

    // 2. 展開済みのバージョンを取得
    final prefs = await SharedPreferences.getInstance();
    final int deployedVer = prefs.getInt(_verKey) ?? -1;

    debugPrint("NetHackAssets: Asset version = $assetVer, Deployed version = $deployedVer");

    // 3. バージョンチェックとアセットコピーの実行
    if (deployedVer < assetVer) {
      debugPrint("NetHackAssets: Copying assets to ${dstDir.path}...");
      await _copyAssets(dstDir, deployedVer != -1);
      
      // バージョンと展開先パスを保存
      await prefs.setInt(_verKey, assetVer);
      await prefs.setString(_dataDirKey, dstDir.path);
      debugPrint("NetHackAssets: Copying completed.");
    } else {
      debugPrint("NetHackAssets: Assets are up to date.");
    }

    return dstDir;
  }

  static Future<void> _copyAssets(Directory dstDir, bool isUpgrade) async {
    // AssetManifest をロードして nethackdir 配下のアセットを列挙
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final nethackAssets = assets.where((key) => key.startsWith('assets/nethackdir/')).toList();

    for (final assetKey in nethackAssets) {
      // 展開先のファイルパスを生成
      final relativePath = assetKey.replaceFirst('assets/nethackdir/', '');
      final dstFile = File('${dstDir.path}/$relativePath');

      // defaults.nh の特別処理
      if (relativePath == 'defaults.nh' && await dstFile.exists()) {
        if (isUpgrade) {
          // アップグレード時は既存の defaults.nh をバックアップ
          final bakFile = File('${dstFile.path}.bak');
          if (await bakFile.exists()) {
            await bakFile.delete();
          }
          await dstFile.rename(bakFile.path);
          debugPrint("NetHackAssets: Backed up existing defaults.nh to defaults.nh.bak");
        } else {
          // 初回起動時（何らかの理由でファイルだけ残っていた場合等）は上書きせずスキップ
          continue;
        }
      }

      // ディレクトリの自動作成
      final parentDir = dstFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // バイナリデータとしてコピー
      final byteData = await rootBundle.load(assetKey);
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await dstFile.writeAsBytes(bytes, flush: true);
    }
  }
}
