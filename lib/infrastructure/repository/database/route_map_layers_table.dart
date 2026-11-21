// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';

/// What the user chose to show on the route map. Design: docs/systems/tables/TBL-005-route-map-layers.md
class RouteMapLayers extends Table {
  /// `RouteMapLayerValue.code`, such as `network`.
  TextColumn get layerCode => text()();

  /// Whether the layer is shown.
  BoolColumn get visible => boolean()();

  @override
  Set<Column> get primaryKey => {layerCode};
}
