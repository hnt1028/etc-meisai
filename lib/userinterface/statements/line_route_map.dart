import 'package:etc_meisai/application/dto/line_route_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// SCR-003: the route of one statement line on a map. It cannot be tapped:
/// positions are chosen on the route map (SCR-005).
class LineRouteMap extends ConsumerWidget {
  const LineRouteMap({super.key, required this.line});

  final StatementLineDTO line;

  static const _height = 240.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(lineRouteProvider(line));
    return route.when(
      loading: () => const SizedBox(
        height: _height,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.all(16),
        child: MessageText(
          StatementDetailStrings.routeLoadFailed,
          isError: true,
        ),
      ),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.unlocatedIcNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                StatementDetailStrings.unlocatedNotice(data.unlocatedIcNames),
              ),
            ),
          if (data.places.isNotEmpty)
            SizedBox(
              height: _height,
              child: _Map(route: data, pending: _isPending),
            ),
        ],
      ),
    );
  }

  bool get _isPending => line.status == ConfirmationStatusValue.pending;
}

class _Map extends ConsumerWidget {
  const _Map({required this.route, required this.pending});

  final LineRouteDTO route;
  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final segment = route.segment;
    final points = [
      for (final p in route.places) LatLng(p.latitude, p.longitude),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: 12,
        // A single marker has no extent to fit, so the zoom is capped.
        initialCameraFit: CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
          maxZoom: 14,
        ),
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        ref.watch(tileLayerProvider),
        if (segment != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(segment.fromLatitude, segment.fromLongitude),
                  LatLng(segment.toLatitude, segment.toLongitude),
                ],
                strokeWidth: 4,
                color: scheme.primary.withValues(alpha: 0.7),
                pattern: pending
                    ? StrokePattern.dashed(segments: const [10, 8])
                    : const StrokePattern.solid(),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final place in route.places)
              Marker(
                point: LatLng(place.latitude, place.longitude),
                width: 40,
                height: 40,
                child: Stack(
                  key: ValueKey('line-place-${place.icName}'),
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.circle, size: 14, color: scheme.primary),
                    Positioned(
                      top: 36,
                      left: -50,
                      width: 140,
                      child: Text(
                        RouteMapStrings.markerLabel(
                          place.icName,
                          approximate: place.approximate,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          backgroundColor: scheme.surface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution(RouteMapStrings.attribution)],
        ),
      ],
    );
  }
}
