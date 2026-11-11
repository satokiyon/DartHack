import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'models/topten_entry.dart';
import 'models/xlog_entry.dart';
import 'utils/app_prefs.dart';
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

    // 一時レベルファイル用ディレクトリの作成（クラウドバックアップ対象外へ分離）
    final levelsDir = Directory('${dstDir.path}/levels');
    if (!await levelsDir.exists()) {
      await levelsDir.create(recursive: true);
    }

    // 旧バージョンの各種ユーザーデータ（セーブ、スコアログ、defaults.nh等）を包括的マイグレーション
    await _migrateAllLegacyUserData(dstDir, docDir);

    // 旧バージョンのセーブファイル (uid=1) を現行 UID に安全マイグレーション
    await _migrateLegacySaveFiles(saveDir);

    // 旧バージョン等で nethackdir 直下に残っていた一時レベルファイルを levels/ へ移行整理
    await _migrateLegacyLevelFiles(dstDir, levelsDir);

    // 既存の肥大化した logfile / xlogfile があれば record の有効レコードに合わせてトリム整理
    await _syncLogsWithRecord(dstDir);

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
    final prefs = await AppPrefs.getInstance();
    final int deployedVer = prefs.getInt(_verKey) ?? -1;
    final String deployedBuildId = prefs.getString(_buildIdKey) ?? "";

    final String buildIdToUse = currentBuildId ?? "unknown";

    debugPrint("NetHackAssets: Asset ver = $assetVer (Deployed: $deployedVer), Build ID = $buildIdToUse (Deployed: $deployedBuildId)");

    // 3. バージョンまたは Cコア Build ID の変更、および必須アセットファイルの存在チェック
    final bool isVersionUpdated = deployedVer < assetVer;
    final bool isBuildIdUpdated = buildIdToUse != "unknown" && buildIdToUse != deployedBuildId;
    final bool hasCoreDataFiles = await File('${dstDir.path}/data').exists() &&
        await File('${dstDir.path}/rumors').exists() &&
        await File('${dstDir.path}/defaults.nh').exists();
    final bool isCoreUpdated = isVersionUpdated || isBuildIdUpdated || !hasCoreDataFiles;

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
      if (prefs.getString(_dataDirKey) != dstDir.path) {
        await prefs.setString(_dataDirKey, dstDir.path);
      }
      debugPrint("NetHackAssets: Assets are up to date.");
    }

    return dstDir;
  }

  static const Set<String> _protectedDataFiles = {
    'record',
    'logfile',
    'xlogfile',
    'livelog',
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

  /// defaults.nh が存在しない、空、または過去の処理で短縮破壊された状態（50行未満）かを判定
  static Future<bool> _isDefaultsIncomplete(File file) async {
    if (!await file.exists()) return true;
    try {
      final lines = await file.readAsLines();
      return lines.length < 50;
    } catch (e) {
      return true;
    }
  }

  /// テキストログファイル（record, logfile, xlogfile等）の重複排除結合（マージ）
  static Future<void> _mergeTextLogFiles(File srcFile, File dstFile) async {
    try {
      final srcLines = await srcFile.readAsLines();
      if (srcLines.isEmpty) return;

      if (!await dstFile.exists()) {
        await srcFile.copy(dstFile.path);
        return;
      }

      final dstLines = await dstFile.readAsLines();
      final existingLinesSet = Set<String>.from(dstLines.map((l) => l.trim()));
      final newLinesToAppend = <String>[];

      for (final line in srcLines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !existingLinesSet.contains(trimmed)) {
          newLinesToAppend.add(line);
          existingLinesSet.add(trimmed);
        }
      }

      if (newLinesToAppend.isNotEmpty) {
        final sink = dstFile.openWrite(mode: FileMode.append);
        for (final line in newLinesToAppend) {
          sink.writeln(line);
        }
        await sink.flush();
        await sink.close();
        debugPrint("NetHackAssets: Merged ${newLinesToAppend.length} new log lines from '${srcFile.path}' -> '${dstFile.path}'");
      }
    } catch (e) {
      debugPrint("Warning: Could not merge text log files: $e");
    }
  }

  /// 旧バージョンの各種ユーザーデータ（セーブ、スコアログ、defaults.nh等）を包括的に自動マイグレーション
  static Future<void> _migrateAllLegacyUserData(Directory dstDir, Directory docDir) async {
    final candidateDirs = <Directory>[
      docDir,
      Directory('${docDir.path}/nethack'),
    ];

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      candidateDirs.add(docsDir);
      candidateDirs.add(Directory('${docsDir.path}/NetHack'));
      candidateDirs.add(Directory('${docsDir.path}/nethackdir'));
    } catch (e) {
      debugPrint("Warning: Could not get ApplicationDocumentsDirectory for migration: $e");
    }

    final targetSaveDir = Directory('${dstDir.path}/save');
    if (!await targetSaveDir.exists()) {
      await targetSaveDir.create(recursive: true);
    }

    const logFiles = ['record', 'logfile', 'xlogfile', 'livelog', 'history', 'paniclog'];

    for (final candidateDir in candidateDirs) {
      if (candidateDir.path == dstDir.path) continue;
      if (!await candidateDir.exists()) continue;

      try {
        // 1. スコア・ログファイルのマイグレーション（重複排除マージ）
        for (final logName in logFiles) {
          final legacyLogFile = File('${candidateDir.path}/$logName');
          if (await legacyLogFile.exists()) {
            final targetLogFile = File('${dstDir.path}/$logName');
            await _mergeTextLogFiles(legacyLogFile, targetLogFile);
            try {
              await legacyLogFile.delete();
            } catch (_) {}
          }
        }

        // 2. defaults.nh のマイグレーション
        final legacyDefaults = File('${candidateDir.path}/defaults.nh');
        final targetDefaults = File('${dstDir.path}/defaults.nh');
        if (await legacyDefaults.exists()) {
          if (await _isDefaultsIncomplete(targetDefaults)) {
            final content = await legacyDefaults.readAsString();
            if (content.trim().isNotEmpty) {
              await targetDefaults.writeAsString(content, flush: true);
              debugPrint("NetHackAssets: Migrated legacy defaults.nh from '${legacyDefaults.path}' -> '${targetDefaults.path}'");
            }
          }
          try {
            await legacyDefaults.delete();
          } catch (_) {}
        }

        // 3. perm (永続ロックファイル) のマイグレーション
        final legacyPerm = File('${candidateDir.path}/perm');
        final targetPerm = File('${dstDir.path}/perm');
        if (await legacyPerm.exists()) {
          if (!await targetPerm.exists() || (await targetPerm.length()) < 50) {
            await legacyPerm.copy(targetPerm.path);
            debugPrint("NetHackAssets: Migrated legacy perm lock file -> '${targetPerm.path}'");
          }
          try {
            await legacyPerm.delete();
          } catch (_) {}
        }

        // 4. セーブデータ (save/ ディレクトリ配下) のマイグレーション
        final legacySaveDir = Directory('${candidateDir.path}/save');
        if (await legacySaveDir.exists()) {
          final entries = await legacySaveDir.list().toList();
          for (final entry in entries) {
            if (entry is File) {
              final fileName = entry.path.split(Platform.pathSeparator).last;
              final targetSaveFile = File('${targetSaveDir.path}/$fileName');
              if (!await targetSaveFile.exists()) {
                await entry.copy(targetSaveFile.path);
                debugPrint("NetHackAssets: Migrated legacy save file '$fileName' -> '${targetSaveFile.path}'");
              }
              try {
                await entry.delete();
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint("Warning: Exception while migrating legacy user data from '${candidateDir.path}': $e");
      }
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

      // 端末の defaults.nh が存在しない、または不完全な場合はフルテンプレートで初期化
      final bool incomplete = await _isDefaultsIncomplete(targetFile);

      final tmpAssetFile = File('${dstDir.path}/defaults.nh.asset_tmp');
      final byteData = await rootBundle.load('assets/nethackdir/common/defaults.nh');
      final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      await tmpAssetFile.writeAsBytes(bytes, flush: true);

      if (incomplete) {
        // フルテンプレートをそのままベースとしてコピー
        await tmpAssetFile.copy(targetFile.path);
        debugPrint("NetHackAssets: Initialized/Repaired target defaults.nh with full asset template.");
      }

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

  /// 旧UIDで作成されたセーブデータ関連ファイル（Player, テスト, .0, .sav, .bak等）を現行プロセスの UID へリネーム移行する
  static Future<void> _migrateLegacySaveFiles(Directory saveDir) async {
    if (!await saveDir.exists()) return;
    final currentUid = _getCurrentUid();

    try {
      final entries = await saveDir.list().toList();
      // 先頭が数字列 (\d+) で始まり、その後にプレイヤー名および拡張子 (.0, .sav, .bak 等) が続くファイルを検出
      final regExp = RegExp(r'^(\d+)(.+)$');

      for (final entry in entries) {
        if (entry is File) {
          final fileName = entry.path.split(Platform.pathSeparator).last;
          final match = regExp.firstMatch(fileName);
          if (match != null) {
            final oldUidStr = match.group(1)!;
            final restName = match.group(2)!; // プレイヤー名 + 拡張子 (.0, .sav, .bak 等)

            final int? oldUid = int.tryParse(oldUidStr);
            if (oldUid != null && oldUid != currentUid) {
              final newFileName = '$currentUid$restName';
              final newFile = File('${saveDir.path}/$newFileName');

              if (await newFile.exists()) {
                // リネーム先ファイルが既に存在する場合は日付の新しい方を優先しバックアップを保管
                final newModTime = await newFile.lastModified();
                final oldModTime = await entry.lastModified();
                if (oldModTime.isAfter(newModTime)) {
                  final bakFile = File('${saveDir.path}/$newFileName.bak_${DateTime.now().millisecondsSinceEpoch}');
                  await newFile.copy(bakFile.path);
                  await entry.copy(newFile.path);
                  await entry.delete();
                  debugPrint("NetHackAssets: Updated save file '$fileName' -> '$newFileName' (newer timestamp)");
                } else {
                  final oldBak = File('${entry.path}.old_bak');
                  await entry.rename(oldBak.path);
                  debugPrint("NetHackAssets: Preserved existing '$newFileName', backed up older '$fileName'");
                }
              } else {
                await entry.rename(newFile.path);
                debugPrint("NetHackAssets: Successfully migrated legacy save file '$fileName' -> '$newFileName'");
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Warning: Exception during save file migration: $e");
    }
  }

  @visibleForTesting
  static Future<void> migrateLegacyLevelFilesForTesting(
    Directory dstDir,
    Directory levelsDir, {
    int? currentUidOverride,
  }) =>
      _migrateLegacyLevelFiles(
        dstDir,
        levelsDir,
        currentUidOverride: currentUidOverride,
      );

  /// 旧バージョン等で nethackdir 直下に残っていた一時レベルファイル（`<UID><Name>.<lev>`）を整理する。
  /// 現行のアプリ UID と一致するファイルは進行中ゲーム保護のため levels/ へ移動し、
  /// 別 UID の残骸（再インストール・別端末リストア等の孤立データ）は安全に削除する。
  static Future<void> _migrateLegacyLevelFiles(
    Directory dstDir,
    Directory levelsDir, {
    int? currentUidOverride,
  }) async {
    if (!await dstDir.exists()) return;
    final currentUid = currentUidOverride ?? _getCurrentUid();
    final regExp = RegExp(r'^(\d+).+\.(\d+)$');

    try {
      final entries = await dstDir.list().toList();
      for (final entry in entries) {
        if (entry is! File) continue;
        final fileName = entry.path.split(Platform.pathSeparator).last;
        final match = regExp.firstMatch(fileName);
        if (match == null) continue;

        final int? fileUid = int.tryParse(match.group(1)!);
        if (fileUid == null) continue;

        if (fileUid == currentUid) {
          final targetFile = File('${levelsDir.path}/$fileName');
          if (!await targetFile.exists()) {
            await entry.rename(targetFile.path);
            debugPrint("NetHackAssets: Migrated active level file '$fileName' -> 'levels/$fileName'");
          } else {
            final targetMod = await targetFile.lastModified();
            final srcMod = await entry.lastModified();
            if (srcMod.isAfter(targetMod)) {
              await entry.copy(targetFile.path);
            }
            await entry.delete();
            debugPrint("NetHackAssets: Cleaned up duplicate legacy level file '$fileName'");
          }
        } else {
          await entry.delete();
          debugPrint("NetHackAssets: Removed orphaned level file from different UID: '$fileName'");
        }
      }
    } catch (e) {
      debugPrint("Warning: Exception during legacy level file cleanup: $e");
    }
  }

  static int _getCurrentUid() {
    if (Platform.isAndroid || Platform.isLinux) {
      try {
        final libc = DynamicLibrary.process();
        final getuid = libc.lookupFunction<Uint32 Function(), int Function()>('getuid');
        return getuid();
      } catch (e) {
        debugPrint("Warning: Could not lookup getuid via FFI: $e");
      }
    }
    return 10470;
  }

  /// テスト用エントリーポイント: logfile / xlogfile の record 同期処理を直接実行する
  @visibleForTesting
  static Future<void> syncLogsWithRecordForTesting(Directory nethackDir) {
    return _syncLogsWithRecord(nethackDir);
  }

  /// 既存の logfile / xlogfile が存在する場合に限り、record の有効行に合わせてトリム整理する
  static Future<void> _syncLogsWithRecord(Directory nethackDir) async {
    try {
      final logFile = File('${nethackDir.path}/logfile');
      final xlogFile = File('${nethackDir.path}/xlogfile');
      final hasLog = await logFile.exists();
      final hasXLog = await xlogFile.exists();
      if (!hasLog && !hasXLog) return;

      final recordFile = File('${nethackDir.path}/record');
      final List<RecordLogEntry> recordEntries;
      if (await recordFile.exists()) {
        final recBytes = await recordFile.readAsBytes();
        final recText = utf8.decode(recBytes, allowMalformed: true);
        recordEntries = parseRecordLines(const LineSplitter().convert(recText));
      } else {
        recordEntries = const [];
      }

      if (hasLog) {
        final logBytes = await logFile.readAsBytes();
        final logText = utf8.decode(logBytes, allowMalformed: true);
        final normalizedOrig = logText.replaceAll('\r\n', '\n');
        String newLogText;

        if (recordEntries.isEmpty) {
          newLogText = '';
        } else {
          final logEntries = parseRecordLines(const LineSplitter().convert(logText));
          final consumed = List<bool>.filled(logEntries.length, false);
          final keptLines = <String>[];

          for (final rec in recordEntries) {
            for (int j = 0; j < logEntries.length; j++) {
              if (consumed[j]) continue;
              final le = logEntries[j];
              if (le.points == rec.points &&
                  le.dnum == rec.dnum &&
                  le.dlev == rec.dlev &&
                  le.maxlvl == rec.maxlvl &&
                  le.hp == rec.hp &&
                  le.maxhp == rec.maxhp &&
                  le.deaths == rec.deaths &&
                  le.deathdate == rec.deathdate &&
                  le.birthdate == rec.birthdate &&
                  le.uid == rec.uid &&
                  le.role == rec.role &&
                  le.race == rec.race &&
                  le.gend == rec.gend &&
                  le.align == rec.align &&
                  le.name == rec.name) {
                consumed[j] = true;
                keptLines.add(le.rawLine);
                break;
              }
            }
          }
          newLogText = keptLines.isEmpty ? '' : '${keptLines.join('\n')}\n';
        }

        if (normalizedOrig != newLogText) {
          await logFile.writeAsString(newLogText, flush: true);
          debugPrint("NetHackAssets: Synced logfile with ${recordEntries.length} record entries.");
        }
      }

      if (hasXLog) {
        final xlogBytes = await xlogFile.readAsBytes();
        final xlogText = utf8.decode(xlogBytes, allowMalformed: true);
        final normalizedOrig = xlogText.replaceAll('\r\n', '\n');
        String newXLogText;

        if (recordEntries.isEmpty) {
          newXLogText = '';
        } else {
          final xlogLines = const LineSplitter().convert(xlogText);
          final parsedXLogs = <XLogEntry>[];
          for (final line in xlogLines) {
            final parsed = XLogEntry.parseLine(line);
            if (parsed != null) {
              parsedXLogs.add(parsed);
            }
          }
          final consumed = List<bool>.filled(parsedXLogs.length, false);
          final keptLines = <String>[];

          for (final rec in recordEntries) {
            for (int j = 0; j < parsedXLogs.length; j++) {
              if (consumed[j]) continue;
              final xl = parsedXLogs[j];
              if (xl.matchesRecordFields(
                points: rec.points,
                deathdnum: rec.dnum,
                deathlev: rec.dlev,
                maxlvl: rec.maxlvl,
                hp: rec.hp,
                maxhp: rec.maxhp,
                deaths: rec.deaths,
                deathdate: rec.deathdate,
                birthdate: rec.birthdate,
                uid: rec.uid,
                role: rec.role,
                race: rec.race,
                gender: rec.gend,
                align: rec.align,
                name: rec.name,
              )) {
                consumed[j] = true;
                keptLines.add(xl.rawLine);
                break;
              }
            }
          }
          newXLogText = keptLines.isEmpty ? '' : '${keptLines.join('\n')}\n';
        }

        if (normalizedOrig != newXLogText) {
          await xlogFile.writeAsString(newXLogText, flush: true);
          debugPrint("NetHackAssets: Synced xlogfile with ${recordEntries.length} record entries.");
        }
      }
    } catch (e) {
      debugPrint("Warning: Exception during syncLogsWithRecord: $e");
    }
  }
}


