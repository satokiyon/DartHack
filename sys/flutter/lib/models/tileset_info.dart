/// タイルセットのメタデータを定義するモデルクラス
class TilesetInfo {
  final String id;
  final String displayName;
  final int tileWidth;
  final int tileHeight;
  final String author;
  final String url;
  final String assetPath;

  const TilesetInfo({
    required this.id,
    required this.displayName,
    required this.tileWidth,
    required this.tileHeight,
    required this.author,
    required this.url,
    required this.assetPath,
  });

  /// 利用可能なすべてのタイルセット定義一覧
  static const List<TilesetInfo> allTilesets = [
    TilesetInfo(
      id: 'default_16x16',
      displayName: 'Default (16x16)',
      tileWidth: 16,
      tileHeight: 16,
      author: 'NetHack DevTeam',
      url: 'https://nethackwiki.com/wiki/Tileset',
      assetPath: 'assets/tiles/default_16x16.webp',
    ),
    TilesetInfo(
      id: 'nevanda_32x32',
      displayName: 'Nevanda (32x32)',
      tileWidth: 32,
      tileHeight: 32,
      author: 'Nevanda',
      url: 'https://nethackwiki.com/wiki/Nevanda',
      assetPath: 'assets/tiles/nevanda_32x32.webp',
    ),
    TilesetInfo(
      id: 'pixelhack_32x32',
      displayName: 'PixelHack (32x32)',
      tileWidth: 32,
      tileHeight: 32,
      author: 'John Shaw (PixelHack)',
      url: 'https://pixelhack.blogspot.com/',
      assetPath: 'assets/tiles/pixelhack_32x32.webp',
    ),
    TilesetInfo(
      id: 'zeldhack_32x32',
      displayName: 'ZeldHack (32x32)',
      tileWidth: 32,
      tileHeight: 32,
      author: 'LSpixel',
      url: 'https://lspixel.itch.io/zeldhack',
      assetPath: 'assets/tiles/zeldhack_32x32.webp',
    ),
    TilesetInfo(
      id: 'kevintamtiles_64x64',
      displayName: 'KevinTam tiles (64x64)',
      tileWidth: 64,
      tileHeight: 64,
      author: 'Kevin Tam',
      url: 'https://github.com/glorat/nethack-cocoa',
      assetPath: 'assets/tiles/kevintamtiles_64x64.webp',
    ),
    TilesetInfo(
      id: 'abigaba_32x32',
      displayName: 'Abigaba (32x32)',
      tileWidth: 32,
      tileHeight: 32,
      author: 'Abigaba',
      url: 'https://nethackwiki.com/wiki/Abigaba_tiles',
      assetPath: 'assets/tiles/abigaba_32x32.webp',
    ),
    TilesetInfo(
      id: 'geoduck_15x25',
      displayName: 'Geoduck (15x25)',
      tileWidth: 15,
      tileHeight: 25,
      author: 'Geoduck',
      url: 'http://www.geoduckthings.net/nhack/nhack.html',
      assetPath: 'assets/tiles/geoduck_15x25.webp',
    ),
  ];

  /// ID から TilesetInfo を検索（見つからない場合はデフォルトの PixelHack を返す）
  static TilesetInfo findById(String id) {
    return allTilesets.firstWhere(
      (t) => t.id == id,
      orElse: () => allTilesets[2], // pixelhack_32x32
    );
  }
}

