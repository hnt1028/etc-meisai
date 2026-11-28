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

  /// Stores the entrance date and time and the entrance IC the user entered
  /// for the line with the id [id]. A null argument is left as it is. They are
  /// kept apart from the CSV's values, and the duplicate key does not change.
  /// The rule that only blank ones may be entered belongs to the usecase.
  Future<void> updateEntrance(
    String id, {
    DateTime? entranceAt,
    String? entranceIc,
  });

  /// Returns every stored statement line.
  /// Stores the note of the line [id]: replaces its memo and its tags.
  Future<void> updateNote(
    String id, {
    required String memo,
    required List<String> tags,
  });

  Future<List<StatementLineEntity>> findAll();

  /// Removes every stored statement line.
  Future<void> deleteAll();
}
