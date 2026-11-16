import 'dart:typed_data';

import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/statement_line_if.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns the given statement lines, or throws when [error] is set.
class _FakeStatementIF implements StatementIF {
  _FakeStatementIF(this.statementLines, {this.error});

  final List<StatementLineEntity> statementLines;
  final FormatException? error;

  @override
  List<StatementLineEntity> parse(Uint8List bytes) {
    if (error != null) throw error!;
    return statementLines;
  }
}

/// Keeps statement lines in memory, keyed like the real duplicate key.
class _FakeStatementLineIF implements StatementLineIF {
  final Map<String, StatementLineEntity> stored = {};

  String _key(StatementLineEntity t) =>
      '${t.entranceAt}|${t.entranceIc}|${t.exitIc}|${t.cardNumber}';

  @override
  Future<StatementLineEntity?> findSame(
    StatementLineEntity statementLine,
  ) async => stored[_key(statementLine)];

  @override
  Future<void> save(StatementLineEntity statementLine) async =>
      stored[_key(statementLine)] = statementLine;

  @override
  Future<StatementLineEntity?> findById(String id) async => null;

  @override
  Future<void> updateVehicleNumber(String id, int vehicleNumber) async {}

  @override
  Future<List<StatementLineEntity>> findAll() async => stored.values.toList();

  @override
  Future<void> deleteAll() async => stored.clear();
}

StatementLineEntity _statementLine({
  required ConfirmationStatusValue status,
  int fare = 1000,
  String exitIc = 'B-IC',
  int? vehicleNumber = 1234,
}) {
  return StatementLineEntity(
    entranceAt: DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: 'A-IC',
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: fare,
    fareAfterRebate: 0,
    postpaidFare: fare,
    vehicleType: VehicleTypeValue.standard,
    vehicleNumber: vehicleNumber,
    cardNumber: '0000-****-0001',
    status: status,
    discountTypes: const [],
  );
}

void main() {
  late _FakeStatementLineIF statementLines;
  final bytes = Uint8List(0);

  ImportStatementUC usecase(
    List<StatementLineEntity> incoming, {
    FormatException? e,
  }) {
    return ImportStatementUC(
      statement: _FakeStatementIF(incoming, error: e),
      statementLines: statementLines,
    );
  }

  setUp(() => statementLines = _FakeStatementLineIF());

  test('stores a statement line that is not stored yet', () async {
    final result = await usecase([
      _statementLine(status: ConfirmationStatusValue.pending),
    ]).execute(bytes);

    expect(result.addedCount, 1);
    expect(result.overwrittenCount, 0);
    expect(result.ignoredCount, 0);
    expect((await statementLines.findAll()).length, 1);
  });

  test('importing the same CSV twice does not add statement lines', () async {
    final incoming = [
      _statementLine(status: ConfirmationStatusValue.confirmed),
    ];
    await usecase(incoming).execute(bytes);
    final second = await usecase(incoming).execute(bytes);

    expect(second.addedCount, 0);
    expect((await statementLines.findAll()).length, 1);
  });

  for (final incomingStatus in ConfirmationStatusValue.values) {
    test('ignores an incoming $incomingStatus row '
        'when a confirmed statement line is stored', () async {
      await statementLines.save(
        _statementLine(status: ConfirmationStatusValue.confirmed, fare: 1000),
      );

      final result = await usecase([
        _statementLine(status: incomingStatus, fare: 2000),
      ]).execute(bytes);

      expect(result.ignoredCount, 1);
      expect(result.overwrittenCount, 0);
      final stored = (await statementLines.findAll()).single;
      expect(stored.fare, 1000);
      expect(stored.status, ConfirmationStatusValue.confirmed);
    });
  }

  test('overwrites a pending statement line with a confirmed row', () async {
    await statementLines.save(
      _statementLine(status: ConfirmationStatusValue.pending, fare: 1000),
    );

    final result = await usecase([
      _statementLine(status: ConfirmationStatusValue.confirmed, fare: 800),
    ]).execute(bytes);

    expect(result.overwrittenCount, 1);
    final stored = (await statementLines.findAll()).single;
    expect(stored.fare, 800);
    expect(stored.status, ConfirmationStatusValue.confirmed);
  });

  test('overwrites a pending statement line with a pending row', () async {
    await statementLines.save(
      _statementLine(status: ConfirmationStatusValue.pending, fare: 1000),
    );

    final result = await usecase([
      _statementLine(status: ConfirmationStatusValue.pending, fare: 900),
    ]).execute(bytes);

    expect(result.overwrittenCount, 1);
    expect((await statementLines.findAll()).single.fare, 900);
  });

  test('counts added, overwritten and ignored rows together', () async {
    await statementLines.save(
      _statementLine(status: ConfirmationStatusValue.confirmed),
    );
    await statementLines.save(
      _statementLine(status: ConfirmationStatusValue.pending, exitIc: 'C-IC'),
    );

    final result = await usecase([
      _statementLine(status: ConfirmationStatusValue.pending),
      _statementLine(status: ConfirmationStatusValue.confirmed, exitIc: 'C-IC'),
      _statementLine(status: ConfirmationStatusValue.confirmed, exitIc: 'D-IC'),
    ]).execute(bytes);

    expect(result.ignoredCount, 1);
    expect(result.overwrittenCount, 1);
    expect(result.addedCount, 1);
  });

  test('throws and stores nothing when the CSV is invalid', () async {
    final failing = usecase([
      _statementLine(status: ConfirmationStatusValue.confirmed),
    ], e: const FormatException('column count is 14, expected 15'));

    await expectLater(failing.execute(bytes), throwsFormatException);
    expect(await statementLines.findAll(), isEmpty);
  });

  group('vehicle number the user entered', () {
    test('is kept when a pending line is overwritten by a blank one', () async {
      statementLines = _FakeStatementLineIF();
      final stored = _statementLine(
        status: ConfirmationStatusValue.pending,
        vehicleNumber: 4321,
      );
      await statementLines.save(stored);

      final result = await usecase([
        _statementLine(
          status: ConfirmationStatusValue.pending,
          fare: 2000,
          vehicleNumber: null,
        ),
      ]).execute(bytes);

      expect(result.overwrittenCount, 1);
      final now = statementLines.stored.values.single;
      // The new fare, and the number the user entered.
      expect(now.fare, 2000);
      expect(now.vehicleNumber, 4321);
    });

    test('is replaced when the CSV has a vehicle number', () async {
      statementLines = _FakeStatementLineIF();
      await statementLines.save(
        _statementLine(
          status: ConfirmationStatusValue.pending,
          vehicleNumber: 4321,
        ),
      );

      await usecase([
        _statementLine(
          status: ConfirmationStatusValue.confirmed,
          vehicleNumber: 1111,
        ),
      ]).execute(bytes);

      expect(statementLines.stored.values.single.vehicleNumber, 1111);
    });

    test('stays blank when nothing was entered', () async {
      statementLines = _FakeStatementLineIF();
      await statementLines.save(
        _statementLine(
          status: ConfirmationStatusValue.pending,
          vehicleNumber: null,
        ),
      );

      await usecase([
        _statementLine(
          status: ConfirmationStatusValue.confirmed,
          vehicleNumber: null,
        ),
      ]).execute(bytes);

      expect(statementLines.stored.values.single.vehicleNumber, isNull);
    });

    test('is kept when a confirmed line is imported again', () async {
      statementLines = _FakeStatementLineIF();
      await statementLines.save(
        _statementLine(
          status: ConfirmationStatusValue.confirmed,
          vehicleNumber: 4321,
        ),
      );

      final result = await usecase([
        _statementLine(
          status: ConfirmationStatusValue.confirmed,
          vehicleNumber: null,
        ),
      ]).execute(bytes);

      // A confirmed line is ignored, so nothing changes.
      expect(result.ignoredCount, 1);
      expect(statementLines.stored.values.single.vehicleNumber, 4321);
    });

    test('adds a line without a vehicle number', () async {
      statementLines = _FakeStatementLineIF();

      final result = await usecase([
        _statementLine(
          status: ConfirmationStatusValue.confirmed,
          vehicleNumber: null,
        ),
      ]).execute(bytes);

      expect(result.addedCount, 1);
      expect(statementLines.stored.values.single.vehicleNumber, isNull);
    });
  });
}
