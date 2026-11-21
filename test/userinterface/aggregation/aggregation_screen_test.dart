import 'dart:async';

import 'package:etc_meisai/application/dto/route_coverage_row_dto.dart';
import 'package:etc_meisai/domain/entity/ic_link_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_pie.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_providers.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_screen.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_strings.dart';
import 'package:etc_meisai/userinterface/aggregation/aggregation_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

FakeIcMasterIF _master() => FakeIcMasterIF(
  [
    fakeIcPoint(name: '北', routeNames: const ['東名高速道路']),
    fakeIcPoint(name: '東', routeNames: const ['東名高速道路']),
  ],
  // 北 and 東 are 3 km apart along the road.
  links: const [IcLinkEntity(fromId: 'id-北', toId: 'id-東', meters: 3000)],
);

/// January: 1,000 yen (2 times, with a 240 yen discount) and 500 yen.
/// February: 250 yen.
List<StatementLineEntity> _lines() => [
  fakeStatementLine(
    entranceIc: '北',
    exitIc: '東',
    fare: 1000,
    etcDiscount: -240,
    discountTypes: const ['深夜割引'],
    exitAt: DateTime(2026, 1, 10, 8, 30),
  ),
  fakeStatementLine(
    entranceIc: '北',
    exitIc: '東',
    fare: 500,
    exitAt: DateTime(2026, 1, 17, 9),
  ),
  fakeStatementLine(
    entranceIc: '北',
    exitIc: '東',
    fare: 250,
    exitAt: DateTime(2026, 2, 3, 20),
  ),
];

class _SlowLines extends FakeStatementLineIF {
  final done = Completer<void>();

  @override
  Future<List<StatementLineEntity>> findAll() async {
    await done.future;
    return super.findAll();
  }
}

Future<void> _show(
  WidgetTester tester, {
  List<StatementLineEntity>? lines,
  FakeStatementLineIF? source,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = source ?? (FakeStatementLineIF()..stored.addAll(lines ?? []));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aggregateStatementsUCProvider.overrideWithValue(
          fakeAggregateUC(store, master: _master()),
        ),
      ],
      // ignore: prefer_const_constructors
      child: MaterialApp(home: AggregationScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

PieChartData _pie(WidgetTester tester) =>
    tester.widget<PieChart>(find.byType(PieChart)).data;

double _bar(WidgetTester tester, int index) => tester
    .widget<FractionallySizedBox>(find.byKey(ValueKey('bar-$index')))
    .widthFactor!;

void main() {
  testWidgets('shows the totals and the months as a table at first', (
    tester,
  ) async {
    await _show(tester, lines: _lines());

    expect(
      find.text(AggregationStrings.summary(3, 1750, 240, 9000)),
      findsOneWidget,
    );
    // The month is the first unit. Newest first.
    expect(find.text('2026/02'), findsOneWidget);
    expect(find.text('2026/01'), findsOneWidget);
    // A row gives the count, the fare and the discount.
    expect(find.text('2回'), findsOneWidget);
    expect(find.text('1,500円'), findsOneWidget);
    expect(find.text('240円'), findsOneWidget);
    expect(find.text('250円'), findsOneWidget);
    expect(find.text('0円'), findsOneWidget);
  });

  testWidgets('shows the distance in the table, with a note', (tester) async {
    await _show(tester, lines: _lines());

    // January has two lines of 3 km, February one.
    expect(find.text('6.0km'), findsOneWidget);
    expect(find.text('3.0km'), findsOneWidget);
    expect(find.text(AggregationStrings.distanceNote), findsOneWidget);
    // Every line has a distance.
    expect(find.textContaining('距離が分からない'), findsNothing);

    // The note is only where a distance is.
    await _tap(tester, AggregationStrings.kind(AggregationKind.route));
    expect(find.text(AggregationStrings.distanceNote), findsNothing);
    await _tap(tester, AggregationStrings.kind(AggregationKind.discount));
    expect(find.text(AggregationStrings.distanceNote), findsNothing);
    await _tap(tester, AggregationStrings.kind(AggregationKind.operator));
    expect(find.text('9.0km'), findsOneWidget);
    expect(find.text(AggregationStrings.distanceNote), findsOneWidget);
    await _tap(tester, AggregationStrings.kind(AggregationKind.hour));
    expect(find.text(AggregationStrings.distanceNote), findsOneWidget);
  });

  testWidgets('aggregates by tag, with a row for the lines without one', (
    tester,
  ) async {
    await _show(
      tester,
      lines: [
        fakeStatementLine(fare: 1000, tags: const ['仕事', '東京']),
        fakeStatementLine(
          fare: 500,
          exitAt: DateTime(2026, 1, 11, 9),
          tags: const ['私用'],
        ),
        fakeStatementLine(fare: 200, exitAt: DateTime(2026, 1, 12, 9)),
      ],
    );

    await _tap(tester, AggregationStrings.kind(AggregationKind.tag));

    // A line with two tags counts for both.
    expect(find.text('仕事'), findsOneWidget);
    expect(find.text('東京'), findsOneWidget);
    expect(find.text('私用'), findsOneWidget);
    expect(find.text('タグなし'), findsOneWidget);
    expect(find.text(AggregationStrings.tagNote), findsOneWidget);
    expect(find.text('1,000円'), findsNWidgets(2));
    expect(find.text('500円'), findsOneWidget);
    expect(find.text('200円'), findsOneWidget);
  });

  testWidgets('shows how much of each road was driven', (tester) async {
    await _show(tester, lines: _lines());

    await _tap(tester, AggregationStrings.kind(AggregationKind.coverage));

    expect(find.text(AggregationStrings.coverageSummary(1, 1)), findsOneWidget);
    expect(find.text(AggregationStrings.coverageNote), findsOneWidget);
    // 北 - 東 is all of 東名高速道路.
    expect(find.byKey(const ValueKey('coverage-東名高速道路')), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('3.0km / 3.0km'), findsOneWidget);
    // There is no table or graph for it.
    expect(
      find.text(AggregationStrings.display(AggregationDisplay.graph)),
      findsNothing,
    );
  });

  testWidgets('says so when no road was driven', (tester) async {
    // The ICs are not in the master.
    await _show(
      tester,
      lines: [fakeStatementLine(entranceIc: 'X', exitIc: 'Y')],
    );

    await _tap(tester, AggregationStrings.kind(AggregationKind.coverage));

    expect(find.text(AggregationStrings.coverageSummary(0, 1)), findsOneWidget);
    expect(find.text(AggregationStrings.coverageNone), findsOneWidget);
  });

  test('the share of a road is in tenths of a percent, rounded down', () {
    RouteCoverageRowDTO row(int driven, int total) => RouteCoverageRowDTO(
      routeName: 'R',
      totalMeters: total,
      drivenMeters: driven,
    );

    expect(coverageTenths(row(1, 3)), 333);
    expect(coverageTenths(row(3, 3)), 1000);
    expect(coverageTenths(row(0, 0)), 0);
    expect(AggregationStrings.coveragePercent(333), '33.3%');
    expect(AggregationStrings.coveragePercent(1000), '100.0%');
    expect(AggregationStrings.coveragePercent(5), '0.5%');
  });

  testWidgets('draws the distance as bars and as a pie', (tester) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    // A graph of the fare has no note.
    expect(find.text(AggregationStrings.distanceNote), findsNothing);

    await _tap(tester, AggregationStrings.metric(AggregationMetric.distance));
    // February 3 km, January 6 km.
    expect(_bar(tester, 0), 0.5);
    expect(_bar(tester, 1), 1);
    expect(find.text('3.0km'), findsOneWidget);
    expect(find.text(AggregationStrings.distanceNote), findsOneWidget);

    await _tap(tester, AggregationStrings.kind(AggregationKind.operator));
    expect(_pie(tester).sections.single.value, 9000);
    expect(find.text('9.0km'), findsOneWidget);
  });

  testWidgets('says how many lines have no distance', (tester) async {
    // The entrance A-IC and the exit B-IC are not in the master.
    await _show(
      tester,
      lines: [
        fakeStatementLine(fare: 100),
        fakeStatementLine(fare: 200, exitAt: DateTime(2026, 1, 11)),
        fakeStatementLine(
          entranceIc: '北',
          exitIc: '東',
          fare: 300,
          exitAt: DateTime(2026, 1, 12),
        ),
      ],
    );

    expect(
      find.text(AggregationStrings.summary(3, 600, 0, 3000)),
      findsOneWidget,
    );
    expect(find.text(AggregationStrings.distanceUnknown(2)), findsOneWidget);
  });

  testWidgets('switches the unit of the period', (tester) async {
    await _show(tester, lines: _lines());

    await _tap(tester, AggregationStrings.unit(AggregationUnit.week));
    // 2026-01-10 is a Saturday, 2026-01-17 too, 2026-02-03 a Tuesday.
    expect(find.text('2026/02/02〜'), findsOneWidget);
    expect(find.text('2026/01/12〜'), findsOneWidget);
    expect(find.text('2026/01/05〜'), findsOneWidget);

    await _tap(tester, AggregationStrings.unit(AggregationUnit.year));
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('1,750円'), findsOneWidget);
  });

  testWidgets('shows the other kinds, and the note of the operator', (
    tester,
  ) async {
    await _show(tester, lines: _lines());
    expect(find.text(AggregationStrings.operatorNote), findsNothing);
    // The unit buttons are for the period only.
    expect(
      find.text(AggregationStrings.unit(AggregationUnit.week)),
      findsOneWidget,
    );

    await _tap(tester, AggregationStrings.kind(AggregationKind.operator));
    expect(find.text('NEXCO中日本'), findsOneWidget);
    expect(find.text(AggregationStrings.operatorNote), findsOneWidget);
    expect(
      find.text(AggregationStrings.unit(AggregationUnit.week)),
      findsNothing,
    );

    await _tap(tester, AggregationStrings.kind(AggregationKind.route));
    expect(find.text('東名高速道路'), findsOneWidget);
    expect(find.text('3回'), findsOneWidget);
    expect(find.text(AggregationStrings.operatorNote), findsNothing);

    await _tap(tester, AggregationStrings.kind(AggregationKind.ic));
    expect(find.text('北'), findsOneWidget);
    expect(find.text('東'), findsOneWidget);

    await _tap(tester, AggregationStrings.kind(AggregationKind.hour));
    expect(find.text('8時'), findsOneWidget);
    expect(find.text('23時'), findsOneWidget);
    expect(find.text('0時'), findsOneWidget);

    await _tap(tester, AggregationStrings.kind(AggregationKind.discount));
    expect(find.text('深夜割引'), findsOneWidget);
    expect(find.text('1回'), findsOneWidget);
    expect(find.text('240円'), findsOneWidget);
  });

  testWidgets('draws bars as long as the value, switching the value', (
    tester,
  ) async {
    await _show(tester, lines: _lines());

    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    // Newest first: February 250 yen, then January 1,500 yen (the longest).
    expect(_bar(tester, 0), closeTo(250 / 1500, 0.0001));
    expect(_bar(tester, 1), 1);

    await _tap(tester, AggregationStrings.metric(AggregationMetric.count));
    // By count: February once, January 2 times.
    expect(_bar(tester, 0), 0.5);
    expect(_bar(tester, 1), 1);

    await _tap(tester, AggregationStrings.metric(AggregationMetric.discount));
    // By discount: February none, January 240 yen.
    expect(_bar(tester, 0), 0);
    expect(_bar(tester, 1), 1);

    await _tap(tester, AggregationStrings.display(AggregationDisplay.table));
    expect(find.byKey(const ValueKey('bar-0')), findsNothing);
  });

  testWidgets('draws no bar when the largest value is 0', (tester) async {
    await _show(tester, lines: [fakeStatementLine(fare: 100)]);

    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    await _tap(tester, AggregationStrings.metric(AggregationMetric.discount));

    expect(_bar(tester, 0), 0);
  });

  testWidgets('offers only the values the kind gives', (tester) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    expect(
      find.text(AggregationStrings.metric(AggregationMetric.fare)),
      findsOneWidget,
    );

    // A route has only a count, so there is nothing to choose.
    await _tap(tester, AggregationStrings.kind(AggregationKind.route));
    expect(
      find.text(AggregationStrings.metric(AggregationMetric.fare)),
      findsNothing,
    );
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('3回'), findsOneWidget);

    // A discount type has a count and a discount, not a fare.
    await _tap(tester, AggregationStrings.kind(AggregationKind.discount));
    expect(
      find.text(AggregationStrings.metric(AggregationMetric.fare)),
      findsNothing,
    );
    expect(
      find.text(AggregationStrings.metric(AggregationMetric.discount)),
      findsOneWidget,
    );
  });

  testWidgets('keeps the value when the next kind gives it', (tester) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    await _tap(tester, AggregationStrings.metric(AggregationMetric.discount));

    await _tap(tester, AggregationStrings.kind(AggregationKind.discount));
    // The discount is still chosen: the pie shows the 240 yen of 深夜割引.
    expect(_pie(tester).sections.single.value, 240);
    expect(find.text('240円'), findsOneWidget);
  });

  testWidgets('draws bars for the period and the hour, pies for the rest', (
    tester,
  ) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));

    expect(find.byKey(const ValueKey('bar-0')), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);

    await _tap(tester, AggregationStrings.kind(AggregationKind.hour));
    expect(find.byKey(const ValueKey('bar-23')), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);

    for (final kind in [
      AggregationKind.operator,
      AggregationKind.route,
      AggregationKind.ic,
      AggregationKind.discount,
    ]) {
      await _tap(tester, AggregationStrings.kind(kind));
      expect(find.byType(PieChart), findsOneWidget, reason: '$kind');
      expect(
        find.byKey(const ValueKey('bar-0')),
        findsNothing,
        reason: '$kind',
      );
    }
  });

  testWidgets('shows the share of each slice in the legend', (tester) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    await _tap(tester, AggregationStrings.kind(AggregationKind.ic));

    // 北 and 東 are on all three lines: 3 and 3 of 6.
    expect(_pie(tester).sections.map((s) => s.value), [3, 3]);
    expect(find.text('50.0%'), findsNWidgets(2));
    expect(find.text('3回'), findsNWidgets(2));
    expect(find.text('北'), findsOneWidget);
  });

  testWidgets('switches the value of the pie', (tester) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    await _tap(tester, AggregationStrings.kind(AggregationKind.operator));

    // One operator (NEXCO中日本) takes everything, whatever the value is.
    expect(_pie(tester).sections.single.value, 1750);
    expect(find.text('100.0%'), findsOneWidget);
    await _tap(tester, AggregationStrings.metric(AggregationMetric.count));
    expect(_pie(tester).sections.single.value, 3);
    await _tap(tester, AggregationStrings.metric(AggregationMetric.discount));
    expect(_pie(tester).sections.single.value, 240);
  });

  testWidgets(
    'leaves a row with 0 out of the pie, and says so when all are 0',
    (tester) async {
      await _show(tester, lines: [fakeStatementLine(fare: 100)]);
      await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
      await _tap(tester, AggregationStrings.kind(AggregationKind.operator));
      expect(_pie(tester).sections, hasLength(1));

      // The line has no discount.
      await _tap(tester, AggregationStrings.metric(AggregationMetric.discount));
      expect(find.byType(PieChart), findsNothing);
      expect(find.text(AggregationStrings.noPieValues), findsOneWidget);
    },
  );

  testWidgets('gathers the routes and ICs outside the top 10 into the rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Twelve ICs, each on its own route, with one line each.
    final store = FakeStatementLineIF()
      ..stored.addAll([
        for (var i = 0; i < 12; i++)
          fakeStatementLine(
            entranceIc: 'P$i',
            exitIc: 'P$i',
            exitAt: DateTime(2026, 1, 10, i),
          ),
      ]);
    final master = FakeIcMasterIF([
      for (var i = 0; i < 12; i++)
        fakeIcPoint(
          name: 'P$i',
          routeNames: ['R${i.toString().padLeft(2, '0')}'],
        ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aggregateStatementsUCProvider.overrideWithValue(
            fakeAggregateUC(store, master: master),
          ),
        ],
        child: const MaterialApp(home: AggregationScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));

    await _tap(tester, AggregationStrings.kind(AggregationKind.route));
    // Ten routes and the rest (two routes, one line each).
    expect(_pie(tester).sections, hasLength(11));
    expect(_pie(tester).sections.last.value, 2);
    expect(find.text(AggregationStrings.other), findsOneWidget);
    expect(find.text('16.7%'), findsOneWidget);

    await _tap(tester, AggregationStrings.kind(AggregationKind.ic));
    expect(_pie(tester).sections, hasLength(11));
    expect(find.text(AggregationStrings.other), findsOneWidget);
  });

  testWidgets('colors the slices from the theme, the rest in grey', (
    tester,
  ) async {
    await _show(tester, lines: _lines());
    await _tap(tester, AggregationStrings.display(AggregationDisplay.graph));
    await _tap(tester, AggregationStrings.kind(AggregationKind.ic));

    final scheme = Theme.of(tester.element(find.byType(PieChart))).colorScheme;
    final colors = _pie(tester).sections.map((s) => s.color).toList();
    expect(colors[0], HSLColor.fromColor(scheme.primary).toColor());
    expect(colors[1], isNot(colors[0]));
    expect(
      AggregationPie.colorsOf(scheme, const [
        PieSlice('a', 1),
        PieSlice('b', 1, isOther: true),
      ]).last,
      scheme.outline,
    );
  });

  testWidgets('says so when there are no statement lines', (tester) async {
    await _show(tester, lines: []);

    expect(find.text(StatementListStrings.emptyNoData), findsOneWidget);
    expect(find.textContaining('回数'), findsNothing);
    expect(
      find.text(AggregationStrings.kind(AggregationKind.period)),
      findsNothing,
    );
  });

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(AggregationScreen)));

  testWidgets('filters with the controls shared with the statement list', (
    tester,
  ) async {
    await _show(
      tester,
      lines: [
        fakeStatementLine(fare: 100, vehicleNumber: 1),
        fakeStatementLine(
          fare: 700,
          vehicleNumber: 2,
          exitAt: DateTime(2026, 1, 11),
        ),
      ],
    );
    expect(find.text(AggregationStrings.summary(2, 800, 0, 0)), findsOneWidget);
    // The filter starts closed.
    expect(find.text(StatementListStrings.vehicleNumberLabel), findsNothing);

    await _tap(tester, AggregationStrings.filterTitle);
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    expect(find.text(AggregationStrings.summary(1, 700, 0, 0)), findsOneWidget);
    expect(container(tester).read(statementFilterProvider).vehicleNumber, 2);
  });

  testWidgets('says so when the filter leaves nothing', (tester) async {
    await _show(tester, lines: _lines());

    container(tester)
        .read(statementFilterProvider.notifier)
        .setPeriod(DateTime(2030, 1, 1), DateTime(2030, 1, 2));
    await tester.pumpAndSettle();

    expect(find.text(StatementListStrings.emptyNoMatch), findsOneWidget);
    expect(find.textContaining('回数'), findsNothing);
  });

  testWidgets('shows a progress indicator while reading', (tester) async {
    final lines = _SlowLines();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aggregateStatementsUCProvider.overrideWithValue(
            fakeAggregateUC(lines),
          ),
        ],
        child: const MaterialApp(home: AggregationScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    lines.done.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a failure without details, and reads again on request', (
    tester,
  ) async {
    final lines = FakeStatementLineIF()
      ..stored.addAll(_lines())
      ..readError = StateError('secret details');
    await _show(tester, source: lines);

    expect(find.text(AggregationStrings.loadFailed), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);

    lines.readError = null;
    await _tap(tester, AggregationStrings.retry);
    expect(
      find.text(AggregationStrings.summary(3, 1750, 240, 9000)),
      findsOneWidget,
    );
  });

  testWidgets('the use case must be overridden', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AggregationScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text(AggregationStrings.loadFailed), findsOneWidget);
  });
}
