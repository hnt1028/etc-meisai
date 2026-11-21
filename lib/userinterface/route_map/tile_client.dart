import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

/// The HTTP client that fetches the map tiles. It tries a tile again when the
/// server is busy or the connection fails for a moment (a weak or switching
/// mobile network): a tile that fails stays gray until the map is moved, so a
/// failure that goes away by itself must not reach the screen
/// (docs/route-map.md, "地図の読み込み").
///
/// When [cache] is given, a tile that cannot be fetched is answered with the
/// tile kept in the cache, even if it is old (the map works offline): see
/// [StaleTileClient]. The old tile is tried before the retries, so that going
/// offline does not make every tile wait for them.
///
/// [inner] is the client that really sends; the tests pass a fake.
Client createTileClient({
  Client? inner,
  Duration? delay,
  MapCachingProvider? cache,
}) {
  final base = delay ?? const Duration(milliseconds: 400);
  final sender = inner ?? Client();
  return RetryClient(
    cache == null ? sender : StaleTileClient(sender, cache),
    retries: tileRetries,
    when: (response) => _retryStatuses.contains(response.statusCode),
    whenError: (error, _) =>
        error is ClientException || error is TimeoutException,
    delay: (attempt) => base * (1 << attempt),
  );
}

/// How many times a tile is tried again after it fails.
const tileRetries = 4;

/// The statuses of a server that is busy, or limits the requests: the tile is
/// asked for again after a while. Other statuses (404 and so on) are final.
const _retryStatuses = {429, 500, 502, 503, 504};

/// A client that answers a tile it cannot fetch with the tile in [cache], even
/// when the tile is old: the connection fails, or the server is busy or
/// failing (the statuses of [_retryStatuses]). When the cache has no such tile,
/// the failure goes on as it is (and the retries try it again).
///
/// The tile that is answered is put in the cache again by the tile provider,
/// so that it is fresh again for the usual time. The map is then not asked for
/// that tile until then, even if the network is back.
class StaleTileClient extends BaseClient {
  StaleTileClient(this._inner, this._cache);

  final Client _inner;
  final MapCachingProvider _cache;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (request.method != 'GET' || !_cache.isSupported) {
      return _inner.send(request);
    }
    try {
      final response = await _inner.send(request);
      if (!_retryStatuses.contains(response.statusCode)) return response;
      final kept = await _kept(request);
      if (kept == null) return response;
      await response.stream.drain<void>();
      return kept;
    } on ClientException {
      final kept = await _kept(request);
      if (kept == null) rethrow;
      return kept;
    } on TimeoutException {
      final kept = await _kept(request);
      if (kept == null) rethrow;
      return kept;
    }
  }

  Future<StreamedResponse?> _kept(BaseRequest request) async {
    final tile = await _cache.getTile(request.url.toString());
    if (tile == null) return null;
    return StreamedResponse(
      Stream.value(tile.bytes),
      200,
      contentLength: tile.bytes.length,
      request: request,
      headers: const {'content-type': 'image/png'},
    );
  }

  @override
  void close() => _inner.close();
}
