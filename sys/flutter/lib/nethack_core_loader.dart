import 'dart:ffi';
import 'dart:io';

/// Dynamic Core Loader for Bilingual NetHack (EN / JP)
class NetHackCoreLoader {
  static DynamicLibrary? _loadedLibrary;
  static String? _currentLanguage;

  /// Returns the current active language code ('ja' or 'en')
  static String get currentLanguage => _currentLanguage ?? 'ja';

  /// Returns the sub-asset directory path ('jp' or 'en')
  static String getAssetSubdir([String? langCode]) {
    final lang = langCode ?? currentLanguage;
    return (lang == 'ja') ? 'jp' : 'en';
  }

  /// Resolves the library filename or path for the target platform and language.
  /// If [platformOverride] is provided, it resolves for that platform ('android', 'windows', 'ios', 'other').
  static String getLibraryName({String langCode = 'ja', String? platformOverride}) {
    final isJp = (langCode == 'ja');
    final platform = platformOverride ??
        (Platform.isAndroid
            ? 'android'
            : (Platform.isWindows
                ? 'windows'
                : (Platform.isIOS ? 'ios' : 'other')));

    switch (platform) {
      case 'android':
        return isJp ? 'libnethack_jp.so' : 'libnethack_en.so';
      case 'windows':
        return isJp ? 'nethack_jp.dll' : 'nethack_en.dll';
      case 'ios':
        return isJp
            ? 'Frameworks/nethack_jp.framework/nethack_jp'
            : 'Frameworks/nethack_en.framework/nethack_en';
      default:
        return isJp ? 'nethack_jp' : 'nethack_en';
    }
  }

  /// Resets the cached library and language state for unit testing.
  static void resetForTesting() {
    _loadedLibrary = null;
    _currentLanguage = null;
  }

  /// Loads the appropriate NetHack C-core shared library based on [langCode].
  /// On Android: loads 'libnethack_jp.so' or 'libnethack_en.so'
  /// On Windows: loads 'nethack_jp.dll' or 'nethack_en.dll'
  /// On iOS: loads Dynamic Framework 'nethack_jp.framework/nethack_jp' or 'nethack_en.framework/nethack_en'
  static DynamicLibrary loadCore({String langCode = 'ja'}) {
    if (_loadedLibrary != null && _currentLanguage == langCode) {
      return _loadedLibrary!;
    }

    _currentLanguage = langCode;

    if (Platform.isIOS) {
      final frameworkPath = getLibraryName(langCode: langCode, platformOverride: 'ios');
      try {
        _loadedLibrary = DynamicLibrary.open(frameworkPath);
      } catch (e) {
        _loadedLibrary = DynamicLibrary.process();
      }
    } else {
      final libraryName = getLibraryName(langCode: langCode);
      _loadedLibrary = DynamicLibrary.open(libraryName);
    }

    return _loadedLibrary!;
  }
}
