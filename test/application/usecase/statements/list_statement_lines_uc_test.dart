import 'package:etc_meisai/application/usecase/statements/list_statement_lines_uc.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

ListStatementLinesUC _uc(FakeStatementLineIF lines) => fakeListUC(lines);

Future<FakeStatementLineIF> _stored(List<dynamic> entities) async {
  final lines = FakeStatementLineIF();
  for (final e in entities) {
    lines.stored.add(e);
  }
  return lines;
}

void main() {
  test('returns an empty result when nothing is stored', () async {
    final result = await _uc(FakeStatementLineIF()).execute();

    expect(result.lines, isEmpty);
    expect(result.totalFare, 0);
    expect(result.totalFareAfterRebate, 0);
    expect(result.totalPostpaidFare, 0);
    expect(result.vehicleNumberChoices, isEmpty);
    expect(result.cardNumberChoices, isEmpty);
  });

  test(
    'sorts the newest exit first and keeps the stored order of ties',
    () async {
      final lines = await _stored([
        fakeStatementLine(exitIc: 'old', exitAt: DateTime(2026, 1, 1, 9)),
        fakeStatementLine(exitIc: 'tie1', exitAt: DateTime(2026, 1, 3, 9)),
        fakeStatementLine(exitIc: 'new', exitAt: DateTime(2026, 1, 5, 9)),
        fakeStatementLine(exitIc: 'tie2', exitAt: DateTime(2026, 1, 3, 9)),
      ]);

      final result = await _uc(lines).execute();

      expect(result.lines.map((l) => l.exitIc), ['new', 'tie1', 'tie2', 'old']);
    },
  );

  group('period', () {
    Future<FakeStatementLineIF> lines() => _stored([
      fakeStatementLine(exitIc: 'before', exitAt: DateTime(2026, 1, 9, 23, 59)),
      fakeStatementLine(exitIc: 'first', exitAt: DateTime(2026, 1, 10, 0, 0)),
      fakeStatementLine(exitIc: 'last', exitAt: DateTime(2026, 1, 12, 23, 59)),
      fakeStatementLine(exitIc: 'after', exitAt: DateTime(2026, 1, 13, 0, 0)),
    ]);

    test('includes the first and the last day, whatever the time', () async {
      final result = await _uc(
        await lines(),
      ).execute(from: DateTime(2026, 1, 10, 18), to: DateTime(2026, 1, 12, 6));

      expect(result.lines.map((l) => l.exitIc), ['last', 'first']);
    });

    test('works with only a start day', () async {
      final result = await _uc(
        await lines(),
      ).execute(from: DateTime(2026, 1, 12));

      expect(result.lines.map((l) => l.exitIc), ['after', 'last']);
    });

    test('works with only an end day', () async {
      final result = await _uc(
        await lines(),
      ).execute(to: DateTime(2026, 1, 10));

      expect(result.lines.map((l) => l.exitIc), ['first', 'before']);
    });
  });

  test('filters by vehicle number and by the last 4 of the card', () async {
    final lines = await _stored([
      fakeStatementLine(
        exitIc: 'a',
        vehicleNumber: 1,
        cardNumber: '0000-****-0001',
      ),
      fakeStatementLine(
        exitIc: 'b',
        vehicleNumber: 2,
        cardNumber: '0000-****-0001',
      ),
      fakeStatementLine(
        exitIc: 'c',
        vehicleNumber: 1,
        cardNumber: '0000-****-0002',
      ),
    ]);

    final byVehicle = await _uc(lines).execute(vehicleNumber: 1);
    final byCard = await _uc(lines).execute(cardNumberSuffix: '0001');
    final both = await _uc(
      lines,
    ).execute(vehicleNumber: 1, cardNumberSuffix: '0001');

    expect(byVehicle.lines.map((l) => l.exitIc).toSet(), {'a', 'c'});
    expect(byCard.lines.map((l) => l.exitIc).toSet(), {'a', 'b'});
    expect(both.lines.map((l) => l.exitIc), ['a']);
  });

  test(
    'makes the choices from all lines, not only the filtered ones',
    () async {
      final lines = await _stored([
        fakeStatementLine(vehicleNumber: 20, cardNumber: '0000-****-0002'),
        fakeStatementLine(vehicleNumber: 10, cardNumber: '0000-****-0001'),
        fakeStatementLine(vehicleNumber: 10, cardNumber: '9999-****-0001'),
      ]);

      final result = await _uc(lines).execute(vehicleNumber: 20);

      expect(result.lines, hasLength(1));
      expect(result.vehicleNumberChoices, [10, 20]);
      expect(result.cardNumberChoices, ['0001', '0002']);
    },
  );

  group('a line without a vehicle number', () {
    test('is listed, but is not a choice of the filter', () async {
      final lines = await _stored([
        fakeStatementLine(id: 'a', vehicleNumber: 10),
        fakeStatementLine(
          id: 'b',
          withoutVehicleNumber: true,
          exitAt: DateTime(2026, 1, 11),
        ),
      ]);

      final result = await _uc(lines).execute();

      expect(result.lines, hasLength(2));
      expect(result.lines.map((l) => l.vehicleNumber), [null, 10]);
      expect(result.vehicleNumberChoices, [10]);
    });

    test('is left out when the filter names a vehicle number', () async {
      final lines = await _stored([
        fakeStatementLine(id: 'a', vehicleNumber: 10),
        fakeStatementLine(
          id: 'b',
          withoutVehicleNumber: true,
          exitAt: DateTime(2026, 1, 11),
        ),
      ]);

      final result = await _uc(lines).execute(vehicleNumber: 10);

      expect(result.lines.map((l) => l.id), ['a']);
    });

    test('carries the id of the stored line, to enter the number', () async {
      final lines = await _stored([
        fakeStatementLine(id: 'abc', withoutVehicleNumber: true),
      ]);

      final result = await _uc(lines).execute();

      expect(result.lines.single.id, 'abc');
      expect(result.lines.single.vehicleNumber, isNull);
    });
  });

  test('shows only the last 4 characters of a card number', () async {
    final lines = await _stored([
      fakeStatementLine(cardNumber: '1234-5678-9012-3456'),
      fakeStatementLine(cardNumber: '12'),
    ]);

    final result = await _uc(lines).execute();

    expect(result.cardNumberChoices, ['12', '3456']);
  });

  test('sums the fares and the breakdown of the filtered lines', () async {
    final lines = await _stored([
      fakeStatementLine(vehicleNumber: 1, fare: 1000, fareAfterRebate: 200),
      fakeStatementLine(vehicleNumber: 1, fare: 500),
      fakeStatementLine(vehicleNumber: 2, fare: 9999),
    ]);

    final result = await _uc(lines).execute(vehicleNumber: 1);

    expect(result.totalFare, 1500);
    expect(result.totalFareAfterRebate, 200);
    expect(result.totalPostpaidFare, 1300);
  });

  test('includes pending lines in the total and keeps their status', () async {
    final lines = await _stored([
      fakeStatementLine(
        exitIc: 'p',
        fare: 300,
        status: ConfirmationStatusValue.pending,
      ),
      fakeStatementLine(exitIc: 'c', fare: 100),
    ]);

    final result = await _uc(lines).execute();

    expect(result.totalFare, 400);
    expect(
      result.lines.singleWhere((l) => l.exitIc == 'p').status,
      ConfirmationStatusValue.pending,
    );
  });

  test('keeps a blank entrance as null', () async {
    final lines = await _stored([fakeStatementLine(withoutEntrance: true)]);

    final line = (await _uc(lines).execute()).lines.single;

    expect(line.entranceAt, isNull);
    expect(line.entranceIc, isNull);
  });

  test('passes on a failure to read', () async {
    final lines = FakeStatementLineIF()..readError = StateError('disk');

    expect(_uc(lines).execute(), throwsStateError);
  });

  test('carries every field of a statement line, with a card suffix', () async {
    final lines = await _stored([
      fakeStatementLine(
        exitIc: 'x',
        grossFare: 1200,
        etcDiscount: -240,
        fare: 960,
        fareAfterRebate: 100,
        vehicleType: VehicleTypeValue.light,
        vehicleNumber: 77,
        cardNumber: '1234-****-5678',
        status: ConfirmationStatusValue.pending,
        discountTypes: const ['深夜割引', '休日割引'],
      ),
    ]);

    final line = (await _uc(lines).execute()).lines.single;

    expect(line.exitIc, 'x');
    expect(line.grossFare, 1200);
    expect(line.etcDiscount, -240);
    expect(line.fare, 960);
    expect(line.fareAfterRebate, 100);
    expect(line.postpaidFare, 860);
    expect(line.vehicleType, VehicleTypeValue.light);
    expect(line.vehicleNumber, 77);
    expect(line.cardNumberSuffix, '5678');
    expect(line.status, ConfirmationStatusValue.pending);
    expect(line.discountTypes, ['深夜割引', '休日割引']);
  });

  test(
    'keeps blank discounts as null and no discount types as empty',
    () async {
      final lines = await _stored([fakeStatementLine()]);

      final line = (await _uc(lines).execute()).lines.single;

      expect(line.grossFare, isNull);
      expect(line.etcDiscount, isNull);
      expect(line.discountTypes, isEmpty);
    },
  );

  group('route names', () {
    final points = [
      fakeIcPoint(name: '北', routeNames: const ['R1', 'R2']),
      fakeIcPoint(name: '東', routeNames: const ['R2', 'R3']),
      fakeIcPoint(name: '南', routeNames: const ['R4']),
    ];

    Future<List<String>> routesOf(
      String entrance,
      String exit, {
      FakeIcMappingIF? mappings,
      bool withoutEntrance = false,
    }) async {
      final lines = FakeStatementLineIF();
      lines.stored.add(
        fakeStatementLine(
          exitIc: exit,
          entranceIc: entrance,
          withoutEntrance: withoutEntrance,
        ),
      );
      final uc = fakeListUC(lines, points: points, mappings: mappings);
      return (await uc.execute()).lines.single.routeNames;
    }

    test('are the routes both ICs share', () async {
      expect(await routesOf('北ＩＣ', '東'), ['R2']);
    });

    test('are the routes of both ICs when they share none', () async {
      expect(await routesOf('北', '南'), ['R1', 'R2', 'R4']);
    });

    test('are the routes of the one IC that is known', () async {
      expect(await routesOf('北', '不明'), ['R1', 'R2']);
      expect(await routesOf('不明', '南'), ['R4']);
      expect(await routesOf('北', '東', withoutEntrance: true), ['R2', 'R3']);
    });

    test('are empty when no IC is known', () async {
      expect(await routesOf('不明', '不明2'), isEmpty);
    });

    test('follow a mapping the user registered', () async {
      final mappings = FakeIcMappingIF()
        ..stored.add(const IcMappingEntity(icName: '不明', pointId: 'id-南'));

      expect(await routesOf('北', '不明', mappings: mappings), ['R1', 'R2', 'R4']);
    });
  });
}
