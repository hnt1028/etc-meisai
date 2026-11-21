import 'dart:math' as math;

import 'package:etc_meisai/application/dto/route_map_dto.dart';
import 'package:etc_meisai/application/dto/route_network_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_display.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_layer_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_layer_sheet.dart';
import 'package:etc_meisai/userinterface/route_map/operator_color_providers.dart';
import 'package:etc_meisai/userinterface/route_map/operator_colors.dart';
import 'package:etc_meisai/userinterface/common/message_text.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_controller.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_sheets.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_filter_bar.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// SCR-005: draws the routes of the statement lines on a map.
class RouteMapScreen extends ConsumerWidget {
  const RouteMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(routeMapProvider);
    final filter = ref.watch(statementFilterProvider);
    final picking = ref.watch(icPickingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(RouteMapStrings.title)),
      body: map.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MessageText(RouteMapStrings.loadFailed, isError: true),
              TextButton(
                onPressed: () => ref.invalidate(routeMapProvider),
                child: const Text(RouteMapStrings.retry),
              ),
            ],
          ),
        ),
        data: (data) => LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              if (map.isLoading) const LinearProgressIndicator(),
              // On a short screen, the controls take at most half of the
              // height and scroll, so that the map keeps some room.
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: box.maxHeight * 0.5),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ExpansionTile(
                        title: const Text(RouteMapStrings.filterTitle),
                        shape: const Border(),
                        collapsedShape: const Border(),
                        children: [
                          StatementFilterBar(
                            filter: filter,
                            vehicleNumberChoices: data.vehicleNumberChoices,
                            cardNumberChoices: data.cardNumberChoices,
                          ),
                        ],
                      ),
                      if (picking.icName != null)
                        _PickingPanel(picking: picking)
                      else if (data.unlocated.isNotEmpty)
                        _UnlocatedBanner(data: data),
                    ],
                  ),
                ),
              ),
              // A line between the controls and the map.
              const Divider(height: 1),
              Expanded(
                child: Stack(
                  children: [
                    _RouteMap(data: data, picking: picking),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        key: const ValueKey('layer-button'),
                        heroTag: null,
                        tooltip: RouteMapStrings.layerButton,
                        onPressed: () => showRouteMapLayerSheet(context),
                        child: const Icon(Icons.layers),
                      ),
                    ),
                    if (data.lineCount == 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 64,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              filter.isActive
                                  ? StatementListStrings.emptyNoMatch
                                  : StatementListStrings.emptyNoData,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlocatedBanner extends ConsumerWidget {
  const _UnlocatedBanner({required this.data});

  final RouteMapDTO data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                RouteMapStrings.unlocatedBanner(
                  data.unlocated.length,
                  data.undrawnLineCount,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => showUnlocatedSheet(context, ref, data.unlocated),
              child: const Text(RouteMapStrings.specifyPosition),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickingPanel extends ConsumerWidget {
  const _PickingPanel({required this.picking});

  final IcPickingState picking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icName = picking.icName!;
    final pin = picking.pin;
    return Card.filled(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(RouteMapStrings.picking(icName)),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: pin == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(routeMapActionsProvider)
                                .savePosition(icName, pin);
                            ref.read(icPickingProvider.notifier).cancel();
                          } catch (_) {
                            // The details are not shown: they could contain
                            // personal data.
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(RouteMapStrings.saveFailed),
                              ),
                            );
                          }
                        },
                  child: const Text(RouteMapStrings.register),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: ref.read(icPickingProvider.notifier).cancel,
                  child: const Text(RouteMapStrings.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The map itself. It is made again (and so fits all the markers again) when
/// the markers change, but not when only the pin moves.
class _RouteMap extends ConsumerStatefulWidget {
  const _RouteMap({required this.data, required this.picking});

  final RouteMapDTO data;
  final IcPickingState picking;

  @override
  ConsumerState<_RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends ConsumerState<_RouteMap> {
  final LayerHitNotifier<RouteSegmentDTO> _hit = ValueNotifier(null);

  /// Japan as a whole, for a map without any marker.
  static final _japan = LatLng(36.2, 138.25);

  void _onTap(TapPosition tapPosition, LatLng point) {
    if (widget.picking.icName != null) {
      ref.read(icPickingProvider.notifier).setPin(point);
      return;
    }
    final hits = _hit.value?.hitValues;
    if (hits == null || hits.isEmpty) return;
    if (hits.length == 1) {
      context.push('/route-map/detail', extra: hits.single.line);
    } else {
      showSegmentSheet(context, hits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final scheme = Theme.of(context).colorScheme;
    final operatorColors = ref.watch(operatorColorsProvider).value;
    final shown = shownLayers(ref.watch(routeMapLayersProvider).value);
    final network =
        shown.contains(RouteMapLayerValue.network) ||
            shown.contains(RouteMapLayerValue.networkNames)
        ? ref.watch(routeNetworkProvider).value
        : null;
    final segments = [
      for (final s in data.segments)
        if (shown.contains(RouteMapLayerValue.pending) ||
            s.line.status != ConfirmationStatusValue.pending)
          s,
    ];
    final counts = shown.contains(RouteMapLayerValue.scaleByCount)
        ? segmentCounts(segments)
        : null;
    final points = [
      for (final p in data.places) LatLng(p.latitude, p.longitude),
    ];
    final pin = widget.picking.pin;
    // The camera fits the lines too, not only the markers.
    final extent = [
      ...points,
      for (final segment in data.segments)
        for (final run in segmentRuns(segment))
          for (final v in run.points) LatLng(v.latitude, v.longitude),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => FlutterMap(
        key: ValueKey(
          data.places
              .map((p) => '${p.icName}@${p.latitude},${p.longitude}')
              .join('|'),
        ),
        options: MapOptions(
          initialCenter: _japan,
          initialZoom: 5,
          initialCameraFit: extent.isEmpty
              ? null
              : CameraFit.coordinates(
                  coordinates: extent,
                  padding: EdgeInsets.all(
                    math.min(48, constraints.biggest.shortestSide / 4),
                  ),
                  maxZoom: 14,
                ),
          onTap: _onTap,
        ),
        children: [
          ref.watch(tileLayerProvider),
          if (network != null && shown.contains(RouteMapLayerValue.network))
            PolylineLayer(
              polylines: [
                for (final line in network.lines)
                  Polyline(
                    points: [
                      for (final v in line.points)
                        LatLng(v.latitude, v.longitude),
                    ],
                    strokeWidth: 2,
                    color: Colors.grey.withValues(alpha: 0.45),
                  ),
              ],
            ),
          if (network != null &&
              shown.contains(RouteMapLayerValue.networkNames))
            _NetworkNames(network: network),
          if (shown.contains(RouteMapLayerValue.traveled))
            PolylineLayer<RouteSegmentDTO>(
              hitNotifier: _hit,
              polylines: [
                for (final segment in segments)
                  for (final run in segmentRuns(segment))
                    Polyline<RouteSegmentDTO>(
                      points: [
                        for (final v in run.points)
                          LatLng(v.latitude, v.longitude),
                      ],
                      strokeWidth: counts == null
                          ? segmentBaseWidth
                          : segmentWidth(counts[segmentRoadKey(segment)] ?? 1),
                      color: runColor(context, run, scheme, operatorColors),
                      pattern:
                          segment.line.status == ConfirmationStatusValue.pending
                          ? StrokePattern.dashed(segments: const [10, 8])
                          : const StrokePattern.solid(),
                      hitValue: segment,
                    ),
              ],
            ),
          if (shown.contains(RouteMapLayerValue.markers))
            MarkerLayer(
              markers: [
                for (final place in data.places)
                  Marker(
                    point: LatLng(place.latitude, place.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      key: ValueKey('marker-${place.icName}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.picking.icName != null
                          ? null
                          : () => showPlaceSheet(context, ref, place),
                      child: Stack(
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
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    backgroundColor: scheme.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          if (pin != null)
            MarkerLayer(
              markers: [
                Marker(
                  key: const ValueKey('pin'),
                  point: pin,
                  width: 40,
                  height: 40,
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Icon(
                      Icons.location_on,
                      size: 36,
                      color: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution(RouteMapStrings.attribution)],
          ),
        ],
      ),
    );
  }
}

/// The names of the roads of the network, written at one place of each road.
/// Only the ones in view are made, and only when the map is zoomed in.
class _NetworkNames extends StatelessWidget {
  const _NetworkNames({required this.network});

  final RouteNetworkDTO network;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (camera.zoom < networkNamesMinZoom) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.labelSmall;
    final surface = Theme.of(context).colorScheme.surface;
    final bounds = camera.visibleBounds;
    return MarkerLayer(
      markers: [
        for (final label in network.labels)
          if (bounds.contains(LatLng(label.latitude, label.longitude)))
            Marker(
              point: LatLng(label.latitude, label.longitude),
              width: 160,
              height: 20,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    label.routeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                      backgroundColor: surface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
