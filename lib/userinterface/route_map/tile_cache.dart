import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

/// How long a tile in the cache is used without asking the server again
/// (docs/route-map.md, "地図の読み込み"). The server says about a week; a tile
/// that is kept longer lets the map work offline for places that were seen.
const tileFreshAge = Duration(days: 90);

/// The cache of the map tiles. It is kept in the folder of the app, which the
/// OS does not clear when the space is short (the usual cache folder may be).
/// Returns null when the folder cannot be found: the map then uses the usual
/// cache.
///
/// The cache is one for the whole app, so this is called once, before the
/// first tile is shown (lib/main.dart).
Future<MapCachingProvider?> createTileCache({
  Future<String> Function()? directory,
}) async {
  try {
    final path =
        await (directory ??
            () async => (await getApplicationSupportDirectory()).path)();
    return BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: path,
      overrideFreshAge: tileFreshAge,
    );
  } catch (_) {
    return null;
  }
}
