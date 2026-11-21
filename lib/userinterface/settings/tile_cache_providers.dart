import 'package:etc_meisai/application/usecase/settings/clear_tile_cache_uc.dart';
import 'package:etc_meisai/application/usecase/settings/get_tile_cache_size_uc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final getTileCacheSizeUCProvider = Provider<GetTileCacheSizeUC>(
  (ref) => throw UnimplementedError('Override getTileCacheSizeUCProvider'),
);

final clearTileCacheUCProvider = Provider<ClearTileCacheUC>(
  (ref) => throw UnimplementedError('Override clearTileCacheUCProvider'),
);

/// The size of the kept map tiles in bytes (PRC-028). It is read every time
/// the settings screen is opened, and again after the tiles are deleted.
final tileCacheSizeProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(getTileCacheSizeUCProvider).execute(),
  retry: (_, _) => null,
);
