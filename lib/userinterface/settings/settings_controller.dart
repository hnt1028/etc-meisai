import 'package:etc_meisai/application/dto/import_result_dto.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the settings screen shows. Only one of [result], [error] and [notice]
/// is set at a time.
class SettingsState {
  const SettingsState({
    this.busy = false,
    this.result,
    this.error,
    this.notice,
  });

  /// True while an import or a deletion runs.
  final bool busy;

  /// The counts of the last import.
  final ImportResultDTO? result;

  /// The message of the last failure.
  final String? error;

  /// A message about the last deletion.
  final String? notice;
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);

/// Operations of the settings screen (OP-1 and OP-2 of SCR-001).
class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  /// OP-1: picks a CSV and imports it.
  Future<void> importCsv() async {
    if (state.busy) return;
    final bytes = await ref.read(csvPickerProvider)();
    if (bytes == null) return;

    state = const SettingsState(busy: true);
    try {
      final result = await ref.read(importStatementUCProvider).execute(bytes);
      state = SettingsState(result: result);
    } on FormatException catch (e) {
      state = SettingsState(error: SettingsStrings.importFailed(e.message));
    } catch (_) {
      // The details are not shown: they could contain personal data.
      state = const SettingsState(error: SettingsStrings.importUnexpected);
    } finally {
      // Even a failed import can leave some statement lines stored (ER-2).
      ref.read(dataRevisionProvider.notifier).changed();
    }
  }

  /// OP-2: deletes every stored statement line.
  Future<void> deleteAll() async {
    if (state.busy) return;
    state = const SettingsState(busy: true);
    try {
      await ref.read(deleteAllStatementLinesUCProvider).execute();
      state = const SettingsState(notice: SettingsStrings.deleted);
    } catch (_) {
      state = const SettingsState(error: SettingsStrings.deleteFailed);
    } finally {
      ref.read(dataRevisionProvider.notifier).changed();
    }
  }
}
