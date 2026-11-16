import 'package:etc_meisai/application/dto/aggregation_row_dto.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

FakeIcMasterIF _master() => FakeIcMasterIF([
  fakeIcPoint(name: '北', routeNames: const ['東名高速道路']),
  fakeIcPoint(name: '東', routeNames: const ['東名高速道路']),
  fakeIcPoint(name: '西', routeNames: const ['山陽自動車道']),
  fakeIcPoint(name: '街', routeNames: const ['首都高速4号新宿線']),
]);

FakeStatementLineIF _lines(List<StatementLineEntity> lines) =>
    FakeStatementLineIF()..stored.addAll(lines);

Map<String, int?> _fares(List<AggregationRowDTO> rows) => {
  for (final r in rows) r.label: r.fare,
};

void main() {
  group('AggregateStatementsUC', () {
    test('is empty when nothing is stored', () async {
      final result = await fakeAggregateUC(FakeStatementLineIF()).execute();

      expect(result.summary.lineCount, 0);
      expect(result.summary.fareTotal, 0);
      expect(result.summary.discountTotal, 0);
      expect(result.weeks, isEmpty);
      expect(result.months, isEmpty);
      expect(result.years, isEmpty);
      expect(result.operators, isEmpty);
      expect(result.routes, isEmpty);
      expect(result.ics, isEmpty);
      expect(result.discountTypes, isEmpty);
      // Every hour is listed, even with nothing.
      expect(result.hours, hasLength(24));
      expect(result.hours.every((h) => h.count == 0 && h.fare == 0), isTrue);
    });

    test('totals the count, the fare and the discount as a positive', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(fare: 1000, etcDiscount: -240),
          fakeStatementLine(
            fare: 500,
            etcDiscount: -60,
            exitAt: DateTime(2026, 1, 11, 9),
          ),
          // A blank discount (no discount) is 0.
          fakeStatementLine(fare: 300, exitAt: DateTime(2026, 1, 12, 9)),
        ]),
      );

      final summary = (await uc.execute()).summary;

      expect(summary.lineCount, 3);
      expect(summary.fareTotal, 1800);
      expect(summary.discountTotal, 300);
    });

    test(
      'groups by week (from Monday), month and year, newest first',
      () async {
        // 2026-01-04 is a Sunday, 2026-01-05 a Monday, 2026-02-01 a Sunday.
        final uc = fakeAggregateUC(
          _lines([
            fakeStatementLine(fare: 100, exitAt: DateTime(2026, 1, 4, 23, 59)),
            fakeStatementLine(fare: 200, exitAt: DateTime(2026, 1, 5, 0, 0)),
            fakeStatementLine(
              fare: 300,
              exitAt: DateTime(2026, 1, 11, 12),
              etcDiscount: -50,
            ),
            fakeStatementLine(fare: 400, exitAt: DateTime(2026, 2, 1, 12)),
            fakeStatementLine(fare: 500, exitAt: DateTime(2025, 12, 31, 12)),
          ]),
        );

        final result = await uc.execute();

        expect(result.weeks.map((r) => r.label), [
          '2026/01/26',
          '2026/01/05',
          '2025/12/29',
        ]);
        expect(_fares(result.weeks), {
          '2026/01/26': 400,
          '2026/01/05': 500,
          '2025/12/29': 600,
        });
        expect(result.months.map((r) => r.label), [
          '2026/02',
          '2026/01',
          '2025/12',
        ]);
        expect(_fares(result.months), {
          '2026/02': 400,
          '2026/01': 600,
          '2025/12': 500,
        });
        expect(result.years.map((r) => r.label), ['2026', '2025']);
        expect(result.years.first.count, 4);
        expect(result.years.first.discount, 50);
      },
    );

    test('groups by the hour of the exit', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(fare: 100, exitAt: DateTime(2026, 1, 10, 8, 5)),
          fakeStatementLine(fare: 200, exitAt: DateTime(2026, 1, 11, 8, 59)),
          fakeStatementLine(fare: 300, exitAt: DateTime(2026, 1, 12, 23, 0)),
        ]),
      );

      final hours = (await uc.execute()).hours;

      expect(hours.map((h) => h.label), [for (var i = 0; i < 24; i++) '$i']);
      expect(hours[8].count, 2);
      expect(hours[8].fare, 300);
      expect(hours[23].count, 1);
      expect(hours[0].count, 0);
    });

    test('groups by operator, putting the larger fare first', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(entranceIc: '北', exitIc: '東', fare: 500),
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '西',
            fare: 3000,
            exitAt: DateTime(2026, 1, 11),
          ),
          fakeStatementLine(
            entranceIc: '街',
            exitIc: '北',
            fare: 700,
            exitAt: DateTime(2026, 1, 12),
          ),
          fakeStatementLine(
            entranceIc: '不明1',
            exitIc: '不明2',
            fare: 100,
            exitAt: DateTime(2026, 1, 13),
          ),
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '東',
            fare: 400,
            exitAt: DateTime(2026, 1, 14),
          ),
        ]),
        master: _master(),
      );

      final operators = (await uc.execute()).operators;

      // 北→西 shares no route, so it has the routes of both: two operators.
      expect(operators.map((r) => r.label), ['複数の事業者', 'NEXCO中日本', '不明']);
      expect(_fares(operators), {'複数の事業者': 3700, 'NEXCO中日本': 900, '不明': 100});
      expect(operators.first.count, 2);
    });

    test('takes the operator of the exit when the entrance is blank', () async {
      final uc = fakeAggregateUC(
        _lines([fakeStatementLine(exitIc: '西', withoutEntrance: true)]),
        master: _master(),
      );

      expect((await uc.execute()).operators.single.label, 'NEXCO西日本');
    });

    test('lists the top 10 routes and ICs, by count then name', () async {
      final lines = <StatementLineEntity>[];
      // 12 exit ICs, I00 to I11; I05 is used 3 times, the others once.
      for (var i = 0; i < 12; i++) {
        final name = 'I${i.toString().padLeft(2, '0')}';
        for (var n = 0; n < (i == 5 ? 3 : 1); n++) {
          lines.add(
            fakeStatementLine(
              entranceIc: 'X',
              exitIc: name,
              exitAt: DateTime(2026, 1, 10, i, n),
            ),
          );
        }
      }
      final uc = fakeAggregateUC(_lines(lines));

      final ics = (await uc.execute()).ics;

      expect(ics, hasLength(10));
      // The entrance X is on all 14 lines, then I05 (3 lines), then the ones
      // used once, by name.
      expect(ics.take(4).map((r) => '${r.label}:${r.count}'), [
        'X:14',
        'I05:3',
        'I00:1',
        'I01:1',
      ]);
    });

    test('counts an IC once for a line, and skips a blank entrance', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(entranceIc: '北', exitIc: '北'),
          fakeStatementLine(
            exitIc: '東',
            withoutEntrance: true,
            exitAt: DateTime(2026, 1, 11),
          ),
        ]),
      );

      final ics = (await uc.execute()).ics;

      expect(ics.map((r) => '${r.label}:${r.count}'), ['北:1', '東:1']);
      expect(ics.every((r) => r.fare == null && r.discount == null), isTrue);
    });

    test('counts each route of a line, without a fare', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(entranceIc: '北', exitIc: '東'),
          fakeStatementLine(
            entranceIc: '北',
            exitIc: '西',
            exitAt: DateTime(2026, 1, 11),
          ),
          fakeStatementLine(exitIc: '不明', exitAt: DateTime(2026, 1, 12)),
        ]),
        master: _master(),
      );

      final routes = (await uc.execute()).routes;

      // 北→西 has the routes of both ICs; the unknown line has none.
      expect(routes.map((r) => '${r.label}:${r.count}'), [
        '東名高速道路:2',
        '山陽自動車道:1',
      ]);
      expect(routes.every((r) => r.fare == null && r.discount == null), isTrue);
    });

    test('groups by discount type, with the discount only', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(
            etcDiscount: -100,
            discountTypes: const ['深夜割引', '休日割引'],
          ),
          fakeStatementLine(
            etcDiscount: -50,
            discountTypes: const ['深夜割引', '深夜割引'],
            exitAt: DateTime(2026, 1, 11),
          ),
          fakeStatementLine(exitAt: DateTime(2026, 1, 12)),
        ]),
      );

      final types = (await uc.execute()).discountTypes;

      expect(types.map((r) => '${r.label}:${r.count}:${r.discount}'), [
        '深夜割引:2:150',
        '休日割引:1:100',
      ]);
      expect(types.every((r) => r.fare == null), isTrue);
    });

    test('filters like the statement list, keeping the choices', () async {
      final uc = fakeAggregateUC(
        _lines([
          fakeStatementLine(
            fare: 100,
            vehicleNumber: 1,
            cardNumber: '0000-****-0001',
            exitAt: DateTime(2026, 1, 10, 9),
          ),
          fakeStatementLine(
            fare: 200,
            vehicleNumber: 2,
            cardNumber: '0000-****-0002',
            exitAt: DateTime(2026, 2, 10, 9),
          ),
        ]),
      );

      final byPeriod = await uc.execute(
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
      );
      final byVehicle = await uc.execute(vehicleNumber: 1);
      final byCard = await uc.execute(cardNumberSuffix: '0002');

      expect(byPeriod.summary.fareTotal, 200);
      expect(byVehicle.summary.fareTotal, 100);
      expect(byCard.summary.lineCount, 1);
      expect(byPeriod.vehicleNumberChoices, [1, 2]);
      expect(byPeriod.cardNumberChoices, ['0001', '0002']);
    });

    test('passes on a failure to read', () {
      final lines = FakeStatementLineIF()..readError = StateError('x');

      expect(fakeAggregateUC(lines).execute(), throwsStateError);
    });
  });
}
