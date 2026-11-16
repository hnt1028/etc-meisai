import 'package:etc_meisai/application/interface/statement_line_if.dart';

/// Saves the vehicle number the user entered for a statement line whose CSV
/// row left it blank. It can be saved once. Design: PRC-014.
class SaveVehicleNumberUC {
  const SaveVehicleNumberUC({required this.statementLines});

  /// The vehicle numbers that can be entered: one to four digits.
  static const smallest = 1;
  static const largest = 9999;

  final StatementLineIF statementLines;

  /// Throws [ArgumentError] when [vehicleNumber] is out of range, and
  /// [StateError] when the line is not found or already has a vehicle number.
  /// The messages never include the number: it is personal data.
  Future<void> execute({required String id, required int vehicleNumber}) async {
    if (vehicleNumber < smallest || vehicleNumber > largest) {
      throw ArgumentError('The vehicle number is out of range.');
    }
    final line = await statementLines.findById(id);
    if (line == null) throw StateError('The statement line is not found.');
    if (line.vehicleNumber != null) {
      throw StateError('The statement line already has a vehicle number.');
    }
    await statementLines.updateVehicleNumber(id, vehicleNumber);
  }
}
