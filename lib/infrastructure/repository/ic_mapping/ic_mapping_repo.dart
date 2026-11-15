import 'package:etc_meisai/application/interface/ic_mapping_if.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Keeps the IC mappings in the SQLite database (TBL-002).
class IcMappingRepo implements IcMappingIF {
  const IcMappingRepo(this._db);

  final AppDatabase _db;

  @override
  Future<List<IcMappingEntity>> findAll() async {
    final rows = await _db.select(_db.icMappings).get();
    return [
      for (final row in rows)
        IcMappingEntity(icName: row.icName, pointId: row.pointId),
    ];
  }

  @override
  Future<void> save(IcMappingEntity mapping) => _db
      .into(_db.icMappings)
      .insertOnConflictUpdate(
        IcMappingsCompanion.insert(
          icName: mapping.icName,
          pointId: mapping.pointId,
        ),
      );

  @override
  Future<void> delete(String icName) async {
    await (_db.delete(
      _db.icMappings,
    )..where((t) => t.icName.equals(icName))).go();
  }
}
