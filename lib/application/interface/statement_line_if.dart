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

  /// Returns the stored statement line with the id [id], or null.
  Future<StatementLineEntity?> findById(String id);

  /// Sets the vehicle number of the stored line with the id [id]. The rule
  /// that only a line without one may be changed belongs to the usecase.
  Future<void> updateVehicleNumber(String id, int vehicleNumber);

  /// Returns every stored statement line.
  Future<List<StatementLineEntity>> findAll();

  /// Removes every stored statement line.
  Future<void> deleteAll();
}
