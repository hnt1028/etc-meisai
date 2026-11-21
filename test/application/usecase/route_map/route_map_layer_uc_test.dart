import 'package:etc_meisai/application/usecase/route_map/list_route_map_layers_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_layer_uc.dart';
import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('RouteMapLayerValue', () {
    test('finds a layer by its code', () {
      for (final layer in RouteMapLayerValue.values) {
        expect(RouteMapLayerValue.fromCode(layer.code), layer);
      }
      expect(RouteMapLayerValue.fromCode('nothing'), isNull);
    });

    test('shows the network, the driven roads and the markers at first', () {
      expect(RouteMapLayerValue.values.where((l) => l.defaultVisible), [
        RouteMapLayerValue.network,
        RouteMapLayerValue.traveled,
        RouteMapLayerValue.markers,
        RouteMapLayerValue.pending,
      ]);
    });
  });

  group('ListRouteMapLayersUC', () {
    test('gives the defaults when the user has not chosen', () async {
      final layers = await ListRouteMapLayersUC(
        routeMapLayers: FakeRouteMapLayerIF(),
      ).execute();

      expect(layers.map((l) => l.layer), RouteMapLayerValue.values);
      expect(
        layers.map((l) => l.visible),
        RouteMapLayerValue.values.map((l) => l.defaultVisible),
      );
    });

    test('uses what the user chose, and the default for the rest', () async {
      final store = FakeRouteMapLayerIF()
        ..stored.addAll(const [
          RouteMapLayerEntity(layerCode: 'network', visible: false),
          RouteMapLayerEntity(layerCode: 'scaleByCount', visible: true),
          // A layer this version does not know is left out.
          RouteMapLayerEntity(layerCode: 'future', visible: true),
        ]);

      final layers = await ListRouteMapLayersUC(
        routeMapLayers: store,
      ).execute();

      final byLayer = {for (final l in layers) l.layer: l.visible};
      expect(byLayer[RouteMapLayerValue.network], isFalse);
      expect(byLayer[RouteMapLayerValue.scaleByCount], isTrue);
      expect(byLayer[RouteMapLayerValue.traveled], isTrue);
      expect(byLayer[RouteMapLayerValue.networkNames], isFalse);
      expect(layers, hasLength(RouteMapLayerValue.values.length));
    });

    test('passes on a failure to read', () async {
      final store = FakeRouteMapLayerIF()..error = StateError('x');

      expect(
        ListRouteMapLayersUC(routeMapLayers: store).execute(),
        throwsStateError,
      );
    });
  });

  group('SaveRouteMapLayerUC', () {
    test('stores the choice, and replaces the one of the same layer', () async {
      final store = FakeRouteMapLayerIF();
      final uc = SaveRouteMapLayerUC(routeMapLayers: store);

      await uc.execute(layer: RouteMapLayerValue.markers, visible: false);
      await uc.execute(layer: RouteMapLayerValue.markers, visible: true);

      expect(store.stored, hasLength(1));
      expect(store.stored.single.layerCode, 'markers');
      expect(store.stored.single.visible, isTrue);
    });

    test('passes on a failure to store', () async {
      final store = FakeRouteMapLayerIF()..error = StateError('x');

      expect(
        SaveRouteMapLayerUC(
          routeMapLayers: store,
        ).execute(layer: RouteMapLayerValue.network, visible: true),
        throwsStateError,
      );
    });
  });
}
