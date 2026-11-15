import 'package:etc_meisai/userinterface/common/confirm_dialog.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/settings/settings_controller.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          if (result != null)
            MessageText(
              SettingsStrings.importResult(
                result.addedCount,
                result.overwrittenCount,
                result.ignoredCount,
              ),
            ),
          if (state.error != null) MessageText(state.error!, isError: true),
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
          if (state.notice != null) MessageText(state.notice!),
        ],
      ),
    );
  }
}
