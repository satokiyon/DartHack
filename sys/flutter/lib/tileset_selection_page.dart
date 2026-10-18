import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/app_prefs.dart';
import 'l10n/app_localizations.dart';
import 'models/tileset_info.dart';

/// タイルセットの比較・選択画面
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
    await prefs.setString('selected_tileset', tilesetId);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tilesets = TilesetInfo.allTilesets;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tilesetSelectionTitle),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: tilesets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = tilesets[index];
          final isSelected = (t.id == _selectedTileset);

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
                      // タイトル行（タイルセット名 + 選択状態）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.displayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.cyanAccent : Colors.white,
                              ),
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

                      // 作者名
                      Text(
                        l10n.tilesetAuthorLabel(t.author),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // URL行（テキスト + コピーアイコン）
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
                                      fontSize: 13,
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
                                    size: 18,
                                    color: Colors.lightBlue.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

