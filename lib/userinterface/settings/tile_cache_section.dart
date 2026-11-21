import 'package:etc_meisai/userinterface/common/confirm_dialog.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/settings/settings_strings.dart';
import 'package:etc_meisai/userinterface/settings/tile_cache_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-10 and OP-11 of SCR-001: the size of the map tiles kept on the device,
/// and a button that deletes them.
class TileCacheSection extends ConsumerWidget {
  const TileCacheSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(tileCacheSizeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(SettingsStrings.tileCacheSection),
        Text(
          SettingsStrings.tileCacheNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        size.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const MessageText(
            SettingsStrings.tileCacheLoadFailed,
            isError: true,
          ),
          data: (bytes) => Text(
            SettingsStrings.tileCacheSize(formatDataSize(bytes)),
            key: const ValueKey('tile-cache-size'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('tile-cache-clear'),
          // Nothing to delete while the size is 0, not read, or unreadable.
          onPressed: (size.value ?? 0) == 0 ? null : () => _clear(context, ref),
          child: const Text(SettingsStrings.tileCacheClear),
        ),
      ],
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      message: SettingsStrings.tileCacheClearConfirm,
      cancelLabel: SettingsStrings.deleteConfirmCancel,
      okLabel: SettingsStrings.tileCacheClearOk,
    );
    if (!ok || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(clearTileCacheUCProvider).execute();
      messenger.showSnackBar(
        const SnackBar(content: Text(SettingsStrings.tileCacheCleared)),
      );
    } catch (_) {
      // The details are not shown.
      messenger.showSnackBar(
        const SnackBar(content: Text(SettingsStrings.tileCacheClearFailed)),
      );
    }
    ref.invalidate(tileCacheSizeProvider);
  }
}
