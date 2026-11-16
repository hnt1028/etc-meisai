import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/delete_all_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/export_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_data_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/userinterface/settings/backup_files.dart';
import 'package:etc_meisai/userinterface/settings/csv_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The use cases are built in lib/main.dart (the only place that wires the
/// layers together) and given here with ProviderScope overrides.
final importStatementUCProvider = Provider<ImportStatementUC>(
  (ref) => throw UnimplementedError('Override importStatementUCProvider'),
);

final deleteAllStatementLinesUCProvider = Provider<DeleteAllStatementLinesUC>(
  (ref) =>
      throw UnimplementedError('Override deleteAllStatementLinesUCProvider'),
);

final csvPickerProvider = Provider<CsvPicker>((ref) => pickCsv);

final exportDataUCProvider = Provider<ExportDataUC>(
  (ref) => throw UnimplementedError('Override exportDataUCProvider'),
);

final importDataUCProvider = Provider<ImportDataUC>(
  (ref) => throw UnimplementedError('Override importDataUCProvider'),
);

final deleteAllDataUCProvider = Provider<DeleteAllDataUC>(
  (ref) => throw UnimplementedError('Override deleteAllDataUCProvider'),
);

/// Choosing a backup file to read, and choosing where to save one. Tests
/// replace them.
final backupPickerProvider = Provider<BackupPicker>((ref) => pickBackup);

final backupSaverProvider = Provider<BackupSaver>((ref) => saveBackup);
