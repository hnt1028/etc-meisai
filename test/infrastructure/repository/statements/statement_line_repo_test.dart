import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

StatementLineEntity _statementLine({
  int fare = 1000,
  String exitIc = 'B-IC',
  DateTime? entranceAt,
  String? entranceIc = 'A-IC',
  String cardNumber = '0000-****-0001',
  VehicleTypeValue vehicleType = VehicleTypeValue.standard,
}) {
  return StatementLineEntity(
    entranceAt: entranceAt ?? DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: entranceIc,
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: fare,
    fareAfterRebate: 0,
    postpaidFare: fare,
    vehicleType: vehicleType,
    vehicleNumber: 1234,
    cardNumber: cardNumber,
    status: ConfirmationStatusValue.pending,
    discountTypes: const [],
  );
}

void main() {
  late AppDatabase db;
  late StatementLineRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StatementLineRepo(db);
  });

  tearDown(() => db.close());

  test('findSame returns null when nothing is stored', () async {
    expect(await repo.findSame(_statementLine()), isNull);
  });

  test(
    'findSame finds a statement line with the same key, whatever the amount',
    () async {
      await repo.save(_statementLine(fare: 1000));
      final found = await repo.findSame(_statementLine(fare: 2000));
      expect(found?.fare, 1000);
    },
  );

  test(
    'save replaces the stored statement line that has the same key',
    () async {
      await repo.save(_statementLine(fare: 1000));
      await repo.save(_statementLine(fare: 800));

      final all = await repo.findAll();
      expect(all, hasLength(1));
      expect(all.single.fare, 800);
    },
  );

  group('statement lines that differ in one key part are separate', () {
    final cases = <String, StatementLineEntity>{
      'entrance date and time': _statementLine(
        entranceAt: DateTime(2026, 1, 11, 8, 30),
      ),
      'entrance IC': _statementLine(entranceIc: 'Z-IC'),
      'exit IC': _statementLine(exitIc: 'C-IC'),
      'card number': _statementLine(cardNumber: '0000-****-0002'),
    };
    cases.forEach((name, other) {
      test(name, () async {
        await repo.save(_statementLine());
        expect(await repo.findSame(other), isNull);
        await repo.save(other);
        expect(await repo.findAll(), hasLength(2));
      });
    });
  });

  test(
    'a statement line with a blank entrance can be stored and found',
    () async {
      final statementLine = _statementLine(entranceIc: null);
      await repo.save(statementLine);
      expect(await repo.findSame(statementLine), isNotNull);
    },
  );

  test('every column survives a save and a read', () async {
    final statementLine = StatementLineEntity(
      entranceAt: DateTime(2026, 1, 10, 8, 30),
      exitAt: DateTime(2026, 1, 10, 9, 15),
      entranceIc: 'A-IC',
      exitIc: 'B-IC',
      grossFare: 1200,
      etcDiscount: -240,
      fare: 960,
      fareAfterRebate: 0,
      postpaidFare: 960,
      vehicleType: VehicleTypeValue.standard,
      vehicleNumber: 1234,
      cardNumber: '0000-****-0001',
      status: ConfirmationStatusValue.confirmed,
      discountTypes: const ['深夜割引', '休日割引'],
    );
    await repo.save(statementLine);

    final read = (await repo.findAll()).single;
    expect(read.entranceAt, statementLine.entranceAt);
    expect(read.exitAt, statementLine.exitAt);
    expect(read.entranceIc, statementLine.entranceIc);
    expect(read.exitIc, statementLine.exitIc);
    expect(read.grossFare, 1200);
    expect(read.etcDiscount, -240);
    expect(read.fare, 960);
    expect(read.fareAfterRebate, 0);
    expect(read.postpaidFare, 960);
    expect(read.vehicleType, VehicleTypeValue.standard);
    expect(read.vehicleNumber, 1234);
    expect(read.cardNumber, '0000-****-0001');
    expect(read.status, ConfirmationStatusValue.confirmed);
    expect(read.discountTypes, ['深夜割引', '休日割引']);
  });

  test('null amounts and a blank entrance survive a save and a read', () async {
    await repo.save(_statementLine(entranceIc: null));

    final read = (await repo.findAll()).single;
    expect(read.grossFare, isNull);
    expect(read.etcDiscount, isNull);
    expect(read.entranceIc, isNull);
    expect(read.discountTypes, isEmpty);
  });

  group('id', () {
    final uuidV7 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('is a UUID version 7', () async {
      await repo.save(_statementLine());
      final rows = await db.select(db.statementLines).get();
      expect(rows.single.id, matches(uuidV7));
    });

    test('differs between statement lines', () async {
      await repo.save(_statementLine());
      await repo.save(_statementLine(exitIc: 'C-IC'));
      final rows = await db.select(db.statementLines).get();
      expect(rows.map((r) => r.id).toSet(), hasLength(2));
    });

    test('does not change when the statement line is overwritten', () async {
      await repo.save(_statementLine(fare: 1000));
      final before = (await db.select(db.statementLines).getSingle()).id;
      await repo.save(_statementLine(fare: 800));
      final after = (await db.select(db.statementLines).getSingle()).id;
      expect(after, before);
    });
  });

  test('vehicle type and status are stored as numbers', () async {
    await repo.save(_statementLine());
    final row = await db
        .customSelect('SELECT vehicle_type, status FROM statement_lines')
        .getSingle();
    expect(row.read<int>('vehicle_type'), VehicleTypeValue.standard.code);
    expect(row.read<int>('status'), ConfirmationStatusValue.pending.index);
  });

  test('every vehicle type survives a save and a read', () async {
    for (final type in VehicleTypeValue.values) {
      await repo.deleteAll();
      await repo.save(_statementLine(vehicleType: type));
      expect((await repo.findAll()).single.vehicleType, type);
    }
  });

  test('deleteAll removes every statement line', () async {
    await repo.save(_statementLine());
    await repo.save(_statementLine(exitIc: 'C-IC'));
    await repo.deleteAll();
    expect(await repo.findAll(), isEmpty);
  });
}
