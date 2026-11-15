import 'dart:async';

import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/domain/entity/ic_point_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/userinterface/route_map/route_map_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

StatementLineDTO _line({
  DateTime? entranceAt,
  String? entranceIc = 'A-IC',
  String exitIc = 'B-IC',
  int? grossFare = 1200,
  int? etcDiscount = -240,
  ConfirmationStatusValue status = ConfirmationStatusValue.confirmed,
  List<String> discountTypes = const ['深夜割引', '休日割引'],
  List<String> routeNames = const ['テスト自動車道', 'テスト都市高速'],
}) {
  return StatementLineDTO(
    entranceAt: entranceAt ?? DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: entranceIc,
    exitIc: exitIc,
    grossFare: grossFare,
    etcDiscount: etcDiscount,
    fare: 960,
    fareAfterRebate: 100,
    postpaidFare: 860,
    vehicleType: VehicleTypeValue.standard,
    vehicleNumber: 1234,
    cardNumberSuffix: '0001',
    status: status,
    discountTypes: discountTypes,
    routeNames: routeNames,
  );
}

/// The IC master has テスト北 and テスト東 only, so A-IC and B-IC are unknown
/// to it.
FakeIcMasterIF _master() => FakeIcMasterIF([
  fakeIcPoint(name: 'テスト北', latitude: 35.1, longitude: 139.1),
  fakeIcPoint(name: 'テスト東', latitude: 35.2, longitude: 139.2),
]);

/// An IC master that answers when the test says so.
class _SlowMaster extends FakeIcMasterIF {
  _SlowMaster() : super([]);

  final done = Completer<void>();

  @override
  Future<List<IcPointEntity>> findAll() async {
    await done.future;
    return super.findAll();
  }
}

/// The screen is a long list, so the test window is made tall enough to build
/// every field. The map tiles need the network, so no tiles are drawn.
Future<void> _show(
  WidgetTester tester,
  StatementLineDTO? line, {
  FakeIcMasterIF? master,
  FakeIcPositionIF? positions,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final uc = GetLineRouteUC(
    icMaster: master ?? _master(),
    icMappings: FakeIcMappingIF(),
    icPositions: positions ?? FakeIcPositionIF(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getLineRouteUCProvider.overrideWithValue(uc),
        tileLayerProvider.overrideWithValue(const SizedBox.shrink()),
      ],
      child: MaterialApp(home: StatementDetailScreen(line: line)),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('shows every field', (tester) async {
    await _show(tester, _line());

    for (final text in [
      StatementDetailStrings.title,
      '2026/01/10 08:30',
      '2026/01/10 09:15',
      'A-IC',
      'B-IC',
      '1,200円',
      '-240円',
      '960円',
      '100円',
      '860円',
      '普通車',
      '1234',
      '**** 0001',
      StatementDetailStrings.confirmed,
      '深夜割引・休日割引',
      StatementDetailStrings.routeNames,
      'テスト自動車道・テスト都市高速',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text(StatementDetailStrings.notFound), findsNothing);
  });

  testWidgets('shows - for a blank entrance and for no discount', (
    tester,
  ) async {
    final line = StatementLineDTO(
      entranceAt: null,
      exitAt: DateTime(2026, 1, 10, 9, 15),
      entranceIc: null,
      exitIc: 'B-IC',
      grossFare: null,
      etcDiscount: null,
      fare: 960,
      fareAfterRebate: 0,
      postpaidFare: 960,
      vehicleType: VehicleTypeValue.standard,
      vehicleNumber: 1234,
      cardNumberSuffix: '0001',
      status: ConfirmationStatusValue.confirmed,
      discountTypes: const [],
    );
    await _show(tester, line);

    // Entrance date and time, entrance IC, route names, gross fare and ETC
    // discount.
    expect(find.text(StatementDetailStrings.blank), findsNWidgets(5));
    expect(find.text(StatementDetailStrings.none), findsOneWidget);
  });

  testWidgets('shows a pending statement line as pending', (tester) async {
    await _show(tester, _line(status: ConfirmationStatusValue.pending));

    expect(find.text(StatementDetailStrings.pending), findsOneWidget);
    expect(find.text(StatementDetailStrings.confirmed), findsNothing);
  });

  testWidgets('says so when opened without a statement line', (tester) async {
    await _show(tester, null);

    expect(find.text(StatementDetailStrings.notFound), findsOneWidget);
    expect(find.text('B-IC'), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);
  });

  group('route map', () {
    List<Polyline<Object>> lines(WidgetTester tester) => tester
        .widget<PolylineLayer<Object>>(find.byType(PolylineLayer<Object>))
        .polylines;

    testWidgets('draws the line and marks the entrance and the exit', (
      tester,
    ) async {
      await _show(tester, _line(entranceIc: 'テスト北', exitIc: 'テスト東'));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byKey(const ValueKey('line-place-テスト北')), findsOneWidget);
      expect(find.byKey(const ValueKey('line-place-テスト東')), findsOneWidget);
      expect(lines(tester), hasLength(1));
      expect(lines(tester).single.pattern.segments, isNull);
      expect(find.textContaining('位置が分からない'), findsNothing);
      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });

    testWidgets('draws a pending line dashed', (tester) async {
      await _show(
        tester,
        _line(
          entranceIc: 'テスト北',
          exitIc: 'テスト東',
          status: ConfirmationStatusValue.pending,
        ),
      );

      expect(lines(tester).single.pattern.segments, isNotNull);
    });

    testWidgets('marks a position the app borrowed as approximate', (
      tester,
    ) async {
      await _show(tester, _line(entranceIc: 'テスト北', exitIc: 'テスト東本線'));

      expect(find.text('テスト東本線（近似）'), findsOneWidget);
    });

    testWidgets('uses the position the user chose', (tester) async {
      final positions = FakeIcPositionIF()
        ..stored.add(
          const IcPositionEntity(icName: 'B-IC', latitude: 36, longitude: 140),
        );

      await _show(
        tester,
        _line(entranceIc: 'テスト北', exitIc: 'B-IC'),
        positions: positions,
      );

      expect(lines(tester), hasLength(1));
      expect(lines(tester).single.points.last.latitude, 36);
    });

    testWidgets('says which IC has no position, and marks the known one', (
      tester,
    ) async {
      await _show(tester, _line(entranceIc: 'テスト北'));

      expect(
        find.text(StatementDetailStrings.unlocatedNotice(['B-IC'])),
        findsOneWidget,
      );
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer<Object>), findsNothing);
      expect(find.byKey(const ValueKey('line-place-テスト北')), findsOneWidget);
    });

    testWidgets('marks only the exit when the entrance is blank', (
      tester,
    ) async {
      await _show(tester, _line(entranceIc: null, exitIc: 'テスト東'));

      expect(find.byType(PolylineLayer<Object>), findsNothing);
      expect(find.byKey(const ValueKey('line-place-テスト東')), findsOneWidget);
      expect(find.textContaining('位置が分からない'), findsNothing);
    });

    testWidgets('shows no map when no position is known', (tester) async {
      await _show(tester, _line());

      expect(find.byType(FlutterMap), findsNothing);
      expect(
        find.text(StatementDetailStrings.unlocatedNotice(['A-IC', 'B-IC'])),
        findsOneWidget,
      );
      // The other fields are shown all the same.
      expect(find.text('960円'), findsOneWidget);
    });

    testWidgets('shows the other fields while the route is loading', (
      tester,
    ) async {
      final master = _SlowMaster();

      await _show(tester, _line(), master: master, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('960円'), findsOneWidget);

      master.done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('says so when the route cannot be read, keeping the fields', (
      tester,
    ) async {
      final positions = FakeIcPositionIF()..error = StateError('x');

      await _show(tester, _line(), positions: positions);

      expect(find.text(StatementDetailStrings.routeLoadFailed), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('960円'), findsOneWidget);
    });
  });
}
