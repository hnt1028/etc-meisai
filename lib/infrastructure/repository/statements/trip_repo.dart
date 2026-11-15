import 'package:drift/drift.dart';

import '../../../application/interface/trip_if.dart';
import '../../../domain/entity/trip_entity.dart';
import '../database/app_database.dart';

/// Keeps trips in the SQLite database.
class TripRepo implements TripIF {
  const TripRepo(this._db);

  final AppDatabase _db;

  /// The duplicate key of docs/csv-format.md. It never leaves this class.
  static String _key(TripEntity trip) {
    return [
      trip.entranceAt?.toIso8601String() ?? '',
      trip.entranceIc ?? '',
      trip.exitIc,
      trip.cardNumber,
    ].join('|');
  }

  @override
  Future<TripEntity?> findSame(TripEntity trip) async {
    final row = await (_db.select(
      _db.trips,
    )..where((t) => t.duplicateKey.equals(_key(trip)))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> save(TripEntity trip) async {
    final companion = _toCompanion(trip);
    await _db
        .into(_db.trips)
        .insert(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            target: [_db.trips.duplicateKey],
          ),
        );
  }

  @override
  Future<List<TripEntity>> findAll() async {
    final rows = await (_db.select(
      _db.trips,
    )..orderBy([(t) => OrderingTerm.asc(t.exitAt)])).get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete(_db.trips).go();
  }

  TripsCompanion _toCompanion(TripEntity trip) {
    return TripsCompanion.insert(
      duplicateKey: _key(trip),
      entranceAt: Value(trip.entranceAt),
      exitAt: trip.exitAt,
      entranceIc: Value(trip.entranceIc),
      exitIc: trip.exitIc,
      grossFare: Value(trip.grossFare),
      etcDiscount: Value(trip.etcDiscount),
      fare: trip.fare,
      fareAfterRebate: trip.fareAfterRebate,
      postpaidFare: trip.postpaidFare,
      vehicleType: trip.vehicleType,
      vehicleNumber: trip.vehicleNumber,
      cardNumber: trip.cardNumber,
      status: trip.status,
      discountTypes: trip.discountTypes.join(';'),
    );
  }

  TripEntity _toEntity(Trip row) {
    return TripEntity(
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
