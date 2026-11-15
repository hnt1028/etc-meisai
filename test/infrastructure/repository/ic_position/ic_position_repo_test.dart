import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/ic_position_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/ic_position/ic_position_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late IcPositionRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = IcPositionRepo(db);
  });

  tearDown(() => db.close());

  test('is empty at first', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('stores positions and reads them back', () async {
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 35.123, longitude: 139.456),
    );
    await repo.save(
      const IcPositionEntity(icName: '南', latitude: -1.5, longitude: 170.25),
    );

    final all = await repo.findAll();

    final north = all.singleWhere((p) => p.icName == '北');
    expect(north.latitude, 35.123);
    expect(north.longitude, 139.456);
    expect(all.singleWhere((p) => p.icName == '南').longitude, 170.25);
  });

  test('replaces the position of the same IC name', () async {
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 1, longitude: 2),
    );
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 3, longitude: 4),
    );

    final all = await repo.findAll();

    expect(all, hasLength(1));
    expect(all.single.latitude, 3);
    expect(all.single.longitude, 4);
  });

  test('deletes one position, and does nothing for an unknown name', () async {
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 1, longitude: 2),
    );
    await repo.save(
      const IcPositionEntity(icName: '南', latitude: 3, longitude: 4),
    );

    await repo.delete('北');
    await repo.delete('無い');

    expect((await repo.findAll()).single.icName, '南');
  });

  test('is created when a version 2 database is upgraded', () async {
    // A version 2 database has no ic_positions table.
    await db.customStatement('DROP TABLE ic_positions');

    await db.migration.onUpgrade(db.createMigrator(), 2, 3);
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 1, longitude: 2),
    );

    expect(await repo.findAll(), hasLength(1));
  });

  test('is created too when a version 1 database is upgraded', () async {
    await db.customStatement('DROP TABLE ic_positions');
    await db.customStatement('DROP TABLE ic_mappings');

    await db.migration.onUpgrade(db.createMigrator(), 1, 3);
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 1, longitude: 2),
    );

    expect(await repo.findAll(), hasLength(1));
  });

  test('keeps the table when the database is already version 3', () async {
    await repo.save(
      const IcPositionEntity(icName: '北', latitude: 1, longitude: 2),
    );

    await db.migration.onUpgrade(db.createMigrator(), 3, 3);

    expect(await repo.findAll(), hasLength(1));
  });
}
