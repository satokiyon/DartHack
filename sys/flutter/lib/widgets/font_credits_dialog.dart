import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:darthack/l10n/app_localizations.dart';

/// 同梱フォントのクレジット・ライセンス情報エントリ
class FontCreditEntry {
  final String id;
  final String name;
  final String fileName;
  final String author;
  final String authorEn;
  final String license;
  final String shortLicense;
  final Color licenseColor;
  final String url;
  final String descriptionJa;
  final String descriptionEn;

  const FontCreditEntry({
    required this.id,
    required this.name,
    required this.fileName,
    required this.author,
    required this.authorEn,
    required this.license,
    required this.shortLicense,
    required this.licenseColor,
    required this.url,
    required this.descriptionJa,
    required this.descriptionEn,
  });
}

/// 同梱フォント一覧（静的定義）
class FontCreditsData {
  static const List<FontCreditEntry> entries = [
    FontCreditEntry(
      id: 'NotoSansMonoCJKjp',
      name: 'Noto Sans Mono CJK JP',
      fileName: 'NotoSansMonoCJKjp-Regular.otf',
      author: '© 2014-2021 Adobe (西塚涼子 氏, Paul D. Hunt 氏, Sandoll Communications 他)',
      authorEn: '© 2014-2021 Adobe (Ryoko Nishizuka, Paul D. Hunt, Sandoll Communications, et al.)',
      license: 'SIL Open Font License 1.1',
      shortLicense: 'SIL OFL 1.1',
      licenseColor: Color(0xFF26A69A), // Teal
      url: 'https://github.com/notofonts/noto-cjk',
      descriptionJa: 'Google と Adobe が共同開発した高品位な等幅日本語フォントです。JIS第1〜第4水準の漢字やラテン文字に対応しています。',
      descriptionEn: 'High-quality monospace Japanese font co-developed by Google and Adobe, supporting JIS Level 1-4 Kanji and Latin characters.',
    ),
    FontCreditEntry(
      id: 'Terminus',
      name: 'Terminus (TTF)',
      fileName: 'TerminusTTF-Regular.ttf, TerminusTTF-Bold.ttf',
      author: 'Copyright (C) 2020 Dimitar Toshkov Zhekov / TTF版: Copyright (C) 2023 Tilman Blumenbach',
      authorEn: 'Copyright (C) 2020 Dimitar Toshkov Zhekov / TTF version: Copyright (C) 2023 Tilman Blumenbach',
      license: 'SIL Open Font License 1.1',
      shortLicense: 'SIL OFL 1.1',
      licenseColor: Color(0xFF26A69A), // Teal
      url: 'https://files.ax86.net/terminus-ttf/',
      descriptionJa: 'NetHack 伝統の鮮明で視認性の高いビットマップ調等幅フォントです。アスキーアートマップ描画に最適です。',
      descriptionEn: 'Classic crisp bitmap-style monospace font traditional in NetHack. Optimal for ASCII dungeon map display.',
    ),
    FontCreditEntry(
      id: 'IBMVGA9x16',
      name: 'PxPlus IBM VGA 9x16',
      fileName: 'PxPlus_IBM_VGA_9x16.ttf',
      author: 'Outline (vector) version by VileR',
      authorEn: 'Outline (vector) version by VileR',
      license: 'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
      shortLicense: 'CC BY-SA 4.0',
      licenseColor: Color(0xFF42A5F5), // Blue
      url: 'https://int10h.org/oldschool-pc-fonts/',
      descriptionJa: 'The Ultimate Oldschool PC Font Pack より。MS-DOS 時代の IBM PC/AT VGA (Code Page 437) テキスト画面を忠実に再現したクラシックフォントです。',
      descriptionEn: 'From The Ultimate Oldschool PC Font Pack. Faithfully reproduces classic IBM PC/AT VGA (Code Page 437) text screens from the MS-DOS era.',
    ),
    FontCreditEntry(
      id: 'MisakiGothic',
      name: '美咲ゴシック (Misaki Gothic)',
      fileName: 'misaki_gothic.ttf',
      author: 'Copyright (C) 2002-2021 門真 なむ (Num Kadoma)',
      authorEn: 'Copyright (C) 2002-2021 Num Kadoma',
      license: '自由利用 (フリーソフトウェア)',
      shortLicense: '自由利用',
      licenseColor: Color(0xFF66BB6A), // Green
      url: 'https://littlelimit.net/misaki.htm',
      descriptionJa: '門真 なむ 氏 (Little Limit) 作成の 8×8 ドット超小型日本語ビットマップフォントです。改変・再配布・商業利用が自由です。',
      descriptionEn: 'Ultra-compact 8x8 dot Japanese bitmap font created by Num Kadoma (Little Limit). Free for modification, redistribution, and commercial use.',
    ),
    FontCreditEntry(
      id: 'Unscii-8',
      name: 'Unscii 8x8',
      fileName: 'unscii-8.ttf',
      author: 'Ville-Matias Heikkilä (Viznut)',
      authorEn: 'Ville-Matias Heikkilä (Viznut)',
      license: 'Public Domain (CC0 1.0 Universal)',
      shortLicense: 'Public Domain',
      licenseColor: Color(0xFFAB47BC), // Purple
      url: 'http://pelulamu.net/unscii/',
      descriptionJa: 'コモドール 64 やクラシック PC 調のアスペクト比 1.0 (正方形セル) を持つレトロ調ビットマップフォントです。パブリックドメインとして提供されています。',
      descriptionEn: 'Retro bitmap font with 1.0 aspect ratio (square cells) inspired by Commodore 64 and classic PCs. Dedicated to the public domain (CC0).',
    ),
  ];
}

/// 同梱フォントのライセンス・クレジットを閲覧するためのモーダルダイアログ
class FontCreditsDialog extends StatelessWidget {
  const FontCreditsDialog({super.key});

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FontCreditsDialog(),
    );
  }

  void _copyToClipboard(BuildContext context, String url, String message) {
    Clipboard.setData(ClipboardData(text: url));
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
    final isEn = l10n.localeName.startsWith('en');
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          children: [
            // ヘッダー部
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.text_fields_rounded, color: Colors.amberAccent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.fontCreditsDialogTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 説明文
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.fontCreditsDialogDesc,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),

            // フォント一覧リスト
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: FontCreditsData.entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = FontCreditsData.entries[index];
                  final author = isEn ? entry.authorEn : entry.author;
                  final description = isEn ? entry.descriptionEn : entry.descriptionJa;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // フォント名とライセンスバッジ
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.fileName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ライセンスバッジ
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: entry.licenseColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: entry.licenseColor.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                entry.shortLicense,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: entry.licenseColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ライセンス詳細
                        Text(
                          l10n.fontCreditsLicense(entry.license),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        // 著作者
                        Text(
                          l10n.fontCreditsAuthor(author),
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        // 説明
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                        const SizedBox(height: 6),
                        // 配布元URL (タップしてコピー)
                        InkWell(
                          onTap: () => _copyToClipboard(
                            context,
                            entry.url,
                            l10n.fontCreditsCopiedUrl,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.link, size: 14, color: Colors.cyanAccent),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.url,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.cyanAccent,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy, size: 12, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(color: Colors.white24, height: 1),
            // フッター閉じるボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

