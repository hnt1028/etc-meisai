import 'package:etc_meisai/application/dto/import_result_dto.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/settings/settings_providers.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The part of the screen a message belongs to: it is shown under its buttons,
/// so that the user sees it where they pressed.
enum SettingsSection { none, importCsv, backup, delete }

/// What the settings screen shows. Only one of [result], [error] and [notice]
/// is set at a time, and [section] says where it is shown.
class SettingsState {
  const SettingsState({
    this.busy = false,
    this.result,
    this.error,
    this.notice,
    this.section = SettingsSection.none,
  });

  /// The part of the screen the message is shown in.
  final SettingsSection section;

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
      state = SettingsState(section: SettingsSection.importCsv, result: result);
    } on FormatException catch (e) {
      state = SettingsState(
        section: SettingsSection.importCsv,
        error: SettingsStrings.importFailed(e.message),
      );
    } catch (_) {
      // The details are not shown: they could contain personal data.
      state = const SettingsState(
        section: SettingsSection.importCsv,
        error: SettingsStrings.importUnexpected,
      );
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
      state = const SettingsState(
        section: SettingsSection.delete,
        notice: SettingsStrings.deleted,
      );
    } catch (_) {
      state = const SettingsState(
        section: SettingsSection.delete,
        error: SettingsStrings.deleteFailed,
      );
    } finally {
      ref.read(dataRevisionProvider.notifier).changed();
    }
  }

  /// OP-4: makes the backup and lets the user save it. Nothing is shown when
  /// the user chose no place.
  Future<void> exportData() async {
    if (state.busy) return;
    state = const SettingsState(busy: true);
    try {
      final data = await ref.read(exportDataUCProvider).execute();
      final saved = await ref.read(backupSaverProvider)(
        data.fileName,
        data.bytes,
      );
      state = saved
          ? SettingsState(
              section: SettingsSection.backup,
              notice: SettingsStrings.exported(
                data.summary.lineCount,
                data.summary.mappingCount,
                data.summary.positionCount,
              ),
            )
          : const SettingsState();
    } catch (_) {
      // The details are not shown: they could contain personal data.
      state = const SettingsState(
        section: SettingsSection.backup,
        error: SettingsStrings.exportFailed,
      );
    }
  }

  /// OP-5: picks a backup file and replaces all the data with it. The screen
  /// has asked the user to confirm already.
  Future<void> restoreData() async {
    if (state.busy) return;
    final bytes = await ref.read(backupPickerProvider)();
    if (bytes == null) return;

    state = const SettingsState(busy: true);
    try {
      final summary = await ref.read(importDataUCProvider).execute(bytes);
      state = SettingsState(
        section: SettingsSection.backup,
        notice: SettingsStrings.restored(
          summary.lineCount,
          summary.mappingCount,
          summary.positionCount,
        ),
      );
    } on FormatException catch (e) {
      state = SettingsState(
        section: SettingsSection.backup,
        error: SettingsStrings.restoreFailed(e.message),
      );
    } catch (_) {
      state = const SettingsState(
        section: SettingsSection.backup,
        error: SettingsStrings.restoreUnexpected,
      );
    } finally {
      ref.read(dataRevisionProvider.notifier).changed();
    }
  }

  /// OP-6: deletes everything that is stored.
  Future<void> deleteAllData() async {
    if (state.busy) return;
    state = const SettingsState(busy: true);
    try {
      await ref.read(deleteAllDataUCProvider).execute();
      state = const SettingsState(
        section: SettingsSection.delete,
        notice: SettingsStrings.deletedAll,
      );
    } catch (_) {
      state = const SettingsState(
        section: SettingsSection.delete,
        error: SettingsStrings.deleteAllFailed,
      );
    } finally {
      ref.read(dataRevisionProvider.notifier).changed();
    }
  }
}
