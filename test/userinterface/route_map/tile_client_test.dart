import 'dart:async';

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
