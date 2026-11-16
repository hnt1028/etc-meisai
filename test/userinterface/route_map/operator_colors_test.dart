import 'package:etc_meisai/application/dto/route_run_dto.dart';
import 'package:etc_meisai/application/dto/route_segment_dto.dart';
import 'package:etc_meisai/application/dto/route_vertex_dto.dart';
import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/application/usecase/aggregation/route_operators.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/userinterface/route_map/operator_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StatementLineDTO _line() => StatementLineDTO(
  entranceAt: DateTime(2026, 1, 10, 8),
  exitAt: DateTime(2026, 1, 10, 9),
  entranceIc: 'a',
  exitIc: 'b',
  grossFare: null,
  etcDiscount: null,
  fare: 100,
  fareAfterRebate: 100,
  postpaidFare: 100,
  vehicleType: VehicleTypeValue.standard,
  vehicleNumber: 1,
  cardNumberSuffix: '0001',
  status: ConfirmationStatusValue.confirmed,
  discountTypes: const [],
);

/// The color of [operator] on a theme of [brightness].
Future<Color> _color(
  WidgetTester tester,
  String operator,
  Brightness brightness,
) async {
  late Color color;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Builder(
        builder: (context) {
          color = operatorLineColor(context, operator);
          return const SizedBox();
        },
      ),
    ),
  );
  // The theme changes with an animation.
  await tester.pumpAndSettle();
  return color;
}

void main() {
  group('operatorLineColor', () {
    testWidgets('has its own color for every operator of the table', (
      tester,
    ) async {
      final colors = <Color>{};
      for (final operator in knownOperators) {
        colors.add(await _color(tester, operator, Brightness.light));
      }
      expect(colors, hasLength(knownOperators.length));
    });

    testWidgets('is lighter on a dark theme, so it can be seen there', (
      tester,
    ) async {
      final light = await _color(tester, 'NEXCO東日本', Brightness.light);
      final dark = await _color(tester, 'NEXCO東日本', Brightness.dark);

      expect(
        HSLColor.fromColor(dark).lightness,
        greaterThan(HSLColor.fromColor(light).lightness),
      );
    });

    testWidgets('is the neutral outline for an unknown operator', (
      tester,
    ) async {
      final color = await _color(tester, unknownOperator, Brightness.light);

      expect(color.a, lessThan(1));
      final known = await _color(tester, 'NEXCO東日本', Brightness.light);
      expect(color, isNot(known));
    });
  });

  group('segmentRuns', () {
    // Non-const, so that the constructors count as run.
    // ignore: prefer_const_constructors
    final segment = RouteSegmentDTO(
      line: _line(),
      fromIcName: 'a',
      toIcName: 'b',
      fromLatitude: 35.0,
      fromLongitude: 139.0,
      toLatitude: 35.2,
      toLongitude: 139.2,
      via: const [RouteVertexDTO(latitude: 35.1, longitude: 139.1)],
    );

    test('draws a line without parts in one part, through its points', () {
      final runs = segmentRuns(segment);

      expect(runs, hasLength(1));
      expect(runs.single.operator, unknownOperator);
      expect(runs.single.points.map((p) => p.latitude), [35.0, 35.1, 35.2]);
    });

    test('keeps the parts a line has', () {
      final parts = [
        const RouteRunDTO(operator: 'NEXCO東日本', points: []),
        const RouteRunDTO(operator: '首都高速道路', points: []),
      ];
      final withRuns = RouteSegmentDTO(
        line: _line(),
        fromIcName: 'a',
        toIcName: 'b',
        fromLatitude: 35.0,
        fromLongitude: 139.0,
        toLatitude: 35.2,
        toLongitude: 139.2,
        runs: parts,
      );

      expect(segmentRuns(withRuns), same(parts));
    });
  });

  testWidgets('runColor is the main color of the theme when unknown', (
    tester,
  ) async {
    late Color unknown, known;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            unknown = runColor(
              context,
              const RouteRunDTO(operator: unknownOperator, points: []),
              scheme,
            );
            known = runColor(
              context,
              const RouteRunDTO(operator: 'NEXCO中日本', points: []),
              scheme,
            );
            expect(unknown, scheme.primary.withValues(alpha: 0.7));
            return const SizedBox();
          },
        ),
      ),
    );

    expect(known, isNot(unknown));
  });
}
