import 'package:flutter/material.dart';

/// ダイアログ内で直近の状況メッセージを表示する引用風ボックスウィジェット。
/// - 直近メッセージを最大数行スクロール可能に表示
/// - 初回表示時は最新メッセージ（最下部）に自動スクロール
/// - キーボード展開時はコンパクト（省スペース）に自動縮小しつつ最下部を維持
/// - タップ時に全メッセージ履歴ダイアログへシームレスに遷移
class DialogRecentMessagesBox extends StatefulWidget {
  final List<String> messages;
  final VoidCallback? onTapHistory;
  final bool isKeyboardVisible;

  const DialogRecentMessagesBox({
    super.key,
    required this.messages,
    this.onTapHistory,
    this.isKeyboardVisible = false,
  });

  @override
  State<DialogRecentMessagesBox> createState() => _DialogRecentMessagesBoxState();
}

class _DialogRecentMessagesBoxState extends State<DialogRecentMessagesBox> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant DialogRecentMessagesBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isKeyboardVisible != widget.isKeyboardVisible ||
        oldWidget.messages != widget.messages) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxHeight = widget.isKeyboardVisible ? 48.0 : 88.0;
    final isJa = Localizations.localeOf(context).languageCode == 'ja';
    final titleText = isJa ? '直前の状況' : 'Recent Context';
    final tapHintText = isJa ? 'タップで全履歴' : 'Tap for full history';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTapHistory,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左側のアクセントバー（引用デザイン）
                Container(
                  width: 3.5,
                  color: Colors.tealAccent.shade400,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ヘッダー行（状況ラベル ＋ 履歴アイコン）
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: Colors.tealAccent.shade200,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent.shade200,
                              ),
                            ),
                            const Spacer(),
                            if (widget.onTapHistory != null) ...[
                              Flexible(
                                child: Text(
                                  tapHintText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // メッセージ本文エリア（最下部初期表示・スクロール可能）
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.messages.map((msg) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                                  child: Text(
                                    msg,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      color: Colors.white70,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.clip,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

