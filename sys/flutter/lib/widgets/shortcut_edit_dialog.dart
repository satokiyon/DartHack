import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/ext_cmd_entry.dart';
import '../nethack_cmd_panel.dart';

void showShortcutEditDialog({
  required BuildContext context,
  required int index,
  required List<ExtCmdEntry> extCmdList,
  required VoidCallback onSaved,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isJp = AppLocalizations.of(context)?.localeName == 'ja';

  final List<Map<String, String>> extCommands = [];
  for (final entry in extCmdList) {
    var cmd = entry.command;
    if (!cmd.startsWith('#') && !cmd.startsWith('?')) {
      cmd = '#$cmd';
    }
    extCommands.add({
      'command': cmd,
      'description': entry.description,
    });
  }

  final shortcutLabelsJp = [
    "左上ボタン (0)", "上中央ボタン (1)", "右上ボタン (2)",
    "中段左ボタン (3)", "中段中央ボタン (4)", "中段右ボタン (5)",
    "下段左ボタン (6)", "下段中央ボタン (7)", "下段右ボタン (8)"
  ];
  final shortcutLabelsEn = [
    "Top-Left (0)", "Top-Center (1)", "Top-Right (2)",
    "Mid-Left (3)", "Mid-Center (4)", "Mid-Right (5)",
    "Btm-Left (6)", "Btm-Center (7)", "Btm-Right (8)"
  ];
  final shortcutName = isJp ? shortcutLabelsJp[index] : shortcutLabelsEn[index];

  SharedPreferences.getInstance().then((prefs) {
    final defaultShortcuts = [
      'i', '/', '#terrain', '#therecmdmenu', '#herecmdmenu', '#chat', '#chronicle', '#overview', r'\\e'
    ];
    final currentVal = prefs.getString('shortcut_btn_$index') ?? defaultShortcuts[index];
    final parsed = CmdItem.parseCmds(currentVal);
    final currentCmdItem = parsed.isNotEmpty ? parsed.first : CmdItem(command: currentVal);

    final controller = TextEditingController(text: currentCmdItem.command);
    final labelController = TextEditingController(text: currentCmdItem.label);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Text(l10n.editShortcutTitle(shortcutName)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.shortcutHint,
                helperText: l10n.shortcutHelper,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Enter'),
                  onPressed: () => controller.text = r'\n',
                ),
                ActionChip(
                  label: const Text('Space'),
                  onPressed: () => controller.text = r'\s',
                ),
                ActionChip(
                  label: const Text('Esc'),
                  onPressed: () => controller.text = r'\e',
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                showDialog(
                  context: dialogContext,
                  builder: (innerContext) {
                    String filterText = '';
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        final filtered = extCommands.where((item) {
                          final cmd = (item['command'] ?? '').toLowerCase();
                          final desc = (item['description'] ?? '').toLowerCase();
                          final query = filterText.toLowerCase();
                          return cmd.contains(query) || desc.contains(query);
                        }).toList();

                        return AlertDialog(
                          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          title: Text(l10n.menuExtCmds),
                          content: SizedBox(
                            width: double.maxFinite,
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    hintText: l10n.searchCmdOrDesc,
                                    prefixIcon: const Icon(Icons.search),
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      filterText = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            l10n.noCmdFound,
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: filtered.length,
                                          itemBuilder: (context, idx) {
                                            final item = filtered[idx];
                                            final cmd = item['command'] ?? '';
                                            final desc = item['description'] ?? '';
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.white12, width: 1.0),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                child: Material(
                                                  color: const Color(0xFF2C2C2C),
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: ListTile(
                                                    title: Text(
                                                      cmd,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    subtitle: desc.isNotEmpty
                                                        ? Text(
                                                            desc,
                                                            style: const TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: 12,
                                                            ),
                                                          )
                                                        : null,
                                                    onTap: () {
                                                      controller.text = cmd;
                                                      Navigator.pop(innerContext);
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(innerContext),
                              child: Text(l10n.cancel),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              child: Text(isJp ? "拡張コマンドから選択..." : "Select from extended commands..."),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: isJp ? "表示ラベル (任意)" : "Custom Label (optional)",
                hintText: isJp ? "例: 道具, 地形, #メニュー" : "e.g. Items, Terrain, Menu",
                helperText: isJp ? "空にするとコマンド名がそのまま表示されます" : "Leave empty to use command name",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final cmdVal = controller.text.trim();
              final labelVal = labelController.text.trim();
              if (cmdVal.isNotEmpty || labelVal.isNotEmpty) {
                final serialized = CmdItem.serializeCmds([CmdItem(command: cmdVal, label: labelVal)]);
                prefs.setString('shortcut_btn_$index', serialized).then((_) {
                  onSaved();
                });
              }
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  });
}
