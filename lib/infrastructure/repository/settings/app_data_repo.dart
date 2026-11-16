import 'package:drift/drift.dart';
import 'package:etc_meisai/application/interface/app_data_if.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_record_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Reads, replaces and deletes all the tables of the database as a whole.
class AppDataRepo implements AppDataIF {
  const AppDataRepo(this._db);

  final AppDatabase _db;

  @override
  Future<AppDataEntity> readAll() async {
    final lines =
        await (_db.select(_db.statementLines)..orderBy([
              (t) => OrderingTerm.asc(t.exitAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
            .get();
    final mappings = await (_db.select(
      _db.icMappings,
    )..orderBy([(t) => OrderingTerm.asc(t.icName)])).get();
    final positions = await (_db.select(
      _db.icPositions,
    )..orderBy([(t) => OrderingTerm.asc(t.icName)])).get();
    return AppDataEntity(
      statementLines: [for (final row in lines) _toRecord(row)],
      icMappings: [
        for (final row in mappings)
          IcMappingEntity(icName: row.icName, pointId: row.pointId),
      ],
      icPositions: [
        for (final row in positions)
          IcPositionEntity(
            icName: row.icName,
            latitude: row.latitude,
            longitude: row.longitude,
          ),
      ],
    );
  }

  @override
  Future<void> replaceAll(AppDataEntity data) {
    return _db.transaction(() async {
      await _deleteTables();
      await _db.batch((batch) {
        batch.insertAll(_db.statementLines, [
          for (final line in data.statementLines) _toCompanion(line),
        ]);
        batch.insertAll(_db.icMappings, [
          for (final m in data.icMappings)
            IcMappingsCompanion.insert(icName: m.icName, pointId: m.pointId),
        ]);
        batch.insertAll(_db.icPositions, [
          for (final p in data.icPositions)
            IcPositionsCompanion.insert(
              icName: p.icName,
              latitude: p.latitude,
              longitude: p.longitude,
            ),
        ]);
      });
    });
  }

  @override
  Future<void> deleteAll() => _db.transaction(_deleteTables);

  Future<void> _deleteTables() async {
    await _db.delete(_db.statementLines).go();
    await _db.delete(_db.icMappings).go();
    await _db.delete(_db.icPositions).go();
  }

  StatementLineRecordEntity _toRecord(StatementLine row) {
    return StatementLineRecordEntity(
      id: row.id,
      duplicateKey: row.duplicateKey,
      entranceAt: row.entranceAt,
      exitAt: row.exitAt,
      entranceIc: row.entranceIc,
      exitIc: row.exitIc,
      grossFare: row.grossFare,
      etcDiscount: row.etcDiscount,
      fare: row.fare,
      fareAfterRebate: row.fareAfterRebate,
      postpaidFare: row.postpaidFare,
      vehicleType: row.vehicleType,
      vehicleNumber: row.vehicleNumber,
      enteredEntranceAt: row.enteredEntranceAt,
      enteredEntranceIc: row.enteredEntranceIc,
      cardNumber: row.cardNumber,
      status: row.status,
      discountTypes: row.discountTypes.isEmpty
          ? const []
          : row.discountTypes.split(';'),
    );
  }

  StatementLinesCompanion _toCompanion(StatementLineRecordEntity line) {
    return StatementLinesCompanion.insert(
      id: Value(line.id),
      duplicateKey: line.duplicateKey,
      entranceAt: Value(line.entranceAt),
      exitAt: line.exitAt,
      entranceIc: Value(line.entranceIc),
      exitIc: line.exitIc,
      grossFare: Value(line.grossFare),
      etcDiscount: Value(line.etcDiscount),
      fare: line.fare,
      fareAfterRebate: line.fareAfterRebate,
      postpaidFare: line.postpaidFare,
      vehicleType: line.vehicleType,
      vehicleNumber: Value(line.vehicleNumber),
      enteredEntranceAt: Value(line.enteredEntranceAt),
      enteredEntranceIc: Value(line.enteredEntranceIc),
      cardNumber: line.cardNumber,
      status: line.status,
      discountTypes: line.discountTypes.join(';'),
    );
  }
}
