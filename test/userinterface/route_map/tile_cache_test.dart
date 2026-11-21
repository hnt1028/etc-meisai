import 'dart:io';

import 'package:etc_meisai/userinterface/route_map/tile_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a tile for 90 days', () {
    expect(tileFreshAge, const Duration(days: 90));
  });

  test('gives no cache when the folder is not found', () async {
    final cache = await createTileCache(
      directory: () async => throw const FileSystemException('none'),
    );

    expect(cache, isNull);
  });

  test('makes the cache in the folder it is given', () async {
    final folder = Directory.systemTemp.createTempSync('tile_cache_test');
    addTearDown(() => folder.deleteSync(recursive: true));

    final cache = await createTileCache(directory: () async => folder.path);

    expect(cache, isNotNull);
    expect(cache!.isSupported, isTrue);
  });
}
