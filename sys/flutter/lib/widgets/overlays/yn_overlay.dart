import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/yn_choice_parser.dart';
import 'dialog_recent_messages_box.dart';

class YnOverlay extends StatefulWidget {
  final String question;
  final String choices;
  final int defaultChoice;
  final Function(int choiceCode) onSelect;
  final Function(String text)? onSelectText;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;
  final List<String> recentMessages;
  final bool usePhysicalKeyboardNotation;

  const YnOverlay({
    super.key,
    required this.question,
    required this.choices,
    required this.defaultChoice,
    required this.onSelect,
    this.onSelectText,
    required this.onShowMsgHistory,
    required this.bottomInset,
    this.recentMessages = const [],
    this.usePhysicalKeyboardNotation = false,
  });

  @override
  State<YnOverlay> createState() => YnOverlayState();
}

class YnOverlayState extends State<YnOverlay> {
  late final TextEditingController _textController;
  late final FocusNode _textFocusNode;
  String _currentFocusTarget = 'none';

  String get currentFocusTarget => _currentFocusTarget;
  FocusNode get textFocusNode => _textFocusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _textFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if (event is KeyDownEvent) {
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            cycleFocus(!isShift);
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (event is KeyDownEvent) {
            widget.onSelect(27);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus && _currentFocusTarget != 'input') {
        setState(() {
          _currentFocusTarget = 'input';
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  /// 外部またはテンキーからの文字追記
  void appendText(String text) {
    final current = _textController.text;
    final selection = _textController.selection;
    if (selection.isValid && selection.start >= 0 && selection.end >= selection.start) {
      final newText = current.replaceRange(selection.start, selection.end, text);
      final newOffset = selection.start + text.length;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
      final newText = current + text;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  /// 外部またはテンキーからの1文字削除
  void deleteChar() {
    final current = _textController.text;
    if (current.isEmpty) return;
    final selection = _textController.selection;
    if (selection.isValid && selection.start >= 0 && selection.end > selection.start) {
      final newText = current.replaceRange(selection.start, selection.end, '');
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      final offset = selection.isValid && selection.start > 0 ? selection.start : current.length;
      if (offset > 0) {
        final newText = current.substring(0, offset - 1) + current.substring(offset);
        _textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: offset - 1),
        );
      }
    }
  }

  /// 外部またはテンキーからの全クリア
  void clearText() {
    _textController.clear();
  }

  /// 外部または決定ボタンからの確定処理
  void submit() {
    if (_currentFocusTarget == 'cancel') {
      widget.onSelect(27);
      return;
    }
    if (_currentFocusTarget == 'history') {
      widget.onShowMsgHistory();
      return;
    }
    if (_currentFocusTarget.startsWith('choice:')) {
      final ch = _currentFocusTarget.substring(7);
      _handleSingleChoice(ch);
      return;
    }

    final parsed = YnChoiceParser.parse(
      question: widget.question,
      choices: widget.choices,
      defaultChoice: widget.defaultChoice,
    );

    if (parsed.type == YnPromptType.countInput ||
        _currentFocusTarget == 'confirm' ||
        _currentFocusTarget == 'input') {
      _submitText(_textController.text);
      return;
    }

    if (widget.defaultChoice != 0) {
      widget.onSelect(widget.defaultChoice);
    }
  }

  /// Tab キーによるフォーカス循環ナビゲーション
  void cycleFocus([bool forward = true]) {
    final parsed = YnChoiceParser.parse(
      question: widget.question,
      choices: widget.choices,
      defaultChoice: widget.defaultChoice,
    );

    final List<String> targets = ['none'];
    if (parsed.type == YnPromptType.countInput) {
      targets.add('input');
      targets.add('cancel');
      targets.add('confirm');
      targets.add('history');
    } else {
      for (final ch in parsed.quickChoices) {
        targets.add('choice:$ch');
      }
      if (parsed.allowsFreeInput) {
        targets.add('input');
      }
      targets.add('cancel');
      targets.add('history');
    }

    final currentIndex = targets.indexOf(_currentFocusTarget);
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;
    final nextIndex = forward
        ? (safeIndex + 1) % targets.length
        : (safeIndex - 1 + targets.length) % targets.length;
    final nextTarget = targets[nextIndex];

    setState(() {
      _currentFocusTarget = nextTarget;
    });

    if (nextTarget == 'input') {
      _textFocusNode.requestFocus();
    } else {
      _textFocusNode.unfocus();
    }
  }

  void _submitText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    if (widget.onSelectText != null) {
      widget.onSelectText!(text);
    } else {
      widget.onSelect(text.codeUnitAt(0));
    }
    _textController.clear();
  }

  void _handleSingleChoice(String ch) {
    if (widget.onSelectText != null) {
      widget.onSelectText!(ch);
    } else {
      widget.onSelect(ch.codeUnitAt(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = YnChoiceParser.parse(
      question: widget.question,
      choices: widget.choices,
      defaultChoice: widget.defaultChoice,
    );
    final isKeyboardVisible = widget.bottomInset > 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomInset),
          child: Center(
            child: Card(
            margin: const EdgeInsets.all(24),
            color: const Color(0xFF141A22),
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                maxHeight: MediaQuery.of(context).size.height - widget.bottomInset - 32,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline_rounded, color: Colors.amber[300], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.confirmTitle,
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
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
                          onTapHistory: widget.onShowMsgHistory,
                          isKeyboardVisible: isKeyboardVisible,
                        ),
                      Text(
                        widget.question,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (parsed.isYesNo)
                        _buildYesNoButtons(context, parsed, l10n)
                      else
                        _buildDynamicChoiceBody(context, parsed, l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildYesNoButtons(BuildContext context, ParsedYnPrompt parsed, AppLocalizations l10n) {
    final isJp = Localizations.localeOf(context).languageCode == 'ja';

    return ExcludeFocus(
      excluding: true,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final ch in parsed.quickChoices)
            Builder(
              builder: (context) {
                final isFocused = _currentFocusTarget == 'choice:$ch';
                final isDefault = ch.codeUnitAt(0) == parsed.defaultChoice;
                return ElevatedButton(
                  onPressed: () => widget.onSelect(ch.codeUnitAt(0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFocused
                        ? (isDefault ? Colors.teal[400] : Colors.blueGrey[700])
                        : (isDefault ? Colors.teal[600] : Colors.blueGrey[800]),
                    foregroundColor: ch == 'a' ? Colors.amber[200] : Colors.white,
                    elevation: isFocused ? 6 : 2,
                    side: isFocused
                        ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                        : null,
                  ),
                  child: Text(
                    YnChoiceParser.resolveButtonLabel(
                      ch,
                      question: widget.question,
                      isJapanese: isJp,
                      useKeyboardNotation: widget.usePhysicalKeyboardNotation,
                    ),
                  ),
                );
              },
            ),
          ElevatedButton(
            onPressed: () => widget.onSelect(27), // ESC
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentFocusTarget == 'cancel' ? Colors.black87 : Colors.black54,
              foregroundColor: _currentFocusTarget == 'cancel' ? Colors.amberAccent : Colors.white70,
              side: _currentFocusTarget == 'cancel'
                  ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                  : null,
            ),
            child: Text(widget.usePhysicalKeyboardNotation
                ? (isJp ? 'Esc:${l10n.cancel}' : 'Esc: ${l10n.cancel}')
                : l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: widget.onShowMsgHistory,
            icon: const Icon(Icons.history_rounded, size: 16),
            label: Text(l10n.history),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentFocusTarget == 'history' ? Colors.blueGrey[700] : Colors.blueGrey[900],
              foregroundColor: Colors.amber[200],
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: _currentFocusTarget == 'history'
                  ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicChoiceBody(BuildContext context, ParsedYnPrompt parsed, AppLocalizations l10n) {
    if (parsed.type == YnPromptType.countInput) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 入力欄 (TextField) ＋ 右横に「決定」ボタン
          _buildTextFieldRow(context, parsed, l10n),
          const SizedBox(height: 8),

          // 2. テンキー風数字パネル (1〜9, C, 0, ⌫)
          Center(child: _buildCountKeypad(context, l10n)),
          const SizedBox(height: 14),

          // 3. 補助アクション (キャンセル ESC, 履歴)
          _buildAuxiliaryActions(context, parsed, l10n),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. クイックチップグリッド
        if (parsed.quickChoices.isNotEmpty) ...[
          _buildQuickChoiceGrid(context, parsed),
          const SizedBox(height: 12),
        ],

        // 2. 自由入力テキストフィールド (タップされた時のみソフトウェアキーボード起動)
        if (parsed.allowsFreeInput) ...[
          _buildTextFieldRow(context, parsed, l10n),
          const SizedBox(height: 14),
        ],

        // 3. 補助アクション (使用中一覧 ?, キャンセル ESC, 履歴)
        _buildAuxiliaryActions(context, parsed, l10n),
      ],
    );
  }

  /// 数量入力専用のテンキーパネル (1-2-3 / 4-5-6 / 7-8-9 / C-0-⌫)
  Widget _buildCountKeypad(BuildContext context, AppLocalizations l10n) {
    const buttonRows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: buttonRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      height: 44,
                      child: _buildKeypadButton(key, l10n),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// テンキーの各ボタン生成
  Widget _buildKeypadButton(String key, AppLocalizations l10n) {
    if (key == '⌫') {
      return ElevatedButton(
        onPressed: deleteChar,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF232D3B),
          foregroundColor: Colors.amber[300],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: const Icon(Icons.backspace_outlined, size: 20),
      );
    }
    if (key == 'C') {
      return ElevatedButton(
        onPressed: clearText,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF2A1C1E),
          foregroundColor: Colors.redAccent[100],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
        ),
        child: const Text('C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: () => appendText(key),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: const Color(0xFF232D3B),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      child: Text(
        key,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// クイックチップグリッド (スロット選択や水晶玉探知などで使用)
  Widget _buildQuickChoiceGrid(BuildContext context, ParsedYnPrompt parsed) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      constraints: const BoxConstraints(maxHeight: 180),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: parsed.quickChoices.map((ch) {
            final isDefault = ch.codeUnitAt(0) == parsed.defaultChoice;
            return SizedBox(
              width: 38,
              height: 38,
              child: ElevatedButton(
                onPressed: () => _handleSingleChoice(ch),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isDefault ? Colors.teal[600] : const Color(0xFF232D3B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: _currentFocusTarget == 'choice:$ch'
                        ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                        : BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                child: Text(
                  ch,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// テキスト入力欄 + 右横「決定」ボタン
  Widget _buildTextFieldRow(BuildContext context, ParsedYnPrompt parsed, AppLocalizations l10n) {
    final isInputFocused = _currentFocusTarget == 'input';
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _textFocusNode,
            autofocus: false,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: parsed.type == YnPromptType.countInput
                  ? (Localizations.localeOf(context).languageCode == 'ja' ? '数量を入力' : 'Enter quantity')
                  : (Localizations.localeOf(context).languageCode == 'ja' ? '文字・記号を自由に入力' : 'Enter character or symbol'),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0F141C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: isInputFocused
                    ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                    : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: isInputFocused
                    ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                    : BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.amberAccent, width: 2.5),
              ),
            ),
            onSubmitted: _submitText,
          ),
        ),
        const SizedBox(width: 8),
        ExcludeFocus(
          excluding: true,
          child: ElevatedButton(
            onPressed: () => _submitText(_textController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: _currentFocusTarget == 'confirm'
                  ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                  : null,
            ),
            child: Text(Localizations.localeOf(context).languageCode == 'ja' ? '決定' : l10n.ok),
          ),
        ),
      ],
    );
  }

  /// 補助アクション (使用中一覧 ?, キャンセル ESC, 履歴)
  Widget _buildAuxiliaryActions(BuildContext context, ParsedYnPrompt parsed, AppLocalizations l10n) {
    final isJp = Localizations.localeOf(context).languageCode == 'ja';
    return ExcludeFocus(
      excluding: true,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          if (parsed.hasHelpOption)
            ElevatedButton.icon(
              onPressed: () => widget.onSelect('?'.codeUnitAt(0)),
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: Text(widget.usePhysicalKeyboardNotation
                  ? (isJp ? '? 使用中スロット' : '? Used Slots')
                  : (isJp ? '使用中スロット' : 'Used Slots')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2836),
                foregroundColor: Colors.amber[300],
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ElevatedButton(
            onPressed: () => widget.onSelect(27), // ESC
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentFocusTarget == 'cancel' ? Colors.black87 : Colors.black54,
              foregroundColor: _currentFocusTarget == 'cancel' ? Colors.amberAccent : Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: _currentFocusTarget == 'cancel'
                  ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                  : null,
            ),
            child: Text(widget.usePhysicalKeyboardNotation
                ? (isJp ? 'Esc:${l10n.cancel}' : 'Esc: ${l10n.cancel}')
                : l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: widget.onShowMsgHistory,
            icon: const Icon(Icons.history_rounded, size: 16),
            label: Text(l10n.history),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentFocusTarget == 'history' ? Colors.blueGrey[700] : Colors.blueGrey[900],
              foregroundColor: Colors.amber[200],
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: _currentFocusTarget == 'history'
                  ? const BorderSide(color: Colors.amberAccent, width: 2.5)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
