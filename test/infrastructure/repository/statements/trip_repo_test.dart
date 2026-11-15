import 'package:etc_meisai/domain/entity/trip_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/statements/trip_repo.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TripEntity _trip({
  int fare = 1000,
  String exitIc = 'B-IC',
  DateTime? entranceAt,
  String? entranceIc = 'A-IC',
  String cardNumber = '0000-****-0001',
}) {
  return TripEntity(
    entranceAt: entranceAt ?? DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: entranceIc,
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: fare,
    fareAfterRebate: 0,
    postpaidFare: fare,
    vehicleType: '1',
    vehicleNumber: 'TEST 0000',
    cardNumber: cardNumber,
    status: ConfirmationStatusValue.pending,
    discountTypes: const [],
  );
}

void main() {
  late AppDatabase db;
  late TripRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TripRepo(db);
  });

  tearDown(() => db.close());

  test('findSame returns null when nothing is stored', () async {
    expect(await repo.findSame(_trip()), isNull);
  });

  test(
    'findSame finds a trip with the same key, whatever the amount',
    () async {
      await repo.save(_trip(fare: 1000));
      final found = await repo.findSame(_trip(fare: 2000));
      expect(found?.fare, 1000);
    },
  );

  test('save replaces the stored trip that has the same key', () async {
    await repo.save(_trip(fare: 1000));
    await repo.save(_trip(fare: 800));

    final all = await repo.findAll();
    expect(all, hasLength(1));
    expect(all.single.fare, 800);
  });

  group('trips that differ in one key part are separate', () {
    final cases = <String, TripEntity>{
      'entrance date and time': _trip(entranceAt: DateTime(2026, 1, 11, 8, 30)),
      'entrance IC': _trip(entranceIc: 'Z-IC'),
      'exit IC': _trip(exitIc: 'C-IC'),
      'card number': _trip(cardNumber: '0000-****-0002'),
    };
    cases.forEach((name, other) {
      test(name, () async {
        await repo.save(_trip());
        expect(await repo.findSame(other), isNull);
        await repo.save(other);
        expect(await repo.findAll(), hasLength(2));
      });
    });
  });

  test('a trip with a blank entrance can be stored and found', () async {
    final trip = _trip(entranceIc: null);
    await repo.save(trip);
    expect(await repo.findSame(trip), isNotNull);
  });

  test('every column survives a save and a read', () async {
    final trip = TripEntity(
      entranceAt: DateTime(2026, 1, 10, 8, 30),
      exitAt: DateTime(2026, 1, 10, 9, 15),
      entranceIc: 'A-IC',
      exitIc: 'B-IC',
      grossFare: 1200,
      etcDiscount: -240,
      fare: 960,
      fareAfterRebate: 0,
      postpaidFare: 960,
      vehicleType: '1',
      vehicleNumber: 'TEST 0000',
      cardNumber: '0000-****-0001',
      status: ConfirmationStatusValue.confirmed,
      discountTypes: const ['深夜割引', '休日割引'],
    );
    await repo.save(trip);

    final read = (await repo.findAll()).single;
    expect(read.entranceAt, trip.entranceAt);
    expect(read.exitAt, trip.exitAt);
    expect(read.entranceIc, trip.entranceIc);
    expect(read.exitIc, trip.exitIc);
    expect(read.grossFare, 1200);
    expect(read.etcDiscount, -240);
    expect(read.fare, 960);
    expect(read.fareAfterRebate, 0);
    expect(read.postpaidFare, 960);
    expect(read.vehicleType, '1');
    expect(read.vehicleNumber, 'TEST 0000');
    expect(read.cardNumber, '0000-****-0001');
    expect(read.status, ConfirmationStatusValue.confirmed);
    expect(read.discountTypes, ['深夜割引', '休日割引']);
  });

  test('null amounts and a blank entrance survive a save and a read', () async {
    await repo.save(_trip(entranceIc: null));

    final read = (await repo.findAll()).single;
    expect(read.grossFare, isNull);
    expect(read.etcDiscount, isNull);
    expect(read.entranceIc, isNull);
    expect(read.discountTypes, isEmpty);
  });

  test('deleteAll removes every trip', () async {
    await repo.save(_trip());
    await repo.save(_trip(exitIc: 'C-IC'));
    await repo.deleteAll();
    expect(await repo.findAll(), isEmpty);
  });
}
