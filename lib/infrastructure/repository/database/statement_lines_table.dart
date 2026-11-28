// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/vehicle_type_converter.dart';
import 'package:uuid/uuid.dart';

/// Stored statement lines. Design: docs/systems/tables/TBL-001-statement-lines.md
@TableIndex(name: 'statement_lines_exit_at', columns: {#exitAt})
class StatementLines extends Table {
  /// UUID version 7, made when the row is first stored.
  TextColumn get id => text().clientDefault(() => const Uuid().v7())();

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

  /// The CSV number of the vehicle type (see [VehicleTypeValue]).
  IntColumn get vehicleType => integer().map(const VehicleTypeConverter())();

  /// Null when the CSV leaves it blank and the user has not entered one.
  IntColumn get vehicleNumber => integer().nullable()();

  /// What the user entered when the CSV left the entrance blank. They are kept
  /// apart from [entranceAt] and [entranceIc], which the duplicate key uses,
  /// so that entering them does not change the key (docs/csv-format.md).
  DateTimeColumn get enteredEntranceAt => dateTime().nullable()();
  TextColumn get enteredEntranceIc => text().nullable()();

  TextColumn get cardNumber => text()();

  /// Stored as the position in [ConfirmationStatusValue] (0 confirmed, 1 pending).
  /// Do not reorder the enum.
  IntColumn get status => intEnum<ConfirmationStatusValue>()();

  /// Discount types joined with `;`, like the CSV note. Empty when none.
  TextColumn get discountTypes => text()();

  /// A note of the user. Empty when there is none. The import does not touch
  /// it, so that a line that is imported again keeps its note.
  TextColumn get memo => text().withDefault(const Constant(''))();

  /// Tags of the user joined with `;`. Empty when none.
  TextColumn get tags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
