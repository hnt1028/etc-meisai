import 'dart:async';

import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/route_map/get_line_route_uc.dart';
import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
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
  String? id,
  bool withoutVehicleNumber = false,
}) {
  return StatementLineDTO(
    id: id,
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
    vehicleNumber: withoutVehicleNumber ? null : 1234,
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
  FakeStatementLineIF? lines,
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
        saveVehicleNumberUCProvider.overrideWithValue(
          SaveVehicleNumberUC(statementLines: lines ?? FakeStatementLineIF()),
        ),
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

  group('vehicle number', () {
    final enter = find.byKey(const ValueKey('enter-vehicle-number'));

    /// A stored line without a vehicle number, and the screen for it.
    Future<FakeStatementLineIF> showBlank(WidgetTester tester) async {
      final lines = FakeStatementLineIF()
        ..stored.add(
          fakeStatementLine(id: 'blank', withoutVehicleNumber: true),
        );
      await _show(
        tester,
        _line(id: 'blank', withoutVehicleNumber: true),
        lines: lines,
      );
      return lines;
    }

    Future<void> typeNumber(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pumpAndSettle();
    }

    FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, StatementDetailStrings.save),
    );

    testWidgets('shows - and an enter button when there is none', (
      tester,
    ) async {
      await showBlank(tester);

      expect(enter, findsOneWidget);
      expect(find.text('1234'), findsNothing);
    });

    testWidgets('shows no button when the line has a number', (tester) async {
      await _show(tester, _line(id: 'x'));

      expect(find.text('1234'), findsOneWidget);
      expect(enter, findsNothing);
    });

    testWidgets('shows no button for a line that is not stored', (
      tester,
    ) async {
      await _show(tester, _line(withoutVehicleNumber: true));

      expect(enter, findsNothing);
    });

    testWidgets('saves the number once, and shows it', (tester) async {
      final lines = await showBlank(tester);

      await tester.tap(enter);
      await tester.pumpAndSettle();
      expect(
        find.text(StatementDetailStrings.vehicleNumberOnceNotice),
        findsOneWidget,
      );
      await typeNumber(tester, '4321');
      await tester.tap(find.text(StatementDetailStrings.save));
      await tester.pumpAndSettle();

      // Saved, shown, and the button is gone: it cannot be entered again.
      expect(lines.stored.single.vehicleNumber, 4321);
      expect(find.text('4321'), findsOneWidget);
      expect(enter, findsNothing);
      expect(
        find.text(StatementDetailStrings.saveVehicleNumberFailed),
        findsNothing,
      );
    });

    testWidgets('cannot save until the number has one to four digits', (
      tester,
    ) async {
      await showBlank(tester);
      await tester.tap(enter);
      await tester.pumpAndSettle();

      expect(saveButton(tester).onPressed, isNull);
      await typeNumber(tester, '0');
      expect(saveButton(tester).onPressed, isNull);
      await typeNumber(tester, '00');
      expect(saveButton(tester).onPressed, isNull);
      await typeNumber(tester, '1');
      expect(saveButton(tester).onPressed, isNotNull);
      await typeNumber(tester, '9999');
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('accepts only digits, and at most four', (tester) async {
      await showBlank(tester);
      await tester.tap(enter);
      await tester.pumpAndSettle();

      await typeNumber(tester, '12ab-34567');

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '1234',
      );
    });

    testWidgets('saves nothing when the dialog is cancelled', (tester) async {
      final lines = await showBlank(tester);
      await tester.tap(enter);
      await tester.pumpAndSettle();
      await typeNumber(tester, '4321');

      await tester.tap(find.text(StatementDetailStrings.cancel));
      await tester.pumpAndSettle();

      expect(lines.stored.single.vehicleNumber, isNull);
      expect(enter, findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('says so when saving fails, without details', (tester) async {
      final lines = await showBlank(tester);
      lines.error = StateError('secret 4321');
      await tester.tap(enter);
      await tester.pumpAndSettle();
      await typeNumber(tester, '4321');

      await tester.tap(find.text(StatementDetailStrings.save));
      await tester.pumpAndSettle();

      expect(
        find.text(StatementDetailStrings.saveVehicleNumberFailed),
        findsOneWidget,
      );
      expect(find.textContaining('secret'), findsNothing);
      // The number is not shown, and can be entered again.
      expect(find.text('4321'), findsNothing);
      expect(enter, findsOneWidget);
    });

    testWidgets('says so when the line already has a number elsewhere', (
      tester,
    ) async {
      // The screen has a line without a number, but the stored one has one.
      final lines = FakeStatementLineIF()
        ..stored.add(fakeStatementLine(id: 'blank', vehicleNumber: 1));
      await _show(
        tester,
        _line(id: 'blank', withoutVehicleNumber: true),
        lines: lines,
      );
      await tester.tap(enter);
      await tester.pumpAndSettle();
      await typeNumber(tester, '4321');

      await tester.tap(find.text(StatementDetailStrings.save));
      await tester.pumpAndSettle();

      expect(
        find.text(StatementDetailStrings.saveVehicleNumberFailed),
        findsOneWidget,
      );
      expect(lines.stored.single.vehicleNumber, 1);
    });
  });

  test('the use cases must be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(saveVehicleNumberUCProvider),
      throwsA(anything),
    );
  });
}
