import 'dart:io';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class DefaultsEditor extends StatefulWidget {
  final String defaultsFilePath;

  const DefaultsEditor({super.key, required this.defaultsFilePath});

  @override
  State<DefaultsEditor> createState() => _DefaultsEditorState();
}

class _DefaultsEditorState extends State<DefaultsEditor> {
  late TextEditingController _controller;
  bool _isLoading = true;
  bool _hasChanges = false;
  String? _errorMessageKey;
  String? _errorParam;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.defaultsFilePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _controller.text = content;
          _isLoading = false;
          _hasChanges = false;
        });
      } else {
        setState(() {
          _errorMessageKey = 'defaultsNotFound';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessageKey = 'fileReadError';
        _errorParam = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFile() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final file = File(widget.defaultsFilePath);
      await file.writeAsString(_controller.text, flush: true);
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.defaultsSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.saveErrorTitle),
            content: Text(l10n.saveErrorMsg(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              )
            ],
          ),
        );
      }
    }
  }

  void _formatContent() {
    final lines = _controller.text.split('\n');
    final formattedLines = <String>[];
    bool modified = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('OPTIONS=') && !trimmed.startsWith('#')) {
        final prefix = line.substring(0, line.indexOf('OPTIONS=') + 'OPTIONS='.length);
        final content = line.substring(line.indexOf('OPTIONS=') + 'OPTIONS='.length);

        final buffer = StringBuffer();
        final tokens = <String>[];
        bool inQuote = false;

        for (int i = 0; i < content.length; i++) {
          final char = content[i];
          if (char == '"' || char == "'") {
            inQuote = !inQuote;
            buffer.write(char);
          } else if (char == ',' && !inQuote) {
            tokens.add(buffer.toString());
            buffer.clear();
          } else {
            buffer.write(char);
          }
        }
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
        }

        final cleanedTokens = tokens.map((tok) => tok.trim()).where((tok) => tok.isNotEmpty).toList();
        final newLine = '$prefix${cleanedTokens.join(', ')}';
        if (newLine != line) {
          modified = true;
          formattedLines.add(newLine);
          continue;
        }
      }
      formattedLines.add(line);
    }

    if (modified) {
      setState(() {
        _controller.text = formattedLines.join('\n');
        _hasChanges = true;
      });
      if (mounted) {
        final isJp = Localizations.localeOf(context).languageCode == 'ja';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isJp ? 'defaults.nh の記述を整頓しました（保存ボタンで反映されます）' : 'Formatted defaults.nh OPTIONS (press Save to apply)'),
          ),
        );
      }
    } else {
      if (mounted) {
        final isJp = Localizations.localeOf(context).languageCode == 'ja';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isJp ? '整頓が必要な OPTIONS= 行はありません' : 'No OPTIONS= lines required formatting'),
          ),
        );
      }
    }
  }

  String _getErrorMessage(AppLocalizations l10n) {
    if (_errorMessageKey == 'defaultsNotFound') {
      return l10n.defaultsNotFound;
    } else if (_errorMessageKey == 'fileReadError') {
      return l10n.fileReadError(_errorParam ?? '');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errMsg = _getErrorMessage(l10n);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.discardChangesTitle),
            content: Text(l10n.discardChangesMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.discard),
              ),
            ],
          ),
        );
        if (discard == true && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editDefaultsTitle),
          actions: [
            if (!_isLoading && errMsg.isEmpty) ...[
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: Localizations.localeOf(context).languageCode == 'ja' ? '記述の整頓（フォーマット）' : 'Format OPTIONS',
                onPressed: _formatContent,
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: l10n.saveTooltip,
                onPressed: _saveFile,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : errMsg.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        errMsg,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.amber.withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.defaultsEditNotice,
                                style: const TextStyle(color: Colors.amber, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          color: Colors.grey[950],
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: l10n.enterOptionHint,
                            ),
                            onChanged: (val) {
                              if (!_hasChanges) {
                                setState(() {
                                  _hasChanges = true;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

