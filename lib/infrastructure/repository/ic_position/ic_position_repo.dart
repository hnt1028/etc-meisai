import 'package:etc_meisai/application/interface/ic_position_if.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Keeps the positions the user chose in the SQLite database (TBL-003).
class IcPositionRepo implements IcPositionIF {
  const IcPositionRepo(this._db);

  final AppDatabase _db;

  @override
  Future<List<IcPositionEntity>> findAll() async {
    final rows = await _db.select(_db.icPositions).get();
    return [
      for (final row in rows)
        IcPositionEntity(
          icName: row.icName,
          latitude: row.latitude,
          longitude: row.longitude,
        ),
    ];
  }

  @override
  Future<void> save(IcPositionEntity position) => _db
      .into(_db.icPositions)
      .insertOnConflictUpdate(
        IcPositionsCompanion.insert(
          icName: position.icName,
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );

  @override
  Future<void> delete(String icName) async {
    await (_db.delete(
      _db.icPositions,
    )..where((t) => t.icName.equals(icName))).go();
  }
}
