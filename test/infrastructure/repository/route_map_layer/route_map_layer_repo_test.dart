import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/route_map_layer_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/route_map_layer/route_map_layer_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RouteMapLayerRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    repo = RouteMapLayerRepo(db);
  });

  tearDown(() => db.close());

  test('has no choice before the user chooses', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('stores the choices, and gives them back ordered by layer', () async {
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: false),
    );
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'markers', visible: true),
    );

    final layers = await repo.findAll();

    expect(layers.map((l) => (l.layerCode, l.visible)), [
      ('markers', true),
      ('network', false),
    ]);
  });

  test('replaces the choice of the same layer', () async {
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: false),
    );
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: true),
    );

    final layers = await repo.findAll();

    expect(layers, hasLength(1));
    expect(layers.single.visible, isTrue);
  });

  test('deletes every choice', () async {
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: false),
    );

    await repo.deleteAll();

    expect(await repo.findAll(), isEmpty);
  });

  test('is created by the upgrade from the version 5', () async {
    await db.customStatement('DROP TABLE route_map_layers');

    await db.migration.onUpgrade(db.createMigrator(), 5, 6);
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: false),
    );

    expect(await repo.findAll(), hasLength(1));
  });

  test('is not created again when the version is already 6', () async {
    await repo.save(
      const RouteMapLayerEntity(layerCode: 'network', visible: false),
    );

    await db.migration.onUpgrade(db.createMigrator(), 6, 6);

    expect(await repo.findAll(), hasLength(1));
  });
}
