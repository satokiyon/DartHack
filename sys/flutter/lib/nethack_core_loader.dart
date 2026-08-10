import 'dart:ffi';
import 'dart:io';

/// Dynamic Core Loader for Bilingual NetHack (EN / JP)
class NetHackCoreLoader {
  static DynamicLibrary? _loadedLibrary;
  static String? _currentLanguage;

  /// Returns the current active language code ('ja' or 'en')
  static String get currentLanguage => _currentLanguage ?? 'ja';

  /// Loads the appropriate NetHack C-core shared library based on [langCode].
  /// On Android: loads 'libnethack_jp.so' or 'libnethack_en.so'
  /// On iOS: loads Dynamic Framework 'nethack_jp.framework/nethack_jp' or 'nethack_en.framework/nethack_en'
  static DynamicLibrary loadCore({String langCode = 'ja'}) {
    if (_loadedLibrary != null && _currentLanguage == langCode) {
      return _loadedLibrary!;
    }

    _currentLanguage = langCode;
    final isJp = (langCode == 'ja');

    if (Platform.isAndroid) {
      final libraryName = isJp ? 'libnethack_jp.so' : 'libnethack_en.so';
      try {
        _loadedLibrary = DynamicLibrary.open(libraryName);
      } catch (e) {
        // Fallback for single library or legacy build
        _loadedLibrary = DynamicLibrary.open('libnethack.so');
      }
    } else if (Platform.isIOS) {
      final frameworkPath = isJp
          ? 'Frameworks/nethack_jp.framework/nethack_jp'
          : 'Frameworks/nethack_en.framework/nethack_en';
      try {
        _loadedLibrary = DynamicLibrary.open(frameworkPath);
      } catch (e) {
        _loadedLibrary = DynamicLibrary.process();
      }
    } else {
      // Desktop / Other platforms
      final libraryName = isJp ? 'nethack_jp' : 'nethack_en';
      _loadedLibrary = DynamicLibrary.open(libraryName);
    }

    return _loadedLibrary!;
  }
}
