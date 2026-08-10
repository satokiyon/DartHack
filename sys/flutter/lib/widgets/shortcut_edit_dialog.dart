import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ext_cmd_entry.dart';
import '../nethack_cmd_panel.dart';

void showShortcutEditDialog({
  required BuildContext context,
  required int index,
  required List<ExtCmdEntry> extCmdList,
  required VoidCallback onSaved,
}) {
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

  final shortcutLabels = [
    "左上ボタン (0)", "上中央ボタン (1)", "右上ボタン (2)",
    "中段左ボタン (3)", "中段中央ボタン (4)", "中段右ボタン (5)",
    "下段左ボタン (6)", "下段中央ボタン (7)", "下段右ボタン (8)"
  ];

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
        title: Text("${shortcutLabels[index]} を編集"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "例: i, d, #terrain, #herecmdmenu 等",
                  helperText: "#で始まるものは拡張コマンドとして入力送信されます",
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
                            title: const Text("拡張コマンド"),
                            content: SizedBox(
                              width: double.maxFinite,
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    decoration: const InputDecoration(
                                      hintText: "コマンド名や説明で検索...",
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                      border: OutlineInputBorder(),
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
                                        ? const Center(
                                            child: Text(
                                              "見つかりませんでした",
                                              style: TextStyle(color: Colors.grey),
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
                                child: const Text("キャンセル"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                child: const Text("拡張コマンドから選択..."),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: "表示ラベル (任意)",
                  hintText: "例: 道具, 地形, #メニュー",
                  helperText: "空にするとコマンド名がそのまま表示されます",
                ),
              ),
            ],
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("キャンセル"),
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
            child: const Text("保存"),
          ),
        ],
      ),
    );
  });
}
