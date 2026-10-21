import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_core_loader.dart';

void main() {
  group('NetHackCoreLoader Tests', () {
    setUp(() {
      NetHackCoreLoader.resetForTesting();
    });

    tearDown(() {
      NetHackCoreLoader.resetForTesting();
    });

    test('言語初期値が ja であること', () {
      expect(NetHackCoreLoader.currentLanguage, 'ja');
    });

    test('アセットサブディレクトリ解決 (ja -> jp, en -> en)', () {
      expect(NetHackCoreLoader.getAssetSubdir('ja'), 'jp');
      expect(NetHackCoreLoader.getAssetSubdir('en'), 'en');
      expect(NetHackCoreLoader.getAssetSubdir(), 'jp'); // デフォルト
    });

    group('Android プラットフォームのライブラリ名解決', () {
      test('日本語版 (ja) で libnethack_jp.so が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'ja',
          platformOverride: 'android',
        );
        expect(libName, 'libnethack_jp.so');
      });

      test('英語版 (en) で libnethack_en.so が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'en',
          platformOverride: 'android',
        );
        expect(libName, 'libnethack_en.so');
      });
    });

    group('Windows プラットフォームのライブラリ名解決', () {
      test('日本語版 (ja) で nethack_jp.dll が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'ja',
          platformOverride: 'windows',
        );
        expect(libName, 'nethack_jp.dll');
      });

      test('英語版 (en) で nethack_en.dll が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'en',
          platformOverride: 'windows',
        );
        expect(libName, 'nethack_en.dll');
      });
    });

    group('iOS プラットフォームのフレームワークパス解決', () {
      test('日本語版 (ja) で正しい framework パスが返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'ja',
          platformOverride: 'ios',
        );
        expect(libName, 'Frameworks/nethack_jp.framework/nethack_jp');
      });

      test('英語版 (en) で正しい framework パスが返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'en',
          platformOverride: 'ios',
        );
        expect(libName, 'Frameworks/nethack_en.framework/nethack_en');
      });
    });

    group('その他のデスクトップ/POSIX プラットフォームのライブラリ名解決', () {
      test('日本語版 (ja) で nethack_jp が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'ja',
          platformOverride: 'other',
        );
        expect(libName, 'nethack_jp');
      });

      test('英語版 (en) で nethack_en が返ること', () {
        final libName = NetHackCoreLoader.getLibraryName(
          langCode: 'en',
          platformOverride: 'other',
        );
        expect(libName, 'nethack_en');
      });
    });
  });
}

