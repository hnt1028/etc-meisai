import 'package:etc_meisai/application/usecase/settings/delete_all_statement_lines_uc.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
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
