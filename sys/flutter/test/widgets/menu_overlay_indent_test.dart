import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_screen.dart';

void main() {
  group('ダンジョン概要およびメニューのインデント調整（Dedent）テスト', () {
    test('ダンジョン概要の階層行（先頭3スペース）と詳細行（先頭6スペース）から共通最小インデント3スペースが削られ、0スペース/3スペースに調整されること', () {
      final menuItems = [
        // カテゴリ（ダンジョン名）
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 1, text: '運命の大迷宮: 1階から50階', preselected: 0, color: 0, tile: -1),
        // 階層行（先頭3スペース）
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '   1階:', preselected: 0, color: 0, tile: -1),
        // 詳細行（先頭6スペース）
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '      店: 雑貨屋 (1個)', preselected: 0, color: 0, tile: -1),
        // 階層行（先頭3スペース）
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '   2階:', preselected: 0, color: 0, tile: -1),
        // 詳細行（先頭6スペース）
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '      階段', preselected: 0, color: 0, tile: -1),
      ];

      int minLeadingSpaces = 999;
      for (final item in menuItems) {
        if (item.attr > 0 || item.text.trim().isEmpty) continue;
        int spaces = 0;
        while (spaces < item.text.length && item.text[spaces] == ' ') {
          spaces++;
        }
        if (spaces < minLeadingSpaces) {
          minLeadingSpaces = spaces;
        }
      }
      expect(minLeadingSpaces, equals(3));

      String adjustIndent(String rawText, int minSpaces) {
        if (minSpaces <= 0) return rawText.trimRight();
        int spaces = 0;
        while (spaces < rawText.length && rawText[spaces] == ' ') {
          spaces++;
        }
        int spacesToRemove = spaces < minSpaces ? spaces : minSpaces;
        return rawText.substring(spacesToRemove).trimRight();
      }

      expect(adjustIndent(menuItems[1].text, minLeadingSpaces), equals('1階:'));
      expect(adjustIndent(menuItems[2].text, minLeadingSpaces), equals('   店: 雑貨屋 (1個)'));
      expect(adjustIndent(menuItems[3].text, minLeadingSpaces), equals('2階:'));
      expect(adjustIndent(menuItems[4].text, minLeadingSpaces), equals('   階段'));
    });

    test('通常メニュー（先頭0スペースから始まる）では minLeadingSpaces が 0 となりテキストが維持されること', () {
      final menuItems = [
        MenuItemData(ident: 1, accelerator: 97, groupacc: 0, attr: 0, text: 'a - 呪われていない食品', preselected: 0, color: 0, tile: -1),
        MenuItemData(ident: 2, accelerator: 98, groupacc: 0, attr: 0, text: 'b - 魔法の短剣', preselected: 0, color: 0, tile: -1),
      ];

      int minLeadingSpaces = 999;
      for (final item in menuItems) {
        if (item.attr > 0 || item.text.trim().isEmpty) continue;
        int spaces = 0;
        while (spaces < item.text.length && item.text[spaces] == ' ') {
          spaces++;
        }
        if (spaces < minLeadingSpaces) {
          minLeadingSpaces = spaces;
        }
      }
      expect(minLeadingSpaces, equals(0));
    });
  });
}
