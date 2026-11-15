// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';

/// IC mappings the user registered. Design: docs/systems/tables/TBL-002-ic-mappings.md
class IcMappings extends Table {
  /// The IC name as written in the CSV.
  TextColumn get icName => text()();

  /// The id of the IC point in the IC master.
  TextColumn get pointId => text()();

  @override
  Set<Column> get primaryKey => {icName};
}
