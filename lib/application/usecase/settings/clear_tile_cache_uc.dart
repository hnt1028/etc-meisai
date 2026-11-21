import 'package:etc_meisai/application/interface/tile_cache_if.dart';

/// Deletes the map tiles kept on the device. Design: PRC-029.
class ClearTileCacheUC {
  const ClearTileCacheUC({required this.tileCache});

  final TileCacheIF tileCache;

  Future<void> execute() => tileCache.clear();
}
