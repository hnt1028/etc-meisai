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
}
