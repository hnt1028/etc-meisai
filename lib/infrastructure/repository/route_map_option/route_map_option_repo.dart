import 'package:drift/drift.dart';
import 'package:etc_meisai/application/interface/route_map_option_if.dart';
import 'package:etc_meisai/domain/entity/route_map_option_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Stores the numbers of the route map in the database
/// (docs/systems/tables/TBL-006-route-map-options.md).
class RouteMapOptionRepo implements RouteMapOptionIF {
  const RouteMapOptionRepo(this._db);

  final AppDatabase _db;

  @override
  Future<List<RouteMapOptionEntity>> findAll() async {
    final rows = await (_db.select(
      _db.routeMapOptions,
    )..orderBy([(t) => OrderingTerm.asc(t.optionCode)])).get();
    return [
      for (final row in rows)
        RouteMapOptionEntity(optionCode: row.optionCode, value: row.value),
    ];
  }

  @override
  Future<void> save(RouteMapOptionEntity option) {
    return _db
        .into(_db.routeMapOptions)
        .insertOnConflictUpdate(
          RouteMapOptionsCompanion.insert(
            optionCode: option.optionCode,
            value: option.value,
          ),
        );
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.routeMapOptions).go();
}
