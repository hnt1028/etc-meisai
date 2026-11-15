import 'package:etc_meisai/domain/entity/statement_line_entity.dart';

/// Stores and reads statement lines on the device.
///
/// Rules such as "confirmed statement lines are never overwritten" belong to the
/// usecase, not to implementations of this interface.
abstract interface class StatementLineIF {
  /// Returns the stored statement line that has the same duplicate key as [statement line],
  /// or null when there is none.
  ///
  /// The key is entrance date and time, entrance IC, exit IC and card number.
  Future<StatementLineEntity?> findSame(StatementLineEntity statementLine);

  /// Stores [statement line]. If a statement line with the same duplicate key is already stored,
  /// it is replaced.
  Future<void> save(StatementLineEntity statementLine);

  /// Returns every stored statement line.
  Future<List<StatementLineEntity>> findAll();

  /// Removes every stored statement line.
  Future<void> deleteAll();
}
