import 'dart:typed_data';

import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/application/dto/import_result_dto.dart';
import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';

/// Imports a usage statement CSV into the stored statement lines.
class ImportStatementUC {
  const ImportStatementUC({
    required this.statement,
    required this.statementLines,
  });

  final StatementIF statement;
  final StatementLineIF statementLines;

  /// Imports the CSV given as raw [bytes].
  ///
  /// Throws a [FormatException] when the CSV is invalid. In that case nothing
  /// is stored, because parsing finishes before the first save.
  Future<ImportResultDTO> execute(Uint8List bytes) async {
    final incoming = statement.parse(bytes);

    var added = 0;
    var overwritten = 0;
    var ignored = 0;

    for (final statementLine in incoming) {
      final stored = await statementLines.findSame(statementLine);
      if (stored == null) {
        await statementLines.save(statementLine);
        added++;
      } else if (stored.status == ConfirmationStatusValue.confirmed) {
        ignored++;
      } else {
        await statementLines.save(statementLine);
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
