import 'package:drift/drift.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/vehicle_type_converter.dart';
import 'package:etc_meisai/infrastructure/repository/database/statement_lines_table.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

/// The SQLite database of the app.
@DriftDatabase(tables: [StatementLines])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
