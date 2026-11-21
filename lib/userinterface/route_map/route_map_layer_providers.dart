import 'package:etc_meisai/application/dto/route_map_layer_dto.dart';
import 'package:etc_meisai/application/dto/route_map_option_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_options_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_option_uc.dart';
import 'package:etc_meisai/domain/value/route_map_option_value.dart';
import 'package:etc_meisai/application/dto/route_network_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_layers_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_network_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_layer_uc.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final listRouteMapLayersUCProvider = Provider<ListRouteMapLayersUC>(
  (ref) => throw UnimplementedError('Override listRouteMapLayersUCProvider'),
);

final saveRouteMapLayerUCProvider = Provider<SaveRouteMapLayerUC>(
  (ref) => throw UnimplementedError('Override saveRouteMapLayerUCProvider'),
);

final listRouteMapOptionsUCProvider = Provider<ListRouteMapOptionsUC>(
  (ref) => throw UnimplementedError('Override listRouteMapOptionsUCProvider'),
);

final saveRouteMapOptionUCProvider = Provider<SaveRouteMapOptionUC>(
  (ref) => throw UnimplementedError('Override saveRouteMapOptionUCProvider'),
);

final listRouteNetworkUCProvider = Provider<ListRouteNetworkUC>(
  (ref) => throw UnimplementedError('Override listRouteNetworkUCProvider'),
);

/// What the route map shows (PRC-024). It is read again when the stored data
/// is replaced or deleted (a restore, a deletion), and after a choice is
/// saved.
final routeMapLayersProvider = FutureProvider<List<RouteMapLayerDTO>>((
  ref,
) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(listRouteMapLayersUCProvider).execute();
}, retry: (_, _) => null);

/// The numbers of the route map (PRC-030). Read again like the layers.
final routeMapOptionsProvider = FutureProvider<List<RouteMapOptionDTO>>((
  ref,
) async {
  ref.watch(dataRevisionProvider);
  return ref.watch(listRouteMapOptionsUCProvider).execute();
}, retry: (_, _) => null);

/// The width of the lines of the driven roads. While the numbers are not read
/// (or cannot be read), the default.
int lineWidthOf(List<RouteMapOptionDTO>? options) {
  for (final o in options ?? const <RouteMapOptionDTO>[]) {
    if (o.option == RouteMapOptionValue.lineWidth) return o.value;
  }
  return RouteMapOptionValue.lineWidth.defaultValue;
}

/// Every road of the IC master (PRC-026). The master does not change while the
/// app runs, so it is made once.
final routeNetworkProvider = FutureProvider<RouteNetworkDTO>(
  (ref) => ref.watch(listRouteNetworkUCProvider).execute(),
  retry: (_, _) => null,
);

/// The layers that are shown. While the choices are not read (or cannot be
/// read), the defaults.
Set<RouteMapLayerValue> shownLayers(List<RouteMapLayerDTO>? layers) {
  if (layers == null) {
    return {
      for (final l in RouteMapLayerValue.values)
        if (l.defaultVisible) l,
    };
  }
  return {
    for (final l in layers)
      if (l.visible) l.layer,
  };
}
