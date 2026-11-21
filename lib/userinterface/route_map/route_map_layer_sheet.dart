import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
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

class _LayerSheet extends ConsumerWidget {
  const _LayerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = shownLayers(ref.watch(routeMapLayersProvider).value);
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
          ],
        ),
      ),
    );
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
