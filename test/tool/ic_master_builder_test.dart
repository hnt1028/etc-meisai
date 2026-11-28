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

  group('links', () {
    // The lines are the ones above: east runs along latitude 35.0 and north
    // along longitude 140.0, and they cross at (140.0, 35.0).
    Map<String, Object?> buildWith(
      List<Map<String, Object?>> joints,
      List<Map<String, Object?>> sections,
    ) => build(joints, sections);

    List<List<Object?>> linksOf(Map<String, Object?> master) =>
        (master['links'] as List).cast<List<Object?>>();

    test('join the points that are next to each other on a route', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
          _joint('EA03_3', '丙', '1', 140.0, 35.0),
        ],
        [east],
      );

      final links = linksOf(master);

      // 甲 - 乙 and 乙 - 丙, and no link from 甲 to 丙, which is on the way.
      expect(links.map((l) => '${l[0]}-${l[1]}'), [
        'EA03_1:甲-EA03_2:乙',
        'EA03_2:乙-EA03_3:丙',
      ]);
      // 0.5 degrees of longitude at latitude 35.0 are about 45.6 km.
      expect(links[0][2] as int, closeTo(45600, 600));
      expect(links[1][2] as int, closeTo(45600, 600));
    });

    test('go from one route to another at a junction', () {
      final master = buildWith(
        [
          _joint('EA03_1', '西', '1', 139.5, 35.0),
          _joint('EA03_2', '分岐', '3', 140.0, 35.0),
          _joint('EA03_3', '北', '1', 140.0, 35.5),
        ],
        [east, north],
      );

      final links = linksOf(master);

      expect(links.map((l) => '${l[0]}-${l[1]}').toSet(), {
        'EA03_1:西-EA03_2:分岐',
        'EA03_2:分岐-EA03_3:北',
      });
      // 0.5 degrees of latitude are about 55.3 km.
      final toNorth = links.singleWhere((l) => (l[1] as String).endsWith('北'));
      expect(toNorth[2] as int, closeTo(55300, 600));
    });

    test('have a point in the order of the ids, and one link for a pair', () {
      final master = buildWith(
        [
          _joint('EA03_2', 'b', '1', 139.5, 35.0),
          _joint('EA03_1', 'a', '1', 139.0, 35.0),
        ],
        [east],
      );

      final links = linksOf(master);

      expect(links, hasLength(1));
      expect(
        (links.single[0] as String).compareTo(links.single[1] as String),
        lessThan(0),
      );
    });

    test('leave out a point that is far from every route', () {
      // 0.01 degrees of latitude is about 1.1 km from the east line.
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
          _joint('EA03_3', '遠い', '1', 139.7, 35.01),
        ],
        [east],
      );

      final ids = linksOf(master).expand((l) => [l[0], l[1]]).toSet();

      expect(ids, {'EA03_1:甲', 'EA03_2:乙'});
    });

    test('do not join two routes that do not meet', () {
      final apart = _section('別の線', [
        [
          [139.0, 36.0],
          [140.0, 36.0],
        ],
      ]);
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
          _joint('EA03_3', '丙', '1', 139.0, 36.0),
          _joint('EA03_4', '丁', '1', 139.5, 36.0),
        ],
        [east, apart],
      );

      final links = linksOf(master).map((l) => '${l[0]}-${l[1]}').toSet();

      expect(links, {'EA03_1:甲-EA03_2:乙', 'EA03_3:丙-EA03_4:丁'});
    });

    test('join two points at one place with a link of 0 meters', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.5, 35.0),
          _joint('EA03_2', '乙', '3', 139.5, 35.00001),
          _joint('EA03_3', '丙', '1', 140.0, 35.0),
        ],
        [east],
      );

      final links = linksOf(master);

      final same = links.singleWhere((l) => l[2] == 0);
      expect({same[0], same[1]}, {'EA03_1:甲', 'EA03_2:乙'});
      // 丙 is next to the first of the two.
      expect(links.where((l) => l[2] != 0), hasLength(1));
    });

    test('keep the shorter of two ways between the same two points', () {
      // A ring: the east line out and a longer way back through the north.
      final ring = _section('環状', [
        [
          [139.5, 35.0],
          [139.5, 35.2],
          [140.0, 35.2],
          [140.0, 35.0],
        ],
      ]);
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.5, 35.0),
          _joint('EA03_2', '乙', '1', 140.0, 35.0),
        ],
        [east, ring],
      );

      final links = linksOf(master);

      expect(links, hasLength(1));
      // The straight 45.6 km along the east line, not the 100 km ring.
      expect(links.single[2] as int, closeTo(45600, 600));
    });

    /// A road that bends: west at (139.0, 35.0), up to (139.1, 35.3), across
    /// to (139.4, 35.3) and down to the east at (139.5, 35.0).
    final bent = _section('曲がった線', [
      [
        [139.0, 35.0],
        [139.1, 35.3],
        [139.4, 35.3],
        [139.5, 35.0],
      ],
    ]);

    List<double> shapeOf(Map<String, Object?> master, String from, String to) {
      final link = linksOf(master).singleWhere(
        (l) => (l[0] as String).endsWith(from) && (l[1] as String).endsWith(to),
      );
      return (link[3] as List).cast<double>();
    }

    test('hold the shape of the road between two points', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
        ],
        [bent],
      );

      final shape = shapeOf(master, '甲', '乙');

      // The two bends, from 甲 to 乙, as lat, lon, lat, lon.
      expect(shape, hasLength(4));
      expect(shape[0], closeTo(35.3, 0.001));
      expect(shape[1], closeTo(139.1, 0.001));
      expect(shape[2], closeTo(35.3, 0.001));
      expect(shape[3], closeTo(139.4, 0.001));
    });

    test('hold the shape from the point with the smaller id', () {
      // The east point has the smaller id, so the shape starts at the east.
      final master = buildWith(
        [
          _joint('EA03_2', '甲', '1', 139.0, 35.0),
          _joint('EA03_1', '乙', '1', 139.5, 35.0),
        ],
        [bent],
      );

      final link = linksOf(master).single;
      final shape = (link[3] as List).cast<double>();

      expect(link[0], 'EA03_1:乙');
      expect(shape[1], closeTo(139.4, 0.001));
      expect(shape[3], closeTo(139.1, 0.001));
    });

    test('leave out the points of a straight road', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
        ],
        [east],
      );

      expect(shapeOf(master, '甲', '乙'), isEmpty);
    });

    test('leave out a bend of less than 15 meters', () {
      // 0.00003 degrees of latitude are about 3 meters.
      final wavy = _section('細かく曲がった線', [
        [
          [139.0, 35.0],
          [139.25, 35.00003],
          [139.5, 35.0],
        ],
      ]);
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
        ],
        [wavy],
      );

      expect(shapeOf(master, '甲', '乙'), isEmpty);
    });

    test('round the shape to 5 decimals', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.0, 35.0),
          _joint('EA03_2', '乙', '1', 139.5, 35.0),
        ],
        [bent],
      );

      for (final value in shapeOf(master, '甲', '乙')) {
        expect((value * 1e5).roundToDouble() / 1e5, value);
      }
    });

    test('have an empty shape for two points at one place', () {
      final master = buildWith(
        [
          _joint('EA03_1', '甲', '1', 139.5, 35.0),
          _joint('EA03_2', '乙', '3', 139.5, 35.00001),
        ],
        [east],
      );

      expect(linksOf(master).single[3], isEmpty);
    });

    test('are empty without any route', () {
      final master = buildWith([_joint('EA03_1', '甲', '1', 139.0, 35.0)], []);

      expect(linksOf(master), isEmpty);
    });

    test('also join a point of OpenStreetMap that is on a route', () {
      final master = buildIcMaster(
        jointJson: _collection([_joint('EA03_1', '甲甲', '1', 139.0, 35.0)]),
        sectionJson: _collection([east]),
        osmJson: jsonEncode({
          'elements': [
            {
              'type': 'node',
              'id': 7,
              'lat': 35.0,
              'lon': 139.5,
              'tags': {'name': '乙乙料金所'},
            },
          ],
        }),
        source: 'test',
      );

      expect(linksOf(master).map((l) => '${l[0]}-${l[1]}'), [
        'EA03_1:甲甲-osm:7',
      ]);
    });
  });

  group('roads of OpenStreetMap', () {
    // A road from (139.0, 36.0) to (140.0, 36.0), with a bend, that N06 does not have.
    final roads = jsonEncode({
      'elements': [
        {
          'type': 'way',
          'id': 1,
          'tags': {'name': '東京湾アクアライン'},
          'geometry': [
            {'lat': 36.0, 'lon': 139.0},
            {'lat': 36.01, 'lon': 139.5},
            {'lat': 36.0, 'lon': 140.0},
          ],
        },
        // Not a way, and a way without a shape: both are left out.
        {'type': 'node', 'id': 2, 'lat': 36.0, 'lon': 139.0},
        {'type': 'way', 'id': 3, 'tags': {}},
      ],
    });

    Map<String, Object?> buildWithRoads() => buildIcMaster(
      jointJson: _collection([
        _joint('EA03_1', '甲甲', '1', 139.0, 36.0),
        _joint('EA03_2', '乙乙', '1', 140.0, 36.0),
        _joint('EA03_3', '丙丙', '1', 139.5, 35.0),
      ]),
      sectionJson: _collection([east]),
      osmRoadsJson: roads,
      source: 'test',
    );

    test('give their route name to the points on the road', () {
      final byName = {for (final p in points(buildWithRoads())) p['name']: p};

      expect(byName['甲甲']!['routes'], ['東京湾アクアライン']);
      expect(byName['乙乙']!['routes'], ['東京湾アクアライン']);
      expect(byName['丙丙']!['routes'], ['東西線']);
    });

    test('join the points on the road, with its shape', () {
      final links = (buildWithRoads()['links'] as List)
          .cast<List<Object?>>()
          .where((l) => (l[0] as String).startsWith('EA03_1'))
          .toList();

      expect(links.map((l) => '${l[0]}-${l[1]}'), ['EA03_1:甲甲-EA03_2:乙乙']);
      // The road bends between the two points.
      expect(links.single[3], isNotEmpty);
    });
  });
}
