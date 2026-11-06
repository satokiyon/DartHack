import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ext_cmd_entry.dart';
import 'dialog_recent_messages_box.dart';

/// GetLine オーバーレイでの Tab キーフォーカス対象
enum GetLineFocusTarget {
  none,
  input,
  history,
  cancel,
  confirm,
}

class GetLineOverlay extends StatefulWidget {
  final String prompt;
  final TextEditingController inputController;
  final List<ExtCmdEntry> extCmdList;
  final Function(String? result) onSubmit;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;
  final bool Function(String prompt) isCallOrNamePrompt;
  final List<String> recentMessages;

  const GetLineOverlay({
    super.key,
    required this.prompt,
    required this.inputController,
    required this.extCmdList,
    required this.onSubmit,
    required this.onShowMsgHistory,
    required this.bottomInset,
    required this.isCallOrNamePrompt,
    this.recentMessages = const [],
  });

  @override
  State<GetLineOverlay> createState() => GetLineOverlayState();
}

class GetLineOverlayState extends State<GetLineOverlay> {
  late TextEditingController _extCmdFilterController;
  late List<ExtCmdEntry> _filteredExtCmds;
  late FocusNode _inputFocusNode;
  late FocusNode _filterFocusNode;
  late ScrollController _listScrollController;
  int? _selectedCandidateIndex;
  GetLineFocusTarget _currentFocusTarget = GetLineFocusTarget.none;

  bool get _isExtCmd => widget.extCmdList.isNotEmpty;
  int get _maxBytes => widget.isCallOrNamePrompt(widget.prompt) ? 62 : 100;

  @override
  void initState() {
    super.initState();
    _extCmdFilterController = TextEditingController();
    _filteredExtCmds = List.from(widget.extCmdList);
    _inputFocusNode = FocusNode();
    _filterFocusNode = FocusNode();
    _listScrollController = ScrollController();
    _selectedCandidateIndex = null;
  }

  @override
  void didUpdateWidget(covariant GetLineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.extCmdList != oldWidget.extCmdList) {
      _updateFilteredExtCmds(_extCmdFilterController.text);
    }
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _filterFocusNode.dispose();
    _extCmdFilterController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _updateFilteredExtCmds(String val) {
    final query = val.toLowerCase();
    setState(() {
      _filteredExtCmds = widget.extCmdList.where((entry) {
        return entry.command.toLowerCase().contains(query) ||
            entry.description.toLowerCase().contains(query);
      }).toList();
      _selectedCandidateIndex = null;
    });
  }

  /// フォーカスレス物理キーボードからの文字追記
  void appendText(String text) {
    if (_isExtCmd) {
      final newText = _extCmdFilterController.text + text;
      _extCmdFilterController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _updateFilteredExtCmds(newText);
      return;
    }

    final current = widget.inputController.text;
    final selection = widget.inputController.selection;
    String newText;
    int newOffset;
    if (selection.isValid && selection.start >= 0 && selection.end >= selection.start) {
      newText = current.replaceRange(selection.start, selection.end, text);
      newOffset = selection.start + text.length;
    } else {
      newText = current + text;
      newOffset = newText.length;
    }
    if (utf8.encode(newText).length <= _maxBytes) {
      widget.inputController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  /// フォーカスレス物理キーボードからの1文字削除 (Backspace)
  void deleteChar() {
    final controller = _isExtCmd ? _extCmdFilterController : widget.inputController;
    final current = controller.text;
    if (current.isEmpty) return;

    final selection = controller.selection;
    String newText;
    int newOffset;
    if (selection.isValid && selection.start >= 0 && selection.end > selection.start) {
      newText = current.replaceRange(selection.start, selection.end, '');
      newOffset = selection.start;
    } else {
      final offset = (selection.isValid && selection.start > 0) ? selection.start : current.length;
      if (offset <= 0) return;
      newText = current.substring(0, offset - 1) + current.substring(offset);
      newOffset = offset - 1;
    }
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    if (_isExtCmd) {
      _updateFilteredExtCmds(newText);
    }
  }

  /// フォーカスレス物理キーボードからの全消去 (Delete)
  void clearText() {
    if (_isExtCmd) {
      _extCmdFilterController.clear();
      _updateFilteredExtCmds('');
    } else {
      widget.inputController.clear();
    }
  }

  /// 拡張コマンド候補の上下移動
  void moveCandidate(int delta) {
    if (!_isExtCmd || _filteredExtCmds.isEmpty) return;
    setState(() {
      if (_selectedCandidateIndex == null) {
        // 未選択時: 下キー (delta > 0) なら先頭、上キー (delta < 0) なら末尾を選択
        _selectedCandidateIndex = delta > 0 ? 0 : _filteredExtCmds.length - 1;
      } else {
        _selectedCandidateIndex =
            (_selectedCandidateIndex! + delta).clamp(0, _filteredExtCmds.length - 1);
      }
    });
    _scrollToSelectedCandidate();
  }

  void _scrollToSelectedCandidate() {
    if (!_listScrollController.hasClients || _selectedCandidateIndex == null) return;
    const itemHeight = 48.0;
    final targetOffset = _selectedCandidateIndex! * itemHeight;
    final currentOffset = _listScrollController.offset;
    final viewportHeight = _listScrollController.position.viewportDimension;
    final maxScroll = _listScrollController.position.maxScrollExtent;

    if (targetOffset < currentOffset) {
      _listScrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
      _listScrollController.animateTo(
        (targetOffset + itemHeight - viewportHeight).clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  /// 拡張コマンド候補リストのページ送り
  void pageScroll(int direction) {
    if (!_isExtCmd || !_listScrollController.hasClients) return;
    final viewport = _listScrollController.position.viewportDimension;
    final step = viewport > 0 ? viewport * 0.85 : 200.0;
    final nextOffset = (_listScrollController.offset + direction * step)
        .clamp(0.0, _listScrollController.position.maxScrollExtent);
    _listScrollController.animateTo(
      nextOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  /// Tab キーによる候補名の自動補完（未選択なら先頭を選択、選択中ならその候補を補完、cycle=trueなら順送り巡回）
  void autocompleteCandidate([bool cycle = false, bool forward = true]) {
    if (!_isExtCmd || _filteredExtCmds.isEmpty) return;

    setState(() {
      if (_selectedCandidateIndex == null) {
        _selectedCandidateIndex = forward ? 0 : _filteredExtCmds.length - 1;
      } else if (cycle) {
        _selectedCandidateIndex = forward
            ? (_selectedCandidateIndex! + 1) % _filteredExtCmds.length
            : (_selectedCandidateIndex! - 1 + _filteredExtCmds.length) % _filteredExtCmds.length;
      }
    });

    final targetIdx = _selectedCandidateIndex!.clamp(0, _filteredExtCmds.length - 1);
    var rawCmd = _filteredExtCmds[targetIdx].command.trim();
    final cmd = rawCmd.startsWith('#') ? rawCmd.substring(1).trim() : rawCmd;

    _extCmdFilterController.value = TextEditingValue(
      text: cmd,
      selection: TextSelection.collapsed(offset: cmd.length),
    );
    widget.inputController.value = TextEditingValue(
      text: cmd,
      selection: TextSelection.collapsed(offset: cmd.length),
    );
    _scrollToSelectedCandidate();
  }

  /// Tab キーによるフォーカス循環ナビゲーション
  void cycleFocus([bool forward = true]) {
    if (_isExtCmd) {
      // 候補リストが存在する拡張コマンド画面では Tab / Shift+Tab は補完・順送り専用
      autocompleteCandidate(true, forward);
      return;
    }

    final targets = <GetLineFocusTarget>[
      GetLineFocusTarget.none,
      GetLineFocusTarget.input,
      if (widget.recentMessages.isNotEmpty) GetLineFocusTarget.history,
      GetLineFocusTarget.cancel,
      GetLineFocusTarget.confirm,
    ];

    final currentIndex = targets.indexOf(_currentFocusTarget);
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = forward
        ? (safeIndex + 1) % targets.length
        : (safeIndex - 1 + targets.length) % targets.length;
    final nextTarget = targets[nextIndex];

    setState(() {
      _currentFocusTarget = nextTarget;
    });

    if (nextTarget == GetLineFocusTarget.input) {
      if (_isExtCmd) {
        _filterFocusNode.requestFocus();
      } else {
        _inputFocusNode.requestFocus();
      }
    } else {
      _inputFocusNode.unfocus();
      _filterFocusNode.unfocus();
    }
  }

  /// 先頭の '#' を確実に除去して C コアに送信
  void _sendCleanExtCmd(String rawCmd) {
    var cmd = rawCmd.trim();
    if (cmd.startsWith('#')) {
      cmd = cmd.substring(1).trim();
    }
    widget.inputController.text = cmd;
    widget.onSubmit(cmd);
  }

  /// Enter キーによる確定送信処理
  void submit() {
    // フォーカスが特定ボタンに当たっている場合はそのボタンを実行
    if (_currentFocusTarget == GetLineFocusTarget.cancel) {
      widget.onSubmit(null);
      return;
    }
    if (_currentFocusTarget == GetLineFocusTarget.history) {
      _handleShowHistory();
      return;
    }

    if (_isExtCmd) {
      if (_selectedCandidateIndex != null &&
          _filteredExtCmds.isNotEmpty &&
          _selectedCandidateIndex! >= 0 &&
          _selectedCandidateIndex! < _filteredExtCmds.length) {
        _sendCleanExtCmd(_filteredExtCmds[_selectedCandidateIndex!].command);
        return;
      }
      _handleFilterSubmit(_extCmdFilterController.text);
      return;
    }

    final val = widget.inputController.text;
    final byteCount = utf8.encode(val).length;
    if (byteCount <= _maxBytes) {
      widget.onSubmit(val);
    }
  }

  void _handleFilterSubmit(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      if (_selectedCandidateIndex != null && _filteredExtCmds.isNotEmpty) {
        final idx = _selectedCandidateIndex!.clamp(0, _filteredExtCmds.length - 1);
        _sendCleanExtCmd(_filteredExtCmds[idx].command);
      } else if (widget.inputController.text.trim().isNotEmpty) {
        _sendCleanExtCmd(widget.inputController.text);
      }
      return;
    }
    // 1. 完全一致があるか検索
    for (final entry in _filteredExtCmds) {
      var cmd = entry.command.trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd == q) {
        _sendCleanExtCmd(entry.command);
        return;
      }
    }
    // 2. 前方一致があるか検索
    for (final entry in _filteredExtCmds) {
      var cmd = entry.command.trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd.startsWith(q)) {
        _sendCleanExtCmd(entry.command);
        return;
      }
    }
    // 3. 部分一致があるか検索
    for (final entry in _filteredExtCmds) {
      var cmd = entry.command.trim().toLowerCase();
      if (cmd.startsWith('#')) cmd = cmd.substring(1).trim();
      if (cmd.contains(q)) {
        _sendCleanExtCmd(entry.command);
        return;
      }
    }
    // 4. 候補が絞り込まれており、明示的に選択されているならその候補を実行
    if (_filteredExtCmds.isNotEmpty && _selectedCandidateIndex != null) {
      final idx = _selectedCandidateIndex!.clamp(0, _filteredExtCmds.length - 1);
      _sendCleanExtCmd(_filteredExtCmds[idx].command);
      return;
    }
    // 5. 候補が残っている場合は先頭候補を実行
    if (_filteredExtCmds.isNotEmpty) {
      _sendCleanExtCmd(_filteredExtCmds.first.command);
      return;
    }
    // フォールバック: 入力欄の文字列（#除去済み）を送信
    _sendCleanExtCmd(query);
  }

  void _handleShowHistory() {
    widget.onShowMsgHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isExtCmd = _isExtCmd;
    final maxBytes = _maxBytes;

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
                    if (widget.recentMessages.isNotEmpty)
                      DialogRecentMessagesBox(
                        messages: widget.recentMessages,
                        onTapHistory: _handleShowHistory,
                        isKeyboardVisible: widget.bottomInset > 0,
                      ),
                    TextField(
                      controller: widget.inputController,
                      focusNode: _inputFocusNode,
                      autofocus: false,
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
                            final isOverLimit = byteCount > maxBytes;
                            return Text(
                              l10n.bytesCount(byteCount, maxBytes),
                              style: TextStyle(
                                color: isOverLimit ? Colors.redAccent : Colors.grey,
                                fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      onSubmitted: (val) {
                        final byteCount = utf8.encode(val).length;
                        if (byteCount <= maxBytes) {
                          widget.onSubmit(val);
                        }
                      },
                    ),
                    if (isExtCmd) ...[
                      const SizedBox(height: 8),
                      Text(l10n.selectExtCmd, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _extCmdFilterController,
                        focusNode: _filterFocusNode,
                        autofocus: false,
                        onSubmitted: _handleFilterSubmit,
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
                        onChanged: _updateFilteredExtCmds,
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
                            controller: _listScrollController,
                            shrinkWrap: true,
                            itemCount: _filteredExtCmds.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredExtCmds[index];
                              final isHighlighted = index == _selectedCandidateIndex;
                              return Material(
                                color: isHighlighted
                                    ? Colors.teal.withValues(alpha: 0.25)
                                    : Colors.transparent,
                                child: ListTile(
                                  title: Text(
                                    entry.command,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: isHighlighted ? Colors.amber[200] : Colors.white,
                                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                    ),
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _handleShowHistory,
                          icon: const Icon(Icons.history_rounded, size: 16),
                          label: Text(l10n.history),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[900],
                            foregroundColor: Colors.amber[200],
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            side: _currentFocusTarget == GetLineFocusTarget.history
                                ? const BorderSide(color: Colors.tealAccent, width: 2.0)
                                : null,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => widget.onSubmit(null),
                              style: TextButton.styleFrom(
                                side: _currentFocusTarget == GetLineFocusTarget.cancel
                                    ? const BorderSide(color: Colors.tealAccent, width: 2.0)
                                    : null,
                              ),
                              child: Text(l10n.cancel),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: widget.inputController,
                              builder: (context, value, child) {
                                final byteCount = utf8.encode(value.text).length;
                                final isOverLimit = byteCount > maxBytes;
                                return ElevatedButton(
                                  onPressed: isOverLimit
                                      ? null
                                      : () => submit(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004D40), // 深いダークティール (ラベンダー文字とのコントラスト比 約 6.5:1)
                                    disabledBackgroundColor: const Color(0xFF004D40).withValues(alpha: 0.3),
                                    side: _currentFocusTarget == GetLineFocusTarget.confirm
                                        ? const BorderSide(color: Colors.tealAccent, width: 2.0)
                                        : null,
                                  ),
                                  child: Text(l10n.confirm),
                                );
                              },
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
