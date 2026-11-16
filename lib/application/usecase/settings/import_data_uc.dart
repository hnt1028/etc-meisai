import 'dart:typed_data';

import 'package:etc_meisai/application/dto/data_summary_dto.dart';
import 'package:etc_meisai/application/interface/app_data_if.dart';
import 'package:etc_meisai/application/interface/backup_if.dart';

/// Replaces everything that is stored with the content of a backup file.
/// Design: PRC-018.
class ImportDataUC {
  const ImportDataUC({required this.appData, required this.backup});

  final AppDataIF appData;
  final BackupIF backup;

  /// Throws a [FormatException] when the file is not a valid backup. In that
  /// case nothing is changed, because reading finishes before the first change.
  /// When the replacement fails, what was stored stays (one transaction).
  Future<DataSummaryDTO> execute(Uint8List bytes) async {
    final data = backup.decode(bytes);
    await appData.replaceAll(data);
    return DataSummaryDTO(
      lineCount: data.statementLines.length,
      mappingCount: data.icMappings.length,
      positionCount: data.icPositions.length,
    );
  }
}
