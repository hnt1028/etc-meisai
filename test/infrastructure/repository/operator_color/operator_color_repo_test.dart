import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/operator_color_entity.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/operator_color/operator_color_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late OperatorColorRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    // Not const, so that the constructor runs (and is counted by coverage).
    // ignore: prefer_const_constructors
    repo = OperatorColorRepo(db);
  });

  tearDown(() => db.close());

  test('has no color before the user chooses one', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('stores colors, and gives them back ordered by operator', () async {
    await repo.save(
      const OperatorColorEntity(operatorName: '首都高速道路', color: 0xFF000002),
    );
    await repo.save(
      const OperatorColorEntity(operatorName: 'NEXCO東日本', color: 0xFF000001),
    );

    final colors = await repo.findAll();

    expect(colors.map((c) => (c.operatorName, c.color)), [
      ('NEXCO東日本', 0xFF000001),
      ('首都高速道路', 0xFF000002),
    ]);
  });

  test('replaces the color of the same operator', () async {
    const name = 'NEXCO東日本';
    await repo.save(const OperatorColorEntity(operatorName: name, color: 1));
    await repo.save(const OperatorColorEntity(operatorName: name, color: 2));

    final colors = await repo.findAll();

    expect(colors, hasLength(1));
    expect(colors.single.color, 2);
  });

  test('deletes the color of one operator, or all of them', () async {
    for (final name in ['NEXCO東日本', '首都高速道路', '阪神高速道路']) {
      await repo.save(OperatorColorEntity(operatorName: name, color: 1));
    }

    await repo.delete('NEXCO東日本');
    expect((await repo.findAll()).map((c) => c.operatorName), [
      '阪神高速道路',
      '首都高速道路',
    ]);
    // An operator without a color is not an error.
    await repo.delete('名古屋高速道路公社');
    expect(await repo.findAll(), hasLength(2));

    await repo.deleteAll();
    expect(await repo.findAll(), isEmpty);
  });

  test('is created by the upgrade from the version 4', () async {
    await db.customStatement('DROP TABLE operator_colors');

    await db.migration.onUpgrade(db.createMigrator(), 4, 5);
    await repo.save(
      const OperatorColorEntity(operatorName: 'NEXCO東日本', color: 1),
    );

    expect(await repo.findAll(), hasLength(1));
  });

  test('is not created again when the version is already 5', () async {
    await repo.save(
      const OperatorColorEntity(operatorName: 'NEXCO東日本', color: 1),
    );

    await db.migration.onUpgrade(db.createMigrator(), 5, 5);

    expect(await repo.findAll(), hasLength(1));
  });
}
