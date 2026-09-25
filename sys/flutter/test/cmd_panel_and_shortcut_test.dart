import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:darthack/l10n/app_localizations.dart';
import 'package:darthack/nethack_cmd_panel.dart';
import 'package:darthack/nethack_shortcut_pad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetHackCmdPanel & ShortcutPad 仕様検証テスト', () {
    test('デフォルトパネルが4枚（標準・戦闘・道具・情報）正しく定義されていること', () {
      expect(NetHackCmdPanel.defaultPanels.length, 4);
      expect(NetHackCmdPanel.defaultPanels[0]['nameJp'], '標準');
      expect(NetHackCmdPanel.defaultPanels[0]['nameEn'], 'Default');
      expect(NetHackCmdPanel.defaultPanels[1]['nameJp'], '戦闘');
      expect(NetHackCmdPanel.defaultPanels[1]['nameEn'], 'Combat');
      expect(NetHackCmdPanel.defaultPanels[2]['nameJp'], '道具');
      expect(NetHackCmdPanel.defaultPanels[2]['nameEn'], 'Items');
      expect(NetHackCmdPanel.defaultPanels[3]['nameJp'], '情報');
      expect(NetHackCmdPanel.defaultPanels[3]['nameEn'], 'Info');

      // 最大パネル数が 7 であること
      expect(NetHackCmdPanel.maxPanelCount, 7);
    });

    test('標準パネルの内容に 20s が含まれ、重複コマンド（t, f, x, a 等の戦闘特化）および除外対象が含まれないこと', () {
      final defaultCmds = NetHackCmdPanel.defaultPanels[0]['cmds']!;
      final items = CmdItem.parseCmds(defaultCmds).map((e) => e.command).toList();

      // 20s が含まれていること
      expect(items.contains('20s'), isTrue);
      // ユーザー指示で追加されたコマンド
      expect(items.contains('t'), isTrue);
      expect(items.contains('f'), isTrue);
      expect(items.contains('x'), isTrue);
      expect(items.contains('a'), isTrue);
      // 削除されたコマンド（i, o, ,, F, ^x, ^o, ? 等）
      expect(items.contains('i'), isFalse);
      expect(items.contains('o'), isFalse);
      expect(items.contains(','), isFalse);
      expect(items.contains('F'), isFalse);
      expect(items.contains('^x'), isFalse);
      expect(items.contains('^o'), isFalse);
      expect(items.contains('?'), isFalse);
    });

    test('デフォルトショートカットが新 9 枠（3x3）正しく定義されていること', () {
      expect(NetHackShortcutPad.defaultShortcuts.length, 9);
      expect(NetHackShortcutPad.defaultShortcuts, [
        'i', '/', ',',
        '#therecmdmenu', '#herecmdmenu', '#chat',
        'e', '^a', r'\e',
      ]);
    });

    test('CmdItem.getEffectiveLabel の日本語ラベル辞書引き検証', () {
      // 20s -> '20探索'
      final item20s = const CmdItem(command: '20s');
      expect(item20s.getEffectiveLabel(showLabel: true, langCode: 'ja'), '20探索');

      // v -> '実績'
      final itemV = const CmdItem(command: 'v');
      expect(itemV.getEffectiveLabel(showLabel: true, langCode: 'ja'), '実績');

      // ^o -> '迷宮概要'
      final itemCtrlO = const CmdItem(command: '^o');
      expect(itemCtrlO.getEffectiveLabel(showLabel: true, langCode: 'ja'), '迷宮概要');

      // #overview -> '迷宮概要'
      final itemOverview = const CmdItem(command: '#overview');
      expect(itemOverview.getEffectiveLabel(showLabel: true, langCode: 'ja'), '迷宮概要');

      // #chronicle -> '実績'
      final itemChronicle = const CmdItem(command: '#chronicle');
      expect(itemChronicle.getEffectiveLabel(showLabel: true, langCode: 'ja'), '実績');

      // #therecmdmenu -> 'そこ'
      final itemThere = const CmdItem(command: '#therecmdmenu');
      expect(itemThere.getEffectiveLabel(showLabel: true, langCode: 'ja'), 'そこ');

      // #herecmdmenu -> 'ここ'
      final itemHere = const CmdItem(command: '#herecmdmenu');
      expect(itemHere.getEffectiveLabel(showLabel: true, langCode: 'ja'), 'ここ');

      // i -> '持ち物'
      final itemI = const CmdItem(command: 'i');
      expect(itemI.getEffectiveLabel(showLabel: true, langCode: 'ja'), '持ち物');

      // #inventory -> '持ち物'
      final itemInv = const CmdItem(command: '#inventory');
      expect(itemInv.getEffectiveLabel(showLabel: true, langCode: 'ja'), '持ち物');

      // D -> '複数置'
      final itemD = const CmdItem(command: 'D');
      expect(itemD.getEffectiveLabel(showLabel: true, langCode: 'ja'), '複数置');

      // #droptype -> '複数置'
      final itemDropType = const CmdItem(command: '#droptype');
      expect(itemDropType.getEffectiveLabel(showLabel: true, langCode: 'ja'), '複数置');

      // 個別ラベルが設定されている場合は辞書引きより優先されること
      final customItem = const CmdItem(command: '20s', label: 'マイ探索');
      expect(customItem.getEffectiveLabel(showLabel: true, langCode: 'ja'), 'マイ探索');

      // showLabel が false の場合はコマンド名がそのまま返ること
      expect(item20s.getEffectiveLabel(showLabel: false, langCode: 'ja'), '20s');
    });

    test('CmdItem.getEffectiveLabel の英語ラベル辞書引き検証', () {
      final item20s = const CmdItem(command: '20s');
      expect(item20s.getEffectiveLabel(showLabel: true, langCode: 'en'), '20Srch');

      final itemV = const CmdItem(command: 'v');
      expect(itemV.getEffectiveLabel(showLabel: true, langCode: 'en'), 'Chron');

      final itemCtrlO = const CmdItem(command: '^o');
      expect(itemCtrlO.getEffectiveLabel(showLabel: true, langCode: 'en'), 'Overvw');

      final itemOverview = const CmdItem(command: '#overview');
      expect(itemOverview.getEffectiveLabel(showLabel: true, langCode: 'en'), 'Overvw');

      final itemThere = const CmdItem(command: '#therecmdmenu');
      expect(itemThere.getEffectiveLabel(showLabel: true, langCode: 'en'), 'There');

      final itemHere = const CmdItem(command: '#herecmdmenu');
      expect(itemHere.getEffectiveLabel(showLabel: true, langCode: 'en'), 'Here');
    });

    test('CmdItem.parseCmds における特殊キー \\e, \\n, \\s のパースおよびエスケープ保持検証', () {
      // 生の \e が "e" に化けず \e（Esc）としてパースされること
      final parsedRawEsc = CmdItem.parseCmds(r'\e');
      expect(parsedRawEsc.length, 1);
      expect(parsedRawEsc.first.command, r'\e');
      expect(parsedRawEsc.first.displayLabel, 'Esc');

      // \\e（シリアライズされたEsc）も \e としてパースされること
      final parsedEscapedEsc = CmdItem.parseCmds(r'\\e');
      expect(parsedEscapedEsc.length, 1);
      expect(parsedEscapedEsc.first.command, r'\e');
      expect(parsedEscapedEsc.first.displayLabel, 'Esc');

      // 複数コマンド内の \e も正しくパースされること
      final multiCmds = CmdItem.parseCmds(r't f Q \e M-m');
      expect(multiCmds.map((e) => e.command).toList(), ['t', 'f', 'Q', r'\e', 'M-m']);

      // 区切り文字のエスケープ（\| や \ ）が正常に機能すること
      final pipeCmd = CmdItem.parseCmds(r'foo\|bar|ラベル');
      expect(pipeCmd.length, 1);
      expect(pipeCmd.first.command, 'foo|bar');
      expect(pipeCmd.first.label, 'ラベル');
    });

    test('新規追加コマンド群（直接キー、#拡張コマンド、特殊キー）の日英既定ラベル検証', () {
      // Group A: 直接キー
      final directTests = {
        '[': ('鎧一覧', 'Armors'),
        '=': ('指輪一覧', 'Rings'),
        '(': ('道具一覧', 'Tools'),
        ')': ('武器一覧', 'Weapons'),
        '"': ('護符一覧', 'Amulet'),
        r'$': ('所持金', 'Gold'),
        'I': ('種別所持', 'TypeInv'),
        '@': ('自動拾い', 'AutoPick'),
        'V': ('版詳細', 'VerInfo'),
        'M-a': ('整理', 'Adjust'),
        'M-n': ('名付け', 'Name'),
        'M-X': ('探索Mode', 'Explore'),
        'M-v': ('版情報', 'Version'),
        'M-?': ('コマンド', 'CmdList'),
        '^r': ('再描画', 'Redraw'),
        '^_': ('再移動', 'ReTravel'),
        'm': ('メニュー', 'ReqMenu'),
        'G': ('走る', 'Run'),
        'g': ('急ぐ', 'Rush'),
        '|': ('所持スク', 'PermInv'),
        '`': ('既知種別', 'KwnClass'),
        r'\b': ('BS', 'BS'),
      };

      for (final entry in directTests.entries) {
        final item = CmdItem(command: entry.key);
        expect(item.getEffectiveLabel(showLabel: true, langCode: 'ja'), entry.value.$1,
            reason: 'Direct key ${entry.key} ja label mismatch');
        expect(item.getEffectiveLabel(showLabel: true, langCode: 'en'), entry.value.$2,
            reason: 'Direct key ${entry.key} en label mismatch');
      }

      // Group B: # 拡張コマンド
      final extTests = {
        '#pray': ('祈る', 'Pray'),
        '#eat': ('食べる', 'Eat'),
        '#loot': ('あさる', 'Loot'),
        '#dip': ('浸す', 'Dip'),
        '#enhance': ('強化', 'Enhan'),
        '#cast': ('詠唱', 'Cast'),
        '#open': ('開ける', 'Open'),
        '#force': ('こじ開', 'Force'),
        '#ride': ('乗る', 'Ride'),
        '#untrap': ('罠解除', 'Untrap'),
        '#search': ('捜索', 'Search'),
        '#quaff': ('飲む', 'Quaff'),
        '#read': ('読む', 'Read'),
        '#wield': ('構える', 'Wield'),
        '#swap': ('持ち替', 'Swap'),
        '#twoweapon': ('二刀流', 'TwoWep'),
        '#kick': ('蹴る', 'Kick'),
        '#teleport': ('テレポ', 'Tele'),
        '#quit': ('終了', 'Quit'),
        '#save': ('セーブ', 'Save'),
        '#options': ('設定', 'Option'),
        '#attributes': ('属性', 'Attrib'),
        '#conduct': ('禁忌', 'Cond'),
        '#genocided': ('虐殺', 'Geno'),
        '#vanquished': ('討伐', 'Vanq'),
        '#seeall': ('装備一覧', 'SeeAll'),
        '#seearmor': ('鎧一覧', 'Armors'),
        '#showgold': ('所持金', 'Gold'),
      };

      for (final entry in extTests.entries) {
        final item = CmdItem(command: entry.key);
        expect(item.getEffectiveLabel(showLabel: true, langCode: 'ja'), entry.value.$1,
            reason: 'Ext cmd ${entry.key} ja label mismatch');
        expect(item.getEffectiveLabel(showLabel: true, langCode: 'en'), entry.value.$2,
            reason: 'Ext cmd ${entry.key} en label mismatch');
      }

      // 未定義コマンド（ウィザードコマンド等）はコマンド名がそのまま返ること
      final wizCmd = const CmdItem(command: '#wizwish');
      expect(wizCmd.getEffectiveLabel(showLabel: true, langCode: 'ja'), '#wizwish');
      expect(wizCmd.getEffectiveLabel(showLabel: true, langCode: 'en'), '#wizwish');

      // [kbd] / [pad] は辞書未登録のためそのまま返ること
      final kbdCmd = const CmdItem(command: '[kbd]');
      expect(kbdCmd.getEffectiveLabel(showLabel: true, langCode: 'ja'), '[kbd]');
    });

    testWidgets('表示ラベル変更ヘルパー説明文の日英およびモード切替の文言検証', (tester) async {
      late AppLocalizations l10nJa;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Builder(
            builder: (context) {
              l10nJa = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10nEn = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      // 日本語
      expect(l10nJa.btnLabelHelperDefault, '空にすると既定のラベル（未定義時はコマンド名）が表示されます');
      expect(l10nJa.btnLabelHelperCommand, '空にするとコマンド名がそのまま表示されます');

      // 英語
      expect(l10nEn.btnLabelHelperDefault, 'Leave empty to use default label or command name');
      expect(l10nEn.btnLabelHelperCommand, 'Leave empty to use command name');
    });
  });
}
