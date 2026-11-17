import 'dart:async';

import 'package:http/http.dart';
import 'package:http/retry.dart';

/// The HTTP client that fetches the map tiles. It tries a tile again when the
/// server is busy or the connection fails for a moment (a weak or switching
/// mobile network): a tile that fails stays gray until the map is moved, so a
/// failure that goes away by itself must not reach the screen
/// (docs/route-map.md, "地図の読み込み").
///
/// [inner] is the client that really sends; the tests pass a fake.
Client createTileClient({Client? inner, Duration? delay}) {
  final base = delay ?? const Duration(milliseconds: 400);
  return RetryClient(
    inner ?? Client(),
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
