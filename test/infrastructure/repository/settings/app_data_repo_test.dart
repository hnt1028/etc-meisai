import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/app_data_entity.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/domain/entity/statement_line_entity.dart';
import 'package:etc_meisai/domain/value/confirmation_status_value.dart';
import 'package:etc_meisai/domain/value/vehicle_type_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_mapping_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_position/ic_position_repo.dart';
import 'package:etc_meisai/infrastructure/repository/settings/app_data_repo.dart';
import 'package:etc_meisai/infrastructure/repository/statements/statement_line_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

StatementLineEntity _csvLine({
  String exitIc = 'B-IC',
  bool blankEntrance = false,
}) => StatementLineEntity(
  entranceAt: blankEntrance ? null : DateTime(2026, 1, 10, 8, 30),
  exitAt: DateTime(2026, 1, 10, 9, 15),
  entranceIc: blankEntrance ? null : 'A-IC',
  exitIc: exitIc,
  grossFare: 1200,
  etcDiscount: -240,
  fare: 960,
  fareAfterRebate: 0,
  postpaidFare: 960,
  vehicleType: VehicleTypeValue.standard,
  vehicleNumber: blankEntrance ? null : 1234,
  cardNumber: '0000-****-0001',
  status: ConfirmationStatusValue.pending,
  discountTypes: const ['深夜割引', '休日割引'],
);

void main() {
  late AppDatabase db;
  late AppDataRepo repo;
  late StatementLineRepo lines;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AppDataRepo(db);
    lines = StatementLineRepo(db);
  });

  tearDown(() => db.close());

  Future<void> storeEverything() async {
    await lines.save(_csvLine());
    await lines.save(_csvLine(exitIc: 'C-IC', blankEntrance: true));
    final blank = (await lines.findAll()).firstWhere((l) => l.exitIc == 'C-IC');
    // What the user entered for the blank line.
    await lines.updateEntrance(
      blank.id!,
      entranceAt: DateTime(2026, 1, 10, 7, 45),
      entranceIc: '入力した',
    );
    await lines.updateVehicleNumber(blank.id!, 4321);
    await IcMappingRepo(
      db,
    ).save(const IcMappingEntity(icName: '北', pointId: 'p-1'));
    await IcPositionRepo(db).save(
      const IcPositionEntity(icName: '東', latitude: 35.5, longitude: 139.5),
    );
  }

  group('readAll', () {
    test('is empty at first', () async {
      final data = await repo.readAll();

      expect(data.statementLines, isEmpty);
      expect(data.icMappings, isEmpty);
      expect(data.icPositions, isEmpty);
    });

    test(
      'reads every table, with the CSV and the entered values apart',
      () async {
        await storeEverything();

        final data = await repo.readAll();

        expect(data.statementLines, hasLength(2));
        final csv = data.statementLines.firstWhere((l) => l.exitIc == 'B-IC');
        final blank = data.statementLines.firstWhere((l) => l.exitIc == 'C-IC');
        expect(csv.id, isNotEmpty);
        expect(csv.duplicateKey, isNotEmpty);
        expect(csv.entranceAt, DateTime(2026, 1, 10, 8, 30));
        expect(csv.enteredEntranceAt, isNull);
        expect(csv.discountTypes, ['深夜割引', '休日割引']);
        expect(csv.etcDiscount, -240);
        // The CSV left it blank: it is still blank, and the entry is apart.
        expect(blank.entranceAt, isNull);
        expect(blank.entranceIc, isNull);
        expect(blank.enteredEntranceAt, DateTime(2026, 1, 10, 7, 45));
        expect(blank.enteredEntranceIc, '入力した');
        expect(blank.vehicleNumber, 4321);
        expect(data.icMappings.single.pointId, 'p-1');
        expect(data.icPositions.single.latitude, 35.5);
      },
    );

    test('has an empty list of discount types as empty', () async {
      await lines.save(
        StatementLineEntity(
          entranceAt: null,
          exitAt: DateTime(2026, 1, 1),
          entranceIc: null,
          exitIc: 'X',
          grossFare: null,
          etcDiscount: null,
          fare: 1,
          fareAfterRebate: 0,
          postpaidFare: 1,
          vehicleType: VehicleTypeValue.standard,
          vehicleNumber: 1,
          cardNumber: 'c',
          status: ConfirmationStatusValue.confirmed,
          discountTypes: const [],
        ),
      );

      expect(
        (await repo.readAll()).statementLines.single.discountTypes,
        isEmpty,
      );
    });
  });

  group('replaceAll', () {
    test('gives back, row by row, what readAll gave', () async {
      await storeEverything();
      final before = await repo.readAll();
      await repo.deleteAll();
      expect((await repo.readAll()).statementLines, isEmpty);

      await repo.replaceAll(before);

      final after = await repo.readAll();
      expect(after.statementLines, hasLength(2));
      for (final line in before.statementLines) {
        final back = after.statementLines.firstWhere((l) => l.id == line.id);
        expect(back.duplicateKey, line.duplicateKey);
        expect(back.entranceAt, line.entranceAt);
        expect(back.entranceIc, line.entranceIc);
        expect(back.enteredEntranceAt, line.enteredEntranceAt);
        expect(back.enteredEntranceIc, line.enteredEntranceIc);
        expect(back.vehicleNumber, line.vehicleNumber);
        expect(back.status, line.status);
        expect(back.discountTypes, line.discountTypes);
      }
      expect(after.icMappings.single.icName, '北');
      expect(after.icPositions.single.icName, '東');
    });

    test(
      'keeps the duplicate key, so that the same CSV is not added again',
      () async {
        await storeEverything();
        final data = await repo.readAll();
        await repo.deleteAll();
        await repo.replaceAll(data);

        // The same CSV line again is the same line.
        final same = await lines.findSame(
          _csvLine(exitIc: 'C-IC', blankEntrance: true),
        );
        expect(same, isNotNull);
        expect(same!.entranceIc, '入力した');
        await lines.save(_csvLine(exitIc: 'C-IC', blankEntrance: true));
        expect(await lines.findAll(), hasLength(2));
      },
    );

    test('replaces what is stored, and does not add to it', () async {
      await storeEverything();

      await repo.replaceAll(
        AppDataEntity(
          statementLines: [fakeRecord(id: 'new', duplicateKey: 'new-key')],
          icMappings: const [IcMappingEntity(icName: '南', pointId: 'p-9')],
          icPositions: const [],
        ),
      );

      final data = await repo.readAll();
      expect(data.statementLines.single.id, 'new');
      expect(data.icMappings.single.icName, '南');
      expect(data.icPositions, isEmpty);
    });

    test('can replace everything with nothing', () async {
      await storeEverything();

      await repo.replaceAll(emptyAppData());

      final data = await repo.readAll();
      expect(data.statementLines, isEmpty);
      expect(data.icMappings, isEmpty);
      expect(data.icPositions, isEmpty);
    });

    test('keeps what was stored when it fails half way', () async {
      await storeEverything();
      final before = await repo.readAll();

      // Two lines with one duplicate key: the database refuses the second.
      await expectLater(
        repo.replaceAll(
          AppDataEntity(
            statementLines: [
              fakeRecord(id: 'a', duplicateKey: 'same'),
              fakeRecord(id: 'b', duplicateKey: 'same'),
            ],
            icMappings: const [IcMappingEntity(icName: '南', pointId: 'x')],
            icPositions: const [],
          ),
        ),
        throwsA(anything),
      );

      // Everything that was stored is still there, in every table.
      final after = await repo.readAll();
      expect(after.statementLines.map((l) => l.id).toSet(), {
        for (final l in before.statementLines) l.id,
      });
      expect(after.icMappings.single.icName, '北');
      expect(after.icPositions.single.icName, '東');
    });
  });

  group('deleteAll', () {
    test('empties every table', () async {
      await storeEverything();

      await repo.deleteAll();

      final data = await repo.readAll();
      expect(data.statementLines, isEmpty);
      expect(data.icMappings, isEmpty);
      expect(data.icPositions, isEmpty);
    });

    test('does nothing to an empty database', () async {
      await repo.deleteAll();

      expect((await repo.readAll()).statementLines, isEmpty);
    });
  });
}
