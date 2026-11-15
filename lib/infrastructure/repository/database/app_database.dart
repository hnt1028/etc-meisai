import 'package:drift/drift.dart';

import '../../../domain/value/confirmation_status_value.dart';
import 'trips_table.dart';

part 'app_database.g.dart';

/// The SQLite database of the app.
@DriftDatabase(tables: [Trips])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
