import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/route_map_option_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/route_map_option/route_map_option_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RouteMapOptionRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    repo = RouteMapOptionRepo(db);
  });

  tearDown(() => db.close());

  test('has nothing before the user sets a number', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('stores a number, and replaces the one of the same option', () async {
    await repo.save(
      const RouteMapOptionEntity(optionCode: 'lineWidth', value: 6),
    );
    await repo.save(
      const RouteMapOptionEntity(optionCode: 'lineWidth', value: 8),
    );
    await repo.save(const RouteMapOptionEntity(optionCode: 'a', value: 1));

    final options = await repo.findAll();

    expect(options.map((o) => (o.optionCode, o.value)), [
      ('a', 1),
      ('lineWidth', 8),
    ]);
  });

  test('deletes every number', () async {
    await repo.save(
      const RouteMapOptionEntity(optionCode: 'lineWidth', value: 6),
    );

    await repo.deleteAll();

    expect(await repo.findAll(), isEmpty);
  });

  test('is created by the upgrade from the version 7', () async {
    await db.customStatement('DROP TABLE route_map_options');

    await db.migration.onUpgrade(db.createMigrator(), 7, 8);
    await repo.save(
      const RouteMapOptionEntity(optionCode: 'lineWidth', value: 6),
    );

    expect(await repo.findAll(), hasLength(1));
  });

  test('is not created again when the version is already 8', () async {
    await repo.save(
      const RouteMapOptionEntity(optionCode: 'lineWidth', value: 6),
    );

    await db.migration.onUpgrade(db.createMigrator(), 8, 8);

    expect(await repo.findAll(), hasLength(1));
  });
}
