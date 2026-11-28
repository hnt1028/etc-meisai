import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
import 'package:etc_meisai/domain/value/route_map_option_value.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_layer_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OP-10 of SCR-005: the sheet with a check box for each layer of the map.
/// A change is applied at once and stored.
Future<void> showRouteMapLayerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _LayerSheet(),
  );
}

class _LayerSheet extends ConsumerStatefulWidget {
  const _LayerSheet();

  @override
  ConsumerState<_LayerSheet> createState() => _LayerSheetState();
}

class _LayerSheetState extends ConsumerState<_LayerSheet> {
  /// The width while the slider is dragged: it is stored when the finger lifts.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final shown = shownLayers(ref.watch(routeMapLayersProvider).value);
    final width = lineWidthOf(ref.watch(routeMapOptionsProvider).value);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                RouteMapStrings.layerSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final layer in RouteMapLayerValue.values)
              CheckboxListTile(
                key: ValueKey('layer-${layer.code}'),
                value: shown.contains(layer),
                title: Text(RouteMapStrings.layerTitle(layer)),
                subtitle: Text(RouteMapStrings.layerNote(layer)),
                onChanged: (value) =>
                    _save(context, ref, layer, value ?? false),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(RouteMapStrings.lineWidthLabel),
                  const Spacer(),
                  Text(
                    '${(_dragging ?? width).round()}',
                    key: const ValueKey('line-width-value'),
                  ),
                ],
              ),
            ),
            Slider(
              key: const ValueKey('line-width-slider'),
              value: (_dragging ?? width).toDouble(),
              min: RouteMapOptionValue.lineWidth.minimum.toDouble(),
              max: RouteMapOptionValue.lineWidth.maximum.toDouble(),
              divisions:
                  RouteMapOptionValue.lineWidth.maximum -
                  RouteMapOptionValue.lineWidth.minimum,
              label: '${(_dragging ?? width).round()}',
              onChanged: (value) => setState(() => _dragging = value),
              onChangeEnd: (value) => _saveWidth(context, value.round()),
            ),
          ],
        ),
      ),
    );
  }

  /// Stores the width of the lines and reads the numbers again. A failure is
  /// shown as a message, without details.
  Future<void> _saveWidth(BuildContext context, int value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(saveRouteMapOptionUCProvider)
          .execute(option: RouteMapOptionValue.lineWidth, value: value);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(RouteMapStrings.layerSaveFailed)),
      );
    }
    ref.invalidate(routeMapOptionsProvider);
    // The map reads the new width: the slider shows what is stored again.
    if (mounted) setState(() => _dragging = null);
  }

  /// Stores the choice and reads the layers again. A failure is shown as a
  /// message, without details.
  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    RouteMapLayerValue layer,
    bool visible,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(saveRouteMapLayerUCProvider)
          .execute(layer: layer, visible: visible);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(RouteMapStrings.layerSaveFailed)),
      );
    }
    ref.invalidate(routeMapLayersProvider);
  }
}
