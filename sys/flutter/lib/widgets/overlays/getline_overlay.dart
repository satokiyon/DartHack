import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ext_cmd_entry.dart';
import '../../utils/utf8_length_limiting_formatter.dart';

class GetLineOverlay extends StatefulWidget {
  final String prompt;
  final TextEditingController inputController;
  final List<ExtCmdEntry> extCmdList;
  final Function(String? result) onSubmit;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;
  final bool Function(String prompt) isCallOrNamePrompt;

  const GetLineOverlay({
    super.key,
    required this.prompt,
    required this.inputController,
    required this.extCmdList,
    required this.onSubmit,
    required this.onShowMsgHistory,
    required this.bottomInset,
    required this.isCallOrNamePrompt,
  });

  @override
  State<GetLineOverlay> createState() => _GetLineOverlayState();
}

class _GetLineOverlayState extends State<GetLineOverlay> {
  late TextEditingController _extCmdFilterController;
  late List<ExtCmdEntry> _filteredExtCmds;

  @override
  void initState() {
    super.initState();
    _extCmdFilterController = TextEditingController();
    _filteredExtCmds = List.from(widget.extCmdList);
  }

  @override
  void dispose() {
    _extCmdFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isExtCmd = widget.extCmdList.isNotEmpty;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.84),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomInset),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber[300]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.prompt,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                    const SizedBox(height: 12),
                    TextField(
                      controller: widget.inputController,
                      autofocus: true,
                      inputFormatters: [Utf8LengthLimitingTextInputFormatter(100)],
                      decoration: InputDecoration(
                        hintText: l10n.enterText,
                        filled: true,
                        fillColor: const Color(0xFF0E1117),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counter: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: widget.inputController,
                          builder: (context, value, child) {
                            final byteCount = utf8.encode(value.text).length;
                            return Text(
                              l10n.bytesCount(byteCount, 100),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        widget.onSubmit(val);
                      },
                    ),
                    if (isExtCmd) ...[
                      const SizedBox(height: 8),
                      Text(l10n.selectExtCmd, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _extCmdFilterController,
                        decoration: InputDecoration(
                          hintText: l10n.filterCmds,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF0E1117),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) {
                          final query = val.toLowerCase();
                          setState(() {
                            _filteredExtCmds = widget.extCmdList
                                .where((entry) {
                                  return entry.command.toLowerCase().contains(query)
                                      || entry.description.toLowerCase().contains(query);
                                })
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredExtCmds.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredExtCmds[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(
                                    entry.command,
                                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                                  ),
                                  subtitle: entry.description.isNotEmpty
                                      ? Text(
                                          entry.description,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        )
                                      : null,
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  onTap: () {
                                    widget.inputController.text = entry.command;
                                    widget.onSubmit(entry.command);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.isCallOrNamePrompt(widget.prompt))
                          ElevatedButton.icon(
                            onPressed: widget.onShowMsgHistory,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: Text(l10n.history),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[900],
                              foregroundColor: Colors.amber[200],
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => widget.onSubmit(null),
                              child: Text(l10n.cancel),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => widget.onSubmit(widget.inputController.text),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[500]),
                              child: Text(l10n.confirm),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
