import 'dart:async';

import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/delete_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/route_map/save_ic_position_uc.dart';
import 'package:etc_meisai/application/usecase/ic_mapping/search_ic_points_uc.dart';
import 'package:etc_meisai/userinterface/ic_mapping/ic_mapping_providers.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/app_strings.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_controller.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_screen.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../support/fakes.dart';

/// An IC master whose points cannot be read.
class _BrokenMaster extends FakeIcMasterIF {
  _BrokenMaster() : super(const []);

  @override
  Future<List<IcPointEntity>> findAll() async => throw StateError('x');
}

/// Everything the screen reads, kept in memory so that a test can change it.
class _World {
  final lines = FakeStatementLineIF();
  final positions = FakeIcPositionIF();

  /// The links of the IC master, which a test can set (a road through ICs).
  final links = <IcLinkEntity>[];

  /// The master the search reads, when a test needs another one.
  FakeIcMasterIF? searchMaster;

  FakeIcMasterIF get master => FakeIcMasterIF([
    fakeIcPoint(
      name: '北',
      routeNames: const ['北線'],
      latitude: 35.1,
      longitude: 139.1,
    ),
    fakeIcPoint(
      name: '東',
      routeNames: const ['東線'],
      latitude: 35.2,
      longitude: 139.3,
    ),
    fakeIcPoint(name: '南', latitude: 35.0, longitude: 139.4),
    // On the road between 北 and 東.
    fakeIcPoint(name: '中', latitude: 35.3, longitude: 139.15),
  ], links: links);

  /// A line from [from] to [to], on its own day.
  void line(
    String from,
    String to, {
    int day = 10,
    ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
    int vehicleNumber = 1234,
  }) {
    lines.stored.add(
      fakeStatementLine(
        entranceIc: from,
        exitIc: to,
        entranceAt: DateTime(2026, 1, day, 8),
        exitAt: DateTime(2026, 1, day, 9),
        status: status,
        vehicleNumber: vehicleNumber,
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
      saveIcPositionUCProvider.overrideWithValue(
        SaveIcPositionUC(icPositions: positions),
      ),
      searchIcPointsUCProvider.overrideWithValue(
        SearchIcPointsUC(icMaster: searchMaster ?? master),
      ),
      deleteIcPositionUCProvider.overrideWithValue(
        DeleteIcPositionUC(icPositions: positions),
      ),
      tileLayerProvider.overrideWithValue(const SizedBox.shrink()),
    ],
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );
}

Future<void> _open(WidgetTester tester, _World world) async {
  await tester.pumpWidget(world.app());
  await tester.pumpAndSettle();
  await tester.tap(find.text(AppStrings.routeMapTab));
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.text(text);

List<Polyline<RouteSegmentDTO>> _polylines(WidgetTester tester) => tester
    .widget<PolylineLayer<RouteSegmentDTO>>(
      find.byType(PolylineLayer<RouteSegmentDTO>),
    )
    .polylines;

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(RouteMapScreen)));

/// The marker of the IC [name]: the tap area around its dot.
Finder _marker(String name) => find.byKey(ValueKey('marker-$name'));

/// Taps the map. The map waits for a possible double tap before it reports a
/// tap, so the test lets that time pass.
Future<void> _tapMap(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// The title of the screen (the navigation bar has the same text).
Finder get _title => find.descendant(
  of: find.byType(AppBar),
  matching: find.text(RouteMapStrings.title),
);

/// The middle of the map. The camera fits two markers, so the line between
/// them runs through it.
Offset _center(WidgetTester tester) =>
    tester.getCenter(find.byType(FlutterMap));

void main() {
  testWidgets('draws the lines and the markers of the lines', (tester) async {
    final world = _World()
      ..line('北', '東')
      ..line('東', '南', day: 11, status: ConfirmationStatusValue.pending);

    await _open(tester, world);

    expect(_title, findsOneWidget);
    for (final name in ['北', '東', '南']) {
      expect(_text(name), findsOneWidget);
    }
    expect(_text(RouteMapStrings.attribution), findsNothing);
    expect(find.byType(RichAttributionWidget), findsOneWidget);
    // No banner when every IC has a position.
    expect(find.textContaining('位置不明'), findsNothing);
  });

  testWidgets('draws a confirmed line solid and a pending line dashed', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..line('東', '南', day: 11, status: ConfirmationStatusValue.pending);

    await _open(tester, world);

    final lines = _polylines(tester);
    expect(lines, hasLength(2));
    final confirmed = lines.singleWhere(
      (l) => l.hitValue!.line.status == ConfirmationStatusValue.confirmed,
    );
    final pending = lines.singleWhere(
      (l) => l.hitValue!.line.status == ConfirmationStatusValue.pending,
    );
    expect(confirmed.pattern.segments, isNull);
    expect(pending.pattern.segments, isNotNull);
    expect(confirmed.points.first, const LatLng(35.1, 139.1));
    expect(confirmed.points.last, const LatLng(35.2, 139.3));
  });

  testWidgets('draws lines that overlap, one for each statement line', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..line('北', '東', day: 11)
      ..line('東', '北', day: 12);

    await _open(tester, world);

    expect(_polylines(tester), hasLength(3));
    // One marker for each IC.
    expect(_text('北'), findsOneWidget);
  });

  testWidgets('tells how many ICs have no position, without drawing them', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..line('北', '不明', day: 11)
      ..line('不明', '東', day: 12);

    await _open(tester, world);

    expect(_text(RouteMapStrings.unlocatedBanner(1, 2)), findsOneWidget);
    expect(_polylines(tester), hasLength(1));
    // The unknown IC has no marker.
    expect(find.text('不明'), findsNothing);
  });

  testWidgets('says nothing about a line without an entrance', (tester) async {
    final world = _World()..line('北', '東');
    world.lines.stored.add(
      fakeStatementLine(exitIc: '南', withoutEntrance: true),
    );

    await _open(tester, world);

    expect(find.textContaining('位置不明'), findsNothing);
    expect(_text('南'), findsOneWidget);
    expect(_polylines(tester), hasLength(1));
  });

  group('choosing a position', () {
    Future<_World> start(WidgetTester tester) async {
      final world = _World()
        ..line('北', '東')
        ..line('北', '不明', day: 11);
      await _open(tester, world);
      return world;
    }

    Future<void> chooseUnknown(WidgetTester tester) async {
      await tester.tap(_text(RouteMapStrings.specifyPosition));
      await tester.pumpAndSettle();
      expect(_text(RouteMapStrings.unlocatedSheetTitle), findsOneWidget);
      expect(_text(RouteMapStrings.lineCount(1)), findsOneWidget);
      await tester.tap(_text('不明'));
      await tester.pumpAndSettle();
    }

    testWidgets('registers the tapped point and draws the line', (
      tester,
    ) async {
      final world = await start(tester);
      await chooseUnknown(tester);

      expect(_text(RouteMapStrings.picking('不明')), findsOneWidget);
      // Nothing can be registered before the map is tapped.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, RouteMapStrings.register),
            )
            .onPressed,
        isNull,
      );

      await _tapMap(tester, _center(tester));
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      await tester.tap(_text(RouteMapStrings.register));
      await tester.pumpAndSettle();

      expect(world.positions.stored.single.icName, '不明');
      expect(_text(RouteMapStrings.picking('不明')), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(find.textContaining('位置不明'), findsNothing);
      expect(_polylines(tester), hasLength(2));
      expect(_text('不明'), findsOneWidget);
    });

    testWidgets('moves the pin with another tap', (tester) async {
      await start(tester);
      await chooseUnknown(tester);

      await _tapMap(tester, _center(tester));
      final first = tester.getCenter(find.byIcon(Icons.location_on));
      await _tapMap(tester, _center(tester) + const Offset(60, 40));

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(tester.getCenter(find.byIcon(Icons.location_on)), isNot(first));
    });

    testWidgets('cancels without registering anything', (tester) async {
      final world = await start(tester);
      await chooseUnknown(tester);
      await _tapMap(tester, _center(tester));

      await tester.tap(_text(RouteMapStrings.cancel));
      await tester.pumpAndSettle();

      expect(world.positions.stored, isEmpty);
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(_text(RouteMapStrings.picking('不明')), findsNothing);
      expect(_text(RouteMapStrings.unlocatedBanner(1, 1)), findsOneWidget);
    });

    testWidgets('shows a failure to register, and keeps the pin', (
      tester,
    ) async {
      final world = await start(tester);
      await chooseUnknown(tester);
      await _tapMap(tester, _center(tester));

      world.positions.saveError = StateError('secret');
      await tester.tap(_text(RouteMapStrings.register));
      await tester.pumpAndSettle();

      expect(_text(RouteMapStrings.saveFailed), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(_text(RouteMapStrings.picking('不明')), findsOneWidget);
    });

    testWidgets('does not open a marker or a line while choosing', (
      tester,
    ) async {
      await start(tester);
      await chooseUnknown(tester);

      // The tap goes to the map (it moves the pin), not to the marker.
      await _tapMap(tester, tester.getCenter(_marker('北')));

      expect(_text(RouteMapStrings.respecify), findsNothing);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });
  });

  group('marker', () {
    testWidgets('shows what is known about an IC of the master', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await tester.tap(_marker('北'));
      await tester.pumpAndSettle();

      expect(
        find.text('${RouteMapStrings.routeNamesLabel}: 北線'),
        findsOneWidget,
      );
      expect(
        find.text(
          '${RouteMapStrings.positionLabel}: ${RouteMapStrings.positionMaster}',
        ),
        findsOneWidget,
      );
      expect(_text(RouteMapStrings.lineCount(1)), findsOneWidget);
      expect(_text(RouteMapStrings.respecify), findsOneWidget);
      expect(_text(RouteMapStrings.unspecify), findsNothing);
    });

    testWidgets('marks the position of a toll gate as approximate', (
      tester,
    ) async {
      final world = _World()..line('北', '北本線');
      await _open(tester, world);

      expect(
        _text(RouteMapStrings.markerLabel('北本線', approximate: true)),
        findsOneWidget,
      );
      await tester.tap(_marker('北本線'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '${RouteMapStrings.positionLabel}: ${RouteMapStrings.positionMaster}'
          '${RouteMapStrings.approximate}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('lets the user choose the position again', (tester) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await tester.tap(_marker('東'));
      await tester.pumpAndSettle();
      await tester.tap(_text(RouteMapStrings.respecify));
      await tester.pumpAndSettle();

      expect(_text(RouteMapStrings.picking('東')), findsOneWidget);
      expect(_container(tester).read(icPickingProvider).icName, '東');
    });

    testWidgets('unspecifies a position the user chose', (tester) async {
      final world = _World()..line('北', '東');
      world.positions.stored.add(
        const IcPositionEntity(icName: '東', latitude: 36.0, longitude: 140.0),
      );
      await _open(tester, world);

      await tester.tap(_marker('東'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          '${RouteMapStrings.positionLabel}: ${RouteMapStrings.positionSpecified}',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '${RouteMapStrings.routeNamesLabel}: ${RouteMapStrings.noRouteNames}',
        ),
        findsOneWidget,
      );
      await tester.tap(_text(RouteMapStrings.unspecify));
      await tester.pumpAndSettle();

      expect(world.positions.stored, isEmpty);
      final line = _polylines(tester).single;
      expect(line.points.last, const LatLng(35.2, 139.3));
    });

    testWidgets('shows a failure to unspecify', (tester) async {
      final world = _World()..line('北', '東');
      world.positions.stored.add(
        const IcPositionEntity(icName: '東', latitude: 36.0, longitude: 140.0),
      );
      await _open(tester, world);
      await tester.tap(_marker('東'));
      await tester.pumpAndSettle();

      world.positions.deleteError = StateError('secret');
      await tester.tap(_text(RouteMapStrings.unspecify));
      await tester.pumpAndSettle();

      expect(_text(RouteMapStrings.deleteFailed), findsOneWidget);
    });
  });

  group('line', () {
    testWidgets('chooses the tapped line, then opens its detail', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await _tapMap(tester, _center(tester));

      // The line is chosen: a card says which one, and nothing is opened.
      expect(find.byKey(const ValueKey('selected-lines')), findsOneWidget);
      expect(_text(StatementListStrings.route('北', '東')), findsOneWidget);
      expect(_text(StatementDetailStrings.title), findsNothing);

      await tester.tap(find.byKey(const ValueKey('open-selected')));
      await tester.pumpAndSettle();

      expect(_text(StatementDetailStrings.title), findsOneWidget);
      expect(_text('東'), findsWidgets);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(_title, findsOneWidget);
    });

    testWidgets('lets the user choose among lines that overlap', (
      tester,
    ) async {
      final world = _World()
        ..line('北', '東', day: 10)
        ..line('北', '東', day: 11);
      await _open(tester, world);

      await _tapMap(tester, _center(tester));

      // Both lines are chosen, and the list is opened from the card.
      expect(_text(RouteMapStrings.overlapped(2)), findsOneWidget);
      expect(_text(RouteMapStrings.segmentSheetTitle), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-selected')));
      await tester.pumpAndSettle();

      expect(_text(RouteMapStrings.segmentSheetTitle), findsOneWidget);
      expect(_text(StatementListStrings.route('北', '東')), findsNWidgets(2));

      await tester.tap(find.textContaining('2026/01/11 08:00'));
      await tester.pumpAndSettle();

      expect(_text(StatementDetailStrings.title), findsOneWidget);
      expect(_text('2026/01/11 08:00'), findsOneWidget);
    });

    testWidgets('does nothing when the tap misses every line', (tester) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await _tapMap(tester, _center(tester) + const Offset(0, 150));

      expect(_text(StatementDetailStrings.title), findsNothing);
      expect(_text(RouteMapStrings.segmentSheetTitle), findsNothing);
      expect(find.byKey(const ValueKey('selected-lines')), findsNothing);
    });

    testWidgets('draws the chosen line out, and the others paler', (
      tester,
    ) async {
      final world = _World()
        ..line('北', '東')
        ..line('東', '南', day: 11);
      await _open(tester, world);
      // The middle of the line from 北 to 東 (a straight line here).
      final map = tester.getTopLeft(find.byType(FlutterMap));
      final camera = MapCamera.of(
        tester.element(find.byType(PolylineLayer<RouteSegmentDTO>)),
      );
      final onLine =
          map + camera.latLngToScreenOffset(const LatLng(35.15, 139.2));
      double width(WidgetTester t, String to) => _polylines(
        t,
      ).firstWhere((p) => p.hitValue!.toIcName == to).strokeWidth;
      double alpha(WidgetTester t, String to) =>
          _polylines(t).firstWhere((p) => p.hitValue!.toIcName == to).color.a;
      final before = width(tester, '東');
      final opaque = alpha(tester, '南');

      await _tapMap(tester, onLine);

      expect(width(tester, '東'), before + selectedExtraWidth);
      expect(alpha(tester, '東'), opaque);
      expect(width(tester, '南'), before);
      expect(alpha(tester, '南'), lessThan(opaque));
    });

    testWidgets('lets go of the line with the close button or another tap', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await _tapMap(tester, _center(tester));
      await tester.tap(find.byKey(const ValueKey('clear-selected')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('selected-lines')), findsNothing);

      await _tapMap(tester, _center(tester));
      expect(find.byKey(const ValueKey('selected-lines')), findsOneWidget);
      // Away from the line, and from the card at the bottom.
      await _tapMap(tester, _center(tester) + const Offset(0, -100));
      expect(find.byKey(const ValueKey('selected-lines')), findsNothing);
    });

    testWidgets('forgets the chosen line when the lines are read again', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);
      await _tapMap(tester, _center(tester));
      expect(find.byKey(const ValueKey('selected-lines')), findsOneWidget);

      _container(
        tester,
      ).read(statementFilterProvider.notifier).setVehicleNumber(1234);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('selected-lines')), findsNothing);
    });
  });

  group('map tools', () {
    MapCamera camera(WidgetTester tester) => MapCamera.of(
      tester.element(find.byType(PolylineLayer<RouteSegmentDTO>)),
    );

    testWidgets('shows everything again with the fit button', (tester) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);
      final first = camera(tester).center;
      final firstZoom = camera(tester).zoom;

      await tester.drag(find.byType(FlutterMap), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(
        camera(tester).center.longitude,
        isNot(closeTo(first.longitude, 1e-6)),
      );

      await tester.tap(find.byKey(const ValueKey('fit-button')));
      await tester.pumpAndSettle();

      expect(camera(tester).center.longitude, closeTo(first.longitude, 1e-3));
      expect(camera(tester).center.latitude, closeTo(first.latitude, 1e-3));
      expect(camera(tester).zoom, closeTo(firstZoom, 1e-3));
    });

    testWidgets('shows the whole country with the fit button without lines', (
      tester,
    ) async {
      await _open(tester, _World());

      await tester.drag(find.byType(FlutterMap), const Offset(200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fit-button')));
      await tester.pumpAndSettle();

      final c = MapCamera.of(tester.element(find.byType(MarkerLayer).first));
      expect(c.center.latitude, closeTo(36.2, 1e-6));
      expect(c.zoom, 5);
    });

    Future<void> search(WidgetTester tester, String text) async {
      await tester.tap(find.byKey(const ValueKey('search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('map-search-field')),
        text,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('moves the map to the IC that is chosen', (tester) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await search(tester, '南');
      expect(
        find.byKey(const ValueKey('map-search-result-id-南')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('map-search-result-id-南')));
      await tester.pumpAndSettle();

      expect(camera(tester).center.latitude, closeTo(35.0, 1e-3));
      expect(camera(tester).center.longitude, closeTo(139.4, 1e-3));
      expect(camera(tester).zoom, foundZoom);
      expect(find.byKey(const ValueKey('found')), findsOneWidget);

      // The mark goes away with the fit button.
      await tester.tap(find.byKey(const ValueKey('fit-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('found')), findsNothing);
    });

    testWidgets('says so when no IC has the name', (tester) async {
      await _open(tester, _World()..line('北', '東'));

      await search(tester, 'ない名前');

      expect(_text(RouteMapStrings.searchNone), findsOneWidget);
    });

    testWidgets('lists nothing before a name is typed, and can be closed', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);

      await tester.tap(find.byKey(const ValueKey('search-button')));
      await tester.pumpAndSettle();
      expect(_text(RouteMapStrings.searchTitle), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => '${w.key}'.contains('map-search-result')),
        findsNothing,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_text(RouteMapStrings.searchTitle), findsNothing);
      expect(find.byKey(const ValueKey('found')), findsNothing);
    });

    testWidgets('says so when the search fails', (tester) async {
      final world = _World()
        ..line('北', '東')
        ..searchMaster = _BrokenMaster();
      await _open(tester, world);

      await search(tester, '北');

      expect(_text(RouteMapStrings.searchFailed), findsOneWidget);
    });

    testWidgets('leaves the chosen line when the map moves to an IC', (
      tester,
    ) async {
      final world = _World()..line('北', '東');
      await _open(tester, world);
      await _tapMap(tester, _center(tester));
      expect(find.byKey(const ValueKey('selected-lines')), findsOneWidget);

      await search(tester, '南');
      await tester.tap(find.byKey(const ValueKey('map-search-result-id-南')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('selected-lines')), findsNothing);
    });
  });

  testWidgets('says so when nothing is imported, and still shows the map', (
    tester,
  ) async {
    await _open(tester, _World());

    expect(_text(StatementListStrings.emptyNoData), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('says so when the filter leaves nothing', (tester) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);

    _container(tester)
        .read(statementFilterProvider.notifier)
        .setPeriod(DateTime(2030, 1, 1), DateTime(2030, 1, 2));
    await tester.pumpAndSettle();

    expect(_text(StatementListStrings.emptyNoMatch), findsOneWidget);
    expect(_polylines(tester), isEmpty);
  });

  testWidgets('filters with the controls shared with the statement list', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東', vehicleNumber: 1)
      ..line('東', '南', day: 11, vehicleNumber: 2);
    await _open(tester, world);
    expect(_polylines(tester), hasLength(2));
    // The filter starts closed.
    expect(_text(StatementListStrings.vehicleNumberLabel), findsNothing);

    await tester.tap(_text(RouteMapStrings.filterTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(_polylines(tester), hasLength(1));
    expect(_container(tester).read(statementFilterProvider).vehicleNumber, 2);
    expect(_text(StatementListStrings.clearFilter), findsOneWidget);
  });

  testWidgets('keeps the open filter apart from the map', (tester) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);

    await tester.tap(_text(RouteMapStrings.filterTitle));
    await tester.pumpAndSettle();

    // The card number box is the last control of the filter. The map starts
    // below it with room between them: the padding and a line.
    final controlsBottom = tester
        .getBottomLeft(find.byType(DropdownButtonFormField<String?>))
        .dy;
    final mapTop = tester.getTopLeft(find.byType(FlutterMap)).dy;
    expect(mapTop - controlsBottom, greaterThanOrEqualTo(12));
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('draws a line through the ICs on the way', (tester) async {
    final world = _World()
      ..links.addAll(const [
        IcLinkEntity(fromId: 'id-北', toId: 'id-中', meters: 1000),
        IcLinkEntity(fromId: 'id-中', toId: 'id-東', meters: 1000),
      ])
      ..line('北', '東');
    await _open(tester, world);

    final line = _polylines(tester).single;

    // From 北, through 中, to 東.
    expect(line.points, const [
      LatLng(35.1, 139.1),
      LatLng(35.3, 139.15),
      LatLng(35.2, 139.3),
    ]);
  });

  testWidgets('draws a straight line when no way over the links is known', (
    tester,
  ) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);

    expect(_polylines(tester).single.points, const [
      LatLng(35.1, 139.1),
      LatLng(35.2, 139.3),
    ]);
  });

  testWidgets('shows a progress indicator while reading', (tester) async {
    final world = _World()..line('北', '東');
    await tester.pumpWidget(world.app());
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    world.lines.readGate = gate.future;
    await tester.tap(find.text(AppStrings.routeMapTab));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('keeps the map while it reads again', (tester) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);

    final gate = Completer<void>();
    world.lines.readGate = gate.future;
    _container(tester).read(statementFilterProvider.notifier).clear();
    _container(tester).invalidate(routeMapProvider);
    await tester.pump();
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('shows a failure without details, and reads again on request', (
    tester,
  ) async {
    final world = _World()
      ..line('北', '東')
      ..lines.readError = StateError('secret');
    await _open(tester, world);

    expect(_text(RouteMapStrings.loadFailed), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);

    world.lines.readError = null;
    await tester.tap(_text(RouteMapStrings.retry));
    await tester.pumpAndSettle();

    expect(_text(RouteMapStrings.loadFailed), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('reads again when the stored data changes', (tester) async {
    final world = _World()..line('北', '東');
    await _open(tester, world);
    expect(_polylines(tester), hasLength(1));

    world.line('東', '南', day: 11);
    await _container(tester).read(routeMapActionsProvider).deletePosition('x');
    await tester.pumpAndSettle();

    expect(_polylines(tester), hasLength(2));
  });

  test('the use cases must be overridden', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(() => c.read(listRouteMapUCProvider), throwsA(anything));
    expect(() => c.read(saveIcPositionUCProvider), throwsA(anything));
    expect(() => c.read(deleteIcPositionUCProvider), throwsA(anything));
  });

  test('the map tiles are the ones of OpenStreetMap by default', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final layer = c.read(tileLayerProvider) as TileLayer;

    expect(layer.urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer.tileProvider, isA<NetworkTileProvider>());
    expect(
      (layer.tileProvider as NetworkTileProvider).headers['User-Agent'],
      contains('jp.mtrk.etc_meisai'),
    );
  });

  test('the pin can be put only while a position is being chosen', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final picking = c.read(icPickingProvider.notifier);

    picking.setPin(const LatLng(1, 2));
    expect(c.read(icPickingProvider).pin, isNull);

    picking.start('x');
    picking.setPin(const LatLng(1, 2));
    expect(c.read(icPickingProvider).pin, const LatLng(1, 2));

    picking.cancel();
    expect(c.read(icPickingProvider).icName, isNull);
    expect(c.read(icPickingProvider).pin, isNull);
  });
}
