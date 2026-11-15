import 'dart:async';

import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/userinterface/app.dart';
import 'package:etc_meisai/userinterface/common/data_revision.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_controller.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_providers.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_screen.dart';
import 'package:etc_meisai/userinterface/statements/statement_list_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Widget _app(FakeStatementLineIF lines) {
  return ProviderScope(
    overrides: [
      listStatementLinesUCProvider.overrideWithValue(
        ListStatementLinesUC(statementLines: lines),
      ),
    ],
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    child: EtcMeisaiApp(),
  );
}

Future<void> _start(WidgetTester tester, FakeStatementLineIF lines) async {
  await tester.pumpWidget(_app(lines));
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(StatementListScreen)));

Finder _text(String text) => find.text(text);

FakeStatementLineIF _linesOfTwoVehicles() {
  final lines = FakeStatementLineIF();
  lines.stored.addAll([
    fakeStatementLine(
      exitIc: 'X-IC',
      exitAt: DateTime(2026, 1, 11, 9),
      vehicleNumber: 1,
      cardNumber: '0000-****-0001',
      fare: 1000,
    ),
    fakeStatementLine(
      exitIc: 'Y-IC',
      exitAt: DateTime(2026, 1, 12, 9),
      vehicleNumber: 2,
      cardNumber: '0000-****-0002',
      fare: 500,
    ),
  ]);
  return lines;
}

void main() {
  testWidgets('shows the fields of each statement line, newest first', (
    tester,
  ) async {
    await _start(tester, _linesOfTwoVehicles());

    expect(_text(StatementListStrings.title), findsOneWidget);
    expect(_text('A-IC → X-IC'), findsOneWidget);
    expect(_text('2026/01/10 08:30 → 2026/01/11 09:00'), findsOneWidget);
    expect(_text('1,000円'), findsOneWidget);
    expect(_text('500円'), findsOneWidget);
    expect(
      tester.getTopLeft(_text('A-IC → Y-IC')).dy,
      lessThan(tester.getTopLeft(_text('A-IC → X-IC')).dy),
    );
  });

  testWidgets('shows the total and its breakdown', (tester) async {
    final lines = FakeStatementLineIF();
    lines.stored.addAll([
      fakeStatementLine(exitIc: 'a', fare: 1000, fareAfterRebate: 200),
      fakeStatementLine(exitIc: 'b', fare: 500),
    ]);

    await _start(tester, lines);

    expect(_text(StatementListStrings.totalFare(1500)), findsOneWidget);
    expect(
      _text(StatementListStrings.totalBreakdown(200, 1300)),
      findsOneWidget,
    );
  });

  testWidgets('marks only pending lines and shows a blank entrance as -', (
    tester,
  ) async {
    final lines = FakeStatementLineIF();
    lines.stored.addAll([
      fakeStatementLine(
        exitIc: 'p',
        status: ConfirmationStatusValue.pending,
        withoutEntrance: true,
      ),
      fakeStatementLine(exitIc: 'c'),
    ]);

    await _start(tester, lines);

    expect(_text(StatementListStrings.pending), findsOneWidget);
    expect(_text('- → p'), findsOneWidget);
    expect(_text('- → 2026/01/10 09:15'), findsOneWidget);
  });

  testWidgets('says so when nothing is imported, with a total of 0', (
    tester,
  ) async {
    await _start(tester, FakeStatementLineIF());

    expect(_text(StatementListStrings.emptyNoData), findsOneWidget);
    expect(_text(StatementListStrings.totalFare(0)), findsOneWidget);
    expect(_text(StatementListStrings.clearFilter), findsNothing);
  });

  group('filter', () {
    testWidgets('by vehicle number, and clears it', (tester) async {
      await _start(tester, _linesOfTwoVehicles());

      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2').last);
      await tester.pumpAndSettle();

      expect(_text('A-IC → Y-IC'), findsOneWidget);
      expect(_text('A-IC → X-IC'), findsNothing);
      expect(_text(StatementListStrings.totalFare(500)), findsOneWidget);

      await tester.tap(_text(StatementListStrings.clearFilter));
      await tester.pumpAndSettle();

      expect(_text('A-IC → X-IC'), findsOneWidget);
      expect(_text('A-IC → Y-IC'), findsOneWidget);
      expect(_text(StatementListStrings.clearFilter), findsNothing);
    });

    testWidgets('by card number, shown as the last 4 only', (tester) async {
      await _start(tester, _linesOfTwoVehicles());

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      expect(find.textContaining('0000-'), findsNothing);
      await tester.tap(
        _text(StatementListStrings.cardNumberChoice('0001')).last,
      );
      await tester.pumpAndSettle();

      expect(_text('A-IC → X-IC'), findsOneWidget);
      expect(_text('A-IC → Y-IC'), findsNothing);
    });

    testWidgets('keeps the choices when the filter leaves one line', (
      tester,
    ) async {
      await _start(tester, _linesOfTwoVehicles());
      _container(tester).read(statementFilterProvider.notifier)
        ..setVehicleNumber(1)
        ..setCardNumberSuffix('0001');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();

      expect(_text('2'), findsOneWidget);
    });

    testWidgets('by period, shown on the button', (tester) async {
      await _start(tester, _linesOfTwoVehicles());
      expect(
        _text(
          '${StatementListStrings.periodLabel}: ${StatementListStrings.periodNone}',
        ),
        findsOneWidget,
      );

      _container(tester)
          .read(statementFilterProvider.notifier)
          .setPeriod(DateTime(2026, 1, 12), DateTime(2026, 1, 12));
      await tester.pumpAndSettle();

      expect(_text('A-IC → Y-IC'), findsOneWidget);
      expect(_text('A-IC → X-IC'), findsNothing);
      expect(
        _text('${StatementListStrings.periodLabel}: 2026/01/12 〜 2026/01/12'),
        findsOneWidget,
      );
    });

    testWidgets('says so when the filter leaves nothing', (tester) async {
      await _start(tester, _linesOfTwoVehicles());

      _container(tester)
          .read(statementFilterProvider.notifier)
          .setPeriod(DateTime(2030, 1, 1), DateTime(2030, 1, 2));
      await tester.pumpAndSettle();

      expect(_text(StatementListStrings.emptyNoMatch), findsOneWidget);
      expect(_text(StatementListStrings.emptyNoData), findsNothing);
      expect(_text(StatementListStrings.totalFare(0)), findsOneWidget);
    });

    testWidgets('picks a period with the date range picker', (tester) async {
      final now = DateTime.now();
      final lines = FakeStatementLineIF();
      lines.stored.addAll([
        fakeStatementLine(
          exitIc: 'in',
          exitAt: DateTime(now.year, now.month, 11, 9),
        ),
        fakeStatementLine(
          exitIc: 'out',
          exitAt: DateTime(now.year, now.month, 20, 9),
        ),
      ]);
      await _start(tester, lines);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_text('A-IC → in'), findsOneWidget);
      expect(_text('A-IC → out'), findsNothing);
    });

    testWidgets('keeps the period when the picker is cancelled', (
      tester,
    ) async {
      await _start(tester, _linesOfTwoVehicles());
      _container(tester)
          .read(statementFilterProvider.notifier)
          .setPeriod(DateTime(2026, 1, 12), DateTime(2026, 1, 12));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        _text('${StatementListStrings.periodLabel}: 2026/01/12 〜 2026/01/12'),
        findsOneWidget,
      );
    });
  });

  testWidgets('shows a progress indicator while reading', (tester) async {
    final gate = Completer<void>();
    final lines = _linesOfTwoVehicles()..readGate = gate.future;
    await tester.pumpWidget(_app(lines));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_text('A-IC → X-IC'), findsOneWidget);
  });

  testWidgets('reads again when the stored data changes, keeping the list', (
    tester,
  ) async {
    final lines = _linesOfTwoVehicles();
    await _start(tester, lines);
    expect(lines.readCount, 1);

    final gate = Completer<void>();
    lines.readGate = gate.future;
    lines.stored.add(fakeStatementLine(exitIc: 'Z-IC'));
    _container(tester).read(dataRevisionProvider.notifier).changed();
    await tester.pump();
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_text('A-IC → X-IC'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(lines.readCount, 2);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(_text('A-IC → Z-IC'), findsOneWidget);
  });

  testWidgets('shows a failure without details, and reads again on request', (
    tester,
  ) async {
    final lines = _linesOfTwoVehicles()..readError = StateError('secret');
    await _start(tester, lines);

    expect(_text(StatementListStrings.loadFailed), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);

    lines.readError = null;
    await tester.tap(_text(StatementListStrings.retry));
    await tester.pumpAndSettle();

    expect(_text(StatementListStrings.loadFailed), findsNothing);
    expect(_text('A-IC → X-IC'), findsOneWidget);
  });

  test('the use case must be overridden', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    expect(() => c.read(listStatementLinesUCProvider), throwsA(anything));
  });
}
