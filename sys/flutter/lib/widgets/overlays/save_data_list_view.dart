import 'package:flutter/material.dart';

/// ゲーム開始時のセーブデータ一覧ウィジェット
///
/// 4件以上のセーブデータが存在する場合はスクロールバーを表示し、
/// 選択中のセーブデータをテーマカラーとチェックマークでハイライトします。
class SaveDataListView extends StatelessWidget {
  final List<String> saves;
  final String? selectedName;
  final ValueChanged<String> onSelect;
  final double maxHeight;
  final ScrollController scrollController;

  const SaveDataListView({
    super.key,
    required this.saves,
    required this.selectedName,
    required this.onSelect,
    required this.maxHeight,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (saves.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: saves.length >= 4,
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: saves.length,
          itemBuilder: (context, index) {
            final name = saves[index];
            final isSelected = selectedName == name;

            return Material(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              child: ListTile(
                selected: isSelected,
                selectedTileColor: colorScheme.primary.withValues(alpha: 0.16),
                selectedColor: colorScheme.primary,
                dense: true,
                title: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                leading: Icon(
                  Icons.account_circle,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: colorScheme.primary, size: 18)
                    : null,
                onTap: () => onSelect(name),
              ),
            );
          },
        ),
      ),
    );
  }
}
