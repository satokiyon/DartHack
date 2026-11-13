import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/topten_entry.dart';
import '../models/xlog_entry.dart';
import '../utils/app_prefs.dart';
import 'keyboard_help_dialog.dart';

/// スコアボードのレコードタップ時に表示する詳細スコアダイアログ（スクロール＆キーボード対応）
class ScoreDetailDialog extends StatefulWidget {
  final TopTenEntry entry;
  final bool? isJp;
  final bool? usePhysicalKeyboardNotation;

  const ScoreDetailDialog({
    super.key,
    required this.entry,
    this.isJp,
    this.usePhysicalKeyboardNotation,
  });

  @override
  State<ScoreDetailDialog> createState() => _ScoreDetailDialogState();
}

class _ScoreDetailDialogState extends State<ScoreDetailDialog> {
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  bool _isCloseButtonFocused = false;
  bool _usePhysicalKeyboardNotation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    if (widget.usePhysicalKeyboardNotation != null) {
      _usePhysicalKeyboardNotation = widget.usePhysicalKeyboardNotation!;
    } else if (AppPrefs.instance != null) {
      _usePhysicalKeyboardNotation =
          AppPrefs.instance!.getBool('use_physical_keyboard_notation') ?? false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _pageScroll(int direction) {
    if (!_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final step = viewport > 0 ? viewport * 0.85 : 280.0;
    _scrollBy(direction * step);
  }

  void _jumpToEdge(bool toTop) {
    if (!_scrollController.hasClients) return;
    final target = toTop ? 0.0 : _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  bool get _canScrollFurtherDown {
    if (!_scrollController.hasClients) return false;
    final maxExtent = _scrollController.position.maxScrollExtent;
    return maxExtent > 10.0 && _scrollController.offset < maxExtent - 5.0;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // 操作ヘルプ: F1 / Alt+h
    if (key == LogicalKeyboardKey.f1 ||
        (key == LogicalKeyboardKey.keyH && HardwareKeyboard.instance.isAltPressed)) {
      if (isDown) {
        final jaMode = widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
        KeyboardHelpDialog.show(
          context,
          helpContext: KeyboardHelpContext.scoreDetail,
          isJapanese: jaMode,
        );
      }
      return KeyEventResult.handled;
    }

    // 閉じる: Escape / q / Enter / NumpadEnter
    if (key == LogicalKeyboardKey.escape ||
        (key == LogicalKeyboardKey.keyQ && !isCtrl) ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (isDown) Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Tab: 閉じるボタンのフォーカス切替
    if (key == LogicalKeyboardKey.tab) {
      if (isDown) {
        setState(() {
          _isCloseButtonFocused = !_isCloseButtonFocused;
        });
      }
      return KeyEventResult.handled;
    }

    // Space / Shift+Space: ページスクロール（最下部到達時またはスクロール不要時は KeyDownEvent で閉じる）
    if (key == LogicalKeyboardKey.space) {
      if (isShift) {
        _pageScroll(-1);
      } else if (_canScrollFurtherDown) {
        _pageScroll(1);
      } else if (isDown) {
        Navigator.of(context).pop();
      }
      return KeyEventResult.handled;
    }

    // 行スクロール: ↑ / k
    if (key == LogicalKeyboardKey.arrowUp ||
        (key == LogicalKeyboardKey.keyK && !isCtrl)) {
      _scrollBy(-48.0);
      return KeyEventResult.handled;
    }

    // 行スクロール: ↓ / j
    if (key == LogicalKeyboardKey.arrowDown ||
        (key == LogicalKeyboardKey.keyJ && !isCtrl)) {
      _scrollBy(48.0);
      return KeyEventResult.handled;
    }

    // ページ下スクロール: PageDown / > / .
    if (key == LogicalKeyboardKey.pageDown ||
        event.character == '>' ||
        key == LogicalKeyboardKey.period) {
      _pageScroll(1);
      return KeyEventResult.handled;
    }

    // ページ上スクロール: PageUp / < / ,
    if (key == LogicalKeyboardKey.pageUp ||
        event.character == '<' ||
        key == LogicalKeyboardKey.comma) {
      _pageScroll(-1);
      return KeyEventResult.handled;
    }

    // 先頭 / 末尾ジャンプ: Home / ^ , End / |
    if (key == LogicalKeyboardKey.home ||
        event.character == '^' ||
        key == LogicalKeyboardKey.caret) {
      if (isDown) _jumpToEdge(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end || event.character == '|') {
      if (isDown) _jumpToEdge(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _buildSectionTitle(String title, IconData icon, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: accent,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2029),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildChipGroup(
    List<String> items, {
    required String emptyText,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          emptyText,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jaMode =
        widget.isJp ?? (Localizations.localeOf(context).languageCode == 'ja');
    final entry = widget.entry;
    final raw = entry.rawRecord;
    final xlog = entry.xlog;
    final screenSize = MediaQuery.sizeOf(context);
    final maxDialogWidth = math.min(560.0, math.max(260.0, screenSize.width - 24));
    final maxDialogHeight =
        math.min(680.0, math.max(240.0, screenSize.height * 0.88));

    final rankDisplay = entry.rank > 0 ? '${entry.rank}' : '-';

    // 死因・場所の構築
    String deathText = '';
    if (xlog != null && xlog.death.isNotEmpty) {
      deathText = translateDeathTextForDisplay(xlog.death, jaMode);
      if (xlog.whileReason != null && xlog.whileReason!.isNotEmpty) {
        final whileStr = XLogEntry.translateWhileReason(xlog.whileReason!, jaMode);
        deathText = jaMode ? '$deathText（$whileStr）' : '$deathText ($whileStr)';
      }
    } else if (raw != null && raw.death.isNotEmpty) {
      deathText = translateDeathTextForDisplay(raw.death, jaMode);
    } else if (entry.details.isNotEmpty) {
      deathText = entry.details.first;
    }

    String? locationText;
    if (xlog != null) {
      final loc = translateDeathLocationForDisplay(
          xlog.deathdnum, xlog.deathlev, jaMode);
      locationText = jaMode
          ? '$loc（最大到達 ${xlog.maxlvl}階）'
          : '$loc (max level ${xlog.maxlvl})';
    } else if (raw != null) {
      final loc = translateDeathLocationForDisplay(raw.dnum, raw.dlev, jaMode);
      locationText = jaMode
          ? '$loc（最大到達 ${raw.maxlvl}階）'
          : '$loc (max level ${raw.maxlvl})';
    }

    final hpVal = xlog?.hp ?? raw?.hp;
    final maxHpVal = xlog?.maxhp ?? raw?.maxhp;
    final hpDisplay = (hpVal != null && maxHpVal != null)
        ? '${hpVal <= 0 ? '-' : hpVal} / $maxHpVal'
        : (entry.details.length > 1 ? entry.details[1] : null);

    // 初期性別・初期属性の変化検出
    String? initialProfileChange;
    if (xlog != null) {
      final changes = <String>[];
      if (xlog.gender0.isNotEmpty && xlog.gender0 != xlog.gender) {
        final g0 = translateGendCodeForDisplay(xlog.gender0, jaMode);
        final g1 = translateGendCodeForDisplay(xlog.gender, jaMode);
        changes.add(jaMode ? '性別: $g0 → $g1' : 'Gender: $g0 → $g1');
      }
      if (xlog.align0.isNotEmpty && xlog.align0 != xlog.align) {
        final a0 = translateAlignCodeForDisplay(xlog.align0, jaMode);
        final a1 = translateAlignCodeForDisplay(xlog.align, jaMode);
        changes.add(jaMode ? '属性: $a0 → $a1' : 'Align: $a0 → $a1');
      }
      if (changes.isNotEmpty) {
        initialProfileChange = changes.join(' / ');
      }
    }

    return Dialog(
      backgroundColor: const Color(0xFF12161D),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 固定ヘッダー
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: entry.isCurrent
                            ? const Color(0xFFFFB300)
                            : Colors.amber.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        rankDisplay,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: entry.isCurrent ? Colors.black : Colors.amber[200],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jaMode ? '${entry.score} 点' : '${entry.score} pts',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[200],
                            ),
                          ),
                          Text(
                            entry.nameAndProfile,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),

                // スクロール可能な詳細本体
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (initialProfileChange != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                jaMode
                                    ? '変化履歴: $initialProfileChange'
                                    : 'Changed: $initialProfileChange',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.cyan[200],
                                ),
                              ),
                            ),

                          _buildSectionTitle(
                            jaMode ? '冒険の結果・到達状況' : 'Outcome & Location',
                            Icons.place_outlined,
                            Colors.amber[200]!,
                          ),
                          _buildSectionCard([
                            if (deathText.isNotEmpty)
                              _buildInfoRow(
                                jaMode ? '結末・死因' : 'Fate',
                                deathText,
                              ),
                            if (locationText != null)
                              _buildInfoRow(
                                jaMode ? '場所' : 'Location',
                                locationText,
                              ),
                            if (hpDisplay != null)
                              _buildInfoRow(
                                jaMode ? 'HP / 最大HP' : 'HP / Max HP',
                                hpDisplay,
                              ),
                            if (xlog != null) ...[
                              _buildInfoRow(
                                jaMode ? '所持金' : 'Gold',
                                '${xlog.gold} Zm',
                              ),
                              _buildInfoRow(
                                jaMode ? '死亡回数' : 'Deaths',
                                '${xlog.deaths}',
                              ),
                            ] else if (raw != null) ...[
                              _buildInfoRow(
                                jaMode ? '死亡回数' : 'Deaths',
                                '${raw.deaths}',
                              ),
                            ],
                          ]),

                          if (xlog != null) ...[
                            _buildSectionTitle(
                              jaMode ? 'プレイ統計 (xlogfile)' : 'Play Statistics (xlogfile)',
                              Icons.analytics_outlined,
                              Colors.lightBlue[200]!,
                            ),
                            _buildSectionCard([
                              _buildInfoRow(
                                jaMode ? '開始日時' : 'Started',
                                xlog.starttime > 0
                                    ? XLogEntry.formatTimestamp(xlog.starttime, jaMode)
                                    : XLogEntry.formatDateInt(xlog.birthdate, jaMode),
                              ),
                              _buildInfoRow(
                                jaMode ? '終了日時' : 'Ended',
                                xlog.endtime > 0
                                    ? XLogEntry.formatTimestamp(xlog.endtime, jaMode)
                                    : XLogEntry.formatDateInt(xlog.deathdate, jaMode),
                              ),
                              _buildInfoRow(
                                jaMode ? '実プレイ時間' : 'Real Time',
                                XLogEntry.formatDuration(xlog.realtime, jaMode),
                              ),
                              _buildInfoRow(
                                jaMode ? '経過ターン数' : 'Turns',
                                '${xlog.turns}',
                              ),
                              _buildInfoRow(
                                jaMode ? '願い回数' : 'Wishes',
                                jaMode
                                    ? '${xlog.wishCnt} 回（アーティファクト: ${xlog.artiWishCnt} 回）'
                                    : '${xlog.wishCnt} (Artifact: ${xlog.artiWishCnt})',
                              ),
                              _buildInfoRow(
                                jaMode ? '骸骨・再生成' : 'Bones / Rerolls',
                                jaMode
                                    ? '骨ファイル: ${xlog.bones} / リロール: ${xlog.rerolls}'
                                    : 'Bones: ${xlog.bones} / Rerolls: ${xlog.rerolls}',
                              ),
                              if (xlog.version.isNotEmpty)
                                _buildInfoRow(
                                  jaMode ? 'バージョン' : 'Version',
                                  xlog.version,
                                ),
                            ]),

                            _buildSectionTitle(
                              jaMode ? '達成項目' : 'Achievements',
                              Icons.military_tech_outlined,
                              Colors.greenAccent[200]!,
                            ),
                            _buildSectionCard([
                              _buildChipGroup(
                                xlog.achievements
                                    .map((k) => XLogEntry.translateAchievement(k, jaMode))
                                    .toList(),
                                emptyText: jaMode ? 'なし' : 'None',
                                bgColor: Colors.green.withValues(alpha: 0.16),
                                borderColor: Colors.greenAccent.withValues(alpha: 0.35),
                                textColor: Colors.green[100]!,
                              ),
                            ]),

                            _buildSectionTitle(
                              jaMode ? '縛りプレイ (Conduct)' : 'Conducts',
                              Icons.verified_outlined,
                              Colors.purple[200]!,
                            ),
                            _buildSectionCard([
                              _buildChipGroup(
                                xlog.conducts
                                    .map((k) => XLogEntry.translateConduct(k, jaMode))
                                    .toList(),
                                emptyText: jaMode ? 'なし' : 'None',
                                bgColor: Colors.purple.withValues(alpha: 0.16),
                                borderColor: Colors.purpleAccent.withValues(alpha: 0.35),
                                textColor: Colors.purple[100]!,
                              ),
                            ]),
                          ] else ...[
                            if (raw != null) ...[
                              _buildSectionTitle(
                                jaMode ? '基本日付・バージョン' : 'Dates & Version',
                                Icons.calendar_today_outlined,
                                Colors.lightBlue[200]!,
                              ),
                              _buildSectionCard([
                                _buildInfoRow(
                                  jaMode ? '開始日' : 'Started',
                                  XLogEntry.formatDateInt(raw.birthdate, jaMode),
                                ),
                                _buildInfoRow(
                                  jaMode ? '終了日' : 'Ended',
                                  XLogEntry.formatDateInt(raw.deathdate, jaMode),
                                ),
                                if (raw.version.isNotEmpty)
                                  _buildInfoRow(
                                    jaMode ? 'バージョン' : 'Version',
                                    raw.version,
                                  ),
                              ]),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.amber[200],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.rank <= 0
                                          ? (jaMode
                                              ? 'ウィザード・探索モードまたはランキング圏外のため拡張ログ (xlogfile) は保存されません。'
                                              : 'Extended log (xlogfile) is not saved for wizard/discover mode or unranked games.')
                                          : (jaMode
                                              ? 'この記録に対する詳細な拡張ログ (xlogfile) が見つかりません。旧バージョンで記録されたスコアには詳細データが含まれない場合があります。'
                                              : 'Detailed extended log (xlogfile) is not available for this record. Scores recorded in older versions may not include detailed data.'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber[100],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                // 固定フッター
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCloseButtonFocused
                          ? Colors.amber[700]
                          : Colors.teal[600],
                      foregroundColor:
                          _isCloseButtonFocused ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: _isCloseButtonFocused
                            ? const BorderSide(
                                color: Colors.amberAccent, width: 2)
                            : BorderSide.none,
                      ),
                      elevation: _isCloseButtonFocused ? 6 : 2,
                    ),
                    child: Text(
                      _usePhysicalKeyboardNotation
                          ? (jaMode ? 'Esc:閉じる' : 'Esc: Close')
                          : (jaMode ? '閉じる' : 'Close'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
