// coverage:ignore-file
// The columns are only declarations; drift's generated code runs them.
import 'package:drift/drift.dart';

/// The numbers the user set for the route map. Design: docs/systems/tables/TBL-006-route-map-options.md
class RouteMapOptions extends Table {
  /// `RouteMapOptionValue.code`, such as `lineWidth`.
  TextColumn get optionCode => text()();

  /// The number.
  IntColumn get value => integer()();

  @override
  Set<Column> get primaryKey => {optionCode};
}
