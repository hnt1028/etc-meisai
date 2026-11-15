import 'package:etc_meisai/application/dto/route_place_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/unlocated_ic_dto.dart';
import 'package:etc_meisai/domain/value/ic_place_source_value.dart';
import 'package:etc_meisai/userinterface/common/format.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_controller.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// OP-3: the IC names without a position. Choosing one starts OP-4.
Future<void> showUnlocatedSheet(
  BuildContext context,
  WidgetRef ref,
  List<UnlocatedIcDTO> unlocated,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              RouteMapStrings.unlocatedSheetTitle,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final ic in unlocated)
            ListTile(
              title: Text(ic.icName),
              subtitle: Text(RouteMapStrings.lineCount(ic.lineCount)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(icPickingProvider.notifier).start(ic.icName);
              },
            ),
        ],
      ),
    ),
  );
}

/// OP-7: what is known about a marker, and the way to choose its position.
Future<void> showPlaceSheet(
  BuildContext context,
  WidgetRef ref,
  RoutePlaceDTO place,
) {
  final specified = place.source == IcPlaceSourceValue.specified;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.icName,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${RouteMapStrings.routeNamesLabel}: '
              '${place.routeNames.isEmpty ? RouteMapStrings.noRouteNames : place.routeNames.join('・')}',
            ),
            Text(
              '${RouteMapStrings.positionLabel}: '
              '${specified ? RouteMapStrings.positionSpecified : RouteMapStrings.positionMaster}'
              '${place.approximate ? RouteMapStrings.approximate : ''}',
            ),
            Text(RouteMapStrings.lineCount(place.lineCount)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(icPickingProvider.notifier).start(place.icName);
                  },
                  child: const Text(RouteMapStrings.respecify),
                ),
                if (specified)
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.of(sheetContext).pop();
                      try {
                        await ref
                            .read(routeMapActionsProvider)
                            .deletePosition(place.icName);
                      } catch (_) {
                        // The details are not shown: they could contain
                        // personal data.
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(RouteMapStrings.deleteFailed),
                          ),
                        );
                      }
                    },
                    child: const Text(RouteMapStrings.unspecify),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// OP-8: the lines that overlap where the user tapped.
Future<void> showSegmentSheet(
  BuildContext context,
  List<RouteSegmentDTO> segments,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              RouteMapStrings.segmentSheetTitle,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          for (final segment in segments)
            ListTile(
              title: Text(
                StatementListStrings.route(
                  segment.line.entranceIc,
                  segment.line.exitIc,
                ),
              ),
              subtitle: Text(
                StatementListStrings.times(
                  segment.line.entranceAt,
                  segment.line.exitAt,
                ),
              ),
              trailing: Text(formatYen(segment.line.fare)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push('/route-map/detail', extra: segment.line);
              },
            ),
        ],
      ),
    ),
  );
}
