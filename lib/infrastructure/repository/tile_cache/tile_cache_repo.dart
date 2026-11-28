import 'dart:io';

import 'package:etc_meisai/application/interface/tile_cache_if.dart';

/// The name of the file in which the cache of flutter_map counts its size. It
/// is not a tile: it is kept when the tiles are deleted.
const tileCacheSizeMonitorFileName = 'sizeMonitor.bin';

/// The folder that holds the tiles of the cache of flutter_map, in the folder
/// [applicationSupportPath] it is given.
String tileCacheFolderOf(String applicationSupportPath) =>
    '$applicationSupportPath${Platform.pathSeparator}fm_cache';

/// Reads the size of the folder with the kept map tiles, and deletes the tiles
/// in it (docs/route-map.md, "保存したタイルの使い方").
class TileCacheRepo implements TileCacheIF {
  /// [directory] is null when the folder of the cache is not known: there is
  /// nothing to read or delete then.
  const TileCacheRepo({required this.directory});

  final String? directory;

  /// The files of the tiles. A folder that is not there has none.
  Stream<File> _tiles() async* {
    final path = directory;
    if (path == null) return;
    final folder = Directory(path);
    if (!await folder.exists()) return;
    await for (final entry in folder.list(recursive: true)) {
      if (entry is! File) continue;
      if (entry.uri.pathSegments.last == tileCacheSizeMonitorFileName) continue;
      yield entry;
    }
  }

  @override
  Future<int> sizeInBytes() async {
    var total = 0;
    await for (final file in _tiles()) {
      total += await file.length();
    }
    return total;
  }

  @override
  Future<void> clear() async {
    await for (final file in _tiles()) {
      await file.delete();
    }
  }
}
