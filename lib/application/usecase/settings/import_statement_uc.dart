import 'dart:typed_data';

import '../../../domain/value/confirmation_status_value.dart';
import '../../dto/import_result_dto.dart';
import '../../interface/statement_if.dart';
import '../../interface/trip_if.dart';

/// Imports a usage statement CSV into the stored trips.
class ImportStatementUC {
  const ImportStatementUC({required this.statement, required this.trips});

  final StatementIF statement;
  final TripIF trips;

  /// Imports the CSV given as raw [bytes].
  ///
  /// Throws a [FormatException] when the CSV is invalid. In that case nothing
  /// is stored, because parsing finishes before the first save.
  Future<ImportResultDTO> execute(Uint8List bytes) async {
    final incoming = statement.parse(bytes);

    var added = 0;
    var overwritten = 0;
    var ignored = 0;

    for (final trip in incoming) {
      final stored = await trips.findSame(trip);
      if (stored == null) {
        await trips.save(trip);
        added++;
      } else if (stored.status == ConfirmationStatusValue.confirmed) {
        ignored++;
      } else {
        await trips.save(trip);
        overwritten++;
      }
    }

    return ImportResultDTO(
      addedCount: added,
      overwrittenCount: overwritten,
      ignoredCount: ignored,
    );
  }
}
