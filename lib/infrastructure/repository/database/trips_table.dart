import 'package:drift/drift.dart';

import '../../../domain/value/confirmation_status_value.dart';

/// Stored trips. Design: docs/systems/tables/TBL-001-trips.md
@TableIndex(name: 'trips_exit_at', columns: {#exitAt})
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The duplicate key of docs/csv-format.md joined into one text.
  /// Entrance columns can be null, so a unique index on them would not work.
  TextColumn get duplicateKey => text().unique()();

  DateTimeColumn get entranceAt => dateTime().nullable()();
  DateTimeColumn get exitAt => dateTime()();
  TextColumn get entranceIc => text().nullable()();
  TextColumn get exitIc => text()();
  IntColumn get grossFare => integer().nullable()();
  IntColumn get etcDiscount => integer().nullable()();
  IntColumn get fare => integer()();
  IntColumn get fareAfterRebate => integer()();
  IntColumn get postpaidFare => integer()();
  TextColumn get vehicleType => text()();
  TextColumn get vehicleNumber => text()();
  TextColumn get cardNumber => text()();
  TextColumn get status => textEnum<ConfirmationStatusValue>()();

  /// Discount types joined with `;`, like the CSV note. Empty when none.
  TextColumn get discountTypes => text()();
}
