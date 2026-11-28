import 'package:etc_meisai/application/interface/tile_cache_if.dart';
import 'package:etc_meisai/application/usecase/settings/clear_tile_cache_uc.dart';
import 'package:etc_meisai/application/usecase/settings/get_tile_cache_size_uc.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/settings/tile_cache_providers.dart';
import 'package:etc_meisai/userinterface/settings/tile_cache_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The kept tiles on memory.
class _FakeTileCache implements TileCacheIF {
  _FakeTileCache(this.bytes);

  int bytes;

  /// When set, a read or a deletion throws it.
  Object? error;

  @override
  Future<int> sizeInBytes() async {
    if (error != null) throw error!;
    return bytes;
  }

  @override
  Future<void> clear() async {
    if (error != null) throw error!;
    bytes = 0;
  }
}

Future<void> _show(WidgetTester tester, _FakeTileCache cache) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getTileCacheSizeUCProvider.overrideWithValue(
          GetTileCacheSizeUC(tileCache: cache),
        ),
        clearTileCacheUCProvider.overrideWithValue(
          ClearTileCacheUC(tileCache: cache),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: TileCacheSection())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _size = find.byKey(const ValueKey('tile-cache-size'));
final _clear = find.byKey(const ValueKey('tile-cache-clear'));

void main() {
  test('shows a size in bytes, kilobytes or megabytes', () {
    expect(formatDataSize(0), '0B');
    expect(formatDataSize(1023), '1023B');
    expect(formatDataSize(1024), '1KB');
    expect(formatDataSize(1536), '2KB');
    expect(formatDataSize(1024 * 1024), '1.0MB');
    expect(formatDataSize(12 * 1024 * 1024 + 300 * 1024), '12.3MB');
  });

  testWidgets('shows the size of the kept tiles', (tester) async {
    await _show(tester, _FakeTileCache(5 * 1024 * 1024));

    expect(find.text(SettingsStrings.tileCacheSection), findsOneWidget);
    expect(find.text(SettingsStrings.tileCacheNote), findsOneWidget);
    expect(
      tester.widget<Text>(_size).data,
      SettingsStrings.tileCacheSize('5.0MB'),
    );
  });

  testWidgets('deletes the tiles after a confirmation', (tester) async {
    final cache = _FakeTileCache(1024);
    await _show(tester, cache);

    await tester.tap(_clear);
    await tester.pumpAndSettle();
    expect(find.text(SettingsStrings.tileCacheClearConfirm), findsOneWidget);
    await tester.tap(find.text(SettingsStrings.tileCacheClearOk));
    await tester.pumpAndSettle();

    expect(cache.bytes, 0);
    expect(find.text(SettingsStrings.tileCacheCleared), findsOneWidget);
    expect(
      tester.widget<Text>(_size).data,
      SettingsStrings.tileCacheSize('0B'),
    );
    // There is nothing more to delete.
    expect(tester.widget<OutlinedButton>(_clear).onPressed, isNull);
  });

  testWidgets('deletes nothing when cancelled', (tester) async {
    final cache = _FakeTileCache(1024);
    await _show(tester, cache);

    await tester.tap(_clear);
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.deleteConfirmCancel));
    await tester.pumpAndSettle();

    expect(cache.bytes, 1024);
    expect(find.text(SettingsStrings.tileCacheCleared), findsNothing);
  });

  testWidgets('says so when the tiles could not be deleted', (tester) async {
    final cache = _FakeTileCache(1024);
    await _show(tester, cache);
    cache.error = StateError('x');

    await tester.tap(_clear);
    await tester.pumpAndSettle();
    await tester.tap(find.text(SettingsStrings.tileCacheClearOk));
    await tester.pumpAndSettle();

    expect(find.text(SettingsStrings.tileCacheClearFailed), findsOneWidget);
    expect(find.text(SettingsStrings.tileCacheCleared), findsNothing);
  });

  testWidgets('cannot delete when there is nothing kept', (tester) async {
    await _show(tester, _FakeTileCache(0));

    expect(tester.widget<OutlinedButton>(_clear).onPressed, isNull);
  });

  testWidgets('says so when the size cannot be read', (tester) async {
    final cache = _FakeTileCache(1024)..error = StateError('x');

    await _show(tester, cache);

    expect(find.text(SettingsStrings.tileCacheLoadFailed), findsOneWidget);
    expect(_size, findsNothing);
    expect(tester.widget<OutlinedButton>(_clear).onPressed, isNull);
  });

  testWidgets('waits while the size is read', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getTileCacheSizeUCProvider.overrideWithValue(
            GetTileCacheSizeUC(tileCache: _FakeTileCache(1)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TileCacheSection()),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('the use cases must be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(getTileCacheSizeUCProvider), throwsA(anything));
    expect(() => container.read(clearTileCacheUCProvider), throwsA(anything));
  });
}
