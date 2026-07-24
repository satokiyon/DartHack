import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetHackAssets {
  static const String _verKey = "verDat";
  static const String _dataDirKey = "datadir";
  static const String _buildIdKey = "cCoreBuildId";

  /// 今回の起動で Cコア/アセットの更新が発生したか
  static bool wasUpdated = false;
  static String updatedBuildId = "";

  /// アセットの展開を行い、展開先の File パス（ディレクトリ）を返す。
  static Future<Directory> initialize({String? currentBuildId}) async {
    final docDir = await getApplicationSupportDirectory();
    // NetHackのデータフォルダ名
    final dstDir = Directory('${docDir.path}/nethackdir');
    if (!await dstDir.exists()) {
      await dstDir.create(recursive: true);
    }

    // セーブ用ディレクトリの作成
    final saveDir = Directory('${dstDir.path}/save');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
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

    // 2. 展開済みのバージョンおよびビルドIDを取得
    final prefs = await SharedPreferences.getInstance();
    final int deployedVer = prefs.getInt(_verKey) ?? -1;
    final String deployedBuildId = prefs.getString(_buildIdKey) ?? "";

    final String buildIdToUse = currentBuildId ?? "unknown";

    debugPrint("NetHackAssets: Asset ver = $assetVer (Deployed: $deployedVer), Build ID = $buildIdToUse (Deployed: $deployedBuildId)");

    // 3. バージョンまたは Cコア Build ID の変更チェック
    final bool isVersionUpdated = deployedVer < assetVer;
    final bool isBuildIdUpdated = buildIdToUse != "unknown" && buildIdToUse != deployedBuildId;
    final bool isCoreUpdated = isVersionUpdated || isBuildIdUpdated;

    if (isCoreUpdated) {
      wasUpdated = true;
      updatedBuildId = buildIdToUse;
      debugPrint("NetHackAssets: Updating core assets in ${dstDir.path}...");

      // セーブデータの安全保護/確認
      await _checkAndBackupSaveFiles(saveDir, isUpgrade: deployedVer != -1 || deployedBuildId.isNotEmpty);

      // アセットファイルのコピー・置換
      await _copyAssets(dstDir, deployedVer != -1);
      
      // バージョンと展開先パス・ビルドIDを保存
      await prefs.setInt(_verKey, assetVer);
      await prefs.setString(_dataDirKey, dstDir.path);
      if (buildIdToUse != "unknown") {
        await prefs.setString(_buildIdKey, buildIdToUse);
      }
      debugPrint("NetHackAssets: Core & asset update completed.");
    } else {
      wasUpdated = false;
      debugPrint("NetHackAssets: Assets are up to date.");
    }

    return dstDir;
  }

  static Future<void> _copyAssets(Directory dstDir, bool isUpgrade) async {
    // AssetManifest をロードして nethackdir 配下のアセットを列挙
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final nethackAssets = assets.where((key) => key.startsWith('assets/nethackdir/')).toList();
    debugPrint("NetHackAssets: Found ${nethackAssets.length} assets in nethackdir.");
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

  /// Cコア更新時にセーブデータの保護とバックアップを行う
  static Future<void> _checkAndBackupSaveFiles(Directory saveDir, {required bool isUpgrade}) async {
    if (!await saveDir.exists()) return;
    try {
      final entries = await saveDir.list().toList();
      final saveFiles = entries.whereType<File>().where((f) {
        final name = f.path.split(Platform.pathSeparator).last;
        return name.endsWith('.sav') || name.endsWith('.0') || name.contains('save');
      }).toList();

      if (saveFiles.isNotEmpty && isUpgrade) {
        final backupDir = Directory('${saveDir.parent.path}/save_bak_${DateTime.now().millisecondsSinceEpoch}');
        await backupDir.create(recursive: true);
        debugPrint("NetHackAssets: Backing up ${saveFiles.length} save files to ${backupDir.path}");
        for (final saveFile in saveFiles) {
          final fileName = saveFile.path.split(Platform.pathSeparator).last;
          await saveFile.copy('${backupDir.path}/$fileName');
        }
      }
    } catch (e) {
      debugPrint("Warning: Exception while checking/backing up save files: $e");
    }
  }
}

