import 'package:drift/drift.dart';
import 'package:etc_meisai/application/interface/route_map_layer_if.dart';
import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Stores what the user chose to show on the route map in the database
/// (docs/systems/tables/TBL-005-route-map-layers.md).
class RouteMapLayerRepo implements RouteMapLayerIF {
  const RouteMapLayerRepo(this._db);

  final AppDatabase _db;

  @override
  Future<List<RouteMapLayerEntity>> findAll() async {
    final rows = await (_db.select(
      _db.routeMapLayers,
    )..orderBy([(t) => OrderingTerm.asc(t.layerCode)])).get();
    return [
      for (final row in rows)
        RouteMapLayerEntity(layerCode: row.layerCode, visible: row.visible),
    ];
  }

  @override
  Future<void> save(RouteMapLayerEntity layer) {
    return _db
        .into(_db.routeMapLayers)
        .insertOnConflictUpdate(
          RouteMapLayersCompanion.insert(
            layerCode: layer.layerCode,
            visible: layer.visible,
          ),
        );
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.routeMapLayers).go();
}
