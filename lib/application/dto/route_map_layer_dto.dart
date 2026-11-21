import 'package:etc_meisai/domain/value/route_map_layer_value.dart';

/// Whether one layer of the route map is shown. Design: PRC-024.
class RouteMapLayerDTO {
  const RouteMapLayerDTO({required this.layer, required this.visible});

  final RouteMapLayerValue layer;
  final bool visible;
}
