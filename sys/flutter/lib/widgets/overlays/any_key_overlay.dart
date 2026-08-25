import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

class AnyKeyOverlay extends StatefulWidget {
  final String question;
  final int defaultChoice;
  final String? descriptionText;
  final Function(int choiceCode) onSelect;
  final VoidCallback onClose;
  final VoidCallback onShowMsgHistory;
  final double bottomInset;

  const AnyKeyOverlay({
    super.key,
    required this.question,
    required this.defaultChoice,
    this.descriptionText,
    required this.onSelect,
    required this.onClose,
    required this.onShowMsgHistory,
    required this.bottomInset,
  });

  @override
  State<AnyKeyOverlay> createState() => _AnyKeyOverlayState();
}

class _AnyKeyOverlayState extends State<AnyKeyOverlay> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _lastSentCode = 0;
  int _lastSentTimestamp = 0;

  // 修飾子トグル状態 (手動切替まで保持)
  bool _isShiftActive = false;
  bool _isCtrlActive = false;
  bool _isMetaActive = false;

  // クイックキーパッドの表示モード (false = ABC文字, true = 全記号 32種)
  bool _showSymbolsPad = false;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 修飾子 (Shift / Ctrl / Meta) の適用ロジック
  int _applyModifiers(int rawCode) {
    int code = rawCode;

    // Shift 適用 ('a'..'z' -> 'A'..'Z')
    if (_isShiftActive) {
      if (code >= 97 && code <= 122) {
        code = code - 32;
      }
    }

    // Ctrl 適用 ('a'..'z' または 'A'..'Z' -> 1..26)
    if (_isCtrlActive) {
      if (code >= 97 && code <= 122) {
        code = code - 96;
      } else if (code >= 65 && code <= 90) {
        code = code - 64;
      }
    }

    // Meta 適用 (code | 0x80)
    if (_isMetaActive) {
      code = code | 0x80;
    }

    return code;
  }

  void _sendCode(int rawCode) {
    if (rawCode < 1) return;
    final finalCode = _applyModifiers(rawCode);
    final now = DateTime.now().millisecondsSinceEpoch;

    // 同一キーの 50ms 以内重複送信をガード
    if (finalCode == _lastSentCode && (now - _lastSentTimestamp) < 50) {
      return;
    }
    _lastSentCode = finalCode;
    _lastSentTimestamp = now;

    widget.onSelect(finalCode);
    _inputController.clear();
  }

  void _sendKey(String char) {
    if (char.isEmpty) return;
    _sendCode(char.codeUnitAt(0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isJapanese = widget.question.contains('どの') || Localizations.localeOf(context).languageCode == 'ja';
    final hasDesc = widget.descriptionText != null && widget.descriptionText!.trim().isNotEmpty;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent && event.character != null && event.character!.isNotEmpty) {
              _sendKey(event.character!);
            }
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Card(
                  margin: const EdgeInsets.all(12),
                  color: const Color(0xFF141A22),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ヘッダー
                        Row(
                          children: [
                            Icon(Icons.help_center_rounded, color: Colors.amber[300], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.anyKeyPromptTitle,
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                        const SizedBox(height: 12),

                        // 質問表示
                        Text(
                          widget.question,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.anyKeyPromptSubtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // 1文字テキスト入力フィールド (ソフトキーボード用)
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _inputController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 20),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: l10n.anyKeyPlaceholder,
                              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: Colors.black45,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                _sendKey(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 解説カード（機能説明カード: 入力欄の直下に配置）
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasDesc ? const Color(0xFF1E2836) : Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasDesc ? Colors.teal.shade300 : Colors.white.withValues(alpha: 0.12),
                              width: 1.5,
                            ),
                            boxShadow: hasDesc
                                ? [
                                    BoxShadow(
                                      color: Colors.teal.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasDesc ? Icons.info_outline_rounded : Icons.keyboard_alt_outlined,
                                    color: hasDesc ? Colors.teal[300] : Colors.grey[400],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    hasDesc
                                        ? (isJapanese ? 'キー機能の解説:' : 'Key Description:')
                                        : (isJapanese ? '説明ガイド:' : 'Guide:'),
                                    style: TextStyle(
                                      color: hasDesc ? Colors.teal[200] : Colors.grey[400],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                hasDesc
                                    ? widget.descriptionText!.trim()
                                    : (isJapanese
                                        ? '調べたいキー（例: a, d, e, ?, & 等）を入力またはタップしてください。修飾子(Shift/Ctrl/Meta)をONにすると修飾キーの検索が可能です。'
                                        : 'Type or tap any key. Toggle Shift/Ctrl/Meta for modified key info.'),
                                style: TextStyle(
                                  fontSize: hasDesc ? 14 : 12,
                                  fontWeight: hasDesc ? FontWeight.w600 : FontWeight.normal,
                                  color: hasDesc ? Colors.white : Colors.grey[400],
                                  fontFamily: hasDesc ? 'monospace' : null,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 入力補助修飾子トグル (Shift / Ctrl / Meta)
                        _buildModifierToggles(isJapanese),
                        const SizedBox(height: 10),

                        // 画面タップ用クイックキーボード
                        _buildQuickKeyPad(isJapanese),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.16), height: 1),
                        const SizedBox(height: 12),

                        // アクションボタン (閉じる & 履歴)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: Text(l10n.close),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade900.withValues(alpha: 0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: widget.onShowMsgHistory,
                              icon: const Icon(Icons.history_rounded, size: 16),
                              label: Text(l10n.history),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[900],
                                foregroundColor: Colors.amber[200],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
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
      ),
    );
  }

  /// 修飾子トグル (Shift / Ctrl / Meta) UI
  Widget _buildModifierToggles(bool isJapanese) {
    return Column(
      children: [
        Text(
          isJapanese ? '入力修飾子 (切り替えるまで保持):' : 'Input Modifiers:',
          style: TextStyle(fontSize: 12, color: Colors.grey[300], fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            FilterChip(
              label: Text(_isShiftActive ? 'Shift (大文字) [ON]' : 'Shift (大文字)'),
              selected: _isShiftActive,
              selectedColor: Colors.amber.shade700,
              checkmarkColor: Colors.black,
              labelStyle: TextStyle(
                color: _isShiftActive ? Colors.black : Colors.amber[200],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (val) {
                setState(() => _isShiftActive = val);
              },
            ),
            FilterChip(
              label: Text(_isCtrlActive ? 'Ctrl (^キー) [ON]' : 'Ctrl (^キー)'),
              selected: _isCtrlActive,
              selectedColor: Colors.teal.shade600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _isCtrlActive ? Colors.white : Colors.teal[200],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (val) {
                setState(() => _isCtrlActive = val);
              },
            ),
            FilterChip(
              label: Text(_isMetaActive ? 'Meta (Alt) [ON]' : 'Meta (Alt)'),
              selected: _isMetaActive,
              selectedColor: Colors.purple.shade600,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _isMetaActive ? Colors.white : Colors.purple[200],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (val) {
                setState(() => _isMetaActive = val);
              },
            ),
          ],
        ),
      ],
    );
  }

  /// クイック文字入力キーパッド (画面タップ用)
  Widget _buildQuickKeyPad(bool isJapanese) {
    const letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
    // NetHack 全 32 種印刷可能記号
    const symbols = [
      '?', '#', '&', '!', '/', ':', ';', '@', '.', ',', '\$', '^', '*', '<', '>', '_',
      '(', ')', '[', ']', '=', '"', "'", '%', '+', '-', '\\', '|', '~', '{', '}', '`'
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // パネル表示モード切替タブ (文字 vs 全記号)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(isJapanese ? 'ABC (文字)' : 'ABC (Letters)'),
                selected: !_showSymbolsPad,
                selectedColor: Colors.blueGrey.shade800,
                labelStyle: TextStyle(
                  color: !_showSymbolsPad ? Colors.amber : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                onSelected: (val) {
                  if (val) setState(() => _showSymbolsPad = false);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(isJapanese ? '#!? (全記号 32種)' : '#!? (All Symbols)'),
                selected: _showSymbolsPad,
                selectedColor: Colors.teal.shade900,
                labelStyle: TextStyle(
                  color: _showSymbolsPad ? Colors.tealAccent : Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                onSelected: (val) {
                  if (val) setState(() => _showSymbolsPad = true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 文字モード
          if (!_showSymbolsPad)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: letters.map((ch) {
                final displayChar = _isShiftActive ? ch.toUpperCase() : ch;
                return InkWell(
                  onTap: () => _sendCode(ch.codeUnitAt(0)),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF263238),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blueGrey.shade700),
                    ),
                    child: Text(
                      displayChar,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),

          // 記号モード (全 32 種)
          if (_showSymbolsPad)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: symbols.map((sym) {
                return InkWell(
                  onTap: () => _sendCode(sym.codeUnitAt(0)),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.teal.shade300.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      sym,
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
