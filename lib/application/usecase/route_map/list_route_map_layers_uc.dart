import 'package:etc_meisai/application/dto/route_map_layer_dto.dart';
import 'package:etc_meisai/application/interface/route_map_layer_if.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';

/// Lists every layer of the route map, shown or not: what the user chose, or
/// else the default. Design: PRC-024.
class ListRouteMapLayersUC {
  const ListRouteMapLayersUC({required this.routeMapLayers});

  final RouteMapLayerIF routeMapLayers;

  /// In the order of [RouteMapLayerValue.values].
  Future<List<RouteMapLayerDTO>> execute() async {
    final chosen = {
      for (final l in await routeMapLayers.findAll()) l.layerCode: l.visible,
    };
    return [
      for (final layer in RouteMapLayerValue.values)
        RouteMapLayerDTO(
          layer: layer,
          visible: chosen[layer.code] ?? layer.defaultVisible,
        ),
    ];
  }
}
