import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:etc_meisai/domain/entity/ic_mapping_entity.dart';
import 'package:etc_meisai/domain/value/ic_kind_value.dart';
import 'package:etc_meisai/infrastructure/repository/database/app_database.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_mapping_repo.dart';
import 'package:etc_meisai/infrastructure/repository/ic_mapping/ic_master_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IcMasterRepo', () {
    String json() => jsonEncode({
      'source': 'x',
      'points': [
        {
          'id': 'a',
          'name': '東京',
          'kind': 3,
          'lat': 35.5,
          'lon': 139.5,
          'routes': ['R1', 'R2'],
        },
        {
          'id': 'b',
          'name': '不明な種類',
          'kind': 99,
          'lat': 1,
          'lon': 2,
          'routes': [],
        },
      ],
    });

    test('reads the points of the JSON', () async {
      final points = await IcMasterRepo(loadJson: () async => json()).findAll();

      expect(points, hasLength(2));
      expect(points.first.id, 'a');
      expect(points.first.name, '東京');
      expect(points.first.kind, IcKindValue.junction);
      expect(points.first.latitude, 35.5);
      expect(points.first.longitude, 139.5);
      expect(points.first.routeNames, ['R1', 'R2']);
      expect(points.last.kind, IcKindValue.other);
      expect(points.last.latitude, 1.0);
      expect(points.last.routeNames, isEmpty);
    });

    test('reads the file only once', () async {
      var count = 0;
      final repo = IcMasterRepo(
        loadJson: () async {
          count++;
          return json();
        },
      );

      await repo.findAll();
      await repo.findAll();

      expect(count, 1);
    });

    test('fails on a broken file', () {
      final repo = IcMasterRepo(loadJson: () async => 'not json');

      expect(repo.findAll(), throwsA(isA<FormatException>()));
    });
  });

  group('links', () {
    String json({String? links}) =>
        '{"points": [{"id": "a", "name": "A", "kind": 1, "lat": 35.0, '
        '"lon": 139.0, "routes": ["R"]}]${links ?? ''}}';

    test('are read with the points', () async {
      final repo = IcMasterRepo(
        loadJson: () async =>
            json(links: ', "links": [["a", "b", 1234], ["b", "c", 5]]'),
      );

      final links = await repo.findLinks();

      expect(links.map((l) => '${l.fromId}-${l.toId}:${l.meters}'), [
        'a-b:1234',
        'b-c:5',
      ]);
      expect(await repo.findAll(), hasLength(1));
    });

    test('have a shape, which is read as points', () async {
      final repo = IcMasterRepo(
        loadJson: () async => json(
          links:
              ', "links": [["a", "b", 100, [35.1, 139.1, 35.2, 139.2]], '
              '["b", "c", 5, []], ["c", "d", 7]]',
        ),
      );

      final links = await repo.findLinks();

      expect(links[0].shape.map((p) => '${p.latitude},${p.longitude}'), [
        '35.1,139.1',
        '35.2,139.2',
      ]);
      // An empty shape, and a link without one (an older master).
      expect(links[1].shape, isEmpty);
      expect(links[2].shape, isEmpty);
    });

    test('are empty when the master has none', () async {
      final repo = IcMasterRepo(loadJson: () async => json());

      expect(await repo.findLinks(), isEmpty);
    });

    test('are read from the file once, with the points', () async {
      var loaded = 0;
      final repo = IcMasterRepo(
        loadJson: () async {
          loaded++;
          return json(links: ', "links": []');
        },
      );

      await repo.findAll();
      await repo.findLinks();
      await repo.findLinks();

      expect(loaded, 1);
    });
  });

  test('the bundled IC master (assets/ic_master.json) is consistent', () async {
    final text = File('assets/ic_master.json').readAsStringSync();
    final points = await IcMasterRepo(loadJson: () async => text).findAll();

    expect(points.length, greaterThan(2000));
    expect({for (final p in points) p.id}, hasLength(points.length));
    for (final p in points) {
      expect(p.name, isNotEmpty, reason: p.id);
      // The points of OpenStreetMap can lie off the routes of N06.
      if (!p.id.startsWith('osm:')) {
        expect(p.routeNames, isNotEmpty, reason: p.id);
      }
      // Inside Japan.
      expect(p.latitude, inInclusiveRange(20, 46), reason: p.id);
      expect(p.longitude, inInclusiveRange(122, 154), reason: p.id);
    }
    expect((jsonDecode(text) as Map)['source'], contains('国土数値情報'));
    expect((jsonDecode(text) as Map)['source'], contains('OpenStreetMap'));
    expect(points.where((p) => p.id.startsWith('osm:')), isNotEmpty);

    // The links join points of the master, and have a length.
    final links = await IcMasterRepo(loadJson: () async => text).findLinks();
    final ids = {for (final p in points) p.id};
    expect(links.length, greaterThan(2000));
    // Most links have a shape: the road between the two points.
    expect(links.where((l) => l.shape.isNotEmpty).length, greaterThan(2000));
    for (final l in links) {
      expect(ids, contains(l.fromId));
      expect(ids, contains(l.toId));
      expect(l.fromId.compareTo(l.toId), lessThanOrEqualTo(0));
      expect(l.meters, greaterThanOrEqualTo(0));
      // No road between two neighbors is longer than the whole of Japan.
      expect(l.meters, lessThan(500000));
    }
  });

  group('IcMappingRepo', () {
    late AppDatabase db;
    late IcMappingRepo repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = IcMappingRepo(db);
    });

    tearDown(() => db.close());

    test('is empty at first', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('stores mappings and reads them back', () async {
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'a'));
      await repo.save(const IcMappingEntity(icName: '南', pointId: 'b'));

      final all = await repo.findAll();

      expect(all.map((m) => '${m.icName}:${m.pointId}').toSet(), {
        '北:a',
        '南:b',
      });
    });

    test('replaces the mapping of the same IC name', () async {
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'a'));
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'b'));

      final all = await repo.findAll();

      expect(all, hasLength(1));
      expect(all.single.pointId, 'b');
    });

    test('deletes one mapping, and does nothing for an unknown name', () async {
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'a'));
      await repo.save(const IcMappingEntity(icName: '南', pointId: 'b'));

      await repo.delete('北');
      await repo.delete('無い');

      expect((await repo.findAll()).single.icName, '南');
    });

    test('is created when a version 1 database is upgraded', () async {
      // A version 1 database has no ic_mappings table.
      await db.customStatement('DROP TABLE ic_mappings');

      await db.migration.onUpgrade(db.createMigrator(), 1, 2);
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'a'));

      expect(await repo.findAll(), hasLength(1));
    });

    test('keeps the table when the database is already version 2', () async {
      await repo.save(const IcMappingEntity(icName: '北', pointId: 'a'));

      await db.migration.onUpgrade(db.createMigrator(), 2, 2);

      expect(await repo.findAll(), hasLength(1));
    });
  });
}
