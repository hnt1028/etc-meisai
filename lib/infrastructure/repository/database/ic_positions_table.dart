// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';

/// Positions the user chose on the map. Design: docs/systems/tables/TBL-003-ic-positions.md
class IcPositions extends Table {
  /// The IC name as written in the CSV.
  TextColumn get icName => text()();

  /// Degrees.
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  @override
  Set<Column> get primaryKey => {icName};
}
