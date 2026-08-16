import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/game_enums.dart';
import '../../utils/utf8_length_limiting_formatter.dart';

class AskNameOverlay extends StatefulWidget {
  final TextEditingController nameController;
  final int maxChars;
  final List<String> saves;
  final PlayMode initialPlayMode;
  final Function(PlayMode mode, String? name) onSubmit;
  final double bottomInset;

  const AskNameOverlay({
    super.key,
    required this.nameController,
    required this.maxChars,
    required this.saves,
    required this.initialPlayMode,
    required this.onSubmit,
    required this.bottomInset,
  });

  @override
  State<AskNameOverlay> createState() => _AskNameOverlayState();
}

class _AskNameOverlayState extends State<AskNameOverlay> {
  late PlayMode _selectedPlayMode;
  String _previousCustomName = "";

  @override
  void initState() {
    super.initState();
    _selectedPlayMode = widget.initialPlayMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String modeDescText;
    Color modeDescBorderColor;
    switch (_selectedPlayMode) {
      case PlayMode.normal:
        modeDescText = l10n.modeDescNormal;
        modeDescBorderColor = Colors.amber.withValues(alpha: 0.4);
        break;
      case PlayMode.explore:
        modeDescText = l10n.modeDescExplore;
        modeDescBorderColor = Colors.lightBlueAccent.withValues(alpha: 0.4);
        break;
      case PlayMode.wizard:
        modeDescText = l10n.modeDescWizard;
        modeDescBorderColor = Colors.purpleAccent.withValues(alpha: 0.4);
        break;
    }

    final askNameBytes = utf8.encode(widget.nameController.text).length;
    final maxAskNameBytes = widget.maxChars > 0 ? widget.maxChars - 1 : 31;
    final isAskNameOverflow = askNameBytes > maxAskNameBytes;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.84),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, widget.bottomInset),
          child: Center(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF141A22),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 18, color: Colors.amber[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.whoAreYou,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.nameController,
                        autofocus: true,
                        enabled: _selectedPlayMode != PlayMode.wizard,
                        inputFormatters: [Utf8LengthLimitingTextInputFormatter(maxAskNameBytes)],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _selectedPlayMode == PlayMode.wizard
                              ? const Color(0xFF1E2530)
                              : const Color(0xFF0E1117),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          counterText: l10n.bytesCount(askNameBytes, maxAskNameBytes),
                          counterStyle: TextStyle(
                            color: isAskNameOverflow ? Colors.red : Colors.white70,
                            fontWeight: isAskNameOverflow ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                        onSubmitted: (val) {
                          if (!isAskNameOverflow) {
                            widget.onSubmit(_selectedPlayMode, val);
                          }
                        },
                      ),
                      if (isAskNameOverflow) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.nameTooLong(maxAskNameBytes),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (widget.saves.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l10n.savedGames, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 140),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.saves.length,
                            itemBuilder: (context, index) {
                              final name = widget.saves[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  leading: const Icon(Icons.account_circle, color: Colors.lightBlueAccent, size: 20),
                                  dense: true,
                                  onTap: () {
                                    if (_selectedPlayMode == PlayMode.wizard) {
                                      _previousCustomName = name;
                                    } else {
                                      widget.nameController.text = name;
                                      _previousCustomName = name;
                                    }
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(l10n.playMode, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      SegmentedButton<PlayMode>(
                        segments: [
                          ButtonSegment<PlayMode>(
                            value: PlayMode.normal,
                            label: Text(l10n.playModeNormal, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.emoji_events_outlined, size: 15),
                          ),
                          ButtonSegment<PlayMode>(
                            value: PlayMode.explore,
                            label: Text(l10n.playModeExplore, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.search, size: 15),
                          ),
                          ButtonSegment<PlayMode>(
                            value: PlayMode.wizard,
                            label: Text(l10n.playModeWizard, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.auto_fix_high, size: 15),
                          ),
                        ],
                        selected: {_selectedPlayMode},
                        onSelectionChanged: (Set<PlayMode> newSelection) {
                          final newMode = newSelection.first;
                          setState(() {
                            if (newMode == PlayMode.wizard) {
                              if (_selectedPlayMode != PlayMode.wizard) {
                                _previousCustomName = widget.nameController.text;
                              }
                              widget.nameController.text = "wizard";
                            } else {
                              if (_selectedPlayMode == PlayMode.wizard) {
                                widget.nameController.text = _previousCustomName.isNotEmpty ? _previousCustomName : "Player";
                              }
                            }
                            _selectedPlayMode = newMode;
                          });
                        },
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: modeDescBorderColor),
                        ),
                        child: Text(
                          modeDescText,
                          style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => widget.onSubmit(_selectedPlayMode, null),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isAskNameOverflow
                                ? null
                                : () => widget.onSubmit(_selectedPlayMode, widget.nameController.text),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[500]),
                            child: Text(l10n.startGame),
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
      ),
    );
  }
}
