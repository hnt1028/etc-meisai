import 'package:etc_meisai/application/dto/ic_match_dto.dart';
import 'package:etc_meisai/application/dto/ic_match_list_dto.dart';
import 'package:etc_meisai/domain/value/ic_match_value.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/common/section_title.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_controller.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_strings.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_point_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// SCR-004: ties the IC names of the CSV to the points of the IC master.
class IcMappingScreen extends ConsumerWidget {
  const IcMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(icMatchListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(IcMappingStrings.title)),
      body: list.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MessageText(IcMappingStrings.loadFailed, isError: true),
              TextButton(
                onPressed: () => ref.invalidate(icMatchListProvider),
                child: const Text(IcMappingStrings.retry),
              ),
            ],
          ),
        ),
        data: (data) => _Content(data: data, reloading: list.isLoading),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.data, required this.reloading});

  final IcMatchListDTO data;
  final bool reloading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (reloading) const LinearProgressIndicator(),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SectionTitle(IcMappingStrings.unresolvedSection),
        ),
        if (data.unresolved.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(IcMappingStrings.noUnresolved),
          ),
        for (final match in data.unresolved)
          ListTile(
            title: Text(match.icName),
            subtitle: Text(
              match.state == IcMatchValue.ambiguous
                  ? IcMappingStrings.ambiguous(match.lineCount)
                  : IcMappingStrings.unknown(match.lineCount),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showIcPointPicker(context, match),
          ),
        const Divider(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionTitle(IcMappingStrings.registeredSection),
        ),
        if (data.registered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(IcMappingStrings.noRegistered),
          ),
        for (final match in data.registered) _RegisteredTile(match: match),
      ],
    );
  }
}

class _RegisteredTile extends ConsumerWidget {
  const _RegisteredTile({required this.match});

  final IcMatchDTO match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = match.point;
    return ListTile(
      title: Text(
        point == null
            ? match.icName
            : IcMappingStrings.registeredLine(match.icName, point.name),
      ),
      subtitle: Text(
        point == null
            ? IcMappingStrings.pointMissing
            : point.routeNames.join('・'),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: IcMappingStrings.unlink,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(icMappingActionsProvider).delete(match.icName);
          } catch (_) {
            // The details are not shown: they could contain personal data.
            messenger.showSnackBar(
              const SnackBar(content: Text(IcMappingStrings.deleteFailed)),
            );
          }
        },
      ),
    );
  }
}
