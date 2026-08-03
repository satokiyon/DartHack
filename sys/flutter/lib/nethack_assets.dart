import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/defaults_helper.dart';

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

    // sysconf アセットを端末ストレージへ常に強制上書き更新
    try {
      final syscfData = await rootBundle.load('assets/nethackdir/sysconf');
      final syscfBytes = syscfData.buffer.asUint8List(syscfData.offsetInBytes, syscfData.lengthInBytes);
      final syscfDst = File('${dstDir.path}/sysconf');
      await syscfDst.writeAsBytes(syscfBytes, flush: true);
      debugPrint("NetHackAssets: Always forcibly updated sysconf to ${syscfDst.path}");
    } catch (e) {
      debugPrint("Warning: Could not force update sysconf asset: $e");
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

      // アセットファイルのコピー・置換（ユーザーのスコア・ログ・defaults.nhは保護）
      await _copyAssets(dstDir, deployedVer != -1);
      
      // defaults.nh の安全マージ（ユーザー設定の維持・新項目の補完・廃止項目の削除）
      await _mergeDefaultsFile(dstDir);

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

  static const Set<String> _protectedDataFiles = {
    'record',
    'logfile',
    'xlogfile',
    'history',
    'paniclog',
    'perm',
    'defaults.nh',
  };

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

      // 既存のユーザーデータファイル（スコア、ログ、設定ファイル等）の上書き保護
      if (await dstFile.exists()) {
        if (_protectedDataFiles.contains(relativePath) || relativePath.startsWith('save/')) {
          debugPrint("NetHackAssets: Skipping overwrite for existing file '$relativePath'");
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

  /// アセットの defaults.nh と端末の defaults.nh / SharedPreferences を安全にマージする
  static Future<void> _mergeDefaultsFile(Directory dstDir) async {
    try {
      final targetFile = File('${dstDir.path}/defaults.nh');
      if (await targetFile.exists()) {
        final content = await targetFile.readAsString();
        if (content.contains('OPTIONS=!number_pad')) {
          final fixedContent = content.replaceAll('OPTIONS=!number_pad', 'OPTIONS=number_pad:0');
          await targetFile.writeAsString(fixedContent, flush: true);
          debugPrint("NetHackAssets: Fixed legacy OPTIONS=!number_pad in existing defaults.nh");
        }
      }

      final tmpAssetFile = File('${dstDir.path}/defaults.nh.asset_tmp');
      final byteData = await rootBundle.load('assets/nethackdir/defaults.nh');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await tmpAssetFile.writeAsBytes(bytes, flush: true);

      final defaultsHelper = DefaultsHelper();
      await defaultsHelper.mergeAssetDefaultsWithPrefs(tmpAssetFile.path, targetFile.path);

      if (await tmpAssetFile.exists()) {
        await tmpAssetFile.delete();
      }
      debugPrint("NetHackAssets: Safely merged defaults.nh with user preferences.");
    } catch (e) {
      debugPrint("Warning: Exception during defaults.nh merge: $e");
    }
  }
}


