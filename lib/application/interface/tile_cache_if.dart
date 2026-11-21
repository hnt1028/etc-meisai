/// The map tiles the app keeps on the device (docs/route-map.md, "保存した
/// タイルの使い方").
abstract interface class TileCacheIF {
  /// How many bytes the kept tiles take. 0 when there are none.
  Future<int> sizeInBytes();

  /// Deletes every kept tile. They are fetched again when they are needed.
  Future<void> clear();
}
