import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_map_layers_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/list_route_network_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_route_map_layer_uc.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/route_map_layer_value.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_display.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_layer_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

/// The route map with a road R1 between 北 and 東, and what the user chose to
/// show kept in memory.
class _World {
  final lines = FakeStatementLineIF();
  final positions = FakeIcPositionIF();
  final layers = FakeRouteMapLayerIF();

  /// When set, the use case that makes the network throws it.
  Object? networkError;

  FakeIcMasterIF get master => FakeIcMasterIF(
    [
      fakeIcPoint(
        name: '北',
        routeNames: const ['R1'],
        latitude: 35.1,
        longitude: 139.1,
      ),
      fakeIcPoint(
        name: '東',
        routeNames: const ['R1'],
        latitude: 35.2,
        longitude: 139.3,
      ),
    ],
    links: const [IcLinkEntity(fromId: 'id-北', toId: 'id-東', meters: 20000)],
  );

  void line(
    String from,
    String to, {
    int day = 10,
    ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
  }) {
    lines.stored.add(
      fakeStatementLine(
        entranceIc: from,
        exitIc: to,
        entranceAt: DateTime(2026, 1, day, 8),
        exitAt: DateTime(2026, 1, day, 9),
        status: status,
      ),
    );
  }

  Widget app() => ProviderScope(
    overrides: [
      listStatementLinesUCProvider.overrideWithValue(
        fakeListUC(lines, positions: positions),
      ),
      listRouteMapUCProvider.overrideWithValue(
        fakeRouteMapUC(lines, master: master, positions: positions),
      ),
      listRouteMapLayersUCProvider.overrideWithValue(
        ListRouteMapLayersUC(routeMapLayers: layers),
      ),
      saveRouteMapLayerUCProvider.overrideWithValue(
        SaveRouteMapLayerUC(routeMapLayers: layers),
      ),
      listRouteNetworkUCProvider.overrideWithValue(
        networkError == null
            ? ListRouteNetworkUC(icMaster: master)
            : ListRouteNetworkUC(icMaster: _Broken(networkError!)),
      ),
      tileLayerProvider.overrideWithValue(const SizedBox.shrink()),
    ],
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );

  void choose(RouteMapLayerValue layer, bool visible) => layers.stored.add(
    RouteMapLayerEntity(layerCode: layer.code, visible: visible),
  );
}

class _Broken extends FakeIcMasterIF {
  _Broken(this.failure) : super(const []);

  final Object failure;

  @override
  Future<List<IcLinkEntity>> findLinks() async => throw failure;
}

Future<void> _open(WidgetTester tester, _World world) async {
  await tester.pumpWidget(world.app());
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.routeMapTab));
  await tester.pumpAndSettle();
}

Finder get _network => find.byType(PolylineLayer<Object>);
Finder get _traveled => find.byType(PolylineLayer<RouteSegmentDTO>);

List<Polyline<RouteSegmentDTO>> _lines(WidgetTester tester) =>
    tester.widget<PolylineLayer<RouteSegmentDTO>>(_traveled).polylines;

Finder _checkbox(RouteMapLayerValue layer) =>
    find.byKey(ValueKey('layer-${layer.code}'));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('layer-button')));
  await tester.pumpAndSettle();
}

bool _checked(WidgetTester tester, RouteMapLayerValue layer) =>
    tester.widget<CheckboxListTile>(_checkbox(layer)).value!;

void main() {
  testWidgets('shows the network, the driven roads and the markers at first', (
    tester,
  ) async {
    final world = _World()..line('北', '東');

    await _open(tester, world);

    expect(_network, findsOneWidget);
    expect(
      tester.widget<PolylineLayer<Object>>(_network).polylines,
      hasLength(1),
    );
    expect(_lines(tester), isNotEmpty);
    expect(find.byKey(const ValueKey('marker-北')), findsOneWidget);
    // The names of the roads are not shown at first.
    expect(find.text('R1'), findsNothing);
  });

  testWidgets('the sheet has a check box for each layer', (tester) async {
    final world = _World()
      ..line('北', '東')
      ..choose(RouteMapLayerValue.network, false)
      ..choose(RouteMapLayerValue.scaleByCount, true);
    await _open(tester, world);

    await _openSheet(tester);

    expect(find.text(RouteMapStrings.layerSheetTitle), findsOneWidget);
    for (final layer in RouteMapLayerValue.values) {
      expect(_checkbox(layer), findsOneWidget);
      expect(find.text(RouteMapStrings.layerTitle(layer)), findsOneWidget);
    }
    expect(_checked(tester, RouteMapLayerValue.network), isFalse);
    expect(_checked(tester, RouteMapLayerValue.scaleByCount), isTrue);
    expect(_checked(tester, RouteMapLayerValue.traveled), isTrue);
    expect(_checked(tester, RouteMapLayerValue.networkNames), isFalse);
  });

  testWidgets('hides the network when it is unchecked, and keeps the choice', (
    tester,
  ) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);

    await _openSheet(tester);
    await tester.tap(_checkbox(RouteMapLayerValue.network));
    await tester.pumpAndSettle();

    expect(_checked(tester, RouteMapLayerValue.network), isFalse);
    expect(world.layers.stored.single.layerCode, 'network');
    expect(world.layers.stored.single.visible, isFalse);
    expect(_network, findsNothing);
    expect(_traveled, findsOneWidget);
  });

  testWidgets('hides the driven roads, and the lines cannot be tapped', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..choose(RouteMapLayerValue.traveled, false);

    await _open(tester, world);

    expect(_traveled, findsNothing);
    expect(_network, findsOneWidget);
  });

  testWidgets('hides the markers', (tester) async {
    final world = _World()
      ..line('北', '東')
      ..choose(RouteMapLayerValue.markers, false);

    await _open(tester, world);

    expect(find.byKey(const ValueKey('marker-北')), findsNothing);
    expect(_traveled, findsOneWidget);
  });

  testWidgets('hides the pending lines', (tester) async {
    final world = _World()
      ..line('北', '東')
      ..line('東', '北', day: 11, status: ConfirmationStatusValue.pending)
      ..choose(RouteMapLayerValue.pending, false);

    await _open(tester, world);

    expect(_lines(tester).map((p) => p.hitValue!.line.status).toSet(), {
      ConfirmationStatusValue.confirmed,
    });
  });

  testWidgets('draws a road driven often with a thicker line', (tester) async {
    final world = _World()
      ..line('北', '東')
      ..line('東', '北', day: 11)
      ..line('北', '東', day: 12);

    await _open(tester, world);
    expect(_lines(tester).map((p) => p.strokeWidth).toSet(), {
      segmentBaseWidth,
    });

    await _openSheet(tester);
    await tester.tap(_checkbox(RouteMapLayerValue.scaleByCount));
    await tester.pumpAndSettle();

    // Three times, in either direction: 2 more for each time after the first.
    expect(_lines(tester).map((p) => p.strokeWidth).toSet(), {segmentWidth(3)});
  });

  testWidgets('writes the names of the roads when the map is zoomed in', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..choose(RouteMapLayerValue.networkNames, true);

    await _open(tester, world);

    expect(find.text('R1'), findsOneWidget);
  });

  testWidgets('does not write the names of the roads on the whole country', (
    tester,
  ) async {
    // Without a line, the map shows the whole country.
    final world = _World()..choose(RouteMapLayerValue.networkNames, true);

    await _open(tester, world);

    expect(find.text('R1'), findsNothing);
  });

  testWidgets('keeps the map when the network cannot be made', (tester) async {
    final world = _World()
      ..networkError = StateError('x')
      ..line('北', '東');

    await _open(tester, world);

    expect(_network, findsNothing);
    expect(_traveled, findsOneWidget);
  });

  testWidgets('says so when a choice could not be stored', (tester) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);
    await _openSheet(tester);
    world.layers.error = StateError('x');

    await tester.tap(_checkbox(RouteMapLayerValue.markers));
    await tester.pump();

    expect(find.text(RouteMapStrings.layerSaveFailed), findsOneWidget);
  });

  testWidgets('uses the defaults when the choices cannot be read', (
    tester,
  ) async {
    final world = _World()..line('北', '東');
    world.layers.error = StateError('x');

    await _open(tester, world);

    expect(_network, findsOneWidget);
    expect(_traveled, findsOneWidget);
  });

  testWidgets('the use cases must be overridden', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(listRouteMapLayersUCProvider),
      throwsA(isA<Object>()),
    );
    expect(
      () => container.read(saveRouteMapLayerUCProvider),
      throwsA(isA<Object>()),
    );
    expect(
      () => container.read(listRouteNetworkUCProvider),
      throwsA(isA<Object>()),
    );
  });
}
