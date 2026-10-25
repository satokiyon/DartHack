import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_prefs.dart';
import 'l10n/app_localizations.dart';
import 'models/tileset_info.dart';
import 'services/tileset_manager.dart';

/// タイルセットの比較・選択・カスタム追加画面
class TilesetSelectionPage extends StatefulWidget {
  final String currentTileset;
  final ValueChanged<String>? onTilesetSelected;

  const TilesetSelectionPage({
    super.key,
    required this.currentTileset,
    this.onTilesetSelected,
  });

  @override
  State<TilesetSelectionPage> createState() => _TilesetSelectionPageState();
}

class _TilesetSelectionPageState extends State<TilesetSelectionPage> {
  late String _selectedTileset;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _selectedTileset = widget.currentTileset;
  }

  /// タイルセットを選択して保存
  Future<void> _selectTileset(String tilesetId) async {
    setState(() {
      _selectedTileset = tilesetId;
    });
    final prefs = await AppPrefs.getInstance();
    await prefs.setString(TilesetManager.prefSelectedTileset, tilesetId);
    widget.onTilesetSelected?.call(tilesetId);
  }

  /// URLをクリップボードにコピーして通知
  void _copyUrlToClipboard(String url, String message) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// デバイスから画像ファイルを選択してカスタムタイルセットとしてインポート
  Future<void> _pickAndImportCustomTileset(AppLocalizations l10n) async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'webp', 'bmp'],
      );

      if (result.isEmpty) {
        return;
      }

      final file = result.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tilesetImportFailed('画像データを読み込めませんでした'))),
        );
        return;
      }

      final validation = await TilesetManager.instance.importCustomTileset(
        bytes,
        file.name,
      );

      if (!mounted) return;

      if (validation.isValid) {
        final sizeStr = '${validation.tileWidth}x${validation.tileHeight}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tilesetImportSuccess(file.name, sizeStr)),
            backgroundColor: Colors.teal.shade700,
          ),
        );
        // 新しく追加されたカスタムタイルを選択
        final newlyAdded = TilesetManager.instance.customTilesets.lastOrNull;
        if (newlyAdded != null) {
          await _selectTileset(newlyAdded.id);
        }
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('インポート失敗'),
              ],
            ),
            content: Text(
              validation.errorMessage ?? '不明なバリデーションエラーが発生しました',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tilesetImportFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  /// カスタムタイルセットの削除確認ダイアログ
  Future<void> _confirmDeleteTileset(
    TilesetInfo tileset,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tilesetDeleteCustom),
        content: Text(l10n.tilesetDeleteConfirm(tileset.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await TilesetManager.instance.deleteCustomTileset(tileset.id);
      if (_selectedTileset == tileset.id) {
        setState(() {
          _selectedTileset = TilesetManager.defaultTilesetId;
        });
        widget.onTilesetSelected?.call(TilesetManager.defaultTilesetId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListenableBuilder(
      listenable: TilesetManager.instance,
      builder: (context, _) {
        final tilesets = TilesetManager.instance.allTilesets;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.tilesetSelectionTitle),
            actions: [
              IconButton(
                icon: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                tooltip: l10n.tilesetAddCustom,
                onPressed: _isImporting ? null : () => _pickAndImportCustomTileset(l10n),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: tilesets.length + 1, // +1 は上部のインポートカード
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                // 上部: カスタムタイルセット追加アクションカード
                return Card(
                  elevation: 2,
                  color: Colors.blueGrey.shade900.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 1.0),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isImporting ? null : () => _pickAndImportCustomTileset(l10n),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.file_upload_outlined, color: Colors.cyanAccent, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tilesetAddCustom,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  '横40列仕様の NetHack タイル画像を自動判定して追加',
                                  style: TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.cyanAccent),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final t = tilesets[index - 1];
              final isSelected = (t.id == _selectedTileset);

              // アスペクト比の表記（非正方形の場合）
              final isNonSquare = t.tileWidth != t.tileHeight;
              final aspectText = isNonSquare
                  ? ' (${t.tileWidth}:${t.tileHeight})'
                  : '';

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Colors.blueGrey.shade900 : Colors.grey.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.cyanAccent : Colors.grey.shade800,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectTileset(t.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // タイトル行（タイルセット名 + バッジ + 選択状態）
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.displayName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.cyanAccent : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (!t.isBuiltIn) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amberAccent.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amberAccent, width: 0.8),
                                        ),
                                        child: Text(
                                          l10n.tilesetCustomBadge,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.cyanAccent),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check, size: 14, color: Colors.cyanAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.tilesetCurrentSelected,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Icon(Icons.radio_button_unchecked, color: Colors.white38),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // サイズ & アスペクト比、作者名
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${l10n.tilesetSizeLabel(t.tileWidth, t.tileHeight)}$aspectText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.cyanAccent,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.tilesetAuthorLabel(t.author),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!t.isBuiltIn)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: l10n.delete,
                                  onPressed: () => _confirmDeleteTileset(t, l10n),
                                ),
                            ],
                          ),

                          // URL行（内蔵タイルの場合のみ）
                          if (t.isBuiltIn && t.url.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _copyUrlToClipboard(t.url, l10n.tilesetUrlCopied),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t.url,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.lightBlue.shade300,
                                            decoration: TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: l10n.tilesetTapToCopy,
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 16,
                                          color: Colors.lightBlue.shade300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
