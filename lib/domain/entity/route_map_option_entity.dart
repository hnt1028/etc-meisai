/// What the user set for one number of the route map.
/// Design: docs/systems/tables/TBL-006-route-map-options.md
class RouteMapOptionEntity {
  const RouteMapOptionEntity({required this.optionCode, required this.value});

  /// `RouteMapOptionValue.code`.
  final String optionCode;

  final int value;
}
