import 'package:drift/drift.dart';

import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';

/// Keeps statement lines in the SQLite database.
class StatementLineRepo implements StatementLineIF {
  const StatementLineRepo(this._db);

  final AppDatabase _db;

  /// The duplicate key of docs/csv-format.md. It never leaves this class.
  static String _key(StatementLineEntity statementLine) {
    return [
      statementLine.entranceAt?.toIso8601String() ?? '',
      statementLine.entranceIc ?? '',
      statementLine.exitIc,
      statementLine.cardNumber,
    ].join('|');
  }

  @override
  Future<StatementLineEntity?> findSame(
    StatementLineEntity statementLine,
  ) async {
    final row =
        await (_db.select(_db.statementLines)
              ..where((t) => t.duplicateKey.equals(_key(statementLine))))
            .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(StatementLineEntity statementLine) async {
    final companion = _toCompanion(statementLine);
    await _db
        .into(_db.statementLines)
        .insert(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            target: [_db.statementLines.duplicateKey],
          ),
        );
  }

  @override
  Future<StatementLineEntity?> findById(String id) async {
    final row = await (_db.select(
      _db.statementLines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> updateVehicleNumber(String id, int vehicleNumber) async {
    await (_db.update(_db.statementLines)..where((t) => t.id.equals(id))).write(
      StatementLinesCompanion(vehicleNumber: Value(vehicleNumber)),
    );
  }

  @override
  Future<List<StatementLineEntity>> findAll() async {
    final rows = await (_db.select(
      _db.statementLines,
    )..orderBy([(t) => OrderingTerm.asc(t.exitAt)])).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.statementLines).go();
  }

  StatementLinesCompanion _toCompanion(StatementLineEntity statementLine) {
    return StatementLinesCompanion.insert(
      duplicateKey: _key(statementLine),
      entranceAt: Value(statementLine.entranceAt),
      exitAt: statementLine.exitAt,
      entranceIc: Value(statementLine.entranceIc),
      exitIc: statementLine.exitIc,
      grossFare: Value(statementLine.grossFare),
      etcDiscount: Value(statementLine.etcDiscount),
      fare: statementLine.fare,
      fareAfterRebate: statementLine.fareAfterRebate,
      postpaidFare: statementLine.postpaidFare,
      vehicleType: statementLine.vehicleType,
      vehicleNumber: Value(statementLine.vehicleNumber),
      cardNumber: statementLine.cardNumber,
      status: statementLine.status,
      discountTypes: statementLine.discountTypes.join(';'),
    );
  }

  StatementLineEntity _toEntity(StatementLine row) {
    return StatementLineEntity(
      id: row.id,
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
      cardNumber: row.cardNumber,
      status: row.status,
      discountTypes: row.discountTypes.isEmpty
          ? const []
          : row.discountTypes.split(';'),
    );
  }
}
