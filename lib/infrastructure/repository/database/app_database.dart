import 'package:drift/drift.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/ic_mappings_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/ic_positions_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/operator_colors_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/route_map_layers_table.dart';
import 'package:etc_meisai/infrastructure/repository/database/vehicle_type_converter.dart';
import 'package:etc_meisai/infrastructure/repository/database/statement_lines_table.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

/// The SQLite database of the app.
@DriftDatabase(
  tables: [
    StatementLines,
    IcMappings,
    IcPositions,
    OperatorColors,
    RouteMapLayers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 7;

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
              // The rebuild gives the table its current columns, so the ones
              // of the later versions have to be new here too.
              statementLines.memo,
              statementLines.tags,
            ],
          ),
        );
      }
      // Version 5 added the colors of the road operators (TBL-004).
      if (from < 5) await m.createTable(operatorColors);
      // Version 6 added what the user chose to show on the route map (TBL-005).
      if (from < 6) await m.createTable(routeMapLayers);
      // Version 7 added the memo and the tags of a statement line (TBL-001).
      // The database of version 3 or older got them with the rebuild of
      // version 4, so they may be there.
      if (from < 7) {
        final columns = {
          for (final row in await customSelect(
            'PRAGMA table_info(statement_lines)',
          ).get())
            row.read<String>('name'),
        };
        if (!columns.contains('memo')) {
          await m.addColumn(statementLines, statementLines.memo);
        }
        if (!columns.contains('tags')) {
          await m.addColumn(statementLines, statementLines.tags);
        }
      }
    },
  );
}
