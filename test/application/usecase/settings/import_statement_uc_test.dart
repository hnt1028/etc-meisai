import 'dart:typed_data';

import 'package:etc_meisai/application/interface/statement_if.dart';
import 'package:etc_meisai/application/interface/trip_if.dart';
import 'package:etc_meisai/application/usecase/settings/import_statement_uc.dart';
import 'package:etc_meisai/domain/entity/trip_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns the given trips, or throws when [error] is set.
class _FakeStatementIF implements StatementIF {
  _FakeStatementIF(this.trips, {this.error});

  final List<TripEntity> trips;
  final FormatException? error;

  @override
  List<TripEntity> parse(Uint8List bytes) {
    if (error != null) throw error!;
    return trips;
  }
}

/// Keeps trips in memory, keyed like the real duplicate key.
class _FakeTripIF implements TripIF {
  final Map<String, TripEntity> stored = {};

  String _key(TripEntity t) =>
      '${t.entranceAt}|${t.entranceIc}|${t.exitIc}|${t.cardNumber}';

  @override
  Future<TripEntity?> findSame(TripEntity trip) async => stored[_key(trip)];

  @override
  Future<void> save(TripEntity trip) async => stored[_key(trip)] = trip;

  @override
  Future<List<TripEntity>> findAll() async => stored.values.toList();

  @override
  Future<void> deleteAll() async => stored.clear();
}

TripEntity _trip({
  required ConfirmationStatusValue status,
  int fare = 1000,
  String exitIc = 'B-IC',
}) {
  return TripEntity(
    entranceAt: DateTime(2026, 1, 10, 8, 30),
    exitAt: DateTime(2026, 1, 10, 9, 15),
    entranceIc: 'A-IC',
    exitIc: exitIc,
    grossFare: null,
    etcDiscount: null,
    fare: fare,
    fareAfterRebate: 0,
    postpaidFare: fare,
    vehicleType: '1',
    vehicleNumber: 'TEST 0000',
    cardNumber: '0000-****-0001',
    status: status,
    discountTypes: const [],
  );
}

void main() {
  late _FakeTripIF trips;
  final bytes = Uint8List(0);

  ImportStatementUC usecase(List<TripEntity> incoming, {FormatException? e}) {
    return ImportStatementUC(
      statement: _FakeStatementIF(incoming, error: e),
      trips: trips,
    );
  }

  setUp(() => trips = _FakeTripIF());

  test('stores a trip that is not stored yet', () async {
    final result = await usecase([
      _trip(status: ConfirmationStatusValue.pending),
    ]).execute(bytes);

    expect(result.addedCount, 1);
    expect(result.overwrittenCount, 0);
    expect(result.ignoredCount, 0);
    expect((await trips.findAll()).length, 1);
  });

  test('importing the same CSV twice does not add trips', () async {
    final incoming = [_trip(status: ConfirmationStatusValue.confirmed)];
    await usecase(incoming).execute(bytes);
    final second = await usecase(incoming).execute(bytes);

    expect(second.addedCount, 0);
    expect((await trips.findAll()).length, 1);
  });

  for (final incomingStatus in ConfirmationStatusValue.values) {
    test('ignores an incoming $incomingStatus row '
        'when a confirmed trip is stored', () async {
      await trips.save(
        _trip(status: ConfirmationStatusValue.confirmed, fare: 1000),
      );

      final result = await usecase([
        _trip(status: incomingStatus, fare: 2000),
      ]).execute(bytes);

      expect(result.ignoredCount, 1);
      expect(result.overwrittenCount, 0);
      final stored = (await trips.findAll()).single;
      expect(stored.fare, 1000);
      expect(stored.status, ConfirmationStatusValue.confirmed);
    });
  }

  test('overwrites a pending trip with a confirmed row', () async {
    await trips.save(
      _trip(status: ConfirmationStatusValue.pending, fare: 1000),
    );

    final result = await usecase([
      _trip(status: ConfirmationStatusValue.confirmed, fare: 800),
    ]).execute(bytes);

    expect(result.overwrittenCount, 1);
    final stored = (await trips.findAll()).single;
    expect(stored.fare, 800);
    expect(stored.status, ConfirmationStatusValue.confirmed);
  });

  test('overwrites a pending trip with a pending row', () async {
    await trips.save(
      _trip(status: ConfirmationStatusValue.pending, fare: 1000),
    );

    final result = await usecase([
      _trip(status: ConfirmationStatusValue.pending, fare: 900),
    ]).execute(bytes);

    expect(result.overwrittenCount, 1);
    expect((await trips.findAll()).single.fare, 900);
  });

  test('counts added, overwritten and ignored rows together', () async {
    await trips.save(_trip(status: ConfirmationStatusValue.confirmed));
    await trips.save(
      _trip(status: ConfirmationStatusValue.pending, exitIc: 'C-IC'),
    );

    final result = await usecase([
      _trip(status: ConfirmationStatusValue.pending),
      _trip(status: ConfirmationStatusValue.confirmed, exitIc: 'C-IC'),
      _trip(status: ConfirmationStatusValue.confirmed, exitIc: 'D-IC'),
    ]).execute(bytes);

    expect(result.ignoredCount, 1);
    expect(result.overwrittenCount, 1);
    expect(result.addedCount, 1);
  });

  test('throws and stores nothing when the CSV is invalid', () async {
    final failing = usecase([
      _trip(status: ConfirmationStatusValue.confirmed),
    ], e: const FormatException('column count is 14, expected 15'));

    await expectLater(failing.execute(bytes), throwsFormatException);
    expect(await trips.findAll(), isEmpty);
  });
}
