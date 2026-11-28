// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';

/// Colors the user chose for road operators. Design: docs/systems/tables/TBL-004-operator-colors.md
class OperatorColors extends Table {
  /// The road operator, such as NEXCO東日本.
  TextColumn get operatorName => text()();

  /// Opaque ARGB, `0xFFRRGGBB`.
  IntColumn get color => integer()();

  @override
  Set<Column> get primaryKey => {operatorName};
}
