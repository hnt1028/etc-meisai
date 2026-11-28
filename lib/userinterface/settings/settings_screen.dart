import 'package:etc_meisai/userinterface/common/confirm_dialog.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/settings/operator_color_section.dart';
import 'package:etc_meisai/userinterface/settings/settings_controller.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/settings/tile_cache_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// SCR-001: imports a usage statement CSV and deletes the imported data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final result = state.result;

    return Scaffold(
      appBar: AppBar(title: const Text(SettingsStrings.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.busy) const LinearProgressIndicator(),
          const SectionTitle(SettingsStrings.importSection),
          FilledButton(
            onPressed: state.busy ? null : controller.importCsv,
            child: const Text(SettingsStrings.importButton),
          ),
          if (result != null && state.section == SettingsSection.importCsv)
            MessageText(
              SettingsStrings.importResult(
                result.addedCount,
                result.overwrittenCount,
                result.ignoredCount,
              ),
            ),
          if (_shows(state, SettingsSection.importCsv) && state.error != null)
            MessageText(state.error!, isError: true),
          const Divider(height: 32),
          const OperatorColorSection(),
          const Divider(height: 32),
          const TileCacheSection(),
          const Divider(height: 32),
          const SectionTitle(SettingsStrings.backupSection),
          OutlinedButton(
            onPressed: state.busy ? null : controller.exportData,
            child: const Text(SettingsStrings.exportButton),
          ),
          const SizedBox(height: 4),
          Text(
            SettingsStrings.exportNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      message: SettingsStrings.restoreConfirmMessage,
                      cancelLabel: SettingsStrings.deleteConfirmCancel,
                      okLabel: SettingsStrings.restoreConfirmOk,
                    );
                    if (ok) await controller.restoreData();
                  },
            child: const Text(SettingsStrings.restoreButton),
          ),
          // The result is under the buttons that were pressed.
          if (_shows(state, SettingsSection.backup)) ..._messages(state),
          const Divider(height: 32),
          const SectionTitle(SettingsStrings.deleteSection),
          OutlinedButton(
            onPressed: state.busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      message: SettingsStrings.deleteConfirmMessage,
                      cancelLabel: SettingsStrings.deleteConfirmCancel,
                      okLabel: SettingsStrings.deleteConfirmOk,
                    );
                    if (ok) await controller.deleteAll();
                  },
            child: const Text(SettingsStrings.deleteButton),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.busy
                ? null
                : () async {
                    final ok = await showConfirmDialog(
                      context,
                      message: SettingsStrings.deleteAllConfirmMessage,
                      cancelLabel: SettingsStrings.deleteConfirmCancel,
                      okLabel: SettingsStrings.deleteConfirmOk,
                    );
                    if (ok) await controller.deleteAllData();
                  },
            child: const Text(SettingsStrings.deleteAllButton),
          ),
          if (_shows(state, SettingsSection.delete)) ..._messages(state),
          const Divider(height: 32),
          const SectionTitle(SettingsStrings.icMappingSection),
          OutlinedButton(
            onPressed: () => context.push('/settings/ic-mapping'),
            child: const Text(SettingsStrings.icMappingButton),
          ),
          const SizedBox(height: 24),
          Text(
            SettingsStrings.credit,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// True when the message of [state] belongs to [section].
  static bool _shows(SettingsState state, SettingsSection section) =>
      state.section == section;

  /// The notice or the error of [state], under the buttons it belongs to.
  static List<Widget> _messages(SettingsState state) => [
    if (state.notice != null) MessageText(state.notice!),
    if (state.error != null) MessageText(state.error!, isError: true),
  ];
}
