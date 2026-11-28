import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
import 'package:etc_meisai/userinterface/route_map/tile_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final listRouteMapUCProvider = Provider<ListRouteMapUC>(
  (ref) => throw UnimplementedError('Override listRouteMapUCProvider'),
);

final saveIcPositionUCProvider = Provider<SaveIcPositionUC>(
  (ref) => throw UnimplementedError('Override saveIcPositionUCProvider'),
);

final deleteIcPositionUCProvider = Provider<DeleteIcPositionUC>(
  (ref) => throw UnimplementedError('Override deleteIcPositionUCProvider'),
);

/// The cache of the map tiles, made in lib/main.dart (see `createTileCache`).
/// Null in the tests, and when the folder is not found: the usual cache is
/// used then.
final tileCacheProvider = Provider<MapCachingProvider?>((ref) => null);

/// The map tiles of OpenStreetMap. This is the only thing the app fetches from
/// the network (docs/privacy.md). Tests replace it, so that they need no
/// network.
///
/// A tile that was seen is kept for 90 days, and is used when the network is
/// not there, even if it is older (see `createTileCache`, `StaleTileClient`).
/// A tile that fails is tried again (see [createTileClient]), and is asked for
/// again when it is shown again (the map is moved): a failed tile is not kept.
final tileLayerProvider = Provider<Widget>((ref) {
  final cache = ref.watch(tileCacheProvider);
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'jp.mtrk.etc_meisai',
    tileProvider: NetworkTileProvider(
      httpClient: createTileClient(cache: cache),
      cachingProvider: cache,
    ),
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
  );
});
