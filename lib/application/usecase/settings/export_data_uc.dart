import 'package:etc_meisai/application/dto/data_summary_dto.dart';
import 'package:etc_meisai/application/dto/export_data_dto.dart';
import 'package:etc_meisai/application/interface/app_data_if.dart';
import 'package:etc_meisai/application/interface/backup_if.dart';

/// Makes the backup file of everything that is stored. Design: PRC-017.
class ExportDataUC {
  const ExportDataUC({
    required this.appData,
    required this.backup,
    this.now = DateTime.now,
  });

  final AppDataIF appData;
  final BackupIF backup;

  /// The time of the export, for the file name. Tests give a fixed one.
  final DateTime Function() now;

  Future<ExportDataDTO> execute() async {
    final data = await appData.readAll();
    final exportedAt = now();
    return ExportDataDTO(
      fileName: _fileName(exportedAt),
      bytes: backup.encode(data, exportedAt),
      summary: DataSummaryDTO(
        lineCount: data.statementLines.length,
        mappingCount: data.icMappings.length,
        positionCount: data.icPositions.length,
      ),
    );
  }

  /// etc-meisai-backup-20261116-1234.json
  static String _fileName(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'etc-meisai-backup-${time.year}${two(time.month)}${two(time.day)}'
        '-${two(time.hour)}${two(time.minute)}.json';
  }
}
