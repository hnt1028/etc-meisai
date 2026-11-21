import 'package:etc_meisai/application/interface/route_map_layer_if.dart';
import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';

/// Stores whether a layer of the route map is shown. Design: PRC-025.
class SaveRouteMapLayerUC {
  const SaveRouteMapLayerUC({required this.routeMapLayers});

  final RouteMapLayerIF routeMapLayers;

  Future<void> execute({
    required RouteMapLayerValue layer,
    required bool visible,
  }) {
    return routeMapLayers.save(
      RouteMapLayerEntity(layerCode: layer.code, visible: visible),
    );
  }
}
