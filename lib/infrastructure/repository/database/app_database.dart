import 'package:drift/drift.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/ic_mappings_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/ic_positions_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/vehicle_type_converter.dart';
import 'package:etc_meisai/infrastructure/repository/database/statement_lines_table.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

/// The SQLite database of the app.
@DriftDatabase(tables: [StatementLines, IcMappings, IcPositions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Version 2 added the IC mappings (TBL-002).
      if (from < 2) await m.createTable(icMappings);
      // Version 3 added the positions the user chose (TBL-003).
      if (from < 3) await m.createTable(icPositions);
      // Version 4 lets the vehicle number be null (a blank in the CSV), and
      // keeps the entrance the user entered apart from the CSV's.
      if (from < 4) {
        await m.alterTable(
          TableMigration(
            statementLines,
            newColumns: [
              statementLines.enteredEntranceAt,
              statementLines.enteredEntranceIc,
            ],
          ),
        );
      }
    },
  );
}
