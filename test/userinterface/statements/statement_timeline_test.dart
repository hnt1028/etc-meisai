import 'package:etc_meisai/application/dto/statement_line_dto.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:etc_meisai/userinterface/statements/statement_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Future<void> _start(WidgetTester tester, FakeStatementLineIF lines) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listStatementLinesUCProvider.overrideWithValue(fakeListUC(lines)),
      ],
      // ignore: prefer_const_constructors
      child: EtcMeisaiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTimeline(WidgetTester tester) async {
  await tester.tap(find.text(StatementListStrings.modeTimeline));
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(StatementListScreen)));

Finder _text(String text) => find.text(text);

/// Lines on 10 January (two of them) and on 12 January (one). 11 January has
/// no line.
FakeStatementLineIF _lines() {
  final lines = FakeStatementLineIF();
  lines.stored.addAll([
    fakeStatementLine(
      exitIc: 'early',
      entranceAt: DateTime(2026, 1, 10, 8, 30),
      exitAt: DateTime(2026, 1, 10, 9, 15),
      vehicleNumber: 1,
      status: ConfirmationStatusValue.pending,
    ),
    fakeStatementLine(
      exitIc: 'long',
      entranceAt: DateTime(2026, 1, 10, 12),
      exitAt: DateTime(2026, 1, 10, 18),
      vehicleNumber: 1,
    ),
    fakeStatementLine(
      exitIc: 'later',
      entranceAt: DateTime(2026, 1, 12, 7),
      exitAt: DateTime(2026, 1, 12, 8),
      vehicleNumber: 2,
    ),
  ]);
  return lines;
}

void main() {
  testWidgets('switches between the list and the timeline', (tester) async {
    await _start(tester, _lines());
    expect(_text('2026/01/12'), findsNothing);

    await _openTimeline(tester);
    expect(_text('2026/01/12'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-bar-0')), findsOneWidget);

    await tester.tap(_text(StatementListStrings.modeList));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timeline-bar-0')), findsNothing);
    expect(_text('A-IC → later'), findsOneWidget);
  });

  testWidgets('keeps the filter and the total in the timeline', (tester) async {
    await _start(tester, _lines());
    _container(
      tester,
    ).read(statementFilterProvider.notifier).setVehicleNumber(2);
    await tester.pumpAndSettle();

    await _openTimeline(tester);

    expect(_text(StatementListStrings.totalFare(1000)), findsOneWidget);
    expect(_text(StatementListStrings.clearFilter), findsOneWidget);
  });

  testWidgets('shows the newest day first, with the lines of that day only', (
    tester,
  ) async {
    await _start(tester, _lines());
    await _openTimeline(tester);

    expect(_text('2026/01/12'), findsOneWidget);
    expect(_text('A-IC → later　1,000円'), findsOneWidget);
    expect(_text('A-IC → early　1,000円'), findsNothing);
    expect(find.byKey(const ValueKey('timeline-row-1')), findsNothing);
  });

  testWidgets('moves between the days that have lines, skipping empty days', (
    tester,
  ) async {
    await _start(tester, _lines());
    await _openTimeline(tester);

    TextButton button(String label) =>
        tester.widget(find.widgetWithText(TextButton, label));
    expect(button(StatementListStrings.nextDay).onPressed, isNull);

    await tester.tap(_text(StatementListStrings.previousDay));
    await tester.pumpAndSettle();
    expect(_text('2026/01/10'), findsOneWidget);
    expect(button(StatementListStrings.previousDay).onPressed, isNull);
    expect(button(StatementListStrings.nextDay).onPressed, isNotNull);

    await tester.tap(_text(StatementListStrings.nextDay));
    await tester.pumpAndSettle();
    expect(_text('2026/01/12'), findsOneWidget);
  });

  testWidgets(
    'lines are in order of their start, with the bar placed by time',
    (tester) async {
      await _start(tester, _lines());
      await _openTimeline(tester);
      await tester.tap(_text(StatementListStrings.previousDay));
      await tester.pumpAndSettle();

      expect(_text('A-IC → early　1,000円'), findsOneWidget);
      final width = tester
          .getSize(find.byKey(const ValueKey('timeline-row-0')))
          .width;
      final first = tester.getRect(
        find.byKey(const ValueKey('timeline-bar-0')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('timeline-bar-1')),
      );
      final row = tester.getTopLeft(
        find.byKey(const ValueKey('timeline-row-0')),
      );

      // 8:30 to 9:15 is 45 minutes of 24 hours.
      expect(first.left - row.dx, closeTo(width * (8.5 / 24), 1));
      expect(first.width, closeTo(width * (0.75 / 24), 1));
      // 12:00 to 18:00 is a quarter of the day, and comes after the first.
      expect(second.left - row.dx, closeTo(width * 0.5, 1));
      expect(second.width, closeTo(width * 0.25, 1));
      expect(first.top, lessThan(second.top));
    },
  );

  testWidgets('draws a pending line with an outline only', (tester) async {
    await _start(tester, _lines());
    await _openTimeline(tester);
    await tester.tap(_text(StatementListStrings.previousDay));
    await tester.pumpAndSettle();

    BoxDecoration decoration(String key) =>
        tester.widget<DecoratedBox>(find.byKey(ValueKey(key))).decoration
            as BoxDecoration;

    expect(decoration('timeline-bar-0').color, isNull);
    expect(decoration('timeline-bar-0').border, isNotNull);
    expect(decoration('timeline-bar-1').color, isNotNull);
    expect(decoration('timeline-bar-1').border, isNull);
  });

  testWidgets('shows a line without an entrance as a small mark at its exit', (
    tester,
  ) async {
    final lines = FakeStatementLineIF();
    lines.stored.add(
      fakeStatementLine(
        exitIc: 'only-exit',
        exitAt: DateTime(2026, 1, 10, 12),
        withoutEntrance: true,
      ),
    );
    await _start(tester, lines);
    await _openTimeline(tester);

    final width = tester
        .getSize(find.byKey(const ValueKey('timeline-row-0')))
        .width;
    final row = tester.getTopLeft(find.byKey(const ValueKey('timeline-row-0')));
    final bar = tester.getRect(find.byKey(const ValueKey('timeline-bar-0')));

    expect(_text('- → only-exit　1,000円'), findsOneWidget);
    expect(bar.width, 6);
    expect(bar.left - row.dx, closeTo(width * 0.5, 1));
  });

  testWidgets('shows only the part of a line that runs over midnight', (
    tester,
  ) async {
    final lines = FakeStatementLineIF();
    lines.stored.add(
      fakeStatementLine(
        exitIc: 'night',
        entranceAt: DateTime(2026, 1, 9, 23),
        exitAt: DateTime(2026, 1, 10, 1),
      ),
    );
    await _start(tester, lines);
    await _openTimeline(tester);

    final width = tester
        .getSize(find.byKey(const ValueKey('timeline-row-0')))
        .width;
    final row = tester.getTopLeft(find.byKey(const ValueKey('timeline-row-0')));
    var bar = tester.getRect(find.byKey(const ValueKey('timeline-bar-0')));

    // On 10 January: from 0:00 to 1:00.
    expect(_text('2026/01/10'), findsOneWidget);
    expect(bar.left - row.dx, closeTo(0, 1));
    expect(bar.width, closeTo(width / 24, 1));

    await tester.tap(_text(StatementListStrings.previousDay));
    await tester.pumpAndSettle();
    bar = tester.getRect(find.byKey(const ValueKey('timeline-bar-0')));

    // On 9 January: from 23:00 to 24:00.
    expect(_text('2026/01/09'), findsOneWidget);
    expect(bar.left - row.dx, closeTo(width * 23 / 24, 1));
    expect(bar.right - row.dx, closeTo(width, 1));
  });

  testWidgets('goes back to the newest day when the chosen day has no line', (
    tester,
  ) async {
    await _start(tester, _lines());
    await _openTimeline(tester);
    await tester.tap(_text(StatementListStrings.previousDay));
    await tester.pumpAndSettle();
    expect(_text('2026/01/10'), findsOneWidget);

    // Only the vehicle 2 line (12 January) is left.
    _container(
      tester,
    ).read(statementFilterProvider.notifier).setVehicleNumber(2);
    await tester.pumpAndSettle();

    expect(_text('2026/01/12'), findsOneWidget);
    expect(_text('A-IC → later　1,000円'), findsOneWidget);
  });

  testWidgets('shows the empty message instead of a timeline', (tester) async {
    await _start(tester, FakeStatementLineIF());
    await _openTimeline(tester);

    expect(_text(StatementListStrings.emptyNoData), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-row-0')), findsNothing);
  });

  testWidgets('opens the detail when a line is tapped', (tester) async {
    await _start(tester, _lines());
    await _openTimeline(tester);

    await tester.tap(find.byKey(const ValueKey('timeline-row-0')));
    await tester.pumpAndSettle();

    expect(_text(StatementDetailStrings.title), findsOneWidget);
    expect(_text('later'), findsOneWidget);
  });

  group('helpers', () {
    StatementLineDTO dto(DateTime? entrance, DateTime exit) => StatementLineDTO(
      entranceAt: entrance,
      exitAt: exit,
      entranceIc: null,
      exitIc: 'x',
      grossFare: null,
      etcDiscount: null,
      fare: 0,
      fareAfterRebate: 0,
      postpaidFare: 0,
      vehicleType: fakeStatementLine().vehicleType,
      vehicleTypeName: '普通車',
      vehicleNumber: 1,
      cardNumberSuffix: '0001',
      status: ConfirmationStatusValue.confirmed,
      discountTypes: const [],
    );

    test('timelineDays lists each day a line touches, oldest first', () {
      final days = timelineDays([
        dto(DateTime(2026, 1, 9, 23), DateTime(2026, 1, 11, 1)),
        dto(null, DateTime(2026, 1, 20, 8)),
      ]);

      expect(days, [
        DateTime(2026, 1, 9),
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 20),
      ]);
    });

    test('spanOfDay clips a line to the day', () {
      final span = spanOfDay(
        dto(DateTime(2026, 1, 9, 12), DateTime(2026, 1, 11, 12)),
        DateTime(2026, 1, 10),
      );

      expect(span.start, 0);
      expect(span.end, 1);
    });
  });
}
