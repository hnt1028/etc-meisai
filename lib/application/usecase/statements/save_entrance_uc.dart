import 'package:etc_meisai/application/interface/statement_line_if.dart';

/// Saves the entrance date and time and the entrance IC the user entered for a
/// statement line whose CSV row left them blank. Each can be saved once.
/// Design: PRC-015.
class SaveEntranceUC {
  const SaveEntranceUC({required this.statementLines});

  final StatementLineIF statementLines;

  /// Throws [ArgumentError] when nothing is given, when [entranceIc] is blank,
  /// or when [entranceAt] is after the exit, and [StateError] when the line is
  /// not found or already has what is given. The messages never include what
  /// the user entered.
  Future<void> execute({
    required String id,
    DateTime? entranceAt,
    String? entranceIc,
  }) async {
    final ic = entranceIc?.trim();
    if (entranceAt == null && ic == null) {
      throw ArgumentError('Nothing is given.');
    }
    if (ic != null && ic.isEmpty) {
      throw ArgumentError('The entrance IC is blank.');
    }
    final line = await statementLines.findById(id);
    if (line == null) throw StateError('The statement line is not found.');
    if (entranceAt != null) {
      if (line.entranceAt != null) {
        throw StateError('The statement line already has an entrance time.');
      }
      if (entranceAt.isAfter(line.exitAt)) {
        throw ArgumentError('The entrance is after the exit.');
      }
    }
    if (ic != null && line.entranceIc != null) {
      throw StateError('The statement line already has an entrance IC.');
    }
    await statementLines.updateEntrance(
      id,
      entranceAt: entranceAt,
      entranceIc: ic,
    );
  }
}
