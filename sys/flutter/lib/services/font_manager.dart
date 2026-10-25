import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_prefs.dart';
import 'font_validator.dart';

/// フォント設定の対象コンポーネント（5系統）
enum FontTarget {
  /// ダンジョンマップ（アスキーアート描画）: 日本語フォールバック完全禁止
  map,

  /// 上部メッセージ行 & メッセージ履歴
  message,

  /// ステータス行（HP、レベル、AC、ゴールド等）
  status,

  /// メニュー & テキストウィンドウ（インベントリ、遠見、案内等）
  menu,

  /// 全体UI・仮想コントローラ・設定画面ダイアログ
  ui,
}

/// 選択可能なフォントエントリ
class FontItem {
  /// 一意の識別子 ('system', 'Terminus', '`custom_<uuid>`' 等)
  final String id;

  /// 画面表示用ラベル ('システム標準等幅', 'Terminus TTF', 等)
  final String displayName;

  /// Flutter で使用する fontFamily 名
  final String? fontFamily;

  /// アプリ内蔵フォントかどうか（内蔵フォントは削除不可）
  final bool isBuiltIn;

  /// 外部フォントの場合の保存先ファイルパス
  final String? localFilePath;

  const FontItem({
    required this.id,
    required this.displayName,
    this.fontFamily,
    this.isBuiltIn = true,
    this.localFilePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// アプリ全体のフォント設定、内蔵・外部フォントのロード、
/// およびアスキーマップ用セルサイズの自動計測・一元管理を司るサービスクラス
class FontManager extends ChangeNotifier {
  static FontManager? _instance;

  /// シングルトンインスタンス取得
  static FontManager get instance => _instance ??= FontManager._();

  // Prefs キー名
  static const String prefFontMap = 'pref_font_map';
  static const String prefFontMessage = 'pref_font_message';
  static const String prefFontStatus = 'pref_font_status';
  static const String prefFontMenu = 'pref_font_menu';
  static const String prefFontUi = 'pref_font_ui';
  static const String prefMapAsciiScale = 'pref_map_ascii_scale';

  /// 内蔵フォント一覧
  static const List<FontItem> builtInFonts = [
    FontItem(
      id: 'system',
      displayName: 'システム標準 (等幅)',
      fontFamily: 'monospace',
      isBuiltIn: true,
    ),
    FontItem(
      id: 'Terminus',
      displayName: 'Terminus TTF (アスキー定番)',
      fontFamily: 'Terminus',
      isBuiltIn: true,
    ),
    FontItem(
      id: 'Unscii-8',
      displayName: 'Unscii 8x8 (レトロPC)',
      fontFamily: 'Unscii-8',
      isBuiltIn: true,
    ),
    FontItem(
      id: 'Unscii-16',
      displayName: 'Unscii 16x16 (高精細レトロ)',
      fontFamily: 'Unscii-16',
      isBuiltIn: true,
    ),
    FontItem(
      id: 'MisakiGothic',
      displayName: '美咲ゴシック (日本語レトロ)',
      fontFamily: 'MisakiGothic',
      isBuiltIn: true,
    ),
  ];

  /// 日本語フォールバック用フォントファミリリスト（マップ以外用）
  static const List<String> defaultJapaneseFallbacks = [
    'Noto Sans JP',
    'Hiragino Sans',
    'Meiryo',
    'Yu Gothic',
    'sans-serif',
  ];

  AppPrefs? _prefs;
  Directory? _customFontsDir;

  /// 動的インポートされたカスタムフォント一覧
  final List<FontItem> _customFonts = [];

  /// 各ターゲットの現在選択されているフォントID
  final Map<FontTarget, String> _selectedFontIds = {
    FontTarget.map: 'Terminus',
    FontTarget.message: 'system',
    FontTarget.status: 'system',
    FontTarget.menu: 'system',
    FontTarget.ui: 'system',
  };

  /// アスキーマップ表示倍率（デフォルト 1.0）
  double _mapAsciiScale = 1.0;

  /// フォント別のアスペクト比（文字幅 / 高さ）キャッシュ
  final Map<String?, double> _aspectRatioCache = {};

  bool _isInitialized = false;

  FontManager._();

  /// テスト用リセット
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  /// 初期化完了フラグ
  bool get isInitialized => _isInitialized;

  /// 利用可能な全フォント一覧（内蔵 ＋ 外部インポート）
  List<FontItem> get availableFonts => [...builtInFonts, ..._customFonts];

  /// アスキーマップの表示倍率（1.0 〜 2.5）
  double get mapAsciiScale => _mapAsciiScale;

  /// 初期化処理（Prefs ロード、外部フォント走査・動的登録）
  Future<void> init({AppPrefs? prefs, Directory? customFontsDir}) async {
    _prefs = prefs ?? await AppPrefs.getInstance();

    if (customFontsDir != null) {
      _customFontsDir = customFontsDir;
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      _customFontsDir = Directory('${appDocDir.path}/custom_fonts');
    }

    if (!await _customFontsDir!.exists()) {
      await _customFontsDir!.create(recursive: true);
    }

    // 保存されている設定値を読み込み
    _selectedFontIds[FontTarget.map] =
        _prefs!.getString(prefFontMap) ?? 'Terminus';
    _selectedFontIds[FontTarget.message] =
        _prefs!.getString(prefFontMessage) ?? 'system';
    _selectedFontIds[FontTarget.status] =
        _prefs!.getString(prefFontStatus) ?? 'system';
    _selectedFontIds[FontTarget.menu] =
        _prefs!.getString(prefFontMenu) ?? 'system';
    _selectedFontIds[FontTarget.ui] =
        _prefs!.getString(prefFontUi) ?? 'system';
    _mapAsciiScale = _prefs!.getDouble(prefMapAsciiScale) ?? 1.0;

    // 外部フォントディレクトリを走査して動的登録
    await _loadCustomFontsFromStorage();

    _isInitialized = true;
    notifyListeners();
  }

  /// 外部フォントをローカルストレージからスキャンして Flutter に登録
  Future<void> _loadCustomFontsFromStorage() async {
    _customFonts.clear();
    if (_customFontsDir == null || !await _customFontsDir!.exists()) return;

    final files = _customFontsDir!.listSync();
    for (final entity in files) {
      if (entity is File && FontValidator.hasSupportedExtension(entity.path)) {
        try {
          final bytes = await entity.readAsBytes();
          final validation = FontValidator.validateAndNormalize(bytes);
          if (validation.isValid && validation.normalizedBytes != null) {
            final fileName = entity.uri.pathSegments.last;
            final baseName = fileName.contains('.')
                ? fileName.substring(0, fileName.lastIndexOf('.'))
                : fileName;
            final fontId = 'custom_$baseName';
            final familyName = 'CustomFont_$baseName';

            // Flutter FontLoader に動的登録
            final fontLoader = FontLoader(familyName);
            fontLoader.addFont(Future.value(ByteData.sublistView(validation.normalizedBytes!)));
            await fontLoader.load();

            _customFonts.add(FontItem(
              id: fontId,
              displayName: '$baseName (${validation.formatDescription})',
              fontFamily: familyName,
              isBuiltIn: false,
              localFilePath: entity.path,
            ));
          }
        } catch (e) {
          debugPrint('[FontManager] 外部フォント読み込み失敗: ${entity.path}, エラー: $e');
        }
      }
    }
  }

  /// ターゲットごとの選択中フォントエントリを取得
  FontItem getSelectedFont(FontTarget target) {
    final id = _selectedFontIds[target] ?? 'system';
    return availableFonts.firstWhere(
      (f) => f.id == id,
      orElse: () => builtInFonts.first, // 'system'
    );
  }

  /// ターゲットのフォントを変更
  Future<void> setFont(FontTarget target, String fontId) async {
    final exists = availableFonts.any((f) => f.id == fontId);
    final targetId = exists ? fontId : 'system';

    _selectedFontIds[target] = targetId;

    if (_prefs != null) {
      final key = _getPrefKeyForTarget(target);
      await _prefs!.setString(key, targetId);
    }

    notifyListeners();
  }

  /// 全5系統のフォントを一括変更
  Future<void> setAllFonts(String fontId) async {
    final exists = availableFonts.any((f) => f.id == fontId);
    final targetId = exists ? fontId : 'system';

    for (final target in FontTarget.values) {
      _selectedFontIds[target] = targetId;
      if (_prefs != null) {
        final key = _getPrefKeyForTarget(target);
        await _prefs!.setString(key, targetId);
      }
    }

    notifyListeners();
  }

  /// アスキーマップ表示倍率の設定（1.0 〜 2.5）
  Future<void> setMapAsciiScale(double scale) async {
    _mapAsciiScale = scale.clamp(1.0, 2.5);
    if (_prefs != null) {
      await _prefs!.setDouble(prefMapAsciiScale, _mapAsciiScale);
    }
    notifyListeners();
  }

  /// 外部フォントファイルを検証・インポートして永続保存
  Future<FontValidationResult> importCustomFont(
    Uint8List rawBytes,
    String originalFileName,
  ) async {
    final validation = FontValidator.validateAndNormalize(rawBytes);
    if (!validation.isValid || validation.normalizedBytes == null) {
      return validation;
    }

    if (_customFontsDir == null) {
      return const FontValidationResult.failure('フォント保存先ディレクトリが初期化されていません');
    }

    // ファイル名から拡張子を除去してサニタイズ（英数字、アンダースコア、ハイフンのみ許可）
    final nameWithoutExt = originalFileName.contains('.')
        ? originalFileName.substring(0, originalFileName.lastIndexOf('.'))
        : originalFileName;
    final sanitizedBase = nameWithoutExt
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final ext = originalFileName.toLowerCase().endsWith('.woff') ? '.ttf' : '.ttf';
    final targetFileName = '$sanitizedBase$ext';
    final targetFile = File('${_customFontsDir!.path}/$targetFileName');

    // 展開・正規化された SFNT バイナリをディスクに保存
    await targetFile.writeAsBytes(validation.normalizedBytes!);

    final fontId = 'custom_$sanitizedBase';
    final familyName = 'CustomFont_$sanitizedBase';

    // 即時動的ロード
    try {
      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future.value(ByteData.sublistView(validation.normalizedBytes!)));
      await fontLoader.load();
    } catch (e) {
      return FontValidationResult.failure('フォント動的登録エラー: $e');
    }

    // 既存リストにあれば置換、なければ追加
    _customFonts.removeWhere((f) => f.id == fontId);
    final newItem = FontItem(
      id: fontId,
      displayName: '$sanitizedBase (${validation.formatDescription})',
      fontFamily: familyName,
      isBuiltIn: false,
      localFilePath: targetFile.path,
    );
    _customFonts.add(newItem);

    // アスペクト比キャッシュを更新
    _measureAndCacheAspectRatio(familyName);

    notifyListeners();
    return validation;
  }

  /// 外部フォントの削除
  Future<bool> deleteCustomFont(String fontId) async {
    final index = _customFonts.indexWhere((f) => f.id == fontId);
    if (index == -1) return false;

    final item = _customFonts[index];
    if (item.localFilePath != null) {
      final file = File(item.localFilePath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('[FontManager] フォントファイル削除エラー: $e');
        }
      }
    }

    _customFonts.removeAt(index);

    // 削除されたフォントが選択されていた場合は 'system' にフォールバック
    for (final target in FontTarget.values) {
      if (_selectedFontIds[target] == fontId) {
        await setFont(target, 'system');
      }
    }

    notifyListeners();
    return true;
  }

  /// ターゲットごとの TextStyle を生成
  TextStyle getStyle(
    FontTarget target, {
    TextStyle? baseStyle,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) {
    final fontItem = getSelectedFont(target);
    final family = fontItem.fontFamily;

    if (target == FontTarget.map) {
      // マップ描画: 日本語フォールバック完全禁止、ビットマップの滲み防止 (normal weight)
      return (baseStyle ?? const TextStyle()).copyWith(
        fontFamily: family,
        fontFamilyFallback: null,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight ?? FontWeight.normal,
        height: height ?? 1.0,
      );
    }

    // マップ以外: 英語専用フォント選択時でも日本語が消去されないようフォールバックを設定
    return (baseStyle ?? const TextStyle()).copyWith(
      fontFamily: family,
      fontFamilyFallback: defaultJapaneseFallbacks,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// フォントの文字アスペクト比（文字幅 / 高さ）を取得
  double getAspectRatio(FontTarget target) {
    final item = getSelectedFont(target);
    final family = item.fontFamily;
    if (_aspectRatioCache.containsKey(family)) {
      return _aspectRatioCache[family]!;
    }
    return _measureAndCacheAspectRatio(family);
  }

  /// TextPainter による文字アスペクト比の自動計測
  double _measureAndCacheAspectRatio(String? fontFamily) {
    try {
      final painter = TextPainter(
        text: TextSpan(
          text: 'M',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 20.0,
            height: 1.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      final w = painter.width;
      final h = painter.height;
      if (h <= 0) {
        _aspectRatioCache[fontFamily] = 0.5;
        return 0.5;
      }
      final ratio = (w / h).clamp(0.3, 1.0);
      _aspectRatioCache[fontFamily] = ratio;
      return ratio;
    } catch (_) {
      _aspectRatioCache[fontFamily] = 0.5;
      return 0.5;
    }
  }

  /// マップセルサイズの一元算出
  ///
  /// タイルモード時は 32x32（固定）。
  /// アスキーモード時は、フォントの実測アスペクト比と倍率設定に基づいて
  /// 縦横のセルサイズを動的に計算します。
  Size getMapCellSize({required bool useTiles, double? customScale}) {
    if (useTiles) {
      return const Size(32.0, 32.0);
    }
    final scale = customScale ?? _mapAsciiScale;
    final baseH = 28.0 * scale;
    final ratio = getAspectRatio(FontTarget.map);
    final baseW = (baseH * ratio).roundToDouble();
    return Size(baseW, baseH);
  }

  String _getPrefKeyForTarget(FontTarget target) {
    switch (target) {
      case FontTarget.map:
        return prefFontMap;
      case FontTarget.message:
        return prefFontMessage;
      case FontTarget.status:
        return prefFontStatus;
      case FontTarget.menu:
        return prefFontMenu;
      case FontTarget.ui:
        return prefFontUi;
    }
  }
}
