import 'dart:io';
import 'package:flutter/material.dart';

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
  String _errorMessage = "";

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
          _errorMessage = "defaults.nh が見つかりませんでした。";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "ファイルの読み込みエラー: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFile() async {
    try {
      final file = File(widget.defaultsFilePath);
      await file.writeAsString(_controller.text, flush: true);
      setState(() {
        _hasChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("defaults.nh を保存しました。")),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("保存エラー"),
            content: Text("ファイルを保存できませんでした。\n$e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("変更の破棄"),
            content: const Text("編集内容が保存されていません。破棄して戻りますか？"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("キャンセル"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("破棄"),
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
          title: const Text("defaults.nh を編集"),
          actions: [
            if (!_isLoading && _errorMessage.isEmpty)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: "保存",
                onPressed: _saveFile,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _errorMessage,
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
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "※ defaults.nh の編集内容を反映するには新規ゲームの開始が必要です",
                                style: TextStyle(color: Colors.amber, fontSize: 13),
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
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "オプションを入力してください...",
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
