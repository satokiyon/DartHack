import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

void showMsgHistoryPanel({
  required BuildContext context,
  required List<String> messages,
  required double msgFontSize,
}) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF12161D),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: Colors.amber[300]),
                      const SizedBox(width: 8),
                      Text(
                        l10n.msgHistoryTitle,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.entriesCount(messages.length),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noMsgHistory,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final dataIndex = messages.length - 1 - index;
                            final line = messages[dataIndex];
                            final ratio = (dataIndex + 1) / messages.length;
                            final color = Color.lerp(Colors.white38, Colors.white, ratio)!;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                line,
                                style: TextStyle(
                                  color: color,
                                  fontFamily: 'monospace',
                                  fontSize: msgFontSize,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(sheetContext).padding.bottom + 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(l10n.close),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget buildMsgHistoryButton({
  required VoidCallback onPressed,
  String label = '履歴',
}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.history, size: 18, color: Colors.amber),
    label: Text(label, style: const TextStyle(color: Colors.amber)),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.amber,
      side: BorderSide(color: Colors.amber.withValues(alpha: 0.6)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

bool isCallOrNamePrompt(String prompt) {
  if (prompt.isEmpty) return false;
  final p = prompt.toLowerCase();
  return prompt.contains('何と呼びますか')
      || prompt.contains('何と名付けますか')
      || prompt.contains('名前を付け')
      || prompt.contains('注釈')
      || prompt.contains('何に変更しますか')
      || p.contains('call ')
      || p.contains('name ')
      || p.contains('call this')
      || p.contains('name this')
      || p.contains('what do you want to call')
      || p.contains('what do you want to name')
      || p.contains('annotation')
      || p.contains('replace annotation');
}

/// アイテムの名前付け・呼び名プロンプト（巻物・薬・杖・魔法書など）か判定する。
/// ※マップ注釈（annotation）や拡張コマンドは除外
bool isItemCallOrNamePrompt(String prompt) {
  if (prompt.isEmpty) return false;
  final p = prompt.toLowerCase();

  // マップ注釈メモは明確に除外
  if (prompt.contains('注釈') || p.contains('annotation')) return false;

  // 英語の docall プロンプト: "Call <item>:" (例: "Call a scroll:")
  final trimmed = p.trim();
  if (trimmed.startsWith('call ') && trimmed.endsWith(':')) {
    return true;
  }

  return prompt.contains('何と呼びますか')
      || prompt.contains('何と名付けますか')
      || prompt.contains('何という名前にしますか')
      || prompt.contains('名前を付けますか')
      || prompt.contains('名前を付け')
      || prompt.contains('何に変更しますか')
      || p.contains('call this')
      || p.contains('name this')
      || p.contains('call the')
      || p.contains('name the')
      || p.contains('what do you want to call')
      || p.contains('what do you want to name');
}

/// 死亡直後の持ち物開示および bones 保存確認プロンプトか判定する。
/// ※「能力値を表示しますか?」「倒した怪物の一覧を表示しますか?」などの後続ダイアログは除外
bool isDeathConfirmationPrompt(String prompt) {
  if (prompt.isEmpty) return false;
  final p = prompt.toLowerCase();

  // 後続の統計・記録開示ダイアログは明確に除外
  if (prompt.contains('能力値') ||
      prompt.contains('倒した怪物') ||
      prompt.contains('行跡') ||
      prompt.contains('墓石') ||
      p.contains('attributes') ||
      p.contains('creatures vanquished') ||
      p.contains('conduct') ||
      p.contains('tombstone')) {
    return false;
  }

  return prompt.contains('持ち物を識別表示しますか')
      || prompt.contains('死亡時点の所持品を表示しますか')
      || prompt.contains('bones ファイルを保存しますか')
      || p.contains('possessions identified')
      || (p.contains('what you had when you') && p.contains('died'))
      || p.contains('save bones');
}

/// 危険行動の警告確認プロンプト、または状況確認プロンプトか判定する。
/// ※ゲーム終了確認（Really quit?）などの日常確認は除外
bool isRiskyActionPrompt(String prompt) {
  if (prompt.isEmpty) return false;
  final p = prompt.toLowerCase();

  // ゲーム終了・中断は明確に除外
  if (prompt.contains('終了') || prompt.contains('やめ') || p.contains('quit') || p.contains('stop')) {
    return false;
  }

  // テレポート確認・飛び込み確認
  if (prompt.contains('テレポートしますか') ||
      prompt.contains('飛び込みますか') ||
      p.contains('teleport?') ||
      p.contains('jump in?')) {
    return true;
  }

  // 食事継続確認（満腹時の窒息危険）
  if (prompt.contains('食事を続けますか') || p.contains('continue eating?')) {
    return true;
  }

  // 日本語の危険行動警告（「本当に」＋危険動詞・名詞）
  if (prompt.contains('本当に') &&
      (prompt.contains('攻撃') ||
       prompt.contains('入る') ||
       prompt.contains('進む') ||
       prompt.contains('祈り') ||
       prompt.contains('飲みますか') ||
       prompt.contains('食べますか') ||
       prompt.contains('飛び込みますか') ||
       prompt.contains('装備しますか') ||
       prompt.contains('歩きますか') ||
       prompt.contains('振りますか') ||
       prompt.contains('撃ちますか') ||
       prompt.contains('潜りますか') ||
       prompt.contains('這い'))) {
    return true;
  }

  // 英語の杖破壊警告（日英共通で出力されるメッセージ）
  if (p.contains('are you really sure you want to break')) {
    return true;
  }

  // 英語の攻撃・祈り確認
  if (p.contains('are you sure you want to attack') ||
      p.contains('are you sure you want to pray')) {
    return true;
  }

  // 英語の really + 動詞 (attack, enter, move, drink, eat, dive, crawl, wear, put on, shoot, jump)
  if (p.contains('really ') &&
      (p.contains('attack') ||
       p.contains('enter') ||
       p.contains('move') ||
       p.contains('drink') ||
       p.contains('eat') ||
       p.contains('dive') ||
       p.contains('crawl') ||
       p.contains('wear') ||
       p.contains('put on') ||
       p.contains('shoot') ||
       p.contains('jump'))) {
    return true;
  }

  return false;
}

/// ダイアログ内で直近メッセージ枠を表示すべき特定のプロンプト（アイテム名前付け、死亡時確認、危険行動確認）かどうかを判定する。
bool shouldShowRecentMessagesInDialog(String prompt) {
  if (prompt.isEmpty) return false;
  return isItemCallOrNamePrompt(prompt) ||
         isDeathConfirmationPrompt(prompt) ||
         isRiskyActionPrompt(prompt);
}

/// ダイアログ表示の直前に出力された状況メッセージを抽出する。
/// - 空行や制御用行（MOREなど）を除外
/// - プロンプト文字列（ダイアログの質問文）との重複を除外
/// - 直近の有効なメッセージを最大 [maxCount] 行取得し、時系列順（古い行→新しい行）で返却
List<String> extractRecentContextMessages(
  List<String> messageHistory, {
  String? prompt,
  int maxCount = 6,
}) {
  if (messageHistory.isEmpty) return const [];

  final cleanedPrompt = prompt?.trim().toLowerCase();
  final List<String> extracted = [];

  for (int i = messageHistory.length - 1; i >= 0; i--) {
    final rawLine = messageHistory[i];
    final trimmed = rawLine.trim();

    if (trimmed.isEmpty) continue;
    if (trimmed == '-- MORE --' || trimmed.toLowerCase() == '--more--') continue;

    // プロンプト文との重複・包含チェック（二重表示の防止）
    if (cleanedPrompt != null && cleanedPrompt.isNotEmpty) {
      final lowerLine = trimmed.toLowerCase();
      if (lowerLine == cleanedPrompt ||
          (lowerLine.length > 5 && cleanedPrompt.contains(lowerLine)) ||
          (cleanedPrompt.length > 5 && lowerLine.contains(cleanedPrompt))) {
        continue;
      }
    }

    extracted.add(rawLine);
    if (extracted.length >= maxCount) break;
  }

  // 古い行 → 新しい行 の時系列順に戻して返す
  return extracted.reversed.toList();
}

