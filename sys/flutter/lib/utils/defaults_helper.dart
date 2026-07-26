import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NetHack の defaults.nh ファイルおよび SharedPreferences との連動を管理するヘルパークラス
class DefaultsHelper {
  /// アプリの設定画面から管理・変更を行うオプションキーの集合
  /// これ以外のオプション（例: color, dumplog 等）は一切改変せず保持する
  static const Set<String> managedKeys = {
    'name',
    'tutorial',
    'autopickup',
    'pickup_types',
    'time',
    'showexp',
    'price_quotes',
    'dogname',
    'catname',
    'horsename',
    'fruit',
    'hilite_status',
    'menucolor',
    'number_pad',
  };

  static const String managedHeaderComment = '# *** Managed Options by Settings ***';

  /// defaults.nh 内の管理対象オプション保持用マップ
  final Map<String, String> _options = {};

  /// 文字列を指定した文字数（UTF-8 のルーン数/文字単位）で切り詰める（改行コードは自動除去）
  static String truncateUtf8Chars(String text, int maxChars) {
    if (text.isEmpty || maxChars <= 0) return '';
    final sanitized = text.replaceAll(RegExp(r'[\r\n]'), '');
    final characters = sanitized.characters;
    if (characters.length <= maxChars) return sanitized;
    return characters.take(maxChars).toString();
  }

  /// defaults.nh ファイルを読み込み、管理対象の OPTIONS をパースする
  Future<void> loadFromFile(String filePath) async {
    _options.clear();
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint("defaults.nh not found at $filePath");
      return;
    }

    try {
      final lines = await file.readAsLines();
      bool hasActiveHiliteStatus = false;
      bool hasActiveMenuColor = false;

      for (var line in lines) {
        final trimmed = line.trim();

        // hilite_status と MENUCOLOR の有効行（先頭コメントなし）の存在チェック
        if (trimmed.startsWith('OPTIONS=hilite_status:')) {
          hasActiveHiliteStatus = true;
        }
        if (trimmed.startsWith('MENUCOLOR=') || trimmed.startsWith('MENUCOLOR ')) {
          hasActiveMenuColor = true;
        }

        // コメント行や空行はパースからはスキップ
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        if (trimmed.startsWith('OPTIONS=')) {
          final content = trimmed.substring('OPTIONS='.length);
          _parseOptionsLine(content);
        }
      }

      // hilite_status および menucolor の全体判定結果を保存
      _options['hilite_status'] = hasActiveHiliteStatus ? 'true' : 'false';
      _options['menucolor'] = hasActiveMenuColor ? 'true' : 'false';
    } catch (e) {
      debugPrint("Error reading defaults.nh: $e");
    }
  }

  /// 1行の OPTIONS=... 内容（カンマ区切りを含む）から管理対象オプションのみパースする
  void _parseOptionsLine(String lineContent) {
    final tokens = _splitCommaTokens(lineContent);
    for (var token in tokens) {
      token = token.trim();
      if (token.isEmpty) continue;

      String key = '';
      String val = '';
      bool isBool = false;
      bool boolVal = true;

      if (token.contains(':')) {
        final colonIdx = token.indexOf(':');
        key = token.substring(0, colonIdx).trim();
        val = token.substring(colonIdx + 1).trim();
      } else if (token.startsWith('!')) {
        key = token.substring(1).trim();
        isBool = true;
        boolVal = false;
      } else {
        key = token.trim();
        isBool = true;
        boolVal = true;
      }

      // hilite_status は個別の _parseOptionsLine ではなく行単位の全走査で一括判定するためここでの単独登録はスキップ
      if (key == 'hilite_status' || key == 'menucolor') continue;

      if (managedKeys.contains(key)) {
        if (key == 'number_pad') {
          if (isBool) {
            _options[key] = boolVal ? '1' : '0';
          } else {
            _options[key] = val;
          }
        } else if (isBool) {
          _options[key] = boolVal ? 'true' : 'false';
        } else {
          _options[key] = val;
        }
      }
    }
  }

  /// 引用符や文字列内のカンマを保護しながらカンマ分割
  List<String> _splitCommaTokens(String content) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuote = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"' || char == "'") {
        inQuote = !inQuote;
        buffer.write(char);
      } else if (char == ',' && !inQuote) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }
    return result;
  }

  /// 指定キーのオプション値を取得
  String? getOption(String key) => _options[key];

  /// ブールオプションの値を取得 (未設定時のデフォルト値を指定可能)
  bool getBoolOption(String key, {bool defaultValue = false}) {
    final val = _options[key];
    if (val == null) return defaultValue;
    return val.toLowerCase() == 'true';
  }

  /// オプションの値をセットする
  void setOption(String key, String value) {
    if (managedKeys.contains(key)) {
      _options[key] = value;
    }
  }

  /// ブールオプションの値をセットする
  void setBoolOption(String key, bool value) {
    if (managedKeys.contains(key)) {
      _options[key] = value ? 'true' : 'false';
    }
  }

  /// 現在の _options の状態を defaults.nh ファイルに反映・保存する
  Future<void> saveToFile(String filePath) async {
    final file = File(filePath);
    List<String> lines = [];
    if (await file.exists()) {
      lines = await file.readAsLines();
    }

    final newLines = <String>[];
    bool headerAlreadyPresent = false;

    final hiliteStatusOn = getBoolOption('hilite_status', defaultValue: true);
    final menucolorOn = getBoolOption('menucolor', defaultValue: true);

    for (var line in lines) {
      var trimmed = line.trim();

      // 重複ヘッダーコメントの除去
      if (trimmed == managedHeaderComment) {
        if (headerAlreadyPresent) {
          continue;
        }
        headerAlreadyPresent = true;
      }

      // 1. hilite_status 行のコメントアウト／コメント解除トグル処理
      final isHiliteLine = trimmed.startsWith('OPTIONS=hilite_status:') ||
          trimmed.startsWith('#OPTIONS=hilite_status:') ||
          trimmed.startsWith('# OPTIONS=hilite_status:');

      if (isHiliteLine) {
        if (hiliteStatusOn) {
          // ON の場合: コメント '#' を除去して有効化
          if (trimmed.startsWith('#')) {
            var activeLine = trimmed.substring(1).trim();
            newLines.add(activeLine);
          } else {
            newLines.add(line);
          }
        } else {
          // OFF の場合: 先頭に '#' を追加してコメントアウト
          if (!trimmed.startsWith('#')) {
            newLines.add('#$trimmed');
          } else {
            newLines.add(line);
          }
        }
        continue;
      }

      // 2. MENUCOLOR 行のコメントアウト／コメント解除トグル処理
      final isMenuColorLine = trimmed.startsWith('MENUCOLOR=') ||
          trimmed.startsWith('MENUCOLOR ') ||
          trimmed.startsWith('#MENUCOLOR=') ||
          trimmed.startsWith('# MENUCOLOR=') ||
          trimmed.startsWith('#MENUCOLOR ') ||
          trimmed.startsWith('# MENUCOLOR ');

      if (isMenuColorLine) {
        if (menucolorOn) {
          // ON の場合: コメント '#' を除去して有効化
          if (trimmed.startsWith('#')) {
            var activeLine = trimmed.substring(1).trim();
            newLines.add(activeLine);
          } else {
            newLines.add(line);
          }
        } else {
          // OFF の場合: 先頭に '#' を追加してコメントアウト
          if (!trimmed.startsWith('#')) {
            newLines.add('#$trimmed');
          } else {
            newLines.add(line);
          }
        }
        continue;
      }

      // 3. 一般 OPTIONS= 行の単独管理キーの更新処理
      if (trimmed.startsWith('OPTIONS=')) {
        final content = trimmed.substring('OPTIONS='.length);
        final tokens = _splitCommaTokens(content);
        final remainingTokens = <String>[];

        for (var token in tokens) {
          final t = token.trim();
          String key = '';
          if (t.contains(':')) {
            key = t.substring(0, t.indexOf(':')).trim();
          } else if (t.startsWith('!')) {
            key = t.substring(1).trim();
          } else {
            key = t.trim();
          }

          // 管理対象キー（hilite_status, menucolor を除く単独オプション）はスキップ
          if (managedKeys.contains(key) && key != 'hilite_status' && key != 'menucolor') {
            continue;
          } else {
            remainingTokens.add(token);
          }
        }

        if (remainingTokens.isNotEmpty) {
          newLines.add('OPTIONS=${remainingTokens.join(', ')}');
        }
      } else {
        newLines.add(line);
      }
    }

    // 単独管理キーの新しいオプション設定行を準備（hilite_status, menucolor を除く）
    final pendingLines = <String>[];
    _options.forEach((key, val) {
      if (key == 'hilite_status' || key == 'menucolor') return;

      if (key == 'number_pad') {
        if (val == '0') {
          pendingLines.add('OPTIONS=!number_pad');
        } else {
          pendingLines.add('OPTIONS=number_pad:$val');
        }
      } else if (val.toLowerCase() == 'true') {
        pendingLines.add('OPTIONS=$key');
      } else if (val.toLowerCase() == 'false') {
        pendingLines.add('OPTIONS=!$key');
      } else {
        pendingLines.add('OPTIONS=$key:$val');
      }
    });

    if (pendingLines.isNotEmpty) {
      if (!headerAlreadyPresent) {
        newLines.add(managedHeaderComment);
      }
      newLines.addAll(pendingLines);
    }

    try {
      await file.writeAsString('${newLines.join('\n')}\n', flush: true);
    } catch (e) {
      debugPrint("Error writing to defaults.nh: $e");
    }
  }

  /// SharedPreferences と defaults.nh 間の同期
  Future<void> syncFromFileToPrefs(String filePath) async {
    await loadFromFile(filePath);
    final prefs = await SharedPreferences.getInstance();

    // チュートリアル確認
    final tutorialVal = getOption('tutorial');
    if (tutorialVal != null) {
      await prefs.setBool('nh_opt_tutorial', tutorialVal.toLowerCase() == 'true');
    } else {
      if (!prefs.containsKey('nh_opt_tutorial')) {
        await prefs.setBool('nh_opt_tutorial', true);
      }
    }

    // 自動拾い (autopickup)
    final autopickupVal = getOption('autopickup');
    if (autopickupVal != null) {
      await prefs.setBool('nh_opt_autopickup', autopickupVal.toLowerCase() == 'true');
    }

    // 自動拾い種別 (pickup_types)
    final pickupTypesVal = getOption('pickup_types');
    if (pickupTypesVal != null) {
      await prefs.setString('nh_opt_pickup_types', pickupTypesVal);
    }

    // 経過ターン表示 (time)
    final timeVal = getOption('time');
    if (timeVal != null) {
      await prefs.setBool('nh_opt_time', timeVal.toLowerCase() == 'true');
    }

    // 経験値表示 (showexp)
    final showexpVal = getOption('showexp');
    if (showexpVal != null) {
      await prefs.setBool('nh_opt_showexp', showexpVal.toLowerCase() == 'true');
    }

    // 価格見積表示 (price_quotes)
    final priceQuotesVal = getOption('price_quotes');
    if (priceQuotesVal != null) {
      await prefs.setBool('nh_opt_price_quotes', priceQuotesVal.toLowerCase() == 'true');
    }

    // ステータスハイライト (hilite_status): デフォルト ON (true)
    final hiliteStatusVal = getOption('hilite_status');
    if (hiliteStatusVal != null) {
      await prefs.setBool('nh_opt_hilite_status', hiliteStatusVal.toLowerCase() == 'true');
    } else {
      if (!prefs.containsKey('nh_opt_hilite_status')) {
        await prefs.setBool('nh_opt_hilite_status', true);
      }
    }

    // メニューのカラー表示 (menucolor): デフォルト ON (true)
    final menucolorVal = getOption('menucolor');
    if (menucolorVal != null) {
      await prefs.setBool('nh_opt_menucolor', menucolorVal.toLowerCase() == 'true');
    } else {
      if (!prefs.containsKey('nh_opt_menucolor')) {
        await prefs.setBool('nh_opt_menucolor', true);
      }
    }

    // 主人公名 & ペット名 & 果物名
    final nameVal = getOption('name');
    if (nameVal != null) {
      await prefs.setString('nh_opt_name', nameVal);
    }
    final dognameVal = getOption('dogname');
    if (dognameVal != null) {
      await prefs.setString('nh_opt_dogname', dognameVal);
    }
    final catnameVal = getOption('catname');
    if (catnameVal != null) {
      await prefs.setString('nh_opt_catname', catnameVal);
    }
    final horsenameVal = getOption('horsename');
    if (horsenameVal != null) {
      await prefs.setString('nh_opt_horsename', horsenameVal);
    }
    final fruitVal = getOption('fruit');
    if (fruitVal != null) {
      await prefs.setString('nh_opt_fruit', fruitVal);
    }

    // テンキー移動 (number_pad): int型 (デフォルト: 0)
    final numberPadVal = getOption('number_pad');
    if (numberPadVal != null) {
      final parsedInt = int.tryParse(numberPadVal) ?? (numberPadVal.toLowerCase() == 'true' ? 1 : 0);
      await prefs.setInt('nh_opt_number_pad', parsedInt);
    } else {
      if (!prefs.containsKey('nh_opt_number_pad')) {
        await prefs.setInt('nh_opt_number_pad', 0);
      }
    }
  }

  /// SharedPreferences の現在値を defaults.nh ファイルに反映保存する
  Future<void> syncFromPrefsToFile(String filePath) async {
    await loadFromFile(filePath);
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('nh_opt_tutorial')) {
      setBoolOption('tutorial', prefs.getBool('nh_opt_tutorial') ?? true);
    }
    if (prefs.containsKey('nh_opt_autopickup')) {
      setBoolOption('autopickup', prefs.getBool('nh_opt_autopickup') ?? false);
    }
    if (prefs.containsKey('nh_opt_pickup_types')) {
      setOption('pickup_types', prefs.getString('nh_opt_pickup_types') ?? '');
    }
    if (prefs.containsKey('nh_opt_time')) {
      setBoolOption('time', prefs.getBool('nh_opt_time') ?? true);
    }
    if (prefs.containsKey('nh_opt_showexp')) {
      setBoolOption('showexp', prefs.getBool('nh_opt_showexp') ?? true);
    }
    if (prefs.containsKey('nh_opt_price_quotes')) {
      setBoolOption('price_quotes', prefs.getBool('nh_opt_price_quotes') ?? true);
    }
    if (prefs.containsKey('nh_opt_hilite_status')) {
      setBoolOption('hilite_status', prefs.getBool('nh_opt_hilite_status') ?? true);
    }
    if (prefs.containsKey('nh_opt_menucolor')) {
      setBoolOption('menucolor', prefs.getBool('nh_opt_menucolor') ?? true);
    }
    if (prefs.containsKey('nh_opt_name')) {
      setOption('name', prefs.getString('nh_opt_name') ?? '');
    }
    if (prefs.containsKey('nh_opt_dogname')) {
      setOption('dogname', prefs.getString('nh_opt_dogname') ?? '');
    }
    if (prefs.containsKey('nh_opt_catname')) {
      setOption('catname', prefs.getString('nh_opt_catname') ?? '');
    }
    if (prefs.containsKey('nh_opt_horsename')) {
      setOption('horsename', prefs.getString('nh_opt_horsename') ?? '');
    }
    if (prefs.containsKey('nh_opt_fruit')) {
      setOption('fruit', prefs.getString('nh_opt_fruit') ?? '');
    }
    if (prefs.containsKey('nh_opt_number_pad')) {
      setOption('number_pad', (prefs.getInt('nh_opt_number_pad') ?? 0).toString());
    }

    await saveToFile(filePath);
  }

  /// アセットの defaults.nh と SharedPreferences のユーザー設定を安全に双方向マージする
  /// - 新規キー: アセットのデフォルト値を補完追加
  /// - 廃止キー: SharedPreferences から削除
  /// - 無効値: デフォルト値にフォールバック
  /// - 有効な既存設定: そのまま優先維持
  Future<void> mergeAssetDefaultsWithPrefs(String assetFilePath, String targetFilePath) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. アセット側の最新 defaults.nh を読込
    await loadFromFile(assetFilePath);
    final Map<String, String> assetDefaults = Map.from(_options);

    // 2. 廃止された nh_opt_* キーの削除クリーンアップ
    final allKeys = prefs.getKeys().where((k) => k.startsWith('nh_opt_')).toList();
    for (final prefKey in allKeys) {
      final optKey = prefKey.substring('nh_opt_'.length);
      if (!managedKeys.contains(optKey)) {
        await prefs.remove(prefKey);
        debugPrint("DefaultsHelper: Removed obsolete option key '$prefKey'");
      }
    }

    // 3. 各 managedKeys の比較・補完・検証
    for (final optKey in managedKeys) {
      final prefKey = 'nh_opt_$optKey';
      final assetDefaultVal = assetDefaults[optKey];

      if (!prefs.containsKey(prefKey)) {
        // 新規キーの補完追加
        if (assetDefaultVal != null) {
          if (optKey == 'number_pad') {
            final int iVal = int.tryParse(assetDefaultVal) ?? 0;
            await prefs.setInt(prefKey, iVal);
          } else if (optKey == 'name' || optKey == 'pickup_types' || optKey == 'dogname' || optKey == 'catname' || optKey == 'horsename' || optKey == 'fruit') {
            await prefs.setString(prefKey, assetDefaultVal);
          } else {
            final bool bVal = assetDefaultVal.toLowerCase() == 'true';
            await prefs.setBool(prefKey, bVal);
          }
          debugPrint("DefaultsHelper: Added new option '$prefKey' = $assetDefaultVal");
        }
      } else {
        // 既存設定の検証と範囲外値のフォールバック
        if (optKey == 'number_pad') {
          final currentVal = prefs.getInt(prefKey);
          if (currentVal == null || currentVal < -1 || currentVal > 4) {
            await prefs.setInt(prefKey, 0);
          }
        } else if (optKey == 'pickup_types') {
          final currentVal = prefs.getString(prefKey) ?? '';
          // 有効なピックアップ文字以外の不正文字が含まれる場合はデフォルトへリセット
          final validChars = RegExp(r'^[a-zA-Z0-9\$\"=/!\?\+\*\-\%\`\[\]\)\(\@\_\#]+$');
          if (currentVal.isNotEmpty && !validChars.hasMatch(currentVal)) {
            final defaultPickup = assetDefaultVal ?? r'$"=/!?+';
            await prefs.setString(prefKey, defaultPickup);
            debugPrint("DefaultsHelper: Invalid pickup_types '$currentVal' reset to '$defaultPickup'");
          }
        }
      }
    }

    // 4. マージ完了後の最新設定をターゲットdefaults.nhファイルに書き出し
    await syncFromPrefsToFile(targetFilePath);
  }
}

