import 'package:etc_meisai/application/dto/ic_match_dto.dart';
import 'package:etc_meisai/application/dto/ic_point_dto.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_controller.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the sheet where the user chooses the IC point of [match] (OP-2).
Future<void> showIcPointPicker(BuildContext context, IcMatchDTO match) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => IcPointPicker(match: match),
  );
}

/// The sheet of SCR-004. With no typed text, it lists the candidates of the
/// IC name; with a typed text, the IC points that have it in their name.
class IcPointPicker extends ConsumerStatefulWidget {
  const IcPointPicker({super.key, required this.match});

  final IcMatchDTO match;

  @override
  ConsumerState<IcPointPicker> createState() => _IcPointPickerState();
}

class _IcPointPickerState extends ConsumerState<IcPointPicker> {
  String _query = '';

  Future<void> _choose(IcPointDTO point) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(icMappingActionsProvider)
          .save(widget.match.icName, point.id);
      navigator.pop();
    } catch (_) {
      // The details are not shown: they could contain personal data.
      messenger.showSnackBar(
        const SnackBar(content: Text(IcMappingStrings.saveFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typed = _query.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                IcMappingStrings.pickerTitle(widget.match.icName),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: IcMappingStrings.searchHint,
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: typed
                  ? ref
                        .watch(icPointSearchProvider(_query))
                        .when(
                          skipLoadingOnReload: true,
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => const MessageText(
                            IcMappingStrings.searchFailed,
                            isError: true,
                          ),
                          data: _points,
                        )
                  : _points(widget.match.candidates),
            ),
          ],
        ),
      ),
    );
  }

  Widget _points(List<IcPointDTO> points) {
    if (points.isEmpty) {
      return const Center(child: Text(IcMappingStrings.noResult));
    }
    return ListView.separated(
      itemCount: points.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final point = points[index];
        return ListTile(
          title: Text(point.name),
          subtitle: Text(
            IcMappingStrings.pointDetail(
              kind: point.kind,
              routeNames: point.routeNames,
              latitude: point.latitude,
              longitude: point.longitude,
            ),
          ),
          onTap: () => _choose(point),
        );
      },
    );
  }
}
