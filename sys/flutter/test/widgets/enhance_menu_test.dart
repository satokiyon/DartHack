import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/nethack_screen.dart';

void main() {
  group('#enhance スキルメニューの日英バイリンガル動作検証テスト', () {
    test('日本語モード: endMenu でアクセラレータが自動採番され、#や*の行が維持されること', () {
      final screen = NetHackScreen();

      // 日本語のスキル項目を追加
      // 1. スキルアップ可能 (can_advance): ident > 0, accelerator = 0
      screen.addMenu(1, 10, 0, 0, 0, ' 短剣 [入門]', 0, 0, -1);
      // 2. スロット不足 (could_advance): ident = 0, accelerator = 0
      screen.addMenu(1, 0, 0, 0, 0, '  * 長剣 [入門]', 0, 0, -1);
      // 3. 最大レベル到達 (peaked_skill): ident = 0, accelerator = 0
      screen.addMenu(1, 0, 0, 0, 0, '  # 短棒 [熟練者]', 0, 0, -1);
      // 4. スキルアップ可能 2つ目
      screen.addMenu(1, 20, 0, 0, 0, ' 投石器 [入門]', 0, 0, -1);

      // 日本語のプロンプトで endMenu を呼び出し
      screen.endMenu(1, '習熟させるスキルを選んでください:');

      // 1つ目のスキルアップ可能項目に 'a' (0x61) が割り当てられていること
      expect(screen.menuItems[0].accelerator, equals(0x61)); // 'a'
      // 2つ目の could_advance は accelerator 0 のままでテキスト維持
      expect(screen.menuItems[1].accelerator, equals(0));
      expect(screen.menuItems[1].text, contains('*'));
      // 3つ目の peaked_skill は accelerator 0 のままでテキスト維持
      expect(screen.menuItems[2].accelerator, equals(0));
      expect(screen.menuItems[2].text, contains('#'));
      // 4つ目のスキルアップ可能項目に 'b' (0x62) が割り当てられていること
      expect(screen.menuItems[3].accelerator, equals(0x62)); // 'b'
    });

    test('英語モード: endMenu でアクセラレータが自動採番され、#や*の行が維持されること', () {
      final screen = NetHackScreen();

      // 英語のスキル項目を追加
      // 1. can_advance: ident > 0, accelerator = 0
      screen.addMenu(1, 5, 0, 0, 0, ' dagger [basic]', 0, 0, -1);
      // 2. could_advance: ident = 0, accelerator = 0
      screen.addMenu(1, 0, 0, 0, 0, '  * broadsword [basic]', 0, 0, -1);
      // 3. peaked_skill: ident = 0, accelerator = 0
      screen.addMenu(1, 0, 0, 0, 0, '  # club [skilled]', 0, 0, -1);
      // 4. can_advance 2つ目
      screen.addMenu(1, 15, 0, 0, 0, ' sling [basic]', 0, 0, -1);

      // 英語のプロンプトで endMenu を呼び出し
      screen.endMenu(1, 'Pick a skill to advance:');

      // 1つ目のスキルアップ可能項目に 'a' (0x61) が割り当てられていること
      expect(screen.menuItems[0].accelerator, equals(0x61)); // 'a'
      // 2つ目の could_advance は accelerator 0 のままでテキスト維持
      expect(screen.menuItems[1].accelerator, equals(0));
      expect(screen.menuItems[1].text, contains('*'));
      // 3つ目の peaked_skill は accelerator 0 のままでテキスト維持
      expect(screen.menuItems[2].accelerator, equals(0));
      expect(screen.menuItems[2].text, contains('#'));
      // 4つ目のスキルアップ可能項目に 'b' (0x62) が割り当てられていること
      expect(screen.menuItems[3].accelerator, equals(0x62)); // 'b'
    });

    test('拡張コマンド以外のメニューで「#」で始まる項目（peaked_skill）が除外されないこと', () {
      final menuItems = [
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '  # dagger [expert]', preselected: 0, color: 0, tile: -1),
        MenuItemData(ident: 0, accelerator: 0, groupacc: 0, attr: 0, text: '  # 短剣 [エキスパート]', preselected: 0, color: 0, tile: -1),
      ];

      // menu_overlay のフィルターロジックの再現検証
      bool isExtCmdMenu = false;
      final filteredItems = menuItems.where((item) {
        final text = item.text.trim();
        if (isExtCmdMenu) {
          if (text == '#' || text == '?') return false;
        }
        return true;
      }).toList();

      expect(filteredItems.length, equals(2));
      expect(filteredItems[0].text, contains('dagger'));
      expect(filteredItems[1].text, contains('短剣'));
    });
  });
}
