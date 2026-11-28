import 'dart:io';

import 'package:etc_meisai/infrastructure/repository/tile_cache/tile_cache_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('tile_cache_repo'));
  tearDown(() => folder.deleteSync(recursive: true));

  void write(String name, int bytes) =>
      File('${folder.path}${Platform.pathSeparator}$name')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(bytes, 1));

  test('names the folder of the cache inside the folder of the app', () {
    expect(
      tileCacheFolderOf('${Platform.pathSeparator}app'),
      '${Platform.pathSeparator}app${Platform.pathSeparator}fm_cache',
    );
  });

  test('adds up the size of the tiles, in folders too', () async {
    write('a', 100);
    write('sub${Platform.pathSeparator}b', 250);
    final repo = TileCacheRepo(directory: folder.path);

    expect(await repo.sizeInBytes(), 350);
  });

  test('does not count the file that counts the size', () async {
    write('a', 100);
    write(tileCacheSizeMonitorFileName, 999);
    final repo = TileCacheRepo(directory: folder.path);

    expect(await repo.sizeInBytes(), 100);
  });

  test('deletes the tiles, and keeps the file that counts the size', () async {
    write('a', 100);
    write('sub${Platform.pathSeparator}b', 250);
    write(tileCacheSizeMonitorFileName, 8);
    final repo = TileCacheRepo(directory: folder.path);

    await repo.clear();

    expect(await repo.sizeInBytes(), 0);
    expect(
      File(
        '${folder.path}${Platform.pathSeparator}$tileCacheSizeMonitorFileName',
      ).existsSync(),
      isTrue,
    );
    // Deleting again, with nothing left, is not an error.
    await repo.clear();
  });

  test('has nothing when the folder is not there', () async {
    final repo = TileCacheRepo(
      directory: '${folder.path}${Platform.pathSeparator}none',
    );

    expect(await repo.sizeInBytes(), 0);
    await repo.clear();
  });

  test('has nothing when the folder is not known', () async {
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    final repo = TileCacheRepo(directory: null);

    expect(await repo.sizeInBytes(), 0);
    await repo.clear();
  });
}
