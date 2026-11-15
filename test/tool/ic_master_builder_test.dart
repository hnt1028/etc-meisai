import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ic_master_builder.dart';

Map<String, Object?> _joint(
  String id,
  String name,
  String kind,
  double lon,
  double lat, {
  int end = 9999,
}) => {
  'type': 'Feature',
  'properties': {
    'N06_012': 2000,
    'N06_013': 2000,
    'N06_014': end,
    'N06_015': id,
    'N06_018': name,
    'N06_019': kind,
  },
  'geometry': {
    'type': 'Point',
    'coordinates': [lon, lat],
  },
};

Map<String, Object?> _section(
  String route,
  List<List<List<double>>> lines, {
  int end = 9999,
}) => {
  'type': 'Feature',
  'properties': {'N06_003': end, 'N06_007': route},
  'geometry': {'type': 'MultiLineString', 'coordinates': lines},
};

String _collection(List<Map<String, Object?>> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

void main() {
  // A line that runs east along latitude 35.0, and one that runs north along
  // longitude 140.0. They cross at (140.0, 35.0).
  final east = _section('東西線', [
    [
      [139.0, 35.0],
      [140.0, 35.0],
      [141.0, 35.0],
    ],
  ]);
  final north = _section('南北線', [
    [
      [140.0, 34.0],
      [140.0, 36.0],
    ],
  ]);

  Map<String, Object?> build(
    List<Map<String, Object?>> joints,
    List<Map<String, Object?>> sections,
  ) => buildIcMaster(
    jointJson: _collection(joints),
    sectionJson: _collection(sections),
    source: 'test',
  );

  List<Map<String, Object?>> points(Map<String, Object?> master) =>
      (master['points'] as List).cast<Map<String, Object?>>();

  test('keeps the id, name, kind and position of a point', () {
    final master = build([_joint('EA03_1', '甲', '2', 139.5, 35.0)], [east]);

    expect(master['source'], 'test');
    expect(points(master).single, {
      'id': 'EA03_1:甲',
      'name': '甲',
      'kind': 2,
      'lat': 35.0,
      'lon': 139.5,
      'routes': ['東西線'],
    });
  });

  test('gives every route within 50 meters, the nearest first', () {
    // 0.0002 degrees of latitude is about 22 meters north of the east line.
    final master = build(
      [_joint('EA03_1', '交点', '3', 140.0, 35.0002)],
      [east, north],
    );

    expect(points(master).single['routes'], ['南北線', '東西線']);
  });

  test('leaves out a route that is farther than 50 meters', () {
    // 0.001 degrees of latitude is about 110 meters.
    final master = build(
      [_joint('EA03_1', '離れた点', '1', 139.5, 35.001)],
      [east],
    );

    expect(points(master).single['routes'], isEmpty);
  });

  test('leaves out features that no longer exist', () {
    final master = build(
      [
        _joint('EA03_1', '現役', '1', 139.5, 35.0),
        _joint('EA03_2', '廃止', '1', 139.6, 35.0, end: 2010),
      ],
      [
        east,
        _section('廃止線', [
          [
            [139.0, 35.0],
            [141.0, 35.0],
          ],
        ], end: 2010),
      ],
    );

    expect(points(master), hasLength(1));
    expect(points(master).single['routes'], ['東西線']);
  });

  test('makes ids unique when a relation id is shared', () {
    final master = build(
      [
        _joint('EA03_1', '海老江', '1', 139.5, 35.0),
        _joint('EA03_1', '海老江JCT', '3', 139.6, 35.0),
        _joint('EA03_1', '海老江', '1', 139.7, 35.0),
      ],
      [east],
    );

    expect(points(master).map((p) => p['id']).toSet(), {
      'EA03_1:海老江',
      'EA03_1:海老江JCT',
      'EA03_1:海老江-2',
    });
  });

  test('sorts the points by id and reads a single line', () {
    final single = {
      'type': 'Feature',
      'properties': {'N06_003': 9999, 'N06_007': '一本線'},
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [139.0, 35.0],
          [141.0, 35.0],
        ],
      },
    };
    final master = build(
      [
        _joint('EA03_2', 'B', '1', 139.5, 35.0),
        _joint('EA03_1', 'A', '1', 139.6, 35.0),
      ],
      [single],
    );

    expect(points(master).map((p) => p['name']), ['A', 'B']);
    expect(points(master).first['routes'], ['一本線']);
  });

  test('measures to a line that is a single point', () {
    final master = build(
      [_joint('EA03_1', '点', '1', 139.5, 35.0)],
      [
        _section('点の線', [
          [
            [139.5, 35.0],
            [139.5, 35.0],
          ],
        ]),
      ],
    );

    expect(points(master).single['routes'], ['点の線']);
  });

  group('points of OpenStreetMap', () {
    Map<String, Object?> osmNode(int id, String name, double lat, double lon) =>
        {
          'type': 'node',
          'id': id,
          'lat': lat,
          'lon': lon,
          'tags': {'name': name},
        };

    Map<String, Object?> buildWith(
      List<Map<String, Object?>> joints,
      List<Map<String, Object?>> nodes,
    ) => buildIcMaster(
      jointJson: _collection(joints),
      sectionJson: _collection([east]),
      osmJson: jsonEncode({'elements': nodes}),
      source: 'test',
    );

    test('adds a point that N06 does not have', () {
      final master = buildWith(
        [_joint('EA03_1', '甲甲', '1', 139.5, 35.0)],
        [osmNode(7, '乙乙料金所', 35.0, 139.6)],
      );

      final osm = points(master).singleWhere((p) => p['id'] == 'osm:7');
      expect(osm['name'], '乙乙料金所');
      expect(osm['kind'], 4);
      expect(osm['lat'], 35.0);
      expect(osm['lon'], 139.6);
      // On the east line.
      expect(osm['routes'], ['東西線']);
    });

    test('leaves a point without routes when no route is near', () {
      final master = buildWith([], [osmNode(7, '乙乙', 36.0, 139.6)]);

      expect(points(master).single['routes'], isEmpty);
    });

    test('does not add a name N06 has, even with another suffix', () {
      final master = buildWith(
        [_joint('EA03_1', '甲甲IC', '1', 139.5, 35.0)],
        [osmNode(7, '甲甲料金所', 35.0, 139.5), osmNode(8, '甲甲', 35.0, 139.5)],
      );

      expect(points(master).map((p) => p['id']), ['EA03_1:甲甲IC']);
    });

    test('makes one point of one name, at the average position', () {
      final master = buildWith([], [
        osmNode(7, '丙丙料金所', 35.0, 139.0),
        osmNode(8, '丙丙', 35.0, 139.002),
        osmNode(9, '丙丙料金所', 35.002, 139.001),
      ]);

      final osm = points(master).single;
      expect(osm['id'], 'osm:7');
      expect(osm['name'], '丙丙');
      expect(osm['lat'] as double, closeTo(35.00067, 0.00001));
      expect(osm['lon'] as double, closeTo(139.001, 0.00001));
    });

    test('leaves out a point of the same name that is far away', () {
      final master = buildWith([], [
        osmNode(7, '丁丁', 35.0, 139.0),
        osmNode(8, '丁丁', 36.0, 139.0),
      ]);

      expect(points(master).single['lat'], 35.0);
    });

    test('leaves out PA and SA, short names and nodes without a position', () {
      final master = buildWith([], [
        osmNode(1, '京橋PA(下り)', 35.0, 139.0),
        osmNode(2, '鬼怒川SA', 35.0, 139.0),
        osmNode(3, 'ＩＣ', 35.0, 139.0),
        {
          'type': 'node',
          'id': 4,
          'tags': {'name': '位置なし'},
        },
        {'type': 'node', 'id': 5, 'lat': 35.0, 'lon': 139.0, 'tags': {}},
      ]);

      expect(points(master), isEmpty);
    });
  });
}
