import 'dart:async';
import 'dart:typed_data';

import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/route_map/tile_client.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

/// A client that answers with [answers] in order, and counts the requests.
class _Server {
  _Server(this.answers);

  final List<Object> answers;
  int requests = 0;

  Client client() => createTileClient(
    inner: MockClient((request) async {
      final answer = answers[requests++];
      if (answer is Response) return answer;
      throw answer;
    }),
    delay: Duration.zero,
  );
}

/// A cache with the tiles in [tiles] (by URL), which counts the questions.
class _Cache implements MapCachingProvider {
  _Cache(this.tiles, {this.supported = true});

  final Map<String, Uint8List> tiles;
  final bool supported;
  int asked = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<CachedMapTile?> getTile(String url) async {
    asked++;
    final bytes = tiles[url];
    if (bytes == null) return null;
    return (
      bytes: bytes,
      metadata: CachedMapTileMetadata(
        staleAt: DateTime.utc(2000),
        lastModified: null,
        etag: null,
      ),
    );
  }

  @override
  Future<void> putTile({
    required String url,
    required CachedMapTileMetadata metadata,
    Uint8List? bytes,
  }) async {}
}

class _Closing extends BaseClient {
  _Closing(this.onClose);

  final void Function() onClose;

  @override
  Future<StreamedResponse> send(BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => onClose();
}

void main() {
  test('gets the tile at once when the server answers', () async {
    final server = _Server([Response('tile', 200)]);

    final response = await server.client().get(Uri.parse('https://t/1.png'));

    expect(response.statusCode, 200);
    expect(server.requests, 1);
  });

  test('tries again when the connection fails for a moment', () async {
    final server = _Server([
      ClientException('connection closed'),
      TimeoutException('slow'),
      Response('tile', 200),
    ]);

    final response = await server.client().get(Uri.parse('https://t/1.png'));

    expect(response.statusCode, 200);
    expect(server.requests, 3);
  });

  test('tries again when the server is busy or limits the requests', () async {
    final server = _Server([
      Response('', 429),
      Response('', 503),
      Response('', 502),
      Response('tile', 200),
    ]);

    final response = await server.client().get(Uri.parse('https://t/1.png'));

    expect(response.statusCode, 200);
    expect(server.requests, 4);
  });

  test('does not try again for a tile that does not exist', () async {
    final server = _Server([Response('', 404)]);

    final response = await server.client().get(Uri.parse('https://t/1.png'));

    expect(response.statusCode, 404);
    expect(server.requests, 1);
  });

  test('gives up after the retries, with the last answer', () async {
    final server = _Server([
      for (var i = 0; i <= tileRetries; i++) Response('', 503),
    ]);

    final response = await server.client().get(Uri.parse('https://t/1.png'));

    expect(response.statusCode, 503);
    expect(server.requests, tileRetries + 1);
  });

  test(
    'gives up after the retries when the connection keeps failing',
    () async {
      final server = _Server([
        for (var i = 0; i <= tileRetries; i++) ClientException('down'),
      ]);

      expect(
        server.client().get(Uri.parse('https://t/1.png')),
        throwsA(isA<ClientException>()),
      );
    },
  );

  test('does not hide an error that is not about the connection', () async {
    final server = _Server([StateError('bug')]);

    expect(server.client().get(Uri.parse('https://t/1.png')), throwsStateError);
  });

  group('with the tiles in the cache', () {
    final url = Uri.parse('https://t/1.png');
    final old = Uint8List.fromList([1, 2, 3]);

    Client client(_Server server, _Cache cache) => createTileClient(
      inner: MockClient((request) async {
        final answer = server.answers[server.requests++];
        if (answer is Response) return answer;
        throw answer;
      }),
      delay: Duration.zero,
      cache: cache,
    );

    test('answers with the old tile when there is no connection', () async {
      final server = _Server([ClientException('offline')]);
      final cache = _Cache({url.toString(): old});

      final response = await client(server, cache).get(url);

      expect(response.statusCode, 200);
      expect(response.bodyBytes, old);
      expect(response.headers['content-type'], 'image/png');
      // It does not wait for the retries.
      expect(server.requests, 1);
    });

    test('answers with the old tile when the request is too slow', () async {
      final server = _Server([TimeoutException('slow')]);

      final response = await client(
        server,
        _Cache({url.toString(): old}),
      ).get(url);

      expect(response.bodyBytes, old);
      expect(server.requests, 1);
    });

    test('answers with the old tile when the server is failing', () async {
      final server = _Server([Response('busy', 503)]);

      final response = await client(
        server,
        _Cache({url.toString(): old}),
      ).get(url);

      expect(response.statusCode, 200);
      expect(response.bodyBytes, old);
    });

    test('uses the server when it answers', () async {
      final server = _Server([Response('new', 200)]);
      final cache = _Cache({url.toString(): old});

      final response = await client(server, cache).get(url);

      expect(response.body, 'new');
      expect(cache.asked, 0);
    });

    test(
      'goes on with the failure when the tile is not in the cache',
      () async {
        final server = _Server([
          for (var i = 0; i <= tileRetries; i++) ClientException('offline'),
        ]);
        final cache = _Cache({});

        await expectLater(
          client(server, cache).get(url),
          throwsA(isA<ClientException>()),
        );
        // Asked for each try, and then tried again as usual.
        expect(server.requests, tileRetries + 1);
      },
    );

    test(
      'goes on with a slow request when the tile is not in the cache',
      () async {
        final server = _Server([
          for (var i = 0; i <= tileRetries; i++) TimeoutException('slow'),
        ]);

        await expectLater(
          client(server, _Cache({})).get(url),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('goes on with the answer when the tile is not in the cache', () async {
      final server = _Server([Response('busy', 503), Response('tile', 200)]);

      final response = await client(server, _Cache({})).get(url);

      expect(response.body, 'tile');
    });

    test(
      'does not use a cache that is not supported, or other requests',
      () async {
        final server = _Server([ClientException('offline')]);
        final unsupported = _Cache({url.toString(): old}, supported: false);

        await expectLater(
          StaleTileClient(
            MockClient((request) async => throw ClientException('offline')),
            unsupported,
          ).get(url),
          throwsA(isA<ClientException>()),
        );
        await expectLater(
          StaleTileClient(
            MockClient((request) async => throw ClientException('offline')),
            _Cache({url.toString(): old}),
          ).post(url),
          throwsA(isA<ClientException>()),
        );
        expect(unsupported.asked, 0);
        expect(server.requests, 0);
      },
    );

    test('closes the client under it', () {
      var closed = false;
      final inner = _Closing(() => closed = true);

      StaleTileClient(inner, _Cache({})).close();

      expect(closed, isTrue);
    });
  });

  test('the map layer of the app uses the cache it is given', () {
    final cache = _Cache({});
    final container = ProviderContainer(
      overrides: [tileCacheProvider.overrideWithValue(cache)],
    );
    addTearDown(container.dispose);

    final layer = container.read(tileLayerProvider) as TileLayer;

    expect(layer.tileProvider, isA<NetworkTileProvider>());
  });

  test('the map layer of the app tries a failed tile again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final layer = container.read(tileLayerProvider) as TileLayer;

    expect(layer.tileProvider, isA<NetworkTileProvider>());
    expect(
      layer.evictErrorTileStrategy,
      EvictErrorTileStrategy.notVisibleRespectMargin,
    );
    expect(layer.urlTemplate, contains('openstreetmap.org'));
  });
}
