/// What the user chose for one layer of the route map: shown or not.
/// Design: docs/systems/tables/TBL-005-route-map-layers.md
class RouteMapLayerEntity {
  const RouteMapLayerEntity({required this.layerCode, required this.visible});

  /// `RouteMapLayerValue.code`.
  final String layerCode;

  final bool visible;
}
