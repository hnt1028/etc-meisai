import 'package:drift/drift.dart';
import 'package:etc_meisai/application/interface/operator_color_if.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Stores the colors of the operators in the database
/// (docs/systems/tables/TBL-004-operator-colors.md).
class OperatorColorRepo implements OperatorColorIF {
  const OperatorColorRepo(this._db);

  final AppDatabase _db;

  @override
  Future<List<OperatorColorEntity>> findAll() async {
    final rows = await (_db.select(
      _db.operatorColors,
    )..orderBy([(t) => OrderingTerm.asc(t.operatorName)])).get();
    return [
      for (final row in rows)
        OperatorColorEntity(operatorName: row.operatorName, color: row.color),
    ];
  }

  @override
  Future<void> save(OperatorColorEntity color) {
    return _db
        .into(_db.operatorColors)
        .insertOnConflictUpdate(
          OperatorColorsCompanion.insert(
            operatorName: color.operatorName,
            color: color.color,
          ),
        );
  }

  @override
  Future<void> delete(String operatorName) {
    return (_db.delete(
      _db.operatorColors,
    )..where((t) => t.operatorName.equals(operatorName))).go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.operatorColors).go();
}
