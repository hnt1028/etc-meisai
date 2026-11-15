import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
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

/// The map tiles of OpenStreetMap. This is the only thing the app fetches from
/// the network (docs/privacy.md). Tests replace it, so that they need no
/// network.
final tileLayerProvider = Provider<Widget>(
  (ref) => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'jp.mtrk.etc_meisai',
  ),
);
