import 'package:etc_meisai/application/dto/ic_point_dto.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_controller.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-12 of SCR-005: asks for an IC by its name, among every IC of the master.
/// Returns the IC the user chose, or null when the sheet was closed.
Future<IcPointDTO?> showIcSearchSheet(BuildContext context) {
  return showModalBottomSheet<IcPointDTO>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SearchSheet(),
  );
}

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet();

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = _query.trim().isEmpty
        ? null
        : ref.watch(icPointSearchProvider(_query));
    return Padding(
      // The sheet rises over the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  RouteMapStrings.searchTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const ValueKey('map-search-field'),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: RouteMapStrings.searchLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: results == null
                    ? const SizedBox.shrink()
                    : results.when(
                        skipLoadingOnReload: true,
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(RouteMapStrings.searchFailed),
                        ),
                        data: (points) => points.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(RouteMapStrings.searchNone),
                              )
                            : ListView(
                                children: [
                                  for (final p in points)
                                    ListTile(
                                      key: ValueKey(
                                        'map-search-result-${p.id}',
                                      ),
                                      title: Text(p.name),
                                      subtitle: p.routeNames.isEmpty
                                          ? null
                                          : Text(p.routeNames.join('・')),
                                      onTap: () => Navigator.of(context).pop(p),
                                    ),
                                ],
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
