import 'package:etc_meisai/application/interface/tile_cache_if.dart';

/// Gives the size of the map tiles kept on the device. Design: PRC-028.
class GetTileCacheSizeUC {
  const GetTileCacheSizeUC({required this.tileCache});

  final TileCacheIF tileCache;

  /// The size in bytes. 0 when no tile is kept.
  Future<int> execute() => tileCache.sizeInBytes();
}
