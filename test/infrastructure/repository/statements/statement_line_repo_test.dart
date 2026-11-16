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
  int? vehicleNumber = 1234,
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
    vehicleNumber: vehicleNumber,
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

  group('vehicle number', () {
    test('stores a line without a vehicle number', () async {
      await repo.save(_statementLine(vehicleNumber: null));

      final lines = await repo.findAll();

      expect(lines.single.vehicleNumber, isNull);
    });

    test('gives every stored line an id, and finds the line by it', () async {
      await repo.save(_statementLine(vehicleNumber: null));
      await repo.save(_statementLine(exitIc: 'C-IC'));

      final lines = await repo.findAll();

      expect(lines.every((l) => l.id != null && l.id!.isNotEmpty), isTrue);
      expect(lines[0].id, isNot(lines[1].id));
      final found = await repo.findById(lines[1].id!);
      expect(found!.exitIc, lines[1].exitIc);
      expect(await repo.findById('no-such-id'), isNull);
    });

    test('updates the vehicle number of one line only', () async {
      await repo.save(_statementLine(vehicleNumber: null));
      await repo.save(_statementLine(exitIc: 'C-IC', vehicleNumber: null));
      final first = (await repo.findAll()).firstWhere(
        (l) => l.exitIc == 'B-IC',
      );

      await repo.updateVehicleNumber(first.id!, 4321);

      final lines = await repo.findAll();
      expect(lines.firstWhere((l) => l.exitIc == 'B-IC').vehicleNumber, 4321);
      expect(lines.firstWhere((l) => l.exitIc == 'C-IC').vehicleNumber, isNull);
      // Nothing else of the line changed, and the id stayed.
      final updated = lines.firstWhere((l) => l.exitIc == 'B-IC');
      expect(updated.id, first.id);
      expect(updated.fare, first.fare);
    });

    test('does nothing for an id that is not stored', () async {
      await repo.save(_statementLine(vehicleNumber: null));

      await repo.updateVehicleNumber('no-such-id', 1);

      expect((await repo.findAll()).single.vehicleNumber, isNull);
    });

    test('keeps the id when an overwrite replaces the line', () async {
      await repo.save(_statementLine(vehicleNumber: null));
      final id = (await repo.findAll()).single.id;

      await repo.save(_statementLine(vehicleNumber: null, fare: 2000));

      final lines = await repo.findAll();
      expect(lines.single.id, id);
      expect(lines.single.fare, 2000);
    });

    test('is made nullable when a version 3 database is upgraded', () async {
      // A version 3 database has a vehicle number that cannot be null.
      await db.customStatement('DROP TABLE statement_lines');
      await db.customStatement('''
        CREATE TABLE statement_lines (
          id TEXT NOT NULL PRIMARY KEY,
          duplicate_key TEXT NOT NULL UNIQUE,
          entrance_at INTEGER NULL,
          exit_at INTEGER NOT NULL,
          entrance_ic TEXT NULL,
          exit_ic TEXT NOT NULL,
          gross_fare INTEGER NULL,
          etc_discount INTEGER NULL,
          fare INTEGER NOT NULL,
          fare_after_rebate INTEGER NOT NULL,
          postpaid_fare INTEGER NOT NULL,
          vehicle_type INTEGER NOT NULL,
          vehicle_number INTEGER NOT NULL,
          card_number TEXT NOT NULL,
          status INTEGER NOT NULL,
          discount_types TEXT NOT NULL
        )
      ''');
      await db.customStatement(
        "INSERT INTO statement_lines VALUES ('old', 'k', NULL, 1, NULL, 'X', "
        "NULL, NULL, 100, 0, 100, 1, 1234, 'c', 0, '')",
      );

      await db.migration.onUpgrade(db.createMigrator(), 3, 4);

      // The columns for the entrance the user enters are there too.
      final id = (await repo.findAll()).single.id!;
      await repo.updateEntrance(id, entranceIc: '入力');
      expect((await repo.findById(id))!.entranceIc, '入力');

      // The line stays, and a line without a vehicle number can be stored.
      expect((await repo.findAll()).single.vehicleNumber, 1234);
      await repo.save(_statementLine(vehicleNumber: null));
      expect(await repo.findAll(), hasLength(2));
    });
  });

  group('entrance the user entered', () {
    // _statementLine gives a default entrance when it is null, so these lines
    // are built by hand.
    StatementLineEntity blank({int fare = 1000, String exitIc = 'B-IC'}) =>
        StatementLineEntity(
          entranceAt: null,
          exitAt: DateTime(2026, 1, 10, 9, 15),
          entranceIc: null,
          exitIc: exitIc,
          grossFare: null,
          etcDiscount: null,
          fare: fare,
          fareAfterRebate: 0,
          postpaidFare: fare,
          vehicleType: VehicleTypeValue.standard,
          vehicleNumber: null,
          cardNumber: '0000-****-0001',
          status: ConfirmationStatusValue.pending,
          discountTypes: const [],
        );

    test('is stored apart, and read as the entrance of the line', () async {
      await repo.save(blank());
      final id = (await repo.findAll()).single.id!;

      await repo.updateEntrance(
        id,
        entranceAt: DateTime(2026, 1, 10, 8),
        entranceIc: 'テスト北',
      );

      final line = (await repo.findAll()).single;
      expect(line.entranceAt, DateTime(2026, 1, 10, 8));
      expect(line.entranceIc, 'テスト北');
      expect((await repo.findById(id))!.entranceIc, 'テスト北');
    });

    test('updates one of them and leaves the other', () async {
      await repo.save(blank());
      final id = (await repo.findAll()).single.id!;

      await repo.updateEntrance(id, entranceIc: '北');
      await repo.updateEntrance(id, entranceAt: DateTime(2026, 1, 10, 8));

      final line = (await repo.findAll()).single;
      expect(line.entranceIc, '北');
      expect(line.entranceAt, DateTime(2026, 1, 10, 8));
    });

    test('does not change the duplicate key', () async {
      await repo.save(blank());
      final id = (await repo.findAll()).single.id!;
      await repo.updateEntrance(
        id,
        entranceAt: DateTime(2026, 1, 10, 8),
        entranceIc: '北',
      );

      // The same CSV line again is the same line, not a new one.
      final again = await repo.findSame(blank());
      expect(again!.id, id);
      await repo.save(blank(fare: 2000));

      final lines = await repo.findAll();
      expect(lines, hasLength(1));
      expect(lines.single.id, id);
      expect(lines.single.fare, 2000);
      // What the user entered is still there.
      expect(lines.single.entranceAt, DateTime(2026, 1, 10, 8));
      expect(lines.single.entranceIc, '北');
    });

    test('is not used instead of a value the CSV has', () async {
      await repo.save(blank());
      final id = (await repo.findAll()).single.id!;
      await repo.updateEntrance(id, entranceIc: '入力した');

      // A later CSV (for the same key) cannot have an entrance, because the
      // entrance is in the key; the line the CSV gives for a stored line with
      // an entrance keeps the CSV's value over any entered one.
      await repo.save(_statementLine(vehicleNumber: null));
      final lines = await repo.findAll();
      final fromCsv = lines.firstWhere((l) => l.entranceIc == 'A-IC');
      await repo.updateEntrance(fromCsv.id!, entranceIc: 'ignored');
      expect((await repo.findById(fromCsv.id!))!.entranceIc, 'A-IC');
    });

    test('does nothing for an id that is not stored', () async {
      await repo.save(blank());

      await repo.updateEntrance('no-such-id', entranceIc: '北');

      expect((await repo.findAll()).single.entranceIc, isNull);
    });

    test('has no entrance until the user enters one', () async {
      await repo.save(blank());

      final line = (await repo.findAll()).single;

      expect(line.entranceAt, isNull);
      expect(line.entranceIc, isNull);
    });
  });
}
